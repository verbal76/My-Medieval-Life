# Owner directive, 2026-11-03 (received 2026-11-02 21:28 EST): Build 25 completion (B25-FINISH-01)

Saved verbatim.

---

MY MEDIEVAL LIFE — BUILD 25 COMPLETION DIRECTIVE

Establish the finish line and deliver the playtest

This is an owner directive. Build 25 is entering completion mode.

The objective is to finish all work already approved for Build 25, validate the integrated game, complete a successful 365-day flight recorder simulation, and produce a private playable release.

No new features, expansions, or discretionary improvements are authorized.

Phase 1 — Establish the remaining-work inventory

Inspect the current repository, all active Build 25 branches, work-package registers, decision records, outstanding tests, and GitHub Actions evidence.

Produce a definitive checklist of:

1. All approved Build 25 requirements.
2. The eight approved REGION-NAV-01 stages, S1 through S8.
3. Remaining Living Economy integration and activation requirements.
4. Other previously approved Build 25 expansions and recovered work.
5. Confirmed defects and incomplete acceptance tests.
6. Outstanding merges or integration dependencies.

For every item, report its current status, source branch, relevant commit, remaining work, and acceptance evidence.

This existing approved work becomes the fixed Build 25 finish line.

Do not silently omit, defer, or replace an approved requirement.

Phase 2 — Complete the existing scope

Continue implementation until every approved Build 25 requirement is complete.

Incorporate all confirmed defects discovered by the existing validation agent and test suites.

Do not introduce new features or start unrelated investigations.

The main development session owns integration and final acceptance.

Phase 3 — Final integration testing

Once the complete Build 25 source is assembled:

- Identify the exact integrated source SHA.
- Run all applicable required tests.
- Execute independent test groups in parallel through GitHub Actions.
- Reuse valid existing test evidence where appropriate.
- Correct genuine defects and rerun affected tests.
- Verify saves, migrations, determinism, economy conservation, NPC behavior, journeys, and regional systems.
- Ensure all required suites are registered in CI.

Do not perform redundant full campaigns merely for reassurance.

Phase 4 — 365-day flight recorder acceptance

After the integrated source passes its required tests, run a full 365-day flight recorder simulation against that exact Build 25 candidate, with the approved Living Economy configuration active.

The flight recorder must examine the established simulation KPIs and invariants, including:

- Economic conservation of coins, goods, and resources.
- Household and business survival and transactions.
- Production, employment, founding, and independent crafters.
- Regional travel, trade, courier activity, and envoys.
- NPC mortality, relationships, and continuity.
- Save/load integrity and deterministic behavior.
- Errors, crashes, deadlocks, and simulation stalls.

Use the existing flight recorder instrumentation and acceptance rules. Do not invent new mandatory thresholds.

If the simulation passes cleanly, proceed directly to packaging.

If it reveals a genuine defect:

1. Identify and correct the cause.
2. Run focused regression tests.
3. Re-run the necessary affected validation.
4. Repeat the full 365-day acceptance flight against the corrected final candidate.

An older simulation on an earlier SHA does not substitute for the final integrated acceptance flight.

Phase 5 — Package the Build 25 playtest

When all requirements are complete, all applicable tests pass, and the final 365-day flight recorder succeeds:

Produce playable packages for:

- Android APK
- Windows ZIP
- Linux ZIP

Run the necessary package, export, and launch smoke checks.

Attach the packages, test evidence, simulation report, and source SHA to a private draft GitHub release.

Do not publish publicly.

Reporting and autonomy

Use the approved Pittsburgh-local timestamp format.

Report progress against the fixed completion checklist, showing actual completed items and remaining blockers rather than estimated percentages.

Do not request additional owner approval for routine corrections, validation, integration, or private playtest packaging.

Do not begin Build 26 or expand Build 25.

Definition of done: All previously approved Build 25 work completed, integrated tests passing, final 365-day flight recorder passing, and three verified playable packages available in a private draft GitHub release.

First produce the remaining-work inventory and fixed completion checklist. Then continue implementation automatically.
