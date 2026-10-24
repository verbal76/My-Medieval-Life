Owner directive, 2026-10-24, verbatim.

MY MEDIEVAL LIFE — PERMANENT SIMULATION, BLACK-BOX FLIGHT RECORDER, AND EXCEL QUALITY GATE
OWNER DIRECTIVE — ALL FUTURE BUILDS
This is a permanent development and release requirement for My Medieval Life.
Every future build must undergo comprehensive automated village simulations, capture simulation activity through the existing black-box flight recorder architecture, and produce an Excel analysis workbook before release packaging.
This is not an optional audit, a one-time experiment, or a task requiring repeated owner authorization.
The flight recorder, simulation analysis, and Excel workbook are mandatory components of every build.
The owner has not seen sufficient evidence that the previously discussed flight recorder and simulation reporting are actually operating. Your first responsibility is to audit their current implementation and identify what exists, what is incomplete, and what has not been connected to the build pipeline.
Do not claim these capabilities exist until verified.
1. PERMANENT BUILD PIPELINE
Implement this mandatory sequence:

1. Complete the intended development changes.
2. Run existing unit, integration, gameplay, and regression tests.
3. Run comprehensive automated village simulations.
4. Capture simulation activity through the black-box flight recorder.
5. Export the recorded data in structured form.
6. Generate the Excel analysis workbook, including charts and historical comparisons.
7. Evaluate the simulation against established acceptance criteria.
8. Stop packaging if a mandatory quality gate fails.
9. If all gates pass, package Android, Windows, and Linux from the exact verified commit.
10. Attach the workbook, simulation summary, and verification evidence to the authorized private draft release.

The simulation must run against the exact source commit used for packaging.
Any source change after verification invalidates the release audit unless the exact verified artifact and inputs remain unchanged.
Do not bypass this process because a code change appears minor.
2. AUDIT THE EXISTING BLACK-BOX RECORDER
Before implementing anything new, inspect the existing flight recorder design, implementation, tests, and project documentation.
Determine:

* Whether the recorder actually exists in executable code.
* Whether it records events from the complete village simulation.
* Whether it captures hourly state snapshots.
* Whether it records the decisions and actions of NPCs.
* Whether it tracks economic transactions and resource movements.
* Whether it captures relationship and morality changes.
* Whether it records crimes, witnesses, and guard responses.
* Whether it captures event causes and consequences.
* Whether its output can be exported.
* Whether an Excel analysis pipeline exists.
* Whether any CI workflow invokes it.
* Whether recorder output has been validated against simulation truth.

Classify each component as implemented, partially implemented, designed but not implemented, or missing.
Do not create a second recorder if an existing implementation can be completed or extended.
Preserve the previously approved recorder architecture and recording controls.
3. COMPREHENSIVE AUTOMATED VILLAGE SIMULATIONS
Every build must run reproducible simulations that exercise the village over meaningful periods.
Include different starting conditions and deterministic seeds.
Cover normal village operation, economic stress, resource shortages, population changes, and unusual events.
Use both:

* Fixed regression seeds for historical comparison.
* A broader deterministic rotating sample to uncover new defects.

Measure the actual execution cost and choose meaningful sample sizes.
Document the sample sizes and limitations.
The simulations must cover the complete interacting village, not just isolated NPCs or individual mechanics.
Required simulation scenarios
A. Normal village equilibrium
Run the simulation long enough to evaluate whether:

* Households obtain necessities.
* Workers perform productive activities.
* Businesses function.
* Goods circulate.
* Population remains viable.
* Prices and inventories respond sensibly.
* The economy avoids unexplained collapse or runaway growth.

B. Resource shortages
Simulate shortages of food, timber, ore, tools, and other relevant materials.
Observe:

* Production interruptions.
* Purchasing decisions.
* Substitution behavior.
* Household hardship.
* Recovery mechanisms.
* Trade responses.
* Employment changes.

C. Population and households
Exercise:

* Births and deaths.
* Household formation and dissolution.
* Marriage and courtship.
* Employment changes.
* Aging where implemented.
* Household resources.
* Population sustainability.

Do not invent unsupported mechanics merely to satisfy a test category. Report systems that are not yet implemented.
D. Production and economy
Exercise:

* Farming.
* Mining.
* Forestry.
* Crafting.
* Trade.
* Contracts.
* Business ownership.
* Labor availability.
* Production facilities.
* Inventory movement.
* Prices and wages.

E. Relationships and reputation
Exercise:

* NPC proximity and relationship progression.
* Friendship and rivalry.
* Gifts.
* Household relationships.
* Gossip.
* Witnessing.
* Morality events.
* Good/Bad opinion ledgers.
* Social consequences.

F. Crime and law enforcement
Exercise:

* Theft.
* Assault.
* Murder.
* Multiple serious crimes.
* Witness reporting.
* Guard response.
* Pursuit.
* Loss of line of sight.
* Reinforcements.
* Wanted status.
* Long-term consequences.

