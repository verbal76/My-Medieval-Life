# Build 25 Revision 1: progress and integration audit, 2026-11-03 19:53 EST (2026-11-04 00:55 UTC)

Read-only audit at the owner's request. Evidence: `git ls-remote` heads, the integration worktree, GitHub Actions runs since
2026-11-03 22:40 UTC (artifacts read), worker reports cross-checked against code on the branches. Percentages are labelled
estimates. Nothing was stopped, rerun or changed for this audit.

## State of the branches (verified)

| Branch | Head | Contents | In `wip/b25r1`? |
|---|---|---|---|
| `wip/b25r1` (integration) | `fee6521` | Build 25 + B25R1-002 interaction, 003-006 map/travel, 007-008 UI, 004/011/Q1 roads and wear, 012 gamepad map, 009 seed travelers, 016 recorder (`220d7de`), gate-only workflow mode, three base test fixes | yes (is the base) |
| `wip/b25r1-water` | `49e78a9` | water generator gen 4, rivers anchored on the layout, bridges/fords, flow, falls, sound | merged locally by the integration worker (`953e750`), not pushed |
| `wip/b25r1-region` | `9ce9a2e` | region layout, RegionGeo, gen 4 sites, Downs/waste/Wood Perilous, landmarks, organic towns (`site_plan.gd`), Higham walls/castle/churches, Larchrow props | no |
| `wip/b25r1-settle` | `084d4f0` | 10 hamlets, trips replacing road_trade and food shipments, SettlementPeople provider, M_BODY fold | no |
| `wip/b25r1-homestead` | `33b1f4b` | life decisions, homesteads, band in the wild (Q2), wells (Q3), pens/workshops, pack import, polish, FATAL fix | no (fixes for CI failures in progress) |
| `wip/b25r1-presence` | `3980a83` | presence by view, fixed 0.5 s tick, crowd management (B25R1-020), tree sway | no (fixes for start/refuge/housing in progress) |

Code verified present: `presence.gd` 357 lines, `trips.gd` 544, `people.gd` 330, `wilds.gd` 1674, `life_decisions.gd` 700,
`site_plan.gd` 683, `region_layout.json` 1384, `water.json`, `tools/flight_lives.py` 1042.

## GitHub evidence (runs since 22:40 UTC)

Passing: gate on base `eb04908` (41733570702: PASS, baseline identical, determinism identical); presence 60-day
`--no-crowd` (41740563376: 0 leaks, alive 104 to 130, food 3 to 8 days; the switch is not echoed in the output).

Failing:
- base Tests `eb04908` (41733575763): discovery coins, start_test fumble, save_transfer trees. Fixed at `fee6521` (one real
  bug: `NPC.remember` dropped the newest memory). Not yet re-run on CI.
- region Tests `d4b5119` and `3d03adf` (41735516442, 41740708833): 17-23 suites; mostly pre-gen-4 save fixtures now refused
  (identity, le06, le07, multiplayer a1/b/c, message_journal, crafts, farm_shared_save, underground) plus map-dependent
  checks (courier distance, envoy radius, contract ore, stone census, prospecting coins, campfire, outside_interact).
- presence Tests `47cea96` (41737006430): start_test animal sizes and Joan's bed, refuge_test dispersal, housing_test.
- homestead Tests `3134094` (41740375492): run_tests beds and household save, chapel, multiplayer a1/c wilds not idempotent
  on reload, campfire, identity household count, and the 10-day smoke FATAL (fixed at `33b1f4b`).
- homestead 240-day `3134094` (41740383468): FATAL day 40 (planks, tin, birds); fixed at `33b1f4b`.
- gates on region `d4b5119` and presence `47cea96`: FAIL on baseline differences only; no leaks, no script errors, no
  FATAL, determinism identical. Expected; the baseline is re-recorded once on the integrated candidate.

Running (no outcome yet): presence 240-day, presence view-sweep (pending), region-ci2 gate, homestead-ci gate and ci2
tests/gate, settle-ci tests/gate/365-day, settle-ci3 tests/gate, water-ci and water-ci2 tests/gate.

Not run on any commit: the integrated candidate (does not exist yet), the 365-day flight campaign, the targeted scenarios on
Actions, a release build of anything after Build 25.

## Workstreams (estimates labelled)

| # | Workstream | Built (est.) | Integrated | Validated at the right commit | Main gaps |
|---|---|---|---|---|---|
| 1 | Region, towns, hamlets, geography, walls | 85% | no | focused tests only | knoll and Bear Hill height; town art not store-quality (Netherton church, paving, parallel lanes); hamlet lanes stone; art gaps (cross, white battlements, fountain water) |
| 2 | Roads, tap-to-travel, route planner | 90% | partly (base roads merged; new routes not) | focused only on branch | stray stone cell at the fair bridge; Higham-Garton link dropped |
| 3 | Water | 90% | merging now | focused only | stub cell; shore steps |
| 4 | Settlement economies, trips, inventories | 85% | no | focused only (hamlet_test 74/0) | never run together with presence; 365-day not run |
| 5 | Homesteading, construction | 85% | no | focused; CI failures open | beds/household save, wilds reload idempotence, walkable well, camp last-unit |
| 6 | Outlaws, combat, pursuit | 80% | no | focused; 6-day probe only | band shrinks fast on raids (untuned, by design to measure); campfire test |
| 7 | Presence, off-screen simulation | 85% | no | focused + 60-day CI | three failing suites; settlement provider never exercised live |
| 8 | Crowd thinning (B25R1-020) | 75% | no | focused only | effectiveness and Android cost unmeasured |
| 9 | Long-run stability, determinism, saves | 50% | partly | base gate PASS only | integrated gate, re-baseline, 365-day campaign; old-save fixtures to replace (Q5) |
| 10 | Other B25R1 (interaction, map UI, char creation, roads wear, gamepad, travelers, recorder) | 95% | yes | base CI at `eb04908` had 3 failures, fixed at `fee6521` | region map restyle (lead, not started); grass decoration (approved, not started) |

