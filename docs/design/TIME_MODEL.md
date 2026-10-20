# The time model (OD-21)

The owner's decision of 2026-10-20 (`docs/directives/2026-10-20_od21_time_model.md`): keep 24-hour game days, 8-day
years and four 2-day seasons, and give every timed system an explicit meaning. Three classifications, not three
clocks:

- **Operational time (O):** hunger, sleep, the work day, travel, immediate actions. Hours and days; does not scale with
  the calendar.
- **Economic time (E):** wages, rents, prices, contracts, reserves, production costs. Operational days or calendar
  periods, whichever the obligation is.
- **Calendar time (C):** seasons, ageing, births, generations, seasonal agriculture, long-term biology. Years and
  seasons; scales with `calendar.year_days`.

Register: OD-21 (the decision), TIME-01 (this audit), TIME-02 (explicit units through one conversion layer, no
behaviour change at 8 days), TIME-03 (the retuning proposals in section 5: **proposals only, nothing is changed
without the owner**).

Conventions: 1 game day = 1440 game minutes = 12 real minutes; 1 year = 8 days, 1 season = 2 days; so 1 day = 0.125
year = 0.5 season and 1 hour = 1/192 year. "Scales" means the value changes when `calendar.year_days` changes. Line
numbers are those of the audited commit (2026-10-20, `58f049c`); `bal` is `game/data/balance.json`. Audit made by
reading the code (an agent's read-only inventory, its defect claims spot-checked: the player's starvation literal at
`world.gd:507`, the daily mortality chance at `life.gd:130-138`, `Property.WEEK` at `property.gd:18`).

