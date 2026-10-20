# Current development state

This is the session handoff (owner directive 2026-10-20, register MEM-01). Read it after `docs/PROJECT_MEMORY.md` at the start of every session, and update it before a session ends, before a context handoff and before a build. It records where the work stands. It does not copy the register: every id below is an entry in `docs/requirements/requirements.json`, and the register is authoritative where they differ. `tools/check_requirements.py` fails if an entry in ACTIVE DEVELOPMENT is not named here, or if a path named here does not exist.

**Updated:** 2026-10-20.

## Where the work is

| | |
|---|---|
| Repository | `verbal76/My-Medieval-Life` |
| Development branch | `staging/my-medieval-life` (push here; standing authorization) |
| Last verified remote commit before this file | `a203c0b` (Reconcile every open item against the owner's five-build roadmap). The commit that adds this file is the next one; check `git log origin/staging/my-medieval-life -1`. |
| `main` | Changes only when the owner merges. |
| Multiplayer | `wip/multiplayer` (MP-01), isolated. It must not be merged into staging without the owner's explicit approval. |
| Active build | **Build 15**, simulation stabilization (ROAD-01) |
| Last released build | **Build 14**, a private draft from `7dbae4f` (`docs/release/BUILD_14_PACKET.md`) |
| Release authorization | REL-14-16: Builds 15 and 16 may be released as **private drafts** when the eight conditions hold. No placeholder builds. Public visibility needs new owner approval. |

Old agent worktrees (`.claude/worktrees/*`, branches `pl-*`, `b8-*` and others) hold work that has been merged. They are history. Only `wip/multiplayer` is live.

## In progress (ACTIVE DEVELOPMENT)

- **EQ-07:** correct the 365-day failures under EQ-16. The Build 15 runs below are the evidence.
  - Done so far:
    - the housing deadlock: households split only when they had more members than beds;
    - births without a free bed (EQ-08);
    - founding couples;
    - start cost (`found_start_share`);
    - wildlife refuges (WR-01);
    - courtship pacing (CRT-01..12).
  - Still open:
    - few new houses get built (see the known defects);
    - unemployment climbs after day 40.
- **EQ-16:** world equilibrium, the Build 16 objective. It closes on the multi-seed 100- and 365-day acceptance runs (EQ-06).
- **DVW-A3:** re-measure money supply over 100 and 365 days on 2–3 seeds with no player. It shares the EQ runs.
- **MEM-01:** this project memory: `docs/PROJECT_MEMORY.md`, this file, the session-start procedure in `CLAUDE.md`, the validator checks and the fresh-session recovery test.
- **REL-14-16:** release Builds 15 and 16 as private drafts when the conditions hold. Build 14 is done.
- **ROAD-01:** the owner's five-build roadmap. Every open item carries a `target_build` (the ledger's Roadmap section).
- **MP-01:** multiplayer on `wip/multiplayer` only, isolated. Nothing is to be done on it without the owner.

## Last test results

**Suites.** These were all passing at `a203c0b`:
- Python: `python3 -m unittest discover -s tests`;
- the Godot suites in `.github/workflows/tests.yml`, among them `relations_test.gd`, `save_transfer_test.gd`, `refuge_test.gd`, `aging_test.gd` and `start_test.gd`.

**Long runs.** These use `game/tests/economy_sim.gd`; results go in `docs/release/LONG_RUN_SIMULATION.md`. The "fix9" set is the current code with the caravan at 30 coins a day:

| Run | Result |
|---|---|
| 100 days, seed 1 | **Finished.** 118 alive (start 100), no starvation, 16 other deaths. Wildlife 81 (54 at the start). Currency leak 0, item leaks 0. Iron, coal, copper and gold gone by day 20; stone 56 of 240 left. 12 courtships. 1 house built. 16 unemployed. |
| 100 days, seed 2; 365 days, seeds 1 and 2 | Running, outside the repository (`out/eq/`). At day 80: 128 alive, no starvation, leak 0. |

