# Ore on consignment: why Higham stopped, and the two rules reviewed (B25-ECON-P6, owner question 27)

Agent investigation, 2026-11-05. Branch `wip/b25r1-econ4`. Developer reference for INT-779 and INT-777; no gameplay change.

## 1. Why Higham stopped carrying Garton's ore after day 40

Run under review: 120-day seed 1, Actions run 42058240181 (commit e097fab). Reproduced locally to day 40 on `ea37f7f`
(the same code plus an opt-in trace, `MML_TRACE_TRADERS=1`, prints only): the village fingerprint matched the Actions run at
every checkpoint (days 0-40), conservation held (`LEAKS: currency 0; items {}`).

**Root cause: Higham's traders closed on day 34; no other trader existed in the region from day 34 to about day 65.**

The trace (`TTRACE` lines) shows Higham's traders losing their households one a week to better-paid trades through the
weekly job move (`OffMapSettlement._move_jobs`), then closing under the idle rule (`_close_idle`, owner X20-TRADER-CLOSE):

| Day | Event at Higham | Household pay last week | Traders' till |
|---|---|---|---|
| 13 | household 19 moves to the cook | 0 | 262 |
| 20 | household 20 moves to the herd | 15 (2.1 a day) | 237 |
| 27 | household 21, the last, moves to the farm | 6 (0.9 a day) | 205 |
| 34 | the traders close (two weekly looks with nobody) | - | 349 |

The households were paid next to nothing because a founding trader's working reserve is 0.85 of its starting till
(`OffMapSettlement.create`, `b.reserve = int(b.till * 0.85)`: Higham 360 -> 306) and `_pay_wages` pays only the till above the reserve; Higham's
till stayed between 205 and 298 from day 10 to day 30, under 306, so its households earned under `switch_below` (4 a day)
and left for trades paying at least `switch_to_at_least` (8). The same happened to every founding trader: Garton and Bourton
closed on day 20, Netherton on day 27, Wulstead on day 34.

At closing Higham held, for Garton's diggings, 31 iron ore, 30 coal, 11 copper ore and 10 tin ore and 46 coins set aside
(`consign_due`). `_consign_to_treasury` passed them to Higham's treasury, which settles at once (Regions.consign_round):
by day 40 no consignment was held anywhere and Garton's quarry stock had risen from 92 to 200 iron ore. The village had
bought 9 iron ore by then.

