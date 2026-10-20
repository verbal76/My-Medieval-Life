# Current development state

This is the session handoff (owner directive 2026-10-20, register MEM-01). Read it after `docs/PROJECT_MEMORY.md` at the start of every session, and update it before a session ends, before a context handoff and before a build. It records where the work stands. It does not copy the register: every id below is an entry in `docs/requirements/requirements.json`, and the register is authoritative where they differ. `tools/check_requirements.py` fails if an entry in ACTIVE DEVELOPMENT is not named here, or if a path named here does not exist.

**Updated:** 2026-10-20.

## Where the work is

| | |
|---|---|
| Repository | `verbal76/My-Medieval-Life` |
| Development branch | `staging/my-medieval-life` (push here; standing authorization) |
| Last verified remote commit | The head of `origin/staging/my-medieval-life` (`git log origin/staging/my-medieval-life -1`). This file was last brought up to date in the commit `git log -1 -- docs/CURRENT_DEVELOPMENT_STATE.md` shows; anything newer on staging is described in that commit's successors. |
| `main` | Changes only when the owner merges. |
| Multiplayer | `wip/multiplayer` (MP-01), isolated. It must not be merged into staging without the owner's explicit approval. |
| Active build | **Build 15**, simulation stabilization (ROAD-01) |
| Last released build | **Build 14**, a private draft from `7dbae4f` (`docs/release/BUILD_14_PACKET.md`) |
| Release authorization | REL-14-16: Builds 15 and 16 may be released as **private drafts** when the eight conditions hold. No placeholder builds. Public visibility needs new owner approval. |

Old agent worktrees (`.claude/worktrees/*`, branches `pl-*`, `b8-*` and others) hold work that has been merged. They are history. Only `wip/multiplayer` is live.

## In progress (ACTIVE DEVELOPMENT)

Seven entries, all named here (the validator checks). The ledger's count of six is of approved requirements only; ROAD-01 is an owner decision (kind `decision`, already answered by the owner) being carried out.

- **EQ-07:** correct the 365-day failures under EQ-16. The Build 15 runs below are the evidence.
  - Done so far:
    - the housing deadlock: households split only when they had more members than beds;
    - births without a free bed (EQ-08);
    - founding couples;
    - start cost (`found_start_share`);
    - wildlife refuges (WR-01);
    - courtship pacing (CRT-01..12).
    - 2026-10-20, under the owner's housing directive (`docs/directives/2026-10-20_housing_succession_adoption.md`): persistent housing goals, a responsible adult per household, saving, living quarters for crowded families, couples of either sex (HOUSE-01..06, FAM-01; investigation in `docs/release/LONG_RUN_SIMULATION.md`, "EQ-07 investigation").
  - Still open:
    - crowded families nobody can leave, in original houses (no parcel for quarters): owner decision OD-13;
    - the fix10 runs (corrected code) to read;
    - unemployment climbs after day 40.
- **HOUSE-07:** the EQ-07 investigation, tests (`game/tests/housing_test.gd`) and re-runs. Done: the trace, the root causes, the tests. Remaining: the fix10 100-day results.
- **EQ-16:** world equilibrium, the Build 16 objective. It closes on the multi-seed 100- and 365-day acceptance runs (EQ-06).
- **DVW-A3:** re-measure money supply over 100 and 365 days on 2–3 seeds with no player. It shares the EQ runs.
- **REL-14-16:** release Builds 15 and 16 as private drafts when the conditions hold. Build 14 is done.
- **ROAD-01:** the owner's five-build roadmap. Every open item carries a `target_build` (the ledger's Roadmap section).
- **MP-01:** multiplayer on `wip/multiplayer` only, isolated. Nothing is to be done on it without the owner.

Also: **MEM-01** and **MEM-02** (the two memory directives) are complete: see "Recovery test" below. Keep this file and the index current.

## Last test results

**Suites.** The Python suites and the register validator pass at every commit of 2026-10-20 (run before each push). CI (`.github/workflows/tests.yml`) runs the Godot suites on each staging push; earlier runs are cancelled when a newer push arrives, so check the latest run's result for the head commit. The Godot suites last passed locally at `a203c0b`; the game code has changed since (the EQ-07 housing work), and the full Godot list (22 suites, `housing_test.gd` included) passed locally on 2026-10-20 before the push that carries it:
- Python: `python3 -m unittest discover -s tests`;
- the Godot suites in `.github/workflows/tests.yml`, among them `relations_test.gd`, `save_transfer_test.gd`, `refuge_test.gd`, `aging_test.gd` and `start_test.gd`.

**Long runs.** These use `game/tests/economy_sim.gd`; results go in `docs/release/LONG_RUN_SIMULATION.md`. The "fix9" set is the current code with the caravan at 30 coins a day:

