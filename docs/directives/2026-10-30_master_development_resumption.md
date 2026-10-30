MY MEDIEVAL LIFE — MASTER DEVELOPMENT RESUMPTION DIRECTIVE

Date: October 30, 2026
Baseline: Build 24 / Expansion 20 checkpoint
Development status: Authorized to resume
Operating mode: Coordinated parallel development with bounded autonomy

1. OWNER AUTHORIZATION

I am formally lifting the October 28 development pause on My Medieval Life.

Resume active development immediately, using the latest verified repository state, recovery handoff, decision register, and Build 24 checkpoint.

You are authorized to:

- Implement approved features and resolve ordinary engineering details independently.
- Start and coordinate parallel development workers.
- Create branches, commit, push, open draft PRs, and run appropriate tests.
- Integrate completed work after validating dependencies and resolving conflicts.
- Produce Android, Windows, and Linux private draft playtest releases when appropriate.
- Fix defects discovered during implementation, testing, and simulation.
- Continue through successive approved development phases without requiring a new instruction after every completed task.

Do not publicly publish releases, promote anything to Steam, or undertake unapproved expansions.

My lack of recent playtesting is not a development blocker. I had classes this week and will playtest Build 24 when my schedule permits.

Do not repeatedly ask whether you should continue. This directive is authorization to proceed through the approved work described below.

2. PRIMARY OBJECTIVES

Run three coordinated workstreams in parallel:

Workstream A — Expansion 20 Living Economy

Complete LE-03 through LE-07 and all necessary dependencies, validation, calibration, and integration work.

Workstream B — Settlement-to-Settlement Food Trade

Implement the previously approved X20-SETTLE-FOOD functionality using legitimate economic transactions and existing settlement mechanics.

Workstream C — Multiplayer Batch D

Resume the previously paused multiplayer work, including internet connectivity, joining interfaces, connection recovery, cross-platform compatibility, and required integrity checks.

Use separate branches and clearly assigned ownership.

One worker must not overwrite another worker's implementation.

Before parallel implementation, identify shared interfaces, data structures, save formats, and likely merge conflicts.

Establish interface contracts so each worker can progress independently.

Do not serialize independent work unnecessarily.

3. AUTONOMOUS DECISION-MAKING

I do not want development stopping every ten minutes because of a small implementation question.

Use the following decision hierarchy:

1. Explicit owner decisions already recorded in the repository.
2. Approved design specifications and acceptance criteria.
3. Existing game architecture and established conventions.
4. Behavior already demonstrated by working systems.
5. Conservative engineering judgment consistent with the game's design.

If an implementation question can be answered through these sources, answer it yourself and continue.

For ordinary details such as method selection, data structures, internal naming, UI spacing, error handling, test organization, performance optimizations, and equivalent implementation approaches, make a reasonable decision.

Record meaningful decisions in the development register.

Do not ask permission for routine engineering work.

Escalate only when a decision would:

- Contradict a previously approved design rule.
- Fundamentally change gameplay or the economic model.
- Introduce a recurring paid service or meaningful financial commitment.
- Create an irreversible data migration or unacceptable save-loss risk.
- Require a significant new architectural direction outside approved scope.
- Require public publication.
- Present multiple materially different gameplay outcomes that existing owner decisions do not resolve.

When escalation is necessary, consolidate related questions into one decision package, explain the alternatives, recommend a default, and continue all independent work while awaiting an answer.

Never leave the entire project idle because one worker encounters a question.

4. WORKSTREAM A — LIVING ECONOMY

Resume from the existing LE-02 implementation.

Follow the established LE-03 through LE-07 specifications and acceptance criteria. Do not replace those specifications with a newly invented economic design.

LE-03: Transaction integrity and economic participation

The highest-priority issue is eliminating competing purchasing paths that can independently consume the same money or goods.

Establish one authoritative economic transaction mechanism wherever the approved design requires it.

The implementation must prevent:

