Owner directive, 2026-10-26, verbatim.

MY MEDIEVAL LIFE — FINAL OWNER ANSWERS AND EXECUTION AMENDMENT

OCTOBER 26, 2026 — BINDING OWNER AUTHORIZATION

This amendment supplements the full Build 22 and Expansion 20 directive I just provided.

It answers every outstanding question in your latest message and removes the remaining routine decision blockers.

DO NOT replace or shorten the previous master prompt. Both instructions apply together.

My intention is to complete as much of the approved work as possible, not continually move difficult items into later builds.

1. GO-AHEAD — APPROVED

You have explicit authorization to begin Build 22 immediately.

The October 24 hold is superseded.

Do not ask again whether you have permission to begin development.

You may implement, integrate, test, correct defects, prepare builds, and start the next approved expansion under the established boundaries.

2. BUILD 22 SCOPE — ALL ITEMS INCLUDED

Build 22 includes all six deferred requirements:

1. GP-BUSINESS-DESK — Business desk.
2. GP-BUSINESS-COURIER — Courier integration at that desk.
3. GP-TABLE-ITEMS — Merchandise previews on tables.
4. GP-FARMER-TENDING — Farmers visibly working in their fields.
5. GP-LOCKPICK — Complete interactive lockpicking minigame.
6. MP-PLAYER-FAMILY — Children, households and adoption for married players.

It also includes all seven reported issues from today's playtesting:

7. Mine wooden-frame visual problem.
8. Encyclopedia recipe tools.
9. Being-hunted visual warning.
10. Controller Max/Min button.
11. Booth rents the wrong pitch.
12. Booth spacing.
13. Equipped armour not displaying.

And the additional controller feature:

14. Skills menu on right trigger.

All 14 belong in Build 22.

These are not optional items and are not automatically postponed to Expansion 20.

Read their recorded requirements and retain every existing acceptance criterion.

3. PLAYER CHILDREN — KEEP IN BUILD 22

I understand this is the riskiest item because it affects households, family relationships, persistence and multiplayer.

I am nevertheless authorizing its completion in Build 22.

Implement it as a contained workstream and integrate it only after its relevant tests pass.

Requirements:

- Married male/female player couples follow the approved biological-child rules.
- Same-sex player couples use adoption under the previously approved design.
- Both parents are correctly recorded.
- Parent-child relationships survive saving and loading.
- Household membership is correct.
- Multiplayer player identity and family records remain consistent.
- Disconnected players retain their family relationships.
- Existing NPC family systems continue working.
- Single-player family behavior remains unchanged where not explicitly extended.
- Build 21 saves migrate safely to the new format.
- No duplication, orphaned relationships, accidental loss of family records or invented children.

Use the existing owner-approved family rules.

Do not redesign marriage, reproduction, guardianship or adoption.

Do not create a temporary shortcut that corrupts persistence.

Finish the underlying data-model changes properly.

You may run its development and testing independently from the smaller polish fixes, provided shared files and integration remain controlled.

4. ARMOUR — OWNER ANSWER

Do not limit the correction to whichever armour happened to be equipped during my playtest.

Investigate every currently equippable armour type, including leather and iron.

The requirement is straightforward:

If a character equips visible body armour, that armour must actually appear on the character.

Verify:

- Leather armour.
- Iron armour.
- Other existing equippable armour variants.
- Male and female character sprites.
- All supported movement directions.
- Idle, walking, working and combat animations.
- Correct drawing order relative to clothing, weapons and equipment.
- Unequipping restores the appropriate clothing appearance.
- Saving and loading preserves appearance.
- Multiplayer correctly displays the equipment of other players.

Use the existing art assets and equipment system.

Do not add fictitious armour types or replace the character-art style.

Correct the underlying equipment-visual linkage so this issue cannot recur for another existing armour item.

Do not wait for me to identify one armour type before beginning the investigation.

5. MINE WOODEN FRAME — OWNER ANSWER

Inspect both possible sources:

- The wooden frame at the mine or cave entrance.
- Timber supports placed within the mine.

The visual problem is that wooden framing must not appear to obstruct or incorrectly cover the ore deposit or traversable opening.

Identify the exact asset and rendering relationship responsible.

Correct the placement, sprite transparency, layering, anchoring or framing geometry as appropriate.

The result must:

