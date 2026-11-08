# JUS-03 — old-age death closes criminal case, no heir pursuit

**Audited source:** `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122` (2026-11-08). **Engineering branch:** `audit/jus03-age-death-case-20261108`.

Owner-approved rule, originally recorded in `justice.gd`: the criminal case ends when the offender dies; family reputation/stain persists. Combat death followed it, but `Life._player_dawn_one` old-age death did not call `justice.on_death`.

- [RED single-runner action #42462198471](https://github.com/verbal76/My-Medieval-Life/actions/runs/42462198471): **9 checks, 5 failures**. Old-age host and guest death left their cases open; host heir inherited wanted case. No production changes in baseline test.
- **Correction SHA:** `6ab511f4459451ca60b7028243e37f1028f77fed`. Calls `w.justice.on_death(w.acting_ref())` immediately when old-age death is recorded, before recorder/event updates. Uses existing idempotent closure with original criminal record archived as `died`. No change to family reputation.
- [GREEN single-runner action #42462279977](https://github.com/verbal76/My-Medieval-Life/actions/runs/42462279977): **9 checks, 0 failures**. Host and guest cases closed; heir keeps family reference without wanted case; closed case archived once.
- Regression: `game/tests/jus03_old_age_justice_test.gd` included in regular tests workflow.

**Status:** runtime reproduced and corrected on a separate branch; **NOT merged, NOT closed**. Before integration: run existing justice, aging, multiplayer, save/load and determinism gates on the intended commit. Avoid automatic baseline rewriting or release. Focused runs showed Godot exit resource warnings; not investigated by this fix.
