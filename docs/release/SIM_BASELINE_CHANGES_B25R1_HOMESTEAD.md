# Sim gate: expected differences from the accepted baseline (B25R1-014, wip/b25r1-homestead)

Commit under test: `943b453` (wip/b25r1-homestead; dispatched on wip/b25r1-homestead-ci with the gate-mode workflow commit).
The baseline is NOT re-recorded on this branch: it is re-recorded once, on the integrated B25R1 candidate (lead's instruction).

## Intended changes that move the gate's figures (seeds 1 and 2, days 10 and 30)

1. **The band lives in the wild** (owner B25R1-Q2 option a). From the founding the six bandits are a household on a concealed
   outlaw claim in the open country (`Wilds.found_band`), not at the village camp. They walk there on day 1, leave the
   village's night-time prey rule (40 tiles round the old camp) and come back only on raids. Expected: fewer robberies on
   most nights, concentrated on raid nights; bandit deaths earlier and in groups (raiders meet guards together); coins carried
   out of the village by raiders; village food bought by bandits on market trips.
2. **Raids are judged at dawn** (`band_raid`): a hungry band raids on day 1 or 2. `raid_keep_home 1` sends 5 of 6.
3. **Claims drink, draw, build and hunt**: new stats `wilds_*`, `homestead_*`; materials used in wells counted
   `used_building_stone`, `used_building_log`; countryside animals adopted near the camp (`country_adopted`), some hunted
   (`hunted_*`).
4. **Fights outside the village** path over the world's ground (`find_path_world`): a chase that used to end "blocked" at the
   village map's edge goes on.
5. **Judgment profiles** `band_raid` and `outlaw_turn` add decision records.

## What must not change
Currency leak 0 and no item leaks at every checkpoint (every new move goes through `World.trade`, `World.transfer`, Fauna's
own acts, or is a purse move recorded under the recorder's `coins` field: animal purchases). Determinism (the two seeds
repeat exactly; `wilds_test` J checks a replayed day).

## Probe on the commit's code (seed 1, 6 days, local)
Water 18 units at the camp by day 6, no dry dawn after day 1; food 1.9 to 4.8 days; no starvation or thirst death; 3 of 6
bandits slain by guards on raid nights or a day market trip (one guard slain too): outcomes of the existing combat (WDR-022).
