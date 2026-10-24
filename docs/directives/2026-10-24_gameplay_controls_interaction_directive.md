# Owner directive, 2026-10-24: master gameplay, controls and interaction improvement directive

Saved verbatim from the session. Two images were supplied with it: the owner's Android screenshot (mining beside a highlighted
ore deposit, the "Mining" bar over the character, the nine bottom actions), saved as
`docs/gameplay_polish/reference/android_mining_hud_2026-10-24.png`; and a pin-tumbler lock cutaway illustration (the mechanical
reference for the lockpicking minigame, a third-party diagram), kept with the work items in the git-ignored
`private-assets/references/pin_tumbler_lock_reference.gif`.

---

MY MEDIEVAL LIFE — MASTER GAMEPLAY, CONTROLS AND INTERACTION IMPROVEMENT DIRECTIVE

OWNER PRIORITY AND SCHEDULING

This directive consolidates all recently identified Android, PC, controller, workstation, harvesting, progress indicator, and lockpicking improvements.

Record all requirements in the tracked development backlog now.

Multiplayer remains the active development priority. Do not stop or restart the current multiplayer development agent, interfere with Batch A1, alter the frozen Build 19 release, or create conflicting changes in the multiplayer branch.

Schedule this work as a dedicated Gameplay and Controls Polish batch at the earliest safe integration point after the multiplayer player-action architecture is stable, and before beginning Expansion 20.

Independent visual or input improvements may be developed earlier if they can be safely isolated and verified without disrupting multiplayer.

Do not wait for my personal playtesting to authorize normal development progression.

Do not produce another lengthy planning exercise instead of completing the authorized work.

---

1. WORKSHOP ANVIL INTERACTION FIX

On Android, the visible anvil is located on a table, but the game currently associates the anvil interaction with the nearby woodpile.

I must tap the woodpile to operate the anvil.

This is incorrect.

Requirements:

1. Center the anvil's touch interaction target on the actual visible anvil.
2. Ensure the interaction corresponds to the correct workstation object.
3. Route the character to a valid standing position beside the anvil.
4. Tapping the woodpile must not activate the anvil.
5. Preserve the existing workshop artwork and layout.
6. Preserve all existing crafting functionality.
7. Check for similar mismatches between workstation graphics and interaction targets elsewhere.
8. Validate Android touchscreen interaction separately from PC mouse interaction.

Do not solve this by moving the anvil artwork to the woodpile.

---

2. INTERACTIVE PIN-TUMBLER LOCKPICKING MINIGAME

Replace the current passive lockpicking progress meter with a playable minigame.

The supplied pin-tumbler lock illustration is the mechanical reference.

Visual presentation

Show a cutaway lock mechanism with multiple vertical pin chambers.

Each chamber contains:

- A visible spring.
- A movable tumbler or pin assembly.
- A clearly indicated setting position.
- Visible upward movement.
- A wobble or warning animation before a pin falls.
- A falling animation if the player fails to catch it.

A lockpick replaces the key.

The lockpick should appear to lift or support the pins.

Use the existing My Medieval Life pixel-art style. Do not copy the reference image as finished game art.

Core gameplay

The minigame is a simple, satisfying, whack-a-mole-style timing challenge.

Pins rise toward their setting positions.

An unstable pin begins wobbling before falling.

The player taps or presses the corresponding input to catch and set that pin.

Other pins may become unstable while the player is working.

The objective is to keep the required pins set long enough to open the lock.

Successful taps must produce immediate visual and audible feedback.

The minigame must be based on readable, predictable visual timing rather than hidden randomness.

Difficulty

Easy locks:

- Start with approximately four tumblers.
- Require roughly six to eight successful taps.
- Use slow wobbling.
- Provide generous reaction time.
- Introduce one unstable tumbler at a time initially.
- Avoid excessive penalties for a missed tap.

More difficult locks:

- May have five or six tumblers.
- Wobble faster.
- Provide shorter reaction windows.
- Introduce multiple unstable pins simultaneously.
- Require greater coordination.

Difficulty must not be increased by shrinking touch targets.

Missing a pin can cause it to slip and require another attempt, but routine mistakes should not cause unnecessarily punishing full resets.

Preserve existing skill, tool, lock difficulty, crime, ownership, and reputation mechanics.

Touchscreen controls

Each tumbler must have a distinct, non-overlapping touch region.

One tap must never trigger two tumblers.

The targets must remain large enough for comfortable play on Android, including the Pixel 10 Pro XL.

Support smaller Android screens without sacrificing readability.

Prevent touches from passing through the minigame into the world.

Gamepad controls

Each tumbler receives a dedicated gamepad input.

Four-tumbler locks:

- A
- B
- X
- Y

Five- or six-tumbler locks may additionally use LB and RB.

Display the appropriate input prompt beneath each tumbler.

Support equivalent button labels on other controller layouts.

The player must not have to move a cursor between tumblers during the timing challenge.

Support rapid alternating button presses without dropped or duplicated inputs.

Use sensible keyboard equivalents for PC players.

Do not introduce more simultaneous tumblers than can be comfortably controlled.

Multiplayer integration

The minigame is local to the player operating the lock.

It must not pause the shared multiplayer world.

The host remains authoritative over lock state, success, contents, ownership, and consequences.

Two players must not be able to duplicate rewards by interacting with the same lock.

Cancellation, interruption, and disconnects must leave the lock in a valid state.

---

3. ANDROID MOVEMENT CONTROL OPTIONS

Add an Android settings option allowing the player to select either:

Tap-to-move: The existing movement behavior.

Virtual joystick: A left-side on-screen thumbstick for continuous movement.

Preserve tap-to-move as the default for existing players unless they choose otherwise.

Virtual joystick requirements:

- Lower-left screen placement.
- Comfortable thumb operation.
- Correct directional movement.
- Consistent movement speed.
- Proper interaction with existing collision and navigation rules.
- No interference with menus, dialogue, inventory, or minigames.
- Correct scaling across supported screen sizes.
- Proper handling of Android safe areas.
- Hide or disable when the current interface requires it.

Do not change the underlying movement mechanics simply to introduce another input method.

Store the preference per player or device as appropriate.

---

4. ANDROID ACTION BUTTON LAYOUT

The current Android interface displays nine actions across the bottom of the screen:

Run, Use, Gather ON, Attack, Fire, Pack, Skills, Map, and Menu.

The labels are too small and spread across the screen, making them difficult to read.

Redesign the action controls into two vertical columns along the right side.

Suggested organization:

Column 1:

- Run
- Gather
- Fire
- Skills
- Menu

Column 2:

- Use
- Attack
- Pack
- Map

This is a proposed arrangement, not permission to remove or change any actions.

Requirements:

- Preserve every existing action.
- Improve text readability.
- Use comfortable touch targets.
- Prevent overlap between buttons.
- Keep the center of the screen available for gameplay.
- Do not obscure the status HUD in the upper left.
- Do not obscure dialogue, contextual prompts, or critical world information.
- Respect Android screen insets.
- Accommodate supported display sizes and orientations.
- Keep contextual controls stable rather than constantly shifting their positions.

The Gather control must clearly indicate its current state.

If gathering is enabled, display an unambiguous active state.

If gathering is disabled, show that clearly.

Do not merely move the existing tiny labels into a different arrangement.

Use the supplied Android screenshot as the visual baseline.

Preserve the overall look and feel of the game.

---

5. FIX ANDROID PICKAXE ANIMATION

On Android, the character successfully mines ore but does not visibly swing the pickaxe.

The character stands motionless while the mining progress bar fills.

On PC, the pickaxe-swinging animation works.

Fix the Android animation.

Requirements:

- Display the correct pickaxe-swinging animation during mining.
- Keep the animation synchronized with the actual work activity.
- Preserve the current Android continuous mining behavior.
- Do not require repeated tapping to make the animation play.
- Check animation state, activity state, facing direction, equipment visibility, and platform-specific code paths.
- Ensure the animation stops when mining stops.
- Confirm other long-duration work animations are functioning correctly.

The animation fix must not change mining speed, resource production, or harvesting rules.

---

6. CONTINUOUS HARVESTING ON ALL PLATFORMS

Android currently provides a better mining interaction than PC.

On Android, I can select a rock, activate Harvest, and watch the character continue mining without repeatedly tapping.

On PC, repeated inputs are required.

Preserve the Android behavior and make continuous harvesting available across all platforms.

Add a gameplay setting with two options:

Continuous harvesting: One interaction starts the activity and the character continues until the task ends or is interrupted.

Manual harvesting: Each input initiates one work action.

Apply the setting to appropriate repetitive activities, including mining and other long-duration gathering chores.

Do not automatically apply it to actions where repetition would create unintended consequences.

Requirements:

- Continuous work must use normal simulation timing.
- No increase in resource output per simulated hour.
- Preserve tool durability and stamina costs.
- Preserve skill progression.
- Preserve resource depletion.
- Stop correctly on cancellation, movement, danger, exhaustion, invalid targets, or other existing interruptions.
- Do not duplicate rewards.
- Do not leave invisible work running after the player stops.
- Do not introduce idle resource generation exploits.

In multiplayer, track each player's activity independently and validate resource production through the authoritative host.

