# Owner directive, 2026-10-23: Post-audit foundation repairs

Saved verbatim.

---

MY MEDIEVAL LIFE — POST-AUDIT FOUNDATION REPAIRS

I have reviewed the findings from "docs/design/CROSS_EXPANSION_PRESERVATION_AUDIT.md", commit "6c4e507".

Approve a controlled repair phase before integration of Expansions 19, 20, and 21.

Authorized work

1. Repair D1 and D2

- A save file must never activate a disabled feature.
- Disabled features must preserve their saved data without processing, modifying, or deleting it.
- Follow the existing civic-records preservation pattern where appropriate.
- Add targeted save/load regression tests, including repeated save cycles.

2. Repair D3

- Move the friendly-guard fine adjustment behind the appropriate feature gate.
- When judgment is disabled, preserve Build 18 behavior exactly.
- When enabled, preserve the approved rule: friendly guards may halve a fine but never waive it.
- Add a targeted player-theft and guard-response test.

3. Establish persistent NPC identity

Design and implement one authoritative identity mechanism that survives:

- Migration between settlements.
- Migration away and back.
- Save/load.
- Household and relationship changes.
- Death and inheritance.
- Transition between detailed and abstract regional simulation, when that functionality is eventually implemented.

Preserve relationship history, reputation, economic ownership, civic history, and lineage wherever applicable.

Do not create replacement people when an existing person changes location or simulation mode.

Do not reuse historical identities.

Provide a migration strategy for existing saves. Never silently discard or reassign historical data.

4. Reconcile overlapping mechanisms

Audit and propose the safest integration of:

- Existing temperament with the new personality layer.
- Existing contract holds with new economic reservations.

There must be one authoritative calculation for each behavioral factor and one authoritative reservation mechanism for each inventory quantity.

Preserve existing behavior when new expansion flags are disabled.

Do not replace working systems merely because newer code offers an alternative.

Execution boundaries

- Keep Expansions 19, 20, and 21 separate until the foundation repairs are complete.
- Do not activate unfinished features.
- Do not merge into main or the release branch.
- Do not publish builds.
- Do not modify released Build 18.
- Use narrowly targeted tests for changed code and reuse valid existing evidence.
- Run broader determinism and conservation checks only when integration makes them necessary.
- Keep an updated recovery handoff before Claude reaches approximately 80% context usage.

Required checkpoints

After D1–D3, report the repairs and test results.

Before implementing a major identity schema change, present the proposed identity and save-migration design for approval.

After identity work, report migration, inheritance, persistence, and historical continuity test results.

Before combining the expansion branches, present the integration plan and remaining conflicts.

Do not proceed beyond an approval checkpoint without authorization.

The objective is to protect everything already working in Build 18 while making the foundation safe for Expansions 19–23.
