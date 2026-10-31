# Expansion 23: Bandit Factions and Criminal Careers

**Current status:**
- The BAN-A audit is done (E23-BANA, a document).
- E23-SCOPE is approved.
- The faction direction E23-OD-01 is `[FUTURE]`.
- BAN-B..E are **not authorized**.
- Priority 3, after 21.
- **Next authorized phase: none until the owner authorizes it.**

Status vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 (DOC-RECON-01).

## Current approved scope

| Date | Owner decision (quoted) | Source |
|---|---|---|
| 2026-10-30 | "Do not begin Expansions 22–27." | `docs/directives/2026-10-30_master_development_resumption.md` §11 |
| 2026-10-27 | D30 (E23-OD-01) `[FUTURE]`: "Future bandit factions may have members, territory and leaders, with real inventory, crimes and social reintegration; no magical spawn engine; existing bandit behaviour and the SIM-F3 fix stay." | `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md` |
| 2026-10-24 | ROAD-Q2 / E23-SCOPE: "Expansion 23 may implement banditry, crime, and related economic consequences within the village, existing roads, and currently represented settlements. … Avoid temporary systems that will need to be discarded later." | `docs/directives/2026-10-24_owner_roadmap_question_decisions.md` |
| 2026-10-24 | "Extend the existing bandit and judgment systems rather than replacing them. … Preserve the approved bandit survival, food-purchasing, healing, and combat behavior from Build 19." | `docs/directives/2026-10-24_expansion_roadmap_reprioritization.md` |
| 2026-10-23 | Renumbering to 23; "BAN-A audit and requirements reconciliation only"; "Do not implement new criminal actions or faction behavior in this phase." | `docs/directives/2026-10-23_expansions_22_23_kickoff.md` |
| 2026-10-21 | Owner starter specification, as "Expansion 22 (proposed)". Banditry is a possible livelihood, with real resources, faction fragmentation and an orphan-clan fallback. Phases BAN-A..E are labelled "Proposed implementation plan". | `docs/directives/2026-10-21_master_expansion_roadmap.md`; `wip/roadmap-docs:docs/roadmap/22_Bandits.md` |

The governing rule is World Design Rule 016, tracked by the compliance record WDR-016-C, which is NOT STARTED.

## Implemented

| Id | What | Evidence |
|---|---|---|
| E23-BANA | BAN-A audit: Rule 016 capabilities against Build 18 code, and a proposed faction architecture | `docs/design/EXPANSIONS_22_23_AUDIT.md` §4. Register: IMPLEMENTED ON TASK BRANCH (document, awaiting owner review). |

**Related systems already integrated elsewhere** (they must be extended, not duplicated):
- X20-BANDIT-AI, INTEGRATED on `wip/expansion20` (`dd7dca1`, TARGETED TESTS PASSED), under the SJD-H C4 directive of
  2026-10-31;
- GP-CRIME-PURSUIT, INTEGRATED (pursuit, manhunts, wanted status);
- DVW-B2, INTEGRATED (fines for assault and killing);
- the Build 19 bandit food, healing and blocked-chase rules;
- FAM-07, the orphan-clan fallback.

## Partial

The BAN-A audit (written against Build 18) is **partly stale**. Its rows "Guard investigation … Absent" and "no fines for
assault or killing" predate GP-CRIME-PURSUIT, DVW-B2 and X20-BANDIT-AI. Refresh it against the frozen baseline before
BAN-B. This is a document fix, not new scope.

## Remaining approved work (approved, not authorized)

- **E23-SCOPE.** Village, existing roads and represented settlements only; no route-banditry stand-in on
  `routes.gd`/`regional.gd`. NOT STARTED.
- **E23-OD-01 direction (D30).** Members, territory, leaders, real inventory, social reintegration. `[FUTURE]`.
- **WDR-016-C.** Compliance with Rule 016. NOT STARTED.
- **FAM-08.** A young adult raised in the clan decides their own future. Target `20+`; NOT STARTED.

## Design only / not authorized

- **BAN-B..E**, from the owner's 2026-10-21 starter, which itself calls them "Proposed implementation plan" (records
  proposed):
  - BAN-B: faction identity, membership, hierarchy, safehouse ownership, persistent resources;
  - BAN-C: career actions, recruitment, theft and raids, resale, suspicion and response;
  - BAN-D: rank, challenge, leadership, schism, succession;
  - BAN-E: economy, judgment and politics integration; long runs.
- **The P22-A..F list** in `docs/roadmap/22_Bandits.md` is a variant of the same plan under the old number.
- **Acceptance** in the starter:
  - no invented loot or currency;
  - stolen items keep provenance and custody;
  - factions can fail and disband;
  - guards act only on knowable crimes;
  - child dependents gain no adult combat abilities.
- **The audit's proposed faction architecture** (audit §4, PROPOSAL).

## Deferred and superseded

| Item | Status | By |
|---|---|---|
| FR-09, crime from desperation | DEFERRED ("no desperation crime yet") | owner 2026-10-17 |
| Route banditry over continuous geography | Moved out of 23 into 22 phase E | ROAD-Q2 (2026-10-24) |
| REQ-BANDIT | SUPERSEDED | WDR-016-C |
| Old number 22 for Bandits | Historical | renumbering 2026-10-23 (OD-30) |

## Outstanding owner decisions

1. Review of the BAN-A audit; approval of the faction architecture.
2. Implementation authorization (none today).
3. Detail still open under the starter's own "Unresolved decisions": leadership-challenge rules, jurisdiction, faction
   numbers. E23-OD-01 gives only `[FUTURE]` direction, and the proposal "one faction to start" is not approved.

## Dependencies

- **Needs:**
  - Expansion 19 (reputation, judgment);
  - Expansion 20 (crimes as events with provenance; stolen-goods custody and fencing, OD-LE-09);
  - Expansion 21 (legal record, constable and guards: Q-POL-8 written as "before Expansion 22" under the old number).
- **Supplies:**
  - faction records for 22-E route banditry;
  - crime history for 24.

## References

- Register:
  - E23-BANA, E23-OD-01, E23-SCOPE;
  - WDR-016-C, FAM-07, FAM-08, FR-09;
  - X20-BANDIT-AI, GP-CRIME-PURSUIT, DVW-B2;
  - ROAD-Q2, OD-30.
- `docs/design/EXPANSIONS_22_23_AUDIT.md` §4
- `docs/design/ROADMAP_20_27_PRIORITY.md` §2, 3, 7.

## Missing sources

None blocking. The owner's starter `22_Bandits.md`/`.docx` exists only on `wip/roadmap-docs`; see
`docs/expansions/MISSING_SOURCES.md`.
