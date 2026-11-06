"""Run CI test suites without stopping at the first failure, and report them (owner directive HAG-MEM-02, Part 3).

Two commands:

  run     Runs every suite in a list file, one after another, even when one fails. Each suite's output goes to its own log
          file and is echoed to the job log in a collapsible group. One JSON line per suite is appended to a results file:
          exit code, duration, the suite's own "N checks, M failures" (or "N steps, M failures") line, its first FAIL lines
          and its SCRIPT ERROR count. Exits 1 if any suite failed, so the step still fails.

  report  Reads the results files and writes a machine-readable report (format "mml-ci-report/1") and a Markdown summary
          (appended, so it can be $GITHUB_STEP_SUMMARY). The outcome is TESTED only when every expected group ran and every
          suite and step passed; FAILED when anything failed; INCOMPLETE when evidence is missing without a recorded failure.
          It never says VALIDATED, PACKAGED or RELEASED: a green test run is none of those. It exits 0 unless --strict is
          given, because the steps that ran the tests already carry their own failure; a reporting problem must never hide one.

List file: one suite per line, read with shell-like quoting; '#' starts a comment; $VARS and ~ are expanded. Each line is
appended to --prefix (for example "~/godot-bin/godot --headless --path game --script").

  python3 tools/ci_report.py run --group game --list suites.txt --prefix "godot --headless --path game --script" \\
      --logs out/logs --results out/results.jsonl [--timeout 1800] [--fail-on-script-errors] [--require-counts]
      [--floors tools/ci_check_floors.json]

TEST-GOV-01 (2026-11-06): a suite that exited 0 still fails when it printed failures, and, when asked, when it had a
SCRIPT ERROR (a check cut short), printed no check count, or ran fewer checks than its floor.
  python3 tools/ci_report.py report --results out/results.jsonl --expect python --expect game \\
      --json out/ci-report.json --markdown "$GITHUB_STEP_SUMMARY" [--step game=failure] [--purpose TEXT]

Standard library only.
"""

import argparse
import datetime
import json
import os
import re
import shlex
import subprocess
import sys
import time

FORMAT = "mml-ci-report/1"
COUNT_RE = re.compile(r"(\d+)\s+(checks?|steps?|tests?)\b[^\n]*?(\d+)\s+failures?", re.I)
UNITTEST_RE = re.compile(r"^Ran (\d+) tests?")
UNITTEST_FAIL_RE = re.compile(r"^FAILED \((.*)\)")
FAIL_LINE_RE = re.compile(r"^(FAIL\b|FAIL:|FAILED\b|ERROR:|Traceback|AssertionError|::error::)|SCRIPT ERROR")
MAX_FAIL_LINES = 5


