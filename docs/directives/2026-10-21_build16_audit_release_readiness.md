# Owner directive, 2026-10-21: Build 16 development audit and release-readiness report

Received in the session on 2026-10-21, verbatim:

> MY MEDIEVAL LIFE — BUILD 16
>
> IMMEDIATE DEVELOPMENT AUDIT AND RELEASE READINESS REPORT
>
> OWNER PRIORITY REQUEST
>
> We have been working on Build 16 for approximately 11 hours, and I still do not have a new playable build.
>
> I need a complete, factual accounting of the project's current state, why we have not produced Build 16, and exactly what remains before I can playtest it.
>
> This is an immediate reporting priority.
>
> Finish or safely checkpoint any operation that cannot be interrupted without losing work. Then prepare and deliver this report before beginning another substantial implementation task or launching additional long-running simulations.
>
> Do not interpret this request as an instruction to stop approved development permanently.
>
> ---
>
> 1. Current development status
>
> Tell me:
>
> - What are you working on right now?
> - What were you working on immediately before this request?
> - What tasks are running in the background?
> - How many agents are active?
> - What is each agent doing?
> - How long has each active task been running?
> - Are any agents idle, stalled, repeatedly retrying, or duplicating work?
> - Are there any GitHub Actions jobs currently running?
> - Which jobs are actually necessary before the next playable build?
>
> Report the actual state. Do not simply repeat the previous status document.
>
> 2. GitHub and code preservation
>
> Identify:
>
> - Current repository and branch.
> - Current local HEAD commit.
> - Latest commit pushed to remote staging.
> - Whether local and remote commits match.
> - Whether there are uncommitted changes.
> - Whether there are unpushed commits.
> - Whether any agent has changes in another worktree or branch.
> - Whether any completed work is at risk of being lost.
> - Whether there are open pull requests.
> - Whether a merge is required before a test build can be produced.
>
> If verified work is complete but uncommitted, preserve it appropriately.
>
> Do not merge into the release branch without authorization.
>
> 3. Build 16 completion audit
>
> Read the authoritative Build 16 status register and compare it against the actual repository, commits, tests, and active tasks.
>
> Give me the current totals for:
>
> - Complete and verified.
> - Implemented but awaiting testing.
> - In progress.
> - Not started.
> - Blocked.
> - Deferred.
> - Superseded.
>
> For every incomplete item, report:
>
> | Item ID | Description | Status | Remaining work | Blocker | Estimated complexity | Required for next playable build? |
>
> Do not mark something complete merely because code exists.
>
> Do not count deferred or superseded items as active unfinished work.
>
> Identify any items whose status document disagrees with actual repository evidence.
>
> 4. What has been accomplished in these 11 hours?
>
> Provide a chronological development summary.
>
> For each major completed task, identify:
>
> - What was changed.
> - Why it was changed.
> - Commit SHA.
> - Tests performed.
> - Whether the work is integrated into staging.
> - Whether the change is available in a playable build.
>
> Distinguish actual implementation from investigation, documentation, testing, and planning.
>
> I want to understand where the development time went.
>
> 5. Why haven't we produced Build 16?
>
> This is the central question.
>
> Identify the exact reason there is no new playable Build 16 available.
>
> Is it because:
>
> - Required systems are unfinished?
> - Tests are failing?
> - Simulations are still running?
> - New regressions are being discovered?
> - A build/export pipeline is broken?
> - Owner decisions remain unresolved?
> - The implementation scope is still expanding?
> - Development is complete but nobody has initiated the build?
> - Another specific reason?
>
> Identify the actual blockers with evidence.
>
> Do not present optional improvements as mandatory release blockers.
>
> Do not keep delaying a playable build solely because another approved expansion feature can be implemented.
>
> 6. Playable build versus completed expansion
>
> Distinguish between two separate milestones.
>
> A. Next playable Build 16 development candidate
>
> A privately distributed build that I can install and playtest to evaluate the current work.
>
> B. Final Build 16 expansion completion
>
> The complete approved Build 16 feature set, fully integrated, tested, and ready for final acceptance.
>
> I understand these are not necessarily the same milestone.
>
> Tell me what is required for each.
>
> Identify whether the current staging commit is suitable for a private development build.
>
> If not, list the specific defects preventing one.
>
> A feature being incomplete does not automatically make the current code unsuitable for a development build, provided it is stable enough for meaningful testing and its limitations are clearly identified.
>
> Do not create or publish a build yet. I am requesting release readiness information, not authorizing a new build.
>
> 7. Test and simulation results
>
> Report the latest verified results for:
>
> - All Godot test suites.
> - Python tests.
> - Determinism checks.
> - Script errors.
> - Coin conservation.
> - Item conservation.
> - Food security.
> - Household behavior.
> - Farming and seasonal simulations.
> - Livestock survival.
> - Armorer and shopkeeper interactions.
> - Construction, seeds, and market stalls.
> - Android export and installation readiness.
>
> For each, distinguish Passed, Failed, Running, Not Tested, and Not Applicable.
>
> Include the tested commit SHA.
>
> Do not describe an earlier passing test as verification of newer untested changes.
>
> 8. Farming and livestock status
>
> Provide the latest status of:
>
> - FSE-12 shared per-cell farming.
> - FSE-13 seasonal farming.
> - FARM-08 yield comparisons.
> - FARM-08A homeless-household crash.
> - Cattle population decline.
> - Milk production.
> - Seed consumption and recovery.
> - Family farmland leasing and construction.
>
> Explain which farming switches are currently enabled in normal gameplay.
>
> Identify any unresolved owner decisions and whether they actually block a private development build.
>
> Do not change approved farming values or activate experimental systems without authorization.
>
> 9. Armorer, counters, and trade
>
> The armorer was previously identified as a release blocker.
>
> Tell me whether:
>
> - The armorer profession now exists.
> - The armorer can produce and sell actual equipment.
> - The armoury counter functions.
> - Pressing A at the counter summons an available shopkeeper.
> - Shopkeepers can serve customers while following ordinary schedules.
> - Businesses purchase actual required inputs.
> - Player and NPC transactions conserve inventory and money.
> - These interactions have been tested on Android.
>
> Clearly identify what remains unverified.
>
> 10. Agent and credit efficiency
>
> Report the agents used during this development session.
>
> For each agent, include:
>
> - Assigned task.
> - Duration.
> - Reported token usage, if available.
> - Work completed.
> - Whether the result was integrated.
> - Whether parallel execution saved meaningful time.
>
> Also report:
>
> - RTK status and measured savings, if available.
> - Repeated or unnecessary investigations.
> - Duplicated test runs.
> - Long-running tasks that produced no useful result.
> - Any preventable resource waste.
>
> Do not invent credit costs or token savings.
>
> I want to know whether additional agents are accelerating development or simply consuming more resources.
>
> 11. Outstanding owner decisions
>
> List every unresolved decision.
>
> For each, provide:
>
> - Decision ID.
> - Exact question.
> - Available options.
> - Your recommendation.
> - What is blocked until I answer.
> - Whether it prevents a private development build.
>
> Do not reopen decisions I have already approved.
>
> Preserve the approved Build 16 scope and the authorized Build 17 and Build 18 deferrals.
>
> 12. Critical path to the next playable build
>
> Give me the shortest responsible path to a playable Build 16 development candidate.
>
> Provide the next five actions in priority order.
>
> For each, identify:
>
> - Required work.
> - Dependencies.
> - Whether another agent can perform it independently.
> - Whether testing is necessary.
> - Whether owner approval is needed.
> - Estimated complexity.
>
> Distinguish essential work from optional polishing.
>
> Do not sacrifice data integrity, determinism, or basic stability merely to produce a build sooner.
>
> 13. Critical path to final Build 16 completion
>
> Separately provide the remaining implementation plan for the complete expansion.
>
> Identify which systems are the largest remaining workloads and which can be developed in parallel.
>
> Do not silently defer approved Build 16 requirements.
>
> Do not merge future expansion milestones into Build 16.
>
> 14. Required executive summary
>
> Start your response with a concise executive summary containing:
>
> CURRENT STATUS
>
> - Latest verified staging commit:
> - Current active development task:
> - Build 16 completion percentage and calculation:
> - Total open work items:
> - Current test status:
> - Current simulation status:
> - Active agents:
> - Active GitHub Actions runs:
>
> PLAYABLE BUILD
>
> - Can a private Build 16 development candidate be produced from current staging? YES / NO / NOT YET VERIFIED
> - Exact reason:
> - What must happen first:
> - Owner decisions blocking it:
>
> FINAL EXPANSION
>
> - What remains:
> - Largest outstanding systems:
> - Known blockers:
> - Next five actions:
>
> RESOURCE USAGE
>
> - Approximate session activity:
> - Measured token usage, if available:
> - Agent efficiency concerns:
>
> 15. Reporting requirements
>
> Give me the actual findings in your response, not just a link to a document.
>
> Update "docs/BUILD_16_STATUS.md" and the relevant development state files after reconciling the findings.
>
> Preserve verified work in GitHub staging.
>
> Do not launch another large development task before delivering this report.
>
> After reporting, continue approved independent development unless blocked by a genuine owner decision.
>
> Do not merge, export, publish, or distribute a new build without my explicit approval.
>
> ---
>
> Final owner instruction
>
> I am not asking you to rush an unfinished expansion into public release.
>
> I am asking why, after approximately 11 hours of development, I still cannot playtest the current progress.
>
> I need to see where the time went, what is actually finished, what is preventing a private playable build, and how close we are to completing the entire Build 16 expansion.
>
> Give me evidence, not optimistic estimates.
>
> Report first. Then we will decide the next step.
