# Build 17: mining parity, recoverable trial-pit earth, shovels and digging rights

Register: MIN-D2, MIN-D3 (parent MIN-D), MIN-SHOVEL, MIN-RIGHTS, MIN-SKILLCAP (parent MIN-E); all target Build 17. Branch
`wip/b17-parity` (base `wip/build17` `45554d8`, merged up to `4c68391`). Source: the owner's
consolidated directive of 2026-10-21 (`docs/directives/2026-10-21_build17_consolidated_14_decisions.md`), whose
numbering maps to the register as its header says: the directive's MIN-D-Q2 = MIN-D2, MIN-D-Q3 = MIN-D3, MIN-E-Q4
(shovels) = MIN-SHOVEL, MIN-E-Q5 (rights) = MIN-RIGHTS, MIN-E-Q6 (specialists) = MIN-SKILLCAP. Earlier documents:
`MIN_D_DISCOVERY.md` (its OPEN questions 2 and 3 are answered here), `MIN_E_OPEN_PIT.md` (its OPEN questions 3, 4, 5 and
6), `MIN_F2_STRUCTURE.md` (rubble and fill below ground).

Labels: **OWNER** (the directive's words, binding), **DONE** (implemented and tested here), **DECISION** (an agent
decision on a minor detail under the standing release directive), **OPEN** (for the owner), **DEFERRED** (tracked for a
later build, not built).

## 1. What the owner decided (OWNER)

- MIN-D-Q2: "Count the player as a resident under exactly the same mining-capability rules as NPC villagers, including
  relevant skills and equipment ... The player's equipment remains the player's property ... must not receive an
  artificial capability bonus ... must not be excluded merely because they are player-controlled ... If the player
  leaves the settlement or no longer satisfies the applicable resident criteria, recalculate ... Capability levels must
  not become permission gates, consistent with Q18-9."
- MIN-D-Q3: "Trial pits must produce conserved, recoverable excavated spoil and topsoil ... Integrate trial pits with the
  established MIN-E material system ... Previously approved underground backfilling remains player-directed only. Do
  not introduce automatic NPC tunnel backfilling."
- MIN-E-Q4: "Introduce craftable shovels for topsoil and loose-earth excavation. Retain pickaxes for rock and hard
  materials ... carpenter-made wooden components ... smith-made metal components ... Both tool categories must have
  legitimate durability and wear ... Do not strand existing saves or introduce an unhandled tool dependency."
- MIN-E-Q5: "Preserve open access to suitable common ground for both players and NPCs. Do not create automatic manor
  mining rights, universal royalties, mining permits, mandatory manor authorization, extraction quotas ... Existing
  legitimate property ownership must be respected."
- MIN-E-Q6: "Do not count job titles as substitutes for actual competence ... Appropriately equipped nonspecialists must
  remain eligible to perform suitable excavation work."

## 2. What is built (DONE)

