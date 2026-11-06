# Build 25 Revision 2 (Play Test Build One): completion checklist

Owner directives: `docs/directives/2026-11-06_my_folklore_pc_playtest_repair.md` (the five repairs, with the answers
B25R2-Q1..Q4) and the full completion directive of 2026-11-06. Base F2 `20e579e`; repair branch `wip/b25r2-playtest`.
Counts, not percentages. Times Eastern. "Open" means not yet verified, never assumed.

Last updated 2026-11-06 12:50 EST, branch head `cb5e323`.

## The five repairs

| # | Repair | State | Evidence |
|---|---|---|---|
| 1 (item 2) | Riverbank autotravel | Fixed, verified in CI | `travel_river_test` 18/0 on `c0be482` (run 42241115251), 21/0 locally on `f3c5bdd` (driver case now really exercised: gives up after 12.0 s, bound 17.0 s). Before, on F2 (repro run 42238322262): 14, 90 and 28 wet hops on seeds 1, 2, 7; after: 0 on each. Causes: `RegionTravel._attach` legs never checked for water; the walk goes straight at targets; `TravelDriver` took sliding for progress. |
| 2 (item 3) | Long-distance stutter | Fixed for the journey's chunk work; two world spikes remain | `travel_perf_test`, CI: F2 200 frames over 33 ms, mean 2.78 ms; `82cb449` 4 over, 1.21 ms; `c0be482` 41 over, 2.06 ms (generation 8's cost); `6ca3b1f` 6 over, 1.36 ms (run 42244565455). Remaining over 100 ms: the first frame of the run (07:00-07:01, villagers deciding, about 230-400 ms) and the daily 17:00 hour (about 230-380 ms, world). CI figure for `f3c5bdd`: open (suite running). |
| 3 (item 4) | Resume/Dismiss by controller | Fixed, verified | `pad_reach_test` travel-bar checks 9/9 (59/0 whole test, `c0be482` CI and `f3c5bdd` local). |
| 4 (item 5) | Full Windows controller support | Fixed, verified headless; device check open | `pad_reach_test` 22 windows, every control reached and framed; `gamepad_map_test` 19/0 locally on `f3c5bdd` (was 5 failures on `c0be482`: a window button took focus on the first pad press, so A no longer travelled). A real Windows controller check is the owner's (playtest). |
| 5 (item 6) | Looping bridge geometry | 31 loops -> 4 (8 seeds); 6 of 8 seeds clean | `bridge_validity_test`, seeds 1, 2, 3, 4, 5, 7, 11, 42: `6ca3b1f` 4, 4, 4, 5, 4, 2, 2, 6 loops; `cb5e323` 3, 0, 0, 0, 0, 0, 1, 0. Each loop traced to its generator stage (commit `0112fd1`). The 4 left: seed 1 at -63,879 and -269,143/-265,144, seed 11 at 310,935. Two are traced to B25R1-017's rule that water keeps off a road running along a course: a second road beside the water cuts its edge dry, and that strip joins the banks next to a genuine bridge. One (seed 11) is a road along a lake's shore on the bank noise. Not fixed yet. |

## Owner-required resolutions

| Item | State | Evidence |
|---|---|---|
| 365-day sim script errors (127) | Fixed; campaign rerun open | `af8a190`: a manor hand with no house was looked for at a door that does not exist (`NPCBrain._workplace_cell`). Seed 2 did not stop at day 300: segment 3 ended at its boundary, segment 4 reached 365 (campaign 42154260748). |
| Save/reload integrity | Fixed; campaign rerun open | `18e4c41`. Read from the campaign's own state files. Trees: cleared ground gained a birth time on load (seed 2 day 100, 3 orchard trees). Couriers: a shop booth opened at one stall and was linked to another; a load moved it (seed 1 days 200, 300). Carts: villagers let go of pulled carts on load by design (KI-FR-CARTHITCH, decision 2026-11-02), now listed as "explained" only when that is all that differs. `save_exact_test` 13/0; 4 failures on the old code. After the fix, seed 1 day 100 and seed 2 day 100 load back exactly; day 200/300 files were written by the old code. |
| Lake-edge bridges | See repair 5 | |
| Controller tests | Passing locally | See repairs 3, 4 |
| Performance preserved | Open for `f3c5bdd` (CI) | See repair 2. Generation 8 also made the overworld's creation 3.6x slower (11.5 s against 2.8 s); `0112fd1` brought it back to 3.4-3.8 s (chunks 33-39 ms against generation 7's 27-29), identical roads. |
| Generation compatibility | Verified | Generation 7 (Build 34's worlds) still matches its recorded chunk hashes on seeds 1, 2, 7 (`water_test` GOLDEN_7, 67/0); generation 8 pinned, two processes agree. |

## Full suite

- `c0be482` (run 42242729094): failures in water_test 5, gamepad_map 5, crafts 1, region_travel 2, overworld 1 (432 ms a
  chunk), net_g1 8, net_mp4 1; 3 shards cancelled at the time limit (stone_test 1506 s). Fixed since: water, crafts,
  gamepad_map, region_travel (`f3c5bdd`), chunk and creation speed (`0112fd1`).
- `f3c5bdd`: dispatched 2026-11-06 about 12:15 EST; open. net_g1 and net_mp4 to be read there (on `c0be482` they ran
  under the slow generation).

## Still to do before the package

1. Read the `f3c5bdd` suite; fix anything left.
2. Bridges: the 4 remaining loops (above).
3. Rerun the 365-day campaign on the final commit: script errors, conservation, twin agreement, save round trip.
4. Sim gate baseline differences: investigate, not re-record (B25R2-Q1).
5. Windows package from the final commit through the release workflow, smoke-tested; release notes ("Play Test
   Build One", My Folklore in the notes only). Not published without the owner's approval.