| Run | Result |
|---|---|
| 100 days, seed 1 | **Finished.** 118 alive (start 100), no starvation, 16 other deaths. Wildlife 81 (54 at the start). Currency leak 0, item leaks 0. Iron, coal, copper and gold gone by day 20; stone 56 of 240 left. 12 courtships. 1 house built. 16 unemployed. |
| 100 days, seed 2 | **Finished.** 133 alive, no starvation, wildlife 74, leak 0, but only 1 house built, although 3 crowded households could afford one. |
| 100 days, seeds 1 and 2, **fix10 (corrected housing code)** | Started 2026-10-20 about 01:20 UTC on that session's container (`out/eq/fix10_d100_s1`, `_s2`); expected by about 02:10 UTC. Same re-run rule as below. |
| 365 days, seeds 1 and 2 (fix9, old code) | **In progress** (interim figures recorded in `docs/release/LONG_RUN_SIMULATION.md`). Started 2026-10-20 at about 00:30 UTC in `/home/user/My-Medieval-Life/game` on that session's cloud container, writing to `out/eq/fix9_d365_s1` and `fix9_d365_s2` (not committed). Seed 1 at day 190: 125 alive, no starvation, 26 unemployed, **stone 0**, 7 house sites started and 1 finished. Seed 2 at day 160: 137 alive, stone 1, 8 sites started and 1 finished. Expected to end by about 03:30 UTC. **If a later session finds no day-365 result recorded and it is past that time, the run was lost: run it again** ("Interrupted or fragile processes", below). |

**Limits of these results:**
- The runs have no player.
- They run headless on a cloud container, not a phone.
- The scratch outputs in `out/` are not committed. Only the written report in `docs/release/LONG_RUN_SIMULATION.md` is the record.

## Known defects (open)

- **EQ-09, stone (Build 16):** the mine deposits run out by about day 160–190. The owner's rule of 2026-10-18 (B7-007) brings caravan stone once deposits are low, and it is implemented. The open question is whether that supply keeps pace, which the 365-day results answer. At day 100 the merchants held 80 stone, so stone was not what stalled housing. (OD-10, raised on a misreading of the deposit figure, is withdrawn.) Iron, coal, copper and gold run out by day 10–20.
- **EQ-10, ledger residuals:** the economy simulation shows axe and hammer ledger residuals of 1–3 from about day 120 in 365-day runs.
- **WR-02, grazers (Build 16):** grazers starve together.
- **Housing growth (EQ-07):** one house in 100 days in both seeds on the old code. Root causes are in `docs/release/LONG_RUN_SIMULATION.md` ("EQ-07 investigation"): crowded families nobody can leave (no parcel for quarters, OD-13); no goal or saving; same-sex couples excluded. Corrected except OD-13; the fix10 runs measure it. Unemployment climbs after day 40.
- **B14R-12, long-run regression:** partly addressed. Wildlife no longer collapses at 100 days; it is still to be confirmed at 365.

## Hardware checks still required (done, not verified on a device)

The device queue is entries with status AUTOMATED TESTS PASSED — PLAYTEST REQUIRED (the ledger lists them). Among them:
- SAVE-00 and SAVE-02..09 (SAVE-01 is complete): export and import a save on an Android phone, through the system picker (SAVE-05);
- CRT-01, CRT-02, CRT-04, CRT-05 and CRT-07..12 (CRT-03 and CRT-06 are not device items): courtship and friendship;
- WR-01: the refuges;
- CQ-01, B13-12, B13-13, B14-01, B14-06 and B14-13;
- B7-001, B7-005 and B7-010..013;
- B8-018, PL1-03, PL1-05 and Q-04.

The complete list is the ledger's "Real-device verification queue". None of these can be closed until a real device check is recorded.

**Who does them and when:** the owner (or a tester the owner names) does them on their own phone, controller and PC. This happens when a private build is installed, Build 15 next. The agent prepares the checklist in the build's packet and records the results the owner reports with `tools/requirements_update.py set ID --playtest-done "device, date"`. The umbrella entry B12A-10 is this owner action.

## Next approved tasks, in order

1. **When the 365-day fix9 runs end:** record the Build 15 results in `docs/release/LONG_RUN_SIMULATION.md` and update EQ-06, EQ-07, B14R-12, DVW-A3 and CARAVAN-TMP. If a run was killed by a container restart, restart it (below).
2. **EQ-07 / HOUSE-07:** read the fix10 100-day runs against fix9, record them labelled as corrected code; put OD-13 to the owner with the evidence.
3. **EQ-09:** from the 365-day results, check whether caravan stone keeps house sites supplied once the deposits are gone.
4. **EQ-10:** fix the axe and hammer ledger residuals.
5. **WR-02 (target Build 16, taken early because it bears on the 365-day runs):** grazers starving together.
6. **The other Build 15 items:** from the ledger's Roadmap section. Examples: DVW-A2 (rotated save backups), DVW-A4 (faucet and drain ledger), FR-07 (short simulations in CI), REC-017 (stale documents) and FR-06 (wiki pages).
7. **Build 15 release:** when REL-14-16's conditions hold, a private draft with a readiness packet like `docs/release/BUILD_14_READINESS.md`.

## Waiting on the owner

