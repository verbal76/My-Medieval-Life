"""The permanent pre-build simulation gate (SIM-GATE-01, owner directive 2026-10-24, and its amendment of the same day).

Runs the village simulation scenarios with the flight recorder on, checks them, exports the recorder's analysis and the
workbook (the game's own GDScript writer, tests/sim_workbook.gd) and decides whether packaging may go on.
.github/workflows/release.yml runs it before any export; the release is packaged only when it exits 0.

    python3 tools/sim_suite.py --out out/sim-gate                # the full suite (about 275 simulated days, parallel)
    python3 tools/sim_suite.py --out DIR --only eq_s1,crime      # a targeted subset while developing (never a release)
    python3 tools/sim_suite.py --reuse DIR --out DIR2 [--inject leak|corrupt|crash]
                                         # re-check an earlier run's outputs without simulating again; --inject plants a
                                         # defect in the copy to prove the gate stops (tests and proof only)
Options: --godot PATH (default $GODOT, else godot on the path, else /opt/godot/godot), --jobs N (default: the CPU count),
--import (run Godot's import first).

What fails the gate (exit 1), and nothing else (WDR-022: a village may fail, the simulation may not):
  crash         a run or probe exited abnormally, timed out, or printed a script error
  conservation  economy_sim's currency or item ledger broke (a FATAL line, a leak, exit 1), or the recorder saw coins
                created or lost outside the books (coin.unattributed_total)
  determinism   the recorded and the unrecorded run of the same seed differ at any checkpoint (this also proves the
                recorder changes nothing)
  baseline      a fixed-seed run differs from the accepted baseline docs/release/sim_baseline.json (an unapproved
                regression; an intended change is accepted only by the lead's documented baseline update, never here)
  recorder      an archive is incomplete, truncated, inconsistent or does not match the simulation's own output
  save/load     a save loaded and saved again drops or changes anything, or a second round trip is not identical
  coverage      a required scenario did not run to its end
  workbook      the workbook is missing, a required sheet or chart is missing or empty, a chart range is invalid, or the
                Runs sheet disagrees with the simulation's output
Hardship, deaths, shortages and collapse are reported, never failed. Measures without an approved limit (stuck villagers,
navigation failures, speed, recorder overhead) are reported as PROPOSED thresholds for the owner and never block.
Known open requirements (GP-CRIME-PURSUIT: the corner case) are reported, not failed, until they are implemented.
"""
import argparse
import concurrent.futures
import gzip
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_workbook  # noqa: E402
import recorder_archive  # noqa: E402
from sim_gate import summarise, compare  # noqa: E402

RELEASE = ROOT / "docs" / "release"
ACCEPTED = RELEASE / "sim_baseline.json"
SCHEMA = recorder_archive.SCHEMA
COVERAGE = {"A": "normal village equilibrium", "B": "resource shortages and economic stress", "C": "population and households",
            "D": "production and economy", "E": "relationships and judgment", "F": "crime and law enforcement",
            "G": "navigation and daily behaviour", "H": "simulation performance"}

# The fixed scenarios. Seeds 1 and 2 at 30 days are the accepted baseline's (sim_baseline.json, checks at days 10 and 30).
# Shortages start on day 5, after the village has settled; 20 days shows the interruption and the response.
SCENARIOS = [
    {"run": "eq_s1", "scenario": "A normal equilibrium", "cover": "ACDEG", "seed": 1, "days": 30, "record": True, "args": [], "baseline": True},
    {"run": "eq_s2", "scenario": "A normal equilibrium (profiled)", "cover": "ACDEGH", "seed": 2, "days": 30, "record": True, "args": ["--profile"], "baseline": True},
    {"run": "det_s1", "scenario": "determinism and recorder neutrality (eq_s1 without the recorder)", "cover": "", "seed": 1, "days": 30, "record": False, "args": []},
    {"run": "b18_s1", "scenario": "Build 18 rules: judgment off (historical comparison)", "cover": "", "seed": 1, "days": 30, "record": False, "args": ["--no-judgment"]},
    {"run": "food_start", "scenario": "B shortage: no stored food at the start", "cover": "BC", "seed": 3, "days": 20, "record": True,
     "args": ["--set", "start_granary_days=0", "--set", "start_household_wheat_per_member=0"]},
    {"run": "corner_wheat", "scenario": "B shortage: the wheat bought up on day 5", "cover": "BD", "seed": 3, "days": 20, "record": True,
     "args": ["--scenario", "corner_wheat", "--at", "5"]},
    {"run": "hunt_out", "scenario": "B shortage: the deer and boar hunted out on day 5", "cover": "B", "seed": 4, "days": 20, "record": True,
     "args": ["--scenario", "hunt_out", "--at", "5"]},
    {"run": "kill_smiths", "scenario": "B shortage: the smiths (tools) lost on day 5", "cover": "BCD", "seed": 4, "days": 20, "record": True,
     "args": ["--scenario", "kill_smiths", "--at", "5"]},
    {"run": "no_caravan", "scenario": "B and D: no caravan after day 1 (trade cut off)", "cover": "BD", "seed": 5, "days": 20, "record": True,
     "args": ["--set", "caravan_every_days=100000"]},
    {"run": "crime", "scenario": "F crime: theft, pickpocket, killings, flight, assault from day 3", "cover": "EFG", "seed": 1, "days": 15, "record": True,
     "args": ["--scenario", "crime_spree", "--at", "3"]},
]
ROTATING_DAYS = 20
ROTATING_COUNT = 2


