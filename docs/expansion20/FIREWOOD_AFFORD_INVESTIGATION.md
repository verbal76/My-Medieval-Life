# Firewood, axes, the manor's wage raise and unaffordable bids (X20-FIREWOOD, X20-AFFORD)

Owner directive: `docs/directives/2026-11-01_economic_maturation_master_directive.md` sections 4 and 5 (on
`wip/requirements-control`). Earlier evidence: `docs/release/economic_maturation/AUDIT_20_SYSTEMS.md` findings 1-2,
`docs/release/build25_validation/` (runs 41233948995, 41233970504), `docs/expansion20/ECONOMIC_INVESTIGATION_2026-11-02.md`.
Branch `wip/b25-firewood`, from `d6ab686` (the Build 25 source). Worker report to the lead; the register is not edited here.

## 1. Evidence used

| Run | Code | Configuration | Days | Why |
|---|---|---|---|---|
| A | `d6ab686` | normal play (economy off), seed 1, `--every 20` | 200 | the one long run (SIM-01): firewood, woodcutters, axes, wage offers |
| P | `d6ab686` + `tests/firewood_probe.gd` (read only) | as A, one line a day | 130 | the iron-to-axe-to-woodcutter chain day by day; its trajectory is A's (day 20: treasury 152, trees 156, iron + coal left 180 in both) |
| M | `d6ab686` | `--market` (Living Economy on, shipped `economy.json`), seed 1, `--every 15` | 90 | X20-AFFORD: unaffordable bids exist only with the economy on (section 4) |
| F | `3b530d5` (the two fixes) | as A | 160 | the fixes' effect; a different code configuration, so a separate run (SIM-01) |
| scenario | `d6ab686` | `od16_test`-style set-ups, a few game days | - | the manor's advance to a coinless smith, step by step |

Run A: currency leak 0, item leaks 0, exit 0, fingerprint `9ee7b0bcc7182024207cad35b99d7d5e`. (Its LEAKS line also prints a
deposits note, tin ore mined 48 against 0 taken from deposits: the trial pits' tin, the same in run M (24); not a ledger
failure, exit 0, outside this task.) Run M: currency 0, items 0, fingerprint `325ff60699a74f335d19d42cb1b7abdf`.

## 2. Firewood (X20-FIREWOOD)

### 2.1 What was measured (run A, cold household-nights by 20-day interval)

| Days | 0-20 | 20-40 | 40-60 | 60-80 | 80-100 | 100-120 | 120-140 | 140-160 | 160-180 | 180-200 |
|---|---|---|---|---|---|---|---|---|---|---|
| Cold household-nights | 5 | 8 | 13 | 4 | 1 | 2 | 38 | 58 | 78 | 105 |
| Households | 25 | 25 | 25 | 26 | 26 | 26 | 26 | 26 | 26 | 28 |
| Woodcutters (end) | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 4 | 3 | 3 |
| Retired (cumulative) | 0 | 0 | 3 | 4 | 6 | 10 | 18 | 27 | 36 | 42 |

- **Every one of the 312 cold nights had logs for sale** (`cold_sellers_had_logs` 312 of 312): woodcutters, carpenters and
  merchants held 89-150 logs at every checkpoint, and households' pantries 140-640 more (concentrated in four or five
  woodcutters' and labourers' families: logs no buyer takes go to the family chest, FSE-18). Supply was never what bound.
- **The households were not poor.** By household cash on the cold night: under 3 coins 5, 3-19 coins 27, 20-99 coins 229,
  100 or more 51. The early nights (days 0-60) are one household with 4 coins (hardship, an outcome); from day 120 on, the
  cold households hold 30-120 coins and are cold night after night: household 24 (two elders, 77 coins) 37 nights of 40
  from day 120; households 13, 21 and 22 17-20 nights of every 20.
- The rise starts with the founding generation's retirements (10 by day 120, 42 by day 200).

### 2.2 Cause (traced in code)

1. **Elders never bought the household's necessities.** `NPCBrain._decide` sends an elder (55 and over, retired) to the
   family's farmland, the church plot or a walk; only adults reach `_plan_evening`, whose second step is `_plan_provision`
   (firewood when the pantry has none, grain when it holds fewer units than members), and guards call it on their rounds.
   Purses are personal (no pooling, LE-04 decision 1), and `_plan_provision` pays from the shopper's own purse (3 coins for
   a log). So a household whose coins sit with elders (an elder-only home; retired parents holding the savings while the
   adults of the house hold 0-2 coins; a widow who inherited, `World._inherit`) has no one who both shops and can pay.
   OD-19/PAR-02A say a household's necessities may be bought out of any of its coins ("the reserve is intended to protect
   essential needs, not prevent the household from satisfying them"). **DEFECT** (a mechanic failing its approved function).
   Fixed (section 2.4).
