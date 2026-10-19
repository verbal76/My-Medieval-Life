# Build 14 readiness, historical requirements recovery and permanent backlog preservation

Owner directive, received 2026-10-19T19:09:08.297Z (verbatim).

---

MY MEDIEVAL LIFE
MASTER DIRECTIVE — BUILD 14 READINESS, HISTORICAL REQUIREMENTS RECOVERY, AND PERMANENT BACKLOG PRESERVATION
OWNER AUTHORIZATION AND INTENT
The recent Build 14 audit identified:

* 80 outstanding requirements.
* 109 items recorded as complete and verified through automated testing, without comprehensive real-device verification.
* 17 partially implemented items.
* 26 approved items not yet started.
* 18 blocked items.
* 2 deferred items.
* 13 items awaiting real-device or controller verification.
* 2 items with unknown status.
* 31 previously approved requests missing from the active backlog.
* 3 additional items whose statuses were inaccurate.

The audit report is `docs/release/BUILD_14_OPEN_ITEMS_AUDIT.md`, recorded on staging at `ec3bd0e`.
The multiplayer prototype is isolated on `wip/multiplayer` at `d18d7d1`.
These are the reported baseline findings. Verify them against the current repository rather than treating them as permanently accurate.
The discovery of 31 missing requests reveals a serious weakness in project continuity.
I want every approved requirement to survive until it is completed and verified, explicitly superseded, or explicitly canceled by me.
At the same time, I do not want development interrupted unnecessarily.
This directive combines two objectives:

1. Complete the short list needed to make Build 14 ready for my approval.
2. Implement a permanent, automated requirements preservation and recovery system so that no approved feature, fix, or design commitment silently disappears.

Proceed with both objectives in parallel wherever practical.
Do not create or publish Build 14 without my explicit approval.
Do not merge multiplayer into staging without my explicit approval.
Do not stop productive development merely to reorganize documentation.
PART I — IMMEDIATE BUILD 14 READINESS
1. Complete the economy simulations
Finish the ongoing 100-day economy simulations.
Record:

* Starting conditions.
* Simulation duration.
* Seed or reproducibility parameters.
* Total currency.
* Currency creation and removal.
* Household wealth distribution.
* Employment and unemployment.
* Business profitability.
* Trade activity.
* Resource availability.
* Food production and consumption.
* Population stability.
* Economic shortages.
* Unexpected accumulation or depletion.
* Any detected regressions.

Investigate and correct genuine regressions.
Do not conceal economic failures by changing simulation parameters merely to obtain passing results.
Continue the 365-day simulations as a separate workstream where practical.
Compare results against previous measurements, but do not assume older Build 7 measurements remain representative.
2. Evaluate unauthorized economy changes
Two economy changes were previously implemented without explicit owner approval:

1. A manor reserve that allows earlier day-labor employment.
2. A limit on how much money visiting caravans introduce.

Do not permanently approve or reverse either change without presenting evidence.
Where practical, compare four configurations:

* Both changes disabled.
* Manor reserve enabled only.
* Caravan money limit enabled only.
* Both changes enabled.

Use comparable seeds and simulation conditions.
Measure effects on:

* Employment.
* Household survival.
* Economic circulation.
* Currency supply.
* Trade.
* Prices.
* Business activity.
* Economic stability.

If full comparison runs are prohibitively expensive, perform a smaller controlled comparison and clearly state its limitations.
Keep the current implementation stable while testing.
Return a recommendation for each change.
The owner retains final approval.
3. Preserve finite resource deposits
Iron ore and coal currently run out around game day 10.
Do not automatically respawn depleted deposits without approval.
Investigate sustainable alternatives consistent with the existing finite-resource economy:

* Discoverable new deposits.
* Prospecting.
* Mining expansion.
* Imports through trade.
* NPC adaptation to shortages.
* Changes in production and pricing.
* Material substitution where appropriate.

