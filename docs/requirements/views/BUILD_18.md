# Build 18: Combined release (tracks A, B, C)

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: B18-DIR, B18-SCOPE; no distributable without the owner's approval

Readiness: **IN DEVELOPMENT (not feature complete)**

| Count | Value |
|---|---|
| Approved requirements in scope | 74 |
| Integrated | 36 of 74 (49%) |
| Automated tests passed | 37 of 74 (50%) |
| Integration verified | 36 of 74 (49%) |
| Gameplay verified | 0 of 74 (0%) |
| Owner playtested | 0 of 74 (0%) |
| Complete | 1 of 74 (1%) |
| Open (release blockers) | 73 |
| Open owner decisions (blocking) | 10 (2) |

## In development (worker assigned) (3)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| DVW-B3-FEAST | Coin sink: wedding feasts and seasonal feasts at the tavern, food and ale really bought and eaten | OWNER APPROVED | IN DEVELOPMENT | feast worker (Sonnet subagent, started 2026-10-23) / wip/b18-feast | NOT TESTED |  |  | M |
| DVW-B3-LUX | Coin sink: luxury imports sold by the caravan for status | OWNER APPROVED | IN DEVELOPMENT | luxury worker (Sonnet subagent, started 2026-10-23) / wip/b18-luxury | NOT TESTED |  |  | S |
| REG-INV-01 | Regional economy investigation: Higham's treasury decline, village sustainability under settlement traders, village buying from settlements, courier booths on the five settlements, settlement demographics | OWNER APPROVED | IN DEVELOPMENT | lead / wip/build18 | NOT TESTED |  | design: UNKNOWN | UNKNOWN |

