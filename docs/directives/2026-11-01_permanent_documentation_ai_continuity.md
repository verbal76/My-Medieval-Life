HOT ATTIC GAMES

PERMANENT DEVELOPMENT DOCUMENTATION AND AI CONTINUITY DIRECTIVE

OWNER DIRECTIVE — NOVEMBER 1, 2026

Applies to:

- Upwardly — "verbal76/Climb-Up"
- My Medieval Life — "verbal76/My-Medieval-Life"

Status: APPROVED — EFFECTIVE IMMEDIATELY

Claude,

I am establishing a permanent documentation and development-history requirement for Hot Attic Games.

The purpose is to ensure that any future Claude session, ChatGPT conversation, development agent, or authorized engineer can reconstruct the complete state and relevant history of a project directly from GitHub.

I should never have to explain weeks of previous development because an AI conversation reached its context limit.

Our GitHub repositories must serve as our permanent institutional memory.

This directive applies to your current project. Do not modify the other project's repository.

---

1. GITHUB IS THE PERMANENT DEVELOPMENT RECORD

Every meaningful development milestone must be recorded in GitHub.

Documentation must establish:

1. What was changed.
2. Why it was changed.
3. Which owner decision authorized it.
4. Which requirements it implements.
5. Which source files or systems were affected.
6. Which development branch contains it.
7. Which commit introduced it.
8. Whether it has been merged.
9. What validation was performed.
10. Whether the implementation is complete.
11. What remains unfinished.
12. What should happen next.

Do not rely on conversations as the only record of development decisions.

Do not rely on commit messages alone to explain complex changes.

Commit history, development changelogs, decision records, validation artifacts, and recovery documentation should complement one another.

Avoid duplicating entire documents unnecessarily.

---

2. MAINTAIN A PERMANENT DEVELOPMENT CHANGELOG

Maintain one clearly identified chronological development changelog for the project.

Reuse an existing suitable changelog if one exists. Otherwise, establish a dedicated development-history document.

This is separate from player-facing release notes.

Record meaningful development milestones, including:

- New gameplay systems.
- Modified mechanics.
- Bug fixes.
- Procedural-generation changes.
- Performance optimizations.
- UI and visual changes.
- Audio improvements.
- Save-system changes.
- Testing infrastructure changes.
- Integration and merging.
- Reverted experiments.
- Abandoned approaches.
- Technical discoveries.
- Major test results.
- Owner-approved changes in direction.

Each entry should include:

Date:
Build or expansion:
Requirement or decision ID:
Branch:
Commit SHA:
Change:
Reason:
Implementation status:
Validation evidence:
Outstanding work:

Use short entries for simple changes and more detailed entries for substantial changes.

Do not write a lengthy essay for every small commit.

The goal is comprehensive historical coverage, not unnecessary repetition.

Preserve chronological history.

Never silently rewrite past records to make unsuccessful experiments disappear.

---

3. CREATE AN UNAMBIGUOUS CURRENT-STATE ENTRY POINT

Every repository must have one clearly identified starting document for a new development session.

It must explain:

- Current development build.
- Active integration branch.
- Exact latest verified SHA.
- Current development head, if different.
- Active workers.
- Suspended workers.
- Pending integration branches.
- Completed milestones.
- Current tests and results.
- Actual known defects.
- Outstanding owner decisions.
- Next authorized development action.
- Links to historical records.

Make this document easily discoverable from the repository's root README or existing agent instructions.

Do not create a competing system if one already exists.

Most importantly:

Historical documentation must not be mistaken for the current development state.

When a branch ledger, old handoff, or historical report contains obsolete information, clearly identify it as historical or update its current-state pointer.

Never delete useful historical evidence merely because development has advanced.

---

4. PRESERVE OWNER DECISIONS PERMANENTLY

Every substantive owner decision must be recorded.

This includes decisions made during technical discussions when the owner challenges an assumption or changes the intended design.

Record:

- Date of decision.
- Owner's actual instruction.
- Previous assumption or policy.
- New approved policy.
- Affected gameplay or engineering systems.
- Whether implementation is authorized.
- Whether the decision supersedes earlier instructions.
- Applicable tests.
- Implementation status.

Do not confuse a suggestion, investigation, or hypothetical example with an approved owner decision.

A discussion of a possible feature does not authorize implementing it.

When the owner explicitly approves a change, preserve that authorization and its scope.

Do not reopen settled decisions merely because the original conversation is unavailable.

When an owner decision supersedes earlier requirements, preserve the historical record and identify which instruction now controls.

---

5. CONNECT TEST RESULTS TO THE EXACT SOURCE

Every significant validation record must identify:

- Source commit SHA.
- Branch.
- Test suite or workflow.
- GitHub Actions run ID and link, where applicable.
- Test configuration.
- Relevant seeds or simulation inputs.
- Pass/fail results.
- Important measurements.
- Known limitations.
- Artifacts containing detailed results.

