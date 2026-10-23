# Owner directive, 2026-10-23: Expansion 20 Living Economy, development authorization phase 1

Saved verbatim.

---

MY MEDIEVAL LIFE — EXPANSION 20

Living Economy — Development Authorization, Phase 1

Project: Hot Attic Games — My Medieval Life
Expansion: 20 — Living Economy
Primary specification: Living Economy Expansion — Owner Design Specification, October 20, 2026
Immediate assignment: LE-00 architecture audit, requirements registration, and LE-01 foundation preparation.

1. Mission

Begin authorized development preparation for Expansion 20 while preserving the existing game, ongoing Expansion 19 work, and all approved owner decisions.

The goal is to develop a genuinely living medieval economy in which individuals, households, businesses, merchants, and institutions respond independently to their needs, available resources, knowledge, opportunities, and constraints.

A village is allowed to fail. The simulation is not.

We are not building a scripted economy that guarantees prosperity.

2. Authority and boundaries

You are authorized to:

- Inspect the existing repository and economic architecture.
- Complete the LE-00 audit.
- Register Expansion 20 requirements and dependencies.
- Identify existing functionality that can be reused.
- Prepare data contracts and migration plans.
- Create isolated, backward-compatible foundation components where requirements are settled.
- Write focused tests for those components.
- Commit and push approved work to an appropriate remote development branch.

You are not authorized to:

- Enable the new economy in live gameplay.
- Rewrite the existing NPC decision system.
- Activate Expansion 19 Judgment.
- Change established economic balancing without approval.
- Invent gameplay policies for unresolved owner decisions.
- Merge into staging or main without authorization.
- Publish a release or create a distributable playtest build.
- Modify another worker's active branch or overwrite uncommitted changes.

3. First action: repository and worker-state audit

Before editing anything:

1. Identify the current repository, branches, commits, and active worktrees.
2. Determine which workers are currently modifying Expansion 18, 19, or other systems.
3. Confirm the authoritative Expansion 20 specification exists in the repository.
4. Locate the existing Interlocking Systems Manifest, requirements register, decision records, and recovery handoff.
5. Inspect the current economic services and their actual ownership of state.
6. Identify existing feature flags, persistence formats, simulation tests, and performance budgets.

Do not assume the earlier design documents accurately describe the current implementation.

If the specification is absent, report that and request the source document. Do not recreate it from memory.

4. LE-00: Cross-system architecture audit

Trace the actual flow of goods, money, needs, and decisions through:

- NPC goals, planning, schedules, and decision-making.
- Individual and household inventories.
- Business and workshop inventories.
- Ownership, custody, reservations, and transfers.
- Currency, credit, debts, and accounting.
- Market prices, buying, selling, and negotiation.
- Production recipes, material shortages, and accepted orders.
- Employment, skills, wages, and job switching.
- Housing and construction.
- Manor treasury and institutional spending.
- Caravans, merchants, and external trade.
- Bandit inventories and stolen goods.
- Farming, forestry, mining, and finite resources.
- Settlement and regional economic interfaces.
- Save/load, deterministic replay, and simulation diagnostics.
- Expansion 19 Judgment interfaces, with the judgment hook remaining OFF.

For each subsystem, document its authoritative data owner, existing interfaces, missing functionality, integration risks, and required dependencies.

Do not create a second authoritative inventory, ledger, or NPC brain.

5. LE-01: Shared economic foundation

After LE-00, identify what is already implemented and what remains necessary for the following records:

Record| Required responsibility
Economic Actor| Identity, ownership, resources, location, obligations, capabilities
Need| Desired outcome, shortfall, urgency, deadline, alternatives
Knowledge| Known offers, suppliers, source, age, confidence
Offer| Buyer, seller, item, quantity, price, terms, expiration
Contract| Parties, obligations, delivery, payment, breach
Reservation| Earmarked stock without changing physical ownership
Credit| Lender, borrower, principal, terms, repayment, default
Economic Event| Timestamped, deterministic economic occurrence
Ledger Integration| Accountable movement of money, goods, debt, and ownership

Reuse and extend existing structures wherever possible.