- Clearly distinguish the mine opening, ore deposit and wooden support.
- Preserve the natural irregular mine/cave appearance already approved.
- Avoid wooden beams visually cutting through the deposit.
- Show the correct foreground/background relationships.
- Preserve actual entrance access, mining interaction and collision behavior.
- Work with roof transparency and isometric rendering.
- Avoid introducing flickering or disappearing objects.

This is a visual and interaction correction, not authorization to redesign the mining system.

Do not change ore depletion, regeneration, sustainability or mining economics.

Use the actual game assets to determine which framing element is responsible.

If both entrance frames and placed timber supports share the defect, fix both.

Do not hold the build waiting for another identification question.

6. BOOTH SPACING — OWNER ANSWER

The booths are too close together. Space them farther apart.

Give market stalls enough visible and usable separation that the marketplace does not look cramped.

Preserve:

- Walkable access between stalls.
- Proper customer and merchant interaction positions.
- Space for the merchant to work.
- Clear entrances and circulation.
- Correct stall ownership and identifiers.
- Existing market transactions and listings.
- Compatible NPC navigation.

Do not invent a fixed tile separation if the art and movement requirements indicate a different appropriate spacing.

Choose spacing based on actual footprint, player clearance and NPC pathing.

Verify that widening the layout does not place booths on another building, inaccessible terrain, paths that become obstructed or other conflicting objects.

Record the layout change and its simulation-baseline effects before accepting a new baseline.

7. BOOTH RENTAL — OWNER ANSWER

When I select a particular vacant market booth and choose Rent, the game must rent that selected booth.

Do not rent the first vacant booth elsewhere in the village.

Use the actual selected booth's identity.

Check availability, ownership, rental price and permissions against that booth.

After renting, show the correct booth as mine.

The transaction must be atomic, must charge correctly, and must not alter another stall's ownership.

Test with multiple empty booths and occupied booths.

8. SKILLS BUTTON — OWNER ANSWER

Add the controller RIGHT TRIGGER as an additional way to open Skills.

Preserve the existing Skills controls.

This is an additional shortcut, not a replacement.

Requirements:

- Right trigger opens Skills during normal gameplay.
- Existing keyboard, mouse, touch and controller access remains available.
- The on-screen controller guide shows the new shortcut.
- Avoid double-opening from one trigger press.
- Respect dialogs, menus, combat and other contexts where the trigger may already have a required action.
- Do not steal an existing essential control without providing equivalent functionality.
- Preserve consistent behavior across supported controllers.

If the current controller map has a real conflict, resolve it through the established input-mapping system while retaining the requested direct Skills access.

Do not stop development merely to ask whether this should be a second button. That decision is now made.

9. CONTROLLER MAX/MIN — OWNER ANSWER

Provide direct Max and Min shortcuts in all applicable quantity selectors.

One intentional controller action should select the maximum available permitted amount, or the minimum permitted amount.

Do not require repeated button presses to reach a limit.

The current button prompts must identify the assigned controls.

The behavior must respect:

- Available inventory.
- Affordability.
- Transaction limits.
- Contract quantity restrictions.
- Storage or carrying limits.
- Allowed minimum quantities.
- Existing transaction validation.

Use the established input system consistently.

Do not allow one press to activate two controls.

10. ENCYCLOPEDIA TOOLS — OWNER ANSWER

Every crafting or production recipe should clearly identify:

- The required tools.
- Which existing items qualify for each requirement.
- Relevant tool condition or capability restrictions, where applicable.
- The distinction between tools and consumed ingredients.

Use the actual production requirements as the data source.

Do not create a separate, manually maintained list that can drift from gameplay.

Update the encyclopedia consistently across professions and recipe categories.

Provide tests ensuring that recipes with tool requirements do not silently omit them.

11. BEING-HUNTED WARNING — OWNER ANSWER

Use the already existing crime and guard-pursuit system.

When guards are actively hunting the player, display:

- A clear but unobtrusive red visual ring around the player's character.
- A small readable interface panel explaining that the player is wanted or being hunted and why.

The warning must correspond to actual pursuit/wanted state, not a separate invented crime flag.

Update when the state changes.

Remove the warning when the underlying state legitimately ends.

Do not permanently display it after a cleared crime or completed punishment.

Do not reveal hidden guard information the player would not legitimately know.

