"""Build the playable village map for the Godot game (game/data/village.json).

The village is 120 x 90 tiles (16 px), assembled from twelve 30 x 30 districts:

    row 0:  forest       | mine highland (Shade's cave sample) | forest | forest + bandit camp
    row 1:  houses (Shade's village sample 1) | tavern (sample 3) | smithy + armory (sample 2) | houses
    row 2:  houses       | market square + houses | farms | houses

Shade's sample maps (PUNY-WORLD-PAID_v1.zip) are used as they are, minus the people Shade baked into
them as tiles; the live NPCs replace them. The generated districts reuse objects cut from those
samples (the small house, single trees, stumps, tables, crates), ore rocks and field tiles from the
paid atlas, and grass and dirt-road tiles from the free PUNY_WORLD_v1 wangsets (the same ones
tools/puny_world_terrain.py uses).

Output (deterministic for a given seed):
  game/data/village.json   tile layers, collision, and every gameplay entity: buildings with doors,
                           homes, workstations, trees, ore deposits, fields, stalls, build plots,
                           containers (crates, barrels, tavern tables), spawn points, and each
                           building's interior (floor, doors, roof cells, beds and other use spots;
                           see Village.interiors) with "roof_layers" naming the layers roofs are in
  game/assets/tiles/       the two tile atlases, copied from the archives (provenance in
                           game/assets/PROVENANCE.json, written by tools/import_game_assets.py)

Tile values: atlas * 100000 + tile id (atlas 0 = paid punyworld-tiles, 1 = free overworld tiles,
2 = Cozy Farm tiles), -1 = empty. Pens are fenced with Cozy Farm fence tiles; "woods" are the forest
districts where wild animals live.

Usage:
    python3 tools/build_village.py [--seed 1]
"""
import argparse
import heapq
import json
import random
from pathlib import Path

from assetzip import AssetZip, REPO
import puny_world_terrain as pwt

PAID = "PUNY-WORLD-PAID_v1.zip"
SAMPLE = "PUNY-WORLD-PAID_v1/Tiled/sample-{}.tmj"
FREE = 100000           # atlas offset for the free overworld tiles
COZY = 2 * FREE         # atlas offset for the Cozy Farm tiles (fences, gates)
COZY_COLS = 54
CH = 30                 # district size in tiles
W, H = 4 * CH, 3 * CH
OUT = REPO / "game" / "data" / "village.json"

# --- atlas facts (tile ids in punyworld-tiles.png, 220 columns) -------------------------------
DOORS = {3875, 3799, 3801}                   # doors and archways: walkable
PEOPLE_MIN = 126 * 220                       # rows 126+ hold the tiny people Shade drew into maps
ORE = {"iron_ore": 1966, "copper_ore": 1744, "coal": 1746, "stone": 1743, "gold_ore": 1965}
DEPLETED_ROCK = 1964
STUMP = 459
TREE_DRAWS = 22                              # tree kinds drawn per tree by generator v1 (keeps the layout)
SAPLING = 4304
FIELD_TILES = {"tilled": 3737, "growing": 1971, "ripe": 2851}
FRAME = 3499                                 # wooden construction frame (build sites)
CAMPFIRE = 5958                              # animated in the tileset (5958-5961)
CRATE, BARREL = 3500, 3502
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

# --- interiors (generator v3) --------------------------------------------------------------------
# Every roofed building has an interior under its roof: Shade drew the rooms, walls and furniture of
# his houses and the manor under their roofs, and gave the tavern and the smithy roofs of their own
# (sample-village-3 / -2, in a "Roof" group he left hidden). The game fades a roof while the player is
# under it (game/scripts/view/roof_fade.gd).
ROOF_LAYERS = ("above3", "above4", "above5")       # the "above" layers that hold roofs (faded, never canopies)
HIDDEN_ROOFS = (("village-3", 1, 1), ("village-2", 2, 1))     # (sample, district x, district y)
# Beds Shade drew (the bed's body tile -> where its head lies); the bed's other tile is a headboard
BED_TILES = {1472: "up", 1477: "up", 1482: "up", 1691: "right", 1696: "right", 1701: "right",
             1693: "left", 1698: "left", 1703: "left"}
