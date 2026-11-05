# B25R1 validation handoff, 2026-11-05 00:20 UTC (2026-11-04 19:20 EST)

Lead coordinator handoff. Verified facts are marked (V); hypotheses (H).

## Commits
- `361f364` merge of the three repair branches (fix1 `5cd1765`, fix2 `2275b92`, fix3 `40f190e`) on `wip/b25r1`.
- `bfce680` (pushed head of `wip/b25r1`): + `tests.yml` empty-shard expectation + `net_econ_integrity_test` lossy settle.
  Game code identical to `361f364` (V: diff is `.github/workflows/tests.yml` and the one test file only).
- `0161f39` (local, unpushed, worktree `b25r1-integrate`): `tools/ci_report.py` a shard given no suites is TESTED.

## Runs
| What | Run | SHA | Result |
|---|---|---|---|
| Full suite | 41923790388 | 361f364 | V: one failure, net_econ_integrity_test (lossy race; fixed in bfce680). The four earlier failing suites (homestead_test, run_tests, net_fauna_test, wilds_test) pass; regional_food passes with the script-error guard; net_g1 passes. 53 min. |
| Recorder-only | 41923795331 | 361f364 | V: 3/3 suites pass; report red (empty shards). |
| Simulation gate | 41923800341 | 361f364 | V: 93 min (was over 120). Recorded = unrecorded at every checkpoint (both switch sets). 32 blocking findings, all baseline differences from `df67e8e` (seeds 1, 2; days 10, 30). |
| Affected suites (`only`) | 41937849606 | bfce680 | V: all 8 shards passed (net_econ_integrity + 3 recorder suites); report red: empty shards 5-7 INCOMPLETE (fixed by 0161f39, unpushed). |
| 365-day campaign, seeds 1,2 + twins, 100-day segments, recorded | 41939383765 | bfce680 | running (provisional) |
| Packages (release.yml, private) | 41939387992 | bfce680 | running; the draft release step needs a passing sim-gate, so the gate inside it will fail on the same baseline differences; the package and smoke jobs do not depend on it (artifacts only, provisional). |

## Open items
1. Baseline: candidate being recorded locally (`tools/sim_gate.py --write`, uncommitted); must match the gate's eq_s1/eq_s2
   fingerprints (seed 1 day 10 `e137f39ae04864e413a09c94ae454061`, day 30 `b6d0c1a8a0a33353c7f63644fa6b914d`).
2. Treasury seed 1 day 30: 323 (df67e8e) vs 32. Local recorded run of seed 1, 30 days, in the scratchpad (rec1) to trace it.
   H: B25R1 village spending (hamlet civic policy Q9, wells, roads) or the one new path that pays into w.treasury; not traced yet.
   Other differences: households 25->26, alive 112->118 (day 30), currency 4013->4322 (H: band household in the wild, Q2;
   homesteads; settlement people).
3. Reconnection checks in net_econ_integrity_test ("same request number sent again after the reconnection", "answered again
   under a new number", "an answer sent twice while the host's app was frozen"): failed once locally right after a container
   restart, passed on the next run and on GitHub (41937849606). Open: possible multiplayer reliability risk; not investigated.
4. Container restarted twice during local runs; long investigations should move to Actions.
