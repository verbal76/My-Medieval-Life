# Movement freeze investigation (B25-MOVE-STUTTER-INV), 2026-11-13

Owner's words: "Step, freeze, step, freeze, step, freeze. The whole game freezes momentarily and then catches up."
Directives: `docs/directives/2026-11-13_movement_stutter_deep_investigation.md` and `..._clarification.md` (on
`wip/requirements-control`). Branch `wip/b25-move-stutter-inv` from Build 40's `a5a0b7c`. Investigation only: nothing
here changes gameplay. One experiment, labelled **PROBE, not a fix**, lives only in a test script.

## Summary

The freezes are main-thread stalls in the game's own work. They are not rendering-only, and the player is not being
pulled back. Five sources were measured, each with its function:

| # | Source | When | Cost measured (headless, this container) | Status |
|---|---|---|---|---|
| 1 | **The fixed world tick** (`World.update`, `world.gd:397-403`, `TICK := 0.5` at `:391`, since `e66ca18`, 2026-11-03): every villager, every animal, the hour and the clock run in ONE frame out of every 30 | every 0.5 s, all the time, everywhere | that frame's median is 12.5 ms against 5.9 ms for the others; mean 19.0 against 6.6; `world.update` p50 7.2 ms, p90 18 ms, p99 36-40 ms, max 55 ms (1.1 ms on the other frames). 27% of tick frames run over 16.7 ms, so at 60 Hz one frame in 30 misses vsync. **Before `e66ca18` there was no 0.5 s peak**: costliest phase 4.8 ms median, the same as every other phase | **Confirmed** as the periodic, clock-like "step, freeze". The only periodic source at walking cadence |
| 2 | **A village tile made during play** (`MapView._put` → `_make_tile`, `map_view.gd:173-183`). The village's field tiles (tilled 3515, growing 1747, ripe 2627, each a 4×4 block of edge variants in atlas 0) are not in `_make_all_tiles`'s list, which holds only the overworld's data. A field cleared or tilled by villagers (`land_clearing.gd:333`, `world.gd:3773`) draws a variant not made before, and the shared TileSet changes. Every layer drawn with it updates again | a few times an hour of play while fields are worked (4 in 99 s of the morning on seed 1); state-dependent; again each session | 113-157 ms (180 ms worst) after `main._process`; 170-222 ms with a renderer (llvmpipe) | **Confirmed** by experiment: with the 30 missing field tiles made first (PROBE), all four frames are gone (frames over 100 ms: 6 → 0) |
| 3 | **Autosave every game hour** (`main.gd:2024`, `save_game(false)`: `world.to_dict()` + `JSON.stringify` of a ~530 KB save + an atomic write with a backup, all on the main thread) | every 30 real seconds | 50-85 ms, on the same frame as the hour's world work (11-17 ms) and a tick: 94-149 ms frames at hh:00 | **Confirmed**. It grows with the save (D4) |
| 4 | **Chunk data prepared ahead** (`OverworldView._prefetch` → `Overworld.get_chunk`, `overworld_view.gd:122-142`, from `82cb449`). On every frame with no chunk to build, one ring chunk is generated, synchronously | at each chunk crossing: 3-5 frames in a row | 26-35 ms a frame (about 100-140 ms over 4 frames) | **Confirmed** (`ow:prefetch` profile) |
| 5 | **Rare world spikes inside a tick**: one villager's long path search (`World._path_to` from a `go` step with `pathed`, `world.gd:858-860`; a traveller to (36, 775) cost 345-409 ms in one tick; bandits 35-44 ms), the first tick of a session (all villagers decide and travellers plan at once: 0.8-0.9 s; journeys 466 ms, homesteads 139 ms, decide 116 ms), 06:00 dawn (`_new_day`, 0.6-1.2 s; `brain.dawn` 430-640 ms), 17:00 `brain.reeve_day()` (30-130 ms), 12:00 caravan (47 ms) | first frame; rare; daily | as given | **Confirmed** (per-part and per-villager profiles) |

**Catch-up is confirmed.** The movement step is `speed * delta` (`main.gd:2722`), so the frame after a stall moves the
player the whole stalled time at once. With real deltas (`--max-fps 60`), after the 104-146 ms frames the next frame
moved the player 0.43-0.65 tiles, 6-9 times a normal frame's 0.075. The world's accumulator (`tick_left`) and the view's
interpolation (`_tick_alpha`) jump the same way. No frame in the walks ran more than one world tick, because none lasted
0.5 s. A stall of 0.5 s or more does run several ticks in the next frame, though: the `while` loop at `world.gd:400` has
no cap, and the 06:00 dawn and the first tick are that long. When not hosting, `main._process` does not clamp delta
(`HOST_STALL_SECONDS` applies only to a host).

