# Owner approval, 2026-10-23: identity foundation design, ID-D1, tolerance and reservation overlaps

Saved verbatim. Answers `docs/design/IDENTITY_AND_RECONCILIATION_PROPOSAL.md` (register ID-01, ID-D1, RECON-01).

---

Approve the identity foundation design with the following requirements and clarifications.

1. Permanent identity architecture: APPROVED

Every person receives one globally unique, permanent identity that is never reused.

Maintain a historical identity register covering living, deceased, migrated, and inherited characters.

Migration must transfer the existing person, not create a replacement.

Identity must survive save/load, settlement transfers, family changes, death, and future transitions between detailed and abstract regional simulation.

Approve save version 20 and a dedicated foundation branch.

The save migration must be deterministic, preserve existing references wherever possible, and never overwrite the original save if migration fails.

If old saves lack sufficient information to establish a historical identity reliably, report the ambiguity rather than inventing relationships or merging unrelated people.

2. ID-D1: Player succession and reputation

Preserve Build 18's existing family-reputation continuity as the immediate compatibility baseline.

However, the heir must retain their own permanent individual identity.

The deceased predecessor and the heir must remain separate people in historical, relationship, civic, and economic records.

Family reputation may influence how villagers initially judge the heir, but it must not erase the heir's personal reputation or imply that every NPC has the same opinion of both characters.

Do not introduce a new inheritance reputation formula during this foundation repair. Any deeper integration with Expansion 19's subjective judgment engine requires separate approval.

3. Tolerance overlap: APPROVED

Establish one authoritative calculation for tolerance and related personality modifiers.

Do not apply the existing temperament adjustment and new personality adjustment independently to the same event.

Preserve Build 18 behavior while the new personality system is disabled.

4. Goods reservations overlap: APPROVED

Establish one authoritative mechanism for tracking committed inventory.

New reservations must recognize existing contract holds.

The same goods cannot be reserved, promised, sold, or transferred twice.

Preserve inventory conservation and existing contract behavior while the new economy is disabled.

Execution boundaries

Implement these foundation repairs on the dedicated foundation branch.

Keep Expansions 19, 20, and 21 separate.

Do not activate expansion features, merge into Build 18, or publish a release.

Use targeted tests for identity continuity, migration, succession, save compatibility, personality calculation, reservation conflicts, and conservation.

Reuse existing passing test evidence where the source code is unchanged.

Before integration of the three expansion branches, provide the completed foundation results and remaining conflict inventory.

Preserve all previously approved owner decisions and existing working gameplay.
