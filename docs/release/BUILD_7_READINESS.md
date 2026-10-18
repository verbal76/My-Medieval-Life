# Build 7 readiness report

Prepared 2026-10-18 for the owner's decision. **Build 7 is not authorized**; this report only
describes what a build would contain. Nothing has been built for release, uploaded or published.

## Source

| | |
|---|---|
| Proposed source | `staging/my-medieval-life` at `5fb28ac` (pushed; remote hash verified) |
| Last released build | Build 6, from `claude/charming-albattani-8jjfya` at `3d7bbce` |
| Changes since Build 6 | 31 commits, 109 files, +11,624 / −540 lines |
| Proposed build number | **Build 7**, the next run of `.github/workflows/release.yml`, started by hand on the approved commit; a pre-release, because the commit is not on `main` |
| Platforms | Linux, Windows and Android from that one commit, published together in GitHub Releases |

## What changed since Build 6

Owner requests and decisions, in the order they were made:

- **Quests:** conversation choices, journal quest page, markers by quest kind (story pennant, skill
  scroll, wheat, iron, crossed swords, log, axe), marker over a home quest giver's door, the sage
  storyline also for older saves, the tanner's skill quest.
- **Talking:** real conversation window; busy villagers call out a bubble; villagers never forget
  meeting the player; keepers name the animal the player killed.
- **Trees:** only trunks block; canopies fade over the player.
- **Camera and controls:** two-finger pan, Recenter, village map, a dead zone in the middle of the
  screen; RB (Skills) on the gamepad list; the pad's B closes every window.
- **Screen:** windows and buttons clear of rounded phone corners; buttons sized to their words.
- **Inventory:** Cozy Farm's inventory art, item tabs plus Skills and Journal, six gear slots
  (weapon, tool, body, head, amulet, ring).
- **Shops and theft:** buying at counters and stalls; table food, crates, barrels, stalls and
  pockets can be stolen from; stolen goods stay marked (also in the home chest).
- **Work and food:** villagers hire the player; children eat 0.6 of an adult's share in every food
  reckoning.
- **Interiors:** every building has an inside under a roof that fades; villagers walk in and sleep
  in beds; sleepers can be woken, robbed or attacked; families in beds, guards and cooks on pallets.
- **Property:** one ownership model; buying and weekly leasing from the manor; empty houses return
  to the manor; the player may own several houses and sell them; building anywhere legal with the
  ground bought or leased on the spot; hired helpers; workshops (smithy, carpenter's shop, bakehouse);
  crowded households split and build; readable place names.
- **Map and fixes:** building plots moved off three houses (whose walls had been walkable); quest
  markers drawn over roofs; the four audit defects in ownership fixed (stale field owners, vacant
  stalls, station reservations, unused land price).

## Test results (at `5fb28ac`)

| Suite | Result |
|---|---|
| `game/tests/run_tests.gd` (simulation, economy, saves, property, construction) | 588 checks, 0 failures |
| `game/tests/start_test.gd` (first-play path through the real interface) | 219 steps, 0 failures |
| `game/tests/play_test.gd` (scripted player) | 37 steps, 0 failures |
| `python3 -m unittest discover -s tests` | 41 tests OK |
| `tools/check_interactions.py` | 61 interactions, 0 problems |
| `game/tests/households_sim.gd`, 30 days | 100/100 alive; coins and grain conserved |
| Generators re-run | no unintended diff; village map byte-identical on re-run |

Screens were looked at in screenshots on the phone and desktop layouts for every new window.

## Interaction manifest

61 interactions (INT-001 to INT-061), all with source, effects and tests; reverse index current.
New since Build 6: INT-038 to INT-061.

## Save compatibility

Saves are now version 6. Versions 1 to 5 load with migrations (each with a test from an old-version
save): Build 6 saves (version 3) keep the player's plots, houses, quests and goods; villagers who were
at home load in their beds; the plots moved off the houses take any house built on them along. A save
newer than version 6 is refused with a message and kept.

## Platform readiness

| | Compiles from `5fb28ac` | Run here | Not verified |
|---|---|---|---|
| Linux | yes (78 MB) | launched under a virtual display to the title screen | a real desktop |
| Windows | yes (114 MB) | no Windows machine here | running it on Windows |
| Android | yes (64 MB debug-signed APK) | not installable here | a phone: touch, Back, safe-area insets, performance |

All three come from one Godot project with no platform-specific features except Android's Back
button and the phone layout, so they carry the same features and content.

## Known issues and limitations

- Device-only checks outstanding: two-finger touch, a real gamepad, Android Back, notched phones,
  phone performance, the Windows build on Windows.
- The Windows `.exe` shows Godot's file icon in Explorer (the game window and taskbar show the game's
  icon). Fixing it needs rcedit and Wine in the build workflow, a new build-time dependency.
- Households only become crowded when people move in (no births yet), so splits are rare in play;
  villagers build houses but not workshops.
- The tavern child and the sage sleep on pallets for lack of room.
- No music or sound: none has been supplied.
- Every number labelled provisional (theft, rents, prices, wages, gear bonuses, child food factor,
  roof-fade timings) awaits the owner's balance review.

## Decision needed

Whether to run Build 7 for Linux, Windows and Android from `staging/my-medieval-life` at `5fb28ac`.
