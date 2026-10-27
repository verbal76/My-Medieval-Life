> **HISTORICAL / SUPERSEDED DESIGN SOURCE — NOT ACTIVE DEVELOPMENT AUTHORITY (owner, 2026-10-27).** This file records early Game Designer interview material, a prototype decision or an obsolete design proposal. Retain it for provenance, not as a current specification, task list, owner approval or permission to implement features. Current guidance comes from `CLAUDE.md`, `docs/PROJECT_MEMORY.md`, `docs/requirements/requirements.json`, later applicable owner directives and validated game code. See `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md`. An old design idea needs new owner confirmation before becoming active.

# Design gap assessment and implementation sequence

Status: **proposal, awaiting owner approval.** Written 2026-10-18 against staging commit `b9f0003`.
Documentation only: no game code was changed and no gameplay mechanic is started by this document.
Everything below is an agent recommendation (`docs/DECISIONS.md` marks such items *Proposed*); the
owner decides, and `CLAUDE.md` section 11 still gates the engine, mechanics, network features and
paid services.

## 1. Purpose and how to read this

The owner states six goals as design intent that **must not be dropped or descoped**. Most are
already Confirmed in `docs/GAME_DESIGN.md` (items 9 to 12) or recorded as owner direction. This
document compares each with the prototype as it is today, names the gap, the risks and the owner
decisions, and proposes a dependency-ordered sequence that keeps the game playable at every step and
starts no major rewrite now.

Effort figures are in **agent-weeks**: roughly one focused agent working one week, including tests
and review. They are rough ranges with stated uncertainty, not commitments. "Uncertain" means the
repository does not settle the question.

### Summary

| # | Goal | Where the prototype stands | Gap | Biggest unknown |
|---|---|---|---|---|
| 1 | Isometric world | Square 16 px orthogonal tiles, oblique-looking art | Large, but mostly in the view layer; the logic grid can stay square | Whether suitable isometric art exists or can be made |
| 2 | Eight-direction sprites | People already use 8-direction sheets; animals partly 4-direction | Small to medium | Art for lying, gear layers and isometric-facing animals |
| 3 | Player-hosted multiplayer (3-4) | Strictly single player; one `World.player`; variable-step simulation | Very large; needs refactors before any network code | How players find and reach a host with no server |
| 4 | Persistent world-specific characters and gear | Character is stored inside the world save; six gear slots; XP skills | Medium | Character identity across hosts, and the heir rule |
| 5 | Learnable magic | One hard-coded spell, learned for coins; stamina as its cost | Large, and blocked on owner answers | J-M1 to J-M4 |
| 6 | Living medieval society | A real 100-villager economy with property, crime, jobs | Medium to very large (it is the long-running stream) | Scale beyond one village; sustainability defects |

## 2. Baseline: what the prototype is

Facts read from the code at `b9f0003` (file references are under `game/`).

