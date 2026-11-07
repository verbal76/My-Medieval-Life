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

## Generation 8 baseline candidate (2026-11-06 night; TEST-AUDIT-Q2, conditional; NOT accepted)

Prepared after the 365-day campaign on the candidate passed. **It is a candidate only.** The accepted baseline
`docs/release/sim_baseline.json` (`df67e8e`) is unchanged, with its history, and still blocks. Promoting it needs the owner.

- **Candidate file:** `docs/release/sim_baseline_candidate_gen8.json`, format `mml-sim-baseline/1`, commit `1f2ff4f`, overworld
  generation 8, save version 23, days 10 and 30 of seeds 1 and 2. Built from the gate's own runs `eq_s1` and `eq_s2` of release
  run 42297641550 (code `1f2ff4f`, artifact `sim-gate` 13543193307), with the gate's own `summarise`: the same values an
  accepted baseline records, and nothing hand-entered.
- **The 365-day campaign on `1f2ff4f` (run 42297637074, 21:33 UTC to 00:47 UTC):** both seeds reached 365 of 365 days, stopped
  "completed". 0 CRITICAL and 0 confirmed defects on each seed, archive checks ok, workbooks ok. No segment's defect step fired
  (script errors, ledgers, twin agreement, save round trips are each segment's own checks). The homestead water script error of
  the `832f711` campaign (seed 2, days 200-300) did not recur.
  - The remaining findings are the flight recorder's unconfirmed heuristics (TEST-GOV-01: not defects by themselves). Seed 1:
    48 HIGH, 65 MEDIUM (`832f711`: 20 HIGH, 78 MEDIUM); the most frequent are trades refused many times in a row (wheat 7,072 times
    for one villager, iron ore). Seed 2: 99 HIGH, 45 MEDIUM (`832f711`: 108, 45); villagers failing to reach a goal, logs not bought.
    Seed 1's HIGH count rose, and is the one change worth an owner's look: it is
    consistent with the plans now kept across saves (TEST-AUDIT-Q1, `adf71ec`: a villager goes on asking where they would have
    replanned), but that is not proven. Not investigated further (owner's development hold); listed as an open finding.
- **Gate on `1f2ff4f` (run 42297641550):** determinism identical at every checkpoint (shipped and Expansion 20 switches);
  conservation clean; 32 blocking findings: the first says the accepted baseline is not applicable (no versions recorded; this
  code is generation 8, save 23); the other 31 are the value differences below.

| Seed, day | Value | Accepted (`df67e8e`) | Candidate (`1f2ff4f`) |
|---|---|---|---|
| 1, 10 | households / alive | 25 / 107 | 26 / 110 |
| 1, 10 | currency / treasury | 3,314 / 130 | 2,957 / 70 |
| 1, 30 | households / alive | 25 / 112 | 26 / 116 |
| 1, 30 | currency / treasury | 4,013 / 323 | 3,366 / 161 |
| 2, 10 | households / alive | 25 / 109 | 26 / 107 |
| 2, 10 | currency / treasury | 3,034 / 190 | 2,965 / 95 |
| 2, 30 | households / alive | 25 / (same) | 26 / (same) |
| 2, 30 | currency / treasury | 3,597 / 184 | 3,775 / 274 |
| all four | leaks | 0 | 0 (unchanged) |
| all four | fingerprint, item ledger, deposits, animals | differ | (follow from the above) |

**Attribution.** Every difference follows from the founding: the 26th household (the outlaw band's own claim, `bf20dc9`,
owner-approved B25R1-Q2 a, bisected above) and overworld generations 6-8 (B25R1 and B25R2 repairs: roads, river crossings,
booth seating, the manor hand's door), which change what the founding's people do from the first hour. No rule of the economy
changed; leaks are 0 in both; determinism is identical. Nothing is unexplained.

**Caution for promotion.** The next package will come from `wip/b25r2-rev2` (the owner's playtest fixes: hosting for 4, caves,
Host a game, tiles made at the start, the label). None of those touches the simulation (network, interface and drawing only),
but the gate must run on that exact commit: if its `eq_s1`/`eq_s2` values differ from this candidate, this candidate does not
apply to it and a new one is prepared, not this one promoted.

**Recommendation:** accept a generation 8 baseline, recorded from the final package's commit, once the owner has read this. The
owner decides; nothing is promoted here.
