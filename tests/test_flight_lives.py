"""Tests for the living-world reports (B25R1-016, tools/flight_lives.py): from a small synthetic archive written in the recorder's own
chunk format, a young adult's homestead lifecycle is reconstructed as case A with its stages, an intention or a claim alone is not a
completed homestead, the bandit ledger reconciles (and an unexplained change shows as a residual), cases with no matching event are
"unobserved", an unmapped event reaches the exception report, every report file is written, and two identical runs compare
identical while a changed run does not. Standard library only; no Godot needed."""
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tests"))
import flight_lives  # noqa: E402
from test_sim_gate import FULL_EVENT, write_chunk  # noqa: E402

CODES = json.load(open(ROOT / "game" / "data" / "recorder_codes.json"))["chronicle"]


class Run:
    """A one-session archive: chronicle events with ctx/needs factors, participants and state changes, a snapshot per day."""

    def __init__(self):
        self.ev = []        # (day, minute, kind, actor, f)

    def add(self, day, kind, actor, **f):
        self.ev.append((day, 60 + len(self.ev), kind, actor, f))

    def write(self, root):
        s = Path(root) / "rec" / "s1"
        seq, eid = 0, 0
        days = sorted({e[0] for e in self.ev})
        for day in days:
            ev, fac, part, sc = [], [], [], []
            for d, minute, kind, actor, f in [e for e in self.ev if e[0] == day]:
                eid += 1
                spec = CODES.get(kind, ["life", "death", "life", 0, ""]) if kind != "death" else ["life", "death", "life", 0, ""]
                for k, v in f.get("ctx", {}).items():
                    seq += 1
                    fac.append([seq, eid, "ctx", k, v, "text", "chronicle", "yes"])
                for k, v in f.get("needs", {}).items():
                    seq += 1
                    fac.append([seq, eid, "needs", k, v, "value", "live_code", "yes"])
                for r, role in f.get("parts", []):
                    seq += 1
                    part.append([seq, eid, r, role])
                for r, prop, b, a in f.get("sc", []):
                    seq += 1
                    sc.append([seq, eid, r, prop, b, a, "not evaluated", "summary"])
                seq += 1
                ev.append([seq, eid, -1, eid, f.get("object", ""), day, minute, f.get("place", ""), -1, -1, spec[0], spec[1], spec[2], kind, actor,
                           f.get("outcome", "ok"), f.get("reason", ""), "", f.get("detail", "")])
            dd = s / ("d%04d" % day)
            write_chunk(dd / "event.h01.p0.jsonl.gz", "event", FULL_EVENT, ev)
            if fac:
                write_chunk(dd / "factor.h01.p0.jsonl.gz", "factor", ["seq", "event", "option", "factor", "value", "unit", "source", "evaluated"], fac)
            if part:
                write_chunk(dd / "participant.h01.p0.jsonl.gz", "participant", ["seq", "event", "ref", "role"], part)
            if sc:
                write_chunk(dd / "state_change.h01.p0.jsonl.gz", "state_change", ["seq", "event", "ref", "prop", "before", "after", "delta", "authority"], sc)
            seq += 1
            write_chunk(dd / "snapshot.h02.p0.jsonl.gz", "snapshot", ["seq", "day", "hour", "alive", "trades_h", "trade_coins_h", "wall_ms"], [[seq, day, 2, 100, 3, 30, 17 + day]])
        (s / "session.json").write_text(json.dumps({"session": "s1", "seed": 7, "commit": "abc", "ended": True, "completeness": "complete", "start_unix": 1}))
        (Path(root) / "status.json").write_text(json.dumps({"seed": 7, "commit": "abc", "days_requested": 10, "days_reached": 9, "stop_reason": "completed",
                                                            "ok": True, "currency_leak": 0, "item_leaks": {}, "start_day": 0}))


def census(run, day, members, dependants=0):
    run.add(day, "clan_census", "world", place="clan:bandit", object="clan:bandit", needs={"members": members, "dependants": dependants})
    run.add(day, "population_day", "world", needs={"alive": 100, "households": 20, "stage:bandit": members, "wilderness_population": 0, "offmap_population": 50})


