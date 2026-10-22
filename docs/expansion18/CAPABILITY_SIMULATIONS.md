# Capability simulations (X18-SIM): comparative evidence, no constants adopted

PROSPECTIVE (Expansion 18, PROS-18).
- Directive: owner, 2026-10-21, `docs/directives/2026-10-21_expansion18_capability_simulations_contracts.md` on staging (register X18-SIM).
- **Test hypotheses only.** The game's active profile stays neutral (every multiplier 1.0), and no balancing constant is set. The owner reviews this evidence first.
- Baseline code: `wip/expansion18-preparation` at `1dea6c9` (the released Build 16 plus Expansion 18 prospective code; no Build 17 code).
- Runs: 30-day economy simulations of the normal village (seeds 1-4) and four scenarios (seed 1). 59 runs were made (41 distinct configurations: the level-10 runs were repeated once mining was forced too), every one with `LEAKS: currency 0; items {}; deposits []; animals {}`.

## 1. Method

- **The real systems.** `game/tests/economy_sim.gd`, the existing deterministic simulation (`STEP` 0.5 s, one game minute; the same seeded village every run).
- **The switch.** Each run forces a capability level on the implemented industries through `CapabilityHook`. This is the one analysis switch:
  - It is off in the game.
  - With it off, the economy simulation's fingerprint is identical to the code before the hook: 10 days on seed 1, every sample's fingerprint compared.
- **What OutputMultiplier does.** It shortens each unit's existing work time:
  - a mining swing (`mine_minutes`);
  - a felling (`chop_minutes`);
  - a recipe run (recipe `minutes`; smithing at forge and anvil, carpentry at sawhorse and workbench, tanning for hides, pelts and leather);
  - the farmers' sowing and cutting (`Farming.field_work_minutes`).
- **Skills and the level together.** Where a worker's own Skill already shortens the same work, the two gains add over the base once each (no double counting).
- **What PayMultiplier does.** It raises the only existing wages tied to these industries: the manor's quarry wage (mining) and mending wage (carpentry). Every other productive worker in the game is self-employed and earns by selling, so the pay effect is otherwise indirect.
- **What does not change.** Every unit still ends in the existing rule:
  - ore and stone come out of a seam or boulder;
  - recipe inputs leave the pack;
  - grain is the field's crop.
- **Conservation.** Every run printed `LEAKS: currency 0; items {}; deposits []; animals {}`. This is economy_sim's ledger: currency, every item, each deposit and each animal kind balance.
- **Models (UNAPPROVED test hypotheses, owner directive).**
  - Conservative: +10% output, +5% pay at level 10.
  - Moderate: +20%, +8%.
  - Aggressive: +35%, +15%.
  - All use the owner's diminishing-returns shape: 18% of the gain at L1, 48% at L3, 70% at L5, 92% at L8.
  - Level 0 is the baseline for every model (multiplier 1.0), so it was run once.
- **Scenarios**, built only by changing the start state with existing data and systems (`tests/capability_metrics.gd`):
  - resource-poor: seams and boulders at 40%, field yield 2/3;
  - resource-rich: ×2 and 4/3;
  - labour-poor: one in four workers of the productive trades leaves at the start (`World.kill`, "left the village"; heirs inherit, succession refills posts by the B8-016 rules);
  - labour-rich: six newcomers take productive posts (the B8-016 newcomer, purse counted as coins from outside).
- **Regional trade volume between settlements of different size.** The regional harness (`caravan_compare.gd --profiles`): three off-map settlements of 25, 70 and 140 people beside the live village of about 100, their production under each profile.
- **Industries.**
  - Implemented and tested: mining, forestry, farming, smithing, carpentry, tanning.
  - Real production loops with no capability industry in the schema, so not tested and not faked: cooking, brewing, the sage's medicines, weaving and sewing, hunting, animal husbandry.
  - Trade has a capability industry but no production loop: its only effect is a carter's fee in the regional model.


