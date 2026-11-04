"""Write game/data/overworld_tiles.json: the tile ids the game's overworld generator draws with.

The overworld (game/scripts/core/overworld.gd) is generated at run time, so it cannot read the
Tiled wangsets in the archives. This tool copies the few tables it needs, as tile values in the same
form as game/data/village.json (atlas * 100000 + tile id; atlas 0 = paid tileset, 1 = free overworld
tileset), so the game can draw with the atlases it already has. Nothing is drawn new:

  grass, cliff   the free PUNY_WORLD_v1 "overworld" corner wangset: the grass tiles, and for every
                 grass/cliff corner combination the transition tile (a raised, rock-rimmed plateau)
  chalk, dry     (B25R1-018) the same corner set's grass/sand and grass/dirt transitions: the Downs' chalk
                 patches and the waste's dry earth, for every corner combination
  dirt_path      the "pathways" edge wangset: the dirt road tile for each set of connected sides
  trees, sapling the (trunk, canopy top, canopy bottom) tree stamps and the sapling tile the village uses
  rock, flowers, bushes   single-tile objects of the paid tileset, identified visually
  water          B25R1-Q3: the stream tiles in game/assets/tiles/water_tiles.png (tools/water_tiles.py, the same free
                 tileset's grass/river corner set, waterfall, wooden walk and castle wall-walk): river[k] for water corners
                 k (bit 0 top-left, 1 top-right, 2 bottom-right, 3 bottom-left; [] where the set has no tile), cols (the
                 frames a row), looks and look_rows (EA-01: the tile of look v, flow f and corners k is
                 flow_base + (v * look_rows + f * 16 + k) * cols), fall, fall_foot, ford (stepping stones), bridge {plank_ns,
                 plank_ew, stone_ns, stone_ew, plank_n, plank_s, plank_w, plank_e}, as atlas 9 values (9 * 100000 + row * cols)

Run:  python3 tools/build_overworld_tiles.py
"""
import json

from assetzip import AssetZip, REPO
import puny_world_terrain as pwt
import water_tiles

OUT = REPO / "game" / "data" / "overworld_tiles.json"
VILLAGE = REPO / "game" / "data" / "village.json"
FREE = 100000
GRASS, CLIFF = 1, 4          # wangset colours in the free tileset's "overworld" corner set
DIRT, SAND = 2, 3            # B25R1-018: bare ground in the same corner set: sand drawn as the Downs' chalk, dirt as the waste's dry earth
# tree kinds by look (paid tileset, keyed by the canopy's bottom tile): a region can favour one group
TREE_GROUPS = {456: "leafy", 458: "autumn", 460: "conifer", 1120: "leafy", 1780: "mixed", 1782: "mixed"}
ROCK = 1964                  # a grey boulder (also the village's worked-out ore rock)
FLOWERS = [2657, 2658, 2659, 2656]   # PL1-12: the low red flower (2656) grows outside the village too (overworld GEN_VERSION 2)
BUSHES = [2661, 2663]
FORMAT = "mml-overworld-tiles/1"
WATER_ATLAS = 9 * 100000                 # MapView's water atlas (MapView.WATER_ATLAS) (game/assets/tiles/water_tiles.png; its layout: water_tiles.ROW)
WCOLS = water_tiles.FRAMES


def build():
    _, _, ids, tiles, paths = pwt.load(AssetZip(pwt.ZIP))
    assert ids["grass"] == GRASS and ids["cliff"] == CLIFF
    grass = sorted(tiles[(GRASS,) * 4])
    # corner combination index: bit 0 top-left, 1 top-right, 2 bottom-right, 3 bottom-left is cliff
    cliff = []
    for k in range(16):
        key = tuple(CLIFF if k >> b & 1 else GRASS for b in range(4))
        cliff.append(sorted(tiles[key]))
    # B25R1-018: grass with patches of chalk (sand) and of dry earth (dirt), indexed as the cliff corners
    soil = {}
    for name, colour in (("chalk", SAND), ("dry", DIRT)):
        soil[name] = []
        for k in range(16):
            key = tuple(colour if k >> b & 1 else GRASS for b in range(4))
            soil[name].append(sorted(tiles[key]))
    # connected sides: bit 0 north, 1 east, 2 south, 3 west (index 0, no side, has no tile)
    assert tuple(pwt.DIRS) == ((0, -1), (1, 0), (0, 1), (-1, 0)), pwt.DIRS   # N E S W
    path = []
    for k in range(16):
        key = tuple(bool(k >> b & 1) for b in range(4))
        path.append(sorted(paths["dirt"].get(key, [])))
    river_id = ids["river"]
    river = []
    for k in range(16):
        key = tuple(river_id if k >> b & 1 else GRASS for b in range(4))
        river.append([WATER_ATLAS + k * WCOLS] if k != 0 and tiles.get(key) else [])
    row = water_tiles.ROW
    water = {"river": river, "flow_base": WATER_ATLAS, "cols": WCOLS, "looks": water_tiles.LOOKS,
             "look_rows": water_tiles.FLOWS * 16, "fall": WATER_ATLAS + row["fall"] * WCOLS,
             "fall_foot": WATER_ATLAS + row["fall_foot"] * WCOLS, "ford": WATER_ATLAS + row["ford"] * WCOLS,
             "bridge": {k: WATER_ATLAS + row[k] * WCOLS for k in water_tiles.BRIDGE}}
    village = json.loads(VILLAGE.read_text())
    stamps = sorted({(t["trunk"], t["top"], t["bottom"]) for t in village["trees"]})
    trees = [{"trunk": a, "top": b, "bottom": c, "group": TREE_GROUPS[c]} for a, b, c in stamps]
    return {"format": FORMAT,
            "grass": [FREE + t for t in grass],
            "cliff": [[FREE + t for t in ts] for ts in cliff],
            "dirt_path": [[FREE + t for t in ts] for ts in path],
            "chalk": [[FREE + t for t in ts] for ts in soil["chalk"]],
            "dry": [[FREE + t for t in ts] for ts in soil["dry"]],
            "trees": trees, "sapling": village["tiles"]["sapling"], "rock": ROCK, "flowers": FLOWERS, "bushes": BUSHES,
            "water": water}


def main():
    data = build()
    OUT.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    print(f"wrote {OUT.relative_to(REPO)}: {len(data['grass'])} grass tiles, {len(data['trees'])} tree kinds")


if __name__ == "__main__":
    main()
