"""Living-world reports of a flight recorder campaign (B25R1-016, owner directive 2026-11-03, sections 4-14;
docs/design/FLIGHT_RECORDER.md section 9).

Reads one seed's run (the chained segments seg1, seg2, ... as tools/flight_analyse.py does, or one run's files directly) and
writes, from the WHOLE archive (never sampled), the reports the directive lists:

  A_executive.md          what actually happened, facts first, interpretations apart
  B_migration_ledger.csv  every recorded change of residence or affiliation (and B_migration_ledger.md with the journeys)
  C_bandit_ledger.md      recruitment by source, births, deaths, departures; reconciled with the dawn clan census
  D_homestead_ledger.md   every homestead: founder, track, stages reached, residents, production, survival, abandonment
  E_economic_ledger.md    production, consumption, trade, wilderness economy, roads; reconciled with the coin and item audits
  F_life_histories.md     cases A-G (lawful homesteader ... multigenerational household), real people or "unobserved"
  G_charts/*.svg          line and scatter charts (hand-written SVG: matplotlib is not available in CI)
  H_exceptions.md         failed attempts, missing activity, conservation, demographic instability, broken journeys
  I_evidence_index.md     commit, seed, configuration, segments, run ids, sessions, fingerprints, checks
  features.json           the section 12 classification of every feature, with counts at each level
  lives.json              all of the above as data

Targeted scenarios (tools/flight_scenarios.py) are read with --targeted DIR and reported apart, never mixed into the organic
numbers. --compare RUN_DIR2 compares the event streams and fingerprints of a second independent run of the same seed and
configuration (the determinism check). Nothing here changes the game; nothing judges an outcome (WDR-022): a failing village is
reported as what happened.

    python3 tools/flight_lives.py RUN_DIR [--out DIR] [--targeted DIR] [--compare RUN_DIR2]

Standard library only.
"""
import argparse
import csv
import glob
import gzip
import hashlib
import json
import os
import re
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import recorder_archive as ra  # noqa: E402
from flight_analyse import Segments, load_json, kv  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CODES = os.path.join(ROOT, "game", "data", "recorder_codes.json")
YEAR_DAYS = 8                       # life.json: a game year is 8 days
WINDOW_DAYS = 5 * YEAR_DAYS         # the young-adult safeguard's window: five game years
SAFEGUARD = 0.02                    # about 2% of eligible household formations (the owner's approved safeguard)
KEEP_CATS = {"identity", "life", "migration", "employment"}
KEEP_SUMMARIES = {"population_day", "clan_census", "settlement_state", "roads_day", "settlement_day"}
SIDE = ["participant", "factor", "state_change", "decision", "alternative"]
LEVELS = ["no_opportunity", "rejected", "failed", "partial", "completed", "sustained"]
LEVEL_TEXT = {"no_opportunity": "No eligible opportunity occurred", "rejected": "Eligible opportunity occurred but judgment rejected it",
              "failed": "Decision made but action failed", "partial": "Action partially completed", "completed": "Action successfully completed",
              "sustained": "Activity continued sustainably"}


def chron_codes():
    return (load_json(CODES, {}) or {}).get("chronicle", {})


def num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


class Archive:
    """The kept events of every session in order, with their side rows, plus the snapshots, alerts and daily person samples."""

    def __init__(self, run_dir):
        self.segs = Segments(run_dir)
        self.chron = chron_codes()
        self.events = []                 # dicts, in session then seq order
        self.snaps = []                  # snapshot rows (dicts)
        self.alerts = Counter()          # rule -> n
        self.alert_sev = Counter()
        self.coins_day = defaultdict(dict)    # ref -> {day: coins at the day's first sample}
        self.last_seen = {}              # ref -> last day sampled alive
        self.first_seen = {}
        self.sessions = []
        self.chunk_problems = []
        self.unknown_codes = Counter()
        for si, sdir in enumerate(self.segs.sessions()):
            sess = load_json(os.path.join(sdir, "session.json"), {}) or {}
            self.sessions.append({"dir": sdir, "session": sess.get("session"), "completeness": sess.get("completeness"), "bytes": sess.get("bytes"),
                                  "events": sess.get("events"), "commit": sess.get("commit"), "seed": sess.get("seed"), "flags": sess.get("flags"),
                                  "scenario": sess.get("scenario"), "save_version": sess.get("save_version"), "counts": sess.get("counts")})
            for k, v in (sess.get("unknown_codes") or {}).items():
                self.unknown_codes[k] += int(v)
            self._read(si, sdir)

    def _chunks(self, ddir, table):
        for p in sorted(glob.glob(os.path.join(ddir, table + ".*.jsonl.gz")), key=lambda q: (int(re.search(r"\.h(\d+)\.", q).group(1)), int(re.search(r"\.p(\d+)\.", q).group(1)))):
            head, rows, problem = ra.read_chunk(p)
            if problem:
                self.chunk_problems.append("%s: %s" % (p, problem))
            if head is None or not rows:
                continue
            ix = {c: i for i, c in enumerate(head["columns"])}
            yield ix, rows

    def _read(self, si, sdir):
        for ddir in sorted(glob.glob(os.path.join(sdir, "d*"))):
            kept = {}
            for ix, rows in self._chunks(ddir, "event"):
                for r in rows:
                    sub, cat = r[ix["subtype"]], r[ix["category"]]
                    spec = self.chron.get(sub)
                    if (spec is not None and r[ix["system"]] == spec[0]) or cat in KEEP_CATS or sub in KEEP_SUMMARIES:
                        e = {c: r[i] for c, i in ix.items()}
                        e.update({"sess": si, "parts": [], "f": {}, "sc": [], "dec": None, "alts": []})
                        kept[e["id"]] = e
            for table in SIDE:
                for ix, rows in self._chunks(ddir, table):
                    for r in rows:
                        e = kept.get(r[ix["event"]])
                        if e is None:
                            continue
                        if table == "participant":
                            e["parts"].append((r[ix["ref"]], r[ix["role"]]))
                        elif table == "factor":
                            e["f"]["%s.%s" % (r[ix["option"]], r[ix["factor"]])] = r[ix["value"]]
                        elif table == "state_change":
                            e["sc"].append((r[ix["ref"]], r[ix["prop"]], r[ix["before"]], r[ix["after"]], r[ix["authority"]]))
                        elif table == "decision":
                            e["dec"] = (r[ix["chosen"]], r[ix["basis"]])
                        else:
                            e["alts"].append((r[ix["option"]], r[ix["feasible"]], r[ix["score"]]))
            self.events += sorted(kept.values(), key=lambda e: e["seq"])
            for ix, rows in self._chunks(ddir, "snapshot"):
                for r in rows:
                    s = {c: r[i] for c, i in ix.items()}
                    s.pop("wall_ms", None)
                    s.pop("mem_bytes", None)
                    s["sess"] = si
                    self.snaps.append(s)
            for ix, rows in self._chunks(ddir, "alert"):
                for r in rows:
                    self.alerts[r[ix["rule"]]] += 1
                    self.alert_sev[r[ix["severity"]]] += 1
            for ix, rows in self._chunks(ddir, "sample"):
                for r in rows:
                    ref, day = r[ix["entity"]], int(r[ix["day"]])
                    if day not in self.coins_day[ref]:
                        self.coins_day[ref][day] = r[ix["coins"]]
                    self.last_seen[ref] = day
                    self.first_seen.setdefault(ref, day)


# ---------------------------------------------------------------- helpers ------------------------
def ctx(e, k, default=""):
    v = e["f"].get("ctx." + k)
    return default if v is None else v


def need(e, k, default=None):
    v = e["f"].get("needs." + k)
    return default if v is None else v


