# Expansion 20, LE-01 foundation: data contracts

Phase 1 (owner directive 2026-10-23, `docs/directives/2026-10-23_expansion20_phase1_authorization.md`). Three isolated
records behind a disabled switch. Nothing in live play calls them; the shipped game builds none of them and writes no
save key. Spec sections 3, 6, 14, 16; refresh `LE00_BUILD18_REFRESH.md` section 7 items 1-3.

## Switch and attach point: `game/data/economy.json` (format `mml-economy/1`)

| Field | Meaning |
|---|---|
| `enabled` | `false` as shipped. Only a test turns it on (`EconomyFoundation.set_override`). |
| `reservations.keep_finished` | finished (released, expired, consumed) records kept; older ones dropped (default 200) |
| `events.capacity` | event ring size (default 500); `events.save` saves the ring (default true) |

`EconomyFoundation.attach(world, saved)` (`scripts/core/economy/economy_foundation.gd`) is the one attach point, called
at the end of `World.setup` and in `World.load_dict`. Disabled: returns null, `World.economy == null`, `to_dict` has no
`economy` key unless the save carried one: a saved `economy` section is then held untouched (`World.economy_foreign`, a deep
copy, never parsed or processed) and written back unchanged, so switching the foundation off never erases saved data
(CLAUDE.md s.7, audit D2; the Expansion 21 `civic_foreign` pattern). Enabled: the optional save key `"economy"`
`{reservations?, events?}` is written only when a part is non-empty; an older save without it loads with empty records.
No `SAVE_VERSION` change.

## Actor resolver: `econ_actor.gd` (`EconActor`)

Read-only, uncached view over today's owners: `kind/exists/alive/coins/count/goods/holding/reserved`. Refs: `npc:<id>`,
`hh:<n>`, `player`, `manor` (treasury and granary), `region:<settlement>/<holder>` (via `Regions.party`), plus read-only
`chapel`, `stall:<id>`, `shop:<building id>` (tills, coins only). A dead villager exists but is not alive; an ended
household is not alive and holds nothing; a household has no purse. **No business identity**: OD-LE-04 and OD-LE-07 are
open, so no `business:` ref exists. Consumers: reservations, events, later diagnostics.

## Reservation record: `reservations.gd` (`EconReservations`)

`{id, owner, item (id or "coins"), qty, purpose, made_day, made_minute, expiry (day, -1 never), state: held|released|expired|consumed}`.
- A claim, never a transfer: reserve, release, expire and consume move no coin or good; the transfer stays with
  `World.trade` / `World.give`. `consume` only marks the claim.
- `reserve` refuses: qty <= 0, unknown or not-alive owner, an expiry already past, and more than held minus contract holds minus already reserved.
- **Contract holds (RECON-01, owner approval 2026-10-23 item 4).** `Contracts.held_for` (finished goods a seller still owes on open
  contracts; read by `NPCBrain.reserve` and `Credit.available`) is the live authority and stays so while the economy is off.
  `available(owner, item)` = held - `contract_held(owner, item)` (= `Contracts.held_for_ref`, the ref form `held_for` now
  delegates to; coins are never reduced, their contract set-aside is escrow) - own reservations, so the same goods cannot be both
  held for a contract and reserved; `reserve` refuses beyond it. A fulfilled or ended contract shrinks its hold and availability
  returns. Planned at integration (owner approval needed): contract holds re-expressed as reservations with purpose
  `contract:<id>` and `held_for` reading from them, one mechanism, with a test that contract behaviour is unchanged. Other live
  goods earmarks (all derived policy or flags, none a record; untouched, not read here): `NPCBrain.reserve` pen-feed share,
  `NPCBrain.keeps` (trade tools/forging for manor orders), `PlayerState.stolen_count` (stolen goods not for sale), the
  construction seller hold-back (`construction.gd`), `ManorWork.consign` (a physical move into a lot, not an earmark). Coin
  escrow (contracts, quests, manor work, couriers) stays out of scope.
- `unbacked()` reports held claims an owner no longer covers (goods left by a live trade, or promised on a contract after being
  reserved: reserved + contract holds above the stock; fields `reserved, contract_held, held, short, alive`); it never repairs.
- Deterministic: ids count up, listings and the saved array sorted by id. Cost per operation is the owner's own held
  reservations (an index by owner); `expire_due` scans held reservations only; no population scan.
- Future consumers (not wired): accepted-order inputs, then the other scattered forms of LE00 s.3.

## Economic event record: `econ_events.gd` (`EconEvents`)

`{seq, day, minute, type, actor, other, item, qty, coins, note}`; types are a closed list (`EconEvents.TYPES`). Strict order
by (day, minute, seq); an event earlier than the last is refused. Bounded ring (`capacity`). Query by actor (either side)
and type. Diagnostics only: nothing reads it to decide. Reservation changes are noted as events.
Future consumers: `economy_sim.gd` diagnostics, Expansion 19 facts.

## Not here (blocked or out of scope)
Offer book (OD-LE-02), knowledge (OD-LE-10), need model, credit terms (OD-LE-05/07), contract breach (OD-LE-13), business
identity (OD-LE-04/07), adaptive prices, loans, wages. Tests: `game/tests/economy_foundation_test.gd`.
