# Work queues

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

## Workers and task branches (35)

| ID | Build | Status | Worker | Branch |
|---|---|---|---|---|
| ARMOR-01 | 18 | IMPLEMENTED ON TASK BRANCH | worker B (interface) | wip/b22-ui |
| ARMOR-CATALOG-01 | 20 | IN DEVELOPMENT | worker D (gear) | wip/b22-gear |
| ARMOR-MATERIALS-01 | 20 | IN DEVELOPMENT | worker D (gear) | wip/b22-gear |
| E20-P1 | 20 | IMPLEMENTED ON TASK BRANCH | X20 foundation worker (Sonnet subagent) | wip/expansion20-preparation |
| E22-P1 | 22 | IMPLEMENTED ON TASK BRANCH | lead | staging/my-medieval-life |
| E23-BANA | 23 | IMPLEMENTED ON TASK BRANCH | lead | staging/my-medieval-life |
| FIX-D1D2 | 20 | IMPLEMENTED ON TASK BRANCH | repair workers (Sonnet subagents) | wip/expansion19-preparation, wip/expansion20-preparation |
| GP-BASELINE-POLICY | multiplayer | IMPLEMENTED ON TASK BRANCH | primary development agent | wip/multiplayer-b19 |
| GP-BUSINESS-COURIER | 20 | IMPLEMENTED ON TASK BRANCH | worker A (market) | wip/b22-market |
| GP-BUSINESS-DESK | 20 | IMPLEMENTED ON TASK BRANCH | worker A (market) | wip/b22-market |
| GP-CHECKPOINT-1 | multiplayer | IMPLEMENTED ON TASK BRANCH | primary development agent | wip/multiplayer-b19 |
| GP-FARMER-TENDING | 20 | IMPLEMENTED ON TASK BRANCH | worker C (family and farming) | wip/b22-family |
| GP-LOCKPICK | 20 | IMPLEMENTED ON TASK BRANCH | worker B (interface) | wip/b22-ui |
| GP-MARKET-SPACING | 20 | IMPLEMENTED ON TASK BRANCH | worker A (market) | wip/b22-market |
| GP-MINE-WOOD-FRAME | 20 | IMPLEMENTED ON TASK BRANCH | worker B (interface) | wip/b22-ui |
| GP-QTY-PICKER-CONTROLLER | 20 | IMPLEMENTED ON TASK BRANCH | worker B (interface) | wip/b22-ui |
| GP-SKILLS-RT | 20 | IMPLEMENTED ON TASK BRANCH | worker B (interface) | wip/b22-ui |
| GP-STALL-RENT-WRONG-PITCH | 20 | IMPLEMENTED ON TASK BRANCH | worker A (market) | wip/b22-market |
| GP-TABLE-ITEMS | 20 | IMPLEMENTED ON TASK BRANCH | worker A (market) | wip/b22-market |
| GP-WANTED-INDICATOR | 20 | IMPLEMENTED ON TASK BRANCH | worker B (interface) | wip/b22-ui |
| GP-WIKI-RECIPE-TOOLS | 20 | IMPLEMENTED ON TASK BRANCH | worker B (interface) | wip/b22-ui |
| ID-01 | unassigned | IN DEVELOPMENT | identity worker 2 (Sonnet subagent) | wip/foundation-identity |
| LE-00 | 20+ | IMPLEMENTED ON TASK BRANCH | lead | wip/expansion20-preparation |
| MP-01 | multiplayer | IMPLEMENTED ON TASK BRANCH | none | wip/multiplayer |
| MP-PLAYER-FAMILY | 20 | IMPLEMENTED ON TASK BRANCH | worker C (family and farming) | wip/b22-family |
| P21-00 | 21 | IMPLEMENTED ON TASK BRANCH | lead | wip/expansion21-preparation |
| P21-01 | 21 | IMPLEMENTED ON TASK BRANCH | X21 foundation worker (Sonnet subagent) | wip/expansion21-preparation |
| P21-02 | 21 | IMPLEMENTED ON TASK BRANCH | lead | wip/expansion21-preparation |
| REC-19 | 20 | IN DEVELOPMENT | recorder worker (Sonnet subagent) | wip/recorder |
| REC-DIAG | 20 | IN DEVELOPMENT | lead | wip/recorder (read-only runs) |
| RECON-01 | unassigned | IMPLEMENTED ON TASK BRANCH | reconciliation worker (Sonnet subagent) | wip/expansion19-preparation, wip/expansion20-preparation |
| ROAD-03 | owner decision | IMPLEMENTED ON TASK BRANCH | none |  |
| WEAPON-CATALOG-01 | 20 | IN DEVELOPMENT | worker D (gear) | wip/b22-gear |
| WEAPON-VISIBLE-01 | 20 | IN DEVELOPMENT | worker D (gear) | wip/b22-gear |
| XAUDIT-01 | unassigned | IMPLEMENTED ON TASK BRANCH | lead | staging/my-medieval-life |

