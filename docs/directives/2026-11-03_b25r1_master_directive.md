# Owner directive, 2026-11-03 (received about 11:15 EST): Build 25 Revision 1 master implementation directive

Saved verbatim. Register: B25R1 and its children.

---

MY MEDIEVAL LIFE — BUILD 25 REVISION 1

MASTER IMPLEMENTATION DIRECTIVE

Regional Navigation, Living-World Interactions, Automatic Travel, Character Creation and Complete UI Polish

OWNER APPROVAL: IMPLEMENT ALL REQUIREMENTS

This is the consolidated implementation directive for Build 25 Revision 1. It supersedes conflicting earlier instructions concerning regional discovery, navigation, travel, character customization, and the affected interfaces.

The objective is to make the existing living world fully accessible, interactive, and professionally presented.

Core principle: My Medieval Life is a living-world simulation, not an exploration simulator. Traveling outside the starting village must not mean leaving the functional simulation behind.

Preserve the completed Build 25 private draft as a rollback point. Revision 1 must receive its own identifiable private draft release.

---

1. REGIONAL MAP — THE WORLD IS ALREADY KNOWN

The player lives in an established medieval world. Major settlements and established routes are common geographic knowledge.

Requirements

1. Display and label all major established settlements from the beginning of the game.
2. Include the starting village, Wulstead, Netherton, Garton, Higham-on-the-Way, Bourton Abbas, and all other major settlements actually present in world data.
3. Display established roads, trails, and significant geographic features.
4. Clearly identify the player's current position.
5. Show settlement names, distances, and directions.
6. Do not require NPC conversations to unlock knowledge of major settlements.
7. Keep major settlements visible regardless of whether the player has physically visited them.
8. Use accurate world coordinates and geographic relationships.

Discoverable locations

Smaller locations may still require physical discovery.

Examples include:

- Mines and ore deposits
- Caves and ruins
- Bandit camps
- Remote buildings
- Hunting grounds
- Other generated points of interest

When discovered, create a persistent icon on the regional map.

Icons must survive save/load and correspond to actual world objects or locations.

Do not invent destinations that do not exist.

NPC conversations about roads may provide additional information, rumors, trade opportunities, and local knowledge, but must not gate the visibility of major settlements.

---

2. ROADS, TRAILS AND REGIONAL GEOGRAPHY

Audit the existing road and trail implementation before changing it.

The owner expects the world to contain both stone roads and dirt roads/trails, where those types are supported by the existing design and world data.

Determine which road types are currently implemented, generated, rendered, and traversable.

Requirements

- Preserve and correctly render existing stone roads.
- Preserve and correctly render dirt roads and trails.
- Ensure road types connect logically to settlements and appropriate destinations.
- Keep road geometry consistent between the regional map and playable world.
- Make roads visually recognizable.
- Maintain terrain continuity across world streaming boundaries.
- Preserve existing road-related movement and gameplay rules.
- Ensure roads and trails remain physically traversable by the character.

If either expected road type is missing or nonfunctional, identify the gap and implement the appropriate correction within the approved regional navigation design.

Do not fabricate decorative roads that do not correspond to actual traversable terrain.

---

3. REGIONAL MAP — VISUAL PRESENTATION AND CONTROLS

Redesign the regional map as a useful navigation interface.

Required functionality

- Open zoomed out enough to display the major settlement network.
- Support pinch-to-zoom on Android.
- Support mouse-wheel zoom on desktop.
- Support touch and mouse dragging to pan.
- Provide a Center on Player control.
- Show readable settlement names and destination labels.
- Show distances and directions.
- Display discovered landmark icons.
- Show the player's position prominently.
- Display the active travel destination.
- Display the planned route where supported.
- Keep labels legible at different zoom levels.
- Maintain correct geographic proportions.

The map must use the available screen space effectively.

Do not leave a tiny map surrounded by a large, mostly empty panel.

Distinguish map dragging from destination selection so that zooming or panning does not accidentally start travel.

---

4. TAP ANYWHERE TO TRAVEL

Owner decision: The player may tap any reachable point on the regional map and instruct the character to travel there.

This includes locations that are not settlements.

Route planning

The navigation system must:

1. Identify the selected world coordinate.
2. Determine whether the destination is reachable.
3. Calculate a practical route from the character's current position.
4. Prefer established roads and trails where reasonably efficient.
5. Leave the road network when necessary to approach the destination.
6. Navigate around impassable terrain and obstacles.
7. Recalculate routes when necessary.
8. Avoid endless pathfinding loops or repeated attempts against blocked terrain.

Do not use teleportation or artificial instant travel.

Actual movement

Automatic travel must move the character through the real playable world.

The following systems remain active where applicable:

- In-game time
- Hunger and fatigue
- Weather
- Movement speed
- Terrain restrictions
- NPC activity
- Animal behavior
- Hostile encounters
- Combat and injury
- Resource availability
- World events
- Existing survival and simulation mechanics

Do not suspend or simplify the living world merely because travel is automatic.

Camera

During automatic travel, the gameplay camera must follow and center on the character.

Manual interruption

The player can take manual control at any moment.

