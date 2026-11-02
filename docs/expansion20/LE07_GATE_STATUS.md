# LE-07 release-readiness gates: status on the Build 25 candidate

Register LE-07 ("All mandatory release gates green"), X20-COMPLETE, **B25-LE-ACTIVATE-D1** (owner 2026-11-01,
`docs/directives/2026-11-01_nine_owner_decisions_consolidated.md` s.4: "Once all thirteen applicable objective readiness gates
pass, activate the Living Economy by default in the integrated Build 25 candidate. Do not request another owner approval merely
to change the enabled flag after those requirements pass. If the requirements do not pass, correct the defects and retain the
appropriate disabled or isolated state until they do. Preserve evidence of the actual gating results.").

Candidate measured: **`eca0e7d`** (Build 25 source), worktree branch `wip/b25-le07`. The thirteen gates are the checklist of
`docs/expansion20/ACTIVATION.md` section 3. Worker: LE-07 worker, 2026-11-02. **The economy is still off:** `game/data/economy.json`
`"enabled": false` is unchanged on this branch.

**Verdict: activation is NOT yet authorized by the gates.** Passed: 2, 3, 5, 7, 8 (and 13, conditionally). Waiting on runs: 1, 4,
6, 9. Waiting on the lead: 10. Waiting on a device: 11. Applied with the switch: 12. No gate failed on a demonstrated defect.

## 1. The thirteen gates

| # | Gate (ACTIVATION.md s.3) | Decided by | Status | Evidence |
|---|---|---|---|---|
| 1 | All suites, `run_tests`, `start_test`, the save tests and `wiki_test`: 0 failures, 0 script errors (economy off, and the economy suites with it on) | Test suites (local) + the Tests workflow on Actions | **NEEDS RUN** (local part passed) | Local, `eca0e7d`: 30 suites, 0 failures, 0 script errors (s.2). The full list is the Tests workflow (147 Godot suites with this branch's additions); 33 further suites are in no workflow (s.2) |
| 2 | `le07_gates_test`: 0 failures | Test suite (local) | **PASSED** | `eca0e7d`: 25 checks, 0 failures; `8f288a2` (adds the current-build save gate, item 7): 31 checks, 0 failures |
| 3 | Economy off is the shipped game: `tools/sim_gate.py` (G0) identical to the accepted baseline, or every difference explained by an approved change | Local simulation | **PASSED (differences explained)** | s.3 |
| 4 | Economy on, multi-seed long runs: leak 0, item leaks none at every checkpoint, 0 claim breaches, no script error, no FATAL, escrow 0 or accounted | Year-long Actions run | **NEEDS RUN** | Inputs in s.4. Local 30-day smoke (seed 1): leak 0, item leaks none, 0 breaches, 0 script errors, rental escrow 32 counted (`holders_mismatch` 0) |
| 5 | Determinism: two independent economy-on runs of one seed, same fingerprints at the agreed checkpoints | Local simulation (+ the gate-4 run across machines) | **PASSED** | Two local runs, seed 1, `--market`, 30 days: fingerprints identical at days 0, 10, 20, 30 (`8f06b0d2`, `311fef9d`, `13f86336`, `d7bb179b`) |
| 6 | Save/load: the LE-06 load-backs exact in the long run; the economy save size at day 365 recorded | Year-long Actions run | **NEEDS RUN** (30 days passed) | Local, days 10/20/30: "round trip exact true", 534,790 / 584,542 / 583,548 bytes, 0 breaches |
| 7 | Migration: a Build 24 (v23) save and a Build 25 economy-off save switched on load and run | Test suite (local) | **PASSED** | `le07_gates_test::test_activation_old_save` (Build 24 fixture) and `::test_activation_current_save` (new, a save of this build with Build 25's businesses and employment running): nothing else in the save changes, every coin in place, a dawn run with the ledger exact. `SAVE_VERSION` stays 23; no migration code is needed |
| 8 | No second uncontrolled buying path | Code audit + test suites | **PASSED** | s.5 |
| 9 | Calibration: the PROVISIONAL LE-02..LE-05 parameters reviewed against the long-run evidence (measured, not pass/fail; WDR-022) | Document (review of the gate-4 run) | **NEEDS RUN**, then review | One observation already (s.6) |
| 10 | Mandatory dependencies integrated, no unresolved critical defect | Document (the register) | **NEEDS LEAD (register)** | No critical defect found in this work. Register points to settle: s.7. LE-05 remainder (2026-11-02, `wip/b25-le05-risk`): route risk in prices built (INT-673, `le05_route_risk_test`, economy off unchanged); regional links beyond the food trade done as specified (nothing further specified; LE05_IMPLEMENTATION s.7). Awaiting integration and the lead's register update |
| 11 | Performance (OD-LE-15): about 500 villagers, about 4 ms a frame, mid-range Android phone | Device check | **NEEDS DEVICE** | Not measurable here. OD-LE-15: "a target to PROFILE, not a success claim"; whether it blocks activation is the lead's or owner's call (s.7) |
| 12 | Wiki (WIKI-01): player pages for what becomes playable; `todo:tool_rental` retired, in the same change as the switch | Document, applied with the switch | **PREPARED** (applied in the activation commit) | Pages listed in s.8 |
| 13 | The owner's authorization, then the one-line change, recording commit, evidence and configuration | Document | **GIVEN, conditional on 1-12** | B25-LE-ACTIVATE-D1 (owner 2026-11-01) replaces the per-occasion approval of X20-ACTIVATION-AUTHORITY (2026-10-31) |

## 2. Gate 1: the suites run locally (`eca0e7d`, Godot 4.7.2 headless)

Every one exit 0, 0 `SCRIPT ERROR` lines: `economy_model_test` 112, `economy_foundation_test` 89, `le02_market_test` 102,
`le03_claims_test` 80, `le03_economy_test` 38, `le03_transactions_test` 79, `le04_test` 68, `le05_test` 11, `le05_repair_test` 57,
`le05_rental_test` 53, `le05_paid_repair_test` 31, `le05_construction_hire_test` 10, `le06_save_test` 21, `net_econ_integrity_test`
126, `conservation_test` 8, `till_ownership_test` 71, `wear_transfer_test` 32, `business_money_test` 37, `services_test` 51,
`services_d2_test` 89, `business_founding_test` 66, `business_ownership_test` 165, `skilled_employment_test` 54, `settle_food_test`
93, `migration_test` 109, `save_transfer_test` 21, `save_continuity_test` 5, `wiki_test` (all passed), `start_test` 523 steps,
`run_tests` 3,602 checks; `le07_gates_test` 25 (31 with the new check). The economy suites switch the economy on themselves.

Found while doing this: `le05_paid_repair_test`, `le05_construction_hire_test`, `le07_gates_test` and `save_continuity_test` were
in no workflow. Added to `.github/workflows/tests.yml` (`40f8494`). Still in no workflow (33): `aspiration_test`, `bandit_ai_test`,
`business_founding_test`, `business_ownership_test`, `capability_progress_test`, `career_ambition_test`, `courier_desk_test`,
`desk_test`, `field_work_test`, `history_test`, `judgment_calibration_test`, `judgment_incident_test`, `judgment_soak_test`,
`juice_test`, `market_spacing_test`, `materials_b25_test`, `mp_interact_ui_test`, `net_family_test`, `net_fault_test`,
`net_interact_test`, `net_mp4_test`, `net_recorder_quit_test`, `net_soak_test`, `player_family_test`, `services_d2_test`,
`settle_food_test`, `settle_review_test`, `sim_f2_test`, `sim_f3_test`, `skilled_employment_test`, `stall_rent_pitch_test`,
`sword_visual_test`, `table_preview_test`. Whether each belongs in CI is the lead's call (some are soaks or screenshot scripts).

**To close gate 1:** dispatch the Tests workflow (`tests.yml`, `workflow_dispatch`) on the candidate branch; 0 failures and 0
script errors closes it, with the suites above.

## 3. Gate 3: economy off against the accepted baseline

`python3 tools/sim_gate.py --seeds 1,2 --days 30 --check 10,30` on `eca0e7d`: **27 differences** from the committed baseline
(`docs/release/sim_baseline.json`, recorded at `a3643c8`, replaced last at `ad281dc`). Leaks 0 at every checkpoint, no script error.
Seed 1 day 30: fingerprint `74237435`, alive 114, currency 4,109 (baseline 117, 4,416); seed 2 day 30: `4f472332`, 117, 3,976.

Attribution (seed 1, 10 days, the baseline's day-10 fingerprint `0b882a87`):

| Commit | What it is | Day-10 fingerprint |
|---|---|---|
| `ad281dc` | the baseline's code | `0b882a87` (reproduced on this machine) |
| `7dfd3d5` | Build 25 with the career ambition, before the Living Economy remainder | `0b882a87` |
| `63c0144` | + the Living Economy remainder (LE-05 paid repair, construction hiring, activation, LE-07 gates) | `0b882a87`: **the economy code left the economy-off game identical** |
| `eca0e7d` | + B25-EMPLOY-IMPL, B25-BUSINESS-IMPL / EMP-PERM-01, B25-NINE-D2 (services), B25-BIZ-OWN / D1..D5, B25-NINE-D4 (witness reporting), D9 (juice), D5..D7 (materials), D1/D8 (skills, capability), B25-BIZ-TENANT-Q, the save-continuity fix `da1ed8c` | `67b6c604` |

Every first-parent change after `63c0144` is an owner-approved Build 25 change; the one among them that touches the economy's
code (`ed4e8ed`, B25-BIZ-D1/D2: venture tills as economy actors) is itself approved. The differences are not attributed merge by
merge. **Action for the lead:** replace the baseline (`sim_gate.py --write`) on the final candidate, after the farming-yield change
(`wip/b25-farming`) lands, and record it in `docs/DECISIONS.md`. On activation the shipped game becomes economy-on, so that baseline
is then recorded with the switch on (s.9).

## 4. Gates 4, 6 and 9: the year-long run to dispatch (`long-sims.yml`)

One dispatch, on the **final integrated candidate** (after `wip/b25-farming` and `wip/b25-econ-funnel` land; a run on `eca0e7d`
would have to be repeated once either changes the game):

| Input | Value |
|---|---|
| ref | the final Build 25 candidate branch |
| `seeds` | `1,2,3,4` |
| `days` | `365` |
| `every` | `10` |
| `set` | empty |
| `variants` | empty |
| `sim_args` | `--market` (the shipped `economy.json` with `enabled` forced on: the exact activation configuration) |
| `record` | false |
| `recover_run` | empty |

Four seeds as the release policy's four-seed runs of the normal game (after activation the normal game is this configuration).
SIM-01: one run per seed at the longest duration; days 30, 90, 180 and 365 are read from the checkpoints. Each checkpoint prints
`ECONOMY day N:` (save bytes, load-back exact, claim breaches); a broken ledger or load-back fails the job there (FATAL).
Timing: the economy-off year on Build 25 (`908a17e`, run 41362329381) took 4 h 23 min a seed; the economy-on year on `ae8641d`
(run 41279051834) 4 h 12 min; the job limit is 5 h 30 min (sim `timeout 19200`), so the margin is about an hour.

Read for each gate: **4** the `day N:` lines (leak 0, item leaks 0), the final `currency:` line (`holders_mismatch` 0, rental and
repair escrow), `economy audit: 0 breaches`, no `SCRIPT ERROR`; **6** every `ECONOMY day N:` "round trip exact true" and the day-365
save bytes (LE-06 measured 527,690 and 438,945 at day 365 on `5319993`); **9** the market, rental and repair counters
(`economy market:`, `LE05`) and the village outcomes, against LE-06 run 41143001791. **5, across machines:** if the run's code is
the code measured here, seed 1's checkpoints at days 10, 20 and 30 must equal `311fef9d`, `13f86336`, `d7bb179b`; on a different
candidate, repeat the local pair (s.1, gate 5) on that commit instead.

Earlier economy-on year runs do not count for this candidate: 41143001791 (`5319993`, LE-06) predates Build 25; 41233970504
(`ad281dc`) predates the Build 25 merges; 41279051834 (`ae8641d`) failed on 12 script errors in `JudgmentStore._tell`, fixed since by
`1e3b8cf` (X20-TELL-GUARD, inside `eca0e7d`).

## 5. Gate 8: buying paths added since LE-03 was verified

Every line added between `ad281dc` and the candidate that takes coins from a party where goods also move (`coins -=` with an
inventory change within 25 lines) was listed and read. Result: one, and it is controlled:

- `npc_brain.gd` B25 Decision 5 caravan trade imports (raw silk for the tanner): `w.claims_release(o, COINS, price, id)` before the
  coins move, as the caravan's other imports (LE03_IMPLEMENTATION s.3 table).

Other coin paths added by Build 25, all coins only (no goods), read as well: workshop and venture sales (`ventures.gd::_pay`:
`claims_allow` on every payer, then `World.transactions.transfer_coins` per part, with the economy on), construction wages
(`construction.gd`, LE-05: `claims_allow` then `transfer_coins`), employment wages (`employment.gd::_pay`). Observation, not a
defect: `employment.gd::_pay` takes a **player** employer's wage from its purse without consulting its claims. No player holds a
coin claim today (market offers are posted by villagers only, `econ_market.gd`), so nothing can break; if players ever post bids,
it should call `World.claims_release` as construction wages do. The LE-03 suites (`le03_claims_test` 80, `le03_transactions_test`
79, `le03_economy_test` 38) pass on the candidate.

## 6. Calibration observations so far (gate 9; outcomes, not pass/fail)

- **Building with the economy on (found by the activation dry run, s.9).** `run_tests::test_households_split` (a founder with 326
  coins builds a house with a hired carrier): economy off, built on day 5; economy on, built on day 7. Probe: the founder's coins
  become reserved for its own market bids, the carrier's wage is refused by the claims on day 4 (contract ended) and a new one
  starts on day 6. Coins are conserved and the house is built: a legitimate outcome of LE-03's rule (open bids hold coins;
  non-necessity spending yields to them). Whether a running construction wage should rank as a necessity is a calibration question
  for the review, not a defect.
- **Economy save size** at day 30 (seed 1): 583,548 bytes (knowledge 7,159 entries, 2,851 forgotten), within LE-06's measured range.

## 7. Points for the lead (register, not editable here)

- **X20-ACTIVATION-AUTHORITY** (APPROVED 2026-10-31, "do not automatically activate") is revised by **B25-LE-ACTIVATE-D1**
  (2026-11-01: "The previous blanket requirement for another manual owner approval was not the intended permanent policy"). Under
  DCR-01 an intentional revision: the register should say so (SUPERSEDED or a note), and ACTIVATION.md item 13 now reads as gate 13.
- **X20-SERVICES-SCOPE** is now APPROVED (CON-03..CON-08 in Build 25, built in `contract_services.gd`, outside `market.services`).
  `market.services` gates nothing and stays false; `le07_gates_test`'s wording ("open owner decision") is stale and is corrected in
  the activation commit.
- **LE-05** is PARTIALLY IMPLEMENTED (route risk in prices: documented gap; regional links beyond X20-SETTLE-FOOD). Whether these
  are mandatory dependencies of activation (gate 10) is the lead's reading of LE-05's acceptance ("Integration matrix covered").
  Update 2026-11-02 (`wip/b25-le05-risk`, from `28d5280`): route risk in prices is built (a per-route loss record of real losses and
  a PROVISIONAL expected-loss term, INT-673, LE05_IMPLEMENTATION s.2), and regional links beyond the food trade are confirmed in code
  as nothing further specified (s.7). Once merged, the two LE-05 parts gate 10 named are no longer missing; the register is the
  lead's to update.
- **Gate 11** cannot be decided by an automated run. If it is "applicable" in the owner's sense, activation waits for a device
  profile; if not, record why. LE-06's desktop profile (`142d68c`, 106 villagers): 25.07 s a game day on, 25.39 s off.

## 8. Wiki pages for gate 12 (in the activation commit)

What becomes playable with the switch, from the code (`econ_market.gd`, `econ_rentals.gd`, `econ_repairs.gd`):

- **New `sys:market` ("How villagers trade: bids, asks and bargains")**: villagers post what they want to buy and sell, bargain when
  they meet (a few rounds, by personality), take bids to sellers they know as short contracts, merchants buy cheap to sell on;
  prices move with what people know and what is scarce; word of mouth spreads prices; nothing is ever sold that is not held.
- **New `sys:tool_rental` ("Villagers renting tools")**: a worker short of its trade's tool may rent a spare from a willing owner for a
  deposit (the tool's value) and a fee (the wear its use consumes), for a few days, then gives it back.
- **`sys:repair` updated**: its last paragraph adds paid mending (a villager with a worn tool may pay a smith; the price is the
  materials and the smith's time; the coins are held until the work is done and refunded if it is not).
- **Messages journal (`sys:journal_map` or the controls page) updated**: market lines: talking with a villager shows the offers it has
  open; each new price goes in the journal with the day and place (only what you learned in person).
- **`todo:tool_rental` retired**; a new "Not in the game yet" entry for what the player still cannot do: renting a tool or paying a
  smith from the menus (the world has the actions, `World.player_rent_tool`, but no window uses them).
- **`sys:market` also says** (LE-05 route risk, INT-673): a villager who agrees to deliver goods asks a little more when goods
  have been lost on the way lately (a delivery robbed by bandits, a courier's load lost on the road); with nothing lost, nothing
  is added.
- `wiki_test`: a check that the new pages exist, that `todo:tool_rental` is gone and that the replacement todo says "Not in the game yet."

## 9. The activation change (prepared, NOT applied)

Dry run: a copy of the candidate with only `"enabled": true` (scratch, not committed) ran the economy suites, `run_tests`,
`start_test`, `wiki_test`, `recorder_test`, `migration_test`, `save_continuity_test`, `conservation_test`: every **economy-off** check
that relied on the installed switch being off failed (15 economy suites), and `run_tests` failed 2 checks with 1 script error (the two
base-game scenarios of s.6 and B7-016, where a woodcutter short of an axe rents instead of buying: LE05-RENTAL as designed).
`start_test`, `wiki_test`, `conservation_test`, `migration_test`, `recorder_test`, `save_continuity_test`, `business_*`,
`services_d2_test`: passed with the economy on.

Done on this branch (neutral while the switch is off; makes the off-path tests independent of it): `EconomyFoundation.off_config()`
and `file_config()`; every test that means "economy off" now says so (`set_override(EconomyFoundation.off_config())`), the
multiplayer host takes a `noecon` flag, and `run_tests` runs `test_households_split` and `test_long_run_economy` with the economy
off. Results in both states: s.10.

**The activation commit itself** (on the integrated candidate, once gates 1-12 pass):

1. `game/data/economy.json`: `"enabled": false,` -> `"enabled": true,`; the `note`'s last sentence "Activation is the owner's
   decision." -> "On by default from Build 25 (B25-LE-ACTIVATE-D1, owner 2026-11-01) after the LE-07 gates passed
   (docs/expansion20/LE07_GATE_STATUS.md)." Nothing else in the file changes: `market.services` and `market.negotiated_wages` stay false.
2. Tests whose assertion is the shipped default (they read the file):
   - `le07_gates_test::test_default`: "the shipped switch is off" -> on; the `services` message no longer cites an open decision.
   - `economy_foundation_test::test_disabled`: "shipped economy.json is disabled" and "economy.json format and enabled=false" -> enabled.
   - `economy_model_test`: "shipped economy.json: off, with needs and offers settings" -> on.
   - `le02_market_test::test_switch`: "shipped: the economy off (activation is the owner's)" -> on, its market driving.
   - `le03_claims_test::test_switch_off`: "shipped: economy.json enabled false" -> enabled.
3. `docs/release/sim_baseline.json`: re-record with the shipped (economy-on) game; `docs/DECISIONS.md` entry. `tests.yml`'s short
   simulation then runs economy-on by default.
4. Save migration: **none**. `SAVE_VERSION` stays 23. A save without an `economy` section starts the economy empty on loading
   (gate 7); a save with one resumes it. No data is reinterpreted or dropped (INT-655).
5. Wiki pages of s.8, `wiki_test`.
6. Documents: `ACTIVATION.md` (record commit, evidence and configuration: gate 13); INT-655 trigger text ("shipped off; enabling it
   in the normal game waits for the owner's explicit authorization" -> shipped on from Build 25, B25-LE-ACTIVATE-D1);
   `economy_foundation.gd` header comment (line 5, "the shipped state"); `docs/DECISIONS.md`; this file.
7. Register (lead): LE-07, X20-COMPLETE, B25-LE-ACTIVATE-D1, X20-ACTIVATION-AUTHORITY history lines with the commit.

## 10. Test results with the off-path change (both states)

Branch `wip/b25-le07` after the off-path change, Godot 4.7.2 headless, 0 script errors in every run:

| Suite | Switch off (as shipped) | Switch on (scratch copy, `"enabled": true` only) |
|---|---|---|
| `le07_gates_test` | 31, 0 failures | 31, 1 failure: "the shipped switch is off" |
| `economy_model_test` | 112, 0 | 112, 1: "shipped economy.json: off" |
| `economy_foundation_test` | 89, 0 | 89, 2: "shipped economy.json is disabled", "enabled=false" |
| `le02_market_test` | 102, 0 | 102, 1: "shipped: the economy off" |
| `le03_claims_test` | 81, 0 | 81, 1: "shipped: economy.json enabled false" |
| `le03_economy_test`, `le03_transactions_test`, `le04_test`, `le05_test`, `le05_repair_test`, `le05_rental_test`, `le05_paid_repair_test`, `le05_construction_hire_test`, `le06_save_test`, `till_ownership_test`, `wear_transfer_test`, `net_econ_integrity_test` | 38, 79, 68, 11, 57, 53, 31, 10, 21, 71, 32, 126: 0 failures | the same counts, 0 failures |
| `run_tests` | 3,602, 0 | 3,602, 0 |

With the switch on, the only failures left are the six assertions of the shipped default, exactly the edits of s.9 item 2.
`start_test` (523), `wiki_test`, `conservation_test` (8), `migration_test` (109), `recorder_test` (214), `save_continuity_test`
(5), `business_money_test` (37), `business_ownership_test` (165) and `services_d2_test` (89) already passed with the switch on in
the first dry run (they do not use the override).