**Limits of these results:**
- The runs have no player.
- They run headless on a cloud container, not a phone.
- The scratch outputs in `out/` are not committed. Only the written report in `docs/release/LONG_RUN_SIMULATION.md` is the record.

## Known defects (open)

- **EQ-09, stone (Build 16; may depend on MIN-B):** stone runs out by about day 60–100 with no lasting source. Iron, coal, copper and gold run out by day 10–20.
- **EQ-10, ledger residuals:** the economy simulation shows axe and hammer ledger residuals of 1–3 from day 12.
- **WR-02, grazers:** grazers starve together.
- **Housing growth (EQ-07):** the 100-day seed 1 run ends with 5 crowded households and 2 couples needing a home, none of which can afford one. Only 1 house was built.
- **B14R-12, long-run regression:** partly addressed. Wildlife no longer collapses at 100 days; it is still to be confirmed at 365.

## Done but not verified on a device

The device queue is entries with status AUTOMATED TESTS PASSED — PLAYTEST REQUIRED (the ledger lists them). Among them:
- SAVE-00..09: export and import a save on an Android phone, through the system picker (SAVE-05);
- CRT-01..12: courtship and friendship;
- WR-01: the refuges;
- CQ-01, B13-12, B13-13, B14-01, B14-06 and B14-13;
- B7-001, B7-005 and B7-010..013;
- B8-018, PL1-03, PL1-05 and Q-04.

None of these can be closed until a real device check is recorded.

## Next approved tasks, in order

1. **MEM-01:** finish. Run the fresh-session recovery test and fix the gaps it finds.
2. **When the fix9 runs end:** record the Build 15 results in `docs/release/LONG_RUN_SIMULATION.md` and update EQ-06, EQ-07, B14R-12, DVW-A3 and CARAVAN-TMP. If a run was killed by a container restart, restart it (below).
3. **EQ-07, housing growth:** find why crowded households cannot afford a home. Then re-run.
4. **EQ-10:** fix the axe and hammer ledger residuals.
5. **WR-02:** grazers starving together.
6. **EQ-09, stone:** measure and bring the options to the owner before any change. The options are caravan stone as a stand-in, or MIN-B earlier (`docs/EXPANSION_ROADMAP.md`).
7. **The other Build 15 items:** from the ledger's Roadmap section. Examples: DVW-A2 (rotated save backups), DVW-A4 (faucet and drain ledger), FR-07 (short simulations in CI), REC-017 (stale documents) and FR-06 (wiki pages).
8. **Build 15 release:** when REL-14-16's conditions hold, a private draft with a readiness packet like `docs/release/BUILD_14_READINESS.md`.

## Waiting on the owner

- **OD-01..09:** open owner decisions.
- **SJD-Q01..Q14:** the judgment system's 14 questions. Never answer them on the owner's behalf.
- Entries with `target_build` `owner decision` or `owner action`, such as the permanent Android signing key, deferred by the owner.
- **Builds 17–19 (EXP-A, EXP-B, EXP-C):** approved objectives that have not been started. They need the owner's authorization to begin.

## Fragile processes

- **Long simulations die on a container restart.** Check with:
  `ps -eo pid,args | awk '$2=="/opt/godot/godot"'`
  Restart a run with:
  `cd game && nohup /opt/godot/godot --headless --script res://tests/economy_sim.gd -- --days N --seed S --every 10 --out ../out/eq/NAME.json > ../out/eq/NAME.log 2>&1 &`
  100 days take about 30–40 minutes; 365 days take about 2–3 hours.
- **Never kill with `pkill -f` and a pattern that appears in your own command.** It kills the shell. Match on the process arguments with `awk` as above.
- **After adding a GDScript `class_name`,** run `godot --headless --path game --import` before the tests.
- **The off-machine backup** (CLAUDE.md section 5) is occasional. GitHub staging is the day-to-day record, so push completed work.
