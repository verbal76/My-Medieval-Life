# MML — Deep Investigation: Repeated Player Movement Stutter and Backward Corrections

Owner directive, 2026-11-13, received in the Build 25 lead session. Saved verbatim.

---

MML — Deep Investigation: Repeated Player Movement Stutter and Backward Corrections
Owner direction: The player has experienced persistent movement problems resembling repeated backward steps, rubber-banding, or clock-like positional corrections.
A previous journey-stutter fix was reported around November 6, but two approximately 230 ms world-frame spikes remained and gameplay validation was incomplete.
I requested a serious investigation, not a minor adjustment.
Phase 1 — Recover the history

1. Examine movement-related commits, investigations, profiling records, issue logs, and tests from October 30 through November 13.
2. Identify the exact earlier fix, its commit, what it changed, and the evidence supporting it.
3. Determine whether a genuine root-cause investigation was performed or whether only a symptom was reduced.
4. Establish whether the two reported 230 ms spikes were subsequently explained or resolved.

Phase 2 — Investigate the actual movement problem
Trace the entire player-movement pipeline, including:

* Input processing and movement commands.
* Physics ticks and rendering interpolation.
* Player position and velocity updates.
* Pathfinding, collision, and navigation corrections.
* World simulation updates and expensive periodic operations.
* Save/load, background processing, and scheduled world events.
* Multiplayer authority, synchronization, prediction, and position reconciliation where applicable.

Do not assume this is a graphics-performance problem. Determine whether the character is actually moving backward in simulation or whether the screen is displaying delayed or corrected positions.
Phase 3 — Instrument and reproduce

1. Establish a deterministic reproduction if possible.
2. Record frame times, physics-tick times, player coordinates, velocity, input, and correction events.
3. Profile normal movement, journeys, populated settlements, and multiplayer where applicable.
4. Identify whether the problem follows a periodic interval, player location, simulation workload, or network event.
5. Correlate each visible backward step with the underlying game state.
6. Compare behavior before and after the previous fix.

Phase 4 — Findings
Report:

* Confirmed root causes versus hypotheses.
* Exact offending functions and relevant commits.
* Frequency and severity of stalls or positional corrections.
* Whether the previous fix actually addressed the underlying cause.
* Reproduction steps and measured evidence.
* Recommended corrections, ranked by impact and risk.

Investigate unexplained behavior rather than dismissing it because a test passes.
Restrictions
This is an investigation first. Do not make speculative movement changes, alter simulation baselines, merge branches, dispatch GitHub Actions, rebuild packages, or publish releases.
Keep the boar and ND-29 workers undisturbed.
Once the causes are established, present the evidence and proposed fixes before implementation.
Completion standard: Do not mark this investigation complete merely because movement appears smoother. Demonstrate what caused the repeated backward steps and verify that the cause has been eliminated.
