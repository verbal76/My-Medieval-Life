"""Build the Build 25 validation and economic sustainability report (HTML) from report_data.json."""
import json, html
from charts import line_chart
D = json.load(open("report_data.json"))
def ser(k, f): return [(p["day"], p[f]) for p in D[k]["series"]]
def n(v): return f"{v:,}" if isinstance(v, int) else (f"{v}" if v is not None else "n/a")
B25 = ["N1", "N2", "E1"]; BASE = ["G1", "G2", "F1", "F2", "D1", "D2", "L1", "L2"]
def end(k, f): return D[k]["end"][f]
def pct(a, b): return f"{100.0*a/b:.0f}%" if b else "n/a"

# ---- charts
pop = "".join(line_chart([("Population", "c1", ser(k, "alive"), False), ("Adults", "c2", ser(k, "adults"), False),
                          ("With a job", "c3", ser(k, "jobs"), False), ("Unemployed adults", "c4", ser(k, "unemployed"), False)],
                         D[k]["label"], "people") for k in B25)
coins = "".join(line_chart([("Chapel fund", "c4", ser(k, "chapel"), False), ("Villagers' purses", "c2", ser(k, "villagers"), False),
                            ("Manor treasury", "c3", ser(k, "treasury"), False), ("All coins", "c5", ser(k, "coins"), True)],
                           D[k]["label"], "coins") for k in B25)
share = line_chart([(D[k]["label"].replace("Build 25 ", "B25 "), c, ser(k, "chapel_share"), False) for k, c in (("N1", "c1"), ("N2", "c2"), ("E1", "c3"))] +
                   [("Earlier runs (8)", "c5", ser(k, "chapel_share"), True) for k in BASE[:1]] +
                   [("", "c5", ser(k, "chapel_share"), True) for k in BASE[1:]], "Chapel's share of all coins, every run", "percent", ymax=100, pct=True)
share = share.replace('<span class="key"><i class="sw c5 dash"></i></span>', "")
hh = line_chart([(D[k]["label"].replace("Build 25 ", "B25 "), c, ser(k, "hh_median"), False) for k, c in (("N1", "c1"), ("N2", "c2"), ("E1", "c3"))],
                "Median household cash", "coins")
mig_note = {"N1": (170, 49, 146), "N2": (124, 70, 99), "E1": (138, 25, 110)}

def row(k):
    e, s = D[k]["end"], D[k]["start"]
    return (f'<tr><th scope="row">{html.escape(D[k]["label"])}</th><td>{n(s["alive"])} → {n(e["alive"])}</td><td>{n(e["births"])}</td><td>{n(e["deaths"])}</td>'
            f'<td>{n(e["slain"])}</td><td>{n(e["adults"])}</td><td>{n(e["jobs"])}</td><td>{n(e["unemployed"])} ({pct(e["unemployed"], e["adults"])})</td>'
            f'<td>{n(s["households"])} → {n(e["households"])}</td><td>{n(e["coins"])}</td><td>{e["chapel_share"]}%</td><td>{n(s["hh_median"])} → {n(e["hh_median"])}</td>'
            f'<td>{e["food_days"]}</td><td>{n(e["missed_no_food"])}</td><td>{n(e["no_firewood_nights"])}</td></tr>')
table_head = ('<tr><th scope="col">Run</th><th scope="col">Population</th><th scope="col">Births</th><th scope="col">Deaths</th><th scope="col">Violent deaths</th>'
              '<th scope="col">Adults</th><th scope="col">Jobs</th><th scope="col">Unemployed</th><th scope="col">Households</th><th scope="col">All coins</th>'
              '<th scope="col">Chapel share</th><th scope="col">Median household cash</th><th scope="col">Food (days)</th><th scope="col">Meals missed, none for sale</th>'
              '<th scope="col">Nights without firewood</th></tr>')
def tbl(keys): return f'<div class="scroll"><table class="num">{table_head}{"".join(row(k) for k in keys)}</table></div>'
runs_tbl = "".join(f'<tr><td>{html.escape(D[k]["label"])}</td><td><a href="https://github.com/verbal76/My-Medieval-Life/actions/runs/{D[k]["run"]}">{D[k]["run"]}</a></td><td><code>{D[k]["commit"]}</code></td><td>{html.escape(D[k]["settings"])}</td></tr>' for k in B25 + BASE)

