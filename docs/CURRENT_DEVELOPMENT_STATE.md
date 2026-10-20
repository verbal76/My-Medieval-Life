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
| Active build | **Build 15**, simulation stabilization (ROAD-01). **BLOCKED** on owner decision OD-16 (house completion on seed 1); all other Build 15 work continues |
| Directive in force | OVN-01, `docs/directives/2026-10-20_master_overnight_development_directive.md` (autonomous engineering; Builds 15 → 16 → 17 → 18 strictly in order), with `docs/directives/2026-10-20_compaction_readiness.md` |
| Last released build | **Build 14**, a private draft from `7dbae4f` (`docs/release/BUILD_14_PACKET.md`) |
| Release authorization | OVN-01 section 9 and REL-15-18: Builds 15 to 18 may be released as **private drafts**, in order, each only when every condition of OVN-01 section 4 holds (REL-14-16 before it). No placeholder builds. Public visibility needs new owner approval. |

Old agent worktrees (`.claude/worktrees/*`, branches `pl-*`, `b8-*` and others) hold work that has been merged. They are history. Only `wip/multiplayer` is live.

## In progress (ACTIVE DEVELOPMENT)

The validator checks that every ACTIVE DEVELOPMENT id is named here. Updated 2026-10-20 about 08:00 UTC.

- **EQ-07 / HOUSE-07 (Build 15's blocker):**
  - Done: population (101 alive at day 365, seed 1) and wildlife (every species alive at day 365) are fixed.
  - Done: the housing routes of the owner's directive (HOUSE-04: family help, builders' own timber, tools kept from the caravan).
  - Open: houses. Seed 2 finishes 3 sites in 200 days; seed 1 none, because the village's trade economy stops around day 120-140. The diagnosis is in `docs/release/LONG_RUN_SIMULATION.md`, "Why seed 1 builds no house". Waits on **OD-16**.
- **EQ-16** (Build 16 objective, world equilibrium) and **DVW-A3** (money supply measurements): they share the 365-day runs. OD-16 is their first question.
- **OVN-01:** the overnight directive in force. **ROAD-01:** the roadmap.
- **REL-14-16:** superseded in practice by REL-15-18 for Builds 15-18. Build 14 is done.
- **PERF-01:** the runtime answer. PERF-02..05 are complete (the simulation is about twice as fast, and every change passes the gate). PERF-06 (checkpoint and resume) is evaluation only, done in `docs/release/SIMULATION_PERFORMANCE.md` section 4.
- **MP-01:** multiplayer on `wip/multiplayer` only. Nothing to do without the owner.

Closed tonight (2026-10-20), with evidence in the register:
- EQ-17 and EQ-10, both verified by 365-day Actions runs;
- FR-07 (CI run 39368652711);
- DVW-A4, FR-06, PERF-02..05;
- B7-008 verified, with its buyer half waiting on OD-15.

Implemented and tested, waiting on a device or a long run: DVW-A2, DVW-A6, FR-04 (a controller), HOUSE-04 (OD-16).

## Last test results (2026-10-20 about 07:50 UTC, staging `d4e2dc4` and later)

- **Godot suites:** all 23 in `.github/workflows/tests.yml` pass locally (`conservation_test.gd` and `housing_test.gd` included, the latter with 95 checks).
- **Python:** `python3 -m unittest discover -s tests` OK. `tools/check_requirements.py` and `tools/check_interactions.py`: 0 problems.
- **CI:** green on 0ee0218, e0c6ca7 and 2ef31bd (runs 39368652711, 39370974090, 39372860024). It runs again on each push; check the latest run for the head commit.
- **Determinism gate** (`python3 tools/sim_gate.py`): PASS against `docs/release/sim_baseline.json` at `59057ac`.
- **Year-long runs** (GitHub Actions, the record is `docs/release/LONG_RUN_SIMULATION.md`):
  - run 39368663150 on `0ee0218`: both seeds, 0 script errors, ledger balanced; seed 1 builds no house;
  - run 39385942656 on `59057ac` (the housing corrections): **in progress** at 08:00 UTC, see below.
- **Known failures:** none in the tests. The open behaviour defect is EQ-07's seed 1 housing (OD-16).

## Known defects (open)

- **EQ-07, seed 1 builds no house:** the trade economy stops around day 120-140. The smith runs out of coins and can no longer buy imported iron, so no axes are made, woodcutters fall from 6 to 1, and there is no timber. About 45 % of coins sit with bandits or as loot nobody picks up. Waits on OD-16.
- **Hunters' income:** most meat finds no buyer (seed 1: 3,957 made in a year, about 600 sold), and hunters miss most meals for lack of money. Build 16 equilibrium (EQ-01); part of OD-16's question.
- **Firewood:** households went without firewood on about 63 % of nights in the 0ee0218 run. Same cause.
- **EQ-09, stone (Build 16):** deposits run out; caravan stone (B7-007) supplies it. Seed 1 ran out of stone for sale by day 195 in the 200-day trace.
- **WR-02, grazers (Build 16):** grazers starve together.

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

Updated 2026-10-20 about 07:40 UTC under the overnight directive (OVN-01): Builds 15 to 18 in order. The overnight report for the owner is `docs/release/OVERNIGHT_REPORT_2026-10-20.md`.

