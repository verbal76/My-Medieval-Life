# Build 18: Combined release (tracks A, B, C)

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: B18-DIR, B18-SCOPE; no distributable without the owner's approval

Readiness: **IN DEVELOPMENT (not feature complete)**

| Count | Value |
|---|---|
| Approved requirements in scope | 73 |
| Integrated | 32 of 73 (44%) |
| Automated tests passed | 33 of 73 (45%) |
| Integration verified | 32 of 73 (44%) |
| Gameplay verified | 0 of 73 (0%) |
| Owner playtested | 0 of 73 (0%) |
| Complete | 1 of 73 (1%) |
| Open (release blockers) | 72 |
| Open owner decisions (blocking) | 5 (2) |

## Open, in development (4)

| ID | Requirement | Design | Effort | Verification | Worker / branch | Remaining work | Decisions / depends on |
|---|---|---|---|---|---|---|---|
| DVW-B3-CHAPEL | Coin sink: offerings at a village chapel or shrine (a chapel building is needed) | SPECIFIED | L | NOT TESTED | chapel worker (Sonnet subagent, started 2026-10-23) / wip/b18-chapel |  |  |
| ECON-P1.3 | Caravan as finite regional market (:73) | SPECIFIED | M | NOT TESTED | regions worker (Sonnet subagent, started 2026-10-23) / wip/b18-regions |  |  |
| SET-C-FIVE | Five off-map settlements of mixed kinds, each a simulated economy (SET-C-SIM) | SPECIFIED | M | NOT TESTED | regions worker (Sonnet subagent, started 2026-10-23) / wip/b18-regions |  | after Q18-4 |
| SET-C-SIM | Off-map settlements as lighter-detail simulated economies: households, a manor or council treasury, businesses, wages, taxes and prices under the village's rules, stepped daily | SPECIFIED | XL | NOT TESTED | regions worker (Sonnet subagent, started 2026-10-23) / wip/b18-regions |  | after Q18-3 |

## Open, partially implemented (15)

| ID | Requirement | Design | Effort | Verification | Worker / branch | Remaining work | Decisions / depends on |
|---|---|---|---|---|---|---|---|
| LAW-SKILL | Law skill: learned by witnessing and carrying documents, taught by the clergy or reeve; needed by a courier to notarise | SPECIFIED | S | TARGETED TESTS PASSED |  | courier-notary path not live; villagers do not take lessons; clergy teaching waits on DVW-B3-CHAPEL | after Q18-14 |
| PL1-10 | Player businesses, staged (1-4) | UNKNOWN | UNKNOWN | NOT TESTED |  |  |  |
| PL2-008 | Expandable property | UNKNOWN | UNKNOWN | NOT TESTED |  |  |  |
| PL2-014 | Modular house/workshop expansion | UNKNOWN | UNKNOWN | NOT TESTED |  |  |  |
| PL2-015 | Farming, livestock, hand plough | UNKNOWN | UNKNOWN | NOT TESTED |  |  |  |
| SET-A | Settlement expansion phase A: Design and ledger: requirement ids, cross-industry skill schema, save compatibility, dependency audit | SPECIFIED | XS | NOT TESTED |  | close-out against the specification's acceptance criteria |  |
| SET-B | Settlement expansion phase B: Settlement capability model: per-industry capabilities, NPC knowledge, workshops, prerequisites, decay and continuity | SPECIFIED | S | NOT TESTED |  | close-out against the specification's acceptance criteria | after SET-A |
| SET-C | Settlement expansion phase C: Abstract regional economy: off-map settlements with finite demand, supply and budgets; variable caravan trade | SPECIFIED | UNKNOWN | NOT TESTED |  | lands with SET-C-SIM and SET-C-FIVE | after SET-B |
| WDR-002-C | Comply with World Design Rule 2: Professional Interdependency | SPECIFIED | M | NOT TESTED |  | docs/systems/MATERIAL_INTERDEPENDENCY.md professions table; the sage's supply link |  |
| WDR-004-C | Comply with World Design Rule 4: Economic Consequences | DESIGN WORK REQUIRED | M | NOT TESTED |  | Comparison runs (B14R-02); scarcity responses audit |  |
| WDR-012-C | Comply with World Design Rule 12: NPC Competition and Economic Rivalry | DESIGN WORK REQUIRED | M | NOT TESTED |  | Competition audit and design |  |
| X18-Q12 | Implement Q18-12 transport: flat-rate fees on regular routes or scheduled delivery, negotiated special deliveries, self-collection; smoke tests | PARTIAL | L | NOT TESTED |  | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |  |
| X18-Q12-BOOTH | Courier booths in each city, village and major business, serving regular routes (flat fee per load or scheduled delivery); special deliveries negotiated by choosing a recipient among the people and businesses the buyer knows | SPECIFIED | M | NOT TESTED |  | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |  |
| X18-Q12-POST | Courier contract popup like online postage (dropdowns: quantity, item, recipient, location, collect payment, deliver or deposit proceeds, money/item type and amount, route or special) assembled into a readable instruction; recipients from known people and businesses incl. prior trading contacts (owner represents the business; location from world records); fee computed from route type, distance, burden, capacity, stops, return/deposit, labour, notarial service; physical execution; fulfilled only when obligations are done | SPECIFIED | M | NOT TESTED |  | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |  |
| X18-Q13 | Implement Q18-13 signing: small agreements unsigned; formal contracts and ownership transfers signed face to face, or through a courier-notary with legal skill carrying the documents; no remote instant signing; smoke tests for incomplete, rejected, interrupted and completed agreements | PARTIAL | L | NOT TESTED |  | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |  |

