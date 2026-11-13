# Chain 12 baseline investigation: the 32 gate differences and the economy since df67e8e

Owner directives 2026-11-12: `docs/directives/2026-11-12_build39_chain12_direction.md` and
`docs/directives/2026-11-12_chain12_baseline_economic_investigation.md`. Lead, 2026-11-12 evening (EST). **Baseline
decision: NOT APPROVED.** The candidate `docs/release/sim_baseline_candidate_b3c9eb5.json` is inactive; the accepted
baseline (`docs/release/sim_baseline.json` on the development line, recorded at `df67e8e`) is unchanged.

## 1. What the 32 findings are

Gate run 43321404909 (build 39, `b3c9eb5`): 32 blocking findings, all in `eq_s1`.

- 1 finding: the accepted baseline records no versions; this code is overworld generation 8, save version 23, so the gate
  cannot tell its differences from a regression (TEST-GOV-01).
- 31 value differences at days 10 and 30, seeds 1 and 2 (36 values compared; the 4 `leaks` values and 1 more match):
  households, alive, currency, treasury, fingerprint, item_ledger, deposits, animals (8 keys x 4 checkpoints, less the
  matches). Leaks are `{currency 0, items {}}` at every checkpoint on both sides.

Note: the copy of `sim_baseline.json` on `wip/requirements-control` and staging is an older file (commit `07dc786`);
the gate reads the development line's copy (`df67e8e`). A record inconsistency only; the gate is unaffected.

## 2. Integrity on chain 12 (the directive's item 4)

- **Currency and item conservation:** leak 0 and no item leak at every checkpoint of eq_s1 and eq_s2; no FATAL line.
- **Determinism:** recorded against unrecorded, shipped switches and Expansion 20 switches: identical at every
  checkpoint (gate). Local reruns of `b3c9eb5` (seeds 1, 2) and `428a494` (seed 1) reproduced CI's values exactly (3 of 3).
- **Save/load:** the gate's three save/load probes (seed 1, seed 2, seed 1 with switches): 0 added, 0 changed, 0 dropped,
  second round trip identical.
- **Script errors:** 0 in eq_s1, eq_s2, det_s1.

## 3. Where the values moved (the 31 value differences traced)

The simulation is chaotic: once one value differs, every later value differs. So each of the 31 differences is traced
to **the changes that moved the values**, step by step along the development line, from the gates' own eq_s1/eq_s2
outputs (36 gate runs) and local or CI reruns of single merges.

| Step | Interval | Responsible change | Evidence | Classification |
|---|---|---|---|---|
| 1 | `df67e8e` -> `1f2ff4f` (109 commits) | Build 25R1 scope: the outlaw band as its own household (`bf20dc9`, owner B25R1-Q2 a: households 25 -> 26 at the founding), the region, settlements, water, homesteads, presence and roads merges, overworld generations 5-8, the economy merges P1-P5 and owner decisions 32/33 | gates at f60772f, bfce680, a995397, a9e9f6e, 20e579e, 832f711, 1f2ff4f; founding bisect (`SIM_BASELINE_DIFFERENCES_B25R2.md`) | Expected (approved scope), but its economic effects are examined in section 4 and two problems are raised there |
| 2 | seed 2 only, at `229f76e` | LIFE-03/LIFE-04 merge (sage succession; a widow(er) may remarry) | local run: `f0a854c` (brush-off guard) keeps the old seed 2 values; `229f76e` gives the new ones | Expected (owner decisions) |
| 3 | seed 1 day 30, at `acc24b2` | audit-sim2 merge: JUS-02, NPC-02, REG-02 journey part | local runs: `e44d6b8`, `b3a1696` (EMP-03), `dd0ba5b` (audit-sim1) keep the old values | Expected (audit fixes) |
| 4 | chain 8, at `e21bfc6` | NPC-04 (the other three chain 8 merges change nothing) | CI runs on each merge (section 5) | Expected (audit fix) |
| 5 | chain 9, at `9da9e47` and `f04782f` | F015/P99 and the probe findings (traveller paths); REG-02 debt and SAV-04/NPC-01 change nothing | CI runs on each merge (section 5) | Expected (owner-approved fix; defect fix) |
| 6 | chain 11, at `5c712cf` | ND-23: the manor's grain relief no longer goes to the outlaw band (owner "Exclude the band") | local runs: `0ed4c8b` (guest trust) and `3f94e2b` (MP-07) keep chain 10's values; `5c712cf` gives chain 12's exactly | Expected (owner decision) |
| - | no effect | `f0a854c`, `e44d6b8` (audit fixes), `b3a1696`, `dd0ba5b`, chain 10 (owner decisions, INV-02 off, MP-06, NPC-01 fix), guest trust, MP-07, journey tests, the chain-scenario harness fix, ND-26, station_tap fix | identical values | - |

