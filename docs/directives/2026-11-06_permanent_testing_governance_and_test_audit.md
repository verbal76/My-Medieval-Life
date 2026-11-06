MY MEDIEVAL LIFE — PERMANENT TESTING GOVERNANCE DIRECTIVE & FULL TEST REGIMEN AUDIT

Date: November 6, 2026
Repository: "verbal76/My-Medieval-Life"
Priority: High — execute alongside current Play Test Build One validation
Execution: One development agent; GitHub Actions parallel testing permitted
Scope: Entire existing testing and validation infrastructure

PART 1 — PERMANENT DIRECTIVE: VERIFY THE TEST ITSELF

Effective immediately, a failed test is not automatically evidence of defective game code.

A failed test establishes only that observed behavior did not satisfy a particular assertion, comparison, threshold, or execution requirement.

Before changing game code, test code, or recorded baselines, determine whether the test correctly measures the intended behavior.

1. Mandatory failure classification

Classify every failure using verified evidence:

A. Genuine game defect

- Game behavior violates an approved rule or requirement.
- State, resources, or progress are incorrectly lost or created.
- A system fails under valid gameplay conditions.
- A save/load operation changes state incorrectly.
- Simulation determinism is violated without an approved explanation.

B. Incorrect or outdated test expectation

- The test expects behavior from an older implementation.
- The expected result conflicts with an approved design change.
- The assertion measures an implementation detail rather than the required behavior.
- The test incorrectly assumes a particular entity, cell, order, or state.

C. Defective test procedure

- Incorrect setup or fixture.
- Wrong test target or environment.
- Invalid assumptions about game state.
- Missing prerequisites.
- Incorrect comparison logic.
- Test fails to exercise the intended code path.
- Test silently skips assertions.
- Test reports success after a script error or premature termination.

D. Testing infrastructure failure

- Runner timeout.
- Resource exhaustion.
- Incorrect CI configuration.
- Missing dependency or artifact.
- Environmental inconsistency.
- Broken workflow orchestration.
- Test results incorrectly collected or reported.

E. Legitimate simulation or version evolution

- An approved game change produces different but valid results.
- World-generation versions require different expectations.
- A baseline represents an earlier approved configuration.
- Simulation outputs legitimately differ because the underlying rules changed.

Do not assign a category based on guesswork.

A failure may have multiple contributing causes. Record each cause separately.

If the cause remains unknown, classify it as UNRESOLVED and continue investigating.

2. Mandatory three-part verification

For every failure, answer:

Question 1: Is the game behaving correctly?

Compare observed behavior with the approved game rules, requirements, and intended player experience.

Question 2: Is the test itself correct?

Examine setup, fixtures, assertions, execution paths, coverage, and reporting.

Verify that the test actually exercises the intended behavior.

Question 3: Is the baseline or expectation applicable?

Verify compatibility with the current world-generation version, save format, simulation rules, configuration, and intended behavior.

Do not assume the newest baseline is automatically correct.

3. Correction rules

If the game is wrong, fix the game.

If the test is wrong, fix the test.

If both are wrong, fix both.

If infrastructure is wrong, repair the infrastructure and rerun the affected validation.

If a baseline is outdated, establish the approved behavioral reason before proposing a baseline update.

Never automatically re-record a baseline to obtain a passing result.

Do not weaken assertions, widen tolerances, remove checks, or exclude failing seeds simply to make CI green.

Any legitimate change to acceptance criteria must be justified and documented.

Where practical, demonstrate that the corrected test detects the original defect and passes the repaired implementation.

4. Permanent documentation

Record this directive in the repository's governance documentation and reference it from "CLAUDE.md".

Document:

- Why the directive exists.
- How failures must be classified.
- Required investigation steps.
- Evidence required before corrections.
- Baseline-change authorization rules.
- Regression requirements.
- Reporting requirements.

This directive must survive future conversations and agent handoffs.

---

PART 2 — COMPLETE AUDIT OF THE CURRENT TESTING REGIMEN

This is a comprehensive audit of the project's existing testing architecture.

Do not limit the audit to the currently running CI jobs, currently failing tests, or the five Play Test Build One repairs.

Audit every existing testing mechanism that contributes to confidence in the game.

The objective is to establish whether the testing regimen is accurate, complete, meaningful, reproducible, efficient, and capable of detecting real defects.

5. Inventory every test and validation system

Discover and catalog:

- Every automated test file and suite.
- Every GitHub Actions testing workflow.
- Every long-running simulation campaign.
- Every simulation acceptance gate.
- Every deterministic replay test.
- Every golden baseline and fingerprint.
- Every save/load and migration test.
- Every world-generation and geography test.
- Every economy, inventory, employment, and business test.
- Every NPC behavior and social simulation test.
- Every travel, roads, bridges, and regional movement test.
- Every controller and user-interface test.
- Every multiplayer and networking test.
- Every performance benchmark and threshold.
- Every Windows build and smoke test.
- Every release qualification procedure.
- Every manual verification requirement.

