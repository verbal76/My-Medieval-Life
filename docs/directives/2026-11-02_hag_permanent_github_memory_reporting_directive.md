HOT ATTIC GAMES

PERMANENT GITHUB MEMORY, DECISION HISTORY, AND DEVELOPMENT REPORTING DIRECTIVE

Version 1.0 — November 2, 2026

OWNER DIRECTIVE — IMPLEMENT IN THIS REPOSITORY

This directive applies to the Hot Attic Games repository you are currently working in.

The owner has established GitHub as the permanent, authoritative record of project development.

Our objective is to eliminate manual conversation handoffs permanently.

ChatGPT (Bob) is connected to our GitHub repositories and can read commits, workflow runs, job results, logs, documentation, and artifacts. ChatGPT also has repository write access.

Claude and ChatGPT must be able to independently recover the project's development history, current status, owner decisions, and next actions directly from GitHub.

This directive authorizes documentation-system setup and necessary lightweight CI reporting modifications. It does not authorize gameplay changes, unrelated refactoring, public releases, or modifying frozen release candidates.

---

PART 1 — INITIAL REPOSITORY RECONNAISSANCE

Before implementing anything, investigate THIS repository.

Identify:

1. Repository name and purpose.
2. Current development build.
3. Most recent successfully packaged build.
4. Active development branch and exact commit SHA.
5. Frozen or protected branches.
6. Active workstreams and their respective branches.
7. Existing development documentation.
8. Current owner-approved requirements.
9. Owner decisions and non-negotiable constraints.
10. Existing CI workflows and test infrastructure.
11. Recent release history.
12. Known defects and unresolved investigations.
13. Currently running GitHub Actions jobs.
14. Pending work and release blockers.
15. Any existing recovery or handoff instructions.

Review the latest 20 GitHub Actions workflow runs, including their constituent jobs.

For each relevant run, inspect its status, commit, significant results, and available reporting artifacts.

Read actual failure evidence when necessary.

Do not assume a green workflow proves that every feature passed. Distinguish successful packaging from successful testing, skipped validation, and tests whose failures were improperly tolerated.

Inspect existing documentation before creating new files.

Preserve authoritative records already in place.

Do not overwrite established project history, requirements, or previously approved decisions.

If existing documents are stale, identify them and reconcile them against newer evidence.

Do not treat a historical handoff as more authoritative than current code, current owner decisions, or the project's established requirements register.

---

PART 2 — ESTABLISH PERMANENT PROJECT MEMORY

Every repository must provide six logical documentation components.

Existing documents may fulfill these requirements. Do not create unnecessary duplicates.

A. PROJECT MEMORY

A permanent description of the project.

Include:

- Project vision and intended experience.
- Target platforms.
- Main systems and architecture.
- Owner-approved design principles.
- Important technical constraints.
- Features and systems already implemented.
- Feature status and development milestones.
- Rejected design directions.
- Long-term objectives.
- Links to authoritative specifications.

This is the historical foundation.

It must not be rewritten from scratch whenever a build changes.

B. CURRENT DEVELOPMENT STATE

A concise, continuously maintained snapshot.

Include:

- Current development build.
- Last packaged release.
- Active branches and their purposes.
- Relevant commit SHAs.
- Current workstreams.
- Active GitHub testing.
- Known blockers.
- Unresolved failures.
- Recently completed milestones.
- Immediate next actions.
- Decisions awaiting owner approval.
- Relevant CI run links.

A fresh AI session must be able to understand the project's present condition by reading this file.

Always record when the snapshot was last verified.

A stale snapshot must never silently masquerade as current information.

C. DEVELOPMENT HISTORY

Maintain a chronological record of meaningful development.

For every significant change, record:

- Date.
- Build.
- Branch.
- Commit SHA.
- What changed.
- Why it changed.
- Which problem it was intended to solve.
- Relevant owner decision.
- Affected systems.
- Verification performed.
- Results.
- Remaining limitations.

Do not delete previous history when new changes supersede old work.

D. OWNER DECISION REGISTER

This is mandatory.

Major development discussions must be preserved as durable decision records.

Each record must explain not only WHAT was decided but WHY.

