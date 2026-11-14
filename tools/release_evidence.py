"""Release evidence on the exact commit (B42-RELEASE-EXACT-SHA; owner directive 2026-11-14 item 3: "Require all mandatory
release tests to pass against the exact commit SHA used to produce the release packages. Failed, skipped, missing, or
incomplete required tests must block release. Reuse valid results for the exact SHA rather than running expensive duplicate
tests.").

What is mandatory is defined once, in tools/release_requirements.json. Two commands, both used by .github/workflows/release.yml:

  tests   Find a complete, fully green Tests (tests.yml) run of exactly this commit through the GitHub API and REUSE it. A
          run of the commit still in progress is AWAITED. When no full run of the commit exists (none, or only targeted,
          cancelled, skipped or expired ones) and --when-missing dispatch is given, ONE full run is started on the ref (only
          when the ref's head is this commit) and awaited. A full run of the commit that FAILED blocks: it is never re-run
          here to get a better result (a failed job is re-run by a person, "Re-run failed jobs", after deciding why it failed).
          A run passes only when: it is of this commit, completed, concluded success; its latest attempt's jobs are all
          success (plan, every shard of the full plan read from tests.yml at this commit, report; nothing skipped or
          cancelled); its consolidated validation (ci-validation-<run>-<attempt>) passes for this commit; every shard's report
          is TESTED on this commit with every suite passed and every game suite at or above its floor
          (tools/ci_check_floors.json); shard 0 ran the python, game and sim groups and each required python check (the
          unittest skip guard when tools/check_unittest_skips.py exists); and, when tools/check_test_env.py exists, shard 0's
          environment record (test-env.json) is "fit" for this commit.
  needs   In the release job: every job of release.yml named in release_requirements.json concluded success (sim-gate may be
          skipped only for the owner-approved private reuse of an earlier gate), and the tests evidence names this commit.

    python3 tools/release_evidence.py tests --repo OWNER/REPO --sha SHA --ref BRANCH --when-missing dispatch \\
        --json out/release-evidence.json --markdown "$GITHUB_STEP_SUMMARY"
    python3 tools/release_evidence.py needs --needs-json "$NEEDS" --visibility private --reuse-gate-run "" \\
        --evidence release-evidence/release-evidence.json --sha SHA

Uses the `gh` CLI (GH_TOKEN) for the API; standard library otherwise. Exit 0 = the requirement is met, 1 = blocked, 2 = usage.
"""
import argparse
import datetime
import io
import json
import os
import re
import subprocess
import sys
import time
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REQUIREMENTS = REPO / "tools" / "release_requirements.json"
FORMAT = "mml-release-evidence/1"

PASS, FAILED, INCOMPLETE, UNUSABLE = "pass", "failed", "in progress", "unusable"
FAILING_JOB = ("failure", "timed_out", "startup_failure")


def load_requirements(path=REQUIREMENTS):
    return json.loads(Path(path).read_text())


# ---------------------------------------------------------------------------------------------------------------- the tree

def full_shard_count(tests_yml_text):
    """The number of shards of a FULL Tests run, from tests.yml's plan job (its last `shards=[...]` line: the full branch)."""
    found = re.findall(r"shards=\[([0-9,\s]+)\]", tests_yml_text) or re.findall(r"(?m)^\s*shard: \[([0-9,\s]+)\]", tests_yml_text)
    if not found:                      # (the second form: tests.yml before its plan job, a static matrix)
        raise ValueError("tests.yml has no shards=[...] plan line")
    return len([x for x in found[-1].split(",") if x.strip()])


def tree_facts(root=REPO, req=None):
    """What the commit under release says the Tests run must contain (read from the checked-out tree, i.e. this commit)."""
    req = req or load_requirements()
    t = req["tests"]
    root = Path(root)
    floors = json.loads((root / t["floors"]).read_text())
    files = set()
    for c in t["python_checks"]:
        if c.get("when_file_exists") and (root / c["when_file_exists"]).exists():
            files.add(c["when_file_exists"])
    env = t.get("environment_record") or {}
    if env.get("when_file_exists") and (root / env["when_file_exists"]).exists():
        files.add(env["when_file_exists"])
    return {"full_shards": full_shard_count((root / ".github" / "workflows" / t["workflow"]).read_text()),
            "floors": {k: int(v) for k, v in floors.items() if not k.startswith("_")},
            "files": sorted(files)}


