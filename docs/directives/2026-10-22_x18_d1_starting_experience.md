# Owner decision, 2026-10-22: Expansion 18 D1, starting experience (verbatim)

Approve Expansion 18 D1, Option 2 with farming sub-option (a).

Initialize each person's industry-specific experience once from their existing recorded skill using:

Starting experience days = industry experience cap × recorded skill level ÷ 10.

For farming, derive the starting level consistently from the existing PAR-01A working-history mechanism rather than introducing an unrelated random system.

Requirements:

1. Preserve existing villagers' established experience and skill differences.
2. Apply initialization once for new worlds and when migrating older saves that lack experience records.
3. Never overwrite, reset, or regenerate experience already saved.
4. Do not fabricate additional historical work beyond the approved PAR-01A initialization mechanism.
5. Keep experience independent for each industry.
6. Preserve accumulated experience when a worker changes industries.
7. Facility limitations must never reduce stored experience.
8. Ensure deterministic initialization and save/load round-trips.

Record the approval in the Expansion 18 decision register and implement it on the Expansion 18 branch only.

Keep the live capability modifier hook disabled until the remaining required decisions are approved.

Use focused tests and existing passing evidence. Do not initiate another long-duration simulation campaign.

After implementation, present D2 in dependency order with options, economic consequences, and a recommendation.

Expansion 19's gossip-timing investigation may continue independently. Expansion 20 remains at its completed LE-00 audit until further authorization.

Build 17 is frozen and must remain unchanged.
