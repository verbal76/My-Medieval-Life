# Expansion 20: Living Economy (EXP-D, LE-00..LE-07) and its carryovers

Status record under owner directive 2026-10-31 (`docs/directives/2026-10-31_documentation_reconciliation.md`, DOC-RECON-01).
Vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 against:
- the code, tests and notes on `origin/wip/expansion20` at `ad281dc`;
- the register on `staging/my-medieval-life` at `aeaa012` (1,038 records);
- every directive from 2026-10-20 to 2026-10-31.

Where this file and the register differ, the proposed register corrections are listed in section 10. Until the lead applies
them, this file states the evidence and the register still holds its older value.

**One-line status: PARTIAL, advanced.**
- LE-00 to LE-04 and LE-06 are IMPLEMENTED. LE-05 is PARTIAL. LE-07 is APPROVED, NOT IMPLEMENTED.
- Every Living Economy mechanic is behind `game/data/economy.json` `"enabled": false`, and the economy is OFF by default.
- Tool repair is the exception: it works with the economy on or off.
- The Build 25 validation runs on `ad281dc` are running. **Their results are not yet reported**, and nothing here anticipates
  them.

Build and expansion numbers differ: Build 25 is the Expansion 20 validation and freeze (BUILD-SEQ-25-27). The register views
`BUILD_20.md`..`BUILD_27.md` are named by **expansion** number.

## 1. Current approved scope

| Source | What it sets | Status of the source |
|---|---|---|
| `docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.txt` (and `.docx`, same text) | Sets out the stages LE-00..LE-07 (s.17), the tests (s.16), the anti-patterns (s.19) and the definition of done (s.20). Done means that needs cause offers, offers change independent decisions, and those choices alter supply, jobs, budgets, production and institutions without hard-coded rescue. It also requires one transaction model, accounted goods and money, bounded knowledge, possible failure, working saves and replay, and green release gates | Owner spec (EXP-D) |
| OD-LE-01..OD-LE-15, OD-LE-02B, OD-LE-05B, OD-LE-13B | All APPROVED. The `[FUTURE]` answers (OD-LE-03, -04, -08, -11, -13B, -14) were brought into Expansion 20 by X20-SCOPE (owner 2026-10-27). Lending, interest and manor emergency loans stay excluded (OD-LE-05/05B, OD-LE-06) | Current |
| `2026-10-26_build22_expansion20_execution_authorization.md` (+ amendment) | Substantive implementation authorized on `wip/expansion20`. This superseded the 2026-10-23 phase-1 limit | Current |
| `2026-10-27_complete_expansion20_first.md` (X20-COMPLETE) | Finish Expansion 20 before Expansion 21: REC-DIAG, tills, LE-02..LE-05, carryovers, LE-06, LE-07 | Current; its 2026-10-28 "SUSPENDED" note was lifted 2026-10-30 |
| `2026-10-24_expansion20_open_items_reconciliation.md` (X20-OPEN-ITEMS) | The carryover scope (84 records): polish, Android, interaction, visuals, Build 19/21/22 items | Current |
| `2026-10-26_build19_carryover_audit_x20_integration.md` (B19-RECOVERY) | Recover the unfinished Build 19 scope on the Expansion 20 line (R1-R8) | Current |
| `2026-10-30_master_development_resumption.md` (X20-RESUME) | Resumption after the pause. Three workstreams: LE-03..LE-07, settlement food trade, multiplayer Batch D. Automatic economy activation is allowed only when the objective readiness conditions hold. Expansion 21 is on hold; Expansions 22-27 are not to begin | Current, but see section 6 (economy activation) |
| `2026-10-30_*` trader, Build 24 review and background directives | X20-SETTLE-FOOD, X20-TRADER-CLOSE (option b: reopening), X20-TRADER-PAY (option A, deferred), X20-TRADER-PAY-INV, X20-B24-REVIEW/REMED (F1..F8), X20-BACKGROUND, X20-MP-ECON-INTEGRITY | Current |
| `2026-10-31_sjdh_c4_bandit_intelligence.md`, `2026-10-31_sjdh_decisions_le05_authorization.md` | SJD-H C1-C6 decisions; X20-BANDIT-AI; LE-05 tool repair (economy on or off) and rental (economy on only) | Current |
| `2026-10-31_x20_merged_validation_decisions.md`, `2026-10-31_x20_yearlong_validation_release_readiness.md` | Three 365-day runs on the merged SHA, one consolidated report, then **stop for the owner's review**. Go-between buying and judgment-driven migration DEFERRED. Economy disabled by default. Build 24 unchanged. No packaging, release or publication | **Latest; binding now** |
| `2026-10-31_documentation_reconciliation.md` (BUILD-SEQ-25-27) | Build 25 = Expansion 20 validation and freeze, only after the validation passes and the owner approves it. Build 26 = consolidation. Build 27 = Expansion 21, only on explicit authorization | **Latest; binding now** |