# ------------------------------------------------------------------------------------------------------------- the judging

def judge_jobs(run, jobs, sha, req, tree):
    """(verdict, problems) from the run record and its latest attempt's jobs alone (no downloads)."""
    t = req["tests"]
    if run.get("head_sha") != sha:
        return UNUSABLE, ["run of commit %s, not %s" % (str(run.get("head_sha"))[:12], sha[:12])]
    if run.get("status") != "completed":
        shard_jobs = [m for m in (re.match(t["shard_job"], j.get("name", "")) for j in jobs) if m]
        if shard_jobs and any(int(m.group(2)) != tree["full_shards"] for m in shard_jobs):
            return UNUSABLE, ["a targeted run (%s shard(s); a full run has %d), still %s" % (shard_jobs[0].group(2), tree["full_shards"], run.get("status"))]
        return INCOMPLETE, ["run is %s" % run.get("status")]
    problems, failing = [], False
    if run.get("conclusion") != "success":
        problems.append("run concluded %s" % run.get("conclusion"))
    names = {}
    for j in jobs:
        names.setdefault(j.get("name", ""), []).append(j)
    for need in t["required_jobs"]:
        if need not in names:
            problems.append("no %s job" % need)
    shards = {}
    for name, js in names.items():
        m = re.match(t["shard_job"], name)
        if m:
            shards[int(m.group(1))] = (int(m.group(2)), js)
    totals = {n for n, _ in shards.values()}
    targeted = bool(totals) and totals != {tree["full_shards"]}
    if targeted:
        problems.append("not a full run: %s shard(s), a full run of this commit has %d (a targeted 'only'/'group' run)"
                        % ("/".join(map(str, sorted(totals))), tree["full_shards"]))
    for k in range(tree["full_shards"]):
        if k not in shards and not targeted:
            problems.append("shard %d: no job" % k)
    for name, js in sorted(names.items()):
        for j in js:
            c = j.get("conclusion")
            if j.get("status") != "completed" or c != "success":
                problems.append("job %s: %s" % (name, c or j.get("status")))
                # a test shard that failed is a test failure; a cancelled run's report failing (its shards missing) is not
                failing = failing or (c in FAILING_JOB and bool(re.match(t["shard_job"], name)))
    if not problems:
        return PASS, []
    return (FAILED if failing and not targeted else UNUSABLE), problems


