# PL2-015 farming and livestock: what Build 18 retains and what it defers

Owner decisions: **B18-DP-04** ("keep what is necessary to make Build 18 functional, defer the remainder; audit the actual
dependencies before deferring anything; a deferred feature stays an open, traceable requirement, never marked complete") and
**B18-DP-12** (the player volunteers on the church field; see the last section). Source row: `docs/release/BUILD_11_PUNCH_LIST_2.md`
PL2-015. Design notes: `docs/BUILD_DECISIONS.md` "Farming, livestock and hand ploughing". Code: `game/scripts/core/farming.gd`,
`farm_plots.gd`, `fauna.gd`, `balance.json` "farming". PL2-015 itself stays **open** (partly implemented) until the deferred rows
below are built or the owner closes them.

Status words: **RETAINED** works now (the test shows it); **RETAIN-MINIMUM** needed for animals or farms to survive or operate and
was missing or broken, minimum implemented now; **DEFERRED** not a dependency of the Build 18 simulation (code-path evidence given).

Audit result: every element a Build 18 farm or animal depends on is already RETAINED. No element was missing or broken, so no
RETAIN-MINIMUM code was needed. Five groups are DEFERRED.

## The table

| # | PL2-015 element | Status | Evidence (code path and test) |
|---|---|---|---|
| 1 | Clear and till owned or leased land, any shape | RETAINED | `Farming.till/clear_*`, `land_refusal` (held parcels only), one cell a Use; `FarmPlots.till/clear` for villagers' plots. `farming_test` test_land_and_clearing, test_tilling; `farm_plots_test` test_player_farming, test_household_farming |
| 2 | Craftable hand plough, slower and tiring by hand, faster with it | RETAINED | Item `plough`, recipe `craft_plough`, `balance.json` farming.till hand 7 s/80 stamina, plough 2.5 s/25. `farming_test` test_tilling. Villagers use a plough from pack or pantry (`FarmPlots.plough_in`, `task_minutes`) |
| 2a | Approved horse plough | RETAINED | `Farming.plough_horse`, `buy_horse` (caravan, a settlement's real horse, coins leave the village), `till_cost` horse 1 s/10 stamina. `horse_test` test_buying, test_ploughing, test_feeding, test_save |
| 3 | Wheat, vegetables, herbs | RETAINED | `balance.json` farming.crops (wheat, carrot, potato, herb), `Farming.sow/harvest`. `farming_test` test_crops; the manor's and households' fields: `Farming.sow_field`, `FarmPlots` (INT-171). `farm_plots_test` test_household_work |
| 4 | Seed saving | RETAINED | `seeds_back` on every harvest (player and `FarmPlots.harvest_goods`); farmers keep `seed_keep` from the crop (`Farming.save_seed/keep_seed`). `farming_test` test_crops, test_household_seed, test_seed_seller |
| 5a | Seasons | RETAINED | `Farming.season_rate`, `can_sow_now` (no sowing in winter, growth slows in autumn). `farming_test` test_crops; `FarmPlots.hour` uses the same rate |
| 5b | Weather | DEFERRED | No weather system exists; no crop or animal loss is modelled (`FarmPlots.land_requirement` doc: "the game models no crop losses besides the seed"). Nothing in `world.gd`, `fauna.gd`, `npc_brain.gd` reads a weather state. Not a dependency |
| 6 | Fences and gates | RETAINED | Player pens (`Farming.build_pen`, `fence_cells`), farmland fences (`FarmPlots.build_fence`, gate free, fence solid). `farming_test` test_pens_and_animals; `farm_plots_test` test_fence |
| 7 | Pens | RETAINED | `Fauna.pens`; the village's keeper pens and the player's (`flag player`), one species a pen, hunger, trough, breeding, life stages, a keeper succeeding a dead one (BUILD_DECISIONS: "A pen whose keeper dies ... passes to another farmer"). `farming_test` test_pens_and_animals, test_village_chain; `herd_test`, `aging_test` |
| 8 | Separate coops and roofed shelters | DEFERRED | A pen's fence is the shelter. No animal state depends on a roof or on cold or rain: `fauna.gd`, `farming.gd` have no shelter or exposure term; animals die only of hunger, age or slaughter. Not a dependency of existing animals surviving |
| 9a | Buy animals from keepers | RETAINED | `Farming.buy_animal` (a spare animal out of the keeper's pen, the coins to the keeper). `farming_test` test_pens_and_animals |
| 9b | Buy other animals from the caravan | DEFERRED (the plough horse is RETAINED, row 2a) | Only `buy_horse` reads the caravan; nothing else in the economy or the village's pens needs imported stock (the keepers' pens breed their own). Additional animal-purchasing interfaces are named in B18-DP-04 as deferrable |
| 10 | Trap animals | DEFERRED | Wild animals are hunted with weapons (`Fauna.kill`); the village hunter supplies meat, hides and pelts (BUILD_DECISIONS, wildlife section); `tan_leather`/`tan_pelts` run on that supply. No code path needs a trap item or a trap place |
| 11 | Feed | RETAINED | `Fauna.feed` (the trough), `daily_need`; keepers buy feed in part lots and farmers hold feed for sale (FARM-08B, INT-172). `farming_test` (trough, hunger), `horse_test` test_feeding |
| 12 | Water | RETAIN as is; expanded watering DEFERRED | There is no water need: the trough is the feed (BUILD_DECISIONS "Water is not a separate need"); crops are not watered and none dies of drought. No code path reads a water state. Expanded watering interactions are named deferrable in B18-DP-04 |
| 13 | Breed and raise young | RETAINED | `Fauna` breeding (`next_birth`, only well-fed adults), life stages newborn to adult to old; breeding stock `keep` floor. `farming_test` ("the pair breed in the player's pen", chick stages); `aging_test`, `herd_test`, `refuge_test` |
| 14a | Eggs, milk, wool | RETAINED | `Farming.daily_products`, `collect`; the village's own pens lay and give likewise. `farming_test` test_pens_and_animals, test_village_chain |
| 14b | Meat and hides into leatherwork | RETAINED | `Fauna.kill` gives meat and `hide`; recipes `tan_leather` (hide to leather), `tan_pelts`, `leather_armor`; the tanner buys hides (`NPCBrain.BUYS/OUTLETS`). `farming_test` test_village_chain, test_market |
| 15 | Cooking and trade | RETAINED | Recipes `press_cheese`, `bake_egg_bread`, `weave_cloth`, `sew_bandages`; cook and merchants buy the goods. `farming_test` test_market, test_village_chain |
| 16 | Markets | RETAINED | The same buyers and the player's stall (INT-129). `farming_test` test_market |
| 17 | Later hired help (hired farmhands) | DEFERRED | The household's own members work its plots (FARM-04, `FarmPlots.plan_work`); no code path needs an employed farmhand. B18-DP-04 names it deferrable |
| 18 | Optional, startable with no capital | RETAINED | By-hand tilling needs no tool, seed costs 2 coins (`seed_price`), five seeds for 10 coins. `farming_test` test_tilling, test_crops. Farming is never required by any other system |

## The two questions under the owner's answer

**No Farming skill gate; skills only improve efficiency: verified, nothing gates basic work.**
- `skills.json` "farming" has one tier, "Till, sow and harvest fields" at level 1, which everyone holds (`Skills.level_of` starts at 1). Farming and Husbandry are trained by the work (DVW-B8) and are read nowhere as a condition: `farming.gd` and `farm_plots.gd` have no level test.
- The hand plough recipe asks Crafting 1, the starting level; tilling by hand needs nothing. Skills act only as speed or price: `CapabilityHook.time` (off in the game) and the Trading price bonus on seed.
- Villagers farm by the same rules (`FarmPlots.able`: hurt or not, no skill).

**Bought seed from real stock where the economy supports it: already so; the BUILD_DECISIONS note was stale and is corrected.**
- Since Build 13 (MERCH-01, `Farming.buy_seed_item`) a seed is taken from the seller's own pack (`n.inv`), refused when the seller has fewer ("They have only N"), and paid to the seller through `World.trade` (coins moved, none made). Sellers: farmers and the food stall's merchant, stocked by `seed_stock`, farmers' `seed_keep`, the caravan's `caravan_seed_stock`. Villagers buy by the same call (`NPCBrain._plan_buy_seed`, `FarmPlots._plan_buy_seed`), and the church buys its seed the same way (`Chapel._buy_seed`).
- Tests: `farming_test` test_seed_seller ("buying more than the farmer holds is refused whole", "a farmer with no seed left offers none"), test_household_seed; `conservation_test`.
- What was changed: the prose in `docs/BUILD_DECISIONS.md` (Harvest and seed, Deferred, Open questions) and the `yield_notes` of `game/data/resources.json` that still said "a standing offer, taken from nobody's stock". No game logic changed.

## Deferred records and proposed later builds

The lead enters these in the register as open requirements under PL2-015 (children of the parent, `parent` set), each DEFERRED with
the owner's B18-DP-04 wording, none marked complete. The roadmap (`docs/EXPANSION_ROADMAP.md`) has no farming item; Build 20 is
the Living Economy (EXP-D) and Build 21 is unassigned, so every proposal below is the Build 20+ backlog, with a fitting roadmap
item named where one exists. All are proposals; the owner places them.

| Deferred record (proposed id) | Covers | Proposed build |
|---|---|---|
| PL2-015-COOPS | Additional coops and shelters as separate roofed buildings; animals' shelter from cold and rain | Build 20+ backlog, with a weather system (below) because a shelter needs something to shelter from |
| PL2-015-TRAP | Expanded trapping (a trap item, set and checked traps, rabbits and small game) | Build 20+ backlog; fits the ecology strand of LE-05 (construction, ecology, mining, bandits, regional links) best |
| PL2-015-BUYANIMALS | Additional animal-purchasing interfaces: animals other than the horse from the caravan, buying from the settlements' herds | Build 20+ backlog; fits LE-05 (regional links) and the settlements' real herds (SET-C) |
| PL2-015-WATER | Expanded watering interactions, with weather, drought and crop loss | Build 20+ backlog, one weather-and-water item |
| PL2-015-HIRED | Hired farmhands | Build 20+ backlog; fits LE-03 (production, job choice and household budgets) |
| PL2-015-OTHER | Oxen and other draught animals, riding and horse-drawn carts, per-crop art, harvesting several cells at once, taking a pen down (BUILD_DECISIONS "Deferred, on purpose") | Build 20+ backlog |

## Player volunteering on the church field (B18-DP-12, DVW-B3-CHAPEL)

Done in this work. The player faces a cell of the church's plot and Uses: harvest a ripe cell, sow a tilled one, till an empty cleared
one, or clear a plant, sapling or stump (an axe in the pack or the church's store). It is the villagers' work path, not a new
activity: `FarmPlots.work_cell` (the one rule for a cell, now also used by `act` for NPCs), `FarmPlots.clearable`, the church's store
for crop and seed, the plot's fence and till rules, and `able` (a badly hurt person does not work it). The crop and its seed back go
to the church's store; the player is paid nothing, takes no crop, and spends their own time and stamina as on their own field. The
farming experience the work trains (DVW-B8) is the one a villager's `fp_work` step also trains. Code: `FarmPlots.church_targets`,
`church_plan`, `church_work`; hooks in `Farming.targets_at` and `Farming.plan`; interaction INT-370; test
`chapel_test` test_player_volunteers; wiki page "The chapel" says so.
Limits: the player is not counted among `Chapel.volunteers` (that list is the villagers chosen at dawn by piety, capped by
`volunteers_max`), so the clergy still work the plot themselves when no villager volunteers, even on a day the player helps.
