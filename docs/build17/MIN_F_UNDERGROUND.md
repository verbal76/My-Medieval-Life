# MIN-F and MIN-H: underground works, minecarts, track and the natural cave (Build 17)

Register: MIN-F (parent EXP-A; depends on MIN-E) and the rest of MIN-H (enterable caves: roof-fade principle, NPC
pathing, persistence). Branch `wip/b17-minf` (base `wip/build17` `70900c0`). Spec: the Mining and Industrial
Development expansion (`docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf`) stages 4 and 5, sections 4, 7
and 11, phase F ("Add underground/cave mining, cutaway presentation, minecarts, track construction and full industrial
dependencies"); `BUILD_17_PLAN.md`, `UNDERGROUND_ARCHITECTURE.md`, `MIN_A_ARCHITECTURE.md`, `MIN_B_QUARRY.md`,
`MIN_D_DISCOVERY.md`, `MIN_E_OPEN_PIT.md`. Owner decisions: OD-29 (underground = separate level maps tied to surface
portals; open pits stay on the surface), OD-28 and B17-DIR (one deposit system everywhere, depletion, no regeneration,
no automatic ore, no mining wage, independent mining and CON-01 kept), Q18-9 (capability levels never gate).

Labels: **APPROVED** (owner decision or approved spec), **DONE** (implemented and tested here), **DECISION** (an agent
decision under the standing release directive, recorded here and in the data files), **OPEN** (the owner's), **NOT
SUPPORTED** (the architecture does not carry it; documented, not invented).

## 1. What is asked (APPROVED)

- Stage 4: "Suitable rock faces and underground formations may support shafts, galleries, chambers and enterable caves
  ... roofs/overhead terrain hide or become transparent so the player can see characters inside. Supports, lighting,
  ventilation, access, navigation and hauling are genuine dependencies."
- Stage 5: "minecarts, track laying, track fabrication, cart assembly, repair, hauling logistics ... supported by an
  actual workforce and resource economy rather than a simple unlock button."
- Section 11: "Underground workings, if implemented, are enterable, readable in isometric view and navigable by NPCs";
  "Minecarts, track, timber supports and tools connect to existing workshops and transport rather than appearing for
  free."

## 2. What is built (DONE)

| Part | Behaviour | Where |
|---|---|---|
| The natural cave (MIN-H) | A second level map, `hill_cave`, on **level -2** under the same hill as the adit gallery (-1), made by the gallery's own generator with its own salt (its passages are its own) and more winding passages and chambers; 50 to 77 floor cells on seeds 1, 2, 3, 7, 12345. Its own mouth on the hill's south face: portal `cave_mouth`, surface stand (43, 10), door (43, 9), drawn with the adit's own opening tile. Deterministic from the seed, not saved (as the gallery). The adit gallery is byte-identical to before (tested against its seed-1 fingerprint) | `underground.json`, `underground.gd::_make_gallery` |
| Cave seams | Three ordinary `World.deposits` records with `"level": -2` (coal, iron ore, copper ore, the village's own amounts), with MIN-B host rock; mined by `work_mine`, counted `mined_`, never refilled; load merge by (level, x, y) | `underground.gd::_place_seams`, `world.gd` |
| NPC pathing | `World.villager_levels` is now every level a portal reaches (`Underground.reachable_levels`: [0, -1, -2]); the existing router walks villagers through the cave's mouth; a miner whose ore is left only in the cave walks in, mines, and carries it out (tested, 0 level disagreements) | `world.gd::setup`, `load_dict` |
| Stacked levels | The cave lies under the gallery, so the ground alone cannot tell -1 from -2. `Underground.levels_at` lists every level at a cell; `World.level_at` takes the level of whoever stands at the point (the player, a villager below), else the player's level if it is one of them, else the shallowest. Awareness, reach and fights stay on one level (tested) | `underground.gd::levels_at`, `world.gd::level_at` |
| Tunnels | Rock beside a level's floor is cut one unit at a time with a pickaxe (`MineWorks.dig`, PAR-01: the player and a villager by one function): each rock cell holds 3 stone then 2 spoil, counted `cut_<item>`; the last unit opens the cell as floor (its A* at once, the view redraws it). Only rock under the hill's static rock with rock all round and inside the map's edge (`Underground.under_rock`, the rule every level's floor keeps), never a seam's cell, only from an open face, standing at it. Pickaxe wear 1, 4 Mining xp a unit, each unit's minutes for a villager, a mining swing for the player | `mine_works.gd`, `mine_works.json` |
| Timber supports | Made at the sawhorse (`make_timber_support`: 1 log, 2 planks); set up on a level's floor from the setter's own inventory with a mallet (`place_support`, used_timber_support, mallet wear, Crafting xp), saved. **What they do:** rock is cut only within 2 cells of a support. Nothing else is claimed: collapse is not simulated | `mine_works.gd::place_support`, `rock_refusal` |
| Track | Made at the workbench (`make_track_section`: 2 planks, 4 nails); laid one a cell with a mallet on a level's floor, and on the surface's open ground within 14 cells of a portal's surface stand (the mine's yard), used up (used_track_section), saved. Drawn four ways | `mine_works.gd::lay_track`, `track_ground_refusal` |
| Minecart | Built at the workbench (`build_minecart`: 4 cart wheels, 2 axles, 2 ironwork, 6 planks: the handcart's own parts chain, smith and carpenter). Set down from the pack on a track cell it becomes a cart of kind `minecart` on the setter's level (`Carts`: owner rules, chest-like store of 16 kinds, wear by the tiles pulled). It follows its puller only onto track cells of its level; pulled off the rails it stays where they end and, 3 tiles off, is let go. On track it is pulled at 0.95 of walking speed (a handcart 0.75). It crosses a portal with its puller (player or villager, one rule) only where track lies on both stands; a handcart is still refused at the adit. No teleport: the cart moves with the existing trailing rule; the crossing is the same one-cell step through the portal the puller makes | `carts.gd`, `world.gd::player_through`, `_npc_through` |
| Cutaway presentation | The existing level view with the surface faded (MIN-A); MIN-F adds: the cave's own level view (only the level the player is on shows), the cave floor shaded, a cut cell redrawn with the walls round it, track and supports drawn on the level (`WorksView`), the yard's track on the surface (fades with it), minecarts drawn with the paid atlas's own mine carts (empty / heaped with rock) and shown only on their level, the cave's mouth drawn in the rock face | `level_view.gd`, `works_view.gd`, `main.gd` |
| The player | Below ground: "Cut into the rock (n of 5 units left here)", or the reason the face may not be cut yet; "Set up a timber support here"; "Lay a track section here"; pull / let go / open a minecart; the pack's "Set it down" puts a minecart on track | `main.gd::_works_targets`, `_cart_targets`, `set_down_cart` |
| Capability (Q18-9) | `Discovery.structures("timber_support")` counts the supports set up (level 4's need); reported only: a level-0 village mines the cave and cuts tunnels (tested) | `discovery.gd::structures` |
| Saves | Version stays **17**. New key `"mine_works"` `{gen, opened, cut, supports, track}`; carts may carry `"kind"` and `"level"`. Absent: nothing cut, set up or laid, every cart a surface handcart. A version 16 save loads on the surface with the cave's seams full. `Underground.GEN_VERSION` 1 -> 2 (the cave added; the gallery unchanged, so gen-1 saves keep every seam) | `world.gd::to_dict`, `load_dict`, `mine_works.gd`, `carts.gd` |
| Books | `economy_sim.gd`: `cut_` is a faucet; the rock cut is a pool (`MineWorks.ground_cut`): its rise equals `cut_` per item, else a residual under LEAKS deposits | `tests/economy_sim.gd` |
| Resources | Node `tunnel_rock` (match kind `tunnel`, checked against `mine_works.json` by `tools/check_resources.py`); material uses for timber_support and track_section; minecart no-consumer exception (as the handcart); spoil's import exception names the tunnels. Three Survival-pack stand-in icons through `tools/import_game_assets.py` | `resources.json`, `tools/check_resources.py`, `resource_nodes.gd` |

## 3. Decisions taken (DECISION)

1. **The cave on level -2 under the hill.** The village's only static rock is the mine hill (148 cells), already
   under the gallery's map on level -1; OD-29 forbids two maps of one level overlapping, and the overworld's rock is out
   of villagers' reach (they never leave the village grid). So the cave lies a level deeper under the same hill with its
   own surface mouth, and `World.level_at` was made stack-aware (by who stands there) rather than changing the gallery.
2. **Supports gate tunnelling only.** No collapse rule: a deterministic, conserving collapse (what falls, where the
   rock goes, who is hurt) is a gameplay mechanic the owner has not specified. Reach 2 cells.
3. **A rock cell: 3 stone, then 2 spoil**, 30 and 25 minutes a unit; tunnels only where the rock above is at least a
   cell deep all round (the hill bounds them: finite).
4. **Track on the surface only in the mine's yard** (14 cells of a portal's stand), so a minecart can come out of the
   adit onto rails; nothing else on the surface checks track (it blocks nothing).
5. **A minecart is a cart of its own kind** in the one cart system (no second cart system); market runs and stall
   deliveries keep using handcarts only (`Carts.of(owner, kind)`). Speed on track 0.95, 16 stacks (as a handcart:
   carts hold kinds, not units).
6. **Art:** the paid Puny World atlas's mine carts (tiles 3229 empty, 3449 loaded, beside the handcart stand-in 3009);
   no rail or timber-set art is imported (Puny Dungeon has a log beam and poles but no rails, status "planned"), so
   rails and supports are drawn procedurally at 16 px as PitView's stakes are; the cave floor is the free atlas's
   plain dirt, shaded. Icons: Survival pack stand-ins (log block, plank, iron tub).

## 4. Owner questions (ANSWERED 2026-10-21; kept as asked)

All five were answered by the owner (MIN-F-Q1..Q5, `docs/directives/2026-10-21_build17_minf_q1_q5_decisions.md`) and built in
MIN-F2, MIN-EQUIP and MIN-COLLAPSE: unsupported spans collapse and supports wear and are repaired (`MIN_F2_STRUCTURE.md`);
the manor's tunnel job and hidden underground ore; miners' minecart-or-carry choice and household minecarts where the
player laid track; shafts and deeper levels; player-ordered backfilling only; a collapse's outcome for people
(`MIN_EQUIP_COLLAPSE.md`). Ventilation and lighting were not part of the answers and are not built. The questions as
first asked:

1. **Collapse and safety:** should unsupported spans fail (and with what consequence), should supports decay (DVW-B4)
   and need repair, and should ventilation and lighting (lamps, torches) be real needs?
2. **Autonomous tunnelling:** villagers cut, set up supports, lay track and pull minecarts by the same functions
   (tested), but no villager decides to: tunnels expose no ore (the seams below are generated; MIN-D's hidden bodies are
   surface clues). Should tunnelling find hidden underground bodies, and should the manor post "drive a heading" and
   "lay track" jobs (paid as quarry work), and the carpenter make supports and track to sell?
3. **Minecarts for villagers:** should miners haul by minecart (a household or manor minecart) instead of carrying?
4. **Shafts and deeper levels:** a shaft (a portal with both ends at one (x, y)) from the gallery down to the cave?
5. **Spoil below ground:** may spoil be backfilled into tunnels or stacked in worked-out chambers?

## 5. Not supported (NOT SUPPORTED; documented, not invented)

**Superseded in part (2026-10-21):** the owner answered questions 1-5 of section 4 (MIN-F2,
`docs/directives/2026-10-21_build17_minf_q1_q5_decisions.md`): collapses, support wear and repair, hidden ore, manor
tunnel jobs, minecart preference, shafts and player-directed backfill are built; see `MIN_F2_STRUCTURE.md`.

- Collapse, ventilation, lighting as a need, flooding: not simulated (atmosphere-only darkness stays as MIN-A).
- A cave outside the hill: the village grid has no other static rock; the overworld's mountains are out of villagers'
  reach.
- Rails across the surface beyond the yard, track switches, powered haulage.
- Existing parity gap found (not changed here, it would move the economy): villagers pulling a handcart walk at full
  speed (`World._walk` ignores `pull_speed`); the player is slowed. Minecart speed is likewise applied to the player only.

## 6. Interactions (for the lead's INT entries)

| Trigger | Sources | Affects | Expected |
|---|---|---|---|
| A rock unit cut | `mine_works.gd::dig`, `main.gd::_tunnel_cut` | cutter's inventory (`cut_`), pickaxe wear, Mining xp, `LevelMap.set_solid` (collision, A*), `LevelView.redraw_around` | one unit, finite; a cell opens only after its last unit; never unreachable floor |
| A support set up | `mine_works.gd::place_support` | inventory (`used_timber_support`), mallet wear, which rock may be cut, `Discovery.structures` | consumed, saved, counted only (Q18-9) |
| Track laid | `mine_works.gd::lay_track` | inventory (`used_track_section`), where a minecart may run, `WorksView` | consumed, saved |
| A minecart set down / pulled | `mine_works.gd::set_down_minecart`, `carts.gd::place`, `update`, `pull_speed_for`, `main.gd` movement | carts (kind, level), census of goods in carts, wear | moves only on track of its level; goods carried, never made |
| A minecart through a mouth | `world.gd::player_through`, `_npc_through`, `carts.gd::cross` | cart level and position | only with track on both stands; a handcart refused |
| Cave and router | `underground.gd::reachable_levels`, `world.gd::villager_levels`, `nearest_seam`, `_walk` | job market miner places, caravan import thresholds, `Quests.deposit_left` (the cave's ore counts as the village's) | villagers mine the cave through its mouth |
| Stacked levels | `underground.gd::levels_at`, `world.gd::level_at` | `present`, `near`, `reaches`, guards | nobody sees or reaches across levels |
| Save and load | `world.gd::to_dict`, `load_dict`, `mine_works.gd::load_dict`, `carts.gd` | saves, collision | cut cells reopen before anyone is placed; absent keys are defaults |

## 7. Tests and results

`game/tests/underground_ext_test.gd` (113 checks): the cave's generation per seed (reachable, under the rock, three
wall seams, other seeds other caves, no rng draw) and the adit gallery unchanged; entry and exit through the cave's
mouth, collision and tap-walk in the cave, the router; stacked levels (a cell floor of both levels: the player in the
cave and a villager in the gallery do not see or reach each other); supports (refusals, consumed, counted by the
census and the capability evaluator); cutting (refusals: no support, seam, thin rock, no open face, no pickaxe, out of
reach; 3 stone then 2 spoil, the cell opens on the last, its A*, xp, `cut_` counts, the goods census rises by exactly
the rock's fall, the support's reach, DVW-A10 reach of every floor cell, every cut cell under the rock); parity of the
player and a villager; track (refusals, consumed, the yard rule); the minecart (built by its recipe, set down on track
only, its kind, level and stacks, market runs ignore it, pulled along the track it stays on the rails and carries 4
real ore units unchanged, wears, stays when pulled off and is let go); through the adit only with track on both stands,
for the player and a villager, a handcart still refused; saves (cut, half-cut, supports, track, the minecart and the
player in the cave round-trip; a 17 save from before MIN-F and a 16 save load with defaults); determinism; a level-0
village mines the cave and cuts (Q18-9); a miner whose only ore is in the cave walks in through its mouth, mines and
carries it out, every unit counted. The scene: two level views, the mouth drawn, the cave shown alone, a cut cell
redrawn, the "Cut into the rock" offer.

Results on `wip/b17-minf` merged with `wip/build17` `e9a01e4`, 0 failures each: underground_ext 113, underground 95,
openpit 66, discovery 65, quarry 39, contracts 138, services 51, world 339, run_tests 3538, start 499 steps, play 37
steps, parity 55; `check_resources.py` 28 nodes 0 problems; `check_materials.py` 0 broken references, 0 stale
exceptions, 18 open findings (16 before: nails is now a recipe material, consumed by no villager profession: open);
`check_assets.py` 0 problems; `python3 -m unittest discover -s tests` 105 OK. `economy_sim.gd --days 30 --seed 1`:
`LEAKS: currency 0; items {}; deposits []; animals {}`, fingerprint `5063396929116f24aa7e707200ff846c` (changed from
the Build 17 baseline: the cave's three seams are the village's own ore now, so the labour market, the caravan's
import thresholds and the miners' choices move; in this run the miners worked the cave's seams and the manor staked an
open pit). Tests updated for the cave by design: `underground_test` (two portals, villager levels [0, -1, -2], the
cave's seams counted, two level views), `world_test` (the sawhorse now has two log recipes), `tests/test_resources.py`
(tunnel_rock is a finite node with no replacement).

Screenshots (looked at; `main.gd --screenshot ... --panel mine_works | cave`, xvfb, opengl3): **mine_works**: the gallery's
grey cobbled floor with its mossy rock walls, a timber set (two posts and a cap beam) at the new face, a run of rails
with sleepers from the adit's mouth bending north and east to it, a mine cart heaped with grey rock on the rails beside
the set, the player standing by the cart and a villager (the labourer) on the track; the cells cut open read as more
of the same cobbled floor, so the cut is not visibly different from the old gallery. **cave**: the cave alone, the
surface faded out; a broad ochre-dirt floor (one shaded tile, flat-looking), pale rock walls round it, three seams on
its walls (copper's orange flecks, iron's blue, coal's black), the player in the middle and a villager who walked in
through the mouth beside them. Not looked at on a phone.