- Duplicate purchases.
- Double spending.
- Negative inventory caused by competing transactions.
- Currency or items being created or destroyed unintentionally.
- Ownership inconsistencies.
- Stale offers completing after their goods or funding become unavailable.
- Partial transfers that leave buyers and sellers in inconsistent states.

Use atomic transactions or equivalent validated commit/rollback semantics.

Household budgets, production decisions, food bids, negotiated labor, services, and job choice must follow their approved specifications.

Preserve existing negotiated quantity-based procurement contracts. Do not replace them with mandatory fixed wages or arbitrary centralized pricing.

LE-04 through LE-07

Continue in documented dependency order.

Preserve the existing design for production, market participation, economic choices, settlement behavior, and calibration.

Where specifications contain provisional numerical values, retain them as provisional until evidence supports calibration.

Do not silently change economic constants simply to make simulations look healthier.

Activation policy

I authorize automatic activation of the completed Living Economy once all documented acceptance tests, integration checks, required simulations, and integrity checks pass.

Activation must be based on objective readiness, not merely completion of code.

Before activation:

- Verify there is no second uncontrolled buying path.
- Confirm conservation of goods and currency, allowing only documented legitimate sources and sinks.
- Verify save/load and deterministic replay where applicable.
- Verify migration compatibility with existing saves.
- Complete the required long-run economic calibration.
- Confirm all mandatory dependencies are integrated.
- Confirm there are no unresolved critical defects.

Keep the economy disabled while these conditions remain unmet.

Once they are met, you may activate it without asking me again, provided activation does not require destructive migration or contradict an existing owner decision.

Record the exact activation commit, evidence, and configuration.

5. ECONOMIC FAILURE IS PERMITTED

The world must remain a living simulation.

Do not introduce invisible rescue systems, artificial prosperity, automatic treasury refills, free food, guaranteed employment, or economic rubber-banding merely to prevent failure.

Settlements may decline or collapse.

Residents may become poor, migrate, starve, or die as consequences of the simulated economy.

These outcomes are not automatically bugs.

However, distinguish legitimate emergent failures from software defects.

Examples:

Permitted outcomes

- A settlement loses its population because it cannot sustain food production.
- Businesses fail because nobody buys their goods.
- A household cannot afford necessities.
- Trade routes fail to supply a settlement.
- Wealth concentrates through legitimate transactions.

Defects requiring investigation

- Money disappears without an authorized transaction or sink.
- Food exists and is available, but a broken market path prevents legitimate purchases.
- Inventories become negative.
- A seller receives payment without delivering goods.
- Agents make impossible decisions because of corrupted state.
- A settlement fails because an intended system never executes.

Do not alter the game's philosophy to improve a success percentage.

Measure the outcomes and identify their actual causes.

6. WORKSTREAM B — INTERSETTLEMENT FOOD TRADE

Implement the already approved settlement-to-settlement food trading functionality.

This is not a settlement rescue mechanism.

It is a legitimate economic opportunity.

Requirements:

- Settlements must obtain food through real production, ownership, negotiation, purchase, transport, and delivery.
- Goods and currency must be accounted for.
- Trade must respect availability, affordability, and the established economic rules.
- Do not teleport goods or invent supply to meet demand.
- A settlement may fail if it cannot secure enough food.
- Traders and settlements must not bypass the authoritative transaction process established in LE-03.
- Handle unavailable stock, failed negotiations, insufficient funds, interrupted delivery, and other realistic failure cases.
- Prevent duplicate delivery or payment after retries, save/load, or interruptions.

Coordinate with the Living Economy worker before implementing shared transaction interfaces.

If necessary, develop the independent settlement logistics first and integrate the final transaction mechanism when LE-03 is ready.

Do not create a third purchasing system.

7. WORKSTREAM C — INTERNET MULTIPLAYER

Resume Multiplayer Batch D.

Internet multiplayer is mandatory.

The desired player experience is:

Primary method: Simple joining through invite codes or an equivalent user-friendly joining mechanism.

Advanced method: Direct-IP joining remains available.