def judge_evidence(run, ev, sha, req, tree):
    """(verdict, problems) from the downloaded artifacts: ev = {"validation": dict|None, "validation_attempt": int|None,
    "shards": {k: {"report": dict|None, "manifest": dict|None, "env": dict|None, "attempt": int}}, "expired": [names]}."""
    t = req["tests"]
    problems, failing = [], False
    attempt = int(run.get("run_attempt") or 1)
    if ev.get("expired"):
        problems.append("evidence expired: %s" % ", ".join(sorted(ev["expired"])))
    v = ev.get("validation")
    if v is None:
        problems.append("no consolidated validation (ci-validation-%s-%d)" % (run.get("id"), attempt))
    else:
        if ev.get("validation_attempt") != attempt:
            problems.append("the consolidated validation is from attempt %s, not the latest attempt %d" % (ev.get("validation_attempt"), attempt))
        if v.get("sha") != sha:
            problems.append("the consolidated validation names commit %s" % v.get("sha"))
        src = (v.get("sources") or {}).get("tests") or {}
        if v.get("result") != "pass" or src.get("result") != "pass":
            problems.append("the consolidated validation did not pass (%s)" % "; ".join((v.get("problems") or [])[:5] or [str(v.get("result"))]))
            failing = failing or bool(src.get("failed"))
        if src.get("shards") != tree["full_shards"]:
            problems.append("the consolidated validation covers %s shard(s), not %d" % (src.get("shards"), tree["full_shards"]))
    floors = tree["floors"]
    shards = ev.get("shards") or {}
    for k in range(tree["full_shards"]):
        s = shards.get(k)
        if not s or s.get("report") is None:
            problems.append("shard %d: no report (ci-report-%s-*-shard%d)" % (k, run.get("id"), k))
            continue
        if s.get("attempt", 0) > attempt:
            problems.append("shard %d: report from attempt %s, after the run's attempt %d" % (k, s.get("attempt"), attempt))
        rep, man = s["report"], s.get("manifest") or {}
        if (rep.get("identification") or {}).get("commit") != sha:
            problems.append("shard %d: reports commit %s" % (k, (rep.get("identification") or {}).get("commit")))
        if man and (man.get("commit") != sha or man.get("shards") != tree["full_shards"]):
            problems.append("shard %d: planned on %s for %s shard(s)" % (k, man.get("commit"), man.get("shards")))
        if rep.get("outcome") != "TESTED":
            problems.append("shard %d: %s" % (k, rep.get("outcome")))
        for miss in rep.get("missing_evidence") or []:
            problems.append("shard %d: missing evidence: %s" % (k, miss))
        for su in rep.get("suites") or []:
            if su.get("status") != "passed":
                problems.append("shard %d: %s %s" % (k, su.get("name"), su.get("status")))
                failing = True
            elif su.get("group") == "game":
                if su.get("checks") is None:
                    problems.append("shard %d: %s printed no check count" % (k, su.get("name")))
                elif su.get("name") in floors and su["checks"] < floors[su["name"]]:
                    problems.append("shard %d: %s ran %d checks, under its floor of %d" % (k, su["name"], su["checks"], floors[su["name"]]))
                    failing = True
    s0 = shards.get(0) or {}
    rep0 = s0.get("report") or {}
    if rep0:
        groups = rep0.get("groups") or {}
        for g in t["full_run_groups"]:
            if not (groups.get(g) or {}).get("attempted"):
                problems.append("shard 0 ran no %s group (not a full run)" % g)
        for step in ("python", "sim"):
            if (rep0.get("steps") or {}).get(step) != "success":
                problems.append("shard 0: step %s %s" % (step, (rep0.get("steps") or {}).get(step)))
        py = [su for su in rep0.get("suites") or [] if su.get("group") == "python"]
        for c in t["python_checks"]:
            want = c["command_contains"]
            if c.get("when_file_exists") and c["when_file_exists"] not in tree["files"]:
                want = c.get("else_contains", want)
            hit = [su for su in py if want in su.get("command", "")]
            if not hit:
                problems.append("shard 0: python check '%s' did not run" % want)
            elif any(su.get("status") != "passed" for su in hit):
                problems.append("shard 0: python check '%s' failed" % want)
                failing = True
        envreq = t.get("environment_record") or {}
        if envreq.get("when_file_exists") in tree["files"]:
            env = s0.get("env")
            if env is None:
                problems.append("shard 0: no environment record (%s)" % envreq["artifact_file"])
            elif env.get("verdict") != envreq["verdict"] or env.get("candidate") != sha:
                problems.append("shard 0: environment record %s for %s" % (env.get("verdict"), env.get("candidate")))
    if not problems:
        return PASS, []
    return (FAILED if failing else UNUSABLE), problems


def decide(judged, when_missing):
    """judged: [{"run": run, "verdict": v, "problems": [...]}], newest first -> (decision, chosen run or None).
    decision: "reuse" (a passing run), "wait" (a run of the commit is in progress), "dispatch" (no full run exists and
    starting one is allowed), "blocked"."""
    for j in judged:
        if j["verdict"] == PASS:
            return "reuse", j["run"]
    if any(j["verdict"] == INCOMPLETE for j in judged):
        return "wait", None
    if any(j["verdict"] == FAILED for j in judged):
        return "blocked", None
    return ("dispatch" if when_missing == "dispatch" else "blocked"), None


