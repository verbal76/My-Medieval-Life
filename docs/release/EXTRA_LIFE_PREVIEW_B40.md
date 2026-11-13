# Extra Life gameplay preview (build 40): INCOMPLETE PRIVATE PREVIEW, not a Steam or production release

Owner authorization 2026-11-12 (one private CI packaging run; packages stay private CI artifacts; release gate not bypassed).

- **Source:** branch `wip/b25-preview`, commit `a5a0b7c` = development line `b3c9eb5` (chain 12) + `baa0a72` (ND-28 guest pacing,
  ND-19 walk re-path and fencer stand, journey findings 2 and 3) + `3ba8d22` (B25-ANIMAL-HUNT-AI) + the session test + D2 (a walk to
  a villager the player cannot reach is given up with a word).
- **CI run:** Build and release 43362745451 (run number 40). Its simulation gate is expected to fail on the known baseline
  differences (no accepted baseline for this version), so nothing is published; the packages are the run's artifacts, kept 30 days
  (until 2026-12-13).
- **Windows package:** artifact `pkg-full-windows` (id 14008684078), file `MyMedievalLife-B40-Windows.zip`, 236,108,280 bytes,
  sha256 `a54fe9fedba4dbdb7ac73d6a2bf98242161af5a41fd38aaf53c73914b8ef2e3e`; it holds one file, `MyMedievalLife.exe` (game data
  embedded). Download (signed in to GitHub): https://github.com/verbal76/My-Medieval-Life/actions/runs/43362745451 , section
  Artifacts, `pkg-full-windows`.

## Installing (Windows)

1. Download `pkg-full-windows` from the run page (GitHub wraps it in a zip: `pkg-full-windows.zip`).
2. Unzip it; inside is `MyMedievalLife-B40-Windows.zip`. Unzip that to a folder of its own (e.g. `C:\Games\MyMedievalLife-B40`).
3. Run `MyMedievalLife.exe`. Windows SmartScreen may warn about an unrecognised app: "More info", then "Run anyway".
4. Saves go to the user's app-data folder (`%APPDATA%\Godot\app_userdata\My Medieval Life` or the project's custom user dir), not
   the game folder; deleting the game folder keeps them.

## What was tested (automated, on `a5a0b7c` or its parents)

- Continuous scripted session through the real game scene and windows (`extra_life_session_test`, worker run on `b31476d`): 40 rounds,
  550 game hours, 40 save/Continue cycles all exact (purse, pack, position, journal, quests, clock, world coins), coins conserved at
  every step, 0 script errors, no crash; each round: talk, pack and wield, fell a tree, mine, hunt and loot, craft at the sawhorse or
  oven, the reeve's board, sell/buy/eat, save and Continue. On `a5a0b7c`: one round 29/0, `player_journey_test` 95/0,
  `d2_talk_unreachable_test` 7/0, `animal_hunt_ai_test` 68/0.
- 22 suites on the preview's base (1,123 checks, 0 failures) including all save suites, multiplayer guest pacing, the wiki.
- Hunting seen in play (frame sequences): a struck deer turns, startles and flees in zigzags facing its way; a boar flees; a bear
  turns, closes to its bite reach and bites.

## Known limitations (for the stream)

- **Not tested on real Windows hardware, gamepad, touch or audio**; frame rate on a real GPU unmeasured (all checks headless).
- **Memory grows with each Continue (D1):** about +34 MB per load (the old world is kept), and about +40 MB per game day of play
  (not traced). Over a 3-hour stream: avoid many save/Continue cycles; quitting to the desktop and restarting clears it.
- **A short hitch (0.5-1.5 s) right after Continue (D3).**
- **Starting axe and pickaxe wear out** after about 20 uses; the smith sells new ones.
- **The reeve's job board fills at five in the evening**; earlier, ask farmers, miners or woodcutters "Any work for me?".
- **Shared stations** (sawhorse, oven) may be in use by villagers: crafting can mean a short wait.
- **No prey outruns the player** and the bear is beatable with the starting sword (balance for the owner).
- **Animals in dense wood are half hidden behind trees**; their health bar stays visible.
- **Tapping a villager behind a fence:** the character now gives up after 3 seconds standing still and says "You can't reach ...".
- **Multiplayer** is in the build but was not part of the preview session.
- The economy is under investigation (caravan income since Build 25R1, owner decision Q33): village life works, but these are not
  final economic numbers.