| Area | Fact |
|---|---|
| World | One hand-built village, 120 x 90 tiles of 16 px (`data/village.json`, built by `tools/build_village.py`; `scripts/core/village_map.gd`). It is not yet the generated county of `docs/world/H_WORLD_GENERATOR_SPEC.md`. |
| Logic grid | A square grid. `solid` is a byte array; `AStarGrid2D` with octile diagonals does villagers' path-finding (`village_map.gd`). Positions are float tile coordinates (`NPC.pos`, `PlayerState.pos`). |
| Simulation | `World` (`scripts/core/world.gd`) is a headless `RefCounted`; the view only reads it. About 100 villagers in 23 households plus 6 bandits, animals, a manor, property, construction, quests, a job board. Tested headless (`tests/run_tests.gd`, economy runs with a fixed step). |
| Ticking | `World.update(real_dt)` takes the frame time. NPCs within `detail_radius` (34 tiles) of `player.pos` update every frame; the others every 0.5 s with the same rules ("abstract tier"). So results depend on frame rate and on where the player stands. |
| Randomness | All through seeded `RandomNumberGenerator`s (`world.rng`, `Population`); no wall-clock time in `core/`. Same seed with the same fixed step reproduces (the tests rely on it). |
| Player | One `World.player` (`PlayerState`). Hard-wired singletons: NPC `target == -2` means "the player"; ownership ref `"player"` is the family (`World.PLAYER`); crimes, stolen-goods marks, quests and the home are fields of `PlayerState`. The word `player` is on about 110 lines of `world.gd`, 130 of `main.gd`, 55 of `quests.gd`, 50 of `game_ui.gd`. |
| Player actions | Movement (`_try_move`), crafting, striking, casting and gathering are carried out in `main.gd` (a presentation script) by writing to world state. There is no command or intent layer. |
| Pause | Opening some windows and placing a building pause the world (`paused`, "the game waits meanwhile"). |
| Rendering | `MapView` builds square `TileMapLayer`s (`tile_size` 16). `main.gd` draws actors at `pos * T` (`T := 16`); `actors.y_sort_enabled = true`; canopies and roofs live in "above" layers (z 10) and fade by cell lookup (`CanopyFade`, `RoofFade`, `World.roof_idx`). About 60 lines in 8 files multiply or divide by the tile size (a grep count, not an audit). |
| Sprites | `ActorSprite`: Puny Characters sheet, 29 columns x 8 rows of 32 px, rows S, SE, E, NE, N, NW, W, SW. `face()` quantises a vector to 8 directions. Animals: Puny Monsters 12 x 8 (8-direction) or Cozy Farm 4 x 5 (down, up, left, right, sleep). A sleeper is the standing frame rotated on its side (no lying frame). |
| Appearance | A `look` id picks a pre-built sheet (`data/appearances.json`); equipping gear changes stats only, not the sprite. |
| Character data | `PlayerState`: XP per skill (levels cost 100 x level), six gear slots (weapon, tool, armor, head, amulet, ring), inventory, chest, coins, stamina, hunger. |
| Magic | `PlayerState.spells = {"fireball": true}`; the Sage teaches Fireball for 50 coins; casting costs 30 stamina with a 6 s cooldown; a `magic` skill unlocks cooldown and damage (`main.gd fireball()`, `data/skills.json`, `data/balance.json`). |
| Save | One JSON file, `user://save1.json`, from `World.to_dict()`; `SAVE_VERSION` 8; written to a temporary file then renamed; autosave each game hour. The whole world and the player are one document. Old versions migrate in `load_dict`. |
| Death | Permadeath with an heir: the heir keeps the family's home, chest and property, starts every skill from nothing and loses spells (`World.continue_as_heir`). |

## 3. Goal 1: isometric world (2D/2.5D)

| | |
|---|---|
| **Current state** | Orthogonal square tiles (`map_view.gd`), `pos * T` drawing, screen-aligned input, tap-to-cell by dividing by `T` (`main.gd _cell_at`, `village_map_view.gd`, `placement_ghost.gd`). Terrain, buildings and trees are drawn in an oblique front view, not in a diamond projection. `docs/GAME_DESIGN.md` P2 (top-down) is superseded by Confirmed 11; `J-G4` is still undecided. |
| **What exists to reuse** | The simulation, collision, path-finding and save are all in grid coordinates and do not care how the grid is drawn: **an isometric view can be a projection of the same square grid**, which keeps `core/` unchanged. Godot's `TileMapLayer` has an isometric tile shape and per-tile y-sort. Y-sorting of actors, roof fade and canopy fade already exist and need adapting, not inventing. `tools/render_tmj.py` and the Tiled tooling read `.tmj` maps. |
| **Art that exists** | In the repository, isometric content is limited to the Puny Characters Editor Edition's demo: `Tiled-Maps/Isometric/` holds `Isometric-map.tmj` (orientation isometric, 32 x 16 tiles, a 32 x 32-cell map with five block layers, a vegetation layer and a character layer) and `Isometric-tiles.png` (128 x 96, 12 tiles in 32 x 32 cells). It reuses the same `Characters.png` as the orthogonal and hexagonal demos (identical hash in `asset_manifest.csv`). It is a **sample**, not a medieval terrain, building or tree set. I did not view the demo, so how well the 8-direction characters sit on it is **uncertain**. No other pack in `ASSET_MANIFEST.md` has isometric content. The owner has mentioned an isometric animal pack that is not uploaded (`docs/DECISIONS.md`); whether other isometric art exists is **unknown**. |
| **Gap** | (a) A projection layer: grid to screen, screen to grid, depth key. (b) Input: movement vectors, tap and mouse picking, placement ghost and map window all assume screen axes equal grid axes. (c) Terrain, building, tree, interior and prop art in a diamond projection: **none exists** for the medieval set. Re-projecting today's 16 px oblique tiles by rotating 45 degrees and squashing is possible in principle, but pixel-art quality, building legibility and roof and wall shapes are **uncertain** and need a visual test. (d) Depth sorting for multi-cell objects (buildings, canopies, fences); isometric ordering is harder than the current simple y-sort. (e) Roofs and interiors: the roof fade works on cell lookups and will need new occlusion geometry. (f) Scale and UI: a 2:1 diamond is wider per cell than a 16 px square, so zoom, camera dead zone, speech bubbles and markers change. |
| **Dependencies and risks** | Depends on a coordinate abstraction (R1 below). Biggest risk is **art**, not code: without isometric terrain and buildings the work stops at a placeholder. Second risk: the owner's meaning of "isometric" (see decisions) could be a true 2:1 diamond projection or the oblique "3/4 top-down" look of today's art; they have very different costs. Third: UI and touch controls were tuned on a phone for the current view (device checks pending, `docs/DEVELOPMENT_QUEUE.md`). |
| **Owner decisions** | D1 (definition and reference picture), D2 (art source: commission, buy, re-project, or mix; this is `J-G4`). |
| **Effort** | Coordinate abstraction and input: 1 to 2 agent-weeks. Isometric renderer with placeholder art, depth and picking: 3 to 5. Converting roofs, canopies, interiors, placement and map window: 3 to 6. Art production or purchase: **uncertain, possibly the largest cost and lead time**; do not schedule until D2 is answered. Total code about 7 to 13 agent-weeks, high uncertainty (art excluded). |

