# Expansion 20, LE-02: implementation note (adaptive bids, asks, negotiation and settlement)

Register LE-02 (gate "Ledger-safe multi-actor trades"; branch `wip/x20-le02`, base `5c303be`). Authority: owner directives
2026-10-27 `docs/directives/2026-10-27_complete_expansion20_first.md` (s.3 LE-02) and
`docs/directives/2026-10-27_x20_scope_and_free_migration.md` (X20-SCOPE); design
`docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.txt` s.3-5, 9, 13, 14, 16, 19. Builds on LE-01
(`LE01_IMPLEMENTATION.md`, `LE01_DATA_CONTRACTS.md`). Developer reference only: everything is behind
`game/data/economy.json` `"enabled": false`, nothing is playable, so no wiki page changes (WIKI-01: describe only what has
landed and can be played).

## 1. Owner policies implemented, and nothing else

| Decision | Owner answer (register) | Where |
|---|---|---|
| OD-LE-02 | Combined market pricing: supply, demand, scarcity and completed transactions inform asking prices; buyers and sellers negotiate actual deals with limited counteroffers, individual willingness to compromise, influence from urgency, alternatives, experience and personality; no guaranteed transaction | `EconMarket.ask_price`, `seller_floor`, `buyer_ceiling`, `negotiate`, `concession` |
| OD-LE-02B (D01, current) | Offers local to real encounters, stalls and direct dialogue; gossip carries what a villager genuinely learned; no universal offer board; NPC-limited information | `EconOffers.VISIBILITY`; `EconKnowledge` source `in_person`; `EconMarket.on_encounter`, `dialogues` |
| OD-LE-10 (D09, current) | Price knowledge from observation, direct offers and existing gossip with source, age and trust; may be wrong or stale; the integrated gossip and judgment plumbing; no separate rumour engine, no omniscient market | `EconKnowledge` source `word_of_mouth`, `reliability`; `JudgmentStore._meet_now` -> `EconMarket.on_meeting` |
| OD-LE-03 (D02, authorized by X20-SCOPE) | Existing wage and hiring rules intact; contracts may negotiate explicit item, quantity and unit price | `EconMarket.procure` through `Contracts.propose` (CON-01, any tradable product). Wages and services untouched (LE-03) |
| OD-LE-13 | Context-sensitive renegotiation: partial delivery, extensions, changed payment terms or cancellation; no automatic penalty | `EconMarket.renegotiate`, `Contracts.amend`, `Contracts.cancel` |
| Opinion rule 2026-10-26 | Opinion one weighed factor; refusal valid; no hard cutoff; no rule that every trade stays possible | `JudgmentWeighting.choose` with `market_buy` / `market_sell` (judgment.json) |

## 2. The five prices, kept apart (design s.5)

| Price | What it is | Record |
|---|---|---|
| Reference (believed) | what one actor's own knowledge says the item goes for: the reliability-weighted mean of the prices it knows others deal at, else the item's value | computed, `EconMarket.believed` |
| Advertised bid | an open `bid` offer (coins reserved for its remaining units at its price) | `EconOffers` |
| Advertised ask | an open `ask` offer (goods reserved) | `EconOffers` |
| Negotiated | the round-by-round quotes and the agreed price | `negotiate` result `quotes`, `price_each`; both parties learn the last quotes (`in_person`) |
| Settled | a completed `World.trade`, then a deal record | `EconMarket.deals` (bounded `keep_deals`); `EconEvents` "trade" |

All limits stay inside the existing band `GameData.value(item) x [price_min, price_max]` (balance.json 0.6, 1.8).

**Buyer's ceiling** (expected benefit, urgency, alternatives, contract obligations): a contract-bound seller buying the goods
it owes pays at most the contract's own price; a trade's missing tool, the band's top; an input or a housing material, between
the value and the band's top by urgency (shortfall over target; housing `housing_urgency`); `alternatives_discount` off when
it knows two or more sellers. Cash is separate (`cash_for`: spendable above the OD-19 reserve, `World.spendable`, net of its
other reservations).

