"""Flight recorder campaign analyser (FLIGHT-REC-01, owner directive 2026-11-02; docs/release/flight_recorder/README.md).

Reads one seed's complete flight recorder run (every chained segment's archive, status, log and simulation output), checks the
archive with tools/recorder_archive.py, and searches the WHOLE archive (not the workbook's 20,000-event presentation cap) for
abnormal behaviour. It writes:

  findings.json       every finding (severity, confirmed or suspected, NPC, event ids, day range, count, systems, evidence,
                      how to reproduce), with the run's status, the archive checks and the totals
  findings.md         the concise report: what stopped the run and when, then CRITICAL, HIGH, MEDIUM, INFORMATIONAL
  workbook_data.json  the 14 sheets of the analysis workbook as tables and charts (rendered by game/tests/flight_workbook.gd)
  summary.json        the machine-readable result (status, days, stop reason, counts by severity, the top findings)

Severities (the directive's section 7): CRITICAL a confirmed defect (a broken ledger, an impossible state the archive proves, a
crash, a corrupt archive); HIGH repeated behavioural failures, severe economic abnormalities, significant interaction defects;
MEDIUM suspicious trends to investigate; INFORMATIONAL normal observations and legitimate hardship. Only CRITICAL findings are
"confirmed"; everything behavioural is a suspicion with its evidence, never called a programming defect without proof. A village
may fail; the simulation may not (WDR-022): hunger, deaths and decline are reported, never treated as defects by themselves.
Nothing here changes the game.

    python3 tools/flight_analyse.py RUN_DIR [--out OUT_DIR] [--no-verify]

RUN_DIR holds the segments seg1, seg2, ... (each: status.json, sim.json, sim.log, rec/<session>/), or one run's files directly.
Standard library only.
"""
import argparse
import glob
import json
import os
import re
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import recorder_archive as ra  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DEFS = os.path.join(ROOT, "game", "data", "sim_workbook.json")
COVERAGE = os.path.join(ROOT, "game", "data", "recorder_coverage.json")
SEVERITIES = ["CRITICAL", "HIGH", "MEDIUM", "INFORMATIONAL"]
PLAYER_BAND = 1000000                      # person ids from here are the settlement and player band, not villagers
FOOD = {"pottage", "roast_meat", "bread", "flatbread", "cheese", "apple", "blueberries", "red_berries", "meat", "wheat", "egg",
        "milk", "carrot", "potato", "ale", "fish", "cooked_fish"}
FOOD_ACTS = {"eat", "eat_home", "buy_food", "take_pantry", "church_ask", "buy_stall", "drink"}
KEY_ARGS = ("item", "recipe", "pen", "field", "stall", "plot", "station", "plant", "animal", "job", "clue")
# Thresholds: chosen so that legitimate repeated work is not flagged (checked against recorded runs; see the README). A streak is
# the same actor failing the same action on the same thing with no success of it in between.
T = {
    "fail_streak_high": 50, "fail_day_high": 20, "fail_streak_medium": 15, "fail_streak_medium_days": 2,
    "refused_streak_high": 30, "refused_streak_medium": 10,
    "pingpong_day": 16,                     # alternating A,B,A,B... plans in one day (a normal day has 10-30 decisions in all)
    "pingpong_days_high": 5,                # ...on this many days: HIGH
    "empty_day": 40,                        # decisions with no plan by one actor in one day
    "walk_lost_day": 10,                    # navigation failures by one actor in one day
    "station_giveup_day": 10,               # waits given up at one station in one day (two or more actors: contention)
    "stuck_hours_medium": 12, "stuck_hours_high": 24,
    "starving_hours": 24, "starving_hunger": 15.0, "starving_coins": 10, "village_food_days": 1.0,
    "job_flip": 4, "job_flip_high": 8, "job_churn_30d": 10,
    "dup_trades": 5,                        # identical trades (buyer, detail) in one game minute
    "contract_fail_party": 5,
    "cascade_min": 20, "cascade_factor": 5.0,
    "deaths_day": 5,
}


def load_json(path, default=None):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def kv(detail, key):
    """The value of key=value in a recorder detail text ("item=log qty=1 total=2", "cause=old age; role=...")."""
    m = re.search(r"(?:^|[ ;])%s=([^;]*?)(?=(?: [a-z_]+=|;|$))" % re.escape(key), detail or "")
    return m.group(1).strip() if m else ""


def act_key(detail):
    """An action's target from its JSON args (the item bought, the recipe, the pen...), or its cell, or ""."""
    if not detail or detail[0] != "{":
        return ""
    try:
        a = json.loads(detail)
    except ValueError:
        return ""
    if not isinstance(a, dict):
        return ""
    for k in KEY_ARGS:
        if k in a:
            return "%s=%s" % (k, a[k])
    if "x" in a and "y" in a:
        return "cell=%s,%s" % (a["x"], a["y"])
    return ""


def pid(ref):
    try:
        return int(str(ref).split(":")[1])
    except (IndexError, ValueError):
        return -1


def is_villager(ref):
    return str(ref).startswith("p:") and 0 <= pid(ref) < PLAYER_BAND


class Segments:
    """The run's segments in order: (name, dir, status, sim.json path, log path, session dirs)."""

    def __init__(self, run_dir):
        segs = sorted((d for d in glob.glob(os.path.join(run_dir, "seg*")) if os.path.isdir(d)),
                      key=lambda d: int(re.sub(r"\D", "", os.path.basename(d)) or 0))
        if not segs:
            segs = [run_dir]
        self.list = []
        for d in segs:
            sessions = [s for s in glob.glob(os.path.join(d, "rec", "s*")) + glob.glob(os.path.join(d, "s*"))
                        if os.path.isfile(os.path.join(s, "session.json"))]
            sessions.sort(key=lambda s: (load_json(os.path.join(s, "session.json"), {}) or {}).get("start_unix", 0))
            self.list.append({"name": os.path.basename(d), "dir": d, "status": load_json(os.path.join(d, "status.json")),
                              "sim": os.path.join(d, "sim.json"), "log": os.path.join(d, "sim.log"), "sessions": sessions})

    def sessions(self):
        return [s for seg in self.list for s in seg["sessions"]]


class Finding:
    def __init__(self, severity, kind, title, systems, npc="", day_from=None, day_to=None, count=1, events=None, evidence=None,
                 confirmed=False):
        self.d = {"severity": severity, "confirmed": confirmed, "kind": kind, "title": title, "npc": npc, "day_from": day_from,
                  "day_to": day_to, "count": count, "systems": systems, "events": (events or [])[:10], "evidence": evidence or {}}


