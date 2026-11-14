# Build 42 movement stutter: measurements log (B25-MOVE-STUTTER-INV, Agent P)

Running log, committed as it grows so a container restart cannot lose evidence. Branch `wip/b42-stutter` (base `0bbee94`,
Build 41 candidate: substepped movement `8c78e24`, village tiles made at start `ab68133`) plus the investigation worker's
probes cherry-picked from `wip/b25-move-stutter-inv` (`12cf1a4`). Directive:
`docs/directives/2026-11-14_b42_movement_stutter_correction.md` (on `wip/requirements-control`).

Probe: `game/tests/freeze_probe.gd` on the real `main.tscn`, new game seed 1, player walked by the movement actions,
`--headless --fixed-fps 60` (same world every run; wall time measured). B42 options: `dir=south|north|east|west`,
`hops=N` (the next settlement that way, N times, by the game's own road-preferring route finder RegionTravel.plan),
a `mem_mb` column (static memory) and a `ps:*` breakdown of `_player_step`. Bins: `tools/freeze_probe_bins.py`.

**Machine load matters:** 4 cores shared with several agents; the load average is recorded with every run. Absolute
times scale with load; compare runs only at similar load and repeat.

## Owner's route reproduced (equivalent; the owner's save is not available)

Seed 1. Start (44.5, 53.5) in the main village, out of the south gate (66, 90), along the roads to Wendholt (180, 262),
Milton (195, 700) and Elmcote (220, 790): 1,390 route cells, about 330 game seconds of walking.

### Run base_south1 (0bbee94 + probes, load 7.9-8.5, i.e. about 2 agents per core)

19,522 frames. p50 15.2 ms, p90 21.7, p99 58.0, max 368.5. Frames over 33 ms: 499; over 50: 237; over 100: 21;
over 200: 7. No frame ran more than one world tick.
By place: village 660 frames p50 8.6 ms (over 33 ms: 2); overworld 16,400 frames p50 15.2 (411); site 2,462 p50 15.7 (86).

| t (s) | y | p50 | p90 | >33 | >50 | >100 | mem MB | biggest parts (mean ms a frame) |
|---|---|---|---|---|---|---|---|---|
| 0 | 55-136 | 9.5 | 14.4 | 22 | 13 | 1 | 490 | sync_sprites 3.9, player_step 2.9, world.update 2.3, presence 1.8 |
| 30 | 136-200 | 13.9 | 18.1 | 40 | 28 | 2 | 496 | sync_sprites 5.0, player_step 4.3, world.update 3.1 |
| 60 | 200-317 | 14.8 | 19.8 | 43 | 23 | 2 | 497 | sync_sprites 4.9, player_step 4.8 |
| 90 | 317-345 | 15.1 | 19.4 | 37 | 16 | 2 | 498 | player_step 5.3, sync_sprites 4.5 |
| 120 | 345-429 | 15.2 | 21.7 | 57 | 34 | 4 | 495 | player_step 5.6, sync_sprites 4.9 |
| 150 | 429-517 | 8.1 | 18.5 | 31 | 14 | 1 | 494 | player_step 4.5 |
| 180 | 517-608 | 8.3 | 18.1 | 32 | 15 | 1 | 494 | player_step 4.9 |
| 210 | 608-525 | 16.0 | 22.9 | 44 | 10 | 1 | 494 | player_step 6.7 |
| 240 | 525-607 | 16.3 | 24.5 | 54 | 18 | 3 | 494 | player_step 7.7 |
| 270 | 607-704 | 16.7 | 26.9 | 82 | 45 | 3 | 496 | player_step 8.3, sync_sprites 5.7 |
| 300 | 704-787 | 17.4 | 24.8 | 57 | 21 | 1 | 496 | player_step 8.1 |

First finding: `_player_step` is the largest every-frame cost on the trail and it grows with the distance from the
village (2.9 ms a frame in the village bin to 8.1-8.3 ms 650-730 tiles south), while memory stays flat (490-498 MB:
no correlation with Agent M's KI-08 leak on this walk). At fixed 60 fps the substepping of `8c78e24` makes one step a
frame, so it is not the substeps. Being broken down next (`ps:*` columns).
