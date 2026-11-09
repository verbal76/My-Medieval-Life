# Owner messages of 2026-11-05 (America/New_York) recovered from the lead session record

**Reconstructed 2026-11-09 by the documentation agent (owner directive HAG-FORENSICS-01) from the lead session's transcript**
(`754052d8-fb21-5c64-b3f9-641f462e2c23.jsonl`, the conversation record of the Build 25 lead session; not in the repository).
These are the owner's messages of that day that were **not** already saved verbatim in `docs/directives/`. Each is copied
exactly as received; nothing is summarised or reworded. Times are the transcript's receive time (UTC) and America/New_York (EST,
UTC-5). This file did not exist when the messages were sent: it was written on 2026-11-09 and is not evidence that the records
held them at the time.

- `UNSAVED`: no saved directive contains the text. `PARTIAL`: a saved directive holds part of it (often a condensed copy); the
  full text is here.
- Messages the owner answered through the session's question tool, and owner answers already copied into the register's
  `owner_answer` fields, are not repeated here; the register is their record.
- Pasted file references (`@"/root/.claude/uploads/..."`) name files uploaded to that session; the files themselves are not
  in the repository unless a later commit imported them.
- Redaction: one multiplayer invite code (sent 2026-11-06 19:34 EST, in the 2026-11-06 file) is replaced by `[INVITE CODE REDACTED]`, because an invite code can
  carry the host's network address. Nothing else is altered.
- Saved directives of the same day stay authoritative for what they hold; where a saved directive says it was condensed,
  the full text below is the owner's exact wording.

## 2026-11-05 10:17 EST (2026-11-05 15:17:32 UTC), UNSAVED, transcript message `35aaeae5-4588-4006-a1c8-11fd01b735a3`

````text
Review the Claude Code permissions for this My Medieval Life repository.

Configure persistent, narrowly scoped preapprovals for routine Godot testing, GitHub Actions monitoring, test-log inspection, and safe build commands so development doesn't repeatedly stop waiting for me.

Use the appropriate ".claude/settings.json" permission allowlist. Preserve existing settings.

Do not grant unrestricted Bash access, disable safety checks, or preapprove destructive commands, credential access, force pushes, or repository deletion.

Verify the rules work for our actual test commands, including commands executed from worktrees. Report anything that still requires manual approval.

Once configured, continue the currently authorized B25R1 work.
````

## 2026-11-05 10:20 EST (2026-11-05 15:20:51 UTC), UNSAVED, transcript message `53dbf6b8-9fcc-44f8-a661-62a58a4a7fa4`

````text
Give me a complete, current B25R1 development status report.

Do not stop, cancel, or restart any running work to prepare this report.

Inspect the current repository, active worktrees, GitHub Actions runs, open pull requests, and development records.

I want:

1. Completed and merged: Everything completed since our last checkpoint, including commit SHAs.
2. Currently running: Every active agent, branch, and GitHub Actions job, with its purpose and current status.
3. Remaining development: Every unfinished B25R1 requirement, defect, integration, and investigation. Include counts.
4. Testing: Which suites have passed, which are running, which failed, and which require rerunning on the final commit.
5. Economy: Status of business founding, household tools, elder inventory sales, cross-settlement ore consignment, and farmland clearing. Include simulation outcomes.
6. Multiplayer: Status of host disconnects, network bandwidth, and the intermittent relationship synchronization defect.
7. Release readiness: Everything standing between the current build and private Windows, Linux, and Android playtest packages.
8. Owner decisions: Any genuinely unresolved questions requiring my approval. Do not reopen decisions already recorded.
9. Estimated remaining work: Give realistic time ranges based on actual test durations and dependencies, not guesses.

Separate verified results from work in progress and unknowns.

Use exact commit SHAs, GitHub run IDs, and timestamps. Do not claim a test passed merely because it was started.

Finish with a concise TL;DR showing:

- Completed workstreams / total workstreams
- Active workstreams
- Outstanding defects
- Outstanding owner decisions
- Remaining validation campaigns
- Next milestone

