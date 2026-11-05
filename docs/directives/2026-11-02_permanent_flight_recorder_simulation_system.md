MY MEDIEVAL LIFE

PERMANENT FLIGHT RECORDER SIMULATION SYSTEM

Owner Directive — Build 25 and All Future Expansions

I want to establish a permanent, independent simulation system that runs entirely through GitHub Actions.

From this point forward, whenever I say:

"Run flight recorder"

You must automatically initiate a complete, 365-game-day simulation campaign on GitHub.

No additional explanation, configuration questions, or approval should be necessary.

This is a standing owner authorization.

1. REUSE OUR EXISTING SYSTEMS

We already have:

- GitHub Actions long-running simulations.
- The "economy_sim.gd" simulation harness.
- The flight recorder and event archives.
- Recorder analysis tools.
- Excel workbook generation.
- Automated integrity and conservation checks.

Audit these systems and connect them into one reliable standalone operation.

Do not unnecessarily rebuild working infrastructure.

Implement the command behavior in the permanent project instructions, including "CLAUDE.md", so future Claude sessions recognize it.

2. DEFAULT SIMULATION CONFIGURATION

When I say "Run flight recorder," automatically use:

- Duration: 365 game days.
- World seeds: 1 and 2.
- Maximum concurrency: Two simulation jobs.
- Flight recorder: ENABLED.
- Checkpoints: Every 10 game days.
- Scenario: Normal integrated village gameplay.
- Source: Latest suitable integrated development commit.
- Execution: GitHub Actions.
- Output: Complete flight recorder archives, Excel analysis, and diagnostic reports.

Both seeds must simulate independently.

If I specify different seeds, duration, or scenarios, those instructions override these defaults.

The 365-day run must capture intermediate observations without restarting separate 30-, 90-, or 180-day simulations.

3. CATASTROPHIC FAILURE AND EARLY TERMINATION

The objective is to simulate the entire year.

However, do not waste several hours simulating an extinct village.

Terminate a simulation early if the entire village population has died and the existing game systems provide no possibility of recovery or repopulation.

Also terminate for genuine fatal simulation defects, including:

- Impossible world states.
- Unrecoverable simulation crashes.
- Confirmed currency or inventory conservation violations.
- Irrecoverable recorder corruption.
- Other established fatal integrity failures.

Ordinary starvation, unemployment, business failures, economic hardship, and individual deaths are NOT reasons to terminate a simulation.

A village may legitimately struggle or fail economically.

A village is allowed to fail. The simulation is not.

Before terminating, save the relevant evidence.

Always report why the simulation stopped and the exact simulated day reached.

4. RECORD NPC AND SYSTEM BEHAVIOR

The flight recorder must capture every interaction supported by our existing instrumentation.

This includes, where instrumented:

- NPC decision-making.
- Employment and job selection.
- Farming and production.
- Trading and purchasing.
- Businesses and economic activity.
- Contracts and credit.
- Food consumption and starvation.
- Chapel donations and relief.
- Government decisions and spending.
- Crime and combat.
- Relationships and household development.
- Resource movement.
- Inventory and currency transfers.
- Failed actions.
- Repeated decisions.
- Interruptions and abandoned tasks.
- Other integrated gameplay systems.

Audit recorder coverage against the current Expansion 20 systems and upcoming expansion integrations.

Identify meaningful coverage gaps rather than claiming complete coverage where instrumentation does not exist.

Preserve simulation determinism and ensure recording does not change gameplay outcomes.

5. AUTOMATICALLY SEARCH FOR ABNORMAL BEHAVIOR

This is the most important requirement.

We previously discovered NPC behavior involving a villager repeatedly attempting to purchase an axe hundreds of times.

I want the system to find that kind of behavior automatically.

Analyze the complete recorded archive for suspicious patterns.

Examples:

Decision loops

- NPC repeatedly attempting the same failed action.
- Repeated purchases that never succeed.
- Endless job searches.
- Repeatedly selecting impossible tasks.
- NPCs switching endlessly between two decisions.

Economic abnormalities

- Businesses making repeated irrational transactions.
- Money or goods disappearing.
- Duplicate payments.
- Contracts repeatedly failing.
- Villagers unable to purchase available necessities.

Survival abnormalities

- Starving villagers surrounded by available food.
- Chapel relief failing to reach eligible households.
- NPCs repeatedly abandoning food-seeking behavior.
- Workers unable to access essential resources.

System integration abnormalities

- Two systems interfering with each other.
- Tasks endlessly interrupting one another.
- Conflicting priorities.
- Broken resource transfers.
- NPCs becoming permanently stuck.
- Unexpected cascades of failures.

Use meaningful thresholds and context to distinguish suspicious repetition from legitimate repeated work.

