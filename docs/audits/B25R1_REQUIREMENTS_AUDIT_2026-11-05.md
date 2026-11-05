# Build 25 / Build 25 Revision 1 requirements audit (read-only)

- **Date:** 2026-11-05. **Auditor:** read-only subagent; no code, register or branch changed.
- **Sources:** register `docs/requirements/requirements.json` on `wip/requirements-control` (`306eba7`); code on `origin/wip/b25r1` (head `a995397`);
  `docs/release/build25_reconciliation/COMPLETION_CHECKLIST.md`; handoffs `B25R1_VALIDATION_HANDOFF_2026-11-05.md`, `OVERNIGHT_2026-11-04.md`,
  `PLAYTEST_READINESS_B25R1.md`; design notes on `wip/b25r1` (`HOMESTEADING_B25R1`, `PRESENCE_B25R1`, `REGION_RECONSTRUCTION_B25R1`, `WATER`); GitHub Actions run list for `wip/b25r1`.
- **Scope:** every `kind: approved` record with `target_build` 20 (the register files Build 25 and Revision 1 under Expansion 20; the register's
  "build 25" key is the Weather expansion, so E25-OD-* and WEATHER-01 are **out of scope**) plus all `B25-*`, `B25R1-*`, `EA-01`, `DEMO-01`.
  178 registered records, plus 2 owner-named art tasks with no register id. Decisions (`kind: decision`) are cited, not counted.

## Classes
- **Complete and verified**: acceptance met with evidence (register INTEGRATION VERIFIED / COMPLETE, or a document deliverable delivered).
- **Implemented but unverified**: code present and integrated (on `wip/b25r1` or the Build 25 source), targeted tests pass, but integration-level
  verification on the Revision 1 candidate (gate baseline, 365-day campaign, device check) or a behavioural acceptance item is outstanding.
- **Incomplete**: approved work missing or partial. **Blocked**: cannot close without an owner answer, review or device check.
- **Superseded**: overtaken by an explicit owner decision.

## Counts (178 registered + 2 unregistered = 180)

| Class | Main table (47 + 2) | Appendix (131) | Total |
|---|---|---|---|
| Complete and verified | 2 | 65 | **67** |
| Implemented but unverified | 36 | 51 | **87** |
| Incomplete | 7 | 9 | **16** |
| Blocked (owner) | 3 | 4 | **7** |
| Superseded | 1 | 1 | **2** |
| Not applicable (umbrella, X20-OPEN-ITEMS) | 0 | 1 | **1** |

Caveat on "Complete and verified": the 65 appendix records were verified on earlier SHAs (Builds 18-25). Revision 1 rebuilt the world (overworld
generation 4, hamlets, presence, homesteads, band in the wild), so none is re-verified on a Revision 1 candidate until the gate baseline and
the 365-day campaign run on the final SHA.

## Validation state of `wip/b25r1` (the evidence every row below depends on)

| Run | SHA | Result |
|---|---|---|
| Full suite 41923790388 | 361f364 | 1 failure (net_econ_integrity lossy race), fixed in bfce680; affected suites 41937849606 green (report red only for empty shards, fixed 0161f39) |
| Simulation gate 41923800341 | 361f364 | 32 blocking findings, all baseline differences; recorder neutrality holds (recorded = unrecorded). Treasury difference later traced to the courtship axe-gift loop |
| Axe fix | a995397 (8d05942) | Tests 'only' 41962211717 **success** (od16, relations, gift_quantity); gate **41962208084 in progress**; no full suite on a995397 |
| 365-day campaign 41939383765 | bfce680 | **still running; provisional only** (contains the axe loop; cannot certify a995397) |
| Packages 41939387992 | bfce680 | **failure**: Windows full smoke 0xC0000005 at shutdown (not reproduced in 28 later launches); 71 GDScripts leaked at exit bisected to `overworld_view.gd:441` static cache; fix proposed, **awaiting owner** |
| Gate baseline | none | **not re-recorded** for Revision 1 (must follow a clean gate on the fixed SHA) |

## Main table: owner-named targets and B25/B25R1 records

