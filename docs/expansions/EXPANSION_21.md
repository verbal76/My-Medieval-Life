# Expansion 21: Village Politics and Civic Authority

**Current status:** scope approved. Phase 1 (P21-00, P21-01, P21-02) is built on a stranded task branch. Everything else is
**ON HOLD**, and nothing more is authorized. **Next authorized phase:** Build 27. That build starts only after Build 26 is
frozen and the owner explicitly authorizes Expansion 21's implementation.

Status vocabulary and precedence: `docs/expansions/README.md`. The register (`docs/requirements/requirements.json`) holds
the same statuses. Reconciled 2026-10-31 (DOC-RECON-01) against staging `aeaa012`, `origin/wip/expansion21-preparation`
`8ac88f5` and `origin/wip/expansion20` `ad281dc` (read only).

## Current approved scope

These owner decisions apply, newest first:

| Date | Owner decision (quoted) | Source |
|---|---|---|
| 2026-10-31 | "Build 27 — Resume expansion development. Begin Expansion 21 only after Build 26 is validated and frozen and I explicitly authorize implementation." | `docs/directives/2026-10-31_documentation_reconciliation.md` §4; BUILD-SEQ-25-27 |
| 2026-10-30 | "Keep Expansion 21 politics isolated and on hold unless its work is explicitly required by an already approved dependency." | `docs/directives/2026-10-30_master_development_resumption.md` §11 |
| 2026-10-28 | "Do not start Expansion 21." | `docs/directives/2026-10-28_x20_checkpoint_build_and_pause.md` |
| 2026-10-27 | "Expansion 21 remains the next major expansion. Its previously approved initial scope is preserved: Civic and political audit. Civic records. Mapping existing owner decisions. Political behavior disabled until authorized." It was also called "a development-priority decision, not a cancellation of Expansion 21." | `docs/directives/2026-10-27_complete_expansion20_first.md` §10; X20-COMPLETE |
| 2026-10-27 | Q-POL-6-CONFLICT, option B: "There will be no impeachment, recall, or political removal mechanics for the mayor. The mayor serves the established four-game-year term unless death or permanent absence ends that term early." | `docs/directives/2026-10-27_q_pol_6_conflict_resolution.md` |
| 2026-10-27 | D19-D26: the Q-POL answers, all `[FUTURE]` except Q-POL-7 `[CURRENT]` | `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md` |
| 2026-10-24 | Priority "20 → 21 → 23 → 22 → 24 → 25 → 26 → 27". For 21: "Preserve previously approved election, office, eligibility, and term rules." | `docs/directives/2026-10-24_owner_roadmap_question_decisions.md`, `2026-10-24_expansion_roadmap_reprioritization.md` |
| 2026-10-23 | Phase 1 only (P21-00 audit, P21-01 isolated foundations, P21-02 decision map): "Keep all new political behavior disabled." and "Do not merge into staging or main, activate new gameplay systems, or publish builds." | `docs/directives/2026-10-23_expansion21_phase1_authorization.md` |
| 2026-10-23 | P21-MAYOR: "Mayors are elected. Mayoral terms last four in-game years. Incumbents may seek reelection. Established adult residents are eligible to vote. Eligible voters are also eligible to run for mayor." | `docs/directives/2026-10-23_expansions_19_21_consolidated_design.md` |
| 2026-10-19 | VP-01: living village politics, covering offices, individual NPC voting, elections and civic authority. Covered by World Design Rules 015 and 019. | `docs/directives/2026-10-19_memory_refuges_politics.md` Part III |

**Scope:** villages govern themselves; officials do real work; public resources are finite; leadership changes through the
simulation; the player is a participant, not automatically the ruler.

**Not in this scope without separate authorization:** courts, corruption and campaigning beyond a platform
(`docs/design/ROADMAP_20_27_PRIORITY.md` §2).

## Implemented

Nothing is integrated into any build. P21-00, P21-01 and P21-02 are IMPLEMENTED ON TASK BRANCH only (see Partial).

## Partial

