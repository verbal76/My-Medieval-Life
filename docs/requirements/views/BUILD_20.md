# Build 20: Living Economy

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

Authority: owner directive 2026-10-23 (docs/directives/2026-10-23_expansion20_phase1_authorization.md): phase 1 only: LE-00 audit, registration, data contracts and isolated foundation components behind disabled hooks on wip/expansion20-preparation; no live economy, no merge to staging or main, no policy for open OD-LE decisions

Readiness: **IN DEVELOPMENT (not feature complete)**

| Count | Value |
|---|---|
| Approved requirements in scope | 9 |
| Integrated | 0 of 9 (0%) |
| Automated tests passed | 1 of 9 (11%) |
| Integration verified | 0 of 9 (0%) |
| Gameplay verified | 0 of 9 (0%) |
| Owner playtested | 0 of 9 (0%) |
| Complete | 0 of 9 (0%) |
| Open (release blockers) | 9 |
| Open owner decisions (blocking) | 14 (14) |

## Blocked (open owner decision, unfinished dependency or unsettled design) (9)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| E20-P1 | Expansion 20 phase 1: LE-00 audit, requirements registration and isolated LE-01 foundation (no live economy) | OWNER APPROVED | IMPLEMENTED ON TASK BRANCH | X20 foundation worker (Sonnet subagent) / wip/expansion20-preparation | TARGETED TESTS PASSED | owner reviews the architecture (LE00_BUILD18_REFRESH.md, LE01_DATA_CONTRACTS.md) and answers OD-LE-02, 04, 07, 10, 13, 15 | design: UNKNOWN | UNKNOWN |
| EMP-PERM-01 | Permanent employment by the player for production roles (miner at a mine, smith at a forge, carpenter, attendant, assigned production role) through the existing job-offer and wage systems, working on during normal simulation subject to real resources, equipment and wages | OWNER APPROVED | NOT STARTED | none | NOT TESTED | Build 20 (owner 2026-10-23); temporary contracts and workshop attendants do not complete it | design: UNKNOWN | UNKNOWN |
| LE-01 | Living Economy stage LE-01: Shared actor, need, offer, knowledge and contract model | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| LE-02 | Living Economy stage LE-02: Adaptive bids, asks, negotiation and settlement | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| LE-03 | Living Economy stage LE-03: Production, job choice and household budgets | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| LE-04 | Living Economy stage LE-04: Organic finance, merchants and manor behavior | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| LE-05 | Living Economy stage LE-05: Construction, ecology, mining, bandits and regional links | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| LE-06 | Living Economy stage LE-06: Multi-seed long-run, determinism and profiling | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| LE-07 | Living Economy stage LE-07: Release readiness and platform builds | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |

## Open owner decisions (14)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
| OD-LE-02 | Owner decision (Living Economy): Market board, direct negotiation or hybrid and visibility rules | OPEN | yes |  |
| OD-LE-03 | Owner decision (Living Economy): Wages, rents and service contracts in first release | OPEN | yes | ECON-P3.4 |
| OD-LE-04 | Owner decision (Living Economy): Business founding, partnerships, ownership and inheritance | OPEN | yes |  |
| OD-LE-05 | Owner decision (Living Economy): Loan interest, collateral, default and collection rules | OPEN | yes |  |
| OD-LE-06 | Owner decision (Living Economy): Permissible manor interventions and political authority | OPEN | yes |  |
| OD-LE-07 | Owner decision (Living Economy): Restricted-use advances and business/household account separation | OPEN | yes |  |
| OD-LE-08 | Owner decision (Living Economy): Barter, rental, repair and resource substitution | OPEN | yes |  |
| OD-LE-09 | Owner decision (Living Economy): Bandit market participation and regional trading limits | OPEN | yes |  |
| OD-LE-10 | Owner decision (Living Economy): Economic rumor, memory persistence and reliability | OPEN | yes |  |
| OD-LE-11 | Owner decision (Living Economy): Speculation, hoarding and deliberate market manipulation | OPEN | yes |  |
| OD-LE-12 | Owner decision (Living Economy): Charity, kinship support and communal relief | OPEN | yes |  |
| OD-LE-13 | Owner decision (Living Economy): Contract cancellation, penalties and death of a party | OPEN | yes |  |
| OD-LE-14 | Owner decision (Living Economy): Player intervention and visibility of market decisions | OPEN | yes |  |
| OD-LE-15 | Owner decision (Living Economy): Performance and population acceptance targets | OPEN | yes |  |

## Not counted: umbrellas, proposals, ideas, deferred (3)

| ID | Item | Kind | Approval |
|---|---|---|---|
| ECON-P3.3 | Stock targets in days of sales (agent proposal P3.3, docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md line 185) | proposal | PROPOSED |
| ECON-P3.4 | Hire wages from the market quote (agent proposal P3.4, docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md line 186) | proposal | PROPOSED |
| EXP-D | Living Economy Expansion: needs-driven economic architecture (needs, offers, adaptive prices, contracts, reservations, credit, bounded knowledge, organic safety levers) across households, employment, production, construction, markets, caravans, mining, the manor, bandits and NPC decisions; its OWN standalone build | umbrella | OWNER APPROVED |

