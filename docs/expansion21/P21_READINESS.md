# Expansion 21 (Village Politics and Civic Authority): P21-00 audit, P21-01 foundation plan, P21-02 decision map

Owner directive 2026-10-23 (`docs/directives/2026-10-23_expansion21_phase1_authorization.md`; register P21-00, P21-01,
P21-02 under VP-01). Requirement sources: World Design Rules 015 and 019 (`docs/WORLD_DESIGN_RULES.md`), the directive
of 2026-10-19 Part III (`docs/directives/2026-10-19_memory_refuges_politics.md`), the Judgment and Decision Engine master
specification (`docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.txt`), and the register.
Code read: `wip/expansion21-preparation` at `983d80f` (the released Build 18 code; the Build 17 `PRELIMINARY_PLAN.md`
section 4.1 is superseded by section 1 here). Read in the code; nothing run. FACT unless marked PROPOSAL.

## 1. P21-00: what exists today

| System | State | Owner (script: field) and how it works |
|---|---|---|
| Village administration | FUNCTIONAL, one manor model | `NPCBrain.reeve_day` at hour 17 once a day (`World.last_reeve_day`): succession, guard posts, tax, relief, tools for essential trades, repairs, public works, granary buying. `World.treasury`, `granary`, `tax_state`, `reeve_id`, `manor_work` |
| The five settlements | FUNCTIONAL, abstract | `settlement/offmap.gd` `gov = {coins, granary, officials[], acc}`; officials are households with `trade == "official"`, fixed at creation, paid `official_wage`; taxes through the same `TaxPolicy`; a government name only ("the mayor and council", "the abbey's bailiff") |
| Manor and nobility | PARTIAL | the manor is an owner ref (`World.MANOR`), a building and the treasury; no lord, noble household or steward |
| Reeve | FUNCTIONAL | set at world creation (`population.gd`); on death `NPCBrain._reeve_succession` opens a vacancy filled by the trades' succession (the late reeve's household first, then the lowest-id adult without a trade, else a newcomer; the code calls the rule "an open policy question"); serves for life, never migrates |
| Mayor, elder, council, constable, captain, bailiff, magistrate, clerks | ABSENT in the village | |
| Treasury | FUNCTIONAL | `World.treasury` (int), saved; every movement is a direct `+=`/`-=` paired with a real coin transfer and a `stat("gov_*")` |
| Taxes | FUNCTIONAL | `TaxPolicy.step`: three bands with hysteresis and announced changes; collected per household above an exemption (register DVW-B5 still says NOT STARTED: a register mismatch) |
| Fines | PARTIAL | only the player's theft (`World.guard_confront`); a friend guard waives it in Build 18 (fixed to "reduce, never waive" on the Expansion 19 branch, 949b5b9, X19-GUARD); assault and killing unfined (DVW-B2 not started) |
| Rents, fees | FUNCTIONAL | `Property.collect_rents`, the stall's 5% commission, leases without a keeper, manor contracts, recovered loot, ended households' tills |
| Spending and civic wages | FUNCTIONAL | `pay_guards` (hour 18: sage, reeve, guards, manor hands; lays off the newest hand when under 2 days of obligations), day labour, relief, tools and manor orders, public works (needs a living reeve), repairs, granary, caravan food, mine supply, manor jobs; the chapel's fund is separate |
| Guards | FUNCTIONAL, basic | six guards; `NPCBrain._guard` shifts, fight bandits seen, recover loot, patrol random posts (`w.rng`); staffing only if the treasury affords it; witnesses and reports (`World.witness`, `report_crime`, PAR-05, PICK-01); no investigation, captain, equipment budget or funding-scaled response |
| Courts, magistrates, bailiffs | ABSENT | criminal records exist for the player only (`player.crimes`, `Relations.notoriety`); `law.gd` is the notaries' Law skill |
| Jobs and careers | FUNCTIONAL, no ladder | `seek_work`, `_hiring_competition`, vacancies (`_open_vacancy`, `_post_left`, `_install`), skills, work experience; no promotion |
| Land, buildings, public property | FUNCTIONAL; public buildings ABSENT | owner and tenant refs on plots, buildings, stalls, fields, pens; public works consume materials only; MAINT-01 not started |
| Influence, reputation, family | PARTIAL | pairwise ties and `notoriety` (relations.gd); family links on the NPC; memory capped at 8 lines; no political reputation (Expansion 19 adds judgment, trust, family reputation: prospective) |
| History, graves | ABSENT | `World.kill` sets `alive = false` and logs a line; no death day or cause stored; log capped at 300 lines; WDR-014-C graves not started |
| Elections, appointments | ABSENT | the only succession is the trades' vacancy system (reeve, guards) |
| Save and determinism | FUNCTIONAL | `SAVE_VERSION` 19, optional keys without a version bump; `tools/sim_gate.py` fingerprints positions, coins, jobs, goods, RNG state, treasury |

