# Owner directive, 2026-11-06 (late night, EST): finish remaining tests, save everything, then stop

Verbatim, as received.

---

MML — FINISH REMAINING TESTS, SAVE EVERYTHING, THEN STOP

Owner directive — November 6, 2026

You are authorized to finish the six drawing/stutter validation suites already in progress following the container restart.

Complete these six suites only:

1. "road_wear"
2. "tree"
3. "underground_ext"
4. "water"
5. "world"
6. "start"

The other eight suites have already passed with 758 checks, zero failures, and zero script errors. Preserve those results.

After the six suites finish

1. Record the results of all 14 suites, including check counts, failures, script errors, and exact commit SHA tested.
2. If a test fails, investigate sufficiently to identify and document the failure, but do not begin another development or repair cycle.
3. Commit and push all completed code, tests, documentation, and findings.
4. Verify the commits exist on the remote GitHub branch.
5. Preserve any unfinished work in a recoverable checkpoint. Do not discard anything.
6. Update the permanent project handoff and decision records, including what was done, why, what was verified, and what remains.
7. Record the current status and run IDs of any outstanding GitHub Actions workflows. Allow them to continue independently without waiting or polling.

Preserve Monday's recovery point

Document the following clearly:

- Current branch and latest pushed SHA.
- Results of all 14 drawing suites.
- Status of the stutter fix and any remaining performance issues.
- Status of the 365-day simulations and their evidence.
- Generation 8 baseline comparison status.
- All unresolved defects and coverage gaps.
- Play Test Build One package and release status.
- Exact next steps for Monday, in priority order.

Do not promote or replace the Generation 8 baseline. That decision remains mine.

Mandatory stopping point

Once the six suites finish and all results and work are safely preserved:

STOP ALL CLAUDE DEVELOPMENT ACTIVITY.

Do not:

- Start another test campaign.
- Launch additional GitHub Actions workflows.
- Begin new features, fixes, or optimizations.
- Continue investigating unrelated issues.
- Start background agents or watchers.
- Rebuild packages.
- Publish or promote a release.
- Continue polling GitHub.

Existing GitHub Actions workflows may finish independently.

Final response before stopping

Give me one concise handoff report with the timestamp, exact saved commit SHA, all 14 suite results, unresolved issues, and Monday's next steps.

Confirm that everything is committed, pushed, and recoverable.

Then stop. No further work until I explicitly authorize it on Monday.

This instruction supersedes any earlier direction to continue automatically.