| id | title | class | evidence | smallest path to completion |
|---|---|---|---|---|
| B25-LE-ACTIVATE-D1 / X20-COMPLETE | Living Economy activation and Expansion 20 completion | Implemented but unverified | `economy.json enabled: true` (b00439f); le07_gates 31/0; Build 25 economy-on flight 41587688728 on c4c3490, 365 d, CRITICAL 0; X20-COMPLETE register IN DEVELOPMENT | Gate 11 ruling (see LE-07); clean R1 gate + 365-day campaign on final SHA; close register |
| LE-07 | Release readiness gates | Blocked | Gates 2,3,5,7,8 passed; 4, 6 on 4b51c92 year; 9 reviewed; **gate 11 (mid-range phone) declared non-blocking by the lead (OD-LE-15 reading), not by the owner**; checklist H2 still asks the owner | Owner ruling or device check on gate 11; gate 1 full suite on the final R1 SHA |
| LE-05 | Construction, ecology, mining, bandits, regional | Implemented but unverified | INTEGRATED / TARGETED; le05_* suites, route_risk 37 | Integration verification on final SHA |
| B25-EMPLOY-IMPL | Skilled employment growth without fixed caps (skill-aware hiring) | Implemented but unverified | 265ddc1; skilled_employment_test 54/0; register NOT TESTED | Year-long employment measure from the R1 campaign; register update |
| B25-CAREER-IMPL | Opportunity-based career advancement | Implemented but unverified | npc_brain.gd blocks since 265ddc1; register tests field empty | Name its tests; campaign evidence |
| B25-CAREER-SYSTEM | Experience->skill->ambition->opportunity chain | Implemented but unverified | Integrated 265ddc1; acceptance needs longitudinal days 1-365 measures (X20-ECON-LONGITUDINAL NOT STARTED) | Longitudinal report from the R1 campaign |
| B25-AMBITION-IMPL | Career ambition (job_choice) on | Implemented but unverified | 7dfd3d5; career_ambition_test, aspiration_test; sim_suite ships it on (726ceeb) | Register tests result; campaign |
| B25-NINE (+D1..D9) | Nine decisions: organic skills and apprenticeship (D1, D8), services, farming, reporting, materials, armour, clothing, juice | Implemented but unverified | Register NOT STARTED is stale: D1/D8 625e362 (experience 79/0, capability tests), D2 8d71c5e, D3 farming 4b51c92, D4 2c364d1, D5-7 48acc91, D9 ba94edd | Fix register; year-long skill progression evidence from campaign |
| B25-BUSINESS-IMPL | Independent business founding | Implemented but unverified | d0dc0d7; business_founding 58-73/0; **no villager founded a business in any run** (30-day, 365-day 41362329381) | Depends on B25-ECON-P1..P5 (owner) or a WDR-022 outcome ruling |
| B25-BIZ-D1..D5 (5 records) | Business accounts, paid employees, cancellation, permanent employment, buy/sell/expand | Implemented but unverified | 908a17e; business_ownership 165, business 160, business_money 37, till_ownership 71, conservation 8, all 0 failures; register NOT TESTED | Register tests; live-run behaviour (same blocker as BIZ-OWN) |
| B25-BIZ-OWN | Business ownership acceptance: NPCs found, buy, sell, hire, expand over a year | Blocked | Acceptance 2 failed in 41362329381 (no venture all year); funnel stops at demand (benches 2-20% busy vs 0.35); B25-ECON-P1..P5 **OPEN** | Owner answers P1..P5, or rules zero founding an acceptable outcome (checklist H1) |
| EMP-PERM-01 | Permanent employment by the player | Implemented but unverified | d0dc0d7, 908a17e; same suites | Device/playtest; register |
| REGION-NAV-01 | Regional economy: villages, map, envoys, inter-village trade | Implemented but unverified | S1-S8 integrated b540971; envoy 31/0, intel 13/0, region_trade 23/0, region_demand 11/0, region_sim 8/0; all in tests.yml shards; R1 reconstruction changed geography since | Ten-question final report on R1 SHA; Android profile (gate 11) |
| (envoy travel, needs/haves, crafter contact) | REGION-NAV-01 S4/S5, checklist A9 | Implemented but unverified | `envoys.gd`: walks via Journeys, interviews every person in `SettlementFolk.people` (keepers, official, crafters), records have/want with source and day into `World.intel_book`; checklist A9 still says TO DO (stale) | Update checklist A9; campaign evidence of envoy interviews |
| (multi-village trade / settlement food trade) | REGION-NAV-01 S6, seed travelers, hamlet walkers | Implemented but unverified | region_trade 23/0, courier_live 148/0 (aba1e7d), hamlet 74/0, regional_food passes (12df4aa script-error guard) | Campaign trade ledgers |
| P21-01 / Q9 (civic records) | Civic foundations, hamlets as civic places under their lord's town | Implemented but unverified | civic switch off by design (Expansion 21 on hold); b905aa9 Q9 policy; civic_records 52/0 | None beyond final-SHA suite (listed in appendix) |
| (save/load continuity and migration) | B25R1-Q5 owner: no migration for R1; old saves refused with message, file kept | Implemented but unverified | 6a1d5b2 fixtures refused; 5cd1765 current save loads exactly, run_tests new-household save passes in 41923790388; homestead_presence mid-build save exact; LE-07 gate 6 (37/37 round trips) only on 4b51c92 | Segment save round trips in the R1 campaign evidence index |
| (economy conservation and long-duration stability) | SIM-01/02, WDR-022 | Implemented but unverified | Build 25: flight 41587688728 365 d CRITICAL 0. R1: axe loop (treasury) found and fixed a995397; 30-day seed 1 now 0 axes bought; recorder neutrality fixed 2677ea7; no R1 run on fixed SHA | Gate 41962208084 clean, re-record baseline, one 365-day campaign on final SHA |
| B25-FINISH-01 | Build 25 completion | Blocked | Build 25 draft built (a459186, run 41666958781, release 432836586); acceptance 2 ("every approved requirement complete") waits on checklist H1-H4 owner answers | Owner answers H1-H4 |
| B25-CLOSE-01 | Closure audit, farming Phase 2 | Implemented but unverified | Audit written; Phase 2 merged 4b51c92; process superseded in practice by FINISH-01 | Close with FINISH-01 |
| B25-CLOSE-02 | Strict-scope close on frozen 4b51c92 | Superseded | Freeze overtaken by owner B25-SCOPE-REGION (register history), register still says PARTIALLY IMPLEMENTED | Mark SUPERSEDED by B25-SCOPE-REGION / B25-FINISH-01 |
| B25-SCOPE-REGION | REGION-NAV-01 mandatory in Build 25 | Implemented but unverified | Register NOT STARTED is stale; REGION-NAV-01 integrated | Register; REGION-NAV-01 validation |
| B25-OVN-0211 | Overnight autonomous development | Implemented but unverified | Register NOT STARTED is stale: Option B 3c7e45b, funnel d6ab686 | Register; consolidated report reference |
| B25-SCOPE-AUDIT | Scope reconciliation audit | Complete and verified | BUILD25_RECONCILIATION.md + IMPLEMENTATION_PLAN.md delivered | Mark complete |
| VAL-AGENT-01 | One read-only validation agent | Complete and verified | Assignment done; D1-D4 fixed 8792886, b18f418; agent stopped | Mark complete |
| FLIGHT-REC-01 | Permanent flight recorder system | Implemented but unverified | Used by 41587688728; recorder 214/0, recorder_neutrality 5/0; flight_lives.py, flight_analyse.py on wip/b25r1 | Close with R1 campaign |
| DEMO-01 | 120-minute demo, Steam promotion, six packages | Implemented but unverified | Register IN DEVELOPMENT stale; checklist I1-I8 DONE (ca27195, 8d31017; demo_test 35/0; Build 25 six-package draft); R1 Windows demo smoke passed in 41939387992 | Register; device check; R1 draft |
| EA-01 | Steam Early Access readiness (~2026-11-24) | Incomplete | NOT STARTED; **target_build unassigned**; centralisation audit and interaction quality pass not done (Revision 1 merges cite it, e.g. walking rule in trips.gd) | Owner places it in a build; run centralisation audit and interaction pass |
| B25R1-001 | Revision 1 umbrella | Incomplete | Children not complete; no R1 private six-package draft (41939387992 failed) | Children; packages on final SHA |
| B25R1-002 | Full interaction outside the village | Implemented but unverified | 10491e7; outside_interact 23/0; owner accepted focused evidence; final integrated check and device playtest pending | Device playtest |
| B25R1-003 | Region map: settlements and roads known; landmarks persist | Implemented but unverified | e7e17d2; region_travel 71/0, overworld 333/0; screenshots looked at | Final-SHA suite; restyle (below) |
| B25R1-004 | Roads and trails: stone, dirt, trail | Implemented but unverified | 9a9e0f0, 0c1aeb3; road_types 14/0 (2431 of 15703 main cells stone) | Final-SHA suite |
| B25R1-005 | Region map controls | Implemented but unverified | e7e17d2; screenshots 1280x720, 2400x1080 | Touch device check |
| B25R1-006 | Tap anywhere to travel | Implemented but unverified | region_travel 71/0 (walk home->Wulstead, save/restore) | Device check |
| B25R1-007 | Unrestricted cosmetic character creation | Implemented but unverified | 932739d; char_create_test 0 failures (117 options x 3 bodies x 8 dirs) | Final-SHA suite |
| B25R1-008 | Visual polish; modal HUD | Implemented but unverified | 932739d; screenshots; region map part overlaps the pending restyle | Restyle; screenshots |
| B25R1-009 | Seed travelers | Implemented but unverified | b329da0; seed_traveler 48/0, run_tests 3602/0 | Campaign |
| B25R1-010 | Homesteading (NPCs and player) | Implemented but unverified | Register IN DEVELOPMENT stale; c137815..5cd1765 merged; homestead 47-49/0, homestead_presence 17/0, player_homestead 40/0. 160-day measure: 0 organic homesteads. **Player homestead cannot build a well** (agent provisional decision, HOMESTEADING_B25R1.md; pen and workshop added e080bc0) | Owner check that the player-well gap is acceptable under B25R1-015; demographic validation in campaign |
| B25R1-011 | Road wear and paving | Implemented but unverified | 9a9e0f0, 40f190e; road_wear 40/0 | Campaign |
| B25R1-012 | Gamepad destination on region map | Implemented but unverified | e66feaf; gamepad_map 19/0 (real joypad events) | Physical controller check |
| B25R1-013 | Youth runaways, bandit recruitment | Implemented but unverified | Register IN DEVELOPMENT stale; 8e1ab51, 2607807; life_decisions 27/0; 0 runaways organically (160-day) | Campaign or labelled targeted scenario |
| B25R1-014 | Wilderness settlements, outlaw communities | Implemented but unverified | bf20dc9, 943b453, a1bb9fc; wilds 69-71/0 (raid walk fixed); design table: raids, defence, water, works, livestock, crafting, members-only market, discovery, allegiance, clan births all "yes" | Campaign (multigenerational, section 11) |
| B25R1-016 | 365-day flight-recorder campaign | Incomplete | Tooling done (194f7d1, 85ef070, flight_lives.py); campaign 41939383765 on bfce680 provisional (axe loop); not yet on final SHA | Clean gate on a995397+, baseline, one campaign, reports A-I |
| B25R1-017 | Water system, credits, compatibility | Implemented but unverified | Register IN DEVELOPMENT stale; 1e9c0c8, 70ec466, 49e78a9 merged 953e750; water 62 goldens; credits fixed c5299cd; weather hooks documented, not built (by directive) | Final-SHA suite; register |
| B25R1-018 | Regional world reconstruction | Incomplete | Merged 1d024dc, 4c419a0, 64be5a2, 0c1aeb3; overworld 333/0. **Bear Hill and the castle knoll not raised ("assessed, not started")**; stone cross withheld, white battlements and fountain lack art (owner Q8 pack pending) | Raise Bear Hill or get an owner ruling; art from owner's pack |
| B25R1-019 | Presence by view range | Implemented but unverified | e66ca18, 711d59d; presence 37/0, homestead_presence 17/0, recorder_neutrality 5/0; CPU measured in container, phone projected | Gate re-baseline; campaign |
| B25R1-020 | Anticipatory crowd management | Implemented but unverified | presence.gd crowd paths, availability locks a970731; soft target measured in the container, **not on Android** as acceptance asks | Android measurement |
| B25R1-022 | Fantasy Lands houses | Incomplete | NOT STARTED; no asset, registry or code reference on wip/b25r1 | Register pack, import at 16 px, palette remap, wall/roof split, place by regional style |
| (no id) Bow.Pixel grass decoration | Owner-listed art task | Incomplete | Pack imported (dd35a2e), atlases 6-7 loaded in MapView, `LOW_GRASS` constant **never used** | Capture in register; place grass in OverworldView |
| (no id) Region map restyle | Owner-listed art task (state file: UIStyle, pad focus on Village tab) | Incomplete | `region_map_view.gd` has no UIStyle reference; last change 1d024dc | Capture in register; restyle; screenshots |

