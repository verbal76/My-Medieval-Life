# Underground architecture: caves, tunnels and open pits (Build 17 planning, read-only)

Prepared 2026-10-21 under the owner's directive `docs/directives/2026-10-21_build17_architecture_mining_contracts_decisions.md`
(section 3, Owner Decision 1; section 10). Planning only: no game code or data was changed. Code references are to
staging `6607000` (the planning branch `wip/build17-plan` adds documents only).

**Labels used on every statement**

| Label | Meaning |
|---|---|
| VERIFIED | VERIFIED CURRENT BEHAVIOUR: read in the code named beside it |
| APPROVED | EXISTING APPROVED DESIGN: an owner directive, register entry or approved spec |
| HISTORICAL | HISTORICAL PROPOSAL: an earlier agent proposal, never approved |
| RECOMMENDATION | ENGINEERING RECOMMENDATION: this document's advice, not a decision |
| OPEN | OPEN OWNER DECISION: only the owner can settle it |

## 1. Summary for the owner

- **APPROVED** (directive section 3): genuine, enterable caves, tunnels, chambers and open pits that NPCs can use, with
  mining, depletion, transport, save and load, and overhead rock that gets out of the way like a house roof.
- **VERIFIED**: the game today is one flat sheet of squares. Walls, paths and collision know only "this square is
  blocked or not", with no idea of height or of one place lying under another (section 2).
- **RECOMMENDATION**: build **Option B with Option C's coordinates**. Each underground level is its own small map
  (its own walls, its own path-finder, its own tiles), laid exactly under the ground it lies beneath and joined to
  it by real entrances: the adit, ramps, ladders and, later, shafts. The surface map stays exactly as it is. Open pits
  stay on the surface map, as excavated ground with stepped sides (they have nothing overhead).
  - This gives the player everything the layered world (Option C) promises: walk in, the hill "lifts away", mine,
    haul ore out, dig shafts later.
  - It costs a fraction of a full layered rewrite, because none of the surface's roughly 23 collision and
    path-finding uses, or its ~124 distance checks, needs a height added.
- **Why not full Option C:** its extra abilities (seeing several levels at once, things falling between levels,
  digging down anywhere) are not in the approved requirements. It would touch every movement, collision, drawing
  and save path in the game.
- **Why not Option A alone:** it is cheapest and fine for open pits, but it cannot put a tunnel under anything you can
  walk on. That blocks shafts, multi-level mines and the later industrial stage the owner approved.
- **Still yours to choose** (section 7): the architecture itself, what the surface looks like while you are
  underground, how dark caves are and whether light is a gameplay need, where the first caves go, and which build
  carries underground mining (MIN-F) if Build 17 cannot carry all of it.

## 2. How the world works today (the evidence)

