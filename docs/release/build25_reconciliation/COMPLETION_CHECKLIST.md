# Build 25 fixed completion checklist (B25-FINISH-01)

- **Directive:** `docs/directives/2026-11-03_build25_completion_directive.md`, owner, 2026-11-03.
- **Checklist written:** 2026-11-02 21:35 EST. Each item's status is updated in place, with the time of each update.
- **Sources:** the register (`docs/requirements/requirements.json`, 169 approved Build 25 records), `BUILD25_CLOSURE_2026-11-02.md`,
  `REGION_NAV_WORK_PACKAGES.md`, `CAMPAIGN_4b51c92_2026-11-03.md`, `docs/expansion20/LE07_GATE_STATUS.md`, the branches and
  GitHub Actions.
- **Register numbering:** Build 25 is the consolidation build. Its records are `target_build` 20 (Expansion 20) plus
  `B25-*`, `FR-*` and `REGION-NAV-*` (closure audit, note on numbering).
- **The finish line:** the items below. Nothing approved is left out. Items outside Build 25 are listed in section G, with the
  record that places them elsewhere.

**Branches:**
- **Integration:** `wip/expansion20`, head `4b51c92` (2026-11-02 21:39 UTC), the tested baseline.
- **Regional work:** `wip/region-nav`, head `d13668d` (2026-11-03 02:24 UTC).
- **Records:** `wip/requirements-control`.

Status words: **DONE** (criteria met, evidence cited), **TESTING** (built; tests or evidence pending), **IN PROGRESS**,
**TO DO**, **OWNER** (needs an owner answer or device check; development continues around it).

## A. REGION-NAV-01: the eight approved stages (`wip/region-nav`)

