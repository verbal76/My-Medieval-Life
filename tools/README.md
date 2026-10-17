# Asset tools

Python 3 + Pillow. Everything reads straight from the zips in the repo root; nothing is extracted.

| Script | What it does |
|---|---|
| `puny_chargen.py` | Random characters from the PUNY CHARACTERS TDSM style (a port of its `manifest.tds`). Writes a full 8-direction sheet, a walk GIF and a recipe JSON per character, plus `lineup.png`. |
| `puny_terrain.py` | Procedural terrain from the Puny Characters orthogonal tileset's corner terrain set. Writes a PNG and a Tiled `.tmj`. |
| `render_tmj.py` | Renders the packs' Tiled sample maps (orthogonal) to PNG. |
| `build_manifest.py` | Regenerates `ASSET_MANIFEST.md` and `asset_manifest.csv`. |

```sh
python3 tools/puny_chargen.py -n 16 --seed 42 --none-prob facial-hair=0.7
python3 tools/puny_terrain.py --size 64 40 --seed 3 -n 3
python3 tools/render_tmj.py --all
python3 tools/build_manifest.py
```

Output goes to `out/` (git-ignored). Same seed, same output.

Notes:
- The TDSM manifest gives facial hair and jaw a 100% "none" chance when randomising; use `--none-prob` to get beards.
- TDSM frame durations are ticks; the GIFs assume 60 ticks per second.
- The terrain set chains Dark Grass - Light Grass - Sand - Shallow Water - Deep Water. The detailed PUNY WORLD tileset has no terrain data, so it can't be auto-tiled yet.
- The PUNY_DUNGEON sample maps reference `../puny-dungeon-tiles.tsx`; the renderer falls back to the copy beside the map.

## miniworld_terrain.py

Layered terrain from the 17 miniworld+ terrain modules (octoshrimpy, **CC BY 4.0: credit required**).
Biomes: `temperate`, `winter`, `desert`, `marsh`. Writes a PNG plus a JSON corner-level grid.

```sh
python3 tools/miniworld_terrain.py --biome temperate --size 64 40 --seed 3
```

## puny_world_terrain.py (+ puny_world_features.py)

Overworld maps from the **free** Puny World tileset, using the Tiled terrain data in its own `.tsx`:
sea depths, sand, grass, dirt patches, a trees overlay, and

- **rivers**: a main river from an inland spring to a map edge, plus a tributary joining it with a
  T-junction. Streams use the tileset's water-path tiles; some stretches widen into the "river"
  terrain and join the stream through Shade's connector tiles (275/301/303/329).
- **roads**: dirt paths linking settlement sites (plus one road off the map edge) along a minimum
  spanning tree; later roads reuse earlier ones, so junctions form naturally.
- **bridges**: only where a stream runs straight across the road (848 or 876 on a `Bridges` layer),
  never next to a spring. As in Shade's sample map, road tiles stop at the bridge.

Writes `punyworld_s<seed>.png`, a three-layer Tiled `.tmj` (Ground, Trees, Bridges; put it next to
`punyworld-overworld-tiles.tsx` to open it) and `punyworld_s<seed>.features.json` (sites, river and
road courses, bridges). The same seed always gives the same map.

```sh
python3 tools/puny_world_terrain.py --size 64 44 --seed 1 -n 4
python3 tools/puny_world_terrain.py --rivers 0 --sites 0     # terrain only
```

Limitations: the river terrain has no transitions to sand or sea, so rivers run through grassland and
off the map edge (as in Shade's samples) rather than into the sea. Wide reaches need straight entry and
exit, so they mostly appear where a river leaves the map.

## miniworld_anims.py / miniworld_buildings.py

Data for the game from the Miniworld sheets, written to `data/` and documented in
[`docs/ASSET_DATA.md`](../docs/ASSET_DATA.md):

- `miniworld_anims.py`: animation frames and timing for all 44 soldier/worker sheets
  (`--previews` writes GIFs and aligned frame strips).
- `miniworld_buildings.py`: building atlas keyed by the names in `Miniworld-Guide.docx`
  (`--previews` writes labelled contact sheets).

## Tests

```sh
python3 -m unittest discover -s tests -v
```
