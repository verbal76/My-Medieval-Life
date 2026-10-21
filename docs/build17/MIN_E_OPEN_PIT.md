# MIN-E: open-pit excavation (Build 17)

Register: MIN-E (parent EXP-A; depends on MIN-D). Branch `wip/b17-mine` (base `wip/build17` `9f229f7`). Spec: the Mining and
Industrial Development expansion (`docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf`) stage 3, sections 6,
7, 9 and 11, phase E ("Add open-pit excavation, spoil handling, ramps, hauling and geological layers where architecture
supports them"); `BUILD_17_PLAN.md` section 3 and row MIN-E; `MIN_A_ARCHITECTURE.md` section 8 (the design this
implements) and 10 (acceptance E); `MIN_B_QUARRY.md`; `MIN_D_DISCOVERY.md`; `DEPOSIT_SUSTAINABILITY.md`. Owner decisions:
OD-29 (open pits stay on the surface), OD-28 and B17-DIR (one deposit system everywhere, no regeneration, no automatic
ore, no mining wage, CON-01 kept), Q18-9 (capability levels never gate).

Labels: **APPROVED** (owner decision or approved spec), **DONE** (implemented and tested here), **DECISION** (an agent
decision under the standing release directive: a minor detail, recorded here and in `game/data/open_pit.json`),
**OPEN** (the owner's), **NOT SUPPORTED** (the architecture does not carry it; documented, not invented).

## 1. What is asked (APPROVED)

- "Workers remove topsoil, dirt and rock to excavate a roughly square pit with terraced sides and a descending spiral
  ramp or switchback access. Deeper strata may reveal new finite deposits. Excavation creates real spoil, access,
  hauling and safety requirements" (stage 3).
- "Excavated dirt and topsoil are separately tracked materials rather than deleted terrain ... Agricultural use must
  distinguish suitable topsoil from poor subsoil. Storage and disposal have labor and space costs. All uses require
  recipes and world-system integration before implementation" (section 6).
- "Open pits should visibly deepen through excavation, with terraced walls and a navigable spiral or switchback ramp"
  (section 7). Acceptance: "Open-pit excavation, if implemented, removes and accounts for dirt/stone and exposes finite
  layers" (section 11); MIN-A's: "Excavation conserves every unit of topsoil, dirt and stone; no unreachable pit cell
  (DVW-A10)".

## 2. The architecture question, answered

The surface is one plane (`VillageMap.solid`, one `AStarGrid2D`; `BUILD_17_PLAN.md` section 3). OD-29 keeps pits on it,
so depth is MIN-A's option (a): **per cell**. Each pit cell keeps one integer, the units dug from it; the layers under
every cell are one finite table, so a cell's depth (whole layers dug), the item of its next unit and its collision all
follow from that integer. Nothing about the map, the path-finder or the save format had to change: a dug cell is solid
(a terrace wall) or walkable (the ramp, ground not yet stripped), exactly the two states the plane knows.

## 3. What is built (DONE)

| Part | Behaviour | Where |
|---|---|---|
| A pit | `OpenPits` (`World.pits`): `{id, x, y, owner, for, day, dug: [units per cell], heaps: [{x, y, inv}]}`. A 5 x 5 square staked on clear common ground of the village: the layout's open ground, clear now (`World.plant_refusal`: no road, building, parcel, field, pen, market, station, container, seam, tree, plant), no farmland, nothing parked or lying, nobody standing; a border of walkable ground round it (a road may run by: the way round stays open); two spoil heap cells two out from it on clear ground with clear ground all round (a lone solid cell cuts no path). Its whole ground enters the books when staked (`pit_ground_<item>`) | `open_pit.gd::open_pit`, `site_refusal` |
| Geological layers | Under every cell, top first: 2 topsoil, 3 dirt (subsoil), 3 spoil (broken rock and gravel), then 8 stone (the rock) | `open_pit.json` |
| Terraces and ramp | A cell of ring r is dug to `ring_depth[r]` whole layers: the edge 2 (topsoil and dirt), the next ring 3 (down to the rock), the middle 4 (through the stone). The ramp is one cell per ring on the middle column from the north edge to the middle; it stays walkable at every depth; every other cell dug below the surface is solid | `target`, `is_ramp`, `walkable`, `_sync` |
| Digging (PAR-01) | One rule for the player and a villager: a pickaxe, one unit a dig, the cell's next layer item into the digger's inventory (or a manor job's load), counted `dug_<item>`; the pickaxe wears 1 (Mining `tool_wear_save` may spare it), 4 Mining xp a unit; each layer's minutes a unit (Mining `mine_time` for a villager; the player's swing timed as a mining swing). Refused: no pickaxe, dug to its depth, a seam on the cell, someone standing or something lying there, nowhere to stand beside it, or a dig that would cut a walkable pit cell off from the border (DVW-A10) | `dig`, `dig_ground_refusal`, `_connected_without` |
| Exposed deposits | A cell (not the ramp) dug down to the rock opens the first prospecting body (MIN-C) within `expose_reach` 2 cells that nothing has opened, **by the trial pit's own rule** (`Discovery.expose` -> `_open_seam`): one ordinary `World.deposits` record of the body's finite amount, with its MIN-B host rock, solid, its ore sprite, `found_<ore>`, carrying `"pit"`; mined by `World.work_mine` from the pit beside it, never refilled (OD-28). A misleading stain has no body and opens nothing | `_expose`, `discovery.gd::expose` |
| Earth and the heaps | Topsoil, dirt and spoil are items (`items.json`, value 0: no market). Tipped onto the pit's heaps (an Inventory each, holding its share of the pit's earth; solid while it holds anything: storage takes ground) and taken back from them; stone is kept (the manor's goes to the works yard). The goods census counts the heaps (`tests/census.gd` "pits") | `tip`, `take`, `goods` |
| Backfill (a real use) | A unit goes back into a dug cell, the last dug layer first (`backfilled_<item>`): the ground rises by it; a cell filled back through a layer is level again | `backfill`, `fill_refusal` |
| Hauling | No new transport: a villager carries a load of `carry_ore` (6, the miners' carrying rule) in the manor job's load; the player carries earth in the pack and may load a handcart (`Carts`) as with any goods; the ramp is walkable, so a pulled cart can go down it | `manor_work.gd` |
| The manor | `ManorWork.post_pits` (the reeve's evening, after `post_discovery`): for a find the manor knows (at least `min_confidence`) that no trial pit can still reach (its pits used up or no clear cell), not opened and with no pit dug for it before, the manor stakes a pit at the clear site nearest its readings (within 6 cells) and posts one **excavate** job at a time while it still wants the pit (its find not opened, cells not yet down to the rock): dig a load into the job's load, tip the earth onto the heaps, bring any stone to the works yard. Paid at the quarry job's rate a unit (6 coins for 10 -> 4 for 6; no wage of its own), set aside from the treasury above its reserve when taken, open to the player and villagers by the same rules (a pickaxe needed); a miner whose ore is worked out takes it as it takes a trial pit. Never gated by the capability level | `manor_work.gd::post_pits`, `excavate_cell`, `do_step`, `plan`; `npc_brain.gd::_miner`, `reeve_day` |
| The player | With a pickaxe in hand and nothing else in front: "Mark out an open pit here" (the cheap look on the move, the full check when used). At their own pit: dig the cell ahead, put back a unit, tip the pack's earth onto a heap, take earth from a heap. The manor's pit only through its job (the manor_job target: dig, tip, bring the stone) | `main.gd::_pit_targets`, `_pit_stake`, `_pit_dig`, the `manor_job` branch |
| Land | No land is claimed over a pit, its border or its heaps (`Property.can_claim`); no villager stall there (`Stalls.site_refusal`); house-site search skips them (`Construction._free_sums`); no planting or trial pit there (`World.plant_refusal`) | `property.gd`, `stalls.gd`, `construction.gd`, `world.gd` |
| Capability (Q18-9) | A pit whose ramp is dug to its floor counts as a `pit_ramp` structure (`Discovery.structures`); level 3 still needs two "excavator" practitioners and a handcart (`capabilities.json`, MIN-D's data, unchanged), so it is reported, never a gate: a level-0 village digs and the manor posts | `discovery.gd::structures` |
| Drawing | `PitView` (a child of the village MapView, under its "below" layers, so it fades with the surface and a seam's sprite shows over the floor): each dug cell shows the layer it is down to with the map's own tiles (the free atlas's dirt, the hill's rock fill for spoil, the quarry's cobbled slab for stone), darker the deeper; a shadow band where a neighbour is higher (terrace walls); the ramp lighter with steps; four stakes on a staked pit; a heap is a mound in its earth's colour sized by how full it is | `game/scripts/view/pit_view.gd` |
| Icons | Three Survival-pack icons through the asset pipeline (`tools/import_game_assets.py`, `PROVENANCE.json`): topsoil Dirt-Block-01 (grass-topped), dirt Dirt-Block-13, spoil Rocks-02 | `game/assets/icons/` |
| Saves | Save version stays **17**. New key `"pits"` `{gen, next_id, pits}`; the depths, heaps and their goods round-trip; collision is rebuilt from them on load (a seam's cell keeps its own rules). Absent (a 16 save, or 17 before MIN-E): no pits | `world.gd::to_dict`, `load_dict`, `open_pit.gd::load_dict` |
| Books | `economy_sim.gd`: `dug_` is a faucet and `backfilled_` a drain of every item; the pits' ground is a pool per item, start + `pit_ground_` - end = `dug_` - `backfilled_` (a residual is printed under LEAKS deposits) | `tests/economy_sim.gd` |
| Resources | `resources.json` node `open_pit` (match kind `pit`, checked against `open_pit.json`'s layers by `tools/check_resources.py`), `materials` uses for topsoil, dirt and spoil (backfill, storage; "backfill" added to the consuming kinds), import exceptions for the three (the ground is finite) | `resources.json`, `tools/check_resources.py` |

## 4. Decisions taken (DECISION)

1. **Depth per cell on the surface** (MIN-A option (a), the only one OD-29 leaves for pits): one integer per cell, no
   map or path-finder change.
2. **Items:** `topsoil`, `dirt` (subsoil, the "poor subsoil" of section 6) and `spoil` (the broken rock and gravel
   between the subsoil and the sound rock) are three items; the rock yields the existing `stone`, the same item a
   seam's host rock and a boulder give. This does **not** answer whether quarry stone and building blocks differ
   (open, below). Values 0 and no buyer: no market is invented.
3. **Numbers:** a 5 x 5 pit, layers 2/3/3/8, ring depths 2/3/4 (a pit holds 50 topsoil, 75 dirt, 27 spoil, 8 stone),
   20/25/30/25 minutes a unit, wear 1, 4 xp, 2 heaps, expose reach 2 (the trial pit's), a manor load of `carry_ore` at
   the quarry rate. All data in `open_pit.json`; the owner may change any.
4. **The ramp** is straight, one cell per ring from the north edge into the middle: on a 5 x 5 pit a spiral or a
   switchback has no room. The ramp cell of a ring may drop two layers (the edge ring is two deep).
5. **The digger cannot dig the cell it stands on**; a dig that would wall a level pit cell in is refused; the pit is
   dug a bench at a time (the shallowest diggable cell first), so the topsoil comes off first, as good practice does.
6. **Exposure only where the rock is reached** (non-ramp cells of the inner rings), on that cell; the seam is solid,
   mined from the pit's floor or ramp beside it.
7. **The manor stakes a pit only when the trial pits are spent** for a find it knows (a trial is the cheaper look),
   once per find, and stops posting when its find is opened or every non-ramp cell is down to the rock: a pit that
   finds nothing is a failed venture (WDR-022); the middle's stone may stay in the ground.
8. **The player's pits are the player's**, the manor's are dug only through its job; the ground is common land and no
   rights are made (MIN-C-Q2 kept).
9. **The border may be a road** (it stays walkable); the pit itself and its heaps keep off roads. On the static layout
   this gives 66 sites (seeds 1, 2 and 7 alike; 15 with a fully clear border).
10. **Pits only in the village grid.** The overworld keeps no per-cell state of this kind (MIN-A section 8: "the
    overworld later through its changes block").

## 5. Owner questions (OPEN; not built)

1. **Earth's uses beyond backfill and storage:** topsoil on farmland (better yield) and dirt/spoil for road embankments,
   grading building plots, defensive earthworks and landscaping are the spec's candidates; each needs a recipe and a
   system (section 6). Which, and in which build?
2. **Quarry stone, building blocks, spoil and topsoil** (Mining spec section 12; `DEPOSIT_SUSTAINABILITY.md` 6.3): this
   build keeps one `stone` item and makes spoil a separate waste item. Should stone from a pit or a seam be split into
   rough stone and dressed blocks (a mason's recipe)?
3. **MIN-D-Q3 (unchanged):** whether trial pits also yield dirt or topsoil. Not decided here: trial pits move no earth.
4. **A spade or shovel:** digging earth uses the pickaxe. A spade (carpenter's handle, smith's blade) would be the
   spec's "real tool"; adding one is a new item, recipe and workstation use.
5. **Who may stake a pit, and where:** built, anyone (the player, the manor) on clear common ground, like a trial pit.
   Should a pit need the manor's leave or be the manor's mining right (the proposal P1.2)?
6. **Excavator practitioners:** capability level 3 names two "excavator" practitioners; no such job exists (the
   manor's excavate job is open work). Should excavation be a trade (job), or should level 3 count the villagers who dig?
7. **Bigger pits, spirals, more layers:** a spiral or switchback ramp and deeper strata need larger pits (7 x 7 or more)
   than the village's ground holds (section 6, NOT SUPPORTED below), or pits in the overworld.

## 6. Not supported by the architecture (NOT SUPPORTED; documented, not invented)

- **Many geological layers / varying strata:** every cell has the same four-layer column. Varying strata by place would
  need a hashed geology per cell (like MIN-C's bodies); not built.
- **A spiral or switchback ramp:** needs room the village grid's open ground does not have (5 x 5 pits; 66 sites).
- **Pits outside the village:** the overworld stores changes per chunk, not per-cell depth.
- **Pit art:** the Forgotten Memories cliff steps (B14-07) are in `private-assets/` (absent here) and "planned"; the pit
  is drawn with the map's own tiles and shading instead. Prospecting stains (ClueView) still draw over a dug cell.
- **Safety:** collapse, water and supports are not simulated (the spec lists "safety requirements"; MIN-F's supports
  would be the place).

## 7. Interactions (for the lead's INT entries)

| Trigger | Sources | Affects | Expected |
|---|---|---|---|
| A pit staked | `open_pit.gd::open_pit`, `site_refusal`, `main.gd::_pit_stake`, `manor_work.gd::post_pits` | ground use: `World.plant_refusal`, `Property.can_claim`, `Stalls.site_refusal`, `Construction._free_sums`, `Discovery.ground_refusal`; the ledger (`pit_ground_`) | nothing planted, claimed, built or trial-dug on the pit, its border or heaps; its ground counted once |
| A unit dug | `open_pit.gd::dig`, `_sync`, `main.gd::_pit_dig`, `manor_work.gd::do_step` | the digger's inventory or job load, pickaxe wear, Mining xp, collision and paths (`VillageMap.set_solid`), `PitView` | one unit of the cell's layer, `dug_<item>`; never a cut-off cell |
| Down to the rock | `open_pit.gd::_expose`, `discovery.gd::expose`, `_open_seam` | `World.deposits` (one ordinary seam with host rock), collision, the village view, the caravan's import threshold, the labour market's miner places, `Quests.deposit_left`, capability | `found_<ore>` = amount; mined by `work_mine`, never refilled |
| Earth tipped, taken, backfilled | `open_pit.gd::tip`, `take`, `backfill` | heap inventories (the goods census), heap collision, the pit's ground (`backfilled_`) | goods conserved; a heap solid only while it holds anything |
| The reeve's evening | `npc_brain.gd::reeve_day`, `manor_work.gd::post_pits`, `open_pit.gd::manor_target`, `best_site` | the job board, the treasury (wage set aside when taken), the works yard (stone) | one excavate job at a time, only for a find out of a trial's reach; coins conserved |
| A miner without ore | `npc_brain.gd::_miner`, `manor_work.gd::seek_kind` | job choice | takes the manor's trial or excavate job |
| Dawn capability | `discovery.gd::structures`, `evaluate` | the `pit_ramp` structure | counted, reported only (Q18-9) |
| Save and load | `world.gd::to_dict`, `load_dict`, `open_pit.gd::load_dict`, `sync_all` | saves, collision, the view | depths and heaps round-trip; absent key = no pits |

## 8. Tests

`game/tests/openpit_test.gd` (66 checks): sites on seeds 1, 2 and 7 (66 each) and the same per seed; no pit on a road;
staking enters the ground into the books; nothing planted, claimed, trial-dug or overlapped on a pit, its border or its
heaps; parity (the player and a villager dig the same layer, the same xp, the same pickaxe refusal); a whole pit dug
unit by unit (160 units) with the pit's ledger and the path-finder's reach of every walkable cell checked every 12
digs, the goods census rising by exactly what was dug, the earth on the heaps, the terraces and ramp as designed;
backfill (the last layer first, level ground again, the books and the census moving back); the cut-off refusal
(DVW-A10) and its way out; exposure on seeds 1 (iron) and 7 (copper): an ordinary seam of the body's amount with host
rock, solid, `found_`, mined by `work_mine` beside it, no trial pit after; the manor (no pit while a trial can reach
the find; then one staked and one excavate job of 6 at 4 coins; a labourer digs, tips and is paid from the treasury,
coins and goods conserved; the next load planned and dug by the villager in the running world); a level-0 village digs
a ramp to its floor, `pit_ramp` counted, the level still 0 (Q18-9); determinism (same seed, same digs: same pit,
goods, rng and books; another seed differs); saves (round-trip of depths, heaps, collision, goods and ground; a save
without pits and a version 16 save load with none).

## 9. Results (2026-10-21, `wip/b17-mine`)

- Suites, 0 failures each: openpit 66, discovery 65, prospecting 54, quarry 39, underground 95, contracts 75, crafts 20,
  world 339, run_tests 3537, start 499 steps, play 37 steps, parity 55, conservation 8. `check_resources.py` 27 nodes,
  0 problems; `check_materials.py` 0 broken references, 0 stale exceptions (16 open findings, as before);
  `check_assets.py` 0 problems; `python3 -m unittest discover -s tests` 105 tests OK.
- `economy_sim.gd --days 30 --seed 1`: `LEAKS: currency 0; items {}; deposits []; animals {}`, fingerprint
  `329a078f78e90f4865e6d8b0dbba84ba`, identical to the Build 17 baseline at day 30 (`DETERMINISM_GATE.md`): in 30 days
  of seed 1 the manor knows no find out of a trial's reach, so no pit is staked and nothing in the run changes.
- Screenshots (looked at; `main.gd --panel open_pit | open_pit_dug`, seed of a new game, warp 30,60, a pit staked at
  (32, 66) beside the Dale family's house): part dug (the north-west edge down a step in grey, the rest of the topsoil
  being stripped in sandy dirt, the ramp lighter with step lines, one dark topsoil heap south of it, the player at its
  south-east corner); dug out (the edge bench grey-olive rubble, the inner ring darker cobbles, the floor and the ramp's
  foot, dark shadow bands along every drop, two mounds south of it). A tall pine standing south of the pit is drawn in
  front of its south-west corner (correct depth order). The stripped topsoil reads much like the village's sandy paths;
  the terraces read as rock, not as a hole with height. The villager placed on the ramp for the picture had walked off
  by the time it was taken. Not looked at on a phone.
