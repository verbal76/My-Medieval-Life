Owner directive, 2026-10-24, verbatim.

MY MEDIEVAL LIFE — MULTIPLAYER BATCH C EXECUTION AND G2 VERIFICATION

Continue the approved multiplayer development schedule on "wip/multiplayer-b19", currently at commit "805a1c9".

Batch A1, A2, and B are complete. Gates G0 and G1 have passed. Batch C is underway.

Do not restart completed work, reopen settled decisions, or repeat passing test campaigns without a technical reason.

1. Primary Objective

Complete Batch C: full multiplayer gameplay parity.

Every connected player must function as an independent individual within the same persistent, host-authoritative world while participating in the existing economic, social, family, criminal, political, and survival simulations.

Multiplayer must extend existing gameplay systems rather than create simplified parallel versions.

Preserve all existing single-player behavior and deterministic results.

2. Required Implementation

Individual player identity and reputation

- Each player maintains independent relationships with every NPC.
- Separate Good and Bad reputation ledgers by player identity.
- Preserve existing witness, family, rivalry, association, and reputation propagation mechanics.
- Track crimes, notoriety, investigations, and legal consequences independently.
- Never attribute one player's actions to another without an established in-game reason.
- NPCs evaluate each player independently using the existing weighted decision framework.

Families, inheritance, and ownership

- Guests may establish relationships, court, marry, have families, and produce heirs.
- Family ownership references persist across generations.
- Property, debts, inventory, businesses, and obligations remain attached to their rightful owners.
- Apply the same succession rules to hosts and guests.
- Support multiple independent player families within one world.
- Prevent ownership collisions and inheritance duplication.

Full gameplay parity

Audit every existing player action and verify that guests can perform it under the same rules as the host.

Include:

- Gathering, mining, farming, crafting, construction, and production.
- Trading, purchasing, selling, negotiated contracts, and employment.
- Inventory, equipment, currency, property, and ownership.
- Relationships, marriage, family, inheritance, and succession.
- Crimes, witnessing, guards, investigations, punishment, and notoriety.
- Quests, rewards, objectives, and progression.
- Combat, injury, death, and survival.
- NPC interactions, dialogue, and economic participation.

Do not introduce guest-only shortcuts or alternative simulation rules.

Host authority and synchronization

The host remains authoritative over world state.

- Validate guest actions against existing gameplay rules.
- Prevent duplicated transactions, inventory, currency, rewards, or resources.
- Resolve competing actions deterministically.
- Handle disconnects during transactions without partial application.
- Preserve guest identity and state through reconnection and host restart.
- Prevent simultaneous sessions from controlling the same player identity.

3. Save Migration

Implement migration from Build 20 saves to the multiplayer-compatible structure.

Requirements:

1. Preserve all existing player, NPC, world, economic, relationship, criminal, family, and ownership data.
2. Map the original single-player character into the appropriate persistent player identity.
3. Preserve existing deterministic behavior.
4. Make migration idempotent.
5. Verify save, reload, restart, and reconnection behavior.
6. Never silently discard incompatible data.

If migration cannot safely preserve existing state, stop and report the exact problem.

4. G2 Verification

Complete the approved per-system multiplayer verification matrix.

Test at minimum:

- Two independent players interacting with the same NPC.
- Different NPC opinions toward each player.
- One player committing a crime while another remains innocent.
- Separate quests and rewards.
- Independent marriages and family succession.
- Shared economic transactions without duplication.
- Simultaneous attempts to acquire the same limited resource.
- Guest death, inheritance, and reconnection.
- Disconnect during a transaction.
- Host save and restart with multiple persistent players.
- Migration of an existing Build 20 save.
- Preservation of the established single-player determinism baseline.

Reuse existing passing evidence from "805a1c9" where applicable. Run new or affected tests for Batch C, not redundant full campaigns.

G2 cannot pass if multiplayer correctness requires changing established single-player simulation results.

If any test fails, identify the actual cause, repair it, and rerun the affected checks.

5. Outstanding Design Decisions

These are nonblocking unless implementation reaches a genuine dependency.

Smithy wall and bandit campfire: Keep as separate visual tasks. Do not interrupt Batch C.

Hue and cry: Use local audible propagation through witnesses and existing communication mechanics. The village bell carries farther but does not instantly inform every NPC regardless of distance.

Known killers and shops: Do not implement automatic universal refusal. Existing NPC judgment, personal reputation, necessity, risk, scarcity, and economic incentives determine willingness to transact.

Five simulation warning thresholds: Establish proposed thresholds from measured baseline performance and simulation behavior. Present the evidence and recommendations for owner approval before finalizing them.

Do not invent additional gameplay policies to fill perceived gaps.

6. Development Discipline

- Continue on the existing multiplayer branch.
- Preserve all completed Batch A and B functionality.
- Avoid unnecessary architectural rewrites.
- Do not launch redundant parallel agents.
- Do not perform unrelated visual polishing.
- Do not publish builds or merge into "main" without authorization.
- Maintain the PR checklist and development handoff.
- Record exact commit hashes and relevant verification evidence.
- Preserve recovery documentation before context compaction, which has been occurring around 80% usage.
- Prioritize completing functional work over generating extensive reports.

If a genuine design decision blocks implementation, ask one focused question with the available options and their consequences.

7. Completion Report

When Batch C is finished, provide:

1. Exact branch and commit.
2. Completed gameplay systems and any remaining exceptions.
3. Save migration results.
4. Multiplayer isolation and synchronization results.
5. Single-player determinism comparison.
6. Test counts, failures, and final status.
7. G2 pass/fail determination.
8. Remaining risks, particularly those requiring real-device testing.
9. Next scheduled multiplayer batch and its prerequisites.

Update PR "verbal76/My-Medieval-Life#3" with the verified results.

Do not mark G2 passed based solely on an agent's summary. Independently verify the required evidence on the exact completed commit.

Proceed with Batch C now. Do not stop for routine status updates or previously answered questions. Complete the approved work, verify it, and report the outcome.