# ---------------------------------------------------------------------------------------------------------------- GitHub

class GitHub:
    """The few API calls needed, through the `gh` CLI (which follows the artifact download redirect without leaking the token)."""

    def __init__(self, repo):
        self.repo = repo

    def _api(self, path, *args, raw=False):
        p = subprocess.run(["gh", "api", "repos/%s/%s" % (self.repo, path)] + list(args), capture_output=True, check=False)
        if p.returncode != 0:
            raise RuntimeError("gh api %s: %s" % (path, p.stderr.decode(errors="replace").strip()[:300]))
        return p.stdout if raw else json.loads(p.stdout or b"{}")

    def runs(self, workflow, sha):
        return self._api("actions/workflows/%s/runs?head_sha=%s&per_page=100" % (workflow, sha)).get("workflow_runs", [])

    def jobs(self, run_id):
        return self._api("actions/runs/%s/jobs?filter=latest&per_page=100" % run_id).get("jobs", [])

    def artifacts(self, run_id):
        return self._api("actions/runs/%s/artifacts?per_page=100" % run_id).get("artifacts", [])

    def artifact_files(self, artifact_id, names):
        z = zipfile.ZipFile(io.BytesIO(self._api("actions/artifacts/%s/zip" % artifact_id, raw=True)))
        return {n: z.read(n) for n in z.namelist() if n in names}

    def ref_sha(self, ref):
        return self._api("commits/%s" % ref).get("sha")

    def dispatch(self, workflow, ref, sha):
        # release_sha puts the run in a concurrency group of its own commit (tests.yml): it cancels no other Tests run and no
        # push's run cancels it (owner 2026-11-14, B42-Q-RELEASE-TESTS item 2)
        self._api("actions/workflows/%s/dispatches" % workflow, "--method", "POST", "-f", "ref=%s" % ref,
                  "-f", "inputs[release_sha]=%s" % sha, raw=True)

    def runs_since(self, workflow, ref, since):
        """Runs of the workflow on the branch created at or after `since` (to see a started run that tests another commit)."""
        return [r for r in self._api("actions/workflows/%s/runs?branch=%s&event=workflow_dispatch&per_page=30" % (workflow, ref)).get("workflow_runs", [])
                if (r.get("created_at") or "") >= since]


def collect_evidence(gh, run):
    """Download the run's consolidated validation (latest attempt) and each shard's latest report."""
    rid = run["id"]
    ev = {"validation": None, "validation_attempt": None, "shards": {}, "expired": []}
    best_v, best_s = None, {}
    for a in gh.artifacts(rid):
        m = re.match(r"^ci-validation-%s-(\d+)$" % rid, a["name"])
        if m and (best_v is None or int(m.group(1)) > best_v[0]):
            best_v = (int(m.group(1)), a)
        m = re.match(r"^ci-report-%s-(\d+)-shard(\d+)$" % rid, a["name"])
        if m and int(m.group(1)) >= best_s.get(int(m.group(2)), (0, None))[0]:
            best_s[int(m.group(2))] = (int(m.group(1)), a)
    if best_v:
        if best_v[1].get("expired"):
            ev["expired"].append(best_v[1]["name"])
        else:
            f = gh.artifact_files(best_v[1]["id"], {"validation.json"})
            ev["validation"] = json.loads(f["validation.json"]) if "validation.json" in f else None
            ev["validation_attempt"] = best_v[0]
    for k, (att, a) in best_s.items():
        if a.get("expired"):
            ev["expired"].append(a["name"])
            continue
        f = gh.artifact_files(a["id"], {"ci-report.json", "shard.json", "test-env.json"})
        ev["shards"][k] = {"attempt": att, "report": json.loads(f["ci-report.json"]) if "ci-report.json" in f else None,
                           "manifest": json.loads(f["shard.json"]) if "shard.json" in f else None,
                           "env": json.loads(f["test-env.json"]) if "test-env.json" in f else None}
    return ev


