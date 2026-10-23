"""Determinism gate for simulation optimizations (PERF-03) and parallel seeds (PERF-05).

Runs the economy simulation (game/tests/economy_sim.gd) for each seed in its own process, with its
own Godot user data, temp directory and output file, and compares what the world became at each
checkpoint day with a committed baseline:
  fingerprint (every villager's position, coins, hunger, job and goods; every animal; the RNG state;
  deposits; pantries), villagers alive, households, currency, treasury, the item ledger table, deposits
  and animals.
An optimization passes only when every one is identical. It changes nothing in the game.

    python3 tools/sim_gate.py --write          # record the baseline (docs/release/sim_baseline.json)
    python3 tools/sim_gate.py                  # compare with it; exit 1 on any difference
    python3 tools/sim_gate.py --sequential     # one seed after the other instead of side by side
    python3 tools/sim_gate.py --sim-args=--no-judgment   # Build 19 ships judgment on: this runs the Build 18 path against the baseline
Options: --seeds 1,2  --days 30  --check 10,30  --godot PATH (default $GODOT or /opt/godot/godot)
"""
import argparse
import json
import math
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASELINE = ROOT / "docs" / "release" / "sim_baseline.json"


def run_seed(godot, seed, days, every, work, extra=()):
    """Start one simulation process with isolated paths; returns (process, output path, log path)."""
    base = Path(work) / ("seed%d" % seed)
    (base / "userdata").mkdir(parents=True)
    (base / "tmp").mkdir()
    env = dict(os.environ, XDG_DATA_HOME=str(base / "userdata"), TMPDIR=str(base / "tmp"))
    out, log = base / "sim.json", base / "sim.log"
    cmd = [godot, "--headless", "--path", str(ROOT / "game"), "--script", "res://tests/economy_sim.gd", "--",
           "--days", str(days), "--seed", str(seed), "--every", str(every), "--out", str(out)] + list(extra)
    proc = subprocess.Popen(cmd, stdout=open(log, "w"), stderr=subprocess.STDOUT, env=env)
    return proc, out, log


def summarise(sample):
    """The values compared at one checkpoint."""
    return {
        "fingerprint": sample["fingerprint"],
        "alive": sample["people"]["alive"],
        "households": sample["people"]["households"],
        "currency": sample["currency"]["total"],
        "treasury": sample["money"]["treasury"],
        "deposits": sample["materials"]["deposits"],
        "animals": sample["wildlife"],
        "item_ledger": sample["ledger"].get("table", {}),
        "leaks": {"currency": sample["currency"]["leak"], "items": sample["ledger"]["items"]},
    }


def simulate(godot, seeds, days, check, parallel, extra=()):
    every = math.gcd(*check)               # a sample at every checkpoint day
    results, timing = {}, {}
    with tempfile.TemporaryDirectory(prefix="sim_gate_") as work:
        procs = []
        t0 = time.time()
        for seed in seeds:
            t = time.time()
            p = run_seed(godot, seed, days, every, work, extra)
            procs.append((seed, p, t))
            if not parallel:
                p[0].wait()
                timing[seed] = round(time.time() - t, 1)
        for seed, (proc, out, log), t in procs:
            code = proc.wait()
            timing.setdefault(seed, round(time.time() - t, 1))
            text = Path(log).read_text(errors="replace")
            errors = text.count("SCRIPT ERROR")
            if code not in (0, 1) or not Path(out).exists() or errors:
                sys.exit("seed %d: the simulation failed (exit %d, %d script errors); log:\n%s" % (seed, code, errors, text[-3000:]))
            data = json.loads(Path(out).read_text())
            by_day = {s["day"]: s for s in data["samples"]}
            results[str(seed)] = {str(d): summarise(by_day[d]) for d in check}
        wall = round(time.time() - t0, 1)
    return results, {"per_seed_seconds": timing, "wall_seconds": wall, "parallel": parallel}


def compare(base, now):
    problems = []
    for seed in sorted(set(base) | set(now)):
        for day in sorted(set(base.get(seed, {})) | set(now.get(seed, {})), key=int):
            a, b = base.get(seed, {}).get(day), now.get(seed, {}).get(day)
            if a is None or b is None:
                problems.append("seed %s day %s: missing in the %s" % (seed, day, "baseline" if a is None else "new run"))
                continue
            for k in a:
                if a[k] != b.get(k):
                    detail = "" if k in ("item_ledger", "deposits", "animals") else ": %s -> %s" % (a[k], b.get(k))
                    problems.append("seed %s day %s: %s differs%s" % (seed, day, k, detail))
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seeds", default="1,2")
    ap.add_argument("--days", type=int, default=30)
    ap.add_argument("--check", default="10,30")
    ap.add_argument("--godot", default=os.environ.get("GODOT", "/opt/godot/godot"))
    ap.add_argument("--write", action="store_true", help="record the baseline instead of comparing")
    ap.add_argument("--sequential", action="store_true", help="run the seeds one after the other")
    ap.add_argument("--sim-args", default="", help="extra economy_sim arguments, e.g. --no-judgment (Build 19 ships judgment on; the baseline is Build 18, judgment off)")
    args = ap.parse_args()
    seeds = [int(s) for s in args.seeds.split(",")]
    check = [int(d) for d in args.check.split(",")]
    if max(check) > args.days:
        sys.exit("--check days must be within --days")
    results, timing = simulate(args.godot, seeds, args.days, check, not args.sequential, args.sim_args.split())
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    print("timing: %s" % json.dumps(timing))
    for seed in results:
        for day in results[seed]:
            r = results[seed][day]
            print("seed %s day %s: fingerprint %s, alive %s, households %s, currency %s, leaks %s" % (
                seed, day, r["fingerprint"], r["alive"], r["households"], r["currency"], json.dumps(r["leaks"])))
    if args.write:
        BASELINE.write_text(json.dumps({"format": "mml-sim-baseline/1", "commit": commit, "days": args.days,
                                        "results": results}, indent=1, sort_keys=True) + "\n")
        print("baseline written: %s (from %s)" % (BASELINE.relative_to(ROOT), commit))
        return 0
    base = json.loads(BASELINE.read_text())["results"]
    problems = compare(base, results)
    for p in problems:
        print("DIFFERS: " + p)
    print("determinism gate: %s" % ("PASS, identical to the baseline" if not problems else "FAIL, %d differences" % len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
