# SAV-01 — red/green evidence; integration not complete

**Recorded 2026-11-08 UTC.** Audited source: `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`. Branch: `audit/sav01-famine-reload-20261108`.

## Finding and root cause
The game's last hourly food-days decision cache was not serialized, so it reverted to 99 and transiently suppressed famine on load. The fix persists the exact last-hour cache; saves without the new key rebuild the cache from loaded inventories, preserving legacy compatibility. Save snapshot semantics remain hourly, not continuously recalculated.

## Runtime reproduction (unmodified production code)
- [RED Godot Actions run #42505790508](https://github.com/verbal76/My-Medieval-Life/actions/runs/42505790508) — **5 checks / 3 failures**.
- Regression: `game/tests/sav01_famine_reload_test.gd`, executed as a single Godot headless script on a single Linux Actions runner. The first run reproduced the failure before any game code was modified.

## Correction and verification
- **Correction commit:** `f5287a2e4c9e70d01043fa37ecb264397c05daf2`.
- [GREEN Godot Actions run #42505924495](https://github.com/verbal76/My-Medieval-Life/actions/runs/42505924495) — **5 checks / 0 failures**.
- Normal regression catalog: `.github/workflows/tests.yml` references `sav01_famine_reload_test.gd`.
- Temporary one-runner branch workflow used only for red/green and removed from final PR.
- No Claude Console credits used, no release, no baselines re-recorded.

## Remaining gates
**Reproduced and corrected on isolated branch — NOT merged, NOT closed.** Existing game suites, multiplayer/save-continuity, full simulation/determinism gates, and review against the eventual integrated commit are not done. Validate to exact final SHA; do not treat passing a focused test as proof all longer simulations are unchanged. Update canonical register only after owner-coordinated record synchronization.