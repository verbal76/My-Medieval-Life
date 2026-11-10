# Owner directive, 2026-11-10: Continued investigation, validation and merge preparation

Received 2026-11-10 in the lead session. Saved verbatim below; never edited. Register ids B25-CONT-INV-01 (whole directive),
B25-INV-P100-FULLPACK (2A), B25-INV-P52-BLOCKS (2B), B25-INV-BANDIT-CHILD (2C); extends B25-F015-FOOD-01, B25-P99-PAYER-01,
B25-FINAL-REVIEW-01.

---

MML Build 25 — Continued Investigation, Validation and Merge Preparation

Claude, continue the current Build 25 workstreams. We have two fixes implemented and three additional findings requiring investigation.

Primary directive: Keep the Batch 3+4 merge candidate isolated from subsequent defect fixes. Continue validation, investigate all unresolved findings, and preserve the owner approval gates.

1. Complete F015 and Smith Purchase Fix Validation

Current fix branch: "wip/b25-f015-p99"
Tested commit: "3d515d6"

Running GitHub Actions:

- Full Tests: "42832327842"
- Simulation gate: "42832333046"
- Recorded 365-day campaign: "42832338970"

Retrieve the actual artifacts and verify results against this exact commit.

Confirm:

- Smiths no longer repeatedly plan purchases that cannot satisfy actual price and household reserve requirements.
- F015 homesteaders correctly distinguish physical food inventory from purchasing capacity.
- Hungry homesteaders can purchase available edible food through legitimate transactions.
- No food, items, or coins are created or lost.
- Save/load and deterministic replay remain correct.
- The fixes do not introduce new starvation, economic, or trading regressions.

Compare both 365-day seeds against their previous results. Report counts and causal explanations, not just whether CI is green.

Do not merge this branch until validation is complete and I approve integration.

2. Investigate Three Additional Findings

Start three independent, read-only investigations where practical. Do not delay them while the 365-day campaign runs.

A. p:100 — Meal Purchases Refused Due to Full Inventory

The campaign recorded 45 refusals in one day because the villager's pack was full.

Investigate:

- Which planner schedules the purchase.
- Whether it checks carrying capacity.
- Whether the execution layer uses a different capacity rule.
- Whether the same defect affects other purchases or villagers.
- Whether failed attempts bypass an existing retry-suppression mechanism.

Recommend a correction that aligns planning with actual purchase eligibility.

B. p:52 — Repeated Building-Block Purchase Failures

The campaign recorded 453 consecutive refusals, compared with 42 previously.

Identify:

- The responsible planner and execution path.
- The precise refusal reason.
- Why the same purchase repeats.
- Whether the increase reflects a new regression or an existing defect amplified by changed simulation conditions.
- Whether similar behavior occurs in other construction or material-purchasing systems.

Trace the actual cause using campaign artifacts and code evidence. Do not assume it is another coin-reserve problem.

C. Bandit-Clan Children Starving Despite Household Food

Four children starved on days 305–306 while their household reportedly held food.

Investigate:

- Where the food was physically stored.
- Whether the children could access it.
- Household ownership and food distribution rules.
- Whether an adult or household process was responsible for feeding them.
- Whether food was edible, reachable, or reserved for another purpose.
- Whether the issue affects ordinary households as well as bandit clans.

Distinguish an actual food-distribution defect from legitimate shortages or inaccessible supplies.

For all three investigations, produce the root cause, affected scope, supporting evidence, proposed correction, and regression-test requirements.

Do not implement speculative fixes. Once causes are verified, implement focused corrections on isolated branches where existing authorization permits; otherwise present the proposed change for owner approval.

3. Finish Batch 3+4 Baseline Attribution

Merge candidate: "fbfd6ad"
Current development line: "9fd18a5"

Complete the investigation of the 33 blocking baseline findings.

Group the 32 measurement differences by their actual initiating causes, distinguishing those causes from downstream consequences.

Pay particular attention to Generation 8 world generation and the change from 25 to 26 households.

For each causal group, report:

- Previous behavior and measured values.
- New behavior and measured values.
- First commit where the measurement changed.
- Verified underlying cause.
- Whether the change is intentional, corrective, defective, or unexplained.
- Recommendation: ACCEPT, FIX, or INVESTIGATE.

Do not treat an obsolete baseline as automatically acceptable. Verify the replacement measurements and their causes.

4. Prepare the Batch 3+4 Owner Decision Report

Both campaign seeds on "fbfd6ad" have completed and been verified.

Include:

- Strict Tests: 277 suites, 0 failed.
- Gate findings: 33 known baseline findings, no new blockers.
- Both 365-day campaign results.
- Improvements in repeated food-purchase failures.
- Remaining known defects, including smith refusals, F015, full-pack refusals, building-block refusals, and bandit-child starvation.
- Completed baseline attribution.
- Exact commit SHAs, workflow IDs, and artifact evidence.
- A clear recommendation on whether Batch 3+4 can be merged independently of the isolated defect fixes.

Explain the results in terms of actual gameplay and simulation behavior, not merely technical measurements.

5. Governance and Integration

Maintain the following rules:

1. Do not merge "fbfd6ad" without my explicit approval.
2. Do not merge "wip/b25-f015-p99" without successful validation and my approval.
3. Do not accept, replace, or re-record simulation baselines without my explicit approval.
4. Do not weaken tests or suppress findings to obtain passing results.
5. Investigate unexplained changes before accepting them.
6. Keep independent workstreams isolated until their dependencies and validation gates are satisfied.
7. Preserve worktrees, uncommitted work, logs, reports, and campaign artifacts.
8. Record all findings, decisions, reasons, and validation evidence in the project register and state documentation.
9. Report exact commit SHAs and verified test counts.
10. Do not repeatedly ask for approval on already authorized investigation or testing work.

6. Next Report

When the baseline attribution is complete, deliver the Batch 3+4 owner decision report immediately. Do not hold that report waiting for the separate F015/p:99 campaign or the three new investigations.

Report those independent workstreams separately as their evidence becomes available.

The objective is to resolve every finding, not merely achieve passing CI. Continue productive investigation and validation while preserving the approval gates. Bring me decisions only when there is sufficient evidence to make them.
