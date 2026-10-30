# Expansion 20, LE-03: implementation note (one transaction path; production, budgets, wages and services)

Register LE-03 (gate "No tool-order traps; real opportunity response"; branch `wip/x20-le03`, base `4611d86` = Build 24).
Authority: owner directive 2026-10-30 `docs/directives/2026-10-30_master_development_resumption.md` (X20-RESUME s.3-5, 10),
X20-SCOPE (`docs/directives/2026-10-27_x20_scope_and_free_migration.md`), design
`docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.txt` s.4-8, 16, 17, 19; owner answers OD-LE-03 (D02),
OD-LE-04 (D03), OD-LE-07 (D06), OD-LE-08 (D07), OD-LE-11 (D10), OD-LE-13B (D12), OD-LE-14 (D13); opinion rule 2026-10-26.
Builds on LE-02 (`LE02_IMPLEMENTATION.md` s.9 "for LE-03"). Developer reference only: everything is behind
`game/data/economy.json` `"enabled": false`; nothing is playable, so no wiki page changes (WIKI-01).

## 1. Priority 1: one authoritative transaction path (done)

LE-02 left two buying channels: the brain's own purchases and `Contracts.npc_orders` did not read reservations, so goods behind an
ask or coins behind a bid could leave by them, and the market only reported it. LE-03 makes `World.trade` the one validated
transaction for village actors and puts the same validation in front of every other village path that moves goods for coins.

### 1.1 Claims (`game/scripts/core/economy/econ_claims.gd`)

A **claim** is a hold on an actor's own coins or goods that another use must not silently consume:

| Claim | Where it lives | Yields to |
|---|---|---|
| Goods owed on an open CON-01 contract | `Contracts.held_for_ref` (the live authority, RECON-01) | nothing: the transfer is refused |
| An ask's goods (`offer:<id>`) | `EconReservations` | any sale of those goods by its poster (a sale answers the ask) |
| A bid's coins (`offer:<id>`) | `EconReservations` | a purchase by its poster of the same item, or of a household necessity (food, firewood, medicine: `World.is_necessity`) |
| Any other reservation (an earmark) | `EconReservations` | nothing |

`EconClaims` keeps no ledger: holdings are read through `EconActor` from the existing owners, claims from the two records above.
The only record it changes is the offer, and only by cutting the actor's own offer (`EconOffers.resize`, or `withdraw` under its
lot), newest first, recorded as an event and counted in `stats` (saved under the optional `economy.claims` key).

| Function | What it does |
|---|---|
| `plan(ref, item, qty, for_item, necessity, exempt)` | Pure. Whether `ref` may part with `qty` of `item` ("coins") and which of its own offers must yield, by how many units |
| `apply(cuts)` | Cuts those offers |
| `check_trade(buyer, seller, id, qty, total, exempt)` | Both parties of a sale: stale offers reconciled first, then `plan` for the seller's goods and the buyer's coins |
| `reconcile(ref, item)` / `reconcile_all()` | Cuts own offers until every claim on `item` is backed by what is held (dawn: every owner with held reservations) |
| `free_units(ref, item, for_item, necessity)` | What an actor may spend or sell for this purpose (`World.claims_free_coins`) |
| `inbound(ref, item)` | Units still coming to `ref` on accepted or signing contracts |
| `audit()` | Every breach now: negative coins or goods, an open priced offer whose reservation is not exactly what remains, an overfilled offer, unbacked reservations |

### 1.2 Validate, then commit

`World.trade(buyer, seller, id, qty, price_each, total_price := -1, exempt := [])`:
1. the existing checks (quantity, price, purse, stock, room);
2. economy on: `EconClaims.check_trade` (the reservations of the offers a market settlement is filling are `exempt`: they back
   this very sale; `EconMarket._settle` passes them);
3. refused: nothing has changed (the recorder notes the refusal as before);
4. accepted: the yielding offers are cut, then the goods and coins move, then the existing hooks run.

