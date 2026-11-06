# Owner directive, 2026-11-06 (night, EST): complete current validation, preserve work, then hold

Verbatim, as received.

---

MY MEDIEVAL LIFE — COMPLETE CURRENT VALIDATION, PRESERVE WORK, THEN HOLD

Owner directive — November 6, 2026

My Medieval Life is approaching the end of its current validation cycle. Once the work described below is complete, enter a development hold until I explicitly authorize further work.

This is not permission to skip testing, overlook defects, or prematurely declare Play Test Build One complete.

1. Finish the existing validation

Allow all currently running GitHub Actions workflows to finish without interruption, including:

- 365-day campaign: "42297637074"
- Original campaign: "42274347279", if still active
- Any existing validation or packaging workflows

Do not cancel or restart them.

Do not keep a Claude agent continuously running just to watch GitHub Actions. The workflows can complete independently.

When results are available, inspect the actual logs and artifacts.

For the 365-day campaign, verify:

- Both seeds completed all 365 days.
- Script errors and their causes.
- Coin and item conservation.
- Deterministic agreement between twin runs.
- Save/load round-trip integrity.
- Villager plans, carts, cargo, and work reservations.
- The previously discovered homestead water defect does not recur.
- Any other simulation failures or unexpected differences.

Do not report success based solely on green workflow status.

2. Investigate actual failures

If a test or simulation fails:

- Identify the precise failure.
- Preserve the logs and evidence.
- Determine whether it is a game defect, test defect, infrastructure issue, or expected baseline difference.
- Document the root cause and recommended correction.

Do not automatically change game code, weaken tests, regenerate baselines, or launch another major development cycle.

If a genuine game defect requires repair, report it for my decision before beginning substantial new work.

3. Prepare the Generation 8 baseline decision

Once the campaign finishes:

- Compare the Generation 8 results against the existing accepted baseline.
- Explain every material difference.
- Distinguish approved world-generation changes from unexplained behavior.
- Prepare the replacement baseline as a candidate only.
- Preserve the original baseline and its history.
- Provide the exact simulation evidence and commit SHAs.

STOP before promoting or accepting the Generation 8 baseline.

My previous authorization was conditional. Final approval remains mine.

4. Preserve the Play Test Build One candidate

Current candidate: "1f2ff4f"
Branch: "wip/b25r2-playtest"

The existing Windows artifact remains authorized for provisional personal testing:

https://github.com/verbal76/My-Medieval-Life/actions/runs/42297641550/artifacts/13542782040

Do not alter, replace, or invalidate that artifact.

The next approved package should display:

0.1.34 Rev 2 — Playtest 1

Do not rebuild solely to update the version label during this hold.

The eventual private draft release remains authorized only after all required validation conditions are satisfied, including my explicit Generation 8 baseline approval.

No public release or Steam upload is authorized.

5. Preserve all work and documentation

Before stopping:

- Commit and push completed work to the appropriate branches.
- Preserve any uncommitted or unfinished work in a recoverable checkpoint.
- Document what changed, why, and how it was verified.
- Record all relevant commit SHAs, workflow IDs, artifact locations, and outstanding decisions.
- Preserve the complete testing audit, including the corrected count of 12 testing defects and 10 coverage gaps.
- Keep all eight open coverage gaps visible.
- Record the test-only "door_exit_test" at "7971720" for the next validation cycle.
- Do not silently mark unverified requirements as complete.

Ensure the next Claude session can resume directly from the GitHub records without requiring another handoff document from me.

6. Final report

Once the available validation results have been reviewed, provide:

1. Timestamp in Eastern Time.
2. Exact candidate branch and SHA.
3. Status of both 365-day campaigns.
4. Test results with actual counts.
5. All genuine defects and unresolved findings.
6. Generation 8 baseline comparison and recommendation.
7. Existing Windows playtest artifact location.
8. Remaining steps before the officially validated private Play Test Build One release.
9. Documentation commits and recovery locations.
10. Confirmation that all work is safely preserved.

7. Enter development hold

After completing the current validation review and documentation:

- Stop active development.
- Stop background Claude agents and watchers.
- Do not start new features or investigations.
- Do not launch additional workflows.
- Do not repeatedly poll GitHub.
- Do not promote the baseline.
- Do not publish a release.

If GitHub Actions is still running when the session needs to stop, preserve its run ID and stop anyway. Do not consume Claude usage waiting for it.

The stopping point is the Generation 8 baseline decision.

Once the evidence is ready, report it and wait for my approval.

Our objective is to finish the current validation responsibly, preserve every bit of work, and conserve Claude usage until I authorize the next step.
