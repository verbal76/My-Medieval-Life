# Owner directive, 2026-10-23: master requirements reconciliation and permanent development control system

Saved verbatim (register: REQ-CTRL-01).

---

MY MEDIEVAL LIFE — MASTER REQUIREMENTS RECONCILIATION AND PERMANENT DEVELOPMENT CONTROL SYSTEM
OWNER DIRECTIVE
We have identified a serious project-management problem in My Medieval Life.
Multiple requirements registers contain different information, some approved requirements are missing from active tracking, development statuses do not always match the code, and previous progress reports have overstated how close builds are to completion.
This needs to be corrected permanently.
Your assignment is to reconcile all existing development records, establish one authoritative requirements system, implement controls to prevent future divergence, and provide an accurate development baseline for Builds 18, 19, 20, and 21.
This is an authorized repository maintenance and project-management implementation task.
Do not stop at recommendations or a proposed plan.
Implement the system, migrate the existing records, validate the results, and report completion.
Apply MSW-01 Minimum Sufficient Work throughout.
1. NONNEGOTIABLE PRINCIPLES
The new system must satisfy the following:

1. No approved requirement is silently lost.
2. No owner decision is silently overwritten.
3. No requirement exists in multiple independently maintained authoritative registers.
4. Every requirement has one stable, unique identifier.
5. Every requirement has a clearly identified build assignment or an explicit unassigned status.
6. Implementation status is separate from testing and playability status.
7. Requirements cannot be declared complete merely because code exists.
8. Every development worker uses the same authoritative information.
9. New owner decisions are incorporated into the master system.
10. Progress reports are generated from the master system, not manually maintained estimates.
11. Unapproved proposals are not treated as approved requirements.
12. Previously approved decisions can be reconsidered when implementation exposes unforeseen problems.
13. Meaningful changes to gameplay design require owner approval.
14. Routine engineering corrections may proceed without unnecessary owner questions.
15. The system must be lightweight enough that maintaining it does not consume more development effort than it saves.

The goal is accurate control of development, not administrative bureaucracy.
2. PROTECT CURRENT DEVELOPMENT
Two Build 18 workers were active during the previous audit:

* Chapel implementation.
* Five settlements and caravan implementation.

Check their current status before making changes.
Do not stop, interrupt, overwrite, or interfere with active development.
Do not modify another worker's working files.
Do not create competing edits to files currently owned by active workers.
Perform the reconciliation on a dedicated branch or isolated worktree.
Use a controlled integration process when the work is complete.
If active workers have already changed requirements or decisions, incorporate their changes rather than replacing them.
Preserve all uncommitted work.
Do not merge gameplay branches as part of this administrative task.
3. DISCOVER EVERY EXISTING SOURCE OF REQUIREMENTS
Inspect the repository and identify all relevant sources, including:

* Main requirements register.
* Build 18 requirements register.
* Build 19 design and implementation records.
* Build 20 planning documents.
* Build 21 planning documents.
* Owner decision registers.
* World Design Rules.
* Expansion plans.
* Development roadmaps.
* Worker handoffs.
* Current session recovery documents.
* Build checklists.
* Release checklists.
* Known defects.
* Deferred requirements.
* Previously approved design decisions.
* Relevant branch-specific records.

Do not limit discovery to documents with "requirements" in their filenames.
Inspect cross-references and historical records where necessary.
Do not treat every brainstorming note as an approved requirement.
Identify the authoritative evidence for each item.
4. RECONCILE THE TWO COMPETING REGISTERS
The previous audit identified:

* 72 entries present in the Build 18 register but missing from the main register.
* 93 entries present in the main register but missing from the Build 18 register.
* Five stonecutter requirements missing from the register used for earlier Build 18 completion calculations.
* Recent owner decisions missing from one of the registers.

These figures are investigation leads, not assumptions about the final number of unique requirements.
Perform a complete comparison.
For every entry:

1. Identify its source.
2. Identify its existing ID.
3. Determine whether it duplicates another requirement.
4. Determine whether it represents a distinct requirement.
5. Identify its intended build.
6. Identify its approval status.
7. Identify its latest owner decision.
8. Identify its implementation status.
9. Identify its dependencies.
10. Preserve its historical references.

