# Owner directive, 2026-10-23: requirements recovery, reconciliation and Builds 18-21 status audit

Saved verbatim (register: REQ-CTRL-02).

---

MY MEDIEVAL LIFE — REQUIREMENTS RECOVERY, RECONCILIATION AND BUILDS 18–21 STATUS AUDIT

OWNER DIRECTIVE

Your investigation has identified:

- 99 remote branches.
- 87 branches containing requirements-register copies.
- Approximately 40 distinct register versions.
- Owner directives that exist on development branches but not staging.
- Requirement IDs appearing in documents outside the central register.
- Historical evidence stored in inconsistent fields.

This raises legitimate concerns about the accuracy of our development tracking and previous completion estimates.

Continue the investigation and complete the necessary requirements-management corrections, but preserve every owner decision and all historical evidence.

The objective is to establish one reliable, auditable source of truth for Builds 18, 19, 20, and 21.

This is a requirements-management and reporting task, not authorization to modify gameplay or expand build scope.

1. Complete the reconciliation safely

Finish comparing all relevant register versions and associated requirements documents.

Use the existing register tooling wherever practical.

Before applying the migration:

- Perform a complete dry run.
- Preserve immutable copies of the source records.
- Record each requirement's original branch, document, and identifier.
- Identify duplicates and superseded records.
- Identify conflicting decisions.
- Identify requirements missing from the current authoritative register.
- Identify missing or broken evidence references.
- Identify requirements that have code but incomplete tracking records.

Do not silently discard records.

Do not assume that the newest commit contains the newest owner decision.

Do not assume an older branch's requirement remains active.

Explicit owner decisions take precedence over inferred intent, but contradictory or ambiguous owner decisions must be flagged rather than automatically reconciled.

2. Migration safeguards

The version 2 register must preserve:

- Requirement IDs.
- Original descriptions.
- Build assignments.
- Approval status.
- Supersession relationships.
- Decision history.
- Implementation evidence.
- Test evidence.
- Branch and commit provenance.
- Outstanding dependencies.
- Owner questions.

Do not assign new IDs to existing requirements unless absolutely necessary.

Do not reactivate superseded requirements.

Do not mark unapproved proposals as approved.

Do not change Build 18's combined scope.

Do not automatically move requirements between Builds 18–21.

Keep unassigned future requirements in a separate backlog.

Ensure the migration is repeatable and does not create duplicates when run again.

Validate that every source record is accounted for as migrated, superseded, duplicated, conflicting, or intentionally excluded with an explanation.

3. Protect active development

Other workers are actively implementing Build 18 features.

Do not interrupt them unnecessarily.

Do not modify their working branches or uncommitted files.

Perform register consolidation in an isolated working branch or worktree.

Do not overwrite staging documents while other workers are using them.

If an operation could create a merge conflict or affect active development, stage the changes separately and report the dependency.

Do not merge the reconciliation until validation is complete.

4. Verify the migration

After the dry run, report:

- Total source records discovered.
- Unique requirement IDs.
- Exact duplicates.
- Superseded requirements.
- Conflicting requirements.
- Missing requirements recovered.
- Records with incomplete provenance.
- Records with missing implementation evidence.
- Records with missing test evidence.
- Unresolved owner decisions.

Check that the migration preserves all source records and decision history.

Validate references across branches without treating legitimate branch-specific files as missing.

If the dry run is clean, apply the migration to the isolated working branch and run the relevant register validators.

Do not run unrelated gameplay test suites.

If unresolved conflicts could alter the authoritative requirements, preserve them for owner review rather than choosing an answer.

5. Identify previously unaccounted-for work

This is particularly important.

For Builds 18, 19, 20, and 21, identify every requirement that was absent from or incorrectly represented in the previous authoritative register.

Classify each recovered requirement as:

- Already completed but not tracked.
- Partially implemented but not tracked.
- Approved and still outstanding.
- Awaiting an owner decision.
- Superseded or canceled.
- Unapproved proposal.
- Duplicate of an existing requirement.

Provide exact counts by build.

Explain whether the newly recovered requirements increase or decrease the amount of remaining work.

Do not assume every recovered record represents additional development.

6. Recalculate actual completion

Using the reconciled register and current repository evidence, prepare an updated report for Builds 18–21.

