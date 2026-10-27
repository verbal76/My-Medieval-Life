"""Independent check of a flight recorder archive (REC-19, schema mml-recorder/2; SIM-GATE-01).

The game writes the archive (game/scripts/core/recorder/); this module reads it with nothing but the standard library and
says whether it is whole and consistent, so the simulation gate never trusts the writer's own word:

  - session.json exists, names the schema, ended, completeness "complete", no unknown codes, nothing recovered;
  - every chunk is a gzip file with a header, one JSON array per row of the header's width, and a footer whose row count
    and sha256 (of the row lines, each followed by "\\n") match;
  - the row sequence numbers of all tables together are exactly 1..last_seq, each once (nothing lost, nothing doubled);
  - each table's row count equals the session's own count;
  - the hourly snapshots (table "snapshot") follow one another an hour apart. A multiplayer guest's session (its network events
    all "guest") has none: the guest's copy of the host's world never simulates (the approved host-authoritative design), so its
    hourly record is the net_state digest, taken on the sync the host marks at each of its hours, in distinct rising game hours
    (none when the guest left before the host's next hour; X20 phase 4.5).

It also returns the facts the gate reconciles with the simulation's own output: the closing snapshot (session.json
"final_snapshot", the world as the session left it), alert counts by rule, villager deaths, births and arrivals (newcomers,
outlaws, arrivals and people returning from a settlement), and accepted trades.

X20-FINAL phase 5 (owner directive 2026-10-27): the black-box checks of the archive's content (class Deep), all from the rows:
  - event ids 1..N each once (N the session's own count), and every row of the other tables naming a recorded event;
  - valid transitions: nobody decides, acts, trades or is born again after their death; roles only child -> adult -> elder;
    a contract opens once, is delivered and paid only while open, ends once, nothing after its end, and its set-aside coins
    come back to zero; a debt is extended once and repaid or defaulted after; each job change starts from the last recorded job
    (reported, not a problem: employment is partly instrumented);
  - the hourly snapshots: counters that only grow never fall, values in range;
  - the session's recorded flags against the flags a scenario requires (verify(..., require_flags=));
  - what was exercised: event counts for each row of recorder_coverage.json "exercise" (the coverage matrix's rows), so a
    scenario that claims a system and recorded none of it is a problem (verify(..., require_rows=));
  - the owner's judgment chain (chains()): a crime fact, the beliefs it formed (witnessed, then told or rumoured), and a later
    weighted choice by a believer with the fact's actor as counterparty; with those who only heard of it counted apart;
  - measures for review (never problems): re-decisions (empty decisions and repeated identical choices per actor-day),
    choice diversity per profile, flows produced, consumed and unmet.
  compare_participants(dirs): the multiplayer participants' hourly net_state digests, section by section.

    python3 tools/recorder_archive.py ARCHIVE_SESSION_DIR      # prints the report; exit 1 if the archive is not valid
    python3 tools/recorder_archive.py --participants HOST_DIR GUEST_DIR...   # compares a network session's participants
"""
import glob
import gzip
import hashlib
import json
import fnmatch
import os
import sys
from collections import Counter, defaultdict

SCHEMA = "mml-recorder/2"
TABLES = ["event", "participant", "decision", "alternative", "factor", "state_change", "link", "alert", "sample", "snapshot"]
COVERAGE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "data", "recorder_coverage.json")
CRIME_FACTS = ("fact:theft", "fact:pickpocket", "fact:assault", "fact:killing", "fact:robbery", "fact:trade_cheat")
ROLE_STEPS = {("child", "adult"), ("adult", "elder")}
GROWING = ("births", "deaths")


def exercise_rows():
    """The coverage matrix's rows with the event patterns that show each was exercised (recorder_coverage.json "exercise")."""
    try:
        return json.load(open(COVERAGE_FILE)).get("exercise", [])
    except (OSError, ValueError):
        return []


