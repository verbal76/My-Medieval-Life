Owner directive, 2026-10-24, verbatim (the reconciliation directive and its Build 22 deferred-work preservation clarification).

MY MEDIEVAL LIFE — EXPANSION 20 MASTER OPEN-ITEMS RECONCILIATION

OWNER DIRECTIVE — RECORD AND COMMIT ONLY

Expansion 20 is the next major development milestone.

I want every outstanding gameplay, Android usability, interaction, visual, and previously deferred Build 19 item reconciled into the Expansion 20 planning scope.

This is a documentation, requirements-management, and memory-handoff task ONLY.

Do not implement, modify gameplay code, launch agents, start simulations, build packages, run CI campaigns, or begin Expansion 20 development.

The purpose is to establish one accurate, comprehensive, persistent work register before implementation begins.

1. Source of truth and reconciliation

Begin with a read-only audit of:

- "docs/requirements/requirements.json"
- "docs/requirements/views/STATUS.md"
- "docs/requirements/views/QUEUES.md"
- "docs/requirements/views/DECISIONS.md"
- "docs/CURRENT_DEVELOPMENT_STATE.md"
- "docs/handoffs/CURRENT_SESSION_RECOVERY.md"
- Build 19 completion and release records
- Build 21 multiplayer completion and deferral records
- "docs/backlog/BUILD22_MINI_BUILD.md"
- Existing gameplay polish directives and schedules
- Expansion 20 design, architecture, and Phase 1 implementation records
- Relevant owner decisions and prior playtest findings

Inspect the current repository state before changing any records.

The requirements register remains the authoritative record. Generated views must be updated through the established requirements tooling.

Do not create a competing requirements system.

2. Existing Expansion 20 — Living Economy

Preserve all existing Expansion 20 work, including:

- Reservation records and reservation accounting.
- Event records and event processing foundations.
- Actor resolution.
- Existing contract and market-economy integration points.
- Economic conservation and determinism requirements.
- Save/load compatibility.
- Existing architecture and owner decisions.
- Disabled feature hooks and unfinished activation work.
- Any remaining Expansion 20 owner decisions.

Do not change economic formulas, prices, labor behavior, trading rules, or existing economic mechanics.

Do not activate any disabled Expansion 20 features.

The current foundation must remain intact.

3. Android interface and usability

Add or reconcile the following owner-reported issues.

GP-ANDROID-RECENTER

The Recenter control currently positions the player incorrectly relative to the visible gameplay area.

Required behavior:

- Recenter places the character at the visual center of the usable gameplay area.
- Account for the screen area occupied by persistent HUD elements.
- Do not position the character underneath the health panel.
- Work consistently at different zoom levels and Android display sizes.
- Preserve existing camera controls and movement behavior.

GP-ANDROID-HUD-SCALE

Reduce the health and status panel by approximately 15%.

Preserve:

- Health and other status information.
- Numerical values.
- Legibility.
- Existing gameplay functionality.

Reduce wasted space rather than removing useful information.

GP-ANDROID-ACTION-BUTTONS

Refine the right-side action controls.

Requirements:

- Preserve existing glyph artwork and glyph size.
- Preserve all visible button labels.
- Preserve the existing button functions and ordering.
- Replace oversized rectangular button backgrounds with compact circular backgrounds.
- Size the controls to accommodate their glyphs and labels.
- Position controls closer to the right screen edge, respecting device safe areas.
- Maintain comfortable touchscreen hit targets.
- Reclaim gameplay screen space without making controls difficult to use.

Do not remove labels as a space-saving shortcut.

GP-ANDROID-USE-TALK-TARGETING

The existing Use button sometimes selects a nearby villager when the player intends to interact with a station or other usable object.

Requirements:

- Improve differentiation between usable world objects and nearby characters.
- Use should prioritize the appropriate usable station or object.
- Talk should prioritize nearby characters.
- Make the current target understandable to the player.
- When multiple eligible targets exist, provide a practical way to select the intended one.
- Preserve existing interaction distance, permissions, ownership, and access rules.
- Do not require maximum camera zoom or pixel-perfect tapping.

The game already has a Use button. Do not add a redundant Use Nearby button.

Prefer corrections to the existing targeting and interaction system.

4. Interactive-object identification and feedback

GP-INTERACTABLE-OUTLINES

