# The transaction authority (Expansion 20 LE-03; X20-RESUME s.4, s.6; parallel-work contract 1)

Owner directive 2026-10-30 (second message, via the lead): LE-03 and the settlement food trade converge on ONE authoritative
transaction mechanism. Worker A (Living Economy) owns it; Worker B (X20-SETTLE-FOOD) integrates through it and adds no purchase
path of its own. This page is the interface contract. Status: **defined 2026-10-30; implementation on `wip/x20-le03`**
(`game/scripts/core/economy/econ_transactions.gd`, tests `game/tests/le03_transactions_test.gd`); section 9 says what has landed.

## 1. One authority, two layers under it

| Layer | Path | Who |
|---|---|---|
| Village actors trading face to face | `World.trade` (validate-then-commit with LE-03 claims; INT-600) | villagers, players, guests, the market |
| Any supported party, including settlement parties, at a distance or across settlements | `World.transactions` (`EconTransactions`): `exchange`, `ship` / `deliver` / `fail` / `lose` | settlement food trade, LE-05 regional links, later the caravan |

`EconTransactions.exchange` between two village actors calls `World.trade` itself, so there is still one village path.
`EconTransactions` is built by `World.setup` / `load_dict` **whether or not the Living Economy is switched on** (settlement food
trade is shipped play); claims (reservations, contract holds) are enforced only while the economy is on. With nothing calling it,
it changes nothing and writes no save key (G0 unchanged).

## 2. Parties (refs, as `EconActor` resolves them)

| Ref | Holder of coins | Holder of goods | Supported |
|---|---|---|---|
| `npc:<id>` | `NPC.coins` | `NPC.inv` | yes |
| `player` (host), `player:<line>` (guest) | `PlayerState.coins` | the pack (`PlayerState.inv`) | yes |
| `region:<settlement>/<holder>` (`trader`, a business type, `treasury`, `hh:<n>`) | `SettlementParty.purse()` | `SettlementParty.held()` | yes |
| `manor` (LE-04) | `World.treasury` | the granary (`World.granary`) | yes |
| `hh:<n>` (village household, LE-04) | its head's own purse (`World.party`: the household's first living adult, elder or child) | its pantry | yes; refused when nobody of it is left |
| `chapel` (LE-04) | `Chapel.coins` | `Chapel.store` | yes |
| `stall:<id>`, `shop:<building>`, `front:<building>`, `counter:<building>` (LE-04) | the till | none (a till holds coins only: buying goods is `no_room`, selling `no_stock`) | yes |

Village parties trade with each other inside the village (no boundary crossing); two people (villagers, players) still trade
through `World.trade`. A household's coins are its head's own, paid and received explicitly (the TILL-D1 and stall-payee rule),
never a pooled purse (OD-LE-07 D06). Claims (economy on) apply to villagers and players, and to a household's head when it pays.

A party is **available** when `EconActor.alive(ref)` is true (a living villager, a present player, a live settlement holder).

## 3. Calls

All return a **Result** `{ok: bool, code: String, txid: String, replay: bool, state: String}`.

```gdscript
# Immediate exchange: `qty` of `item` from seller to buyer and `total` coins from buyer to seller, together or not at all.
World.transactions.exchange(txid: String, buyer: String, seller: String, item: String, qty: int, total: int) -> Dictionary

# Shipment, phase 1 (goods will travel): validate both sides, then take the seller's goods into TRANSIT custody and the
# buyer's coins into ESCROW, together or not at all. `due_day`: the last day it is expected to arrive (information for the
# caller's own lapse rule; the authority never acts on time by itself).
World.transactions.ship(txid: String, buyer: String, seller: String, item: String, qty: int, total: int, due_day: int) -> Dictionary

# Phase 2, exactly one of, for an OPEN shipment `txid`:
World.transactions.deliver(txid: String) -> Dictionary        # goods to the buyer, escrow to the seller (the sale completes)
World.transactions.fail(txid: String, why: String) -> Dictionary   # goods back to the seller, escrow back to the buyer (refund)
World.transactions.lose(txid: String, why: String) -> Dictionary   # goods destroyed in transit (a legitimate loss: bandits,
                                                                  # spoilage); the SELLER bears it; escrow back to the buyer

World.transactions.get_shipment(txid) -> Dictionary          # a copy of the record ({} unknown)
World.transactions.open_shipments() -> Array                 # copies, by txid order
World.transactions.overdue(day: int) -> Array                # open shipments whose due_day < day (for the caller's rule)
World.transactions.in_transit() -> {coins: int, goods: {item: n}, village_coins: int, village_goods: {item: n}}
```

## 4. Transaction ids (retry and replay safety)

- `txid` = `"<namespace>:<seq>"`: `namespace` is the caller's own (letters, digits, `_`, `-`, `.`, `/`), `seq` a positive integer
  the caller increments for every new attempt in that namespace (e.g. `settle_food/riverford:41`). Anything else: `bad_id`.
- Per namespace the authority keeps the highest `seq` it has seen. An id **above** it is a new attempt: it is evaluated and its
  outcome recorded. An id **at or below** it is a replay: nothing executes; the stored outcome is returned with `replay: true`
  (the last `keep_outcomes`, default 64, per namespace), or `{ok: false, code: "stale_id"}` when it is older than that.
- So an id executes **at most once**, whatever retries, reloads or replays follow. A rejected attempt is retried under a NEW id.
- Phase-2 calls (`deliver`, `fail`, `lose`) name the shipment's own `txid`; on a shipment no longer open they change nothing and
  return `{ok: true, code: "duplicate", replay: true, state: <its final state>}` when the same outcome is asked again, or
  `{ok: false, code: "not_open", state}` for a different one. A shipment changes state once.
