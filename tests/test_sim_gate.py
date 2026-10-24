"""Tests for the pre-build simulation gate (SIM-GATE-01): the archive check, the gate's decisions, the workbook check and
the Android exclusion of the desktop export (owner amendment, 2026-10-24). Standard library only; no Godot needed."""
import gzip
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import check_workbook  # noqa: E402
import recorder_archive  # noqa: E402
import sim_suite  # noqa: E402


def write_chunk(path, table, columns, rows, footer=True):
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [json.dumps({"schema": recorder_archive.SCHEMA, "session": "s1", "table": table, "day": 0, "hour": 7, "part": 0, "columns": columns,
                         "first_seq": rows[0][0], "last_seq": rows[-1][0]})]
    h = hashlib.sha256()
    for r in rows:
        line = json.dumps(r)
        lines.append(line)
        h.update((line + "\n").encode())
    if footer:
        lines.append(json.dumps({"footer": True, "rows": len(rows), "sha256": h.hexdigest()}))
    with gzip.open(path, "wt") as f:
        f.write("\n".join(lines) + "\n")


SNAP_COLS = ["seq", "day", "hour", "alive", "total_coins"]
EVENT_COLS = ["seq", "id", "category", "subtype", "outcome", "detail"]


def make_archive(root, footer=True, gap=False, ended=True):
    s = Path(root) / "s1"
    write_chunk(s / "d0000" / "snapshot.h07.p0.jsonl.gz", "snapshot", SNAP_COLS, [[1, 0, 7, 100, 3000], [3, 0, 8, 100, 3001]])
    write_chunk(s / "d0000" / "event.h07.p0.jsonl.gz", "event", EVENT_COLS, [[2, 1, "life", "death", "ok", "cause=old age; role=elder"]], footer=footer)
    last = 4 if gap else 3
    sess = {"schema": recorder_archive.SCHEMA, "session": "s1", "ended": ended, "completeness": "complete" if ended else "recording", "last_seq": last,
            "counts": {"snapshot": 2, "event": 1}, "unknown_codes": {}, "recovered": [],
            "final_snapshot": {"day": 0, "hour": 8, "alive": 100, "total_coins": 3001}}
    (s / "session.json").write_text(json.dumps(sess))
    return str(s)


class ArchiveCheck(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def test_whole_archive_passes(self):
        r = recorder_archive.verify(make_archive(self.tmp))
        self.assertTrue(r["ok"], r["problems"])
        self.assertEqual(r["snapshot_hours"], 2)
        self.assertEqual(r["villager_deaths"], 1)
        self.assertEqual(r["final_snapshot"]["total_coins"], 3001)

    def test_truncated_chunk_fails(self):
        r = recorder_archive.verify(make_archive(self.tmp, footer=False))
        self.assertFalse(r["ok"])
        self.assertTrue(any("no footer" in p for p in r["problems"]), r["problems"])

    def test_missing_rows_fail(self):
        r = recorder_archive.verify(make_archive(self.tmp, gap=True))
        self.assertTrue(any("row sequence" in p for p in r["problems"]), r["problems"])

    def test_unfinished_session_fails(self):
        r = recorder_archive.verify(make_archive(self.tmp, ended=False))
        self.assertTrue(any("never ended" in p for p in r["problems"]), r["problems"])

    def test_tampered_row_fails(self):
        s = Path(make_archive(self.tmp))
        p = s / "d0000" / "snapshot.h07.p0.jsonl.gz"
        text = gzip.open(p, "rt").read().replace("3001", "3002")
        with gzip.open(p, "wt") as f:
            f.write(text)
        r = recorder_archive.verify(str(s))
        self.assertTrue(any("footer does not match" in p for p in r["problems"]), r["problems"])


def fake_sim(path, leak=0, items=None, alive=100, coins=3000, days=10):
    sample = lambda d: {"day": d, "fingerprint": "f%d" % d, "people": {"alive": alive, "households": 25, "births": 0},
                        "currency": {"total": coins, "leak": leak if d == days else 0}, "money": {"treasury": 300},
                        "materials": {"deposits": {}}, "wildlife": {}, "ledger": {"items": (items or {}) if d == days else {}, "table": {}}}
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"samples": [sample(d) for d in range(0, days + 1, 5)], "deaths": [], "reached": days}))


