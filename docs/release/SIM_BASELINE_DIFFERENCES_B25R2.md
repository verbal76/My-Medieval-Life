# Simulation gate: baseline differences on Build 25 Revision 2 (investigated, not re-recorded)

Owner answer B25R2-Q1: baseline differences are investigated, never re-recorded automatically. This records what was found.
The accepted baseline stays `docs/release/sim_baseline.json` (recorded from `df67e8e`, 2026-11-03).

## The gate on the candidate

Run 42274351589, code `832f711` (sim-gate on `wip/b25r2-playtest`): 19 runs, 425 simulated days, 8 seeds.
- Determinism: recorded against unrecorded, seed 1, shipped switches and Expansion 20 switches: identical at every checkpoint.
- Blocking findings: 31, every one a difference from the accepted baseline at days 10 and 30 (seeds 1 and 2). No
  conservation, ledger or script-error finding.

| Value | Baseline (`df67e8e`) | F2 `20e579e` (gate 42154224992) | Candidate `832f711` |
|---|---|---|---|
| seed 1 day 10 households | 25 | 26 | 26 |
| seed 1 day 10 alive | 107 | 108 | 110 |
| seed 1 day 30 alive | 112 | 117 | 116 |
| seed 1 day 10 currency | 3314 | 3036 | 2957 |
| seed 1 day 30 currency | 4013 | 3670 | 3366 |
| seed 1 day 10 treasury | 130 | 62 | 70 |
| seed 2 day 10 alive | 109 | 110 | 107 |
| seed 2 day 10 currency | 3034 | 2960 | 2965 |

## Cause

1. **The differences predate B25R2:** F2, the B25R1 candidate, already differed from the baseline in the same values.
2. **The first difference is at the founding, not in play.** A new seed 1 world has 26 households and 110 people on F2
   and on the candidate; at `df67e8e` it has 25 households and 110 people. A one-hour trace of the candidate's first ten
   days shows no household created after the founding.
3. **Bisected** (founding households, seed 1, every step built and run): the first commit with 26 is `bf20dc9` "The band
   moves to the wild; water, works, livestock and crafting on claims (B25R1-014, B25R1-Q2 a, B25R1-Q3)": the outlaw band
   became its own household on a concealed claim in the open country. Owner-approved (B25R1-Q2 a). Its members were
   counted in a village household before; now they are a household of their own, so the founding differs and every value
   downstream moves (the first day's job board, pantries, alms, prices).
4. B25R2's own changes move the values further (F2 to candidate). They change what villagers do on the region roads and
   at the courier booths (overworld generation 8, booth seating), a manor hand without a house (the 127 script errors),
   and save fidelity. None changes a rule of the economy.

## Not done

The baseline is not re-recorded (B25R2-Q1). Recording a new accepted baseline needs the owner's permission
(`tools/sim_gate.py --write`). Recommendation: accept a new baseline from the final B25R2 commit once the 365-day campaign
on it is read, since the remaining differences are explained by an approved feature and by the repairs.