Continue all authorized development and testing after preparing the report. Do not wait for me unless a genuine owner decision is required.
````

## 2026-11-05 10:41 EST (2026-11-05 15:41:03 UTC), UNSAVED, transcript message `65e6a74a-4f7b-4d3e-86c6-aca70ecf6911`

````text
Run a new full-world drone flyover and generate a high-resolution stitched aerial image of My Medieval Life using the latest integrated B25R1 build.

Use the existing drone capture and stitching tools from our previous flyover. Review the previous flyover procedure and results before starting.

Requirements:

1. Capture the entire playable world, including every settlement, surrounding countryside, roads, rivers, forests, farmland, and major landmarks.
2. Include all recently integrated changes: Bear Hill, the castle knoll, Fantasy Lands houses, new grass decoration, regional terrain changes, and expanded farmland.
3. Use a consistent camera height, angle, zoom, and lighting across captures.
4. Stitch the images into one continuous, high-resolution aerial overview with no missing sections, duplicate terrain, or visible stitching seams.
5. Preserve the world's actual procedural layout. Do not fabricate, rearrange, or artistically reinterpret terrain or buildings.
6. Inspect the finished image for terrain discontinuities, misplaced buildings, roads ending unexpectedly, floating structures, vegetation clipping, and other visible defects.
7. Save the final stitched image as a downloadable PNG artifact, along with the capture metadata, seed, commit SHA, and image dimensions.
8. If practical, provide separate detailed aerial crops of each settlement for closer inspection.
9. Compare the new flyover with the previous one and identify the most significant visible changes.

Use the current integrated build and a recorded world seed so the results are reproducible.

Run this as an independent visual-validation task. Do not stop, cancel, or delay the existing economy, multiplayer, or GitHub validation work.

Report the artifact location and any defects discovered. Do not mark a visual defect resolved without verifying the correction.
````

## 2026-11-05 11:55 EST (2026-11-05 16:55:20 UTC), UNSAVED, transcript message `79923818-f732-496c-9de0-0bf1fdf01824`

````text
A few things immediately stand out to me:
Higham dominates the southern half. The walled settlement is unmistakable, but its position relative to the surrounding roads and waterways needs attention.
The northern settlements are much more spread out. That's a significant improvement over the old tightly packed village arrangement.
The waterways look good in the wilderness, with natural bends and tributaries. But the missing sections around settlements are noticeable. Fixing those should make the geography much more convincing.
The Wood Perilous is enormous. Its southern forest boundary is unusually straight and rectangular. That is worth checking against the intended geography.
The roads are extremely faint and sometimes difficult to follow. Several appear to fade into open ground rather than connect clearly to destinations.
The chalk figures are visible, which is encouraging given the scale of the map.
````

## 2026-11-05 12:45 EST (2026-11-05 17:45:45 UTC), UNSAVED, transcript message `605682c5-0f0e-461f-92eb-c48f4c2220ce`

````text
B25R1 — Economy Follow-Up Investigation

Two items from the cross-settlement ore consignment report need to remain explicitly tracked and verified.

1. Higham trader stopping ore collection after day 40

The 120-day simulation (GitHub Actions run "42058240181") showed that Higham's trader stopped carrying Garton's ore after day 40. The cause remains unexplained.

Investigate this using the existing simulation evidence, trade records, trader state, inventory, route availability, business status, purchasing limits, and consignment rules.

Determine exactly why collection stopped.

- If this is intended economic behavior, demonstrate why with evidence.
- If this is a defect, correct the root cause and run targeted verification.
- If the existing simulation lacks sufficient information, add narrowly scoped instrumentation and reproduce the behavior.
- Do not dismiss the issue because the overall 120-day simulation passed.
- Preserve real inventory, coin conservation, and existing economic rules.

2. Consignment policy review

The agent implemented two rules:

- Outside traders collect ore only from settlements without their own trader.
- Unsold consigned ore returns after 12 days.

Review both against the approved cross-settlement trading design.

Determine whether either rule unnecessarily prevents legitimate trade or creates avoidable shortages. Explain the economic consequences using actual simulation evidence.