2. Diagnostic added to tell this from poverty: `World._cold_detail` now counts whose purse could have paid for the night's
   log (`cold_payer_adult`, `_elder`, `_child`, `_none`). Read only (fingerprint identical, section 6).
3. What is not explained by (1) (left for the year run to measure with `cold_payer_*`): a cold household where an adult
   holds the price. Code reading finds one more legitimate path: `_plan_provision` tries only the first seller
   (`_seller_of`, or the judgment's pick) and plans nothing when that seller's price beats the shopper's purse; with 3-4
   coin logs and these purses it should be rare.

### 2.3 Woodcutters and axes

- **Places.** Woodcutter places are grown trees / `trees_per_woodcutter` (30): 4-5 all run (trees 128-171). Woodcutters
  fell from 6 to 3 by day 200: 2 left early for other trades (day 5 "out of work": an axe broke, 44 coins against a 45-coin
  axe; day 8 an apprenticeship), both replaced by day 17 (a hunter and a jobless adult took the places); Sabina Barley retired
  on day 73 and was replaced; after day 140 two more left (retirement or death) and nobody took their places. Places open at day 200: 2.
- **Who could fill them.** A place with a tool is open to a seeker only with the tool or its price (`_job_options`). The
  jobless (10 at day 100, 16 at day 200) are all young people who came of age in the run and never had a job, median coins
  0. Axes were plentiful: 26-31 held in the village (42 made, 15 exported), the goods merchant 4-8 for sale at about 41-45
  coins, and 17-19 held by people not in the trade (retired and former woodcutters keep theirs; succession passes tools only
  in the skilled trades). The manor's tool support (`tool_needers`) serves only workers already in a trade. **OUTCOME** of the
  approved rules; the policy is owner question **B25-ECON-P2** (first tool for a coinless adult) and **P3** (stock and tools
  held by retirees); evidence added in section 7.
- **The manor's axe advances.** In run A the manor bought 4 axes on sale and advanced 4 (2 delivered, 1 lapsed, 1 open at
  day 200). The year runs' "0 of 30-56 delivered" comes after the founding smiths retire (in run P both experienced smiths,
  levels 8-9, leave around day 115-120; their apprentices start at level 1 with 0 coins and no stock; the masters keep 30 ore,
  30 coal, 12 bars, 10 planks, 3 axes and 3 pickaxes each, P3). Scenario, step by step (seams worked out, the raw-goods
  merchant holding 40 ore and 12 coal, a new smith with nothing): the manor advances 32 coins; the smith buys the plank (2)
  and the coal (6), then the ore as stock: `buy_from` lets non-necessities use only coins above the OD-19 reserve, and a
  household with no other coins reserves 17. It bought 2 of the 4 ore and could buy no more (`buy_failed` at a 3-coin
  price with 18 coins); the order lapses after `manor_order_days` (10) and the advance is spent on the household. With the
  household holding coins elsewhere (reserve 0) the same smith forged and delivered the axe. EQ-19's acceptance: "with the
  smith short of coins, the manor's support lets the forge buy ore and make axes". **DEFECT.** Fixed (section 2.4).
- Once the iron is gone (the seams out by day 36-100; nothing imported, P4), no axe can be forged whatever the money:
  **OUTCOME** (WDR-013 finite deposits).

### 2.4 Fixes (commit `3b530d5`)

1. `NPCBrain._elder_provides(n)`: an elder stocks the pantry through the same `_plan_provision` (its own purse, the same
   prices and rules) when no living adult of the household holds 3 coins. First step of the elder's branch (recorder branch
   `elder_provision`). An adult with the coins keeps the shopping, so who pays changes only where nobody else could.
2. `_fetch_for_order` marks its purchases `order`; `buy_from` lets reserved coins pay them, as OD-19/PAR-02A lets "due
   obligations" (the advance was paid for exactly this). Nothing else in the reserve rule changes.

