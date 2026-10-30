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

## 2. Priority 2 (in progress)

Household budgets and food bids, production response without tool-order traps, negotiated wages and services behind their switch
(OD-LE-03 D02), job choice behind its existing gate. Recorded here as it lands.

## 3. Known limits and notes for the lead

- Outflows nobody can refuse (tax, rent, eating, crafting, theft, death, a till float) still reduce an actor's holdings below its
  offers; such offers are cut at the next validation or dawn and can never fill meanwhile. Crafting does not yet refuse to consume
  contract-earmarked inputs (`EconContractLinks.earmark` has no live caller); production (priority 2) decides it.
- With the economy OFF, `NPCBrain`'s `buy_from` takes `min(wanted, vendor stock)` without subtracting the vendor's contract holds
  (`World.trade` does not check them there). Not changed (G0 must stay identical) and not verified as a live defect; with the
  economy on, `World.trade` refuses such a sale.
- Every claims read is the actor's own held reservations or open offers; `inbound` scans the contract list (bounded by CON-01's
  open and recent contracts). LE-06 profiles it.

## 4. Evidence (CI and G0)

Filled in when the runs finish.
