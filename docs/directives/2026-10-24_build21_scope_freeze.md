Owner directive, 2026-10-24, verbatim.

OWNER DIRECTIVE — MY MEDIEVAL LIFE BUILD 21: IMMEDIATE SCOPE FREEZE, WORK PRESERVATION, AND PLAYTEST BUILD
PRIORITY: IMMEDIATE. EXECUTE THIS DIRECTIVE NOW.
We have consumed 97% of the weekly Claude allowance. The priority is to finish and deliver My Medieval Life Build 21 for hands-on playtesting before the remaining allowance is exhausted.
This directive supersedes previous instructions requiring all approved Build 21 features to be completed before packaging.
Do not ask for confirmation. Do not start new feature development. Do not continue working on the four items listed below.
1. Immediately stop and preserve unfinished work
Stop the active Build 21 agent from continuing the four deferred features.
Before reverting, excluding, or changing any partially completed work:

* Preserve all uncommitted changes and completed work in a dedicated Git branch or recoverable commit.
* Record the branch, commit SHA, affected files, current implementation status, remaining work, and dependencies.
* Do not delete, overwrite, or discard partially completed features.
* Do not accidentally merge incomplete functionality into Build 21.
* Keep all deferred work recoverable for the next build.
* Avoid unnecessary agents, audits, or additional development rounds.

Use the minimum safe Git operations necessary to preserve the work.
2. Defer these four items to Build 22
A. Lockpicking minigame
Defer all unfinished implementation and testing. Preserve existing progress.
B. Farmers tending their fields
This is primarily a visual animation improvement. It is not a Build 21 requirement. Preserve the work and defer it.
C. Merchandise displayed on tables
Clarification of original design intent:
Tables are not supposed to function as item-pickup containers.
They should provide a visual representation or quick preview of merchandise available from the business, allowing the player to see what is offered without initiating a transaction.
Do not implement a table-item pickup mechanic. Preserve any useful work and defer unfinished visual-preview functionality.
D. Business desk and courier integration
Defer unfinished courier integration and business-desk enhancements.
Mandatory condition: Existing shopkeepers and salespeople must still allow the player to buy and sell goods normally.
If the existing buy/sell interaction works, do not hold Build 21 for courier integration or additional desk functionality.
If it is broken, perform only the minimum repair necessary to restore the existing transaction functionality.
3. Preserve the Build 22 mini-build backlog
Create or update:
`docs/backlog/BUILD22_MINI_BUILD.md`
This document must preserve the four deferred items above, including their implementation history and recovery references.
Also include the previously deferred MP-PLAYER-FAMILY repair:

* Player marriage and couple-household records.
* Correct parent-child relationships.
* Adoption records and adoptive-parent links.
* Existing biological birth versus adoption population rules.
* Required save compatibility, simulation integrity, and regression tests.

Record any other known unfinished defects, approved polish items, or follow-up work already identified in the project registers, handoffs, or audit documents. Do not invent additional scope.
Clearly distinguish:

1. Deferred feature development.
2. Existing known defects.
3. Validation still required.
4. Issues discovered during Build 21 playtesting.

Build 22 is a focused mini-build to finish outstanding work before the next major expansion. Do not start Build 22 now.
4. Freeze Build 21
Preserve all completed, working Build 21 improvements.
Do not remove functioning features merely because unrelated work is deferred.
Do not introduce new mechanics, redesign existing systems, expand scope, or perform optional polish.
If a deferred feature has partially modified working gameplay, restore the last known working behavior while retaining its development work safely on the preservation branch.
Maintain the existing package identifier:
`com.hotatticgames.mymedievallife.dev`
Maintain Build 21 as Android version code 21.
Do not change save formats or signing identities unnecessarily.
5. Integrate permanent Android signing
Merge the completed signing work from:
`wip/android-signing`
Signing implementation commit:
`8f38920`
Preserve the four existing GitHub secrets:

* `ANDROID_RELEASE_KEYSTORE_BASE64`
* `ANDROID_RELEASE_KEYSTORE_PASSWORD`
* `ANDROID_RELEASE_KEY_ALIAS`
* `ANDROID_RELEASE_KEY_PASSWORD`

Do not expose, regenerate, replace, or modify signing credentials.
The final Android APK must be signed with the owner's permanent signing key.
Verify the actual APK signature and report its SHA-256 certificate fingerprint for comparison with the Build & Signing Manager.
If signing fails, report the precise non-secret failure. Never substitute a temporary signing key.
6. Complete only essential Build 21 verification
Run the existing required release and simulation checks on the exact Build 21 release commit.
Do not regenerate simulation baselines merely to make tests pass.
If a baseline legitimately changes, retain the previous baseline and document the reason before approving its replacement.
Do not launch redundant test suites or duplicate CI runs.
If a check fails, distinguish an outdated test expectation from an actual functional defect. Repair only genuine release-blocking problems necessary to produce a working playtest build.
Do not spend the remaining allowance on optional validation, unrelated improvements, or extensive refactoring.
7. Build and deliver all three platforms
Produce:

* Android: Installable Build 21 APK.
* Windows: Playable Build 21 executable/package.
* Linux: Playable Build 21 package.

Use the established GitHub release workflow.
Place the completed files on the game's normal GitHub Releases page, clearly labeled:
My Medieval Life — Build 21
The owner must be able to open GitHub, identify the newest build, and download the playable files without searching through Actions logs.
Provide the direct GitHub release-page link.
Do not publish to Steam, Google Play, or another storefront.
Preserve the existing release visibility and access settings. Do not change repository visibility.
Include the existing save-backup and reinstall instructions because Build 21 uses a different permanent Android signing certificate from Build 20.
8. Final report and stop
When the builds are complete, provide one concise report containing:

* Build 21 release-page URL.
* Android APK, Windows, and Linux artifact names.
* Final commit SHA.
* CI and build results.
* Android signing certificate SHA-256 fingerprint.
* Any known playtest limitations.
* Location of the Build 22 mini-build backlog.
* Preservation branch and commit references for unfinished work.

Then stop.
Do not begin Build 22, another expansion, additional polish, or another development round.
FINAL OWNER PRIORITY
Preserve the unfinished work. Freeze the scope. Finish the essential checks. Sign and package Build 21. Put the playable files on GitHub Releases. Give me the link. Stop.
We are not abandoning the four deferred features. We are moving them into a controlled Build 22 mini-build so the owner can finally playtest Build 21 before the weekly allowance resets.
Execute immediately.
