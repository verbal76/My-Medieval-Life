# Expansion 24: Generational Legacy

**Current status:**
- The number and scope direction are approved. Implementation is **not authorized**.
- The register has **no umbrella record** for this expansion; one is proposed (EXP-24).
- Priority 5.
- **Next authorized phase: none until the owner authorizes it.**

Status vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 (DOC-RECON-01).

## Current approved scope

| Date | Owner decision (quoted) | Source |
|---|---|---|
| 2026-10-30 | "Do not begin Expansions 22–27." | `docs/directives/2026-10-30_master_development_resumption.md` §11 |
| 2026-10-24 | Priority 5, "24 — Legacy: Generational consequences, inheritance, and family continuity". Also: "Allow the consequences of earlier generations to influence later generations through the mechanisms defined in the approved specification. Maintain consistency with permanent NPC identities, family relationships, property, reputation, and mortality." | `docs/directives/2026-10-24_expansion_roadmap_reprioritization.md` |
| 2026-10-23 | "Legacy moves to Expansion 24." | `docs/directives/2026-10-23_expansions_22_23_kickoff.md`; OD-30 `owner_answer`; register `builds.24`: "numbering only" |
| 2026-10-21 | Owner starter specification, as "Expansion 23 (proposed) — Generational Legacy & Living History". It is "Approved detailed directive; NEW consolidated implementation starter". Its phases LEG-A..E are "Proposed implementation plan". | `docs/directives/2026-10-21_master_expansion_roadmap.md`; `wip/roadmap-docs:docs/roadmap/23_Legacy.md` (phases P23-A..E) |
| 2026-10-19 | Generational memory and living history, Part I | `docs/directives/2026-10-19_memory_refuges_politics.md` Part I; World Design Rules 014, 017, 021 |

**Scope:**
- the world remembers real events, objects and relationships across generations;
- graves and headstones, family trees, biographies, property histories, the life chronicle;
- dialogue drawn from recorded facts;
- descendants inherit stories, not firsthand memory or skill.

It must not create a second history database: it deepens Expansion 19's memory and uses Expansion 20's event record.

## Implemented

Nothing in Expansion 24 itself. Foundations integrated elsewhere (they must be extended, not duplicated):

| Id | What | Evidence |
|---|---|---|
| GM-01 | Generational memory and historical consequences (the 30-planks chain) | INTEGRATED on the X20 line (`wip/x20-r2r4`, `de61317`), TARGETED TESTS PASSED; target 20 |
| DVW-B2 | Heirs inherit fines and the stain of crimes | INTEGRATED |
| Permanent identity, family succession | | Build 19 / Expansion 20 (ID-01 still IN DEVELOPMENT in the register; WDR-021-C PARTIALLY IMPLEMENTED) |

## Partial

None.

## Remaining approved work (approved, not authorized)

- **WDR-014-C:** graveyards, ancestry, NPC legacy ("Graveyard and headstones with GM-01"). NOT STARTED; target `20+`.
- **WDR-017-C:** generational memory and living history. NOT STARTED; unassigned.
- **DVW-B7:** life chronicle, titles, memorial. NOT STARTED; target `20+`.

  Its "titles" part must respect OD-17 / D36a (2026-10-27): "no chosen hero, title or scripted destiny"; opinions come
  from real deeds.

## Design only / not authorized

Phases, from the owner's starter. They are labelled "proposed" there and have no register ids; records LEG-A..E are
proposed under a new EXP-24 parent:
- **LEG-A:** reconcile Expansion 19's event and belief store; prevent a second history database.
- **LEG-B:** persistent event graph, significance and retention, kinship and provenance links.
- **LEG-C:** dialogue from real history, memorial biographies, graveyard and chronicle presentation.
- **LEG-D:** lineage and heir continuity, political, criminal and professional careers, damaged, rebuilt and sold
  properties.
- **LEG-E:** historical query performance, saves, long multigenerational tests.

The same plan appears as P23-A..E in `23_Legacy.md` and as P24-A..E in `docs/design/ROADMAP_20_27_PRIORITY.md` §7.

## Deferred and superseded

| Item | Status | By |
|---|---|---|
| REQ-GRAVE | SUPERSEDED | WDR-014-C |
| Old number 23 for Legacy | Historical | renumbering 2026-10-23 (OD-30) |
| Starter's note "Much of foundation belongs in 19" | Realised in part: GM-01 landed in the Expansion 20 line | GM-01 |

## Outstanding owner decisions

1. Implementation authorization (none today).
2. The starter's own open items: "Number 23 and final boundary need approval". The number is settled (24); the boundary
   between the Expansion 19/20 foundations and Expansion 24 is still open.

## Dependencies

- **Needs:**
  - Expansion 19 memories and beliefs;
  - permanent identity;
  - Expansion 20's event ids and provenance;
  - Expansion 21's political careers;
  - Expansion 23's crime history.
- **Supplies:** history for later expansions; nothing downstream depends on it in the current order.

## References

- Register:
  - GM-01, DVW-B7, DVW-B2;
  - WDR-014-C, WDR-017-C, WDR-021-C;
  - REQ-GRAVE, OD-30, ROAD-03.
- `docs/design/ROADMAP_20_27_PRIORITY.md` §2, 3, 7.
- `wip/roadmap-docs:docs/roadmap/23_Legacy.md`, `23_Legacy_comparison.md`, `source/23_Legacy.docx`

## Missing sources

None found missing. The owner's starter specification (`23_Legacy.md` and its docx) exists **only** on
`wip/roadmap-docs`, which is merged nowhere. It is the "approved specification" the 2026-10-24 directive refers to, so it
is a single copy at risk (`docs/expansions/MISSING_SOURCES.md`).
