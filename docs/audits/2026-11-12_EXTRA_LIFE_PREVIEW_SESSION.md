# Extra Life preview: continuous gameplay session (2026-11-12)

Status: **INTERIM** (pushed 2026-11-12 ~21:45 EST; the final version follows by 22:30 EST).

Owner directive `docs/directives/2026-11-12_b25_stabilization_animal_ai_extra_life_preview.md` (on `origin/wip/requirements-control`),
section 3: a private Windows gameplay preview for casual play on the Extra Life charity stream, clearly marked incomplete, not a
Steam release. "Test a representative continuous gameplay session and document any remaining defects."

This is a worker report. It changes no register entry (the lead does that) and publishes nothing.

## 1. The preview branch

| | |
|---|---|
| Branch | `wip/b25-preview` |
| Base | `b3c9eb5` (development line, chain 12) |
| Merged | `origin/wip/b25-nd19-28-journey` at `baa0a72` (ND-28 guest pacing x2, ND-19 walk re-path and fencer stand, journey findings 2 and 3); merge commit `610a24d`, no conflicts |
| Added | `7006499` the session test `game/tests/extra_life_session_test.gd` (+ `tests.yml` entry beside `player_journey_test`, floor 25 in `tools/ci_check_floors.json`) |

Targeted suites on `610a24d` (Godot 4.7.2 headless, `tools/ci_report.py` with `--fail-on-script-errors --require-counts --floors`):
22 suites, **1,123 checks, 0 failures, 0 script errors**. The later commit only adds the new test and its CI lines.

| Suite | Checks | Failures | Script errors | Seconds |
|---|---|---|---|---|
| nd28_guest_pace_test | 30 | 0 | 0 | 15 |
| mp06_guest_trust_test | 42 | 0 | 0 | 15 |
| multiplayer_c_test | 326 | 0 | 0 | 564 |
| net_c_test | 43 | 0 | 0 | 88 |
| combat_test | 41 | 0 | 0 | 29 |
| player_journey_test | 95 | 0 | 0 | 79 |
| demo_journey_test | 64 | 0 | 0 | 80 |
| demo_test | 35 | 0 | 0 | 103 |
| wiki_test | 144 | 0 | 0 | 16 |
| nd19_solid_cells_test | 8 | 0 | 0 | 64 |
| farm_plots_test | 104 | 0 | 0 | 114 |
| npc01_path_backoff_test | 10 | 0 | 0 | 57 |
| journey_site_path_test | 37 | 0 | 0 | 14 |
| sav04_reload_determinism_test | 13 | 0 | 0 | 62 |
| station_tap_test | 25 | 0 | 0 | 17 |
| farm_shared_save_test | 18 | 0 | 0 | 41 |
| judgment_guard_save_test | 20 | 0 | 0 | 121 |
| le06_save_test | 22 | 0 | 0 | 136 |
| save_continuity_test | 5 | 0 | 0 | 131 |
| save_exact_test | 15 | 0 | 0 | 43 |
| save_tolerance_test | 5 | 0 | 0 | 118 |
| save_transfer_test | 21 | 0 | 0 | 137 |
| extra_life_session_test (new, 1 round) | 29 | 0 | 0 | 35 |

## 2. The session (what was played)

`extra_life_session_test.gd` extends `player_journey_test.gd` (reuses its walking, talking, trade-window, reeve and eating
helpers) and drives the real `Main` scene and its windows. Title, New game, character creation, origin Begin, then rounds of:

1. walk up to a villager who is free (not asleep, not at a shop post, not busy) and talk: What do you do?, Any news?, How are things at home?, Goodbye;
2. open the pack, wield the rusty sword from the Weapons tab, flip every tab;
3. walk to the nearest grown tree and fell it with the starting axe (Use, chop by chop), take the logs;
4. walk to stone and mine it with the starting pickaxe;
5. chase the nearest wild game with the sword (attack), take what the kill leaves;
6. walk to an oven (roast meat) or sawhorse (saw planks), open its craft window, press Make, wait for the work;
7. walk up to the reeve, "Any work for me?", take and do a board job for its wage (sleeping first if it is night);
8. sell gathered goods through a trade window, buy food when hungry, eat from the pack;
9. save, return to the title, Continue, and compare purse, pack, player record, journal, messages, quests, clock, world coins
   and position value for value;