## 2. Results at level 10 (30 days)

Every table compares the four models on identical seeds and start states. "Production output" sums the six implemented industries:
- mining: ore and stone mined;
- forestry: logs felled;
- farming: grain harvested;
- smithing, carpentry and tanning: units made by their recipes.

Each industry's units, and units per worker-day, are in the rows below the total.

Definitions:
- **Labour compensation:** what the workers of those trades earned (sales and wages).
- **Production cost:** what they spent.
- **Business profit:** earned minus spent by the 18 villagers whose trades buy and sell.
- **Trade volume:** the village's coins with the outside (the caravan, the live game's only inter-settlement trade).

### Normal village, seed 1

| Metric | Baseline | Conservative | Moderate | Aggressive |
|---|---|---|---|---|
| Production output (units, 6 industries) | 9288 | 9573 | 9780 | 9721 |
| &nbsp;&nbsp;mining units (per worker-day) | 723 (3.01) | 689 (2.55) | 752 (2.79) | 762 (2.82) |
| &nbsp;&nbsp;forestry units (per worker-day) | 3144 (17.47) | 3385 (18.81) | 3342 (18.57) | 3420 (19.00) |
| &nbsp;&nbsp;farming units (per worker-day) | 3600 (10.00) | 3600 (10.00) | 3600 (10.00) | 3600 (10.00) |
| &nbsp;&nbsp;smithing units (per worker-day) | 510 (8.50) | 565 (9.42) | 635 (10.58) | 461 (7.68) |
| &nbsp;&nbsp;carpentry units (per worker-day) | 1209 (20.15) | 1233 (20.55) | 1335 (22.25) | 1373 (22.88) |
| &nbsp;&nbsp;tanning units (per worker-day) | 102 (1.70) | 101 (1.68) | 116 (1.93) | 105 (1.75) |
| Labour compensation (coins earned by productive workers) | 11900 | 12231 | 13412 | 11350 |
| Production cost (coins they spent) | 6338 | 6784 | 7717 | 5871 |
| Net business profit (18 trades; losing / broke) | 2448 (9 / 2) | 3427 (6 / 1) | 3282 (9 / 2) | 1835 (9 / 4) |
| Household purchasing power (median purse; median food days; broke) | 166; 3.65; 0 | 176; 2.63; 0 | 170; 5.17; 0 | 165; 4.33; 0 |
| Wealth concentration (Gini of household purses) | 0.292 | 0.317 | 0.240 | 0.311 |
| Resource depletion (ore and stone left of start; iron ore used; logs used) | 157 / 880; 346; 718 | 191 / 880; 416; 726 | 128 / 880; 470; 779 | 118 / 880; 312; 770 |
| Trade volume (caravan coins in + out) | 3986 | 4335 | 5012 | 3472 |
| Market prices (wheat, plank, pickaxe, axe) | 2, 2, 40, 40 | 2, 2, 42, 39 | 2, 2, 43, 38 | 2, 2, 38, 38 |
| Economic failures (deaths; starvation; meals missed for no food) | 6; 0; 1 | 4; 0; 13 | 7; 0; 5 | 5; 0; 2 |
| Alive at the end | 109 | 112 | 106 | 110 |
| Conservation (LEAKS currency 0, items {}, deposits []) | yes | yes | yes | yes |

### Normal village, seed 2

