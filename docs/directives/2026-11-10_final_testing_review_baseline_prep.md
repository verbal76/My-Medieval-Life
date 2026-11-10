# Owner directive, 2026-11-10: Final testing review and baseline approval preparation

Received 2026-11-10 in the lead session. Saved verbatim below; never edited. Register id B25-FINAL-REVIEW-01 (extends
B25-BASELINE-REVIEW-01).

---

MML Build 25 — Final Testing Review and Baseline Approval Preparation

Claude, continue the Batch 3 + 4 validation on "fbfd6ad".

Objective: Complete the testing investigation and give me everything necessary to make an informed decision about baseline acceptance and merging. Do not merge or accept a new baseline without my explicit approval.

1. Complete the 365-day campaign review

Retrieve and inspect the actual artifacts from GitHub Actions run "42788018729".

Review both seeds for:

- Failed food purchases, self-trade attempts, and retry loops.
- F015: homesteaders starving despite having coins.
- Household food availability and business-stock consumption.
- Inventory, currency, and item conservation.
- Save/load consistency and determinism.
- Script errors, crashes, and any other confirmed defects.

Compare these results against Batch 3's previous campaign.

2. Complete the baseline attribution

Investigate all 33 findings against baseline "df67e8e".

Identify the first commit where each measurement changed, then establish the actual cause rather than assuming that commit itself is responsible.

Pay particular attention to Generation 8 world generation and the increase from 25 to 26 households.

Group the 32 measurement differences by their underlying causes, not simply by seed and checkpoint.

Classify each causal group as:

- Expected: Intentional, verified behavior change.
- Corrected: Legitimate defect fix.
- Defect: Incorrect behavior requiring repair.
- Unexplained: Insufficient evidence; further investigation required.

3. Prepare an owner decision report

Give me a concise but complete report containing:

1. Exact tested commit SHA and GitHub Actions run IDs.
2. Verified results of all 277 test suites.
3. Results from both 365-day campaign seeds.
4. All 33 baseline findings, grouped by cause.
5. Old versus new behavior and supporting evidence.
6. Any actual defects or unresolved questions.
7. Your recommendation for each causal group: ACCEPT, FIX, or INVESTIGATE.
8. Whether Batch 3 + 4 is ready to merge.

Explain the findings in plain English. I need to understand what changed in the game and whether those changes are beneficial, not just see technical measurements.

4. Governance

Do not automatically approve baseline changes.

Do not re-record baselines merely to make tests pass.

Do not weaken tests, conceal failures, or skip validation.

If defects are discovered, investigate and recommend corrections before requesting approval.

Preserve all existing work, documentation, logs, and evidence.

Once the investigation is complete, present the owner decision report and stop at the approval gate.

If everything is verified and correct, I want to be able to approve the baseline and merge in one decision, without unnecessary additional testing or repetitive approval requests.
