# Current session recovery handoff (2026-10-21, evening UTC)

A continuity checkpoint for the lead agent after a context compaction. The register
(`docs/requirements/requirements.json`), `docs/DECISIONS.md`, `docs/directives/` and `docs/CURRENT_DEVELOPMENT_STATE.md`
stay authoritative; this file says where things stand between them. **V** = verified by the lead from git, CI or a test
run; **W** = reported by a worker, not yet re-checked by the lead.

## Follow-up (2026-10-21, after the owner's recovery follow-up directive)

- Worker N committed `b00c7ad` (no uncommitted files); the lead pushed it to `wip/b17-parity`. Still active: no completion
  report yet, so it is not treated as finished.
- Worker L had `7ed3e20` and 45 staged files (a merge of `wip/build17` in progress); left untouched. `wip/b17-equip` holds
  `89f30d3`. Still active.
- Expansion 18 worker: its 2 uncommitted files (`docs/expansion18/DESIGN.md`, `game/tests/capability_test.gd`) are
  preserved without touching its worktree as `wip/expansion18-snapshot` (`b649850`, a snapshot only, never merged).
- STONE-Q part 1 answered (STONE-Q1, Option C); STONE-02, STONE-03 and X18-STONECUT (staging) placed in Expansion 18, not
  Build 17 blockers; STONE-Q part 2 (dressing waste) awaits the owner. `wip/build17` head after recording: `cca7f2b`.

## Branches (V, remote heads at the first checkpoint)

| Branch | Head | What |
|---|---|---|
| `staging/my-medieval-life` (= local `wip/b16-integration`, main worktree) | `49cd86c` | Build 16 released (`b3bbb1c`, tag `build-16`); WIKI-01 rule in CLAUDE.md; Expansion 18/19 register entries (PROS-01/18/19, Q18-*, X18-*, SJD-*, X19-*) |
| `wip/build17` (worktree `scratchpad/b17wt`) | `0a086af` | Build 17 integration: MIN-A..F, MIN-H, MIN-F2, CON-01, CON-02, crafts, DVW-A12, decay, terrain, OD-01 quest retirement, STONE-01, the first WIKI-B17 pass |
| `wip/b17-equip` | `89f30d3` | Worker L: MIN-EQUIP + MIN-COLLAPSE; committed and pushed by the lead before compaction; worker had not yet reported |
| `wip/b17-parity` (local `45554d8`) / `wip/b17-parity-snapshot` | `e28f621` | Worker N: MIN-D2, MIN-D3, MIN-SHOVEL, MIN-RIGHTS, MIN-SKILLCAP; the snapshot is the worker's uncommitted tree (40 files incl. 11 new), made without touching the worktree; the worker is still running |
| `wip/b17-stone` | `d28503c` | STONE-01: merged into wip/build17 |
| `wip/b17-wiki` | `0147066` | WIKI-B17 first pass: merged into wip/build17 |
| `wip/expansion18-preparation` | `8a54ec8` | Expansion 18, isolated; worker running (capability simulations, Q18-12/13, courier booths/popup); 2 uncommitted files in its worktree |
| `wip/expansion19-preparation` | `1b05da0` | Expansion 19, paused after rounds 1-4, awaiting owner questions |
| `wip/multiplayer` | `d18d7d1` | Never merged into staging without the owner's explicit approval |

## Active workers (agent ids for SendMessage)

| Worker | Id | Task | State |
|---|---|---|---|
| N (parity, shovels) | `a899252ff0eb35b0d` | MIN-D2, MIN-D3, MIN-SHOVEL, MIN-RIGHTS, MIN-SKILLCAP; wiki page `wiki_excavation.gd` | Running; told to merge `0a086af` before its final tests |
| L (equipment, collapse) | `a7109d77c0920b842` | MIN-EQUIP, MIN-COLLAPSE (binary survive/die; no health system), `wiki_mine_equipment.gd`, collapse outcome on `sys:mine_stability` | Running (W: committed 89f30d3); told to merge `0a086af` |
| Expansion 18 | `a5803847a53d8a4ff` | PROS-18: capability simulations (baseline/conservative/moderate/aggressive), Q18-12/13 smoke tests, courier booths and contract popup (X18-Q12-BOOTH, X18-Q12-POST) | Running; no completion report yet |
| STONE-01 (M), wiki (O) | done | | Merged |