Include tests that are disabled, skipped, obsolete, orphaned, or not currently invoked by CI.

Identify tests that exist but are not executed during normal validation.

Identify workflows that execute the same tests redundantly.

Produce a complete inventory with exact file paths and workflow references.

6. Audit what each test actually verifies

For every test or logically grouped set of tests, establish:

1. What behavior or requirement it claims to verify.
2. What behavior it actually exercises.
3. Whether its fixtures and assumptions are valid.
4. Whether its assertions correctly detect failure.
5. Whether it reaches all required assertions.
6. Whether errors or exceptions can produce false passes.
7. Whether skipped checks are reported accurately.
8. Whether it depends on execution order or shared state.
9. Whether it is deterministic and reproducible.
10. Whether it can detect the defects it is intended to prevent.

Do not assume that a passing test is a useful test.

A test that always passes, cannot reach its assertions, or only checks that a function runs is not sufficient evidence of correct gameplay.

7. Verify tests can actually fail

Use controlled negative tests or mutation testing where practical.

Introduce temporary, isolated defects into a disposable worktree or equivalent test environment.

Examples:

- Incorrectly create or destroy inventory.
- Alter a save/load value.
- Break an NPC state transition.
- Change a deterministic seed result.
- Disable a controller action.
- Corrupt a road connection.
- Change a business transaction.
- Introduce an invalid simulation state.

Verify that the appropriate tests detect the injected defect.

Revert all injected defects afterward.

Never merge intentional defects into production code.

Record which tests successfully detect the mutation and which fail to detect it.

For tests that cannot safely be mutation-tested, explain why and use another suitable validation method.

Prioritize high-risk tests first; do not spend excessive CI resources mutating trivial assertions.

8. Audit the simulation gates

Inspect the complete architecture of the simulation acceptance gates, including the currently failing "SIM-GATE-01".

Verify:

- What each gate measures.
- What its acceptance criteria represent.
- Whether those criteria reflect approved game rules.
- Whether baselines belong to the correct simulation version.
- Whether every comparison uses equivalent starting conditions.
- Whether expected randomness is handled correctly.
- Whether determinism checks are genuinely deterministic.
- Whether legitimate simulation evolution is distinguishable from defects.
- Whether failures identify the actual violated condition.
- Whether individual partitions passing but final evaluation failing is correctly reported.
- Whether the gate can produce false positives or false negatives.

For the current failure, establish the exact violated condition and supporting evidence.

Do not modify the baseline until the cause is established.

9. Audit world-generation version compatibility

Pay particular attention to generations 7 and 8.

Generation 7 represents the existing shipped-world compatibility baseline.

Generation 8 contains the newer bridge and road-generation repairs.

Verify that:

- Generation 7 retains its original expected fingerprints.
- Generation 8 has independently validated expectations.
- Tests never compare generation 8 against generation 7 without an explicit compatibility reason.
- Existing saved worlds remain stable.
- New worlds use the intended generation.
- Save migration and load behavior are correctly verified.
- Geographic differences are not mistaken for unrelated gameplay defects.

Do not overwrite generation 7's evidence to accommodate generation 8.

10. Audit the entire save/load testing system

Investigate whether save/load tests correctly account for:

- Persistent entity state.
- Villager ownership and held items.
- Carts and transportation.
- NPC plans and destinations.
- Business transactions.
- Employment and skill progression.
- Buildings and settlements.
- World-generation versions.
- Relationships and family continuity.
- Economy conservation.
- Simulation timing and replay determinism.

Distinguish intended transient-state reconstruction from unintended state loss.

In particular, investigate the reported behavior where a villager releases a held cart after loading because the villager's plan is not persisted.

Determine whether this is an approved gameplay rule or an actual continuity defect.

Do not classify a difference as acceptable solely because the existing implementation behaves that way.

11. Audit test reporting and CI orchestration

Verify that GitHub Actions accurately reports:

- Total tests discovered.
- Tests actually executed.
- Assertions completed.
- Tests passed.
- Tests failed.
- Tests skipped.
- Script errors and exceptions.
- Timeouts and cancellations.
- Incomplete test shards.
- Missing artifacts.
- Overall pass/fail status.

A test must not report success after aborting prematurely.

A passing workflow must not conceal script errors that invalidate test results.

Differentiate intentional negative-test errors from unexpected runtime errors.

Verify that a cancelled or timed-out shard cannot be counted as a successful full-suite run.

12. Audit test coverage against the actual game

Build a requirements-to-tests coverage map.

Identify:

- Major game systems without meaningful tests.
- Important player actions without regression coverage.
- Systems tested only through unrealistic fixtures.
- Missing interactions between otherwise tested systems.
- Unverified edge cases.
- Areas dependent entirely on manual testing.
- Tests that duplicate coverage without adding meaningful confidence.

Pay particular attention to interactions between:

- Travel and geography.
- Economy and inventory.
- Employment and skills.
- NPC behavior and save/load.
- Families and long-term simulation.
- Controller input and menu state.
- Multiplayer and persistent world state.