Manual input immediately suspends automatic navigation.

The destination remains stored.

Provide two controls:

Resume Destination

- Recalculate from the player's current location.
- Continue toward the saved destination.

Dismiss Destination

- Cancel the journey.
- Clear the saved destination and route.

The player must never be forced to complete an automatic journey before regaining control.

Save/load

Preserve the destination and appropriate travel state across save/load.

Prevent invalid route restoration or movement into unloaded terrain.

---

5. CRITICAL — FULL INTERACTION OUTSIDE THE STARTING VILLAGE

OWNER-REPORTED DEFECT — RELEASE BLOCKER

During the owner's previous Build 25 playthrough, interaction stopped working after leaving the starting village.

The player could not interact with people, animals, or collectible world materials.

This is unacceptable for a living-world simulation.

Investigate the actual cause rather than assuming the systems are working because their code exists.

Required investigation

Inspect:

- Regional world streaming and chunk loading
- NPC spawning and registration
- Animal spawning and behavior
- Resource spawning and persistence
- Interaction detection and targeting
- Coordinate conversion between local and regional positions
- Input handling outside settlements
- Collision and proximity detection
- Entity lifecycle and ownership
- Scene transitions
- Save/load and world-state restoration
- Interaction UI visibility
- Any region-specific restrictions that disable interactions

Identify whether the problem is missing entities, decorative entities without functional behavior, failed interaction registration, incorrect coordinates, disabled input, or another confirmed cause.

Record the root cause and correction.

5A. NPC INTERACTION

NPCs outside the starting village must remain functional.

Applicable existing interactions include:

- Dialogue
- Trading and negotiation
- Employment and hiring
- Social relationships
- Reputation-related interactions
- Combat and hostility
- Other supported NPC actions

These systems must work at other settlements, along roads, and in wilderness areas wherever applicable NPCs exist.

NPCs must not become noninteractive scenery outside the starting village.

5B. ANIMAL INTERACTION

Animals encountered outside the village must remain part of the functional simulation.

Preserve applicable existing systems for:

- Animal movement
- AI behavior
- Hunting
- Combat
- Damage and mortality
- Resource collection from animals
- Other implemented animal interactions

Do not make every animal automatically friendly or harmless.

Preserve the game's existing ecological and combat rules.

5C. RESOURCE GATHERING

The player must be able to interact with valid resource objects outside the starting village.

This includes applicable existing systems for:

- Trees and wood
- Stone
- Ore deposits
- Plants and forageable materials
- Other collectible resources
- Mining
- Harvesting
- Inventory transfer
- Resource depletion and sustainability

Resources must use the same established rules wherever they occur.

Do not create separate arbitrary resource-generation or regeneration rules for wilderness areas.

A tree, stone deposit, or ore-bearing rock must not become decorative simply because it exists outside the home village.

5D. INTERACTION DURING AUTOMATIC TRAVEL

Automatic travel must not disable world interaction.

When the player manually interrupts travel:

1. Character control returns immediately.
2. Nearby NPCs remain interactable.
3. Animals retain their normal behavior and interactions.
4. Resources remain available for gathering.
5. The travel destination remains saved.
6. The player may resume or dismiss the destination afterward.

Normal world events and encounters continue during automatic travel.

If an event requires player intervention, preserve the appropriate gameplay behavior rather than bypassing it.

5E. REGIONAL CONTINUITY

Verify that the same functional world systems operate:

- Inside the starting village
- Immediately outside the village
- Along stone roads
- Along dirt roads and trails
- In wilderness areas
- At distant settlements
- Across streamed region boundaries
- After saving and reloading

Acceptance criterion: A player can leave the starting village, walk to another settlement, interact with its residents, gather materials along the journey, encounter animals, and return home without losing access to the normal gameplay systems.

This must be demonstrated through actual interactive gameplay tests, not merely background simulation success.

---

6. CHARACTER CREATION — UNRESTRICTED COSMETIC OPTIONS

Owner decision: Unlock all cosmetic character customization options.

If a player wants to create a green elf, that is acceptable.

Cosmetic choices do not need to conform to realistic human appearances.

Audit first

Determine whether current customization is restricted by:

- Hardcoded option limits
- UI controls
- Palette restrictions
- Sprite layers
- Rendering architecture
- Animation support
- Save-data structures

Identify the actual limitations before implementing corrections.

Required customization

Expose all supported cosmetic options and expand the system where technically practical.

Include:

- Broad skin color selection, including fantasy colors
- Hair styles
- Hair colors
- Eye colors
- Facial hair
- Existing appearance options
- Unrestricted cosmetic combinations

Do not impose unnecessary gender-based restrictions.

Where the existing rendering system supports palette-based recoloring, use it to provide broad color freedom.

Ensure appearance choices work in the character preview and actual gameplay.

Rendering and persistence

Validate:

- Idle animation
- Walking animation
- Directional sprites
- Existing applicable character animations
- Sprite-layer alignment
- Save/load
- Existing character compatibility

Do not silently expose options that render incorrectly.

Equipment restriction

Armor and weapons remain governed by existing gameplay rules.

Character creation must not grant equipment or bypass inventory, progression, or acquisition requirements.

