# EXPANSION 20 FINAL VALIDATION, FLIGHT RECORDER MODERNIZATION, AND AUTOMATIC RELEASE (owner directive, 2026-10-27)

Received in the session of 2026-10-27, verbatim:

OWNER DIRECTIVE — EXPANSION 20 FINAL VALIDATION, FLIGHT RECORDER MODERNIZATION, AND AUTOMATIC RELEASE

This directive supersedes my earlier instruction requiring another owner authorization before releasing Expansion 20.

I am explicitly authorizing the completion, validation, packaging, and release of Expansion 20 once the requirements below are satisfied.

DO NOT STOP AND WAIT FOR MY FINAL RELEASE APPROVAL.

Your responsibility is to complete the integration, thoroughly test the resulting game, correct genuine defects, verify the corrections, and produce the three-platform release.

However, I want a much more comprehensive final simulation process than simply running our existing tests.

We have made significant changes throughout Expansions 18, 19, and 20.

Our flight recorder, black-box simulations, diagnostics, and reporting must be brought up to date with those changes before release.

I do not want newly introduced systems escaping testing simply because our original simulation infrastructure predates their implementation.

---

PHASE 1 — COMPLETE THE EXISTING INTEGRATION

Continue from the current Expansion 20 integration state.

Current reference points:

- Verified aspirations baseline: "3601211"
- Multiplayer integration commit: "87b69ab"
- Integration branch: "wip/x20-final"
- Existing verified baseline branch: "wip/expansion20"

The combined validation of "87b69ab" was running when this directive was issued.

Do not interrupt or redundantly restart that validation.

Review its results.

If it passes, proceed.

If it reveals defects, correct those defects and rerun only the tests whose evidence was invalidated.

Preserve the verified baseline until the replacement has passed its required checks.

Do not overwrite unrelated owner commits.

Once the integration is validated, complete any remaining approved fixes that belong to the Expansion 20 release scope.

Do not silently add unapproved future-expansion features.

---

PHASE 2 — MODERNIZE THE FLIGHT RECORDER AND BLACK-BOX SIMULATIONS

This is a mandatory part of release preparation.

Our existing flight recorder and simulation gate must be reviewed against the actual functionality implemented during the last three expansions.

Specifically:

EXPANSION 18
EXPANSION 19
EXPANSION 20

Do not assume that passing the older simulation scenarios means these newer systems have been adequately tested.

2.1 Full simulation coverage audit

Inspect the actual code, approved design documents, decision register, feature switches, and existing test infrastructure.

Identify every meaningful gameplay system introduced or materially changed in Expansions 18–20.

Build a coverage matrix showing:

1. Feature or system.
2. Expansion in which it was introduced.
3. Current implementation status.
4. Relevant owner-approved behavior.
5. Existing automated tests.
6. Existing simulation coverage.
7. Existing flight-recorder coverage.
8. Missing coverage.
9. Required additional verification.

Distinguish clearly between:

- Implemented and active systems.
- Implemented systems behind feature switches.
- Partially implemented systems.
- Approved but not yet implemented systems.
- Future expansion work.

Do not mistake a documented design for an implemented feature.

Do not introduce future functionality merely to make the coverage matrix complete.

2.2 Expansion 18 coverage

Review and exercise the implemented settlement, production, and regional economic systems.

Include relevant scenarios for:

- Settlement development and capability levels.
- Industry specialization.
- Skills and tools affecting productivity.
- Resource extraction and depletion.
- Production chains.
- Mining and forestry sustainability.
- Farming and food production.
- Regional supply and demand.
- Settlement inventories.
- Trade routes.
- Transportation and cartage.
- Merchant competition.
- Courier services.
- Contract formation and fulfillment.
- Payments and ownership transfers.
- Currency and inventory conservation.
- Save/load continuity.

The recorder must make it possible to identify where a transaction or production chain failed.

Do not merely report that the village economy changed.

Record sufficient information to determine why.

2.3 Expansion 19 coverage

Review the complete implemented NPC judgment, personality, memory, and relationship systems.

Include:

- Individual opinions.
- Personality differences.
- Positive and negative judgments.
- Trust and reputation.
- Friendship.
- Family relationships.
- Family-first decision priorities.
- Gossip.
- Rumors and misinformation.
- Memory formation.
- Memory decay.
- Permanent memories where required.
- Corrections to false information.
- Social consequences of actions.
- Negotiation and trade preferences.
- NPC reactions to crimes.
- Criminal reputation.
- Decision weighting.
- NPC choices that differ because of personality or prior experience.
- Save/load of memory and relationships.

Pay particular attention to interactions between systems.

For example:

A villager witnesses a theft.

That event affects the villager's opinion.

The information spreads through gossip.

Another villager receives that information and incorporates it into their own judgment.

