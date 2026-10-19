# Permanent asset integration system

Owner directive, received 2026-10-19T16:50:04.254Z (verbatim; kept so approved requirements stay traceable).

---

MY MEDIEVAL LIFE — PERMANENT ASSET INTEGRATION SYSTEM

OWNER DIRECTIVE — CREATE AND ACTIVATE A REUSABLE CLAUDE CODE SKILL

You are authorized and instructed to establish a permanent, autonomous asset discovery, processing, scaling, and integration system for My Medieval Life.

This is a standing project directive intended to eliminate repeated discussions about asset licensing, scaling, discovery, and implementation.

The project owner has already supplied the asset packs and their available licensing documentation specifically so these assets can be used in the game.

The owner does not want to manually inspect thousands of files, identify every useful sprite, specify every animation, or repeatedly explain where individual assets should be used.

That is the development team's responsibility.

Your job is to discover the contents, identify opportunities, make reasonable implementation decisions, and integrate the assets into the living game world.

Do not simply inventory assets and stop.

---

1. CREATE THE PERMANENT SKILL

Create a reusable Claude Code project skill named:

"asset-integration-pipeline"

Use the project's supported Claude Code skill structure, preferably:

".claude/skills/asset-integration-pipeline/SKILL.md"

Include supporting reference files or scripts as appropriate.

The skill must cover:

- Asset discovery and inventory
- Asset classification
- License-document discovery and recording
- Pixel-art scaling and alignment
- Sprite-sheet extraction
- Animation identification
- Texture and sprite optimization
- Godot resource integration
- Collision and navigation setup
- Gameplay opportunity discovery
- Cross-system integration
- Automated validation
- Documentation and asset provenance
- Integration prioritization
- Regression prevention

Use scripts where practical so routine processing does not require repeated manual investigation or large amounts of agent context.

Do not create a skill that merely explains how to perform these tasks.

Create a skill that can actually guide and support their execution.

2. PERMANENT ACTIVATION THROUGH CLAUDE.MD

Update the repository's existing root "CLAUDE.md".

Preserve all existing project instructions.

Add a mandatory policy stating:

Asset Integration Policy

Whenever new asset packs, sprites, textures, animations, models, tilesets, environmental objects, or related asset files are introduced, the development agent must activate the "asset-integration-pipeline" skill.

The agent must independently inspect the assets, identify useful content, determine appropriate scaling, and integrate suitable assets into existing or planned gameplay systems.

The owner is not required to identify each asset or explain its intended use.

All development agents and subagents working with assets must follow this policy.

Previously supplied and approved asset packs must not be repeatedly presented to the owner for authorization.

The agent must consult the project's existing asset registry and license documentation before raising a licensing question.

Asset integration is a normal part of development, not a separate activity that requires repeated permission.

Do not remove or weaken existing World Design Rules, development requirements, or agent instructions.

3. OWNER AUTHORIZATION AND LICENSING

The owner has explicitly authorized the use of the supplied asset packs for development of My Medieval Life.

The owner has also provided the available licensing documentation.

Record that authorization permanently.

Do not confuse repository visibility with gameplay implementation permission.

A public source repository, a private development repository, and a distributed compiled game are different distribution contexts.

Do not automatically reject an asset because its original source files cannot be redistributed publicly.

Instead:

1. Locate the license and supplied documentation.
2. Identify the actual permissions and restrictions.
3. Record the license source and approved uses in the asset registry.
4. Use the assets in permitted development and game-distribution contexts.
5. Keep original third-party source packs out of public distribution when their terms require it.
6. Use appropriate private storage, packaging, or build-time asset delivery when necessary.
7. Preserve required attribution and notices.
8. Avoid repeated licensing discussions after a pack has been reviewed.

Do not interpret this directive as permission to violate an actual license restriction.

If a particular asset has a genuine, specific legal restriction that prevents the intended use, identify the exact restriction and seek a compliant implementation.

Escalate only an unresolved, material restriction. Do not turn routine license documentation into a development blocker.

The objective is to use the assets, not manufacture reasons to leave them unused.

4. BUILD A PERMANENT ASSET REGISTRY

Create or update a persistent registry, such as:

"docs/assets/ASSET_REGISTRY.md"

Maintain machine-readable metadata as well where useful.

For each pack record:

- Pack name
- Source
- Version
- Original file location
- License-document location
- Verified usage permissions
- Asset categories
- File count
- Sprite and texture dimensions
- Animation availability
- Intended gameplay opportunities
- Current integration status
- Relevant scenes, scripts and resources
- Scaling requirements
- Dependencies
- Known issues
- Future integration opportunities

Do not lose this information between builds or agent sessions.

Do not duplicate an existing registry if one already exists.

5. DISCOVER EVERYTHING, NOT JUST THE OBVIOUS ASSETS

