"""Build the playable village map for the Godot game (game/data/village.json).

Generator v6 (Build 8, owner decision 2026-10-19: one new FIXED village, the same in every game): the
village is laid out here, tile by tile, as one coherent settlement of 120 x 90 tiles (16 px). It is no
longer assembled from the twelve 30 x 30 districts of Shade's sample maps, whose terrain seams, cut-off
trees and loose patches showed in play.

What is laid out
    - the ground: one continuous layer of the free PUNY_WORLD_v1 corner wangset (grass; dirt yards for
      the market, the tavern's court, the smithy, the mine, the sawmill and the camp; a rocky hill for
      the mine), the same grass tiles the overworld (game/scripts/core/overworld.gd) draws round the
      village, so the village's edge meets it without a seam. Dirt roads are the wangset's "pathways";
      the four exits (north, east, south, west) are roads that run to the map's edge.
    - the buildings, stamped from Shade's sample maps (PUNY-WORLD-PAID_v1.zip) building by building, each
      with the floor under its roof, its walls, furniture and roof, but none of the sample's grass,
      dirt patches, trees or people: the small house (21 homes), the manor, the tavern with its terrace
      and well, the sage's hut and the smithy with its armory stay where Shade's samples put them
      relative to one another and keep their ids; the sawmill is a new workshop (the small house with the
      sawhorse of the smithy's carpenter's corner).
    - the market (six stalls), four fenced animal pens, six fields, two building plots, the mine (a hill
      cut by a timbered adit, a yard, a track that runs from the adit to the cart stop, and the ore
      seams), and the bandits' camp.
    - trees and plants. Trees are records only (village.json "trees": the trunk's cell and the old tile
      ids that fix the species); the game draws them as Living Forest sprites (game/scripts/view/tree_view.gd)
      and no tree tile is left in any tile layer. Wild flowers and berry bushes are the gatherable
      plants of generator v5.

Tall objects (the tops of tables, benches, racks and armour stands that Shade drew in his "Object Top"
layers) are put in "below" layers over their base (below3, below4): the player is drawn over them and
can never stand under half an object. A cell holding only the top of a taller object is solid.

Output (deterministic for a given seed; no random numbers are drawn from the global generator):
  game/data/village.json   tile layers, collision, and every gameplay entity: buildings with doors,
                           homes, workstations, trees, ore deposits, fields, stalls, build plots,
                           containers (crates, barrels, tavern tables), spawn points, and each
                           building's interior (floor, doors, roof cells, beds and other use spots;
                           see Village.interiors) with "roof_layers" naming the layers roofs are in
  game/assets/tiles/       the three tile atlases, copied from the archives (provenance in
                           game/assets/PROVENANCE.json, written by tools/import_game_assets.py)

Tile values: atlas * 100000 + tile id (atlas 0 = paid punyworld-tiles, 1 = free overworld tiles,
2 = Cozy Farm tiles), -1 = empty. Pens are fenced with Cozy Farm fence tiles; "woods" are the forest
patches where wild animals live.

Usage:
    python3 tools/build_village.py [--seed 1] [--preview out/village.png [--solid]]
"""
import argparse
import json
import math
import random
from pathlib import Path

from assetzip import AssetZip, REPO
import puny_world_terrain as pwt

PAID = "PUNY-WORLD-PAID_v1.zip"
SAMPLE = "PUNY-WORLD-PAID_v1/Tiled/sample-{}.tmj"
FREE = 100000           # atlas offset for the free overworld tiles
COZY = 2 * FREE         # atlas offset for the Cozy Farm tiles (fences, gates)
COZY_COLS = 54
CH = 30                 # a sample map is 30 x 30 tiles
W, H = 120, 90
OUT = REPO / "game" / "data" / "village.json"
SOUTH_X = 66            # where Mill Road leaves the map in the south (it jogs east below the south lane)

# The civic buildings keep the places they had when the village was made of Shade's districts: a sample's
# tile (x, y) lies at ORIGIN + (x, y), so the tavern, the manor, the smithy and their stations stay where
# they were relative to one another and to the player's start.
ORIGIN = {"village-1": (0, CH), "village-2": (2 * CH, CH), "village-3": (CH, CH)}

# --- atlas facts (tile ids in punyworld-tiles.png, 220 columns) -------------------------------
DOORS = {3875, 3799, 3801}                   # doors and archways: walkable
# generator v5: gatherable plants, paid-atlas tile values (0 * 100000 + id), identified visually
# (PL1-12: 2656 is the low red flower, 2659 the white one; both are wild flowers like the purple and yellow)
PLANTS = {2656: "flower", 2658: "flower", 2657: "flower", 2659: "flower", 2660: "redberry", 2662: "blueberry"}
PEOPLE_MIN = 126 * 220                       # rows 126+ hold the tiny people Shade drew into maps
ORE = {"iron_ore": 1966, "copper_ore": 1744, "coal": 1746, "stone": 1964, "gold_ore": 1965}
DEPLETED_ROCK = 1964
STUMP = 459
SAPLING = 4304
# Field art is a 4x4 edge set per state, named by its top-left tile: columns are narrow / left / middle
# / right, rows are top / middle / bottom / narrow, so a field of any size closes cleanly on all four
# sides (generator v5: v1-v4 drew one left-edge tile on every cell, so the right and bottom edges of
# every field showed half plants). Tilled = brown soil (215,15), growing = olive wheat (207,7),
# ripe = yellow wheat (207,11) in the paid atlas, which is 220 tiles wide.
PAID_COLS = 220
FIELD_TILES = {"tilled": 15 * PAID_COLS + 215, "growing": 7 * PAID_COLS + 207, "ripe": 11 * PAID_COLS + 207}


def field_cell_tile(base, w, h, i, j, cols=PAID_COLS):
    """Tile for cell (i, j) of a w x h field drawn from the 4x4 edge set starting at tile `base`."""
    col = 0 if w == 1 else 1 if i == 0 else 3 if i == w - 1 else 2
    row = 3 if h == 1 else 0 if j == 0 else 2 if j == h - 1 else 1
    return base + row * cols + col


FRAME = 3499                                 # wooden construction frame (build sites)
CAMPFIRE = 5958                              # animated in the tileset (5958-5961)
CRATE, BARREL = 3500, 3502
RAIL_V, RAIL_TOP, RAIL_END = 1083, 863, 1303  # the track: a straight rail, its top end and its bottom end
MINE_CART = 3009                             # the mine cart on its rail
ROCK_FILL = (16750, 16751, 16752, 16753, 16970, 16971, 16972, 16973, 17190, 17191, 17192, 17193, 17410, 17411, 17412, 17413)
ROCK_SLAB = (9286, 9287, 9288, 9289, 9726, 9727, 9728, 9729)   # grey cobbled stone, for the quarry's slabs
ROCK_LEDGE = (9499, 9500)                    # a dark rock lip along the lower half of the cell
ADIT = FREE + 154                            # the timbered mine mouth of the free tileset, over a cliff face
PLANKS = (1024, 1025)                        # piles of planks and logs (the smithy's carpenter's corner)
# Containers the player can take from (or steal from): the crate and barrel tiles Shade drew by the
# houses, in the tavern and at the stalls, and the dishes and mugs he drew on the tavern's tables
CRATE_TILES = {CRATE, 794, 796, 797, 1024, 1025}
BARREL_TILES = {BARREL, 358}
DISH_TILES = {798: "pottage", 583: "pottage", 799: "pottage", 800: "pottage", 803: "roast_meat",
              2121: "ale", 2122: "ale"}
# Cozy Farm tiles.png (54 columns): the wooden fence ring at columns 4-6, rows 29-31, and a closed gate
FENCE = {"tl": 29 * 54 + 4, "t": 29 * 54 + 5, "tr": 29 * 54 + 6, "l": 30 * 54 + 4, "r": 30 * 54 + 6,
         "bl": 31 * 54 + 4, "b": 31 * 54 + 5, "br": 31 * 54 + 6}
GATE = 29 * 54 + 0
PENS = ("cow", "pig", "sheep", "chicken")   # one fenced pen per kind of livestock


def is_tree_tile(t):
    """Tree art in the paid atlas: the crowns, trunks and stumps of columns 16-23, rows 0-11 (rows 12+
    hold the flowers and bushes). Generator v6 never copies one into a layer: trees are records."""
    return 16 <= t % 220 <= 23 and t // 220 <= 11


# --- interiors (generator v3) --------------------------------------------------------------------
# Every roofed building has an interior under its roof: Shade drew the rooms, walls and furniture of
# his houses and the manor under their roofs, and gave the tavern and the smithy roofs of their own
# (sample village-3 / -2, in a "Roof" group he left hidden). The game fades a roof while the player is
# under it (game/scripts/view/roof_fade.gd).
ROOF_LAYERS = ("above3", "above4", "above5")       # the "above" layers that hold roofs (faded, never canopies)
TOP_LAYERS = {"Object Top": 3, "Object Top Offset": 4}    # generator v6: tall objects' tops go to below3 / below4
# Beds Shade drew (the bed's body tile -> where its head lies); the bed's other tile is a headboard
BED_TILES = {1472: "up", 1477: "up", 1482: "up", 1691: "right", 1696: "right", 1701: "right",
             1693: "left", 1698: "left", 1703: "left"}
TABLE_TILES = {2539, 2540, 2542, 1887, 1888, 1889, 1890, 2547, 2548, 2549, 2550}
HEARTH_TILES = {2565, 2566, 2567, 2568}     # bread ovens / hearths
CHEST_TILES = {355}
KITCHEN_CELL = (52, 47)                     # a cell of the tavern's open-air kitchen (stove area)
MAT = 593                                   # a straw pallet: a sleeping place on the floor (walkable)
SLEEP_PLACES = 6                            # beds plus pallets in every home
HOME_TYPES = ("house", "manor", "tavern", "hut")
# Beds added to the big homes so the family sleeps in beds (owner: villagers with homes sleep in their
# own beds; straw pallets are for guards and cooks). (body, foot post) tiles of Shade's beds, head left.
# The tavern has no room for more beds outside its dining hall: its keepers take Shade's two inn beds.
EXTRA_BEDS = {"manor": 2}
ADDED_BED_TILES = ((1693, 1694), (1698, 1699))
HUT_BOX = 3222                              # the box Shade drew in the sage's hut's only inner cell
# Beds for Shade's small house (local cells; (body, foot post) tiles): four along the west wall, head to
# the wall, where his straw mat, shelf and jars stood, and one by the east wall. Colours alternate.
HOUSE_CLEAR = ((1, 4), (2, 4), (1, 6), (2, 6), (1, 7), (2, 7))
HOUSE_BEDS = (((1, 4), (2, 4), 1693, 1694), ((1, 5), (2, 5), 1698, 1699), ((1, 6), (2, 6), 1703, 1704),
              ((1, 7), (2, 7), 1693, 1694), ((7, 5), (6, 5), 1696, 1695))