Do not change these two policy values without owner approval. If a change is recommended, present the evidence and recommendation.

Execution priorities

Do not interrupt or delay the active multiplayer investigation, visual corrections, or final B25R1 validation.

Incorporate this investigation into the existing economy reconciliation work wherever practical. Avoid duplicating completed simulation campaigns.

Record the investigation, root cause, findings, supporting evidence, and any corrections in the project documentation and decision register.

Do not mark either item resolved until the evidence supports that conclusion.

Report the findings when available. No immediate owner response is required.
````

## 2026-11-05 14:09 EST (2026-11-05 19:09:07 UTC), UNSAVED, transcript message `be056b0c-922d-4986-9cbc-11a7bfabea2d`

````text
Claude, one clarification on tonight's B25R1 private playtest requirements.

Your packaging sequence didn't explicitly include the "net_c" multiplayer host-restart investigation.

That issue is a shipping blocker for tonight's private playtest.

Before packaging, we need:

1. The host-restart failure investigated to its root cause.
2. Any confirmed defect corrected and merged into "wip/b25r1".
3. The relevant multiplayer regression tests passing on the final integrated commit.
4. Confirmation that character identity, inventory, money, relationships, and other persistent records survive host restart correctly.

If the original failure was caused by test infrastructure rather than game code, demonstrate that with evidence and passing reproduction tests.

Please include multiplayer alongside the aerial maps, Wood Perilous corrections, and economy investigation in the final integration checklist.

Blocking means preventing shipment, not preventing parallel development. All four workstreams can continue independently, but their blocking issues must be resolved before tonight's playtest package is shipped.

Do not restart completed testing unnecessarily. Reuse valid evidence tied to the correct commit and run only what is required for final integration.

No need to stop the agents or change their current work. This is a clarification of the existing shipping requirements.
````

## 2026-11-05 15:32 EST (2026-11-05 20:32:02 UTC), PARTIAL, transcript message `7934ff61-bbc9-4b4e-aa82-9a768c116ca6`

````text
Claude — MML Build 25 Revision 1, additional economy directive.

Owner decision: APPROVED — Recover stranded settlement treasury ore.

Implement this alongside the ongoing economy work, but do not jeopardize tonight's private Windows playtest.

Required behavior

1. When a quarry, mining business, or trader closes, ore already transferred into settlement treasury storage must remain available to the economy.
2. A settlement's own active trader receives first opportunity to collect available surplus ore.
3. Neighboring traders may collect remaining surplus, consistent with approved owner decision 32.
4. Protect ore required for local production, existing obligations, and legitimate settlement reserves. Do not permit traders to drain essential local inventory.
5. Use existing commercial purchasing, consignment, pricing, inventory-transfer, and settlement accounting mechanisms wherever applicable. Do not introduce free transfers or duplicate economic systems.
6. Preserve the existing 12-day consignment return rule.
7. Business closures must remain possible for legitimate economic reasons.

Verification requirements

- First investigate how treasury ore is stored, owned, reserved, and accounted for. Identify the correct integration point before modifying code.
- Add regression tests for closed quarries, closed traders, competing neighboring traders, insufficient funds, local reserve protection, failed transactions, and save/load continuity.
- Verify that ore and coins are conserved across every transaction.
- Include treasury-ore recovery in the existing 120-day economy simulations on seeds 1–4, reporting quantities recovered, quantities traded, trader survival, iron imports, production, starvation deaths, and conservation failures.
- Compare against the approved economy baseline and distinguish improvements from unintended changes.
- Record the implementation, rationale, test results, and exact commit SHA in the development documentation and decision register.

Scheduling and shipping

Continue the already-approved work on decisions 32 and 33 without interruption.

Investigate and implement this in parallel if practical. Do not restart completed simulations unnecessarily.

If treasury recovery is safe, tested, and ready before the final integrated validation begins, merge it into "wip/b25r1" and include it in that validation.

