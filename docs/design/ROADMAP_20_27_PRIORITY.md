# Expansions 20-27: revised roadmap and dependency review (2026-10-24)

Owner directive: `docs/directives/2026-10-24_expansion_roadmap_reprioritization.md` (register ROAD-03). **Planning only: no
expansion is authorized for implementation by it.** Expansion numbers are unchanged; only the development order changes. Every
scope below is summarized from its source, which stays authoritative; nothing approved is replaced. Build 19 (private playtest
draft, `wip/build19` 2f72ec3) is frozen and untouched.

## 1. Priority order

| Priority | Expansion | Source specification (authoritative) | Authorization today |
|---|---|---|---|
| 1 | **20 Living Economy** | `docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx` (text beside it); `docs/expansion20/LE00_BUILD18_REFRESH.md`, `docs/expansion20/LE01_DATA_CONTRACTS.md` (on wip/expansion20-preparation); `docs/design/EXPANSIONS_19_21_ALIGNMENT.md` s.3; `docs/design/EXPANSIONS_20_21_DECISION_PACKET.md` | Phase 1 only (LE-00 audit, registration, isolated foundation: done, off). LE-01 onward not authorized |
| 2 | **21 Politics** | `docs/roadmap/21_Politics.md` (wip/roadmap-docs); `docs/directives/2026-10-23_expansion21_phase1_authorization.md`; `docs/directives/2026-10-23_expansions_19_21_consolidated_design.md` (P21-MAYOR); ALIGNMENT s.4 | Phase 1 only (P21-00, 01, 02: done, off). Elections and powers not authorized |
| 3 | **23 Bandit Factions and Criminal Careers** | `docs/directives/2026-10-21_master_expansion_roadmap.md` (BAN-A..E); `docs/roadmap/22_Bandits.md` (wip/roadmap-docs, old number); `docs/design/EXPANSIONS_22_23_AUDIT.md` s.4 | BAN-A audit done (document). BAN-B not authorized |
| 4 | **22 Settlement Advancement Phase 2** | `docs/directives/2026-10-23_expansions_22_23_kickoff.md`; `docs/design/EXPANSIONS_22_23_AUDIT.md` s.1-3, 5-6 | Audit done; E22-OD-01 and E22-OD-02 approved as design only; architecture not authorized |
| 5 | **24 Generational Legacy** | `docs/roadmap/23_Legacy.md` (wip/roadmap-docs, written as "Expansion 23" before the renumbering); `docs/directives/2026-10-19_memory_refuges_politics.md` Part I; WDR-014, 017, 021; GM-01, DVW-B7, WDR-014-C | Not authorized |
| 6 | **25 Weather, Seasons and Disasters** | `docs/design/EXPANSION25_WEATHER_SEASONS_DISASTERS.md` | Design only |
| 7 | **26 Creatures and Heroes** | `docs/design/EXPANSION26_CREATURES_AND_HEROES.md` | Design only |
| Pending | **27** | **None found** (see section 8) | |

## 2. Scope of each expansion (from its source)

**20 Living Economy.** Needs drive behaviour; prices are offers; accepted orders are real obligations with reservations, credit and
contracts; knowledge is bounded; safety levers are organic, never hidden rescue. Stages LE-00 (audit) to LE-07 (release).
Approved decisions: combined pricing and limited negotiation (OD-LE-02), breach and renegotiation (OD-LE-13), credit with
installments, goods and collateral (OD-LE-05). Built and off: reservation record, economic event record, actor resolver.
Capabilities by stage: LE-01 Need, Offer, Knowledge records; LE-02 pricing, negotiation, transaction record; LE-03 production
reservations, business identity, hiring and wages, household finances; LE-04 credit, contract breach, government purchasing;
LE-05 trade and transport, bandits and stolen goods. **Joan Stone's case** (her building fund stolen) maps to approved or existing
mechanisms: seeking work (job market exists; side work is OD-LE-03), negotiating payment (OD-LE-02), selling possessions (trade
exists; household budgets OD-LE-12), borrowing (OD-LE-05; who may lend OD-LE-05B), family help (family purse and FAM-SAC-01
exist). They are possibilities; failure stays possible.