## Implemented but not tested (47)

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
| DVW-B1 | 20 | PARTIALLY IMPLEMENTED |  |
| E22-P1 | 22 | IMPLEMENTED ON TASK BRANCH |  |
| E23-BANA | 23 | IMPLEMENTED ON TASK BRANCH |  |
| EQ-05 | 16 | PARTIALLY IMPLEMENTED |  |
| FARM-08 | 16 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| FSE-00 | 16 | INTEGRATED | closure review against its acceptance criteria (human review) |
| LE-00 | 20+ | IMPLEMENTED ON TASK BRANCH |  |
| MIN-G | 17 | INTEGRATED |  |
| MP-01 | multiplayer | IMPLEMENTED ON TASK BRANCH |  |
| OWN-08 | owner decision | PARTIALLY IMPLEMENTED |  |
| OWN-19 | 20+ | PARTIALLY IMPLEMENTED |  |
| OWN-22 | owner decision | PARTIALLY IMPLEMENTED |  |
| OWN-28 | 20+ | PARTIALLY IMPLEMENTED |  |
| P21-00 | 21 | IMPLEMENTED ON TASK BRANCH |  |
| P21-02 | 21 | IMPLEMENTED ON TASK BRANCH |  |
| PERF-01 | 15 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| PL1-07 | 20+ | PARTIALLY IMPLEMENTED |  |
| PL1-11 | owner decision | PARTIALLY IMPLEMENTED | stages after 1 (Google Drive cloud saves) need the owner's decision (network/paid-service rule, CLAUDE.md section 11) |
| PL1-13 | 20+ | PARTIALLY IMPLEMENTED |  |
| PL2-008 | 18 | INTEGRATED | Checks and owner playtest only (B18-DP-02/03); no NPC module expansion, no module signs |
| PL2-010 | 20+ | PARTIALLY IMPLEMENTED |  |
| PL2-013 | 20+ | PARTIALLY IMPLEMENTED |  |
| PL2-014 | 18 | INTEGRATED | Checks and owner playtest only (B18-DP-02/03); no NPC module expansion, no module signs |
| REC-003 | 15 | PARTIALLY IMPLEMENTED | owner confirms the policy (then CLAUDE.md section 8); aapt2 dump badging on a built APK |
| ROAD-03 | owner decision | IMPLEMENTED ON TASK BRANCH |  |
| SET-C | 18 | PARTIALLY IMPLEMENTED | Close-out (docs/expansion18/CLOSEOUT_SET_A_B_C_WDR002.md): 10 MET, 1 PARTIAL (credit parity, in progress), 1 NOT MET (100- and 365-day multi-seed and multi-generation runs of the integrated game; to run with REL18-LONGRUN on the final code) |
| WDR-001-C | 17 | PARTIALLY IMPLEMENTED |  |
| WDR-009-C | 20 | PARTIALLY IMPLEMENTED |  |
| WDR-010-C | 15 | PARTIALLY IMPLEMENTED |  |
| WDR-013-C | 17 | PARTIALLY IMPLEMENTED |  |
| WDR-015-C | 20+ | PARTIALLY IMPLEMENTED |  |
| WDR-018-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-020-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-021-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-022-C | 15 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| WIKI-B17 | 17 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| XAUDIT-01 | unassigned | IMPLEMENTED ON TASK BRANCH |  |

## Awaiting owner playtest or device check (79)

| ID | Build | Verification | Needs |
|---|---|---|---|
| B13-12 | 15 | TARGETED TESTS PASSED | controller |
| B13-13 | 15 | TARGETED TESTS PASSED | phone |
| B14-01 | 15 | TARGETED TESTS PASSED | controller |
| B14-06 | 15 | TARGETED TESTS PASSED | phone |
| B14-11 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| B14-13 | 15 | TARGETED TESTS PASSED | phone, controller |
| B21-LAN-PLAYTEST | multiplayer | INTEGRATION VERIFIED | L, A, N,  , p, l, a, y,  , o, n,  , r, e, a, l,  , d, e, v, i, c, e, s,  , (, P, C,  , h, o, s, t, ,,  , A, n, d, r, o, i, d,  , g, u, e, s, t, ;,  , W, i, n, d, o, w, s,  , F, i, r, e, w, a, l, l,  , U, D, P,  , 4, 7, 8, 1, 0, /, 4, 7, 8, 1, 1, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
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
| GP-ACTIONBAR | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-ANVIL | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-BACK-DOORS | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-BANDIT-CAMP-ART | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-CRIME-PURSUIT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-DIALOGUE-PERSPECTIVE | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-DRAW-UNDER-HOUSE | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-GIFT-QUANTITY | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-GOSSIP-NATURAL | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-HARVEST-CONT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-INPUT-CONSIST | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-INTERIOR-WALLS | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-JOYSTICK | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-MARKET-SHELVES | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-PACK-DETAIL-FIT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-PAUSE-PANEL | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-PICKAXE-ANIM | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-PROPERTY-NAME-DOUBLE | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-REPAIR-SOCIAL | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-SHARPEN | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-SMITHY-WORKBENCH | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-STALL-PRICE-ON-PUTUP | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-START-RUSTY-AXE | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-TARGET-ART-MATCH | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-TRAIL-EDGES | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-UI-COMPACT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-WHEAT-PICKED | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-WIKI-LAYOUT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
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
