# Owner decisions, 2026-10-20: OD-18, player and villager system parity

Saved verbatim. Register: OD-18 (answered), PAR-00 (the central rule), PAR-01..PAR-05 (the five decisions), and OD-15
(resolved by PAR-02).

---

MY MEDIEVAL LIFE — BUILD 16

OD-18: OWNER DECISIONS — PLAYER AND VILLAGER SYSTEM PARITY

Claude, the owner has reviewed all five outstanding OD-18 questions and made definitive decisions.

All five decisions are approved design requirements.

The central rule is:

THE PLAYER IS A VILLAGER.

The player is not a special entity operating under different economic, crafting, skill, health, or world-awareness rules.

The only fundamental difference is decision-making control: the player is controlled by a human, while other villagers are controlled by their AI.

Implement these decisions through shared underlying systems wherever practical. Avoid maintaining separate player and NPC rules that can drift apart.

OD-18.1 — Skills and progression

Owner decision: All villagers must develop skills exactly as the player does.

- NPCs must use the same skill definitions, experience requirements, progression calculations, and level thresholds as the player.
- Performing eligible activities must award experience under the same rules.
- Skill requirements must apply equally to the player and villagers.
- Villagers cannot bypass Mining level 3 to mine gold if the player must reach Mining level 3.
- NPCs should develop proficiency naturally through their activities, rather than receiving arbitrary skill increases solely to satisfy production needs.
- Skill progression must persist with the villager and remain deterministic within the simulation.
- Existing villagers and saved games need a carefully considered migration strategy.

Do not solve missing NPC proficiency by secretly granting unlimited skills or creating exceptions to the requirements.

OD-18.2 — Trader coin reserves and economic rules

Owner decision: One economic rule for everyone. We are villagers too.

- The player and NPCs must use the same transaction eligibility rules.
- Traders must not maintain one minimum coin reserve for NPC transactions and another for player transactions.
- Resolve the existing OD-15 dependency consistently with this decision.
- Shared economic rules must apply regardless of whether the buyer or seller is controlled by the player or AI.
- NPC preferences, needs, relationships, and individual circumstances may influence whether they choose to trade, but not change the fundamental accounting rules.

A trader may refuse a transaction for a legitimate in-world reason, but not because the buyer is classified as an NPC rather than the player.

OD-18.3 — Rest and health recovery

Owner decision: Use the player's existing recovery model for both players and villagers.

- Villagers must receive the same health-restoration behavior as the player under equivalent conditions.
- Use the existing player recovery model as the authoritative starting point.
- Do not introduce a weaker NPC-only healing model.
- Equivalent actions under equivalent conditions must produce equivalent recovery.
- NPC AI must be able to recognize when rest is needed and seek an appropriate opportunity to rest.
- Preserve the distinction between having access to recovery and actually choosing or being able to rest.

If the current player model restores full health after qualifying rest, NPCs must receive the same benefit after qualifying rest.

OD-18.4 — Recipes and crafting progression

Owner decision: Villagers have access to every recipe available to the player, subject to the same skill-level requirements.

- Maintain one authoritative recipe catalog.
- Use identical skill prerequisites for players and villagers.
- No recipe should be permanently player-exclusive simply because NPC crafting logic has not yet been implemented.
- Villagers must be capable of crafting any recipe when they possess the required skills, materials, equipment, and other applicable prerequisites.
- Crafting must consume resources and produce outputs through the same inventory and accounting systems.
- NPCs must make contextual decisions about what to craft based on needs, work, resources, and opportunities.
- Do not force NPCs to craft every available recipe merely because they can.

Audit the eleven recipes currently unavailable to villagers and close the functionality gap.

OD-18.5 — Crime witnessing and guard awareness

Owner decision: Correct. Guards must not possess unexplained knowledge of an assault.

- Remove the automatic awareness of assaults based solely on a fixed 15-tile radius.
- Apply consistent witnessing and information rules to assault and theft.
- A guard or villager must have a legitimate way to learn about an incident, such as directly witnessing it, hearing an audible disturbance where supported, receiving a report, or discovering credible evidence.
- Do not make guards omniscient.
- Separate crime detection from alarm propagation and guard response.
- Once a guard legitimately becomes aware of a crime, their response can depend on their role, proximity, abilities, circumstances, and existing AI rules.
- Apply these rules whether the offender is the player or another NPC.

An assault should not automatically be invisible simply because nobody has direct line of sight if the simulation already supports a legitimate audible or reported warning. However, do not invent unsupported sensing mechanics merely to preserve the old 15-tile behavior.

IMPLEMENTATION REQUIREMENTS

These decisions are final design direction, not invitations to introduce alternative player-specific exceptions.

Before changing the systems, identify the existing authoritative player implementations and map the NPC implementations against them.

Prefer shared simulation services and data definitions rather than duplicating logic.

Pay particular attention to:

1. Existing save compatibility and migration.
2. Determinism and replay consistency.
3. Skill progression and production availability.
4. Economic conservation and transaction rules.
5. NPC rest behavior and survival.
6. Crafting availability and resource consumption.
7. Witnessing, information propagation, and guard response.
8. Existing Build 16 equilibrium and intervention-scenario tests.

Important: Do not interrupt or invalidate running EQ-06 tests unnecessarily.

Preserve their results as a baseline where possible. Because these decisions can materially change simulation behavior, rerun affected equilibrium and intervention tests after integration.

Implement in dependency order. Do not attempt to force all five into one unreviewable change.

Use separate, testable commits and push approved work to the existing remote GitHub staging branch.

Continue independent approved development while working through the implementation.

Do not merge or publish Build 16 without owner authorization.

REQUIRED ACKNOWLEDGMENT

Before implementation, confirm that you understand:

The player and villagers are governed by the same world rules. Their differences arise from their knowledge, skills, resources, circumstances, and decisions, not from hidden player-versus-NPC exceptions.

Then provide:

- The five OD-18 decisions marked as resolved.
- The shared systems requiring modification.
- Your proposed implementation sequence.
- Any genuine technical dependencies or save-migration risks.
- The regression and equilibrium tests needed.

Proceed with approved development after acknowledging the decisions. Do not wait for another authorization to begin implementation.
