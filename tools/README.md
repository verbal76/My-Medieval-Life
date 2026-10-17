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
