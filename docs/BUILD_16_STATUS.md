# Build 16 status audit

The owner's request of 2026-10-20 (register B16-AUDIT, `docs/directives/2026-10-20_build16_seeds_merchants_counters_status.md`):
where Build 16 stands, what is finished, what is left, what blocks completion, and how much has been added to its scope.
**The inventory tables are generated from the requirements register** (`python3 tools/build_status.py --write`; never
hand-edited); the sections around them are kept by hand and updated as work completes. A status is taken from the
register only: nothing is called complete because code was written or a design approved.

*Last updated: 2026-10-21, staging (see the commit that last changed this file).*

## F. Executive summary

*Reconciled 2026-10-21 on `02ae508` for the owner's audit request (`docs/directives/2026-10-21_build16_audit_release_readiness.md`);
the readiness answer is section R below.*

| | |
|---|---|
| Build 16 items | **105** register entries (30 when Build 16 began at the Build 15 release `a8760be`, 2026-10-20 12:33 UTC; **77 added since** by owner directives); 2 moved out by the owner (DVW-A12 to Build 17, DVW-B6 to Build 18) |
| Complete and verified | **41** |
| Implemented, awaiting testing | **21** (17 awaiting runs or owner readings; 4 awaiting a device playtest: ARM-01, CTR-01..03) |
| In progress | **17** (7 active, 10 partially implemented) |
| Not started | **22** (family farms FARM-01..05/07, stalls STALL-01..06, FSE-14/15, EQ-01/03/04/09, DVW-A5, REC-001, SJD-A, TIME-03) |
| Blocked | **2** (B7-016 pending a re-measure; OD-17, an owner decision) |
| Superseded | 2 (FSE-11 by FARM-06; OD-10) |
| Open release blockers | **1**: ARM-01, implemented and tested by suites (`4bfc81b`), awaiting the owner's device playtest. FSE-B06, B11 and B12 are closed (COMPLETE AND VERIFIED on the `62b7488` runs) |
| Branch and latest verified commit | `staging/my-medieval-life`, `02ae508` (pushed, remote hash checked; local and remote equal) |
| Test suites | All 27 Godot suites pass on `02ae508`; Python tests OK; register, interactions, resources: 0 problems |
| Determinism | The gate passes on `02ae508`, identical to its baseline (no coin or goods leaks) |
| Normal game, 365 days | Last four-seed run of the normal game (switches off): `62b7488`, starvation 0/0/0/0, 0 script errors, ledgers balanced. Code since then (SHOP-01/TRADE-01/CTR-04 `51fd1e5`, FARM-08A `49c530a`) has suites and the gate only; the four-seed run of `02ae508` is the control variant of Actions run 39598992347 (queued) |
| Farming switches | `shared_manor_farming` 0 and `seasonal_village_farming` 0 in `game/data/balance.json`: both off in normal play |

**Completion percentage.** By count, 41 of the 103 Build 16 items that are not superseded are complete and verified:
**40 %**. Every item counts the same, which they are not; most of the open effort is in a few large systems not started
(family farms, market stalls) and in the acceptance runs (EQ-01..06, EQ-16).

### Essential for stabilization versus a later milestone (no deferral without the owner)

- **Stabilization-essential** (the village must hold up on its own; these protect the baseline): the release blockers;
  the pending-testing items (relief, the family chest, families and orphans, grazing); the equilibrium acceptance runs
  (EQ-01..06, EQ-16, WDR-005-C, SJD-A Gate A); the remaining food-security defects; TIME-02 (no behaviour change).
- **New features the owner placed in Build 16 that a later milestone could take, if the owner chooses** (each is a
  substantial system): family farms (FARM-01..07), market stalls (STALL-01..06), skilled-trade counters and shopkeepers
  (CTR-01..04, SHOP-01, TRADE-01), seed propagation and the seed merchant (SEED-02..04, MERCH-01), seasonal village
  farming (FSE-13) and the shared farming model (FSE-12). They are approved for Build 16 and **are not deferred**; the
  owner may choose to move some to their own milestone so the next playable build is not held back.
- **Already outside Build 16, and kept there** (MILE-01): the goal-driven living economy (FSE-10, with EXP-D, the
  standalone Living Economy build) and the NPC Judgment system (Build 19).

## R. Release readiness and the audit of 2026-10-21

The owner's request (`docs/directives/2026-10-21_build16_audit_release_readiness.md`): why there is no playable Build 16,
what is finished, what blocks a private build. Facts as of `02ae508`.

**Why there is no Build 16.** No technical cause: no test fails, nothing in the export pipeline changed since the Build 15
release (the last `release.yml` run, Build 15 on `a8760be`, succeeded; `release.yml`, `export_presets.cfg` and
`project.godot` are unchanged since), and no defect is known that breaks the normal game. The causes are process:

1. **The build gate was "Build 16 complete".** OVN-01 section 4 counts a build complete only when its mandatory approved
   requirements are implemented, and REL-15-18 authorizes Build 16 as a private draft when it meets that; OD-25 (2026-10-21)
   then required explicit owner authorization for any release. No interim "development candidate" milestone existed,
   and the agent did not propose one. That is the main reason.
2. **The scope tripled while the work went on.** Build 16 began with 30 items; owner directives added 77 in the next 24
   hours (food security 26, parity 10, farms 11, stalls 6, counters and trade 6, seeds 5, time 4, others 9). Each new
   directive moved the gate.
3. **Most of the time went into the food-security work and its verification.** Starvation deaths (31 after parity on
   2026-10-20) were driven to 0 on four seeds through six fix-then-run cycles (B7-015, FSE-16/17/18, FSE-B06/B11/B12), each
   needing a 365-day four-seed run of about 40 minutes. Then the owner-ordered comparisons (FSE-12, FSE-13, FARM-08 and
   the cattle investigation) of systems that are switched off in the normal game.

**Two milestones.**

- **A. A private development candidate** (installable, for playtesting the current work; limitations stated). Needs:
  the four-seed 365-day run of the current staging with both switches off (the control jobs of Actions run 39598992347),
  0 script errors and balanced ledgers on all four; the owner's authorization; then `release.yml` as a private draft,
  with artifacts checked against the tested commit. Nothing else: no open owner decision blocks it. Readiness today:
  **not yet verified** (the normal game's code changed after the last four-seed run: SHOP-01/TRADE-01/CTR-04 and the
  FARM-08A fix, which have suites and the determinism gate only).
- **B. Build 16 complete** (the full approved scope): the 62 open items, of which the largest are family farms
  (FARM-01..05, 07), market stalls (STALL-01..06, waiting on audit questions 8-13), the acceptance runs (EQ-01..06, EQ-16),
  the activation decisions for FSE-12/FSE-13 (the FARM-08 yield and the cattle investigation, FARM-08B), the device
  playtest of the counters (ARM-01, CTR-01..03), and the readings items 5-7 and 14-22 for the owner to confirm.

