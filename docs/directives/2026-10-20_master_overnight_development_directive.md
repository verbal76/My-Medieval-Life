# Owner directive, 2026-10-20: master overnight development directive

Saved verbatim from the owner's message. It supersedes the previous overnight instructions wherever they conflict. Register: OVN-01 (and the entries it touches: INFRA-02, REL-15-18, SKIP register).

---

MY MEDIEVAL LIFE

MASTER OVERNIGHT DEVELOPMENT DIRECTIVE

Autonomous Execution, Decision Authority, Build Completion, Testing and Releases

Claude,

This directive supersedes my previous overnight development instructions wherever they conflict.

I want you to operate as the lead development engineer for My Medieval Life while I am away.

You have authority to make routine engineering decisions, solve technical problems, implement approved requirements, run tests, commit and push code, and publish qualifying builds without repeatedly requesting permission.

I am the game designer and product owner. You are responsible for engineering execution.

Do not confuse engineering decisions with game-design decisions.

My goal is to wake up to substantial, verified progress, ideally with Builds 15, 16, and 17 completed and Build 18 underway.

That is an ambitious target, not permission to skip work, weaken requirements, or misrepresent completion.

---

1. IMMEDIATE DECISION: GITHUB ACTIONS

I approve option 1 from your question.

Add ".github/workflows/long-sims.yml" to the repository's "main" branch.

Authorization is limited to the workflow file and any strictly necessary, independently safe workflow configuration.

Do not merge unfinished gameplay code into "main".

Do not alter unrelated files on "main".

Ensure the workflow can execute the requested staging revision rather than accidentally testing outdated code from "main".

Record the actual commit SHA used for every simulation.

Validate the workflow with the previously approved 10-day deterministic comparison.

If fingerprints differ, investigate and correct the problem before treating remote simulations as authoritative.

After validation, use GitHub Actions for unattended long-duration simulations.

Do not publish releases or game artifacts through this testing workflow.

This is an approved infrastructure operation. You do not need to ask me again.

---

2. YOUR DECISION-MAKING AUTHORITY

You are authorized to make engineering decisions necessary to fulfill already approved requirements.

Decisions you should make independently

You may decide:

- How to structure code and classes.
- Which algorithms and data structures to use.
- How to fix bugs.
- How to implement approved mechanics.
- How to improve performance without changing gameplay behavior.
- How to organize tests.
- How to isolate test processes.
- How to configure CI workflows.
- How to resolve routine Git conflicts.
- How to manage WIP and staging branches.
- How to structure internal save-data migrations while preserving compatibility.
- How to implement logging, diagnostics, and profiling.
- How to address technical debt.
- How to schedule independent development tasks.
- How to fix nonfunctional UI implementation details.
- How to recover from failed tests or interrupted development environments.
- Which approved task to work on next when another task is blocked.

You do not need to present multiple technical options and wait for me to choose one when the decision does not materially change the game's intended behavior.

Research the alternatives, select the best defensible solution, implement it, test it, and document the result.

Decisions that still require my approval

You may not independently decide:

- New gameplay mechanics outside approved requirements.
- Fundamental changes to the game's economy.
- Unlimited or artificially replenished resources.
- Changes to NPC autonomy or fundamental decision-making principles.
- New social, political, or relationship rules that have not been approved.
- Changes to progression, survival, or difficulty philosophy.
- Major architectural changes that materially alter the player experience.
- Removing mandatory features from a build.
- Changing the approved roadmap.
- Spending money or activating paid services.
- Publishing publicly accessible test material that is designated private.
- Making irreversible or destructive repository changes without an approved recovery path.

If one of these decisions is necessary, document it as an owner decision and continue other approved work.

Do not choose an unapproved design merely because I am unavailable.

Guiding rule

If the decision concerns HOW to implement approved behavior, you normally own it.

If the decision concerns WHAT the game should be or HOW it should fundamentally behave, I own it.

---

3. BUILD PROGRESSION IS STRICTLY SEQUENTIAL

The approved roadmap is:

Build 15 → Build 16 → Build 17 → Build 18

Do not skip Build 16 or Build 17 to reach Build 18.

Do not declare a build complete simply because the next build's work is more interesting.

Build 15 — Stabilization

Complete the approved stabilization requirements, including:

- Housing construction and completion.
- Persistent housing goals.
- Economic recovery from missing work tools.
- Bed sharing.
- Sleeping lofts.
- Existing-house expansion requirements.
- Household ownership and occupancy integrity.
- Required regression tests.
- Long-duration simulation validation.
- Save/load compatibility.
- Resource and currency accounting.

