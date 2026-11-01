"""X20-CHAPEL-FIX before-and-after report (HTML) from report_data.json (analyze.py), the chapel runs' parsed logs and digests."""
import json, html, os
from charts import line_chart
D = json.load(open("report_data.json"))
PAIRS = [("N1", "C1", "p_chapel_normal_s1.json", "digest_41279031310.json", 1), ("N2", "C2", "p_chapel_normal_s2.json", "digest_41279031310.json", 2)]
if "C3" in D:
    PAIRS.append(("E1", "C3", "p_chapel_econ_s1.json", "digest_41279051834.json", 1))
def ser(k, f): return [(p["day"], p[f]) for p in D[k]["series"]]
def n(v): return f"{v:,}" if isinstance(v, int) else (f"{v}" if v is not None else "n/a")
def pct(a, b): return f"{100.0*a/b:.0f}%" if b else "n/a"
P = {c: json.load(open(p)) for _, c, p, _, _ in PAIRS}
def quant(dfile, seed):
    smp = [r for r in json.load(open(dfile)) if r["run"]["seed"] == seed][0]["samples"]
    return [(s["day"], (s.get("money") or {}).get("household_cash") or {}) for s in smp]
Q = {c: quant(d, s) for _, c, _, d, s in PAIRS}

# ---- charts
share = line_chart([(D[b]["label"].replace("Build 25 ", "Before: "), c, ser(b, "chapel_share"), True) for (b, _, _, _, _), c in zip(PAIRS, ("c1", "c2", "c3"))] +
                   [(D[a]["label"].replace("Chapel fix ", "After: "), c, ser(a, "chapel_share"), False) for (_, a, _, _, _), c in zip(PAIRS, ("c1", "c2", "c3"))],
                   "Chapel's share of all coins", "percent", ymax=100, pct=True)
circ = "".join(line_chart([("Chapel fund", "c4", ser(k, "chapel"), False), ("Villagers' purses", "c2", ser(k, "villagers"), False),
                           ("Manor treasury", "c3", ser(k, "treasury"), False), ("All coins", "c5", ser(k, "coins"), True)],
                          D[k]["label"], "coins") for b, a, _, _, _ in PAIRS for k in (b, a))
hhmed = line_chart([(D[b]["label"].replace("Build 25 ", "Before: "), c, ser(b, "hh_median"), True) for (b, _, _, _, _), c in zip(PAIRS, ("c1", "c2", "c3"))] +
                   [(D[a]["label"].replace("Chapel fix ", "After: "), c, ser(a, "hh_median"), False) for (_, a, _, _, _), c in zip(PAIRS, ("c1", "c2", "c3"))],
                   "Median household cash", "coins")
spread = "".join(line_chart([("90th percentile", "c4", [(d, q.get("p90")) for d, q in Q[a]], False), ("75th", "c2", [(d, q.get("p75")) for d, q in Q[a]], False),
                             ("Median", "c1", [(d, q.get("median")) for d, q in Q[a]], False), ("25th", "c3", [(d, q.get("p25")) for d, q in Q[a]], False),
                             ("10th", "c5", [(d, q.get("p10")) for d, q in Q[a]], True)],
                            D[a]["label"] + ": household cash spread", "coins") for _, a, _, _, _ in PAIRS)
def flows(a):
    ch = P[a]["chapel"]; pts_in, pts_out, pts_w = [], [], []
    prev = {"offering_coins": 0, "alms_coins": 0, "wages": 0}
    for c in ch:
        st = c["stats"]
        pts_in.append((c["day"], st["offering_coins"] - prev["offering_coins"])); pts_out.append((c["day"], st["alms_coins"] - prev["alms_coins"]))
        pts_w.append((c["day"], st["wages"] - prev["wages"])); prev = st
    return line_chart([("Given (10 days)", "c1", pts_in, False), ("Alms paid (10 days)", "c3", pts_out, False), ("Clergy wages (10 days)", "c5", pts_w, True)],
                      D[a]["label"] + ": chapel money in and out", "coins")
flow = "".join(flows(a) for _, a, _, _, _ in PAIRS)

# ---- tables
def row(k):
    e, s = D[k]["end"], D[k]["start"]
    return (f'<tr><th scope="row">{html.escape(D[k]["label"])}</th><td>{n(e["alive"])}</td><td>{n(e["births"])}</td><td>{n(e["deaths"])}</td>'
            f'<td>{n(e["adults"])}</td><td>{n(e["jobs"])}</td><td>{n(e["unemployed"])} ({pct(e["unemployed"], e["adults"])})</td><td>{n(e["households"])}</td>'
            f'<td>{n(e["coins"])}</td><td>{e["chapel_share"]}%</td><td>{n(e["treasury"])}</td><td>{n(e["hh_median"])}</td><td>{e["food_days"]}</td>'
            f'<td>{n(e["missed_no_food"])}</td><td>{n(e["missed_no_money"])}</td><td>{n(e["no_firewood_nights"])}</td><td>{n(e["traders_zero"])} of {n(e["traders_n"])}</td></tr>')
head = ('<tr><th scope="col">Run (day 365)</th><th scope="col">Population</th><th scope="col">Births</th><th scope="col">Deaths</th><th scope="col">Adults</th>'
        '<th scope="col">Jobs</th><th scope="col">Unemployed</th><th scope="col">Households</th><th scope="col">All coins</th><th scope="col">Chapel share</th>'
        '<th scope="col">Treasury</th><th scope="col">Median household cash</th><th scope="col">Food (days)</th><th scope="col">Meals missed, none for sale</th>'
        '<th scope="col">Meals missed, no money</th><th scope="col">Nights without firewood</th><th scope="col">Traders with no coins</th></tr>')
