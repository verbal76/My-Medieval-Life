# Owner directive 2026-10-31: Expansion 20 year-long validation and release readiness

Verbatim, as received in the coordinating session on 2026-10-31. Register: X20-MERGED-VALIDATION (scope of its report).

---

MY MEDIEVAL LIFE — EXPANSION 20 YEAR-LONG VALIDATION AND RELEASE READINESS

Claude, continue the approved Expansion 20 validation on integrated commit "ad281dc9431b782582513ef8a083c962b5039b8f".

The objective is to determine whether the integrated systems remain stable, economically balanced, deterministic, and believable over a full simulated year.

Do not interrupt, restart, duplicate, or expand the three simulations already dispatched.

1. Preserve the current integration

The following work is already merged into "wip/expansion20":

- Worker D: bandit intelligence and incident counting.
- Worker F: judgment calibration.
- Worker G: tool repair and rental.
- Flight-recorder correction from "a3643c8".

The 42 integration tests and F's additional calibration suite have passed.

The replacement 30-day baseline was reproduced three times locally, with identical states and no coin or item conservation violations.

Treat this as established evidence. Do not repeat these tests without a demonstrated reason.

2. Complete the three approved 365-day simulations

Monitor these existing GitHub Actions runs:

Normal settings, seeds 1 and 2:
https://github.com/verbal76/My-Medieval-Life/actions/runs/41233948995

Economy enabled, seed 1:
https://github.com/verbal76/My-Medieval-Life/actions/runs/41233970504

All results must be associated with the exact tested commit.

Allow the runs to complete naturally. Do not dispatch additional year-long simulations without identifying a genuine need and obtaining approval.

3. Analyze long-term village stability

For each simulation, provide a separate report covering:

Population and demographics

- Starting and ending population.
- Births, deaths, and migration.
- Causes of death.
- Population changes over time.
- Any evidence of demographic collapse or uncontrolled growth.

Economy and conservation

- Total coins across all holders.
- Coin distribution among villagers, households, businesses, and treasury.
- Item conservation.
- Production, consumption, trade, and inventory movement.
- Economic shortages or accumulation.
- Any stalled economic activity.
- Differences between normal and economy-enabled simulations.

Bandit intelligence

- Bandit incidents and outcomes.
- Bandit-related deaths.
- Changes in bandit behavior over time.
- Whether responses to threats are consistent with the implemented intelligence rules.
- Any repeated, irrational, or pathological behavior.

Judgment and social behavior

- Reputation and judgment changes.
- Effects on actual NPC decisions.
- Candidate-choice distributions.
- Whether negative opinions influence decisions without becoming absolute prohibitions.
- Any evidence of runaway hostility, social isolation, or unrealistic behavior.
- Flight-recorder integrity.

Tool repair and rental

- Rental frequency and utilization.
- Repair frequency.
- Tool durability and availability.
- Rental income and expenses.
- Economic sustainability.
- Ownership and inventory integrity.
- Any exploit, deadlock, or unreasonable NPC behavior.

For measurements not currently recorded, explicitly identify the limitation. Do not invent data or change the simulation to manufacture missing metrics.

4. Compare the three simulations

Produce side-by-side tables and time-series graphs where the existing evidence supports them.

Compare:

- Seed 1 versus seed 2 under normal settings.
- Seed 1 normal versus seed 1 with the economy enabled.
- New Expansion 20 results versus the earlier available baseline evidence.

Distinguish expected simulation variation from genuine regressions.

Identify any significant differences in population survival, economic stability, NPC decision-making, bandit outcomes, and tool availability.

5. Validate simulation integrity

For each run, report:

- Exact SHA.
- Workflow status and conclusion.
- Simulated days completed.
- Checkpoint results every 10 days.
- Coin and item conservation.
- Any exceptions, warnings, crashes, or stalls.
- Any determinism or state-integrity failures.
- Any incomplete or unavailable evidence.

A successful GitHub Actions conclusion alone is not sufficient. Review the actual simulation results and identify whether the village remains viable.

Do not classify an unfamiliar but valid emergent behavior as a defect merely because it differs from the previous baseline.

6. Release-readiness assessment

After all three runs finish, classify findings as:

A — Release blockers: crashes, determinism failures, conservation violations, invalid state, broken essential systems, or severe simulation failures.

B — Significant gameplay defects: clearly irrational behavior, dysfunctional economic systems, severe unintended population outcomes, or major balancing problems.

C — Nonblocking observations: ordinary simulation variance, minor imbalances, reporting limitations, or opportunities for future refinement.

Do not start another development cycle to address Category C observations.

For Category A or B findings, provide the evidence, root-cause assessment, and smallest justified correction. Do not make broad gameplay changes without approval.

7. Preserve deferred decisions

The following remain deferred:

- Go-between buying.
- Dislike-driven migration.

Do not implement or reopen them during this validation.

Do not introduce unrelated systems or new balancing mechanics.

8. Final deliverable

When both GitHub workflows complete, deliver one consolidated Expansion 20 validation report containing:

1. Executive summary.
2. Exact commit and workflow references.
3. Results for all three 365-day simulations.
4. Population and economic graphs.
5. Bandit intelligence analysis.
6. Judgment and social-decision analysis.
7. Tool repair and rental analysis.
8. Determinism and conservation results.
9. Comparison with previous baseline evidence.
10. Identified defects and their severity.
11. Release-readiness recommendation.
12. Any decisions genuinely requiring my approval.

Continue the existing monitoring and scheduled check-in.

Do not merge into a release branch, publish a build, or initiate additional major testing without my approval.

Our objective is to establish whether Expansion 20 is stable enough to advance, not to pursue endless optimization.

Proceed with the three already-approved year-long runs and report their results when complete.
