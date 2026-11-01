# Exploration and Combat: starter compared with the owner's directives and the register

Prepared 2026-10-21 on `wip/roadmap-docs` (documentation only). Compares `docs/roadmap/Exploration_Combat.md` with its
cited sources: register entries B14-09, CQ-01 and FR-01 (and the related REC-006, DGA-D9, OWN-28, DVW-A9, DVW-B6,
DVW-B9, FR-10), `docs/directives/2026-10-19_sword_combat.md`, `docs/WORLD_DESIGN_RULES.md` Rules 013, 016, 018 and
022, `docs/DECISIONS.md`, and the Build 17 owner decisions (`2026-10-21_build17_architecture_mining_contracts_decisions.md`,
`2026-10-21_build17_start_underground_contracts.md`). Code facts read at staging `b3bbb1c` and `origin/wip/build17` `0fd94b3`.

**Labels.** **APPROVED** (owner source cited) · **STARTER DRAFT** · **OPEN DECISION** · **FACT**.

## 1. Summary

- Only three pieces of this grouping are owner-approved work items: **CQ-01** sword fixes (done in automated tests,
  device check pending), **B14-09** skeletons, and **FR-01** lizards and spiders (BLOCKED on assets). Everything else
  is grouping, proposal or deferred. The starter says so itself ("NOT a fully approved expansion"); that is correct.
- **Source gap:** the starter cites "docs/DECISIONS.md, cave skeletons"; `DECISIONS.md` has the lizards-and-spiders
  entry (2026-10-18) and the magic entry (2026-10-17) but **no skeleton entry**. B14-09's only record is the register
  ("owner answers 2026-10-19"); no verbatim owner text for it was found in `docs/directives/`. FACT.
- **One real tension:** B14-09's three-day respawn with bone and rusty-gear drops is a recurring item source, which
  Rules 013 and 022 ("no fabricated materials", "every item with a legitimate history") forbid unless it is an
  explicit, accounted faucet. See C1.

## 2. Section-by-section comparison

| Starter section | Statement (abridged) | Label and source | Register ids |
|---|---|---|---|
| Purpose and scope | Exploration through a consequential world; combat, hazards, ruins, caves, creatures tied to inventory, risk, memory, wildlife, economy | STARTER DRAFT (grouping); the consequence principle is APPROVED (Rules 009, 013, 022) | - |
| | Reuse sword-combat work; no rewrite without a defect | APPROVED: sword directive ("Inspect the actual combat implementation before changing it") | CQ-01 |
| World and locations | Build from existing terrain, caves, woods, settlements, underground maps | APPROVED in part: overworld exists (OWN-05, B8-011); separate underground maps tied to surface locations (OD-29, 2026-10-21). Ruins and dungeons: STARTER DRAFT (REC-006 DEFERRED) | OWN-05, OD-29, MIN-H, REC-006 |
| | Loot legitimate and bounded | APPROVED: Rules 013, 022 | WDR-013-C, WDR-022-C |
| Combat mechanics | Audit buffering, reach, phases, walls, knockback | APPROVED: sword directive; done in automated tests (combat_test 41 checks, `3e283b6`), device test pending | CQ-01 |
| | Use existing equipment, health, stamina; no new stat system | STARTER DRAFT (prudent default; DGA-D6 "combat model" is an open owner proposal) | DGA-D6 |
| | Record injuries, deaths, rescues, crimes, battles, witnesses, damage for judgment, guards, history | APPROVED: 2026-10-19 directive Part I s.7 | GM-01, PAR-05 |
| Approved creature content | B14-09 skeletons: caves and uncleared woods, guard by day, roam at night, 3-day respawn, bones and rusty gear | APPROVED: register B14-09 (owner answers 2026-10-19; verbatim text not located) | B14-09 |
| | FR-01 lizards and spiders, assets missing | APPROVED: DECISIONS 2026-10-18 ("good enemies"); BLOCKED on assets | FR-01 (supersedes OWN-24) |
| | Other dungeons, castles, enemies are proposals | APPROVED as a boundary: REC-006 DEFERRED; owner's B8-011 directive called castles, ruins, caves and towns "future possibilities, not authorization" | REC-006 |
| Ecology, faction, mining | Wildlife not infinite; refuges and recolonisation preserved | APPROVED: Rule 018; Part II | WR-01, WDR-018, EQ-02 |
| | Bandit encounters use factions, supplies, witnesses | APPROVED: Rule 016 | WDR-016-C |
| | Mining caves: same deposit objects and depletion above and below ground | APPROVED: OD-28 ("one deposit system everywhere") | OD-28, MIN-H |
| Progression and interface | Discoveries affect map knowledge, dialogue, contracts, trade; rewards legitimate | STARTER DRAFT (contracts: CON-01, APPROVED in principle) | CON-01 |
| | Android attack prompts, feedback, target selection, keyboard dismissal; controller and keyboard | APPROVED: sword directive "Platform consistency"; Rule 010 | CQ-01, B12A-10 |
| Phases EX-A..E | Audit; sword usability and skeletons; location state and loot; integration; assets and device tests | STARTER DRAFT | - |
| Acceptance | Reach, phases, walls; device testing | APPROVED: sword directive acceptance | CQ-01 |
| | Skeleton day/night and three-day respawn, bounded and traceable drops | APPROVED (B14-09) plus STARTER DRAFT "bounded and traceable" (see C1) | B14-09 |
| | Wildlife kills have ecological consequences; theft creates loss and evidence | APPROVED: Part II s.16; Rule 013; PAR-05 | WR-01, PAR-05 |
| | Save/load cannot duplicate enemies, corpses, treasure; identical depletion in caves | APPROVED: Rule 013; OD-28 | WDR-013-C, OD-28 |
| Open scope boundaries | No handcrafted dungeons, magic combat, monster classes, skill trees, bosses without approval | APPROVED as a boundary (REC-006 deferred; DGA-D9 magic is an owner decision; FR-10 archery "not authorised") | REC-006, DGA-D9, FR-10 |

