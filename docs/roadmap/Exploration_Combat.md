# Exploration_Combat (text extracted from the owner's docx, 2026-10-21)

Source: docs/roadmap/source/Exploration_Combat.docx (Expansion Documentation Pack, supplied by the owner 2026-10-21). Paragraphs as in the original; tables flattened one cell per line.

Exploration and Combat — World Content Expansion
My Medieval Life | Implementation-ready design baseline | 21 October 2026
DOCUMENT STATUS: Consolidates approved requirements with explicitly labeled proposed implementation stages. Proposed numbering for 21–23 is not yet an owner-approved register assignment.
Governing constraints
Owner-approved directives and existing repository rules take precedence over proposed engineering detail. The world remains finite and autonomous. Every item, coin, event, death, relationship and political action needs legitimate provenance. A village may fail; the simulation may not cheat to save it. Preserve seeded determinism, save migrations, the existing development ledger, Interlocking Systems Manifest, and in-game Wiki. Expansion means active coding on an isolated branch; Build means final acceptance and packaging; Release means published three-platform artifacts.
Authoritative references
docs/DEVELOPMENT_LEDGER.md, B14-09, CQ-01, FR-01
docs/directives/2026-10-19_sword_combat.md
docs/WORLD_DESIGN_RULES.md, Rules 013, 016 and 022
docs/DECISIONS.md, cave skeletons and enemy asset notes
Purpose and scope
Exploration rewards travel through a consequential medieval world, not disconnected arenas. Combat, hazards, ruins, caves and creatures must interact with real inventory, risk, NPC memory, wildlife and economy.
Existing sword-combat work and tests must be reused; do not rewrite it without identifying an actual defect.
World and locations
Build from existing terrain, navigation, caves, ruins, woods, settlements and underground mining maps. Distinguish accessible routes, danger zones, visibility, encounter habitats and navigation limits.
Locations may contain resources, hazards, clues, threats and discoverable history. Loot must have legitimate origin and bounded availability; no unlimited material creation.
Combat mechanics
Audit sword input buffering, reach, attack phases, hit detection, walls, knockback and response. Ledger CQ-01 reports automated tests passed, device playtest pending.
Combatants use actual equipment, health, positioning, visibility, stamina or other already-approved attributes; avoid inventing an entirely new stat system.
Record significant injuries, deaths, rescues, crimes, battles, witnesses and property damage for judgment, guards and generational history.
Approved creature content
B14-09: skeletons inhabit caves and uncleared woods, guard during the day and roam at night, with a three-day respawn rule and bone/rusty-gear drops. Preserve the exact owner decision unless later superseded.
FR-01: lizards and spiders are approved enemy types but their assets were still flagged as missing in the ledger. Do not declare them complete without usable assets.
Other dungeons, castles and enemies should be tagged proposed unless supported by a specific existing directive.
Ecology, faction and mining interaction
Do not treat wildlife like infinite combat targets; preserve protected refuges and natural recolonization.
Bandit encounters use faction membership, actual supplies, patrols, witnesses and crime consequences, not purely randomized hostile spawns.
Mining caves may contain exploration threats, but the same ore deposit objects and depletion rules apply above and below ground.
Progression and interface
Exploration discoveries may affect map knowledge, NPC dialogue, contracts and trade. Rewards come from found, crafted, earned or legitimately looted items.
Android controls need readable attack prompts, clear feedback, sensible target selection and keyboard dismissal; verify Windows/Linux controller and keyboard use.
Phases (proposed)
EX-A audit existing sword code, maps, creature AI, assets and approved encounters.
EX-B complete verified sword usability and cave/wood skeleton behaviors.
EX-C implement exploration location state, threat/navigation and finite loot provenance.
EX-D integrate bandits, wildlife, injuries, guards, memory and mining caves.
EX-E add approved enemy assets when available, then run device and long-run tests.
Acceptance
Sword attacks respect reach, phases and intervening walls; physical device testing complements existing automated evidence.
Skeleton day/night and three-day respawn behavior follow approved rules, with bounded and traceable drops.
Killing wildlife has ecological consequences; stealing loot from a person creates real loss and possible criminal evidence.
Save/load cannot duplicate enemies, corpses or treasure; caves and deposits maintain identical depletion mechanics.
Open scope boundaries
A large handcrafted dungeon system, magic combat, new monster classes, combat skill trees or boss mechanics are not authorized by the reviewed evidence. Treat them as optional future design questions, not commitments.
Handoff checklist
Reconcile this specification against current branch and owner decisions before coding.
Create or update existing development-register tasks, not a second backlog.
Record data schema and save migrations; protect inventory, currency and history conservation.
Use narrow tests for changed code and reuse relevant green CI.
Keep expansion work on remote GitHub staging/WIP branch; do not publish a build until the build stage.
Update in-game Wiki, developer documentation and Interlocking Systems Manifest.