Inspect every accessible supplied asset pack.

Do not stop after reading filenames or inspecting preview images.

Where practical, examine sprite sheets, animation frames, tilesets, directories, metadata and documentation.

Discover assets that the owner may not have noticed.

For example, a pack primarily advertised as environmental art might also contain:

- Useful crafting equipment
- Furniture
- Carts and wagon components
- Doors and gates
- Food or crops
- Fences and walls
- Water features
- Terrain transitions
- Animated objects
- Containers
- Tools
- Animals
- Building decorations

These examples are illustrative, not an exhaustive checklist.

Classify discovered assets by their potential gameplay function.

Identify unexpected opportunities that would make the world more interactive and interconnected.

Do not require the owner to review thousands of individual assets.

6. ESTABLISH A CONSISTENT SCALING STANDARD

The existing game uses a 16-pixel tile grid.

This does not mean every sprite must be 16×16 pixels.

Establish a coherent world-scale convention using existing playable scenes and characters as references.

Define appropriate proportions for:

- Human characters
- Children and adults
- Animals
- Horses and livestock
- Furniture
- Doors and buildings
- Trees and vegetation
- Crops
- Crafting stations
- Carts and wagons
- Terrain features
- Environmental objects

Preserve original source files.

Create game-ready versions or import transformations when appropriate.

Use nearest-neighbor filtering for pixel art unless the existing art direction requires otherwise.

Prefer integer scaling when it preserves visual quality, but do not blindly apply one multiplier to every pack.

Consider the actual visible content bounds of sprites, not just their canvas dimensions.

For every integrated object, verify:

- Visual proportions
- Ground contact point
- Sprite origin
- Collision geometry
- Navigation clearance
- Interaction range
- Animation alignment
- Sorting and layering
- Tile-grid compatibility

Document the scaling standard in:

"docs/assets/ASSET_SCALING_STANDARD.md"

Where possible, automate routine scaling and import operations.

Different source resolutions are an integration problem to solve, not a reason to abandon an asset pack.

7. CREATE A REUSABLE PROCESSING PIPELINE

Implement practical processing utilities for:

- Identifying image dimensions
- Detecting sprite-sheet layouts
- Extracting frames
- Generating sprite animations
- Converting supported image formats
- Applying consistent scaling
- Preserving transparency
- Validating texture imports
- Checking resource references
- Detecting missing frames
- Detecting broken animations
- Reporting unused assets

Use the existing project language and tools where appropriate.

Avoid unnecessary dependencies.

Do not destructively modify original asset packs.

Make processing reproducible so future agents do not repeat the same manual work.

8. INTEGRATE ALL SUITABLE PACKS

Every accessible, approved asset pack must receive an integration plan.

The goal is to incorporate all suitable assets that improve the game, not force every duplicate or irrelevant sprite into gameplay.

Do not consider a pack integrated merely because its files have been copied into the repository.

An asset is meaningfully integrated when it is used by an appropriate game system, scene, animation, environment or player-facing feature.

Prioritize integration into existing systems before inventing unrelated mechanics.

Where an asset enables a useful new mechanic consistent with the World Design Rules, evaluate and implement it when feasible.

Avoid purely decorative implementation when a meaningful interaction is appropriate.

Examples:

- A cart should support transportation or the economy rather than existing only as decoration.
- A crop should participate in farming, harvesting, consumption or trade.
- A crafting station should support an actual production process.
- An animal should participate in wildlife, livestock, hunting or other appropriate systems.
- A container should work with storage and inventory where applicable.

Preserve the game's existing design philosophy:

If I can't get lost in my own game, it's not alive enough.

9. PROACTIVE GAMEPLAY DISCOVERY

For each pack, independently identify opportunities to strengthen the game.

Ask internally:

- What existing system could benefit from this asset?
- Does it complete a missing production chain?
- Does it enable a new interaction?
- Does it improve player feedback?
- Could NPCs use it?
- Could it participate in the economy?
- Does it help a profession?
- Could it create an emergent gameplay situation?
- Does it fill a known gap in the Interlocking Systems Manifest?
- Could it make a village, wilderness area or household behave more believably?

Do not limit discovery to the owner's explicit examples.

The owner expects the development agents to find useful possibilities independently.

Prioritize high-value discoveries that fit the current development roadmap.

Record lower-priority opportunities without disrupting active work.

10. APPLY THE SYSTEM TO CURRENT ASSET PACKS

Immediately apply the new skill to all accessible asset packs supplied for Build 13 and Build 14.

Include, where present:

- MiniFolks forest animals
- Skeleton assets
- Forgotten Memories assets
- Animal Farm assets
- Craftpix plant and crop assets
- Any additional supplied packs or files not captured by the prior audit

Do not assume the previous audit identified every pack or every useful asset.

Reinspect available contents and determine actual integration opportunities.

