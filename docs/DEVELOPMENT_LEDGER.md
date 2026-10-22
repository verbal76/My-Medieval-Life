# Development ledger: the requirements register

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`; do not edit
this file. Every owner-approved requirement stays here until it is COMPLETE AND VERIFIED, SUPERSEDED by a named
requirement, or CANCELED BY OWNER (CLAUDE.md, requirements register). Proposals, open owner decisions and design
rules are listed separately and are not counted as approved work. The order of work is in
`docs/CURRENT_DEVELOPMENT_STATE.md` (start from `docs/PROJECT_MEMORY.md`);
the ledger before this register is kept in `docs/requirements/LEDGER_ARCHIVE_2026-10-19.md`.

## Counts (approved requirements; each counted once, by lifecycle status)

| Status | Count |
|---|---|
| APPROVED — NOT STARTED | 63 |
| ACTIVE DEVELOPMENT | 18 |
| PARTIALLY IMPLEMENTED | 33 |
| IMPLEMENTED — TESTING REQUIRED | 24 |
| AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | 44 |
| BLOCKED | 14 |
| DEFERRED | 11 |
| COMPLETE AND VERIFIED | 226 |
| SUPERSEDED | 21 |
| CANCELED BY OWNER | 0 |
| UNKNOWN — INVESTIGATION REQUIRED | 7 |
| **Total approved** | **461** |
| Outstanding (not complete, superseded or canceled) | 214 |

Also in the register: 32 proposal awaiting an owner decision (not approved), 77 owner decision (open or answered), 30 world design rule, 2 unapproved idea; of the owner decisions, 37 are open (status BLOCKED).
These counts are of approved requirements only: an owner decision being carried out (status ACTIVE DEVELOPMENT) is counted under
the owner decisions, not here. The Roadmap total below counts every open entry of every kind but rules.

## Roadmap (owner, 2026-10-20: ROAD-01)

Every open entry (approved work, proposals, decisions; rules excluded) with the build it belongs to. A gate says what
must happen first (a device check, an owner decision, art). Completed entries are not counted here.
Open owner decisions that belong to a build's design (OD-*, SJD-Q*) are listed under that build with the gate
"owner decision first"; "Waiting on an owner decision" holds the rest. Every open owner decision is
status BLOCKED (the ledger's owner-decisions section lists them all).

| Target | Open entries | of which approved work |
|---|---|---|
| Build 15: simulation stabilization | 52 | 50 |
| Build 16: long-term equilibrium and validation | 34 | 33 |
| Build 17: Mining & Industrial Development | 26 | 21 |
| Build 18: Settlement Advancement & Regional Economy | 34 | 27 |
| Build 19: NPC Judgment System | 21 | 15 |
| Build 20 or later (outside the five builds) | 44 | 42 |
| Multiplayer track (isolated branch) | 3 | 2 |
| Waiting on an owner decision | 67 | 18 |
| Owner or external action (not development work) | 6 | 6 |
| **Total open** | **287** | **214** |

### Build 15: simulation stabilization (52)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| B13-12 | B closes only quantity selector | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B13-13 | Touch sprint | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B14-01 | Harvest or talk: A works the resource, Y / T talks to the villager beside it | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B14-06 | Carts in play: pulled storage, parking, cart stops, deliveries, household market runs | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B14-13 | A controller connected to a phone or tablet hides the touch buttons and uses the pad controls | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B7-001 | Starting coins | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B7-005 | Earning money discoverable; "Trade with" | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B7-009 | Treasury starts below reserve; no paid manor work until ~day 12 | approved | IMPLEMENTED — TESTING REQUIRED |  | economy placeholders measured in the Build 15 runs (manor reserve, 30-coin caravan stand-in) |
| B7-010 | HUD anchoring on Android | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B7-011 | Tapping trees/ore does nothing | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B7-012 | Gather mode | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B7-013 | Brown glyph icons | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| B7-014 | Caravan grows currency ~12x a year | approved | IMPLEMENTED — TESTING REQUIRED |  | economy placeholders measured in the Build 15 runs (manor reserve, 30-coin caravan stand-in) |
| B8-018 | Roof flicker indoors | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| CARAVAN-TMP | The daily caravan allowance is a labelled, adjustable temporary stand-in for unsimulated outside settlements during Builds 15-16 (30 coins a day) | decision | IMPLEMENTED — TESTING REQUIRED |  | economy placeholders measured in the Build 15 runs (manor reserve, 30-coin caravan stand-in) |
| CQ-01 | Sword responsiveness and hit detection (buffer, reach, phases, walls) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| CRT-01 | Player courtship and marriage through gifts: attraction, dating, proposal that can be declined if too early | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-02 | Friendship: a Befriend option appears after help and gifts; no proposal needed | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-04 | Villagers court each other through gifts, dating and proposals by the player's rules, replacing the random pairing chance | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-05 | Gift tastes follow obvious things: a villager's trade and current needs; favourite gifts speed courting, traditional gifts always work | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-07 | Courtship and marriage between any two humans, same sex included; humans only for now | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-08 | Shared experiences start friendships and romances: working together and personal interactions build regard and attraction | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-09 | Weighting of closeness and conversation: proximity about 1 point, a conversation 0.25, later ones about 0.11, so talk spamming does little | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-10 | Relationship weighting system: closeness over time (the nearby-name prompt), many factors, distinct days known; no button spamming to a quick marriage | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-11 | Single villagers with spare money and goods actively seek company: spend time near the one they court or befriend, and buy gifts | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| CRT-12 | Proposals can be refused: not wanting to marry, a rival suitor with a better offer, or the suitor's deeds (killing villagers, crimes, theft from their friends or family) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | relationship sustainability (owner's Build 15 scope); code and tests done, the owner's play check remains |
| DVW-A14 | Play one whole life before each release (:39) | approved | IMPLEMENTED — TESTING REQUIRED |  | release practice: play one whole life before each release, starting with Build 15 |
| FAM-01 | Household succession: when one parent dies the surviving parent (either sex) becomes responsible for the dependants and every household decision; the household keeps functioning | approved | IMPLEMENTED — TESTING REQUIRED |  | the responsible-adult choice is needed by the housing fix (HOUSE-02); the rest exists (inheritance, work, purse) |
| FR-04 | Pad shortcuts for the Journal and Build menus; complete on-screen controls list | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |  | small completeness items (pad shortcuts, controls list, missing wiki pages) |
| HOUSE-12 | Sleeping loft: a lightweight house improvement adding sleeping places after real construction (materials, labour, time), integrated with sleeping, occupancy and household behaviour; not a navigable second floor | approved | IMPLEMENTED — TESTING REQUIRED |  | OD-14 follow-up, owner's preferred direction |
| OVN-01 | Master overnight directive: autonomous lead-engineer execution of approved work, Builds 15 to 18 strictly in order, the build-completion definition, the skipped-items register, release and decision authority | approved | ACTIVE DEVELOPMENT |  |  |
| OVN-02 | Final development mandate: Build 15 closure standard, living-world philosophy (WDR-022), release when functionally complete, then Builds 16, 17, 18 in order, autonomous engineering | approved | ACTIVE DEVELOPMENT |  |  |
| PERF-01 | Simulation performance audit: measured explanation of the runtime growth since the 530-689 s 365-day benchmark (regression, contention, environment or estimates) | approved | ACTIVE DEVELOPMENT |  | owner priority: after Build 15 stabilization and EQ-07 housing (owner order 4-5) |
| PL1-03 | Merchant quantity control | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| PL1-05 | current/max inside bars | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| Q-04 | Resources & Gathering journal page | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | code done in earlier builds; only the real-device check remains, done with the Build 15 package |
| REC-003 | Android builds target API 36 (Hot Attic Games standing platform policy) | approved | UNKNOWN — INVESTIGATION REQUIRED |  | release configuration check (target Android API) before the next package |
| REL-15-18 | Release authorization for Builds 15 to 18: create and publish each when all its release gates pass (section 4), with the established platforms, naming and procedure; private test builds stay private | approved | ACTIVE DEVELOPMENT |  | covers the release of each build 15-18 as it qualifies |
| ROAD-01 | Five-build roadmap: 15 simulation stabilization, 16 long-term equilibrium, 17 Mining & Industrial, 18 Settlement & Regional Economy, 19 NPC Judgment | decision | ACTIVE DEVELOPMENT |  | the roadmap record itself, kept current from Build 15 |
| SAVE-00 | Save continuity across separate test builds (Android reinstall): user-selected save location or Android-supported export/import; permanent signing key deferred | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | save continuity is code-complete; verified with the Build 15 package |
| SAVE-02 | A stable save identity independent of build numbers (requirement 2) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | save continuity is code-complete; verified with the Build 15 package |
| SAVE-03 | Explicit save-schema versioning and forward migration from older supported formats (requirements 3, 4) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | save continuity is code-complete; verified with the Build 15 package |
| SAVE-04 | Back up the original before migrating, validate the migrated save before adopting it, preserve the original on failure, never leave a partial conversion, never destroy the only usable save (requirements 5-8, 15) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | save continuity is code-complete; verified with the Build 15 package |
| SAVE-05 | A clear way to reconnect to an existing save after an Android reinstall, using supported Android storage (Storage Access Framework or equivalent), no unrestricted filesystem access (requirements 9, 10) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | the Android export/uninstall/import check on a phone |
| SAVE-06 | The same versioning and migration principles on Windows and Linux (requirement 11) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | save continuity is code-complete; verified with the Build 15 package |
| SAVE-07 | Migration tests over persistent world data: terrain changes, resources, NPCs, households, relationships, buildings, inventories, settlements, simulation state (requirement 12) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | save continuity is code-complete; verified with the Build 15 package |
| SAVE-08 | Preserve unknown or future data where practical; no claim of backward compatibility unless implemented and tested (requirement 13) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | save continuity is code-complete; verified with the Build 15 package |
| SAVE-09 | An independently recoverable backup and documented recovery instructions (requirement 14) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | save continuity is code-complete; verified with the Build 15 package |
| WDR-008-C | Comply with World Design Rule 8: Player Knowledge and Wiki | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |  | automated compliance, wiki coverage and clarity are kept up with every build; tracked from Build 15 |
| WDR-010-C | Comply with World Design Rule 10: Depth Without Obscurity | approved | PARTIALLY IMPLEMENTED |  | automated compliance, wiki coverage and clarity are kept up with every build; tracked from Build 15 |
| WDR-022-C | Comply with World Design Rule 22: classify every finding as defect, legitimate outcome or future improvement; no hidden rescue; tests check mechanics and integrity, never prosperity | approved | ACTIVE DEVELOPMENT |  |  |
| WR-01 | Protected wildlife breeding refuges, offspring cohorts and dispersal | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | device check | wildlife sustainability; code and tests done, play check remains |

### Build 16: long-term equilibrium and validation (34)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| ARM-01 | Armorer availability: verify the armorer exists, keeps a schedule, a place, stock, a path, and trades with the player (the owner's playtest: never available) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| B16-AUDIT | Build 16 complete status audit, maintained (docs/BUILD_16_STATUS.md) | approved | ACTIVE DEVELOPMENT | Build 16 in development (OVN-01) | owner instruction 2026-10-20 |
| B16-READY | Build 16 development audit and release-readiness report | approved | ACTIVE DEVELOPMENT | Build 16 | Owner audit request |
| B7-016 | Tanners/goods merchants end at 0 coins | approved | BLOCKED |  | missed meals and traders at 0 coins are equilibrium failures; the Build 16 directive authorizes correcting root causes (was waiting on the owner) |
| CTR-01 | Skilled-trade sales counters: every established skilled business (armorer, smith, carpenter, others as they develop) has a working customer counter | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| CTR-02 | At a counter: a prompt, press A, and the business's available shopkeeper walks to the counter to serve | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| CTR-03 | Shopkeeper availability: ordinary villagers with schedules; when summoned an available one comes, else the player is told clearly; employees or family may serve; no interrupted emergencies, no duplicate service tasks | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| DVW-A3 | Re-measure money supply, 100 and 365 days, 2-3 seeds, no player (:28) | approved | ACTIVE DEVELOPMENT |  | money supply re-measured over 100/365 days on several seeds (EQ-06) |
| EQ-05 | The player is the disruptive variable: no hidden protection of the world from player consequences | approved | PARTIALLY IMPLEMENTED |  | the owner's Build 16 world-equilibrium objective and its acceptance runs |
| EQ-22 | Caravan buying order: smiths first starves the hide and leather chain after parity | approved | IMPLEMENTED — TESTING REQUIRED |  |  |
| FAM-02 | Both parents dead: dependent children never found households or start construction; an existing household takes them in | approved | IMPLEMENTED — TESTING REQUIRED |  | a new mechanic; Build 16 is long-term equilibrium across generations, and Build 15 must not be delayed |
| FAM-03 | Informal adoption order: living grandparents (both sides), then the nearest eligible blood relative by genealogy, then another villager's household with a responsible adult; no adoption authority | approved | IMPLEMENTED — TESTING REQUIRED |  | needs a kinship-distance function (today Life.kin covers parents and siblings only) |
| FAM-04 | Integration: the child becomes a dependant of the receiving household and uses its house; genealogy (mother, father, birth family) is never overwritten; a surname change is allowed and does not corrupt the tree | approved | IMPLEMENTED — TESTING REQUIRED |  | with FAM-02 |
| FAM-05 | Occupancy after a child is taken in is recalculated; any housing need it creates belongs to the receiving household's responsible adult; no house is built automatically | approved | IMPLEMENTED — TESTING REQUIRED |  | with FAM-02; uses the HOUSE-* goal |
| FAM-06 | Family scenario tests: the eight family scenarios of the directive, written when the mechanics are implemented | approved | IMPLEMENTED — TESTING REQUIRED |  | with FAM-02..05 |
| FAM-07 | Unplaced orphans join the bandit clan (OD-11): after surviving parent, grandparents, nearest eligible blood relative and a willing villager household; the child keeps identity, age, genealogy and relationships and stays a child (no adult combat) | approved | IMPLEMENTED — TESTING REQUIRED |  | with FAM-02/03 (Build 16); full integration with bandit factions follows WDR-016-C (Build 20+) |
| FARM-06 | Manor fields need seed and labour like any farm (no free seed, crops or materials) | approved | PARTIALLY IMPLEMENTED | Build 16 in development (OVN-01) | owner decisions OD-22..24, 2026-10-20 |
| FARM-08 | Shared-yield comparison: the per-cell model and seasonal farming together at several yields (0.9-3 a cell), identical seeds; grain produced/consumed/sold/stored/unsold, seed use and recovery, labour a harvest, food security and starvation causes, manor and family-farm viability, prices and demand, livestock feed and milk, seasonal timing; the milk collapse explained; a recommended yield for the owner's approval | approved | ACTIVE DEVELOPMENT | Build 16 in development (OVN-01) | owner decision 2026-10-21 (FSE-12/13) |
| FARM-08B | Cattle decline under the shared and seasonal farming model: investigation | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 | FARM-08 comparison |
| FARM-09 | Farmland placement by drag: two green corners, live price at screen centre, lease or buy, confirm | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | Build 16 | Owner master directive 2026-10-21 |
| FSE-00 | Food security, household production, land use, markets and goal-driven economic behavior (final master directive) | approved | ACTIVE DEVELOPMENT | Build 16 in development (OVN-01) | section 18: audit first, then only defects and small foundations in Build 16 |
| FSE-12 | One agricultural model for player and village farming (parity) | approved | PARTIALLY IMPLEMENTED | Build 16 in development (OVN-01) | owner follow-up 2026-10-20: a tracked Build 16 task |
| FSE-13 | Seasonal farming for village fields (implemented and tested in isolation; activation needs owner review) | approved | PARTIALLY IMPLEMENTED | Build 16 in development (OVN-01) | owner follow-up 2026-10-20: a tracked Build 16 task |
| MERCH-01 | A village seed merchant or booth selling crop and flower seed, berry cuttings and fruit-tree seed or saplings, with real stock, coins and restocking | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| OD-17 | Owner decision: the Game Designer spec's open calls not covered by another entry: C1 the hero (spec: 'Your main character is the hero' against the confirmed 'not the chosen one'), C10 the view (top-down at an angle, three-quarter, or isometric; with DGA-D1), and Steam Deck labelling (the spec's '(web)' build; the owner said to correct the label without changing the platforms). Class progression is REC-010, ranged combat REC-009, Mote REC-002, the API 36 policy REC-003 | decision | BLOCKED | owner decision first | design wording only; nothing in Build 15 depends on it |
| PICK-01 | A caught pickpocket raises a witness report through World.witness (OD-20), as assault does (PAR-05): awareness only from legitimate witnesses, no omniscient guards, not always an audible alarm | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 in development (OVN-01) | owner decisions 2026-10-21 |
| SEED-02 | Planting consumes real seed or propagation material for every plant type; harvests recover seed or cuttings at a deterministic chance | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| SEED-03 | Perennials (fruit trees, berry bushes) survive harvest and bear again by season; growth follows the 8-day year | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| SEED-04 | Households save planting material from their own harvests | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| SHOP-01 | Skilled businesses sell what they produce or stock and buy useful goods by real need and funds (a carpenter buys timber, an armorer materials), the same mechanics for player and villagers | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| SJD-A | Judgment expansion Gate A: Build 16 stabilization and baseline (seeds, remote commit, known defects); no implementation | approved | APPROVED — NOT STARTED |  | the judgment system's Gate A is the Build 16 baseline itself |
| STALL-06 | Villager households build, stock, open, close and restock stalls by the player's mechanics, selling surplus with the family's needs weighed | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 in development (OVN-01) | owner decisions OD-22..24, 2026-10-20 |
| TRADE-01 | Trade-specific purchasing at counters through the shared trade rules (OD-19 reserve, PAR-02) | approved | IMPLEMENTED — TESTING REQUIRED | Build 16 in development (OVN-01) | owner directive 2026-10-20, Build 16 sections 1-8 |
| WR-02 | Grazers in a wood all stop eating while the wood is over its grass capacity, so some starve together | approved | IMPLEMENTED — TESTING REQUIRED |  | nature sustainability (EQ-02) |

### Build 17: Mining & Industrial Development (26)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| B14-07 | Cliff steps (pickaxe, Mining), wooden stairs and walkways (planks, nails, Carpentry, a mallet) | approved | APPROVED — NOT STARTED |  | cliff steps, stairs and walkways need the terrain/elevation audit (MIN-A) |
| B7-006 | Hired work pays poorly (mine shift 8 for ore worth ~18; axe needed) | approved | BLOCKED | owner decision first | the mine wage belongs with mining labour economics; still the owner's call (OD-01) |
| B7-007 | Deposits never refill; no stone source | approved | PARTIALLY IMPLEMENTED |  | deposit sustainability is answered by the mining expansion (quarry, prospecting, finite hidden deposits) |
| CON-01 | Universal negotiated goods-procurement contracts (item, quantity, price per unit; accept, reject or counter; any party to any party) | approved | APPROVED — NOT STARTED | Build 17 | Owner Build 17 decisions 2026-10-21 |
| DVW-A10 | No black-hole spaces (:35) | approved | APPROVED — NOT STARTED |  | cliff steps, stairs and walkways need the terrain/elevation audit (MIN-A) |
| DVW-A12 | Keep rules in `core/`, not UI; audit list (:37) | approved | DEFERRED |  | rules in core/, not UI: a code audit before the expansions build on it |
| DVW-B4 | Goods decay (grain spoils, clothes/armour/carts wear) | approved | APPROVED — NOT STARTED | owner decision first | wear and maintenance give tools, supports and carts real upkeep (industrial chains) |
| ECON-P1.1 | Demand-driven mining (:71) | proposal | BLOCKED |  | older deposit proposals; inputs to the mining phases (candidates to supersede by MIN-B..D) |
| ECON-P1.2 | Manor mining rights, royalty, quota, stone reserve (:72) | proposal | BLOCKED |  | older deposit proposals; inputs to the mining phases (candidates to supersede by MIN-B..D) |
| ECON-P1.4 | Prospecting new seams (:74) | proposal | BLOCKED |  | older deposit proposals; inputs to the mining phases (candidates to supersede by MIN-B..D) |
| ECON-P1.5 | Distant quarry (:75) | proposal | BLOCKED |  | older deposit proposals; inputs to the mining phases (candidates to supersede by MIN-B..D) |
| EXP-A | Expansion A: Mining & Industrial Development (independent future expansion; supporting document is the primary specification) | approved | APPROVED — NOT STARTED |  | the Mining & Industrial Development expansion |
| MIN-A | Mining expansion phase A: Audit terrain, elevation, mining, inventory, recipes, AI, pathfinding, saves and map generation; architecture and measurable acceptance tests | approved | APPROVED — NOT STARTED |  | the Mining & Industrial Development expansion |
| MIN-B | Mining expansion phase B: Exhausted ore outcrops stay quarryable stone; quarry chain and stone logistics | approved | APPROVED — NOT STARTED |  | the Mining & Industrial Development expansion |
| MIN-C | Mining expansion phase C: Natural prospecting clues, prospector profession, forge-made toolkit, samples and assay | approved | APPROVED — NOT STARTED |  | the Mining & Industrial Development expansion |
| MIN-D | Mining expansion phase D: Finite hidden deposit discovery; settlement mining capability levels 1-4 with autonomous NPC adoption | approved | APPROVED — NOT STARTED |  | the Mining & Industrial Development expansion |
| MIN-E | Mining expansion phase E: Open-pit excavation, spoil, dirt and topsoil as materials, ramps, hauling and geological layers (where the architecture supports them) | approved | APPROVED — NOT STARTED | depends on MIN-A | open-pit and underground mining; may slip to 20+ if MIN-A finds the terrain cannot carry depth (document section 7) |
| MIN-F | Mining expansion phase F: Underground and cave mining, cutaway presentation, supports, minecarts, track construction and full industrial dependencies | approved | APPROVED — NOT STARTED | depends on MIN-A | open-pit and underground mining; may slip to 20+ if MIN-A finds the terrain cannot carry depth (document section 7) |
| MIN-G | Mining expansion phase G: 100/365-day multi-seed simulations and gameplay tests; save validation; economic conservation; no resource spawning | approved | APPROVED — NOT STARTED |  | the Mining & Industrial Development expansion |
| MIN-H | Enterable caves and underground mining environments (roof-fade principle, NPC pathing, persistence) | approved | APPROVED — NOT STARTED | Build 17 | Owner Build 17 decisions 2026-10-21 |
| OD-01 | Owner decision: deposit sustainability (P1) and the mine wage (B7-006) | decision | BLOCKED | owner decision first | deposit sustainability is answered by the mining expansion (quarry, prospecting, finite hidden deposits) |
| PL1-12 | Red flowering plant not pickable | approved | PARTIALLY IMPLEMENTED |  | the red plant in the overworld needs an overworld generator version, done with the geological clues (MIN-C) |
| REC-013 | Need-based maintenance (wear) model and the other unanswered job-board questions | approved | BLOCKED | owner decision first | wear and maintenance give tools, supports and carts real upkeep (industrial chains) |
| WDR-001-C | Comply with World Design Rule 1: Material Interdependency | approved | PARTIALLY IMPLEMENTED |  | material interdependency, meaningful recipes and finite resources are the mining expansion's rules |
| WDR-003-C | Comply with World Design Rule 3: Meaningful Recipes | approved | UNKNOWN — INVESTIGATION REQUIRED |  | material interdependency, meaningful recipes and finite resources are the mining expansion's rules |
| WDR-013-C | Comply with World Design Rule 13: Finite Resources and Actual Consumption | approved | PARTIALLY IMPLEMENTED |  | material interdependency, meaningful recipes and finite resources are the mining expansion's rules |

### Build 18: Settlement Advancement & Regional Economy (34)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| B14-11 | Animal Farm pack: the horse and farm animals | approved | APPROVED — NOT STARTED |  | the plough horse bought from the caravan fits when caravans trade real goods; draught animals change farm output |
| CAP-TOOLHOLDER | Design review: a villager holding a tool only for sale counts as a capability practitioner | idea | APPROVED — NOT STARTED |  |  |
| DVW-B3 | Coin sinks people enjoy (luxury imports, feasts, weddings, offerings, heriot) | approved | APPROVED — NOT STARTED |  | coin sinks and predictable taxes are settlement finance |
| DVW-B5 | Predictable taxes with hysteresis, announced | approved | APPROVED — NOT STARTED |  | coin sinks and predictable taxes are settlement finance |
| DVW-B6 | Wildlife wandering in from the overworld | approved | DEFERRED |  | wildlife wandering in from the overworld: recolonization (EQ-02) |
| ECON-P1.3 | Caravan as finite regional market (:73) | proposal | BLOCKED |  | caravan as a finite regional market; household versus business money |
| ECON-P3 | Household vs business money, quotes follow money, stock days, market hire wages, `World.spendable` (:183-187) | proposal | BLOCKED |  | caravan as a finite regional market; household versus business money |
| EXP-B | Expansion B: Settlement Advancement & Regional Economy (independent future expansion; supporting document is the primary specification) | approved | APPROVED — NOT STARTED |  | the Settlement Advancement & Regional Economy expansion |
| F-1 | NPC workshop construction | approved | DEFERRED |  | NPCs building workshops is settlement development |
| OD-05 | Owner decisions: inner doorways, relaying survey plots | decision | BLOCKED | owner decision first | property, farming and arbitrage questions the settlement economy needs answered |
| OD-06 | Owner decisions: farming (Farming skill, wheat versus wages) | decision | BLOCKED | owner decision first | property, farming and arbitrage questions the settlement economy needs answered |
| OD-08 | Owner decision: is honest arbitrage intended? | decision | BLOCKED | owner decision first | property, farming and arbitrage questions the settlement economy needs answered |
| PL1-10 | Player businesses, staged (1-4) | approved | PARTIALLY IMPLEMENTED |  | production chains in player shops, coops, hired farm help, draught animals: industry and specialization |
| PL2-008 | Expandable property | approved | PARTIALLY IMPLEMENTED | owner decision first | expandable property is settlement growth |
| PL2-014 | Modular house/workshop expansion | approved | PARTIALLY IMPLEMENTED | owner decision first | expandable property is settlement growth |
| PL2-015 | Farming, livestock, hand plough | approved | PARTIALLY IMPLEMENTED |  | production chains in player shops, coops, hired farm help, draught animals: industry and specialization |
| PROS-18 | Expansion 18 prospective implementation (settlement capability and specialization, regional supply and demand, routes and transport, settlement inventories and reports, competition and cooperation, caravan subsidy replacement plan, conservation tests) | approved | ACTIVE DEVELOPMENT |  |  |
| Q18-11 | What pay factor and output factor should each settlement capability level give, and for which industries? (Until answered every factor is 1.0, no effect) | decision | PARTIALLY IMPLEMENTED |  |  |
| SET-A | Settlement expansion phase A: Design and ledger: requirement ids, cross-industry skill schema, save compatibility, dependency audit | approved | APPROVED — NOT STARTED | needed during 17 | the expansion's design phase; its capability schema should be designed during Build 17 so MIN-D can use it |
| SET-B | Settlement expansion phase B: Settlement capability model: per-industry capabilities, NPC knowledge, workshops, prerequisites, decay and continuity | approved | APPROVED — NOT STARTED |  | the Settlement Advancement & Regional Economy expansion |
| SET-C | Settlement expansion phase C: Abstract regional economy: off-map settlements with finite demand, supply and budgets; variable caravan trade | approved | APPROVED — NOT STARTED |  | the Settlement Advancement & Regional Economy expansion |
| SET-D | Settlement expansion phase D: Settlement development: growth and decline, specialization, housing, infrastructure, population and employment | approved | APPROVED — NOT STARTED |  | the Settlement Advancement & Regional Economy expansion |
| WDR-002-C | Comply with World Design Rule 2: Professional Interdependency | approved | PARTIALLY IMPLEMENTED |  | professional interdependency, economic consequences, NPC prosperity and rivalry are the settlement expansion's rules |
| WDR-004-C | Comply with World Design Rule 4: Economic Consequences | approved | PARTIALLY IMPLEMENTED |  | professional interdependency, economic consequences, NPC prosperity and rivalry are the settlement expansion's rules |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | approved | APPROVED — NOT STARTED |  | professional interdependency, economic consequences, NPC prosperity and rivalry are the settlement expansion's rules |
| WDR-012-C | Comply with World Design Rule 12: NPC Competition and Economic Rivalry | approved | PARTIALLY IMPLEMENTED |  | professional interdependency, economic consequences, NPC prosperity and rivalry are the settlement expansion's rules |
| X18-CAPCOMP | Capability composition: workforce capability from local experience, effective capability capped by operational facilities | approved | PARTIALLY IMPLEMENTED |  |  |
| X18-CAPNUM | Capability modifiers: the bounded model (revised_bounded) for six industries, farming as labour efficiency | approved | IMPLEMENTED — TESTING REQUIRED |  |  |
| X18-Q12 | Implement Q18-12 transport: flat-rate fees on regular routes or scheduled delivery, negotiated special deliveries, self-collection; smoke tests | approved | ACTIVE DEVELOPMENT |  |  |
| X18-Q12-BOOTH | Courier booths in each city, village and major business, serving regular routes (flat fee per load or scheduled delivery); special deliveries negotiated by choosing a recipient among the people and businesses the buyer knows | approved | ACTIVE DEVELOPMENT |  |  |
| X18-Q12-POST | Courier contract popup like online postage (dropdowns: quantity, item, recipient, location, collect payment, deliver or deposit proceeds, money/item type and amount, route or special) assembled into a readable instruction; recipients from known people and businesses incl. prior trading contacts (owner represents the business; location from world records); fee computed from route type, distance, burden, capacity, stops, return/deposit, labour, notarial service; physical execution; fulfilled only when obligations are done | approved | ACTIVE DEVELOPMENT |  |  |
| X18-Q13 | Implement Q18-13 signing: small agreements unsigned; formal contracts and ownership transfers signed face to face, or through a courier-notary with legal skill carrying the documents; no remote instant signing; smoke tests for incomplete, rejected, interrupted and completed agreements | approved | ACTIVE DEVELOPMENT |  |  |
| X18-SIM | Comparative capability simulations (baseline, conservative, moderate, aggressive; levels 0,2,5,8,10; implemented industries; settlement size, resource and labour scenarios; 30 and 90 days) and a recommendation; no permanent constants before owner review | approved | ACTIVE DEVELOPMENT |  |  |
| X18-STONECUT | Professional stonecutter: an independent trade and business that dresses and sells building blocks | approved | APPROVED — NOT STARTED |  |  |

### Build 19: NPC Judgment System (21)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| DVW-B1 | Villager relationships, memory of favours/gifts/harms, gossip | approved | PARTIALLY IMPLEMENTED |  | memory of favours and harms, crimes and their stain are judgment inputs (EXP-C) |
| DVW-B2 | Assault and killing as recorded, fined crimes; heir inheritance of fines/stain | approved | APPROVED — NOT STARTED |  | memory of favours and harms, crimes and their stain are judgment inputs (EXP-C) |
| EXP-C | Expansion C: NPC Judgment System (Subjective Judgment & Universal Decision Engine; independent future expansion after a stable Build 16 baseline) | approved | APPROVED — NOT STARTED |  | the NPC Judgment System expansion |
| FR-09 | Crime from desperation | approved | DEFERRED | owner decision first | crime from desperation is need weighed against judgment; held back by the owner until then |
| FR-11 | Personality, prestige and migration (owner's living-society list, 2026-10-17) | approved | UNKNOWN — INVESTIGATION REQUIRED |  | personality and decision weights are part of the judgment design (spec section 10); migration part goes with 18 |
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | approved | APPROVED — NOT STARTED | fit to confirm | generational memory is the judgment system's event and belief record; not named in any build, closest fit |
| PROS-19 | Expansion 19 prospective implementation (personal memory, subjective judgment, signed opinions, decision weighting that influences not dictates, provenance and sharing, persistence and migration prototypes, determinism and large-population performance tests) | approved | ACTIVE DEVELOPMENT |  |  |
| SJD-B | Judgment expansion Gate B: architecture audit (Godot services, relationships, economic decisions, event hooks, save format, risks) and integration map with open questions | approved | APPROVED — NOT STARTED |  | the NPC Judgment System expansion |
| SJD-C | Judgment expansion Gate C: isolated prototype (event catalog, beliefs, signed interpretation, GOOD/BAD ledger, tests), no effect on live behaviour | approved | APPROVED — NOT STARTED |  | the NPC Judgment System expansion |
| SJD-D | Judgment expansion Gate D: decision prototype (factor registry, utility profiles, the 50-iron scenario, explanation traces, determinism) | approved | APPROVED — NOT STARTED |  | the NPC Judgment System expansion |
| SJD-E | Judgment expansion Gate E: first gated integration in one low-risk domain, feature flag off by default, matched-seed tests | approved | APPROVED — NOT STARTED |  | the NPC Judgment System expansion |
| SJD-F | Judgment expansion Gate F: incremental rollout (trade, aid, friendship, courtship, employment, crime, politics) | approved | APPROVED — NOT STARTED |  | the NPC Judgment System expansion |
| SJD-G | Judgment expansion Gate G: full soak and calibration: 100/365-day comparisons, performance and save migration | approved | APPROVED — NOT STARTED |  | the NPC Judgment System expansion |
| SJD-H | Judgment expansion Gate H: owner review; release and broad enablement approved separately | approved | APPROVED — NOT STARTED |  | the NPC Judgment System expansion |
| SJD-Q03 | Judgment open decision: Different disposition thresholds per NPC, or one calibrated scale? | decision | BLOCKED | owner decision first | an open design question; stays unanswered until the owner answers it (no default chosen) |
| SJD-Q04 | Judgment open decision: Should very large GOOD and BAD totals with NET near 0 create ambivalence behaviour? | decision | BLOCKED | owner decision first | an open design question; stays unanswered until the owner answers it (no default chosen) |
| SJD-Q05 | Judgment open decision: How much may prior judgment bias interpretation of ambiguous events? | decision | BLOCKED | owner decision first | an open design question; stays unanswered until the owner answers it (no default chosen) |
| SJD-Q09 | Judgment open decision: Always highest utility, or sometimes near-optimal via seeded randomness? | decision | BLOCKED | owner decision first | an open design question; stays unanswered until the owner answers it (no default chosen) |
| SJD-Q12 | Judgment open decision: What makes an event important enough to score? | decision | BLOCKED | owner decision first | an open design question; stays unanswered until the owner answers it (no default chosen) |
| SJD-Q13 | Judgment open decision: How should individual decision weights be learned, configured or tuned? | decision | BLOCKED | owner decision first | an open design question; stays unanswered until the owner answers it (no default chosen) |
| WDR-009-C | Comply with World Design Rule 9: Emergent Gameplay | approved | PARTIALLY IMPLEMENTED |  | emergent gameplay is the judgment system's purpose |

### Build 20 or later (outside the five builds) (44)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| B12A-05 | Accessibility not yet added: text scaling, a colour-blind mode, key rebinding, turning off the blinking | idea | APPROVED — NOT STARTED |  | accessibility, escape safety, object uses, danger cues, campfire, more side quests: player experience outside the five builds |
| B12A-07 | Art blockers: crop stages, tool swings, sitting poses, chimney, sawhorse (Craftpix crops could supply crop art, B14-10) | approved | BLOCKED | art needed | art and presentation (crop stages, tool swings, sitting poses, chimney, sawhorse, props); can be pulled into any build when art arrives |
| B12A-08 | Deferred features from the Build 12 audit (umbrella; each child item tracked on its own) | approved | DEFERRED |  | umbrella of deferred features; each child is assigned on its own |
| B14-09 | Skeletons in caves and uncleared woods (guard by day, roam at night, 3-day respawn; bones and rusty gear) | approved | APPROVED — NOT STARTED |  | bandit factions, skeletons, castles, dungeons: combat content outside the five builds |
| B14-10 | Craftpix farm plants: crop stages, produce, crates, fruit trees chopped like the others | approved | PARTIALLY IMPLEMENTED | art needed | art and presentation (crop stages, tool swings, sitting poses, chimney, sawhorse, props); can be pulled into any build when art arrives |
| B8-007 | Wrong tool shown | approved | PARTIALLY IMPLEMENTED | art needed | art and presentation (crop stages, tool swings, sitting poses, chimney, sawhorse, props); can be pulled into any build when art arrives |
| CRT-06 | Friendship benefits: better prices, help and favours, gossip and news, backing in disputes and votes | approved | PARTIALLY IMPLEMENTED |  | village politics (offices, voting, elections) is approved but in none of the five builds; voting weighs judgment, so after 19 |
| DVW-A13 | Every visible object has a use (:38) | approved | PARTIALLY IMPLEMENTED |  | accessibility, escape safety, object uses, danger cues, campfire, more side quests: player experience outside the five builds |
| DVW-A9 | Player can always escape predators/bandits (:34) | approved | APPROVED — NOT STARTED |  | accessibility, escape safety, object uses, danger cues, campfire, more side quests: player experience outside the five builds |
| DVW-B7 | Life chronicle, titles, memorial | approved | APPROVED — NOT STARTED |  | graveyards, legacy, life chronicle: approved, in none of the five builds |
| DVW-B9 | Readable danger: howl/roar cues, lethal-need warnings, cause on succession screen | approved | APPROVED — NOT STARTED |  | accessibility, escape safety, object uses, danger cues, campfire, more side quests: player experience outside the five builds |
| FAM-08 | Future: an adult raised in the bandit clan decides their own future from circumstances, relationships, opportunities, needs and personal decisions (NPC Judgment, bandit factions); beyond the interim rule of FAM-07 | approved | APPROVED — NOT STARTED |  | needs NPC Judgment (Build 19) and bandit factions (WDR-016-C, 20+) |
| FR-01 | Lizards and spiders as enemies | approved | BLOCKED | owner assets | enemies and sound need asset uploads from the owner |
| FR-02 | Forgotten Memories waterfalls, fences and props | approved | APPROVED — NOT STARTED | art needed | art and presentation (crop stages, tool swings, sitting poses, chimney, sawhorse, props); can be pulled into any build when art arrives |
| FR-03 | A campfire for cooking raw meat outside the village | approved | APPROVED — NOT STARTED |  | accessibility, escape safety, object uses, danger cues, campfire, more side quests: player experience outside the five builds |
| FR-08 | Music and sound | approved | BLOCKED | owner assets | enemies and sound need asset uploads from the owner |
| FR-10 | Archery | approved | DEFERRED |  | archery, combat style, main storyline, Tiny Ranch pack: deferred or held by the owner |
| HOUSE-11 | Evaluate the alternatives where a ground-floor addition is impossible (OD-14 item 6): a smaller configuration, and whether an upper-floor or attic conversion is practical in the existing building system; no new upper-floor system invented to bypass geometry | approved | DEFERRED |  | OD-14 Phase 1 alternatives |
| MIN-L5 | Mining capability level 5 (integrated industrial mining) | proposal | APPROVED — NOT STARTED |  | mining level 5 is a proposal pending later confirmation |
| OWN-19 | Quest markers; Fireball storyline; side quests; busy-villager bubbles | approved | PARTIALLY IMPLEMENTED |  | accessibility, escape safety, object uses, danger cues, campfire, more side quests: player experience outside the five builds |
| OWN-28 | Living world intent; Morris world; ordinary inhabitant; magic learnable; multiplayer 3-4 host; isometric 8-dir; research rules | approved | PARTIALLY IMPLEMENTED |  | living-world umbrella: isometric and magic remain open |
| PL1-07 | NPCs sunk into beds/chairs | approved | PARTIALLY IMPLEMENTED | art needed | art and presentation (crop stages, tool swings, sitting poses, chimney, sawhorse, props); can be pulled into any build when art arrives |
| PL1-13 | Recognisable stove | approved | PARTIALLY IMPLEMENTED | art needed | art and presentation (crop stages, tool swings, sitting poses, chimney, sawhorse, props); can be pulled into any build when art arrives |
| PL2-010 | Recognisable sawhorse | approved | PARTIALLY IMPLEMENTED | art needed | art and presentation (crop stages, tool swings, sitting poses, chimney, sawhorse, props); can be pulled into any build when art arrives |
| PL2-013 | Usable furniture | approved | PARTIALLY IMPLEMENTED | art needed | art and presentation (crop stages, tool swings, sitting poses, chimney, sawhorse, props); can be pulled into any build when art arrives |
| PVG-01 | Procedural villages: expansion-aware house placement (footprint, parcel, road access, adjoining construction space, terrain and elevation, neighbours and boundaries, future rooms, household activity space) | approved | APPROVED — NOT STARTED | procedural village generation not yet scheduled | with the procedural settlement work (REC-007, SET-E); the owner said not to assign it to Build 15 |
| PVG-02 | Procedural villages: realistic medieval density and variation (compact homes by central roads and markets, larger plots outward, trades by infrastructure, farms on suitable land, irregular terrain-following roads and parcels) | approved | APPROVED — NOT STARTED | procedural village generation not yet scheduled | with the procedural settlement work (REC-007, SET-E); the owner said not to assign it to Build 15 |
| PVG-03 | Procedural villages: viable long-term housing options per home where practical (attached additions, smaller rooms, upper floors if supported, acquiring adjoining land, a new home elsewhere), decided by the real building and property systems | approved | APPROVED — NOT STARTED | procedural village generation not yet scheduled | with the procedural settlement work (REC-007, SET-E); the owner said not to assign it to Build 15 |
| PVG-04 | Procedural villages: reserve physical space for potential expansion footprints before placing neighbouring buildings and roads, without keeping it empty for ever | approved | APPROVED — NOT STARTED | procedural village generation not yet scheduled | with the procedural settlement work (REC-007, SET-E); the owner said not to assign it to Build 15 |
| PVG-05 | Procedural villages: growth over generations through inhabitants' legitimate construction (homes, roads, workshops in response to population, land, resources and finances), never an omniscient builder | approved | APPROVED — NOT STARTED | procedural village generation not yet scheduled | with the procedural settlement work (REC-007, SET-E); the owner said not to assign it to Build 15 |
| PVG-06 | Procedural villages: validation before acceptance (road access, no illegal parcel overlap, valid footprints, traversable routes, reasonable expansion opportunities, growth not blocked by the initial layout, terrain and resources fit the settlement type), configurable criteria, tested across seeds, terrain and densities | approved | APPROVED — NOT STARTED | procedural village generation not yet scheduled | with the procedural settlement work (REC-007, SET-E); the owner said not to assign it to Build 15 |
| PVG-07 | Procedural villages: deterministic generation and persistence; buildings, parcels, modifications, ownership and construction progress persist; regenerating or loading a region never overwrites player or NPC changes | approved | APPROVED — NOT STARTED | procedural village generation not yet scheduled | with the procedural settlement work (REC-007, SET-E); the owner said not to assign it to Build 15 |
| REC-002 | Over-the-air updates on the Hot Attic Games Mote architecture (fully automatic) | approved | BLOCKED | owner/external | over-the-air updates need the Hot Attic Games Mote repository |
| REC-006 | Castles, dungeons and caves in the world | approved | DEFERRED |  | bandit factions, skeletons, castles, dungeons: combat content outside the five builds |
| REC-007 | Several settlements (villages, towns, cities) with their own economies; NPC migration and regional jobs between them | approved | DEFERRED |  | real separate settlements and near/far simulation tiers need a larger world map |
| REC-008 | Near/far simulation tiers (detailed near the player, abstract far away, nothing duplicated on switching) | approved | UNKNOWN — INVESTIGATION REQUIRED |  | real separate settlements and near/far simulation tiers need a larger world map |
| REC-009 | Combat style: real-time aimed attacks, melee combos and abilities on cooldowns | approved | UNKNOWN — INVESTIGATION REQUIRED |  | archery, combat style, main storyline, Tiny Ranch pack: deferred or held by the owner |
| REC-011 | Main storyline after the first story quest (side quests now, story later) | approved | DEFERRED |  | archery, combat style, main storyline, Tiny Ranch pack: deferred or held by the owner |
| REC-012 | Tiny Ranch pack: on hold by the owner, not cancelled | approved | DEFERRED |  | archery, combat style, main storyline, Tiny Ranch pack: deferred or held by the owner |
| SET-E | Settlement expansion phase E: Actual inter-settlement network: persistent settlements, routes, logistics, competition, merchant AI | approved | APPROVED — NOT STARTED |  | real separate settlements and near/far simulation tiers need a larger world map |
| VP-01 | Living village politics: offices, individual NPC voting, elections, civic authority | approved | APPROVED — NOT STARTED |  | village politics (offices, voting, elections) is approved but in none of the five builds; voting weighs judgment, so after 19 |
| WDR-014-C | Comply with World Design Rule 14: Graveyards, Ancestry, and NPC Legacy | approved | APPROVED — NOT STARTED |  | graveyards, legacy, life chronicle: approved, in none of the five builds |
| WDR-015-C | Comply with World Design Rule 15: Political Authority, Social Hierarchy, and Civic Employment | approved | PARTIALLY IMPLEMENTED |  | village politics (offices, voting, elections) is approved but in none of the five builds; voting weighs judgment, so after 19 |
| WDR-016-C | Comply with World Design Rule 16: Bandit Factions, Criminal Careers, and Outlaw Leadership | approved | APPROVED — NOT STARTED |  | bandit factions, skeletons, castles, dungeons: combat content outside the five builds |

### Multiplayer track (isolated branch) (3)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| CRT-03 | Courtship between players in multiplayer (the other player may decline a proposal) | approved | APPROVED — NOT STARTED |  | the multiplayer track stays isolated on its own branch until the owner authorizes integration |
| DGA-D3 | Connectivity with no server | proposal | PARTIALLY IMPLEMENTED |  | the multiplayer track stays isolated on its own branch until the owner authorizes integration |
| MP-01 | Player-hosted multiplayer: two-player LAN milestone, host-authoritative | approved | ACTIVE DEVELOPMENT |  | the multiplayer track stays isolated on its own branch until the owner authorizes integration |

### Waiting on an owner decision (67)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| B13-15 | Android signing stability | approved | BLOCKED | owner decision first | signing key deferred by the owner; cloud saves and the formal platform entry need the owner |
| DGA-D1 | Meaning of "isometric" | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D10 | Formal platform/engine approval (U1, U2) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D11 | Living-society scope (U20, U21, P1-P3, balance review) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D12 | Approval to start phase 1 | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D2 | Isometric art source (J-G4) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D4 | Shared-world rules (pause, characters, heir) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D5 | Reputation/ownership/PvP (J-S3, U21) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D6 | Combat model and latency (U7) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D7 | Visible gear | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D8 | Era, county, political status, map scale | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-D9 | Magic (J-M1..4) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-R | Refactors (coordinates, players collection, command layer, fixed step + state hash, save split, appearance data, magic schema) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DGA-S | Isometric look spike; network feasibility spike | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DVW-B10 | Onboarding, first ten minutes | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DVW-B11 | No instant fast travel (rule) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DVW-B12 | Ethics/lore: thralldom, Church, content note | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DVW-B13 | Story kept as sparks; audit `story: true` quests | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| DVW-B8 | Skills for farming, husbandry, hunting, healing | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| ECON-P2 | Wildlife carrying capacity, sex floor, migration pool, hunting rights/quota, extinction, seasons (:116-121) | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| EXP-D | Living Economy Expansion: needs-driven economic architecture (needs, offers, adaptive prices, contracts, reservations, credit, bounded knowledge, organic safety levers) across households, employment, production, construction, markets, caravans, mining, the manor, bandits and NPC decisions; its OWN standalone build | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| FARM-CROP-01 | Share a field's crop among its cutters in proportion to their cutting work | approved | IMPLEMENTED — TESTING REQUIRED |  |  |
| FSE-10 | Living-economy build: gardens, rented land and pens, side hunting, household stalls, multiple incomes, goal-driven individual choices (class D) | approved | APPROVED — NOT STARTED | owner decision first | part of the standalone Living Economy build EXP-D, whose number and placement the owner decides (OD-LE-01) |
| LE-00 | Living Economy stage LE-00: Repository audit and cross-system dependencies (read-only architecture audit first) | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| LE-01 | Living Economy stage LE-01: Shared actor, need, offer, knowledge and contract model | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| LE-02 | Living Economy stage LE-02: Adaptive bids, asks, negotiation and settlement | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| LE-03 | Living Economy stage LE-03: Production, job choice and household budgets | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| LE-04 | Living Economy stage LE-04: Organic finance, merchants and manor behavior | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| LE-05 | Living Economy stage LE-05: Construction, ecology, mining, bandits and regional links | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| LE-06 | Living Economy stage LE-06: Multi-seed long-run, determinism and profiling | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| LE-07 | Living Economy stage LE-07: Release readiness and platform builds | approved | APPROVED — NOT STARTED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-02 | Owner decision: balance review of every provisional number | decision | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| OD-03 | Owner decisions: design gap assessment D1-D12 (isometric, magic, era, county) | decision | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| OD-04 | Owner decisions: chest and lock questions | decision | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| OD-07 | Owner decision: hunting in Gather mode | decision | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| OD-09 | Owner decisions: GAME_DESIGN items still open (U3-U5, U13, U16-U21) | decision | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| OD-LE-02 | Owner decision (Living Economy): Market board, direct negotiation or hybrid and visibility rules | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-03 | Owner decision (Living Economy): Wages, rents and service contracts in first release | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-04 | Owner decision (Living Economy): Business founding, partnerships, ownership and inheritance | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-05 | Owner decision (Living Economy): Loan interest, collateral, default and collection rules | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-06 | Owner decision (Living Economy): Permissible manor interventions and political authority | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-07 | Owner decision (Living Economy): Restricted-use advances and business/household account separation | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-08 | Owner decision (Living Economy): Barter, rental, repair and resource substitution | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-09 | Owner decision (Living Economy): Bandit market participation and regional trading limits | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-10 | Owner decision (Living Economy): Economic rumor, memory persistence and reliability | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-11 | Owner decision (Living Economy): Speculation, hoarding and deliberate market manipulation | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-12 | Owner decision (Living Economy): Charity, kinship support and communal relief | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-13 | Owner decision (Living Economy): Contract cancellation, penalties and death of a party | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-14 | Owner decision (Living Economy): Player intervention and visibility of market decisions | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OD-LE-15 | Owner decision (Living Economy): Performance and population acceptance targets | decision | BLOCKED | owner decision first | a standalone build whose number and placement the owner decides (OD-LE-01); not part of Builds 16-18 |
| OWN-02 | Wildlife balance follow-up; horse imported, use pending | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| OWN-08 | Post-audit remediation (SaveStore, tests.yml, release gates, stable test key) | approved | PARTIALLY IMPLEMENTED | owner decision first | signing key deferred by the owner; cloud saves and the formal platform entry need the owner |
| OWN-22 | Platforms: Android first then PC; touch/gamepad/KBM auto-detected; settings | approved | PARTIALLY IMPLEMENTED | owner decision first | signing key deferred by the owner; cloud saves and the formal platform entry need the owner |
| OWN-29 | Era, county, atlas storage, Godot, Android, PCG32 | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| PL1-11 | Google Drive cloud saves (staged) | approved | BLOCKED | owner decision first | signing key deferred by the owner; cloud saves and the formal platform entry need the owner |
| Q-08 | Resource depletion and wildlife sustainability | approved | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| Q-11 | Design gap assessment, phased sequence | proposal | BLOCKED | owner decision first | waiting on an owner decision, not development work |
| REC-010 | Class progression, 'system jobs' and a tech/research tree | approved | UNKNOWN — INVESTIGATION REQUIRED | owner decision first | waiting on an owner decision, not development work |
| REC-014 | Revisit the settlement, agriculture, food, resource, population and trade foundations using the recent research | approved | UNKNOWN — INVESTIGATION REQUIRED | owner decision first | waiting on an owner decision, not development work |
| ROAD-02 | Master Expansion Roadmap and Documentation Pack (owner, 2026-10-21): 17 Mining, 18 Settlements, 19 Judgment approved; 20 Living Economy, 21 Politics, 22 Bandits, 23 Legacy, Exploration and Multiplayer as proposed numbering | proposal | APPROVED — NOT STARTED | Owner designation | Numbering 20+ needs the owner |
| X19-ASSAULT | Should being assaulted oneself be a permanent memory (the proposed threshold makes it so; at the stress rate victims accumulate many)? | decision | BLOCKED |  |  |
| X19-CRT12 | Courtship proposals use fixed notoriety and regard cut-offs (CRT-12); keep 'no marrying a killer' absolute and weigh the rest with judgment, or keep the cut-offs? | decision | BLOCKED |  |  |
| X19-DECAY | Judgment decay rate for ordinary contributions (proposed 3 permille a day, half-life 231 days; demonstrated 1-10 permille over 365 days; murder never decays) | decision | BLOCKED |  |  |
| X19-GUARD | A guard who is the player's friend waives the fine (CRT-06) while SJD-Q08 says a guard can like someone and still enforce: keep, always enforce, or let friendship reduce but never waive the fine? | decision | BLOCKED |  |  |
| X19-HARMED | Relations.harmed lowers the player's standing with a victim's kin and friends instantly; when judgment is live, should word of mouth carry it instead (SJD-Q07 no instant broadcasts)? | decision | BLOCKED |  |  |
| X19-Q-TIMING | Gossip timing: keep 'spread' (identical results to telling an hour's meetings at once; rare long catch-up frames ~8.6 ms on a phone) or allow 'scheduled' (each meeting at its own seeded minute: smallest frames, but word passes at different times, so outcomes differ slightly)? | decision | BLOCKED |  |  |
| X19-REGARD | Relations regard is both trust (believing stories) and harm (a seen crime lowers it), so victims believe culprits less: accept this coupling or separate trust from regard? | decision | BLOCKED |  |  |

### Owner or external action (not development work) (6)

| ID | Item | Kind | Status | Gate | Why here |
|---|---|---|---|---|---|
| AR-OWNER | Audit remediation owner checklist: public-release environment, repository visibility, private infrastructure repository | approved | BLOCKED | owner/external | only the owner (or the environment's settings) can do this |
| AR-P0-3 | Owner must delete `inventory/registry` by hand | approved | BLOCKED | owner/external | only the owner (or the environment's settings) can do this |
| AR-P1-2 | Fixed on staging; PR #1 branch still has push-triggered workflow | approved | PARTIALLY IMPLEMENTED | owner/external | only the owner (or the environment's settings) can do this |
| B12A-10 | Hardware verification of everything on real devices (umbrella of the device queue) | approved | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED | owner/external | only the owner (or the environment's settings) can do this |
| ENV-RTK | RTK token tool and its hook persistent in the cloud environment | approved | BLOCKED | owner/external | only the owner (or the environment's settings) can do this |
| Q-10 | Hot Attic Games read-only registry | approved | BLOCKED | owner/external | only the owner (or the environment's settings) can do this |

## Real-device verification queue

Every open entry with a device check outstanding (a `playtest` need, or the status AUTOMATED TESTS PASSED —
PLAYTEST REQUIRED). Automated tests do not count as device verification.

| ID | Requirement | Needs | Status |
|---|---|---|---|
| ARM-01 | Armorer availability: verify the armorer exists, keeps a schedule, a place, stock, a path, and trades with the player (the owner's playtest: never available) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B12A-10 | Hardware verification of everything on real devices (umbrella of the device queue) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B13-12 | B closes only quantity selector | controller | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B13-13 | Touch sprint | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B14-01 | Harvest or talk: A works the resource, Y / T talks to the villager beside it | controller | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B14-06 | Carts in play: pulled storage, parking, cart stops, deliveries, household market runs | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B14-13 | A controller connected to a phone or tablet hides the touch buttons and uses the pad controls | phone, controller | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B7-001 | Starting coins | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B7-005 | Earning money discoverable; "Trade with" | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B7-010 | HUD anchoring on Android | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B7-011 | Tapping trees/ore does nothing | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B7-012 | Gather mode | phone, controller | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B7-013 | Brown glyph icons | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| B8-018 | Roof flicker indoors | windows | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CQ-01 | Sword responsiveness and hit detection (buffer, reach, phases, walls) | phone, controller | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-01 | Player courtship and marriage through gifts: attraction, dating, proposal that can be declined if too early | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-02 | Friendship: a Befriend option appears after help and gifts; no proposal needed | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-04 | Villagers court each other through gifts, dating and proposals by the player's rules, replacing the random pairing chance | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-05 | Gift tastes follow obvious things: a villager's trade and current needs; favourite gifts speed courting, traditional gifts always work | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-07 | Courtship and marriage between any two humans, same sex included; humans only for now | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-08 | Shared experiences start friendships and romances: working together and personal interactions build regard and attraction | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-09 | Weighting of closeness and conversation: proximity about 1 point, a conversation 0.25, later ones about 0.11, so talk spamming does little | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-10 | Relationship weighting system: closeness over time (the nearby-name prompt), many factors, distinct days known; no button spamming to a quick marriage | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-11 | Single villagers with spare money and goods actively seek company: spend time near the one they court or befriend, and buy gifts | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CRT-12 | Proposals can be refused: not wanting to marry, a rival suitor with a better offer, or the suitor's deeds (killing villagers, crimes, theft from their friends or family) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CTR-01 | Skilled-trade sales counters: every established skilled business (armorer, smith, carpenter, others as they develop) has a working customer counter | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CTR-02 | At a counter: a prompt, press A, and the business's available shopkeeper walks to the counter to serve | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| CTR-03 | Shopkeeper availability: ordinary villagers with schedules; when summoned an available one comes, else the player is told clearly; employees or family may serve; no interrupted emergencies, no duplicate service tasks | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| FARM-09 | Farmland placement by drag: two green corners, live price at screen centre, lease or buy, confirm | Touch drag on an Android phone, Physical gamepad | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| FR-04 | Pad shortcuts for the Journal and Build menus; complete on-screen controls list | a controller: D-pad up opens the Journal, left stick press opens Build | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| MP-01 | Player-hosted multiplayer: two-player LAN milestone, host-authoritative | two-device LAN, phone | ACTIVE DEVELOPMENT |
| PL1-03 | Merchant quantity control | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| PL1-05 | current/max inside bars | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| Q-04 | Resources & Gathering journal page | phone | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-00 | Save continuity across separate test builds (Android reinstall): user-selected save location or Android-supported export/import; permanent signing key deferred | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-02 | A stable save identity independent of build numbers (requirement 2) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-03 | Explicit save-schema versioning and forward migration from older supported formats (requirements 3, 4) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-04 | Back up the original before migrating, validate the migrated save before adopting it, preserve the original on failure, never leave a partial conversion, never destroy the only usable save (requirements 5-8, 15) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-05 | A clear way to reconnect to an existing save after an Android reinstall, using supported Android storage (Storage Access Framework or equivalent), no unrestricted filesystem access (requirements 9, 10) | Android phone: export, uninstall, install a new build, import, continue the same world | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-06 | The same versioning and migration principles on Windows and Linux (requirement 11) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-07 | Migration tests over persistent world data: terrain changes, resources, NPCs, households, relationships, buildings, inventories, settlements, simulation state (requirement 12) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-08 | Preserve unknown or future data where practical; no claim of backward compatibility unless implemented and tested (requirement 13) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| SAVE-09 | An independently recoverable backup and documented recovery instructions (requirement 14) | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| WDR-008-C | Comply with World Design Rule 8: Player Knowledge and Wiki | phone, controller | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |
| WDR-010-C | Comply with World Design Rule 10: Depth Without Obscurity | phone, controller | PARTIALLY IMPLEMENTED |
| WR-01 | Protected wildlife breeding refuges, offspring cohorts and dispersal | a device check | AUTOMATED TESTS PASSED — PLAYTEST REQUIRED |

## APPROVED — NOT STARTED (63)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| B14-07 | Cliff steps (pickaxe, Mining), wooden stairs and walkways (planks, nails, Carpentry, a mallet) | owner message and answers 2026-10-19 (DEVELOPMENT_LEDGER B14-07) |  |  | Start next (owner order) |
| B14-09 | Skeletons in caves and uncleared woods (guard by day, roam at night, 3-day respawn; bones and rusty gear) | owner answers 2026-10-19 |  |  | After B14-07 |
| B14-11 | Animal Farm pack: the horse and farm animals | owner message 2026-10-19; horse role decided by the owner 2026-10-19: a plough horse bought from the visiting caravan | `a91b8f1`, `f9fb853` |  | implement the caravan's plough horse |
| CON-01 | Universal negotiated goods-procurement contracts (item, quantity, price per unit; accept, reject or counter; any party to any party) | docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md |  |  |  |
| CRT-03 | Courtship between players in multiplayer (the other player may decline a proposal) | docs/directives/2026-10-19_courtship_friendship.md |  | after CRT-01; after MP-01 |  |
| DVW-A10 | No black-hole spaces (:35) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 254) |  |  |  |
| DVW-A9 | Player can always escape predators/bandits (:34) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 253) |  |  |  |
| DVW-B2 | Assault and killing as recorded, fined crimes; heir inheritance of fines/stain | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 274) |  |  |  |
| DVW-B3 | Coin sinks people enjoy (luxury imports, feasts, weddings, offerings, heriot) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 275) |  |  |  |
| DVW-B4 | Goods decay (grain spoils, clothes/armour/carts wear) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 276) |  |  |  |
| DVW-B5 | Predictable taxes with hysteresis, announced | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 277) |  |  |  |
| DVW-B7 | Life chronicle, titles, memorial | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 279) |  |  |  |
| DVW-B9 | Readable danger: howl/roar cues, lethal-need warnings, cause on succession screen | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 281) |  |  |  |
| EXP-A | Expansion A: Mining & Industrial Development (independent future expansion; supporting document is the primary specification) | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |  | after MIN-A; after MIN-B; after MIN-C; after MIN-D; after MIN-E; after MIN-F; after MIN-G | see docs/EXPANSION_ROADMAP.md; begins after the Build 16 baseline |
| EXP-B | Expansion B: Settlement Advancement & Regional Economy (independent future expansion; supporting document is the primary specification) | docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf |  | after SET-A; after SET-B; after SET-C; after SET-D; after SET-E | see docs/EXPANSION_ROADMAP.md; begins after the Build 16 baseline |
| EXP-C | Expansion C: NPC Judgment System (Subjective Judgment & Universal Decision Engine; independent future expansion after a stable Build 16 baseline) | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  | after SJD-A; after SJD-B; after SJD-C; after SJD-D; after SJD-E; after SJD-F; after SJD-G; after SJD-H | see docs/EXPANSION_ROADMAP.md; begins after the Build 16 baseline |
| EXP-D | Living Economy Expansion: needs-driven economic architecture (needs, offers, adaptive prices, contracts, reservations, credit, bounded knowledge, organic safety levers) across households, employment, production, construction, markets, caravans, mining, the manor, bandits and NPC decisions; its OWN standalone build | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx; docs/directives/2026-10-20_fam07_clarification_living_economy.md |  |  |  |
| FAM-08 | Future: an adult raised in the bandit clan decides their own future from circumstances, relationships, opportunities, needs and personal decisions (NPC Judgment, bandit factions); beyond the interim rule of FAM-07 | docs/directives/2026-10-20_fam07_clarification_living_economy.md |  | after WDR-016-C |  |
| FR-02 | Forgotten Memories waterfalls, fences and props | owner message 2026-10-19 |  |  | With B14-07 |
| FR-03 | A campfire for cooking raw meat outside the village | owner request in Build 8 testing (BUILD_8_ISSUES) |  |  |  |
| FSE-10 | Living-economy build: gardens, rented land and pens, side hunting, household stalls, multiple incomes, goal-driven individual choices (class D) | docs/directives/2026-10-20_food_security_goal_driven_economy.md |  | after EXP-D |  |
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | docs/directives/2026-10-19_memory_refuges_politics.md Part I |  | after DVW-B1 |  |
| LE-00 | Living Economy stage LE-00: Repository audit and cross-system dependencies (read-only architecture audit first) | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 17 |  |  |  |
| LE-01 | Living Economy stage LE-01: Shared actor, need, offer, knowledge and contract model | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 17 |  |  |  |
| LE-02 | Living Economy stage LE-02: Adaptive bids, asks, negotiation and settlement | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 17 |  |  |  |
| LE-03 | Living Economy stage LE-03: Production, job choice and household budgets | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 17 |  |  |  |
| LE-04 | Living Economy stage LE-04: Organic finance, merchants and manor behavior | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 17 |  |  |  |
| LE-05 | Living Economy stage LE-05: Construction, ecology, mining, bandits and regional links | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 17 |  |  |  |
| LE-06 | Living Economy stage LE-06: Multi-seed long-run, determinism and profiling | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 17 |  |  |  |
| LE-07 | Living Economy stage LE-07: Release readiness and platform builds | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 17 |  |  |  |
| MIN-A | Mining expansion phase A: Audit terrain, elevation, mining, inventory, recipes, AI, pathfinding, saves and map generation; architecture and measurable acceptance tests | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |  |  |  |
| MIN-B | Mining expansion phase B: Exhausted ore outcrops stay quarryable stone; quarry chain and stone logistics | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |  | after MIN-A |  |
| MIN-C | Mining expansion phase C: Natural prospecting clues, prospector profession, forge-made toolkit, samples and assay | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |  | after MIN-B |  |
| MIN-D | Mining expansion phase D: Finite hidden deposit discovery; settlement mining capability levels 1-4 with autonomous NPC adoption | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |  | after MIN-C |  |
| MIN-E | Mining expansion phase E: Open-pit excavation, spoil, dirt and topsoil as materials, ramps, hauling and geological layers (where the architecture supports them) | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |  | after MIN-D |  |
| MIN-F | Mining expansion phase F: Underground and cave mining, cutaway presentation, supports, minecarts, track construction and full industrial dependencies | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |  | after MIN-E |  |
| MIN-G | Mining expansion phase G: 100/365-day multi-seed simulations and gameplay tests; save validation; economic conservation; no resource spawning | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |  | after MIN-F |  |
| MIN-H | Enterable caves and underground mining environments (roof-fade principle, NPC pathing, persistence) | docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md |  |  |  |
| PVG-01 | Procedural villages: expansion-aware house placement (footprint, parcel, road access, adjoining construction space, terrain and elevation, neighbours and boundaries, future rooms, household activity space) | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 2 |  |  |  |
| PVG-02 | Procedural villages: realistic medieval density and variation (compact homes by central roads and markets, larger plots outward, trades by infrastructure, farms on suitable land, irregular terrain-following roads and parcels) | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 2 |  |  |  |
| PVG-03 | Procedural villages: viable long-term housing options per home where practical (attached additions, smaller rooms, upper floors if supported, acquiring adjoining land, a new home elsewhere), decided by the real building and property systems | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 2 |  |  |  |
| PVG-04 | Procedural villages: reserve physical space for potential expansion footprints before placing neighbouring buildings and roads, without keeping it empty for ever | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 2 |  |  |  |
| PVG-05 | Procedural villages: growth over generations through inhabitants' legitimate construction (homes, roads, workshops in response to population, land, resources and finances), never an omniscient builder | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 2 |  |  |  |
| PVG-06 | Procedural villages: validation before acceptance (road access, no illegal parcel overlap, valid footprints, traversable routes, reasonable expansion opportunities, growth not blocked by the initial layout, terrain and resources fit the settlement type), configurable criteria, tested across seeds, terrain and densities | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 2 |  |  |  |
| PVG-07 | Procedural villages: deterministic generation and persistence; buildings, parcels, modifications, ownership and construction progress persist; regenerating or loading a region never overwrites player or NPC changes | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 2 |  |  |  |
| SET-A | Settlement expansion phase A: Design and ledger: requirement ids, cross-industry skill schema, save compatibility, dependency audit | docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf |  |  |  |
| SET-B | Settlement expansion phase B: Settlement capability model: per-industry capabilities, NPC knowledge, workshops, prerequisites, decay and continuity | docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf |  | after SET-A |  |
| SET-C | Settlement expansion phase C: Abstract regional economy: off-map settlements with finite demand, supply and budgets; variable caravan trade | docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf |  | after SET-B |  |
| SET-D | Settlement expansion phase D: Settlement development: growth and decline, specialization, housing, infrastructure, population and employment | docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf |  | after SET-C |  |
| SET-E | Settlement expansion phase E: Actual inter-settlement network: persistent settlements, routes, logistics, competition, merchant AI | docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf |  | after SET-D |  |
| SJD-A | Judgment expansion Gate A: Build 16 stabilization and baseline (seeds, remote commit, known defects); no implementation | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  |  |  |
| SJD-B | Judgment expansion Gate B: architecture audit (Godot services, relationships, economic decisions, event hooks, save format, risks) and integration map with open questions | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  | after SJD-A |  |
| SJD-C | Judgment expansion Gate C: isolated prototype (event catalog, beliefs, signed interpretation, GOOD/BAD ledger, tests), no effect on live behaviour | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  | after SJD-B |  |
| SJD-D | Judgment expansion Gate D: decision prototype (factor registry, utility profiles, the 50-iron scenario, explanation traces, determinism) | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  | after SJD-C |  |
| SJD-E | Judgment expansion Gate E: first gated integration in one low-risk domain, feature flag off by default, matched-seed tests | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  | after SJD-D |  |
| SJD-F | Judgment expansion Gate F: incremental rollout (trade, aid, friendship, courtship, employment, crime, politics) | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  | after SJD-E |  |
| SJD-G | Judgment expansion Gate G: full soak and calibration: 100/365-day comparisons, performance and save migration | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  | after SJD-F |  |
| SJD-H | Judgment expansion Gate H: owner review; release and broad enablement approved separately | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |  | after SJD-G |  |
| VP-01 | Living village politics: offices, individual NPC voting, elections, civic authority | docs/directives/2026-10-19_memory_refuges_politics.md Part III |  | after GM-01; after DVW-B1 |  |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | Design the five aspiration domains |
| WDR-014-C | Comply with World Design Rule 14: Graveyards, Ancestry, and NPC Legacy | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | Graveyard and headstones with GM-01 |
| WDR-016-C | Comply with World Design Rule 16: Bandit Factions, Criminal Careers, and Outlaw Leadership | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | Design factions and careers |
| X18-STONECUT | Professional stonecutter: an independent trade and business that dresses and sells building blocks | docs/directives/2026-10-21_stone_q1_and_stonecutting_trade.md |  | after PROS-18; after Q18-9 |  |

## ACTIVE DEVELOPMENT (18)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| B16-AUDIT | Build 16 complete status audit, maintained (docs/BUILD_16_STATUS.md) | owner message 2026-10-20 (section 9: Build 16 complete status audit and remaining work) |  |  |  |
| B16-READY | Build 16 development audit and release-readiness report | docs/directives/2026-10-21_build16_audit_release_readiness.md |  |  |  |
| DVW-A3 | Re-measure money supply, 100 and 365 days, 2-3 seeds, no player (:28) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 247) |  |  | measured by the Build 15 runs (docs/release/LONG_RUN_SIMULATION.md): coins grow from about 2900 to about 6000 in 100 days with the 30-coin caravan; finish with the 365-day results |
| FARM-08 | Shared-yield comparison: the per-cell model and seasonal farming together at several yields (0.9-3 a cell), identical seeds; grain produced/consumed/sold/stored/unsold, seed use and recovery, labour a harvest, food security and starvation causes, manor and family-farm viability, prices and demand, livestock feed and milk, seasonal timing; the milk collapse explained; a recommended yield for the owner's approval | docs/directives/2026-10-21_fse12_fse13_farming_decision.md |  | after FSE-12; after FSE-13 | Owner decision on the FARM-08 yield and switches and on the remaining balance options (herd cost vs milk income, 4-day trough vs harvest gaps, household feed purse or granary sales, unsold milk and cheese); crop sharing decided (FARM-08-Q-CROP, option B) and implemented on wip/farm-cropshare (FARM-CROP-01) |
| FSE-00 | Food security, household production, land use, markets and goal-driven economic behavior (final master directive) | docs/directives/2026-10-20_food_security_goal_driven_economy.md |  | after PAR-00; after OD-19; after PAR-02A |  |
| MP-01 | Player-hosted multiplayer: two-player LAN milestone, host-authoritative | docs/directives/2026-10-19_multiplayer_foundation.md | `d18d7d1`; net_test (36, separate processes); branch wip/multiplayer |  |  |
| OVN-01 | Master overnight directive: autonomous lead-engineer execution of approved work, Builds 15 to 18 strictly in order, the build-completion definition, the skipped-items register, release and decision authority | docs/directives/2026-10-20_master_overnight_development_directive.md |  |  |  |
| OVN-02 | Final development mandate: Build 15 closure standard, living-world philosophy (WDR-022), release when functionally complete, then Builds 16, 17, 18 in order, autonomous engineering | docs/directives/2026-10-20_final_development_mandate.md |  |  |  |
| PERF-01 | Simulation performance audit: measured explanation of the runtime growth since the 530-689 s 365-day benchmark (regression, contention, environment or estimates) | docs/directives/2026-10-20_simulation_performance_audit.md; docs/directives/2026-10-20_build15_followup_performance_clarification.md |  |  |  |
| PROS-18 | Expansion 18 prospective implementation (settlement capability and specialization, regional supply and demand, routes and transport, settlement inventories and reports, competition and cooperation, caravan subsidy replacement plan, conservation tests) | docs/directives/2026-10-21_parallel_prospective_development_18_19.md | `8eec56e`, `283ec55`; settlement_test 63, regional_test 67, caravan_compare 20/50; run_tests, world_test, start_test, parity_test, conservation_test, business_test; branch wip/expansion18-preparation |  |  |
| PROS-19 | Expansion 19 prospective implementation (personal memory, subjective judgment, signed opinions, decision weighting that influences not dictates, provenance and sharing, persistence and migration prototypes, determinism and large-population performance tests) | docs/directives/2026-10-21_parallel_prospective_development_18_19.md | `e05d367`, `693e0c3`, `6615da4`, `1b05da0`, `e91d903`, `05adc9d`; judgment_test 164, judgment_live_test 53, judgment_decay_demo 24, judgment_perf 23; run_tests, world_test, relations_test, parity_test, conservation_test, save_transfer_test; sim_gate identical when off; branch wip/expansion19-preparation |  |  |
| REL-15-18 | Release authorization for Builds 15 to 18: create and publish each when all its release gates pass (section 4), with the established platforms, naming and procedure; private test builds stay private | docs/directives/2026-10-20_master_overnight_development_directive.md section 9 |  | after REL-14-16 | Build 16 when it meets OVN-01 section 4 and OVN-02 section 5 |
| WDR-022-C | Comply with World Design Rule 22: classify every finding as defect, legitimate outcome or future improvement; no hidden rescue; tests check mechanics and integrity, never prosperity | docs/directives/2026-10-20_final_development_mandate.md |  |  |  |
| X18-Q12 | Implement Q18-12 transport: flat-rate fees on regular routes or scheduled delivery, negotiated special deliveries, self-collection; smoke tests | docs/directives/2026-10-21_expansion18_capability_simulations_contracts.md |  |  |  |
| X18-Q12-BOOTH | Courier booths in each city, village and major business, serving regular routes (flat fee per load or scheduled delivery); special deliveries negotiated by choosing a recipient among the people and businesses the buyer knows | docs/directives/2026-10-21_courier_booths_known_recipients.md |  |  |  |
| X18-Q12-POST | Courier contract popup like online postage (dropdowns: quantity, item, recipient, location, collect payment, deliver or deposit proceeds, money/item type and amount, route or special) assembled into a readable instruction; recipients from known people and businesses incl. prior trading contacts (owner represents the business; location from world records); fee computed from route type, distance, burden, capacity, stops, return/deposit, labour, notarial service; physical execution; fulfilled only when obligations are done | docs/directives/2026-10-21_courier_contract_interface_pricing.md |  |  |  |
| X18-Q13 | Implement Q18-13 signing: small agreements unsigned; formal contracts and ownership transfers signed face to face, or through a courier-notary with legal skill carrying the documents; no remote instant signing; smoke tests for incomplete, rejected, interrupted and completed agreements | docs/directives/2026-10-21_expansion18_capability_simulations_contracts.md |  |  |  |
| X18-SIM | Comparative capability simulations (baseline, conservative, moderate, aggressive; levels 0,2,5,8,10; implemented industries; settlement size, resource and labour scenarios; 30 and 90 days) and a recommendation; no permanent constants before owner review | docs/directives/2026-10-21_expansion18_capability_simulations_contracts.md |  |  |  |

## PARTIALLY IMPLEMENTED (33)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| AR-P1-2 | Fixed on staging; PR #1 branch still has push-triggered workflow | docs/release/AUDIT_REMEDIATION.md (audit inventory row 368) |  |  | PR #1 was closed unmerged on 2026-10-20 after its work was verified in staging (OPS-01). Its branch claude/charming-albattani-8jjfya still carries a push-triggered workflow; nothing pushes to it. Deleting or editing that branch is the owner's call (repository change). |
| B14-10 | Craftpix farm plants: crop stages, produce, crates, fruit trees chopped like the others | owner message 2026-10-19 | `f9fb853` |  |  |
| B7-007 | Deposits never refill; no stone source | docs/release/BUILD_7_ISSUES.md (audit inventory row 48) |  |  |  |
| B8-007 | Wrong tool shown | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 108) |  |  |  |
| CRT-06 | Friendship benefits: better prices, help and favours, gossip and news, backing in disputes and votes | docs/directives/2026-10-19_courtship_friendship.md (answers) | game/tests/relations_test.gd |  | friends vote with the player once elections exist |
| DVW-A13 | Every visible object has a use (:38) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 257) |  |  |  |
| DVW-B1 | Villager relationships, memory of favours/gifts/harms, gossip | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 273) |  |  | harms lower regard; gossip spreads deeds |
| EQ-05 | The player is the disruptive variable: no hidden protection of the world from player consequences | docs/directives/2026-10-19_build16_world_equilibrium.md |  |  |  |
| FARM-06 | Manor fields need seed and labour like any farm (no free seed, crops or materials) | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `68a3611`; world_test::_fse12_shared_fields |  | Activated with FSE-12 after the owner's review |
| FSE-12 | One agricultural model for player and village farming (parity) | docs/directives/2026-10-20_agricultural_findings_followup.md | `68a3611`; world_test::_fse12_shared_fields | after FSE-16 | Owner's choice: (a) the player's yield as is, (b) one lower per-cell yield for everyone, (c) fewer cells sown; decided with FSE-13 |
| FSE-13 | Seasonal farming for village fields (implemented and tested in isolation; activation needs owner review) | docs/directives/2026-10-20_agricultural_findings_followup.md | `01a83f0`; world_test::_fse13_seasonal_fields | after FSE-12 | Owner's review of docs/design/FSE13_COMPARISON.md; recommendation: pair with farm plots and FSE-12 and compare again |
| OWN-08 | Post-audit remediation (SaveStore, tests.yml, release gates, stable test key) | docs/DECISIONS.md (audit inventory row 324) |  | after B13-15 |  |
| OWN-19 | Quest markers; Fireball storyline; side quests; busy-villager bubbles | docs/DECISIONS.md (audit inventory row 335) |  |  | More side-quest templates |
| OWN-22 | Platforms: Android first then PC; touch/gamepad/KBM auto-detected; settings | docs/DECISIONS.md (audit inventory row 338) |  | after FR-08 |  |
| OWN-28 | Living world intent; Morris world; ordinary inhabitant; magic learnable; multiplayer 3-4 host; isometric 8-dir; research rules | docs/DECISIONS.md (audit inventory row 344) |  | after MP-01; after DGA-D1; after DGA-D9 |  |
| PL1-07 | NPCs sunk into beds/chairs | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 144) |  |  |  |
| PL1-10 | Player businesses, staged (1-4) | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 147) |  |  |  |
| PL1-12 | Red flowering plant not pickable | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 149) |  |  | Add tile 2656 to overworld flowers with the next overworld generator version (with B14-09) |
| PL1-13 | Recognisable stove | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 150) |  |  |  |
| PL2-008 | Expandable property | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 163) |  |  |  |
| PL2-010 | Recognisable sawhorse | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 165) |  |  |  |
| PL2-013 | Usable furniture | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 168) |  |  |  |
| PL2-014 | Modular house/workshop expansion | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 169) |  |  |  |
| PL2-015 | Farming, livestock, hand plough | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 170) |  |  |  |
| WDR-001-C | Comply with World Design Rule 1: Material Interdependency | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | docs/systems/MATERIAL_INTERDEPENDENCY.md lists the open violations; resolve with recipes or justified exceptions in Build 17 (mining and industry) |
| WDR-002-C | Comply with World Design Rule 2: Professional Interdependency | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | docs/systems/MATERIAL_INTERDEPENDENCY.md professions table; the sage's supply link |
| WDR-004-C | Comply with World Design Rule 4: Economic Consequences | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | Comparison runs (B14R-02); scarcity responses audit |
| WDR-009-C | Comply with World Design Rule 9: Emergent Gameplay | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | GM-01 |
| WDR-010-C | Comply with World Design Rule 10: Depth Without Obscurity | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | device playtest (phone, controller); cart-route feedback when carts gain collision (SKIPPED_ITEMS, Build 16) |
| WDR-012-C | Comply with World Design Rule 12: NPC Competition and Economic Rivalry | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | Competition audit and design |
| WDR-013-C | Comply with World Design Rule 13: Finite Resources and Actual Consumption | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | WR-01; owner decision OD-01 on deposits |
| WDR-015-C | Comply with World Design Rule 15: Political Authority, Social Hierarchy, and Civic Employment | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | VP-01 |
| X18-CAPCOMP | Capability composition: workforce capability from local experience, effective capability capped by operational facilities | docs/directives/2026-10-22_q18_11b_decision.md | `4ce9927`; experience_test 31 (new), capability 72, settlement 83, regional 71, courier 44, contract_sign 20, farming 217, farm_plots 104, contracts 138, world 339, conservation 8, run_tests 3544, start 499; economy_sim 30 days seed 1 fingerprint 1c755f53 unchanged, no leaks | after Q18-11B; after PROS-18 | Owner: facility caps, starting experience, thresholds; open: industry for unattributed work (trade at stall, slaughter, hunting, foraging, clearing, fencing, building, manor survey/trial/excavation/tunnel/shoring/backfill/haul), level rounding for modifiers, wages fixed at posting, drop timing on death/emigration |

## IMPLEMENTED — TESTING REQUIRED (24)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| B7-009 | Treasury starts below reserve; no paid manor work until ~day 12 | docs/release/BUILD_7_ISSUES.md (audit inventory row 50) |  | owner decision after comparison | Four-way comparison runs, then owner decision |
| B7-014 | Caravan grows currency ~12x a year | docs/release/BUILD_7_ISSUES.md (audit inventory row 55) |  | owner decision after comparison | Four-way comparison runs, then owner decision |
| DVW-A14 | Play one whole life before each release (:39) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 258) |  |  | the owner's or a tester's play-through on Build 15 |
| EQ-22 | Caravan buying order: smiths first starves the hide and leather chain after parity | docs/release/LONG_RUN_SIMULATION.md | `5cce264`; od16_test::test_caravan_buys_by_need |  | Owner to confirm the reading of need (the seller's need to sell); measure in the four-seed runs |
| FAM-01 | Household succession: when one parent dies the surviving parent (either sex) becomes responsible for the dependants and every household decision; the household keeps functioning | docs/directives/2026-10-20_housing_succession_adoption.md Part 3.1 | game/tests/housing_test.gd test_responsible_adult_after_a_death |  | confirm over a long run that a widowed parent's household keeps feeding itself and building |
| FAM-02 | Both parents dead: dependent children never found households or start construction; an existing household takes them in | docs/directives/2026-10-20_housing_succession_adoption.md Part 3.2, Part 4.3 | game/tests/family_test.gd |  |  |
| FAM-03 | Informal adoption order: living grandparents (both sides), then the nearest eligible blood relative by genealogy, then another villager's household with a responsible adult; no adoption authority | docs/directives/2026-10-20_housing_succession_adoption.md Part 4.1-4.2 | game/tests/family_test.gd | after FAM-02 |  |
| FAM-04 | Integration: the child becomes a dependant of the receiving household and uses its house; genealogy (mother, father, birth family) is never overwritten; a surname change is allowed and does not corrupt the tree | docs/directives/2026-10-20_housing_succession_adoption.md Part 4.3 | game/tests/family_test.gd | after FAM-02 |  |
| FAM-05 | Occupancy after a child is taken in is recalculated; any housing need it creates belongs to the receiving household's responsible adult; no house is built automatically | docs/directives/2026-10-20_housing_succession_adoption.md Part 4.4 | game/tests/family_test.gd | after FAM-02; after HOUSE-03 |  |
| FAM-06 | Family scenario tests: the eight family scenarios of the directive, written when the mechanics are implemented | docs/directives/2026-10-20_housing_succession_adoption.md Part 6 | game/tests/family_test.gd; game/tests/housing_test.gd | after FAM-02 |  |
| FAM-07 | Unplaced orphans join the bandit clan (OD-11): after surviving parent, grandparents, nearest eligible blood relative and a willing villager household; the child keeps identity, age, genealogy and relationships and stays a child (no adult combat) | docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md (OD-11) | game/tests/family_test.gd test_nobody_can_take | after FAM-02; after FAM-03; after WDR-016-C | suites; then COMPLETE once a long run has exercised it or tests suffice |
| FARM-08B | Cattle decline under the shared and seasonal farming model: investigation | docs/directives/2026-10-21_farm08_cattle_investigation.md | `463861a`; herd_test (19 checks, 10 fail on the old code); 40/120-day local runs |  |  |
| FARM-CROP-01 | Share a field's crop among its cutters in proportion to their cutting work | docs/directives/2026-10-22_farm08_q_crop_decision.md | `132960a`; crop_share_test 19, farming_test 217, world_test 339, run_tests 3544, farm_plots_test 104, conservation_test 8, start_test 499, reserve_test 43, wiki_test; economy_sim 30 days seed 1 leaks 0; branch wip/farm-cropshare | after FARM-08-Q-CROP | Owner: authorize merging into Build 17 now, or carry it to the next build |
| HOUSE-12 | Sleeping loft: a lightweight house improvement adding sleeping places after real construction (materials, labour, time), integrated with sleeping, occupancy and household behaviour; not a navigable second floor | docs/directives/2026-10-20_sleeping_loft_and_long_run_reliability.md | game/tests/housing_test.gd test_sleeping_loft, test_housing_options_weighed |  | a loft finished in a year-long run, once the timber supply holds (Build 16, OD-16) |
| MERCH-01 | A village seed merchant or booth selling crop and flower seed, berry cuttings and fruit-tree seed or saplings, with real stock, coins and restocking | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `fd2f9de`; farming_test (test_propagation, test_perennials, test_household_seed, test_seed_seller) | after SEED-02 | Measure in the four-seed runs; owner to confirm the readings |
| PICK-01 | A caught pickpocket raises a witness report through World.witness (OD-20), as assault does (PAR-05): awareness only from legitimate witnesses, no omniscient guards, not always an audible alarm | docs/directives/2026-10-21_build16_owner_decision_resolution.md | `b018185`; world_test::_pick01_reports | after OD-20 | Owner to confirm two readings: the Stealth guard_radius perk now narrows who sees a caught try; a told guard fines a thief in sight |
| SEED-02 | Planting consumes real seed or propagation material for every plant type; harvests recover seed or cuttings at a deterministic chance | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `fd2f9de`; farming_test (test_propagation, test_perennials, test_household_seed, test_seed_seller) | after SEED-01 | Measure in the four-seed runs; owner to confirm the readings |
| SEED-03 | Perennials (fruit trees, berry bushes) survive harvest and bear again by season; growth follows the 8-day year | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `fd2f9de`; farming_test (test_propagation, test_perennials, test_household_seed, test_seed_seller) | after SEED-01 | Measure in the four-seed runs; owner to confirm the readings |
| SEED-04 | Households save planting material from their own harvests | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `fd2f9de`; farming_test (test_propagation, test_perennials, test_household_seed, test_seed_seller) | after SEED-02 | Measure in the four-seed runs; owner to confirm the readings |
| SHOP-01 | Skilled businesses sell what they produce or stock and buy useful goods by real need and funds (a carpenter buys timber, an armorer materials), the same mechanics for player and villagers | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `f56e9bb`; world_test::_shop01_need |  | Measure in the next four-seed runs; owner to set a stocking horizon and confirm the readings |
| STALL-06 | Villager households build, stock, open, close and restock stalls by the player's mechanics, selling surplus with the family's needs weighed | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `afef91d`; stalls_test |  |  |
| TRADE-01 | Trade-specific purchasing at counters through the shared trade rules (OD-19 reserve, PAR-02) | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `f56e9bb`; world_test::_shop01_need | after SHOP-01 | Measure in the next four-seed runs; owner to set a stocking horizon and confirm the readings |
| WR-02 | Grazers in a wood all stop eating while the wood is over its grass capacity, so some starve together | WR-01 agent report 2026-10-19 | game/tests/wildlife_test.gd test_grazing_over_capacity |  |  |
| X18-CAPNUM | Capability modifiers: the bounded model (revised_bounded) for six industries, farming as labour efficiency | docs/directives/2026-10-22_q18_11a_conditional_decision.md | `b01e8f4`; capability_test 72 (22 new: durations and pay at L0/5/10 for seven industries, farm sites, harvest wage 50->52, yield 100 wheat at L0 and L10, determinism), regional 71, settlement 83, farming 217, farm_plots 104, herd 19, world 339, conservation 8, run_tests 3544; economy_sim 30 days seed 1 hook off fingerprint 1c755f53 identical, forced L10 no leaks wheat unchanged | after Q18-11A; after X18-CAPCOMP | Switch the hook on at reconciliation with X18-CAPCOMP; then one SIM-01 run per required seed with a determinism pair. Open: whole-coin rounding of +4% on the 6-coin harvest wage; whether slaughter, clearing and fencing count as farm tasks |

## AUTOMATED TESTS PASSED — PLAYTEST REQUIRED (44)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| ARM-01 | Armorer availability: verify the armorer exists, keeps a schedule, a place, stock, a path, and trades with the player (the owner's playtest: never available) | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `4bfc81b`; world_test::_ctr01_counters |  | Owner playtest at the armoury counter; armour stock follows SHOP-01 |
| B12A-10 | Hardware verification of everything on real devices (umbrella of the device queue) | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 360) |  |  |  |
| B13-12 | B closes only quantity selector | docs/DEVELOPMENT_LEDGER.md (audit inventory row 187) |  |  |  |
| B13-13 | Touch sprint | docs/DEVELOPMENT_LEDGER.md (audit inventory row 188) |  |  |  |
| B14-01 | Harvest or talk: A works the resource, Y / T talks to the villager beside it | docs/DECISIONS.md (owner, Build 13 playtest) | `60a365b`; start_test |  |  |
| B14-06 | Carts in play: pulled storage, parking, cart stops, deliveries, household market runs | docs/DECISIONS.md (owner, Build 14) | `512f1bc`, `f9fb853`, `8ae29c2`; home_test::test_carts_in_play |  |  |
| B14-13 | A controller connected to a phone or tablet hides the touch buttons and uses the pad controls | docs/directives/2026-10-19_android_controller.md | `1458da8`, `c984b4f`; start_test |  |  |
| B7-001 | Starting coins | docs/release/BUILD_7_ISSUES.md (audit inventory row 42) |  |  |  |
| B7-005 | Earning money discoverable; "Trade with" | docs/release/BUILD_7_ISSUES.md (audit inventory row 46) |  |  |  |
| B7-010 | HUD anchoring on Android | docs/release/BUILD_7_ISSUES.md (audit inventory row 51) |  |  |  |
| B7-011 | Tapping trees/ore does nothing | docs/release/BUILD_7_ISSUES.md (audit inventory row 52) |  |  |  |
| B7-012 | Gather mode | docs/release/BUILD_7_ISSUES.md (audit inventory row 53) |  |  |  |
| B7-013 | Brown glyph icons | docs/release/BUILD_7_ISSUES.md (audit inventory row 54) |  |  |  |
| B8-018 | Roof flicker indoors | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 119) |  |  |  |
| CQ-01 | Sword responsiveness and hit detection (buffer, reach, phases, walls) | docs/directives/2026-10-19_sword_combat.md | `3e283b6`; combat_test (41) |  |  |
| CRT-01 | Player courtship and marriage through gifts: attraction, dating, proposal that can be declined if too early | docs/directives/2026-10-19_courtship_friendship.md | game/tests/relations_test.gd; aging_test | after DVW-B1 |  |
| CRT-02 | Friendship: a Befriend option appears after help and gifts; no proposal needed | docs/directives/2026-10-19_courtship_friendship.md | game/tests/relations_test.gd; aging_test | after DVW-B1 |  |
| CRT-04 | Villagers court each other through gifts, dating and proposals by the player's rules, replacing the random pairing chance | docs/directives/2026-10-19_courtship_friendship.md (answers) | game/tests/relations_test.gd; aging_test |  |  |
| CRT-05 | Gift tastes follow obvious things: a villager's trade and current needs; favourite gifts speed courting, traditional gifts always work | docs/directives/2026-10-19_courtship_friendship.md (answers) | game/tests/relations_test.gd; aging_test |  |  |
| CRT-07 | Courtship and marriage between any two humans, same sex included; humans only for now | docs/directives/2026-10-19_courtship_friendship.md (answers) | game/tests/relations_test.gd; aging_test |  |  |
| CRT-08 | Shared experiences start friendships and romances: working together and personal interactions build regard and attraction | owner message 2026-10-19 (chat) | game/tests/relations_test.gd::test_villagers_court, test_shared_hours; aging_test |  |  |
| CRT-09 | Weighting of closeness and conversation: proximity about 1 point, a conversation 0.25, later ones about 0.11, so talk spamming does little | owner message 2026-10-19 (chat) | game/tests/relations_test.gd::test_shared_hours |  |  |
| CRT-10 | Relationship weighting system: closeness over time (the nearby-name prompt), many factors, distinct days known; no button spamming to a quick marriage | owner message 2026-10-19 (chat) | game/tests/relations_test.gd::test_closeness, test_no_rushing |  |  |
| CRT-11 | Single villagers with spare money and goods actively seek company: spend time near the one they court or befriend, and buy gifts | owner message 2026-10-19 (chat) | game/tests/relations_test.gd::test_seek_company |  |  |
| CRT-12 | Proposals can be refused: not wanting to marry, a rival suitor with a better offer, or the suitor's deeds (killing villagers, crimes, theft from their friends or family) | owner message 2026-10-19 (chat) | game/tests/relations_test.gd::test_refusals |  |  |
| CTR-01 | Skilled-trade sales counters: every established skilled business (armorer, smith, carpenter, others as they develop) has a working customer counter | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `4bfc81b`; world_test::_ctr01_counters |  | Device playtest; more counters (carpenter, sage) need counter stations in their buildings (a village-generator change: generator version bump) |
| CTR-02 | At a counter: a prompt, press A, and the business's available shopkeeper walks to the counter to serve | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `4bfc81b`; world_test::_ctr01_counters | after CTR-01 | Device playtest; more counters (carpenter, sage) need counter stations in their buildings (a village-generator change: generator version bump) |
| CTR-03 | Shopkeeper availability: ordinary villagers with schedules; when summoned an available one comes, else the player is told clearly; employees or family may serve; no interrupted emergencies, no duplicate service tasks | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `4bfc81b`; world_test::_ctr01_counters | after CTR-02 | Device playtest; more counters (carpenter, sage) need counter stations in their buildings (a village-generator change: generator version bump) |
| FARM-09 | Farmland placement by drag: two green corners, live price at screen centre, lease or buy, confirm | docs/directives/2026-10-21_build16_master_completion_directive.md | `a36a0ab`; farm_place_test (25 checks; mouse, touch, keys/pad); xvfb screenshots |  |  |
| FR-04 | Pad shortcuts for the Journal and Build menus; complete on-screen controls list | docs/release/BUILD_12_FULL_AUDIT.md | start_test.gd (498 steps); screenshot of the gamepad controls list |  |  |
| PL1-03 | Merchant quantity control | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 140) |  |  |  |
| PL1-05 | current/max inside bars | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 142) |  |  |  |
| Q-04 | Resources & Gathering journal page | docs/DEVELOPMENT_QUEUE.md (audit inventory row 220) |  |  |  |
| SAVE-00 | Save continuity across separate test builds (Android reinstall): user-selected save location or Android-supported export/import; permanent signing key deferred | docs/directives/2026-10-20_two_decisions_three_expansions.md |  | after SAVE-01; after SAVE-02; after SAVE-03; after SAVE-04; after SAVE-05; after SAVE-06; after SAVE-07; after SAVE-08; after SAVE-09 |  |
| SAVE-02 | A stable save identity independent of build numbers (requirement 2) | docs/directives/2026-10-20_two_decisions_three_expansions.md | game/tests/save_transfer_test.gd; start_test::_save_meta_tests |  |  |
| SAVE-03 | Explicit save-schema versioning and forward migration from older supported formats (requirements 3, 4) | docs/directives/2026-10-20_two_decisions_three_expansions.md | game/tests/save_transfer_test.gd; start_test::_save_meta_tests |  |  |
| SAVE-04 | Back up the original before migrating, validate the migrated save before adopting it, preserve the original on failure, never leave a partial conversion, never destroy the only usable save (requirements 5-8, 15) | docs/directives/2026-10-20_two_decisions_three_expansions.md | game/tests/save_transfer_test.gd; start_test::_save_meta_tests |  |  |
| SAVE-05 | A clear way to reconnect to an existing save after an Android reinstall, using supported Android storage (Storage Access Framework or equivalent), no unrestricted filesystem access (requirements 9, 10) | docs/directives/2026-10-20_two_decisions_three_expansions.md | save_transfer_test; start_test |  |  |
| SAVE-06 | The same versioning and migration principles on Windows and Linux (requirement 11) | docs/directives/2026-10-20_two_decisions_three_expansions.md | game/tests/save_transfer_test.gd; start_test::_save_meta_tests |  |  |
| SAVE-07 | Migration tests over persistent world data: terrain changes, resources, NPCs, households, relationships, buildings, inventories, settlements, simulation state (requirement 12) | docs/directives/2026-10-20_two_decisions_three_expansions.md | game/tests/save_transfer_test.gd; start_test::_save_meta_tests |  |  |
| SAVE-08 | Preserve unknown or future data where practical; no claim of backward compatibility unless implemented and tested (requirement 13) | docs/directives/2026-10-20_two_decisions_three_expansions.md | game/tests/save_transfer_test.gd; start_test::_save_meta_tests |  |  |
| SAVE-09 | An independently recoverable backup and documented recovery instructions (requirement 14) | docs/directives/2026-10-20_two_decisions_three_expansions.md | game/tests/save_transfer_test.gd; start_test::_save_meta_tests |  |  |
| WDR-008-C | Comply with World Design Rule 8: Player Knowledge and Wiki | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | device check of wiki navigation on touch and controller |
| WR-01 | Protected wildlife breeding refuges, offspring cohorts and dispersal | docs/directives/2026-10-19_memory_refuges_politics.md Part II | `b15208a`, `7bd1905`; game/tests/refuge_test.gd |  |  |

## BLOCKED (14)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| AR-OWNER | Audit remediation owner checklist: public-release environment, repository visibility, private infrastructure repository | docs/release/AUDIT_REMEDIATION.md (audit inventory row 372) |  |  |  |
| AR-P0-3 | Owner must delete `inventory/registry` by hand | docs/release/AUDIT_REMEDIATION.md (audit inventory row 371) |  |  |  |
| B12A-07 | Art blockers: crop stages, tool swings, sitting poses, chimney, sawhorse (Craftpix crops could supply crop art, B14-10) | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 357) |  |  |  |
| B13-15 | Android signing stability | docs/DEVELOPMENT_LEDGER.md (audit inventory row 190) |  |  |  |
| B7-006 | Hired work pays poorly (mine shift 8 for ore worth ~18; axe needed) | docs/release/BUILD_7_ISSUES.md (audit inventory row 47) |  |  |  |
| B7-016 | Tanners/goods merchants end at 0 coins | docs/release/BUILD_7_ISSUES.md (audit inventory row 57) |  |  |  |
| ENV-RTK | RTK token tool and its hook persistent in the cloud environment | owner request 2026-10-19 (DEVELOPMENT_LEDGER ENV-RTK) |  | owner: environment setup script |  |
| FR-01 | Lizards and spiders as enemies | owner 2026-10-18 ('good enemies'; docs/DECISIONS.md) |  | no lizard or spider pack supplied |  |
| FR-08 | Music and sound | BUILD_7_ISSUES F-3 |  | no audio supplied |  |
| PL1-11 | Google Drive cloud saves (staged) | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 148) |  |  |  |
| Q-08 | Resource depletion and wildlife sustainability | docs/DEVELOPMENT_QUEUE.md (audit inventory row 224) |  | owner decision OD-01 |  |
| Q-10 | Hot Attic Games read-only registry | docs/DEVELOPMENT_QUEUE.md (audit inventory row 226) |  |  |  |
| REC-002 | Over-the-air updates on the Hot Attic Games Mote architecture (fully automatic) | Game Designer ('Bob') spec, owner interview answers: /root/.claude/uploads/754052d8-fb21-5c64-b3f9-641f462e2c23/23b72163-The_Well_corrected_two_documents.zip CLAUDE.md Part A s.A0 and A2 (lines 55-62, 149-151) and MASTER_PROMPT.md line 42; owner message #27 2026-10-17T18:46Z |  | owner input (see notes) | The owner's original answers were a chat upload that is not in the repository; ask the owner to restate them or supply the document when this item is taken up |
| REC-013 | Need-based maintenance (wear) model and the other unanswered job-board questions | owner message #109 2026-10-18T06:00Z; AskUserQuestion round 2026-10-18T06:46Z (wear model, staff fallback, manor hands on the job board, board wage basis) left unanswered; docs/HANDOFF.md and docs/DEVELOPMENT_QUEUE.md 'Waiting on the owner: A need-based maintenance model' |  | owner input (see notes) |  |

## DEFERRED (11)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| B12A-08 | Deferred features from the Build 12 audit (umbrella; each child item tracked on its own) | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 358) |  |  |  |
| DVW-A12 | Keep rules in `core/`, not UI; audit list (:37) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 256) |  |  | Start of Build 17 |
| DVW-B6 | Wildlife wandering in from the overworld | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 278) |  |  | Build 18 |
| F-1 | NPC workshop construction | docs/release/BUILD_7_ISSUES.md (audit inventory row 62) |  |  |  |
| FR-09 | Crime from desperation | owner design intent 2026-10-17, deferred by the owner ('no desperation crime yet') |  |  |  |
| FR-10 | Archery | docs/directives/2026-10-19_sword_combat.md (future, not authorised) |  |  |  |
| HOUSE-11 | Evaluate the alternatives where a ground-floor addition is impossible (OD-14 item 6): a smaller configuration, and whether an upper-floor or attic conversion is practical in the existing building system; no new upper-floor system invented to bypass geometry | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 1 item 6 |  | after HOUSE-10 | future design consideration; not scheduled |
| REC-006 | Castles, dungeons and caves in the world | Game Designer spec Part A s.A1/A2 (bob/CLAUDE.md lines 67, 76, 90), the owner's interview in their own words |  |  |  |
| REC-007 | Several settlements (villages, towns, cities) with their own economies; NPC migration and regional jobs between them | owner message #47 2026-10-17T23:35Z sections 6, 13 (regional job opportunity) and 14; #144 2026-10-18T18:20Z s.10H lists additional villages and towns as future, not authorised now |  |  |  |
| REC-011 | Main storyline after the first story quest (side quests now, story later) | AskUserQuestion answer 2026-10-18T01:39:43Z; owner message #86 01:39Z 'Make the first storyline quest learning fireball from the guy in the Hut to the north' |  |  |  |
| REC-012 | Tiny Ranch pack: on hold by the owner, not cancelled | owner message #30 2026-10-17T19:25Z; AskUserQuestion answer 2026-10-17T19:29:10Z |  |  |  |

## COMPLETE AND VERIFIED (226)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| AR-P0-1 | Fixed `21647e2` | docs/release/AUDIT_REMEDIATION.md (audit inventory row 367) |  |  |  |
| AR-P0-2 | Assessed; remediation needs owner | docs/release/AUDIT_REMEDIATION.md (audit inventory row 370) |  |  |  |
| B12A-01 | 1-11 fixed (B13-01..10); 12 → B13-14 | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 351) |  |  |  |
| B12A-02 | Fixed (WHAT_WAS_DONE:135) | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 352) |  |  |  |
| B12A-03 | Fixed / one withdrawn (addendum :1631) | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 353) |  |  |  |
| B13-01 | Retirement opens no post | docs/DEVELOPMENT_LEDGER.md (audit inventory row 176) |  |  |  |
| B13-02 | Gold ore has no source | docs/DEVELOPMENT_LEDGER.md (audit inventory row 177) |  |  |  |
| B13-03 | Medicine effect text | docs/DEVELOPMENT_LEDGER.md (audit inventory row 178) |  |  |  |
| B13-04 | Attendant hired as carrier | docs/DEVELOPMENT_LEDGER.md (audit inventory row 179) |  |  |  |
| B13-05 | health_jobs_test in CI; always-true checks | docs/DEVELOPMENT_LEDGER.md (audit inventory row 180) |  |  |  |
| B13-06 | Rule 1: no purchase without money | docs/DEVELOPMENT_LEDGER.md (audit inventory row 181) |  |  |  |
| B13-07 | Rule 2: bulk prices per unit | docs/DEVELOPMENT_LEDGER.md (audit inventory row 182) |  |  |  |
| B13-08 | Rule 3: seed from real stock | docs/DEVELOPMENT_LEDGER.md (audit inventory row 183) |  |  |  |
| B13-09 | Rule 4: theft by items/value | docs/DEVELOPMENT_LEDGER.md (audit inventory row 184) |  |  |  |
| B13-10 | Stale text and documents | docs/DEVELOPMENT_LEDGER.md (audit inventory row 185) |  |  |  |
| B13-11 | Livestock production chain | docs/DEVELOPMENT_LEDGER.md (audit inventory row 186) |  |  |  |
| B13-14 | Station occupancy | docs/DEVELOPMENT_LEDGER.md (audit inventory row 189) |  |  |  |
| B14-02 | Villagers' home production: forage, brew poultices, treat their own wounds | docs/DECISIONS.md (owner, Build 14) | `b94dc22`; home_test |  |  |
| B14-03 | House storefronts (player and villager households) | docs/DECISIONS.md (owner, Build 14) | `a9c6db0`, `d01376c`; home_test |  |  |
| B14-04 | Cart parts and handcarts | docs/DECISIONS.md (owner, Build 14) | `d01376c`; home_test |  |  |
| B14-05 | Local-availability pricing | docs/DECISIONS.md (owner, Build 14) | `75093bf`; home_test, business_test |  |  |
| B14-08 | Forest animals (MiniFolks): grazers, predators, fox raids, fights | docs/DECISIONS.md (owner, Build 14) | `2caca5a`, `f9fb853`; wildlife_test |  |  |
| B14-12 | Sprite list with pixel-grid copies for Aseprite (missing and weak sprites) | owner message 2026-10-19 | tools/assets/check_assets.py 0 problems; grid copies inspected |  | Generate the package with tools/assets/sheets.py contact |
| B14R-01 | Record completed 100-day economy simulations (start, seeds, currency, wealth, jobs, trade, resources, food, population, shortages, regressions) | docs/directives/2026-10-19_build14_readiness_requirements_preservation.md s.1 | `a5cf3e8`; game/tests/economy_sim.gd (seeds 1, 2; 100 and 365 days) |  |  |
| B14R-02 | Compare the manor reserve and the caravan money limit (four configurations) and recommend | same directive s.2 | economy_sim.gd --set overrides, seed 1, 100 days | after B7-009; after B7-014 |  |
| B14R-03 | Investigate iron and coal running out by day 10; document sustainable alternatives without changing the resource model | same directive s.3 | economy_sim.gd seeds 1, 2 | after OD-01 |  |
| B14R-04 | Build 14 tester notes | same directive s.4 | n/a (document) |  |  |
| B14R-05 | Identify the Build 14 candidate commit and ask the owner for build approval | same directive s.5 | `7dbae4f`; CI 39313936196; release run 39315420666 | after B14R-01; after B14R-04; after B14R-12 |  |
| B14R-06 | Permanent requirements register, lifecycle, validation, silent-deletion detection, startup and handoff rules | same directive Parts II, V, VI | `386498b`; tests/test_requirements.py; tools/check_requirements.py in tests.yml and pre-push |  |  |
| B14R-07 | Second historical requirements recovery pass and coverage report | same directive Part III | tools/check_requirements.py |  |  |
| B14R-08 | Reconcile the original 16 World Design Rules (restore text if the source is found) | same directive Part IV |  |  |  |
| B14R-09 | Stable Android test-signing procedure documented (credentials, secrets, setup, key preservation, risks, install and update test) | same directive s.28 |  | after B13-15 |  |
| B14R-10 | Separate real-device verification queue (phone, controller, Windows, cross-platform and two-device LAN) | same directive s.29 | `386498b`; tests/test_requirements.py |  |  |
| B14R-11 | Review draft PR #1 for unique content before recommending closure | same directive s.30 | n/a (review) |  | owner: authorise closing PR #1 |
| B14R-12 | Long-run regression: wild animals reach 0 by day 320 and the population falls from 100 to 69 in the 365-day run | Build 14 readiness simulations 2026-10-19 (owner: investigate and correct genuine regressions, s.1) | `d598e65`, `4fe265d`, `b15208a` |  | record the Build 15 365-day results (wildlife holds at 85-92 by day 160-190); close when both seeds pass at day 365 |
| B7-002 | Quest rewards reserved | docs/release/BUILD_7_ISSUES.md (audit inventory row 43) |  |  |  |
| B7-003 | Jewellery/helmets have buyers | docs/release/BUILD_7_ISSUES.md (audit inventory row 44) |  |  |  |
| B7-004 | Harvest-work wheat theft | docs/release/BUILD_7_ISSUES.md (audit inventory row 45) |  |  |  |
| B7-008 | Player can drain buyers to 0, kill all wildlife | docs/release/BUILD_7_ISSUES.md (audit inventory row 49) |  |  | Close with PAR-02 once the suites pass |
| B7-015 | Missed meals while food piles up | docs/release/BUILD_7_ISSUES.md (audit inventory row 56) | `9db091b`; Actions 39523615798, 39529507848; suites |  | Close on the 62b7488 four-seed run if it holds |
| B8-001 | (earlier fix) | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 102) |  |  |  |
| B8-002 | Village pasted over terrain | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 103) |  |  |  |
| B8-003 | Floating/partial trees | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 104) |  |  |  |
| B8-004 | Broken mining area | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 105) |  |  |  |
| B8-005 | Tree collision/transparency | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 106) |  |  |  |
| B8-006 | Harvest animation never stops | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 107) |  |  |  |
| B8-008 | Deposits misidentified | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 109) |  |  |  |
| B8-009 | Collection notices need icons | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 110) |  |  |  |
| B8-010 | Inventory blocked during harvest | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 111) |  |  |  |
| B8-011 | No cancel | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 112) |  |  |  |
| B8-012 | Oversized inventory highlights | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 113) |  |  |  |
| B8-013 | Oversized prompts | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 114) |  |  |  |
| B8-014 | NPC blocks a workstation | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 115) |  |  |  |
| B8-015 | Weapon racks | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 116) |  |  |  |
| B8-016 | Essential trade succession | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 117) |  |  |  |
| B8-017 | Personal chests in public rows | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 118) |  |  |  |
| B8-019 | Unclear HUD | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 120) |  |  |  |
| B8-020 | Death cause | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 121) |  |  |  |
| B8-025 | Player clipped behind tabletops | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 123) |  |  |  |
| B8-026 | Grey boulders not minable | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 124) |  |  |  |
| B8-027 | Sprint | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 125) |  |  |  |
| B8-028 | Sawmill | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 126) |  |  |  |
| B8-029 | Calendar, aging, families, animal life cycles | docs/release/BUILD_8_MASTER_FIXES.md (audit inventory row 127) |  |  |  |
| B8R-001 | Pad cannot reach Wear/Drop | docs/release/BUILD_8_ISSUES.md (audit inventory row 74) |  |  |  |
| B8R-002 | Trapped inside a door | docs/release/BUILD_8_ISSUES.md (audit inventory row 75) |  |  |  |
| B8R-003 | Trapped between trees | docs/release/BUILD_8_ISSUES.md (audit inventory row 76) |  |  |  |
| B8R-004 | Sage's hut door off by one | docs/release/BUILD_8_ISSUES.md (audit inventory row 77) |  |  |  |
| B8R-007 | Overlapping house edges | docs/release/BUILD_8_ISSUES.md (audit inventory row 80) |  |  |  |
| B8R-008 | Family name signs at houses | docs/release/BUILD_8_ISSUES.md (audit inventory row 81) |  |  |  |
| B8R-009 | Trading skill never gains XP | docs/release/BUILD_8_ISSUES.md (audit inventory row 82) |  |  |  |
| B8R-010 | Pickpocketing children allowed | docs/release/BUILD_8_ISSUES.md (audit inventory row 83) | code: world.gd pickpocket refuses role child |  |  |
| B8R-011 | Map border; large world | docs/release/BUILD_8_ISSUES.md (audit inventory row 84) |  |  |  |
| B8R-012 | Hit feedback | docs/release/BUILD_8_ISSUES.md (audit inventory row 85) |  |  |  |
| B8R-013 | Cow attack shows no damage | docs/release/BUILD_8_ISSUES.md (audit inventory row 86) |  |  |  |
| B8R-014 | Pad cycles all buttons | docs/release/BUILD_8_ISSUES.md (audit inventory row 87) |  |  |  |
| B8R-015 | Flowers pickable/walkable | docs/release/BUILD_8_ISSUES.md (audit inventory row 88) |  |  |  |
| B8R-016 | Berry bushes pickable | docs/release/BUILD_8_ISSUES.md (audit inventory row 89) |  |  |  |
| B8R-017 | Field half-plants at edges | docs/release/BUILD_8_ISSUES.md (audit inventory row 90) |  |  |  |
| B8R-018 | Villagers swing tools idly | docs/release/BUILD_8_ISSUES.md (audit inventory row 91) |  |  |  |
| B8R-019 | Building collision, interior nav, roof flicker | docs/release/BUILD_8_ISSUES.md (audit inventory row 92) |  |  |  |
| B8R-020 | Gathering banners fill phone screen | docs/release/BUILD_8_ISSUES.md (audit inventory row 93) |  |  |  |
| CTR-04 | Permanent counters are not market stalls: no stall commission on counters without an approved rule | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `f56e9bb`; world_test::_ctr04_counter_terms | after CTR-01 |  |
| DVW-A1 | Stale heir comment (:26) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 245) |  |  |  |
| DVW-A11 | Threats never scale to player (:36) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 255) |  |  |  |
| DVW-A2 | Rotate several dated save backups, not one `.bak` (:27) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 246) | run_tests.gd test_dated_backups; start_test.gd save safety case 4b |  |  |
| DVW-A4 | Faucet and drain ledger for coins and each item (:29) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 248) | economy_sim.gd 3-day seed 1 output |  |  |
| DVW-A5 | Exploit-player test (arbitrage, round trips, cornering, flooding) (:30) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 249) | `1dd89fa`; exploit_test (36 checks); 30 suites; gate identical |  |  |
| DVW-A6 | Coins and goods conserved across save/load and tier transitions (:31) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 250) | game/tests/conservation_test.gd (8 checks); economy_sim 10-day seed 1 fingerprint eeabb2a8 unchanged after the census refactor |  |  |
| DVW-A7 | Over-production from raising skills by use (:32) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 251) | world_test.gd _player_gain |  |  |
| DVW-A8 | Audit player-only perks vs same rules (:33) | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 252) |  |  |  |
| EQ-01 | Human civilization sustains itself without the player | docs/directives/2026-10-19_build16_world_equilibrium.md | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) | after B14R-12 |  |
| EQ-02 | Nature sustains itself: reproduction, aging, predation, competition, dispersal, habitat, local extinction, recolonization, recovery | docs/directives/2026-10-19_build16_world_equilibrium.md | `b15208a`; Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) | after WR-01 | Every bullet mapped to tests (wildlife, refuge, aging, ecology_test); multi-generation survival from the four-seed 365-day runs |
| EQ-03 | Humans and nature affect each other through real NPC decisions | docs/directives/2026-10-19_build16_world_equilibrium.md | `152ffa2`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| EQ-04 | A functioning society survives individual losses (succession of trades, households, leadership, businesses) | docs/directives/2026-10-19_build16_world_equilibrium.md | `1e88118`, `89ee852`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| EQ-06 | Build 16 acceptance simulations: multi-seed, player inactive, 100 and 365 days and generations, plus player-intervention scenarios | docs/directives/2026-10-19_build16_world_equilibrium.md | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves); EQ-06 local scenarios 100 days (LONG_RUN_SIMULATION.md) | after EQ-01; after EQ-02; after EQ-03; after EQ-04; after EQ-05 |  |
| EQ-07 | Investigate and correct the 365-day failures: population 100 to 69, wildlife to zero, no houses built | docs/directives/2026-10-19_build16_world_equilibrium.md | long-sims run 39385942656; local 365-day runs seeds 1 and 2 (fingerprint f1a34dd0 matches); branch staging/my-medieval-life | after B14R-12 | owner answer to OD-16; then 365-day Actions runs on both seeds |
| EQ-08 | Births do not require a free bed; the crowding a birth causes is what drives a household to split and move | owner message 2026-10-19 (chat) | `af60f94`; game/tests/aging_test.gd::test_partners_and_births, test_couples_found_households; run_tests::test_households_split |  |  |
| EQ-09 | Local stone deposits run out (day 160-190 in the Build 15 runs); verify that the owner-approved caravan stone (20 a visit once 10 or less remain) keeps house building supplied | Build 15 simulation runs 2026-10-19 (fix2: stone 0 by day 60) and 2026-10-20 (fix9: stone 0 by day 160-190, docs/release/LONG_RUN_SIMULATION.md) | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | confirm with seed 2's day-365 figures, then close |
| EQ-10 | Economy simulation: axe and hammer ledger residuals of 1-3 from day 120 in 365-day runs | WR-01 agent report 2026-10-19 (also in the unchanged baseline) | long-sims run 39368663150; world_test.gd hammer conservation |  |  |
| EQ-16 | World equilibrium: an untouched world stays viable across generations; the player is the disruptive variable | docs/directives/2026-10-19_build16_world_equilibrium.md | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) | after EQ-01; after EQ-02; after EQ-03; after EQ-04; after EQ-05; after EQ-06; after EQ-07 | Build 15: diagnose and fix EQ-07; Build 16: EQ-06 acceptance |
| EQ-17 | Long simulations: a household that loses its house leaves an empty home id; births and members then raise script errors | agent finding 2026-10-20: SCRIPT ERROR counts in out/eq logs (fix2 to fix13), building_door on a missing building | long-sims run 39368663150; housing_test.gd |  |  |
| EQ-18 | Tool recovery and essential trades over a year: job seekers can buy the trade tool where tools are sold (seek_work looked among timber sellers, so nobody without an axe became a woodcutter and the trade died out), and an essential trade left for other work opens its succession post (seed 2 had no smith from day 240) | Build 15 release-candidate run (Actions 39396414426 on af60f94), 2026-10-20; OVN-01 section 3 Build 15 scope 'Economic recovery from missing work tools' | housing_test.gd test_axe_bought_to_take_up_woodcutting, test_left_trade_post_opens |  | re-run after OD-16 is implemented |
| EQ-19 | The manor supports the essential trades from its treasury (OD-16 b): it keeps the smithy and the woodlands working by buying iron and tools for the village's workers, or lending to the smith against future output | owner answer to OD-16, 2026-10-20 | game/tests/od16_test.gd |  | future improvement: earmark advances for materials, or the manor buys the coal for an order (Build 16/17); device-free, no blocker |
| EQ-20 | Bandit coins recirculate (OD-16 a): bandits spend their hoards at the market, and guards recover loot to the treasury | owner answer to OD-16, 2026-10-20 | game/tests/od16_test.gd |  |  |
| EQ-21 | The caravan buys more of the village's surplus (OD-16 c): meat, hides and other over-produced goods | owner answer to OD-16, 2026-10-20 | game/tests/od16_test.gd |  |  |
| FARM-01 | Farmland plots: any household (player or villager) leases a small plot through the existing lease framework at 2 coins, registered so no one else can claim it | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `3fd88ae`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | Implement with the owner's answers OD-27 (Q8-Q13, 2026-10-21); worker branch per the master directive |
| FARM-02 | Developing farmland: clear trees and obstructions, then build a fence and gate from logs and stone through the normal construction system | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `3fd88ae`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | Implement with the owner's answers OD-27 (Q8-Q13, 2026-10-21); worker branch per the master directive |
| FARM-03 | Ploughing and sowing a family plot with real seed by the established farming mechanics (one model for player and villagers) | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `3fd88ae`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| FARM-04 | Household participation: family members work the plot by age, ability, skill and time; no farmer occupation required | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `3fd88ae`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| FARM-05 | Whether a household takes up a plot: from its circumstances, needs, skills, resources and opportunities (no quota, no forced farming) | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `3fd88ae`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| FARM-07 | The farmland lease's recurring charge: 2 coins under the existing weekly lease framework (first week at once), ambiguity reported to the owner | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `3fd88ae`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | Implement with the owner's answers OD-27 (Q8-Q13, 2026-10-21); worker branch per the master directive |
| FARM-08A | No script error when a homeless household's couple or founder looks for a building site | Actions run 39580481791 (FARM-08 yield matrix), seed 2 at shared_wheat_yield 2.5: 37 SCRIPT ERRORs at World.building_door from Construction._found_couple | `49c530a`; aging_test; Actions 39595792732 |  |  |
| FARM-08C | Wheat price floor: record as an economic finding | docs/directives/2026-10-21_farm08_cattle_investigation.md | `463861a` |  |  |
| FR-05 | Title window opens scrolled into the controls list | docs/release/BUILD_13_PACKET.md | `ec3bd0e`; start_test |  |  |
| FR-06 | Wiki pages missing: magic, the employer star, journal and map, death causes, caravan, bandits | docs/release/BUILD_12_FULL_AUDIT.md | wiki_test.gd; run_tests.gd 3535 checks |  |  |
| FR-07 | Economy and household simulations in CI (short variant) | Build 14 audit | tests.yml 'Short economy simulation (FR-07)', run 39368652711 |  |  |
| FSE-01 | Current-system audit: agriculture, consumption, hunting, husbandry, land and commerce | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `ee589c7` |  |  |
| FSE-02 | Food sustainability calculation: food and productive land per villager, household and village | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `ee589c7` |  |  |
| FSE-03 | Gap analysis: agriculture, husbandry, hunting, rental, commerce and AI behavior | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `ee589c7` |  |  |
| FSE-04 | Cross-system dependency map for the food and living economy | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `ee589c7` |  |  |
| FSE-05 | Implementation roadmap: Build 16 foundations vs the living-economy build | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `ee589c7` |  |  |
| FSE-06 | Testing strategy for the food and living economy | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `ee589c7` |  |  |
| FSE-07 | Unresolved owner questions arising from the food-security directive | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `ee589c7` |  |  |
| FSE-08 | The directive's 25 deterministic tests (section 17) | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `268895c`; docs/design/FSE08_TEST_MAP.md; farm_plots_test, stalls_test |  | Mapped (docs/design/FSE08_TEST_MAP.md): 13 covered, 4 in the Build 16 push (2, 6, 7, 18), 8 in the Living Economy build. Close when the push's farm and stall tests land |
| FSE-09 | Build 16 food-security defects and foundations (classes B and C) | docs/directives/2026-10-20_food_security_goal_driven_economy.md | `268895c` |  | Every class B defect is closed (FSE-B05..B12); class C foundations done except FSE-14 (Worker A, land planning). Close with FSE-14 |
| FSE-14 | Dynamic land planning: design and safe foundations (land rental for plots and pens) | docs/directives/2026-10-20_agricultural_findings_followup.md | `268895c`; farm_plots_test (foundations) |  |  |
| FSE-15 | Recalculate the land requirement after the seed, season and parity corrections | docs/directives/2026-10-20_agricultural_findings_followup.md | `27a1be5`; farm_plots_test | after FSE-11; after FSE-12; after FSE-13 |  |
| FSE-16 | Seed-2 starvation: root cause of each of the 11 deaths | docs/directives/2026-10-20_agricultural_findings_followup.md | `9db091b`; Actions 39523615798, 39529507848; suites | after B7-015 | Close on the 62b7488 four-seed run if it holds |
| FSE-17 | Manor relief checks and draws on every food store (amends the B3 relief rule) | owner message 2026-10-20 ('Relief should check all possible food stores') and the owner's answers to the agent's two clarifying questions the same day | Actions 39523615798, 39529507848; suites | after FSE-16 | Close on the 62b7488 four-seed run if it holds |
| FSE-18 | The family chest: a household's food is kept in its pantry, communal; traders keep sellable stock and stock the chest first | owner message 2026-10-20 ('cant we just keep the family food in a second chest? and have it be commuunal?') and the owner's answers to the agent's two questions the same day | Actions 39523615798, 39529507848; suites | after FSE-17 | Close on the 62b7488 four-seed run if it holds |
| FSE-B05 | A pen whose keeper is gone is let again (its animals starved untended) | docs/design/FOOD_SECURITY_AUDIT.md section 6 (class B) | `a946ba1`; world_test |  |  |
| FSE-B06 | Bandits' poaching and the clan's camp meals feed them only from real food | docs/design/FOOD_SECURITY_AUDIT.md section 6 (class B) | `6ab7d50`; Actions 39523615798, 39529507848; suites | after WDR-016-C | Close on the 62b7488 four-seed run if it holds |
| FSE-B07 | Villagers can sell flowers to the Apothecary | docs/design/FOOD_SECURITY_AUDIT.md section 6 (class B) | `a946ba1`; world_test |  |  |
| FSE-B08 | A hunt cut short releases its claim on the animal | docs/design/FOOD_SECURITY_AUDIT.md section 6 (class B) | `a946ba1`; world_test |  |  |
| FSE-B09 | Hunter job openings count only game hunters may take | docs/design/FOOD_SECURITY_AUDIT.md section 6 (class B) | `a946ba1`; world_test |  |  |
| FSE-B10 | The player's kills enter the wildlife ledger | docs/design/FOOD_SECURITY_AUDIT.md section 6 (class B) | `a946ba1`; world_test |  |  |
| FSE-B11 | The home hearth gives the player and villagers the same recipes | docs/design/FOOD_SECURITY_AUDIT.md section 6 (class B) | `6ab7d50`; Actions 39523615798, 39529507848; suites |  | Close on the 62b7488 four-seed run if it holds |
| FSE-B12 | Hunting experience by one rule for the player and villagers | docs/design/FOOD_SECURITY_AUDIT.md section 6 (class B) | `6ab7d50`; Actions 39523615798, 39529507848; suites |  | Close on the 62b7488 four-seed run if it holds |
| HOUSE-01 | Housing need arises from circumstances: crowding, a couple living apart, an adult leaving home, no permanent residence, a lost home; not every extra person needs a house | docs/directives/2026-10-20_housing_succession_adoption.md Part 1.2 | `af60f94`; game/tests/housing_test.gd |  |  |
| HOUSE-02 | The household's responsible adult decides and builds; no sex or strength restriction (a mother can initiate and complete construction; same-sex couples found homes too) | docs/directives/2026-10-20_housing_succession_adoption.md Part 1.3 | `af60f94`; game/tests/housing_test.gd |  |  |
| HOUSE-03 | A persistent housing goal begins before the household can afford it: the plan (existing recipe, materials owned, to buy, cost, own labour, help) is kept and worked toward | docs/directives/2026-10-20_housing_succession_adoption.md Part 1.4 | `af60f94`; game/tests/housing_test.gd |  |  |
| HOUSE-04 | Money and materials come from real systems: work, saving, buying, materials the household owns, gathering, producing, trading, help from kin and neighbours; never free supplies | docs/directives/2026-10-20_housing_succession_adoption.md Part 1.5 | `af60f94`; housing_test.gd test_family_helps_builder, test_builder_makes_timber, test_caravan_keeps_needed_tools |  | gathering and trading by households: decide scope after the fix10 runs; may move to Build 16 |
| HOUSE-05 | Construction is real work over time: it consumes materials, progresses as they arrive, keeps unfinished progress, yields to survival needs and resumes after a shortage | docs/directives/2026-10-20_housing_succession_adoption.md Part 1.6 | `af60f94`; game/tests/housing_test.gd |  |  |
| HOUSE-06 | No construction deadlock: a household reconsiders its approach with what exists (save, buy elsewhere, another existing recipe such as added quarters) without new building types or bypassed costs | docs/directives/2026-10-20_housing_succession_adoption.md Part 1.7 | housing_test.gd test_sleeping_loft, test_housing_options_weighed, test_small_room | after HOUSE-08; after HOUSE-09 |  |
| HOUSE-07 | EQ-07 investigation and tests: trace need to completion (the directive's ten questions), name the root causes, tests for the seven housing scenarios, re-run the simulations labelled old and new code | docs/directives/2026-10-20_housing_succession_adoption.md Part 2, Part 6 | housing_test.gd; long-run records |  |  |
| HOUSE-08 | Bed sharing in the crowding rule (OD-13): couples share a bed and young children share beds within an age limit; crowding counts sleeping places, not people | docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md (OD-13) | `af60f94`; game/tests/housing_test.gd test_bed_sharing; aging_test; run_tests test_households_split |  |  |
| HOUSE-09 | Original village houses can take living-quarters expansions (OD-13): the ground under a generated house becomes its parcel so modules attach; the quarters still cost real materials, labour and time | docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md (OD-13) | housing_test.gd test_quarters_on_an_original_house, test_small_room | after OD-14 |  |
| HOUSE-10 | Smaller attached rooms for existing houses (OD-14): a bedroom-sized addition that fits the current tile grid, built through the existing construction and module systems on legitimate adjoining ground, with real materials, labour and time | docs/directives/2026-10-20_od14_housing_expansion_procedural_villages.md Phase 1 | game/tests/housing_test.gd test_small_room (with test_housing_options_weighed, test_sleeping_loft); tests/test_village.py | after HOUSE-09 |  |
| INFRA-01 | Long-run test reliability: preserve long-running simulation progress or prevent session-idle termination, without altering simulation results | docs/directives/2026-10-20_sleeping_loft_and_long_run_reliability.md | `9ec6b40`; INFRA-02 validation |  |  |
| INFRA-02 | Manual GitHub Actions workflow for long-duration simulations: seed and duration inputs, isolated output, artifacts, commit/seed/runtime/fingerprint/ledger recorded, clear failure, no builds or releases, no automatic year-long runs, bounded concurrency; validated against a local 10-day run first | docs/directives/2026-10-20_loft_and_actions_approval.md section 2 | `9ec6b40`, `de76782`; .github/workflows/long-sims.yml run 39365379504 |  |  |
| K-1 | 5 coins vs land 60+ | docs/release/BUILD_7_ISSUES.md (audit inventory row 59) |  |  |  |
| K-2 | Tavern child and sage on pallets; no lying frame | docs/release/BUILD_7_ISSUES.md (audit inventory row 60) |  |  |  |
| MEM-01 | Persistent project memory: PROJECT_MEMORY.md index, CURRENT_DEVELOPMENT_STATE.md handoff, mandatory session-start instructions, checkpoints, safeguards and a fresh-session recovery test | docs/directives/2026-10-20_project_memory_hardening.md | `3814618`, `c2ed962`; tests/test_requirements.py RoadmapAndMemoryTest |  |  |
| MEM-02 | Permanent project memory: index covers every listed source (incl. the 231-entry reconciliation), 8-step session start, baseline of the 231 open and 142 closed entries, 9-question recovery test | docs/directives/2026-10-20_permanent_project_memory_hardening.md | `d672353`, `6a56b9e`, `9a01e88`; tests/test_requirements.py RoadmapAndMemoryTest | after MEM-01 |  |
| OPS-01 | Resolve PR #1 as routine maintenance: inspect, compare with staging, preserve any unique work on a remote branch, then close with a comment | docs/directives/2026-10-20_two_decisions_three_expansions.md | git merge-base --is-ancestor; git rev-list staging..head = 0; git cherry = 0 |  |  |
| OWN-01 | Asset integration pipeline (skill, policy, registry, scaling standard, tools) | docs/DECISIONS.md (audit inventory row 317) |  |  |  |
| OWN-03 | Calendar (8-day year), human aging, explicit family links, heirs from family graph, animal life stages | docs/DECISIONS.md (audit inventory row 319) |  |  |  |
| OWN-04 | Village generator v6, fixed village, save v13 refusal | docs/DECISIONS.md (audit inventory row 320) |  |  |  |
| OWN-05 | Overworld (B8-011) | docs/DECISIONS.md (audit inventory row 321) |  |  |  |
| OWN-06 | Living Forest tree lifecycle | docs/DECISIONS.md (audit inventory row 322) |  |  |  |
| OWN-07 | Flowers/berries walkable and gatherable | docs/DECISIONS.md (audit inventory row 323) |  |  |  |
| OWN-10 | Queue + parallel agents; resource manifest, Gather mode, journal page | docs/DECISIONS.md (audit inventory row 326) |  |  |  |
| OWN-11 | Continuous development; reeve employment | docs/DECISIONS.md (audit inventory row 327) |  |  |  |
| OWN-13 | Windows exe icon | docs/DECISIONS.md (audit inventory row 329) |  |  |  |
| OWN-14 | Interiors roof fade, sleepers reachable | docs/DECISIONS.md (audit inventory row 330) |  |  |  |
| OWN-15 | Property phases 1-2, construction, helpers, households split | docs/DECISIONS.md (audit inventory row 331) |  |  |  |
| OWN-16 | GitHub workflow; work preservation; off-machine copies; backup branch | docs/DECISIONS.md (audit inventory row 332) |  |  |  |
| OWN-18 | Inventory tabs, six gear slots, tavern food theft, stealing, pickpocketing, buttons sized, camera dead zone | docs/DECISIONS.md (audit inventory row 334) |  |  |  |
| OWN-20 | Trees walk-under; heir kit; journal book | docs/DECISIONS.md (audit inventory row 336) |  |  |  |
| OWN-23 | UI recolour brown; flat UI pack buttons; Kenney prompts | docs/DECISIONS.md (audit inventory row 339) |  |  |  |
| OWN-25 | Attack mode; blood splats; readable phone text | docs/DECISIONS.md (audit inventory row 341) |  |  |  |
| OWN-26 | Animal breeding, hunger, livestock as meat, wild animals hunted | docs/DECISIONS.md (audit inventory row 342) |  |  |  |
| OWN-27 | Manor government B3 | docs/DECISIONS.md (audit inventory row 343) |  |  |  |
| PAR-00 | The player is a villager: one set of world rules for player and villagers | docs/directives/2026-10-20_od18_player_villager_parity.md | suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| PAR-01 | OD-18.1: villagers develop skills exactly as the player does | docs/directives/2026-10-20_od18_player_villager_parity.md | parity_test.gd |  |  |
| PAR-01A | Starting experience only at world creation, from a plausible occupational history; one-time migration for older saves | docs/directives/2026-10-20_par_final_consolidated_directive.md | parity_test.gd |  |  |
| PAR-01B | Career changes neither grant nor reset experience | docs/directives/2026-10-20_par_final_consolidated_directive.md | parity_test.gd |  |  |
| PAR-01C | Experience comes from activities, whatever the occupation | docs/directives/2026-10-20_par_final_consolidated_directive.md | parity_test.gd |  |  |
| PAR-02 | OD-18.2: one trade eligibility rule (the trader's coin reserve) for player and villagers | docs/directives/2026-10-20_od18_player_villager_parity.md | world_test.gd _par02_reserve; start_test.gd |  | Owner answers OD-19; set buyer_reserve accordingly |
| PAR-02A | OD-19: a dynamic, necessity-based reserve in place of fixed coin floors | docs/directives/2026-10-20_od19_dynamic_reserves.md | reserve_test.gd; world_test.gd _par02_reserve |  |  |
| PAR-03 | OD-18.3: villagers recover health by the player's rest model | docs/directives/2026-10-20_od18_player_villager_parity.md | world_test.gd _par03_rest |  |  |
| PAR-04 | OD-18.4: villagers can craft every recipe the player can, under the same requirements | docs/directives/2026-10-20_od18_player_villager_parity.md | parity_test.gd test_eleven_recipes | after PAR-01 |  |
| PAR-05 | OD-18.5: crime awareness by legitimate means only, the same for assault and theft | docs/directives/2026-10-20_od18_player_villager_parity.md | world_test.gd _par05_awareness |  | Replace the cry with reports by witnesses and the victim; tests |
| PERF-02 | Profile a representative 10-day run by subsystem (npc_brain decisions, _run_plan, movement and pathfinding, fauna, hourly and daily world processing, harness sampling) before any optimization | docs/directives/2026-10-20_simulation_performance_audit.md; docs/directives/2026-10-20_build15_followup_performance_clarification.md | economy_sim.gd --profile; 10-day fingerprint eeabb2a8 with profiling on | after PERF-01 |  |
| PERF-03 | Determinism gate for optimizations: baseline fingerprints, then identical fingerprints and ledgers at 10 and 30 days on the same seeds after each change | docs/directives/2026-10-20_simulation_performance_audit.md; docs/directives/2026-10-20_build15_followup_performance_clarification.md | tools/sim_gate.py (PASS for both PERF-04 changes) | after PERF-02 |  |
| PERF-04 | Small, measured, low-risk optimizations (indexes or caches for NPC scans, fauna membership sets, hot-loop config reads) that pass the determinism gate; no bigger STEP, no disabled systems, no shortcuts | docs/directives/2026-10-20_simulation_performance_audit.md; docs/directives/2026-10-20_build15_followup_performance_clarification.md | tools/sim_gate.py PASS after each change; economy_sim --profile before and after | after PERF-03 |  |
| PERF-05 | Parallel seeds: two seeds as separate processes with isolated save, temp and output paths, against the same two run sequentially | docs/directives/2026-10-20_simulation_performance_audit.md; docs/directives/2026-10-20_build15_followup_performance_clarification.md | tools/sim_gate.py --write (parallel) then --sequential (PASS) | after PERF-02 |  |
| PERF-06 | Long-simulation checkpoint and resume: evaluate design and determinism risks before any implementation (owner: do not implement until evaluated) | docs/directives/2026-10-20_simulation_performance_audit.md; docs/directives/2026-10-20_build15_followup_performance_clarification.md |  |  | implementation only if the owner asks after reading the evaluation |
| PL1-01 | Settings > Controls exit freezes game | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 138) |  |  |  |
| PL1-02 | One tabbed Settings with Back | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 139) |  |  |  |
| PL1-04 | Health recovery + Apothecary | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 141) |  |  |  |
| PL1-06 | Every stone minable, size-based | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 143) |  |  |  |
| PL1-08 | Consumable effects shown everywhere | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 145) |  |  |  |
| PL1-09 | Gold star over employer | docs/release/BUILD_11_PUNCH_LIST_1.md (audit inventory row 146) |  |  |  |
| PL2-001 | Forge occupancy wrongly blocks | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 156) |  |  |  |
| PL2-002 | Chests, locks, lockpicking | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 157) |  |  |  |
| PL2-003 | Dialogue text | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 158) |  |  |  |
| PL2-004 | Animal loot, leather | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 159) |  |  |  |
| PL2-005 | Longer skill trees | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 160) |  |  |  |
| PL2-006 | Harvest everywhere | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 161) |  |  |  |
| PL2-007 | Fields grow, ripen, regrow | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 162) |  |  |  |
| PL2-009 | In-game wiki | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 164) |  |  |  |
| PL2-011 | No interactions through walls | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 166) |  |  |  |
| PL2-012 | Storage UI quantities, focus | docs/release/BUILD_11_PUNCH_LIST_2.md (audit inventory row 167) |  |  |  |
| Q-03 | Resource manifest and registry (INT-067) | docs/DEVELOPMENT_QUEUE.md (audit inventory row 219) |  |  |  |
| Q-05 | Reeve employment, real jobs, NPCs same rules (INT-066) | docs/DEVELOPMENT_QUEUE.md (audit inventory row 221) |  |  |  |
| Q-06 | Long-duration simulations 10/30/100/365 | docs/DEVELOPMENT_QUEUE.md (audit inventory row 222) |  |  |  |
| REC-001 | Adoption and orphan guardianship (NPCs and the player) | owner message #46 2026-10-17T22:58Z (MASTER DEVELOPMENT PROMPT, section 10 'ADOPTION AND ORPHAN CARE', scenarios 11 and 16); reaffirmed #47 2026-10-17T23:35Z section 17.4 ('Orphaned children should have possible adoption or guardianship paths. Family members may receive priority, followed by suitable willing households') and 17.5 ('The player must be eligible for marriage, children, household formation, and adoption under the same basic systems as NPCs') | `04a8eb9`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| REC-004 | Merge the Game Designer ('Bob') corrected spec into the project docs and record its owner answers | owner message #27 2026-10-17T18:46Z; agent merge proposal (transcript -home-user-My-Medieval-Life/754052d8...jsonl, 'Merge proposal for your approval'); owner #28 18:48Z then built from 'the Game Designer documents we have just reviewed and reconciled' |  |  | the open owner calls in SPEC_RECONCILIATION.md section 4 stay with the owner |
| REC-005 | Working title 'The Well'; repository, package and identifiers stay My Medieval Life | AskUserQuestion answer 2026-10-17T18:46:03Z; owner message #27 2026-10-17T18:46Z | observed in project.godot and the export package name |  |  |
| REC-017 | Bring stale project documents up to date (handoff, plan, game design, build decisions, CLAUDE.md release list, resources.json exception) | owner messages #111 2026-10-18T13:38Z item 10 and #116 14:03Z s.6; Build 14 audit section C 'Also found' and F (no id) | tools/check_resources.py 0 problems; GitHub release list |  |  |
| SAVE-01 | Inspect and document the current save architecture before modifying it (requirement 1) | docs/directives/2026-10-20_two_decisions_three_expansions.md | n/a (document) |  |  |
| SEED-01 | Seed and propagation audit: crops, fruit trees, berry bushes, flowers (acquire, store, plant, grow, harvest) | docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md | `38b987e` |  |  |
| STALL-01 | Stalls are built by anyone on cleared land through the construction system with real materials, under the realm's 5% sales lease | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `afef91d`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | Implement with the owner's answers OD-27 (Q8-Q13, 2026-10-21); worker branch per the master directive |
| STALL-02 | A stall's own inventory: goods are moved into it for sale and are in one place only | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `afef91d`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| STALL-03 | OPEN STALL: the stall sells unattended to real buyers through the existing market; auto-closes when sold out, with a notification | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `afef91d`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | Implement with the owner's answers OD-27 (Q8-Q13, 2026-10-21); worker branch per the master directive |
| STALL-04 | CLOSE STALL: sales stop, the unsold goods stay in the stall, the session's sales are totalled | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `afef91d`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  |  |
| STALL-05 | The realm's 5% commission on each session's actual sales, through real coins (100 sold: 5 to the treasury, 95 to the seller) | docs/directives/2026-10-20_od22_od23_od24_farms_leases_stalls.md | `afef91d`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | Implement with the owner's answers OD-27 (Q8-Q13, 2026-10-21); worker branch per the master directive |
| SYNC-17 | Synchronize Expansions 18 and 19 one way with the Build 17 baseline cd7439c | docs/directives/2026-10-21_sync_expansions_with_build17.md | `283ec55`, `e91d903`; see PROS-18 and PROS-19 | after PROS-18; after PROS-19 |  |
| TIME-01 | Time-system audit: every timed system's duration, unit, meaning, calendar equivalent, calibration, balance effect and parity | docs/directives/2026-10-20_od21_time_model.md | `b388bfb` |  |  |
| TIME-02 | Explicit time units in configuration and code; one shared conversion layer (no third clock) | docs/directives/2026-10-20_od21_time_model.md | `99e7448`; suites; Actions 39523615798, 39529507848 | after TIME-01 | Update the older docs' key names (DECISIONS, BUILD_DECISIONS, audits) where they cite renamed keys |
| TIME-04 | Player starvation damage follows the villagers' rule (time-audit defect D4) | docs/design/TIME_MODEL.md section 3 (D4), under docs/directives/2026-10-20_food_security_goal_driven_economy.md section 1 (same rules for food consumption) | `a946ba1`; world_test |  |  |
| TREAS-01 | The manor treasury as the village reserve: fees in, real purchases out, relief from owned stock | docs/directives/2026-10-21_build16_master_completion_directive.md | `1de1bcc`; suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | Procurement and relief part done (e992044: relief from the granary's own stock, bought relief through the granary); commission to the treasury in wip/b16-stalls, leases and purchases in wip/b16-farms (both via existing accounting); then the four-seed runs |
| WDR-005-C | Comply with World Design Rule 5: Living World Independence | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), starvation 0/0/0/0, no famine, food days 286/282/346/286, houses built 13/9/7/12, cattle herds kept (115-120 calves) |  | Idle-player construction and housing (B7-017, B14R-12) |
| WDR-006-C | Comply with World Design Rule 6: Maintain the Existing Interlocking Systems Manifest | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) | check_interactions (CI) |  |  |
| WDR-007-C | Comply with World Design Rule 7: Automated Compliance | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) | `fdc30a5`; tests/test_check_materials.py |  |  |

## SUPERSEDED (21)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| AR-P1-1 | Prepared; owner must create key | docs/release/AUDIT_REMEDIATION.md (audit inventory row 369) |  | superseded by B13-15 |  |
| B12A-04 | Not recorded as done | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 354) |  | superseded by FR-04 |  |
| B12A-06 | Sword page added by CQ-01 (`3e283b6`); others not recorded | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 356) |  | superseded by FR-06 |  |
| B12A-09 | RTK token tool persistence in the cloud environment (owner action) | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 359) |  | superseded by ENV-RTK |  |
| B12A-11 | "Not investigated further" | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 361) |  | superseded by FR-05 |  |
| B7-017 | No building in a year (no births) | docs/release/BUILD_7_ISSUES.md (audit inventory row 58) |  | superseded by EQ-07 |  |
| B8R-005 | Hunger icon looked like coin bag | docs/release/BUILD_8_ISSUES.md (audit inventory row 78) |  | superseded by B8-019 |  |
| B8R-006 | Where to cook raw meat | docs/release/BUILD_8_ISSUES.md (audit inventory row 79) |  | superseded by FR-03 |  |
| F-2 | Births, children, aging, family growth | docs/release/BUILD_7_ISSUES.md (audit inventory row 63) |  | superseded by B8-029 |  |
| F-3 | Music and sound | docs/release/BUILD_7_ISSUES.md (audit inventory row 64) |  | superseded by FR-08 |  |
| FSE-11 | Village sowing consumes seed (seed consumption correction) | docs/directives/2026-10-20_agricultural_findings_followup.md |  | after FSE-16; superseded by FARM-06 |  |
| K-3 | Every provisional number awaits the owner's balance review | docs/release/BUILD_7_ISSUES.md (audit inventory row 61) |  | superseded by OD-02 |  |
| OWN-12 | Build 7 corrections; "Not approved yet (investigate first)": mining wage 15+, 15-coin reserve on player sales, deposit regeneration, wildlife respawn, broad changes | docs/DECISIONS.md (audit inventory row 328) |  | superseded by OD-01 |  |
| OWN-17 | Provisional numbers await a separate balance review | docs/DECISIONS.md (audit inventory row 333) |  | superseded by OD-02 |  |
| OWN-21 | Every build published under GitHub Releases | docs/DECISIONS.md (audit inventory row 337) |  | superseded by OWN-09 |  |
| OWN-24 | Lizards and spiders as enemies | docs/DECISIONS.md (audit inventory row 340) |  | superseded by FR-01 |  |
| REC-015 | NPC competition and economic rivalry (as a game system) | owner messages #168 2026-10-19T06:15Z s.7, #188 16:50Z s.11, #194 18:32Z s.3; rule topic 12 in the 2026-10-19T19:09Z directive |  | superseded by WDR-012-C |  |
| REC-016 | NPC self-improvement and prosperity (as a game system) | owner messages #168 2026-10-19T06:15Z s.7, #188 s.11, #194 s.3; #47 2026-10-17T23:35Z s.19 (better housing, business ownership, social standing); rule topic 11 in the 2026-10-19T19:09Z directive |  | superseded by WDR-011-C |  |
| REL-14-16 | Release Builds 14, 15 and 16 (three platform packages each) when the eight release conditions hold | docs/directives/2026-10-19_builds_14_16_release_authorization.md | `7dbae4f` | superseded by REL-15-18 | Build 15: finish EQ-07 housing growth and the multi-seed long runs (docs/CURRENT_DEVELOPMENT_STATE.md); release a private draft when the eight conditions hold |
| REQ-BANDIT | Bandit factions, criminal careers and outlaw leadership | owner: World Design Rule 16 topic; directive 2026-10-19 (requirements preservation) s.26 |  | superseded by WDR-016-C |  |
| REQ-GRAVE | Graveyards, ancestry and NPC legacy | owner: World Design Rule 14 topic; directive 2026-10-19 (requirements preservation) s.26 |  | after GM-01; superseded by WDR-014-C |  |

## UNKNOWN — INVESTIGATION REQUIRED (7)

| ID | Requirement | Source | Evidence | Blockers / depends on | Next action |
|---|---|---|---|---|---|
| FR-11 | Personality, prestige and migration (owner's living-society list, 2026-10-17) | owner message 2026-10-17 |  |  |  |
| REC-003 | Android builds target API 36 (Hot Attic Games standing platform policy) | Game Designer spec Part A s.A0 (bob/CLAUDE.md lines 47-53) and MASTER_PROMPT.md line 41, supplied by the owner 2026-10-17T18:44Z; the agent's merge proposal planned to add it to CLAUDE.md s.8 but never did |  |  | owner to confirm the policy; then record it in CLAUDE.md section 8. The builds already comply |
| REC-008 | Near/far simulation tiers (detailed near the player, abstract far away, nothing duplicated on switching) | Game Designer spec Part A (owner's interview answer, bob/CLAUDE.md line 131); owner directive #16 2026-10-17T16:23Z s.9 ('do not assume every NPC requires full simulation at all times. Propose simulation detail appropriate to the player's location') |  |  |  |
| REC-009 | Combat style: real-time aimed attacks, melee combos and abilities on cooldowns | Game Designer spec Part A s.A2 (bob/CLAUDE.md line 119); agent merge proposal planned a DECISIONS entry 'combat style' that was never written |  |  |  |
| REC-010 | Class progression, 'system jobs' and a tech/research tree | Game Designer spec Part A s.A1/A2 (bob/CLAUDE.md lines 67, 77, 91, 101); agent merge proposal conflict C2 ('Unresolved; your call') never answered |  |  |  |
| REC-014 | Revisit the settlement, agriculture, food, resource, population and trade foundations using the recent research | owner message #149 2026-10-18T20:43Z Phase 1 |  |  |  |
| WDR-003-C | Comply with World Design Rule 3: Meaningful Recipes | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |  |  | Document each counted recipe's purpose |

## Owner decisions, open and answered (open: 37, status BLOCKED) (77)

| ID | Item | Status | Source |
|---|---|---|---|
| CARAVAN-TMP | The daily caravan allowance is a labelled, adjustable temporary stand-in for unsimulated outside settlements during Builds 15-16 (30 coins a day) | IMPLEMENTED — TESTING REQUIRED | docs/directives/2026-10-20_two_decisions_three_expansions.md |
| FARM-08-Q-CROP | How is a field's crop divided among the farmers who work it? | COMPLETE AND VERIFIED | docs/design/FARM08_YIELD_COMPARISON.md |
| OD-01 | Owner decision: deposit sustainability (P1) and the mine wage (B7-006) | BLOCKED | docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md |
| OD-02 | Owner decision: balance review of every provisional number | BLOCKED | docs/DECISIONS.md |
| OD-03 | Owner decisions: design gap assessment D1-D12 (isometric, magic, era, county) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md |
| OD-04 | Owner decisions: chest and lock questions | BLOCKED | docs/BUILD_DECISIONS.md |
| OD-05 | Owner decisions: inner doorways, relaying survey plots | BLOCKED | docs/BUILD_DECISIONS.md |
| OD-06 | Owner decisions: farming (Farming skill, wheat versus wages) | BLOCKED | docs/BUILD_DECISIONS.md |
| OD-07 | Owner decision: hunting in Gather mode | BLOCKED | docs/HANDOFF.md |
| OD-08 | Owner decision: is honest arbitrage intended? | BLOCKED | docs/reference/DESIGNING_VIRTUAL_WORLDS.md A5 |
| OD-09 | Owner decisions: GAME_DESIGN items still open (U3-U5, U13, U16-U21) | BLOCKED | docs/GAME_DESIGN.md |
| OD-10 | Owner decision: a lasting stone source before Build 17 (stone runs out by day 160-190 and stalls house building) | SUPERSEDED | docs/release/LONG_RUN_SIMULATION.md (Build 15 interim 365-day runs); docs/EXPANSION_ROADMAP.md (EQ-09 dependency) |
| OD-11 | Owner decision: an orphaned child for whom no household is eligible: what temporary care applies (stay in the family house watched by neighbours, lodge at the manor, other) | COMPLETE AND VERIFIED | docs/directives/2026-10-20_housing_succession_adoption.md Part 4.5 |
| OD-12 | Owner decision: choosing between equally close eligible relatives (for example two grandparent households, or an aunt and an uncle) | COMPLETE AND VERIFIED | docs/directives/2026-10-20_housing_succession_adoption.md Part 4.5 |
| OD-13 | Owner decision: crowded families that no member can leave (two parents, young children, often a grandparent, more people than beds). Should young children share beds, so such a family is not crowded? Should the original village houses be extendable with living quarters (the ground under them surveyed as parcels)? Both, or neither? | COMPLETE AND VERIFIED | docs/directives/2026-10-20_housing_succession_adoption.md Part 2 (EQ-07 trace, seed 2: five crowded households, all of this shape) |
| OD-14 | Owner decision: no original village house has room for the living-quarters module. The module is house-sized (9x10), must touch the house and cannot cover a road; on the current layout every original house is hemmed in. Options: (a) detached quarters on nearby free ground, counted as the household's rooms; (b) a smaller added room (a new building type); (c) accept that original houses do not expand, and rely on bed sharing, households splitting and new houses. | COMPLETE AND VERIFIED | docs/release/LONG_RUN_SIMULATION.md (EQ-07); measured with housing_test.gd::test_quarters_on_an_original_house |
| OD-15 | Should the player's sales stop at a trader's 15-coin floor, as villagers' sales do (B7-008)? | COMPLETE AND VERIFIED | agent, 2026-10-20, verifying B7-008 (docs/release/BUILD_7_ISSUES.md B7-008; World.player_sell) |
| OD-16 | The village's trade economy stops around day 120-140 on seed 1 (smith out of coins, no iron, no axes, no timber): how should money flow back to the essential trades? | COMPLETE AND VERIFIED | agent, 2026-10-20, docs/release/LONG_RUN_SIMULATION.md 'Why seed 1 builds no house' |
| OD-17 | Owner decision: the Game Designer spec's open calls not covered by another entry: C1 the hero (spec: 'Your main character is the hero' against the confirmed 'not the chosen one'), C10 the view (top-down at an angle, three-quarter, or isometric; with DGA-D1), and Steam Deck labelling (the spec's '(web)' build; the owner said to correct the label without changing the platforms). Class progression is REC-010, ranged combat REC-009, Mote REC-002, the API 36 policy REC-003 | BLOCKED | docs/game-designer/SPEC_RECONCILIATION.md section 4 (REC-004, 2026-10-20) |
| OD-18 | Player-only perks and rules found by the DVW-A8 and DVW-A12 audits | COMPLETE AND VERIFIED | docs/release/BUILD_16_AUDITS.md |
| OD-19 | PAR-02: the universal coin-reserve threshold | COMPLETE AND VERIFIED | docs/directives/2026-10-20_par_final_consolidated_directive.md |
| OD-20 | PAR-05: should a caught pickpocket's cry (theft rules 2026-10-18; the Stealth guard_radius perk) become a report like assault's? | COMPLETE AND VERIFIED | docs/directives/2026-10-20_par_final_consolidated_directive.md |
| OD-21 | Explicit time model and calendar consistency (approved architectural decision) | COMPLETE AND VERIFIED | docs/directives/2026-10-20_od21_time_model.md |
| OD-22 | Which definition the shared farming model starts from (per-cell, per-field, or an explicit difference) | COMPLETE AND VERIFIED | docs/design/FOOD_SECURITY_AUDIT.md section 8 |
| OD-23 | What the manor's fields cost their farmers (lease, crop share, or free to any farmer) | COMPLETE AND VERIFIED | docs/design/FOOD_SECURITY_AUDIT.md section 8 |
| OD-24 | Rent for villager merchants' stalls (pay as the player does, or the player's pitch free) | COMPLETE AND VERIFIED | docs/design/FOOD_SECURITY_AUDIT.md section 8 |
| OD-25 | Owner decision resolution for Build 16 (2026-10-21): FARM-07 2 coins a week; FARM-01/02 variable plots, materials from the perimeter; STALL-01/05 5% of completed sales after audits, rounding not approved; FSE-12 behind a switch with comparison; FSE-13 comparison then review; FSE-B06 deadwood interim; OD-20 witness reports; EQ-22 buying by need; OD-17 still blocked; DVW-A12 to Build 17; DVW-B6 to Build 18 | COMPLETE AND VERIFIED | docs/directives/2026-10-21_build16_owner_decision_resolution.md |
| OD-26 | Owner decision 2026-10-21: one shared per-cell farming model for player, households and manor approved as the direction; no yield approved; both switches off; compare several shared yields (between about 0.9 and 3 wheat a cell) with seasonal farming on, identical seeds; investigate the seasonal milk collapse; recommend a yield for approval | COMPLETE AND VERIFIED | docs/directives/2026-10-21_fse12_fse13_farming_decision.md |
| OD-27 | Owner answers to the land and stall questions Q8-Q13 (2026-10-21) | COMPLETE AND VERIFIED | docs/directives/2026-10-21_build16_master_completion_directive.md |
| OD-28 | Owner decisions for Build 17 (2026-10-21): enterable caves and underground mining; one deposit system everywhere; universal negotiated goods contracts; DVW-A12 direction | COMPLETE AND VERIFIED | docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md |
| OD-29 | Owner decisions (2026-10-21): Build 17 starts now beside Build 16; separate underground maps tied to their surface locations, open pits on the surface; contract defaults provisional | COMPLETE AND VERIFIED | docs/directives/2026-10-21_build17_start_underground_contracts.md |
| OD-30 | Official expansion numbering: 20 Living Economy, 21 Politics, 22 Bandits, 23 Legacy; Exploration unnumbered; Multiplayer a separate track | COMPLETE AND VERIFIED | docs/directives/2026-10-21_expansion_numbering_approval.md |
| OD-LE-01 | Owner decision (Living Economy): Standalone build number and placement without displacing existing Build 19 Judgment | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-02 | Owner decision (Living Economy): Market board, direct negotiation or hybrid and visibility rules | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-03 | Owner decision (Living Economy): Wages, rents and service contracts in first release | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-04 | Owner decision (Living Economy): Business founding, partnerships, ownership and inheritance | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-05 | Owner decision (Living Economy): Loan interest, collateral, default and collection rules | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-06 | Owner decision (Living Economy): Permissible manor interventions and political authority | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-07 | Owner decision (Living Economy): Restricted-use advances and business/household account separation | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-08 | Owner decision (Living Economy): Barter, rental, repair and resource substitution | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-09 | Owner decision (Living Economy): Bandit market participation and regional trading limits | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-10 | Owner decision (Living Economy): Economic rumor, memory persistence and reliability | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-11 | Owner decision (Living Economy): Speculation, hoarding and deliberate market manipulation | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-12 | Owner decision (Living Economy): Charity, kinship support and communal relief | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-13 | Owner decision (Living Economy): Contract cancellation, penalties and death of a party | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-14 | Owner decision (Living Economy): Player intervention and visibility of market decisions | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OD-LE-15 | Owner decision (Living Economy): Performance and population acceptance targets | BLOCKED | docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx section 18 |
| OWN-09 | Build 8 private only; registry public-only; no sustainability changes until decided | COMPLETE AND VERIFIED | docs/DECISIONS.md (audit inventory row 325) |
| Q18-10 | Anyone may buy from another settlement; the buyer fetches the goods or pays a willing carter; no free delivery, no merchant-only buying, nothing created | COMPLETE AND VERIFIED | docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md |
| Q18-11 | What pay factor and output factor should each settlement capability level give, and for which industries? (Until answered every factor is 1.0, no effect) | PARTIALLY IMPLEMENTED | docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md |
| Q18-11A | Which compensation and productivity percentages per industry and level 0-10? (Candidate +20% output / +8% pay at level 10, diminishing; research-informed proposal, NOT approved) | COMPLETE AND VERIFIED | docs/directives/2026-10-21_expansion18_master_directive.md |
| Q18-11B | How do worker experience, tools, facilities and infrastructure compose a settlement's capability rating? (Options to be presented; no weighting or permanent advancement system without approval) | COMPLETE AND VERIFIED | docs/directives/2026-10-21_expansion18_master_directive.md |
| Q18-12 | May a buyer hire a villager or carter to haul goods between settlements, and on what terms (day wage, fee per load, or a negotiated service contract)? Overlaps OD-LE-03 and MIN-D-Q1 | COMPLETE AND VERIFIED | docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md |
| Q18-13 | Should CON-01 contracts gain parties for households and off-map settlements, or should a household buy through a named member and a region through a named merchant? | COMPLETE AND VERIFIED | docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md |
| Q18-9 | Settlement capability levels affect pay scales and production output only; never a permission gate | COMPLETE AND VERIFIED | docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md |
| ROAD-01 | Five-build roadmap: 15 simulation stabilization, 16 long-term equilibrium, 17 Mining & Industrial, 18 Settlement & Regional Economy, 19 NPC Judgment | ACTIVE DEVELOPMENT | owner messages 2026-10-20 (chat), restated in docs/directives/2026-10-20_project_memory_hardening.md and docs/directives/2026-10-20_permanent_project_memory_hardening.md; recorded in docs/EXPANSION_ROADMAP.md |
| SJD-Q01 | Judgment open decision: Should there be a NEUTRAL objective event type, or must every judged event begin GOOD/BAD? | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q02 | Judgment open decision: Should scores decay, or change only through new events, forgiveness and corrected beliefs? | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q03 | Judgment open decision: Different disposition thresholds per NPC, or one calibrated scale? | BLOCKED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q04 | Judgment open decision: Should very large GOOD and BAD totals with NET near 0 create ambivalence behaviour? | BLOCKED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q05 | Judgment open decision: How much may prior judgment bias interpretation of ambiguous events? | BLOCKED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q06 | Judgment open decision: How should confidence and rumours influence points: multiplier, threshold, or separate belief layer? | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q07 | Judgment open decision: How far should gossip spread; should reach depend on social proximity and personality? | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q08 | Judgment open decision: How should legal guilt, moral judgment and personal loyalty interact? | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q09 | Judgment open decision: Always highest utility, or sometimes near-optimal via seeded randomness? | BLOCKED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q10 | Judgment open decision: What judgment information, if any, can the player see? | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q11 | Judgment open decision: How should memory persistence and forgiveness vary by severity? | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q12 | Judgment open decision: What makes an event important enough to score? | BLOCKED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q13 | Judgment open decision: How should individual decision weights be learned, configured or tuned? | BLOCKED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| SJD-Q14 | Judgment open decision: Which domain gets the first live integration after the prototype? | COMPLETE AND VERIFIED | docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf |
| X19-ASSAULT | Should being assaulted oneself be a permanent memory (the proposed threshold makes it so; at the stress rate victims accumulate many)? | BLOCKED | docs/directives/2026-10-21_expansion19_sjd_final_decisions.md |
| X19-CRT12 | Courtship proposals use fixed notoriety and regard cut-offs (CRT-12); keep 'no marrying a killer' absolute and weigh the rest with judgment, or keep the cut-offs? | BLOCKED | docs/directives/2026-10-21_expansion19_sjd_final_decisions.md |
| X19-DECAY | Judgment decay rate for ordinary contributions (proposed 3 permille a day, half-life 231 days; demonstrated 1-10 permille over 365 days; murder never decays) | BLOCKED | docs/directives/2026-10-21_expansion19_sjd_final_decisions.md |
| X19-GUARD | A guard who is the player's friend waives the fine (CRT-06) while SJD-Q08 says a guard can like someone and still enforce: keep, always enforce, or let friendship reduce but never waive the fine? | BLOCKED | docs/directives/2026-10-21_expansion19_sjd_final_decisions.md |
| X19-HARMED | Relations.harmed lowers the player's standing with a victim's kin and friends instantly; when judgment is live, should word of mouth carry it instead (SJD-Q07 no instant broadcasts)? | BLOCKED | docs/directives/2026-10-21_expansion19_sjd_final_decisions.md |
| X19-Q-TIMING | Gossip timing: keep 'spread' (identical results to telling an hour's meetings at once; rare long catch-up frames ~8.6 ms on a phone) or allow 'scheduled' (each meeting at its own seeded minute: smallest frames, but word passes at different times, so outcomes differ slightly)? | BLOCKED | docs/directives/2026-10-21_parallel_prospective_development_18_19.md |
| X19-REGARD | Relations regard is both trust (believing stories) and harm (a seen crime lowers it), so victims believe culprits less: accept this coupling or separate trust from regard? | BLOCKED | docs/directives/2026-10-21_expansion19_sjd_final_decisions.md |

## World design rule (30)

| ID | Item | Status | Source |
|---|---|---|---|
| AGENT-01 | Controlled parallel development: at most two subagents at once (three agents with the lead), bounded tasks, no nested agents, only the lead runs long simulations; an agent summary in progress reports | COMPLETE AND VERIFIED | docs/directives/2026-10-20_controlled_parallel_development.md |
| MILE-01 | Milestone assignments are respected: nothing moves into Build 16 from the expansions (the Living Economy build, Build 19's NPC Judgment) without the owner | COMPLETE AND VERIFIED | docs/directives/2026-10-20_controlled_parallel_development.md |
| MSW-01 | Minimum Sufficient Work: correctness mandatory, redundancy justified | APPROVED — NOT STARTED | docs/directives/2026-10-22_msw01_outstanding_issues_x18_preparation.md |
| PROS-01 | Parallel prospective development of Expansions 18 and 19 on isolated branches while Build 17 stays the priority; no merge, release or presentation as integrated gameplay before the reconciliation gates | ACTIVE DEVELOPMENT | docs/directives/2026-10-21_parallel_prospective_development_18_19.md |
| REL-CONT | Standing release model: continuous develop, test, release, advance; minor decisions made and documented | COMPLETE AND VERIFIED | docs/directives/2026-10-21_standing_continuous_release_directive.md |
| SIM-01 | Continuous long-run simulation testing: the longest run once per seed, monitored, with checkpoints | APPROVED — NOT STARTED | docs/directives/2026-10-21_continuous_long_run_simulation.md |
| SIM-02 | Simulation monitoring: observe, never restart active runs without owner approval; check-ins from measured runtimes; prompt reporting | APPROVED — NOT STARTED | docs/directives/2026-10-21_simulation_monitoring.md |
| WDR-001 | World Design Rule 1: Material Interdependency | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-002 | World Design Rule 2: Professional Interdependency | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-003 | World Design Rule 3: Meaningful Recipes | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-004 | World Design Rule 4: Economic Consequences | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-005 | World Design Rule 5: Living World Independence | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-006 | World Design Rule 6: Maintain the Existing Interlocking Systems Manifest | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-007 | World Design Rule 7: Automated Compliance | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-008 | World Design Rule 8: Player Knowledge and Wiki | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-009 | World Design Rule 9: Emergent Gameplay | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-010 | World Design Rule 10: Depth Without Obscurity | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-011 | World Design Rule 11: NPC Self-Improvement and Prosperity | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-012 | World Design Rule 12: NPC Competition and Economic Rivalry | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-013 | World Design Rule 13: Finite Resources and Actual Consumption | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-014 | World Design Rule 14: Graveyards, Ancestry, and NPC Legacy | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-015 | World Design Rule 15: Political Authority, Social Hierarchy, and Civic Employment | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-016 | World Design Rule 16: Bandit Factions, Criminal Careers, and Outlaw Leadership | COMPLETE AND VERIFIED | docs/WORLD_DESIGN_RULES.md (owner's World Design Rules v1.0, expanded reference, docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf, 2026-10-19) |
| WDR-017 | World Design Rule 17: Generational Memory and Living History | COMPLETE AND VERIFIED | docs/directives/2026-10-19_memory_refuges_politics.md s.40 (text recorded in docs/WORLD_DESIGN_RULES.md) |
| WDR-018 | World Design Rule 18: Protected Ecological Continuity | COMPLETE AND VERIFIED | docs/directives/2026-10-19_memory_refuges_politics.md s.40 (text recorded in docs/WORLD_DESIGN_RULES.md) |
| WDR-019 | World Design Rule 19: Living Political Agency and Democratic Consequences | COMPLETE AND VERIFIED | docs/directives/2026-10-19_memory_refuges_politics.md s.40 (text recorded in docs/WORLD_DESIGN_RULES.md) |
| WDR-020 | World Design Rule 20: Autonomous Housing | COMPLETE AND VERIFIED | docs/directives/2026-10-20_housing_succession_adoption.md (final governing principle; text recorded in docs/WORLD_DESIGN_RULES.md) |
| WDR-021 | World Design Rule 21: Household Succession and Family Care | COMPLETE AND VERIFIED | docs/directives/2026-10-20_housing_succession_adoption.md (final governing principle; text recorded in docs/WORLD_DESIGN_RULES.md) |
| WDR-022 | World Design Rule 22: A Village Is Allowed to Fail; the Simulation Is Not | COMPLETE AND VERIFIED | docs/directives/2026-10-20_final_development_mandate.md sections 1-4, 11, 12 (text in docs/WORLD_DESIGN_RULES.md) |
| WIKI-01 | Permanent wiki and documentation maintenance: a feature is not complete without accurate documentation; player-facing in-game wiki and developer reference kept separate; updated in the same workstream; implemented-only; reported; a release documentation gate | COMPLETE AND VERIFIED | docs/directives/2026-10-21_permanent_wiki_maintenance.md |

## Proposal awaiting an owner decision (not approved) (32)

| ID | Item | Status | Source |
|---|---|---|---|
| DGA-D1 | Meaning of "isometric" | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 378) |
| DGA-D10 | Formal platform/engine approval (U1, U2) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 387) |
| DGA-D11 | Living-society scope (U20, U21, P1-P3, balance review) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 388) |
| DGA-D12 | Approval to start phase 1 | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 389) |
| DGA-D2 | Isometric art source (J-G4) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 379) |
| DGA-D3 | Connectivity with no server | PARTIALLY IMPLEMENTED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 380) |
| DGA-D4 | Shared-world rules (pause, characters, heir) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 381) |
| DGA-D5 | Reputation/ownership/PvP (J-S3, U21) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 382) |
| DGA-D6 | Combat model and latency (U7) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 383) |
| DGA-D7 | Visible gear | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 384) |
| DGA-D8 | Era, county, political status, map scale | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 385) |
| DGA-D9 | Magic (J-M1..4) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 386) |
| DGA-R | Refactors (coordinates, players collection, command layer, fixed step + state hash, save split, appearance data, magic schema) | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 390) |
| DGA-S | Isometric look spike; network feasibility spike | BLOCKED | docs/DESIGN_GAP_ASSESSMENT.md (audit inventory row 391) |
| DVW-B10 | Onboarding, first ten minutes | BLOCKED | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 282) |
| DVW-B11 | No instant fast travel (rule) | BLOCKED | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 283) |
| DVW-B12 | Ethics/lore: thralldom, Church, content note | BLOCKED | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 284) |
| DVW-B13 | Story kept as sparks; audit `story: true` quests | BLOCKED | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 285) |
| DVW-B8 | Skills for farming, husbandry, hunting, healing | BLOCKED | docs/reference/DESIGNING_VIRTUAL_WORLDS.md (audit inventory row 280) |
| ECON-P1.1 | Demand-driven mining (:71) | BLOCKED | docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md (audit inventory row 298) |
| ECON-P1.2 | Manor mining rights, royalty, quota, stone reserve (:72) | BLOCKED | docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md (audit inventory row 299) |
| ECON-P1.3 | Caravan as finite regional market (:73) | BLOCKED | docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md (audit inventory row 300) |
| ECON-P1.4 | Prospecting new seams (:74) | BLOCKED | docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md (audit inventory row 301) |
| ECON-P1.5 | Distant quarry (:75) | BLOCKED | docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md (audit inventory row 302) |
| ECON-P2 | Wildlife carrying capacity, sex floor, migration pool, hunting rights/quota, extinction, seasons (:116-121) | BLOCKED | docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md (audit inventory row 303) |
| ECON-P3 | Household vs business money, quotes follow money, stock days, market hire wages, `World.spendable` (:183-187) | BLOCKED | docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md (audit inventory row 304) |
| MIN-L5 | Mining capability level 5 (integrated industrial mining) | APPROVED — NOT STARTED | docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf |
| OWN-02 | Wildlife balance follow-up; horse imported, use pending | BLOCKED | docs/DECISIONS.md (audit inventory row 318) |
| OWN-29 | Era, county, atlas storage, Godot, Android, PCG32 | BLOCKED | docs/DECISIONS.md (audit inventory row 345) |
| Q-11 | Design gap assessment, phased sequence | BLOCKED | docs/DEVELOPMENT_QUEUE.md (audit inventory row 227) |
| ROAD-02 | Master Expansion Roadmap and Documentation Pack (owner, 2026-10-21): 17 Mining, 18 Settlements, 19 Judgment approved; 20 Living Economy, 21 Politics, 22 Bandits, 23 Legacy, Exploration and Multiplayer as proposed numbering | APPROVED — NOT STARTED | docs/directives/2026-10-21_master_expansion_roadmap.md (the pack's other documents on wip/roadmap-docs, docs/roadmap/) |
| TIME-03 | Recommended time retuning (outliers): proposals only, owner review before any change | COMPLETE AND VERIFIED | docs/directives/2026-10-20_od21_time_model.md |

## Unapproved idea (2)

| ID | Item | Status | Source |
|---|---|---|---|
| B12A-05 | Accessibility not yet added: text scaling, a colour-blind mode, key rebinding, turning off the blinking | APPROVED — NOT STARTED | docs/release/BUILD_12_FULL_AUDIT.md (audit inventory row 355) |
| CAP-TOOLHOLDER | Design review: a villager holding a tool only for sale counts as a capability practitioner | APPROVED — NOT STARTED | docs/directives/2026-10-22_msw01_outstanding_issues_x18_preparation.md |