## 4. Goal 2: eight-direction character sprite animations

| | |
|---|---|
| **Current state** | Already largely in place for people: `actor_sprite.gd` uses the Puny Characters layout (29 frames x 8 rows) for the player, villagers, guards and bandits, with idle, walk, sword, bow, throw, hurt, death, carry and work. Direction comes from a facing vector (`face()`). Puny Monsters animals are 8-direction too. |
| **What exists to reuse** | The sheets, the animation table (`ANIMS`), `tools/puny_chargen.py` (a headless port of the layered character maker: skins, shoes, clothes, gloves, hair, headgear, add-ons), and `data/appearances.json`. |
| **Gap** | (a) In an isometric view the sheet row must be chosen from the **screen-space** direction of motion, not the grid direction, so `face()` needs the projection (a one-line change once R1 exists). (b) Cozy Farm animals have 4 directions only (livestock). (c) No lying or sleeping frames; sleepers are rotated. (d) Equipment is not visible, because sprites are pre-built sheets per look; showing gear needs layered sprites (the pack is layered, and `puny_chargen.py` already composes layers offline). (e) Frame and timing data for the Puny sheets is not exported as JSON yet (`docs/DEVELOPMENT_PLAN.md`, "Known limitations"). |
| **Dependencies and risks** | Layered runtime sprites cost memory and draw calls on a phone (uncertain: not measured). A 4-direction animal in an isometric world looks wrong unless remapped or replaced. |
| **Owner decisions** | D7 (must worn gear be visible; which gear). |
| **Effort** | Isometric-aware facing and animal fallback: 0.5 to 1. Layered appearance and visible gear: 2 to 4. New art for lying, animals, gear: **uncertain**. |

## 5. Goal 3: player-hosted multiplayer, about 3-4 players, no always-on server

