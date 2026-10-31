# Expansion 27: World Exploration, Dungeons and Encounters

**Current status:**
- The number and the assignment of the existing specification are approved (ROAD-Q1).
- Implementation is **not authorized**.
- Priority 8, the last in the order.
- **Next authorized phase: none until the owner authorizes it.**

Status vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 (DOC-RECON-01).

## Current approved scope

| Date | Owner decision (quoted) | Source |
|---|---|---|
| 2026-10-30 | "Do not begin Expansions 22–27." | `docs/directives/2026-10-30_master_development_resumption.md` §11 |
| 2026-10-27 | D32h/D32i, GDD-REVIEW, PARK. The old-GDD Morris era, atlas and five-region starts are parked, along with any "sprawling elemental system" of magic: "Existing combat Fireball is real and should be preserved". "Large outside-world terrain requested earlier is still a separate approved direction." | `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md` §3; OD-17 |
| 2026-10-24 | ROAD-Q1: "Expansion 27 is officially World Exploration, Dungeons & Encounters. Preserve the complete existing specification for that track and assign it to Expansion 27. Do not reduce its scope or invent new features. Multiplayer remains an independent parallel development track and is not Expansion 27." | `docs/directives/2026-10-24_owner_roadmap_question_decisions.md`; EXP-27 |
| 2026-10-24 | ROAD-Q3: "Expansion 27 owns their [skeletons, lizards, spiders] placement within its exploration environments and encounters." | same; CREATURE-OWN |
| 2026-10-21 | The owner's starter "Future unnumbered — Exploration, Dungeons & Encounters". Its own status: "Partially approved features; DRAFT grouping only". Purpose: "Connect the starting village to a larger county and broader world, with meaningful encounters and consequences rather than making the player the predetermined hero." | `docs/directives/2026-10-21_master_expansion_roadmap.md`; `wip/roadmap-docs:docs/roadmap/Exploration_Combat.md` |

**Approved baseline inside the specification:**
- B14-09, skeletons: behaviour in 26, placement in 27;
- FR-01, lizards and spiders: behaviour in 26;
- earlier owner direction for a vast explorable overworld and a broader county.

**Boundaries kept as written in the specification:** "Castles, dungeons, large-world implementation and magic mechanics
need separate scope decisions." Cave mining and dungeon gameplay are not merged "merely because both use underground
maps".

## Implemented

Nothing in Expansion 27. Related existing systems:
- the sword combat and Fireball;
- the overworld generator (`overworld.gd`);
- the mining caves (Expansion 17).

## Partial

None.

## Remaining approved work (approved, not authorized)

**EXP-27** (umbrella-like; NOT STARTED). Acceptance as recorded:
- saved travel and encounter state is consistent across reload;
- no enemy respawns into an occupied or invalid place;
- asset and licence validation and device performance;
- creature behaviour comes from 26.

## Design only / not authorized

**Phases**, from the owner's starter, where they are labelled "Proposed implementation plan". They have no register ids;
records are proposed:
- **WORLD-A:** audit map scale, streaming, navigation, save identities, mining cave entrances.
- **WORLD-B:** overworld regions, encounter locations, travel persistence; no assumed infinite generation.
- **WORLD-C:** approved skeleton behaviours and loot under the existing combat and conservation rules (the behaviour
  itself is Expansion 26's).
- **WORLD-D:** environmental encounters, performance, multiplayer boundaries; magic as separate scoped work before coding.

`Exploration_Combat.md` carries a variant list, EX-A..E.

**Magic:** "learnable, rule-based magic" is earlier owner direction cited by the starter. It is parked beyond Fireball by
D32i (2026-10-27), and the specification itself requires a separate scope decision. Not authorized.

## Deferred and superseded

| Item | Status | By |
|---|---|---|
| REC-006, castles, dungeons and caves in the world | DEFERRED ("future possibilities, not authorization to implement all of them now"). Related to 27 and still needs a separate scope decision. | owner (B8-011), register note 2026-10-24 |
| "24? / unnumbered" (master roadmap) | SUPERSEDED: numbered 27 | ROAD-Q1, 2026-10-24 |
| Magic systems, Morris atlas and regions from the old GDD | Parked (GDD-REVIEW) | OD-17 / D32, 2026-10-27 |

## Outstanding owner decisions

1. Implementation authorization (none today).
2. The separate scope decisions the specification requires: castles, dungeons, large-world implementation, magic.
3. Expansion 22's continuous geography (E22-OD-02) and Expansion 27's map scale and streaming (WORLD-A) touch the same
   world model. Designing them once is recommended. No owner decision is needed until either is authorized.

## Dependencies

- **Needs:**
  - 26's creature behaviour (CREATURE-OWN);
  - 22's continuous geography and streaming, where used;
  - 23's factions, for encounters;
  - existing combat and mining caves;
  - the asset pipeline.
- **Supplies:** none downstream in the current order.

## References

- Register: EXP-27, CREATURE-OWN, B14-09, FR-01, REC-006, ROAD-Q1, ROAD-Q3, OD-17.
- `docs/design/ROADMAP_20_27_PRIORITY.md` §2, §8.
- `wip/roadmap-docs:docs/roadmap/Exploration_Combat.md`, `Exploration_Combat_comparison.md`,
  `source/Exploration_Combat.docx`

## Missing sources

- The owner's starter (`Exploration_Combat.md`/`.docx`) exists only on `wip/roadmap-docs`. It is a single copy at risk.
- The "prior owner world exploration and magic discussions" that the starter cites have no dedicated directive. They trace
  to the historical game-design material, which is now parked. Recorded in `docs/expansions/MISSING_SOURCES.md`.
