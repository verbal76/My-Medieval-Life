MY MEDIEVAL LIFE — BUILD 18 MASTER INTEGRATION DIRECTIVE

OWNER DIRECTIVE: BUILD 18 — VISUAL POLISH, CHARACTER CUSTOMIZATION, ARMOR AND CROP SHARING

Project: My Medieval Life
Studio: Hot Attic Games
Target: Build 18 / Expansion 18
Priority: Integrate approved owner feedback while preserving simulation integrity.

This directive consolidates the owner's Build 17 playtest findings and approved Build 18 changes.

It is intended to be handed directly to Claude Code for repository inspection, implementation planning, coordinated development, focused validation and eventual integration.

Do not modify or delay Build 17.

Build 17's release candidate "cd7439c" remains frozen. Its existing CI, repeatable-results evidence and four 365-day validation runs must not be invalidated by Build 18 work.

All new work belongs on appropriate Build 18 development branches until integration is authorized.

---

PART 1 — GOVERNING ENGINEERING REQUIREMENTS

1.1 Preserve the simulation

The governing principle remains:

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

All changes must preserve:

- Conservation of physical goods and money.
- Deterministic simulation behavior.
- NPC and player economic parity.
- Real ownership and inventory.
- Physical production, transportation and consumption.
- Existing NPC decision-making and pathfinding.
- Save-file integrity.
- Existing approved economic rules.

Visual improvements must not silently alter gameplay or simulation outcomes.

1.2 MSW-01 — Minimum Sufficient Work

Follow the permanent engineering directive:

Do the work necessary to achieve a correct, reliable, complete result. Do not perform additional work merely to demonstrate thoroughness.

Before launching work, identify:

1. What needs to change.
2. What valid evidence already exists.
3. What uncertainty remains.
4. The smallest implementation that resolves it.
5. What focused validation is necessary.
6. The conditions for stopping.

Do not rerun passing full simulation suites merely for reassurance.

Do not launch unnecessary agents, audits, investigations or speculative refactoring.

Reuse existing repository assets, systems and passing test evidence.

1.3 Work coordination

Use parallel workers only when the work is genuinely independent and doing so reduces total development time.

Avoid multiple workers editing the same UI or rendering files.

Preserve a clear integration branch and commit history.

Do not publish a build or release without explicit owner approval.

---

PART 2 — CHARACTER CREATION

CC-01 — Integrate the existing random character creator

The repository already contains a random character creator application or asset that the project is permitted to use.

The existing eight-character selection system must be replaced with the character creator.

Required behavior

During the game's introduction:

1. Open the character creation interface.
2. Allow the player to generate a random appearance.
3. Allow customization of the appearance features actually supported by the existing asset.
4. Show a preview of the resulting character.
5. Allow the player to confirm their appearance.
6. Enter the game using that appearance.

Starting character restrictions

The player begins as an ordinary medieval villager.

Character creation must not grant:

- Armor.
- Upgraded weapons.
- Free equipment.
- Additional starting wealth.
- Combat bonuses.
- Special classes or professions.

Preserve the previously approved starting inventory and economic balance.

Ordinary civilian clothing is appropriate.

Persistence

The selected character appearance must persist through:

- Saving and loading.
- Movement and directional animations.
- Equipment changes.
- Hairstyle changes.
- Interior and exterior rendering.
- Other existing character animation states.

Asset requirements

Inspect the existing generator before implementation.

Identify its supported:

- Body and appearance variants.
- Hair and facial options.
- Clothing layers.
- Animation directions.
- Sprite dimensions.
- Export formats.
- Licensing and attribution requirements.

Reuse the existing assets and generation logic rather than building a second generator.

If the generator cannot directly produce compatible runtime sprites, report the required adaptation.

Do not invent unsupported customization options.

---

PART 3 — BARBER SHOP

BARBER-01 — In-world hairstyle customization

Add a barber shop service that allows the player to change their hairstyle after character creation.

