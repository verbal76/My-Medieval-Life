# MP-04 — Host-authorized cart placement regression evidence

**Recorded:** 2026-11-08 UTC  
**Repository:** `verbal76/My-Medieval-Life`  
**Audited revision:** `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`  
**Engineering branch:** `audit/mp04-cart-gateway-20261108`  
**State:** Reproduced in headless Godot and corrected in an isolated branch; **not merged**, full regression suite outstanding.

## Original finding

Audit MP-04 identified a client-authority bypass: the guest verb whitelist permitted `carts.place`. This is an internal world-creation method, not the validated action that takes a `handcart` from the player's inventory. A crafted guest verb could therefore create a free cart and increment `used_handcart` in the accounting ledger.

The normal player action `World.player_set_down_cart` checks for a handcart and removes exactly one before calling `carts.place`.

## Reproduction: RED

- **Commit:** `5eb6a085ff57edada82a62be082c7629bf925353` (audited production code unchanged; test and single-runner CI workflow added).
- **GitHub Actions:** https://github.com/verbal76/My-Medieval-Life/actions/runs/42459686569
- **Command:** `godot --headless --path game --script res://tests/mp04_cart_gateway_test.gd`
- **Observed:** 6 checks; **2 failed**, 4 passed. The unauthorized `NetActions.apply_verb(..., "carts.place", ...)` was accepted and added a cart without consuming an item. The legitimate `player_set_down_cart` pathway succeeded and consumed one handcart.

This is runtime reproduction of **MP-04 only**, not confirmation of the other static-audit findings.

## Minimal correction: GREEN

- **Correction commit:** `32cab1d0fde6c937c577d96a63b0d49706d7e754`.
- **Change:** Remove `carts.place` from `NetActions.VERBS`; leave `player_set_down_cart` available.
- **GitHub Actions:** https://github.com/verbal76/My-Medieval-Life/actions/runs/42459774174
- **Observed:** **6 checks, 0 failures** on the corrected commit. Forged direct cart creation was rejected, and legitimate placement still created one cart and consumed one item.
- **Regression:** `game/tests/mp04_cart_gateway_test.gd`, added to the ordinary `.github/workflows/tests.yml` game-suite list for future full validation.

Both headless runs emitted ObjectDB/resource-in-use warnings at exit. They are not part of MP-04's assertions and were not investigated or fixed in this narrowly scoped change.

## Scope and next gates

Only the direct cart-creation verb authorization was changed; no simulation decisions, procedural generation, save schemas, economy baselines, or runtime cart-placement behavior were modified. The isolated focused workflow used **one GitHub Actions Linux runner**, not the twelve-shard standard suite.

**Before merging or closing MP-04:** review the pull request, run the normal relevant multiplayer suites and applicable determinism gates on the intended integration commit, ensure the permitted wrapper works under a real guest connection, and preserve passing SHA-bound evidence. Never re-record a simulation baseline merely to pass a test.

This evidence updates the MP-04 status to **reproduced / fixed on isolated branch / integration verification outstanding**; it does not close the entire 69-item audit backlog.
