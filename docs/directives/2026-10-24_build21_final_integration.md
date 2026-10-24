Owner directive, 2026-10-24, verbatim.

MY MEDIEVAL LIFE — BUILD 21 FINAL INTEGRATION, FLIGHT RECORDER AUDIT & PRIVATE PLAYTEST

OWNER AUTHORIZATION — EXECUTE

This is authorization to complete the final, bounded integration and verification work for My Medieval Life Build 21.

The objective is to deliver a playable Windows and Android private test build containing:

1. The completed G2 multiplayer foundation, now accessible through functional host/join controls.
2. Android networking support.
3. Animal synchronization using the existing network architecture.
4. The gameplay corrections previously implemented following the owner's Windows and Android playtesting.
5. An updated and executed in-flight black-box recorder audit covering those gameplay corrections.
6. A complete findings report and updated outstanding-issues register.

This is not authorization for another broad development campaign.

The desired completion point is a game that the owner can install, play, and test on actual devices, with known defects documented rather than automatically repaired.

Proceed without repeatedly requesting permission for routine implementation decisions. Stop only for a genuine architectural blocker, unavailable required signing credentials, a material risk to existing saves or releases, or work that substantially exceeds the agreed scope.

---

1. ESTABLISHED BASELINE — DO NOT REPEAT THE AUDIT

The completed multiplayer G2 milestone is verified.

Branch: "wip/multiplayer-b19"

Final G2 commit: "2b92fa8"

Game-code commit: "36b1e75"

Verified evidence:

- "multiplayer_c_test": 340 checks passed.
- "net_c_test": 35 checks passed.
- "net_g1_test": 44 checks passed.
- "run_tests": 3,598 checks passed.
- "start_test": 523 steps completed.
- Simulation integrity gate passed.
- Single-player deterministic baseline unchanged.

Batches A1, A2, B, and C are complete.

Gates G0, G1, and G2 passed.

Reuse this evidence wherever it remains applicable.

Do not repeat the complete architecture audit, rerun unchanged test suites for reassurance, or reopen completed G2 design decisions.

The previous LAN-readiness assessment already established that the core infrastructure exists.

Relevant systems include:

- "net_session.gd"
- "net_protocol.gd"
- "net_discovery.gd"
- "net_actions.gd"
- "net_sync.gd"
- "main.gd"

Existing networking uses ENet over UDP.

Game port: 47810.

Discovery port: 47811.

The host-authoritative architecture, world transfer, player movement, guest actions, ownership, persistence, and major world synchronization already exist.

Extend these systems. Do not replace them.

---

2. TASK ONE — COMPLETE THE MULTIPLAYER USER INTERFACE

Implement the missing interface necessary to use the existing multiplayer foundation.

Host controls

Add an Open to Friends option to the pause menu of an existing world.

It must:

- Call the existing host functionality.
- Display the host's local IP address and port.
- Support an optional password using the existing networking implementation.
- Show the hosting status.
- Allow the host to close the multiplayer session without damaging the world.
- Display useful errors when hosting fails.

Join controls

Add a Join Game option to the title screen.

It must:

- Display discovered LAN games when discovery works.
- Allow manual IP entry.
- Allow player-name entry.
- Accept a password when required.
- Display connection progress and results.
- Display existing refusal, version mismatch, duplicate-identity, and disconnect messages.
- Allow the guest to leave cleanly.

Use the game's existing visual language.

Do not introduce oversized menus, giant background panels, clipped controls, or mobile layouts that obscure gameplay.

The owner has previously identified oversized UI elements and a giant brown pause-menu background as defects. Do not reproduce those problems.

The controls must be usable on both Windows and Android.

Do not create temporary developer-only menus that will need to be replaced later.

---

3. TASK TWO — ENABLE AND VERIFY ANDROID NETWORKING

Update the Android export configuration to enable the necessary networking permissions.

Android's ordinary INTERNET permission is a manifest permission and generally does not require a runtime approval popup.

