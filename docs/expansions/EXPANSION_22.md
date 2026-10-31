# Expansion 22: Settlement Advancement Phase 2

**Current status:**
- The audit is done (E22-P1, a document).
- The architecture decisions E22-OD-01 and E22-OD-02 are approved as **design only**.
- E22-OD-03..05 have approved `[FUTURE]` direction.
- **No implementation is authorized.** Priority 4 of the expansion order.
- **Next authorized phase: none until the owner authorizes it.**

Status vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 (DOC-RECON-01).

## Current approved scope

| Date | Owner decision (quoted) | Source |
|---|---|---|
| 2026-10-31 | "Expansions 22–27: Do not begin implementation without explicit authorization." | `docs/directives/2026-10-31_documentation_reconciliation.md` |
| 2026-10-30 | "Do not begin Expansions 22–27." | `docs/directives/2026-10-30_master_development_resumption.md` §11 |
| 2026-10-27 | D27-D29 (E22-OD-03, 04, 05), all `[FUTURE]`, design direction only | `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md` |
| 2026-10-24 | ROAD-Q4: "Expansion 22 owns the shared building-condition, damage, deterioration, and repair infrastructure. Expansion 25 must reuse that infrastructure…" | `docs/directives/2026-10-24_owner_roadmap_question_decisions.md`; E22-CONDITION |
| 2026-10-24 | ROAD-Q2: "Regional travel-time route banditry that depends on Expansion 22's completed route infrastructure belongs in Expansion 22, Phase E." Also: "Settlement growth and decline should emerge from available resources… Do not create artificial development milestones…" | same; `2026-10-24_expansion_roadmap_reprioritization.md` |
| 2026-10-23 | Renumbering: "Expansion 22 is now Settlement Advancement Phase 2, building directly on the systems released in Build 18." "Do not rebuild or duplicate any functionality already delivered in Build 18." E22-OD-01 (hybrid regional simulation) and E22-OD-02 (continuous geography): "Both are design approvals only. They do not authorize implementation." "Do not begin implementation until we review the audit and approve the architecture." | `docs/directives/2026-10-23_expansions_22_23_kickoff.md` |

**Scope** (kickoff directive):
- A region of independent settlements that grow, stagnate, decline or disappear through simulated causes.
- Phases:
  - A: architecture and regional ledger, with no second ledger;
  - B: capability model;
  - C: abstract regional settlements, with promote and demote;
  - D: settlement development and abandonment;
  - E: persistent regional networks.
- The primary authority is the standalone specification
  `docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf` (text beside it).

## Implemented

| Id | What | Evidence |
|---|---|---|
| E22-P1 | Read-only audit of the specification against Build 18: phases A-E dependency map, proposed regional data model | `docs/design/EXPANSIONS_22_23_AUDIT.md` §1-3, 5-6 (staging). Register: IMPLEMENTED ON TASK BRANCH; it is a document, awaiting the owner's review. |

**Delivered in Build 18 (Expansion 18; do not rebuild):**
- SET-A, SET-B, SET-D INTEGRATED;
- SET-C PARTIALLY IMPLEMENTED;
- capability evaluation;
- worker experience;
- `CapabilityHook` (neutral factors);
- off-map settlements (`offmap.gd`);
- road trade and couriers.

Route stand-ins in `settlement/routes.gd` and `regional.gd` are present on `wip/expansion20` and need re-validation (audit §5).

## Partial

None for Expansion 22 itself. From Build 18:
- SET-C (abstract regional economy) is partial;
- SET-E (persistent inter-settlement network) is NOT STARTED and was deferred under Q18-8. The audit maps it onto phase E.
  That mapping is an agent reading, not an owner assignment.

## Remaining approved work (approved, not authorized)

- **E22-OD-01.** Hybrid regional simulation: detailed nearby NPCs; abstract distant settlements that keep identities,
  households, property, economic state and history. Design only.
- **E22-OD-02.** Continuous geography: streamed regions, persistent world coordinates, persistent player and NPC
  changes. Design only.
- **E22-CONDITION.** The one shared building-condition, damage, deterioration and repair system, which 25 and 26 reuse.
  NOT STARTED.
- **E22-OD-03 (D27).** Skills transfer or die out through experience, teaching, apprenticeship and records; no automatic
  inheritance. `[FUTURE]`.
- **E22-OD-04 (D28).** Future physical caravans with capacity and danger; the six-day abstraction stays until an approved
  regional stage. `[FUTURE]`.
- **E22-OD-05 (D29).** Distant settlements may grow, decline or be abandoned, constrained by land, housing and food.
  `[FUTURE]`.
- **Phases A-E**, as written in the owner's kickoff directive. They have no register ids; records are proposed. Each waits
  for the owner's architecture approval.
- **Route banditry on real routes** (phase E), built on Expansion 23's faction records (E23-SCOPE).
- **SET-D-MULTIGEN** (multigenerational verification, owner 2026-10-23, "deferred to a later build"), target `20+`.

## Design only / not authorized

- The proposed regional data model (audit §3, PROPOSAL).
- The recommended next assignment (audit §6): an architecture document for E22-OD-01 and E22-OD-02, then region-wide
  person ids behind a switch. It waits for the owner's review.

## Deferred and superseded

| Item | Status | By |
|---|---|---|
| Kickoff header "Authorization: … safe isolated foundation work" | Narrowed by the owner's answer the same day: "Do not begin implementation until we review the audit and approve the architecture", then 2026-10-30 "Do not begin Expansions 22–27" | owner 2026-10-23, 2026-10-30 |
| REG-CIRC-D1 (coins flowing one way into Garton) | DEFERRED (decision disposition) | register |
| Old number 22 = Bandits (OD-30, 2026-10-21) | Historical; Bandits are now 23 | renumbering 2026-10-23 (OD-30 `owner_answer`) |

## Outstanding owner decisions

1. Review of the E22-P1 audit and **approval of the architecture**, as the owner required before any implementation.
2. Implementation authorization (none today).
3. Q18-11 capability factors (provisional at 1.0; affects phase B). This is a Build 18 decision, listed as a dependency.

## Dependencies

- **Needs:**
  - identity (Build 19, done; ID-01 still IN DEVELOPMENT in the register);
  - Expansion 20 (construction purchasing, event record and actor resolver);
  - Expansion 21 (tolls, jurisdiction);
  - Expansion 23 (faction records, for route banditry in phase E).

  Priority order: 23 comes before 22.
- **Supplies:**
  - regional map and geography (25's rivers should be designed on it to avoid two map migrations);
  - building condition (25, 26);
  - lairs and geography (26).

## References

- Register:
  - E22-P1, E22-OD-01..05, E22-CONDITION;
  - SET-C, SET-E, SET-D-MULTIGEN, EXP-B;
  - ROAD-Q2, ROAD-Q4, OD-30, ROAD-03.
- `docs/design/EXPANSIONS_22_23_AUDIT.md`
- `docs/design/ROADMAP_20_27_PRIORITY.md` §2, 3, 7.
- `docs/directives/2026-10-23_expansions_22_23_kickoff.md`

## Missing sources

- The Expansion 18 specification (PDF, 6 pages, and TXT) is on staging.
- No separate "Phase 2" specification exists on any branch. Phase 2's scope is the kickoff directive plus that PDF. If the
  owner holds a further Settlement Advancement Phase 2 document, it is a MISSING SOURCE requiring recovery
  (`docs/expansions/MISSING_SOURCES.md`).
