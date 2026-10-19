# Build 12: private three-platform testing packet

Made under the owner's master development execution directive of 2026-10-19. Private draft release;
not public. Build 10 and Build 11 are kept as they were.

| | |
|---|---|
| Build | 12 (Android `version/code` 12, `version/name` 0.1.12-test; Windows file version 0.1.12.0) |
| Source | `staging/my-medieval-life` at `f8b4a98` (all three platforms from this one commit) |
| CI on that commit | Tests workflow passed: https://github.com/verbal76/My-Medieval-Life/actions/runs/39220899906 |
| Release run | https://github.com/verbal76/My-Medieval-Life/actions/runs/39221314511 |
| Artifacts | Private draft release "My Medieval Life Build 12" (created 2026-10-19 08:16 UTC): https://github.com/verbal76/My-Medieval-Life/releases/tag/untagged-0a8b8449c482c4df487f <br>`MyMedievalLife-build12-android.apk` (64.6 MB) sha256 `80ce334e52da030427f17e4268adc9574660f6831e765c4775c13a081f31b5a7` <br>`MyMedievalLife-build12-windows-x86_64.zip` (43.1 MB, `MyMedievalLife.exe` with the game packed in) sha256 `2bbf6f8520770f39431221cb53121b189f3d4231b78df7280757d5cccca304f6` <br>`MyMedievalLife-build12-linux-x86_64.zip` (33.4 MB) sha256 `9f555a3fc6b9b1441934d4e27b294a2cb1ff65cc1a92c78c44df97b3596fa643` <br>Verified: all three downloaded back and matched `SHA256SUMS.txt`; the Linux build started under a virtual display and drew the village (screenshot looked at). Windows and Android not run here |
| Since Build 11 (`c6661fa`) | 71 commits on staging |

## Changelog since Build 11

Build 8 master fix list (`BUILD_8_MASTER_FIXES.md`): a new village laid out as one place (no pasted
sample maps), with floors in every room; a quarry-hill mine with a connected cart track; harvesting
that stops after one cycle, can be cancelled (B / Esc / right-click / tap) and gives way to the Pack;
the right tool shown in hand; a choice when a villager stands at a station (Q / Tab, D-pad); sprint
(LT on a pad, Shift on a keyboard); deposits identified by their look; minable boulders (small and
large); collection notices with icons; labelled HUD bars; the cause of death; roof flicker and table-top
clipping fixed; a named Sawmill; personal chests by their homes; succession of essential trades.

B8-029: an 8-day year in four seasons on the world clock; villagers, the player and animals age;
explicit partners and parents, births to partners, deaths of old age, family-first inheritance and the
player's grown child as heir; baby animal sprites, animal old age.

Build 11 punch list 1: the Settings freeze fixed; one tabbed Settings screen with Back; buy/sell
quantity control; healing items and the sage's Apothecary; current/max inside the bars; boulders by
size; seated and sleeping villagers; consumable effects shown; the gold star over your employer; a
market stall, shops in your own rooms with placed equipment and hired attendants, villagers buying only
for real needs; portable save identity (cloud stage 1); the red flowering plant pickable; a
recognisable stove.

Build 11 punch list 2: forge occupancy; chests, locks and lockpicking; dialogue text; animal loot,
pelts, feathers and tanning; longer skill trees; flowers and stone harvestable everywhere; ripe fields
you can see; modular property (rooms added later); the in-game wiki; a recognisable sawhorse; no
interactions through walls; storage quantities and controller focus; usable furniture (sit, sleep,
home oven, food table); farming (clear, till, plough, sow by season, seed saving, pens, eggs, milk,
wool).

## Task report

Full status per task with evidence: `docs/DEVELOPMENT_LEDGER.md`.

