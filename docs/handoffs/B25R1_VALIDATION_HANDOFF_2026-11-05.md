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

## Update 2026-11-05 00:45 UTC (2026-11-04 19:45 EST)

- `0161f39` pushed to `wip/b25r1` (reporting only: a shard given no suites, expecting none, is TESTED; still INCOMPLETE when
  results were expected, FAILED on a failure; checked with synthetic shard results; not yet seen on a GitHub run).
- The container restarted three times (00:00, 00:28 UTC and earlier); local long runs are abandoned per the owner's
  instruction. The candidate baseline was NOT recorded; nothing baseline-related is committed.
- Local seed 1 (game code = bfce680 = 361f364), economy_sim --every 1, reached day 26 before the restart. (V) At day 10 it
  equals the gate's eq_s1: alive 108, households 26, coins 3267, treasury 118. Fingerprints were not printed by this run.
- Village treasury, seed 1, by day (V, local log): d0 270, d1 490, d2 451, d3 411, d4 376, d5 351, d6 340, d7 293, d8 251,
  d9 197, d10 118, d11 115, d12 109, d13 103, d14 26, d15 37, d16 12, d17 39, d18 20, d19 16, d20 35, d21 26, d22 38, d23 20,
  d24 19, d25 24, d26 39. Households 26 from day 0 (baseline df67e8e: 25), so households 25->26 is a changed starting
  condition, not something that happened in play. Baseline df67e8e: day 10 treasury 130 (now 118), day 30 323 (now 32): the
  old village rebuilt its treasury after day 10; the new one spends it down to a floor of about 12-39 from day 14.
- Not yet traced: which outflows hold the treasury at the floor (the recorder's village-treasury rows are stock samples; the
  'owner=treasury' journey rows are hamlet dues to their lords' settlement treasuries, not the village's). Next step on
  Actions: a long-sims run of seed 1 for 30 days on bfce680, at df67e8e for comparison, reading the daily treasury and the
  manor/relief lines (economy_sim WATCH RELIEF, manor wages) from the job logs; then record the baseline on Actions.
- Running: campaign 41939383765, packages 41939387992 (both bfce680).

## Update 2026-11-05 ~02:00 UTC: treasury cause found (V), Windows full smoke crash (open)

Treasury, seed 1, 30 days, from the artifacts of long-sims 41942611804 (df67e8e) and 41942615526 (bfce680), `sim.json`
(downloaded with the API; both runs reproduce the gate's values exactly: day 30 treasury 323 and 32).
- Cumulative village-treasury flows at day 30 (df67e8e -> bfce680): tools 125 -> 1040 (+915), wages 1856 -> 1534 (-322),
  repairs 311 -> 130 (-181), tax 1996 -> 2167 (+171), loot recovered 68 -> 8 (-60). The tools line is the cause.
- `od16.axes_given` 0 -> 22: the treasury bought 22 axes (OD-16 `NPCBrain._support_trades` / LE-04 `EconMarket.manor_tools`) for
  "workers short of their trade's tool" (`tool_needers`: a woodcutter with no axe, or the responsible adult of a household
  building its own home with no axe). tool_needers itself is unchanged since df67e8e.
- The axes pile up: the 5-6 woodcutters hold 6 axes on day 0, 18 on day 14, 41 on day 30 (df67e8e: 7 at day 30); smiths forge
  46 axes in 30 days (df67e8e 16). The pile starts on day 8, before the treasury buys any (its first on day 14), so axes are
  being bought by others too and ending with the woodcutters, and someone keeps coming up short.
- Classification: a DEFECT (an unintended loop), not legitimate activity and not a changed start. Hypothesis to confirm: an
  axe given to a home builder (B25R1 homesteads put many households into building) passes to a woodcutter, by household
  tool sharing or sale, so the builder is short again the next evening and the treasury buys another. Next: trace one axe
  in a short seed 1 run (who receives it, where it goes), fix the hand-off, then re-run the treasury comparison and the gate.
  The baseline must NOT be recorded before this fix.

Windows full smoke (release 41939387992, job 126965284940): `--headless --quit-after 300` exits -1073741819 (0xC0000005)
about 0.3 s after the engine banner; the Windows demo smoke passed on the same engine. The presets differ only by the `demo`
feature. The previous release run 41666958781 (a459186, Build 25) passed. The project starts headless on Linux without a
crash (local). Not reproduced on Windows yet; cause unknown (startup path that differs between full and demo, or engine).

## Update 2026-11-05 ~03:30 UTC: axe defect fixed and merged; Windows crash not reproduced

Treasury axe loop (V), fixed in `8d05942` (wip/b25r1-axe), merged to `wip/b25r1` as `a995397`:
- Cause: `Relations._gift_from` (game/scripts/core/relations.gd) gave the courted person's first favourite the giver held;
  `FAVOURITES["woodcutter"] = ["axe", "bread"]`, so a woodcutter courting a woodcutter gave its only work axe every dawn
  (seed 1: Agnes 24 -> Margery 67, 1 -> 13 axes by day 16; Roger 13 and Joan 78 likewise). The giver, now without its trade's
  tool, was a genuine tool needer (NPCBrain.tool_needers) and the treasury bought it another. Bug present since 1c1d4a5
  (2026-10-19); B25R1's world first paired two woodcutters in seed 1. Builders, homesteads, sharing and rentals not involved.
- Fix: `_spare_to_give`: a villager never gives away a tool its work keeps unless it holds a spare, nor a rented tool.
- Test: od16_test `test_courting_gift_keeps_the_work_axe`: old code 44/3 failures, fix 44/0. Local suites on the fix: od16
  44/0, relations 80/0, gift_quantity 7/0, le04 68/0, le05_rental 53/0, aging 136/0, homestead 49/0, player_homestead 40/0,
  wilds 69/0; 10-day seed 1 conservation clean. Pre-existing: od16 prints a SCRIPT ERROR "Invalid access to 'stock'" on old
  and new code (open, not investigated).
- 30-day seed 1 on the fix (long-sims 41960195751): treasury d10/d20/d30 151/189/414 (df67e8e 130/185/323; bfce680 118/35/32);
  treasury tools 0, axes given 0, woodcutters hold 5 axes for 5 woodcutters. Remaining differences from df67e8e are the
  B25R1 world (no pickaxe purchases, 114 vs 112 alive) and still need the gate's per-value listing before a baseline.
- Dispatched on a995397: simulation gate (long-sims gate) and Tests 'only' (od16, relations, gift_quantity).
- The four 365-day chains (41939383765, bfce680) contain the axe loop: provisional only, not certification for a995397.

Windows full smoke (V): not reproduced. win-smoke.yml on wip/b25r1-winsmoke (head 5af20c5), runs 41955589354 (full x2, demo,
Build 25 full: all exit 0) and 41957360444 (27 launches of the same full package: all exit 0); no dump. The failed launch ran
about 8 s (the game's 300 frames) and lacked the shutdown leak report every other launch prints, so it most likely crashed
at engine shutdown. New since Build 25: 71 GDScripts leaked at exit, bisected to 1fe523e (`static var _looks := {}` in
game/scripts/view/overworld_view.gd:441); a local-variable cache removes the leak (scratch test). Proposed, not applied:
that change, plus failing the release smoke on "resources still in use at exit". Awaiting owner decision.