| Id | What exists | Evidence | Validation |
|---|---|---|---|
| P21-00 | Government architecture audit (document) | `wip/expansion21-preparation` `64317eb`: `docs/expansion21/P21_READINESS.md`, `PRELIMINARY_PLAN.md` | Not tested (a document) |
| P21-01 | Civic records: office registry, tenure and succession events, legacy record. Switched off (`game/data/civic.json` `enabled: false`); it grants no powers. | `8ac88f5`: `game/scripts/core/civic/civic_records.gd`, `civic_offices.gd`, `game/tests/civic_records_test.gd` | TARGETED TESTS PASSED on `8ac88f5`: civic_records 48, world 339, migration 92, save_transfer 21, family 51, succession 26, treasury 23. Determinism gate identical; 30 days identical with the records on and off. |
| P21-02 | Political decision map and the 12-topic owner decision packet | `64317eb` | Not tested (a document) |

- **The branch is stranded.** Its base is Build 18 (`239bdff`, via SYNC-18 `983d80f`). It is not in `wip/expansion20`;
  `civic_records.gd` is absent there. Batch 0 (ROAD-Q5, approved with conditions on 2026-10-24) was never done. Bringing
  the branch forward is expected to conflict only in `game/scripts/core/world.gd` (`to_dict`/`load_dict` and the hooks).
- **Civic groundwork already in the live game** (not Expansion 21 work, listed so it is not rebuilt):
  - the manor treasury: TREAS-01 INTEGRATED;
  - predictable taxes: DVW-B5 INTEGRATED;
  - the reeve's evening business and its succession;
  - guards and their pay: `manor_work.gd`, `npc_brain.gd`;
  - crime pursuit: GP-CRIME-PURSUIT INTEGRATED;
  - fines for assault and killing: DVW-B2 INTEGRATED.

  WDR-015-C is PARTIALLY IMPLEMENTED for this reason.

## Remaining approved work (approved, not implemented, not yet authorized)

- **P21-MAYOR.** Elected mayor with four-game-year terms. Established adult residents vote and stand. Incumbents may run
  again. An early vacancy calls a replacement election as soon as possible; the longest-serving eligible civic official
  holds authority meanwhile. Status: NOT STARTED.
- **VP-01** (umbrella). Offices, individual NPC voting, elections and civic authority; WDR-015-C and WDR-019-C compliance.
  Status: NOT STARTED.
- **Approved design direction, all `[FUTURE]`**, which means design only:
  - Q-POL-1 and P21-STRUCTURE (D19): elected mayor and council long term; the manor and reeve kept until a transition is
    drafted and authorized.
  - P21-RESIDENCY (D20): voting after 8 game days of residence; council candidacy after 16.
  - Q-POL-4 (D21): secret ballots; aggregate totals published.
  - Q-POL-5 (D22): runoff, then service tenure, then age; an explicit deterministic fallback.
  - Q-POL-6 (D23) with Q-POL-6-CONFLICT B: no impeachment or recall.
  - Q-POL-8 (D25): mayor and council select a constable who commands the guards under existing law.
  - Q-POL-9 (D26): the mayor proposes taxes within the existing bands; the council approves major items.
- **Q-POL-7 (D24, `[CURRENT]`).** "Real voter choices must wait for operational tested individual Judgment System; no
  interim omniscient scripted political vote engine." Judgment is integrated on `wip/expansion20`, but SJD-H (Gate H
  owner review) is not done.

## Design only / not authorized

- **Later phases**, as proposed by the agent in `docs/design/ROADMAP_20_27_PRIORITY.md` §2 and §7. They have no register
  ids yet; records are proposed:
  - P21-03: elections and the voter model;
  - P21-04: treasury, taxes and spending through Expansion 20 transactions;
  - P21-05: guards with real duties.
- **VP-01A..E:** stages proposed by the agent in the preliminary plan. They are PROPOSED and overlap P21-03..05; only one
  stage plan should survive.
- **The owner's starter specification** `docs/roadmap/21_Politics.md` (2026-10-21, on `wip/roadmap-docs`). Its phases
  P21-A..E and the master roadmap's POL-A..E are labelled "proposed" in the owner's own document.

