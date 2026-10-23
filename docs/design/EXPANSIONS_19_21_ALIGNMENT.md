# Expansions 19-21: development alignment report and capability matrices (2026-10-23)

Answers the owner's consolidated design directive (`docs/directives/2026-10-23_expansions_19_21_consolidated_design.md`).
Sources: the Expansion 19 branch (`wip/expansion19-preparation`, the foundations round merged at c756211, `docs/expansion19/DESIGN.md`),
the Expansion 20 audit and contracts (`wip/expansion20-preparation` 4d9bc05, `docs/expansion20/LE00_BUILD18_REFRESH.md`,
`LE01_DATA_CONTRACTS.md`), the Expansion 21 audit (`wip/expansion21-preparation`, `docs/expansion21/P21_READINESS.md`) and the register.
No implementation is authorized by the directive; this report changes no scope.

Classes: **Approved** (owner requirement, not yet built), **Existing** (in the repository and tested; "prospective" = on an isolated
branch, switched off), **Proposed** (not approved), **Blocked** (needs an owner decision or a prerequisite), **Deferred** (not this phase).
Phase codes: X19 rounds; LE-01..07 (Expansion 20 specification s.17); P21-01..03 (P21-03 = the mayoral system, proposed numbering).

## 1. Ownership (directive s.5, confirmed against the code)

| Responsibility | Owner | Where it lives (one copy) |
|---|---|---|
| Personality, beliefs, opinion, trust, gossip, reputation, personal memory | 19 | `JudgmentStore` and its modules (judgment, trust, personality, bonds); Relations keeps regard and courtship |
| Offers, pricing, contracts, debt; goods, money, obligations | 20 | World holders (purses, inventories, tills, treasury), `contracts.gd`, `credit.gd`, and the new reservation and event records; one census |
| Offices, elections, civic authority | 21 | civic records (new, off) over today's `reeve_day`, guards and treasury |
| Taxes, civic wages, public purchasing | 21 decides, 20 executes | today: direct treasury changes in `reeve_day`/`pay_guards`; future: Expansion 20 transactions attributed to an office id |
| Voting | 21 asks, 19 supplies the subjective weights | nothing yet |
| Negotiation | 20 owns the deal, 19 re-weighs willingness | today: six decision hooks (contracts, lending, barter, food seller, family help) through `JudgmentLive` |
| Crime and investigation | existing crime paths (`World.witness`, `guard_confront`, reports) then civic authority | no duplicate |

One brain (`NPCBrain`), one inventory and ledger (World holders, `total_coins`, holdings census), one social memory (`JudgmentStore`),
one political record (civic records). Nothing in the three expansions duplicates these; Expansion 20's actor resolver and reservations
read the World holders, Expansion 21's records read the existing succession paths.

## 2. Expansion 19: Subjective judgment and decision engine

**Status.** Prospective, switched off (`judgment.json` `enabled: false`), on `wip/expansion19-preparation` synced with the released Build 18.
Built and tested: the judgment store with separate Good and Bad ledgers; observer interpretation; trust apart from liking; gossip at the
meeting itself weighted by closeness; per-person temperament; personality framework (traits, wisdom, anger, history; formulas inert);
relationship history, resentment, familiarity and family reputation (reach inert); live event feeds; six decision hooks.
Gate identical with the judgment off at every step.