def godot_path(arg):
    if arg:
        return arg
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    return shutil.which("godot") or "/opt/godot/godot"


def git_commit():
    r = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True)
    return r.stdout.strip() or "unknown"


def rotating(commit):
    """A deterministic sample of seeds derived from the commit: different for each commit, the same for a rerun of it."""
    h = commit if re.fullmatch(r"[0-9a-f]{16,}", commit) else "0" * 16
    seeds = []
    for i in range(ROTATING_COUNT):
        s = 100 + int(h[i * 8:(i + 1) * 8], 16) % 9900
        while s in seeds:
            s += 1
        seeds.append(s)
    return [{"run": "rot_%d" % s, "scenario": "rotating sample (seed from the commit)", "cover": "ACDG", "seed": s, "days": ROTATING_DAYS,
             "record": True, "args": []} for s in seeds]


def job_env(base, commit):
    (base / "userdata").mkdir(parents=True, exist_ok=True)
    (base / "tmp").mkdir(exist_ok=True)
    return dict(os.environ, XDG_DATA_HOME=str(base / "userdata"), TMPDIR=str(base / "tmp"), MML_COMMIT=commit)


def run_job(godot, job, out, commit):
    """Run one economy_sim scenario, a probe or the perf harness in its own process with isolated paths."""
    base = out / job["run"]
    if base.exists():
        shutil.rmtree(base)
    base.mkdir(parents=True)
    kind = job.get("kind", "sim")
    if kind == "sim":
        cmd = [godot, "--headless", "--path", str(ROOT / "game"), "--script", "res://tests/economy_sim.gd", "--",
               "--days", str(job["days"]), "--seed", str(job["seed"]), "--every", "5", "--out", str(base / "sim.json")] + job["args"]
        if job["record"]:
            cmd += ["--record", str(base / "rec")]
        timeout = 600 + 90 * job["days"]
    elif kind == "probe":
        cmd = [godot, "--headless", "--path", str(ROOT / "game"), "--script", "res://tests/sim_probes.gd", "--", "--probe", job["probe"],
               "--seed", str(job["seed"]), "--out", str(base / "probe.json")] + job.get("args", [])
        if job.get("record"):
            cmd += ["--record", str(base / "rec")]
        timeout = 900
    else:
        cmd = [godot, "--headless", "--path", str(ROOT / "game"), "--script", "res://tests/judgment_perf.gd", "--"] + job["args"]
        timeout = 1200
    t0 = time.time()
    with open(base / "run.log", "w") as log:
        try:
            code = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, env=job_env(base, commit), timeout=timeout).returncode
        except subprocess.TimeoutExpired:
            code = "timeout after %d s" % timeout
    return {"run": job["run"], "code": code, "seconds": round(time.time() - t0, 1), "cmd": " ".join(cmd[1:]), "dir": str(base)}


def run_all(godot, jobs, out, commit, workers):
    order = sorted(jobs, key=lambda j: -j.get("days", 1) * (1.2 if j.get("record") else 1.0))
    results = {}
    t0 = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(run_job, godot, j, out, commit): j for j in order}
        for f in concurrent.futures.as_completed(futs):
            r = f.result()
            results[r["run"]] = r
            print("  %-12s exit %-6s %7.1f s" % (r["run"], r["code"], r["seconds"]), flush=True)
    return results, round(time.time() - t0, 1)


# ---------------------------------------------------------------- evaluation ---------------------------------------------
def finding(job, description, severity, blocking, expected="", actual="", day=None, hour=None, entity="", event="", reproduce=None):
    return {"seed": job.get("seed"), "scenario": job.get("scenario", job["run"]), "run": job["run"], "day": day, "hour": hour, "entity": entity,
            "event": event, "description": description, "severity": severity, "blocking": blocking, "expected": expected, "actual": actual,
            "reproduce": reproduce if reproduce is not None else job.get("reproduce", "")}