Deduplicate by actual meaning, not merely identical wording.
Do not merge distinct requirements simply because they concern the same system.
Do not silently discard superseded requirements.
Preserve superseded entries as historical records linked to their replacements.
If two records genuinely conflict and owner intent cannot be established, flag the conflict for review.
Do not invent an owner decision to resolve ambiguity.
Produce a reconciliation ledger showing:

* Original source.
* Original ID.
* Canonical ID.
* Action taken.
* Reason.
* Supporting evidence.

Every original entry must be accounted for.
5. CREATE ONE AUTHORITATIVE MASTER REQUIREMENTS REGISTER
Establish one canonical, machine-readable requirements register in the repository.
Choose a maintainable format appropriate to the existing development environment, such as YAML or JSON.
Prefer a simple format that can be validated automatically.
The register must support these fields:
Identity

* Canonical requirement ID.
* Short title.
* Full requirement description.
* Relevant game system.
* Source document or owner decision.
* Historical IDs and aliases.

Scope

* Target build.
* Workstream.
* Approval status.
* Requirement type.
* Priority.
* Dependencies.
* Related requirements.

Development

* Implementation status.
* Assigned worker, if any.
* Working branch, if any.
* Relevant commit.
* Code location, if known.
* Remaining implementation work.

Verification

* Integration status.
* Automated test evidence.
* Test commit.
* Gameplay verification status.
* Owner playtest status.
* Platform verification status.
* Known defects.

Release

* Release-blocker classification.
* Acceptance criteria.
* Required validation.
* Final completion status.

History

* Original creation reference.
* Last material update.
* Relevant owner decisions.
* Superseded or replaced requirement links.
* Change history reference.

Do not populate fields with invented values.
Use explicit unknown or unverified values when evidence is unavailable.
Avoid duplicating information that can be reliably derived from another canonical record.
Keep the schema practical rather than unnecessarily complicated.
6. SEPARATE REQUIREMENT STATUS FROM VERIFICATION STATUS
A single status such as "complete" is insufficient.
Use separate status dimensions.
Approval status

* PROPOSED
* OWNER APPROVED
* OWNER DECISION REQUIRED
* DEFERRED
* REJECTED
* SUPERSEDED

Implementation status

* NOT STARTED
* READY
* IN DEVELOPMENT
* IMPLEMENTED ON TASK BRANCH
* INTEGRATED
* IMPLEMENTATION BLOCKED

Verification status

* NOT TESTED
* TARGETED TESTS PASSED
* INTEGRATION VERIFIED
* GAMEPLAY VERIFIED
* OWNER PLAYTESTED
* VERIFICATION FAILED

Release status

* NOT READY
* RELEASE BLOCKED
* RELEASE CANDIDATE
* RELEASE READY
* RELEASED

A requirement may be integrated but not tested.
It may pass automated tests but not be playable through the interface.
It may be owner-playtested but still fail a platform-specific release gate.
The tracking system must represent these distinctions accurately.
Do not automatically promote requirements to completed or verified based solely on a commit, merge, or passing unrelated test.
7. CREATE A CANONICAL OWNER DECISION REGISTER
Owner decisions must be tracked separately from implementation status while remaining linked to affected requirements.
Every decision should record:

* Unique decision ID.
* Exact decision or question.
* Relevant build.
* Affected requirements.
* Date or source reference.
* Current disposition.
* Owner-approved answer, if any.
* Rationale when available.
* Whether implementation is blocked.
* Whether the decision supersedes an earlier decision.

Support:

* OPEN
* APPROVED
* PROVISIONAL
* SUPERSEDED
* REOPENED
* DEFERRED