class GateDecisions(unittest.TestCase):
    """The gate's own evaluation on fabricated outputs: a defect blocks, an outcome never does."""

    def setUp(self):
        self.out = Path(tempfile.mkdtemp())
        self.jobs = [{"run": "eq_s1", "scenario": "A", "cover": "A", "seed": 1, "days": 10, "record": False, "args": []},
                     {"run": "det_s1", "scenario": "det", "cover": "", "seed": 1, "days": 10, "record": False, "args": []}]

    def tearDown(self):
        shutil.rmtree(self.out)

    def run_gate(self, code=0, log="", only_eq=False, **sim):
        results = {}
        for j in self.jobs:
            fake_sim(self.out / j["run"] / "sim.json", **(sim if j["run"] == "eq_s1" or not only_eq else {}))
            (self.out / j["run"] / "run.log").write_text(log if j["run"] == "eq_s1" else "")
            results[j["run"]] = {"run": j["run"], "code": code if j["run"] == "eq_s1" else 0, "seconds": 1.0}
        ev = sim_suite.evaluate(self.jobs, results, self.out, "abc", partial=True, release_dir=self.out / "no_baselines")
        return [f for f in ev["findings"] if f["blocking"]], ev

    def test_clean_runs_pass(self):
        blocking, ev = self.run_gate()
        self.assertEqual(blocking, [])
        self.assertEqual(ev["history"][0]["verdict"], "MATCH")

    def test_currency_leak_blocks(self):
        blocking, _ = self.run_gate(leak=7, code=1)
        self.assertTrue(any("conservation" in f["description"] for f in blocking), blocking)

    def test_item_leak_blocks(self):
        blocking, _ = self.run_gate(items={"log": {"diff": 1}})
        self.assertTrue(any("conservation" in f["description"] for f in blocking), blocking)

    def test_script_error_is_a_crash(self):
        blocking, _ = self.run_gate(log="SCRIPT ERROR: boom\n")
        self.assertTrue(any(f["description"].startswith("crash") for f in blocking), blocking)

    def test_determinism_difference_blocks(self):
        blocking, _ = self.run_gate(coins=3001, only_eq=True)     # eq_s1 differs from det_s1 at every checkpoint
        self.assertTrue(any("determinism" in f["description"] for f in blocking), blocking)

    def test_baseline_difference_blocks(self):
        base = self.out / "release"
        base.mkdir()
        fake_sim(self.out / "b" / "sim.json", alive=100)
        samples = {s["day"]: s for s in json.load(open(self.out / "b" / "sim.json"))["samples"]}
        (base / "sim_baseline.json").write_text(json.dumps({"commit": "base", "results": {"1": {"10": sim_suite.summarise(samples[10])}}}))
        results = {}
        for j in self.jobs:
            fake_sim(self.out / j["run"] / "sim.json", alive=99)
            (self.out / j["run"] / "run.log").write_text("")
            results[j["run"]] = {"run": j["run"], "code": 0, "seconds": 1.0}
        ev = sim_suite.evaluate(self.jobs, results, self.out, "abc", partial=True, release_dir=base)
        self.assertTrue(any("accepted baseline" in f["description"] and f["blocking"] for f in ev["findings"]), ev["findings"])
        self.assertTrue(any(h["verdict"] == "REGRESSION" for h in ev["history"]))

    def test_hardship_never_blocks(self):
        blocking, _ = self.run_gate(alive=3)            # a village nearly dead: an outcome, not a defect (WDR-022)
        self.assertEqual(blocking, [])

    def test_full_suite_requires_coverage(self):
        results = {}
        for j in self.jobs:
            fake_sim(self.out / j["run"] / "sim.json")
            (self.out / j["run"] / "run.log").write_text("")
            results[j["run"]] = {"run": j["run"], "code": 0, "seconds": 1.0}
        ev = sim_suite.evaluate(self.jobs, results, self.out, "abc", partial=False, release_dir=self.out / "no_baselines")
        self.assertTrue(any("coverage" in f["description"] and f["blocking"] for f in ev["findings"]))


class Rotation(unittest.TestCase):
    def test_rotating_seeds_follow_the_commit(self):
        a = [j["seed"] for j in sim_suite.rotating("0123456789abcdef0123456789abcdef01234567")]
        b = [j["seed"] for j in sim_suite.rotating("0123456789abcdef0123456789abcdef01234567")]
        c = [j["seed"] for j in sim_suite.rotating("fedcba9876543210fedcba9876543210fedcba98")]
        self.assertEqual(a, b)
        self.assertNotEqual(a, c)
        self.assertEqual(len(set(a)), sim_suite.ROTATING_COUNT)
        self.assertTrue(all(100 <= s < 10000 for s in a + c))

    def test_scenarios_cover_every_required_area(self):
        covered = set("".join(j["cover"] for j in sim_suite.SCENARIOS)) | {"F", "H"}     # F, H also by the probes and the perf run
        self.assertEqual(covered, set(sim_suite.COVERAGE))


