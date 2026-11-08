# LIFE-04 — Widowed NPC, player/NPC and player/player remarriage

**Owner-approved 2026-11-08.** Branch `feature/life04-widow-remarriage-20261108`, audited baseline `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`.

**Implemented:** living partner eligibility for NPC and player courtship checks no longer confuses a deceased spouse with an active one. NPC-autonomous courtship, NPC/NPC marriage, player/NPC proposals and player/player consent path respect the rule. Optional `past_partners` histories preserve previous spouse person IDs through serialization and do not delete historical family links. Existing live relationships remain exclusive and kinship exclusions continue.

**Focused evidence:** initial [run #42513138777](https://github.com/verbal76/My-Medieval-Life/actions/runs/42513138777) passed 11/11; extended [run #42514346703](https://github.com/verbal76/My-Medieval-Life/actions/runs/42514346703) passed **15/15**, including player-to-player remarriage, no parse failures. Normal `.github/workflows/tests.yml` registration and a **15-check floor** are added. New behavior is not an original-code bug red/green demonstration.

**Pending before merge:** existing relation, family, marriage, player multiplayer, player-couple household, save migration, family history, heirs and broad deterministic simulation tests on the combined integration SHA. Specific risks: established couple households and descendants across subsequent remarriages, legacy saves with dead spouse pointers, and multiplayer guest rejoin. Inspect behavior; do not edit baselines to obtain green. **Not integrated, merged, released or marked closed.**