Determine whether day-10 depletion is an intended economic constraint, an implementation problem, or a serious gameplay bottleneck.
Document the alternatives and their consequences.
Do not silently change the fundamental resource model.
4. Finish Build 14 tester notes
Prepare tester documentation covering:

* Current playable features.
* Controls.
* Known limitations.
* Known defects.
* Save compatibility.
* Android installation.
* Controller support.
* Cart functionality.
* Economy limitations.
* Combat limitations.
* Missing audio.
* Temporary artwork.
* Unverified platform behavior.
* Any important gameplay restrictions.

Clearly distinguish tested behavior from expected behavior.
5. Establish the next clean build boundary
Evaluate staging at `ec3bd0e` and any subsequent verified commits.
Identify the best stable commit for a single-player Build 14 checkpoint.
A suitable build must have:

* Successful startup.
* No known critical regression preventing meaningful playtesting.
* Passing relevant automated tests.
* Functional save/load behavior.
* A coherent single-player gameplay loop.
* Documented playtest limitations.
* No unintended multiplayer integration.

A feature being incomplete does not automatically make it a build blocker.
Do not hold Build 14 hostage to long-term systems such as generational politics, multiplayer, or future wildlife improvements.
Finish the short list, prepare the checkpoint, and request owner approval.
Do not export, publish, or distribute Build 14 until approved.
PART II — PERMANENT REQUIREMENTS PRESERVATION
6. Establish the governing principle
Every approved owner request is a continuing project obligation.
It must remain discoverable and actionable until one of three conditions is met:

1. Completed and verified against its acceptance criteria.
2. Explicitly superseded by another approved requirement.
3. Explicitly canceled by the owner.

No requirement may disappear because:

* A Claude session ends.
* Context is compacted.
* A subagent finishes.
* Development moves to another build.
* A feature is postponed.
* A task becomes difficult.
* A branch is abandoned.
* A new feature takes priority.
* A document is reorganized.
* A release is completed.
* Automated tests pass without required gameplay verification.

The repository must preserve the project's commitments independently of an agent's conversational memory.
7. Maintain one authoritative register
Extend the existing authoritative requirements register.
Do not create a competing backlog.
Every requirement must have:

* Permanent unique ID.
* Requirement title.
* Original owner wording where available.
* Normalized requirement description.
* Source reference.
* Approval evidence.
* Acceptance criteria.
* Current lifecycle status.
* Implementation evidence.
* Test evidence.
* Playtest requirements.
* Relevant branch and commit.
* Dependencies.
* Blockers.
* Related design rules.
* Related Interlocking Systems Manifest entries.
* In-game Wiki references where applicable.
* Next action.
* Priority.
* Historical disposition.

Never recycle IDs.
Never delete historical requirement records simply to reduce the apparent backlog.
8. Establish a consistent lifecycle
Use these lifecycle states:

* APPROVED — NOT STARTED
* ACTIVE DEVELOPMENT
* PARTIALLY IMPLEMENTED
* IMPLEMENTED — TESTING REQUIRED
* AUTOMATED TESTS PASSED — PLAYTEST REQUIRED
* BLOCKED
* DEFERRED
* COMPLETE AND VERIFIED
* SUPERSEDED
* CANCELED BY OWNER
* UNKNOWN — INVESTIGATION REQUIRED

Maintain separate attributes for blockers, branches, verification requirements, and assigned workstreams.
A requirement may be partially implemented and blocked without appearing twice in the outstanding total.
Produce mutually exclusive lifecycle counts that reconcile mathematically.
Preserve a distinction between automated verification and real-device testing.
9. Preserve partial requirements
Do not mark a broad feature complete because one portion works.
For example, a cart system is not fully complete if required hauling, ownership, persistence, inventory interaction, or controls remain unfinished.
Maintain the original parent requirement.
Break implementation into child tasks where useful.
Do not close the parent until its approved acceptance criteria have been met or explicitly revised by the owner.
Apply this approach to all major interconnected systems.
10. Distinguish ideas from approvals
Maintain separate classifications for:

* Unapproved ideas.
* Approved requirements.
* Deferred approved requirements.
* Rejected proposals.
* Superseded requirements.
* Explicitly canceled requirements.

Do not promote brainstorming into mandatory implementation without approval.
Do not demote approved work into optional brainstorming.
Where approval evidence is uncertain, mark the item for investigation rather than guessing.
PART III — COMPREHENSIVE HISTORICAL RECOVERY
11. Conduct a second historical recovery audit
The first audit recovered 31 missing requests.
Treat this as evidence that more may remain undiscovered.
Search all accessible historical project records, including:

* Original project specifications.
* Historical development conversations and transcripts where accessible.
* Agent session summaries and handoff documents.
* Previous build punch lists.
* Development roadmaps.
* Owner directives.
* GitHub issues.
* Pull requests.
* Closed and draft pull requests.
* Commit history.
* Remote branches.
* Abandoned worktrees.
* Previous audits.
* Decision logs.
* World Design Rules.
* Interlocking Systems Manifest.
* In-game Wiki.
* Test reports.
* Asset integration records.
* Uploaded project documents available to the agent.
* Designing Virtual Worlds review materials.
* TODO and FIXME comments.
* Disabled or incomplete code.

Look for owner instructions expressed as:

* I want.
* We need.
* Add.
* Implement.
* Fix.
* Later.
* After this build.
* Put it on the list.
* Don't forget.
* Approved.
* This should work.
* This isn't working.

These phrases are examples, not the limits of the search.
Identify actual commitments rather than collecting every speculative idea.
12. Recover orphaned implementations
Search for code and assets that exist without a corresponding active requirement.
Identify:

* Incomplete features.
* Unmerged implementations.
* Abandoned prototypes.
* Assets imported but not integrated.
* Disabled mechanics.
* Tests covering unfinished behavior.
* Documentation describing missing functionality.
* Features with no gameplay verification.
* Work waiting on external dependencies.

Connect each finding to the appropriate existing requirement or create a sourced recovery entry.
Do not duplicate already tracked requirements.
13. Preserve historical evidence
For every recovered requirement, record:

* Exact wording where available.
* Source location.
* Date if known.
* Approval evidence.
* Original intent.
* Current implementation.
* Missing functionality.
* Dependencies.
* Verification requirements.

If exact original wording is unavailable, label the reconstructed requirement accordingly.
Never invent a quotation or approval.
14. Record inaccessible history
Document any sources that cannot be accessed.
Examples include unavailable conversations, missing attachments, inaccessible transcripts, and deleted branches.
Report historical coverage gaps explicitly.
Do not claim complete recovery when source coverage is incomplete.
If those sources become accessible later, repeat the recovery process.
PART IV — RESTORE THE WORLD DESIGN RULES
15. Reconcile the original 16 rules
The project originally established 16 World Design Rules.
The recent audit reported that only nine were present in the repository and added three newer rules as numbers 10–12.
That must be reconciled.
The original framework includes these 16 rule topics:

1. Material Interdependency.
2. Professional Interdependency.
3. Meaningful Recipes.
4. Economic Consequences.
5. Living World Independence.
6. Maintain the Existing Interlocking Systems Manifest.
7. Automated Compliance.
8. Player Knowledge and Wiki.
9. Emergent Gameplay.
10. Depth Without Obscurity.
11. NPC Self-Improvement and Prosperity.
12. NPC Competition and Economic Rivalry.
13. Finite Resources and Actual Consumption.
14. Graveyards, Ancestry, and NPC Legacy.
15. Political Authority, Social Hierarchy, and Civic Employment.
16. Bandit Factions, Criminal Careers, and Outlaw Leadership.

Search for the authoritative original documents, including:

* `My_Medieval_Life_World_Design_Rules_v1.pdf`
* `My_Medieval_Life_World_Design_Rules_v1.docx`

If available, restore their actual rule text.
If unavailable, preserve the known rule topics and mark the original detailed text as awaiting source recovery.
Do not invent the missing detailed rules.
Do not renumber newer rules to overwrite the original 10–16.
Evaluate genuinely new rules for numbering beginning at 017.
Check for duplicates before adding them.
Preserve the existing Interlocking Systems Manifest rather than creating another one.
PART V — AUTOMATIC CAPTURE OF FUTURE OWNER REQUESTS
16. Install permanent agent instructions
Add a concise permanent requirement to the root `CLAUDE.md` or equivalent authoritative project instructions.
Whenever the owner authorizes a feature, fix, system, or design change, the agent must:

1. Search the authoritative register for existing coverage.
2. Create or update the relevant requirement.
3. Preserve the owner's intent.
4. Record approval evidence.
5. Assign stable IDs.
6. Define acceptance criteria.
7. Record dependencies.
8. Identify related systems.
9. Record implementation status.
10. Keep the requirement visible until properly dispositioned.

Capture approved requirements before they can disappear during context compaction.
This is a standing project rule, not a one-time audit procedure.
17. Survive session restarts
Every new development session or major handoff must inspect:

* The authoritative requirements register.
* Active tasks.
* Blocked and deferred tasks.
* Current build target.
* Current branches and worktrees.
* Outstanding regressions.
* Pending owner decisions.
* Relevant World Design Rules.
* Interlocking Systems Manifest.

Do not depend on conversational memory as the authoritative record.
18. Preserve context before handoffs
Record:

* Active requirement IDs.
* Current branch.
* Current commit.
* Uncommitted changes.
* Tests performed.
* Known failures.
* Remaining work.
* Blockers.
* Pending decisions.
* Next actions.

Reference the permanent register rather than copying an incomplete backlog into a temporary summary.
19. Coordinate parallel agents
All agents must use the same authoritative requirement IDs.
Prevent duplicate entries.
Preserve branch-specific implementation status.
Reconcile work before merges.
Do not overwrite another agent's uncommitted changes.
Do not accept an agent's completion claim without appropriate evidence.
PART VI — AUTOMATED BACKLOG INTEGRITY
20. Create a requirements validation tool
Implement lightweight automated validation using existing project tooling where practical.
Verify:

* Unique requirement IDs.
* Valid lifecycle states.
* Required source references.
* Parent-child integrity.
* Valid dependency references.
* Valid supersession links.
* Reconciled totals.
* No duplicate authoritative entries.
* No unexplained requirement deletions.
* No completed items lacking required evidence.
* No canceled items incorrectly treated as active.
* No broken references to documentation.

Avoid unnecessary dependencies.
21. Detect silent deletion
Compare the authoritative requirements register with its previous committed version.
If an approved requirement disappears without documented completion, supersession, or owner cancellation, flag the change.
Fail the relevant integrity check.
Distinguish legitimate file migration from actual requirement loss.
Never silently accept deletion merely because a new register has fewer entries.
22. Test the protection
Create a temporary test fixture that simulates an approved requirement disappearing.
Verify that the validation detects it.
Do not delete or alter actual requirements to perform this test.
23. Integrate integrity checks
Run appropriate checks:

* During major development handoffs.
* During release audits.
* Before build readiness is declared.
* After requirements migrations.
* Before closing major feature groups.
* In CI where practical.

Do not perform an expensive full historical audit after every minor code edit.
Use incremental validation during routine development and comprehensive reconciliation at appropriate milestones.
PART VII — PRESERVE REQUIREMENTS ACROSS BUILDS
24. Builds do not erase obligations
Build 14, Build 15, Build 16, and future releases are milestones.
At each build boundary:

* Carry forward all unfinished requirements.
* Preserve partially implemented features.
* Preserve blocked work.
* Preserve deferred work.
* Preserve real-device verification requirements.
* Preserve unresolved regressions.
* Update completed implementation evidence.
* Update test results.
* Record newly discovered problems.

Never create a new build backlog by discarding the old one.
25. Maintain independent development workstreams
Keep multiplayer isolated on `wip/multiplayer` unless an authorized integration plan changes that.
Continue independent work on:

* Multiplayer.
* Economy measurements.
* Build 14 preparation.
* Requirements recovery.
* Appropriate feature development.

Coordinate branches and worktrees safely.
Do not interrupt productive development solely to perform documentation work.
26. Preserve approved future systems
At minimum, ensure continued tracking of:

* Villager relationships.
* Generational social memory.
* Gossip and inherited reputation.
* Wildlife breeding refuges.
* Wildlife dispersal and recovery.
* Elections and individual NPC voting.
* Mayor, constable, guard, and captain roles.
* Civic employment and public spending.
* Bandit factions and criminal careers.
* Graveyards and family legacy.
* Goods decay and equipment wear.
* Economy money sinks.
* Predictable taxes.
* Wildlife immigration.
* Readable danger.
* Sword combat responsiveness.
* Future archery.
* Cliff steps, stairs, and walkways.
* Skeleton asset integration.
* Horse integration.
* Real-device verification.
* Persistent Android signing.
* Google Drive cloud saves.
* Player-hosted multiplayer.
* All other approved requirements discovered in the historical records.

This is a minimum preservation checklist, not an exhaustive list.
Do not treat the existence of this checklist as proof that every requirement has been recovered.
PART VIII — OWNER DECISIONS AND EXTERNAL DEPENDENCIES
27. Horse implementation
Record my preferred initial horse role:
A plough horse available for purchase from the visiting caravan.
Evaluate integration with farming, animal ownership, transport, and the existing economy.
Do not invent additional horse capabilities or treat this preference as approval for unrelated mechanics.
28. Android signing
Prepare a stable test-signing procedure so future Android updates can preserve existing saves where technically supported.
Document:

* Required signing credentials.
* Required GitHub secrets.
* Secure setup steps.
* Key preservation requirements.
* Risks of changing signing identities.
* Test installation and update procedures.

Do not request that private signing credentials be pasted into chat or committed to GitHub.
Do not claim stable signing is configured until verified.
29. Real-device testing
Maintain a separate verification queue for items awaiting:

* Android phone testing.
* Physical controller testing.
* Windows PC testing.
* Cross-platform multiplayer testing.
* Two-device LAN testing.

Automated tests alone do not count as real-device verification.
30. Draft pull request
Review draft PR #1.
Determine whether it contains unique commits, code, assets, or documentation not preserved elsewhere.
Recommend closure only after verifying nothing valuable would be lost.
Do not close it without appropriate authorization.
31. Minimize owner interruptions
Only ask for owner decisions that genuinely cannot be resolved through existing approvals, project rules, or technical evidence.
Group related decisions together.
Do not repeatedly ask questions already answered in the decision log.
Do not silently decide major gameplay policy questions that remain reserved for the owner.
PART IX — DOCUMENTATION AND EVIDENCE
32. Synchronize project documentation
Keep the following consistent:

* Authoritative requirements register.
* Build audit reports.
* Decision log.
* World Design Rules.
* Interlocking Systems Manifest.
* Developer documentation.
* In-game Wiki.
* Test reports.
* Branch status.

Do not mark a feature complete if its required documentation is missing.
Distinguish implemented features from planned mechanics.
33. Produce a historical coverage report
Document:

* Sources searched.
* Date ranges covered.
* Requirements discovered.
* Requirements already tracked.
* Newly recovered requirements.
* Duplicates reconciled.
* Uncertain requirements.
* Inaccessible sources.
* Outstanding historical gaps.