| Part | Behaviour | Where |
|---|---|---|
| Residents (MIN-D2) | `Discovery.residents()`: every living adult villager, then the player while `player_resident()` (the family has a home in the village: `PlayerState.home` names a building that stands). One list, one rule. The resident player's pack and home chest count in `tool_stock` exactly as a villager's pack and household pantry; nothing is moved (the player's goods stay the player's). Losing or leaving the home ends residency; the next dawn's evaluation no longer counts them (and notes the fall with the reason, as for any loss) | `discovery.gd` |
| Practitioners (MIN-SKILLCAP) | `Discovery.practitioner(o, need, used)`: the resident's Skills level in `skill` at least `min_level`, and, when the need names a `tool`, a tool of that kind they can use: their own pack, or one in their household's store (the player: their home chest) not already given to another member (one shared tool serves one practitioner). Tool kinds match by `items.json` `tool` (a rusty pickaxe is a pickaxe). `jobs` is read only where the game's own rule makes a trade the sole performer: the assayer (the smith at the forge, owner MIN-C-Q3) | `discovery.gd`, `capabilities.json` |
| Capability needs | Level 1: a resident with Mining 1 and a pickaxe ("miner"); level 2: a resident with a prospector's kit ("prospector") and the smith-assayer; level 3: two residents with shovels ("excavator", formerly a job nobody had); level 4: two residents with Mining 3 and a pickaxe ("skilled miner", formerly miners/labourers by title). Levels stay reported only (Q18-9) | `capabilities.json` |
| Trial-pit earth (MIN-D3) | A trial pit digs one cell of the open pit's earth layers down to the rock face (`OpenPits.earth_column`: 2 topsoil, 3 dirt, 3 spoil; the same layer table, so the numbers cannot drift). Each unit enters the books as `trial_ground_<item>` (the pool) and is counted `dug_<item>` (goods made, by `World._work_goods`, the digger's own rule), and the earth is left in **a spoil pile beside the pit** (a loot pile on the cell south of it, `from` "a trial pit"): physical, counted by the goods census, saved with the world's loot, taken up by anyone (`World.player_loot`), carried, tipped on an open pit's heap or put back into an open pit (`OpenPits.backfill`). Its name does not begin "the ", so it never rots away as a carcass does. No stone is dug (the rock is only reached) | `discovery.gd::trial_dig`, `trial_earth`, `pile_cell` |
| Ledger | `economy_sim.gd`: the pits' pool per item is now start + `pit_ground_` + `trial_ground_` - end = `dug_` - `backfilled_` (a trial pit keeps nothing: its ground left is always 0) | `tests/economy_sim.gd` |
| Shovel (MIN-SHOVEL) | Items `shovel` (tool kind "shovel", durability 120, like the pickaxe), `shovel_blade` (the smith's iron part), `shovel_haft` (the carpenter's wooden part). Recipes `forge_shovel_blade` (anvil, 1 iron bar, Smithing 1, 30 min), `make_shovel_haft` (workbench, 1 plank, Crafting 1, 20 min), `assemble_shovel` (workbench, haft + blade, Crafting 1, 20 min). Player and villagers by the same `World.work_craft`. Icons from the Survival pack through `tools/import_game_assets.py` (Shovel-05; the wooden Shovel-15 as the haft; Metal-Slab-05 as the blade's iron shoe) | `items.json`, `recipes.json`, `game/assets/icons/` |
| Tools by layer | `open_pit.json` layers carry `tool`: topsoil, dirt, spoil "shovel"; stone "pickaxe" (`OpenPits.tool_of`, `tool_needed`; `dig_refusal` names the tool needed). Trial pits need `trial.tool` "shovel". Below ground `MineWorks.tool_kind`: rock "pickaxe", a cell's rubble or fill (loose spoil) "shovel". Each dig wears the tool used by the existing amount (`wear`, Mining's `tool_wear_save` may spare it); a worn-out tool breaks and is gone (`broke_shovel`) | `open_pit.gd`, `discovery.gd`, `mine_works.gd` |
| Who digs what | `OpenPits.held_tool(who, kind)` and `kinds_held(who)`: one rule for the player and a villager. `OpenPits.next_dig(p, from, mover, kinds)` picks only cells the digger's tools can dig. `ManorWork.can_dig`: a trial needs a shovel; an excavation some cell the taker's tools can dig (earth first: a shovel); a tunnel the kind of its face; a quarry a pickaxe. An excavation load ends early (tip, then deliver and be paid, as when the pit stops being wanted) when its digger's tools can dig no cell left. CON-02 dig contracts: the seller needs tools for a diggable cell (reason `tool:shovel` / `tool:pickaxe`, said in words by `Contracts`) | `manor_work.gd`, `contract_services.gd`, `contracts.gd` |
| Made to demand (villagers) | As nails and mallets (PAR-04): the goods merchant stocks `shovel` 2 (`BUYS`); the carpenter (`NPCBrain._carpenter_shovel`) makes one only for a buyer: a haft from its planks, the blade bought from the smith (the carpenter keeps one blade on hand, `BUYS carpenter shovel_blade 1`; the smith forges it only for that buyer, `forge_shovel_blade` in its made-to-order list), assembled at the workbench, then sold. A miner whose ore is worked out and who finds posted trial or excavation work closed to it only for want of a shovel (`ManorWork.shovel_would_open`) buys one (`NPCBrain._buy_tool`: the goods merchant, the smith, the carpenter) with its own coins if one is for sale; miners and labourers keep their shovel (`KEEPS`) | `npc_brain.gd`, `manor_work.gd` |
| Player | Trial pit offered with a shovel in the pack; an open pit's cell offered with the tool its next layer needs; staking a pit with a pickaxe or a shovel in hand; below ground a face offered with the tool its next unit needs ("needs a shovel to dig out" for rubble or fill); messages name the broken tool; the swing shows the tool used | `main.gd` |
| Rights (MIN-RIGHTS) | Verified, no code change needed: a pit (`OpenPits.site_refusal`) and a trial pit (`Discovery.ground_refusal`) both go through `World.plant_refusal` (surveyed or held parcels, buildings, the manor's fields, pens, the market, stations, roads, doorways) plus farmland (`farm_plots`, farm parcels); tunnels are cut only under the hill's static rock with rock all round (`Underground.under_rock`), where no parcel can be claimed (`Property.can_claim` refuses solid ground), so no tunnel lies under anyone's land (checked over the whole gallery: 0 of 63 cuttable cells). Common ground is open to everyone; no royalty, permit or quota exists anywhere in the digging rules. Hiring someone to dig one's own pit (CON-02) is the existing consent route | `parity_mining_test` |
| Saves | Save version stays **17**. Nothing new is saved: shovels and their wear are inventory, trial piles are loot, the trial record is MIN-D's. A save without them loads as before | `world.gd` (unchanged) |

## 3. Decisions taken (DECISION)

1. **Residency is having a home in the village** (`PlayerState.home`, a standing building): the equivalent of a
   villager's household and home. Being away on an overworld trip does not end it (a villager at work outside is still a
   resident); selling or losing the last house does.
