# Owner directive, 2026-11-06 (evening, EST): Playtest Build One — owner decisions and authorization

Verbatim, as received.

---

MY MEDIEVAL LIFE — OWNER DECISIONS AND PLAYTEST BUILD ONE AUTHORIZATION

I have reviewed your latest readiness audit and artifact-access report.

These are my decisions. Record them in the permanent decision register, including the reasoning and relevant commit SHAs.

1. Existing Windows artifact — APPROVED FOR IMMEDIATE PERSONAL TESTING

The existing Windows package is available:

https://github.com/verbal76/My-Medieval-Life/actions/runs/42297641550/artifacts/13542782040

Artifact ID: 13542782040
Candidate SHA: 1f2ff4f

I authorize using this existing package for personal testing immediately.

Do not rebuild, modify, replace, or delay access to this artifact.

It is a provisional playtest package, not the final validated Play Test Build One release.

The existing artifact must remain accessible while validation continues.

2. Version identification — APPROVED

Keep the underlying Build 34 designation.

The next package must visibly identify itself as:

0.1.34 Rev 2 — Playtest 1

The existing package may retain its current version label because changing it requires rebuilding.

Apply the corrected label to the next authorized build.

Do not rebuild solely to change the label while the 365-day campaign is running.

3. Private draft release — AUTHORIZED, SUBJECT TO VALIDATION

I authorize publication of Play Test Build One as a private GitHub draft release only, after the required validation gates pass.

This authorization is conditional on:

- The 365-day campaign completing successfully.
- All unexplained simulation differences being investigated.
- The Generation 8 baseline receiving my explicit approval.
- The normal validation gate passing.
- The next package carrying the approved revision label.

Once these conditions are met, you may proceed with the normal private draft release workflow without requesting the same publication approval again.

This does NOT authorize:

- A public GitHub release.
- A Steam release or upload.
- Bypassing or weakening any validation gate.
- Automatically accepting a new simulation baseline.
- Claiming that physical controller testing has passed before I perform it.

If GitHub draft releases cannot provide the intended private access in this public repository, report that limitation and preserve the artifact-access method rather than publishing a visible release.

4. Generation 8 baseline — CONDITIONAL APPROVAL

Complete the 365-day campaign on candidate 1f2ff4f.

After completion:

- Inspect both seeds through day 365.
- Confirm deterministic agreement.
- Verify coin and item conservation.
- Check save/load round trips.
- Investigate script errors and unexplained changes.
- Compare results against the existing baseline.
- Prepare the Generation 8 baseline candidate and full comparison report.
- Preserve the previous baseline and its history.

STOP before promoting the baseline. I will review the evidence and explicitly approve or reject it.

Do not automatically accept a new baseline merely to make the release gate pass.

5. Testing audit — COUNT RECONCILIATION ACCEPTED

The corrected accounting is:

- 12 confirmed testing defects, all repaired.
- 10 coverage gaps, with 8 still open.
- T13 was incorrectly counted as a testing defect because it duplicates coverage gap G2.

Preserve this explanation in the audit documentation.

Do not silently close outstanding coverage gaps.

6. Door-exit test

The test-only commit 7971720 is approved for integration into the next appropriate validation cycle.

It is not a reason to invalidate or rebuild the existing playable artifact.

Ensure the final candidate and its test results are traceable to the exact commit tested.

7. Workload and reporting

Continue the already-running GitHub Actions campaign without interruption.

Conserve Claude usage. Do not launch unnecessary development or repeat completed investigations.

When the campaign finishes, report:

1. Results for both seeds through day 365.
2. All script errors, conservation results, and determinism checks.
3. Baseline differences and whether they are explained.
4. The proposed Generation 8 baseline candidate.
5. Any remaining blockers to the private draft release.
6. The exact candidate SHA and package versions.

Do not promote the baseline until I approve it.

Immediate priority: Preserve access to my existing Windows artifact so I can begin testing tonight.

No public publication is authorized.