| Metric | Baseline | Conservative | Moderate | Aggressive |
|---|---|---|---|---|
| Production output (units, 6 industries) | 8793 | 9623 | 8543 | 9669 |
| &nbsp;&nbsp;mining units (per worker-day) | 777 (3.24) | 772 (3.22) | 692 (2.88) | 784 (3.27) |
| &nbsp;&nbsp;forestry units (per worker-day) | 2655 (14.75) | 3459 (19.22) | 2535 (14.08) | 3309 (18.38) |
| &nbsp;&nbsp;farming units (per worker-day) | 3600 (10.00) | 3600 (10.00) | 3600 (10.00) | 3600 (10.00) |
| &nbsp;&nbsp;smithing units (per worker-day) | 384 (6.40) | 354 (5.90) | 461 (7.68) | 452 (7.53) |
| &nbsp;&nbsp;carpentry units (per worker-day) | 1276 (21.27) | 1346 (22.43) | 1156 (19.27) | 1427 (23.78) |
| &nbsp;&nbsp;tanning units (per worker-day) | 101 (1.68) | 92 (1.53) | 99 (1.65) | 97 (1.62) |
| Labour compensation (coins earned by productive workers) | 11617 | 11113 | 11216 | 11531 |
| Production cost (coins they spent) | 6429 | 6575 | 6872 | 6627 |
| Net business profit (18 trades; losing / broke) | 869 (12 / 4) | 707 (11 / 6) | 1087 (10 / 4) | 1231 (11 / 5) |
| Household purchasing power (median purse; median food days; broke) | 179; 3.93; 0 | 169; 4.01; 0 | 165; 4.44; 0 | 197; 4.78; 0 |
| Wealth concentration (Gini of household purses) | 0.323 | 0.329 | 0.275 | 0.323 |
| Resource depletion (ore and stone left of start; iron ore used; logs used) | 103 / 880; 320; 669 | 108 / 880; 346; 694 | 188 / 880; 400; 623 | 96 / 880; 364; 726 |
| Trade volume (caravan coins in + out) | 3276 | 3428 | 4411 | 4015 |
| Market prices (wheat, plank, pickaxe, axe) | 2, 2, 42, 42 | 2, 2, 38, 44 | 2, 2, 42, 42 | 2, 2, 42, 42 |
| Economic failures (deaths; starvation; meals missed for no food) | 6; 0; 0 | 6; 0; 0 | 6; 0; 12 | 4; 0; 11 |
| Alive at the end | 116 | 108 | 107 | 117 |
| Conservation (LEAKS currency 0, items {}, deposits []) | yes | yes | yes | yes |

### Scenarios, seed 1 (per-industry rows omitted; see section 3)

**Resource-poor**: seams and boulders at 40%, field yield 2/3.

| Metric | Baseline | Conservative | Moderate | Aggressive |
|---|---|---|---|---|
| Production output (units, 6 industries) | 8113 | 7868 | 8197 | 8346 |
| Labour compensation (coins earned by productive workers) | 10674 | 10226 | 11184 | 10846 |
| Production cost (coins they spent) | 7011 | 6455 | 7350 | 7174 |
| Net business profit (18 trades; losing / broke) | 2098 (7 / 4) | 1722 (9 / 4) | 2263 (8 / 0) | 1676 (8 / 3) |
| Household purchasing power (median purse; median food days; broke) | 151; 3.36; 0 | 186; 2.29; 0 | 166; 2.70; 0 | 193; 4.09; 0 |
| Wealth concentration (Gini of household purses) | 0.307 | 0.265 | 0.285 | 0.261 |
| Resource depletion (ore and stone left of start; iron ore used; logs used) | 27 / 350; 394; 821 | 27 / 350; 376; 801 | 27 / 350; 362; 851 | 27 / 350; 404; 823 |
| Trade volume (caravan coins in + out) | 6153 | 6130 | 6265 | 6395 |
| Market prices (wheat, plank, pickaxe, axe) | 2, 2, 38, 38 | 2, 2, 38, 38 | 2, 2, 38, 38 | 2, 2, 38, 38 |
| Economic failures (deaths; starvation; meals missed for no food) | 4; 0; 4 | 5; 0; 0 | 6; 0; 3 | 7; 0; 1 |
| Alive at the end | 112 | 111 | 112 | 109 |
| Conservation (LEAKS currency 0, items {}, deposits []) | yes | yes | yes | yes |

**Resource-rich**: seams and boulders ×2, field yield 4/3.