Players need to recognize which objects can be used without tapping everything.

Requirements:

- Nearby usable objects display a subtle glowing outline.
- The currently selected interaction target displays a brighter outline.
- The outline follows the object's actual sprite silhouette rather than its entire tile.
- Support ovens, workbenches, market stalls, anvils, storage, and other eligible interactive objects.
- Respect existing interaction range and access restrictions.
- Avoid unnecessary visual clutter or excessive rendering cost.
- Keep the highlighting consistent across supported platforms where appropriate.

This is a usability feature, not authorization for a new interaction framework.

GP-INTERACTION-PROMPT-LIFECYCLE

Contextual prompts such as "Use the workbench" currently remain visible during or after interactions until the player moves away.

Requirements:

- Show contextual prompts when a valid target is selected.
- Clear or suppress the prompt while the corresponding interaction is active.
- Clear stale prompts when the interaction closes, the target changes, or the target becomes invalid.
- Allow prompts to return when the player selects the object again.
- Preserve useful activity feedback such as "Crafting."

Do not confuse persistent proximity with an active interaction target.

5. Existing gameplay and Android punch-list reconciliation

Locate every existing issue associated with these areas and carry forward anything not demonstrably completed and accepted.

World rendering and buildings

- Character rendering beneath building edges.
- Incorrect indoor/outdoor occlusion.
- Roof transparency and flickering.
- Doors appearing in incorrect locations, including roofs.
- Smithy walls and interior presentation.
- Building entry and exit pathing.
- Farm and path tile edges.
- Incorrect object sprites or artwork.
- Interaction targets not matching visible artwork.

Character controls and equipment

- Android pickaxe animation and usability.
- Anvil targeting and operation.
- Rusty axe and starting equipment issues.
- Joystick responsiveness and consistency.
- Input behavior across touchscreen, keyboard, and controller.
- Continuous harvesting.
- Tool sharpening.
- Lockpicking interactions.
- Contextual Use and Talk behavior.

NPCs, reputation, and social behavior

- Repetitive gossip and dialogue.
- NPC identity and awareness.
- Crime reporting and pursuit.
- Guards and criminal response.
- Relationship and family interactions.
- Gift selection and quantity.
- Existing reputation and judgment features carried forward from Build 19.

Do not redesign or weaken the completed Build 19 reputation system.

Combat and bandits

- Bandit respawning.
- Bandit spawning inside props or occupied locations.
- Bandit camp object and sprite selection.
- Campfire flame scale and visual overlap.
- Any outstanding bandit interaction or combat defects.

Markets, crafting, and workplaces

- Market stall artwork and shelf presentation.
- Ten distinct market listings.
- Stall pricing when placing goods for sale.
- Business desk and management interactions.
- Workbench interaction and crafting.
- Table item placement.
- Farmer tending behavior.
- Existing player-business integration.
- Object selection and targeting.
- Workplace UI layout and readability.

Interface and feedback

- Oversized or obstructive panels.
- Pause menu scaling.
- Wiki and journal layout.
- Progress indicators.
- Inventory and trading interfaces.
- Text clipping and screen-space use.
- Target selection feedback.
- Any remaining Android-specific readability or interaction issues.

For each area, find the existing requirement IDs before creating anything new.

Do not assume an item remains open simply because it appears in an older playtest report.

6. Carry-forward items from Build 19

Explicitly audit all Build 19 items that were:

- Deferred.
- Incomplete.
- Partially implemented.
- Implemented but not integrated.
- Integrated but not verified.
- Left awaiting owner playtesting.
- Accepted as nonblocking for the Build 19 release.
- Moved to a later build during the Build 19 scope freeze.

Preserve their original requirement IDs, history, acceptance criteria, and implementation evidence.

Do not reopen completed and accepted Build 19 work.

Where a Build 19 item remains genuinely unfinished, assign it to the Expansion 20 carry-forward scope or clearly identify an existing owner-approved later destination.

Do not silently discard items.

7. Build 21 and Build 22 deferred items

Reconcile the multiplayer Build 21 scope-freeze deferrals, including:

- "GP-BUSINESS-DESK"
- "GP-TABLE-ITEMS"
- "GP-FARMER-TENDING"
- "GP-LOCKPICK"
- "MP-PLAYER-FAMILY"

For MP-PLAYER-FAMILY, preserve the approved owner rules:

- Male/female married couples may create new children through the existing biological reproduction mechanics.
- Same-sex married couples may adopt existing children.
- Male/female couples may also adopt.
- Biological birth creates a new population entity.
- Adoption transfers an existing child into a family relationship without increasing the population.
- Both spouses must be recognized as parents.
- Adoption is an active action, not automatic.

The future adoption-agency concept is a separate, deferred design item. Do not implement it or create a new family system.

These deferred items may already be assigned to a Build 22 mini-build. Reconcile their scheduling rather than creating duplicates.

For this planning pass, Expansion 20 is the umbrella milestone for outstanding gameplay polish, but preserve any established Build 22 mini-build delivery dependency unless the owner explicitly authorizes changing it.

8. Classification and scheduling

For every reconciled item, record:

1. Existing or new requirement ID.
2. Clear description.
3. Original source or build.
4. Current verified status.
5. Whether code already exists.
6. Remaining acceptance criteria.
7. Target milestone.
8. Dependencies or blockers.
9. Whether it is gameplay polish, a defect, an existing-system correction, or new functionality.
10. Whether owner authorization is still required.

Keep these distinctions explicit:

- Completed and accepted.
- Implemented but unverified.
- Partially implemented.
- Not implemented.
- Deferred.
- Design decision unresolved.

Do not convert unverified work into completed work.

Do not reopen completed work unnecessarily.

Do not duplicate requirements already tracked elsewhere.

Do not silently move previously approved features between milestones without recording the scheduling change.

9. Memory and recovery persistence

Update the established persistent project records so this work survives Claude context compaction.

Update as appropriate:

- Requirements register.
- Generated status and queue views.
- Expansion 20 planning documentation.
- Development-state handoff.
- Session recovery documentation.
- Existing project memory or "CLAUDE.md" references, where appropriate.

The recovery instructions must direct future Claude sessions to the authoritative Expansion 20 records.

Do not paste the entire requirements register into memory files. Store concise pointers and the important owner scope decisions.

10. Git instructions

This is a documentation-only commit.

- Work on the appropriate staging/documentation branch.
- Do not modify gameplay source files.
- Do not merge expansion branches.
- Do not change release metadata.
- Do not start CI or build workflows intentionally.
- Run only the necessary requirements-register consistency check.
- Commit and push the documentation and tracking changes.
- Report the commit SHA.

If an existing file already contains a complete record, update its references rather than recreating it.

11. Explicit stop boundary

After the records are reconciled, committed, and pushed:

STOP.

Do not:

- Start Expansion 20 implementation.
- Activate the Living Economy.
- Fix the Android interface.
- Create the interaction outlines.
- Launch development agents.
- Begin a new testing campaign.
- Package Build 20.
- Publish anything.
- Move on to Expansion 21.

Wait for my explicit authorization.

12. Final report

Provide a concise report containing:

- Total outstanding items assigned to Expansion 20.
- Number carried forward from Build 19.
- Number carried forward from Build 21 or the Build 22 mini-build.
- Number of newly recorded Android and gameplay issues.
- Items already implemented but awaiting verification.
- Any scheduling conflicts or duplicates resolved.
- Exact documents updated.
- Commit SHA and push confirmation.

Identify anything that could not be reconciled rather than guessing.

Owner objective: One complete, accurate Expansion 20 work plan, preserving all prior work and decisions, with no implementation started.
Build 22 deferred-work preservation clarification

The following statuses are confirmed by the owner and must be preserved when reconciling Expansion 20:

- Business desk and courier work: Existing unfinished and untested implementation is preserved on "wip/build22-business-desk" at commit "e25eec9". Record the exact branch and commit. Do not discard, overwrite, restart, or mark this work complete.
- Lockpicking: Not started. No implementation exists to preserve.
- Farmer field tending: Not started. No implementation exists to preserve.
- Table merchandise previews: Not started. No implementation exists to preserve.
- Player-children repair: Deferred and already recorded in the backlog. Preserve the approved family rules and existing backlog record without reopening or implementing the repair.

Include all five work areas, with business desk and courier treated as related but individually traceable, in the Expansion 20 consolidated planning inventory.

Preserve their existing branch history, statuses, and any previously approved milestone assignments.

This clarification is for documentation and tracking only. Do not start implementation, testing, merging, or packaging.