2. **A shared tool counts once**: a tool in a household's store (or the player's chest) makes at most one member a
   practitioner, so a household of three with one pickaxe is one miner, not three.
3. **The assayer keeps its trade** (`jobs: ["smith"]`): the assay itself is the smith's at the forge (owner MIN-C-Q3);
   counting anyone with Smithing 1 would count people who cannot assay. Every other mining need names no job.
4. **Level 3's excavators are shovel holders**, level 4's skilled miners Mining 3 with a pickaxe; level 1's miner Mining 1
   (everyone's floor) with a pickaxe. Specialisation still grows by experience: diggers gain Mining xp, and skill speeds
   work and spares tools.
5. **A trial pit moves earth only** (2 topsoil, 3 dirt, 3 spoil from the open pit's own table) and needs a shovel only; it
   reaches the rock face without breaking it, so it yields no stone and needs no pickaxe. Time (`trial.minutes` 120) and
   wear (`trial.wear` 2, now on the shovel) are unchanged.
6. **Where trial earth goes: straight to a spoil pile beside the pit** (south cell, always open ground by the trial
   pit's own siting rule), for the player and villagers alike. Not into the digger's pack: villagers have no use or buyer
   for earth (value 0) and would carry it for ever; a pile is physical storage anyone can take up. A trial pit is not
   refilled (only open pits take earth back), and no villager carries trial earth below ground (MIN-F2 backfill stays
   player-directed).
7. **Rubble and fill below ground take a shovel** (loose spoil); cutting rock, including the spoil units of a rock cell
   and a shaft's units, stays the pickaxe's (it is broken rock as it is cut).
8. **Recipe numbers**: blade 1 iron bar (half a pickaxe's iron), haft 1 plank, 30/20/20 minutes, xp 8/4/5; shovel value
   20 (blade 15, haft 3). Agent balance, owner may change.
9. **Supply**: the merchant's stock target of 2 shovels and the carpenter's one blade on hand follow the mallet pattern.
   Only miners buy a shovel on their own (for posted earthwork); a labourer or manor hand takes earthwork when it already
   has one. The player buys or makes their own.
10. **Repair**: no tool in the game is repaired; a broken shovel, like a broken pickaxe, is replaced by buying or making
    another (the "existing economic processes").
11. **`capabilities.json` keeps format `mml-capabilities/1`**: `tool` is an added optional key on `practitioners`, and
    `jobs` stays readable.

## 4. Compatibility (older saves and open jobs)

- An open trial job taken by a villager without a shovel is released at its next plan step and posted again by the reeve;
  open to anyone with a shovel. Taken by the player without one, it refuses the step with the reason and lapses by the
  ordinary `manor_jobs.days` rule.
- A partly dug pit in an older save: each cell's next layer decides the tool, so a cell down to the stone needs a
  pickaxe and an earth cell a shovel; an excavation job's taker digs whatever its tools allow and then delivers.
- Below ground, a face full of rubble or fill needs a shovel holder; the manor's tunnel job at such a face is open only
  to one (`can_dig`).
- No job, pit or trial is stranded while shovels can be made: the recipes need only iron bars and planks, which the
  village already makes, and the carpenter makes them to the merchant's stock.

## 5. Expansion 18 reconciliation (one evaluator)

The prospective Expansion 18 evaluator (`wip/expansion18-preparation`, `game/scripts/core/settlement/industries.gd`,
`holds` for `practitioners`) reads `capabilities.json`'s vocabulary and filters practitioners by `jobs` and `skill`. With
this change mining's needs name `tool` and no `jobs` (except the assayer), so that evaluator, unchanged, would count every
adult with the skill floor as a miner, prospector, excavator or skilled miner whether equipped or not (an over-count),
and never count the player. At its reconciliation gate it must (a) read `tool` (a practitioner fact carrying the tools a
resident can use, with one shared store tool serving one member), and (b) take its practitioner facts from
`Discovery.residents()` (villagers plus the resident player), or call `Discovery.practitioner` directly so there is one
implementation. Recorded here for the lead; Expansion 18's code is not touched.

## 6. Interactions (for the lead's INT entries)

| Trigger | Sources | Affects | Expected |
|---|---|---|---|
| Dawn capability | `discovery.gd::dawn`, `evaluate`, `residents`, `practitioner`, `tool_stock` | the levels and history; the resident player's pack and chest read (never changed) | the player counted by the villagers' rule while resident; reported only |
| A trial pit | `discovery.gd::trial_dig`, `main.gd::_trial_dig`, `manor_work.gd::do_step` | shovel wear, Mining xp, `trial_ground_`/`dug_` counters, a loot pile (goods census), the clue's pits | 8 earth units in a pile beside the pit; no coins, no stone |
| Trial earth reused | `World.player_loot`, `OpenPits.backfill`, `OpenPits.tip` | the player's pack, a pit's ground (`backfilled_`), heaps | goods conserved |
| A pit or tunnel dig | `open_pit.gd::dig`, `tool_needed`, `next_dig`; `mine_works.gd::dig`, `tool_kind`; `manor_work.gd::can_dig`, `excavate_cell`, `step`; `contract_services.gd::means`, `_plan_dig`, `_step_dig` | which tool wears (shovel or pickaxe), which jobs a worker can take, a load's end | earth by shovel, rock by pickaxe, for everyone |
| Shovels made and bought | `npc_brain.gd::_carpenter_shovel`, `_smith`, `_buy_tool`, `_miner`; `manor_work.gd::shovel_would_open` | iron bars and planks used, the merchant's stock, coins between villagers | made only to a buyer's want; bought with own coins |
| The wiki | `wiki_excavation.gd` (provider), `wiki_contracts.gd` (hiring text) | player-facing pages | as built |

## 7. Tests

`game/tests/parity_mining_test.gd` (62 checks): residency (a homeless player's pickaxe does not count; resident it makes
level 1; nothing moved; leaving recalculates to 0); equal contributions need by need for the player and a villager with the
same skill and tool in the pack, at home or none; no bonus without the skill; one shared tool, one practitioner;
deterministic evaluation that draws no rng; a level-0 village's player still digs (Q18-9). Skills not titles (a woodcutter
with a pickaxe is a miner, a "miner" without one is not; a labourer with a kit is a prospector; two shovel holders of other
trades are excavators; only the assayer names a job; a farmer with a shovel may take an excavation, a worker without tools
may not). Trial earth (2/3/3 from the layer table, `trial_ground_` and `dug_`, the pile beside the pit, the census rises by
exactly the earth, no coins, the pool balances, taken up and put back into an open pit, no villager tunnel backfill).
Shovel (item, recipes and stations, the player and a carpenter by one rule, wear a unit, broken and gone). Tools by layer
(a shovel to the rock in a pit, a pickaxe for its stone, not for topsoil; trial pits a shovel; tunnels rock a pickaxe,
rubble or fill a shovel). Villagers (the smith's blade has the carpenter as buyer, the merchant stocks shovels, the
carpenter sets to work, a miner closed out of a trial only for a shovel buys one at the market, then may take it, keeps
it). Rights (pit sites on common ground with no permit or fee; a household's parcel refuses a pit and a trial pit; the
manor's fields; no tunnel rock under any holding; no royalty, permit or quota in the rules). Saves (version 17, a worn
shovel, the trial pile and record, the census; an older save without the keys). Determinism (same seed and digs give the
same stats, piles, rng and capability; another seed differs).

Updated for the new rule (not weakened: each asserts the shovel where it now applies): `discovery_test` (trial pits with
a shovel; the "player's own do not count" check made explicit as a non-resident player), `openpit_test` (diggers carry
both tools and dig with the layer's; the level-0 village is one where nobody holds a pickaxe), `underground_ext_test`
(level 0 by no pickaxe; the stored level is still 0 when the work is done), `underground_struct_test` (rubble and fill
dug out with a shovel), `services_test` (the dig contract's seller has a shovel; without one the refusal names it).

Results (2026-10-21, on `wip/build17` `4c68391` merged in): 0 failures in parity_mining 62, discovery 65, prospecting
54, openpit 66, quarry 39, underground 95, underground_ext 113, underground_struct 90, services 51, contracts 138, crafts
20, parity 55, conservation 8, world 339, run_tests 3544, start 499 steps, play 39 steps, wiki_test all passed;
`check_resources` 28 nodes 0 problems, `check_materials` 0 broken references and 0 stale exceptions (the four shovel-part
findings excepted like the cart parts), `check_assets` 0 problems, `check_interactions` 0 problems, unittest 105 OK.

`economy_sim.gd --days 30 --seed 1`: `LEAKS: currency 0; items {}; deposits []; animals {}`; day 30 alive 107, coins 4914
(fingerprint `c86937d59dfe7ec0fe3d12163a064b60`), against the same base without this work (`4c68391`, run here) alive
109, coins 4918 (`1b9459281e412bb36d11a44d46000c76`). The behaviour changed as expected: the carpenter made 3 shovels for
the goods merchant (7 blades forged, 5 hafts, 3 of each assembled; a blade or haft is left on hand per smith and
carpenter), 7 trial pits were dug with shovels and left 14 topsoil, 21 dirt and 21 spoil in piles, and a trial job was
still open at day 30. On the base, the trial pits had been used up and the manor had staked an open pit, with 42 topsoil
dug by pickaxe; here no pit was staked within 30 days (the trial pits took longer while shovels were made: a legitimate
pace, shovels being obtainable). Iron bars made 261 against 235. Births 12 against 16 and deaths 5 against 7 (old age
only; nobody starved in either run) account for the population difference: the random stream diverges once the
smithing and carpentry differ.

Not looked at on a screen: the shovel icons in the inventory and the trial pile on the map (headless only).

**For the documentation worker:** `game/scripts/core/wiki_mining.gd` (not edited here, as directed) still says the open
pit and the trial pit are dug with a pickaxe (its open-pit page "where" and "hint", the trial-pit paragraph, the
open-pit digging and hiring paragraphs), and below ground does not say rubble and fill take a shovel. Those sentences are
now wrong and should point to "Shovels and pickaxes" (`sys:digging_tools`).

## 8. Deferred and owner questions

- **DEFERRED (already tracked by the lead's register work):** farmland improvement with topsoil, road embankments,
  grading, earthworks, landscaping (MIN-E-Q1); bigger pits (MIN-E-Q7). Trial earth is kept and counted for them.
- **OPEN (none blocking):** the shovel's numbers (section 3.8) and the merchant's stock of 2 are agent balance for the
  owner's review. No owner question arises: a consent or agreement route for digging another's land does not exist and is
  not needed for Build 17 (refusal is the safe default the directive allows: "may require the appropriate owner's
  consent"); it belongs with the negotiated-agreement work already deferred under CON02-S.
