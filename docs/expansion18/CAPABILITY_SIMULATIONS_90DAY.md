# Capability simulations, round 2 (X18-SIM): 90-day runs on the Build 18 code, no constants adopted

PROSPECTIVE (Expansion 18, PROS-18). Register: X18-SIM (owner directive 2026-10-21,
`docs/directives/2026-10-21_expansion18_capability_simulations_contracts.md`). Companion to
`CAPABILITY_SIMULATIONS.md` (round 1: 30-day runs on the Build 16 baseline, seeds 1-4, four scenarios, levels 2/5/8/10), which left the
90-day runs, the regional harness by profile and the revised model "not yet run". This report is those runs.

- **Evidence only.** No multiplier, profile or constant was changed or adopted by this work. The recommendations in section 5 are an agent
  recommendation for the owner's Q18-11 decision. (Q18-11A was answered on 2026-10-22, after round 1: the `approved` profile holds the
  owner's numbers. It is run here beside the three hypotheses so the evidence covers it.)
- Code: `wip/b18-capsim` from `wip/build18` `421525c` (Build 18 combined). Analysis-only changes: `economy_sim.gd --cap-at 30,60` prints the
  capability report at those days of the one run (SIM-01: milestones read from one continuous run), `tools/x18_capsum.py` makes the tables, and
  `caravan_compare.gd`'s currency check now counts the outlaw and scenario purses that come in from outside (it reported a false leak of 30).
- Raw numbers: `data/capsim_90day_summary.json` (every run's day 30, 60 and 90 report line, deaths per checkpoint, ledger line).

## 1. What was run, and what was not

Every run is `economy_sim.gd --days 90 --every 10 --cap-at 30,60 --cap-report`, one continuous run per configuration (the day 30 and 60 columns are
checkpoints of the same run; no run was restarted to report a shorter duration). The capability switch forces the level on the six implemented
industries (mining, forestry, farming, smithing, carpentry, tanning) through `CapabilityHook`; trade has no production loop; cooking, brewing, medicine, weaving, hunting and
husbandry have no capability industry and were not faked (`CapabilityHook.analysis`; see round 1 section 1).

| Group | Seeds | Configurations (level 10 unless stated) | Days | Status |
|---|---|---|---|---|
| Normal village | 1 | baseline (L0), conservative, moderate, aggressive, approved | 90 (30, 60 read) | done |
| Normal village, second seed | 2 | baseline only | 90 | done |
| Resource-poor (seams and boulders at 40%, field yield 2/3) | 1 | baseline, moderate, aggressive | 90 | done |
| Regional harness (`caravan_compare.gd`), three off-map settlements of 25/70/140 people | 1 | neutral, conservative, moderate, aggressive, approved | 30 | done |
| Levels 2, 5 and 8 (the diminishing-returns shape) | 1 | -- | 90 | **not run** (round 1 has 30-day sweeps on the Build 16 baseline) |
| Seed 2 with a model; seeds 3, 4 at 90 days | 2-4 | -- | 90 | **not run** |
| Resource-poor conservative and approved; resource-rich, labour-poor, labour-rich | 1 | -- | 90 | **not run** (round 1 has all four at 30 days) |
| `revised_bounded` | -- | -- | -- | not run: superseded by `approved` (2026-10-22) |

Why: the shared machine ran at a load of 8-11 on 4 cores for most of the session, so a 90-day run took 26-110 minutes instead of about 10; nine runs fit in the
time budget of about three hours. The prioritised set above was chosen so that every model and the baseline are compared on identical seeds and
start states at the three horizons, plus one hard scenario and one second seed to size the noise. Runs were queued in priority order and the queue was stopped, not
edited, when time ran out. Nothing that is absent from the table was run and reported.

**Ledger status of every run: no FATAL line in any run; every run ended `LEAKS: currency 0; items {}; deposits []; animals {}`** (nine of nine, and the
checkpoint leak column was 0 throughout). A village failing (a starvation, broke households) is an outcome, recorded below, and did not stop a run.

Assumptions (unchanged from round 1): the models are the owner's unapproved test hypotheses (level 10: conservative +10% output / +5% pay, moderate +20% / +8%,
aggressive +35% / +15%, the owner's diminishing-returns shape); OutputMultiplier shortens the work time of each unit and never adds a unit from the same inputs (ore
still comes from a seam, inputs from packs, crops from fields); PayMultiplier raises only the wages tied to these industries (the manor's quarry and mending
wages), because every other productive worker is self-employed and paid by selling. `approved` is the owner's 2026-10-22 numbers (mining and forestry +5% output / +2% pay;
tanning and trade +10% / +4%; carpentry, smithing and masonry +15% / +6%; farming +10% work rate, labour time only, +4% pay).

