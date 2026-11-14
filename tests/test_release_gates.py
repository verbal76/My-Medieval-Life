"""B42-RELEASE-EXACT-SHA and B42-ANDROID-DEBUGGABLE (owner directive 2026-11-14 items 3 and 5): the release gates' decisions.

tools/release_evidence.py is tested on GitHub API responses recorded from real Tests runs (tests/fixtures/release/api_*.json:
a green full run on b3c9eb5, a run with a failed shard on 1d03eea, a cancelled run on 1b8bbd8, a targeted one-shard run on
efb0b93) and on variants of the green one (a skipped shard, floors not met, an older attempt, no run, another commit's run,
a run still in progress, a run started because none existed). tools/check_android_apk.py is tested on manifests from local
Godot 4.7.2 --export-release and --export-debug exports of a minimal project carrying the game's Android preset, the release
template's own manifest, and apksigner outputs. No network, no Godot."""
import contextlib
import copy
import io
import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIX = ROOT / "tests" / "fixtures" / "release"
sys.path.insert(0, str(ROOT / "tools"))
import axml  # noqa: E402
import check_android_apk as apk  # noqa: E402
import release_evidence as ev  # noqa: E402

REQ = ev.load_requirements()


def fixture(name):
    return json.loads((FIX / name).read_text())


class FakeGitHub:
    """Serves a recorded fixture; `after_dispatch` (a fixture) appears once dispatch() is called, `progress` lists run
    states served in turn before the recorded one (a run in progress)."""

    def __init__(self, fx, head=None, after_dispatch=None, progress=()):
        self.fx, self.head, self.after, self.progress = copy.deepcopy(fx), head, after_dispatch, list(progress)
        self.dispatched, self.downloads = [], 0

    def runs(self, workflow, sha):
        assert workflow == "tests.yml"
        runs = copy.deepcopy([r for r in self.fx["runs"] if r["head_sha"] == sha or self.fx.get("serve_any_sha")])
        if self.progress and runs:
            runs[0].update(self.progress.pop(0))
        return runs

    def jobs(self, rid):
        return copy.deepcopy(self.fx["jobs"][str(rid)])

    def artifacts(self, rid):
        return copy.deepcopy(self.fx["artifacts"][str(rid)])

    def artifact_files(self, aid, names):
        self.downloads += 1
        return {n: json.dumps(v).encode() for n, v in self.fx["files"].get(str(aid), {}).items() if n in names}

    def ref_sha(self, ref):
        return self.head

    def runs_since(self, workflow, ref, since):
        return [r for r in self.fx.get("branch_runs", []) if r["created_at"] >= since]

    def dispatch(self, workflow, ref, sha):
        self.dispatched.append((workflow, ref, sha))
        if self.after:
            for k in ("runs",):
                self.fx[k] = self.after[k] + self.fx[k]
            for k in ("jobs", "artifacts", "files"):
                self.fx[k].update(self.after[k])


class Clock:
    def __init__(self):
        self.t = 0.0

    def now(self):
        return self.t

    def sleep(self, s):
        self.t += s


def find(gh, sha, tree, when_missing="fail", ref="wip/x"):
    c = Clock()
    return ev.find_tests(gh, sha, ref, REQ, tree, when_missing, sleep=c.sleep, now=c.now, log=lambda *a: None)


GREEN = fixture("api_green_b3c9eb5.json")
SHA = GREEN["sha"]
RID = str(GREEN["runs"][0]["id"])


def variant(edit):
    fx = copy.deepcopy(GREEN)
    edit(fx)
    return fx


def shard0_files(fx):
    aid = next(str(a["id"]) for a in fx["artifacts"][RID] if a["name"].endswith("-shard0"))
    return fx["files"][aid]