TABLE_TILES = {2539, 2540, 2542, 1887, 1888, 1889, 1890, 2547, 2548, 2549, 2550}
HEARTH_TILES = {2565, 2566, 2567, 2568}     # bread ovens / hearths
CHEST_TILES = {355}
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

# --- workshop stamps (property phase 2, agent proposal) -------------------------------------------
# A workshop is Shade's small house (the house stamp: walls, roof, door, chest and tables) with its beds
# and straw pallet taken out and the stations of his smithy (village-2) or tavern kitchen (village-3)
# moved in, tile for tile, from where he drew them in this village: (local cell, source cell) pairs,
# copied in the named layers. Nothing is drawn new. Each station records its object cell and the floor
# cell it is used from. A workshop has no hearth spot (it is not a home).
WORK_LAYERS = ("below1", "below2", "above0", "above1", "above2")
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
        {"type": "sawhorse", "at": (2, 6), "use": (3, 6), "layers": ("below0",),
         "paste": (((1, 6), (76, 45)), ((2, 6), (77, 45)))},
        {"type": "", "layers": WORK_LAYERS, "paste": (((1, 7), (79, 45)), ((2, 7), (80, 45)))},   # grindstone
    ]},
    "bakehouse": {"stations": [
        {"type": "oven", "at": (5, 2), "use": (5, 3), "layers": WORK_LAYERS,
         "paste": (((5, 1), (54, 46)), ((6, 1), (55, 46)), ((5, 2), (54, 47)), ((6, 2), (55, 47)))},
        {"type": "stove", "at": (2, 5), "use": (3, 5), "layers": WORK_LAYERS,
         "paste": (((1, 5), (51, 47)), ((2, 5), (52, 47)), ((1, 6), (53, 47)))},       # the pan and the pot
    ]},
}

CATS = ("ground", "path", "below", "above")


def tile_val(atlas, tid):
    return atlas * FREE + tid