| Capability | Class | Existing | Missing | Owner subsystem | Depends on | Performance | Open decision | Phase |
|---|---|---|---|---|---|---|---|---|
| Moral judgment (Good/Bad ledgers) | Existing (prospective) | `JudgmentStore` net, ambivalence | live activation | 19 | event feeds | event-driven | Gate E | X19 Gate E |
| Trust and reliability | Existing (prospective) | `store.trust`, 15b events | promises as events (no source in the game) | 19 | 20 contracts | per event | X19-TRUST-RATES | X19 |
| Familiarity, respect, family reputation | Existing (prospective), partly Blocked | bonds module, +10/+5/12% | family reach and transmission | 19 | Life family graph | gain path 4 microseconds | X19-SPILL-REACH, X19-REP-TRANSMIT | X19 |
| Friendship, rivalry, romance | Existing (live, Relations) | regard, attraction, courtship, rivals | rivalry as a judgment outcome is partial | Relations + 19 | | per day | none | done |
| Gossip and propagation | Existing (prospective) | scheduled meetings, closeness, no hop limit | settlement-to-settlement path | 19 | Expansion 18 couriers, migration | 7 ms worst frame at 500 (this machine) | X19-GOSSIP-FLOOR | X19 |
| Deliberate misinformation, investigation, correction | Approved (X19-MISINFO), Blocked | `misattribute_permille` (accidental), `correct()` for proven-false stories | the act of fabricating, who investigates, intent consequences | 19 (+21 investigation) | civic investigation (absent) | per event | who investigates (crime system vs civic office) | X19 next round (fabrication, correction) / P21 (investigation) |
| Story lifetime (generations, fading) | Approved (X19-STORY-LIFE), partly Existing | permanent memories, memory cap and retirement, decay | generational retelling, important vs minor | 19 | Life (children), family reputation | bounded memory 24 a person | what makes a story "important" | X19 next round |
| Forgiveness, reconciliation | Existing (prospective) | resentment softening by growth, trust recovery by reliability | formulas | 19 | personality | dawn, holders only | X19-PERS-FORMULA, X19-DECAY | X19 |
| Personality differences, learning, emotion | Existing (prospective, inert) | traits, wisdom, anger, override; 30% stubbornness | live feeds of mistakes and reminders; decision effect of stubbornness | 19 | | per event | X19-PERS-FORMULA, X19-TRAIT-DIST | X19 |
| Decisions influenced, not dictated | Existing (prospective) | margin selection, live order preserved | more decision points | 19 via shared hooks | 20, 21 decision points | per decision | X19-RUNNERUP | X19 / LE-02 |
| Integration breadth (trade, work, credit, family, crime, politics, business, bandits, assistance, migration, settlements, history) | Approved | trade, credit, contracts, family help, food seller wired | employment, crime, elections, bandits, migration, settlements, history | 19 via hooks | 20 offers, 21 elections | | none blocking | after Gate E, per system |

**Major missing:** live activation (Gate E: owner numbers, decay rate, calibration runs); fabrication and investigation; generational
stories; hooks into employment, crime, migration and elections. **Reusable:** the store, event feeds, `JudgmentLive` hook pattern,
determinism and save sections. **Genuine blockers:** the owner's numbers (five bundles plus decay) block Gate E; nothing blocks the
next round of approved mechanics (fabrication and correction, story lifetime) except "who investigates", which needs Expansion 21.

## 3. Expansion 20: Living economy

**Status.** Phase 1 authorized. LE-00 refreshed against Build 18; foundation built and off (`economy.json enabled: false`): reservation
record, economic event record, actor resolver (66 checks, gate identical). Pricing, breach and credit terms now partly answered
(OD-LE-02, 13, 05).