Distinguish:

IMPLEMENTED: Code exists.

COMPILED: Compilation succeeded.

TESTED: Specific tests executed.

VALIDATED: Relevant acceptance requirements were demonstrated.

INTEGRATED: Changes are present in the intended integration source.

PACKAGED: A distributable artifact was built.

RELEASED: An authorized release was actually published.

Do not describe local tests as GitHub CI results.

Do not describe successful unit tests as proof of complete gameplay validation.

Do not claim a result applies to a later SHA without verifying that the relevant changes preserve its applicability.

Preserve important negative results.

A failed experiment can explain why a future developer should not repeat an approach.

---

6. GITHUB ACTIONS MUST PRODUCE DURABLE EVIDENCE

Continue using GitHub Actions for substantial repeatable computation.

When practical, workflows should produce:

- Human-readable summaries.
- Structured JSON or CSV.
- Detailed test results.
- Relevant logs.
- Performance statistics.
- Comparison tables.
- Charts when useful.
- Failure classifications.

Preserve meaningful results in GitHub Actions artifacts and, when appropriate, committed project reports.

Record run IDs and artifact references in the development history.

Remember that GitHub Actions artifacts can expire.

Important conclusions, measurements, fingerprints, and links needed for long-term reproducibility should be preserved in durable repository records rather than existing only in temporary artifacts.

Do not commit enormous raw logs unnecessarily.

Prefer concise durable conclusions with enough information to reproduce or retrieve the evidence.

Do not launch new simulations merely to populate documentation.

Reuse existing validated evidence.

---

7. REQUIREMENTS AND IMPLEMENTATION TRACEABILITY

Every major approved feature should be traceable through:

OWNER DECISION

↓

REQUIREMENT

↓

IMPLEMENTATION

↓

COMMIT

↓

TEST EVIDENCE

↓

INTEGRATION

↓

RELEASE STATUS

This chain must be reconstructable from GitHub.

Do not mark a feature complete merely because its code exists.

Do not mark abandoned or experimental work as integrated.

Do not silently remove approved requirements.

---

8. UPWARDLY-SPECIFIC DOCUMENTATION

For Upwardly, integrate this documentation policy with the existing records:

- "CLAUDE.md"
- "docs/DECISIONS.md"
- "docs/BRANCH_LEDGER.md"
- "docs/RELEASES.md"
- Existing verification and certification records.
- Existing Build 83 and Build 84 performance reports.
- Existing recovery and handoff documents.

The current Build 84 source must be distinguished from historical development branches.

Do not allow outdated branch documentation to misdirect a future development session.

Preserve documentation covering:

- NORMAL, PUNISHER, and NGH rules.
- Procedural-generation architecture.
- Generator and solver distinctions.
- Determinism requirements.
- Generation recovery.
- Streaming and buffering.
- Startup performance.
- Simulation KPIs.
- Difficulty calibration.
- Build certification.
- Steam and platform release preparation.

Record the latest findings concerning:

- Solver UNKNOWN classifications.
- Actual generation exhaustion.
- Streaming-generation margins.
- Startup time to first controllable step.
- Prepared-climb restoration.
- The two-slice startup decision.

Distinguish findings from proposed or implemented corrections.

Do not change the generator as part of establishing this documentation policy.

---

9. MY MEDIEVAL LIFE-SPECIFIC DOCUMENTATION

For My Medieval Life, preserve the existing requirements-control architecture.

Relevant records include:

- "docs/CURRENT_DEVELOPMENT_STATE.md"
- "docs/handoffs/CURRENT_SESSION_RECOVERY.md"
- "docs/requirements/requirements.json"
- "docs/DEVELOPMENT_LEDGER.md"
- "docs/requirements/views/"
- Existing owner directives.
- Existing development and release records.

The existing requirements register remains the authoritative record for requirement and decision status.

Do not create a second competing requirements database.

Do not manually edit generated requirements views or the generated development ledger.

Follow the established register-update and regeneration procedures.

Preserve the restriction that authoritative register changes occur through the designated requirements-control branch and process.

Ensure a fresh developer can distinguish the latest authoritative staging documentation from stale copies on older development branches.

For Build 25, document:

- Approved consolidation scope.
- The nine owner decisions.
- The Living Economy activation policy.
- Skilled-employment integration.
- Business founding and permanent employment.
- Five suspended workstreams.
- Integration dependencies.
- Existing testing results.
- Farming calibration requirements.
- Thirteen economy-readiness gates.
- Existing known defects.
- Remaining packaging and release requirements.

Maintain traceability across previous builds and expansions.

Do not discard approved historical work because the current implementation resides on a newer branch.

---

