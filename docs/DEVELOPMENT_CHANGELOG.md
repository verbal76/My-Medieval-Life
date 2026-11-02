# Development changelog

The chronological development history of My Medieval Life (owner directive 2026-11-01, DOC-CONT-01,
`docs/directives/2026-11-01_permanent_documentation_ai_continuity.md`). It is for developers. Player-facing release notes are
separate (`docs/release/BUILD_*_TESTER_NOTES.md`).

**How it relates to the other records.** This file records *what happened, when, on which commit*.
- Requirement and decision status lives only in the register, `docs/requirements/requirements.json`. Its generated views are in
  `docs/requirements/views/` and `docs/DEVELOPMENT_LEDGER.md`.
- The owner's words live in `docs/directives/`.
- The current state lives in `docs/CURRENT_DEVELOPMENT_STATE.md`.

When this file and the register disagree about a status, the register wins. Fix this file with a new entry, never by rewriting an
old one.

**Rules.**
- Add an entry at each meaningful milestone: a merge, a fix, a test result, an owner decision acted on, an abandoned approach or a
  discovery.
- Newest first. Never delete or rewrite an entry. Correct one with a later entry that names it.
- Failed experiments and negative results stay.
- Short entries for small changes. Commit messages carry the detail; the register carries acceptance and evidence.

**Status words.** These are the levels the directive defines. Use the highest one the evidence supports, and name where the test
ran: *local* (this machine, Godot headless) or *CI* (GitHub Actions, with the run id).

| Level | Meaning |
|---|---|
| IMPLEMENTED | The code exists on a branch. |
| COMPILED | The project loads without script errors. |
| TESTED | The named tests ran on that SHA, with the stated result. |
| VALIDATED | The acceptance criteria were demonstrated. |
| INTEGRATED | The change is in the Build 25 source (`wip/expansion20`). |
| PACKAGED | A three-platform build was made from it. |
| RELEASED | An authorized release was published. |

**Entry fields.** Each entry gives:
- Date
- Build or expansion
- Requirement or decision IDs
- Branch
- Commit SHA
- Change
- Reason
- Implementation status
- Validation evidence
- Outstanding work

## History before this changelog (index, not a reconstruction)

| Period | Where the record is |
|---|---|
| Builds 7-16 | `docs/release/BUILD_*` packets, readiness and tester notes; `docs/DECISIONS.md` |
| Builds 17-24, Expansions 17-20 | `docs/expansions/README.md` and `EXPANSION_17.md` to `EXPANSION_20.md`; `docs/requirements/views/STATUS.md` |
| Every requirement's history lines | `docs/requirements/requirements.json` (`history` field of each record) |
| Owner directives, verbatim | `docs/directives/` (dated file names) |
| Releases | GitHub Releases (private drafts). Build 24: commit `4611d86`, run 40636966840 |
| Simulation results | `docs/release/LONG_RUN_SIMULATION.md`; `docs/release/build25_validation/`; `docs/release/chapel_fix/` |
| Archived handoffs | `docs/handoffs/archive/` (history only, not current) |

---

## 2026-11-02

**B25-NINE-D5..D7: materials, armour bonuses, cosmetic clothing.**
- Branch: `wip/b25-materials`, merged as `48acc91`. Commits: `041a67c` (WIP), `017d357` (catch-up merge), `394e77d` (the remaining
  work: resources, six icons through the pipeline, wiki, INT-671, DECISIONS row, `materials_b25_test`), and `c7c51f1`, `5fd39b9`
  and `c1dfb02` (existing tests updated for the tin seam; the lead reviewed them and none was loosened).
- Change:
  - Material pathways:
    - Tin: hidden veins, Garton diggings and caravan stock.
    - Bronze: smelted from copper, tin and coal.
    - Steel: iron and coal.
    - Fur: dressed from a hide or pelts.
    - Silk: neighbouring towns' weavers, sold through the caravan.
    - Antlers and tusks: unchanged, from killed animals.
  - Bronze and steel gear now uses real bars.
  - Armour pieces are marked physical, regional, rare or elemental.
  - One working regional bonus: samurai armour gives +1 damage with a sword.
  - Frost, lightning, wind and mounted bonuses are recorded but not applied (no system for them yet), and shown as "not in the
    game yet".
  - 33 ordinary clothes are cosmetic. **This removes stats players had:** the musketeer and hunter hats and the traveller's robe
    lose armour and stamina, as Decision 7 requires.
