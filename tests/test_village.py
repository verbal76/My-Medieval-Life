"""game/data/village.json is what tools/build_village.py writes (generator v6), and a coherent village:
deterministic, no tree tiles in any layer, everything reachable on foot, chests by their owners."""
import json
import sys
import unittest
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import build_village  # noqa: E402

D = build_village.build()
W, H = D["w"], D["h"]


def solid_grid():
    s = [[c == "1" for c in row] for row in D["solid"]]
    for t in D["trees"]:
        s[t["y"]][t["x"]] = True          # the trunk (the game sets it from the tree's stage)
    return s


def reach(solid, start):
    seen, q = {start}, deque([start])
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if 0 <= n[0] < W and 0 <= n[1] < H and n not in seen and not solid[n[1]][n[0]]:
                seen.add(n)
                q.append(n)
    return seen


class VillageTest(unittest.TestCase):
    def test_committed_file_is_generated_and_deterministic(self):
        self.assertEqual(json.loads(build_village.OUT.read_text()), D)
        self.assertEqual(build_village.build(), D)

    def test_trails_lay_no_grass_over_dirt(self):
        """GP-TRAIL-EDGES (generator v10): no trail cell's pathway tile lays its grass notches or fringes over the dirt
        of a yard (Village.road_over_dirt, checked over every road cell drawn with a pathway tile); a road cell that
        would has joined the yard, its ground dirt and no pathway tile drawn."""
        v = build_village.Village(1).build()
        drawn = [c for c in sorted(v.road) if c not in v.yard and c not in v.walkable_override]
        self.assertGreater(len(drawn), 500)
        self.assertEqual([c for c in drawn if v.road_over_dirt(c)], [])
        path0 = next(l["data"] for l in D["layers"] if l["name"] == "path0")
        self.assertEqual([c for c in sorted(v.road) if c in v.yard and path0[c[1] * W + c[0]] >= 0], [])
        self.assertEqual(sorted(map(tuple, D["road"])), sorted(v.road))     # the road itself is unchanged: only its art

    def test_every_door_has_a_trail(self):
        """GP-BACK-DOORS (generator v10): every door of every building that opens outside (front, back or side; seen
        or under a roof) has its step on a road, a yard or a drawn door trail, joined to the village's roads."""
        v = build_village.Village(1).build()
        doors = v.outer_doors()
        self.assertGreaterEqual(len(doors), 30)
        ways = v.road | v.yard | v.trail
        self.assertEqual(sorted(map(tuple, D["door_trails"])), sorted(v.trail))
        self.assertTrue(v.trail.isdisjoint(v.road))           # drawn only: the roads the villagers walk are as before
        net, todo = {(62, 57)}, [(62, 57)]
        while todo:
            x, y = todo.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in ways and n not in net:
                    net.add(n)
                    todo.append(n)
        cut = [(b, door) for b, door, step in doors if step not in net]
        self.assertEqual(cut, [])
        self.assertIn(("b2", (38, 38), (38, 37)), doors)          # the tavern's back door (the owner's screenshot)
        self.assertIn(("b4", (81, 40), (81, 39)), doors)          # the smithy's back door

    def test_every_interior_is_walled(self):
        """GP-INTERIOR-WALLS (generator v12, owner: "why is the right wall missing"): round every building's interior the
        ring of cells just outside it is wall (solid) or one of its doors, on every side, so with the roof lifted the floor
        never runs into the grass. Before v12 the smithy's east side (x = 83) was open ground: the lane."""
        open_sides = {}
        for b in D["buildings"]:
            it = b.get("interior")
            if not it:
                continue
            area = {tuple(c) for c in it["area"]}
            doors = {tuple(c) for c in it.get("doors", [])}
            for (x, y) in area:
                if (x, y) in doors:
                    continue
                for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if n not in area and n not in doors and D["solid"][n[1]][n[0]] == "0":
                        open_sides.setdefault(b["id"], set()).add(n)
        self.assertGreaterEqual(sum(1 for b in D["buildings"] if b.get("interior")), 25)
        self.assertEqual(open_sides, {})
        smithy = next(b for b in D["buildings"] if b["id"] == "b4")
        self.assertEqual(smithy["w"], 17)
        self.assertTrue(all(D["solid"][y][83] == "1" for y in range(40, 49)))     # its east wall

    def test_containers_named_as_drawn(self):
        """GP-TARGET-ART-MATCH (generator v13): every container's prompt name (its `look`, else its kind) is what the art
        at its cell shows: a crate only on a crate tile, a barrel on a barrel, a woodpile, a plank pile, a counter; tables
        carry a dish drawn on them."""
        W = D["w"]
        layers = {l["name"]: l["data"] for l in D["layers"]}
        wrong = []
        for c in D["containers"]:
            tiles = [layers["below%d" % i][c["y"] * W + c["x"]] % 100000 for i in range(6) if layers["below%d" % i][c["y"] * W + c["x"]] >= 0]
            name = c.get("look", c["kind"])
            if c["kind"] == "table":
                if c.get("tile") is None or c["tile"] % 100000 not in tiles:
                    wrong.append((c["id"], name, tiles))
                continue
            drawn = [build_village.CONTAINER_LOOKS[t] for t in tiles if t in build_village.CONTAINER_LOOKS]
            if not drawn or drawn[0] != name:
                wrong.append((c["id"], name, tiles))
        self.assertEqual(wrong, [])
        self.assertEqual(next(c for c in D["containers"] if c["id"] == "c21").get("look"), "counter")      # the tavern's (the owner's report)

    def test_built_rooms_have_floors(self):
        """Every interior floor cell of a stamp the player builds (house, workshops, rooms) has a floor
        tile, so a room built on grass never shows grass inside, under its beds either."""
        for name, st in D["stamps"].items():
            w = st["w"]
            grounds = [v for k, v in st["layers"].items() if k.startswith("ground") and k != "ground0"]
            bare = [c for c in st["interior"]["floor"] if not any(g[c[1] * w + c[0]] >= 0 for g in grounds)]
            self.assertEqual(bare, [], name)

    def test_no_tree_tiles_in_any_layer(self):
        tops = {t for p in D["tiles"]["canopy"] for t in p}
        for lay in D["layers"]:
            if lay["z"] == "ground":
                continue
            for v in lay["data"]:
                if v >= 0 and v < build_village.FREE:
                    self.assertFalse(build_village.is_tree_tile(v), f"tree tile {v} in {lay['name']}")
                    self.assertNotIn(v, tops)

    def test_trees_stand_on_open_cells(self):
        roads = {tuple(c) for c in D["road"]}
        cells = {(t["x"], t["y"]) for t in D["trees"]}
        self.assertEqual(len(cells), len(D["trees"]))
        for x, y in cells:
            self.assertNotIn((x, y), roads)
            self.assertFalse(D["solid"][y][x] == "1", f"tree on a solid cell {(x, y)}")
            self.assertFalse(any((x + dx, y + dy) in cells for dx, dy in ((1, 0), (0, 1), (1, 1), (1, -1))), "trees never touch")

    def test_everything_is_reachable_on_foot(self):
        solid = solid_grid()
        hub = tuple(D["spawns"]["player"])
        town = reach(solid, hub)
        for b in D["buildings"]:
            self.assertIn(tuple(b["door"]), town, b["id"])
            self.assertTrue(any(tuple(c) in town for c in b["interior"]["doors"]), b["id"])
            for sp in b["interior"]["spots"]:
                self.assertIn(tuple(sp["use"]), town, (b["id"], sp))
        for s in D["stations"]:
            self.assertIn(tuple(s["use"]), town, s["id"])
        for p in D["plots"]:
            self.assertIn(tuple(p["door"]), town)
        for p in D["pens"]:
            self.assertIn(tuple(p["feed_at"]), town)
        for s in D["stalls"]:
            self.assertIn(tuple(s["use"]), town)
        for c in D["road"]:
            self.assertIn(tuple(c), town)
            self.assertFalse(solid[c[1]][c[0]])

    def test_plots_lie_on_open_ground_with_the_old_ones_remembered(self):
        """Generator v8 (ROOMS-18): the two plots stand on open ground, off every road, building, field and
        pen, with a lane to the road and the ring round them free of trees; the old sites stay in
        legacy_plots (a saved world keeps its plots there), still clear of trees."""
        roads = {tuple(c) for c in D["road"]}
        trees = {(t["x"], t["y"]) for t in D["trees"]}
        self.assertEqual([(p["x"], p["y"]) for p in D["legacy_plots"]], list(build_village.LEGACY_PLOTS))
        self.assertEqual([(p["x"], p["y"]) for p in D["plots"]], list(build_village.PLOTS))
        for p in D["plots"]:
            cells = {(x, y) for y in range(p["y"], p["y"] + p["h"]) for x in range(p["x"], p["x"] + p["w"])}
            self.assertFalse(cells & roads, p["id"])
            self.assertFalse(cells & trees, p["id"])
            for key in ("buildings", "fields", "pens"):
                for e in D[key]:
                    ecells = {(x, y) for y in range(e["y"], e["y"] + e["h"]) for x in range(e["x"], e["x"] + e["w"])}
                    self.assertFalse(cells & ecells, (p["id"], e["id"]))
            self.assertIn((p["door"][0], p["door"][1] + 1), roads, "a lane runs to its door step")
        for p in D["legacy_plots"]:
            cells = {(x, y) for y in range(p["y"], p["y"] + p["h"]) for x in range(p["x"], p["x"] + p["w"])}
            self.assertFalse(cells & trees, "the old plots stay clear of trees")
            lanes = {c for lane in build_village.PLOT_LANES for c in build_village.road_cells(*lane)}
            self.assertFalse((cells & roads) - lanes, "and free of roads but the new plots' lanes (the view clears those)")

    def test_chapel_and_church_plot(self):
        """Generator v9 (DVW-B3-CHAPEL): a chapel (the small house) and the church's plot lie on open ground, off every other
        building, field, pen, plot and road; the chapel's door step has a lane to the north lane; the plot's gate opens onto
        ground reached from the village; no tree stands on either."""
        chapel = [b for b in D["buildings"] if b["type"] == "chapel"]
        self.assertEqual(len(chapel), 1)
        b = chapel[0]
        self.assertEqual((b["x"], b["y"]), build_village.CHAPEL_AT)
        plot = D["church_plot"][0]
        self.assertEqual((plot["x"], plot["y"], plot["w"], plot["h"]), build_village.CHURCH_PLOT)
        roads = {tuple(c) for c in D["road"]}
        trees = {(t["x"], t["y"]) for t in D["trees"]}
        cells = lambda e: {(x, y) for y in range(e["y"], e["y"] + e["h"]) for x in range(e["x"], e["x"] + e["w"])}
        mine = cells(b) | cells(plot)
        self.assertFalse(mine & trees)
        self.assertFalse(cells(plot) & roads)
        self.assertFalse(cells(b) & cells(plot))
        for key in ("buildings", "fields", "pens", "plots", "legacy_plots"):
            for e in D[key]:
                if e["id"] != b["id"]:
                    self.assertFalse(mine & cells(e), (key, e["id"]))
        ring = {(x, y) for y in range(b["y"] - 1, b["y"] + b["h"] + 1) for x in range(b["x"] - 1, b["x"] + b["w"] + 1)}
        for e in D["buildings"]:
            if e["id"] != b["id"]:
                self.assertFalse(ring & cells(e), "no roof touches the chapel's (%s): the roof fade treats touching roofs as one" % e["id"])
        self.assertIn((b["door"][0], b["door"][1]), roads, "a lane runs to the chapel's door step")
        solid = solid_grid()
        gate = tuple(plot["gate"])
        self.assertEqual(gate, (plot["x"] + plot["w"] // 2, plot["y"] + plot["h"] - 1))
        start = tuple(D["spawns"]["player"])
        seen = reach(solid, start)
        self.assertIn((gate[0], gate[1] + 1), seen, "the plot's gate opens onto ground reached from the village")
        self.assertIn((b["door"][0], b["door"][1]), seen)
        self.assertEqual(len(b["interior"]["doors"]) >= 1, True)

    def test_the_four_exits_run_to_the_edge(self):
        roads = {tuple(c) for c in D["road"]}
        self.assertEqual([c for c in roads if c[0] == 0], [(0, 57)])
        self.assertEqual([c for c in roads if c[0] == W - 1], [(W - 1, 57)])
        self.assertEqual([c for c in roads if c[1] == 0], [(62, 0)])
        self.assertEqual([c for c in roads if c[1] == H - 1], [(build_village.SOUTH_X, H - 1)])

    def test_mine_deposits_and_rails(self):
        solid = solid_grid()
        town = reach(solid, tuple(D["spawns"]["player"]))
        trees = {(t["x"], t["y"]) for t in D["trees"]}
        kinds = sorted(d["ore"] for d in D["deposits"])
        self.assertEqual(kinds, sorted(["iron_ore"] * 5 + ["coal"] * 4 + ["stone"] * 3 + ["copper_ore"] * 2 + ["gold_ore"]))
        for d in D["deposits"]:
            c = (d["x"], d["y"])
            self.assertNotIn(c, trees)
            self.assertTrue(solid[c[1]][c[0]], "a seam is a solid rock")
            self.assertTrue(any((c[0] + dx, c[1] + dy) in town for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))), d)
        rails = {build_village.RAIL_V, build_village.RAIL_TOP, build_village.RAIL_END}
        layer = next(l for l in D["layers"] if l["name"] == "below2")["data"]
        cells = [(i % W, i // W) for i, v in enumerate(layer) if v % build_village.FREE in rails and v < build_village.FREE]
        xs = {x for x, _ in cells}
        ys = sorted(y for _, y in cells)
        self.assertEqual(len(xs), 1)
        self.assertEqual(ys, list(range(ys[0], ys[-1] + 1)), "the track is one run")
        x = xs.pop()
        entrance = D["mine"]["entrance"]
        self.assertEqual((x, ys[0]), tuple(entrance), "the track begins at the adit's mouth")
        self.assertIn((x, ys[-1] + 1), town, "and ends in the open yard, not against rock")
        for c in cells:
            self.assertFalse(c in trees)
        self.assertIn(tuple(next(s for s in D["stations"] if s["type"] == "mine_cart")["at"]), cells, "the cart stands on the track")

    def test_chests_stand_by_their_owners(self):
        b = {x["id"]: x for x in D["buildings"]}
        stalls = {s["id"]: s for s in D["stalls"]}
        for c in D["containers"]:
            if c["at"] in stalls:
                s = stalls[c["at"]]
                near = abs(c["x"] - s["x"]) <= 2 and abs(c["y"] - s["y"]) <= 1
            else:
                o = b[c["at"]]
                near = o["x"] - 1 <= c["x"] <= o["x"] + o["w"] and o["y"] - 1 <= c["y"] <= o["y"] + o["h"] + 1
            self.assertTrue(near, c)
            # and no other building is nearer than its owner's
            for o in b.values():
                if o["id"] == c.get("at"):
                    continue
                self.assertFalse(o["x"] - 1 <= c["x"] <= o["x"] + o["w"] and o["y"] - 1 <= c["y"] <= o["y"] + o["h"], (c, o["id"]))

    def test_sawmill(self):
        saw = [b for b in D["buildings"] if b.get("name") == "Sawmill"]
        self.assertEqual(len(saw), 1)
        horses = [s for s in D["stations"] if s["type"] == "sawhorse"]
        self.assertEqual(len(horses), 1)
        self.assertEqual(horses[0]["building"], saw[0]["id"])
        self.assertEqual(len([s for s in D["stations"] if s["type"] == "workbench"]), 1)
        u = horses[0]["use"]
        self.assertIn(tuple(u), {tuple(c) for c in saw[0]["interior"]["floor"]})
        guard_spots = {tuple(c) for c in D["road"]}
        self.assertNotIn(tuple(u), guard_spots)

    def test_racks_and_tabletops_are_solid_and_under_the_player(self):
        """B8-015 / B8-025: the armory's racks are decoration (nothing can be taken from them): their cells,
        tops included, are solid, and the tops of tables, benches and racks are in the below layers
        (drawn under the characters), so nobody can stand under half an object."""
        L = {l["name"]: l["data"] for l in D["layers"]}
        racks = [i for i, v in enumerate(L["below1"]) if v in (1026, 1027, 1029) and 69 <= i % W <= 74 and 47 <= i // W <= 52]
        self.assertTrue(racks)
        for i in racks:
            self.assertEqual(D["solid"][i // W][i % W], "1")
        for name in ("below3", "below4"):
            for i, v in enumerate(L.get(name, [])):
                if v >= 0:
                    self.assertEqual(D["solid"][i // W][i % W], "1", f"{name} top at {(i % W, i // W)} is a solid object")


if __name__ == "__main__":
    unittest.main()