Make the process repeatable by future agents.
34. Preserve a durable audit trail
Each requirement change should retain sufficient evidence to answer:

* Who requested it?
* What was approved?
* When was it approved, if known?
* What changed?
* Why did it change?
* Where is it implemented?
* How was it tested?
* What remains unfinished?
* Why was it closed, superseded, or canceled?

The register must support historical investigation rather than merely displaying the current status.
PART X — REQUIRED DELIVERABLES
35. Build 14 readiness report
Provide:

* Completed 100-day economy results.
* Any detected regressions and fixes.
* Status of the 365-day simulations.
* Manor reserve comparison.
* Caravan money-limit comparison.
* Resource depletion findings.
* Updated tester notes.
* Known playtest limitations.
* Recommended stable branch and commit.
* Whether Build 14 is ready for owner approval.

Do not create the build yet.
36. Requirements recovery report
Provide:

* Total known requirements.
* Total outstanding.
* Newly recovered requirements.
* Previously recovered requirements.
* Duplicates merged.
* Unknown or uncertain items.
* Blocked and deferred items.
* Historical coverage gaps.
* Corrected statuses.
* Missing approval evidence.

Ensure totals reconcile.
37. Permanent preservation implementation report
Provide:

* Authoritative register location.
* Permanent agent instructions added.
* Automated validation tools.
* Silent-deletion protection.
* CI or workflow integration.
* Handoff requirements.
* Validation test results.
* Relevant commits.
* Any limitations.

38. Development continuation plan
Identify:

* Immediate work.
* Next clean build boundary.
* Next feature development sequence.
* Independent parallel workstreams.
* Owner decisions required.
* Remaining external blockers.

The plan should preserve development momentum rather than impose unnecessary pauses.
PART XI — COMPLETION CONDITIONS
This combined directive is complete only when:

1. The 100-day economy results are recorded.
2. Genuine Build 14 regressions are investigated.
3. Build 14 tester notes are prepared.
4. A stable candidate commit is identified.
5. The owner has been asked for build approval.
6. A second historical requirements recovery pass is completed.
7. Newly recovered requirements are merged into the authoritative register.
8. The original 16 World Design Rules are reconciled as far as available evidence permits.
9. Stable requirement IDs are preserved.
10. Lifecycle counts reconcile.
11. Automatic backlog integrity validation exists.
12. Silent requirement deletion is detected.
13. A simulated deletion test passes.
14. Permanent startup and handoff procedures are installed.
15. Future build transitions preserve unfinished requirements.
16. Documentation reflects actual implementation.
17. Completed work is committed and pushed to the appropriate authorized branch.
18. Remaining historical gaps and owner decisions are explicitly reported.

Do not falsely claim completion when a required source or external dependency is unavailable.
Keep such items visible and unresolved.
FINAL INSTRUCTION
I want two things to happen simultaneously:
First: Finish preparing a clean, stable Build 14 that I can approve and playtest without unnecessarily delaying development.
Second: Establish a permanent project memory system that protects every approved requirement from being forgotten, lost, prematurely closed, or silently removed.
The 31 missing requests discovered in the recent audit should never have disappeared.
Recover as many additional historical requests as the available evidence supports.
Make the requirements register durable across sessions, agents, branches, and builds.
Automatically detect missing or improperly closed requirements.
Preserve unfinished work until it is actually finished.
Do not ask me to repeat decisions that are already documented.
Do not interrupt productive development unnecessarily.
Do not publish a new build without my approval.
The project must never depend on an AI agent remembering what I asked for. The repository must remember, and the development process must enforce it.
When finished, return:

1. Build 14 readiness status and recommended commit.
2. Economy simulation findings.
3. Total known and outstanding requirements.
4. Additional historical requirements recovered.
5. Automated preservation safeguards installed.
6. World Design Rules reconciliation status.
7. Remaining blockers and owner decisions.
8. Recommended next development priorities.

Continue approved development safely while carrying out this directive.
