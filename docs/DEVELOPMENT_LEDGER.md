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
| B14-01 | Harvest or talk: A works the resource, Y / T talks to the villager beside it (owner playtest) | VERIFIED (headless) | staging `60a365b` | start_test: A mines with a villager there, Y and T talk, no offer with nobody near; T prompt imported with provenance. Not run with a real controller |
| B14-02 | Villagers' home production: forage, brew poultices at home, treat their own wounds | VERIFIED | staging `b94dc22` | home_test (healing, foraging and brewing, an 8-day village with coins conserved) |
| B14-03 | House storefronts (player and villager households) | VERIFIED | staging `a9c6db0`, `d01376c` | home_test (player storefront incl. save/load, villager build, keeper, buying medicine); screenshot looked at; storefront_coins raised to 150 in `d01376c` |
| B14-04 | Cart parts and handcarts (wheel, axle, ironwork, handcart) | VERIFIED | staging `d01376c` | home_test (carpenter, smith, household assembly or purchase, 12-day run with coins conserved). Handcarts are used since B14-06 |
| B14-05 | Local-availability pricing | VERIFIED | staging `75093bf` | home_test::test_local_pricing; business_test (a dearer stall loses the sale) |
| B14-06 | Carts in play: pulled storage, parking, cart stops, deliveries, household market runs | VERIFIED (headless) | staging `512f1bc`, `f9fb853`, `8ae29c2` | Set down, pull (slower walk), park, fill like a chest, owner/family/hired help only, theft from another's cart, two market cart stops where the player's attendant unloads into the stall, households' market runs, save/load (home_test::test_carts_in_play, INT-146); screenshot looked at 2026-10-19; wiki updated. Stand-in art (mine cart). "Hubs" are the two market cart stops; more hubs not built. Not tried on a device |
| B14-07 | Cliff steps, wooden stairs and walkways | NOT STARTED | - | Owner answers recorded (task after carts) |
| B14-08 | Forest animals (MiniFolks): grazers, predators, fox raids, fights | VERIFIED | staging `2caca5a` | wildlife_test (50 checks incl. a 20-day food chain); screenshot looked at; also fixes the player's waypoint overshoot |
| B14-09 | Skeletons in caves and uncleared woods | NOT STARTED | - | Owner answers recorded; only the sword skeleton is in the free pack |
| B14-10 | Craftpix farm plants, produce and crates, fruit trees | PARTIALLY COMPLETED | staging `f9fb853` | Apple trees in play (INT-147, home_test::test_apple_trees). Not done: crop growth stages, produce icons, crates as storefront displays, plum and yellow-fruit trees (docs/assets/packs.json) |
| B14-11 | Animal Farm pack (horse and farm animals) | BLOCKED (owner decision) | staging `a91b8f1`, `f9fb853` | Pack extracted; horse imported at 1/3 with the "farm" sprite layout (wildlife_test). How horses enter the village and what they do (plough, carts, riding) is the owner's call (CLAUDE.md s.11); options in the Build 14 audit |
| B14-12 | Sprite list with pixel-grid copies for the owner | NOT STARTED | - | Requested with the cliff work |
| B14-13 | A controller connected to a phone hides the touch buttons (owner, 2026-10-19 18:25) | VERIFIED (headless) | staging `1458da8` | `joy_connection_changed` and a pad present at start switch to the pad scheme; unplugging returns a phone to touch (start_test). Not tried with a real phone and controller |
| CQ-01 | Sword responsiveness and hit detection (owner directive `docs/directives/2026-10-19_sword_combat.md`) | VERIFIED (headless) | staging `3e283b6` | combat_test (41 checks, CI); real Android touch feel not verified; archery not authorised |
| MP-01 | Player-hosted multiplayer, two-player LAN milestone (`docs/directives/2026-10-19_multiplayer_foundation.md`) | IN PROGRESS | `wip/multiplayer` `d18d7d1` (isolated; not in staging) | Host/join menus, UDP discovery, identity by key hash, host-validated movement, reconnect and host restart restore the guest; shared pick_fruit; net_test 36 checks with separate processes; all single-player suites pass on the branch. Guests can only walk. Not tried on two real devices; Android hosting unverified (docs/MULTIPLAYER.md) |
| GM-01 | Generational memory and historical consequences (`docs/directives/2026-10-19_memory_refuges_politics.md` Part I) | NOT STARTED | — | Depends on DVW-B1 relationships. Acceptance: the 30-planks multigenerational chain from real records |
| WR-01 | Protected wildlife breeding refuges, cohorts, dispersal (same directive Part II) | NOT STARTED | — | Will replace the scavenging floor of `f9fb853` |
| VP-01 | Living village politics, elections, civic offices (same directive Part III) | NOT STARTED | — | Depends on GM-01 and DVW-B1; directive section 32 lists its tests |
| WDR-10..12 | World design rules 10-12: generational memory, ecological continuity, political agency (same directive s.40) | COMPLETED | staging (this audit) | Added to `MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` s.1 after the nine existing principles; no 16-rule list exists |
| DVW-B1 | Villager relationships: favours, gifts, harms, gossip (owner chose, `749a9cd`) | NOT STARTED | — | GM-01 and VP-01 build on it |
| DVW-B2 | Assault and killing as recorded, fined crimes; what passes to an heir | NOT STARTED | — | Today an attack only turns guards hostile |
| DVW-B3 | Coin sinks worth spending on (luxuries, feasts, weddings, offerings, heriot) | NOT STARTED | — | Sized after DVW-A3's re-measure |
| DVW-B4 | Goods decay and wear (grain spoils; clothes, armour and carts wear) | NOT STARTED | — | |
| DVW-B5 | Predictable taxes with hysteresis, announced in advance | NOT STARTED | — | |
| DVW-B6 | Wildlife wandering in from the overworld | NOT STARTED | — | Overlaps WR-01 dispersal; build together |
| DVW-B7 | Life chronicle, titles and a memorial | NOT STARTED | — | Overlaps GM-01 |
| DVW-B9 | Readable danger: howl and roar cues, lethal-need warnings, cause on the succession screen | PARTIALLY COMPLETED | staging | Cause of death exists (B8-020); howl/roar rows unused; no lethal-need warning |
| DVW-A2 | Rotate several dated save backups instead of one .bak | NOT STARTED | — | SaveStore keeps one .bak |
| DVW-A3 | Re-measure the money supply, 100 and 365 days, no player | IN PROGRESS | staging `1458da8` | Runs started 2026-10-19 (seeds 1-2 at 100 days, seed 1 at 365); results go in LONG_RUN_SIMULATION.md |
| DVW-A4 | Coin and goods source/sink ledger | NOT STARTED | — | |
| DVW-A5 | Exploit test (arbitrage, round trips, cornering, flooding) | NOT STARTED | — | Plus the owner question whether honest arbitrage is intended |
| DVW-A6 | Coins and goods conserved across save/load | PARTIALLY COMPLETED | staging | Coins checked across load in run_tests and start_test; goods not |
| DVW-A7 | Over-production from raising skills by use | NOT STARTED | — | |
| DVW-A8 | Audit player-only perks against the same rules | NOT STARTED | — | Known: saplings, overworld gathering, fireball; NPCs craft regardless of skill |
| DVW-A9 | The player can always escape predators and bandits | NOT STARTED | — | |
| DVW-A12 | Keep rules in core, not UI (audit list) | NOT STARTED | — | Crime and storefront-target rules still in main.gd |
| DVW-A14 | Play one whole life before each release | NOT STARTED | — | Add to TESTING_CHECKLIST |
| FR-01 | Lizards and spiders as enemies (owner, 2026-10-18: "good enemies") | BLOCKED (art) | — | No lizard or spider pack supplied; Puny Monsters has spiders for caves (with B14-09) |
| FR-02 | Forgotten Memories waterfalls, fences and props (owner, 2026-10-19) | NOT STARTED | — | Pack stored and credited; ramps go with B14-07 |
| FR-03 | Cooking raw meat outside the village: a campfire (owner request, Build 8 testing) | NOT STARTED | — | Recorded in BUILD_8_ISSUES as "needs owner approval"; the owner asked for it, so it is approved |
| FR-04 | Pad shortcuts for the Journal and Build menus; complete on-screen controls list (B12 audit) | NOT STARTED | — | |
| FR-05 | Title window opens scrolled to the bottom (Build 13 packet) | NOT STARTED | — | Not investigated |
| FR-06 | Wiki pages missing: magic, the employer star, journal and map, death causes, caravan, bandits (B12 audit) | PARTIALLY COMPLETED | staging | Sword fighting page added (CQ-01); carts and apple trees added (`8ae29c2`) |
| FR-07 | economy_sim and households_sim not run by CI | NOT STARTED | — | Both exit 1 on failure; long, so a short-day variant in CI |
| FR-08 | Music and sound (volume sliders control nothing) | BLOCKED (assets) | — | No audio supplied |
| FR-09 | Crime from desperation (owner design intent 2026-10-17: hunger can drive theft and violence) | DEFERRED (owner: "no desperation crime yet") | — | Revisit with DVW-B2 and VP-01 (constables) |
| FR-10 | Archery | DEFERRED (owner: future, not authorised) | — | Named in the sword directive as planned, not for now |
| FR-11 | Personality, prestige and migration from the owner's living-society list (2026-10-17) | STATUS UNKNOWN | staging (partly) | Apprenticeships, memories (8 events), migration of newcomers and families exist; personality traits and prestige not found; scope to confirm against GM-01/VP-01 |

## Decisions in this run

- 2026-10-19: punch-list work is pushed to `staging/my-medieval-life` after its tests pass, as
  CLAUDE.md's standing authorisation allows; the master directive authorises normal Git operations and
  integration. `main` is untouched.
