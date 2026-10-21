# FSE-12 comparison: the manor's fields on the shared per-cell farming model

Owner decision of 2026-10-21 (`docs/directives/2026-10-21_build16_owner_decision_resolution.md` section 4): the manor's six
fields move to the shared per-cell model behind a test switch, comparison runs are made, and the model is not activated
universally until the owner has reviewed them. **It is not activated.** `shared_manor_farming` stays 0 in
`game/data/balance.json`.

## What was compared

Both runs use the same commit (`62b7488`), four seeds, 365 game days each, player inactive.

- **Baseline:** Actions run 39529507848. The current field model: a field yields `field_yield` (60) a harvest, sown
  without seed, and the farmer keeps `seed_keep` (2) seed up to `seed_cap` (12).
- **Shared model:** Actions run 39531422104, `set: shared_manor_farming=1`.
  - Sowing takes one wheat seed a cell, so a 66-cell field takes 66 seeds.
  - A sown cell yields the player's crop (`yield` 3) and gives back `seeds_back` (1) seed.
  - Sowing, cutting and ploughing take the player's time a cell.
  - A new world starts its farmers with a field's seed between them, 66 for each of the six fields. This is a stated
    world-setup assumption, hence the starting seed of 464 in the table.

## Results at day 365

| Measure | Seed 1 (base -> shared) | Seed 2 | Seed 3 | Seed 4 |
|---|---|---|---|---|
| Script errors / ledgers | 0 / balanced -> 0 / balanced | same | same | same |
| Starvation deaths | 0 -> 0 | 0 -> 0 | 0 -> 0 | 0 -> 0 |
| Alive at the end | 123 -> 115 | 151 -> 147 | 142 -> 124 | 128 -> 124 |
| Births | 92 -> 85 | 123 -> 118 | 109 -> 91 | 99 -> 93 |
| Wheat harvested in the year | 43,920 -> **134,604** | 43,920 -> **138,564** | 43,920 -> **138,762** | 43,920 -> **136,296** |
| Wheat consumed | 41,738 -> 67,577 | 40,932 -> 49,475 | 42,210 -> 64,606 | 39,158 -> 58,523 |
| Wheat held at the end | 2,791 -> **67,632** | 3,659 -> **89,704** | 2,385 -> **74,686** | 5,399 -> **78,254** |
| Wheat seed sown / returned in the year | none / 266 kept -> 45,078 / 44,748 | none / 277 -> 46,332 / 46,068 | none / 241 -> 46,530 / 46,134 | none / 252 -> 45,642 / 45,312 |
| Wheat seed bought in (caravan) | 51 -> 498 | 34 -> 485 | 37 -> 548 | 57 -> 491 |
| Pottage cooked | 59,816 -> 45,400 | 64,982 -> 63,230 | 63,890 -> 48,355 | 54,980 -> 52,566 |
| Milk eaten | 320 -> 54 | 915 -> 542 | 632 -> 63 | 777 -> 290 |
| Nights without firewood | 2,657 -> 2,054 | 1,546 -> 2,514 | 1,390 -> 2,324 | 1,737 -> 1,319 |
| Unemployed / manor hands | 1 / 32 -> 0 / 29 | 18 / 37 -> 19 / 32 | 5 / 35 -> 0 / 34 | 0 / 27 -> 0 / 30 |
| Houses built | 10 -> 9 | 11 -> 8 | 8 -> 9 | 8 -> 11 |

## What the comparison shows

- **Yields:** the per-cell model gives about 3.1 times the grain. The two models differ in yield: the player's crop is 3
  wheat a cell, while the old field gives 60 for 66 cells, about 0.9 a cell. That is the gap FSE-12's first criterion
  asked to explain: the crop definition differs between the two models, not the land or the time. Both grow in one season.
- **Seed:** the fields are sown with real seed every time, and the seed comes back one for one, so seed is never short.
  The caravan sells the merchants about ten times as much seed as before, because the food stall's seed stock is drawn on.
- **Labour:** farmers spend longer in the field (sowing 66 cells takes about 1.8 game hours, cutting and ploughing about 7).
  Every field is still sown and cut each season; no field stood unsown for want of seed or hands.
- **Food supply:** nobody starves either way. The extra grain is mostly not eaten: 67,000-90,000 wheat is left in stores
  at the end. Households cook less pottage (by 3-24 %) and eat less milk: with grain plentiful and cheap they eat raw
  grain and buy less.
- **Economic effects:** a grain glut. Farmers hold most of it unsold, and the population ends slightly smaller with
  slightly fewer births (by 3-18 people). Firewood nights rise on two seeds and fall on two. The cause is not isolated in
  these runs.
- **Determinism and conservation:** both runs balanced their coin and item ledgers (the job fails otherwise) and ended
  with 0 script errors. Each run is reproducible from its seed.

## Reading, for the owner

The shared model works mechanically: real seed, real labour, no free grain, conserved. But with the player's crop
numbers the six manor fields produce about three times what the village eats.

There are three ways to make the models one, all owner choices:

- **(a) Keep the player's crop numbers.** Accept the glut, which prices and the caravan would then have to absorb.
- **(b) Lower the per-cell yield for every farmer, the player included.** For example, 1 wheat a cell, so the fields
  match today's harvest. This changes the player's farming too.
- **(c) Keep the per-cell rules but sow fewer cells.** For example, fallow land, or smaller fields.

**Recommendation:** (b), since one rule for player and village is the parity principle. The exact number is the owner's
to approve, and seasonal farming (FSE-13, `docs/design/FSE13_COMPARISON.md`) would remove about a quarter of the harvest.
Its comparison showed the old fields could not stand that loss; the per-cell fields could. The two should be decided
together.