**Ids.** People `npc:<id>` stay unique because the dead stay in `w.npcs` (one exception: the child who becomes the player's
heir is removed, `life.gd:660`; if it held the top id, the next newcomer reuses it). Households `hh:<n>` are indexes,
ended not removed. Settlements have string ids; buildings string ids; posts have **no id** (a vacancy is a dictionary).

**Owner requirements already approved that bear on it:** VP-01 (concept, Build 21), WDR-015-C (partial), WDR-019-C,
WDR-014-C (graves), WDR-021-C, TREAS-01, EQ-04 (leadership succession), CRT-06 (includes "backing in votes"), DVW-B2,
DVW-B5, JOB-02, SJD-F (judgment rollout includes politics), PAR-05, PICK-01, Q-C7 (the reeve represents the manor in
contracts). Open: Q-POL-1..9 (drafted by the agent, never yet put to the owner), OD-LE-06, DGA-D8 and VP-01A..E
(proposals).

## 2. Dependencies

- **Expansion 20** owns money movement. Today every treasury movement is a direct field change; the civic records must
  attribute treasury transactions **through Expansion 20's economic event record** (LE-00 refresh, section 7 item 2),
  not a second log. Taxation, payroll, public purchasing: Expansion 20's offers and contracts, later. OD-LE-06 (what the
  manor may do) sets the manor's authority until Expansion 21 changes it.
- **Expansion 19** owns subjective judgment, trust, personality, family reputation. Voting from "knowledge, relationships,
  family histories, interests and assessment" (Rule 019) reads Expansion 19's beliefs; practical interest (a household's
  or profession's benefit from a policy) is Expansion 21's own input, kept apart from liking. Moral judgment (Expansion
  19 NET), legal guilt (a court record, absent) and political eligibility (office rules) stay three separate values.
- **Graves and history** (WDR-014-C, WDR-017) need a death record (day, cause, career), which nothing stores today.

## 3. P21-01: settled, safe foundation (ranked)

Settled by Rules 015 and 019 (offices with real work, a real treasury, succession, careers in historical records),
records only, every behaviour disabled, gate identical:

1. **Civic office registry**: stable office ids per jurisdiction (`village` plus the five settlement ids), today's posts
   as offices (reeve, the six guard posts, the sage) with authority metadata as descriptive text only, and the five
   settlements' named governments as jurisdictions. Consumer: tenure and succession records, later elections.
2. **Tenure history and succession events**: who held which office from day to day and how they left (death, migration,
   replacement), recorded by observing today's succession (`_reeve_succession`, `_install`, `_post_left`) without
   changing it; one open tenure per office (no duplicates); references by `npc:<id>` survive death.
3. **Legacy record**: a person's death day and cause and their offices and trades, kept apart from `NPC.memory`; the
   foundation WDR-014-C graves and Rule 015's "preserve political careers in historical records" both need.
4. **Treasury attribution**: through Expansion 20's economic event record once it exists (not built here).

Not started (owner decisions): elections, voting, eligibility, terms, tax rates and limits, punishments, office powers,
councils, appointments by an official.

## 4. P21-02: political decision map