- The namespaces' high marks, the recent outcomes and every open shipment (and the last `keep_finished` closed ones) are saved,
  so a save taken between phase 1 and phase 2, or between a call and its retry, resumes with the same ids and the same holdings.

## 5. Validation (nothing changes on any rejection)

In order; the first failure is the code returned, and **no coin, good or record changes**:

| Code | When |
|---|---|
| `bad_id`, `stale_id` | section 4 |
| `invalid_quantity` | `qty <= 0`, `total < 0`, empty item, item `"coins"` |
| `same_party` | buyer == seller |
| `unknown_party` / `unsupported_party` / `party_unavailable` | section 2 |
| `no_stock` | the seller holds fewer than `qty` (a village actor: in its pack; a settlement party: `held`) |
| `no_funds` | the buyer's purse is under `total` |
| `no_room` | the buyer cannot hold the item (`Inventory.can_add`; `SettlementParty.can_hold`) |
| `claimed` | economy on: the transfer would break a claim (contract holds, reservations: `EconClaims.plan`, INT-600) |
| `not_found`, `not_open` | phase 2 on an unknown or already closed shipment |

The whole check runs before anything moves; a commit that has passed it cannot fail half way (single-threaded game loop; no
await between validation and commit). An interruption (the app suspended, the game closed) falls between calls, never inside one.

## 6. What moves, and who owns what

| Step | Goods | Coins | Ownership |
|---|---|---|---|
| `exchange` | seller -> buyer | buyer -> seller | passes at once |
| `ship` (open) | seller -> TRANSIT (custody) | buyer -> ESCROW | goods stay the **seller's** in transit; coins stay the **buyer's** in escrow |
| `deliver` | TRANSIT -> buyer | ESCROW -> seller | both pass together: the sale completes |
| `fail` | TRANSIT -> seller | ESCROW -> buyer (refund) | nothing passes |
| `lose` | TRANSIT -> destroyed (a sink, `lost_in_transit_<item>`) | ESCROW -> buyer (refund) | the seller bore the risk |

If the party a return or refund goes to is no longer available (a villager died, a household dissolved), the phase-2 call
returns `party_unavailable` and the shipment stays open with its goods and coins where they are, never lost or duplicated; the
caller may `deliver` instead (when the other party is still there) or settle the estate by its own rule later (OD-LE-13B).

Inventory reservation: `ship` takes the goods out of the seller's holdings into custody, so they can be neither sold again nor
used while in transit; the coins likewise. (Face-to-face reservations for offers stay `EconReservations`, INT-600.)

## 7. Ledgers (nothing duplicated, lost or transferred twice)

- **Village actors:** transit and escrow are OUTSIDE the village for its ledgers. Coins leaving a villager or player (paid to a
  settlement, or into escrow) and arriving (from a settlement, or from escrow: a payment or a refund) adjust `World.coin_sources`
  exactly as the caravan does (`-` out, `+` in); goods leaving a village holder (sold to a settlement, or into custody) count as
  `exported_<item>`, goods arriving as `imported_<item>`. So `World.total_coins()` and `economy_sim`'s currency and item ledgers
  balance at every moment without a new holder. `in_transit()` reports the village parts (`village_coins`, `village_goods`) for
  information. A village-to-village exchange is `World.trade` (no boundary crossed); a village-to-village shipment crosses out
  and back in.
- **Settlement parties:** every side is booked through `SettlementParty` (B's books): `deal("sell"/"buy", ...)` for an exchange
  between two settlement parties (regional flow lines that cancel, `Regions.audit`); for a shipment, the goods and coins leaving
  a party into transit or escrow and arriving from it are its `outside_*` lines (`SettlementParty.remove/add/outside_coins`),
  whose other end is `in_transit()`. **For Worker B:** `Regions.audit` (or the regional ledger check) must add
  `World.transactions.in_transit()` (coins, goods minus the village part) as a holder, as the courier booths are added today.
- Every committed call notes one line in `journal` (bounded, saved): `{txid, op, buyer, seller, item, qty, total, day, minute,
  state}`. The flight recorder and the economy events can read it; nothing else is a second ledger.

## 8. Determinism and saves

No RNG, no wall clock; everything iterates sorted. Saved as the optional World key `"transactions"` (only when non-empty):
`{marks: {ns: seq}, outcomes: {ns: [[seq, result], ...]}, shipments: [...], journal: [...]}`. Old saves have no key: empty.
No `SAVE_VERSION` change. (Key name: the lead's decision under contract 3; proposed `transactions` because the settlement trade
runs with the Living Economy off, when the `economy` key is not written.)

## 9. Status on `wip/x20-le03`

Implemented at `8393449`: `game/scripts/core/economy/econ_transactions.gd`, `World.transactions` (built in `setup` and `load_dict`,
saved as `transactions` only when non-empty; key approved by the lead 2026-10-30). Tests `game/tests/le03_transactions_test.gd`:
79 checks, 0 failures (ids and every code; two buyers for the last unit; several transactions on the same funds and on escrowed
coins; shipments delivered, failed with refund, lost; village-to-settlement both ways; rejected and interrupted transfers; save,
load and replay including an open shipment; ten days of shipments, failures, retries and replays; claims with the economy on;
determinism; the switch). Conservation is checked across the village, the settlements, transit and the sink, with
`Regions.audit()` balanced, after every scenario. INT-606.

**Tester note (save compatibility):** once settlement shipments run in shipped play, normal saves carry the `transactions` key. A
build without this authority (Build 24 and earlier) loading such a save drops the key: open shipments' goods and escrowed coins
would be lost to that build. Load such saves only with a build that has it (the same treatment as other optional keys).
