# Owner directive, 2026-10-21: synchronize Expansions 18 and 19 with Build 17 (verbatim)

OWNER DIRECTIVE — SYNCHRONIZE EXPANSIONS 18 AND 19 WITH BUILD 17

Objective

Build 17 is feature-complete and undergoing final release validation.

I want Expansions 18 and 19 to refresh against the latest stable Build 17 code now, rather than continuing development against an outdated foundation.

Begin this work immediately, in parallel, without interrupting Build 17's validation.

This is a synchronization and compatibility directive, not authorization to expand either project's scope or release anything.

1. Establish the Build 17 baseline

The last reported integrated Build 17 commit was "cd7439c".

Before beginning, verify the actual current "wip/build17" HEAD and its status.

Use the latest committed, integrated Build 17 source as the synchronization baseline. Record its exact commit SHA in both expansion workstreams.

Do not assume Build 17 is officially released.

If Build 17 receives a correction during final testing, identify and incorporate that specific change later as needed.

Do not merge Expansion 18 or Expansion 19 into Build 17.

Synchronization must be one-way:

Build 17 → Expansion 18

Build 17 → Expansion 19

2. Protect existing expansion work

Before integrating anything:

- Confirm the current branches and working trees for Expansions 18 and 19.
- Preserve all committed and uncommitted work.
- Push any completed local-only commits or safely checkpoint unfinished work where appropriate.
- Review active workers before changing files they are editing.
- Avoid overwriting existing expansion implementations with older Build 17 versions.
- Do not restart workers or duplicate assignments unnecessarily.

Use the repository's established branching and integration practices.

Resolve conflicts deliberately, preserving both the completed Build 17 features and the expansion-specific work.

Do not silently discard functionality from either side.

3. Expansion 18 — Economic and physical-system reconciliation

Refresh Expansion 18 against the latest Build 17 foundation.

Pay particular attention to the following systems:

Mining and excavation

- Mining capability and player/NPC parity.
- MIN-D2 and MIN-D3.
- Shovels and pickaxes.
- Mining rights and land restrictions.
- Trial pits, spoil, earth piles, and material conservation.
- Underground excavation, stability, supports, and collapse outcomes.
- Mining equipment production and physical supply chains.

Economic and labor systems

- Manor purchasing of tools and materials.
- Smith and carpenter production dependencies.
- Negotiated procurement contracts.
- Physical goods movement and inventory ownership.
- Manor delivery fallback, including LOG-01.
- Worker availability and job assignment.
- Finite currency, inventory, and market transactions.

PROS-18 compatibility correction

Build 17 identified a specific discrepancy: Expansion 18's capability calculator does not yet account for the updated equipment-based capability rules or the player's contribution.

Reconcile PROS-18 with the actual implemented Build 17 rules.

Ensure the calculator does not count workers as capable when they lack required equipment, and includes the player where the approved capability rules require it.

Do not invent new eligibility rules or occupation-based privileges.

Stoneworking requirements

Preserve the approved Expansion 18 requirements:

- STONE-02
- STONE-03
- STONE-04
- STONE-05
- STONE-06
- X18-STONECUT

The three STONE-Q owner decisions are final.

Dedicated Stoneworking skill and iron chisels belong to Expansion 18, not Build 17.

Do not invent the remaining owner-controlled starting levels, conversion efficiencies, durability rates, or recipes. Keep those questions documented for the appropriate design stage.

Do not confuse the current Build 17 stone-dressing recipe with the future Expansion 18 implementation.

4. Expansion 19 — NPC systems compatibility

Refresh Expansion 19 against the same Build 17 foundation.

Review integration points involving:

- NPC identities and relationships.
- Household and family membership.
- NPC occupations, work assignments, and economic decisions.
- Trading and ownership changes.
- Player/NPC interactions.
- Crimes, combat, injuries, and deaths.
- Mining accidents and collapse outcomes.
- NPC availability, daily updates, and event processing.
- Subjective judgment, gossip, reputation, and memory.

Preserve the approved subjective-judgment design.

NPCs maintain individual opinions based on observed or legitimately communicated events. Opinions influence decisions without automatically dictating them.

Do not introduce runtime LLM dependencies or replace deterministic systems with invented behavior.

Preserve existing conservation and determinism guarantees.

Performance: Retain Expansion 19's completed optimizations, including distributed daily updates and reduced trade-hook overhead.

The previously reported gossip frame-time hotspot remains an Expansion 19 performance concern. Do not turn this synchronization into another broad performance campaign unless integration creates a genuine regression.

Preserve outstanding owner questions. Do not silently choose answers.

5. Run both refreshes in parallel

Expansion 18 and Expansion 19 should synchronize independently.

Neither expansion needs to wait for the other unless a specific technical dependency makes that necessary.

Use existing workers when practical.

Avoid launching duplicate workers for tasks already underway.

Keep each expansion's integration changes isolated on its own branch.

If an active worker is editing conflicting files, coordinate or defer that narrow integration rather than risking lost work.

6. Testing discipline

Follow the permanent SIM-01 policy.

Do not repeat comprehensive simulation suites merely because branches were refreshed.

Reuse existing passing evidence where it still applies.

For changes introduced by synchronization:

- Run focused compatibility tests for affected systems.
- Run necessary compile, import, or launcher checks.
- Verify relevant determinism and conservation invariants.
- Use longer simulation tests only when necessary to validate genuinely changed behavior.

When long simulations are needed, use one monitored longest-duration run per required seed, with intermediate checkpoints, instead of redundant shorter runs.

Preserve distinct scenarios and independent determinism comparisons where required.

Do not delay Build 17 or consume excessive compute on redundant validation.

7. Protect Build 17 release readiness

Build 17's final validation has priority.

Its remaining work includes:

- Repeatable-results verification.
- CI.
- Four monitored 365-day MIN-G simulations.
- Remaining documentation corrections.
- Visual review.
- Readiness report.
- Owner release approval.

Do not modify Build 17's release-candidate code as part of the expansion refresh.

Do not introduce Expansion 18 or 19 requirements as new Build 17 blockers.

If a genuine Build 17 defect is discovered during synchronization, report it with evidence rather than silently modifying the release candidate.

Any subsequent Build 17 fix should be incorporated into the expansion branches through a targeted follow-up synchronization.

8. Documentation

Follow WIKI-01.

Update the expansion requirements registers, decision records, system interactions, and developer documentation to reflect the actual synchronized implementation.

Clearly distinguish:

- Implemented and verified.
- Implemented but requiring integration validation.
- Planned but not yet implemented.
- Awaiting owner decision.

Do not present future expansion features as playable Build 17 features.

Record the Build 17 baseline SHA used by each expansion.

9. Report back

Provide a concise report for each expansion covering:

1. Original branch and commit.
2. Build 17 baseline commit incorporated.
3. New resulting branch commit.
4. Files or systems with significant merge conflicts.
5. Compatibility issues discovered and resolved.
6. Outstanding compatibility issues.
7. Focused tests performed and results.
8. Remaining owner decisions.
9. Whether the expansion is ready to resume its previously planned work.

Also confirm that Build 17's release-candidate branch and ongoing validation were not disturbed.

Final instructions

Proceed with both expansion refreshes now.

Preserve all existing work.

Do not restart completed development, introduce unnecessary features, or perform redundant test campaigns.

Do not release or distribute any build without explicit owner authorization.

The objective is to have Expansions 18 and 19 working from the nearly finalized Build 17 foundation while Build 17 completes its remaining validation.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