## 4. The economy since df67e8e (directive items 1-6)

Day 30, eq runs (wc/min/smi/car = woodcutters, miners, smiths, carpenters; tax, repairs = the treasury's 30-day totals;
mend = manor repair jobs done; cold = household-nights without firewood):

| commit | seed | alive | unemployed | wc/min/smi/car | logs | planks | iron ore | iron bars | coins in | coins out | tax | repairs | mend | cold |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| df67e8e | 1 | 112 | 3 | 5/8/3/3 | 2813 | 952 | 473 | 261 | 2057 | 1053 | 1996 | 311 | 81 | 7 |
| f60772f | 1 | 119 | 2 | 5/8/3/2 | 2559 | 851 | 480 | 318 | 2917 | 1360 | 2206 | 244 | 64 | 29 |
| bfce680 | 1 | 118 | 2 | 5/12/2/3 | 2332 | 724 | 480 | 325 | 2502 | 1189 | 2167 | 130 | 28 | 40 |
| a9e9f6e | 1 | 116 | 1 | 5/12/3/2 | 1572 | 694 | 480 | 270 | 1923 | 1382 | 955 | 111 | 21 | 39 |
| 1f2ff4f | 1 | 116 | 2 | 6/10/3/2 | 2250 | 600 | 399 | 200 | 1486 | 1129 | 1228 | 109 | 22 | 44 |
| c9da5db | 1 | 116 | 2 | 6/10/3/2 | 2250 | 600 | 399 | 200 | 1486 | 1129 | 1228 | 109 | 22 | 44 |
| acc24b2 | 1 | 119 | 1 | 6/11/3/2 | 2238 | 586 | 406 | 205 | 1525 | 1239 | 1065 | 94 | 20 | 43 |
| e21bfc6 | 1 | 117 | 2 | 6/10/3/2 | 2230 | 600 | 425 | 213 | 1455 | 1143 | 988 | 94 | 20 | 43 |
| 57583fb | 1 | 115 | 1 | 6/12/3/2 | 1581 | 614 | 426 | 220 | 1386 | 1109 | 1148 | 151 | 36 | 39 |
| b3c9eb5 | 1 | 114 | 0 | 6/12/2/2 | 2101 | 678 | 415 | 195 | 1388 | 1060 | 1192 | 140 | 26 | 48 |
| f60772f | 2 | 117 | 2 | 4/8/3/2 | 2684 | 921 | 480 | 304 | 2325 | 1227 | 1777 | 351 | 93 | 29 |
| bfce680 | 2 | 113 | 3 | 5/10/2/2 | 2798 | 774 | 480 | 255 | 2029 | 1107 | 1751 | 241 | 60 | 35 |
| a9e9f6e | 2 | 113 | 2 | 5/10/3/2 | 2540 | 662 | 470 | 229 | 1903 | 1175 | 1310 | 202 | 47 | 30 |
| 1f2ff4f | 2 | 118 | 3 | 2/9/2/2 | 2492 | 865 | 460 | 218 | 1760 | 951 | 1634 | 334 | 87 | 36 |
| c9da5db | 2 | 112 | 0 | 4/13/2/2 | 2537 | 830 | 480 | 243 | 1901 | 1107 | 1644 | 261 | 67 | 32 |
| acc24b2 | 2 | 112 | 0 | 4/13/2/2 | 2537 | 830 | 480 | 243 | 1901 | 1107 | 1644 | 261 | 67 | 32 |
| e21bfc6 | 2 | 112 | 0 | 4/13/2/2 | 2537 | 807 | 471 | 226 | 1841 | 1008 | 1713 | 250 | 63 | 31 |
| 57583fb | 2 | 112 | 1 | 5/13/2/2 | 1766 | 659 | 450 | 195 | 1749 | 1027 | 1215 | 169 | 39 | 32 |
| b3c9eb5 | 2 | 113 | 0 | 5/11/3/2 | 1832 | 685 | 480 | 245 | 1967 | 1063 | 1500 | 210 | 49 | 42 |

