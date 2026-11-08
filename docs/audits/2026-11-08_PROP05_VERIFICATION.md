# PROP-05 — reproduced and fixed, pending integration

Recorded 2026-11-08 UTC. Audited source SHA `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`. Only this finding's code and tests changed on branch `audit/prop05-guest-sale-20261108`.

**Observed defect:** Direct network verb business.sell was available to guest clients, allowing unauthorized host shop stock to be transferred to an NPC at arbitrary zero price. Removed internal sale from NetActions.VERBS; ordinary host-driven Business.sell remains unchanged.

## Headless Godot reproduction on unmodified production code
- [Red GitHub Actions run #42461609614](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461609614): **8 checks, 5 failures**. Failure was observed in the expected unauthorized path. The red run also showed follow-on failures from the malicious state mutation, not separate defects.

## Minimal correction
- Fix commit: `c5e2db912aa18db33aea0d00b8f08a1d4a506c6c`.
- [Green GitHub Actions run #42461726200](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461726200): **8 checks, 0 failures**, same focused script, same GitHub runner configuration, with only the correction applied.
- Focused test: `game/tests/prop05_guest_sale_test.gd`.
- Regression registered under `.github/workflows/tests.yml` for the ordinary test suite; ordinary full suite **not yet run**.

**Status:** runtime reproduced; fixed on isolated branch; **NOT merged, NOT fully validated, NOT closed**. Full multiplayer and determinism CI remains required on the intended integration SHA. No baseline re-recording, no release, no other audit items changed.

Both headless Godot runs emitted resource-in-use warnings at process exit; not investigated here, do not interpret a focused pass as a full resource leak fix.
