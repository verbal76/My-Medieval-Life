# Build 20: tester notes

A private playtest build for the owner (not a public release): Checkpoint 1 of the gameplay and controls polish
(GP-POLISH), built from `wip/multiplayer-b19`. Android, Windows and Linux come from one commit with one build number.

## Before you install (Android)

- **This APK is signed with a disposable key** (the owner's one-time exception for Build 20). It cannot install over
  Build 19: uninstalling Build 19 deletes its save. **Export your save first** (Settings > Saves), then uninstall,
  install Build 20 and import it. Build 19 saves load in Build 20 (save version 21; tested).
- Later builds will be signed with a permanent key and install over each other.

## What is new since Build 19

- **Anvil and stations (Android):** tapping a station's drawing (the anvil, not the woodpile beside it) walks you to it
  and opens it. A station is offered only when you stand on its working spot, or beside it and facing it.
- **Pickaxe swing (Android):** mining from Gather mode or a tap now swings the pickaxe the whole time.
- **Action buttons (Android):** the nine touch buttons stand in two readable columns at the right edge; Gather says ON or
  OFF.
- **Windows that fit the screen:** the Pack's item details scroll and their buttons (Eat, Drop, Drop all...) always stay
  on screen; the talk and stall windows no longer run off the right edge.
- **People in front of houses** are drawn in front of the wall, not half under it.
- **A rusty axe** in every new character's starting kit (slower than a proper axe, wears out).
- **Cut wheat shows stubble** as a field is harvested, from where the cutting started.
- **Trails** no longer draw stray grass edges over dirt yards.
- **Back doors** are no longer drawn on top of roofs, and a trail leads to every door.
- Two Build 19 test defects fixed (the 50-ore contract test and the judgment decay demo).

## Not in this build (still on the list)

Your other reports are recorded and scheduled, not forgotten:

- the missing smithy wall indoors, which needs your decision (fixing it moves the chapel lane by one tile and changes the
  village simulation);
- the bandit camp's wrong pictures, which need campfire art;
- the gift number picker (one tap gave exactly one gift in every test; the repeat is still being looked for);
- the pause panel, setting a price on put-up, a bigger stall table, smaller menu text, the classic wiki layout;
- taking items from tables, the tavern "crate" and the courier booth at the forge, the business desk, the smithy
  workbench and sharpening;
- farmers working through their fields, the joystick option, continuous harvesting, the overhead progress bar, the
  lockpicking minigame;
- the dialogue, crime and guard repairs.

## Multiplayer

The multiplayer foundations are in the code but **inactive**: there is no menu to host or join, and nothing in the game
offers it.

## Verification and the simulation gate

Build 20 **predates the mandatory pre-build simulation and flight-recorder gate (SIM-GATE-01)**, which applies from the
next release. It was verified with the existing checks: the complete test inventory (`tests.yml`), the Python suite and
data validators, the single-player determinism gate, and money and item accounting. The determinism baseline changed only
by the rusty axe in the starting kit, as authorized and documented (`docs/DECISIONS.md`; the Build 19 baseline is kept).

## Known limitations

- Nothing here has been checked on a real phone, controller or Windows PC; layouts and touch were tested with simulated
  input at the phone, 16:9, 16:10 and Steam Deck sizes.
