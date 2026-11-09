# Owner directive, 2026-11-09: Permanent development forensics, GitHub accountability, and complete historical recovery

Received 2026-11-09 13:12 EST in the lead session (Build 25 development lead). Saved verbatim below; never edited. Register id
HAG-FORENSICS-01.

---

HOT ATTIC GAMES — MY MEDIEVAL LIFE

PERMANENT DEVELOPMENT FORENSICS, GITHUB ACCOUNTABILITY, AND COMPLETE HISTORICAL RECOVERY

OWNER DIRECTIVE — NOVEMBER 9, 2026

Priority: Mandatory documentation recovery and permanent workflow enforcement.

Project: "verbal76/My-Medieval-Life"

Scope: My Medieval Life only. Do not modify Upwardly.

1. WHY THIS DIRECTIVE EXISTS

We have numerous AI agents, parallel development branches, independent audits, GitHub Actions workflows, integration processes, and development conversations contributing to this game.

The owner cannot personally remember every technical discussion or reconstruct every development decision.

That is precisely why Hot Attic Games previously established GitHub as its sole authoritative development record.

The existing directives remain in force:

- "docs/directives/2026-11-01_permanent_documentation_ai_continuity.md"
- "docs/directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md"
- "docs/directives/2026-11-03_reporting_timestamps.md"
- "docs/decisions/HAG-MEM-02.md"
- All applicable requirements in "CLAUDE.md".

This directive reinforces and expands their practical enforcement.

We are not asking for a conventional development changelog.

We are establishing a recoverable engineering history that preserves the complete factual context behind every significant decision.

Imagine the current development lead becomes permanently unavailable tomorrow.

A replacement developer must be able to read GitHub and understand what that developer was doing, what problems they encountered, which agents they coordinated with, why their implementation decisions were made, what was tried unsuccessfully, what evidence was gathered, and exactly how to continue.

No private conversation, individual AI session, temporary container, or developer's memory should be necessary to recover a documented development decision.

This is a permanent operating requirement.

2. AUTHORIZATION TO DELEGATE

The owner authorizes you to launch one dedicated documentation and historical-recovery subagent if that is the most effective way to accomplish this task.

Claude usage is currently plentiful, so normal subscription token conservation is not a reason to leave this important work incomplete.

Use the appropriate model and sufficient context to inspect the repository and evidence thoroughly.

The documentation agent may:

- Investigate repository and branch history.
- Read relevant existing and accessible agent records.
- Examine development evidence and test results.
- Identify missing historical explanations.
- Reconstruct documented technical decisions.
- Prepare documentation repairs.
- Commit and push its work to an isolated documentation branch.

The agent must not modify gameplay or simulation code.

The main development lead remains responsible for integrating the completed documentation into the authoritative records using the established safe process.

Do not run two agents against the same writable branch.

Do not overwrite or race another agent's edits.

The documentation agent should work independently where practical while the main developer continues previously authorized Build 25 work.

This authorization does not extend to additional paid API services or unnecessary third-party expenses.

3. DO NOT INTERRUPT BUILD 25

Before doing anything else, inspect the live GitHub state.

Recent known work includes:

- "wip/b25r2-rev2", the current Build 25 development integration line.
- "wip/requirements-control", the authoritative records and requirements-control branch.
- "wip/b25-backlog-merge", the tested backlog integration.
- "wip/b25-mp05-on-dev", the MP-05 integration branch.
- The completed backlog 365-day campaign, Actions run "42627103286".
- The MP-05 365-day campaign, Actions run "42664730920", which was running at the last external check.

Verify all current statuses rather than assuming these snapshots remain accurate.

Do not interrupt, cancel, restart, or duplicate an existing simulation.

Do not suspend otherwise authorized development simply because documentation reconciliation is underway.

Do not change the source commit being tested merely to record documentation.

Preserve every established integration, test, baseline, and release gate.

4. FIRST TASK — INVESTIGATE WHAT HAS BEEN MISSED

We already have reason to suspect the existing documentation is lagging behind actual development.

An external review identified the following:

1. The permanent changelog on "wip/requirements-control" does not clearly reflect all recent Build 25 work through November 9.
2. The central current-state file contains newer information but has an outdated verification heading.
3. The recovery documentation identifies older development branches and may not adequately direct a new session to the current Build 25 integration line.
4. Numerous independent audit corrections, development branches, owner decisions, test campaigns, and agent integrations have occurred within a short period.