Cosmetic customization must not create gameplay advantages.

---

7. COMPLETE VISUAL POLISH — CHARACTER CREATION, ORIGIN AND MAP

Owner approval: Redesign the actual appearance of the panels as well as their layouts.

This is not simply a resizing task.

The current oversized brown panels look unfinished and waste available screen space.

Create a consistent, professional medieval pixel-art interface.

Shared visual standards

Improve:

- Panel backgrounds
- Borders and framing
- Typography
- Spacing and padding
- Button appearance
- Visual hierarchy
- Color coordination
- Decorative details
- Contrast and readability
- Touch-target sizing
- Responsive layouts

The visual style should complement the existing game artwork.

Avoid excessive decoration that interferes with usability.

7A. Character Creation

Create a polished character creation interface.

- Prominent animated character preview.
- Preview on the left where screen dimensions permit.
- Organized customization controls on the right.
- Clear categories and labels.
- Accessible color selection.
- Full access to available cosmetic choices.
- No unnecessary empty space.
- No clipped controls.
- Proper Android and desktop scaling.

The player should be able to see the effects of customization immediately.

7B. Origin Story

Preserve the existing approved story text.

Redesign the presentation using:

- A centered, proportionate panel
- Improved typography
- Comfortable reading width
- Character portrait or sprite
- Attractive medieval framing
- Clear progression controls
- Better spacing

The screen should feel like an intentional game introduction, not a giant debugging dialog.

7C. Region Map

Use the same visual design language.

Prioritize map usability, readable icons, and clear navigation controls.

Do not sacrifice map space for decorative borders.

7D. HUD and Modal Behavior

When a modal screen is open:

- Hide or dim obscured HUD elements.
- Prevent accidental interaction with underlying controls.
- Avoid overlapping panels.
- Preserve appropriate pause behavior.
- Support Android and desktop input correctly.

---

8. VALIDATION — TEST WHAT THE PLAYER ACTUALLY DOES

The owner's previous experience demonstrates that successful long simulations do not guarantee working player interactions.

Validation must include actual player-facing interaction scenarios.

Required test scenarios

Scenario A — Starting village to wilderness

Start a new game, leave the village, approach a valid resource object, interact with it, collect materials, and verify inventory changes.

Scenario B — Roadside NPC

Encounter an NPC outside the starting village, initiate dialogue, and exercise applicable interactions.

Scenario C — Wildlife

Encounter an animal outside the village and verify applicable AI, combat, hunting, or other supported interactions.

Scenario D — Distant settlement

Travel to another settlement and interact with its residents and functional locations.

Scenario E — Automatic travel interruption

Select a destination, begin travel, interrupt manually, interact with nearby world objects, and resume the journey.

Scenario F — Save/load

Save outside the starting village, reload, and confirm that NPCs, animals, resources, discovered locations, and travel state remain functional.

Scenario G — Roads and trails

Verify actual traversability and route selection across stone roads, dirt roads/trails, and off-road terrain.

Scenario H — Character creation

Test expanded cosmetic combinations, rendering, animations, and persistence.

Scenario I — Interface presentation

Capture and inspect screenshots of character creation, origin, and regional map screens at representative Android and desktop resolutions.

Validation rules

- Reuse valid passing CI evidence for unchanged systems.
- Run focused tests for changed functionality.
- Verify deterministic behavior where applicable.
- Do not automatically repeat the 365-day simulation.
- Run broader tests only when technically justified by affected code or required release gates.
- Never treat passing background simulations as a substitute for actual player-interaction validation.

A feature is not complete merely because it compiles or its automated test reports success.

---

9. RELEASE REQUIREMENTS

Target: My Medieval Life Build 25 Revision 1

- Preserve the original Build 25 private draft.
- Record the exact source commit.
- Validate all changed functionality.
- Produce full-game and demo packages for Android, Windows, and Linux.
- Sign Android packages with the established release key.
- Verify package identities and checksums.
- Create a separate private draft release.
- Do not publish publicly.
- Do not upload to Steam without authorization.

Document all implementation changes, root causes, owner decisions, rationale, test evidence, and remaining limitations in the existing GitHub records.

Update recovery documentation so future development sessions can reconstruct the project state without a separate handoff conversation.

---

10. EXECUTION AUTHORITY

Proceed autonomously within the approved scope.

Do not repeatedly ask for approval on decisions already made.

Do not introduce unrelated gameplay systems or redesign unrelated features.

If a genuinely unresolved design decision or substantial technical tradeoff arises, present one focused question at a time.

Preserve the current Build 25 release as a rollback point.

Final acceptance standard

Build 25 Revision 1 must deliver a connected, living medieval world where:

- Major settlements are known and visible.
- Stone roads and dirt trails are usable where supported by the world design.
- The player can select any reachable map destination and travel there naturally.
- The player can interrupt and resume travel freely.
- People, animals, and resources remain fully interactive beyond the starting village.
- Character creation provides broad cosmetic freedom.
- Character creation, origin, and map interfaces look polished and professionally finished.

The world must remain playable and interactive everywhere the player can legitimately travel. That is a release requirement, not optional polish.