# --- the building stamps (sample, rect (x, y, w, h) in the sample's tiles) ------------------------
HOUSE_RECT = (2, 10, 9, 10)                 # Shade's small house, village-1: 9 x 10, door step at (4, 9)
MANOR_RECT = (14, 6, 15, 18)                # the manor and its fenced garden, village-1
TAVERN_RECT = (4, 8, 23, 18)                # the tavern, its terrace and the well, village-3
HUT_RECT = (9, 1, 4, 3)                     # the sage's hut and its barrels, village-3
SMITHY_RECT = (7, 10, 16, 14)               # the smithy and the armory, village-2

# --- workshop stamps (property phase 2, agent proposal) -------------------------------------------
# A workshop is Shade's small house (the house stamp: walls, roof, door, chest and tables) with its beds
# and straw pallet taken out and the stations of his smithy (village-2) or tavern kitchen (village-3)
# moved in, tile for tile, from where he drew them in this village: (local cell, source cell) pairs,
# copied in the named layers. Nothing is drawn new. Each station records its object cell and the floor
# cell it is used from. A workshop has no hearth spot (it is not a home).
WORK_LAYERS = ("below1", "below2", "below3", "below4", "above0", "above1")
WORKSHOPS = {
    "smithy": {"stations": [
        {"type": "forge", "at": (5, 2), "use": (5, 3), "layers": WORK_LAYERS,
         "paste": (((5, 1), (76, 40)), ((6, 1), (77, 40)), ((5, 2), (76, 41)), ((6, 2), (77, 41)))},
        {"type": "anvil", "at": (1, 5), "use": (3, 5), "layers": WORK_LAYERS,
         "paste": (((1, 5), (77, 43)), ((2, 5), (78, 43)))},
    ]},
    "carpentry": {"stations": [
        {"type": "workbench", "at": (1, 4), "use": (3, 4), "layers": WORK_LAYERS,
         "paste": (((1, 4), (79, 47)), ((2, 4), (80, 47)))},
        {"type": "sawhorse", "at": (2, 6), "use": (3, 6), "layers": ("below1", "below3"),
         "paste": (((1, 6), (65, 26)), ((2, 6), (66, 26)))},       # the sawmill's sawhorse (PL2-010), once built
        {"type": "", "layers": WORK_LAYERS, "paste": (((1, 7), (79, 45)), ((2, 7), (80, 45)))},   # grindstone
    ]},
    "bakehouse": {"stations": [
        {"type": "oven", "at": (5, 2), "use": (5, 3), "layers": WORK_LAYERS,
         "paste": (((5, 1), (54, 46)), ((6, 1), (55, 46)), ((5, 2), (54, 47)), ((6, 2), (55, 47)))},
        {"type": "stove", "at": (2, 5), "use": (3, 5), "layers": WORK_LAYERS,
         "paste": (((1, 5), (51, 47)), ((2, 5), (52, 47)), ((1, 6), (53, 47)))},       # the stone coal bed with the pot (PL1-13)
    ]},
    # Property modules (PL2-014): rooms that are added to a property over time. The kitchen and the
    # apothecary are the bakehouse's coal bed and pot (the stove) on their own, the apothecary's at the
    # far corner; storage is the bare room (its chest and tables stay). Living quarters are the house
    # stamp itself (its beds). Nothing is drawn new.
    "kitchen": {"stations": [
        {"type": "stove", "at": (2, 5), "use": (3, 5), "layers": WORK_LAYERS,
         "paste": (((1, 5), (51, 47)), ((2, 5), (52, 47)), ((1, 6), (53, 47)))},
    ]},
    "apothecary": {"stations": [
        {"type": "stove", "at": (2, 6), "use": (3, 6), "layers": WORK_LAYERS,
         "paste": (((1, 6), (51, 47)), ((2, 6), (52, 47)), ((1, 7), (53, 47)))},
    ]},
    "storage": {"stations": []},
}
# The sawmill is the small house fitted as the carpenter's corner but for the workbench, so the village
# keeps one workbench (the smithy's) and the sawhorse is where the planks are sawn.
SAWMILL_STATIONS = (WORKSHOPS["carpentry"]["stations"][1], WORKSHOPS["carpentry"]["stations"][2])

# --- the small room (HOUSE-10, owner OD-14, 2026-10-20: a bedroom-sized addition that fits the grid) --------
# Shade's small house taken in to 5 x 6: its outer columns and the door's (gable, ridge, walls, door) and
# its top and bottom rows (roof peak, back wall, the last two rows of the room, eaves, front wall, porch).
# Inside, the furniture is cleared and two of his beds stand: one head to the west wall, one head to the
# back wall (its headboard over the wall, as he drew that bed), leaving a floor from the door to both.
ROOM_COLS = (0, 1, 4, 7, 8)                 # house columns kept, west to east (4 is the door's)
ROOM_ROWS = (0, 1, 6, 7, 8, 9)              # house rows kept, north to south (8 is the front wall)
ROOM_BEDS = (((1, 2), (2, 2), 1698, 1699, "left"), ((3, 2), (3, 1), 1477, 1257, "up"))   # body, head or post


def room_stamp(house):
    """The small room's stamp, cut from the house stamp (ROOM_COLS x ROOM_ROWS) with its beds
    (ROOM_BEDS). Reads only the house stamp, draws no random numbers, draws nothing new."""
    hw = house["w"]
    w, h = len(ROOM_COLS), len(ROOM_ROWS)
    cells = [(x, y, hx, hy) for y, hy in enumerate(ROOM_ROWS) for x, hx in enumerate(ROOM_COLS)]
    layers = {}
    for name, data in house["layers"].items():
        layers[name] = [data[hy * hw + hx] for _, _, hx, hy in cells]
    solid = [[house["solid"][hy][hx] for hx in ROOM_COLS] for hy in ROOM_ROWS]
    room = [(x, y) for y in (2, 3) for x in (1, 2, 3)]            # inside, the last two rows of the house
    for x, y in room:
        for name in list(layers):
            v = layers[name][y * w + x]
            if (name != "below0" or v == tile_val(0, MAT)) and name not in ROOF_LAYERS and not name.startswith(("path", "ground")):
                layers[name][y * w + x] = -1
        solid[y][x] = "0"
    spots = []
    for (bx, by), (px, py), body, other, head in ROOM_BEDS:
        layers["below1"][by * w + bx] = tile_val(0, body)
        layers["below1" if head != "up" else "below3"][py * w + px] = tile_val(0, other)
        solid[by][bx] = "1"
        solid[py][px] = "1"
        spots.append({"kind": "bed", "at": [bx, by], "use": [bx, 3], "head": head, "tile": body})
    door = (ROOM_COLS.index(4), ROOM_ROWS.index(8))
    area = sorted(room + [door])
    floor = sorted(c for c in area if solid[c[1]][c[0]] == "0")
    roof = [[x, y] for x in range(w) for y in range(h - 1)]
    interior = {"doors": [list(door)], "area": [list(c) for c in area], "floor": [list(c) for c in floor],
                "roof": roof, "spots": spots}
    return {"w": w, "h": h, "door": [door[0], door[1] + 1], "layers": {k: layers[k] for k in sorted(layers)},
            "interior": interior, "solid": ["".join(r) for r in solid]}

CATS = ("ground", "path", "below", "above")
TOPS = [("above", i) for i in range(6)] + [("below", 3), ("below", 4)]     # layers whose tiles cover an object


def tile_val(atlas, tid):
    return atlas * FREE + tid


# ---- deterministic noise (integers in, floats out: the same on every machine) ---------------------
def _hash(x, y, salt):
    h = (x * 374761393 + y * 668265263 + salt * 2246822519 + 12345) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h ^= h >> 16
    return h / 4294967296.0


def vnoise(x, y, period, salt):
    """Smooth value noise in 0..1, lattice `period` tiles apart."""
    gx, gy = x / period, y / period
    ix, iy = math.floor(gx), math.floor(gy)
    fx, fy = gx - ix, gy - iy
    sx, sy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = _hash(ix, iy, salt), _hash(ix + 1, iy, salt)
    c, d = _hash(ix, iy + 1, salt), _hash(ix + 1, iy + 1, salt)
    top, bot = a + (b - a) * sx, c + (d - c) * sx
    return top + (bot - top) * sy


def road_cells(*points):
    """The 4-connected cells of a road through axis-aligned `points` (each leg horizontal or vertical)."""
    out = []
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        assert x0 == x1 or y0 == y1, "a road leg is straight"
        for x in range(min(x0, x1), max(x0, x1) + 1):
            for y in range(min(y0, y1), max(y0, y1) + 1):
                out.append((x, y))
    return out


