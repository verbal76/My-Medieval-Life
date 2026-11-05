"""Build 25 economic sustainability analysis (X20-ECON-SUSTAIN). Reads the parsed job logs (parse.py) and the sim.json
digests (digest.py, recover job on wip/val-recover) and writes report_data.json: per-run checkpoint series and end figures."""
import json
RUNS = [  # key, label, actions run, commit, settings, digest file, seed, parsed log (or None)
    ("N1", "Build 25 normal, seed 1", 41233948995, "ad281dc", "normal (economy off)", "digest_41233948995.json", 1, "normal_s1.json"),
    ("N2", "Build 25 normal, seed 2", 41233948995, "ad281dc", "normal (economy off)", "digest_41233948995.json", 2, "normal_s2.json"),
    ("E1", "Build 25 economy on, seed 1", 41233970504, "ad281dc", "--market (Living Economy on)", "digest_41233970504.json", 1, "econ_s1.json"),
    ("C1", "Chapel fix normal, seed 1", 41279031310, "ae8641d", "normal (economy off)", "digest_41279031310.json", 1, "p_chapel_normal_s1.json"),
    ("C2", "Chapel fix normal, seed 2", 41279031310, "ae8641d", "normal (economy off)", "digest_41279031310.json", 2, "p_chapel_normal_s2.json"),
    ("C3", "Chapel fix economy on, seed 1", 41279051834, "ae8641d", "--market (Living Economy on)", "digest_41279051834.json", 1, "p_chapel_econ_s1.json"),
    ("G1", "SJD-G soak (pre-calibration), seed 1", 41129188776, "d0f623b", "normal (judgment on)", "digest_41129188776.json", 1, None),
    ("G2", "SJD-G soak (pre-calibration), seed 2", 41129188776, "d0f623b", "normal (judgment on)", "digest_41129188776.json", 2, None),
    ("F1", "Judgment calibration branch, seed 1", 41166571846, "d99ec66", "normal", "digest_41166571846.json", 1, None),
    ("F2", "Judgment calibration branch, seed 2", 41166571846, "d99ec66", "normal", "digest_41166571846.json", 2, None),
    ("D1", "Bandit AI first behaviour, seed 1", 41171898332, "c664b31", "normal", "digest_41171898332.json", 1, None),
    ("D2", "Bandit AI first behaviour, seed 2", 41171898332, "c664b31", "normal", "digest_41171898332.json", 2, None),
    ("L1", "LE-06 economy on (pre LE-05), seed 1", 41143001791, "5319993", "--market", "digest_41143001791.json", 1, None),
    ("L2", "LE-06 economy on (pre LE-05), seed 2", 41143001791, "5319993", "--market", "digest_41143001791.json", 2, None),
]
out = {}
for key, label, run, commit, settings, dfile, seed, plog in RUNS:
    smp = [r for r in json.load(open(dfile)) if r["run"]["seed"] == seed][0]["samples"]
    ser = []
    for s in smp:
        h = s.get("holders") or {}; w = s.get("work") or {}; m = s.get("money") or {}; hc = m.get("household_cash") or {}
        p = s.get("people") or {}; f = s.get("food") or {}; t = s.get("trade") or {}; ev = s.get("events") or {}
        tot = h.get("total") or 0
        ser.append({"day": s["day"], "alive": p.get("alive"), "births": p.get("births"), "deaths": sum((p.get("deaths") or {}).values()),
                    "slain": (p.get("deaths") or {}).get("slain", 0), "starved": (p.get("deaths") or {}).get("starvation", 0),
                    "adults": w.get("adults"), "jobs": w.get("with_job"), "unemployed": w.get("unemployed"), "households": hc.get("n"),
                    "coins": tot, "chapel": h.get("chapel", 0), "villagers": h.get("villagers", 0), "treasury": h.get("treasury", 0),
                    "tills": h.get("stall_tills", 0), "loot": h.get("loot", 0), "contract_reserves": h.get("contract_reserves", 0),
                    "chapel_share": round(100.0 * h.get("chapel", 0) / tot, 1) if tot else 0.0,
                    "hh_median": hc.get("median"), "hh_min": hc.get("min"), "hh_max": hc.get("max"), "hh_total": hc.get("total"),
                    "merchant_funds": m.get("merchant_funds"), "tax": (m.get("gov") or {}).get("tax", 0), "wages": (m.get("gov") or {}).get("wages", 0),
                    "coin_sources": s.get("coin_sources_delta"), "food_days": f.get("days_of_need"), "missed_no_money": f.get("missed_meal_no_money"),
                    "missed_no_food": f.get("missed_meal_no_food_for_sale"), "relief_grain": f.get("relief_grain"), "caravans": t.get("caravans"),
                    "caravan_in": t.get("coins_in"), "caravan_out": t.get("coins_out"), "no_firewood_nights": ev.get("no_firewood_nights"),
                    "job_changes": w.get("job_changes"), "manor_taken": (s.get("manor_work") or {}).get("taken"),
                    "traders_zero": sum(v.get("zero", 0) for v in ((m.get("traders") or {}).values())),
                    "traders_n": sum(v.get("n", 0) for v in ((m.get("traders") or {}).values()))})
    rec = {"label": label, "run": run, "commit": commit, "settings": settings, "seed": seed, "series": ser, "end": ser[-1], "start": ser[0]}
    if plog:
        pl = json.load(open(plog))
        rec["script_errors"] = pl["script_errors"]; rec["script_error_text"] = pl.get("script_error_text", [])
        rec["leaks"] = sorted(set((d["leak"], d["item_leaks"]) for d in pl["days"]))
        rec["bandits"] = pl["bandits"][-1] if pl["bandits"] else None
        rec["bandit_deaths"] = pl["deaths"]
        rec["judge_end"] = {k: pl["judge"][-1][k] for k in ("n", "net", "stats")} if pl["judge"] else None
        rec["judge_series"] = [{"day": j["d"], "memories": j["n"]["memories"], "permanent": j["n"]["memories_permanent"], "net_p1": j["net"]["p1"],
                                "net_min": j["net"]["min"], "neg_zero_pos": j["net"]["neg_zero_pos"]} for j in pl["judge"]]
        rec["economy"] = pl["economy"]
        rec["end_lines"] = pl.get("end", {})
    out[key] = rec
json.dump(out, open("report_data.json", "w"), indent=1)
hdr = ["run", "alive", "births", "deaths", "slain", "adults", "jobs", "unemp", "hh", "coins", "chapel%", "hh_med", "food_days", "missed_food", "no_fire_nights", "caravans"]
print(" | ".join(hdr))
for k, r in out.items():
    e = r["end"]
    print(" | ".join(str(x) for x in [k, e["alive"], e["births"], e["deaths"], e["slain"], e["adults"], e["jobs"], e["unemployed"], e["households"], e["coins"], e["chapel_share"], e["hh_median"], e["food_days"], e["missed_no_food"], e["no_firewood_nights"], e["caravans"]]))
