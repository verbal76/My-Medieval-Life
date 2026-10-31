# Expansion 26: Creatures and Heroes

**Current status:**
- **DESIGN ONLY, NOT AUTHORIZED.**
- Owner design answers are recorded; questions E26-OD-01..09 are open, and the packet is not yet approved.
- One genuine conflict needs the owner: the boss roster and hero status against OD-17 / D36 (2026-10-27).
- Priority 7.
- It forms one combined "Wild World" design scope with Expansion 25.
- **Next authorized phase: none until the owner authorizes it.**

Status vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 (DOC-RECON-01).

## Numbering, combined design scope and authorization

- **Number.** 26 = Creatures and Heroes.
  - Split from the one-day "Wild World 25" on 2026-10-23, at the owner's request (`2026-10-23_split_expansions_25_26.md`).
  - Adopted by name by the owner on 2026-10-24: priority "7 | 26 — Creatures & Heroes"; ROAD-Q3 "Skeletons, lizards, and
    spiders belong in Expansion 26, Creatures & Heroes".
- **Combined design scope.** Designed together with 25 as the "Wild World" concept. Owner 2026-10-23: "Merge with weather
  (25): one 'Wild World' expansion … designed as one". Full history in `EXPANSION_25.md`.
- **Authorization.** None. Owner 2026-10-24: "Keep … Creatures & Heroes in design-only status until specifically
  authorized". Owner 2026-10-30: "Do not begin Expansions 22–27". Register `builds.26.implementation_authorized: false`.

## Current approved scope

| Date | Owner decision | Source |
|---|---|---|
| 2026-10-24 | CREATURE-OWN: "Expansion 26 owns their behavior, survival, combat, and other creature-specific mechanics … Expansion 27 owns their placement … Do not duplicate creature behavior systems." | `docs/directives/2026-10-24_owner_roadmap_question_decisions.md` (ROAD-Q3) |
| 2026-10-23 | MON-01, with the answers: bosses "Crab and Buwaya", "Minotaur and yeti", "Necromancer", "Dragons"; defence "Guards, then volunteers"; rewards "Bounty coin", "Prestige and hero status", "Monster goods market", "Villager hunters" | `docs/directives/2026-10-23_monsters_bounties_companions_idea.md` |
| 2026-10-23 | PET-01: taming foxes, wolves and rabbits by feeding; marker; husbandry odds "By animal"; "Follows and stays", "Wolf defends you", "Villagers react", "Villagers tame too"; pens, with tame young; rabbits for meat and pelts; wolves as guard dogs; selling tame young; "Just pets". Companions: "pick a pet fox or a pet wolf as a companion" | `docs/directives/2026-10-23_animal_domestication_idea.md`, `2026-10-23_monsters_bounties_companions_idea.md` |
| 2026-10-19 | B14-09: skeletons in caves and uncleared woods (guard by day, roam at night, 3-day respawn; bones and rusty gear) | owner answers 2026-10-19 |
| 2026-10-18 | FR-01: lizards and spiders as enemies ("good enemies"). The art blocker was wrong: the art was supplied. | `docs/DECISIONS.md` |

**Specification:** `docs/design/EXPANSION26_CREATURES_AND_HEROES.md`, an agent-written packet with the owner's words in
its appendix. Its header reads: "design approved in parts by the owner; no code until the owner approves this packet."

## Implemented

Nothing. Checked on `origin/wip/expansion20` `ad281dc`: no taming, companion, monster, boss, bounty or skeleton code.

Existing wildlife, husbandry, pens, combat and the family-protection rule are reused, not rebuilt.

## Partial

None.

## Remaining approved work (approved design, not authorized)

- **PET-01, MON-01, B14-09, FR-01, CREATURE-OWN.** All NOT STARTED, target 26.
- **Packet phases.** These are an agent plan, not separately approved:
  - 26-A: taming and pets;
  - 26-B: pens and companions;
  - 26-C: monsters;
  - 26-D: bosses;
  - 26-E: village defence and heroes;
  - 26-F: bounties and hunters;
  - 26-G: release gate.

## Design only / not authorized

- The proposed architecture (packet §3): tameness record, escrowed bounties, monster goods as items and recipes, the
  hunter job, heroes through Expansion 19 judgment events with no separate fame score.
