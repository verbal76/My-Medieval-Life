# Build 17 preparation (read-only): Mining and Industrial Development

Prepared 2026-10-21 under the owner's master directive (`docs/directives/2026-10-21_build16_master_completion_directive.md`
section 13): read-only preparation while Build 16 is completed. **Nothing here is approved Build 17 implementation, and
nothing here is merged into Build 16 staging.** Scope is the register's Build 17 entries only (24): EXP-A and MIN-A..G
(spec: `docs/directives/My_Medieval_Life_Mining_Industry_Expansion.txt`), B14-07, B7-006, B7-007, DVW-A10, DVW-A12
(deferred to the start of Build 17), DVW-B4, ECON-P1.1/1.2/1.4/1.5 (proposals), OD-01 (decision), PL1-12, REC-013,
WDR-001-C, WDR-003-C, WDR-013-C. Code references are as of staging `6607000`.

## 0. Owner decisions of 2026-10-21 (OD-28)

Source: `docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md` (verbatim). A documentation-only
update of this branch is authorized; **no Build 17 gameplay implementation is authorized by it** (section 9).

- **Caves and underground (section 3).**
  - **Approved direction:** genuine, enterable natural caves, tunnels, chambers and open pits, and later
    industrial mining. They must be usable by the player and NPCs (movement, pathfinding, mining, real depletion,
    transport, access, save and load). Overhead rock gets out of the way as a house roof does, with darkness for
    atmosphere that never makes the game unplayable. Not a decorative pit.
  - **Architecture: not selected.** The owner prefers to investigate a layered world, without an unnecessary
    rewrite.
  - Comparison and recommendation: [`UNDERGROUND_ARCHITECTURE.md`](UNDERGROUND_ARCHITECTURE.md). It recommends
    separate underground levels laid in the surface's coordinates and joined by real entrances, with open pits on
    the surface. Section 7 there lists the owner's remaining choices, including scheduling MIN-E/MIN-F.
- **Deposit consistency (section 4).**
  - Every mineral deposit (surface, pit, cave, tunnel) uses the same resource objects and rules: identity, the ore-dot
    sprite, extraction gate, quantities, depletion, inventory transfer, save and accounting.
  - No second economy, and no regeneration unless the common system has it (it has none).
  - Today's system and what to reuse or adapt: [`DEPOSIT_SUSTAINABILITY.md`](DEPOSIT_SUSTAINABILITY.md). The open
    sustainability questions (OD-01, B7-007, MIN-B detail, ownership of found seams) are listed separately there.
- **Universal negotiated procurement contracts (section 5).**
  - Register **CON-01**: any character offers any other a contract for item, quantity and price per unit. It can be
    accepted, rejected or countered; it works player-NPC, NPC-player and NPC-NPC; it conserves goods and money.
    There is no mining-specific wage.
  - Register **MIN-H**: mining labour uses CON-01.
  - Mapping to the job board, manor jobs, tool orders, carriers and the Living Economy's Contract record, the
    eight undecided policy details, and the build question: [`PROCUREMENT_CONTRACTS.md`](PROCUREMENT_CONTRACTS.md).
    It is not Build 16; the owner places it.
- **DVW-A12 rules-to-core refactor (section 6). Approved direction.**
  - The interface handles presentation, input and feedback. Core systems own eligibility, resource requirements
    and consumption, outcomes, inventory and coin transfers, and state changes.
  - Order: **mining, then felling, then crafting**, subject to code dependencies (section 4 below).
  - Safeguards: small, reviewable changes with focused tests; no broad rewrite; existing behaviour preserved
    unless an approved requirement changes it.
  - Before Build 16's automated completion gate, planning and preparation only. Once Build 17 implementation is
    permitted, the work goes on isolated branches. Never destabilize the frozen Build 16 candidate.
  - Regression list for every step: player interactions; NPC interactions; tool requirements; resource
    consumption; inventory changes; action completion and failure; save and load; deterministic behaviour;
    controller and touch input.
- **ECON-P1.1, P1.2, P1.4, P1.5 (section 7).**
  - Still unapproved. Retrieved verbatim and explained in [`ECON_PROPOSALS_BRIEFS.md`](ECON_PROPOSALS_BRIEFS.md),
    one question each.
  - Not to be implemented while awaiting the owner.

## 1. What exists for mining today

