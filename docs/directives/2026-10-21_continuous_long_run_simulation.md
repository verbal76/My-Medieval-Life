# Permanent owner directive, 2026-10-21: continuous long-run simulation testing (verbatim)

PERMANENT OWNER DIRECTIVE — CONTINUOUS LONG-RUN SIMULATION TESTING

Purpose

Effective immediately, change the simulation testing strategy for My Medieval Life across Build 17 and all future builds and expansions.

Owner decision: Stop running redundant 30-, 90-, 100-, and 365-day simulations separately when they validate the same scenario.

Instead, execute the longest required simulation once per required seed and monitor it continuously, with intermediate checkpoints.

This is a permanent testing efficiency policy.

1. Core principle

If we need to validate a village through 365 days, start a 365-day simulation immediately.

Do not run a 30-day simulation, restart the same world for 90 days, restart again for 100 days, and finally restart for 365 days merely to establish the same conditions.

The reasoning is straightforward:

- A failure on day 12 is detected on day 12, regardless of the requested maximum duration.
- A failure on day 45 is detected on day 45 without replaying the first 30 days.
- Reaching day 100 already provides the observations that equivalent 30-, 90-, and 100-day runs would have provided.
- Reaching day 365 completes the full long-run validation without repeatedly simulating the same early days.

A 365-day run must be continuously validated, not simply checked when it finishes.

2. Required implementation

For every applicable long-running simulation:

1. Start with the longest required duration.
2. Use the required seed and test configuration.
3. Monitor simulation invariants throughout execution.
4. Capture results at days 30, 90, 100, 365, or other relevant milestones.
5. Preserve useful diagnostic information at each checkpoint.
6. Stop early when a genuine simulation defect is detected.
7. Report the exact seed, simulated day, failed invariant, and relevant diagnostic state.
8. Do not restart from day zero simply to produce a shorter-duration report.

Where existing test infrastructure supports this already, reuse it. Do not build a new testing framework unnecessarily.

3. Continuous validation requirements

Maintain all applicable checks, including:

- Currency conservation.
- Item and material conservation.
- Valid inventory transfers.
- No duplicate goods or payments.
- No invalid negative inventories or balances where prohibited.
- NPC state and task consistency.
- Physical resource extraction and transport integrity.
- Production-chain correctness.
- Simulation integrity and determinism requirements.
- Any feature-specific invariants previously covered by the shorter tests.

Intermediate snapshots should capture relevant population, production, trade, inventory, employment, resources, and other metrics already required by existing tests.

Do not weaken or remove assertions merely to make the long run pass.

4. Distinguish simulation defects from legitimate village failure

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

A village may legitimately experience:

- Starvation.
- Population decline.
- Economic shortages.
- Resource exhaustion.
- Business failures.
- Failed production chains caused by actual scarcity.
- Inability to complete projects because materials or labor are unavailable.

These outcomes are not automatically simulation defects.

Record them as economic or gameplay outcomes and continue when the simulation remains valid.

Stop immediately for actual simulation failures, including conservation violations, impossible states, broken invariants, or other established fatal conditions.

If an existing acceptance criterion specifically requires a successful economic outcome, report that criterion as failed without confusing it with a conservation or simulation-integrity failure.

5. Preserve meaningful test coverage

Separate simulations remain appropriate when they test genuinely different conditions, such as:

- Different world seeds.
- Different population sizes.
- Different economic scenarios.
- Different feature configurations.
- Specific regression reproductions.
- Independent runs required for determinism comparisons.
- Focused unit, integration, or smoke tests.

Do not combine tests that are materially different merely because they share a duration.

Likewise, do not remove a short test that provides unique assertions or materially faster failure detection without incorporating equivalent coverage.

The rule is to eliminate redundant simulation work, not necessary validation.

6. Determinism

Preserve the existing determinism requirements.

If verifying repeatable results requires two independent executions of the same seed and configuration, perform the necessary comparison.

Do not claim that one successful execution proves determinism.

Reuse existing passing determinism evidence when it applies to the exact intended source state and configuration.

Avoid additional duplicate runs for reassurance.

7. Apply immediately to Build 17

Review the existing MIN-G and Build 17 simulation plan.

Where the 30-, 90-, 100-, and 365-day tests use equivalent scenarios:

- Consolidate them into one monitored 365-day run per required seed.
- Capture the intermediate checkpoints.
- Preserve all relevant assertions.
- Reuse already completed valid test evidence.
- Do not restart completed runs unnecessarily.
- Do not delay the release merely to rewrite working test infrastructure.

If the current test harness cannot provide continuous validation or intermediate observations, make the smallest practical adjustment, or use the existing equivalent coverage and report the limitation.

Do not initiate another comprehensive test campaign just to adopt this policy.

8. Make the policy permanent

Record this owner decision in the appropriate permanent project documentation, including:

- The development instructions in "CLAUDE.md" where applicable.
- The owner decision log.
- The testing strategy or simulation test documentation.
- Relevant Build 17 and future expansion test plans.

Apply the rule to future development automatically.

Feature workers should follow it without requiring the owner to repeat the instruction.

Keep the policy consistent across active development branches where practical, without disrupting running workers or creating unnecessary merge conflicts.

9. Reporting requirements

Future long-run simulation reports should identify:

- Source commit tested.
- Seed and configuration.
- Maximum intended duration.
- Actual day reached.
- Checkpoint results.
- Any genuine failures.
- Any legitimate village failures or noteworthy economic outcomes.
- Conservation and determinism evidence.
- Whether any separate runs were necessary and why.

Do not present four checkpoint reports as four independent simulation executions when they came from one continuous run.

10. Development efficiency

The owner's objective is to reduce wasted development time, unnecessary compute, and redundant testing.

Do not spend time rebuilding already proven infrastructure or repeating previously validated simulation days without a meaningful reason.

Implement the smallest change necessary to adopt this policy.

Continue existing Build 17 integration and release-readiness work.

No new owner approval is required to eliminate redundant simulation durations when equivalent coverage is preserved.

Report briefly when this policy has been recorded and whether it changes the remaining Build 17 test schedule.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
