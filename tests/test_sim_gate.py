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
import ci_plan  # noqa: E402
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


FULL_EVENT = ["seq", "id", "parent", "interaction", "object", "day", "minute", "settlement", "x", "y", "system", "subsystem", "category", "subtype",
              "actor", "outcome", "reason", "rule", "detail"]


def ev(seq, i, day, minute, system, subsystem, category, subtype, actor, obj="", parent=-1, outcome="ok"):
    return [seq, i, parent, i, obj, day, minute, "", -1, -1, system, subsystem, category, subtype, actor, outcome, "", "", ""]


def make_full(root, events, parts=(), changes=(), flags=None, name="s1", net_factors=()):
    """An archive with full event columns (the X20-FINAL content checks): events are rows without seq (it is given here)."""
    s = Path(root) / name
    seq = 0
    rows = []
    for e in events:
        seq += 1
        rows.append([seq] + list(e))
    write_chunk(s / "d0000" / "event.h07.p0.jsonl.gz", "event", FULL_EVENT, rows)
    counts = {"event": len(rows)}
    tables = [("participant", ["seq", "event", "ref", "role"], parts), ("state_change", ["seq", "event", "ref", "prop", "before", "after", "delta", "authority"], changes),
              ("factor", ["seq", "event", "option", "factor", "value", "unit", "source", "evaluated"], net_factors)]
    for t, cols, data in tables:
        if data:
            trows = []
            for d in data:
                seq += 1
                trows.append([seq] + list(d))
            write_chunk(s / "d0000" / ("%s.h07.p0.jsonl.gz" % t), t, cols, trows)
            counts[t] = len(trows)
    seq += 1
    write_chunk(s / "d0000" / "snapshot.h07.p1.jsonl.gz", "snapshot", SNAP_COLS, [[seq, 0, 7, 100, 3000]])
    counts["snapshot"] = 1
    sess = {"schema": recorder_archive.SCHEMA, "session": name, "ended": True, "completeness": "complete", "last_seq": seq, "events": len(rows),
            "counts": counts, "unknown_codes": {}, "recovered": [], "final_snapshot": {"day": 0, "hour": 8, "alive": 100}, "flags": flags or {}}
    (s / "session.json").write_text(json.dumps(sess))
    return str(s)