These are investigation targets, not permission to blindly overwrite established records.

First determine which records are truly missing, which are elsewhere, which are stale, and which only need better cross-references.

Determine the last fully documented, verifiable checkpoint.

Then perform a historical audit from that checkpoint through the present. At minimum, inspect the November 1–9 development period. Go further back wherever you find an earlier unresolved gap.

Do not stop at a superficial review of recent commit messages.

Inspect the meaningful work across all relevant branches, pull requests, issues, workflow runs, artifacts, directives, and existing reports.

5. EVERY SIGNIFICANT DECISION NEEDS ITS COMPLETE STORY

For each significant event, preserve the following information.

A. Identity and timeline

- Stable event or decision ID.
- Actual date and timestamp.
- Project, build, and relevant requirement IDs.
- Responsible agent, developer, or workflow, where known.
- Branch and commit SHA.
- Source references.

B. Original situation

Explain what was happening before the work started.

What did the developer observe?

What behavior was unexpected?

What problem needed solving?

Was the work prompted by an owner request, failing test, defect report, performance measurement, another agent's finding, or an architectural dependency?

What was the original intended behavior?

C. Evidence and investigation

Document the material observations that led to the decision.

Include relevant:

- Error messages and failure symptoms.
- Reproduction cases.
- Test inputs and results.
- Diagnostic measurements.
- Simulation evidence.
- Code paths and interactions.
- Relevant environmental conditions.
- Earlier fixes or assumptions that influenced the outcome.

Distinguish confirmed facts from hypotheses.

For unsuccessful approaches, preserve what was attempted, what happened, and why the attempt was rejected or abandoned.

D. Communication and coordination

Record the material coordination between agents and developers.

Identify, where evidence permits:

- Who requested the work.
- Who investigated it.
- Who supplied relevant findings.
- Who implemented the change.
- Who reviewed or tested it.
- Which other agents or workstreams were affected.
- What instructions or constraints were passed between them.
- Which dependencies or conflicts had to be resolved.

An agent must not become an anonymous source of unexplained code changes.

Where an agent's communication is unavailable, say so explicitly rather than inventing conversations.

E. Decision and rationale

Explain the decision in sufficient engineering detail that a future developer could evaluate it independently.

Record:

- The problem the decision was intended to solve.
- The owner's actual direction, when applicable.
- Whether the decision was owner-approved or an authorized engineering choice.
- The assumptions used.
- The evidence supporting the selected approach.
- Material alternatives genuinely considered.
- Why those alternatives were not selected.
- Anticipated risks.
- Possible unintended consequences.
- Conditions under which the decision should be reconsidered.

Do not confuse a recommendation with an owner approval.

Do not invent alternatives or retrospective reasoning.

We need the factual decision rationale and evidence, not inaccessible private internal reasoning.

F. Implementation and verification

Connect the decision to the actual work.

Include:

- Relevant source files and systems.
- Implementation branch and commit.
- Integration or PR history.
- Tests performed.
- GitHub Actions run IDs.
- Results and failures.
- Simulations and determinism checks.
- Relevant performance comparisons.
- Known limitations.
- Whether acceptance criteria were actually satisfied.

Never use the word "complete" for something merely implemented or partially tested.

G. Consequences and next action

Record what the change affected, including interactions with other systems.

Explain any new dependencies, limitations, or risks.

Identify unfinished testing, blocked integration, pending owner decisions, and the next authorized action.

The required chain is:

ORIGINAL REQUIREMENT → OBSERVATION → INVESTIGATION → EVIDENCE → DECISION → IMPLEMENTATION → VALIDATION → RESULT → REMAINING WORK.

A replacement developer must be able to follow that chain without speaking to the original developer.

6. RECONSTRUCT THE MISSING BUILD 25 HISTORY

Pay particular attention to recent parallel development and independent audit activity.

Investigate the complete available history of:

- The independent audit findings and their classifications.
- Which findings were merely static suspicions.
- Which were reproduced in actual tests.
- Which fixes were implemented.
- Which fixes were merged or remain isolated.
- Why the original behavior was defective.
- Why a particular correction was selected.
- Failed red tests and successful green tests.
- Interactions between independent corrections.
- The order in which branches were integrated.
- Unexpected regressions discovered during integration.
- Follow-up corrections after apparently successful tests.
- 365-day simulation campaigns and their actual results.
- Flight-recorder findings and conservation/determinism evidence.
- Baseline differences and decisions about whether to accept them.
- Any unresolved questions or behavior changes.

