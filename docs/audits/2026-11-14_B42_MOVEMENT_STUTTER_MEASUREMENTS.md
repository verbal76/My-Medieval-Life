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

### Run base_south2 (same route and commit, load 6.8 rising to 7.1)

19,552 frames. `_player_step` broken down (mean ms a frame, 30 s bins): everything but `_find_target` is under 0.25 ms;
`_find_target` is 4.9 (first bin, start-up), 2.8, 4.5, 4.2, 5.2, 5.5, 6.3, 6.0, 6.0, 6.7, 7.6 ms. It runs every frame
(the "what can I use here" prompt) and grows with the walk. Per-bin p50/p90 and spikes repeat run 1's pattern
(p50 8.5-17.9 ms, frames over 50 ms 8-42 a bin, over 100 ms 1-8 a bin). Memory flat 492-500 MB.

### Run ft_south (`e438f1e`, load 7.6-7.9): what the long frames are

`tools/freeze_probe_spikes.py` (each frame over 50 ms put down to its costliest leaf part): **215 frames over 50 ms; 152
are `ow:prefetch`** (worst 143.7 ms), 26 presence (worst 85.8), 10 autosave (worst 306.1), 9 villagers' plans (worst
112.6), 3 villagers deciding, 2 chunk builds, 1 field cells, the rest (12) unnamed or small. `_find_target`'s growth is
`BusinessDesks.faced_all` (`ft:desks`): 1.1, 2.2, 2.7, 3.8, 3.9, 4.9 ms a frame in 60 s bins; everything else in
`_find_target` is flat (under 1 ms).

