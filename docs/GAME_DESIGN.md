# My Medieval Life: game design

Status: **draft, waiting on owner answers.** Nothing here is approved unless it is listed under
Confirmed. The art packs show what the game *could* look like; they do not decide what it *is*.

How items move: Undecided → (owner answers) → Confirmed, or Proposed → (owner approves) → Confirmed.
Each change is recorded in `docs/DECISIONS.md`.

## Sources of evidence

| Source | What it tells us |
|---|---|
| Game title "My Medieval Life"; studio Hot Attic Games | The game's name and studio |
| GitHub repository description: "Mini RPG" | The owner's one-line description of the genre |
| Asset packs the owner bought or chose (`ASSET_MANIFEST.md`) | Available art: 16x16 top-down overworld, villages, dungeons, 8-direction characters, RPG item icons, skill FX, Miniworld RTS-style units and buildings, Philippine-mythology monsters |
| Owner instructions in this project so far | Asset preparation, deterministic generation, no invented gameplay, owner approval for engine, platform and mechanics |
| The owner's other project "Climb up" (`ClimbUp_restore_backup.zip`) | Precedent only, **not a requirement here**: Android, landscape, touch with floating stick, libGDX, fully offline, personal sideload, GitHub Actions CI, CC0-first asset policy, semver, package id `com.hotatticgames.<name>`, owner experience "beginner", usage style "conservative" |

## Confirmed

1. **Title:** My Medieval Life. **Studio:** Hot Attic Games.
2. **Genre:** described by the owner as a "Mini RPG" (repository description). Scope and subgenre are
   undecided.
3. **Art direction:** 16x16 pixel art from the packs in this repository, mainly Shade's Puny and
   Miniworld families. Which family is the main look is undecided (U13).
4. **Medieval setting.**
5. **Procedural worlds must be deterministic:** the same seed always gives the same world. This is
   established by the owner's asset-preparation instructions.
6. **Workflow rules:** the owner approves the engine, the primary platform and every gameplay
   mechanic before implementation. Design must not be invented from the art packs.
7. **World foundation:** William Morris's *The Well at the World's End*. Its story is the world's
   history, not the player's quest. The research is in `docs/world/`.
8. **The player is not the chosen one.** They begin as an ordinary inhabitant of an original village
   in an original county, free to stay home or travel. It is an open-world life simulation with
   RPG mechanics (answers U3 in outline; the core loop U4 is still open).
9. **Magic is a learnable discipline** that keeps knowledge, proficiency and capacity separate. Its
   scientific framing is GAME EXPANSION. Details are open (`docs/world/J_OPEN_DECISIONS.md`
   J-M1 to J-M4).
10. **Multiplayer:** player-hosted worlds for about 3–4 players; no always-on server (answers U9).
11. **Visual direction:** 2D/2.5D isometric with 8-direction animated sprites (supersedes P2).
12. **Living economy:** an interdependent production economy in which goods and money really move.
    NPCs are persistent people with occupations, inventories and finances, and robbing or killing
    them has lasting consequences. Players may follow productive or criminal paths. The design
    reference is `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` (its §2 "established intent"), and its
    fit with the repository is reviewed in `docs/LIVING_WORLD_ALIGNMENT.md`.

## Proposed (agent recommendations, not approved)

| # | Proposal | Why |
|---|---|---|
| P1 | First playable is a small vertical slice: one generated map, one controllable character with 4- or 8-direction animation, camera follow, collision, a few buildings, a fixed seed, basic save/load | Proves the technical foundation without committing to mechanics (see `docs/DEVELOPMENT_PLAN.md`) |
| P2 | ~~Top-down orthogonal view~~ **Superseded** by the owner's isometric direction (Confirmed 11) | Every terrain and building asset is drawn top-down orthogonal; the Puny packs also ship isometric and hex demos, but only as samples |
| P3 | Overworld built by the existing Puny World generator (terrain, rivers, roads, bridges, settlement sites) | Already working, tested and deterministic |
| P4 | Player character drawn with the Puny Characters sprite system (8 directions; customisable by layered parts and palettes) | It is the only pack that supports character variety and matches the Puny World tileset |
| P5 | Save = world seed + generator version + player state + changes to the world | Small saves, and deterministic regeneration makes it possible |
| P6 | ~~Fully offline, single player~~ **Superseded** by player-hosted multiplayer (Confirmed 10) | Matches the owner's other project; avoids server cost. **Needs confirmation (U9)** |