class TestsEvidence(unittest.TestCase):
    def test_green_full_run_is_reused_without_a_new_run(self):
        gh = FakeGitHub(GREEN, head=SHA)
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual(rec["result"], "pass", rec)
        self.assertEqual(rec["run"]["id"], int(RID))
        self.assertEqual(gh.dispatched, [], "a valid run of the exact commit exists: nothing is started")
        self.assertEqual(rec["considered"][0]["problems"], [])

    def test_failed_shard_blocks_and_is_never_rerun(self):
        fx = fixture("api_failed_1d03eea.json")
        gh = FakeGitHub(fx, head=fx["sha"])
        rec = find(gh, fx["sha"], fx["tree"], "dispatch")
        self.assertEqual(rec["result"], "blocked")
        self.assertEqual(rec["considered"][0]["verdict"], ev.FAILED)
        self.assertTrue(any("shard 5 of 12): failure" in p for p in rec["considered"][0]["problems"]), rec["considered"][0]["problems"])
        self.assertEqual(gh.dispatched, [], "a failed run is not re-run for a better result")
        self.assertIn("failed", rec["why"])

    def test_skipped_shard_blocks(self):
        def skip(fx):
            j = next(j for j in fx["jobs"][RID] if j["name"] == "test (shard 3 of 12)")
            j["conclusion"] = "skipped"
        fx = variant(skip)
        rec = find(FakeGitHub(fx, head=SHA), SHA, fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertIn("job test (shard 3 of 12): skipped", rec["considered"][0]["problems"])

    def test_missing_shard_job_blocks(self):
        fx = variant(lambda fx: fx["jobs"].__setitem__(RID, [j for j in fx["jobs"][RID] if j["name"] != "test (shard 7 of 12)"]))
        rec = find(FakeGitHub(fx, head=SHA), SHA, fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertIn("shard 7: no job", rec["considered"][0]["problems"])

    def test_cancelled_run_blocks(self):
        fx = fixture("api_cancelled_1b8bbd8.json")
        rec = find(FakeGitHub(fx, head="0" * 40), fx["sha"], fx["tree"], "dispatch")
        self.assertEqual(rec["result"], "blocked")
        self.assertEqual(rec["considered"][0]["verdict"], ev.UNUSABLE)
        self.assertIn("run concluded cancelled", rec["considered"][0]["problems"])

    def test_targeted_run_is_not_full_evidence(self):
        fx = fixture("api_targeted_efb0b93.json")
        rec = find(FakeGitHub(fx), fx["sha"], fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertTrue(any("not a full run" in p for p in rec["considered"][0]["problems"]))

    def test_no_run_for_the_commit_blocks(self):
        rec = find(FakeGitHub(GREEN), "f" * 40, GREEN["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertEqual(rec["considered"], [])

    def test_a_run_of_another_commit_never_counts(self):
        fx = variant(lambda fx: fx.__setitem__("serve_any_sha", True))   # an API answer naming another commit's run
        other = "a" * 40
        rec = find(FakeGitHub(fx, head=other), other, fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertTrue(rec["considered"][0]["problems"][0].startswith("run of commit b3c9eb593fe1"))

    def test_floor_not_met_blocks(self):
        tree = copy.deepcopy(GREEN["tree"])
        rep = shard0_files(GREEN)["ci-report.json"]
        suite = next(s for s in rep["suites"] if s["group"] == "game" and s["checks"])
        tree["floors"][suite["name"]] = suite["checks"] + 1
        rec = find(FakeGitHub(GREEN), SHA, tree)
        self.assertEqual(rec["result"], "blocked")
        self.assertEqual(rec["considered"][0]["verdict"], ev.FAILED)
        self.assertTrue(any("under its floor of %d" % (suite["checks"] + 1) in p for p in rec["considered"][0]["problems"]))

    def test_suite_without_a_count_blocks(self):
        def nocount(fx):
            next(s for s in shard0_files(fx)["ci-report.json"]["suites"] if s["group"] == "game")["checks"] = None
        fx = variant(nocount)
        rec = find(FakeGitHub(fx), SHA, fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertTrue(any("printed no check count" in p for p in rec["considered"][0]["problems"]))

    def test_validation_of_an_older_attempt_blocks(self):
        def rerun(fx):
            fx["runs"][0]["run_attempt"] = 2
        fx = variant(rerun)
        rec = find(FakeGitHub(fx), SHA, fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertTrue(any("not the latest attempt 2" in p for p in rec["considered"][0]["problems"]))

    def test_shard_report_of_another_commit_blocks(self):
        fx = variant(lambda fx: shard0_files(fx)["ci-report.json"]["identification"].__setitem__("commit", "b" * 40))
        rec = find(FakeGitHub(fx), SHA, fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertIn("shard 0: reports commit " + "b" * 40, rec["considered"][0]["problems"])

    def test_missing_shard_report_blocks(self):
        fx = variant(lambda fx: fx["artifacts"].__setitem__(RID, [a for a in fx["artifacts"][RID] if not a["name"].endswith("-shard4")]))
        rec = find(FakeGitHub(fx), SHA, fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertTrue(any(p.startswith("shard 4: no report") for p in rec["considered"][0]["problems"]))

    def test_expired_evidence_blocks(self):
        fx = variant(lambda fx: [a.__setitem__("expired", True) for a in fx["artifacts"][RID]])
        rec = find(FakeGitHub(fx), SHA, fx["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertTrue(any(p.startswith("evidence expired") for p in rec["considered"][0]["problems"]))

    def test_guards_required_when_the_commit_has_them(self):
        # the commit carries Agent C's unittest skip guard and environment check: the run must have used them
        tree = copy.deepcopy(GREEN["tree"])
        tree["files"] = ["tools/check_test_env.py", "tools/check_unittest_skips.py"]
        rec = find(FakeGitHub(GREEN), SHA, tree)
        probs = rec["considered"][0]["problems"]
        self.assertEqual(rec["result"], "blocked")
        self.assertIn("shard 0: python check 'tools/check_unittest_skips.py' did not run", probs)
        self.assertIn("shard 0: no environment record (test-env.json)", probs)

        def guarded(fx):
            files = shard0_files(fx)
            unit = next(s for s in files["ci-report.json"]["suites"] if "unittest discover" in s["command"])
            unit["command"] = "python3 tools/check_unittest_skips.py"
            files["test-env.json"] = {"format": "mml-test-env/1", "candidate": SHA, "verdict": "fit", "problems": []}
        fx = variant(guarded)
        self.assertEqual(find(FakeGitHub(fx), SHA, tree)["result"], "pass")
        fx["files"][next(str(a["id"]) for a in fx["artifacts"][RID] if a["name"].endswith("-shard0"))]["test-env.json"]["verdict"] = "environment"
        self.assertEqual(find(FakeGitHub(fx), SHA, tree)["result"], "blocked")

    def test_failed_python_check_blocks(self):
        def fail(fx):
            next(s for s in shard0_files(fx)["ci-report.json"]["suites"] if "check_requirements" in s["command"])["status"] = "failed"
        fx = variant(fail)
        rec = find(FakeGitHub(fx), SHA, fx["tree"], "dispatch")
        self.assertEqual(rec["result"], "blocked")
        self.assertEqual(rec["considered"][0]["verdict"], ev.FAILED)

    def test_run_in_progress_is_awaited_then_reused(self):
        gh = FakeGitHub(GREEN, head=SHA, progress=[{"status": "in_progress", "conclusion": None}] * 3)
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual(rec["result"], "pass")
        self.assertEqual(gh.dispatched, [], "a run of the commit in progress is awaited, not duplicated")

    def test_run_in_progress_too_long_blocks(self):
        gh = FakeGitHub(GREEN, progress=[{"status": "in_progress", "conclusion": None}] * 1000)
        rec = find(gh, SHA, GREEN["tree"])
        self.assertEqual(rec["result"], "blocked")
        self.assertIn("did not finish within", rec["why"])

    def test_none_exists_so_one_is_started_and_awaited(self):
        empty = {"runs": [], "jobs": {}, "artifacts": {}, "files": {}}
        later = copy.deepcopy(GREEN)
        later["runs"][0]["created_at"] = "2999-01-01T00:00:00Z"        # created after the dispatch
        gh = FakeGitHub(empty, head=SHA, after_dispatch=later)
        rec = find(gh, SHA, GREEN["tree"], "dispatch", ref="wip/b42-integration")
        self.assertEqual(gh.dispatched, [("tests.yml", "wip/b42-integration", SHA)], "started with release_sha: its own concurrency group")
        self.assertEqual(rec["result"], "pass")
        self.assertIn("started for this release", rec["why"])

    # owner 2026-11-14, B42-Q-RELEASE-TESTS: "If a run for the exact commit is already underway, wait for and reuse it. If another
    # commit is running, queue the release verification or otherwise isolate its concurrency so neither run cancels the other."
    def test_concurrent_run_of_the_exact_commit_is_awaited_and_reused(self):
        gh = FakeGitHub(GREEN, head=SHA, progress=[{"status": "queued", "conclusion": None}, {"status": "in_progress", "conclusion": None}])
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual((rec["result"], rec["run"]["id"], gh.dispatched), ("pass", int(RID), []))

    def test_concurrent_run_of_another_commit_is_left_alone_and_the_release_run_queues(self):
        other = copy.deepcopy(GREEN["runs"][0])
        other.update({"id": 1, "head_sha": "e" * 40, "status": "in_progress", "conclusion": None, "event": "push"})
        fx = {"runs": [other], "jobs": {"1": []}, "artifacts": {"1": []}, "files": {}}
        later = copy.deepcopy(GREEN)
        later["runs"][0]["created_at"] = "2999-01-01T00:00:00Z"
        gh = FakeGitHub(fx, head=SHA, after_dispatch=later, progress=[])
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual(rec["result"], "pass")
        self.assertEqual(gh.dispatched, [("tests.yml", "wip/x", SHA)], "the other commit's run is not waited on and not reused")
        self.assertFalse(hasattr(ev.GitHub, "cancel"), "the release never cancels a Tests run")
        self.assertEqual([r["status"] for r in gh.fx["runs"] if r["id"] == 1], ["in_progress"])

    def test_release_run_queued_behind_others_is_awaited(self):
        later = copy.deepcopy(GREEN)
        later["runs"][0]["created_at"] = "2999-01-01T00:00:00Z"
        gh = FakeGitHub({"runs": [], "jobs": {}, "artifacts": {}, "files": {}}, head=SHA, after_dispatch=later)
        gh.progress = [{"status": "queued", "conclusion": None}] * 5 + [{"status": "in_progress", "conclusion": None}] * 5
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual((rec["result"], len(gh.dispatched)), ("pass", 1))

    def test_expired_evidence_is_verified_again(self):
        fx = variant(lambda fx: [a.__setitem__("expired", True) for a in fx["artifacts"][RID]])
        later = copy.deepcopy(GREEN)
        later["runs"][0].update({"id": 2, "created_at": "2999-01-01T00:00:00Z"})
        later["jobs"] = {"2": later["jobs"][RID]}
        later["artifacts"] = {"2": [dict(a, name=a["name"].replace(RID, "2")) for a in later["artifacts"][RID]]}
        gh = FakeGitHub(fx, head=SHA, after_dispatch=later)
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual((rec["result"], rec["run"]["id"], len(gh.dispatched)), ("pass", 2, 1))
        self.assertEqual(rec["considered"][1]["verdict"], ev.UNUSABLE)

    def test_cancelled_release_run_never_passes(self):
        later = copy.deepcopy(GREEN)
        later["runs"][0].update({"created_at": "2999-01-01T00:00:00Z", "conclusion": "cancelled"})
        gh = FakeGitHub({"runs": [], "jobs": {}, "artifacts": {}, "files": {}}, head=SHA, after_dispatch=later)
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual((rec["result"], len(gh.dispatched)), ("blocked", 1), "started once, cancelled: blocked, not started again")

    def test_failed_release_run_blocks(self):
        later = copy.deepcopy(GREEN)
        later["runs"][0].update({"created_at": "2999-01-01T00:00:00Z", "conclusion": "failure"})
        next(j for j in later["jobs"][RID] if j["name"] == "test (shard 2 of 12)")["conclusion"] = "failure"
        gh = FakeGitHub({"runs": [], "jobs": {}, "artifacts": {}, "files": {}}, head=SHA, after_dispatch=later)
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual((rec["result"], len(gh.dispatched)), ("blocked", 1))
        self.assertEqual(rec["considered"][0]["verdict"], ev.FAILED)

    def test_started_run_of_a_moved_branch_blocks(self):
        moved = copy.deepcopy(GREEN["runs"][0])
        moved.update({"id": 3, "head_sha": "9" * 40, "created_at": "2999-01-01T00:00:00Z", "status": "completed", "conclusion": "failure"})
        fx = {"runs": [], "jobs": {}, "artifacts": {}, "files": {}, "branch_runs": [moved]}
        gh = FakeGitHub(fx, head=SHA)
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual(rec["result"], "blocked")
        self.assertIn("moved on", rec["why"])

    def test_no_dispatch_when_the_ref_moved_on(self):
        gh = FakeGitHub({"runs": [], "jobs": {}, "artifacts": {}, "files": {}}, head="c" * 40)
        rec = find(gh, SHA, GREEN["tree"], "dispatch")
        self.assertEqual(gh.dispatched, [])
        self.assertEqual(rec["result"], "blocked")
        self.assertIn("would test another commit", rec["why"])

    def test_shard_count_read_from_tests_yml(self):
        self.assertEqual(ev.full_shard_count((ROOT / ".github" / "workflows" / "tests.yml").read_text()), 12)
        self.assertEqual(ev.full_shard_count("        shard: [0, 1, 2, 3, 4, 5, 6, 7]\n"), 8)
        tree = ev.tree_facts(ROOT, REQ)
        self.assertEqual(tree["full_shards"], 12)
        self.assertGreater(len(tree["floors"]), 100)

    def test_markdown_names_the_commit_and_run(self):
        rec = find(FakeGitHub(GREEN), SHA, GREEN["tree"])
        md = ev.markdown(rec)
        self.assertIn(SHA, md)
        self.assertIn(RID, md)


NEEDS_OK = {"tests-evidence": {"result": "success"}, "sim-gate": {"result": "success"}, "package": {"result": "success"},
            "smoke-windows": {"result": "success"}}


class ReleaseJobNeeds(unittest.TestCase):
    def test_all_success(self):
        self.assertEqual(ev.judge_needs(NEEDS_OK, REQ, "private", ""), [])

    def test_each_failure_blocks(self):
        for job in NEEDS_OK:
            for res in ("failure", "cancelled", "skipped", None):
                n = copy.deepcopy(NEEDS_OK)
                if res is None:
                    del n[job]
                else:
                    n[job]["result"] = res
                if job == "sim-gate" and res == "skipped":
                    continue
                self.assertTrue(ev.judge_needs(n, REQ, "private", ""), (job, res))

    def test_gate_reuse_only_when_owner_approved_private(self):
        n = copy.deepcopy(NEEDS_OK)
        n["sim-gate"]["result"] = "skipped"
        self.assertTrue(ev.judge_needs(n, REQ, "private", ""))
        self.assertEqual(ev.judge_needs(n, REQ, "private", "43527275522"), [])
        self.assertTrue(ev.judge_needs(n, REQ, "public", "43527275522"))

    def test_tests_skipped_is_never_allowed(self):
        n = copy.deepcopy(NEEDS_OK)
        n["tests-evidence"]["result"] = "skipped"
        self.assertTrue(ev.judge_needs(n, REQ, "private", "43527275522"))

    def test_evidence_must_name_this_commit(self):
        self.assertEqual(ev.judge_needs(NEEDS_OK, REQ, "private", "", {"result": "pass", "sha": SHA}, SHA), [])
        self.assertTrue(ev.judge_needs(NEEDS_OK, REQ, "private", "", {"result": "pass", "sha": "d" * 40}, SHA))
        self.assertTrue(ev.judge_needs(NEEDS_OK, REQ, "private", "", {"result": "blocked", "sha": SHA}, SHA))
        self.assertTrue(ev.judge_needs(NEEDS_OK, REQ, "private", "", None, SHA))


AND = REQ["android"]


def facts(name):
    return axml.manifest_facts((FIX / name).read_bytes())


def sig(name):
    return apk.parse_signature((FIX / name).read_text())


class AndroidGate(unittest.TestCase):
    def test_manifest_reader(self):
        self.assertEqual(facts("full_release.axml"), {"package": "com.hotatticgames.mymedievallife.dev", "versionCode": 42,
                                                      "versionName": "0.1.42-test", "debuggable": False, "testOnly": False,
                                                      "minSdk": 24, "targetSdk": 36})
        self.assertTrue(facts("full_debug.axml")["debuggable"])
        self.assertEqual(facts("demo_release.axml")["package"], "com.hotatticgames.mymedievallife.dev.demo")
        self.assertEqual(facts("template_release.axml")["package"], "com.godot.game")
        with self.assertRaises(axml.AxmlError):
            axml.manifest_facts(b"<manifest package='x'/>")

    def test_production_packages_pass(self):
        self.assertEqual(apk.check(facts("full_release.axml"), sig("sig_release_key.txt"), "full", 42, AND), [])
        self.assertEqual(apk.check(facts("demo_release.axml"), sig("sig_release_key.txt"), "demo", 42, AND), [])

    def test_debuggable_package_fails(self):
        p = apk.check(facts("full_debug.axml"), sig("sig_release_key.txt"), "full", 42, AND)
        self.assertEqual(len(p), 1)
        self.assertIn("android:debuggable is true", p[0])

    def test_wrong_package_id_fails(self):
        self.assertTrue(any("package id" in p for p in apk.check(facts("demo_release.axml"), sig("sig_release_key.txt"), "full", 42, AND)))
        self.assertTrue(any("package id" in p for p in apk.check(facts("full_release.axml"), sig("sig_release_key.txt"), "demo", 42, AND)))
        p = apk.check(facts("template_release.axml"), sig("sig_release_key.txt"), "full", 42, AND)
        self.assertTrue(any("com.godot.game" in x for x in p) and any("versionCode is 1" in x for x in p))

    def test_version_code_must_be_the_build_number(self):
        p = apk.check(facts("full_release.axml"), sig("sig_release_key.txt"), "full", 43, AND)
        self.assertIn("versionCode is 42, not the build number 43", p)
        self.assertIn("versionName is 0.1.42-test, not 0.1.43-test", p)

    def test_other_certificate_fails(self):
        p = apk.check(facts("full_release.axml"), sig("sig_other_key.txt"), "full", 42, AND)
        self.assertEqual(len(p), 1)
        self.assertIn("not the permanent release certificate", p[0])

    def test_two_signers_unverified_or_v1_only_fail(self):
        self.assertTrue(apk.check(facts("full_release.axml"), sig("sig_two_signers.txt"), "full", 42, AND))
        p = apk.check(facts("full_release.axml"), sig("sig_not_verified.txt"), "full", 42, AND)
        self.assertIn("the signature does not verify (apksigner verify)", p)
        self.assertTrue(any("v2/v3" in x for x in apk.check(facts("full_release.axml"), sig("sig_v1_only.txt"), "full", 42, AND)))

    def test_cli(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self._cli()
        self.assertIn("::error::full_debug.axml: android:debuggable is true", out.getvalue())

    def _cli(self):
        args = ["--manifest", str(FIX / "full_release.axml"), "--signature-text", str(FIX / "sig_release_key.txt"), "--edition", "full"]
        self.assertEqual(apk.main(args + ["--build-number", "42"]), 0)
        self.assertEqual(apk.main(args + ["--build-number", "41"]), 1)
        self.assertEqual(apk.main(["--manifest", str(FIX / "full_debug.axml"), "--signature-text", str(FIX / "sig_release_key.txt"),
                                   "--edition", "full", "--build-number", "42"]), 1)

    def test_known_certificate(self):
        self.assertEqual(AND["certificate_sha256"], "31704b8025a4585cf4119e268ee6c8b30d5a39d1c62cdc00eecf0b7e76cb80e6")
        self.assertEqual(AND["editions"]["full"]["package"], "com.hotatticgames.mymedievallife.dev")
        self.assertEqual(AND["editions"]["demo"]["package"], "com.hotatticgames.mymedievallife.dev.demo")


def gh_expr(expr, inputs, ref="refs/heads/wip/x", run_id="77"):
    """Evaluate the small GitHub expression subset tests.yml's concurrency uses (&&, ||, ==, !=, '', null, format, inputs.*)."""
    py = expr.strip()
    py = re.sub(r"^\$\{\{|\}\}$", "", py)
    py = py.replace("&&", " and ").replace("||", " or ").replace("null", "None")
    py = re.sub(r"inputs\.(\w+)", r"inputs.get('\1')", py)
    py = py.replace("github.ref", repr(ref)).replace("github.run_id", repr(run_id))
    return eval(py, {"format": lambda f, *a: f.replace("{0}", str(a[0])), "inputs": inputs})


class TestsConcurrency(unittest.TestCase):
    """B42-Q-RELEASE-TESTS item 2: a release's verification run and other Tests runs never cancel each other."""
    wf = (ROOT / ".github" / "workflows" / "tests.yml").read_text()
    group = re.search(r"(?m)^concurrency:\n(?:  #.*\n)*  group: (.*)$", wf).group(1)
    cancel = re.search(r"(?m)^  cancel-in-progress: (.*)$", wf).group(1)

    def ctx(self, **inputs):
        return gh_expr(self.group, inputs), gh_expr(self.cancel, inputs)

    def test_push_runs_still_supersede_each_other(self):
        self.assertEqual(self.ctx(), ("tests-refs/heads/wip/x", True))         # a push: no inputs at all
        self.assertEqual(self.ctx(only="", group="", release_sha=""), ("tests-refs/heads/wip/x", True))

    def test_release_run_has_its_own_group_and_cancels_nothing(self):
        g, c = self.ctx(only="", group="", release_sha=SHA)
        self.assertEqual((g, c), ("tests-release-" + SHA, False))
        self.assertNotEqual(g, self.ctx()[0], "a push's run and the release's run are in different groups")
        self.assertNotEqual(g, self.ctx(release_sha="e" * 40)[0], "two commits' release runs never share a group")

    def test_targeted_runs_unchanged(self):
        self.assertEqual(self.ctx(only="res://tests/x.gd", release_sha="")[0], "tests-only-77")

    def test_release_run_refuses_another_commit(self):
        self.assertIn('if [ "$RELEASE_SHA" != "$GITHUB_SHA" ]', self.wf)
        self.assertIn("inputs[release_sha]=", (ROOT / "tools" / "release_evidence.py").read_text())


class ReleaseWorkflow(unittest.TestCase):
    """release.yml carries the gates tools/release_requirements.json defines, and no way around them."""
    wf = (ROOT / ".github" / "workflows" / "release.yml").read_text()

    def job(self, name):
        m = re.search(r"(?ms)^  %s:\n(.*?)(?=^  [a-z][\w-]*:\n|\Z)" % re.escape(name), self.wf)
        self.assertIsNotNone(m, name)
        return m.group(1)

    def test_android_is_a_release_export(self):
        self.assertNotRegex(self.wf, r"godot [^\n]*--export-debug", "no package is exported with Godot's debug template")
        self.assertIn('--export-release "Android${PRESET_SUFFIX}"', self.wf)
        self.assertIn("tools/check_android_apk.py", self.job("package"))
        self.assertIn("tools/check_android_apk.py", self.job("release"))

    def test_release_needs_every_mandatory_job(self):
        needs = re.search(r"needs: \[([^\]]+)\]", self.job("release")).group(1)
        have = {x.strip() for x in needs.split(",")}
        want = {k for k in REQ["release_jobs"] if not k.startswith("_")}
        self.assertEqual(have, want)
        for k in want:
            self.assertIn(k + ":", self.wf.split("\njobs:\n", 1)[1])

    def test_release_job_checks_needs_and_evidence(self):
        rel = self.job("release")
        self.assertIn("release_evidence.py needs", rel)
        self.assertIn("toJSON(needs)", rel)
        self.assertIn("release_evidence.py tests", self.job("tests-evidence"))

    def test_no_bypass_inputs(self):
        inputs = re.search(r"(?ms)^    inputs:\n(.*?)^permissions:", self.wf).group(1)
        names = re.findall(r"(?m)^      ([a-z_]+):$", inputs)
        self.assertEqual(sorted(names), sorted(["visibility", "confirm_public", "build_number", "reuse_gate_run", "tests_when_missing"]))
        self.assertNotRegex(self.wf, r"(?i)skip_tests|bypass|force_release")

    def test_signing_secrets_untouched(self):
        for s in ["ANDROID_RELEASE_KEYSTORE_BASE64", "ANDROID_RELEASE_KEYSTORE_PASSWORD", "ANDROID_RELEASE_KEY_ALIAS", "ANDROID_RELEASE_KEY_PASSWORD"]:
            self.assertIn("secrets." + s, self.wf)
        self.assertNotIn("debug_keystore_pass", self.wf, "the release key is not handed to Godot as a debug keystore any more")


if __name__ == "__main__":
    unittest.main()
