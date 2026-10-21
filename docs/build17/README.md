# Build 17 developer reference: index

Register: WIKI-B17 (documentation reconciliation), under WIKI-01 (CLAUDE.md section 3, "Wiki and documentation
maintenance"). Branch `wip/b17-wiki`, from `wip/build17` `b4ebc55`. This index lists each Build 17 system, its design note,
its register ids, its tests (the suites `.github/workflows/tests.yml` runs, under `game/tests/`) and where the player
reads about it. The player wiki is the in-game one (`game/scripts/core/wiki*.gd`, checked by `game/tests/wiki_test.gd`);
these notes are the developer layer: architecture, data ownership, parameters, limitations, saves.

Statements in the wiki were checked against the code, not only these notes. Where a note and the code differ, the code is
right and the difference is listed under "Corrections" below.

## Systems

| System | Design note | Register ids | Tests | Player wiki |
|---|---|---|---|---|
| Underground architecture: level maps tied to surface portals, the adit gallery, level router, save keys | `MIN_A_ARCHITECTURE.md`, `UNDERGROUND_ARCHITECTURE.md` | MIN-A, OD-28, OD-29 | `underground_test` | `sys:mining_underground` |
| Stone after ore (grey host rock), villagers quarry boulders and host rock, the caravan's stone rule, B7-006 and B7-007 | `MIN_B_QUARRY.md`, `DEPOSIT_SUSTAINABILITY.md` | MIN-B, B7-006, B7-007, MIN-STONE-Q, OD-01, OD01-QUEST | `quarry_test`, `run_tests` | `sys:mining`, `node:*_seam`, `node:boulder` |
| Prospecting: clues, kit, samples, the smith's assay, the prospector job | `MIN_C_PROSPECTING.md` | MIN-C, MIN-C-Q1, MIN-C-Q2, MIN-C-Q3 | `prospecting_test` | `sys:prospecting`, `node:prospect_clue` |
| Discovery: trial pits open finds as ordinary seams, settlement mining level (reported only), the manor's survey and trial jobs | `MIN_D_DISCOVERY.md` | MIN-D, MIN-D-Q1..Q3, Q18-9 | `discovery_test` | `sys:prospecting`, `sys:mining` (village level), `sys:manor_jobs` |
| Open pits: staking, layers, terraces and ramp, spoil heaps, backfill, the manor's excavate job | `MIN_E_OPEN_PIT.md` | MIN-E, MIN-E-Q1..Q5 | `openpit_test` | `sys:open_pits`, `node:open_pit`, `sys:mine_backfill` |
| Underground works: the cave (level -2), tunnels, timber supports, track, minecarts, stacked levels | `MIN_F_UNDERGROUND.md` | MIN-F, MIN-F-Q1..Q5, MIN-H | `underground_ext_test` | `sys:mining_underground`, `sys:minecarts`, `node:tunnel_rock` |
| Stability and collapse, support and ladder wear and repair, hidden ore, the manor's tunnel job, the minecart-or-carry choice, shafts and deeper levels, player-only backfill | `MIN_F2_STRUCTURE.md` | MIN-F2, MIN-F2-Q1, MIN-F2-Q2 | `underground_struct_test` | `sys:mine_stability`, `sys:mine_shafts`, `sys:mine_backfill`, `sys:minecarts`, `sys:manor_jobs` |
| Goods contracts: offers, counters, the face-to-face signing rule, obligations, villagers' own orders | `CON01_COMPLETION.md`, `PROCUREMENT_CONTRACTS.md` | CON-01, Q-C1..Q-C9 | `contracts_test` | `sys:contracts` |
| Service contracts (dig your pit, survey a stain) in the CON-01 engine | `CON02_SERVICES.md` | CON-02, CON02-S-1..S-6 | `services_test`, `contracts_test` | `sys:contracts` |
| Goods that spoil and wear, ways through a cliff | `BUILD_17_PLAN.md` | DVW-B4, B14-07 | `decay_test`, `terrain_test` | `sys:decay`, `sys:cliff_ways` |
| Saves: Build 16 save into Build 17, version 17, per-system keys (`underground`, `prospecting`, `discovery`, `pits`, `mine_works`) | `SAVE_MIGRATION.md`, and each note's "Saves" row | (CLAUDE.md section 7) | `save_transfer_test`, `world_test` | `sys:saving` |
| Mining equipment made to order and procured by the manor, shore jobs, miners' minecarts; a collapse's outcome (survive or die, escape or trapped) | `MIN_EQUIP_COLLAPSE.md` | MIN-EQUIP, MIN-COLLAPSE, MIN-F2-Q1, MIN-F2-Q2, HEALTH-01 | `equip_test`, `underground_struct_test` | `sys:mine_equipment`, `sys:mine_collapse`, `sys:mine_stability` |
| Shovels and pickaxes, trial-pit earth, where you may dig, the resident player in the capability count | `MIN_PARITY_SHOVELS.md` | MIN-D2, MIN-D3, MIN-SHOVEL, MIN-RIGHTS, MIN-SKILLCAP | `parity_mining_test` | `wiki_excavation.gd` pages |
| Raw stone dressed into building blocks | `STONE_01_BLOCKS.md` | STONE-01, STONE-Q1..Q3 (STONE-02..06 Expansion 18) | `stone_test` | `sys:stoneworking`, `todo:stonecutters` |
| Determinism and the 30-day run | `DETERMINISM_GATE.md` | MIN-G, B17-DIR | `economy_sim`, `conservation_test` | none (developer only) |

Common to all: `run_tests`, `world_test`, `start_test`, `play_test`, `parity_test` (one rule for the player and a villager),
`wiki_test`. `python3 tools/check_resources.py` and `tools/check_materials.py` read the node and material data these
systems share (`game/data/resources.json`).

## Data files (parameters live here, never in the wiki text)

`game/data/underground.json`, `mine_works.json`, `open_pit.json`, `prospecting.json`, `discovery.json`, `capabilities.json`;
`balance.json` (`quarry_host_stone`, `manor_jobs`, `contracts`, `caravan_*`). The wiki reads the counts a prompt shows from
these, so a changed parameter cannot leave the wiki wrong; formula values (stability weights, assay confidence, collapse
rate) are deliberately not in the wiki.

## Wiki conventions used for these systems

- Mining pages are `game/scripts/core/wiki_mining.gd` (`sys:mining` is the hub). Contracts and decay stay in
  `wiki_contracts.gd`; the manor's job board is `sys:manor_jobs` in `wiki_manor.gd`.
- `WikiMining.NODE_TEXT` and `USE_TEXT` give the player-facing wording for the mining nodes and goods. `resources.json`
  keeps its code-facing text for the manifests (`docs/systems/`); `Wiki._nodes` and `Wiki._items` prefer the override.
- "Not in the game yet" (`todo:` pages) holds approved but unbuilt ideas: reuse of excavated earth (EARTH-01), larger and
  deeper pits (PIT-02), selling prospecting information (INFO-01), contract advances (CON-03), pay for results (CON-04),
  disputes (CON-05), farm labour contracts (CON-06), villagers hiring on their own (CON-07), a separate signing line for
  services (CON-08), and the health placeholders (HEALTH-01). When one is built, delete its `todo:` entry and document it
  on the system's own page in the same change.
- (Done.) A collapse's effect on a person is on `sys:mine_stability` and `sys:mine_collapse` (MIN-COLLAPSE, merged).

## Corrections made while verifying

- `sys:contracts` said a villager may offer the player a work contract. No villager does in play (CON02 live use: none;
  the engine and the tests support it). The sentence is removed and the "Not in the game yet" entry says only the player
  hires.
- The manor's job board had no wiki page at all (haul, mend and quarry predate Build 17). `sys:manor_jobs` covers every
  kind; the tunnel and backfill kinds are never offered to the player.
- The caravan page's stone line, `place:mine`, `guide:mine`, the miner, laborer and prospector texts and the seam, boulder
  and pit nodes described the pre-Build 17 mine (no adit to enter, no stone after ore). Updated.
- `MIN_D_DISCOVERY.md` and `MIN_E_OPEN_PIT.md` say capability level 3 needs two "excavator" practitioners. No such job
  exists, so the settlement level cannot pass 2 (levels 3 and 4 are reported but unreachable until MIN-SKILLCAP changes the
  counting). `sys:mining` says the report stops at the second level; update it with MIN-SKILLCAP.
- `MIN_F_UNDERGROUND.md` section 4 lists open owner questions that MIN_F2 answered; read section 5's note there first.

## Known documentation gaps (not Build 17 mining)

- Most `node:` pages outside mining (trees, flowers, wheat, animals) still show code-facing text from `resources.json` in
  "Where" and "Comes back?". They should get the same player-facing override as the mining nodes.
- `JOB_TEXT` has a `prospector` entry, but `Population.JOBS` has no `prospector`, so there is no `job:prospector` page;
  `sys:prospecting` covers the trade.