| Metric | Baseline | Conservative | Moderate | Aggressive |
|---|---|---|---|---|
| Production output (units, 6 industries) | 9982 | 9908 | 9997 | 10207 |
| Labour compensation (coins earned by productive workers) | 10341 | 8737 | 9209 | 10009 |
| Production cost (coins they spent) | 5650 | 4670 | 5131 | 5442 |
| Net business profit (18 trades; losing / broke) | 2208 (10 / 2) | 1615 (11 / 2) | 1605 (10 / 4) | 2589 (8 / 2) |
| Household purchasing power (median purse; median food days; broke) | 159; 4.62; 0 | 146; 4.27; 0 | 164; 4.91; 0 | 152; 2.93; 0 |
| Wealth concentration (Gini of household purses) | 0.381 | 0.423 | 0.287 | 0.395 |
| Resource depletion (ore and stone left of start; iron ore used; logs used) | 707 / 1760; 336; 506 | 825 / 1760; 262; 496 | 771 / 1760; 290; 529 | 591 / 1760; 416; 522 |
| Trade volume (caravan coins in + out) | 2335 | 2253 | 2335 | 2221 |
| Market prices (wheat, plank, pickaxe, axe) | 2, 2, 40, 42 | 2, 2, 41, 40 | 2, 2, 38, 38 | 2, 2, 35, 35 |
| Economic failures (deaths; starvation; meals missed for no food) | 6; 0; 0 | 4; 0; 0 | 6; 0; 0 | 6; 0; 1 |
| Alive at the end | 111 | 110 | 103 | 109 |
| Conservation (LEAKS currency 0, items {}, deposits []) | yes | yes | yes | yes |

**Labour-poor**: one in four productive workers leaves at the start.

| Metric | Baseline | Conservative | Moderate | Aggressive |
|---|---|---|---|---|
| Production output (units, 6 industries) | 9017 | 8835 | 9038 | 8850 |
| Labour compensation (coins earned by productive workers) | 12052 | 11657 | 10538 | 10529 |
| Production cost (coins they spent) | 7394 | 6989 | 6063 | 5990 |
| Net business profit (18 trades; losing / broke) | 1407 (10 / 1) | 1487 (10 / 3) | 1255 (10 / 5) | 1784 (9 / 3) |
| Household purchasing power (median purse; median food days; broke) | 178; 4.74; 0 | 143; 2.69; 0 | 138; 4.83; 0 | 147; 2.16; 0 |
| Wealth concentration (Gini of household purses) | 0.371 | 0.339 | 0.404 | 0.400 |
| Resource depletion (ore and stone left of start; iron ore used; logs used) | 182 / 880; 330; 774 | 168 / 880; 376; 795 | 176 / 880; 324; 765 | 187 / 880; 256; 726 |
| Trade volume (caravan coins in + out) | 3509 | 4240 | 3187 | 2486 |
| Market prices (wheat, plank, pickaxe, axe) | 2, 2, 40, 40 | 2, 2, 36, 37 | 2, 2, 38, 38 | 2, 2, 37, 38 |
| Economic failures (deaths; starvation; meals missed for no food) | 10; 0; 0 | 11; 0; 10 | 12; 0; 1 | 14; 0; 0 |
| Alive at the end | 97 | 95 | 97 | 97 |
| Conservation (LEAKS currency 0, items {}, deposits []) | yes | yes | yes | yes |

**Labour-rich**: six newcomers in productive posts.

