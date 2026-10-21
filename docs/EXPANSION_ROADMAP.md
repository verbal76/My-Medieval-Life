# Roadmap: Builds 15-19 and the three expansions

**Owner directive:** 2026-10-20 (`docs/directives/2026-10-20_two_decisions_three_expansions.md`). The three supporting documents in `docs/directives/` are the primary specifications.

These are three independent expansions:

| | Register | Specification |
|---|---|---|
| A | Mining & Industrial Development: EXP-A, phases MIN-A..G | `My_Medieval_Life_Mining_Industry_Expansion.pdf` |
| B | Settlement Advancement & Regional Economy: EXP-B, phases SET-A..E | `My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf` |
| C | NPC Judgment System: EXP-C, gates SJD-A..H, open decisions SJD-Q01..Q14 | `My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf` |

Each has its own phases, tests, integration review and build decision. None is started; none interrupts the Build 15–16 equilibrium work (EQ-16). The directive assigned no build numbers; the owner's roadmap below (ROAD-01, the same day) did.

## Official expansion numbering (owner, 2026-10-21, register OD-30)

17 Mining & Industrial Development, 18 Settlement Advancement & Regional Economy, 19 NPC Judgment (all three as before);
**20 Living Economy, 21 Village Politics, 22 Bandit Factions, 23 Generational Legacy**; World Exploration unnumbered until
its scope and dependencies are established; Multiplayer a separate track
(`docs/directives/2026-10-21_expansion_numbering_approval.md`). This is organization and sequencing only: it approves no
open design decision, authorizes no implementation of a future expansion and sets no release date. The starter
specifications and their comparisons are on `wip/roadmap-docs` (`docs/roadmap/`).

## The owner's five-build roadmap (2026-10-20, register ROAD-01)

| Build | Content |
|---|---|
| 15 | Simulation stabilization: population, housing, wildlife, resources, economy, relationships |
| 16 | Long-term equilibrium and validation: the baseline before the expansions |
| 17 | Expansion A, Mining & Industrial Development |
| 18 | Expansion B, Settlement Advancement & Regional Economy |
| 19 | Expansion C, NPC Judgment System |

Every open register entry carries `target_build` (15–19, `20+`, `multiplayer`, `owner decision` or `owner action`) with a gate and a reason. `tools/check_requirements.py` refuses an open entry without one. The item-by-item table is the "Roadmap" section of `docs/DEVELOPMENT_LEDGER.md`, generated from the register.

The mining specification itself proposes "a dedicated Build 17 or 18". The owner's roadmap (ROAD-01) settled it as Build 17.

**Dependencies that touch the order (none forces a change):**
- **SET-A in Build 17.** Mining capability levels (MIN-D, Build 17) are settlements' first industry capability. The settlement capability schema (SET-A, Build 18's design phase) should be designed during Build 17 so MIN-D builds on it. This is design only, and part of Build 17: it starts only when the owner authorizes Build 17. Build 18 still implements the model.
- **MIN-E and MIN-F.** Open-pit and underground mining depend on MIN-A's finding about layered terrain. If the terrain cannot carry depth, these slip to Build 20 or later, and Build 17 ships phases A–D and G.
- **EQ-09, stone, and owner decision OD-10.** In the Build 15 runs stone reaches 0 by about day 160–190 (56 and 115 of 240 were left at day 100), and house sites then stall. Iron, coal, copper and gold run out by about day 20. With no lasting stone source before the quarry chain (MIN-B, Build 17), the Build 16 baseline must either accept caravan stone imports as the stand-in or move MIN-B earlier. That choice is OD-10, the owner's; EQ-09 is BLOCKED on it.
- **Build 19 needs the owner's answers.** Its 14 open design questions (SJD-Q01..Q14) stay unanswered until the owner answers them. The design audit and isolated prototype can proceed; live integration cannot.
- **VP-01, generational memory and legacy.** Village politics (VP-01), generational memory (GM-01) and legacy (WDR-014) are approved but named in none of the five builds. GM-01 is placed in 19 as the closest fit, to confirm. Politics follows 19, because voting weighs judgment.

## The Living Economy Expansion: a standalone build (owner, 2026-10-20; register EXP-D)

The owner's design, `docs/directives/My_Medieval_Life_Living_Economy_Standalone_Build_Design.docx` (text beside it), is
**its own major build**, not a Build 16 item:
- needs drive behaviour;
- prices are offers;
- accepted orders are real obligations, with reservations, credit and contracts;
- knowledge is bounded;
- safety levers are organic, never hidden rescue.

It must integrate the NPC brain, households, employment, production, construction, markets, caravans, mining, the
manor, bandits and the NPC Judgment hooks. Builds 16-18 go ahead as approved, and are not delayed for it.

