"""Validate a flight recorder analysis workbook (SIM-GATE-01) with the standard library only.

The workbook is written by the game's own XLSX writer (game/scripts/recorder_export/, GDScript); this reads it back as the
zip of XML parts it is and checks:
  - it opens, and every sheet game/data/sim_workbook.json requires is present and holds data (a header and at least one row);
  - every chart part parses, refers to sheets that exist, and its value ranges hold numbers in at least one cell;
  - the charts the definition requires are there (by title, on their sheet);
  - optionally (--sims), the "Runs" sheet agrees with the simulation's own outputs: for every recorded run, villagers alive,
    currency and treasury at the end, villager deaths, and births plus newcomers equal what economy_sim.gd wrote (--out).

    python3 tools/check_workbook.py WORKBOOK.xlsx [--sims run=sim.json,run2=sim2.json]
"""
import argparse
import json
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFS = ROOT / "game" / "data" / "sim_workbook.json"
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
      "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
      "pr": "http://schemas.openxmlformats.org/package/2006/relationships",
      "c": "http://schemas.openxmlformats.org/drawingml/2006/chart",
      "a": "http://schemas.openxmlformats.org/drawingml/2006/main"}
REF = re.compile(r"^'?(.*?)'?!\$([A-Z]+)\$(\d+)(?::\$([A-Z]+)\$(\d+))?$")


def col_index(letters):
    n = 0
    for ch in letters:
        n = n * 26 + ord(ch) - 64
    return n - 1


def read_sheets(z):
    """{sheet name: {(row, col): value}} and {sheet name: part path}."""
    wb = ET.fromstring(z.read("xl/workbook.xml"))
    rels = ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
    target = {r.get("Id"): r.get("Target") for r in rels.findall("pr:Relationship", NS)}
    sheets, parts = {}, {}
    for s in wb.findall("m:sheets/m:sheet", NS):
        name = s.get("name")
        part = "xl/" + target[s.get("{%s}id" % NS["r"])]
        parts[name] = part
        cells = {}
        root = ET.fromstring(z.read(part))
        for c in root.iter("{%s}c" % NS["m"]):
            m = re.match(r"([A-Z]+)(\d+)", c.get("r"))
            col, row = col_index(m.group(1)), int(m.group(2))
            t = c.get("t")
            if t == "inlineStr":
                v = "".join(x.text or "" for x in c.iter("{%s}t" % NS["m"]))
            else:
                ve = c.find("m:v", NS)
                v = None if ve is None else ve.text
                if v is not None and t != "b":
                    v = float(v) if re.search(r"[.eE]", v) else int(v)
                elif t == "b":
                    v = v == "1"
            cells[(row, col)] = v
        sheets[name] = cells
    return sheets, parts


def charts_of(z, sheet_parts):
    """[(sheet name, chart part, title, [refs])] for every chart, found through the sheets' drawings."""
    out = []
    for name, part in sheet_parts.items():
        rels_path = part.replace("worksheets/", "worksheets/_rels/") + ".rels"
        if rels_path not in z.namelist():
            continue
        for rel in ET.fromstring(z.read(rels_path)).findall("pr:Relationship", NS):
            drawing = "xl/" + rel.get("Target").replace("../", "")
            drels = drawing.replace("drawings/", "drawings/_rels/") + ".rels"
            for crel in ET.fromstring(z.read(drels)).findall("pr:Relationship", NS):
                cpart = "xl/" + crel.get("Target").replace("../", "")
                root = ET.fromstring(z.read(cpart))
                title = "".join(t.text or "" for t in root.findall("c:chart/c:title//a:t", NS))
                refs = [f.text for f in root.iter("{%s}f" % NS["c"])]
                out.append((name, cpart, title, refs, root))
    return out