## Register and scope observations (not new requirements)
- No register id for the grass decoration or the region map restyle, and no `B25R1-021` exists (numbering gap): capture-at-once (CLAUDE.md 9a) not met.
- `B25R1-015` (full scope mandatory) is in the register as `kind: rule`, approval `PROPOSED`, though its directive is saved as an owner directive.
- Narrowings without an owner decision, contrary to B25R1-015: player homestead well (agent provisional), Bear Hill not raised, stone cross withheld.
- LE-07 gate 11 declared non-blocking by the lead (b00439f message), while the checklist (H2) still lists it as an owner question.
- Stale register statuses (code is merged): B25-NINE, B25-SCOPE-REGION, B25-OVN-0211, DEMO-01, B25R1-010/013/014/016/017/018/019/020 (IN DEVELOPMENT), B25R1-002..008/011/012 (IMPLEMENTED ON TASK BRANCH, now on wip/b25r1); B25-CLOSE-02 should read SUPERSEDED.
- Approved but never placed in a build (JOB-02, CON-02-KINDS, PIT-02, FSE-10): checklist H4 asks the owner; not counted here.
- Open owner decisions that the definition of done depends on: B25-ECON-P1..P5, CHAPEL-GIVE-14-Q, SJD-H review, LE-07 gate 11, the Windows exit-leak fix proposal.
- Open defects not owned by a record: od16 SCRIPT ERROR "Invalid access to 'stock'" (pre-existing); net_econ_integrity reconnection checks flaky once locally.