Do not assume a recommendation is an owner-approved decision.
Do not convert a provisional answer into a final decision.
For example, X19-DECAY must reflect its actual current disposition and the unresolved calendar/reputation question.
Preserve the existing eight-day calendar decision unless the owner explicitly changes it.
However, record that approved design decisions may be revisited when evidence reveals unintended gameplay consequences.
The principle is:
Owner decisions establish design intent, not an obligation to preserve a flawed implementation.
Engineering changes that preserve design intent may proceed.
Meaningful gameplay changes require owner approval.
8. SEPARATE BUILDS 18, 19, 20 AND 21
The master register must distinguish approved scope from proposed future development.
Build 18
Preserve the complete approved combined scope.
Include gameplay, visual improvements, inventory, equipment, character customization, settlement economy, farming, property, contracts, couriers, chapel, stonecutter, and all other approved Build 18 requirements.
Do not split Build 18 or silently defer requirements.
Build 19
Track NPC judgment, reputation, gossip, trust, relationships, and associated approved requirements.
Distinguish the existing switched-off prototype from fully integrated functionality.
Record any implementation rework required by later owner decisions.
Build 20
Track Living Economy proposals and approved decisions.
Build 20 is not authorized for implementation unless subsequent evidence establishes authorization.
Do not count planning documents as completed code.
Build 21
Track Village Politics proposals and approved decisions.
Build 21 is not authorized for implementation unless subsequent evidence establishes authorization.
Do not count existing relationship systems as completed political functionality without specific supporting requirements and evidence.
Future backlog
Maintain a separate category for:

* Unassigned approved requirements.
* Future proposals.
* Deferred features.
* Items designated "Build 20 or later."
* Ideas requiring additional design.

Do not arbitrarily assign future items to Builds 20 or 21.
9. RECONCILE THE REGISTER AGAINST ACTUAL CODE
Once the canonical register is assembled, perform a targeted implementation-evidence audit.
For every requirement currently marked implemented or integrated:

* Verify relevant code exists.
* Identify its branch.
* Identify the supporting commit where practical.
* Determine whether it is merged into the target build.
* Locate applicable existing test evidence.
* Identify known incomplete functionality.
* Identify whether player-facing verification has occurred.

Correct stale statuses.
Examples from the previous audit:

* Couriers were marked in development despite having no active worker.
* Some settlement functionality was marked not started even though code existed.
* Certain requirements were counted as nearly finished despite having no owner playtest.
* A save-import issue was discovered only after integration.

Do not assume that a missing worker means no implementation exists.
Do not assume that existing code means the requirement is complete.
Use the available evidence.
Avoid broad test campaigns.
This is primarily a documentation and evidence-reconciliation task.
10. IMPLEMENT AUTOMATIC VALIDATION
Create a lightweight requirements validation tool using the repository's existing tooling where practical.
The validator must detect:

1. Duplicate canonical IDs.
2. Missing required fields.
3. Invalid status values.
4. References to nonexistent requirements.
5. Broken dependency references.
6. Broken decision references.
7. Invalid build assignments.
8. Missing acceptance criteria for approved implementation work.
9. Contradictory terminal statuses.
10. Unapproved requirements incorrectly marked as release-ready.
11. Requirements marked integrated without required integration evidence.
12. Requirements marked verified without supporting evidence.
13. Conflicting canonical records.
14. Stale generated reports, if applicable.

Validate referential integrity automatically.
Where evidence cannot be checked mechanically, report it as requiring human review rather than pretending it has been verified.
Do not create a large database or external project-management platform.
Keep everything version-controlled in the existing repository.
11. PREVENT FUTURE REGISTER DIVERGENCE
The canonical register must be the only manually maintained authoritative requirements list.
Existing documents may remain as historical references.
If build-specific views are useful, generate them automatically from the canonical register.
Examples:

* Build 18 requirements.
* Build 19 requirements.
* Build 20 planning.
* Build 21 planning.
* Open owner decisions.
* Active worker assignments.
* Release blockers.
* Requirements awaiting tests.
* Requirements awaiting owner playtest.

Do not allow generated views to become independent editable sources.
Mark generated files clearly.
If possible, make generated views reproducible through a simple command.
Do not require workers to update the same requirement in multiple documents.
12. INTEGRATE THE SYSTEM INTO NORMAL DEVELOPMENT
Update the project's existing agent instructions, worker handoff procedures, and development workflow.
All workers must follow these rules:
Before starting work

1. Read the authoritative requirement.
2. Confirm owner approval.
3. Confirm target build.
4. Review dependencies.
5. Identify acceptance criteria.
6. Check whether another worker already owns the task.

During development

1. Work only within the assigned scope.
2. Preserve existing decisions.
3. Record meaningful implementation progress.
4. Flag newly discovered dependencies.
5. Distinguish engineering choices from owner decisions.

When implementation is finished