Do not implement a parallel economic architecture simply because it is easier than integrating the existing one.

6. Authorized isolated implementation

Where gameplay policy is already settled and existing architecture supports it, implement small, reusable foundation improvements behind disabled integration hooks.

Prioritize:

1. Stable identifiers and data contracts.
2. Ownership and inventory integrity.
3. Safe reservation and release behavior.
4. Offer and contract lifecycle representations.
5. Persistence and save compatibility.
6. Deterministic ordering.
7. Diagnostics that explain economic decisions.

Do not implement adaptive price behavior, loans, wage policies, market manipulation, business founding, or government intervention until their relevant owner decisions are resolved.

Any new foundation component must have a clear consumer and avoid duplicating existing functionality.

7. Mandatory economic principles

Preserve these requirements throughout development:

- Needs drive economic decisions.
- Every actor has bounded knowledge.
- Prices are offers, not automatic transactions.
- Trade requires agreement and the ability to perform.
- Resources, currency, labor, and time are finite.
- NPCs can decline profitable opportunities.
- NPCs can make mistakes.
- Contracts create real obligations.
- Household and business ownership must remain distinguishable.
- Supply shortages can cause business failures.
- Caravans cannot create unlimited demand or purchasing power.
- No hidden resources or emergency currency appear to save the village.
- The player follows the same underlying economic rules as NPCs.
- Existing Judgment integration must remain optional and disabled.

8. Expansion 19 compatibility

Expansion 19 is responsible for subjective judgment, personality, trust, and relationship-influenced decisions.

Expansion 20 must own economic needs, offers, transactions, obligations, and economic consequences.

The two systems must eventually interact without competing for ownership of decisions or data.

Document the interface between them, but do not enable it or make assumptions about unfinished Expansion 19 mechanics.

9. Tests and performance

Use narrowly targeted tests for actual changes.

Required foundation checks include:

- No duplicated or missing money.
- No duplicated or missing inventory.
- No double-spending reserved stock.
- No impossible contract fulfillment.
- Deterministic record ordering.
- Correct save/load restoration.
- No new behavior when integration hooks are OFF.
- No unbounded processing queues or population-wide per-frame scans.

Reuse relevant passing tests and existing CI evidence when the source commit is unchanged.

Do not rerun entire simulation campaigns or all platform exports merely for reassurance.

10. Preserve all open owner decisions

Register the existing OD-LE-01 through OD-LE-15 decisions from the specification.

For each decision, report:

- Current status.
- What the existing game already does.
- Whether the decision blocks current foundation work.
- Recommended default, if appropriate.
- Consequences of alternative choices.

Do not silently approve your own recommendations.

Group genuinely blocking questions together. Do not interrupt work for trivial implementation details.

11. Work management and context recovery

Keep Expansion 20 on an isolated, remotely preserved development line.

- Make logical commits at meaningful milestones.
- Push completed work to GitHub.
- Maintain a concise recovery handoff.
- Record current branch, commit, completed work, test evidence, active workers, and next actions.
- Update recovery state before approaching approximately 80% context usage.
- Avoid excessive parallel agents and unnecessary token consumption.
- Do not create release artifacts.

12. First deliverable

Return a concise but complete Expansion 20 LE-00 Readiness Report containing:

1. Current branch and worker safety status.
2. Architecture and authoritative data-owner map.
3. Existing features that already satisfy Expansion 20 requirements.
4. Missing foundational capabilities.
5. Dependencies and integration risks.
6. LE-01 implementation tasks ranked by priority.
7. Owner decisions that actually block the next stage.
8. Changes made, with commit IDs.
9. Focused test results and reused evidence.
10. Recommended next development assignment.

13. Execution instruction

Begin LE-00 now.

Continue through requirements registration and any safe, isolated foundation work that does not depend on unresolved gameplay policy.

Do not stop merely because the audit is complete if useful, authorized, nonconflicting foundation work remains.

Do not begin the full living-economy integration until I approve the architecture and material gameplay decisions.

The objective of this assignment is to leave Expansion 20 with a verified architecture, registered requirements, protected development branch, and a useful tested foundation ready for the next phase.

A village is allowed to fail. The simulation is not.