| | |
|---|---|
| **Current state** | Single player only. `docs/ARCHITECTURE.md` section 4 left networking out deliberately; the living-world design (`docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` sections 11 and 12) already prefers a **host-authoritative** simulation that pauses when the host closes. |
| **What exists to reuse** | The simulation is headless and separate from the view, which is the single most valuable property. Conservation invariants and the transaction functions (`World.trade`, `transfer`, atomic sales) are the right shape for host validation. The save is a complete, serialisable world state. Godot's high-level networking (ENet, WebSocket, WebRTC) is available (`docs/ARCHITECTURE.md` section 1). |
| **Gap** | 1. **One player is baked in** (section 2): `World.player`, `target == -2`, `"player"` ownership, quests, crimes and the home on `PlayerState`. Needs a set of players keyed by id, with refs such as `player:<id>`. 2. **No command layer**: player actions are executed by `main.gd`. A host must receive intents ("buy 3 wheat from vendor 12"), validate and apply them. 3. **Variable-step, player-distance-dependent ticking**: the simulation differs with frame rate and with who is near; with several players the detail zones must be the union of all players' areas. 4. **Pause**: any player's menu cannot freeze everyone. 5. **Sync**: replicate about 106 NPCs plus animals, items, doors, fields and trees to clients. 6. **Per-player knowledge**: reputation, crimes known to witnesses, quests, dialogue state. 7. **Connectivity** with no server (below). 8. **Late join, disconnect and host-quit** handling, and the failure scenarios listed in the living-world design section 12. |
| **Lockstep is not a good fit** | Sharing only inputs and running the same simulation on every device (deterministic lockstep) needs bit-identical floating point, path-finding and random sequences on Android ARM and desktop x86, a fixed step, and no per-frame variation. None of that is true or tested today, and `RandomNumberGenerator` parity across platforms is **unverified**. The recommendation is **host-authoritative state replication**: clients send intents, the host simulates and sends snapshots and events. Determinism is still worth having on the host, for replay tests (R4). |
| **Rough bandwidth, an estimate not a measurement** | 106 NPCs at about 8 bytes each (id, quantised position, animation and facing) is about 0.85 KB per snapshot, about 8.5 KB/s at 10 snapshots per second per client before protocol overhead; sending only entities near each client cuts this a lot. This is small. The hard part is **correctness of discrete events** (trades, theft, deaths, construction), not bandwidth. Real-time melee and the Fireball projectile (`main.gd _projectiles_step`) are latency-sensitive; client-side prediction or host-lag tolerance is a combat-design question (U7). |
| **Connectivity (unknown, a real risk)** | "No always-on server" is clear, but a player-hosted game still needs a way for a client to reach the host. On a home network that is a LAN address or port forwarding; on a phone behind carrier-grade NAT, inbound connections generally do not work. Options: LAN and Wi-Fi hotspot only; direct IP; peer-to-peer WebRTC with a free signalling and STUN service (some third-party service is involved, and a relay for hard NATs costs money). Each touches `CLAUDE.md` section 11 ("network or online features; paid services"). Which are acceptable is an owner decision; feasibility on Android is **uncertain** until tested on devices. |
| **Other dependencies and risks** | World time in the design runs only while the host runs, which suits a pause-when-closed model. Cheating: the host is trusted; clients must not create goods or coins. Save compatibility (section 7 of `CLAUDE.md`): the player split changes the save and needs a migration from version 8. Cross-platform play (Android host with a PC client) is likely wanted; performance of an Android host simulating 100 NPCs plus serving three clients is **unmeasured**. |
| **Owner decisions** | D3 (connectivity), D4 (pause rule, time while players are away), D5 (reputation per player or shared, `J-S3`; family or per-player households; player-versus-player harm, which also touches U21), D6 (combat model and latency, U7), D10 (platform order, U1). |
| **Effort** | Preparatory refactors R2, R3, R4: 4 to 8 agent-weeks. Transport, lobby, join and host-authoritative replication for 2 players: 5 to 9. Scaling to 4 players, interest management, late join, reconnect, disconnect and failure tests: 4 to 8. Connectivity beyond LAN: **uncertain**. Total about 13 to 25 agent-weeks, wide because of connectivity and testing on real devices. |

## 6. Goal 4: persistent world-specific character progression and equipment

| | |
|---|---|
| **Current state** | Already world-specific: `PlayerState` is saved inside the world document (`World.to_dict()["player"]`), so progression, gear, home and chest belong to that world. Skills are XP-levelled (`player_state.gd`, `data/skills.json`), gear fills six slots with stat bonuses, and the chest and property belong to the family. |
| **What exists to reuse** | Versioned save with migrations and fixture tests; `Inventory` serialisation; the inheritance/heir path (`continue_as_heir`) as a model for "a character leaves a world". |
| **Gap** | (a) **Identity**: today there is exactly one character per world and no id. Several players need character records keyed by a stable id, with a way to re-attach a returning player to theirs (a player id or token stored by the client). (b) **Where the record lives**: in a player-hosted game, the host's world save is the authority; whether a copy is exportable, and whether a character may enter another world, is undecided. (c) **Equipment visuals** (goal 2 gap d). (d) **Progression rules to reconcile**: the heir starts every skill from nothing and loses spells. Persistent progression, shared family, and permadeath need one coherent rule (U6 is undecided). I did not find a decision entry that settles the heir rule for multiplayer. (e) Equipment depth: armour, jewellery and gear icons exist in the packs, but the item set and bonuses are provisional agent proposals (`docs/DEVELOPMENT_PLAN.md`). (f) Item instances versus stacks: the design asks to decide this early (living-world design section 12); durable, individual gear (wear, quality, provenance) may need instances. |
| **Dependencies and risks** | Depends on R2 (player id) and R5 (separating character and world saves). Risk: a character file that can move between worlds invites duplication of goods and coins and breaks the conservation invariants (`World` header comment); keeping characters inside the host world avoids it. |
| **Owner decisions** | D4: one character or several per player per world; death and heir rule; can characters travel between worlds; whether the client holds a backup copy. |
| **Effort** | Player id and character records (part of R2 and R5): 2 to 4 agent-weeks. Rejoin by identity: 1 to 2. Item instances with wear and quality, if chosen: 2 to 4. |

## 7. Goal 5: learnable magic (knowledge, proficiency, capacity separate)