If it requires substantial additional work, isolate it on its own branch and defer its merge until after the B25R1 private playtest. Do not delay packaging solely for this enhancement.

Do not declare the feature complete until the relevant GitHub Actions evidence is available and verified against the exact commit.

Primary objective remains unchanged: deliver a stable, playable B25R1 Windows package as soon as the existing shipping blockers are resolved.

Proceed without additional approval unless an actual economic policy decision is required.
````

## 2026-11-05 15:38 EST (2026-11-05 20:38:21 UTC), UNSAVED, transcript message `e12f234d-9641-477b-99aa-3b0d0e89e309`

````text
Claude — MML Build 25 Revision 1: Final Integration and Shipping Control

Your update on decisions 32 and 33, treasury-ore recovery ("wip/b25r1-econ6"), Wood Perilous, and multiplayer is acknowledged.

Owner directive: Continue all approved work in parallel. Our priority is delivering a stable B25R1 Windows private playtest as soon as the required validation passes.

1. Maintain the shipping boundary

The required integration work remains:

- Economy decisions 32 and 33 ("wip/b25r1-econ5").
- Wood Perilous geography and visual corrections ("wip/b25r1-wood").
- Multiplayer "net_interact" and host-restart persistence ("wip/b25r1-net5").

Treasury-ore recovery ("wip/b25r1-econ6") is authorized but is not a shipping blocker.

Do not wait for treasury recovery if the other three workstreams are ready for final validation.

2. Enforce a single final validation commit

Once the three required workstreams are ready:

1. Merge their verified commits into "wip/b25r1".
2. Record the exact integrated commit SHA.
3. Freeze that SHA for final validation.
4. Run the full test suite and split simulation checks against that exact SHA.
5. Reconcile results against the approved baseline.
6. Package the Windows private playtest from the same validated SHA.

Do not merge additional changes while final validation is running.

If any code changes after the validation SHA is established, identify which validation must be repeated. Never represent tests from an older SHA as validation of a newer build.

3. Treasury-ore branch handling

Continue the approved investigation, implementation, and four-seed 120-day simulation campaign independently.

If treasury recovery is fully tested and ready before the final integration freeze, it may be included after reviewing its evidence and integration risk.

Otherwise, leave it isolated until after the Windows playtest package is produced.

Do not cancel or restart completed simulations unnecessarily.

4. Resolve genuine blockers

For "net_interact", host-restart persistence, Wood Perilous, and economy decisions 32/33:

- Investigate every unresolved failure.
- Identify the root cause before changing code.
- Add focused regression coverage.
- Verify fixes through GitHub Actions.
- Record the exact tested SHA.
- Continue independent workstreams while another is testing.

Do not weaken tests or bypass failures simply to obtain a green result.

5. Package and report

After successful integrated validation, produce the Windows private playtest package with its build information, commit SHA, and known limitations.

Keep the full 365-day simulation campaign running independently where possible, provided no critical evidence indicates the package is unsafe for playtesting.

Give me a timestamped status report containing:

- Required workstreams: completed versus outstanding.
- Treasury recovery: separate progress and evidence.
- Current integrated branch SHA.
- GitHub Actions runs, conclusions, and tested SHAs.
- Remaining critical blockers.
- Estimated time to the Windows package, based on actual remaining work.
- Final package link once verified.

Do not introduce new features or expand scope. Do not ask for routine approvals already granted.

The goal is to get Build 25 Revision 1 into my hands for actual gameplay testing while preserving our verification standards.

Proceed.
````

## 2026-11-05 16:02 EST (2026-11-05 21:02:02 UTC), UNSAVED, transcript message `6e2023d9-712a-4679-bda6-d44bc62d5c9a`

````text
Claude — MML B25R1 Critical-Path Parallelization Audit

We're approximately two hours behind our original schedule.

Immediately audit all active agents, local processes, GitHub Actions workflows, test dependencies, and remaining shipping tasks.

Determine whether we have maximized useful parallel execution without compromising validation.

Specifically:

1. Identify every task currently on the critical path to the Windows package.
2. Identify tasks that are unnecessarily waiting on other tasks.
3. Run independent Wood Perilous geometry tests and flyover verification concurrently.
4. Separate multiplayer root-cause investigation from independent persistence regression testing where safe.
5. Begin baseline reconciliation preparation using known economy and generation changes.
6. Prepare Windows packaging and smoke-test infrastructure before final validation finishes, without creating or labeling an unvalidated release.
7. Examine whether the 65-minute full suite can be divided into independent GitHub jobs while preserving identical test coverage and results.
8. Avoid duplicate watchers, redundant simulations, and unnecessary resource contention.
9. Do not interrupt existing productive agents or restart tests unnecessarily.
10. Preserve the approved shipping boundary and exact-SHA validation requirements.

Do not add agents simply to increase concurrency. First identify available capacity, dependencies, and whether additional parallelism would actually reduce completion time.

Report:

- Current critical path and measured remaining durations.
- Work already parallelized.
- Additional work that can safely run concurrently.
- Any resource bottlenecks.
- Estimated time saved by each proposed change.
- Revised earliest realistic package time.

Implement safe scheduling improvements immediately. Do not weaken tests, omit required validation, or change shipping scope without approval.
````

## 2026-11-05 18:11 EST (2026-11-05 23:11:28 UTC), PARTIAL, transcript message `eed9928f-ce79-4fd8-a71c-e9b8f8e736b8`

````text
B25R1 — DINING ROOM RELEASE: FASTEST SAFE DELIVERY

OWNER DIRECTIVE — November 5, 2026

This is a FAMILY PLAYTEST, not a Steam release or public production launch.

Our priority is the earliest possible playable Windows package, followed by the remaining requested packages.

Keep the existing frozen source F ("a9e9f6e"), validation requirements, naming conventions, DEMO-01 preset, and established release workflow.

1. Finish the validation already running.

- Do not restart passing tests or duplicate campaigns.
- Investigate actual failures; do not bypass safety-critical checks.
- Do not wait for the 365-day campaign unless it reveals a critical issue.
- Reconcile the simulation baseline and obtain required approval. Verify P differs from F only in "sim_baseline.json".

2. Start packaging immediately after the required gates pass.

- No additional planning cycles, new features, workflow redesigns, or unrelated documentation delays.
- Use existing parallel GitHub Actions jobs.
- Do not serialize independent builds unnecessarily.

3. Prioritize Windows delivery.

- The full Windows game is the first priority.
- The Windows DEMO-01 package is the second priority.
- Android and Linux full packages follow, with their automatic demo variants.
- If Windows packages pass their established smoke tests before other platforms finish, make them downloadable immediately if the existing workflow permits it without risky modifications.
- Do not delay a ready Windows package merely to complete other platform uploads.

4. Public GitHub Release.

- Publish the established package names and release tag.
- Make the release easy to find and mark it Latest when appropriate.
- Verify assets are downloadable.
- No Steam uploads and no changes to repository visibility.
- No unnecessary additional testing beyond the established release gates.

5. Report measured times, not padded estimates.
Report when each stage starts and finishes, the exact SHA and run IDs, and the first verified Windows download link.

If an existing workflow dependency prevents early Windows delivery, identify that dependency and its actual time cost. Do not rewrite the workflow tonight merely to save a few minutes.

This is a dining room release. Get the verified game into our hands as quickly as safely possible.
````

## 2026-11-05 20:31 EST (2026-11-06 01:31:48 UTC), UNSAVED, transcript message `91845e0d-215f-4515-86af-94732ce27723`

````text
MY MEDIEVAL LIFE — BUILD 25R1

OWNER DIRECTIVE: FAMILY PLAYTEST NOW, FINAL VALIDATION IN PARALLEL

Date: November 5, 2026
Priority: IMMEDIATE EXECUTION
Feature scope: CLOSED — No new features or expansions

OBJECTIVE

Build 25's planned feature scope is complete. We are not waiting for another expansion or development phase.

We have two parallel objectives:

TRACK A — Deliver the complete integrated Build 25 family playtest immediately.