class WorkbookCheck(unittest.TestCase):
    def test_not_a_workbook_fails(self):
        with tempfile.NamedTemporaryFile(suffix=".xlsx", delete=False) as f:
            f.write(b"not a zip")
        try:
            self.assertFalse(check_workbook.check(f.name)["ok"])
        finally:
            os.unlink(f.name)

    def test_missing_sheets_fail(self):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "w.xlsx")
            with zipfile.ZipFile(p, "w") as z:
                z.writestr("xl/workbook.xml", '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
                           'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
                           '<sheet name="Runs" sheetId="1" r:id="rId1"/></sheets></workbook>')
                z.writestr("xl/_rels/workbook.xml.rels", '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                           '<Relationship Id="rId1" Type="x" Target="worksheets/sheet1.xml"/></Relationships>')
                z.writestr("xl/worksheets/sheet1.xml", '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
                           '<row r="1"><c r="A1" t="inlineStr"><is><t>run</t></is></c></row></sheetData></worksheet>')
            r = check_workbook.check(p)
            self.assertFalse(r["ok"])
            self.assertTrue(any("missing sheet: Executive Summary" in x for x in r["problems"]))
            self.assertTrue(any("sheet Runs is empty" in x for x in r["problems"]))

    def test_definition_names_the_directive_sheets(self):
        defs = json.load(open(ROOT / "game" / "data" / "sim_workbook.json"))
        self.assertEqual(defs["required_sheets"], ["Executive Summary", "Population and Households", "Economy", "NPC Activity", "Relationships and Morality",
                                                   "Crime and Justice", "Production and Resources", "Performance", "Historical Comparison", "Regression Register"])
        self.assertTrue(all(len(s) <= 31 for s in defs["required_sheets"] + defs["extra_sheets"]))


class AndroidExclusion(unittest.TestCase):
    """Owner amendment: the APK carries no workbook or desktop export code (export_presets.cfg exclude_filter)."""

    def presets(self):
        text = (ROOT / "game" / "export_presets.cfg").read_text()
        out, name = {}, None
        for line in text.splitlines():
            m = re.match(r'name="(.+)"', line)
            if m:
                name = m.group(1)
            m = re.match(r'exclude_filter="(.*)"', line)
            if m and name:
                out[name] = [x.strip() for x in m.group(1).split(",")]
        return out

    def test_android_excludes_the_export(self):
        ex = self.presets()["Android"]
        self.assertIn("scripts/recorder_export/*", ex)
        self.assertIn("data/sim_workbook.json", ex)

    def test_desktop_keeps_the_export(self):
        for name in ("Windows Desktop", "Linux"):
            ex = self.presets()[name]
            self.assertNotIn("scripts/recorder_export/*", ex)
            self.assertNotIn("data/sim_workbook.json", ex)

    def test_shipped_code_never_names_the_export(self):
        """Only main.gd's LIVE_EXPORT path loads it (by path, at run time); nothing else in the shipped scripts refers to it."""
        hits = []
        for p in (ROOT / "game" / "scripts").rglob("*.gd"):
            if "recorder_export" in p.parts:
                continue
            for i, line in enumerate(p.read_text().splitlines(), 1):
                if "recorder_export" in line or "sim_workbook" in line:
                    hits.append("%s:%d" % (p.relative_to(ROOT), i))
        self.assertEqual([h for h in hits if not h.startswith("game/scripts/main.gd")], [], hits)
        main = (ROOT / "game" / "scripts" / "main.gd").read_text()
        self.assertNotIn('preload("res://scripts/recorder_export', main)

    def test_export_scripts_have_no_class_name(self):
        for p in (ROOT / "game" / "scripts" / "recorder_export").glob("*.gd"):
            self.assertNotIn("\nclass_name", "\n" + p.read_text(), p)

    def test_recorder_is_off_by_default(self):
        cfg = json.load(open(ROOT / "game" / "data" / "recorder.json"))
        self.assertIs(cfg["enabled"], False)


if __name__ == "__main__":
    unittest.main()
