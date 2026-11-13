"""Summarise a freeze_probe.gd CSV (B25-MOVE-STUTTER-INV): frame-time distribution, long frames and what each was spent on,
their periodicity (seconds, world ticks, tiles walked), and frames that took more than one world tick (catch-up).

    python3 tools/freeze_probe_report.py out.csv [--skip 30] [--long 33] [--top 25]

Standard library only. Reads the CSV the probe writes; changes nothing.
"""
import argparse
import csv
import statistics


def pct(xs, p):
    xs = sorted(xs)
    if not xs:
        return 0.0
    k = (len(xs) - 1) * p / 100.0
    lo = int(k)
    hi = min(lo + 1, len(xs) - 1)
    return xs[lo] + (xs[hi] - xs[lo]) * (k - lo)


def load(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--skip", type=int, default=30, help="first frames left out (loading)")
    ap.add_argument("--long", type=float, default=33.0)
    ap.add_argument("--top", type=int, default=25)
    a = ap.parse_args()
    rows = load(a.csv)[a.skip:]
    parts = [k for k in rows[0] if k.startswith("w:") or k.startswith("m:")]
    wall = [float(r["wall_ms"]) for r in rows]
    print("frames %d (after skipping %d)" % (len(rows), a.skip))
    print("wall ms: mean %.2f p50 %.2f p90 %.2f p99 %.2f p99.9 %.2f max %.2f" % (
        statistics.mean(wall), pct(wall, 50), pct(wall, 90), pct(wall, 99), pct(wall, 99.9), max(wall)))
    for lim in (16.7, 33.0, 50.0, 100.0, 200.0):
        print("  frames over %5.1f ms: %d" % (lim, sum(1 for x in wall if x > lim)))
    # tick frames vs others
    tick = [float(r["wall_ms"]) for r in rows if int(r["ticks"]) > 0]
    notick = [float(r["wall_ms"]) for r in rows if int(r["ticks"]) == 0]
    if tick:
        print("frames with a world tick: %d, wall p50 %.2f p90 %.2f max %.2f; without: %d, p50 %.2f p90 %.2f max %.2f" % (
            len(tick), pct(tick, 50), pct(tick, 90), max(tick), len(notick), pct(notick, 50), pct(notick, 90), max(notick)))
        wt = [float(r["m:world.update"]) for r in rows if int(r["ticks"]) > 0]
        print("  world.update on tick frames: p50 %.2f p90 %.2f p99 %.2f max %.2f ms" % (pct(wt, 50), pct(wt, 90), pct(wt, 99), max(wt)))
    multi = [r for r in rows if int(r["ticks"]) > 1]
    print("frames that took more than one world tick (catch-up): %d" % len(multi))
    for r in multi[:10]:
        print("   frame %s t=%s delta %s ms ticks %s step %s tiles" % (r["frame"], r["t_game"], r["delta_ms"], r["ticks"], r["step"]))
    by_place = {}
    for r in rows:
        by_place.setdefault(r["where"].split(":")[0], []).append(float(r["wall_ms"]))
    for k, xs in sorted(by_place.items()):
        print("  %-10s %6d frames p50 %.2f p90 %.2f p99 %.2f max %.2f over33 %d" % (
            k, len(xs), pct(xs, 50), pct(xs, 90), pct(xs, 99), max(xs), sum(1 for x in xs if x > 33)))
    # mean of each part on tick and non-tick frames
    print("mean ms per part, tick frames / other frames:")
    for k in parts:
        t = [float(r[k]) for r in rows if int(r["ticks"]) > 0]
        o = [float(r[k]) for r in rows if int(r["ticks"]) == 0]
        if (t and max(t) > 0.05) or (o and max(o) > 0.05):
            print("  %-60s %7.2f / %7.2f   (max %.1f)" % (k, statistics.mean(t) if t else 0, statistics.mean(o) if o else 0,
                                                    max([float(r[k]) for r in rows])))
    longs = [r for r in rows if float(r["wall_ms"]) > a.long]
    print("long frames (> %.0f ms): %d" % (a.long, len(longs)))
    prev = None
    walked = 0.0
    walked_at = {}
    for r in rows:
        walked += float(r["step"])
        walked_at[r["frame"]] = walked
    gaps_s, gaps_tiles = [], []
    for r in longs:
        if prev is not None:
            gaps_s.append(float(r["t_game"]) - float(prev["t_game"]))
            gaps_tiles.append(walked_at[r["frame"]] - walked_at[prev["frame"]])
        prev = r
    if gaps_s:
        print("  interval between long frames: game s p50 %.2f (min %.2f max %.2f); tiles walked p50 %.2f" % (
            pct(gaps_s, 50), min(gaps_s), max(gaps_s), pct(gaps_tiles, 50)))
    for r in sorted(longs, key=lambda r: -float(r["wall_ms"]))[: a.top]:
        top = sorted(((float(r[k]), k) for k in parts if k != "m:world.update" and float(r[k]) > 2.0), reverse=True)[:4]
        acc = sum(float(r[k]) for k in parts if k.startswith("m:") and not k.startswith(("m:ss:", "m:ow:")))
        print("  %7.1f ms frame %s t=%ss %02d:%s ticks %s %s (%s,%s) chunks %s ms tiles+%s; main parts %.1f, outside main %.1f: %s" % (
            float(r["wall_ms"]), r["frame"], r["t_game"], int(r["hour"]), "%02d" % (int(float(r["minutes"])) % 60), r["ticks"],
            r["where"], r["x"], r["y"], r["chunks_built_ms"], r["tiles_made"], acc, float(r["wall_ms"]) - acc,
            ", ".join("%s %.1f" % (k[2:], v) for v, k in top)))


if __name__ == "__main__":
    main()
