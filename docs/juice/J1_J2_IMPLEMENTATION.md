# Game juice J1 and J2: implementation notes (Build 25)

Owner Decision 9, 2026-11-01 (`docs/directives/2026-11-01_nine_owner_decisions_consolidated.md`; register B25-NINE-D9,
JUICE-J1). Assessment: `docs/juice/PRELIMINARY_ASSESSMENT.md`. Interaction: INT-670. Test: `game/tests/juice_test.gd`.
Not in scope: J3-J5, screen shake, haptics, day/night darkness, NPC speech bubbles, a notification filter.

## What is built

| Part | Where |
|---|---|
| Effects helper: pooled particles (cap 48), camera culling (30 tiles), Reduce effects, flash and pulse | `game/scripts/view/effects.gd` (`GameEffects`, one instance, `Main.fx`) |
| Corner log in two lanes, coin counter, prompt pulse, No blinking | `game/scripts/ui/game_ui.gd` |
| Flinch (the sheet's hurt frames) and the stroke-frame impact | `game/scripts/view/actor_sprite.gd` |
| Feeds from real events (health fall, work blows, deliveries, completion, depletion, felling, sprint start) | `game/scripts/main.gd` (`_fx_step`, `_flinch_check`, `_work_fx`, `_player_fx`, `_fx_tile_changed`, `_fx_building_added`, `_sync_sites`) |
| Settings `[accessibility] reduce_effects, no_blink` (settings file, not the save) | `game/scripts/ui/game_settings.gd` |

Presentation only: nothing here is read by the world, it never draws on `World.rng` (the helper has its own generator),
and it changes no save. Evidence: `juice_test` compares `World.rng.state` across every trigger; the 10-day seed-1
economy fingerprint is `0e5e945af798c6fec96eea72d3bed048` both on `origin/wip/expansion20` (`2c364d1`) and with J1/J2.

## Notification routing (for Decision 8's progression notifications)

The corner log (top right) keeps its size and has two lanes; the player's own lane sits above the village lane, and
while both have lines each keeps its newest one.

- **Personal** (the player's own news; a gold edge): `GameUI.personal(text, item := "", category := "", seconds := GAIN_SECONDS)`.
  `item` adds that item's icon; a `category` from `message_journal.json` (for a skill level, `"skill"`) also keeps the
  line on the journal's Messages page through `World.player_tell`, as `message()` does. Gains use `GameUI.gain(text, item)`.
  Example: `ui.personal("Mining Level 3 Reached.", "", "skill", 4.0)` (`Main._level_up` already routes skill levels here).
- **Village** (what happens in the village): write `World.note(text)`. It is kept in the village record (Menu, Journal),
  reaches a guest with the host's record, and shows in the village lane through `World.event` -> `GameUI.village`.
  Example: `world.note("Village Development: Mining Capability Level 2 Reached.")`. Never send village news through
  `personal()`, and never call `GameUI.village` directly from the simulation (the UI may not exist, as in `economy_sim`).
- Announce a village milestone once, when its recorded history first reaches the level, not on every fluctuation of
  current capability (Decision 8); that de-duplication belongs to the milestone record, not to the log.
