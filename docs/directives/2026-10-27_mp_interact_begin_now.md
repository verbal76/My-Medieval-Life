# BEGIN MULTIPLAYER INTERACTION DEVELOPMENT NOW (owner directive, MP-INTERACT-01, Expansion 20, 2026-10-27)

Amends the schedule (not the release requirements) of `docs/directives/2026-10-27_multiplayer_interaction_release_blocker.md`.
Received in the session of 2026-10-27, verbatim:

MY MEDIEVAL LIFE

OWNER DIRECTIVE — BEGIN MULTIPLAYER INTERACTION DEVELOPMENT NOW

MP-INTERACT-01 | EXPANSION 20 | MANDATORY RELEASE BLOCKER

I am amending the development schedule, not the release requirements.

Previously, I directed that the multiplayer interaction correction be completed as the final integration batch.

That instruction remains in effect.

However, I do not want the multiplayer worker sitting idle while other workers finish independent tasks.

AUTHORIZE DEVELOPMENT OF MP-INTERACT-01 IMMEDIATELY ON AN ISOLATED BRANCH.

The multiplayer worker may develop, test, and complete its corrections in parallel with the remaining Expansion 20 work.

The completed multiplayer changes must still be integrated LAST, after the other approved development batches have been merged.

No Expansion 20 build may be packaged or distributed until this requirement has been integrated and validated.

Do not reopen Mini Build 22.

---

1. CONFIRMED PLAYTEST FAILURE

During my multiplayer playtest:

- I was playing on Windows.
- Another character, Bob, was playing on Android.
- The connection succeeded.
- Bob appeared in the Windows game.
- Bob could move and interact with the world.
- The shared world was functioning.
- I could not select Bob or open a player interaction with him.

I did not test whether Android could initiate interactions with Windows.

I did not test Linux.

Therefore, do not classify this as an Android-only defect.

Treat it as a potentially universal cross-platform player-interaction deficiency.

The objective is for every player to be able to initiate appropriate interactions with every other connected player, regardless of platform or which machine hosts the world.

---

2. DEVELOPMENT AND INTEGRATION ORDER

Create or designate a dedicated worktree and branch for MP-INTERACT-01.

Base the work on the most recent stable Expansion 20 integration commit.

Record the exact starting commit.

Do not work directly in a directory where another worker is running tests.

Other workers may continue:

- Build 19 recovery.
- Judgment System completion and measurement.
- Living Economy development.
- Android usability corrections.
- Messages journal corrections.
- Existing approved Expansion 20 tasks.

The multiplayer worker should begin immediately.

Integration sequence

1. Complete other approved development batches.
2. Integrate those batches into Expansion 20.
3. Validate the combined baseline.
4. Freeze that baseline for the final multiplayer integration.
5. Rebase or merge the multiplayer worker's completed branch onto it.
6. Resolve conflicts without sacrificing either system.
7. Run focused multiplayer and combined regression tests.
8. Confirm the release gate is satisfied.
9. Present the results for release readiness.

Do not repeatedly rebuild the multiplayer correction from scratch whenever another worker commits.

Use normal Git integration and focused conflict resolution.

---

3. AUDIT THE EXISTING IMPLEMENTATION FIRST

Before writing new functionality, identify what already exists.

The initial code audit identified these relevant locations:

"game/scripts/main.gd"

- "_find_target()"
- "_find_target_below()"
- "_creature_at()"
- "_tap()"
- "interact()"
- "_beside_player()"
- "_sync_avatars()"
- "target_options"
- "talk_alt"
- "cycle_target()"

"game/scripts/ui/game_ui.gd"

- "show_players()"
- Existing NPC conversation interfaces.
- Existing trade and contract interfaces.
- Existing offer and acceptance controls.

"game/scripts/core/world.gd"

- "player_offer()"
- "player_answer()"
- "offers_to()"
- "offers_from()"
- "player_of_ref()"
- "trade()"
- Existing player identity and ownership systems.

"game/scripts/net/net_actions.gd"

