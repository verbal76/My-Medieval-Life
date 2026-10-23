# Owner direction, 2026-10-23: Bounded parallel simulation testing

Saved verbatim.

---

Owner direction — Bounded parallel simulation testing

Simulation testing is authorized to run alongside approved development on Expansions 19–23, without blocking or replacing that development.

Do not create an indefinite simulate-analyze-fix-repeat loop.

Run simulations against fixed, identified commits, with defined durations and stop conditions. Reuse existing results and only extend runs when findings justify additional coverage.

Analyze and report meaningful defects, their evidence, and likely causes. Do not automatically fix unrelated problems or launch repeated campaigns without owner approval.

Prioritize approved expansion implementation and playable releases over exhaustive simulation campaigns.

Use idle compute capacity where possible, but do not consume additional Claude agents or substantial context merely to supervise simulations that can run unattended.

At each checkpoint, report simulation duration, tested commit, findings, actual development progress, and remaining work.

Simulation is a bounded supporting workstream, not a perpetual development task.