## Integrated, awaiting gameplay or owner verification (35)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| ARMOR-01 | Armour is acquired in play, physical, and visible when worn | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| B14-11 | Animal Farm pack: the horse and farm animals | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate; known: the caravan's wagon is a stand-in sprite (mine cart tile) |  | verification only |
| BANDIT-RETURN | Outlaws return: a season after the band is wiped out, 2-3 outlaws arrive from outside and camp in the woods | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| BARBER-01 | Barber service: change hairstyle in the village through the economy | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| CC-01 | Character creator replaces the eight preset looks (appearance only, civilian) | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest; phone layout and cost of the runtime sprite not checked on a device; Build 18 release gate |  | verification only |
| CON-UX-01 | Contract window needs design work | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| DVW-B3-CHAPEL | Coin sink: offerings at a village chapel or shrine (a chapel building is needed) | OWNER APPROVED | INTEGRATED | 18 | INTEGRATION VERIFIED | Gameplay and device check; owner review CHAPEL-R1..R5 (non-blocking); wage, piety, offering and seed numbers in balance.json "chapel" are provisional working values, not owner-approved balance; known: Chapel uses the plain house art (no steeple or sign); Player cannot volunteer on the church plot; Old saves lose 22 wild plants on the chapel ground; hidden-ore layout shifts for every seed |  | verification only |
| DVW-B8 | Skills for farming, husbandry, hunting, healing | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest; Build 18 release gate; known: Farming, Husbandry and Hunting train but give no gameplay effect yet (no perks were specified) |  | verification only |
| ECON-P1.3 | Caravan as finite regional market (:73) | OWNER APPROVED | INTEGRATED | 18 | INTEGRATION VERIFIED | Gameplay check. Measured effect over 30 days: the caravan buys 7-8 kinds of goods instead of about 20, and the village earns roughly a quarter to a half less from it (seed 1 +1540 vs +1996 coins, seed 2 +1070 vs +2178); population and food unaffected; known: Courier booths still use SettlementLedger parties, not the new settlements |  | verification only |
| FARM-CROP-01 | Share a field's crop among its cutters in proportion to their cutting work | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate |  | verification only |
| FARM-CROP-SEED | Seed kept back from a shared field is split among its cutters by work, as the grain is | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| INV-18 | Categorized inventory: eight capacity pools, separate equipment, two upgrade stages | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| MAP-01 | Map shows where you are beyond the village | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| ORE-PLACE-01 | Natural ore evidence and finds kept out of the developed village footprint | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest; the determinism gate must be re-recorded on Build 18 (REL18-DET) because clue placement changed |  | verification only |
| ROOMS-18 | Inner doorways between joined house rooms, and the two survey plots relaid onto open ground | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate; known: no doorway on a house's east wall (furniture) or between rooms stacked north-south; the old-world (legacy plots) view is untested by screenshot |  | verification only |
| SET-C-FIVE | Five off-map settlements of mixed kinds, each a simulated economy (SET-C-SIM) | OWNER APPROVED | INTEGRATED | 18 | INTEGRATION VERIFIED | Gameplay check; owner may review the lore choices in docs/expansion18/SETTLEMENTS.md; known: Garton's mining diggings are a game invention (flagged unresolved in docs/expansion18/SETTLEMENTS.md); the village's own place on the road is assumed (J-D2 open) |  | verification only |
| SET-C-SIM | Off-map settlements as lighter-detail simulated economies: households, a manor or council treasury, businesses, wages, taxes and prices under the village's rules, stepped daily | OWNER APPROVED | INTEGRATED | 18 | INTEGRATION VERIFIED | Gameplay check; settlement numbers in game/data/settlements.json are provisional agent values (DECISIONS.md); Higham-on-the-Way loses 10 of 99 after about day 150 in isolation (recorded outcome, not tuned); known: No births or old-age deaths in the settlements yet; Village cannot buy food from the settlements yet; no tool-shortage productivity penalty |  | verification only |
| SKILL-TRADES-18 | Carpentry, Masonry and Tanning skills, started from each person's Crafting experience; the matching work earns them | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| STONE-05 | Stoneworking skill: a distinct skill in the existing skill system that governs stone dressing | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| TAILOR-18 | Tailor: a village NPC service selling the two backpack upgrades | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| TRADE-AXE-01 | Playtest: cannot buy Clement Ward's axe (listed 45) holding 47 coins | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| TRADE-UI-02 | Contract proposal's answer shown in view | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| UI-HUD-01 | HUD status panel too large: shrink and move the date line | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| UI-HUNGER-01 | Hunger icon becomes a drumstick | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| UI-PROGRESS-01 | Progress bar visible on light and dark ground | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| UI-WIKI-01 | Village Encyclopedia: navigable, searchable wiki window | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| VIS-ANIMAL-01 | Stray fragments above animals removed at the source | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| VIS-AXE-01 | Lumberjack axe: believable chop, blade never through the head | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| VIS-CROP-01 | Ripe wheat recognizable; planted, growing, mature, harvested look distinct | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| VIS-DOOR-01 | Doorway transition: characters no longer pass under a closed door | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| VIS-STEPS-01 | Steps cut through rock need real step art | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate; known: a thin seam at one join between two step cells (north-south, ground to the north) |  | verification only |
| VIS-TREE-02 | Tree fragments: no stray old tree pieces; stages and stumps draw correctly | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| WORLD-LIFE-01 | The countryside is empty of people and animals; its trails lead nowhere yet | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device (performance on a phone); Build 18 release gate; known: countryside animals are ambient only: they cannot be hunted; travellers stop at the village gate |  | verification only |
| X18-CAPCOMP | Capability composition: workforce capability from local experience, effective capability capped by operational facilities | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | owner playtest on a device; Build 18 release gate (REL18-*) |  | verification only |
| X18-CAPNUM | Capability modifiers: the bounded model (revised_bounded) for six industries, farming as labour efficiency | OWNER APPROVED | INTEGRATED | Build 18 wip/build18 | INTEGRATION VERIFIED | final percentages after X18-SIM (Q18-11); MIN-D mining stages mapped to 0-10 (reconciliation item); owner playtest |  | verification only |

