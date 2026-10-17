"""Rivers, roads, bridges and settlement sites for puny_world_terrain.py.

Everything here follows how Shade's own free sample maps use the tileset:

* Streams are the "water-paths" edge wangset: opaque grass tiles with a
  one-tile-wide stream; every connection pattern (end, straight, bend, T,
  cross) exists, so any 4-connected course renders without gaps.
* Wide reaches use the "river" corner terrain, which only borders grass.
  A stream joins a wide reach through a connector tile: a river-edge tile
  with an opening on the side facing away from the river body.
* Roads are the "dirt-paths" edge wangset (also opaque grass tiles).
* A road crosses a stream only where the stream runs straight across its
  path; the stream tile stays and a bridge goes on an overlay layer. As in
  the sample, the road tiles next to a bridge are not joined to it.

River and road tiles replace ground tiles, so both are only placed on cells
whose four ground corners are grass or dirt (dirt is turned back to grass).
"""
import heapq

from puny_terrain import value_noise

N, E, S, W = (0, -1), (1, 0), (0, 1), (-1, 0)
DIRS = (N, E, S, W)

# connector tile -> (open side, river-body corners as (TL, TR, BR, BL) True=river)
CONNECTORS = {
    W: (301, (False, True, True, False)),
    E: (303, (True, False, False, True)),
    N: (275, (False, False, True, True)),
    S: (329, (True, True, False, False)),
}
ROCK_RIVER = 302          # full river tile with a rock, used as a rare variant
BRIDGE_NS = 848           # road running N-S over an E-W stream
BRIDGE_EW = 876           # road running E-W over a N-S stream (plank middle)


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def neg(d):
    return (-d[0], -d[1])


def corners_of(c):
    x, y = c
    return [(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)]  # TL, TR, BR, BL


