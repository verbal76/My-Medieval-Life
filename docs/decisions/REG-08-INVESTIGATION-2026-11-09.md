# REG-08 investigation: courier stranded-delivery recovery (2026-11-09)

- **Requirement:** audit item REG-08, listed by the owner's 2026-11-09 overnight directive as "still under investigation"
  (`docs/directives/2026-11-09_overnight_autonomous_development.md`). Register: decision B25-AUD-REG-08 (UNDER REVIEW).
- **Who:** read-only investigator agent assigned by the lead under PAR-AGENTS-01, 2026-11-09 ~16:30 EST; reviewed and recorded by
  the lead. Evidence: code at `wip/b25r2-rev2` `b7884d3` and existing tests only; nothing was run or changed.
- **Status:** investigation done. Fixes need owner policy (questions at the end); nothing implemented.

Paths are under `game/scripts/core/` unless shown in full; `couriers.gd` is `settlement/couriers.gd`.

## Findings

**F1. REG-08 proper: a waiting route delivery that never resolves. CONFIRMED DEFECT (low).**
- `tick` (`couriers.gd:837`) interrupts only `in_transit`/`returning` jobs. `_depart` (`:854-858`) hands an `at_booth` job to the
  booth's new keeper or does `continue`. No cancel, timeout or UI ends a waiting job; only `_arrive`, `_home`, `interrupt` end jobs.
- The only way out is the daily keeper replacement (`:1157-1161`), which needs a living adult who passes `Construction.can_hire`
  (`construction.gd:270-283`). In a failing village (WDR-022) that may never come; every shop booth's route uses the village
  booth's keeper (`:1161`).
- While stuck: goods stay in the booth store (counted in `held_goods`); the flat fee already went to the carrier at booking
  (`:722-723`); new bookings are refused (`:601-602`).
- Knock-on: one unfinished job per sender (`:1233-1234`, `settlement/region_trade.gd:172-173`) blocks that NPC trader's courier
  trade for good; the stuck goods count as pending demand (`:1256`); the shop booth never closes (`:1191`).
- Save/load keeps it stuck (`:1316-1372`).
- Minimal fix (needs policy Q1-Q3): end a waiting job with no living carrier after a limit; return goods to the sender (pack, else
  deposit); a new terminal state added to the terminal lists (`:1233`, `:1194`, `region_trade.gd:172`). Failing-first test in
  `courier_live_test`: book with an NPC merchant, kill the keeper, make nobody hireable, run past three departures, assert terminal
  state, goods back, `coin_gap()`/`item_gap()` 0, merchant can post again; repeat across save/load.

**F2. Refunds into a person who is not alive. CONFIRMED value-loss path, latent (REG-03 overlap).**
- `interrupt` refunds a special delivery's fee with `add_coins(sender, fee)` (`couriers.gd:1038`) without checking the sender.
- Dead NPC: coins land after `_inherit` (`world.gd:3910+`) in a corpse's purse (counted, unusable). Migrated NPC: `_reactivate`
  sets `n.coins = coins` (`settlement/migration.gd:454`), erasing a refund with no ledger entry (coin destruction). NPC removed
  from `w.npcs` (`settlement/people.gd:182`, `migration.gd:481`): `add_coins` hits null at `:162` (script error).
- Latent: today only the player books special deliveries (`ui/courier_window.gd:143`).

**F3. Deposits for senders who will never collect them. CONFIRMED stranding (REG-03 overlap).**
- `_home` deposits proceeds at the booth when the sender is not alive or a pack is full (`couriers.gd:970-975`); only the player's
  courier window calls `withdraw` (`ui/courier_window.gd:101`). Dead or migrated NPC senders' proceeds, and an alive NPC's overflow,
  stay out of play for ever (counted). The coins were taken from the region party (`:160-166`).

**F4. A courier who migrates is treated as "died on the road". SUSPECTED; mostly REG-04 policy.** `tick:837` interrupts and
`_drop_load` (`:1063-1077`) drops the load where the NPC last stood, or at the booth if a region party dissolved
(`settlement/regions.gd:246-252`). Conserved, but place and wording wrong.

**F5.** The flat route fee is not refunded when the courier dies: works as coded; owner policy.

**F6.** Arrival-day arithmetic works as designed (`:832-835` catch-up). `every_days` 0 in `data/couriers.json` would loop for ever
(no guard). Route travel days fixed at creation (`:349`).

**F7.** Recipient gone / cannot pay / no longer wants: works as designed (`_arrive` `:875-913` sends goods back; `_region_takes`
`:932-947` re-checks demand).

## Related items
- REG-04 (couriers physically travel; approved, not implemented) would replace the abstract timers behind F1, F4, F5 and needs its
  own terminal-state design. REG-07 (merged) does not affect stranding (`Intel.fresh` checked at booking; arrival re-checks demand).
  REG-02: neither migration nor `World.kill` notifies the courier service; its cleanup should cover F2/F3.
- Save/load: in-flight jobs round-trip; only `in_transit` is tested (`game/tests/courier_live_test.gd:280-325`). Finished jobs are
  never pruned (saves grow).
- Test gaps: waiting job with no carrier; sender dies/migrates mid-delivery; uncollected NPC deposits; courier migrates; dissolved
  region party; save/load of `at_booth`/`returning`; one stuck job blocking later trade.

## Owner decisions needed (B25-AUD-REG-08; not chosen, per DECISION-CONFLICT-01)
1. Who receives stranded goods and coins: the sender's heir or household, a booth deposit, or the manor/treasury.
2. How a waiting route job ends: timeout, reassignment, or waiting indefinitely; over what period.
3. Whether the flat route fee is refunded when a delivery never departs or is interrupted.
4. How a courier's migration is treated (depends on REG-04).