class Deep:
    """The content checks of one session (X20-FINAL phase 5), fed table by table in the order verify reads the chunks."""

    def __init__(self, sess):
        self.sess = sess
        self.events_n = int(sess.get("events", 0) or 0)
        self.ids = bytearray(self.events_n + 2) if self.events_n else None
        self.id_dup = self.id_out = 0
        self.refs = []                          # (table, event id) rows naming events, checked at the end
        self.bad_refs = Counter()
        self.ev = {}                            # id -> (day, minute, system, subsystem, category, subtype, actor, outcome, object)
        self.keep = set()                       # ids of the events the transition and chain checks need
        self.died = {}                          # actor ref -> (day, minute, id)
        self.after_death = []
        self.born = Counter()
        self.role_bad = []
        self.job_last = {}
        self.job_breaks = []
        self.props = Counter()
        self.flows = Counter()
        self.contract_coins = defaultdict(int)
        self.choice_cp = defaultdict(set)       # choice event id -> counterparties
        self.belief_teller = {}
        self.part_rows = defaultdict(list)      # kept event id -> [(ref, role)]
        self.empty_dec = Counter()              # (actor, day) -> empty decisions
        self.choices = Counter()                # (actor, day, profile, chosen) -> count
        self.profile = defaultdict(lambda: {"n": 0, "choosers": set(), "chosen": Counter()})
        self.snap_prev = None
        self.snap_bad = []
        self.decisions = {}                     # choice event id -> chosen
        self.diag = Diag()                      # REC-DIAG: abnormal-run evidence (findings, never problems)

    # --- feeding
    def event_rows(self, cols, rows):
        ix = {c: i for i, c in enumerate(cols)}
        g = lambda r, c, d=None: r[ix[c]] if c in ix else d
        for r in rows:
            i = g(r, "id")
            if self.ids is not None and isinstance(i, int):
                if i < 1 or i > self.events_n:
                    self.id_out += 1
                elif self.ids[i]:
                    self.id_dup += 1
                else:
                    self.ids[i] = 1
            par = g(r, "parent", -1)
            if isinstance(par, int) and par > 0:
                self.refs.append(("event.parent", par))
            row = (g(r, "day", 0), g(r, "minute", 0.0), g(r, "system", ""), g(r, "subsystem", ""), g(r, "category", ""), g(r, "subtype", ""),
                   g(r, "actor", ""), g(r, "outcome", ""), g(r, "object", ""))
            cat, sub, sysn, subsys, actor = row[4], row[5], row[2], row[3], row[6]
            if (cat in ("life", "contract", "credit", "network", "summary") or (cat == "judgment" and subsys in ("fact", "belief", "choice", "gossip"))
                    or cat in ("action", "decision", "transaction", "verb")) and isinstance(i, int):
                if cat in ("action", "decision", "transaction", "verb"):
                    self.ev[i] = (row[0], row[1], "", "", cat, sub, actor, row[7], "")      # light: after-death checks, a death's cause chain
                else:
                    self.ev[i] = row
                    self.keep.add(i)
            if cat == "decision" and row[7] == "empty":
                self.empty_dec[(actor, row[0])] += 1
            self.diag.event(i, row, g(r, "detail", ""))

    def other_rows(self, table, cols, rows):
        ix = {c: i for i, c in enumerate(cols)}
        key = {"participant": "event", "decision": "event", "alternative": "event", "factor": "event", "state_change": "event"}.get(table)
        for r in rows:
            if key and key in ix:
                self.refs.append((table, r[ix[key]]))
            if table == "link":
                for c in ("from", "to"):
                    if c in ix:
                        self.refs.append(("link." + c, r[ix[c]]))
            if table in ("factor", "participant"):
                self.diag.other(table, ix, r)
            if table == "participant" and "event" in ix:
                self.part_rows[r[ix["event"]]].append((r[ix["ref"]], r[ix["role"]]))
            elif table == "decision" and "event" in ix:
                self.decisions[r[ix["event"]]] = r[ix["chosen"]]
            elif table == "state_change" and "prop" in ix:
                prop, ref, ev = str(r[ix["prop"]]), str(r[ix["ref"]]), r[ix["event"]]
                head = prop.split(":")[0]
                self.props[head] += 1
                if head in ("produced", "consumed", "unmet"):
                    d = r[ix["delta"]] if isinstance(r[ix["delta"]], (int, float)) else 0
                    self.flows[prop] += d if isinstance(d, (int, float)) else 0
                elif prop == "role":
                    if (r[ix["before"]], r[ix["after"]]) not in ROLE_STEPS:
                        self.role_bad.append("%s role %s -> %s (event %s)" % (ref, r[ix["before"]], r[ix["after"]], ev))
                elif prop == "job":
                    last = self.job_last.get(ref)
                    if last is not None and last != r[ix["before"]] and len(self.job_breaks) < 20:
                        self.job_breaks.append("%s job %r -> %r, last recorded %r (event %s)" % (ref, r[ix["before"]], r[ix["after"]], last, ev))
                    self.job_last[ref] = r[ix["after"]]
                elif prop == "coins" and ref.startswith("contract:") and isinstance(r[ix["delta"]], int):
                    self.contract_coins[ref] += r[ix["delta"]]
            elif table == "snapshot":
                s = dict(zip(cols, r))
                if self.snap_prev:
                    for k in GROWING:
                        if k in s and k in self.snap_prev and s[k] < self.snap_prev[k]:
                            self.snap_bad.append("snapshot %s fell: %s -> %s at day %s hour %s" % (k, self.snap_prev[k], s[k], s.get("day"), s.get("hour")))
                for k in ("alive", "starving", "households", "adults"):
                    if isinstance(s.get(k), (int, float)) and s[k] < 0:
                        self.snap_bad.append("snapshot %s negative at day %s hour %s" % (k, s.get("day"), s.get("hour")))
                if isinstance(s.get("mean_hunger"), (int, float)) and not (0 <= s["mean_hunger"] <= 100):
                    self.snap_bad.append("snapshot mean_hunger %s out of range at day %s" % (s["mean_hunger"], s.get("day")))
                if isinstance(s.get("starving"), int) and isinstance(s.get("alive"), int) and s["starving"] > s["alive"]:
                    self.snap_bad.append("snapshot starving %s above alive %s at day %s" % (s["starving"], s["alive"], s.get("day")))
                self.snap_prev = s
                self.diag.snapshot(s)

    # --- results
    def finish(self, rep, require_flags=None, require_rows=None):
        probs, notes = rep["problems"], rep.setdefault("notes", [])
        if self.ids is not None:
            missing = self.events_n - sum(self.ids[1:self.events_n + 1])
            if missing or self.id_dup or self.id_out:
                probs.append("event ids: %d missing, %d doubled, %d out of range (of %d)" % (missing, self.id_dup, self.id_out, self.events_n))
            bad = Counter(t for t, e in self.refs if not (isinstance(e, int) and 1 <= e <= self.events_n and self.ids[e]))
            if bad:
                probs.append("rows naming an event that was not recorded: %s" % dict(bad))
        # life: births once; after a death no decision, action, trade or verb by that person
        order = sorted(self.ev.items(), key=lambda kv: (kv[1][0], kv[1][1], kv[0]))
        for i, e in order:
            cat, sub, actor = e[4], e[5], e[6]
            if cat == "life" and sub == "birth":
                self.born[actor] += 1
            if cat == "life" and sub == "death" and actor not in self.died:
                self.died[actor] = (e[0], e[1], i)
            elif cat in ("action", "decision", "transaction", "verb") and actor in self.died:
                d = self.died[actor]
                if (e[0], e[1]) > (d[0], d[1]) and len(self.after_death) < 20:
                    self.after_death.append("%s %s event %d on day %s minute %s after their death (event %d, day %s)" % (actor, cat, i, e[0], e[1], d[2], d[0]))
        twice = [a for a, n in self.born.items() if n > 1]
        if twice:
            probs.append("born more than once: %s" % twice[:10])
        if self.after_death:
            probs.append("events after a death: %d (first: %s)" % (len(self.after_death), self.after_death[0]))
        if self.role_bad:
            probs.append("invalid role changes: %s" % self.role_bad[:5])
        # contracts and debts: their object threads in event order
        threads = defaultdict(list)
        for i, e in order:
            if e[8] and (e[8].startswith("contract:") or e[8].startswith("debt:")) and e[4] in ("contract", "credit"):
                threads[e[8]].append((i, e[5]))
        bad_c = []
        for obj, evs in sorted(threads.items()):
            seq = [s for _, s in evs]
            if obj.startswith("contract:"):
                ends = [k for k, s in enumerate(seq) if s in ("fulfilled", "cancelled", "lapsed")]
                opened = [k for k, s in enumerate(seq) if s == "opened"]
                if len(ends) > 1 or len(opened) > 1 or (ends and ends[0] != len(seq) - 1):
                    bad_c.append("%s %s" % (obj, seq))
                elif any(s in ("delivered", "paid") for s in seq) and not opened:
                    pass                                     # opened before this session began (a loaded game): not judged
                elif opened and any(s in ("delivered", "paid") for k, s in enumerate(seq) if k < opened[0]):
                    bad_c.append("%s %s" % (obj, seq))
                if ends and opened and self.contract_coins.get(obj, 0) != 0:
                    bad_c.append("%s ended with %d coins still set aside on the record" % (obj, self.contract_coins[obj]))
            else:
                ext = [k for k, s in enumerate(seq) if s == "extended"]
                done = [k for k, s in enumerate(seq) if s in ("repaid", "repaid_late")]
                if len(ext) > 1 or len(done) > 1 or (ext and done and done[0] < ext[0]) or (done and done[0] != len(seq) - 1):
                    bad_c.append("%s %s" % (obj, seq))
        if bad_c:
            probs.append("invalid contract or debt transitions: %d (first: %s)" % (len(bad_c), bad_c[0]))
        rep["contracts"] = {"threads": sum(1 for o in threads if o.startswith("contract:")), "debts": sum(1 for o in threads if o.startswith("debt:")),
                            "states": dict(Counter(s for o, evs in threads.items() for _, s in evs))}
        if self.job_breaks:
            notes.append("job changes not starting from the last recorded job (employment is partly instrumented): %d, e.g. %s" % (
                len(self.job_breaks), self.job_breaks[0]))
        probs.extend(self.snap_bad[:5])
        # flags and required rows
        flags = self.sess.get("flags") or {}
        rep["flags"] = flags
        for k, want in (require_flags or {}).items():
            if flags.get(k) != want:
                probs.append("flag %s is %r in the recording; the scenario requires %r (the system was not exercised as claimed)" % (k, flags.get(k), want))
        rep["exercised"] = exercised(rep.get("events", {}), self.props)
        for row in (require_rows or []):
            if rep["exercised"].get(row, {}).get("events", 0) == 0:
                probs.append("required system not exercised: %s (%s)" % (row, rep["exercised"].get(row, {}).get("system", "no such row")))
        # measures for review
        red = [(n, a, d) for (a, d), n in self.empty_dec.items()]
        red.sort(reverse=True)
        rep["redecisions"] = {"empty_decisions": sum(self.empty_dec.values()), "worst_actor_days": [{"actor": a, "day": d, "empty": n} for n, a, d in red[:5]]}
        rep["flows"] = {k: round(v, 2) for k, v in sorted(self.flows.items()) if v}
        rep["state_props"] = dict(self.props)
        rep["chains"] = self.chains()
        prof = defaultdict(lambda: [0, set(), Counter()])
        for i, e in self.ev.items():
            if e[4] == "judgment" and e[3] == "choice":
                p = prof[e[5]]
                p[0] += 1
                p[1].add(e[6])
                p[2][str(self.decisions.get(i))] += 1
        rep["abnormal"] = self.diag.report(self.sess, self.ev)
        rep["choice_profiles"] = {k: {"choices": v[0], "choosers": len(v[1]), "distinct_chosen": len(v[2]),
                                      "forgo_or_none": v[2].get("forgo", 0) + v[2].get("none", 0)} for k, v in sorted(prof.items())}

    def chains(self):
        """The owner's chain: crime fact -> beliefs (witnessed, then told) -> a later choice by a believer about the actor."""
        facts = {}
        for i, e in self.ev.items():
            if e[4] == "judgment" and e[3] == "fact" and e[5] in CRIME_FACTS and e[8]:
                actors = [r for r, role in self.part_rows.get(i, []) if str(role).startswith("actor")]
                facts[e[8]] = {"id": i, "type": e[5], "day": e[0], "minute": e[1], "actors": set(actors)}
        believers = defaultdict(dict)           # fact object -> observer -> (day, minute, source)
        for i, e in self.ev.items():
            if e[4] == "judgment" and e[3] == "belief" and e[8] in facts:
                obs = e[6]
                if obs not in believers[e[8]] or (e[0], e[1]) < believers[e[8]][obs][:2]:
                    believers[e[8]][obs] = (e[0], e[1], e[5])
        choices = defaultdict(list)             # counterparty -> [(day, minute, chooser, profile, chosen)]
        for i, e in self.ev.items():
            if e[4] == "judgment" and e[3] == "choice":
                for ref, role in self.part_rows.get(i, []):
                    if role == "counterparty":
                        choices[ref].append((e[0], e[1], e[6], e[5], self.decisions.get(i)))
        out = {"crime_facts": len(facts), "beliefs": 0, "heard_not_seen": 0, "later_choices": 0, "later_choices_hearsay": 0, "by_profile": Counter(), "examples": []}
        for obj, f in sorted(facts.items(), key=lambda kv: kv[1]["id"]):
            bel = believers.get(obj, {})
            out["beliefs"] += len(bel)
            out["heard_not_seen"] += sum(1 for b in bel.values() if b[2] in ("told", "rumour"))
            for actor in f["actors"]:
                for c in choices.get(actor, []):
                    b = bel.get(c[2])
                    if b and (c[0], c[1]) > (b[0], b[1]):
                        out["later_choices"] += 1
                        out["by_profile"][c[3]] += 1
                        if b[2] in ("told", "rumour"):
                            out["later_choices_hearsay"] += 1
                            if len(out["examples"]) < 5:
                                out["examples"].append({"fact": obj, "type": f["type"], "actor": actor, "chooser": c[2], "heard_by": b[2], "heard_day": b[0],
                                                        "choice_day": c[0], "profile": c[3], "chosen": c[4]})
        out["by_profile"] = dict(out["by_profile"])
        out["complete"] = out["later_choices_hearsay"] > 0
        return out


