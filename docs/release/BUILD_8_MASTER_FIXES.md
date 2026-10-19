# Build 8 master fix list: status

The owner's "Build 8 master fix and improvement prompt" (2026-10-19). Its IDs differ from the earlier
register `BUILD_8_ISSUES.md` (there, for example, B8-010 is child pickpocketing); this file uses the
master prompt's IDs. Owner decisions for it (2026-10-19): one new fixed village; older test saves are
disposable (refused and kept, never overwritten); a dead essential worker is replaced by an apprentice,
else a newcomer; sprint on LT (not L3).

Status: FIXED (implemented and verified by tests and, for visual items, screenshots looked at),
PARTIAL, BLOCKED, UNVERIFIED, ALREADY RESOLVED. Nothing here was checked on a phone or with a real
controller. Branch `staging/my-medieval-life`.

| ID | Item | Status | Root cause and fix |
|---|---|---|---|
| B8-001 | (earlier fix) | ALREADY RESOLVED | — |
| B8-002 | Village pasted over terrain | FIXED | The village was Shade's sample maps pasted as districts. `tools/build_village.py` now lays out one coherent village on continuous wang terrain from the purchased building art; edges meet the overworld without seams (`de5ca4d`) |
| B8-003 | Floating or partial trees | FIXED | Old tree tiles from the sample maps remained in tile layers. Trees are only Living Forest records now; tests check no tree tile is left in any village or overworld layer |
| B8-004 | Broken mining area | PARTIAL | One track from the adit to a cart stop, every seam reachable (tested). Left: the mine hill is a plain flat plateau, and a few trees stand on its rim |
| B8-005 | Tree collision and transparency | FIXED | No fault found; checks added: trunk-only collision, canopy fade, harvestable while faded, one sprite per tree across chunks |
| B8-006 | Harvest animation never stops | FIXED | The work animation was only ever replaced by walking; a Use is now one cycle ending in idle |
| B8-007 | Wrong tool shown | PARTIAL | The "work" animation was the staff swing. The player now swings with the real tool's icon in hand (no tool-swing art exists in the character sheets); villagers' work still shows the staff |
| B8-008 | Deposits misidentified | FIXED | Ore-flecked rocks with no seam behind them; the resource now comes from each deposit's tile (`resources.json` deposit_tiles) |
| B8-009 | Collection notices need icons | FIXED | Corner line "[icon] +1 Iron ore" for mining, logs, saplings, picking, wheat and loot |
| B8-010 | Inventory blocked during harvesting | FIXED | Opening any window stops the action with nothing awarded |
| B8-011 | No cancel | FIXED | B, Esc, right-click or a tap cancel at once, nothing awarded |
| B8-012 | Oversized inventory highlights | FIXED | The tab row's focus ring covered the whole touch area and theme margins grew the slots; both fit their slots |
| B8-013 | Oversized action prompts | FIXED | The prompt and messages size to their text; the prompt sits above the touch buttons |
| B8-014 | NPC blocks a workstation | FIXED | Every usable thing in reach is offered (Q / Tab, D-pad); a theft is never the default |
| B8-015 | Weapon racks | FIXED | Decorative: solid, drawn under the player, nothing to take (BUILD_DECISIONS.md) |
| B8-016 | Essential trade succession | FIXED | Posts left by a death go to an adult without a trade after 3 days, else a newcomer within 10 days. "Grown child" becomes real with B8-029 aging |
| B8-017 | Personal chests in public rows | FIXED | Each household's chests stand in its own door yard |
| B8-018 | Roof flicker indoors | FIXED | A map redraw put the roof back at full opacity before it lifted again; it now resumes where it was |
| B8-019 | Unclear HUD | FIXED | Labels with values, a bread icon for food (the old icon was a cannon), red blinking below 25% |
| B8-020 | Death cause | FIXED | Starvation, spoiled food and attacks ("Killed by Wat the guard.") are recorded, saved and shown. The game has no bleeding or environmental damage to report |
| B8-025 | Player clipped behind tabletops | FIXED | Overlay tiles of solid cells were drawn above everyone; they are y-sorted with the characters (checked from all four sides) |
| B8-026 | Grey boulders not minable | FIXED | Small boulders give stone (3 uses), village and overworld, kept across chunk reloads and saves |
| B8-027 | Sprint | FIXED | LT toggles, Shift holds (or toggles), 1.5x speed, uses stamina. No touch sprint control exists |
| B8-028 | Sawmill | FIXED | The saw-planks recipe existed at an unlabelled sawhorse; a named Sawmill now holds it |
| B8-029 | Calendar, aging, animal life cycles | In progress | Separate branch `b8-aging`; owner-approved 8-day year |

Needs manual playtesting: the village and mine as a whole (walk every road and building), all tool
swings from east and west, controller use of the choice prompt (D-pad) and sprint (LT), the Pack and
cancel during work, succession over several game days, roofs in every building, and the HUD and prompts
on a phone and on Steam Deck.

Artwork wanted: pickaxe, axe and hammer swing animations for the player and villagers; elderly and
child character sheets (B8-029); a baby boar.