TRACK B — Continue all existing regression, determinism, and long-term validation until Build 25 can be formally frozen.

This is a family dining room multiplayer playtest, NOT a Steam release or production launch.

We are not postponing gameplay for production-level testing.

The family needs to be able to generate a world, join that same world, play together, save, leave, and return with their progress intact.

---

TRACK A — IMMEDIATE FAMILY PLAYTEST

1. Select the correct source

Use the current complete integrated Build 25R1 baseline:

"wip/b25r1" — "a9e9f6e"

If a newer commit is already integrated and verified safe, identify it and explain why it is preferable.

Do not merge unfinished experimental fixes merely to make the build newer.

Do not alter the frozen baseline while preparing the family package.

Use an isolated build branch or worktree as needed.

The package must contain the complete planned Build 25 feature scope, not a reduced demonstration or partial integration.

2. Run focused smoke tests immediately

This is a short, targeted validation pass, not another full regression campaign.

Verify:

1. Windows launch: The executable starts and reaches gameplay without crashing.
2. World generation: A new world generates successfully using a seed.
3. Multiplayer connection: Multiple players can join the same hosted world.
4. Shared world: Players occupy the same world and observe consistent changes.
5. Player persistence: Characters, inventories, relationships, and relevant player state are preserved.
6. World persistence: Buildings, businesses, settlements, and meaningful world changes survive saving.
7. Save and reload: Save the multiplayer world, exit completely, reopen the game, and load the saved world.
8. Reconnect: Players can rejoin the saved world and resume their previous progress.
9. Economic persistence: Record known coin balances and inventories, perform a legitimate purchase or payment, verify the results, save, exit, reload, and confirm that the balances and transaction results remain unchanged.

Use existing automated tests and test infrastructure wherever possible.

If a test requires a real multiplayer session that cannot be performed automatically, report it as unverified and identify the smallest practical manual check.

Do not falsely report a test as passed.

Do not build a new test framework or start hours of additional simulations.

3. Buyer 39 investigation — important distinction

The ongoing determinism investigation has established:

- The household first-tool rule did not fire during the relevant window.
- Buyer 39's logged wheat purchase was identical in both simulations.
- Buyer 39 nevertheless experienced approximately a 10-coin difference between recorder-enabled and recorder-disabled simulations.
- The cause remains unidentified.
- Possible sources include wages, rent, contracts, household transfers, or other payments.

The latest trace runs are:

- Recorder enabled: "42144094135"
- Recorder disabled: "42144097399"
- Both at commit "2c02087"

These runs are tracing every change to Buyer 39's coins between simulation minutes 24925 and 24945.

Continue this investigation independently.

Do not assume the difference is harmless, but do not automatically classify it as save corruption either.

The investigation must establish whether the difference represents a legitimate but differently ordered transaction, an accounting defect, or another simulation problem.

The family playtest can proceed if its focused economic persistence and save/load checks pass and no critical gameplay defect is demonstrated.

4. Build and deliver Windows immediately

Once the essential smoke checks pass:

- Build the complete Windows game.
- Include all required runtime dependencies.
- Create a ready-to-play ZIP.
- Record the exact source commit SHA and build timestamp.
- Label it "My Medieval Life — Build 25R1 Family Playtest".
- Include brief launch and multiplayer instructions.
- Publish it as a downloadable GitHub Release asset.
- Make the release accessible to the family and provide the direct download link.
- Identify known issues and unverified checks.

Do not publish an empty release or claim a package exists before its asset is available.

Do not wait for Android or Linux.

After Windows is delivered, package Android and Linux using the same playtest baseline where practical.

Do not allow their builds to delay Windows delivery.

5. What actually blocks the family playtest?

Only confirmed critical problems:

- Game cannot launch or generate a playable world.
- Multiplayer cannot establish a shared world.
- Fundamental shared-world synchronization is broken.
- Save/load fails or corrupts the playtest world.
- Coins, items, or critical player state are demonstrably lost or duplicated during normal save/reload.
- A repeatable crash prevents normal gameplay.