## 2. Section 5 metrics, normal village, seed 1, level 10

Identical seed and start state (the village at 1342 ore and stone in its seams and boulders, 115-126 people). Percentages are against the baseline of the same horizon.

### 2.1 Summary table (the directive's section 5 layout), 90 days

| Metric | Baseline | Conservative | Moderate | Aggressive | Approved |
|---|---|---|---|---|---|
| Production output (units, six industries) | 19854 | 21405 (+7.8%) | 20296 (+2.2%) | 20226 (+1.9%) | 20684 (+4.2%) |
| Labour cost (coins earned by the productive workers) | 16659 | 16951 | 16284 | 16729 | 17487 |
| Production cost (coins they spent) | 8740 | 9845 | 9725 | 8714 | 10253 |
| Net business profit (18 trades; losing / broke) | 5098 (10 / 7) | 4653 (10 / 4) | 5127 (8 / 6) | 4726 (9 / 7) | 5374 (8 / 6) |
| Household purchasing power (median purse; food days; broke households) | 128; 4.43; 2 | 103; 4.36; 0 | 98; 2.91; 1 | 132; 4.53; 1 | 111; 5.02; 0 |
| Resource depletion (ore and stone left of 1342; iron ore used; logs used) | 309; 702; 936 | 304; 724; 946 | 277; 710; 1024 | 325; 706; 852 | 290; 672; 973 |
| Trade volume (caravan coins in + out) | 7868 | 7813 | 7463 | 7820 | 7726 |
| Economic failures (deaths; starved; meals missed for no food / no money) | 13; 0; 0 / 0 | 17; 0; 1 / 49 | 13; 0; 6 / 1 | 13; 0; 0 / 3 | 13; 0; 0 / 0 |
| Gini of household purses | 0.488 | 0.484 | 0.402 | 0.355 | 0.342 |
| Alive | 124 | 132 | 123 | 123 | 124 |
| Ledger balanced | yes | yes | yes | yes | yes |

### 2.2 Output over the three horizons (one run each; days 30 and 60 are its checkpoints)

| Horizon | Baseline | Conservative | Moderate | Aggressive | Approved |
|---|---|---|---|---|---|
| Day 30 | 7974 | 8105 (+1.6%) | 8150 (+2.2%) | 8029 (+0.7%) | 8282 (+3.9%) |
| Day 60 | 14273 | 15091 (+5.7%) | 14505 (+1.6%) | 14399 (+0.9%) | 14810 (+3.8%) |
| Day 90 | 19854 | 21405 (+7.8%) | 20296 (+2.2%) | 20226 (+1.9%) | 20684 (+4.2%) |

### 2.3 Output by industry, day 90 (units; units per worker-day)

| Industry | Baseline | Conservative | Moderate | Aggressive | Approved |
|---|---|---|---|---|---|
| Mining | 1417 (1.97) | 1434 (1.99) | 1273 (1.57) | 1432 (1.99) | 1206 (1.68) |
| Forestry | 5390 (14.97) | 7022 (15.60) | 5846 (16.24) | 5686 (15.79) | 6528 (18.13) |
| Farming | 10800 (10.00) | 10800 (10.00) | 10800 (10.00) | 10800 (10.00) | 10800 (10.00) |
| Smithing | 757 (4.21) | 746 (4.14) | 813 (4.52) | 817 (4.54) | 772 (4.29) |
| Carpentry | 1350 (7.50) | 1250 (6.94) | 1372 (7.62) | 1333 (7.41) | 1184 (6.58) |
| Tanning | 140 (0.78) | 153 (0.85) | 192 (1.07) | 158 (0.88) | 194 (1.08) |

The full per-horizon tables (days 30, 60, 90, with prices, availability and all metrics) are reproducible from `data/capsim_90day_summary.json`
(`python3 tools/x18_capsum.py LOGDIR "title|day|tag:Name,..."` on the raw logs).

## 3. Scenario and seed context

### 3.1 Resource-poor village (seed 1, level 10), 90 days

| Metric | Baseline | Moderate | Aggressive |
|---|---|---|---|
| Production output | 14005 | 13241 (-5.4%) | 13800 (-1.5%) |
| Labour cost / production cost | 13056 / 8434 | 13515 / 9016 | 11892 / 8256 |
| Net business profit | 2579 | 2503 | 2083 |
| Household purchasing power (median purse; food days; broke) | 76; 4.28; 0 | 74; 3.75; 1 | 80; 4.58; 1 |
| Ore and stone left of 534; iron ore used; logs used | 108; 500; 1010 | 100; 512; 913 | 103; 508; 903 |
| Trade volume | 8318 | 8020 | 7891 |
| Deaths; starved; meals missed no food / no money | 15; 0; 0 / 0 | 12; 0; 3 / 15 | 15; 1; 24 / 0 |
| Gini | 0.528 | 0.502 | 0.461 |
| Ledger balanced | yes | yes | yes |

