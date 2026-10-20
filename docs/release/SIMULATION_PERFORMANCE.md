# Simulation performance (PERF-01..06)

**Owner directives, 2026-10-20:**
- `docs/directives/2026-10-20_simulation_performance_audit.md`: the audit and the optimization rules;
- `docs/directives/2026-10-20_build15_followup_performance_clarification.md`: the runtime questions.

**Priority:** this work comes after Build 15 stabilization and the EQ-07 housing work. It must never interrupt a running simulation.

**Labels:** every figure here is one of three kinds:
- **Measured:** from a timestamp, a file time or a process table.
- **Estimated:** worked out from measured figures.
- **Hypothesis:** not measured.

## 1. The runtime question (2026-10-20)

### The historical benchmark

`docs/release/LONG_RUN_SIMULATION.md`, at staging `79ffeb7`, gives **measured** 365-day runtimes of 689 s (seed 1, 1.9 s/day) and 530 s (seed 2, 1.5 s/day). The runs went one after another on a 4-core container. That was the Build 7 village: about 100 people, and none of the later systems (relations, refuges, carts, housing goals).

### Today's runs, measured

The times below come from process start times (`ps`), the end-of-run JSON file times, and a log timestamper started at 02:39 UTC (`out/eq/timing_fix12.txt`).

| Run | Code | Start (UTC) | End (UTC) | Wall clock | s/day | Other Godot processes at the time |
|---|---|---|---|---|---|---|
| fix9 365 days, seed 1 | old housing code | 00:30:47 (ps) | 01:17:58 (JSON) | 2831 s | 7.8 | 3–5: the 100-day runs, traces, test suites |
| fix9 365 days, seed 2 | old housing code | 00:30:47 (ps) | 01:21:58 (JSON) | 3071 s | 8.4 | same |
| fix12 365 days, seeds 1 and 2, first start | three corrections | 01:31 | killed by the container restart (see 3) | not known | not known | the full test list (01:31–01:39), then none |
| fix12 365 days, seeds 1 and 2, restart | same | 02:19:31 (ps) | running | at 02:39:08: 1176 s for day 130 (seed 1) and day 170 (seed 2) | 9.0 and 6.9 average | the full test list from about 02:27 |

### The owner's ten questions

1. **How the 04:30 estimate was made.** It was not measured. Earlier the same night I had written "365 days take about 2–3 hours" into the handoff file, from memory of runs going slowly under heavy contention. I added that to the 01:31 start. No timing was taken. **The estimate was wrong.** The fix9 365-day runs on the same machine had just finished in 47 and 51 minutes, and I did not use those times.
2. **Start times of the interrupted runs.** 01:31 UTC, both seeds (stated when they were launched; the logs that would show it were overwritten).
3. **Elapsed time when the container restarted.** **Cannot be determined.** The restarted runs wrote to the same log files, so the old file times are gone. The machine booted at 02:19:03 (measured: `/proc/uptime` was 1205.9 s at 02:39:08). The old runs stopped some time between their last log line and 02:19. At the measured rate of the restarted runs, days 120 and 160 would have been reached around 01:50–01:55. That is an estimate, and it suggests the processes died then, not at 02:19.
4. **Final progress.** Seed 1: the last line was day 120. Seed 2: day 160 (read live at 02:19; my later summary showed day 150 because it sampled every third line).
5. **Seconds per day.** Measured averages: fix9 7.8 and 8.4 s/day over 365 days; the restarted fix12 runs 9.0 and 6.9 s/day over their first 130–170 days. Per-interval rates are in the timing file (section 2).
6. **Progressive slowdown.** **Not yet determined.** Old logs carry no timestamps. The new timing file records the time of every 10-day line from 02:39 onward. Its first intervals (2.5–4 s/day) are faster than the earlier average, which points to contention earlier in the run rather than to slowing with population. To be confirmed when the runs end.
7. **Contention.** The machine has 4 cores and 16 GB. Each simulation uses about 190 MB and one core (measured: about 99 % CPU each). Memory is not a constraint. Contention happens when more than 4 Godot processes run at once, as during the fix9 runs (two 365-day runs, two 100-day runs, traces and test suites at times). Exactly how much is a hypothesis until PERF-05 measures parallel against sequential.
8. **Is the current code slower than the benchmark's?** **Likely, not yet measured cleanly.** About 7–9 s/day now against 1.5–1.9 s/day then is 4–5 times slower. But today's runs shared the machine, carry 20–35 % more people (115–138 against about 100), and the code now has relations, refuges, carts and housing goals. A clean single-process 10-day profile on an idle machine (PERF-02) will separate code cost from contention. It will run when the 365-day runs finish, so as not to disturb them.
9. **How the 05:20 estimate was made.** By adding the same unmeasured "about 3 hours" to the 02:20 restart. **Also wrong.**
10. **Will the current runs meet it?** Yes, by a wide margin. At the measured rate they finish around 03:00–03:15 UTC, roughly two hours early.

