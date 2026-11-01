"""Parse a long-sims job log (economy_sim) into per-checkpoint series and end totals. Usage: parse.py LOG OUT.json"""
import json, re, sys
RAW = open(sys.argv[1]).read().split("\n")
L = []
for l in RAW:
    if l.startswith("##[error]"):
        break                                  # the workflow re-prints the first error and 12 lines after it
    if "\x1b[36;1m" not in l:
        L.append(l)
out = {"days": [], "bandits": [], "judge": [], "deaths": [], "economy": [], "neighbours": [], "growth": []}
num = lambda pat, s, f=int: (lambda m: f(m.group(1)) if m else None)(re.search(pat, s))
for l in L:
    m = re.match(r"^day +(\d+): (.*)", l)
    if m:
        d, s = int(m.group(1)), m.group(2)
        hh = re.search(r"hh cash min/med/max (\d+)/(\d+)/(\d+)", s)
        out["days"].append({"day": d, "alive": num(r"alive (\d+)", s), "starved": num(r"starved (\d+)", s),
            "other_deaths": num(r"other deaths (\d+)", s), "food_days": num(r"food ([\d.]+) days", s, float),
            "hunger": num(r"mean hunger (\d+)", s), "unemployed": num(r"unemployed (\d+)", s),
            "hh_min": int(hh.group(1)) if hh else None, "hh_med": int(hh.group(2)) if hh else None, "hh_max": int(hh.group(3)) if hh else None,
            "treasury": num(r"treasury (\d+)", s), "coins": num(r"coins (\d+) \(leak", s), "leak": num(r"leak (-?\d+)\)", s),
            "item_leaks": num(r"item leaks (\d+)", s), "households": num(r" hh (\d+),", s), "houses": num(r"houses (\d+)", s),
            "traders_unable": num(r"traders unable to buy (\d+)", s)})
        continue
    if l.startswith("  neighbours:"):
        out["neighbours"].append({"day": out["days"][-1]["day"] if out["days"] else None, "people": num(r"neighbours: (\d+) people", l),
                                  "coins": num(r"people, (\d+) coins", l), "village_paid_net": num(r"village paid net (-?\d+)", l)})
    elif l.startswith("  growth:"):
        g = json.loads(l.split("growth:", 1)[1]); g["day"] = out["days"][-1]["day"] if out["days"] else None; out["growth"].append(g)
    elif l.startswith("BANDITS "): out["bandits"].append(json.loads(l[8:]))
    elif l.startswith("BANDIT_DEATH "): out["deaths"].append(json.loads(l[13:]))
    elif l.startswith("JUDGE "): out["judge"].append(json.loads(l[6:]))
    elif l.startswith("ECONOMY day"):
        out["economy"].append({"day": num(r"ECONOMY day (\d+)", l), "bytes": num(r"save bytes (\d+)", l), "knowledge": num(r"knowledge (\d+) entries", l),
                               "exact": "round trip exact true" in l, "breaches": num(r"claims breaches (\d+)", l)})
    for key in ("people:", "food:", "money:", "trade:", "currency:", "ledger flows:", "judgment:", "JUDGE_SAVE", "LE05", "=== seed", "fingerprint", "recorder:"):
        if l.startswith(key):
            out.setdefault("end", {})[key.rstrip(":")] = l
m = re.search(r'"script_errors": (\d+)', "\n".join(RAW)); out["script_errors"] = int(m.group(1)) if m else None
m = re.search(r'"exit_code": (\d+)', "\n".join(RAW)); out["exit_code"] = int(m.group(1)) if m else None
out["fatal"] = [l for l in L if l.startswith("FATAL")]
out["script_error_text"] = [l for l in RAW if l.startswith("SCRIPT ERROR") or l.strip().startswith("at: ") and "res://" in l][:4]
json.dump(out, open(sys.argv[2], "w"), indent=1)
d = out["days"]
print(sys.argv[1], "checkpoints", len(d), "first", d[0]["day"] if d else None, "last", d[-1]["day"] if d else None,
      "leaks", sorted(set((x["leak"], x["item_leaks"]) for x in d)), "script_errors", out["script_errors"], "fatal", len(out["fatal"]),
      "deaths", len(out["deaths"]), "judge", len(out["judge"]), "econ", len(out["economy"]))