**Status: TIME-01 complete as an inventory.** TIME-02 implemented (section 8; the register entry is the lead's to close). TIME-03 is open.

## Inventory

### Calendar and human life (Life, life.gd)

| System | Key / file:line | Value | Clock | Meaning | Calendar equiv. | Class | Scales? (should?) | Calibration | Parity |
|---|---|---|---|---|---|---|---|---|---|
| Calendar | `calendar` bal:5-10; life.gd:33-73 | 8 d/yr, 4×2 d | days | the year and its seasons | — | C | definition | as owner set | one clock |
| Life stages | `life.child_until/adolescent_until/elder_from` bal:13-15; life.gd:84-92 | 12/16/55 yr | years via `Life.age_years` | stages by age | 96/128/440 days | C | yes (yes) | reasonable | same (player ages too) |
| Old-age mortality | `mortality_from/certain_at` bal:16-17 | 60/80 yr | years | window of natural death | — | C | yes (yes) | reasonable | same (life.gd:343) |
| Old-age hazard | `mortality_daily_max` bal:18; life.gd:130-138, rolled daily at 329-336 | 0.1 per **day** × curve | game days | daily chance rising to certain death | 0.8/yr at the cap | C | **no (should)** | median death ≈70.1 yr now | same |
| Birth rate | `birth_interval_years` bal:25; life.gd:476 | 2.0 yr → 1/16 per day | years→days via `year_days()` | one child per 2 yrs | 16 days | C | **yes (yes)** | fine | same (life.gd:483-487) |
| Birth spacing | `birth_min_gap_years` bal:26; life.gd:500 | 1 yr | years | no baby in last year | 8 days | C | yes (yes) | fine | same |
| Birth food check | `birth_min_food_days` bal:27; life.gd:496 | 1 day of food | food-days | household can feed | 0.125 yr | O | no (no) | fine | same |
| Skill history | `skill_start` bal:495 (`xp_per_year` 300, `max_tenure_years` 25, `from_age` 16); skills.gd:107-113 | XP per **year** | years | plausible tenure at worldgen | 37.5 XP per day | C | yes (yes) | see §2 | player gets none by design |

### Operational needs, rest, daily rhythm

| System | Key / file:line | Value | Clock | Meaning | Cal. equiv. | Class | Scales? | Calibration | Parity |
|---|---|---|---|---|---|---|---|---|---|
| Villager hunger | `hunger_per_hour` bal:84; world.gd:396 | 3/h (72/day) | hours | eating | — | O | no (no) | fine | child ×0.6 (bal:85) |
| Player hunger | `player_hunger_per_hour` bal:89; world.gd:506 | 3/h | hours | — | — | O | no | fine | equal rate, separate key |
| Starvation | `starve_damage_per_hour` bal:88 (NPC, world.gd:398); **player literal 3.0, world.gd:507** | 2/h vs 3/h | hours | hp loss at 0 food | — | O | no | — | **differs** (§3 D4) |
| Daily rhythm | npc_brain.gd:7-10 `WORK_START 7, WORK_END 18, SLEEP 21.5, WAKE 6`; 199 (`h < 12` day labour); 1305 (bandit night 21-4.5) | hours | hours | work day, sleep | — | O | no (no) | fine | player unconstrained (by design) |
| Rest | `rest.day_minutes` 120, `seek_below` bal:497; world.gd:1501 | 120 min | minutes | rest to cap | — | O | no | fine | **same rule** (PAR-03) |
| Work units, recipes | `mine/chop/hunt_minutes` 25/40/40 bal:140-142; recipes.json `minutes` 20-150; also report 6 h, tavern hours, predation per hour (bal:424, 496, 529) | game min | minutes | labour per unit | — | O | no | fine | player swing = minutes/gmps × 0.6 (mine) / 0.5 (chop) real s: **player ~1.7-2× faster** (documented time_note) |
| Loot | `loot_recover_hours` 12 bal:440; **`ANIMAL_LOOT_DAYS` 3.0 world.gd:2696, ×1440 at 347** | 12 h / 3 d | hours/days | coins collected; carcass spoils | 0.375 yr | O | no | fine (literal outside data) | — |

### Agriculture, trees, plants

| System | Key / file:line | Value | Clock | Meaning | Cal. equiv. | Class | Scales? | Calibration | Parity |
|---|---|---|---|---|---|---|---|---|---|
| Tree regrow (stump) | `tree_regrow_days` [3,6] bal:118; world.gd:1143-1144, trees.gd:224 | 3-6 d | days | stump sprouts | 0.375-0.75 yr | C | **no (should)** | **outlier** | same |
| Tree growth | `tree_growth.sapling/young/growing_days` 0.75/0.75/0.5 bal:108-110; trees.gd:165-171 (own `DAY` 1440, trees.gd:23) | 2 d sapling→mature | days | lifecycle | 0.25 yr; felled→mature 0.6-1.0 yr | C | **no (should)** | **outlier** (decades in reality) | same |
| Fruit trees | `fruit_trees.apple_orchard.regrow_days` [2,3], `seasons` Summer/Autumn bal:117; trees.gd:102-104, world.gd:963-975 | 2-3 d, seasonal | days + `Life.season` | bears again | 1-1.5 seasons | C | season gate yes; regrow no | reasonable (≈1-2 pickings/yr) | same (npc_brain.gd:620) |
| Wild plants | `plant_regrow_days` [2,4] bal:122; world.gd:997-1006, 365 | 2-4 d, **not seasonal** | days | berries/flowers ripen again | 1-2 seasons | C | no (should) | ripe in winter | same |
| Village fields | `field_grow_days` 2 bal:127; world.gd:1359-1360, 1372, 323-328 | 2 d, **no season** | days | field ripens | 1 season | C | no (should; plus season) | **outlier: 4 harvests/yr incl. winter** | **differs** (§3 D1) |
| Player crops | `farming.crops.*.days` 1.0-2.5 bal:540-543; farming.gd:227-238 (hourly `1/(days*24)`) | days × `season_rate` | hours + `w.season()` | crop growth | 0.5-1.25 seasons | C | season part yes; length no (should) | reasonable | player only (vs D1) |
| Season rates / sowing | `farming.season_rate`, `sow_seasons` bal:537-538; farming.gd:199-210 | Sp/Su 1, Au 0.5, Wi 0 | `Life.season` | seasonal agriculture | — | C | yes (yes) | reasonable | player only |

### Livestock and wildlife (Fauna, animal.gd, refuges.gd)

| System | Key / file:line | Value | Clock | Meaning | Cal. equiv. | Class | Scales? | Calibration | Parity |
|---|---|---|---|---|---|---|---|---|---|
| Animal stages | `animals.*.juvenile_days/grow_days/elder_days` bal:228-421; animal.gd:41-60 (literal 1440) | cow 2/6/96 d; pig 1/4/56; sheep 1/4/64; chicken 0.5/2/32; boar 1/5/56; rabbit 0.5/2/24; deer 1/4/60; wolf 1/5/64; fox 1/3/40; bear 2/8/96; bird 0.5/2/30 | days | stages ("a day = 1/year_days of a year", bal:229) | cow adult 0.75 yr, elder 12 yr | C | **no (should)** | lifespans plausible as years; maturity fast | same pens/woods |
| Lifespan | `death_days` (cow 120-160, chicken 40-56, rabbit 28-40, bear 110-140 …); fauna.gd:450-461 | days | days | old-age death | cow 15-20 yr, chicken 5-7 yr, rabbit 3.5-5 yr | C | **no (should)** | reasonable as years | same |
| Breeding interval | `breed_days` (cow 6, pig 4, sheep 5, chicken 3, rabbit 3, wolf 10, bear 20); fauna.gd:134, 442 (literal 1440) | days, **year-round** | days | litter cadence | cow 0.75 yr, chicken 0.375 yr, bear 2.5 yr | C | **no (should)** | reasonable cadence | livestock & woods same rule |
| Animal hunger | `animal_hunger_per_hour` 3, species `hunger_per_hour` (wolf 1, fox 1.2, bear 0.8), `animal_starve_hp_per_hour` 0.1 bal:426-428; fauna.gd:164-176 | per hour | hours | feeding | — | O | no (no) | fine | — |
| Keeper feed stock | npc_brain.gd:1971 literal `4` days (1 in famine) | days | days | trough reserve | 0.5 yr | O/E | no | literal outside data | NPC only |
| Products | `farming.products` egg 1/1 d, milk 2/1 d, wool 1/4 d; `product_cap` 8 bal:555-560; farming.gd:508-535 (literal 1440) | days | days | yield of well-fed adults | hen 8 eggs/yr; wool 2/yr | O/E (see §5) | no | eggs/milk daily rates fine operationally; wool 2 shearings/yr high | **same** for player and village pens |
| Refuges | `refuges.species.*.interval_days` (rabbit 3 … bear 16), `seasons`, `settle_days` 2 bal:425; refuges.gd:65, 111, 121, 129, 237 | days + `Life.season` | days | protected litters in season | fox/wolf 1/yr, bear 1 per 2 yr | C | seasons yes; intervals no (should) | reasonable | n/a |

### Economy, government, households

| System | Key / file:line | Value | Clock | Meaning | Cal. equiv. | Class | Scales? | Calibration | Parity |
|---|---|---|---|---|---|---|---|---|---|
| Wages | `guard_wage_per_day` 6, `manor_wage_per_day` 6, `reeve_wage_per_day` 6, `day_labour_wage` 6, `helper_wage` 6, `attendant_wage` 8 bal:136,433,455,463,202,172; paid daily world.gd:333-335 | coins/day | days | day wage | 48 coins/yr | E (operational day) | no (no) | consistent with 72 food/day | same wage for player hires |
| Rent period | **`Property.WEEK = 7` property.gd:18**, used property.gd:421, world.gd:2749 | 7 days | days | "weekly" rent (owner rule) | **0.875 yr**, 3.5 seasons | E | no (no for a 7-day week; see §2) | ambiguous | same (player and households) |
| Rent amount | `weekly_rent_share` 0.1 bal:146; property.gd:192, construction.gd:139 | 10%/7 days | weeks | 15 coins/wk for a house | ≈17/yr | E | no | ≈2.1 coins/day vs wage 6 | same |
| Eviction | `rent_evict_missed` 2 bal:148 | 2 weeks | weeks | arrears limit | 1.75 yr | E | no | long | same |
| Stall / shop rent | `stall_rent_day` 5, `stall_large_rent_day` 9, `shop_licence_day` 4, `stall_evict_days` 2 bal:151-152,162,165; business.gd:454-471 | coins/day | days | pitch rent | — | E | no | fine | player only |
| Tax | `tax_rate_*` 0.12/0.06 bal:447-448, applied **every evening** npc_brain.gd:2161-2183 | % per day | days | tax on cash above exemption | 8 levies/yr | E | no | 6%/day is steep (§4) | NPC households only |
| Tax holiday | `treasury_tax_holiday_days` 30 bal:454; npc_brain.gd:2161, 2354 | 30 obligation-days | days | no tax above it; public works above it | 3.75 yr | E | no | **outlier (high)** | — |
| Treasury reserve | `treasury_reserve_days` 10 bal:451; npc_brain.gd:2159, 2698 | 10 days | days | low-treasury tax, hiring | 1.25 yr | E | no | high but consistent | — |
| Manor orders | `manor_order_days` 10 bal:437; npc_brain.gd:2322 | 10 d | days | advance lapses | 1.25 yr | E | no | long | — |
| Hire runway | `manor_hire_runway_days` 20 bal:478; npc_brain.gd:2699 | 20 d | days | hiring needs runway | 2.5 yr | E | no | high | — |
| Granary target | `granary_target_days` 7 bal:457; npc_brain.gd:2212 | 7 days of food | food-days | granary buys to this | 0.875 yr of food | E | no (no, while fields are year-round) | consistent | — |
| Relief | `relief_trigger_days` 2, `relief_fill_days` 3 bal:460-461; npc_brain.gd:2386-2435 | food-days | days | manor relief | — | E | no | fine | NPC households only |
| Chronic relief | `chronic_relief_days` 4 bal:462; **window literal 7** npc_brain.gd:2461-2466 | 4 of 7 days | days | named in the log "once a week" | — | E | no | literal 7 | — |
| Famine | `famine_food_days` 2 bal:445; world.gd:313 | food-days | days | famine mode | — | E | no | fine | — |
| Personal reserve | `reserve_days` 2 bal:423; world.gd:662-712 | 2 days | days | OD-19 necessity horizon | 0.25 yr | E | no (no) | fine; sees rent only within 2 days of due | **same** for player and villagers |
| Household economics | `household_savings_days` 10, `mobility_unsustainable_days` 3 bal:467-468; income window literal 7 (npc_brain.gd:3094), avg 5 (2752), min 3 (2685) | days | days | sustainability, job change | — | E | no | literals outside data | NPC only |
| Job mobility | `job_switch_cooldown_days` 7, `job_return_days` 14 bal:469-470 | days | days | — | 0.875 / 1.75 yr | E | no | fine | NPC only |
| Succession | `succession_days` 3, `newcomer_max_days` 10 bal:472-473; npc_brain.gd:2906-2907 | days | days | post open; newcomer arrives | 0.375 / 1.25 yr | E | no | fine | — |
| Caravan | `caravan_every_days` 2 bal:130; world.gd:338 (`day() % every == 1`, noon); npc_brain.gd:3134-3141 | every 2 d | days | regional trade | **once per season** (coincidence) | E | no | fine | — |

### Relations, reputation

| System | Key / file:line | Value | Clock | Meaning | Cal. equiv. | Class | Scales? | Calibration | Parity |
|---|---|---|---|---|---|---|---|---|---|
| Courtship gates | `court_min_days` 3, `propose_min_days` 6, `marry_min_days` 12, `interest_days` 2 bal:56,46,68,52; relations.gd:443, 467, 614, 627 | days known / days courting | days | CRT-10: closeness over time | marry ≥1.5 yr after meeting | O (social) | no (see §2) | reasonable for play time | **same functions** for player and NPC |
| Tie decay | `decay_per_day` 0.5 bal:48; relations.gd:577 | per day without contact | days | ties cool | 4/yr | O | no | fine | same |
| Closeness | `close.sample_minutes` 2, `regard_per_hour` 1, `attraction_per_hour` 0.5, `known_minutes` 20; `shared` per hour bal:75-77; relations.gd:342-397, 487-560 | per hour | hours | time together | — | O | no | fine | player: closeness; NPC: shared hours (same unit, the hour) |
| Notoriety | `notoriety_days` 16, `notoriety_refuse` 3 bal:59-60; relations.gd:273-279 | 16 days | days | crimes remembered | **2 yr** | O/C (§2) | no | reasonable in play time (3.2 real h) | player only (villagers' crimes not tracked this way) |

## 1. Systems already consistent with their intended time model

- **Human ageing, stages, eligibility, births** (life.gd:42-58, 84-92, 474-505): all in years. The birth chance is converted with `year_days()` (life.gd:476). Mortality is the exception (D2).
- **Seasons** (`Life.season`) correctly gate player crops (farming.gd:199-210), fruit trees (trees.gd:102-104) and refuge breeding (refuges.gd:111). Skill history (skills.gd:107-113) is in years.
- **Operational systems** (hunger, rest under PAR-03, daily rhythm, labour and recipe minutes, reports, loot, predation) never read the calendar, which is correct.
- **Daily economics** (wages, obligations, tax, stall rent, OD-19 reserves, relief, famine, granary food-days, caravan) use operational days consistently.
- **Courtship** uses days known, matching CRT-10's play-time guard.
- **Parity:** courtship (`ask_court`/`propose`), rest, products, rent and reserves (`World.necessity`) apply the same rule to the player and to NPCs.

## 2. Systems with ambiguous time units

1. **`Property.WEEK = 7`** (property.gd:18): an owner rule says "weekly", but a week is not a calendar unit here. 7 days = 0.875 year, so due days drift against seasons and years. The value is not in balance.json, and the wiki says "rent is weekly" (wiki.gd:522, 574). Two missed weeks give 14 days, or 1.75 years.
2. **Animal ages in days, human ages in years.** balance.json:229 says "a day = 1/year_days of a year", and the values are clearly calibrated as years (cow 15-20 yr, chicken 5-7 yr). The code reads them as raw days (animal.gd:42; fauna.gd:134, 442, 450-461). The wiki contradicts itself: it says "people and animals keep ageing" in years (wiki.gd:580) and also that animals are staged "by their age in game days" (wiki.gd:607).
3. **Tree, plant and field durations** are written as day counts. Their meaning ("one season", "under a year") rests on the unstated assumption that a year has 8 days.
4. **Refuge `interval_days`** (fox/wolf 8 = exactly one year, bear 16 = two years) are calendar periods written as day counts.
5. **Courtship and notoriety**: the gates are days, but the eligibility ages are years. With 8 days a year the result is sensible (marriage at least 1.5 yr after meeting). The values are unlabelled, so nothing records whether they are meant as play time (operational) or social years (calendar). My reading of CRT-10 is that they are operational.
6. **"Week" windows hard-coded as 7**: chronic relief (npc_brain.gd:2461-2466), the income history (npc_brain.gd:3094) and job cooldown (`job_switch_cooldown_days` 7). These are a 7-day week in an 8-day year.
7. **`skill_start.xp_per_year` 300** is calendar XP. The player earns XP per action, which is operational. A 25-year master (7,500 XP) stands for 200 game days of history, and nothing documents whether that equivalence is intended.
8. **Literals outside balance.json:** `ANIMAL_LOOT_DAYS` 3 (world.gd:2696), keeper feed of 4 days (npc_brain.gd:1971), repairs `3.0 * obligations` (npc_brain.gd:2186), player starvation 3.0 (world.gd:507), obligations `4.0 +` (npc_brain.gd:2486), fauna start spread of 3 days (fauna.gd:127). The literal 1440 is used instead of `World.DAY` in animal.gd:42, fauna.gd:134/442, farming.gd:526/530, world.gd:347 and trees.gd:23. Dev-only literals: main.gd:630, 1033, 3799.

## 3. Genuine defects (OD-21 §5)

- **D1. Village fields ignore the seasons; player crops do not** (wrong clock for seasonal agriculture, and a parity violation). Village fields ripen `field_grow_days` (2) after sowing in every season, winter included (world.gd:1359-1360, 1372, 323-328). The comment at world.gd:1357-1358 calls the season dependence "a hook, not a mechanic yet". The player's crops stop in winter, run at half rate in autumn and cannot be sown in winter (farming.gd:199-210, 227-238). So the village gets about 4 field cycles a year, the player about 2.5. Fixing this changes the food baseline a great deal (it touches the seed-2 starvation investigation), so it needs owner review and a comparison first.
- **D2. The human old-age hazard is per game day while ages are in calendar years** (life.gd:130-138, rolled at every dawn 329-336, `mortality_daily_max` bal:18). Births are converted per year (life.gd:476); deaths are not. Integrated hazard from 60 to age *a* is 5.33·u³ per year at 8 days (u = (a−60)/20). The median age at death is about 70.1 yr at 8 days/yr, about 68.0 at 16 and about 72.8 at 4. Changing the calendar would therefore change lifespans in years. There is no behaviour change at 8 days. Fix: express it as a per-year hazard and convert it with `year_days`.
- **D3. Animal life cycles would not scale with the calendar** (§2.2). The values are meant as years but stored as days. Changing `year_days` would change animal lifespans and maturity in years while human ones stay fixed. There is no behaviour change at 8.
- **D4. The player's starvation damage is a hard-coded 3.0/h** (world.gd:507) against the villagers' `starve_damage_per_hour` 2.0 (world.gd:398). It is documented in the wiki (wiki_topics.gd:89), so it is a known divergence. It is still a parity difference and sits outside the data file. With 100 hp against an NPC's 30 hp, the player lasts about 33 h at zero food and an NPC about 15 h. The owner should confirm or unify it.

No other evidence of a wrong clock was found. Operational and economic day counts are internally consistent at 8 days a year.

## 4. Gameplay-balance concerns (not defects)

- **Trees:** stump to mature in 5-8 days (0.6-1.0 yr). Very fast in calendar terms, but log supply depends on it (`trees_per_woodcutter` 30).
- **Breeding seasons:** wild animals in the woods (fauna.gd:417-447) and livestock breed all year; refuges breed only in season (refuges.gd:111). Wild plants ripen again in winter; fruit trees are seasonal.
- **Tax cadence:** tax is levied every evening at 6-12% of cash above the exemption, about 39% a year at 6%. The tax holiday at 30 obligation-days (3.75 yr) is rarely reached.
- **Pen products:** wool every 4 days means 2 shearings a year. A hen gives 8 eggs a year, about 30-40 in her lifetime.
- **Rent:** eviction after 14 days (1.75 yr) is lenient. The 2-day reserve sees rent only when it falls due within 2 days.
- **Long horizons:** `manor_hire_runway_days` 20 and `manor_order_days` 10 are long for an economy otherwise reckoned in 2-7 days.
- **Caravan:** it arrives once per season only because both numbers happen to be 2.

## 5. Recommended retuning (TIME-03: proposals only; owner review before any change)

| Outlier | Recommendation | Expected consequence |
|---|---|---|
| Tree growth and regrowth | Classify as C. Express in seasons: stump 2-3 seasons, growth about 1 yr in total (that is today's ~0.6-1.0 yr, written as calendar units). Leave the speed alone unless log shortages are wanted; a slower forest needs `trees_per_woodcutter` raised. | No change at 8 days if only the units change. Any lengthening cuts log and plank supply, raises construction costs and slows household founding. |
| Crop growth and seasonal restrictions | Fix D1: village fields take `season_rate`/`sow_seasons` like the player's, keeping 1 season for wheat. Compare against seed-2 first. | Village grain falls by about 35-40%. The winter gap must be covered by granary stock (7 days already covers a 2-day winter), and relief demand rises. This is the largest effect on food security. |
| Egg and milk production | Keep operational/daily (the food economy is daily). Optionally reduce laying in winter. Wool to once a year (8 days) or once per Spring season. | Eggs and milk barely change. Wool falls by half, which reduces cloth (`weave_cloth`). |
| Livestock breeding and lifespans | Convert to years (`grow_years`, `breed_years`, `death_years`) with the same values (cow 0.75/0.75/15-20). Consider seasonal breeding to match refuges. | No change at 8 days. Seasonal breeding lowers herd growth by up to 50% and reduces meat and hide supply. |
| Rent and leases (Property.WEEK) | Move to balance.json as `rent_period_days`. Either keep 7 and document it as a 7-day market week, or align it to the year (8) or the season (2, with the share scaled to 2/7). | Aligning to 2 days with the same daily cost keeps the economics. Eviction comes sooner (4 days), so more evictions in poor households. Aligning to 8 is +14% rent per day unless the share is adjusted. |
| Courtship and marriage | Keep in operational days (CRT-10 play-time guard) and label it so. Do not scale with the calendar. | No change. |
| Food reserves (`reserve_days`, famine, caravan keep) | Keep O/E in days. | No change. |
| Manor relief | Keep in days. Move the 7-day window literal into balance.json. | No change. |
| Granary targets | Keep 7 food-days. If D1 is fixed, consider a seasonal top-up (target ≥ autumn half-rate plus 2 days of winter consumption, about 3-4 days), so 7 is adequate. | No change now. With D1 fixed it decides whether winter causes starvation. |
| Treasury reserves | Keep 10 obligation-days (E, operational day). | No change. |
| Tax holidays | Consider 30 → 16 (2 yr) or a yearly tax (levy once per year at about 8× the daily rate). | Lower: more holidays and public works, more household cash. Yearly levy: lumpier cash flow and seasonal arrears risk. |
| Caravan frequency | Keep 2 days and document it as "once per season at 8 days/yr". Optionally express it as `caravan_per_season` 1 if seasonal trade is wanted. | No change at 8 days. |
| Reputation and notoriety | Keep `notoriety_days` 16 operational (3.2 real h) and label it. `decay_per_day` likewise. | No change. |
| Human mortality (D2) | Per-year hazard: `mortality_yearly_max` 0.8 (today's equivalent), converted per day. | No change at 8 days; future-proof. |
| Starvation parity (D4) | Unify at `starve_damage_per_hour` with a player multiplier key, or document it as intended. | Unifying to 2/h lets the player survive 50 h unfed. |

## 6. Dependencies

- **Agriculture → everything food:** granary (npc_brain.gd:2212), relief (2386-2435), famine (world.gd:313), caravan food export (3159), keeper feed (1971), births (`birth_min_food_days`).
- **Livestock:** pen feed comes from field wheat (npc_brain.gd:1965-1975). Converting stages or seasonal breeding changes products, meat and hide (tanners, `caravan_producer_keep`) and predator prey balance (`prey_per_predator`, refuges).
- **Household economics:** rent period, `reserve_days`, wages and daily tax meet in `World.necessity` (world.gd:662-712) and sustainability and mobility (npc_brain.gd:2638-2762).
- **Generational:** mortality (D2), birth rate, stage ages, courtship days and `partner_max_gap` set population turnover. Succession, newcomer days and `job_return_days` set trade continuity. Births depend on food-days, so agricultural changes reach demography.

## 7. Where the shared conversion layer goes

Already in place: `Life.year_days()`, `year_minutes()`, `age_years()`, `born_for_age()`, `year()`, `day_of_year()`, `season_index()`, `season()`, `clock_text()` (life.gd:33-80); `World.DAY`, `day()`, `hour()`, `season()`, `year()` (world.gd:27, 211-228).

Proposed additions to life.gd, the calendar layer (no new clock): `days_per_season(i)`, `years_to_minutes(y)`, `seasons_to_minutes(s)`, `days_to_minutes(d)` (operational), `per_year_to_per_day(p)` = 1−(1−p)^(1/year_days), and a `season_start(now)` cadence helper. All balance keys would carry an explicit unit suffix (`_hours`, `_days`, `_years`, `_seasons`).

Call sites that would read through it:
- **Calendar values**: animal.gd:42-60; fauna.gd:127-134, 442, 450-461; refuges.gd:65, 121, 129, 153, 237; trees.gd:23, 165-171, 224; world.gd:1143-1144 (stumps), 1003-1004 (plants), 968-969 (fruit), 1359-1372 (fields); farming.gd:238, 278 (crops); life.gd:130-138 (mortality).
- **Operational days via `World.DAY`**: farming.gd:526, 530; world.gd:347, 2749; property.gd:18, 421; npc_brain.gd:1971, 2186, 2461-2466, 3094; the player starvation literal at world.gd:507.
- **Display**: wiki.gd:576-607 and wiki_topics.gd:102-117 should print the units from the same layer.

## 8. Implementation (TIME-02)

The conversion layer is `Life` (game/scripts/core/life.gd, "time units (TIME-02)"); there is still one clock,
`World.minutes`. Functions: `season_count()`, `years_to_days(y)`, `seasons_to_days(s)` (a season is
`year_days / season_count` days), `days_to_years(d)`, `years_to_minutes(y)`, `seasons_to_minutes(s)`,
`per_year_to_per_day(r)` (a yearly hazard as the daily rate a dawn roll uses; linear, like the birth chance) and
`season_range_days([lo, hi])` (a season range as whole days for the regrowth draws). Helpers on top of it:
`Animal.stage_days(spec, "juvenile"|"grow"|"elder"|"breed")`, `Animal.death_days(spec)`, `Farming.crop_days(crop)`,
`World.field_grow_days(f)`, `Trees.stage_minutes(stage)` (its cache now also keys on `year_days`).

Calendar values renamed in balance.json with their unit, every reader changed with them (values divided by 8 or by 2,
so the results at 8 days a year are the old day counts exactly: those divisions are powers of two):

| Old key (days) | New key | Read by |
|---|---|---|
| `life.mortality_daily_max` 0.1 | `life.mortality_yearly_max` 0.8 (per year, D2) | `Life.death_chance` |
| `animals.*.juvenile/grow/elder/breed_days`, `death_days` | `*_years`, `death_years` | animal.gd, fauna.gd (spawn ages, breeding, old age), refuges.gd, wiki.gd |
| `refuges.species.*.interval_days` | `interval_years` | refuges.gd, wiki.gd |
| `tree_growth.sapling/young/growing_days` | `*_seasons` | `Trees.stage_minutes` |
| `tree_regrow_days`, `plant_regrow_days`, `fruit_trees.*.regrow_days` | `*_seasons` | `World.fell`, `pick_plant`, `pick_fruit` |
| `field_grow_days` | `field_grow_seasons` | `World.field_grow_days` |
| `farming.crops.*.days` | `seasons` | `Farming.crop_days` (hour, days_left), wiki_farming.gd |

Player-facing text is unchanged: resources.json now names the new keys and `GameUI._res_plain` shows `_seasons` and
`_years` keys in game days through the same functions. Unchanged on purpose (operational or economic, section 1 and
5): hunger, rest, work minutes, wages, rent (`Property.WEEK`), reserves, relief, courtship and notoriety days,
`refuges.settle_days`, pen products, caravan days, and the literals of section 2.8 (among them the 3-day spread of
starting animal ages, fauna.gd:127). Verified: `python3 tools/sim_gate.py` identical to its baseline before and after;
`aging_test.gd` `test_time_units` checks that the calendar values double at 16 days a year and halve at 4 while the
operational ones stay put.
