# Work queues

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

## Workers and task branches (8)

| ID | Build | Status | Worker | Branch |
|---|---|---|---|---|
| ECON-P3 | 18 | IN DEVELOPMENT | household-money worker (Sonnet subagent, started 2026-10-23) | wip/b18-econp3 |
| MIGRATE-18 | 18 | IN DEVELOPMENT | migration worker (Sonnet subagent, started 2026-10-23) | wip/b18-migration |
| MP-01 | multiplayer | IMPLEMENTED ON TASK BRANCH | none | wip/multiplayer |
| SJD-B | 19 | IMPLEMENTED ON TASK BRANCH | none | wip/expansion19-preparation |
| SJD-C | 19 | IMPLEMENTED ON TASK BRANCH | none | wip/expansion19-preparation |
| SJD-D | 19 | IMPLEMENTED ON TASK BRANCH | none | wip/expansion19-preparation |
| TRADE-CREDIT | 18 | IN DEVELOPMENT | credit-parity worker (Sonnet subagent, started 2026-10-23) | wip/b18-creditparity |
| X18-SIM | 18 | IN DEVELOPMENT | capability-sim worker (Sonnet subagent, started 2026-10-23) | wip/b18-capsim |

## Implemented but not tested (48)

| ID | Build | Implementation | Remaining |
|---|---|---|---|
| AR-P1-2 | owner action | PARTIALLY IMPLEMENTED |  |
| B14-10 | 20+ | PARTIALLY IMPLEMENTED |  |
| B16-AUDIT | 16 | INTEGRATED | closure review against its acceptance criteria (human review) |
| B16-READY | 16 | INTEGRATED | closure review against its acceptance criteria (human review) |
| B7-009 | 15 | INTEGRATED |  |
| B7-014 | 15 | INTEGRATED |  |
| B8-007 | 20+ | PARTIALLY IMPLEMENTED |  |
| DVW-A13 | 20+ | PARTIALLY IMPLEMENTED |  |
| DVW-A14 | 15 | INTEGRATED |  |
| DVW-A3 | 16 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| DVW-B1 | 19 | PARTIALLY IMPLEMENTED |  |
| EQ-05 | 16 | PARTIALLY IMPLEMENTED |  |
| FARM-08 | 16 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| FSE-00 | 16 | INTEGRATED | closure review against its acceptance criteria (human review) |
| MIN-G | 17 | INTEGRATED |  |
| MP-01 | multiplayer | IMPLEMENTED ON TASK BRANCH |  |
| OWN-08 | owner decision | PARTIALLY IMPLEMENTED |  |
| OWN-19 | 20+ | PARTIALLY IMPLEMENTED |  |
| OWN-22 | owner decision | PARTIALLY IMPLEMENTED |  |
| OWN-28 | 20+ | PARTIALLY IMPLEMENTED |  |
| PERF-01 | 15 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| PL1-07 | 20+ | PARTIALLY IMPLEMENTED |  |
| PL1-10 | 18 | PARTIALLY IMPLEMENTED |  |
| PL1-11 | owner decision | PARTIALLY IMPLEMENTED | stages after 1 (Google Drive cloud saves) need the owner's decision (network/paid-service rule, CLAUDE.md section 11) |
| PL1-13 | 20+ | PARTIALLY IMPLEMENTED |  |
| PL2-008 | 18 | PARTIALLY IMPLEMENTED |  |
| PL2-010 | 20+ | PARTIALLY IMPLEMENTED |  |
| PL2-013 | 20+ | PARTIALLY IMPLEMENTED |  |
| PL2-014 | 18 | PARTIALLY IMPLEMENTED |  |
| PL2-015 | 18 | PARTIALLY IMPLEMENTED |  |
| REC-003 | 15 | PARTIALLY IMPLEMENTED | owner confirms the policy (then CLAUDE.md section 8); aapt2 dump badging on a built APK |
| SET-A | 18 | PARTIALLY IMPLEMENTED | close-out against the specification's acceptance criteria |
| SET-B | 18 | PARTIALLY IMPLEMENTED | close-out against the specification's acceptance criteria |
| SET-C | 18 | PARTIALLY IMPLEMENTED | lands with SET-C-SIM and SET-C-FIVE |
| WDR-001-C | 17 | PARTIALLY IMPLEMENTED |  |
| WDR-002-C | 18 | PARTIALLY IMPLEMENTED |  |
| WDR-004-C | 18 | PARTIALLY IMPLEMENTED |  |
| WDR-009-C | 19 | PARTIALLY IMPLEMENTED |  |
| WDR-010-C | 15 | PARTIALLY IMPLEMENTED |  |
| WDR-012-C | 18 | PARTIALLY IMPLEMENTED |  |
| WDR-013-C | 17 | PARTIALLY IMPLEMENTED |  |
| WDR-015-C | 20+ | PARTIALLY IMPLEMENTED |  |
| WDR-018-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-020-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-021-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-022-C | 15 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| WIKI-B17 | 17 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| X18-Q12 | 18 | PARTIALLY IMPLEMENTED | wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL) |

## Awaiting owner playtest or device check (51)

| ID | Build | Verification | Needs |
|---|---|---|---|
| ARMOR-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| B13-12 | 15 | TARGETED TESTS PASSED | controller |
| B13-13 | 15 | TARGETED TESTS PASSED | phone |
| B14-01 | 15 | TARGETED TESTS PASSED | controller |
| B14-06 | 15 | TARGETED TESTS PASSED | phone |
| B14-11 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| B14-13 | 15 | TARGETED TESTS PASSED | phone, controller |
| B7-001 | 15 | TARGETED TESTS PASSED | phone |
| B7-005 | 15 | TARGETED TESTS PASSED | phone |
| B7-010 | 15 | TARGETED TESTS PASSED | phone |
| B7-011 | 15 | TARGETED TESTS PASSED | phone |
| B7-012 | 15 | TARGETED TESTS PASSED | phone, controller |
| B7-013 | 15 | TARGETED TESTS PASSED | phone |
| B8-018 | 15 | TARGETED TESTS PASSED | windows |
| BANDIT-RETURN | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| BARBER-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| CC-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| CON-UX-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| CQ-01 | 15 | TARGETED TESTS PASSED | phone, controller |
| DVW-B8 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| FARM-09 | 16 | TARGETED TESTS PASSED | Touch drag on an Android phone, Physical gamepad |
| FARM-CROP-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| FARM-CROP-SEED | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| FR-04 | 15 | TARGETED TESTS PASSED | a controller: D-pad up opens the Journal, left stick press opens Build |
| INV-18 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| MAP-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| ORE-PLACE-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| PL1-03 | 15 | TARGETED TESTS PASSED | phone |
| PL1-05 | 15 | TARGETED TESTS PASSED | phone |
| Q-04 | 15 | TARGETED TESTS PASSED | phone |
| ROOMS-18 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| SAVE-05 | 15 | TARGETED TESTS PASSED | Android phone: export, uninstall, install a new build, import, continue the same world |
| SKILL-TRADES-18 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| STONE-05 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| TAILOR-18 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| TRADE-AXE-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| TRADE-UI-02 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| UI-HUD-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| UI-HUNGER-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| UI-PROGRESS-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| UI-WIKI-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| VIS-ANIMAL-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| VIS-AXE-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| VIS-CROP-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| VIS-DOOR-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| VIS-STEPS-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| VIS-TREE-02 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| WDR-008-C | 15 | TARGETED TESTS PASSED | phone, controller |
| WORLD-LIFE-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| X18-CAPCOMP | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| X18-CAPNUM | 18 | INTEGRATION VERIFIED | owner playtest on a device |
