# Build 25 Revision 2 (Play Test Build One): completion checklist

Owner directives: `docs/directives/2026-11-06_my_folklore_pc_playtest_repair.md` (the five repairs, with the answers
B25R2-Q1..Q4) and the full completion directive of 2026-11-06. Base F2 `20e579e`; repair branch `wip/b25r2-playtest`.
Counts, not percentages. Times Eastern. "Open" means not yet verified, never assumed.

Last updated 2026-11-06 15:45 EST. Test regimen audit alongside: `docs/audits/2026-11-06_TEST_REGIMEN_AUDIT.md`. Candidate `832f711` (code); `7c1bac4` adds the decision log only.

## The five repairs

| # | Repair | State | Evidence |
|---|---|---|---|
| 1 (item 2) | Riverbank autotravel | Fixed, verified in CI | `travel_river_test` 18/0 on `c0be482` (run 42241115251), 21/0 locally on `f3c5bdd` (driver case now really exercised: gives up after 12.0 s, bound 17.0 s). Before, on F2 (repro run 42238322262): 14, 90 and 28 wet hops on seeds 1, 2, 7; after: 0 on each. Causes: `RegionTravel._attach` legs never checked for water; the walk goes straight at targets; `TravelDriver` took sliding for progress. |
| 2 (item 3) | Long-distance stutter | Fixed for the journey's chunk work; two world spikes remain | `travel_perf_test`, CI: F2 200 frames over 33 ms, mean 2.78 ms; `82cb449` 4 over, 1.21 ms; `c0be482` 41 over, 2.06 ms (generation 8's cost); `6ca3b1f` 6 over, 1.36 ms (run 42244565455). Remaining over 100 ms: the first frame of the run (07:00-07:01, villagers deciding, about 230-400 ms) and the daily 17:00 hour (about 230-380 ms, world). CI on `f3c5bdd` (run 42263249923): 6 over 33 ms, mean 1.31 ms, worst 234 ms (the first frame). |
| 3 (item 4) | Resume/Dismiss by controller | Fixed, verified | `pad_reach_test` travel-bar checks 9/9 (59/0 whole test, `c0be482` CI and `f3c5bdd` local). |
| 4 (item 5) | Full Windows controller support | Fixed, verified headless; device check open | `pad_reach_test` 22 windows, every control reached and framed; `gamepad_map_test` 19/0 locally on `f3c5bdd` (was 5 failures on `c0be482`: a window button took focus on the first pad press, so A no longer travelled). A real Windows controller check is the owner's (playtest). |
| 5 (item 6) | Looping bridge geometry | Fixed: 0 loops on all 8 seeds (local; CI on `832f711` open) | `bridge_validity_test`, seeds 1, 2, 3, 4, 5, 7, 11, 42: `6ca3b1f` 4, 4, 4, 5, 4, 2, 2, 6 loops; `6893763` 0 on every seed. Each loop traced to its generator stage (`0112fd1`, `cb5e323`, `6893763`; DECISIONS 2026-11-06). Connectivity kept: `region_geography_test` 992/0, `overworld_test` 440/0, `road_types` 14/0, `hamlet` 74/0. |

## Owner-required resolutions

| Item | State | Evidence |
|---|---|---|
| 365-day sim script errors (127) | Fixed; campaign rerun open | `af8a190`: a manor hand with no house was looked for at a door that does not exist (`NPCBrain._workplace_cell`). Seed 2 did not stop at day 300: segment 3 ended at its boundary, segment 4 reached 365 (campaign 42154260748). |
| Save/reload integrity | Fixed; campaign rerun open | `18e4c41`. Read from the campaign's own state files. Trees: cleared ground gained a birth time on load (seed 2 day 100, 3 orchard trees). Couriers: a shop booth opened at one stall and was linked to another; a load moved it (seed 1 days 200, 300). Carts: villagers let go of pulled carts on load by design (KI-FR-CARTHITCH, decision 2026-11-02), now listed as "explained" only when that is all that differs. `save_exact_test` 13/0; 4 failures on the old code. After the fix, seed 1 day 100 and seed 2 day 100 load back exactly; day 200/300 files were written by the old code. |
| Lake-edge bridges | See repair 5 | |
| Controller tests | Passing locally | See repairs 3, 4 |
| Performance preserved | Verified on `f3c5bdd` (CI): 6 over 33 ms, mean 1.31 ms | See repair 2. Generation 8 also made the overworld's creation 3.6x slower (11.5 s against 2.8 s); `0112fd1` brought it back to 3.4-3.8 s (chunks 33-39 ms against generation 7's 27-29), identical roads. |
| Generation compatibility | Verified | Generation 7 (Build 34's worlds) still matches its recorded chunk hashes on seeds 1, 2, 7 (`water_test` GOLDEN_7, 67/0); generation 8 pinned, two processes agree. |

## Full suite

- `c0be482` (run 42242729094): failures in water 5, gamepad_map 5, crafts 1, region_travel 2, overworld 1 (432 ms a
  chunk), net_g1 8, net_mp4 1; 3 shards at the time limit. All fixed or explained since.
- `f3c5bdd` (run 42263249923): 2 failing tests, bridge_validity (fixed in `6893763`) and save_transfer (its own copy of
  the old tree rule, `0550c1d`); the network tests pass (they had run under the slow generation). Every ERROR line swept:
  missing skill glyphs (8 skills), chapel_test's Build 17 save case stopping early while reporting PASSED (now 175/0,
  9 checks that never ran now run), three test messages (`832f711`). The rest are the suites' own negative cases.
- `832f711`: full suite 42274258964 **green**. Sim gate 42274351589: determinism identical at every checkpoint (shipped and Expansion 20 switches); the only blocking findings are baseline differences, investigated in `SIM_BASELINE_DIFFERENCES_B25R2.md` (they begin at `bf20dc9`, the owner-approved band household; not re-recorded). 365-day campaign 42274347279: running.
- Windows package: release.yml run 42284391094 on `7c1bac4` (code of `832f711` plus the decision log), private, build 34: all six packages and both Windows smoke runs **succeeded**; the gate failed (baseline differences only) so the release step was **skipped**: nothing published or drafted. `pkg-full-windows` (artifact 13536562662, 235,931,879 bytes, sha256 `0d20c3084305f6b2392b761b27ce072e322415dc5e494151f8f60c0a15b0188f`) holds `MyMedievalLife-B34-Windows.zip`, version 0.1.34 (file and product 0.1.34.0). The smoke run starts it headless for 300 frames: exit 0, no script errors, no leak at exit. It does not draw, play or use a controller (owner playtest).

## Known, not in this repair's scope

- Eight skills have no glyph in the Skills window (the space is left empty): art to choose.
- The first frame of a session and the 17:00 hour each take about 230 ms of world work on CI.

## Still to do before the package

1. Read the `832f711` suite, campaign and gate; fix anything failing.
2. Owner decision: whether to accept a new simulation baseline (see `SIM_BASELINE_DIFFERENCES_B25R2.md`).
3. Windows package from the validated commit through the release workflow, smoke-tested; release notes ("Play Test
   Build One", My Folklore in the notes only). Not published without the owner's approval.
