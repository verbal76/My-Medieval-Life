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
