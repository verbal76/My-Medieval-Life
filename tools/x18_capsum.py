"""Summarise X18-SIM capability runs (economy_sim.gd --cap-report --cap-at 30,60) into the section 5 metrics tables.

Reads the "CAPABILITY@30", "CAPABILITY@60" and final "CAPABILITY" lines, the day-N sample line (alive, deaths) and the
LEAKS / FATAL lines of each log, and prints markdown. Analysis only; it changes nothing.

    python3 tools/x18_capsum.py LOGDIR GROUP...
A GROUP is "title|day|tag:Name,tag:Name,..." (day 30, 60 or 90).  With no group, prints a one-line status per log.
"""
import json
import os
import re
import sys

OK_LEAKS = "LEAKS: currency 0; items {}; deposits []; animals {}"


def load(logdir, tag, day):
    p = os.path.join(logdir, tag + ".log")
    if not os.path.exists(p):
        return None
    cap = None
    sample = None
    leaks = None
    fatal = None
    final = None
    for line in open(p, errors="replace"):
        if line.startswith("CAPABILITY@%d " % day):
            cap = json.loads(line.split(" ", 1)[1])
        elif line.startswith("CAPABILITY ") and day == final_day(p):
            cap = json.loads(line.split(" ", 1)[1])
        elif re.match(r"day\s+%d:" % day, line):
            sample = line
        elif line.startswith("LEAKS:"):
            leaks = line.strip()
        elif line.startswith("FATAL"):
            fatal = line.strip()
    if cap is None:
        return None
    m = re.search(r"alive (\d+) \(starved (\d+), other deaths (\d+)\)", sample or "")
    cap["_alive"], cap["_starved"], cap["_other"] = (int(x) for x in m.groups()) if m else (cap["alive"], 0, 0)
    cap["_leaks"] = leaks
    cap["_fatal"] = fatal
    return cap


_FD = {}


def final_day(p):
    if p not in _FD:
        d = 0
        for line in open(p, errors="replace"):
            m = re.match(r"day\s+(\d+):", line)
            if m:
                d = int(m.group(1))
        _FD[p] = d
    return _FD[p]


def row(c):
    u = c["units"]
    return {
        "out": sum(u.values()), "units": u, "pwd": c["units_per_worker_day"],
        "pay": sum(c["labour_pay"].values()), "cost": sum(c["production_cost"].values()),
        "profit": c["business"]["profit"], "losing": c["business"]["losing"], "broke": c["business"]["broke"],
        "purse": c["households"]["purse_median"], "food": c["households"]["food_days_median"], "hhbroke": c["households"]["broke"],
        "gini": c["gini_households"], "left": sum(c["deposits_end"].values()), "start": sum(c["deposits_start"].values()),
        "ironuse": c["used"].get("iron_ore", 0), "loguse": c["used"].get("log", 0),
        "trade": c["caravan"]["in"] + c["caravan"]["out"], "deaths": c["_starved"] + c["_other"], "starved": c["_starved"],
        "missed": c["missed_meals_no_food"], "alive": c["_alive"], "nomoney": c["missed_meals_no_money"],
        "ok": c["_leaks"] == OK_LEAKS and not c["_fatal"], "pr": c["prices"],
    }


def table(logdir, day, items):
    rs = [load(logdir, t, day) for t, _ in items]
    names = [n for _, n in items]
    miss = [t for (t, _), r in zip(items, rs) if r is None]
    if miss:
        keep = [(i, r) for i, r in zip(items, rs) if r is not None]
        if not keep:
            return "missing: " + ", ".join(miss)
        names = [n for (_, n), _r in keep]
        rs = [r for _i, r in keep]
    rows = [row(r) for r in rs]
    out = ["| Metric | " + " | ".join(names) + " |", "|---|" + "---|" * len(names)]

    def add(label, f):
        out.append("| " + label + " | " + " | ".join(f(r) for r in rows) + " |")
    add("Production output (units, 6 industries)", lambda r: str(r["out"]))
    for ind in ["mining", "forestry", "farming", "smithing", "carpentry", "tanning"]:
        add("&nbsp;&nbsp;%s units (per worker-day)" % ind, lambda r, i=ind: "%d (%.2f)" % (r["units"][i], r["pwd"].get(i, 0)))
    add("Labour compensation (coins earned)", lambda r: str(r["pay"]))
    add("Production cost (coins spent)", lambda r: str(r["cost"]))
    add("Net business profit (losing / broke)", lambda r: "%d (%d / %d)" % (r["profit"], r["losing"], r["broke"]))
    add("Household purchasing power (median purse; food days; broke)", lambda r: "%d; %.2f; %d" % (r["purse"], r["food"], r["hhbroke"]))
    add("Gini of household purses", lambda r: "%.3f" % r["gini"])
    add("Resource depletion (ore+stone left / start; iron ore used; logs used)", lambda r: "%d / %d; %d; %d" % (r["left"], r["start"], r["ironuse"], r["loguse"]))
    add("Trade volume (caravan coins in + out)", lambda r: str(r["trade"]))
    add("Prices (wheat, plank, pickaxe, axe)", lambda r: "%s, %s, %s, %s" % tuple(r["pr"][k] for k in ("wheat", "plank", "pickaxe", "axe")))
    add("Economic failures (deaths; starved; meals missed no food / no money)", lambda r: "%d; %d; %d / %d" % (r["deaths"], r["starved"], r["missed"], r["nomoney"]))
    add("Alive", lambda r: str(r["alive"]))
    add("Ledger (LEAKS 0, no FATAL)", lambda r: "yes" if r["ok"] else "NO")
    note = ("\n(not yet available: %s)" % ", ".join(miss)) if miss else ""
    return "\n".join(out) + note


if __name__ == "__main__":
    logdir = sys.argv[1]
    groups = sys.argv[2:]
    if not groups:
        for f in sorted(os.listdir(logdir)):
            if f.endswith(".log"):
                p = os.path.join(logdir, f)
                txt = open(p, errors="replace").read()
                print(f[:-4], "day", final_day(p), "LEAKS ok" if OK_LEAKS in txt else "no final LEAKS", "FATAL" if "FATAL" in txt else "")
    for g in groups:
        title, day, spec = g.split("|")
        items = [tuple(x.split(":", 1)) for x in spec.split(",")]
        print("### " + title + "\n")
        print(table(logdir, int(day), items))
        print()
