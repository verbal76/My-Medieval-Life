Owner directive, 2026-10-26, verbatim.

MY MEDIEVAL LIFE — BUILD 22 AND EXPANSION 20 EXECUTION AUTHORIZATION

OWNER DIRECTIVE — OCTOBER 26, 2026

This directive supersedes the October 24 implementation hold.

I am authorizing active development.

Execute in the following sequence:

1. Complete the Build 22 mini-build.
2. Include all seven items from today's Build 21 playtesting.
3. Integrate, validate, and prepare Build 22 for private testing.
4. Immediately begin Expansion 20 implementation.

Do not stop after documentation, planning, or a preliminary audit.

Do not ask for another general authorization to begin Expansion 20.

PHASE 1 — BUILD 22 MINI-BUILD

Complete the deferred work identified in:

"docs/backlog/BUILD22_MINI_BUILD.md"

Include all five deferred work areas:

1. Business desk and courier integration.
2. Merchandise previews on business tables.
3. Farmers visibly tending their fields.
4. Interactive lockpicking minigame.
5. Children and correct family relationships for player-to-player marriages.

The business desk and courier are separately tracked requirements.

Preserve the unfinished implementation on "wip/build22-business-desk", commit "e25eec9". Integrate and complete that work. Do not discard or restart it.

Preserve existing business transactions, inventory, courier behavior and ownership rules.

Tables display actual merchandise previews. They are not new pickup containers.

Farmer animations must correspond to genuine fieldwork, without changing farming productivity or simulation timing unintentionally.

The lockpicking minigame must follow the previously approved pin-tumbler design and support touch, mouse, keyboard and gamepad.

Player children require correct parent relationships, household membership, adoption records, save/load persistence and backwards-compatible migration.

Do not implement a superficial workaround that loses family relationships or corrupts old saves.

PHASE 2 — INCLUDE TODAY'S SEVEN PLAYTEST ISSUES

Use the exact owner reports and requirement records created today as the authoritative specifications.

Include:

1. Mine frame.
2. Encyclopedia tools.
3. Being-hunted warning.
4. Controller Max button.
5. Booth rental defect.
6. Booth spacing.
7. Armour not displaying.

These are part of the Build 22 scope, not a separate future release.

For each:

- Read the existing issue record.
- Identify the root cause.
- Implement the requested behavior.
- Add focused regression coverage where applicable.
- Verify the visual or gameplay result.
- Preserve related systems and existing owner decisions.

Do not invent new requirements or substitute your own interpretation where the existing playtest report already specifies the desired outcome.

Where visual confirmation requires my device, mark that verification outstanding rather than claiming it passed.

PHASE 3 — BUILD 22 INTEGRATION AND VALIDATION

Integrate all Build 22 changes on a controlled release branch.

Maintain one consistent source commit for Android, Windows and Linux.

Verify:

- All new gameplay and interface behavior.
- Save/load integrity and migration from Build 21.
- No lost inventory, currency, items or family relationships.
- Single-player simulation integrity.
- Existing multiplayer gameplay parity.
- Controls and interface compatibility.
- No unintended NPC simulation changes.
- Deterministic behavior where required.
- No regressions in existing economy or relationship systems.

Reuse passing test evidence for unchanged code.

Run focused tests for changed systems and the established necessary release gates.

Do not launch redundant long simulation campaigns just for reassurance.

Use GitHub Actions wherever practical.

Build 22 private playtest

After successful applicable release gates, package:

- Android APK.
- Windows executable.
- Linux build.

Use the established permanent Android signing key.

Verify that Build 22 can update Build 21 without losing the existing save.

Include checksums, source commit and concise tester notes.

Prepare the packages as an access-controlled private playtest release.

No public publication, Steam deployment or marketplace distribution.

Do not label unverified real-device behavior as fully tested.

PHASE 4 — BEGIN EXPANSION 20

Once Build 22 has been completed and its private playtest packages prepared, begin Expansion 20 implementation immediately.

You have my authorization to begin substantive work, not merely to prepare plans.

Use:

"docs/expansion20/X20_OPEN_ITEMS.md"

and the authoritative requirements register:

"docs/requirements/requirements.json"

Expansion 20 includes the reconciled 67 open approved items, including gameplay polish, Android usability, interactions, visual improvements, unfinished work carried forward, and the existing Living Economy foundations.

Before implementation, reconcile completed Build 22 items so they are not implemented a second time.

Use the existing requirements, approved designs, dependencies and priorities.

Living Economy

Preserve the existing Living Economy foundations, formulas and conservation requirements.

Integrate and test the existing implementation rather than rebuilding it.

Do not silently change previously approved economic formulas or introduce currency or item creation.

The Living Economy must pass its required simulation, persistence, determinism and conservation gates before being enabled in a test build.

Any unresolved owner-controlled economic policy or numerical value must be presented specifically rather than guessed.

The authorization to begin Expansion 20 does not authorize unsupported changes to the economic model.

Expansion execution

Break the remaining work into coherent, testable batches.

Use parallel agents only where tasks are genuinely independent and integration ownership is clear.

Preserve completed Build 18, 19, 20 and 21 features.

Do not reopen established reputation, family, judgment or simulation designs without a demonstrated defect.

Maintain the requirements register and recovery handoff.

PHASE 5 — DEVELOPMENT DISCIPLINE

Correct "docs/CURRENT_DEVELOPMENT_STATE.md" so the obsolete Build 18 and 19 next-action lists are clearly historical.

Keep the current Build 22 and Expansion 20 execution status at the top.

Maintain accurate branch, commit, test and worker records.

Checkpoint before approximately 80% context usage.

Do not repeatedly stop for routine implementation questions.

You have authority to make minor reversible engineering decisions consistent with existing requirements.

Major design changes, removal of approved features, changes to fundamental economic policies and public publication still require owner approval.

FINAL EXECUTION ORDER

FIRST: Complete all five deferred Build 22 work areas.

SECOND: Complete all seven newly reported playtest issues.

THIRD: Integrate, validate and package Build 22 for private testing.

FOURTH: Begin substantive Expansion 20 implementation immediately, without waiting for a separate general go-ahead.

Preserve all prior work, existing saves, simulation integrity and approved designs.

Do not use the old October 24 hold as a reason to stop.

Begin execution now.
