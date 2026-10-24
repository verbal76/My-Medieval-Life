# Build 22 mini-build backlog

Owner directive 2026-10-24 (Build 21 scope freeze, `docs/directives/2026-10-24_build21_scope_freeze.md` on staging): Build 21
was frozen at `c33d7c2` (plus the signing merge) and these items moved to a focused Build 22 mini-build, to finish before the
next expansion. **Build 22 is not started.** Requirement ids are those of the register (`docs/requirements/requirements.json`).

## 1. Deferred feature development

| Item | Register id | State when frozen | Recovery | Remaining work |
|---|---|---|---|---|
| Business desk and courier integration | GP-BUSINESS-DESK | Started, unfinished, untested: a new `game/scripts/core/business_desks.gd`, changes to `counters.gd`, `settlement/couriers.gd`, `wiki.gd`, `world.gd`, `main.gd`, `ui/game_ui.gd`, `game/data/village.json`, `tools/build_village.py` (133 lines added, 18 removed) | branch `wip/build22-business-desk`, commit `e25eec9` (on top of `c33d7c2`) | finish the desk and courier hand-off, write the desk test, regenerate the village, check G0 (generator change). Existing shopkeepers' buying and selling must keep working (it does in Build 21) |
| Merchandise previews on tables | GP-TABLE-ITEMS | Not started | none | **Owner clarification 2026-10-24:** tables are not item-pickup containers; they show a visual preview of what the business offers, with no transaction. Do not build a pickup mechanic |
| Farmers tending their fields | GP-FARMER-TENDING | Not started | none | a visual animation of farmers working through their fields; likely changes G0, so follow the baseline policy (evidence first, keep the old baseline) |
| Lockpicking minigame | GP-LOCKPICK | Not started | none | the approved minigame and its tests |
| Children of player-to-player marriages | MP-PLAYER-FAMILY | Deferred under the owner's minimal-fix stop rule (`docs/directives/2026-10-24_mp_player_family_minimal_fix.md`): households hold villagers only, a married player couple has no household, and adoption records no parents, so it needs a data-model change | none (recorded in `docs/DECISIONS.md`) | player marriage and couple-household records; correct parent-child links; adoption records with both spouses as adoptive parents; male and female player spouses have biological children under the existing rules, same-sex couples only adopt (owner decision `docs/directives/2026-10-24_owner_decision_player_marriage_children.md`); a save migration from save version 22; simulation integrity (G0) and regression tests for the five cases: male/female birth, no same-sex birth, adoption records both spouses, save/load keeps the links, single-player unchanged |

## 2. Existing known defects (found before or during Build 21, not fixed)

- Villagers spent about 2 NPC-hours on solid cells in the flight-recorder playtest probe (seen, not investigated).
- After loading a save the loader fills 72 to 77 keys that the save lacks (minor, known; nothing is lost).
- The 35-poultice gift repeat reported in Build 20 could not be reproduced (the gift now asks how many, starting at one).
- Audio files are re-encoded on import (noted in the Build 21 audit, not a playtest defect).

## 3. Validation still required

- Real devices: the thumbstick, the smaller windows, the market shelves, the sharpening prompt, the parchment encyclopedia
  on a phone; the Craftpix and SMStudios credit links on Android and Windows.
- LAN play: a PC hosting and a phone joining, Windows Firewall (UDP 47810 and 47811 on private networks), the Android
  network permissions, automatic discovery.
- Android signing: that Build 22 installs over Build 21 and keeps the save (the first same-key update).
- The simulation warning thresholds are still proposals awaiting the owner.

## 4. Issues discovered during Build 21 playtesting

None recorded yet; add the owner's Build 21 playtest reports here.