Nothing after step 3 can fail, so no partial transfer is possible. After a fill, `EconOffers._rebook` re-reserves what remains;
when the actor can no longer back it (a negotiated price above the bid's own, an outflow), the offer is cut to what it can back or
withdrawn: an open offer is never left without a reservation (LE-02 left it at `reservation = -1`).

### 1.3 The paths outside World.trade

`World.claims_allow` (pure) and `World.claims_release` (commit) are called before the coins or goods move:

| Path | Party checked |
|---|---|
| `Business.sell` (a villager at a premises' counter) | buyer's coins (for the item; necessity when bought for the pantry or a necessity) |
| Caravan imports in `npc_brain.gd` (smith's stock, sage's medicine, merchant's seed, household food, food businesses, stone) and `luxury.gd` | buyer's coins |
| The manor's purchases (repairs, granary, public works, tools, relief) and `mine_supply.gd` | seller's goods |
| Caravan exports | seller's goods |
| `Contracts.fund_refusal` (every escrow with a villager buyer) | free coins above the OD-19 reserve |
| `Contracts._open` | the seller's asks over goods now held, the buyer's bids over coins now in escrow, cut at once |
| `World.can_afford`, `World.purchase_qty` (every brain purchase decision) | the coins no claim holds back for this purpose |

The caravan and courier paths themselves stay as they are (parallel-work contract 1); only the village buyer's or seller's claim
rule is added, and only with the economy on.

### 1.4 No duplicate purchase

- A business with an open market bid for an input does not also order it by `npc_orders` (one channel per need).
- While the market drives, `NPCBrain.wants` is net of units coming on contracts, and the market's needs (`open_need`, used by
  `need_for` and `post_bids`) likewise: a bid that became a CON-01 contract is not posted again the next dawn, and the routine
  purchase does not double an order. (Found in LE-02's driven market: a fully committed bid finished as "filled" while the need,
  derived from the inventory, persisted until delivery, so a new bid was posted and procured.)

### 1.5 The switch

Every new entry point returns at once while `World.economy` is null; `NPCBrain.wants` changes only while `market.drive` is true.
Economy off: no new record, no new save key, no RNG draw, so the shipped game is unchanged (G0 below). Economy on with the market
not driving: no offers exist, so no claim yields and nothing differs (LE-02's `test_switch` day comparison passes).

### 1.6 Verification (2026-10-30, head `bfde588`)

| Check | Result |
|---|---|
| `le03_claims_test.gd` (new) | 79 checks, 0 failures |
| `le02_market_test.gd` | 101 checks, 0 failures |
| `economy_model_test.gd`, `economy_foundation_test.gd` | 112, 89 checks; 0 failures (two LE-01 checks rewritten: see below) |
| `contracts_test`, `contract_sign_test`, `till_ownership_test`, `conservation_test` | 154, 21, 54, 8 checks; 0 failures |
| Full CI suite (`tests.yml` on the branch) | see section 4 |
| G0, switch off (seeds 1 and 2, 30 days, checkpoints 10 and 30) | see section 4 |

Rewritten checks (the behaviour LE-03 removes): `economy_model_test` "a live trade of 3" now names the ask it fills (`exempt`), as
the market's settlement does; `economy_foundation_test.test_unbacked` now asserts that a trade cannot take reserved goods and
exercises `unbacked()` through an outflow nobody refuses.

`le03_claims_test.gd` covers: an ask against a routine sale (free goods first, then the ask yields, withdrawn when its goods are
gone); a bid against a routine purchase (an unrelated purchase refused, the same item and a necessity allowed, the bid cut);
contract holds bind (trade, the non-trade paths, a new ask); competing claims on the same goods in one tick (a routine purchase
and two settlements on one ask: one fill, the loser untouched); the same coins in one tick; stale offers (no fill beyond what is
held; reconciled at dawn; a bid with nothing behind it withdrawn); rollback (a refusal at the seller, at the buyer, and on a
non-trade path leaves every holding and record byte-identical); rebook to backing; escrow and npc_orders; inbound contracts;
`Business.sell`; save and load mid-reservation (a competing purchase after load ends exactly as without the save);
determinism (byte-identical saves); the switch.

## 2. Priority 2: budgets, food bids, production (done except wages and services)

All of it acts only while the economy is on and `market.drive` is true.

### 2.1 Household budgets (`EconMarket.budget_for`)

Design s.4 "Evaluate competing uses of money and time" and s.8. A villager's coins go first to the obligations and necessities it
answers for, `COMMITTED`: its household's food (when it is the household's payer), goods it owes on a contract, its trade's tool.
They are served in order of each need's own urgency (`buyer_ceiling`: food's missing days over the horizon, a contract's
nearness to its deadline, a tool 1.0); `BUDGET_ORDER` breaks ties only, so there is no fixed rank. Each takes at most its open
quantity at its own ceiling. Food draws on the whole purse net of other reservations (OD-19: necessities from any coins); the
others on coins above the OD-19 reserve (`cash_for`). A discretionary need (a trade input, a housing material) gets what is left
after them, never more than its own cost. Stock targets (SHOP-01 `wants`) are not obligations: a strictly sequential version let
them, far larger than any purse, starve every bid, and was rejected. `post_bid` sizes a bid and `review` keeps or raises it within
this budget, so a bid never holds coins the household's food or an obligation needs first. Purses are never pooled.

### 2.2 Food bids

`food` joins `BID_KINDS`. A household's food need (LE-01: `hh.econ.days` under `reserve_days`) is bid by its payer
(`food_payer`: the adult with the most coins, lowest id on a tie) for the purchasable food it believes cheapest per food point
(`food_item`, its own knowledge), in units for the missing days (`food_units`). One food bid per household (another food item does
not open a second). The bid settles like any other (INT-580, INT-600): sellers met in person, direct dialogue, CON-01. The
existing household food routines (`buy_food`, OD-19) still run; both go through `World.trade`, and a food purchase may draw on a
bid's coins only by cutting the bid (INT-600), so nothing is spent twice. A household that cannot pay goes without (WDR-022).

### 2.3 Production honours accepted contracts; no tool-order trap

- **Earmarks** (design s.6): when a CON-01 goods contract the seller will craft opens (route "craft"), the inputs it holds for
  the units still owed are earmarked (`EconContractLinks.earmark`, first live caller), in its own pack. They cannot be sold
  (INT-600) or worked into another product (`EconClaims.craft_ok`: `NPCBrain._do_recipe` does not plan such a recipe,
  `World.work_craft` refuses it). The contract's own recipe uses them and the earmark shrinks with the use (`after_craft`). It
  ends with the contract, whatever ends it (deadline lapse, renegotiation, cancellation): the dawn sweep releases it. What the
  seller lacks it must still buy; nothing is created.
- **Tool orders**: while the market drives, a worker waiting on the manor's tool order (EQ-19) keeps its tool need, so it may
  bid for the tool and buy it from whoever sells; the forged tool then goes to the next worker short of one, or waits at the
  forge (EQ-19 unchanged). A manor order that cannot be met lapses by its own rule (`manor_order_days`).
- **Opportunity response**: higher bids reach whoever knows of them (encounters, word of mouth, direct dialogue: LE-02), and
  anyone with the tool, skill and source may take a CON-01 contract (`Contracts.means`, unchanged); a toolless worker is no
  longer stuck behind an order. Job choice (changing trade) stays behind its own existing gate (`job_choice`, off), untouched.

### 2.4 Not built in LE-03: negotiated wages and services (OD-LE-03 D02, broader part)

The owner's answer: "Existing wage and hiring rules remain intact ... Broader negotiated wages and services are layered into LE-03
behind flags; do not replace functioning pay or invent universal wages." The villagers have no demand for a service or a hire
that the market could negotiate today: CON-02 services (dig, survey) are ordered by the player and the manor, guard and reeve
wages are the manor's, attendants' wages the player's. Every one of those payers is LE-04's (the manor as an economic actor,
business identity OD-LE-04/D03, accounts OD-LE-07/D06). Building a flag with nothing behind it would be a stub, and inventing a
villager hiring demand would be a new mechanic. Proposed: layer negotiated wages and service prices onto the manor's hiring and
the business accounts in LE-04, behind `market.negotiated_wages` and `market.services` (both off), with CON-01's existing
counteroffer rounds as the negotiation. Recorded for the lead (not an owner question unless the lead decides otherwise).

### 2.5 Verification (head `81620f0`)

| Check | Result |
|---|---|
| `le03_economy_test.gd` (new) | 38 checks, 0 failures |
| `le03_claims_test.gd` | 80 checks, 0 failures (a check added for the `_open` fix below) |
| `le02_market_test`, `economy_model_test`, `economy_foundation_test`, `contracts_test` | 101, 112, 89, 154 checks; 0 failures |

Defect found and fixed: `Contracts._open` ran the LE-03 hook before the new contract was in the contract list, so the seller's
asks were not cut at once and no earmark could be made (`EconContractLinks.earmark` looks the contract up). Economy on only.

## 3. Known limits and notes for the lead

- Outflows nobody can refuse (tax, rent, eating, crafting, theft, death, a till float) still reduce an actor's holdings below its
  offers; such offers are cut at the next validation or dawn and can never fill meanwhile. Crafting does not yet refuse to consume
  contract-earmarked inputs (`EconContractLinks.earmark` has no live caller); production (priority 2) decides it.
- With the economy OFF, `NPCBrain`'s `buy_from` takes `min(wanted, vendor stock)` without subtracting the vendor's contract holds
  (`World.trade` does not check them there). Not changed (G0 must stay identical) and not verified as a live defect; with the
  economy on, `World.trade` refuses such a sale.
- `economy_sim --economy` only ever attached the LE-01 observer (its override `{"enabled": true}` leaves `market.drive` absent),
  so no economy-on Actions run before LE-03 exercised the market. `--market` (added; allowed in `long-sims.yml`) runs the shipped
  `economy.json` switched on, prints the market's and the claims' counters and fails on an integrity breach. Smoke, seed 1, 2
  days, head `81620f0`+: coins 3009 -> 3057 with leak 0 (+48 accounted external flow), item leaks none, 5 deals, 34 bids and 20
  asks posted, 63 bids unaffordable within budget, 23 offers cut by a yield, 1 input earmark, 0 breaches, 1 earmark left unbacked
  by an outflow nobody refuses (reported). The economy save section was 540 KB after 2 days (knowledge 1915 entries, mostly word
  of mouth): LE-06 must measure and bound it.
- Every claims read is the actor's own held reservations or open offers; `inbound` scans the contract list (bounded by CON-01's
  open and recent contracts). LE-06 profiles it.