### 4.1 Why miners rose while smiths and carpenters fell (item 1)

- The job market opens miner posts from the reachable ore and quarry stone (`ore / ore_per_miner` less miners and
  labourers, NPCBrain market): 12-13 open miner posts at day 5 on **both** `df67e8e` and chain 12. That rule is unchanged.
- What changed is the other trades' pay. 30-day earnings by trade, seed 1: carpenters `df67e8e` 2062 for 3 (687 each),
  chain 12 533 for 2 (266 each); tanners 282 -> 6; miners about 150 each on both. Carpenters' work is largely the manor's
  repairs (planks for mends): the treasury's repair spending fell 311 -> 140 and mend jobs 81 -> 26.
- The treasury's spending fell because its **wealth tax** fell (1996 -> 1192 over 30 days): the tax is a rate on each
  household's cash above an exemption, and households held less cash (3343 -> 2796), because **the village earned less
  from the caravans** (coins in 2057 -> 1388; coins out unchanged, 1053 -> 1060). Exports of planks (148 -> 88) and iron
  bars (111 -> 65) fell.
- So: less outside income -> less cash -> less tax -> fewer repairs -> carpentry pays less -> carpenters and a smith
  move to the open miner posts. The extra miners add no ore: seams are worked out within the 30 days (17-21 seams), output
  stays 400-480 whatever the number of miners (8-13 across checkpoints). Miners' pay per head did not fall (ore prices;
  consignment, owner decisions 32/33).
- The fall in tax first appears between `bfce680` (tax 2167, seed 1) and `a9e9f6e` (955): the Build 25R1 economy merges
  (econ1 founding without the full-bench gate and household first tool; econ2 ore on consignment P4 and land cleared by
  labour P5; econ3/econ5 traders and neighbours carrying spare ore; also generation 5-7 map merges). Seed 2 moves the same
  way less strongly and partly recovers (1f2ff4f: mend 87, manor wages 500, close to the baseline). **Not attributed to a
  single merge** (see section 6).

### 4.2 Why logs fell with more woodcutters (item 2)

- Woodcutters fell without a demand check (`_woodcutter`: the nearest grown tree within 70 cells; sell when carrying 6).
  Trees were not short: grown trees at day 20/30 were 152/138 on chain 12 against 93/109 on `df67e8e`.
- On `df67e8e` households **hoarded** firewood: logs held by households rose 146 -> 1180 over the 30 days (they burn about
  25 a night). On chain 12 household stocks level off at about 540-609 from day 15; woodcutters then hold full loads they
  cannot sell (30-49 logs held by woodcutters, days 10-25), and felling slows from about 16 trees a day to 8-9.
- Firewood burned is the same (743 vs 732 logs in 30 days). Lower log production is **demand-limited**: less surplus, not
  less supply.

### 4.3 Firewood shortages (raised by this investigation)

Household-nights without firewood: 7 on `df67e8e`, 29-48 on every Build 25R1 and later checkpoint. Broken down (chain 12):
- seed 1: household 25 30 nights, household 10 15, three others 1 each; seed 2: household 25 29, household 10 9, household 24 4.
- **Household 25 is the outlaw band's camp** (members with no "adult" role, nothing earned, 1-4 coins). Bandits never buy
  firewood, and the dawn count (`World`, "households had no firewood last night") counts the camp every night. Going without
  firewood has no effect but this count and the player's daily message, so the band inflates the message ("N households had
  no firewood") with the outlaws' camp. **Classified: unintended (a counting and message defect introduced with the band's
  own household, `bf20dc9`).** Recorded as ND-29. Proposed fix: skip the band's household in the count, as ND-23 skips it
  for relief; or, if the owner prefers, the band keeps its own fire. Not merged: it would not change the world's state.
