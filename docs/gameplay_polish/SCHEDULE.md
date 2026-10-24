# Gameplay and Controls Polish (GP-POLISH): placement and dependencies (2026-10-24)

Owner directive `docs/directives/2026-10-24_gameplay_controls_interaction_directive.md`. All work happens on the multiplayer branch
`wip/multiplayer-b19`, by the one primary development agent in sequence, so nothing conflicts with Batch A1 and every change is
per-player from the start. Build 19 is not touched. Expansion 20 waits for multiplayer's gates and this batch.

| Slot | Items | Depends on | Why there |
|---|---|---|---|
| **P1: right after Batch A1 lands** (isolated, presentation and data only) | GP-ANVIL (station 's5' anvil at [77,43], use [78,44] in `game/data/village.json`, checked against the drawn anvil by screenshot), GP-PICKAXE-ANIM, GP-ACTIONBAR | nothing in multiplayer | small, independent of the player-action architecture; screenshot verification on desktop, device check on Android |
| **P2: after Batch A** (player actions are explicit intents) | GP-PROGRESS-BAR, GP-JOYSTICK, GP-HARVEST-CONT, GP-LOCKPICK, GP-INPUT-CONSIST | A1 per-player activity and verbs; A2 intents and host validation | each needs per-player activity state, input separated from actions, and host authority (lock state, harvested output) |
| Gates | each item's acceptance in the register; G0 (single player unchanged) at P1 and P2 ends | | device checks (Android touch, gamepad, Steam Deck) recorded separately as unverified until run |

Reference images: `docs/gameplay_polish/reference/android_mining_hud_2026-10-24.png` (the owner's Android screenshot);
the lock cutaway reference is kept in the git-ignored `private-assets/references/pin_tumbler_lock_reference.gif`.