Do not invent a permission-request screen for permissions that Android automatically grants.

Use the existing network connection architecture.

Manual IP joining must work even if automatic LAN discovery is unavailable.

Do not spend substantial time implementing Android multicast-lock handling or rebuilding discovery if manual IP joining works.

The first physical playtest will use:

Host: Windows PC

Guest: Pixel 10 Pro XL running Android

Connection: Same home Wi-Fi network

Do not implement phone hosting, internet matchmaking, relay servers, or dedicated servers.

Verify that the required permissions are actually present in the exported APK.

---

4. TASK THREE — COMPLETE ANIMAL SYNCHRONIZATION

The previous audit established that animals are not currently synchronized to guests.

The host simulates animal movement, but guests may see animals frozen at their initial positions.

Correct this using the existing host-authoritative synchronization architecture.

Reuse the current NPC snapshot, entity identity, world-state, and network synchronization patterns wherever appropriate.

Synchronize the animal state necessary for correct guest presentation and interactions, including relevant:

- Identity.
- Position and movement.
- Animation or behavioral state.
- Spawn and despawn events.
- Health, death, and relevant combat state.
- Ownership or pen association where applicable.

Do not duplicate the animal simulation on the guest.

The host remains authoritative.

Do not invent a second animal networking system.

Implement the smallest correct extension of the existing synchronization mechanisms.

If animal synchronization reveals a substantial architectural problem rather than a contained extension, stop that task, document the blocker, and continue only with work that remains safe and independent. Do not silently omit animal synchronization from the final status.

---

5. TASK FOUR — RECOVER THE ORIGINAL GAMEPLAY DEFECT REGISTER

This is a critical part of the assignment.

The owner previously conducted extensive Windows and Android playtesting and identified approximately 17–20 gameplay defects and concerns.

These were discussed and consolidated into development work before the multiplayer G2 milestone.

Do not substitute the multiplayer test results for verification of these gameplay corrections.

Locate the actual source-of-truth records:

- Original owner playtest findings.
- Open-items and punch-list documents.
- Implementation commits.
- Previous handoff and recovery notes.
- Existing issue register.
- Related tests and black-box recorder documentation.

Recover the complete list rather than relying solely on the examples below.

Known examples include:

Interface and visual problems

- Oversized menus and interface elements.
- Giant brown pause-menu background.
- Controls or panels that extend beyond screen boundaries.
- Building edges that characters can walk underneath incorrectly.
- House back doors appearing on roofs.
- Incorrect interior walls, roofs, transparency, or rendering.
- Smithy wall and building-edge problems.
- Incorrect sprite-sheet item identification.
- Bandit camp displaying market stalls instead of the intended crates and campfire.
- Campfire artwork still requiring an owner-approved solution.

Gameplay and interaction problems

- Bandits immediately dying or disappearing.
- Bandits failing to respawn correctly.
- Criminal pursuit and response behavior.
- Incorrect interaction positions or distances.
- Anvil interaction targeting.
- Android tool and pickaxe interaction problems.
- Rusty axe behavior.
- Gift-selection interface behavior.
- Excessively repeated gossip.
- NPC identity, relationship, and family awareness.

These are examples, not an exhaustive or automatically authoritative defect list.

Do not invent missing items or assume that every example was approved for implementation.

For each original issue, establish:

1. Original defect description.
2. Affected platform or platforms.
3. Relevant implementation or correction.
4. Current status.
5. Existing verification evidence.
6. Remaining verification needed.

Distinguish:

- Fixed and verified.
- Implemented but not verified.
- Still open.
- Intentionally deferred.
- Requires owner visual inspection.
- Cannot be established from available evidence.

Preserve existing owner decisions.

Do not silently close issues because code was committed.

---

6. TASK FIVE — COMPLETE THE SKIPPED IN-FLIGHT BLACK-BOX RECORDER AUDIT

The owner specifically requested this audit following the gameplay corrections.