A determinism mismatch alone is not a release blocker.

An unfinished 365-day simulation is not a release blocker.

Unrelated regression failures are not automatically release blockers.

If a critical defect is found, identify the exact problem and perform the smallest necessary correction. Do not silently expand the release criteria.

Use fresh playtest saves until compatibility with older saves has been verified.

---

TRACK B — CONTINUE FINAL VALIDATION IN PARALLEL

6. Preserve all running GitHub work

Do not cancel, restart, or interfere with existing workflows.

Known investigations include:

Work| GitHub Actions run
Original recorder-enabled trace| "42141394672"
Original recorder-disabled trace| "42141398779"
Combined regression tests on "wip/b25r1-f2pre"| "42141779390"
Existing 365-day campaign| "42124902114"
Buyer 39 detailed trace, recorder enabled| "42144094135"
Buyer 39 detailed trace, recorder disabled| "42144097399"

Read the actual artifacts and "sim.log" files when completed. Do not rely solely on workflow summary status.

Investigate the five previously identified regression failures and the determinism divergence.

Preserve the distinction between:

- Confirmed game defects
- Test defects
- Infrastructure failures
- Legitimate simulation behavior
- Unresolved findings

Do not guess or dismiss discrepancies without evidence.

7. Complete the final candidate

The current preliminary combined-fix branch is:

"wip/b25r1-f2pre" — "8254089"

This is an early integration check, not automatically the final F2 candidate.

When the determinism investigation and regression fixes are ready:

1. Integrate the verified corrections.
2. Confirm no planned Build 25 feature is missing.
3. Verify multiplayer and persistence.
4. Run the required full regression suite.
5. Complete the required simulation and determinism gates.
6. Validate against the exact final candidate commit SHA.
7. Preserve logs, artifacts, results, and decisions in GitHub.

Reuse existing valid test evidence where appropriate, but do not claim an older commit's passing tests validate newly modified game code.

All of this continues while the family is already playing the earlier package.

---

FINAL BUILD 25 DECISION

Outcome A — Defects are found

If the ongoing testing reveals defects:

- Identify the actual root cause.
- Make targeted corrections.
- Verify the fixes.
- Update the family package if the defect affects gameplay, multiplayer, or persistence.
- Continue the remaining final validation.

Do not introduce additional features or expansions.

Do not restart the entire development cycle for an isolated correction.

Outcome B — Everything passes

If the full planned feature scope is confirmed and every established final validation gate passes:

FREEZE BUILD 25 AUTOMATICALLY.

Specifically:

1. Confirm the final integrated commit SHA.
2. Confirm the required fixes are included.
3. Confirm multiplayer and save/load integrity.
4. Confirm regression, determinism, and long-term simulation results meet the established gates.
5. Confirm the final playable package corresponds to the verified source.
6. Record the evidence and final decision in the repository.
7. Create the final Build 25 tag and publish the verified release artifacts.
8. Mark Build 25 feature-complete and frozen.

No additional owner approval is necessary once all established requirements are satisfied.

Do not declare a freeze if any required gate remains failed or unverified.

If the family playtest package already matches the final verified commit, promote that exact artifact where appropriate.

If corrections changed the source, produce and verify the corrected final package.

---

EXECUTION AND REPORTING RULES

- Execute both tracks concurrently.
- Windows family playtest delivery takes immediate priority.
- Keep GitHub validation running.
- Do not hold packaging for the Buyer 39 investigation unless it establishes a critical playtest problem.
- No new features.
- No unnecessary testing expansion.
- No restarting successful workflows.
- No speculative delivery estimates.
- No claiming unverified results.
- Record exact commits, timestamps, and evidence.
- Report progress in completed/outstanding counts, not percentages.
- Do not repeatedly request permission to proceed.

First report required

Provide:

Family playtest

- Smoke tests: passed / failed / unverified
- Multiplayer: verified / unverified
- Save/load: verified / unverified
- Economic persistence: verified / unverified
- Windows ZIP: building / ready / blocked
- Download link when published

Final validation

