# Owner directive, 2026-10-20: controlled parallel development, expansion milestones and agent budget

Saved verbatim. Register: AGENT-01 (the agent budget and its controls), MILE-01 (milestone assignments respected).

---

MY MEDIEVAL LIFE — CONTROLLED PARALLEL DEVELOPMENT
Expansion Milestones and Agent Budget
Clarification from the owner:
Our builds are substantial expansion milestones, not small collections of miscellaneous features.
The judgment system, living economy, settlement expansion, and other planned systems each have their own design scope and delivery milestone.
Do not assume that every feature mentioned during Build 16 belongs in Build 16. Respect the existing expansion documents, approved milestone assignments, and dependencies.
In particular, preserve the standalone Living Economy Expansion plan and the reserved Build 19 NPC Judgment milestone unless I explicitly authorize a change.
Controlled agent authorization
You are authorized to use up to two additional subagents, for a maximum of three active agents including yourself.
This is a ceiling, not a target. Use fewer agents when the work does not justify parallel execution.
Primary agent: Own architecture, integration, task assignment, simulation decisions, and final verification.
Worker 1: Handle a clearly isolated implementation task with explicit files, requirements, and acceptance criteria.
Worker 2: Handle a different nonoverlapping task, or targeted testing and regression analysis.
Credit and resource controls

1. Never launch more than two subagents simultaneously.
2. Do not spawn nested agents.
3. Do not launch agents merely to investigate what another agent already knows.
4. Do not have multiple agents independently read the entire repository.
5. Provide workers with concise, relevant context and specific file paths.
6. Assign bounded tasks with a clear stopping point.
7. Avoid repeated full test-suite runs by multiple agents.
8. Only the primary agent should coordinate expensive long-running village simulations.
9. Reuse existing reports and test evidence where valid.
10. Stop an agent when it completes its assignment. Do not leave it running speculatively.

Budget awareness
Start with one additional worker.
Introduce the second only when there is genuinely independent work that can run in parallel.
If the available tooling exposes actual token or cost usage, monitor it. Do not invent usage measurements.
If consumption rises unexpectedly, reduce concurrency immediately and report the cause.
Do not start large parallel investigations without a clear expected benefit.
Build 16 priorities
Finish the Build 16 inventory and completion audit.
Identify the critical path and select parallel tasks that do not interfere with household-pantry stabilization, economic baselines, or determinism testing.
Do not silently move future expansion features into Build 16.
Do not sacrifice test coverage or simulation correctness for speed.
Continue approved development, commit and push verified changes to staging, and do not merge or publish without authorization.
Reporting
In normal progress reports, include a brief agent summary:

* Number of agents used.
* Each agent's assignment.
* What each completed.
* Any duplicate work or integration conflicts.
* Whether parallel execution appears to be saving time.
* Any observable token or credit consumption concerns.

The objective is to buy back development time, not consume credits faster.