- **OD-13, crowded families (new, 2026-10-20):** should young children share beds, should the original village houses take living quarters, or both? It decides the largest remaining cause of EQ-07.
- **OD-11 and OD-12 (new, 2026-10-20, Build 16):** temporary care for an orphan no household can take, and choosing between equally close relatives (FAM-02..06, the family system, is planned for Build 16).
- **OD-01..09:** open owner decisions. Some are listed under the build whose design they decide, with the gate "owner decision first".
- **SJD-Q01..Q14:** the judgment system's 14 questions. They are items 25–38 under the heading "Owner decisions still open" (line 584 of `docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.txt`; the spec numbers two headings 19, and this is the second). The spec also names open points inside its sections, such as the rumour and credibility questions in its evidence section. Those belong to the same gates and are unanswered too. Never answer any of them on the owner's behalf.
- **GM-01, generational memory:** placed in Build 19 as the closest fit. The owner has not confirmed this (gate "fit to confirm"). **VP-01, village politics:** approved, but in none of the five builds (target `20+`, after Build 19's judgment).
- Entries with `target_build` `owner decision` or `owner action`, such as the permanent Android signing key, deferred by the owner.
- **Builds 17–19 (EXP-A, EXP-B, EXP-C):** approved objectives that have not been started. They need the owner's authorization to begin.

## Interrupted or fragile processes

- **Long simulations die on a container restart.** They run only on the machine that started them, and write to that checkout's `out/eq/`. A fresh clone or another machine has no `out/`, so a new session on another machine cannot see them. It treats every run with no result in `docs/release/LONG_RUN_SIMULATION.md` as not done, and runs it again.
  On the same machine, check with:
  `ps -eo pid,args | awk '$2=="/opt/godot/godot"'`
  Then check each process's working directory (`readlink /proc/PID/cwd`) and the last line of its `out/eq/NAME.log`.
  Restart a run with:
  `cd game && nohup /opt/godot/godot --headless --script res://tests/economy_sim.gd -- --days N --seed S --every 10 --out ../out/eq/NAME.json > ../out/eq/NAME.log 2>&1 &`
  100 days take about 30–40 minutes; 365 days take about 2–3 hours.
- **Never kill with `pkill -f` and a pattern that appears in your own command.** It kills the shell. Match on the process arguments with `awk` as above.
- **After adding a GDScript `class_name`,** run `godot --headless --path game --import` before the tests.
- **The off-machine backup** (CLAUDE.md section 5) is occasional. GitHub staging is the day-to-day record, so push completed work.

## Recovery test (MEM-01, 2026-10-20)

**How it was run:** an agent with no conversation context, working from a fresh clone of `staging/my-medieval-life` at `3814618`.

**Result:** it answered all seven questions of the directive from the committed files. It needed four core files (CLAUDE.md, this index, this file, the ledger) and about 13 files in all.

**Gaps it found, fixed in `c2ed962` and the commit after it (a re-check by the same agent confirmed them):**
- stale pointers to the old plan and queue (CLAUDE.md section 5, the ledger header, `docs/DEVELOPMENT_PLAN.md`);
- a device queue missing the status-only playtest items;
- the decision lists' counts;
- the expansion roadmap's superseded sequence;
- CLAUDE.md's platform line;
- the Build 15 run results kept only outside the repository;
- the SJD question mapping;
- GM-01 and VP-01 placement;
- REL-14-16's next action;
- REC-002's off-repository source.

Some register sources cite `docs/HANDOFF.md`, `docs/DEVELOPMENT_QUEUE.md` or `docs/DEVELOPMENT_PLAN.md`. Those are where the item was first recorded; the files are kept, marked historical, so the citations stay valid. Repeat this test after any large change to the memory files.

## Recovery tests (MEM-02, 2026-10-20: the owner's nine questions)

Each pass used a new agent with no conversation context, working only from a fresh clone of `staging/my-medieval-life`.

**Pass 1, at `d672353`:**
- All nine questions were answered.
- 17 gaps were found and fixed in `6a56b9e`. The main ones:
  - 365-day runs that a clone cannot see;
  - counts that disagreed between files;
  - stale pointers in CLAUDE.md;
  - sources that live only in chat.

**Pass 2, at `6a56b9e`:**
- All nine questions were answered.
- Verdict: "a new agent could resume the project correctly from these files alone, with the caveats".
- Two gaps were blocking, and the commit after `6a56b9e` fixed both:
  - stone was not registered as an owner decision; it is now OD-10, and EQ-09 is BLOCKED on it;
  - the unfinished 365-day runs had no rule for a later session; they now have an expected end time and a re-run rule.
- Minor gaps fixed at the same time: stale stone figures, SET-E's placement, whether SET-A needs authorization, PR #1's final state, numbering and counts.

**Re-check of pass 2, at `9a01e88`:**
- Both blocking gaps were confirmed fixed.
- The remaining minor wording (the titles and next actions of EQ-07, EQ-09 and EQ-10, and this section) was fixed in the commit after `9a01e88`.
- EQ-07's title is kept on purpose: it names the Build 14 failures the entry was opened for.

**Known limits that remain:**
- `wip/multiplayer` is not in a staging clone.
- A few early sources exist only in chat; their wording is copied into the register.
- The spec's inline open points beyond SJD-Q01..Q14 are noted here but have no entries of their own.