**Known limitations a development candidate would carry:** the shared and seasonal farming switches off; no family
farms or built stalls; one counter (the armoury); the Android build signed with a throwaway key (the stable test key's
secrets do not exist), so Build 15 must be uninstalled first; save version 15 (a Build 15 save, version 14, is migrated
by Skills.seed_villagers; checked 2026-10-21 against a real save written by the Build 15 code `a8760be`: it passes SaveStore's check, loads, migrates (villagers get their skills), runs four game days with no script error and the same outcome as a new world of the same seed, and saves again as version 15).

## Inventory (generated)

<!-- b16:start (generated by tools/build_status.py --write) -->

**109 Build 16 items in the register** (30 when Build 16 began at the Build 15 release `a8760be`; **81 added since**).

| Status | Items |
|---|---|
| Complete | 73 |
| In progress | 9 |
| Pending testing | 22 |
| Not started | 1 |
| Blocked | 2 |
| Deferred | 0 |
| Superseded | 2 |

| Completion class | Items |
|---|---|
| Release blocker | 4 |
| Required feature | 51 |
| Testing and verification | 18 |
| Optional | 1 |
| Owner decision | 1 |
| Done | 31 |
| Superseded | 2 |
| Unclassified | 1 |

Added since Build 16 began, by family: AGENT 1, ARM 1, B16 2, CTR 4, EQ 1, FARM 12, FSE 26, MERCH 1, MILE 1, OD 4, PAR 10, PICK 1, SEED 4, SHOP 1, STALL 6, TIME 4, TRADE 1, TREAS 1.

### Other

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| AGENT-01 | Controlled parallel development: at most two subagents at once (three agents with the lead), bounded tasks, no nested agents, only the lead  | Complete | docs/directives/2026-10-20_controlled_parallel_development.md |  | `7e0d9c6` |  |  | Done |  |
| MILE-01 | Milestone assignments are respected: nothing moves into Build 16 from the expansions (the Living Economy build, Build 19's NPC Judgment) wit | Complete | docs/directives/2026-10-20_controlled_parallel_development.md |  | `7e0d9c6` |  |  | Done |  |
| TREAS-01 | The manor treasury as the village reserve: fees in, real purchases out, relief from owned stock | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `1de1bcc`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | M |

### Counters, shopkeepers and trade

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| ARM-01 | Armorer availability: verify the armorer exists, keeps a schedule, a place, stock, a path, and trades with the player (the owner's playtest: | Pending testing | The armoury counter (s8) now works: ring for service, a smith walks over by the ordinary path and serves through the trade window; told why when nobody can come; world_test::_ctr01_counters; all 27 suites pass, gate iden | Owner playtest at the armoury counter; armour stock follows SHOP-01 | `4bfc81b`, world_test::_ctr01_counters |  |  | Release blocker | M |
| CTR-01 | Skilled-trade sales counters: every established skilled business (armorer, smith, carpenter, others as they develop) has a working customer  | Pending testing | Counters (core/counters.gd): one mechanism for skilled-trade counters, first the armoury counter kept by the smiths; ring, the keeper walks over, serves, stays while the player stays, returns to work; unavailable reasons | Device playtest; more counters (carpenter, sage) need counter stations in their buildings (a village-generator change: generator version bump) | `4bfc81b`, world_test::_ctr01_counters |  |  | Required feature | L |
| CTR-02 | At a counter: a prompt, press A, and the business's available shopkeeper walks to the counter to serve | Pending testing | Counters (core/counters.gd): one mechanism for skilled-trade counters, first the armoury counter kept by the smiths; ring, the keeper walks over, serves, stays while the player stays, returns to work; unavailable reasons | Device playtest; more counters (carpenter, sage) need counter stations in their buildings (a village-generator change: generator version bump) | `4bfc81b`, world_test::_ctr01_counters | after CTR-01 |  | Required feature | M |
| CTR-03 | Shopkeeper availability: ordinary villagers with schedules; when summoned an available one comes, else the player is told clearly; employees | Pending testing | Counters (core/counters.gd): one mechanism for skilled-trade counters, first the armoury counter kept by the smiths; ring, the keeper walks over, serves, stays while the player stays, returns to work; unavailable reasons | Device playtest; more counters (carpenter, sage) need counter stations in their buildings (a village-generator change: generator version bump) | `4bfc81b`, world_test::_ctr01_counters | after CTR-02 |  | Required feature | M |
| CTR-04 | Permanent counters are not market stalls: no stall commission on counters without an approved rule | Complete | A sale and a purchase at the armoury counter move exactly the quoted price between the player and the smith; treasury and total coins unchanged; no commission on counters |  | `f56e9bb`, world_test::_ctr04_counter_terms | after CTR-01 |  | Required feature | S |
| SHOP-01 | Skilled businesses sell what they produce or stock and buy useful goods by real need and funds (a carpenter buys timber, an armorer material | Pending testing | Businesses buy only inputs of recipes they have the skill for, up to their stock limit, partial lots towards a batch, within coins and the OD-19 reserve; one sale rule for the player and villagers with refusal reasons; w | Measure in the next four-seed runs; owner to set a stocking horizon and confirm the readings | `f56e9bb`, world_test::_shop01_need |  |  | Required feature | M |
| TRADE-01 | Trade-specific purchasing at counters through the shared trade rules (OD-19 reserve, PAR-02) | Pending testing | Businesses buy only inputs of recipes they have the skill for, up to their stock limit, partial lots towards a batch, within coins and the OD-19 reserve; one sale rule for the player and villagers with refusal reasons; w | Measure in the next four-seed runs; owner to set a stocking horizon and confirm the readings | `f56e9bb`, world_test::_shop01_need | after SHOP-01 |  | Required feature | S |

### Status audit

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| B16-AUDIT | Build 16 complete status audit, maintained (docs/BUILD_16_STATUS.md) | In progress | Roadmap target | docs/BUILD_16_STATUS.md: every Build 16 item with status, implementation, remaining work, evidence, blockers, owner input, and whether it blocks completion; open owner decisions; completion criteria; execution plan; exec |  |  |  | Required feature | S |
| B16-READY | Build 16 development audit and release-readiness report | In progress | Report being delivered | The report answers sections 1-15 with evidence; docs/BUILD_16_STATUS.md and the state file are reconciled; verified work is in staging; no build is made or published without the owner's approval |  |  |  | Required feature | S |

### Economy defects

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| B7-015 | Missed meals while food piles up | Complete | (B7_ISSUES:58) / "Diagnosed; needs a design decision" / AWAIT-OWNER (recorded) / Partial code: guards provision households (INT-072), `87b3663` / Owner decision / Register not updated with INT-072 |  | `9db091b`, Actions 39523615798, 39529507848; suites |  |  | Testing and verification | S |
| B7-016 | Tanners/goods merchants end at 0 coins | Blocked | (B7_ISSUES:59) / "Diagnosed; proposal P3 awaits owner" / AWAIT-OWNER (recorded) / Partial code: goods merchant retails smith tools, woodcutter sells firewood (INT-073), `9c13794` / Owner P3 / Register not updated | As recorded in the source document; evidence named in implementation and tests |  |  |  | Testing and verification | M |

### Audits and measurements

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| DVW-A3 | Re-measure money supply, 100 and 365 days, 2-3 seeds, no player (:28) | In progress | Plan; "LONG_RUN_SIMULATION.md dates from Build 7" / No newer run in docs; newest published year-long runs are on `79ffeb7` and `f836aca` / NOT-STARTED | measured by the Build 15 runs (docs/release/LONG_RUN_SIMULATION.md): coins grow from about 2900 to about 6000 in 100 days with the 30-coin caravan; finish with the 365-day results |  |  |  | Testing and verification | S |
| DVW-A5 | Exploit-player test (arbitrage, round trips, cornering, flooding) (:30) | Complete | VERIFIED analysis: profit from Trading 4, ~35% at Trading 10; **owner question: is honest arbitrage intended?** / No arbitrage/exploit test in `game/tests` / NOT-STARTED (+ AWAIT-OWNER on intent) |  | `1dd89fa`, exploit_test (36 checks); 30 suites; gate identical |  |  | Required feature | M |
| DVW-A7 | Over-production from raising skills by use (:32) | Complete | NOT VERIFIED / none / NOT-STARTED |  | world_test.gd _player_gain |  |  | Done |  |
| DVW-A8 | Audit player-only perks vs same rules (:33) | Complete | NOT VERIFIED (saplings, overworld gathering, fireball) / none; MID_AUDIT:255 and BUILD_DECISIONS:19 note NPCs ignore skill levels for crafting / NOT-STARTED |  |  |  |  | Done |  |

### Equilibrium and acceptance

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| EQ-01 | Human civilization sustains itself without the player | Complete | The world sustains itself without the player for 365 days (about 45 calendar years) on four seeds: food produced and distributed, families and births, houses built, posts filled, stone supplied (no site given up for ston |  | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), st | after B14R-12 |  | Testing and verification | L |
| EQ-02 | Nature sustains itself: reproduction, aging, predation, competition, dispersal, habitat, local extinction, recolonization, recovery | Complete | The world sustains itself without the player for 365 days (about 45 calendar years) on four seeds: food produced and distributed, families and births, houses built, posts filled, stone supplied (no site given up for ston |  | `b15208a`, Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers ba | after WR-01 |  | Testing and verification | M |
| EQ-03 | Humans and nature affect each other through real NPC decisions | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `152ffa2`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | M |
| EQ-04 | A functioning society survives individual losses (succession of trades, households, leadership, businesses) | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `1e88118`, `89ee852`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 s |  |  | Testing and verification | M |
| EQ-05 | The player is the disruptive variable: no hidden protection of the world from player consequences | In progress | EQ-06 scenarios show the player's disruptions have real consequences (dearer food after a wheat corner, timber short after the smiths die) and the village adapts without hidden protection; DVW-A5's profit measurement rem | The world simulates independently of the player; Player disruption and restoration both possible through real systems; No secret protections |  |  |  | Required feature | M |
| EQ-06 | Build 16 acceptance simulations: multi-seed, player inactive, 100 and 365 days and generations, plus player-intervention scenarios | Complete | Multi-seed inactive-player runs reproducible and recorded; no spiral into extinction, starvation, unemployment or paralysis; the intervention scenarios change the results |  | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), st | after EQ-01; after EQ-02; after EQ-03; after EQ-04; after EQ-05 |  | Required feature | M |
| EQ-09 | Local stone deposits run out (day 160-190 in the Build 15 runs); verify that the owner-approved caravan stone (20 a visit once 10 or less re | Complete | The world sustains itself without the player for 365 days (about 45 calendar years) on four seeds: food produced and distributed, families and births, houses built, posts filled, stone supplied (no site given up for ston |  | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), st |  |  | Testing and verification | S |
| EQ-16 | World equilibrium: an untouched world stays viable across generations; the player is the disruptive variable | Complete | Every child EQ-01..EQ-07 complete and verified |  | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), st | after EQ-01; after EQ-02; after EQ-03; after EQ-04; after EQ-05; after EQ-06; after EQ-07 |  | Required feature | L |
| EQ-22 | Caravan buying order: smiths first starves the hide and leather chain after parity | Pending testing | The caravan buys one unit at a time from the line with the highest need (the seller's surplus share plus the share of its missing inputs' cost its coins cannot pay); no fixed order, no equal split; deterministic; od16_te | Owner to confirm the reading of need (the seller's need to sell); measure in the four-seed runs | `5cce264`, od16_test::test_caravan_buys_by_need |  |  | Required feature | M |
| WDR-005-C | Comply with World Design Rule 5: Living World Independence | Complete | Villagers live, work, trade and age without the player; 0 houses built in 365 days (B14R-12) |  | Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers balanced), st |  |  | Testing and verification | M |

### Families and orphans

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| FAM-02 | Both parents dead: dependent children never found households or start construction; an existing household takes them in | Pending testing | implemented in game/scripts/core/guardianship.gd (called each dawn from Life.dawn), tested in game/tests/family_test.gd (22 checks); a long run and CI still to confirm | No child founds a household, hires, buys or builds; Orphaned children move into a receiving household as dependants; Guardianship order (OD-11, owner 2026-10-20): surviving parent, living grandparents, nearest eligible b | game/tests/family_test.gd |  |  | Testing and verification | S |
| FAM-03 | Informal adoption order: living grandparents (both sides), then the nearest eligible blood relative by genealogy, then another villager's ho | Pending testing | implemented in game/scripts/core/guardianship.gd (called each dawn from Life.dawn), tested in game/tests/family_test.gd (22 checks); a long run and CI still to confirm | Grandparents first; a closer eligible relative always before a more distant one; then any suitable household; Tests for each tier; Among equally close eligible relatives (OD-12, owner 2026-10-20): prefer ability to provi | game/tests/family_test.gd | after FAM-02 |  | Testing and verification | S |
| FAM-04 | Integration: the child becomes a dependant of the receiving household and uses its house; genealogy (mother, father, birth family) is never  | Pending testing | implemented in game/scripts/core/guardianship.gd (called each dawn from Life.dawn), tested in game/tests/family_test.gd (22 checks); a long run and CI still to confirm | Birth parents and birth surname stay recorded after a move and a surname change; Test: genealogy survives transfer and surname change | game/tests/family_test.gd | after FAM-02 |  | Testing and verification | S |
| FAM-05 | Occupancy after a child is taken in is recalculated; any housing need it creates belongs to the receiving household's responsible adult; no  | Pending testing | implemented in game/scripts/core/guardianship.gd (called each dawn from Life.dawn), tested in game/tests/family_test.gd (22 checks); a long run and CI still to confirm | Test: the receiving household's crowding and housing need update; no automatic house | game/tests/family_test.gd | after FAM-02; after HOUSE-03 |  | Testing and verification | S |
| FAM-06 | Family scenario tests: the eight family scenarios of the directive, written when the mechanics are implemented | Pending testing | the eight scenarios have tests: father dies and mother dies (housing_test.gd, FAM-01); grandparents, nearest relative, another villager, genealogy and surname, orphans do not build, occupancy and no automatic house (fami | Each of the eight scenarios has a passing test before FAM-02..05 close | game/tests/family_test.gd; game/tests/housing_test.gd | after FAM-02 |  | Testing and verification | S |
| FAM-07 | Unplaced orphans join the bandit clan (OD-11): after surviving parent, grandparents, nearest eligible blood relative and a willing villager  | Pending testing | coming of age per the owner's clarification: Guardianship.leave_camp places the young adult with kin or a household with room (as an adult without a trade), else they stay with the band; family_test 34 checks | suites; then COMPLETE once a long run has exercised it or tests suffice | game/tests/family_test.gd test_nobody_can_take | after FAM-02; after FAM-03; after WDR-016-C |  | Testing and verification | S |
| REC-001 | Adoption and orphan guardianship (NPCs and the player) | Complete | Not implemented. The only mention in code is a comment in game/scripts/core/npc_brain.gd:2137 ('marriage, births and adoption will call it too'); no adopt/orphan/guardian logic in game/scripts. docs/BUILD_DECISIONS.md 'K |  | `04a8eb9`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | M |

### Family farms and leases

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| FARM-01 | Farmland plots: any household (player or villager) leases a small plot through the existing lease framework at 2 coins, registered so no one | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `3fd88ae`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | M |
| FARM-02 | Developing farmland: clear trees and obstructions, then build a fence and gate from logs and stone through the normal construction system | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `3fd88ae`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | L |
| FARM-03 | Ploughing and sowing a family plot with real seed by the established farming mechanics (one model for player and villagers) | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `3fd88ae`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | L |
| FARM-04 | Household participation: family members work the plot by age, ability, skill and time; no farmer occupation required | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `3fd88ae`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | M |
| FARM-05 | Whether a household takes up a plot: from its circumstances, needs, skills, resources and opportunities (no quota, no forced farming) | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `3fd88ae`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | L |
| FARM-06 | Manor fields need seed and labour like any farm (no free seed, crops or materials) | In progress | Manor fields take real seed under the FSE-12 switch (off until the owner reviews the comparison) | Activated with FSE-12 after the owner's review | `68a3611`, world_test::_fse12_shared_fields |  |  | Required feature | M |
| FARM-07 | The farmland lease's recurring charge: 2 coins under the existing weekly lease framework (first week at once), ambiguity reported to the own | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `3fd88ae`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | S |
| FARM-08 | Shared-yield comparison: the per-cell model and seasonal farming together at several yields (0.9-3 a cell), identical seeds; grain produced/ | In progress | Worker C report integrated | Report written (docs/design/FARM08_YIELD_COMPARISON.md, provisional 2.0 a cell); 365-day variants on the integrated commit, then the owner's decision; switches stay off |  | after FSE-12; after FSE-13 |  | Required feature | M |
| FARM-08A | No script error when a homeless household's couple or founder looks for a building site | Complete | Actions run 39595792732 on 98d2b27 (the fix): seeds 1-4 at shared_wheat_yield 2.5 with both switches on, 365 days, all four jobs passed (0 script errors, ledgers balanced), seed 2 being the case that crashed |  | `49c530a`, aging_test; Actions 39595792732 |  |  | Required feature | S |
| FARM-08B | Cattle decline under the shared and seasonal farming model: investigation | Pending testing | Three defects fixed (whole-lot feed buying, grain locked in chests, elderly kept as breeding stock); remaining loss legitimate (keeper cannot afford feed between seasonal harvests); nine answers in FARM08_YIELD_COMPARISO | Report, per seed over 365 days: starting cattle; births and deaths; causes and timing of deaths; feed available against feed eaten; whether cattle can reach their feed; seasonal and winter effects; breeding eligibility a | `463861a`, herd_test (19 checks, 10 fail on the old code); 40/120-day local runs |  |  | Required feature | S |
| FARM-08C | Wheat price floor: record as an economic finding | Complete | Recorded in docs/design/FARM08_YIELD_COMPARISON.md: the asking price cannot fall below 0.8 of value (wheat 2); 2-4 range; any seller with 14+ asks 2; no pricing change |  | `463861a` |  |  | Required feature | S |
| FARM-09 | Farmland placement by drag: two green corners, live price at screen centre, lease or buy, confirm | Pending testing | Drag placement with live lease and purchase price; device check (touch, physical pad) needed | The house-plot placement flow adapted: first corner, drag, rectangle grows and shrinks, validity preview, live lease and purchase price (Property.land_price and rent_of by area), confirm; insufficient funds refuse; no ov | `a36a0ab`, farm_place_test (25 checks; mouse, touch, keys/pad); xvfb screenshots |  |  | Required feature | M |

### Food security, relief, family chest

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| FSE-00 | Food security, household production, land use, markets and goal-driven economic behavior (final master directive) | In progress | Roadmap target: the directive's audit and Build 16 foundations (section 18) | Deliverables 1-7 of section 19 delivered (FSE-01..07); Findings classified A existing / B defects / C Build 16 foundations / D future living-economy features (section 18); Section 17's 25 tests planned, and those for imp |  | after PAR-00; after OD-19; after PAR-02A |  | Required feature | XL |
| FSE-01 | Current-system audit: agriculture, consumption, hunting, husbandry, land and commerce | Complete | docs/design/FOOD_SECURITY_AUDIT.md |  | `ee589c7` |  |  | Done |  |
| FSE-02 | Food sustainability calculation: food and productive land per villager, household and village | Complete | docs/design/FOOD_SECURITY_AUDIT.md |  | `ee589c7` |  |  | Done |  |
| FSE-03 | Gap analysis: agriculture, husbandry, hunting, rental, commerce and AI behavior | Complete | docs/design/FOOD_SECURITY_AUDIT.md |  | `ee589c7` |  |  | Done |  |
| FSE-04 | Cross-system dependency map for the food and living economy | Complete | docs/design/FOOD_SECURITY_AUDIT.md |  | `ee589c7` |  |  | Done |  |
| FSE-05 | Implementation roadmap: Build 16 foundations vs the living-economy build | Complete | docs/design/FOOD_SECURITY_AUDIT.md |  | `ee589c7` |  |  | Done |  |
| FSE-06 | Testing strategy for the food and living economy | Complete | docs/design/FOOD_SECURITY_AUDIT.md |  | `ee589c7` |  |  | Done |  |
| FSE-07 | Unresolved owner questions arising from the food-security directive | Complete | docs/design/FOOD_SECURITY_AUDIT.md |  | `ee589c7` |  |  | Done |  |
| FSE-08 | The directive's 25 deterministic tests (section 17) | Complete | All 25 mapped: 17 to tests (2, 6, 7, 18 now by farm_plots_test and stalls_test), 8 to the Living Economy build |  | `268895c`, docs/design/FSE08_TEST_MAP.md; farm_plots_test, stalls_test |  |  | Required feature | M |
| FSE-09 | Build 16 food-security defects and foundations (classes B and C) | Complete | Every class B defect closed (FSE-B05..B12); class C foundations done (FSE-17, cooking parity, TIME-02, FSE-14) |  | `268895c` |  |  | Required feature | M |
| FSE-11 | Village sowing consumes seed (seed consumption correction) | Superseded | Covered by FARM-06 (OD-23: manor farms get no free seed; village sowing takes real seed), the owner's later decision |  |  | superseded by FARM-06 |  | Superseded |  |
| FSE-12 | One agricultural model for player and village farming (parity) | In progress | Comparison done (Actions 39531422104 against 39529507848): 3.1x the grain, a glut of 67,000-90,000 wheat, no starvation; report docs/design/FSE12_COMPARISON.md; not activated | Owner's choice: (a) the player's yield as is, (b) one lower per-cell yield for everyone, (c) fewer cells sown; decided with FSE-13 | `68a3611`, world_test::_fse12_shared_fields | after FSE-16 |  | Required feature | L |
| FSE-13 | Seasonal farming for village fields (implemented and tested in isolation; activation needs owner review) | In progress | Comparison done (Actions 39526774144 against 39523615798): seasonal fields cut the grain year by 26-28 %, the pens' milk by 44-90 %, starvation 8-27 a seed against 0; report docs/design/FSE13_COMPARISON.md; not activated | Owner's review of docs/design/FSE13_COMPARISON.md; recommendation: pair with farm plots and FSE-12 and compare again | `01a83f0`, world_test::_fse13_seasonal_fields | after FSE-12 |  | Required feature | M |
| FSE-14 | Dynamic land planning: design and safe foundations (land rental for plots and pens) | Complete | Design written (docs/design/FSE14_LAND_PLANNING.md): land supply, Build 16 foundations, small and large plots and pens on rent as proposals; the rest scheduled with FSE-10 per the acceptance |  | `268895c`, farm_plots_test (foundations) |  |  | Required feature | M |
| FSE-15 | Recalculate the land requirement after the seed, season and parity corrections | Complete | FarmPlots.land_requirement: a year's food need against a cell's net yearly yield after seed, capped by labour: 0.64 cells per adult (was 1.7 assumed) |  | `27a1be5`, farm_plots_test | after FSE-11; after FSE-12; after FSE-13 |  | Required feature | S |
| FSE-16 | Seed-2 starvation: root cause of each of the 11 deaths | Complete | Two four-seed 365-day acceptance runs with no starvation death, 0 script errors and balanced ledgers (1fefddb, Actions 39523615798; 62b7488, Actions 39529507848), with its tests passing in all 27 suites |  | `9db091b`, Actions 39523615798, 39529507848; suites | after B7-015 |  | Testing and verification | S |
| FSE-17 | Manor relief checks and draws on every food store (amends the B3 relief rule) | Complete | Two four-seed 365-day acceptance runs with no starvation death, 0 script errors and balanced ledgers (1fefddb, Actions 39523615798; 62b7488, Actions 39529507848), with its tests passing in all 27 suites |  | Actions 39523615798, 39529507848; suites | after FSE-16 |  | Testing and verification | S |
| FSE-18 | The family chest: a household's food is kept in its pantry, communal; traders keep sellable stock and stock the chest first | Complete | Two four-seed 365-day acceptance runs with no starvation death, 0 script errors and balanced ledgers (1fefddb, Actions 39523615798; 62b7488, Actions 39529507848), with its tests passing in all 27 suites |  | Actions 39523615798, 39529507848; suites | after FSE-17 |  | Testing and verification | S |

### Food-security defects

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| FSE-B05 | A pen whose keeper is gone is let again (its animals starved untended) | Complete | a946ba1 |  | `a946ba1`, world_test |  |  | Done |  |
| FSE-B06 | Bandits' poaching and the clan's camp meals feed them only from real food | Complete | Two four-seed 365-day acceptance runs with no starvation death, 0 script errors and balanced ledgers (1fefddb, Actions 39523615798; 62b7488, Actions 39529507848), with its tests passing in all 27 suites |  | `6ab7d50`, Actions 39523615798, 39529507848; suites | after WDR-016-C |  | Release blocker | M |
| FSE-B07 | Villagers can sell flowers to the Apothecary | Complete | a946ba1 |  | `a946ba1`, world_test |  |  | Done |  |
| FSE-B08 | A hunt cut short releases its claim on the animal | Complete | a946ba1 |  | `a946ba1`, world_test |  |  | Done |  |
| FSE-B09 | Hunter job openings count only game hunters may take | Complete | a946ba1 |  | `a946ba1`, world_test |  |  | Done |  |
| FSE-B10 | The player's kills enter the wildlife ledger | Complete | a946ba1 |  | `a946ba1`, world_test |  |  | Done |  |
| FSE-B11 | The home hearth gives the player and villagers the same recipes | Complete | Two four-seed 365-day acceptance runs with no starvation death, 0 script errors and balanced ledgers (1fefddb, Actions 39523615798; 62b7488, Actions 39529507848), with its tests passing in all 27 suites |  | `6ab7d50`, Actions 39523615798, 39529507848; suites |  |  | Release blocker | S |
| FSE-B12 | Hunting experience by one rule for the player and villagers | Complete | Two four-seed 365-day acceptance runs with no starvation death, 0 script errors and balanced ledgers (1fefddb, Actions 39523615798; 62b7488, Actions 39529507848), with its tests passing in all 27 suites |  | `6ab7d50`, Actions 39523615798, 39529507848; suites |  |  | Release blocker | S |

### Seeds and propagation

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| MERCH-01 | A village seed merchant or booth selling crop and flower seed, berry cuttings and fruit-tree seed or saplings, with real stock, coins and re | Pending testing | Implemented (fd2f9de, 4375d4c): flower seed and berry cuttings recovered by a seeded chance on picking and planted on village grass; berry bushes bear in Summer and Autumn; households keep recovered material; the seed se | Measure in the four-seed runs; owner to confirm the readings | `fd2f9de`, farming_test (test_propagation, test_perennials, test_household_seed, test_seed_seller) | after SEED-02 |  | Required feature | M |
| SEED-01 | Seed and propagation audit: crops, fruit trees, berry bushes, flowers (acquire, store, plant, grow, harvest) | Complete | docs/BUILD_16_STATUS.md, findings for the owner's sections 1-8 (seeds and propagation) |  | `38b987e` |  |  | Required feature | S |
| SEED-02 | Planting consumes real seed or propagation material for every plant type; harvests recover seed or cuttings at a deterministic chance | Pending testing | Implemented (fd2f9de, 4375d4c): flower seed and berry cuttings recovered by a seeded chance on picking and planted on village grass; berry bushes bear in Summer and Autumn; households keep recovered material; the seed se | Measure in the four-seed runs; owner to confirm the readings | `fd2f9de`, farming_test (test_propagation, test_perennials, test_household_seed, test_seed_seller) | after SEED-01 |  | Required feature | L |
| SEED-03 | Perennials (fruit trees, berry bushes) survive harvest and bear again by season; growth follows the 8-day year | Pending testing | Implemented (fd2f9de, 4375d4c): flower seed and berry cuttings recovered by a seeded chance on picking and planted on village grass; berry bushes bear in Summer and Autumn; households keep recovered material; the seed se | Measure in the four-seed runs; owner to confirm the readings | `fd2f9de`, farming_test (test_propagation, test_perennials, test_household_seed, test_seed_seller) | after SEED-01 |  | Required feature | M |
| SEED-04 | Households save planting material from their own harvests | Pending testing | Implemented (fd2f9de, 4375d4c): flower seed and berry cuttings recovered by a seeded chance on picking and planted on village grass; berry bushes bear in Summer and Autumn; households keep recovered material; the seed se | Measure in the four-seed runs; owner to confirm the readings | `fd2f9de`, farming_test (test_propagation, test_perennials, test_household_seed, test_seed_seller) | after SEED-02 |  | Required feature | S |

### Owner decisions

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| OD-10 | Owner decision: a lasting stone source before Build 17 (stone runs out by day 160-190 and stalls house building) | Superseded | raised in error: the owner already decided this on 2026-10-18 (docs/DECISIONS.md, Build 7 economy corrections) and it is implemented (NPCBrain._caravan_stone); the stall at day 100 was not stone either (merchants held 80 |  |  | superseded by B7-007 | yes | Superseded |  |
| OD-11 | Owner decision: an orphaned child for whom no household is eligible: what temporary care applies (stay in the family house watched by neighb | Complete | answered by the owner 2026-10-20 (docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md); implementation is FAM-07 |  |  |  |  | Done |  |
| OD-12 | Owner decision: choosing between equally close eligible relatives (for example two grandparent households, or an aunt and an uncle) | Complete | answered by the owner 2026-10-20 (docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md); implementation is part of FAM-03 |  |  |  |  | Done |  |
| OD-17 | Owner decision: the Game Designer spec's open calls not covered by another entry: C1 the hero (spec: 'Your main character is the hero' again | Blocked | Owner, 2026-10-21 (docs/directives/2026-10-21_build16_owner_decision_resolution.md) | The owner's answer recorded in owner_answer before any change follows from it |  |  | yes | Owner decision |  |
| OD-20 | PAR-05: should a caught pickpocket's cry (theft rules 2026-10-18; the Stealth guard_radius perk) become a report like assault's? | Complete | Owner, 2026-10-21 (docs/directives/2026-10-21_build16_owner_decision_resolution.md) |  |  |  |  |  |  |
| OD-25 | Owner decision resolution for Build 16 (2026-10-21): FARM-07 2 coins a week; FARM-01/02 variable plots, materials from the perimeter; STALL- | Complete | docs/directives/2026-10-21_build16_owner_decision_resolution.md |  |  |  |  | Done |  |
| OD-26 | Owner decision 2026-10-21: one shared per-cell farming model for player, households and manor approved as the direction; no yield approved;  | Complete | docs/directives/2026-10-21_fse12_fse13_farming_decision.md |  |  |  |  | Done |  |
| OD-27 | Owner answers to the land and stall questions Q8-Q13 (2026-10-21) | Complete | Owner answered |  |  |  |  | Required feature | M |

### Player-villager parity

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| PAR-00 | The player is a villager: one set of world rules for player and villagers | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script errors, ledgers  |  |  | Required feature | M |
| PAR-01 | OD-18.1: villagers develop skills exactly as the player does | Complete | Shared skills for the player and villagers; clarified by the final directive (PAR-01A..C); parity_test 42 checks; 26 suites pass; gate re-baselined |  | parity_test.gd |  |  | Done |  |
| PAR-01A | Starting experience only at world creation, from a plausible occupational history; one-time migration for older saves | Complete | Implemented with PAR-01; parity_test checks it; 26 suites pass |  | parity_test.gd |  |  | Done |  |
| PAR-01B | Career changes neither grant nor reset experience | Complete | Implemented with PAR-01; parity_test checks it; 26 suites pass |  | parity_test.gd |  |  | Done |  |
| PAR-01C | Experience comes from activities, whatever the occupation | Complete | Implemented with PAR-01; parity_test checks it; 26 suites pass |  | parity_test.gd |  |  | Done |  |
| PAR-02 | OD-18.2: one trade eligibility rule (the trader's coin reserve) for player and villagers | Complete | One rule for every purchase, now OD-19's dynamic reserve (PAR-02A) |  | world_test.gd _par02_reserve; start_test.gd |  |  | Done |  |
| PAR-02A | OD-19: a dynamic, necessity-based reserve in place of fixed coin floors | Complete | All 27 Godot suites pass with it (out of the 27a3560 tree); reserve_test's nine scenarios pass |  | reserve_test.gd; world_test.gd _par02_reserve |  |  | Done |  |
| PAR-03 | OD-18.3: villagers recover health by the player's rest model | Complete | World.rest_recover, the player's model, used by the player's rest and every villager rest step (rest_end); a hurt villager rests by day; 25 suites pass; gate unchanged |  | world_test.gd _par03_rest |  |  | Done |  |
| PAR-04 | OD-18.4: villagers can craft every recipe the player can, under the same requirements | Complete | The eleven recipes have makers through World.work_craft, for a buyer only (INT-157); check_materials shows no player-only recipe; parity_test test_eleven_recipes; all 26 suites passed on this code with PAR-05's rework in |  | parity_test.gd test_eleven_recipes | after PAR-01 |  | Done |  |
| PAR-05 | OD-18.5: crime awareness by legitimate means only, the same for assault and theft | Complete | Reworked per the final directive: no hearing; guards learn of an attack by sight or by a report from the victim or a witness (World.report_crime, NPCBrain._report), the same for the player and bandits; all 26 suites pass |  | world_test.gd _par05_awareness |  |  | Done |  |

### Theft and crime

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| PICK-01 | A caught pickpocket raises a witness report through World.witness (OD-20), as assault does (PAR-05): awareness only from legitimate witnesse | Pending testing | A caught pickpocket no longer raises a cry; the victim and villagers who saw it report it through report_crime (PAR-05 rules); unseen thefts known to nobody; a guard told of a theft fines only with the thief in sight, ne | Owner to confirm two readings: the Stealth guard_radius perk now narrows who sees a caught try; a told guard fines a thief in sight | `b018185`, world_test::_pick01_reports | after OD-20 |  | Required feature | S |

### Judgment gate

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| SJD-A | Judgment expansion Gate A: Build 16 stabilization and baseline (seeds, remote commit, known defects); no implementation | Not started |  | As stated in the source document |  |  |  | Required feature | S |

### Market stalls

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| STALL-01 | Stalls are built by anyone on cleared land through the construction system with real materials, under the realm's 5% sales lease | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `afef91d`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | L |
| STALL-02 | A stall's own inventory: goods are moved into it for sale and are in one place only | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `afef91d`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | M |
| STALL-03 | OPEN STALL: the stall sells unattended to real buyers through the existing market; auto-closes when sold out, with a notification | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `afef91d`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | M |
| STALL-04 | CLOSE STALL: sales stop, the unsold goods stay in the stall, the session's sales are totalled | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `afef91d`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | S |
| STALL-05 | The realm's 5% commission on each session's actual sales, through real coins (100 sold: 5 to the treasury, 95 to the seller) | Complete | Implemented and tested; the four-seed year runs of the integrated build pass |  | `afef91d`, suites (35); Actions run 39618523947 on dbbb66a, normal game, 365 days, seeds 1-4: all passed (0 script error |  |  | Required feature | S |
| STALL-06 | Villager households build, stock, open, close and restock stalls by the player's mechanics, selling surplus with the family's needs weighed | Pending testing | Households build, stock, open and restock stalls by the player's rules; stall sales to be measured in the four-seed runs (acceptance); grain is not sold through stalls (needs an owner rule on how much grain a household k | The OD-19/FSE-18 reserve is weighed, not an absolute bar; no guaranteed sales; measured on the seed runs | `afef91d`, stalls_test |  |  | Required feature | L |

### Time model

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| TIME-01 | Time-system audit: every timed system's duration, unit, meaning, calendar equivalent, calibration, balance effect and parity | Complete | docs/design/TIME_MODEL.md (the audit document) |  | `b388bfb` |  |  | Done |  |
| TIME-02 | Explicit time units in configuration and code; one shared conversion layer (no third clock) | Complete | The last criterion done: the living documents (BUILD_DECISIONS, the interaction manifest) cite the renamed keys; historical audits keep the names of their time. Code in 99e7448, suites green since, the four-seed runs on  |  | `99e7448`, suites; Actions 39523615798, 39529507848 | after TIME-01 |  | Required feature | M |
| TIME-03 | Recommended time retuning (outliers): proposals only, owner review before any change | Complete | Proposals only, as the entry asks: docs/design/TIME03_RETUNING_PROPOSALS.md (P1-P9, U1-U7) for the owner's review; no data changed |  | `8542a33` | after TIME-01 |  | Optional | S |
| TIME-04 | Player starvation damage follows the villagers' rule (time-audit defect D4) | Complete | a946ba1 |  | `a946ba1`, world_test |  |  | Done |  |

### Wildlife

| ID | Item | Status | Implemented | Remains | Evidence | Blockers / depends | Owner? | Class | Size |
|---|---|---|---|---|---|---|---|---|---|
| WR-02 | Grazers in a wood all stop eating while the wood is over its grass capacity, so some starve together | Pending testing | Fauna._may_graze: over a wood's grass capacity only as many grazers eat as it feeds, ranked strongest (health share), then best fed, then id; the weakest and hungriest go short. wildlife_test test_grazing_over_capacity;  | Over capacity, the weakest or hungriest suffer first rather than the whole herd at once | game/tests/wildlife_test.gd test_grazing_over_capacity |  |  | Testing and verification | S |

<!-- b16:end -->

## Findings for the owner's sections 1-8 (current state, before any change)

- **Seeds and propagation (SEED-01, audited):** crops (wheat, carrot, potato, herb) are planted by the player cell by cell
  and **consume one real seed** a cell; a harvest returns a fixed one seed (no chance); seasons apply. The manor's fields
  sow **without seed** (FARM-06). Fruit trees: apple, oak and pine saplings exist; the player can plant a sapling
  (`main.gd::plant_sapling`, consumes it); felling drops saplings by a seeded chance; apple trees are perennial and bear
  in Summer and Autumn. Berry bushes and wild flowers regrow after picking (perennial) but are **not seasonal and cannot be
  propagated or planted** (no cuttings, no flower seed from wild flowers). Villagers never plant anything.
- **Seed merchant (MERCH-01):** the food merchant and farmers sell crop seed to the **player only**, from finite stock the
  caravan restocks; no seller of berry cuttings, flower seed or saplings; no villager buys seed.
- **Armorer (ARM-01): STILL PRESENT** (established from the code; not yet observed in play). There is no armorer
  occupation. The "Smithy and Armory" (b4) has an armoury counter (`s8`) that is decorative: no keeper, no prompt. The
  smith is never counted as "at a post" (`World`'s at-post check covers only the tavernkeeper, stall merchants and
  storefront keepers), so the player can buy from the smith only by talking to them, which fails with "Can't talk, I'm..."
  whenever they are forging (25-150 minutes a job) or walking; they work 7:00-18:00. The second smith probably goes home
  in the day when the forge and anvil are both taken (inferred). Iron armour has no market outlet and the smith keeps at
  most one. Partial workaround today: the goods merchant's tools-and-arms stalls (7:00-18:00) sell swords, tools and
  helmets, never armour. No fix was ever claimed and no test covers buying from the smith.
- **Counters, shopkeepers, trade (CTR-01..04, SHOP-01, TRADE-01): not started.** Working counters today: the tavern
  (keeper there 7:00-18:00 although it opens to 22:00), the six market stalls, the player's own stall and shops (with an
  attendant), villager storefronts. No counter: the smith and tanner (b4), the carpenter (b25), the sage (b3). Nothing
  summons a keeper; a counter works only when its keeper happens to stand by it. Businesses already buy from the player
  and villagers through one shared trade rule with real coins and the household reserve, but their demand is a fixed
  stock cap per trade, not real production need (the smith buys gold ore below the level to smelt it). Reusable: the
  prompts and A button, the at-post checks, the trade window, the attendants' walk-to-the-counter pattern, counter `s8`.
  To build: counters for the smithy (reuse `s8`), sawmill, sage and built workshops (a village-generator change: a
  generator version bump and save handling); one summon-and-serve task with a clear "nobody can come" message, which
  releases a station without losing materials; the at-post and shop-name checks extended (the shop-name lookup would
  fail for a smith as written); demand from real need; whether iron armour reaches the market.

## C. Owner decisions affecting Build 16

**Resolved by the owner on 2026-10-21** (OD-25, `docs/directives/2026-10-21_build16_owner_decision_resolution.md`; each
recorded on its entries with a history line; an approval is not an implementation):

| Decision | Owner's choice | Entries | Implementation |
|---|---|---|---|
| FARM-07 | 2 coins a week, existing lease scheduling and accounting, no new fees, penalties or evictions | FARM-07, FARM-01 | Not started |
| FARM-01/02 | Variable plot sizes (5x6 rejected); fence and gate materials from the actual perimeter by the existing construction rules; a missing recipe proposed for approval | FARM-01, FARM-02 | Not started (recipe audit first) |
| STALL-01/05 | 5% of completed sales, settled at session close; audits first; 6 planks + 1 iron bar not adopted; no rounding rule approved; existing merchant arrangements not converted silently | STALL-01, STALL-05 | Not started (audits first) |
| FSE-12 | Manor fields to the shared per-cell model behind a test switch; comparison; owner review before activation | FSE-12 | Implemented behind the switch (`68a3611`), compared (`docs/design/FSE12_COMPARISON.md`); FARM-08 yield comparison in progress; switch off |
| FSE-13 | Comparison first, owner review before activation; the 8-day year kept | FSE-13 | Implemented behind the switch (`01a83f0`), compared (`docs/design/FSE13_COMPARISON.md`); switch off |
| FSE-B06 | Deadwood camp fire kept as an interim exception until bandit factions (WDR-016-C) | FSE-B06 | Complete and verified (`6ab7d50`, runs on `62b7488`) |
| OD-20 | Witness reports for a caught pickpocket, no automatic alarm | OD-20 (answered), PICK-01 | Implemented (`b018185`), awaiting runs and two readings (items 6-7) |
| EQ-22 | The caravan buys by actual need; no fixed smiths-first order, no equal split | EQ-22 (now approved) | Implemented (`5cce264`), awaiting runs and a reading (item 5) |
| OD-17 | **Remains blocked**: no answer | OD-17 | Blocked |
| DVW-A12 | Deferred to the start of Build 17 | DVW-A12 (DEFERRED, target 17) | Deferred, acceptance kept |
| DVW-B6 | Deferred to Build 18 | DVW-B6 (DEFERRED, target 18) | Deferred, acceptance kept |

**Conflicts found while recording them (for the owner; nothing changed silently):**

1. **The farmland rent against the lease framework.** The existing framework prices a lease by size: a week's rent is
   10 % (`weekly_rent_share`) of the land price, and the land price is 60 coins (`plot_price`) per 90 cells, so a plot of
   16-30 cells pays 2 coins a week, 31-45 cells 3, 46-60 cells 4 (`Property.rent_of`, `land_price`). The approved price is
   2 coins a week whatever the size. Implementing it means farm plots are priced apart from the size formula: the
   approved price stands, and no new formula is introduced.
2. **No upper limit on a plot's size.** The land system refuses plots under 3x3 cells, outside the village, on the
   manor's fields or on pens, but sets no maximum; at a flat 2 coins a week a household could lease a very large field.
   Options: (a) no limit beyond the land system: the fence's materials (from the perimeter) and the labour of clearing,
   ploughing and sowing limit what a household takes on; (b) a maximum farm plot size; (c) the size formula above a
   threshold (a new pricing rule, not approved). Recommendation: (a), measured in the simulations; the owner decides.
3. **STALL-05's earlier acceptance said the 5% "replaces the 5-coin daily stall rent and villager merchants' free
   stalls".** The 2026-10-21 decision asks for an audit first and no silent conversion; the acceptance is rewritten to
   the new wording.
4. **The earlier report's OD-17 recommendation ("as in the entry") was empty:** the entry holds no recommendation. The
   entry is presented below as it stands.

**Readings made while implementing (2026-10-21), for the owner to confirm or correct** (implemented as described, each
easy to change):

5. **EQ-22, what "need" means.** The caravan buys the village's surplus, so need is read as the seller's need to sell: the
   share of its holding that is surplus, plus the share of its missing trade inputs' cost that its coins cannot pay.
   "Competing demand" is read as competition for the caravan's purse; village buyers wanting the same good are not a term.
6. **PICK-01, the Stealth perk `guard_radius`.** The perk acted only on the pickpocket's cry, which OD-20 removes. It now
   narrows how far a caught try is seen (the witness radius times the perk's factor), so fewer people can report it; the
   victim always knows. The alternative is to remove the perk from Stealth tiers 6, 8 and 10.
7. **PICK-01, a guard told of a theft.** The existing rules do not say what a guard does when told. Implemented: the guard
   knows; if the thief is in the guard's sight when the report arrives, the guard stops and fines them (the existing
   caught-thief fine); never a chase (that is assault's response). The alternative is knowledge only.

**Questions from the farm and stall audits (2026-10-21, `docs/design/FARM_STALL_AUDIT.md`), open for the owner;
FARM-02's fence and gate and STALL-01..06 wait on them; FARM-06, the plot lease itself and seeds do not:**

8. **Rounding of the 5% commission** (no convention exists: rent rounds up, prices to nearest, the household tax down):
   (a) down (sessions under 20 coins pay nothing); (b) nearest; (c) up (any sale pays at least 1 coin); (d) the exact
   fraction kept as a saved remainder per stall, whole coins settled as they accrue.
9. **"Logs and stone" for the fence and gate:** the only fence rule (the pens) uses planks, 1 per 3 fence cells, with a
   free gate and no stone. (a) the pen rule unchanged; (b) the pen rule plus stone for the gate posts; (c) raw logs at the
   sawing ratio (6 fence cells a log) plus stone for the gate; (d) quantities the owner sets.
10. **A stall's materials:** no free-standing stall recipe exists. (a) the storefront's 6 planks + 1 iron bar; (b) the shop
   counter's 3 planks; (c) a new recipe for approval.
11. **Plot size at a flat 2 coins** (no maximum in the land system): (a) no limit; (b) a maximum (e.g. the 9x10 house
   plot); (c) one farmland lease per household. And may farmland also be bought outright (priced by area), or only leased?
12. **Which existing stalls OD-24 covers:** (a) only newly built stalls; the merchants' six rent-free stalls and the two
   5-coin pitches stay as they are; (b) the 5% also on the merchants' stalls and/or replacing the pitches' rent; (c) the
   pitches withdrawn once built stalls exist.
13. **Proceeds before a session closes** (the till can be emptied at any time today): (a) they stay in the stall until
   settled; (b) all but the commission's share may be taken; (c) free withdrawal, an unpaid commission under the
   existing arrears rules.

**Readings made for seeds and the seed merchant (2026-10-21; SEED-02..04, MERCH-01), implemented, for the owner:**

14. **Berry bushes bear in Summer and Autumn** (as the apple trees), bare in Spring and Winter; wild flowers all year.
    Berries are a food: this changes the food supply in two seasons (measured in the next runs).
15. **Recovery chances and growing times** (balance, provisional): a picked flower gives a seed 1 time in 4, a picked
    bush a cutting 1 time in 5; flower seed grows in 1 season, a cutting in 2; prices 1-2 coins.
16. **Where cuttings and flower seed are planted:** free village grass, by the sapling rule (not on a surveyed plot, not
    outside the village). Only the player plants them so far; villagers forage and keep or sell the material.
17. **A farmer short of wheat seed buys it** at the food stall with the household's coins, within its reserve.
18. **Art:** no pack has a cutting or sprout; the cuttings use seed-packet icons, and a young plant is not drawn until it
    bears.

**Readings made for SHOP-01, TRADE-01 and CTR-04 (2026-10-21), implemented, for the owner:**

19. **A business buys by need:** only inputs of recipes it has the skill for (a smith below Smithing 3 buys no gold ore),
    up to its stock limit (the existing `NPCBrain.BUYS` numbers kept as the limit), partial lots towards a batch allowed,
    and within its coins and the OD-19 reserve. How far ahead a business should stock (a day's work, a week's) has no
    rule; the existing limits stand until the owner sets one.
20. **One sale rule** for the player and villagers selling to a business; a sale it cannot take whole is refused with
    the reason ("can use only 2 more iron ore"); villager sales are one all-or-nothing trade.
21. **Not yet under the rule:** purchases a business starts itself (the smith's trips for ore, coal and planks, the
    carpenter's parts), and an input bought without its companion (ore without coal).
22. **Counters keep their terms** (CTR-04): no commission on counter sales; the 5% applies to OD-24 stalls only (not yet
    built, waiting on the stall questions 8-13).

**OD-17, still blocked: the entry as recorded** (source `docs/game-designer/SPEC_RECONCILIATION.md` section 4):

- **C1, the hero.** Spec, the owner's interview: "One hero (owner said: "Your main character is the hero")"; Bob's
  recommendation "Full story with dialogue". Against the owner's decision of 2026-10-17: "The player is an ordinary
  inhabitant of an original village in an original county, not the chosen one", and "the novel's story is the world's
  history, not the player's quest". Question: does "one hero" mean one player character (not a party), or a hero role in
  the story? An agent proposal of 2026-10-17 read it as one player character, not a party; never confirmed.
- **C10, the view.** Spec: "a top-down pixel map, but the characters ... kind of at an angle"; "almost isometric ...
  you'll see a little bit of the side and the edge"; Bob: "2.5D / three-quarter view ... avoid flattening this to pure
  top-down" and also "Perspective: Top-down". Owner decision of 2026-10-17: "Working visual direction: 2D/2.5D isometric
  with 8-direction animated sprites". Open question D1: a true 2:1 diamond projection, or an oblique 3/4 top-down view
  like today's art (2.5D)? A reference picture asked for. No agent recommendation recorded.
- **Steam Deck labelling.** Spec: Steam Deck a target platform, labelled "(web)" for updates. Owner (#27): "Correct
  Steam Deck platform labeling without changing supported platforms." Question: confirm Steam Deck is a supported target
  served by the Linux build (an agent proposal of 2026-10-17, C6; never confirmed).
- **Dependencies:** the view (C10) ties to DGA-D1 and OD-03 (art direction); nothing in Build 16 waits on any of the
  three. Class progression (REC-010), ranged combat (REC-009), Mote (REC-002) and the API 36 policy (REC-003) are separate
  entries.

Not affecting Build 16 and not reopened: the Living Economy decisions (OD-LE-01..15), the Judgment questions
(SJD-Q01..Q14, Build 19), OD-01..09 (later builds or general balance review).

## D. What remains before Build 16 is complete

Build 16 is complete when every non-deferred item is complete and verified, and the acceptance runs (EQ-06: four seeds,
365 days, player inactive) show 0 script errors, balanced ledgers and no consistent collapse, with the suites green and
the determinism gate passing. Outcomes are measured, not required to be favourable (WDR-022).

- **Release blockers (4):** ARM-01 (the armorer, the owner's playtest); FSE-B06 (bandits fed from nothing); FSE-B11 (the
  hearth's recipes differ for player and villagers); FSE-B12 (hunting experience differs). Any script error in a long
  run is also a blocker.
- **Required features not finished (41):** family farms (FARM-01..07); stalls (STALL-01..06); counters, shopkeepers and
  trade (CTR-01..04, SHOP-01, TRADE-01); seeds (SEED-02..04, MERCH-01); the farming model and seasons (FSE-12..15); the
  time-unit layer (TIME-02); the food-security umbrella and its tests (FSE-00, FSE-08, FSE-09); parity's umbrella
  (PAR-00); the exploit-player test (DVW-A5); equilibrium objectives EQ-03, EQ-05, EQ-06, EQ-16; REC-001 (the player's
  adoption is not yet confirmed); SJD-A (Gate A, the Build 16 baseline); this audit.
- **Testing and verification (18):** relief, the family chest and the death analysis (FSE-16..18, B7-015, now measured:
  close on seeds 3-4); families and orphans (FAM-02..07); grazing (WR-02); B7-016 (traders at 0 coins: re-measure); EQ-09
  (stone); DVW-A3 (money supply); EQ-01, EQ-02, EQ-04, WDR-005-C (measured on the acceptance runs).
- **Optional (1):** TIME-03 (the retuning proposals; owner review).
- **Deferred by the owner (2026-10-21):** DVW-A12 to the start of Build 17, DVW-B6 to Build 18. Nothing else is moved.

## E. Recommended execution plan

Stabilization first: the family-chest baseline is closed before any change that would invalidate it.

| Order | Work | Size | Depends on | Changes the baseline? | Parallel? |
|---|---|---|---|---|---|
| 1 | Read the four-seed run on `d6d80a4`; classify every death; close FSE-16..18, B7-015, FSE-B06/B11/B12 on it | S | the run under way | no | lead only (simulations) |
| 2 | ARM-01 with CTR-01..03: one summon-to-counter interaction for skilled businesses (prompt, A, the keeper walks to the counter by normal navigation, "nobody can come" otherwise), starting with the smithy's counter `s8` | M-L | - | yes | lead |
| 3 | EQ-22 caravan buying by need; PICK-01 pickpocket witness reports | M, S | - | yes | one worker (separate files: the caravan; theft) |
| 4 | Audits before code: the fence, gate and pen construction definitions (FARM-02), the stall recipes, land, merchant stalls, pitch rent and settlement (STALL-01/05) | S each | - | no | the same worker, read-only |
| 5 | FARM-06 manor fields take seed; FARM-01..05, FARM-07 family plots (variable sizes, perimeter materials, 2 coins a week) | L | 4 | yes | lead |
| 6 | SEED-02..04, MERCH-01 propagation and the seed merchant | L | 5 | yes | lead or a worker after 5 |
| 7 | STALL-01..06 (after the settlement audit and the owner's rounding answer if no convention applies) | L | 4 | yes | a worker |
| 8 | SHOP-01, TRADE-01, CTR-04 (the counters for the remaining trades) | L | 2 | yes | after 2 |
| 9 | FSE-12 manor fields on the shared model behind a switch, comparison; FSE-13 seasonal fields behind a switch, comparison report; FSE-15 | M-L | 5 | only when the owner activates | lead (simulations) |
| 10 | Re-measure: four seeds, 365 days; close EQ-01..06, EQ-09, EQ-16, FAM-02..07, WR-02, B7-016, DVW-A3, WDR-005-C; DVW-A5 exploit-player test | M | 2-9 | is the new baseline | lead |
| 11 | Final acceptance: four seeds, 365 days; the suites; the gate; the report | M | all | is the release baseline | lead |

Done since the plan was written: FSE-B11, FSE-B12, FSE-B06 (`6ab7d50`) and TIME-02 (`99e7448`), awaiting the runs.
Deferred by the owner: DVW-A12 (Build 17), DVW-B6 (Build 18).

At most two workers at once (AGENT-01), one preferred until parallel work shows its worth (owner, 2026-10-21). The
baseline changes only through the lead, who runs the simulations and re-baselines.

## G. Agent summary

- **Before the owner's agent directive (this session):** read-only audit workers, one task each, reports reused: the
  agriculture audit (about 143,000 tokens), hunting and husbandry (191,000), the time-system inventory (180,000), the
  OD-22..24 code survey (211,000). These counts are the tool's own reports; no other cost figure is available.
- **Since the directive (AGENT-01):** two workers in all, one at a time, each bounded with its own files: the armorer and counters check (read-only; about 149,000 tokens by the tool's report) and TIME-02 (implementation in its own worktree, merged by the lead after the lead's suites and gate; about 171,000 tokens by the tool's report). No duplicate work and no conflicts: the worker's fauna.gd edits (aging) and the lead's (hunting) merged cleanly.
- **Is parallel work saving time?** Yes for the audits, which ran while the long simulations ran (only the lead runs
  simulations). Implementation workers will be used only on tasks with separate files.