Include:

Decision identification

- Unique decision ID.
- Date.
- Project/build.
- Decision status.
- Source of authority.

Original problem

- What prompted the discussion?
- What was wrong or missing?
- What outcome was the owner trying to achieve?

Owner's direction

- What did the owner actually approve?
- Preserve brief, meaningful quotations when necessary.
- Clearly distinguish an actual owner statement from Claude's interpretation.

Reasoning and alternatives

- Why was this approach selected?
- What alternatives were genuinely considered?
- Why were those alternatives rejected?
- What benefits and disadvantages were identified?
- What assumptions influenced the decision?

Consequences

- What systems are affected?
- What constraints now apply?
- What must not change without authorization?
- Does the decision create new dependencies or risks?

Implementation

- Relevant tasks.
- Commits.
- Pull requests.
- Tests.
- Results.
- Current completion status.

Future reconsideration

- Under what circumstances should this decision be reviewed?
- What evidence would justify changing it?

Never invent alternatives, discussions, or approval that did not occur.

If the original reasoning is unknown, explicitly mark it UNKNOWN rather than fabricating an explanation.

A later decision may supersede an earlier decision, but the original decision and its reasoning must remain recoverable.

E. KNOWN ISSUES AND INVESTIGATIONS

Maintain durable records of significant defects and unresolved questions.

Include:

- Symptom.
- Discovery date.
- Affected versions.
- Reproduction conditions.
- Relevant seeds or simulation configurations.
- Suspected cause.
- Confirmed root cause, when established.
- Attempts already made.
- Failed approaches and why they failed.
- Current status.
- Resolution commit.
- Verification evidence.
- Remaining risks.

This prevents future developers from repeating unsuccessful investigations simply because an older conversation disappeared.

F. SESSION RECOVERY INSTRUCTIONS

Create or maintain one clear entry point for future Claude and ChatGPT sessions.

It must explain:

1. Which branch represents current development.
2. Which project documents are authoritative.
3. Where decisions are recorded.
4. Where current work is documented.
5. How to examine recent CI results.
6. How to identify unresolved blockers.
7. How to distinguish completed, tested, and released work.
8. What the next authorized action is.

The recovery instructions must be short enough to use efficiently.

They must link to detailed evidence rather than duplicate the entire repository history.

---

PART 3 — MANDATORY REPORTING FOR GITHUB ACTIONS

All development and validation workflows must generate useful reporting.

Use existing reporting mechanisms wherever possible.

Extend them only where needed.

The goal is to make the latest 20 workflow runs sufficient to understand recent development, while permanent project memory preserves older information.

Every substantial CI run must report:

Identification

- Repository.
- Project.
- Build number.
- Branch.
- Exact commit SHA.
- Workflow name.
- Run ID.
- Run attempt.
- Start and completion times.

Purpose

- Why the workflow was triggered.
- What it was intended to verify.
- Which systems were affected.
- Which decision or implementation prompted it.

Test results

- Tests attempted.
- Tests passed.
- Tests failed.
- Tests skipped.
- Tests cancelled.
- Execution duration.
- Relevant measurements.
- Expected results.
- Actual results.

Failures

- Exact failed test.
- Error message.
- Relevant reproduction details.
- Root cause, if known.
- Whether a fix exists.
- Whether that fix has been verified.

Outcome
Use precise classifications.

IMPLEMENTED does not automatically mean TESTED.

TESTED does not automatically mean VALIDATED.

VALIDATED does not automatically mean PACKAGED.

PACKAGED does not automatically mean RELEASED.

RELEASED on GitHub does not automatically mean UPLOADED TO STEAM.

Never collapse these distinctions into a simple success statement.

Required output formats

Where practical, generate:

1. A human-readable Markdown summary.
2. A machine-readable JSON report.
3. Detailed supporting logs or artifacts.

Use GitHub Actions job summaries for quick inspection.

Upload detailed reports as workflow artifacts.

Reporting should execute even when tests fail, wherever technically possible.

A reporting failure must not hide a genuine test failure, and a test failure must never be reported as success merely because reporting completed.

When a workflow cannot generate a complete report, explicitly identify the missing evidence.