| # | Item | Status | Commit | Remaining work | Acceptance evidence |
|---|---|---|---|---|---|
| A1 | S1 Settlement placement, discovery, the region map | TESTING | `2745f2f`, `3fd24e2`, `6c88df0` | Close with S2's run (Q3 geography check included) | overworld 179/0, atlas 17/0, countryside 38/0; region_geography 130/0 before D4 |
| A2 | S2 Settlement people: keepers and crafters (Q4), trade through `deal` (Q5), save and load, one geography (Q3) | TESTING | `909b180`..`8792886`, `b18f418` (D1–D4 fixes), `5e3b803` (records) | Finish the running suite pass on `b18f418`; S2 completion report | 9 suites already green on `b18f418` (section F) |
| A3 | S3 Villager long-distance travel | TESTING | `aafcc4d`, `b18f418` | Wiki not needed (no journeys in play until S4); stage report | journey 14/0, journey_s3 19/0 (arrival determinism, blocked route turns home, death conserves), INT-682 |
| A4 | S4 Envoy post | DONE | `b281e90`, `14bbd86` | — | envoy_test 31/0 |
| A5 | S5 Intel network | DONE | `619fcc2` | — | intel_test 13/0 |
| A6 | S6 Independent trade | DONE | `14bbd86` | — | region_trade_test 23/0 |
| A7 | S7 Regional demand and founding measurement | DONE | `5a00993` | — | region_demand_test 11/0 |
| A8 | S8 Measurements, determinism, save mid-mission | DONE (Android profile: gate 11 device check) | `b540971` | Phone profile | region_sim_test 8/0; economy_sim REGION line |
| A9 | Crafters among `Regions.parties()` so the regional market and envoys reach them (from the validation agent's report; Q4 "envoys interview every relevant crafter") | TO DO, in S4 | — | With S4 | — |

## B. Living Economy integration and activation

| # | Item | Status | Commit | Remaining work | Acceptance evidence |
|---|---|---|---|---|---|
| B1 | LE-07 gate 1: full suites on the final SHA | TO DO | final SHA | Run on the candidate (section E) | — |
| B2 | LE-07 gate 4: economy-on long run, leak 0, no item leaks, 0 breaches, no script error | DONE on the baseline for seed 1 | `4b51c92` | Confirmed by the final flight on the candidate (E3) | run 41536810831: 365 days, leak 0, item leaks none, 0 breaches, 0 script errors |
| B3 | LE-07 gate 6: save and load exact over the year; save size recorded | DONE on the baseline | `4b51c92` | Same | 37 of 37 round trips exact; 838,681 bytes at day 365 |
| B4 | LE-07 gate 9: calibration review | DONE (`LE07_CALIBRATION_REVIEW.md`, nothing changed) | — | Write the review from run 41536810831 (measured, not pass/fail) | — |
| B5 | LE-07 gate 10: register settled | TO DO | — | At the build's close | — |
| B6 | LE-07 gate 11: mid-range Android phone performance | OWNER | — | A device check, or an owner ruling (OD-LE-15: "a target to profile, not a success claim"). The S8 Android profile is the evidence offered | — |
| B7 | Living Economy on by default (B25-LE-ACTIVATE-D1), with its wiki pages | DONE (`b00439f`) | — | Turn it on in the candidate after B1–B5, before the final flight (so the flight runs the approved configuration) | — |
| B8 | EXP-D (section 20 of the design) and X20-COMPLETE | TESTING | `wip/expansion20` | Close with B1–B7 and the final flight | integrated; targeted tests |

## C. Other approved Build 25 work and recovered work (integrated on `wip/expansion20`)

| # | Item | Status | Remaining work | Evidence |
|---|---|---|---|---|
| C1 | B25-NINE decisions 1–9 | TESTING | Decision 9 is B7; year-long behaviour in the final flight | integrated; CI 41509578455 green on `0d194c8` |
| C2 | B25-BIZ-D1..D5, B25-BUSINESS-IMPL, B25-EMPLOY-IMPL, B25-AMBITION-IMPL, EMP-PERM-01, CON-03..08, CHAPEL-PURPOSE, X20-CHAPEL-FIX and -INTEGRATE, X20-TELL-GUARD, LE-05 remainder, P21-00..02 (off), FLIGHT-REC-01 | TESTING | Year-long verification in the final flight | integrated, targeted tests, CI green |
| C3 | B25-CAREER-IMPL, B25-CAREER-SYSTEM | TESTING | The register still says NOT STARTED, which is stale: correct it (in the code since `265ddc1`) | `npc_brain.gd` B25-CAREER-IMPL blocks |
| C4 | B25-BIZ-OWN acceptance ("found, buy, sell, hire and expand on their own over a year") | OWNER | No villager founds a business in the runs (benches 2–20 % busy against a 0.35 threshold). B25-ECON-P1..P5 are open | investigation recorded |
| C5 | Farming Phase 2 (FARM-YIELD-D1; FSE-12, FSE-13, FARM-06), KI-HOME-DOOR (FR-REPAIR-01), KI-FR-CARTHITCH | TESTING | Final flight | baseline flight seed 2: 365 days, no home-door or cart-hitch finding; economy-on: starved 0, no famine |
| C6 | X20-MERGED-VALIDATION | TESTING | The final flight on the candidate is its rerun | failed on `ad281dc` (X20-TELL-GUARD, fixed) |
| C7 | X20-ECON-MATURE, -MATURE-REPORT (16 charts), -LONGITUDINAL (days 1/30/90/180/270/365), -AFFORD, -FIREWOOD, -SUSTAIN, -AUDIT | TO DO | Analyses of year-long evidence: from the final candidate's runs | — |
| C8 | B19-RECOVERY and its children (SJD-F, SJD-G, X19-FOUND, DVW-B1, DVW-B2, GM-01, X19-MISINFO, X19-STORY-LIFE, REC-19, REC-DIAG, REC-STORE, B19-EMERGE, WDR-009-C, WDR-011-C, FAM-SAC-01) | TESTING | All integrated; year-long verification in the final flight; matrix kept current | register; `B19_RECOVERY_MATRIX.md` |
| C9 | SJD-H (the Judgment owner review gate) | OWNER | Owner review after SJD-G (matrix: "genuinely blocked") | — |
| C10 | CHAPEL-LENDING | DONE against its acceptance, which asks for the proposal only ("nothing built until the design is approved"). Nine owner questions are open; nothing is to be built | `CHAPEL_LENDING_PROPOSAL.md` at `8b203c5` |
| C11 | Audit and record items: X20-CAREER-AUDIT, X20-ECON-AUDIT, B25-SCOPE-AUDIT, DOC-RECON-01 | DONE as documents | Mark complete at the close | documents on the branches |
| C12 | Process records: B25-CLOSE-01/02, B25-OVN-0211, BUILD-SEQ-25-27, X20-RESUME, B25-SCOPE-REGION, VAL-AGENT-01, DOC-AUTH-01, DOC-RECON-REVIEW-01, B25-FINISH-01 | IN PROGRESS | Close with the build. DOC-AUTH-01 waits for an owner delivery and stays open | — |

## D. Confirmed defects and incomplete acceptance tests

| # | Item | Status | Commit | Remaining work | Evidence |
|---|---|---|---|---|---|
| D1 | Validation D1: crafter counters not saved | FIXED | `8792886` | — | regions 120/0, settlement_life 54/0, settlement_development 32/0 |
| D2 | Validation D2: a household both a crafter and a business worker | FIXED | `b18f418` | Suite result | crafter test 150-day check (running) |
| D3 | Validation D3: a crafter household moving to the village loses its trade's purse and stock | FIXED | `b18f418` | Suite result | migration 109/0; crafter test leave-with-load check (running) |
| D4 | Validation D4: straight-line courier routes after a load | FIXED | `b18f418` | Suite result | geography test after-load check (running) |
| D5 | KI-RECOVER-LOOT: seven villagers fail `recover_loot` up to 96,414 times in a row (baseline flight seed 2, F001–F007) | TO DO | — | Find the cause; fix if a defect; focused test | `CAMPAIGN_4b51c92_2026-11-03.md` |
| D6 | Flight seed 2 F008–F011: hunger at the camp while holding coins; F012/F013: plan alternation | TO DO | — | Classify (bandit design outcome or defect); fix only a defect | same |
| D7 | Baseline flight seed 1 (run 41536805310) | RUNNING | `4b51c92` | Read at 03:02 UTC | — |
| D8 | courier_live_test fee check stale under Q3 road lengths | FIXED (test) | `fbcedc8` | Suite result | baseline 138/0; the old check passed only because the trip was half a day |

## E. Integration, final tests, acceptance flight, packaging

| # | Item | Status | Remaining work |
|---|---|---|---|
| E1 | Merge `wip/region-nav` into `wip/expansion20` | DONE | Fast-forward to `b540971` (2026-11-02 22:5x EST) |
| E2 | Final candidate SHA and full CI | DONE | Candidate `c4c3490` (`a72ed0a` plus two test-only fixes). Run 41580777660 on `a72ed0a`: shards 2 and 3 passed. Shard 0's Python test (`da7c8c1`, 179/179) and shard 1's `od16_test` (`c4c3490`, 46/0) failed on stale test expectations, both fixed; every other suite, the data checks and the FR-07 run passed. Record: `CI_RECORD.md` |
| E3 | Final 365-day flight recorder on that exact SHA with the Living Economy on (B7), under the existing acceptance rules. On a genuine defect: fix, focused tests, rerun the flight | DONE | Run 41587688728 on `c4c3490`: seeds 1 and 2, 365 of 365 days, CRITICAL 0, confirmed defects 0, archives and workbooks ok (seed 1: HIGH 32, MEDIUM 39; seed 2: HIGH 58, MEDIUM 14). Record: `CI_RECORD.md` |
| E4 | Packages: Android APK (permanent signing identity), Windows ZIP, Linux ZIP from the one SHA; export and launch smoke checks; private draft release with the test evidence, simulation report and SHA | TO DO | Not published |

## F. Evidence already on `b18f418` (2026-11-02 21:2x EST, local)

Passing:
- journey_s3_test 19/0
- journey_test 14/0
- regions_test 120/0
- settlement_life_test 54/0
- settlement_development_test 32/0
- settlement_test 89/0
- regional_test 71/0
- migration_test 109/0
- settle_food_test 94/0
- settle_review_test 104/0
- regional_food_test 47/0

Still running: courier_live, courier, courier_desk, countryside, atlas, wiki, settlement_crafter, region_geography,
settlement_folk and overworld.

## G. Not Build 25 (listed so nothing disappears; each placement is the register's)

| Item | Register placement |
|---|---|
| FR-01 lizards and spiders | `target_build` 26 (Expansion 26 design, owner review) |
| FR-02 waterfalls and props, FR-03 campfire, FR-10 archery, LE-00, X20-TRADER-PAY-INV | `20+` (later) |
| FR-09 crime from desperation | DEFERRED by the owner (`target_build` 19) |
| FR-11 personality, prestige, migration | OWNER DECISION REQUIRED (`target_build` 19); parts delivered through Judgment (X19) |
| JOB-02, CON-02-KINDS, PIT-02, FSE-10 | Approved but never placed in a build (reconciliation Q2, unanswered). Not counted as Build 25 unless the owner places them |
| X20-GO-BETWEEN, X20-JUDG-MIGRATION, X20-TRADER-PAY | Deferred by the owner |
| Expansions 21 (beyond phase 1) to 27, CRT-06 remainder, JUICE-JD2..5, X19-SWITCHES-D1, XEXPL-01 | Not authorized, or open owner questions |

## H. Owner answers that the definition of done depends on

These are not requests to approve routine work: development continues around them. Each is a recorded question whose answer
the acceptance criteria name.

1. **C4, B25-ECON-P1..P5:** zero business founding over a year. Answer the five balance questions, or rule that zero founding
   is an acceptable outcome under WDR-022. *Recommendation:* rule it an acceptable outcome for this build (the code works, demand
   is too low; balance belongs to a later build), so C4 closes on the evidence.
2. **B6, LE-07 gate 11:** a device check, or a ruling that the S8 Android profile settles it. *Recommendation:* the profile,
   as OD-LE-15 describes.
3. **C9, SJD-H:** the owner's Judgment review. *Recommendation:* review with the playtest build.
4. **G, reconciliation Q2:** JOB-02, CON-02-KINDS, PIT-02 and FSE-10 not in Build 25. *Recommendation:* confirm.


## I. DEMO-01: replayable 120-minute demo, Steam integration, six-package pipeline (owner 2026-11-03)

Directive: `docs/directives/2026-11-03_demo01_steam_release_pipeline.md`. Register: DEMO-01. A bounded release work package, not a
ninth regional stage.

| # | Item | Status |
|---|---|---|
| I1 | Demo build configuration (one source; demo flag; the full game never restricted) | DONE (`ca27195`, `8d31017`; demo_test 35/0) |
| I2 | Active-play clock (monotonic, injectable; counts only while the world runs) | DONE (`ca27195`, `8d31017`; demo_test 35/0) |
| I3 | Per-world allowance saved with stable world identity; warnings 30/10/5/1 once per world; creation notice | DONE (`ca27195`, `8d31017`; demo_test 35/0) |
| I4 | Expiry: simulation stops, final save, expiry screen (new world, menu, exit, full-game note, Steam); expired worlds marked | DONE (`ca27195`, `8d31017`; demo_test 35/0) |
| I5 | Full game loads demo saves unrestricted; legacy saves migrate; Android save export/import | DONE (`ca27195`, `8d31017`; demo_test 35/0) |
| I6 | Steam promotion: one configured destination; "Coming Soon on Steam" until the owner supplies the page; menus and expiry screen | DONE (`ca27195`, `8d31017`; demo_test 35/0) |
| I7 | Focused tests (timer, persistence, expiry, compatibility, Steam, demo-equals-full simulation) | DONE (`ca27195`, `8d31017`; demo_test 35/0) |
| I8 | Six packages from one SHA in parallel jobs; private draft release | RUNNING: run 41624309659 on `c4c3490` built and verified all six packages, but its simulation gate failed on a stale harness expectation (fixed in `726ceeb`, harness only), so no draft was created. Rerun: release run 41648387967 on `726ceeb`, dispatched 2026-11-03 08:53 EST |

## Order of work (no new scope)

1. Finish the S2 suite pass and report S2 and S3.
2. D5 and D6.
3. S4, S5, S6, S7, S8 (A4–A9).
4. B4 (gate 9 review, from the baseline economy run).
5. E1 merge.
6. B7 activation.
7. E2 candidate CI.
8. E3 flight.
9. C7 analyses from the final runs.
10. DEMO-01 (I1-I7) alongside, before E2's candidate CI.
11. E4 packages: six (I8).
