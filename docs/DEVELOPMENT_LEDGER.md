# Development ledger (run of 2026-10-19)

The owner's master development execution directive (2026-10-19) authorises an autonomous run through
Build 11 punch lists 1 and 2 and approved work, ending in a private Android, Windows and Linux build
packet from one verified revision. Specifications: `docs/release/BUILD_11_PUNCH_LIST_1.md`,
`docs/release/BUILD_11_PUNCH_LIST_2.md` and the B8 master list `docs/release/BUILD_8_MASTER_FIXES.md`.
World intent: `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` and `docs/DECISIONS.md`. Interactions:
`docs/SYSTEM_INTERACTION_MANIFEST.md` (the one manifest; updated with each change). Player wiki: in game,
Settings > Wiki (PL2-009).

Statuses: NOT STARTED, IN PROGRESS, PARTIALLY COMPLETED, BLOCKED, COMPLETED (implemented), VERIFIED
(passed its tests and, for visual items, screenshots looked at). Nothing is checked on a device here.

| ID | Task | Status | Branch / commit | Notes |
|---|---|---|---|---|
| B8-029 | Calendar, aging, families, animal life cycles | VERIFIED | staging (merge of `b8-aging`) | 8-day year; explicit partners and parents; save version 14; aging_test 96 checks; baby and child screenshots looked at. Kept existing animal grow/breed days (rabbit 2, cow 6) per the owner's "preserve existing maturation" |
| B8-004 | Mine hill look (plateau, trees on its rim) | PARTIALLY COMPLETED | staging | Track and seams done |
| B8-007 | Tool swing art (villagers still show the staff) | PARTIALLY COMPLETED | staging | No tool-swing art in the character sheets |
| PL1-01 | Settings > Controls exit freezes the game | NOT STARTED | — | Critical |
| PL1-02 | One tabbed Settings screen with Back | NOT STARTED | — | Hosts the Wiki tab |
| PL2-009 | In-game player wiki | NOT STARTED | — | Top priority; generated from game data |
| PL1-03 | Merchant buy/sell quantity control | NOT STARTED | — | Shared control with PL2-012 |
| PL2-012 | Storage quantity and controller navigation | NOT STARTED | — | |
| PL1-05 | current/max inside the bars | PARTIALLY COMPLETED | staging | B8-019 labels; Food still a percentage |
| PL1-08 | Consumable effects shown everywhere | NOT STARTED | — | |
| PL2-003 | Dialogue text and readability | NOT STARTED | — | |
| PL2-001 | Forge occupancy and stale reservations | NOT STARTED | — | |
| PL2-004 | Animal loot and the path to leather | NOT STARTED | — | |
| PL2-006 / PL1-12 | Resources harvestable everywhere; red flowering plant | NOT STARTED | — | |
| PL1-06 | Every stone object minable, size-based yield | PARTIALLY COMPLETED | staging | B8-026 boulders |
| PL2-011 | No interactions through walls | NOT STARTED | — | |
| PL2-007 | Fields grow, ripen and regrow | NOT STARTED | — | Seasons from B8-029 |
| PL1-04 | Health recovery and Apothecary | NOT STARTED | — | |
| PL1-09 | Gold star over the accepted job's employer | NOT STARTED | — | |
| PL1-07 | NPCs sunk into beds and chairs | NOT STARTED | — | |
| PL2-013 | Usable furniture (sit, lie in bed, furnace, food table) | NOT STARTED | — | Shares poses with PL1-07 |
| PL1-13 | Recognisable stove | NOT STARTED | — | |
| PL2-010 | Recognisable sawhorse | NOT STARTED | — | |
| PL2-002 | Usable chests, locks and lockpicking | NOT STARTED | — | |
| PL2-005 | Longer skill trees and pacing | NOT STARTED | — | |
| PL2-008 / PL2-014 | Expandable property, modular house and workshops | NOT STARTED | — | One shared foundation |
| PL2-015 | Farming, livestock and hand ploughing | NOT STARTED | — | Builds on B8-029 and PL2-007 |
| PL1-10 | Player businesses and real NPC demand (staged) | NOT STARTED | — | Stage 1 first |
| PL1-11 | Google Drive cloud saves (staged) | NOT STARTED | — | Stage 1 (portability audit) is local; later stages need a Google OAuth client registered by the owner |
| ENV-RTK | RTK token tool and its hook | BLOCKED | — | Not installed in this container (`/root/.local/bin/rtk` absent); the environment's setup script must install it and run `rtk init -g --auto-patch` (owner action, environment settings) |

## Decisions in this run

- 2026-10-19: punch-list work is pushed to `staging/my-medieval-life` after its tests pass, as
  CLAUDE.md's standing authorisation allows; the master directive authorises normal Git operations and
  integration. `main` is untouched.
