# Expansion 21 (Village Politics): preliminary plan

Branch `wip/expansion21-preparation`, created from Build 17's code (`dfec7ec`). Authority: owner directive 2026-10-22,
`docs/directives/2026-10-22_expansion21_preliminary_authorization.md` (staging `09b9d78`): "This is planning
authorization only. Do not implement gameplay mechanics, invent requirements, merge branches, run simulation
campaigns, or prepare Expansion 21 builds."

**Status: PLANNING ONLY.** No code, data, save format, test or register entry is changed. Labels follow the roadmap
comparison: **APPROVED** (an owner source, cited), **STARTER DRAFT** (in the owner's starter pack only; a proposal until
the owner confirms it), **OPEN** (no owner answer), **FACT** (what the code or register says). This plan reuses
`docs/roadmap/21_Politics_comparison.md` (on `origin/wip/roadmap-docs`), which already compares the starter with every
owner source section by section; it is not repeated here.

---

## 1. Scope as recorded (not redefined)

Expansion 21 is **Village Politics** (OD-30, `docs/directives/2026-10-21_expansion_numbering_approval.md`: "Expansion 21:
Politics"; sequencing only, "It does not approve unresolved design decisions, authorize implementation of future
expansions, or establish release dates").

| Source | What it establishes |
|---|---|
| Register **VP-01** (APPROVED — NOT STARTED, target `20+`, depends on GM-01, DVW-B1) | "Living village politics: offices, individual NPC voting, elections, civic authority". Source: `docs/directives/2026-10-19_memory_refuges_politics.md` Part III |
| Directive 2026-10-19 Part III, s.18-32; Part IV s.33-35; Part V s.36-39 | The full requirements: philosophy (s.18), civic positions (s.19), real individual voting (s.20), generational reputation (s.21), opinions from circumstances (s.22), campaigns (s.23), schedules and procedures (s.24), authority of mayor, constable, captain, guard (s.25), accountability (s.26), politics and the economy (s.27), history (s.28), NPC autonomy (s.29), imperfect knowledge (s.30), transparency and privacy (s.31), 14 integration tests and the Downs/Miller scenario (s.32), shared historical foundations (s.33), performance (s.34), host authority (s.35), implementation order (s.37), wiki (s.39) |
| **World Design Rule 015** (WDR-015 recorded; compliance WDR-015-C, PARTIALLY IMPLEMENTED, `20+`) | Scaled governance (mayor/elder, council, guard captain, guards, tax collector, bailiff/magistrate, clerks/stewards, household servants "as applicable"); officials do real work; a real public treasury; locally appropriate succession (election, appointment, council selection, inheritance); anyone may seek office without guaranteed success; guards by funding, staffing and equipment; domestic workers; political careers in history |
| **World Design Rule 019** (WDR-019, recorded from directive s.40) | Living political agency and democratic consequences: genuine individual votes from knowledge, relationships, family histories and interests; real responsibilities; politics continues without the player across generations |
| Starter spec `docs/roadmap/21_Politics.md` (owner's documentation pack, 2026-10-21) | "Expansion 21 — Living Village Politics"; STARTER DRAFT where it goes beyond the sources: phases P21-A..E, the coupling to the Living Economy; its own status line says the 21-23 numbering was "not yet an owner-approved register assignment" (since approved by OD-30) |
| Related entries | CRT-06 (friends "Back you up" in disputes and votes; PARTIALLY IMPLEMENTED), SJD-F (judgment rollout to "trade, aid, friendship, courtship, employment, crime, politics"), OD-LE-06 ("Permissible manor interventions and political authority", BLOCKED), DGA-D8 ("Era, county, political status, map scale", BLOCKED proposal), GM-01 (generational memory, the 30-planks chain), DVW-B1, DVW-B5 (predictable announced taxes, target 18), EQ-04 ("Government continues through leadership change", COMPLETE), TREAS-01 (one treasury, COMPLETE), WDR-014-C (legacy), MP-01 (host authority) |

The directive's s.37 said "Start meaningful implementation work, not just planning documents" (2026-10-19). The later
directives (OD-30 2026-10-21; the 2026-10-22 authorization) make the current authorization planning only; the
comparison records this as conflict C1. This plan follows the newer directive.

---

## 2. Preliminary requirements inventory

Nothing below is new: each line cites its source. "Needs" is what must exist in the game for it to be built.

### 2.1 Approved (owner sources)

| # | Requirement | Source | Needs |
|---|---|---|---|
| A1 | Offices: mayor or equivalent leader, constable, captain of the guard, guard; open to NPCs and the player; selection methods configurable per settlement | s.19; Rule 015 b.1, b.4 | An office record (holder, method, term); OD on the starting structure (Q-POL-1) |
| A2 | Further offices "as applicable": council, tax collector, bailiff/magistrate, clerks/stewards, household servants | Rule 015 b.1, b.7 | Q-POL-1; domestic work as real employment |
| A3 | Every eligible voter decides individually from knowledge, testimony, family memory, gossip, conduct, competence, security, economic interest; may abstain; results counted from ballots, never fabricated | s.20; Rule 019 | A voter model over judgment beliefs (Expansion 19) and economic interests; franchise (Q-POL-2) |
| A4 | Generational reputation: family history influences only voters who know it; it may tip, never override | s.21 | GM-01 (events linked to families, transmitted), Expansion 19 beliefs and ledgers |
| A5 | Opinions derived from circumstances (farmer, merchant, guard, struggling household, landowner, bandit victim), changing with conditions, never random | s.22 | Household economics (`evaluate_household`), Expansion 20 needs if present |
| A6 | Campaigns (service, promises, gatherings, endorsements, debates), not a click minigame; NPCs campaign | s.23; starter | Events for promises and gatherings; meetings (Expansion 19 channel) |
| A7 | Schedules and procedures: terms, eligibility, candidacy, dates, counting, ties, vacancies, resignation, death in office, by-elections; never vacant indefinitely; persisted; reload never repeats or changes an election | s.24 | Saved election records; Q-POL-3, Q-POL-5 |
| A8 | Real authority: mayor (spending, works, taxes within rules, guard funding, appointments, emergencies); constable (law, investigations, arrests, records, disputes); captain (assignments, patrols, training, equipment, readiness, discipline); guards (patrol, respond, protect, investigate, report) | s.25; Rule 015 b.2, b.6 | Today's reeve evening business split into decisions by office holders; a crime record (DVW-B2 gap) |
| A9 | Accountability: promises made/kept/broken, taxes, works, emergencies, favouritism, defences remembered; removal or loss of support through the established system | s.26 | Event feeds into Expansion 19; Q-POL-6 |
| A10 | Politics changes the real economy: guard funding, roads, taxes, projects creating demand, civic wages; nothing from nothing | s.27; Rule 015 b.3; WDR-022 | The one treasury (TREAS-01) and the existing purchases; OD-LE-06 |
| A11 | History: results, careers, projects recorded; descendants recall real facts | s.28; starter | GM-01, WDR-014-C |
| A12 | NPC autonomy: politics runs without the player | s.29; Rule 019 | NPC candidacy and voting in the daily simulation |
| A13 | Imperfect knowledge: no omniscient voters; rumours weighed by source; candidates do not know how everyone votes; secret crimes count only when discovered | s.30 | Expansion 19 beliefs with provenance |
| A14 | Transparency: public interface (offices, dates, candidates, platforms, eligibility, results, totals, holders, terms); private votes unless the rules permit; believable feedback without exposing the simulation | s.31; SJD-Q10 (no numbers in normal play) | UI; Q-POL-4 |
| A15 | The 14 tests of s.32 and the Downs/Miller scenario, from real memory and voting logic | s.32 | All of the above |
| A16 | Bounded histories, summaries, indexed relationships (performance) | s.34 | Budgets (none set: CLAUDE.md section 8) |
| A17 | Host authority for elections, appointments and counting in future multiplayer | s.35 | MP-01's host-authoritative model; no client-side results |
| A18 | Wiki entries for offices, elections, voting, campaigning, civic employment, guard careers, taxation, political reputation, succession, historical leadership | s.39; WIKI-01 | The wiki providers (`wiki*.gd`) |
| A19 | Friends side with the player in disputes and votes | CRT-06 (owner answers 2026-10-19) | Voting exists (A3) |
| A20 | Taxes predictable, with hysteresis, announced | DVW-B5 (target 18) | Constrains A8's tax power |
| A21 | Government continues through leadership change | EQ-04 (done for the reeve and the watch) | Kept as the floor: no vacancy left indefinitely |
| A22 | Judgment is one factor, never a threshold; applies to politics | EXP-C owner wording; SJD-F | Expansion 19 weighting interface |

### 2.2 Proposals (not approved)

- Phases P21-A..E and the roadmap's POL-A..E (two names for one sequence): STARTER DRAFT.
- Coupling to the Living Economy's interfaces: STARTER DRAFT (the directive requires "the existing economy", s.27).
- Q-POL-1..7 and the engineering defaults (comparison s.6): agent questions, not owner-registered decisions.
- DGA-D8 (era, county, political status, map scale): a BLOCKED proposal awaiting the owner.

### 2.3 Rules

- WDR-015, WDR-019 (above); WDR-022 ("A village is allowed to fail. The simulation is not": unfunded services may fail,
  no hidden rescue); WDR-013 (finite resources); WDR-014 (legacy); MSW-01; WIKI-01.
- Register gap (FACT, from the comparison): no `WDR-019-C` compliance entry exists; Rule 019 is tracked only through VP-01.

---

## 3. Dependencies on Expansions 18, 19 and 20

| Expansion | What politics needs from it | Hard or soft |
|---|---|---|
| **19 Judgment** (`origin/wip/expansion19-preparation`, `docs/expansion19/DESIGN.md`) | Events as facts (`JudgmentStore.publish`); beliefs with provenance and confidence; GOOD/BAD ledgers with permanent murder records (Q02, Q11); word of mouth through meetings only (Q06, Q07); the shared decision interface `JudgmentWeighting.choose` (Q14: "every applicable NPC decision"); morality separate from law (Q08); no numbers shown (Q10). A ballot is a choice among candidates with judgment as one factor (A3, A22); generational reputation (A4) and imperfect knowledge (A13) are this machinery. GM-01 (VP-01's own dependency) is the judgment system's event and belief record (register). | **Hard.** VP-01's placement reason: "voting weighs judgment, so after 19". |
| **18 Settlements** (`origin/wip/expansion18-preparation`, `docs/expansion18/DESIGN.md`) | Settlement-local structure: Rule 015's "appropriately scaled governance" and s.19's "different settlements may develop different political structures" need a settlement entity; Expansion 18's settlement facts and report (`settlement/facts.gd`, `report.gd`: residents, coins by holder, the manor as a party) are where per-settlement offices and treasuries would attach. Residency (`Discovery.residents`, MIN-D-Q2) is a natural input to the franchise. Several settlements (SET-E) are targeted 20+. | **Soft** for one village; hard for per-settlement structures. |
| **20 Living Economy** (`wip/expansion20-preparation`, `docs/expansion20/LE00_ARCHITECTURE_AUDIT.md`) | OD-LE-06 ("permissible manor interventions and political authority") is the shared decision: which spending, lending, taxing and procurement the manor or an office may do. LE-04 makes the manor a constrained actor that decides; Expansion 21 decides who holds those powers. Voters' economic interests (A5) read household budgets and needs (LE-03). Civic wages as offers depend on OD-LE-03. | **Soft** for a first slice on today's economy (s.27 requires "the existing economy"); **hard** for OD-LE-06. |

Expansion 22 (Bandits) and 23 (Legacy) consume politics (crime records, political careers in the chronicle), they are
not dependencies of it.

---

## 4. Architectural conflicts and shared interfaces

### 4.1 What Build 17 already has (FACT, `dfec7ec`)

| Area | Code | What it does |
|---|---|---|
| The reeve (the only governing office) | `World.reeve_id`; `world.gd::_open_treasury` | The reeve's starting coins beyond `reeve_purse` become the treasury at setup |
| The manor's evening business | `npc_brain.gd::reeve_day` (17:00, `world.gd::_on_hour`) | Market update, reeve succession, guard posts, tax (only below `treasury_tax_holiday_days` of obligations; a share of cash above an exemption per household), relief (`_relief`), tool support (`_support_trades`), repairs, mining postings, public works (`_public_works`, only while a reeve lives), granary purchases. Rules, not the reeve's choices: the reeve's person decides nothing |
| Reeve succession | `npc_brain.gd::_reeve_succession` | A dead reeve's post opens in `World.vacancies`; filled by "the trades' rule, used until the owner sets one for the office (an open policy question)": an adult without a trade (the late reeve's household first), else a caravan newcomer (`succession_dawn`, `succession_caravan`, `_apprentice_for`, `_newcomer_for`, `_install`) |
| The watch | `Population.JOBS` (guards, reeve, sage), `Population.GUARD_STATS`; `npc_brain.gd::_guard_posts`, `_take_guard_post`, `_guard`, `_guard_shift` | Kept at the starting strength while the treasury can pay (`manor_hire_runway_days`); day and night shifts; patrol to random posts (`w.rng`), fight seen bandits, recover lying loot to the treasury (`_loot_to_recover`), re-arm from own coins (`Decay.plan_rearm`). No captain, no ranks, no assignments |
| Wages and layoffs | `npc_brain.gd::pay_guards` (18:00), `daily_obligations` | Sage 4, reeve, guards, manor hands from the treasury; unpaid when it is short; the newest hand laid off below two days of obligations |
| Treasury income | tax (above), `property.gd::collect_rents`, `_pay_manor`, `stalls.gd::settle` (5% commission), land sales, fines (`world.gd::guard_confront`) | One treasury (TREAS-01) |
| Law | `world.gd::witness`, `raise_alarm`, `report_crime`, `deliver_report`, `guard_near`, `guard_confront`, `theft_fine_for`; `npc_brain.gd::_report` | Crimes against villagers by the player and attacks by anyone are seen and reported; guards fine the player; CRT-06: a friendly guard waives the fine, a friend nearby halves it. No villager theft record (DVW-B2), no constable, no courts |
| Manor work board | `manor_work.gd` (`seek`, `plan`, `reeve_fallback`: LOG-01) | Civic employment as paid jobs: hauling, mending, quarrying, surveys, pits, tunnels, shoring |
| Inheritance | `world.gd::kill`, `_heir`, `_inherit`; `life.gd` | Family graph; offices are not inherited |
| Relationships | `relations.gd` (`player_friend`, `harmed`, `notoriety`, `refusal`) | One regard per pair (0-100); harm player-centred; CRT-12 fixed notoriety threshold |
| Wiki | `wiki_manor.gd` | The manor's player-facing page |
| Not present (FACT, comparison s.7, re-checked on this code) | — | No election, vote, mayor, constable, council or office record anywhere in `game/scripts` |

### 4.2 Shared interfaces and conflicts

1. **Offices versus the reeve and the manor (Q-POL-1, DGA-D8, OD-LE-06).** Today one "manor" with an appointed-by-rule
   reeve runs everything by fixed rules. Politics needs offices whose holders decide (A8). Whether the reeve stays (a
   lord's officer beside an elected mayor), becomes the mayor, or is replaced is undecided (comparison C2). Proposal:
   generalise `World.reeve_id` and `World.vacancies` into one office record, with the reeve as its first office, so
   EQ-04's succession keeps working and nothing is duplicated.
2. **One treasury.** TREAS-01 forbids a parallel treasury. Offices draw on `World.treasury`; per-office budgets are
   allocations recorded against it, not separate purses. Expansion 18's per-party ledgers must not become a second
   civic treasury (the Expansion 20 audit's conflict 1).
3. **Who decides spending.** `reeve_day`'s rules (tax holiday, relief, tool support, works) are OD-16, OD-19, TREAS-01 and
   EQ-19 owner rules. Expansion 20 (LE-04) would turn them into the manor's decisions; Expansion 21 would give them to
   office holders. Both edit the same function. Sequence them (section 6) and decide OD-LE-06 once for both.
4. **Civic employment.** Guards, manor hands and the reeve are paid by fixed daily wages (`pay_guards`), not offers.
   Expansion 20's OD-LE-03 (wages as offers) and Expansion 18's capability pay multiplier both touch civic wages; the
   multiplier applies to a base wage, never fixes it (X18 DESIGN s.9a rule 7).
5. **NPC decision hooks.** Voting, candidacy and campaigning are new decisions; they must go through Expansion 19's
   shared interface (`JudgmentWeighting.choose`, Q14) rather than a second scoring system (comparison s.6: "must not
   become a second judgment system"). Today's decisions are in `NPCBrain.decide`'s priority list; campaigning and
   gatherings need a slot in it.
6. **Event and gossip channel.** Promises, scandals, results and civic works (A9, A11) are events: publish them through
   Expansion 19's `JudgmentStore.publish` and spread them by meetings (Q07), with permanent records where Q11 says. The
   Expansion 20 audit proposes the same channel for economic knowledge; all three expansions share its frame budget
   (Expansion 19's open gossip performance concern).
7. **Existing fixed rules that politics would replace.** CRT-12's notoriety refusal and `Relations.harmed`'s instant
   spread (X19 conflicts 1 and 2), CRT-06's friendly guard versus Q08 "the legal system is separate" (X19 conflict 3),
   which A8's constable and law work will reopen. None is resolved here.
8. **Saves.** `SAVE_VERSION` 17 (Build 17); Expansions 18 (`x18_settlements`, `x18_experience`) and 19 (`judgment`) add
   optional sections without a bump. Politics adds offices, election records, ballots or tallies, terms and civic
   history (A7, A11): an optional section while prospective, a versioned section with migration fixtures at
   integration, after 18, 19 and 20 take theirs. Reload must not rerun an election (A7): the election record holds its
   state and result.
9. **Determinism.** Guard patrols (`_guard`) and other decisions draw on `World.rng`; ballots, tie lots and campaign
   choices should use seeded hash draws as Expansion 19 does (A19-2), so turning politics on does not shift every other
   random stream.

---

## 5. Approved decisions and unanswered questions

### 5.1 Already decided (do not ask again)

OD-30 (numbering); EQ-04 (government continues through leadership change); TREAS-01 (one treasury, real purchases);
OD-16 (b) (the manor supports essential trades); OD-19 (dynamic reserves, used by tax-exempt reckoning); CRT-06 owner
answers (friends back you up); Expansion 19's answered SJD-Q01, Q02, Q06, Q07, Q08, Q10, Q11, Q14 (facts, decay with
permanent murder, trust from regard, meetings only, law separate, no numbers shown, permanent memories, universal
integration through one interface); the directive's own defaults (secret ballot unless the rules permit, s.31;
no indefinite vacancies, s.24).

### 5.2 Owner decisions, in dependency order (questions from the comparison, s.5-6, plus the register)

1. **Placement and gate (Q-POL-7, comparison C1).** Confirm politics waits for Expansion 19's live judgment (the
   register's reason), or allow an interim voter model behind a flag. Everything else waits on this.
2. **Political structure of the starting village (Q-POL-1, DGA-D8, comparison C2).** Manor with a reeve, elected mayor,
   council, or a mix; what the lord retains; whether the reeve becomes or sits beside the mayor.
3. **Authority of offices versus the manor (OD-LE-06).** Which spending, taxing, lending, appointing and relief powers
   each office holds "subject to established rules"; one answer for Expansions 20 and 21.
4. **Franchise (Q-POL-2).** Who votes and who may stand (age, residency, household head or every adult, property;
   bandits and clan members).
5. **Terms and calendar (Q-POL-3).** Office terms, election season, by-elections on death or resignation (with eight-day
   game years, B8-029).
6. **Ties (Q-POL-5)** and **removal from office (Q-POL-6).**
7. **Vote privacy and public totals (Q-POL-4)** (s.31's default is secret; confirm what totals are shown).
8. **The constable and the law.** Whether Q08's separate legal system gains a constable and crime records before
   Expansion 22, and CRT-06's friendly guard (X19 conflict 3).
9. **Taxes under an elected authority and DVW-B5's predictability** (hysteresis, announcement).
10. Engineering defaults the owner may leave to the agent (comparison s.6): ballot factor weights within Expansion
    19's profiles, campaign cadence, candidacy propensity, schema, per-office treasury line items.

---

## 6. Proposed implementation sequence (agent proposal)

Follows the directive's s.37 order and the starter's P21 phases (one naming scheme proposed: children `VP-01A..E`).

| Step | Scope | Needs first |
|---|---|---|
| **VP-01A** Audit (P21-A, s.37.1) | This document plus a decision-point audit of `reeve_day`, `pay_guards`, `_guard`, `guard_confront`, succession | Done in outline here |
| **VP-01B** Offices and civic work (P21-B, s.37.2, s.37.8) | One office record generalising the reeve and the watch (holder, method, term, wage, authority list), succession through the existing vacancies; captain and constable duties on the existing guard and law code; spending decisions moved from fixed rules to office holders within owner rules; one treasury | Decisions 2, 3, 8; Expansion 20 LE-04 sequencing |
| **VP-01C** Voting and the election lifecycle (P21-C, s.37.3-5) | Eligibility, candidacy, ballots through Expansion 19's interface, counting, ties, terms, vacancies, persistence | Expansion 19 live (decision 1); decisions 4-7 |
| **VP-01D** Candidacy, campaigns, player participation, UI (P21-D, s.37.6-7) | NPC and player candidacy, campaign activities as events and meetings, the public election page, believable feedback | VP-01C |
| **VP-01E** Policies, history, long runs (P21-E, s.37.9-10) | Promises and their keeping, civic history events (GM-01), the 14 tests and the Downs/Miller scenario, long-run validation across generations and save/load, wiki | GM-01; DVW-B5 |

Placement: after Build 19 (judgment) and after Expansion 20's LE-04 where they share `reeve_day` (OD-30 order).

---

## 7. Preliminary complexity and risk

- **Complexity: high.** Offices touch the treasury, wages, law and the manor's whole evening business; voting needs the
  full Expansion 19 belief machinery plus economic interests; history needs GM-01. The directive's 14 tests span three
  expansions' systems.
- **Dependency risk (highest).** Without live judgment, a voter model would either be a second judgment system
  (forbidden by EXP-C's design and the comparison) or a placeholder that must be replaced.
- **Overlap risk.** `reeve_day` is claimed by Expansion 20 (manor as actor) and Expansion 21 (offices); editing it twice
  in parallel branches would conflict. One owner of the change at a time.
- **Behavioural risk.** Moving owner-ruled spending (relief, tool support, tax holidays) under office holders' choices
  can starve services; WDR-022 allows the failure but the owner's earlier rules (OD-16, TREAS-01) must still hold as
  the "established rules" the offices act within.
- **Performance.** Elections are periodic (cheap); campaigns and political gossip add to Expansion 19's meeting channel
  (its open frame-cost concern, p99.9 3.67 ms at 500 people). s.34's bounded histories apply.
- **Saves and replay.** Election records must make reload idempotent (s.24, test 3); a fourth optional section joins
  18, 19 and 20's at integration.
- **Determinism.** Ballots and ties from seeded hash draws, stable voter order.
- **Multiplayer.** Host authority for counting (s.35) is a design constraint, not work now.

---

## 8. Preliminary work that could proceed independently now

All of the following are documents and read-only analysis on this branch. None changes live behaviour, and none
answers an owner decision:
1. **The owner decision brief** for decisions 1-9 of section 5.2: options, a recommendation each, and what each changes
   in today's code, so the owner can answer in one pass. The comparison's Q-POL list is its starting point.
2. **A decision-point map of `reeve_day` and `pay_guards`**: each rule, the owner decision it rests on (OD-16, OD-19,
   TREAS-01, EQ-19, EQ-04), and which future office would hold it. Shared with Expansion 20's LE-04 to avoid two
   rewrites.
3. **The 14 tests of s.32 mapped to their dependencies** (which can run on today's systems, which need Expansion 19,
   which need GM-01), as the future test plan.
4. **An office and election record schema** as a design note, extending `World.vacancies` and the reeve rather than
   adding a parallel structure, for review only.

Not proposed now: any code, including a prototype voter model (it would anticipate Expansion 19's interface and
decision 1) or an office refactor of the reeve (live behaviour; Build 17 is being packaged for its playtest release).

---

## 9. Proposed register changes (for the lead; not made)

1. VP-01: `branch` `wip/expansion21-preparation`, this document as preliminary planning evidence, a history line;
   `target_build` 21 per OD-30 if the lead agrees (today `20+`).
2. Add `WDR-019-C` (compliance with Rule 019), the gap the comparison found, or record on VP-01 that it covers Rule 019.
3. Register the owner decisions of section 5.2 (as `OD-POL-1..9` or the comparison's `Q-POL-*`), each linked to VP-01,
   OD-LE-06 and DGA-D8 where they overlap.
4. Children `VP-01A..E` when the work is scheduled (directive s.36 asks for manageable tasks; one naming scheme).
5. Cross-reference OD-LE-06 and the political-structure decision as one question for Expansions 20 and 21.

---

## 10. Wiki and documentation

- Player-facing wiki: nothing changed, none needed (no feature).
- Developer documentation: this file is new; nothing else edited.