class Analyser:
    def __init__(self, defs, seed=None):
        self.defs = defs
        self.seed = seed
        self.classes = defs.get("activity_classes", {})
        self.f = []                                          # findings (Finding)
        self.counts = Counter()                              # category|subtype|outcome
        self.daily = defaultdict(lambda: defaultdict(float))   # day -> measure -> value
        self.snap_by_hour = {}                               # day*24+hour -> food_days
        self.last_snap = None
        # streaks
        self.fail = {}                                       # (actor, kind, key) -> state
        self.refused = {}                                    # (buyer, item) -> state
        self.act_totals = defaultdict(lambda: [0, 0])        # kind -> [ok, failed]
        self.trade_items = defaultdict(Counter)              # item -> outcome|reason -> n
        self.pp = {}                                         # actor -> ping-pong state
        self.pp_days = defaultdict(list)                     # actor -> [(day, run, A, B, first event)]
        self.empty = Counter()                               # (actor, day) -> empty decisions
        self.last_plan = {}                                  # actor -> (decision id, plan)
        self.walk_lost = Counter()                           # (actor, day) -> n
        self.walk_lost_plan = defaultdict(Counter)           # (actor, day) -> plan -> n
        self.walk_lost_ev = {}
        self.station = defaultdict(lambda: [0, set(), None])  # (station, day) -> [n, actors, first event]
        self.jobs = defaultdict(list)                        # ref -> [(day, before, after, event)]
        self.dup = Counter()
        self.dup_ev = {}
        self.contracts = {}                                  # contract -> {item, actor, states, day0, day1, ids}
        self.credit = Counter()
        self.deaths = []                                     # [day, minute, actor, cause, detail, event]
        self.births = 0
        self.arrivals = 0
        self.tills = Counter()
        self.chapel_acts = defaultdict(lambda: [0, 0])       # day -> [church_ask ok, failed]
        self.employment = Counter()
        self.civic = Counter()
        self.judgment = Counter()
        self.stuck = {}                                      # entity -> [x, y, cls, run, start day, start hour, doing]
        self.stuck_best = {}                                 # entity -> (hours, day, hour, doing, x, y)
        self.starve = {}                                     # entity -> [run, start day, start hour, coins min, hunger min, last hix]
        self.starve_best = {}
        self.hourly_fail = []                                # (hix, failed actions, walk lost)
        self.pending_trade = {}                              # event id -> (buyer, item) awaiting the seller participant
        self.alerts = Counter()
        self.alert_ex = {}
        self.rows_read = Counter()
        self.chunk_problems = []
        self.sessions = []
        self.cur_day = 0

    # ------------------------------------------------------------------ reading
    def read_session(self, sdir):
        sess = load_json(os.path.join(sdir, "session.json"), {}) or {}
        self.sessions.append({"dir": sdir, "session": sess.get("session"), "completeness": sess.get("completeness"),
                              "ended": sess.get("ended"), "bytes": sess.get("bytes"), "events": sess.get("events")})
        order = ["snapshot", "event", "participant", "state_change", "sample", "alert"]
        for ddir in sorted(glob.glob(os.path.join(sdir, "d*"))):
            self.cur_day = int(re.sub(r"\D", "", os.path.basename(ddir)) or 0)     # a session's directories are its game days
            files = defaultdict(list)
            for p in sorted(glob.glob(os.path.join(ddir, "*.jsonl.gz"))):
                files[os.path.basename(p).split(".")[0]].append(p)
            for table in order:
                for p in files.get(table, []):
                    head, rows, problem = ra.read_chunk(p)
                    if problem:
                        self.chunk_problems.append("%s: %s" % (os.path.relpath(p, sdir), problem))
                        if not rows or head is None:
                            continue                      # a torn chunk: what parsed before the tear is still read
                    ix = {c: i for i, c in enumerate(head["columns"])}
                    self.rows_read[table] += len(rows)
                    getattr(self, "on_" + table)(ix, rows)
            self.pending_trade.clear()

    def on_snapshot(self, ix, rows):
        for r in rows:
            s = {c: r[i] for c, i in ix.items()}
            day, hour = int(s["day"]), int(s["hour"])
            hix = day * 24 + hour
            self.snap_by_hour[hix] = s.get("food_days")
            dd = self.daily[day]
            for k in ("alive", "households", "adults", "employed", "children", "elders", "mean_hunger", "min_hunger", "starving",
                      "total_coins", "villager_coins", "treasury", "coin_sources", "hh_purse_min", "hh_purse_median", "hh_purse_max",
                      "food_days", "granary_wheat", "births", "deaths", "ties", "friends", "facts", "idle", "lost"):
                if isinstance(s.get(k), (int, float)):
                    dd[k] = s[k]
            for k in ("trades_h", "trade_coins_h", "transfers_h", "actions_h", "actions_failed_h", "walk_lost_h", "crimes_h", "chases_h", "alerts_h"):
                if isinstance(s.get(k), (int, float)):
                    dd[k] += s[k]
            if isinstance(s.get("starving"), (int, float)):
                dd["starving_hours"] += s["starving"]
            sd = s.get("stats_delta") or {}
            if isinstance(sd, dict):
                for k, v in sd.items():
                    if not isinstance(v, (int, float)):
                        continue
                    if k.startswith("chapel_"):
                        dd["stat:" + k] += v
                    elif k.startswith("eaten_"):
                        dd["eaten"] += v
                    elif k.startswith("spoiled_"):
                        dd["spoiled"] += v
                    elif k.startswith(("made_", "farm_harvest_", "keeper_collected_", "villager_foraged_", "hunted_")):
                        if any(f in k for f in FOOD):
                            dd["food_made"] += v
                    if k.startswith(("relief_", "manor_relief")):
                        dd["stat:" + k] += v
            self.hourly_fail.append((hix, s.get("actions_failed_h") or 0, s.get("walk_lost_h") or 0, s.get("actions_h") or 0))
            self.last_snap = s

    def on_event(self, ix, rows):
        I = ix
        for r in rows:
            cat, sub, out = r[I["category"]], r[I["subtype"]], r[I["outcome"]]
            day, minute, actor, eid = int(r[I["day"]]), r[I["minute"]], r[I["actor"]], r[I["id"]]
            detail, reason = r[I["detail"]] or "", r[I["reason"]] or ""
            self.counts["%s|%s|%s" % (cat, sub, out)] += 1
            if cat == "action":
                self.act_totals[sub][0 if out == "ok" else 1] += 1
                key = (actor, sub, act_key(detail))
                self._streak(self.fail, key, out == "ok", day, eid, extra=None)
                if sub == "church_ask":
                    self.chapel_acts[day][0 if out == "ok" else 1] += 1
                if out != "ok":
                    self.daily[day]["actions_failed"] += 1
            elif cat == "decision":
                self._decision(actor, day, eid, out, detail)
            elif cat == "transaction" and sub == "trade":
                item = kv(detail, "item")
                self.trade_items[item]["ok" if out == "ok" else "refused:" + reason] += 1
                self._streak(self.refused, (actor, item), out == "ok", day, eid, extra=reason)
                self.pending_trade[eid] = (actor, item)
                if out == "ok":
                    k = (actor, day, minute, detail)
                    self.dup[k] += 1
                    self.dup_ev.setdefault(k, eid)
                    self.daily[day]["trades_ok"] += 1
                else:
                    self.daily[day]["trades_refused"] += 1
            elif cat == "transaction" and sub.startswith("till"):
                self.tills[sub] += 1
            elif cat == "interruption":
                if sub == "walk_lost":
                    self.walk_lost[(actor, day)] += 1
                    lp = self.last_plan.get(actor)
                    self.walk_lost_plan[(actor, day)][lp[1] if lp else "?"] += 1
                    self.walk_lost_ev.setdefault((actor, day), eid)
                elif sub == "station_giveup":
                    st = self.station[(detail or "?", day)]
                    st[0] += 1
                    st[1].add(actor)
                    st[2] = st[2] or eid
            elif cat == "contract":
                obj = r[I["object"]]
                c = self.contracts.setdefault(obj, {"item": kv(detail, "item"), "actor": actor, "states": [], "day0": day, "day1": day, "ids": []})
                c["states"].append(sub)
                c["day1"] = day
                if len(c["ids"]) < 4:
                    c["ids"].append(eid)
                if kv(detail, "item") and not c["item"]:
                    c["item"] = kv(detail, "item")
            elif cat == "credit":
                self.credit[sub] += 1
            elif cat == "life":
                if sub == "death":
                    cause = kv(detail, "cause")
                    self.deaths.append([day, minute, actor, cause, detail[:200], eid])
                    if "role=bandit" not in detail:
                        self.daily[day]["villager_deaths"] += 1
                        self.daily[day]["death:" + ("starvation" if cause == "starvation" else "old age" if cause == "old age" else "other")] += 1
                elif sub == "birth":
                    self.births += 1
            elif cat == "identity" and sub in ("registered_newcomer", "registered_arrival", "returned_to_village", "registered_outlaw"):
                self.arrivals += 1
            elif cat == "employment":
                self.employment[sub] += 1
                self.daily[day]["employment:" + sub] += 1
            elif cat == "civic":
                self.civic[sub] += 1
            elif cat == "judgment":
                self.judgment["%s|%s" % (r[I["subsystem"]], sub)] += 1

    def on_participant(self, ix, rows):
        for r in rows:
            e = r[ix["event"]]
            if e in self.pending_trade and "seller" in str(r[ix["role"]]):
                buyer, item = self.pending_trade.pop(e)
                st = self.refused.get((buyer, item))
                if st is not None and st["cur"] > 0:
                    st["sellers"][r[ix["ref"]]] += 1

    def on_state_change(self, ix, rows):
        for r in rows:
            if r[ix["prop"]] == "job":
                ref = r[ix["ref"]]
                if is_villager(ref):
                    self.jobs[ref].append((self.cur_day, r[ix["before"]], r[ix["after"]], r[ix["event"]]))

    def on_alert(self, ix, rows):
        for r in rows:
            k = (r[ix["severity"]], r[ix["rule"]])
            self.alerts[k] += 1
            self.alert_ex.setdefault(k, {c: r[i] for c, i in ix.items()})

    def on_sample(self, ix, rows):
        for r in rows:
            ent = r[ix["entity"]]
            if not is_villager(ent):
                continue
            day, hour = int(r[ix["day"]]), int(r[ix["hour"]])
            hix = day * 24 + hour
            doing = r[ix["doing"]] or ""
            hunger, coins = r[ix["hunger"]], r[ix["coins"]]
            cls = self.activity_class(doing)
            self.daily[day]["villager_hours"] += 1
            self.daily[day]["hours:" + cls] += 1
            if isinstance(hunger, (int, float)) and hunger < 25:
                self.daily[day]["hungry_hours"] += 1
            # stuck: one cell, hour after hour, while travelling or lost
            x, y = r[ix["x"]], r[ix["y"]]
            st = self.stuck.get(ent)
            if st and st[0] == x and st[1] == y and st[2] == cls and cls in ("travel", "lost") and st[7] == hix - 1:
                st[3] += 1
                st[7] = hix
            else:
                st = [x, y, cls, 1, day, hour, doing, hix]
                self.stuck[ent] = st
            if cls in ("travel", "lost") and st[3] > self.stuck_best.get(ent, (0,))[0]:
                self.stuck_best[ent] = (st[3], st[4], st[5], st[6], x, y)
            # starving with coins while the village has food in store
            fd = self.snap_by_hour.get(hix)
            cond = (isinstance(hunger, (int, float)) and hunger < T["starving_hunger"] and isinstance(coins, (int, float))
                    and coins >= T["starving_coins"] and isinstance(fd, (int, float)) and fd >= T["village_food_days"])
            sv = self.starve.get(ent)
            if cond:
                if sv and sv[5] == hix - 1:
                    sv[0] += 1
                    sv[3] = min(sv[3], coins)
                    sv[4] = min(sv[4], hunger)
                    sv[5] = hix
                else:
                    sv = [1, day, hour, coins, hunger, hix, doing]
                    self.starve[ent] = sv
                if sv[0] > self.starve_best.get(ent, [0])[0]:
                    self.starve_best[ent] = list(sv) + [day, doing]
            elif sv:
                self.starve.pop(ent, None)

    def activity_class(self, doing):
        if doing == "":
            return "idle"
        for cls in self.classes.get("order", []):
            for pat in self.classes.get("patterns", {}).get(cls, []):
                if pat and pat in doing:
                    return cls
        return "work"

    # ------------------------------------------------------------------ streaks and decisions
    @staticmethod
    def _streak(table, key, ok, day, eid, extra):
        st = table.get(key)
        if st is None:
            st = {"cur": 0, "d0": day, "e0": eid, "d1": day, "e1": eid, "best": None, "ok": 0, "fail": 0, "dayn": 0, "dayd": day,
                  "bestday": (0, day, eid), "why": Counter(), "sellers": Counter()}
            table[key] = st
        if ok:
            st["ok"] += 1
            if st["cur"] and (st["best"] is None or st["cur"] > st["best"][0]):
                st["best"] = (st["cur"], st["d0"], st["d1"], st["e0"], st["e1"], dict(st["why"].most_common(3)), dict(st["sellers"].most_common(3)))
            st["cur"] = 0
            st["why"] = Counter()
            st["sellers"] = Counter()
            return
        st["fail"] += 1
        if st["cur"] == 0:
            st["d0"], st["e0"] = day, eid
        st["cur"] += 1
        st["d1"], st["e1"] = day, eid
        if extra:
            st["why"][extra] += 1
        if st["dayd"] != day:
            st["dayd"], st["dayn"] = day, 0
        st["dayn"] += 1
        if st["dayn"] > st["bestday"][0]:
            st["bestday"] = (st["dayn"], day, eid)

    @staticmethod
    def _best(st):
        b = st["best"]
        if st["cur"] and (b is None or st["cur"] > b[0]):
            b = (st["cur"], st["d0"], st["d1"], st["e0"], st["e1"], dict(st["why"].most_common(3)), dict(st["sellers"].most_common(3)))
        return b

    def _decision(self, actor, day, eid, out, detail):
        m = re.search(r"plan=(.*)$", detail)
        plan = m.group(1) if m else ""
        self.last_plan[actor] = (eid, plan)
        if out == "empty":
            self.empty[(actor, day)] += 1
        p = self.pp.get(actor)
        if p is None or p["day"] != day:
            if p is not None and p["best"] >= T["pingpong_day"]:
                self.pp_days[actor].append((p["day"], p["best"], p["A"], p["B"], p["ev"]))
            p = {"day": day, "prev2": None, "prev": None, "run": 1, "best": 0, "A": "", "B": "", "ev": eid, "start": eid}
            self.pp[actor] = p
        if p["prev2"] is not None and plan == p["prev2"] and plan != p["prev"]:
            p["run"] += 1
        else:
            p["run"] = 2 if p["prev"] is not None and plan != p["prev"] else 1
            p["start"] = eid
        if p["run"] > p["best"]:
            p["best"], p["A"], p["B"], p["ev"] = p["run"], p["prev"] or "", plan, p["start"]
        p["prev2"], p["prev"] = p["prev"], plan

    # ------------------------------------------------------------------ findings
    def add(self, *a, **k):
        self.f.append(Finding(*a, **k))

    def detect(self):
        # repeated failed actions (the villager trying to buy an axe hundreds of times)
        for (actor, kind, key), st in self.fail.items():
            b = self._best(st)
            if not b:
                continue
            n, d0, d1, e0, e1 = b[0], b[1], b[2], b[3], b[4]
            bd = st["bestday"]
            sev = None
            if n >= T["fail_streak_high"] or bd[0] >= T["fail_day_high"]:
                sev = "HIGH"
            elif n >= T["fail_streak_medium"] and d1 - d0 + 1 >= T["fail_streak_medium_days"]:
                sev = "MEDIUM"
            if sev:
                food = kind in FOOD_ACTS
                self.add(sev, "repeated_failed_action", "%s failed %s%s %d times in a row" % (actor, kind, (" (%s)" % key) if key else "", n),
                         ["NPC decisions", "actions"] + (["food and survival"] if food else []) + (["trade"] if kind.startswith("buy") else []),
                         npc=actor, day_from=d0, day_to=d1, count=n, events=[e0, e1, bd[2]],
                         evidence={"action": kind, "target": key, "longest_streak": n, "most_in_one_day": bd[0], "that_day": bd[1],
                                   "failed_total": st["fail"], "ok_total": st["ok"]})
        for (buyer, item), st in self.refused.items():
            b = self._best(st)
            if not b:
                continue
            n = b[0]
            sev = "HIGH" if n >= T["refused_streak_high"] else "MEDIUM" if n >= T["refused_streak_medium"] else None
            if sev and is_villager(buyer):
                self.add(sev, "repeated_failed_purchase", "%s was refused %s %d times in a row" % (buyer, item or "a trade", n),
                         ["trade", "economy"] + (["food and survival"] if item in FOOD else []), npc=buyer, day_from=b[1], day_to=b[2],
                         count=n, events=[b[3], b[4]], evidence={"item": item, "reasons": b[5], "sellers": b[6], "refused_total": st["fail"],
                                                                 "bought_total": st["ok"]})
        # villagers unable to buy necessities (village-wide)
        for item, c in self.trade_items.items():
            if item in FOOD:
                ref = sum(v for k, v in c.items() if k.startswith("refused"))
                if ref >= 50 and ref > c.get("ok", 0):
                    self.add("MEDIUM", "necessity_unbuyable", "%s: %d refused purchases against %d sales" % (item, ref, c.get("ok", 0)),
                             ["trade", "food and survival"], count=ref, evidence={"outcomes": dict(c)})
        # ping-pong between two plans
        for actor, p in self.pp.items():
            if p["best"] >= T["pingpong_day"]:
                self.pp_days[actor].append((p["day"], p["best"], p["A"], p["B"], p["ev"]))
        for actor, days in self.pp_days.items():
            worst = max(days, key=lambda x: x[1])
            sev = "HIGH" if len(days) >= T["pingpong_days_high"] else "MEDIUM"
            self.add(sev, "decision_oscillation", "%s alternated between two plans %d times in one day (on %d days)" % (actor, worst[1], len(days)),
                     ["NPC decisions"], npc=actor, day_from=min(d[0] for d in days), day_to=max(d[0] for d in days), count=len(days),
                     events=[worst[4]], evidence={"plan_a": worst[2], "plan_b": worst[3], "worst_day": worst[0], "alternations": worst[1],
                                                  "days": [d[0] for d in sorted(days)][:30]})
        # decisions with no plan
        by_actor = defaultdict(list)
        for (actor, day), n in self.empty.items():
            if n >= T["empty_day"]:
                by_actor[actor].append((day, n))
        for actor, days in by_actor.items():
            worst = max(days, key=lambda x: x[1])
            self.add("MEDIUM", "empty_decisions", "%s decided with no plan %d times in one day (on %d days)" % (actor, worst[1], len(days)),
                     ["NPC decisions"], npc=actor, day_from=min(d for d, _ in days), day_to=max(d for d, _ in days), count=sum(n for _, n in days),
                     evidence={"worst_day": worst[0], "days": sorted(days)[:20]})
        # impossible tasks: navigation failures
        wl = defaultdict(list)
        for (actor, day), n in self.walk_lost.items():
            if n >= T["walk_lost_day"]:
                wl[actor].append((day, n, dict(self.walk_lost_plan[(actor, day)].most_common(3)), self.walk_lost_ev[(actor, day)]))
        for actor, days in wl.items():
            worst = max(days, key=lambda x: x[1])
            self.add("HIGH" if len(days) >= 3 else "MEDIUM", "impossible_task", "%s could not reach their goal %d times in one day (on %d days)" % (
                actor, worst[1], len(days)), ["NPC decisions", "navigation"], npc=actor, day_from=min(d[0] for d in days),
                day_to=max(d[0] for d in days), count=sum(d[1] for d in days), events=[worst[3]],
                evidence={"worst_day": worst[0], "plans": worst[2], "days": [d[0] for d in sorted(days)][:20]})
        # station contention
        for (stn, day), (n, actors, ev) in self.station.items():
            if n >= T["station_giveup_day"]:
                self.add("MEDIUM", "station_contention", "station %s: %d waits given up on day %d by %d villagers" % (stn, n, day, len(actors)),
                         ["work stations", "NPC decisions"], npc=",".join(sorted(actors)[:5]), day_from=day, day_to=day, count=n, events=[ev],
                         evidence={"station": stn, "actors": sorted(actors)[:10]})
        # stuck villagers
        for ent, (h, day, hour, doing, x, y) in self.stuck_best.items():
            if h >= T["stuck_hours_medium"]:
                self.add("HIGH" if h >= T["stuck_hours_high"] else "MEDIUM", "stuck_npc", "%s stayed on one cell for %d hours while '%s'" % (ent, h, doing),
                         ["navigation", "NPC decisions"], npc=ent, day_from=day, day_to=day + h // 24, count=h,
                         evidence={"from_day": day, "from_hour": hour, "doing": doing, "cell": [x, y]})
        # starving with coins while the village has food
        for ent, sv in self.starve_best.items():
            if sv[0] >= T["starving_hours"]:
                self.add("HIGH", "starving_with_means", "%s stayed below hunger %d for %d hours with %d+ coins while the village had food" % (
                    ent, T["starving_hunger"], sv[0], sv[3]), ["food and survival", "trade", "NPC decisions"], npc=ent, day_from=sv[1],
                    day_to=sv[1] + sv[0] // 24, count=sv[0], evidence={"from_day": sv[1], "from_hour": sv[2], "coins_min": sv[3],
                                                                         "hunger_min": sv[4], "doing": sv[6]})
        # employment: flip-flops and churn
        for ref, ch in self.jobs.items():
            if len(ch) < T["job_flip"]:
                continue
            pairs = Counter(frozenset((b, a)) for _, b, a, _ in ch if b != a)
            pair, n = pairs.most_common(1)[0]
            if n >= T["job_flip"]:
                self.add("HIGH" if n >= T["job_flip_high"] else "MEDIUM", "job_oscillation", "%s switched between %s %d times" % (
                    ref, " and ".join(sorted(str(x) or "no job" for x in pair)), n), ["employment", "NPC decisions"], npc=ref, count=n,
                    day_from=ch[0][0], day_to=ch[-1][0],
                    events=[e for _, _, _, e in ch][:6], evidence={"changes": [[b, a] for _, b, a, _ in ch][:20], "total_changes": len(ch)})
            elif len(ch) >= T["job_churn_30d"]:
                self.add("MEDIUM", "job_churn", "%s changed job %d times" % (ref, len(ch)), ["employment"], npc=ref, count=len(ch),
                         day_from=ch[0][0], day_to=ch[-1][0],
                         events=[e for _, _, _, e in ch][:6], evidence={"changes": [[b, a] for _, b, a, _ in ch][:20]})
        # duplicate payments
        for (actor, day, minute, detail), n in self.dup.items():
            if n >= T["dup_trades"]:
                self.add("MEDIUM", "duplicate_trades", "%s made the same trade %d times in one game minute (%s)" % (actor, n, detail),
                         ["trade", "economy"], npc=actor, day_from=day, day_to=day, count=n, events=[self.dup_ev[(actor, day, minute, detail)]],
                         evidence={"minute": minute, "detail": detail})
        # contracts failing repeatedly for the same party and item
        cf = defaultdict(lambda: [0, 0, [], [], []])     # (party, item) -> [failed, fulfilled, contracts, days, events]
        for obj, c in self.contracts.items():
            k = (c["actor"], c["item"])
            if any(s in ("cancelled", "lapsed") for s in c["states"]):
                cf[k][0] += 1
                cf[k][2].append(obj)
                cf[k][3] += [c["day0"], c["day1"]]
                cf[k][4] += c["ids"][:1]
            if "fulfilled" in c["states"]:
                cf[k][1] += 1
        for (actor, item), (bad, good, objs, days, evs) in cf.items():
            if bad >= T["contract_fail_party"] and good == 0:
                self.add("MEDIUM", "contracts_failing", "%s: %d contracts for %s failed, none fulfilled" % (actor, bad, item or "goods"),
                         ["contracts", "economy"], npc=actor, count=bad, day_from=min(days), day_to=max(days), events=evs,
                         evidence={"contracts": objs[:10], "states": dict(Counter(st for o in objs for st in self.contracts[o]["states"]))})
        # cascades: hours with far more failures than usual
        fails = sorted(x[1] for x in self.hourly_fail if x[1])
        if fails:
            med = fails[len(fails) // 2]
            lim = max(T["cascade_min"], T["cascade_factor"] * med)
            spikes = [x for x in self.hourly_fail if x[1] >= lim]
            if spikes:
                worst = max(spikes, key=lambda x: x[1])
                self.add("MEDIUM", "failure_cascade", "%d hours with %d+ failed actions (usual hour: %d); worst day %d hour %d: %d" % (
                    len(spikes), lim, med, worst[0] // 24, worst[0] % 24, worst[1]), ["NPC decisions", "system interaction"],
                    day_from=spikes[0][0] // 24, day_to=spikes[-1][0] // 24, count=len(spikes),
                    evidence={"hours": [[x[0] // 24, x[0] % 24, x[1]] for x in spikes[:20]], "median_failed_per_hour": med})
        # death clusters (outcomes; violent or sudden ones worth a look)
        dd = Counter(d[0] for d in self.deaths if "role=bandit" not in d[4])
        for day, n in sorted(dd.items()):
            if n >= T["deaths_day"]:
                causes = Counter(d[3] for d in self.deaths if d[0] == day and "role=bandit" not in d[4])
                sev = "MEDIUM" if sum(v for k, v in causes.items() if k not in ("old age", "starvation")) >= T["deaths_day"] else "INFORMATIONAL"
                self.add(sev, "death_cluster", "%d villagers died on day %d" % (n, day), ["life", "food and survival"], day_from=day, day_to=day,
                         count=n, events=[d[5] for d in self.deaths if d[0] == day][:10], evidence={"causes": dict(causes)})
        # recorder alerts
        for (sev, rule), n in self.alerts.items():
            ex = self.alert_ex[(sev, rule)]
            if rule == "identity.ids_changed_on_load":
                self.add("CRITICAL", "identity_on_load", "people's ids changed on load (%d)" % n, ["save and load", "identity"], count=n,
                         day_from=ex.get("day"), evidence=ex, confirmed=True)
            elif rule == "coin.unattributed_total":
                self.add("HIGH", "coins_unattributed_total", "the world's coin total changed %d times without a recorded cause" % n,
                         ["currency", "recorder"], count=n, day_from=ex.get("day"), events=[ex.get("event")], evidence=ex)
            elif rule == "coin.unattributed_holder":
                self.add("INFORMATIONAL", "coins_unattributed_holder", "%d holder balances moved at coin sites the recorder does not instrument" % n,
                         ["currency", "recorder coverage"], count=n, day_from=ex.get("day"), evidence=ex)
            else:
                self.add("MEDIUM" if sev in ("violation", "error") else "INFORMATIONAL", "alert", "recorder alert %s (%s): %d" % (rule, sev, n),
                         ["recorder"], count=n, day_from=ex.get("day"), evidence=ex)
        if self.chunk_problems:
            self.add("CRITICAL", "archive_chunks", "%d archive chunks could not be read whole" % len(self.chunk_problems), ["recorder"],
                     count=len(self.chunk_problems), evidence={"first": self.chunk_problems[:10]}, confirmed=True)

    def chapel(self, chapel_lines, abnormal):
        """Chapel relief against the households in hardship (Diag household_hardship), window by window between checkpoints."""
        hard = [f for f in abnormal if f.get("kind") == "household_hardship"]
        prev = None
        for c in chapel_lines:
            if prev is not None:
                d0, d1 = prev["day"], c["day"]
                hh = sorted({f["actor"] for f in hard if d0 < (f["evidence"].get("to_day") or f["day"]) and f["day"] <= d1})
                food, pfood = c.get("food", {}), prev.get("food", {})
                st, pst = c.get("stats", {}), prev.get("stats", {})
                relieved = (food.get("relieved", 0) - pfood.get("relieved", 0)) + (food.get("food_alms_households", 0) - pfood.get("food_alms_households", 0)) \
                    + (st.get("alms_households", 0) - pst.get("alms_households", 0))
                able = (c.get("fund", 0) or 0) > (c.get("reserve_now", 0) or 0) or (c.get("store_points", 0) or 0) > 0
                if hh and relieved == 0 and able:
                    self.add("MEDIUM", "chapel_relief_missed", "days %d-%d: %d households in hardship, the chapel relieved none (fund %s, store %s points)" % (
                        d0 + 1, d1, len(hh), c.get("fund"), c.get("store_points")), ["chapel", "food and survival"], npc=",".join(hh[:5]),
                        day_from=d0 + 1, day_to=d1, count=len(hh), evidence={"households": hh[:20], "fund": c.get("fund"), "reserve_now": c.get("reserve_now"),
                                                                              "store_points": c.get("store_points"), "asked": food.get("asked", 0) - pfood.get("asked", 0)})
                asked = food.get("asked", 0) - pfood.get("asked", 0)
                got = food.get("relieved", 0) - pfood.get("relieved", 0)
                if asked >= 10 and got == 0:
                    self.add("MEDIUM", "chapel_asked_unanswered", "days %d-%d: villagers asked the chapel for food %d times and none was relieved" % (
                        d0 + 1, d1, asked), ["chapel", "food and survival"], day_from=d0 + 1, day_to=d1, count=asked,
                        evidence={"store_points": c.get("store_points"), "fund": c.get("fund")})
            prev = c


def parse_log(path):
    """The simulation log's machine lines: FATAL, EXTINCT, SEGMENT, script errors, CONFIG, and the checkpoint JSON lines."""
    out = {"fatal": [], "extinct": [], "script_errors": 0, "script_error_first": [], "chapel": [], "jobs": [], "biz": [], "funnel": [],
           "config": None, "day_lines": [], "resumed": [], "status": None}
    if not os.path.isfile(path):
        return out
    with open(path, errors="replace") as f:
        lines = f.read().split("\n")
    for i, line in enumerate(lines):
        if line.startswith("FATAL"):
            out["fatal"].append(line[:2000])
        elif line.startswith("EXTINCT"):
            out["extinct"].append(line[:400])
        elif line.startswith("resumed:"):
            out["resumed"].append(line[:400])
        elif "SCRIPT ERROR" in line:
            out["script_errors"] += 1
            if len(out["script_error_first"]) < 3:
                out["script_error_first"].append("\n".join(lines[i:i + 6])[:1200])
        elif re.match(r"^day +\d+:", line):
            out["day_lines"].append(line[:300])
        else:
            for tag, key in (("CHAPEL ", "chapel"), ("JOBS ", "jobs"), ("BIZ ", "biz"), ("FUNNEL ", "funnel"), ("CONFIG ", "config"), ("STATUS ", "status")):
                if line.startswith(tag):
                    try:
                        v = json.loads(line[len(tag):])
                    except ValueError:
                        break
                    if key in ("config", "status"):
                        out[key] = v
                    else:
                        out[key].append(v)
                    break
    return out


def run_status(segs, logs):
    """The run's status: commit, seed, days requested and reached, why it stopped, with each segment's own record."""
    st = {"segments": [], "stop_reason": "unknown", "days_reached": 0, "days_requested": None, "commit": None, "seed": None, "args": ""}
    for seg, lg in zip(segs.list, logs):
        s = seg["status"] or lg.get("status") or {}
        row = {"segment": seg["name"], "stop_reason": s.get("stop_reason") or "no status (crash or timeout)", "start_day": s.get("start_day"),
               "days_reached": s.get("days_reached"), "ok": s.get("ok"), "wall_seconds": s.get("wall_seconds"),
               "exit_code": s.get("exit_code"), "fatal": lg["fatal"][:2], "script_errors": lg["script_errors"]}
        st["segments"].append(row)
        for k in ("commit", "seed", "args"):
            st[k] = s.get(k) or st[k]
        st["days_requested"] = s.get("days_requested") or st["days_requested"]
        if s.get("days_reached"):
            st["days_reached"] = s["days_reached"]
        st["stop_reason"] = row["stop_reason"]
        if s.get("stop_reason") in ("fatal", "extinct", "completed", "crash", "timeout") or not s:
            break
    st["segments_run"] = len(st["segments"])
    return st


def build(run_dir, out_dir, verify=True):
    defs = load_json(DEFS, {}) or {}
    segs = Segments(run_dir)
    logs = [parse_log(s["log"]) for s in segs.list]
    status = run_status(segs, logs)
    an = Analyser(defs, status.get("seed"))
    # 1. the archive's own checks (tools/recorder_archive.py), session by session
    checks, abnormal, redecisions = [], [], []
    for sdir in segs.sessions():
        if verify:
            r = ra.verify(sdir)
            checks.append({"session": os.path.basename(sdir), "ok": r["ok"], "problems": r["problems"][:20], "bytes": r["bytes"],
                           "chunks": r["chunks"], "snapshot_hours": r["snapshot_hours"], "contracts": r.get("contracts"),
                           "redecisions": r.get("redecisions"), "flags": r.get("flags"), "exercised": r.get("exercised"),
                           "villager_deaths": r.get("villager_deaths"), "births": r.get("births"), "newcomers": r.get("newcomers")})
            abnormal += (r.get("abnormal") or {}).get("findings", [])
            redecisions.append(r.get("redecisions"))
            for p in r["problems"]:
                cut = "never ended" in p or "completeness" in p
                an.add("HIGH" if cut else "CRITICAL", "archive_check", "%s: %s" % (os.path.basename(sdir), p), ["recorder"] if cut else ["recorder", "simulation integrity"],
                       evidence={"session": sdir}, confirmed=not cut)
        an.read_session(sdir)
    # 2. the simulation's own integrity (the harness ledgers, crashes, script errors)
    for seg, lg in zip(segs.list, logs):
        s = seg["status"] or {}
        for line in lg["fatal"]:
            an.add("CRITICAL", "ledger_broken", line[:300], ["currency", "inventory", "simulation integrity"], confirmed=True,
                   day_from=int(re.search(r"day (\d+)", line).group(1)) if re.search(r"day (\d+)", line) else None, evidence={"segment": seg["name"], "line": line[:2000]})
        if lg["script_errors"]:
            an.add("CRITICAL", "script_errors", "%d script errors in %s" % (lg["script_errors"], seg["name"]), ["simulation integrity"], count=lg["script_errors"],
                   confirmed=True, evidence={"first": lg["script_error_first"]})
        if s.get("econ_roundtrip_bad"):
            an.add("CRITICAL", "economy_save_roundtrip", "the economy section did not load back exactly at %d checkpoints" % s["econ_roundtrip_bad"],
                   ["save and load", "economy"], count=s["econ_roundtrip_bad"], confirmed=True)
        if s and s.get("stop_reason") in ("crash", "timeout"):
            an.add("CRITICAL" if s["stop_reason"] == "crash" else "HIGH", "run_" + s["stop_reason"], "%s: the simulation %s (exit %s) after day %s" % (
                seg["name"], "crashed" if s["stop_reason"] == "crash" else "ran out of time", s.get("exit_code"), s.get("days_reached")),
                ["simulation integrity"] if s["stop_reason"] == "crash" else ["infrastructure"], confirmed=s["stop_reason"] == "crash",
                day_from=s.get("days_reached"), evidence={"segment": seg["name"], "status": s})
        if s.get("stop_reason") == "extinct":
            an.add("INFORMATIONAL", "village_extinct", "the village died out: no villager alive from day %s; the run stopped on day %s" % (
                s.get("extinct_since"), s.get("days_reached")), ["life", "population"], day_from=s.get("extinct_since"), day_to=s.get("days_reached"),
                evidence={"lines": lg["extinct"][:3]})
    # 3. the whole archive, searched
    an.detect()
    an.chapel([c for lg in logs for c in lg["chapel"]], abnormal)
    diag_map = {"starved_with_means": ("HIGH", ["food and survival"]), "settlement_hunger_death": ("INFORMATIONAL", ["settlements"]),
                "settlement_no_household_left_death": ("INFORMATIONAL", ["settlements"]), "till_without_owner": ("MEDIUM", ["business", "economy"]),
                "starved_without_means": ("INFORMATIONAL", ["food and survival"]), "violent_or_accidental_death": ("INFORMATIONAL", ["life", "crime"])}
    for k, n in Counter(f["kind"] for f in abnormal).items():
        sev, systems = diag_map.get(k, ("INFORMATIONAL", ["economy"]))
        ex = [f for f in abnormal if f["kind"] == k]
        an.add(sev, "diag_" + k, "%s: %d (recorder_archive.py abnormal-run evidence)" % (k.replace("_", " "), n), systems, npc=ex[0].get("actor", ""),
               day_from=min(f["day"] for f in ex), day_to=max(f["day"] for f in ex), count=n,
               evidence={"examples": [{x: f.get(x) for x in ("day", "actor", "evidence", "chain")} for f in ex[:5]]})
    # the population's story, for the record
    last_day = max(an.daily) if an.daily else 0
    ld = an.daily.get(last_day, {})
    fd = an.daily.get(min(an.daily), {}) if an.daily else {}
    causes = Counter(d[3] for d in an.deaths if "role=bandit" not in d[4])
    an.add("INFORMATIONAL", "population", "villagers %s at the start, %s on day %s; %d deaths (%s), %d births, %d arrivals" % (
        fd.get("alive"), ld.get("alive"), last_day, sum(causes.values()), ", ".join("%s %d" % kv_ for kv_ in causes.most_common(5)), an.births, an.arrivals),
        ["life", "population"], day_from=min(an.daily) if an.daily else None, day_to=last_day, count=sum(causes.values()), evidence={"causes": dict(causes)})
    findings = [x.d for x in an.f]
    for i, fnd in enumerate(sorted(findings, key=lambda x: (SEVERITIES.index(x["severity"]), -(x["count"] or 0)))):
        fnd["id"] = "F%03d" % (i + 1)
    findings.sort(key=lambda x: x["id"])
    repro_args = "--days %s --seed %s --every 10 --record DIR%s" % (status.get("days_requested") or 365, status.get("seed"),
                                                                    (" " + " ".join(a for a in (status.get("args") or "").split() if a in ("--market", "--economy", "--no-judgment", "--aspiration", "--job-choice"))))
    for fnd in findings:
        fnd["reproduce"] = "commit %s; godot --headless --path game --script res://tests/economy_sim.gd -- %s; read events %s around day %s" % (
            status.get("commit"), repro_args, fnd["events"][:3] or "-", fnd["day_from"])
    sev_counts = Counter(f["severity"] for f in findings)
    result = {"format": "mml-flight-findings/1", "status": status, "severity_counts": {s: sev_counts.get(s, 0) for s in SEVERITIES},
              "confirmed_defects": sum(1 for f in findings if f["confirmed"]), "archive_checks": checks, "sessions": an.sessions,
              "rows_read": dict(an.rows_read), "thresholds": T, "findings": findings, "redecisions": redecisions,
              "note": "CRITICAL findings are confirmed defects; every other finding is a suspicion or an observation with its evidence (WDR-022: a village may fail)."}
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "findings.json"), "w") as f:
        json.dump(result, f, indent=1, default=str)
    with open(os.path.join(out_dir, "findings.md"), "w") as f:
        f.write(report_md(result))
    wb = workbook_spec(result, an, logs, checks)
    with open(os.path.join(out_dir, "workbook_data.json"), "w") as f:
        json.dump(wb, f, default=str)
    top = [{k: x[k] for k in ("id", "severity", "confirmed", "title", "npc", "day_from", "count")} for x in findings if x["severity"] != "INFORMATIONAL"][:10]
    summary = {"format": "mml-flight-summary/1", "commit": status.get("commit"), "seed": status.get("seed"), "days_requested": status.get("days_requested"),
               "days_reached": status.get("days_reached"), "stop_reason": status.get("stop_reason"), "severity_counts": result["severity_counts"],
               "confirmed_defects": result["confirmed_defects"], "archive_ok": all(c["ok"] for c in checks) if checks else None, "top_findings": top}
    with open(os.path.join(out_dir, "summary.json"), "w") as f:
        json.dump(summary, f, indent=1, default=str)
    return result, summary


def report_md(r):
    st = r["status"]
    L = ["# Flight recorder findings: seed %s" % st.get("seed"), "",
         "- Commit: `%s`" % st.get("commit"), "- Days: %s of %s reached; stopped: **%s**" % (st.get("days_reached"), st.get("days_requested"), st.get("stop_reason")),
         "- Segments: " + "; ".join("%s %s (day %s to %s)" % (s["segment"], s["stop_reason"], s["start_day"], s["days_reached"]) for s in st["segments"]),
         "- Findings: " + ", ".join("%s %d" % (k, v) for k, v in r["severity_counts"].items()) + "; confirmed defects %d" % r["confirmed_defects"],
         "- Archive checks: " + ("; ".join("%s %s" % (c["session"], "ok" if c["ok"] else "PROBLEMS") for c in r["archive_checks"]) or "not run"),
         "- Rows read (whole archive): " + ", ".join("%s %d" % kv_ for kv_ in sorted(r["rows_read"].items())), "",
         "CRITICAL findings are confirmed defects. HIGH and MEDIUM are suspicions with evidence to investigate, not proven bugs. "
         "A village may fail; the simulation may not (WDR-022).", ""]
    for sev in SEVERITIES:
        fs = [f for f in r["findings"] if f["severity"] == sev]
        if not fs:
            continue
        L.append("## %s (%d)" % (sev, len(fs)))
        L.append("")
        cap = 40 if sev != "INFORMATIONAL" else 25
        for f in sorted(fs, key=lambda x: -(x["count"] or 0))[:cap]:
            days = "day %s" % f["day_from"] if f["day_to"] in (None, f["day_from"]) else "days %s-%s" % (f["day_from"], f["day_to"])
            L.append("- **%s** %s%s. %s; count %s; systems: %s; events %s." % (f["id"], f["title"], " (confirmed)" if f["confirmed"] else "",
                                                                             days, f["count"], ", ".join(f["systems"]), f["events"][:3] or "-"))
            ev = json.dumps(f["evidence"], default=str)
            L.append("  - evidence: `%s`" % (ev[:400] + ("..." if len(ev) > 400 else "")))
        if len(fs) > cap:
            L.append("- ... %d more in findings.json" % (len(fs) - cap))
        L.append("")
    return "\n".join(L) + "\n"


# ---------------------------------------------------------------- the workbook (14 sheets) -------
def _r(v, nd=2):
    return round(v, nd) if isinstance(v, float) else v


def workbook_spec(r, an, logs, checks):
    """The analysis workbook as sheets of blocks {title, header, rows, charts}; game/tests/flight_workbook.gd writes it with the game's
    one XLSX writer (workbook_builder.gd build_spec). Charts name 0-based columns of their block; rows run from the block's header."""
    days = sorted(an.daily)
    D = an.daily
    st = r["status"]
    findings = r["findings"]
    sheets = []

    FW = [7, 13, 10, 60, 12, 8, 8, 8, 26, 22, 70, 50]          # column widths of a sheet led by a findings table

    def sheet(name, blocks, widths=None):
        sheets.append({"name": name, "blocks": [b for b in blocks if b], "widths": widths or []})

    def blk(title, header, rows, charts=None, cap=5000):
        return {"title": title, "header": header, "rows": [[_r(v) for v in row] for row in rows[:cap]], "charts": charts or []}

    def frow(f):
        return [f["id"], f["severity"], "confirmed" if f["confirmed"] else "suspected", f["title"], f["npc"], f["day_from"], f["day_to"], f["count"],
                ", ".join(f["systems"]), json.dumps(f["events"][:5]), json.dumps(f["evidence"], default=str)[:600], f.get("reproduce", "")]

    fhead = ["id", "severity", "status", "finding", "NPC", "from day", "to day", "count", "systems", "events", "evidence", "reproduce"]
    top = [f for f in findings if f["severity"] != "INFORMATIONAL"]
    # 1. Executive summary
    sheet("Executive Summary", [
        blk("", ["item", "value"], [["what this is", "Flight recorder campaign run (FLIGHT-REC-01): one seed, normal integrated play, the whole archive analysed"],
                                     ["commit", st.get("commit")], ["seed", st.get("seed")], ["days requested", st.get("days_requested")],
                                     ["days reached", st.get("days_reached")], ["stop reason", st.get("stop_reason")],
                                     ["segments", "; ".join("%s: %s day %s-%s" % (s["segment"], s["stop_reason"], s["start_day"], s["days_reached"]) for s in st["segments"])],
                                     ["findings", ", ".join("%s %d" % kv_ for kv_ in r["severity_counts"].items())],
                                     ["confirmed defects", r["confirmed_defects"]],
                                     ["archive checks", "all ok" if checks and all(c["ok"] for c in checks) else ("not run" if not checks else "PROBLEMS: see Currency and Inventory Integrity")],
                                     ["villagers start / end", "%s / %s" % (D[days[0]].get("alive") if days else None, D[days[-1]].get("alive") if days else None)],
                                     ["read me", "A village is allowed to fail; the simulation is not (WDR-022). CRITICAL = confirmed defect; HIGH and MEDIUM = suspicions with evidence; INFORMATIONAL = observations."]]),
        blk("Most significant findings", ["finding", "what", "NPC", "from day", "to day", "count", "systems", "events", "evidence", "reproduce"],
            [["%s %s %s" % (f["id"], f["severity"], "confirmed" if f["confirmed"] else "suspected"), f["title"], f["npc"], f["day_from"], f["day_to"], f["count"],
              ", ".join(f["systems"]), json.dumps(f["events"][:5]), json.dumps(f["evidence"], default=str)[:600], f.get("reproduce", "")] for f in top[:25]]
            or [["none", "no CRITICAL, HIGH or MEDIUM finding", "", None, None, 0, "", "", "", ""]]),
    ], [32, 90, 14, 9, 9, 8, 26, 22, 70, 50])
    # 2. Population and survival
    pop = [[d, D[d].get("alive"), D[d].get("households"), D[d].get("adults"), D[d].get("children"), D[d].get("elders"), D[d].get("births"),
            D[d].get("deaths"), D[d].get("villager_deaths", 0), D[d].get("death:starvation", 0), _r(D[d].get("mean_hunger")), D[d].get("starving_hours", 0),
            D[d].get("hungry_hours", 0)] for d in days]
    sheet("Population and Survival", [
        blk("", ["day", "villagers alive", "households", "adults", "children", "elders", "births (since start)", "deaths (since start)", "deaths that day",
                 "starvation deaths that day", "mean hunger", "starving villager-hours", "hungry villager-hours (<25)"], pop,
            [{"type": "line", "title": "Population over the year", "y_cols": [1, 2], "y_title": "people"},
             {"type": "line", "title": "Hunger and starvation", "y_cols": [10, 11], "y_title": "hunger / hours"}]),
    ])
    # 3. Food
    food = [[d, _r(D[d].get("food_days")), D[d].get("granary_wheat"), D[d].get("food_made", 0), D[d].get("eaten", 0), D[d].get("spoiled", 0),
             D[d].get("starving_hours", 0)] for d in days]
    sheet("Food Production and Use", [
        blk("", ["day", "food days in store", "granary wheat", "food made (units)", "food eaten (points)", "spoiled", "starving villager-hours"], food,
            [{"type": "line", "title": "Food in store", "y_cols": [1], "y_title": "days of the village's need"},
             {"type": "line", "title": "Food made and eaten", "y_cols": [3, 4], "y_title": "units / points"}]),
        blk("Purchases of food by item", ["item", "sold", "refused (all reasons)", "outcomes"],
            [[i, c.get("ok", 0), sum(v for k, v in c.items() if k.startswith("refused")), json.dumps(dict(c))] for i, c in sorted(an.trade_items.items()) if i in FOOD]),
    ])
    # 4. Economy and employment
    emp = [[d, D[d].get("adults"), D[d].get("employed"), D[d].get("total_coins"), D[d].get("villager_coins"), D[d].get("treasury"), D[d].get("hh_purse_median"),
            D[d].get("hh_purse_min"), D[d].get("employment:job_switched", 0) + D[d].get("employment:job_taken", 0) + D[d].get("employment:job_lost", 0)] for d in days]
    jobs = [lg for l in logs for lg in l["jobs"]]
    sheet("Economy and Employment", [
        blk("", ["day", "adults", "employed", "currency in the world", "villagers' coins", "treasury", "median household purse", "poorest household purse", "job changes"], emp,
            [{"type": "line", "title": "Employment", "y_cols": [1, 2], "y_title": "people"},
             {"type": "line", "title": "Currency and treasury", "y_cols": [3, 5], "y_title": "coins"}]),
        blk("Employment events (whole run)", ["event", "count"], sorted(an.employment.items())),
        blk("Job market at each checkpoint (sim.log JOBS)", ["day", "job changes", "looked and found none", "migrants in", "migrants out", "by job"],
            [[j.get("day"), j.get("job_changes"), j.get("looked_found_none"), j.get("migrants_in"), j.get("migrants_out"), json.dumps(j.get("by_job"))] for j in jobs]),
    ])
    # 5. Businesses and trade
    biz = [lg for l in logs for lg in l["biz"]]
    sheet("Businesses and Trade", [
        blk("", ["day", "trades", "refused trades", "coins traded", "transfers"], [[d, D[d].get("trades_ok", 0), D[d].get("trades_refused", 0), D[d].get("trade_coins_h", 0),
                                                                                D[d].get("transfers_h", 0)] for d in days],
            [{"type": "line", "title": "Trade activity", "y_cols": [1, 2], "y_title": "trades a day"}]),
        blk("Trades by item", ["item", "sold", "refused", "outcomes"],
            [[i, c.get("ok", 0), sum(v for k, v in c.items() if k.startswith("refused")), json.dumps(dict(c))] for i, c in sorted(an.trade_items.items(), key=lambda kv_: -sum(kv_[1].values()))]),
        blk("Till movements (businesses, stalls, counters)", ["till event", "count"], sorted(an.tills.items())),
        blk("Businesses at each checkpoint (sim.log BIZ)", ["day", "open", "setting up", "stats"], [[b.get("day"), b.get("open"), b.get("setting_up"), json.dumps(b.get("stats"))] for b in biz]),
    ])
    # 6. Chapel
    ch = [lg for l in logs for lg in l["chapel"]]
    sheet("Chapel and Relief", [
        blk("", ["day", "chapel fund", "operating reserve", "store (food points)", "services", "offering coins", "alms coins", "alms households", "food asked",
                 "food relieved", "food alms households", "relief bought"],
            [[c.get("day"), c.get("fund"), c.get("reserve_now"), c.get("store_points"), (c.get("stats") or {}).get("services"), (c.get("stats") or {}).get("offering_coins"),
              (c.get("stats") or {}).get("alms_coins"), (c.get("stats") or {}).get("alms_households"), (c.get("food") or {}).get("asked"), (c.get("food") or {}).get("relieved"),
              (c.get("food") or {}).get("food_alms_households"), (c.get("stats") or {}).get("relief_bought")] for c in ch] or [[None] * 12],
            [{"type": "line", "title": "Chapel fund and alms", "y_cols": [1, 6], "y_title": "coins"}]),
        blk("Villagers asking the chapel for food (church_ask actions)", ["day", "ok", "failed"], [[d, v[0], v[1]] for d, v in sorted(an.chapel_acts.items())]),
        blk("Chapel findings", fhead, [frow(f) for f in findings if "chapel" in f["systems"]]),
    ])
    # 7. Contracts and credit
    states = Counter(s for c in an.contracts.values() for s in c["states"])
    sheet("Contracts and Credit", [
        blk("", ["contract or debt event", "count"], sorted(states.items()) + [["credit " + k, v] for k, v in sorted(an.credit.items())] or [["none", 0]]),
        blk("Contracts by item", ["item", "contracts", "fulfilled", "failed (cancelled or lapsed)"],
            sorted([[it, n[0], n[1], n[2]] for it, n in _contract_items(an).items()], key=lambda x: -x[1])),
        blk("Contract findings", fhead, [frow(f) for f in findings if "contracts" in f["systems"]]),
        blk("Archive contract checks (recorder_archive.py)", ["session", "contracts"], [[c["session"], json.dumps(c.get("contracts"))] for c in checks]),
    ])
    # 8. NPC behaviour and decisions
    acts = sorted(an.act_totals.items(), key=lambda kv_: -(kv_[1][0] + kv_[1][1]))
    sheet("NPC Behaviour and Decisions", [
        blk("", ["day", "work", "travel", "idle", "lost", "rest and leisure", "need", "sleep", "villager-hours"],
            [[d] + [D[d].get("hours:" + k, 0) for k in ("work", "travel", "idle", "lost", "rest and leisure", "need", "sleep")] + [D[d].get("villager_hours", 0)] for d in days],
            [{"type": "line", "title": "How villagers spent their hours", "y_cols": [1, 2, 3, 6], "y_title": "villager-hours"}]),
        blk("Actions (whole archive)", ["action", "ok", "failed", "failure share"], [[k, v[0], v[1], _r(v[1] / max(1, v[0] + v[1]), 4)] for k, v in acts]),
        blk("Decision findings", fhead, [frow(f) for f in findings if f["kind"] in ("decision_oscillation", "empty_decisions", "impossible_task", "stuck_npc", "job_oscillation", "job_churn")]),
        blk("Judgment and relations events", ["subsystem|subtype", "count"], sorted(an.judgment.items(), key=lambda kv_: -kv_[1])[:80]),
    ])
    # 9. Repeated failed actions
    sheet("Repeated Failed Actions", [
        blk("", fhead, [frow(f) for f in findings if f["kind"] in ("repeated_failed_action", "repeated_failed_purchase", "necessity_unbuyable")]
            or [["-", "none", "", "no repeated failure above the thresholds", "", None, None, 0, "", "", json.dumps(T), ""]]),
        blk("Longest failure streaks (all, for context)", ["actor", "action", "target", "longest streak", "from day", "to day", "most in one day", "failed total", "ok total"],
            sorted([[a, k, key, b[0], b[1], b[2], st["bestday"][0], st["fail"], st["ok"]] for (a, k, key), st in an.fail.items() for b in [an._best(st)] if b],
                   key=lambda x: -x[3])[:200]),
    ], FW)
    # 10. System interaction anomalies
    sheet("System Interaction Anomalies", [
        blk("", fhead, [frow(f) for f in findings if f["kind"] in ("station_contention", "failure_cascade", "stuck_npc", "duplicate_trades", "starving_with_means",
                                                                   "chapel_relief_missed", "coins_unattributed_total", "death_cluster")]
            or [["-", "none", "", "no interaction anomaly above the thresholds", "", None, None, 0, "", "", "", ""]]),
        blk("Failed actions and navigation failures by day", ["day", "failed actions", "walk lost", "actions"],
            [[d, D[d].get("actions_failed_h", 0), D[d].get("walk_lost_h", 0), D[d].get("actions_h", 0)] for d in days],
            [{"type": "line", "title": "Failures over the year", "y_cols": [1, 2], "y_title": "a day"}]),
    ], FW)
    # 11. Currency and inventory integrity
    integ = [[s["segment"], s["stop_reason"], s["start_day"], s["days_reached"], s["ok"], s["script_errors"], "; ".join(s["fatal"])[:500]] for s in st["segments"]]
    sheet("Currency and Inventory", [
        blk("", ["segment", "stop reason", "from day", "to day", "ledgers ok", "script errors", "FATAL lines"], integ or [["-", "no status", None, None, None, None, ""]]),
        blk("Archive checks (tools/recorder_archive.py)", ["session", "ok", "problems", "bytes", "chunks", "snapshot hours"],
            [[c["session"], c["ok"], "; ".join(c["problems"])[:800], c["bytes"], c["chunks"], c["snapshot_hours"]] for c in checks]),
        blk("Currency by day (recorder snapshots)", ["day", "currency in the world", "coins from outside (cumulative)", "treasury"],
            [[d, D[d].get("total_coins"), D[d].get("coin_sources"), D[d].get("treasury")] for d in days],
            [{"type": "line", "title": "Currency in the world", "y_cols": [1, 2], "y_title": "coins"}]),
        blk("Recorder alerts", ["severity", "rule", "count"], [[s_, rule, n] for (s_, rule), n in sorted(an.alerts.items())]),
        blk("Integrity findings", fhead, [frow(f) for f in findings if f["confirmed"]]),
    ])
    # 12. Critical events and deaths
    sheet("Critical Events and Deaths", [
        blk("", fhead, [frow(f) for f in findings if f["severity"] in ("CRITICAL", "HIGH")] or [["-", "none", "", "no CRITICAL or HIGH finding", "", None, None, 0, "", "", "", ""]]),
        blk("Deaths", ["day", "minute", "person", "cause", "detail", "event"], [d for d in an.deaths if "role=bandit" not in d[4]], cap=3000),
        blk("Deaths by cause", ["cause", "deaths"], Counter(d[3] for d in an.deaths if "role=bandit" not in d[4]).most_common()),
    ], FW)
    # 13. Trends and graphs
    sheet("Trends and Graphs", [
        blk("", ["day", "villagers alive", "employed", "food days in store", "median household purse", "treasury", "starving villager-hours", "trades"],
            [[d, D[d].get("alive"), D[d].get("employed"), _r(D[d].get("food_days")), D[d].get("hh_purse_median"), D[d].get("treasury"),
              D[d].get("starving_hours", 0), D[d].get("trades_ok", 0)] for d in days],
            [{"type": "line", "title": "Village over the year", "y_cols": [1, 2], "y_title": "people"},
             {"type": "line", "title": "Wealth over the year", "y_cols": [4, 5], "y_title": "coins"},
             {"type": "line", "title": "Food security", "y_cols": [3], "y_title": "days of need"}]),
    ])
    # 14. Coverage and limitations
    cov = load_json(COVERAGE, {}) or {}
    exercised = {}
    for c in checks:
        for k, v in (c.get("exercised") or {}).items():
            exercised[k] = exercised.get(k, 0) + (v or {}).get("events", 0)
    sheet("Coverage and Limitations", [
        blk("", ["system", "what is recorded", "status", "stage"], [[x.get("system"), (x.get("interaction") or "")[:300], x.get("status"), x.get("stage")] for x in cov.get("rows", [])]),
        blk("Exercised in this run (events per coverage row)", ["row", "events"], sorted(exercised.items())),
        blk("Limitations", ["limitation"], [[x] for x in [
            "Systems marked 'Not instrumented' (farming scripts, mining scripts, manor work, chapel, feasts, quests) are seen only through the game's counters (stats_delta), the harness's checkpoint lines (CHAPEL, JOBS, BIZ) and their effects on villagers.",
            "A chained run (segments) goes on from the game's own save; movement in progress is not saved, so it is deterministic from each save but not identical to an unbroken run.",
            "Thresholds tell suspicious repetition from repeated work; they are reading aids, never pass/fail rules (WDR-022). See findings.json 'thresholds'.",
            "The read-only bandit diagnostics (BANDITS lines) restart in each segment; the ledgers, samples and counts carry over.",
            "The full archive is in the archive artifacts; this workbook shows summaries and prioritised examples, not every event."]]),
    ])
    return {"format": "mml-flight-workbook/1", "sheets": sheets}


def _contract_items(an):
    out = defaultdict(lambda: [0, 0, 0])
    for c in an.contracts.values():
        o = out[c["item"] or "?"]
        o[0] += 1
        o[1] += 1 if "fulfilled" in c["states"] else 0
        o[2] += 1 if any(s in ("cancelled", "lapsed") for s in c["states"]) else 0
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("run_dir")
    ap.add_argument("--out", default="")
    ap.add_argument("--no-verify", action="store_true", help="skip tools/recorder_archive.py's checks (faster; integrity not checked)")
    a = ap.parse_args()
    result, summary = build(a.run_dir, a.out or a.run_dir, verify=not a.no_verify)
    print(json.dumps(summary, indent=1, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