Mining output was 628, 627 and 636 units in the three runs: **the deposit set the mining output, not the model.** The aggressive run had the
only starvation death of the nine runs and 24 missed meals for no food; with one seed this is a note, not a finding.

### 3.2 How large is run-to-run variation? Baseline seed 1 against seed 2 (same code, no bonus)

| Baseline | Day 30, seed 1 / 2 | Day 90, seed 1 / 2 |
|---|---|---|
| Production output | 7974 / 7013 (-12%) | 19854 / 17312 (-13%) |
| Forestry units | 2494 / 1703 (-32%) | 5390 / 3380 (-37%) |
| Smithing units | 330 / 245 (-26%) | 757 / 491 (-35%) |
| Net business profit | -71 / -541 | 5098 / 2384 |
| Trade volume | 2675 / 1482 | 7868 / 5535 |
| Gini | 0.365 / 0.373 | 0.488 / 0.409 |

### 3.3 Regional trade between settlements (`caravan_compare.gd`, seed 1, 30 days, 15 caravan visits; 242 checks, 0 failures)

All five profiles (neutral, conservative, moderate, aggressive, approved) produced **identical** shadow trade: village coins in 1189 and out 1451 (net -262), 0 coins
created, region purses 2912 of 2650, carriage fees 0, and the same unmet-need breakdown ("no supplier" 33588 units, "funds" 1477, "no carriage" 146). The regional
trade is bound by what the three settlements stock and want, and by what the village holds for sale (wheat 516 of the sales abroad); faster production abroad did not change what
was bought or sold in 30 days. For comparison the live village's own caravan trade differed little across models in the economy runs (table 2.1: 7463-7868).
The harness does not show the effect of capability on trade between settlements of different size; the first run of the harness also reported a false currency leak of 30
(an uncounted outlaw purse in its check), fixed here and passing since.

## 4. What the numbers say

1. **Every model is positive against the baseline for total output at all three horizons, but the size does not follow the size of the bonus.** At day 90: conservative
   +7.8%, moderate +2.2%, aggressive +1.9%, approved +4.2%. The ordering is the reverse of the bonuses. The baseline of a different seed differs from seed 1 by 13%, and by 26-37% in
   forestry and smithing. A model's difference is therefore smaller than the difference two seeds make with no model at all. The deterministic runs are exactly reproducible, but a few percent of
   work time re-plans villagers' days and the paths diverge. Round 1's conclusion (at 30 days no model shows an effect larger than run-to-run variation) stands at 90 days for total output.
2. **Capability did not create resources or deplete them faster.** Ore and stone left at day 90: 304, 277, 325 and 290 for the models against 309 for the baseline, of 1342;
   mining units were 1206-1434 against 1417 and mining units per worker-day did not rise in any model. The seams are worked out whatever the model, which is the structural limit
   round 1 found; here it shows in the resource-poor run too (628 / 627 / 636 units). Every ledger balanced, so nothing was created.
3. **Farming is time only.** Grain was 3600 / 7200 / 10800 at days 30 / 60 / 90 in every normal-village run (and 2400 / 7200 at days 30 / 90 in the resource-poor runs), the same in every model, as the owner's F1 decision (labour time only, never yield) requires.
4. **Smithing is the one industry with a consistent signal.** Moderate, aggressive and approved smithed more than the baseline at all three horizons (day 30: 388, 378, 362 against 330; day 60: 644, 670, 643
   against 580; day 90: 813, 817, 772 against 757; +2% to +8% at day 90). Conservative was above at days 30 and 60 and below at 90. Carpentry showed none (1184-1372 against 1350). Tanning was higher for moderate and approved
   (192, 194 against 140) but the base is small (under 200 units). These are single-seed readings.
5. **Pay and household purchasing power: no consistent effect.** Median household purse at day 90 was 98-132 against 128; the Gini was lower under every model (0.342-0.484 against 0.488) but seed 2's baseline is 0.409, so this is inside the noise.
   Labour compensation moved -2% to +5%. Only the manor's quarry and mending wages are tied to these industries, so a pay multiplier has little to act on in this economy.