## Appendix: remaining in-scope records (rule-based from register statuses; overrides: SJD-H, CHAPEL-LENDING, DOC-AUTH-01, DOC-RECON-REVIEW-01 -> Blocked, they wait on owner review or delivery)

| id | title | class | register (impl / verification) |
|---|---|---|---|
| ARMOR-CATALOG-01 | Every armour, helmet and cultural outfit in the Puny Characters pack can be made and bough | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| ARMOR-MATERIALS-01 | Boar tusks and antlers as hunted materials, used in special armour and weapons | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| B19-EMERGE | Build 19 verification and emergence principle: classify unexpected outcomes as emergent be | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| B19-RECOVERY | Build 19 carryover recovery within Expansion 20: audit the 18 unfinished Build 19 requirem | Incomplete | PARTIALLY IMPLEMENTED / TARGETED TESTS PASSED |
| BUILD-SEQ-25-27 | Build sequence (owner, 2026-10-31): Build 25 = Expansion 20 validation and freeze (wip/exp | Incomplete | NOT STARTED / NOT TESTED |
| CHAPEL-LENDING | Chapel community lending and grants (concept approved): hardship recovery, viable business | Blocked | NOT STARTED / NOT TESTED |
| CHAPEL-PURPOSE | Chapel economic purpose: a charitable institution that maintains itself, not enriches itse | Implemented but unverified | INTEGRATED / NOT TESTED |
| DOC-AUTH-01 | Document authority replacement: once the owner explicitly approves and delivers the final  | Blocked | NOT STARTED / NOT TESTED |
| DOC-RECON-01 | Documentation reconciliation and owner-decision protection: every expansion (17-27), multi | Implemented but unverified | IMPLEMENTED ON TASK BRANCH / TARGETED TESTS PASSED |
| DOC-RECON-REVIEW-01 | Owner review of DOC-RECON-01 (2026-10-31): wip/requirements-control stays isolated at the  | Blocked | NOT STARTED / NOT TESTED |
| DVW-B1 | Villager relationships, memory of favours/gifts/harms, gossip | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| DVW-B2 | Assault and killing as recorded, fined crimes; heir inheritance of fines/stain | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| E20-P1 | Expansion 20 phase 1: LE-00 audit, requirements registration and isolated LE-01 foundation | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| EMP-CONTRACT-01 | Contracted services: the player negotiates a specific task or quantity (e.g. 50 iron ore)  | Superseded | NOT APPLICABLE / NOT APPLICABLE; completion CLOSED |
| EXP-D | Living Economy Expansion: needs-driven economic architecture (needs, offers, adaptive pric | Incomplete | PARTIALLY IMPLEMENTED / TARGETED TESTS PASSED |
| FIX-D1D2 | Saves never activate a disabled feature, and a disabled feature keeps its saved section un | Complete and verified | INTEGRATED / INTEGRATION VERIFIED; completion COMPLETE |
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-ACTIONBAR | Android action controls redesigned into two readable right-side columns (proposed: Run, Ga | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-ANDROID-ACTION-BUTTONS | Android right-side action controls: compact circular backgrounds, closer to the right edge | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-ANDROID-HUD-SCALE | Android health and status panel about 15% smaller, with every value kept legible | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-ANDROID-RECENTER | Android Recenter places the character at the visual centre of the usable gameplay area, no | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-ANDROID-USE-TALK-TARGETING | Use prioritises the usable station or object and Talk the nearby character; the current ta | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-ANVIL | Workshop anvil: the touch and click target is the visible anvil (not the woodpile); the ch | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-BACK-DOORS | Back doors not drawn on roofs; a trail leads to every door | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-BANDIT-CAMP-ART | Bandit camp: crates, barrels and campfire drawn with the wrong tiles | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-BUSINESS-COURIER | Business courier integration: the courier hand-off at a business desk (individually tracea | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-BUSINESS-DESK | Every business has a business desk: trade and courier in one place | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-CRIME-PURSUIT | Proportionate crime response, guard pursuit that survives loss of sight, coordinated manhu | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-DIALOGUE-PERSPECTIVE | NPCs speak from their own perspective: I, we, my mother, you; witnessed versus heard; pers | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-DRAW-UNDER-HOUSE | Player drawn half under a house wall (Marsh house front) | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-FARMER-TENDING | Farmers tending a field walk through it working the ground with a tool | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-GIFT-QUANTITY | Gifts: give one by default, with a number picker; never the whole stack by accident | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-GOSSIP-NATURAL | Gossip combines related events naturally without repeating names, households and places | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-HARVEST-CONT | Continuous harvesting on all platforms with a setting (continuous or manual) for mining an | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-INPUT-CONSIST | Cross-platform input consistency: Android, Windows, Linux, Steam Deck, keyboard, mouse, to | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-INTERACTABLE-OUTLINES | Usable objects nearby show a subtle sprite-silhouette glow; the selected target a brighter | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-INTERACTION-PROMPT-LIFECYCLE | Contextual prompts ('Use the workbench') clear while the interaction is active and when it | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-INTERIOR-WALLS | Building interiors: side walls missing when inside | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-JOYSTICK | Android movement option: tap-to-move (default, existing) or a lower-left virtual joystick  | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-LOCKPICK | Interactive pin-tumbler lockpicking minigame replacing the passive meter: cutaway chambers | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-MARKET-SHELVES | Market stalls as Craftpix wooden shelves showing each merchant's actual listings (up to te | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-MARKET-SPACING | Market stalls with the Craftpix shelf sprite stand too close together | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-MESSAGE-FOOTPRINT | The message box and the interaction prompt take too much of the screen; make them compact  | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-MESSAGE-JOURNAL | Messages journal is saved with the world: persistent, per-world, filtered to meaningful ev | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-MINE-WOOD-FRAME | Underground: a wooden frame drawn over the wall beside a deposit reads as blocking it; sup | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-PACK-DETAIL-FIT | Pack item detail panel: action buttons cut off the bottom of the screen | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-PAUSE-PANEL | Pause menu: a framed panel over the dimmed game, not a full-screen brown background | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-PICKAXE-ANIM | Android mining shows the pickaxe swing synchronized with the work and stops when mining st | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-POLISH | Gameplay and Controls Polish batch: anvil interaction, lockpicking minigame, Android joyst | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-PROPERTY-NAME-DOUBLE | Village log doubles a property's location ('beside the smithy beside the smithy') | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-QTY-PICKER-CONTROLLER | Quantity pickers (putting goods up at a stall, gifts): Max and Min reachable in one press  | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-REPAIR-SOCIAL | Master gameplay repair: dialogue, social awareness, crime response and guard AI | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-SHARPEN | Sharpen a weapon at the smith's grinding wheel for 1 coin | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-SKILLS-RT | Controller right trigger opens Skills during normal play (an additional shortcut; RB and L | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-SMITHY-WORKBENCH | Smithy: the grinding wheel is not the workbench; a table dressed with hammers is | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-STALL-PRICE-ON-PUTUP | Market stall: set the price when putting goods up | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-STALL-RENT-WRONG-PITCH | Renting a market pitch rents the first free one, not the one the player chose, then says ' | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-START-RUSTY-AXE | The player starts with a rusty axe | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-SWORD-VIS | Visible equipped sword: held when drawn, swung with the attack in every facing, layered an | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-TABLE-ITEMS | Merchandise previews on tables: a visual preview of what the business offers (no pickup) | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-TARGET-ART-MATCH | Interaction prompts name what the art shows (tavern 'crate' is a roast) | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-TRAIL-EDGES | Trails crossing bare dirt show stray grass edges | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-UI-COMPACT | Menus: smaller text and tighter boxes so more fits on screen | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-WANTED-INDICATOR | Show the player when guards are hunting them: a red ring around the character and an out-o | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| GP-WHEAT-PICKED | Harvested wheat shows as picked, cell by cell | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-WIKI-LAYOUT | Encyclopedia laid out like a classic wiki page, on parchment | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| GP-WIKI-RECIPE-TOOLS | Encyclopedia recipes name every tool the work needs (for example a mallet and a chisel, an | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| LE-01 | Living Economy stage LE-01: Shared actor, need, offer, knowledge and contract model | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| LE-02 | Living Economy stage LE-02: Adaptive bids, asks, negotiation and settlement | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| LE-03 | Living Economy stage LE-03: Production, job choice and household budgets | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| LE-04 | Living Economy stage LE-04: Organic finance, merchants and manor behavior | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| LE-06 | Living Economy stage LE-06: Multi-seed long-run, determinism and profiling | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| LE05-RENTAL | Tool rental behind the Living Economy switch through World.transactions: willing owner, de | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| LE05-REPAIR | Tool repair at an anvil for the player and eligible NPC smiths, in normal gameplay (econom | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| MP-INTERACT-01 | Release blocker: player-to-player selection and interaction work for host and guest on Win | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| MP-PLAYER-FAMILY | Children of player-to-player marriages: biological (male and female) and adoption with bot | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| PROS-19 | Expansion 19 prospective implementation (personal memory, subjective judgment, signed opin | Complete and verified | INTEGRATED / INTEGRATION VERIFIED; completion COMPLETE |
| REC-19 | Build 19 Simulation Flight Recorder: full-scope interaction, decision, state-change and ca | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| REC-DIAG | Use the flight recorder now for autonomous simulation analysis: progressively longer runs, | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| REC-STORE | Recorder keeps every decision's alternatives and factors in full; no reduction, sampling o | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| SJD-E | Judgment expansion Gate E: first gated integration in one low-risk domain, feature flag of | Complete and verified | INTEGRATED / INTEGRATION VERIFIED; completion COMPLETE |
| SJD-F | Judgment expansion Gate F: incremental rollout (trade, aid, friendship, courtship, employm | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| SJD-G | Judgment expansion Gate G: full soak and calibration: 100/365-day comparisons, performance | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| SJD-H | Judgment expansion Gate H: owner review; release and broad enablement approved separately | Blocked | PARTIALLY IMPLEMENTED / TARGETED TESTS PASSED |
| WDR-009-C | Comply with World Design Rule 9: Emergent Gameplay | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| WEAPON-CATALOG-01 | Every weapon on the master weapons sheet can be made at the smithy at an appropriate Smith | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| WEAPON-VISIBLE-01 | An equipped weapon is drawn on the character while walking, and attacks swing it like the  | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X19-FOUND | Expansion 19 foundations round: personality, relationship history and family reputation (j | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X19-MISINFO | Deliberate misinformation and its correction: NPCs may fabricate false accusations; listen | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X19-STORY-LIFE | Family stories: reputation extends through a recognized family name, observers judge famil | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X20-B24-F1 | Review finding 1: a settlement business (its trader) kept operating with nobody working it | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-F2 | Review finding 2: TILL-D1 not applied when a household's last members leave (the storefron | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-F3 | Review finding 3: a leaving trader's stall takings not returned to that trader | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-F4 | Review finding 4: another player's one sword blow struck twice on a guest's screen | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-F5 | Review finding 5: a phantom NPC blow landed when the NPC came into view | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-F6 | Review finding 6: stall commission recorded at the wrong moment (not at Stalls.settle) | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-F7 | Review finding 7: a storefront or counter till did not go to its previous holder's own fun | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-F8 | Review finding 8: the recorder's 'starved with means' counted village food rather than the | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-REMED | Build 24 review remediation and Expansion 20 integration: per-finding register, failing-fi | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-B24-REVIEW | Build 24 code review: eight findings fixed in Expansion 20 at their underlying causes, wit | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-BACKGROUND | Expansion 20 continues in the background within approved decisions (Upwardly Build 83 is t | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X20-BANDIT-AI | Bandit situational awareness, threat assessment and self-preservation comparable to villag | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X20-CAREER-AUDIT | Audit career progression, NPC ambition and skilled employment | Implemented but unverified | IMPLEMENTED ON TASK BRANCH / NOT TESTED |
| X20-CHAPEL-FIX | Chapel economy correction: voluntary, affordable, individually decided donations (piety ra | Implemented but unverified | INTEGRATED / NOT TESTED |
| X20-CHAPEL-INTEGRATE | Integrate the chapel correction and the gossip fix into wip/expansion20 | Implemented but unverified | INTEGRATED / NOT TESTED |
| X20-CHECKPOINT | Build 24: private three-platform checkpoint of Expansion 20 groundwork (till ownership, TI | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-ECON-AFFORD | Re-evaluate the unaffordable bids by interval, category, household condition and cause | Incomplete | NOT STARTED / NOT TESTED |
| X20-ECON-AUDIT | Audit which of 20 economic progression systems the year-long simulations exercise | Implemented but unverified | IMPLEMENTED ON TASK BRANCH / NOT TESTED |
| X20-ECON-FIREWOOD | Re-evaluate firewood shortages by season, household, income and period | Implemented but unverified | INTEGRATED / NOT TESTED |
| X20-ECON-LONGITUDINAL | Longitudinal economic evaluation framework (snapshots days 1/30/90/180/270/365 plus interv | Incomplete | NOT STARTED / NOT TESTED |
| X20-ECON-MATURE | Economic maturation: evaluate the economy as a developing system | Incomplete | NOT STARTED / NOT TESTED |
| X20-ECON-MATURE-REPORT | Economic maturation report with the 16 required charts and the executive-summary questions | Incomplete | NOT STARTED / NOT TESTED |
| X20-ECON-SUSTAIN | Build 25 economic sustainability analysis: per-run checkpoint analysis and graphs (populat | Implemented but unverified | IMPLEMENTED ON TASK BRANCH / NOT TESTED |
| X20-FINAL | Expansion 20 final validation, flight-recorder and black-box modernization for Expansions  | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-JUDG-C1 | Judgment integration audit and calibration: every NPC decision system audited for where ju | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X20-JUDG-C2 | Second-hand memories of assault and lesser offences fade by existing memory rules while th | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X20-JUDG-C3 | Wrongdoing counted by incident: a continuous fight is one incident with its meaningful act | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X20-JUDG-C5 | Mixed feelings in real decisions: dislike, respect for ability, fear, dependence, family o | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X20-MERGED-VALIDATION | Merged year-long validation after integrating workers D, F and G: one 30-day baseline repl | Incomplete | PARTIALLY IMPLEMENTED / VERIFICATION FAILED |
| X20-MIGRATE | Free, individual migration from off-map settlements (REG-X20-D1): remove the sole-worker a | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-MP-ECON-INTEGRITY | When multiplayer and the economy systems are integrated, verify that disconnects, retries, | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-OPEN-ITEMS | Expansion 20 consolidated open-items scope: outstanding gameplay polish, Android usability | N/A | NOT APPLICABLE / NOT APPLICABLE |
| X20-RESUME | Resume Medieval development (owner 2026-10-30): three parallel workstreams (Living Economy | Incomplete | PARTIALLY IMPLEMENTED / TARGETED TESTS PASSED |
| X20-SETTLE-FOOD | Live settlement-to-settlement food purchasing (REG-BUY-D1 approval): one settlement's surp | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-SETTLE-REOPEN | A closed settlement business reopens (or is re-established) when a household takes up its  | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-SPLASH | Opening splash: the Hot Attic Games studio logo shows when the game starts, before the gam | Implemented but unverified | INTEGRATED / TARGETED TESTS PASSED |
| X20-TELL-GUARD | Defect: JudgmentStore._tell reads a story the teller forgot during the same meeting (a ref | Implemented but unverified | INTEGRATED / NOT TESTED |
| X20-TILL-KEEP | A household that moves away or gives up a house takes its storefront till balance into its | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-TXN-REPLAY-FIELDS | Latent defect: the transaction authority's saved past results keep only basic fields, so a | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |
| X20-WEAR-TRANSFER | Defect: a tool's saved wear does not travel when the tool changes hands (sale, gift, inher | Complete and verified | INTEGRATED / INTEGRATION VERIFIED |

