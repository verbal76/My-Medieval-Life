# MIN-D: finite deposit discovery and settlement mining capability (Build 17)

Register: MIN-D (parent EXP-A; depends on MIN-C). Branch `wip/b17-mind` (base `wip/build17` `443bddb`, merged up to
`53feeff`). Spec: the Mining and Industrial Development expansion
(`docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf`) sections 3, 4, 8, 9 and 11, phase D ("Add new
finite deposit discovery and settlement capability levels with autonomous NPC adoption"); `MIN_A_ARCHITECTURE.md`
section 9 (SET-A schema); `MIN_C_PROSPECTING.md` section 4; `DEPOSIT_SUSTAINABILITY.md` section 6 item 5; owner
decisions OD-28, OD-29 and the Build 17 combined direction of 2026-10-21 (B17-DIR,
`docs/directives/2026-10-21_build17_combined_integration_direction.md`).

Labels: **APPROVED** (owner decision or approved spec), **DONE** (implemented and tested here), **DECISION** (an agent
decision under the standing release directive: a minor detail, recorded here and in `game/data/discovery.json` or
`game/data/capabilities.json`), **OPEN** (the owner's).

## 1. What is asked (APPROVED)

- "Newly located deposits remain finite"; "Ore bodies and stone layers remain finite. No automatic replenishment";
  "Prospecting does not guarantee success; expansion needs time, labor, materials and investment" (sections 2 and 9).
- Capability levels 1-4 are "the owner's stated progression" (level 5 a proposal, not built); "Advancement requires
  real prerequisites and can regress if workers, equipment or knowledge disappear" (section 3).
- "A village with sufficient capability may train a prospector, commission equipment, investigate clues, open a
  quarry or expand a mine without a player issuing orders. A failed prospecting venture costs time and resources"
  (section 8). Acceptance: "The settlement can advance from surface extraction to prospecting through real
  prerequisites and NPC agency" (section 11).
- B17-DIR: the existing ore-bearing rock objects and depletion mechanics everywhere; no separate regeneration, no
  automatic ore creation, no mining-specific wage; independent mining and negotiated arrangements (CON-01) kept;
  prospector pay: support manor commissioning without making the manor the only employer, compatible with CON-01
  (MIN-C-Q1); no sharing, selling, ownership, access or extraction rights for discoveries (MIN-C-Q2); the smith stays
  the assayer (MIN-C-Q3).

## 2. What is built (DONE)

| Part | Behaviour | Where |
|---|---|---|
| Hidden until dug | A clue's body (MIN-C) stays geology. Nothing is added to `World.deposits` by generation, prospecting or knowledge; the caravan, the labour market, `Quests.deposit_left` and capability see only seams that exist (`DEPOSIT_SUSTAINABILITY.md` 6.5: count only discovered seams) | `discovery_test` |
| Trial pit | `Discovery.trial_dig(who, clue, cell, tool)`: one rule for the player and a villager (PAR-01). Needs a pickaxe, a cell of the clue's area that was open in the village's static layout with open ground on its four sides (so a seam there blocks no road, door or yard), clear now (`World.plant_refusal`, no farmland, nobody standing there), not dug before; the clue not opened and with pits left (`trial.per_clue` 4). Costs `trial.minutes` 120 (Mining `mine_time`), wears the pickaxe 2 (`tool_wear_save` may spare it), earns 6 Mining xp. Counted `trial_pits`, `trial_misses` | `discovery.gd` |
| Opening | Only when the body lies within `trial.reach` 2 cells (Chebyshev) of the pit. The body becomes **an ordinary seam record** on the pit's cell, level 0 (OD-29: open workings on the surface): `{x, y, ore, amount, found, found_by, found_day}` plus its MIN-B host rock (`quarry_host_stone`); solid, drawn with its ore's sprite (`deposit_tiles`), found by `deposit_at`, an instance of the same `resources.json` seam node, mined by `World.work_mine` (pickaxe, gold gate, extra-ore chance, wear, 8 xp, `mined_<ore>`), worked out to the hollow rock, then quarried for stone and opened like any seam (OD-28). Never refilled | `Discovery._open_seam` |
| Amount | The body's finite amount: the village map's own per-seam amount for its ore (`village.json`: iron 60, coal 50, copper 30, gold 8) x grade / 5, rounded up. No seam bigger than the village's own (bigger deposits were ruled out) | `body_amount` |
| Books | `found_<ore>` and `found_stone` count the pool entering the books; `economy_sim`'s deposit ledger is start + found - end = mined, so a seam opened during a run is checked like the rest | `economy_sim.gd` |
| Capability | `capabilities.json` (`mml-capabilities/1`, the SET-A schema). `Discovery.evaluate` derives the level from the world each dawn (`World` daily, before the labour market): the highest level whose needs, and every lower level's, all hold. History of changes `{day, industry, from, to, why}` and a journal note on rise or fall | `discovery.gd`, `capabilities.json` |
| Level 1 Surface extraction | Ore or stone left on the surface the village's workers reach; a living miner or labourer; a pickaxe held by a villager, a household or the manor's yard; transport (a handcart, or carrying by hand as the miners do) | data |
| Level 2 Prospecting and assay | A living prospector; a smith with Smithing 1 (the assayer, MIN-C-Q3); a forge; a prospector's kit held in the village; a discovery the manor knows (`Prospecting.findings("manor")` with ore) | data |
| Levels 3 and 4 | Open pit (excavators, a pit ramp, handcarts) and underground (a portal, timber supports, two miners with Mining 3). Pit ramps and timber supports are MIN-E/MIN-F's and none exist, so neither level can hold yet. The needs are in data so MIN-E/F only add the structures | data, `Discovery.structures` |
| Adoption: the prospector | `NPCBrain.job_market` has a `prospector` place (`Discovery.prospector_place`): open while nobody prospects (whatever the capability level), some clue has ground left and the manor could fund a survey. Its pay is prospectors' real earnings, or before any, a survey's wage over `pay_estimate_days`. `seek_work` weighs it with the other jobs by the ordinary rules. The prospector gets its kit as MIN-C built (buy, or a CON-01 order to a smith) | `npc_brain.gd` |
| Adoption: the manor commissions | Two kinds on the reeve's ordinary job board (`ManorWork`, open to the player and villagers by the same rules, the wage set aside from the treasury above its reserve, paid for the labour whatever is found): **survey** (one at a time: take 2 samples of a clue the manor has heard nothing of with one's own kit, have a smith assay them, paying the fees on the way, report the readings at the manor; wage 22; needs a kit and the fees in hand; not for manor hands) and **trial** (one at a time, once the manor knows a find: a pit at the cell nearest the readings the manor knows, for the most certain find of at least 0.3 confidence; wage 8; needs a pickaxe). Jobs the village can no longer do or need are taken down untaken. A prospector takes a survey before prospecting on its own; a miner whose ore is worked out takes a trial before quarrying stone | `manor_work.gd`, `prospecting.gd::plan`, `npc_brain.gd::_miner` |
| Player | The cell ahead in a clue's area with a pickaxe: "Dig a trial pit here"; the manor's survey and trial steps at their places (sample, assay at a smith, report at the manor's door, dig) | `main.gd`, `game_ui.gd` |
| Saves | Save version stays **17**. New key `"discovery"` `{gen, dug, levels, history}`; opened seams are in `deposits` (with `found`) and their cells are solid again on load unless quarried away. Absent (a 16 save, or 17 before MIN-D): nothing dug, levels computed from the world, no history. Survey jobs carry `taken` and `sids` in `manor_work` | `world.gd`, `discovery.gd::load_dict` |

## 3. Decisions taken (DECISION)

1. **A trial pit is the real work that opens a find**: digging (time, wear) within reach of the body; a body under a
   road, building or yard cannot be reached (seeds 1, 2 and 7: 13 of 25 bodies are reachable from clear ground).
   Digging moves no earth items: spoil and topsoil are MIN-E's open item question.
2. **The seam lies on the pit's cell, on the surface**, solid like every seam; the four-open-sides rule keeps it from
   blocking anything. Numbers: reach 2, 4 pits a clue, 120 minutes, wear 2, 6 xp.
3. **Amount** = the village's own per-seam amount x grade / 5 (no new quantity formula; never bigger than a village
   seam). The body is generated geology revealed by work, not ore created: it existed from the seed, unknown.
4. **Capability is the villagers', households' and manor's**: the player's own tools and skills are not the
   settlement's. Levels are sequential; carrying by hand counts as transport (as the miners carry today).
5. **Prospector compensation (MIN-C-Q1, as directed)**: the manor commissions surveys and trial pits as ordinary
   manor work paid for the labour. It is not the only employer: a prospector may still prospect on its own (MIN-C),
   the kit is a CON-01 order, and ore and stone stay sold by miners on their own or by CON-01 contracts. No finder's
   fee and no sale of knowledge (MIN-C-Q2: knowledge stays as MIN-C left it; surveys report readings to the manor as a
   prospector already reported finds). No ownership or rights on opened seams.
6. **Assay fees on a survey are the worker's**, paid from the wage (the wage covers them); so a survey needs the fees in
   hand and manor hands (paid a day's wage, no job wage) take none. A survey's own samples are assayed first.
7. **The first find needs a level-2 village** before the manor commissions pits; the player may dig at any time.
8. Levels 3 and 4 are defined but cannot hold until MIN-E/MIN-F build ramps and supports.

An earlier version of this branch paid the reporter a finder's fee from the treasury; it was replaced by the survey
job before commit under B17-DIR (MIN-C-Q1, MIN-C-Q2).

## 4. Owner questions (OPEN; not built)

1. **Any buyer commissioning prospecting by CON-01.** CON-01 contracts are for goods; a survey is a service. A business
   or the player commissioning a survey would need a service contract (the Living Economy's OD-LE-03). Today the
   manor's board is the commissioning route, and anyone may prospect on their own. Recommendation: add service terms to
   CON-01 when OD-LE-03 is decided.
2. **Should the player's tools and skills count toward the settlement's capability** (a player living in the village
   as a miner)? Built: they do not.
3. **Trial pit spoil**: whether digging should yield dirt or topsoil items (with MIN-E's item decision).

## 5. Interactions (for the lead's INT entries)

| Trigger | Sources | Affects | Expected |
|---|---|---|---|
| A trial pit | `discovery.gd::trial_dig`, `main.gd::_trial_dig`, `manor_work.gd::do_step` | pickaxe wear, Mining xp, the clue's finite pits, the ledger | pit recorded, wear, 6 xp; no coins, no goods |
| A body opened | `discovery.gd::_open_seam` | `World.deposits` (one ordinary seam with host rock), collision, the village view, the caravan's import threshold, the labour market's miner places, `Quests.deposit_left`, capability | `found_<ore>` = amount; the seam is mined by `work_mine` and never refilled |
| Dawn | `world.gd` daily, `discovery.gd::dawn`, `evaluate` | capability levels and history, the labour market (prospector place), the reeve's postings | levels only from present assets; rise and fall noted |
| The labour market | `npc_brain.gd::job_market`, `seek_work`, `discovery.gd::prospector_place` | job changes (prospector) | one place while nobody prospects, ground is left and a survey is fundable |
| The reeve's evening | `npc_brain.gd::reeve_day`, `manor_work.gd::post_discovery`, `discovery.gd::survey_target`, `trial_target` | the manor's job board, the treasury (wages set aside when taken) | one survey and one trial at a time; stale ones removed |
| A survey | `manor_work.gd::do_step`, `plan`, `prospecting.gd::take_sample`, `assay` (sample picked), `share` | samples, the smith's coal and forge, fees (worker to smith), the manor's knowledge, the wage | wage from treasury on the report; fees conserved |
| A miner without ore | `npc_brain.gd::_miner`, `manor_work.gd::seek_kind` | trial jobs | the manor's trial pit before quarrying stone |
| Save and load | `world.gd::to_dict`, `load_dict`, `discovery.gd::load_dict`, `world.gd::sync_boulders` | saves, collision, tiles | opened seams solid and drawn after a load; absent key = nothing dug |

## 6. Tests

`game/tests/discovery_test.gd` (64 checks): hidden bodies (no deposit from a find, finite amounts, reachability over
seeds, determinism of the capability); trial pits (pickaxe needed, player and villager by one rule with the same xp,
misses recorded, no coins, a hit opens one ordinary seam of the body's amount with host rock, solid and found by
`deposit_at`, `found_` counted, a misleading stain never yields, a clue's pit limit, the same seam for the same pit in
a second world); the opened seam (the same swing and xp, worked out after its amount, then host rock, never refilled,
the ledger balances); capability (start at 1; all pickaxes gone: 0 with the reason; back to 1; the player's goods do
not count; prospector, kit, smith, forge and a reported find: 2; levels 3 and 4 never; the prospector's death: back
to 1; evaluation draws no rng); adoption (the prospector's place opens and closes by treasury and an existing
prospector, never by level; an adult out of work takes it by `seek_work`); the manor commissions (a survey posted at level 1, a kit
needed, the prospector does it end to end, the manor knows every reading, paid, coins and samples conserved; a trial
posted at level 2, dug by a labourer and paid, a seam only on a hit, coins conserved); saves (the opened seam, its
cell, pits, levels, history and the survey job round-trip; a save without the key and a version 16 save load).
The village view of an opened seam (its ore sprite on open ground) was **not looked at on a screen** (headless).

## Owner decision Q18-9 (2026-10-21): levels never gate

`docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md`: capability levels affect pay scales and production
output only, never permission. The first MIN-D build posted surveys from level 1, trial pits from level 2 and opened the
prospector's place from level 1; those checks are removed (`survey_level`, `trial_level`, `prospector_level` dropped
from `discovery.json`). Each posting still needs its real conditions (a clue with ground left, a find the manor knows,
the treasury's means). In Build 17 the levels are reported only; their effect on pay and output is Expansion 18's
(PROS-18), with the magnitudes an open owner question.