## Ready to proceed now (approved, specified, nothing open blocks it) (20)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| DVW-B5 | Predictable taxes with hysteresis, announced | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | M |
| ECON-P3 | Household vs business money, quotes follow money, stock days, market hire wages, `World.spendable` (:183-187) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | M |
| LAW-SKILL | Law skill: learned by witnessing and carrying documents, taught by the clergy or reeve; needed by a courier to notarise | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | TARGETED TESTS PASSED | courier-notary path not live; villagers do not take lessons; clergy teaching waits on DVW-B3-CHAPEL |  | S |
| MIGRATE-18 | Migration both ways between the village and the off-map settlements for work, land, marriage or hunger | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | L |
| REL18-DET | Build 18 release gate: Determinism gate re-recorded on Build 18 code (two independent runs identical) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | S |
| REL18-DEVICE | Build 18 release gate: Device and owner playtest of every player-facing Build 18 requirement (the playtest queue) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | M |
| REL18-EXPORT | Build 18 release gate: Android, Windows and Linux packages from one commit and one build number | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | M |
| REL18-LONGRUN | Build 18 release gate: Conservation and long runs: one 365-day run per required seed, no ledger leak (SIM-01) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | M |
| REL18-OWNER | Build 18 release gate: The owner's approval to publish a Build 18 distributable (B17-DIR exception carried to Build 18) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | S |
| REL18-SAVE | Build 18 release gate: Save compatibility: a real Build 17 save loads into Build 18, plus migration fixtures | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | S |
| REL18-SUITES | Build 18 release gate: All automated suites pass on the final Build 18 integration commit | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | S |
| REL18-WIKI | Build 18 release gate: WIKI-01 release gate: new and changed mechanics documented, wiki checks pass | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | S |
| SET-A | Settlement expansion phase A: Design and ledger: requirement ids, cross-industry skill schema, save compatibility, dependency audit | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | NOT TESTED | close-out against the specification's acceptance criteria |  | XS |
| TRADE-CREDIT | Barter and credit with trust: goods-for-goods deals and recorded debts that must be repaid; unpaid debts hurt standing | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  |  | L |
| WDR-002-C | Comply with World Design Rule 2: Professional Interdependency | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED | docs/systems/MATERIAL_INTERDEPENDENCY.md professions table; the sage's supply link |  | M |
| X18-Q12 | Implement Q18-12 transport: flat-rate fees on regular routes or scheduled delivery, negotiated special deliveries, self-collection; smoke tests | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | NOT TESTED | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |  | L |
| X18-Q12-BOOTH | Courier booths in each city, village and major business, serving regular routes (flat fee per load or scheduled delivery); special deliveries negotiated by choosing a recipient among the people and businesses the buyer knows | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | NOT TESTED | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |  | M |
| X18-Q12-POST | Courier contract popup like online postage (dropdowns: quantity, item, recipient, location, collect payment, deliver or deposit proceeds, money/item type and amount, route or special) assembled into a readable instruction; recipients from known people and businesses incl. prior trading contacts (owner represents the business; location from world records); fee computed from route type, distance, burden, capacity, stops, return/deposit, labour, notarial service; physical execution; fulfilled only when obligations are done | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | NOT TESTED | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |  | M |
| X18-Q13 | Implement Q18-13 signing: small agreements unsigned; formal contracts and ownership transfers signed face to face, or through a courier-notary with legal skill carrying the documents; no remote instant signing; smoke tests for incomplete, rejected, interrupted and completed agreements | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | NOT TESTED | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |  | L |
| X18-SIM | Comparative capability simulations (baseline, conservative, moderate, aggressive; levels 0,2,5,8,10; implemented industries; settlement size, resource and labour scenarios; 30 and 90 days) and a recommendation; no permanent constants before owner review | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | NOT TESTED | run the comparative simulations (models x levels x scenarios, 30 and 90 days) and report; no constants before owner review (Q18-11) |  | M |

## Blocked (open owner decision, unfinished dependency or unsettled design) (15)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| PL1-10 | Player businesses, staged (1-4) | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| PL2-008 | Expandable property | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| PL2-014 | Modular house/workshop expansion | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| PL2-015 | Farming, livestock, hand plough | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| SET-B | Settlement expansion phase B: Settlement capability model: per-industry capabilities, NPC knowledge, workshops, prerequisites, decay and continuity | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | NOT TESTED | close-out against the specification's acceptance criteria | SET-A | S |
| SET-C | Settlement expansion phase C: Abstract regional economy: off-map settlements with finite demand, supply and budgets; variable caravan trade | OWNER APPROVED | PARTIALLY IMPLEMENTED | Build 18 wip/build18 | NOT TESTED | lands with SET-C-SIM and SET-C-FIVE | SET-B | UNKNOWN |
| SET-D | Settlement expansion phase D: Settlement development: growth and decline, specialization, housing, infrastructure, population and employment | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | SET-C, design: DESIGN WORK REQUIRED | XL |
| STONE-02 | Personal-use stone dressing by any villager (own house or repairs), same rules as the player | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | STONE-D1, STONE-D2, design: OWNER DECISION REQUIRED | S |
| STONE-03 | Materials by kind of work: major masonry reconstruction in blocks and mixed raw-stone-and-block jobs | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | STONE-D1, design: OWNER DECISION REQUIRED | S |
| STONE-04 | Skill-based stone dressing efficiency with conserved waste (one rule for player and villagers) | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | STONE-D1, design: OWNER DECISION REQUIRED | S |
| STONE-06 | Iron chisel: smith-made, worn by use, needed with the mallet to dress stone | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | STONE-D2, design: OWNER DECISION REQUIRED | S |
| WDR-004-C | Comply with World Design Rule 4: Economic Consequences | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED | Comparison runs (B14R-02); scarcity responses audit | design: DESIGN WORK REQUIRED | M |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | OWNER APPROVED | NOT STARTED | none | NOT TESTED | Design the five aspiration domains | design: DESIGN WORK REQUIRED | L |
| WDR-012-C | Comply with World Design Rule 12: NPC Competition and Economic Rivalry | OWNER APPROVED | PARTIALLY IMPLEMENTED | none | NOT TESTED | Competition audit and design | design: DESIGN WORK REQUIRED | M |
| X18-STONECUT | Professional stonecutter: an independent trade and business that dresses and sells building blocks | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | STONE-D1, STONE-D2, design: OWNER DECISION REQUIRED | M |