10. MAINTAIN RECOVERABLE WORKER HISTORIES

Every active or suspended development workstream must have a recoverable record.

Include:

- Worker assignment.
- Branch name.
- Latest pushed commit.
- Unpushed or uncommitted work, if any.
- Relevant worktree location, where applicable.
- Completed changes.
- Tests performed.
- Known defects.
- Merge readiness.
- Outstanding dependencies.
- Next safe step.

When a worker stops, completes, or is suspended, update the record.

A future development session must be able to identify work that exists but has not yet been merged.

Never assume that an unmerged branch is disposable.

Do not claim that local uncommitted work is safely preserved in GitHub.

---

11. AUTOMATIC RECOVERY AFTER CONTEXT LOSS

Establish a standard recovery procedure for future Claude sessions.

A new session should:

1. Identify the repository and current development objective.
2. Read the root agent instructions.
3. Locate the authoritative current-state entry point.
4. Fetch current GitHub branch heads.
5. Review recent development changelog entries.
6. Review applicable owner decisions.
7. Review active and suspended workstreams.
8. Identify the latest verified integration SHA.
9. Inspect relevant recent CI results.
10. Identify outstanding defects and dependencies.
11. Resume the next authorized development action.

The procedure must distinguish current state from historical documentation.

Before context compaction, update the recovery checkpoint.

When context usage is measurable, prepare the checkpoint before the session becomes difficult to recover.

Do not wait until the context window is exhausted.

---

12. ALLOW A FUTURE CHATGPT TO RECONSTRUCT DEVELOPMENT

Documentation must also be usable by an external assistant with GitHub access that was not involved in development.

Do not assume the reader knows:

- What we discussed last week.
- Why a test was performed.
- Which approach was rejected.
- Which owner decision controls.
- Which branch is authoritative.
- Which features are integrated.
- Which simulation results apply.
- Why a release was withheld.

Use explicit terminology, dated entries, stable identifiers, source references, and links.

A future assistant should be capable of generating:

A CURRENT STATUS REPORT

What is happening now?

A LAST 24-HOUR REPORT

What changed, what passed, and what failed?

A BUILD HISTORY REPORT

How did we reach the current implementation?

AN OWNER DECISION REPORT

What did the owner approve, reject, or defer?

A TECHNICAL PROGRESS REPORT

What functionality is implemented, tested, and integrated?

A RELEASE READINESS REPORT

What evidence exists, and what genuinely remains?

These reports must be reconstructable from durable repository information without relying on inaccessible conversation history.

---

13. DOCUMENTATION MUST NOT DISRUPT DEVELOPMENT

This policy takes effect immediately.

However, it must not create unnecessary development overhead.

Do not:

- Interrupt current Build 84 work.
- Restart MML's suspended workers.
- Launch expensive documentation-only test campaigns.
- Recreate every old report from scratch.
- Start multiple documentation agents.
- Generate redundant daily summaries containing identical information.
- Use excessive Claude tokens rewriting existing documents.

First establish clear navigation and current-state accuracy.

Then maintain the records naturally as development progresses.

For historical work, create a concise index pointing to existing authoritative records rather than rewriting the entire history.

When code changes, update the relevant records as part of the same milestone.

Documentation-only changes should not trigger heavyweight gameplay CI unless the workflow genuinely requires it.

---

14. RESOURCE PRIORITY REMAINS UNCHANGED

Upwardly:

Highest development priority.

Continue Build 84 implementation, performance work, and approved audits.

My Medieval Life:

Reduced-resource mode.

Maximum one active Claude development worker.

Preserve the other suspended workstreams.

Prefer GitHub Actions for substantial repeatable computation.

This directive does not change the existing development priorities.

---

15. COMPLETION REQUIREMENTS

Implement the documentation structure using existing systems wherever possible.

Do not stop gameplay development for an extensive historical reconstruction.

At the next safe checkpoint, provide:

1. The authoritative current-state document.
2. The development changelog location.
3. The owner-decision record location.
4. The requirements record location, if applicable.
5. The testing and certification evidence locations.
6. The worker and branch recovery location.
7. The standard instructions for a future AI session.
8. Any outdated navigation references that were corrected.
9. The commit SHA containing these documentation improvements.

Then continue authorized development.

---

FINAL OWNER INSTRUCTION

GitHub must preserve not only our code, but the reasoning, decisions, discoveries, mistakes, corrections, validation results, and development history that produced it.

I want any future iteration of ChatGPT or Claude to reconstruct our progress by examining the repository.

No important owner decision should disappear with a conversation.

No completed workstream should be forgotten because its worker stopped.

No test result should lose its connection to the source it validated.

No historical documentation should be mistaken for the current project state.

Establish this as a permanent Hot Attic Games development standard and maintain it continuously.

END OF OWNER DIRECTIVE