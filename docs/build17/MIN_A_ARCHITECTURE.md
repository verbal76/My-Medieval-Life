# MIN-A: underground and mining architecture (Build 17 decision record and design)

Register: MIN-A (audit, architecture, acceptance tests), MIN-H (enterable caves), with MIN-B..G, SET-A, EXP-A.
Prepared 2026-10-21 on `wip/b17-mining` (base `wip/build17` `eaf5bd3`). Builds on `UNDERGROUND_ARCHITECTURE.md` (the
comparison) and `DEPOSIT_SUSTAINABILITY.md` (the deposit audit); this document does not repeat their evidence.

Labels: **APPROVED** (owner decision or approved spec), **VERIFIED** (read in the code named), **DESIGN** (this
document's engineering design under the approved architecture; minor details decided under the standing release
directive, `docs/directives/2026-10-21_standing_continuous_release_directive.md`), **OPEN** (needs the owner).

## 1. The decision

**APPROVED.** Owner, 2026-10-21 (`docs/directives/2026-10-21_build17_start_underground_contracts.md`, register OD-29):

> For underground architecture, proceed with the recommended separate underground maps associated with their surface
> locations, with open-pit mining remaining on the surface. Document this as the approved architecture and design it
> for future expansion.

The recommendation it approves is "B+" of `UNDERGROUND_ARCHITECTURE.md` section 3:

- Each underground level is its own small map: its own collision, its own path-finder, its own tiles.
- It is laid in the surface's coordinates, directly under the ground it belongs to: cell (x, y) on level -1 lies
  under cell (x, y) of the surface.
- Levels are joined to the surface and to each other only by real entrances (portals): the existing adit first;
  ramps, ladders and shafts later.
- The surface map (`VillageMap`, the overworld) is not rewritten. Its collision, path-finding and movement code stay
  as they are; underground code is added beside them.
- Open pits stay on the surface map (nothing is overhead).

