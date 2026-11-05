# Build 26: Creatures and Heroes

Generated from `docs/requirements/requirements.json` by `python3 tools/check_requirements.py --write`. Do not edit: change the register (`tools/requirements_update.py`) and regenerate.

> **Implementation of Build 26 is NOT AUTHORIZED.** PET-01, MON-01 (owner 2026-10-23): design only, no code Nothing below is implemented work.

Readiness: **NOT AUTHORIZED for implementation**

| Count | Value |
|---|---|
| Approved requirements in scope | 5 |
| Integrated | 0 of 5 (0%) |
| Automated tests passed | 0 of 5 (0%) |
| Integration verified | 0 of 5 (0%) |
| Gameplay verified | 0 of 5 (0%) |
| Owner playtested | 0 of 5 (0%) |
| Complete | 0 of 5 (0%) |
| Open (release blockers) | 5 |
| Open owner decisions (blocking) | 9 (0) |

## Blocked (open owner decision, unfinished dependency or unsettled design) (5)

| ID | Requirement | Approval | Implementation | Code (branch, commit or build) | Verification | Remaining work | Blocked by / owner decision | Effort |
|---|---|---|---|---|---|---|---|---|
| B14-09 | Skeletons in caves and uncleared woods (guard by day, roam at night, 3-day respawn; bones and rusty gear) | OWNER APPROVED | NOT STARTED | none | NOT TESTED | owner reviews docs/design/EXPANSION26_CREATURES_AND_HEROES.md; no code before approval | design: UNKNOWN | UNKNOWN |
| CREATURE-OWN | Creature ownership: Expansion 26 owns the behaviour, survival, combat and other creature-specific mechanics of skeletons, lizards, spiders and its other creatures; Expansion 27 owns their placement in its exploration environments and encounters; no duplicate creature behaviour systems | OWNER APPROVED | NOT STARTED | none | NOT TESTED |  | design: UNKNOWN | UNKNOWN |
| FR-01 | Lizards and spiders as enemies | OWNER APPROVED | NOT STARTED | none | NOT TESTED | owner reviews docs/design/EXPANSION26_CREATURES_AND_HEROES.md; no code before approval | design: UNKNOWN | UNKNOWN |
| MON-01 | Monsters, village defence, bounties and monster goods: skeletons underground and in the woods, lizards, a crab monster and boss monsters in forests and hills; rare attacks on the village where guards go first and villagers form a defensive line; the player can become a hero of the town; bounties to hunt monsters and bring back their pelts, building prestige; villagers may choose to become monster hunters; a market for specialty goods only monsters give; all of it moving villagers' emotions, their view of the player and their sense of safety | OWNER APPROVED | NOT STARTED | none | NOT TESTED | owner reviews docs/design/EXPANSION26_CREATURES_AND_HEROES.md; no code before approval | E26-OD-01, E26-OD-02, E26-OD-03, E26-OD-04, E26-OD-05, E26-OD-06, E26-OD-07, E26-OD-08, E26-OD-09, design: UNKNOWN | UNKNOWN |
| PET-01 | Taming small wild animals as pets (foxes, wolves, rabbits): with their liked food in hand the player gets an action to try; a few feedings tame the animal and it follows; a marker over an animal already tried; husbandry skill makes it quicker (about three feedings unskilled, one or two when skilled) | OWNER APPROVED | NOT STARTED | none | NOT TESTED | owner reviews docs/design/EXPANSION26_CREATURES_AND_HEROES.md; no code before approval | E26-OD-01, E26-OD-02, E26-OD-03, E26-OD-04, E26-OD-05, E26-OD-06, E26-OD-07, E26-OD-08, E26-OD-09, design: UNKNOWN | UNKNOWN |

## Open owner decisions (9)

| ID | Question | Disposition | Blocks | Affects |
|---|---|---|---|---|
| E26-OD-01 | Foxes: pets only, or also companions? (recommendation: companions too; only their pen use is pets-only) | OPEN | no | MON-01, PET-01 |
| E26-OD-02 | Monster respawn (recommendation: skeletons 3 days as approved, spiders alike; a killed boss not back for a game year, some never) | OPEN | no | MON-01, PET-01 |
| E26-OD-03 | How often a monster attacks the village (recommendation: about once in several game years, never more than one at a time) | OPEN | no | MON-01, PET-01 |
| E26-OD-04 | Bounties when the treasury is empty (recommendation: no bounty without the coins; villagers may pool coins) | OPEN | no | MON-01, PET-01 |
| E26-OD-05 | Bounty prices (recommendation: set by the reeve within an owner-approved band, proposal 20-60 coins monsters, 150-400 bosses) | OPEN | no | MON-01, PET-01 |
| E26-OD-06 | Monster goods recipes (recommendation: one special item per boss plus bones and rusty gear from skeletons) | OPEN | no | MON-01, PET-01 |
| E26-OD-07 | Companion combat numbers (recommendation: wolf about a wild wolf, fox weaker but quicker; heal with rest and food) | OPEN | no | MON-01, PET-01 |
| E26-OD-08 | Can villagers' pets or guard dogs fight in village defence? (recommendation: guard dogs join the guards' line) | OPEN | no | MON-01, PET-01 |
| E26-OD-09 | When to build Expansion 26, and may phases 26-A..C and 26-F start before Expansion 25? | OPEN | no | MON-01, PET-01 |

## Not counted: umbrellas, proposals, ideas, deferred (1)

| ID | Item | Kind | Approval |
|---|---|---|---|
| EXP-26 | Expansion 26, Creatures and Heroes: taming, pets and companions, monsters and bosses, village defence, bounties, heroes, monster goods; owns creature behaviour (ROAD-Q3); designed with Expansion 25 as the 'Wild World' concept | umbrella | OWNER APPROVED |

