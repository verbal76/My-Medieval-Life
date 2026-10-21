# Mineral deposits: how they work today and how caves and pits reuse them (Build 17 planning, read-only)

Prepared 2026-10-21 under the owner's directive `docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md`
(section 4, Owner Decision 2: "mechanical consistency across environments, not a newly approved depletion formula").
Planning only; no code or data changed. Code references are to staging `6607000`.

Labels: **VERIFIED** (current behaviour, read in the code named), **APPROVED** (existing approved design),
**HISTORICAL** (earlier unapproved proposal), **RECOMMENDATION** (this document's advice), **OPEN** (the owner's
decision).

## 1. In one paragraph

**VERIFIED.**
- A mineral deposit today is one small record, `{x, y, ore, amount}`, in one list, `World.deposits`.
- Every miner (the player, a villager miner or labourer, a manor quarry hand) takes one unit at a time through one
  function, `World::mine_unit`, by one swing rule, `World::work_mine`.
- The amount only ever goes down. Nothing in the game refills it.
- When a seam is empty its picture changes to the hollow "worked-out" rock and the cell stays solid.
- The caravan sells the village ore, coal and stone once the village's own seams are nearly empty. It never buys
  them away.
- The test harness checks that every unit taken from a seam is counted as mined.

**RECOMMENDATION.**
- Caves and pits should put their seams **in that same list, as the same record**, with one added field saying where
  they lie.
- Everything else (the sprite, the swing, the tool and skill gate, the counting, the caravan rule, the save) then
  applies unchanged.

## 2. How surface deposits work today