- Seams: `World.deposits` `{x, y, ore, amount}`, loaded from `village.json` (15 seams; stone: 3 x 80 = 240). One unit at a
  time by `World.mine_unit` (the cell stays solid, the tile becomes worked-out rock, never refilled); one swing rule for
  everyone, `World.work_mine` (PAR-01). `World.nearest_deposit` scans `deposits` only, so villagers never mine boulders.
- Node data: `ResourceNodes` and `game/data/resources.json` (iron, coal, stone, copper, gold seams; boulder).
- AI: `NPCBrain._miner` (labourers mine stone, or coal when nobody buys stone; miners turn manor hands when all is worked
  out), `_wanted_ores` (an `rng.randf` draw), the labour market's `ore_per_miner`.
- Trade: `NPCBrain.BUYS`, `NOT_EXPORTED`, `_caravan_imports` (ore and coal under 10 left), `_caravan_stone` (20 at markup 2).
- Manor quarry: `ManorWork.post_quarry` (quarry_qty 10, quarry_wage 6).
- Recipes: smelting (2 ore + 1 coal at the forge), tools and cart iron at the anvil; nothing consumes stone except
  building costs and the manor's works.
- Mine carts, rails and the adit are decoration tiles only (`tools/build_village.py::mine`).

## 2. Phase by phase

| Phase | Builds on | Missing |
|---|---|---|
| MIN-A audit and design | all of section 1 | the architecture document and acceptance tests; the SET-A capability schema (roadmap) |
| MIN-B stone after ore, quarry chain | `mine_unit` already leaves a solid rock cell; `ManorWork` quarry; `_caravan_stone` | a second finite stone pool per seam; `ResourceNodes` returning stone after ore; villager boulder quarrying; stone handling (raw stone vs blocks is an open spec question). Covers B7-007, B7-006 (wage), ECON-P1.1/P1.2 if approved, OD-01 |
| MIN-C prospecting | `Overworld` hashed generation; `World.work_craft`; job markets | clue overlay, prospector and assayer jobs, toolkit and sample recipes, uncertain assays, a record of who knows a discovery (no knowledge system exists) |
| MIN-D hidden deposits, capability levels | `World.deposits` (load merge keyed on x,y) | seeded hidden deposits and their reveal; settlement capability state (with SET-A); the spec's adoption rules |
| MIN-E open pit | only `set_solid` | depth (section 3); dirt, topsoil, spoil items |
| MIN-F underground | `RoofFade` cutaway; `Carts` | interior space, track and cart recipes, supports, lighting |
| MIN-G validation | `economy_sim` deposit ledger, `conservation_test`, `sim_gate` | census of the new pools and state; save fixtures |

## 3. The depth question (MIN-E, MIN-F): the map has no depth

(Superseded in detail by `UNDERGROUND_ARCHITECTURE.md`, which compares three options on the owner's 12 criteria.)

One flat plane: `VillageMap.solid` is one byte array and one `AStarGrid2D` (`is_solid`, `set_solid`, `find_path` take no
level); map layers are draw order only (`MapView`); cliffs are solid cells; the overworld `Chunk` has no height; saves
store changes, not terrain. **Owner decision needed at MIN-A:** (a) a staged pit on one plane (per-cell depth or stratum,
ramps drawn, walkable), feasible in the current model; or (b) separate interior grids with portals (a second map, scene
switch, multi-map pathing and saves), a large architecture change. Without one, MIN-E/F move to Build 20 or later, as
the roadmap allows, and Build 17 ships A-D and G.

## 4. DVW-A12 (rules held in UI code; `docs/release/BUILD_16_AUDITS.md`)

The audit's line numbers are out of date: R1-R3 are partly moved (`World.work_mine`, `work_felled`, `work_craft`,
`player_gain`). Still in `main.gd`: the pickaxe check, a duplicate gold check and the swing-time formula (R1), felling
(R2), sapling planting (R4), loot (R5), xp award (R6), combat and death (R7-R8), assault as a crime with a hard-coded 15
tiles (R9), livestock killing as theft (R10), Fireball (R11), reach checks (R15), theft default (R16), the field-owner
prompt (R17), rest (R18), sprint (R19); in `game_ui.gd`: learning Fireball (a direct coin transfer, R12), trading xp
(R13), pickpocket reach (R14), stolen marks (R20), the helper's budget (R21). Priority: R1-R3 first (they overlap mining),
then R8/R9, R12, R14/R15.

