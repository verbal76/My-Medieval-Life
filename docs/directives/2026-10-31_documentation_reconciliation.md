# Owner directive 2026-10-31: documentation reconciliation and owner-decision protection

Verbatim, as received in the coordinating session on 2026-10-31. Register: DOC-RECON-01. Branch: wip/requirements-control (isolated; REQ-CTRL-02).

---

MY MEDIEVAL LIFE — DOCUMENTATION RECONCILIATION AND OWNER-DECISION PROTECTION

Owner directive

I want the entire My Medieval Life documentation system brought up to date.

We have spent considerable time designing expansions, making decisions, revising systems, and implementing features. I do not want an older design document, outdated roadmap, stale requirements entry, or historical development note causing you or another agent to reverse an approved decision or rebuild something that already exists.

The latest explicit owner decision takes precedence over all older documentation, regardless of which branch contains it.

This is an authorized documentation-maintenance task. It is not authorization to begin new expansion development.

1. Audit all documentation across branches

Examine the complete documentation history, including:

- "staging/my-medieval-life"
- "wip/expansion20"
- "wip/expansion21-preparation"
- "wip/roadmap-docs"
- "wip/x20-trader-inv"
- "wip/juice-assessment"
- Other branches containing relevant design decisions, requirements, or implementation records.

Include the requirements register, owner directives, expansion specifications, roadmaps, development handoffs, implementation notes, test reports, and historical documents.

Do not assume that the newest commit contains the newest owner decision. Compare the actual dates and contents of the decisions.

2. Reconcile every expansion document

For Expansions 17 through 27, plus multiplayer and standalone approved systems:

1. Identify every planned feature and requirement.
2. Determine whether it is implemented, partially implemented, approved but unimplemented, deferred, superseded, or awaiting an owner decision.
3. Verify implementation against actual source code and tests, not just an agent's completion statement.
4. Update the corresponding design document to reflect its current status.
5. Mark completed requirements clearly as IMPLEMENTED, including the relevant implementation reference and validation evidence.
6. Mark partially completed requirements with what is finished and what remains.
7. Mark superseded requirements as SUPERSEDED, identifying the newer decision.
8. Preserve approved but unimplemented requirements for future development.
9. Do not mistake missing tests for missing functionality, or existing code for validated functionality.

Use a consistent status system throughout the repository.

Do not delete implemented features from the historical record. Mark them complete so future agents understand what was planned, what was built, and what remains.

3. Establish owner-decision precedence

Apply this hierarchy when documents disagree:

1. Latest explicit owner decision.
2. Later owner-approved amendments and clarifications.
3. Current approved expansion specifications.
4. Earlier approved specifications.
5. Historical proposals, agent recommendations, and superseded plans.

A newer agent recommendation never overrides an explicit owner decision.

An older document does not become authoritative merely because it is located on the active branch.

If two owner decisions genuinely conflict and the later ruling cannot be established, flag the conflict for my review. Do not choose one arbitrarily.

Known examples

- Mayor terms: Four-year terms end early only through death or permanent absence. No automatic impeachment or recall. Misconduct affects reputation, support, and future elections.
- Expansion sequence: 20 → 21 → 23 → 22 → 24 → 25 → 26 → 27.
- Expansions 22–27: Do not begin implementation without explicit authorization.
- Deferred features: Go-between buying and dislike-driven migration remain deferred.
- Weather and creatures: Review the later owner decision to design Expansions 25 and 26 together as the Wild World concept. Preserve the distinction between expansion numbering, combined design scope, and actual implementation authorization.

These examples are not an exhaustive list. Search the full decision history.

4. Protect our current build sequence

Our current development plan is:

Build 25 — Expansion 20 validation and freeze

The currently validating "wip/expansion20" source becomes the frozen Build 25 baseline only after its validation passes and I approve the results.

Build 26 — Repository recovery and consolidation

Create a separate experimental integration branch from the exact frozen Build 25 SHA. Recover the relevant stranded work, reconcile the branches, validate the integrated result, and freeze Build 26 after my approval.

Build 27 — Resume expansion development

Begin Expansion 21 only after Build 26 is validated and frozen and I explicitly authorize implementation.

Do not confuse build numbers with expansion numbers.

Important execution restriction

You may update documentation now in an isolated documentation branch or worktree, without disturbing the running validation.

Do not modify the validating Build 25 source, merge into its branch, change its commit, cancel its tests, or interfere with its freeze.

Do not perform the Build 26 integration or begin Expansion 21 as part of this documentation task.

5. Reconcile the requirements register

The audit identified a 1,038-record register on staging and a 789-record version on Expansion 20.

Reconcile them without losing newer requirements or implementation evidence.

Correct outdated statuses, including the previously identified EXP-B, EXP-D, GP-POLISH, B19-RECOVERY, SJD-H, LE-05, and ID-01 records, based on actual evidence.

Register missing approved decisions, expansion phases, and open questions where appropriate.

Preserve original requirement IDs. Do not silently renumber or duplicate them.

Explicitly distinguish:

- Approved and implemented
- Approved and partially implemented
- Approved and not implemented
- Design only / not authorized
- Deferred
- Superseded
- Open owner decision

6. Preserve the original expansion specifications

Some comprehensive expansion specifications were developed outside the repository and subsequently supplied to development sessions.

Do not assume an incomplete repository copy represents the complete owner-approved design.

In particular, account for the original Weather, Seasons & Disasters and Creatures & Heroes design packets, the master expansion roadmap, settlement advancement specifications, and other owner-supplied documents.

If an original document is not accessible, record it as a missing source requiring recovery. Do not reconstruct its contents from assumptions or declare its features unapproved merely because the file is absent.

7. Update the documentation itself

I do not want only another audit report.

Actually correct the outdated documents on the isolated documentation branch.

For each expansion, provide:

- Current approved scope
- Implemented features
- Partially implemented features
- Remaining approved work
- Deferred and superseded requirements
- Outstanding owner decisions
- Dependencies
- Current implementation and validation references
- Next authorized development phase

Update the master roadmap, requirements register, project memory, and recovery handoffs to agree with these records.

Clearly label historical documents so future agents cannot mistake them for current instructions.

Maintain traceability to the original decisions rather than erasing their history.

8. Acceptance criteria

Before declaring the documentation reconciliation complete:

1. No known outdated owner decision is presented as current.
2. No verified implemented feature is incorrectly listed as entirely unimplemented.
3. No deferred or unauthorized feature is listed as ready for implementation.
4. Every remaining expansion has a clearly identified current design status.
5. Conflicting or missing owner decisions are explicitly listed rather than guessed.
6. The master roadmap and requirements register agree.
7. Future development agents have one clear, authoritative documentation entry point.
8. The running Build 25 validation remains completely untouched.

Run only documentation consistency checks and narrowly relevant verification. Do not start another full game simulation or CI campaign for documentation changes.

9. Report back

When finished, give me:

- The documentation branch and commit SHA.
- Which files were updated.
- How many requirements changed status.
- How many were confirmed implemented, partially implemented, deferred, or superseded.
- Which owner decisions were corrected.
- Which original documents are still missing.
- Any genuine contradictions requiring my decision.
- Confirmation that Build 25 validation was not disturbed.

The purpose is to preserve our development history accurately so we can move forward without repeatedly reopening decisions or rebuilding completed systems.

Proceed with the isolated documentation reconciliation. Do not merge it into the frozen or validating gameplay baseline without my authorization.