**The earlier fix (`ed221df`) treated a real root cause, but only part of it.** "A tile made during play changes the
TileSet" is right. Only the tiles the overworld's data names were made at the start, so the same mechanism still fires
for the village's field tiles. `82cb449`'s chunk change spread the chunk work but did not remove it; it moved into
`_prefetch`. The 2 Hz world tick from `e66ca18` (2026-11-03) was never examined. It predates both of the owner's
reports (2026-11-06; "like a clock ticking every other step", 2026-11-07 01:56 UTC) and is the one source whose period
matches "step, freeze, step, freeze".

## Phase 1: history

- **`e66ca18` (2026-11-03, B25R1-019, Presence):** "one fixed tick for the world's rules". Before it, villagers near the
  player were updated every frame and far ones every 0.5 s. After it, everyone, every animal, the clock and the hour run on
  one shared 0.5 s tick in a single frame. Its tests (presence_test) cover observation-independence, not frame pacing.
- **Owner report 2026-11-06** ("repeated microfreezes far from the starting village", Windows) led to **`82cb449`**
  (2026-11-06). `NPCBrain.batch_unit` exited early: 15-27 ms a call, 66 ms a plan. The view built one chunk a frame instead
  of up to three, plus `_prefetch`. `travel_perf_test` (world plus chunk building, headless, no scene) went from 200
  frames over 33 ms to 4. It recorded "two world spikes remain", in `docs/release/B25R2_COMPLETION_CHECKLIST.md`
  (`2011bf6`, `a09b698`): "the first frame of the run (07:00-07:01, villagers deciding, about 230-400 ms) and the daily
  17:00 hour (about 230-380 ms, world)"; CI on `f3c5bdd` (42263249923) had a worst frame of 234 ms. These are **the two
  ~230 ms spikes**.
- **Owner report 2026-11-07 01:56 UTC:** "like a clock ticking every other step it would freeze for a second". It led to
  **`ed221df`** and **`fe7d8f8`** (2026-11-07). `stutter_probe.gd` (the real scene) found 37 frames over 50 ms, each a
  frame where `MapView._put` made a new tile (150-280 ms). `MapView._make_all_tiles` now makes the tiles the overworld's
  data names at the start (3,062 in 53 ms). Afterwards: 4 frames over 50 ms ("worst about 150 ms: the village's hour").
  `tile_premake_test` checks 4/0 with the start-up tiles and fails 2 without them. Recorded in `8dfc844` (register
  B25R2-STUTTER APPROVED, "real PC not checked") and in `docs/KNOWN_ISSUES.md` KI-14 (on `wip/requirements-control`):
  "one frame of about 150 ms at the village's hourly work, plus the first-frame and 17:00 spikes of about 230 ms.
  Measured headless only".
- **Was it root cause?** In part. The tile mechanism was found and fixed for the overworld. The leftover 150 ms hourly
  frame was not explained; it is autosave plus the hour, #3. The two 230 ms spikes were recorded but **never explained or
  fixed**. They are now explained (#5):
  - **First frame:** the first tick plans every villager at once, travellers' long journeys included (0.8-0.9 s here). It
    is the same frame as Build 40's D3, "hitch after Continue".
  - **17:00:** `NPCBrain.reeve_day()` (`npc_brain.gd:3748`, called from `world.gd:522`), 30-130 ms, plus that tick's
    villagers.

  Neither is periodic at walking pace. Neither probe measured the 0.5 s cadence: `travel_perf_test` and `stutter_probe`
  list only frames over 33/50 ms.

## Phase 2: pipeline trace (a5a0b7c)

`main._process` (`main.gd:1989`) does the following, in order:
1. audio and view report;
2. `world.update(delta)`, the accumulator and fixed ticks. Each tick: the clock, then the hour (`_on_hour`: recorder,
   regions, couriers, trees, wilds, farms, feasts at 17/20, chapel at 16, food days, tables, business, carts, relations,
   fields, `_new_day` at 6, reeve at 17, guards at 18, caravan at 12, judgment), then gossip, crowd and every villager
   (`_update_npc`: hunger, fight, pursue, journey, runaway, homestead, decide, run plan with path search), then fauna.
   Every frame: carts, the player's needs, `presence.refresh/classify` (about 1 ms every frame, 10-24 ms on some tick
   frames);
3. `_player_step` (input, collision with `_try_move`, delta-scaled step);
4. projectiles, look, aerial (aerial maps draw only while the player stands still);
5. the hourly autosave;
6. fx;
7. `_sync_sprites`: villager sprites interpolated along the last tick's trail, doors, canopy, tree view, then
   `ow_view.follow`: recentre, build one chunk, else `_prefetch` one, roads, live water, works and homes, roofs, canopy;
8. levels, outlines, HUD.

