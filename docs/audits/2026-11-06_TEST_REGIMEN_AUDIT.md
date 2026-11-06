# Test regimen audit, 2026-11-06 (TEST-AUDIT-01)

Owner directive: `docs/directives/2026-11-06_permanent_testing_governance_and_test_audit.md`. Governance: `docs/TESTING_GOVERNANCE.md`
(TEST-GOV-01). Inventory appendix: `docs/audits/2026-11-06_TEST_INVENTORY.md`. Repairs on branch `wip/test-audit` (from the Play Test
Build One candidate's branch at `7c1bac4`), kept apart from the candidate until validated. Counts, not percentages. Times Eastern.

## A. Executive findings

| Measure | Count |
|---|---|
| Godot test scripts in `game/tests/` | 281 (225 suites run by CI; 56 tools, probes, simulators, fixture generators, helpers; 1 stray scratch file, removed) |
| Python test files in `tests/` | 18 (195 tests; 1 skipped by design, needs a real gate's output) |
| Data and tool checks in CI | 5 (`check_interactions`, `check_requirements`, `check_resources`, `check_materials`, `build_weapons`) plus the 10-day simulation smoke run |
| Checks run by the full suite (832f711) | 18,303 |
| Workflows | 9 (2 run on push to staging, 7 by hand or as called workflows) |
| Simulation baselines and pinned evidence | 12 baseline files (1 blocking, 4 compared, 7 historical), 3 pinned-hash sets, 1 new check-count floor file |
| Mutation sampling | **9 unique injected defects**, 10 rows (M6b is M6 run against 5 more suites); 25 existing suites run against them, plus the new workplace_reach_test. Outcomes: 7 detected (M1, M2, M3, M4, M5b, M7, M8); 1 equivalent (M5: the generation-8 fallbacks lay the same dry roads; its stronger form M5b is detected); 1 undetected by all 9 suites tried (M6, coverage gap G2), now detected by `workplace_reach_test` |
| Testing defects confirmed | 13 (section C, T1-T13) |
| Testing defects repaired | 13 (all of T1-T13; each repair in section C) |
| Testing defects tracked, not repaired | 0. (The earlier "2 tracked" counted two coverage gaps, G1 and G3, as defects: they are gaps, section E) |
| False-positive risks (a red that may not mean a defect) | 4: the gate's baseline of another generation (repaired: now labelled); 19 suites with wall-clock thresholds; 12 multi-process network suites (timing); the CI shard time limit when placement drifts (repaired) |
| False-negative risks (a green that may hide a defect) | 8: script errors ignored (repaired); no-count suites (repaired); printed failures with exit 0 (repaired); silent early stops (repaired: floors); save_continuity_test left out the player (repaired); 3 data-dependent skips (guarded by floors; none fire today); performance measured, never asserted in CI; the Windows smoke run is headless only |
| Coverage gaps | 10 identified (section E: G1-G10); 2 closed (G2 by workplace_reach_test, G5 by plan_continuity_test); 8 open, each classified in section I |

Validity, by what this audit could establish: 26 suites mutation-tested (25 existing, 1 new); 16 suites repaired or created; all 225
(now 227) CI suites run under the strict rules (run 42286848307: 232 suites passed, 18,896 checks, 0 script errors, none under its
floor). The rest are read by the static scan only. No suite is claimed valid beyond that. Exhaustive mutation testing of 227 suites
(about 28,000 runner seconds a pass) was not attempted.

## B. Inventory (summary; every item in the appendix)

- **CI (`tests.yml`)**: 12 shards; each suite through `tools/ci_report.py` (a log per suite, its counts, its first failures); a report job
  that fails when a shard is missing, cancelled, timed out, ran another commit or list, or when the shards do not cover the list exactly
  once (verified: 225 listed, 225 run, no duplicates, on 832f711).
- **Simulation**: `long-sims.yml` (comparison runs, the flight-recorder campaign of seeds 1 and 2 for 365 days in 100-day segments with
  twin chains and a save round trip per segment, the gate on any branch); `sim-gate.yml` (SIM-GATE-01: 19 runs, 8 seeds, scenarios A to J,
  determinism pairs, baselines) called by `release.yml` and `long-sims.yml`.
- **Builds**: `release.yml` (6 packages from one commit, the Windows smoke runs, a release only when the gate passed); `win-smoke.yml`
  (smoke an existing artifact).
- **Records**: `requirements.yml` (the register and its history).
- Static risk flags over the 225 suites: 0 unseeded randomness; 1 quit(0) path (travel_perf_test's manual `seconds=` mode only);
  19 wall-clock thresholds; 56 early returns inside checks (now guarded by the floors); 3 data-dependent skips (none fire on 832f711);
  12 multi-process or network suites.

## C. Confirmed testing defects (classified per TEST-GOV-01)

| # | Class | Defect | Evidence | Repair |
|---|---|---|---|---|
| T1 | C/D | CI judged a game suite by its exit code: a SCRIPT ERROR was counted but ignored | chapel_test PASSED on f3c5bdd (run 42263249923) after a script error, 166 of 175 checks run; replayed through ci_report: old rules pass, new fail | `2027707`: game group runs with `--fail-on-script-errors` |
| T2 | C | A suite that printed failures but exited 0 earned only a warning | `test_ci_report` | `2027707`: a failure |
| T3 | C | 9 suites printed no "N checks, M failures" line, so CI could not tell how many checks ran | results.jsonl of run 42274258964: `checks: null` | `2027707`: each counts; CI `--require-counts` |
| T4 | C | A suite that stops early without an error (an early return, a skipped block) passed | the 56 early returns, the 3 skips | `2027707`: `tools/ci_check_floors.json`, 225 floors; counts identical between f3c5bdd and 832f711 except chapel's recovered 9 |
| T5 | C | chapel_test test_b17_save loaded a generation-2 save that loads refuse (B25R1-Q5), so the world never loaded and the test stopped | SCRIPT ERROR at chapel_test.gd:968 | `832f711`: refusal checked, then loaded at the current generation; 175/0 |
| T6 | B | save_transfer_test copied the old tree-load rule by hand | full suite f3c5bdd | `0550c1d` |
| T7 | C | save_continuity_test said "the same in every part" but compared no part of the player | mutation M2: player coins loaded +1, test passed | `cb7f80b`: player compared; mutation now fails it |
| T8 | C | judgment_personality_test: a literal % in three messages (formatting errors; the checks ran) | engine ERROR lines | `832f711` |
| T9 | B/E | water_test pinned "whatever generation is current" as GOLDEN_4: the next bump would overwrite generation 8's evidence | the file | `7199a9a`: GOLDEN_7 and GOLDEN_8 each created by number |
| T10 | E | SIM-GATE-01's accepted baseline records no generation or save version, so a generation-8 world against a generation-4/5-era baseline (df67e8e, 2026-11-03) is reported as 31 "unapproved differences" | run 42274351589; bisection to `bf20dc9` (`docs/release/SIM_BASELINE_DIFFERENCES_B25R2.md`) | `8d239a9`: baselines record their versions; a baseline of other versions is reported "not applicable" first; still blocks |
| T11 | D | CI shard placement used timings missing for 19 suites and drifted up to 20x: shards 22-56 min | run 42274258964 | `8d239a9`: measured timings; predicted 27-34 min |
| T12 | C | A scratch script committed into `game/tests/` | `zz_ascii.gd` (c0be482) | `2027707`: removed |
| T13 | coverage | No suite checked that villagers reach their workplace | mutation M6/M6b passed 9 suites | `d8ed2b2`: `workplace_reach_test` |

Mutation sampling (disposable worktree at `7c1bac4`, each defect alone, reverted; nothing committed):

| Mutation | Suites run | Caught by | Missed by | Reading |
|---|---|---|---|---|
| M1 an item created on a multi-item add | stalls, business, trade_skills, econ_p2p3 | 3 | trade_skills | detected in its area |
| M2 the player's coins +1 on load | save_exact, save_transfer, farm_shared_save, save_continuity | 2 | farm_shared_save, save_continuity | save_continuity defect T7, repaired; farm_shared_save is about farms (expected miss) |
| M3 a coin created on every sale | business_money, econ_p2p3, stalls, trade_skills | 3 | trade_skills | detected |
| M4 the travel bar refuses the pad | pad_reach, gamepad_map, pad_shortcuts | 1 | 2 (they do not cover the bar) | detected by the suite that owns it |
| M5 generation 8's dry-way search disabled | bridge_validity, travel_river, road_types | 0 | 3 | see M5b: the later fallbacks lay equally dry roads, so this mutation may be equivalent |
| M5b generation 8's crossing repair skipped entirely | bridge_validity, travel_river | 2 | 0 | detected (bridge_validity: 7 of 8 seeds fail; travel_river: 0 journeys planned): M5 was an equivalent mutation |
| M6 villagers walk to where they stand instead of their workplace | job_board, health_jobs, business, stalls | 0 | 4 | see M6b |
| M6b the same against the work suites | desk, courier_desk, contracts, elder_provision, discovery | 0 | 5 | **gap G2 confirmed** (9 suites); new `workplace_reach_test` catches it (`d8ed2b2`: 4/0 correct, 2 failures with M6) |
| M7 skill experience never added | skills, trade_skills, skilled_employment | 2 | skilled_employment | detected |
| M8 unseeded randomness in villagers' hunger | recorder_neutrality, save_continuity, save_exact | 2 | save_exact | detected: the determinism checks are real (save_exact compares one round trip, not a run) |

## D. Baselines and simulation

- **SIM-GATE-01 on 832f711 (run 42274351589).** Determinism: recorded against unrecorded identical at every checkpoint, shipped and
  Expansion 20 switches. Conservation: no currency, ledger or script-error finding. The 31 blocking findings are all differences from the
  accepted baseline. Cause (class E, not A): the baseline predates the band household (`bf20dc9`, owner-approved B25R1-Q2 a) that gives
  every new world a 26th household at the founding (bisected), and predates overworld generations 6, 7 and 8; the B25R2 repairs move the
  values further. The baseline is not re-recorded (B25R2-Q1); accepting one for generation 8 needs the owner.
- **Partitions against the final.** Parts 2 and 3 PASS, parts 0, 1 and 4 FAIL, the merged evaluation FAIL: correctly reported (a part runs
  a subset; the merge re-evaluates every run). Part 0's one failure is its own workbook missing a chart (a subset has no historical sheet
  data); the merged workbook is complete. Recommendation: a part's workbook check should not count a chart only the merged workbook has
  (low).
- **Determinism checks are real**: two independent worlds, compared at every checkpoint; mutation M8 (unseeded randomness) was caught by
  recorder_neutrality_test and save_continuity_test.
- **Generations.** Generation 7 keeps its recorded fingerprints (`water_test` GOLDEN_7, seeds 1, 2, 7: unchanged since before
  generation 8). Generation 8 is pinned on its own (GOLDEN_8). No test compares generation 8 against 7. A loaded world keeps its own
  generation (`World.load_dict` passes the save's generation; `aerial_map` too). New worlds are generation 8 (`water_test`, `crafts_test`).
- **Save/load.** What is compared: `save_exact_test` (every top-level section after a round trip), `save_continuity_test` (state after
  load; two loads go on identically; now the player too), `save_transfer_test` (every listed section through an export and import), the
  campaign's per-segment round trip (every section), migration fixtures (`gen_*_fixture` and their tests). Intended reconstruction:
  villagers' plans, headings and paths are not saved (agent decision, B25 save continuity, 2026-11-01), so a loaded world is deterministic
  from its save, not identical to the unbroken one. **The cart hold** (a villager pulling a cart lets go on load, KI-FR-CARTHITCH, agent
  decision 2026-11-02): no item, coin or cart is lost (the cart keeps its place, load and owner), and without it the cart would stay held
  for ever; but a market run under way at the save does not finish after the load. It is the consequence of unsaved plans, an agent
  decision never put to the owner: tracked as an owner question (section G), not called acceptable because the code does it.

## E. Coverage gaps (by gameplay impact)

| # | Gap | Impact | Evidence |
|---|---|---|---|
| G1 | Real controllers and Windows hardware: every controller test is headless (events injected); the Windows smoke run starts the game headless for 300 frames (exit code, script errors, leaks), never drawing, playing or using a pad | High: the playtest's main input | release.yml smoke-windows; pad_* suites |
| G2 | Villagers going to their workplace: mutation M6 passed 9 suites | High | repaired `d8ed2b2` (workplace_reach_test) |
| G3 | Performance is measured, never asserted in CI (`travel_perf_test` asserts only that the walk arrives; `--assert` is manual) | Medium: a stutter regression would pass CI | tests.yml |
| G4 | Register traceability. Matrix (`docs/audits/2026-11-06_REQUIREMENTS_TEST_MATRIX.md`, 742 integrated or NOT TESTED approved records): 445 traced; 76 tested but untraced (a suite cites the id); 15 covered indirectly (checked by hand); 3 gaps (G10); 7 need a device or a person; 81 process, documentation or art; 59 not built yet (no test expected); 56 built, uncited and not yet checked by hand. One record names a test that does not exist (MP-01: net_test) | Medium | the matrix |
| G5 | NPC plans across a save (the cart hold) | Medium | **closed**: owner decision TEST-AUDIT-Q1 implemented (`adf71ec`); `plan_continuity_test` 15/0, 6 failures without the change |
| G6 | The skipped Python gate test (`test_sim_gate.RealGateSplit`) never runs in CI | Low | unittest output |
| G7 | 109 approved requirements wait on a device or owner playtest | Owner | register `playtest` |
| G8 | Interactions are covered unevenly: travel and geography (travel_river, region_travel, bridge_validity, seed_traveler), economy and inventory (econ, stalls, business, inventory18), employment and skills (skilled_employment, trade_skills), multiplayer and persistence (net_fault host restart, net_mp4) have joint tests; controller input and menu state, and families across long simulation, rest on single-system suites and the 365-day campaign | Medium | inventory |
| G9 | 19 suites assert wall-clock thresholds that a slower runner can break (false-red risk) | Low | static scan |
| G10 | Three built requirements with no meaningful test (checked by hand): B13-01 a retirement opens the post; B8R-002 a villager trapped inside a door; B7-008 the player draining buyers or hunting out the wildlife | Medium / medium / low | `2026-11-06_REQUIREMENTS_TEST_MATRIX.md` |

## F. CI efficiency

- Full suite on 832f711: 225 game suites, 24,100 runner seconds; Python 109 s; simulation smoke 108 s. Slowest: run_tests 1,095 s,
  courier_live 615, chapel 578, multiplayer_c 475, home 429.
- Shards ran 1,255-3,216 s (21-54 min wall) because placement timings were missing or stale (T11). With measured timings: 1,648-2,042 s
  predicted (about 34 min). Same suites, same coverage.
- No suite runs twice in one workflow; tests.yml runs on pushes to staging only (paths filtered) and by hand; the release workflow runs
  `run_tests`, `start_test`, `demo_test` once more inside the Linux package job (intended: the packaged commit).
- Long simulations: the 365-day campaign is about 7 hours of runner time in chained 100-day segments with twins; the gate about 18 minutes
  of simulation on 4 workers.

## G. Corrective action register

| Priority | Item | State |
|---|---|---|
| Critical | T1 script errors ignored in game suites | Repaired `2027707`; full-suite validation run 42286848307 |
| Critical | T4 silent early stops | Repaired `2027707` (floors) |
| High | T3 suites without counts | Repaired `2027707` |
| High | T7 save_continuity_test missing the player | Repaired `cb7f80b` |
| High | T10 gate cannot tell another version's baseline from a regression | Repaired `8d239a9`; accepting a generation-8 baseline: owner |
| High | G1 real hardware and controller verification | Owner playtest (cannot be automated here) |
| High | G2 villagers' workplace untested | Repaired `d8ed2b2` |
| High | G5 villagers' plans across a save | Repaired `adf71ec` (owner decision TEST-AUDIT-Q1) |
| Medium | G3 performance not asserted | Open: proposal, assert the journey's chunk work (not the known first-frame and 17:00 world spikes) |
| Medium | G4 register traceability | Open |
| Medium | T11 shard placement | Repaired `8d239a9` |
| Low | T2, T6, T8, T9, T12 | Repaired |
| Low | G6, G9, the part workbook chart | Open |

## H. Verification evidence

- Runs: full suite 832f711 42274258964 (success); f3c5bdd 42263249923; gate 42274351589; F2 gate 42154224992; package 42284391094;
  campaign 42274347279; audit branch full suite 42286848307.
- Commits: candidate `832f711`/`7c1bac4`; audit `2027707`, `8d239a9`, `7199a9a`, `cb7f80b` on `wip/test-audit`.
- Reproductions: chapel_test replay (old rules pass, new fail); save_continuity_test with M2 (passes before the repair, fails after);
  mutation logs (section C); the household bisection (`docs/release/SIM_BASELINE_DIFFERENCES_B25R2.md`).

## I. Unresolved items (directive part 9)

| Item | What remains unverified | Why it matters | Risk | Verification needed | Blocks Play Test Build One | Evidence |
|---|---|---|---|---|---|---|
| G1 hardware and controllers | Drawing on a Windows GPU, a physical pad, audio devices, window modes, input latency | The playtest is played on a Windows PC with a controller | High | The owner plays the package with a pad | No: it is what the playtest is for; recorded as an owner playtest item (B12A-10) | smoke run is headless only (release.yml) |
| G3 performance not asserted | A stutter regression would pass CI | Repair 3 (stutter) could regress unseen | Medium | Assert the journey's chunk work in CI (the first-frame and 17:00 world spikes are known and excluded) | No: measured on the candidate (travel_perf_test) and reported | travel_perf_test asserts arrival only; `--assert` manual |
| G4 traceability | 56 built requirements uncited and not hand-checked; 76 tested but not named in the register | Coverage cannot be read from the register | Medium | Add the citing suites to the register; read the 56 | No | the matrix |
| G6 skipped gate test | `test_sim_gate.RealGateSplit` never runs in CI (needs a real gate's outputs) | The gate's split evaluation on real data is checked only by hand | Low | Run it in the gate workflow, where the outputs exist | No | unittest output (skipped=1) |
| G7 owner playtests | 109 approved requirements wait on a device or the owner | They cannot be COMPLETE before | Owner | Device checks recorded in the register | No (they are playtest items) | register `playtest` |
| G8 interaction coverage | Controller and menu state, families over long runs: single-system suites plus the 365-day campaign | Interactions can break where each part passes | Medium | Joint tests where play shows a problem | No | inventory |
| G9 wall-clock thresholds | 19 suites can go red on a slow runner | False-red risk | Low | Watch; widen only with evidence of a slow runner, never to hide a regression | No | static scan |
| G10 three requirement gaps | B13-01, B8R-002, B7-008 untested | Old fixes could regress unseen | Medium / medium / low | A focused test each | No: none touched by B25R2 | matrix |

## J. Strict regression, combined candidate and campaign

- **Strict rules validated** (run 42286848307, commit `2027707` on `wip/test-audit`, 20:15:51-21:06:39 UTC): 12 shards and the report,
  232 suites passed (225 game, 6 Python, 1 simulation), 18,896 checks, 0 script errors, no suite below its floor; the only check-count
  changes from 832f711 are the nine newly counted suites and the two new Python tests. No false failure.
- **365-day campaign on 832f711** (run 42274347279, started 18:50:37 UTC): seed 2 segment 3 failed on one SCRIPT ERROR, a genuine
  game defect (class A): a homestead's pending water source was saved as text and failed after a load. Fixed `c903ce8`; the segment
  was otherwise clean (currency leak 0, item leaks 0, save round trip exact, `ok` true).
- **Combined candidate** `1f2ff4f` (`adf71ec` Q1 + `4bfd8fd` merge of wip/test-audit + floors): focused suites 7/7 locally (save_exact
  15/0, plan_continuity 15/0, workplace_reach 4/0, save_continuity 5/0, save_transfer 21/0, homestead 49/0, wilds 72/0); full strict
  suite, 365-day campaign and release workflow dispatched on it.

## Release qualification (directive item 14)

| Step | Must pass | Evidence today |
|---|---|---|
| Build candidate | full suite green on the exact commit (no script errors, every suite at or above its floor), Python suite, data checks | 832f711: green (before the stricter rules); audit rules validating in 42286848307 |
| Windows smoke | package built from the candidate; the game starts headless, exits 0, no script errors, no leaks | 42284391094: success (pkg-full-windows, sha256 0d20c308…188f, 0.1.34) |
| Private playtest | the above; the sim gate's determinism identical; conservation clean; baseline differences explained; the 365-day campaign read (no script errors, ledgers clean, twins agree, round trip exact or explained) | gate determinism identical; differences explained; campaign running |
| Public release | the above with an owner-accepted baseline for this version; the owner's approval | not given |
| Production | the above plus real-device and controller checks recorded in the register | none recorded |

Automated verification does not cover real hardware: drawing on a Windows GPU, a physical controller, audio devices, window modes.
Those are owner playtest items and are never reported as tested by CI.