- Household 10 is a poor village household (one adult, coins spread below a log's price in each purse): 7 nights on
  `df67e8e`, 9-15 now. A legitimate outcome (WDR-022), recorded.

### 4.4 Classification (item 6)

| Effect | Classification |
|---|---|
| Founding: the band as its own household; overworld generation 8 | direct, intended (owner decisions) |
| Less outside income (planks, bars) and the lower wealth tax, repairs and mends | emergent; first appears with the Build 25R1 economy merges; **not yet attributed to a single change** |
| Carpenters and a smith moving to mining | emergent consequence of the above |
| Miners beyond what the seams can use (ore output capped by seams worked out) | emergent; a weakness of the miner-post rule that predates Build 25R1 (13 open posts at day 5 on `df67e8e` too); more posts are now filled because other trades pay less. Proposed for the owner, not changed |
| Lower log production | emergent, demand-limited; firewood burned unchanged; households hoarded on `df67e8e` |
| Firewood count including the band's camp | **unintended: ND-29** |
| More relief (grain relief 68 -> 117; chapel relief households 59 -> 82) | emergent consequence of lower household cash; relief rules unchanged |
| Conservation, determinism, save/load | intact |

## 5. Chain 8 and chain 9 merges

CI runs of each merge (long-sims, seeds 1 and 2, 30 days, on `wip/b25-attr-<sha>`; runs 43340320854-43340343765). A CI run of
an unchanged merge reproduced the gate's values exactly, as the local runs did.

| Merge | Values (s1 d10, s1 d30, s2 d10, s2 d30: households/alive/currency/treasury) | Effect |
|---|---|---|
| chain 7 `5503614` (gate) | 26/110/2957/70, 26/119/3295/37, 26/107/2973/107, 26/112/3760/185 | - |
| `e9ee6f4` emigration with spouse | identical to `5503614` | none |
| `b0faa1a` BIZ-06 | identical | none |
| `0d0ecd0` TRD-04 | identical | none |
| `e21bfc6` NPC-04 (evening companion away or underground) | 26/109/2957/70, 26/117/3321/76, (s2 d10 same), 26/112/3799/298 | **moves the values**: expected (audit fix; owner-approved list) |
| `3bb486d` REG-02 debt part | identical to `e21bfc6` | none |
| `9da9e47` F015/P99 (food held vs purchasing power; fallback food purchase) | 26/114/3037/56, 26/122/3386/90, 26/111/3032/87, 26/118/3691/146 | **moves the values**: more villagers alive on both seeds; expected (owner approved 2026-11-12) |
| `f04782f` probe findings (travellers walk round settlement buildings; village map) | 26/109/2997/95, 26/115/3286/193, 26/107/3010/106, 26/112/3688/107 | **moves the values** to chain 9's exactly: expected (defect fix) |
| `57583fb` SAV-04 test and NPC-01 walk back-off | identical to `f04782f` | none |

So every difference after `1f2ff4f` is accounted for by six merges: LIFE-03/04, audit-sim2 (JUS-02, NPC-02, REG-02 journeys),
NPC-04, F015/P99, the probe findings (traveller paths), ND-23.

## 6. Unresolved

- The step from `bfce680` to `a9e9f6e` (Build 25R1 economy and map merges) is where outside income and the wealth tax
  first fall; which merge does it is not yet isolated. Isolating it needs about 8 more paired runs (2 seeds each) on the
  merges in that interval; their aggregate values are noisy on 2 seeds (seed 2 partly recovers), so the 365-day
  four-seed campaigns are the better evidence of sustainability.
- Sustainability over long periods (item 5): the chain 12 campaigns (runs 43332151718 seeds 1-2 and 43332156022 seeds
  3-4, 365 days, recorded) are running; the earlier 365-day campaign on `1f2ff4f` (run 42297637074) reached 365 of 365 days
  on both seeds with 0 CRITICAL and 0 confirmed defects.

## 7. Recommendation (interim)

Not yet. The baseline candidate should wait for: the chain 8/9 attributions (section 5), the chain 12 campaigns, and the
owner's view on ND-29 and on the miner-post weakness. No regression in conservation, determinism, saves or script errors
was found; the economic shift since `df67e8e` is real (less outside income, lower tax, fewer repairs), traceable to the
Build 25R1 economy interval, and is not yet shown to be either intended or a defect.
