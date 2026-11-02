# Known issues and investigations

A durable record of significant defects, unexplained observations and investigations. It exists so a later session does not
repeat a failed approach because the conversation that tried it is gone. Owner directive HAG-MEM-02, Part 2E,
[`docs/directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md`](directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md).

**How this file relates to the others**

| What | Where it lives |
|---|---|
| Requirement and decision status | The register, [`docs/requirements/requirements.json`](requirements/requirements.json) |
| The full event history | [`docs/DEVELOPMENT_CHANGELOG.md`](DEVELOPMENT_CHANGELOG.md) |
| Current session state | [`docs/CURRENT_DEVELOPMENT_STATE.md`](CURRENT_DEVELOPMENT_STATE.md) |
| What is broken or unexplained, what was tried, how it ended, and the evidence | This file |

**Rules**
- Add an entry when a significant defect is found or an investigation starts.
- Update it when the cause is known, an approach fails, or a fix is verified.
- Never delete an entry. Move it to "Resolved" with its resolution commit and evidence.
- Actions artifacts expire (30-90 days), so the conclusion is written here with the run ID.
- An **outcome** is a legitimate result of the approved rules ("a village is allowed to fail", WDR-022). It is recorded here so
  it is not "fixed" by mistake. Changing it needs the owner.

**Status words:** OPEN, INVESTIGATING, FIX IN PROGRESS, RESOLVED (fix integrated; say how verified), OUTCOME (not a defect).

**Paths:**
- Files under `docs/expansion20/` and `docs/release/flight_recorder/` are on the Build 25 source, branch `wip/expansion20`.
  They are not on this records branch.
- Run links point to `https://github.com/verbal76/My-Medieval-Life/actions/runs/<id>`.

## Open and in progress

### KI-01 Farming yield: scarcity at yield 1.5 (INVESTIGATING)
- **Register:** B25-NINE-D3, FARM-YIELD-D1.
- **Symptom:** in year-long runs with shared and seasonal farming on, the village starves late in the year at the
  provisional wheat yield.
- **Discovered:** 2026-11-02, Farming Dispatch A.
- **Affected:** Build 25 source from `eca0e7d`. Configuration: `--market`, `shared_manor_farming=1`,
  `seasonal_village_farming=1`, `shared_wheat_yield` 1.5 or 2.0, 365 days, every 5.
