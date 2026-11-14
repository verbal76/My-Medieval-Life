"""B42 (B25-MOVE-STUTTER-INV): the long frames of a freeze_probe.gd CSV, each put down to its costliest named part.
    python3 tools/freeze_probe_spikes.py OUT.csv [THRESHOLD_MS=50]
Leaf parts only (the sums such as m:world.update and m:player_step are not used when their pieces are there)."""
import collections
import csv
import sys

SUMS = {"m:world.update", "m:player_step", "m:sync_sprites (incl. ow_view.follow)", "m:ss:ow_view.follow", "m:ps:find_target",
        "w:villagers (all)"}


def main():
    rows = list(csv.DictReader(open(sys.argv[1])))[30:]
    th = float(sys.argv[2]) if len(sys.argv) > 2 else 50.0
    parts = [k for k in rows[0] if k.startswith(("w:", "m:")) and k not in SUMS]
    by = collections.Counter()
    worst = collections.defaultdict(float)
    for x in rows:
        wall = float(x["wall_ms"])
        if wall <= th:
            continue
        k, v = max(((k, float(x[k])) for k in parts), key=lambda kv: kv[1])
        named = sum(float(x[k]) for k in parts if k.startswith("m:") and not k.startswith(("m:ps:", "m:ft:", "m:ss:", "m:ow:")))
        if int(x["tiles_made"]) > 0:
            k = "tile made (TileSet change)"
        elif v < 0.3 * wall:
            k = "unnamed (outside main._process: engine, draw, GC) [%s]" % k
        by[k] += 1
        worst[k] = max(worst[k], wall)
    total = sum(by.values())
    print("frames over %.0f ms: %d" % (th, total))
    for k, n in by.most_common():
        print("  %4d  worst %6.1f ms  %s" % (n, worst[k], k))


if __name__ == "__main__":
    main()