**Seller's floor** (cost, household needs, other bids, stock, opportunity cost): the band's floor or the cheapest recipe it
can make the item by at its inputs' value; at least the best bid it knows elsewhere; CON-01's household factors
(`needy_factor` when at or under its reserve, else `comfortable_factor`); a friend, partner or kin gets the friend's price
(`Relations friend_price`, as CON-01's `price_terms`); `scarcity_floor` more when the sale leaves it under `scarce_left`.

**Ask** (supply, demand, scarcity, completed trades): `World.sell_price_at`'s scarcity rule on its own stock, moved by the
sellers and buyers it knows of, blended with the prices it has seen (`txn_weight`); never under its floor.

## 3. Negotiation and settlement

`negotiate(buyer, seller, item, want, bid, ask, via)`: feasibility first (live adults, the buyer's need, the seller's goods for
sale: not its tools (`NPCBrain.keeps`), not its trade's own materials unless a merchant, not what contracts or other claims
hold; the lot; cash for a lot at the band's floor). Opening quotes: the bid's price or the opening bid; the ask's price or a
quoted ask. Crossing at once: the standing offer's terms are taken. Else up to `max_rounds`: the buyer gives `concession`
of the gap to its ceiling, the seller of the gap to its floor; each person's concession is spread by the shared personality
weighting, raised by urgency, lowered by Trading experience. No crossing is a valid end ("no_agreement"). Then both weigh the
terms in `JudgmentWeighting.choose`: the buyer (`market_buy`: necessity = urgency, price, sole source over known sellers,
disposition) and the seller (`market_sell`: coin need, price, surplus, disposition), each against doing without.

Settlement `_settle`: every check again (stock, coins, room, cash net of reservations and reserve, both offers' remaining),
then `World.trade` (all or nothing), then `record_fill` on the ask and the bid (refuses more than remains), then the deal
record. A guard refuses a settlement inside another. Nothing books unless the trade happened. Every outcome is counted
(`stats`) and failures noted as events.

## 4. Where it runs (event-driven, bounded)

| Entry | Trigger | Bound |
|---|---|---|
| `on_encounter(a, b)` | `Relations.share` (two villagers' shared hour within the meeting radius): offers seen in person; one bargain | two index reads when neither has an offer; one negotiation |
| `on_meeting(a, b)` | `JudgmentStore._meet_now` (the gossip's own meetings, its own timing) | `word_of_mouth_per_meeting` each way; only when `would_tell` |
| `dawn(day)` | `EconomyFoundation.dawn` (after the LE-01 model's dawn) | below |
| `review` | open offers not reviewed for `review_days` | open offers only |
| `post_bids` | the need table, round robin | `posts_per_dawn` actors |
| `post_asks` | `World.npcs`, round robin, local_supply jobs | `ask_sellers_per_dawn` x `ask_items_per_seller` |
| `dialogues` | standing bids a day old or more, not tried today | `dialogues_per_dawn` |
| `renegotiate` | open villager goods contracts due today | the contract list |

Anti-oscillation: offers live `bid_days` / `ask_days`; a price moves at most every `review_days`, by `revise_share` of the gap
to the actor's own limit, at most `max_revisions` times; a bid rises only while its need lasts and only toward its own ceiling
(never a fixed raise until supply appears, design s.19), and falls to the ceiling when the need eases; an ask falls toward its
floor when unsold and rises only toward a bid its poster knows. Nothing summons supply.

## 5. Knowledge (OD-LE-02B, OD-LE-10)

Sources now: `own`, `dealing`, `contract`, `in_person` (meeting a poster; a negotiation's quotes; direct dialogue) and
`word_of_mouth` (the integrated gossip). Refused: `notice` (no offer board) and `rumour` (no separate engine). An entry keeps its
first `source` and adds `latest` (the source of its current price) and `via` (the teller); older news never replaces newer;
hearsay of a day the knower saw for itself does not replace it. Reliability is computed when read, never stored: firsthand 1,
word of mouth the listener's `JudgmentStore.credibility` of the teller (the measure gossip uses), times `0.5^(age /
half_life_days)`. Only firsthand knowledge is retold; hearsay is bounded per villager (`max_hearsay`, the oldest forgotten).
A price can be wrong because it is stale; nothing corrects it but news.

## 6. CON-01 procurement (OD-LE-03 D02) and renegotiation (OD-LE-13)

`procure(bid, buyer, seller)`: the buyer proposes a CON-01 contract for the bid's remaining units at its price per unit with
deadline `contract_days`, for any tradable product (the seller's means: stock, mining, felling, harvest, a recipe, a vendor);
CON-01's own evaluation answers (accept, counter, reject; its seller-side judgment `contract_accept` and least price stand); a
counter is met when it stays inside the buyer's ceiling, lot and cash and the buyer still weighs it worth dealing, up to
`max_rounds` offers. The units are **committed** on the bid (`EconOffers.commit`; a commitment, not a sale). The bid's coin
reservation is lifted only for the offer (CON-01 escrows the coins) and restored when nothing is agreed, so coins are never
both reserved and escrowed. A formal contract agreed at a distance becomes CON-01's "signing" record (Q18-13), also committed.

`renegotiate(day)`: for each open goods contract between two villagers due today with goods owed beyond what the seller
holds: a buyer that no longer needs the goods cancels (`Contracts.cancel`: no fee); else the seller proposes, from CON-01
`means`: an extension (its work can manage the rest within `max_extend_days`), a changed payment (it must buy the goods dearer
than the contract pays; inside the band, the buyer's ceiling and cash), or a partial delivery (quantity = delivered + held, a
day to bring it). The buyer weighs it (`market_buy`); `Contracts.amend` records it (escrow = left x new price, the difference
returned or set aside by `fund_refusal`; history "amend" with the old terms; `paid` stays the sum actually paid). No penalty is
added; an unresolved contract lapses by CON-01's existing rule (its regard loss is CON-01's, unchanged).

## 7. Persistence and the switch

The optional `economy` save key gains `market` (`deals`, `next_deal`, `stats`, `bid_cursor`, `ask_cursor`) when non-empty;
offers gain optional fields (`min_lot`, `committed`, `contracts`, `revisions`, `reviewed_day`, `need`, `seen_filled`,
`dialogue_day`), knowledge entries `latest` and `via`. An LE-01 section loads with defaults (tested); switched off the section
is carried untouched (D2, tested). No `SAVE_VERSION` change.

With `enabled` false (shipped) the World builds nothing: the two new live calls (`Relations.share`, `JudgmentStore._meet_now`)
are guarded by `economy != null`; `Contracts.amend` is called by nothing else. With `enabled` true and `market.drive` false
(or absent, as in LE-01's tests) the market does nothing (tested: a stepped day identical to the switch off). The shipped file
says `drive: true`, so switching the economy on starts the market: that activation is the owner's decision.

Determinism: sorted iteration everywhere, ids counting up, round-robin cursors saved, no `World.rng`; personal choices use the
shared engine's seeded hashes (SJD-Q09 near-best, SJD-Q03/Q13 personality). Tested: the same operations twice give identical
records; a full driven day twice gives byte-identical saves.

## 8. Verification (2026-10-28)

| Check | Result |
|---|---|
| `le02_market_test.gd` | 101 checks, 0 failures |
| `economy_model_test.gd` | 112 checks, 0 failures (the LE-01 refused-source checks rewritten for the decided sources; reliability now decays) |
| `economy_foundation_test`, `till_ownership_test`, `contracts_test`, `contract_sign_test` | 89, 50, 154, 21 checks; 0 failures |
| `judgment_test`, `judgment_live_test`, `relations_test`, `recorder_test` | 217, 161, 80, 214 checks; 0 failures |
| `run_tests`, `start_test`, `world_test`, `multiplayer_c_test` | 3600 checks, 523 steps, 339, 340 checks; 0 failures |
| G0, switch off (seeds 1 and 2, 30 days, checks 10 and 30) | identical to the accepted baseline 6ee13c7 (recorded from 5c303be): day-30 fingerprints c24e8660... and 45fd9acb...; leaks currency 0, items none. Against the older baseline d4686cd: day 10 identical, day 30 differs exactly as 5c303be itself does (free migration, REG-X20-D1) |

`game/tests/le02_market_test.gd` covers: prices and the band; three actor
types (a smith's input, a raw-goods merchant's stock, a woodcutter's contract obligation) answering the same plank shortage
through actual trades, conserved, one bid left part filled; negative paths (no funds, no stock, a tool not for sale, no need,
expiry, no agreement after the limited rounds); opinion weighed (the same dislike splits buyers of moderate need by personality,
great need outweighs it, without the dislike more deal); partial fills, no duplicate fill, atomic guard; adaptive review
(bids rise to and never past the ceiling, at most `max_revisions`; withdrawn when the need is met; asks fall to and never under
the floor; cut when goods go); local knowledge and word of mouth (no board, in person, heard with age and the teller's trust,
not retold, the gossip's own rule, bounded); CON-01 procurement of a crafted good with a counter; renegotiation (extension,
partial delivery, cancellation, changed payment, refusal); the dawn driver and its bounds; determinism; save and load mid-way,
an LE-01 save, D2; the switch.

## 9. What LE-02 does not do (for LE-03 and later)

- **Food** posts no bids: household food buying stays with the existing rule (`Credit._cheapest_food`, OD-19) until LE-03's
  household budgets weigh food against other needs.
- **Two buying channels coexist** when switched on: the brain's own purchases (`NPCBrain` sellers, `Contracts.npc_orders`)
  still run and do not read reservations, so an ask's goods or a bid's coins can go by them; the market reports it
  (`EconReservations.unbacked`, `EconOffers.backed`) and its review cuts or withdraws the offer. LE-03 should route production
  and household purchases through the market's decisions, or make the brain read reservations, as one channel.
- **No travel cost** in pricing: direct dialogue happens at dawn without walking (the goods then travel by CON-01 delivery).
  Distance, route and risk (design s.5 "travel and risk") are for LE-05's regional links.
- **The player** gets no derived bids and no market journal (OD-LE-14, brought forward by X20-SCOPE: a personal journal of
  offers the player actually learned, LE-05 or later, aligned with the Messages journal).
- **Negotiated wages and services** (OD-LE-03's broader part), business identity and accounts (OD-LE-04/07), speculation and
  hoarding (OD-LE-11), rental and repair (OD-LE-08), contracts through the estate (OD-LE-13B): LE-03 to LE-05.
- **Calibration**: every number in `economy.json` `market`/`knowledge` and the two judgment profiles is a provisional agent
  value (docs/DECISIONS.md 2026-10-28); LE-06's long runs should measure deals, refusals, revisions and save size before the
  owner considers activation.
