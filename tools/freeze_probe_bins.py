"""B42 (B25-MOVE-STUTTER-INV): a freeze_probe.gd CSV summarised in time bins: frames, p50/p90 wall ms, counts of frames
over 33/50/100 ms, memory at the bin's end, and the five costliest parts (mean ms a frame).
    python3 tools/freeze_probe_bins.py OUT.csv [BIN_SECONDS]
"""
import csv
import statistics
import sys


def q(a, p):
    a = sorted(a)
    return a[min(len(a) - 1, int(p * len(a)))] if a else 0


def main():
    rows = list(csv.DictReader(open(sys.argv[1])))[30:]
    bins = int(sys.argv[2]) if len(sys.argv) > 2 else 30
    parts = [k for k in rows[0] if k.startswith(("w:", "m:"))]
    print("t_bin  y-range      frames  p50   p90  >33 >50 >100  mem_mb | top parts, mean ms a frame")
    for b in range(0, int(float(rows[-1]["t_game"])) + 1, bins):
        r = [x for x in rows if b <= float(x["t_game"]) < b + bins]
        if not r:
            continue
        w = [float(x["wall_ms"]) for x in r]
        means = {k: statistics.mean(float(x[k]) for x in r) for k in parts}
        top = sorted(means.items(), key=lambda kv: -kv[1])[:5]
        print("%4d %5.0f-%5.0f %6d %5.1f %5.1f %3d %3d %3d %7s | %s" % (
            b, float(r[0]["y"]), float(r[-1]["y"]), len(r), q(w, .5), q(w, .9), sum(v > 33 for v in w),
            sum(v > 50 for v in w), sum(v > 100 for v in w), r[-1].get("mem_mb", ""),
            ", ".join("%s %.1f" % (k[:24], v) for k, v in top)))


if __name__ == "__main__":
    main()
