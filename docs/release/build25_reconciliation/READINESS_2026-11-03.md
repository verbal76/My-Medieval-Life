# Build 25 readiness assessment (2026-11-03)

- **Requested by:** the owner on 2026-11-03, as a factual status report.
- **Sources:**
  - the register (`docs/requirements/requirements.json`);
  - the branches `wip/expansion20` (`4b51c92`) and `wip/region-nav` (`add1651`, then S3a at `6c88df0`);
  - GitHub Actions;
  - `BUILD25_CLOSURE_2026-11-02.md`.

Scope: B25-SCOPE-D1, plus B25-SCOPE-REGION, which makes REGION-NAV-01 mandatory.

## Progress (register counts, 152 approved Build 25 requirements, excluding not-applicable)

| Measure | Count | Share |
|---|---|---|
| Implemented (integrated or on a task branch) | 129 | 85 % |
| Integrated into `wip/expansion20` | 124 | 82 % |
| Integration-verified | 65 | 43 % |
| At least targeted tests passed | 113 | 74 % |

Counts are not effort. REGION-NAV-01 is one record but about 60 % of the remaining development. Weighted by effort (a lead
estimate, not a count), Build 25 is about **60 % complete**.

**Register lags the code:**
- B25-CAREER-IMPL is in the code (`265ddc1`) but still marked NOT STARTED.
- REGION-NAV-01's stages are tracked in its history, not as child records.

## Regional economy stages (REGION-NAV-01)

| Stage | Status | Commit and evidence |
|---|---|---|
| S1a Settlements in the overworld | Done | `2745f2f` |
| S1b Discovery, explored ground, Region map | Done | `3fd24e2`; atlas 17/0 |
| S2a A building per trade | Done | `909b180` |
| S2b Named keepers, trade through the courier edge | Done | `8a57974`; settlement_folk 21/0 |
| S2c Keepers drawn, talk window, wiki | Done | `add1651`; wiki_test passes; screenshots looked at |
| S3a Roads out of settlements, routes to all settlements, a cache-key defect fixed | Done | `6c88df0`; overworld 179/0, countryside 38/0 |
| S3b Villager journeys | In test | — |
| S4 Envoys | Not started | — |
| S5 Information network | Not started | — |
| S6 Villagers' trade between villages | Not started | — |
| S7 Regional demand and founding | Not started | — |
| S8 Measurements and performance | Not started | — |

## Evidence

| Evidence | Where | Result |
|---|---|---|
| Full CI | Tests 41509578455 on `0d194c8` | Green |
| 20 targeted suites | `4b51c92`, local | 0 failures (run_tests 3,602) |
| Seed 1 smoke and seed 2 replay | `4b51c92`, local | Clean |
| Farming B1/B2 | `8acbdea`, CI | Food-secure |
| Flight 41469410306 | `8acbdea`, CI | Seed 1 clean; seed 2's defect since fixed |
| Running | Flight 41536805310 and economy-on 41536810831, `4b51c92` | Baseline evidence only; the regional code needs one final consolidated campaign |

## Packaging

- **Technical blockers: none known.** `release.yml` is unchanged since Build 24, and the permanent signing identity is in place.
- **Release blockers:**
  - REGION-NAV-01 S3b-S8;
  - LE-07 gates 1, 4, 6, 9 and 11, and the economy activation;
  - the maturation report;
  - the X20-MERGED-VALIDATION rerun;
  - the owner decisions (B25-ECON-P1..P5, the phone pass mark, the never-placed approvals, BRANCH-POL-Q1);
  - the owner's release authorization.

## Estimates (hours of agent work; one worker; MML second priority)

| Area | Optimistic | Realistic | Conservative |
|---|---|---|---|
| Development | 50 | 70 | 100 |
| Integration | 6 | 10 | 16 |
| Validation (plus 4-6 h of GitHub runner time) | 8 | 14 | 24 |
| Packaging | 2 | 3 | 5 |

**Earliest complete playtest package:** about 2026-11-17 realistically, 2026-11-11 optimistically, early December
conservatively.

**Critical path:**
1. S3b, then S4, S5, S6, S7 and S8;
2. merge and full CI;
3. the consolidated campaign;
4. the LE-07 gates and activation;
5. packaging, on the owner's authorization.

**In parallel:** owner decisions, reading the running campaigns, the owner's device test.
