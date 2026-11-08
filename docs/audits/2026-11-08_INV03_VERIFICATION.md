# INV-03 — Prevent foreign player-owned chests being treated as owned

**Audited base:** `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`; isolated branch `audit/inv03-foreign-player-chests-20261108`.

- Harness compilation failed in first try [#42506825276](https://github.com/verbal76/My-Medieval-Life/actions/runs/42506825276), corrected in test only (Variant type explicit). This was **not defect evidence**.
- [RED original game #42506955329](https://github.com/verbal76/My-Medieval-Life/actions/runs/42506955329): **7 checks, 3 failures**. Guest saw host's real family chest as "own", deposited items freely and consumed its own inventory.
- **Correction commit:** `3329e4295dedd337f57bee84269ee2946ef0da1d`. `Chests.info` and container classification now compare the holder to `w.acting_ref()`. Other player's actual family chest remains visible as foreign (theft rules apply), while their storage cannot be filled freely. Existing host access remains own.
- [GREEN corrected game #42507116945](https://github.com/verbal76/My-Medieval-Life/actions/runs/42507116945): **7 checks, 0 failures**.
- Regression: `game/tests/inv03_foreign_player_chests_test.gd`, registered for normal CI; check-count floor 7.

**LIMITS:** test exercises a real in-world host family chest. Separate real-container and cross-player theft/lock tests remain important before merge. **DRAFT ONLY; NOT MERGED OR CLOSED.** Broad multiplayer, save/load and full strict integration validation on exact final SHA needed. No baselines, builds or Claude Console spend. Temporary one-runner workflow removed from PR.
