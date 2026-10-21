# 22 Bandits: starter compared with the owner's directives and the register

Prepared 2026-10-21 on `wip/roadmap-docs` (documentation only). Compares `docs/roadmap/22_Bandits.md` with its cited
sources: `docs/WORLD_DESIGN_RULES.md` Rule 016 (and 013, 021, 022), `docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md`
(OD-11), `docs/directives/2026-10-20_fam07_clarification_living_economy.md`, the Living Economy design (sections 9, 10, 12)
and the register (read-only). Code facts read at staging `b3bbb1c`.

**Labels.** **APPROVED** (owner source cited) · **STARTER DRAFT** · **OPEN DECISION** · **FACT** (code or register today).

## 1. Summary

- Rule 016 is the owner's full requirement; the starter restates nearly all of its eight bullets correctly.
- **One substantive omission:** the owner's FAM-07 clarification that a child raised in the clan is *not* bound to
  banditry at adulthood (FAM-08). The starter covers the child's status but not the adult's free choice.
- **One dependency conflict:** the starter requires fencing to use "existing Living Economy infrastructure", which does
  not exist yet (EXP-D not started, placement undecided under OD-LE-01). The only existing goods-contract mechanism is
  CON-01 on `wip/build17` (first slice, not on staging).
- Existing code already implements several pieces the starter treats as future (section 7), so P22-A must audit before
  designing.

## 2. Section-by-section comparison