Do not restart or duplicate these; wait for each notification, then integrate (merge into b17wt, `--import`, the worker's suites + `wiki_test`, INT entries, register, decisions, `tests.yml` for new suites, push).

## CI and test evidence (V)

- Tests run 39678592892 on `0a086af` (wip/build17, the STONE-01 + wiki merge): **success** (completed 21:39 UTC).
- Tests 39663123990 on `19efeb3`: success. Tests 39656594571 on `9f229f7`: success.
- Determinism gate re-baselined after MIN-F/MIN-H at `3be45b5` (seed 1 d10 alive 102 coins 4580, d30 102/4897; seed 2 d10 109/4431, d30 114/4907); MIN-F2 left it identical. STONE-01 changes it (W: seed 1 d30 109 alive, 4918 coins, 0 leaks) → **re-baseline once after the parity and equipment merges**, not before.
- On `0a086af` the lead ran: `wiki_test` all passed, `stone_test` 45 checks 0 failures; check_interactions 199/0, check_requirements 0 problems, check_materials 0 broken (21 open threshold findings, reported not failing), check_resources 0, check_assets 0.
- W (worker M on its merge): quarry, openpit, crafts, farm_plots, housing, business, contracts, services, parity, conservation, world, start, play, run_tests (3544) all pass.
- Build 16 save loads in Build 17 (`docs/build17/SAVE_MIGRATION.md`).
- FARM-08 long run 39618523947 (long-sims group): partial results read (yield 2.0: cattle died out on seeds 2 and 3; 1.5 fine); remaining variants pending; no recommendation until the cattle decline is explained. Switches `shared_manor_farming`, `seasonal_village_farming`, `shared_wheat_yield` stay 0.

## Owner decisions this session (all recorded; do not reopen)

Directives saved in `docs/directives/` (2026-10-21): Build 17 combined integration direction (B17-DIR), parallel prospective
development 18/19 (PROS-01), Q18-9/Q18-10, Expansion 18 master directive, capability simulations, courier booths and the
courier contract interface, CON-01 final decisions and service contracts (Q-C1..Q-C9, CON-02), Expansion 19 SJD
decisions, MIN-F-Q1..Q5 (`build17_minf_q1_q5_decisions`), OD-01, REC-013, quarry stone vs blocks (STONE-01), the consolidated
14 decisions (MIN-D-Q2/Q3, MIN-E-Q1..Q5, MIN-C-Q2, CON02-S-1..S-6), MIN-F2-Q1/Q2 (MIN-EQUIP, MIN-COLLAPSE, HEALTH-01), and
the permanent wiki maintenance directive (WIKI-01 on staging, WIKI-B17 on wip/build17, section in CLAUDE.md on both).
Register checked at checkpoint: every one of these ids is present with the right status.

## Open owner questions (BLOCKED decisions; never answer for the owner)

STONE-Q (fittings/mending on blocks, dressing waste, mason trade; new), CON-08-Q (service signing threshold number),
Q18-11A/B, X19-* questions incl. the timing question, placement of MAINT-01, LOG-01, JOB-02 and HEALTH-01.

## Build 17 remaining, in order

1. Integrate Worker N, then Worker L when they report (watch `wiki.gd` provider list and JOB_TEXT conflicts).
2. Small items: JOB-01 focused test (no priority, no double booking), LOG-01 narrow-change evaluation, B7-006 axe affordability.
3. WIKI-B17 gaps: capability levels cap at 2 (no excavator job; with MIN-SKILLCAP), collapse outcome on `sys:mine_stability`
   (Worker L), code names on non-mining node pages, prospector JOB_TEXT with no Population job, stale owner questions in
   `docs/build17/MIN_F_UNDERGROUND.md` section 4.
4. Re-baseline the determinism gate once; MIN-G long multi-seed runs on GitHub (after FARM-08 frees the `long-sims` group);
   final CI; visual review; release documentation gate (WIKI-01); Build 17 readiness report.
5. **No distributable without the owner's explicit approval** (B17-DIR). Report readiness and wait.

## Boundaries

Expansion 18/19 code stays on its branches until its reconciliation gate (18 after Build 17 is complete, 19 after Build
18); never merge Build 17 or each other into them. Pushes only to staging and `wip/*`. Private `XDG_DATA_HOME` per
Godot process. Commit trailers per the session reminder.