## Integration health

- Five of the largest workstreams (region, settle, homestead, presence, and water until pushed) are NOT on the integration
  branch. Every per-branch green is evidence about that branch only.
- Known cross-branch interfaces to reconcile at merge: one `EXTRA_ATLASES` list (ids 5-10); two import steps in
  `import_game_assets.py`; `world.gd` (fixed tick, fold-before-save) and `journeys.gd` (trip hand-off); `Fauna.update`
  (led animal vs tick); the duplicated walking rule in `trips.gd` to be replaced by `Presence.road_tiles`; Wilds `count`
  parameter (settle codes against a stub).
- The combined NPC journey (a settlement resident walking a trip, becoming live near the player, trading, folding back,
  continuing the errand) is built in two halves on two branches and has never run as one: settle's provider is tested
  against a stub presence, presence against a stub provider.
- Regression risk: the gen-4 generator refuses older worlds by design (Q5); many tests built on old fixtures must be
  re-based on fresh saves, not deleted or weakened.

## Performance and readiness

- Measured on the shared cloud machine (software GL, loaded): about 121 ms process time a frame at normal zoom with 22 live
  villagers versus 196 ms with the whole village live. This is not an Android benchmark. No device numbers exist.
- Headless: decisions are 46.5% of CPU and run in both modes, so presence saves at most about 13% of simulation CPU; the gain
  is per-frame cost. Settlement residents as records cost about 34 microseconds a person a day against about 150 ms for a
  full NPC, which is what makes 480 extra people affordable.
- The five-town world is navigable by tap-to-travel on the region branch (planner fixed, region_travel 61/0), not yet in an
  integrated build.

## Critical path to a playable build (dependency order)

1. Integration worker merges region, settle, homestead (with its CI fixes), presence (with its fixes) onto `wip/b25r1`; fixes
   merge conflicts and the integration failures (old-save fixtures per Q5, map-dependent checks, stub cell). (in progress)
2. Full Tests on the integrated SHA (about 1 hour on Actions); fix what remains.
3. Gate on the integrated SHA; re-record the baseline once with an evidence note (SIM-GATE-01).
4. Private interim playtest build from that SHA (three platforms) — possible here, before the 365-day campaign, if the owner
   wants to play early.
5. 365-day flight campaign with `--twin` and the targeted scenarios (several hours on Actions); reports A-I.
6. Revision 1 private draft (six packages) from the validated SHA.

Hard blockers: steps 1-3 (no integrated code; old-save fixture failures; homestead and presence suite failures).
Important defects (fix before release, not before an internal playtest): band attrition on raids, walkable well, camp last
unit, crowd and presence on device, stray bridge cell. Polish: town art and layout, chalk/knoll height, grass decoration,
region map restyle, hamlet dirt lanes, rough shores.

Parallel now: homestead and presence fixes on their branches; integration of the already-final branches; grass decoration
and region map restyle can start on `wip/b25r1` only after the merge settles.

## Completion estimates (labelled estimates)

- Feature implementation: about 80% of the approved B25R1 scope exists in code (missing: elevation, grass decoration, map
  restyle, polish items, art the packs lack).
- Integration: about 35% (by volume of new work, most of it sits on unmerged branches; merging has begun with water).
- Validation and release readiness: about 10% (no integrated commit has run CI, the gate or the campaign).

Remaining work, from observed pace: integration and its fixes about 1 to 1.5 days of worker time; CI, gate and re-baseline a
few hours; the 365-day campaign with twin about 6 to 8 hours of Actions time plus review; packaging about 2 hours. A playable
internal build is about 1.5 to 2 days away if integration finds no deep conflict; the full Revision 1 draft about 2.5 to 3
days. Unknowns: how many integration failures are real bugs, presence and settle working live together, device performance.

## If Revision 1 were packaged right now

Only `wip/b25r1` (`fee6521`) could be packaged. Its gate would very likely pass (the base gate at `eb04908` passed; `fee6521`
adds three test fixes and one memory-rule bug fix, which may shift the baseline slightly). The build would contain the
interaction fixes, the new region map and tap-to-travel on the old corridor geography, character creation and UI, worn and
paved roads, gamepad map control, seed travelers and the recorder. It would NOT contain water, the new region and towns, the
hamlets, homesteading and outlaws in the wild, presence or crowd management. It would not be Revision 1.