- Status: INTEGRATED, TESTED (local).
- Evidence:
  - On `c1dfb02`: materials_b25 104, run_tests 3602, 25+ suites, Python tests, all with 0 failures.
  - check_resources, check_interactions and check_assets: 0 problems.
  - check_materials open findings went from 20 to 28, because the new materials have few uses. They are left open, not excepted.
  - 30-day seed 1: no errors or leaks. Tin, bronze, steel and fur were made. **No villager used them** (only player orders do). No
    silk was bought (likely the tanner's Crafting level, unconfirmed).
- Outstanding:
  - Villager demand for the new materials.
  - Silk has no village-grown source (no silkworm system).
  - Elemental bonuses wait on a magic system.
  - The tin seam has not been looked at underground.
  - An older-save edge case: a hidden vein beside an already-cut cell is not exposed.

**JUICE-J1 (B25-NINE-D9): game juice J1 and J2.**
- Branch: `wip/b25-juice`, merged as `ba94edd`. Commits:
  - `efd0cd0`: implementation and wiki.
  - `f905c3e`: catch-up merge.
  - `f6801fd`: INT-670, DECISIONS row, `docs/juice/J1_J2_IMPLEMENTATION.md`.
  - `1a483de`: start_test adapted to the two-lane log; reviewed by the lead, it tests the same intent.
  - `4b72103`: screenshot script.
- Change:
  - J1:
    - The corner log has two lanes, one for personal gains and skill levels and one for village news.
    - The coin counter counts to the new amount.
    - A hurt flinch.
    - Dust and a prompt pulse.
    - "Reduce effects" and "No blinking" settings.
  - J2 is work effects: chips, sparks, sawdust, earth, site progress, finished-building dust and an exhausted seam.
  - Not built: J3-J5, screen shake, haptics, darkness, speech bubbles.
- Status: INTEGRATED, TESTED (local).
- Evidence:
  - juice 44, message_journal 51, x20_android_ui 95, net_ui 61, mp_interact_ui 112, multiplayer_c 340, migration 109, wiki_test,
    start_test 523, run_tests 3601, all 0 failures on `1a483de`.
  - 10-day seed 1 fingerprint `0e5e945a...` is identical with and without the effects.
  - One headless screenshot was looked at.
- Outstanding:
  - Not looked at: the flinch in motion, Reduce effects, the phone layout.
  - No device check.
  - Skill levels are now a corner line rather than a top banner, as Decision 9's split asks.
  - The optional notification filter is not approved, so it was not built.

**Owner directive: chapel economic purpose (CHAPEL-PURPOSE, CHAPEL-LENDING), 2026-11-02.**
- The directive is saved verbatim.
- What the owner set:
  - The chapel maintains itself and does not enrich itself.
  - It keeps food only for clergy, livestock, seed and a modest reserve; the rest is for charity.
  - The 14-day hardship line applies to both food and money aid. This replaces the 6-day food line from `35fbd48`.
  - There is a faster emergency path with priority, plus proactive, fair and legitimate delivery.
  - The operating reserve is to be audited.
  - Starvation deaths while the chapel held food or funds are to be investigated.
  - The whole cycle is to be instrumented.
  - Lending is approved as a concept only, through a separate proposal.
- B25-CHAPEL-FOOD-Q is answered: accumulate when prosperous, use when needed.
- Work started on `wip/b25-chapel-purpose` from `91cf244`.

**First CI run on the Build 25 source (LE-07 gate 1).**
- Run: Tests [41446921087](https://github.com/verbal76/My-Medieval-Life/actions/runs/41446921087) on `f583086`.
- Result: **failed 1 of 339 world_test checks**, `DVW-A12 R6: a new level is announced by core and shown by the interface`.
  - The check still looked for a level-up in the top banner.
  - Since the capability merge `625e362`, the approved routing makes a player's level-up a personal line in the corner log.
  - It is a stale test expectation, not a game defect.
- Fix in `91cf244`: the check reads the personal lane for "Level 2 Reached". Same intent; world_test passes 339 of 339 locally.
- Re-dispatched as Tests [41451824267](https://github.com/verbal76/My-Medieval-Life/actions/runs/41451824267).
- Lesson: `tests.yml` runs only on staging pushes, so several suites (od16, world_test) never ran on the Build 25 source in CI.
  It is now dispatched by hand on `wip/expansion20` at milestones.

**X20-CHAPEL-FIX follow-up: the chapel's food store.**
- Branch: `wip/b25-chapel-food` (`d08b18c`, `df4f7db`, `fa75bd1`), merged as `35fbd48`. The merge also committed two Godot uid
  files the firewood merge had missed.
- Finding:
  - At yield 2.0 the chapel ended the year with 763 and 2,142 wheat. The source is the church plot's own harvest, about 12-18
    wheat a day; offerings were under 1 a day.
  - Its only outflow was relief on request, which stops once the village is food-secure.
- Defects fixed:
  - The chapel's store never spoiled. `decay.gd` skipped it, against DVW-B4's "wherever it is kept".
  - The food store had no reserve or surplus rule; X20-CHAPEL-FIX and CHAPEL-R2 had been applied to coins only.
  - New weekly `Chapel.food_alms`:
    - it keeps a reserve of 4 weeks of relief for 14 days;
    - it gives the rest to households below `goods_keep_days` (6, PROVISIONAL) of food, counting what their coins can buy;
    - poorest per member go first;
    - only goods move, so conservation holds.
  - The lead kept the 6-day line rather than the 14-day essentials line. Below 6 days a household offers no wheat, so food given
    as alms cannot be offered straight back. Both values are agent-provisional.
- Evidence:
  - On the branch: chapel_test 137, conservation 8, net_econ_integrity 126, migration 109, wiki_test, all 0 failures.
  - On the merge: chapel 137, conservation 8, elder_provision 11. run_tests is running.
  - The default fingerprint changes to `b01fbf44`, because of the first service's food alms.
- Outstanding:
  - The plot's surplus in a food-secure village still accumulates, now limited by spoilage. Owner question B25-CHAPEL-FOOD-Q;
    the recommendation is that the church sows only to need.
  - A `currency leak -4` at day 40 appeared in the worker's first-version run, with the same signature as the `wip/b25-leak2`
    defect.

**X20-FIREWOOD and X20-AFFORD: two firewood defects fixed; affordability is an outcome.**
- Branch: `wip/b25-firewood` (`2021a5b` read-only cold-payer diagnostic, `3b530d5` fixes, `0069250` docs, `8938f56`/`15c4d57`
  findings), merged as `8654451`. The merge resolved a DECISIONS.md conflict by keeping both rows, and committed the missing
  `le05_route_risk_test.gd.uid`.
- Defects fixed:
  - Elders never bought household firewood, because only adults reach `_plan_provision`. Fixed with `_elder_provides`, under
    OD-19 and PAR-02A.
  - A coinless apprentice smith could not spend the manor's axe advance on ore, because its reserve blocked the purchase. Order
    inputs may now use reserved coins as due obligations, under PAR-02A and EQ-19.
- Evidence:
  - 160-day seed 1 run: cold household-nights fell from 159 to 37; leaks 0.
  - Tests: elder_provision 11, run_tests 3602 and 9 suites, 0 failures.
  - The diagnostic is fingerprint-neutral (`67b6c604`).
- Outcomes, not defects:
  - Woodcutters decline because the jobless have no coins for a first axe (owner question P2).
  - The manor wage raise never fires, because manor places fill the same morning.
  - Unaffordable bids happen only with the market on: about 35 a day, mostly traders restocking inputs, none for household food.
- Open:
  - 7 cold nights where an adult could pay (the first seller only?), to check in the year run.
  - A note of 48 tin ore mined against 0 taken from deposits in the LEAKS line, to check.
- **od16_test fixed (lead, `f583086`):** it had failed 2 checks since the materials merge `48acc91` (bisected: 38/0 at `ba94edd`,
  38/2 at `48acc91`). The carts now sell villagers tin and silk, which filled the trader's test purse mid-visit with real coins.
  The test now keeps the new materials off the carts, as it already did luxuries. Legitimate behaviour, no check loosened; 46
  checks pass.
- First full CI run on the Build 25 source dispatched: Tests 41446921087.

**Farming Dispatch A: results (Actions 41403541582, `eca0e7d`).**
- Setup: `--market`, shared and seasonal farming on, 365 days, every 5.
- Decision rule from FARMING_YIELD_CALIBRATION.md, applied by the lead's read-only analysis:

  | Run | Starved | Famine checkpoints | Meals missed, no food | Lowest food | Classification |
  |---|---|---|---|---|---|
  | Yield 1.5, seed 1 | 15 (from day 323) | 3 | 49,009 | 0.6 days | **Scarcity** |
  | Yield 2.0, seed 1 | 0 | 0 | 17 | 3.5 days | **Food-secure** |
  | Yield 2.0, seed 2 | 0 | 0 | 6 | 3.8 days | **Food-secure** |

- At yield 1.5 the population grew from 104 to 345 against six fixed manor fields; the shortage is late-year, not a winter gap.
- All three runs are integrity-clean. Seed 2 at 1.5 is not a result (see below).
- Rule row 2: test yield 1.75 next.
  - Final choice: 1.75 if it passes on both seeds, otherwise 2.0.
  - Dispatch B (yield 1.75 on seeds 1 and 2, plus seed 2 at 1.5 as evidence) goes on the leak-fix commit so it cannot stop on the
    same defect.
- Observations:
  - The wheat price sat at its floor of 2 on every run.
  - At yield 2.0 the chapel held 91,600 and 257,060 food points, more than all households together; to examine.
  - Seed corn was thin (18-63 left), with imports covering it.
  - Run times: 3 h 37 min, 4 h 16 min, 2 h 26 min.

**Farming Dispatch A: an integrity failure found (Actions 41403541582, `eca0e7d`).**
- Result: the job for seed 2 at yield 1.5 with `--market` stopped with `FATAL day 180 seed 2: currency leak -2`.
  - World total and holders agree (`holders_mismatch` 0), but `World.coin_sources` is out by 2 (`coin_sources_mismatch` -2): an
    external coin flow was not recorded.
  - Day 175 had passed.
  - Artifact `sim-v0-seed2-days365` (ID 13127007444) on the run page, kept 30 days.
- Classification: a defect (SIM-01; Category E integrity). It is not a yield result: under the calibration rule that job does not
  count.
- Action: a worker is root-causing it on `wip/b25-leak2`. Dispatch B will rerun that job after the fix.
- Also seen in that log: `bid_unaffordable` 7394 by day 180 under `--market`. The X20-AFFORD investigation is on
  `wip/b25-firewood`.

**LE-05: route risk in delivered prices.**
- Branch: `wip/b25-le05-risk` (`cb648ec`, `ba2cc3e`), merged as `0c122b6`.
- Change:
  - `EconRouteRisk` keeps a per-route record of value carried and value lost over a rolling 30-day window. Losses come from
    interrupted courier loads and from robbery of goods owed on a contract; caravans have no loss event.
  - A PROVISIONAL `route_risk` term in `Contracts.price_terms`: the loss rate times the unit's value times `risk_weight` 1.0.
    It is exactly 0 with no recorded losses. The seller bears it, as with travel.
  - It works only with the Living Economy on, under `market.route_risk`. The record is saved under the optional key
    `economy.route_risk`.
  - Regional links beyond the food trade: confirmed in code that nothing further is specified.
  - INT-673.
- Status: INTEGRATED, TESTED (local). LE-05 scope implemented; LE-07 gate 10 no longer waits on it.
- Evidence:
  - le05_route_risk 37, run_tests 3602 and 16 suites, all 0 failures.
  - The default game is fingerprint-identical (`67b6c604`), on the branch and on the merge with `d6ab686`.
  - 30-day economy-on run: no leaks. Value was carried on six routes and no losses happened, so the term stayed 0.
- Outstanding: the term has not risen in a live run; settlement-road losses are recorded but priced nowhere yet (every delivered
  contract is in-village).

**Economic investigation: business funnel, professions and unemployment, ore (B25-OVN-0211 sections 4-6).**
- Branch: `wip/b25-econ-funnel` (`50497cf`, `006ca8f`, `6603daf`, `50cc561`, `d5e32ef`, `86c0b80`), merged as `d6ab686`.
- Change:
  - Read-only diagnostics: venture refusal-stage counts, and `CONFIG`, `FUNNEL`, `JOBS` and `ORE` lines in economy_sim, also
    printed by long-sims.
  - Neutrality proven: the 10-day seed 1 fingerprints are identical to `3c7e45b`.
  - Fixed a fault in the worker's own counting (dead villagers counted as looks), with a test.
- Evidence: a local 120-day seed 1 run plus the logs of year run 41362329381. Tests on the branch: business_founding 73,
  business_ownership 165, skilled_employment 54, career_ambition 71, conservation 8, net_econ_integrity 126, migration 109,
  run_tests 3602, all 0 failures.
- Findings:
  - **Decision systems:** all on (judgment, business_found, job_choice, aspiration); the economy is off.
  - **Business funnel:**
    - All 172 weekly looks were refused before any decision: no work 106, experience 36, skill 29, bench room 1.
    - The founding trades' benches were only 2-20% busy, against the 0.35 the rule needs.
    - So the outcome is **nobody eligible**: a legitimate result of the approved demand rule, not a defect.
    - The year runs' "owns house 0" was the BIZ line counting gates in sequence. In fact 22-23 of 25-26 households own their
      homes.
  - **Unemployment:**
    - Counts adults aged 16-55 with no job; all at day 120 had come of age in the run and never worked.
    - Places are capped by land, the treasury (near 0) and first tools.
    - Founding trades stay at their starting strength, refilled by succession.
  - **Ore:**
    - The original seams were gone by day 30-60; mining outran smelting, so stock piled up.
    - Prospecting stopped when the treasury emptied.
    - This follows the owner's rules (finite seams, OD-01).
    - Imports stalled because Garton's trader had no coins.
- Owner questions B25-ECON-P1..P5 recorded with options and recommendations: founding gate, first tool, retirees' stock, ore
  imports, land growth.
- Outstanding: year-long FUNNEL, JOBS and ORE evidence comes from the final validation runs on the finished candidate. No separate
  run.

**LE-07: the 13 Living Economy readiness gates reviewed on the integrated candidate.**
- Branch: `wip/b25-le07` (`8f288a2`, `40f8494`, `60f4cf4`, `ddf2fdf`), merged as `28d5280`.
- Change:
  - New check: a save made with the economy off loads with it on, and the ledger stays exact through a dawn.
  - `le05_paid_repair`, `le05_construction_hire`, `le07_gates` and `save_continuity` are added to `tests.yml`; CI never ran them
    before.
  - Tests that mean "economy off" now set it off explicitly (`EconomyFoundation.off_config`). Flipping the switch had broken 15
    suites and run_tests, because those tests were reading the installed setting.
  - Gate record: `docs/expansion20/LE07_GATE_STATUS.md`.
- Gates on `eca0e7d`:

  | Gate | Status |
  |---|---|
  | 2, 3, 5, 7, 8 | Passed |
  | 1, 4, 6, 9 | Need the final runs |
  | 10 | Waits on the LE-05 remainder |
  | 11 | Needs a device (a profiling target per OD-LE-15) |
  | 12, 13 | Go in with the activation commit |

- No gate failed on a defect.
- The activation change is prepared, not applied: `economy.json` enabled, six "shipped off" checks flipped, the baseline
  re-recorded, and the wiki pages.
- Observation for calibration: with the economy on, a builder's wage can wait behind the founder's open market bids (a house
  finished on day 7 instead of day 5). Coins are conserved; recorded as a calibration question.
- Next: the LE-05 remainder, then the final long runs on the final candidate (gates 1, 4, 6, 9).

**Farming yield calibration, Phase 1 (B25-NINE-D3, FARM-YIELD-D1), and a harness defect fixed.**
- Branch: `wip/b25-farming` (`1400efa`, `97a1e8b`), merged into the Build 25 source as `eca0e7d`.
- Change:
  - Plan in `docs/expansion20/FARMING_YIELD_CALIBRATION.md`, written before any results:
    - six year-long jobs in two dispatches;
    - a food-security rule judged on integrity, starvation, famine checkpoints and missed meals;
    - failures classified as scarcity or access, with only scarcity raising the yield.
  - **Defect fixed in the harness:** `economy_sim.gd` missed the paid-repair escrow among coin holders. Every run with the market
    or economy on stopped on a false leak once a paid repair was unfinished (control run: FATAL on day 10, exactly the 19 escrowed
    coins). The fix only reads; fingerprint unchanged.
- Evidence: local 10-day smoke tests for every variant, with no errors or leaks.
- Earlier yield evidence (Build 16, FARM-08) only narrows the search.
- Dispatched Actions run 41403541582: Dispatch A, yields 1.5 and 2.0.
- Outstanding:
  - Dispatch B.
  - Phase 2 sets the yield, which also changes the player's and households' wheat from 3 to the chosen value; the wiki needs
    updating.
  - An older save loaded after the switch has no seed corn; this needs a test.
- Workstreams: LE-07 readiness gates started on `wip/b25-le07`. Eight merged worktrees were removed to free disk; their branches
  stay on GitHub.

**B25-BIZ-TENANT-Q answered: Option B, and the overnight directive B25-OVN-0211.**
- Branch: `wip/expansion20` `3c7e45b`.
- Change:
  - `Construction.may_build` accepts a home held owned or rented for a standalone workshop.
  - `module_refusal` is unchanged, so a tenant never builds onto the landlord's house.
  - `Ventures.refusal`: an owner adds the workshop to its house first; a tenant builds standalone on bought ground.
  - Wiki (skills, property) and BUSINESS_FOUNDING.md updated.
- Reason: the owner's Option B. It replaces the lead's interim `f8f9cac` rule.
- Status: INTEGRATED, TESTED (local).
- Evidence: business_founding 66, business_ownership 165, business 160, conservation 8, wiki_test, all 0 failures.
- run_tests 3602 and start_test 523 steps on `3c7e45b`: 0 failures.
- Outstanding: whether villagers now found businesses (economic investigation and Actions).
- The overnight directive authorises parallel workstreams. Started: the economic investigation on `wip/b25-econ-funnel`.

**B25-NINE-D1 and D8: organic skills and capability milestones.**
- Branch: `wip/b25-capability`, merged as `625e362`. Commits: `f891a11` (WIP), `4976137` (catch-up and notification routing,
  INT-672), `ae36a6d` (catch-up with `f8f9cac`), `54a4850` (read-only `CAPMS` sim line). The lead's `8dbe74f` prints `CAPMS` in the
  long-run logs.
- Change:
  - Experience comes from successful work, whatever it is for. A builder who cannot buy stone quarries it for their own house.
  - Apprentice, journeyman and master gate nothing.
  - The village keeps a record of the best level each industry has ever reached. A level is announced once, only when it beats
    that record, as village news through `World.note`.
  - A player's level-ups are personal lines in the corner log.
- Status: INTEGRATED, TESTED (local).
- Evidence:
  - On `ae36a6d`: run_tests 3602, start 523, experience 79, underground 95/113/90, regional_food 47.
  - On `4976137`: 20 more suites.
  - 30-day seed 1: 4 milestones (Masonry 1, Forestry 2, Trade 2, Mining 2), each announced once; no leaks.
- Outstanding:
  - Supplier selection by capability is a dependency, not built. No system lets other settlements learn the village's capability.
  - Learning faster beside a master is not modelled.
  - Own-house quarrying has not happened in a simulation.
  - Not checked on a device.

**Year-long business run 41362329381 (`908a17e`, normal settings, seeds 1 and 2), and the lead's fixes.**
- Runs: seed 1 took 13751 s (37.7 s a game day); seed 2 took 15767 s (43.2 s a day). These are slower than earlier builds, because
  the population grew.
- Result:
  - All 365 days were simulated. Currency and item leaks were 0 at every checkpoint. No FATAL lines.
  - Population reached 356 (seed 1) and 308 (seed 2), with 141 and 112 unemployed.
  - Ore was exhausted by day 360 in both seeds.
- **Businesses:**
  - In neither seed did any villager consider, found, buy, sell, hire or expand a business. The `ventures_*` stats stayed empty all
    year.
  - Founding gates at day 365, as founding trades / skilled / experienced / household free / owns house:
    - seed 1: 9 / 5 / 3 / 1 / 0;
    - seed 2: 8 / 4 / 2 / 0 / 0.
  - Most families live in manor cottages, so owning the house is the gate that stops them.
- **Fixes on `wip/expansion20`:**
  - `9989f3c`: a contract harvest is timed through `CapabilityHook.work_time`, as felling is. It is identical while the hook is
    off. experience_test had failed 1 of 79 checks since the services merge `8d71c5e`; it now passes.
  - `f8f9cac`:
    - A tenant household may now reopen or buy a workshop, since neither builds anything.
    - Building still needs an owned house (owner rule of 2026-10-18, "a house first, then workshops").
    - The lead first tried letting tenants build a standalone workshop. `Construction.may_build` refused it under that rule, so
      the change was undone, and owner question B25-BIZ-TENANT-Q was raised.
    - New tenant check in business_founding (61 checks); business_ownership 165 passes.
- Outstanding:
  - The owner's answer to B25-BIZ-TENANT-Q.
  - Few villagers work in founding trades (8-9 among 300+).
  - Business behaviour over a year is still not shown.

**B25-NINE-D4: judgment-based witness reporting.**
- Branch: `wip/b25-report`, merged as `2c364d1`. Commits: `f15faf8` (implementation, from before the suspension), `fa58b44`
  (catch-up merge of `908a17e`), `eab25e2` (wiki and DCR-01), `5bf548c` (evidence).
- Change:
  - Each witness or victim weighs whether to tell a guard, by severity, kinship with the victim, and liking or fear of the
    offender. Keeping quiet forgets nothing.
  - `integration.report` is on.
  - This intentionally revises PAR-05's rule that every witness reports, as the owner approved in Decision 4. A parent fetching
    help stays a rule.
- Status: INTEGRATED, TESTED (local).
- Evidence on `eab25e2`, 0 failures:
  - judgment suites: live 180, judgment 217, x19 122, calibration 86;
  - justice 33, pursuit 35, family 51 and 104;
  - recorder 214, migration 109, multiplayer_c 340;
  - start_test 523, run_tests 3601.
- 30-day seed 1: 0 script errors, leaks 0. There were 29 report choices, all attacks, and **every witness chose to tell**.
- Outstanding:
  - Nobody kept quiet in normal play. The values were not tuned to force an outcome. Provisional values: harm_killing 100000,
    harm_victim_theft 50000, victim_kin 100000.
  - Theft from shops, containers and livestock is still noticed only by guards. This is unchanged.
  - The crime_spree scenario was not run.
  - The year-long validation will come with the end-of-build runs.

## 2026-11-01

All the work below is Build 25, the consolidation build (B25-SCOPE-D1).
- Source branch: `wip/expansion20`.
- Rollback point: `ad281dc`.
- Records branch: `wip/requirements-control`.
- Tests are local unless a run id is given.

**B25-BIZ-OWN: business ownership, paid employment and economic expansion (B25-BIZ-D1..D5).**
- Branch: `wip/b25-bizown`, merged as `908a17e`. Commits:
  - `24b634d`: audit and two-shop finding.
  - `ed4e8ed`: D1 separate money, D2 paid employees.
  - `f3fb56f`: D4 one employment framework.
  - `af6033f`: D5 buying and selling.
  - `8173f5e`: D3 abandoning sites, plus expansion and career changes.
  - `b10eab3`: interface, wiki and INT-666..669.
  - `2dadf5d`: evidence.
  - `9926ddf`: the lead's read-only `BIZ` simulation line.
- Change:
  - A villager business keeps its own till inside the workshop record, settled each morning by the existing storefront rule. The
    owner invests and withdraws by choice.
  - Paid employees are distinct from independent hands; wages come from the till.
  - One employment framework for miner, woodcutter, farmer, builder, smith, carpenter, tanner, cook and stonecutter. Wages come from
    the labour market, never below the manor day wage.
  - Workshops can be offered for sale, bought at a Trading-skill price and reopened. A home workshop is detached from the house and
    the doorway walled up, so the home never changes hands.
  - A business with money in its till can open a second workshop.
  - An unfinished site is given up through `World.cancel_site`, with no money refund.
  - New host-checked verbs. Spec: `docs/expansion20/BUSINESS_OWNERSHIP.md`.
- Two-shop finding: there is no coded limit. A new world's land office offered only `plot0` and `plot1`; a property has one room
  of each kind; a player has one market pitch. The land office now points to the Build menu for more ground.
- Status: INTEGRATED, TESTED (local).
- Evidence:
  - On `b10eab3`: business_ownership 165, plus 21 regression suites and run_tests 3601, 0 failures.
  - The `BIZ` line is neutral: 10-day seed 1 fingerprint `0e5e945a...` is the same with and without it.
  - Local 90-day seed 1: leaks 0, no workshop built.
  - At day 10 only 1 of 10 founding-trade villagers had the 20 working days of experience.
- Outstanding:
  - Year-long Actions run 41362329381 (seeds 1 and 2) will show whether villagers found, buy, sell, hire and expand on their own.
  - The windows have not been looked at on a device.
  - Few new paths have been tested with the Living Economy on.
  - Provisional values are listed in the spec.

**B25-NINE-D2: informal services and CON-03..CON-08.**
- Branch: `wip/b25-services`, merged as `8d71c5e`. Commits: `3bedaee` (catch-up merge of `d0dc0d7`), `c4911d4` (the missing
  `ContractServices` functions, so the branch compiles again), `41de050` (contract window and `services_d2_test`), `19882ea` (docs),
  `1388f36` (Godot uid file).
- Change:
  - Favours between friends, partners and relatives.
  - CON-03: advances on assay fees.
  - CON-04: pay for the work done, for results only, or a base plus a bonus per result.
  - CON-05: held-back pay, with disputes ruled by the reeve.
  - CON-06: harvest labour; the crop goes to the owner, and cutting under a contract is not theft.
  - CON-07: households hire harvest help. It is on in normal play, through the balance key `contracts.services.npc_hire`.
  - CON-08: a services signing line, left unset, so the 50-coin rule applies.
  - INT-664 and INT-665; design note `docs/expansion20/SERVICES.md`.
- Status: INTEGRATED, TESTED (local).
- Evidence:
  - On `41de050`: services_d2 89, services 51, contracts 154, contract_sign 21, contract_50ore 19, migration 109, save_transfer 21,
    conservation 8, net_econ_integrity 126, business_founding 58, multiplayer_c 340, farming 224, farm_plots 104, le05_repair 57,
    start_test 523.
  - On game code identical to `19882ea`: run_tests 3601, wiki_test.
  - The merge tree is identical to `1388f36`. services_d2 and conservation were re-run on `8d71c5e`.
- Outstanding:
  - The contract window rows have not been looked at on screen.
  - The guest path of `ContractServices:player_harvest` and `contracts.dispute` is untested.
  - CON-08-Q, the signing value, is still open.
  - Provisional numbers: results premium 2.0, held-back share up to 50%, reeve rules after 3 days.
  - A first-attempt merge command failed in the lead's shell; nothing was lost.

**B25-BIZ-OWN: owner's final business decisions recorded (B25-BIZ-D1..D5).**
- Branch: `wip/requirements-control`. Records only, no code yet.
- Change: the five open business questions are answered, and the directive is saved verbatim. The register has a parent record
  (B25-BIZ-OWN) with five approved children:
  - D1: business finances separate from the household's.
  - D2: employees are paid; using a workshop independently is not employment.
  - D3: unfinished business construction can be cancelled through the existing cancellation system, with no money refund.
  - D4: permanent employment across all professions that have real work systems.
  - D5: businesses can be built, bought, sold and expanded; a home workshop is sold without the home; the "two-shop limit" is to be
    investigated.
- DCR-01 classification:
  - All five are compatible with earlier owner rules. D1 extends ECON-P3.
  - D1, D2, D4 and D5 intentionally revise the agent's provisional choices Q1, Q2, Q4 and Q5 from `d0dc0d7`.
  - D3 confirms Q3 (no refund) and adds a cancellation path.
  - No conflict needs escalation.
- Status: approved, not started. It is queued as the next work for the one worker, after the informal services work is
  checkpointed.

**B25-BUSINESS-IMPL and EMP-PERM-01: villager businesses, business hiring, the player's permanent employee (B25-BUSINESS-D2, B25-EMPLOY-D3).**
- Branch: `wip/b25-business` (`cc830e0` design, `2f99b29` founding and closing, `04054bb` hiring and EMP-PERM-01, `c60ac0e` docs),
  merged as `d0dc0d7`.
- Change:
  - Qualified smiths, carpenters, tanners and cooks may build a workshop of their own through normal construction (`ventures.gd`,
    judgment profile `business_found`). A workshop closes after 14 idle days or passes to a family member in the trade.
  - Open ventures offer places through the labour market.
  - The player can employ a permanent miner, paid daily from the purse (`employment.gd`; optional save key `employment`; guest
    verbs `employment.employ` and `employment.dismiss`).
  - INT-661..663.
- Status: INTEGRATED, TESTED (local).
- Evidence:
  - On `d0dc0d7`: `business_founding` 58, `migration` 109, `save_continuity` 5, `save_transfer` 21, `run_tests` 3601, 0 failures.
  - On `c60ac0e`, the worker's run: `business` 160, `business_money` 37, `till_ownership` 71, `skilled_employment` 54,
    `net_econ_integrity` 126, `conservation` 8, `start_test` 523, `wiki_test` passed. `housing_test` loft check fails, as before.
  - 30-day seed 1: leaks 0, 0 script errors, **no founding happened**. Most skilled villagers start short of 20 working days in
    their trade, and no workplace was full and busy. Treated as a legitimate outcome; not retuned.
- Outstanding: provisional numbers. Five open questions are implemented the conservative way (Q1-Q5 in
  `docs/expansion20/BUSINESS_FOUNDING.md`). Founding has not yet been observed in a live run.

**DOC-CONT-01: documentation and AI continuity standard.**
- Branch: `wip/requirements-control`. Commit: this changelog's commit.
- Change:
  - Added this changelog.
  - Rewrote `docs/CURRENT_DEVELOPMENT_STATE.md` as the single current-state entry point. The old copy is archived.
  - Rewrote the recovery procedure as 11 steps.
  - Added a root `README.md` pointer.
  - Marked the stale state-file copies on other branches: `staging/my-medieval-life` `baa6479` and `wip/expansion20` `343c220`
    and `39b1662` (banner only, no code).
- Reason: the owner directive.
- Status: documentation only.
- Validation: `check_requirements.py` reports 0 problems.

**B25-EMPLOY-IMPL: skilled places without fixed headcount; skill-aware hiring (B25-EMPLOY-D3).**
- Branch: `wip/b25-employ`, merged as `265ddc1`. Work commits: `22c17de`, `7ce739d`, `99815ca`.
- Change:
  - Skilled trades open places from workplace room, available work and earnings, not a starting headcount.
  - Hiring weighs skill.
  - Manifest entry renumbered to INT-660 on merge.
- Status: INTEGRATED.
- Evidence: `skilled_employment_test` 54 checks and `run_tests` 3601 checks, 0 failures, local on `265ddc1`.
- Outstanding:
  - Year-long behaviour is not yet observed.
  - Tavern employment measure and immigrant offers (vacancies only) are open items.

**Save continuity fix.**
- Commits: `da1ed8c` and `2c0a780` (Godot uid file), on `wip/expansion20`.
- Change: saves keep the random state, pack order and whole deposit amounts.
- Reason: a save-and-load showed a fingerprint difference (defect register, `BUILD25_RECONCILIATION.md`).
- Status: INTEGRATED.
- Evidence (local):
  - `save_continuity_test` 5
  - `save_transfer` 21
  - `migration` 109
  - `le06_save` 21
  - `le07_gates` 25
  - `start_test` 523
  - `run_tests` 3601
- Known limit: movement in progress is not saved. A loaded game is deterministic from its save, but not identical to an
  uninterrupted game.

**Living Economy remainder (LE-05, LE-07; B25-LE-ACTIVATE-D1).**
- Branch: `wip/b25-econ`, merged as `63c0144`. Work commit: `0ddfcb4`.
- Change:
  - Paid commercial repair.
  - Construction wages.
  - The economy activation mechanism.
  - The LE-07 readiness gates as tests.
- Status: INTEGRATED. The economy is still **off** by default.
- Evidence (local):
  - `le05_paid_repair` 31
  - `le05_construction_hire` 10
  - `le07_gates` 25
  - `net_econ_integrity` 126
  - `run_tests` 3601
- Outstanding: the 13 LE-07 gates must pass on the integrated candidate. The economy is then switched on by default with no further
  approval (B25-LE-ACTIVATE-D1).

**B25-AMBITION-IMPL: career ambition switched on (B25-AMBITION-D4).**
- Branch: `wip/b25-ambition`, merged as `7dfd3d5`. Work commits: `eeae76e`, `bd5ce84`, `fcd0d9c`, `16ef4a4`.
- Change:
  - Ambition and job choice are on.
  - Trade-to-skill mappings are corrected.
  - Ambitious villagers weigh open places against staying.
- Status: INTEGRATED.
- Evidence: `career_ambition` 71, `aspiration` 157 and `run_tests` 3601, local.

**Recovered stranded documents and the `--trader-diag` switch.**
- Commit: `a034c2a`.
- Change: brought in the documents approved for recovery from abandoned branches (B25-SCOPE-D1): trader analysis, JUICE-00 and the
  ROAD-02 sources.
- Status: INTEGRATED. Documentation and a simulation option only.

**P21-00..02: Expansion 21 phase-1 civic records ported.**
- Commit: `ab8ac71`, from `8ac88f5`.
- Change: civic offices and records are present behind a switch that is off. There is no political gameplay.
- Status: INTEGRATED.
- Evidence (local):
  - 10-day fingerprints are identical to `552febf` with the switch both off and on.
  - `civic_records` 48
  - `run_tests` 3601

**X20-TELL-GUARD: gossip crash fix.**
- Commits: `1e3b8cf` and `552febf` (Godot uid file).
- Change: a story forgotten during the same meeting is no longer told.
- Reason: it caused the script errors that failed the Build 25 year-long validation (Actions 41233948995 seed 1, 41279031310,
  41279051834).
- Process note: `59b7c43` holds an earlier draft of the test that did not reproduce the crash. It is kept as a negative result. The
  real path was found by tracing seed 1 to day 45.
- Status: INTEGRATED, TESTED.
- Evidence:
  - The regression test `test_tell_forgotten_mid_meeting` fails without the fix and passes with it.
  - 13 judgment, history, family, bandit and recorder suites pass, local.
- Outstanding: not yet seen through a full year-long run.

**X20-ECON-LONGITUDINAL: observation-only instrumentation.**
- Commit: `55c0881`.
- Change: added `ECON10`, `CHAPEL` and development snapshot lines, plus unaffordable-bid and firewood detail.
- Status: INTEGRATED.
- Evidence: 30-day seed 1 fingerprints at days 0, 10, 20 and 30 are identical to `ae8641d` (`8f06b0d2`, `0a045165`, `9e3c0179`,
  `f0092d8c`), local.

**X20-CHAPEL-FIX: voluntary chapel giving, operating reserve, hardship alms.**
- Commits: `37680c7`, retuned in `ae8641d`.
- Reason: the chapel was absorbing 77-83% of the village's coins.
- Status: INTEGRATED. VALIDATED by year-long runs on `ae8641d` (CI):
  - Runs: Actions 41279031310 (normal settings, seeds 1 and 2) and 41279051834 (economy on).
  - Chapel share of coins: 0.9-1.2%.
  - Median household cash: 161-203 coins (was 4-11).
  - Leaks: 0.
  - Economy saves: 37 of 37 exact.
  - The jobs failed only on X20-TELL-GUARD errors, fixed afterwards.
- Report: `docs/release/chapel_fix/chapel_report.html`, plus the artifact linked in the register.
- Negative result: the first tuning (`37680c7`) still put 34% of coins in the fund by day 30. It was retuned in `ae8641d`: gift
  share 0.1, alms line 14 days.

**X20-MERGED-VALIDATION: Build 25 year-long validation on `ad281dc`.**
- Runs (CI): Actions 41233948995 (normal settings, seeds 1 and 2) and 41233970504 (economy on).
- Result:
  - Seed 1 failed on one X20-TELL-GUARD script error. All 365 days were simulated.
  - Analysis found the chapel was draining household money.
- Status: superseded by the fixes above.
- Report: `docs/release/build25_validation/BUILD25_VALIDATION_REPORT.html`.

**Audits** (read-only, no code):
- X20-ECON-AUDIT: `docs/release/economic_maturation/AUDIT_20_SYSTEMS.md`.
- X20-CAREER-AUDIT: `CAREER_PROGRESSION.md` in the same folder. It found no experience-driven career mobility and capped skilled
  posts. The posts are now fixed by B25-EMPLOY-IMPL.
- B25-SCOPE-AUDIT: `docs/release/build25_reconciliation/BUILD25_RECONCILIATION.md`. Its conclusion was SCOPE INCOMPLETE.

**Owner decisions recorded.** All are in the register; the verbatim text is in `docs/directives/2026-11-01_*`.
- B25-SCOPE-D1: Build 25 is the consolidation build.
- B25-CAREER-D1, B25-BUSINESS-D2, B25-EMPLOY-D3, B25-AMBITION-D4.
- B25-NINE-D1..D9.
- B25-LE-ACTIVATE-D1.
- Reduced-resource mode: one worker at a time.
- DOC-CONT-01.

**Suspended workstreams.** These branches hold real, unmerged work. They are suspended, not abandoned. State and next step are in
`docs/CURRENT_DEVELOPMENT_STATE.md`, "Workers and branches".
- `wip/b25-juice` at `efd0cd0`
- `wip/b25-report` at `f15faf8`
- `wip/b25-materials` at `041a67c`
- `wip/b25-capability` at `f891a11`
- `wip/b25-services` at `68df430`
