# Work queues

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

## Workers and task branches (14)

| ID | Build | Status | Worker | Branch |
|---|---|---|---|---|
| E22-P1 | 22 | IMPLEMENTED ON TASK BRANCH | lead | staging/my-medieval-life |
| E23-BANA | 23 | IMPLEMENTED ON TASK BRANCH | lead | staging/my-medieval-life |
| GP-BASELINE-POLICY | multiplayer | IMPLEMENTED ON TASK BRANCH | primary development agent | wip/multiplayer-b19 |
| GP-CHECKPOINT-1 | multiplayer | IMPLEMENTED ON TASK BRANCH | primary development agent | wip/multiplayer-b19 |
| ID-01 | unassigned | IN DEVELOPMENT | identity worker 2 (Sonnet subagent) | wip/foundation-identity |
| LE-00 | 20+ | IMPLEMENTED ON TASK BRANCH | lead | wip/expansion20-preparation |
| MP-01 | multiplayer | IMPLEMENTED ON TASK BRANCH | none | wip/multiplayer |
| MP-INTERACT-01 | 20 | IMPLEMENTED ON TASK BRANCH | worker K (multiplayer interaction) | wip/x20-mp-interact |
| P21-00 | 21 | IMPLEMENTED ON TASK BRANCH | lead | wip/expansion21-preparation |
| P21-01 | 21 | IMPLEMENTED ON TASK BRANCH | X21 foundation worker (Sonnet subagent) | wip/expansion21-preparation |
| P21-02 | 21 | IMPLEMENTED ON TASK BRANCH | lead | wip/expansion21-preparation |
| REC-DIAG | 20 | IN DEVELOPMENT | lead | wip/recorder (read-only runs) |
| ROAD-03 | owner decision | IMPLEMENTED ON TASK BRANCH | none |  |
| XAUDIT-01 | unassigned | IMPLEMENTED ON TASK BRANCH | lead | staging/my-medieval-life |

## Implemented but not tested (45)

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
| WDR-010-C | 15 | PARTIALLY IMPLEMENTED |  |
| WDR-013-C | 17 | PARTIALLY IMPLEMENTED |  |
| WDR-015-C | 20+ | PARTIALLY IMPLEMENTED |  |
| WDR-018-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-020-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-021-C | unassigned | PARTIALLY IMPLEMENTED | compliance audit against the rule's verification scenario (human review) |
| WDR-022-C | 15 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| WIKI-B17 | 17 | PARTIALLY IMPLEMENTED | unknown: needs a human review of what remains |
| XAUDIT-01 | unassigned | IMPLEMENTED ON TASK BRANCH |  |

## Awaiting owner playtest or device check (103)

