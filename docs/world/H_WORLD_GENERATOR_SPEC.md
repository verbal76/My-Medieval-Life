> **HISTORICAL LITERARY RESEARCH — NOT BINDING GAME CANON OR DESIGN (owner, 2026-10-27).** William Morris source research is retained as literary evidence and possible inspiration, not the specification for the already developed My Medieval Life. Names, geography, maps, history, political systems, magic and novel events do not become required game content without new, explicit owner approval. Consult the current register and directives. Research text below is preserved for provenance.

# H. Procedural world generator: design specification

**Status: proposal.** No engine, scale, tile size, coordinate system or algorithm is chosen here.
Those decisions are listed in J. This document specifies *what* the generator must do with the
literary evidence and *how* determinism and saves stay safe. It builds on `docs/ARCHITECTURE.md`
§3.1 (the `WorldSource` interface and PCG32 port), which it does not change.

Everything in this document is **GAME EXPANSION** design. The canonical inputs it consumes are
CANON or CANON-INFERRED records with paragraph citations.

## 1. Inputs

| Input | File | Versioned by |
|---|---|---|
| Canonical dataset | `research/registries/*.json` (entities, spatial, travel, facts) | dataset hash: sha256 of the registry files, recorded in each world |
| Constraint set | `research/registries/worldgen_constraints.json` (342 nodes, 296 constraints; built by `tools/lore/build_constraints.py`) | same dataset hash |
| Design overlay | original regions, the starting county, era state, unit conversions (§4) | its own version number (`overlay_version`) |
| World seed | 64-bit integer | n/a |
| Generator | code | `generator_version` |
| Settings | world size, density, era (E1/E2/E3, see D §2), difficulty knobs | stored with the world |

Same seed + generator version + dataset hash + overlay version + settings = the same world,
byte for byte (CLAUDE.md §6).

## 2. What the evidence gives the solver

`worldgen_constraints.json` classifies every spatial record:

| Kind | Meaning | Count (hard / soft / info) |
|---|---|---|
| direction | a lies north/south/east/west of b | 19 / 26 / 1 |
| distance | stated miles, leagues, days or hours | 20 / 24 / 1 |
| sequence | A, then B, along a journey (no direction implied) | 20 / 18 / 1 |
| containment | within, on, surrounds, outside | 24 / 12 / 0 |
| adjacency | near, beside, at the foot of, across from | 21 / 22 / 2 |
| visibility | can see, overlooks | 10 / 2 / 0 |
| flow | upstream, downstream, flows into or from | 4 / 5 / 1 |
| beyond, between, crossing | relative placement with a third reference | 14 / 23 / 3 |
| other | relations a solver cannot use directly | 0 / 0 / 23 |

- **hard** = `fixed` certainty, stated in narration. The generator must satisfy it.
- **soft** = `constrained`, or spoken by a character, or from a tale or rumour. Satisfy where
  possible, with a penalty when not.
- **info** = recorded for writers, not for the solver.

Nodes carry the gazetteer's certainty: **fixed**, **constrained**, **flexible**, **unplaced**,
or **original** for overlay places.

### The macro skeleton the evidence supports

Without coordinates, the text fixes a chain from home to the World's End:

```
Hill-country (N) ── Wood Debateable (N march) ── bishop-baron (beyond, N)
                         │
   Four-want-way ── UPMEADS (Upmeads Water flows W→E) ── [west road: unknown] [east road → … Whitwall]
                         │ south
                      Wulstead (on a little hill; outside Upmeads)
                         │ south: the Downs (Bear Hill, Bear Castle, Greenway, thorps)
                         │ ~40 miles Wulstead→Higham
                      Higham-on-the-Way (river round it; Westland Barons ~20 mi W)
                         │ south: vine country → Bourton Abbas (by noon)
                      dry waste → Wood Perilous ── crossroads (Hampton E, Burg S, peopled parts W)
                         │                                    │
                      Abundance (via stony waste, wide river, wasted downland)   Burg of the Four Friths
                         │ south: long lake … desert … Swelling Flood (ford) → Whitwall (+Swevenham 4 mi)
                         │ east, 3 days: mountain wall → Mid-Mountain House → Cheaping Knowe
                      Whiteness (~50 mi) → Goldburg mountains (7 days) → Goldburg (river to the sea)
                         │ east: heath and bog → Utterbol moorland → Utterness, Utterbol, Dale of the Tower
                         │ east: Great Mountains (Wall of the World), forest of Utterness
                      Sage's house → chestnut valley → Sea of Molten Rocks → Rock of the Fighting Man
                         │ 30 days: Vale of Sweet Chestnuts → 9 days: Innocent Folk → weeks: House of the Sorceress
                      Thirsty Desert → Dry Tree → black-sand river (flows E) → Well at the World's End, Ocean Sea (E)
```