Measure separately:

Design completeness: Approved requirements with sufficient settled decisions to implement.

Implementation completeness: Approved functionality actually implemented in code.

Integration completeness: Functionality integrated into the correct build and supported by applicable evidence.

Playable completeness: Functionality usable by a player through normal gameplay.

Release readiness: Remaining work required to produce a complete, validated playable release.

Do not count a feature as complete solely because it has a passing unit test.

Do not count code on a worker branch as integrated.

Do not count documentation as implementation.

Do not invent percentages when the evidence is insufficient.

Provide requirement counts alongside percentages and explain the calculation.

7. Build-by-build status

Produce a comparison table:

Measurement| Build 18| Build 19| Build 20| Build 21
Approved requirements| | | | 
Completed implementation| | | | 
Partially implemented| | | | 
Not started| | | | 
Integrated and verified| | | | 
Player-verified| | | | 
Open owner decisions| | | | 
Release blockers| | | | 
Remaining effort| | | | 
Current readiness| | | | 

Clearly distinguish planned, authorized, in-development, integrated, playable, and release-ready states.

If Builds 20 or 21 are not yet authorized for implementation, state that prominently.

Do not count infrastructure inherited from earlier builds as completed later-build requirements without direct evidence.

8. Complete open-item register

For every outstanding requirement, provide:

- Requirement ID.
- Assigned build.
- Description.
- Approval status.
- Current implementation status.
- Branch or commit containing relevant code.
- Remaining work.
- Blocking dependencies.
- Owner decision required, if any.
- Estimated effort category.

Use XS, S, M, L, and XL effort categories.

Do not invent calendar deadlines.

Separate work that is blocked from approved work that can proceed immediately.

9. Owner decision audit

Identify all outstanding owner decisions, including those recovered from older branches.

For each decision, explain:

- Exact question.
- Original context.
- Current approved direction, if any.
- Affected build.
- Blocked functionality.
- Whether development can continue independently.
- Whether the decision is genuinely necessary or merely an engineering choice.

Do not reopen previously answered questions unless new evidence reveals a material problem.

Remember the standing design philosophy:

Owner decisions are the best starting specifications based on available information, not immutable rules.

If testing reveals an unforeseen consequence, identify it and recommend an adjustment.

Do not independently change major gameplay intentions.

Do not defend an earlier decision merely because it was previously approved.

10. Development pipeline

Report all active workstreams, their branches, and current status.

Identify:

- Work in progress.
- Work awaiting integration.
- Work awaiting tests.
- Work awaiting owner playtesting.
- Work blocked by missing requirements.
- Work blocked by owner decisions.
- Approved work ready to begin.

Do not start additional workers during this audit.

Do not duplicate work already being performed.

11. Final management report

Conclude with a plain-English executive summary answering:

1. How many requirements were missing or incorrectly tracked?
2. How many were genuinely new outstanding obligations?
3. How many were already implemented but unrecognized?
4. How many conflicting owner decisions remain?
5. Were previous Build 18 completion estimates materially inaccurate?
6. What is the actual remaining work for Build 18?
7. How much of Build 19 is designed versus implemented?
8. Are Builds 20 and 21 real implementation projects yet, or still design-stage?
9. What are the five largest bottlenecks?
10. What are the five highest-value approved tasks that can proceed without additional owner input?

Include a before-and-after comparison of the old completion estimate versus the reconciled estimate, where evidence permits.

If the estimates cannot be compared reliably, explain why.

12. Completion and handoff

When finished:

- Save the reconciled register on the isolated branch.
- Save the migration and validation evidence.
- Generate readable Build 18, 19, 20, and 21 status reports.
- Identify unresolved conflicts requiring owner review.
- Provide the branch and commit references.
- Recommend the next safe integration step.

Do not merge conflicting requirements or change gameplay code.

Do not publish a new game build as part of this task.

Follow MSW-01. Reuse existing evidence and avoid unnecessary test campaigns.

The objective is not to make our completion percentages look better. It is to establish exactly what we approved, what we built, what actually works, and what remains.

I want to know whether Build 18 is genuinely close to completion or whether our previous tracking overlooked substantial unfinished work.

Finish the reconciliation, preserve the history, and give me the evidence-based answer.
