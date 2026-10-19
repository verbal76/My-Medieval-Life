# Build 11 punch list 2 (PL2)

The owner's Build 11 playtest punch list ("Build_11_Punch_List_2.docx", received 2026-10-19), kept as
open items. The owner's IDs are kept in commits, PRs and verification notes. Owner's guidance: keep
save compatibility and working behaviour; fix reproducible bugs and interaction reliability before
large features; reuse shared systems; support controller, keyboard and mouse, and touch; confirm in
code before assuming a feature exists. Acceptance for every item: verified in a playable build,
including controller use and save/load.

Status: **Open** = not started. "Related" names work already done or under way that touches the item
(it is not a claim the item is fixed).

| ID | Item | Priority | Kind | Status | Related |
|---|---|---|---|---|---|
| PL2-001 | Forge occupancy wrongly blocks crafting ("Alice Stone is using the forge" with nobody there): audit reservations, release stale locks, accurate message | High | Bug | Open | B8-014 (choice between a person and a station) is merged; reservations are untouched |
| PL2-002 | Usable storage chests with ownership and access rules; lockable chests and lockpicking with tools, difficulty and consequences; theft, witnesses and reputation; decorative chests are not public storage | High | Feature | Done on branch pl-chests, not merged | B8-017 (personal chests moved beside their owners' homes) is in the village rebuild, not merged |
| PL2-003 | NPC dialogue text: malformed sentences (a theft rumour joined to an unrelated buyer line), names, possessives, grammar; panels wrap and fit, readable, clear controller focus | High | UI and content | Open | — |
| PL2-004 | Animal loot: hunted animals gave 0 meat, 0 leather, 0 coins, and drops stayed or could not be picked up; plausible products per animal, no coins from wild animals unless intended; a working path to leather (hides, tanning) | High | Bug | Open | B8 report saw hunting rabbits and boar work; B8-009 made loot lines per item; B8-029 adds animal ages (babies give half meat, no hide) |
| PL2-005 | Skill trees too short: longer tiers and unlocks for mining, woodcutting, smithing, crafting, cooking, combat, magic, trading, stealth; slower advancement; every perk shown is implemented; keep character saves | High | Balance | Open | — |
| PL2-006 | Outside the village trees can be cut but flowers cannot be picked and many rocks cannot be mined; same resource types interactable everywhere; decorative scenery must not look harvestable | High | Bug | Open | B8-026 (small grey boulders minable in the village and outside it) is merged; flowers outside the village are not |
| PL2-007 | Village fields look planted but never become harvestable wheat over several days; full cycle (planting to regrowth) on game time and seasons; farmers tend and harvest; visible change while the player is away | High | World simulation | Open | B8-029 (calendar with seasons) in progress |
| PL2-008 | Expandable property: start with a house or basic structure and add facilities to the same plot over time, without demolishing; materials, rent, footprint, access; shares a modular foundation with PL2-014 | High | Building design | Open | — |
| PL2-009 | In-game encyclopedia from Settings or the main menu: items, resources, tools, roles, animals, buildings, stations, recipes, skills, controls, systems; image, what, use, where to get, links; tutorials; searchable; generated from game data where possible | High | Help | Open | Journal resource pages exist (resources.json); no encyclopedia |
| PL2-010 | Sawhorse looks like racks or boards: a recognisable sawhorse (timber on angled trestles, with a saw or log), same style, scale, use cell and collision | Medium | Visual | Open | B8-028 (named Sawmill shed) is in the village rebuild |
| PL2-011 | Interactions through walls: from inside a building the player can target flowers and chop trees outside; block across walls and inside/outside boundaries by line of sight or room checks, both directions, all inputs | High | Bug | Open | B8-014 target list (merged) is where the check belongs |
| PL2-012 | Storage UI: quantity +/- (default 1, up to the stack), preview, Store All, same for taking out; controller focus scrolls with the list; after storing keep focus on the item, or the next one in its place, never back to the top | High | Inventory UI | Open | — |
| PL2-013 | Player housing: sit on chairs (seated pose, stand up), lie in bed while sleeping and wake beside it, furnace for cooking (smelting only if its design supports it), the food table as a preparation station distinct from cooking; all inputs; future houses too | High | Feature | Open | — |
| PL2-014 | Modular house and workshop expansion: connected additions (carpentry, smithy, kitchen, bakery, apothecary, storage, living quarters) with walls, doors, roofs, navigation and working stations; mixed use, optional standalone shops, no profession lock-in | High | Building system | Open | Shares a foundation with PL2-008 |
| PL2-015 | Farming and livestock: clear and till owned or leased land in any shape; craftable hand plough (slower, more stamina) before horses or oxen; wheat, vegetables, herbs, seed saving, weather and seasons; fences, pens, gates, coops, shelters; buy or trap animals, feed, water, breed, raise young; eggs, milk, wool, meat, hides to leatherwork, cooking and trade; markets, later hired help; optional, startable with no capital | High | Major feature | Open | B8-029 (animal life cycles, births) in progress; the economy's pens and fields exist |

Suggested order, following the owner's guidance (bugs and interaction reliability first): PL2-001, 004,
006, 007, 011, 003, 012; then PL2-002, 005, 010, 013; then the large shared building and farming work
(PL2-008 with 014, then 015) and PL2-009, which gains most once the systems it documents are settled.
This order is a proposal; nothing here has started.
