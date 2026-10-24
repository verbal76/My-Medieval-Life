# Owner decisions, 2026-10-24: roadmap questions ROAD-Q1 to ROAD-Q5

Saved verbatim from the session.

---

MY MEDIEVAL LIFE — ROADMAP QUESTIONS: OWNER DECISIONS
The ROAD-03 review is accepted, with the following decisions.
ROAD-Q1 — APPROVED
Expansion 27 is officially World Exploration, Dungeons & Encounters.
Preserve the complete existing specification for that track and assign it to Expansion 27. Do not reduce its scope or invent new features.
Multiplayer remains an independent parallel development track and is not Expansion 27.
ROAD-Q2 — APPROVED
Expansion 23 may implement banditry, crime, and related economic consequences within the village, existing roads, and currently represented settlements.
Regional travel-time route banditry that depends on Expansion 22's completed route infrastructure belongs in Expansion 22, Phase E.
Avoid temporary systems that will need to be discarded later.
ROAD-Q3 — APPROVED
Skeletons, lizards, and spiders belong in Expansion 26, Creatures & Heroes.
Expansion 26 owns their behavior, survival, combat, and other creature-specific mechanics defined in its specification.
Expansion 27 owns their placement within its exploration environments and encounters.
Do not duplicate creature behavior systems.
ROAD-Q4 — APPROVED
Expansion 22 owns the shared building-condition, damage, deterioration, and repair infrastructure.
Expansion 25 must reuse that infrastructure for weather and disaster effects.
Design one extensible system rather than separate damage models.
ROAD-Q5 — APPROVED WITH CONDITIONS
After Build 19 receives owner playtest acceptance, the Expansion 20 and 21 preparation branches may be brought forward onto the approved Build 19 baseline.
Before performing the integration, report the exact branches, merge bases, anticipated conflicts, and preservation plan.
Do not activate unfinished systems or modify the accepted Build 19 release.
Do not merge into the protected main branch without authorization.
Updated Roadmap
The approved development priority is:
20 → 21 → 23 → 22 → 24 → 25 → 26 → 27
Expansion numbers remain fixed.
Multiplayer remains a separate parallel track.
Additional Instructions

1. Update the roadmap, expansion register, dependency review, and affected specification references.
2. Correct outdated expansion-number references while preserving the historical record of previous numbering.
3. Maintain clear ownership boundaries between shared systems.
4. Preserve every previously approved feature and design decision.
5. Identify any remaining architectural questions for Expansion 20.
6. Do not implement Expansion 20 or begin branch integration yet.

Record these decisions as approved, update the documentation, and report readiness for Expansion 20.
Stop after completing the documentation updates.