endtbl = f'<div class="scroll"><table class="num">{head}{"".join(row(k) for b, a, _, _, _ in PAIRS for k in (b, a))}</table></div>'

def giving(a):
    c = P[a]["chapel"][-1]; st = c["stats"]; by = c["by_bracket"]
    r = (f'<tr><th scope="row">{html.escape(D[a]["label"])}</th><td>{n(st["services"])}</td><td>{n(st["present"])}</td><td>{n(st["unable"])} ({pct(st["unable"], st["present"])})</td>'
         f'<td>{n(st["considered"])}</td><td>{n(st["donors"])} ({pct(st["donors"], st["considered"])})</td><td>{n(st["declined"])} ({pct(st["declined"], st["considered"])})</td>'
         f'<td>{n(st["offering_coins"])}</td><td>{c["gift_mean_x100"]/100:.1f}</td><td>{n(c["gift_median"])}</td><td>{n(st["offering_wheat"])}</td>'
         f'<td>{n(st["wages"])}</td><td>{n(st["alms_coins"])}</td><td>{n(st["alms_households"])}</td><td>{n(c["fund"])}</td><td>{n(c["reserve_now"])}</td></tr>')
    return r
ghead = ('<tr><th scope="col">Run</th><th scope="col">Services</th><th scope="col">Present</th><th scope="col">Unable to spare</th><th scope="col">Decided</th>'
         '<th scope="col">Gave</th><th scope="col">Declined</th><th scope="col">Coins given</th><th scope="col">Mean gift</th><th scope="col">Median gift</th>'
         '<th scope="col">Wheat given</th><th scope="col">Clergy wages</th><th scope="col">Alms paid</th><th scope="col">Households helped (times)</th>'
         '<th scope="col">Fund, day 365</th><th scope="col">Reserve, day 365</th></tr>')
gtbl = f'<div class="scroll"><table class="num">{ghead}{"".join(giving(a) for _, a, _, _, _ in PAIRS)}</table></div>'
def bracket(a):
    by = P[a]["chapel"][-1]["by_bracket"]; o = []
    for b in ("poor", "modest", "comfortable"):
        x = by[b]; dec = x["donors"] + x["declined"]
        o.append(f'<tr><th scope="row">{html.escape(D[a]["label"])}, {b}</th><td>{n(x["present"])}</td><td>{n(x["unable"])} ({pct(x["unable"], x["present"])})</td>'
                 f'<td>{n(x["donors"])} ({pct(x["donors"], dec)})</td><td>{n(x["declined"])} ({pct(x["declined"], dec)})</td><td>{n(x["gift_coins"])}</td>'
                 f'<td>{x["gift_coins"]/x["donors"]:.1f}</td></tr>' if x["donors"] else
                 f'<tr><th scope="row">{html.escape(D[a]["label"])}, {b}</th><td>{n(x["present"])}</td><td>{n(x["unable"])}</td><td>0</td><td>{n(x["declined"])}</td><td>0</td><td>n/a</td></tr>')
    return "".join(o)
btbl = ('<div class="scroll"><table class="num"><tr><th scope="col">Run, household bracket</th><th scope="col">Present</th><th scope="col">Unable to spare</th>'
        '<th scope="col">Gave (of those deciding)</th><th scope="col">Declined</th><th scope="col">Coins given</th><th scope="col">Mean gift</th></tr>'
        + "".join(bracket(a) for _, a, _, _, _ in PAIRS) + "</table></div>")
def recips(a):
    ls = P[a]["chapel"][-1]["last_service"]
    rs = ls.get("recipients", [])
    rows = "".join(f'<tr><td>{r["household"]}</td><td>{r["bracket"]}</td><td>{r["members"]}</td><td>{n(r["wealth"])}</td><td>{n(r["line"])}</td><td>{n(r["cash_before"])}</td><td>{n(r["given"])}</td><td>{n(r["cash_after"])}</td></tr>' for r in rs)
    return (f'<h3>{html.escape(D[a]["label"])}: the last service (day {ls.get("day")})</h3><p>Fund before alms {n(ls.get("fund_before_alms"))}, reserve {n(ls.get("reserve"))}, alms {n(ls.get("alms"))} to {len(rs)} households.</p>'
            '<div class="scroll"><table class="num"><tr><th scope="col">Household</th><th scope="col">Bracket</th><th scope="col">Members</th><th scope="col">Wealth</th>'
            f'<th scope="col">Two-week line</th><th scope="col">Cash before</th><th scope="col">Given</th><th scope="col">Cash after</th></tr>{rows}</table></div>')
rtbl = "".join(recips(a) for _, a, _, _, _ in PAIRS)
runs = "".join(f'<tr><td>{html.escape(D[k]["label"])}</td><td><a href="https://github.com/verbal76/My-Medieval-Life/actions/runs/{D[k]["run"]}">{D[k]["run"]}</a></td><td><code>{D[k]["commit"]}</code></td><td>{html.escape(D[k]["settings"])}</td><td>{n(D[k].get("script_errors"))}</td><td>{html.escape(str(D[k].get("leaks")))}</td></tr>' for b, a, _, _, _ in PAIRS for k in (b, a))

open("chapel_parts.json", "w").write(json.dumps({"share": share, "circ": circ, "hhmed": hhmed, "spread": spread, "flow": flow, "endtbl": endtbl, "gtbl": gtbl, "btbl": btbl, "rtbl": rtbl, "runs": runs}))
print("parts", {k: len(v) for k, v in json.load(open("chapel_parts.json")).items()}, "pairs", [p[1] for p in PAIRS])
