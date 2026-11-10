# Owner directive, 2026-11-10: Owner decisions (INV-02, REG-02, SAV-04, REQ-B17F-JOBS) and WP-1 authorization

Received 2026-11-10 in the lead session. Saved verbatim below; never edited. Register ids B25-INV02-D2 (INV-02 decisions),
B25-REG02-DEBT-D1, B25-SAV04-D1, B25-B17FJOBS-D1, B25-WP1-01 (WP-1 authorization).

---

MML Build 25 — Owner Decisions and WP-1 Authorization

Claude, the following decisions are approved.

INV-02 — Food Spoilage

Approve F1(b), F2(b), F3(b), F4(a), F5(b), and F6(b), as recommended.

Defer F7, food preservation.

Keep the spoilage prototype disabled by default until implementation and full validation are complete.

Verify storage classes, settlement inventory, courier ownership and losses, away-guest behavior, food consumption priorities, conservation, determinism, and save/load.

REG-02 — Migrating Household Loans

Approve option (b), subject to preserving legitimate continuing obligations.

Investigate whether the existing estate-sale process correctly applies to household migration.

Do not automatically liquidate a household merely because it moves.

If obligations can legitimately continue, preserve them. If the household is dissolving or departing the applicable economic system, settle debts through the established process and record unpaid balances as defaults.

Implement and test the verified rule.

SAV-04 — Wildlife and Combat Continuity

Approve option (a).

A saved game must reload deterministically, but exact equivalence with an uninterrupted wildlife or combat simulation is not currently required.

Document the limitation and verify deterministic repeated reloads.

Do not silently discard persistent world state that existing gameplay rules require.

REQ-B17F-JOBS — Adult Unemployment

Approve option (b): measurement only.

After Batch 3+4 integration, measure current adult unemployment and identify the actual causes.

Do not implement employment-system changes based solely on obsolete Build 17 measurements.

WP-1 — Authorized

Begin the 14-item small-work package using isolated development branches.

Start with failing-first reproduction tests and actual code inspection.

Implement verified corrections that remain within the existing approved requirements. Escalate genuine design choices.

Do not mark an issue complete merely because it cannot be reproduced. Document the tested conditions and coverage.

Keep the original 69-item tracker current, preserving all original IDs.

Validation and integration

Continue the baseline attribution and deliver the Batch 3+4 decision report immediately when ready.

Complete F015/P99 campaign verification and all isolated defect-branch validations.

Do not merge branches or accept simulation baselines without my explicit approval.

Preserve conservation, determinism, save/load integrity, existing permissions, and all relevant gameplay invariants.

Provide concise updates with verified counts, commit SHAs, remaining blockers, and decisions needed.
