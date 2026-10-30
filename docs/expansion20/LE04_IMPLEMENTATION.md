# Expansion 20, LE-04: implementation note and handoff (organic finance, merchants and manor behaviour)

Register LE-04 (gate "Costs, default and refusal paths"; branch `wip/x20-le04`, from LE-03's frozen `8fff5ce`). Authority: owner
directive 2026-10-30 (X20-RESUME s.4), the lead's LE-04 brief (2026-10-30), design s.10, s.12, s.17; owner answers OD-LE-03 (D02),
OD-LE-04 (D03), OD-LE-07 (D06), OD-LE-11 (D10), OD-LE-13B (D12). Excluded: lending, interest, manor emergency loans (OD-LE-05B,
OD-LE-06). Everything new is behind `game/data/economy.json` `"enabled": false` (and `market.drive`); developer reference only.
Every integration goes through the transaction authority (`docs/expansion20/TRANSACTION_AUTHORITY.md`).

## Status (keep current)

| Part | State | Where |
|---|---|---|
| Build 24 review items 6 and 7 (till handover, stall commission record) | done `3073b95` | `business_money.gd::keep_till`, `stalls.gd::settle`; `till_ownership_test` |
| 1a Village parties of the authority (manor, households, chapel, tills) | done `74b99de` | `econ_transactions.gd`; INT-607; `le04_test` |
| 1b The manor's tools through the economy (buy via the authority, else CON-01 commission) | done `74b99de` | `econ_market.gd::manor_tools`; INT-608 |
| 1 Business identity and separate accounts (recorded contributions and distributions; one owner per business) | done (see commit log) | section 1; `le04_test::test_business_accounts` |
| 2 Contract estate claims on death (OD-LE-13B) | done (no migration needed) | section 2; `le04_test::test_estate_claims` |
| 3 Speculation and stockpiling (OD-LE-11) | done | section 3; `le04_test::test_speculation` |
| 4 Negotiated wages and services behind off flags (OD-LE-03 D02) | wages done (off); services not built (reason in s.4) | section 4; `le04_test::test_negotiated_wages` |
| Milestone evidence: one G0 (seeds 1,2, 30 days) + one `--market` run | not run | the G0 may differ only by items 6 and 7 |

Rules for whoever continues: the switch stays off; G0 identical except the item 6/7 fixes (report differences with conservation
evidence); no unbounded saved state (the economy's save size is an activation blocker, LE-06); a migration that is not purely an
added optional key is stopped and reported to the lead; Actions only at the milestone; tests failing first, then the fix.

## 1. Business identity and separate accounts (OD-LE-04 D03, OD-LE-07 D06)

Owner answers: "One owner per business initially, ownership recorded separately from household money and estate inheritance";
"Business tills, stock and obligations are separate from household holdings (ECON-P3). Owners can make explicit recorded
contributions, legitimate profit distributions or estate transfers; no silent pooling." A business is its till (`stall:`, `shop:`,
`front:`, `counter:`) and its one owner is the till's controller (`EconActor.controller`, the ECON-P3 / B18-DP-01 rule). With the
economy on, every move between a till and its owner's purse (necessity draw, owner pay, float top-up, the player's own till moves)
is a recorded coin transfer through the authority (`EconTransactions.transfer_coins`), journalled with its purpose
(`coins:necessity`, `coins:owner_pay`, `coins:topup`, `coins:kept`, `coins:contribution`, `coins:distribution`); such a move is
neither earned nor spent; coins an offer holds back cannot be contributed (claims). No new saved record: ownership stays the
existing owner/tenant records and the controller rule (one owner per till). Economy off, or on with the market not driving:
`BusinessMoney._move` exactly as before.

## 2. Contract estate claims (OD-LE-13B D12)

Owner answer: "Death of a contract party can create estate claims up to real estate assets; heirs bear no automatic liability from
separate personal funds. Current contract-death and lapse handling stays until the authorized contract and estate stage with
migrations. No invented penalties."

**Where a claim can arise.** CON-01 escrows the buyer's coins when a contract opens and pays per unit on delivery; on a party's death
`Contracts.on_death` cancels its contracts and returns the unpaid escrow to the buyer, so a CON-01 contract leaves nobody owed. The
only coins paid ahead of delivery in the game are the manor's advances (`World.manor_orders`: EQ-19 tools, MIN-EQUIP supplies).

**Rule (economy on, market driving).** At the death (`Contracts._estate_claims`, before the dead's coins pass to the heir or lie as
loot): an order whose good the dead already made is completed from its stock (to the worker, else the works yard); otherwise the
advance is paid back to the treasury from the dead's own coins, never more than it holds, through
`EconTransactions.estate_claim` (journalled `estate:manor_order`), and the rest is written off. The order ends. Heirs' own purses
are untouched; no penalty is added. With the switch off: the existing lapse rule, unchanged.

**Save migration plan: none needed.** The claim is settled at the moment of death and nothing is persisted (no new key, no changed
key, no `SAVE_VERSION` change). An older save's open advances are simply settled by this rule if their smith dies with the economy on.

## 3. Speculation and stockpiling (OD-LE-11 D10)

Owner answer: "Villager speculation and hoarding is an approved direction once adaptive prices, resource accounting and storage
exist. Nothing manipulates supply by fiat; scarcity, inventory, consequences and finite purses govern." `EconMarket.speculate`
(market dawn, after the bids from needs; `market.speculation`): up to `spec_per_dawn` merchants (round robin, a saved cursor) each
weigh the goods their trade stocks; one that KNOWS (its own reliable knowledge) of an ask at least `spec_margin` under the resale it
expects (the best bid it knows, else its believed price) bids for it (need kind `stock`): up to its stock caps (`NPCBrain.wants`:
storage and its trade's limits) and `spec_share` of its spendable coins (never food or obligations: the budget's discretionary
part). It resells by its usual asks (LE-02), which can fail: a speculation can lose. Withdrawn at review when the opportunity is
gone. Nothing created; no new unbounded state (one cursor). Provisional numbers in `economy.json` (`spec_*`).

## 4. Negotiated wages and services (OD-LE-03 D02, broader part), behind off flags

`market.negotiated_wages` (shipped false): a manor job's wage, still fixed when taken (X18-D6), is bargained once by
`EconMarket.wage_bargain`: the existing skill-adjusted wage is the floor; a worker comfortable in coins (1 - `JudgmentLive.coin_need`)
asks up to `wage_max_factor` (1.25, provisional) of it; a needy worker takes the existing wage; the treasury check uses the agreed
wage. No universal wage; posted bases unchanged. `market.services` (shipped false) is reserved but nothing is behind it yet: CON-02
services (dig, survey) are already priced per unit through CON-01's counteroffers, and no villager has a service demand to
negotiate; construction labour (LE-05) is the natural first one. Recorded as remaining, not invented.

## 5. Milestone evidence

See the report; one G0 (seeds 1,2, 30 days) and one `--market` run at the LE-04 head.