Required behavior

The player visits an actual barber or barber shop in the village.

The interface presents compatible hairstyle choices from the existing character assets.

The player previews the selected hairstyle and confirms the change.

The appearance change persists through saving, loading and animation.

Economic integration

The barber must ultimately function as a legitimate village service provider.

The barber should participate in the existing economy rather than operating as an unlimited free customization menu.

Respect:

- NPC ownership.
- Actual payment.
- Service availability.
- Normal NPC economic behavior.
- Existing employment and business systems.

Do not invent service prices, barber wages, resource consumption or production requirements.

Present unresolved economic rules for owner approval.

Do not make a barber shop a prerequisite for starting a new game.

---

PART 4 — ARMOR SYSTEM

ARMOR-01 — Integrate existing armor sprite sheets

The repository contains armor sprite sheets that must be inspected and integrated into the character equipment system.

Armor is not part of character creation.

Armor must be obtained during gameplay.

Acquisition

Players should be able to acquire armor through legitimate gameplay, including purchasing it from an armorer when available.

Armor must exist as an actual inventory item.

A player cannot simply select any armor appearance from an unlimited cosmetic menu.

An armorer's stock must follow the game's normal production, inventory, ownership and trade rules.

Visual equipment

Equipping armor changes the visible appearance of the character.

Removing armor restores the appropriate underlying appearance.

Armor layers must work with the existing character sprite system and supported directional animations.

Inspect compatibility with the random character generator before committing to an implementation approach.

Armor classification

Each distinct armor item or set should support an appropriate classification system.

Investigate:

- Armor class or protective rating.
- Durability or item hit points.
- Rarity.
- Weight.
- Movement effects where applicable.
- Material composition.
- Crafting requirements.
- Production requirements.
- Purchase price.
- Availability and scarcity.

Important distinction

The sprite sheets establish the artwork, not necessarily the gameplay statistics.

Inspect associated metadata and existing equipment definitions before assigning any values.

Do not fabricate armor statistics from appearance alone.

Do not assume traditional RPG rarity tiers are already approved.

Present the available armor variants and proposed classification framework for owner review.

Rarity and availability should remain consistent with the physical economy.

Scope boundary

Do not invent a complete combat overhaul as part of integrating armor visuals.

Reuse existing combat and equipment mechanics wherever possible.

If additional protection or durability mechanics are required, identify the dependency and request the necessary owner decisions.

---

PART 5 — BUILDING ENTRANCE TRANSITIONS

VIS-DOOR-01 — Correct NPC building entry and exit

Observed defect

NPCs currently appear to walk underneath the visible closed doorway sprite when entering a building.

The intended doorway transition is missing or not functioning.

Intended behavior

When a character approaches a building entrance:

1. The normal doorway changes to a dark opening.
2. The character walks toward and into that opening.
3. As the character crosses the threshold, the character gradually becomes visually obscured.
4. Once the character is fully inside, the normal doorway appearance returns.

When a character exits, the visual sequence reverses.

Required technical behavior

- Do not allow characters to visibly pass underneath a closed door.
- Preserve existing pathfinding and building access rules.
- Support multiple NPCs using the same doorway.
- Avoid premature door closing.
- Avoid flickering during overlapping entry and exit transitions.
- Avoid character clipping through exterior walls.
- Preserve appropriate sprite depth ordering.
- Ensure the visual transition does not trap characters or interrupt their jobs.

Inspect existing doorway, masking, occlusion and rendering code before implementing.

This is primarily a visual correction, not a redesign of building navigation.

---

PART 6 — STATUS AND PROGRESS INDICATORS

UI-PROGRESS-01 — Improve progress bar visibility

Observed defect

A pale white progress/status bar near the center of the screen is nearly invisible against light-colored terrain and building interiors.

Required behavior

Make the indicator clearly visible against both light and dark backgrounds.

Use:

- A dark or appropriately contrasting background track.
- A clearly distinguishable progress fill.
- A visible outline or border.
- Consistent pixel-art styling.

The indicator should remain readable at empty, partial and full progress.

Additional requirements

Determine what action or entity the indicator represents.

Ensure its position and behavior communicate that relationship clearly.

Preserve existing progress calculations, timing and gameplay behavior.

Apply consistent styling to equivalent indicators where practical.

Avoid introducing oversized UI elements that obscure gameplay.

---

PART 7 — HUNGER HUD ICON

UI-HUNGER-01 — Replace the ambiguous food icon

Observed defect

The green hunger or nourishment bar uses a yellow icon that resembles a stick of butter or a gold bar.

It does not clearly communicate food.

Required change

Replace the existing icon with a recognizable pixel-art food symbol.

Preferred design: a chicken drumstick.

Match the existing HUD's:

- Pixel-art resolution.
- Icon scale.
- Outline treatment.
- Alignment.
- Visual weight.

Preserve the existing red health bar, green food bar and yellow stamina bar.

Do not change their underlying values, behavior or positioning.

This is an icon replacement, not a HUD redesign.

---

PART 8 — IN-GAME WIKI REDESIGN

UI-WIKI-01 — Replace the button wall with a usable encyclopedia

Observed defect

The in-game wiki contains valuable information, but its layout is crowded and difficult to navigate.

The current interface presents dozens of irregularly sized buttons across the screen.

The heading incorrectly identifies the interface as SETTINGS.

The user cannot easily locate topics or read information comfortably.

Required redesign

Create a structured encyclopedia interface using the existing wiki data.

Suggested title:

Village Encyclopedia

Navigation

Provide:

- Clear category navigation.
- Search across existing topics and articles.
- Consistent button or navigation-item sizing.
- Predictable back navigation.
- Readable article pages.
- Appropriate scrolling.
- Clear keyboard and controller focus.
- A straightforward way to return to gameplay.

Desktop layout

Where screen space permits, favor:

- Left navigation or category panel.
- Main article-reading panel.
- Search near the top.
- Clear article headings.

Smaller screens

Adapt the layout for controller and smaller-screen use without clipped text or inaccessible navigation.

Existing content

Preserve all current wiki information, including:

- How-to articles.
- Tools.
- Weapons and armor.
- Food and drink.
- Medicine.
- Materials.
- Recipes.
- Gathering.
- Stations.
- Skills.
- Animals.
- Professions.
- Controls.
- Game mechanics.
- Features not yet implemented.

Preserve the distinction between mechanics currently available and mechanics planned for the future.

Data integrity

The wiki is generated from the game's actual data.

Do not replace that system with manually invented information.

Reuse the current data generation, article linking and content architecture.

This task is a UI redesign, not a wiki rewrite.

---

PART 9 — WHEAT AND CROP VISUALS

VIS-CROP-01 — Make ripe wheat recognizable

Observed defect

Wheat that is ready for harvesting looks like recently planted soil with tiny green sprouts.

The player cannot identify mature wheat without reading the interaction prompt.

Required visual states

Provide clearly distinguishable representations for:

Planted: Exposed soil with small sprouts.

Growing: Taller green plants with visibly increasing coverage.

Mature: Dense golden wheat with recognizable heads of grain.

Harvested: Cut stubble and exposed soil.

Asset investigation

First inspect the existing repository and licensed asset collections for suitable wheat sprites.

If compatible assets already exist, reuse them.

If they do not, identify the gap and propose the smallest suitable replacement or adaptation.

Implementation

Use the existing crop growth and harvest states to select the appropriate visual representation.

Preserve:

- Crop yields.
- Growth rates.
- Seasonal behavior.
- Harvest labor.
- Field ownership.
- Theft rules.
- Seed reservations.
- Cattle feed priority.
- Conservation.

Do not change farming mechanics to solve a visual problem.

The mature field should be recognizable at normal gameplay zoom.