Include the recent LIFE, PROP, JUS, REG, SAV, INV, BIZ, TRD, and multiplayer work, to the extent supported by actual history.

For MP-05 specifically, document the original owner requirements, the implementation and integration history, the discovered cart-sharing regressions, their fixes, the verification evidence, and the current status of its 365-day campaign.

Do not reconstruct the history from memory or assume that a successful merge means the original investigation was fully documented.

7. CREATE A TRACEABLE HISTORICAL COVERAGE REGISTER

Create or extend a suitable existing audit record that accounts for the meaningful activity within the recovery period.

For each work item, capture:

- Event or requirement ID.
- Branch.
- Commit or relevant source reference.
- Responsible agent or workstream, if known.
- Associated owner decision.
- Existing documentation location.
- Documentation completeness.
- Missing information.
- Recovery action taken.
- Evidence quality.
- Remaining uncertainty.

Classify documentation coverage as:

- COMPLETE — evidence and rationale are recoverable.
- PARTIAL — some information remains missing.
- UNDOCUMENTED — development evidence exists but no adequate historical record was found.
- UNRECOVERABLE — relevant source material could not be recovered after investigation.
- NOT APPLICABLE — non-substantive activity requiring no separate history.

Do not silently ignore commits, PRs, or significant workflow results.

Group routine mechanical activity where appropriate, but never collapse distinct decisions, important discoveries, or failed experiments into an unexplained summary.

The purpose is to prove which development history has been covered and identify exactly what is still missing.

8. REPAIR THE EXISTING DOCUMENTATION SYSTEM

Reuse the repository's established structures.

In particular:

- "docs/PROJECT_MEMORY.md"
- "docs/CURRENT_DEVELOPMENT_STATE.md"
- "docs/DEVELOPMENT_CHANGELOG.md"
- "docs/KNOWN_ISSUES.md"
- "docs/decisions/"
- "docs/directives/"
- "docs/requirements/requirements.json"
- "docs/requirements/views/"
- "docs/handoffs/CURRENT_SESSION_RECOVERY.md"

Do not create multiple competing current-state documents or decision registers.

The requirements register remains authoritative for requirement and decision status.

The decision rationale documents explain why those decisions were made.

The changelog records chronological milestones.

The current-state document describes active development, blockers, workers, branches, and next actions.

The recovery document explains how a new session finds everything.

Generated requirement views must be updated using the repository's existing tools, not manually edited.

Preserve history. Correct inaccurate records through traceable corrections rather than silently rewriting prior conclusions.

Clearly identify superseded instructions.

Do not mistake historical documents for current authority.

9. MAKE THE RECORDS ACCESSIBLE TO FUTURE AI SESSIONS

A particularly important requirement:

A new AI must be able to find the current Build 25 state immediately.

Reconcile the documented authority of:

- The current source integration branch.
- The records branch.
- Active task branches.
- Frozen and historical branches.
- GitHub Actions evidence.
- Pending integrations.

Do not change branch ownership or governance simply to repair old documentation.

Where the existing "CLAUDE.md" or recovery instructions reference outdated development branches, determine the accurate present structure and repair the directions through the established documentation process.

A fresh session must never silently resume work from an obsolete branch because it followed an outdated recovery file.

10. ENFORCE CONTINUOUS GITHUB REPORTING

After recovery, the same documentation standards apply automatically to every meaningful future development checkpoint.

Every agent must preserve its work in GitHub.

The standard checkpoint is:

1. Record the work performed.
2. Record why it was performed.
3. Record important observations and decisions.
4. Record the evidence and its limitations.
5. Record outstanding questions.
6. Update the appropriate history, status, and decision records.
7. Commit and push to the authorized working branch.
8. Confirm the remote commit SHA.

Regular pushes to authorized development and task branches do not require individual owner approval.

Do not let important work accumulate exclusively in temporary local files or ephemeral agent sessions.

For independently working agents, the lead must maintain a recoverable worker inventory: task, responsible agent, branch, last pushed SHA, dependencies, status, and next action.

The lead must incorporate the workstream's meaningful decision and evidence records into the permanent documentation when integrating it.

Avoid concurrent writes to the shared records branch.

Use a designated lead to reconcile and safely integrate documentation changes.

Never force-push or overwrite another worker's work.

Never alter a frozen or release candidate branch merely to update records.