A system passing in isolation does not establish that its interactions with other systems are correct.

13. Audit performance and test efficiency

Measure the current testing regimen.

Determine:

- Total full-suite runtime.
- Long-simulation runtime.
- Slowest suites.
- Duplicate execution.
- Tests with excessive setup costs.
- Sources of CI timeouts.
- Opportunities for safe parallel execution.
- Tests that can run as focused preflight checks.
- Tests that must remain full integration checks.

Improve testing efficiency where possible without reducing validation quality.

Preserve exact behavior and coverage when optimizing tests.

Do not change production gameplay merely to make a test run faster unless the production behavior itself is defective or inefficient.

14. Audit release qualification

Determine whether the current testing regimen is sufficient to authorize a Windows playtest package.

Identify which requirements must pass before:

- Creating a build candidate.
- Performing a Windows smoke test.
- Releasing a private playtest.
- Publishing a public release.
- Promoting a production build.

Separate automated verification from physical controller and real-hardware testing.

A green automated suite must not be represented as proof that all real-world hardware behavior has been tested.

---

PART 3 — REQUIRED DELIVERABLES

15. Produce a formal testing audit report

Create a permanent report under "docs/audits/" with an appropriate date-based filename.

Include:

A. Executive findings

- Number of tests and suites inventoried.
- Number of workflows inventoried.
- Number of valid, defective, outdated, skipped, and unverified tests.
- Number of identified false-positive risks.
- Number of identified false-negative risks.
- Number of missing coverage areas.

B. Detailed inventory

For each suite:

- File path.
- Intended purpose.
- Actual behavior verified.
- Current CI coverage.
- Validity assessment.
- Known weaknesses.
- Recommended corrective action.

C. Failure-classification findings

Document each confirmed testing defect and its root cause.

D. Baseline and simulation findings

Identify legitimate differences, outdated expectations, and genuine simulation defects.

E. Coverage gaps

Prioritize by potential gameplay impact.

F. CI efficiency findings

Include measured runtime and optimization opportunities.

G. Corrective action plan

Classify findings as:

- Critical: invalidates release confidence.
- High: significant missing or misleading verification.
- Medium: worthwhile reliability or coverage improvement.
- Low: documentation or minor efficiency improvement.

H. Verification evidence

Reference commit SHAs, GitHub Actions runs, test logs, and reproduction results.

Do not report an item as verified without supporting evidence.

16. Repair confirmed testing defects

You are authorized to repair confirmed defects in the testing infrastructure within the approved scope.

For each repair:

1. Reproduce the problem.
2. Establish the root cause.
3. Demonstrate why the existing test is wrong or incomplete.
4. Implement the correction.
5. Verify the corrected test catches the intended defect.
6. Run the appropriate regression coverage.
7. Record the change and evidence.

Do not modify unrelated gameplay systems solely to satisfy the audit.

If an actual game defect is discovered, investigate it, document its severity, and repair it when it falls within the already approved Play Test Build One scope.

For new gameplay scope or design decisions, request owner authorization.

17. Preserve current validation work

The current Play Test Build One campaign must continue.

Known candidate commit: "832f711"

Known GitHub Actions runs:

- Full regression suite: "42274258964" — passed.
- 365-day campaign: "42274347279" — running at last verification.
- Simulation gate: "42274351589" — final evaluation failed.

These are historical checkpoints. Refresh their statuses before reporting.

Do not cancel or invalidate existing simulation campaigns simply to begin the audit.

Run the audit alongside existing work, using one development agent and existing CI capabilities.

Keep audit changes separate from the playtest candidate until they have been validated and are ready for controlled integration.

Do not replace the Play Test Build One release process with the audit.

18. Completion requirements

The audit is not complete merely because a report has been written.

Completion requires:

- Full test inventory.
- Verified testing architecture.
- Identified false-positive and false-negative risks.
- Confirmed defects repaired or explicitly tracked.
- Baseline rules audited.
- Simulation gates evaluated.
- Coverage gaps documented.
- CI reporting accuracy verified.
- Prioritized corrective-action register.
- Permanent governance directive committed.
- Reproducible evidence for major findings.

If exhaustive mutation testing is impractical, clearly identify what was sampled and what remains unverified. Do not claim universal test validity from partial sampling.

19. Reporting

Report progress using concrete counts, not vague percentages.

Include:

- Eastern timestamp.
- Current commit SHA.
- Suites inventoried / total discovered.
- Suites audited / total.
- Testing defects confirmed.
- Testing defects repaired.
- Coverage gaps identified.
- CI runs and outcomes.
- Unresolved questions.
- Next actions.

Do not interrupt for routine implementation choices.

Investigate unknowns rather than deferring them without examination.

Begin immediately. First establish the current state of the Play Test Build One validation runs, record the permanent directive, and inventory the entire testing system. Then audit and repair the testing regimen systematically.

The objective is not to make every test green.

The objective is to make every green test meaningful and every red test trustworthy.
