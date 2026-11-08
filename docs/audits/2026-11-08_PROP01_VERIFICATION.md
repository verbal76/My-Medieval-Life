# PROP-01 — reproduced and fixed, pending integration

Recorded 2026-11-08 UTC. Audited source SHA `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`. Only this finding's code and tests changed on branch `audit/prop01-cancel-site-20261108`.

**Observed defect:** A guest could call cancel_site with another owner's plot and receive materials into its own inventory. Host now checks the site's own owner matches the requesting player AND the decoded refund inventory is precisely that player's own pack. NPC/host internal cancellations are unaffected.

## Headless Godot reproduction on unmodified production code
- [Red GitHub Actions run #42461697475](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461697475): **7 checks, 5 failures**. Failure was observed in the expected unauthorized path. The red run also showed follow-on failures from the malicious state mutation, not separate defects.

## Minimal correction
- Fix commit: `cf744a1188ddc4a49a6b8c9dd8ee5004c1ca64be`.
- [Green GitHub Actions run #42461831319](https://github.com/verbal76/My-Medieval-Life/actions/runs/42461831319): **7 checks, 0 failures**, same focused script, same GitHub runner configuration, with only the correction applied.
- Focused test: `game/tests/prop01_cancel_site_test.gd`.
- Regression registered under `.github/workflows/tests.yml` for the ordinary test suite; ordinary full suite **not yet run**.

**Status:** runtime reproduced; fixed on isolated branch; **NOT merged, NOT fully validated, NOT closed**. Full multiplayer and determinism CI remains required on the intended integration SHA. No baseline re-recording, no release, no other audit items changed.

Both headless Godot runs emitted resource-in-use warnings at process exit; not investigated here, do not interpret a focused pass as a full resource leak fix.