Approved with it (directive 2026-10-21 sections 3 and 4, and the owner's choices recorded in OD-29):

- Caves look natural: irregular passages, chambers, uneven walls; not rectangular rooms.
- Overhead rock gets out of the way as a house roof does (`RoofFade`'s principle and timing); the player always stays
  visible.
- Darkness is atmosphere only (it never hides the player or the path) unless a later owner decision makes light a need.
- Underground deposits are the same seam records and rules as the surface, plus a level.

## 2. Data model

### 2.1 Levels

| Item | Design | Label |
|---|---|---|
| Level number | An integer depth: `0` the surface, `-1` the first level below, `-2` the next. A level is a depth, not a map | DESIGN |
| Level map | `LevelMap` (`game/scripts/core/level_map.gd`): `id` (stable string, e.g. `"adit_gallery"`), `level` (depth), `region` (a `Rect2i` in surface coordinates), `solid` (one byte per cell of the region), `floor` (the generated floor cells), its own `AStarGrid2D` over the region | DESIGN |
| Coordinates | The surface's own. A level map stores no offset: its cell (x, y) is the surface's (x, y). Outside its region a level map is solid rock | DESIGN |
| Uniqueness | Two maps of the same level never overlap (the registry refuses it). So `(level, x, y)` names exactly one cell of the whole world, and deposits, dug cells and future tracks are keyed by it | DESIGN |
| Registry | `Underground` (`game/scripts/core/underground.gd`): every level map (sorted by id), every portal, `map_at(level, cell)`, `is_solid(level, cell)`, `find_path(level, from, to)`, `portal_from(level, cell, dir)`. Held by `World.underground`; created from the world's seed by `Underground.create(seed, map)` in `World.setup` and again in `World.load_dict` (it is generated, never stored) | DESIGN |
| Generator | A level map is generated from the world seed by integer hashing (`Overworld.hash32`) with salts of its own. It never draws from `world.rng` (no other stream shifts) and never touches the overworld's chunks (a `GEN_VERSION` bump there drops every saved overworld change, `overworld.gd::load_dict`). `Underground.GEN_VERSION` versions it; the generation inputs are the seed and the village's static layout (`village.json` "solid", "mine"), never runtime state | DESIGN |
| Data | `game/data/underground.json` (`mml-underground/1`): per gallery its id, level, the surface place it lies under, the seams it holds (ore and count), the tiles it is drawn with, and its generation sizes | DESIGN |

### 2.2 The first level: the adit gallery

| Item | Design | Label |
|---|---|---|
| Place | Under the mine hill (`tools/build_village.py::mine_hill`, rows 2-9, x 38-59), entered by the existing adit at (48, 9) | APPROVED (OD-29: "starting with the existing adit") |
| Floor rule | Floor only where the hill's static rock (surface cells solid in `village.json`) lies over the cell and all eight of its neighbours (the entrance passage excepted), so at least one cell of rock separates any surface walker from the gallery's floor. This keeps every surface rule (building placement, sapling refusals, villager paths) unaffected, and keeps surface people out of reach of the player below, until the same-level guards of section 4 exist everywhere | DESIGN |
| Shape | Winding passages carved by seeded "worms" from the entrance, one to three chambers (irregular blobs), smoothed by a cellular-automaton pass, then every floor cell not reachable from the entrance filled back with rock (no black-hole cells, DVW-A10) | DESIGN |
| Seams | Placed on rock cells beside the floor (cave walls), never beside the entrance. Each is an ordinary `World.deposits` record with `"level": -1` (section 6). Kinds and counts come from `underground.json`; each seam's amount is the village map's own per-seam amount for that ore (`village.json` "deposits": iron ore 60, coal 50, stone 80, copper ore 30), so no new quantity formula is introduced | DESIGN (the counts are an agent decision; the owner may change them in data) |

### 2.3 Portals (entrances)

A portal joins two ends. Each end is `{level, stand, door}`: `stand` is the walkable cell the actor stands on and
`door` the neighbouring cell it walks into (solid on that end's own map). The adit:

| End | Level | Stand | Door |
|---|---|---|---|
| Surface | 0 | (48, 10), the cell in front of the adit (`village.json` "mine" "entrance") | (48, 9), the adit drawn on the rock face |
| Gallery | -1 | (48, 9), the inner mouth, under the adit | (48, 10), the daylight mouth (rock on level -1) |

- **Rule (DESIGN):** an actor on a portal's `stand` moving toward its `door` (a step whose direction points at the door
  cell) crosses. It arrives at the centre of the other end's `stand`. Because each end's door is the other's stand,
  arriving never walks straight back through.
- **Future (DESIGN):** a ramp or ladder is a portal whose ends lie on levels L and L-1. A shaft is a portal whose two
  ends share (x, y) on levels L and L-1, which is why the levels share coordinates. Rails cross a portal as a track
  record with the same two ends.

## 3. Movement and pathing

| Who | How | Label |
|---|---|---|
| Player collision | The four foot corners (`main.gd::_blocked_corners`) ask `World.solid_for_player(cell)`: the surface's `VillageMap.is_solid_world` on level 0, the level map's `is_solid` below. One added branch; the surface branch is the old call | DESIGN |
| Player tap-to-walk | `World.path_for_player(from, to)`: `VillageMap.find_path_world` on level 0, the level map's own A* below (clamped to its region, the nearest floor cell when the goal is rock) | DESIGN |
| Crossing | `World.player_through(dir)`: if the player's cell is a portal's stand and `dir` points at its door, the player moves to the other end and `World.player_level` changes. Called by Main after each movement step, and when a tap-to-walk ends at a stand with its goal on the door. Refused while the player pulls a cart ("The cart will not go down the adit.": carts below are MIN-F's rails) | DESIGN |
| NPC router | `NPC.depth` (the villager's level; saved as `"level"` only below the surface; `NPC.level()` is the skill lookup, hence the name). A plan step `{k: "go", to, level}` (`NPCBrain.go(c, speed, level)`; the key is left out on the surface, so surface plans are unchanged) whose level differs from the walker's is routed by `World._walk`: walk to the portal's stand on the walker's own level (`Underground.next_leg`, a breadth-first search over the portals), go through (`World._npc_through`: the other end's stand, a pulled cart set down at the mouth, counted `portal_crossings`), and walk on with the other level's A*. Every plan to a surface place made below therefore walks out first. Plans are not saved; a villager loaded below plans again from there | IMPLEMENTED (`wip/b17-mining2`) |
| Scheduling | `World.villager_levels` is `[0, -1]`. Miners, labourers and the manor's quarry hands pick seams with `World.nearest_seam(n, ores)`: the nearest by the same rule as on the surface, the distance across levels walked through the portal; `NPCBrain.seam_steps` plans the walk beside the seam on its level and the swing (`mine`, `mj_mine` with the seam's level). The labour market's miner places, the caravan's import check and `Quests.deposit_left` (the caravan's stone, the manor quarry, contracts) count the gallery's ore | IMPLEMENTED (`wip/b17-mining2`) |
| Safeguard | A villager below whose cell is not floor of their level (moved by a rule that knows no levels, such as a door) is counted on the surface (`World._update_npc`); `World._unstick` leaves villagers below alone | IMPLEMENTED |
| Path cost | One extra `AStarGrid2D` the size of the gallery's region (24 x 10 cells, 240 points, for the adit gallery), against the village's 10,800; the gallery has 56 to 81 floor cells for seeds 1, 2 and 7 | VERIFIED (measured) |

## 4. Rules across levels

Positions stay 2D `Vector2`; the level is a separate field. A rule that compares two positions must also compare
their levels. **DESIGN:** a helper `World.same_level(a_level, b_level)` and, per actor, its level field.

| Site | Today | In this branch | Next step |
|---|---|---|---|
| The player's target list (`main.gd::_find_target`) | surface lookups | Below ground a level-only finder (`_find_target_below`): seams and loot of the player's level; the seam target is the surface's own, so Use mines it by `World.work_mine` | - |
| Taps (`main.gd::_tap`) | surface lookups | A tap on the adit (either side) walks to its stand and goes through. Below ground: walk, take a pile of the level, or use the seam beside the player | Gather mode below (`ResourceNodes.node_at` is surface-only) |
| Attack and Fireball | surface creatures and projectiles | Refused below ground ("Nothing to fight here.") | when NPCs and animals can be below |
| Loot | no level | `"level"` on loot dropped below (absent = 0); the surface lists skip it; guards never recover it | - |
| Guards recovering loot (`NPCBrain._loot_to_recover`, `recover_loot`) | all loot | Skip loot below (one-line hooks) | villagers below |
| Awareness and reach (`World.near`, `present`, `reaches`) | positions only | `World.level_at(p)` (`Underground.level_at`: a gallery's floor and walls under the hill's rock are its level, everything else the surface's) and only villagers of that level are seen or reached; `reaches` is false across levels. Every witness, chat partner, guard sighting and target list built on them sees one level | - |
| Fights (`NPCBrain.fight`, `_prey_for`, `_bandit_seen`, `_guard_near`) | positions only | A fight across levels ends at once; bandits prey only on their own level; sightings compare levels | - |
| Fauna (`Fauna._foe_pos`, `_hunt_people`, flight) | the player's and villagers' positions | Animals live on the surface: nobody below is a foe, prey or threat to them | animals below (none planned) |
| Relations (`Relations` chats) | positions only | Chat partners are on one level | - |
| The player and villagers below (`main.gd`) | - | Villagers working below are drawn in the gallery only, and can be talked to there (target list, taps); talking and striking need the same level | combat below (melee and Fireball stay refused) |

## 5. Saving

| Item | Design | Label |
|---|---|---|
| Version | `World.SAVE_VERSION` 16 -> 17 for Build 17. Every Build 17 change that adds save keys shares this one bump (the lead merges the version comment). `SaveTransfer.MIGRATIONS` stays empty: every new key has a default when absent | DESIGN |
| Player's level | `"underground": {"gen": 1, "player_level": L}`. Absent: the surface. On load, a player saved below on a cell that is no longer floor (a generator change) is put on the nearest floor cell, and on the surface stand if the level is gone | DESIGN |
| Deposits | Saved whole in `deposits`, as today; underground seams carry `"level"`; surface seams carry none (absent = 0), so surface records and older saves are unchanged | DESIGN |
| Load merge | `World.load_dict` appends map seams missing from the save keyed by **(level, x, y)** (was (x, y)): the village's seams (level 0), then the generated level seams. A save from before Build 17 loads with the gallery's seams full | DESIGN |
| Loot | `"level"` written only when not 0; read back with default 0 | DESIGN |
| Later keys | `NPC "level"`, carts `"level"`, animals `"level"`; dug cells per level as changes, `"dug": [[level, x, y], ...]`, like `overworld.rock_changes` (saves store changes, not terrain) | DESIGN |
| Generator bumps | A change to a gallery's shape for an existing seed bumps `Underground.GEN_VERSION`. Saves record `gen`; a save of an older `gen` keeps its seams by (level, x, y) where the new map still has rock there, and the load step above moves the player to floor. The old generator is kept if a bump would strand saved seams | DESIGN |

## 6. Deposits underground (reuse, `DEPOSIT_SUSTAINABILITY.md` section 4)

- **Same records:** `{x, y, ore, amount, level}` in `World.deposits`. Same `resources.json` nodes, same ore-dot
  sprites (`deposit_tiles`), same worked-out sprite, same `World.mine_unit` and `World.work_mine` (pickaxe, Mining
  level 3 for gold, skill effects, wear, 8 xp a unit), same `mined_<ore>` counting, same save array. No refill.
- **Adapted (DESIGN):**
  - `World.deposit_at(c, level := 0)` and `World.nearest_deposit(from, ores, level := 0)` match the level. Existing
    callers pass nothing and keep getting surface seams.
  - `mine_unit` sends a level seam's worked-out tile change to the level's view (`World.level_tile_changed`), not to
    the village's `below0`.
  - Sums that mean "what the village's own workers can mine" (`NPCBrain.job_market` miner places,
    `NPCBrain._caravan_imports`, `Quests.deposit_left` used by the caravan's stone and the manor quarry) count only
    seams on `villager_levels`, which since `wip/b17-mining2` is `[0, -1]`: villagers walk to the gallery, so its
    ore is the village's own and the caravan's import of iron ore, coal, copper ore and stone waits until the gallery
    too is nearly worked out. (In the foundation branch, before villagers could go below, these sums left the
    gallery out.)
  - `World.plant_refusal` and the placement checks ignore seams below (they lie under rock in any case).

## 7. Rendering and transitions

| Item | Design | Label |
|---|---|---|
| Level view | `LevelView` (`game/scripts/view/level_view.gd`, a `MapView` sharing the village's TileSet): a dark ground under the region, a floor layer, a wall layer (the rock beside the floor) and a deep-rock layer (darkened), a seam layer (the same ore sprites as the surface), and the darkness overlay. Added between the surface tile views and the characters | DESIGN |
| Art | The tiles already imported: the hill's own rock (`ROCK_FILL`, Puny World paid atlas) for walls, the mine yard's dirt for floors, the `deposit_tiles` ore sprites for seams. The rock that is the hill's top above is the rock of its walls below. The Puny Dungeon pack (CC0, "planned") is a built dungeon (brick, flagstones), not natural rock; its torches, supports and carts are candidates for MIN-F, through `tools/import_game_assets.py` and the asset skill | DESIGN |
| Fade | Crossing a portal fades the surface (village and overworld tiles, roofs, canopies, trees, every surface character, cart, sign and loot) out and the level in over `RoofFade.FADE_TIME` (0.25 s); back again on leaving. The player's sprite never fades. The camera does not jump (the stands are one cell apart) | APPROVED principle; DESIGN detail |
| Surface while below | Hidden (the recommended option in `UNDERGROUND_ARCHITECTURE.md` section 7.2) | DESIGN |
| Darkness | One radial overlay centred on the player: clear within about 3 tiles, darkening to at most 55 % at about 10 tiles. Atmosphere only; no light sources, nothing consumed | APPROVED (atmosphere only) |
| Cost | One extra set of four `TileMapLayer`s for the gallery, drawn only while below; one textured sprite for darkness | DESIGN |

## 8. Open pits on the surface (MIN-E design)

| Item | Design | Label |
|---|---|---|
| Where | On the surface map, in the village grid first (the overworld later through its changes block) | APPROVED (open pits on the surface) |
| State | `World.pits`: `{id, rect, depth: {cell -> 0..N}, ramp: [cells], layers: [{depth, material, amount}]}`. A cell's depth only grows; depth > 0 cells are solid except ramp cells and the floor of the deepest step reachable by the ramp (DVW-A10: every open pit cell reachable) | DESIGN |
| Extraction | Digging a cell one step removes that step's material by the finite `layers` table (topsoil, dirt, stone, and at depth an exposed seam: an ordinary deposit record at level 0 with `"depth"`). Spoil is real items counted `dug_<item>` in the ledger. Items for topsoil and dirt need the owner's open MIN-B/E choice (quarry stone vs blocks vs spoil vs topsoil, Mining spec section 12) | DESIGN / OPEN item names |
| Drawing | Terraces as stepped edge tiles (Forgotten Memories cliff steps, B14-07, "planned"), ramps as path tiles; no roof, no fade | DESIGN |
| Save | Pits saved as changes (rect, depth per cell, layers left) | DESIGN |
| A pit and a level | A pit floor may later hold a portal down to a level (a ramp or shaft end) | DESIGN |

## 9. SET-A: settlement capability schema (sketch for MIN-D)

The roadmap asks for SET-A's schema to be designed during Build 17 so MIN-D builds on it (`docs/EXPANSION_ROADMAP.md`).
Design only; Build 18 implements the model. Sources: Settlement spec sections 4 and 10 (phase A), Mining spec section 3.

```json
{
  "format": "mml-capabilities/1",
  "industries": {
    "mining": {
      "levels": [
        {"level": 1, "name": "Surface extraction",
         "needs": [{"kind": "deposit_access", "level": 0},
                   {"kind": "practitioners", "skill": "mining", "min_level": 1, "count": 1},
                   {"kind": "tool_stock", "tool": "pickaxe", "count": 1},
                   {"kind": "transport", "any": ["handcart", "carrier"]}]},
        {"level": 2, "name": "Prospecting and assay",
         "needs": [{"kind": "practitioners", "job": "prospector", "count": 1},
                   {"kind": "practitioners", "job": "assayer", "count": 1},
                   {"kind": "tool_stock", "tool": "prospecting_kit", "count": 1},
                   {"kind": "records", "what": "discovery", "count": 1}]},
        {"level": 3, "name": "Open-pit excavation",
         "needs": [{"kind": "practitioners", "job": "excavator", "count": 2},
                   {"kind": "structure", "what": "pit_ramp"}, {"kind": "transport", "any": ["handcart"]}]},
        {"level": 4, "name": "Underground mining",
         "needs": [{"kind": "portal", "min_depth": -1}, {"kind": "structure", "what": "timber_support"},
                   {"kind": "practitioners", "skill": "mining", "min_level": 3, "count": 2}]}
      ]
    }
  }
}
```

- **Derived, never stored as truth (DESIGN):** a settlement's level per industry is recomputed (at dawn) from the
  world: living practitioners and their skills (`NPC.skills`, PAR-01), tool stocks, structures, portals and records.
  It rises when every need of the next level holds and falls when one stops holding (the spec's "can regress").
  The save keeps only the last computed levels and the dates they changed, for history and the wiki.
- **Cross-industry needs:** a need may name another industry's level (`{"kind": "industry", "id": "smithing",
  "min": 2}`), so mining 4 can depend on carpentry and smithing, as the spec asks.
- **Knowledge:** `records` needs refer to a discovery log with provenance (who knows it), which MIN-C creates.
- **Not decided here (OPEN, for SET-A/B):** the thresholds, the industries beyond mining, and how a level changes
  NPC decisions (MIN-D's "autonomous adoption").

## 10. Acceptance tests per phase (measurable)

| Phase | Test | Pass condition |
|---|---|---|
| A (this document) | Register and documents | This record committed; `check_requirements.py` 0 problems (the lead's step) |
| F-foundation (this branch) | `underground_test.gd` determinism | Two worlds of one seed give byte-identical gallery maps (solid, floor, seams); two seeds differ |
| | reachability | Every floor cell is reachable from the inner stand by the level's A*; the floor lies only under static surface rock; no floor cell outside the region |
| | portals | Pushing into the adit moves the player to level -1 at the inner stand; pushing out returns them to (48, 10) on level 0; positions and level round-trip exactly; a cart refuses |
| | collision | Below ground the player cannot walk into rock; on the surface the old collision answers every cell as before |
| | seams | A level seam is found by `deposit_at(c, -1)` and not by `deposit_at(c)`; `work_mine` takes one unit, counts `mined_<ore>` and gives 8 xp, as on the surface; the worked-out signal goes to the level |
| | save/load | A save made below loads below at the same position; half-worked level seams keep their amounts; a save without the new keys loads with the player on the surface and the gallery's seams full |
| | surface unchanged | The surface map's solid cells, the village's deposits and a short surface simulation are identical with and without the gallery's seams in `deposits` (villager sums and choices ignore level seams) |
| F-router (next) | NPC below | A miner sent to a level seam walks to the adit, crosses, mines and carries the ore out; its path never leaves its level between portals |
| | same-level rules | No witness, reach, aggression or loot recovery across levels |
| B | quarry stone | A worked-out ore seam yields stone from a finite second pool, then refuses; `mined_stone` equals the pool's fall |
| C | prospecting | Clues deterministic per seed, some false; a toolkit only by `work_craft`; an assay never certain |
| D | hidden deposits | Nothing hidden in `deposits` before discovery; capability levels rise and fall with their needs |
| E | open pits | Excavation conserves every unit of topsoil, dirt and stone; no unreachable pit cell (DVW-A10) |
| G | validation | 100/365-day multi-seed runs: ledger residual 0 for every `mined_`/`dug_`/`imported_` good, every pool (surface, pit, level) by id; v16 -> v17 save fixture |

## 11. Work in this branch, and what remains

| Done here | Remains |
|---|---|
| MIN-A record (this document) | MIN-B..E, G as planned in `BUILD_17_PLAN.md` |
| `LevelMap`, `Underground` registry and generator, `underground.json` | Carts through portals (MIN-F rails); a cart pulled to the adit is set down there |
| The adit portal pair, player crossing, collision and tap-walk below; Gather mode below (`ResourceNodes.node_at` looks on the player's level) | Stacked levels: `level_at` reads the ground, which is enough for one level per place |
| Level seams as deposit records; level-keyed lookups and load merge | Combat below (Attack and Fireball are refused below; `Combat` and projectiles are surface-only) |
| Player level and loot level saved (SAVE_VERSION 17) | Carts, animals and NPCs below; rails, supports, lighting as a need (MIN-F) |
| `LevelView`, fade, darkness overlay | Cave-specific art (supports, torches) through the asset skill |
| (`wip/b17-mining2`) Villagers below: `NPC.depth`, the level router, `nearest_seam`, `seam_steps`, `villager_levels = [0, -1]`, same-level guards | |