Rules in force now (latest owner decisions):
- The economy is off by default.
- Build 24 (`4611d86`, tag `build-24`) stays frozen.
- No build, package or release of any kind.
- No new expansion work.
- WDR-022 applies: a village may fail; the simulation may not.

## 2. Implemented

All commits are on `origin/wip/expansion20`; each was checked to be an ancestor of `ad281dc`. "Switch" means behind
`economy.json` `enabled: false`, so nothing behind it is playable until activation.

| Id | What | Integration (merge) | Tests and validation (from the register and notes; not re-run) | Switch |
|---|---|---|---|---|
| LE-00 | Read-only architecture audit; every OD-LE decision registered (gate met: all 15 answered) | `d82f173`, `953998a` | Document | n/a |
| LE-01 | Actor, need, offer, knowledge and contract model (`economy/econ_*.gd`); additive optional save key | `b7e3c3b` | `economy_model_test` 112, `economy_foundation_test` 89; LE suites re-passed on merged `721f5ff` (LE06 note s.3.2) | Switch |
| LE-02 | Adaptive bids and asks, haggling, settlement through `World.trade`, per-unit CON-01 procurement, renegotiation (OD-LE-02, -02B, -10, -13, opinion rule 2026-10-26) | `e8cc44b` | `le02_market_test` 102; register INTEGRATION VERIFIED | Switch (`market.drive` true does nothing while off) |
| LE-03 | One transaction authority (`World.transactions`, `econ_claims.gd`, `TRANSACTION_AUTHORITY.md`), household budgets, food bids, no tool-order trap; job choice stays behind its own gate (off) | `70c619b`, `5195c2c` | `le03_claims` 80, `le03_economy` 38, `le03_transactions` 79. G0 identical (Actions 41118611434, 41124728769). Economy on, 30 days (41127569935): leaks 0, 0 claim breaches | Switch |
| LE-04 | Business identity and separate accounts (OD-LE-04/D03, OD-LE-07/D06); estate claims on death (OD-LE-13B); speculation and stockpiling (OD-LE-11); the manor's tools bought through the authority; settle-to-estate for shipments whose party is gone (`econ_transactions.gd::settle_estate`) | `8bbdcfb` | `le04_test` 68, `till_ownership_test` 71. G0 identical (41135548780). Economy on, 30 days (41135583126): leaks 0 | Switch; `market.negotiated_wages` built but false |
| LE-06 | Bounded economy save (lossless format 2 plus forgetting only what can never be acted on); 365-day economy-on run | `a227158` | `le06_save_test` 21. Actions 41143001791, seeds 1 and 2, 365 days: 37 exact load-backs each, coin and item leaks 0, economy save 528 KB / 439 KB at day 365 (was 1.97 MB at day 30). Economy-off `sim_gate` identical | Switch |
| LE05-REPAIR | Tool repair at an anvil, player and eligible NPC smiths; materials from the forging recipe scaled by wear; identity kept | `25663e5` (branch head `d01470c`) | `le05_repair_test` 57; G0 differs only by the approved repair (LE05 note s.5.2) | **Not behind the switch** (owner: normal gameplay) |
| LE05-RENTAL | Tool rental with deposit, wear fee and settlement through the authority; weighed against buying, borrowing or postponing | `25663e5` | `le05_rental_test` 53. Actions 41169157542 (365 days, economy on): rentals 161 / 207, coin and item leaks 0. Seed 1 had one script error in older LE-02/03 code (`econ_market.gd:714`), fixed in `d01470c` and not re-run; the economy-on validation run 41233970504 covers it (results pending) | Switch (`market.rental`) |
| LE-05 parts | Travel cost in a delivered contract's price (`contracts.gd::travel_per_unit`, INT-612); the player's market journal (OD-LE-14, INT-613) | `25663e5` | `le05_test` | Switch |
| X20-SETTLE-FOOD, X20-SETTLE-REOPEN | Settlement-to-settlement food purchase through `World.transactions`; a closed settlement trade reopens when a household takes it up (X20-TRADER-CLOSE option b) | `5195c2c`, `ed6360f` | `settle_food_test` 93, `settle_review_test` 104, `regional_food_test` 47. G0 41142767484: conservation exact | Normal play |
| X20-B24-F1..F8 | Eight Build 24 review findings, each fixed at its cause with a failing-first test. All remain present in frozen Build 24 (per-finding notes) | `5195c2c`, `8bbdcfb`, `f8b3f10` | All INTEGRATION VERIFIED in the register | Normal play |
| X20-MP-ECON-INTEGRITY, X20-TXN-REPLAY-FIELDS, X20-WEAR-TRANSFER | Fault-injected multiplayer trades, contracts and escrow; the authority's replay fields; tool wear that travels with the tool | `5830c35`, `97f7ab6` | `net_econ_integrity_test` 126 | Both |
| SJD-G | Judgment soak and the SJD-H calibration package (`SJDG_SOAK_REPORT.md`) | `531da40` | Actions 41129188776 (judgment on) and 41129193143 (off), 365 days | n/a |
| X20-JUDG-C1, C2, C5 | Judgment integrated into real choices with mixed feelings (C1, C5); hearsay assault memories fade while the opinion stays (C2); decay unchanged (C6) (`JUDGMENT_INTEGRATION_AUDIT.md`) | `17432f0` | `judgment_calibration_test` 86, `judgment_test` 217, `judgment_live_test` 161; Actions 41166571846 | Judgment on (Build 19) |
| X20-JUDG-C3, X20-BANDIT-AI | Wrongdoing counted by incident; bandit awareness, retreat and cooperation, with no stat changes (SJD-H C4) (`BANDIT_AI_REPORT.md`) | `8dc6cef` | `bandit_ai_test` 17; Actions 41171898332. The report's year-long final comparison is the pending validation | Normal play |
| X20-SPLASH | Hot Attic Games opening splash | `4f236c9` | Checked by eye; `run_tests` 3601/0 | Normal play |
| REC-DIAG, X20-FINAL | Flight-recorder diagnostics; final validation for Build 23 | `3a6eee8` (`5c303be`), `eaf6652` | Actions 40478714284, 40478725139 | Tooling |
| X20-TILL-KEEP / TILL-D1, X20-MIGRATE, GP-SWORD-VIS | A leaving household keeps its till; free migration (REG-X20-D1); visible swords | In Build 24 `4611d86` (`4d4f4a1` and earlier) | Register INTEGRATION VERIFIED | Normal play |
| B19-RECOVERY R1-R5 | False accusation published; recorder D5/D4; witness reporting weighed by judgment (flag off); historical memory (GM-01); aspirations (all flags off) | `e49384e`, `9b90e05`, `3601211` | Combined validation on `3601211` (29 suites, G0 identical) | Flags off where stated |
| GP-POLISH children | All eight named items are integrated: GP-ANVIL, GP-LOCKPICK, GP-JOYSTICK, GP-ACTIONBAR, GP-PICKAXE-ANIM, GP-HARVEST-CONT, GP-PROGRESS-BAR (owner playtested, COMPLETE), GP-INPUT-CONSIST. So are the other GP- children | Builds 19-22, all in `ad281dc` | Mostly INTEGRATION VERIFIED; GP-LOCKPICK has targeted tests only | Normal play |
| MP-INTERACT-01 and multiplayer Batch D | See `MULTIPLAYER.md` | `87b69ab`, `de8d225` | | |