def check(path, defs=None, sims=None):
    defs = defs or json.load(open(DEFS))
    problems, info = [], {}
    try:
        z = zipfile.ZipFile(path)
        bad = z.testzip()
        if bad:
            return {"ok": False, "problems": ["corrupt member %s" % bad]}
        sheets, parts = read_sheets(z)
    except (zipfile.BadZipFile, KeyError, ET.ParseError, OSError) as e:
        return {"ok": False, "problems": ["the workbook does not open: %s" % e]}
    info["sheets"] = {n: len({r for r, _ in c}) for n, c in sheets.items()}
    for name in defs["required_sheets"] + defs.get("extra_sheets", []):
        if name not in sheets:
            problems.append("missing sheet: %s" % name)
        elif len({r for r, _ in sheets[name]}) < 2:
            problems.append("sheet %s is empty (header only)" % name)
    charts = charts_of(z, parts)
    info["charts"] = len(charts)
    titles = {}
    for name, cpart, title, refs, root in charts:
        titles.setdefault(name, []).append(title)
        for ref in refs:
            m = REF.match(ref or "")
            if not m:
                problems.append("%s: a reference that does not parse: %r" % (cpart, ref))
                continue
            sheet = m.group(1).replace("''", "'")
            if sheet not in sheets:
                problems.append("%s: refers to a sheet that does not exist: %s" % (cpart, sheet))
                continue
            c0, r0 = col_index(m.group(2)), int(m.group(3))
            r1 = int(m.group(5) or r0)
            cells = [sheets[sheet].get((r, c0)) for r in range(r0, r1 + 1)]
            if all(v is None for v in cells):
                problems.append("%s (%s): range %s is empty" % (cpart, title, ref))
        for val in root.iter("{%s}val" % NS["c"]):
            f = val.find(".//c:f", NS)
            m = REF.match(f.text if f is not None else "")
            if m and m.group(1).replace("''", "'") in sheets:
                c0, r0, r1 = col_index(m.group(2)), int(m.group(3)), int(m.group(5) or m.group(3))
                nums = [sheets[m.group(1).replace("''", "'")].get((r, c0)) for r in range(r0, r1 + 1)]
                if not any(isinstance(v, (int, float)) and not isinstance(v, bool) for v in nums):
                    problems.append("%s (%s): no number in the values %s" % (cpart, title, f.text))
    for sheet, wanted in defs.get("required_charts", {}).items():
        if sheet == "Historical Comparison" and sheets.get(sheet, {}).get((2, 7)) == "not applicable":
            continue                                   # no baseline was compared (a live recording): nothing to chart
        for t in wanted:
            if t not in titles.get(sheet, []):
                problems.append("missing chart %r on sheet %s" % (t, sheet))
    if sims is not None and "Runs" in sheets:
        problems += reconcile(sheets["Runs"], defs["runs_columns"], sims)
    return {"ok": not problems, "problems": problems, "info": info}


def reconcile(cells, columns, sims):
    """Compare the Runs sheet's recorder-derived values with each run's economy_sim output (the simulation's truth)."""
    problems = []
    nrows = max(r for r, _ in cells)
    col = {name: i for i, name in enumerate(columns)}
    for r in range(2, nrows + 1):
        run = cells.get((r, col["run"]))
        if run not in sims or not cells.get((r, col["recorded"])):
            continue
        sim = json.load(open(sims[run]))
        last = sim["samples"][-1]
        truth = {"alive_end": last["people"]["alive"], "currency_end": last["currency"]["total"], "treasury_end": last["money"]["treasury"],
                 "villager_deaths": len(sim.get("deaths", [])), "births+newcomers": last["people"]["births"]}
        got = {k: cells.get((r, col[k])) for k in ("alive_end", "currency_end", "treasury_end", "villager_deaths")}
        got["births+newcomers"] = (cells.get((r, col["births"])) or 0) + (cells.get((r, col["newcomers"])) or 0)
        for k in truth:
            if got[k] != truth[k]:
                problems.append("run %s: %s is %s in the workbook (from the recorder) but %s in the simulation's output" % (run, k, got[k], truth[k]))
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("workbook")
    ap.add_argument("--sims", default="", help="run=sim.json,... to reconcile the Runs sheet")
    a = ap.parse_args()
    sims = dict(kv.split("=", 1) for kv in a.sims.split(",") if "=" in kv) if a.sims else None
    res = check(a.workbook, sims=sims)
    print(json.dumps(res, indent=1))
    return 0 if res["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
