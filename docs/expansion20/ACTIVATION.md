# Living Economy: activation mechanism, LE-07 release gates and the validation checklist

Register X20-ACTIVATION-AUTHORITY (APPROVED, owner 2026-10-31, `docs/directives/2026-10-31_doc_recon_review_decisions.md` s.2):
"Keep the Living Economy disabled by default. [...] Prepare the activation mechanism and validation evidence, but wait for my
explicit authorization before enabling it in the normal game." LE-07 (design s.16, s.17: "All mandatory release gates green").
Build 25 scope by B25-SCOPE-D1 (owner 2026-11-01). Branch `wip/b25-econ` (from `ab8ac71`).

**Revised 2026-11-01 (B25-LE-ACTIVATE-D1, `docs/directives/2026-11-01_nine_owner_decisions_consolidated.md` s.4):** "Once all
thirteen applicable objective readiness gates pass, activate the Living Economy by default in the integrated Build 25 candidate. Do
not request another owner approval merely to change the enabled flag after those requirements pass." The checklist of section 3 is
those thirteen gates; item 13 is now the recording of that authorization with the commit, evidence and configuration, not a new
request. Gate-by-gate status and the prepared activation change: `docs/expansion20/LE07_GATE_STATUS.md`.

**Nothing here enables the economy.** `game/data/economy.json` `"enabled": false` is unchanged and a test (`le07_gates_test`)
fails if it is ever shipped on. Enabling it is one line in that file, made only on the owner's explicit authorization, with the
commit, evidence and configuration recorded (X20-RESUME's "Record the exact activation commit, evidence, and configuration").

## 1. The mechanism (`EconomyFoundation`, `World`; INT-655)

| Case | What happens | Evidence |
|---|---|---|
| New game, switch on | `attach()` builds empty records; needs are derived from the world as it is | `le07_gates_test::test_running_gates` |
| Existing save with no `economy` section (every save_version 23 save, all written with the switch off), switch on | The same as a new game from that day: `attach(world, {})`. Nothing to migrate; nothing else in the save is read differently or rewritten; no `SAVE_VERSION` change | `le07_gates_test::test_activation_old_save` (Build 24 fixture `b24_save_v23_single.json`: the save's other keys identical, coins identical, a day run with the ledger exact) |
| Save with a section, switch off | The section is **parked** (`World.economy_foreign`, the LE-01 D2 rule): written back unchanged, never acted on. The coins its open rentals and paid-repair orders hold in escrow stay counted (`EconomyFoundation.parked_coins` in `World.total_coins`), so the ledger is exact. A rented tool stays with its renter | `le07_gates_test::test_switch_off_and_on`, `le05_paid_repair_test::test_save_and_replay` |
| Switch on again | `attach()` reads the parked section; open rentals and orders resume where they stood (a rental's fee then counts the wear used meanwhile, as its rule does) | `le07_gates_test::test_switch_off_and_on` |
| A sub-switch turned off with records open | `market.paid_repair` off: open orders are refunded whole at the next dawn. `market.rental` off: open rentals stay open and parked in the live economy (their escrow counted) | `le05_paid_repair_test::test_refunds` |
| Read the state | `EconomyFoundation.activation_state(world)`: enabled, attached, parked, parked escrow, open rentals and orders, the flags | `le07_gates_test::test_default` |

Not designed, so not built (listed for the owner, not invented): a **per-world** switch (the switch is per installation: a world
is "economy on" while the installed data says so); a **wind-down** that closes every open rental and order when switching off
(parking keeps them instead, which is non-destructive); a player-facing control. Each would be an owner decision.

## 2. LE-07 gates automated as tests (`game/tests/le07_gates_test.gd`)

Design s.16 rows, as far as a short headless run can show them:

| Gate (s.16) | Check |
|---|---|
| Release / default | the shipped switch is off; `market.services` off (X20-SERVICES-SCOPE open); `market.negotiated_wages` off; economy off builds and saves nothing |
| Accounting | a day with the economy on: the world's coins less what crossed its boundary unchanged |
| Determinism | two runs of the same seed give economy_sim's fingerprint |
| Persistence | the economy section loads back exactly; the ledger the same after loading and after running on. Not a fingerprint through save/load: found while writing this gate, the base game's fingerprint is not kept by a JSON save even with the economy off (it differs right after loading, e.g. float positions and hunger), so it cannot gate the economy; LE-06's measure (the section's exact load-back) is used |
| Performance (bounds only) | events, deals, rentals and repairs within their configured bounds |
| Compatibility | a Build 24 save loads with the switch on with nothing else changed, and runs |

Existing suites carry the rest of s.16 (unit, interaction, negative): `economy_model_test`, `economy_foundation_test`,
`le02_market_test`, `le03_*`, `le04_test`, `le05_*`, `le06_save_test`, `net_econ_integrity_test`, `conservation_test`.

## 3. Validation checklist before the owner is asked to authorize activation

Each line needs evidence on the exact candidate commit (reuse valid evidence on unchanged code; MSW-01). The X20-RESUME conditions
(2026-10-30 s.4) are the frame; the owner's 2026-10-31 decision makes the final step the owner's.

1. [ ] All suites above, `run_tests`, `start_test`, the save tests and `wiki_test`: 0 failures, 0 script errors (economy off, and
   the economy suites with it on).
2. [ ] `le07_gates_test`: 0 failures.
3. [ ] Economy off is the shipped game: `tools/sim_gate.py` (G0) identical to the accepted baseline, or every difference
   explained by an approved change.
4. [ ] Economy on (`economy_sim --market`), the multi-seed long runs (SIM-01: one run per seed, the longest duration, milestones
   read from checkpoints): currency leak 0 and item leaks none at every checkpoint, 0 claim breaches, no script error, no FATAL;
   rental and repair escrow 0 or accounted at the end.
5. [ ] Determinism: two independent economy-on runs of one seed give the same fingerprints at the agreed checkpoints.
6. [ ] Save/load: the LE-06 load-backs exact in the long run; the economy save size at day 365 recorded (LE-06 bound).
7. [ ] Migration: a Build 24 (v23) save and a Build 25 economy-off save switched on load and run (this file, section 1).
8. [ ] No second uncontrolled buying path (LE-03 authority; paid repair and construction wages now through it, INT-653/654).
9. [ ] Calibration: the PROVISIONAL LE-02..LE-05 parameters (economy.json, judgment.json market profiles, balance repair) reviewed
   against the long-run evidence; outcomes are measured, not pass/fail (WDR-022).
10. [ ] Mandatory dependencies integrated and no unresolved critical defect (the register's LE-05/LE-07 records; open owner
    decisions listed below are not defects).
11. [ ] Performance (OD-LE-15): profile on a mid-range Android phone at about 500 villagers, about 4 ms a frame (a target to
    profile, needs a device).
12. [ ] Wiki (WIKI-01): what becomes playable on activation (rental, paid mending, the market journal) gets player pages, and
    `todo:tool_rental` is retired, in the same change as the switch.
13. [ ] The owner's authorization (given by B25-LE-ACTIVATE-D1 once 1-12 pass), then the one-line change, recording commit,
    evidence and configuration.

## 4. Open owner decisions that bound this work

- **X20-SERVICES-SCOPE** (OPEN): whether "service contracts behind their switches (OD-LE-03/D02)" includes CON-03..CON-08.
  `market.services` stays off with nothing behind it until answered.
- **Calibration of provisional parameters** (checklist item 9): engineering defaults, awaiting review.

## 5. Activation record (2026-11-03)

- **Authority:** B25-LE-ACTIVATE-D1 (owner 2026-11-01), under B25-FINISH-01 (owner 2026-11-03).
- **Change:** `game/data/economy.json` `"enabled": true` (its note updated). `market.services` and `market.negotiated_wages` stay
  false. No save migration.
- **Gates:** `LE07_GATE_STATUS.md` (verdict 2026-11-03).
  - 4 and 6 passed on the economy-on year 41536810831.
  - 9 is reviewed in `LE07_CALIBRATION_REVIEW.md`.
  - 11 is profiled and not blocking (the lead's call).
  - 12 and 13 are applied with this change.
  - 1 is the activated candidate's CI.
- **Tests changed for the shipped default:**
  - `le07_gates_test`
  - `economy_foundation_test`
  - `economy_model_test`
  - `le02_market_test`
  - `le03_claims_test`
- **Wiki:**
  - `sys:market` and `sys:tool_rental` are new.
  - `sys:repair` gains paid mending.
  - `todo:tool_rental` is replaced by `todo:tool_rental_menu`.
  - `todo:other_towns` is corrected for REGION-NAV-01.