| Capability | Class | Existing | Missing | Owner subsystem | Depends on | Performance | Open decision | Phase |
|---|---|---|---|---|---|---|---|---|
| Individual supply and demand (needs) | Approved | `necessity`, household evaluation, `wants`, need rates | a Need record with urgency and deadline | 20 over NPCBrain | | event triggers, not scans | none (spec s.4) | LE-01 |
| Combined market pricing | Approved (OD-LE-02) | local-availability prices, `_market_price` cache | asks from supply, demand, scarcity and past deals; a transaction record | 20 | event record | hour cache, local indexes | none | LE-02 |
| Negotiation (limited counteroffers, willingness) | Approved (OD-LE-02) | contracts negotiate; credit asks | bids and counteroffers in ordinary trade | 20, 19 re-weighs | 19 personality (inert) | bounded rounds | none | LE-02 |
| Offer visibility | Blocked | stall prices, contracts | the rule | 20 | | | OD-LE-02B | LE-01 |
| Knowledge (bounded) | Blocked | contacts, note_trade, memory | source, age, confidence | 20 with 19's channel | 19 gossip | one channel | OD-LE-10 | LE-01 |
| Production and supply chains | Existing (live) | recipes, return-ordered crafting, manor orders | input reservations for accepted orders | 20 | reservations (built) | | none | LE-03 |
| Business ownership and operation | Existing in part | stalls, shops, tills (ECON-P3), player workshop | business identity, several businesses under one owner, managers | 20 | | | OD-LE-04, OD-LE-07 | LE-03 |
| Hiring, labour market, wages | Existing in part | job market, hiring competition, experience (Expansion 18) | employer offers, side work, retraining | 20 | Expansion 18 capability | | OD-LE-03 | LE-03 |
| Competition, growth, insolvency | Existing in part | stall relocation, failing merchants give up | expansion, downsizing, closure with debts | 20 | credit | | OD-LE-04 | LE-03/04 |
| Contracts with breach and renegotiation | Approved (OD-LE-13) | CON-01/02, OD-29 defaults | partial delivery, extension, changed terms | 20 | reservations | | OD-LE-13B (death) | LE-02/04 |
| Credit, installments, goods, collateral | Approved (OD-LE-05) | `credit.gd` debts, no interest | installments, payment in goods, pledged collateral, surplus return | 20 | reservations, actor | | OD-LE-05B (interest, lenders) | LE-04 |
| Household finances | Existing in part | reserve, family tab, business draws | budgets over competing uses | 20 | | | OD-LE-12 | LE-03 |
| Trade, transport, regional | Existing (live) | five settlements' traders, couriers, carts | knowledge-bounded traders, freight decisions | 20 | Expansion 18 | hourly steps | OD-LE-09 | LE-05 |
| Conservation (no creation or loss) | Existing | `total_coins`, census, off-map audits, FATAL checks | reservations and events reconciled (built, off) | 20 | | | none | done/LE-01 |
| Government purchasing | Approved (directive s.5) | manor orders, granary buying | 21 initiating through 20 transactions | 20 executes | 21 | | OD-LE-06 | LE-04 with P21 |
| Bandits and stolen goods | Existing in part | bandit market, loot recovery | hoarding, fencing, custody vs ownership | 20 | | | OD-LE-09 | LE-05 |
| Speculation, manipulation | Blocked | none | | 20 | | | OD-LE-11 | LE-02+ |
| Performance budgets | Blocked | profiler, gate | budgets | all | | O(n^2) dawn food search, unpruned logs (E20-RISK-QUEUES) | OD-LE-15 | LE-01/06 |

**Major missing:** Need, Offer and Knowledge records; negotiation in ordinary trade; business identity; installments and collateral.
**Reusable:** World holders and census, contracts, credit, tills, settlements, the three new foundation records. **Genuine blockers:**
OD-LE-02B (visibility) and OD-LE-10 (knowledge) block the LE-01 Offer and Knowledge records; OD-LE-04/07 block business identity;
OD-LE-15 the budgets. The Need record and the approved pricing and negotiation model are not blocked by a decision, only by the
owner's approval of the architecture before integration (directive phase-1 s.13).

## 4. Expansion 21: Politics and civic authority

**Status.** Phase 1 authorized. Audit and decision map done; civic records (office registry, tenure and succession, legacy) being built,
off (`civic.json enabled: false`). Mayoral structure approved today.