| | |
|---|---|
| **Current state** | A placeholder: one boolean spell (`spells["fireball"]`), one skill (`magic`, levels 1 to 3 unlocking cooldown and damage), stamina as the cost, 50 coins to learn from the Sage, and a story quest that asks for it. This accidentally resembles the three-way split (knowledge is the boolean, proficiency is the skill level, capacity is stamina), but nothing is designed: the capacity is the same stamina pool melee uses, and `J-M1` (energy source) is undecided. Spells are lost when the heir takes over. |
| **What exists to reuse** | `GameData` JSON tables (items, recipes, skills) with `format` fields; the teach-a-skill quest hook (`PlayerState.raise_to`, quests with `learn`); `docs/world/MAGIC_RESEARCH.md` (119 magic facts with quotes, the M-A, M-B, M-C options, the canon-protected list); the Puny Skills pack (skill icons and effect animations, paid licence). |
| **Gap** | A data-driven model with three separate records: **knowledge** (which formulas or methods a character understands, and how well), **proficiency** (skill at carrying them out, trained by practice), **capacity** (what limits sustained use). Teachers and books (NPCs "obey the same rules"), non-combat uses, practice and experiment loops, failure, and the legal and religious risk of `J-M4`. NPC practitioners need the same model. None of this can be designed until the owner answers `J-M1` to `J-M4`. The Well (`J-M3`) is outside the system in the recommended option M-C. |
| **Dependencies and risks** | Depends on the character save split (R5) and the living-economy skill and recipe-knowledge model (design section 7). Risk of inventing mechanics: `CLAUDE.md` section 11 requires owner approval for any gameplay mechanic, and every game mechanic attached to a canonical thing must be labelled GAME EXPANSION. Multiplayer: spell effects need host validation. |
| **Owner decisions** | D9: `J-M1` (capacity source), `J-M2` (how far Morris-style lore is learnable), `J-M3` (the Well in play), `J-M4` (legal and religious risk); plus whether Fireball stays as a stop-gap, and the choice among M-A, M-B and M-C. |
| **Effort** | Schema separation with unchanged behaviour (R7): 0.5 to 1 agent-week; this is safe before the answers. Design after the answers: 2 to 4. First slice (a few formulas, one teacher, one non-combat use, a practice loop, tests): 4 to 8. Uncertainty is high until D9 is answered. |

## 8. Goal 6: living medieval society with meaningful economy, relationships and progression

| | |
|---|---|
| **Current state** | The strongest part of the prototype. 100 villagers and 6 bandits with jobs, households, pantries, wages, shops, a manor treasury, granary and job board, property and leases, construction, animals, hunting, farming, theft and witnesses and guards, quests that grow from real needs, and talk generated from simulation state. Coins and goods follow conservation invariants that tests enforce (`world.gd` header, `tests/run_tests.gd`). Long runs of 10 to 365 days exist (`docs/release/LONG_RUN_SIMULATION.md`). |
| **What exists to reuse** | All of it. The work is the documented stream in `docs/DEVELOPMENT_QUEUE.md` and `docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md`. |
| **Gap** | (a) **Relationships**: an NPC remembers at most 8 events (`NPC.remember`); there is no relationship graph, family tree, friendship, rivalry, marriage, or reputation beyond crimes. (b) **Life course**: no births, aging or marriage (tracked as approved future work; open question U20). (c) **Law and institutions**: guards and a reeve exist; courts, fines, outlawry and per-region law do not (`docs/world/I_GAME_SYSTEMS.md`). (d) **Scale**: one village. The design wants regions, caravans and a county with Detailed, Abstract and Dormant simulation tiers; today there are two tiers by distance and no regional economy (living-world Phases C to F). (e) **Economic sustainability**: four documented long-run defects and the owner's pending choices on proposals P1 to P3 (queue items 6 and 8; B7-009). (f) **Progression**: skills and gear exist; recipe learning and teachers are only partly there. (g) **Canon grounding**: the county, era and political status (`J-D1` to `J-D3`) are undecided, which limits setting and names. |
| **Dependencies and risks** | R4 (fixed step, deterministic ticking) benefits this goal most, as do replayable scenarios. Scaling NPC counts is **unmeasured** on phones (device checks are pending in the queue). Content burden and balance are the main risks; the owner's balance review of all provisional numbers is pending. |
| **Owner decisions** | D11 (the pending sustainability choices; U20: aging, generations, currency conservation, law, scale, first slice variant; U21: content rating and depiction of crime and thralldom) and D8 (`J-D1` to `J-D3`, `J-G1`). |
| **Effort** | Ongoing. Relationships and memory model: 3 to 6 agent-weeks. Births, aging, marriage and inheritance: 4 to 8. Law and courts: 3 to 6. Second settlement with caravans and regional prices: 6 to 12. Performance work for larger populations: **uncertain**. Treat as a continuous stream, not a single phase. |