For every finding, identify the NPC, event, simulated day, repetition count, affected systems, and supporting evidence.

Do not automatically modify gameplay to suppress unusual behavior.

Report the findings for investigation.

6. AUTOMATIC EXCEL WORKBOOK GENERATION

Every completed simulation must produce a readable Excel workbook using our existing workbook-generation infrastructure.

Include worksheets covering:

1. Executive summary.
2. Population and survival.
3. Food production and consumption.
4. Economy and employment.
5. Businesses and trade.
6. Chapel activity and relief.
7. Contracts and credit.
8. NPC behavior and decisions.
9. Repeated failed actions.
10. System interaction anomalies.
11. Currency and inventory integrity.
12. Critical events and deaths.
13. Trends and graphs.
14. Recorder coverage and limitations.

Use meaningful charts where practical.

The workbook should prominently display the most significant findings.

Do not limit the actual analysis to the workbook's existing 20,000-event presentation cap.

Analyze the complete event archive, then provide useful summaries and prioritized examples in Excel.

Preserve the full underlying recorder data separately.

Avoid generating unusably enormous workbooks.

7. AUTOMATED FINDINGS REPORT

GitHub must automatically generate a concise findings report.

Categorize findings:

CRITICAL
Confirmed simulation defects, broken invariants, or impossible states.

HIGH
Repeated behavioral failures, severe economic abnormalities, or significant system interaction defects.

MEDIUM
Suspicious trends requiring investigation.

INFORMATIONAL
Normal economic observations, village development statistics, and legitimate hardships.

Every finding should include enough evidence to reproduce or investigate it.

Distinguish confirmed defects from suspicious observations.

Do not claim that an unusual result is a programming defect without supporting evidence.

8. INDEPENDENT GITHUB EXECUTION

This workflow must be entirely independent of:

- Active development workers.
- Other simulation campaigns.
- CI regression gates.
- Build packaging.
- Releases.
- Pull-request approval.
- Other expansion work.

Launching the flight recorder must not stop, pause, or block normal development.

Use a dedicated workflow or suitably isolated existing workflow.

Each run must be tied to its exact source commit.

Do not automatically cancel an older simulation merely because development continues.

Do not automatically rerun a failed year-long simulation without first examining the failure.

Control parallel execution and artifact sizes to protect GitHub Actions spending.

Account for the additional runtime and storage required when full flight recording is enabled.

Ensure the actual GitHub workflow timeout accommodates a recorded 365-day simulation, or implement a reliable checkpoint/resumption mechanism.

9. PRESERVE RESULTS EVEN ON FAILURE

At the end of each run, whether successful or failed, preserve:

- Complete recorded event archives.
- Simulation logs.
- Excel workbook where generation is possible.
- Findings report.
- Machine-readable results.
- Relevant checkpoint data.
- Source commit.
- Seed and configuration.
- Actual days completed.
- Reason for termination.

Artifacts must be downloadable through GitHub.

The workflow should provide a clear GitHub Actions summary with direct links to its results.

Do not lose all diagnostic information because a simulation terminates on day 247.

10. CLAUDE AND CHATGPT REVIEW

GitHub is responsible for running simulations, collecting evidence, and performing automated anomaly detection.

Claude is responsible for reviewing those findings and investigating suspected defects.

ChatGPT must also be able to independently retrieve and inspect GitHub results.

Do not require a local Claude process to remain occupied while simulations run.

When I return and ask:

"What did the flight recorder find?"

Retrieve the latest results and explain:

- What happened.
- What worked.
- What failed.
- Which NPCs behaved strangely.
- Which systems may be interfering.
- What deserves further investigation.

Provide the most important findings first.

11. IMPLEMENTATION AND FIRST EXECUTION

Implement this permanent command using existing infrastructure wherever possible.

Record the owner directive.

Create or update the standalone GitHub workflow.

Ensure flight recording and automated analysis are enabled by default.

Verify Excel workbook generation works in GitHub's headless environment.

Run focused validation of the workflow without unnecessarily repeating existing full test suites.

Once operational, automatically initiate the first two-seed, 365-day campaign against the latest suitable Build 25 integration commit.

If a known, imminent fix makes the current commit unsuitable, use the corrected integration commit rather than wasting an entire simulation campaign on a known defect.

Provide the GitHub Actions link immediately after dispatch.

Do not wait for the simulations to finish before continuing development.

PERMANENT OWNER COMMAND

From now on:

"RUN FLIGHT RECORDER"

Means:

Launch independent 365-day My Medieval Life simulations on GitHub, with full flight recording, automatic behavioral analysis, Excel reports, and preserved diagnostic evidence.

No additional explanation or approval is required.

No other development tasks should be blocked.

This system must remain available through future builds and expansions.