| ID | Build | Verification | Needs |
|---|---|---|---|
| ARMOR-01 | 18 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, A, n, d, r, o, i, d,  , t, o, u, c, h, ,,  , c, o, n, t, r, o, l, l, e, r, ,,  , t, w, o, -, d, e, v, i, c, e,  , p, l, a, y,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ) |
| ARMOR-CATALOG-01 | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g, ;,  , v, a, l, u, e, s,  , p, r, o, v, i, s, i, o, n, a, l,  , f, o, r,  , t, h, e,  , o, w, n, e, r, ', s,  , r, e, v, i, e, w,  , (, t, h, e,  , a, r, m, o, u, r,  , a, n, d,  , w, e, a, p, o, n,  , c, a, t, a, l, o, g, u, e,  , t, a, b, l, e,  , o, n,  , w, i, p, /, b, u, i, l, d, 2, 2, ) |
| ARMOR-MATERIALS-01 | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g, ;,  , v, a, l, u, e, s,  , p, r, o, v, i, s, i, o, n, a, l,  , f, o, r,  , t, h, e,  , o, w, n, e, r, ', s,  , r, e, v, i, e, w,  , (, t, h, e,  , a, r, m, o, u, r,  , a, n, d,  , w, e, a, p, o, n,  , c, a, t, a, l, o, g, u, e,  , t, a, b, l, e,  , o, n,  , w, i, p, /, b, u, i, l, d, 2, 2, ) |
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
| GP-ANDROID-ACTION-BUTTONS | 20 | INTEGRATION VERIFIED | r, e, a, l,  , p, h, o, n, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, t, h, u, m, b,  , c, o, m, f, o, r, t, ,,  , e, d, g, e,  , g, a, p,  , b, y,  , t, h, e,  , c, a, m, e, r, a,  , c, u, t, o, u, t, ,,  , l, e, g, i, b, i, l, i, t, y, ,,  , o, u, t, l, i, n, e,  , v, i, s, i, b, i, l, i, t, y,  , i, n,  , d, a, y, l, i, g, h, t, ,,  , N, e, x, t,  , b, u, t, t, o, n, ) |
| GP-ANDROID-HUD-SCALE | 20 | INTEGRATION VERIFIED | r, e, a, l,  , p, h, o, n, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, t, h, u, m, b,  , c, o, m, f, o, r, t, ,,  , e, d, g, e,  , g, a, p,  , b, y,  , t, h, e,  , c, a, m, e, r, a,  , c, u, t, o, u, t, ,,  , l, e, g, i, b, i, l, i, t, y, ,,  , o, u, t, l, i, n, e,  , v, i, s, i, b, i, l, i, t, y,  , i, n,  , d, a, y, l, i, g, h, t, ,,  , N, e, x, t,  , b, u, t, t, o, n, ) |
| GP-ANDROID-RECENTER | 20 | INTEGRATION VERIFIED | r, e, a, l,  , p, h, o, n, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, t, h, u, m, b,  , c, o, m, f, o, r, t, ,,  , e, d, g, e,  , g, a, p,  , b, y,  , t, h, e,  , c, a, m, e, r, a,  , c, u, t, o, u, t, ,,  , l, e, g, i, b, i, l, i, t, y, ,,  , o, u, t, l, i, n, e,  , v, i, s, i, b, i, l, i, t, y,  , i, n,  , d, a, y, l, i, g, h, t, ,,  , N, e, x, t,  , b, u, t, t, o, n, ) |
| GP-ANDROID-USE-TALK-TARGETING | 20 | INTEGRATION VERIFIED | r, e, a, l,  , p, h, o, n, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, t, h, u, m, b,  , c, o, m, f, o, r, t, ,,  , e, d, g, e,  , g, a, p,  , b, y,  , t, h, e,  , c, a, m, e, r, a,  , c, u, t, o, u, t, ,,  , l, e, g, i, b, i, l, i, t, y, ,,  , o, u, t, l, i, n, e,  , v, i, s, i, b, i, l, i, t, y,  , i, n,  , d, a, y, l, i, g, h, t, ,,  , N, e, x, t,  , b, u, t, t, o, n, ) |
| GP-ANVIL | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-BACK-DOORS | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-BANDIT-CAMP-ART | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-BUSINESS-COURIER | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g |
| GP-BUSINESS-DESK | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g |
| GP-CRIME-PURSUIT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-DIALOGUE-PERSPECTIVE | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-DRAW-UNDER-HOUSE | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-FARMER-TENDING | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, p, h, o, n, e,  , v, i, e, w, ) |
| GP-GIFT-QUANTITY | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-GOSSIP-NATURAL | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-HARVEST-CONT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-INPUT-CONSIST | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-INTERACTABLE-OUTLINES | 20 | INTEGRATION VERIFIED | r, e, a, l,  , p, h, o, n, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, t, h, u, m, b,  , c, o, m, f, o, r, t, ,,  , e, d, g, e,  , g, a, p,  , b, y,  , t, h, e,  , c, a, m, e, r, a,  , c, u, t, o, u, t, ,,  , l, e, g, i, b, i, l, i, t, y, ,,  , o, u, t, l, i, n, e,  , v, i, s, i, b, i, l, i, t, y,  , i, n,  , d, a, y, l, i, g, h, t, ,,  , N, e, x, t,  , b, u, t, t, o, n, ) |
| GP-INTERACTION-PROMPT-LIFECYCLE | 20 | INTEGRATION VERIFIED | r, e, a, l,  , p, h, o, n, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, t, h, u, m, b,  , c, o, m, f, o, r, t, ,,  , e, d, g, e,  , g, a, p,  , b, y,  , t, h, e,  , c, a, m, e, r, a,  , c, u, t, o, u, t, ,,  , l, e, g, i, b, i, l, i, t, y, ,,  , o, u, t, l, i, n, e,  , v, i, s, i, b, i, l, i, t, y,  , i, n,  , d, a, y, l, i, g, h, t, ,,  , N, e, x, t,  , b, u, t, t, o, n, ) |
| GP-INTERIOR-WALLS | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-JOYSTICK | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-LOCKPICK | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, A, n, d, r, o, i, d,  , t, o, u, c, h, ,,  , c, o, n, t, r, o, l, l, e, r, ,,  , t, w, o, -, d, e, v, i, c, e,  , p, l, a, y,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ) |
| GP-MARKET-SHELVES | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-MARKET-SPACING | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g |
| GP-MINE-WOOD-FRAME | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, A, n, d, r, o, i, d,  , t, o, u, c, h, ,,  , c, o, n, t, r, o, l, l, e, r, ,,  , t, w, o, -, d, e, v, i, c, e,  , p, l, a, y,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ) |
| GP-PACK-DETAIL-FIT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-PAUSE-PANEL | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-PICKAXE-ANIM | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-PROPERTY-NAME-DOUBLE | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-QTY-PICKER-CONTROLLER | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, A, n, d, r, o, i, d,  , t, o, u, c, h, ,,  , c, o, n, t, r, o, l, l, e, r, ,,  , t, w, o, -, d, e, v, i, c, e,  , p, l, a, y,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ) |
| GP-REPAIR-SOCIAL | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-SHARPEN | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-SKILLS-RT | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, A, n, d, r, o, i, d,  , t, o, u, c, h, ,,  , c, o, n, t, r, o, l, l, e, r, ,,  , t, w, o, -, d, e, v, i, c, e,  , p, l, a, y,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ) |
| GP-SMITHY-WORKBENCH | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-STALL-PRICE-ON-PUTUP | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-STALL-RENT-WRONG-PITCH | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g |
| GP-START-RUSTY-AXE | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-TABLE-ITEMS | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g |
| GP-TARGET-ART-MATCH | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-TRAIL-EDGES | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-UI-COMPACT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-WANTED-INDICATOR | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, A, n, d, r, o, i, d,  , t, o, u, c, h, ,,  , c, o, n, t, r, o, l, l, e, r, ,,  , t, w, o, -, d, e, v, i, c, e,  , p, l, a, y,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ) |
| GP-WHEAT-PICKED | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-WIKI-LAYOUT | 20 | INTEGRATION VERIFIED | d, e, v, i, c, e,  , c, h, e, c, k,  , (, A, n, d, r, o, i, d,  , p, h, o, n, e, ;,  , P, C,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ),  , n, o, t,  , y, e, t,  , d, o, n, e |
| GP-WIKI-RECIPE-TOOLS | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, A, n, d, r, o, i, d,  , t, o, u, c, h, ,,  , c, o, n, t, r, o, l, l, e, r, ,,  , t, w, o, -, d, e, v, i, c, e,  , p, l, a, y,  , w, h, e, r, e,  , i, t,  , a, p, p, l, i, e, s, ) |
| INV-18 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| MAP-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| MP-PLAYER-FAMILY | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g,  , (, t, w, o, -, d, e, v, i, c, e,  , m, a, r, r, i, a, g, e, ,,  , b, i, r, t, h,  , a, n, d,  , a, d, o, p, t, i, o, n,  , o, v, e, r,  , W, i, -, F, i, ) |
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
| WEAPON-CATALOG-01 | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g, ;,  , v, a, l, u, e, s,  , p, r, o, v, i, s, i, o, n, a, l,  , f, o, r,  , t, h, e,  , o, w, n, e, r, ', s,  , r, e, v, i, e, w,  , (, t, h, e,  , a, r, m, o, u, r,  , a, n, d,  , w, e, a, p, o, n,  , c, a, t, a, l, o, g, u, e,  , t, a, b, l, e,  , o, n,  , w, i, p, /, b, u, i, l, d, 2, 2, ) |
| WEAPON-VISIBLE-01 | 20 | TARGETED TESTS PASSED | r, e, a, l,  , d, e, v, i, c, e,  , c, h, e, c, k,  , o, u, t, s, t, a, n, d, i, n, g, ;,  , v, a, l, u, e, s,  , p, r, o, v, i, s, i, o, n, a, l,  , f, o, r,  , t, h, e,  , o, w, n, e, r, ', s,  , r, e, v, i, e, w,  , (, t, h, e,  , a, r, m, o, u, r,  , a, n, d,  , w, e, a, p, o, n,  , c, a, t, a, l, o, g, u, e,  , t, a, b, l, e,  , o, n,  , w, i, p, /, b, u, i, l, d, 2, 2, ) |
| WORLD-LIFE-01 | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| X18-CAPCOMP | 18 | INTEGRATION VERIFIED | owner playtest on a device |
| X18-CAPNUM | 18 | INTEGRATION VERIFIED | owner playtest on a device |