## 9. Cross-cutting findings

1. **The best asset is the headless `World`.** It makes both multiplayer and an isometric view
   affordable, provided the logic grid stays square and the view and the player's commands stay out
   of it.
2. **The three structural weaknesses** are the same for several goals: the player is a singleton
   baked into world logic; player actions run in `main.gd`; the tick depends on frame time and on
   one player's position. Fixing these once serves multiplayer, the character split, replay tests
   and the living-world scale.
3. **Art is the long pole for isometric** and for visible gear; code is not. Decide the art route
   early because it has lead time.
4. **Several decisions interlock**: pause rules, permadeath and heirs, combat model and reputation
   scope all change differently in single and shared worlds. They are listed once in section 12.
5. **Engine approval is still formally open** (`docs/DECISIONS.md`, entry *Proposed*). All of the
   below assumes Godot 4.7.

## 10. Preparatory refactors (recommended, each small and reversible)

None changes what a player sees. Each keeps every existing test green, is its own branch and draft
PR (`CLAUDE.md` section 10), and is merged to staging only after the regression suites pass. None
may start without owner approval of this plan. Any change in how systems affect each other adds or
updates its `INT-###` entry in `docs/SYSTEM_INTERACTION_MANIFEST.md`.

| ID | Refactor | Why | Acceptance criteria |
|---|---|---|---|
| R1 | **Coordinate abstraction.** One small class (for example `Projection`) with `to_screen(grid_pos)`, `to_grid(screen_pos)`, a depth key, and a cell footprint. Replace every `* T`, `/ T` and tile-size assumption in `main.gd`, `village_map_view.gd`, `placement_ghost.gd`, `speech_bubble.gd`, `game_ui.gd`, `game_settings.gd`. Start with the identity (orthogonal) implementation. | Makes isometric a swap of one class plus art; also fixes picking and the map window in one place. | Zero remaining direct uses of the tile size outside the class (a grep check in the tests). Screenshots of fixed seeds and positions are pixel-identical before and after (looked at, not only compared). All suites pass. A unit test round-trips grid to screen to grid for random points. |
| R2 | **Players as a collection.** `World.players` keyed by stable id, `World.player` kept as an alias for the local player; `target == -2` becomes a player id; ownership ref `"player"` becomes `"player:<id>"` (family handling decided in D5); crimes, quests, home and stolen marks stay per player. | Removes the singleton that blocks multiplayer and the character split. | Save version 9 with a migration and a fixture test from version 8; a single-player game plays and tests exactly as before; a new headless test runs two `PlayerState`s in one world (one buys, one steals, one is attacked) and all conservation invariants hold; no `-2` literal remains. |
| R3 | **Command layer for player actions.** Introduce `World.apply(player_id, command)` for movement intent, trade, craft, strike, cast, gather, build, take and use; `main.gd` builds commands and reads state. Move family by family, starting with trade and craft. | Gives the host something to validate and a log to replay; keeps rules out of the view. | Each migrated action family has a headless test that performs it only through commands; `main.gd` contains no direct writes to world state for those families (checked by a documented grep list that shrinks to empty); a recorded command log from a scripted play-through replays to the same final state hash. |
| R4 | **Fixed-step, frame-independent simulation with a state hash.** `World.step()` at a fixed rate, accumulated from frame time in the view; detail zone chosen from the set of players; a stable `state_hash()` over the saved state. | Reproducible tests and replays, the basis for any host-side sanity check, and a prerequisite for sensible scale. | The same seed and the same command log produce the same hash at day 10 and day 30 when the frame time is varied (for example 30, 60 and 144 per second); existing long-run results stay within their recorded ranges or the change is documented as a balance-affecting event (a generator or simulation version bump, `CLAUDE.md` section 6); hash identical on Linux and Windows in CI (Android is checked on a device, uncertain until done). |
| R5 | **Character and world save split.** World document without players, plus per-character documents (or sections) with `world_id`, `character_id`, `save_version`; the loader refuses an unmigratable file with a clear message and keeps it (`CLAUDE.md` section 7). | Lets a world hold several characters, lets a returning player re-attach, keeps the option to back up or export characters. | A version 8 fixture loads into the new layout losing nothing (item and coin totals equal); a corrupt or newer file is refused with a message and is not deleted; a round trip keeps `state_hash` equal; atomic write kept. |
| R6 | **Appearance as data.** Compose a character's look from layer ids (skin, clothes, hair, headgear, armour, gear) rather than one pre-built sheet per look; offline build step stays in `tools/`. | Prepares visible gear and lighter asset counts. | Existing looks render identically (looked at); equipping a helmet changes the sprite in a test scene; memory and frame time on a mid-range phone recorded (device check). Only after D7. |
| R7 | **Magic schema separation.** Replace `spells: {name: bool}` with `knowledge`, `proficiency` and a generic `capacity` source, mapped to Fireball, `magic` XP and stamina so behaviour is unchanged. | Lets later magic design land without another save migration. | Save migration with a fixture; Fireball plays identically (cooldown, cost, damage); data lives in JSON with a `format` field; no new gameplay. Only after D9 is at least partly answered. |
| S1 | **Spike, throwaway branch: isometric look test.** Render a small area (a house, trees, a road, three villagers) in a true isometric projection from the existing tiles re-projected, and from the 12-tile demo set, using R1's interface or a stand-in. | Settles whether re-projection is acceptable before anything is committed (D1, D2). | A written note with screenshots that were actually looked at, a list of what breaks, and an owner decision; the branch is deleted or parked, never merged as-is. |
| S2 | **Spike, throwaway branch: network feasibility.** Two headless Godot instances, one hosting a tiny scripted world, exchanging the command log and snapshots over loopback, then two physical devices on a LAN. | Gives measured bandwidth, latency and Android behaviour before committing to the transport (D3). | A written note with measured bytes per second and tick cost on the target phone, and whether an Android device can host and be joined; no production code changes. |

