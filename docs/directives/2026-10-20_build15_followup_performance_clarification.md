# Owner directive, 2026-10-20: Build 15 follow-up and simulation performance clarification

Saved verbatim from the owner's message. Register: PERF-01..06, EQ-07, HOUSE-07.

---

MY MEDIEVAL LIFE — BUILD 15 FOLLOW-UP AND SIMULATION PERFORMANCE CLARIFICATION

Claude,

Yes, I authorized the simulation performance audit directive forwarded by the independent read-only Claude session.

You may preserve its findings and register the approved performance investigation. However, this work remains secondary to Build 15 stabilization and EQ-07 housing.

Do not interrupt the currently running simulations.

1. Continue the housing investigation

The interrupted simulations revealed:

- Seed 1 reached day 120 with 7 houses started and 1 completed.
- Seed 2 reached day 160 with 9 houses started and 1 completed.
- Available planks reportedly remained between 108 and 173.

This suggests material availability is no longer the primary bottleneck.

Trace stalled construction sites individually, including:

- Founder's available money and income.
- Construction labor and assigned workers.
- Material purchasing and delivery.
- Work scheduling and NPC priorities.
- Construction progress and completion conditions.
- Whether founders abandon, defer, or repeatedly restart construction tasks.

Identify the actual root cause using simulation evidence.

Continue implementing approved corrections and testing them. Do not stop productive development while waiting for the long simulations.

2. Explain the simulation runtime discrepancy

This question remains unresolved and requires a measured answer.

The independent audit found historical 365-day simulation runtimes of approximately 530–689 seconds, or 9–12 minutes.

However, you originally projected completion at 04:30 UTC, and the restarted simulations were subsequently projected to finish at 05:20 UTC.

The container restart explains why the original simulations were interrupted. It does not explain why their expected execution time was so much longer than the historical benchmarks.

Please determine:

1. Exactly how the original 04:30 UTC estimate was calculated.
2. The actual start times of the interrupted simulations.
3. Their elapsed wall-clock runtimes when the container restarted.
4. Their final progress: seed 1 at day 120 and seed 2 at day 160.
5. The measured seconds per simulated day for each seed.
6. Whether execution became progressively slower as populations, households, wildlife, or construction sites increased.
7. Whether running multiple simulations simultaneously caused CPU or memory contention.
8. Whether the current code is substantially slower than the version used for the historical benchmarks.
9. How the new 05:20 UTC completion estimate was calculated.
10. Whether the current runs are progressing at the rate required to meet that estimate.

Distinguish verified measurements from estimates and hypotheses.

If the necessary logs or timestamps were lost during the restart, explicitly state what cannot be determined.

Do not invent measurements.

I want to know whether we have a real performance regression, resource contention, or simply inaccurate completion estimates.

3. Investigate the container restart

Determine what is known about the restart that killed both simulations.

Report whether it was caused by resource exhaustion, session lifecycle behavior, infrastructure interruption, or an unknown cause.

Investigate whether long simulations can safely support checkpointing and resuming without changing deterministic outcomes.

Do not implement a checkpointing system until its design and risks have been evaluated.

4. Preserve development priorities

Continue in this order:

1. Build 15 stabilization.
2. EQ-07 housing completion investigation and corrections.
3. Required housing regression testing.
4. Simulation performance profiling and baseline measurements.
5. Proven, deterministic performance optimizations.

Performance investigation documentation can proceed alongside other work, but it must not interfere with running simulations.

Continue committing and pushing approved work to the appropriate remote GitHub branches under the existing testing and promotion requirements.

Do not publish a distributable build without my authorization.

5. Report back

Provide a concise status report covering:

- Current progress of both 365-day simulations.
- Evidence explaining why houses are not finishing.
- Measured simulation runtime versus historical benchmarks.
- Whether the original completion estimates were justified.
- What is known about the container restart.
- Next corrective actions.

Do not restart, cancel, or modify the running simulations merely to answer these questions.

The objective is to get Build 15 stable while making sure we aren't wasting hours on simulations that historically completed in minutes.