- Buyer 39 investigation: findings
- Five regression fixes: status
- Determinism: status
- 365-day campaign: status
- Build 25 freeze: pending / eligible / completed

FINAL INSTRUCTION

Start the family smoke tests and Windows packaging immediately.

Continue the detailed GitHub investigations in parallel.

Our family should be able to play the complete Build 25 experience while those investigations finish.

If testing finds defects, fix them.

If everything passes, freeze Build 25.

No more waiting for production-level validation before we can sit down and play our game. Proceed without another approval.
````

## 2026-11-05 20:49 EST (2026-11-06 01:49:59 UTC), UNSAVED, transcript message `06a6103d-6e25-4bf7-9cc2-ef41845d433d`

````text
My Medieval Life — Build 25R1 Windows Family Playtest: Remove Unnecessary Release Dependency

Priority: Get the existing Windows family playtest package smoke-tested and published immediately. Do not wait for Linux, Android, or the long-running simulation campaigns.

1. Correct the Windows release dependency

The current "release.yml" workflow waits for all six platform packages before starting the Windows smoke test.

Five packages have completed, including both Windows packages. The full Linux package is taking substantially longer and is blocking Windows validation.

This dependency is unnecessary for our Windows-first family playtest.

Required actions:

1. Inspect the existing release workflow and its job dependencies.
2. Determine whether the Windows smoke test can run immediately against the already-built Windows artifact from run "42144510422", commit "a9e9f6e".
3. If possible, run the existing Windows smoke test independently without rebuilding the Windows package.
4. If the workflow requires modification, make the smallest targeted change so Windows smoke testing depends only on its required Windows package and prerequisites.
5. Preserve all existing Linux, Android, and full-release validation jobs. Do not cancel or disrupt them.
6. Do not restart the entire six-package build merely to correct this dependency.

The goal is to eliminate unnecessary waiting, not eliminate meaningful validation.

2. Publish the family playtest

Once the Windows smoke test passes:

- Publish the already-built Windows package from commit "a9e9f6e".
- Use the prepared "wip/b25r1-family" publishing workflow where appropriate.
- Verify that the published ZIP is byte-identical to the tested artifact.
- Publish under the existing planned release, My Medieval Life — Build 25R1 Family Playtest.
- Include the build SHA, date, known issues, and instructions for hosting and joining multiplayer sessions.
- Provide the direct download link.

If the GitHub "public-release" environment requires my approval, tell me exactly where to approve it. Do not silently bypass that protection.

Do not mark the package validated if its Windows smoke test has not passed.

3. Keep Build 25 verification running independently

Continue the existing investigations and tests without blocking the family playtest:

- Recorder-enabled versus recorder-disabled determinism verification on fix "65a5f2e".
- The two 30-day seed-1 simulations, including five-day checkpoint comparisons.
- Outstanding "net_econ_integrity_test" investigation.
- Remaining regression suites and the 365-day campaign.
- Full Build 25 integration and eventual freeze requirements.

Do not claim Build 25 is frozen or fully validated until its required gates pass.

The family playtest is a separate, explicitly authorized limited testing release, not a production-ready declaration.

4. Preserve the exact source and release evidence

The family playtest package currently comes from "a9e9f6e".

Do not silently replace it with the newer unverified fixes branch. If a critical playability defect requires a newer package, identify the exact defect, commit, and minimum retesting required.

Record all decisions, commit SHAs, test results, timestamps, and reasons for workflow changes in the project documentation.

5. Required report

Report back with:

1. Windows dependency: Removed or bypassed, with explanation.
2. Windows smoke test: PASS/FAIL, exact artifact and commit.
3. Family playtest: Published or blocked, with the precise reason.
4. Download: Direct GitHub release link when available.
5. Remaining Build 25 tests: Current status and unresolved issues.

Standing authorization: Proceed automatically through Windows smoke testing and preparation for publication. Do not stop for routine approvals. Only request my action where GitHub explicitly requires it or where a new critical defect changes the approved plan.

Do not let a slow Linux build hold our Windows family playtest hostage.
````