def judge_all(gh, sha, req, tree, log=print):
    out = []
    runs = sorted(gh.runs(req["tests"]["workflow"], sha), key=lambda r: (r.get("created_at") or "", r.get("id") or 0), reverse=True)
    for run in runs:
        verdict, problems = judge_jobs(run, gh.jobs(run["id"]), sha, req, tree)
        if verdict == PASS:
            verdict, problems = judge_evidence(run, collect_evidence(gh, run), sha, req, tree)
        log("Tests run %s (attempt %s, %s, %s): %s%s" % (run.get("id"), run.get("run_attempt"), run.get("event"), run.get("status"),
                                                         verdict.upper(), "".join("\n    - " + p for p in problems[:20])))
        out.append({"run": run, "verdict": verdict, "problems": problems})
    return out


def find_tests(gh, sha, ref, req, tree, when_missing, sleep=time.sleep, now=time.monotonic, log=print):
    """The whole `tests` command, with the clock and the API injectable (tests). Returns the evidence record."""
    t = req["tests"]
    deadline = now() + 60 * float(t["max_wait_minutes"])
    dispatched = dispatched_floor = None
    while True:
        judged = judge_all(gh, sha, req, tree, log)
        decision, chosen = decide(judged, when_missing if dispatched is None else "fail")
        if decision == "dispatch":
            head = gh.ref_sha(ref)
            if head != sha:
                return record(sha, "blocked", None, judged, "no full Tests run of %s exists, and one cannot be started: the head of %s is now %s, so a "
                              "run started on it would test another commit. Start Tests on this commit, or release the newer commit." % (sha[:12], ref, str(head)[:12]))
            gh.dispatch(t["workflow"], ref, sha)
            at = datetime.datetime.now(datetime.timezone.utc)
            dispatched = at.strftime("%Y-%m-%dT%H:%M:%SZ")
            dispatched_floor = (at - datetime.timedelta(minutes=2)).strftime("%Y-%m-%dT%H:%M:%SZ")   # clock skew
            log("No full Tests run of %s: started one on %s (%s); waiting for it." % (sha[:12], ref, dispatched))
            sleep(t["poll_seconds"])
            continue
        started = dispatched and any((j["run"].get("created_at") or "") >= dispatched_floor for j in judged)
        if dispatched and not started:
            moved = [r for r in gh.runs_since(t["workflow"], ref, dispatched_floor) if r.get("head_sha") != sha]
            if moved:
                return record(sha, "blocked", None, judged, "the Tests run started for this release (%s) tests commit %s: %s moved on "
                              "after the check. Nothing is published; release the newer commit, or start Tests on this one."
                              % (moved[0].get("id"), str(moved[0].get("head_sha"))[:12], ref), dispatched)
        if decision == "wait" or (dispatched and not started):
            if now() >= deadline:
                return record(sha, "blocked", None, judged, "the Tests run of this commit did not finish within %s minutes" % t["max_wait_minutes"], dispatched)
            sleep(t["poll_seconds"])
            continue
        if decision == "reuse":
            return record(sha, "pass", chosen, judged, "reused" if not dispatched else "started for this release and passed", dispatched)
        why = ("a full Tests run of this commit failed: fix the failure, or (after deciding the failure was the runner's, not the "
               "game's) re-run its failed jobs; it is never re-run here for a better result") if any(j["verdict"] == FAILED for j in judged) \
            else "no complete, fully green full Tests run of this commit"
        return record(sha, "blocked", None, judged, why, dispatched)


def record(sha, result, run, judged, why, dispatched=None):
    return {"format": FORMAT, "sha": sha, "result": result, "why": why, "dispatched_at": dispatched,
            "run": ({"id": run.get("id"), "attempt": run.get("run_attempt"), "url": run.get("html_url"), "event": run.get("event"),
                     "created_at": run.get("created_at")} if run else None),
            "considered": [{"id": j["run"].get("id"), "attempt": j["run"].get("run_attempt"), "head_sha": j["run"].get("head_sha"),
                            "status": j["run"].get("status"), "conclusion": j["run"].get("conclusion"), "verdict": j["verdict"],
                            "problems": j["problems"]} for j in judged]}


