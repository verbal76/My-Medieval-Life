# Development ledger (run of 2026-10-19)

The owner's master development execution directive (2026-10-19) authorises an autonomous run through
Build 11 punch lists 1 and 2 and approved work, ending in a private Android, Windows and Linux build
packet from one verified revision. Specifications: `docs/release/BUILD_11_PUNCH_LIST_1.md`,
`docs/release/BUILD_11_PUNCH_LIST_2.md` and the B8 master list `docs/release/BUILD_8_MASTER_FIXES.md`.
World intent: `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` and `docs/DECISIONS.md`. Interactions:
`docs/SYSTEM_INTERACTION_MANIFEST.md` (the one manifest; updated with each change). Player wiki: in game,
Settings > Wiki (PL2-009).

Statuses: NOT STARTED, IN PROGRESS, PARTIALLY COMPLETED, BLOCKED, COMPLETED (implemented), VERIFIED
(passed its tests and, for visual items, screenshots looked at). Nothing is checked on a device here.

| ID | Task | Status | Branch / commit | Notes |
|---|---|---|---|---|
| B8-029 | Calendar, aging, families, animal life cycles | VERIFIED | staging (merge of `b8-aging`) | 8-day year; explicit partners and parents; save version 14; aging_test 96 checks; baby and child screenshots looked at. Kept existing animal grow/breed days (rabbit 2, cow 6) per the owner's "preserve existing maturation" |
| B8-004 | Mine hill look | VERIFIED | staging | Rock quarry hill from Shade tiles, trees kept off the rim (screenshot looked at) |
| B8-007 | Tool swing art | PARTIALLY COMPLETED | staging | Player and villagers swing with the right tool icon in hand (throw frames + overlay); real tool-swing sheets do not exist in the packs |
| PL1-01 | Settings > Controls exit freezes the game | VERIFIED | staging | Back now returns to the screen that opened the window; wiki_test drives X/Esc/B from title and pause |
| PL1-02 | One tabbed Settings screen with Back | VERIFIED | staging | Audio, Display, Interface, Controls, Wiki; settings persist (test) |
| PL2-009 | In-game player wiki | VERIFIED | staging | Settings > Wiki: 209 pages in 15 categories (Build 13 count) generated from items, recipes, resources, skills, professions, animals, stations, controls; guides, chains, search, links (wiki_test); pages looked at. Prose of hand-written pages partly checked against code. Each new feature adds pages |
| PL1-03 | Merchant buy/sell quantity control | VERIFIED | staging | Shared QuantityPicker; atomic; 17c/coal 2c -> 8 (start_test); screenshot looked at. Touch not run |
| PL2-012 | Storage quantity and controller navigation | VERIFIED | staging | Same picker, Store/Take all, focus kept and scrolled (start_test) |
| PL1-05 | current/max inside the bars | VERIFIED | staging | 9/100, 12/100, 32/100 with outline (screenshot); phone/Steam Deck not checked |
| PL1-08 | Consumable effects shown everywhere | VERIFIED | staging | From items.json fields; consumed only on success (start_test) |
| PL2-003 | Dialogue text and readability | VERIFIED | staging | Sentences closed and de-duplicated, possessives, no id leaks, wrapping choices (start_test over 60 villagers) |
| PL2-001 | Forge occupancy and stale reservations | VERIFIED | staging | Only a villager working at the station blocks it; never saved (world_test) |
| PL2-004 | Animal loot and the path to leather | VERIFIED | staging | Piles show their item, tap and take, spoil after 3 days; hides and rabbit pelts tan to leather; chickens drop feathers (trade good; icon is a stand-in leaf) |
| PL2-006 / PL1-12 | Resources harvestable everywhere; red flowering plant | VERIFIED | staging | Red plant is tile 2656, now a plant; every overworld flower pickable and saved (world_test, screenshots) |
| PL1-06 | Every stone object minable, size-based yield | VERIFIED | staging | Small (2 uses) and large (6 uses) boulders, overworld and village (world_test, screenshot) |
| PL2-011 | No interactions through walls | VERIFIED | staging | World.reaches guards targets, Use, Gather and attacks both ways (world_test) |
| PL2-007 | Fields grow, ripen and regrow | VERIFIED | staging | The cycle worked; farmers cut within the hour. They now wait 12 h, so ripe fields are seen (world_test, screenshots). Seasons hook in place |
| PL1-04 | Health recovery and Apothecary | VERIFIED | staging | Four medicines, two starting bandages, the sage as Apothecary with finite stock from brewing and caravans (health_jobs_test, screenshot). Bandages not craftable: no cloth in the game |
| PL1-09 | Gold star over the accepted job's employer | VERIFIED | staging | Keyed by NPC id, survives save/load, clears on payment (health_jobs_test, screenshot) |
| PL1-07 | NPCs sunk into beds and chairs | PARTIALLY COMPLETED | staging | Sleepers use the lying frame centred on the bed (looked at); seated villagers use the cut-off standing frame (no sit art) |
| PL2-013 | Usable furniture (sit, lie in bed, furnace, food table) | PARTIALLY COMPLETED | staging | Sitting, lying in bed and waking beside it, home oven and food table (furniture_test). Seated pose is the standing frame cut at the knees (no sit art), which reads poorly |
| PL1-13 | Recognisable stove | PARTIALLY COMPLETED | staging | Coal-bed hearth with pot, "Use Stove", "Stove — Cooking & Tonics"; no chimney (wall row above). The grass kitchen floor was fixed in `f8b4a98` (built rooms get floors) |
| PL2-010 | Recognisable sawhorse | PARTIALLY COMPLETED | staging | Trestle bench with logs from Shade tiles; no angled-trestle or saw art exists in the packs |
| PL2-002 | Usable chests, locks and lockpicking | VERIFIED | staging | Own/household/business/decorative rules, locks, lockpicks (Stealth), witnesses and fines (chests_test 68); chest window screenshots looked at |
| PL2-005 | Longer skill trees and pacing | VERIFIED | staging | Levels 1-10, every perk read by game code (skills_test), XP curve in BUILD_DECISIONS; skills window looked at |
| PL2-008 / PL2-014 | Expandable property, modular house and workshops | PARTIALLY COMPLETED | staging | A first building plus rooms added later (workshops, kitchen, apothecary, storage, quarters) with costs, rent and sale rules (property_test 62); screenshot looked at. Open: rooms are joined wall to wall with separate street doors (no inner doorways: no wall-opening art); the two survey plots have room for one module |
| PL2-015 | Farming, livestock and hand ploughing | PARTIALLY COMPLETED | staging | VERIFIED parts: clear and till held land in any shape by hand or with a craftable plough, wheat/carrots/potatoes/herbs on seasonal growth with seed saving, fenced player pens, bought stock, eggs/milk/wool and recipes (farming_test 124; screenshots looked at). Deferred: coops/shelters, hired help, draught animals (none exist), trapping, water need; all crops share the wheat field art |
| PL1-10 | Player businesses and real NPC demand (staged) | PARTIALLY COMPLETED | staging | Stages 1-4 VERIFIED: rentable pitch and larger stall, shops in your own rooms with placed equipment deciding the trade, stock chest back room, books, hired attendants who sell while you are away (business_test 153; screenshots looked at). Deferred: production chains (workers crafting from shop stock), display sprite, shops in rented village houses |
| PL1-11 | Google Drive cloud saves (staged) | PARTIALLY COMPLETED; stages 2-5 BLOCKED | staging | Stage 1 VERIFIED: saves are one platform-neutral JSON (user:// paths, world from its seed, versioned with SaveStore refusing older ones) and now carry a world id, times, play time, device and character for conflict checks (start_test). Blocked: Google OAuth needs a client registered by the owner in Google Cloud (consent screen, drive.appdata scope, Android and desktop client ids); without it no upload or download can be built or tested. Next once available: stage 2 manual upload/download |
| ENV-RTK | RTK token tool and its hook | VERIFIED (this container only) | — | Built from the official repository (`cargo install --git https://github.com/rtk-ai/rtk --tag v1.0.1 --locked rtk --root /root/.local`), `rtk init -g --auto-patch` added the Bash PreToolUse hook to `~/.claude/settings.json` (no earlier settings file, no hooks replaced); `rtk gain` shows commands routed. Persistence needs the owner: the environment setup script must run the same install and `rtk init -g --auto-patch` |
| B13-01 | Retirement opens no post in a fully staffed trade (audit defect 1) | VERIFIED | staging `3d922f1` | `_open_vacancy` leaves the leaver out of the staff count; aging_test retires a smith and an apprentice fills the post |
| B13-02 | Gold ore has no source (audit defect 2) | VERIFIED | staging `97aea61` | One gold seam (generator v7, 8 units, Mining 3 gate in `can_harvest`); older saves gain it on load; scarce by design (no caravan gold) (world_test::_gold, test_village, test_resources) |
| B13-03 | Medicines show no effect text (audit defect 3, PL1-08) | VERIFIED | staging `9fb459f` | `GameData.effects` reads heal without food (start_test) |
| B13-04 | Attendant hired away as a carrier (audit defect 4) | VERIFIED | staging `8ad0b15` | `Construction.can_hire` refuses attendants (business_test) |
| B13-05 | health_jobs_test not in CI; always-true checks (audit defect 5) | VERIFIED | staging `fe555e7` | Added to tests.yml; `or true` removed from health_jobs_test and run_tests. The farming station check the audit called always-true is real (it accepts a village or a home station) |
| B13-06 | Economy rule 1: no purchase without the money | VERIFIED | staging `07d1170` | `player_sell_many` / `player_buy_many` refuse unless the payer's own coins cover the summed bill (start_test) |
| B13-07 | Economy rule 2: bulk prices follow supply | VERIFIED | staging `07d1170` | `World.player_quote` prices each unit at the stock it leaves; picker totals unit prices (start_test: swords 65/67/70, bars 55 not 60) |
| B13-08 | Economy rule 3: seed from real stock | VERIFIED | staging `07d1170` | Seller seed stock, farmers save seed from harvests, caravan sells seed from the merchant's coins (farming_test; grain ledger in run_tests) |
| B13-09 | Economy rule 4: theft counted by items, quantity, value | VERIFIED | staging `07d1170` | Crime records carry items/qty/value; fine = base + 50% of value (chests_test, run_tests) |
| B13-10 | Stale text and documents | VERIFIED | staging | Stamina tooltip, origin coins, L3 note, medicine wiki category, B8 master list, punch-list status notes, ledger, manifest INT-076/110/111 (start_test, wiki_test) |
| B13-11 | Livestock production chain (audit item 13) | VERIFIED | staging `a29b877` | Village pens produce; keepers collect and sell; a tavern-kitchen preparation table (s10); the cook makes cheese and egg bread; villagers eat them (meals by food per coin, tavern suppers); the tanner weaves cloth and sews bandages for the sage (farming_test::test_village_chain, an 8-day sim with coins conserved) |
| B13-12 | B closes only a quantity selector (audit item 14) | VERIFIED (headless) | staging `0570f14` | Back, Esc and X dismiss an open quantity or price control first (start_test: trade and home chest, focus kept). Not run with a real controller |
| B13-13 | Touch sprint (audit item 15) | VERIFIED (headless) | staging `0570f14` | A Run toggle on the touch bar latches sprint; same speed and cost (start_test, layout at three shapes). Not run on a phone |
| B13-14 | Station occupancy (audit item 16) | VERIFIED | staging `e6ba579` | Villagers wait while the player works a station, give way after 45 minutes; the player's place is freed on finish or cancel; nothing saved (world_test::_station_conflict) |
| B13-15 | Android signing stability | BLOCKED (owner) | release runs 13, 15 | Checked: the stable test-key secrets are missing (run 13 stopped at signing; all three empty). Build 13 is signed with a throwaway key; consequences and the owner's steps in `docs/release/BUILD_13_PACKET.md` and `ANDROID_SIGNING.md`. No key committed |

## Decisions in this run

- 2026-10-19: punch-list work is pushed to `staging/my-medieval-life` after its tests pass, as
  CLAUDE.md's standing authorisation allows; the master directive authorises normal Git operations and
  integration. `main` is untouched.