Pay particular attention to current development involving:

- Carts and transportation
- Horses
- Wildlife
- Skeletons
- Farming and crops
- Fruit trees
- Environmental traversal
- Village structures
- Functional environmental objects

Do not invent unavailable assets.

If an archive format cannot be opened by the current environment, investigate available compatible extraction tools or alternative access methods before asking the owner to repack it.

If extraction remains genuinely impossible, record the precise technical blocker and continue with the other packs.

Do not hold up unrelated development.

11. INTERLOCKING SYSTEMS COMPLIANCE

Maintain the existing Interlocking Systems Manifest.

Do not create a duplicate.

Whenever asset integration adds or strengthens a gameplay interaction, update the relevant manifest entries.

Respect the permanent World Design Rules.

Focus especially on:

- Material interdependency
- Professional interdependency
- Economic consequences
- NPC autonomy
- Finite resources
- Real consumption
- NPC prosperity and competition
- Emergent gameplay

An asset that enables several interconnected gameplay interactions is generally more valuable than one that serves only a cosmetic purpose.

12. TESTING AND QUALITY CONTROL

For every significant integration, validate the relevant behavior.

Include checks for:

- Missing textures
- Broken resource paths
- Incorrect frame extraction
- Sprite clipping
- Incorrect animation timing
- Collision problems
- Navigation obstruction
- Incorrect interaction distances
- Visual sorting errors
- Performance regressions
- Save/load compatibility
- Gameplay integration failures

Use automated tests where possible.

Perform real runtime inspection where the environment supports it.

Do not claim visual correctness solely because an import script succeeded.

Record what was verified and what still requires actual-device playtesting.

13. AUTONOMOUS EXECUTION

This is a standing authorization to perform normal asset integration work.

The owner should not need to approve routine decisions such as:

- Which useful sprites to extract
- Which compatible assets to integrate
- How to scale ordinary environmental objects
- How to configure animations
- How to align sprites with the world grid
- How to add appropriate collision shapes
- How to connect assets to existing mechanics
- How to organize asset metadata
- How to prioritize straightforward integration opportunities

Use sound development judgment.

Continue normal Build 14 work while introducing this pipeline.

Do not cancel active development or unnecessarily redirect agents.

Do not initiate a new public release or merge into main without the existing release authorization.

If an integration requires a substantial redesign or creates a genuine conflict with established game mechanics, record the issue and use the existing planning process.

Do not ask the owner to micromanage routine asset work.

14. PREVENT FUTURE REPETITION

The following must become permanent project knowledge:

1. The owner supplies assets because they are intended for use.
2. Existing license documentation must be consulted before raising new concerns.
3. Public repository visibility does not automatically prohibit compiled-game integration.
4. Asset scaling is a normal development responsibility.
5. The owner is not responsible for identifying every useful asset.
6. Agents must proactively discover opportunities.
7. Assets should strengthen functional gameplay wherever practical.
8. Previously resolved issues must not be repeatedly reopened without new evidence.
9. Future asset packs automatically enter the discovery and integration pipeline.
10. The skill and asset registry must be maintained across future builds.

15. VALIDATE THE SKILL ITSELF

We previously discovered that some installed efficiency skills were not actually being invoked.

Do not repeat that failure.

Verify that the new skill:

- Is installed in the correct location.
- Has valid skill metadata.
- Is discoverable by Claude Code.
- Is referenced by "CLAUDE.md".
- Can be used by relevant development agents.
- Is actually invoked during an asset integration task.
- Produces useful registry updates and integration work.

Where supported, use appropriate activation mechanisms.

Do not claim automatic invocation is guaranteed unless it has been verified.

16. COMPLETION CRITERIA

This directive is complete only when:

- The reusable skill exists.
- The root "CLAUDE.md" contains the permanent policy.
- An asset registry exists and is populated.
- A scaling standard exists.
- Reusable processing tools are implemented where practical.
- Existing packs have been inspected.
- Integration opportunities have been identified.
- Suitable assets are actively being incorporated into gameplay.
- Automated validation is functioning.
- Future agents have clear instructions to continue the process.

Do not report success after merely writing documentation.

Demonstrate that the system works by processing and integrating representative assets.

Then continue integrating the remaining suitable assets through the normal development workflow.

17. FINAL REPORT

Provide a concise summary containing:

- Skill location and activation verification
- "CLAUDE.md" changes
- Asset registry location
- Scaling standard
- Processing tools created
- Packs discovered
- Assets newly integrated
- Previously unused assets now functional
- Gameplay systems strengthened
- Remaining integration opportunities
- Genuine unresolved blockers
- Relevant commit IDs

The goal is a permanent system that lets the owner provide asset packs once and have the development team handle discovery, scaling, integration and verification from that point forward.

Do the work, preserve the knowledge, and stop requiring the owner to repeat established instructions.