## Complete (1)

| ID | Requirement | Verification | Release |
|---|---|---|---|
| SYNC-17 | Synchronize Expansions 18 and 19 one way with the Build 17 baseline cd7439c | INTEGRATION VERIFIED | NOT READY |

## Open owner decisions (10)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
| CHAPEL-R1 | Should the player be allowed to volunteer on the church field? (Today only villagers and the clergy work it.) | OPEN | no |  |
| CHAPEL-R2 | Can offerings sustainably fund the clergy's wages (3 and 2 coins a day, unpaid days owed up to 14)? Needs long-run evidence before the owner decides. | OPEN | no |  |
| CHAPEL-R3 | Can old-save migration preserve the existing wild plants and other objects on the chapel ground instead of removing them (22 plants today)? | OPEN | no |  |
| CHAPEL-R4 | Does the chapel's placement change seeded hidden-ore locations in a way that violates the determinism or save-compatibility requirements? | OPEN | no |  |
| CHAPEL-R5 | Does the chapel need distinct artwork (steeple, sign) before the Build 18 release? | OPEN | no |  |
| Q18-11 | What pay factor and output factor should each settlement capability level give, and for which industries? (Until answered every factor is 1.0, no effect) | PROVISIONAL | no | Q18-11A, Q18-11B |
| Q18-6 | Q18-6: may abstract regions show 'two settlements develop different profiles' | PROVISIONAL | no |  |
| STONE-D1 | Stone dressing efficiency values by skill (STONE-04) and the materials rule's numbers | OPEN | yes | STONE-02, STONE-03, STONE-04, X18-STONECUT |
| STONE-D2 | Iron chisel wear and recipe (STONE-06) | OPEN | yes | STONE-02, STONE-06, X18-STONECUT |
| X18-FEES | Courier fee coefficients and the small-agreement threshold (X18-Q12, X18-Q13) | OPEN | no |  |

## Not counted: umbrellas, proposals, ideas, deferred (9)

| ID | Item | Kind | Approval |
|---|---|---|---|
| B17F-DEPLETE | Build 17 finding: 26-28 ore seams worked out a seed by day 365; resource depletion trend | idea | PROPOSED |
| B17F-SIMREPORT | economy_sim reporting fixes: open pits counted as building sites; checkpoint lines not in the job log | idea | PROPOSED |
| B18-DIR | Build 18 master integration directive (visual polish, character customization, armour, crop sharing) | umbrella | OWNER APPROVED |
| CAP-TOOLHOLDER | Design review: a villager holding a tool only for sale counts as a capability practitioner | idea | PROPOSED |
| DVW-B3 | Coin sinks people enjoy (luxury imports, feasts, weddings, offerings, heriot) | umbrella | OWNER APPROVED |
| DVW-B6 | Wildlife wandering in from the overworld | approved | DEFERRED |
| EXP-B | Expansion B: Settlement Advancement & Regional Economy (independent future expansion; supporting document is the primary specification) | umbrella | OWNER APPROVED |
| F-1 | NPC workshop construction | approved | DEFERRED |
| PROS-18 | Expansion 18 prospective implementation (settlement capability and specialization, regional supply and demand, routes and transport, settlement inventories and reports, competition and cooperation, caravan subsidy replacement plan, conservation tests) | umbrella | OWNER APPROVED |