Keep the warning legible on Android without covering important controls.

No redesign of crime, morality, judgment, guard pursuit or punishment is authorized.

12. FARMERS — COMPLETE THE ACTUAL ANIMATION

Farmers must visibly move through their fields while sowing, tending or harvesting.

They should not simply stand at one edge swinging a tool.

Use the correct existing tools, movement and work animations.

Preserve productivity, elapsed work time, harvest quantities, tool wear, ownership and simulation scheduling.

Record any genuine simulation-baseline changes caused by movement/pathing before accepting them.

13. LOCKPICKING — COMPLETE THE MINIGAME

Implement the full previously approved pin-tumbler system.

Include the visible lock chambers, pins, springs, setting line, feedback and player inputs.

Support touch, controller, mouse and keyboard.

Easy locks should follow the previously approved approximately six-to-eight successful-input progression.

Prevent duplicate activations, dropped rapid presses and unintended actions when closing the screen.

Lock difficulty must not make touch targets unreasonably small.

A failed or interrupted attempt must leave the lock in the state specified by the existing lockpicking rules.

Do not replace the approved design with another passive progress bar.

14. BUSINESS DESK AND COURIER — FINISH EXISTING WORK

Recover "wip/build22-business-desk" at "e25eec9".

Do not discard or rewrite the half-finished implementation unnecessarily.

Complete the desk and courier handoff as separate testable requirements.

Keep existing merchant buying, selling, stock, contracts and ownership behavior intact.

Tables and shelves should represent actual merchant listings.

Table previews are visual only and do not create pickup transactions.

15. INTEGRATION AND RELEASE

Complete all 14 items on one controlled Build 22 integration path.

Use targeted tests per workstream, then the necessary cross-system and release gates.

Especially protect:

- Saves and migration from Build 21.
- Multiplayer identity and relationships.
- Inventory and currency conservation.
- Market transactions.
- NPC movement and pathfinding.
- Deterministic simulation.
- Existing crime and reputation systems.
- All established gameplay systems.

Do not accept a new simulation baseline solely because a test changed. Document and explain actual differences first.

Prepare one private Build 22 release from one verified source commit:

- Signed Android APK.
- Windows executable.
- Linux build.
- SHA-256 checksums.
- Tester notes.
- Save-upgrade instructions and known limitations.

Do not publish publicly.

Do not falsely claim real-device checks passed.

16. THEN BEGIN EXPANSION 20

After Build 22 is prepared, proceed immediately with Expansion 20.

The October 24 implementation hold is no longer applicable.

Reconcile completed Build 22 requirements against the 67-item Expansion 20 register so no completed work is duplicated.

Continue through the remaining approved requirements in coherent implementation batches.

Do not stop at planning or audits.

Preserve the completed Build 19 judgment and reputation systems.

Preserve the existing Living Economy foundations, formulas and conservation requirements.

You may implement the authorized technical systems, but do not guess unresolved owner-controlled economic policies, change approved formulas or activate unverified economic behavior.

Where a particular item genuinely requires a new major owner policy, isolate and record that decision while continuing independent authorized work.

Do not use one unresolved item as a reason to stop the entire expansion.

17. WORKFLOW AND AUTONOMY

You have authority for routine engineering decisions.

Use multiple workers only when their tasks are independent and merges can be controlled.

Reuse passing test evidence.

Avoid redundant full simulation campaigns and repeated build attempts.

Use GitHub Actions for relevant automation.

Maintain the requirements register and update CURRENT_DEVELOPMENT_STATE.md so it no longer presents obsolete Build 18 or 19 next steps as active work.

Checkpoint before context compaction.

Do not repeatedly return asking whether to proceed.

FINAL OWNER DIRECTIVE

Build 22 includes all six deferred requirements, all seven issues from today's playtesting and the new right-trigger Skills shortcut.

That is 14 items. None are to be silently omitted.

Player children stay in Build 22.

Armour rendering is to be checked across all existing armour types.

The mine frame is to be diagnosed against both entrance and placed-support art.

Market booths need greater spacing.

Right trigger is an additional Skills shortcut.

All remaining routine decisions are delegated to you within these specifications.

Finish as much as possible, integrate it properly, prepare the private Build 22 playtest, and then move directly into Expansion 20 without another general authorization.

Begin execution now.
