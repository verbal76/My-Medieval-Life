# Simulation findings from the flight recorder (register REC-DIAG)

Owner directive: `docs/directives/2026-10-23_simulation_first_diagnostics.md`. Each run is analysed before the next. Coverage today is
the recorder's first stage (decisions at the top level, plan actions, trades, transfers, hourly samples, coin audit); systems the
recorder does not see yet are listed as gaps, never assumed to work.

## Run 1: 10 days, seed 1, about 105 villagers (existing archive, recorder `94b1304` on the Expansion 19 line, judgment off)

Archive: 1.45 M rows, 10.5 MB compressed. Totals: 51,149 decisions, 11,339 plan actions (938 failed), 2,772 trades (2 refused),
499 coin-audit warnings, 26,686 hourly samples.

| # | Finding | Systems | Evidence | Cause (as far as recorded) | Verdict | Recommendation |
|---|---|---|---|---|---|---|
| F1 | Villagers holding unsold goods re-decide every few minutes | NPC brain, jobs, trade | 6 villagers with 400-600 decisions a day against 4-19 actions by day 9; decisions 2,100 a day (day 0) to 8,300 (day 9) | being investigated (FIX-RECF1) | defect (owner-approved fix in progress) | FIX-RECF1 |
| F2 | A stonecutter tried to buy an iron chisel 328 times in one day | stonecutting (Build 18), NPC brain, trade | villager p:14 on day 2: from 10:01 to 17:59 a `buy_from` of a chisel from vendor 46 fails every game minute, each followed by the same decision ("buying an iron chisel to dress stone"); p:14 holds 12 coins | the plan chooses the purchase again after it fails; the failure reason is not recorded (gap), the 12 coins suggest he could not afford it or the smith had none | defect (a working day lost to a loop) | same family as F1: the decision should not re-choose an action that has just failed for a reason that has not changed; fix narrowly with F1's approach once approved |
| F3 | Bandits stalking at night make empty decisions hundreds of times a day | bandits | bandits p:102, p:104 with 400-435 empty decisions a day on days 4-8; `doing = stalking`, plan empty | `NPCBrain._bandit`: when prey is found at night it sets `n.target` and returns without a plan, so `decide` runs again every tick while the chase is driven by the target | performance defect (behaviour itself works through the target) | give the stalk a plan step that lasts while the target is valid (no change to what bandits do) |
| F4 | The whole bandit band of six died within nine days | bandits, food, wildlife, trade | samples: p:101 starves to death at 05:00 on day 2 with hunger 0 from 21:00 the day before while `poach` keeps succeeding; the band is gone by day 9; p:105 holds 140 coins but cannot shop | bandits eat only inside `poach` (a 25% chance to find game within 30 tiles when hungry) or from the band's packs; the market trip (`_bandit_market`) needs at least 15 coins **and** health at least 60%, so an injured or starving bandit with money cannot buy food; most hold 5-13 coins | partly legitimate scarcity, partly a likely defect (the health gate blocks the only food purchase for a starving bandit); death causes are not recorded yet (gap) | confirm with death causes after D3; then the owner decides whether the health gate should not block buying food |
| F5 | One sale attempt in four fails, steadily | trade | `sell_to` 953 ok, 296 failed, every day | failure reason not recorded (gap) | unknown | record the reason `act` fails (D4) before judging |
| F6 | Foraging fails more than half the time on day 0 | foraging | 84 failed against 66 ok on day 0, then about even | likely several villagers reaching the same plant (contention); reason not recorded | probably legitimate | confirm with the failure reason |
| F7 | 48 of 121 sampled people never take part in a trade in ten days | population | 32 are children playing, 9 elders taking the air, 6 bandits lurking, 1 other | expected roles | legitimate | none |
| F8 | About 50 coin-audit warnings a day | money | per-person coin changes outside recorded events; no village-wide coin creation or loss | the about 150 coin sites outside `trade` (owner REC-D4) | expected under REC-D4 | none now |

**Instrumentation gaps found by this run** (to close in D3/D4, never assumed fine): why an action failed (`act` returns only
true/false); deaths and their causes; births; job changes; the treasury and taxes; crimes; guard fights; relationships. These are
in the recorder worker's D3 task now.

**Run plan under the owner's bounded rule** (`docs/directives/2026-10-23_bounded_parallel_simulation.md`): each run names its commit,
duration and stop conditions in advance, runs unattended as a background process (no agent supervises it), is analysed once, and is
not extended unless a finding needs more coverage; new campaigns need the owner.

**Run 2 (planned, not started):** commit = the `wip/recorder` head after FIX-RECF1 and D3 are merged there (named when started);
30 game days, seeds 1 and 2, recording on; stop at day 30, at a FATAL conservation line, or at the storage cap. Purpose: with death causes and failure reasons recorded: to check F1 is gone, settle F4 and F5, and look for longer-term trends (stock build-up, prices, households running out of money).
