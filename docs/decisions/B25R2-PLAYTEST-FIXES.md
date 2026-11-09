# B25R2-PLAYTEST-FIXES: fixes for four defects from the owner's 2026-11-06 evening playtest (hosting for 4, cave follow, Host a game, stutter)

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01) from:
> - the register entries B25R2-HOST4, B25R2-CAVE, B25R2-HOSTMENU and B25R2-STUTTER, with their `owner_answer` fields;
> - commits `6f23933`, `5d07527`, `ef8141a`, `ed221df` and `fe7d8f8`;
> - `docs/release/B25R2_COMPLETION_CHECKLIST.md`;
> - the owner's playtest messages, recovered verbatim in
>   [`2026-11-06_recovered_owner_messages.md`](../directives/2026-11-06_recovered_owner_messages.md) (sent 2026-11-06
>   19:34-20:56 EST);
> - the session's question answers of 2026-11-07 01:42 UTC.
>
> Times are UTC. The five original Play Test Build One repairs (riverbank autotravel, chunk stutter, controller, bridges) are
> recorded with full evidence in the checklist and are not repeated here.

## A. Identity and timeline
- **Register:** B25R2-HOST4, B25R2-CAVE, B25R2-HOSTMENU and B25R2-STUTTER. Related: B25R2-PKG-01, the owner's provisional Windows
  package (artifact 13542782040 from `1f2ff4f`).
- **Branch:** `wip/b25r2-rev2`, started from `1f2ff4f`. All four fixes were done by the lead, the night of 2026-11-06/07.

| Time (UTC, 2026-11-07) | Event |
|---|---|
| 00:34 | Owner: the join code is too long ("who wants to type all that") |
| 00:49 | Owner: "it says its full and only 1 person joined" |
| 00:58 | Owner: "open hosting to 4" |
| 01:02 | Fix `6f23933` |
| 01:19 | Owner: his daughter, as a guest, followed him into a cave and was stuck in the black outside |
| 01:20 | Owner answers "1" (fix now) |
| 01:42 | Owner answers the Host a game questions (saved world; then the host window) |
| 01:44 | Fix `5d07527` |
| 01:55 | `ef8141a` |
| 01:56 | Owner: severe stuttering south of the starter village ("a definite game breaker", register) |
| 02:45 | `ed221df` |
| 02:48 | `fe7d8f8` |
| 03:09 and 03:11 | Owner: hold and save; then the "finish the six suites" directive |

## B-C. What was wrong and what was found

| Item | Observed | Cause (from the commit) | Fix | Test (green; red on old code) |
|---|---|---|---|---|
| HOST4 | A second friend was told the game was full | The host window passed no player limit, so `NetSession.host` defaulted to 2 | The window asks for the owner's limit, 2-4 (`NetProtocol.MAX_PLAYERS` 4) | net_ui_test 64/0; the 3 new checks fail at limit 2; floor 61 → 64 |
| CAVE | A guest who followed the host into a cave was stuck in rock outside | The guest's moves, on another channel, reached the host before the passage request. The host refused them and corrected the guest's place but not its level, so the guest kept the cave level at an outside place | queued moves are not refused while a passage is waiting; corrections carry the level; the portal answer places the guest on the host's side; the players' list fixes a persistent level mismatch | net_cave_test (new, two processes over loopback) 11/0; 2 failures on the old net_session.gd |
| HOSTMENU | The owner wanted "host a game" on the title screen | not applicable (a feature) | `GameUI.show_host_start`: saved character, new character, or Back; then the Open to friends window | net_ui_test 69/0 (floor 69); start 523/0, demo 35/0, audio 171/0, wiki 144/0, pad_reach 59/0, gamepad_map 19/0 (local) |
| STUTTER | About a 1 s freeze every other step south of the village | Measured with `stutter_probe.gd` on the real game scene (seed 1, the walk to Wendholt): 37 frames over 50 ms, each a frame where `MapView._put` made a new tile. Making a tile in play refreshes every layer drawn with that TileSet, about 150 ms each time | `MapView._make_all_tiles` at start: every tile the overworld data names, 3,062 tiles in 53 ms (all 29,040 cells would take 24 s) | tile_premake_test 4/0; 2 failures without the start-up tiles. The same walk afterwards: 0 tiles made, 4 frames over 50 ms |

Owner's words are in the register `owner_answer` fields and the recovered file.

## D. Coordination
The lead worked alone, in a single session, with the owner playtesting live. No worker was involved.

## E. Decisions and rationale
- All four are owner-directed:
  - "open hosting to 4";
  - "1 (fix it now)";
  - the Host a game answers;
  - the stutter: "we have to figure out what's going on there".
- **Stutter, alternatives recorded:** making every atlas cell was measured at 24 s and rejected; only the tiles the data names are
  made. Animated tiles stay made on first use.
- **Not done:** the long invite code. The owner picked an option, but no register record of the choice was found
  (coverage register HR-27).

## F. Verification
- **Local first:** the fourteen drawing suites on `fe7d8f8` ran 1,885 checks with 0 failures and 1 script error. That script
  error was B25R2-BRUSHOFF, a latent defect, not caused by these fixes.
- **First CI run that contains the fixes:** the strict run on `f0a854c` (42519022430), which passed. Batch A was built on
  `fe7d8f8`.
- **Not done:**
  - a real-PC check of the stutter fix. One frame of about 150 ms at the village's hourly work remains, plus the known
    first-frame and 17:00 spikes (about 230 ms);
  - a real two-device cave test;
  - the owner has not replayed these fixes. The package the owner played (`1f2ff4f`) predates them.

## G. Next action
The next package should carry the label "0.1.34 Rev 2 — Playtest 1" (B25R2-VER-01). A private draft is allowed only under
B25R2-DRAFT-01's conditions, which include the owner's baseline decision. These fixes are on `wip/b25r2-rev2` in every later
merge.