## 11. Implementation sequence

Each phase ends with a game that still plays, saves and loads, and a release-readiness check in the
usual way. Releases and main merges stay owner-gated (`CLAUDE.md` section 5). Phases may overlap
where files do not (for example view work and core work), under the parallel-agent rules.

| Phase | Content | Needs | Playable at the end | Rough effort |
|---|---|---|---|---|
| **0. Decide** | Owner answers D1 to D12 in priority order; at minimum D1 and D2 (art), D3 (connectivity) and D9 (magic) unblock the long-lead items. In parallel, normal queue work continues (living-society stream). | Owner | Unchanged | none |
| **1. Foundation refactors** | R1 first (smallest, unlocks isometric), then R2, R4, R3 in that order (R3 is the largest and can be done family by family), then R5. | Approval of this plan | The same game; saves migrate | 7 to 14 agent-weeks together |
| **2. Spikes** (alongside phase 1) | S1 isometric look test (needs R1 or a stand-in), S2 network feasibility. Results feed D1, D2, D3. | Phase 0 for scope | Unchanged; spikes are throwaway | 1 to 3 together |
| **3. Isometric view and 8-direction completion** | The isometric `Projection`, terrain and building art route from D2, depth sorting, roof and canopy occlusion, input and picking, placement and map window, screen-space facing, animal fallback. Layered gear (R6) if D7. | R1, D1, D2, S1 result | The village in isometric view, same simulation | 7 to 13 plus art (uncertain) |
| **4. Multiplayer, host-authoritative** | Transport and join by the route chosen in D3, intent validation on the host, snapshots and events, per-player UI state, pause rule from D4, then 2 then 4 players, then failure-scenario tests. | R2, R3, R4, R5, D3 to D6, S2 result | Two players share one village, then four | 9 to 17 (connectivity uncertain) |
| **5. Persistent characters, final form** | Rejoin by identity, character records in the host world, item instances if chosen, visible equipment. Largely done by R2 and R5; this phase finishes the rules. | R5, D4, D7 | Returning players find their characters | 3 to 6 |
| **6. Learnable magic, first slice** | Formulas and teachers, proficiency practice, capacity per D9, a non-combat use, NPC practitioners under the same rules. | R5, R7, D9 | A character can learn and use a small set of methods | 6 to 12 |
| **Continuous. Living society** | Sustainability fixes, relationships, life course, law, regional economy and larger worlds, following `docs/DEVELOPMENT_QUEUE.md`. Benefits from R4 early. | Owner choices U20, U21 | Always | ongoing (section 8) |

**Why this order.** The refactors serve several goals at once and change nothing a player sees, so
they are the cheapest risk reduction. R1 comes first because the isometric look is the item with the
longest art lead time and R1 is a small change. Multiplayer waits until the player, the command
layer and the tick are fixed, because networking a singleton-based, frame-dependent simulation would
be rewritten twice. Isometric before multiplayer is a recommendation, not a requirement: after phase
1 the two are independent (view versus core) and can run in parallel with two agents. Magic comes
last because it is blocked on answers and must not add a new save migration by itself.

**What this plan deliberately does not do now:** no engine change, no second engine project, no new
third-party dependency, no network code, no art purchase, no change to a Confirmed design item, no
release or merge to `main`.