- VERIFIED (tests pass; visual items looked at in screenshots): B8-029, B8-004, PL1-01, PL1-02, PL1-03,
  PL1-04, PL1-05, PL1-06, PL1-08, PL1-09, PL1-12, PL2-001, PL2-002, PL2-003, PL2-004, PL2-005, PL2-006,
  PL2-007, PL2-009, PL2-011, PL2-012, and the Build 8 master list items marked FIXED.
- PARTIALLY COMPLETED:
  - PL1-07 / PL2-013: sleeping is right; sitting uses the standing frame cut at the knees (no sit art).
  - PL1-13 stove: a hearth with a pot, no chimney. PL2-010 sawhorse: a trestle bench with logs (no
    sawhorse or saw art in the packs).
  - PL2-008 / PL2-014: rooms join wall to wall with their own street doors (no inner doorway art).
  - PL2-015: coops, shelters, hired farm help, draught animals, trapping and water deferred; all crops
    share the wheat field art.
  - PL1-10: production chains (workers crafting from shop stock), a stall display sprite and shops in
    rented village houses deferred.
  - B8-007: tool icons in hand on the throw frames; no real tool-swing sheets exist.
- BLOCKED: PL1-11 stages 2-5 (Google Drive transfer) need a Google OAuth client the owner registers
  (Google Cloud consent screen, `drive.appdata` scope, Android and desktop client ids).

## Decisions

Recorded in `docs/BUILD_DECISIONS.md` and `docs/DECISIONS.md`; the main ones: owner-approved calendar
(8-day year) and child heir; apprentice-then-newcomer succession; lockpicking uses Stealth; the sage is
the Apothecary; the player's stall needs the player or a hired attendant nearby to sell; open market
pitches for the player; shops' trade follows their equipment; skills levels 1-10 with every perk read
by game code; save version 14 (older saves are refused and kept, never overwritten).

## Tests on the source commit

Python unit tests OK; `check_resources.py` 18 nodes and `check_interactions.py` 136 interactions, 0
problems; regenerated data unchanged. Godot: run_tests 3511 checks, start_test 450 steps, play_test 37,
tree_test 45, world_test 96, aging_test 96, wiki_test passed, health_jobs_test 37, skills_test passed,
chests_test 68, property_test 62, business_test 153, furniture_test passed, farming_test 124,
overworld_test 101: 0 failures. Known regressions: none open.

## Documentation

- Interlocking Systems Manifest (`docs/SYSTEM_INTERACTION_MANIFEST.md`): 136 entries, INT-077 to
  INT-136 added in this run (aging, wiki, health, gameplay fixes, property, furniture, chests, skills,
  village polish, save identity, business, farming), validated by `tools/check_interactions.py`.
- Player wiki (Settings > Wiki, also from the title and pause menus): pages generated from game data for
  every item, recipe, resource node, skill, profession, animal and station, plus controls (keyboard,
  pad, touch), systems pages (needs, healing, theft and locks, trading, stalls and shops, property and
  rooms, farming and animals, calendar, ageing, families, inheritance, the mine), "How do I...?"
  guides, production chains, search and cross-links; mechanics not yet built are listed as such.
  Hand-written page wording is partly checked against code.

## Known issues and limits

- Android is signed with a throwaway key (the stable test-key secrets do not exist yet): uninstall the
  previous build first; uninstalling deletes that phone's save. Older saves (before save version 14)
  are refused anyway: start a new game.
- Not checked on a real phone, a real controller, Windows hardware or a Steam Deck. Touch sprint has no
  control.
- Art limits: no sit, tool-swing, inner doorway, sawhorse, chimney or feather art in the purchased
  packs (stand-ins listed above).

## Install and launch

- Android: allow installs from unknown sources, uninstall any earlier My Medieval Life test build,
  open the APK.
- Windows: unzip the package, run `MyMedievalLife.exe` (unsigned: "More info" > "Run anyway").
- Linux / Steam Deck (desktop mode): unzip, `chmod +x MyMedievalLife.x86_64`, run it.
- Check files against `SHA256SUMS.txt` (the paths in it start with `release/`).
