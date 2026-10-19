# Build 12: complete development audit

This audit covers everything that changed between Build 11 (`c6661fa`) and Build 12 (`f8b4a98`). That is 71
commits, 181 files, and +17,284/−954 lines on `staging/my-medieval-life`. Build 12's packet commit
`8d5193a` adds only `BUILD_12_PACKET.md`.

It was written on 2026-10-19 from the Git history, the source code, `docs/DEVELOPMENT_LEDGER.md`, the
Interlocking Systems Manifest, and the test suites. It is a documentation task: no gameplay code was
changed, no build was started and no branch was merged.

Earlier agent and packet claims were checked against the code, not copied. Where the code disagrees with
a report, this document says so and follows the code.

## How to read this audit

Every finding carries one of four evidence levels:

| Mark | Evidence level | Meaning |
|---|---|---|
| **[G]** | Working gameplay | The feature was seen running in the game, either a screenshot of the running game that was looked at, or the Linux build launched and drawn. All of this was under a virtual display, not on hardware. |
| **[T]** | Automated test | A named headless test exercises it and passed on `f8b4a98`. CI run [39220899906](https://github.com/verbal76/My-Medieval-Life/actions/runs/39220899906) passed, and the packet records the local counts. |
| **[C]** | Code only | The code implements it, read in this audit, but no test or screenshot covers it. |
| **[D]** | Real device | It was checked on a phone, a controller, Windows hardware or a Steam Deck. **Nothing in Build 12 has [D].** |

Test counts come from the Build 12 packet and the CI log on `f8b4a98`. This audit did not re-run the
Godot suites.

**A pass proves less than it seems:**
- A passing test proves only what it asserts.
- Two assertions are always true, and are listed under the weak tests in section 16.
- The manifest validator (`tools/check_interactions.py`) proves that each cited function exists, not that it behaves as described.

## Contents

1. Summary
2. NPCs: behaviour, aging, relationships and families
3. Village, buildings, property, interiors and environment
4. Farming, livestock, crafting, professions and production chains
5. Trading, player businesses, NPC demand, inventory and economy
6. Combat, health, consumables, gathering and resources
7. UI, controls, settings, menus and accessibility
8. Player wiki
9. Interlocking Systems Manifest: INT-075 to INT-136
10. Save system
11. Platform builds, tests and hardware verification
12. Changes in the Git diff that are not in the ledger
13. Documentation that is now out of date
14. Build 12 versus Build 11
15. Everything still unfinished
16. Defects and weak tests found by this audit
17. Recommended priorities for Build 13
18. Appendix: task by task

---

## 1. Summary

### What Build 12 adds

Build 12 is the largest change since the prototype began. Ten systems that did not exist in Build 11 are now in the game:

- a calendar with aging, families and inheritance;
- player farming and livestock;
- player stalls and shops, with real villager demand;
- usable chests, locks and lockpicking;
- ten-level skill trees;
- medicines and an apothecary;
- expandable property;
- usable furniture;
- an in-game wiki;
- a rebuilt village.

### Quality

Most systems have dedicated headless suites, 15 Godot suites in all. The same five gaps run through every system:

- nothing was tried on real hardware;
- several pieces of art are stand-ins, because the purchased packs have no art for them;
- a handful of economy loopholes;
- one confirmed aging defect;
- documentation that has fallen behind the code.

### Verdict

- **Ready to keep testing privately:** yes.
- **Ready for a public test:** no, until hardware checks (section 11) and the high-priority defects in section 16 are done.

---

## 2. NPCs: behaviour, aging, relationships and families

Tasks: B8-029, B8-016, B8-020 (its NPC side), PL2-003, PL1-07, PL2-001, B8-007 (its villager side), PL1-09.

### 2.1 Calendar, aging and life stages (B8-029)

**What changed:**
- One world calendar: an 8-day year of four 2-day seasons. The owner approved it.
- The clock reads, for example, "Summer, Year 1  Day 3".
- Every villager, the player and every animal now has a birth time (`born`). Age is computed from `born` and the clock.

**How it works** (`game/scripts/core/life.gd`):

Stages:

| Stage | Age | Drawn at | Notes |
|---|---|---|---|
| Child | under 12 | half scale | |
| Adolescent | 12 to 16 | three-quarter scale | |
| Adult | 16 to 55 | full scale | |
| Elder | 55 and over | full scale | walks at 0.8x |

Starting ages:
- adults 17 to 50;
- elders 56 to 75;
- children 1 to 15;
- the player 18 to 20.

Every dawn, `Life.sync_roles` re-reads each villager's stage:
- An adult who turns 55 retires.
- A child who turns 16 becomes an adult without a trade, and enters the job market and apprenticeship.

**What the player sees:**
- Small children run about the village.
- An old smith slows down, and one morning a notice says "Edwin Smith grows old and retires."
- Over a few in-game years, children grow into workers.

**System connections:** INT-077 and INT-078. Age drives:
- jobs (children and elders have none);
- sprite scale and walk speed;
- succession (retiring opens a post);
- save data (only `born` is saved).

**Before and after:** Build 11 had no calendar, no ages and no growing up. The population was fixed until someone died.

**Status:** fully implemented.

**Evidence:**
- [T] `aging_test` (96 checks): calendar, coming of age, retiring, save and load.
- [T] `start_test::_child_size_tests`.
- [G] Screenshots of babies and children were looked at.

**Limitations:** see the retirement defect in 2.3.
- The calendar is fast: one year is 8 game days.
- Elders and children use the adult character sheet, scaled down. There are no child or elderly sheets.

### 2.2 Relationships, births, death and inheritance (B8-029)

**What changed:**
- Household membership is now separate from romance.
- Each person has explicit `mother`, `father`, `partner` and `children` links.

**How it works.** Each dawn:
- **Partnering:** each eligible unpartnered woman has about a 6.25% daily chance to pair with an unrelated man within 12 years of her age, if a free bed exists.
- **Births:** a partnered woman aged 18 to 42 has about a 6.25% daily chance of a birth, if the household has a free bed and food.
- **Death by old age:** from age 60 the daily chance is `0.1 × ((age − 60) / 20)²`. Death is certain at 80.
- **Inheritance order:**
  1. the eldest adult child;
  2. the partner;
  3. the parents;
  4. the siblings;
  5. a minor child;
  6. the old household fallback.
- **Player death:** the player's eldest child aged 16 or over becomes the new player character. With no such child, the earlier relative flow runs.
- **Player partnering:** the player can choose "Ask to be partners" with an adult villager. The partner keeps their own home.

**What the player sees:**
- A couple in the next house has a baby.
- An old miller dies, and his eldest son inherits the house and coins.
- If the player grows old and has a grown child, play continues as that child.

**System connections:** INT-079 and INT-080. These connect to:
- households and beds (births need a free bed);
- food (births need food);
- inheritance of coins, homes and property;
- employment (deaths open posts);
- the player's continuity.

**Before and after:** Build 11 had no births, partnering or old age. Heirs were "a relative".

**Status:** fully implemented.

**Evidence:**
- [T] `aging_test::test_start_population`, `::test_partners_and_births`, `::test_old_age_and_inheritance`, `::test_player`.
- [C] The "Ask to be partners" dialogue button (`game_ui.gd:1983`) is not driven by any test.

**Limitations:**
- No courtship or relationship state: partnering is a dawn roll, or one button for the player.
- The player's partner does not move in.

### 2.3 Succession of essential trades (B8-016, INT-075)

**What changed:** the death of a skilled worker now opens a saved vacancy. Skilled workers are the smith, carpenter, tanner, cook, tavernkeeper and merchant.

**How it works** (`npc_brain.gd:1868-1900`):
1. After 3 days, a jobless adult takes the post as an apprentice.
2. If nobody can, a newcomer arrives with the caravan, or at the latest after `newcomer_max_days` (10).
3. A newcomer brings 60 new coins, recorded in the coin ledger.

**What the player sees:** the smith dies. Three days later the notice reads "… apprenticed to the late Edwin Smith", and the forge works again.

**Before and after:** Build 11 lost the trade for good.

**Status:** implemented for death. **Defective for retirement.**

**Defect, verified in code:**
- `Life._set_role` (`life.gd:156`) calls `_open_vacancy(n)` *before* the retiree's job is cleared and before their role becomes "elder".
- `_open_vacancy` returns early when `living_in(job) + open_posts(job) >= staff_target(job)`.
- `living_in` still counts the retiree as a working adult.
- So when a trade is at full strength, which is the normal case, retirement opens **no** post.
- The village then quietly loses one smith, cook or merchant each time one turns 55.
- No test covers retirement followed by succession.
- The fix is one line: open the vacancy after clearing the job. That is a gameplay change, so it was not made here.

**Evidence:**
- [T] `world_test::_succession` covers death succession only.

### 2.4 Death causes (B8-020)

**What changed:**
- `damage_player(amount, source)` records the source of every hit, and `death_cause` at 0 HP.
- The death screen shows one of:
  - "You starved."
  - "Spoiled food made you fatally sick."
  - "You died of old age."
  - "Killed by Wat the guard."
  - "You died of your wounds." (no recorded cause)
- The cause is saved, and the heir starts clean.

**Status:** implemented.

**Evidence:**
- [T] `start_test::_b8_ui_tests`.
- [T] `run_tests::test_player_actions` (attacker name).
- [C] The spoiled-food text and the empty-cause fallback have no test.

**Limitations:** the game has no bleeding, falls or weather damage to report.

### 2.5 Dialogue text (PL2-003)

**What changed:**
- Rumour and buyer lines no longer run together.
- Sentences are closed and de-duplicated, possessives are correct ("James's"), and no internal ids leak.
- Choice buttons wrap.

**Evidence:** [T] `start_test` walks the dialogue of 60 or more villagers and checks for malformed text.

**Limitations:** only the `possessive` and `sentence` helpers have direct unit checks. Wrapping at phone resolution is not checked [D].

### 2.6 Station occupancy (PL2-001, INT-085)

**What changed:** `World.station_workers` counts a villager as using a station only when all of these are true:
- alive and awake;
- not fighting;
- the first step of their plan is that station's work;
- within 2.5 tiles of the use cell.

A reservation alone no longer blocks the player. The message names the real worker: "Alice Stone is using the forge".

**What the player sees:** the false "Alice Stone is using the forge" with nobody there is gone.

**Evidence:** [T] `world_test::_pl2_001`. It covers someone on the way, someone working, someone asleep, a task switch, a death, and a reload.

**Limitation:** villagers' own planner (`_station_for`) still counts reservations. So a villager already walking to a station can arrive while the player is using it, and a capacity-1 station can briefly hold two [C].

### 2.7 Villagers in beds and chairs (PL1-07, INT-095, INT-096)

**What changed:**
- Sleepers are drawn with the lying frame, centred on the bed.
- Villagers walk to a chair and eat seated for 15 minutes.
- A home with no chair eats standing.

**Status:** partial.
- Lying is right.
- Seated villagers use the standing frame cut off at the knees. There is no sit art in any pack.

**Evidence:**
- [T] `furniture_test`.
- [G] The sleeping screenshot was looked at.

### 2.8 Villagers show their tool (B8-007, INT-112)

**What changed:** on a work step, villagers play the swing frames with the pickaxe, axe or hammer icon held, instead of the staff swing.

**Status:** partial. It is an icon overlay on the throw frames, because no real tool-swing sheets exist.

**Evidence:**
- [T] `run_tests::test_polish_work_looks`.
- Note: `BUILD_8_MASTER_FIXES.md` still says villagers show the staff. That is out of date.

### 2.9 Employer's gold star (PL1-09, INT-084)

**What changed:** a gold star hovers over each villager who gave the player a job that has not yet been paid for. The reeve counts too, for manor jobs.
- It is keyed by NPC id, so it survives saves.
- It follows the NPC, and hangs at the door when they are indoors.
- It clears on payment, on dropping the job, or when the job lapses.

**What the player sees:** accept the smith's eight-iron job and the star follows him until you deliver and are paid.

**Evidence:**
- [T] `health_jobs_test::test_star`.
- [G] Screenshot looked at.
- **This suite is not run in CI** (section 16).
- [C] The drawing code in `main._sync_stars` is untested.

---

## 3. Village, buildings, property, interiors and environment

Tasks:
- Build 8: B8-002, B8-003, B8-004, B8-005, B8-008, B8-015, B8-017, B8-018, B8-025, B8-026, B8-028.
- Punch list 1: PL1-06, PL1-12, PL1-13.
- Punch list 2: PL2-006, PL2-007, PL2-008, PL2-010, PL2-011, PL2-013, PL2-014.
- Plus the built-room floor fix.

### 3.1 One coherent village (B8-002, B8-003, B8-017, B8-028)

**What changed:** the village is no longer Shade's sample maps pasted as districts.

`tools/build_village.py` now lays it out as one place, on continuous terrain, from the purchased building art. The generator is now version 6, which bumped the save to version 13.

The new village holds:

| Feature | Count |
|---|---|
| Buildings | 26, including a named Sawmill (b25) |
| Stations | 10 |
| Trees (Living Forest records only, no tree tiles) | 226 |
| Ore deposits | 14 |
| Boulders | 18 |
| Plants | 203 |
| Containers | 135 |
| Market stalls | 6 |
| Fields | 6 |
| Pens | 4 |
| Survey plots | 2 |
| Building stamps | 7 |
| Road cells | 808 |

- Solid cells fell from 3,297 to 2,252, so the village is more open to walk through.
- Each household's chests stand in its own door yard (B8-017).
- The saw-planks recipe moved from an unlabelled sawhorse to the Sawmill (B8-028).

**Built-room floors (commit `f8b4a98`, no task ID):**
- The house stamp export now skips the ground layer.
- Bare interior cells are filled with the stamp's most common floor tile.
- So the kitchen and other rooms no longer show grass.
- [T] `tests/test_village.py::test_built_rooms_have_floors`.

**Evidence:**
- [T] `run_tests::test_village_layout`.
- [T] Python `test_village`.
- [G] Village screenshots looked at, and the Linux build drew the village.

**Limitations:**
- No test covers the seam where the village edge meets the overworld.
- "Walk every road and building" is still a manual playtest.
- The original B8-017 fault could not be reproduced from the Build 11 code. The fix is the relocation.

### 3.2 Mine and quarry hill (B8-004, INT-111)

**What changed:**
- One cart track from the adit to the cart stop, with every seam reachable.
- The hill top is bare rock with ledges from Shade's tiles.
- No tree stands within 2 cells of the hill.

**Evidence:**
- [T] `run_tests::test_village_layout`.
- [G] Screenshot looked at.

The ledger says VERIFIED. `BUILD_8_MASTER_FIXES.md` still says PARTIAL; the code agrees with the ledger.

### 3.3 Trees, deposits and boulders (B8-005, B8-008, B8-026, PL1-06, INT-076, INT-087)

**Trees (B8-005):**
- No fault was found.
- Checks were added for:
  - collision on the trunk only;
  - the canopy fading;
  - harvesting while faded;
  - one sprite per tree across chunks.

**Deposits (B8-008):**
- The ore now comes from each deposit's own tile (`resources.json` `deposit_tiles`).
- So a seam always looks like its ore.

**Boulders (PL1-06):**

| Size | Share | Uses |
|---|---|---|
| Small | 55% | 2 |
| Large | 45% | 6 |

- Both sizes exist in the village and the overworld.
- They are saved, and a broken boulder disappears along with its collision.

**What the player sees:** a large boulder takes six pickaxe swings and gives six stone; a small one takes two.

**Evidence:**
- [T] `world_test::_deposits`, `::_boulders`.
- [T] `check_resources.py`.
- [G] Screenshot looked at.

**Out-of-date docs:** INT-076, `BUILD_8_MASTER_FIXES.md` (B8-026) and some comments still say "3 uses".

### 3.4 Flowers and harvesting everywhere (PL2-006, PL1-12)

**What changed:**
- Every overworld flower is pickable, regrows after `plant_regrow_days`, and is saved.
- The low red flowering plant (tile 2656) is now a plant node.

**Status:** PL2-006 implemented. **PL1-12 partial:**
- The red plant exists only in the village.
- The overworld generator never draws it.
- So "every instance" is true only because the overworld has no instances.

**Evidence:**
- [T] `world_test::_pl2_006`.
- [G] Screenshots looked at.

### 3.5 No interaction through walls (PL2-011, INT-088)

**What changed:**
- `World.reaches` blocks use, tap, gather and attacks across a wall, in both directions.
- The exception is when one end stands in the doorway.

**What the player sees:** from inside a house you can no longer chop the tree outside the wall.

**Evidence:** [T] `world_test::_pl2_011`.

### 3.6 Fields that ripen (PL2-007, INT-089)

**What changed:**
- The growth cycle already worked, but farmers cut a field within the hour, so it never looked ripe.
- A field now stands ripe for 12 hours before the farmers cut it.

**Evidence:**
- [T] `world_test::_pl2_007`.
- [G] Screenshots of ripe fields looked at.

### 3.7 Expandable property and modular buildings (PL2-008, PL2-014, INT-090 to INT-094)

**What changed:** the player can add rooms to a building they own. There are 8 kinds:
- workshop
- smithy
- kitchen
- bakery
- apothecary
- storage
- living quarters
- the first building itself

**How it works:**
- Each room is a parcel on the same estate.
- It must share at least 3 wall cells with the existing building and keep its doors clear.
- It pays construction cost and rent like any building.
- The first parcel cannot be sold while rooms stand.
- A finished room gets its stamp's stations, doors and roof.
- Beds in living quarters count for the household.

**What the player sees:** build a cottage, then later add a smithy against its east wall. The anvil inside works like the village smith's.

**Status:** partial.
- Rooms join wall to wall, but each has its own street door. There are no inner doorways, because no wall-opening art exists.
- The two survey plots are tight: there is room for about one added room.
- NPC households never add rooms.

**Evidence:**
- [T] `property_test` (62 checks).
- [G] Screenshot looked at.

### 3.8 Usable furniture (PL2-013, INT-097 to INT-099)

**What changed:** in the player's home:
- **Sit:** chairs (stool tile 1003). You are drawn seated until any input.
- **Sleep:** lie in your own bed. The night passes and you wake beside it; B or Esc wakes you early.
- **Hearth:** works as an oven.
- **Food table:** a preparation station, distinct from cooking.

Home stations use ids like `home:…` and are limited to the home household.

**Status:** partial. Sitting uses the knee-cut standing frame, which reads poorly.

**Evidence:**
- [T] `furniture_test`.
- [G] Bed screenshot looked at.

### 3.9 Station art: stove and sawhorse (PL1-13, PL2-010)

**Stove:**
- A coal-bed hearth with a pot.
- The prompt reads "Use Stove" and the window "Stove — Cooking & Tonics".
- No chimney, because the wall row sits above it.

**Sawhorse:** a trestle bench with logs, made from Shade tiles. No angled-trestle or saw art exists.

**Status:** both partial.

**Evidence:**
- [G] Screenshots looked at.
- [T] Tests check collision and use cells only.

### 3.10 Roofs, tabletops, weapon racks (B8-018, B8-025, B8-015)

- **Roofs (B8-018):** a map redraw no longer snaps a lifted roof back to full opacity.
- **Tabletops (B8-025):** overlay tiles on solid cells are now y-sorted with characters, checked from all four sides.
- **Weapon racks (B8-015):** decorative and solid, with nothing to take.

**Evidence:**
- [T] Covered by `run_tests` checks.
- [G] Roof behaviour inside every building is still a manual playtest item.

---

## 4. Farming, livestock, crafting, professions and production chains

Tasks: PL2-015, PL2-004, PL2-005, PL1-04 (brewing), PL1-10 (production chains, deferred), B8-016 (professions).

### 4.1 Player farming (PL2-015, INT-121 to INT-125, INT-130)

**What changed:** the player can farm any land they hold, in any shape.

**How it works** (`game/scripts/core/farming.gd`):

**Clearing:**
- Stumps, saplings, plants and boulders on your own parcel can be cleared for good.
- A stump takes 4 s and 20 stamina with an axe.

**Tilling:**

| Method | Time per cell | Stamina per cell |
|---|---|---|
| By hand | 7 s | 80 |
| Craftable hand plough | 2.5 s | 25 |

The plough wears down.

**Crops:**

| Crop | Days to ripe | Yield |
|---|---|---|
| Wheat | 2 | 3 + 1 seed back |
| Carrot | 1.5 | 3 + 1 seed back |
| Potato | 2.5 | 3 + 1 seed back |
| Herb | 1 | 2 + 1 seed back |

Seasonal growth rate:

| Season | Rate |
|---|---|
| Spring | 1 |
| Summer | 1 |
| Autumn | 0.5 |
| Winter | 0 (sowing refused) |

**Seed:**
- 2 coins each from a farmer or the food merchant.
- It is a standing offer, created on purchase, not taken from the seller's stock.

**Building over a field:** the field is given up. This is refused if a pen stands there.

**What the player sees:**
1. Buy a 2-coin wheat seed.
2. Till four cells by hand. That takes most of a full stamina bar each.
3. Sow in spring.
4. Two days later, cut 3 wheat per cell and keep a seed back.

**Before and after:** Build 11 had no player farming.

**Status:** partial. Deferred:
- coops and shelters;
- hired farm help;
- draught animals (none exist in the art);
- trapping;
- a water need;
- a Farming skill.

All four crops share the wheat field art.

**Evidence:**
- [T] `farming_test` (124 checks): `test_land_and_clearing`, `test_tilling`, `test_crops`, `test_save`.
- [G] Screenshots looked at.

### 4.2 Livestock (PL2-015, INT-126 to INT-129, INT-081)

**What changed:**
- The player can fence a pen on land they hold, paid in planks.
- They can buy animals from the manor pens.
- Well-fed adults produce goods each morning, kept up to a cap until collected.

Animal prices:

| Animal | Price (coins) | Product |
|---|---|---|
| Chicken | 8 | 1 egg a day (hens) |
| Sheep | 20 | wool every 4 days |
| Pig | 18 | — |
| Cow | 40 | 2 milk a day |

- Buying moves a real animal from the keeper's pen. The keeper's pen never drops below breeding stock.
- Player pens follow the village's feeding and breeding rules.

**Animal life cycles (B8-029):**
- Stages: newborn, juvenile, adult, elderly.
- Only adults breed. Breeding slows once a pen is more than half full.
- Elderly animals move at 0.7x and die of old age.
- Baby sprites come from Cozy Farm for every species except the boar.

**Evidence:**
- [T] `farming_test::test_pens_and_animals`.
- [T] `aging_test::test_animals`, `::test_baby_art`.
- [G] Baby animal screenshots looked at.

**Limitations:**
- Villagers buy eggs, milk and wool but never consume them, so they are a coin outlet, not a modelled need.
- There is no baby boar.

### 4.3 Crafting and new recipes (INT-103, INT-107, INT-114, INT-129, INT-099)

**New items:**
- rabbit pelt, feather
- lockpick, padlock
- four medicines
- hand plough
- four seeds
- carrot, potato, egg, milk, cheese, wool, wool cloth

**New recipes:**

| Station | Recipes |
|---|---|
| Anvil | `forge_lockpicks` (1 iron bar → 3), `forge_padlock` (2 bars) |
| Tannery | `tan_pelts` (2 pelts → 1 leather) |
| Preparation table | `knead_flatbread`, `press_cheese`, `bake_egg_bread` |
| Stove | `brew_poultice`, `brew_healing_tonic`, `brew_strong_tonic` |
| Workbench / loom | `craft_plough`, `weave_cloth`, `sew_bandages` |

**What the player sees:** shear wool, weave cloth, sew bandages. This closes the "bandages are not craftable: no cloth" gap the ledger notes for PL1-04.

**Limitations, verified in code:**
- **The village has no preparation station.** The prep recipes (flatbread, cheese, egg bread) can only be made at a preparation table in the player's own home. Villagers never make them.
- **Nobody sells the plough.** The player must craft it.

**Evidence:**
- [T] `farming_test::test_market`. Its station check is always true (section 16), so it does not prove a station exists.
- [T] `chests_test::test_items`.
- [T] `run_tests::test_polish_game_leftovers`.

### 4.4 Skills (PL2-005, INT-105 to INT-109)

**What changed:**
- Skills now run from level 1 to 10.
- The XP needed for each level is `100·L·(1 + 0.25(L−1))`.
- The cumulative totals for levels 2 to 10 are 100, 350, 800, 1,500, 2,500, 3,850, 5,600, 7,800 and 10,500.
- Every perk listed is read by game code:
  - **Gathering:** bonus ore or logs, faster swings, less tool wear.
  - **Crafting:** faster work, a chance of returned materials, a chance of an extra unit.
  - **Combat and magic:** damage and speed.
  - **Trading:** prices shift by up to 20%.
  - **Stealth:** pickpocket chance and how far a guard hears a caught attempt.
- Trading XP is now `2 + coins/5`, capped at 30, per transaction.

**Save effect:**
- Raw XP survives, but the level is recomputed on the new curve.
- So an old character can drop a level. The pickpocket chance is lower than Build 11 at the same level.

**Evidence:**
- [T] `skills_test` (`test_curve`, `test_outcomes`, `test_effects_are_wired`, `test_saves`).
- [G] Skills window looked at.

### 4.5 Professions and production chains

**Professions:**
- The sage is now the Apothecary. They buy flowers, brew poultices and sell medicines (section 6.2).
- The smith also forges lockpicks and padlocks.
- The tanner buys pelts.
- Succession keeps the skilled trades staffed (section 2.3).

**Production chains:** workers crafting from a player shop's stock are **deferred** (PL1-10 stage 4b). No code exists for it.

---

## 5. Trading, player businesses, NPC demand, inventory and economy

Tasks: PL1-03, PL2-012, PL1-10 (stages 1 to 4), PL1-08 (in the trade window), PL2-004 (loot).

### 5.1 Merchant quantity control (PL1-03)

**What changed:**
- Buy and Sell open a shared "how many?" control (`QuantityPicker`) with a slider, −/+, Max, a live total, Confirm and Cancel.
- Build 11 moved one unit per click.

**How it works:**
- **Buy limit:** `min(stock, coins ÷ price)`.
- **Sell limit:** `min(owned, the merchant's wants, merchant coins ÷ price)`.
- **Buying** is one all-or-nothing trade.
- **Selling:**
  - Prechecks every limit.
  - Then sells one unit at a time.
  - A piece recognised as stolen stops the sale at that unit.

**What the player sees:** with 17 coins, coal at 2 each, Max picks 8 and the total line reads "Total: 16 coins (you will have 1 coins)".

**Evidence:**
- [T] `start_test::_pl_trade_ui_tests`: limits, clamping, Cancel, a poor buyer, coin conservation.
- [G] Screenshot looked at.
- [C] Touch and controller input: code only.

**Limitations [C]:**
- **The price is quoted once, when the picker opens.**
  - Merchants' buy price falls as their stock rises.
  - But the whole stack is paid at the opening price.
  - Selling 20 ore therefore pays the top price on all 20.
  - There is no buy-back arbitrage, because buy and sell margins differ.
- **The player can sell until a merchant's purse is empty.** The `trader_cash_floor` of 15 that villagers respect does not apply to the player. Build 11 had the same gap one unit at a time.
- A partial sale that ends in a guard stop writes two messages, and the first is overwritten.

### 5.2 Storage quantities and controller focus (PL2-012)

**What changed:**
- Store and take use the same picker, plus Store all and Take all.
- Store all moves everything except what is worn or held.
- Focus stays on the item, or moves to the next one, never back to the top.
- Stolen marks travel with the goods.

**Evidence:** [T] `start_test::_pl_trade_ui_tests`. Touch skips focus by design.

### 5.3 Player businesses (PL1-10, stages 1 to 4, INT-116 to INT-120, INT-131 to INT-136)

**Stage 1: a market pitch**

The manor keeps two open pitches.

- **Renting:** 5 coins a day. The first day is paid on renting, to the treasury.
- **Rent falling due:** each morning rent is taken, from the purse first and then the till.
- **Unpaid rent:** selling stops, and after 2 mornings the manor takes the pitch back. Goods and the till return to the pack, and anything that does not fit is left at the stall.
- **Listing:**
  - up to 12 kinds;
  - prices from 1 coin to 4× value;
  - stolen goods cannot be listed.
- **Selling:** sales happen only while the player is within 7 tiles, or an attendant is at the counter.

**Stage 2: real villager demand**

Every game hour, up to 3 idle adults within 100 tiles are sent to a stocked stall. Each buys only for a modelled need:
- a trade's stock below half its cap;
- a missing pickaxe or axe, or a guard's gear;
- materials an open building site needs;
- logs or food for the household pantry.

Rules on each purchase:
- **Price ceiling:** the cheapest local price, or 1.8× value if nobody sells it, plus 10% per urgency level.
- **Cash floor:** buyers keep 15 coins if they are a trader, otherwise 2.
- **Quantity:** at most 6 per visit.
- **Rechecks:** everything is checked again on arrival.

Merchants and children never shop. The player earns 2 trading XP only for sales made in person.

**Stage 3: larger stall and shops**

*Larger stall:*
- 40 coins once, then 9 a day.
- 24 kinds.
- One display item that widens the walk reach 1.5×.
- The display draws no sprite, and the 40 is not refunded on closing.

*Shop in your own room* (`fitting.gd`):
- Place equipment on free floor cells. Reachability is checked by a breadth-first search, and materials come from the pack:
  - counter;
  - shelves (up to 3);
  - stock chest (up to 2);
  - oven;
  - stove;
  - workbench;
  - forge;
  - anvil.
- **Licence:** a counter plus "Open a shop" costs 4 coins a day.
- **Capacity:** 8 kinds, plus 8 per shelf. Each stock chest holds 60 spare pieces and refills a sold-out shelf with up to 6.
- **Shop type:** the equipment sets it. Forge and anvil make a smithy, oven a bakery, workbench a carpenter's, stove a kitchen, otherwise a general store.
- **Stations:** placed stations work as real stations. Villagers may not use them.

**Stage 4: attendants**
- Hire a jobless adult for 8 coins a day, paid from the till and then the purse.
- They stand at the counter from 7:00 to 18:00.
- They sell while you are away, with no trading XP.
- If neither the till nor the purse can pay, they leave.

**What the player sees:**
1. Rent a pitch for 5 coins and list 6 planks at 4 each.
2. A carpenter with an open building site walks over and buys them with his own coins.
3. Later, build a room, fit a counter, two shelves and an oven, and open a bakery.
4. Hire Tom to mind it while you are away.

**Economy:** coins are conserved through rent, licence, the upgrade (treasury), wages (NPCs) and sales (till). `business_test` checks `total_coins()` at each step.

**Before and after:** Build 11 had no player business.

**Status:** stages 1 to 4 implemented. Deferred:
- production chains;
- the display sprite;
- shops in rented village houses;
- night hours;
- villagers entering by the door (they walk to the counter).

**Evidence:**
- [T] `business_test` (153 checks).
- [G] Screenshots looked at.

**Defect [C]: attendant double-booking.**
- `Construction.can_hire` (`construction.gd:248`) does not check whether a villager is already an attendant.
- So the player's helper hire, or an NPC builder, can take the attendant for the day.
- Their plan runs first, so the counter stands empty while the wage is still paid.

### 5.4 Consumable effects (PL1-08)

**What changed:** `GameData.effect_text` builds lines such as "Restores 12 Health / 4 Food" from item data. They appear in the trade rows, the picker and the pack.

**Status: partial (defect verified in code).**
- `GameData.effects` (`game_data.gd:49`) returns nothing for an item without a `food` field.
- The four medicines have `heal` but no `food`.
- So bandages, poultices and tonics show **no** effect text in the shop or the pack, which is where it matters most.
- The test loops only over items with `food`, so it passes anyway.

**Evidence:**
- [T] Food items only.
- [C] Medicines: the gap above.

### 5.5 Animal loot (PL2-004, INT-086, INT-113, INT-114)

**What changed:**
- A hunted animal leaves a visible pile with its item icon. Tap it to take the contents.
- Piles spoil after 3 days.
- Adult rabbits drop a pelt, adult chickens 2 feathers; young animals drop neither.
- `tan_pelts` turns 2 pelts into 1 leather. The tanner and the goods merchant buy pelts.
- No coins from wild animals.

**Evidence:**
- [T] `world_test::_pl2_004`.
- [T] `run_tests::test_polish_game_leftovers`.

**Limitation:** the feather icon is a stand-in (a leaf); there is no feather art.

### 5.6 Economy risks found in this audit

| Risk | Where | Effect | Evidence |
|---|---|---|---|
| Player drains a trader's purse | `quantity_picker.gd:36`, `world.gd:1968` | Merchants left with 0 coins cannot restock or pay | [C] |
| Bulk price fixed at open | `game_ui.gd` `_trade_picker` | Top price paid for every unit up to the cap | [C] |
| Seed made from nothing | `farming.gd:570-583` | Goods inflation: 2-coin seed returns about 3 wheat plus seed; herb seeds make flowers, which the sage turns into medicine | [C] |
| Bulk theft is one crime | `chests.gd:193-213` | A pantry can be emptied in one action for at most one fine; a guard who sees it does recover everything | [C] |
| Attendant double-booking | `construction.gd:248` | Counter empty while the wage is paid | [C] |

---

## 6. Combat, health, consumables, gathering and resources

Tasks: PL1-04, PL1-05, PL2-002, B8-006, B8-009, B8-010, B8-011, B8-014, B8-019, B8-027.

### 6.1 Health recovery and medicines (PL1-04, INT-083)

**What changed:** four medicines:

| Medicine | Heals | Value |
|---|---|---|
| Linen bandage | 15 HP | 3 |
| Herbal poultice | 30 HP | 6 |
| Healing tonic | 50 HP | 12 |
| Strong healing tonic | 80 HP | 22 |

- Use them from the pack.
- They heal only, never above maximum, and are consumed only when you are hurt.
- New characters start with 2 bandages.
- Resting is unchanged: full HP and stamina.

**How the Apothecary works:**
- The sage starts with 6 bandages, 4 poultices, 3 tonics and 2 strong tonics.
- They buy flowers and brew poultices at the stove.
- Each caravan visit sells them up to 4 more pieces, from the sage's own coins. So supply is finite.

**What the player sees:** at 40 HP, using a poultice shows "You use the herbal poultice and feel better (health 70)."

**Evidence:**
- [T] `health_jobs_test` (37 checks).
- [G] Screenshot looked at.
- **This suite is not run in CI.** `test_apothecary` has an assertion that is always true (section 16).

### 6.2 HUD bars (B8-019, PL1-05)

**What changed:**
- Health, food and stamina bars show their value as current/max inside the bar ("9/100"), in high-contrast text with an outline.
- Each bar has a label. The food icon is now bread; it used to be a cannon.
- A bar blinks red below 25%.

**Evidence:**
- [T] Tests cover the values.
- [G] Screenshot looked at.
- Not checked on a phone or Steam Deck.

### 6.3 Harvesting and actions (B8-006, B8-010, B8-011, B8-014, B8-009)

**One cycle (B8-006):**
- A Use is one cycle, then idle with the tool put away.
- Gather mode continues until one of these happens:
  - the resource runs out;
  - the pack is full;
  - the tool is gone;
  - you are hurt.

**The Pack mid-action (B8-010):**
- Opening the Pack or any window cancels the action.
- Nothing is awarded and no tool wear is taken.

**Cancel (B8-011):** B, Esc, right-click or a tap cancels at once.

**Target choice (B8-014):**
- When several things are in reach (a person and a station, say), Q, Tab or the D-pad cycles them.
- The prompt shows the next choice and its position.
- A theft is never the default: labels containing "theft" sort last.

**Collection notices (B8-009):** a compact line with an icon, such as "[icon] +1 Iron ore", for 1.5 s.

**Evidence:**
- [T] `start_test::_actions_tests`.
- [T] `start_test::_b8_ui_tests`.

**Limitation:** theft ordering is done by string match on the label text [C]. "Search X's belongings" is not labelled theft, so it is not demoted.

### 6.4 Sprint (B8-027)

**What changed:**
- LT toggles sprint on a pad (the owner's correction; L3 is unbound).
- Shift holds it on a keyboard, or toggles it if the setting is on.
- Sprint is 1.5× speed (4.5 → 6.75 tiles a second).
- It costs about 12 stamina a second net, and needs 12 to start.
- A full bar lasts about 8 seconds.
- It stops when you stand still, start an action, or attack.

**Evidence:** [T] `start_test::_actions_tests`.

**Not done:**
- **Touch has no sprint control.**
- The `balance.json` note still says "L3".
- Not checked with a real controller [D].

### 6.5 Chests, locks and lockpicking (PL2-002, INT-100 to INT-104)

**What changed:** every chest, crate and barrel now has an owner rule.

| Kind | Who | Rule |
|---|---|---|
| Own | Your family chest, and containers in buildings you hold | Free |
| Foreign | Other households' pantries, the tavern's and the manor's stock | Taking is theft; you cannot store |
| Decor | Chests in buildings nobody holds | Cannot be opened |

**Locks:**

| Container | Lock level |
|---|---|
| Crates and barrels | 0 (never locked) |
| Tavern | 2 |
| Manor | 3 |
| Household chests | about a third locked, at level 1 to 3 |

- A picked lock stays open until the next day.
- Your own padlock is level 2.

**Lockpicking:**

Chance = `0.5 + 0.1 × (Stealth − 1) − 0.15 × (lock − 1)`, kept between 0.1 and 0.9.

| Rule | Value |
|---|---|
| Time | 20 game minutes × lock level |
| A failure snaps the pick | 30% of the time |
| Every attempt | a crime on record |
| Witness radius | 10 tiles (5 for a quiet success) |
| Guard's fine | 10 coins |

Lockpicks and padlocks come from the anvil, and the smith stocks a few.

**What the player sees:**
- A level-2 lock at Stealth 1 shows "35% chance, about 40 minutes, 2 picks".
- If the pick fails: "The lock holds…"
- If anyone is in range: "2 people saw you!"

**Evidence:**
- [T] `chests_test` (68 checks).
- [G] Chest window screenshots looked at.
- [C] The window's Pick button and the timed action are untested. The random rolls are fixed in tests.

**Limitations [C]:**
- **Your own lock does nothing yet.** No villager steals from the player's chest.
- Bulk theft counts as one crime (section 5.6).
- What happens to a stash in a building the player later loses was not verified.

### 6.6 Combat

No new combat mechanics. The changes are:
- skill perks for damage and speed (INT-108);
- the attack-source record for the death cause;
- the no-attack-through-walls rule (INT-088).

The wiki has no combat or magic page.

---

## 7. UI, controls, settings, menus and accessibility

Tasks: PL1-01, PL1-02, PL1-05, PL1-08, B8-012, B8-013, B8-014, B8-027, PL2-012.

### 7.1 Settings freeze (PL1-01)

**Root cause:**
- `hide_all` only unpaused the game when it was already running.
- So leaving Settings > Controls (X) from the title screen left a grey, paused world with the HUD showing.

**Fix:**
- `go_back`, `panel_back` and `inner_back` keep a back stack.
- Back returns to whichever screen opened the window and restores pause and input.

**Evidence:**
- [T] `wiki_test` drives X, Esc and B from the title and pause menus.
- [D] Not run on hardware.

### 7.2 One tabbed Settings screen (PL1-02)

**What changed:**
- Settings now has five tabs: Audio, Display, Interface, Controls and Wiki.
- There is a Back button.
- Settings persist.

**Evidence:** [T] persistence test.

**Limitations [C]:**
- The last tab used is not remembered.
- There is no key rebinding.
- **Volume sliders do nothing: the game has no sounds.**

### 7.3 Inventory and prompt sizing (B8-012, B8-013)

- **Pack:** the tab row's focus ring and theme margins now fit their slots.
- **Prompts:** prompts and messages size to their text and sit above the touch buttons.

**Evidence:** [G] Screenshots looked at.

### 7.4 Controls

| Input | New in Build 12 | Gaps |
|---|---|---|
| Keyboard and mouse | Q / Tab choice, Shift sprint, Esc / right-click cancel | The on-screen control list omits H, P, J, K and others |
| Gamepad | LT sprint, D-pad choice, B cancel and back | No Journal or Build shortcut; B in a picker closes the whole window (chest, stall, trade), not just the picker |
| Touch | Tap to cancel, quantity picker | **No sprint**; nothing tested on a phone |

### 7.5 Stale player-facing text (verified in this audit)

- The stamina tooltip mentions only Fireball, but sprint now spends stamina too.
- The `_sprint_note` in `balance.json` says "L3"; it is LT.
- The origin screen says the player starts with "five coins"; they start with 20.

### 7.6 Accessibility

- **Contrast:** HUD numbers have an outline, and low values blink red.
- **Not added:**
  - text scaling;
  - a colour-blind mode;
  - rebinding;
  - an option to turn off the blinking.

---

## 8. Player wiki (PL2-009, INT-082)

### 8.1 What exists

**Where it opens:** Settings > Wiki, also reachable from the title and pause menus.

**Pages:** about 208 pages in 14 categories, counted in code. The ledger's "~150" is out of date.

| Category | Pages | Source |
|---|---|---|
| Guides ("How do I…?") | 18 | Hand-written |
| Tools | 5 | Generated from `items.json` |
| Gear | 11 | Generated |
| Food | 14 | Generated |
| Materials | 31 | Generated (the four medicines are filed here) |
| Recipes | 33 | Generated from `recipes.json` |
| Resources | 18 | Generated from `resources.json` |
| Stations | 11 | Generated |
| Skills | 9 | Generated from `skills.json` |
| Animals | 6 | Generated |
| Jobs | 14 | Generated from professions |
| Controls | 3 | Keyboard, pad, touch |
| Systems | 32 | Hand-written: needs, healing, theft and locks, trading, stalls and shops, property, farming, calendar, ageing, families, inheritance, the mine… |
| Not yet built | 3 | Mechanics planned but absent |

**Generated entry types:** item, recipe, resource node, station, skill, profession and animal pages.

Each generated page shows:
- an image;
- a description;
- uses;
- where to get it;
- links.

**Search:**
- Matches substrings.
- Handles plurals only by stripping a final "s".
- Shows at most 40 results.

**Cross-references:**
- Items link to the recipes that use or make them, and to stations and sources.
- Production chains show how an item is made.

**Evidence:**
- [T] `wiki_test`.
- [G] Pages looked at.
- [C] Ten sampled hand-written claims were checked against code, and all matched. The rest of the hand-written prose is not checked.

### 8.2 Gaps

- **Chains:** only the first recipe for an item is followed.
- **Medicines** are grouped under Materials, not Health or Food.
- **No pages for:**
  - combat and magic;
  - the gold star;
  - the journal and map;
  - death causes;
  - berries outside the village;
  - the caravan;
  - bandits.
- **Gold ore has no source anywhere in the game.** No deposit is placed, no merchant sells it and no recipe makes it. So gold bars and gold rings cannot be had either, and the wiki cannot say where to get them. This defect is older than Build 12: `resources.json` already records it as `no_source`. It is still open.
- **Hand-written pages are not generated.** They must be updated by hand when numbers change, and nothing tests them against `balance.json`.

---

## 9. Interlocking Systems Manifest: INT-075 to INT-136

**Count:** the manifest grew from INT-074 to INT-136, so **62 new entries**, not the 60 (INT-077 onward) the packet states. INT-075 (succession) and INT-076 (deposits and boulders) were added in this run too.

**Validation:**
- `tools/check_interactions.py` passes: 136 entries, 0 problems.
- A separate script confirmed that all 250 cited functions exist.
- That proves the citations are real, not that the behaviour matches.

**Blemishes:**
- INT-110 and INT-111 list `tools/build_village.py` twice.
- INT-076 still says boulders have 3 uses.

### By system

**NPCs, aging and families**

| INT | What it does |
|---|---|
| 075 | A dead skilled worker's post opens; an apprentice after 3 days, else a newcomer by caravan or 10 days |
| 077 | 8-day calendar; age computed from `born` |
| 078 | Age sets role, job, sprite size and walk speed; elders retire |
| 079 | Partners and births, needing a free bed and food; the player can ask a villager to be partners |
| 080 | Death of old age from 60; family-first inheritance; the player's grown child is the heir |
| 084 | Gold star over the unpaid employer |
| 085 | A station is blocked only by a villager actually working at it |
| 095 | Sleepers lie on beds |
| 096 | Villagers eat seated at home |
| 112 | Villagers show the right tool icon while working |

**World, village and environment**

| INT | What it does |
|---|---|
| 076 | A deposit is the ore its sprite shows; small boulders give stone |
| 087 | Overworld flowers and boulders are real, saved nodes |
| 088 | No targeting across a wall |
| 089 | Fields stand ripe for 12 h before farmers cut them |
| 110 | Interior floors drawn over grass |
| 111 | Mine hill is bare rock, with no trees on the rim |

**Gathering and resources**

| INT | What it does |
|---|---|
| 086 | Hunted animals leave a visible pile that spoils after 3 days |
| 106 | Gathering skill perks (bonus yield, speed, less wear) |
| 113 | Rabbit pelts and chicken feathers |
| 121 | Clearing held land for good |

**Farming and livestock**

| INT | What it does |
|---|---|
| 081 | Animal life stages, old age and baby art |
| 122 | Tilling by hand or with the plough |
| 123 | Crops grow hourly at a seasonal rate; no sowing in winter |
| 124 | Harvest gives yield plus seed |
| 125 | Seed bought for coins |
| 126 | Fenced player pen paid in planks |
| 127 | Buying livestock from the manor pens |
| 128 | Daily eggs, milk and wool |
| 129 | Farm goods sell and feed crafts |
| 130 | Building over a field ploughs it under |

**Crafting and skills**

| INT | What it does |
|---|---|
| 083 | Medicines and the sage's Apothecary |
| 099 | Home hearth as oven, table as prep station |
| 103 | Smith forges lockpicks and padlocks |
| 105 | One 10-level skill curve; raw XP kept on load |
| 107 | Crafting skill perks |
| 114 | Pelts tanned or sold |

**Trading and business**

| INT | What it does |
|---|---|
| 108 | Combat, magic and trading skill perks (prices ±20%) |
| 116 | Rent a market pitch |
| 117 | Stock moves between pack and stall; no stolen goods |
| 118 | Stall sells only while attended |
| 119 | Villagers buy only real needs |
| 120 | Daily rent and eviction |
| 131 | Larger stall |
| 134 | Shop sells from a counter |
| 135 | Hire an attendant |
| 136 | Attendant sells while you are away |

**Property and furniture**

| INT | What it does |
|---|---|
| 090 | Rooms join the estate |
| 091 | Room cost, rent and sale |
| 092 | Room stations, doors and roof |
| 093 | Living quarters and storerooms count as house rooms |
| 094 | Property saved whole |
| 097 | Player sits |
| 098 | Player sleeps in their own bed |
| 132 | Place equipment in a room |
| 133 | Stations follow equipment; the trade is named from it |

**Crime**

| INT | What it does |
|---|---|
| 100 | Chests have owners; taking others' goods is theft |
| 101 | Locks and lockpicking |
| 102 | Lockpicking seen by a witness is a crime |
| 109 | Stealth and pickpocketing |

**UI, wiki and saves**

| INT | What it does |
|---|---|
| 082 | Wiki generated from data; Settings returns to its source |
| 104 | Locks and stashes saved |
| 115 | The save carries a world identity (`meta`) |

---

## 10. Save system

**Version:**
- 12 in Build 11, 14 now.
  - Version 13 is the rebuilt village.
  - Version 14 adds the aging fields: `born`, `sex`, `mother`, `father`, `partner`, `children`.

**Compatibility (owner decision, 2026-10-19):**
- `SaveStore.MIN_VERSION` is 14, so **every Build 11 or older save is refused**.
- The refused file is renamed aside and kept, never overwritten.
- The game falls back to the `.bak` or a new game.
- This departs from CLAUDE.md §7's migration rule, by the owner's decision that old test saves are disposable.

**Added at version 14 without a bump** (old data loads with defaults):
- `vacancies`, `boulders`, `chests`, `farm`;
- overworld `rocks` and `flowers`;
- `player_pens`;
- stall business fields;
- building `fit`;
- shop records;
- the `meta` block (`save_id`, `created`, `saved_at`, `play_seconds`, `platform`, `character`).

**Migration limits:**
- The pre-13 migration code remains in `load_dict`, but nothing can reach it.
- No fixture save from an older version is tested. The refusal is tested with a synthetic file.
- Overworld rocks and tree changes are dropped if the overworld generator version changes.
- Skills keep raw XP but may drop a level.
- **Cloud saves (PL1-11):**
  - Stage 1 is done: one portable JSON with an identity block.
  - Stages 2 to 5 are **blocked**: Drive transfer needs a Google OAuth client the owner registers.

**Evidence:**
- [T] Round-trip tests in:
  - `run_tests`;
  - `start_test::_save_meta_tests` and `_save_safety_tests`;
  - `aging_test`;
  - `chests_test`;
  - `farming_test`;
  - `property_test`;
  - `business_test`;
  - `skills_test`.

---

## 11. Platform builds, tests and hardware verification

### The builds

| | Android | Windows | Linux |
|---|---|---|---|
| File | `MyMedievalLife-build12-android.apk` (64.6 MB) | `…-windows-x86_64.zip` (43.1 MB) | `…-linux-x86_64.zip` (33.4 MB) |
| sha256 | `80ce334e…b5a7` | `2bbf6f85…04f6` | `9f555a3f…a643` |
| Version | code 12, `0.1.12-test` | file version `0.1.12.0` | — |
| Signing | **Throwaway key** (stable test-key secrets absent) | Unsigned | — |
| Downloaded back, checksum matched | Yes | Yes | Yes |
| Launched | No | No | **Yes**, virtual display, village drawn, screenshot looked at |
| Real hardware [D] | No phone | No Windows PC | No Steam Deck |

**Release details:**
- All three were built from `f8b4a98` by release run [39221314511](https://github.com/verbal76/My-Medieval-Life/actions/runs/39221314511).
- They are in a private draft release.
- Builds 10 and 11 are untouched.

### Tests on `f8b4a98`

**Python and validators:**
- Python `unittest`: OK.
- `check_interactions.py`: 136 entries, 0 problems.
- `check_resources.py`: 18 nodes, 0 problems.

**Godot suites:**

| Suite | Count |
|---|---|
| `run_tests` | 3,511 checks |
| `start_test` | 450 steps |
| `play_test` | 37 |
| `tree_test` | 45 |
| `world_test` | 96 |
| `aging_test` | 96 |
| `wiki_test` | passed |
| `health_jobs_test` | 37 (run by hand) |
| `skills_test` | passed |
| `chests_test` | 68 |
| `property_test` | 62 |
| `business_test` | 153 |
| `furniture_test` | passed |
| `farming_test` | 124 |
| `overworld_test` | 101 |

All have 0 failures.

**Coverage gaps:**
- **`health_jobs_test` is not in `.github/workflows/tests.yml`.** CI never runs the medicine, apothecary and gold-star tests.
- `release.yml` runs only `run_tests` and `start_test`. It relies on the separate Tests workflow for the rest.

### Outstanding hardware verification

1. **Android phone:**
   - install, after uninstalling the earlier build (this deletes that save);
   - touch controls, the quantity picker and HUD text at phone size;
   - performance.
2. **Real gamepad:**
   - LT sprint;
   - D-pad target choice;
   - B as back and cancel;
   - focus in the chest, stall and trade windows.
3. **Windows hardware:** launch, SmartScreen, and the icon.
4. **Steam Deck:** HUD and prompt sizes, and the pad.
5. **The manual playtest list in `BUILD_8_MASTER_FIXES.md`:**
   - walk every road and building;
   - tool swings from east and west;
   - roofs in every building;
   - succession over several days.

---

## 12. Changes in the Git diff that are not in the ledger

| Change | Commit | Notes |
|---|---|---|
| Thefts offered last in the target list | `9eb5e7a` | Part of B8-014 in spirit; no INT entry, no named test |
| Quantity picker waits for `tree_entered` before taking focus | `cfef7f1` | Silences a logged error; follow-up to PL1-03 |
| Built rooms get floors | `f8b4a98` | Fixes the grass kitchen the ledger lists under PL1-13 |
| `check_resources.py` learns boulders, player fields and pens, home stations, deposit tiles | several | Validator only |
| 34 new art entries in `PROVENANCE.json` (none removed) | several | 19 Cozy Farm (baby animals, produce, seeds), 9 Shade icons (medicines, pelt, lockpick, padlock, plough, feather stand-in), 6 Kenney prompts, and a generated star marker. All packs were already credited in `credits.json` |
| CI suite list grown to 14 Godot suites | several | `health_jobs_test` missing |
| INT-075 and INT-076 | `4e68d45` and others | Not counted in the packet's "INT-077 to 136" |
| RTK token tool | — | Container only; nothing in the repository |

---

## 13. Documentation that is now out of date

| Document | What is out of date |
|---|---|
| `BUILD_8_MASTER_FIXES.md` | B8-004 marked PARTIAL (now done); B8-007 says villagers show the staff (they show the tool); B8-026 says 3 uses (now 2 and 6); B8-029 "In progress" (verified) |
| `BUILD_11_PUNCH_LIST_1.md`, `_2.md` | Every status column still says Not Started or Open; the ledger is the current record |
| `DEVELOPMENT_LEDGER.md` | Wiki "~150 pages" (about 208); PL1-13 still lists the grass kitchen (fixed in `f8b4a98`) |
| `BUILD_12_PACKET.md` | "INT-077 to INT-136" (075 to 136) |
| `SYSTEM_INTERACTION_MANIFEST.md` | INT-076 says 3 uses |
| `game/data/balance.json` `_sprint_note` | Says L3 (LT) |

---

## 14. Build 12 versus Build 11

| Feature | Build 11 | Build 12 |
|---|---|---|
| Village | Sample maps pasted as districts, grass in rooms | One laid-out village, 26 buildings, a Sawmill, floors everywhere |
| Mine | Flat plateau, gaps in track | Rock hill, one connected track |
| Calendar and age | None | 8-day year, four seasons, everyone ages |
| Families | Households only | Partners, parents, births, old-age death, family inheritance |
| Player continuity | A relative | Your grown child |
| Trade succession | Trade lost on death | Apprentice, else newcomer (death only; retirement defect) |
| Farming | Village fields only, never seen ripe | Player clearing, tilling, plough, 4 crops, seasons, seed saving; ripe village fields visible |
| Livestock | Village pens | Player pens, bought animals, eggs, milk, wool, baby animals, old age |
| Healing | Food and rest | Four medicines, 2 starting bandages, Apothecary |
| Skills | Short trees | Levels 1–10, every perk wired |
| Trading | One unit per click | Quantity picker, value-based XP |
| Player business | None | Pitch, larger stall, shop with equipment, attendants, real demand |
| Chests | Family chest only | Owner rules, locks, lockpicking, witnesses, fines |
| Property | One building per plot | Rooms added to an estate (separate doors) |
| Furniture | Decorative | Sit, sleep, home oven, prep table |
| Stone and flowers | Some boulders, village flowers | All boulders by size; every flower pickable everywhere |
| Walls | Interactions passed through | Blocked |
| Settings | Separate screens, freeze bug | One tabbed screen with Back, no freeze |
| Help | Journal resource pages | In-game wiki, about 208 pages |
| HUD | Labels, food as a percentage | current/max in all three bars |
| Actions | Endless animation, no cancel | One cycle, cancel by any input, target choice, sprint |
| Saves | Version 12 | Version 14 with identity block; older saves refused and kept |
| Manifest | INT-001 to 074 | INT-001 to 136 |

---

## 15. Everything still unfinished

**Blocked on the owner:**
- PL1-11 stages 2 to 5, Google Drive saves: need a Google OAuth client.
- Android signing secrets for a stable test key, so updates install over earlier builds.
- Persisting RTK in the environment setup script (container tooling, not the game).

**Blocked on art (none in the purchased packs):**
- sitting pose (PL1-07, PL2-013);
- tool-swing sheets (B8-007);
- inner doorways (PL2-008/014);
- chimney (PL1-13);
- sawhorse and saw (PL2-010);
- feather icon;
- crop-specific field art (PL2-015);
- child and elder sheets;
- baby boar;
- stall display sprite.

**Deferred features:**
- *Farming:* coops and shelters, hired farm help, draught animals, trapping, water, a Farming skill.
- *Business:* production chains in player shops, shops in rented village houses, night hours, customers entering by the door.
- *Locks:* NPC thieves (which would give the player's own lock a purpose).
- *Villages:* NPC households adding rooms.
- *Controls and settings:* touch sprint, key rebinding, sound (the volume sliders have nothing to control).
- *Wiki:* combat and magic, star, journal and map, death causes, caravan and bandits pages.

**Partial:**
- PL1-07, PL1-08 (medicines), PL1-10, PL1-12 (red plant not in the overworld), PL1-13.
- PL2-008, PL2-010, PL2-013, PL2-014, PL2-015.
- B8-007.

**Not verified on hardware:** everything (section 11).

---

## 16. Defects and weak tests found by this audit

| # | Severity | Defect | Location | Evidence |
|---|---|---|---|---|
| 1 | High | Retirement opens no post when a trade is at full strength; the village loses a skilled worker at every retirement | `life.gd:156` (vacancy opened before the job is cleared) | Verified in code |
| 2 | High | Gold ore (and so gold bars and rings) has no source anywhere; already recorded as `no_source` in `resources.json`, carried over from before Build 12 | `game/data/resources.json:621` | Verified |
| 3 | Medium | Medicines show no effect text in shops or the pack | `game_data.gd:49` | Verified in code |
| 4 | Medium | An attendant can be hired away for the day by a builder | `construction.gd:248` | Verified in code |
| 5 | Medium | `health_jobs_test` is not run in CI | `.github/workflows/tests.yml` | Verified |
| 6 | Medium | The player can drain a trader's purse to 0; bulk sale at the opening price | `quantity_picker.gd`, `world.gd:1968` | Code |
| 7 | Medium | Seeds are made from nothing (goods inflation) | `farming.gd:570` | Code |
| 8 | Medium | Bulk theft from a chest is one crime | `chests.gd:193` | Code |
| 9 | Low | The village has no prep station, so villagers never make cheese or egg bread; eggs, milk and wool have no villager consumer | data | Code |
| 10 | Low | B in a picker closes the whole window | `chest_window.gd`, `stall_window.gd`, `game_ui.gd` | Code |
| 11 | Low | Stale text: stamina tooltip, L3 note, "five coins" | UI and data | Verified |
| 12 | Low | Villagers' own planner still counts reservations, so a station can briefly hold two | `npc_brain.gd:896` | Code |
| 13 | Low | Medicines filed under Materials in the wiki | wiki | Verified |

**Weak tests (always true):**
- `health_jobs_test.gd:80`: `… or true, "the craft action runs"`.
- `run_tests.gd:99`: `… or true, "coins"`.
- `farming_test::test_market`: its station check cannot fail.

These pass whatever the code does. Fixing them means making the assertion real; if the code then fails, the code is fixed.

---

## 17. Recommended priorities for Build 13

**1. Correctness, small and safe:**
1. Retirement succession: open the vacancy after clearing the job, and add a test.
2. Make the three always-true assertions real, and add `health_jobs_test` to CI.
3. Medicine effect text (count `heal` without `food`).
4. Attendant check in `Construction.can_hire`.
5. A source for gold ore, or remove the item.

**2. Hardware verification before any public test:**
- an Android phone with a stable signing key (the owner adds the four secrets);
- a real gamepad;
- Windows hardware;
- a Steam Deck.

These are the only way to move items from [T] or [G] to [D].

**3. Economy balance (owner decisions first, since each changes gameplay):**
- whether player sales respect the traders' cash floor;
- whether bulk sales should re-price per unit;
- a finite seed supply;
- whether bulk theft is one crime.

**4. Close the farming loop:**
- a village preparation station;
- villagers who consume eggs, milk and wool.

**5. Controls and text:**
- touch sprint;
- B in a picker closes only the picker;
- fix the stale texts;
- Journal and Build shortcuts on the pad;
- a complete on-screen control list.

**6. Wiki:**
- move medicines to their own category;
- add the missing pages (combat, star, journal and map, death causes, caravan);
- follow every recipe in chains;
- a test comparing hand-written numbers with `balance.json`.

**7. Documentation:** bring the out-of-date documents in section 13 up to date.

**8. Art:**
- inner doorways, sitting pose, tool swings, red flower in the overworld;
- this needs owner-sourced art, or a decision to accept the stand-ins.

**9. Deferred features, as the owner directs:**
- production chains;
- NPC thieves;
- farm help and draught animals;
- Drive saves, once the OAuth client exists.

---

## 18. Appendix: task by task

Key:
- **Status:** Done, Partial, Blocked, Deferred, or Resolved earlier.
- **Evidence:** G = working gameplay seen, T = automated test, C = code only. No task has device verification (D).

### Build 8 master fix list

| ID | Item | Status | Evidence | Notes |
|---|---|---|---|---|
| B8-001 | (earlier fix) | Resolved earlier | — | — |
| B8-002 | Village pasted over terrain | Done | T, G | One laid-out village; seam with overworld untested |
| B8-003 | Floating trees | Done | T | Trees only as Living Forest records |
| B8-004 | Mining area | Done | T, G | Master list still says PARTIAL |
| B8-005 | Tree collision and fade | Done | T | No fault found; checks added |
| B8-006 | Harvest never stops | Done | T | One cycle, then idle |
| B8-007 | Wrong tool shown | Partial | T | Icon over throw frames; no swing art |
| B8-008 | Deposits misidentified | Done | T | Ore from the tile |
| B8-009 | Notices need icons | Done | T | |
| B8-010 | Inventory during harvest | Done | T | Window cancels, nothing awarded |
| B8-011 | No cancel | Done | T | B / Esc / right-click / tap |
| B8-012 | Oversized highlights | Done | G | |
| B8-013 | Oversized prompts | Done | G | |
| B8-014 | NPC blocks station | Done | T | Q / Tab / D-pad; theft last (string match) |
| B8-015 | Weapon racks | Done | T | Decorative |
| B8-016 | Trade succession | Partial | T | Death works; **retirement defect** (section 2.3) |
| B8-017 | Personal chests | Done | T | Original fault not reproducible from code |
| B8-018 | Roof flicker | Done | T | Every-building check is manual |
| B8-019 | HUD | Done | T, G | |
| B8-020 | Death cause | Done | T | Spoiled-food and fallback text untested |
| B8-025 | Tabletop clipping | Done | T | |
| B8-026 | Grey boulders | Done | T, G | Now 2 and 6 uses |
| B8-027 | Sprint | Done (touch absent) | T | LT / Shift; no touch control |
| B8-028 | Sawmill | Done | T, G | |
| B8-029 | Calendar, aging, families | Done | T, G | aging_test 96 |

### Build 11 punch list 1

| ID | Item | Status | Evidence | Notes |
|---|---|---|---|---|
| PL1-01 | Settings freeze | Done | T | Back stack |
| PL1-02 | Tabbed Settings | Done | T | Volume has no sound to control |
| PL1-03 | Trade quantity | Done | T, G | Price fixed at open; purse can be drained |
| PL1-04 | Healing and Apothecary | Done | T, G | Suite not in CI; one always-true check |
| PL1-05 | current/max in bars | Done | T, G | |
| PL1-06 | All stone minable | Done | T, G | |
| PL1-07 | NPCs in beds and chairs | Partial | T, G | No sit art |
| PL1-08 | Consumable effects | Partial | T | Medicines show no text |
| PL1-09 | Employer star | Done | T, G | Suite not in CI |
| PL1-10 | Player businesses | Partial (stages 1–4 done) | T, G | Production chains and display sprite deferred; attendant double-booking |
| PL1-11 | Cloud saves | Stage 1 done; 2–5 blocked | T | Needs owner's Google OAuth client |
| PL1-12 | Red flowering plant | Partial | T, G | Pickable in the village; not drawn in the overworld |
| PL1-13 | Stove | Partial | G | No chimney; grass kitchen fixed in `f8b4a98` |

### Build 11 punch list 2

| ID | Item | Status | Evidence | Notes |
|---|---|---|---|---|
| PL2-001 | Forge occupancy | Done | T | Villager planner still counts reservations |
| PL2-002 | Chests and locks | Done | T, G | Own lock has no use yet; bulk theft one crime |
| PL2-003 | Dialogue text | Done | T | |
| PL2-004 | Animal loot and leather | Done | T | Feather icon stand-in |
| PL2-005 | Skill trees | Done | T, G | Old saves may drop a level |
| PL2-006 | Harvest everywhere | Done | T, G | |
| PL2-007 | Fields ripen | Done | T, G | |
| PL2-008 | Expandable property | Partial | T, G | No inner doorways; tight plots |
| PL2-009 | Wiki | Done | T, G | About 208 pages; gaps in section 8.2 |
| PL2-010 | Sawhorse | Partial | G | No sawhorse or saw art |
| PL2-011 | No interaction through walls | Done | T | |
| PL2-012 | Storage UI | Done | T | |
| PL2-013 | Usable furniture | Partial | T, G | Seated pose poor |
| PL2-014 | Modular buildings | Partial | T, G | Shared with PL2-008 |
| PL2-015 | Farming and livestock | Partial | T, G | Coops, help, draught animals, trapping, water deferred; one crop art |

---

## Addendum: corrections and Build 13 follow-up (2026-10-19)

This audit describes Build 12 as built. Two of its findings were wrong or need qualifying:

- **Section 16, weak tests.** `farming_test::test_market`'s station check is **not** always true. It
  accepts a recipe's station when the village has one *or* it is a home station (`Furniture.STATION_OF`:
  hearth to oven, table to prep), so a recipe at a station that exists nowhere would fail it. Only the two
  `or true` assertions (`health_jobs_test.gd:80`, `run_tests.gd:99`) were genuinely always true.
- **Section 16, defect 2 (gold ore).** The defect predated Build 12; `resources.json` already recorded it as
  `no_source`.

Build 13 corrective work since this audit is recorded as B13-01 to B13-10 in
`docs/DEVELOPMENT_LEDGER.md`:
- the five defects in section 16 (retirement posts, gold seam, medicine text, attendant hiring, CI
  coverage and the `or true` checks);
- the owner's four economy rules (funds, per-unit pricing, seed stock, per-item theft), which address
  findings 6 to 8 of section 16;
- the stale text in section 7.5;
- the medicine wiki category;
- the out-of-date documents in section 13.

Everything else listed in sections 15 to 17 remains open.
