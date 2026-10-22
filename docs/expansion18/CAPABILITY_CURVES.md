# Capability curves: candidate analysis (Q18-11A) and composition options (Q18-11B)

PROSPECTIVE (Expansion 18, PROS-18). **Analysis only: no constant is adopted.** The active profile in
`game/data/settlement_industries.json` is `neutral` (every multiplier 1.0). Every other profile is labelled UNAPPROVED
and can be selected only by tests and the analysis harness. The numbers belong to the owner (Q18-11A); what a level is
made of belongs to the owner too (Q18-11B, section 5).

Sources:
- Owner master directive 2026-10-21, section 5 (`docs/directives/2026-10-21_expansion18_master_directive.md` on staging).
- `RESEARCH_DIGEST.md`. Its page citations are repeated below.

## 1. The framework (approved structure)

- `OutputMultiplier(industry, L) = 1 + output_max[industry] x shape[L]`
- `PayMultiplier(industry, L) = 1 + output_max[industry] x pay_ratio x shape[L]`
- L runs 0-10. Level 0 is the baseline: a multiplier of 1.0, never inability.
- Both multipliers apply to the existing base pay and base output (DESIGN.md section 9).

How the output multiplier is applied:
- It means faster work: less time per unit.
- Each unit still takes its full inputs, or one unit of its deposit, or one unit of its crop.
- The settlement capability is the place-specific part. Individual Skills are the portable part. The two gains add once each.

## 2. The three candidate shapes

The table gives the % of the level-10 bonus reached at each level.