class ContentChecks(unittest.TestCase):
    """X20-FINAL phase 5: the archive's content, read independently of the game."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def evs(self, rows):
        return [r[1:] for r in rows]

    def test_clean_content_passes(self):
        e = [ev(0, 1, 0, 600, "life", "death", "life", "death", "p:5")[1:], ev(0, 2, 0, 500, "brain", "act", "action", "eat", "p:5")[1:]]
        r = recorder_archive.verify(make_full(self.tmp, e))
        self.assertTrue(r["ok"], r["problems"])

    def test_missing_event_id_fails(self):
        e = [ev(0, 1, 0, 1, "brain", "act", "action", "eat", "p:1")[1:], ev(0, 3, 0, 2, "brain", "act", "action", "eat", "p:1")[1:]]
        r = recorder_archive.verify(make_full(self.tmp, e))
        self.assertTrue(any("event ids" in p for p in r["problems"]), r["problems"])

    def test_dangling_reference_fails(self):
        e = [ev(0, 1, 0, 1, "brain", "act", "action", "eat", "p:1")[1:]]
        r = recorder_archive.verify(make_full(self.tmp, e, parts=[(7, "p:1", "actor")]))
        self.assertTrue(any("naming an event" in p for p in r["problems"]), r["problems"])

    def test_action_after_death_fails(self):
        e = [ev(0, 1, 0, 600, "life", "death", "life", "death", "p:5")[1:], ev(0, 2, 0, 700, "brain", "act", "action", "eat", "p:5")[1:]]
        r = recorder_archive.verify(make_full(self.tmp, e))
        self.assertTrue(any("after a death" in p for p in r["problems"]), r["problems"])

    def test_bad_role_change_fails(self):
        e = [ev(0, 1, 0, 1, "life", "role", "life", "role_changed", "p:5")[1:]]
        r = recorder_archive.verify(make_full(self.tmp, e, changes=[(1, "p:5", "role", "elder", "child", "not evaluated", "life")]))
        self.assertTrue(any("role changes" in p for p in r["problems"]), r["problems"])

    def test_contract_lifecycle(self):
        good = [ev(0, 1, 0, 1, "contracts", "contract", "contract", "opened", "p:2", "contract:1")[1:],
                ev(0, 2, 0, 2, "contracts", "contract", "contract", "paid", "p:2", "contract:1")[1:],
                ev(0, 3, 0, 3, "contracts", "contract", "contract", "fulfilled", "p:2", "contract:1")[1:]]
        coins = [(1, "contract:1", "coins", 0, 10, 10, "contracts"), (2, "contract:1", "coins", 10, 0, -10, "contracts")]
        r = recorder_archive.verify(make_full(self.tmp, good, changes=coins))
        self.assertTrue(r["ok"], r["problems"])
        self.assertEqual(r["contracts"]["threads"], 1)
        bad = good + [ev(0, 4, 0, 4, "contracts", "contract", "contract", "paid", "p:2", "contract:1")[1:]]
        r = recorder_archive.verify(make_full(self.tmp, bad, changes=coins, name="s2"))
        self.assertTrue(any("contract or debt" in p for p in r["problems"]), r["problems"])

    def test_contract_coins_must_return(self):
        e = [ev(0, 1, 0, 1, "contracts", "contract", "contract", "opened", "p:2", "contract:1")[1:],
             ev(0, 2, 0, 3, "contracts", "contract", "contract", "lapsed", "p:2", "contract:1", outcome="failed")[1:]]
        r = recorder_archive.verify(make_full(self.tmp, e, changes=[(1, "contract:1", "coins", 0, 10, 10, "contracts")]))
        self.assertTrue(any("still set aside" in p for p in r["problems"]), r["problems"])

    def test_required_flags(self):
        e = [ev(0, 1, 0, 1, "brain", "act", "action", "eat", "p:1")[1:]]
        d = make_full(self.tmp, e, flags={"aspiration": False})
        r = recorder_archive.verify(d, require_flags={"aspiration": True})
        self.assertTrue(any("flag aspiration" in p for p in r["problems"]), r["problems"])
        self.assertTrue(recorder_archive.verify(d, require_flags={"aspiration": False})["ok"])

    def test_required_rows(self):
        e = [ev(0, 1, 0, 1, "brain", "act", "action", "eat", "p:1")[1:]]
        r = recorder_archive.verify(make_full(self.tmp, e), require_rows=["18.11"])
        self.assertTrue(any("not exercised" in p for p in r["problems"]), r["problems"])

    def test_judgment_chain_traced(self):
        e = [ev(0, 1, 0, 600, "judgment", "fact", "judgment", "fact:pickpocket", "p:-2", "fact:9")[1:],
             ev(0, 2, 0, 600, "judgment", "belief", "judgment", "witnessed", "p:3", "fact:9")[1:],
             ev(0, 3, 1, 100, "judgment", "belief", "judgment", "told", "p:4", "fact:9")[1:],
             ev(0, 4, 3, 600, "judgment", "choice", "judgment", "contract_accept", "p:4")[1:],
             ev(0, 5, 3, 610, "judgment", "choice", "judgment", "contract_accept", "p:7")[1:]]
        parts = [(1, "p:-2", "actor:1000"), (4, "p:-2", "counterparty"), (5, "p:-2", "counterparty")]
        r = recorder_archive.verify(make_full(self.tmp, e, parts=parts))
        ch = r["chains"]
        self.assertTrue(ch["complete"], ch)
        self.assertEqual((ch["crime_facts"], ch["beliefs"], ch["heard_not_seen"], ch["later_choices"], ch["later_choices_hearsay"]), (1, 2, 1, 1, 1))

    def test_participants_compared(self):
        def net(name, role, hashes):
            evs, facs = [], []
            for h, val in enumerate(hashes):
                evs.append(ev(0, h + 1, 0, h * 60 + 5, "net", role, "network", "net_state", "p:1")[1:])
                facs.append((h + 1, "section", "npcs", val, "hash", "network", "yes"))
            return make_full(self.tmp, evs, net_factors=facs, name=name)
        host = net("s_host", "host", ["a", "b", "c", "d"])
        ok = net("s_g1", "guest", ["a", "x", "c", "d"])
        bad = net("s_g2", "guest", ["a", "x", "y", "z"])
        r = recorder_archive.compare_participants([host, ok])
        self.assertTrue(r["ok"], r)
        r = recorder_archive.compare_participants([host, bad])
        self.assertFalse(r["ok"])


def fake_sim(path, leak=0, items=None, alive=100, coins=3000, days=10):
    sample = lambda d: {"day": d, "fingerprint": "f%d" % d, "people": {"alive": alive, "households": 25, "births": 0},
                        "currency": {"total": coins, "leak": leak if d == days else 0}, "money": {"treasury": 300},
                        "materials": {"deposits": {}}, "wildlife": {}, "ledger": {"items": (items or {}) if d == days else {}, "table": {}}}
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"samples": [sample(d) for d in range(0, days + 1, 5)], "deaths": [], "reached": days}))


class AbnormalEvidence(unittest.TestCase):
    """REC-DIAG: the archive's abnormal-run findings (recorder_archive.Diag), each with seed, day, actor and evidence; never problems."""

    @staticmethod
    def row(day, sub, actor):
        return (day, 0.0, "", "", "", sub, actor, "ok", "")

    def test_runs(self):
        runs = recorder_archive.Diag.runs([(1, 0), (2, 0), (3, 0), (4, 0), (5, 1), (6, 0), (7, 0), (9, 0), (10, 0), (11, 0)], lambda v: v == 0)
        self.assertEqual(runs, [(1, 4), (9, 11)])

    def test_findings(self):
        d = recorder_archive.Diag()
        fac = {"source": 0, "event": 1, "option": 2, "factor": 3, "value": 4}
        d.event(1, self.row(4, "death", "p:7"), "cause=starvation; role=adult job=farmer household=3 age=30.0")
        d.other("factor", fac, ["death", 1, "deceased", "coins", 12])
        d.other("factor", fac, ["death", 1, "village", "food_for_sale_stalls", 5])
        d.event(2, self.row(5, "death", "p:8"), "cause=old age; role=elder job= household=3 age=70.0")
        d.event(6, self.row(7, "death", "p:9"), "cause=starvation; role=adult job= household=4 age=40.0")   # penniless: food elsewhere is not theirs
        d.other("factor", fac, ["death", 6, "deceased", "coins", 0])
        d.other("factor", fac, ["death", 6, "village", "granary_food", 50])
        d.event(3, self.row(6, "died", "p:900"), "from=bourton to=dead; cause=hunger")
        d.event(4, self.row(6, "business_abandoned", "hh:3"), "holder gone; stock to the granary=4")
        d.event(5, self.row(6, "migration_out", "settlement:bourton"), "reason=work; people=2; coins=5; goods=0")
        for day, t in ((1, 100), (2, 90), (3, 80), (4, 70), (5, 70)):
            d.snapshot({"day": day, "treasury": t, "hh_purse_min": 0, "food_days": 2.0})
        light = {10: (4, 0.0, "", "", "decision", "eat", "p:7", "empty", "")}
        r = d.report({"seed": 3}, light)
        kinds = r["counts"]
        self.assertEqual(kinds.get("starved_with_means"), 1)
        self.assertNotIn("violent_or_accidental_death", kinds)          # old age is ordinary
        self.assertEqual(kinds.get("starved_without_means"), 1)         # review 2026-10-30: the granary's grain is not the deceased's means
        g = next(x for x in r["findings"] if x["kind"] == "starved_without_means")
        self.assertEqual((g["actor"], g["evidence"]["village_food"]), ("p:9", {"village.granary_food": 50}))
        self.assertEqual(kinds.get("settlement_hunger_death"), 1)
        self.assertEqual(kinds.get("treasury_drain"), 1)
        self.assertEqual(kinds.get("household_purse_at_zero"), 1)
        self.assertEqual(kinds.get("business_abandoned"), 1)
        self.assertEqual(r["settlement_deaths"], {"bourton|hunger": 1})
        self.assertEqual(r["migrations"], {"out|work": 2})
        f = next(x for x in r["findings"] if x["kind"] == "starved_with_means")
        self.assertEqual((f["seed"], f["day"], f["actor"]), (3, 4, "p:7"))
        self.assertEqual(f["evidence"]["means"], {"deceased.coins": 12})       # village food is context, not the deceased's means
        self.assertEqual(f["evidence"]["context"]["village.food_for_sale_stalls"], 5)
        self.assertEqual(f["chain"][0]["subtype"], "eat")


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