## 4. The transaction authority (owner directive 2026-10-30, second message)

LE-03 and the settlement food trade converge on one mechanism, owned here: `EconTransactions` (`World.transactions`), contract
in `docs/expansion20/TRANSACTION_AUTHORITY.md`, INT-606. Village-to-village exchanges go through `World.trade`; settlement
parties and village actors exchange or ship through the authority (transit custody, escrow, deliver, fail with refund, lose),
with single-use transaction ids, validation before any change, and the optional save key `transactions` (approved by the lead).
Tests: `le03_transactions_test.gd` 79 checks, 0 failures.

**Tester note:** once settlement shipments run in shipped play, saves carry the `transactions` key; a build without the authority
(Build 24 and earlier) loading such a save drops it, losing open shipments' goods and escrowed coins in that build. Load those
saves with a build that has it.

## 5. Evidence (CI and G0)

| Check | Result |
|---|---|
| Local frozen checkout of the priority 1 commit `7784ed4` (economy off code paths) | `run_tests` 3600 checks, `start_test` 523 steps, `world_test` 339, `multiplayer_c_test` 340, `business_test` 160, `credit_test` 98, `feast_test` 37: 0 failures. `luxury_test` 34 failures, all `fine_cloth` recipe-data checks, pre-existing on `4611d86` (confirmed by the lead; fixed on `wip/expansion20` `ebafdae`, cherry-picked) |
| CI `tests.yml` run 41118607622 (`bfde588`) | failed in the Python step on a CI fault present since 2026-10-22 (the workflow did not fetch the integration branches); game tests skipped. Fix cherry-picked from staging (`5c3221f`); re-run 41123358434 |
| G0, Actions run 41118611434 (`bfde588`, seeds 1 and 2, 30 days, every 10) | see the report (queued behind another branch's run under the old global concurrency group, fixed by `e363703`) |
