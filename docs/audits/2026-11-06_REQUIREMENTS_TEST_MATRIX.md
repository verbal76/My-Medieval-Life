# Requirements-to-tests matrix, 2026-11-06 (TEST-AUDIT-01, Part 4)

Every approved requirement that is INTEGRATED or marked NOT TESTED (742). Classes: **traced** (the register names its tests); **tested_untraced**
(a test cites its id but the register does not name it); **indirect** (checked by hand: suites test the behaviour without citing the id);
**gap** (checked by hand: no meaningful test found); **device_or_human** (a real device or a person must verify it); **process_or_docs** (a
report, document, release or art task: no behaviour to test); **not_built** (not implemented yet: no test expected); **unverified_no_test_found** (built, no citation, not yet checked by hand:
not assumed covered, not assumed missing). Citations searched in `game/tests/*.gd` and `tests/*.py` on `wip/b25r2-playtest`.

| Class | Count |
|---|---|
| traced | 445 |
| process_or_docs | 81 |
| tested_untraced | 76 |
| not_built | 59 |
| unverified_no_test_found | 56 |
| indirect | 15 |
| device_or_human | 7 |
| gap | 3 |

| Id | Title | Implementation | Verification | Class | Evidence |
|---|---|---|---|---|---|
| ANDROID-RELEASE-SIGNING | Android builds signed with the permanent release identity from the fou | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| AR-OWNER | Audit remediation owner checklist: public-release environment, reposit | IMPLEMENTATION BLOCKED | NOT TESTED | process_or_docs |  |
| AR-P0-1 | Fixed `21647e2` | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| AR-P0-2 | Assessed; remediation needs owner | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| AR-P0-3 | Owner must delete `inventory/registry` by hand | IMPLEMENTATION BLOCKED | NOT TESTED | not_built | not built yet: no test expected |
| AR-P1-2 | Fixed on staging; PR #1 branch still has push-triggered workflow | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| ARM-01 | Armorer availability: verify the armorer exists, keeps a schedule, a p | INTEGRATED | TARGETED TESTS PASSED | traced | world_test.gd |
| ARMOR-01 | Armour is acquired in play, physical, and visible when worn | INTEGRATED | TARGETED TESTS PASSED | traced | armour_worn_test.gd, character_look_test.gd, wiki_test.gd |
| ARMOR-CATALOG-01 | Every armour, helmet and cultural outfit in the Puny Characters pack c | INTEGRATED | TARGETED TESTS PASSED | traced | gear_catalogue_test.gd |
| ARMOR-MATERIALS-01 | Boar tusks and antlers as hunted materials, used in special armour and | INTEGRATED | TARGETED TESTS PASSED | traced | gear_catalogue_test.gd |
| B12A-01 | 1-11 fixed (B13-01..10); 12 → B13-14 | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B12A-02 | Fixed (WHAT_WAS_DONE:135) | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B12A-03 | Fixed / one withdrawn (addendum :1631) | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B12A-05 | Accessibility not yet added: text scaling, a colour-blind mode, key re | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| B12A-07 | Art blockers: crop stages, tool swings, sitting poses, chimney, sawhor | IMPLEMENTATION BLOCKED | NOT TESTED | process_or_docs |  |
| B12A-08 | Deferred features from the Build 12 audit (umbrella; each child item t | NOT STARTED | NOT TESTED | process_or_docs |  |
| B12A-10 | Hardware verification of everything on real devices (umbrella of the d | INTEGRATED | TARGETED TESTS PASSED | process_or_docs |  |
| B13-01 | Retirement opens no post | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: aging_test, "retiring from a fully staffed trade opens one post" (an earlier hand check missed it) |
| B13-02 | Gold ore has no source | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B13-03 | Medicine effect text | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B13-04 | Attendant hired as carrier | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: carts/attendant suites (cart_test family) |
| B13-05 | health_jobs_test in CI; always-true checks | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B13-06 | Rule 1: no purchase without money | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: contracts_test (a buyer who cannot set the coins aside is refused), le05_paid_repair_test, regional_food_test |
| B13-07 | Rule 2: bulk prices per unit | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: parity_mining_test (per-unit prices) |
| B13-08 | Rule 3: seed from real stock | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: farming_test (seed from stock) |
| B13-09 | Rule 4: theft by items/value | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: 9 suites on theft (chests, judgment_incident, judgment) |
| B13-10 | Stale text and documents | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| B13-11 | Livestock production chain | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: experience_test, world_test (livestock) |
| B13-12 | B closes only quantity selector | INTEGRATED | TARGETED TESTS PASSED | device_or_human | ['controller'] |
| B13-13 | Touch sprint | INTEGRATED | TARGETED TESTS PASSED | device_or_human | ['phone'] |
| B13-14 | Station occupancy | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: business_works_test (station occupancy) |
| B14-01 | Harvest or talk: A works the resource, Y / T talks to the villager bes | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| B14-02 | Villagers' home production: forage, brew poultices, treat their own wo | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14-03 | House storefronts (player and villager households) | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14-04 | Cart parts and handcarts | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14-05 | Local-availability pricing | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14-06 | Carts in play: pulled storage, parking, cart stops, deliveries, househ | INTEGRATED | TARGETED TESTS PASSED | traced | home_test.gd |
| B14-07 | Cliff steps (pickaxe, Mining), wooden stairs and walkways (planks, nai | INTEGRATED | TARGETED TESTS PASSED | traced | crafts_test.gd, terrain_test.gd |
| B14-08 | Forest animals (MiniFolks): grazers, predators, fox raids, fights | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14-09 | Skeletons in caves and uncleared woods (guard by day, roam at night, 3 | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| B14-10 | Craftpix farm plants: crop stages, produce, crates, fruit trees choppe | PARTIALLY IMPLEMENTED | NOT TESTED | unverified_no_test_found |  |
| B14-11 | Animal Farm pack: the horse and farm animals | INTEGRATED | INTEGRATION VERIFIED | traced | horse_test.gd, wildlife_test.gd |
| B14-12 | Sprite list with pixel-grid copies for Aseprite (missing and weak spri | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14-13 | A controller connected to a phone or tablet hides the touch buttons an | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| B14R-01 | Record completed 100-day economy simulations (start, seeds, currency, | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-02 | Compare the manor reserve and the caravan money limit (four configurat | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-03 | Investigate iron and coal running out by day 10; document sustainable | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-04 | Build 14 tester notes | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-05 | Identify the Build 14 candidate commit and ask the owner for build app | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-06 | Permanent requirements register, lifecycle, validation, silent-deletio | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-07 | Second historical requirements recovery pass and coverage report | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-08 | Reconcile the original 16 World Design Rules (restore text if the sour | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| B14R-09 | Stable Android test-signing procedure documented (credentials, secrets | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| B14R-10 | Separate real-device verification queue (phone, controller, Windows, c | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-11 | Review draft PR #1 for unique content before recommending closure | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B14R-12 | Long-run regression: wild animals reach 0 by day 320 and the populatio | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B16-AUDIT | Build 16 complete status audit, maintained (docs/BUILD_16_STATUS.md) | INTEGRATED | NOT TESTED | process_or_docs |  |
| B16-READY | Build 16 development audit and release-readiness report | INTEGRATED | NOT TESTED | process_or_docs |  |
| B19-EMERGE | Build 19 verification and emergence principle: classify unexpected out | INTEGRATED | TARGETED TESTS PASSED | traced | run_tests.gd |
| B21-LAN-PLAYTEST | Build 21: host/join interface, Android networking, animal sync, record | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B25-AMBITION-IMPL | Activate and correct the skill-aware career ambition (job_choice) syst | INTEGRATED | NOT TESTED | traced | career_ambition_test.gd, economy_sim.gd |
| B25-BIZ-D1 | Separate business and household finances for founded workshops and all | INTEGRATED | NOT TESTED | traced | recorded in the register |
| B25-BIZ-D2 | Employees are paid: distinguish an independent craftsperson using anot | INTEGRATED | NOT TESTED | traced | recorded in the register |
| B25-BIZ-D3 | Unfinished business construction can be cancelled or abandoned through | INTEGRATED | NOT TESTED | traced | recorded in the register |
| B25-BIZ-D4 | Permanent employment as one shared framework across professions with r | INTEGRATED | NOT TESTED | traced | recorded in the register |
| B25-BIZ-D5 | Businesses may be built (home-attached or standalone), bought, sold an | INTEGRATED | NOT TESTED | traced | economy_sim.gd |
| B25-BIZ-OWN | Build 25 business ownership, paid employment and economic expansion (f | INTEGRATED | NOT TESTED | tested_untraced | business_ownership_test.gd, economy_sim.gd |
| B25-BUSINESS-IMPL | Independent business formation by qualified villagers | INTEGRATED | NOT TESTED | traced | business_founding_test.gd |
| B25-CAREER-IMPL | Opportunity-based career advancement (no automatic promotion) | INTEGRATED | NOT TESTED | tested_untraced | skilled_employment_test.gd |
| B25-CAREER-SYSTEM | Build 25 career, business and employment system (owner decisions D1-D4 | INTEGRATED | NOT TESTED | process_or_docs |  |
| B25-CLOSE-01 | Complete Build 25 before packaging: closure audit, finish farming Phas | INTEGRATED | NOT TESTED | process_or_docs |  |
| B25-CLOSE-02 | Close Build 25 under strict scope: finish the targeted tests, freeze o | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| B25-ECON-P7 | Recover stranded settlement treasury ore | IN DEVELOPMENT | NOT TESTED | unverified_no_test_found |  |
| B25-EMPLOY-IMPL | Skilled employment growth without fixed headcount caps | INTEGRATED | NOT TESTED | traced | career_ambition_test.gd, skilled_employment_test.gd |
| B25-FINISH-01 | Build 25 completion: fixed finish line, finish approved scope, integra | IN DEVELOPMENT | NOT TESTED | process_or_docs |  |
| B25-NINE | Build 25: implement the nine consolidated owner decisions of 2026-11-0 | INTEGRATED | TARGETED TESTS PASSED | traced | world_test.gd |
| B25-OVN-0211 | Overnight autonomous development (2026-11-02): broad engineering discr | INTEGRATED | NOT TESTED | process_or_docs |  |
| B25-SCOPE-AUDIT | Build 25 complete expansion and abandoned-work reconciliation audit (r | IMPLEMENTED ON TASK BRANCH | NOT TESTED | process_or_docs |  |
| B25-SCOPE-REGION | Build 25 scope correction: the regional economy, world map, physical i | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| B25R1-001 | Build 25 Revision 1: regional navigation, living-world interactions, a | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| B25R1-002 | Full interaction outside the starting village (release blocker) | INTEGRATED | TARGETED TESTS PASSED | traced | countryside_test.gd, outside_interact_test.gd |
| B25R1-003 | Region map: major settlements and roads known from the start; discover | INTEGRATED | TARGETED TESTS PASSED | traced | region_travel_test.gd |
| B25R1-004 | Roads and trails audit: stone roads and dirt trails rendered, connecte | INTEGRATED | TARGETED TESTS PASSED | traced | region_travel_test.gd |
| B25R1-005 | Region map controls: pinch and wheel zoom, pan, centre on player, rout | INTEGRATED | TARGETED TESTS PASSED | traced | region_map_shot.gd, region_travel_test.gd |
| B25R1-006 | Tap anywhere to travel: real walked routes, road preference, interrupt | INTEGRATED | TARGETED TESTS PASSED | traced | region_map_shot.gd, region_travel_test.gd |
| B25R1-007 | Character creation: unrestricted cosmetic options | INTEGRATED | TARGETED TESTS PASSED | traced | char_create_test.gd, character_look_test.gd |
| B25R1-008 | Visual polish: character creation, origin story, region map; modal HUD | INTEGRATED | TARGETED TESTS PASSED | traced | char_create_test.gd, ui_polish_shot.gd |
| B25R1-009 | Seed travelers: real settlement residents travel the roads to buy an i | INTEGRATED | TARGETED TESTS PASSED | traced | region_sim_test.gd, region_trade_test.gd, seed_traveler_test.gd |
| B25R1-010 | Independent homesteading and generational rural settlement (NPCs and t | INTEGRATED | TARGETED TESTS PASSED | traced | economy_sim.gd, flight_scenarios.gd, homestead_presence_test.gd, homestead_shot.gd |
| B25R1-011 | Roads grow with use (grass to path to road by traffic share) and pavin | INTEGRATED | TARGETED TESTS PASSED | traced | overworld_test.gd, road_wear_shot.gd, road_wear_test.gd |
| B25R1-012 | Gamepad destination selection on the region map (cursor, D-pad, confir | INTEGRATED | TARGETED TESTS PASSED | traced | gamepad_map_test.gd |
| B25R1-013 | Youth runaways from sustained household hardship, and bandit recruitme | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| B25R1-014 | Shared wilderness settlement foundation: lawful homesteads and outlaw | INTEGRATED | TARGETED TESTS PASSED | traced | flight_scenarios.gd, homestead_presence_test.gd, homestead_shot.gd, homestead_test.gd |
| B25R1-016 | 365-day flight recorder campaign proving the living world: migration, | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | b25_recorder_test.gd, economy_sim.gd, flight_scenarios.gd, test_flight_lives.py |
| B25R1-017 | Integration, real water system (streams, rivers, waterfalls, bridges, | INTEGRATED | TARGETED TESTS PASSED | traced | b25_recorder_test.gd, overworld_test.gd, water_test.gd, wilds_test.gd |
| B25R1-019 | Presence by view range: everything within the player's view plus a mar | INTEGRATED | TARGETED TESTS PASSED | traced | courier_live_test.gd, economy_sim.gd, hamlet_test.gd, homestead_presence_test.gd |
| B25R1-020 | Anticipatory NPC crowd management in the presence buffer: eligible ord | INTEGRATED | TARGETED TESTS PASSED | traced | economy_sim.gd, presence_test.gd |
| B25R1-022 | Integrate Fantasy Lands Houses (Szadi art) into the towns: palette rem | NOT STARTED | NOT TESTED | tested_untraced | fl_house_shot.gd, fl_houses_test.gd, low_grass_test.gd, overworld_test.gd |
| B25R1-023 | Bow.Pixel Low Grass decoration drawn on the overworld (ground variety) | IN DEVELOPMENT | NOT TESTED | unverified_no_test_found |  |
| B25R1-024 | Region map restyle in the shared UI design language (UIStyle), with ga | IN DEVELOPMENT | NOT TESTED | process_or_docs |  |
| B25R1-025 | Aerial region and village maps of the generated world | INTEGRATED | TARGETED TESTS PASSED | traced | aerial_map_shot.gd, aerial_map_test.gd, atlas_test.gd, start_test.gd |
| B25R1-026 | Settlements never hidden by map discovery | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| B7-001 | Starting coins | INTEGRATED | TARGETED TESTS PASSED | tested_untraced | run_tests.gd |
| B7-002 | Quest rewards reserved | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd |
| B7-003 | Jewellery/helmets have buyers | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd |
| B7-004 | Harvest-work wheat theft | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd |
| B7-005 | Earning money discoverable; "Trade with" | INTEGRATED | TARGETED TESTS PASSED | device_or_human | ['phone'] |
| B7-006 | Hired work pays poorly (mine shift 8 for ore worth ~18; axe needed) | INTEGRATED | INTEGRATION VERIFIED | traced | early_game_test.gd, quarry_test.gd |
| B7-007 | Deposits never refill; no stone source | INTEGRATED | TARGETED TESTS PASSED | traced | housing_test.gd, run_tests.gd |
| B7-008 | Player can drain buyers to 0, kill all wildlife | INTEGRATED | INTEGRATION VERIFIED | gap | GAP (low): no test of the player draining buyers or hunting out the wildlife (balance) |
| B7-009 | Treasury starts below reserve; no paid manor work until ~day 12 | INTEGRATED | NOT TESTED | tested_untraced | run_tests.gd |
| B7-010 | HUD anchoring on Android | INTEGRATED | TARGETED TESTS PASSED | tested_untraced | start_test.gd |
| B7-011 | Tapping trees/ore does nothing | INTEGRATED | TARGETED TESTS PASSED | tested_untraced | start_test.gd |
| B7-012 | Gather mode | INTEGRATED | TARGETED TESTS PASSED | tested_untraced | start_test.gd |
| B7-013 | Brown glyph icons | INTEGRATED | TARGETED TESTS PASSED | device_or_human | ['phone'] |
| B7-014 | Caravan grows currency ~12x a year | INTEGRATED | NOT TESTED | tested_untraced | run_tests.gd |
| B7-015 | Missed meals while food piles up | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, reserve_test.gd, run_tests.gd |
| B7-016 | Tanners/goods merchants end at 0 coins | IMPLEMENTATION BLOCKED | NOT TESTED | tested_untraced | run_tests.gd |
| B8-001 | (earlier fix) | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8-002 | Village pasted over terrain | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd |
| B8-003 | Floating/partial trees | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd, tree_test.gd |
| B8-004 | Broken mining area | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd |
| B8-005 | Tree collision/transparency | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | tree_test.gd |
| B8-006 | Harvest animation never stops | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| B8-007 | Wrong tool shown | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | run_tests.gd, start_test.gd |
| B8-008 | Deposits misidentified | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | world_test.gd |
| B8-009 | Collection notices need icons | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| B8-010 | Inventory blocked during harvest | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd, start_test.gd |
| B8-011 | No cancel | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | overworld_test.gd, start_test.gd |
| B8-012 | Oversized inventory highlights | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| B8-013 | Oversized prompts | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| B8-014 | NPC blocks a workstation | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| B8-015 | Weapon racks | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd, start_test.gd, test_village.py |
| B8-016 | Essential trade succession | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | capability_metrics.gd, run_tests.gd, skilled_employment_test.gd, start_test.gd |
| B8-017 | Personal chests in public rows | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd |
| B8-018 | Roof flicker indoors | INTEGRATED | TARGETED TESTS PASSED | tested_untraced | world_test.gd |
| B8-019 | Unclear HUD | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd, start_test.gd |
| B8-020 | Death cause | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd, start_test.gd |
| B8-025 | Player clipped behind tabletops | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | test_village.py |
| B8-026 | Grey boulders not minable | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | world_test.gd |
| B8-027 | Sprint | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| B8-028 | Sawmill | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd |
| B8-029 | Calendar, aging, families, animal life cycles | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | aging_test.gd, start_test.gd |
| B8R-001 | Pad cannot reach Wear/Drop | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-002 | Trapped inside a door | INTEGRATED | INTEGRATION VERIFIED | traced_new | door_exit_test (wip/test-audit `7971720`): from just inside every door the way out is open |
| B8R-003 | Trapped between trees | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-004 | Sage's hut door off by one | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-007 | Overlapping house edges | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-008 | Family name signs at houses | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| B8R-009 | Trading skill never gains XP | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: trade_skills_test (caught mutation M7 on skill gain) |
| B8R-010 | Pickpocketing children allowed | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| B8R-011 | Map border; large world | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-012 | Hit feedback | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-013 | Cow attack shows no damage | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-014 | Pad cycles all buttons | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-015 | Flowers pickable/walkable | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-016 | Berry bushes pickable | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-017 | Field half-plants at edges | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-018 | Villagers swing tools idly | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-019 | Building collision, interior nav, roof flicker | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| B8R-020 | Gathering banners fill phone screen | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| BANDIT-RETURN | Outlaws return: a season after the band is wiped out, 2-3 outlaws arri | INTEGRATED | INTEGRATION VERIFIED | traced | aspiration_test.gd, contract_50ore_test.gd, economy_sim.gd, outlaw_return_test.gd |
| BARBER-01 | Barber service: change hairstyle in the village through the economy | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| BRANCH-POL-01 | Branch and worktree policy: one code integration branch (wip/expansion | INTEGRATED | NOT TESTED | process_or_docs |  |
| BUILD-3PLATFORM | Every build produces Android, Windows and Linux together, stably signe | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| BUILD-SEQ-25-27 | Build sequence (owner, 2026-10-31): Build 25 = Expansion 20 validation | NOT STARTED | NOT TESTED | process_or_docs |  |
| CC-01 | Character creator replaces the eight preset looks (appearance only, ci | INTEGRATED | INTEGRATION VERIFIED | traced | character_look_test.gd, discovery_test.gd, inventory18_test.gd, openpit_test.gd |
| CHAPEL-LENDING | Chapel community lending and grants (concept approved): hardship recov | NOT STARTED | NOT TESTED | process_or_docs |  |
| CHAPEL-PURPOSE | Chapel economic purpose: a charitable institution that maintains itsel | INTEGRATED | NOT TESTED | traced | chapel_test.gd, economy_sim.gd |
| CON-01 | Universal negotiated goods-procurement contracts (item, quantity, pric | INTEGRATED | TARGETED TESTS PASSED | traced | contract_50ore_test.gd, contracts_test.gd, economy_model_test.gd, economy_sim.gd |
| CON-02 | Service contracts in the universal CON-01 engine (labour and services; | INTEGRATED | TARGETED TESTS PASSED | traced | contracts_test.gd, experience_test.gd, services_d2_test.gd, services_test.gd |
| CON-02-KINDS | CON-02 unfinished service kinds: further labour and service contracts | NOT STARTED | NOT TESTED | process_or_docs |  |
| CON-03 | Restricted negotiated service advances (CON02-S-1) | INTEGRATED | NOT TESTED | traced | le07_gates_test.gd, services_d2_test.gd |
| CON-04 | Negotiated service compensation structures: work, results, base plus b | INTEGRATED | NOT TESTED | traced | services_d2_test.gd |
| CON-05 | Contract protections and dispute process before the local authority (C | INTEGRATED | NOT TESTED | traced | services_d2_test.gd |
| CON-06 | Agricultural labour contracts (CON02-S-4) | INTEGRATED | NOT TESTED | traced | services_d2_test.gd |
| CON-07 | Independent villager service hiring across industries (CON02-S-5) | INTEGRATED | NOT TESTED | traced | services_d2_test.gd |
| CON-08 | Separate formal-signing threshold for service contracts (CON02-S-6) | INTEGRATED | NOT TESTED | traced | services_d2_test.gd |
| CON-UX-01 | Contract window needs design work | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| CQ-01 | Sword responsiveness and hit detection (buffer, reach, phases, walls) | INTEGRATED | TARGETED TESTS PASSED | traced | combat_test.gd |
| CREATURE-OWN | Creature ownership: Expansion 26 owns the behaviour, survival, combat | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| CRT-01 | Player courtship and marriage through gifts: attraction, dating, propo | INTEGRATED | TARGETED TESTS PASSED | traced | relations_test.gd |
| CRT-02 | Friendship: a Befriend option appears after help and gifts; no proposa | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| CRT-04 | Villagers court each other through gifts, dating and proposals by the | INTEGRATED | TARGETED TESTS PASSED | traced | aging_test.gd |
| CRT-05 | Gift tastes follow obvious things: a villager's trade and current need | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| CRT-07 | Courtship and marriage between any two humans, same sex included; huma | INTEGRATED | TARGETED TESTS PASSED | traced | relations_test.gd |
| CRT-08 | Shared experiences start friendships and romances: working together an | INTEGRATED | TARGETED TESTS PASSED | traced | aging_test.gd, relations_test.gd |
| CRT-09 | Weighting of closeness and conversation: proximity about 1 point, a co | INTEGRATED | TARGETED TESTS PASSED | traced | relations_test.gd |
| CRT-10 | Relationship weighting system: closeness over time (the nearby-name pr | INTEGRATED | TARGETED TESTS PASSED | traced | relations_test.gd |
| CRT-11 | Single villagers with spare money and goods actively seek company: spe | INTEGRATED | TARGETED TESTS PASSED | traced | relations_test.gd |
| CRT-12 | Proposals can be refused: not wanting to marry, a rival suitor with a | INTEGRATED | TARGETED TESTS PASSED | traced | manhunt_test.gd, relations_test.gd |
| CTR-01 | Skilled-trade sales counters: every established skilled business (armo | INTEGRATED | TARGETED TESTS PASSED | traced | world_test.gd |
| CTR-02 | At a counter: a prompt, press A, and the business's available shopkeep | INTEGRATED | TARGETED TESTS PASSED | traced | world_test.gd |
| CTR-03 | Shopkeeper availability: ordinary villagers with schedules; when summo | INTEGRATED | TARGETED TESTS PASSED | traced | world_test.gd |
| CTR-04 | Permanent counters are not market stalls: no stall commission on count | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| DEMO-01 | Replayable 120-Minute Demo and Steam Integration (with the six-package | INTEGRATED | TARGETED TESTS PASSED | traced | demo_test.gd, test_android_export.py |
| DEV-GOV-01 | Development governance: agents make technical decisions within approve | INTEGRATED | NOT TESTED | process_or_docs |  |
| DOC-AUTH-01 | Document authority replacement: once the owner explicitly approves and | NOT STARTED | NOT TESTED | process_or_docs |  |
| DOC-CONT-01 | Permanent development documentation and AI continuity: one current-sta | NOT STARTED | NOT TESTED | process_or_docs |  |
| DOC-RECON-REVIEW-01 | Owner review of DOC-RECON-01 (2026-10-31): wip/requirements-control st | NOT STARTED | NOT TESTED | process_or_docs |  |
| DVW-A1 | Stale heir comment (:26) | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| DVW-A10 | No black-hole spaces (:35) | INTEGRATED | TARGETED TESTS PASSED | traced | openpit_test.gd, terrain_test.gd, underground_ext_test.gd |
| DVW-A11 | Threats never scale to player (:36) | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| DVW-A12 | Keep rules in `core/`, not UI; audit list (:37) | INTEGRATED | TARGETED TESTS PASSED | traced | economy_sim.gd, run_tests.gd, world_test.gd |
| DVW-A13 | Every visible object has a use (:38) | PARTIALLY IMPLEMENTED | NOT TESTED | unverified_no_test_found |  |
| DVW-A14 | Play one whole life before each release (:39) | INTEGRATED | NOT TESTED | process_or_docs |  |
| DVW-A2 | Rotate several dated save backups, not one `.bak` (:27) | INTEGRATED | INTEGRATION VERIFIED | traced | run_tests.gd, start_test.gd |
| DVW-A3 | Re-measure money supply, 100 and 365 days, 2-3 seeds, no player (:28) | PARTIALLY IMPLEMENTED | NOT TESTED | unverified_no_test_found |  |
| DVW-A4 | Faucet and drain ledger for coins and each item (:29) | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd |
| DVW-A5 | Exploit-player test (arbitrage, round trips, cornering, flooding) (:30 | INTEGRATED | INTEGRATION VERIFIED | traced | exploit_test.gd |
| DVW-A6 | Coins and goods conserved across save/load and tier transitions (:31) | INTEGRATED | INTEGRATION VERIFIED | traced | census.gd, conservation_test.gd |
| DVW-A7 | Over-production from raising skills by use (:32) | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| DVW-A8 | Audit player-only perks vs same rules (:33) | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| DVW-A9 | Player can always escape predators/bandits (:34) | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| DVW-B1 | Villager relationships, memory of favours/gifts/harms, gossip | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| DVW-B2 | Assault and killing as recorded, fined crimes; heir inheritance of fin | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| DVW-B3-CHAPEL | Coin sink: offerings at a village chapel or shrine (a chapel building | INTEGRATED | INTEGRATION VERIFIED | traced | chapel_shot.gd, chapel_test.gd, economy_sim.gd, test_village.py |
| DVW-B3-FEAST | Coin sink: wedding feasts and seasonal feasts at the tavern, food and | INTEGRATED | INTEGRATION VERIFIED | traced | feast_test.gd |
| DVW-B3-LUX | Coin sink: luxury imports sold by the caravan for status | INTEGRATED | INTEGRATION VERIFIED | traced | luxury_test.gd, od16_test.gd, run_tests.gd |
| DVW-B4 | Goods decay (grain spoils, clothes/armour/carts wear) | INTEGRATED | TARGETED TESTS PASSED | traced | chapel_test.gd, decay_test.gd, run_tests.gd, underground_ext_test.gd |
| DVW-B5 | Predictable taxes with hysteresis, announced | INTEGRATED | INTEGRATION VERIFIED | traced | run_tests.gd, tax_test.gd |
| DVW-B6 | Wildlife wandering in from the overworld | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| DVW-B7 | Life chronicle, titles, memorial | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| DVW-B8 | Skills for farming, husbandry, hunting, healing | INTEGRATED | INTEGRATION VERIFIED | traced | career_ambition_test.gd, trade_skills_test.gd |
| DVW-B9 | Readable danger: howl/roar cues, lethal-need warnings, cause on succes | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| E20-P1 | Expansion 20 phase 1: LE-00 audit, requirements registration and isola | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| E22-A | Expansion 22 Phase A, architecture and regional ledger: one regional l | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| E22-B | Expansion 22 Phase B, settlement capability model: capabilities from w | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| E22-C | Expansion 22 Phase C, abstract regional settlements: conserved economi | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| E22-CONDITION | Expansion 22 owns the one shared building-condition, damage, deteriora | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| E22-D | Expansion 22 Phase D, settlement development: dwellings, infrastructur | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| E22-E | Expansion 22 Phase E, persistent regional networks on real routes (E22 | NOT STARTED | NOT TESTED | process_or_docs |  |
| E22-OD-01 | Hybrid regional simulation: detailed nearby NPCs and abstract distant | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| E22-OD-02 | Continuous geography: streamed regions, persistent world coordinates, | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| E22-P1 | Expansion 22 phase 1: read-only audit of the Settlement Advancement sp | IMPLEMENTED ON TASK BRANCH | NOT TESTED | process_or_docs |  |
| E23-BANA | Expansion 23 BAN-A: existing-system audit and requirements reconciliat | IMPLEMENTED ON TASK BRANCH | NOT TESTED | process_or_docs |  |
| E23-SCOPE | Expansion 23 works within the village, existing roads and currently re | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| EA-01 | Steam Early Access readiness: a presentable demo in about three weeks, | NOT STARTED | NOT TESTED | tested_untraced | water_test.gd |
| EARTH-01 | Reuse of excavated earth: farmland improvement, road embankments, plot | NOT STARTED | NOT TESTED | process_or_docs |  |
| ECON-P1.3 | Caravan as finite regional market (:73) | INTEGRATED | INTEGRATION VERIFIED | traced | caravan_compare.gd, consign_test.gd, regions_test.gd, run_tests.gd |
| ECON-P3 | Household vs business money: a shop has its own till; the owner pays t | INTEGRATED | TARGETED TESTS PASSED | traced | business_money_test.gd, business_test.gd, business_works_test.gd, economy_model_test.gd |
| EMP-PERM-01 | Permanent employment by the player for production roles (miner at a mi | INTEGRATED | NOT TESTED | traced | business_founding_test.gd |
| ENV-RTK | RTK token tool and its hook persistent in the cloud environment | IMPLEMENTATION BLOCKED | NOT TESTED | not_built | not built yet: no test expected |
| EQ-01 | Human civilization sustains itself without the player | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| EQ-02 | Nature sustains itself: reproduction, aging, predation, competition, d | INTEGRATED | INTEGRATION VERIFIED | traced | ecology_test.gd |
| EQ-03 | Humans and nature affect each other through real NPC decisions | INTEGRATED | INTEGRATION VERIFIED | traced | ecology_test.gd |
| EQ-04 | A functioning society survives individual losses (succession of trades | INTEGRATED | INTEGRATION VERIFIED | traced | succession_test.gd |
| EQ-05 | The player is the disruptive variable: no hidden protection of the wor | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | economy_sim.gd |
| EQ-06 | Build 16 acceptance simulations: multi-seed, player inactive, 100 and | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, world_test.gd |
| EQ-07 | Investigate and correct the 365-day failures: population 100 to 69, wi | INTEGRATED | INTEGRATION VERIFIED | traced | aging_test.gd, economy_sim.gd, housing_test.gd, housing_trace.gd |
| EQ-08 | Births do not require a free bed; the crowding a birth causes is what | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd |
| EQ-09 | Local stone deposits run out (day 160-190 in the Build 15 runs); verif | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| EQ-10 | Economy simulation: axe and hammer ledger residuals of 1-3 from day 12 | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| EQ-16 | World equilibrium: an untouched world stays viable across generations; | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| EQ-17 | Long simulations: a household that loses its house leaves an empty hom | INTEGRATED | INTEGRATION VERIFIED | traced | housing_test.gd |
| EQ-18 | Tool recovery and essential trades over a year: job seekers can buy th | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| EQ-19 | The manor supports the essential trades from its treasury (OD-16 b): i | INTEGRATED | INTEGRATION VERIFIED | traced | econ_p2p3_test.gd, firewood_probe.gd, le04_test.gd, le05_rental_test.gd |
| EQ-20 | Bandit coins recirculate (OD-16 a): bandits spend their hoards at the | INTEGRATED | INTEGRATION VERIFIED | traced | od16_test.gd |
| EQ-21 | The caravan buys more of the village's surplus (OD-16 c): meat, hides | INTEGRATED | INTEGRATION VERIFIED | traced | od16_test.gd |
| EQ-22 | Caravan buying order: smiths first starves the hide and leather chain | INTEGRATED | TARGETED TESTS PASSED | traced | od16_test.gd |
| EXP-22 | Expansion 22, Settlement Advancement Phase 2: a region of independent | NOT STARTED | NOT TESTED | process_or_docs |  |
| EXP-23 | Expansion 23, Bandit Factions and Criminal Careers: crime, enforcement | NOT STARTED | NOT TESTED | process_or_docs |  |
| EXP-24 | Expansion 24, Generational Legacy: earlier generations' consequences i | NOT STARTED | NOT TESTED | process_or_docs |  |
| EXP-26 | Expansion 26, Creatures and Heroes: taming, pets and companions, monst | NOT STARTED | NOT TESTED | process_or_docs |  |
| EXP-27 | Expansion 27, World Exploration, Dungeons & Encounters: connect the st | NOT STARTED | NOT TESTED | process_or_docs |  |
| EXP-A | Expansion A: Mining & Industrial Development (independent future expan | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| EXP-C | Expansion C: NPC Judgment System (Subjective Judgment & Universal Deci | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| F-1 | NPC workshop construction | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| FAM-01 | Household succession: when one parent dies the surviving parent (eithe | INTEGRATED | TARGETED TESTS PASSED | traced | housing_test.gd |
| FAM-02 | Both parents dead: dependent children never found households or start | INTEGRATED | TARGETED TESTS PASSED | traced | family_test.gd, housing_test.gd |
| FAM-03 | Informal adoption order: living grandparents (both sides), then the ne | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| FAM-04 | Integration: the child becomes a dependant of the receiving household | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| FAM-05 | Occupancy after a child is taken in is recalculated; any housing need | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| FAM-06 | Family scenario tests: the eight family scenarios of the directive, wr | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| FAM-07 | Unplaced orphans join the bandit clan (OD-11): after surviving parent, | INTEGRATED | TARGETED TESTS PASSED | traced | family_test.gd |
| FAM-08 | Future: an adult raised in the bandit clan decides their own future fr | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| FAM-SAC-01 | Family sacrifice and responsibility: the father figure puts children, | INTEGRATED | TARGETED TESTS PASSED | traced | family_first_test.gd, recorder_test.gd |
| FARM-01 | Farmland plots: any household (player or villager) leases a small plot | INTEGRATED | INTEGRATION VERIFIED | traced | farm_plots_test.gd |
| FARM-02 | Developing farmland: clear trees and obstructions, then build a fence | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FARM-03 | Ploughing and sowing a family plot with real seed by the established f | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FARM-04 | Household participation: family members work the plot by age, ability, | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FARM-05 | Whether a household takes up a plot: from its circumstances, needs, sk | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FARM-07 | The farmland lease's recurring charge: 2 coins under the existing week | INTEGRATED | INTEGRATION VERIFIED | traced | farm_plots_test.gd |
| FARM-08 | Shared-yield comparison: the per-cell model and seasonal farming toget | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | aging_test.gd, crop_share_test.gd, economy_sim.gd, farm_plots_test.gd |
| FARM-08A | No script error when a homeless household's couple or founder looks fo | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FARM-08B | Cattle decline under the shared and seasonal farming model: investigat | INTEGRATED | TARGETED TESTS PASSED | traced | economy_sim.gd, herd_test.gd |
| FARM-08C | Wheat price floor: record as an economic finding | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| FARM-09 | Farmland placement by drag: two green corners, live price at screen ce | INTEGRATED | TARGETED TESTS PASSED | traced | farm_place_test.gd, farm_plots_test.gd |
| FARM-CROP-01 | Share a field's crop among its cutters in proportion to their cutting | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FARM-CROP-SEED | Seed kept back from a shared field is split among its cutters by work, | INTEGRATED | INTEGRATION VERIFIED | traced | crop_share_test.gd |
| FIX-D1D2 | Saves never activate a disabled feature, and a disabled feature keeps | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FIX-D3 | Friendly-guard fine rule behind the judgment switch: Build 18 behaviou | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FIX-RECF1 | Fix the unsold-goods re-decision loop (REC-F1): find the actual cause | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FLIGHT-REC-01 | Permanent flight recorder simulation system: 'Run flight recorder' lau | INTEGRATED | NOT TESTED | tested_untraced | economy_sim.gd, flight_workbook.gd, test_flight_analyse.py |
| FR-01 | Lizards and spiders as enemies | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| FR-02 | Forgotten Memories waterfalls, fences and props | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| FR-03 | A campfire for cooking raw meat outside the village | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| FR-04 | Pad shortcuts for the Journal and Build menus; complete on-screen cont | INTEGRATED | TARGETED TESTS PASSED | traced | start_test.gd |
| FR-05 | Title window opens scrolled into the controls list | INTEGRATED | INTEGRATION VERIFIED | traced | start_test.gd |
| FR-06 | Wiki pages missing: magic, the employer star, journal and map, death c | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FR-07 | Economy and household simulations in CI (short variant) | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FR-09 | Crime from desperation | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| FR-10 | Archery | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| FR-11 | Personality, prestige and migration (owner's living-society list, 2026 | PARTIALLY IMPLEMENTED | NOT TESTED | unverified_no_test_found |  |
| FR-REPAIR-01 | Flight recorder repair: KI-HOME-DOOR root cause, homeless-safe evening | INTEGRATED | NOT TESTED | process_or_docs |  |
| FSE-00 | Food security, household production, land use, markets and goal-driven | INTEGRATED | NOT TESTED | process_or_docs |  |
| FSE-01 | Current-system audit: agriculture, consumption, hunting, husbandry, la | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| FSE-02 | Food sustainability calculation: food and productive land per villager | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| FSE-03 | Gap analysis: agriculture, husbandry, hunting, rental, commerce and AI | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| FSE-04 | Cross-system dependency map for the food and living economy | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| FSE-05 | Implementation roadmap: Build 16 foundations vs the living-economy bui | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| FSE-06 | Testing strategy for the food and living economy | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| FSE-07 | Unresolved owner questions arising from the food-security directive | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| FSE-08 | The directive's 25 deterministic tests (section 17) | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FSE-09 | Build 16 food-security defects and foundations (classes B and C) | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | world_test.gd |
| FSE-10 | Living-economy build: gardens, rented land and pens, side hunting, hou | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| FSE-14 | Dynamic land planning: design and safe foundations (land rental for pl | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| FSE-15 | Recalculate the land requirement after the seed, season and parity cor | INTEGRATED | INTEGRATION VERIFIED | traced | farm_plots_test.gd |
| FSE-16 | Seed-2 starvation: root cause of each of the 11 deaths | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, reserve_test.gd |
| FSE-17 | Manor relief checks and draws on every food store (amends the B3 relie | INTEGRATED | INTEGRATION VERIFIED | traced | reserve_test.gd, run_tests.gd |
| FSE-18 | The family chest: a household's food is kept in its pantry, communal; | INTEGRATED | INTEGRATION VERIFIED | traced | reserve_test.gd |
| FSE-B05 | A pen whose keeper is gone is let again (its animals starved untended) | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| FSE-B06 | Bandits' poaching and the clan's camp meals feed them only from real f | INTEGRATED | INTEGRATION VERIFIED | traced | family_test.gd, world_test.gd |
| FSE-B07 | Villagers can sell flowers to the Apothecary | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| FSE-B08 | A hunt cut short releases its claim on the animal | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| FSE-B09 | Hunter job openings count only game hunters may take | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| FSE-B10 | The player's kills enter the wildlife ledger | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| FSE-B11 | The home hearth gives the player and villagers the same recipes | INTEGRATED | INTEGRATION VERIFIED | traced | furniture_test.gd |
| FSE-B12 | Hunting experience by one rule for the player and villagers | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | INTEGRATED | TARGETED TESTS PASSED | traced | history_test.gd, judgment_x19_test.gd |
| GP-ACTIONBAR | Android action controls redesigned into two readable right-side column | INTEGRATED | INTEGRATION VERIFIED | traced | start_test.gd, touch_bar_shot.gd |
| GP-ANDROID-ACTION-BUTTONS | Android right-side action controls: compact circular backgrounds, clos | INTEGRATED | INTEGRATION VERIFIED | traced | start_test.gd, x20_android_ui_test.gd |
| GP-ANDROID-HUD-SCALE | Android health and status panel about 15% smaller, with every value ke | INTEGRATED | INTEGRATION VERIFIED | traced | x20_android_ui_test.gd |
| GP-ANDROID-RECENTER | Android Recenter places the character at the visual centre of the usab | INTEGRATED | INTEGRATION VERIFIED | traced | start_test.gd, x20_android_ui_test.gd |
| GP-ANDROID-USE-TALK-TARGETING | Use prioritises the usable station or object and Talk the nearby chara | INTEGRATED | INTEGRATION VERIFIED | traced | start_test.gd, x20_android_ui_test.gd |
| GP-ANVIL | Workshop anvil: the touch and click target is the visible anvil (not t | INTEGRATED | INTEGRATION VERIFIED | traced | polish_p2_test.gd, sim_probes.gd, station_shot.gd, station_tap_test.gd |
| GP-BACK-DOORS | Back doors not drawn on roofs; a trail leads to every door | INTEGRATED | INTEGRATION VERIFIED | traced | polish_p2_test.gd, run_tests.gd, sim_probes.gd, test_village.py |
| GP-BANDIT-CAMP-ART | Bandit camp: crates, barrels and campfire drawn with the wrong tiles | INTEGRATED | INTEGRATION VERIFIED | traced | campfire_test.gd |
| GP-BASELINE-POLICY | Single-player baseline may be updated for intentional approved changes | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| GP-BUSINESS-COURIER | Business courier integration: the courier hand-off at a business desk | INTEGRATED | TARGETED TESTS PASSED | traced | courier_desk_test.gd |
| GP-BUSINESS-DESK | Every business has a business desk: trade and courier in one place | INTEGRATED | TARGETED TESTS PASSED | traced | business_money_test.gd, desk_test.gd, world_test.gd |
| GP-CHECKPOINT-1 | Checkpoint 1: private three-platform playtest release (Android, Window | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| GP-CRIME-PURSUIT | Proportionate crime response, guard pursuit that survives loss of sigh | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, justice_test.gd, manhunt_test.gd, pursuit_test.gd |
| GP-DIALOGUE-PERSPECTIVE | NPCs speak from their own perspective: I, we, my mother, you; witnesse | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| GP-DRAW-UNDER-HOUSE | Player drawn half under a house wall (Marsh house front) | INTEGRATED | INTEGRATION VERIFIED | traced | house_front_shot.gd, polish_p2_test.gd |
| GP-FARMER-TENDING | Farmers tending a field walk through it working the ground with a tool | INTEGRATED | TARGETED TESTS PASSED | traced | field_work_test.gd |
| GP-GIFT-QUANTITY | Gifts: give one by default, with a number picker; never the whole stac | INTEGRATED | INTEGRATION VERIFIED | traced | gift_quantity_test.gd |
| GP-GOSSIP-NATURAL | Gossip combines related events naturally without repeating names, hous | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| GP-HARVEST-CONT | Continuous harvesting on all platforms with a setting (continuous or m | INTEGRATED | INTEGRATION VERIFIED | traced | harvest_setting_test.gd |
| GP-INPUT-CONSIST | Cross-platform input consistency: Android, Windows, Linux, Steam Deck, | INTEGRATED | INTEGRATION VERIFIED | traced | joystick_test.gd |
| GP-INTERACTABLE-OUTLINES | Usable objects nearby show a subtle sprite-silhouette glow; the select | INTEGRATED | INTEGRATION VERIFIED | traced | x20_android_ui_test.gd |
| GP-INTERACTION-PROMPT-LIFECYCLE | Contextual prompts ('Use the workbench') clear while the interaction i | INTEGRATED | INTEGRATION VERIFIED | traced | x20_android_ui_test.gd |
| GP-INTERIOR-WALLS | Building interiors: side walls missing when inside | INTEGRATED | INTEGRATION VERIFIED | traced | test_village.py |
| GP-JOYSTICK | Android movement option: tap-to-move (default, existing) or a lower-le | INTEGRATED | INTEGRATION VERIFIED | traced | joystick_test.gd |
| GP-LOCKPICK | Interactive pin-tumbler lockpicking minigame replacing the passive met | INTEGRATED | TARGETED TESTS PASSED | traced | lockpick_test.gd, wiki_test.gd |
| GP-MARKET-SHELVES | Market stalls as Craftpix wooden shelves showing each merchant's actua | INTEGRATED | INTEGRATION VERIFIED | traced | business_works_test.gd, market_shelf_test.gd |
| GP-MARKET-SPACING | Market stalls with the Craftpix shelf sprite stand too close together | INTEGRATED | TARGETED TESTS PASSED | traced | housing_test.gd, market_spacing_test.gd, test_village.py |
| GP-MESSAGE-FOOTPRINT | The message box and the interaction prompt take too much of the screen | INTEGRATED | TARGETED TESTS PASSED | traced | msg_prompt_shot.gd, x20_android_ui_test.gd |
| GP-MESSAGE-JOURNAL | Messages journal is saved with the world: persistent, per-world, filte | INTEGRATED | TARGETED TESTS PASSED | traced | gen_b22_save_fixture.gd, message_journal_test.gd, net_g1_test.gd, net_host.gd |
| GP-MINE-WOOD-FRAME | Underground: a wooden frame drawn over the wall beside a deposit reads | INTEGRATED | TARGETED TESTS PASSED | traced | mine_frame_test.gd, wiki_test.gd |
| GP-PACK-DETAIL-FIT | Pack item detail panel: action buttons cut off the bottom of the scree | INTEGRATED | INTEGRATION VERIFIED | traced | polish_p2_test.gd |
| GP-PAUSE-PANEL | Pause menu: a framed panel over the dimmed game, not a full-screen bro | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| GP-PICKAXE-ANIM | Android mining shows the pickaxe swing synchronized with the work and | INTEGRATED | INTEGRATION VERIFIED | traced | start_test.gd, touch_bar_shot.gd |
| GP-POLISH | Gameplay and Controls Polish batch: anvil interaction, lockpicking min | INTEGRATED | TARGETED TESTS PASSED | traced | polish_p2_test.gd, polish_shot.gd |
| GP-PROGRESS-BAR | One overhead activity progress bar on every platform (the Android 'Min | INTEGRATED | OWNER PLAYTESTED | traced | recorded in the register |
| GP-PROPERTY-NAME-DOUBLE | Village log doubles a property's location ('beside the smithy beside t | INTEGRATED | INTEGRATION VERIFIED | traced | property_test.gd |
| GP-QTY-PICKER-CONTROLLER | Quantity pickers (putting goods up at a stall, gifts): Max and Min rea | INTEGRATED | TARGETED TESTS PASSED | traced | pad_shortcuts_test.gd |
| GP-REPAIR-SOCIAL | Master gameplay repair: dialogue, social awareness, crime response and | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| GP-SHARPEN | Sharpen a weapon at the smith's grinding wheel for 1 coin | INTEGRATED | INTEGRATION VERIFIED | traced | sharpen_test.gd |
| GP-SKILLS-RT | Controller right trigger opens Skills during normal play (an additiona | INTEGRATED | TARGETED TESTS PASSED | traced | pad_shortcuts_test.gd |
| GP-SMITHY-WORKBENCH | Smithy: the grinding wheel is not the workbench; a table dressed with | INTEGRATED | INTEGRATION VERIFIED | traced | sharpen_test.gd |
| GP-STALL-PRICE-ON-PUTUP | Market stall: set the price when putting goods up | INTEGRATED | INTEGRATION VERIFIED | traced | stall_putup_test.gd |
| GP-STALL-RENT-WRONG-PITCH | Renting a market pitch rents the first free one, not the one the playe | INTEGRATED | TARGETED TESTS PASSED | traced | stall_rent_pitch_test.gd |
| GP-START-RUSTY-AXE | The player starts with a rusty axe | INTEGRATED | INTEGRATION VERIFIED | traced | early_game_test.gd, farming_test.gd, run_tests.gd, start_test.gd |
| GP-SWORD-VIS | Visible equipped sword: held when drawn, swung with the attack in ever | INTEGRATED | INTEGRATION VERIFIED | traced | sword_visual_test.gd |
| GP-TABLE-ITEMS | Merchandise previews on tables: a visual preview of what the business | INTEGRATED | TARGETED TESTS PASSED | traced | table_preview_test.gd, test_village.py |
| GP-TARGET-ART-MATCH | Interaction prompts name what the art shows (tavern 'crate' is a roast | INTEGRATED | INTEGRATION VERIFIED | traced | test_village.py |
| GP-TRAIL-EDGES | Trails crossing bare dirt show stray grass edges | INTEGRATED | INTEGRATION VERIFIED | traced | test_village.py |
| GP-UI-COMPACT | Menus: smaller text and tighter boxes so more fits on screen | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| GP-WANTED-INDICATOR | Show the player when guards are hunting them: a red ring around the ch | INTEGRATED | TARGETED TESTS PASSED | traced | wanted_indicator_test.gd, wiki_test.gd |
| GP-WHEAT-PICKED | Harvested wheat shows as picked, cell by cell | INTEGRATED | INTEGRATION VERIFIED | traced | polish_p2_test.gd |
| GP-WIKI-LAYOUT | Encyclopedia laid out like a classic wiki page, on parchment | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| GP-WIKI-RECIPE-TOOLS | Encyclopedia recipes name every tool the work needs (for example a mal | INTEGRATED | TARGETED TESTS PASSED | traced | wiki_test.gd |
| HAG-MEM-02 | Permanent GitHub memory, decision history (with rationale) and CI repo | NOT STARTED | NOT TESTED | process_or_docs |  |
| HEALTH-01 | Medieval health, injury and medical system (injury severity, accidents | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| HOUSE-01 | Housing need arises from circumstances: crowding, a couple living apar | INTEGRATED | INTEGRATION VERIFIED | traced | housing_test.gd |
| HOUSE-02 | The household's responsible adult decides and builds; no sex or streng | INTEGRATED | INTEGRATION VERIFIED | traced | housing_test.gd |
| HOUSE-03 | A persistent housing goal begins before the household can afford it: t | INTEGRATED | INTEGRATION VERIFIED | traced | housing_test.gd |
| HOUSE-04 | Money and materials come from real systems: work, saving, buying, mate | INTEGRATED | INTEGRATION VERIFIED | traced | housing_test.gd |
| HOUSE-05 | Construction is real work over time: it consumes materials, progresses | INTEGRATED | INTEGRATION VERIFIED | traced | housing_test.gd |
| HOUSE-06 | No construction deadlock: a household reconsiders its approach with wh | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| HOUSE-07 | EQ-07 investigation and tests: trace need to completion (the directive | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| HOUSE-08 | Bed sharing in the crowding rule (OD-13): couples share a bed and youn | INTEGRATED | INTEGRATION VERIFIED | traced | aging_test.gd, housing_test.gd, run_tests.gd |
| HOUSE-09 | Original village houses can take living-quarters expansions (OD-13): t | INTEGRATED | INTEGRATION VERIFIED | traced | housing_test.gd |
| HOUSE-10 | Smaller attached rooms for existing houses (OD-14): a bedroom-sized ad | INTEGRATED | INTEGRATION VERIFIED | traced | housing_test.gd |
| HOUSE-11 | Evaluate the alternatives where a ground-floor addition is impossible | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| HOUSE-12 | Sleeping loft: a lightweight house improvement adding sleeping places | INTEGRATED | TARGETED TESTS PASSED | traced | housing_test.gd |
| ID-01 | One persistent person identity across migration (between settlements, | INTEGRATED | INTEGRATION VERIFIED | traced | aging_test.gd, identity_test.gd, migration_test.gd |
| INFO-01 | Sharing and selling prospecting information (MIN-C-Q2) | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| INFRA-01 | Long-run test reliability: preserve long-running simulation progress o | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| INFRA-02 | Manual GitHub Actions workflow for long-duration simulations: seed and | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| INV-18 | Categorized inventory: eight capacity pools, separate equipment, two u | INTEGRATED | INTEGRATION VERIFIED | traced | inventory18_test.gd, start_test.gd, wiki_test.gd |
| JOB-01 | Shared job board for salaried manor hands: eligible for appropriate bo | INTEGRATED | INTEGRATION VERIFIED | traced | job_board_test.gd |
| JOB-02 | Offered compensation on the manor job board: each funded posting offer | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| K-1 | 5 coins vs land 60+ | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| K-2 | Tavern child and sage on pallets; no lying frame | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| LAW-SKILL | Law skill: learned by witnessing and carrying documents, taught by the | INTEGRATED | INTEGRATION VERIFIED | traced | contract_sign_test.gd, courier_live_test.gd, trade_skills_test.gd |
| LE-00 | Living Economy stage LE-00: Repository audit and cross-system dependen | INTEGRATED | NOT APPLICABLE | process_or_docs |  |
| LE-01 | Living Economy stage LE-01: Shared actor, need, offer, knowledge and c | INTEGRATED | INTEGRATION VERIFIED | traced | economy_foundation_test.gd, economy_model_test.gd, economy_sim.gd, le02_market_test.gd |
| LE-02 | Living Economy stage LE-02: Adaptive bids, asks, negotiation and settl | INTEGRATED | INTEGRATION VERIFIED | traced | economy_model_test.gd, economy_sim.gd, le02_market_test.gd |
| LE-03 | Living Economy stage LE-03: Production, job choice and household budge | INTEGRATED | INTEGRATION VERIFIED | traced | economy_foundation_test.gd, economy_model_test.gd, economy_sim.gd, le03_claims_test.gd |
| LE-04 | Living Economy stage LE-04: Organic finance, merchants and manor behav | INTEGRATED | INTEGRATION VERIFIED | traced | le03_transactions_test.gd, le04_test.gd, till_ownership_test.gd |
| LE-05 | Living Economy stage LE-05: Construction, ecology, mining, bandits and | INTEGRATED | TARGETED TESTS PASSED | traced | b25_leak2_departure_test.gd, economy_sim.gd, le05_construction_hire_test.gd, le05_paid_repair_test.gd |
| LE-06 | Living Economy stage LE-06: Multi-seed long-run, determinism and profi | INTEGRATED | INTEGRATION VERIFIED | traced | economy_model_test.gd, economy_sim.gd, le02_market_test.gd, le06_save_test.gd |
| LE-07 | Living Economy stage LE-07: Release readiness and platform builds | PARTIALLY IMPLEMENTED | NOT TESTED | traced | le07_gates_test.gd, net_host.gd, od16_test.gd, region_sim_test.gd |
| LE05-RENTAL | Tool rental behind the Living Economy switch through World.transaction | INTEGRATED | TARGETED TESTS PASSED | traced | economy_sim.gd, le05_paid_repair_test.gd, le05_rental_test.gd, run_tests.gd |
| LE05-REPAIR | Tool repair at an anvil for the player and eligible NPC smiths, in nor | INTEGRATED | TARGETED TESTS PASSED | traced | le05_repair_test.gd |
| LOG-01 | Unclaimed manor deliveries fall back to an available salaried manor ha | INTEGRATED | TARGETED TESTS PASSED | traced | job_board_test.gd |
| MAINT-01 | Need-driven maintenance, village expansion and road construction: stru | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| MAP-01 | Map shows where you are beyond the village | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| MEM-01 | Persistent project memory: PROJECT_MEMORY.md index, CURRENT_DEVELOPMEN | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| MEM-02 | Permanent project memory: index covers every listed source (incl. the | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| MERCH-01 | A village seed merchant or booth selling crop and flower seed, berry c | INTEGRATED | TARGETED TESTS PASSED | traced | farming_test.gd |
| MIGRATE-18 | Migration both ways between the village and the off-map settlements fo | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, migration_test.gd, regions_test.gd |
| MIN-A | Mining expansion phase A: Audit terrain, elevation, mining, inventory, | INTEGRATED | TARGETED TESTS PASSED | traced | underground_test.gd |
| MIN-B | Mining expansion phase B: Exhausted ore outcrops stay quarryable stone | INTEGRATED | TARGETED TESTS PASSED | traced | discovery_test.gd, economy_sim.gd, quarry_test.gd, run_tests.gd |
| MIN-C | Mining expansion phase C: Natural prospecting clues, prospector profes | INTEGRATED | TARGETED TESTS PASSED | traced | contract_50ore_test.gd, discovery_test.gd, parity_mining_test.gd, prospecting_test.gd |
| MIN-C-Q1 | Prospector compensation: support manor commissioning, not as the only | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| MIN-C-Q3 | The smith remains the assayer; no separate assayer profession without | INTEGRATED | INTEGRATION VERIFIED | traced | parity_mining_test.gd |
| MIN-COLLAPSE | Binary collapse outcome: a person caught survives or dies deterministi | INTEGRATED | TARGETED TESTS PASSED | traced | equip_test.gd, underground_struct_test.gd |
| MIN-D | Mining expansion phase D: Finite hidden deposit discovery; settlement | INTEGRATED | TARGETED TESTS PASSED | traced | capability_test.gd, discovery_test.gd, economy_sim.gd, parity_mining_test.gd |
| MIN-D2 | The player counts toward the settlement's mining capability by exactly | INTEGRATED | TARGETED TESTS PASSED | traced | discovery_test.gd, openpit_test.gd, parity_mining_test.gd, underground_ext_test.gd |
| MIN-D3 | Trial pits yield conserved, recoverable topsoil, dirt and spoil throug | INTEGRATED | TARGETED TESTS PASSED | traced | parity_mining_test.gd |
| MIN-E | Mining expansion phase E: Open-pit excavation, spoil, dirt and topsoil | INTEGRATED | TARGETED TESTS PASSED | traced | contracts_test.gd, discovery_test.gd, economy_sim.gd, openpit_test.gd |
| MIN-EQUIP | Mining equipment made by carpenters and smiths (supports, ladders, min | INTEGRATED | TARGETED TESTS PASSED | traced | equip_test.gd |
| MIN-F | Mining expansion phase F: Underground and cave mining, cutaway present | INTEGRATED | TARGETED TESTS PASSED | traced | discovery_test.gd, economy_sim.gd, underground_ext_test.gd, underground_struct_test.gd |
| MIN-F2 | Implement the owner's MIN-F-Q1..Q5: support deterioration and collapse | INTEGRATED | TARGETED TESTS PASSED | traced | economy_sim.gd, equip_test.gd, underground_struct_test.gd |
| MIN-G | Mining expansion phase G: 100/365-day multi-seed simulations and gamep | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: underground and mining suites, long-sims |
| MIN-H | Enterable caves and underground mining environments (roof-fade princip | INTEGRATED | TARGETED TESTS PASSED | traced | underground_ext_test.gd, underground_test.gd |
| MIN-RIGHTS | Open access to common ground; legitimate property respected (MIN-E-Q3) | INTEGRATED | TARGETED TESTS PASSED | traced | parity_mining_test.gd |
| MIN-SHOVEL | Craftable shovels for topsoil and loose earth; pickaxes for rock; both | INTEGRATED | TARGETED TESTS PASSED | traced | equip_test.gd, parity_mining_test.gd |
| MIN-SKILLCAP | Capability counts real skills, equipment and facilities, not job title | INTEGRATED | TARGETED TESTS PASSED | traced | openpit_test.gd, parity_mining_test.gd, settlement_test.gd, underground_ext_test.gd |
| MML-CONSERVE-01 | Credit conservation: MML second priority behind Upwardly; one worker; | INTEGRATED | NOT TESTED | process_or_docs |  |
| MON-01 | Monsters, village defence, bounties and monster goods: skeletons under | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| MP-01 | Player-hosted multiplayer: two-player LAN milestone, host-authoritativ | IMPLEMENTED ON TASK BRANCH | NOT TESTED | traced | net_guest.gd, net_host.gd |
| MP-ADOPTION-AGENCY | Adoption agency concept (future, separate design item) | NOT STARTED | NOT TESTED | process_or_docs |  |
| MP-ARCH | Multiplayer architecture approved in principle: one authoritative simu | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| MP-INTERACT-01 | Release blocker: player-to-player selection and interaction work for h | INTEGRATED | INTEGRATION VERIFIED | traced | mp_interact_shot.gd, mp_interact_ui_test.gd, multiplayer_c_test.gd, net_host.gd |
| MP-MASTER | Full player-hosted multiplayer as the next milestone after Build 19 (b | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| MP-PLAYER-FAMILY | Children of player-to-player marriages: biological (male and female) a | INTEGRATED | TARGETED TESTS PASSED | traced | desk_test.gd, gen_v22_family_fixture.gd, multiplayer_c_test.gd, net_family_test.gd |
| MUSIC-18 | Game music from the owner's three songs (Prosperous Village, Sunrise o | INTEGRATED | TARGETED TESTS PASSED | traced | audio_test.gd |
| OD01-QUEST | Retire the fixed-reward quest 'A shift in the mine' (8 coins for 6 iro | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| OPS-01 | Resolve PR #1 as routine maintenance: inspect, compare with staging, p | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| ORE-PLACE-01 | Natural ore evidence and finds kept out of the developed village footp | INTEGRATED | INTEGRATION VERIFIED | traced | discovery_test.gd, prospecting_test.gd |
| OWN-01 | Asset integration pipeline (skill, policy, registry, scaling standard, | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| OWN-03 | Calendar (8-day year), human aging, explicit family links, heirs from | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: aging_test and 32 more |
| OWN-04 | Village generator v6, fixed village, save v13 refusal | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: village refusal in save tests (gen and version refusal) |
| OWN-05 | Overworld (B8-011) | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: overworld_test, water_test, region_geography_test |
| OWN-06 | Living Forest tree lifecycle | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-07 | Flowers/berries walkable and gatherable | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-08 | Post-audit remediation (SaveStore, tests.yml, release gates, stable te | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| OWN-10 | Queue + parallel agents; resource manifest, Gather mode, journal page | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-11 | Continuous development; reeve employment | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: job_board_test |
| OWN-13 | Windows exe icon | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| OWN-14 | Interiors roof fade, sleepers reachable | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-15 | Property phases 1-2, construction, helpers, households split | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: 15 suites (construction, founding, ownership) |
| OWN-16 | GitHub workflow; work preservation; off-machine copies; backup branch | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| OWN-18 | Inventory tabs, six gear slots, tavern food theft, stealing, pickpocke | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-19 | Quest markers; Fireball storyline; side quests; busy-villager bubbles | PARTIALLY IMPLEMENTED | NOT TESTED | unverified_no_test_found |  |
| OWN-20 | Trees walk-under; heir kit; journal book | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-22 | Platforms: Android first then PC; touch/gamepad/KBM auto-detected; set | PARTIALLY IMPLEMENTED | NOT TESTED | unverified_no_test_found |  |
| OWN-23 | UI recolour brown; flat UI pack buttons; Kenney prompts | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-25 | Attack mode; blood splats; readable phone text | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-26 | Animal breeding, hunger, livestock as meat, wild animals hunted | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-27 | Manor government B3 | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| OWN-28 | Living world intent; Morris world; ordinary inhabitant; magic learnabl | PARTIALLY IMPLEMENTED | NOT TESTED | unverified_no_test_found |  |
| P21-00 | Expansion 21 phase 1: government architecture audit (what exists, work | INTEGRATED | NOT TESTED | traced | recorded in the register |
| P21-01 | Expansion 21 phase 1: isolated civic foundations (office ids, holders | INTEGRATED | TARGETED TESTS PASSED | traced | civic_records_test.gd, economy_sim.gd |
| P21-02 | Expansion 21 phase 1: political decision architecture map (owner syste | INTEGRATED | NOT TESTED | traced | recorded in the register |
| P21-MAYOR | Elected mayor: elected by established adult residents who are also eli | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PAR-00 | The player is a villager: one set of world rules for player and villag | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| PAR-01 | OD-18.1: villagers develop skills exactly as the player does | INTEGRATED | INTEGRATION VERIFIED | traced | economy_model_test.gd, farming_test.gd, home_test.gd, materials_b25_test.gd |
| PAR-01A | Starting experience only at world creation, from a plausible occupatio | INTEGRATED | INTEGRATION VERIFIED | traced | experience_test.gd, parity_test.gd |
| PAR-01B | Career changes neither grant nor reset experience | INTEGRATED | INTEGRATION VERIFIED | traced | parity_test.gd |
| PAR-01C | Experience comes from activities, whatever the occupation | INTEGRATED | INTEGRATION VERIFIED | traced | parity_test.gd |
| PAR-02 | OD-18.2: one trade eligibility rule (the trader's coin reserve) for pl | INTEGRATED | INTEGRATION VERIFIED | traced | start_test.gd, world_test.gd |
| PAR-02A | OD-19: a dynamic, necessity-based reserve in place of fixed coin floor | INTEGRATED | INTEGRATION VERIFIED | traced | od16_test.gd, regions_test.gd, reserve_test.gd |
| PAR-03 | OD-18.3: villagers recover health by the player's rest model | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, od16_test.gd, world_test.gd |
| PAR-04 | OD-18.4: villagers can craft every recipe the player can, under the sa | INTEGRATED | INTEGRATION VERIFIED | traced | crafts_test.gd, parity_test.gd, stone_test.gd |
| PAR-05 | OD-18.5: crime awareness by legitimate means only, the same for assaul | INTEGRATED | INTEGRATION VERIFIED | traced | family_first_test.gd, play_test.gd, start_test.gd, world_test.gd |
| PERF-01 | Simulation performance audit: measured explanation of the runtime grow | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| PERF-02 | Profile a representative 10-day run by subsystem (npc_brain decisions, | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd |
| PERF-03 | Determinism gate for optimizations: baseline fingerprints, then identi | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, le07_gates_test.gd, recorder_neutrality_test.gd |
| PERF-04 | Small, measured, low-risk optimizations (indexes or caches for NPC sca | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| PERF-05 | Parallel seeds: two seeds as separate processes with isolated save, te | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| PERF-06 | Long-simulation checkpoint and resume: evaluate design and determinism | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | sim_probes.gd |
| PET-01 | Taming small wild animals as pets (foxes, wolves, rabbits): with their | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PICK-01 | A caught pickpocket raises a witness report through World.witness (OD- | INTEGRATED | TARGETED TESTS PASSED | traced | world_test.gd |
| PIT-02 | Larger and deeper open pits, strata, spiral and switchback ramps (MIN- | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PL1-01 | Settings > Controls exit freezes game | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | wiki_test.gd |
| PL1-02 | One tabbed Settings with Back | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | wiki_test.gd |
| PL1-03 | Merchant quantity control | INTEGRATED | TARGETED TESTS PASSED | tested_untraced | start_test.gd |
| PL1-04 | Health recovery + Apothecary | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | health_jobs_test.gd |
| PL1-05 | current/max inside bars | INTEGRATED | TARGETED TESTS PASSED | tested_untraced | start_test.gd |
| PL1-06 | Every stone minable, size-based | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | world_test.gd |
| PL1-07 | NPCs sunk into beds/chairs | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | furniture_test.gd |
| PL1-08 | Consumable effects shown everywhere | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| PL1-09 | Gold star over employer | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | health_jobs_test.gd |
| PL1-10 | Player businesses, staged (1-4) | INTEGRATED | TARGETED TESTS PASSED | traced | business_test.gd, business_works_test.gd, farming_test.gd, stalls_test.gd |
| PL1-11 | Google Drive cloud saves (staged) | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | start_test.gd |
| PL1-12 | Red flowering plant not pickable | INTEGRATED | TARGETED TESTS PASSED | traced | crafts_test.gd, world_test.gd |
| PL1-13 | Recognisable stove | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | health_jobs_test.gd |
| PL2-001 | Forge occupancy wrongly blocks | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd, world_test.gd |
| PL2-002 | Chests, locks, lockpicking | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | chests_test.gd |
| PL2-003 | Dialogue text | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| PL2-004 | Animal loot, leather | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | run_tests.gd, world_test.gd |
| PL2-005 | Longer skill trees | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | skills_test.gd |
| PL2-006 | Harvest everywhere | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | world_test.gd |
| PL2-007 | Fields grow, ripen, regrow | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | world_test.gd |
| PL2-008 | Expandable property | INTEGRATED | NOT TESTED | tested_untraced | business_test.gd, property_test.gd |
| PL2-009 | In-game wiki | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | wiki_test.gd |
| PL2-010 | Recognisable sawhorse | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | health_jobs_test.gd |
| PL2-011 | No interactions through walls | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | world_test.gd |
| PL2-012 | Storage UI quantities, focus | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | start_test.gd |
| PL2-013 | Usable furniture | PARTIALLY IMPLEMENTED | NOT TESTED | tested_untraced | furniture_test.gd, run_tests.gd, test_resources.py |
| PL2-014 | Modular house/workshop expansion | INTEGRATED | NOT TESTED | tested_untraced | property_test.gd |
| PL2-015 | Farming, livestock, hand plough | INTEGRATED | TARGETED TESTS PASSED | traced | farming_test.gd, furniture_test.gd, test_resources.py |
| PL2-015-BUYANIMALS | Farming: caravan animals other than the horse (deferred from PL2-015; | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PL2-015-COOPS | Farming: coops and animal shelters (deferred from PL2-015; goes with w | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PL2-015-HIRED | Farming: hired farmhands (deferred from PL2-015; fits LE-03) | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PL2-015-OTHER | Farming: oxen, per-crop art and the rest of the deferred-on-purpose li | NOT STARTED | NOT TESTED | process_or_docs |  |
| PL2-015-TRAP | Farming: trapping (deferred from PL2-015; fits LE-05) | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PL2-015-WATER | Farming: weather and expanded watering, crop and animal loss (deferred | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PROS-18 | Expansion 18 prospective implementation (settlement capability and spe | INTEGRATED | TARGETED TESTS PASSED | traced | capability_metrics.gd, capability_test.gd, caravan_compare.gd, census.gd |
| PROS-19 | Expansion 19 prospective implementation (personal memory, subjective j | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, judgment_bonds_test.gd, judgment_guard_save_test.gd, judgment_live_test.gd |
| PVG-01 | Procedural villages: expansion-aware house placement (footprint, parce | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PVG-02 | Procedural villages: realistic medieval density and variation (compact | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PVG-03 | Procedural villages: viable long-term housing options per home where p | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PVG-04 | Procedural villages: reserve physical space for potential expansion fo | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PVG-05 | Procedural villages: growth over generations through inhabitants' legi | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PVG-06 | Procedural villages: validation before acceptance (road access, no ill | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| PVG-07 | Procedural villages: deterministic generation and persistence; buildin | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| Q-03 | Resource manifest and registry (INT-067) | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| Q-04 | Resources & Gathering journal page | INTEGRATED | TARGETED TESTS PASSED | device_or_human | ['phone'] |
| Q-05 | Reeve employment, real jobs, NPCs same rules (INT-066) | INTEGRATED | INTEGRATION VERIFIED | indirect | indirect: 9 suites (reeve, manor work) |
| Q-06 | Long-duration simulations 10/30/100/365 | INTEGRATED | INTEGRATION VERIFIED | unverified_no_test_found |  |
| Q-08 | Resource depletion and wildlife sustainability | IMPLEMENTATION BLOCKED | NOT TESTED | not_built | not built yet: no test expected |
| Q-10 | Hot Attic Games read-only registry | IMPLEMENTATION BLOCKED | NOT TESTED | not_built | not built yet: no test expected |
| REC-001 | Adoption and orphan guardianship (NPCs and the player) | INTEGRATED | INTEGRATION VERIFIED | traced | family_test.gd |
| REC-003 | Android builds target API 36 (Hot Attic Games standing platform policy | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| REC-004 | Merge the Game Designer ('Bob') corrected spec into the project docs a | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| REC-005 | Working title 'The Well'; repository, package and identifiers stay My | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| REC-006 | Castles, dungeons and caves in the world | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| REC-007 | Several settlements (villages, towns, cities) with their own economies | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| REC-008 | Near/far simulation tiers (detailed near the player, abstract far away | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| REC-009 | Combat style: real-time aimed attacks, melee combos and abilities on c | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| REC-011 | Main storyline after the first story quest (side quests now, story lat | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| REC-012 | Tiny Ranch pack: on hold by the owner, not cancelled | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| REC-013 | Need-based maintenance (wear) model and the other unanswered job-board | INTEGRATED | INTEGRATION VERIFIED | tested_untraced | job_board_test.gd |
| REC-014 | Revisit the settlement, agriculture, food, resource, population and tr | NOT STARTED | NOT TESTED | process_or_docs |  |
| REC-017 | Bring stale project documents up to date (handoff, plan, game design, | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| REC-19 | Build 19 Simulation Flight Recorder: full-scope interaction, decision, | INTEGRATED | TARGETED TESTS PASSED | traced | economy_sim.gd, recorder_test.gd |
| REC-DIAG | Use the flight recorder now for autonomous simulation analysis: progre | INTEGRATED | INTEGRATION VERIFIED | traced | recorder_test.gd, test_sim_gate.py, till_ownership_test.gd |
| REC-STORE | Recorder keeps every decision's alternatives and factors in full; no r | INTEGRATED | TARGETED TESTS PASSED | traced | recorder_test.gd |
| RECON-01 | Reconcile overlaps: one calculation for tolerance (temperament life sh | INTEGRATED | TARGETED TESTS PASSED | traced | economy_foundation_test.gd, economy_model_test.gd, judgment_live_test.gd, judgment_personality_test.gd |
| REG-BUY-01 | The village buys food and other goods from the five settlements (villa | INTEGRATED | INTEGRATION VERIFIED | traced | luxury_test.gd, regional_food_test.gd |
| REG-BUY-P1 | Settlement food-selling policy (REG-BUY-01), owner approved: (1) the t | INTEGRATED | INTEGRATION VERIFIED | traced | regional_food_test.gd, settle_food_test.gd |
| REG-COURIER-01 | Connect courier booths, routes and special deliveries to the five sett | INTEGRATED | INTEGRATION VERIFIED | traced | courier_live_test.gd, economy_sim.gd |
| REG-DEMO-01 | Off-map settlement demographics under the village's life rules: member | INTEGRATED | INTEGRATION VERIFIED | traced | party_test.gd, settlement_life_test.gd |
| REG-EVAL-01 | After REG-PARTY-01, REG-BUY-01, REG-COURIER-01 and REG-DEMO-01, evalua | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| REG-INV-01 | Regional economy investigation: Higham's treasury decline, village sus | INTEGRATED | TARGETED TESTS PASSED | traced | regions_test.gd |
| REG-PARTY-01 | One trading-party interface over the five settlements (trader, busines | INTEGRATED | INTEGRATION VERIFIED | traced | courier_test.gd, party_test.gd |
| REGION-NAV-01 | Regional economy, world navigation, envoys and independent inter-villa | INTEGRATED | TARGETED TESTS PASSED | traced | atlas_test.gd, crafts_test.gd, economy_sim.gd, envoy_test.gd |
| REL18-DET | Build 18 release gate: Determinism gate re-recorded on Build 18 code ( | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| REL18-DEVICE | Build 18 release gate: Device and owner playtest of every player-facin | NOT STARTED | NOT TESTED | process_or_docs |  |
| REL18-EXPORT | Build 18 release gate: Android, Windows and Linux packages from one co | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| REL18-LONGRUN | Build 18 release gate: Conservation and long runs: one 365-day run per | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| REL18-OWNER | Build 18 release gate: The owner's approval to publish a Build 18 dist | NOT STARTED | NOT TESTED | process_or_docs |  |
| REL18-PACKAGE | Build 18 packaging gate: no Build 18 test package until every punch-li | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| REL18-SAVE | Build 18 release gate: Save compatibility: a real Build 17 save loads | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| REL18-SUITES | Build 18 release gate: All automated suites pass on the final Build 18 | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| REL18-WIKI | Build 18 release gate: WIKI-01 release gate: new and changed mechanics | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| REQ-CTRL-01 | One authoritative requirements and decision register with separate sta | INTEGRATED | INTEGRATION VERIFIED | traced | test_requirements.py |
| REQ-CTRL-02 | Requirements recovery audit: dry run, immutable sources, conflict and | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| ROAD-03 | Expansion development priority 2026-10-24: 20 Living Economy, 21 Polit | IMPLEMENTED ON TASK BRANCH | NOT TESTED | unverified_no_test_found |  |
| ROOMS-18 | Inner doorways between joined house rooms, and the two survey plots re | INTEGRATED | INTEGRATION VERIFIED | traced | chapel_test.gd, property_test.gd, test_village.py |
| SAVE-00 | Save continuity across separate test builds (Android reinstall): user- | INTEGRATED | TARGETED TESTS PASSED | tested_untraced | save_transfer_test.gd |
| SAVE-01 | Inspect and document the current save architecture before modifying it | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| SAVE-02 | A stable save identity independent of build numbers (requirement 2) | INTEGRATED | TARGETED TESTS PASSED | traced | start_test.gd |
| SAVE-03 | Explicit save-schema versioning and forward migration from older suppo | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| SAVE-04 | Back up the original before migrating, validate the migrated save befo | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| SAVE-05 | A clear way to reconnect to an existing save after an Android reinstal | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| SAVE-06 | The same versioning and migration principles on Windows and Linux (req | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| SAVE-07 | Migration tests over persistent world data: terrain changes, resources | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| SAVE-08 | Preserve unknown or future data where practical; no claim of backward | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| SAVE-09 | An independently recoverable backup and documented recovery instructio | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| SEED-01 | Seed and propagation audit: crops, fruit trees, berry bushes, flowers | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| SEED-02 | Planting consumes real seed or propagation material for every plant ty | INTEGRATED | TARGETED TESTS PASSED | traced | chapel_test.gd, farming_test.gd |
| SEED-03 | Perennials (fruit trees, berry bushes) survive harvest and bear again | INTEGRATED | TARGETED TESTS PASSED | traced | run_tests.gd, start_test.gd |
| SEED-04 | Households save planting material from their own harvests | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| SET-A | Settlement expansion phase A: Design and ledger: requirement ids, cros | INTEGRATED | TARGETED TESTS PASSED | traced | profile_test.gd, settlement_test.gd |
| SET-B | Settlement expansion phase B: Settlement capability model: per-industr | INTEGRATED | TARGETED TESTS PASSED | traced | profile_test.gd, settlement_test.gd |
| SET-C | Settlement expansion phase C: Abstract regional economy: off-map settl | INTEGRATED | INTEGRATION VERIFIED | traced | caravan_compare.gd, economy_sim.gd, regions_sim.gd, regions_test.gd |
| SET-C-FIVE | Five off-map settlements of mixed kinds, each a simulated economy (SET | INTEGRATED | INTEGRATION VERIFIED | traced | regions_test.gd |
| SET-C-SIM | Off-map settlements as lighter-detail simulated economies: households, | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, regions_sim.gd, regions_test.gd |
| SET-D | Settlement expansion phase D: Settlement development: growth and decli | INTEGRATED | TARGETED TESTS PASSED | traced | regions_sim.gd, settlement_development_test.gd |
| SET-D-MULTIGEN | Multigenerational verification of settlement development (SET-D) over | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| SET-E | Settlement expansion phase E: Actual inter-settlement network: persist | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| SFX-18 | Sound effects and ambience from the owner's Cozy RPG SFX pack (ambienc | INTEGRATED | TARGETED TESTS PASSED | traced | audio_test.gd |
| SHOP-01 | Skilled businesses sell what they produce or stock and buy useful good | INTEGRATED | TARGETED TESTS PASSED | traced | economy_model_test.gd, world_test.gd |
| SIM-B17 | SIM-01 in Build 17: one monitored longest run per seed, checkpoints fo | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| SIM-GATE-01 | Permanent pre-build simulation, flight recorder and Excel quality gate | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, live_export_test.gd, recorder_test.gd, sim_probes.gd |
| SJD-A | Judgment expansion Gate A: Build 16 stabilization and baseline (seeds, | INTEGRATED | NOT TESTED | process_or_docs |  |
| SJD-B | Judgment expansion Gate B: architecture audit (Godot services, relatio | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| SJD-C | Judgment expansion Gate C: isolated prototype (event catalog, beliefs, | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| SJD-D | Judgment expansion Gate D: decision prototype (factor registry, utilit | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| SJD-E | Judgment expansion Gate E: first gated integration in one low-risk dom | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| SJD-F | Judgment expansion Gate F: incremental rollout (trade, aid, friendship | INTEGRATED | TARGETED TESTS PASSED | traced | judgment_live_test.gd |
| SJD-G | Judgment expansion Gate G: full soak and calibration: 100/365-day comp | INTEGRATED | INTEGRATION VERIFIED | traced | bandit_ai_test.gd, economy_sim.gd, gen_b24_judgment_fixture.gd, judgment_soak_test.gd |
| SKILL-TRADES-18 | Carpentry, Masonry and Tanning skills, started from each person's Craf | INTEGRATED | INTEGRATION VERIFIED | traced | trade_skills_test.gd |
| STALL-01 | Stalls are built by anyone on cleared land through the construction sy | INTEGRATED | INTEGRATION VERIFIED | traced | stalls_test.gd |
| STALL-02 | A stall's own inventory: goods are moved into it for sale and are in o | INTEGRATED | INTEGRATION VERIFIED | traced | stalls_test.gd |
| STALL-03 | OPEN STALL: the stall sells unattended to real buyers through the exis | INTEGRATED | INTEGRATION VERIFIED | traced | stalls_test.gd |
| STALL-04 | CLOSE STALL: sales stop, the unsold goods stay in the stall, the sessi | INTEGRATED | INTEGRATION VERIFIED | traced | stalls_test.gd |
| STALL-05 | The realm's 5% commission on each session's actual sales, through real | INTEGRATED | INTEGRATION VERIFIED | traced | business_test.gd, economy_sim.gd, run_tests.gd |
| STALL-06 | Villager households build, stock, open, close and restock stalls by th | INTEGRATED | TARGETED TESTS PASSED | traced | stalls_test.gd |
| STONE-01 | Raw quarry stone and finished building blocks as separate items: stone | INTEGRATED | TARGETED TESTS PASSED | traced | housing_test.gd, play_test.gd, run_tests.gd, settlement_test.gd |
| STONE-02 | Personal-use stone dressing by any villager (own house or repairs), sa | INTEGRATED | TARGETED TESTS PASSED | traced | stone_test.gd |
| STONE-03 | Materials by kind of work: major masonry reconstruction in blocks and | INTEGRATED | TARGETED TESTS PASSED | traced | stone_test.gd |
| STONE-04 | Skill-based stone dressing efficiency with conserved waste (one rule f | INTEGRATED | TARGETED TESTS PASSED | traced | stone_test.gd |
| STONE-05 | Stoneworking skill: a distinct skill in the existing skill system that | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| STONE-06 | Iron chisel: smith-made, worn by use, needed with the mallet to dress | INTEGRATED | TARGETED TESTS PASSED | traced | crafts_test.gd, parity_test.gd, play_test.gd, stone_test.gd |
| SYNC-17 | Synchronize Expansions 18 and 19 one way with the Build 17 baseline cd | INTEGRATED | INTEGRATION VERIFIED | traced | settlement_test.gd |
| TAILOR-18 | Tailor: a village NPC service selling the two backpack upgrades | INTEGRATED | INTEGRATION VERIFIED | traced | inventory18_test.gd, tailor_barber_test.gd |
| TEST-AUDIT-01 | Full test regimen audit (inventory, validity, mutation sampling, gates | NOT STARTED | NOT TESTED | tested_untraced | save_continuity_test.gd, water_test.gd, workplace_reach_test.gd |
| TEST-GOV-01 | Permanent testing governance: verify the test itself | NOT STARTED | NOT TESTED | tested_untraced | audio_test.gd, char_create_test.gd, character_look_test.gd, furniture_test.gd |
| TIME-01 | Time-system audit: every timed system's duration, unit, meaning, calen | INTEGRATED | INTEGRATION VERIFIED | process_or_docs |  |
| TIME-02 | Explicit time units in configuration and code; one shared conversion l | INTEGRATED | INTEGRATION VERIFIED | traced | aging_test.gd |
| TIME-04 | Player starvation damage follows the villagers' rule (time-audit defec | INTEGRATED | INTEGRATION VERIFIED | traced | world_test.gd |
| TRADE-01 | Trade-specific purchasing at counters through the shared trade rules ( | INTEGRATED | TARGETED TESTS PASSED | traced | world_test.gd |
| TRADE-AXE-01 | Playtest: cannot buy Clement Ward's axe (listed 45) holding 47 coins | INTEGRATED | INTEGRATION VERIFIED | traced | inventory18_test.gd |
| TRADE-CREDIT | Barter and credit with trust: goods-for-goods deals and recorded debts | INTEGRATED | TARGETED TESTS PASSED | traced | credit_test.gd, economy_sim.gd |
| TRADE-UI-02 | Contract proposal's answer shown in view | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| TREAS-01 | The manor treasury as the village reserve: fees in, real purchases out | INTEGRATED | INTEGRATION VERIFIED | traced | stalls_test.gd, treasury_test.gd |
| UI-HUD-01 | HUD status panel too large: shrink and move the date line | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| UI-HUNGER-01 | Hunger icon becomes a drumstick | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| UI-PROGRESS-01 | Progress bar visible on light and dark ground | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| UI-WIKI-01 | Village Encyclopedia: navigable, searchable wiki window | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| VAL-AGENT-01 | One temporary read-only Validation and Integration Agent for Build 25 | INTEGRATED | NOT TESTED | process_or_docs |  |
| VER-CON-50ORE | Focused contract verification: a 50-iron-ore quantity contract with ex | INTEGRATED | INTEGRATION VERIFIED | traced | contract_50ore_test.gd |
| VIS-ANIMAL-01 | Stray fragments above animals removed at the source | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| VIS-AXE-01 | Lumberjack axe: believable chop, blade never through the head | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| VIS-CROP-01 | Ripe wheat recognizable; planted, growing, mature, harvested look dist | INTEGRATED | INTEGRATION VERIFIED | traced | farming_test.gd, run_tests.gd |
| VIS-DOOR-01 | Doorway transition: characters no longer pass under a closed door | INTEGRATED | INTEGRATION VERIFIED | traced | polish_p2_test.gd, run_tests.gd |
| VIS-STEPS-01 | Steps cut through rock need real step art | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| VIS-TREE-02 | Tree fragments: no stray old tree pieces; stages and stumps draw corre | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| VP-01 | Living village politics: offices, individual NPC voting, elections, ci | NOT STARTED | NOT TESTED | tested_untraced | civic_records_test.gd |
| WDR-001-C | Comply with World Design Rule 1: Material Interdependency | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| WDR-002-C | Comply with World Design Rule 2: Professional Interdependency | INTEGRATED | INTEGRATION VERIFIED | traced | interdependency_test.gd |
| WDR-003-C | Comply with World Design Rule 3: Meaningful Recipes | NOT STARTED | NOT TESTED | process_or_docs |  |
| WDR-004-C | Comply with World Design Rule 4: Economic Consequences | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| WDR-005-C | Comply with World Design Rule 5: Living World Independence | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| WDR-006-C | Comply with World Design Rule 6: Maintain the Existing Interlocking Sy | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| WDR-007-C | Comply with World Design Rule 7: Automated Compliance | INTEGRATED | INTEGRATION VERIFIED | traced | test_check_materials.py |
| WDR-008-C | Comply with World Design Rule 8: Player Knowledge and Wiki | INTEGRATED | TARGETED TESTS PASSED | device_or_human | ['phone', 'controller'] |
| WDR-009-C | Comply with World Design Rule 9: Emergent Gameplay | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| WDR-010-C | Comply with World Design Rule 10: Depth Without Obscurity | PARTIALLY IMPLEMENTED | NOT TESTED | device_or_human | ['phone', 'controller'] |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | INTEGRATED | TARGETED TESTS PASSED | traced | aspiration_test.gd, economy_sim.gd |
| WDR-012-C | Comply with World Design Rule 12: NPC Competition and Economic Rivalry | INTEGRATED | TARGETED TESTS PASSED | traced | competition_test.gd, home_test.gd, stone_test.gd |
| WDR-013-C | Comply with World Design Rule 13: Finite Resources and Actual Consumpt | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| WDR-014-C | Comply with World Design Rule 14: Graveyards, Ancestry, and NPC Legacy | NOT STARTED | NOT TESTED | process_or_docs |  |
| WDR-015-C | Comply with World Design Rule 15: Political Authority, Social Hierarch | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| WDR-016-C | Comply with World Design Rule 16: Bandit Factions, Criminal Careers, a | NOT STARTED | NOT TESTED | process_or_docs |  |
| WDR-017-C | Comply with World Design Rule 17: Generational Memory and Living Histo | NOT STARTED | NOT TESTED | process_or_docs |  |
| WDR-018-C | Comply with World Design Rule 18: Protected Ecological Continuity | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| WDR-019-C | Comply with World Design Rule 19: Living Political Agency and Democrat | NOT STARTED | NOT TESTED | process_or_docs |  |
| WDR-020-C | Comply with World Design Rule 20: Autonomous Housing | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| WDR-021-C | Comply with World Design Rule 21: Household Succession and Family Care | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| WDR-022-C | Comply with World Design Rule 22: classify every finding as defect, le | PARTIALLY IMPLEMENTED | NOT TESTED | process_or_docs |  |
| WEAPON-CATALOG-01 | Every weapon on the master weapons sheet can be made at the smithy at | INTEGRATED | TARGETED TESTS PASSED | traced | gear_catalogue_test.gd, test_gear_catalogue.py, wiki_test.gd |
| WEAPON-VISIBLE-01 | An equipped weapon is drawn on the character while walking, and attack | INTEGRATED | TARGETED TESTS PASSED | traced | gear_catalogue_test.gd |
| WEATHER-01 | Dynamic weather and natural disasters expansion: thunderstorms, rainst | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| WIKI-B17 | Build 17 documentation reconciliation: in-game wiki pages and develope | PARTIALLY IMPLEMENTED | NOT TESTED | traced | wiki_test.gd |
| WORLD-LIFE-01 | The countryside is empty of people and animals; its trails lead nowher | INTEGRATED | INTEGRATION VERIFIED | traced | countryside_test.gd |
| WR-01 | Protected wildlife breeding refuges, offspring cohorts and dispersal | INTEGRATED | TARGETED TESTS PASSED | traced | refuge_test.gd |
| WR-02 | Grazers in a wood all stop eating while the wood is over its grass cap | INTEGRATED | TARGETED TESTS PASSED | traced | wildlife_test.gd |
| X18-CAPCOMP | Capability composition: workforce capability from local experience, ef | INTEGRATED | INTEGRATION VERIFIED | traced | experience_test.gd, profile_test.gd |
| X18-CAPNUM | Capability modifiers: the bounded model (revised_bounded) for six indu | INTEGRATED | INTEGRATION VERIFIED | traced | capability_metrics.gd, capability_test.gd |
| X18-Q12 | Implement Q18-12 transport: flat-rate fees on regular routes or schedu | INTEGRATED | INTEGRATION VERIFIED | traced | courier_live_test.gd, courier_test.gd, courier_window_shot.gd, economy_sim.gd |
| X18-Q12-BOOTH | Courier booths in each city, village and major business, serving regul | INTEGRATED | INTEGRATION VERIFIED | traced | courier_live_test.gd, courier_test.gd |
| X18-Q12-POST | Courier contract popup like online postage (dropdowns: quantity, item, | INTEGRATED | INTEGRATION VERIFIED | traced | courier_live_test.gd, courier_test.gd, courier_window_shot.gd, multiplayer_c_test.gd |
| X18-Q13 | Implement Q18-13 signing: small agreements unsigned; formal contracts | INTEGRATED | INTEGRATION VERIFIED | traced | contract_sign_test.gd, courier_live_test.gd, economy_sim.gd |
| X18-SIM | Comparative capability simulations (baseline, conservative, moderate, | INTEGRATED | TARGETED TESTS PASSED | traced | capability_metrics.gd, capability_test.gd, economy_sim.gd |
| X18-STONECUT | Professional stonecutter: an independent trade and business that dress | INTEGRATED | TARGETED TESTS PASSED | traced | stone_test.gd |
| X19-FOUND | Expansion 19 foundations round: personality, relationship history and | INTEGRATED | TARGETED TESTS PASSED | traced | judgment_bonds_test.gd, judgment_live_test.gd, judgment_personality_test.gd |
| X19-FOUND-BONDS | Relationship history and reconciliation: resentment softens with growt | INTEGRATED | INTEGRATION VERIFIED | traced | judgment_bonds_test.gd, judgment_live_test.gd |
| X19-FOUND-FAMREP | Family reputation: known family history colours descendants' impressio | INTEGRATED | INTEGRATION VERIFIED | traced | judgment_bonds_test.gd |
| X19-FOUND-PERS | Personality framework: evolving traits, soft limits, learning from cos | INTEGRATED | INTEGRATION VERIFIED | traced | judgment_live_test.gd, judgment_personality_test.gd |
| X19-MISINFO | Deliberate misinformation and its correction: NPCs may fabricate false | INTEGRATED | TARGETED TESTS PASSED | traced | judgment_x19_test.gd |
| X19-SCOPE | Expansion 19 ships complete: judgment, personality, relationships, fam | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X19-STORY-LIFE | Family stories: reputation extends through a recognized family name, o | INTEGRATED | TARGETED TESTS PASSED | traced | judgment_x19_test.gd |
| X20-B24-F1 | Review finding 1: a settlement business (its trader) kept operating wi | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-F2 | Review finding 2: TILL-D1 not applied when a household's last members | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-F3 | Review finding 3: a leaving trader's stall takings not returned to tha | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-F4 | Review finding 4: another player's one sword blow struck twice on a gu | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-F5 | Review finding 5: a phantom NPC blow landed when the NPC came into vie | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-F6 | Review finding 6: stall commission recorded at the wrong moment (not a | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-F7 | Review finding 7: a storefront or counter till did not go to its previ | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-F8 | Review finding 8: the recorder's 'starved with means' counted village | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-REMED | Build 24 review remediation and Expansion 20 integration: per-finding | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-B24-REVIEW | Build 24 code review: eight findings fixed in Expansion 20 at their un | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-BACKGROUND | Expansion 20 continues in the background within approved decisions (Up | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| X20-BANDIT-AI | Bandit situational awareness, threat assessment and self-preservation | INTEGRATED | TARGETED TESTS PASSED | traced | bandit_ai_test.gd, bandit_diag.gd, economy_sim.gd, recorder_test.gd |
| X20-CAREER-AUDIT | Audit career progression, NPC ambition and skilled employment | IMPLEMENTED ON TASK BRANCH | NOT TESTED | process_or_docs |  |
| X20-CHAPEL-FIX | Chapel economy correction: voluntary, affordable, individually decided | INTEGRATED | NOT TESTED | traced | chapel_test.gd, economy_sim.gd |
| X20-CHAPEL-INTEGRATE | Integrate the chapel correction and the gossip fix into wip/expansion2 | INTEGRATED | NOT TESTED | unverified_no_test_found |  |
| X20-CHECKPOINT | Build 24: private three-platform checkpoint of Expansion 20 groundwork | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-COMPLETE | Complete Expansion 20 (Living Economy) before Expansion 21: REC-DIAG, | IN DEVELOPMENT | NOT TESTED | unverified_no_test_found |  |
| X20-ECON-AFFORD | Re-evaluate the unaffordable bids by interval, category, household con | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| X20-ECON-AUDIT | Audit which of 20 economic progression systems the year-long simulatio | IMPLEMENTED ON TASK BRANCH | NOT TESTED | process_or_docs |  |
| X20-ECON-FIREWOOD | Re-evaluate firewood shortages by season, household, income and period | INTEGRATED | NOT TESTED | traced | recorded in the register |
| X20-ECON-LONGITUDINAL | Longitudinal economic evaluation framework (snapshots days 1/30/90/180 | NOT STARTED | NOT TESTED | tested_untraced | economy_sim.gd |
| X20-ECON-MATURE | Economic maturation: evaluate the economy as a developing system | NOT STARTED | NOT TESTED | not_built | not built yet: no test expected |
| X20-ECON-MATURE-REPORT | Economic maturation report with the 16 required charts and the executi | NOT STARTED | NOT TESTED | process_or_docs |  |
| X20-ECON-SUSTAIN | Build 25 economic sustainability analysis: per-run checkpoint analysis | IMPLEMENTED ON TASK BRANCH | NOT TESTED | process_or_docs |  |
| X20-FINAL | Expansion 20 final validation, flight-recorder and black-box moderniza | INTEGRATED | INTEGRATION VERIFIED | traced | economy_sim.gd, recorder_test.gd, sim_probes.gd, test_sim_gate.py |
| X20-JUDG-C1 | Judgment integration audit and calibration: every NPC decision system | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| X20-JUDG-C2 | Second-hand memories of assault and lesser offences fade by existing m | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| X20-JUDG-C3 | Wrongdoing counted by incident: a continuous fight is one incident wit | INTEGRATED | TARGETED TESTS PASSED | traced | judgment_incident_test.gd |
| X20-JUDG-C5 | Mixed feelings in real decisions: dislike, respect for ability, fear, | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| X20-MIGRATE | Free, individual migration from off-map settlements (REG-X20-D1): remo | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-MP-ECON-INTEGRITY | When multiplayer and the economy systems are integrated, verify that d | INTEGRATED | INTEGRATION VERIFIED | traced | net_econ_integrity_test.gd, net_host.gd |
| X20-SETTLE-FOOD | Live settlement-to-settlement food purchasing (REG-BUY-D1 approval): o | INTEGRATED | INTEGRATION VERIFIED | traced | settle_food_test.gd |
| X20-SETTLE-REOPEN | A closed settlement business reopens (or is re-established) when a hou | INTEGRATED | INTEGRATION VERIFIED | traced | settle_review_test.gd |
| X20-SPLASH | Opening splash: the Hot Attic Games studio logo shows when the game st | INTEGRATED | TARGETED TESTS PASSED | traced | recorded in the register |
| X20-TELL-GUARD | Defect: JudgmentStore._tell reads a story the teller forgot during the | INTEGRATED | NOT TESTED | traced | judgment_x19_test.gd |
| X20-TILL-KEEP | A household that moves away or gives up a house takes its storefront t | INTEGRATED | INTEGRATION VERIFIED | traced | recorded in the register |
| X20-TRADER-PAY-INV | Investigate why reopened settlement trader households fail to sustain | PARTIALLY IMPLEMENTED | NOT TESTED | traced | economy_sim.gd |
| X20-TXN-REPLAY-FIELDS | Latent defect: the transaction authority's saved past results keep onl | INTEGRATED | INTEGRATION VERIFIED | traced | le04_test.gd |
| X20-WEAR-TRANSFER | Defect: a tool's saved wear does not travel when the tool changes hand | INTEGRATED | INTEGRATION VERIFIED | traced | wear_transfer_test.gd |
| XAUDIT-01 | Cross-expansion preservation audit of Expansions 19-23 against the rep | IMPLEMENTED ON TASK BRANCH | NOT TESTED | process_or_docs |  |
| XEXPL-01 | Decision Explainability: a shared, deterministic, compact explanation | NOT STARTED | NOT TESTED | tested_untraced | family_first_test.gd |