def reproduce_line(job):
    if job.get("kind", "sim") == "sim":
        return "godot --headless --path game --script res://tests/economy_sim.gd -- --days %d --seed %d --every 5 %s%s" % (
            job["days"], job["seed"], " ".join(job["args"]), " --record DIR" if job["record"] else "")
    if job.get("kind") == "probe":
        return "godot --headless --path game --script res://tests/sim_probes.gd -- --probe %s --seed %d" % (job["probe"], job["seed"])
    return "godot --headless --path game --script res://tests/judgment_perf.gd -- " + " ".join(job["args"])


def log_problems(text):
    errors = text.count("SCRIPT ERROR")
    fatal = [l for l in text.splitlines() if l.startswith("FATAL")]
    return errors, fatal


def evaluate(jobs, results, out, commit, inject_note="", partial=False, release_dir=RELEASE):
    findings, runs, history, proposals, notes = [], [], [], [], []
    by_run = {j["run"]: j for j in jobs}
    sims = {}
    pursuit, saveload, perf_rows, profile = {}, [], [], []
    for j in jobs:
        j["reproduce"] = reproduce_line(j)
        res = results.get(j["run"])
        base = out / j["run"]
        text = (base / "run.log").read_text(errors="replace") if (base / "run.log").exists() else ""
        errors, fatal = log_problems(text)
        kind = j.get("kind", "sim")
        if res is None:
            findings.append(finding(j, "the run did not start", "critical", True))
            continue
        crashed = (kind == "sim" and res["code"] not in (0, 1)) or (kind != "sim" and res["code"] != 0) or errors > 0
        if crashed:
            first = text[text.find("SCRIPT ERROR"):][:400] if errors else text[-400:]
            findings.append(finding(j, "crash: exit %s, %d script errors" % (res["code"], errors), "critical", True, "exit 0 or 1, no script error",
                                    first.replace("\n", " | ")))
        if kind == "probe":
            p = base / "probe.json"
            r = json.loads(p.read_text()) if p.exists() else {}
            if j["probe"] == "saveload":
                saveload.append(r)
                diff = r.get("differences", {})
                if not r.get("ok"):
                    findings.append(finding(j, "save and load lose or change data", "critical", True, "nothing dropped or changed; a second round trip identical",
                                            json.dumps({"differences": diff, "second_round_trip_identical": r.get("second_round_trip_identical"),
                                                        "examples": r.get("examples", [])[:3]})[:600], day=r.get("day")))
                elif diff.get("added"):
                    ex = r.get("examples", [])
                    findings.append(finding(j, "the loader fills in %d keys the save lacked (no value lost or changed; the second round trip is identical)" % diff["added"],
                                            "minor", False, "a loaded save writes back the same keys", ex[0]["path"] + " added: " + str(ex[0]["after"]) if ex else "",
                                            day=r.get("day")))
            else:
                pursuit = r
                if r and not r.get("meets_requirement"):
                    findings.append(finding(j, "guard pursuit ends at a corner (the owner's case): known, open requirement GP-CRIME-PURSUIT (owner approved, not started)",
                                            "major", False, "the corner does not end the chase; the guard reaches the player by path",
                                            "chase held %s min, closest %s tiles, ended: %s; the guard then: %s" % (r.get("chase_held_minutes"), r.get("closest_tiles"),
                                                                                                                r.get("end_reason"), r.get("guard_doing_after")),
                                            entity="guard"))
            continue
        if kind == "perf":
            for line in text.splitlines():
                if line.startswith("JSON ["):
                    perf_rows = json.loads(line[5:])
            continue
        # --- an economy_sim run
        sp = base / "sim.json"
        data = json.loads(sp.read_text()) if sp.exists() else None
        row = {"run": j["run"], "scenario": j["scenario"], "seed": j["seed"], "days": j["days"], "recorded": j["record"], "wall_seconds": res["seconds"],
               "cover": j.get("cover", ""), "result": "ok"}
        if data is None:
            findings.append(finding(j, "no simulation output", "critical", True))
            row["result"] = "no output"
            runs.append(row)
            continue
        sims[j["run"]] = str(sp)
        last = data["samples"][-1]
        row.update({"alive_start": data["samples"][0]["people"]["alive"], "alive_end": last["people"]["alive"], "currency_end": last["currency"]["total"],
                    "treasury_end": last["money"]["treasury"], "households_end": last["people"]["households"], "villager_deaths": len(data.get("deaths", [])),
                    "births": last["people"]["births"], "reached": data.get("reached")})
        if data.get("reached") != j["days"]:
            row["result"] = "stopped at day %s" % data.get("reached")
            findings.append(finding(j, "the run stopped before its end (a broken ledger)", "critical", True, "day %d" % j["days"], "day %s" % data.get("reached"),
                                    day=data.get("reached")))
        leak = last["currency"]["leak"]
        items = last["ledger"]["items"]
        if fatal or leak or items or res["code"] == 1:
            row["result"] = "conservation broken"
            findings.append(finding(j, "conservation: coins or goods created or lost (economy_sim's ledgers)", "critical", True, "currency leak 0, item ledger balanced",
                                    "leak %s; items %s; %s" % (leak, json.dumps(items)[:200], "; ".join(fatal)[:200]), day=last["day"]))
        regions = last.get("regions", {})
        if regions and (str(regions.get("audit", "")) or regions.get("coins_mismatch") or regions.get("goods_mismatch") or regions.get("people_mismatch")):
            findings.append(finding(j, "the neighbouring settlements' books do not balance", "critical", True, "no mismatch", json.dumps(regions)[:300], day=last["day"]))
        if j.get("args") and "--profile" in j["args"]:
            for line in text.splitlines():
                m = re.match(r"\s+(.+?)\s{2,}([\d.]+) s\s+([\d.]+)%\s*(.*)$", line)
                if m and "PROFILE" not in line:
                    profile.append({"system": m.group(1).strip(), "seconds": float(m.group(2)), "share": float(m.group(3)) / 100.0, "calls": m.group(4).strip()})
        if j["record"]:
            sessions = recorder_archive.session_dirs(str(base / "rec"))
            if len(sessions) != 1:
                findings.append(finding(j, "recorder: expected one session, found %d" % len(sessions), "critical", True))
            else:
                rep = recorder_archive.verify(sessions[0])
                row["session_dir"] = sessions[0]
                row["analysis_out"] = str(base / "analysis.json")
                row["archive_bytes"] = rep["bytes"]
                row["rows"] = sum(rep["counts"].values())
                row["snapshot_hours"] = rep["snapshot_hours"]
                for p in rep["problems"]:
                    findings.append(finding(j, "recorder output invalid: " + p, "critical", True, "a complete, consistent archive", p))
                ls = rep["final_snapshot"] or {}
                checks = {"villagers alive": (ls.get("alive"), last["people"]["alive"]), "currency": (ls.get("total_coins"), last["currency"]["total"]),
                          "treasury": (ls.get("treasury"), last["money"]["treasury"]), "villager deaths": (rep["villager_deaths"], len(data.get("deaths", []))),
                          "births and arrivals": (rep["births"] + rep["newcomers"], last["people"]["births"])}
                for k, (got, want) in checks.items():
                    if got != want:
                        findings.append(finding(j, "recorder does not match the simulation: %s" % k, "critical", True, "%s (simulation)" % want, "%s (recorder)" % got,
                                                day=ls.get("day"), hour=ls.get("hour")))
                if rep["session"].get("commit") not in (commit, "unknown") and not inject_note:
                    findings.append(finding(j, "recorder session names another commit", "major", True, commit, rep["session"].get("commit")))
                tot = rep["alerts"].get("coin.unattributed_total", 0)
                if tot:
                    findings.append(finding(j, "coins created or lost outside the books (recorder coin.unattributed_total)", "critical", True, "0 alerts", "%d alerts" % tot,
                                            entity="world"))
                row["unattributed_holder_alerts"] = rep["alerts"].get("coin.unattributed_holder", 0)
        runs.append(row)
    # --- determinism and recorder neutrality: eq_s1 (recorded) against det_s1 (not)
    if "eq_s1" in sims and "det_s1" in sims:
        a = {s["day"]: s for s in json.load(open(sims["eq_s1"]))["samples"]}
        b = {s["day"]: s for s in json.load(open(sims["det_s1"]))["samples"]}
        diffs = []
        for d in sorted(set(a) | set(b)):
            if d not in a or d not in b:
                diffs.append("day %s missing" % d)
            elif summarise(a[d]) != summarise(b[d]):
                diffs.append("day %s: %s" % (d, ", ".join(k for k in summarise(a[d]) if summarise(a[d])[k] != summarise(b[d]).get(k))))
        checked = len(set(a) & set(b))
        history.append({"comparison": "determinism: recorded against unrecorded, seed 1", "baseline": "det_s1 (same commit)", "seed": 1, "day": "every 5 days",
                        "value": "fingerprint and summary at %d checkpoints" % checked, "base": "", "now": "", "verdict": "MATCH" if not diffs else "DIFFERS",
                        "note": "; ".join(diffs)[:500] or "identical at every checkpoint: the recorder changes nothing and the run is reproducible"})
        if diffs:
            findings.append(finding(by_run["det_s1"], "determinism: the same seed with and without the recorder differs", "critical", True, "identical at every checkpoint",
                                    "; ".join(diffs)[:500]))
    else:
        findings.append(finding({"run": "det_s1", "seed": 1}, "determinism pair did not run (eq_s1 and det_s1)", "critical", not partial))
    # --- baselines: the accepted one blocks; earlier builds are compared and reported
    build_points = []
    for fname, runs_for, label, blocking in [("sim_baseline.json", ["eq_s1", "eq_s2"], "accepted baseline", True),
                                             ("sim_baseline_build19.json", ["eq_s1", "eq_s2"], "Build 19", False),
                                             ("sim_baseline_build18.json", ["b18_s1"], "Build 18 (judgment off)", False),
                                             ("sim_baseline_build17.json", ["b18_s1"], "Build 17 (no judgment yet)", False),
                                             ("sim_baseline_build16.json", ["b18_s1"], "Build 16 (no judgment yet)", False)]:
        path = Path(release_dir) / fname
        if not path.exists():
            continue
        base = json.loads(path.read_text())
        now = {}
        for rn in runs_for:
            if rn in sims:
                samples = {s["day"]: s for s in json.load(open(sims[rn]))["samples"]}
                seed = str(by_run[rn]["seed"])
                if seed in base["results"]:
                    now[seed] = {d: summarise(samples[int(d)]) for d in base["results"][seed] if int(d) in samples}
        if not now:
            continue
        sub = {s: base["results"][s] for s in now}
        problems = compare(sub, now)
        for seed in sorted(now):
            for day in sorted(now[seed], key=int):
                bv, nv = sub[seed][day], now[seed][day]
                for k in ("fingerprint", "alive", "households", "currency", "treasury", "leaks", "item_ledger", "deposits", "animals"):
                    same = bv.get(k) == nv.get(k)
                    verdict = "MATCH" if same else ("REGRESSION" if blocking else "CHANGED SINCE")
                    short = lambda v: v if isinstance(v, (int, float, str)) else ("(%d entries)" % len(v) if isinstance(v, dict) else json.dumps(v)[:80])
                    history.append({"comparison": "%s, %s" % (label, base.get("commit")), "baseline": fname, "seed": int(seed), "day": int(day), "value": k,
                                    "base": short(bv.get(k)), "now": short(nv.get(k)), "verdict": verdict,
                                    "note": "" if same else ("blocks: an unapproved change against the accepted baseline" if blocking else
                                                             "an earlier build: differences are the approved changes since (docs/DECISIONS.md), listed for review")})
        if "1" in sub and "30" in sub["1"]:
            build_points.append({"label": "%s (%s)" % (label, base.get("commit")), "alive": sub["1"]["30"]["alive"], "currency_tenths": sub["1"]["30"]["currency"] / 10.0})
        if problems and blocking:
            for p in problems:
                findings.append(finding(by_run[runs_for[0]], "unapproved difference from the accepted baseline (%s): %s" % (base.get("commit"), p), "critical", True,
                                        "identical to docs/release/sim_baseline.json", p))
        elif problems:
            notes.append("%s: %d values differ from %s (an earlier build; reported, not failed)" % (label, len(problems), fname))
    for rn, label in (("eq_s1", "this commit"), ("b18_s1", "this commit, judgment off")):
        if rn in sims:
            s30 = [s for s in json.load(open(sims[rn]))["samples"] if s["day"] == 30]
            if s30:
                build_points.append({"label": label, "alive": s30[0]["people"]["alive"], "currency_tenths": s30[0]["currency"]["total"] / 10.0})
    # --- coverage
    covered = set()
    for row in runs:
        if row["result"] == "ok" or row["result"] == "conservation broken":
            covered |= set(row.get("cover", ""))
    if perf_rows:
        covered.add("H")
    if pursuit:
        covered.add("F")
    missing = [c for c in COVERAGE if c not in covered]
    if missing:
        findings.append(finding({"run": "suite", "seed": None, "scenario": "coverage"}, "required scenario coverage missing: %s" % ", ".join("%s %s" % (c, COVERAGE[c]) for c in missing),
                                "critical", not partial, "A to H covered", ", ".join(missing)))
    return {"findings": findings, "runs": runs, "history": history, "notes": notes, "pursuit": pursuit, "saveload": saveload,
            "population_scaling": [{"size": p.get("n"), "line": "%.1f ms a simulated day; worst frame %.2f ms; p99 %.2f ms; memory %.1f MB; save %d KB" % (
                p.get("total_ms", 0), p.get("max_frame_ms", 0), p.get("p99_frame_ms", 0), p.get("mem_mb", 0), p.get("save_kb", 0))} for p in perf_rows],
            "perf_rows": perf_rows, "profile": profile, "build_points": build_points, "sims": sims, "covered": sorted(covered)}


