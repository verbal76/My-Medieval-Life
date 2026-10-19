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
| PL1-01 | Settings > Controls exit freezes the game | VERIFIED | staging | Back now returns to the screen that opened the window; wiki_test drives X/Esc/B from title and pause |
| PL1-02 | One tabbed Settings screen with Back | VERIFIED | staging | Audio, Display, Interface, Controls, Wiki; settings persist (test) |
| PL2-009 | In-game player wiki | VERIFIED | staging | Settings > Wiki: ~150 pages generated from items, recipes, resources, skills, professions, animals, stations, controls; guides, chains, search, links (wiki_test); pages looked at. Prose of hand-written pages partly checked against code. Each new feature adds pages |
| PL1-03 | Merchant buy/sell quantity control | VERIFIED | staging | Shared QuantityPicker; atomic; 17c/coal 2c -> 8 (start_test); screenshot looked at. Touch not run |
| PL2-012 | Storage quantity and controller navigation | VERIFIED | staging | Same picker, Store/Take all, focus kept and scrolled (start_test) |
| PL1-05 | current/max inside the bars | VERIFIED | staging | 9/100, 12/100, 32/100 with outline (screenshot); phone/Steam Deck not checked |
| PL1-08 | Consumable effects shown everywhere | VERIFIED | staging | From items.json fields; consumed only on success (start_test) |
| PL2-003 | Dialogue text and readability | VERIFIED | staging | Sentences closed and de-duplicated, possessives, no id leaks, wrapping choices (start_test over 60 villagers) |
| PL2-001 | Forge occupancy and stale reservations | VERIFIED | staging | Only a villager working at the station blocks it; never saved (world_test) |
| PL2-004 | Animal loot and the path to leather | PARTIALLY COMPLETED | staging | Piles show their item, can be tapped and taken, spoil after 3 days; hide -> tan_leather at the workbench. No feathers or pelts yet (need items and icons) |
| PL2-006 / PL1-12 | Resources harvestable everywhere; red flowering plant | VERIFIED | staging | Red plant is tile 2656, now a plant; every overworld flower pickable and saved (world_test, screenshots) |
| PL1-06 | Every stone object minable, size-based yield | VERIFIED | staging | Small (2 uses) and large (6 uses) boulders, overworld and village (world_test, screenshot) |
| PL2-011 | No interactions through walls | VERIFIED | staging | World.reaches guards targets, Use, Gather and attacks both ways (world_test) |
| PL2-007 | Fields grow, ripen and regrow | VERIFIED | staging | The cycle worked; farmers cut within the hour. They now wait 12 h, so ripe fields are seen (world_test, screenshots). Seasons hook in place |
| PL1-04 | Health recovery and Apothecary | VERIFIED | staging | Four medicines, two starting bandages, the sage as Apothecary with finite stock from brewing and caravans (health_jobs_test, screenshot). Bandages not craftable: no cloth in the game |
| PL1-09 | Gold star over the accepted job's employer | VERIFIED | staging | Keyed by NPC id, survives save/load, clears on payment (health_jobs_test, screenshot) |
| PL1-07 | NPCs sunk into beds and chairs | NOT STARTED | — | |
| PL2-013 | Usable furniture (sit, lie in bed, furnace, food table) | NOT STARTED | — | Shares poses with PL1-07 |
| PL1-13 | Recognisable stove | PARTIALLY COMPLETED | staging | Coal-bed hearth with pot, "Use Stove", "Stove — Cooking & Tonics"; no chimney (wall row above). The kitchen floor shows grass: a village-rebuild regression to fix |
| PL2-010 | Recognisable sawhorse | PARTIALLY COMPLETED | staging | Trestle bench with logs from Shade tiles; no angled-trestle or saw art exists in the packs |
| PL2-002 | Usable chests, locks and lockpicking | NOT STARTED | — | |
| PL2-005 | Longer skill trees and pacing | NOT STARTED | — | |
| PL2-008 / PL2-014 | Expandable property, modular house and workshops | NOT STARTED | — | One shared foundation |
| PL2-015 | Farming, livestock and hand ploughing | NOT STARTED | — | Builds on B8-029 and PL2-007 |
| PL1-10 | Player businesses and real NPC demand (staged) | NOT STARTED | — | Stage 1 first |
| PL1-11 | Google Drive cloud saves (staged) | NOT STARTED | — | Stage 1 (portability audit) is local; later stages need a Google OAuth client registered by the owner |
| ENV-RTK | RTK token tool and its hook | VERIFIED (this container only) | — | Built from the official repository (`cargo install --git https://github.com/rtk-ai/rtk --tag v1.0.1 --locked rtk --root /root/.local`), `rtk init -g --auto-patch` added the Bash PreToolUse hook to `~/.claude/settings.json` (no earlier settings file, no hooks replaced); `rtk gain` shows commands routed. Persistence needs the owner: the environment setup script must run the same install and `rtk init -g --auto-patch` |

## Decisions in this run

- 2026-10-19: punch-list work is pushed to `staging/my-medieval-life` after its tests pass, as
  CLAUDE.md's standing authorisation allows; the master directive authorises normal Git operations and
  integration. `main` is untouched.