| Level | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) owner_candidate (owner's table) | 0 | 18 | 34 | 48 | 60 | 70 | 79 | 86 | 92 | 97 | 100 |
| (b) front_loaded | 0 | 32.4 | 54.6 | 69.7 | 80.0 | 87.1 | 91.9 | 95.2 | 97.4 | 99.0 | 100 |
| (c) intermediate | 0 | 25.2 | 44.3 | 58.8 | 70.0 | 78.5 | 85.4 | 90.6 | 94.7 | 98.0 | 100 |

How each shape is defined:
- **(a) owner_candidate** is the owner's example table divided by its 20% total.
- **(b) front_loaded** is (1 - e^(-kL)) / (1 - e^(-10k)) with k = 0.3812, chosen so that 80% of the gain comes by level 4 (40% of the span).
  - This follows the research's ~80% of the gain by ~40% of the span. Caplin Table 4, p.16: "about 80% by 3-4 years" of the tenure-saving from prior experience.
  - Bishop Appendix C, p.198: about 77% of the observed rise comes in the first six months (digest (b)).
- **(c) intermediate** is the mean of (a) and (b).

All three are concave (diminishing returns), as the directive asks. The owner's shape puts 49% of the gain by level 3 and 70% by level 5. That is "concave but less front-loaded than the empirical individual learning curves" (digest (b)).

## 3. Magnitudes

### 3a. The owner's uniform candidate

+20% output and +8% pay at level 10, the same for every industry.

| Level | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| (a) output % / pay % | 0/0 | 3.6/1.44 | 6.8/2.72 | 9.6/3.84 | 12.0/4.80 | 14.0/5.60 | 15.8/6.32 | 17.2/6.88 | 18.4/7.36 | 19.4/7.76 | 20/8 |
| (b) output % / pay % | 0/0 | 6.5/2.59 | 10.9/4.36 | 13.9/5.57 | 16.0/6.40 | 17.4/6.96 | 18.4/7.35 | 19.0/7.61 | 19.5/7.79 | 19.8/7.92 | 20/8 |
| (c) output % / pay % | 0/0 | 5.0/2.02 | 8.9/3.54 | 11.8/4.71 | 14.0/5.60 | 15.7/6.28 | 17.1/6.83 | 18.1/7.25 | 18.9/7.58 | 19.6/7.84 | 20/8 |

### 3b. Pay/output ratio

Every candidate uses 0.40, which is the owner's 8/20. The research range for the place-specific (firm-specific) part is 0.33-0.45:
- Caplin p.32: 7.9% productivity against 3.2% wage per year, giving 0.41.
- Caplin's "two to three times" (p.3) and "three times" (p.38) give 0.33-0.5.
- Caplin Table 7 (p.30) by job group gives 0.33-0.44 (digest (a)).

For portable individual skill the evidence points nearer 0.6-1.0. That part is the Skills', not the settlement's, so the settlement curve keeps the place-specific ratio.

### 3c. Industry-differentiated candidate (`differentiated`)

The digest (c) supports differentiating industries:
- Simple or unskilled jobs plateau fast, in about 1.5 years, with a smaller total gain. Caplin Table 3, p.15: unskilled manual 1.5 years against high-knowledge 2.9.
- Cumulative gains of about 12% for 1-year jobs against about 45% for 5+-year jobs. This is derived from Caplin Table 7, p.30 (digest (b)).
- For unskilled workers "the bulk of human capital ... is acquired on the job" (Caplin p.18), which is the place-specific part.
- Craft output varies more between workers than factory work does: coefficient of variation .28 against .144 (Bishop p.161).

| Industry | Shape | Output at L2 | at L4 | at L10 | Pay at L10 |
|---|---|---|---|---|---|
| mining (unmapped, stays 1.0) | front_loaded | 6.5% | 9.6% | 12% | 4.8% |
| forestry | front_loaded | 6.5% | 9.6% | 12% | 4.8% |
| farming | intermediate | 7.1% | 11.2% | 16% | 6.4% |
| trade | intermediate | 7.1% | 11.2% | 16% | 6.4% |
| tanning | intermediate | 8.9% | 14.0% | 20% | 8.0% |
| carpentry | owner_candidate | 8.5% | 15.0% | 25% | 10.0% |
| smithing | owner_candidate | 9.5% | 16.8% | 28% | 11.2% |

Farming is mid-range: 2.3 years to plateau, the same as skilled manual work (Caplin Tables 3 and 9, pp.15, 35). The research gives no separate figures for mining, smithing or carpentry (digest (c), (f)), so their placement is a design reading, not a measurement.

### 3d. Caveats

These come from the digest (f):
- The data are modern: Denmark 2020 and the US in the 1980s-1990s.
- "Productivity" there means rated output value, not physical output per unit of material.
- The horizons are short.
- No paper gives a settlement-wide ceiling.
- The 20% ceiling is "in the same order as the mid-range cumulative figures for 2-4 year jobs" and is not a measured cap.

## 4. Effect in the regional harness (analysis only)

Run: `caravan_compare.gd -- --days 30 --seed 1 --profiles neutral,owner_candidate,front_loaded,intermediate,differentiated --local`, 15 caravan visits.

All the sets run over the same live village, so the village, its caravan and its parties are identical across sets. Only each set's three off-map regions follow their profile.

Integrity across all sets: 290 checks, 0 failures. Every shadow transfer was matched, coins were conserved every visit, nothing was delivered free, each region's books and reserves balanced, and the live currency balanced.

Region capabilities in the fixture (0-10 scale):
- Eastmarch: smithing 6 and trade 4. Its mining is on MIN-D's scale, so its multiplier stays 1.0.
- Riverford: farming 7, trade 6.
- Highfold: its mining is likewise unmapped.

| Profile | Village coins in | out | net | Region purses (E / R / H) | Eastmarch iron ore left | Iron bars bought by the village | Unmet "no carriage" (units) |
|---|---|---|---|---|---|---|---|
| neutral (active) | 1561 | 3215 | -1654 | 1833 / 2451 / 20 | 2880 | 728 coins | 434 |
| owner_candidate | 1561 | 3191 | -1630 | 1809 / 2451 / 20 | 2880 | 770 | 398 |
| front_loaded | 1561 | 3194 | -1633 | 1812 / 2451 / 20 | 2880 | 784 | 397 |
| intermediate | 1561 | 3180 | -1619 | 1798 / 2451 / 20 | 2880 | 770 | 397 |
| differentiated | 1561 | 3172 | -1611 | 1790 / 2451 / 20 | 2880 | 784 | 375 |

What the run shows (one seed, one fixture; not a general result):

**The effect is small, and comes only through the work that has a finite, modeled source.**
- Eastmarch's smithy turns its own ore and coal into iron bars faster, so it sells the village more bars: 728 → 770-784 coins.
- Because Eastmarch then uses more of its own ore and coal, it sells the village a little less: iron ore 480 → 408-432 coins, coal 357 → 330-339.
- These two partly cancel. The village's net changes by 21-43 coins over 30 days.

**Under the safeguard, a level adds no raw material.**
- Mining is unmapped, so Eastmarch's iron ore reserve falls identically (3000 → 2880) under every profile.
- Riverford's grain is the land's.
- So faster work shows up as more finished goods from the same reserves, not as more ore or grain.

**Pay effects do not appear, because no carter is hired in the live shadow (Q18-12).** "No carriage" falls slightly under the candidates only through the changed purchases, not through pay.

**The shapes barely separate at these fixture levels (4-7).** By level 4-7 all three shapes stand at 60-95% of their total. They separate most at levels 1-3, so an analysis of young settlements needs fixtures at low levels.

**What this means for Q18-11A.** The choice between the candidates does not move the regional economy much as long as raw materials bind. The choice matters for:
- the time a worker saves, so labour freed for other work. This is visible only in the live simulation, after integration.
- pay, through wages and fees.

A longer, multi-seed comparison belongs to the integration phase. The live village's own industries are not yet driven by these multipliers on this branch.

## 5. Q18-11B: what a capability level is made of (options for the owner; no weighting adopted)

**The research measures no share for tools, facilities or infrastructure.** All three papers measure people. Caplin's "firm-specific human capital" is knowledge held by workers about how things work at that employer, p.17. Lynch warns her productivity estimates do not "control for capital", p.56 (digest (d)). Any weight given to tools or buildings is a design choice, not an estimate.

Bishop p.166 notes that shop-floor practice and technology both constrain and enable what individual skill turns into output. This supports making people and place interact rather than simply adding them.

**Option 1. People's local experience only.**
- The level comes from the settlement's working practitioners: their number and their time in that industry in this place (tenure here, not their portable Skill).
- Tools and facilities stay what they are today: real prerequisites for the work itself (a pickaxe, a forge), never part of the level.
- Pros:
  - closest to the research (firm-specific human capital);
  - no double counting with tools, which already gate the work physically;
  - a village that loses its experienced workers falls (spec s.4).
- Cons:
  - better equipment never raises the level;
  - it needs a tenure record per worker and industry, which does not exist yet (`Skills.tenure_share` estimates it from age and job).

**Option 2. People with a facility cap.**
- Option 1's experience level, capped by the settlement's facilities. For example, smithing above level 5 needs a second forge and anvil, using the existing station types.
- Pros:
  - follows Bishop's interaction (technology constrains what skill can deliver);
  - uses existing structures;
  - capital investment matters without inventing a capital share.
- Cons:
  - the cap thresholds are a design choice;
  - a settlement can be held back by buildings it cannot afford. That is a legitimate outcome under WDR-022, but it is still a design choice.

**Option 3. People plus facilities, fixed weights.**
- The level is a weighted sum of a people score and a facilities and tools score (for example 70/30).
- Pros:
  - simple to explain;
  - investment and training both count.
- Cons:
  - the weights have no empirical basis (none measured);
  - risk of double counting: the same forge is both a prerequisite and a level bonus.

**Option 4. The current schema, extended.**
- Keep today's need lists (practitioners, stations, tools, records), with more rungs up to level 10, each a concrete combination of people and assets, as now for levels 1-3.
- Pros:
  - already built and tested;
  - transparent (each level names what it takes);
  - MIN-D uses the same schema, which eases the one-evaluator merge.
- Cons:
  - the weighting is implicit in the rungs;
  - ten rungs per industry is a lot of authoring;
  - the people side counts heads and Skill levels, not local tenure.

No option is recommended as approved. On the evidence alone, Option 1 or Option 2 matches the research best, and Option 4 is the least new work.
