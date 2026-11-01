"""Assemble the X20-CHAPEL-FIX report HTML from report_head.html (styles) and chapel_parts.json (charts, tables)."""
import json
D = json.load(open("report_data.json")); X = json.load(open("chapel_parts.json"))
H = open("report_head.html").read().replace("<title>Build 25 Year-Long Validation</title>", "<title>Chapel Economy Correction</title>")
H = H[:H.index("<main>")] + "<main>"
has3 = "C3" in D
def e(k, f): return D[k]["end"][f]
def P(a):
    f = {"C1": "p_chapel_normal_s1.json", "C2": "p_chapel_normal_s2.json", "C3": "p_chapel_econ_s1.json"}[a]
    return json.load(open(f))["chapel"][-1]
pairs = [("N1", "C1"), ("N2", "C2")] + ([("E1", "C3")] if has3 else [])
lo = lambda f: min(e(a, f) for _, a in pairs); hi = lambda f: max(e(a, f) for _, a in pairs)
blo = lambda f: min(e(b, f) for b, _ in pairs); bhi = lambda f: max(e(b, f) for b, _ in pairs)
def rng(a, b, fmt="{:,}"): return fmt.format(a) if a == b else (fmt.format(a) + "–" + fmt.format(b))
alms = [P(a)["stats"]["alms_coins"] for _, a in pairs]; given = [P(a)["stats"]["offering_coins"] for _, a in pairs]
dec = [P(a)["stats"]["declined"] * 100 // max(1, P(a)["stats"]["considered"]) for _, a in pairs]
una = [P(a)["stats"]["unable"] * 100 // max(1, P(a)["stats"]["present"]) for _, a in pairs]
med = [P(a)["gift_median"] for _, a in pairs]
errs = {a: D[a].get("script_errors") for _, a in pairs}
leaks = {a: D[a].get("leaks") for _, a in pairs}
runs_desc = "two normal runs (seeds 1 and 2)" + (" and one with the Living Economy on (seed 1)" if has3 else "")
body = f"""
<header>
<p class="eyebrow">My Medieval Life · X20-CHAPEL-FIX · branch <code>wip/x20-chapel</code> at <code>ae8641d</code></p>
<h1>Chapel economy correction: before and after a year</h1>
<p class="lede">Giving to the chapel is now each villager's own weekly choice, and the chapel gives what it does not need to the poorest households. Over a simulated year ({runs_desc}), the chapel's share of the village's coins fell from {rng(blo('chapel_share'), bhi('chapel_share'), '{}')}% to {rng(lo('chapel_share'), hi('chapel_share'), '{}')}%, and median household cash rose from {rng(blo('hh_median'), bhi('hh_median'))} to {rng(lo('hh_median'), hi('hh_median'))} coins. Coins and items were conserved throughout.</p>
<dl class="meta"><div><dt>Directive</dt><dd>Owner, 2026-11-01, <code>docs/directives/2026-11-01_chapel_economy_correction.md</code></dd></div>
<div><dt>Before</dt><dd>Build 25 source <code>ad281dc</code> (unchanged)</dd></div><div><dt>After</dt><dd><code>ae8641d</code> on <code>wip/x20-chapel</code>; not merged</dd></div></dl>
</header>

<section id="audit"><h2>1. What the code did before</h2>
<ul>
<li><b>Giving was automatic.</b> Every seventh day, every adult whose fixed piety was 0.3 or more lost a share of their spare coins, and households a share of their wheat. Nobody chose; there was no attendance and no difference between refusing and being unable.</li>
<li><b>No penalties existed.</b> Nothing in judgment or reputation touched the chapel, so nothing had to be removed.</li>
<li><b>The reserve was fixed</b> at a week of clergy wages plus wages owed.</li>
<li><b>Alms almost never paid.</b> They were capped at a household's shortfall in essentials, and food in the larder cancels that shortfall. A household with grain but no coins got nothing, so the fund held 77–83% of all coins by the end of the year.</li>
</ul></section>

<section id="change"><h2>2. What changed</h2>
<ul>
<li><b>A choice, every week.</b> Each adult and elder who can spare a coin decides through the villagers' own decision system (the same one used for trade, work and courtship). It weighs their piety, what they can spare, the week's circumstances, the dependants their household feeds and their opinion of the preacher. Piety changes the odds and never decides: the devout sometimes keep their coins, those of little faith sometimes give.</li>
<li><b>Affordable, varied gifts.</b> Only coins above what their household needs for the next days and a little savings are ever given; the amount varies. Someone with nothing to spare is not asked and is counted as unable, not as refusing. Declining changes nobody's opinion or reputation. Households decide the same way about spare wheat.</li>
<li><b>A modest reserve.</b> The chapel keeps 14 days of clergy wages, wages owed, and what it has recently spent on relief food and seed.</li>
<li><b>Alms by hardship.</b> Everything above the reserve goes to the poorest households, judged by coins, shop till, and food and firewood held, against two weeks of essentials at today's prices. A full larder no longer rules a household out; a household holding six weeks of essentials or more gets nothing, even when short of coins. Poorest per mouth first, each up to what it lacks.</li>
<li><b>Instrumentation</b> records attendance, those unable, decisions, donors and refusals by wealth bracket, gift sizes, wages, reserve, alms, recipients and their cash before and after, and household cash percentiles. It changes no behaviour.</li>
</ul>
<p>The numbers (gift share 10%, 14-day reserve, two-week essentials line, six-week cutoff, decision weights) are my provisional proposals. The first values tried (25% gifts, one-week line) were measured over 30 days and rejected: the fund reached 34% of all coins within a month.</p></section>

<section id="results"><h2>3. A year, before and after</h2>
{X['share']}
{X['hhmed']}
{X['endtbl']}
<p>The village keeps its money moving: the chapel stays near its reserve, the manor treasury stays solvent and households hold real cash. Alms paid over the year: {', '.join(f'{x:,}' for x in alms)} coins, against {', '.join(f'{x:,}' for x in given)} given.</p>
</section>

<section id="circulation"><h2>4. Where the coins are</h2>
<div class="grid2">{X['circ']}</div>
<p>Before: coins drain into the chapel and stay there. After: the villagers' purses hold most of the money all year. On seed 2 the fund rose to about a tenth of all coins between days 90 and 260 and then fell back to its reserve. Few households qualified for alms in those months, so the surplus waited. The rule held it back rather than handing out money with no hardship to meet.</p>
</section>

<section id="flows"><h2>5. The chapel's money in and out</h2>
<div class="grid2">{X['flow']}</div>
{X['gtbl']}
<p>The saw-tooth comes from counting weekly services in 10-day windows: some windows hold two services, some one. Alms track gifts closely; the clergy's wages are a small, steady cost.</p>
<p>Of those able to give, {rng(min(dec), max(dec), '{}')}% declined at a given service; {rng(min(una), max(una), '{}')}% of those present could not spare a coin. The median gift was {rng(min(med), max(med))} coins.</p>
</section>

<section id="brackets"><h2>6. Who gives, by household means</h2>
{X['btbl']}
<p>Poor households are most often unable to give, and when they can they give small amounts. Comfortable and modest households give almost all the coins.</p>
</section>

<section id="spread"><h2>7. Household cash, spread across the village</h2>
<div class="grid2">{X['spread']}</div>
</section>

<section id="recipients"><h2>8. Who received alms</h2>
{X['rtbl']}
</section>

<section id="economy"><h2>9. With the Living Economy on (seed 1)</h2>
<div class="scroll"><table class="num"><tr><th scope="col">Over the year</th><th scope="col">Before</th><th scope="col">After</th></tr>
<tr><th scope="row">Bids posted</th><td>1,105</td><td>2,396</td></tr>
<tr><th scope="row">Asks posted</th><td>3,191</td><td>3,996</td></tr>
<tr><th scope="row">Negotiations</th><td>413</td><td>787</td></tr>
<tr><th scope="row">Deals settled</th><td>264</td><td>531</td></tr>
<tr><th scope="row">Contracts opened</th><td>208</td><td>368</td></tr>
<tr><th scope="row">Bids a household wanted but could not afford</th><td>12,065</td><td>12,621</td></tr>
<tr><th scope="row">Tool rentals opened</th><td>258</td><td>337</td></tr>
<tr><th scope="row">Economy saves loading back exactly</th><td>37 of 37</td><td>37 of 37 (largest 906 KB)</td></tr></table></div>
<p>With money in purses the market roughly doubles: twice the bids, negotiations, deals and contracts. Jobs rise from 46 to 63 and nights without firewood fall from 4,532 to 790. The count of bids a household could not afford did not fall. Those are wishes priced above what the household can spare, and they rise with the number of people looking. The market still prices some goods beyond what households can pay. The chapel was not the only reason for this, and it needs its own look.</p>
</section>

<section id="integrity"><h2>10. Integrity</h2>
<div class="scroll"><table><tr><th scope="col">Run</th><th scope="col">Actions run</th><th scope="col">Commit</th><th scope="col">Settings</th><th scope="col">Script errors</th><th scope="col">Leaks (currency, items)</th></tr>{X['runs']}</table></div>
<ul>
<li>Coins and items conserved at every checkpoint of every run: no currency leak and no item leak.</li>
<li>Determinism: the 30-day seed-1 run repeated gives the identical fingerprint.</li>
<li>Saves: two optional keys added; older saves load with no recent spending recorded.</li>
<li>Script errors: the after runs reported 0 (seed 1), 2 (seed 2) and 12 (economy on). Every one is the known gossip defect X20-TELL-GUARD (<code>judgment_store.gd:1490</code>, all 12 economy-on locations listed by a read-only recovery job), not the chapel; Build 25 seed 1 hit the same defect once. Each run reached day 365. With more people trading and talking the defect fires more often, which strengthens the case for its two-line fix, still waiting for your approval.</li>
<li>Tests: chapel suite 123 checks, conservation, wiki, recorder and three judgment suites pass.</li>
</ul>
</section>
"""
open("chapel_body.html", "w").write(body)
open("chapel_report.html", "w").write(H + body + "\n</main>\n")
print("ok", len(H + body), "has3", has3)
