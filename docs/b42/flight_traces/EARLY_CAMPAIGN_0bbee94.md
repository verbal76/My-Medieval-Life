# Early 365-day flight campaign on 0bbee94 (Build 41 candidate), compared with chain 12 (b3c9eb5)

Run 43530227383 (long-sims.yml with the flight option, branch wip/b41-stream-candidate at 0bbee943ef25): seeds 1-4, 365 days,
checkpoints every 10 days, 100-day segments, recorder on, no extra switches. This is the same configuration as chain 12
(runs 43332151718 and 43332156022, b3c9eb5). Started 2026-11-13 23:51 UTC, completed 2026-11-14 06:19 UTC (success). Every
seed reached day 365. Money and item ledgers are OK in every segment, 0 script errors, no determinism twin. The
unbacked-reservation alerts come from the pre-fix recorder (0bbee94); they are the stale offers and short earmarks that
wip/b42-recorder-reservation now records as observations.

| | seed 1 | seed 2 | seed 3 | seed 4 |
|---|---|---|---|---|
| alive at days 10 / 100 / 200 / 365 | 107 / 152 / 218 / 257 | 109 / 135 / 146 / 183 | 111 / 150 / 179 / 296 | 111 / 136 / 212 / 329 |
| chain 12, alive at day 365 | 327 | 218 | 281 | 313 |
| starvation deaths (chain 12) | 0 (15) | 7 (24) | 30 (2) | 18 (6) |
| of which envoy journey deaths | 0 | 1 | 30 | 0 |
| of which navigation (stranded, could not reach) | 0 | 6 | 0 | 18 |
| adults with no job at day 365 (chain 12) | 73 (96) | 45 (84) | 102 (93) | 111 (87) |
| employed after day 90 | 72-81 | 72-76 | 66-76 | 71-78 |
| businesses open at day 365 | 4 | 0 | 0 | 1 |
| findings CRITICAL / HIGH / MEDIUM | 0 / 2 / 43 | 0 / 35 / 30 | 0 / 12 / 88 | 0 / 36 / 54 |
| unbacked-reservation alerts (pre-fix recorder) | 147 | 190 | 205 | 133 |

Reading:
- All 55 starvation deaths on 0bbee94 (chain 12: 47) are travel or navigation:
  - 31 envoy journey deaths (Agent F's fix, wip/b42-reg-travel);
  - 24 stranded or could-not-reach deaths (Agent L's fix, wip/b42-nav-stranding).
  - None is a village food shortage.
- Which defect dominates depends on the trajectory: seed 3 lost 30 envoys, seed 4 18 stranded villagers.
- Unemployment grows in every seed (employment capped at about 66-81 while adults reach 150-182): the B17F-JOBS / JOB-02 question (Agent H).
- Businesses mostly fail to last (0-4 open at day 365).