This chain is the **spine**. On the eastern half, directions are almost all "east" and waters run
east. On the western half, directions are mostly north–south. The "east road" from Upmeads and the
route Wulstead → Wood Perilous → Whitwall (BTWO-C14) are the main lateral links.

## 3. Pipeline

```
dataset + overlay + seed
   │
   ▼
[1] Macro solve ─► macro layout: an (x, y) for every canonical and overlay node, plus region polygons
   │                validated against every hard constraint (fails loudly)
   ▼
[2] Corridors ───► rivers (with flow direction), roads and highways, passes, barriers (mountain walls, lava sea)
   ▼
[3] Regions ─────► biome and terrain per region from terrain words in the evidence
   │                (wood, downs, desert, waste, mountains, lava, marsh, sea)
   ▼
[4] Polities ────► era overlay: who rules which region (D), allegiances, conflicts
   ▼
[5] Settlement fill ► original villages, manors, mills, inns on the corridors, sized by resources
   ▼
[6] Local chunks ─► tiles, generated on demand per chunk from (seed, region, chunk), never all at once
```

Stages 1–5 make a small **world atlas** (kilobytes to a few megabytes). Stage 6 is streamed.

### 3.1 Macro solve (stage 1)

- Variables: one 2D point per node, plus a radius for area nodes (woods, downs, deserts).
- Hard constraints become feasibility checks:
  - direction: the bearing from b to a lies within ±θ of the stated compass point. θ is a setting,
    e.g. 60°, because Morris's "north" is not a survey bearing.
  - containment: a lies inside b's area.
  - sequence: journey order along the route polyline.
  - distance: within a range (§4).
  - flow: elevation strictly decreasing downstream.
  - visibility: within a sight distance, with no barrier between.
- Soft constraints are weighted penalties (weight by confidence: high 1.0, medium 0.5, low 0.2).
- The solver is **deterministic**: seeded PCG32 (ARCHITECTURE §3.1), fixed iteration counts,
  integer or fixed-point arithmetic. Candidates are relaxation or annealing on an integer grid. A
  float solver is acceptable only if the macro layout is stored in the save (§6), which makes
  cross-machine float drift harmless.
- Output includes a **validation report**: every hard constraint pass or fail, every soft
  constraint's residual. A world whose hard constraints fail is rejected, and the seed is
  re-rolled deterministically (seed, attempt 1, 2, …).
- Unplaced and flexible nodes are placed after the fixed ones, in suitable biomes, near the
  places the text associates them with.

### 3.2 Corridors (stage 2)

- **Rivers**: Upmeads Water (W→E, with the Ford, the high-road bridge, the Red Bridge and the
  High House bridge), the river round Higham, the wide river of the empty valley, the Swelling
  Flood (ford on the highway), Goldburg's river (to the sea, about twenty leagues to the great
  wood), the black-sand river (E into the Ocean Sea), and the Well's stream across the black sand.
  Flow constraints set the elevation gradient.
- **Roads**: the Four-want-way's four roads, the high road through Wulstead, the Greenway (S from
  Bear Castle over treeless downs), Higham's southern road through the vine country, the Wood
  Perilous crossroads (four ways), Whitwall's east highway, the mountain road via Mid-Mountain
  House, the Utterness highway (forest on the right, tillage on the left).
- **Barriers and passes**: the Great Mountains (Wall of the World) with the pass of the Fighting
  Man; the Goldburg mountains (7 days of stony maze); the Sea of Molten Rocks with its green belt;
  the Thirsty Desert. Passes are the only crossings.

### 3.3 Era overlay (stage 4)

The era setting (E1/E2/E3) selects rulers, garrisons, ruined or occupied places (Higham-land half
ruined in E2, Wulstead paled in E2) and active conflicts. Geography is identical across eras.
**Only the political and settlement state changes**, so an era choice never moves a place.

### 3.4 Settlement fill (stage 5)

- Original settlements are placed where the evidence leaves space (G), never on top of canonical
  places, and never so that they break a hard constraint. For example, nothing may stand between
  Wulstead and Higham that contradicts "big downs, waterless, roadless".
- Each settlement gets resources from its biome (sheep and wool on downs, vines and orchards
  south of Higham, timber and charcoal in woods), a size class, a ruler from the era overlay, and
  links to the nearest corridor.
