# B25R1 playtest readiness (repair coordinator, 2026-11-04)

Branch `wip/b25r1`. Code SHA under test: **2677ea7** (this report is committed on top of it). It continues
`docs/handoffs/OVERNIGHT_2026-11-04.md` (head 3c53431). Nothing was packaged, and the register was not edited.

## Fixes

| SHA | Task | Root cause | Change | Verification (local, checks/failures) |
|---|---|---|---|---|
| 2677ea7 | 1 recorder neutrality (gate 41770724025, det_s1) | An hour-cache entry (World.reserve_of, _market_price, cheapest_food_unit) holds the first reader's value for that game hour. Observers that read first change what the game reads later in the hour: NPCBrain._record_refused_buy (recorder-only) read reserve_of; a recording run takes JudgmentLive's full candidate scan where the game takes the shortcut; Homesteads._sustain's recorder row; economy_sim's own samples. Reproduced locally (unrecorded `--every 5` gives CI's c2a0835f at day 20). The first fingerprinted difference is day 15, 12:00-13:00 (a sage buys an ale from the tavern cook in one run only). The caches already differed from hour 0, found by tracing the cache misses with the recorder on and off. | `World.observing`: observers read the hour caches but never write or clear them. The paths above are wrapped, and the game's choices are unchanged. | New recorder_neutrality_test 5/0: recorded and plain worlds and both caches are equal every hour for 2 days. The control on the previous code fails from hour 0. recorder_test 214/0, judgment_live_test 180/0. |
| f86ba3c | 2 homesteads x presence | Live and calculated homesteaders already ran the same rules on the one tick. Without the mid-test save the house stood by day 6. The cause was Homesteads._errand buying each item from one seller a trip, the nearest: a labourer carrying 2 blocks ended the buying while a merchant held 20. | The errand asks the next-nearest seller while the house still needs the item, the purse allows it and trip_errands lasts. | homestead_test 47/0 (before the final road change; see the remaining failures). New homestead_presence_test 17/0: near and far build at the same hour, nobody is duplicated or lost, goods and coins balance, and a mid-build save loads back exactly. |
| 0c1aeb3 | 3 hamlet roads | (a) Site grounds overlapped: Milton on Higham, Brookhurst on Mileham and Garton, Bourton on Higham on some seeds. Milton's homes there were never built, and routes crossed houses. (b) Side roads ran straight to the nearest route node. (c) Ring legs were checked with a box grown by 2, but roads wobble up to 9 tiles. (d) A trail left from the fair bridge's own point. (e) The busy-paving count used all 120 pairs of places, so every main road was busy. | Anchors moved: Milton (195,700), Brookhurst (-208,797), Bourton (90,946). Side roads are laid after all main joins and avoid every ground, from any side. Ring legs are laid in stretches of at most 40 tiles, checked cell by cell. No trail starts at a layout crossing. RegionRoads.busy_cells counts village-and-town pairs only. | overworld 333/0 (new check: no two grounds overlap), road_types 14/0 (seed 1: 2431 of 15703 main road cells stone), region_travel 71/0, road_wear 40/0, hamlet 74/0, settlement_folk 36/0, water 62 (goldens re-pinned). Seeds 1-8, 11 and 12 have a route from the south gate to every site, with no solid cell. |
| b905aa9 | 4 hamlet civic policy (B25R1-Q9) | Hamlets were listed as jurisdictions. | Only the village and the five towns are jurisdictions. Each town names its hamlets, and `jurisdiction_of()` gives a hamlet its lord's town ("" for Rushford and Ashcombe). No new government. DECISIONS.md entry. | civic_records_test 52/0 |
| aba1e7d | 5 courier_live +13 | The +13 is not the residents' crossing. A regional-trade courier delivery collected 8 coins from a Wulstead party in the same days (traced: Couriers.deliver). The census and the audit balance. | The till check takes the outside line's rise less other deliveries' collections and the residents' crossings (new unsaved counter, SettlementPeople.crossings). | courier_live_test 148/0 |
| 1505762 | 5 campfire (CI timing) | On a loaded runner, one frame takes longer than the art's 150 ms. | The test watches for at least 0.9 s, until 4 frames are seen (capped at 10 s). The check is still 4 frames. | campfire_test 16/0 |
| 6748852 | 5 recorder_test | The credit step could make the theft victim the thief himself. | Another adult is the victim in that case. | recorder_test 214/0 |

## Test runs (GitHub)

| Run | What | Result | Wall clock |
|---|---|---|---|
| 41872740140 | Tests, 8 shards, on 2677ea7 | failure: 4 suites (below), down from 12 on f60772f | 16:57-17:57 (60 min) |
| 41865858149 | Tests on 6748852 | cancelled by the workflow's concurrency group (superseded) | - |
| 41872734897 | gate (long-sims, gate, seed 1, 10 days) on 2677ea7 | still running at 18:56 (started 16:57); the previous gate took 73 min | - |

Because the gate result is not in, the baseline was not re-recorded and the 365-day campaign was not dispatched
(SIM-GATE-01: only after a gate whose blocking findings are explained baseline differences, with det_s1 identical).

## Remaining failures

| Suite: failure | Category | Notes |
|---|---|---|
| homestead_test: "the household breaks ground on its claim and sows its own seed (8 cells, 0 sown)" | A | New after 0c1aeb3. It passed 47/0 before the final road change (the claim site and the walks moved), and it reproduces locally. Not traced. Next: probe the farmer homesteader's field steps after can_sow_now. |
| wilds_test: "F: the raider walked the road to the village" | A | The band's camp now lies so near the village (about (11,140)) that the raider reaches the village in daylight within the first hour and turns home at once, so the check never sees him there. A trial fix (lie low by any edge of the village) did not change it and was reverted. Next: why _lay_raid's daytime cut does not hold the first walk. |
| run_tests: "a save keeps the new household, its house and its members" | B | Open since 65f2665 (overnight report), not traced. |
| net_fauna_test: "the guest's copy holds the host's animals (67)", "animals beyond the snapshots' reach ... (20 off)" (locally also the follow, wander and health checks) | A, multiplayer x presence | The guest does not simulate fauna (no World.update on a guest), so the guest's copy follows the host's snapshots. The id set and far positions differ after presence's tick-by-tick fauna. CI log also shows `Invalid access to property 'present' on Nil`. Not fixed. |
| regional_food_test: SCRIPT ERROR "key 'stock' on Dictionary" (line 211); the suite did not fail | A, test or data | Seen in shard 7's log. Not traced. |

## Playtest checks (from the suites; no device check)

- Clean start and character creation: start_test passed overnight (523 steps), and nothing since touches the new-game path.
- All five towns and their hamlets are reachable: region_travel 71/0 and overworld 333/0. Every site has a road route on seeds 1-8, 11 and 12.
- Residents travel, trade and interact: hamlet 74/0, settlement_folk 36/0, courier_live 148/0.
- Presence transitions keep state: homestead_presence_test (live and calculated, the same build). net_fauna is still open for guests.
- Homesteads build: homestead_presence_test passes; homestead_test's field sowing is open.
- Save/load keeps progress: mid-build round trip is exact. run_tests' new-household save check is still open (category B).
- Conservation and identity: no leak found. The courier +13 is explained, and recording no longer changes the world.

## Platform readiness (feasibility only, nothing packaged)

- **Windows, Linux, Android:** release.yml exports all three from one commit. Nothing here touches export presets, signing or the package id. All three are feasible.
- **Playtest:** two category A items should be fixed first: homestead field sowing and the raid walk. The run_tests save check (B) and net_fauna (multiplayer) should be fixed before a multiplayer playtest.
