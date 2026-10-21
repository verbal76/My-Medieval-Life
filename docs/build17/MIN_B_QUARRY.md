# MIN-B: stone after ore, the quarry chain, B7-006 and B7-007 (Build 17)

Register: MIN-B, with B7-006 and B7-007. Branch `wip/b17-minb` (base `wip/build17` `b0a02c9`). Spec: the Mining and
Industrial Development expansion (`docs/directives/My_Medieval_Life_Mining_Industry_Expansion.txt`) stage 1, sections
6, 9 and 11; `BUILD_17_PLAN.md` section 2; `DEPOSIT_SUSTAINABILITY.md`; `MIN_A_ARCHITECTURE.md`.

Labels: **APPROVED** (owner decision or approved spec), **DONE** (implemented and tested here), **DECISION** (an agent
decision under the standing release directive: a minor detail, recorded here and in `balance.json`), **OPEN** (the
owner's).

## 1. What the spec asks

**APPROVED.** "When the colored indicators are depleted, the remaining gray rock can still be mined for ordinary stone.
Depleted ore does not automatically replenish. Stone is moved into a quarry/stone-handling production chain" (stage 1).
Acceptance: "A depleted colored ore deposit remains mineable for ordinary stone without regenerating ore" (section 11).
The same deposit rules everywhere (directive 2026-10-21 section 4); no ECON-P1 proposal is adopted (owner decision
pending).

## 2. The host rock: a second finite pool of the same seam

| Item | Behaviour | Label |
|---|---|---|
| Record | Every ore seam (iron, coal, copper, gold; surface and gallery) carries `host`: `{x, y, ore: "stone", amount, of: <the seam's ore>, level}` in the same `World.deposits` record. A stone seam has none (it is stone itself) | DONE |
| Size | `quarry_host_stone` = **20** a seam (`balance.json`, with `_quarry_note`): a third of an iron seam, a quarter of a stone seam. The village's 12 surface ore seams hold 240 more stone, the gallery's 5 hold 100: about 17 houses at 20 stone each | DECISION |
| When | Only after the seam's ore is out: `World.deposit_at` then returns the host rock, so every lookup (the player's target list, Gather mode, `ResourceNodes`, villagers' `mine` act, the manor's `mj_mine`) finds stone there | DONE |
| The rule | The same swing: `World.work_mine` and `World.mine_unit` (pickaxe, wear, the skill's extra unit, 8 Mining xp a unit, `mined_stone`). No Mining 3 for a gold seam's host rock: it is plain stone. Quarrying takes `mine_minutes` a unit, as any seam | DONE / DECISION (rate) |
| Never refilled | The ore's amount never rises; the host rock only falls | DONE |
| Picture | While its ore lasts a seam shows its ore sprite; once worked out it shows the hollow grey rock (`deposit_tiles.worked_out`), which is now stone to quarry ("one sprite, one product") | DONE |
| Quarried away | At 0 the rock is gone: the cell becomes open ground and its tile is taken away, as a broken boulder's is (`World._open_quarried`). In the gallery the cave grows by that cell. `DEPOSIT_SUSTAINABILITY.md` section 6 left "whether a cell emptied of its stone becomes walkable" open; this follows the boulders' existing rule, the one stone source that already empties | DECISION |
| Node | The host rock is an instance of the existing `stone_seam` node (`ResourceNodes.def_for_deposit`, `instances`); `resources.json` texts updated and the manifests regenerated (`tools/check_resources.py --write`) | DONE |

## 3. Villagers quarry by the player's rules

- `World.nearest_seam(n, ores)`: when stone is wanted, the sources are the stone seams, the host rock of worked-out ore
  seams (on the levels villagers reach) and the village's boulders, nearest first. `NPCBrain.seam_steps` plans the walk
  and the swing; the act finds the source by cell and level.
- **Boulders:** `resources.json` boulder `npc_harvest` is now true. Villagers quarry only the village's boulders (they
  stay in the village); the overworld's remain the player's. `DEPOSIT_SUSTAINABILITY.md` section 6 item 6 listed this
  as open; the Build 17 lead's MIN-B brief directs it ("villagers quarry worked-out seams and boulders by the same rules
  as the player"). Flagged for the owner's record.
- Who quarries: labourers (stone while the raw-goods merchant buys it), miners with no ore left to sell (they take what
  someone buys, as before), the manor's quarry hands, and villagers fulfilling a CON-01 contract for stone
  (`Contracts.plan`, route `mine`, now through `nearest_seam` and `seam_steps`).

