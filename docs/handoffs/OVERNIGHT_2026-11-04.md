# Overnight integration, 2026-11-04 (B25R1, wip/b25r1)

The integration worker ran alone overnight in the owner's low-token mode. This file is the morning report.

## Head and merges

HEAD is `83d6d1a` on `wip/b25r1`. Every merge is a merge commit, and nothing was force-pushed.

| Merge | Branch at | Commit |
|---|---|---|
| water | 49e78a9 | 953e750 |
| region (towns; carries homestead e080bc0/dd35a2e) | 9ce9a2e | 1d024dc |
| settle (hamlets, trips, SettlementPeople) | 084d4f0 | e0b2b1a |
| homestead (incl. 33b1f4b conservation fixes) | 8da7e1f | 7951dee |
| presence | 711d59d | 9f191f2 |
| CI architecture (8 shards, report job, concurrent twins) | 552826b | 65f2665 |

How the conflicts were resolved:
- **Atlases:** there is one `MapView.EXTRA_ATLASES` list. Ids 4 to 8 are roads, Larchrow, Bow.Pixel x2 and props. Ids 9 and 10 are water, animated then still. The padding loop and `_add_water_tiles` are gone.
- **Water stubs:** the homestead `is_water`/`nearest_water` stubs were removed. They were a duplicate-function parse error.
- **Importer order:** road_tiles, then water_tiles, then region_props, with village_tile_sheets last.
- **Fauna:** the led-animal hook runs before the tick-by-tick move.
- **World:** `homesteads.note_player` sits beside the per-frame position notes in `World.update`.
- **Animal drawing:** animals are drawn with Presence's interpolation.
- **Walking rule (EA-01):** the copies in `trips.gd` are deleted. SettlementTrips uses `Presence.road_tiles`, `arrival` and `along`, and Presence's pace and walking hours.
- **INT ids:** sorted by id, with the index regenerated. check_interactions reports 0 problems (438 interactions), and check_requirements reports 0 problems.
- **CI list:** `wilds_test` was in no CI list. It is now in tests.yml.

The CI branch was merged because its validation run 41753190755 produced every shard's report and failed only on the suites the base already failed on.

## Fixes overnight