The goal is ongoing accountability without obstructing productive development.

11. NO LOSS OF HISTORICAL EVIDENCE

Do not delete failed experiments, outdated-but-important investigations, rejected solutions, superseded owner decisions, or historical development records.

Do not claim that all past work was successful.

Do not hide changes to testing requirements or acceptance criteria.

Do not describe results from one SHA as validating a different SHA without evidence establishing that relationship.

GitHub Actions artifacts may expire. Preserve durable conclusions, reproduction information, significant measurements, and evidence references in the repository.

There is no requirement to commit enormous raw logs when a concise, complete technical record is sufficient.

If a communication, diagnostic, or intermediate result was never preserved, identify the resulting uncertainty.

Historical completeness must be honest, not manufactured.

12. TIMESTAMPS AND PROVENANCE

Follow the existing America/New_York timestamp directive.

Use actual system time, not estimated time.

Distinguish:

- Time of the original event.
- Time of the original test.
- Time of the original commit.
- Time of documentation reconstruction.

Clearly mark historical entries reconstructed after the fact.

Preserve original evidence references.

Do not backdate commits or imply that a reconstructed record existed when the original event occurred.

13. VERIFY THAT AN UNINFORMED AGENT CAN RECOVER THE PROJECT

Once the documentation repairs are pushed, perform a simulated fresh-session recovery.

Prefer an independent agent that has not participated in reconstructing the history.

Give that agent only the GitHub repository and the existing session-start instructions.

It must be able to determine:

1. The current Build 25 development state.
2. Active development and integration branches.
3. All significant recent owner decisions and their rationales.
4. Current and recently completed worker assignments.
5. Which audit findings were confirmed, corrected, or rejected.
6. Why each significant correction was necessary.
7. How the recent development branches were integrated.
8. Which changes were validated and on which SHAs.
9. Which long-running simulations are active or complete.
10. What remains blocked or unverified.
11. Which decisions still belong to the owner.
12. The next authorized work in each active workstream.

For a representative selection of recent fixes, require the recovery agent to explain the complete decision-and-evidence chain without any conversational assistance.

If that recovery fails, identify the missing information and repair the documentation.

Do not simply have the original author declare its own records sufficient.

14. REPORT THE RESULTS TO THE OWNER

When the historical recovery is finished, provide a concise status report showing:

- The historical period examined.
- Number of commits, PRs, workstreams, and significant workflow runs reviewed.
- Number of meaningful development events identified.
- Number already fully documented.
- Number requiring historical reconstruction.
- Number successfully reconstructed.
- Number still incomplete or unrecoverable.
- Documentation files updated.
- Repaired recovery entry points.
- GitHub branch and verified remote SHA.
- Independent recovery test result.
- Any outstanding documentation deficiencies.

Use counts, not vague completion percentages.

All detailed records must live in GitHub. Do not rely on the owner-facing report to preserve them.

15. CONTINUE NORMAL DEVELOPMENT

The documentation agent should perform the historical recovery without unnecessarily blocking the main Build 25 workflow.

The main development lead remains authorized to continue existing approved tests, integrations, investigations, and development.

Do not interrupt the MP-05 campaign.

Do not restart completed tests.

Do not alter approved simulation rules, economic behavior, multiplayer authority, or gameplay scope merely for documentation.

No unapproved release, baseline promotion, or Steam upload is authorized.

After historical recovery, continue normal Build 25 development with continuous documentation checkpoints.

16. PERMANENT OWNER EXPECTATION

I run Hot Attic Games with multiple AI development systems and many parallel workstreams.

That is only sustainable if every significant engineering action is recoverable.

I want GitHub to function like an engineering black-box recorder.

If an agent disappears tomorrow, its replacement must be able to determine not only what code was written, but what the original developer observed, which other agents contributed, what evidence influenced the decision, why one solution was selected, why alternatives were rejected, what happened during verification, and precisely what remains to be done.

No important decision should live exclusively inside an AI conversation.

No development branch should contain unexplained significant changes.

No completed worker should disappear without a recoverable record of its work.

No failed experiment should be erased from our institutional knowledge.

Documentation is part of completing the engineering work, not an optional administrative task afterward.

Assign the documentation specialist if appropriate, audit the missing history, repair the authoritative records, commit and push the results, verify independent recovery, and maintain this standard permanently.

Continue approved Build 25 work in parallel wherever safe.

Do not stop at a plan. Execute the authorized recovery.