COMMIT = "0123456789abcdef0123456789abcdef01234567"


def gate_jobs_for(commit):
    """The jobs sim_suite.py runs on this commit (its rotating seeds follow the commit), read as ci_plan.py gate-plan reads them."""
    real = sim_suite.git_commit
    sim_suite.git_commit = lambda: commit
    try:
        jobs, _ = ci_plan.gate_jobs()
    finally:
        sim_suite.git_commit = real
    return jobs


def split_and_merge(src, results, plan, root, codes=None, drop=()):
    """What sim-gate.yml does with one gate's outputs: each part's runs on their own (a part directory with the part's runs and
    gate-record's part-<k>.json, the part's own gate.json removed), every part's files gathered into one directory as
    download-artifact's merge-multiple does, then gate-merge. Returns (gate-merge's exit code, the gathered directory)."""
    merged = Path(root) / "merged"
    for p in plan["parts"]:
        pd = Path(root) / ("part%d" % p["part"])
        only = p["only"].split(",")
        for n in only:
            shutil.copytree(src / n, pd / n)
        (pd / "gate.json").write_text(json.dumps({"job_results": [results[n] for n in only if n in results], "timing": {"simulations": 1.0}}))
        with contextlib_quiet():
            ci_plan.main(["gate-record", "--out", str(pd), "--part", str(p["part"]), "--only", p["only"], "--code", str((codes or {}).get(p["part"], 0))])
        (pd / "gate.json").unlink()
        if p["part"] in drop:
            continue
        shutil.copytree(pd, merged, dirs_exist_ok=True)
    merged.mkdir(exist_ok=True)
    with contextlib_quiet():
        code = ci_plan.main(["gate-merge", "--dir", str(merged), "--plan", json.dumps(plan)])
    return code, merged