| Metric | Baseline | Conservative | Moderate | Aggressive |
|---|---|---|---|---|
| Production output (units, 6 industries) | 10247 | 9921 | 10363 | 10228 |
| Labour compensation (coins earned by productive workers) | 13820 | 14426 | 13707 | 12845 |
| Production cost (coins they spent) | 8268 | 8769 | 7831 | 7261 |
| Net business profit (18 trades; losing / broke) | 3290 (6 / 3) | 3278 (7 / 3) | 2603 (9 / 3) | 2404 (8 / 3) |
| Household purchasing power (median purse; median food days; broke) | 178; 3.95; 0 | 184; 3.64; 0 | 214; 2.72; 0 | 194; 2.87; 0 |
| Wealth concentration (Gini of household purses) | 0.254 | 0.279 | 0.223 | 0.211 |
| Resource depletion (ore and stone left of start; iron ore used; logs used) | 103 / 880; 488; 871 | 72 / 880; 520; 809 | 151 / 880; 460; 915 | 136 / 880; 374; 904 |
| Trade volume (caravan coins in + out) | 5013 | 5570 | 5056 | 4378 |
| Market prices (wheat, plank, pickaxe, axe) | 2, 2, 0, 40 | 2, 2, 39, 39 | 2, 2, 39, 38 | 2, 2, 36, 36 |
| Economic failures (deaths; starvation; meals missed for no food) | 7; 0; 16 | 7; 0; 5 | 3; 0; 3 | 4; 0; 0 |
| Alive at the end | 116 | 118 | 116 | 121 |
| Conservation (LEAKS currency 0, items {}, deposits []) | yes | yes | yes | yes |

## 3. What the numbers say

### 3.1 Noise is larger than any model's effect at 30 days

The same model at the same level moves outcomes in different directions on different seeds. Model vs baseline, % change by seed 1 / 2 / 3 / 4:

| | Conservative | Moderate | Aggressive |
|---|---|---|---|
| Total output | +3.1 / +9.4 / +1.3 / -8.0 (mean +1.4) | +5.3 / -2.8 / -1.9 / -16.4 (mean -4.0) | +4.7 / +10.0 / +5.4 / -4.2 (mean +3.9) |
| Smithing units | +10.8 / -7.8 / -16.1 / -13.6 | +24.5 / +20.1 / +3.8 / -11.3 | -9.6 / +17.7 / +13.9 / -7.1 |
| Carpentry units | +2.0 / +5.5 / +18.6 / -11.4 | +10.4 / -9.4 / +25.4 / -10.4 | +13.6 / +11.8 / -2.5 / -0.6 |
| Forestry units | +7.7 / +30.3 / -0.2 / -12.4 | +6.3 / -4.5 / -15.8 / -37.5 | +8.8 / +24.6 / +14.2 / -9.4 |
| Business profit | +40 / -19 / -14 / -40 | +34 / +25 / +33 / -39 | -25 / +42 / +31 / -28 |

The baseline itself differs across seeds by 14% in total output, 29-34% in the crafts and forestry, and 97% in business profit.

A few-percent change in work time redirects villagers' day plans, and the 30-day paths diverge (deterministic chaos: each run is exactly reproducible, but small causes compound). The level sweeps on seed 1 (levels 2, 5, 8, 10) are no more ordered than this: output does not rise monotonically with the level in any model.

Caveat on the extra runs: the level sweeps (2, 5, 8) and the level-10 runs on seeds 3 and 4 were made before mining was forced too, so their mining work time is the baseline's. Mining is resource-bound, as shown in 3.2.

**Conclusion: at 30 days no model shows a consistent effect larger than run-to-run variation.**

### 3.2 What is consistent in every run (structural, not statistical)

**Mining is bounded by the deposits.**
- In every normal run the village's iron, coal, copper and gold seams were worked out within 30 days, whatever the model (ore and stone left: 94-191 of 880).
- In the resource-poor runs, exactly 27 of 350 were left in every model.
- A faster miner only reaches the end of the seam sooner. More capability means faster depletion, not more ore.

**Farming is bounded by the land.** Grain harvested was 3600 in every run of every model. Faster cutting and sowing frees the farmers' time but grows no more grain.

**Crafts are bounded by inputs and demand.** Smithing and carpentry vary the most (±25%), but the variation does not follow the model.

