# PROP-06 — Owner-approved gameplay decision implementation

**Recorded:** 2026-11-08 (America/New_York). **Audited source:** `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`. **Branch:** `feature/prop06-migration-property-20261108`. **Status:** isolated correction implemented, focused Godot test passed, pending full integration and owner acceptance.

## Owner decision implemented
Whole departing households sell outright-owned property to manor before packing; if manor cannot pay, departure is blocked rather than title seized. On lease cancellation/eviction, manor takes parcel improvements and unfinished-site goods left on land. Owned unfinished-site materials return to seller's pantry before sale.

## Runtime evidence
- [Godot Actions run #42514264240](https://github.com/verbal76/My-Medieval-Life/actions/runs/42514264240): **10 checks executed, 0 failures**.
- Source regression: `game/tests/prop06_migration_property_test.gd`; registered in `.github/workflows/tests.yml` with minimum check-count floor **10** in `tools/ci_check_floors.json`.
- Tests were implemented and passed for the changed code. Do not misrepresent these as initial failing-on-original red/green tests: this is an approved NEW gameplay rule.
- Temporary single-runner workflow removed from final PR.

## Remaining integration/approval gates
Review multi-parcel estates, house contents/tills, outstanding arrears, remote migration and failed-sale atomicity. Cross-check BIZ-04, INV-04, PROP-03, REG-02; run full conservation, household migration, property/lease and save/load suites.

**Do not mark resolved yet.** No main/production merge, no builds/releases, no baseline re-recording. Claude should integrate into dedicated Build 25 audit branch, test existing suites, inspect logs/artifacts, and only merge verified changes to the approved development branch. Any missing security/property coverage blocks this feature's merge.
