# PROP-02 — confirmed and corrected on isolated branch

**Date:** 2026-11-08 UTC. **Audited SHA:** `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`. **Branch:** `audit/prop02-fitting-owner-20261108`.

## Reproduction (no game code change)
[RED GitHub Actions run #42461880196](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461880196): **13 checks, 5 failures**. A fabricated guest network request successfully removed the host-owned room's fitted counter, closed the associated shop, and returned fitting materials to the guest. Its legitimate host follow-up was consequently affected. The test set up a real leased plot, built house and storeroom, placed a counter, opened a shop, and stocked it.

## Correction
**Fix commit:** `ee3727eec5be616fe1e2ec6815567471990a3979`. `Fitting.remove` now checks `fit_refusal(b)` (same validated room/holder rule used for fitting placement) before changing the room, closing a shop, or refunding any materials. The legitimate host-owner removal path remains available.

[GREEN GitHub Actions run #42461995223](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461995223): **13 checks, 0 failures**. Host shop and stock remain after forged removal; guest receives no materials; host can subsequently remove their own counter.

Test: `game/tests/prop02_fitting_owner_test.gd` (registered in normal `.github/workflows/tests.yml`). Each red/green test was run by a **single Linux GitHub Actions runner**. The temporary workflow was removed after the run.

**Disposition:** reproduced and fixed on separate branch; **NOT merged, NOT closed**. Full multiplayer and determinism tests and merge review are required on an integration commit. No production baseline or save format changed. Both focused runs logged pre-existing-type resource-in-use warnings at process exit; not diagnosed here.