It was skipped during the previous development closeout.

Complete it now.

Purpose

Determine whether the current game behaves correctly after the gameplay repairs, and identify regressions or new problems before Build 21 is handed to the owner.

This is primarily a gameplay and world-simulation audit, not a new multiplayer network-testing campaign.

Prepare the recorder

Inspect the existing black-box recorder and its test coverage.

Reconcile its checks with the actual current implementation.

Update obsolete checks where necessary.

Add focused instrumentation or assertions for the original gameplay defects where those issues can be meaningfully observed automatically.

Prefer extending existing checks and event recording rather than building new testing infrastructure.

Do not preserve obsolete checks merely to avoid editing them.

Do not write tests against old behavior that has intentionally changed.

Coverage

Where supported by the existing architecture, examine:

- World generation integrity.
- Building placement and collision.
- Navigable paths and accessible interactions.
- NPC activity and employment.
- Trading, money, inventory, and resources.
- Villager decision-making.
- Bandit spawning, survival, respawning, and behavior.
- Crime and pursuit behavior.
- Interaction validity.
- Simulation determinism.
- Gameplay regressions introduced by the recent corrections.

For graphical defects, distinguish between what can be checked programmatically and what requires visual inspection.

A passing simulation must not be presented as proof that a sprite, menu, roof, or background looks correct.

Create a concise owner visual-verification checklist for those issues.

Execute simulations

Run three existing deterministic recorder scenarios against the final integrated game code:

1. Standard village simulation.
2. Alternate deterministic seed.
3. Existing heavier or stress-oriented scenario.

Use existing scenario configurations where possible.

If the established recorder uses a different standard run length, retain the established duration rather than inventing a new test campaign.

Do not create an entirely new simulation framework.

Capture detailed logs to files.

Read compact summaries rather than dumping entire logs into the Claude context.

Report results

For every run, report:

- Seed and scenario.
- Duration or simulated days.
- Pass/fail status.
- Recorder warnings.
- Significant anomalies.
- Integrity failures.
- Relevant performance observations.
- New or recurring defects.
- Whether each finding corresponds to an original playtest issue.

Compare results with the last valid baseline where a meaningful comparison exists.

Do not claim a defect is fixed merely because a simulation did not reproduce it.

---

7. DEFECT HANDLING — DO NOT START ANOTHER REPAIR CAMPAIGN

Classify findings into three categories.

Critical blockers

Examples:

- Game cannot launch.
- Host or guest cannot complete the basic connection path.
- Crashes that prevent the intended playtest.
- Save corruption.
- Material loss or duplication of currency or inventory.
- Broken simulation determinism.
- Critical host/guest state corruption.

A confirmed critical blocker may justify a narrowly scoped correction.

For anything substantial, report the defect, cause, and proposed repair before proceeding.

Significant but nonblocking

Examples:

- Major NPC behavioral problems.
- Economic imbalances.
- Broken secondary interactions.
- Repeatable but nonfatal gameplay defects.
- Problems affecting features outside the basic LAN connection test.

Record them for review.

Do not automatically repair them.

Minor

Examples:

- An individual villager failing to purchase a tool.
- Isolated NPC idling.
- Cosmetic problems.
- Minor graphical inconsistencies.
- Noncritical behavioral inefficiencies.

Record and defer.

The owner will decide which nonblocking defects are worth fixing in a later patch.

Do not create multiple agents to investigate separate warnings.

Do not expand the work because the recorder finds interesting problems.

The objective is to discover and document, not eliminate every defect.

---

8. TESTING AND RESOURCE DISCIPLINE

This project already has extensive passing automated evidence.

Reuse it.

Run targeted checks for the changed systems:

- Host/join UI integration.
- Android networking configuration.
- Animal synchronization.
- Relevant recorder changes.
- Changed gameplay code.

Perform one short local connection smoke test using the real game scene and interface where practical.

The owner will perform the actual Windows-to-Android network test.