| Capability | Class | Existing | Missing | Owner subsystem | Depends on | Performance | Open decision | Phase |
|---|---|---|---|---|---|---|---|---|
| Civic offices and duties | Existing in part | reeve (`reeve_day`), six guards, sage | office records (in progress), a mayor's duties | 21 | civic records | daily | P21-STRUCTURE | P21-01, P21-03 |
| Elected mayor, 4-year terms, re-election, vacancy rule | Approved (P21-MAYOR) | none | election record, calendar of elections, interim authority | 21 | civic records, Life ages | yearly event | P21-RESIDENCY | P21-03 |
| Voter evaluation (policies, competence, interests, trust, family) | Approved (P21-MAYOR, Rule 019) | none | the voter model | 21 asks, 19 supplies | Expansion 19 live (Gate E) | voters x candidates once a term | Q-POL-4 secrecy, Q-POL-5 ties | P21-03 (after X19 Gate E) |
| Candidates, campaigning, promises, approval | Essential: candidacy and a stated platform; Proposed: campaigning, promises, approval, factions | none | | 21 | 19, 20 interests | | which are wanted | P21-03 minimal, rest Deferred |
| Treasury, taxes, fees, fines | Existing | `World.treasury`, `TaxPolicy` bands, rents, fees, theft fines | taxing authority of an elected mayor | 21 decides, 20 executes | 20 transactions | daily | Q-POL-9 | P21-04 |
| Public spending, payroll, works | Existing in part | `reeve_day` fixed order, `pay_guards` | priorities chosen by an official | 21 | 20 | daily | spending priorities | P21-04 |
| Guards with real duties | Existing in part | shifts, patrol, fight, recover loot, funded by treasury | investigation, captain, equipment budget | 21 + crime paths | | per guard decision | guard command | P21-05 |
| Courts, judgments, punishments | Absent | fines for the player's theft only | all | crime system + 21 | | | legal procedure (owner) | Deferred |
| Corruption and abuse | Proposed | none | | 21 | 20 ledger | | whether wanted | Deferred |
| Noble or manor authority vs local government | Blocked | a manor with no lord | | 21 | | | P21-STRUCTURE | P21-03 |
| Political history and careers | Existing in part (in progress) | legacy record (in progress) | accomplishments, generational careers | 21 | civic records, graves (WDR-014-C) | event-driven | none | P21-01 |
| Player participation | Approved in principle (Rule 015) | none | | 21 | | | what the player may hold | P21-03 |

**Essential to the approved mayoral system:** an office record and tenure (in progress), an election calendar on the 8-day year
(four years = 32 game days), candidacy from the voter roll, a voter model reading Expansion 19 and household interest, ballots counted
and recorded, the interim rule, and the mayor's duties mapped onto today's reeve evening business. **Separate authorization needed:**
campaigning beyond a platform, promises and their tracking, approval ratings, factions, corruption, courts.

**Major missing:** elections and the voter model; the mayor's powers; investigation and courts. **Reusable:** treasury, tax bands,
`reeve_day`, guard paths, vacancy succession, Life ages and family, the civic records. **Genuine blockers:** P21-STRUCTURE (does the
mayor replace the reeve, sit beside a manor lord, or answer to one) and P21-RESIDENCY block the election record; the voter model
needs Expansion 19's Gate E.

## 5. Cross-expansion dependencies

- 21 voting needs 19 live (Gate E) and 20's household interests (what a policy does to a household's money).
- 21 taxes, payroll and purchasing need 20's transaction record attributed to 21's office ids (both foundations exist, off).
- 20 negotiation willingness and credit risk read 19's trust (hooks exist); 20's Knowledge rides 19's gossip channel (OD-LE-10).
- 19 misinformation investigation needs a civic investigator (21) or the guards (existing crime paths).
- All three share one event-driven, deterministic, sparse design, measured at 500 villagers.

## 6. Recommended next phase per expansion

- **19:** the approved next round within PROS-19 scope: deliberate fabrication and the proven-false correction (X19-MISINFO) and story
  lifetime (X19-STORY-LIFE); then Gate E once the owner's numbers are in.
- **20:** with the owner's approval of the architecture: the LE-01 Need record and the Offer and transaction records shaped by the
  approved combined pricing and negotiation (visibility pending OD-LE-02B).
- **21:** finish P21-01; then design (not build) the election record and calendar against P21-MAYOR, ready for the owner's structure answer.
