# SIM-GATE-01: flight recorder audit, simulation gate and analysis workbook

Owner directive 2026-10-24 (`docs/directives/2026-10-24_permanent_simulation_recorder_excel_gate.md`, permanent) and its
amendment of the same day (`docs/directives/2026-10-24_sim_gate_amendment_platform_exports.md`). Branch `wip/sim-gate`, from
`9304446` (`wip/multiplayer-b19`). Developer reference; nothing here is a player feature except the desktop recording option
(section 7). Agent decisions: `docs/DECISIONS.md` (2026-10-24, SIM-GATE-01).

**Build 20** (`56c24cb`, run 40065271734) was already packaged as a private draft before this directive's gate existed
(CLAUDE.md section 1): it is not re-opened. The gate is in `release.yml` for the next release.

## 1. Audit: what existed at `9304446` (directive section 2)

Verified by reading the code and by a recorded run (seed 1, 10 days, `economy_sim.gd --record`, section 1.2), not from the
documents. Classification: **implemented**, **partial**, **designed only**, **missing**.

| # | Component | Before (at `9304446`) | Evidence | Now (`wip/sim-gate`) |
|---|---|---|---|---|
| 1 | Recorder in executable code | **Implemented** | `game/scripts/core/recorder/flight_recorder.gd` (core, 386 lines), `world_recorder.gd` (738), `recorder_archive.gd` (127); `World.setup` attaches it when enabled (`world.gd:175`), `load_dict` too (`world.gd:5061`); off by default (`game/data/recorder.json` `"enabled": false`) | unchanged design; schema 2 |
| 2 | Events from the whole village (not only the player) | **Partial** | every villager's decision (`npc_brain.gd:210-216` wraps `decide`) and plan-step action (`world.gd:612-618`), trades and transfers (`world.gd:974-1014`), life, employment, government, crime; *not* production effects, relations, contracts, business, farming, mining, settlements' daily steps, judgment (`game/data/recorder_coverage.json`) | adds chases and the village snapshot; the uninstrumented systems remain (section 6) |
| 3 | Hourly state snapshots | **Partial** | per-person samples only (`world_recorder.gd:290-300` at `9304446`: hunger, hp, cell, doing, coins); no village aggregates | **Implemented**: `snapshot` table, 48 aggregates an hour, and the closing snapshot (`world_recorder.gd` `snapshot_values`, `finish`) |
| 4 | NPC decisions and actions | **Partial** (decisions) / **Implemented** (actions) | decision: branch of the priority chain only, "not evaluated" after it (`world_recorder.gd` `decide_begin/end`); every plan-step action with ok/failed | unchanged |
| 5 | Economic transactions and resource movements | **Partial** | `World.trade`/`transfer` fully, coin audit hourly (`_audit_coins`); production and consumption only as action events; about 150 coin sites detected, not attributed (REC-D4) | the hour's `w.stats` changes in the snapshot (`stats_delta`) give production, consumption, trade by counter |
| 6 | Relationship and morality changes | **Designed only** | `recorder_coverage.json` "Relationships", "Judgment": Not instrumented (stages D4, D5 in `FLIGHT_RECORDER_DESIGN.md`) | **Partial**: hourly totals of ties, friendships, courting pairs and judgment facts; per-change events still not instrumented |
| 7 | Crimes, witnesses, guard responses | **Partial** | `witness_begin`, `guard_begin/end`, `alarm_begin/end`, `report`, `robbery`; no chase, no pursuit, no response time | **Implemented as far as the game goes**: chase events with reason, duration, distances, blows; wanted status and reinforcements do not exist in the game |
| 8 | Causes and consequences | **Partial** | context stack: `parent` and `interaction` link decision -> action -> trade, verb -> witness -> confrontation; `link` table (`same_object`) exists but no system uses it (0 rows) | unchanged; a chase does not name the code that set its target |
| 9 | Exportable output | **Partial** | gzip JSON-lines chunks any gzip reader opens, a documented reader (`FLIGHT_RECORDER.md` section 5); no export tool | **Implemented**: `analysis.json` per run, the archive zip and the workbook (`game/scripts/recorder_export/`) |
| 10 | Excel analysis pipeline | **Missing** | nothing in the repository wrote XLSX | **Implemented**: one GDScript writer for CI and the desktop game |
| 11 | CI invokes it | **Missing** (the recorder's output) | `tests.yml:166` runs `recorder_test.gd` (unit tests); its short simulation (`tests.yml:184`) runs *without* `--record`; `long-sims.yml` is manual and unrecorded; `release.yml` ran no simulation at all | **Implemented**: `release.yml` job `sim-gate` before `build` |
| 12 | Recorder output validated against simulation truth | **Partial** | the on/off fingerprint comparison was run by hand once (`FLIGHT_RECORDER.md` section 6); the coin audit checks the recorder against the world's purses; no automated reconciliation with `economy_sim`'s output | **Implemented**: every recorded run is reconciled (section 3) |

### 1.1 Directive section 11, items 1 to 10

1. **Recorder files and architecture.** Core `FlightRecorder` (tables, context stack, object threads, bounded buffer, chunk
   writer with header/footer/sha256, session record, recovery of interrupted sessions, storage cap); `WorldRecorder` (the game's
   instrumentation points, each a guarded `if recorder != null` call); `RecorderArchive` (chunk format and reader); data
   `recorder.json`, `recorder_codes.json`, `recorder_coverage.json`; tests `recorder_test.gd`. Contract: `FLIGHT_RECORDER.md`.
2. **Implemented versus missing:** the table above and `recorder_coverage.json` (now 24 rows: 5 fully, 13 partially and 6 not
   instrumented, the last including the future expansions).
3. **Simulation test infrastructure:** `game/tests/economy_sim.gd` (the real World, fixed 0.5 s step, `--days --seed --every
   --out --record --set --scenario --profile --no-judgment`, ledgers for currency, items, deposits, animals and the settlements,
   FATAL stop on a broken ledger); `tools/sim_gate.py` (determinism against `docs/release/sim_baseline*.json`, seeds 1 and 2,
   days 10 and 30, parallel processes); `long-sims.yml` (manual, 365 days); `households_sim.gd`, `regions_sim.gd`, `earn_sim.gd`;
   `judgment_perf.gd` (synthetic 100 to 2000 people, the only 500-person harness; there is no 500-villager World harness).
4. **Structured exports:** `economy_sim --out` (JSON samples, ledgers, deaths, flows, fingerprint) and the recorder archive.
5. **Excel generation:** none.
6. **CI:** `tests.yml` (staging pushes: unit tests, Godot suites, `recorder_test`, a 10-day unrecorded simulation);
   `long-sims.yml` (manual); `release.yml` (manual, three platforms; no simulation).
7. **Missing instrumentation (before):** village aggregates, chases and pursuit, relations and judgment changes, production and
   consumption amounts, contracts, business, farming, mining, settlements, the code that set a chase's target.
8. **Integration made:** sections 2 to 5.
9. **Tests:** section 8.
10. **Runtime and storage:** section 4.

### 1.2 What a recorded run actually captures (seed 1, 10 days, `9304446`)

`economy_sim.gd --days 10 --seed 1 --every 5 --record DIR`, run beside the same command without `--record`: the fingerprints are
identical at days 0, 5 and 10 (`29bf72b0...`, `f821572a...`, `a47f2e6d1d9b8bb756e8080155c1ee52`, also the accepted baseline's
day-10 value); currency and item leaks 0. Wall time 60.5 s unrecorded, 69.7 s recorded (+15%, both side by side on 4 cores).
Archive: 5,439,686 bytes in 1,745 chunks; rows: event 37,235, participant 40,448, decision 21,901, alternative 296,513,
factor 170,337, state_change 9,969, sample 27,067, alert 308, link 0. Complete, 0 unknown codes, 0 early flushes, peak buffer
6,088 rows. What it held: 20,496 decisions with a plan and 1,405 without; 39 action kinds (eat_home 1,645, rest_end 1,332,
sell_to 1,323, enter 1,300 ...); 1,588 accepted trades, 1 refused; 1,324 transfers; tax 89, wages 80, repairs 102, reeve_day 10,
pay_guards 10; births 6, deaths 2, settlement births 29; crime: raise_alarm 3, report_crime 12, robbery 2; 308 unattributed
holder alerts (warnings: coin sites not instrumented), 0 world-total violations. Missing in it: no village aggregate, no guard
chase, no relation or morality change, no production amount, no walk-lost event in ten days (the path search never failed).

## 2. The recorder, schema 2

`docs/design/FLIGHT_RECORDER.md` sections 3 and 8. In short: an hourly `snapshot` row (48 values, 2 to 3 KB a game day), one
`combat` event per chase (from `NPCBrain.fight`), and `session.json final_snapshot`. Read-only and RNG-neutral like the rest
(`judgment.counts()` is not called: it flushes gossip). Recording stays off by default; the CI turns it on with `--record`.
Bounded: the existing 50,000-row buffer, hourly incremental chunk files, the 1 GiB cap (stop, keep, mark incomplete), which the
gate treats as a failure.

## 3. The gate (`tools/sim_suite.py`)

`python3 tools/sim_suite.py --out DIR` (the release workflow's step; `--only` for a targeted subset while developing, which
never counts as a gate). Each run is its own Godot process with its own user data and temp directory, four at a time (the CPU
count), longest first; `MML_COMMIT` names the commit in every recorder session.

| Run | Scenario (directive section 3) | Seed | Days | Recorder | Coverage |
|---|---|---|---|---|---|
| `eq_s1` | A normal equilibrium; the accepted baseline's seed | 1 | 30 | on | A C D E G |
| `eq_s2` | A normal equilibrium, profiled (`--profile`: time per subsystem) | 2 | 30 | on | A C D E G H |
| `det_s1` | eq_s1 without the recorder: determinism and recorder neutrality | 1 | 30 | off | |
| `b18_s1` | judgment off (`--no-judgment`): the Build 16 to 18 rules, for their baselines | 1 | 30 | off | |
| `food_start` | B no stored food at the start (`--set start_granary_days=0 --set start_household_wheat_per_member=0`) | 3 | 20 | on | B C |
| `corner_wheat` | B the wheat bought up on day 5 (existing `--scenario corner_wheat`) | 3 | 20 | on | B D |
| `hunt_out` | B deer and boar hunted out on day 5 (`--scenario hunt_out`) | 4 | 20 | on | B |
| `kill_smiths` | B the smiths, so new tools, lost on day 5 (`--scenario kill_smiths`) | 4 | 20 | on | B C D |
| `no_caravan` | B and D: no caravan after day 1 (`--set caravan_every_days=100000`): trade cut off | 5 | 20 | on | B D |
| `crime` | F the player's theft, pickpocket, killing and flight, assault, second killing from day 3 (new `--scenario crime_spree`) | 1 | 15 | on | E F G |
| `rot_<seed>` x 2 | rotating sample: seeds `100 + int(commit[0:8], 16) % 9900` and `[8:16]` | from the commit | 20 | on | A C D G |
| `probe_saveload_s1`, `_s2` | save and load integrity (`sim_probes.gd --probe saveload`, 2 days) | 1, 2 | 2 | | |
| `probe_pursuit` | F the owner's corner case (`sim_probes.gd --probe pursuit`) | 1 | 1 | on | F |
| `probe_manhunt` | F the manhunt: hue and cry, search, wanted across save and load, yielding (`--probe manhunt`) | 1 | 1 | | F |
| `probe_playtest` | the owner's playtest corrections, watched (`--probe playtest`, section 10; never blocking) | 1 | 3 + 4 | | E F |
| `perf_scaling` | H 100 and 500 people (`judgment_perf.gd --sizes 100,500 --days 10 --rates live`) | | 10 | | H |

**Checks.** For every economy run: exit code and script errors (crash), the FATAL line, currency leak and item ledger
(conservation), the neighbouring settlements' books. For every recorded run: `tools/recorder_archive.py` (every chunk whole,
footers and sha256, row sequence 1..last_seq exactly once, table counts equal to the session's, snapshots an hour apart, the
session ended complete, no unknown code, a closing snapshot), the recorder's `coin.unattributed_total` alerts (coins created or
lost outside the books) and the reconciliation of the closing snapshot and the events with economy_sim's own output: villagers
alive, currency, treasury, villager deaths, births plus arrivals. Determinism: `eq_s1` and `det_s1` identical at every 5-day
checkpoint (the same values `tools/sim_gate.py` compares). Baseline: `eq_s1` and `eq_s2` against `docs/release/sim_baseline.json`
at days 10 and 30 (blocking); Build 19 (same rules), Build 18, 17 and 16 (judgment off, via `b18_s1`) compared and reported,
never blocking: those differences are the approved changes since. Save and load: nothing dropped or changed, a second round
trip identical. Coverage: A to H all ran to their end. The workbook: written by the game's code, then validated by
`tools/check_workbook.py` (every sheet and chart, every chart range, the Runs sheet against economy_sim's output).

**Never failed:** hardship, deaths, shortages, collapse (WDR-022); measures with no approved number (section 9); the playtest
watches (section 10). The corner pursuit (`probe_pursuit`) and the manhunt (`probe_manhunt`) block since GP-CRIME-PURSUIT
landed (repairs S3, A1-A3).

**Release workflow** (`.github/workflows/release.yml`): job `sim-gate` (checkout, Godot, import, the suite) and job `build`
with `needs: sim-gate`, so a failed gate packages nothing on any platform. Artifacts `sim-gate` (gate.json, the summary, the
workbook, each run's sim.json, log, analysis and probe; 90 days) and `sim-gate-archives` (the recorder archives; 14 days), both
uploaded also when the gate fails. The build job downloads `sim-gate`, refuses to package unless its `gate.json` names the same
commit and a full, passing, uninjected gate, and appends the summary, the run link and the recorder schema to the release notes.
The workbook is never attached to the release (amendment). The private/public, signing and build-number inputs are unchanged.
The APK is listed after export and the build fails if it holds `recorder_export` or `sim_workbook`.

## 4. Measured runtime and storage

Full suite at `1d97953` (the code of this branch; later commits changed only the analysis and documents), this machine (4
cores), four jobs at a time; another agent's two 30-day simulations shared the machine for part of the run, so the times are
upper bounds here. Storage: recorder archive bytes (gzip chunks), rows in all tables.

| Run | Days | Wall seconds | Seconds a day | Archive bytes | Rows |
|---|---|---|---|---|---|
| eq_s1 | 30 | 346.3 | 11.5 | 17,178,707 | 1,867,697 |
| eq_s2 (profiled) | 30 | 347.6 | 11.6 | 17,047,583 | 1,858,817 |
| det_s1 (no recorder) | 30 | 310.0 | 10.3 | | |
| b18_s1 (no recorder) | 30 | 287.6 | 9.6 | | |
| food_start | 20 | 228.9 | 11.4 | 11,814,960 | 1,305,364 |
| corner_wheat | 20 | 254.3 | 12.7 | 11,605,854 | 1,268,409 |
| hunt_out | 20 | 290.3 | 14.5 | 10,933,183 | 1,180,417 |
| kill_smiths | 20 | 282.7 | 14.1 | 10,818,287 | 1,177,498 |
| no_caravan | 20 | 243.6 | 12.2 | 11,310,509 | 1,228,489 |
| crime | 15 | 128.6 | 8.6 | 8,364,977 | 897,519 |
| rot_8299 | 20 | 215.6 | 10.8 | 11,331,232 | 1,230,211 |
| rot_4603 | 20 | 181.5 | 9.1 | 11,263,577 | 1,220,083 |
| probe_saveload_s1, s2 | 2 each | 25.2, 20.9 | | | |
| probe_pursuit | 1 | 16.6 | | (small) | |
| perf_scaling (100 and 500 people) | 10 | 10.0 | | | |
| **Total** | **275** (215 recorded) | **3,190 job-seconds; 812 s wall on 4 jobs** | | **121,668,869** | **13,234,504** |

Then the analyses (10 archives, 25.7 s) and the workbook (27.3 s; 1.37 MB, 13 sheets, 11 charts, 20,000 event records).
Whole gate here: about 15 minutes. The second run, at `97f0bac` with the workflow's command, took 745 s for the simulations
(2,904 job-seconds), 58 s for the analyses and workbook, 841 s in all, with archive sizes within 0.1% of the first. Results directory 250 MB on disk (archives 122 MB of data; analyses 18.9 MB). Recorder overhead,
same seed side by side: 346.3 s against 310.0 s (+11.7%); +15% in the 10-day pair of section 1.2. About 0.57 MB and 61,000 rows a
recorded day for about 110 people; the snapshot table adds about 2 to 3 KB a day.

**On GitHub** (4 vCPU runners): the 365-day unrecorded runs measured 41 to 84 minutes a seed on Build 16 code (6.7 to 13.8 s a
day, CLAUDE.md section 5), so the suite's 3,190 job-seconds here should take roughly 15 to 25 minutes of wall time there, plus
the import and the workbook; the job's limit is 120 minutes. Not yet measured on a runner: the first release run will be.

**Sample sizes and their limits.** Two fixed equilibrium seeds of 30 days (the accepted baseline's: the comparison is exact),
five stress scenarios of 20 days (the shock on day 5 and fifteen days of response; longer recovery is not seen: SIM-01's long
runs remain `long-sims.yml`), one crime scenario of 15 days (one sequence of crimes; a different victim or guard layout needs
another seed), two rotating seeds of 20 days a commit (over many commits they sample new worlds; one commit sees only two). Each
scenario runs one seed, so a scenario's result is one world's, not a distribution. The 500-person scale is the judgment
harness's synthetic load, not a 500-villager village (none exists). A year is not run here: the long-run directive's runs are
separate and too long for a release job.

## 5. Proofs (directive "Mandatory proof of completion")

All local, this machine. The full suite was run twice: at `1d97953` (`full1`) and, with the exact command of the workflow's
gate step, at `97f0bac` (the branch head before this document):
`python3 tools/sim_suite.py --out out/sim-gate --godot <godot> --jobs "$(nproc)"`.

| Proof | Result |
|---|---|
| A full village simulation ran | 12 economy runs, 275 simulated days (215 recorded), seeds 1, 2, 3, 4, 5 and the rotating 2491, 4970 (`97f0bac`; 4603, 8299 at `1d97953`), all scenarios A to H to their end; 0 crashes, 0 script errors |
| The recorder captured events and hourly snapshots | 10 archives, 121.7 MB, 13.2 million rows, every chunk whole (footers, sha256, sequence 1..last_seq once, counts), one snapshot an hour in every run (721 for 30 days), the closing snapshot written |
| Exports match the simulation's truth | every recorded run: villagers alive, currency, treasury, villager deaths, births plus arrivals from the recorder equal economy_sim's own output (the gate's reconciliation and the workbook's Runs sheet, checked by `tools/check_workbook.py`); 0 `coin.unattributed_total` alerts |
| The workbook was generated and validated | `sim_gate_workbook.xlsx`, 1.37 MB, 13 sheets (the ten required and Runs, Proposed Thresholds, Events), 11 charts, every chart range numeric and on an existing sheet; opened by LibreOffice (rendered to PDF and looked at: every required chart draws its data) and by openpyxl |
| Historical comparisons | the accepted baseline `sim_baseline.json` (7551616): 36 values identical (fingerprints, alive, households, currency, treasury, leaks, ledgers, deposits, animals, seeds 1 and 2, days 10 and 30) with the recorder on; Build 19 (417c07f): only the item ledger's new `rusty_axe` row differs, as DECISIONS.md records; Builds 18, 17, 16 (judgment off): 14 to 16 values differ, the approved changes since, reported; and the two independent suite runs gave identical fingerprints for all ten fixed runs |
| A deliberately failed gate stopped packaging | `--reuse full1 --inject leak` (currency leak in eq_s1's output): exit 1, blocking conservation, reconciliation, determinism and baseline findings; `--inject corrupt` (a crime-run chunk torn, footer gone): exit 1, "no footer (truncated)", 30 rows missing, count mismatch; `--inject crash` (a script error in a log): exit 1. The workflow's packaging check run on those gate.json files refuses ("the simulation gate did not pass on this commit"), and in GitHub the build job, `needs: sim-gate`, never starts after a failed gate. Also `tests/test_sim_gate.py` (leak, item leak, script error, determinism and baseline differences block; hardship does not) |
| A passing gate permits packaging | the gate step's command at `97f0bac`: `PASS`, exit code 0, 841 s; gate.json names that commit, full and uninjected, so the build job's check would let the three-platform export run. The release workflow itself was not run here (the lead runs releases) |
| The recorder did not alter determinism | eq_s1 (recorded) and det_s1 (not) identical at every 5-day checkpoint in both suite runs, and both identical to the accepted baseline (recorded unrecorded, at another commit); seed 1, 10 days: identical fingerprints at days 0, 5, 10 (section 1.2) |
| APK exclusion | Godot's own export with the presets (`--export-pack "Android"` to a zip, 1,366 entries): 0 entries under `scripts/recorder_export/` or `data/sim_workbook.json`, while the core recorder (`scripts/core/recorder/*.gdc`) is there; the Linux pack has all 9 export entries. `tests/test_sim_gate.py` checks the presets and that no shipped script names the export; `release.yml` lists the APK and fails on a match |

Artifacts of the passing run (git-ignored, this machine): `out/sim-gate/gate.json`, `out/sim-gate/SIM_GATE_SUMMARY.md`,
`out/sim-gate/sim_gate_workbook.xlsx`, `out/sim-gate/<run>/{sim.json,run.log,analysis.json,rec/}` in the worktree.

## 6. Not in the game yet (reported, not faked)

- **Wanted status, the search, the hue and cry, taking an offender in:** in the game since GP-CRIME-PURSUIT (repairs S3,
  A1-A3) and checked by `probe_manhunt` and `probe_pursuit` (blocking); the recorder's chase events name the new ends (`taken`,
  an ok outcome; `lost_sight`, the hand-over to the search; `case_closed`). The search and the wanted state themselves are not
  recorder events (the probe reads them from the world).
- **Good/Bad opinion ledger changes, gossip propagation, per-relation changes:** not instrumented (recorder stages D4, D5); the
  snapshot carries hourly totals only.
- **Production and consumption by item and actor:** the game's counters (`w.stats`) per hour, not per actor; contracts, business,
  farming and mining internals are not instrumented.
- **Schedule compliance:** the game keeps no schedule to compare against; the workbook says so.
- **A 500-villager World:** no harness exists; the 500-person scale is `judgment_perf.gd` (synthetic judgment load).
- **Timber and ore shortage switches:** no start-condition override exists for deposits or trees; ore runs out on its own in the
  normal runs (copper and gold at about day 10, seed 1), which the workbook shows.
- **A resumed simulation:** not designed (PERF-06), so save-load is checked as integrity (round trip), not as continuation.

## 7. Desktop recording and export (amendment)

- **Setting:** Settings, Saves, "Record gameplay: on/off" (Windows and Linux only), off by default, `[developer] record_gameplay`
  in `user://settings.cfg`; it attaches or closes the recorder at once.
- **Export location:** Settings, Saves, "Export the recording..." writes to `Documents/My Medieval Life/recordings/`
  (`user://recordings` if the system has no Documents folder) the workbook, `_analysis.json` and `_archive.zip`, then opens the
  folder.
- **Storage bounds:** the recorder's: 50,000-row buffer, hourly chunk files under `user://recorder/<session>/`, 1 GiB cap per
  session (stops, keeps, marks incomplete). About 0.5 to 0.6 MB a game day for about 110 people. The export streams the archive
  chunk by chunk; the workbook keeps at most 20,000 event records.
- **Android:** `export_presets.cfg` Android `exclude_filter` adds `scripts/recorder_export/*` and `data/sim_workbook.json`; the
  setting is not shown (`Main.recording_supported`); nothing in the shipped scripts names the export (only `main.gd` loads it by
  path); `release.yml` fails if the APK lists either. APK-exclusion proof: section 5.

## 8. Tests

- `game/tests/recorder_test.gd`: + the snapshot (one an hour, every column, counts agree with the events) and chases
  (`test_chase_events`).
- `game/tests/live_export_test.gd`: the desktop export (workbook sheets and charts, analysis, archive; the recorder goes on).
- `tests/test_sim_gate.py`: the archive check (whole, truncated, missing rows, unfinished, tampered), the gate's decisions on
  fabricated outputs (clean passes; currency leak, item leak, script error, determinism difference and baseline difference block;
  hardship does not), rotation, coverage, the workbook check, the Android exclusion.
- The suite itself: `tools/sim_suite.py` (the gate), its probes `game/tests/sim_probes.gd`.

## 9. Proposed thresholds (owner decision; never blocking)

Measured in the passing run; none blocks; each needs an owner decision before it could become a rule.

| Measure | Value measured | Proposed | Why |
|---|---|---|---|
| Longest hours a villager stayed on one cell while travelling or lost | 2 | review at 3 | no approved requirement sets a number for stuck villagers; work, rest and waiting in place are not counted |
| Navigation failures (walk lost) a villager-day | 0.0 | review if it doubles against the accepted baseline | the path search never failed in 215 recorded days |
| Unattributed coin changes (holder alerts) a simulated day | 24.07 | no growth against the previous build | REC-D4: about 150 coin sites are detected, not attributed; the world total balances (0 violations) |
| Machine seconds a simulated day, worst run, four in parallel | 11.55 | 1.5 x the accepted build's value on the same runner | no approved headless budget (CLAUDE.md section 8) |
| Recorder overhead, same seed side by side | +24% (+11.7% in the first suite run, +15% in the 10-day pair) | under 50% | noisy when the runs share the machine |
| 500-person judgment load (synthetic) | 387 ms a simulated day; worst frame 7.7 ms; p99 2.0 ms | the agent proposal in `docs/expansion19/DESIGN.md` section 7 | proposed budgets, not approved |

The corner pursuit is not a threshold: GP-CRIME-PURSUIT is implemented and its probe blocks.

## 10. Build 21 audit: the owner's playtest corrections (2026-10-24)

Owner directive `docs/directives/2026-10-24_build21_final_integration.md` section 6. Reconciled against the code at `1a6fb4b`:
the pursuit and manhunt probes already followed the crime repairs; obsolete text above (sections 3, 6, 9) is corrected; the
recorder's `taken` chase end is an ok outcome (it was counted "interrupted"); the coverage note lists the new chase ends.

Added: `probe_playtest` (`sim_probes.gd --probe playtest`, seed 1, 3 days of the whole village, then the band killed and watched
for a season and two days). It measures, never blocks (known-defect watches with no approved number; each failing watch is a
"major", non-blocking finding in the gate):

| Owner correction | Watch | Automatic? |
|---|---|---|
| Bandits dying at once, vanishing, not respawning (SIM-F4, BANDIT-RETURN) | a bandit dead within 2 hours of appearing; one gone from the world with no death; at night (01:00-03:00) at the camp, out stalking, or elsewhere; outlaws back a season after the band died, alive, at the camp | yes |
| Guards' pursuit, search, wanted (GP-CRIME-PURSUIT) | `probe_pursuit`, `probe_manhunt` (blocking) | yes |
| Station reach, the use cell free (GP-ANVIL) | each station's use cell open, no other station on it, in reach from it, reached by a path; at the start and after 3 days | yes |
| A trail to every door (GP-BACK-DOORS) | the generator's own check (`tests/test_village.py`) and `polish_p2_test.gd` | yes (static) |
| Characters walking under building edges / on walls | villagers on a solid cell, every hour | yes |
| Gossip said over and over (GP-DIALOGUE A6) | every grown villager asked for news twice the same day: a sentence of the first answer in the second | yes |
| No coins or goods made or lost | every economy run's ledgers and the recorder's coin audit (blocking) | yes |
| Menus' size, the brown pause background, roofs, back doors on roofs, interior walls, the smithy wall, sprite choices, the bandit camp's pictures, the campfire | none: what it looks like is the owner's to judge on a device | no (visual) |