def add_proposals(gate, out):
    """Measured values with no approved limit: reported as PROPOSED for the owner, never blocking. Read from the analyses."""
    props = []
    stuck_limit = json.load(open(ROOT / "game" / "data" / "sim_workbook.json"))["proposed"]["stuck_hours"]
    worst_stuck, lost, vdays, holders, days = 0, 0, 0, 0, 0
    for r in gate["runs"]:
        if not r.get("analysis_out") or not Path(r["analysis_out"]).is_file():
            continue
        p = Path(r["analysis_out"])
        a = json.loads(p.read_text())
        over = [e for e, v in a.get("stuck", {}).items() if v[0] >= stuck_limit]
        worst_stuck = max([worst_stuck] + [v[0] for v in a.get("stuck", {}).values()])
        if over:
            v = max((a["stuck"][e] for e in over), key=lambda v: v[0])
            gate["findings"].append({"seed": r["seed"], "scenario": r["scenario"], "run": r["run"], "day": v[1], "hour": v[2], "entity": max(over, key=lambda e: a["stuck"][e][0]),
                                     "event": "", "description": "%d villagers stayed %d or more hours on one cell while travelling or lost (PROPOSED limit, not approved)" % (len(over), stuck_limit),
                                     "severity": "minor", "blocking": False, "expected": "PROPOSED: under %d hours" % stuck_limit,
                                     "actual": "longest %d hours, doing %r at (%s, %s)" % (v[0], v[3], v[4], v[5]), "reproduce": ""})
        for k, n in a.get("interruptions", {}).items():
            if k.startswith("walk_lost"):
                lost += n
        for d in a.get("daily", []):
            vdays += d.get("alive", 0) * d.get("hours", 0) / 24.0
        holders += a.get("alerts", {}).get("coin.unattributed_holder", 0)
        days += r["days"]
    props.append({"measure": "longest hours a villager stayed on one cell while travelling or lost", "value": worst_stuck, "proposed": stuck_limit,
                  "why": "No approved requirement sets a number for stuck villagers. Proposed as a review trigger, never a failure, until the owner approves one."})
    props.append({"measure": "navigation failures (walk lost) a villager-day", "value": round(lost / max(1.0, vdays), 4), "proposed": "review if it doubles against the accepted baseline",
                  "why": "Measured; the game has no approved limit for path failures."})
    props.append({"measure": "unattributed coin changes per holder alert a simulated day (REC-D4 detection)", "value": round(holders / max(1, days), 2),
                  "proposed": "no growth against the previous build",
                  "why": "About 150 coin sites are not instrumented: their changes are detected hourly, named by holder and amount; the world total balances (violation alerts are 0)."})
    secs = [(r["wall_seconds"], r["days"]) for r in gate["runs"] if r.get("days")]
    if secs:
        props.append({"measure": "machine seconds a simulated day (worst run of this suite, runs in parallel)", "value": round(max(s / d for s, d in secs), 2),
                      "proposed": "1.5 x the accepted build's value on the same runner", "why": "No approved performance limit for the headless simulation (CLAUDE.md section 8: budgets not set)."})
    if gate.get("recorder_overhead"):
        props.append({"measure": "recorder overhead (eq_s1 recorded against det_s1, same seed, run side by side)", "value": gate["recorder_overhead"]["share"],
                      "proposed": "under 0.5 (50%)", "why": "Measured each run; noisy when runs share the machine."})
    gate["proposals"] = props