def contextlib_quiet():
    import contextlib
    import io
    return contextlib.redirect_stdout(io.StringIO())


def evaluate_dir(d, commit, jobs=None, results=None):
    """sim_suite.py --reuse's evaluation of a directory: its gate.json's job results, the jobs among them, the whole gate."""
    if results is None:
        results = {r["run"]: r for r in json.loads((d / "gate.json").read_text())["job_results"]}
    import copy
    jobs = [j for j in copy.deepcopy(jobs) if j["run"] in results]
    ev = sim_suite.evaluate(jobs, results, d, commit, partial=False)
    text = json.dumps({k: ev[k] for k in ("findings", "runs", "history", "notes", "covered", "population_scaling", "perf_rows", "build_points")},
                      sort_keys=True, default=str)
    return json.loads(text.replace(str(d), "<out>")), ev


class GateSplit(unittest.TestCase):
    """B25R1: the gate split across runners (sim-gate.yml) reaches exactly the single-job gate's findings."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.jobs = gate_jobs_for(COMMIT)
        self.src = self.tmp / "single"
        self.results = {}
        for j in self.jobs:
            base = self.src / j["run"]
            base.mkdir(parents=True)
            kind = j.get("kind", "sim")
            log = ""
            if kind == "sim":
                fake_sim(base / "sim.json", alive=100 + j["seed"] % 7, coins=3000 + j["seed"], days=j["days"])
                if j["record"]:
                    make_archive(base / "rec")
            elif kind == "probe":
                (base / "probe.json").write_text(json.dumps({"ok": True, "meets_requirement": True, "bandits_ok": True, "walls_ok": True,
                                                              "stations_ok": True, "gossip_ok": True, "differences": {}}))
            else:
                log = 'JSON [{"n": 100, "total_ms": 12.5, "max_frame_ms": 3, "p99_frame_ms": 2, "mem_mb": 80, "save_kb": 300}]\n'
            (base / "run.log").write_text(log)
            self.results[j["run"]] = {"run": j["run"], "code": 0, "seconds": 10.0 + len(j["run"]), "cmd": "", "dir": str(base)}
        (self.src / "gate.json").write_text(json.dumps({"job_results": list(self.results.values()), "timing": {"simulations": 5.0}}))
        self.real_commit = ci_plan.git_commit
        ci_plan.git_commit = lambda: COMMIT

    def tearDown(self):
        ci_plan.git_commit = self.real_commit
        shutil.rmtree(self.tmp)

    def plan(self, parts=5):
        pairs = [(r, d) for r, d, _ in sim_suite.DET_PAIRS]
        return {"commit": COMMIT, "runs": sorted(j["run"] for j in self.jobs),
                "parts": ci_plan.pack_gate(self.jobs, parts, 4, ci_plan.load_timings(), pairs)}

    def plant_difference(self, run):
        p = self.src / run / "sim.json"
        d = json.loads(p.read_text())
        d["samples"][-1]["people"]["alive"] -= 1
        p.write_text(json.dumps(d))

    def assert_same_findings(self, plan, expect_det=()):
        code, merged = split_and_merge(self.src, self.results, plan, self.tmp)
        self.assertEqual(code, 0, json.loads((merged / "parts.json").read_text())["problems"])
        single, ev = evaluate_dir(self.src, COMMIT, self.jobs, self.results)
        split, _ = evaluate_dir(merged, COMMIT, self.jobs)
        self.assertEqual(split, single)
        self.assertTrue(single["findings"])                       # the fabricated outputs give the gate something to find
        det = {h["comparison"]: h["verdict"] for h in ev["history"] if h["comparison"].startswith("determinism")}
        self.assertEqual(len(det), len(sim_suite.DET_PAIRS))       # both pairs compared, not skipped
        for label in expect_det:
            self.assertTrue(any(label in k and v == "DIFFERS" for k, v in det.items()), det)
            self.assertTrue(any("determinism" in f["description"] and label in f["description"] and f["blocking"] for f in ev["findings"]))
        return split

    def test_plan_covers_every_run_once_and_keeps_pairs_together(self):
        plan = self.plan()
        where = {}
        for p in plan["parts"]:
            for n in p["only"].split(","):
                self.assertNotIn(n, where)
                where[n] = p["part"]
        self.assertEqual(sorted(where), plan["runs"])
        for a, b, _ in sim_suite.DET_PAIRS:
            self.assertEqual(where[a], where[b])

    def test_every_part_judges_its_own_subset(self):
        """A part runner's own (subset) judgement must finish, so it writes its job results: run 41977899291's part 4 held
        eq_s2 without eq_s1 and crashed on a baseline difference (fixed in sim_suite.evaluate)."""
        import copy
        subsets = [p["only"].split(",") for p in self.plan()["parts"]] + [["eq_s2"], ["b18_s1"]]
        for only in subsets:
            jobs = [j for j in copy.deepcopy(self.jobs) if j["run"] in only]
            ev = sim_suite.evaluate(jobs, {n: self.results[n] for n in only}, self.src, COMMIT, partial=True)
            if "eq_s2" in only:
                self.assertTrue(any(f["run"] == "eq_s2" and "accepted baseline" in f["description"] for f in ev["findings"]), only)

    def test_split_reaches_the_same_findings(self):
        self.plant_difference("x20_on_det_s1")
        self.assert_same_findings(self.plan(), expect_det=["Expansion 20 switches on"])

    def test_pair_on_two_runners_is_still_compared(self):
        """Even with a determinism pair split across runners, the gather job compares it from the gathered outputs."""
        self.plant_difference("det_s1")
        runs = sorted(j["run"] for j in self.jobs)
        rest = [n for n in runs if n not in ("eq_s1", "det_s1")]
        plan = {"commit": COMMIT, "runs": runs, "parts": [{"part": 0, "only": ",".join(["eq_s1"] + rest[:12])},
                                                         {"part": 1, "only": ",".join(["det_s1"] + rest[12:])}]}
        self.assert_same_findings(plan, expect_det=["shipped switches"])

    def test_missing_part_fails(self):
        code, merged = split_and_merge(self.src, self.results, self.plan(), self.tmp, drop=(2,))
        self.assertEqual(code, 1)
        g = json.loads((merged / "gate.json").read_text())
        self.assertTrue(g["result"].startswith("FAIL"))
        self.assertTrue(any("part 2: no record" in p for p in json.loads((merged / "parts.json").read_text())["problems"]))

    def test_tool_failure_in_a_part_fails(self):
        code, merged = split_and_merge(self.src, self.results, self.plan(), self.tmp, codes={1: 2})
        self.assertEqual(code, 1)
        self.assertTrue(any("exited 2" in p for p in json.loads((merged / "parts.json").read_text())["problems"]))

    def test_finding_in_a_part_is_not_a_tool_failure(self):
        code, _ = split_and_merge(self.src, self.results, self.plan(), self.tmp, codes={0: 1})
        self.assertEqual(code, 0)


@unittest.skipUnless(os.environ.get("MML_GATE_DIR"), "MML_GATE_DIR: a real gate's outputs (the sim-gate artifact with sim-gate-archives unpacked into it)")
class RealGateSplit(unittest.TestCase):
    """A real single-job gate's outputs, split into parts as sim-gate.yml would run them, gathered and judged again: the same
    findings, history and determinism verdicts as judging the unsplit outputs."""

    def test_real_outputs(self):
        src = Path(os.environ["MML_GATE_DIR"]).resolve()
        g = json.loads((src / "gate.json").read_text())
        commit = g["commit"]
        results = {r["run"]: r for r in g["job_results"]}
        jobs = gate_jobs_for(commit)
        self.assertEqual(sorted(j["run"] for j in jobs), sorted(results))
        tmp = Path(tempfile.mkdtemp())
        real = ci_plan.git_commit
        ci_plan.git_commit = lambda: commit
        try:
            pairs = [(r, d) for r, d, _ in sim_suite.DET_PAIRS]
            plan = {"commit": commit, "runs": sorted(results), "parts": ci_plan.pack_gate(jobs, int(os.environ.get("MML_GATE_PARTS", "5")), 4, ci_plan.load_timings(), pairs)}
            code, merged = split_and_merge(src, results, plan, tmp)
            self.assertEqual(code, 0, json.loads((merged / "parts.json").read_text())["problems"])
            single, ev = evaluate_dir(src, commit, jobs, results)
            split, _ = evaluate_dir(merged, commit, jobs)
            self.assertEqual(split, single)
            blocking = [f for f in ev["findings"] if f["blocking"]]
            det = {h["comparison"]: h["verdict"] for h in ev["history"] if h["comparison"].startswith("determinism")}
            print("\nreal gate %s: %d findings, %d blocking (%d baseline), determinism %s" % (
                commit[:7], len(ev["findings"]), len(blocking), sum("accepted baseline" in f["description"] for f in blocking), det))
        finally:
            ci_plan.git_commit = real
            shutil.rmtree(tmp)


if __name__ == "__main__":
    unittest.main()
