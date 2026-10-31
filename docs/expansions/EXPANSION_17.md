# Expansion 17: Mining & Industrial Development (EXP-A)

Status record under the owner's documentation reconciliation directive (`docs/directives/2026-10-31_documentation_reconciliation.md`,
DOC-RECON-01). Vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 against the register on
`staging/my-medieval-life` (`aeaa012` plus `3ecf89f`) and the game code on `origin/wip/expansion20` at `ad281dc`. Register
corrections this file relies on are proposals until the lead applies them (listed at the end).

**Overall status: IMPLEMENTED and released (Build 17, private draft, 2026-10-22).** All seven phases of the owner's specification
(A-G) and the enterable caves (MIN-H) are integrated and have carried forward through Builds 18-24 into `wip/expansion20`. What
remains is a set of owner-approved follow-ons that have no build placement (design only, not authorized), three World Design Rule
compliance records and the Build 17 wiki reconciliation record.

## 1. Current approved scope

| Source | Date | What it settles |
|---|---|---|
| `docs/directives/My_Medieval_Life_Mining_Industry_Expansion.pdf` / `.txt` | 2026-10-20 | The primary specification: five-stage pathway (surface, prospecting and assay, open pit, underground and caves, mature networks), capability levels 1-4 (level 5 a proposal), phases A-G, acceptance criteria (s.11) |
| `docs/directives/2026-10-20_two_decisions_three_expansions.md` | 2026-10-20 | Mining is its own expansion (EXP-A), separate from Settlements and Judgment |
| Register ROAD-01, `builds.17` | 2026-10-20 | Build 17 = Expansion A; `implementation_authorized: true` |
| `2026-10-21_build17_*` (architecture/mining/contracts, consolidated 14 decisions, MIN-F Q1-Q5, MIN-F2 Q1-Q2, OD-01, REC-013, CON-01 final, start underground, early-game progression, combined integration) | 2026-10-21 | The owner's answers to every MIN-*-Q, OD-01, OD-28, OD-29, Q-C1..Q-C9, CON02-S-1..S-6 (all disposition APPROVED in the register) |
| `2026-10-22_build17_personal_playtest_release.md` | 2026-10-22 | Build 17 private playtest release authorized |

Approved direction kept from the specification: depleted ore never regenerates; clues give a search area, never a guaranteed
deposit; equipment, labour and transport are real; capability levels come from people, tools and infrastructure and never gate
work (Q18-9); level 5 and "explicit candidate mechanics" are proposals (spec s.12 "Directive to Claude").

## 2. Implemented

Evidence for every row: integrated in Build 17 (`wip/build17`, release code `cd7439c`), carried into Build 18 (`wip/build18`) and
present on `origin/wip/expansion20` `ad281dc` (every commit named below is an ancestor of it). Code: `game/scripts/core/`
`prospecting.gd`, `discovery.gd`, `open_pit.gd`, `underground.gd`, `mine_works.gd`, `mine_supply.gd`, `contract_services.gd`;
data `game/data/prospecting.json`, `open_pit.json`, `underground.json`, `mine_works.json`, `capabilities.json`, `resources.json`.