## 5. Shared files (do not touch until Build 16 is frozen)

`npc_brain.gd` (miner, caravan, reeve, labour market), `world.gd` (deposits, save, SAVE_VERSION), `manor_work.gd`,
`balance.json`, `resources.json`, `recipes.json`, `items.json`, `skills.json`, `tools/check_resources.py`,
`tools/check_materials.py`, `economy_sim.gd`, `conservation_test.gd`, `run_tests.gd`, the interaction manifest. Mostly
Build 17 only: `overworld.gd` (GEN_VERSION 1; PL1-12 touches it too), `village_map.gd`, `tools/build_village.py`,
`save_transfer.gd`, `main.gd`/`game_ui.gd` (DVW-A12), `carts.gd`, `inventory.gd` (DVW-B4).

## 6. Tests

Existing: `world_test` (`_deposits`, `_gold`, `_boulders`, `_player_gain`), `parity_test::test_mining_gate_and_xp`,
`run_tests` (`test_trades_and_works`, `test_simulation`), `start_test`/`play_test` mining, `housing_test` (imported ore),
`od16_test` (caravan), `overworld_test` (rocks), `save_transfer_test`, `conservation_test`, Python `test_resources`,
`test_village`, `test_overworld_tiles`.

To write, by phase: A golden-seed identity of `village.json` and overworld chunks; B a worked-out seam yields stone to a
finite pool then refuses, `mined_stone` equals the pool's fall, caravan stone only under the threshold, the quarry wage
from the treasury; C deterministic clues (some false), toolkit only by `work_craft`, seeded assays that never give
certainty; D nothing hidden in `deposits` before discovery, finite amounts kept over save and load, capability levels
that rise and fall with prerequisites; E/F excavation conserves dirt and stone, no unreachable pit cells (DVW-A10); G
100/365-day multi-seed conservation, a v15 -> v16 save fixture, no spawning across every `mined_`/`imported_` stat.

## 7. Risks

- Saves: new seam fields, hidden deposits, capability state need SAVE_VERSION 16, a migration and a fixture; the load
  merge appends map seams missing from a save, so revealed deposits must be keyed carefully.
- Determinism: clue or deposit placement in overworld chunks is a GEN_VERSION bump unless kept in a separate hashed
  overlay; new `world.rng` draws shift every later stream (use dedicated seeded streams).
- Android: `find_path_world` allocates a temporary A* up to 140x140 a call (costly for distant quarries); a second grid
  per mine level doubles path memory.
- Art: no quarry, cave or minecart art beyond the decoration in use; Puny Dungeon (cave interiors) and Forgotten
  Memories (ramps, cliff steps; 32 px) are "planned" in the asset registry.
- Decisions: OD-01 and the ECON-P1.x proposals are open; any new gameplay mechanic needs the owner (CLAUDE.md section 11).
- DVW-B4 (goods decay) has only tool wear and carcass spoilage to build on; REC-013 depends on it.

## 8. Suggested order

1. MIN-A audit and design with the SET-A schema; put the depth question (section 3), OD-01 and ECON-P1.x to the owner
   together. Documents only.
2. DVW-A12 R1-R3 (before MIN-B: the same `main.gd`/`world.gd` code); R8/R9 and R12-R21 can run beside MIN-B.
3. MIN-B with B7-007, B7-006 and the approved ECON-P1 items: one owner of deposits, `_miner`, the caravan,
   `resources.json`, `check_resources.py`.
4. MIN-C then MIN-D (same files plus `overworld.gd`); fold PL1-12 into the same generator change.
5. In parallel: B14-07 with DVW-A10 (`village_map.gd`, `build_village.py`, the Forgotten Memories import), before MIN-E.
6. In parallel: DVW-B4 then REC-013 (`inventory.gd`, `items.json`, `carts.gd`; after MIN-B's quarry changes).
7. MIN-E/F only if MIN-A settles an architecture; otherwise Build 20 or later.
8. MIN-G last, with WDR-001-C, WDR-003-C, WDR-013-C through `tools/check_materials.py`.
   MIN-G's long runs follow SIM-01 (owner, 2026-10-21): one monitored 365-day `economy_sim` run per seed (1-4, the
   normal game) on the integrated commit, checkpoints every 10 days (days 30, 90, 100 read from it), stopped at the first
   broken ledger; the determinism gate (`sim_gate`, seeds 1 and 2, days 10 and 30 from one run each) stays as it is.