class Features:
    def __init__(self, w, h, ground, height, ids, rng):
        self.w, self.h = w, h
        self.ground, self.height, self.ids, self.rng = ground, height, ids, rng
        self.land = {ids["grass"], ids["dirt"]}
        self.stream = {}        # cell -> set of water directions
        self.body = set()       # river corners (x, y)
        self.connectors = {}    # cell -> tile id
        self.road = {}          # cell -> set of road directions
        self.bridges = {}       # cell -> tile id
        self.sites = []
        self.rivers = []        # list of cell paths
        self.roads = []

    # ---- helpers -------------------------------------------------------
    def inside(self, c):
        return 0 <= c[0] < self.w and 0 <= c[1] < self.h

    def on_edge(self, c):
        return c[0] in (0, self.w - 1) or c[1] in (0, self.h - 1)

    def is_land(self, c):
        return self.inside(c) and all(self.ground[cy][cx] in self.land for cx, cy in corners_of(c))

    def cell_height(self, c):
        return sum(self.height[cy][cx] for cx, cy in corners_of(c)) / 4

    def touches_body(self, c):
        return any(k in self.body for k in corners_of(c))

    def busy(self, c):
        return c in self.stream or c in self.connectors or c in self.road or self.touches_body(c)

    def search(self, starts, goal, step_cost):
        """Dijkstra over cells. step_cost(prev, cur, nxt) -> cost or None.
        Returns the cheapest path from a start to a goal cell, or None."""
        dist, prev, heap, n = {}, {}, [], 0
        for s in starts:
            dist[s] = 0.0
            heap.append((0.0, n, s))
            n += 1
        heapq.heapify(heap)
        while heap:
            d, _, cur = heapq.heappop(heap)
            if d > dist.get(cur, float("inf")):
                continue
            if goal(cur):
                path = [cur]
                while path[-1] in prev:
                    path.append(prev[path[-1]])
                return path[::-1]
            for dd in DIRS:
                nxt = add(cur, dd)
                if not self.inside(nxt):
                    continue
                cost = step_cost(prev.get(cur), cur, nxt)
                if cost is None:
                    continue
                nd = d + cost
                if nd < dist.get(nxt, float("inf")):
                    dist[nxt], prev[nxt] = nd, cur
                    n += 1
                    heapq.heappush(heap, (nd, n, nxt))
        return None

    # ---- rivers --------------------------------------------------------
    def make_rivers(self, count=1, tributaries=1):
        meander = value_noise(self.w, self.h, self.rng, octaves=3, base=6)
        cells = [(x, y) for y in range(self.h) for x in range(self.w)]
        for _ in range(count):
            sources = sorted(
                (c for c in cells if self.is_land(c) and not self.busy(c)
                 and 5 <= c[0] < self.w - 5 and 5 <= c[1] < self.h - 5),
                key=lambda c: -self.cell_height(c))
            sources = sources[: max(1, len(sources) // 6)]
            self.rng.shuffle(sources)
            for src in sources[:12]:
                path = self.search(
                    [src], self.on_edge,
                    lambda p, c, n: self._river_cost(n, meander))
                if path and len(path) >= 10:
                    self._lay_river(path)
                    break
        for _ in range(tributaries):
            self._make_tributary(meander)

    def _river_cost(self, c, meander):
        if not self.is_land(c) or self.busy(c):
            return None
        # stay off cells beside other water so courses don't touch
        if any(self.busy(add(c, d)) for d in DIRS):
            return None
        return 1 + 6 * self.cell_height(c) + 4 * meander[c[1]][c[0]]

    def _lay_river(self, path):
        self.rivers.append(path)
        wide = self._pick_wide(path)
        for i in range(len(path) - 1):
            a, b = path[i], path[i + 1]
            d = (b[0] - a[0], b[1] - a[1])
            if a not in wide and a not in self.connectors:
                self.stream.setdefault(a, set()).add(d)
            if b not in wide and b not in self.connectors:
                self.stream.setdefault(b, set()).add(neg(d))
        end = path[-1]
        if end in self.stream:
            for d in DIRS:
                if not self.inside(add(end, d)):
                    self.stream[end].add(d)
                    break
        if len(path) == 1:
            self.stream.setdefault(path[0], set())

    def _pick_wide(self, path):
        """Choose up to two straight-ended stretches to widen into river body."""
        n = len(path)
        dirs = [(path[i + 1][0] - path[i][0], path[i + 1][1] - path[i][1]) for i in range(n - 1)]
        wide = set()
        for _ in range(40):
            if len(wide) >= 6 or n < 10:
                break
            length = self.rng.randint(4, 8)
            a = self.rng.randint(3, max(3, n - 4))
            b = min(a + length - 1, n - 1)
            if b - a < 3:
                continue
            reaches_edge = b == n - 1
            # connector before the stretch: path must run straight through it
            if not (dirs[a - 2] == dirs[a - 1] == dirs[a]):
                continue
            if not reaches_edge and not (b + 2 < n and dirs[b - 1] == dirs[b] == dirs[b + 1]):
                continue
            stretch = path[a: b + 1]
            if wide & set(path[a - 2: b + 3]):
                continue
            body = {k for c in stretch for k in corners_of(c)}
            # connector cell -> direction from it toward the river body
            conns = {path[a - 1]: dirs[a - 1]}
            if not reaches_edge:
                conns[path[b + 1]] = neg(dirs[b])
            if self._body_ok(body, set(stretch), conns, path):
                self.body |= body
                wide |= set(stretch)
                for cell, toward_body in conns.items():
                    self.connectors[cell] = CONNECTORS[neg(toward_body)][0]
        return wide

    def _body_ok(self, body, stretch, conns, path):
        body = body | self.body
        cells = {c for k in body for c in [(k[0] - 1, k[1] - 1), (k[0], k[1] - 1),
                                            (k[0] - 1, k[1]), (k[0], k[1])]}
        on_path = set(path)
        for c in cells:
            if not self.inside(c):
                continue
            if not self.is_land(c):
                return False
            key = tuple(k in body for k in corners_of(c))
            if c in conns:
                opening = neg(conns[c])
                if key != CONNECTORS[opening][1]:
                    return False
                continue
            if c in on_path and c not in stretch:
                return False          # the course would touch its own river body
            if c in self.stream or c in self.road or c in self.connectors:
                return False
            if key in ((True, False, True, False), (False, True, False, True)):
                return False          # diagonal patterns have no river tile
        return True

    def _make_tributary(self, meander):
        joinable = {c for c, ds in self.stream.items()
                    if len(ds) == 2 and c not in self.connectors and not self.touches_body(c)
                    and not self.on_edge(c)}
        if not joinable:
            return
        cells = [(x, y) for y in range(self.h) for x in range(self.w)]
        sources = sorted((c for c in cells if self.is_land(c) and not self.busy(c)
                          and all(not self.busy(add(c, d)) for d in DIRS)
                          and 4 <= c[0] < self.w - 4 and 4 <= c[1] < self.h - 4),
                         key=lambda c: -self.cell_height(c))
        sources = sources[: max(1, len(sources) // 5)]
        self.rng.shuffle(sources)

        def goal(c):
            return any(add(c, d) in joinable for d in DIRS)

        for src in sources[:10]:
            if min(abs(src[0] - j[0]) + abs(src[1] - j[1]) for j in joinable) < 8:
                continue
            path = self.search([src], goal, lambda p, c, n: self._trib_cost(n, meander, joinable))
            if not path or len(path) < 6:
                continue
            end = path[-1]
            target = next(add(end, d) for d in DIRS if add(end, d) in joinable)
            course = path + [target]
            self.rivers.append(course)
            for a, b in zip(course, course[1:]):
                d = (b[0] - a[0], b[1] - a[1])
                self.stream.setdefault(a, set()).add(d)
                self.stream.setdefault(b, set()).add(neg(d))
            return

    def _trib_cost(self, c, meander, joinable):
        if not self.is_land(c) or self.busy(c):
            return None
        near = [add(c, d) for d in DIRS if self.busy(add(c, d))]
        if near and not all(x in joinable for x in near):
            return None
        return 1 + 6 * self.cell_height(c) + 4 * meander[c[1]][c[0]]

    # ---- sites and roads ------------------------------------------------
    def make_sites(self, count=4, exits=1):
        cells = [(x, y) for y in range(self.h) for x in range(self.w)]
        ok = [c for c in cells
              if 3 <= c[0] < self.w - 3 and 3 <= c[1] < self.h - 3
              and all(self.is_land((c[0] + dx, c[1] + dy)) and not self.busy((c[0] + dx, c[1] + dy))
                      for dx in (-1, 0, 1) for dy in (-1, 0, 1))]
        if not ok:
            return
        self.rng.shuffle(ok)
        # keep every site inside the largest region a road can actually reach
        region, left = set(), set(ok)
        while left:
            r = self.road_region(min(left))
            left -= r
            if len(r) > len(region):
                region = r
        ok = [c for c in ok if c in region]
        chosen = [ok[0]]
        while len(chosen) < count:
            best = max(ok, key=lambda c: min(abs(c[0] - s[0]) + abs(c[1] - s[1]) for s in chosen)
                       + self.rng.random() * 3)
            if min(abs(best[0] - s[0]) + abs(best[1] - s[1]) for s in chosen) < 8:
                break
            chosen.append(best)
        self.sites = [{"x": c[0], "y": c[1], "kind": "settlement"} for c in chosen]
        edge = [c for c in cells if self.on_edge(c) and c in region and not self.busy(c)
                and all(not self.busy(add(c, d)) for d in DIRS)]
        self.rng.shuffle(edge)
        for c in edge[:exits]:
            self.sites.append({"x": c[0], "y": c[1], "kind": "exit"})

    def make_roads(self):
        pts = [(s["x"], s["y"]) for s in self.sites]
        if len(pts) < 2:
            return
        # Prim's MST on straight-line distance decides which places get linked
        linked, edges = {pts[0]}, []
        while len(linked) < len(pts):
            a, b = min(((a, b) for a in linked for b in pts if b not in linked),
                       key=lambda e: (e[0][0] - e[1][0]) ** 2 + (e[0][1] - e[1][1]) ** 2)
            edges.append((a, b))
            linked.add(b)
        for a, b in edges:
            path = self._route_road(a, b)
            if path:
                self._lay_road(path)

    def _road_moves(self, cur):
        """Yield (next cell, bridge cell or None, extra cost) for a road at cur.
        A stream is only crossed straight over a cell where it runs across the
        road; an existing bridge is reused cheaply, a new one costs more."""
        for dd in DIRS:
            nxt = add(cur, dd)
            if not self.inside(nxt):
                continue
            if nxt in self.stream and nxt not in self.connectors:
                perp = {(dd[1], dd[0]), (-dd[1], -dd[0])}
                land = add(nxt, dd)
                if self.stream[nxt] != perp or not self._road_ok(land):
                    continue
                # no bridges beside a spring: both upstream/downstream cells must flow on
                if any(len(self.stream.get(add(nxt, p), ())) < 2
                       for p in perp if self.inside(add(nxt, p)) and add(nxt, p) not in self.connectors):
                    continue
                if nxt in self.bridges:
                    yield land, nxt, 0.0
                elif not any(add(nxt, p) in self.bridges for p in perp):
                    yield land, nxt, 8.0
            elif self._road_ok(nxt):
                yield nxt, None, 0.0

    def road_region(self, start):
        """Cells reachable by road from start (used to keep sites linkable)."""
        seen, todo = {start}, [start]
        while todo:
            cur = todo.pop()
            for nxt, _, _ in self._road_moves(cur):
                if nxt not in seen:
                    seen.add(nxt)
                    todo.append(nxt)
        return seen

    def _route_road(self, a, b):
        dist, prev, heap, n = {a: 0.0}, {}, [(0.0, 0, a)], 1
        while heap:
            d, _, cur = heapq.heappop(heap)
            if d > dist.get(cur, float("inf")):
                continue
            if cur == b:
                path = [cur]
                while path[-1] in prev:
                    path.append(prev[path[-1]])
                return path[::-1]
            for nxt, via, extra in self._road_moves(cur):
                cost = (0.35 if nxt in self.road else 1.0) + extra + 2 * self.cell_height(nxt)
                nd = d + cost
                if nd < dist.get(nxt, float("inf")):
                    dist[nxt] = nd
                    if via:
                        prev[via], prev[nxt] = cur, via
                    else:
                        prev[nxt] = cur
                    n += 1
                    heapq.heappush(heap, (nd, n, nxt))
        return None

    def _road_ok(self, c):
        return (self.inside(c) and self.is_land(c) and c not in self.stream
                and c not in self.connectors and not self.touches_body(c))

    def _lay_road(self, path):
        self.roads.append(path)
        for i, c in enumerate(path):
            if c in self.stream:
                d = (path[i + 1][0] - c[0], path[i + 1][1] - c[1])
                self.bridges[c] = BRIDGE_NS if d in (N, S) else BRIDGE_EW
                continue
            self.road.setdefault(c, set())
            for j in (i - 1, i + 1):
                if 0 <= j < len(path) and path[j] not in self.stream:
                    self.road[c].add((path[j][0] - c[0], path[j][1] - c[1]))
        for s in (path[0], path[-1]):
            if any(s == (t["x"], t["y"]) and t["kind"] == "exit" for t in self.sites):
                for d in DIRS:
                    if not self.inside(add(s, d)):
                        self.road[s].add(d)
                        break

    # ---- applying to the map ------------------------------------------
    def claimed_cells(self):
        cells = set(self.stream) | set(self.road) | set(self.connectors)
        cells |= {c for k in self.body for c in [(k[0] - 1, k[1] - 1), (k[0], k[1] - 1),
                                                  (k[0] - 1, k[1]), (k[0], k[1])] if self.inside(c)}
        return cells

    def clear_ground_and_trees(self, over):
        """River/road cells get pure grass corners (their tiles have grass baked
        in); those cells, bridges and the area around sites lose their trees."""
        claimed = self.claimed_cells()
        for c in claimed:
            for cx, cy in corners_of(c):
                if self.ground[cy][cx] == self.ids["dirt"]:
                    self.ground[cy][cx] = self.ids["grass"]
        clear = claimed | set(self.bridges)
        for s in self.sites:
            clear |= {(s["x"] + dx, s["y"] + dy) for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2)}
        for c in clear:
            if self.inside(c):
                for cx, cy in corners_of(c):
                    over[cy][cx] = self.ids["air"]

    def summary(self):
        return {
            "sites": self.sites,
            "rivers": [[list(c) for c in p] for p in self.rivers],
            "roads": [[list(c) for c in p] for p in self.roads],
            "bridges": [{"x": c[0], "y": c[1], "tile": t} for c, t in sorted(self.bridges.items())],
        }