## Deferred and superseded

| Item | Status | Newer decision |
|---|---|---|
| Plan item **A9** on `wip/expansion21-preparation` (`docs/expansion21/PRELIMINARY_PLAN.md`): "removal or loss of support through the established system"; also `P21_READINESS.md` row 5 ("removal") | **SUPERSEDED for the mayor** (the branch is not edited) | Q-POL-6-CONFLICT option B (owner, 2026-10-27): no impeachment, recall or political removal of the mayor, automatic or manual; misconduct affects reputation, support and future elections only. The owner limited this to mayoral removal ("other political mechanics unchanged"), so the 2026-10-19 permission still stands, unbuilt, for other offices. |
| 2026-10-19 "Where appropriate, allow removal from office…" (`2026-10-19_memory_refuges_politics.md` l.749) | SUPERSEDED for the mayor; preserved verbatim | Q-POL-6-CONFLICT B |
| Batch 0 timing (ROAD-Q5: "after Build 19's playtest acceptance") | Overtaken by events (Expansion 20 proceeded without it) | BUILD-SEQ-25-27 (2026-10-31). Open item 2 below asks the owner where Batch 0 now belongs. |
| The `EXPANSIONS_20_21_DECISION_PACKET.md` statement "neither expansion is authorized" | Historical | Phase-1 authorization (2026-10-23), then the hold (2026-10-27 onward) |
| Old numbering in Q-POL-8's title: "before Expansion 22" | Historical number (bandits were 22 on 2026-10-21) | Read it as Expansion 23 (renumbering 2026-10-23, OD-30) |

## Outstanding owner decisions

1. Lifting the hold and authorizing implementation in Build 27 (BUILD-SEQ-25-27).
2. **Where Batch 0 belongs.** Bringing `8ac88f5` onto the frozen baseline with the civic switch off could be Build 26
   "recover the relevant stranded work", or the first step of Build 27. The 2026-10-30 "keep … isolated and on hold"
   leaves this open. Not guessed.
3. Office powers, election formulas, tax rates and punishments, which the 2026-10-23 directive says must not be built
   "without owner approval". The `[FUTURE]` answers give direction, not final numbers. Examples:
   - D22's "deterministic equality fallback must be explicit before final implementation";
   - campaign rules;
   - courts.
4. SJD-H (the Judgment owner review), which gates real votes under Q-POL-7.

## Dependencies

- **Needs:** Expansion 19 judgment live and owner-reviewed (Q-POL-7, SJD-H); Expansion 20's transactions, event record
  and household interests (taxes, payroll, purchasing); GM-01 and DVW-B1 (VP-01 `depends_on`).
- **Supplies:** offices, the legal record, guard duties, tolls and jurisdiction, to:
  - 22-E;
  - 23 (legal record, guards);
  - 24 (political careers);
  - 26 (reeve's or mayor's bounties).

## References

- Register:
  - VP-01;
  - P21-00, P21-01, P21-02, P21-MAYOR, P21-RESIDENCY, P21-STRUCTURE;
  - Q-POL-1..9, Q-POL-6-CONFLICT;
  - VP-01A..E;
  - WDR-015-C, WDR-019-C;
  - ROAD-03, ROAD-Q5;
  - X20-COMPLETE, BUILD-SEQ-25-27.
- Design:
  - `docs/design/ROADMAP_20_27_PRIORITY.md`;
  - `docs/design/EXPANSIONS_19_21_ALIGNMENT.md` §4;
  - `docs/design/DECISION_CONTINUITY_REVIEW_2026-10-27.md` §3.
- Branches: `origin/wip/expansion21-preparation` `8ac88f5` (stranded); `origin/wip/roadmap-docs` `e1e8236`
  (`docs/roadmap/21_Politics.md`, `source/21_Politics.docx`).

## Missing sources

None blocking. The owner's starter specification and its docx exist only on `wip/roadmap-docs`, which is merged nowhere.
The phase-1 work exists only on `wip/expansion21-preparation`. Both are single copies at risk, listed in
`docs/expansions/MISSING_SOURCES.md`.