From day 34 until Garton's and Bourton's traders reopened (about day 63-70, X20-SETTLE-REOPEN) there was no trader in any
neighbouring place, so `consign_round` found no carrier: no walker, no carrying (WDR-022). From then Garton had a trader of its
own, so by the rule it was not collected from by others (its own trader carries its ore, INT-777); its traders closed again
before day 90 and its quarry closed for a while (no `quarry` business at days 90-110), and ore held in a place's
treasury granary is not collected (only businesses' stock above their keep is). Bourton's trader meanwhile carried
Wulstead's smith's spare iron ore (Wulstead traderless).

**Classification: intended behaviour by the current rules, not a consignment defect.** Higham stopped because it had no
trader; nobody else could carry because no trader existed. The consignment code did what INT-779 says (settled through the
treasury, nothing lost: audits 0). The earlier closure than in run 42028695001 (Higham's trader lasted to about day 100
there) is divergence of the whole region from day 10 (Higham's till 218 against 193 at day 10, before any collection),
not something the consignment did: in both runs the households left by the same rule. No fix was made; no regression
test was added (the closed-carrier path is already covered by `consign_test.gd::test_closed_holders`).

The binding constraint is the founding trader's reserve (0.85 of its starting till) together with the job moves: it starves
founding traders of pay while they hold 200-350 coins, and every founding trader in seed 1 is gone by day 34. That rule
predates consignment (it is the founding-trader rule recorded with X20-SETTLE-REOPEN) and changing it changes how long
traders last, so it is an owner question (recommendation in section 3).

## 2. The two rules against the approved design

Owner answer (question 27, "Other traders consign"): any neighbour trader may carry another settlement's real ore on
consignment through the existing wholesale trips, paying that source on sale. The agent added two limits:
(a) collection only from places with **no trader of their own**; (b) unsold goods walked back after **consign_hold_days = 12**.

Experimental comparison, seed 1, 120 days, on `wip/b25r1-econ4-exp` (f1189a7, balance switches `exp_consign_any`,
`exp_consign_hold`, default off, **never to be merged**), Actions run 42080417065, against the shipped rules (run 42058240181):

| Variant | Iron ore imported by day 40 / 80 / 120 | Village iron ore held day 120 | Traders unable to buy, day 120 | Alive day 120 | Leaks |
|---|---|---|---|---|---|
| shipped (traderless only, hold 12) | 9 / 9 / 11 | 25 | 9 | 129 | 0 |
| any place (`exp_consign_any=1`) | 0 / 0 / 29 | 33 | 7 | 139 | 0 |
| hold 60 (`exp_consign_hold=60`) | 9 / 9 / 11 | 25 | 9 | 129 | 0 |
| any place and hold 60 | 0 / 0 / 29 | 33 | 7 | 139 | 0 |

- **The 12-day return:** no effect in seed 1. With a 60-day hold the village's fingerprint matched the shipped run at every
  checkpoint to day 120; only Bourton kept Wulstead's ore a checkpoint longer. With the any-place rule, adding the 60-day hold
  again changed nothing (fingerprints identical to the any-place run at every checkpoint). Goods walked back are collected again on the
  next round while the source still has spare, so the return costs walking, not supply. It does not cause shortage.
- **Only from traderless places:** relaxing it let Higham collect Garton's ore from day 10, while Garton still had its own
  trader, and the village imported 29 iron ore instead of 11 by day 120 (and held 33 against 25). One seed, and the region
  diverges from day 10 (which traders survive differs between the runs), so the size of the gain is not established; the
  direction is consistent with the mechanism: a place's own trader carries at most its carry room (40 iron ore) on a visit,
  while Garton's diggings held up to 200 iron ore, and the rule keeps every other trader from taking the rest.
  In the any-place run the village bought none of the carried ore until day 90 (it held 61-110 of its own) and 29 from
  day 90 to 120, when its own was running down: the gain arrives when the village needs it.
  The owner's answer says "any neighbour trader may carry another settlement's real ore": the traderless-only limit is
  narrower than that wording.

## 3. Recommendations (not applied: policy values need the owner)

1. **Keep `consign_hold_days` at 12.** No evidence it blocks trade or causes shortage.
2. **Owner decision: relax "only from traderless places"** to the owner's wording: any neighbour trader may collect a
   place's spare ore above what that place's own trader is carrying (its own trader keeps first claim, up to its carry room).
   Evidence: 11 -> 29 iron ore imported in seed 1, conservation intact. Confirm with seeds 2-4 before shipping.
3. **Owner question, larger effect: the founding trader's 0.85 reserve.** Every founding trader in seed 1 closed by day 34
   because it could not pay its households while holding 200-350 coins; without traders no ore moves at all, whatever the
   consignment rules. Options: (a) keep (traders fail and reopen by the X20 rules; WDR-022 outcome); (b) use the trader type's
   reserve (80) for founding traders too, as reopened ones already do; (c) a lower share. Recommendation: (b), one rule for
   founding and reopened traders, after a seeds 1-4 comparison.
4. Minor gap, for the record: ore in a place's treasury granary (left by a closed quarry or trader) is never collected on
   consignment; only businesses' stock is. Raise with recommendation 2 if the owner wants granary ore carried.

## 4. Treasury ore recovery (B25-ECON-P7, owner decision 2026-11-05)

Owner directive `docs/directives/2026-11-05_b25r1_treasury_ore_recovery.md` (approved; implements recommendation 4 above).
Branch `wip/b25r1-econ6`.

### 4.1 Investigation: how treasury ore is stored, owned, reserved and accounted

- **Storage and ownership.** A settlement's treasury is `OffMapSettlement.gov` (`coins`, `granary{item: n}`). Ore enters the
  granary only by closure and by consignment returns: `_close_business` (a closing quarry's or smith's stock is first bought by
  the place's trader at market price as far as its till above its reserve reaches, the rest to the granary; a closing
  trader's whole stock goes to the granary), `_consign_return` and `SettlementTrips.consign_errand` "give" (goods returned to a
  source that has closed meanwhile). The granary's goods are the treasury's own; another place's goods a closed trader was
  carrying are also physically in the granary but marked in `gov.consign` (`consigned_in(gov, item)`, B25-ECON-P6) and owed home.
- **Accounting.** The granary counts in `OffMapSettlement.goods()` (so the settlement's audit and `Regions.audit` cover it);
  every cross-place hand-over is a matched regional line pair (`SettlementParty.deal`).
- **Reserves.** The treasury party's sale cap (`SettlementParty._sale_cap`, "treasury") keeps three days of the households'
  food and six of its upkeep goods (planks, blocks), less another place's consigned goods; it has no rule for ore.
- **Why the ore was stranded.** Nothing reads granary ore: the local market offers only businesses' and crafters' stock
  (`_open_offers`), so neither the place's smith nor its trader (`_trader_collects`) can buy it; the own trader's consignment
  (`consign_out`) and the neighbours' collection (`Regions.consign_round`, `consign_errand`) look only at businesses' stock above
  their keep. The regional food round sells treasury goods but only food.

### 4.2 Integration point (no new mechanism)

The treasury becomes **one more consignment source**, key `"treasury"` (a place's own) or `"<place>/treasury"` (another place's),
in the two existing consignment paths, after that place's businesses:

- own trader, `OffMapSettlement.consign_out` (on a caravan visit), up to its carry room: first claim (B25-ECON-P4);
- neighbour traders, `Regions.consign_round` (the spare scan) and `SettlementTrips.consign_errand` (the walker's collection), by
  whatever rule decides who may collect (B25-ECON-P6; owner decision 32 widens it).

Everything else is the existing code, unchanged: the units stay the treasury's until the village buys them; `_consign_sold`
pays `trader_pays_share` of the price to `gov.coins` (a key with no business of that name is the treasury's, the closed-source
rule) or sets it aside for another place's treasury and a walker pays it there (`_consign_source` -> treasury); unsold goods
go back next morning (`_consign_return`, to the granary) or after `consign_hold_days` = 12 by walker. No free transfer, no new
pricing, no new store, no change to closures.

**Protection** (`OffMapSettlement.granary_spare(item)`): only goods of `rules.consign` (iron ore, coal, copper ore, tin ore),
never food or upkeep goods; the granary keeps (a) another place's goods it holds to send home (`consigned_in(gov)`), and (b) the
working stock that this place's open businesses and crafters keep of that good for their recipes (`_keep`: `input_days_ahead`
days of their recipes' use, e.g. Garton's smith 12 iron ore). A closed smith keeps nothing.

**Known limit (not changed):** the protected stock is kept but the local smith still cannot buy from the granary (the local
market offers businesses' stock only); letting it buy would change the local market and is outside this decision.

**Diagnostics:** `OffMapSettlement.granary_ore` {out, sold} (not saved, never read by the rules) and the economy_sim mining
report's `region.<place>.granary` / `granary_ore`.

Tests: `game/tests/treasury_ore_test.gd`; `game/tests/consign_test.gd` (its collection counts now include the closed trader's
ore in Garton's granary, which the fixture leaves there).

### 4.3 Results (120 days, seeds 1-4, every 10)

Run 42109041416 on `a583318` (treasury recovery on top of decisions 32 and 33) against the decision 32/33 baseline run
42106105599 on `7c2bef2`. Conservation: currency leak 0, item leaks none, script errors 0 in all eight runs.

| Seed | Treasury iron ore sold to village (coal) | Iron ore imported, base -> new | Iron bars made | Tools made | Starvation | Traders open d120 |
|---|---|---|---|---|---|---|
| 1 | 38 (28) | 255 -> 212 | 583 -> 547 | 69 -> 69 | 0 -> 0 | 0 -> 0 |
| 2 | 155 (81) | 60 -> 225 | 349 -> 469 | 31 -> 39 | 4 -> 4 | 1 -> 2 |
| 3 | 144 (67) | 8 -> 154 | 405 -> 501 | 40 -> 40 | 0 -> 0 | 2 -> 1 |
| 4 | 110 (53) | 18 -> 138 | 417 -> 475 | 40 -> 41 | 0 -> 0 | 2 -> 2 |

- Improvement: in seeds 2-4 the ore that closures left in Garton's granary became the village's main iron import
  (imports 86 -> 517 across those seeds; iron bars +274).
- Not attributable either way: seed 1 is ahead to day 90 (148 against 141 imported) and behind by day 110-120 (212 against 255).
  The village diverges from day 50, every trader has closed by day 120 in both runs, and Garton's granary still holds 118 iron ore with
  no carrier (no walker, no carrying: WDR-022). Village population differs by births and wildlife deaths, not by starvation.
- Unchanged: trader closures and reopenings follow the same pattern (traders open per checkpoint within one of the baseline),
  starvation deaths are the same, and the fingerprints are identical to the baseline until the first closure leaves ore in a granary (days 40-70).
- Left over: ore stays in Garton's granary at day 120 in seeds 1 and 4 (118 and 179 iron ore); "out" counts in the report are
  gross (the same units lent on each visit and returned the next morning).