class Diag:
    """REC-DIAG (owner directive 2026-10-27, X20-COMPLETE s.2A): evidence of abnormal runs, read from the rows the recorder writes
    (life and identity deaths with their context factors, the daily economy and settlement summaries, till moves, property changes,
    abandoned businesses, migrations, the hourly snapshots). Every finding names the seed, the day, the actor and the cause chain.
    These are measures for review, never problems: a village may fail (WDR-022); the simulation's integrity is checked elsewhere."""

    RUN = 3                                     # consecutive days that make a run worth reporting (a review measure, not a limit)
    SOURCES = ("economy_day", "settlement_day", "death")
    KEEP = ("economy_day", "settlement_day", "death", "died", "migration_in", "migration_out", "business_abandoned",
            "owner_changed", "tenant_changed", "till_escheat")
    CAP = 40

    def __init__(self):
        self.ev = {}                            # id -> (day, minute, subtype, actor, detail)
        self.fac = defaultdict(list)            # event id -> [(option, factor, value)]
        self.parts = defaultdict(list)          # kept event id -> [(ref, role)]
        self.days = {}                          # day -> the day's last snapshot

    def event(self, i, row, detail):
        sub = row[5]
        if sub in self.KEEP and isinstance(i, int):
            self.ev[i] = (row[0], row[1], sub, row[6], str(detail or ""))

    def other(self, table, ix, r):
        if table == "factor":
            if r[ix["source"]] in self.SOURCES:
                self.fac[r[ix["event"]]].append((r[ix["option"]], r[ix["factor"]], r[ix["value"]]))
        elif table == "participant" and r[ix["role"]] in ("from", "to"):      # the property and abandonment events' parties only
            self.parts[r[ix["event"]]].append((r[ix["ref"]], r[ix["role"]]))

    def snapshot(self, s):
        if isinstance(s.get("day"), int):
            self.days[s["day"]] = s

    @staticmethod
    def _detail(d, key):
        for part in d.replace(";", " ").split():
            if part.startswith(key + "="):
                return part[len(key) + 1:]
        return ""

    @classmethod
    def runs(cls, series, test):
        """[(first day, last day)] of the runs of at least RUN consecutive days where test(value) holds."""
        out, run = [], None
        for d, v in series:
            if test(v):
                if run is not None and d == run[1] + 1:
                    run[1] = d
                else:
                    run = [d, d]
            else:
                run = None
            if run is not None and run[1] - run[0] + 1 == cls.RUN:
                out.append(run)                 # the same list grows with the run: its last day is filled in below
        return [(r[0], r[1]) for r in out]

    @staticmethod
    def _cause(detail):
        """The cause of a death event's detail ("cause=old age; role=..."), whole."""
        for part in detail.split(";"):
            part = part.strip()
            if part.startswith("cause="):
                return part[len("cause="):]
        return ""

    def report(self, sess, light):
        seed = sess.get("seed")
        found = []

        def add(kind, day, actor, evidence, chain=None):
            found.append({"kind": kind, "seed": seed, "day": day, "actor": actor, "evidence": evidence, "chain": chain or []})

        # deaths: villagers (life|death with their context), off-map members (identity|died with the settlement's cause)
        by_actor = defaultdict(list)
        for i, e in light.items():
            if e[4] in ("action", "decision", "transaction", "verb"):
                by_actor[e[6]].append((e[0], e[1], i, e[4], e[5], e[7]))
        offmap = Counter()
        for i, (day, minute, sub, actor, detail) in sorted(self.ev.items()):
            if sub == "death":
                cause = self._cause(detail)
                if "role=bandit" in detail:
                    continue
                f = {"%s.%s" % (o, k): v for o, k, v in self.fac.get(i, [])}
                means = {k: v for k, v in f.items() if k in ("deceased.coins", "deceased.food_carried", "household.purse", "household.food_units",
                                                             "village.food_for_sale_stalls", "village.food_carried_by_traders", "village.granary_food")
                         and isinstance(v, (int, float)) and v > 0}
                chain = [{"event": j, "day": d, "minute": m, "category": c, "subtype": s, "outcome": o}
                         for d, m, j, c, s, o in sorted(x for x in by_actor.get(actor, []) if (x[0], x[1]) <= (day, minute))[-8:]]
                if cause == "starvation" and means:
                    add("starved_with_means", day, actor, {"cause": cause, "event": i, "means": means, "context": f, "detail": detail}, chain)
                elif cause not in ("old age", "starvation"):
                    add("violent_or_accidental_death", day, actor, {"cause": cause, "event": i, "context": f, "detail": detail}, chain)
                elif cause == "starvation":
                    add("starved_without_means", day, actor, {"cause": cause, "event": i, "context": f, "detail": detail}, chain)
            elif sub == "died":
                frm = self._detail(detail, "from")
                cause = self._cause(detail) or "unrecorded"
                if frm not in ("", "village", "player"):
                    offmap[(frm, cause)] += 1
                    if cause in ("hunger", "no_household_left"):
                        add("settlement_" + cause + "_death", day, actor, {"settlement": frm, "event": i,
                                                                           "settlement_day": self._settlement_on(frm, day)})
        # economic instability: the village's daily series (the day's last snapshot)
        days = sorted(self.days)
        def series(k):
            return [(d, self.days[d].get(k)) for d in days if isinstance(self.days[d].get(k), (int, float))]
        tre = series("treasury")
        for a, b in self.runs(list(zip([d for d, _ in tre[1:]], [y - x for (_, x), (_, y) in zip(tre, tre[1:])])), lambda v: v < 0):
            v0 = dict(tre).get(a - 1, dict(tre)[a])
            add("treasury_drain", a, "manor", {"from_day": a, "to_day": b, "treasury_before": v0, "treasury_after": dict(tre)[b]})
        for a, b in self.runs(tre, lambda v: v <= 0):
            add("treasury_empty", a, "manor", {"from_day": a, "to_day": b})
        for a, b in self.runs(series("hh_purse_min"), lambda v: v <= 0):
            add("household_purse_at_zero", a, "households", {"from_day": a, "to_day": b, "note": "the poorest household's purse stayed at 0"})
        for a, b in self.runs(series("food_days"), lambda v: v < 1):
            add("village_food_short", a, "village", {"from_day": a, "to_day": b, "food_days": dict(series("food_days"))[a]})
        # the daily economy summary: households in hardship, tills stuck at zero, tills without an owner
        hh = defaultdict(list)
        tills = defaultdict(list)
        for i, (day, minute, sub, actor, detail) in sorted(self.ev.items()):
            if sub != "economy_day":
                continue
            f = defaultdict(dict)
            for o, k, v in self.fac.get(i, []):
                f[o][k] = v
            for o, vals in f.items():
                if o.startswith("hh:"):
                    hh[o].append((day, vals))
            for t, c in f.get("till", {}).items():
                tills[t].append((day, c, f.get("till_owner", {}).get(t, "")))
        for h, rows in sorted(hh.items()):
            for a, b in self.runs([(d, v) for d, v in rows], lambda v: v.get("purse", 1) <= 0 and isinstance(v.get("food_days"), (int, float)) and v["food_days"] < 1):
                add("household_hardship", a, h, {"from_day": a, "to_day": b, "first": dict(rows)[a], "last": dict(rows)[b]})
        for t, rows in sorted(tills.items()):
            if any(not o for _, c, o in rows):
                add("till_without_owner", next(d for d, c, o in rows if not o), t, {"rows": rows[:5]})
            had = False
            ser = []
            for d, c, o in rows:
                had = had or (isinstance(c, int) and c > 0)
                if had:
                    ser.append((d, c))
            for a, b in self.runs(ser, lambda v: v == 0):
                add("till_stuck_at_zero", a, t, {"from_day": a, "to_day": b, "owner": dict((d, o) for d, c, o in rows).get(a, "")})
        # the settlements: coins drained, households hungry day after day
        st = defaultdict(list)
        for i, (day, minute, sub, actor, detail) in sorted(self.ev.items()):
            if sub == "settlement_day":
                f = defaultdict(dict)
                for o, k, v in self.fac.get(i, []):
                    f[o][k] = v
                for o, vals in f.items():
                    st[o].append((day, vals))
        for o, rows in sorted(st.items()):
            co = [(d, v.get("coins")) for d, v in rows if isinstance(v.get("coins"), (int, float))]
            for a, b in self.runs(list(zip([d for d, _ in co[1:]], [y - x for (_, x), (_, y) in zip(co, co[1:])])), lambda v: v < 0):
                add("settlement_coins_drain", a, o, {"from_day": a, "to_day": b, "coins_before": dict(co).get(a - 1), "coins_after": dict(co)[b]})
            for a, b in self.runs([(d, v.get("hungry_households", 0)) for d, v in rows], lambda v: isinstance(v, (int, float)) and v > 0):
                add("settlement_hunger", a, o, {"from_day": a, "to_day": b, "first": dict(rows)[a], "last": dict(rows)[b]})
        # businesses abandoned (a holder who left or ended), tills escheated, property passing to the manor; migrations
        mig = Counter()
        for i, (day, minute, sub, actor, detail) in sorted(self.ev.items()):
            if sub == "business_abandoned":
                add("business_abandoned", day, actor, {"event": i, "detail": detail, "parties": self.parts.get(i, [])})
            elif sub == "till_escheat":
                add("till_escheated", day, actor, {"event": i, "detail": detail, "parties": self.parts.get(i, [])})
            elif sub in ("owner_changed", "tenant_changed") and ("front_till" in detail or "counter_till" in detail):
                add("business_premises_changed_hands", day, actor, {"event": i, "change": sub, "detail": detail, "parties": self.parts.get(i, [])})
            elif sub.startswith("migration_"):
                mig[(sub[len("migration_"):], self._detail(detail, "reason"))] += int(self._detail(detail, "people") or 0)
        counts = Counter(f["kind"] for f in found)
        return {"seed": seed, "counts": dict(sorted(counts.items())), "findings": found[:self.CAP], "findings_total": len(found),
                "settlement_deaths": {"%s|%s" % k: n for k, n in sorted(offmap.items())},
                "migrations": {"%s|%s" % k: n for k, n in sorted(mig.items())}, "run_days": self.RUN,
                "note": "evidence for review; never pass/fail (WDR-022)"}

    def _settlement_on(self, sid, day):
        for i, (d, minute, sub, actor, detail) in self.ev.items():
            if sub == "settlement_day" and d == day:
                return {k: v for o, k, v in self.fac.get(i, []) if o == "settlement:" + sid}
        return {}