Neither creates coins, goods or demand; no rescue is added (a household with no coins, or no log on sale, is still cold).
Tests: `game/tests/elder_provision_test.gd` (11 checks: an elder-only household buys; an elder buys when the adults hold 2
coins; an elder leaves it to an adult with coins; an elder with 2 coins does not; a stocked pantry is not restocked; the log
reaches the pantry, the elder's purse pays the seller's price, total coins unchanged) and
`game/tests/od16_test.gd::test_advance_pays_the_orders_inputs` (reserve 17 of a 32-coin advance; buys plank, 2 coal and 4
ore; the axe is forged and delivered; coins only move).

### 2.5 Effect (run F)

Run F (`3b530d5`, seed 1, 160 days, `--every 20`): currency leak 0, item leaks 0, exit 0, fingerprint
`c7666dd8ee86db8409a7be6b58c4d8ba`. Identical to run A up to day 120 (the same checkpoints, cold nights 5, 8, 13, 4, 1, 2:
no household lacked an adult with a log's price before then, so the fix changed nothing).

| Days | 120-140 | 140-160 | 0-160 |
|---|---|---|---|
| Cold household-nights, run A (`d6ab686`) | 38 | 58 | 159 |
| Cold household-nights, run F (fixes) | 2 | 2 | 37 |
| Logs burned to day 160 | | | A 3,972, F 4,088 |

Run F's 37 cold nights by whose purse could have paid (`cold_payer_*`): nobody in the household held 3 coins 30 (poverty: an
outcome), an adult held the price 7 (section 2.2 item 3), an elder 0. The cold nights from day 120 are those of households
with 3-19 coins. Everything else at day 160 is within the runs' divergence (alive 127 both, woodcutters 4 both, jobless 17
and 16, treasury 602 and 694). No manor advance fell due in either run by day 160, so fix 2 is shown by its test only.

## 3. The manor's wage raise (WDR-012-C, `hiring_competition`)

