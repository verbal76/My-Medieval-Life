"""Tests for the flight recorder campaign analyser (FLIGHT-REC-01, tools/flight_analyse.py): it finds a villager failing the same
purchase over and over (the axe case), leaves ordinary repeated work alone, reads a chained run's segments and status, and keeps
confirmed defects (a broken ledger) apart from suspicions. Standard library only; no Godot needed."""
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tests"))
import flight_analyse  # noqa: E402
import recorder_archive  # noqa: E402
from test_sim_gate import FULL_EVENT, write_chunk  # noqa: E402


def event(i, day, minute, category, subtype, actor, outcome="ok", reason="", detail="", subsystem="act"):
    return [i, -1, i, "", day, minute, "", -1, -1, "brain", subsystem, category, subtype, actor, outcome, reason, "", detail]


def archive(root, events, name="s1"):
    """One session whose events (rows without seq) are spread over their days' directories, with an hourly snapshot per day."""
    s = Path(root) / name
    seq = 0
    by_day = {}
    for e in events:
        by_day.setdefault(e[4], []).append(e)
    counts = {"event": 0, "snapshot": 0}
    snap_cols = ["seq", "day", "hour", "alive", "food_days", "total_coins"]
    for day in sorted(by_day):
        rows = []
        for e in by_day[day]:
            seq += 1
            rows.append([seq] + e)
        write_chunk(s / ("d%04d" % day) / "event.h07.p0.jsonl.gz", "event", FULL_EVENT, rows)
        counts["event"] += len(rows)
        seq += 1
        write_chunk(s / ("d%04d" % day) / "snapshot.h07.p1.jsonl.gz", "snapshot", snap_cols, [[seq, day, 7, 100, 5.0, 3000]])
        counts["snapshot"] += 1
    sess = {"schema": recorder_archive.SCHEMA, "session": name, "start_unix": 1, "ended": True, "completeness": "complete", "last_seq": seq,
            "events": counts["event"], "counts": counts, "unknown_codes": {}, "recovered": [], "final_snapshot": {"day": 0, "hour": 8, "alive": 100}}
    (s / "session.json").write_text(json.dumps(sess))
    return s


class FlightAnalyse(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def run_dir(self, events, status=None, log=""):
        seg = self.tmp / "run" / "seg1"
        (seg / "rec").mkdir(parents=True)
        archive(seg / "rec", events)
        (seg / "status.json").write_text(json.dumps(status or {"seed": 1, "days_requested": 3, "days_reached": 3, "stop_reason": "completed", "ok": True, "commit": "abc"}))
        (seg / "sim.log").write_text(log)
        return self.tmp / "run"

    def kinds(self, result):
        return {(f["kind"], f["npc"]): f for f in result["findings"]}

    def test_repeated_failed_purchase_is_found_and_work_is_not(self):
        evs, i = [], 0
        for day in range(3):
            for k in range(30):                  # the axe: 90 failed buy_from, never a success
                i += 1
                evs.append(event(i, day, 400 + k, "action", "buy_from", "p:7", "failed", "act_returned_false", '{"item":"axe","vendor":3}'))
            for k in range(30):                  # ordinary work: a miner mining all day, every attempt fine but an odd failure
                i += 1
                evs.append(event(i, day, 400 + k, "action", "mine", "p:9", "failed" if k % 10 == 0 else "ok", "", '{"x":1,"y":2}'))
        res, summary = flight_analyse.build(str(self.run_dir(evs)), str(self.tmp / "out"))
        k = self.kinds(res)
        axe = k.get(("repeated_failed_action", "p:7"))
        self.assertIsNotNone(axe, "the axe loop was not found")
        self.assertEqual(axe["severity"], "HIGH")
        self.assertEqual(axe["count"], 90)
        self.assertEqual((axe["day_from"], axe["day_to"]), (0, 2))
        self.assertFalse(axe["confirmed"])
        self.assertNotIn(("repeated_failed_action", "p:9"), k)
        self.assertEqual(summary["stop_reason"], "completed")
        for f in ("findings.json", "findings.md", "workbook_data.json", "summary.json"):
            self.assertTrue((self.tmp / "out" / f).is_file(), f)
        sheets = [s["name"] for s in json.loads((self.tmp / "out" / "workbook_data.json").read_text())["sheets"]]
        self.assertEqual(sheets, json.loads((ROOT / "game" / "data" / "sim_workbook.json").read_text())["flight_recorder"]["required_sheets"])

    def test_plan_oscillation(self):
        evs = []
        for k in range(40):                      # A, B, A, B ... all day
            evs.append(event(k + 1, 0, 400 + k, "decision", "plan_next", "p:4", detail="doing=x; plan=" + ("go,work" if k % 2 else "go,do:buy_food"), subsystem="decide"))
        res, _ = flight_analyse.build(str(self.run_dir(evs)), str(self.tmp / "out"))
        f = self.kinds(res).get(("decision_oscillation", "p:4"))
        self.assertIsNotNone(f)
        self.assertGreaterEqual(f["evidence"]["alternations"], 39)

    def test_fatal_ledger_is_a_confirmed_critical(self):
        evs = [event(1, 0, 400, "action", "eat", "p:1")]
        log = "day  10: alive 100\nFATAL day 10 seed 1: currency leak 5; items {}; deposits {}; animals {}\n"
        st = {"seed": 1, "days_requested": 365, "days_reached": 10, "stop_reason": "fatal", "ok": False, "commit": "abc"}
        res, summary = flight_analyse.build(str(self.run_dir(evs, st, log)), str(self.tmp / "out"))
        crit = [f for f in res["findings"] if f["kind"] == "ledger_broken"]
        self.assertEqual(len(crit), 1)
        self.assertTrue(crit[0]["confirmed"])
        self.assertEqual(crit[0]["severity"], "CRITICAL")
        self.assertEqual(crit[0]["day_from"], 10)
        self.assertEqual((summary["stop_reason"], summary["days_reached"], summary["confirmed_defects"]), ("fatal", 10, 1))

    def test_segments_are_read_in_order(self):
        run = self.tmp / "run"
        for n, (d0, d1, why) in enumerate([(0, 2, "segment"), (2, 4, "completed")], start=1):
            seg = run / ("seg%d" % n)
            (seg / "rec").mkdir(parents=True)
            archive(seg / "rec", [event(1, d0, 400, "action", "eat", "p:1"), event(2, d1 - 1, 400, "action", "eat", "p:1")], name="s%d" % n)
            (seg / "status.json").write_text(json.dumps({"seed": 2, "days_requested": 4, "start_day": d0, "days_reached": d1, "stop_reason": why, "ok": True}))
        res, summary = flight_analyse.build(str(run), str(self.tmp / "out"))
        self.assertEqual((summary["days_reached"], summary["stop_reason"]), (4, "completed"))
        self.assertEqual([s["segment"] for s in res["status"]["segments"]], ["seg1", "seg2"])
        self.assertEqual(res["rows_read"]["event"], 4)
        self.assertEqual([c["session"] for c in res["archive_checks"]], ["s1", "s2"])     # each segment's session checked on its own


if __name__ == "__main__":
    unittest.main()