No `_physics_process` takes part in movement. Multiplayer is not active in single play (`net.apply_requests` only when
hosting). The periodic jobs:
- every 0.5 s: the tick (#1);
- every game hour (30 s): the hour, plus the autosave (#3);
- daily: 06:00 dawn, 17:00 reeve and feast plan, 12:00 caravan;
- every chunk crossed: `_prefetch` and `_build` (#4);
- on world events: tile creation (#2), sprites created by Presence `entered`.

## Phase 3: measurements

**Probe:** `game/tests/freeze_probe.gd` on the real `main.tscn`, a new game (seed 1). The player is walked by
`Input.action_press` on the movement actions, so the real `_player_step`, collision and camera run. The route goes from
the start point (44.5, 53.5) through the village's south gate (66, 90) to Wendholt (180, 262) and back and forth inside
it, 98.9 game seconds, 5,932 frames. Every frame goes to a CSV with: wall time, delta, ticks, World.prof parts,
main._process parts, OverworldView parts, tiles made, draw time.

`--fixed-fps 60` gives every run the same world, with wall time measured; without it, the delta is real (catch-up). The
summaries come from `tools/freeze_probe_report.py`. Per-tick world costs over whole days, the world alone, come from
`game/tests/hour_cost_probe.gd`.

To reproduce:
```sh
godot --headless --path game --import
godot --headless --fixed-fps 60 --path game -s res://tests/freeze_probe.gd -- csv=/abs/out.csv seconds=200 stay=25 [premake_fields]
python3 tools/freeze_probe_report.py /abs/out.csv
godot --headless --path game -s res://tests/hour_cost_probe.gd -- days=2
xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --path game -s res://tests/freeze_probe.gd -- csv=...
```

**Frame times on a5a0b7c** (headless, fixed 60 fps, 5,902 frames after 30 loading frames):

| run | p50 | p90 | p99 | p99.9 | max | >16.7 | >33 | >50 | >100 ms |
|---|---|---|---|---|---|---|---|---|---|
| a5a0b7c (Build 40) | 5.95 | 9.50 | 25.6 | 96 | 180 | 115 | 22 | 7 | 6 |
| a5a0b7c + field tiles made first (PROBE) | 6.44 | 9.66 | 25.4 | 44 | 98 | 125 | 24 | 5 | **0** |
| ed221df^ (`ef8141a`, before the tile fix) | 6.19 | 9.46 | 30.5 | 150 | 219 | 139 | 51 | 36 | 23 |
| 82cb449^ (`624094c`, before the chunk fix) | 6.86 | 10.1 | 43.5 | 197 | 284 | 123 | 66 | 56 | 30 |
| e66ca18^ (`b118bee`, before the fixed tick; generation 7: a different world, route to Wulstead, 100 s) | 4.81 | 6.72 | 22.1 | 119 | 329 | 63 | 51 | 36 | 9 |

By place on a5a0b7c, frames over 33 ms: village 0 (p99 9.8 ms), open country 15 (p99 26 ms), Wendholt 7 (p99 27 ms).

**The 0.5 s cadence** (mean wall time by frame phase mod 30):

| run | the 0.5 s frame | the other 29 |
|---|---|---|
| a5a0b7c | median 12.5, mean 19.0 ms | median 5.9, mean 6.6 |
| PROBE | median 13.4, mean 16.7 | median 6.4, mean 7.0 |
| e66ca18^ | median 4.8, mean 6.6 | median 4.8, mean 5.6 (no peak) |

**The long frames on a5a0b7c and their causes** (each named by the profiles):
- 180, 164, 144 and 129 ms: a field tile made in play, cost after main (#2), at t = 94.5, 69.0, 34.0 and 62.5 s.
- 149, 117 and 94 ms at 10:00, 08:00 and 09:00: autosave 83, 62 and 53 ms plus the hour (#3).
- 30-47 ms runs of 3-5 frames: `_prefetch` (#4), at t = 14.1, 28.8, 41.8, 53.4, 58.9 and 66.6 s.
- 33-60 ms single frames: ticks (villagers 17-37 ms, presence 11-21 ms) (#1, #5).

Intervals between frames over 33 ms: median 2.5 s (11 tiles walked).

**World alone, per tick** (hour_cost_probe, 1-2 days): p50 5.1-5.8, p90 14.6-15.5, p99 32-40 ms. The first tick is
0.79-0.92 s. 06:00 is 0.59-1.18 s. 17:00 is 146-172 ms (reeve 30-130). 21:00 and 18-20:00 reach 70-126 ms (villagers'
evening plans, relations 14-22 ms). Villager ticks over 30 ms: a traveller's path to (36, 775) 345-409 ms (twice), and
bandits 35-44 ms.

**Real renderer:** xvfb with OpenGL 3 on llvmpipe, a software rasteriser on the CPU. Draw time p50 17 ms, p90 24 ms.
Field-tile frames grow to 171-222 ms; the autosave frames do not change. Draw spikes of 45-75 ms come with no game
event (not correlated with chunk building, ticks or tiles): this looks like the software rasteriser and machine load,
and is not evidence about a real GPU.

**Catch-up** (real delta, `--max-fps 60`, 100 s): frames over 100 ms are followed by a player step of 0.43-0.65 tiles
(normal 0.075). No frame ran two ticks.

**Caveat on absolute numbers:** the container has 4 cores shared with other workers (load average 2-5.5 during the
runs), so absolute times vary about ±30% from run to run. The categories, their functions and the before/after
differences repeated in every run.

## Phase 4: recommendations (not implemented; for the owner's approval)

Ranked by impact over risk:

1. **Field tiles at the start (#2).** Add the 4×4 edge variants of `tiles.field` (tilled, growing, ripe), and any other
   village tile the simulation can draw in play (stall awnings `Business.AWNING`, fences and gates `Farming.FENCE`/`COZY`,
   fittings `Fitting.ART`, ore and depleted rock, door frames), to `MapView._make_all_tiles`. Also extend
   `tile_premake_test` to emit every `tile_changed` value the systems can produce. Low risk; it removes the largest
   single stalls (110-220 ms). Proven by the PROBE.
2. **Spread the world tick across frames (#1).** Run the villagers in slices: for example, 1/N of `npcs` each frame of
   the 0.5 s, each still on its own fixed 0.5 s step, in a fixed order by id, so the results stay deterministic and
   independent of the frame rate. Run fauna likewise. The hour can run on a frame of its own, apart from the villagers.
   This removes the 2 Hz pacing. Medium risk: the order in which rules see each other changes within a tick, and the
   simulation baselines may move. It needs the owner's decision (TEST-AUDIT and baseline rules) and the
   determinism/economy gates.
3. **Autosave off the frame (#3).** Build the dictionary on the frame, but stringify and write it on a
   `WorkerThreadPool` task, or spread it over frames. At minimum, keep it off the tick frame and the hour frame
   (`main.gd:2024`, one frame later). Low-medium risk (save consistency: snapshot first). Removes 50-85 ms every 30 s.
4. **Chunk generation off the main thread or time-sliced (#4).** Generate `Overworld.get_chunk` for `_prefetch` on a
   worker (the data is pure per chunk and seed), or limit `_prefetch` to a time budget with chunk generation done in
   resumable parts. Medium risk (thread safety of the overworld caches).
5. **Clamp the frame delta and cap catch-up.** Limit the delta used for the player's step (for example to 50 ms), and
   the number of ticks one frame may run (with the rest carried over), so a stall is not followed by a jump or a
   cascade. Low risk for single play. The world's time per real second is unchanged unless a cap is reached.
6. **Spread the rare spikes (#5):**
   - long path searches incrementally or on a worker (travellers);
   - stagger the first tick's decisions (first frame, D3 Continue);
   - slice 06:00 dawn (`brain.dawn`, construction and manor) and 17:00 `reeve_day` over several ticks.

   Medium risk each; the economy baselines are affected.

## What could not be measured

- Real devices: a Windows PC with a GPU, an Android phone, a gamepad. The owner's machine is likely to show #1 more on a
  phone (GDScript there is several times slower) and possibly less on a fast PC.
- GPU draw cost and vsync behaviour: the llvmpipe numbers are not representative.
- Release export templates: the editor binary was used.
- Multiplayer: not active in single play.
- Long sessions: save size growth and D4 memory growth were not measured over hours.
- Whether the owner's "freeze for a second" was #2 (110-220 ms, worse with a renderer), #1 (every 0.5 s) or both:
  needs a device check with the flight recorder or this probe's CSV.

**Needs hardware verification:** the frame-time distribution on the owner's PC and phone, with
`freeze_probe.gd`-equivalent logging (frame time and tick flag), before and after each correction.

## Instrumentation added (diagnostics only, off by default, reads the clock only)

- `main.gd`: `frame_profiling`, `frame_prof` and `_fp`.
- `overworld_view.gd`: `profiling`, `prof` and `_pf`.
- `map_view.gd`: `log_made` and `made_log`.
- `world.gd`: hourly parts (`hour: ...`), villager branches, and `slow_npcs`, under the existing `profiling` flag.
- Tests: `game/tests/freeze_probe.gd` (with the PROBE option `premake_fields`) and `game/tests/hour_cost_probe.gd`.
- Tool: `tools/freeze_probe_report.py`.

presence_test passes (37/0) with the instrumentation.

## Wiki and documentation

No player-facing change, so no wiki page. This report is the technical reference. The register (B25-MOVE-STUTTER-INV,
B25R2-STUTTER) and KI-14 are for the lead to update; this worker does not edit the register.