def write_summary(gate, out):
    lines = ["## Simulation gate (SIM-GATE-01): %s" % gate["result"], "",
             "- Commit `%s`, recorder schema `%s`, run id `%s`." % (gate["commit"], gate["schema"], gate["run_id"]),
             "- %d runs, %d simulated days, seeds %s; scenarios: %s." % (len(gate["runs"]), sum(r["days"] for r in gate["runs"]),
                                                                       ", ".join(str(s) for s in sorted({r["seed"] for r in gate["runs"]})),
                                                                       "; ".join(r["scenario"] for r in gate["runs"])),
             "- Coverage: %s." % ", ".join("%s %s" % (c, COVERAGE[c]) for c in gate["covered"]),
             "- Wall time %.0f s on %d parallel jobs (simulations %.0f s, workbook %.0f s)." % (gate["timing"]["total"], gate["timing"]["jobs"], gate["timing"]["simulations"],
                                                                                                  gate["timing"].get("workbook", 0))]
    blocking = [f for f in gate["findings"] if f["blocking"]]
    lines.append("- Blocking failures: %d." % len(blocking))
    for f in blocking[:20]:
        lines.append("  - %s (%s, seed %s): %s%s" % (f["run"], f["scenario"], f["seed"], f["description"], (" — " + str(f["actual"])[:160]) if f["actual"] else ""))
    match = [h for h in gate["history"] if h["baseline"] == "sim_baseline.json"]
    lines.append("- Accepted baseline: %s (%d values compared at days 10 and 30, seeds 1 and 2)." % (
        "identical" if match and all(h["verdict"] == "MATCH" for h in match) else ("differs" if match else "not compared"), len(match)))
    det = [h for h in gate["history"] if h["comparison"].startswith("determinism")]
    if det:
        lines.append("- Determinism and recorder neutrality: %s." % det[0]["note"])
    for n in gate["notes"]:
        lines.append("- %s" % n)
    known = [f for f in gate["findings"] if not f["blocking"] and f["severity"] in ("major",)]
    for f in known:
        lines.append("- Known, not blocking: %s" % f["description"])
    lines.append("- Workbook and full results: the workflow artifact `sim-gate` (internal; not attached to the release).")
    text = "\n".join(lines) + "\n"
    (out / "SIM_GATE_SUMMARY.md").write_text(text)
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=str(ROOT / "out" / "sim-gate"))
    ap.add_argument("--godot", default="")
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 2)
    ap.add_argument("--only", default="", help="comma-separated run names (a targeted subset: never a release gate)")
    ap.add_argument("--import", dest="do_import", action="store_true")
    ap.add_argument("--reuse", default="", help="an earlier --out directory: check its outputs again without simulating")
    ap.add_argument("--inject", default="", choices=["", "leak", "corrupt", "crash"], help="plant a defect in the reused copy (tests and proof only)")
    a = ap.parse_args()
    out = Path(a.out).resolve()
    godot = godot_path(a.godot)
    commit = git_commit()
    t_start = time.time()
    jobs = [dict(j) for j in SCENARIOS] + rotating(commit)
    jobs += [{"run": "probe_saveload_s1", "kind": "probe", "probe": "saveload", "seed": 1, "scenario": "save and load integrity", "args": ["--days", "2"]},
             {"run": "probe_saveload_s2", "kind": "probe", "probe": "saveload", "seed": 2, "scenario": "save and load integrity", "args": ["--days", "2"]},
             {"run": "probe_pursuit", "kind": "probe", "probe": "pursuit", "seed": 1, "scenario": "F guard pursuit: the owner's corner case", "record": True},
             {"run": "perf_scaling", "kind": "perf", "seed": 0, "scenario": "H population scaling 100 and 500 (judgment harness)",
              "args": ["--sizes", "100,500", "--days", "10", "--rates", "live", "--variants", "spread"]}]
    if a.only:                           # a targeted subset while developing: suite-level checks (determinism pair, coverage)
        keep = set(a.only.split(","))    # are reported but cannot block, and the result says it is no release gate
        jobs = [j for j in jobs if j["run"] in keep]
    if a.reuse:
        src = Path(a.reuse).resolve()
        if src != out:
            if out.exists():
                shutil.rmtree(out)
            shutil.copytree(src, out)
        prev = json.loads((out / "gate.json").read_text())
        results = {r["run"]: r for r in prev["job_results"]}
        sim_seconds = prev["timing"]["simulations"]
        jobs = [j for j in jobs if j["run"] in results]
        if a.inject:
            inject(out, a.inject, results)
    else:
        if a.inject:
            sys.exit("--inject needs --reuse (it plants a defect in a copy of earlier outputs)")
        out.mkdir(parents=True, exist_ok=True)
        if a.do_import:
            subprocess.run([godot, "--headless", "--path", str(ROOT / "game"), "--import"], stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT,
                           env=job_env(out / "_import", commit), timeout=1800)
        print("simulation gate: %d jobs on %d workers, commit %s" % (len(jobs), a.jobs, commit[:12]), flush=True)
        results, sim_seconds = run_all(godot, jobs, out, commit, a.jobs)
    ev = evaluate(jobs, results, out, commit, a.inject, partial=bool(a.only))
    gate = {"format": "mml-sim-gate/1", "commit": commit, "build": os.environ.get("BUILD_N", ""), "run_id": os.environ.get("GITHUB_RUN_ID", "local-%d" % int(t_start)),
            "schema": SCHEMA, "subset": bool(a.only), "injected": a.inject, "job_results": list(results.values()),
            "timing": {"simulations": sim_seconds, "jobs": a.jobs}}
    gate.update(ev)
    eq, det = results.get("eq_s1"), results.get("det_s1")
    if eq and det and isinstance(eq["code"], int) and isinstance(det["code"], int):
        gate["recorder_overhead"] = {"recorded_s": eq["seconds"], "unrecorded_s": det["seconds"], "share": round(eq["seconds"] / max(1.0, det["seconds"]) - 1.0, 3),
                                     "note": "same seed and days, run side by side with the rest of the suite"}
    gate["parallel"] = {"jobs": a.jobs, "wall_seconds": sim_seconds, "sum_of_job_seconds": round(sum(r["seconds"] for r in results.values()), 1)}
    gate["result"] = "FAIL" if any(f["blocking"] for f in gate["findings"]) else "PASS"
    if a.only:
        gate["result"] += " (subset: not a release gate)"
    # the analyses and the workbook, by the game's own code (tests/sim_workbook.gd); the measured, proposed thresholds come
    # from the analyses, so they are read between the two passes; then the workbook is validated here
    gate_path = out / "gate.json"
    t_wb = time.time()
    wb = out / "sim_gate_workbook.xlsx"
    gate_path.write_text(json.dumps(gate, indent=1, default=str))
    gate["analysis_run"] = godot_workbook(godot, gate_path, None, out, commit)
    add_proposals(gate, out)
    gate["result"] = ("FAIL" if any(f["blocking"] for f in gate["findings"]) else "PASS") + (" (subset: not a release gate)" if a.only else "") + \
        (" (defect injected: %s)" % a.inject if a.inject else "")
    gate_path.write_text(json.dumps(gate, indent=1, default=str))
    if wb.exists():
        wb.unlink()
    gate["workbook_run"] = godot_workbook(godot, gate_path, wb, out, commit)
    v = check_workbook.check(str(wb), sims=gate["sims"]) if wb.exists() else {"ok": False, "problems": ["the workbook was not written"]}
    gate["workbook"] = {"path": str(wb), "validation": v}
    gate["timing"]["workbook"] = round(time.time() - t_wb, 1)
    errs = list(v.get("problems") or [])
    for k in ("analysis_run", "workbook_run"):
        if not gate[k].get("ok"):
            errs.append("%s: %s" % (k, gate[k].get("error", "failed")))
    for p in errs:
        gate["findings"].append({"seed": None, "scenario": "workbook", "run": "workbook", "day": None, "hour": None, "entity": "", "event": "",
                                 "description": "workbook invalid: %s" % p, "severity": "critical", "blocking": True, "expected": "every sheet and chart valid",
                                 "actual": p, "reproduce": "python3 tools/check_workbook.py %s" % wb})
    gate["result"] = "FAIL" if any(f["blocking"] for f in gate["findings"]) else "PASS"
    if a.only:
        gate["result"] += " (subset: not a release gate)"
    if a.inject:
        gate["result"] += " (defect injected: %s)" % a.inject
    gate["timing"]["total"] = round(time.time() - t_start, 1)
    gate_path.write_text(json.dumps(gate, indent=1, default=str))
    text = write_summary(gate, out)
    print(text)
    blocking = [f for f in gate["findings"] if f["blocking"]]
    print("simulation gate: %s (%d blocking findings); results in %s" % (gate["result"], len(blocking), out))
    return 1 if blocking else 0