def read_text(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read()


def parse_list(text):
    """The suite lines of a list file, each as an argument list (comments and blank lines dropped)."""
    suites = []
    for raw in text.splitlines():
        line = os.path.expanduser(os.path.expandvars(raw.strip()))
        if not line or line.startswith("#"):
            continue
        args = shlex.split(line, comments=True)
        if args:
            suites.append(args)
    return suites


def suite_name(args):
    """A short, stable name: the script's base name, or for 'python3 -m mod ...' the module and its first argument."""
    for a in args:
        if a.endswith((".gd", ".py")):
            return os.path.splitext(os.path.basename(a))[0]
    if "-m" in args:
        i = args.index("-m")
        return " ".join(args[i + 1:i + 3])
    return " ".join(args)[:60]


def read_counts(log):
    """(checks, failures, summary_line) from a suite's log; None where the suite printed no count."""
    checks = failures = None
    summary = ""
    for line in log.splitlines():
        m = COUNT_RE.search(line)
        if m:
            checks, failures, summary = int(m.group(1)), int(m.group(3)), line.strip()
            continue
        m = UNITTEST_RE.match(line.strip())
        if m:
            checks, summary = int(m.group(1)), line.strip()
            failures = 0 if failures is None else failures
            continue
        m = UNITTEST_FAIL_RE.match(line.strip())
        if m:
            failures = sum(int(n) for n in re.findall(r"=(\d+)", m.group(1)))
            summary = (summary + "; " if summary else "") + line.strip()
    return checks, failures, summary


def first_failures(log):
    return [line.rstrip()[:300] for line in log.splitlines() if FAIL_LINE_RE.search(line)][:MAX_FAIL_LINES]


def run_suite(group, args, prefix, logs, timeout, fail_on_script_errors, require_counts=False, floors=None):
    argv = prefix + args
    name = suite_name(args)
    log_path = os.path.join(logs, group, re.sub(r"[^A-Za-z0-9_.-]+", "_", name) + ".log")
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    start = time.monotonic()
    status, code = "passed", 0
    with open(log_path, "w", encoding="utf-8", errors="replace") as out:
        try:
            code = subprocess.run(argv, stdout=out, stderr=subprocess.STDOUT, timeout=timeout).returncode
        except subprocess.TimeoutExpired:
            status, code = "timeout", 124
            out.write("\n::error::suite stopped after %d s (ci_report --timeout)\n" % timeout)
        except OSError as e:
            status, code = "error", 127
            out.write("\n::error::could not start the suite: %s\n" % e)
    secs = round(time.monotonic() - start, 1)
    log = read_text(log_path)
    checks, failures, summary = read_counts(log)
    script_errors = log.count("SCRIPT ERROR")
    if status == "passed" and code != 0:
        status = "failed"
    reasons = []                 # TEST-GOV-01: why a suite that exited 0 still failed (each a way a false pass could hide)
    if status == "passed" and fail_on_script_errors and script_errors:
        status = "failed"
        reasons.append("%d SCRIPT ERROR(s): a check may have been cut short" % script_errors)
    if status == "passed" and failures:
        status = "failed"      # (it printed failures but exited 0: before, only a warning)
        reasons.append("printed %d failures but exited 0" % failures)
    if status == "passed" and require_counts and checks is None:
        status = "failed"
        reasons.append("printed no 'N checks, M failures' line: how many checks ran is unknown")
    floor = (floors or {}).get(name)
    if status == "passed" and floor is not None and checks is not None and checks < int(floor):
        status = "failed"
        reasons.append("ran %d checks, fewer than its floor of %d (tools/ci_check_floors.json): checks were skipped or removed" % (checks, int(floor)))
    rec = {"group": group, "name": name, "command": " ".join(shlex.quote(a) for a in argv), "status": status,
           "exit_code": code, "seconds": secs, "checks": checks, "failures": failures, "summary_line": summary,
           "script_errors": script_errors,
           "first_failures": (["::error::" + r for r in reasons] + first_failures(log))[:MAX_FAIL_LINES] if status != "passed" else [],
           "log": os.path.relpath(log_path, logs)}
    if reasons:
        rec["reasons"] = reasons
    return rec, log


def cmd_run(a):
    suites = parse_list(read_text(a.list))
    prefix = shlex.split(os.path.expanduser(os.path.expandvars(a.prefix))) if a.prefix else []
    os.makedirs(a.logs, exist_ok=True)
    os.makedirs(os.path.dirname(os.path.abspath(a.results)), exist_ok=True)
    failed = []
    floors = {}
    if a.floors:
        floors = {k: v for k, v in json.loads(read_text(a.floors)).items() if not k.startswith("_")}
    for args in suites:
        rec, log = run_suite(a.group, args, prefix, a.logs, a.timeout, a.fail_on_script_errors, a.require_counts, floors)
        print("::group::%s %s (%s s)" % (rec["status"].upper(), rec["name"], rec["seconds"]))
        sys.stdout.write(log if log.endswith("\n") or not log else log + "\n")
        print("::endgroup::")
        line = "%-7s %s: %s" % (rec["status"].upper(), rec["name"], rec["summary_line"] or "exit %d" % rec["exit_code"])
        print(line)
        if rec["status"] != "passed":
            failed.append(rec["name"])
            print("::error title=%s failed::%s" % (rec["name"], (rec["first_failures"] or [line])[0]))
        if rec.get("warning"):
            print("::warning title=%s::%s" % (rec["name"], rec["warning"]))
        with open(a.results, "a", encoding="utf-8") as f:
            f.write(json.dumps(rec) + "\n")
        sys.stdout.flush()
    print("%s: %d suites, %d failed%s" % (a.group, len(suites), len(failed), (": " + ", ".join(failed)) if failed else ""))
    return 1 if failed else 0


def load_results(paths):
    recs = []
    for p in paths:
        if os.path.exists(p):
            recs += [json.loads(l) for l in read_text(p).splitlines() if l.strip()]
    return recs


def build_report(recs, expect, steps, purpose="", started="", env=None):
    env = os.environ if env is None else env
    groups = {}
    for r in recs:
        g = groups.setdefault(r["group"], {"attempted": 0, "passed": 0, "failed": 0})
        g["attempted"] += 1
        g["passed" if r["status"] == "passed" else "failed"] += 1
    failed = [r for r in recs if r["status"] != "passed"]
    missing = ["group '%s': no results recorded (the step did not run or stopped before its first suite)" % g
               for g in expect if g not in groups]
    bad_steps = {k: v for k, v in steps.items() if v not in ("success", "")}
    for k, v in bad_steps.items():
        if v in ("skipped", "cancelled"):
            missing.append("step '%s' was %s" % (k, v))
        elif v == "failure" and k in expect and not any(r["group"] == k for r in failed):
            missing.append("step '%s' failed without a failing suite recorded (setup or runner failure; see the job log)" % k)
    if failed or any(v == "failure" for v in bad_steps.values()):
        outcome = "FAILED"
    elif missing or (not recs and expect):        # no results where some were expected; a shard given no suites expects none
        outcome = "INCOMPLETE"
    else:
        outcome = "TESTED"
    server = env.get("GITHUB_SERVER_URL", "https://github.com")
    repo = env.get("GITHUB_REPOSITORY", "")
    run_id = env.get("GITHUB_RUN_ID", "")
    return {
        "format": FORMAT,
        "identification": {
            "repository": repo, "project": "My Medieval Life", "build_number": None,
            "branch": env.get("GITHUB_REF_NAME", ""), "commit": env.get("GITHUB_SHA", ""),
            "workflow": env.get("GITHUB_WORKFLOW", ""), "run_id": run_id, "run_attempt": env.get("GITHUB_RUN_ATTEMPT", ""),
            "run_url": "%s/%s/actions/runs/%s" % (server, repo, run_id) if repo and run_id else "",
            "trigger": env.get("GITHUB_EVENT_NAME", ""), "actor": env.get("GITHUB_ACTOR", ""),
            "started_at": started,
            "completed_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
        "purpose": purpose,
        "outcome": outcome,
        "outcome_note": "TESTED means the listed suites ran on this commit with the stated results. It is not VALIDATED "
                        "(acceptance criteria), PACKAGED or RELEASED.",
        "totals": {"attempted": len(recs), "passed": len(recs) - len(failed), "failed": len(failed),
                   "skipped": 0, "cancelled": sum(1 for v in steps.values() if v == "cancelled"),
                   "seconds": round(sum(r["seconds"] for r in recs), 1)},
        "groups": groups,
        "steps": steps,
        "failures": [{k: r[k] for k in ("group", "name", "status", "exit_code", "summary_line", "first_failures", "log")}
                     for r in failed],
        "warnings": [{"name": r["name"], "warning": r["warning"]} for r in recs if r.get("warning")],
        "missing_evidence": missing,
        "suites": recs,
    }


def render_markdown(rep):
    i, t = rep["identification"], rep["totals"]
    L = ["## %s: %s" % (i["workflow"] or "CI", rep["outcome"]), ""]
    L += ["| | |", "|---|---|"]
    for k, v in (("Repository", i["repository"]), ("Branch", i["branch"]), ("Commit", "`%s`" % i["commit"]),
                 ("Run", "%s (attempt %s)" % (i["run_url"] or i["run_id"], i["run_attempt"])),
                 ("Trigger", "%s by %s" % (i["trigger"], i["actor"])), ("Started", i["started_at"]),
                 ("Completed", i["completed_at"]), ("Purpose", rep["purpose"])):
        L.append("| %s | %s |" % (k, str(v).replace("|", "\\|")))
    L += ["", "| Group | Attempted | Passed | Failed |", "|---|---|---|---|"]
    for g, c in rep["groups"].items():
        L.append("| %s | %d | %d | %d |" % (g, c["attempted"], c["passed"], c["failed"]))
    L.append("| **all** | **%d** | **%d** | **%d** |" % (t["attempted"], t["passed"], t["failed"]))
    L += ["", "Skipped suites: %d. Cancelled steps: %d. Suite time: %.0f s." % (t["skipped"], t["cancelled"], t["seconds"])]
    if rep["failures"]:
        L += ["", "### Failing suites", ""]
        for f in rep["failures"]:
            L.append("- **%s** (%s, %s, exit %s): %s" % (f["name"], f["group"], f["status"], f["exit_code"],
                                                          f["summary_line"] or "no count printed"))
            for line in f["first_failures"]:
                L.append("  - `%s`" % line.replace("`", "'"))
    if rep["warnings"]:
        L += ["", "### Warnings", ""] + ["- %s: %s" % (w["name"], w["warning"]) for w in rep["warnings"]]
    if rep["missing_evidence"]:
        L += ["", "### Missing evidence", ""] + ["- %s" % m for m in rep["missing_evidence"]]
    L += ["", rep["outcome_note"], "Full per-suite logs and `ci-report.json` are in this run's artifact.", ""]
    return "\n".join(L)


def cmd_report(a):
    steps = dict(s.split("=", 1) for s in a.step)
    rep = build_report(load_results(a.results), a.expect, steps, a.purpose, a.started)
    if a.json:
        os.makedirs(os.path.dirname(os.path.abspath(a.json)), exist_ok=True)
        with open(a.json, "w", encoding="utf-8") as f:
            json.dump(rep, f, indent=1)
    md = render_markdown(rep)
    if a.markdown:
        with open(a.markdown, "a", encoding="utf-8") as f:
            f.write(md + "\n")
    print(md)
    return 1 if a.strict and rep["outcome"] != "TESTED" else 0


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--group", required=True)
    r.add_argument("--list", required=True)
    r.add_argument("--prefix", default="")
    r.add_argument("--logs", required=True)
    r.add_argument("--results", required=True)
    r.add_argument("--timeout", type=int, default=1800, help="seconds per suite (default 1800)")
    r.add_argument("--fail-on-script-errors", action="store_true")
    r.add_argument("--require-counts", action="store_true", help="a suite that prints no 'N checks, M failures' line fails")
    r.add_argument("--floors", help="JSON {suite: least checks}: a suite running fewer fails (TEST-GOV-01)")
    o = sub.add_parser("report")
    o.add_argument("--results", action="append", default=[])
    o.add_argument("--expect", action="append", default=[], help="a group that must have results")
    o.add_argument("--step", action="append", default=[], help="NAME=OUTCOME of a workflow step")
    o.add_argument("--purpose", default="")
    o.add_argument("--started", default="")
    o.add_argument("--json")
    o.add_argument("--markdown")
    o.add_argument("--strict", action="store_true", help="exit 1 unless the outcome is TESTED")
    a = p.parse_args(argv)
    return cmd_run(a) if a.cmd == "run" else cmd_report(a)


if __name__ == "__main__":
    sys.exit(main())