- Settlement density is tuned per region from the text's own descriptions: "peopled parts",
  "waste", "empty because of war", "well-tilled".

### 3.5 Local chunks (stage 6)

- The world is split into fixed-size chunks. Each chunk's content is a pure function of
  `(world seed, generator version, chunk x, chunk y, atlas)`, with the sub-seed derived by hashing,
  e.g. `pcg32(hash64(seed, cx, cy))`. Chunks can then be generated in any order, on any machine,
  and still match.
- The existing Python tools (`tools/puny_terrain.py`, `tools/miniworld_terrain.py`, rivers, roads)
  are candidates for the chunk renderer once a tile scale and art family are chosen (J).
- Only chunks near players are generated or simulated (§7).

## 4. Units and conversions (settings, not facts)

The text gives miles, leagues, furlongs, yards, days, nights and hours. Converting days or leagues
into map distance is a **design assumption**. Keep it in the overlay, never in the canonical data.

| Text unit | Canonical value | Proposed default (GAME EXPANSION) |
|---|---|---|
| furlong, mile, yard | fixed English lengths (1/8 mile, 1 mile, 1/1760 mile) | as is |
| league | not stated in the novel | 3 miles |
| a day's ride (horse) | varies: one day to Mid-Mountain House's knoll; "forty miles" Wulstead–Higham ridden in about a day (BONE-C3–C5) | 25–40 miles, terrain-adjusted |
| a day on foot | | 15–20 miles |
| a day by ox pace | Innocent Folk journeys | 10–15 miles |
| "no great way", "not very far" | qualitative | a short range |

Distances are ranges, not points. Terrain multipliers (mountains, wood, desert) apply to time
units only.

## 5. Scale options (decision J-G1)

| Option | What it means | Pros | Cons |
|---|---|---|---|
| S1 True scale | Wulstead–Higham ≈ 40 miles at walking scale | faithful | hours of empty walking; needs fast travel |
| S2 Compressed | uniform scale factor (e.g. 1:10–1:30) on the macro layout | travel times playable; relative geometry preserved | stated distances stop matching walk times |
| S3 Hybrid | full scale inside regions, compressed travel between regions (journey screens or events) | rich local play, fast long journeys | two travel modes to design |

The macro solve is scale-independent: it works in miles, and the scale is applied when chunks are
laid out.

## 6. Determinism and saves

- **Store the atlas in the save.** The macro layout, corridors, polities and settlements (stages
  1–5) are small. Storing them means a later dataset correction or solver change cannot move a
  town in an existing world (CLAUDE.md §7: "store the generated map in the save"). Only stage 6
  chunks are regenerated from the seed, and their generator version is pinned per world.
- A world records: `generator_version`, `dataset_hash`, `overlay_version`, `seed`, settings, era,
  and the atlas. Player changes are stored as per-chunk deltas.
- A new dataset version applies only to new worlds, unless a migration explicitly adds content to
  unexplored regions of old worlds (an owner decision when it arises).
- Golden-seed tests: fixed seeds produce a known atlas hash and known chunk hashes, in the Python
  reference and in any engine port (ARCHITECTURE §3.1).

## 7. Simulation level of detail (relevant to NPCs and multiplayer)

The owner's living-world document (`docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` §11) names the tiers
**Detailed**, **Abstract** and **Dormant**. Those names are used from now on: Active = Detailed, and
Near and Far are two schedules inside Abstract.

| Ring | Where | Simulation |
|---|---|---|
| Active | chunks within view of any player | full: NPC routines, physics, combat |
| Near | the regions players occupy | NPCs in schedules without pathing; production and trade ticks |
| Far | the rest of the world | coarse: polity and economy ticks on a slow clock; events (raids, wars, harvests) as rolls |
| Stopped | when the host is not running | nothing; the world resumes from its save (owner requirement) |

With 3–4 players far apart, each player's surroundings are active rings. Far-ring ticks run on
the host only.

## 8. Validation the generator must report

1. Every hard constraint: pass or fail (a failure rejects the world).
2. Soft-constraint residuals, worst first.
3. Every canonical node placed exactly once. No original node within the minimum spacing of a
   canonical one.
4. Every river flows downhill to a sea, a lake or the map edge, in its stated direction.
5. Every canonical journey in `travel.json` is routable along corridors, with its stated time
   within a tolerance under the chosen unit conversions.
6. Atlas hash and chunk hashes for golden seeds.

## 9. Not decided here

Engine, map scale, tile size, chunk size, isometric projection details, the solver algorithm,
era, and starting county. See J.
