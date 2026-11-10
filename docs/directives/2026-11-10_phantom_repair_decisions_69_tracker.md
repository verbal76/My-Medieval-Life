# Owner directive, 2026-11-10: Owner decisions (legacy household save repair) and 69-item completion tracking

Received 2026-11-10 in the lead session. Saved verbatim below; never edited. Register ids B25-SAVE-PHANTOM-D3 (decisions 1-2),
B25-TRACK-69-02 (sections 3-6); extends B25-SAVE-PHANTOM-D2 and B25-AUDIT-69-01.

---

MML Build 25 — Owner Decisions and 69-Item Completion Tracking

Claude, I approve the following two decisions regarding the legacy household save repair. Continue all existing testing, baseline attribution, and Build 25 workstreams.

1. Dead Villagers in Incorrect Households — APPROVED

Remove incorrect household membership entries for deceased villagers when authoritative records establish that they did not belong to that household.

Requirements:

- Preserve the deceased villager's identity, death record, family relationships, inheritance, and historical records.
- Remove only demonstrably incorrect household memberships.
- Do not delete deceased villagers or alter legitimate historical information.
- If the records conflict or the correct membership cannot be established, preserve the entry and flag it for investigation.
- Ensure the repair is deterministic and idempotent.

2. Bandits Who Have Left Their Band — APPROVED WITH SAFEGUARDS

Remove stale band-household memberships when the records establish that a bandit has genuinely departed.

Requirements:

- Distinguish former bandits from active band members who legitimately have no ordinary household.
- Verify actual departure using authoritative band membership, affiliation, and migration records.
- Do not assume that a missing ordinary household means a bandit has departed.
- Preserve legitimate band membership, relationships, and historical records.
- Flag ambiguous cases rather than guessing.

Add failing-first regression tests for both corrections.

Validate against copies of real campaign saves, including the seed 1 day-300 save from run "42788018729".

Confirm that the repair:

- Changes only demonstrably incorrect membership records.
- Preserves currency, inventory, contracts, inheritance, and legitimate relationships.
- Produces identical results after repeated save/load cycles.
- Does not change unrelated simulation state.

Keep the repair on its isolated branch. Do not merge without approval.

3. Maintain the Original 69-Item Audit as a Living Tracker

The original audit is now established:

- 69 original items.
- 40 engineering-verified.
- 3 implemented, awaiting integration.
- 1 integrated, awaiting verification.
- 4 blocked.
- 21 not started.

Authoritative reconciliation: "docs/audits/2026-11-10_69_OPEN_ITEMS_AUDIT.md" at "6bacff0".

Maintain these 69 original IDs and update their statuses as evidence changes.

Distinguish:

- Code implemented.
- Focused tests passed.
- Full CI passed.
- Simulation validation passed.
- Merged into the development line.
- Player/device verification completed.
- Release-gate verification completed.

Do not describe an item as fully release-verified merely because its automated tests passed.

Keep newly discovered defects in a separate register, linked to affected original items where applicable. Do not silently increase, decrease, or redefine the original 69.

4. Prepare the Remaining 29 Items for Execution

While the baseline attribution and other campaigns run, organize the remaining items into actionable work packages.

Identify which of the 21 not-started items can be investigated and implemented independently.

Prioritize small, isolated, reproducible defects that can be resolved without disrupting active tests.

For the four blocked items—INV-02, SAV-04, REG-02 and REQ-B17F-JOBS—prepare the exact owner decisions required, including consequences and your recommendation for each option.

Do not treat deferred work as cancelled.

For larger systems, including REG-04, REG-05, MP-02, MP-07 and JOB-02, prepare implementation dependencies and test plans before coding.

Do not start major feature implementations without approval.

5. Continue Existing Validation

Continue monitoring and verifying:

- Batch 3+4 baseline attribution and owner decision report.
- F015/P99 campaign and regression results.
- Meal-claims and contract-purchase fixes.
- Clan-child pantry fix.
- Household member-ID fix.
- Legacy household phantom repair.
- Contract-funds correction.

Verify exact commit SHAs, CI artifacts, conservation, determinism, save/load integrity, and regression results.

Do not merge branches, accept new simulation baselines, weaken tests, or declare Build 25 complete without owner approval.

6. Next Owner Report

Provide a concise dashboard showing:

1. Original 69-item progress by status.
2. Items that can close immediately after approved integrations.
3. Remaining development work grouped by workstream.
4. New defects being resolved outside the original 69.
5. The four blocked decisions, with recommendations.
6. The next integration and validation gates.

Continue productive work without repeatedly requesting authorization for investigations and tests already approved.

Our objective is to finish all 69 original items, resolve newly discovered defects, and produce a stable, thoroughly validated Build 25 player build—not simply close checklist entries.