The normal player should not need to understand router configuration, IP addresses, or port forwarding just to join a friend's game.

Connectivity architecture

Investigate the simplest reliable architecture that supports internet play.

Prefer free or low-cost approaches that do not create unnecessary recurring expenses.

If a hosted coordination service, relay, or external infrastructure is necessary, evaluate its costs, limits, reliability, and privacy implications before committing to a paid dependency.

Do not pretend an invite code provides internet connectivity unless the networking architecture actually supports connecting across different networks.

Document NAT traversal limitations, relay requirements, and realistic fallback behavior.

Multiplayer functionality

Preserve all previously approved multiplayer behavior, including player identity, relationships, marriage, heirs, succession, host authority, guest persistence, and player-to-player interaction.

Implement and validate:

- Hosting and joining interfaces.
- Invite creation and joining.
- Direct-IP advanced connection.
- Connection timeouts and meaningful errors.
- Android app suspension and connection drops.
- Guest disconnection and reconnection.
- Host disconnection.
- Duplicate or delayed network messages.
- Save integrity during network interruptions.
- Correct authoritative state reconciliation.
- Prevention of duplicate inventory, currency, and transactions.
- Existing guest permissions and ownership rules.
- Cross-platform compatibility.

Do not silently change the game's social, political, or inheritance rules to accommodate networking.

Platform coverage

Target Android, Windows, and Linux, including the existing Steam Deck requirement.

The previous Linux-to-Linux connection test is not sufficient evidence for full multiplayer readiness.

Build a cross-platform verification matrix and identify what can be automated versus what requires physical devices or real external networks.

Do not claim hardware or internet connectivity was verified when only simulated or local tests were performed.

Use realistic network-fault simulations where actual device coverage is unavailable.

8. BUILD 24 AND PLAYTEST POLICY

Build 24 remains the current owner playtest baseline.

I have not yet playtested it.

Do not block development waiting for my feedback.

Preserve Build 24 as a reproducible checkpoint.

Continue development on appropriate branches.

Future private draft builds may be prepared when a meaningful milestone is reached and the relevant packaging checks pass.

Do not generate a new build after every trivial change.

When I eventually report Build 24 issues:

- Reproduce and classify them.
- Determine whether later development already resolves them.
- Apply fixes to the appropriate active branch.
- Avoid overwriting newer work with an outdated patch.

Maintain compatibility with existing saves wherever feasible.

For any migration with meaningful risk, provide a backup and recovery strategy.

9. PARALLEL DEVELOPMENT COORDINATION

Before launching workers:

1. Read "docs/handoffs/X20_RECOVERY_HANDOFF.md".
2. Inspect the current decision register.
3. Verify the actual repository state.
4. Identify the authoritative integration branch.
5. Establish ownership boundaries.
6. Identify shared interfaces and dependency sequencing.
7. Record each worker's task and expected deliverables.

Use one coordinating agent responsible for integration and progress tracking.

Workers should have bounded assignments with clear completion criteria.

Where one worker is blocked by another, redirect it to independent tasks rather than allowing it to sit idle.

Integrate completed work incrementally when safe.

Do not allow multiple workers to edit the same critical systems without an explicit coordination plan.

10. TESTING AND SIMULATION POLICY

Use GitHub Actions for long-running simulations and tests.

Do not rely on an idle cloud container to complete long jobs when the environment may be reclaimed.

Avoid redundant testing.

If an exact commit already has passing, relevant CI evidence, reuse it.

Do not repeat entire suites simply for reassurance.

When code changes invalidate previous evidence, rerun only the necessary checks, followed by the appropriate integration gates.

Use broader simulation campaigns at meaningful milestones, not after every minor commit.

Required simulation principles

Simulations must examine:

- Economic conservation and transaction integrity.
- Production and consumption.
- Household solvency and budgets.
- Employment and job changes.
- Food availability and legitimate trade.
- Settlement migration and collapse.
- Market pricing and purchasing.
- Long-term population and economic stability.
- Save/load and determinism.
- Multiplayer state consistency and interruption recovery.