| Topic | What the code does | Label |
|---|---|---|
| Map | `VillageMap` holds one `solid` byte per cell of the 120 x 90 village (`village_map.gd` lines 7-10, `load_default`) and one `AStarGrid2D` (`_setup_astar`). `is_solid`, `set_solid` and `find_path` take a cell (x, y) and nothing else | VERIFIED |
| Villagers stay in the village | `VillageMap::find_path` clamps both ends to the village grid ("villagers never leave it"), and `is_solid` calls everything outside the village a wall (`village_map.gd::is_solid`). The interaction manifest says so too (`docs/SYSTEM_INTERACTION_MANIFEST.md` line 655) | VERIFIED |
| Overworld | The land round the village is endless and generated from the seed in 32 x 32 chunks (`overworld.gd`, `GEN_VERSION 1`, `CHUNK 32`, `MAX_CACHED 160`). It shares the village's coordinates, so **there is no scene change or loading screen when you walk out**: `VillageMap::is_solid_world` asks the village inside and the overworld outside. Only the player uses it (`main.gd::_blocked_corners`, `_try_move`) | VERIFIED |
| Player movement | Moves by small steps and checks four foot corners against `is_solid_world` (`main.gd::_blocked_corners`, `_try_move`). Tap-to-walk uses `VillageMap::find_path_world`, which builds a temporary A* grid of up to 140 x 140 cells for each route outside the village | VERIFIED |
| NPC movement | A plan is a list of steps such as `{k: "go", to: Vector2i}` and `{k: "work", ... x, y}` (`npc_brain.gd::_miner` builds `[go(beside(at)), work(... "mine", {x, y})]`). `World::_walk` asks `map.find_path(n.cell(), to)` once per step. Every position is a 2D `Vector2` with no level (`npc.gd` `pos`, `NPC::to_dict` "pos") | VERIFIED |
| Other users of the flat map | Collision or path calls in 9 core files: `business.gd` 1, `construction.gd` 3, `farming.gd` 1, `fauna.gd` 2, `fitting.gd` 3, `manor_work.gd` 1, `npc_brain.gd` 6, `property.gd` 1, `world.gd` 4. There are about 124 `distance_to` comparisons in `main.gd`, `game_ui.gd` and 12 core files (reach, witnesses, targets) | VERIFIED |
| Drawing | `MapView` draws the village's tile layers: "ground", "path" and "below" under the characters, "above" over them (`map_view.gd::build`). The tiles are 16 x 16 squares; no isometric tile layout is set. Characters share one y-sorted node, `actors` (`main.gd::_build_scene`) | VERIFIED |
| Roof fade | `RoofFade` lifts one building's roof. It moves that building's roof cells (listed per building in `village.json` interiors) from the roof layers to stand-in layers and fades their alpha: fully clear inside, half clear behind the eaves, with holds against flicker (`roof_fade.gd::probe`, `follow`, `_lift`). Which building you are in comes from cell lookups (`World::place_of`, `roof_over`) | VERIFIED |
| Canopy fade | `CanopyFade` does the same for tree tops over the player, looking only at the cells the player covers (`canopy_fade.gd::update`) | VERIFIED |
| Lighting | There is no lighting or darkness system: no `Light2D` or `CanvasModulate` anywhere in `game/scripts`. The renderer is `gl_compatibility` on desktop and mobile (`game/project.godot` lines 29-30) | VERIFIED |
| The mine | `tools/build_village.py::mine` makes a rocky hill (solid cliff plateau) with a timbered adit drawn at (48, 9), a yard, a rail and cart that are decoration only, and the 15 seams (`place_deposits`). `village.json` "mine" holds `entrance [48, 10]` and `yard [51, 21]` | VERIFIED |
| Saves | `World::to_dict` stores positions as [x, y] and the deposits whole. `SAVE_VERSION` is 15 (`world.gd` line 2875); `SaveStore.MIN_VERSION` is 14. The overworld saves only its seed and changes (`overworld.gd::to_dict`), and **drops every saved change if `GEN_VERSION` differs** (`overworld.gd::load_dict`) | VERIFIED |
| Path cost | Measured: 18,784 villager path searches in a 10-day run, 28 microseconds each on average, 1.2 % of simulation time (`docs/release/SIMULATION_PERFORMANCE.md` line 135) | VERIFIED |
| Hidden spaces | Wildlife refuges are counts, not places; young "travel unseen" between woods (`refuges.gd` header). The mining spec warns that refuges do not establish cave support (`My_Medieval_Life_Mining_Industry_Expansion.txt` section 7) | VERIFIED / APPROVED |
| Visual direction | `docs/GAME_DESIGN.md` Confirmed 11 says "2D/2.5D isometric"; the game as built draws top-down 16 px squares. The directive asks caves to match "the established ... perspective", which in the shipped game is that top-down square grid | VERIFIED |

## 3. The three options, in plain words

- **Option A: one flat layer, visual excavation.**
  - Caves are tunnels cut into solid hills on the existing map, with the hill's top drawn over them as a "roof"
    that fades when you walk in, as a house roof does.
  - Pits are ground dug down in steps on the same map; the depth is a number per cell that changes the picture and
    what you find there.
- **Option B: separate underground maps joined by entrances.**
  - Each cave or mine is its own map with its own walls and paths.
  - Walking into the adit moves you onto that map. The view shows it instead of the surface, the way a roof
    vanishes when you go indoors.
- **Option C: several logical height layers of one world.**
  - The world has levels stacked in the same coordinates: surface, level -1, level -2.
  - Every collision check, path, drawing and saved position carries its level, and levels connect wherever a ramp,
    ladder or hole links them.

**RECOMMENDATION**, the hybrid compared below as "B+":

- Option B's separate maps, each placed **in the surface's coordinates directly beneath the ground it lies under**,
  with a level number.
- Open pits done Option A's way on the surface.
- This is the smallest form of Option C: a cell (x, y) on level -1 really is under (x, y) on the surface. Shafts,
  stacked galleries and geology that lines up with the surface stay possible later, but the surface map is never
  rewritten.

## 4. Comparison on the owner's 12 criteria

