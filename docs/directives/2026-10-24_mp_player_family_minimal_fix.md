Owner directive, 2026-10-24, verbatim.

MY MEDIEVAL LIFE — MP-PLAYER-FAMILY: MINIMAL FIX AUTHORIZATION

Clarification of my Build 21 decision.

I am not automatically deferring MP-PLAYER-FAMILY. If the two identified gaps can be corrected with small, localized changes to existing mechanics, I want them included in Build 21.

The approved design remains unchanged:

- Married male and female player characters can have biological children organically under the existing reproduction rules.
- Married male/male and female/female player couples can adopt children but cannot have biological children together.
- Adopted children recognize both spouses as parents.

Your task is to extend existing functionality, not develop a new family system.

Implementation boundary

1. Inspect the existing reproduction and adoption code.
2. Determine whether the two gaps can be corrected through small, localized changes.
3. Reuse existing pregnancy, birth, adoption, household, parentage, and persistence mechanics.
4. Do not introduce new family architecture, simulation subsystems, pregnancy mechanics, inheritance systems, networking frameworks, or unrelated features.
5. Do not refactor working NPC family behavior merely to support player couples.
6. Preserve existing single-player behavior and deterministic results.

If the fix is genuinely small, implement it as part of the existing Build 21 agent's work.

A roughly 50-line correction is entirely acceptable. That is an illustration of the intended scale, not a rigid line-count limit.

Stop condition

If inspection reveals that this requires a new subsystem, substantial data-model changes, a broad multiplayer synchronization redesign, or cascading changes across unrelated systems:

Stop work on this item and defer it to a future build.

Do not begin that expansion without my authorization.

Focused verification

If implemented, check only the affected behavior:

- Male/female player couple can have a child under existing rules.
- Same-sex player couples do not have biological children.
- Adoption records both spouses as parents.
- Save/load preserves parent relationships.
- Existing single-player family behavior remains unchanged.

Reuse existing tests wherever possible. Do not initiate a new comprehensive simulation campaign.

Reporting

Tell me whether this was:

- A small correction to existing code, now implemented and tested; or
- A larger expansion, deferred without disturbing Build 21.

If deferred, explain the specific architectural dependency.

My objective is the smallest correct implementation that satisfies the approved behavior, not a new family expansion. Keep Build 21 moving.