---

7. STANDARDIZE THE ANDROID ACTIVITY PROGRESS BAR

The Android mining progress display is significantly better than the current PC version.

The Android screenshot shows a labeled progress bar directly above the character's head.

For example:

Mining — green progress bar.

The PC version currently uses a small white progress indicator near the middle of the screen.

Replace the PC presentation with the Android-style overhead activity indicator.

Use this design consistently across Android, Windows, and Linux.

Activity indicator requirements

1. Position the progress bar directly above the working character.
2. Anchor it to the character so it follows their position.
3. Show a readable label identifying the activity.
4. Show the progress of the current work cycle.
5. For continuous work, reset the fill at the start of each new work cycle.
6. Hide the indicator immediately when the activity ends.
7. Preserve correct timing and work completion behavior.
8. Prevent the indicator from covering important interface elements where practical.
9. Maintain readable scale across supported resolutions.
10. Avoid displaying redundant progress indicators for the same activity.

Apply this to suitable timed activities such as:

- Mining.
- Woodcutting.
- Farming.
- Crafting.
- Construction.
- Other established timed work actions.

Do not change the underlying activity mechanics simply to standardize the visual presentation.

Multiplayer behavior

Each player must have their own activity state and progress indicator.

Other players should be able to understand what a nearby character is doing.

Avoid clutter from unnecessary distant indicators.

The overhead indicator must reflect authoritative activity progress and must not create independent resource-generation logic.

Visual reference

Use the supplied Android screenshot showing the player mining beside a highlighted ore deposit.

The green bar labeled "Mining" above the character is the preferred presentation.

Preserve its clarity and placement.

---

8. CROSS-PLATFORM INPUT AND GAMEPLAY CONSISTENCY

Android, Windows, Linux, Steam Deck, keyboard, mouse, touchscreen, and gamepad should access the same gameplay systems.

However, identical input layouts are not required.

Each platform should use controls appropriate for that device.

Where Android currently has a better interaction, preserve that design and extend it to other platforms.

Where PC has a working animation or interaction that Android lacks, correct the Android implementation.

Do not sacrifice Android gameplay quality to achieve cross-platform consistency.

Do not duplicate core simulation logic for different input methods.

Separate input handling and presentation from authoritative gameplay actions wherever practical.

---

9. TESTING AND ACCEPTANCE

Test the changes in logical groups.

Workstation interaction

- Tapping the visible anvil activates the correct workstation.
- Tapping the woodpile does not.
- Character navigation reaches the correct interaction position.

Lockpicking

- Easy locks can be opened with roughly six to eight successful taps.
- All tumblers have independent inputs.
- One touch cannot trigger adjacent tumblers.
- Gamepad mapping works correctly.
- Difficulty scales without shrinking touch targets.
- Cancelled attempts cannot falsely succeed.
- Rewards cannot be duplicated.
- Ownership and crime consequences remain correct.

Android controls

- Tap-to-move remains functional.
- Virtual joystick movement works correctly.
- The right-side action layout is readable.
- All existing actions remain accessible.
- No controls overlap.
- Settings persist appropriately.

Harvesting

- Android pickaxe animation plays during mining.
- Continuous harvesting works on supported platforms.
- Manual harvesting remains available.
- Resource output and timing remain unchanged.
- Interruptions terminate work correctly.
- No duplication or resource exploits occur.

Progress indicators

- Overhead activity bars display correctly on all platforms.
- Labels identify the actual activity.
- Continuous work resets the bar each cycle.
- Indicators disappear when work ends.
- Multiplayer players display independent activity progress.

Run targeted tests during development and comprehensive regression testing at integration checkpoints.

Do not weaken existing determinism, conservation, economy, or multiplayer tests.

Clearly distinguish automated verification from physical-device testing.

---

10. EXECUTION AND REPORTING

Immediately:

1. Register all requirements and acceptance criteria.
2. Preserve the supplied reference images and screenshots with the work items where possible.
3. Identify dependencies on the active multiplayer architecture.
4. Assign the work to the earliest safe implementation batch.
5. Do not interrupt the current multiplayer agent.
6. Do not begin Expansion 20 before the approved multiplayer and gameplay integration priorities are addressed.

When implementation begins, complete the related work coherently rather than repeatedly revisiting the same systems.

Report:

- Completed items.
- Remaining items.
- Affected platforms.
- Test results.
- Device verification still needed.
- Genuine unresolved decisions.

Do not require my personal playtesting as a development gate.

Do not publish a public release or incur paid service costs without authorization.

The objective is to combine the best Android and PC gameplay behaviors, improve touch and controller usability, and preserve the established My Medieval Life experience while multiplayer development continues.