- The agent reading "foxes are kept as pets only", which is to be confirmed (E26-OD-01).
- The packet's note that phases A to C and F could start before 25. That needs the owner (E26-OD-09); the approved order
  is 25 → 26.

## Deferred and superseded

| Item | Status | By |
|---|---|---|
| PET-01 placement "Small add-on after Build 19 (Recommended)… before the bigger expansions" | SUPERSEDED | owner 2026-10-23 "Merge with weather (25)", then the split to 26 (register history of PET-01) |
| OWN-24 (lizards and spiders) | SUPERSEDED | FR-01 |
| FR-01 "blocked: no lizard or spider pack" | Corrected 2026-10-23 (art supplied) | register FR-01 history |
| DVW-B6 (wildlife wandering in from the overworld) | DEFERRED (owner 2026-10-21; target 18, now past) | related; not reassigned |

## Outstanding owner decisions

**Open questions from packet §5** (not registered yet; decision records are proposed):
- **E26-OD-01:** are foxes companions too, or pets only?
- **E26-OD-02:** monster respawn rules.
- **E26-OD-03:** how often a monster attacks the village.
- **E26-OD-04:** bounties when the treasury is empty.
- **E26-OD-05:** bounty prices.
- **E26-OD-06:** monster goods recipes.
- **E26-OD-07:** companion combat numbers.
- **E26-OD-08:** whether guard dogs fight in village defence.
- **E26-OD-09:** when to build it. The 2026-10-24 order puts 26 after 25; only the early-phases option stays open.

Also outstanding:
- **Approval of the packet.**
- **Implementation authorization.**

**CONFLICT for the owner (C-26-1).** It is not resolved here.
- **The 2026-10-23 decisions.** MON-01's boss roster: "Crab and Buwaya", "Minotaur and yeti", "Necromancer", "Dragons".
  "Prestige and hero status: defending the town or killing a boss makes the player a hero".
- **The 2026-10-27 decision** (OD-17 / D36, `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md`
  §4):
  - D36g "**GDD-REVIEW, PARK:** giant crab/dragon/necromancer/'boss' roster from old imported source is not approval to
    populate current MML. … No mandatory final boss or scripted heroic rank";
  - D36a "no preordained chosen-one, automatic special title, guaranteed heroic destiny or scripted award system. NPCs can
    still form opinions based on real deeds".
- **The difference.** D36g is later and names the same crab, dragon and necromancer. Its stated scope is the *old imported
  GDD* roster, not MON-01's answers in the current game, and the DCR-01 review (2026-10-27) listed D36's parked roster
  without comparing it to MON-01.
- **Two possible readings:**
  - (a) D36g parks only the GDD-sourced roster, and MON-01's bosses stand (the packet already makes hero status a judgment
    outcome with no title or fame score, which fits D36a);
  - (b) D36g also parks MON-01's boss roster until reconfirmed.
- **Owner approval required.** Nothing is built either way.

## Dependencies

- **Needs:**
  - 25: rivers and banks (crab, Buwaya), winter (yeti), building condition via E22-CONDITION, emergency response;
  - 20: monster goods market, escrow, conservation;
  - 21: the reeve's or mayor's bounties from the treasury;
  - 19: judgment, gossip and the family-protection rule.
- **Supplies to 27:** the one creature behaviour system that 27 places (CREATURE-OWN).

## References

- Register:
  - PET-01, MON-01, B14-09, FR-01, CREATURE-OWN;
  - OD-17, ROAD-Q3, ROAD-03;
  - `builds.26`.
- `docs/design/EXPANSION26_CREATURES_AND_HEROES.md`
- `docs/design/DECISION_CONTINUITY_REVIEW_2026-10-27.md` §2.
- Asset packs (unused): `Skeletons_Free_Pack.zip`, `MiniWorldSprites.zip` Monsters, `PUNY_MYTH-CREATURES-RPGMAKER_v1.zip`,
  `PunyMonsters.zip`.

## Missing sources

**The original owner-supplied "Creatures & Heroes" design packet: MISSING SOURCE, requiring recovery.**

No owner-authored or externally developed creatures packet exists on any branch. What exists:
- the agent packet above;
- the deleted Wild World draft (`git show 6c28fbc^:docs/design/EXPANSION25_WILD_WORLD_DESIGN.md`).

Its features are not unapproved because the file is absent. Nothing is reconstructed. See
`docs/expansions/MISSING_SOURCES.md`.