---

PART 4 — PERMANENT RECORDS VERSUS TEMPORARY ARTIFACTS

GitHub Actions artifacts can expire.

Therefore, critical project history cannot exist only inside downloadable CI artifacts.

Preserve important findings in durable repository documentation.

Detailed raw logs may remain in GitHub Actions.

Permanent records must retain:

- Decision history.
- Significant failures.
- Important measurements.
- Root-cause findings.
- Fixes.
- Verification outcomes.
- Current unresolved work.
- Links to the original evidence.

Do not commit enormous raw simulation logs or binaries unnecessarily.

Instead, commit concise conclusions and evidence references.

Automatic reporting should not create unnecessary commits on actively tested code branches, since that would change the commit SHA and complicate validation.

Use an appropriate reporting branch or established repository mechanism when automation must persist records independently.

---

PART 5 — DOCUMENT IMPORTANT CONVERSATIONS

This section is especially important.

Whenever the owner and Claude have a substantial development discussion, evaluate whether it introduces or modifies a lasting decision.

Examples include:

- Changing gameplay mechanics.
- Altering procedural-generation rules.
- Redesigning economic systems.
- Changing NPC behavior.
- Modifying architecture.
- Changing the user interface significantly.
- Establishing or changing test requirements.
- Modifying release policy.
- Rejecting a previously considered feature.
- Accepting a significant technical compromise.
- Changing the project's development priorities.

If the conversation has lasting consequences, document it.

Required procedure

Before implementing the resulting significant change, or at the same authorized development checkpoint:

1. Identify the problem discussed.
2. Record the owner's actual direction.
3. Explain why the decision was made.
4. Preserve meaningful alternatives and objections.
5. Document the expected consequences.
6. Identify what implementation is authorized.
7. Link the decision to subsequent development and test evidence.

Do not simply record:

"Changed the economy system."

Record the reasoning:

"The original behavior created a specific problem. The owner wanted a particular outcome. These alternatives were considered. This solution was chosen for these reasons. These constraints apply to future changes."

The record must allow a future developer to understand why the existing implementation should not casually be replaced.

Preserve the conversation's intent

Do not convert brainstorming into approved requirements.

Do not present Claude's suggestion as the owner's decision.

Do not imply the owner approved something merely because they discussed it.

Record uncertainty explicitly.

When decisions originate in ChatGPT rather than the current Claude conversation, use the owner's supplied instruction or the corresponding committed record. Do not pretend to have access to conversations that are not actually available.

---

PART 6 — GITHUB-FIRST TESTING

The owner has deliberately moved as much testing as practical to GitHub to conserve Claude's context and token allowance.

Preserve this operating model.

GitHub Actions should handle:

- Automated tests.
- Platform builds.
- Regression suites.
- Long simulations.
- Benchmark campaigns.
- Integrity checks.
- Artifact generation.
- Detailed reporting.

Claude should concentrate on development, analysis, and engineering decisions.

Testing efficiency requirements

Prefer parallel, independently reportable test jobs when the repository supports them.

Do not repeat an expensive full test suite merely for reassurance.

Before launching tests, check whether passing results already exist for the exact relevant commit.

Reuse valid existing evidence.

If new code requires additional testing, select the appropriate focused tests.

A full suite should run when genuinely required by the project's validation contract, not automatically after every small change.

Do not sacrifice necessary verification to save tokens.

Optimize testing organization rather than weakening standards.

Keep a clear distinction between parallel test jobs that collectively form a complete suite and individual jobs that provide only partial coverage.

---

PART 7 — AUTOMATIC DEVELOPMENT CHECKPOINTS

Documentation must not depend on remembering to write a handoff at the end of a conversation.

Update the relevant records at meaningful checkpoints.

Examples:

- A significant implementation is completed.
- An important owner decision is made.
- A major defect is discovered.
- A root cause is established.
- An investigation changes direction.
- A system integration is completed.
- A substantial simulation finishes.
- A build is packaged.
- A release is authorized.
- A previously approved design is superseded.

Also checkpoint durable work before context compaction when possible.

Every checkpoint should leave the repository in a condition from which another AI can resume accurately.