def markdown(rec):
    L = ["## Release tests on the exact commit (B42-RELEASE-EXACT-SHA)", "",
         "Commit `%s`: **%s**, %s." % (rec["sha"], rec["result"].upper(), rec["why"])]
    if rec["run"]:
        L.append("Tests run: %s (attempt %s, %s)." % (rec["run"]["url"] or rec["run"]["id"], rec["run"]["attempt"], rec["run"]["event"]))
    if rec["considered"]:
        L += ["", "| Run | Attempt | Status | Verdict | Problems |", "|---|---|---|---|---|"]
        for c in rec["considered"]:
            L.append("| %s | %s | %s/%s | %s | %s |" % (c["id"], c["attempt"], c["status"], c["conclusion"], c["verdict"],
                                                       "; ".join(c["problems"][:5]).replace("|", "/") or "none"))
    else:
        L += ["", "No Tests run of this commit exists."]
    return "\n".join(L) + "\n"


# ------------------------------------------------------------------------------------------------------- the release job

def judge_needs(needs, req, visibility, reuse_gate_run, evidence=None, sha=None):
    """The release job's own check: every mandatory job of release.yml succeeded on this run, and the tests evidence names this commit."""
    problems = []
    for job, rule in req["release_jobs"].items():
        if job.startswith("_"):
            continue
        result = (needs.get(job) or {}).get("result")
        if result == rule["must"]:
            continue
        if result == "skipped" and rule.get("may_skip_when") and reuse_gate_run and visibility == "private":
            continue
        problems.append("%s: %s (%s)" % (job, result or "missing (not a dependency of the release job)", rule["what"]))
    if evidence is not None or sha is not None:
        if evidence is None:
            problems.append("no release evidence record (tests-evidence job artifact)")
        elif evidence.get("result") != "pass" or evidence.get("sha") != sha:
            problems.append("the tests evidence is %s for commit %s, not a pass for %s" % (evidence.get("result"), evidence.get("sha"), sha))
    return problems


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    a1 = sub.add_parser("tests")
    a1.add_argument("--repo", required=True)
    a1.add_argument("--sha", required=True)
    a1.add_argument("--ref", required=True)
    a1.add_argument("--when-missing", choices=["dispatch", "fail"], default="fail")
    a1.add_argument("--json", default="")
    a1.add_argument("--markdown", default="")
    a2 = sub.add_parser("needs")
    a2.add_argument("--needs-json", required=True)
    a2.add_argument("--visibility", required=True)
    a2.add_argument("--reuse-gate-run", default="")
    a2.add_argument("--evidence", default="")
    a2.add_argument("--sha", default="")
    for p in (a1, a2):
        p.add_argument("--requirements", default=str(REQUIREMENTS))
    a = ap.parse_args(argv)
    req = load_requirements(a.requirements)
    if a.cmd == "tests":
        rec = find_tests(GitHub(a.repo), a.sha, a.ref, req, tree_facts(REPO, req), a.when_missing)
        md = markdown(rec)
        print(md)
        if a.json:
            Path(a.json).parent.mkdir(parents=True, exist_ok=True)
            Path(a.json).write_text(json.dumps(rec, indent=1) + "\n")
        if a.markdown:
            with open(a.markdown, "a") as f:
                f.write(md)
        if rec["result"] != "pass":
            print("::error::release blocked: %s" % rec["why"])
        return 0 if rec["result"] == "pass" else 1
    evidence = None
    if a.evidence:
        try:
            evidence = json.loads(Path(a.evidence).read_text())
        except (OSError, ValueError):
            evidence = None
    problems = judge_needs(json.loads(a.needs_json), req, a.visibility, a.reuse_gate_run,
                           evidence if a.evidence else None, a.sha or None)
    for p in problems:
        print("::error::release blocked: %s" % p)
    print("Mandatory release requirements (tools/release_requirements.json): %s" % ("all met" if not problems else "%d not met" % len(problems)))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