Later, that judgment influences a transaction, employment decision, or social interaction.

I want the simulation to verify that the complete chain works where the relevant features are implemented.

The recorder should allow us to trace the event, participants, information propagation, and resulting decisions.

2.4 Expansion 20 coverage

Review everything implemented or materially changed in Expansion 20.

Include:

- NPC aspirations.
- All six approved aspiration domains.
- Changing personal priorities.
- Survival pressure.
- Household-specific hardship.
- Family-first priorities.
- Individual proposal preferences.
- Relationships and courtship.
- The approved player/NPC equality rules.
- Living Economy foundations that are actually implemented.
- Economic needs.
- Offers and reservations.
- Trade knowledge.
- Contract links.
- Inventory and currency integrity.
- NPC judgment integration.
- Multiplayer synchronization.
- Host-owned world behavior.
- Multiplayer player interaction.
- Save/load behavior.
- Network message delivery.
- The recent approved bandit and chisel fixes, once integrated.

Do not invent gameplay functionality for unfinished Living Economy stages.

Test the implemented systems, including their disabled/default behavior and their enabled behavior where the feature switches permit it.

A simulation that leaves a new system disabled does not count as exercising that system.

---

PHASE 3 — UPDATE FLIGHT RECORDER INSTRUMENTATION

Inspect the existing recorder architecture:

- "tools/sim_suite.py"
- "tools/recorder_archive.py"
- "tools/sim_gate.py"
- "game/scripts/core/recorder/"
- Relevant simulation harnesses and reporting tools.

Preserve the existing recorder architecture wherever practical.

Extend it where necessary.

I want the recorder capable of capturing the meaningful interactions introduced over the last three expansions.

At minimum, ensure appropriate visibility into:

NPC behavior

- Decisions made.
- Available alternatives.
- Reasons and weighting factors.
- Relevant memories and opinions.
- Aspiration influences.
- Resulting actions.
- Consequences.

Economic behavior

- Resource production.
- Consumption.
- Inventory transfers.
- Currency transfers.
- Trades.
- Contracts.
- Failed transactions.
- Unmet needs.
- Shortages.
- Resource depletion.
- Economic recovery or collapse.

Social behavior

- Relationships.
- Reputation changes.
- Gossip propagation.
- Crimes.
- Family obligations.
- Courtship decisions.
- NPC aspirations.
- Consequences of important events.

World behavior

- Population changes.
- Household formation.
- Deaths.
- Births.
- Migration.
- Settlement changes.
- Navigation failures.
- Stuck NPCs.
- Save/load transitions.

Multiplayer behavior

- Host state.
- Guest state.
- Player actions.
- World synchronization.
- Relevant network events.
- Disconnects and reconnects.
- State differences between participants.
- World-time behavior.

Do not record unnecessary repetitive data that makes the recorder unusably large.

Use bounded, efficient instrumentation.

Preserve hourly snapshots and independent archive verification.

Every important recorded event should have sufficient context to reconstruct what occurred.

Where practical, record:

- Simulation seed.
- Source commit.
- Simulation time.
- Entity identifiers.
- Event type.
- Relevant state before and after.
- Decision factors.
- Result.
- Associated related events.

Avoid unnecessary duplication.

Recorder instrumentation must not change simulation behavior.

---

PHASE 4 — RUN COMPREHENSIVE BLACK-BOX SIMULATIONS

Once implementation and recorder coverage are complete, execute a controlled set of simulation campaigns.

These are not simply unit tests.

I want the actual integrated village systems operating together long enough for emergent defects to become visible.

Use the existing simulation infrastructure and extend its scenarios as necessary.

4.1 Normal village simulation

Run the village with the approved active systems and normal conditions.

Observe:

- Economic stability.
- Food availability.
- Production.
- Population changes.
- Relationships.
- Aspirations.
- Trade.
- Crime.
- Daily routines.
- NPC decision-making.
- Settlement behavior.

Look for contradictions, deadlocks, missing actions, and unexpected behavior.

4.2 Economic stress simulation

Introduce legitimate shortages and disruptions.

Examples:

- Reduced food supply.
- Missing production workers.
- Interrupted trade.
- Resource depletion.
- Failed contracts.
- Household poverty.
- Missing essential materials.

Verify that villagers respond according to the actual approved systems.

NPCs may make poor decisions.

Households may fail.

Businesses may collapse.

The simulation must not invent resources, lose accounting integrity, or enter invalid states.

4.3 Social and judgment simulation

Exercise the interconnected social systems.

Generate circumstances involving:

- Theft.
- Violence.
- Rumors.
- Friendship.
- Hostility.
- Family responsibilities.
- Marriage proposals.
- Reputation changes.
- Economic dependency.
- Conflicting personal ambitions.