Resolve critical problems before declaring Build 15 complete.

Build 16 — Long-term equilibrium

Complete all approved Build 16 requirements from the authoritative project register.

This includes the approved long-term population, household, economic, and sustainability work.

Do not replace the actual requirements with a generic simulation test.

Implement, integrate, and validate the full approved Build 16 scope.

Build 17 — Mining and industrial development

Complete the approved mining and industrial systems according to their existing specifications.

This includes the approved finite-resource extraction, prospecting, quarrying, mining, production, and associated economic interactions.

Do not substitute unlimited resource generation for functioning industrial systems.

Do not mark Build 17 complete with only placeholder mining mechanics.

Build 18 — Settlement advancement and regional economy

Begin Build 18 only after Builds 15–17 satisfy their completion requirements.

Follow the approved settlement advancement and regional economy specifications.

Do not invent unresolved design decisions.

You may prepare independent infrastructure or documentation for later builds while earlier work is underway, but you may not claim a later milestone has been completed before its predecessors.

---

4. WHAT COUNTS AS A COMPLETED BUILD

A build is complete only when:

1. Its mandatory approved requirements are implemented.
2. The required systems are integrated into actual gameplay.
3. Applicable automated tests pass.
4. Required simulation and integrity checks pass.
5. There are no known game-breaking defects.
6. There are no unexplained resource or currency leaks.
7. Required save/load behavior works.
8. Any deferred items meet the strict deferral policy below.
9. The tested source revision is committed and pushed.
10. The appropriate release artifacts have been successfully produced and validated.

A successful code commit is not a completed build.

A passing unit test is not a completed build.

A successful simulation is not automatically a completed build.

A distributable artifact is not automatically a working game.

All applicable requirements must be satisfied.

---

5. NONCRITICAL BLOCKERS AND SKIPPED ITEMS

I do not want one minor issue consuming the entire night.

If an individual issue is noncritical, isolated, and safely deferrable, you may record it and continue.

Maintain a permanent skipped-items register containing:

- Build number.
- Requirement or issue ID.
- Description.
- Severity.
- Reason for deferral.
- Affected functionality.
- Workaround, if any.
- Recommended correction.
- Target for reconsideration.

Deferrable examples

- Cosmetic imperfections.
- Minor animation glitches.
- Nonessential presentation polish.
- Optional convenience features.
- Isolated low-impact defects with a verified safe workaround.

Not deferrable

- Missing mandatory gameplay systems.
- Crashes.
- Save corruption.
- Broken essential NPC behavior.
- Serious economic deadlocks.
- Invalid resource or currency accounting.
- Broken core construction or survival systems.
- Failed mandatory simulation integrity checks.
- Regressions that invalidate the build's intended functionality.

Do not disable tests to make them green.

Do not silently reclassify mandatory requirements as optional.

Do not defer a major system just to advance the build number.

Skip minor obstacles, not essential development.

If a mandatory blocker prevents a build's completion, keep that milestone open and continue independent approved work. Do not mislabel it as finished.

---

6. TESTING AND QUALITY CONTROL

Continue using the existing test suites and simulation harness.

For every meaningful gameplay change:

- Run relevant focused tests.
- Run the required broader regression tests.
- Validate affected save/load behavior.
- Check economic and resource integrity.
- Confirm deterministic behavior where required.

Do not run unnecessary duplicate simulations.

Do not launch concurrent processes that share save data or output paths.

Use isolated environments for parallel simulation seeds.

For optimization work, compare equivalent state fingerprints and resource ledgers before and after the change.

Do not change simulation step size or skip gameplay systems merely to make tests faster.

Long-duration simulations

Use the GitHub Actions workflow after deterministic validation.

Preserve:

- Seed.
- Commit SHA.
- Duration.
- Runtime.
- Logs.
- State fingerprints.
- Population and household results.
- Housing completion results.
- Resource and currency ledgers.

If a long-running test fails because of infrastructure, distinguish that from a gameplay failure.

Fix the infrastructure problem where practical and continue.

---

7. DEVELOPMENT MUST CONTINUE WHILE TESTS RUN

Do not sit idle waiting for a 365-day simulation to finish.

While simulations execute, work on independent approved tasks that cannot invalidate the running test.

If one task is blocked by an owner decision, move to another approved task.

