# MY MEDIEVAL LIFE — AUDIT DECISIONS AND CONTINUED DEVELOPMENT AUTHORIZATION

Owner directive, 2026-10-24, verbatim.

I have reviewed the implementation audit.
The following decisions are approved.
1. Single-player baseline changes
You are authorized to update the single-player regression baseline for intentional, approved gameplay changes, provided that:

* You identify the exact reason for every difference.
* You verify the difference against the actual implementation.
* You confirm that unrelated simulation values remain unchanged.
* You preserve the previous baseline for comparison.
* You document each authorized baseline change.
* You do not weaken tests, ignore unexplained differences, or automatically accept new failures.

Specifically, investigate whether the rusty starting axe is the sole cause of the current item-count mismatch.
If confirmed, update the expected baseline appropriately and rerun G0.
If other unexplained differences exist, repair or escalate them.
2. Checkpoint 1 private APK
You are authorized to prepare a private Android Checkpoint 1 playtest build once the identified quick wins are complete and the required tests pass.
Include the completed Android and gameplay fixes.
Run the complete applicable test inventory, including the suites omitted from the Build 19 release workflow.
Preserve Build 19 unchanged.
Do not merge incomplete multiplayer functionality into a public release.
The private build may contain inactive multiplayer foundations, but unfinished multiplayer must not be exposed as a working feature.
Use the existing controlled build and signing process.
Do not publish publicly.
3. Development priority
Multiplayer remains the primary development milestone.
Finish the current quick-win polish checkpoint and produce the private APK when ready.
Then resume Multiplayer Batch B without waiting for every Checkpoint 2 improvement to be completed.
Checkpoint 2 and the lockpicking minigame remain approved backlog items.
Implement independent polish work alongside multiplayer only when branch isolation, agent availability, and integration safety permit it.
Do not introduce unnecessary parallel agents or duplicate work.
4. Remaining quality-of-life items
Preserve the complete audited backlog.
Nothing is cancelled or forgotten.
Prioritize:

* Off-screen action buttons.
* Anvil prompt interaction distance.
* Indoor wall defects.
* Bandit camp appearance.
* Building entrances and paths.
* Virtual joystick.
* Continuous harvesting.
* Consistent overhead progress indicators.
* Lockpicking minigame.

For the PC progress bar, keep the issue open pending visual verification. Do not block other work over that screenshot.
5. Progress reporting
At each checkpoint, report:

* Changes implemented.
* Changes tested.
* Remaining failures.
* Current G0 status.
* Multiplayer batch and gate status.
* Private APK availability.
* Remaining gameplay backlog.

Do not require my personal playtesting to continue development.
Proceed with Checkpoint 1, validate the baseline, prepare the private Android build, and keep multiplayer moving.