def when(e):
    return "day %d %02d:%02d" % (int(e["day"]), int(float(e["minute"]) // 60), int(float(e["minute"]) % 60))


def refs_of(e):
    out = {e["actor"]}
    out.update(r for r, _ in e["parts"])
    return out


def name_of(lv, ref):
    return lv.names.get(ref, "")


class Lives:
    def __init__(self, arc):
        self.a = arc
        self.by_kind = defaultdict(list)
        self.by_person = defaultdict(list)
        self.names = {}
        self.parents = {}                # child ref -> (mother, father)
        self.died = {}                   # ref -> event
        for e in arc.events:
            self.by_kind[e["subtype"]].append(e)
            for r in refs_of(e):
                if str(r).startswith("p:"):
                    self.by_person[r].append(e)
            nm = ctx(e, "name")
            if nm and e["actor"].startswith("p:"):
                self.names.setdefault(e["actor"], nm)
            if e["subtype"].startswith("registered_") and e["actor"].startswith("p:"):
                self.names.setdefault(e["actor"], (e["detail"] or "").split(";")[0])
            if e["subtype"] == "birth":
                roles = {ro: r for r, ro in e["parts"]}
                self.parents[e["actor"]] = (roles.get("mother"), roles.get("father"))
            if e["subtype"] in ("death", "died", "clan_member_died", "homestead_member_died") and e["actor"].startswith("p:"):
                self.died.setdefault(e["actor"], e)
        self.days = sorted({int(s["day"]) for s in arc.snaps}) or sorted({int(e["day"]) for e in arc.events}) or [0]

    def k(self, *kinds):
        out = []
        for kd in kinds:
            out += self.by_kind.get(kd, [])
        return sorted(out, key=lambda e: (e["sess"], e["seq"]))


# ---------------------------------------------------------------- B: migration -------------------
MIG_KINDS = {"left_village": "left the village", "returned_to_village": "returned to the village", "moved": "moved",
             "homestead_travel_begin": "set out to homestead", "homestead_travel_end": "homestead journey ended",
             "homestead_residence": "took up residence at a homestead", "homestead_abandoned": "abandoned a homestead",
             "runaway_departed": "ran away", "runaway_outcome": "runaway outcome", "recruit_joined": "joined a clan",
             "bandit_departed": "left a clan", "bandit_reintegrated": "reintegrated", "faction_changed": "faction changed",
             "settlement_occupancy": "settlement occupancy", "household_formed": "formed a household", "guardianship_placement": "placed with a household",
             "guardianship_clan": "placed with the clan", "settlement_attempt_failed": "a settlement attempt failed (B25R1-017)",
             "travel_blocked_by_water": "a journey failed at water (B25R1-017)"}


def migration_ledger(lv):
    rows = []
    for e in lv.k(*MIG_KINDS):
        det = e["detail"] or ""
        origin = ctx(e, "origin") or kv(det, "from") or ctx(e, "faction_before")
        dest = ctx(e, "destination") or kv(det, "to") or ctx(e, "faction") if e["subtype"] in ("recruit_joined", "bandit_departed", "faction_changed") else (ctx(e, "destination") or kv(det, "to"))
        if e["subtype"].startswith("guardianship"):
            hh = [s for s in e["sc"] if s[1] == "household"]
            if hh:
                origin, dest = "hh:%s" % hh[0][2], "hh:%s" % hh[0][3]
        rows.append({"day": e["day"], "minute": e["minute"], "person": e["actor"], "name": name_of(lv, e["actor"]), "type": e["subtype"],
                     "what": MIG_KINDS[e["subtype"]], "origin": origin, "destination": dest or ctx(e, "place"),
                     "reason": e["reason"] or e["rule"] or kv(det, "cause") or kv(det, "reason") or ctx(e, "source"), "track": ctx(e, "track"),
                     "outcome": e["outcome"], "event": "%d:%s" % (e["sess"], e["id"])})
    agg = []
    for e in lv.k("migration_in", "migration_out"):
        agg.append({"day": e["day"], "settlement": e["actor"], "dir": e["subtype"][10:], "reason": kv(e["detail"], "reason"), "people": kv(e["detail"], "people"),
                    "coins": kv(e["detail"], "coins")})
    journeys = defaultdict(dict)
    for e in lv.k("journey_begin", "journey_leg", "journey_purchase", "journey_end"):
        j = journeys[e["object"] or "%s@%s" % (e["actor"], e["day"])]
        j.setdefault("person", e["actor"])
        if e["subtype"] == "journey_begin":
            j.update({"begin": e["day"], "origin": ctx(e, "origin"), "destination": ctx(e, "destination"), "purpose": ctx(e, "action")})
        elif e["subtype"] == "journey_end":
            j.update({"end": e["day"], "outcome": e["outcome"], "reason": e["reason"]})
        elif e["subtype"] == "journey_purchase":
            j["purchases"] = j.get("purchases", 0) + 1
        else:
            j["legs"] = j.get("legs", 0) + 1
    return rows, agg, journeys


# ---------------------------------------------------------------- C: bandits ---------------------
def bandit_ledger(lv):
    census = defaultdict(dict)               # clan -> day -> (members, dependants)
    for e in lv.k("clan_census"):
        census[e["settlement"] or e["object"]][int(e["day"])] = (int(need(e, "members", 0) or 0), int(need(e, "dependants", 0) or 0))
    days = sorted({d for c in census.values() for d in c} | {int(e["day"]) for e in lv.k("population_day")})
    d0, d1 = (days[0], days[-1]) if days else (0, 0)
    clans = sorted(census)

    def inwin(e):
        return d0 <= int(e["day"]) < d1 or (int(e["day"]) == d1 and False)

    src = Counter()
    flows = Counter()
    seen_dead = set()
    for e in lv.k("recruit_joined"):
        if inwin(e):
            src[ctx(e, "source") or "unknown"] += 1
            flows["recruits"] += 1
    for e in lv.k("recruit_rejected"):
        if inwin(e):
            flows["recruits_rejected"] += 1
    for e in lv.k("registered_outlaw"):
        if inwin(e):
            flows["arrivals_from_outside"] += 1
    for e in lv.k("clan_birth"):
        if inwin(e):
            flows["births"] += 1
    for e in lv.k("guardianship_clan"):
        if inwin(e):
            flows["orphans_placed"] += 1
    for e in lv.k("clan_member_died", "death"):
        fac = ctx(e, "faction") or kv(e["detail"], "faction")
        if inwin(e) and str(fac).startswith("clan:") and e["actor"] not in seen_dead:
            seen_dead.add(e["actor"])
            flows["deaths_members" if kv(e["detail"], "role") == "bandit" or e["subtype"] == "clan_member_died" else "deaths_dependants"] += 1
    for e in lv.k("bandit_departed"):
        if inwin(e):
            flows["departures"] += 1
    for e in lv.k("bandit_reintegrated"):
        flows["reintegrated"] += 1

    def tot(day):
        m = sum(census[c].get(day, (0, 0))[0] for c in clans)
        dpd = sum(census[c].get(day, (0, 0))[1] for c in clans)
        return m, dpd

    m0, p0 = tot(d0)
    m1, p1 = tot(d1)
    expected = (m0 + p0) + flows["births"] + flows["recruits"] + flows["arrivals_from_outside"] + flows["orphans_placed"] - flows["deaths_members"] - flows["deaths_dependants"] - flows["departures"]
    residual = (m1 + p1) - expected
    series = [(d, ) + tot(d) for d in days]
    return {"window": [d0, d1], "clans": clans, "start": {"members": m0, "dependants": p0}, "end": {"members": m1, "dependants": p1},
            "flows": dict(flows), "recruits_by_source": dict(src), "expected_end_total": expected, "residual": residual, "series": series,
            "note": "start + births + recruits + arrivals + orphans placed - deaths - departures = end (members and dependants together). "
                    "A clan child growing into a member moves within the total. A non-zero residual is an unexplained change (H)."}


# ---------------------------------------------------------------- D: homesteads ------------------
HS_STAGES = ["homestead_evaluated", "homestead_chosen", "homestead_rejected", "homestead_safeguard", "homestead_trip", "homestead_failed", "homestead_site_evaluated", "homestead_travel_begin", "homestead_travel_end",
             "homestead_claimed", "homestead_resources", "homestead_construction", "homestead_shelter_built", "homestead_residence", "homestead_sustain",
             "homestead_year", "homestead_family_change", "homestead_inheritance", "homestead_member_died", "homestead_abandoned"]


def homestead_ledger(lv):
    hs = {}
    people_track = {}
    for e in lv.k(*HS_STAGES, "settlement_created", "settlement_construction", "settlement_occupancy", "settlement_affiliation", "settlement_abandoned",
                  "settlement_discovered", "settlement_state", "water_source_selected", "water_unavailable", "wild_production", "wild_consumption", "wild_trade", "wild_shortage", "livestock_change", "wild_craft", "raid"):
        key = e["object"] if str(e["object"]).startswith("homestead:") else (e["settlement"] if str(e["settlement"]).startswith("homestead:") else "")
        if e["actor"].startswith("p:") and ctx(e, "track"):
            people_track[e["actor"]] = ctx(e, "track")
        if not key:
            continue
        h = hs.setdefault(key, {"id": key, "founder": "", "track": "", "path": "", "first_day": e["day"], "stages": Counter(), "residents": set(),
                                "production": Counter(), "consumption": Counter(), "trade_events": 0, "sustain_ok": 0, "sustain_failed": 0, "years": 0,
                                "abandoned": None, "state": None, "raids": 0, "affiliations": []})
        sub = e["subtype"]
        h["stages"][sub] += 1
        h["last_day"] = e["day"]
        if e["actor"].startswith("p:"):
            if not h["founder"] and sub in ("homestead_claimed", "homestead_chosen", "homestead_travel_begin", "homestead_residence"):
                h["founder"] = e["actor"]
            if sub in ("homestead_residence", "homestead_family_change") or (sub == "settlement_occupancy" and ctx(e, "action") != "out"):
                h["residents"].add(e["actor"])
        h["track"] = h["track"] or ctx(e, "track")
        h["path"] = ctx(e, "path") or h["path"]
        if sub == "homestead_sustain":
            h["sustain_ok" if e["outcome"] == "ok" else "sustain_failed"] += 1
        elif sub == "homestead_year":
            h["years"] += 1
        elif sub in ("homestead_abandoned", "settlement_abandoned"):
            h["abandoned"] = {"day": e["day"], "reason": e["reason"]}
        elif sub == "settlement_state":
            h["state"] = {k[6:]: v for k, v in e["f"].items() if k.startswith("needs.")}
        elif sub in ("wild_production", "wild_consumption"):
            tgt = h["production" if sub == "wild_production" else "consumption"]
            moved = [s for s in e["sc"] if str(s[1]).startswith("item:")]
            for s in moved:
                b, a = num(s[2]), num(s[3])
                if b is not None and a is not None:
                    tgt["%s:%s" % (ctx(e, "action") or "?", s[1][5:])] += abs(a - b)
            if not moved:
                tgt[ctx(e, "action") or "?"] += 1
        elif sub == "wild_trade":
            h["trade_events"] += 1
        elif sub == "raid":
            h["raids"] += 1
        elif sub == "water_source_selected":
            h["water"] = "%s at %s tiles" % (ctx(e, "source") or need(e, "source", "?"), need(e, "distance", "?"))
        elif sub == "water_unavailable":
            h["water_unavailable"] = h.get("water_unavailable", 0) + 1
        elif sub == "settlement_affiliation":
            h["affiliations"].append((e["day"], ctx(e, "faction_before"), ctx(e, "faction")))
    for h in hs.values():
        st = h["stages"]
        h["status"] = ("abandoned" if h["abandoned"] else "sustained" if h["years"] > 0 and st["homestead_residence"] else
                       "resident" if st["homestead_residence"] else "built" if st["homestead_shelter_built"] else "claimed" if st["homestead_claimed"] else "intended")
        h["residents"] = sorted(h["residents"])
    by_track = defaultdict(Counter)
    for e in lv.k("household_formed"):
        by_track[ctx(e, "track") or "unknown"]["household_formations"] += 1
    for e in lv.k(*HS_STAGES):
        t = ctx(e, "track") or people_track.get(e["actor"], "unknown")
        by_track[t][e["subtype"]] += 1
    for h in hs.values():
        by_track[h["track"] or "unknown"]["surviving_at_end"] += 1 if h["status"] in ("resident", "sustained") else 0
    return hs, by_track


def young_adult_rate(lv):
    """Homestead departures (chosen) of track young_adult over eligible household formations of that track, per five-game-year window."""
    out = []
    forms = [int(e["day"]) for e in lv.k("household_formed") if ctx(e, "track") == "young_adult"]
    chose = [int(e["day"]) for e in lv.k("homestead_chosen") if ctx(e, "track") == "young_adult"]
    done = [int(e["day"]) for e in lv.k("homestead_residence") if ctx(e, "track") == "young_adult"]
    d1 = lv.days[-1]
    start = lv.days[0]
    while start <= d1:
        end = start + WINDOW_DAYS
        f = sum(1 for d in forms if start <= d < end)
        c = sum(1 for d in chose if start <= d < end)
        r = sum(1 for d in done if start <= d < end)
        out.append({"days": [start, min(end, d1 + 1)], "eligible_formations": f, "chose_homestead": c, "completed": r,
                    "rate": round(c / f, 4) if f else None, "complete_window": end <= d1 + 1})
        start = end
    return out


# ---------------------------------------------------------------- E: economy --------------------
PROD = ("made_", "mined_", "farm_harvest_", "hunted_", "villager_foraged_", "keeper_collected_", "felled_", "chopped_", "produced_", "quarried_", "caught_", "milked_", "sheared_")
CONS = ("eaten_", "used_", "spoiled_", "burned_", "fed_")


def economic_ledger(lv, run_status):
    a = lv.a
    totals = Counter()
    trade = Counter()
    for s in a.snaps:
        sd = s.get("stats_delta") or {}
        if isinstance(sd, dict):
            for k, v in sd.items():
                if isinstance(v, (int, float)):
                    totals[k] += v
        for k in ("trades_h", "trade_coins_h", "transfers_h", "actions_h", "actions_failed_h"):
            if isinstance(s.get(k), (int, float)):
                trade[k[:-2]] += s[k]
    prod = {k: round(v, 2) for k, v in totals.most_common() if k.startswith(PROD)}
    cons = {k: round(v, 2) for k, v in totals.most_common() if k.startswith(CONS)}
    unmet = {k: round(v, 2) for k, v in totals.most_common() if k.startswith(("missed_", "unmet_", "refused_"))}
    wild = Counter()
    wild_items = Counter()
    for e in lv.k("wild_production", "wild_consumption", "wild_trade", "wild_shortage", "sale_refused", "livestock_change", "skill_progress", "wild_craft", "raid", "raid_defended", "journey_purchase"):
        wild["%s|%s" % (e["subtype"], ctx(e, "action") or e["outcome"])] += 1
        for s in e["sc"]:
            if str(s[1]).startswith("item:") and num(s[2]) is not None and num(s[3]) is not None:
                wild_items["%s|%s" % (e["subtype"], s[1][5:])] += num(s[3]) - num(s[2])
    roads = Counter(e["subtype"] for e in lv.k("road_formed", "road_cleared", "road_wear", "road_paved", "road_repaired", "bridge_built", "bridge_used", "travel_blocked_by_water"))
    for e in lv.k("route_crossing"):
        roads["route_crossing:" + str((e["dec"] or (ctx(e, "action") or "?",))[0])] += 1
    for e in lv.k("road_faded", "road_overgrown"):
        roads[e["subtype"] + "_cells"] += int(need(e, "cells", 0) or 0)
    paving_stone = sum(int(need(e, "stone", 0) or 0) for e in lv.k("road_paved", "road_repaired"))
    ledgers = []
    for seg in lv.a.segs.list:
        st = seg["status"] or {}
        ledgers.append({"segment": seg["name"], "currency_leak": st.get("currency_leak"), "item_leaks": st.get("item_leaks"), "ok": st.get("ok")})
    coin_alerts = {k: v for k, v in a.alerts.items() if k.startswith("coin.")}
    return {"production": prod, "consumption": cons, "unmet": unmet, "trade": dict(trade), "wilderness": dict(wild), "wilderness_items": {k: round(v, 2) for k, v in wild_items.items()},
            "roads": dict(roads), "paving_stone": paving_stone, "harness_ledgers": ledgers, "coin_audit_alerts": coin_alerts,
            "reconciled": all((l["currency_leak"] in (0, None)) and not l["item_leaks"] for l in ledgers) if ledgers else None}


# ---------------------------------------------------------------- features (section 12) ---------
def feature_table(lv):
    def cnt(kinds, pred=None):
        return sum(1 for e in lv.k(*kinds) if pred is None or pred(e))

    def track(t):
        return lambda e: ctx(e, "track") == t

    def path(p):
        return lambda e: ctx(e, "path") == p

    def src(s):
        return lambda e: ctx(e, "source") == s

    def fail(e):
        return e["outcome"] in ("failed", "abandoned", "interrupted")

    F = []

    def add(name, opp, rej, fld, part, comp, sus):
        lv_ = {"no_opportunity": 0, "rejected": rej, "failed": fld, "partial": part, "completed": comp, "sustained": sus}
        reached = "no_opportunity"
        for L in LEVELS[1:]:
            if lv_[L] > 0:
                reached = L
        if opp == 0 and reached == "no_opportunity":
            reached = "no_opportunity"
        F.append({"feature": name, "opportunities": opp, "counts": lv_, "classification": reached, "text": LEVEL_TEXT[reached]})

    for t in ("young_adult", "established_adult"):
        add("homestead_" + t, cnt(["homestead_evaluated", "homestead_safeguard"], track(t)), cnt(["homestead_rejected", "homestead_safeguard"], track(t)),
            cnt(["homestead_travel_end"], lambda e, t=t: track(t)(e) and fail(e)) + cnt(["homestead_abandoned", "homestead_failed"], track(t)),
            cnt(["homestead_claimed"], track(t)), cnt(["homestead_residence"], track(t)), cnt(["homestead_year"], track(t)))
    for p in ("lawful", "outlaw"):
        add("homestead_path_" + p, cnt(["homestead_evaluated", "homestead_chosen"], path(p)), cnt(["homestead_rejected"], path(p)),
            cnt(["homestead_abandoned"], path(p)), cnt(["homestead_claimed"], path(p)), cnt(["homestead_residence"], path(p)), cnt(["homestead_year"], path(p)))
    stay = ("stay", "stay_home")
    add("youth_runaway", cnt(["runaway_hardship", "runaway_evaluated"]), cnt(["runaway_evaluated"], lambda e: (e["dec"] or ("",))[0] in stay),
        cnt(["runaway_outcome"], lambda e: fail(e) or ctx(e, "action") == "died"),
        cnt(["runaway_departed"]) + cnt(["runaway_evaluated"], lambda e: e["dec"] is not None and e["dec"][0] not in stay),
        cnt(["runaway_outcome"], lambda e: e["outcome"] == "ok" and ctx(e, "action") not in ("died", "")), cnt(["runaway_outcome"], lambda e: ctx(e, "action") in ("independent", "employed", "relocated")))
    for s in ("orphan", "runaway", "displaced_adult", "fugitive", "voluntary", "relationship", "raised_in_clan"):
        add("recruit_" + s, cnt(["recruit_circumstance", "recruit_sought"], src(s)), cnt(["recruit_sought"], lambda e, s=s: src(s)(e) and e["outcome"] == "refused"),
            cnt(["recruit_rejected"], src(s)), cnt(["recruit_contact", "recruit_accepted"], src(s)), cnt(["recruit_joined"], src(s)),
            cnt(["outlaw_occupation"], src(s)))
    add("bandit_departure", cnt(["bandit_leave_evaluated"]), cnt(["bandit_leave_evaluated"], lambda e: e["outcome"] == "refused"), 0, 0, cnt(["bandit_departed"]), cnt(["bandit_reintegrated"]))
    add("faction_change", cnt(["faction_changed", "recruit_joined", "bandit_departed"]), 0, 0, 0, cnt(["faction_changed", "recruit_joined", "bandit_departed"]), 0)
    add("wilderness_settlement", cnt(["settlement_created", "homestead_claimed"]), 0, cnt(["settlement_abandoned"]), cnt(["settlement_construction"]),
        cnt(["settlement_occupancy", "homestead_residence"]), cnt(["settlement_state"], lambda e: (num(need(e, "population", 0)) or 0) > 0))
    add("wilderness_production", cnt(["wild_production", "wild_consumption"]), 0, cnt(["wild_shortage", "sale_refused"]), 0, cnt(["wild_production"]), cnt(["wild_trade"]))
    add("raids", cnt(["raid", "raid_defended"]), cnt(["raid"], lambda e: e["outcome"] == "refused"), cnt(["raid"], fail), 0, cnt(["raid"], lambda e: e["outcome"] == "ok"), 0)
    add("resident_journeys", cnt(["journey_begin", "journey_refused"]), 0, cnt(["journey_end"], fail) + cnt(["journey_refused", "journey_errand_failed"]), cnt(["journey_leg"]), cnt(["journey_end"], lambda e: e["outcome"] == "ok"), cnt(["journey_purchase"]))
    add("road_formation", cnt(["road_formed", "road_faded", "road_overgrown"]), 0, 0, cnt(["road_formed"]), cnt(["road_formed"], lambda e: any(s[1] == "level" and s[3] == 2 for s in e["sc"])), 0)
    add("road_paving_repair", cnt(["road_paved", "road_repaired", "road_wear"]), 0, 0, 0, cnt(["road_paved", "road_repaired"]), 0)
    add("landmark_discovery", cnt(["landmark_discovered"]), 0, 0, 0, cnt(["landmark_discovered"]), 0)
    add("player_region_travel", cnt(["travel_destination_set", "travel_refused"]), 0, cnt(["travel_refused"]), cnt(["travel_suspended"]), cnt(["travel_arrived"]), 0)
    add("water_settlement", cnt(["water_source_selected", "settlement_attempt_failed"]), 0, cnt(["settlement_attempt_failed", "water_unavailable"]), 0,
        cnt(["water_source_selected"]), 0)
    add("water_crossings", cnt(["route_crossing", "bridge_used", "travel_blocked_by_water", "bridge_built"]), 0, cnt(["travel_blocked_by_water"]), cnt(["route_crossing"]),
        cnt(["bridge_used"]), cnt(["bridge_built"]))
    add("orphan_placement", cnt(["guardianship_placement", "guardianship_clan"]), 0, 0, 0, cnt(["guardianship_placement", "guardianship_clan"]), 0)
    return F


# ---------------------------------------------------------------- F: life histories --------------
CASES = [("A", "Lawful homesteader", "a young adult leaves a village, selects wilderness land, builds a home, establishes a livelihood and continues living there"),
         ("B", "Established-adult homesteader", "an established resident has a meaningful life change, relocates and establishes a new household"),
         ("C", "Youth runaway", "a young person under sustained hardship considers alternatives, leaves home and follows a survival path"),
         ("D", "Bandit recruit", "a persistent NPC leaves ordinary society, meets an outlaw clan, becomes a member and takes part in its economy"),
         ("E", "Skilled outlaw", "a bandit develops an occupation, obtains materials, produces goods and contributes to the settlement"),
         ("F", "Former bandit", "an adult leaves outlaw life, relocates and tries to reintegrate while keeping their history"),
         ("G", "Multigenerational household", "a household followed through births, adulthood, new households, inheritance and deaths")]


def pick_cases(lv):
    def richest(cands):
        cands = sorted(set(cands), key=lambda r: (-len(lv.by_person.get(r, [])), r))
        return cands[0] if cands else None

    res = {}
    res["A"] = richest(e["actor"] for e in lv.k("homestead_residence") if ctx(e, "track") == "young_adult" and ctx(e, "path", "lawful") != "outlaw")
    res["B"] = richest(e["actor"] for e in lv.k("homestead_residence", "household_formed") if ctx(e, "track") == "established_adult")
    res["C"] = richest(e["actor"] for e in lv.k("runaway_departed"))
    res["D"] = richest(e["actor"] for e in lv.k("recruit_joined"))
    skilled = [e["actor"] for e in lv.k("outlaw_occupation", "wild_craft", "wild_production") if str(ctx(e, "faction")).startswith("clan:")]
    res["E"] = richest(skilled)
    res["F"] = richest([e["actor"] for e in lv.k("bandit_reintegrated")] or [e["actor"] for e in lv.k("bandit_departed")])
    # G: the founder whose descendants reach the furthest generation (births recorded in the archive), ties by most descendants
    kids = defaultdict(list)
    for c, (m, f) in lv.parents.items():
        for p in (m, f):
            if p and str(p).startswith("p:"):
                kids[p].append(c)

    def depth(r, seen=()):
        if r in seen:
            return 0, 0
        best, total = 0, 0
        for c in kids.get(r, []):
            d, t = depth(c, seen + (r,))
            best = max(best, d + 1)
            total += 1 + t
        return best, total

    roots = [r for r in kids if r not in lv.parents or not any(lv.parents[r])]
    scored = sorted(((depth(r), r) for r in roots), key=lambda x: (-x[0][0], -x[0][1], x[1]))
    res["G"] = scored[0][1] if scored and scored[0][0][0] >= 2 else None
    res["G_generations"] = scored[0][0][0] + 1 if scored else 0
    res["G_kids"] = kids
    return res


def history(lv, ref, max_events=200):
    evs = sorted(lv.by_person.get(ref, []), key=lambda e: (e["sess"], e["seq"]))
    skip = {"population_day", "clan_census", "settlement_state", "roads_day", "settlement_day"}
    tl = []
    places = []
    for e in evs:
        if e["subtype"] in skip:
            continue
        role = "self" if e["actor"] == ref else next((ro for r, ro in e["parts"] if r == ref), "")
        place = ctx(e, "place") or e["settlement"] or ctx(e, "destination")
        if place and (not places or places[-1][1] != place):
            places.append((e["day"], place))
        dec = ""
        if e["dec"] and e["actor"] == ref:
            dec = "chose %s over %s" % (e["dec"][0], ", ".join(str(a[0]) for a in e["alts"] if str(a[0]) != str(e["dec"][0])) or "nothing else")
        money = ["%s %s %s->%s" % (s[0], s[1], s[2], s[3]) for s in e["sc"] if s[0] == ref and (s[1] == "coins" or str(s[1]).startswith("item:"))]
        tl.append({"when": when(e), "day": e["day"], "kind": e["subtype"], "role": role, "outcome": e["outcome"], "reason": e["reason"] or e["rule"],
                   "place": place, "decision": dec, "money": money[:4], "detail": (e["detail"] or "")[:160]})
    coins = lv.a.coins_day.get(ref, {})
    days = sorted(coins)
    traj = [(d, coins[d]) for d in days[:: max(1, len(days) // 12)]] + ([(days[-1], coins[days[-1]])] if days else [])
    death = lv.died.get(ref)
    final = ("died %s (%s)" % (when(death), kv(death["detail"], "cause") or death["reason"] or death["subtype"]) if death else
             "alive, last seen day %s" % lv.a.last_seen.get(ref) if ref in lv.a.last_seen else "not seen in the village at the end (see the last event)")
    return {"ref": ref, "name": name_of(lv, ref), "events": len(tl), "timeline": tl[:max_events], "truncated": max(0, len(tl) - max_events),
            "locations": places, "coins": traj, "final": final, "parents": lv.parents.get(ref)}


# ---------------------------------------------------------------- G: charts (SVG) ---------------
PAL = ["#2b6cb0", "#c05621", "#2f855a", "#9b2c2c", "#6b46c1", "#b7791f", "#319795", "#4a5568"]


def svg_line(path, title, xlabel, series, ylabel="", scatter=False):
    """series: [(label, [(x, y), ...])]. A plain line (or scatter) chart, hand-written SVG."""
    W, H, L, R, T, B = 760, 380, 64, 170, 36, 44
    pts = [p for _, s in series for p in s if p[1] is not None]
    if not pts:
        pts = [(0, 0), (1, 1)]
    x0, x1 = min(p[0] for p in pts), max(p[0] for p in pts)
    y0, y1 = min(0, min(p[1] for p in pts)), max(p[1] for p in pts)
    x1 = x1 if x1 > x0 else x0 + 1
    y1 = y1 if y1 > y0 else y0 + 1
    sx = lambda x: L + (x - x0) / (x1 - x0) * (W - L - R)
    sy = lambda y: H - B - (y - y0) / (y1 - y0) * (H - T - B)
    o = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="sans-serif" font-size="12">' % (W, H, W, H),
         '<rect width="100%" height="100%" fill="#ffffff"/>', '<text x="%d" y="22" font-size="15" font-weight="bold">%s</text>' % (L, esc(title))]
    for i in range(5):
        yv = y0 + (y1 - y0) * i / 4
        o.append('<line x1="%d" x2="%d" y1="%.1f" y2="%.1f" stroke="#e2e8f0"/>' % (L, W - R, sy(yv), sy(yv)))
        o.append('<text x="%d" y="%.1f" text-anchor="end" fill="#4a5568">%s</text>' % (L - 6, sy(yv) + 4, fmt(yv)))
    for i in range(6):
        xv = x0 + (x1 - x0) * i / 5
        o.append('<text x="%.1f" y="%d" text-anchor="middle" fill="#4a5568">%s</text>' % (sx(xv), H - B + 16, fmt(xv)))
    o.append('<line x1="%d" x2="%d" y1="%d" y2="%d" stroke="#4a5568"/>' % (L, W - R, H - B, H - B))
    o.append('<text x="%d" y="%d" text-anchor="middle" fill="#2d3748">%s</text>' % ((L + W - R) // 2, H - 8, esc(xlabel)))
    if ylabel:
        o.append('<text x="14" y="%d" transform="rotate(-90 14 %d)" text-anchor="middle" fill="#2d3748">%s</text>' % (H // 2, H // 2, esc(ylabel)))
    for i, (label, s) in enumerate(series):
        c = PAL[i % len(PAL)]
        s = [p for p in s if p[1] is not None]
        if scatter:
            for x, y in s:
                o.append('<circle cx="%.1f" cy="%.1f" r="3" fill="%s" fill-opacity="0.7"/>' % (sx(x), sy(y), c))
        elif s:
            o.append('<polyline fill="none" stroke="%s" stroke-width="2" points="%s"/>' % (c, " ".join("%.1f,%.1f" % (sx(x), sy(y)) for x, y in s)))
        o.append('<rect x="%d" y="%d" width="12" height="12" fill="%s"/><text x="%d" y="%d">%s</text>' % (W - R + 12, T + 18 * i, c, W - R + 30, T + 18 * i + 10, esc(label)))
    o.append("</svg>")
    with open(path, "w") as f:
        f.write("\n".join(o) + "\n")


def esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def fmt(v):
    return ("%d" % v) if abs(v - round(v)) < 1e-9 or abs(v) >= 100 else ("%.1f" % v)


def charts(lv, out, bl, hs):
    os.makedirs(out, exist_ok=True)
    made = []
    pop = lv.k("population_day")
    if pop:
        ser = [("village alive", [(int(e["day"]), num(need(e, "alive"))) for e in pop]),
               ("households", [(int(e["day"]), num(need(e, "households"))) for e in pop]),
               ("bandits", [(int(e["day"]), num(need(e, "stage:bandit", 0))) for e in pop]),
               ("wilderness", [(int(e["day"]), num(need(e, "wilderness_population", 0))) for e in pop]),
               ("off-map settlements", [(int(e["day"]), num(need(e, "offmap_population", 0))) for e in pop])]
        svg_line(os.path.join(out, "population.svg"), "Population over time", "game day", ser, "people")
        made.append("population.svg")
        stages = [("children", "stage:child"), ("adolescents", "stage:adolescent"), ("adults", "stage:adult"), ("elders", "stage:elder")]
        svg_line(os.path.join(out, "life_stages.svg"), "Life stages over time", "game day", [(lab, [(int(e["day"]), num(need(e, k, 0))) for e in pop]) for lab, k in stages], "people")
        made.append("life_stages.svg")
    if bl["series"]:
        svg_line(os.path.join(out, "clans.svg"), "Clan membership (dawn census)", "game day",
                 [("members", [(d, m) for d, m, _ in bl["series"]]), ("dependants", [(d, p) for d, _, p in bl["series"]])], "people")
        made.append("clans.svg")
    cum = []
    for kinds, lab in ((("left_village",), "left the village"), (("returned_to_village",), "returned"), (("homestead_residence",), "homestead residence"),
                       (("runaway_departed",), "runaways"), (("recruit_joined",), "joined a clan"), (("bandit_departed",), "left a clan"), (("household_formed",), "households formed")):
        n = 0
        s = []
        for e in lv.k(*kinds):
            n += 1
            s.append((int(e["day"]), n))
        if s:
            cum.append((lab, [(lv.days[0], 0)] + s + [(lv.days[-1], n)]))
    if cum:
        svg_line(os.path.join(out, "migration_cumulative.svg"), "Migration and household formation (cumulative)", "game day", cum, "events")
        made.append("migration_cumulative.svg")
    daily = defaultdict(lambda: [0, 0, 0])
    for s in lv.a.snaps:
        d = daily[int(s["day"])]
        d[0] += s.get("trades_h") or 0
        d[1] += s.get("trade_coins_h") or 0
        d[2] += s.get("actions_h") or 0
    if daily:
        ds = sorted(daily)
        svg_line(os.path.join(out, "economy_daily.svg"), "Economic activity per day", "game day",
                 [("trades", [(d, daily[d][0]) for d in ds]), ("coins traded / 10", [(d, daily[d][1] / 10.0) for d in ds])], "per day")
        made.append("economy_daily.svg")
    active = []
    for d in lv.days:
        n = sum(1 for h in hs.values() if h["stages"]["homestead_residence"] and h["first_day"] <= d and (not h["abandoned"] or h["abandoned"]["day"] > d))
        active.append((d, n))
    if hs:
        svg_line(os.path.join(out, "homesteads_active.svg"), "Homesteads with residents", "game day", [("active", active)], "homesteads")
        made.append("homesteads_active.svg")
    deaths = [(int(e["day"]), num(kv(e["detail"], "age"))) for e in lv.k("death") if num(kv(e["detail"], "age")) is not None]
    if deaths:
        svg_line(os.path.join(out, "deaths_age.svg"), "Age at death by day (each a villager)", "game day", [("death", deaths)], "age (years)", scatter=True)
        made.append("deaths_age.svg")
    return made


# ---------------------------------------------------------------- H: exceptions -----------------
def exceptions(lv, feats, bl, hs, rates, econ, run_status, people_check):
    H = []

    def add(kind, text, evidence=None):
        H.append({"kind": kind, "observation": text, "evidence": evidence or {}})

    for f in feats:
        if f["classification"] == "no_opportunity":
            add("missing_activity", "%s: no eligible opportunity was recorded" % f["feature"])
        elif f["counts"]["failed"]:
            add("failed_attempts", "%s: %d failed attempts (and %d completed)" % (f["feature"], f["counts"]["failed"], f["counts"]["completed"]))
    for e in lv.k("journey_end"):
        if e["outcome"] != "ok":
            add("broken_journey", "%s %s journey ended %s (%s)" % (when(e), e["actor"], e["outcome"], e["reason"]), {"event": "%d:%s" % (e["sess"], e["id"])})
    for h in hs.values():
        if h["abandoned"]:
            add("abandoned_work", "%s abandoned on day %s (%s) at status before: %s" % (h["id"], h["abandoned"]["day"], h["abandoned"]["reason"], dict(h["stages"])))
    if bl["residual"]:
        add("bandit_ledger_unexplained", "the clan census differs from the recorded flows by %d (start %s, end %s, flows %s)" % (bl["residual"], bl["start"], bl["end"], bl["flows"]))
    for r in rates:
        if r["rate"] is not None and r["rate"] > SAFEGUARD * 1.5 and r["eligible_formations"] >= 10:
            add("homestead_rate_above_safeguard", "young-adult homesteading %.1f%% of %d eligible formations on days %s" % (100 * r["rate"], r["eligible_formations"], r["days"]))
    if econ["reconciled"] is False:
        add("conservation", "a harness ledger did not balance: %s" % econ["harness_ledgers"])
    for k, v in econ["coin_audit_alerts"].items():
        if k == "coin.unattributed_total":
            add("conservation", "the recorder's coin audit: %d unattributed changes of the world total" % v)
    pop = lv.k("population_day")
    if len(pop) > WINDOW_DAYS:
        for i in range(WINDOW_DAYS, len(pop)):
            a0, a1 = num(need(pop[i - WINDOW_DAYS], "alive")) or 0, num(need(pop[i], "alive")) or 0
            if a0 >= 20 and a1 < 0.5 * a0:
                add("demographic_instability", "the village fell from %d to %d people in five game years (days %s-%s)" % (a0, a1, pop[i - WINDOW_DAYS]["day"], pop[i]["day"]))
                break
            if a0 >= 20 and a1 > 3 * a0:
                add("demographic_instability", "the village grew from %d to %d people in five game years (days %s-%s)" % (a0, a1, pop[i - WINDOW_DAYS]["day"], pop[i]["day"]))
                break
    moves = defaultdict(list)
    for e in lv.k("left_village", "returned_to_village", "homestead_travel_begin", "recruit_joined", "bandit_departed"):
        moves[e["actor"]].append(int(e["day"]))
    for r, ds in moves.items():
        ds.sort()
        for i in range(len(ds) - 5):
            if ds[i + 5] - ds[i] <= WINDOW_DAYS:
                add("migration_loop", "%s moved 6 times within five game years (days %s)" % (r, ds[i:i + 6]))
                break
    for seg in lv.a.segs.list:
        rt = (seg["status"] or {}).get("save_roundtrip") or {}
        if rt and not rt.get("exact", True):
            add("save_roundtrip", "%s: the save of day %s loaded into a fresh world and saved again differs in: %s" % (seg["name"], rt.get("day"), ", ".join(rt.get("differ", []))), rt)
    for p in people_check["unaccounted"][:50]:
        add("unaccounted_person", "%s registered in the village, not recorded as dead or gone, and not sampled at the end" % p)
    for k, n in Counter(e["reason"] or str(need(e, "reason", "?")) for e in lv.k("settlement_attempt_failed")).items():
        add("settlement_attempt_failed", "%d settlement attempts failed for %s (B25R1-017)" % (n, k))
    for e in lv.k("travel_blocked_by_water"):
        add("travel_blocked_by_water", "%s %s: %s" % (when(e), e["actor"], e["reason"] or "water"), {"event": "%d:%s" % (e["sess"], e["id"])})
    if lv.k("water_unavailable"):
        add("water_unavailable", "%d times a settlement's water could not be used (%s)" % (len(lv.k("water_unavailable")), dict(Counter(e["reason"] for e in lv.k("water_unavailable")))))
    for k, n in Counter(e["detail"] for e in lv.k("unmapped_event")).items():
        add("unmapped_event", "%d events the recorder has no mapping for: %s" % (n, k))
    if lv.a.unknown_codes:
        add("unknown_codes", "codes outside recorder_codes.json: %s" % dict(lv.a.unknown_codes))
    for c in lv.a.chunk_problems[:20]:
        add("archive", c)
    return H


def people_accounting(lv):
    """Every person the register learnt in the village: dead, gone (where) or seen alive at the end; never silently absent."""
    last_day = max(lv.a.last_seen.values()) if lv.a.last_seen else 0
    where = {}
    for e in lv.k(*[k for k in lv.by_kind if k.startswith("registered_")], "left_village", "returned_to_village", "moved", "died", "became_ancestor", "became_player"):
        for s in e["sc"]:
            if s[1] == "where":
                where[e["actor"]] = s[3]
    for r, d in lv.a.first_seen.items():
        if d == min(lv.a.first_seen.values()) and str(r).startswith("p:") and r not in where:
            where[r] = "village"                  # present at the start of the archive (registered before it began)
    unacc = []
    tally = Counter()
    for r, w in where.items():
        if r in lv.died or w == "dead":
            tally["dead"] += 1
        elif w != "village":
            tally["away:" + ("settlement" if str(w).isdigit() or str(w).startswith("s") else str(w))] += 1
        elif lv.a.last_seen.get(r) == last_day:
            tally["alive_in_village"] += 1
        else:
            unacc.append(r)
    return {"registered": len(where), "tally": dict(tally), "unaccounted": sorted(unacc), "last_day": last_day,
            "duplicates": [r for r, n in Counter(e["actor"] for e in lv.k("birth")).items() if n > 1]}


# ---------------------------------------------------------------- determinism --------------------
def stream_hashes(run_dir):
    """sha256 per session and game day of the event, state_change and snapshot rows (the machine's wall_ms and mem_bytes left out)."""
    out = {}
    for si, sdir in enumerate(Segments(run_dir).sessions()):
        for ddir in sorted(glob.glob(os.path.join(sdir, "d*"))):
            h = hashlib.sha256()
            for table in ("event", "state_change", "participant", "snapshot"):
                for p in sorted(glob.glob(os.path.join(ddir, table + ".*.jsonl.gz")), key=lambda q: (int(re.search(r"\.h(\d+)\.", q).group(1)), int(re.search(r"\.p(\d+)\.", q).group(1)))):
                    head, rows, _ = ra.read_chunk(p)
                    if head is None:
                        continue
                    drop = {head["columns"].index(c) for c in ("wall_ms", "mem_bytes") if c in head["columns"]}
                    for r in rows:
                        h.update(json.dumps([v for i, v in enumerate(r) if i not in drop], sort_keys=True).encode())
            out["%d/%s" % (si, os.path.basename(ddir))] = h.hexdigest()
    return out


def fingerprints(run_dir):
    out = {}
    for seg in Segments(run_dir).list:
        sim = load_json(seg["sim"], {}) or {}
        for s in sim.get("samples", []):
            if isinstance(s, dict) and "fingerprint" in s:
                out[int(s["day"])] = s["fingerprint"]
        if sim.get("fingerprint"):
            out[int(sim.get("reached", -1))] = sim["fingerprint"]
    return out


def compare(run_a, run_b):
    ha, hb = stream_hashes(run_a), stream_hashes(run_b)
    fa, fb = fingerprints(run_a), fingerprints(run_b)
    days = sorted(set(ha) | set(hb))
    diff = [d for d in days if ha.get(d) != hb.get(d)]
    fdiff = [d for d in sorted(set(fa) | set(fb)) if fa.get(d) != fb.get(d)]
    return {"stream_days": len(days), "stream_days_differing": diff[:20], "first_stream_difference": diff[0] if diff else None,
            "fingerprint_days": sorted(set(fa) & set(fb)), "fingerprints_differing": fdiff, "identical": not diff and not fdiff and bool(days)}


# ---------------------------------------------------------------- the reports --------------------
def _write(path, text):
    with open(path, "w") as f:
        f.write(text)


def table(header, rows):
    L = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    for r in rows:
        L.append("| " + " | ".join(str(x).replace("|", "/") for x in r) + " |")
    return L


def build(run_dir, out_dir, targeted=None, compare_dir=None):
    arc = Archive(run_dir)
    lv = Lives(arc)
    from flight_analyse import run_status, parse_log
    logs = [parse_log(s["log"]) for s in arc.segs.list]
    status = run_status(arc.segs, logs)
    os.makedirs(out_dir, exist_ok=True)
    mig, mig_agg, journeys = migration_ledger(lv)
    bl = bandit_ledger(lv)
    hs, by_track = homestead_ledger(lv)
    rates = young_adult_rate(lv)
    econ = economic_ledger(lv, status)
    feats = feature_table(lv)
    pc = people_accounting(lv)
    cases = pick_cases(lv)
    hist = {}
    for cid, title, _ in CASES:
        ref = cases.get(cid)
        hist[cid] = history(lv, ref) if ref else None
    gfam = None
    if cases.get("G"):
        fam = []
        stack = [cases["G"]]
        while stack:
            r = stack.pop()
            if r in fam:
                continue
            fam.append(r)
            stack += cases["G_kids"].get(r, [])
        gfam = [history(lv, r, 40) for r in fam[:12]]
    chart_files = charts(lv, os.path.join(out_dir, "G_charts"), bl, hs)
    exc = exceptions(lv, feats, bl, hs, rates, econ, status, pc)
    det = compare(run_dir, compare_dir) if compare_dir else None
    tgt = None
    if targeted:                                     # one targeted.json, or several (one per scenario run) under the directory
        found = sorted(glob.glob(os.path.join(targeted, "targeted.json")) + glob.glob(os.path.join(targeted, "*", "targeted.json")))
        tgt = {"scenarios": [x for p in found for x in (load_json(p, {}) or {}).get("scenarios", [])], "files": found}
    # ---------------- B
    with open(os.path.join(out_dir, "B_migration_ledger.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["day", "minute", "person", "name", "type", "what", "origin", "destination", "reason", "track", "outcome", "event"])
        w.writeheader()
        for r in mig:
            w.writerow(r)
    L = ["# B. Migration ledger", "", "Observed facts. Every recorded change of residence, household or affiliation: %d rows (full list: `B_migration_ledger.csv`)." % len(mig), ""]
    L += ["## By type", ""] + table(["type", "count"], sorted(Counter(r["type"] for r in mig).items(), key=lambda x: -x[1])) + [""]
    L += ["## Settlement caravan moves (Migration, aggregate)", ""] + table(["day", "settlement", "direction", "reason", "people"], [(r["day"], r["settlement"], r["dir"], r["reason"], r["people"]) for r in mig_agg[:200]]) + [""]
    L += ["## Journeys (travel, not a change of residence): %d" % len(journeys), "",
          "Resident travellers only (envoys, buying trips, seed travellers: real villagers with ids). The ambient travellers on the roads are "
          "scenery with no identity and are not recorded.", ""] + table(["journey", "person", "purpose", "from", "to", "begin", "end", "outcome", "reason", "purchases"],
        [(k, j.get("person"), j.get("purpose"), j.get("origin"), j.get("destination"), j.get("begin"), j.get("end"), j.get("outcome", "unfinished"), j.get("reason"), j.get("purchases", 0)) for k, j in list(journeys.items())[:300]]) + [""]
    L += ["## First 300 rows", ""] + table(["day", "person", "name", "what", "origin", "destination", "reason", "outcome"], [(r["day"], r["person"], r["name"], r["what"], r["origin"], r["destination"], r["reason"], r["outcome"]) for r in mig[:300]])
    _write(os.path.join(out_dir, "B_migration_ledger.md"), "\n".join(L) + "\n")
    # ---------------- C
    L = ["# C. Bandit population ledger", "", "Observed facts (window days %s to %s, from the first to the last dawn census)." % tuple(bl["window"]), ""]
    L += table(["", "members", "dependants"], [("start", bl["start"]["members"], bl["start"]["dependants"]), ("end", bl["end"]["members"], bl["end"]["dependants"])]) + [""]
    L += ["## Flows", ""] + table(["flow", "count"], sorted(bl["flows"].items())) + [""]
    L += ["## Recruitment by source", ""] + (table(["source", "recruits"], sorted(bl["recruits_by_source"].items())) if bl["recruits_by_source"] else ["No recruit joined a clan in the window."]) + [""]
    L += ["## Reconciliation", "", bl["note"], "", "Expected end total %d; census end total %d; **residual %d**." % (bl["expected_end_total"], bl["end"]["members"] + bl["end"]["dependants"], bl["residual"]), ""]
    _write(os.path.join(out_dir, "C_bandit_ledger.md"), "\n".join(L) + "\n")
    # ---------------- D
    L = ["# D. Homestead ledger", "", "Observed facts. An intention or a claim is never counted as a completed homestead: only a recorded residence is.", ""]
    L += ["## By track", ""] + table(["track", "formations", "evaluated", "chose", "rejected", "set out", "claimed", "built", "resident", "abandoned", "surviving at end"],
        [(t, c["household_formations"], c["homestead_evaluated"], c["homestead_chosen"], c["homestead_rejected"], c["homestead_travel_begin"], c["homestead_claimed"],
          c["homestead_shelter_built"], c["homestead_residence"], c["homestead_abandoned"], c["surviving_at_end"]) for t, c in sorted(by_track.items())]) + [""]
    L += ["## Young-adult safeguard (about 2%% or less of eligible household formations, five-game-year windows of %d days)" % WINDOW_DAYS, ""]
    L += table(["days", "eligible formations", "chose homestead", "completed", "rate", "whole window"], [(r["days"], r["eligible_formations"], r["chose_homestead"], r["completed"],
               "-" if r["rate"] is None else "%.2f%%" % (100 * r["rate"]), r["complete_window"]) for r in rates]) + [""]
    fails = lv.k("settlement_attempt_failed")
    L += ["## Water and failed settlement attempts (B25R1-017)", "", "Water sources chosen: %s." % (dict(Counter(ctx(e, "source") or str(need(e, "source", "?")) for e in lv.k("water_source_selected"))) or "none recorded"),
          "Failed settlement attempts by reason: %s." % (dict(Counter(e["reason"] or str(need(e, "reason", "?")) for e in fails)) or "none recorded"),
          "Water unavailable at a settlement: %d events." % len(lv.k("water_unavailable")), ""]
    L += table(["day", "person", "reason", "cell"], [(e["day"], e["actor"], e["reason"] or need(e, "reason", ""), need(e, "cell", "")) for e in fails[:100]]) + [""] if fails else []
    L += ["## Every homestead (%d)" % len(hs), ""] + table(["id", "founder", "track", "path", "from day", "status", "water", "residents", "years", "sustain ok/failed", "production", "raids", "abandoned"],
        [(h["id"], "%s %s" % (h["founder"], name_of(lv, h["founder"])), h["track"], h["path"], h["first_day"], h["status"], h.get("water", "-"), len(h["residents"]), h["years"],
          "%d/%d" % (h["sustain_ok"], h["sustain_failed"]), ", ".join("%s %s" % (k, round(v, 1)) for k, v in h["production"].most_common(4)), h["raids"],
          "-" if not h["abandoned"] else "day %s %s" % (h["abandoned"]["day"], h["abandoned"]["reason"])) for h in sorted(hs.values(), key=lambda x: (x["first_day"], x["id"]))])
    _write(os.path.join(out_dir, "D_homestead_ledger.md"), "\n".join(L) + "\n")
    # ---------------- E
    L = ["# E. Economic ledger", "", "Observed facts, summed over the whole archive (the game's own counters, `stats_delta`, and the recorded events).", ""]
    L += ["## Conservation", ""] + table(["segment", "currency leak", "item leaks", "ok"], [(l["segment"], l["currency_leak"], l["item_leaks"] or "none", l["ok"]) for l in econ["harness_ledgers"]])
    L += ["", "Recorder coin audit alerts: %s (holder alerts name coin sites not instrumented; a `coin.unattributed_total` would be a violation)." % (econ["coin_audit_alerts"] or "none"), "",
          "Reconciled against the harness's currency and item ledgers: **%s**." % econ["reconciled"], ""]
    L += ["## Trade and work", ""] + table(["measure", "total"], sorted(econ["trade"].items())) + [""]
    for title, key in (("Production (game counters)", "production"), ("Consumption", "consumption"), ("Unmet needs and refusals", "unmet")):
        L += ["## " + title, ""] + table(["counter", "total"], list(econ[key].items())[:60]) + [""]
    L += ["## Wilderness and outlaw economy (events)", ""] + (table(["event|action", "count"], sorted(econ["wilderness"].items())) if econ["wilderness"] else ["None recorded."]) + [""]
    L += table(["event|item", "net units"], sorted(econ["wilderness_items"].items())) + [""] if econ["wilderness_items"] else []
    L += ["## Roads", ""] + table(["measure", "count"], sorted(econ["roads"].items())) + ["", "Stone used for paving and repair (recorded): %d" % econ["paving_stone"]]
    _write(os.path.join(out_dir, "E_economic_ledger.md"), "\n".join(L) + "\n")
    # ---------------- F
    L = ["# F. Individual life histories", "", "Real people of this run, picked by the rule stated for each case (the matching person with the most recorded events). "
         "No example is invented: a case with no matching organic event is marked unobserved, with the targeted-scenario evidence beside it.", ""]
    for cid, title, desc in CASES:
        L += ["## Case %s: %s" % (cid, title), "", "_%s._" % desc, ""]
        h = hist[cid]
        if not h:
            L += ["**Unobserved** in the organic run: no recorded event matched this case."]
            if tgt:
                ts = [s for s in tgt.get("scenarios", []) if cid in s.get("cases", [])]
                L += ["Targeted evidence (separate, not organic): " + ("; ".join("%s: %s" % (s["name"], s.get("result")) for s in ts) if ts else "none for this case")]
            L += [""]
            continue
        L += ["- Person: **%s** %s; parents %s" % (h["ref"], h["name"], h["parents"]), "- Final status: %s" % h["final"],
              "- Locations: " + (" -> ".join("%s (day %s)" % (p, d) for d, p in h["locations"]) or "the village throughout"),
              "- Coins: " + (", ".join("day %s: %s" % (d, c) for d, c in h["coins"]) or "not sampled"), "", "Timeline (%d events%s):" % (h["events"], ", first %d shown" % len(h["timeline"]) if h["truncated"] else ""), ""]
        L += table(["when", "event", "role", "outcome", "reason", "place", "decision", "money", "detail"],
                   [(t["when"], t["kind"], t["role"], t["outcome"], t["reason"], t["place"], t["decision"], "; ".join(t["money"]), t["detail"][:80]) for t in h["timeline"]]) + [""]
        if cid == "G" and gfam:
            L += ["Family (%d generations recorded): %s" % (cases["G_generations"], ", ".join("%s %s (%s)" % (m["ref"], m["name"], m["final"]) for m in gfam)), ""]
    _write(os.path.join(out_dir, "F_life_histories.md"), "\n".join(L) + "\n")
    # ---------------- H
    L = ["# H. Exception report", "", "Observations, not verdicts (WDR-022: a village may fail; the simulation may not). Conservation and accounting rows are the ones that point at defects.", ""]
    L += table(["kind", "observation"], [(x["kind"], x["observation"]) for x in exc[:400]]) if exc else ["Nothing exceptional was observed."]
    L += ["", "## People accounting", "", "Registered %d; %s; unaccounted %d; duplicate births %s." % (pc["registered"], pc["tally"], len(pc["unaccounted"]), pc["duplicates"] or "none")]
    _write(os.path.join(out_dir, "H_exceptions.md"), "\n".join(L) + "\n")
    # ---------------- I
    ev = {"commit": status.get("commit"), "seed": status.get("seed"), "days_requested": status.get("days_requested"), "days_reached": status.get("days_reached"),
          "stop_reason": status.get("stop_reason"), "args": status.get("args"), "segments": status.get("segments"),
          "sessions": [{k: s.get(k) for k in ("session", "completeness", "bytes", "events", "commit", "seed", "scenario", "save_version", "flags")} for s in arc.sessions],
          "fingerprints": fingerprints(run_dir), "determinism": det, "rows_kept": len(arc.events), "snapshots": len(arc.snaps), "chunk_problems": arc.chunk_problems[:20],
          "tests": ["game/tests/recorder_test.gd", "game/tests/b25_recorder_test.gd", "tools/recorder_archive.py (per session)", "tools/flight_lives.py"],
          "targeted": {"dir": targeted, "scenarios": [s.get("name") for s in (tgt or {}).get("scenarios", [])]} if tgt else None}
    L = ["# I. Evidence index", ""] + ["- %s: `%s`" % (k, json.dumps(ev[k], default=str)[:1500]) for k in ("commit", "seed", "days_requested", "days_reached", "stop_reason", "args")]
    segst = [dict(sg["status"] or {}, name=sg["name"]) for sg in arc.segs.list]
    ev["segment_status"] = segst
    L += ["", "## Segments", ""] + table(["segment", "stop", "days", "seconds", "run", "currency leak", "item leaks"], [(s.get("name"), s.get("stop_reason"), "%s-%s" % (s.get("start_day"), s.get("days_reached")),
                                                                                                         s.get("job_seconds") or s.get("wall_seconds"), s.get("run_url", "local"), s.get("currency_leak"), s.get("item_leaks") or "none") for s in segst])
    L += ["", "## Sessions", ""] + table(["session", "completeness", "bytes", "events", "scenario", "flags"], [(s["session"], s["completeness"], s["bytes"], s["events"], s["scenario"], json.dumps(s["flags"])[:120]) for s in ev["sessions"]])
    L += ["", "## Save and load at each segment's end (loaded into a fresh world, saved again, section by section)", ""] + table(["segment", "day", "exact", "sections differing"],
        [(sg["name"], (sg.get("save_roundtrip") or {}).get("day", "-"), (sg.get("save_roundtrip") or {}).get("exact", "not checked (last segment)"),
          ", ".join((sg.get("save_roundtrip") or {}).get("differ", [])) or "-") for sg in segst])
    L += ["", "## Fingerprints at checkpoints", ""] + table(["day", "fingerprint"], sorted(ev["fingerprints"].items()))
    L += ["", "## Determinism (a second independent run of the same seed and configuration)", "", json.dumps(det, default=str) if det else "Not compared in this report (pass --compare RUN_DIR2)."]
    _write(os.path.join(out_dir, "I_evidence_index.md"), "\n".join(L) + "\n")
    # ---------------- A
    pop = lv.k("population_day")
    p0, p1 = (pop[0], pop[-1]) if pop else (None, None)
    L = ["# A. Executive report: what happened", "", "Seed %s, commit `%s`, days %s of %s (%s). Facts first; interpretations are in their own section." % (
        status.get("seed"), status.get("commit"), status.get("days_reached"), status.get("days_requested"), status.get("stop_reason")), "", "## Observed facts", ""]
    if p0:
        L.append("- Village people %s on day %s, %s on day %s; households %s -> %s; bandits %s -> %s; wilderness %s -> %s; off-map settlements %s -> %s." % (
            need(p0, "alive"), p0["day"], need(p1, "alive"), p1["day"], need(p0, "households"), need(p1, "households"), need(p0, "stage:bandit", 0), need(p1, "stage:bandit", 0),
            need(p0, "wilderness_population", 0), need(p1, "wilderness_population", 0), need(p0, "offmap_population"), need(p1, "offmap_population")))
    L.append("- Births %d, deaths %d (causes: %s)." % (len(lv.k("birth")), len(lv.k("death")), dict(Counter(kv(e["detail"], "cause") for e in lv.k("death")).most_common(6))))
    L.append("- Households formed %d (%s); homesteads %d (%s)." % (len(lv.k("household_formed")), dict(Counter(ctx(e, "track") for e in lv.k("household_formed"))),
                                                                    len(hs), dict(Counter(h["status"] for h in hs.values()))))
    L.append("- Migration rows %d (%s); journeys %d." % (len(mig), dict(Counter(r["type"] for r in mig).most_common(6)), len(journeys)))
    L.append("- Clans: members %s -> %s, recruits by source %s, departures %d, reconciliation residual %d." % (bl["start"]["members"], bl["end"]["members"], bl["recruits_by_source"] or "none",
                                                                                                         bl["flows"].get("departures", 0), bl["residual"]))
    L.append("- Economy: trades %s, coins traded %s; currency and item ledgers reconciled: %s." % (econ["trade"].get("trades"), econ["trade"].get("trade_coins"), econ["reconciled"]))
    L.append("- Roads: %s; landmarks found %d; player journeys %d." % (econ["roads"] or "no change recorded", len(lv.k("landmark_discovered")), len(lv.k("travel_destination_set"))))
    L += ["", "## Feature classification (section 12, organic run)", ""] + table(["feature", "opportunities", "rejected", "failed", "partial", "completed", "sustained", "classification"],
        [(f["feature"], f["opportunities"], f["counts"]["rejected"], f["counts"]["failed"], f["counts"]["partial"], f["counts"]["completed"], f["counts"]["sustained"], f["text"]) for f in feats])
    L += ["", "## Life histories (F)", ""] + ["- %s %s: %s" % (cid, title, ("%s %s, %s" % (hist[cid]["ref"], hist[cid]["name"], hist[cid]["final"])) if hist[cid] else "unobserved") for cid, title, _ in CASES]
    if tgt:
        L += ["", "## Targeted scenarios (separate evidence: a mechanic can work; not its natural frequency)", ""] + table(["scenario", "result", "cases"], [(s["name"], s.get("result"), ",".join(s.get("cases", []))) for s in tgt.get("scenarios", [])])
    L += ["", "## Interpretation (derived from the facts above, by stated rules)", ""]
    if p0 and p1:
        a0, a1 = num(need(p0, "alive")) or 0, num(need(p1, "alive")) or 0
        L.append("- Village trend: %s (end/start %.2f)." % ("declining" if a1 < 0.8 * a0 else "growing" if a1 > 1.2 * a0 else "stable", a1 / a0 if a0 else 0))
    obs = [f["feature"] for f in feats if f["classification"] in ("completed", "sustained")]
    none = [f["feature"] for f in feats if f["classification"] == "no_opportunity"]
    L.append("- Features seen completing or sustained organically: %s." % (", ".join(obs) or "none"))
    L.append("- Features with no organic opportunity in this run (need targeted evidence): %s." % (", ".join(none) or "none"))
    L.append("- Bandit population %s." % ("reconciles with its recorded flows" if bl["residual"] == 0 else "does NOT reconcile with its recorded flows (residual %d: see H)" % bl["residual"]))
    L.append("- Exceptions recorded: %d (H)." % len(exc))
    L += ["", "Reports: B_migration_ledger, C_bandit_ledger, D_homestead_ledger, E_economic_ledger, F_life_histories, G_charts (%s), H_exceptions, I_evidence_index." % ", ".join(chart_files)]
    _write(os.path.join(out_dir, "A_executive.md"), "\n".join(L) + "\n")
    _write(os.path.join(out_dir, "features.json"), json.dumps(feats, indent=1))
    data = {"format": "mml-flight-lives/1", "status": {k: status.get(k) for k in ("commit", "seed", "days_requested", "days_reached", "stop_reason")}, "features": feats,
            "bandit_ledger": bl, "homestead_by_track": {k: dict(v) for k, v in by_track.items()}, "young_adult_rate": rates, "economy": econ,
            "people": pc, "cases": {k: (v["ref"] if v else None) for k, v in hist.items()}, "histories": hist, "exceptions": exc, "evidence": ev,
            "homesteads": {k: dict(v, stages=dict(v["stages"]), production=dict(v["production"]), consumption=dict(v["consumption"])) for k, v in hs.items()}}
    _write(os.path.join(out_dir, "lives.json"), json.dumps(data, indent=1, default=str))
    return data


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("run_dir")
    ap.add_argument("--out", default="")
    ap.add_argument("--targeted", default="", help="the targeted scenarios' output directory (tools/flight_scenarios.py)")
    ap.add_argument("--compare", default="", help="a second run of the same seed and configuration: compare event streams and fingerprints")
    a = ap.parse_args()
    out = a.out or os.path.join(a.run_dir, "lives")
    d = build(a.run_dir, out, a.targeted or None, a.compare or None)
    print(json.dumps({"out": out, "features": {f["feature"]: f["classification"] for f in d["features"]}, "cases": d["cases"],
                      "bandit_residual": d["bandit_ledger"]["residual"], "exceptions": len(d["exceptions"]),
                      "determinism": (d["evidence"]["determinism"] or {}).get("identical")}, indent=1))
    det = d["evidence"]["determinism"]
    return 1 if det is not None and not det["identical"] else 0


if __name__ == "__main__":
    sys.exit(main())