Verify that decisions reflect the approved weighting and personality systems rather than hardcoded universal behavior.

Different NPCs should be capable of responding differently to similar circumstances.

Do not treat a reasonable NPC refusal, social conflict, or unhappy outcome as a defect merely because it is unfavorable.

4.4 Long-duration simulation

Run a limited number of extended simulations to identify defects that only become visible over time.

Use appropriate durations based on the systems being examined.

Include longer runs where necessary to observe:

- Resource sustainability.
- Economic accumulation or depletion.
- NPC memory decay.
- Relationship changes.
- Household evolution.
- Settlement development.
- Long-term contract behavior.
- Population stability or decline.

Do not automatically launch a huge campaign of year-long simulations.

Use a few deliberately selected seeds and durations that provide meaningful coverage.

Reuse existing valid results where possible.

4.5 Multiplayer simulation

Multiplayer requires its own integration scenarios.

Our design supports three to four players.

Verify both:

- One host and two guests.
- One host and three guests.

Include:

- World synchronization.
- Concurrent player actions.
- Player interaction targeting.
- Network message delivery.
- Save/load continuity.
- Host disconnect and reconnect.
- Guest disconnect and reconnect.
- Time stopping when the host is absent.
- Inventory and currency integrity.
- Consistency between host and guest world states.

Exercise available keyboard, mouse, controller, and touch input tests.

Preserve the approved host-owned architecture.

Do not invent new multiplayer design decisions.

Use available automated network tests to establish everything that can be verified without physical devices.

Document physical-device testing that remains necessary.

---

PHASE 5 — INDEPENDENT BLACK-BOX ANALYSIS

This is extremely important.

Do not rely solely on the simulation reporting that it passed.

Analyze the actual recorder output.

Use the independent archive verifier.

Verify:

1. Every required simulation completed.
2. Recorder archives are complete.
3. No recorded events are missing or duplicated.
4. Hourly snapshots are consistent.
5. State transitions are valid.
6. Currency conservation holds.
7. Item conservation holds.
8. Save/load does not corrupt data.
9. Deterministic scenarios reproduce the same results.
10. Recorder-enabled and recorder-disabled simulations produce identical gameplay results.
11. Network participants maintain valid synchronized state.
12. Required systems were actually exercised.
13. No unexpected script errors occurred.
14. No required simulation silently skipped a feature.
15. No established owner-approved invariant was violated.

A test that never exercises the intended system must not be reported as evidence that the system works.

Where the recorder exposes suspicious behavior, trace it back through the relevant events and decisions.

Identify genuine defects rather than simply reporting unusual outcomes.

Remember the existing owner rule:

A village is allowed to fail. The simulation is not.

NPC death, economic hardship, business failure, resource shortages, and village collapse are not automatically programming defects.

Unaccounted currency, duplicated goods, corrupted saves, impossible state transitions, broken decisions, and invalid synchronization are defects.

---

PHASE 6 — CORRECT DEFECTS FOUND

You have my authorization to fix genuine implementation defects discovered during this validation.

Do not stop after generating a list of obvious bugs.

Fix them.

Examples include:

- Broken state transitions.
- Missing decision hooks.
- Incorrect event handling.
- Lost or duplicated transactions.
- Invalid NPC behavior caused by programming errors.
- Incorrect memory or aspiration updates.
- Broken contract accounting.
- Multiplayer synchronization defects.
- Save corruption.
- Broken interaction targeting.
- Missing recorder instrumentation.
- Incorrect feature-switch behavior.
- Determinism failures.
- Script errors and crashes.

For each defect:

1. Identify the root cause.
2. Record a reproducible example.
3. Correct the underlying problem.
4. Add a focused regression test.
5. Run the affected validation.
6. Confirm the original defect no longer occurs.
7. Preserve evidence of the correction.

Do not weaken tests to hide failures.

Do not rewrite accepted simulation baselines merely to obtain a passing result.

If an approved change legitimately alters a baseline, document why and independently validate the new expected state before updating it.

Do not perform arbitrary economic rebalancing or introduce new gameplay rules.

If a finding requires a new owner design decision rather than a technical correction, preserve the existing approved behavior. Report the unresolved issue and treat it as a release blocker only if it genuinely prevents a safe, valid release.

---

PHASE 7 — FINAL CLEAN SIMULATION PASS

After correcting the defects, perform the final necessary validation against the exact source commit intended for release.

This must include:

- Relevant automated regression suites.
- Required multiplayer validation.
- Flight-recorder integrity.
- Black-box simulation coverage.
- Economic conservation.
- Determinism.
- Save/load integrity.
- Script-error checks.
- Required performance checks.
- Coverage verification.

Do not rerun identical comprehensive simulations after unrelated documentation changes.

Do not rerun every test after every small fix.