| Requirement | What | Commit | Tests (on `ad281dc`) | Validation |
|---|---|---|---|---|
| MIN-A | Terrain, mining, inventory, recipes, AI, pathfinding, save audit and architecture | `a659f42` | n/a (audit) | TARGETED TESTS PASSED |
| MIN-B, STONE-01, B7-006 | Exhausted ore leaves quarryable stone; raw stone and building blocks separate; fair mine pay | `79afe00`, `d28503c` | `quarry_test`, `stone_test` | TARGETED TESTS PASSED; B7-006 INTEGRATION VERIFIED |
| MIN-C, MIN-C-Q3 | Natural clues, prospector, forge-made kit, samples, assay by the smith | `7b83fe8` | `prospecting_test`, `discovery_test` | TARGETED TESTS PASSED |
| MIN-C-Q1 | Manor commissions surveys but is not the only employer; any buyer can contract a survey through CON-01/02; no mining wage | `b0506db` (manor), `contract_services.gd` (survey service) | `discovery_test` (manor survey), `services_test` (player-to-NPC survey) | TARGETED TESTS PASSED. Register shows PARTIAL: **stale, proposed INTEGRATED** |
| MIN-D, MIN-D2, MIN-D3 | Finite hidden deposits; settlement mining capability 1-4 with autonomous adoption; player counts by villager rules; trial-pit earth | `b0506db`, `fbdc8fc` | `discovery_test`, `parity_mining_test` | TARGETED TESTS PASSED |
| MIN-E, MIN-RIGHTS, MIN-SHOVEL, MIN-SKILLCAP | Open pits, spoil, topsoil/dirt as materials, ramps; open access to common ground; shovels; capability from real skills | `6ebf1ae`, `fbdc8fc`, `e3b992a` | `openpit_test`, `parity_mining_test` | TARGETED TESTS PASSED |
| MIN-F, MIN-F2, MIN-EQUIP, MIN-COLLAPSE | Underground mining, cutaway, supports that decay and collapse, hidden underground ore, minecarts and track, shafts; equipment made by carpenters and smiths; binary collapse outcome | `e929446`, `f7f9f71`, `9a7b513` | `underground_test`, `underground_struct_test`, `underground_ext_test`, `mine_frame_test` | TARGETED TESTS PASSED |
| MIN-H | Enterable caves and underground environments (roof fade, NPC pathing, persistence) | `a659f42`, `e929446` | `underground_test` | TARGETED TESTS PASSED |
| MIN-G | 100/365-day multi-seed runs, saves, conservation, no resource spawning | `0aa425c` (results), `7e19008` (gate) | Actions 39692107077, seeds 1-4 x 365 days: leak 0, no item leak, 0 script errors, no FATAL (`docs/build17/MIN_G_LONG_RUNS.md`); determinism gate on `cd7439c` two runs identical | Register says NOT TESTED: **stale, proposed INTEGRATION VERIFIED** |
| B7-007 | Deposits never refill; no stone source | answered by MIN-B and MIN-D (`79afe00`, `b0506db`) | `quarry_test`, `discovery_test` | Register shows PARTIAL: **proposed INTEGRATED** (its note says "See EXP-A"; both parts are now built) |
| CON-01, CON-02 | Universal negotiated procurement contracts; service contracts (dig, survey) in the same engine | `daf08f3`, `02563a8`, `0954de3` | `contracts_test`, `contract_sign_test`, `services_test`, `contract_50ore_test` | TARGETED TESTS PASSED |
| JOB-01, REC-013, LOG-01, OD01-QUEST, SIM-B17 | Shared manor job board; need-based wear; delivery fallback; the fixed mine quest retired; SIM-01 practice | as in the register | `world_test`, `run_tests` | JOB-01, REC-013, OD01-QUEST, SIM-B17 INTEGRATION VERIFIED and RELEASED |
| B14-07, DVW-A10, DVW-A12, DVW-B4, PL1-12 | Cliff steps and walkways; no black-hole spaces; rules in `core/`; goods decay; red plant pickable | as in the register | `run_tests` | TARGETED TESTS PASSED |

Wiki: `game/scripts/core/wiki_mining.gd`, `wiki_mine_equipment.gd`, `wiki_stone.gd` on `ad281dc`; their "Not in the game yet"
lists (earth reuse, bigger pits, selling finds, contract advances, results pay, disputes, farm labour contracts, villagers hiring,
service signing) match the unimplemented records in section 4.

## 3. Partial

| Requirement | Done | Remaining |
|---|---|---|
| EXP-A (umbrella) | Phases A-G and MIN-H integrated and released | Umbrella closes with its children. **Proposed INTEGRATED / INTEGRATION VERIFIED**; the follow-ons in section 4 are separate records and do not hold the umbrella open |
| WDR-001-C (Rule 001 material interdependency) | Mining materials, equipment and recipes interlock; `tools/check_materials.py` report | Open violations listed in `docs/systems/MATERIAL_INTERDEPENDENCY.md`; not re-audited here |
| WDR-013-C (Rule 013 finite resources) | Finite seams and deposits, no regeneration (MIN-B/D) | The rule's verification scenario is not recorded as run; not re-audited here |
| WIKI-B17 | `0147066`, `3dcd583` closed the known gaps; `wiki_test` passes | "Remaining unknown: needs a human review" (register). Wiki has been revised in every later build; a Build-17-only review is probably obsolete (agent view, not a status change) |

## 4. Remaining approved work

None is authorized for implementation now. Each is owner-approved as direction but has target "owner decision" or "unassigned"
(no build placement), so its status is **DESIGN ONLY, NOT AUTHORIZED** until the owner places it:

| Requirement | Approved content | Source |
|---|---|---|
| PIT-02 | Larger, deeper open pits; strata; spiral and switchback ramps | MIN-E-Q5 answer, 2026-10-21 |
| EARTH-01 | Reuse of excavated earth (farmland, embankments, plot grading, earthworks, landscaping) as physical processes | MIN-E-Q1 answer, 2026-10-21 |
| INFO-01 | Sharing and selling prospecting information; no rights transfer | MIN-C-Q2 answer, 2026-10-21 |
| CON-02-KINDS, CON-03..CON-08 | Further service kinds; service advances; pay structures; protections and disputes; farm labour contracts; independent villager hiring; separate service signing threshold | `2026-10-21_build17_con01_final_decisions_service_contracts.md`; CON02-S-1..S-6; scheduling `2026-10-23_dp15_dp16_con02_empperm.md` ("a later build") |
| JOB-02, MAINT-01 | Offered compensation on the job board; need-driven maintenance and village expansion | REC-013 decisions 2026-10-21 |

## 5. Deferred and superseded

| Record | Status | Decision |
|---|---|---|
| ECON-P1.1 demand-driven mining, ECON-P1.2 manor mining rights/royalty/quota, ECON-P1.5 distant quarry | REJECTED (owner) | Agent proposals cancelled by the owner (`2026-10-21_build17_od01_final_decisions.md`; register history 2026-10-23 "CANCELED BY OWNER") |
| ECON-P1.4 prospecting new seams | SUPERSEDED | `superseded_by` MIN-C |
| MIN-L5 mining capability level 5 | Proposal only (PROPOSED, target 20+) | Spec s.3 and s.12: level 5 is a proposal pending validation |
| B17F-DEPLETE, B17F-PERF, B17F-SIMREPORT, B17F-FOOD, B17F-HENS, B17F-JOBS | Ideas (PROPOSED), not approved work | Owner 2026-10-22: noncritical Build 17 findings deferred to the appropriate backlog |

## 6. Outstanding owner decisions

- **WDR-003-C** (Rule 003 meaningful recipes): approval OWNER DECISION REQUIRED, next action "document each counted recipe's
  purpose". Unchanged.
- Build placement for PIT-02, EARTH-01, INFO-01, CON-02-KINDS, CON-03..08, JOB-02, MAINT-01 (section 4).
- MIN-G's old next action names "owner decision on the harness one-line fix"; no record of it exists in the register. Probably
  overtaken by later long-run tooling (agent view); listed so it is not lost.

## 7. Dependencies

Depends on the Build 16 baseline (released). Expansion 18 (settlement capability, SET-A) built on the capability schema MIN-D
introduced (`capabilities.json`); Expansion 20 (LE-05) uses mining as an economy input. Contracts (CON-01/02) are the universal
engine later used by Expansions 18 and 20.

## 8. Implementation and validation references

| Item | Reference |
|---|---|
| Integration branch | `wip/build17`; release `80e6b99` (game code `cd7439c`; `3dcd583` wiki wording) |
| Release | private draft "My Medieval Life Build 17", run 39706003658 (2026-10-22); CI Tests 39689213264 on `cd7439c`; Android signed with a throwaway key (pre-policy) |
| Long runs | Actions 39692107077 on `7e19008`, seeds 1-4 x 365 days (`docs/build17/MIN_G_LONG_RUNS.md`) |
| Packet | `docs/release/BUILD_17_PACKET.md` and the implementation notes `docs/build17/*` (on `origin/wip/expansion20` only, except MIN_G_LONG_RUNS) |
| Device | No platform tested on physical hardware; no owner device check recorded (not a gate: owner 2026-10-24) |

## 9. Next authorized phase

Expansion 17 itself is complete. Nothing in section 4 is authorized. The build sequence (owner, 2026-10-31): **Build 25** =
Expansion 20 validation and freeze; **Build 26** = repository recovery and consolidation; **Build 27** = Expansion 21, only if
the owner authorizes it. Any Expansion 17 follow-on needs the owner to place it in a build first.

## 10. Missing sources

None for Expansion 17. The specification (PDF and text) and all Build 17 directives are on staging; the Build 17 implementation
notes (`docs/build17/` except `MIN_G_LONG_RUNS.md`, `docs/release/BUILD_17_PACKET.md`) exist only on `origin/wip/expansion20`
(readable, not missing; to be consolidated in Build 26).