6. **Village failures were few and not tied to the bonus.** No model starved anyone in the normal village. The conservative run missed 49 meals for want of money (against 0 for the baseline), the moderate run 6 for want of food;
   the aggressive resource-poor run had the only starvation (1 death, 24 missed meals). All isolated to one run each.
7. **No runaway advantage.** The largest industry gain at level 10 was forestry +30% (conservative), +21% (approved) at 90 days, with no change in logs used or in the stand (logs used 852-1024 against 936).
   Wealth concentration did not rise under any model.

## 5. Recommendation (agent recommendation for the owner's Q18-11 decision; nothing is adopted)

Not chosen by default and not chosen on the measured output: the output evidence cannot rank the models, because the differences sit inside seed-to-seed variation. The recommendation therefore rests on
the structural findings, which hold in every run, and on the consistent per-industry signals.

| Industry | Recommendation | Evidence |
|---|---|---|
| Mining | Keep the output gain small (the owner's +5% is consistent). A larger gain only reaches the end of the seam sooner. | Output set by the deposit in every run, including the resource-poor ones; no model raised units per worker-day. |
| Forestry | Small gain (+5%) is safe; a larger one is not shown to help. | Higher forestry output in all four models at day 90, no extra logs used or stand pressure; but the noisiest industry (seed 2 baseline 37% lower). |
| Farming | Labour time only, as decided (F1). No yield effect is possible or wanted. | Grain identical in every run; the time saved frees the farmers for other work, which these runs do not measure separately. |
| Smithing | The industry that can carry the largest gain (the owner's +15% is consistent with the moderate and aggressive hypotheses, which gave +2% to +8% in one seed). A gain above +15% is not supported. | Higher at all three horizons for the three larger models; limited by ore and demand; no ore created. |
| Carpentry | Same shape as smithing; no gain was measured, so the evidence neither supports nor opposes +15%. | 1184-1372 against 1350: noise. |
| Tanning | +10% is harmless; the evidence is too thin (under 200 units) to say more. | Higher for moderate and approved only. |
| Trade | No evidence either way: no production loop, and the regional harness shows no profile effect over 30 days. Defer until trade has measurable work. | Identical shadow trade across all five profiles. |

Across industries: **different curves are justified** (finite-source industries low, input-bound crafts higher, farming time-only), which is the structure of the `approved` profile; the aggressive hypothesis is
not supported (its extra multiplier acts on finite seams and woods and showed no output advantage, and its resource-poor run had the only starvation); a single uniform curve (conservative or moderate) is acceptable but gives no more
measurable benefit than `approved`. `approved` showed no adverse signal in any measure: no starvation, no broke households at day 90, the lowest Gini (0.342), the highest labour compensation (17487), no extra depletion, and the same trade.
No revised model was needed: the three hypotheses were not all unsuitable, only indistinguishable, so no further model was proposed or tested.

## 6. Limitations

- One seed carries every model comparison (seed 1); seed 2 was run for the baseline only. Differences under about 15% in output, and under about 35% in an industry, are within variation (section 3.2) and must not be read as model effects.
- Levels 2, 5 and 8 were not run at 90 days, so the diminishing-returns shape is evidenced only by round 1 (30 days, Build 16 baseline), where it was also inside the noise.
- Resource-rich, labour-poor and labour-rich scenarios, and the resource-poor conservative and approved runs, were not run at 90 days; settlement-size and infrastructure variation exist only in the regional harness, where capability changed nothing.
- The harness's regional trade is demand- and supply-bound and does not respond to production speed at this horizon; trade-volume conclusions between settlements are therefore not available.
- The outcomes are measured, not thresholded (WDR-022): no figure here is a pass or fail on the economy. The only pass/fail checks are the ledgers (all passed) and the existing tests.
- Round 1's numbers (Build 16 baseline) and these (Build 18 baseline: 1342 ore and stone, not 880) are not comparable run for run.
- Section 4 of the directive (contract smoke tests, Q18-12 and Q18-13) is a different requirement and is not covered here.

## 7. Reproduce

```
godot --headless --path game --script res://tests/economy_sim.gd -- --days 90 --seed 1 --every 10 --cap-at 30,60 --cap-report
godot --headless --path game --script res://tests/economy_sim.gd -- --days 90 --seed 1 --every 10 --cap-at 30,60 --capability 10 --cap-profile moderate [--cap-scenario resource_poor]
godot --headless --path game --script res://tests/caravan_compare.gd -- --days 30 --seed 1 --profiles neutral,conservative,moderate,aggressive,approved
python3 tools/x18_capsum.py LOGDIR "title|90|n1_base:Baseline,n1_moderate_L10:Moderate"
```