class Village:
    def __init__(self, seed):
        self.rng = random.Random(seed)
        self.seed = seed
        self.layers = {}            # (cat, index) -> list
        self.walkable_override = set()
        self.decor = set()          # cells whose only object is 1x1 decor (walkable)
        self.roof = set()           # cells under a roof (solid)
        self.walls = set()          # cells holding a wall tile (Shade's "Wall" layers)
        self.late_roof = set()      # roof cells of the hidden roofs (the tavern's and the smithy's)
        self.floor = set()          # walkable interior floor (interiors())
        self.hill = set()           # cells of the mine's hill: solid rock
        self.road = set()
        self.yard = set()           # cells all of whose corners are dirt: no road tile is drawn there
        self.keep = set()           # cells no tree's trunk or crown may cover (set by place_trees)
        self.ents = {"buildings": [], "stations": [], "trees": [], "deposits": [], "fields": [],
                     "stalls": [], "plots": [], "pens": [], "woods": [], "spawns": {}, "mine": None,
                     "containers": []}
        self.free = pwt.load(AssetZip(pwt.ZIP))
        _, _, ids, self.wang, self.paths = self.free
        self.GRASS, self.DIRT, self.CLIFF = ids["grass"], ids["dirt"], ids["cliff"]
        self.corner = [[self.GRASS] * (W + 1) for _ in range(H + 1)]
        self.paid = AssetZip(PAID)
        self.samples = {}
        self.named_cache = {}
        self.foot_cache = {}

    # ---- layers -----------------------------------------------------------------------------
    def layer(self, cat, i):
        key = (cat, i)
        if key not in self.layers:
            self.layers[key] = [-1] * (W * H)
        return self.layers[key]

    def put(self, cat, i, x, y, val):
        if 0 <= x < W and 0 <= y < H:
            self.layer(cat, i)[y * W + x] = val

    def get(self, cat, i, x, y):
        key = (cat, i)
        return self.layers[key][y * W + x] if key in self.layers else -1

    def has_object(self, x, y):
        return any(v[y * W + x] >= 0 for (c, _), v in self.layers.items() if c in ("below",))

    # ---- sample maps ------------------------------------------------------------------------
    def sample(self, name):
        """The visible tile layers of a sample map: [(layer path, data)] (hidden groups left out)."""
        if name not in self.samples:
            d = json.loads(self.paid.text(SAMPLE.format(name)))
            out = []

            def walk(ls, prefix="", vis=True):
                for lay in ls:
                    v = vis and lay.get("visible", True)
                    if lay["type"] == "group":
                        walk(lay["layers"], prefix + lay["name"] + "/", v)
                    elif lay["type"] == "tilelayer" and v:
                        out.append((prefix + lay["name"], [(g & 0x1FFFFFFF) - 1 for g in lay["data"]]))
            walk(d["layers"])
            self.samples[name] = out
        return self.samples[name]

    @staticmethod
    def category(layer_name):
        n = layer_name.split("/")[-1]
        if "Grass" in n or n.startswith("Ground") or n == "Dirt" or n.startswith("Floor") or n == "Roof":
            return "ground"
        if "Top" in n or "Roof" in layer_name:
            return "above"
        return "below"

    def named(self, name):
        """A sample's visible layers as [(cat, index, layer path, data, source cat)]: the layer a tile goes
        to in the village. Indices count in the sample's layer order per category, as in generators v1-v5
        (so the roofs stay in above3 / above4); the tree layer is dropped. The tops of objects ("Object Top",
        "Object Top Offset") have the category "top": stamp() puts each in below3 / below4 or leaves it in
        its above layer, by what stands under it (generator v6)."""
        if name not in self.named_cache:
            counters = {c: 0 for c in CATS}
            out = []
            for lname, data in self.sample(name):
                cat = self.category(lname)
                idx = counters[cat]
                counters[cat] += 1
                base = lname.split("/")[-1]
                if base == "Tree Top":
                    continue
                if base in TOP_LAYERS:
                    out.append(("top", idx, lname, data, cat))
                else:
                    out.append((cat, idx, lname, data, cat))
            self.named_cache[name] = out
        return self.named_cache[name]

    def footprint(self, name):
        """The sample cells under a building's roof (visible or hidden), where its own floor is drawn."""
        if name not in self.foot_cache:
            cells = set()
            for lname, data in self.sample(name):
                if "Roof" in lname:
                    cells |= {(i % 30, i // 30) for i, t in enumerate(data) if 0 <= t < PEOPLE_MIN}
            d = json.loads(self.paid.text(SAMPLE.format(name)))
            for g in d["layers"]:
                if g["type"] == "group" and g["name"] == "Roof":
                    for lay in [l for l in g["layers"] if l["type"] == "tilelayer"][:2]:
                        cells |= {(i % 30, i // 30) for i, v in enumerate(lay["data"])
                                  if 0 <= (v & 0x1FFFFFFF) - 1 < PEOPLE_MIN}
            self.foot_cache[name] = cells
        return self.foot_cache[name]

    def stamp(self, name, rect, ox, oy, hidden_roof=False):
        """Copy a building of a sample map to (ox, oy): everything in `rect` except the sample's grass,
        dirt patches, trees and people. Ground tiles (the floors) only under the building's roof; the
        village's own wang ground is everywhere else. Records roofs, walls, doorways and 1x1 decorations
        for the collision pass."""
        rx, ry, rw, rh = rect
        foot = self.footprint(name)
        objs = {}
        tops = []
        for cat, idx, lname, data, src in self.named(name):
            base = lname.split("/")[-1]
            roof = "Roof" in lname
            for y in range(rh):
                for x in range(rw):
                    sx, sy = rx + x, ry + y
                    t = data[sy * 30 + sx]
                    if t < 0 or t >= PEOPLE_MIN:
                        continue
                    X, Y = ox + x, oy + y
                    if cat == "ground":
                        # the sample's floor goes over the village's wang ground (ground0), in ground1+
                        if (sx, sy) not in foot:
                            continue
                        self.put(cat, idx + 1, X, Y, tile_val(0, t))
                        continue
                    elif is_tree_tile(t):
                        continue
                    if cat == "top":
                        tops.append((idx, TOP_LAYERS[base], X, Y, t))
                        continue
                    self.put(cat, idx, X, Y, tile_val(0, t))
                    if roof:
                        self.roof.add((X, Y))
                    if src == "below":
                        objs.setdefault((x, y), []).append(t)
                        if "Wall" in base:
                            self.walls.add((X, Y))
                        if t in DOORS:
                            self.walkable_override.add((X, Y))
        if hidden_roof:
            self.hidden_roof(name, rect, ox, oy)
        for idx, below_idx, X, Y, t in tops:
            self.put_top(idx, below_idx, X, Y, tile_val(0, t))
        # 1x1 objects with nothing around them and nothing on top are decorations (flowers, rocks)
        for (x, y), ts in objs.items():
            X, Y = ox + x, oy + y
            alone = all((x + dx, y + dy) not in objs for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            top = any(self.get(c, i, X, Y - d) >= 0 for d in (0, 1) for c, i in TOPS)
            if alone and not top and len(ts) == 1:
                self.decor.add((X, Y))

    def base_at(self, x, y):
        """Whether a cell holds an object of its own (not the top of one)."""
        return any(self.get("below", i, x, y) >= 0 for i in (0, 1, 2, 5))

    def put_top(self, idx, below_idx, x, y, val):
        """The top of an object (Shade's "Object Top" layers): drawn under the characters, over its base, when a
        base stands in the cell (the items on a table, bench or shelf) or directly south of it (the top half
        of a rack or an armour stand); then no one can stand under half an object, and a cell holding only
        a top is solid like the base below it. Over a doorway or an open passage it stays over the
        characters (a lintel, a hanging): they walk under it."""
        door = (x, y) in self.walkable_override
        if not door and (self.base_at(x, y) or (self.base_at(x, y + 1) and (x, y + 1) not in self.walls
                                                and (x, y + 1) not in self.walkable_override)):
            self.put("below", below_idx, x, y, val)
        else:
            self.put("above", idx, x, y, val)

    def hidden_roof(self, name, rect, ox, oy):
        """The roof group Shade drew for a sample map but left hidden in Tiled, inside `rect`: its first
        layer (the roof itself) into above3, its roof objects (chimneys, dormers) into above4 and its
        fence into above5."""
        rx, ry, rw, rh = rect
        d = json.loads(self.paid.text(SAMPLE.format(name)))
        group = next(g for g in d["layers"] if g["type"] == "group" and g["name"] == "Roof")
        for j, lay in enumerate(l for l in group["layers"] if l["type"] == "tilelayer"):
            for y in range(rh):
                for x in range(rw):
                    t = (lay["data"][(ry + y) * 30 + rx + x] & 0x1FFFFFFF) - 1
                    if t < 0 or t >= PEOPLE_MIN:
                        continue
                    target = 3 + min(j, 2)
                    assert self.get("above", target, ox + x, oy + y) < 0, f"roof tile over another at {(ox + x, oy + y)}"
                    self.put("above", target, ox + x, oy + y, tile_val(0, t))
                    self.late_roof.add((ox + x, oy + y))

    def canopy_pairs(self):
        """(top, bottom) canopy tiles of Shade's two-tile trees, from sample village 1's Tree Top
        layer: two stacked tiles where the bottom is the atlas tile directly under the top."""
        tops = dict(self.sample("village-1"))["Tree Top"]
        pairs = set()
        for y in range(1, 30):
            for x in range(30):
                a, b = tops[(y - 1) * 30 + x], tops[y * 30 + x]
                if a >= 0 and b == a + 220:
                    pairs.add((a, b))
        return sorted(pairs)

    def tree_stamps(self):
        """(stump, top, bottom) trees from sample village 1. Shade draws a tree as two canopy tiles in
        the Tree Top layer (the bottom one holds the trunk) over a stump in the Objects layer: the
        stump cell is the trunk, and is the tree's only solid cell. The game takes the species from the
        tiles (World._tree_species); the tiles themselves are never drawn."""
        layers = dict(self.sample("village-1"))
        objs, tops = layers["Objects"], layers["Tree Top"]
        canopy = set(self.canopy_pairs())
        stamps = set()
        for y in range(1, 30):
            for x in range(30):
                top, bottom, stump = tops[(y - 1) * 30 + x], tops[y * 30 + x], objs[y * 30 + x]
                if stump >= 0 and (top, bottom) in canopy and objs[(y - 1) * 30 + x] < 0:
                    stamps.add((stump, top, bottom))
        return sorted(stamps)

    # ---- ground (the free tileset's corner wangset) ------------------------------------------
    def blob(self, cx, cy, rx, ry, terrain, salt, wobble=0.16, power=2.0):
        """Set the corners inside an irregular, rounded shape (an ellipse, or with a high `power` a
        rounded rectangle) to `terrain`."""
        for y in range(int(cy - ry) - 3, int(cy + ry) + 4):
            for x in range(int(cx - rx) - 3, int(cx + rx) + 4):
                if not (0 <= x <= W and 0 <= y <= H):
                    continue
                d = (abs((x - cx) / rx) ** power + abs((y - cy) / ry) ** power) ** (1 / power)
                if d + (vnoise(x, y, 4, salt) - 0.5) * wobble * 2 <= 1.0:
                    self.corner[y][x] = terrain

    def dirt(self, x0, y0, x1, y1, salt, power=4.0):
        """A dirt yard over the cells x0..x1, y0..y1: a rounded rectangle with a wobbling edge."""
        self.blob((x0 + x1 + 1) / 2, (y0 + y1 + 1) / 2, (x1 - x0 + 1) / 2 + 0.5, (y1 - y0 + 1) / 2 + 0.5,
                  self.DIRT, salt, power=power)

    def grass_corners(self, x0, y0, x1, y1):
        for y in range(y0, y1 + 2):
            for x in range(x0, x1 + 2):
                self.corner[y][x] = self.GRASS

    def paint_ground(self):
        """The ground layer: one wang tile per cell from its four corners (grass, dirt or cliff)."""
        for y in range(H):
            for x in range(W):
                key = (self.corner[y][x], self.corner[y][x + 1], self.corner[y + 1][x + 1], self.corner[y + 1][x])
                assert not (self.CLIFF in key and self.DIRT in key), f"cliff meets dirt at {(x, y)}"
                self.put("ground", 0, x, y, tile_val(1, self.rng.choice(sorted(self.wang[key]))))
                if key == (self.DIRT,) * 4:
                    self.yard.add((x, y))
                if self.CLIFF in key:
                    self.hill.add((x, y))

    # ---- buildings --------------------------------------------------------------------------
    def building(self, kind, x, y, w, h, door, **extra):
        b = {"id": f"b{len(self.ents['buildings'])}", "type": kind, "x": x, "y": y, "w": w, "h": h,
             "door": list(door), **extra}
        self.ents["buildings"].append(b)
        return b

    def civic(self, sample, rect, hidden_roof=False):
        """Stamp a civic building of a sample at the place its sample put it (ORIGIN + the rect's corner)."""
        ox, oy = ORIGIN[sample][0] + rect[0], ORIGIN[sample][1] + rect[1]
        self.stamp(sample, rect, ox, oy, hidden_roof)
        return ox, oy

    def house(self, ox, oy, kind="house", **extra):
        """Shade's small house from sample village 1 (9 x 10 tiles, door step at (4, 9))."""
        self.stamp("village-1", HOUSE_RECT, ox, oy)
        b = self.building(kind, ox, oy, 9, 10, (ox + 4, oy + 9), **extra)
        self.walkable_override.add((ox + 4, oy + 8))
        return b

    def station(self, kind, use, building=None, at=None):
        self.ents["stations"].append({"id": f"s{len(self.ents['stations'])}", "type": kind,
                                      "use": list(use), "at": list(at or use), "building": building})

    # ---- the layout --------------------------------------------------------------------------
    def build(self):
        self.trees = self.tree_stamps()
        E = self.ents

        # --- civic buildings, where Shade's samples put them (ids as before) ---------------------
        self.civic("village-1", HOUSE_RECT)
        E["buildings"].append({"id": "b_v1_house", "type": "house", "x": 2, "y": CH + 10, "w": 9, "h": 10,
                               "door": [6, CH + 19]})
        self.walkable_override.add((6, CH + 18))
        self.civic("village-1", MANOR_RECT)
        E["buildings"].append({"id": "b_manor", "type": "manor", "x": 14, "y": CH + 6, "w": 15, "h": 18,
                               "door": [23, CH + 22]})
        self.civic("village-3", TAVERN_RECT, hidden_roof=True)
        self.building("tavern", 34, 38, 23, 14, (38, 52), name="The Well House")                      # b2
        self.civic("village-3", HUT_RECT, hidden_roof=True)
        self.building("hut", 39, 31, 3, 3, (40, 34), name="Sage's hut")                               # b3
        self.civic("village-2", SMITHY_RECT, hidden_roof=True)
        self.building("smithy", 67, 40, 16, 14, (71, 54), name="Smithy and Armory")                   # b4

        # --- houses: 20 more of Shade's small house along the lanes (b5-b24) ----------------------
        # (lane row, y offset of the row's houses above it, xs): a house stands 10 rows above its lane,
        # so its door step (4, 9) is next to the lane; some stand a row higher and have a longer path
        rows = [(43, (90, 100, 110), (-1, 2)), (57, (90, 100, 110), (-1, 2)),     # east houses, b5-b10
                (71, (1, 11, 21), (0, 2)), (85, (1, 11, 21), (0, 2)),             # west houses, b11-b16
                (71, (90, 100, 110), (-1, 2)), (85, (90, 100, 110), (-1, 2))]     # south-east houses, b17-b22
        self.lanes = []
        for lane, xs, (lo, hi) in rows:
            # x shifts never decrease along a row, so neighbours keep a gap; y shifts give some a longer path
            dxs = sorted(lo + int(_hash(i, lane, 3) * (hi - lo)) for i in range(len(xs)))
            for x, dx in zip(xs, dxs):
                oy = lane - 10 - int(_hash(x, lane, 4) * 2)
                self.house(x + dx, oy)
                self.lanes.append(road_cells((x + dx + 4, oy + 9), (x + dx + 4, lane)))
        for x, lane in ((2, 35), (16, 35)):                             # b23, b24: the north-west hamlet
            oy = lane - 10
            self.house(x, oy)
            self.lanes.append(road_cells((x + 4, oy + 9), (x + 4, lane)))
        sawmill = self.sawmill(64, 20)
        self.lanes.append(road_cells((68, 29), (68, 30)))

        # --- roads ------------------------------------------------------------------------------
        self.roads()
        # --- ground: dirt yards, the mine's hill ----------------------------------------------------
        self.yards()
        self.mine_hill()
        self.paint_ground()
        self.rock_top()

        # --- things on the ground ---------------------------------------------------------------
        E["mine"] = self.mine()
        self.stations(sawmill)
        self.market(36, 63)
        for i, kind in enumerate(PENS):
            self.pen(kind, 33 + i * 7, 76, 7, 6)
        for j in range(3):
            for i in range(2):
                self.field(64 + i * 13, 61 + j * 9, 11, 6)
        self.camp(104, 13)
        self.plots(((90, 20), (107, 20)))
        E["woods"] = [{"id": "woods_w", "x": 1, "y": 1, "w": 28, "h": 22},
                      {"id": "woods_e", "x": 66, "y": 1, "w": 24, "h": 17}]
        E["spawns"]["player"] = [44, 53]
        self.place_trees()
        self.place_boulders()
        self.place_plants()
        self.draw_roads()
        self.containers()
        self.interiors()
        return self

    # ---- roads and yards ---------------------------------------------------------------------
    def roads(self):
        """The road network, laid out by hand: Main Street east-west and Mill Road north-south cross at the
        village's heart and run out to the map's edge (the four exits); lanes serve the houses, the market,
        the pens and the fields; the Woods Road runs north to the woodcutters' clearing; the Mine Road
        and the Quarry Link join the mine's yard."""
        r = set()
        for pts in (
            ((0, 57), (119, 57)),                        # Main Street: the west and east exits
            ((62, 0), (62, 86), (SOUTH_X, 86), (SOUTH_X, 89)),   # Mill Road: the north and south exits
            ((31, 24), (31, 85)),                        # Woods Road, and the way south to the lanes
            ((2, 35), (52, 35)),                         # the north lane: hamlet, sage's hut, tavern's back door, Mine Road
            ((38, 35), (38, 37)),
            ((40, 34), (40, 35)),
            ((52, 35), (52, 14)),                        # Mine Road
            ((52, 20), (62, 20)),                        # Quarry Link
            ((62, 30), (68, 30)),                        # the sawmill's lane
            ((2, 71), (33, 71)), ((2, 85), (118, 85)),   # the west lane, the south lane
            ((88, 30), (88, 85)),                        # the east connector
            ((88, 30), (118, 30)), ((88, 43), (118, 43)), ((88, 71), (118, 71)),
            ((94, 29), (94, 30)), ((111, 29), (111, 30)),   # the building plots' door steps
            ((31, 75), (62, 75)),                        # the pens' lane
            ((75, 57), (75, 85)),                        # between the fields
            ((62, 68), (88, 68)), ((62, 77), (88, 77)),
            ((6, 49), (6, 57)), ((23, 52), (23, 57)),    # the old house, the manor
            ((38, 52), (38, 57)), ((71, 54), (71, 57)),  # the tavern, the smithy
        ):
            r.update(road_cells(*pts))
        for cells in self.lanes:
            r.update(cells)
        self.road = r

    def yards(self):
        """Dirt yards of the free tileset's dirt terrain: round the tavern, in its court, the market, the
        crossing, the smithy, the sawmill, the mine and the woodcutters' clearing and the bandits' camp."""
        self.dirt(34, 52, 55, 57, 11, power=3.0)         # the tavern's yard and terrace, Main Street's west side
        self.dirt(43, 47, 47, 51, 12)                    # the tavern's inner court (open to the south)
        self.dirt(58, 53, 66, 61, 13, power=2.5)         # the crossing: Mill Road and Main Street
        self.dirt(68, 54, 82, 57, 14, power=3.0)         # the smithy's yard
        self.dirt(35, 60, 59, 68, 15, power=3.0)         # the market
        self.dirt(63, 24, 74, 31, 16, power=3.0)         # the sawmill's yard
        self.dirt(37, 12, 61, 23, 17, power=3.0)         # the mine's yard
        self.dirt(27, 20, 34, 25, 18, power=2.5)         # the woodcutters' clearing, end of the Woods Road
        self.blob(104, 13, 7, 5.5, self.DIRT, 19)        # the bandits' camp
        # two flower beds on the market's edge: grass islands in the dirt
        for cx, cy in ((41, 66), (55, 66)):
            self.blob(cx, cy, 2.2, 1.6, self.GRASS, 20 + cx)

    def mine_hill(self):
        """The mine's hill: a plateau of the free tileset's cliff terrain (a raised, rock-rimmed top; solid,
        the same rock as the overworld's mountains) with the timbered adit cut into its south face."""
        rows = {3: (45, 53), 4: (42, 56), 5: (40, 58), 6: (39, 59), 7: (39, 59), 8: (40, 58), 9: (42, 56)}
        for y, (a, b) in rows.items():
            for x in range(a, b + 1):
                self.corner[y][x] = self.CLIFF
        for y in (10, 11):                               # a strip of grass between the rock face and the yard
            for x in range(36, 63):
                if self.corner[y][x] == self.DIRT:
                    self.corner[y][x] = self.GRASS
        self.adit = (48, 9)                              # the face cell the adit is drawn over
        self.put("below", 2, self.adit[0], self.adit[1], ADIT)

    def rock_top(self):
        """B8-004: the hill's top is bare rock, not the grass of the free tileset's plateau: Shade's rock ground
        (PUNY-WORLD-PAID, the grey-brown stone of his sample overworld's mountain) over every cell whose four
        corners are cliff, in ground1, a few cells with cracks."""
        top = set()
        for y in range(H):
            for x in range(W):
                if all(c == self.CLIFF for c in (self.corner[y][x], self.corner[y][x + 1],
                                                  self.corner[y + 1][x], self.corner[y + 1][x + 1])):
                    top.add((x, y))
        for x, y in sorted(top):
            fill = ROCK_SLAB if vnoise(x, y, 3, 62) > 0.66 else ROCK_FILL
            self.put("ground", 1, x, y, tile_val(0, fill[int(_hash(x, y, 61) * len(fill)) % len(fill)]))
        for y in (5, 7):                    # two quarry ledges: a dark lip along the rock's terraces, in pieces
            run = [x for x in range(W) if (x, y) in top and (x, y - 1) in top and (x, y + 1) in top]
            for x in run:
                if vnoise(x, y, 6, 63) > 0.3 and abs(x - self.adit[0]) > 1:
                    self.put("ground", 1, x, y, tile_val(0, ROCK_LEDGE[(x + y) % 2]))

    # ---- the mine ----------------------------------------------------------------------------
    def mine(self):
        """The track runs from the adit's mouth south to the cart stop in the yard: rail, then the cart
        standing on it, then the rail's end. Ore seams lie on the yard, each reachable on foot."""
        x = self.adit[0]
        for y in range(10, 19):
            self.put("below", 2, x, y, tile_val(0, RAIL_TOP if y == 10 else RAIL_END if y == 18 else RAIL_V))
            self.decor.add((x, y))
        self.put("below", 3, x, 16, tile_val(0, MINE_CART))      # the cart on its rail
        self.decor.discard((x, 16))
        self.cart = (x, 16)
        # crates and barrels of the mine's stores by the adit
        for cx, cy, t in ((44, 12, CRATE), (45, 12, CRATE), (44, 13, BARREL), (53, 12, BARREL), (54, 12, CRATE)):
            self.put("below", 1, cx, cy, tile_val(0, t))
        self.place_deposits()
        return {"entrance": [x, 10], "yard": [51, 21]}

    def place_deposits(self):
        """Ore rocks on the mine's yard, in two seams either side of the track: only cells with grass-free
        dirt all round, off the track and the roads, at least three apart and each with three open
        neighbours, so every one can be reached on foot."""
        rng = self.rng
        cands = []
        for y in range(13, 25):
            for x in range(37, 60):
                c = (x, y)
                if (x, y) not in self.yard or not all(n in self.yard for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                    continue
                if abs(x - self.adit[0]) <= 2 or c in self.road or any(n in self.road for n in ((x + 1, y + 1), (x - 1, y - 1), (x - 1, y + 1), (x + 1, y - 1))):
                    continue
                if self.has_object(x, y) or any(self.has_object(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    continue
                cands.append(c)
        rng.shuffle(cands)
        # Generator v7 (Build 13): the gold seam comes last, so the first fourteen seams stay where v6 put them.
        plan = ["iron_ore", "coal", "stone", "iron_ore", "copper_ore", "coal", "iron_ore", "stone",
                "iron_ore", "coal", "stone", "iron_ore", "copper_ore", "coal", "gold_ore"]
        taken = []
        for ore in plan:
            for c in cands:
                if all(abs(c[0] - t[0]) + abs(c[1] - t[1]) >= 3 for t in taken):
                    taken.append(c)
                    cands.remove(c)
                    self.put("below", 0, c[0], c[1], tile_val(0, ORE[ore]))
                    self.ents["deposits"].append({"x": c[0], "y": c[1], "ore": ore,
                                                  "amount": {"gold_ore": 8, "stone": 80, "coal": 50,
                                                             "copper_ore": 30}.get(ore, 60)})
                    break
        assert len(self.ents["deposits"]) == len(plan), "not enough room for the ore seams"

    # ---- the sawmill -------------------------------------------------------------------------
    def sawmill(self, ox, oy):
        """The sawmill: the small house fitted for sawing (the sawhorse and grindstone of Shade's carpenter's
        corner), its door facing the sawmill's lane, planks and logs piled in its yard."""
        b = self.house(ox, oy, "sawmill", name="Sawmill")
        for x, y in HOUSE_CLEAR:
            for cat, i in (("below", 1), ("below", 3), ("below", 4), ("above", 0), ("above", 1)):
                self.put(cat, i, ox + x, oy + y, -1)
        # PL2-010: Shade's sawhorse cells were two stacks of boards, which read as racks. The sawhorse is a
        # plank trestle bench (his table tiles 2539 and 2540, on legs) with logs lying on
        # it to be sawn (1021 and 1022, tiles of his log pile): timber on a trestle. Both cells stay
        # solid, the use cell is unchanged.
        for dx, base, log in ((1, 2539, 1021), (2, 2540, 1022)):
            self.put("below", 1, ox + dx, oy + 6, tile_val(0, base))
            self.put("below", 3, ox + dx, oy + 6, tile_val(0, log))
        for st in SAWMILL_STATIONS[1:]:
            for (x, y), (sx, sy) in st["paste"]:
                for name in st["layers"]:
                    key = (name[:-1], int(name[-1]))
                    v = self.layers[key][sy * W + sx] if key in self.layers else -1
                    if v >= 0:
                        self.put(key[0], key[1], ox + x, oy + y, v)
        # piles of planks and logs in the yard, east of the shed
        for dx, dy, t in ((10, 5, 1024), (11, 5, 1025), (10, 7, 1025), (11, 7, 1024)):
            self.put("below", 1, ox + dx, oy + dy, tile_val(0, t))
        return b

    def restyle_stove(self):
        """PL1-13: Shade drew the kitchen's stove as a frying pan and a pot standing on bare floor, which
        read as pots, not a stove. Here it is a stone hearth: his stone-framed bed of glowing coals (paid
        atlas tiles 3001 and 3004, the left and right ends of the bed) with his pot (139) hung over the
        right-hand fire and the left fire left open for the pan, which is lifted off (361 and its
        handle 360). The cells keep their collision and the use cell is unchanged."""
        self.put("below", 1, 52, 47, tile_val(0, 3001))
        self.put("below", 1, 53, 47, tile_val(0, 3004))
        self.put("below", 3, 52, 47, -1)
        self.put("above", 0, 51, 47, -1)

    def stations(self, sawmill):
        """Workstations, in a fixed order (their ids s0-s9 are quoted by tests): the tavern's, the well, the
        smithy's, the sawmill's sawhorse, the armory's counter and the mine's cart. Generator v7 (Build 13)
        adds s10, the kitchen's preparation table beside the oven, where the cook presses cheese and bakes
        egg bread."""
        tav = "b2"
        smithy = "b4"
        self.station("tavern_counter", (42, 41), tav, at=(42, 40))
        self.station("oven", (53, 48), tav, at=(54, 47))
        self.station("stove", (52, 48), tav, at=(52, 47))
        self.restyle_stove()
        self.station("well", (45, 55), None, at=(46, 55))
        self.station("forge", (77, 42), smithy, at=(77, 41))
        self.station("anvil", (78, 44), smithy, at=(77, 43))
        self.station("workbench", (79, 46), smithy, at=(79, 47))
        ox, oy = sawmill["x"], sawmill["y"]
        self.station("sawhorse", (ox + 3, oy + 6), sawmill["id"], at=(ox + 2, oy + 6))
        self.station("armory_counter", (71, 44), smithy, at=(71, 43))
        self.station("mine_cart", (self.cart[0] + 1, self.cart[1]), None, at=self.cart)
        self.station("prep", (55, 44), tav, at=(55, 45))     # v7: the kitchen table east of the oven

    # ---- market, pens, fields, camp, plots --------------------------------------------------------
    def market(self, x0, y0):
        """Six stalls in a row on the market's dirt: a table and a crate or barrel each, facing south."""
        tables = dict(self.sample("village-3"))["Floor 1/Objects"]
        table = tables[22 * 30 + 6]          # wooden table from the tavern terrace
        for i in range(6):
            x = x0 + i * 4
            for (dx, dy, t) in ((0, 0, table), (1, 0, CRATE if i % 2 else BARREL)):
                self.put("below", 0, x + dx, y0 + dy, tile_val(0, t))
            self.ents["stalls"].append({"id": f"stall{i}", "x": x, "y": y0, "use": [x, y0 + 1]})

    def field(self, x, y, w, h):
        self.ents["fields"].append({"id": f"f{len(self.ents['fields'])}", "x": x, "y": y, "w": w, "h": h})
        for j in range(h):
            for i in range(w):
                self.put("path", 1, x + i, y + j, tile_val(0, field_cell_tile(FIELD_TILES["ripe"], w, h, i, j)))

    def pen(self, kind, x, y, w, h):
        """A fenced pen with a gate in the middle of the top side. The fence is solid, the gate is
        walkable; animals stay on the inner cells."""
        gate = (x + w // 2, y)
        for j in range(h):
            for i in range(w):
                X, Y = x + i, y + j
                edge = {(0, 0): "tl", (w - 1, 0): "tr", (0, h - 1): "bl", (w - 1, h - 1): "br"}.get((i, j))
                if edge is None:
                    edge = "t" if j == 0 else "b" if j == h - 1 else "l" if i == 0 else "r" if i == w - 1 else None
                if edge is None:
                    continue
                self.put("below", 5, X, Y, COZY + (GATE if (X, Y) == gate else FENCE[edge]))
        self.walkable_override.add(gate)
        self.ents["pens"].append({"id": f"pen_{kind}", "kind": kind, "x": x, "y": y, "w": w, "h": h,
                                  "gate": list(gate), "feed_at": [gate[0], gate[1] - 1]})

    def camp(self, cx, cy):
        """The bandits' camp: a campfire with crates and barrels round it, in a clearing of the forest."""
        self.put("below", 0, cx, cy, tile_val(0, CAMPFIRE))
        for dx, dy, t in ((-2, -1, CRATE), (2, -1, BARREL), (-2, 2, BARREL), (2, 2, CRATE)):
            self.put("below", 0, cx + dx, cy + dy, tile_val(0, t))
        self.ents["spawns"]["bandit_camp"] = [cx, cy + 1]

    def plots(self, corners):
        for i, (x, y) in enumerate(corners):
            self.ents["plots"].append({"id": f"plot{i}", "x": x, "y": y, "w": 9, "h": 10,
                                       "door": [x + 4, y + 9], "price": 60})

    # ---- trees and plants --------------------------------------------------------------------------
    def rect_cells(self, x, y, w, h, grow=0):
        return {(i, j) for j in range(y - grow, y + h + grow) for i in range(x - grow, x + w + grow)}

    def protected(self):
        """Cells a tree's trunk must not stand on: every object, building and its door yard, road (with a
        margin), field, pen, plot, yard, the hill, the camp and the mine's track."""
        keep = set()
        for b in self.ents["buildings"]:
            keep |= self.rect_cells(b["x"], b["y"], b["w"], b["h"], 1)
            dx, dy = b["door"]
            keep |= self.rect_cells(dx - 1, dy, 3, 3)
        for f in self.ents["fields"] + self.ents["pens"] + self.ents["plots"]:
            keep |= self.rect_cells(f["x"], f["y"], f["w"], f["h"], 1)
        for s in self.ents["stalls"]:
            keep |= self.rect_cells(s["x"] - 1, s["y"] - 1, 4, 4)
        for s in self.ents["stations"]:
            keep |= self.rect_cells(s["use"][0] - 1, s["use"][1] - 1, 3, 3)
        for d in self.ents["deposits"]:
            keep |= self.rect_cells(d["x"] - 1, d["y"] - 1, 3, 3)
        for c in self.road:
            keep |= self.rect_cells(c[0] - 1, c[1] - 1, 3, 3)
        camp = self.ents["spawns"]["bandit_camp"]
        keep |= self.rect_cells(camp[0] - 4, camp[1] - 4, 9, 9)
        keep |= self.rect_cells(self.adit[0] - 2, 9, 5, 11)
        for c in self.hill:                 # no tree on or beside the hill's rim (B8-004)
            keep |= self.rect_cells(c[0] - 2, c[1] - 2, 5, 5)
        for (cat, i), data in self.layers.items():
            if cat in ("below", "above"):
                keep |= {(k % W, k // W) for k, v in enumerate(data) if v >= 0}
        for y in range(H):                  # ground that is not plain grass: dirt, the hill's rock
            for x in range(W):
                if {self.corner[y][x], self.corner[y][x + 1], self.corner[y + 1][x], self.corner[y + 1][x + 1]} != {self.GRASS}:
                    keep.add((x, y))
        return keep

    def crown_keep(self):
        """Cells a tree's crown (5 wide, up to 5 above the trunk) must not overhang: what people use."""
        cb = set()
        for b in self.ents["buildings"]:
            cb |= self.rect_cells(b["x"], b["y"], b["w"], b["h"], 0)
            dx, dy = b["door"]
            cb |= self.rect_cells(dx - 1, dy - 1, 3, 3)
        for f in self.ents["fields"] + self.ents["pens"] + self.ents["plots"]:
            cb |= self.rect_cells(f["x"], f["y"], f["w"], f["h"], 0)
        for s in self.ents["stalls"]:
            cb |= self.rect_cells(s["x"] - 1, s["y"] - 1, 4, 3)
        for s in self.ents["stations"]:
            cb |= {tuple(s["use"]), tuple(s["at"])}
        for d in self.ents["deposits"]:
            cb.add((d["x"], d["y"]))
        camp = self.ents["spawns"]["bandit_camp"]
        cb |= self.rect_cells(camp[0] - 3, camp[1] - 3, 7, 7)
        cb |= self.rect_cells(self.adit[0] - 1, 9, 3, 11)
        cb |= self.yard
        return cb

    def density(self, x, y):
        """How thickly trees stand at a cell, 0..1: the forests (the west and east woods, the bandits'
        wood, the north band round the mine's hill), small groves elsewhere, thinning towards the
        village's edge so the forest does not stop at a line where the overworld's meadow begins."""
        def inside(x0, y0, x1, y1, soft):
            dx = max(x0 - x, x - x1, 0)
            dy = max(y0 - y, y - y1, 0)
            return max(0.0, 1.0 - math.hypot(dx, dy) / soft)
        woods = max(inside(0, 0, 29, 23, 4), inside(66, 0, 89, 17, 4), inside(90, 0, 119, 19, 3))
        forest = max(woods, inside(0, 0, 119, 21, 6) * 0.55)
        n = vnoise(x, y, 11, 31) * 0.65 + vnoise(x, y, 5, 32) * 0.35
        grove = max(0.0, (vnoise(x, y, 13, 33) - 0.52) * 2.4)
        clearing = 0.25 if vnoise(x, y, 8, 34) < 0.2 else 1.0
        p = forest * (0.28 + 0.62 * n) * clearing + grove * 0.24
        edge = min(x, W - 1 - x, y, H - 1 - y)
        return p * min(1.0, edge / 10.0) ** 1.1

    def place_trees(self):
        """Trees: a natural scatter of the density field. Never on a protected cell, never with a crown over
        a building, a field, a yard or a station, and no two within a tile of each other (so no tree walls
        anything in). Records only; no tile is drawn."""
        keep = self.protected()
        self.keep = keep
        blocked = self.crown_keep()
        cells = sorted(((x, y) for y in range(1, H) for x in range(W)), key=lambda c: _hash(c[0], c[1], 5))
        placed = set()
        groups = {}
        for stump, top, bottom in self.trees:
            groups.setdefault({456: "leafy", 458: "autumn", 460: "conifer", 1120: "leafy", 1780: "mixed",
                               1782: "mixed"}.get(bottom, "mixed"), []).append((stump, top, bottom))
        for x, y in cells:
            p = self.density(x, y)
            if p <= 0 or _hash(x, y, 7) >= p or (x, y) in keep:
                continue
            if any((x + dx, y + dy) in placed for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                continue
            if any((x + dx, y - dy) in blocked for dx in range(-2, 3) for dy in range(1, 6)):
                continue
            placed.add((x, y))
            # the species of a patch: leafy and autumn oaks, mixed woods, conifers
            u = vnoise(x, y, 14, 35)
            group = "leafy" if u < 0.3 else "autumn" if u < 0.45 else "mixed" if u < 0.75 else "conifer"
            kinds = groups.get(group) or self.trees
            stump, top, bottom = kinds[int(_hash(x, y, 8) * len(kinds)) % len(kinds)]
            self.ents["trees"].append({"x": x, "y": y, "trunk": stump, "top": top, "bottom": bottom})
        self.ents["trees"].sort(key=lambda t: (t["y"], t["x"]))

    def place_boulders(self):
        """Small grey boulders (the plain boulder tile in below0): solid cells the game makes minable stone
        (B8-026), scattered on open grass round the hill, the woods and the meadows' edge; never on or beside a
        tree, road, door, station, plant, seam or yard, and never two within four tiles."""
        keep = set(self.keep)
        for t in self.ents["trees"]:
            keep |= self.rect_cells(t["x"] - 1, t["y"] - 1, 3, 3)
        placed = []
        cells = sorted(((x, y) for y in range(3, H - 3) for x in range(3, W - 3)), key=lambda c: _hash(c[0], c[1], 21))
        for x, y in cells:
            if len(placed) == 18:
                break
            if (x, y) in keep or any(abs(x - px) < 4 and abs(y - py) < 4 for px, py in placed):
                continue
            if vnoise(x, y, 9, 43) < 0.55:
                continue
            placed.append((x, y))
            self.put("below", 0, x, y, tile_val(0, DEPLETED_ROCK))
            self.keep.add((x, y))

    def place_plants(self):
        """Wild flowers and berry bushes in loose patches on open grass (generator v5's gatherable
        plants): never on a road, a yard, a door step or a use cell, nor on a tree."""
        keep = set(self.keep)
        for t in self.ents["trees"]:
            keep.add((t["x"], t["y"]))
            keep |= self.rect_cells(t["x"] - 1, t["y"] - 1, 3, 3)
        for b in self.ents["buildings"]:
            keep |= self.rect_cells(b["x"] - 1, b["y"] - 1, b["w"] + 2, b["h"] + 3)
        for c in self.road:
            keep.add(c)
        out = []
        kinds = [2657, 2658, 2658, 2660, 2662, 2662, 2657]
        for y in range(1, H - 1):
            for x in range(1, W - 1):
                if (x, y) in keep:
                    continue
                patch = vnoise(x, y, 7, 41)
                if patch < 0.48 or _hash(x, y, 9) > (patch - 0.40) * 1.1:
                    continue
                if any((x + dx, y + dy) in out for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1))):
                    continue
                t = kinds[int(_hash(x, y, 10) * len(kinds))]
                if t in (2660, 2662) and _hash(x, y, 12) > 0.5:
                    t = 2657 + int(_hash(x, y, 13) * 2)
                out.append((x, y))
                self.put("below", 1, x, y, tile_val(0, t))

    # ---- containers ---------------------------------------------------------------------------
    def containers(self):
        """Interactable containers, read from the tiles already placed (no random numbers): crates and
        barrels by each house (its household's store), in and around the tavern (its keepers' stock) and
        beside each market stall (the stall's), and each dish or mug drawn on a tavern table (a table
        the tavern keepers set food on). Every one of a house's lies inside its rectangle: its door
        yard, the cells Shade drew its crates in."""
        out = self.ents["containers"]

        def scan(at, x0, y0, x1, y1, dishes):
            for y in range(y0, y1):
                for x in range(x0, x1):
                    below = [self.get("below", i, x, y) for i in range(6)]
                    kind, dish = None, None
                    if any(v in CRATE_TILES for v in below[:3] + below[5:]):
                        kind = "crate"
                    elif any(v in BARREL_TILES for v in below[:3] + below[5:]):
                        kind = "barrel"
                    elif dishes and any(v in DISH_TILES for v in below[3:5]):
                        kind = "table"
                        i = next(i for i in (3, 4) if below[i] in DISH_TILES)
                        dish = {"dish": DISH_TILES[below[i]], "tile": below[i], "layer": f"below{i}"}
                    if kind:
                        c = {"id": f"c{len(out)}", "kind": kind, "x": x, "y": y, "at": at}
                        if dish:
                            c.update(dish)      # what is served there, and the tile that shows it
                        out.append(c)

        for b in self.ents["buildings"]:
            if b["type"] == "tavern":
                scan(b["id"], b["x"], b["y"], b["x"] + b["w"], b["y"] + b["h"] + 2, True)
            elif b["type"] == "house":
                scan(b["id"], b["x"], b["y"], b["x"] + b["w"], b["y"] + b["h"], False)
        for st in self.ents["stalls"]:
            scan(st["id"], st["x"] + 1, st["y"], st["x"] + 2, st["y"] + 1, False)

    # ---- interiors (generator v3) -----------------------------------------------------------
    def interiors(self):
        """Give every roofed building an interior, after everything else is placed (no random numbers,
        so no tree, building, plot, road or container moves): beds in the small houses, the sage's hut's
        inner cell cleared, then for each building the cells under its roof reached from its doors
        (`area`), the walkable ones (`floor`, made walkable here), its roof tiles (faded by the game while
        the player is inside) and its use spots: beds, straw pallets (homes get SLEEP_PLACES sleeping
        places), tables, hearths and chests."""
        for b in self.ents["buildings"]:
            if b["type"] == "hut":
                for y in range(b["y"] - 1, b["y"] + b["h"] + 1):
                    for x in range(b["x"] - 1, b["x"] + b["w"] + 1):
                        for i in range(6):
                            if self.get("below", i, x, y) == HUT_BOX:
                                self.put("below", i, x, y, -1)
            elif b["type"] == "house":
                self.furnish_house(b)
        self.legacy_solid = self.solid_grid()
        roofs = {}
        for name in ROOF_LAYERS:
            data = self.layers.get((name[:5], int(name[5:])), [])
            for i, v in enumerate(data):
                if v >= 0:
                    roofs[(i % W, i // W)] = True
        comp = {}                   # roof cell -> its roof (4-connected roof cells)
        k = -1
        for c in sorted(roofs):
            if c in comp:
                continue
            todo, k = [c], k + 1
            comp[c] = k
            while todo:
                x, y = todo.pop()
                for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if n in roofs and n not in comp:
                        comp[n] = k
                        todo.append(n)
        members = {}
        for c, k in comp.items():
            members.setdefault(k, []).append(c)
        for b in self.ents["buildings"]:
            b["interior"] = self.interior_of(b, comp, members)
        self.floor_fix()

    def has_floor(self, x, y):
        """Whether a stamped floor tile (not the village's wang ground) lies in the cell."""
        return any(0 <= self.get("ground", i, x, y) < FREE for i in range(1, 6))

    def floor_fix(self):
        """Every interior floor cell shows a floor, never the grass of the continuous ground layer (B8-002).
        Where a stamp left a floor cell without one (the tavern's open-air kitchen lies outside its roof,
        and Shade's sample drew grass there), the building's most common floor tile is laid."""
        for b in self.ents["buildings"]:
            cells = b["interior"]["floor"]
            kitchen = set()
            count = {}
            for x, y in cells:
                for i in range(1, 6):
                    t = self.get("ground", i, x, y)
                    if 0 <= t < FREE:
                        count[(i, t)] = count.get((i, t), 0) + 1
            if not count:
                continue
            i, t = sorted(count.items(), key=lambda kv: (-kv[1], kv[0]))[0][0]
            if b["type"] == "tavern":           # the open-air kitchen behind its own walls, entered by a door of its own
                todo = [KITCHEN_CELL]
                seen = set(todo)
                while todo:                     # spread over the cells the kitchen's walls enclose
                    x, y = todo.pop()
                    for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if (n in seen or n in self.walls or n in self.roof or n in self.floor
                                or any(v in DOORS for v in self.below_tiles(*n))
                                or not (b["x"] <= n[0] < b["x"] + b["w"] and b["y"] <= n[1] < b["y"] + b["h"])):
                            continue
                        seen.add(n)
                        todo.append(n)
                        kitchen.add(n)
                assert KITCHEN_CELL in seen and len(kitchen) < 80, "the kitchen's walls leak"
                kitchen.add(KITCHEN_CELL)
            for x, y in list(cells) + sorted(kitchen):
                if not self.has_floor(x, y):
                    self.put("ground", i, x, y, t)

    def furnish_house(self, b):
        """Beds in Shade's small house (HOUSE_BEDS), where his straw mat, shelf and jars stood."""
        ox, oy = b["x"], b["y"]
        assert self.get("below", 1, ox + 1, oy + 2) in CHEST_TILES, "not Shade's small house"
        for x, y in HOUSE_CLEAR:
            for cat, i in (("below", 1), ("below", 3), ("below", 4), ("above", 0), ("above", 1)):
                self.put(cat, i, ox + x, oy + y, -1)
        for (bx, by), (px, py), body, post in HOUSE_BEDS:
            for x, y in ((bx, by), (px, py)):
                assert self.get("below", 1, ox + x, oy + y) < 0, f"bed over furniture in {b['id']}"
            self.put("below", 1, ox + bx, oy + by, tile_val(0, body))
            self.put("below", 1, ox + px, oy + py, tile_val(0, post))

    def below_tiles(self, x, y):
        return [v for (c, _), d in sorted(self.layers.items()) if c == "below" for v in [d[y * W + x]] if v >= 0]

    def interior_of(self, b, comp, members):
        # doors in the building's rectangle or just outside it (the hut's is one cell off); the area
        # spreads from them over roofed cells inside the rectangle, never past a wall
        x0, y0, x1, y1 = b["x"], b["y"], b["x"] + b["w"], b["y"] + b["h"]
        inside = lambda c: x0 <= c[0] < x1 and y0 <= c[1] < y1
        doors = sorted((x, y) for y in range(y0 - 1, y1 + 1) for x in range(x0 - 1, x1 + 1)
                       if (x, y) in comp and any(v in DOORS for v in self.below_tiles(x, y)))
        area, todo = set(doors), list(doors)
        while todo:
            x, y = todo.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in comp and n not in area and n not in self.walls and inside(n):
                    area.add(n)
                    todo.append(n)
        legacy = self.legacy_solid
        floor = set()
        for c in area:
            if not legacy[c[1]][c[0]] or all(v in DOORS or v == MAT for v in self.below_tiles(*c)):
                floor.add(c)
        self.floor |= floor
        # an open doorway (no door drawn, as into the tavern's open-air kitchen) is a door too
        walk = lambda c: 0 <= c[0] < W and 0 <= c[1] < H and (not legacy[c[1]][c[0]] or c in self.floor)
        doors = sorted(set(doors) | {(x, y) for x, y in floor if any(
            n not in area and walk(n) for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))})
        free = sorted(c for c in floor if c not in doors)

        def use_of(at):
            best = min(free, key=lambda c: (abs(c[0] - at[0]) + abs(c[1] - at[1]), abs(c[1] - at[1]), c[1], c[0]),
                       default=None)
            if best is None or abs(best[0] - at[0]) + abs(best[1] - at[1]) > 3:
                return None
            return best

        spots = []
        for c in sorted(area, key=lambda c: (c[1], c[0])):
            for t in self.below_tiles(*c):
                kind = ("bed" if t in BED_TILES else "table" if t in TABLE_TILES else
                        "hearth" if t in HEARTH_TILES else "chest" if t in CHEST_TILES else None)
                use = use_of(c) if kind else None
                if use:
                    s = {"kind": kind, "at": list(c), "use": list(use)}
                    if kind == "bed":
                        s.update(head=BED_TILES[t], tile=t)
                    spots.append(s)
        beds = [s for s in spots if s["kind"] == "bed"]
        if EXTRA_BEDS.get(b["type"]):
            for spot in self.add_beds(b, doors, floor, free, spots, EXTRA_BEDS[b["type"]], use_of):
                spots.append(spot)
                beds.append(spot)
            free = sorted(c for c in floor if c not in doors)
        if b["type"] in HOME_TYPES:
            taken = {tuple(s["use"]) for s in spots} | {(c["x"], c["y"]) for c in self.ents["containers"]}
            near_door = {(x + dx, y + dy) for x, y in doors for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1))}
            cands = [c for c in free if c not in taken and c not in near_door and not self.below_tiles(*c)
                     and all(self.get("above", i, *c) < 0 for i in range(6) if f"above{i}" not in ROOF_LAYERS)]
            ref = [tuple(s["at"]) for s in beds] or doors
            far = -1 if not beds else 1         # pallets by the beds, or as far from the door as can be
            cands.sort(key=lambda c: (far * min(abs(c[0] - r[0]) + abs(c[1] - r[1]) for r in ref), c[1], c[0]))
            cands += [c for c in free if c in near_door and c not in taken and c not in cands and not self.below_tiles(*c)]
            for c in cands[:max(0, SLEEP_PLACES - len(beds))]:
                i = next(i for i in range(6) if self.get("below", i, *c) < 0)
                self.put("below", i, c[0], c[1], tile_val(0, MAT))
                spots.append({"kind": "bed", "at": list(c), "use": list(c), "head": "left", "tile": MAT})
        roof = sorted({r for k in sorted({comp[c] for c in area}) for r in members[k]})
        return {"doors": [list(c) for c in doors], "area": [list(c) for c in sorted(area)],
                "floor": [list(c) for c in sorted(floor)], "roof": [list(c) for c in roof], "spots": spots}

    def add_beds(self, b, doors, floor, free, spots, count, use_of):
        """Up to `count` beds (two cells, head left) on free floor away from the doors, each only where
        every other floor cell can still be reached from a door. The bed cells leave the floor (solid)."""
        taken = {tuple(s["use"]) for s in spots} | {tuple(s["at"]) for s in spots} | \
                {(c["x"], c["y"]) for c in self.ents["containers"]}
        near_door = {(x + dx, y + dy) for x, y in doors for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (0, -2), (0, 2))}
        ok = lambda c: c in floor and c not in taken and c not in near_door and not self.below_tiles(*c) \
            and all(self.get("above", i, *c) < 0 for i in range(6) if f"above{i}" not in ROOF_LAYERS)

        def reach(cells):
            seen, todo = set(), [d for d in doors if d in cells]
            seen |= set(todo)
            while todo:
                x, y = todo.pop()
                for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if n in cells and n not in seen:
                        seen.add(n)
                        todo.append(n)
            return seen

        # a bed may not cut anyone off: what the doors reached before, less the bed, they still reach
        connected = lambda rest: reach(rest) >= reach(floor) - (floor - rest)

        out = []
        for c in sorted(free, key=lambda c: (c[1], c[0])):
            if len(out) == count:
                break
            pair = (c, (c[0] + 1, c[1]))
            if not all(ok(p) for p in pair):
                continue
            rest = floor - set(pair)
            use = next((n for n in ((c[0], c[1] + 1), (c[0], c[1] - 1), (c[0] + 2, c[1] + 1), (c[0] - 1, c[1]))
                        if n in rest and n not in taken), None)
            if use is None or not connected(rest):
                continue
            body, post = ADDED_BED_TILES[len(out) % len(ADDED_BED_TILES)]
            self.put("below", 1, c[0], c[1], tile_val(0, body))
            self.put("below", 1, pair[1][0], pair[1][1], tile_val(0, post))
            floor -= set(pair)
            self.floor -= set(pair)
            taken |= set(pair) | {use}
            out.append({"kind": "bed", "at": list(c), "use": list(use), "head": BED_TILES[body], "tile": body})
        return out

    # ---- collision and roads ----------------------------------------------------------------
    def plant_cells(self):
        """Gatherable plants (generator v5): cells whose only object is a flower or a berry bush, with
        nothing on top and not in a wall, roof, floor or doorway. They are walkable and are exported
        as entities."""
        out = []
        for y in range(H):
            for x in range(W):
                c = (x, y)
                vals = [v[y * W + x] for (cat, _), v in sorted(self.layers.items()) if cat == "below" and v[y * W + x] >= 0]
                if len(vals) != 1 or vals[0] not in PLANTS:
                    continue
                if (c in self.roof or c in self.walls or c in self.floor or c in self.walkable_override
                        or any(self.get("above", i, x, y) >= 0 for i in range(6))):
                    continue
                out.append((x, y, vals[0]))
        return out

    def solid_grid(self):
        solid = [[False] * W for _ in range(H)]
        for y in range(H):
            for x in range(W):
                c = (x, y)
                s = (self.has_object(x, y) and c not in self.decor) or c in self.roof or c in self.hill
                if c in self.walkable_override or c in self.floor:
                    s = False
                solid[y][x] = s
        for x, y, _ in self.plant_cells():                # generator v5: plants are walkable
            solid[y][x] = False
        for p in self.ents["plots"]:                      # plots are clear land
            for y in range(p["y"], p["y"] + p["h"]):
                for x in range(p["x"], p["x"] + p["w"]):
                    solid[y][x] = False
        return solid

    def draw_roads(self):
        """Road tiles of the free tileset's dirt pathways, chosen from the neighbouring road cells; a road
        cell on a map edge continues outwards (the overworld's road takes it up). None on the dirt yards
        (the yard is the road there) nor on a doorway."""
        dirs = ((0, -1), (1, 0), (0, 1), (-1, 0))
        paths = self.paths
        for (x, y) in sorted(self.road):
            if (x, y) in self.walkable_override or (x, y) in self.yard:
                continue
            con = []
            for dx, dy in dirs:
                n = (x + dx, y + dy)
                con.append(n in self.road or n in self.yard or not (0 <= n[0] < W and 0 <= n[1] < H))
            con = tuple(con)
            if con in paths["dirt"]:
                self.put("path", 0, x, y, tile_val(1, self.rng.choice(sorted(paths["dirt"][con]))))

    # ---- output -----------------------------------------------------------------------------
    def workshop_stamp(self, kind, house):
        """A workshop stamp (WORKSHOPS): the house stamp with its sleeping places cleared and the
        stations' tiles copied in from where Shade drew them, with the collision, interior and
        stations to match. Reads only the sample maps and the finished house, draws no random numbers."""
        w, h = house["w"], house["h"]
        layers = {k: list(v) for k, v in house["layers"].items()}
        solid = [list(row) for row in house["solid"]]
        it = house["interior"]
        beds = [tuple(s["at"]) for s in it["spots"] if s["kind"] == "bed"]
        posts = [tuple(p) for _, p, _, _ in HOUSE_BEDS]
        for x, y in beds + posts:
            for name in list(layers):
                v = layers[name][y * w + x]
                if (name != "below0" or v == tile_val(0, MAT)) and name not in ROOF_LAYERS and not name.startswith(("path", "ground")):
                    layers[name][y * w + x] = -1
            solid[y][x] = "0"
        stations = []
        for st in WORKSHOPS[kind]["stations"]:
            for (x, y), (sx, sy) in st["paste"]:
                for name in st["layers"]:
                    key = (name[:-1], int(name[-1]))
                    v = self.layers[key][sy * W + sx] if key in self.layers else -1
                    if name not in layers:
                        layers[name] = [-1] * (w * h)
                    if v >= 0 or name != "below0":
                        layers[name][y * w + x] = v
                if y >= 2:
                    solid[y][x] = "1"
            if st["type"]:
                stations.append({"type": st["type"], "at": list(st["at"]), "use": list(st["use"])})
                ux, uy = st["use"]
                assert solid[uy][ux] == "0", f"{kind}: the {st['type']} is used from a wall"
        area = [tuple(c) for c in it["area"]]
        floor = sorted(c for c in area if solid[c[1]][c[0]] == "0")
        interior = {"doors": it["doors"], "area": it["area"], "floor": [list(c) for c in floor], "roof": it["roof"],
                    "spots": [s for s in it["spots"] if s["kind"] in ("chest", "table")]}
        return {"w": w, "h": h, "door": house["door"], "layers": {k: layers[k] for k in sorted(layers)},
                "interior": interior, "solid": ["".join(r) for r in solid], "stations": stations}

    def reachable_uses(self, solid):
        """Generator v5: a station used from a cell nobody can walk to is used from the nearest walkable
        cell beside it that is reached from the village square."""
        hub = tuple(self.ents["spawns"]["player"])
        seen, todo = {hub}, [hub]
        while todo:
            x, y = todo.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= n[0] < W and 0 <= n[1] < H and n not in seen and not solid[n[1]][n[0]]:
                    seen.add(n)
                    todo.append(n)
        ring = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (-1, 1), (1, -1), (-1, -1)]
        ring += [(dx, dy) for dy in range(-2, 3) for dx in range(-2, 3) if max(abs(dx), abs(dy)) == 2]
        for st in self.ents["stations"]:
            if tuple(st["use"]) in seen:
                continue
            ax, ay = st["at"]
            for dx, dy in ring:
                if (ax + dx, ay + dy) in seen:
                    st["use"] = [ax + dx, ay + dy]
                    break

    def to_json(self):
        solid = self.solid_grid()
        self.reachable_uses(solid)
        layers = []
        order = [("ground", i) for i in range(6)] + [("path", 0), ("path", 1)] + \
                [("below", i) for i in range(6)] + [("above", i) for i in range(6)]
        for key in order:
            if key in self.layers:
                layers.append({"name": f"{key[0]}{key[1]}", "z": key[0], "data": self.layers[key]})
        free_img = self.free[0]
        # the house stamp, for houses the player builds at runtime (cut from the first generated house)
        hb = next(b for b in self.ents["buildings"] if b["type"] == "house" and b["id"].startswith("b") and b["id"][1:].isdigit())
        stamp = {"w": hb["w"], "h": hb["h"], "door": [4, 9], "layers": {}}
        for (cat, i), data in sorted(self.layers.items()):
            if cat == "ground" and i == 0:
                continue                    # the village's wang grass; the house's own floor (ground1+) goes with it
            cells = [data[(hb["y"] + y) * W + hb["x"] + x] for y in range(hb["h"]) for x in range(hb["w"])]
            if any(v >= 0 for v in cells):
                stamp["layers"][f"{cat}{i}"] = cells
        # every floor cell of the built house shows a floor, never the grass of wherever it is built: a
        # cell with no stamped floor of its own takes the house's most common floor tile
        local = lambda c: [c[0] - hb["x"], c[1] - hb["y"]]
        it = hb["interior"]
        g1 = stamp["layers"].setdefault("ground1", [-1] * (hb["w"] * hb["h"]))
        floor_cells = [tuple(local(c)) for c in it["floor"]]
        seen = [g1[y * hb["w"] + x] for x, y in floor_cells if g1[y * hb["w"] + x] >= 0]
        if seen:
            common = max(sorted(set(seen)), key=seen.count)
            for x, y in floor_cells:
                if not any(stamp["layers"].get(f"ground{i}", [-1] * (hb["w"] * hb["h"]))[y * hb["w"] + x] >= 0 for i in range(1, 6)):
                    g1[y * hb["w"] + x] = common
        stamp["interior"] = {k: [local(c) for c in it[k]] for k in ("doors", "area", "floor", "roof")}
        stamp["interior"]["spots"] = [{**sp, "at": local(sp["at"]), "use": local(sp["use"])} for sp in it["spots"]]
        stamp["solid"] = ["".join("1" if solid[hb["y"] + y][hb["x"] + x] else "0" for x in range(hb["w"]))
                          for y in range(hb["h"])]
        stamps = {"house": stamp}
        for kind in WORKSHOPS:
            stamps["workshop_" + kind] = self.workshop_stamp(kind, stamp)
        stamps["room"] = room_stamp(stamp)
        return {
            "format": "mml-village/1", "seed": self.seed, "w": W, "h": H, "tile": 16,
            "atlases": [{"name": "paid", "image": "res://assets/tiles/punyworld-tiles.png", "columns": 220},
                        {"name": "free", "image": "res://assets/tiles/punyworld-overworld-tiles.png",
                         "columns": free_img.width // 16},
                        {"name": "cozy", "image": "res://assets/tiles/cozyfarm-tiles.png", "columns": COZY_COLS}],
            "animated": {str(CAMPFIRE): [CAMPFIRE, CAMPFIRE + 1, CAMPFIRE + 2, CAMPFIRE + 3]},
            "tiles": {"ore": ORE, "depleted_rock": DEPLETED_ROCK, "stump": STUMP, "sapling": SAPLING,
                      "field": FIELD_TILES, "frame": FRAME,
                      "canopy": [list(p) for p in self.canopy_pairs()]},
            "layers": layers,
            "stamps": stamps,
            "roof_layers": list(ROOF_LAYERS),
            "solid": ["".join("1" if s else "0" for s in row) for row in solid],
            "road": sorted([list(c) for c in self.road]),
            "plants": [{"id": f"pl{i}", "x": x, "y": y, "kind": PLANTS[t], "tile": t}
                       for i, (x, y, t) in enumerate(self.plant_cells())],
            **self.ents,
        }


def render(data, solid=False, trees=True):
    """Preview PNG of a built village (and optionally its collision). Trees are drawn from their records'
    old tile ids, only so that the preview shows where they stand."""
    from PIL import Image
    paid = AssetZip(PAID).image("PUNY-WORLD-PAID_v1/Tiled/punyworld-tiles.png").convert("RGBA")
    free = pwt.load(AssetZip(pwt.ZIP))[0].convert("RGBA")
    cozy = AssetZip("CozyFarm_full_version.zip").image("full version/tiles/tiles.png").convert("RGBA")
    sheets = [(paid, 220), (free, free.width // 16), (cozy, COZY_COLS)]
    img = Image.new("RGBA", (W * 16, H * 16), (0, 0, 0, 255))
    cache = {}

    def tile(v):
        if v not in cache:
            sheet, cols = sheets[v // FREE]
            t = v % FREE
            cache[v] = sheet.crop(((t % cols) * 16, (t // cols) * 16, (t % cols) * 16 + 16, (t // cols) * 16 + 16))
        return cache[v]

    above = []
    for lay in data["layers"]:
        for i, v in enumerate(lay["data"]):
            if v < 0:
                continue
            if lay["z"] == "above":
                above.append((i, v))
            else:
                img.alpha_composite(tile(v), ((i % W) * 16, (i // W) * 16))
    if trees:
        for t in data["trees"]:
            for dy, k in ((0, "trunk"), (-1, "top"), (0, "bottom")):
                img.alpha_composite(tile(t[k]), (t["x"] * 16, (t["y"] + dy) * 16))
    for i, v in above:
        img.alpha_composite(tile(v), ((i % W) * 16, (i // W) * 16))
    if solid:
        red = Image.new("RGBA", (16, 16), (255, 0, 0, 90))
        for y, row in enumerate(data["solid"]):
            for x, ch in enumerate(row):
                if ch == "1":
                    img.alpha_composite(red, (x * 16, y * 16))
    return img


def build(seed=1):
    return Village(seed).build().to_json()


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--preview", help="also write a preview PNG here")
    ap.add_argument("--solid", action="store_true", help="tint solid cells in the preview")
    args = ap.parse_args()
    data = build(args.seed)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    n = data
    print(f"wrote {OUT.relative_to(REPO)}: {len(n['buildings'])} buildings, {len(n['stations'])} stations, "
          f"{len(n['trees'])} trees, {len(n['deposits'])} deposits, {len(n['fields'])} fields, "
          f"{len(n['stalls'])} stalls, {len(n['plots'])} plots, {len(n['pens'])} pens, {len(n['containers'])} containers, "
          f"{len(n['road'])} road cells")
    if args.preview:
        render(data, args.solid).save(args.preview)


if __name__ == "__main__":
    main()