def exercised(events, props):
    """Event counts (and state rows) for each row of the coverage matrix (recorder_coverage.json "exercise")."""
    out = {}
    for row in exercise_rows():
        n = 0
        for key, k in events.items():
            cat, sub = key.split("|")[0], key.split("|")[1]
            if any(fnmatch.fnmatch("%s|%s" % (cat, sub), p) for p in row.get("events", [])):
                n += k
        for p in row.get("props", []):
            n += props.get(p, 0)
        out[row["row"]] = {"system": row.get("system", ""), "events": n}
    return out


def read_chunk(path):
    """(header, rows, problem) for one chunk; problem is "" when it is whole."""
    try:
        with gzip.open(path, "rt", encoding="utf-8") as f:
            lines = f.read().split("\n")
    except (OSError, EOFError, UnicodeDecodeError) as e:
        return None, [], "unreadable (%s)" % e
    lines = [l for l in lines if l != ""]
    if not lines:
        return None, [], "empty"
    try:
        head = json.loads(lines[0])
    except ValueError:
        return None, [], "header is not JSON"
    if not isinstance(head, dict) or "columns" not in head:
        return None, [], "no header"
    rows, h = [], hashlib.sha256()
    footer = None
    for line in lines[1:]:
        try:
            v = json.loads(line)
        except ValueError:
            return head, rows, "a torn line"
        if isinstance(v, dict) and v.get("footer"):
            footer = v
            break
        if not isinstance(v, list):
            return head, rows, "a row that is not an array"
        rows.append(v)
        h.update((line + "\n").encode("utf-8"))
    if footer is None:
        return head, rows, "no footer (truncated)"
    if footer.get("rows") != len(rows) or footer.get("sha256") != h.hexdigest():
        return head, rows, "footer does not match the rows"
    width = len(head["columns"])
    if any(len(r) != width for r in rows):
        return head, rows, "a row of the wrong width"
    if rows and (rows[0][0] != head.get("first_seq") or rows[-1][0] != head.get("last_seq")):
        return head, rows, "first_seq/last_seq do not match the rows"
    return head, rows, ""