---

PART 10 — ANIMAL SPRITE ARTIFACTS

VIS-ANIMAL-01 — Remove stray sprite fragments

Observed defect

Pigs, chickens and sheep display stray pixels or horizontal sprite fragments floating above them.

The artifacts appear disconnected from the animals.

Investigation

Inspect:

- Animal sprite sheets.
- Atlas coordinates.
- Frame boundaries.
- Frame dimensions.
- Margins and spacing.
- Animation frame indices.
- Sprite origins and offsets.
- Directional animation definitions.

Determine whether neighboring sprite-sheet content is being accidentally included in rendered frames.

Do not assume the cause until the asset and rendering definitions have been inspected.

Required correction

Remove the stray fragments at their source.

Do not conceal them with arbitrary masking or additional decorative sprites.

Preserve:

- Existing animal artwork.
- Animal movement.
- Animation timing.
- Breeding.
- Feeding.
- Ownership.
- Economic behavior.

Check all animals sharing the same sprite extraction system, not just the three species in the screenshots.

Use focused visual validation.

---

PART 11 — APPROVED FARM-CROP-01 INTEGRATION

FARM-CROP-01 — Proportional harvest sharing

Owner decision: Approved for Build 18.

The implementation already exists on:

"wip/farm-cropshare"

Commit:

"132960a"

This branch was created from Build 17's game code and must not be merged into Build 17.

Approved behavior

When a field cutting completes:

1. Preserve the existing seed reservation.
2. Feed the field's cattle first, using the existing cattle-feed rules.
3. Divide the remaining crop among the farmers actively cutting that field.
4. Allocate shares proportionally to each farmer's actual cutting labor.
5. Equal labor earns equal shares.
6. Zero cutting labor earns zero share.
7. The first farmer to finish does not receive the entire harvest.
8. Remaining cutters stop appropriately and retain their earned shares.
9. Resolve indivisible units deterministically using the existing approved remainder rule.
10. Preserve all crop units without creation or loss.
11. Preserve existing household pantry top-up behavior.

Existing validation

The implementation already passed focused crop-sharing checks, related farming and conservation suites, and a 30-day seed-one run without reported leaks or starvation.

Reuse this evidence wherever applicable.

Do not rerun the entire campaign merely because this code is being incorporated into Build 18.

Run additional targeted validation only where integration changes invalidate the existing evidence.

Existing unresolved question

The current seed reservation still follows the preexisting rule that assigns reserved seed to the farmer who finishes.

Whether seed should also be shared remains an independent owner decision.

Do not change the seed rule without approval.

Farming switches

Both FARM-08 farming switches remain OFF unless separately authorized.

Do not introduce speculative cattle-economy balance changes during this integration.

---

PART 12 — EXISTING EXPANSION 18 DECISIONS

This master directive does not replace or reopen the existing Expansion 18 design decisions.

In particular:

Q18-11B — Approved

Settlement industry capability is based on people's experience, capped by available facilities.

Maintain two separate values:

Workforce capability: Experience and knowledge of the settlement's workers.

Effective capability: Workforce capability limited by available operational facilities.

Both use the approved 0–10 scale.

Facility shortages must not erase accumulated worker experience.

Pay and output multipliers use effective capability.

Capability levels do not determine whether a person is allowed to work.

Still awaiting owner approval

- Experience formulas.
- Tenure accumulation rules.
- Facility caps.
- Threshold values.
- Q18-11A pay and output multipliers.

Do not invent final numerical values for these systems.

Preserve all previously settled Expansion 18 owner decisions.

---

PART 13 — IMPLEMENTATION ORDER

Organize the work by dependency and risk, not simply by the order of this document.

Phase A — Repository inspection and inventory

Perform a focused inventory of:

- Existing character generator.
- Character animation and appearance systems.
- Armor sprite sheets and metadata.
- Existing equipment and combat definitions.
- Barber or comparable service systems.
- Doorway rendering and transitions.
- Progress indicator components.
- HUD icon assets.
- Wiki UI and data generation.
- Crop sprite sheets and growth-state rendering.
- Animal atlas and animation definitions.
- FARM-CROP-01 integration requirements.

Report what already exists and what genuinely needs to be added.

Do not conduct a broad unrelated repository audit.

Phase B — Low-risk visual corrections

Address the relatively isolated visual defects:

1. Hunger icon.
2. Progress indicator contrast.
3. Animal sprite artifacts.
4. Wheat growth-stage presentation.

Reuse compatible existing assets.

Keep these changes isolated from simulation mechanics.

Phase C — World presentation

Implement the building entrance transition.

Validate entry, exit, simultaneous doorway use and sprite occlusion.

Phase D — Wiki usability

Redesign the encyclopedia navigation and article presentation while preserving generated content.

Phase E — Character and equipment integration

Integrate the existing character creator.

Develop the appearance persistence and equipment layering required for armor.

Plan the barber service and armor economy using the actual repository assets and existing economic systems.

Obtain owner approval for unresolved mechanics and numerical values before implementing them.

Phase F — FARM-CROP-01

Integrate the approved proportional harvest sharing implementation into the Build 18 integration branch.

Preserve its tested behavior and reconcile any genuine integration conflicts.

Phase G — Focused integration validation

Validate the changed systems.

Review the resulting gameplay visually.

Confirm that simulation invariants remain intact.

Use existing passing evidence whenever it still applies.

Do not automatically rerun every historical test campaign.

---

PART 14 — ACCEPTANCE CRITERIA

Build 18's work is ready for owner review when:

- The character creator replaces the eight preset character choices.
- Players begin in ordinary civilian clothing without free armor.
- Character appearance persists through gameplay and save/load.
- The barber service's approved scope is implemented, with unresolved economic rules escalated rather than invented.
- Available armor assets are integrated into the approved equipment system, with unapproved balance mechanics clearly separated.
- NPCs visibly enter and exit buildings through proper doorway transitions.
- Progress indicators remain visible against varied backgrounds.
- The hunger icon is immediately recognizable as food.
- The wiki is navigable, searchable and readable.
- Mature wheat visibly looks ready to harvest.
- Animal sprites no longer display stray fragments.
- Proportional harvest sharing is integrated without conservation defects.
- Existing economic and simulation behavior remains intact except where specifically approved.
- Required tests and visual checks pass.
- All changes are documented and traceable.

Do not claim completion of features whose economic rules or numerical mechanics are still awaiting owner decisions.

---

PART 15 — REQUIRED REPORT BACK

Before substantial implementation, provide a concise integration report covering:

1. Existing assets found: Character generator, armor sprites, crop sprites and relevant UI components.
2. Directly reusable systems: What can be integrated without redesign.
3. Missing functionality: What actually requires new code or assets.
4. Implementation assignments: Which independent tasks can safely proceed in parallel.
5. Owner decisions required: Only genuine unresolved choices, presented one at a time.
6. Build 17 protection: Confirmation that its frozen release candidate and validation remain untouched.

After implementation, report:

- Completed features and fixes.
- Relevant commits and branches.
- Focused validation results.
- Remaining blockers.
- Any deferred decisions.
- Build 18 integration readiness.

Do not build, publish or release without owner authorization.

---

FINAL OWNER INSTRUCTION

Build 18 should feel like a more complete game, not simply a more complicated simulation.

Players should understand what they are seeing.

They should recognize ripe crops, understand their status indicators, watch villagers enter buildings naturally, navigate the wiki comfortably, create their own characters, change their appearance and visibly wear armor they have actually acquired.

Use the assets we already own.

Preserve the economy and the simulation.

Do not introduce unapproved mechanics.

Do not waste development effort proving things that have already been established.

Protect Build 17. Integrate deliberately into Build 18. Deliver a playable, coherent improvement.