1. Record the implementation commit.
2. Record applicable test evidence.
3. Identify whether the work is integrated.
4. Identify whether gameplay verification remains.
5. Update the canonical requirement.
6. Preserve known limitations.

Before release

1. Verify every approved requirement assigned to the build is accounted for.
2. Confirm all required implementation is integrated.
3. Confirm required validation evidence.
4. Confirm save compatibility.
5. Confirm platform packaging.
6. Confirm required owner playtesting.
7. Confirm no unresolved release blockers.

No worker should declare a requirement fully complete merely because its local tests pass.
13. MAKE REQUIREMENTS UPDATES PART OF THE DEVELOPMENT WORKFLOW
I do not want to manually remind Claude to update the register.
Make requirements maintenance a standard part of normal work.
When an owner approves a new requirement:

* Create or update its canonical record.
* Link the decision.
* Assign the appropriate build only when established.
* Record dependencies.
* Establish acceptance criteria.

When a requirement changes:

* Preserve the earlier decision.
* Record the new decision.
* Update affected requirements.
* Identify downstream consequences.

When code is implemented:

* Update implementation evidence.

When tests pass:

* Record the applicable test evidence.

When a build is integrated:

* Update integration status.

When the owner playtests:

* Record the outcome.

When a defect is discovered:

* Link it to the affected requirement or release gate.

Do not depend on informal memory or chat history alone.
14. ADD PRACTICAL WORKFLOW ENFORCEMENT
Implement the lightest effective enforcement mechanisms.
At minimum:

* A canonical schema.
* A validator.
* A documented update procedure.
* Generated build views.
* A release-readiness report.

Where practical, integrate validation into the existing CI pipeline.
CI should fail for structural errors such as duplicate IDs, broken references, or invalid statuses.
CI should not fail merely because a requirement is legitimately unfinished.
Avoid expensive workflows or full game test suites for documentation-only changes.
If stronger enforcement would create significant development overhead, explain the tradeoff and choose the simpler reliable option.
15. AUTOMATED PROGRESS REPORTING
Create a report generator that reads the canonical register.
It should report, for each build:

* Total approved requirements.
* Fully specified requirements.
* Open design decisions.
* Not-started requirements.
* Active development requirements.
* Task-branch implementations.
* Integrated requirements.
* Automated-test-verified requirements.
* Gameplay-verified requirements.
* Owner-playtested requirements.
* Release blockers.
* Deferred requirements.
* Unassigned requirements.
* Remaining work by effort category.

Do not count proposals in approved-build completion percentages.
Do not count superseded records twice.
Do not treat implementation completion as release readiness.
Report requirement-count completion separately from effort estimates.
Use conservative effort bands:

* XS
* S
* M
* L
* XL

If evidence is insufficient to estimate effort, report unknown.
Do not invent development hours or completion dates.
16. ESTABLISH AN ACCURATE BUILD 18 BASELINE
After reconciliation, generate a new Build 18 report.
Show:

* Correct total approved requirements.
* Number integrated.
* Number tested.
* Number player-verified.
* Number incomplete.
* Number blocked.
* Number awaiting owner decisions.
* Number actively being developed.
* Number not started.
* Major remaining systems.
* Critical dependencies.
* Release-readiness status.

Explain how the corrected figures differ from the previous 30-of-64 estimate.
Do not force the old percentage to remain valid.
If reconciliation increases the denominator, report the corrected number without interpreting the percentage decrease as lost implementation progress.
Identify the largest remaining engineering bottlenecks.
Preserve the combined Build 18 release scope.
17. BUILDS 19–21 BASELINE
Generate the same reporting structure for Builds 19, 20, and 21.
For Build 19, distinguish completed design decisions from functioning prototype code and integrated gameplay.
For Builds 20 and 21, prominently identify that implementation is not authorized unless newer owner approval exists.
Separate approved future requirements from proposed ideas.
Show unresolved decisions and dependencies.
Do not invent implementation progress.
18. CHANGE CONTROL WITHOUT STIFLING DEVELOPMENT
This system must not prevent creative iteration.
The owner may revise an earlier decision when testing exposes unforeseen problems.
When a design problem emerges:

1. Identify the original intent.
2. Explain the observed problem.
3. Identify affected requirements.
4. Recommend the smallest practical adjustment.
5. Record the proposed change.
6. Obtain owner approval when gameplay behavior meaningfully changes.
7. Preserve the earlier decision in history.
8. Update dependent requirements after approval.

Do not blindly defend an old design decision.
Do not independently redesign major gameplay systems.
Do not repeatedly interrupt the owner for minor engineering choices.
Maintain development momentum.
19. RECOVERY AND CONTEXT COMPACTION
Claude development sessions have repeatedly compacted at approximately 80% context utilization.
Update the existing recovery and handoff process to preserve the canonical register's location, current branch states, active worker assignments, unresolved decisions, and immediate next actions before compaction.
Use a practical checkpoint around 70–75% context utilization where measurable.
Do not duplicate the entire requirements register in the recovery document.
Reference the canonical files and record only session-specific state.
After compaction, reload the authoritative records rather than relying on reconstructed conversational memory.
20. IMPLEMENTATION AND INTEGRATION SEQUENCE
Execute the work in this order:

1. Inventory all existing requirement and decision sources.
2. Compare the competing registers.
3. Create the complete reconciliation ledger.
4. Establish the canonical schema.
5. Migrate all records without data loss.
6. Establish the canonical decision register.
7. Reconcile implementation statuses against existing evidence.
8. Implement the validator.
9. Implement generated build views and reports.
10. Update worker instructions and handoff procedures.
11. Add appropriate lightweight CI validation.
12. Validate all migrated records.
13. Integrate the administrative changes safely.
14. Generate the corrected Builds 18–21 status report.

Do not interrupt the active gameplay workers.
Do not perform unrelated gameplay implementation.
Do not rerun full game test suites unless a change unexpectedly requires them.
Use existing evidence and targeted validation.
If a genuine owner-level ambiguity blocks reconciliation of specific records, preserve them as flagged conflicts and continue reconciling the rest.
Do not stop the entire task because of one ambiguous requirement.
21. ACCEPTANCE CRITERIA
This project-management correction is complete when:

* Every discovered original requirement is accounted for.
* Every original ID maps to a canonical record or preserved historical entry.
* There is one authoritative requirements register.
* There is one authoritative owner decision register.
* No approved requirement has been silently discarded.
* Build-specific views derive from the master.
* All current workers have clear instructions to use the master.
* The validator passes.
* Generated reports are reproducible.
* Requirements and decisions can be updated without maintaining duplicate records.
* Builds 18–21 have accurate, evidence-based baselines.
* Release readiness is separate from implementation progress.
* Existing gameplay branches and active workers remain protected.
* Future compaction recovery points back to the authoritative records.

22. FINAL REPORT TO OWNER
When finished, provide:
A. Reconciliation results

* Number of original records inspected.
* Number of unique canonical requirements.
* Number of duplicates merged.
* Number of superseded records preserved.
* Number of unresolved conflicts.
* Number of previously missing approved requirements recovered.

B. System implementation

* Canonical file locations.
* Decision register location.
* Validator location.
* Report generator location.
* Worker instructions updated.
* CI enforcement implemented.
* Relevant commits.

C. Corrected development status
A table covering Builds 18, 19, 20, and 21 with:

* Approved requirements.
* Integrated requirements.
* Verified requirements.
* Player-verified requirements.
* Open owner decisions.
* Release blockers.
* Readiness classification.

D. Remaining management risks
Identify any remaining uncertainties or requirements requiring owner review.
E. Permanent workflow
Explain in plain English how new requirements, owner decisions, worker progress, tests, and release checks will be recorded automatically or through required workflow steps.
F. Verification
Show evidence that:

* The validator passes.
* No original requirement was lost.
* Generated reports reproduce correctly.
* Active worker work was preserved.
* No unrelated gameplay code was changed.

FINAL OWNER EXPECTATION
We are developing an interconnected simulation with multiple future builds, parallel workers, evolving owner decisions, and long development sessions.
The project cannot depend on remembering which document was updated last.
One authoritative source of truth. One consistent development workflow. No lost requirements. No inflated completion reports.
Preserve the full scope of approved Build 18.
Keep active development moving.
Make the tracking system reliable, lightweight, and maintainable.
Do not stop at planning.
Reconcile the records, implement the controls, validate the results, and give me an accurate picture of where the project actually stands.