Do not run broad test suites repeatedly for reassurance.

If a specific change invalidates earlier evidence, rerun the affected checks.

If a critical shared game-core change requires a wider regression gate, run it once and record why.

Keep logs compact.

Avoid redundant agents, repeated audits, speculative redesigns, and unlimited fix/test cycles.

Do not treat every warning as a reason to launch another investigation.

Keep the work on the established development branch and maintain accurate recovery notes.

Because context compaction occurs around 80%, preserve a concise recovery checkpoint before reaching that threshold.

---

9. BUILD 21 — PRIVATE PLAYTEST DELIVERY

Once the integration and recorder audit are complete, prepare Build 21 using the established packaging workflow.

Required platforms:

- Android APK.
- Windows executable package.

Use the same final source revision for both.

Preserve all previous releases.

Preserve existing save files and backups.

Build 21 uses save version 22. Build 20 saves should load forward, but Build 20 cannot open a Build 21 save.

Document this clearly.

Use the established permanent Android signing identity. If credentials are unavailable, stop and request a signing decision.

Do not silently change the signing identity.

Run only necessary packaging, installation, and launcher smoke checks.

Prepare an access-controlled private playtest release.

Do not publish publicly or make artifacts anonymously accessible.

If the established workflow cannot guarantee private delivery, stop and report the options.

Provide:

- Final source commit.
- Build number and version.
- Android APK size and checksum.
- Windows package size and checksum.
- Artifact download locations.
- Relevant test evidence.
- Known limitations.

Do not begin unrelated Linux packaging unless it is required by an established inseparable workflow. This playtest specifically requires Windows and Android.

---

10. OWNER'S REAL-DEVICE TEST

Provide a short, plain-English procedure for the first physical multiplayer test.

The owner will:

1. Back up the existing world or use a separate test world.
2. Start the Windows game.
3. Open the world to friends.
4. Note the displayed local IP address.
5. Start the Android game on the same Wi-Fi.
6. Join using discovery or manual IP entry.
7. Confirm both player characters appear.
8. Move both characters.
9. Perform basic shared-world interactions.
10. Observe NPCs and animals on both screens.
11. Disconnect the guest.
12. Verify the host world remains intact.

Include the Windows Firewall instruction and the UDP ports.

Do not claim physical-device testing passed until the owner actually confirms it.

---

11. FINAL REPORT AND STOPPING POINT

Provide a single consolidated final report containing:

A. Multiplayer integration

What was implemented, what passed, and what remains unverified on physical devices.

B. Gameplay defect reconciliation

The complete recovered owner punch list, with status and evidence for each issue.

C. Flight-recorder results

The three simulation summaries, warnings, significant anomalies, and integrity findings.

D. Outstanding issues

Critical, significant, and minor findings, including issues requiring visual inspection.

E. Build artifacts

Commit, versions, package sizes, checksums, download locations, and signing status.

F. Owner playtest instructions

A concise Windows-to-Android LAN connection and gameplay checklist.

G. Recovery state

Updated handoff, register, branch status, and any deferred work.

Do not claim Build 21 is defect-free.

Do not claim multiplayer is physically verified before the owner tests it.

Do not start Batch D or Batch E beyond the specific LAN integration authorized here.

Do not implement internet multiplayer, relay services, dedicated servers, phone hosting, or unrelated features.

Once the private artifacts and reports are ready, stop all development work and return My Medieval Life to hold status.

Upwardly remains the primary development priority after this delivery.

FINAL OWNER DIRECTIVE

We have already invested in the gameplay corrections, multiplayer foundation, and testing infrastructure.

Now finish the small remaining integration work, verify the gameplay changes with the recorder, document what still needs attention, and put a playable build in my hands.

Do not spend hours trying to make every simulation warning disappear.

I would rather personally discover and prioritize a few remaining problems than burn development resources chasing every theoretical defect before I can play the game.

Complete the bounded work, prepare the private Build 21 playtest, report the evidence, and stop.