| | |
|---|---|
| Stages | LE-00 (a read-only architecture audit) to LE-07 (release), the register's children of EXP-D |
| Open owner decisions | OD-LE-01..OD-LE-15. OD-LE-01 is its build number and placement |
| Placement | **Proposed** (agent, for OD-LE-01): Build 20, right after Build 19's NPC Judgment, whose trust and reputation it uses. The 20+ items that depend on markets and contracts (village politics' economic levers, bandit factions' trade) would follow it. Build 19 is not displaced. Not decided |
| Earlier builds | May expose compatible interfaces (one ledger, one inventory, events), never implement it early |

## World Design Rules each one serves

| Expansion | Rules (register `rules` field) |
|---|---|
| A Mining | 001 material interdependency, 002 professional interdependency, 003 meaningful recipes, 004 economic consequences, 005 living-world independence, 007 automated compliance, 013 finite resources |
| B Settlements | 001, 002, 004, 005, 009 emergent gameplay, 011 NPC self-improvement, 012 competition, 013, 015 political authority and civic employment |
| C Judgment | 005, 009, 010 depth without obscurity, 012, 015, 016 bandit factions, 017 generational memory, 019 political agency |

## Dependencies

**Shared foundations, before any of the three:**
- Build 16 equilibrium (EQ-16): a stable, measured baseline. All three documents require it, and C names it as Gate A.
- Save continuity (SAVE-00, done for PC; phone check pending). All three add saved state, and migrations go through `SaveTransfer.MIGRATIONS` with fixture tests.
- The long-run harness (`economy_sim.gd`) with exact conservation of coins, goods, animals and deposits. All three use it as their acceptance gate.

**A depends on:**
- the terrain, elevation and navigation audit (MIN-A), which also bears on B14-07 cliff steps;
- the deposit model, resources.json, recipes and professions.

Phases E and F (open pit, underground) depend on what MIN-A finds about layered terrain. The document itself says not to assume it.

**B depends on:**
- a settlement capability schema (SET-A, SET-B). A's capability levels (MIN-D) are the first industry to use it, so SET-A's schema design should come before MIN-D. The capability model itself stays part of B;
- the caravan placeholder (CARAVAN-TMP), which it replaces in SET-C;
- several settlements (SET-E), which need a larger map; REC-007 is related. SET-E is therefore targeted at Build 20 or later, so Build 18 holds SET-A..D.

**C depends on:**
- the Build 16 baseline (SJD-A);
- an audit of every decision point (SJD-B);
- an event record of what happened: theft, help, harm, trade. This exists partly today in `World.witness`, `player.crimes`, `Relations.harmed` and NPC memories.

C replaces today's fixed thresholds, CRT-12's notoriety refusal and the single regard score, with weighed judgment. That conflict is recorded on CRT-12 and EXP-C.


- **Professional stonecutting (X18-STONECUT, owner 2026-10-21) → Expansion 18.** Depends on Build 17's STONE-01 (the
  `dress_stone` recipe and building blocks), the one capability evaluator (PROS-18, Q18-9), ordinary market transactions
  and general procurement contracts (CON-01/CON-02). It shares its production mechanics with personal stone dressing
  (STONE-02) and the finer repair-material split (STONE-03), both also Expansion 18. Expansion 19 adds no second
  stonecutting profession. Not a Build 17 release blocker.

## Proposed sequence (agent proposal, before ROAD-01; superseded where it differs)

> The owner's roadmap (ROAD-01, above) fixes the order: A in Build 17, B in Build 18, C in Build 19. Where this earlier proposal differs (running C's audit and prototype alongside A, B after C's first gates), the roadmap wins; those ideas would need the owner's approval to change the order. SET-A's design during Build 17 is the one dependency the roadmap records.

1. **Now, Builds 15–16:** equilibrium (EQ-01..08, WR-01, CRT-*), save continuity, the caravan as a labelled 30-coin placeholder. Then the 100- and 365-day multi-seed acceptance runs (EQ-06).
2. **First after Build 16: Expansion A, phases MIN-A to MIN-D.**
   - Audit, quarry stone after ore, prospecting and assay, finite hidden deposits, capability levels 1–2.
   - It answers the most pressing problem the runs show: iron and coal run out by about day 10–20, and stone by day 160–190 (Build 15 runs).
   - SET-A (the capability schema design) runs alongside so MIN-D builds on it rather than on something mining-only.
   - Open-pit and underground mining (MIN-E, MIN-F) follow as their own milestone once MIN-A has settled the terrain question.
3. **Expansion C, gates B to D:** the audit and an isolated prototype with no effect on live behaviour. These can run in parallel with A, since they change nothing in play. Live integration (gate E onward) waits until A's simulations are stable, so changes in behaviour can be traced to one cause.
4. **Expansion B, phases SET-B to SET-E:** the capability model, the abstract regional economy replacing the caravan allowance, and settlement growth. It goes after A because mining is its first industry, and before or alongside C's later gates. The full inter-settlement network (SET-E) needs the larger map.
5. **Expansion A, phases MIN-E to MIN-G,** and C's gates F to H, as their prerequisites allow.

Each step ends with its own multi-seed 100- and 365-day runs, save-migration tests and a build decision under the release rules then in force.