## 12. Owner decisions needed

In suggested order of leverage. Each is a question, not a choice made.

| ID | Decision | Options and a recommendation |
|---|---|---|
| D1 | **What "isometric" means for this game.** A true 2:1 diamond projection, or an oblique 3/4 top-down view like today's art (sometimes called 2.5D)? Please give a reference picture. | Recommendation: decide from the S1 look test. Costs differ greatly. |
| D2 | **Isometric art source** (`J-G4`). Re-project the current packs, buy or commission isometric terrain, buildings and trees, or mix. Are there isometric packs not yet uploaded? | Recommendation: S1 first; do not schedule phase 3 until answered. |
| D3 | **Multiplayer connectivity with no always-on server.** LAN and hotspot only; direct IP; peer-to-peer with a third-party signalling or relay service (network and possibly paid, `CLAUDE.md` section 11). Android hosting acceptable? | Recommendation: LAN first, decide the rest after S2 on real devices. |
| D4 | **Shared-world rules.** What pauses the world (any player's menu, placement), how time behaves, one or several characters per player per world, permadeath and the heir rule when one of several players dies, can characters move between worlds. | Recommendation: the world never pauses for one player's menu; characters stay in the host world. |
| D5 | **Reputation and ownership in multiplayer** (`J-S3`): shared by the party or per player; family shared or one household per player; may players rob, wound or kill each other (also U21). | Recommendation: per-player reputation, per-player households, player-versus-player harm off until rated. |
| D6 | **Combat model** (U7) and acceptable latency (real-time melee and projectiles are latency-sensitive in a shared world). | Needed before phase 4 details. |
| D7 | **Must worn gear be visible on the character, and which gear?** | Recommendation: yes for head, body and weapon; decide after R6 cost is measured. |
| D8 | **Era, starting county and political status** (`J-D1` to `J-D3`) and map scale (`J-G1`). | Determines how large the world and NPC counts must become; recommended E3 or E4, county C1 or C4 per `J_OPEN_DECISIONS.md`. |
| D9 | **Magic** (`J-M1` to `J-M4`): capacity source; how far Morris-style lore is learnable; the Well in play; legal and religious risk. Also whether Fireball stays as a stop-gap and which option (M-A, M-B, M-C) is the base. | Recommendation in `MAGIC_RESEARCH.md`: M-A for lore effects plus M-C for the Well. |
| D10 | **Primary platform and input** (U1) and **formal engine approval** (U2). Phase 4 and performance budgets depend on whether a phone is expected to host. | Both are practically assumed (Android first, Godot) but formally open. |
| D11 | **Living-society scope** (U20, U21): aging and generations, law, scale, rating and depiction of crime and thralldom; the pending sustainability choices P1 to P3 and the balance review. | Already tracked; listed here because several goals lean on them. |
| D12 | **Approval to start phase 1**, or a different order. | Recommendation: approve R1 and R2 first as the smallest useful pair. |

## 13. What is not known

- Whether suitable isometric medieval art exists or can be produced to an acceptable quality; the
  repository holds only a 12-tile isometric demo, which I have not viewed.
- Whether re-projected 16 px oblique tiles look acceptable (needs S1).
- Whether a phone can host a shared world (100 NPCs plus three clients), and whether a phone can be
  joined across typical home or mobile networks (needs S2 and device tests).
- Whether `RandomNumberGenerator` and float behaviour match across Android, Windows and Linux
  (relevant to the state hash, not to the recommended replication design).
- How many NPCs a mid-range phone handles; the prototype's device checks are pending.
- Whether any decision entry already approves the heir rule for shared worlds; I found none.
- All effort ranges. They assume the existing test habits (headless suites, fixture saves) continue
  and no scope is added; real costs are likely to land at the top of the ranges for anything
  involving art, devices or networking.

## 14. Verification of this document

Sources read: `CLAUDE.md`; `docs/GAME_DESIGN.md`, `DECISIONS.md`, `ARCHITECTURE.md`,
`BUILD_DECISIONS.md` (searched), `MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` (sections 11 to 17),
`LIVING_WORLD_ALIGNMENT.md`, `DEVELOPMENT_PLAN.md`, `DEVELOPMENT_QUEUE.md`, `docs/world/README.md`,
`J_OPEN_DECISIONS.md`, `MAGIC_RESEARCH.md`; `ASSET_MANIFEST.md` and `asset_manifest.csv`; the
isometric demo's map and tileset files inside `PUNY_CHARACTERS_v2.1.zip` (read as data, nothing
extracted into the repository); and the code named in section 2. No game was run and no image was
viewed for this assessment; line counts are grep counts. Nothing here changes a Confirmed item.