**21 Politics.** Office registry, tenure and succession, legacy (built, off). Approved: an elected mayor, four-game-year terms (32
game days), established adult residents vote and stand, an early vacancy triggers an election as soon as possible with the
longest-serving official interim (P21-MAYOR, settled, not reopened). Phases P21-03 elections and the voter model (reads
Expansion 19 and household interest), P21-04 treasury, taxes and spending through Expansion 20 transactions, P21-05 guards with
real duties. Courts, corruption, campaigning beyond a platform: separate authorization.

**23 Bandit Factions and Criminal Careers.** BAN-A audit (done); BAN-B faction identity, membership, hierarchy, safehouse
ownership, persistent resources; BAN-C career actions, recruitment, theft and raids, resale, suspicion and response; BAN-D rank,
challenge, leadership, schism, succession; BAN-E economy, judgment and politics integration and long runs. Acceptance: no
invented loot or currency, stolen items keep provenance and custody, factions can fail and disband, guards act only on knowable
crimes, child dependents gain no adult combat abilities. Proposal awaiting E23-OD-01: one faction to start (today's band).
Preserve Build 19's bandit food purchase (affordable, however hurt), healing at camp, the blocked-chase rule and combat.

**22 Settlement Advancement Phase 2** (built on Build 18; do not rebuild it). Phases A regional ledger view (no second ledger),
B capability profiles for off-map settlements and knowledge transfer, C promote and demote settlements with identity, property
and history kept (E22-OD-01, hybrid simulation), D development off-map (dwellings, infrastructure, abandonment), E regional
networks on real routes (E22-OD-02, continuous geography). Open: E22-OD-03 knowledge, 04 trade, 05 growth.

**24 Generational Legacy.** Stable causal event ids and knowledge provenance; family transmission and belief; graves, chronicles,
property histories and genealogy; political, crime and battle integration; long multigenerational runs (phases written P23-A..E,
now Expansion 24). Avoid a duplicate memory system: it deepens Expansion 19's.

**25 Weather, Seasons and Disasters** and **26 Creatures and Heroes**: the two packets, including every owner answer, unchanged.

## 3. Dependencies and conflicts

| Expansion | Needs before it | Supplies to later ones |
|---|---|---|
| 20 | Build 19 (judgment trust and gossip channel, identity, recorder) | event record and provenance, transactions, credit, business identity: 21, 22, 23, 24, 26 |
| 21 | 19 live (voting), 20 transactions and household interests (taxes, payroll, purchasing) | offices, legal record, guard duties, tolls and jurisdiction: 22-E, 23, 24, 26 (bounties) |
| 23 | 19 (reputation), 20 (crimes as events with provenance; fencing and stolen-goods custody, OD-LE-09), 21 (legal record, guards) | route banditry and raids: 22-E; crime history: 24 |
| 22 | identity (done), 20 (construction purchasing), 21 (tolls, jurisdiction), 23 (route banditry for E) | regional map and geography: 25 (rivers), 26 (lairs) |
| 24 | 19 memories, identity, 20 event ids, 21 political careers, 23 crime history | |
| 25 | map water (rivers, a map version bump); better after 22's geography | building condition, emergencies, seasons: 26 |
| 26 | 25 (rivers, winter, building condition, emergency response), 20 (monster goods market), 21 (reeve's bounties) | |

**Moving 23 ahead of 22 is safe, with one boundary.** Nothing in 23's BAN-B to BAN-D needs 22. 22's phase E needs 23 (route
banditry), which the new order supplies earlier. The one overlap: 23's raids and resale beyond the village (BAN-C "raids",
regional fencing) would run over today's route stand-ins (`routes.gd`, `regional.gd`, which the 22 audit says must be
re-validated). **Smallest adjustment (recommended):** 23 works in the village and on the existing roads and off-map settlement
books; travel-time route banditry across a continuous region is built in 22-E on 23's faction records. No order change.