def verify(session_dir, require_flags=None, require_rows=None):
    """Check a session directory. Returns a report dict with "ok" and "problems" (and the X20-FINAL content checks: Deep)."""
    rep = {"dir": session_dir, "ok": False, "problems": [], "chunks": 0, "bytes": 0, "counts": {}, "snapshot_hours": 0,
           "alerts": {}, "villager_deaths": 0, "births": 0, "newcomers": 0, "trades": 0, "last_snapshot": None,
           "first_snapshot": None, "events": {}, "net_role": ""}
    sp = os.path.join(session_dir, "session.json")
    try:
        sess = json.load(open(sp))
    except (OSError, ValueError):
        rep["problems"].append("session.json missing or not JSON")
        return rep
    rep["session"] = {k: sess.get(k) for k in ("schema", "session", "completeness", "ended", "seed", "commit", "bytes", "chunk_count", "last_seq", "flags")}
    if sess.get("schema") != SCHEMA:
        rep["problems"].append("schema %r, expected %r" % (sess.get("schema"), SCHEMA))
    if not sess.get("ended"):
        rep["problems"].append("the session never ended (the recording was cut off)")
    if sess.get("completeness") != "complete":
        rep["problems"].append("completeness: %s" % sess.get("completeness"))
    if sess.get("unknown_codes"):
        rep["problems"].append("unknown codes: %s" % sess.get("unknown_codes"))
    if sess.get("recovered"):
        rep["problems"].append("recovered chunks of an earlier session: %d" % len(sess.get("recovered")))
    deep = Deep(sess)
    last_seq = int(sess.get("last_seq", 0))
    seen = bytearray(last_seq + 1)
    dup = out_of_range = 0
    snaps = []
    net_hours = []                        # (seq, game hour, role) of each net_state digest
    net_roles = set()                     # the roles of the session's network events (host, guest)
    files = sorted(glob.glob(os.path.join(session_dir, "d*", "*.jsonl.gz")))
    for path in files:
        rep["chunks"] += 1
        rep["bytes"] += os.path.getsize(path)
        head, rows, problem = read_chunk(path)
        rel = os.path.relpath(path, session_dir)
        if problem:
            rep["problems"].append("%s: %s" % (rel, problem))
            continue
        table = head.get("table")
        if head.get("schema") != SCHEMA or table not in TABLES:
            rep["problems"].append("%s: header schema %r table %r" % (rel, head.get("schema"), table))
            continue
        rep["counts"][table] = rep["counts"].get(table, 0) + len(rows)
        cols = head["columns"]
        if table == "event":
            deep.event_rows(cols, rows)
        else:
            deep.other_rows(table, cols, rows)
        for r in rows:
            s = r[0]
            if not isinstance(s, int) or s < 1 or s > last_seq:
                out_of_range += 1
            elif seen[s]:
                dup += 1
            else:
                seen[s] = 1
        if table == "snapshot":
            snaps.extend(dict(zip(cols, r)) for r in rows)
        elif table == "alert":
            i = cols.index("rule")
            for r in rows:
                rep["alerts"][r[i]] = rep["alerts"].get(r[i], 0) + 1
        elif table == "event":
            ci, si, oi, di = cols.index("category"), cols.index("subtype"), cols.index("outcome"), cols.index("detail")
            for r in rows:
                key = "%s|%s|%s" % (r[ci], r[si], r[oi])
                rep["events"][key] = rep["events"].get(key, 0) + 1
                if r[ci] == "life" and r[si] == "death" and "role=" in str(r[di]) and "role=bandit" not in str(r[di]):
                    rep["villager_deaths"] += 1
                elif r[ci] == "life" and r[si] == "birth":
                    rep["births"] += 1
                elif r[ci] == "identity" and r[si] in ("registered_newcomer", "registered_outlaw", "registered_arrival", "returned_to_village"):
                    rep["newcomers"] += 1
                elif r[ci] == "transaction" and r[si] == "trade" and r[oi] == "ok":
                    rep["trades"] += 1
                elif r[ci] == "network":
                    if r[si] == "net_state":
                        net_hours.append((r[0], int(r[cols.index("day")]) * 24 + int(float(r[cols.index("minute")]) // 60), r[cols.index("subsystem")]))
                    net_roles.add(r[cols.index("subsystem")])
    missing = last_seq - sum(seen[1:]) if last_seq else 0
    if missing or dup or out_of_range:
        rep["problems"].append("row sequence: %d missing, %d doubled, %d out of range (of %d)" % (missing, dup, out_of_range, last_seq))
    for t, n in (sess.get("counts") or {}).items():
        if rep["counts"].get(t, 0) != n:
            rep["problems"].append("table %s: %d rows on disk, the session counted %d" % (t, rep["counts"].get(t, 0), n))
    snaps.sort(key=lambda s: s["seq"])
    rep["snapshot_hours"] = len(snaps)
    roles = {x for x in net_roles if x in ("host", "guest")}
    rep["net_role"] = "/".join(sorted(roles))
    if not snaps and roles == {"guest"}:
        net_hours.sort()
        hrs = [h[1] for h in net_hours]
        if any(b <= a for a, b in zip(hrs, hrs[1:])):
            rep["problems"].append("a guest's net_state digests are not in distinct rising game hours: %s" % hrs[:12])
        rep["net_state_hours"] = len(hrs)
    elif not snaps:
        rep["problems"].append("no hourly snapshot (schema 2 requires one an hour)")
    for a, b in zip(snaps, snaps[1:]):
        if (b["day"] * 24 + b["hour"]) - (a["day"] * 24 + a["hour"]) != 1:
            rep["problems"].append("snapshots not an hour apart: day %s hour %s -> day %s hour %s" % (a["day"], a["hour"], b["day"], b["hour"]))
            break
    rep["final_snapshot"] = sess.get("final_snapshot")
    if sess.get("ended") and not isinstance(sess.get("final_snapshot"), dict):
        rep["problems"].append("session.json has no final_snapshot (the closing state)")
    if snaps:
        rep["first_snapshot"] = {k: v for k, v in snaps[0].items() if k != "stats_delta"}
        rep["last_snapshot"] = {k: v for k, v in snaps[-1].items() if k != "stats_delta"}
    deep.finish(rep, require_flags, require_rows)
    rep["ok"] = not rep["problems"]
    return rep


def net_states(session_dir):
    """A participant's hourly net_state digests: {(day, hour): {"role", "sections": {key: hash}, "players"}}."""
    evs, facs, actors = {}, defaultdict(dict), {}
    for path in sorted(glob.glob(os.path.join(session_dir, "d*", "*.jsonl.gz"))):
        head, rows, problem = read_chunk(path)
        if problem or head is None:
            continue
        cols = head["columns"]
        if head.get("table") == "event":
            ix = {c: i for i, c in enumerate(cols)}
            for r in rows:
                if r[ix["subtype"]] == "net_state":
                    evs[r[ix["id"]]] = (r[ix["day"]], int(float(r[ix["minute"]]) // 60), r[ix["subsystem"]])
                    actors[r[ix["id"]]] = r[ix["actor"]]
        elif head.get("table") == "factor":
            ix = {c: i for i, c in enumerate(cols)}
            for r in rows:
                facs[r[ix["event"]]][(r[ix["option"]], r[ix["factor"]])] = r[ix["value"]]
    out = {}
    for i, (d, h, role) in evs.items():
        f = facs.get(i, {})
        expected = defaultdict(dict)            # the host's: guest ref -> {section: hash of what that guest is sent}
        for k, v in f.items():
            if k[0] == "for" and "|" in k[1]:
                gref, sec = k[1].split("|", 1)
                expected[gref][sec] = v
        out[(d, h)] = {"role": role, "actor": actors.get(i, ""), "sections": {k[1]: v for k, v in f.items() if k[0] == "section"},
                       "players": f.get(("net", "players"), ""), "for": dict(expected)}
    return out


def compare_participants(dirs):
    """Compare network participants' archives hour by hour (the host's first). A section that differs at three or more consecutive
    compared hours is a problem (a guest copy behind the host for an hour is expected: villagers and animals sync less often).
    X20: a guest is compared with what the host sends it: for a section the host records per guest ("for": the offers and messages
    between players, of which each guest is sent only its own), that hash, not the host's whole section ("absent": none)."""
    parts = [(d, net_states(d)) for d in dirs]
    host = next(((d, s) for d, s in parts if any(v["role"] == "host" for v in s.values())), None)
    rep = {"participants": [{"dir": d, "role": sorted({v["role"] for v in s.values()}), "hours": len(s)} for d, s in parts], "problems": [], "differences": {}}
    if host is None:
        rep["problems"].append("no host digest in these archives")
        return rep
    for d, s in parts:
        if d == host[0]:
            continue
        hours = sorted(set(s) & set(host[1]))
        run, worst = Counter(), Counter()
        diff = Counter()
        for hk in hours:
            a = dict(host[1][hk]["sections"])
            for sec, v in host[1][hk].get("for", {}).get(s[hk].get("actor", ""), {}).items():
                if v == "absent":
                    a.pop(sec, None)
                else:
                    a[sec] = v
            b = s[hk]["sections"]
            for k in sorted(set(a) | set(b)):
                if a.get(k) != b.get(k):
                    diff[k] += 1
                    run[k] += 1
                    worst[k] = max(worst[k], run[k])
                else:
                    run[k] = 0
        rep["differences"][d] = {"hours_compared": len(hours), "sections_differing": dict(diff), "longest_run": dict(worst)}
        if not hours:
            rep["problems"].append("%s: no hour in common with the host" % d)
        for k, n in worst.items():
            if n >= 3:
                rep["problems"].append("%s: section %s differs from the host for %d consecutive hours" % (d, k, n))
    rep["ok"] = not rep["problems"]
    return rep


def session_dirs(root):
    """The session directories under a recorder root (one per run in the gate)."""
    return sorted(d for d in glob.glob(os.path.join(root, "s*")) if os.path.isdir(d))


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--participants":
        r = compare_participants(sys.argv[2:])
        print(json.dumps(r, indent=1, sort_keys=True, default=str))
        sys.exit(0 if r["ok"] else 1)
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    r = verify(sys.argv[1])
    print(json.dumps({k: v for k, v in r.items() if k != "events"}, indent=1, sort_keys=True, default=str))
    sys.exit(0 if r["ok"] else 1)