- **Reproduction and results:** [41403541582](https://github.com/verbal76/My-Medieval-Life/actions/runs/41403541582)

  | Run | Starved | Famine checkpoints | Meals missed, no food | Lowest food | Classification |
  |---|---|---|---|---|---|
  | Yield 1.5, seed 1 | 15, from day 323 | 3 | 49,009 | 0.6 days | scarcity |
  | Yield 2.0, seed 1 | 0 | 0 | 17 | 3.5 days | food-secure |
  | Yield 2.0, seed 2 | 0 | 0 | 6 | 3.8 days | food-secure |

  Seed 2 at 1.5 stopped on KI-R01 (the coin_sources leak), so it is not a result.
- **Cause:** at 1.5 the population grew from 104 to 345 against six fixed manor fields. The shortage comes late in the year;
  it is not a winter gap. This is a calibration question, not a code defect.
- **Plan:** written before any results, in `docs/expansion20/FARMING_YIELD_CALIBRATION.md`. Food security is judged on
  integrity, starvation, famine checkpoints and missed meals. Only scarcity raises the yield.
- **Next:**
  - Dispatch B on `8acbdea`: B1 [41469335443](https://github.com/verbal76/My-Medieval-Life/actions/runs/41469335443) (yield
    1.75, seeds 1 and 2) and B2 [41469341029](https://github.com/verbal76/My-Medieval-Life/actions/runs/41469341029) (seed 2
    at 1.5). Both were running on 2026-11-02.
  - Final choice: 1.75 if it passes on both seeds, otherwise 2.0.
- **Remaining risks:**
  - Phase 2 changes the starting wheat for the player and households, and the wiki must follow.
  - An older save loaded after the switch has no seed corn; this needs a test.
  - At yield 2.0 the chapel held more food than all households together, a CHAPEL-PURPOSE follow-up.

### KI-02 48 tin ore mined against 0 taken from deposits, in the LEAKS line (OPEN)
- **Symptom:** the end-of-run LEAKS line prints a deposits note: tin ore mined 48 against 0 taken from deposits (24 in the
  economy-on run).
- **Discovered:** 2026-11-02, during the firewood investigation.
- **Affected:** Build 25 source at `d6ab686`. Seed 1, 160 days, normal play (run A); 90 days with `--market` (run M). Both
  ran locally.
- **Suspected cause:** tin from the trial pits, which do not draw on a deposit record. Not confirmed.
- **Status:** not a ledger failure. Currency and item leaks were 0 and the exit code was 0. It was left out of the firewood
  task's scope, so it remains unexplained.
- **Next:** check whether trial-pit tin should count against a deposit (finite seams, OD-01).
- **Evidence:** `docs/expansion20/FIREWOOD_AFFORD_INVESTIGATION.md`, section 1.

### KI-03 Seven cold household-nights where an adult could pay (OPEN)
- **Symptom:** after the firewood fixes, 37 cold household-nights remained in a 160-day run. In 30 of them nobody in the
  household held 3 coins, which is poverty, an outcome. In 7, an adult held the price of a log.
- **Discovered:** 2026-11-02.
- **Reproduction:** run F, `3b530d5`, seed 1, 160 days, `--every 20`, run locally. The read-only counters are
  `cold_payer_adult`, `cold_payer_elder`, `cold_payer_child` and `cold_payer_none`.
- **Suspected cause, from reading the code, not confirmed:** `_plan_provision` tries only the first seller (`_seller_of`, or
  the judgment's pick) and plans nothing when that seller's price beats the shopper's purse.
- **Next:** measure `cold_payer_adult` in the year runs before changing anything.
- **Evidence:** `docs/expansion20/FIREWOOD_AFFORD_INVESTIGATION.md`, sections 2.2 and 2.4.

### KI-04 Suites never run by CI (OPEN; reporting fixed, coverage not)
- **Symptom:**
  - `tests.yml` ran its suites in one shell step that stopped at the first failing suite. A red run hid every later failure,
    and a run wrote no summary or machine-readable result.
  - It runs automatically only on pushes to `staging/my-medieval-life`. Build 25 is developed on `wip/expansion20`, so CI
    covers it only when the lead dispatches by hand.
  - 34 `*_test.gd` suites in `game/tests/` are not in `tests.yml` at all (counted at `e55cc7f`). Among them are
    `business_founding_test`, `business_ownership_test`, `elder_provision_test`, `skilled_employment_test`,
    `career_ambition_test`, `materials_b25_test`, `juice_test`, `services_d2_test`, `capability_progress_test`, and the
    `net_*` fault, soak and interaction suites.
- **Discovered:**
  - the stop-at-first-failure and staging-only problems on 2026-11-02, when Tests
    [41446921087](https://github.com/verbal76/My-Medieval-Life/actions/runs/41446921087) and
    [41451824267](https://github.com/verbal76/My-Medieval-Life/actions/runs/41451824267) each showed only one failure;
  - the 34 missing suites during HAG-MEM-02 reconnaissance.
- **Why it matters:** od16 and world_test had been failing on the Build 25 source with no CI run noticing (KI-R03).
- **Resolution, part 1:** `tools/ci_report.py`, on branch `docs/hag-memory-rationale-2026-11-02` at `4309029`, makes
  `tests.yml` and `requirements.yml` behave as follows:
  - run every suite after a failure;
  - record each suite's exit code and its "N checks, M failures" line;
  - write a job summary and `ci-report.json` (format `mml-ci-report/1`);
  - still fail the job.

  It is not yet merged into `wip/expansion20` or proven in Actions.
- **Still open:**
  - Adding the 34 suites. Each needs a passing local run first, and some are long soaks, so this is the lead's choice per
    suite.
  - Whether `tests.yml` should also trigger on `wip/expansion20` pushes.
  - Meanwhile, the lead ran all 149 CI suites locally before the next dispatch (2026-11-02).

### KI-05 housing_test loft check fails (OPEN, not classified)
- **Symptom:** the `housing_test` loft check fails. It failed before the 2026-11-01 changes too.
- **Discovered:** before 2026-11-01. The first record is in [`docs/CURRENT_DEVELOPMENT_STATE.md`](CURRENT_DEVELOPMENT_STATE.md),
  "Known defects".
- **Status:** not yet classified. Reproduction details are not recorded (UNKNOWN). `housing_test` is in `tests.yml`, so the
  first full CI run with the new reporting will show its failure line.

## Outcomes (legitimate results of the approved rules; changing them needs the owner)

### KI-O1 No villager founds a business (OUTCOME, owner questions open)
- **Symptom:** in a year with normal settings, no villager considered, founded, bought, sold, hired or expanded a business.
- **Discovered:** 2026-11-02. Year-long run [41362329381](https://github.com/verbal76/My-Medieval-Life/actions/runs/41362329381)
  on `908a17e`, seeds 1 and 2: population 356 and 308; unemployed 141 and 112.
- **First reading, partly wrong:** owning a house looked like the gate, since 0-1 eligible villagers owned theirs. The lead
  raised B25-BIZ-TENANT-Q, and the owner approved Option B (`3c7e45b`). See [the decision record](decisions/B25-BIZ-TENANT-Q.md).
- **Correction:** the economic investigation (`d6ab686`, branch `wip/b25-econ-funnel`) found:
  - **The funnel.** All 172 weekly looks were refused before any decision: no work 106, experience 36, skill 29, bench room 1.
  - **Bench use.** The founding trades' benches were 2-20% busy, against the 0.35 the demand rule needs.
  - **House ownership was misread.** The BIZ line counted the gates in sequence. In fact 22-23 of 25-26 households own their
    homes.
- **Classification:** "nobody eligible", a legitimate result of the approved demand rule, not a defect.
- **Evidence:**
  - a local 120-day seed 1 run;
  - the logs of 41362329381;
  - `docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md`.
- **Owner questions:** B25-ECON-P1..P5 (founding gate, first tool, retirees' stock, ore imports, land growth). Do not weaken
  eligibility before the owner answers. The owner said in B25-OVN-0211: "Do not automatically weaken eligibility requirements
  until we understand the complete causal chain".

### KI-O2 Unaffordable market bids (OUTCOME)
- **Symptom:** about 12,600 `bid_unaffordable` a year (about 35 a day), and 7,394 by day 180 in the Dispatch A seed 2 run.
- **Affected:** only with the Living Economy on (`--market`). The economy ships off (`economy.json` `"enabled": false`), so
  normal play makes no bids.
- **Cause, established:**
  - 92% are trade inputs from traders restocking (SHOP-01), and 8% are merchants' speculation (LE-04).
  - The same 21-22 buyers make them every dawn.
  - None are household food bids; a food bid draws on the whole purse (OD-19).
- **Evidence:**
  - run M, `d6ab686`, seed 1, 90 days, local;
  - run [41233970504](https://github.com/verbal76/My-Medieval-Life/actions/runs/41233970504);
  - `docs/expansion20/FIREWOOD_AFFORD_INVESTIGATION.md`, section 4.
- **Remaining risk:** a calibration question for when the economy is switched on (LE-07 gates).

### KI-O3 Woodcutters decline; the manor wage raise never fires (OUTCOME, owner question open)
- **Woodcutters decline** because the jobless have no coins for a first axe (owner question B25-ECON-P2).
- **The manor wage raise never fires,** because manor places fill the same morning.
- **Evidence:** the firewood investigation, `8654451`.

## Resolved

### KI-R01 coin_sources leak: a departing renter's deposit refunded out of the world (RESOLVED `8acbdea`)
- **Symptom:** `FATAL day 180 seed 2: currency leak -2`. The world total and the holders agreed (`holders_mismatch` 0), but
  `World.coin_sources` was out by 2 (`coin_sources_mismatch` -2): an external coin flow was not recorded.
- **Discovered:** 2026-11-02. Job 125140418049 of run
  [41403541582](https://github.com/verbal76/My-Medieval-Life/actions/runs/41403541582) on `eca0e7d`, seed 2,
  `--market shared_manor_farming=1 seasonal_village_farming=1 shared_wheat_yield=1.5`, 365 days, every 5. Artifact
  `sim-v0-seed2-days365`, ID 13127007444, kept 30 days.
- **Related sightings:**
  - a `currency leak -4` at day 40 in the chapel-food worker's first-version run, with the same signature;
  - the chapel-purpose stress runs.
- **Attempt before it, a different defect:** `1400efa`. The harness `economy_sim.gd` missed the paid-repair escrow among
  coin holders. Every market or economy run stopped on a false leak once a paid repair was unfinished (a control run hit
  FATAL on day 10, exactly the 19 escrowed coins). It was fixed first. The true leak then appeared at day 180.
- **Root cause, confirmed:**
  - A villager moving to a settlement left an LE-05 tool rental open.
  - At the next dawn the rental ended "lost".
  - The remaining 2-coin deposit was refunded to a renter no longer counted, so it left the world unrecorded.
- **Fix** (`wip/b25-leak2` `3ab9a39`/`57a7022`, merged as `8acbdea`):
  - `Migration._pre_leave` settles rentals and paid repairs before departure.
  - New safety net `EconTransactions.refund_party`: a refund owed to an absent party goes to their household, or failing
    that the manor.
- **Verification:**
  - `b25_leak2_departure_test` has 20 checks; 8 of them fail without the fix.
  - The seed-2 reproduction now reaches day 200 with leak 0.
  - The default fingerprint is unchanged, because the change is economy-gated.
  - Merge checks: chapel 173, conservation 8, net_econ_integrity 126.
- **Remaining risk:** not yet seen through a full year. The flight campaign
  [41469410306](https://github.com/verbal76/My-Medieval-Life/actions/runs/41469410306) and farming B2
  [41469341029](https://github.com/verbal76/My-Medieval-Life/actions/runs/41469341029) run on `8acbdea`.

### KI-R02 Gossip crash: a story forgotten mid-meeting was still told (RESOLVED `1e3b8cf`)
- **Symptom:** script errors that failed the Build 25 year-long validation runs:
  - [41233948995](https://github.com/verbal76/My-Medieval-Life/actions/runs/41233948995), seed 1;
  - [41279031310](https://github.com/verbal76/My-Medieval-Life/actions/runs/41279031310);
  - [41279051834](https://github.com/verbal76/My-Medieval-Life/actions/runs/41279051834).

  The latter two still simulated all 365 days, and their chapel results stand.
- **Failed approach:** `59b7c43` holds an earlier draft of the test that did not reproduce the crash. It is kept as a
  negative result.
- **What worked:** the real path was found by tracing seed 1 to day 45.
- **Fix:** `1e3b8cf` (X20-TELL-GUARD) and `552febf` (Godot uid file).
- **Verification:**
  - `test_tell_forgotten_mid_meeting` fails without the fix and passes with it.
  - 13 judgment, history, family, bandit and recorder suites pass, locally.
- **Remaining risk:** not yet seen through a full year-long run.

### KI-R03 Stale test expectations hid behind CI's first failure (RESOLVED)
- **od16_test** (`f583086`):
  - **Symptom:** 2 checks failed after the materials merge `48acc91`. Bisected: 38/0 at `ba94edd`, 38/2 at `48acc91`.
  - **Cause:** the carts now also sell villagers tin and silk, so the trader's test purse filled mid-visit with real coins.
  - **Fix:** the test keeps the new materials off the carts, as it already did luxuries. No check was loosened; the behaviour
    is legitimate trade. 46 checks pass.
- **world_test** (`91cf244`):
  - **Symptom:** 1 of 339 checks failed in Tests
    [41446921087](https://github.com/verbal76/My-Medieval-Life/actions/runs/41446921087) on `f583086`: `DVW-A12 R6`.
  - **Cause:** the check still looked for a level-up in the top banner. Since `625e362` a player's level-up is a personal
    line in the corner log (B25-NINE-D8 routing).
  - **Fix:** the check reads the personal lane, with the same intent. 339 of 339 pass locally.
- **multiplayer_a1** (`e55cc7f`):
  - **Symptom:** 1 of 67 checks failed in Tests
    [41451824267](https://github.com/verbal76/My-Medieval-Life/actions/runs/41451824267) on `91cf244`.
  - **Cause:** a Build 19 fixture's inventories differed only by the item-order key that `da1ed8c` adds.
  - **Fix:** the comparison drops that key.
- **Lesson (KI-04):** each failure surfaced only after the one before it was fixed, one CI run each.

### KI-R04 Firewood: elders never bought firewood; a coinless apprentice could not use the manor's advance (RESOLVED `8654451`)
- **Symptom:** cold households while logs were for sale. The investigation found that every one of the 312 cold nights it
  examined had logs for sale, and 229 of them were in households holding 20-99 coins.
- **Cause and fix:**
  - Only adults reach `_plan_provision`, so elders never bought household firewood. Fixed with `_elder_provides` (OD-19,
    PAR-02A).
  - A coinless apprentice smith could not spend the manor's axe advance on ore, because its reserve blocked the purchase.
    Order inputs may now use reserved coins as due obligations (PAR-02A, EQ-19).
- **Branch:** `wip/b25-firewood` (`3b530d5` fixes, `2021a5b` read-only diagnostic), merged as `8654451`.
- **Verification:**
  - 160-day seed 1, run locally: cold household-nights fell from 159 to 37, leaks 0.
  - elder_provision 11, run_tests 3602 and 9 suites, 0 failures.
  - The diagnostic is fingerprint-neutral (`67b6c604`).
- **Remaining:**
  - KI-03 above.
  - No manor advance fell due by day 160, so fix 2 is shown only by its test.
- **Stale record:** [`docs/CURRENT_DEVELOPMENT_STATE.md`](CURRENT_DEVELOPMENT_STATE.md), "Known defects", still lists
  firewood and X20-AFFORD as unclassified. This entry, KI-O2 and KI-O3 supersede that list.

### KI-R05 The chapel's food store never spoiled and only grew (RESOLVED `35fbd48`, then `8b203c5`)
- **Symptom:** at yield 2.0 the chapel ended the year with 763 and 2,142 wheat, mostly from its own plot.
- **Cause:**
  - `decay.gd` skipped the chapel store, against DVW-B4 ("wherever it is kept").
  - There was no reserve or surplus rule for food.
- **Fix:**
  - `35fbd48`: spoilage and weekly food alms, at a provisional 6-day line chosen by the lead.
  - `8b203c5`: the owner's 14-day line (CHAPEL-PURPOSE) and the emergency path.
  - See [CHAPEL-PURPOSE](decisions/CHAPEL-PURPOSE.md) and the superseded
    [6-day record](decisions/X20-CHAPEL-FIX--food-line-6-day.md).
- **Verification:** chapel_test 137, then 173, with conservation, net_econ_integrity, migration, save_transfer and wiki_test,
  all 0 failures (local).
- **Remaining:**
  - No run past day 40 on `8b203c5`. The flight campaign on `8acbdea` covers it.
  - Owner question CHAPEL-GIVE-14-Q.


## KI-REC-RUNNER: an unsegmented recorded year-long job lost on GitHub (2026-11-02)

- **Symptom:** in long-sims run 41458375116 (`91cf244`, `record=true`, normal play), seed 1's Simulate step ended as *cancelled*
  after about 2.5 hours (16:35 UTC). It was not cancelled by the project; GitHub stopped it. The job log returns 404, and the
  "Keep the results" step was skipped, so nothing was kept.
- **Same run, seed 2:** completed the full year. Its recorded archive was 626 MB.
- **Likely cause (unconfirmed, no log):** runner loss or resource exhaustion while recording a whole year in one job.
- **Resolution in place:** the flight mode in long-sims (FLIGHT-REC-01) records in 100-day segments, with save and resume and
  uploads after each segment. Run 41469410306 reached day 200 on both seeds with no loss.
- **Remaining risk:** single-job recorded runs (`record=true` without `flight`) should not be used for a full year.
