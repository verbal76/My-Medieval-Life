# Owner directive, 2026-10-21: Build 17 early-game progression and integration (verbatim, sections 1-2 and 3 in full; the rest summarised)

MASTER OWNER DIRECTIVE — BUILD 17 EARLY-GAME PROGRESSION AND INTEGRATION

1. B7-006 — Owner-approved closure

Decision: Close B7-006 as Working as Designed, subject to verifying a practical early-game earning route.

The owner does not consider the inability to purchase an axe immediately upon starting a new game to be a defect.

The reported current economy is:

- Starting money: 20 coins.
- Cheapest available axe: approximately 45–46 coins.
- Starting equipment: reportedly a rusty pickaxe and a sword.

The owner recalls starting with both a pickaxe and a sword in previous playable versions. Verify that this remains true in the current Build 17 implementation.

Do not assume the starting equipment is unchanged without checking.

Intended gameplay

A new player should have multiple legitimate ways to begin earning money and acquiring equipment.

Potential routes include:

1. Mining: Use the starting pickaxe to extract legitimate resources, transport them, and sell them through the existing economy.
2. Combat: Use the starting sword to fight bandits, collect legitimate loot or rewards, and sell or use what was actually obtained.
3. Manor work: Accept accessible quarrying, carrying, maintenance, or other paid jobs when available.
4. Other economic activities: Use any existing legitimate trading, gathering, or service opportunities available to a new player.

These are opportunities, not guaranteed income.

A player may choose a dangerous or inefficient route. Combat may result in defeat. Mining may take time. Buyers may lack money or demand. Available jobs may vary.

Do not artificially guarantee success or create free currency, resources, loot, or customers.

Verification before closure

Check the actual current implementation and existing test evidence.

Confirm:

- The player's starting equipment and money.
- That the starting pickaxe can perform at least one genuinely accessible mining or quarrying activity.
- That extracted resources can be legitimately sold, or that accessible paid work provides another practical earning route.
- Whether the starting sword and bandit-loot/reward route currently function as the owner recalls.
- That the verified earning route does not require an axe or another unaffordable prerequisite.

At least one practical earning route must be confirmed for B7-006 to close.

Other routes may be reported as available, unavailable, or conditional based on actual implementation.

Do not invent a guaranteed bandit reward or assume that every bandit drops saleable loot.

Reuse existing tests and evidence where applicable. Run only a narrow targeted check if needed.

Final disposition

If a practical route is verified:

- Mark B7-006 Closed — Working as Designed.
- Record the owner's decision and supporting evidence.
- Retain the current starting economy.
- Do not grant a free axe.
- Do not increase starting coins.
- Do not artificially reduce axe prices.
- Do not introduce guaranteed income.

If no practical route exists, do not falsely close the issue. Report the exact blocker and propose the smallest appropriate correction for owner review.

2. Preserve player freedom and economic consistency

The player is not required to follow one prescribed progression path.

Mining, fighting, trading, and working for others should remain legitimate choices wherever those systems are actually implemented.

The player operates under the same relevant physical and economic rules as NPCs.

Money must come from actual buyers, employers, rewards, or other legitimate existing sources.

Goods and resources must come from actual inventory, extraction, production, or valid loot.

No artificial item or currency generation is authorized.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

3. LOG-01 — Avoid the active worker conflict

The remaining LOG-01 item concerns unclaimed manor deliveries falling back to an available manor worker.

The equipment/collapse worker has been editing "manor_work.gd".

Do not make conflicting changes to that file while its work is active.

Once the equipment worker's changes are safely committed and integrated:

1. Review the actual LOG-01 behavior.
2. Determine whether the required delivery fallback already exists.
3. Implement only the missing narrow behavior, if still required and authorized.
4. Ensure delivery involves actual workers and physical inventory transfers.
5. Prevent duplicate claims, double payments, and unexplained item movement.
6. Use focused validation appropriate to the change.

Do not create a new general logistics subsystem under LOG-01.

Sections 4-8 (summary, owner's words kept where they set rules): complete the existing integration of MIN-D2, MIN-D3,
MIN-SHOVEL, MIN-RIGHTS, MIN-SKILLCAP and the mining equipment and collapse work, preserving active workers ("Do not
restart workers, duplicate completed assignments, or merge incomplete changes"); after both streams merge, run the
determinism check once on the integrated source; STONE-Q is answered and STONE-02..06 and X18-STONECUT are Expansion 18,
not Build 17 blockers, and Build 17 keeps its recipe, Crafting skill and mallet; follow WIKI-01 and keep the recovery
handoff current; "This directive does not authorize a release"; "Do not treat the need to earn an axe as a gameplay
defect simply because it takes time"; report starting kit, verified routes, B7-006, LOG-01, worker status and genuine
release blockers.
