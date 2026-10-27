# Simulation baseline: changes from the Expansion 20 release fixes (wip/x20-fixes)

Evidence for the baseline policy. **`docs/release/sim_baseline.json` is not replaced**; the lead decides. The candidate is
`docs/release/sim_baseline_candidate_x20_fixes.json` (same format, `mml-sim-baseline/1`).

## The run

- G0, once: `python3 tools/sim_gate.py --godot /opt/godot/godot` (seeds 1 and 2, 30 days, checkpoints 10 and 30, judgment on,
  aspirations off, the shipped defaults), at `c932e4b` (base `87b69ab` + SIM-F2 + SIM-F3 + PROP-EQ). Wall time 25 min 12 s
  (both seeds in parallel). The run wrote its results with `--write`; they were moved to the candidate file and the committed
  baseline (`13e779e`) restored unchanged; the comparison below is `sim_gate.compare` on the two files.
- Result: **FAIL, 28 differences**: every compared value at both checkpoints of both seeds (fingerprint, alive, currency,
  treasury, item ledger table, deposits, animals). **Conservation intact**: currency leak 0 and item leaks none at every
  checkpoint (economy_sim stops at a broken ledger with a FATAL line; both seeds reached day 30); a separate 5-day daily
  trace of seed 1 also shows leak 0 and no item leak every day.

| Seed | Day | Alive (old -> new) | Currency | Treasury | Leaks |
|---|---|---|---|---|---|
| 1 | 10 | 103 -> 110 | 3274 -> 3293 | 48 -> 11 | 0 / none -> 0 / none |
| 1 | 30 | 113 -> 111 | 4720 -> 4251 | 137 -> 1 | 0 / none -> 0 / none |
| 2 | 10 | 113 -> 105 | 3315 -> 3212 | 72 -> 106 | 0 / none -> 0 / none |
| 2 | 30 | 126 -> 117 | 4676 -> 3918 | 116 -> 16 | 0 / none -> 0 / none |

These are outcomes of a different history, measured, not judged (WDR-022; no threshold applies).

## The divergence is the fixes'

- The base reproduces the baseline: `87b69ab`, seed 1, 10 days (economy_sim, the gate's arguments) gives fingerprint
  `ca5b786910ef14d14c6070aac835068b`, alive 103, currency 3274, exactly the committed baseline's seed 1 day 10.
- First divergence (seed 1, `87b69ab` against `c932e4b`, every villager's doing, coins and target tick by tick): **day 0,
  11:39**, labourer p:99. At 10:04 he chose to buy a mallet to dress stone from the goods merchant p:46 with 12 coins: list
  price 12, bargained price 13 (the seller's Trading). On `87b69ab` the act refused it and the trip was chosen again at the
  counter until 11:43; with SIM-F2 the purchase is no longer chosen at the bargained price he cannot pay, and he goes back to
  quarrying four minutes earlier. Everything after follows from that (other sales go to other buyers from 12:24, and so on).
  Daily fingerprints: identical at day 0, different from day 1.
- SIM-F3 changes the simulation too (a bandit holds a watch instead of walking the same blocked chase again), by timing only:
  bandit deaths in 8 days on seeds 1, 2, 3 were 0, 2, 3 before SIM-F3 and 3, 0, 3 after (scratch probe, not the gate).
- PROP-EQ is behind `aspiration.enabled` (off in the gate): the changed code is not reached (the suitor is looked up only when
  aspirations are on; `aspiration_test` checks the flags-off path is the live rule).

## What the lead needs to decide

Whether to accept `sim_baseline_candidate_x20_fixes.json` as the baseline (rename over `sim_baseline.json`, with the
recording commit). An independent validation of the new expected state, if wanted, is a second G0 on the same commit
(`python3 tools/sim_gate.py` after the replacement), which should report PASS.
