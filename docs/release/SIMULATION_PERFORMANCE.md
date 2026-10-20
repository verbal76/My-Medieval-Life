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

## 2. Timing of the running fix12 simulations

`out/eq/timing_fix12.txt` (not committed): the UTC time each 10-day line appeared, with the number of Godot processes running. The results are summarized here when the runs end.

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