Use focused tests during corrections.

When the integrated source is stable, execute the final required simulation gate.

The final gate must represent the actual source being packaged.

Do not declare the system clean if important scenarios did not run or failed without investigation.

Once all mandatory checks pass, proceed directly to release.

---

PHASE 8 — AUTOMATIC THREE-PLATFORM RELEASE

THIS MESSAGE IS EXPLICIT OWNER AUTHORIZATION TO PROCEED WITH THE EXPANSION 20 BUILD AND RELEASE ONCE THE REQUIRED VALIDATION IS CLEAN.

Do not ask me for another routine go/no-go decision.

Produce all three packages from the same verified source commit:

1. ANDROID

- Signed APK using the established release signing identity.
- Preserve update compatibility.
- Verify APK integrity and required permissions.
- Preserve Android compatibility requirements.

2. WINDOWS

- Complete playable Windows package.
- Correct executable and required game resources.
- Functional input and startup behavior.

3. LINUX

- Complete playable Linux package.
- Correct executable and required game resources.
- Functional input and startup behavior.

Use the existing GitHub Actions release workflow and established release channel.

Do not silently change a private testing release into a public distribution or bypass existing security protections. This directive authorizes the build and release process, not a change in repository visibility or signing identity.

Where the workflow requires an interactive security approval that cannot be completed automatically, preserve that gate and clearly identify it.

Verify all three exports.

Perform necessary packaging and startup smoke tests.

Do not hold an otherwise validated test release merely because physical-device testing cannot be performed in CI. Clearly identify which device combinations remain unverified.

Publish the three packages together using the existing authorized release visibility.

Do not create three independent releases.

All packages must share:

- Source commit.
- Build number.
- Game version.
- Relevant simulation evidence.
- Release notes.

---

PHASE 9 — FINAL REPORT

After releasing, provide me with a consolidated report.

Include:

A. Release information

- Build number.
- Source commit.
- GitHub release location.
- Windows package.
- Linux package.
- Android APK.
- Release status.

B. Validation

- Automated test results.
- Multiplayer test results.
- Simulation scenarios.
- Seeds and durations.
- Recorder integrity.
- Determinism.
- Conservation checks.
- Save/load checks.
- Performance observations.

C. Expansion coverage

Provide the coverage matrix for Expansions 18, 19, and 20.

Clearly show what was exercised and what remains outside implemented scope.

D. Defects

List the defects discovered.

For each, include:

- Root cause.
- Correction.
- Relevant commit.
- Verification.
- Final status.

E. Simulation findings

Identify significant observations regarding:

- Village economy.
- Population.
- NPC behavior.
- Relationships.
- Aspirations.
- Crime.
- Resources.
- Settlement development.
- Multiplayer.

Distinguish actual programming defects from legitimate simulation outcomes.

F. Remaining limitations

Identify any nonblocking issues or physical-device checks that remain.

Do not represent unperformed testing as successful testing.

---

DEVELOPMENT EFFICIENCY RULE

I do not want uncontrolled cycles of redundant testing.

Our development resources and time matter.

Use this sequence:

1. Finish integration.
2. Audit simulation coverage.
3. Update recorder and scenarios.
4. Run the focused new tests.
5. Execute the expanded black-box simulations.
6. Investigate findings.
7. Fix genuine defects.
8. Rerun affected checks.
9. Perform the final clean validation.
10. Build and publish the three packages.

Do not repeatedly rerun the full campaign merely for reassurance.

Do not run overlapping agents that independently perform the same expensive simulations.

Keep simulation evidence tied to exact source commits.

Preserve all useful recorder artifacts and reports.

Use GitHub Actions runners for longer simulation campaigns where appropriate.

Do not consume development time repeatedly reproducing results already established by valid evidence.

---

FINAL OWNER INSTRUCTION

Expansion 20 is now authorized to proceed through final validation and release without another routine owner approval.

I want the flight recorder and black-box simulation system modernized to account for everything actually implemented across Expansions 18, 19, and 20.

I want those systems tested together.

I want obvious programming defects discovered and corrected.

I want the corrections validated.

I want the final simulation gate clean.

And when the build is ready, I want the Windows, Linux, and Android packages released together.

DO NOT STOP AFTER TESTING TO ASK WHETHER YOU SHOULD BUILD.

DO NOT STOP AFTER BUILDING TO ASK WHETHER YOU SHOULD RELEASE.

Proceed automatically when all technical requirements and applicable release protections have been satisfied.

If a genuine unresolved blocker remains, do not misrepresent the release as clean or bypass the blocker. Report the specific issue and the evidence.

Otherwise, complete the work and deliver the release.

The final deliverable is a tested, stable, three-platform Expansion 20 release—not another report telling me that development is ready to begin.
