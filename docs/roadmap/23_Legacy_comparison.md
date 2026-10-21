# 23 Legacy: starter compared with the owner's directives and the register

Prepared 2026-10-21 on `wip/roadmap-docs` (documentation only). Compares `docs/roadmap/23_Legacy.md` with its cited
sources: `docs/directives/2026-10-19_memory_refuges_politics.md` Part I sections 1-9 and Parts IV-V, `docs/WORLD_DESIGN_RULES.md`
Rules 009, 014, 017 and 021, the Judgment spec (`My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.txt`, where it
overlaps) and the register (read-only). Code facts read at staging `b3bbb1c`.

**Labels.** **APPROVED** (owner source cited) · **STARTER DRAFT** · **OPEN DECISION** · **FACT**.

## 1. Summary

- The starter follows Part I closely and adds no new mechanic.
- **Boundary with Expansion 19.** The register already places GM-01 in Build 19 ("fit to confirm") as the judgment
  system's event and belief record, while WDR-014-C (graveyards) and DVW-B7 (chronicle, titles, memorial) are `20+`.
  The starter's split (foundation in 19, presentation later) matches the register; the boundary itself is not owner
  confirmed. OPEN DECISION.
- **One contradiction:** the starter calls "cross-generation memory decay" a reversible engineering parameter; the
  Judgment spec reserves decay of judgment for the owner (SJD-Q02, SJD-Q11, spec s.5.2: "Never add automatic decay or
  universal caps without explicit owner decision"). See C1.
- **No `WDR-017-C` compliance entry** exists; Rule 017's compliance is tracked only through GM-01. FACT.

## 2. Section-by-section comparison

| Starter section | Statement (abridged) | Label and source | Register ids |
|---|---|---|---|
| Purpose and integration | The world remembers actual events, causes, consequences across generations | APPROVED: Part I s.1; Rule 017 | GM-01, WDR-017 |
| | Deepens foundations shared with Expansion 19; no duplicate memory system | APPROVED (no duplicates): Part IV s.33, Part V s.36. Sharing with 19: register GM-01 target 19 (agent placement, "fit to confirm") | GM-01, EXP-C, DVW-B1 |
| | Heirs know lineage but do not inherit firsthand memories or skills | APPROVED: Part I s.4; Rule 011 example; PAR-01 | GM-01, PAR-01 |
| Event and provenance model | Stable id, time, location, participants and roles, witnesses, quantities, property, outcomes, causal links, significance, knowledge source | APPROVED: Part I s.2 (the list), s.3 (causal links) | GM-01 |
| | Never claim a plank built a house unless traceable | APPROVED: Part I s.3 | GM-01, WDR-013-C |
| | Bounded storage, significance thresholds, summaries without losing meaningful links | APPROVED: Part I s.2; Part IV s.34 | GM-01 |
| Knowledge and interpretation | Sources: witnessing, participation, conversation, family stories, gossip, records, announcements | APPROVED: Part I s.5 | GM-01, DVW-B1 |
| | Firsthand vs secondhand, rumour vs documented | APPROVED: Part I s.5 | GM-01 |
| | Different interpretations; history influences but never mechanically determines decisions | APPROVED: Part I s.6; Judgment spec s.0 | GM-01, EXP-C |
| Family trees and graves | Ancestry, marriages, descendants, households, inheritance, surnames, property history, deaths; genealogy kept through adoption and surname change | APPROVED: Part I s.4; Rule 021 (FAM-04: genealogy never overwritten) | FAM-04, B8-029, GM-01 |
| | Named interactive headstone with dates, occupation, career, achievements, family links, events, remembrance by a knowledgeable character | APPROVED: Rule 014 bullets 1-3 | WDR-014-C (supersedes REQ-GRAVE) |
| | Graves linked to chronicle, tree, property, village history, Wiki; dead not kept as active agents | APPROVED: Rule 014 bullet 4; Part I s.9 | WDR-014-C, DVW-B7 |
| Dialogue from facts | Reusable grammar and templates over actual records; no invented claims | APPROVED: Part I s.8 ("Do not depend on thousands of manually written lines or expensive external AI calls") | GM-01 |
| | Track discussed topics; credible gaps, distorted rumours, forgotten events | APPROVED: Part I s.5 (incomplete, distorted, disputed, forgotten), s.8 (remember what was discussed) | GM-01 |
| Phases P23-A..E | Audit; causal ids; transmission and dialogue; graves and UI; politics, crime, battles, long runs | STARTER DRAFT (Part V s.37 gives a nine-step order the phases follow) | GM-01, WDR-014-C, DVW-B7 |
| Acceptance | Thomas gives William 30 planks ... descendants explain after both die | APPROVED: Part I s.1, s.38 tests; Rule 009 | GM-01 |
| | Who never learned the story does not know it; rumour is not firsthand | APPROVED: s.38 | GM-01 |
| | Grave biography from real careers and relationships; lineage survives death, adoption, inheritance, save/load | APPROVED: Rule 014; s.38 | WDR-014-C, FAM-04 |
| | Facts influence but do not force judgment or votes | APPROVED: Part I s.6; Part III s.21 | GM-01, VP-01 |
| Open details | Retention thresholds, grammar coverage, cross-generation decay as reversible parameters | STARTER DRAFT; decay conflicts with the Judgment spec (C1) | SJD-Q02, SJD-Q11, SJD-Q12 |

## 3. What the starter adds

- The explicit 19/23 split ("much of the foundation belongs in 19") (STARTER DRAFT, consistent with the register's
  GM-01 placement).
- "Reversible engineering parameters" as the classification for retention, grammar and decay (STARTER DRAFT; see C1).

## 4. What the starter omits

1. **Household affiliations at the time of the event** (Part I s.2: "Family and household affiliations at the time").
   Households change (FAM-01..07 succession and adoption), so the record must snapshot them.
2. **"Later consequences" and "Social significance"** as stored fields (s.2) and the full relation vocabulary:
   "cause, enable, contribute to, follow from, contradict, or commemorate" (s.3).
3. **History that reflects later changes to the house** ("destroyed, rebuilt, sold, or abandoned", s.1). The starter
   tests a destroyed and rebuilt house only in the roadmap text.
4. **The player discovers family history gradually**, not every detail revealed automatically (s.9).
5. **Battles in full**: combatants, factions, leaders, casualties, rescues, injuries, property damage, captures,
   looting, security changes, commemorations (s.7). The starter names battles only in P23-E.
6. **Perspectives without copying every event per NPC** (s.6: "without creating an enormous separate copy").
7. **Existing titles and reputation** and the Interlocking Systems Manifest as integration targets (s.9).
8. **Host authority** for historical events, memory changes and lineage in multiplayer (Part IV s.35).
9. **The 12 memory tests of Part V s.38** (the starter restates four).
10. **Titles** (DVW-B7, APPROVED from the Designing Virtual Worlds proposals the owner chose on 2026-10-19).

## 5. Contradictions and tensions

| # | Issue | Evidence | Label |
|---|---|---|---|
| C1 | Starter: "cross-generation memory decay" is a reversible engineering parameter. Judgment spec s.5.2: "Never add automatic decay or universal caps without explicit owner decision"; SJD-Q02 and SJD-Q11 are open owner decisions. The directive does approve that memories "may become incomplete, distorted, disputed, or forgotten" (s.5). Reconciliation: forgetting **knowledge** (who still knows a story) is approved in principle and its rates are tunable; decay of **judgment** points stays with the owner. | directive s.5; Judgment spec s.5.2; register SJD-Q02, SJD-Q11 | OPEN DECISION for judgment decay; engineering default for knowledge retention |
| C2 | Existing code already decays relationship regard without contact (`Relations.dawn`, `decay_per_day` 0.5, half for regard), which the Judgment spec would treat as an owner-level choice. | FACT: `relations.gd` dawn; balance.json `relations.decay_per_day` | To be reconciled under SJD-Q02 (see `19_SJD_RECONCILIATION.md`) |
| C3 | Placement: GM-01 in 19 is an agent placement marked "fit to confirm"; WDR-014-C and DVW-B7 are 20+; the starter proposes 23. | register GM-01, WDR-014-C, DVW-B7 | OPEN DECISION |

## 6. Missing technical decisions (open questions)

Owner-level:
- **Q-LEG-1** Confirm the boundary: event store, knowledge provenance and family transmission in 19 (GM-01), graves,
  chronicle and memorial presentation later (WDR-014-C, DVW-B7).
- **Q-LEG-2** Which facts are permanent (never forgotten by the world record even if no NPC remembers): deaths,
  marriages, offices, crimes convicted, buildings? Part IV s.34 requires "a major historical event should remain
  discoverable even if the original participants have died".
- **Q-LEG-3** Graveyard placement and growth on the fixed village map (Rule 014 "expanding burial grounds"); whether a
  church is part of it (DVW-B12 "Church" is a BLOCKED proposal).
- **Q-LEG-4** How much family history the player sees by default (s.9 gradual discovery).

Engineering-level (documented defaults): significance thresholds and aggregation; event-store schema with stable ids
shared with SJD's `WorldEvent` (spec s.3.1 already lists causal parents, witnesses, resource deltas); retention and
summarisation; template grammar coverage; save-version bump with fixtures.

## 7. Repository facts for P23-A

- FACT: no headstone, graveyard, chronicle or event id in `game/scripts` (grep at `b3bbb1c`).
- FACT: lineage exists: `NPC`/`PlayerState`/`Animal` carry born, sex, mother, father, partner, children (save 14,
  B8-029); heirs (`life.gd`), `FORMER_PLAYER` (-3) links a dead player of an earlier generation; guardianship and
  adoption keep genealogy (FAM-04).
- FACT: `NPC.memory` holds at most 8 strings, keeping "met ..." lines (`npc.gd::remember`); `World.witness` writes
  "saw <player> ..." lines. No structured, causal or transmissible record.
- FACT: deaths are logged and inherited (WDR-014-C implementation note: "No graveyard or headstones; deaths are logged
  and inherited (B8-029)").