Integration-level evidence on the head:
- `ad281dc` replaced the simulation baseline for the merged judgment, bandit and repair work.
- The owner's 2026-10-31 directive records that 42 integration suites and F's calibration suite passed on the merge, and that the
  30-day baseline reproduced three times with no conservation violation.

Register count of target-20 requirement records (decisions excluded):
- 103 of 122 are INTEGRATED, 61 are INTEGRATION VERIFIED, and none is gameplay-verified.
- 54 integrated records still need a real-device check (`playtest`).

## 3. Partial

| Id | Done | Remaining |
|---|---|---|
| EXP-D (umbrella) | LE-00..LE-04, LE-06; LE-05 parts | LE-05 remainder, LE-07, activation, owner review |
| LE-05 | Repair, rental, travel in price, market journal. Construction material bids exist since LE-02 (need kind `housing`) | **Not built:**<br>- paid commercial repair (a smith mending another's tool for coins, economy on);<br>- route risk in prices (documented gap: no route-danger measure exists);<br>- construction hiring (waits on negotiated wages, flag off);<br>- ecology and mining under the existing depletion rules through the economy;<br>- bandits in the market, and regional links beyond the food trade, via `World.transactions`.<br>Source: `LE05_IMPLEMENTATION.md` status table on `wip/expansion20` |
| OD-LE-03 broader part (LE-03/LE-04) | Negotiated manor wages built behind `market.negotiated_wages` (false) | `market.services` is reserved but has nothing behind it: no villager service demand exists yet; construction labour is the natural first one (LE04 note s.4). Recorded as remaining, not invented |
| LE-06 | Save bound, 365-day economy-on run, economy-off identity | OD-LE-15 profiling on a phone (~500 NPCs, ~4 ms a frame) needs a device and a large-population scenario. Provisional parameters are not yet calibrated |
| SJD-H | Owner decisions C1-C6 issued 2026-10-31. C1, C2, C5 integrated (`17432f0`); C3 and C4 integrated (`8dc6cef`); C6 confirmed unchanged | The Gate H owner review. Its input is the X20-MERGED-VALIDATION report (pending) |
| B19-RECOVERY | R1-R5 integrated. R6 measurement done in substance by SJD-G (`531da40`). R7 done in substance: LE-02 market choices go through `JudgmentWeighting`, plus C1/C5. R8 presented: the calibration package was answered 2026-10-31 | The planned `docs/expansion20/B19_CALIBRATION.md` was never written. The witness-report hook (`integration.report`) stays off "until R6 measures it" (`JUDGMENT_INTEGRATION_AUDIT.md` s.2). The matrix (`B19_RECOVERY_MATRIX.md`) has not been refreshed since 2026-10-26. R8 closes with SJD-H |
| X20-TRADER-PAY-INV | Cause analysis and coin reconciliation: no accounting defect; genuine insufficient profit; effect of the 85% reserve. Lives on the **stranded** branch `wip/x20-trader-inv` `3f58ce6`, which is not in `ad281dc` | Compensation alternatives once LE wages and services exist; recover the branch in Build 26 |
| X20-RESUME | Workstreams A (LE-03, -04, -06; LE-05 partly), B (food trade) and C (Batch D) integrated | LE-05 remainder, LE-07, activation (section 6) |
| X20-COMPLETE | REC-DIAG, tills, LE-02..LE-04, LE-06, SJD-G, GP-POLISH code | LE-05 remainder, LE-07, EMP-PERM-01, SJD-H review, the completed-expansion build |
| REC-DIAG | Recorder diagnostics in use | Gaps left on purpose: player premises' till moves, rents and attendants' wages, and construction are not yet recorded as events |
| X20-B24-REVIEW / X20-B24-REMED | All eight findings fixed and verified; LE-04 on the authority; LE-06 bound; MP-econ integrity; SJD-G | The consolidated report (which defects remain in Build 24, any Build 24 maintenance) and the milestone report of the ten directive items were not found as documents. The per-finding notes say each defect remains in Build 24 |

## 4. Remaining approved work

Listed for traceability. **None of it is authorized to start before the owner reviews the validation** (2026-10-31: "stop
for my review before proceeding to another expansion or release"). Where it goes in the build sequence is an open owner
decision (section 6).
1. **X20-MERGED-VALIDATION report.** Runs 41233948995 (normal settings, seeds 1 and 2) and 41233970504 (economy on, seed 1) on
   `ad281dc`; then one consolidated report with A/B/C findings, and stop. Results are not yet reported.
2. **LE-07, release readiness and platform builds** (APPROVED, NOT IMPLEMENTED; gate: all mandatory release gates green).
3. **Economy activation (X20-RESUME conditions), as of `ad281dc`:**
   - No second uncontrolled buying path: met by LE-03's authority.
   - Conservation: exact in every run so far; the year-long runs are pending.
   - Save/load and replay: LE-06 load-backs are exact; X20-TXN-REPLAY-FIELDS is fixed.
   - Migration: format 1 saves load; Build 24 saves load.
   - Long-run calibration: **not done**; LE-02..LE-05 parameters are PROVISIONAL.
   - Mandatory dependencies integrated: **not met** (LE-05 remainder, LE-07).
   - No unresolved critical defects: pending the validation.
4. **EMP-PERM-01, permanent employment by the player** (APPROVED, NOT IMPLEMENTED). Evidence:
   - `docs/DECISIONS.md` 2026-10-24: "Not built: ... permanent staff with terms (EMP-PERM-01)".
   - `X18_X20_COVERAGE_MATRIX.md` row 20.18: APPROVED-NI.
   - The owner's words: temporary contracts and workshop attendants do not complete it.
5. **GP-POLISH remainder.** No code remains that the evidence shows. What remains is the real-device checks of its children
   (Android touch, controller, PC).
6. **B19-RECOVERY R6-R8 remainder** (section 3).
7. **LE-05 remainder**, including paid commercial repair (economy on only).
8. **X20-TRADER-PAY-INV remainder**, and recovery of `wip/x20-trader-inv` (Build 26).
9. **REC-DIAG gaps** (section 3).
10. **Real-device matrix** for the 54 integrated target-20 records with a `playtest` need. This includes MP-INTERACT-01's nine
    host/guest pairs, GP-SWORD-VIS, the GP-ANDROID-* items, GP-LOCKPICK and X20-SPLASH.
11. **Wiki (WIKI-01).** Repair has a player page (`sys:repair`). Rental is listed under `todo:tool_rental` while the economy is
    off. Nothing behind the switch is described as playable.

## 5. Deferred and superseded

| Item | Disposition | Source |
|---|---|---|
| X20-GO-BETWEEN (buying through an intermediary) | DEFERRED; concept kept for later design | Owner 2026-10-31, merged-validation decisions s.2 |
| X20-JUDG-MIGRATION (dislike as a fifth migration reason) | DEFERRED; the four approved reasons stay | Owner 2026-10-31, s.3 |
| X20-TRADER-PAY | DEFERRED: option A; the 85% reserve and compensation unchanged | `2026-10-30_x20_trader_pay_final_decision.md` |
| REG-X20-D2, REG-X20-D4, REG-CIRC-D1 | DEFERRED (hunger migration reads coins only; settlement coin circulation) | 2026-10-23 and 2026-10-28 decisions |
| Lending, interest, collateral, manor emergency loans | Excluded from Expansion 20 (OD-LE-05B, OD-LE-06 `[FUTURE]`; X20-SCOPE) | Owner 2026-10-27 |
| Job choice, aspirations, witness reporting | Built, flags off; not part of activation without its own review | R5, WDR-011 decisions |
| EMP-CONTRACT-01 | SUPERSEDED by CON-02 | Register |
| The 2026-10-28 pause (X20-CHECKPOINT next action "PAUSED"; X20-COMPLETE "SUSPENDED" note; `X20_RECOVERY_HANDOFF.md` "PAUSED") | SUPERSEDED by X20-RESUME (owner 2026-10-30) | `2026-10-30_master_development_resumption.md` |
| X20-FINAL's automatic private-draft release, and X20-RESUME's private draft authority | SUPERSEDED for now by "Do not package, release, or publish anything" | Owner 2026-10-31 |
| The 2026-10-23 phase-1-only limit; `docs/design/EXPANSIONS_20_21_DECISION_PACKET.md` "neither expansion is authorized"; the "authorization today" column of `ROADMAP_20_27_PRIORITY.md` | SUPERSEDED by the 2026-10-26 and 2026-10-27 directives | Register `builds.20.authority` |

## 6. Outstanding owner decisions

1. **The validation review** (X20-MERGED-VALIDATION; also SJD-H Gate H and approval of the Build 25 freeze). It waits on the
   two running runs and the consolidated report.
2. **Where the remaining Expansion 20 scope goes (genuine gap).** The two owner instructions overlap without resolving each other:
   - X20-COMPLETE (2026-10-27) requires LE-05..LE-07, EMP-PERM-01, GP-POLISH and SJD-H before Expansion 21.
   - BUILD-SEQ-25-27 (2026-10-31) freezes Expansion 20 at Build 25 after validation. It makes Build 26 consolidation only and
     Build 27 the start of Expansion 21.

   Neither says whether LE-07, EMP-PERM-01, the LE-05 remainder and economy activation are completed before the freeze, in
   Build 26, or carried past it. The owner must say.
3. **Economy activation authority.** X20-RESUME (2026-10-30) authorized automatic activation on objective readiness. Both
   2026-10-31 directives say "keep the economy disabled by default". The latest rule applies now: OFF. Whether the 2026-10-30
   automatic authority survives the Build 25 freeze is for the owner.
4. **Service contracts (CON-03..CON-08).** These are approved through the CON02-S-1..6 answers, with target "owner decision",
   unscheduled. X20-SCOPE brought "negotiated wages and service contracts behind their switches (OD-LE-03/D02)" into
   Expansion 20. Whether that covers CON-03..08 is not stated; LE-04 left `market.services` empty.
5. **ARMOR-CATALOG-D1:** PROVISIONAL (armour numbers and materials await the owner's balance and art review).
6. **X20-TRADER-PAY:** to be revisited only with LE wage and service evidence (deferred).

Not open:
- OD-LE-01..15, X20-SCOPE, TILL-D1, X20-TRADER-CLOSE, REG-X20-D1/D3, SJD-H-CAL (C1-C6) and LE05-RENTAL-REPAIR are all
  APPROVED.
- MP-INET-RELAY was answered "option A, free methods only" (see `MULTIPLAYER.md`).

## 7. Dependencies

- Builds on Expansion 19: judgment, trust, gossip, identity and the recorder. Builds on Expansions 17-18: CON-01 contracts,
  mining, the settlements and capability.
- Expansion 21 needs Expansion 20's transactions (taxes, payroll, purchasing). Expansion 23 must extend X20-BANDIT-AI, not
  replace it. Expansion 24 needs Expansion 20's event record.
- Multiplayer and the economy share `World.transactions` (X20-MP-ECON-INTEGRITY).

## 8. References

**Branches**
- `wip/expansion20` `ad281dc`: the integration branch and the Build 25 candidate. Do not touch it while validation runs.
- Merged task branches:
  - `wip/x20-le01`..`x20-le06`;
  - `x20-settle-food` `3702566`, `x20-tillkeep`, `x20-migrate`, `x20-sword`;
  - `x20-mp-econ` `d20f63f`, `x20-judgment` `0d91b65`, `x20-bandit-ai` `dd7dca1`, `x20-sjdg` `ed9ade0`;
  - `x20-r1r3`, `x20-r2r4`, `x20-r5`, `x20-final`, `x20-merge-candidate` (= `25663e5`).
- **Not merged (stranded):**
  - `wip/x20-trader-inv` `3f58ce6`: `TRADER_SUSTAINABILITY_ANALYSIS.md` and a `--trader-diag` in `economy_sim.gd`.
  - `wip/x20-bandit-ai-base` `78a4285`: diagnostics baseline only.

**Builds**
- Build 23: `c79b12c`, run 40526826846, private draft 425699977.
- Build 24: `4611d86`, run 40636966840, private draft 426357144, frozen.
- Both are checkpoints, not the completed Expansion 20.

**Actions runs**
- G0: 41142767484, 41118611434, 41124728769, 41135548780.
- Economy-on: 41127569935, 41135583126, 41143001791 (365 days), 41169157542 (365 days).
- SJD-G: 41129188776, 41129193143. Bandits: 41171898332. Judgment: 41166571846.
- X20-FINAL: 40478714284, 40478725139. CI: 41123423327.
- **Validation (pending):** 41233948995, 41233970504.

**Notes (on `wip/expansion20` only)**
- `docs/expansion20/`: LE00_*, LE01_*, LE02..LE06_IMPLEMENTATION, TRANSACTION_AUTHORITY, SAVE_TRANSPARENCY, SJDG_SOAK_REPORT,
  JUDGMENT_INTEGRATION_AUDIT, BANDIT_AI_DESIGN/REPORT, R5_ASPIRATIONS_DESIGN, X18_X20_COVERAGE_MATRIX, MP_*.
- `LE05_RENTAL_REPAIR_PROPOSAL.md`: its header still reads "NOT implemented", which is stale (implemented `25663e5`).
- `docs/release/SIM_BASELINE_CHANGES_X20_*.md`.

**Notes (staging, historical)**
- `docs/expansion20/X20_EXECUTION_PLAN.md`, `X20_OPEN_ITEMS.md`, `B19_RECOVERY_MATRIX.md`, `LE_OWNER_DECISIONS.md`.
- `docs/handoffs/X20_RECOVERY_HANDOFF.md`, `PARALLEL_WORK_2026-10-30.md`.

## 9. Next authorized phase

1. **Build 25, Expansion 20 validation and freeze.** Let runs 41233948995 and 41233970504 finish untouched. Then deliver the
   one consolidated report and stop. `ad281dc` becomes the frozen Build 25 baseline **only** after the validation passes and the
   owner approves it.
2. **Build 26, consolidation.** A separate branch from the exact frozen Build 25 SHA:
   - recover the stranded work (`wip/x20-trader-inv`);
   - bring the `docs/expansion20/` notes and this register onto one line (the Expansion 20 branch's register copy has 789
     records against 1,038 on staging);
   - validate, then freeze on the owner's approval.
3. **No new expansion work.** Expansion 21 begins only at Build 27 on explicit authorization. Expansions 22-27 are not
   authorized.

**Pending document replacement (DOC-AUTH-01, owner 2026-10-31).** The owner is preparing a revised set of expansion
specifications. It supersedes this record's design sources only after the owner explicitly approves the final set. Until
then, the latest explicit owner decisions and the validated baseline govern.

## 10. Proposed register corrections (not applied here)

These proposals were submitted to the lead under DOC-RECON-01. Once applied, they appear as history lines in the register.
They cover:
- EXP-D, LE-05, GP-POLISH, SJD-H, B19-RECOVERY, X20-B24-REVIEW/REMED, X20-RESUME and X20-BACKGROUND, against the evidence above;
- the stale notes on X20-COMPLETE, X20-CHECKPOINT and SJD-H-CAL;
- the wrong `source` on SJD-H-CAL and LE05-RENTAL-REPAIR (both point to 2026-10-30 directives; the answers are in
  `2026-10-31_sjdh_decisions_le05_authorization.md`).

## 11. Sources checked

- **Living Economy spec: present, not missing.** `My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx` (46,197 bytes) is
  in `docs/directives/` on staging, `wip/expansion20` and this branch. The `.txt` contains every one of its 254 paragraphs. An
  earlier audit's statement that the .docx is absent is wrong.
- **Missing or never written:**
  - `docs/expansion20/B19_CALIBRATION.md` (planned by the B19 matrix for R6);
  - the X20-B24-REVIEW consolidated Build 24 report;
  - the X20-B24-REMED milestone report.
- **On one branch only:**
  - `TRADER_SUSTAINABILITY_ANALYSIS.md` (stranded `wip/x20-trader-inv`);
  - every `docs/expansion20/LE*`, bandit and judgment note (`wip/expansion20` only, not staging).