- Network verb authorization.
- Host-side validation.
- Player-reference decoding.
- Guest action routing.

Existing multiplayer tests

- "multiplayer_c_test.gd"
- "net_c_test.gd"
- "net_family_test.gd"
- "net_ui_test.gd"
- Existing host/guest integration tests.

Audit these and any additional relevant files.

Identify which gameplay functions exist, which are accessible through the interface, and which require additional development.

Do not confuse successful backend tests with working player-facing interaction.

---

4. UNIFIED PLAYER TARGETING

A connected human player must be a valid interaction target.

This must work through the same normal input system used to select NPCs and objects.

When a player approaches another player's character, the game must recognize that character as an available interaction target.

Requirements:

- Human players appear in the normal interaction target selection.
- Human players have stable identities.
- Targeting identifies the correct character.
- The selected player's name appears correctly.
- Targeting respects interaction distance.
- Targeting respects the appropriate map level.
- Disconnected or inactive characters cannot be incorrectly targeted.
- A player cannot accidentally select themselves.
- Character movement does not cause incorrect player selection.
- Nearby NPCs and objects do not make human players inaccessible.
- Multiple nearby human players can be selected individually.
- Target selection remains deterministic where required.

Do not merely add a generic button that opens a list of all connected players.

Players should be able to interact with the actual character standing in the world.

The existing player list may remain available as a supplementary interface.

---

5. INPUT REQUIREMENTS FOR ALL THREE PLATFORMS

Android

The player must be able to:

- Tap another player's character.
- Select them through the normal interaction controls.
- Use the Talk button to interact.
- Cycle to another nearby player using Next.
- Open the appropriate player interaction menu.
- Read and respond to incoming requests.
- Accept or decline offers without losing their place in the world.

Touch targets must remain usable on an actual phone.

Preserve the recent Android HUD and action-button improvements.

Do not reintroduce oversized menus that obstruct gameplay.

Windows

The player must be able to:

- Left-click another player's character.
- Select another player using the existing keyboard interaction controls.
- Use the existing target-cycling controls.
- Open the player interaction menu.
- Initiate and respond to multiplayer actions.

Preserve ordinary click-to-move behavior when clicking empty ground.

Linux

Linux must provide the same functionality as Windows.

Do not assume that Windows success automatically proves Linux functionality.

Verify the Linux export and native input behavior.

Controllers

Using the existing controller scheme, verify:

- Target selection.
- Target cycling.
- Opening player interactions.
- Navigating interaction menus.
- Accepting and declining requests.
- Returning to gameplay.

Do not require a mouse or touchscreen for controller users.

All input methods must invoke the same underlying authoritative gameplay actions.

---

6. PLAYER-TO-PLAYER INTERACTION MENU

When one player selects another, open an appropriate interaction interface.

The menu should identify the selected player by name.

It should expose the interactions supported by the approved game systems.

Audit and complete the following:

Conversation

Players must have an appropriate way to communicate directly through the multiplayer interface.

Do not present NPC-generated dialogue as though a human player said it.

If an actual text-chat system is not already present, implement the smallest appropriate player-to-player text communication mechanism, without inventing voice-chat infrastructure or allowing chat text to trigger NPC simulation decisions automatically.

Gifts

Players must be able to offer items.

The recipient may accept or decline.

The item must transfer only once and only when accepted.

Use the existing inventory and consent systems.

Trading

Players must be able to propose an exchange of goods and currency.

Both players must see the terms.

The recipient must be able to accept or decline.

Use the existing transaction rules and inventory system.

Contracts

Players must be able to access applicable approved contract functions.

Where supported, they should be able to propose and negotiate:

- Item or service.
- Quantity.
- Price.
- Contract terms.
- Acceptance or refusal.

Do not introduce unapproved economic policies.

Use the existing contract architecture and the approved negotiated-procurement design.

Relationships and family

Expose existing approved player-to-player relationship functionality.

This includes the consent-based partnership and family systems already implemented.