**Cause 1 confirmed (the owner's "advance, freeze, advance, freeze" on the trail):** `OverworldView._prefetch` generates
one chunk of the next ring out on every frame with no chunk to build, on the main thread. The view keeps 5 x 5 chunks of
32 tiles; the ring outside has 24, so after every chunk border (about every 7 s at walking pace) the new chunks ahead are
generated on consecutive frames, each 26-140 ms here. In the village there is no prefetch (village chunks are skipped),
which is why the stutter starts only once the player is out on the trails.

## Fix 1: chunks prepared ahead on a background thread

`OverworldView` now hands the chunk to a worker thread with a private `Overworld` laid out from the same seed, generation,
gates and the map's stamps (as `AerialMap`'s settlements worker already does, KI-09), and `Overworld.adopt_chunk` takes
the finished chunk into the world's cache on the main thread (plus the rim steps its generation recorded). The worker
reads nothing of the live world. A chunk needed first by the main thread is made there as before; the worker's copy is
then dropped. No simulation code path changes (the simulation's own get_chunk is untouched; headless sims have no view).

`game/tests/chunk_prefetch_test.gd` (6 checks):
- the worker's Overworld, on a thread, generates the 119 chunks along and round the route south identically to the
  world's own `get_chunk`, every field, and the same rim steps (7 cells);
- in the scene, carried south from the gate 422 tiles in 1,500 frames: main-thread prefetch time per frame worst 9.89 ms,
  0 frames over 15 ms, 47 chunks adopted; every one of the 160 cached chunks equals a fresh generation.
- With `-- sync` (the old main-thread prefetch, same walk; load 7.0-7.1): worst 70.0 ms, **64 frames over 15 ms**, so
  the frame check fails (3 failures) before the fix and passes after.

## Fix 2: the desk prompt checks only the desks beside the player

`BusinessDesks.faced_all` (every frame, from `Main._find_target`) built the whole desk list with names and called
`World.reaches` twice for every desk before its distance test; `reaches` costs more the farther the player is from the
village. `BusinessDesks.all(w, near, reach)` now skips desks beyond `reach` before naming them, and `faced_all` asks only
for those within `World.STATION_BESIDE` (its own last test, so the answer cannot change).
`game/tests/desks_faced_test.gd` (5 checks): 34,375 points round the 11 desks (two game hours in), five facings each:
0 answers differ from the old function (531 desks found); the filtered list equals the whole list filtered, in order;
a call costs 0.057 ms against 0.343 in the village and **0.069 ms against 3.521 ms at (195.5, 650.5) on the trail south**
(load 5.7-6.4). This is a steady per-frame cost, not a spike, but it raised every frame on the trail (and so pushed the
0.5 s tick frames further over budget).

## Fix 3: the hourly autosave's text and file on a background thread

`tests/autosave_cost_probe.gd` (new game, 5 repeats, load 6.2-6.8): save 453 KB; `to_dict` 9.0-15.5 ms, `JSON.stringify`
18.7-43.3, `SaveStore.write_text` (write, read back, the old save parsed, backup) 7.1-24.8; whole `save_game` 45.9-93.7 ms,
every game hour (30 real seconds). On the southern walk the autosave frames reached 306 ms.

`Main.save_game(show, background)`: the hourly autosave (only) takes the save on the frame (`to_dict`, then a deep copy so
the thread reads nothing live) and makes the text and the file (the same `SaveStore.write_text`) on a thread. Its outcome
(failure message, recorder note, linked copy) follows when done; every other save, load and save-slot check waits for it
first (one writer; saves land in order). `game/tests/autosave_async_test.gd` (11 checks, 0 failures): the background file
equals the frame's save byte for byte except the wall-clock `saved_at` (370,530 bytes) and the backup chain is as before;
main thread 18.7 ms against 54.7 ms for the whole save; a save asked during one waits and lands after it; a failing
background save sets `save_failing` and leaves the last save; in play the hour's autosave runs in the background and
leaves a good save.

## Before and after: the owner's route south (pair 1)

Same probe, same route (village, south gate, Wendholt, Milton, Elmcote; 19,522 frames, 326 game seconds), seed 1, fixed
60 fps headless. Before = `e438f1e` (Build 41 + probes only); after = `19da97d` (fixes 1-3). Run back to back.

| | before (`e438f1e`) | after (`19da97d`) |
|---|---|---|
| load average during | 6.9 -> 5.9 | 8.9 -> 6.9 (busier) |
| p50 / p90 / p99 ms | 11.5 / 23.6 / 51.7 | 9.1 / 22.0 / 44.1 |
| frames over 33 ms | 682 | 511 |
| frames over 50 ms | 222 | 114 |
| frames over 100 ms | 16 | 11 |
| frames over 200 ms | 7 | 1 |
| max | 298.7 | 349.1 (a 06:00/17:00 hourly frame, cause 5) |
| over 50 ms from chunk prefetch | 113 (worst 166.6) | **0** |
| over 50 ms from the autosave | 9 (worst 298.7) | 5 + 3 following (worst 172.7) |
| over 50 ms from desks (`ft:desks`) | 3 | 0 |
| static memory | 495-500 MB | 512-523 MB (+~23 MB: the worker's private Overworld; flat over the walk) |

What is left over 50 ms after the fixes (114): presence 29 (+9 following; settlement residents materialised as the player
reaches a site, `Presence._run_providers`), chunk drawing `ow:build` 11 (+3), villagers' plans and decisions on tick
frames 17 (+10), field-cell prompt 5, autosave 5 (+3: `to_dict` and the deep copy on the frame), hourly/daily 2 (349 ms:
the dawn or 17:00 frame), and single frames of other parts under load. The 0.5 s tick frame is still about twice an
ordinary frame (tick frames p50 22.2 ms against 9.0; before 25.3 against 11.2).

## Before and after: another direction, east (pair 1)

Village, east gate (120, 57), along the road to Ashcombe (330, 40), 219 route cells, then about the hamlet: 5,644 frames,
94.6 game seconds. Back to back, load 5.8-6.3 for both.

| | before (`e438f1e`) | after (`c0f267a`, same code as `19da97d`) |
|---|---|---|
| p50 / p90 / p99 ms | 7.8 / 15.3 / 33.4 | 5.8 / 14.4 / 29.0 |
| frames over 33 / 50 / 100 / 200 ms | 59 / 28 / 3 / 1 | 39 / 10 / 1 / 0 |
| max | 225.2 (autosave) | 143.3 (autosave, the frame's to_dict under load) |
| over 50 ms from chunk prefetch | 22 (worst 84.2) | 0 |
| over 50 ms from the autosave | 3 (worst 225.2) | 1 + 2 following (worst 143.3) |

The cause is not southbound-specific: east shows the same chunk-crossing stalls before and none after. South shows more
of them because the walk is longer and crosses more chunks (1,390 route cells against 219).
