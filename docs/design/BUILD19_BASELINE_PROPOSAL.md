# Build 19 determinism baseline: proposal for owner approval (2026-10-24)

Owner rules: one combined baseline after identity and the wait-plan fixes are integrated (`docs/directives/2026-10-23_simf9_determinism_decision.md`);
the Build 18 baseline stays as history; differences documented and explained (B19-EMERGE). **Nothing is written to
`docs/release/sim_baseline.json` until the owner approves**; on approval it is written with `python3 tools/sim_gate.py --write` on
the commit named here and committed with the Build 18 file kept as `docs/release/sim_baseline_build18.json`.

## Commit and evidence

`wip/build19` **a7c84e9**: Expansion 19 complete and on (b7f832e), identity foundation, REC-F1 and SIM-F9, flight recorder
(off), and the blocked-chase fix (SIM-F4 defect). Targeted suites on the merge: 18 suites, 1784 checks, 0 failures, wiki
passes; after the fix, world 339, outlaw_return 24, judgment_live 144, family_first 104, recorder 160, conservation 8,
recf1 28, all 0 failures.

| Seed, day | Fingerprint | Alive | Households | Currency | Leaks |
|---|---|---|---|---|---|
| 1, 10 | `41e597274eaa9c0b97f04db464db21c4` | 109 | 25 | 3247 | none |
| 1, 30 | `2ca73c196badc3db91137106935bb1c6` | 118 | 25 | 4661 | none |
| 2, 10 | `0ee4b92f3f53c767e9440dbda9634014` | 110 | 25 | 3237 | none |
| 2, 30 | `51840e25583ecc869c1726de84271db6` | 118 | 25 | 4144 | none |

**Determinism:** two independent runs of each seed (the gate, and the recorded 30-day run) give the same fingerprints at
days 10 and 30; the recorder changes nothing. **Conservation:** no currency or item leak at any checkpoint; no FATAL line.

## Why it differs from Build 18 (each cause established separately)

| Change | Where it first shows | How it was established |
|---|---|---|
| Judgment on (Expansion 19) | day 1 (seed 1 17:32, seed 2 15:58): a sale goes to a different buyer through the approved 15% near-best choice | lockstep judgment-on vs off runs (completion worker, b7f832e); with `--no-judgment` the gate equals Build 18 |
| REC-F1 and SIM-F9 | day 10 | the fixes stop wasted decisions and make meals, medicine and beds last their time (tests fail before, pass after) |
| Permanent identity | day 13 | arriving people keep their own id, and chapel piety and caravan taste are hashes of it (`IDENTITY_GATE_ANALYSIS.md`) |
| Blocked-chase fix | when a bandit's chase meets a wall | bandits no longer freeze; seed 1 bandit starvation 11 to 2 |

## Outcomes over 30 days (a7c84e9, recorded), classified (B19-EMERGE)

| | Seed 1 | Seed 2 | Class |
|---|---|---|---|
| Villager deaths | 5 elders, old age | 7 elders, old age | expected; no villager starved |
| Bandit deaths | 2 slain by a villager, 2 starved | 17 starved | after the chase fix: real scarcity under today's rules (poaching 25%, the market needs 15 coins and 60% health, no healing); **design question** SIM-F4 |
| Population day 30 | 118 | 118 | emergent |

## Decision for the owner

Approve this baseline (seeds 1 and 2, days 10 and 30, on a7c84e9). If SIM-F4's rule answers change bandit behaviour, the
change is measured and this proposal is updated once more before release, not re-baselined per fix.
