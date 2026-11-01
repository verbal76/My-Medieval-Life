# Economic progression audit: what the year-long simulations exercise (X20-ECON-AUDIT)

Owner directive 2026-11-01, section 2 (`docs/directives/2026-11-01_economic_maturation_master_directive.md`). Read-only audit of
commit `ae8641d` (`wip/x20-chapel`, the chapel correction on the Build 25 source) and its three 365-day runs: Actions
41279031310 (normal, seeds 1 and 2: N1, N2) and 41279051834 (Living Economy on, seed 1: E1). Evidence: the job logs and the
per-checkpoint digests of `sim.json` (every 10 days) read back by the recovery job. Code paths under `game/scripts/core/`
unless stated. Classification uses the directive's five classes. Nothing here changes gameplay.

## Summary

| # | System | Classification | Main evidence |
|---|---|---|---|
| 1 | Experience and skills | Implemented and exercised (inferred) | XP-earning acts happen (logs 9,433 felled, ore 648 mined, N1); no skill level is ever recorded, so growth is not measured |
| 2 | Moving to better or specialised occupations | Partially implemented | `seek_work` (npc_brain.gd:4334) chooses only among resource and manor jobs; skilled trades are entered only by succession and apprenticeship (:4476-4615); skills never influence job choice |
| 3 | Job creation, recruitment, unemployment | Implemented and exercised | 190-201 job changes a year; adults 60 → 148-204, jobs held 60 → 51-63, unemployed 0 → 94-141 |
| 4 | Independent production and selling | Implemented and exercised | home production and storefronts (npc_brain.gd:462-609); herbal poultices exported 255 (N1) and 487 (N2) |
| 5 | NPC business formation | Unable to determine from existing evidence | storefront and stall building are reachable (business.gd:234, stalls.gd:508) but their stats are never sampled; founding a new trade (a second smithy) is not implemented |
| 6 | Shop establishment and operation | Implemented but not exercised | `Business` shops and pitches belong to the player (business.gd:256-275); no player acts in the simulation |
| 7 | Inventories, restocking, purchases | Implemented and exercised | traders unable to restock rise from 2-3 to 8-10 of 16 by day ~40 and stay at 7-12 |
| 8 | Merchant activity | Implemented and exercised | 6 merchants all year; merchant funds 720 → 113-417 (Build 25: 0); stall tills 0 → 95-214; 182 caravans |
| 9 | Town-square market | Partially implemented | a fixed market area (merchant stalls, pitches, cart stops) exists; the village has no market day; stall sales are distinguishable in code (`record_sale`, stalls.gd:138) but never sampled |
| 10 | Buyer-seller negotiation | Implemented and exercised with the Living Economy on only | E1: 787 negotiations, 531 settled, 214 without agreement; normal runs trade at set prices |
| 11 | Quantity procurement and labour contracts | Implemented and exercised | contracts (contracts.gd:1131-1312), E1 368 market contracts; manor jobs taken 3,833-5,087; `wage_offers_raised` 0 in every run |
| 12 | Capital accumulation and reinvestment | Partially implemented | villagers build houses and lofts only; workshops only from player code (ui/game_ui.gd:3970); household cash 2,664 → 4,760-6,463 total but 25.6 → 15-18 per person |
| 13 | Business growth, contraction, failure, replacement | Partially implemented | the fixed trades are replaced by succession; no village business closes even with 0 coins (all 3 cooks and both goods merchants at 0, N1 end); off-map settlements do close and open |
| 14 | Supply-and-demand prices | Implemented and exercised | normal play prices by seller stock and nearby sellers (world.gd `sell_price_at`), no demand term; E1 market: asks lowered 3,889, raised 111; no price series recorded |
| 15 | Household savings and discretionary spending | Implemented and exercised | luxuries bought until the traders' fixed import stock runs out (flat from day ~80); lowest-decile household cash 43 → 4 (N1), 34 → 133 (N2) |
| 16 | Resource depletion and replenishment | Implemented and exercised | iron gone by day 30, coal by day 60, copper by 150; trees regrow (193 → 102 → 166-190); wild animals 40 → 70-96 |
| 17 | Population growth and household needs | Implemented and exercised | living 104 → 317-385; 20-24 crowded households; 127 hunger migrants (E1) |
| 18 | Taxes, treasury, chapel, relief | Implemented and exercised | tax 30,982-36,393; manor wages 25,512-33,386; chapel offerings 12,750-14,945 and alms 10,860-13,055; public works never spent |
| 19 | Save/load continuity | Implemented but not exercised | the harness round-trips the economy section only, compares and discards it (economy_sim.gd:179-189); the whole world is never reloaded and continued |
| 20 | Living Economy and the other systems | Implemented and exercised | 337 tool rentals; manor axe advances fall to 0; woodcutters 4-5 late in the year (normal 1-2); cold household-nights 790 (normal 3,419-4,000) |

## Findings that bear on progression (evidence, not yet classified as defects)

1. **Jobs do not grow with the population.** Skilled trades are capped at their starting headcount (`staff_target`, npc_brain.gd:4482) and
   filled only by succession; other openings depend on fields, trees, game, reachable ore and the treasury (`job_market`, :4146-4192).
   Unemployment reaches 64-72% of adults. The manor's wage raise never fires: there is always surplus labour.
2. **Firewood collapses after day ~180 in normal runs** (cold household-nights per 30 days rise from under 10 to 560-770) while the
   village still holds hundreds of logs and woodcutters fall from 6 to 1-2. Woodcutting needs an axe; iron and coal run out by day
   30-60; the manor paid advances for 30 (N1) and 56 (N2) axes and none were delivered. The link from tools to woodcutters is consistent
   with the numbers but not yet measured.
3. **Traders run short of buying money**: 7-12 of 16 below their buying floor from day ~40. Cooks and goods merchants end with 0 coins
   and keep trading; no village business fails or is replaced.
4. **Business formation is limited by design**: villagers can open household storefronts and stalls but cannot found a new trade
   business, rent a shop, or build a workshop; luxuries are never restocked; ore never regenerates (by rule).

## Missing instrumentation (to be added in Phase A, harness and statistics only)

- skill levels by job; open places per job and seekers; job moves by from-job and to-job
- storefronts and stalls built by villagers; household stalls active; stall sales, settlements and commission per checkpoint
- trader stock value and the traders below their buying floor (in `sim.json`, not the digests)
- price series for food, logs, wheat and tools
- Living Economy market statistics per checkpoint (printed only at the end today)
- unaffordable bids by caller, item category, household condition and binding cause (`econ_market.gd:756` counts them without detail)
- firewood: which households go cold, their cash and bracket, whether a seller held logs, logs held by holder group
- households tracked longitudinally (identity, members, cash, wealth, income), so a household growing richer can be told from a richer one arriving
- a whole-world save, reload and continue check (fingerprint comparison)

## Notes on evidence

The GitHub log filter drops several end-of-run lines (contracts, credit, work, materials, wildlife, building, manor work); the digests
omit `materials`, `wildlife`, `ledger`, `regions`, `farm`. The flight recorder was off. Script errors in these runs are all the known
gossip defect X20-TELL-GUARD (`judgment_store.gd:1490`).