Report actual outcomes, including failures.

Do not tune the world to guarantee prosperity.

A failed settlement is not the same as a failed simulation.

Clearly distinguish expected emergent behavior from defects and acceptance-gate failures.

Record seeds, configurations, source commits, runtime, and relevant metrics.

11. REGISTER AND REPOSITORY HOUSEKEEPING

Correct stale development-register entries that incorrectly show already implemented work as not started.

Preserve the historical decision trail.

Review stale PRs #2 and #3.

Verify their changes are fully represented in the current integrated code before closing them.

If superseded, close them with an explanation referencing the replacement commits or branches.

Do not merge stale PRs merely to make the PR list clean.

Keep Expansion 21 politics isolated and on hold unless its work is explicitly required by an already approved dependency.

Do not begin Expansions 22–27.

12. CONTINUOUS PROGRESS AND REPORTING

Do not stop after completing the first task and ask, "What would you like me to do next?"

Proceed through the authorized work.

When a worker finishes:

- Validate its deliverables.
- Integrate when safe.
- Assign the next approved dependency or independent task.
- Update the register and recovery handoff.
- Continue.

Provide progress reports at meaningful milestones rather than requiring me to respond to every status update.

Each report should identify:

- Completed work and commit references.
- Active workers and tasks.
- Test results.
- Defects found and fixed.
- Remaining dependencies.
- Next planned work.
- Genuine owner decisions, if any.

Progress reports are informational unless an actual owner decision is necessary.

Maintain a current recovery handoff so development can resume after context compaction or session interruption.

Preserve enough detail that a new session can recover without reconstructing the project from memory.

13. RELEASE AUTHORITY AND BOUNDARIES

You may:

- Commit and push development changes.
- Run CI and simulations.
- Integrate approved work after validation.
- Prepare and upload private draft releases for Android, Windows, and Linux.
- Maintain release notes, checksums, and build provenance.

You may not:

- Publish a release publicly.
- Upload or publish to Steam.
- Introduce paid infrastructure without approval.
- Perform destructive migrations without approval.
- Override settled owner design decisions.
- Begin unrelated expansions.
- Misrepresent untested features as verified.

A pushed source commit is not an installable build.

When reporting a new playtest build, provide the actual private draft release and platform download links.

14. IMMEDIATE EXECUTION ORDER

Begin now.

Phase 1 — Recovery and coordination

Quickly confirm the Build 24 baseline and existing handoff, establish branch ownership, and launch the three authorized workstreams.

Do not repeat the full recovery audit unless repository evidence contradicts the October 30 report.

Phase 2 — Parallel implementation

Start LE-03, intersettlement food-trade development, and Multiplayer Batch D.

Resolve shared-interface dependencies early.

Keep the Living Economy disabled until its acceptance requirements are met.

Phase 3 — Incremental integration

Validate and integrate completed approved work.

Continue through LE-04 to LE-07 and remaining Batch D requirements as dependencies permit.

Use meaningful checkpoints and existing test evidence.

Phase 4 — Full validation and calibration

Run the necessary long-form simulations, integrity checks, cross-platform tests, and economic calibration.

Fix genuine defects.

Do not conceal legitimate economic failures.

Phase 5 — Activation and private playtest

Activate the Living Economy once its complete objective readiness criteria pass.

Prepare a new private draft playtest build when an appropriate integrated milestone is reached.

Keep all public-release controls unchanged.

FINAL OWNER INSTRUCTION

I want My Medieval Life actively progressing again.

You have authority to make normal engineering decisions, coordinate workers, resolve ordinary defects, and continue through approved development tasks without waiting for repeated permission.

Respect the established design, especially the principles of a living economy, meaningful individual choice, legitimate transactions, and natural consequences.

Do not interrupt development for minor details.

Do not waste time rerunning tests that already have valid evidence.

Do not invent new gameplay rules to solve implementation difficulties.

Start the coordinated development work now, keep moving, and bring me substantive results rather than a new permission request every ten minutes.