def bandit(k):
    b = D[k]["bandits"]; c = b["counts"]
    return (f'<tr><th scope="row">{html.escape(D[k]["label"])}</th><td>{b["seen"]}</td><td>{c["bandit_deaths"]}</td><td>{b["deaths_per_bandit_year"]}</td><td>{b["mean_lifespan_of_dead_days"]:.0f}</td>'
            f'<td>{c["retreats_survived"]} of {c["retreat_starts"]}</td><td>{c["robberies"]}</td><td>{c["robberies_nothing"]}</td><td>{c["rerob_same_victim"]}</td>'
            f'<td>{", ".join(f"{kk} {vv}" for kk, vv in b["deaths_by_phase"].items())}</td><td>{D[k]["end"]["slain"]}</td></tr>')
def judg(k):
    st = D[k]["judge_end"]["stats"]; nt = D[k]["judge_end"]["net"]; nn = D[k]["judge_end"]["n"]
    g = lambda a: st.get(a) or 0
    return (f'<tr><th scope="row">{html.escape(D[k]["label"])}</th><td>{n(g("trade_choices_changed"))} of {n(g("trade_choices"))} ({pct(g("trade_choices_changed"), g("trade_choices"))})</td>'
            f'<td>{n(g("trade_buy_from_changed"))} of {n(g("trade_buy_from_choices"))}</td><td>{n(g("contract_seller_changed"))} of {n(g("contract_seller_choices"))}</td>'
            f'<td>{n(g("food_seller_changed"))} of {n(g("food_seller_choices"))}</td><td>{n(g("tool_buy_changed"))} of {n(g("tool_buy_choices"))}</td>'
            f'<td>{n(g("befriend_held_back"))} of {n(g("befriend_checks"))}</td><td>{nt["abs_ge_10_25_50"][0]}</td><td>{n(nn["memories"])} ({n(nn["memories_permanent"])} permanent)</td></tr>')
judge_save = {"N1": (1044695, 7009076), "N2": (689129, 5644439), "E1": (1238421, 7846992)}
e1 = D["E1"]["end"]; n1 = D["N1"]["end"]