## Undecided: owner input needed

### Essential questions (in order of architectural impact)

1. **U1. Primary platform and input.** Android touch first (like Climb up)? Desktop keyboard and
   mouse first? Both from day one? *This changes UI, controls, performance budgets and the build
   pipeline.*
2. **U2. Engine.** Approve the recommendation in `docs/ARCHITECTURE.md` (Godot 4) or pick another.
3. **U3. What is the player?** A single hero you control directly (Zelda / Stardew style)? A
   settlement or faction you command (RTS / colony style, which the Miniworld units and buildings
   suggest)? Or both (a life sim where you are one person in a village)? "My Medieval *Life*" could
   mean any of these. *This decides camera, controls, entity model and UI.*
4. **U4. Core loop.** What does the player do minute to minute, and what is the goal? For example:
   explore and fight; farm, build and trade; manage a village; live a life from childhood to death.
5. **U5. World structure.** One generated world per save, a handmade world, or a mix (generated
   overworld with handmade towns or dungeons)? One continuous map, or separate areas (overworld,
   town, interior, dungeon)? What size?
6. **U6. Save behaviour.** Autosave, manual save slots, or both? Is death or failure permanent?
7. **U7. Combat.** Is there combat? Real-time or turn-based? (The Myth Creatures pack includes
   RPG Maker-style turn-based battle sprites.)
8. **U8. Building and construction.** Can the player place buildings? Freely, on a grid, or only in
   set spots?
9. **U9. Multiplayer.** Required, possible later, or never?

### Other open design areas

| # | Area | Known | Open |
|---|---|---|---|
| U10 | Crafting and gathering | Survival, jewelry and armour icon packs exist | Whether crafting or gathering exist at all |
| U11 | NPCs and settlements | The generator places settlement sites; Miniworld has workers and buildings | Whether there are NPCs, villages, quests or dialogue |
| U12 | Progression | Puny Skills pack (skill icons and FX) exists | Levels, skills, stats, equipment, or none |
| U13 | Art mix | Puny (8-direction, more detailed) and Miniworld (4-direction, simpler) styles differ | Which family is primary; whether to mix them |
| U14 | Economy and trading | Item icon packs exist | Currency, shops, trading |
| U15 | Survival systems | Survival icon pack exists | Hunger, health, day/night, seasons |
| U16 | Story and setting | Medieval; Myth Creatures pack is Philippine folklore | Tone, story, lore, whether myth creatures belong |
| U17 | Audio | No audio assets in the repo | Music and sound sources |
| U18 | Monetisation and distribution | Climb up precedent: personal sideload | Free, paid, store, sideload |
| U19 | Accessibility and settings | Climb up precedent had a full settings list | Requirements for this game |
| U20 | Living-economy decisions | `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` §2 proposals and §17 questions | Aging and generations, currency conservation, simulation frequency, price model, law, recipe learning, scale, and the first slice (iron miner→smith as written, or the canon-grounded wool variant: `docs/LIVING_WORLD_ALIGNMENT.md` §4) |
| U21 | Content rating and crime depiction | The living-world document allows theft, robbery and murder "where appropriate to the game's rating"; the novel features thralldom (J-S1) | Target rating; how violence, crime and thralldom are shown |

## Not assumed

The following are **not** design requirements, even though assets for them exist: crafting,
jewelry, armour equipment, skills, monsters, RTS units, ships, dungeons, the character customiser,
survival meters. They stay available until the owner chooses.