`NPCBrain.seek_work` calls `_hiring_competition(open_left, seekers)` every morning after everyone has chosen: a raise needs
manor places still open while villagers were looking (`unfilled_days` 3 mornings running). It is evaluated every morning
(`competition_test` exercises it directly). Manor places are `(treasury - treasury_reserve_days x obligations) / (wage x 20)`:
in run P that is 0 on 127 of 130 days (1 on days 66, 122 and 123; treasury 84-731 against a reserve of 10 days of wages), and when a
place opens a jobless seeker (16 at day 200, all coinless and with no tool, so the manor's place is the one they can take)
takes it the same morning. So the condition is reachable (a village short of hands) but not met here: there is always
surplus labour. **OUTCOME** (an employer with more applicants than places does not raise its offer). No change.

## 4. Unaffordable bids (X20-AFFORD)

**Where they come from.** `econ_market.gd` counts `bid_unaffordable` when a buyer cannot cover one lot of a bid it is about to
post (`post_bid`), from `post_bids` (needs) and `speculate` (merchants). That market exists only while the Living Economy is on:
`economy.json` ships `"enabled": false`, `EconomyFoundation.attach` returns null, and normal play makes no bids at all. The
12,600 a year are run 41233970504's (`--market`), not normal play.

**What they are (run M, by 15-day interval; the year run's 12,600 is 34.5 a day, the same rate).**

| Days | Unaffordable | Posted | Share unaffordable | Per 100 villagers | Trade inputs | Merchant speculation | Tool | Food (household) | Housing |
|---|---|---|---|---|---|---|---|---|---|
| 0-15 | 553 | 158 | 78% | 517 | 501 | 51 | 1 | 0 | 0 |
| 15-30 | 605 | 132 | 82% | 522 | 556 | 47 | 2 | 0 | 0 |
| 30-45 | 572 | 105 | 84% | 461 | 505 | 64 | 3 | 0 | 0 |
| 45-60 | 511 | 101 | 83% | 406 | 471 | 39 | 0 | 0 | 0 |
| 60-75 | 482 | 115 | 81% | 374 | 443 | 37 | 0 | 0 | 2 |
| 75-90 | 447 | 105 | 81% | 344 | 412 | 35 | 0 | 0 | 0 |

- **Essentials:** none. A household's food bid draws on its whole purse (OD-19) and never failed; housing 2, a trade's
  tool 6 in 90 days. 92% are **trade inputs** (`NPCBrain.wants`, SHOP-01 restocking: the goods merchant's swords, armour and
  rings, the cook's and tavern's wheat, milk, meat and cheese, the raw-goods merchant's ore and hides), 8% merchants'
  speculation (LE-04).
- **Who:** 21-22 distinct buyers; the top five make 69% (590, 501, 447, 402 and 235 to day 90): the same traders every dawn.
- **Why:** to day 90, held back for the reserve and committed needs 41%, no coins at all 30%, short of a lot 29% (days 75-90:
  27%, 40%, 34%). Per-member household cash of the bidder: 20-49 coins in 61%; the traders' own purses are what is short ("traders
  unable to buy" 3-6 of the village's).
- **Counting:** a failure is an attempt, not a failed trade: nothing is posted, and the same need is tried again at the
  buyer's next turn in the round robin (`posts_per_dawn` 6). Raw totals overstate it; per 100 villagers the rate falls by a
  third over 90 days (517 to 344), as population grows faster than the restocking traders.
- **Pattern:** early failures do not give way to affordability: the share stays about 80% and the year rate is the same,
  because the bidders are the traders whose tills sit at their floor (audit finding 3). **Classification: OUTCOME** of the
  shipped Living Economy rules (a trader without spare coins does not restock; nothing is invented to pay for it), plus a
  **measurement** point: report it as attempts per trader per day, not as an annual total. No defect.

## 5. Owner questions (evidence only; the decisions are the owner's)

- **B25-ECON-P2 (first tools for coinless adults).** Run A: woodcutter places open 1-2 from day 160 while 16 jobless young
  adults with 0 coins look each morning; 17-19 axes held outside the trade and 4-8 on sale at 41-45 coins. Options: (a) leave
  it (a coinless adult takes only tool-free work); (b) the manor's tool support (EQ-19) also serves a seeker taking a tool
  place, paid from the treasury as now, at most one per open place; (c) a tool lent against wages (deducted from earnings
  until paid); (d) a household member's spare tool may be used. Recommendation: (d) first (no money moves, uses tools that
  exist), then (b) bounded by open places.
- **B25-ECON-P3 (stock held by retirees).** The two master smiths retired around day 115-120 holding 30 ore, 30 coal, 12
  bars, 10 planks, 3 axes and 3 pickaxes each, while their apprentices started with nothing and the manor's advances were
  needed. Options: (a) leave it; (b) succession passes the trade's stock with the tools (as `_late_masters_tool`); (c) the
  retiree sells it to the successor or the merchants at their prices. Recommendation: (c), a sale (coins and goods move, the
  retiree keeps the value).
- **B25-ECON-P4 (ore imports).** No iron was imported in 200 days; with the seams out, no axe can be forged however the
  money flows, and the woodcutter count then rests on the axes that exist.
- **Who shops for the household (new, low priority).** The fix lets an elder shop only when no adult has a log's price.
  The wider alternative, any member with the coins shopping, also moves money from elders' savings to necessities in homes
  where the adults are poor but not penniless. Recommendation: keep the narrow rule unless the year run shows
  `cold_payer_elder` nights remaining.

## 6. Diagnostics and neutrality

`World._cold_detail` (`cold_payer_*`) and `tests/firewood_probe.gd` (a separate script) read only. 10-day seed 1 fingerprint
(`--days 10 --seed 1 --every 5`): `67b6c604d4f2f83ee99132517f961630` at `d6ab686` (a temporary worktree, removed) and with
the diagnostic (`2021a5b`): identical.

Note: the message of commit `0069250` attributes "3602 checks" to run_tests; that is run_tests' count (exit 0) on `3b530d5`,
and wiki_test printed "wiki_test: all passed".

## 7. Not verified

- The year-long effect on both seeds (run F reaches day 160; days 160-365 and seed 2 not run); the lead's Actions run
  (section 8). Fix 2 in a long run (no advance fell due by day 160).
- The cold nights of households where an adult held the price (if any remain in the year run, `cold_payer_adult`).
- Devices: nothing here is visible on screen beyond the wiki text.

## 8. Year-long run (for the lead)

`long-sims.yml` dispatched on branch `wip/b25-firewood` (its head after this document): `seeds` `1,2`, `days` `365`, `every`
`10`, `set`, `variants` and `sim_args` empty (economy off), `record` false, `recover_run` empty; and a second dispatch with
`sim_args` `--market` and `seeds` `1`, for comparison with runs
41233948995 and 41233970504. Read: `no_firewood_nights` and `cold_*` (now with `cold_payer_*`) per checkpoint, `gov_tool_*`
(advances against deliveries), woodcutters (`JOBS.by_job`), and the LE05/`eaff_*` lines unchanged.