**Answer in short:** the hours-long expectation came from **inaccurate completion estimates**, not measurements. The real runs take about 45–55 minutes for 365 days on a shared machine. Against the 9–12-minute historical benchmark there is also a **real slowdown, of about 4–5 times per day, still to be split** between contention, a larger population and new systems. That split is PERF-02's first job.

## 2. Timing of the fix12 simulations (measured, 02:39–03:03 UTC)

The UTC time of each 10-day log line, with the number of Godot processes running at the time (`out/eq/timing_fix12.txt`), in seconds per game day:

| Days | Seed 1 | Seed 2 |
|---|---|---|
| 140–200 | 9.5, 8.0, 7.6, 8.0, 7.5, 7.0 | (from day 180) 7.5, 7.0 |
| 200–250 | 7.1, 6.5, 6.5, 6.5, 6.5 | 6.5, 6.1, 6.5, 6.5, 7.5 |
| 250–310 | 6.6, 7.0, 8.5, 8.1, 9.0, 9.0 | 7.6, 8.0, 8.5, 9.5, 9.6, 9.5 |
| 310–350 | (killed at day 320) | 9.5, 9.1, 8.5, 9.5 |

The first interval of each seed (2.5 and 4.6 s/day) started partway through, so it does not count.

**Findings (measured):**
- **One process to a core:** with 2 or 3 Godot processes on 4 cores, each simulation ran at **6.1–9.6 s per game day**. No core was shared, so contention does not explain the gap.
- **Gradual slowdown:** seed 2 went from about 6.1 to about 9.5 s/day between day 210 and day 350, as its population grew to about 145. Seed 1 rose from 6.5 to 9.0 over days 210–310.
- **Comparison with the benchmark:** **4 to 5 times slower** per game day than the 1.5–1.9 s/day benchmark, on an uncontended core. **This is a real slowdown in the current code,** not contention or the environment, and not just inaccurate estimates. How much comes from the larger population and how much from the newer systems is what PERF-02's profile will show.

**Answers this updates in section 1:** question 6 (progressive slowdown: yes, gradual, rising with population), question 7 (contention: not the cause at 2–3 processes on 4 cores), question 8 (the code is substantially slower: yes, measured).

## 3. The container restart

**Known (measured):**
- The machine booted at 02:19:03 UTC (`/proc/uptime`), as a fresh kernel (`dmesg` begins with the boot).
- Files on disk survived, but every process died, both simulations included.
- Memory is 16 GB with 1 GB in use now. The cgroup shows no CPU or memory limit files, and nothing in this boot's log records memory pressure. The previous boot's log is not available.

**Timeline:**
- My last action before the restart: the commit at 01:34:48 and the staging push just after it.
- The session then sat idle, waiting on the runs.
- At 02:19:03, the moment the session was woken by an incoming message, a new machine had booted.

**Most likely cause (inference, not proven):** session lifecycle. This environment reclaims a cloud container after a period of inactivity and starts a fresh one when the session is next used. That fits an idle gap after about 01:35, processes dying around 01:50–01:55 (the estimate in 1, item 3), and a fresh boot exactly when the session woke. Resource exhaustion is unlikely: each simulation uses about 190 MB of 16 GB. It cannot be ruled out, because the previous boot's log is gone.

**A second restart, 03:03:26 UTC (measured):** the machine booted again (`/proc/uptime` 49 s at 03:04:15). Both fix12 runs died at day 320 (seed 1) and day 350 (seed 2), 15 and 45 game days from the end. The session had been idle since about 03:02, waiting for the owner's answer to a question. Both restarts came while the session sat waiting, which supports the session-lifecycle explanation.

**Practical consequence:** a long run must not depend on the session staying active. It survives only while the session is busy, or if it can be resumed. See section 4.

## 4. Checkpoint and resume (PERF-06): evaluation only, nothing implemented

The owner asked that nothing be built until this has been weighed.

**What exists:** `World.to_dict()` / `load_dict()` save and load the whole world: people, households, buildings, the economy, fauna, relations and so on. `save_transfer_test.gd` shows a save loads and saves again identically.

**What a resumed run would also need to match an unbroken one exactly:**
- **The random number generator's state (measured in code).** It is **not** saved. Loading reseeds the generator from the seed plus the clock (`world.gd:2586`, `rng.seed = seed + int(d.minutes)`). A resumed run would therefore draw a different random stream from an unbroken one at once: the rest of the run would differ. Exact resumption needs the generator's state saved and restored.
- **Transient state that is not saved,** for example `NPCBrain.earned_at_dawn` and `laboured_today`, and in-progress plans and their timers.
- **The harness's own accumulators.** `economy_sim.gd` keeps flow ledgers, death logs, event counters and the start snapshot outside the world.