1. **EQ-07, the Build 15 blocker:** housing corrections are in (`59057ac`):
   - family help;
   - builders' own timber (saw, fell, buy an axe);
   - the caravan leaving tools the village needs.

   Seed 2 finishes 3 sites in 200 days. Seed 1 finishes none, because the village's trade economy stops around
   day 120-140 (`docs/release/LONG_RUN_SIMULATION.md`, "Why seed 1 builds no house"). That needs **OD-16**
   (owner).
   - Actions run on `59057ac` (365 days, seeds 1 and 2) dispatched about 07:40 UTC: record it when it ends.
   - When OD-16 is answered, implement the answer and re-run 365 days on both seeds.
2. **PERF-04:** profile again after the two optimizations (`economy_sim.gd --profile`); take the next measured bottleneck through `tools/sim_gate.py`.
3. **The other Build 15 items** (ledger Roadmap):
   - FR-06 (wiki pages), FR-04 (pad shortcuts), B14-12 (sprite list), REC-003, REC-004 and REC-017;
   - HOUSE-10 waits on the owner's upper-floors choice.
4. **Build 15 release:** only when every condition of OVN-01 section 4 holds. Seed 1's housing (OD-16) is a non-deferrable core-construction item, so Build 15 is BLOCKED until it is answered and verified. Release as a private draft (REL-15-18) with a readiness packet.
5. **Then Build 16** (EQ-01..06, FAM-02..07, WR-02, EQ-09 and the rest), Build 17 and Build 18, in order.

Skipped (deferred) items: none. `docs/SKIPPED_ITEMS.md` is empty; nothing was deferred to advance a build.

Done on 2026-10-20 (overnight):
- EQ-17 fix and the script-error gate;
- EQ-10 fixes (verified by the 365-day Actions runs);
- FR-07, DVW-A2, DVW-A4, DVW-A6;
- B7-008 verified, with OD-15 raised;
- PERF-02, PERF-03, PERF-05, and two PERF-04 optimizations (the simulation is about twice as fast);
- HOUSE-04 housing routes, with OD-16 raised.

## Waiting on the owner

- **OD-14 (new):** no original house has room for living quarters on the current layout. Options: detached quarters nearby, a smaller added room, or no expansion.
- OD-11, OD-12 and OD-13 were answered by the owner on 2026-10-20 (`docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md`). Their implementation is open:
  - HOUSE-08 (bed sharing) and HOUSE-09 (quarters on original houses), Build 15;
  - FAM-03 and FAM-07 (orphans: the best-suited equal relative; the bandit-clan fallback, with interim handling until bandit factions, WDR-016-C, Build 20+), Build 16.
- **OD-16 (new, 2026-10-20, blocks Build 15):** the village's trade economy stops around day 120-140 on seed 1 (the smith out of coins, no iron, no axes, no timber), so no house is finished there. How should money flow back to the essential trades? Options and a recommendation are in the entry and in `docs/release/LONG_RUN_SIMULATION.md`.
- **OD-15 (new, 2026-10-20):** should the player's sales stop at a trader's 15-coin floor, as villagers' do? It came up while verifying B7-008; options and a recommendation are in the entry. B7-008 stays BLOCKED on it (its wildlife half is verified).
- **OD-01..09:** open owner decisions. Some are listed under the build whose design they decide, with the gate "owner decision first".
- **SJD-Q01..Q14:** the judgment system's 14 questions. They are items 25–38 under the heading "Owner decisions still open" (line 584 of `docs/directives/My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.txt`; the spec numbers two headings 19, and this is the second). The spec also names open points inside its sections, such as the rumour and credibility questions in its evidence section. Those belong to the same gates and are unanswered too. Never answer any of them on the owner's behalf.
- **GM-01, generational memory:** placed in Build 19 as the closest fit. The owner has not confirmed this (gate "fit to confirm"). **VP-01, village politics:** approved, but in none of the five builds (target `20+`, after Build 19's judgment).
- Entries with `target_build` `owner decision` or `owner action`, such as the permanent Android signing key, deferred by the owner.
- **Builds 17–19 (EXP-A, EXP-B, EXP-C):** approved objectives that have not been started. They need the owner's authorization to begin.

## Interrupted or fragile processes

- **Running now:** GitHub Actions run 39385942656 (`long-sims.yml`, 365 days, seeds 1 and 2, staging `59057ac`, started 07:21 UTC, about 40 minutes).
  - It runs on GitHub's runners, so a container restart cannot kill it. Each seed's job uploads `sim.json`, `sim.log` and `summary.json` as an artifact; the proxy blocks artifact downloads, so read the end of each job's log instead.
  - A self check-in is scheduled for 08:01 UTC to record it.
  - **If this file still says "in progress" and the run has finished:** record both seeds in `docs/release/LONG_RUN_SIMULATION.md` and the overnight report. Read script errors, LEAKS, alive, houses built and sites finished, woodcutters, unemployed and the fingerprint, then update EQ-07 and HOUSE-04. Do not dispatch it again.
- **Long runs belong on Actions** (INFRA-02): dispatch `long-sims.yml` with `ref=staging/my-medieval-life` and inputs seeds, days, every. Local runs die with the container.
- **Local scratch output** in `out/` (git-ignored) is not a record: only the written reports are.
- **Never restart a run because context was compacted:** check Actions (or `ps -eo pid,args | grep godot` locally) first.

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