def godot_workbook(godot, gate_path, wb, out, commit):
    """Run tests/sim_workbook.gd: the analyses only (wb None) or the workbook. Returns its WORKBOOK line, or {ok: false}."""
    cmd = [godot, "--headless", "--path", str(ROOT / "game"), "--script", "res://tests/sim_workbook.gd", "--", "--gate", str(gate_path)]
    cmd += ["--analyse-only"] if wb is None else ["--out", str(wb)]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, env=job_env(out / "_workbook", commit), timeout=1800)
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timed out"}
    line = next((l for l in p.stdout.splitlines() if l.startswith("WORKBOOK ")), "")
    res = json.loads(line[9:]) if line else {"ok": False, "error": (p.stdout + p.stderr)[-600:]}
    if (p.stdout + p.stderr).count("SCRIPT ERROR"):
        res = {"ok": False, "error": "script error: " + (p.stdout + p.stderr)[(p.stdout + p.stderr).find("SCRIPT ERROR"):][:400]}
    return res


def inject(out, what, results):
    """Plant one defect in a copy of earlier outputs, so a test can prove the gate stops (never used by the workflow)."""
    print("INJECTING A DEFECT FOR A TEST: %s" % what, flush=True)
    if what == "leak":
        p = out / "eq_s1" / "sim.json"
        d = json.loads(p.read_text())
        d["samples"][-1]["currency"]["leak"] = 5
        d["samples"][-1]["currency"]["total"] += 5
        p.write_text(json.dumps(d))
    elif what == "corrupt":
        chunks = sorted((out / "crime" / "rec").glob("s*/d0002/event.*.gz"))
        with gzip.open(chunks[0], "rt") as f:
            lines = f.read().split("\n")
        with gzip.open(chunks[0], "wt") as f:
            f.write("\n".join(lines[:len(lines) // 2]) + "\n")       # a torn chunk: no footer
    elif what == "crash":
        with open(out / "kill_smiths" / "run.log", "a") as f:
            f.write("\nSCRIPT ERROR: Invalid call (injected by the test).\n")


if __name__ == "__main__":
    sys.exit(main())