**Risk:** a resume that misses any of this would give a run that differs from an unbroken one without telling anyone, which breaks the determinism rule (CLAUDE.md section 6).

**Proposed design (for the owner):**
- A harness-level checkpoint: the world's save plus the harness's state plus the RNG state, written every N days.
- A resume flag.
- **A gate before it is ever used for results:** a 30-day run, and the same run broken at day 15 and resumed, must give identical fingerprints, ledgers and samples.
- If any transient state cannot be captured, checkpoints are kept for crash recovery only, and their results are labelled "resumed".

**Cheaper alternative, available now:** keep the session busy while runs go (do not leave it idle), and since a 365-day run takes under an hour, simply re-run a lost one.

## 5. Next measurements (PERF-02..05), after the Build 15 runs end

1. A 10-day run, one process, idle machine, seeds 1 and 2: wall clock, CPU, population and animals, and a time breakdown by subsystem, using a profiling harness that only adds timers and leaves the world untouched.
2. Baseline fingerprints at 10 and 30 days (PERF-03).
3. Parallel against sequential for two seeds, each in its own save, temp and output paths (PERF-05).
4. Only then, optimizations, one at a time, each through the determinism gate.

## 5a. Profile by subsystem (PERF-02, measured 2026-10-20)

**How:**
- `economy_sim.gd --profile` turns on timers in `World.update` (villagers, wildlife, carts, player, the hourly and
  daily work), in `VillageMap.find_path` and in the harness's own sampling. They only add timers: the 10-day
  seed-1 fingerprint with profiling on is `eeabb2a8ce8d6ed8e9691867869bc6ee`, the same as without.
- One process on an idle container, seed 1, staging after `e0c6ca7`.
- A temporary, uncommitted breakdown inside `NPCBrain.decide` and `_plan_job` gave the finer rows marked *.

**10 days, seed 1:** 44.0 s (4.40 s a game day); 103 villagers and 82 animals alive at the end.

| Subsystem | Time | Share | Calls | Each |
|---|---|---|---|---|
| Villagers, all | 34.6 s | 78.5 % | 14,400 steps | 2.4 ms |
| of which `decide` (choosing what to do next) | 24.3 s | 55.1 % | 56,094 | 433 us |
| * of which `_plan_job` | 20.3 s | 44.4 % | 41,013 | 494 us |
| * of which miners (`_miner`) | 10.2 s | 22.8 % | 13,104 | 780 us |
| * of which labourers (`_miner`) | 4.0 s | 9.0 % | 9,000 | 447 us |
| * of which woodcutters | 3.3 s | 7.4 % | 8,707 | 381 us |
| of which running plans and walking | 5.2 s | 11.9 % | 1.57 million | 3 us |
| Wildlife (`fauna.update`) | 7.3 s | 16.6 % | 14,400 steps | 508 us |
| Hourly and daily world work | 1.0 s | 2.3 % | 241 hours | 4.1 ms |
| Player | 0.9 s | 2.0 % | | |
| Path searches (A*, inside villagers) | 0.5 s | 1.2 % | 18,784 | 28 us |
| Harness sampling | 0.0 s | 0.1 % | | |

**60 days, seed 1:** 281.1 s (4.68 s a day; 120 villagers, 75 animals). The shares are the same: villagers 75 %,
`decide` 52 %, wildlife 20 %. Fingerprint `26dc442828d79f9aa50dfc3c25e4516b`.

