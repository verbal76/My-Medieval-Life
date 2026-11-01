# 21 Politics: starter compared with the owner's directives and the register

Prepared 2026-10-21 on `wip/roadmap-docs` (documentation only; no code, data or register change). Compares
`docs/roadmap/21_Politics.md` (the owner's starter, extracted from `21_Politics.docx`) with its cited sources:
`docs/directives/2026-10-19_memory_refuges_politics.md` Part III sections 18-32 (and Parts IV-V where they bind
politics), `docs/WORLD_DESIGN_RULES.md` Rules 015, 019 and 022, and `docs/requirements/requirements.json` (read-only).
Code facts were read in `game/` at staging `b3bbb1c` (identical to this branch's `game/`).

**Labels.** **APPROVED** (an owner source, cited). **STARTER DRAFT** (in the starter, not in any owner source; a
proposal until the owner confirms it). **OPEN DECISION** (no owner answer exists; listed as a question, never as an
approval). **FACT** (what the code or register says today; a record, not a design statement).

## 1. Summary

- The starter is faithful to the directive's intent; it contains no statement that contradicts an owner source.
- It is a compression: of the directive's 14 required tests (section 32) it restates five, and it drops several
  explicit obligations (no indefinite vacancies, vote privacy as the default, host authority, Wiki entries,
  the opinion model derived from circumstances). These are listed in section 4 so they are not lost.
- Two real conflicts exist between the record and the starter or roadmap, both about **placement**, not content
  (section 5): the directive said "actively begin their implementation" (2026-10-19), the register places VP-01 at
  `20+`, and the starter numbers it 21. The owner has not assigned a build to politics.
- **Missing register entry.** There is no `WDR-019-C` compliance entry (only `WDR-013-C` to `WDR-016-C` and
  `WDR-022-C` exist among rules 013-022); Rule 019's compliance is tracked only through VP-01. FACT.

## 2. Section-by-section comparison

| Starter section | Statement (abridged) | Label and source | Register ids |
|---|---|---|---|
| Purpose and authority | Village governs itself without the player | APPROVED: directive s.18, s.29; Rule 019 | VP-01, WDR-019, EQ-04 |
| | Mayor/leader, constable, guard captain, guard open to NPCs and player | APPROVED: directive s.19 | VP-01, WDR-015-C |
| | Council, bailiff, tax collector, clerk, steward | APPROVED: Rule 015 bullet 1 ("as applicable") | WDR-015-C |
| | Selection varies by local structure | APPROVED: directive s.19 ("configurable or extensible") | VP-01 |
| | Mayor cannot conjure supplies, guards or money; a guard needs real equipment and a funded role | APPROVED: directive s.25, s.27; Rule 013; Rule 022 | WDR-013-C, TREAS-01, EQ-04 |
| Election model | Individual evaluation from firsthand knowledge, testimony, family memory, gossip, conduct, competence, security, economics; abstention allowed | APPROVED: directive s.20 steps 1-11 | VP-01, GM-01, DVW-B1 |
| | Count actual ballots; no manufactured totals | APPROVED: directive s.20 | VP-01 |
| | Persist nomination ... succession; reload never duplicates an election | APPROVED: directive s.24 | VP-01 |
| | Campaigning: service, promises, gatherings, endorsements, debates; not a click minigame; NPCs campaign | APPROVED: directive s.23 | VP-01 |
| Public finance and law | Treasury from taxes, rents, fees, fines, duties; wages and works consume real resources; unfunded services may fail | APPROVED: Rule 015 bullet 3; directive s.27; Rule 022 | TREAS-01, STALL-05, DVW-B5, WDR-015-C |
| | Officeholders direct spending, guard priorities, projects, taxation, appointments "subject to established rules" | APPROVED: directive s.25 | VP-01, OD-LE-06 |
| Judgment and history | Inherited favour or grievance may tip but never override | APPROVED: directive s.21 | GM-01, EXP-C |
| | Secret crime counts only when credibly discovered | APPROVED: directive s.30 | PAR-05, PICK-01, GM-01 |
| | Track promises, scandals, results, careers, projects | APPROVED: directive s.26, s.28 | VP-01, GM-01, WDR-014-C |
| Phases P21-A..E | Audit; office and treasury state; voting lifecycle; candidacy and UI; policies, history, long runs | STARTER DRAFT (the directive's s.37 gives a ten-step order the phases broadly follow) | VP-01 (no child entries yet) |
| Acceptance | Reproducible ballot or abstention; counted votes equal results | APPROVED: s.20, s.32 tests 1-2 | VP-01 |
| | Descendant remembers the 30 planks but may vote against the family | APPROVED: s.21, s.32 tests 4-5, 7 | VP-01, GM-01 |
| | Projects only with actual resources; guards unpaid without funds | APPROVED: s.27, s.32 test 10 | TREAS-01 |
| | Death in office triggers succession; history survives save/load | APPROVED: s.24, s.32 tests 9, 13 | VP-01, EQ-04 |
| Open implementation details | Terms, franchise, campaign timing, vote privacy, succession mechanisms need defaults or owner decisions | STARTER DRAFT wording; the items themselves are OPEN DECISIONS (section 6) | - |

## 3. What the starter adds beyond the originals

- The named phases P21-A..E and the roadmap's POL-A..E (two parallel naming schemes for the same work). STARTER DRAFT.
  Recommendation: keep one scheme; the register convention is child ids under the parent (e.g. `VP-01A..E`), created
  only when the work is scheduled.
- Coupling to the Living Economy ("Political decisions change the living economy"; roadmap: "using Living Economy
  interfaces"). STARTER DRAFT: the directive requires connection to "the existing economy" (s.27), not to EXP-D,
  whose placement is itself undecided (OD-LE-01).
- "Inheritance" as an office succession method appears in Rule 015 (APPROVED) but not in the directive; the starter
  keeps it. No conflict.

## 4. What the starter omits from the originals (to be kept in scope)

All APPROVED, directive 2026-10-19 Part III unless noted:
1. **No indefinite vacancies** (s.24: "Do not leave civic offices vacant indefinitely because the player ignores politics").
2. **Opinions derived from circumstances**, changing as conditions change; never random (s.22: farmer, merchant, guard,
   struggling household, landowner, bandit victim).
3. **Vote privacy as the default** (s.31: do not expose private votes "unless the settlement's voting rules explicitly
   permit it") and the public election interface (offices, dates, candidates, platforms, eligibility, results,
   totals, officeholders, terms remaining).
4. **Believable feedback** on why a campaign failed, without revealing hidden simulation (s.31).
5. **Candidates do not know how every villager will vote** (s.30).
6. **Removal from office and loss of support** through the established system (s.26).
7. **All 14 automated tests of s.32** plus the multigenerational Downs/Miller scenario "not a hardcoded special case";
   the starter keeps 5.
8. **Host authority** for elections, appointments and vote counting in future multiplayer (Part IV s.35).
9. **Wiki entries** for offices, elections, voting, campaigning, civic employment, guard careers, taxation, political
   reputation, succession and historical leadership; "no mechanic complete" until Wiki, developer docs and manifest
   agree (s.39). The starter's handoff checklist mentions the Wiki only generically.
10. **Domestic workers** with real duties, needs and compensation (Rule 015 bullet 7).
11. **Friends back you in votes** (CRT-06, owner answers 2026-10-19: "Back you up"; PARTIALLY IMPLEMENTED).

## 5. Contradictions and tensions

| # | Issue | Evidence | Label |
|---|---|---|---|
| C1 | **Timing.** The directive says "actively begin their implementation" and "Start meaningful implementation work, not just planning documents" (s.37). The register keeps VP-01 APPROVED — NOT STARTED, `target_build 20+`, reason: "voting weighs judgment, so after 19" (an agent placement during the ROAD-01 reconciliation). The starter numbers it 21. | directive s.37; register VP-01, ROAD-01 | OPEN DECISION: the owner has not placed politics in a build. ROAD-01 names only 15-19, so 20+ is consistent with it, but the 2026-10-19 "begin now" instruction is unreconciled. |
| C2 | **Who governs today.** The code has a **reeve** (the manor's officer) and no mayor; the reeve's successor is chosen by "the trades' rule, used until the owner sets one for the office (an open policy question)" (`npc_brain.gd::_reeve_succession`). Whether the village is a manor with an appointed reeve, a chartered village with an elected mayor, or both, is not decided (DGA-D8 "era, county, political status, map scale" is BLOCKED on the owner). | FACT: `npc_brain.gd` lines ~2525-2552; register DGA-D8 | OPEN DECISION |
| C3 | **Taxes as policy.** The starter lets officeholders set taxation; DVW-B5 (APPROVED, target 18) asks for predictable, announced taxes with hysteresis. A mayor changing rates must respect DVW-B5's predictability. | register DVW-B5 | Not a contradiction; a constraint to carry into P21-E |
| C4 | **Manor authority vs elected authority.** OD-LE-06 ("permissible manor interventions and political authority") is BLOCKED; politics and the Living Economy both claim the manor's levers. | register OD-LE-06 | OPEN DECISION |

## 6. Missing technical decisions (open questions, not approvals)

Material, owner-level (irreversible gameplay semantics):
- **Q-POL-1** Political structure of the starting settlement: manor with reeve, elected mayor, council, or a mix; and
  what the lord (if any) retains (C2, DGA-D8).
- **Q-POL-2** Franchise: who may vote (age, residency, household head or every adult, property, sex-neutral by
  default as CRT-07 already treats sexes equally), and whether bandits and clan members vote.
- **Q-POL-3** Office terms and election calendar (season, years); by-elections on death or resignation.
- **Q-POL-4** Vote privacy (secret ballot by default per s.31) and what totals are public.
- **Q-POL-5** Tie resolution (re-vote, seniority, lot with the seeded RNG, incumbent keeps office).
- **Q-POL-6** Removal from office: recall vote, council, crime conviction, lord's dismissal.
- **Q-POL-7** Build placement (C1) and whether politics waits for EXP-C (Judgment) live integration or uses a
  simpler interim voter model behind a flag.

Engineering-level (documentable defaults an engineer may set, recorded as provisional in `balance.json` notes):
- Ballot evaluation weights and the factor registry (shared with SJD-D; must not become a second judgment system).
- Campaign activity budgets and cadence; NPC candidacy propensity.
- Data schema: `Office {id, title, selection, term_days, holder, since, authority[], wage}`, `Election {id, office,
  day, candidates[], ballots | tally, result, tie_rule}`, saved with a save-version bump and fixture test.
- Treasury line items per office (reuse `World.treasury`, TREAS-01; no parallel treasury).

## 7. Repository facts relevant to P21-A (audit starting points)

- FACT: no `election`, `vote`, `mayor` or `constable` anywhere in `game/scripts` (grep, staging `b3bbb1c`).
- FACT: treasury, taxes (`npc_brain.gd` evening business: tax per household above an exemption), relief, guard wages,
  guard post refills (EQ-04, `_guard_posts`), reeve succession (`_reeve_succession`), stall commission (STALL-05).
- FACT: crime awareness by witness and report only (`World.witness`, `World.report_crime`; PAR-05, PICK-01).
- FACT: `Relations` holds one tie per pair with `regard` clamped to 0..100 (no negative opinion), player-centred harm
  (`Relations.harmed` only lowers ties with the player). A voter model needs SJD's GOOD/BAD ledger or an interim.
- FACT: `NPC.memory` is a list of at most 8 strings ("saw ...", "met ..."); no structured event store (GM-01 not started).