Both participants must agree to interactions requiring mutual consent.

Do not apply NPC courtship decision logic to human players.

Other applicable gameplay interactions

Audit existing approved player-to-player actions and make them accessible where appropriate.

Do not invent an entirely new multiplayer gameplay system when an existing function can be reused.

---

7. SECURITY AND HOST AUTHORITY

The host remains authoritative over the shared world.

Do not weaken the existing multiplayer security model.

The current network implementation rejects requests that attempt to manipulate another player's ownership or identity.

Those protections must remain.

Explicit player-to-player interactions should use narrowly authorized request types that identify the intended recipient without granting control over that recipient.

Ensure:

- Players cannot spend another player's money.
- Players cannot remove another player's inventory without authorized gameplay consequences.
- Players cannot accept an offer on someone else's behalf.
- Players cannot impersonate another character.
- Players cannot alter another player's contracts directly.
- Players cannot bypass interaction distance.
- Players cannot exploit disconnects to duplicate transactions.
- Players cannot submit arbitrary methods or unauthorized world changes through networking.

Distinguish a legitimate request directed to another player from an unauthorized operation performed as another player.

Do not simply remove the existing player-reference security checks.

---

8. TRANSACTION INTEGRITY

For player-to-player economic interactions, preserve the existing conservation rules.

Verify:

- Items transfer once.
- Coins transfer once.
- Both parties receive the correct result.
- Declined offers change neither inventory.
- Expired offers cannot be accepted.
- Disconnects cannot create duplicate transactions.
- Simultaneous requests cannot double-spend.
- Stale offers are revalidated before settlement.
- Save/load preserves applicable pending obligations.
- Ownership records remain accurate.
- Host and guest synchronize correctly after settlement.

Reuse the same inventory, currency, contract, and ownership records as the rest of the game.

Do not create a separate multiplayer economy.

The Living Economy and Judgment System must continue using their existing approved architecture.

---

9. PLAYER CONSENT AND NOTIFICATIONS

The receiving player must know when another player requests an interaction.

For actions requiring consent:

1. Player A selects Player B.
2. Player A chooses an action.
3. Player A enters applicable terms.
4. Player B receives the request.
5. Player B reviews the request.
6. Player B accepts, declines, or negotiates where supported.
7. The host validates and applies the result.
8. Both players receive confirmation.
9. Applicable records are preserved.

Incoming requests must not silently execute.

Notifications must not obstruct gameplay unnecessarily.

Use the existing compact notification system and Messages journal where appropriate.

If a player is busy using another interface, the request should remain accessible until it is answered or expires under existing rules.

Do not pause the entire multiplayer world while someone considers a request.

---

10. CROSS-PLATFORM VALIDATION MATRIX

The correction must cover all three platforms.

Host| Guest
Android| Android
Android| Windows
Android| Linux
Windows| Android
Windows| Windows
Windows| Linux
Linux| Android
Linux| Windows
Linux| Linux

For every combination, test interactions in both directions.

At minimum:

- Host initiates an interaction with guest.
- Guest initiates an interaction with host.
- The correct character is selected.
- Interaction menus open correctly.
- Requests reach the intended recipient.
- Accept and decline function correctly.
- Both players see the result.
- World state remains synchronized.
- Currency and inventory remain conserved.

Where automated platform testing is available, use it.

Where actual devices are required, identify the remaining tests explicitly.

Do not claim real-device validation from simulated screen sizes or Linux loopback tests.

Also test multiple guests interacting with the host and with one another.

---

11. TEST THE ACTUAL GAMEPLAY INTERFACE

This requirement is critical.

The existing multiplayer implementation passed extensive automated tests even though I could not click Bob in the game.

That must not happen again.

Create integration tests that exercise:

Input → Target detection → Character selection → Interaction menu → Network request → Host validation → Recipient response → World update → UI confirmation.

Tests must not begin by directly calling "player_offer()" and then conclude that the interface works.

Those backend tests are useful, but insufficient.

Include specific regressions for:

- Another player beside an NPC.
- Another player beside a workstation.
- Another player beside a market stall.
- Multiple human players standing together.
- Players moving while being selected.
- Target cycling.
- Different map levels.
- Disconnected players.
- Reconnecting players.
- Android touch selection.
- Windows mouse selection.
- Linux mouse selection.
- Controller selection.

Verify that none of these cases makes another player impossible to select.

---

12. SINGLE-PLAYER COMPATIBILITY

Do not damage single-player gameplay.

In particular:

- Normal NPC dialogue continues working.
- Existing NPC trading continues working.
- Existing contracts remain functional.
- Player interaction controls behave normally.
- No unnecessary multiplayer UI appears when playing alone.
- Single-player simulation results remain unchanged unless an explicitly authorized correction requires otherwise.
- Saved games remain backward compatible.

Do not introduce a second NPC interaction engine to solve human-player selection.

Share infrastructure where appropriate while preserving the distinction between human and NPC decisions.

---

13. TESTING EFFICIENCY

Do not run the entire simulation campaign after every small interface correction.

Use this sequence:

1. Audit.
2. Implement player targeting.
3. Run focused targeting tests.
4. Implement menu access.
5. Run interface tests.
6. Connect existing consent mechanics.
7. Run focused multiplayer network tests.
8. Implement any missing approved interaction functions.
9. Verify transaction conservation.
10. Integrate with the completed Expansion 20 baseline.
11. Run the combined regression and simulation gates once on the final integrated commit, unless actual code changes invalidate that evidence.

Reuse applicable passing test evidence.

Do not regenerate existing systems unnecessarily.

Preserve deterministic behavior.

---

14. DOCUMENTATION AND TRACKING

This is already registered as:

MP-INTERACT-01

The owner directive is already saved at:

"docs/directives/2026-10-27_multiplayer_interaction_release_blocker.md"

Do not create a duplicate requirement.

Update that requirement's implementation status and evidence as work progresses.

Add the dedicated multiplayer worker and branch to the current development handoff.

Record:

- Starting commit.
- Files changed.
- Implemented functions.
- Missing functions discovered.
- Tests added.
- Tests passed.
- Known limitations.
- Integration dependencies.
- Final merge readiness.

Checkpoint progress before context compaction, which typically occurs around 80% of the session context.

Preserve sufficient recovery information so a restarted session can continue without reopening established owner decisions.

---

15. FINAL INTEGRATION AND RELEASE RESTRICTION

The multiplayer worker starts now.

The correction is developed independently while other approved Expansion 20 work continues.

When those workstreams finish, multiplayer becomes the final integration batch.

Before an Expansion 20 release can proceed, confirm:

- Player targeting works.
- Android interaction works.
- Windows interaction works.
- Linux interaction works.
- Host-to-guest interaction works.
- Guest-to-host interaction works.
- Guest-to-guest interaction works.
- Approved interactions are accessible.
- Consent functions correctly.
- Transactions conserve currency and goods.
- Saves and reconnects remain valid.
- Relevant regression tests pass.
- Single-player gameplay remains intact.
- Any remaining real-device validation is disclosed to the owner.

NO EXPANSION 20 BUILD MAY BE PACKAGED OR RELEASED UNTIL MP-INTERACT-01 IS INTEGRATED AND VALIDATED.

This includes private APK, Windows, and Linux playtest builds.

Do not reopen Build 22.

Do not publish without owner approval.

---

FINAL OWNER INSTRUCTION

I do not want the multiplayer worker waiting until everything else finishes before beginning development.

START MP-INTERACT-01 NOW ON ITS OWN BRANCH.

Let the other workers continue.

Finish the multiplayer correction in parallel.

Integrate it last.

The goal is simple:

If two players can see one another in My Medieval Life, they must be able to select one another and use the approved multiplayer interaction systems regardless of whether they are playing on Android, Windows, or Linux.

A shared world without functioning player-to-player interactions is not complete multiplayer.

Proceed with development immediately.
