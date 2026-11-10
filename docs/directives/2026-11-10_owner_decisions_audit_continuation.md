# Owner directive, 2026-11-10: Owner decisions, audit continuation and validation

Received 2026-11-10 about 05:35 UTC (00:35 EST) in the lead session. Saved verbatim below; never edited. Register ids:
B25-INV02-SPOIL-D1, B25-MP03-TABLES-D1, B25-DISK-CLEAN-D1, B25-SELFTRADE-VAL-01, B25-AUDIT-CONT-01.

---

MY MEDIEVAL LIFE — BUILD 25
Owner Decisions, Audit Continuation & Validation Directive
Date: November 10, 2026
Project: My Medieval Life — Build 25
Priority: Complete the existing audit and validation work before introducing additional gameplay changes.
1. INV-02 — Food Spoilage
OWNER DECISION: APPROVED IN PRINCIPLE, INVESTIGATE BEFORE IMPLEMENTATION.
Food stored in inventories, homestead chests, business storage, courier storage, and other containers should eventually spoil where appropriate.
However, storage conditions must influence preservation.
Requirements:

* Investigate existing food preservation, consumption, storage, and spoilage mechanics.
* Distinguish perishable foods from shelf-stable foods.
* Evaluate differences between exposed inventory, household storage, commercial storage, and courier transportation.
* Preserve realistic food behavior without excessive micromanagement.
* Consider how spoilage affects hunger, trade, food supply, household survival, and the regional economy.
* Test long-term economic and survival consequences before enabling the mechanic.

Do not introduce spoilage into the currently running Build 25 validation campaign.
Prepare a proposed implementation with expected impacts and testing requirements. Request approval for any unresolved gameplay design decisions before implementation.
2. MP-03 — Public Table Permissions
OWNER DECISION: APPROVED.
Multiplayer guests may interact with genuinely public tables when the tables are accessible and within the permitted interaction range.
Requirements:

* Preserve the validated MP-03 restrictions protecting private packs, chests, and other inventories.
* Public tables must not provide indirect access to private household, business, or player-owned storage.
* Verify ownership, accessibility, permissions, and proximity.
* Test authorized and unauthorized interactions.
* Test multiplayer reconnects and guest state transitions.
* Preserve existing save and network behavior.

Implement separately from the existing MP-03 security correction and run focused regression tests.
Do not reintroduce the blanket MP-06 restriction that broke `net_c_test`.
3. Disk Cleanup — Authorized
OWNER DECISION: APPROVED FOR VERIFIED SAFE CLEANUP.
Available disk space is approximately 310 MB, with roughly 5.2 GB in scratchpad storage.
Proceed as follows:

1. Inventory scratchpad files, temporary test outputs, cached builds, worktrees, and duplicate packages.
2. Identify which files are reproducible or safely disposable.
3. Confirm that packages claimed to exist on GitHub are actually present, complete, and retrievable.
4. Preserve unique evidence, logs, uncommitted work, and anything required by running processes.
5. Clean only verified disposable files.
6. Report the amount of disk space recovered and anything deliberately retained.

Do not delete uncommitted worktrees or unique evidence.
Disk cleanup should not interfere with active GitHub Actions workflows or local development.
4. Self-Trade Defect — Complete the Investigation
The seed-1 campaign identified a real defect involving a household food seller being selected as the payer for a dependent's meal.
The resulting self-trade was refused repeatedly, producing approximately 1,262 failed attempts in one day.
The correction at `b57261f` prevents the payer from being the seller.
Additional validation required:

* Verify that the hungry villager successfully finds another legitimate food source when one exists.
* Verify that the villager does not enter another rapid retry loop when no legitimate food source exists.
* Verify that household funds and inventory remain conserved.
* Test dependent children, food sellers, penniless households, and households with multiple potential payers.
* Confirm the fix does not create starvation, trading, or household-planning regressions.
* Inspect the next 365-day campaign for recurrence of the original HIGH findings.

Do not consider this defect fully resolved merely because the self-trade is prevented.
5. Existing CI and Merge Sequence
Continue the current work without unnecessary restarts.
KI-09

* Monitor Tests run `42758089184`.
* Verify the exact tested commit.
* Advance the development line to `167b235` only after the required tests pass.

MP-03 / TRD-05

* Preserve the validated MP-03 changes at `0acded4`.
* Merge MP-03 and TRD-05 according to the existing dependency plan.
* Run the required multiplayer and integration checks.

Batch 3

* Gate: `42760288204`
* Recorded 365-day campaign: `42760291468`
* Strict Tests: `42760294917`
* Candidate: `wip/b25-audit-sim3`, commit `b57261f`

Inspect actual workflow results and artifacts.
Do not assume success based on workflow completion alone.
Do not merge Batch 3 until its required validation passes and the food-purchase retry behavior is adequately investigated.
6. Governance and Documentation
Follow established Hot Attic Games development rules:

* GitHub Actions and its artifacts are the authoritative evidence for CI validation.
* Match every validation result to its exact commit SHA.
* Investigate unexplained failures before modifying code or baselines.
* Never change a simulation baseline simply to make tests pass.
* Preserve the distinction between verified findings and hypotheses.
* Document what changed, why it changed, and what evidence supports the change.
* Do not advance development stages without the required approval.
* Report progress using completed and outstanding counts rather than percentages.
* Include Eastern timestamps in development reports.

7. Final Reporting
Provide a concise status report covering:

1. KI-09 validation and merge status.
2. MP-03/TRD-05 merge and regression results.
3. Batch 3 validation and campaign findings.
4. Self-trade defect resolution and food-access behavior.
5. Disk space recovered.
6. INV-02 investigation and proposed implementation.
7. Public-table permission implementation and test results.
8. Remaining defects, blockers, and owner decisions.

Standing directive: Anything unresolved is a reason to investigate. Do not confuse a passing test with proof that every related gameplay behavior is correct.
Continue approved work autonomously within these boundaries. Escalate unresolved gameplay design choices, destructive actions outside the approved cleanup scope, and release decisions for owner approval.