## Open, ready (1)

| ID | Requirement | Design | Effort | Verification | Worker / branch | Remaining work | Decisions / depends on |
|---|---|---|---|---|---|---|---|
| X18-SIM | Comparative capability simulations (baseline, conservative, moderate, aggressive; levels 0,2,5,8,10; implemented industries; settlement size, resource and labour scenarios; 30 and 90 days) and a recommendation; no permanent constants before owner review | SPECIFIED | M | NOT TESTED |  |  |  |

## Open, not started (21)

| ID | Requirement | Design | Effort | Verification | Worker / branch | Remaining work | Decisions / depends on |
|---|---|---|---|---|---|---|---|
| DVW-B3-FEAST | Coin sink: wedding feasts and seasonal feasts at the tavern, food and ale really bought and eaten | SPECIFIED | M | NOT TESTED |  |  |  |
| DVW-B3-LUX | Coin sink: luxury imports sold by the caravan for status | SPECIFIED | S | NOT TESTED |  |  |  |
| DVW-B5 | Predictable taxes with hysteresis, announced | SPECIFIED | M | NOT TESTED |  |  |  |
| ECON-P3 | Household vs business money, quotes follow money, stock days, market hire wages, `World.spendable` (:183-187) | SPECIFIED | M | NOT TESTED |  |  |  |
| MIGRATE-18 | Migration both ways between the village and the off-map settlements for work, land, marriage or hunger | SPECIFIED | L | NOT TESTED |  |  | after Q18-7 |
| REL18-DET | Build 18 release gate: Determinism gate re-recorded on Build 18 code (two independent runs identical) | SPECIFIED | S | NOT TESTED |  |  |  |
| REL18-DEVICE | Build 18 release gate: Device and owner playtest of every player-facing Build 18 requirement (the playtest queue) | SPECIFIED | M | NOT TESTED |  |  |  |
| REL18-EXPORT | Build 18 release gate: Android, Windows and Linux packages from one commit and one build number | SPECIFIED | M | NOT TESTED |  |  |  |
| REL18-LONGRUN | Build 18 release gate: Conservation and long runs: one 365-day run per required seed, no ledger leak (SIM-01) | SPECIFIED | M | NOT TESTED |  |  |  |
| REL18-OWNER | Build 18 release gate: The owner's approval to publish a Build 18 distributable (B17-DIR exception carried to Build 18) | SPECIFIED | S | NOT TESTED |  |  |  |
| REL18-SAVE | Build 18 release gate: Save compatibility: a real Build 17 save loads into Build 18, plus migration fixtures | SPECIFIED | S | NOT TESTED |  |  |  |
| REL18-SUITES | Build 18 release gate: All automated suites pass on the final Build 18 integration commit | SPECIFIED | S | NOT TESTED |  |  |  |
| REL18-WIKI | Build 18 release gate: WIKI-01 release gate: new and changed mechanics documented, wiki checks pass | SPECIFIED | S | NOT TESTED |  |  |  |
| SET-D | Settlement expansion phase D: Settlement development: growth and decline, specialization, housing, infrastructure, population and employment | DESIGN WORK REQUIRED | XL | NOT TESTED |  |  | after SET-C |
| STONE-02 | Personal-use stone dressing by any villager (own house or repairs), same rules as the player | OWNER DECISION REQUIRED | S | NOT TESTED |  |  | STONE-D1, STONE-D2, after STONE-01 |
| STONE-03 | Materials by kind of work: major masonry reconstruction in blocks and mixed raw-stone-and-block jobs | OWNER DECISION REQUIRED | S | NOT TESTED |  |  | STONE-D1, after STONE-01, after STONE-Q1 |
| STONE-04 | Skill-based stone dressing efficiency with conserved waste (one rule for player and villagers) | OWNER DECISION REQUIRED | S | NOT TESTED |  |  | STONE-D1, after STONE-01, after STONE-Q2 |
| STONE-06 | Iron chisel: smith-made, worn by use, needed with the mallet to dress stone | OWNER DECISION REQUIRED | S | NOT TESTED |  |  | STONE-D2, after STONE-01, after STONE-Q3 |
| TRADE-CREDIT | Barter and credit with trust: goods-for-goods deals and recorded debts that must be repaid; unpaid debts hurt standing | SPECIFIED | L | NOT TESTED |  |  | after Q18-5 |
| WDR-011-C | Comply with World Design Rule 11: NPC Self-Improvement and Prosperity | DESIGN WORK REQUIRED | L | NOT TESTED |  | Design the five aspiration domains |  |
| X18-STONECUT | Professional stonecutter: an independent trade and business that dresses and sells building blocks | OWNER DECISION REQUIRED | M | NOT TESTED |  |  | STONE-D1, STONE-D2, after PROS-18, after Q18-9 |

