# B25R1 final validation and packaging plan (prepared 2026-11-05 21:10 UTC)

## Freeze
Merge the three required branches (wip/b25r1-econ5, wip/b25r1-wood, wip/b25r1-net5) into wip/b25r1; record SHA F. Nothing else merges until packaging ends (treasury recovery wip/b25r1-econ6 only if fully verified before the freeze).

## On F, in parallel (runner jobs: 12 test shards + 5 gate parts + 1 = 18 of 20 concurrent)
1. Tests (tests.yml, 12 shards since 0f6921e; est. ~30 min wall).
2. Simulation gate (long-sims.yml gate: true, split, ~40 min). Expected: FAIL only on accepted-baseline differences from df67e8e; determinism pairs must MATCH; no conservation/recorder/script findings.
3. 365-day twin campaign (long-sims.yml flight, seeds 1,2, --twin, 100-day segments, ~5.4 h): independent, not a package gate unless it shows the build unsafe.

## Baseline reconciliation (known causes of difference since df67e8e, to classify each gate difference)
- Generation 4 -> 7 world: B25R1-018 region and hamlets, gen 5 Bear Hill/knoll, gen 6 rivers through settlements and roads, gen 7 Wood Perilous ridge and castle way (layout, households 25 -> 26, residents, travel).
- Settlement economy: trips/people (B25R1-019), consignment own-place (P4) and cross-place (q27), q32 any-neighbour collection, q33 founding-trader 80-coin reserve.
- Village economy: axe gift loop fixed (a995397: treasury tools 1040 -> 0), P1 founding without full benches, P2 household first tool, P3 unused stock sold, P5 land clearing (new manor fields, farmers up).
- Not expected to change results: aerial maps, net, CI, leak, drone tool, recorder trace (off by default).
Each blocking difference is traced to one of these with numbers (sim.json gov/od16/ledger/people), or investigated. Then `tools/sim_gate.py --write` (asks for approval by project setting) records the baseline on F's results; commit B (baseline file only) -> SHA P = F + baseline.

## Package from P
Equivalence F -> P: diff is docs/release/sim_baseline.json only; Tests evidence on F carries to P. Run release.yml (visibility private) on P: its split sim-gate must PASS against the new baseline; packages (full/demo x Windows/Linux/Android) and smoke-windows (leak check) run in parallel. Then repeat Windows smoke launches with win-smoke.yml on P's full Windows artifact. Draft release is private; label "B25R1 private playtest", commit P, known limitations.