Include regression scenarios for the owner's observed guard-pursuit failures.
G. Navigation and daily behavior
Exercise:

* Work schedules.
* Travel between buildings.
* Entering and leaving structures.
* Navigation around obstacles.
* Workplace access.
* Idle behavior.
* Pathfinding failures.
* NPCs becoming stuck.
* Guards searching for suspects.

H. Simulation performance
Measure behavior at different population sizes, including the previously tested 500-person scale.
Track frame-time spikes, simulation processing costs, memory, and major system hotspots.
Preserve established performance requirements.
4. BLACK-BOX FLIGHT RECORDER DATA
The recorder must capture meaningful events and state transitions throughout the entire active village.
It must not be limited to player interactions.
Each recorded event should include, where applicable:

* Simulation timestamp.
* Seed and simulation identifier.
* Event identifier and type.
* Actor and affected entities.
* Household or business association.
* Location.
* Decision or action.
* Relevant preconditions.
* Outcome.
* Resource and currency changes.
* Relationship and morality changes.
* Witness information.
* Related event identifiers.
* Relevant causal links.

Record hourly snapshots sufficient to analyze village-wide trends.
Snapshots should capture appropriate aggregates for:

* Population.
* Household finances.
* Employment.
* Production.
* Consumption.
* Inventory.
* Trade.
* Resource shortages.
* Hunger and welfare.
* Crime.
* Relationships.
* Simulation performance.

Do not duplicate enormous quantities of unchanged state unnecessarily.
Use an efficient recording strategy with documented storage limits.
Recording safety
Preserve the previously established recorder requirements:

* Recorder remains off by default during ordinary gameplay.
* Automated simulation CI explicitly enables recording.
* Private development and playtest recording requires an appropriate explicit setting.
* Recording must not affect simulation RNG.
* Recording must not alter deterministic outcomes.
* Recording must not change NPC decisions or economic behavior.
* Recording must not introduce unbounded storage growth.
* When storage capacity is reached, preserve existing evidence, stop recording, and mark the dataset incomplete.
* An incomplete required CI recording fails the analysis gate.

Do not silently discard data and report a complete simulation.
5. AUTOMATIC EXCEL WORKBOOK
Generate a readable XLSX workbook for every build attempt that reaches the simulation stage.
Use the flight recorder and verified simulation exports as the data source.
The workbook must contain the following analysis sections.
Executive Summary
Show:

* Build and commit.
* Overall pass/fail.
* Simulation duration.
* Seeds and scenarios tested.
* Population sizes.
* Major findings.
* Release-blocking defects.
* Historical regressions.

Population and Households
Show:

* Population changes.
* Births and deaths.
* Household counts.
* Household wealth.
* Employment.
* Hunger and unmet needs.
* Household stability.

Economy
Show:

* Total currency circulation.
* Currency by household and business.
* Production and consumption.
* Trade volumes.
* Prices.
* Wages.
* Resource shortages.
* Inventory changes.
* Business viability.
* Unexplained currency or item creation and loss.

NPC Activity
Show:

* Productive work.
* Travel.
* Idle time.
* Failed actions.
* Navigation problems.
* Unmet needs.
* Schedule compliance.
* Decision outcomes.

Relationships and Morality
Show:

* Relationship progression.
* Gifts and assistance.
* Positive and negative events.
* Good/Bad ledger changes.
* Gossip propagation.
* Witness knowledge.
* Social consequences.

Crime and Justice
Show:

* Crime counts and severity.
* Witnesses.
* Guard alerts.
* Response times.
* Pursuit durations.
* Reinforcement activity.
* Suspect escapes.
* Arrests or deaths where supported.
* Wanted-status persistence.
* Unresolved criminal incidents.

Production and Resources
Show:

* Production by industry.
* Input and output consumption.
* Resource availability.
* Facility limitations.
* Worker effectiveness.
* Contracts.
* Supply shortages.
* Production bottlenecks.

Performance
Show:

* Simulation execution time.
* Memory usage.
* Frame or processing spikes.
* Major system hotspots.
* Population scaling.
* Recorder overhead.

Historical Comparison
Compare the current simulation with the latest accepted baseline and relevant earlier builds.
Use identical seeds and compatible rules where direct comparison is valid.
Distinguish intentional changes from unexpected regressions.
Regression Register
For each detected problem, record:

* Seed.
* Scenario.
* Simulation day and hour.
* Entity or household.
* Event identifier.
* Failure description.
* Severity.
* Expected behavior.
* Actual behavior.
* Reproduction instructions.

Charts
Include readable charts for major trends, such as:

* Population over time.
* Household wealth distribution.
* Currency circulation.
* Production versus consumption.
* Resource shortages.
* Employment and idle time.
* Relationship changes.
* Crime and guard response.
* Simulation performance.
* Changes from previous builds.

