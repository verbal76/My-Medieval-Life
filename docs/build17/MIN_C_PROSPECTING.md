# MIN-C: prospecting clues, the prospector, the kit, samples and assay (Build 17)

Register: MIN-C (parent EXP-A; depends on MIN-B). Branch `wip/b17-minc` (base `wip/build17` `2a509f8`, merged up to
`04bf0f7`). Spec: the Mining and Industrial Development expansion (`docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf`)
stage 2, sections 4, 5, 9 and 11, phase C; `BUILD_17_PLAN.md` (row "MIN-C prospecting", order item 4);
`MIN_A_ARCHITECTURE.md` section 9 (SET-A's `records` need); `DEPOSIT_SUSTAINABILITY.md` section 6 item 5.

Labels: **APPROVED** (owner decision or approved spec), **DONE** (implemented and tested here), **DECISION** (an agent
decision under the standing release directive: a minor detail, recorded here and in `game/data/prospecting.json`),
**OPEN** (the owner's), **MIN-D** (left for the next phase on purpose).

## 1. What the spec asks (APPROVED)

- "Prospectors interpret subtle natural clues, investigate nearby terrain with specialized equipment, collect samples
  and have findings evaluated by an assayer or equivalent specialist. A clue indicates a search area, not a guaranteed
  deposit or its exact location. Newly located deposits remain finite." (stage 2)
- Hints "faintly stained or discolored soil, mineral flecks ... a ground stain of a different color"; "plausible
  surface evidence in proximity, with uncertainty and occasional misleading clues"; "An assay can estimate mineral type
  and quality with uncertainty; better tools and experience improve reliability, not omniscience"; "Discoveries are
  recorded and become actionable knowledge only for people or institutions that receive the information" (section 4).
- "A prospecting toolkit should be forge-produced, drawing on existing crafting rules and physical inventories" (section 5).
- Acceptance: "At least one prospecting clue leads to a search area, not a guaranteed exact ore location; failures are
  possible"; "Prospectors and assayers use actual produced equipment and consume actual time and resources" (section 11).

## 2. What is built (DONE)

| Part | Behaviour | Where |
|---|---|---|
| Clues | Stains on open village ground: per 15-cell block a hashed 35 % chance of one, on a cell that is open in the static layout (no road, building, plot, field, pen, stall, station, tree, plant, container or seam). Its look by ore weight (iron 40, coal 30, copper 22, gold 8). 55 % lie over a **body** (ore, grade 1-5, the cell it lies under within the radius); the rest mislead. Seed 1 has 17 clues; seeds 1, 2 and 7 have 25 true and 13 misleading | `Prospecting.generate`, `prospecting.json` |
| Determinism | Integer hashing (`Overworld.hash32`, salts of their own) of the seed and the village's static layout; no `world.rng` draw; not in the overworld's chunks (no `GEN_VERSION` bump there). Generated, not saved (as `Underground`); `Prospecting.GEN_VERSION` 1 | `prospecting.gd` |
| Search area | A disc of radius 4 round the stain. A body lies anywhere in it, not at the stain. Its open cells ("spots") in a hashed order | `generate` |
| Deposits | Nothing is added to `World.deposits`: a body is geology, not a deposit record (MIN-D opens it) | test |
| Kit | `prospecting_kit` (tool, durability 40, value 34): recipe `forge_prospecting_kit` at the **anvil**, 1 iron bar + 1 plank + 1 leather, 50 minutes, Smithing 1, 12 xp. Made only by `World.work_craft`: the player at an anvil, or a smith on a CON-01 order | `recipes.json`, `items.json` |
| Sample | `ore_sample` ("Rock sample", value 0): one a cell of a clue's area, `samples_per_clue` 4 a clue (finite, never refilled). The same rule for the player and a villager (PAR-01): the kit in the pack, an open unsampled cell, room in the pack; the kit wears 1 (Mining `tool_wear_save` spares it), 4 Mining xp, counted `mined_ore_sample`. Where it was taken goes in the holder's **bag** (oldest first), matched to the pack (a sample dropped or passed on leaves the bag; one of unknown origin cannot be assayed) | `Prospecting.take_sample`, `bag_of` |
| Assay | A smith (the "equivalent specialist") awake, at its workplace, with Smithing 1+, a coal and a forge it may use, with no other assay in hand, reads the holder's oldest sample for a **fee of 6 coins** (holder's purse to the smith's), burning 1 coal (`used_coal`); the sample is used up (`used_ore_sample`); the smith works the forge 40 minutes (after the piece of work in hand), earning 6 Smithing xp | `Prospecting.assay` |
| Reading | Confidence = 0.35 + 0.04 x the smith's Smithing + 0.02 x the sampler's Mining (at sampling), between 0.2 and **0.9: never certain**. Over a body: found with confidence x (0.35 + 0.65 x nearness to the body), grade within one step (two below 0.6 confidence); else "nothing worth mining". Over a misleading stain: traces of the stain's ore with (1 - confidence) x 0.5, else nothing. Seeded by the world seed, the sample and the assayer; no `world.rng` draw | `Prospecting.reading` |
| Knowledge | Each reading is a record `{id, sample, clue, x, y, ore, grade, confidence, by, assayer, day, known_by}`. Only `known_by` knows it: the sampler and the smith; a villager prospector walks to the manor and tells it of its finds (`report_find`), adding `"manor"`. `findings(ref)` sums what one party knows per clue (the ore most often found, traces, barren, mean grade, combined confidence at most 0.95) | `records`, `share`, `findings` |
| Prospector | Job `prospector` (workplace "mine"). Its day: report finds the manor has not heard; with a full bag (3) or no ground left, take the samples to the nearest able smith (one assay after another, waiting at the forge); without a kit, buy one for sale, else order one from a smith by a **CON-01 contract** (the kit's value, `npc_order_days`, once a day); else sample the nearest clue it has taken fewer than 2 samples from. Idle: the manor's open work (`_idle_at_work`), as any idle worker | `Prospecting.plan`, `NPCBrain._plan_job`, `act` |
| Player | Standing in a clue's area: "Take a rock sample here" (timed as a mining swing), or without a kit what the stain is and how to sample it. Beside a smith (talk or shop target) while carrying a sample: "Ask X to assay a rock sample (6 coins)": the reading in words after the wait. The rules are `Prospecting`'s (DVW-A12: core owns them) | `main.gd::_prospect_targets`, `_sample`, `_assay` |
| Picture | `ClueView`: each stain a faint blotch of its ore's colour (prospecting.json `color`) and a few flecks, hashed from its cell; procedural pixels at 16 px under the characters, fading with the surface when the player is below. No new art pack. **Not looked at on a screen** (headless session) | `game/scripts/view/clue_view.gd` |
| Icons | Survival pack (already integrated): `Tools/Backpack-05` (the kit, a leather satchel of tools and sample bags), `Stone/Rocks-10` (the sample, reddish fragments), via `tools/import_game_assets.py` with provenance | `game/assets/icons/` |
| Resources | Node `prospect_clue` (match kind `clue`, finite, tool `prospecting_kit`, yields `ore_sample`); `ore_sample` consumed by `assay`; coal as assay fuel; `ore_sample` exception (finite source by design). `tools/check_resources.py` knows the `clue` kind and the `assay` use; `ResourceNodes` lists clue instances, remaining samples and refusals | `resources.json`, generated manifests |
| Saves | Save version stays **17**. New key `"prospecting"` `{gen, taken, samples, bags, records, next_sample, next_record}`; absent (a 16 save, or 17 before MIN-C): nothing sampled, carried or known. Clues come from the seed again. Cells sampled of a clue a later generator no longer makes are dropped with it; records keep | `World.to_dict`, `load_dict`, `Prospecting.load_dict` |

## 3. Decisions taken (DECISION, minor details)

1. **The assayer is the smith** ("an assayer or equivalent specialist"): the forge, its coal and Smithing already exist;
   no assayer job is added. A dedicated assayer can be split off later without changing the record.
2. **Sampling and assay use Mining and Smithing**, not a new skill (skills.json unchanged; `tests/skills_test` reads
   every key).
3. **One kit item** stands for the spec's picks, hammers, sample bags and sieves; it wears per sample. Inputs iron
   bar, plank, leather (a hammer's iron and haft, a leather bag).
4. **Numbers** (all in `prospecting.json`): block 15, 35 % clue chance, 55 % true, radius 4, 4 samples a clue, 2 a
   visit, carry 3, 30 minutes a sample, fee 6, 40 minutes and 1 coal an assay, confidence 0.35 + 0.04/0.02 per level,
   0.2-0.9.
5. **A body is geology only** (ore, grade, cell): no amount, no seam cells. MIN-D decides how a recorded find becomes a
   finite deposit and how big it is.
6. **The fee** is a direct service payment between purses (as a wage), not a contract: an assay is a service, CON-01 is
   goods. The kit, a good, is ordered by CON-01.
7. **The reading is fixed at hand-over** (the smith's forge time follows); the holder waits the assay's time.
8. **Nobody becomes a prospector by themselves** in this phase: the job works when given (tests, and MIN-D's adoption).
   Without an income source of its own a prospector lives on its purse and the manor's open work; that is MIN-D's
   to settle with adoption.
9. **Stains are drawn procedurally** (coloured pixels), so no art pack decision is needed; clue art from Puny World or
   Forgotten Memories could replace it later through the asset skill.
10. **Clues only in the village map** for now; the overworld is left for a hashed overlay keyed by chunk (no chunk
    `GEN_VERSION` bump), as the spec asks for "further geological opportunity" on the future large map.

## 4. For MIN-D (designed to be consumed, not built)

- `Prospecting.findings(ref)`: what a party (a villager, the player, `"manor"`) knows per clue; the "records" need of
  SET-A's level 2 (`{"kind": "records", "what": "discovery", "count": 1}`) can count findings of the manor with an ore.
- `clue.body` `{ore, grade, x, y}`: where MIN-D can open a finite deposit (an ordinary `World.deposits` record, OD-28),
  keyed by `(level, x, y)` in the load merge, once a find is known and dug for. Until then the caravan, the labour
  market and `Quests.deposit_left` see nothing of it (`DEPOSIT_SUSTAINABILITY.md` section 6 item 5: count only
  discovered seams).
- The `prospector` job and its plan; the kit order by CON-01; the manor as the institution told of finds.
- `taken_by`, `samples_left`: what a settlement has already read of its ground.

## 5. Owner questions (OPEN; not built)

1. **Who pays a prospector?** The spec has the settlement "train a prospector, commission equipment, investigate
   clues" (section 8). Options: (a) the manor hires one by a contract or a wage when its capability calls for it (MIN-D
   adoption); (b) prospectors sell finds (a knowledge sale: a new kind of trade); (c) only the player prospects until
   MIN-D. Recommendation: (a), decided with MIN-D's adoption rules.
2. **Should finds be shareable or sellable by the player** (telling the reeve, selling a find)? Not built; the record
   supports `share`.
3. **A separate assayer profession** later, or the smith for good? Built as the smith (decision 1).

## 6. Interactions (for the lead's INT entries)

| Trigger | Sources | Affects | Expected |
|---|---|---|---|
| A sample is taken | `prospecting.gd::take_sample`, `main.gd::_sample`, `npc_brain.gd::act` | inventory, tool wear, Mining xp, the clue's finite pool, the ledger | +1 ore_sample (`mined_ore_sample`), kit wear, 4 xp, one cell used; no coins |
| An assay | `prospecting.gd::assay`, `main.gd::_assay`, `prospecting.gd::npc_assay` | coins (holder to smith), smith's coal, the forge station, the smith's plan, Smithing xp, knowledge records | fee conserved, `used_coal`, `used_ore_sample`, forge held 40 min, a record known by two |
| A prospector without a kit | `prospecting.gd::_get_kit`, `contracts.gd::propose` | CON-01 contracts, the smith's anvil work (`work_craft`) | a contract for 1 kit at its value; the smith forges and delivers it |
| A find reported | `prospecting.gd::plan`, `prospecting.gd::report` | the manor's knowledge (`known_by`) | the manor learns the reporter's finds; nothing else changes (MIN-D acts on it) |
| World start and load | `world.gd::setup`, `world.gd::load_dict`, `prospecting.gd::generate` | clues (static), saves | same clues per seed; no rng draw; absent save key = nothing known |

## 7. Tests

`game/tests/prospecting_test.gd` (54 checks): generation (determinism, seeds differ, true and misleading clues, open
ground, not in deposits, no rng draw); the kit (anvil recipe, work_craft, refusal without it); sampling parity (player
and villager: same rule, xp, wear, ledger, one a cell, finite pool, outside the area refused, bag follows the pack, no
coins); the assay (fee, coal, sample used, forge time, busy smith, known by two, never certain, reading in words,
seeded independent of world.rng, findings, unknown origin refused); uncertainty over 200 readings (misses over a body,
false traces over a misleading stain, a master's confidence capped at 0.9); a prospector's day (CON-01 kit order,
forged and delivered, samples, assays, the report to the manor, coins and goods conserved); saves (round trip exact,
the carried sample still assayable, a save without the key, a 16 save).
