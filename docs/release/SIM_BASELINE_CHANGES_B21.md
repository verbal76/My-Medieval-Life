# Build 21: changes to the accepted simulation baseline (GP-BASELINE-POLICY)

Each change below is an owner-approved change whose differences were listed, explained and checked before the baseline
(`docs/release/sim_baseline.json`, written by `python3 tools/sim_gate.py --write`) was replaced. The baseline before each change
is kept beside it. Raw evidence: the gate's output on the change alone (`DIFFERS` lines) and a value-by-value comparison of the
two baseline files.

## 1. Bandits never start on a solid cell (owner directive 2026-10-24_build21_final_execution.md section 4)

- **Change:** `Population` (world setup) puts a bandit whose random start falls on a solid cell of the camp (a barrel, a crate,
  the fire) on the nearest open cell (`VillageMap.nearest_walkable`); no random number is drawn, so every other draw is as before.
- **Kept:** `docs/release/sim_baseline_pre_bandit_spawn.json` (the accepted baseline from `7551616`).
- **Why it differs:** seed 1 has one such bandit (Sly Tom, start cell (106, 12), the camp's barrel; the recorder audit's
  `probe_playtest` found him there). He now starts one cell away, so his first walk, his poaching and his market trips differ,
  and through them, by the ordinary spread of a living village, seed 1's later days. Seed 2 has no bandit on a solid cell.
- **Unrelated values unchanged:** every seed 2 value at days 10 and 30 is identical (fingerprints `3ec4c344...`, `573d6000...`),
  which shows the change touches only a world with a bandit on a solid cell. Conservation holds: currency and item leaks 0 at
  every checkpoint of both seeds.
- **Differences (seed 1 only; 364 values in all):**
  - day 10 alive: 108 -> 111
  - day 10 currency: 3312 -> 3283
  - day 10 fingerprint: a47f2e6d1d9b8bb756e8080155c1ee52 -> 4e268d9b8cc6eefadf78d9933c1465cd
  - day 10 treasury: 28 -> 41
  - day 30 alive: 116 -> 120
  - day 30 currency: 4664 -> 4718
  - day 30 fingerprint: 60742ce25b0ed80dd673c4e969635994 -> 862b66aadf599be32971466b4addb7d2
  - day 30 treasury: 124 -> 0
  - the item ledger (293 values), animal counts (61 values) and deposits (2 values) at days 10 and 30: the same village life told differently; none is a leak.
- Seed 2 differences: 0.
- Code commit `f86a32d`; the new baseline names it.