H = open("report_head.html").read()
body = f"""
<header class="top">
  <p class="eyebrow">My Medieval Life · Expansion 20 · Build 25 validation</p>
  <h1>Build 25 Year-Long Validation</h1>
  <p class="lede">Three 365-day simulations of commit <code>ad281dc</code>: what passed technically, and whether the village economy holds up over a year.</p>
  <dl class="meta"><div><dt>Commit</dt><dd><code>ad281dc9431b782582513ef8a083c962b5039b8f</code></dd></div>
  <div><dt>Runs</dt><dd><a href="https://github.com/verbal76/My-Medieval-Life/actions/runs/41233948995">41233948995</a> (normal, seeds 1 and 2) · <a href="https://github.com/verbal76/My-Medieval-Life/actions/runs/41233970504">41233970504</a> (economy on, seed 1)</dd></div>
  <div><dt>Prepared</dt><dd>1 November 2026, for the owner's review (X20-MERGED-VALIDATION, X20-ECON-SUSTAIN)</dd></div></dl>
</header>

<section id="summary"><h2>1. Executive summary</h2>
<div class="verdicts">
 <div class="verdict ok"><p class="vh">Technical integrity</p><p class="vv">Passed, with one defect</p><p>No coin or item was created or lost at any of 111 checkpoints. Every economy save loaded back exactly. One script error in normal seed 1 (gossip) fails the workflow; cause reproduced, two-line fix ready, not applied.</p></div>
 <div class="verdict warn"><p class="vh">Money circulation</p><p class="vv">Poor</p><p>By day 365 the chapel holds 77–83% of all coins. Its fund pays out only when a household lacks food, fuel, medicine or rent, which well-fed households never do, so the coins rarely return.</p></div>
 <div class="verdict bad"><p class="vh">Long-term sustainability</p><p class="vv">Not demonstrated</p><p>Population roughly triples, but the number of jobs stays at about 45. By the end 67–77% of adults are out of work, median household cash is 4–11 coins, and households barely form. No one starved.</p></div>
</div>
<p>The simulation runs a full year without breaking the books. That is not the same as a working economy. The village survives because food stays plentiful and relief exists. Money drains into the chapel, work does not grow with the people, and buying power collapses. These patterns appear in every earlier year-long run too, so they come from long-standing design, not from the Expansion 20 merges. The Living Economy, switched on in one run, does not change this: households wanted to bid 12,065 times and could not afford to.</p>
<p><b>Recommendation:</b> fix the gossip script error (category A) before freezing Build 25, then decide on the chapel's payout rule and on job and household growth (category B). Each needs your approval; none has been changed.</p>
</section>

<section id="runs"><h2>2. Runs and evidence</h2>
<div class="scroll"><table><tr><th scope="col">Run</th><th scope="col">Actions</th><th scope="col">Commit</th><th scope="col">Settings</th></tr>{runs_tbl}</table></div>
<p class="note">Earlier runs are the comparison baselines: the SJD-G judgment soak before calibration, the judgment-calibration branch, the first bandit behaviour, and the LE-06 economy-on run before LE-05. Checkpoint samples come from each run's <code>sim.json</code>, read back by a recover job that ran no simulation (branch <code>wip/val-recover</code>). Different commits and seeds follow different histories from day 0, so earlier runs show patterns, not exact before-and-after effects.</p>
</section>

<section id="results"><h2>3. Results at day 365</h2>
<h3>Build 25</h3>{tbl(B25)}
<h3>Earlier year-long runs</h3>{tbl(BASE)}
<p class="note">Violent deaths are villagers recorded as slain; the logs do not record who killed them. Nights without firewood count household-nights. Unemployed means adults with no job.</p>
</section>

<section id="population"><h2>4. Population and employment</h2>
<div class="grid3">{pop}</div>
<ul>
<li><b>Growth comes from births and hungry newcomers.</b> Normal seed 1 took in {mig_note["N1"][0]} people and lost {mig_note["N1"][1]}; {mig_note["N1"][2]} of the newcomers left neighbouring settlements because of hunger. Seed 2: {mig_note["N2"][0]} in ({mig_note["N2"][2]} for hunger), {mig_note["N2"][1]} out. Economy on: {mig_note["E1"][0]} in ({mig_note["E1"][2]} for hunger), {mig_note["E1"][1]} out.</li>
<li><b>Jobs do not grow.</b> The number of adults with a job stays between 40 and 63 all year in every run while adults rise from 60 to 140–199. Every earlier run shows the same, with 41 to 66 jobs at day 365.</li>
<li><b>Households barely form.</b> 25 households at day 0 become 26–29 by day 365 while the population reaches 279–363. In normal seed 1, 22 households are crowded at the end and 55 single adults have no room to marry into.</li>
<li><b>No starvation in any Build 25 run.</b> The pre-calibration soak's seed 1 did starve (81 deaths); its chapel was drained to 0.5% of coins, which shows the fund does pay out when food runs short.</li>
</ul>
</section>

<section id="money"><h2>5. Coins: conservation and circulation</h2>
<h3>Conservation (technical)</h3>
<p>Coin leak 0, holder mismatch 0 and item leaks 0 at all 37 checkpoints of each run. Coin sources from outside (caravans and settlements) added 3,323, 3,600 and 3,488 coins. In the economy-on run the rental escrow ended at 0 with no open rentals, claims breaches were 0, and all 37 economy saves loaded back exactly (economy save 486–648 KB).</p>
<h3>Circulation</h3>
<div class="grid3">{coins}</div>
<div class="grid2">{share}{hh}</div>
<p><b>How coins reach the chapel.</b> On each weekly service day, villagers at or above a piety threshold give a share of their coins above their reserve. <b>How coins leave it.</b> Clergy wages (two low-paid people), food it buys for relief when a household asks, and alms. Alms go only to households short of their "necessity reserve": the coins needed for food, firewood, medicine and rent they lack, after counting what the pantry and members already hold (<code>World.necessity</code>, <code>Chapel.alms</code>). A household with a full pantry needs nothing by that measure, however few coins it has. With 10–25 days of food in store, almost no household qualifies, so the fund keeps growing. The code comment cites your rule: "offerings keep the priest, and what is left goes as alms to the poorest households." The implementation keeps what is left unless a household is short.</p>
<p class="note">Not recorded in these runs: the chapel's own donation, alms and relief totals (kept only as world statistics, not in the samples), the full spread of household cash (only minimum, median, maximum and total), prices, and per-business profit.</p>
</section>

<section id="trade"><h2>6. Production, trade and household purchasing power</h2>
<ul>
<li><b>Food is plentiful.</b> 10–25 days of food at day 365; meals missed because the household had no money: {D["N1"]["end"]["missed_no_money"]}, {D["N2"]["end"]["missed_no_money"]} and {e1["missed_no_money"]}; missed because none was for sale: {n1["missed_no_food"]}, {D["N2"]["end"]["missed_no_food"]} and {e1["missed_no_food"]}.</li>
<li><b>Firewood is short.</b> 4,022–4,988 household-nights without firewood per run (earlier runs: 2,543–4,668). The consequence for health or warmth is not recorded.</li>
<li><b>Traders end broke.</b> At day 365, 12 of the 15–18 traders (cooks, merchants, smiths, tanners, tavern keepers) hold no coins.</li>
<li><b>Trade outside continues.</b> 182 caravans per run. Caravans brought in 4,809, 4,504 and 4,790 coins and took out 2,051, 1,086 and 1,498.</li>
<li><b>Manor work.</b> The manor's jobs were taken 283, 382 and 289 times; it paid 6,790–7,794 coins in wages and collected 7,462–8,476 in tax over the year.</li>
</ul>
<p class="note">Not recorded: prices over time, business formation and failure in the village, wages per worker, profitability, and the value of stolen goods.</p>
</section>

<section id="bandits"><h2>7. Bandits and judgment</h2>
<h3>Bandit intelligence</h3>
<div class="scroll"><table class="num"><tr><th scope="col">Run</th><th scope="col">Bandits seen</th><th scope="col">Bandit deaths</th><th scope="col">Deaths per bandit-year</th><th scope="col">Mean life of the dead (days)</th><th scope="col">Retreats survived</th><th scope="col">Robberies</th><th scope="col">Took nothing</th><th scope="col">Same victim again</th><th scope="col">Deaths by phase</th><th scope="col">Villagers slain</th></tr>{"".join(bandit(k) for k in B25)}</table></div>
<p>Before the bandit work, the same seeds saw 234 and 143 bandit deaths a year, from a re-robbing loop and no retreat. Now bandits die 9–20 times a year, survive 73–80% of retreats, rob each victim once, and defend one another (383, 61 and 581 defend choices). Most deaths come while retreating after a fight, not during a robbery. Villagers slain: 10, 0 and 9 (the first bandit version gave 42 and 33; before the bandit work, 0, because bandits never fought back). The logs do not record who killed each villager.</p>
<h3>Judgment and social decisions</h3>
<div class="scroll"><table class="num"><tr><th scope="col">Run</th><th scope="col">Sales: seller changed by judgment</th><th scope="col">Timber purchases changed</th><th scope="col">Contract seller changed</th><th scope="col">Food seller changed</th><th scope="col">Tool purchases changed</th><th scope="col">Friendships held back</th><th scope="col">Opinions beyond ±10 points</th><th scope="col">Memories</th></tr>{"".join(judg(k) for k in B25)}</table></div>
<p>Judgment now changes 5–12% of sales choices (0.3% before calibration) and most contract seller choices, where the old rule had no real preference. It refused no contract, credit or work: need outweighs dislike, as you asked. No runaway hostility: at most 8 opinions pass ±10 points among several thousand. The judgment save is 0.7–1.2 MB at day 365 (4.4–5.8 MB before C2). Judgment does not affect migration; that stays deferred.</p>
<h3>Tool repair and rental</h3>
<p>Economy on: 718 rental decisions weighed, 258 rentals opened (95 axes, 163 pickaxes), 459 times the worker chose to go without, once to buy. 255 returned, 1 lost and 1 broken; 226 daily fees paid and 36 settled from deposits; escrow 0 at the end. Repairs: 3, 1 and 7 tools (normal, normal, economy on), mostly axes. No exploit, deadlock or stuck rental showed up.</p>
</section>

<section id="econ"><h2>8. Economy off versus economy on (seed 1)</h2>
<div class="scroll"><table class="num"><tr><th scope="col">At day 365</th><th scope="col">Normal (economy off)</th><th scope="col">Economy on</th></tr>
<tr><th scope="row">Population / unemployed</th><td>{n1["alive"]} / {n1["unemployed"]}</td><td>{e1["alive"]} / {e1["unemployed"]}</td></tr>
<tr><th scope="row">Chapel share of coins</th><td>{n1["chapel_share"]}%</td><td>{e1["chapel_share"]}%</td></tr>
<tr><th scope="row">Median household cash</th><td>{n1["hh_median"]}</td><td>{e1["hh_median"]}</td></tr>
<tr><th scope="row">Meals missed, none for sale</th><td>{n1["missed_no_food"]}</td><td>{e1["missed_no_food"]}</td></tr>
<tr><th scope="row">Script errors</th><td>1</td><td>0</td></tr></table></div>
<p><b>What was switched on:</b> the <code>--market</code> option turns on the Living Economy market (LE-02 to LE-04 bids, asks, negotiation, contracts, speculation; LE-05 travel cost and rental; LE-06 bounded knowledge). Negotiated wages and services stay off by their own switches. Repair works in both runs.</p>
<p><b>Market activity:</b> 1,105 bids and 3,191 asks posted, 413 negotiations, 200 deals, 208 contracts, 87 speculative bids, about 1.3 million price tellings by word of mouth. 12,065 times a household wanted to bid and could not afford to.</p>
<p>The market works mechanically and improves food availability a little. It cannot fix buying power, because the coins sit in the chapel. Employment and household formation are unchanged. The two seed-1 runs diverge from the start, so these are differences between two histories, not measured effects.</p>
</section>

<section id="findings"><h2>9. Findings by severity</h2>
<div class="finding a"><p class="sev">A · Release blocker</p><h3>Gossip script error (X20-TELL-GUARD)</h3><p>Normal seed 1, between days 47 and 50: <code>Out of bounds get index '171'</code> in <code>JudgmentStore._tell</code>. A villager forgets a queued story mid-conversation (learning a refutation, or the memory cap) and the next read fails, cutting off the rest of that conversation. Reproduced on <code>ad281dc</code>. Becomes reachable more often since C2 made second-hand assault memories forgettable. <b>Correction:</b> two lines, skip a story already forgotten. Locally to day 52: no error, world unchanged, judgment state changed (the conversation finishes). Needs your approval and a re-validation decision.</p></div>
<div class="finding b"><p class="sev">B · Significant</p><h3>The chapel absorbs most of the money</h3><p>77–83% of all coins by day 365 in Build 25; 58–83% in earlier runs. Long-standing. Root cause: alms paid only against a necessity shortfall that food stocks erase. <b>Smallest correction (for your decision):</b> pay alms from what is left after the clergy's keep to the poorest households by cash held, as your rule reads, or set a ceiling on the fund above which the surplus goes as alms.</p></div>
<div class="finding b"><p class="sev">B · Significant</p><h3>Work does not grow with the village</h3><p>About 45 jobs all year while adults triple; 67–77% of adults idle at the end. Long-standing in every run. Hungry settlers keep arriving. <b>Options (for your decision):</b> let new workplaces open as people arrive, by existing business-creation rules; a cap on in-migration when there is no work; or treat idleness as accepted. A design choice, not a quick fix.</p></div>
<div class="finding b"><p class="sev">B · Significant</p><h3>Buying power collapses</h3><p>Median household cash falls from 63 to 4–11 coins, most traders end with nothing, and 12,065 market bids failed for lack of money. A consequence of the two findings above, not a separate defect.</p></div>
<div class="finding b"><p class="sev">B · Significant</p><h3>Households barely form</h3><p>25 households become 26–29 while the population nearly triples; adults stay in crowded homes. Long-standing. Needs a look at house building and marriage housing before any change.</p></div>
<div class="finding c"><p class="sev">C · Observation</p><h3>Other observations</h3><ul><li>Firewood shortage: 4,000–5,000 household-nights a year without firewood; effect not recorded.</li><li>Villagers slain: 0–10 a year; the killer is not recorded.</li><li>Seed variation is large (population 279 against 359 on the same code).</li><li>Year-long determinism was not re-tested with a second identical run; the 30-day gate is identical three times.</li><li>Judgment, bandit, repair and rental systems behave as designed.</li></ul></div>
</section>

<section id="actions"><h2>10. Recommended actions, ranked</h2>
<ol class="actions">
<li><b>Approve the two-line gossip fix</b>, then re-validate Build 25. Smallest choice: one normal seed-1 run to day 60, which covers the failing day, plus the 30-day gate. Any new Actions run needs your approval.</li>
<li><b>Decide the chapel's payout rule.</b> It is the main reason money stops circulating, and it affects every other economic number.</li>
<li><b>Decide how work should grow with population.</b> Planning belongs with Build 26's Living Economy work (LE-07, permanent employment).</li>
<li><b>Review household formation and housing</b> with the same evidence.</li>
<li><b>Record the missing measures</b> in future runs (chapel inflow and outflow, household cash spread, prices, business accounts), as analysis output only.</li>
</ol>
<p class="note">Nothing in the game was changed for this report. Analysis scripts and data: <code>parse.py</code>, <code>digest.py</code>, <code>analyze.py</code>, <code>charts.py</code>, <code>build_report.py</code>, committed with the report on <code>wip/requirements-control</code> under <code>docs/release/build25_validation/</code>.</p>
</section>
"""
open("report.html", "w").write(H + body)
print("written", len(H + body))