## 3. What the starter adds

- Grouping exploration, combat and creatures into one track with five phases (STARTER DRAFT).
- Map knowledge and discovery feeding dialogue, contracts and trade (STARTER DRAFT).
- The Master Roadmap adds "a vast explorable overworld, broader county ... learnable, rule-based magic". Of these, the
  overworld exists (OWN-05, B8-011, generated and chunk-streamed); "learnable magic" is an owner decision of
  2026-10-17 in `DECISIONS.md` (APPROVED in principle), but its mechanics (J-M1..4, DGA-D9) are open; "vast" and
  "broader county" are not owner-scoped (DGA-D8 BLOCKED). STARTER DRAFT beyond that.

## 4. What the starter omits

1. **Player can always escape predators and bandits** (DVW-A9, APPROVED, not started; no escape logic found).
2. **Readable danger**: howl and roar cues, lethal-need warnings, cause of death on the succession screen (DVW-B9).
3. **Wildlife wandering in from the overworld** (DVW-B6, DEFERRED, target 18), which governs where creatures come from.
4. **Archery is planned but not authorised** (sword directive; FR-10 DEFERRED). The starter's "no new combat" boundary
   covers it implicitly.
5. **Cliff steps, stairs and walkways** (B14-07, target 17) and **no black-hole spaces** (DVW-A10), prerequisites for
   cave and wood navigation; B14-09's register `next_action` is "After B14-07".
6. **Multiplayer combat**: guest swings as host-validated requests (`docs/MULTIPLAYER.md` on `wip/multiplayer`);
   DGA-D6 (combat model and latency) is an open owner proposal.
7. **Asset pipeline**: skeleton, cave-interior (Puny Dungeon, "planned") and enemy art must enter through the
   mandatory `asset-integration-pipeline` skill (CLAUDE.md asset integration policy).

## 5. Contradictions and tensions

| # | Issue | Evidence | Label |
|---|---|---|---|
| C1 | **Respawn vs finite world.** B14-09 approves a three-day respawn with bones and rusty gear; Rule 013 forbids "infinite or purely decorative production" and Rule 022 forbids "fabricated materials". A respawning skeleton's drops are new items each cycle. Options: (a) an accounted faucet like the caravan (a named source in the faucet/drain ledger, DVW-A4) with a cap; (b) skeletons respawn without drops after the first; (c) drops come from a finite cave stock that depletes; (d) skeletons return only where a "source" exists (a burial ground that empties). | register B14-09; Rules 013, 022; DVW-A4 | OPEN DECISION (owner: the respawn itself is approved; the item source is not specified) |
| C2 | **Cave mining vs dungeon content.** The Master Roadmap warns against merging cave-mining architecture with dungeon gameplay; the starter lets "mining caves contain exploration threats". The underground maps of OD-29 would carry both. Recommendation: one level format (`level_map.gd` on `wip/build17`) with content kept in separate systems. | Master Roadmap; OD-29; FACT: `wip/build17` adds `level_map.gd`, `underground.gd` | Engineering decision, recorded |
| C3 | **Register reason text.** B14-09's `roadmap_reason` groups skeletons with bandit factions as "combat content outside the five builds"; factions are a different expansion (22). | register B14-09, WDR-016-C | FACT; update when touched |

## 6. Missing technical decisions (open questions)

Owner-level:
- **Q-EX-1** C1: where skeleton drops come from.
- **Q-EX-2** Which locations count as "uncleared woods" and whether clearing is permanent (who clears them; can they
  return?).
- **Q-EX-3** Whether exploration is a numbered expansion at all, and its order relative to 17-23.
- **Q-EX-4** Magic scope (DGA-D9, J-M1..4) before any magic combat.
- **Q-EX-5** Map scale and the county beyond the overworld (DGA-D8), also needed by SET-E.
- **Q-EX-6** Fast travel rule (DVW-B11, a BLOCKED proposal).

Engineering-level: encounter state schema and save keys; skeleton AI on the existing `Combat` and `Fauna` patterns;
cave entrances as `underground.json` portals; deterministic spawn streams (not `world.rng`, so other streams do not
shift); performance budgets on Android.

## 7. Repository facts for EX-A

- FACT: `combat.gd` (142 lines) and `combat_test.gd` (CQ-01, 41 checks); fireball exists ("magic beyond fireball",
  OWN-28); `magic` is one of nine skills in `skills.json`.
- FACT: no `skeleton` or `dungeon` in `game/scripts`; `cave` appears only in wildlife refuges (`refuges.gd`, `fauna.gd`).
- FACT: the overworld is generated and chunk-streamed (`overworld.gd`, `GEN_VERSION`); villagers stay inside the
  village map.
- FACT: `wip/build17` (not staging) adds the underground foundation (`underground.gd`, `level_map.gd`,
  `level_view.gd`, `game/data/underground.json`, `underground_test.gd`).