10. walk about with the movement keys and let the clock run 300 frames.

Measured each round: `Main._process` frame time, static memory, game time. Coins conserved after every step.

## 3. Results so far

**Short sessions (1 to 5 rounds, ~7 to 36 game hours):** every activity works end to end through the real windows: dialogue,
pack and wielding, felling (+4 logs a tree, plus saplings), mining (+3 stone), hunting (rabbit, deer, bird, fox), taking the kill,
crafting (saw planks at the sawhorse, roast meat at the oven), the reeve's board work paid, selling and buying, eating, and
save/Continue exact on every compared field. Coins conserved throughout. 0 script errors.

**Long session, run 1 (40-minute budget, 8 rounds, 152 game hours, 9.6 wall minutes before it ended):** rounds 1 to 7 clean
(7 trees felled, 7 kills, 7 crafts, 5 board jobs paid, 8 save/Continue cycles exact). In round 8 the player could no longer reach
anything (trees, stone, game, villagers) from (34.5, 65.6), the clock ran three game days during the failed walks, and the player
**starved**. The run did not record the player's level then; a second long run with stuck diagnostics (level, the 5x5 solid
cells around the player, the route length) is under way.

Screenshots (xvfb, 1280x720, looked at): the opening village with the HUD and the opening hint; Mabel Reed's talk window; the
pack window (Weapons tab, sword in the hand slot); after felling (two felled oaks lying, "+4 Log", "+1 Oak sapling", the stump
prompt); after the hunt (blood mark, the next prey's prompt); the reeve's empty-board answer. Nothing visually broken.

Exported builds: `--export-release "Linux"` and `"Windows Desktop"` both export cleanly from the preview branch locally (93 MB and
129 MB). The Linux release binary starts and runs 3,000 frames on the title under xvfb with no script error (only the container's
missing sound card and V-Sync warnings). Release builds leave the tests out, so a scripted soak of the exported binary is not
possible; the session ran in the editor binary.

## 4. Defects found so far

| # | Defect | Severity | Repro |
|---|---|---|---|
| D1 | **Memory leak on every load (Continue):** each Continue keeps the old World alive: about +34 MB static memory and +300 to 450 objects per load; saves alone do not grow. Cause found: the World is `RefCounted` and its parts hold it back (31 parts' `w`, nested parts such as `business.stalls.w`, `economy.market.w`, `judgment.world`, and the `journey_hook`/`person_hook` lambdas); `World.dispose()` breaks only `brain`, `fauna`, `construction`. Breaking all of those found still left the world unfreed (4 references not reachable from script variables), so no fix is committed. | visible but playable (a stream loads a few times: ~34 MB each) | `extra_life_session_test.gd -- --rounds 1 --reload-loop 5`: 517 -> 548 -> 582 -> 617 -> 651 -> 686 MB |
| D2 | **Player stuck, then starved** (long run 1, round 8): every walk failed from (34.5, 65.6) for three game days. Under investigation (level, surroundings). | potentially blocks demo | long session run 1, round 8 |
| D3 | Static memory grows ~18 MB per round of play without a reload, and in the stuck round 8 it reached ~2.8 GB (1.9 GB released at the next load). | under investigation | long session run 1 |
| D4 | Frame spikes: the first frames after a Continue take up to ~1 s (`Main._process`), and a few frames of 50 to 200 ms during crafting and hunting. | cosmetic (a hitch after loading) | any session; `SESSION frames over 50 ms by phase` |

Not defects (by design, recorded for the stream): a villager at work answers with a brush-off line; a shopkeeper at a post opens
the trade window directly; the only sawhorse (`s7`) and the oven (`s1`) are often in use by villagers, so the player may wait to
craft; a young animal or a bird can leave nothing to take; the reeve's board is set at five in the evening (he says so).

## 5. Not tested

Real Windows hardware (only the export was checked); a gamepad or touch on a device; audio (the container has no sound card);
multiplayer during the stream; frame rate with rendering on real GPUs (frame times here are simulation-only, headless).