class Village:
    def __init__(self, seed):
        self.rng = random.Random(seed)
        self.seed = seed
        self.layers = {}            # (cat, index) -> list
        self.walkable_override = set()
        self.decor = set()          # cells whose only object is 1x1 decor (walkable)
        self.roof = set()           # cells under a roof (solid)
        self.solid_extra = set()
        self.walls = set()          # cells holding a wall tile (Shade's "Wall" layers)
        self.late_roof = set()      # roof cells added by interiors() (the tavern's and the smithy's)
        self.floor = set()          # walkable interior floor (interiors())
        self.ents = {"buildings": [], "stations": [], "trees": [], "deposits": [], "fields": [],
                     "stalls": [], "plots": [], "pens": [], "woods": [], "spawns": {}, "mine": None,
                     "containers": []}
        self.free = pwt.load(AssetZip(pwt.ZIP))
        self.paid = AssetZip(PAID)
        self.samples = {}

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
            return "ground"     # the cave sample's raised plateau ("Roof/Roof") is walkable rock floor
        if "Top" in n or "Roof" in layer_name:
            return "above"
        return "below"

    def paste_sample(self, name, ox, oy, rect=None):
        """Copy a sample map (or a rect of it) to (ox, oy). Returns nothing; records roofs and
        1x1 decorations for the collision pass."""
        rx, ry, rw, rh = rect or (0, 0, 30, 30)
        counters = {c: 0 for c in CATS}
        objs = {}
        for lname, data in self.sample(name):
            cat = self.category(lname)
            idx = counters[cat]
            counters[cat] += 1
            roof = "Roof" in lname and name != "cave-1"
            for y in range(rh):
                for x in range(rw):
                    t = data[(ry + y) * 30 + rx + x]
                    if t < 0 or t >= PEOPLE_MIN:
                        continue
                    self.put(cat, idx, ox + x, oy + y, tile_val(0, t))
                    if roof:
                        self.roof.add((ox + x, oy + y))
                    if cat == "below":
                        objs.setdefault((x, y), []).append(t)
                        if "Wall" in lname.split("/")[-1]:
                            self.walls.add((ox + x, oy + y))
                        if t in DOORS:
                            self.walkable_override.add((ox + x, oy + y))
        # 1x1 objects with nothing around them and nothing on top are decorations (flowers, rocks)
        for (x, y), ts in objs.items():
            alone = all((x + dx, y + dy) not in objs for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            top = any(self.get("above", i, ox + x, oy + y - 1) >= 0 or self.get("above", i, ox + x, oy + y) >= 0
                      for i in range(4))
            if alone and not top and len(ts) == 1:
                self.decor.add((ox + x, oy + y))

    def stamp_from_sample(self, name, rect, ox, oy):
        self.paste_sample(name, ox, oy, rect)

    # ---- generated content ------------------------------------------------------------------
    def grass(self, x0, y0, w, h):
        _, _, ids, tiles, _ = self.free
        g = ids["grass"]
        opts = tiles[(g, g, g, g)]
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                self.put("ground", 0, x, y, tile_val(1, self.rng.choice(opts)))

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
        stump cell is the trunk, and is the tree's only solid cell."""
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

    def place_tree(self, x, y, kind=None):
        # v1 drew from 22 (object, top) pairs; drawing the same range keeps every tree, and everything
        # generated after the forests, where it was
        stump, top, bottom = kind or self.trees[self.rng.randrange(TREE_DRAWS) % len(self.trees)]
        self.put("below", 0, x, y, tile_val(0, stump))
        self.put("above", 0, x, y - 1, tile_val(0, top))
        self.put("above", 0, x, y, tile_val(0, bottom))
        self.ents["trees"].append({"x": x, "y": y, "trunk": stump, "top": top, "bottom": bottom})

    def free_cell(self, x, y):
        return (0 <= x < W and 0 <= y < H and not self.has_object(x, y) and (x, y) not in self.roof
                and all(self.get("above", i, x, y) < 0 for i in range(4)))

    def forest(self, x0, y0, w, h, density, clear=()):
        for y in range(y0 + 1, y0 + h):
            for x in range(x0, x0 + w):
                if any(cx <= x < cx + cw and cy <= y < cy + chh for cx, cy, cw, chh in clear):
                    continue
                if (self.rng.random() < density and self.free_cell(x, y) and self.free_cell(x, y - 1)
                        and not any(abs(t["x"] - x) + abs(t["y"] - y) < 2 for t in self.ents["trees"][-40:])):
                    self.place_tree(x, y)

    def house(self, ox, oy, kind="house"):
        """Shade's small house from sample village 1 (9 x 10 tiles, door at (4, 8))."""
        self.stamp_from_sample("village-1", (2, 10, 9, 10), ox, oy)
        b = {"id": f"b{len(self.ents['buildings'])}", "type": kind, "x": ox, "y": oy, "w": 9, "h": 10,
             "door": [ox + 4, oy + 9]}
        self.walkable_override.add((ox + 4, oy + 8))
        self.ents["buildings"].append(b)
        return b

    def building(self, kind, x, y, w, h, door, **extra):
        b = {"id": f"b{len(self.ents['buildings'])}", "type": kind, "x": x, "y": y, "w": w, "h": h,
             "door": list(door), **extra}
        self.ents["buildings"].append(b)
        return b

    def station(self, kind, use, building=None, at=None):
        self.ents["stations"].append({"id": f"s{len(self.ents['stations'])}", "type": kind,
                                      "use": list(use), "at": list(at or use), "building": building})

    # ---- districts --------------------------------------------------------------------------
    def build(self):
        self.trees = self.tree_stamps()
        for cy in range(3):
            for cx in range(4):
                self.grass(cx * CH, cy * CH, CH, CH)

        # row 1: Shade's three village samples
        self.paste_sample("village-1", 0, CH)
        self.ents["buildings"].append({"id": "b_v1_house", "type": "house", "x": 2, "y": CH + 10, "w": 9, "h": 10,
                                       "door": [6, CH + 19]})
        self.ents["buildings"].append({"id": "b_manor", "type": "manor", "x": 14, "y": CH + 6, "w": 15, "h": 18,
                                       "door": [23, CH + 22]})
        self.paste_sample("village-3", CH, CH)
        ox, oy = CH, CH
        tav = self.building("tavern", ox + 4, oy + 8, 23, 14, (ox + 8, oy + 22), name="The Well House")
        self.station("tavern_counter", (ox + 12, oy + 11), tav["id"], at=(ox + 12, oy + 10))
        self.station("oven", (ox + 23, oy + 18), tav["id"], at=(ox + 24, oy + 17))
        self.station("stove", (ox + 22, oy + 18), tav["id"], at=(ox + 22, oy + 17))
        self.station("well", (ox + 15, oy + 25), None, at=(ox + 16, oy + 25))
        self.building("hut", ox + 8, oy + 1, 3, 3, (ox + 9, oy + 4), name="Sage's hut")
        self.paste_sample("village-2", 2 * CH, CH)
        ox = 2 * CH
        smithy = self.building("smithy", ox + 7, oy + 10, 16, 14, (ox + 11, oy + 24), name="Smithy and Armory")
        self.station("forge", (ox + 17, oy + 12), smithy["id"], at=(ox + 17, oy + 11))
        self.station("anvil", (ox + 18, oy + 14), smithy["id"], at=(ox + 17, oy + 13))
        self.station("workbench", (ox + 19, oy + 16), smithy["id"], at=(ox + 19, oy + 17))
        self.station("sawhorse", (ox + 18, oy + 15), smithy["id"], at=(ox + 17, oy + 15))
        self.station("armory_counter", (ox + 11, oy + 14), smithy["id"], at=(ox + 11, oy + 13))

        # row 0: mine highland (Shade's cave sample) between forests
        self.paste_sample("cave-1", CH, 0)
        self.ents["mine"] = {"entrance": [CH + 21, 15], "yard": [CH + 9, 22]}
        self.station("mine_cart", (CH + 9, 22), None, at=(CH + 9, 21))
        self.place_deposits(CH, 0)
        self.forest(0, 0, CH, CH, 0.16)
        self.forest(2 * CH, 0, CH, CH, 0.15)
        self.ents["woods"] = [{"id": "woods_w", "x": 1, "y": 1, "w": CH - 2, "h": CH - 2},
                              {"id": "woods_e", "x": 2 * CH + 1, "y": 1, "w": CH - 2, "h": CH - 2}]
        camp = (3 * CH + 14, 12)
        self.forest(3 * CH, 0, CH, CH, 0.15, clear=[(camp[0] - 4, camp[1] - 4, 9, 9)])
        self.put("below", 0, camp[0], camp[1], tile_val(0, CAMPFIRE))
        for dx, dy, t in ((-2, -1, CRATE), (2, -1, BARREL), (-2, 2, BARREL), (2, 2, CRATE)):
            self.put("below", 0, camp[0] + dx, camp[1] + dy, tile_val(0, t))
        self.ents["spawns"]["bandit_camp"] = [camp[0], camp[1] + 1]

        # rows 1-2: generated house districts, market and farms
        homes = []
        for cx, cy in ((3, 1), (0, 2), (3, 2)):
            ox, oy = cx * CH, cy * CH
            for j in range(2):
                for i in range(3):
                    homes.append(self.house(ox + 1 + i * 10, oy + 2 + j * 14))
            self.forest(ox, oy, CH, CH, 0.06)
        # market square with stalls, plus two houses
        ox, oy = CH, 2 * CH
        for i in range(2):
            homes.append(self.house(ox + 1 + i * 20, oy + 2))
        self.market(ox + 4, oy + 15)
        for i, kind in enumerate(PENS):
            self.pen(kind, ox + 1 + i * 7, oy + 20, 7, 6)
        # farms
        ox = 2 * CH
        for j in range(3):
            for i in range(2):
                self.field(ox + 2 + i * 14, oy + 2 + j * 9, 11, 6)
        self.forest(ox, oy, CH, CH, 0.03, clear=[(ox, oy, CH, CH - 2)])
        # plots the player can buy and build on: two clearings at the forest edge north of the east
        # houses (generator v1 put them over houses b20-b22). Only the trees standing on them are
        # removed, after the forests, so every other tree stays where v1 put it.
        self.plots(((3 * CH, 20), (3 * CH + 17, 20)))
        self.ents["spawns"]["player"] = [CH + 14, CH + 23]
        self.roads()
        self.containers()
        self.interiors()
        return self

    def containers(self):
        """Interactable containers, read from the tiles already placed (no random numbers, so the rest
        of the map is unchanged): crates and barrels by each house (its household's store), in and
        around the tavern (its keepers' stock) and beside each market stall (the stall's), and each
        dish or mug drawn on a tavern table (a table the tavern keepers set food on)."""
        out = self.ents["containers"]

        def scan(at, x0, y0, x1, y1, dishes):
            for y in range(y0, y1):
                for x in range(x0, x1):
                    below = [self.get("below", i, x, y) for i in range(6)]
                    above = [self.get("above", i, x, y) for i in range(6)]
                    kind, dish = None, None
                    if any(v in CRATE_TILES for v in below):
                        kind = "crate"
                    elif any(v in BARREL_TILES for v in below):
                        kind = "barrel"
                    elif dishes and any(v in DISH_TILES for v in above):
                        kind = "table"
                        i = next(i for i, v in enumerate(above) if v in DISH_TILES)
                        dish = {"dish": DISH_TILES[above[i]], "tile": above[i], "layer": f"above{i}"}
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
        so no tree, building, plot, road or container moves): Shade's hidden tavern and smithy roofs,
        beds in the small houses, the sage's hut's inner cell cleared, then for each building the cells
        under its roof reached from its doors (`area`), the walkable ones (`floor`, made walkable here),
        its roof tiles (faded by the game while the player is inside) and its use spots: beds, straw
        pallets (homes get SLEEP_PLACES sleeping places), tables, hearths and chests."""
        for name, dx, dy in HIDDEN_ROOFS:
            self.paste_hidden_roof(name, dx * CH, dy * CH)
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

    def paste_hidden_roof(self, name, ox, oy):
        """The roof group Shade drew for a sample map but left hidden in Tiled: its first layer (the
        roof itself) into above3, its roof objects (chimneys, dormers) into above4 and its fence into above5."""
        d = json.loads(self.paid.text(SAMPLE.format(name)))
        group = next(g for g in d["layers"] if g["type"] == "group" and g["name"] == "Roof")
        for j, lay in enumerate(l for l in group["layers"] if l["type"] == "tilelayer"):
            for i, g in enumerate(lay["data"]):
                t = (g & 0x1FFFFFFF) - 1
                if t < 0 or t >= PEOPLE_MIN:
                    continue
                x, y = ox + i % 30, oy + i // 30
                target = 3 + min(j, 2)
                assert self.get("above", target, x, y) < 0, f"roof tile over another at {(x, y)}"
                self.put("above", target, x, y, tile_val(0, t))
                self.late_roof.add((x, y))

    def furnish_house(self, b):
        """Beds in Shade's small house (HOUSE_BEDS), where his straw mat, shelf and jars stood."""
        ox, oy = b["x"], b["y"]
        assert self.get("below", 1, ox + 1, oy + 2) in CHEST_TILES, "not Shade's small house"
        for x, y in HOUSE_CLEAR:
            for cat, i in (("below", 1), ("above", 0), ("above", 1)):
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

    def place_deposits(self, ox, oy):
        """Ore rocks on bare highland floor of the cave sample: cells with only ground tiles whose
        ground is rock (not grass), at least one tile from cliffs."""
        rng = self.rng
        cands = []
        layers = self.sample("cave-1")
        ground = [d for n, d in layers if self.category(n) == "ground"]
        grass_ids = set(dict(self.sample("village-1"))["Grass 1"]) | set(dict(layers)["Roof/Grass Top"])
        for y in range(2, 28):
            for x in range(2, 28):
                X, Y = ox + x, oy + y
                if self.has_object(X, Y) or any(self.get("above", i, X, Y) >= 0 for i in range(4)):
                    continue
                top = [d[y * 30 + x] for d in ground if d[y * 30 + x] >= 0]
                if not top or top[-1] in grass_ids:
                    continue        # grass, not rock floor
                if any(self.has_object(X + dx, Y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    continue
                cands.append((X, Y))
        rng.shuffle(cands)
        plan = ["iron_ore", "coal", "stone", "iron_ore", "copper_ore", "coal", "iron_ore", "stone"] * 5 + ["gold_ore"]
        taken = []
        for ore in plan:
            for c in cands:
                if all(abs(c[0] - t[0]) + abs(c[1] - t[1]) >= 2 for t in taken):
                    taken.append(c)
                    cands.remove(c)
                    self.put("below", 0, c[0], c[1], tile_val(0, ORE[ore]))
                    self.ents["deposits"].append({"x": c[0], "y": c[1], "ore": ore,
                                                  "amount": {"gold_ore": 8, "stone": 80, "coal": 50,
                                                             "copper_ore": 30}.get(ore, 60)})
                    break

    def market(self, x0, y0):
        """Open square: a row of stalls (table + crate/barrel) facing a central lane."""
        tables = dict(self.sample("village-3"))["Floor 1/Objects"]
        table = tables[22 * 30 + 6]          # wooden table from the tavern terrace
        for i in range(6):
            x = x0 + 2 + i * 4
            for (dx, dy, t) in ((0, 0, table), (1, 0, CRATE if i % 2 else BARREL)):
                self.put("below", 0, x + dx, y0 + dy, tile_val(0, t))
            self.ents["stalls"].append({"id": f"stall{i}", "x": x, "y": y0, "use": [x, y0 + 1]})

    def field(self, x, y, w, h):
        self.ents["fields"].append({"id": f"f{len(self.ents['fields'])}", "x": x, "y": y, "w": w, "h": h})
        for j in range(h):
            for i in range(w):
                self.put("path", 1, x + i, y + j, tile_val(0, FIELD_TILES["ripe"]))

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

    def plots(self, corners):
        for i, (x, y) in enumerate(corners):
            p = {"id": f"plot{i}", "x": x, "y": y, "w": 9, "h": 10, "door": [x + 4, y + 9], "price": 60}
            self.ents["plots"].append(p)
            # clear the land: trees whose trunk or canopy is on the plot
            for t in [t for t in self.ents["trees"]
                      if x <= t["x"] < x + 9 and y <= t["y"] <= y + 10]:
                self.put("below", 0, t["x"], t["y"], -1)
                self.put("above", 0, t["x"], t["y"] - 1, -1)
                self.put("above", 0, t["x"], t["y"], -1)
                self.ents["trees"].remove(t)

    # ---- collision and roads ----------------------------------------------------------------
    def solid_grid(self):
        solid = [[False] * W for _ in range(H)]
        for y in range(H):
            for x in range(W):
                c = (x, y)
                s = (self.has_object(x, y) and c not in self.decor) or c in self.roof
                if c in self.walkable_override or c in self.floor:
                    s = False
                solid[y][x] = s
        for p in self.ents["plots"]:                      # plots are clear land
            for y in range(p["y"], p["y"] + p["h"]):
                for x in range(p["x"], p["x"] + p["w"]):
                    solid[y][x] = False
        return solid

    def roads(self):
        solid = self.solid_grid()
        targets = [tuple(b["door"]) for b in self.ents["buildings"]]
        targets += [tuple(s["use"]) for s in self.ents["stalls"]]
        targets += [tuple(self.ents["mine"]["yard"]), tuple(self.ents["spawns"]["bandit_camp"])]
        targets += [(f["x"] + f["w"] // 2, f["y"] + f["h"]) for f in self.ents["fields"]]
        targets += [tuple(p["door"]) for p in self.ents["plots"]]
        targets += [tuple(p["feed_at"]) for p in self.ents["pens"]]
        hub = tuple(self.ents["spawns"]["player"])
        assert not solid[hub[1]][hub[0]], "road hub must be walkable"
        road = {hub}
        dirs = ((0, -1), (1, 0), (0, 1), (-1, 0))
        for t in sorted(targets, key=lambda c: abs(c[0] - hub[0]) + abs(c[1] - hub[1])):
            if solid[t[1]][t[0]]:
                continue
            dist, prev, heap = {t: 0}, {}, [(0, t)]
            end = None
            while heap:
                d, c = heapq.heappop(heap)
                if c in road:
                    end = c
                    break
                if d > dist[c]:
                    continue
                for dx, dy in dirs:
                    n = (c[0] + dx, c[1] + dy)
                    if not (0 <= n[0] < W and 0 <= n[1] < H) or solid[n[1]][n[0]]:
                        continue
                    nd = d + (1 if n in road else 3)
                    if nd < dist.get(n, 1e9):
                        dist[n], prev[n] = nd, c
                        heapq.heappush(heap, (nd, n))
            if end is None:
                continue
            path = [end]
            while path[-1] != t:
                path.append(prev[path[-1]])
            road.update(path)
        self.road = road
        _, _, _, _, paths = self.free
        grass = set(dict(self.sample("village-1"))["Grass 1"])
        for (x, y) in road:
            grounds = [self.get("ground", i, x, y) for i in range(6)]
            grounds = [g for g in grounds if g >= 0]
            if (x, y) in self.walkable_override or not all(g >= FREE or g in grass for g in grounds):
                continue            # sample dirt, rock, floors or a doorway: keep the original art
            con = tuple((x + dx, y + dy) in road for dx, dy in dirs)
            key = con if con in paths["dirt"] else None
            if key is None:
                continue
            self.put("path", 0, x, y, tile_val(1, self.rng.choice(paths["dirt"][key])))

    # ---- output -----------------------------------------------------------------------------
    def workshop_stamp(self, kind, house):
        """A workshop stamp (WORKSHOPS): the house stamp with its sleeping places cleared and the
        stations' tiles copied in from where Shade drew them, with the collision, interior and
        stations to match. Reads only the finished map, draws no random numbers."""
        w, h = house["w"], house["h"]
        layers = {k: list(v) for k, v in house["layers"].items()}
        solid = [list(row) for row in house["solid"]]
        it = house["interior"]
        beds = [tuple(s["at"]) for s in it["spots"] if s["kind"] == "bed"]
        posts = [tuple(p) for _, p, _, _ in HOUSE_BEDS]
        for x, y in beds + posts:
            for name in list(layers):
                v = layers[name][y * w + x]
                if (name != "below0" or v == tile_val(0, MAT)) and name not in ROOF_LAYERS and not name.startswith("path"):
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

    def to_json(self):
        solid = self.solid_grid()
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
            if cat == "ground":
                continue
            cells = [data[(hb["y"] + y) * W + hb["x"] + x] for y in range(hb["h"]) for x in range(hb["w"])]
            if any(v >= 0 for v in cells):
                stamp["layers"][f"{cat}{i}"] = cells
        # its interior and collision in the house's own cells, for a house built anywhere
        local = lambda c: [c[0] - hb["x"], c[1] - hb["y"]]
        it = hb["interior"]
        stamp["interior"] = {k: [local(c) for c in it[k]] for k in ("doors", "area", "floor", "roof")}
        stamp["interior"]["spots"] = [{**sp, "at": local(sp["at"]), "use": local(sp["use"])} for sp in it["spots"]]
        stamp["solid"] = ["".join("1" if solid[hb["y"] + y][hb["x"] + x] else "0" for x in range(hb["w"]))
                          for y in range(hb["h"])]
        stamps = {"house": stamp}
        for kind in WORKSHOPS:
            stamps["workshop_" + kind] = self.workshop_stamp(kind, stamp)
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
            **self.ents,
        }


def render(data, solid=False):
    """Preview PNG of a built village (and optionally its collision)."""
    from PIL import Image
    paid = AssetZip(PAID).image("PUNY-WORLD-PAID_v1/Tiled/punyworld-tiles.png").convert("RGBA")
    free = pwt.load(AssetZip(pwt.ZIP))[0].convert("RGBA")
    cozy = AssetZip("CozyFarm_full_version.zip").image("full version/tiles/tiles.png").convert("RGBA")
    sheets = [(paid, 220), (free, free.width // 16), (cozy, COZY_COLS)]
    img = Image.new("RGBA", (W * 16, H * 16), (0, 0, 0, 255))
    cache = {}
    for lay in data["layers"]:
        for i, v in enumerate(lay["data"]):
            if v < 0:
                continue
            if v not in cache:
                sheet, cols = sheets[v // FREE]
                t = v % FREE
                cache[v] = sheet.crop(((t % cols) * 16, (t // cols) * 16, (t % cols) * 16 + 16, (t // cols) * 16 + 16))
            img.alpha_composite(cache[v], ((i % W) * 16, (i // W) * 16))
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