## Open, integrated (31)

| ID | Requirement | Design | Effort | Verification | Worker / branch | Remaining work | Decisions / depends on |
|---|---|---|---|---|---|---|---|
| ARMOR-01 | Armour is acquired in play, physical, and visible when worn | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-armour |  |  |
| B14-11 | Animal Farm pack: the horse and farm animals | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  | implement the caravan's plough horse |  |
| BANDIT-RETURN | Outlaws return: a season after the band is wiped out, 2-3 outlaws arrive from outside and camp in the woods | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  | after BANDIT-Q |
| BARBER-01 | Barber service: change hairstyle in the village through the economy | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-tailor |  |  |
| CC-01 | Character creator replaces the eight preset looks (appearance only, civilian) | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-character |  |  |
| CON-UX-01 | Contract window needs design work | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  |  |
| DVW-B8 | Skills for farming, husbandry, hunting, healing | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  |  |
| FARM-CROP-01 | Share a field's crop among its cutters in proportion to their cutting work | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/build18 | Owner: authorize merging into Build 17 now, or carry it to the next build | after FARM-08-Q-CROP |
| FARM-CROP-SEED | Seed kept back from a shared field is split among its cutters by work, as the grain is | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  |  |
| INV-18 | Categorized inventory: eight capacity pools, separate equipment, two upgrade stages | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-inventory |  |  |
| MAP-01 | Map shows where you are beyond the village | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  |  |
| ORE-PLACE-01 | Natural ore evidence and finds kept out of the developed village footprint | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-ore | Build 18 integration gate (determinism re-baseline: clue placement changed) |  |
| ROOMS-18 | Inner doorways between joined house rooms, and the two survey plots relaid onto open ground | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  | after OD-05 |
| SKILL-TRADES-18 | Carpentry, Masonry and Tanning skills, started from each person's Crafting experience; the matching work earns them | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  | after Q18-1 |
| STONE-05 | Stoneworking skill: a distinct skill in the existing skill system that governs stone dressing | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  | after STONE-01, after STONE-Q3, after STONE-04 |
| TAILOR-18 | Tailor: a village NPC service selling the two backpack upgrades | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-tailor |  |  |
| TRADE-AXE-01 | Playtest: cannot buy Clement Ward's axe (listed 45) holding 47 coins | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  |  |
| TRADE-UI-02 | Contract proposal's answer shown in view | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  |  |
| UI-HUD-01 | HUD status panel too large: shrink and move the date line | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-visual |  |  |
| UI-HUNGER-01 | Hunger icon becomes a drumstick | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-visual |  |  |
| UI-PROGRESS-01 | Progress bar visible on light and dark ground | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-visual |  |  |
| UI-WIKI-01 | Village Encyclopedia: navigable, searchable wiki window | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-wiki |  |  |
| VIS-ANIMAL-01 | Stray fragments above animals removed at the source | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-visual |  |  |
| VIS-AXE-01 | Lumberjack axe: believable chop, blade never through the head | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-axe |  |  |
| VIS-CROP-01 | Ripe wheat recognizable; planted, growing, mature, harvested look distinct | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-visual |  |  |
| VIS-DOOR-01 | Doorway transition: characters no longer pass under a closed door | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-visual |  |  |
| VIS-STEPS-01 | Steps cut through rock need real step art | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-polish |  |  |
| VIS-TREE-02 | Tree fragments: no stray old tree pieces; stages and stumps draw correctly | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED | wip/b18-trees |  |  |
| WORLD-LIFE-01 | The countryside is empty of people and animals; its trails lead nowhere yet | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  |  |  |
| X18-CAPCOMP | Capability composition: workforce capability from local experience, effective capability capped by operational facilities | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  | Owner: facility caps, starting experience, thresholds; open: industry for unattributed work (trade at stall, slaughter, hunting, foraging, clearing, fencing, building, manor survey/trial/excavation/tunnel/shoring/backfill/haul), level rounding for modifiers, wages fixed at posting, drop timing on death/emigration | after Q18-11B, after PROS-18 |
| X18-CAPNUM | Capability modifiers: the bounded model (revised_bounded) for six industries, farming as labour efficiency | SPECIFIED | UNKNOWN | INTEGRATION VERIFIED |  | Switch the hook on at reconciliation with X18-CAPCOMP; then one SIM-01 run per required seed with a determinism pair. Open: whole-coin rounding of +4% on the 6-coin harvest wage; whether slaughter, clearing and fencing count as farm tasks | after Q18-11A, after X18-CAPCOMP |

## Complete (1)

| ID | Requirement | Verification | Release |
|---|---|---|---|
| SYNC-17 | Synchronize Expansions 18 and 19 one way with the Build 17 baseline cd7439c | INTEGRATION VERIFIED | NOT READY |

## Open owner decisions (5)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
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