## 4. The village's stone left, the caravan, the labour market

| Reader | Change | Label |
|---|---|---|
| `Quests.deposit_left("stone")` | Adds `World.quarry_stone_left()`: host rock of worked-out seams on villager levels, and the boulders. It drives the caravan's stone rule (`_stone_scarce`), the manor's quarry posting and contracts' feasibility | DONE |
| Caravan stone (B7-007, INT-065) | Unchanged rule: the caravan brings stone only when the village's own stone is at or under `caravan_import_when_left` (10). Since the village's own now includes host rock and boulders, the caravan's stone waits until those are nearly gone too | DONE |
| Labour market | Miner places count the stone left to quarry (`ore_per_miner`) | DONE |

## 5. The quarry chain and stone logistics

No new items: whether quarry stone, building blocks, spoil and topsoil are different goods is an open spec question
(Mining spec section 12; `DEPOSIT_SUSTAINABILITY.md` section 6 item 3) and stays **OPEN**. The chain is the existing
one, now with sources after the seams:

1. **Sources:** stone seams, then host rock of worked-out ore seams and the village's boulders (surface and gallery),
   then the caravan's cart under the threshold.
2. **Extraction:** the player, labourers, miners, manor quarry hands and contract sellers, one swing rule.
3. **Carrying:** villagers carry up to `carry_ore` (6) a trip, through the adit when the source is below.
4. **Handling and sale:** labourers sell to the raw-goods merchants (the village's stone sellers, `Construction.SELLERS`);
   the manor's quarry job carries its stone to the works yard; contract stone goes to its buyer.
5. **Use:** house and building sites (`Construction`), the manor's mending (`ManorWork`), crafts that take stone.

## 6. B7-006: the mine wage

**DECISION** (the brief: "a quarry or mine job's pay can be a contract or the existing manor job; choose what fits
existing systems"). No mining-specific wage is introduced, and no wage number is changed (the owner did not approve
"mining wage 15+", `docs/DECISIONS.md` 2026-10-18; directive 2026-10-21 section 5 rejects a mining-specific wage).

- **The manor's quarry job stays the manor's existing job:** posted by the reeve while the village's stone holds
  `quarry_qty`, paid `quarry_wage` from the treasury on completion (set aside first; `can_fund`); it now quarries host
  rock and boulders too.
- **Fair pay for mining labour is the CON-01 contract:** a buyer (the player, a smith, any business) offers a per-unit
  price for ore or stone; the miner accepts, rejects or counters by what it can really do (`Contracts.means`, route
  `mine`, which now reaches the gallery, host rock and boulders). This replaces "a shift for 8 coins" as the way to agree
  a price for mined goods.
- The player's hire template "A shift in the mine" (`quests.json`, 6 iron ore for 8) is left as it is: changing it is the
  owner's call. **Recommendation for the register:** B7-006 superseded by CON-01 when the owner confirms (as
  `DEPOSIT_SUSTAINABILITY.md` section 6 item 4 says).

## 7. B7-007: no stone source

The village now has stone after its seams: 240 (surface host rock) + 100 (gallery host rock) + the village's boulders (2 to 6
stone each), then the caravan's cart. Depletion itself stays finite: nothing
refills (ECON-P1 proposals not adopted). **Recommendation for the register:** B7-007's remaining part (no stone source)
answered by MIN-B; depletion stays as approved (finite).

## 8. Saves

No new save version (17). The host rock is saved inside each seam's record (`deposits`). A save without it (Build 16, or
Build 17 before MIN-B) loads with every ore seam's host rock whole, worked-out seams included. Rock quarried away is open
ground after a load: its collision on load (`World.load_dict`), its tiles when the views are built (`World.sync_boulders`,
`LevelView`).

## 9. Tests

- `game/tests/quarry_test.gd` (39 checks): the pools; the player's rule (same node, swing, xp, `mined_stone`, the ore
  never rises, no gold gate on host rock); rock quarried away opens on the surface and in the gallery; the village's
  stone left, the caravan's stone only at the threshold; villagers quarry host rock and boulders in a day with
  `mined_stone` equal to the fall of every stone pool; the manor's quarry job on host rock and boulders, its wage from the
  treasury, coins conserved; saves (half-quarried, quarried away, an older save).
- `economy_sim.gd`: the deposit ledger now adds the host rock and the boulders to the stone pools.
- `underground_test.gd`, `run_tests.gd` (B7-007 test: the village's own stone now includes host rock and boulders).