| # | Criterion | A: one flat layer | B: separate maps | C: full layered world | B+ (recommended) |
|---|---|---|---|---|---|
| 1 | Godot feasibility | Easy. Uses `set_solid` and tile changes that already run (`World::mine_unit` already changes tiles in play) | Easy. Godot handles several `TileMapLayer` sets and several `AStarGrid2D` grids; only the visible set is drawn | Feasible but heavy. One y-sorted actor node would need per-level drawing order and per-level hiding of every sprite | As B |
| 2 | Movement and collision dependencies | **None changed**: the same `VillageMap.solid` and `AStarGrid2D` | The ~23 surface calls stay. Only code that runs underground uses the level's map. The player's `_try_move` must ask the map of the level they are on | **Every** call needs a level: the 23 collision/path calls, `is_solid_world`, `_blocked_corners`, `find_path_world`, building placement (`fitting.gd`, `property.gd`), fauna | As B; `is_solid_world` gains one branch: "on a level other than the surface, ask that level" |
| 3 | NPC pathfinding and scheduling | Unchanged: tunnel cells are ordinary cells of the village grid. But a cave can only be where nothing walkable lies above it: inside the mine hill (about 21 x 7 cells, rows 3-9, `build_village.py::mine_hill`) or cliffs | NPCs must leave the surface grid for the first time. A plan step needs a level; a trip between levels is "walk to the entrance, change level, walk on" (`World::_walk`, `NPCBrain` `go`/`beside`). Every rule that compares two positions (124 `distance_to` uses) must not see across levels: witnesses, reach, targets, bubbles, fauna aggression | As B, plus 3D-aware routing everywhere | As B. The level router is the main new code. Distance rules get one guard, "same level", in `World` helpers rather than at each call (RECOMMENDATION: add `World.same_level(a, b)` and use it where the rule can meet an underground actor) |
| 4 | Rendering and roof transparency | **`RoofFade` reused almost as is**: a cave registered like a building interior, with its "roof" cells (the hill top over the tunnel) in a roof layer, lifts to alpha 0 inside (`RoofFade::probe` needs `World.interiors[id].roof` and `place_of`). The hill top is drawn today in a ground layer (`build_village.py::rock_top`, "ground1"), so its cells over a tunnel would move to a roof layer | The surface's layers fade or hide while you are below (the same alpha fade `RoofFade::update` uses, applied to whole layers); the level's own layers show. Simpler than per-cell roof lifting | Draw all levels with the upper ones faded: costly overdraw on phones, and most art would need a partly transparent variant | As B. The fade timing and flicker holds from `RoofFade` (`ENTER_HOLD`, `LEAVE_HOLD`) are reused for the entrance cells |
| 5 | Surface-underground transitions | None needed: you walk under the overlay | An entrance cell moves the actor to the other level. **No scene change**: one scene with a set of layers per level, as the overworld already shares the scene (`main.gd::_build_scene`, `ow_view`) | Ramps and holes anywhere | As B |
| 6 | Save compatibility | Carved tunnels and pit depths are changes to save (like `overworld.rock_changes`). If tunnels are cut by changing `village.json`, that is a village generator version bump (CLAUDE.md section 6); saves store changes, not terrain, so it needs the save handling of section 7 | New "level" on saved positions (NPC, player, animal, loot, cart). Missing means surface, so an older save loads unchanged. Plus the levels' dug cells and their deposits. One `SAVE_VERSION` bump | Same fields as B, plus every saved cell reference needs a level | As B. **Risk:** deposits are found and merged by (x, y) only (`World::deposit_at`, and the load merge in `World::load_dict` lines 3281-3283). Underground seams need (level, x, y) |
| 7 | Performance (Android, Windows, Linux, Steam Deck) | No change | One extra `AStarGrid2D` per level (a 120 x 90 level is 10,800 points, the size of the village's grid today, estimated well under 1 MB). Paths stay short (28 microseconds each today). Only the current level's layers are visible. Steam Deck runs the Linux build | Every level's layers drawn at once, and per-level sorting: the most draw cost on a phone | As B. Darkness as one full-screen overlay with a soft hole round the player costs about one textured draw; many `PointLight2D` lights cost more in the compatibility renderer (estimate, to be profiled on a phone) |
| 8 | Map-generation dependencies | Caves need room inside hills. The fixed village (generator v6, `tools/build_village.py`) has one small hill; more room means changing the fixed village (a generator bump) | Levels come from their own data or a seeded generator with **its own version**, so `village.json` and the overworld (`GEN_VERSION 1`) are untouched except the entrance. The adit already exists at (48, 9) | Generators for every level, aligned to the surface | As B. RECOMMENDATION: keep underground generation out of `overworld.gd` chunks, because a `GEN_VERSION` bump discards every saved overworld change (`overworld.gd::load_dict`) |
| 9 | Open pits | **Good fit**: nothing is overhead. Per-cell depth (drawn as terraces), solid steps except the ramp cells, deposits exposed at a depth. NPC paths unchanged. Needs terrace and ramp art (Forgotten Memories, "planned" in the asset registry) and B14-07 cliff steps | Awkward: a pit is open to the sky, so a separate map is the wrong tool | Natural but expensive: the pit cells remove surface cells over level -1 | Pits the A way. A pit floor may later hold an entrance down to a level |
| 10 | Minecarts, tunnels, shafts, industry | Tunnels only inside hills; **no shafts, no levels**; rails on one plane | Tunnels anywhere in a level; shafts are entrances between levels; tracks and carts per level (`Carts` records gain a level) | Everything, including vertical effects | As B, and because levels line up with the surface, a shaft dug at (x, y) can open (x, y) below |
| 11 | Implementation complexity (estimate, relative) | 1 | 3 to 4 | 8 to 10 | 3.5 to 4.5 (B plus the pit work of A) |
| 12 | Migration and regression risk | Low. Watch DVW-A10 (no unreachable "black-hole" cells) | Medium, concentrated in the new level router and the "same level" guard. Surface behaviour cannot change if the surface map is left alone | High: every movement, collision, drawing and save path is touched | Medium, as B |

## 5. What the player sees under B+

| Moment | What happens | Label |
|---|---|---|
| Walking into the adit | The surface's layers and surface characters fade out over about a quarter second, the way a roof lifts. The tunnel, its walls, its ore and anyone working there fade in. The camera does not jump: the tunnel lies under the hill you walked into | RECOMMENDATION |
| Inside | Irregular passages and chambers drawn from cave tiles (the Puny Dungeon pack is CC0 and "planned" in `docs/assets/packs.json`). Ore-flecked rock is the **same seam sprite** as on the surface (`resources.json` `deposit_tiles`) | RECOMMENDATION / APPROVED (directive section 4) |
| Darkness | A dark overlay with a lit circle round the player, darker away from lamps. It never hides the player or the path | RECOMMENDATION; how dark, and whether light is a requirement, is OPEN |
| NPC miners | They walk into the adit and work the underground seams by the same swing rule (`World::work_mine`, PAR-01). They carry ore out to the same buyers | RECOMMENDATION |
| Open pit | A stepped hole on the surface with a ramp spiralling down; the sky stays. Dirt, topsoil and stone come out as real items | APPROVED (MIN-E); method is RECOMMENDATION |

## 6. Work it needs, in order (no work is authorized by this document)

1. **Level foundation.** A `level` on every positioned actor and record (default surface), saved. A per-level map
   object (solid cells, `AStarGrid2D` over its own region) reusing `VillageMap`'s path code. Entrance records
   joining two cells on two levels. `World` helpers so rules that compare positions see one level.
2. **Router.** `World::_walk` uses the actor's level. NPC plans expand a cross-level trip into "to the entrance,
   through it, on".
3. **Drawing.** One `MapView`-like layer set per level. A level fade reusing `RoofFade`'s timing. Per-level
   visibility for character sprites in `main.gd`. The darkness overlay.
4. **Deposits underground**, by the common deposit rules (see `DEPOSIT_SUSTAINABILITY.md`).
5. **Open pits** on the surface: per-cell depth, terraces, ramps, spoil items (MIN-E).
6. **Later:** shafts, supports, rails and carts per level (MIN-F, then the industrial stage).

Tests to add with it:
- Levels: a level's path never leaves the level; an entrance is the only way between levels; a save made below
  ground loads below ground; an older save loads everyone on the surface.
- Rules across levels: no witness, reach or target across levels.
- Simulation: determinism of underground generation per seed; a 100-day multi-seed run with conservation including
  underground seams.

## 7. What remains the owner's choice

1. **OPEN: the architecture.**
   - Options: approve B+ as recommended; or full Option C; or Option A only (accepting no shafts or multi-level
     mines).
   - Evidence for B over full C: the same player-facing result for every approved feature, at roughly 40 % of the
     cost and without touching the surface's collision and paths.
2. **OPEN: presentation below ground.**
   - Options: the surface fully hidden (recommended, like a lifted roof), or a faint outline of the surface
     above.
3. **OPEN: darkness.**
   - Options: atmosphere only (recommended for the first version), or light as a real need (torches or lamps
     consumed, a new mechanic).
4. **OPEN: where the first underground goes.**
   - Options: under the village's mine hill through the existing adit (recommended), or caves in the overworld
     mountains as well.
   - The overworld option is the first time villagers would walk outside the village. It is a separate,
     larger step.
5. **OPEN: scheduling.**
   - MIN-E (pits) and MIN-F (underground) are register entries for Build 17. The roadmap already allows them to
     move to Build 20 or later if the terrain cannot carry depth (`docs/EXPANSION_ROADMAP.md`).
   - With B+ the terrain *can* carry it, so the real question is capacity. Recommended:
     - Build 17 carries the level foundation, the adit's first gallery with underground seams, and open pits.
     - Supports, rails, minecarts and the industrial stage wait for a later build named by the owner.
   - This is a scheduling decision, not a deferral by default: the dependency is on the level foundation and on
     cart and track recipes.