Do not claim that ephemeral local work exists remotely unless it has actually been pushed.

Record any unpushed or unavailable work as such.

---

PART 8 — RECOVERY STANDARD FOR ANY FUTURE AI

A new ChatGPT or Claude conversation must be able to recover this project using the following procedure.

STEP 1: Identify the repository and active development branch.

STEP 2: Read the permanent project memory and authoritative requirements.

STEP 3: Read the current development snapshot.

STEP 4: Read recent changes and owner decisions, including their rationale.

STEP 5: Inspect the latest 20 GitHub Actions workflow runs and their constituent jobs.

STEP 6: Examine relevant reports and failure evidence.

STEP 7: Verify current release and package status.

STEP 8: Identify active tests and workstreams before starting additional work.

STEP 9: Reconcile conflicting information according to authority, chronology, and actual commit evidence.

STEP 10: Produce an accurate current-state summary and identify the next authorized work.

The repository must contain sufficient information to do this without requiring the owner to reconstruct the project's history.

The latest 20 workflow runs provide recent activity.

The permanent development records provide continuity across the entire life of the project.

Both are necessary.

---

PART 9 — OWNER AUTHORITY AND RELEASE PROTECTION

This directive does not modify existing owner-authority rules.

Continue following all established restrictions.

In particular:

- Never invent owner approval.
- Never silently alter approved gameplay or simulation rules.
- Never discard rejected alternatives from historical records.
- Never rewrite frozen development history.
- Never treat a green CI result as permission to publish.
- Never modify frozen release candidates merely to add documentation.
- Never upload to Steam or publish publicly without the required authorization.
- Never weaken tests or remove coverage without valid engineering justification and the required approval.
- Never restart expensive tests without checking current and completed runs.

Preserve the existing project requirements hierarchy.

---

PART 10 — INITIAL IMPLEMENTATION TASK

Execute the following setup now, in this repository.

1. Perform the complete repository reconnaissance described above.
2. Review existing memory, requirements, decision, and reporting systems.
3. Identify what already satisfies this directive.
4. Reuse existing infrastructure rather than creating competing systems.
5. Establish or update the missing permanent-memory components.
6. Add the decision-rationale documentation standard.
7. Reconcile the current project status against actual GitHub evidence.
8. Add necessary lightweight CI reporting improvements.
9. Ensure important reports are retained in recoverable form.
10. Document this directive itself as an owner-approved process decision, including its rationale.
11. Perform focused documentation/reporting validation without launching unnecessary full test campaigns.
12. Commit and push the approved setup through the repository's established development process, using a documentation branch and draft PR when the active branch is protected or frozen.
13. Report what was installed, what already existed, any remaining gaps, and where future ChatGPT sessions should begin.

Do not merge documentation into a frozen branch or disturb ongoing development.

If a documentation branch named "docs/hag-memory-rationale-2026-11-02" already exists, inspect it before deciding whether to reuse it.

Do not replace newer project state with old records simply because those records are easier to access.

First permanent decision record

Record the owner's November 2, 2026 directive:

Decision: Establish GitHub as the permanent project memory and require detailed CI reporting and documented development reasoning.

Why: ChatGPT and Claude conversations have finite context. Repeated manual handoffs waste time, consume tokens, and risk losing decisions, technical findings, and development history.

Desired outcome: A new AI conversation can recover any project by examining authoritative repository documents and the latest 20 GitHub Actions runs.

Additional requirement: Significant owner conversations must preserve the reasons for decisions, not merely their implementation results.

Development principle: Move expensive testing to GitHub while preserving rigorous verification and conserving Claude's development context.

Completion report

When setup is complete, provide:

- Repository examined.
- Active development branch and SHA.
- Existing documentation reused.
- Documentation created or updated.
- CI reporting improvements.
- Decision-history implementation.
- Validation results.
- Remaining limitations.
- Commit and PR references.
- Exact instructions for future AI recovery.

Do not stop after proposing the system. Implement the authorized documentation and reporting setup, using safe repository practices.

Once established, continue maintaining it throughout subsequent development.

This is a permanent Hot Attic Games development operating requirement.

END OWNER DIRECTIVE
