# Extra Life preview: continuous gameplay session (2026-11-12)

Status: **FINAL** (2026-11-12, 22:00 EST; the interim version was `dcd586e`). Preview head: **`b31476d`** on `wip/b25-preview`.

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
| Added | `7006499` the session test `game/tests/extra_life_session_test.gd` (+ `tests.yml` entry beside `player_journey_test`, floor 25 in `tools/ci_check_floors.json`); `ed8899d` stuck-walk diagnostics; `b31476d` the in-play hunt watch (`--hunt-watch`) |
| Merged | `origin/wip/b25-animal-hunt-ai` at `3ba8d22` (the lead's request); merge commit `0be964a`. One conflict, `docs/SYSTEM_INTERACTION_MANIFEST.md`'s Loot and Fields index rows: both sides kept (INT-783 added); `check_interactions.py` 448 interactions, 0 problems; `tests.yml` and floors merged cleanly |

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

On the merged heads: `animal_hunt_ai_test` 68 checks, 0 failures, 0 script errors (`0be964a`); `extra_life_session_test` 30/0 and
`player_journey_test` 95/0, 0 script errors (`b31476d`).

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

## 3. Results

**Short sessions (1 to 5 rounds, ~7 to 36 game hours), on every head:** every activity works end to end through the real windows:
dialogue, pack and wielding, felling (+4 or 5 logs a tree, plus saplings), mining (+3 stone), hunting (rabbit, deer, bird, fox, boar),
taking the kill, crafting (saw planks at the sawhorse, roast meat at the oven), the reeve's board work paid, selling and buying,
eating, and save/Continue exact on every compared field. Coins conserved after every step. 0 script errors in every run.

**The long session (final, on `b31476d`):** 40 rounds, **550 game hours (23 game days, into Year 3), 27 wall minutes, 22,372
frames, 40 save/Continue cycles**, then a deer, a boar and a bear hunted in play. 914 checks; 0 script errors, no crash, no
conservation break (coins conserved at every step of every round), and **every one of the 40 reloads exact** (purse, pack, player,
journal, messages, quests, clock, world coins, position). Events: 20 trees felled, 20 mining trips, 40 animals hunted, 39 crafts,
14 board jobs paid, 21 sales. The 65 failed checks are all accounted for:

| Failed checks | Cause | Defect? |
|---|---|---|
| 40 (rounds 21 to 40: felling and mining +0) | The starting rusty axe and pickaxe (durability 60) wore out after about 20 trips; the Use prompt then says "A tree: requires an axe (the smith sells them)". The session does not buy new tools. | No: tool wear by design. Stream note below. |
| 16 (the reeve not reached, or asleep at home) | The reeve indoors under a roof cannot be talked to from outside (by design); at night he sleeps (the sleeper window). | No (session timing) |
| 9 (no villager talked to) | Every free villager within 60 tiles was out of reach or busy; and **D2** below. | Partly D2 |

Earlier long runs (on `610a24d`/`7006499`, before the session gave up unreachable villagers): in 3 of 5 runs the player ended
up standing beside a farm-plot fence (34.5, 65.6 or 39.5, 69.6) for game days, unable to reach anything, and **starved**. The
diagnostics (`ed8899d`: Main's walking state and a 60-frame trace) found the cause: `Main.talk_to` was still set to a villager
on the other side of a fence (a guard, a merchant) from an earlier failed "walk up and talk", and `_talk_step` set `move_to`
back to that villager on every frame, overriding every later walk (trace: `<move_to (39.5, 71.5)>` every frame, the player not
moving). Loading the saved world in that state (`stuck.json`) walks out at once, because a load clears `talk_to`. That is D2.

### Hunting a deer, a boar and a bear in play (animal-hunt AI, `3ba8d22`)

Judged on the game's own frames: the player walks to the nearest grown animal and hunts it as a player does (`Main.strike`, one
tap per blow, a new tap whenever the last blow is done, following when it runs); every quarter second the distance, the animal's
health and state and the player's health are logged; under xvfb, 16 consecutive screenshots 0.25 s apart, cropped round the
fight (contact sheets: `docs/audits/img/2026-11-12_el_hunt_{deer,boar,bear}_play.png`; looked at). Three runs gave the same
picture (times are one run's):

- **Deer** (18 health): grazing until the first blow; struck, it runs ("running" from the player) in short zigzag legs, the player
  following 1.2 to 2.3 tiles behind and striking each time it is in reach; killed after 8 to 10 s and 10 to 15 taps. It never gets
  away: its flight (1.5 x 2.2 = 3.3 tiles a second) is slower than the player's walk (4.5). In the frames it reads as a deer
  darting about just ahead of the player, not as an escape.
- **Wild boar** (25): startled on the first blow (turns to the player for a moment), then runs like the deer, more slowly
  (2.2 tiles a second); killed in 4 to 5 s, 7 to 9 taps, the player unhurt. It never fights back.
- **Bear** (60): struck, it turns angry, closes to 0.7 tiles (its bite range) and stands there biting about every 3 s for 12; the
  player kills it with the starting rusty sword in 6.5 to 8.4 s and 12 or 13 taps, losing 36 to 48 of 100 health. In the frames
  the bear's sprite overlaps the player's (0.7 tiles apart), and the player flashes white when bitten.
- Visibility: the wild animals live in dense wood. The canopy fades round the player, but the animal, the player and the strike
  marker are often half hidden behind trunks and crowns (deer frames 8 to 15 show mostly the health bar). The large sword
  marker over the target and the "5" damage numbers stay readable.

Behaviour judgement: the turn, startle, zigzag flight and the bear's charge and bites all show in play and look deliberate; no
animal was seen stuck, sliding through trees or jittering in place. Balance (not defects; owner's call): no prey can outrun the
player, and a bear is beaten with the starting sword at about a third to a half of the player's health.

### Memory and frame time over the long session

Static memory 468 MB at the start, **2,729 MB after 40 rounds** (~57 MB a round: ~34 MB per Continue, D1, and ~20 to 25 MB of play,
about 40 MB a game day). The save loop (3 saves) grew nothing; the Continue loop (3 Continues) +168 MB. `Main._process` mean 11.2
ms (headless, simulation only), 175 frames over 50 ms out of 22,372, almost all in the first frames after a Continue, which grew
from ~0.5 s early on to 1.1 to 1.6 s late in the session (D3).

Screenshots of the session (xvfb, 1280x720, looked at; `docs/audits/img/2026-11-12_el_session_*.png`): Mabel Reed's talk window,
the pack window (Weapons tab, the sword in the hand slot), after felling (two felled oaks, "+4 Log", "+1 Oak sapling", the stump
prompt). Nothing visually broken. The opening screen shows the HUD and the opening hint.

Exported builds: `--export-release "Linux"` and `"Windows Desktop"` both export cleanly from the preview branch locally (93 MB and
129 MB). The Linux release binary starts and runs 3,000 frames on the title under xvfb with no script error (only the container's
missing sound card and V-Sync warnings). Release builds leave the tests out, so a scripted soak of the exported binary is not
possible; the session ran in the editor binary.

## 4. Defects

| # | Defect | Severity | Repro |
|---|---|---|---|
| D1 | **Memory leak on every load (Continue, and any load after a death or from the menu):** the old World is never freed: about +34 MB static memory and +300 to 500 objects per load (2.9 GB after 43 loads in the long session). Saves alone do not grow. Cause found: the World is `RefCounted` and its parts hold it back (31 parts' `w`, nested parts such as `business.stalls.w`, `economy.market.w`, `mine_works.supply.w`, `judgment.world`, `judgment.social.w`, and the `journey_hook`/`person_hook` lambdas); `World.dispose()` breaks only `brain`, `fauna`, `construction`. An attempt that broke all of those (and disconnected the world's signals) still left 3 or 4 references not reachable from script variables, so the world was still not freed. Nothing committed; the attempted patch is kept in the worker's scratchpad. | visible but playable (a stream loads a few times: ~34 MB each, and a slightly longer hitch after each) | `extra_life_session_test.gd -- --rounds 1 --reload-loop 5`: 517 -> 548 -> 582 -> 617 -> 651 -> 686 MB |
| D2 | **Walking up to a villager who cannot be reached never gives up:** tap a villager behind a farm-plot fence (or across water): the player walks to the fence and stands there; `Main.talk_to` stays set, `_talk_step` keeps setting `move_to` back to them every frame (`walk_stuck` is reset by every re-path, so nothing notices), and no message is shown. A tap on the ground or the movement keys clear it. In the scripted runs (no key input) it held the player for game days until they starved. | visible but playable; could look like a freeze on stream if the player keeps tapping the same villager | the farm plots at (32 to 41, 63 to 74) once their fences are up (game day 3 to 5): tap a farmer or guard inside; long-session runs 1, 2, 4 and 5 |
| D3 | Frame hitch after a Continue: the first frames take 0.5 s early in a session, up to 1.1 to 1.6 s after 30+ loads (it grows with D1). A few frames of 100 to 360 ms when a hunt or a craft begins. | cosmetic | any session; `SESSION frames over 50 ms by phase` |
| D4 | Static memory grows ~40 MB a game day without loading (about 600 MB over a 3-hour stream at 2 game minutes a second). Not traced; it may be the world's growing history rather than a leak. | cosmetic for a 3-hour stream on a desktop PC; worth tracing after | the long session's per-round samples |

Not defects (by design, recorded for the stream): the starting axe and pickaxe wear out after about 20 uses each (buy new ones from
the smith); a villager at work answers with a brush-off line; a shopkeeper at a post opens the trade window directly; a villager
indoors is not talked to from outside; the reeve sleeps at night and sets his board at five in the evening (he says so); the only
sawhorse (`s7`) and the oven (`s1`) are often in use by villagers, so the player may wait to craft; a young animal or a bird can
leave nothing to take.

## 5. Recommended before the stream

1. **D2 (small, low risk):** in `Main._talk_step`, give up on `talk_to` when the player has not got closer for ~2 s (or when
   `path_for_player` finds no route to within 1.3 tiles), clear `move_to`, and say "You can't reach <name> from here." Otherwise
   tell the streamer: if the character stands still by a fence, tap the ground or press a movement key.
2. **D1: not tonight.** The fix touches every subsystem's world reference and is not complete; ~34 MB per load is harmless for a
   few hours on a desktop. Advise the streamer not to Continue/load repeatedly. Fix after the stream (break the remaining
   references; add a test that `weakref(old_world)` is freed after Continue).
3. Stream notes: tools wear out (the smith sells new ones); the reeve's board fills at five in the evening; the sawhorse and oven
   are shared with villagers; hunting in the woods is easier to watch at the wood's edge.

## 6. Not tested

Real Windows hardware (only the export was checked); a gamepad, or touch on a device; audio (the container has no sound card);
multiplayer during the stream; frame rate with rendering on real GPUs (frame times here are simulation only, headless); a
scripted soak of the exported release binary (release builds leave the tests out; the binary was only started and idled on the
title); the player buying replacement tools; dying and continuing as the heir in normal play (seen only in the stuck runs).
