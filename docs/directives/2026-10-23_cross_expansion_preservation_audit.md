# Owner directive, 2026-10-23: Cross-expansion preservation audit (Expansions 19-23)

Saved verbatim.

---

MY MEDIEVAL LIFE — CROSS-EXPANSION PRESERVATION AUDIT

Expansions 19, 20, 21, 22, and 23

Project: Hot Attic Games — My Medieval Life
Priority: High
Audit type: Read-only implementation, architecture, and historical reconciliation
Authorization: Audit and documentation only. No implementation, merging, activation, or release.

1. Mission

Before proceeding with further major development, perform a comprehensive cross-expansion audit of Expansions 19–23 against the actual repository.

We have discovered that substantial Settlement Advancement functionality was already delivered in Build 18, even though later planning treated parts of that specification as future work.

We must establish precisely what already exists, what works, what is incomplete, and what is genuinely missing.

The purpose is to preserve completed work and prevent redundant implementation or architectural regressions.

Do not assume that an expansion number indicates an entirely new system.

2. Establish authoritative repository state

Begin by identifying:

- All active development branches and worktrees.
- Released Build 18 source and release provenance.
- Current staging and main commits.
- Expansion 19 merged foundation branch and validation status.
- Expansion 20 foundation commits "1efb59f" and "4d9bc05".
- Expansion 21 civic-records branch and current worker status.
- Existing Expansion 22 and 23 branches, directives, and specifications.
- Historical design decisions, including OD-30.
- All active agents and their assigned work.

Do not modify any active worker's files or branch.

Read-only inspection is permitted while other workers continue.

3. Build a historical implementation inventory

Inspect the relevant commits, releases, tests, directives, and source code from earlier builds through the current development branches.

For every significant system, determine:

1. When it was introduced.
2. Whether it was released.
3. Whether it remains present in current source.
4. Whether it is active, disabled, incomplete, or obsolete.
5. Whether automated tests cover it.
6. Whether later changes replaced or superseded it.
7. Which expansion currently owns future development.

Distinguish between:

- Proposed design.
- Approved design.
- Implemented code.
- Passing tests.
- Enabled gameplay.
- Released functionality.
- Verified in-game behavior.

These are not interchangeable statuses.

4. Expansion 19 — Subjective Judgment

Audit:

- Personality traits and behavioral variation.
- Existing relationship and reputation systems.
- Good/Bad judgment ledgers.
- Trust, familiarity, respect, and romance.
- Gossip and information propagation.
- NPC memory and learning.
- Existing decision hooks.
- Integration with commerce, family, crime, and politics.
- Recent personality and relationship foundation merges.
- Feature flags and deterministic tests.

Determine whether newly merged foundations duplicate earlier systems or extend them correctly.

Identify what remains genuinely unfinished.

5. Expansion 20 — Living Economy

Audit:

- Existing inventories and ownership.
- Currency and transaction services.
- Actor identity and lookup.
- Reservations and economic events.
- Negotiated contracts.
- Household and business finances.
- Employment and wages.
- Supply, demand, and pricing.
- Credit and debt.
- Merchant and regional trade.
- Production and industrial supply chains.
- Save/load and conservation.
- Current foundation test evidence.

Verify the 66 new checks and their relationship to existing suites.

Confirm that the new foundation remains disabled and does not create competing economic state.

Identify any requirements already satisfied by Build 18 or earlier.

6. Expansion 21 — Politics and Civic Authority

Audit:

- Existing village and manor authority.
- Government roles and officeholders.
- Civic careers and historical records.
- Public treasuries.
- Taxes, fines, fees, and public spending.
- Guards, patrols, and criminal investigations.
- Elections and succession.
- Existing law and punishment systems.
- Current civic-records foundation work.

Determine which functions are already real gameplay mechanics and which are only data structures or design requirements.

Preserve all existing government behavior.

7. Expansion 22 — Settlement Advancement Phase 2

Treat released Build 18 as the baseline.

Verify the reported existing functionality:

- Five settlements.
- Regional trade.
- Couriers.
- Migration.
- Worker experience.
- Industrial capability.
- Finite settlement economic resources.
- Retirement of the temporary 30-coin caravan allowance.

For each, inspect actual implementation and tests.

Identify which portions of the original Settlement Advancement specification are complete, partially implemented, or missing.

Preserve the approved design decisions:

E22-OD-01: Hybrid simulation with detailed nearby NPCs and abstract distant settlements.

E22-OD-02: Continuous geography with streamed regions.

Both are design approvals only.

Do not implement streaming, rewrite geography, or replace existing settlement simulation.

Identify how these decisions can extend the current architecture with minimum disruption.

8. Expansion 23 — Bandit Factions and Criminal Careers

Audit existing:

- Theft and stolen-goods mechanics.
- Crime records.
- Guards and enforcement.
- Reputation effects.
- Bandit or hostile NPC behavior.
- Existing faction membership structures.
- Combat and violence.
- Inventory transfer and loot.
- Player criminal actions.
- Travel and settlement interactions.

Determine which components can be reused.

Do not create a separate crime, inventory, reputation, or NPC decision engine.

9. Cross-expansion ownership audit

Produce an authoritative system ownership map.

Pay particular attention to:

- NPC identity.
- Personality and decisions.
- Relationship and reputation records.
- Inventories and ownership.
- Currency and accounting.
- Economic transactions.
- Employment and professional skills.
- Settlements and population.
- Migration and regional travel.
- Government offices and civic finances.
- Crime, law enforcement, and factions.
- Historical records.
- World geography and persistence.
- Decision explanations and diagnostics.

Identify duplicate state, competing implementations, overlapping feature flags, and incompatible assumptions.

One world state. One authoritative owner for each kind of data.

10. Preservation and regression requirements

Identify the automated tests that establish current behavior.

Create a regression-risk matrix showing which existing mechanics could be affected by each planned expansion.

Do not rerun entire test campaigns when valid passing evidence already exists for the same source commit.

Run no tests that modify the repository during this read-only audit.

Identify missing test coverage, but do not implement new tests without authorization.

11. Reconcile expansion numbering

Record the historical assignments and the current proposed roadmap:

- 18: Released Settlement Advancement foundation.
- 19: Subjective Judgment.
- 20: Living Economy.
- 21: Politics and Civic Authority.
- 22: Settlement Advancement Phase 2.
- 23: Bandit Factions and Criminal Careers.
- 24: Legacy, proposed reassignment.

Preserve the history of OD-30.

Do not rewrite historical decisions as though the current numbering was always in place.

Identify any numbering changes that still require explicit confirmation.

12. Required deliverables

Produce one consolidated report containing:

1. Executive summary.
2. Repository and branch inventory.
3. Historical implementation timeline.
4. Expansion 19 capability matrix.
5. Expansion 20 capability matrix.
6. Expansion 21 capability matrix.
7. Expansion 22 capability matrix.
8. Expansion 23 capability matrix.
9. Cross-expansion authoritative ownership map.
10. Duplicate or overlapping implementation findings.
11. Regression-risk matrix.
12. Existing test evidence and coverage gaps.
13. Requirements already completed in earlier builds.
14. Genuine remaining development work.
15. Recommended development sequence.

For each capability, include exact source files, relevant commits, tests, and evidence.

Clearly label conclusions as verified, partially verified, or unverified.

13. Final instructions

Do not implement anything during this audit.

Do not merge, activate feature flags, publish builds, or modify active worktrees.

Do not automatically open new development assignments based on audit findings.

Return the report for owner review before authorizing further integration.

Preserve what already works. Extend existing systems. Never rebuild a working mechanic simply because it appears in a newer expansion specification.