| SHA | What | Category |
|---|---|---|
| 1d024dc | water goldens; road_types journey picks a trail with a real stretch of each kind; wilds_test: a camp by a stream, and the pre-gen-4 band save is refused (the band's move on load is now checked on a current save) | C (gen 4 map, Q2, Q5) |
| 7951dee | player_homestead sentinel (-1,-1) is now a real cell west of the origin; overworld_test site count | C |
| 6a1d5b2 | Q5 old-save fixtures (see the bullets below this table) | C (Q5) |
| 6a1d5b2 | prospecting_test uses the full coin census | C (proven: without net_paid +9, net_paid +9, full census +0; not a leak) |
| 6a1d5b2 | housing_test also counts builder-made blocks (`builder_own_`, HOUSE-04) | C (the builder cut its blocks) |
| f60772f | tree_test (atlas ids), envoy_test (site ground), courier_live (hamlets have no booth; days ordered by road length), overworld/region_travel site counts, water goldens re-pinned | C |
| 266fc61, 83d6d1a | luxury_test and run_tests' tills: hamlets have no trader | C (B25R1-018 s.5) |

The Q5 fixture fixes in 6a1d5b2:
- Each of these suites now checks that the old fixture is refused with its message, the file kept.
- Each then runs its own purpose on a save of this build's world, shaped like the old save.
- Suites: identity, multiplayer_a1/b/c, message_journal, le06, le07, farm_shared_save and crafts.

Two failures the merges themselves fixed:
- **stone_test, contract_50ore:** pass on the integrated tree. Category A, fixed by homestead 33b1f4b (tin seams).
- **underground_test:** passes. Category B, fixed by homestead 8da7e1f (saves write whole numbers as ints).

Local focused suites on the integrated tree (checks/failures):

| Suite | Result | Suite | Result |
|---|---|---|---|
| presence | 37/0 | regions | 120/0 |
| hamlet | 74/0 | homestead_test | 47/0 before presence; 47/3 after (below) |
| wilds | 71/0 | life_decisions | 27/0 |
| start | 523 steps/0 | player_homestead | 40/0 |
| refuge | 59/0 | identity | 100/0 |
| housing | 117/0 | multiplayer_a1 | 69/0 |
| water | 62, 1 failure left (the route below) | multiplayer_b | 32/0 |
| overworld | 331/5 before f60772f | multiplayer_c | 326/0 |
| road_types | 11/3 | message_journal | 48/0 |
| region_travel | 71/0 | le06 | 22/0 |
| envoy | 31/0 | le07 | 32/0 |
| tree | 45/0 | farm_shared_save | 18/0 |
| settlement_folk | 36/0 | crafts | 20/0 |
| campfire | 16/0 | prospecting | 73/0 |
| outside_interact | 23/0 | underground | 95/0 |
| luxury | 142/0 | stone | 105/0 |
| | | contract_50ore | 19/0 |

## Remaining failures (not fixed: they need the owning worker or a decision)

| Failure | Category | Notes |
|---|---|---|
| A road route runs through a hamlet's houses | A, travel | Seed 1 to Elmcote goes through Milton; seed 2 to Mileham through Brookhurst; water_test's "road to every settlement open" (14 of 15) is the same root. A trial fix (the side road picks the nearest node not past another settlement) cleared seeds 1 and 2 but moved the fault to seed 7, through Higham, so it was reverted. Owner: region/settle worker (`_setup_routes`, `_side_road`, the hamlet site plan). |
| overworld_test: Milton has a home for each of its 5 households (8 buildings) | A | The hamlet site plan meets region's new site_plan. Region/settle worker. |
| road_types / road_wear: stone is 4883 of 9368 main road cells; no dirt-road test cell; 3 sampled road cells not open | A or C, needs a decision | Since the settle merge the hamlets join the network and most main roads read as stone (RegionRoads.main_kinds); road_wear finds no dirt road. The 3 closed cells are the hamlet-route root (F). Region worker. |
| homestead_test after the presence merge: the house is not built, so no sleep | A, homesteading x presence | It passed at 7951dee. Presence's fixed tick and live range stop the far homesteader's build trips. This means homesteading and presence do NOT yet work together. Presence and homestead workers. |
| courier_live: "Wulstead paid from its own till" (+13 instead of +5) | C candidate | The Wulstead residents SettlementPeople makes live carry their trip's coins across the ledgers (`people.gd _hand`: outside_coins_out, coin_sources), as designed. The check needs a count of those crossings. It is the same flow the full census already balances. Settle worker. |
| civic_records: the jurisdictions list now includes the 10 hamlets | Needs a decision | Should a hamlet with no officials be a jurisdiction? Settle worker or owner. |
| net_fauna_test: the guest's animal copy is about 3 tiles off and wanders (65f2665) | A, multiplayer x presence | Presence moves animals tick by tick. Presence worker. |
| recorder_test: "X20: the victim's grievance is an event"; Decompression failed (65f2665) | Untriaged | Recorder worker. |
| run_tests: "a save keeps the new household, its house and its members" (65f2665) | Probably F of the homestead x presence item | Not run locally (full run_tests is the lead's). |
| Stray stone cell at the fair bridge's south-east foot | A, minor | Seed 1 map dump: the trail east leaves from (-168,128), the cell right of the bridge's south end, along the bank (rows 128-129), not from the land road at (-170,129). The trail's start node should snap to the road's first land cell past the bridge. Water/region worker. |

## GitHub validation

| Run | What | Result | Wall clock |
|---|---|---|---|
| 41753190755 | Tests on wip/b25r1-ci 552826b | failure, the base's known suites | 01:18-02:05 (shards 10-22 min) |
| 41761854514 | Tests on 65f2665 | failure: the 24 suites above, most fixed since | 02:36-03:54 |
| 41770720688 | Tests on f60772f | see the addendum | started 04:02 |
| 41770724025 | gate (long-sims, seeds 1, 10 days) on f60772f | see the addendum | started 04:02 |

## Answers

- **Is the whole Revision 1 world merged?** Yes. Water, region, settle, homestead, presence and CI are all on wip/b25r1.
- **Does the game launch?** Yes, headless. I ran `godot --headless --path game --quit-after 600` on the main scene: exit 0, no script or parse errors. start_test (a new game in the real scene, 523 steps) passes.
- **Can the player travel between all five towns?** By the planner, yes: region_travel_test 71/0, which plans to every site. Two road routes cross hamlet houses (above), so the drawn road is broken there.
- **Can the player interact and trade with residents?** outside_interact 23/0, settlement_folk 36/0, hamlet 74/0 (residents materialise and fold) and presence 37/0 all pass.
- **Do homesteading and presence work together?** No. homestead_test fails after the presence merge.
- **Does saving and reloading keep state?** On the focused suites, yes: underground, multiplayer_c test_save22, message_journal, le06, housing and identity. run_tests' new-household save check fails on 65f2665 (likely the homestead x presence item).
- **Known conservation or identity defects?**
  - None proven. Prospecting is the census formula (shown above).
  - Stone and ore pass.
  - Identity passes.
  - courier_live's +13 is the designed resident ledger crossing, not yet proven.
- **Can Windows, Linux and Android packages be produced?** Feasible: release.yml exports all three from one commit, and nothing in the merge touches export presets or signing. Nothing was packaged.
- **Which failures block a playtest?**
  - homesteading x presence: homesteads don't get built.
  - The broken road routes through hamlets.
  - The rest are test premises, or minor.

## Recommended next action

1. Presence and homestead workers: the far homesteader's build under the fixed tick and live range.
2. Region and settle workers:
   - routes and side roads through hamlets;
   - Milton's homes;
   - the stone share of main roads;
   - the bridge-foot trail.
3. Settle worker or owner: the jurisdictions decision.
4. Once Tests is green on the new head and the gate's differences are explained, re-record the gate baseline and run the 365-day campaign once.

The gate baseline was not re-recorded overnight and the campaign was not dispatched; the addendum says why.