If one branch requires extended testing, continue independent work on an appropriate separate branch.

Preserve work frequently.

Avoid excessive parallel agents or unnecessary resource consumption.

Do not waste development time repeatedly asking for authorization you already have.

---

8. GITHUB IS THE SOURCE OF TRUTH

All meaningful completed development must be preserved remotely.

Use the established branch strategy:

- WIP branches for active development.
- "staging/my-medieval-life" for validated integration.
- "main" for approved stable releases and infrastructure changes.

Do not use uncommitted local files as the only copy of completed work.

Before promoting changes:

1. Verify the intended source revision.
2. Run the required tests.
3. Resolve integration conflicts.
4. Commit and push.
5. Verify the remote SHA.
6. Record the promotion in the development ledger.

Do not force-push, delete protected branches, or overwrite unrelated work.

Routine non-destructive Git operations are within your engineering authority.

---

9. BUILD AND RELEASE AUTHORIZATION

I explicitly authorize you to create and publish the approved game builds overnight when all applicable release gates pass.

Use the project's established platform targets, artifact naming, and distribution procedures.

Verify that produced artifacts correspond to the tested source revision.

Do not publish an artifact that fails its required checks.

Do not publicly distribute private test builds.

Do not confuse a GitHub Actions simulation artifact with a game release.

If a release cannot be produced safely, record the reason and continue other approved development.

You do not need to wake me up merely to publish a build that meets these conditions.

---

10. PERFORMANCE AND RELIABILITY

The independent audit and subsequent measurements established that current simulations run approximately 4–5 times slower than historical benchmarks.

The slowdown is real, but its causes have not yet been fully isolated.

Profile actual bottlenecks before optimizing.

Investigate:

- Repeated population-wide NPC searches.
- Wildlife linear searches.
- Population scaling.
- Pathfinding.
- Repeated configuration lookups.
- World update costs.

Preserve deterministic gameplay behavior.

Improve performance where evidence supports the change.

The simulation infrastructure must be reliable enough for unattended testing.

Do not depend on an idle development container remaining alive when a validated GitHub Actions workflow can run the same test reliably.

---

11. PROJECT MEMORY AND DOCUMENTATION

Maintain the authoritative project memory, development ledger, requirements register, and current development state.

Every completed feature must have an accurate recorded status.

Every skipped item must remain traceable.

Every unresolved owner decision must remain open until answered.

Every build promotion must record its source revision and validation results.

Do not rewrite project history to make progress appear faster.

Do not allow a new development session to lose previously approved requirements.

---

12. WHEN TO ASK ME A QUESTION

Only interrupt autonomous development for a decision that genuinely requires the product owner.

Before asking:

1. Check the project memory.
2. Check existing specifications.
3. Check the requirements register.
4. Check previous owner decisions.
5. Determine whether this is actually an engineering decision within your authority.

If it is an engineering decision, make it.

If it is a product-design decision, document it and move to other approved work.

If the decision involves external costs, irreversible changes, security exposure, or a fundamental gameplay change, obtain approval.

Do not manufacture decision points for routine implementation details.

---

13. MORNING HANDOFF REPORT

When I return, I expect:

Build status

- Highest build fully completed.
- Highest build currently in development.
- Builds published.
- Builds blocked and why.

Development results

- Features completed.
- Tests executed and results.
- Simulation outcomes.
- Bugs fixed.
- Performance improvements.

GitHub

- Branches updated.
- Verified commit hashes.
- CI results.
- Build and release links.

Outstanding work

- Skipped noncritical items.
- Unresolved owner decisions.
- Remaining mandatory requirements.
- Next planned development steps.

Use accurate status labels:

IMPLEMENTED, TESTED, STAGED, BUILT, RELEASED, BLOCKED, or DEFERRED.

Do not claim success for work that has not passed its required validation.

---

14. FINAL INSTRUCTIONS

You have my permission to operate autonomously as the lead development engineer within the approved design.

Make routine technical decisions yourself.

Do not wait for me to approve ordinary implementation choices.

Do not stop because of one minor issue.

Do not skip mandatory systems or entire builds.

Do not sacrifice deterministic behavior, economic integrity, or gameplay quality to meet a deadline.

Complete Build 15, then Build 16, then Build 17, then proceed to Build 18.

Publish qualifying builds as they pass their required gates.

If a milestone is blocked, preserve its status honestly and continue other approved work.

I want to wake up to working software and measurable progress, not a list of routine technical questions waiting for my approval.

Proceed.