**Other conflicts found:**
1. **Skeletons, lizards and spiders.** The master roadmap (2026-10-21) puts B14-09 and FR-01 in the unnumbered "World Exploration,
   Dungeons & Encounters" track; on 2026-10-23 they were moved into Expansion 26 with the owner's monsters. Owner question Q3.
2. **Building condition.** 22-D (abandonment, infrastructure) and 25 (disaster damage) both need buildings that decay or are
   damaged. Design it once in 22-D if 22 needs it; 25 then reuses it. Not built ahead of need.
3. **Map water.** 25 adds rivers (a map version bump); 22-E's continuous geography also changes the map. Designing 25's rivers
   on 22's regional map avoids two map migrations.
4. **Old document numbering.** The roadmap pack on `wip/roadmap-docs` numbers Bandits 22 and Legacy 23 (written before the
   2026-10-23 renumbering); the register and this report use 23 and 24.

## 4. What every expansion must preserve (Builds 16-19)

Conservation of coins, goods, animals and deposits (`economy_sim` FATAL checks, `World.total_coins`, settlement audits);
determinism (seeded hashes, the Build 19 baseline `docs/release/sim_baseline.json`, Build 18's kept as history); permanent
identity (save version 20, band ids from 1,000,000); the switch-off save pattern (`*_foreign` written back unchanged); Expansion
19's judgment, personality, family reputation, lies, stories, family sacrifice; REC-F1 and SIM-F9 wait plans; the blocked-chase
rule; the owner's bandit food and healing rules; the recorder off in every release; WDR-022 (no hidden rescue) and B19-EMERGE
(classify, never rebalance to look healthier); the player under the same rules as NPCs.

## 5. Shared infrastructure (use, do not duplicate)

- **One event record with provenance** (Expansion 20's, built and off) for transactions (20), offices' acts (21), crimes and
  custody (23), regional changes (22), causal history (24) and explanations (XEXPL-01). Legacy's "stable causal event ids" are
  this record, not a second one.
- **One person-id space** (done in Build 19) for factions, offices, promoted settlements and genealogy.
- **The actor resolver and reservations** (20, built): every party (household, business, office, faction) as a holder the
  conservation audit sees.
- **The flight recorder** (development only) to explain significant changes; extend its coverage per expansion.
- **The determinism gate and baseline** per build, and the bounded-run rule (one run per seed, analysed once).

## 6. Risks

- **Performance:** no budget is set (OD-LE-15; proposed 500 villagers, under 4 ms of economy a frame on a mid-range phone);
  off-map growth has no housing cap yet; a continuous world multiplies settlements; event records need bounded retention.
- **Determinism:** bandit behaviour uses the shared `w.rng`, so faction changes shift the stream (gate); each build ends with one
  new baseline with explained differences, not one per fix.
- **Conservation:** new holders (business tills, faction purses and stores, escrowed bounties) must be inside `total_coins` and
  the census from their first commit.
- **Merges:** the prospective branches 20 and 21 started from Build 18 and conflict in `world.gd` (four places; all in
  `to_dict`); they must be brought onto Build 19 once, with the conflicts resolved together.
- **Saves:** each expansion adds optional sections; every format change ships a migration and fixture test.

## 7. Recommended batches and checkpoints (when authorized)

**Batch 0, before 20 (after Build 19 is accepted):** bring `wip/expansion20-preparation` and `wip/expansion21-preparation` onto
Build 19 together; resolve the `world.gd` conflicts once; add the determinism gate to CI.

| Expansion | Batches | Checkpoints |
|---|---|---|
| 20 | (a) LE-01 records and LE-02 pricing, negotiation, transactions; (b) LE-03 business, labour, household finances; (c) LE-04 credit and contracts, government purchasing hook; (d) LE-05 trade, transport, stolen goods; LE-06 calibration | targeted tests per batch; integration check at the end of (a) and (c): the same seed twice, conservation, one recorded 30-day run on seeds 1-2 analysed per B19-EMERGE; release gate after (d): release tests, seeds 1-4 30 days, one proposed baseline |
| 21 | (a) P21-03 elections and voter model; (b) P21-04 treasury and spending through 20; (c) P21-05 guards and investigation | as for 20 |
| 23 | (a) BAN-B faction records; (b) BAN-C careers, recruitment, theft, resale; (c) BAN-D hierarchy and succession; (d) BAN-E integration and long runs | as for 20; every faction change re-baselined once per build |
| 22 | architecture document first (E22-OD-01/02); then (a) A-B ledger view and capability; (b) C promote and demote; (c) D development; (d) E networks with 23's factions | promote/demote conservation and identity tests designed before code |
| 24 | P24-A audit; B event ids on 20's record; C transmission and dialogue; D graves and genealogy; E integration and multigenerational runs | |
| 25, 26 | design only until authorized | |

Each build: targeted tests while developing, one integration check at meaningful points, one release gate; no repeated long
campaigns without a stated purpose.

## 8. Expansion 27

No Expansion 27 exists in the register, the builds map, `docs/` or the roadmap pack. Two unnumbered tracks exist and could be what
was meant; neither is assigned here:
- **World Exploration, Dungeons & Encounters** (`docs/directives/2026-10-21_master_expansion_roadmap.md` lines 222-234;
  `docs/roadmap/Exploration_Combat.md` on wip/roadmap-docs; references B14-09, CQ-01, FR-01, sword combat). Depends on combat,
  caves and the monster art; overlaps Expansion 26 (conflict 1).
- **Player-hosted Multiplayer** (parallel track, MP-01, `wip/multiplayer`, `docs/directives/2026-10-19_multiplayer_foundation.md`).

## 9. Is Expansion 20 ready for implementation authorization?

**Ready to be authorized, with three owner steps first:**
1. Approve the Expansion 20 architecture (`docs/expansion20/LE00_BUILD18_REFRESH.md`, `docs/expansion20/LE01_DATA_CONTRACTS.md` on wip/expansion20-preparation), already recommended in the
   2026-10-23 decision packet.
2. Answer OD-LE-02B (offer visibility) and OD-LE-10 (knowledge), which block the Offer and Knowledge records of LE-01;
   recommendations are in `docs/design/OWNER_DECISION_PACKET_2026-10-23.md` s.4. OD-LE-04/07 (business identity), 13B, 05B and 15
   are needed by LE-03, LE-04 and the budgets, and can follow.
3. Authorize Batch 0 (both prospective branches onto Build 19).

The Need record and the approved pricing and negotiation need nothing beyond step 1.

## 10. Questions for the owner

| Id | Question | Recommendation |
|---|---|---|
| ROAD-Q1 | Expansion 27: which specification is it? | if it is World Exploration, Dungeons & Encounters, number it 27 and keep its master-roadmap phases; multiplayer stays a parallel track |
| ROAD-Q2 | 23's reach before 22 | the boundary in section 3: village, existing roads and off-map books; route banditry across the continuous map in 22-E |
| ROAD-Q3 | Skeletons, lizards and spiders: in 26 (as moved 2026-10-23) or in the exploration track? | keep them in 26 with the other monsters; the exploration track keeps dungeons and encounters |
| ROAD-Q4 | Building condition: design it with 22-D (abandonment) or with 25 (disasters)? | with 22-D, if 22 needs decay; 25 reuses it |
| ROAD-Q5 | Batch 0 (bring 20 and 21 onto Build 19) right after Build 19's acceptance? | yes, as the first authorized step |