| Part | Behaviour | Evidence | Label |
|---|---|---|---|
| The record | `{x, y, ore, amount}`, copied from `village.json` "deposits" when a world starts | `world.gd` line 46 (`var deposits`), `World::setup` lines 128-129 | VERIFIED |
| The village's seams | 15 seams: iron ore 5 x 60 (300), coal 4 x 50 (200), stone 3 x 80 (240), copper ore 2 x 30 (60), gold ore 1 x 8 | `game/data/village.json` "deposits"; placed by `tools/build_village.py::place_deposits` | VERIFIED |
| Boulders (a second, smaller kind) | Grey boulders in the village give stone, 6 uses (large) or 2 (small) by a hash of the cell (`ResourceNodes::boulder_uses`), in `World.boulders`, saved as [x, y, amount]; when broken the cell becomes walkable (`World::_remove_boulder`). Boulders in the overworld are generated and their uses kept in `Overworld.rock_changes` (`overworld.gd::boulder_at`, `note_rock`). **Villagers never mine boulders** (`resources.json` boulder `npc_harvest: false`; `World::nearest_deposit` scans `deposits` only) | as named | VERIFIED |
| Node definitions | Each seam kind (iron, coal, stone, copper, gold) and the boulder is a node in `game/data/resources.json` "nodes" with its tool (pickaxe, required), skill (mining; gold level 3), yields (1 of its ore), `depletion: "finite"`, owner ("Nobody: ... the manor's mining rights are only proposed, P1.2"), theft ("Never theft"). Read through `ResourceNodes` (`def_for_deposit`, `instances`, `node_at`, `remaining`, `can_harvest`), which changes nothing | `resource_nodes.gd`; `docs/systems/RESOURCE_NODE_MANIFEST.md` (generated) | VERIFIED |
| The visible ore dots | `resources.json` "deposit_tiles": one sprite per ore (stone 1964, iron 1966, copper 1744, coal 1746, gold 1965), the plain boulder 1964, the worked-out hollow 1963, the "flecked" ids. `VillageMap::normalise_rocks` draws each seam with its ore's sprite whatever the map says and turns flecked rock with no seam behind it into a plain boulder: "one sprite, one product" (B8-008) | `village_map.gd::normalise_rocks` | VERIFIED |
| Taking a unit | `World::mine_unit(d)` lowers `amount` by 1 and returns the ore, or "" when empty. At 0 it emits a tile change to the worked-out sprite and a note ("A ... seam at the mine is worked out"). The cell **stays solid** | `world.gd::mine_unit` | VERIFIED |
| One swing rule for everyone | `World::work_mine(who, d, into, tool)`: gold ore needs Mining level 3; a skill chance of an extra unit; the unit goes to `into`, counted as `mined_<ore>`; the pickaxe wears unless the skill spares it; 8 Mining xp a unit (PAR-01) | `world.gd::work_mine`, `_work_goods`, `_work_wear` | VERIFIED |
| Who calls it | The player: `main.gd::interact` case "deposit" (the pickaxe check, the gold check and the swing time are still in `main.gd`: DVW-A12 R1). Villagers: `NPCBrain::_miner` plans the trip and `NPCBrain::act` "mine" swings. The manor's quarry job: `ManorWork::mine_into` swings into the job's load | as named | VERIFIED |
| Which seams villagers choose | `NPCBrain::_wanted_ores` (from the first smith's coal-to-iron ratio, and copper on a 15 % draw of `world.rng`), only ores with a buyer (`_buyer_for`), the nearest by straight distance (`World::nearest_deposit`). Labourers take stone, or coal when nobody buys stone. When every seam is empty, miners become manor hands (`_change_job`, "the mine is worked out") | `npc_brain.gd::_miner` | VERIFIED |
| Regeneration | **None.** The only line in the game that changes a seam's amount is the decrement in `mine_unit` (searched: no `amount +=` anywhere in `game/scripts`). Trees regrow (`World::fell`, `tree_regrow_seasons`), wild plants and wildlife recover (refuges), but minerals do not | `world.gd::mine_unit` | VERIFIED |
| The stand-in when seams run out | The caravan sells each smith up to `caravan_import_stock` (iron ore 12, coal 8, copper ore 6) at value x `caravan_import_markup` 1.0 when the village's seams of that ore hold `caravan_import_when_left` 10 or less (`NPCBrain::_caravan_imports`). It sells the raw-goods merchants up to 20 stone a visit at value x 2.0 when stone is that low (`NPCBrain::_caravan_stone`, `_stone_scarce`, via `Quests::deposit_left`). It **never buys** the village's ore, coal or stone (`NPCBrain.NOT_EXPORTED`). Coins paid leave the village into the caravan's finite purse | `npc_brain.gd` lines 69, 3644-3666, 3732-3763; `balance.json` | VERIFIED |
| Other readers of the seams | The labour market opens miner places by total ore left / `ore_per_miner` 40 (`NPCBrain::job_market`). The reeve posts a quarry job only while stone seams hold at least `quarry_qty` 10 (`ManorWork::post_quarry`). Sapling planting keeps clear of seams (`World::plant_refusal`, "Something stands there") | as named | VERIFIED |
| Counting (ledger) | `game/tests/economy_sim.gd` checks, per ore, start amount minus end amount over all `World.deposits` against the `mined_<ore>` counter, and reports any difference. `conservation_test.gd` checks deposits are unchanged when nothing mines. Imports are counted `imported_<id>` | `economy_sim.gd` lines 751-759; `conservation_test.gd` line 42 | VERIFIED |
| Save and load | `World::to_dict` saves `deposits` whole and boulders as [x, y, amount]; `load_dict` restores them, then **appends any map seam missing from the save, matched by (x, y)** (the gold seam added in Build 13). The overworld's rock changes are saved in its own block | `world.gd` lines 3202, 3280-3288; `overworld.gd::to_dict` | VERIFIED |
| How fast they run out | Build 15 runs: iron, coal, copper and gold seams are worked out by about day 20; stone reaches 0 by about day 160-190 (`docs/EXPANSION_ROADMAP.md`). Older runs (Build 7-14): ore by about day 10 (`docs/release/LONG_RUN_SIMULATION.md` line 179) | as named | VERIFIED (measured, not re-run here) |

## 3. The approved rules that govern every deposit

| Rule | Source | Label |
|---|---|---|
| Deposits are finite; "Depleted ore does not automatically replenish"; "No automatic replenishment of depleted veins" | Mining spec (EXP-A), `docs/directives/My_Medieval_Life_Mining_Industry_Expansion.txt` sections 2 and 9 | APPROVED |
| A depleted coloured ore deposit "remains mineable for ordinary stone without regenerating ore" | Mining spec section 11; register MIN-B | APPROVED, not built |
| New deposits come from prospecting and are themselves finite (MIN-C, MIN-D) | Mining spec stage 2; register MIN-C, MIN-D | APPROVED, not built |
| Bigger deposits are ruled out | `docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md` line 77 ("The owner ruled that out") | APPROVED (owner ruling, recorded) |
| Deposit regeneration "not approved yet (investigate first)" | `docs/DECISIONS.md` 2026-10-18 Build 7 corrections | APPROVED (as "not approved") |
| Stone from a defined outside source at real prices and quantities (the caravan's stone) | `docs/DECISIONS.md` 2026-10-18; INT-065 | APPROVED, built |
| The same deposit rules on the surface, in pits, in caves and in tunnels; the ore-dot rock appears in all of them; no second resource economy; no regeneration unless the common system already has it | Directive 2026-10-21 section 4 | APPROVED |

## 4. What caves and pits must reuse unchanged

**RECOMMENDATION.** An underground or pit seam is a record in `World.deposits`, so that each of these applies
without a second copy:

1. **Identity and node definition:** the same `ore` ids and the same `resources.json` nodes (iron_seam, coal_seam,
   stone_seam, copper_seam, gold_seam). No "cave iron".
2. **Visible ore dots:** the same `deposit_tiles` sprites, and the same worked-out hollow. A flecked sprite always
   means a real seam (B8-008).
3. **Extraction:** `World::mine_unit` and `World::work_mine`: pickaxe required, Mining level 3 for gold, the same
   skill effects, wear and xp, for the player, villagers and manor hands alike.
4. **Quantities and depletion:** amounts from the same kind of data. The amount only falls. There is no refill,
   because the common system has none (section 3).
5. **Inventory transfer and counting:** `_work_goods` into the miner's pack or a job load, counted `mined_<ore>`.
6. **Caravan rules:** `_caravan_imports` and `_caravan_stone` sum `World.deposits`, so an underground seam counts
   as the village's ore automatically. See OPEN item 5 below about seams nobody has found yet.
7. **Labour market and quarry job:** they also sum `World.deposits` and need no change.
8. **Save:** saved in the same `deposits` array.
9. **Ledger:** the `economy_sim` deposit check and `conservation_test` cover them, with the index fix below.

## 5. What must be adapted

| Change | Why | Label |
|---|---|---|
| Add a location field to the record: `level` (0 = surface, default), and for pits `depth` | Two seams can share (x, y) on different levels | RECOMMENDATION |
| `World::deposit_at(c)` and `World::nearest_deposit` take the level; nearest-by-distance must not pick a seam on another level, and should prefer reachable ones | Today both match by (x, y) and straight distance only | RECOMMENDATION |
| The load merge in `World::load_dict` keys on (level, x, y), and on an id for seams found by prospecting | Today it matches (x, y) only, so a revealed or underground seam at the same (x, y) as a surface seam would be confused | RECOMMENDATION (risk already listed in `BUILD_17_PLAN.md` section 7) |
| `mine_unit`'s tile change goes to the seam's own level's layer (today it always emits "below", drawn in the village's "below0") | Drawing on another level or map | RECOMMENDATION |
| A placement step for underground seams that applies `normalise_rocks`' rule (seam = ore sprite; flecked without a seam = plain rock) to the level's layers | Same picture rule on every level | RECOMMENDATION |
| `economy_sim`'s deposit check indexes deposits by array position (`start.deposits[i]`). Give each seam an id and compare by id | Seams appended during a run (discoveries, new levels) would shift the comparison | RECOMMENDATION |
| Boulder stone is counted `mined_stone` by `work_mine` but is not in the deposit check. Today only the player mines boulders and the simulations have no player, so the check holds. If boulders, cave rubble or pit spoil become NPC work, count those pools too | The ledger must cover every pool | VERIFIED (observation) / RECOMMENDATION |
| `ResourceNodes` "where" texts mention "the mine north of the village"; add the new places | Journal and wiki accuracy | RECOMMENDATION |

## 6. Unresolved sustainability decisions (listed separately, none answered here)

1. **OD-01, OPEN:** deposit sustainability (proposals P1.1-P1.5) and the mine wage (B7-006). Open since 2026-10-18
   (`docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md`). The briefs are in `ECON_PROPOSALS_BRIEFS.md`.
2. **B7-007:** partly implemented.
   - Done: the stone import (`ae0e01f`, INT-065) and the end of raw-ore export (`NOT_EXPORTED`).
   - Still open: depletion itself, which is the owner's choice among P1.x. The mining expansion (MIN-B..D) is
     the approved direction that answers it.
3. **MIN-B detail, OPEN:**
   - How much stone a worked-out ore seam still holds.
   - Whether quarry stone, building blocks, spoil and topsoil are different items (Mining spec section 12 lists
     this as open).
   - Whether a cell emptied of its stone becomes walkable, as a broken boulder does today.
4. **B7-006 and the mine wage, OPEN:**
   - The owner did not approve "mining wage 15+" (`docs/DECISIONS.md` 2026-10-18).
   - Directive 2026-10-21 section 5 rejects any mining-specific wage system in favour of negotiated contracts
     (`PROCUREMENT_CONTRACTS.md`). B7-006 may therefore be superseded by CON-01 when the owner confirms.
5. **Hidden deposits and the caravan threshold, OPEN (MIN-D):**
   - Should seams nobody has found yet count toward "the village's ore left"? It matters to the caravan rule, the
     labour market and the quarry job.
   - Recommendation: count only discovered seams. A village does not know about ore it has not found
     (bounded knowledge, EXP-D).
6. **Boulders as villager work, OPEN:**
   - Today only the player breaks boulders (`npc_harvest: false`).
   - Making them villager work would be a new stone source, which is a mechanic, so it is the owner's call.
7. **ECON-P1.3 / B7-014, OPEN:**
   - The caravan as a finite regional market.
   - A different finite purse is built (`caravan_purse`, `caravan_allowance`). The register records a
     contradiction to resolve.

## 7. Tests that should guard consistency (to write with MIN-B, MIN-D and MIN-F)

- The same ore gives the same node definition, sprite, gate, wear and xp on the surface, in a pit and on an
  underground level.
- An underground seam never refills over 365 days.
- `mined_<ore>` equals the fall of every pool by id.
- A save made with underground seams half worked loads them at the same amounts on the same level.
- The caravan import starts at the same threshold whether the last seam is on the surface or below.
