# TIME-03: retuning proposals for the 8-day year (for the owner's review)

**Everything below is a proposal. Nothing in game data or code has been changed.** The owner's decision OD-21
(`docs/directives/2026-10-20_od21_time_model.md`, section 4: "Do not automatically retune these values. Recommend
adjustments based on gameplay purpose, economic consequences, and world consistency") and register entry TIME-03
("proposals only, owner review before any change") govern this document. Each row needs the owner's yes or no before
anything is changed; a yes becomes its own register entry, with a before-and-after seed comparison where the row says
so.

Background: `docs/design/TIME_MODEL.md` (TIME-01 inventory, TIME-02 units). The calendar is 24-hour days, 8-day
years, four 2-day seasons. Since TIME-02 the calendar values carry their unit in their key (`*_seasons`, `*_years`) and
are read through `Life`; the values below are as of `game/data/balance.json` at staging 33013f3 (Build 16). "At 8
days" converts a value to the calendar so its proportion can be judged.

Classes: **O** operational (hours and days of activity, never scales with the calendar), **E** economic (operational
days or calendar periods, whichever the obligation is), **C** calendar (seasons and years; scales with
`calendar.year_days`).

## Summary: the outliers

Out of proportion under the 8-day year, in order of effect:

1. Village fields ignore the seasons (D1): four harvests a year, winter included, where the player gets about 2.5.
2. Daily taxation: up to 12% of cash a day, about 39% a year at the 6% rate, against a tax holiday (30 obligation-days,
   3.75 years) that is rarely reached.
3. `Property.WEEK = 7`: a 7-day "week" in an 8-day year, outside balance.json; eviction after 2 weeks is 1.75 years.
4. Wild animals and livestock breed all year, while the refuges breed only in season.
5. Long economic horizons beside an economy reckoned in 2-7 days: hire runway 20 days (2.5 years), manor orders 10
   days.
6. Wool: shorn every 4 days, twice a year.
7. Seven-day windows hard-coded in code (chronic relief, income history).

Everything else is in proportion or is operational time that is meant not to scale (section 3).

## 1. Proposals that change behaviour (each needs the owner and a seed comparison)

| # | System | Key (file) | Current value | Unit and class | At 8 days | Effect now | Proposal | Expected consequence |
|---|---|---|---|---|---|---|---|---|
| P1 | Village fields: the seasons | `field_grow_seasons` 1; `seasonal_village_farming` 0 (balance.json), `World.field_grow_days` | 1 season to ripen, sown and ripening in every season | C, but no season gate | 4 harvests a year, winter included | The village's grain comes all year round; the player's crops stop in winter and slow in autumn (`farming.season_rate`, `sow_seasons`), a parity difference (TIME_MODEL D1) | **Proposal:** village fields follow the player's rule (`season_rate`, `sow_seasons`), keeping 1 season for wheat. This is the FSE-13 switch (`seasonal_village_farming`), already built and off; enable it only on the owner's decision after the FARM-08 comparisons | Village grain falls by about 35-40%; winter must be bridged by the granary (7 food-days today) and household stores; relief demand rises. The largest single effect on food security, livestock feed and seed. **Owner decision; not a time-model fix alone.** |
| P2 | Daily tax | `tax_rate_low_treasury` 0.12, `tax_rate_normal` 0.06 per evening (`NPCBrain.reeve_day`) | 6-12% a day of cash above the exemption | E (operational day) | two levies a season; ~39% a year at 6% (1 - 0.94^8), ~64% at 12% | Households lose cash above the exemption quickly whenever the treasury is under 30 days of obligations | **Proposal A:** keep the daily levy and halve both rates (0.06 / 0.03). **Proposal B:** levy once a season (every 2 days) at twice today's daily rate. **Or keep.** | A: more household cash, a slower-filling treasury (less relief buying power in a shortage, TREAS-01). B: the same yearly take in lumps; seasonal arrears risk. Either needs a seed comparison of treasury and household cash |
| P3 | Tax holiday | `treasury_tax_holiday_days` 30 | 30 obligation-days | E | 3.75 years of wages | Above it no tax and public works spend the excess; rarely reached, so tax runs nearly always | **Proposal:** 16 (two years of wages). Or keep | More frequent tax holidays and public works; household cash higher; treasury lower on average |
| P4 | Rent period | `Property.WEEK = 7` (property.gd:18, a literal) | 7 days | E | 0.875 year; due days drift against seasons | Weekly rent and leases (the owner's "weekly" rule; FARM-07's 2 coins a week) | **Proposal:** move to balance.json as `rent_period_days` with 7 (no behaviour change) and document it as "a 7-day market week". Aligning to the season (2 days) or the year (8) is a separate owner question | Moving the literal: none. Changing the period changes every lease's cost a day and the eviction clock (P5) |
| P5 | Eviction | `rent_evict_missed` 2 | 2 missed periods | E | 14 days, 1.75 years | A household in arrears keeps a house for two weeks | **Keep** (the owner's lease rules apply unchanged under FARM-07: "no new penalty or eviction mechanic") | None |
| P6 | Livestock and wild breeding seasons | `animals.*.breed_years` (cow 0.75, chicken 0.375 ...); `Fauna.new_day` | All year | C (length scales; no season gate) | Cow a calf every 0.75 yr | Pens and woods breed in winter; refuges only in season (`refuges.species.*.seasons`) | **Proposal:** wild animals in the woods breed only in their refuge seasons (one rule for a wild species, in or out of its refuge). **Keep** year-round breeding for livestock (pens are fed and sheltered), at least until the cattle investigation (FARM-08B/C) is closed | Wild herds grow up to 50% slower; less game, fewer hides; predators' prey margin narrower. No effect on livestock |
| P7 | Wool | `farming.products.sheep` days 4.0 | Every 4 days | O/E | Twice a year | Wool for cloth (`weave_cloth`) | **Proposal:** once a year (8 days), or once in Spring. Eggs and milk: **keep** daily (the food economy is daily) | Wool halves or quarters; cloth and the tanner's weaving fall. Small economy effect |
| P8 | Manor hire runway | `manor_hire_runway_days` 20 | 20 days of a wage | E | 2.5 years | The manor hires hands (and, since EQ-04 in Build 16, opens a guard's post) only with 20 days of the wage to spare above its reserve | **Proposal:** 10 (the same as the treasury reserve). Or keep | More hiring and guard posts filled sooner; the treasury runs closer to its reserve |
| P9 | Manor tool orders | `manor_order_days` 10 | 10 days | E | 1.25 years | An advance paid to a smith lapses after 10 days | **Keep** (a forge's backlog can be long; lapsing sooner only wastes the advance's purpose) | None |

## 2. Proposals that change units or labels only (no behaviour change at 8 days)

| # | System | Key | Current | Proposal | Consequence |
|---|---|---|---|---|---|
| U1 | Chronic relief window | literal 7 in `NPCBrain._note_relief` | 7 days | Move to balance.json `chronic_relief_window_days` 7 | None; one place to change |
| U2 | Household income history | literal 7 (`income_days` kept 7) | 7 days | Move to balance.json `income_history_days` 7 | None |
| U3 | Keeper feed stock | literal 4 days (1 in famine) in the keeper's feed code | 4 days | Move to balance.json (Worker C's area: the cattle workstream decides the value) | None |
| U4 | Carcass spoiling | `World.ANIMAL_LOOT_DAYS` 3.0 | 3 days | Move to balance.json `carcass_spoil_days` 3 | None |
| U5 | Caravan | `caravan_every_days` 2 | every 2 days | **Keep** 2 and document it as "once a season at 8 days a year" (a coincidence today) | None |
| U6 | Courtship and marriage | `court_min_days` 3, `propose_min_days` 6, `marry_min_days` 12, `interest_days` 2 | days | **Keep** as operational days (CRT-10's play-time guard) and label them so | None |
| U7 | Notoriety and tie decay | `notoriety_days` 16, `decay_per_day` 0.5 | days | **Keep** operational (16 days is 3.2 real hours) and label them | None |

## 3. Reviewed and in proportion (keep)

| System | Key | Value | At 8 days | Why keep |
|---|---|---|---|---|
| Tree growth | `tree_growth.*_seasons` 0.375/0.375/0.25; `tree_regrow_seasons` [1.5, 3] | sapling to mature 1 season; stump 1.5-3 seasons | felled to mature 0.6-1.0 year | Fast in reality, but the log supply (`trees_per_woodcutter` 30) and housing depend on it; already calendar units (TIME-02). A slower forest would need `trees_per_woodcutter` raised. **Keep** unless log shortages are wanted |
| Wild plants | `plant_regrow_seasons` [1, 2] | 1-2 seasons, ripen in winter too | — | **Keep** the length; a season gate (no ripening in winter) is a possible later proposal with P6 |
| Fruit trees | `fruit_trees.apple_orchard` regrow 1-1.5 seasons, Summer/Autumn | 1-2 pickings a year | — | Seasonal already. Keep |
| Player crops | `farming.crops.*.seasons`, `season_rate`, `sow_seasons` | 0.5-1.25 seasons | — | Seasonal already. Keep |
| Eggs and milk | `farming.products` chicken 1/day, cow 2/day | daily | — | The food economy is daily. Keep |
| Animal stages and lifespans | `animals.*_years`, `death_years` | cow adult 0.75 yr, dies 15-20 yr | — | Already years (TIME-02, D3 fixed). Keep |
| Human mortality | `life.mortality_yearly_max` 0.8 | per year | median death ≈ 70 yr | Already per year (TIME-02, D2 fixed). Keep |
| Food reserves | `reserve_days` 2, `famine_food_days` 2 | 2 days | a season | Operational horizon. Keep |
| Manor relief | `relief_trigger_days` 2, `relief_fill_days` 3 | food-days | — | Operational. Keep (U1 only moves the window literal) |
| Granary target | `granary_target_days` 7 | 7 food-days | 0.875 yr of food | Covers a 2-day winter with margin if P1 is adopted. Keep; revisit with P1 |
| Treasury reserve | `treasury_reserve_days` 10 | 10 obligation-days | 1.25 yr of wages | Consistent; used for tax, hiring and relief floors. Keep |
| Succession | `succession_days` 3, `newcomer_max_days` 10 | days | 0.375 / 1.25 yr | Keep |
| Job mobility | `job_switch_cooldown_days` 7, `job_return_days` 14 | days | — | Keep |
| Wages and stall rent | `*_wage_per_day` 6, `stall_rent_day` 5 | coins a day | — | Operational days. Keep |

## 4. Not a time question (left as they are)

- **D4, player starvation 3/h against villagers' 2/h** (`world.gd`, a literal): a parity question, not a calendar one.
  It is recorded in TIME_MODEL D4 for the owner to confirm or unify.
- The FSE-12/FSE-13 balance switches (`shared_manor_farming`, `seasonal_village_farming`, `shared_wheat_yield`) are
  the owner's open FARM-08 decision; P1 only notes that the seasonal one is the time-model fix of D1.

## The owner's decisions requested

For each of P1-P9 and U1-U4: adopt, adopt with another value, or keep. U5-U7 and section 3 are recommended to keep
as they are.
