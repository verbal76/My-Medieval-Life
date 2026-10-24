# Build 19 release packet (private playtest draft, 2026-10-24)

| | |
|---|---|
| Build | 19 (stamped through the `build_number` input) |
| Commit | `2f72ec3` on `wip/build19` (game code as `417c07f`; `2f72ec3` changes only a test fixture) |
| Release run | [40044931601](https://github.com/verbal76/My-Medieval-Life/actions/runs/40044931601), success (the first run, 40043968310, stopped at its tests: see below) |
| Release | draft "My Medieval Life Build 19" (tag `build-19` when published), private to collaborators |
| Owner authorization | `docs/directives/2026-10-24_owner_build19_release_authorization.md` on staging: private draft, after 30-day runs on seeds 3 and 4 |

## What Build 19 is

Expansion 19 complete and switched on (owner X19-SCOPE): subjective judgment, gossip, trust, memory and relationships;
personality, temperament, stubbornness and self-defence; family reputation through second cousins (ring weights
provisional) and inherited family stories; deliberate lies and their discovery; the family-sacrifice rule including
protecting the family in danger. With it: permanent identity (save version 20), the REC-F1 and SIM-F9 wait-plan fixes,
the flight recorder (off in every build: `recorder.json` `enabled: false`), the blocked-chase fix and the owner's SIM-F4
rules (bandits buy food when they can afford it, however hurt, and heal at camp).

## Packages (downloaded back from the draft and checked)

| File | Size | SHA-256 |
|---|---|---|
| MyMedievalLife-build19-android.apk | 86,378,470 | `b73f5e4091af81de494cb8ded7d971e538a99c81c851f44a988e9cee741ccace` |
| MyMedievalLife-build19-linux-x86_64.zip | 221,575,953 | `333f33f507e49931c2ef0850fde1e2c99e9020dcc7d6825958c1ff5bcf4c764d` |
| MyMedievalLife-build19-windows-x86_64.zip | 231,325,065 | `2df02a3b2c3764ac72f878214e44250f33631f67822be22b977aa663d569aecd` |

All three match `SHA256SUMS.txt`. The Linux binary started headless and quit cleanly with no script error, and wrote no
recorder data. Windows and Android were not run here (no device); the owner's playtest covers them.

## Android signing

The stable test-key secrets still do not exist, so the APK is signed with a throwaway key (`allow_temporary_key`, as for
Builds 14 to 18): it cannot update an earlier install; uninstall the old one first (the save is lost unless exported).

## Evidence

- Targeted suites on the merge: 18 suites, 1,784 checks, 0 failures; wiki passes. Release tests: `run_tests` 3,595 checks
  and `start_test` 506 steps, 0 failures.
- Determinism: three independent 30-day runs on `417c07f` agree (seed 1 `a47f2e6d`/`60742ce2`, seed 2
  `3ec4c344`/`573d6000`); the Build 19 baseline is written (`docs/release/sim_baseline.json`; Build 18's kept as
  `sim_baseline_build18.json`).
- Conservation: no currency or item leak and no FATAL line on seeds 1 to 4 over 30 days.
- Outcomes over 30 days: nobody starved on any seed; villager deaths are elders of old age; bandits die only in fights
  with villagers they attacked (emergent, B19-EMERGE). Analysis: `docs/design/SIM_FINDINGS.md` (staging), runs 2 to 4
  and the seeds 3-4 gate.
- The first release run stopped at `run_tests`: a household-split test expected its house built within six days, but the
  now-surviving band robbed the family of its building money (a legitimate outcome). The test sets the band aside for that
  scene (`2f72ec3`); every check unchanged.

## Known limitations

- Agent-provisional values in `judgment.json`: family-reputation ring weights, danger radii, the stubbornness penalty
  sizes, the lie motive threshold, the family-story thresholds.
- One guard was seen once (completion worker's 10-day run) standing still for 30 hours on a loot-recovery walk; not seen in
  any 30-day run since; the walking code is unchanged.
- Explanations are in-world only (XEXPL-D1).