**Capability never created a resource.**
- Every run balanced its currency, every item, every deposit and every animal kind.
- `capability_test`: a level-10 miner in the real World takes a 3-ore seam's 3 ore and no more.
- `capability_test`: a level-10 smith with 5 ore smelts 2 bars and stops.

**Pay effects are almost invisible in this economy.** The only wages tied to these industries are the manor's quarry and mending wages. Everyone else is self-employed and paid by sales.

**No model starved anyone.** No starvation death in any run; deaths were from age and illness, 3-14 a run. No household went broke.

### 3.3 Per-industry observations

- **Mining.** Output per worker-day falls as the seams run out in every model. Capability speeds up depletion and nothing else. This is the clearest sustainability risk of a large output multiplier.
- **Forestry.** Trees regrow slowly. The noisiest industry; no consistent gain.
- **Farming.** No quantity effect possible (the crop is the land's); time saved only.
- **Smithing.** The moderate model gained in three of four seeds (+24.5, +20.1, +3.8, -11.3%), the most consistent single result. Even so, one seed lost.
- **Carpentry and tanning.** Mixed; within noise.

### 3.4 Do industries need different curves?

Yes, on structural grounds rather than statistical ones:
- Where output is bounded by a natural finite source (mining, quarrying, forestry) or by land (farming), an output multiplier adds no lasting output and only speeds depletion or frees time.
- Where output is bounded by inputs and labour (smithing, carpentry, tanning), faster work can turn into more finished goods when inputs are on hand.

## 4. Recommendation (no constant adopted)

**Not the moderate model by default.** The evidence cannot rank the three models on output, because their effects sit inside run-to-run variation at 30 days. What the evidence does show is structural:
- the aggressive model's larger multipliers would mainly accelerate depletion of finite seams and woods;
- farming output cannot respond at all.

**Recommendation for the owner to consider:**
- **Revised, bounded model**, data profile `revised_bounded` (UNAPPROVED):
  - small output gains where work draws on a finite natural source: mining +5%, forestry +5%;
  - no output gain for farming (faster work only frees time);
  - moderate gains in the input-bound crafts: smithing +15%, carpentry +15%, tanning +10%;
  - pay at 0.4 of the output gain, within the research's place-specific 0.33-0.45;
  - front-loaded shape for the simple trades, the owner's shape for the crafts.
- **If a single uniform model is preferred, the conservative model** (+10% output, +5% pay at level 10). It brings the same unmeasurable output benefit with the least depletion pressure, and the smallest pay distortion.
- **The moderate model** fits the research's figures best for crafts (CAPABILITY_CURVES.md), but on this evidence is no better than conservative.
- **The aggressive model is not recommended.** It shows no measurable output advantage, and its multipliers act mostly on finite resources.

**Update (round 2):** the 90-day runs, the regional harness by profile and the Q18-11A `approved` profile were run on the Build 18 code; see `CAPABILITY_SIMULATIONS_90DAY.md`. The list below is round 1's state.

**Not yet run (pending, stated plainly):**
- the `revised_bounded` model's own runs;
- the 90-day runs (baseline and each model at level 10, normal and resource-poor);
- the regional harness by profile (trade volume between settlements of different size).

They were prepared (`x18_batch5.sh`, `x18_batch6.sh` in the session scratchpad) but not started, because the owner's SYNC-17 directive puts the Build 17 merge before any new work. Results on a Build 16 baseline and a Build 17 baseline would not be comparable. These runs, and a rerun of this grid's baselines, belong after the sync. A 90-day horizon is also where depletion and adaptation differ most, so it is the run most likely to separate the models.

## 5. Reproduce

```
godot --headless --path game --script res://tests/economy_sim.gd -- --days 30 --seed 1 --every 10 --cap-report
godot --headless --path game --script res://tests/economy_sim.gd -- --days 30 --seed 1 --every 10 --capability 10 --cap-profile moderate [--cap-scenario resource_poor]
```

The "CAPABILITY {json}" line at the end of each log holds the metrics. The tables were made by the session's `x18sum.py` from those lines.