**Ranked bottlenecks:**
1. **Villagers' decisions, above all the miners', labourers' and woodcutters' trade choice** (about 40 % of
   the run). `_miner` asks `_buyer_for` up to 15 times per decision. Each call rescans the whole population
   for each outlet role (`_with_buy_role`: every villager's `buy_role`), so a decision costs several
   thousand villager checks.
2. **Wildlife** (17–20 %), 0.5–0.6 ms per step for about 80 animals.
3. Everything else is under 3 % each. Path searching is 1 %, so pathfinding is not the problem.

**Not yet explained:** these runs measure 4.4–4.7 s a day, while the year-long runs logged 6–10 s a day later in
the year. The 365-day profiles on Actions will show whether a cost grows with time (population, households,
built sites).

## 5b. Determinism gate, optimizations and parallel seeds (PERF-03..05, 2026-10-20)

**The gate (PERF-03):** `python3 tools/sim_gate.py` runs seeds 1 and 2 for 30 days, each in its own process with
its own Godot user data, temp directory and output. It compares days 10 and 30 with
`docs/release/sim_baseline.json` (from `efe7ca7`): fingerprint (every villager's position, coins, hunger, job and
goods; every animal; the RNG state; deposits; pantries), villagers alive, households, currency, treasury, the item
ledger table, deposits and animals. `--write` records a new baseline, only when gameplay is meant to change.

| Seed | Day 10 fingerprint | Day 30 fingerprint | Alive at 30 | Currency at 30 |
|---|---|---|---|---|
| 1 | `eeabb2a8ce8d6ed8e9691867869bc6ee` | `90a6967fc06e4d19b137298722bb66aa` | 106 | 4,919 |
| 2 | `bf1218e07854eec59d7f01910f2d1041` | `ffe3508e40304a79ffb2df491777006e` | 119 | 4,918 |

**Parallel seeds (PERF-05):**

| Mode | Seed 1 | Seed 2 | Wall-clock |
|---|---|---|---|
| Side by side | 127.1 s | 142.3 s | 142.3 s |
| One after the other | 122.2 s | 140.5 s | 262.7 s |

Each seed costs the same either way (two real cores), so running seeds side by side nearly halves the wall-clock.
The outcomes are identical: the sequential run passes the gate against the parallel baseline. No paths are shared.

**Optimizations (PERF-04), each through the gate:**

| Change | 10 days, seed 1 | 30 days, seeds 1 / 2 | Gate |
|---|---|---|---|
| Before | 44.0 s | 127 s / 142 s | baseline |
| Trading roles kept between buyer searches (`NPCBrain._with_buy_role`, rebuilt when a job, workplace, life, villager or stall changes) | 28.4 s | 84 s / 90 s | PASS |
| Wildlife: cell membership through a set (`Fauna.in_area`); prey scan cheapest test first | 25.5 s | 68 s / 73 s | PASS |

A decision went from 433 us to 152 us, and wildlife from 7.3 s to 3.9 s per 10 days. Nothing changed in the
rules, the step size or the systems that run.

## 6. Long-run reliability (INFRA-01, owner 2026-10-20)

**The problem (measured):** two container restarts on 2026-10-20, both while the session sat idle waiting for an answer, killed the long runs. A long run on the session's own container survives only while the session stays active.

**Options:**

| Option | Results identical to an unbroken run? | Effort | Risk |
|---|---|---|---|
| **A. Run long simulations on GitHub Actions:** a manual-only workflow (`workflow_dispatch`), one job per seed and length, uploading the JSON and log as artifacts | Yes: the same code and the same headless harness. To confirm on day one: a 10-day run on CI must give the same fingerprint as locally | Small: CI already installs Godot 4.7.2 (`tests.yml`) | Free for a public repository; jobs are limited to 6 hours (a 365-day run needs about 1 hour); it publishes nothing and runs only by hand |
| **B. Keep the session active:** a harness-tracked background wait on the runs (in use since 03:05) | Yes: nothing in the run changes | None | Unproven: whether an active background wait prevents reclamation is not documented; the 03:05 runs will tell |
| **C. Checkpoint and resume** (PERF-06) | Only if the RNG state (not saved today: loading reseeds it), transient brain state and the harness's accumulators are all saved, proved by a broken-at-day-15 30-day run matching an unbroken one | Medium | A missed piece of state silently changes results; must be gated |

**Recommendation:** **A** for every run longer than about 30 minutes, with **B** as a fallback while a run is local. Keep **C** for later, behind its determinism gate. A needs the owner's approval: it adds a workflow and uses GitHub's runners.

### Validation of the GitHub Actions workflow (2026-10-20, INFRA-02)

**Comparison:** the same code (`9ec6b40`), seed 1, 10 days, sampled every 10 days. Local: `out/eq/val10` with its own user data. GitHub: run 39365379504, job 118440940456.

| | Local | GitHub Actions |
|---|---|---|
| Fingerprint | `eeabb2a8ce8d6ed8e9691867869bc6ee` | `eeabb2a8ce8d6ed8e9691867869bc6ee` |
| Deaths | Ivo Stone d3, Mabel Marsh d7, Rose Barley d10 | the same |
| Currency | total 4298 (villagers 3884, bandits 199, treasury 195, player 20), in 1456, out 85, leak 0 | the same |
| Item ledger | log 36+696-451-85=196; plank 28+256-89-80=115; iron bar 8+106-44-60=10; no leaks | the same |
| Runtime | about 2 min (shared container) | 57 s (simulate step) |

**Result:** identical. Long runs now go to GitHub Actions (`.github/workflows/long-sims.yml`, dispatched with `ref=staging/my-medieval-life`; every run records its commit).