def story():
    r = Run()
    census(r, 0, 3)
    r.add(1, "household_formed", "p:5", ctx={"track": "young_adult", "name": "Ann Smith"})
    r.add(1, "homestead_evaluated", "p:5", ctx={"track": "young_adult", "name": "Ann Smith"}, object="homestead:hs1")
    r.add(1, "homestead_chosen", "p:5", ctx={"track": "young_adult", "path": "lawful"}, object="homestead:hs1")
    r.add(2, "homestead_travel_begin", "p:5", ctx={"track": "young_adult", "path": "lawful", "origin": "hh:2", "destination": "homestead:hs1"}, object="homestead:hs1")
    r.add(2, "homestead_claimed", "p:5", ctx={"track": "young_adult"}, object="homestead:hs1", place="homestead:hs1")
    r.add(3, "homestead_shelter_built", "p:5", ctx={"track": "young_adult"}, object="homestead:hs1", place="homestead:hs1")
    r.add(3, "homestead_residence", "p:5", ctx={"track": "young_adult", "path": "lawful"}, object="homestead:hs1", place="homestead:hs1")
    r.add(4, "wild_production", "p:5", ctx={"action": "fell"}, object="homestead:hs1", place="homestead:hs1", sc=[["p:5", "item:log", 0, 4]])
    r.add(8, "homestead_year", "p:5", ctx={"track": "young_adult"}, object="homestead:hs1", place="homestead:hs1")
    # an intention and a claim that never became a residence
    r.add(2, "homestead_chosen", "p:9", ctx={"track": "young_adult"}, object="homestead:hs2")
    r.add(3, "homestead_claimed", "p:9", ctx={"track": "young_adult"}, object="homestead:hs2", place="homestead:hs2")
    # a recruit and a death in the band
    r.add(4, "recruit_joined", "p:11", ctx={"source": "runaway", "faction_before": "village", "faction": "clan:bandit"}, place="clan:bandit")
    r.add(5, "death", "p:12", detail="cause=slain; role=bandit job= household=-1 age=30.0; faction=clan:bandit")
    r.add(6, "unmapped_event", "p:5", detail="life_event:something_new")
    census(r, 9, 3)
    return r


class FlightLivesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def build(self, run, name="run", **kw):
        d = self.tmp / name
        run.write(d)
        return flight_lives.build(str(d), str(d / "lives"), **kw), d

    def test_reports_and_cases(self):
        data, d = self.build(story())
        for f in ("A_executive.md", "B_migration_ledger.csv", "B_migration_ledger.md", "C_bandit_ledger.md", "D_homestead_ledger.md", "E_economic_ledger.md",
                  "F_life_histories.md", "H_exceptions.md", "I_evidence_index.md", "features.json", "lives.json"):
            self.assertTrue((d / "lives" / f).exists(), f)
        self.assertEqual(data["cases"]["A"], "p:5")
        self.assertIsNone(data["cases"]["F"])
        self.assertIn("Unobserved", (d / "lives" / "F_life_histories.md").read_text())
        kinds = [t["kind"] for t in data["histories"]["A"]["timeline"]]
        self.assertEqual(kinds[:3], ["household_formed", "homestead_evaluated", "homestead_chosen"])
        self.assertIn("homestead_residence", kinds)
        self.assertTrue(any(f.endswith(".svg") for f in (p.name for p in (d / "lives" / "G_charts").iterdir())))

    def test_intention_is_not_a_homestead(self):
        data, _ = self.build(story())
        hs = data["homesteads"]
        self.assertEqual(hs["homestead:hs1"]["status"], "sustained")
        self.assertEqual(hs["homestead:hs2"]["status"], "claimed")
        f = {x["feature"]: x for x in data["features"]}["homestead_young_adult"]
        self.assertEqual(f["counts"]["completed"], 1)
        self.assertEqual(f["classification"], "sustained")

    def test_bandit_ledger_reconciles(self):
        data, _ = self.build(story())
        bl = data["bandit_ledger"]
        self.assertEqual(bl["flows"].get("recruits"), 1)
        self.assertEqual(bl["flows"].get("deaths_members"), 1)
        self.assertEqual(bl["residual"], 0)
        self.assertEqual(bl["recruits_by_source"], {"runaway": 1})
        r = story()
        r.ev = [e for e in r.ev if e[2] != "death"]      # a death the archive does not hold: the census says 3, the flows 4
        data, _ = self.build(r, "run2")
        self.assertEqual(data["bandit_ledger"]["residual"], -1)
        self.assertTrue(any(x["kind"] == "bandit_ledger_unexplained" for x in data["exceptions"]))

    def test_unmapped_in_exceptions(self):
        data, _ = self.build(story())
        self.assertTrue(any(x["kind"] == "unmapped_event" and "something_new" in x["observation"] for x in data["exceptions"]))

    def test_compare(self):
        a = self.tmp / "a"
        b = self.tmp / "b"
        story().write(a)
        story().write(b)
        self.assertTrue(flight_lives.compare(str(a), str(b))["identical"])
        r = story()
        r.add(7, "raid", "p:11")
        c = self.tmp / "c"
        r.write(c)
        res = flight_lives.compare(str(a), str(c))
        self.assertFalse(res["identical"])
        self.assertEqual(res["first_stream_difference"], "0/d0007")


if __name__ == "__main__":
    unittest.main()