| Decision | Owning system (existing or future) | Information needed | Open owner choice |
|---|---|---|---|
| Seeking office | NPC brain (`seek_work`-like career choice) | eligibility, ambition (Expansion 19 personality), wealth, family standing, chance of success | Q-POL-2 who may stand; whether ambition is a trait |
| Supporting candidates | NPC brain, social (Expansion 19 relations) | practical interest from the candidate's policy, liking, trust, family ties | how policies are stated (platforms) |
| Voting | election record (absent) | the voter's knowledge (Expansion 19 beliefs), household and profession interest, testimony | Q-POL-2 franchise, Q-POL-4 secrecy, Q-POL-5 ties |
| Appointing officials | the office holder's decision | candidates, competence (skills, experience), loyalty | which offices are appointed (Q-POL-1) |
| Allocating spending | `reeve_day` today | treasury, obligations, needs (relief, guards, works) | OD-LE-06, spending priorities |
| Collecting taxes, enforcing payment | `TaxPolicy`, `reeve_day` | households' means, arrears | Q-POL-9 tax authority under an elected government; arrears enforcement |
| Hiring and paying guards | `_guard_posts`, `pay_guards` | treasury, crime level, staffing | who commands the guard (captain or reeve) |
| Investigating crimes | guards (absent beyond witnesses) | reports, witnesses, evidence | Q-POL-8 constable and records before Expansion 22 |
| Applying legal judgments | court (absent); `guard_confront` fines today | guilt established how, by whom | legal authority and procedure |
| Infrastructure | `_public_works`, repairs; MAINT-01 | condition, materials, labour | public buildings and maintenance priorities |
| Emergencies | relief, granary | shortage signals | who may declare and spend |
| Lawful succession | `_reeve_succession`, vacancies | office rules, heirs, candidates | Q-POL-1, Q-POL-3, Q-POL-6 |

## 5. Owner decision packet (twelve topics)

| # | Topic | Already approved | In the code | Needs the owner |
|---|---|---|---|---|
| 1 | Government structure and jurisdiction | Rule 015: scaled governance (mayor/elder, council, captain, guards, tax collector, bailiff/magistrate, clerks) | one manor with a reeve; five named off-map governments | the starting village's structure (Q-POL-1) and whether the five settlements get real offices |
| 2 | Election, appointment or inheritance | Rule 015: "locally appropriate succession methods"; Rule 019: elections continue without the player | vacancy succession for the reeve | which method for which office |
| 3 | Eligibility to hold office | Rule 015: wealth, influence, reputation, family, service matter without guaranteeing success | none | who may stand (age, residency, property, sex, standing) |
| 4 | Voting eligibility and method | Rule 019: eligible NPCs vote individually | none | the franchise and the method (Q-POL-2, Q-POL-4, Q-POL-5) |
| 5 | Terms and removal | none | the reeve serves for life | terms, election season on the 8-day year, by-elections, removal (Q-POL-3, Q-POL-6) |
| 6 | Taxation authority and limits | DVW-B5 predictability (bands built) | `TaxPolicy` bands | who sets taxes and within what limits (Q-POL-9) |
| 7 | Public spending priorities | Rule 015: finite treasury for wages, infrastructure, supplies | `reeve_day`'s fixed order | whether officials choose priorities, and any floors (relief, guards) |
| 8 | Legal authority and criminal procedure | DVW-B2 (assault fines, heirs and fines), Rule 015 investigations | fines for the player's theft only | courts, who judges, procedure, punishments (Q-POL-8) |
| 9 | Guard command and enforcement | Rule 015: patrol, investigate, respond by funding, staffing, equipment | six guards, random patrols, funded by treasury | a captain, patrol priorities, equipment budget |
| 10 | Corruption and abuse of office | none | none | whether officials can embezzle, take bribes, favour kin, and the consequences |
| 11 | Noble authority vs local government | none (DGA-D8 proposal) | a manor with no lord | whether a lord exists and what the village may decide alone |
| 12 | Player participation | Rule 015 and 019: players may seek office; the player is not ruler by default | none | what the player may hold, vote in and change |

**Order to ask (PROPOSAL):** 1 and 11 first (structure and noble authority set everything else), then 2, 3, 4, 5,
then 6, 7, 8, 9, then 10 and 12.

## 6. Recommended next stage (PROPOSAL)

P21-01 items 1 to 3 as one isolated worker task when a development slot is free (records only, disabled, gate identical,
save round trip, references surviving death, no duplicate tenures, larger-settlement timing). Item 4 waits for Expansion
20's event record. Everything else waits for the packet's answers, and voting waits for Expansion 19's live judgment
(Q-POL-7).