| Starter section | Statement (abridged) | Label and source | Register ids |
|---|---|---|---|
| Purpose | Bandits are autonomous people and factions, not disposable spawns | APPROVED: Rule 016 bullet 1 | WDR-016-C (supersedes REQ-BANDIT) |
| | Player and NPC discover, join, advance, challenge leadership, run a hideout, face consequences | APPROVED: Rule 016 bullets 3-5 | WDR-016-C |
| | Factions grow, fracture, decline, collapse without scripted prosperity | APPROVED: Rule 016 bullet 7; Rule 022 | WDR-016-C, WDR-022-C |
| Persistent faction state | Faction id, name, members, ranks, leader, succession, hideout, territory, supplies, treasury, relationships, recruitment, planned actions, crimes | STARTER DRAFT as a schema; each element is required by Rule 016 bullets 3-8 | WDR-016-C |
| | Members need real food, shelter, tools, weapons, labour, currency | APPROVED: Rule 016 bullet 7; Rule 013 | WDR-016-C, FSE-B06 |
| | Raid loot moves from actual victims; stolen goods keep provenance "where possible" | APPROVED: Rule 013, Rule 022 ("every coin and item with a legitimate history"); "where possible" is a STARTER DRAFT softening | WDR-013-C, DVW-A4 |
| Criminal careers | Theft, burglary, livestock theft, robbery, smuggling, raids, fencing | APPROVED: Rule 016 bullet 2 | WDR-016-C |
| | Detection depends on witnesses, evidence, information transmission | APPROVED: OD-18.5 / PAR-05; OD-20 / PICK-01 | PAR-05, PICK-01 |
| | Separate reputations among bandits, households, merchants, law | APPROVED: Rule 016 bullet 6 (bandits, villagers, guards); merchants as a fourth audience is STARTER DRAFT | WDR-016-C |
| Leadership and economy | Advancement and challenges by support or duels; failure has risk | APPROVED: Rule 016 bullet 4 | WDR-016-C |
| | Leaders allocate jobs, raids, recruitment, supplies, loot, hideout | APPROVED: Rule 016 bullet 5 | WDR-016-C |
| | Members may refuse orders by judgment, danger, needs, relationships | STARTER DRAFT, consistent with the Judgment spec's "judgment influences, never dictates" (EXP-C) | EXP-C, SJD-F |
| | Fencing and purchases through the Living Economy, no duplicate black-market ledger | "No duplicate ledger": APPROVED (Rule 006; 2026-10-19 directive's "no competing sources of truth"). "Through the Living Economy": STARTER DRAFT (see C1) | EXP-D, OD-LE-09, CON-01 |
| Law and families | Guards investigate with real funding, staffing, evidence, knowledge; bounties authorised and funded | APPROVED: Rule 015 bullet 6; Rule 016 bullet 6; PAR-05 | WDR-015-C, PAR-05 |
| | Orphan fallback: child joins the clan, stays a child, genealogy intact, no adult combat | APPROVED: OD-11 (Rule 021 owner answers) | FAM-07 |
| Phases P22-A..F | Audit; identity; hideout economy; autonomous crime; player career; long runs | STARTER DRAFT | WDR-016-C (no children yet) |
| Acceptance | A faction steals a real animal; witnesses report only plausible knowledge | APPROVED: Rule 013, PAR-05 | WDR-016-C |
| | Player joins, advances, challenges, can fail; NPC succession autonomous | APPROVED: Rule 016; original acceptance check 5 | WDR-016-C |
| | Valid food and wage sources; no infinite loot or unbounded respawn | APPROVED: Rule 013, Rule 022 | FSE-B06, EQ-20 |
| | Unplaced children keep age, history, child behaviour | APPROVED: OD-11 | FAM-07 |

## 3. What the starter adds

- A concrete faction state schema and six phases (STARTER DRAFT).
- Merchants as a separate reputation audience (STARTER DRAFT).
- Members refusing orders (STARTER DRAFT; consistent with EXP-C).
- Roadmap's "orphan-clan fallback must preserve child status" restates OD-11 (APPROVED).

## 4. What the starter omits

1. **FAM-08 (APPROVED, owner 2026-10-20):** "When they reach adulthood, their circumstances, relationships,
   opportunities, needs, and personal decisions should determine their future. Remaining with the bandits is one
   possible outcome, not a mandatory one." The interim rule is in code (`Guardianship.leave_camp`); the full choice
   needs EXP-C and this expansion.
2. **Historical and graveyard records of outlaw careers** (Rule 016 bullet 8; Rule 014 bullet 5). The starter's
   P22-E mentions "historical records" only.
3. **Leaders manage faction relations and territory** (Rule 016 bullet 5): present in the schema but not in any phase.
4. **The owner's deferral of desperation crime.** FR-09 "Crime from desperation" is DEFERRED by the owner ("no
   desperation crime yet"), target 19 with "owner decision first". Any P22 career that lets villagers turn to crime
   from need must wait for that owner decision.
5. **Player escape from bandits** (DVW-A9, APPROVED, not started) and **readable danger** (DVW-B9).
6. **Host authority in multiplayer** (2026-10-19 directive s.35 lists crime under host authority).

## 5. Contradictions and tensions

| # | Issue | Evidence | Label |
|---|---|---|---|
| C1 | Fencing "must use existing Living Economy infrastructure" but the Living Economy does not exist and its placement is undecided; bandit market participation is itself an open owner decision. | register EXP-D (NOT STARTED), OD-LE-01, OD-LE-09 (BLOCKED) | OPEN DECISION |
| C2 | Current bandits already spend hoards at the market and guards return unclaimed loot to the treasury (EQ-20, owner OD-16 a, COMPLETE). A faction treasury and loot division must keep this flow, not replace it silently. | FACT: `npc_brain.gd::_bandit_market`, loot recovery; EQ-20 | Constraint, not a contradiction |
| C3 | "Stolen goods retain provenance where possible" weakens Rule 022's "every coin and item with a legitimate history". Recommendation: provenance always for custody (who holds it, from whom), optional only for display. | Rule 022 | OPEN DECISION (engineering default proposed) |
| C4 | The register's roadmap reason for WDR-016-C groups "bandit factions, skeletons, castles, dungeons" as "combat content". The roadmap and starter correctly separate factions from dungeon content; the register's reason text is stale. | register WDR-016-C `roadmap_reason` | FACT; the reason text should be updated when the entry is next touched |

## 6. Missing technical decisions (open questions)

Owner-level:
- **Q-BAN-1** How many factions exist at world start (today one band of `bandits: 6`), and whether new factions may form
  only by schism or also arrive from outside (migration rules; FR-11 is UNKNOWN).
- **Q-BAN-2** Leadership contest rules: duel to injury or death, support vote, both; consequences of a failed challenge.
- **Q-BAN-3** Recruitment requirements and whether villagers may be recruited from need (ties to FR-09).
- **Q-BAN-4** Legal consequences: fines, imprisonment, outlawry, execution; jurisdiction of the constable vs the lord.
- **Q-BAN-5** Bounties: who may fund one and whether the player may claim it.
- **Q-BAN-6** Whether children of the clan may be trained in non-combat outlaw work (scouting, fencing) before adulthood.

Engineering-level (documented defaults): faction state schema; rank tables in `balance.json`; raid planning cadence;
faction reputation storage as SJD ledgers keyed by faction members (no parallel reputation store).

## 7. Repository facts for P22-A

- FACT: one bandit band created at world start (`Population`, `bandits: 6` in `balance.json`) at the fixed
  `bandit_camp`; no respawn code (the only other `role = "bandit"` assignment is a clan child coming of age with no
  household to take them, `life.gd`).
- FACT: bandits stalk and rob at night, poach and spend coins at the market by day (`npc_brain.gd::_bandit`,
  `_bandit_market`); they eat only real food (FSE-B06); guards recover loot with coins to the treasury (EQ-20).
- FACT: clan children (`NPC.clan == "bandit"`) eat at the camp and are safe from raids; at adulthood
  `Guardianship.leave_camp` places them with kin or a household with room, else they join the band (FAM-07 interim).
- FACT: the player can fence stolen goods and pickpocket; crimes are recorded in `PlayerState.crimes` (player only;
  NPC crimes have no record).
- FACT: no faction, rank, leader, hideout ownership or faction treasury exists.
