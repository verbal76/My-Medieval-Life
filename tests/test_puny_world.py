"""Tests for the Puny World generator: rivers, roads, bridges and .tmj export."""
import io
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from assetzip import REPO, AssetZip  # noqa: E402
import puny_world_terrain as pwt  # noqa: E402
from puny_world_features import CONNECTORS, DIRS, add, neg  # noqa: E402
import render_tmj  # noqa: E402

ASSETS = pwt.load(AssetZip(pwt.ZIP))
SHEET, COLS, IDS, TILES, PATHS = ASSETS
SEEDS = range(1, 9)
W, H = 64, 44


def build(seed, **kw):
    return pwt.build_map(W, H, seed, assets=ASSETS, **kw)


class PunyWorldTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.maps = {s: build(s) for s in SEEDS}

    def test_deterministic(self):
        for seed in (1, 5):
            a, fa = build(seed)
            self.assertEqual(a, self.maps[seed][0])
            self.assertEqual(fa.summary(), self.maps[seed][1].summary())
        self.assertNotEqual(self.maps[1][0], self.maps[2][0])

    def test_terrain_only_still_works(self):
        layers, feat = build(3, rivers=0, sites=0)
        self.assertFalse(feat.stream or feat.road or feat.bridges)
        self.assertEqual(len(layers["Ground"]), W * H)

    def test_every_tile_is_a_known_tile(self):
        known_ground = {t for ts in TILES.values() for t in ts}
        known_ground |= {t for kind in PATHS.values() for ts in kind.values() for t in ts}
        known_ground |= {c[0] for c in CONNECTORS.values()} | {302}
        for seed, (layers, _) in self.maps.items():
            self.assertTrue(all(t in known_ground for t in layers["Ground"]), seed)
            self.assertTrue(all(t == -1 or t in known_ground for t in layers["Trees"]), seed)
            self.assertTrue(set(layers["Bridges"]) <= {-1, 848, 876}, seed)

    def test_every_map_has_rivers_and_roads(self):
        for seed, (_, feat) in self.maps.items():
            self.assertGreaterEqual(len(feat.rivers), 1, seed)
            self.assertGreaterEqual(len(feat.roads), 1, seed)

    def test_stream_and_road_edges_agree(self):
        """No half-joined edges: a gap or dangling stub in a stream or road."""
        for seed, (_, feat) in self.maps.items():
            for grid in (feat.stream, feat.road):
                for c, dirs in grid.items():
                    for d in dirs:
                        n = add(c, d)
                        if not feat.inside(n):
                            self.assertTrue(feat.on_edge(c), (seed, c))
                            continue
                        if n in feat.connectors:
                            self.assertIs(grid, feat.stream, (seed, c))
                            continue
                        self.assertIn(neg(d), grid.get(n, ()), (seed, c, d))

    def test_connectors_open_onto_their_stream(self):
        for seed, (_, feat) in self.maps.items():
            for c, tid in feat.connectors.items():
                opening = next(d for d, (t, _) in CONNECTORS.items() if t == tid)
                body = tuple(k in feat.body for k in
                             [c, (c[0] + 1, c[1]), (c[0] + 1, c[1] + 1), (c[0], c[1] + 1)])
                self.assertEqual(body, CONNECTORS[opening][1], (seed, c))
                self.assertIn(neg(opening), feat.stream.get(add(c, opening), ()), (seed, c))

    def test_river_body_has_no_missing_tiles(self):
        river, grass = IDS["river"], IDS["grass"]
        for seed, (_, feat) in self.maps.items():
            for y in range(H):
                for x in range(W):
                    c = (x, y)
                    if feat.touches_body(c) and c not in feat.connectors:
                        key = tuple(river if k in feat.body else grass for k in
                                    [(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)])
                        self.assertIn(key, TILES, (seed, c))

    def test_rivers_are_continuous_and_end_sensibly(self):
        for seed, (_, feat) in self.maps.items():
            main = feat.rivers[0]
            self.assertTrue(feat.on_edge(main[-1]), seed)
            for river in feat.rivers:
                for a, b in zip(river, river[1:]):
                    self.assertEqual(abs(a[0] - b[0]) + abs(a[1] - b[1]), 1, seed)

    def test_bridges_cross_straight_streams(self):
        for seed, (_, feat) in self.maps.items():
            for c, tid in feat.bridges.items():
                water = feat.stream[c]
                self.assertEqual(len(water), 2, (seed, c))
                d = next(iter(water))
                self.assertIn(neg(d), water)
                self.assertEqual(tid, 848 if d in ((1, 0), (-1, 0)) else 876)

    def test_all_sites_are_linked_by_road(self):
        for seed, (_, feat) in self.maps.items():
            # road graph: edges between joined road cells, plus across bridges
            links = {}
            for c, dirs in feat.road.items():
                links.setdefault(c, set()).update(add(c, d) for d in dirs if add(c, d) in feat.road)
            for b in feat.bridges:
                ends = [add(b, d) for d in DIRS if add(b, d) in feat.road and add(b, d) not in feat.stream]
                for e in ends:
                    links.setdefault(e, set()).update(x for x in ends if x != e)
            sites = [(s["x"], s["y"]) for s in feat.sites]
            seen, todo = {sites[0]}, [sites[0]]
            while todo:
                for n in links.get(todo.pop(), ()):
                    if n not in seen:
                        seen.add(n)
                        todo.append(n)
            self.assertTrue(all(s in seen for s in sites), seed)

    def test_tmj_round_trip_renders_identically(self):
        """The exported .tmj, opened next to the real .tsx, renders the same image."""
        layers, _ = self.maps[3]
        tmj = pwt.to_tmj(layers, W, H)
        self.assertEqual([l["name"] for l in tmj["layers"]], ["Ground", "Trees", "Bridges"])
        for l in tmj["layers"]:
            self.assertEqual(len(l["data"]), W * H)
        src = zipfile.ZipFile(REPO / pwt.ZIP)
        with tempfile.TemporaryDirectory() as tmp:
            zpath = Path(tmp) / "map.zip"
            with zipfile.ZipFile(zpath, "w") as z:
                for name in (pwt.TSX, "PUNY_WORLD_v1/PUNY_WORLD_v1/punyworld-overworld-tileset.png"):
                    z.writestr(name, src.read(name))
                z.writestr("PUNY_WORLD_v1/PUNY_WORLD_v1/Tiled/gen.tmj", json.dumps(tmj))
            via_tiled = render_tmj.render(AssetZip(str(zpath)), "PUNY_WORLD_v1/PUNY_WORLD_v1/Tiled/gen.tmj")
        direct = pwt.render(layers, W, H, SHEET, COLS)
        self.assertEqual(via_tiled.tobytes(), direct.tobytes())


if __name__ == "__main__":
    unittest.main()
