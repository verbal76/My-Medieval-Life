# Owner directive, 2026-10-23: Build 18 overnight completion and release authorization

Verbatim (sent before the owner went to bed):

> MY MEDIEVAL LIFE — BUILD 18 OVERNIGHT COMPLETION AND RELEASE AUTHORIZATION
>
> I am going to bed. Your objective is to complete the remaining approved Build 18 work, pass all required verification gates, and produce the full three-platform Build 18 release.
>
> You have my explicit authorization to proceed without further confirmation, provided all mandatory checks pass.
>
> Do not stop for routine implementation questions that can be resolved reasonably within my existing design decisions.
>
> 1. Complete the chapel alms implementation
>
> For CHAPEL-R2, I approve:
>
> Clergy reserve: Option 1
>
> - Retain all outstanding clergy wages plus seven days of future wages.
> - At the current five coins per day, the additional reserve is 35 coins.
> - Use existing wage obligations and payment rules.
>
> Alms distribution: Option 1
>
> - Distribute available alms to the poorest eligible households.
> - Use the existing necessity-reserve calculation.
> - Prioritize the greatest shortfalls.
> - Fill each recipient's need up to its existing reserve.
> - Retain any undistributed money in the chapel fund.
>
> Ensure shared household resources are handled correctly so multiple household members do not receive duplicate assistance for the same need.
>
> Preserve deterministic ordering, coin conservation, existing clergy wages, food relief, and all other approved chapel behavior.
>
> Do not modify offering rates without authorization.
>
> 2. Authority to resolve minor questions
>
> You are authorized to make reasonable, narrowly scoped decisions without asking me when:
>
> - The decision follows an existing approved design.
> - The available options are functionally similar.
> - The choice is reversible.
> - It does not materially alter gameplay, economic balance, architecture, or player progression.
> - It does not introduce substantial new development work.
> - The recommended option is clearly supported by existing systems and evidence.
>
> Use the smallest sufficient implementation.
>
> Do not stop progress to ask me questions like the last two chapel questions when an existing, sensible recommendation is available.
>
> Mandatory decision log
>
> For every decision you make on my behalf, record:
>
> 1. The exact question that would otherwise have been presented to me.
> 2. The available options.
> 3. The option selected.
> 4. Why you selected it.
> 5. The affected systems and files.
> 6. Whether the decision is reversible.
> 7. Any consequences or follow-up concerns.
>
> Keep these decisions in a clearly identified Build 18 owner-review document.
>
> I will review them after the build.
>
> Do not present routine questions interactively unless they exceed your delegated authority.
>
> 3. Decisions already settled
>
> - CHAPEL-R2: Implement Priest + alms as specified above.
> - REG-CIRC-D1: Defer settlement circulation investigation to a later development round.
> - SET-D: Defer multigenerational settlement verification.
> - DP-17: Approved and complete.
> - DP-18: Retain the provisional +3 wage ceiling.
> - DP-19: Retain neutral 1.0 capability factors.
> - Chapel old-save corrections: Accept if compatibility checks pass.
>
> Do not reopen these decisions.
>
> 4. Complete verification efficiently
>
> Finish implementing and testing the alms system.
>
> Verify:
>
> - Clergy wages remain correct.
> - Chapel reserves are maintained.
> - Alms reach the intended households.
> - Household need is calculated correctly.
> - No duplicate distributions occur.
> - Coin and item conservation remain intact.
> - Determinism passes.
> - Existing Build 17 saves remain compatible.
> - The chapel no longer accumulates excessive funds merely because its approved alms distribution was missing.
> - No new simulation errors, crashes, or regressions are introduced.
>
> Compare the revised economic behavior against the recorded baseline.
>
> If the chapel balance, employment, or treasury results remain concerning, distinguish expected structural problems from actual defects.
>
> Use existing test evidence wherever valid. Run targeted tests for changed behavior and the minimum additional integration or long-run verification necessary.
>
> Do not run redundant full test campaigns.
>
> 5. Build 18 three-platform packaging
>
> When all mandatory verification gates pass, proceed automatically with the full Build 18 package set:
>
> 1. Android APK
> 2. Windows executable package
> 3. Linux executable package
>
> All three must use the same verified Build 18 source revision.
>
> Preserve existing version numbering, Android signing, package identifiers, save compatibility, release structure, and artifact naming conventions.
>
> Include the approved audio content and verify packaging and asset availability.
>
> The Windows and Linux music-download workflow must succeed.
>
> Verify that each artifact exists, is complete, and passes the available packaging checks.
>
> 6. Release authorization
>
> If every mandatory gate passes and all three artifacts are verified, you are authorized to create and publish Build 18 as a private or access-controlled GitHub playtest release, using the existing approved distribution workflow.
>
> If the repository or release would be publicly accessible, do not publish it there. Preserve the artifacts and report the access-control blocker.
>
> Do not publish to Steam, Google Play, or any public storefront.
>
> Do not change repository visibility or expose restricted assets, credentials, or source material.
>
> Do not publish an incomplete three-platform release.
>
> 7. Failure handling
>
> If a mandatory check fails:
>
> - Identify the actual root cause.
> - Apply RCA-01 and MSW-01.
> - Fix narrowly scoped implementation defects within the approved Build 18 work.
> - Rerun only the necessary verification.
> - Do not redesign unrelated systems.
> - Do not introduce speculative economic fixes.
> - Do not run an open-ended overnight repair campaign.
>
> If a major design decision is required, stop that work and document the blocker.
>
> If a release-critical failure cannot be resolved safely, do not publish.
>
> 8. Context and recovery management
>
> Claude context compaction typically occurs around 80%.
>
> Before reaching approximately 70–75% utilization:
>
> - Update the current recovery handoff.
> - Record the current commit and branch.
> - Record completed tasks and pending verification.
> - Preserve test results and decision logs.
> - Document any running processes or workflows.
> - Ensure the next context can continue without repeating completed work.
>
> Avoid unnecessary parallel agents and duplicated effort.
>
> 9. Morning report
>
> When I return, I want a concise report showing:
>
> - Build 18 status: Published, Packaged, or Blocked.
> - Final source commit and release identifier.
> - Test and determinism results.
> - Chapel economic comparison before and after alms.
> - Android APK artifact and download link.
> - Windows package and download link.
> - Linux package and download link.
> - Android signing and upgrade compatibility.
> - Audio packaging status.
> - All minor decisions made under delegated authority.
> - Any remaining non-blocking concerns.
>
> Include the location of the full decision log so I can review it.
>
> FINAL INSTRUCTION
>
> Prioritize getting Build 18 into my hands for playtesting.
>
> Do not expand scope, repeatedly ask minor questions, or spend hours polishing systems that already pass their requirements.
>
> Use sound engineering judgment within the boundaries of my approved design.
>
> Complete the alms implementation, verify it, build all three platforms, and publish to the authorized private playtest channel if everything is clean.
>
> If a major issue prevents a safe release, stop and leave me a clear report.
>
> Otherwise, keep working toward the finished three-platform Build 18 while I sleep.
>
> You do not need another confirmation to proceed within these boundaries.