Avoid decorative charts that do not provide meaningful analytical value.
6. AUTOMATED RELEASE-BLOCKING RULES
Stop packaging when the simulation identifies:

* Determinism failures.
* Unexplained creation or destruction of currency or inventory.
* Broken save/load integrity.
* Critical simulation crashes.
* Invalid or corrupted flight recorder output.
* Missing required workbook sections.
* Missing required scenario coverage.
* Major unapproved regressions against established baselines.
* Severe unresolved economic integrity defects.
* Critical pathfinding or NPC behavior failures.
* Serious failures of established crime-response requirements.
* Violations of previously approved performance limits.

Do not automatically fail a build merely because a village experiences an economically plausible hardship, death, shortage, or collapse.
Distinguish legitimate emergent simulation outcomes from software defects.
Do not invent numerical thresholds and silently treat them as owner-approved rules.
Use existing approved requirements and documented historical evidence.
Propose new thresholds for owner approval when needed.
Never weaken assertions, modify baselines without justification, or suppress defects simply to pass a build.
7. HISTORICAL BASELINES
Maintain versioned simulation baselines.
Preserve earlier accepted results rather than overwriting them.
Compare:

* Identical deterministic seeds.
* Matching scenarios.
* Matching simulation durations.
* Compatible rules.
* Comparable population sizes.

Record intentional changes separately from unexplained deviations.
When the game design changes, establish a new baseline only after verifying and documenting the difference.
Do not regenerate baseline data simply because the current code fails comparison.
8. BUILD ARTIFACT INTEGRITY
Every authorized build must include:

1. Android APK.
2. Windows playable ZIP.
3. Linux playable ZIP.
4. Excel simulation analysis workbook.
5. Human-readable simulation summary.
6. Verification and integrity evidence.

All must correspond to the same source commit and build number.
Include the simulation run identifier and recorder schema version in the release metadata.
Preserve failed simulation reports as CI artifacts even when packaging is blocked.
Never label a build simulation-verified if the required analysis was skipped or incomplete.
For Build 20 only, preserve the previously authorized disposable Android signing exception.
Do not extend that exception automatically to future builds.
9. CI PERFORMANCE AND DEVELOPMENT EFFICIENCY
This gate must be comprehensive without wasting development resources.

* Use targeted simulations during development.
* Run the complete simulation suite once per release candidate.
* Avoid duplicate full runs for superseded commits.
* Reuse verified results only for exactly matching source, configuration, and simulation inputs.
* Run independent simulations in parallel when safe.
* Avoid unnecessary repeated exports.
* Keep simulation data collection efficient.
* Measure the recorder's own performance overhead.

Do not sacrifice required coverage merely to shorten the pipeline.
10. CURRENT BUILD 20 AND FUTURE BUILDS
First determine whether Build 20 has already been frozen, packaged, or released.
Do not destabilize an already verified Build 20 merely to introduce this pipeline change.
If Build 20 is already in final release validation, preserve its current approved process and implement the permanent gate immediately afterward.
If Build 20 has not entered final release validation, assess whether the existing recorder and analysis capabilities can be safely connected without a major rewrite.
Do not silently delay Build 20 for an extensive new instrumentation project.
Report any unavoidable conflict between immediate Build 20 delivery and this permanent requirement.
The permanent simulation and Excel gate must be active before the next subsequent release.
This is a standing owner authorization to implement the pipeline, not authorization for unrelated gameplay changes or public publication.
11. REQUIRED IMPLEMENTATION REPORT
Provide a concise audit identifying:

1. Existing recorder files and architecture.
2. Implemented versus missing recorder features.
3. Existing simulation test infrastructure.
4. Existing structured data exports.
5. Existing Excel workbook generation, if any.
6. Current CI integration.
7. Missing instrumentation.
8. Proposed integration changes.
9. Tests required.
10. Expected runtime and storage cost.

Then implement the missing components and connect them to the build pipeline.
Do not stop after producing documentation.
Mandatory proof of completion
Demonstrate that:

* A full village simulation actually ran.
* The flight recorder captured its events and hourly snapshots.
* The exported records match verified simulation outcomes.
* The Excel workbook was generated and validated.
* Historical comparisons were performed.
* A deliberately failed simulation gate prevented packaging.
* A passing gate permitted the normal three-platform packaging workflow.
* The recorder did not alter deterministic results.

Report the exact commits, test results, and artifact locations.
FINAL OWNER REQUIREMENT
Every My Medieval Life build must automatically run comprehensive village simulations, capture the results through the black-box flight recorder, analyze those results in an Excel workbook, and pass the established quality gates before generating Android, Windows, or Linux release artifacts.
The owner must not have to request this process manually.
The owner must not have to repeatedly authorize it.
The owner must be able to inspect what the village actually did during simulation, why it happened, and whether the current build is healthier or worse than previous builds.
The flight recorder is not just a debugging idea. It is a permanent part of the game's development and release verification system.
