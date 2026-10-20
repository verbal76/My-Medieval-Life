# Owner directive, 2026-10-20: two immediate decisions and three future expansions (verbatim)

Supporting documents, stored unchanged beside this file:
- `My_Medieval_Life_Mining_Industry_Expansion.pdf` (Mining & Industrial Development Expansion)
- `My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf` (Settlement Advancement & Regional Economy Expansion)
- `My_Medieval_Life_Judgment_Decision_Engine_Master_Spec.pdf` (NPC Judgment System Expansion: Subjective Judgment & Universal Decision Engine)

---

MY MEDIEVAL LIFE

MASTER DEVELOPMENT DIRECTIVE — TWO IMMEDIATE DECISIONS AND THREE FUTURE EXPANSIONS

Claude,

This directive resolves the remaining two operational questions from your recent status report and formally approves three separate future development objectives.

I am providing three supporting design documents:

1. Mining & Industrial Development Expansion
2. Settlement Advancement & Regional Economy Expansion
3. NPC Judgment System Expansion

These are three distinct expansion plans. Do not combine them into one development build, and do not treat them as instructions to implement all three immediately.

The current priority remains achieving and verifying simulation equilibrium through Builds 15 and 16.

---

PART I — TWO IMMEDIATE OPERATIONAL DECISIONS

DECISION 1 — GITHUB PULL REQUEST #1

You are authorized to resolve PR #1 as routine repository maintenance.

Before closing it:

1. Inspect the pull request and identify all changes it contains.
2. Compare those changes against the actual current remote development and staging branches.
3. Determine whether every useful change has already been merged, preserved, or intentionally superseded.
4. If the pull request is redundant, close it with a concise explanatory comment.
5. If unique, useful work remains, preserve it in an appropriate remote GitHub branch before closing the pull request.
6. Do not discard unique work or merge obsolete code simply to clear the pull request.

No additional owner approval is required for routine closure once preservation has been verified.

Report the final PR status, the reason for closure or retention, and any work that required preservation.

DECISION 2 — ANDROID SIGNING AND SAVE CONTINUITY

The permanent Android signing-key decision is deferred.

I do not want to establish, rotate, manage, or troubleshoot a permanent signing key tonight.

Instead, proceed with a save-continuity architecture that allows separate private testing builds to access and upgrade existing game saves.

Approved approach

Use a persistent, user-selected save location or an equivalent Android-supported document-access/export-and-import workflow.

The objective is to allow the owner to uninstall an old test build, install a new test build, reconnect to the existing save, and continue playing the same world.

Do not assume that Godot's private "user://" storage survives uninstalling an application.

Mandatory save-system requirements

1. Inspect and document the current save architecture before modifying it.
2. Establish a stable save identity independent of individual build numbers.
3. Implement explicit save-schema versioning.
4. Support forward migration from older supported save formats into newer formats.
5. Back up the original save before attempting migration.
6. Validate the migrated save before adopting it.
7. Preserve the original if migration fails.
8. Never silently destroy, overwrite, or corrupt the only usable save.
9. Provide a clear way to reconnect to an existing save after an Android reinstall.
10. Use supported Android storage and permission mechanisms rather than relying on unrestricted access to arbitrary external filesystem paths.
11. Apply the same save-versioning and migration principles to Windows and Linux.
12. Test migration of persistent world data, including terrain changes, resources, NPCs, households, relationships, buildings, inventories, settlements, and simulation state.
13. Preserve unknown or future-compatible data where practical, but do not claim backward compatibility unless it is explicitly implemented and tested.
14. Keep an independently recoverable backup and document recovery instructions.
15. Ensure a failed or interrupted migration cannot leave the save in a partially converted state.

Important implementation distinction

Separate APKs do not automatically share Android private storage.

If Android requires the user to select a save file or folder again after reinstalling, that is acceptable. The process should be straightforward and clearly explained.

If the chosen approach requires a native Android plugin, Storage Access Framework integration, or another platform-specific component, investigate and document that requirement before implementation.

Do not promise seamless automatic reconnection if Android's permission model prevents it.

Work authorization

Inspect the architecture and proceed with safe, approved save-continuity development.

Do not endanger existing saves or destabilize the current simulation to accelerate this feature.

Keep permanent signing-key management deferred.

---

PART II — THREE INDEPENDENT FUTURE BUILD PLANS

These expansions are approved design objectives, not authorization to interrupt the current stabilization effort.

Each must have its own development ledger entries, dependency analysis, implementation phases, automated tests, simulation acceptance criteria, and release gates.

Do not assign final build numbers without reviewing the existing roadmap and dependencies.

EXPANSION A — MINING & INDUSTRIAL DEVELOPMENT

Supporting document: Mining & Industrial Development Expansion

Purpose: Expand how settlements discover, extract, process, transport, and use finite natural resources.

This expansion addresses the eventual depletion of surface iron, coal, stone, and other materials without resorting to magical resource regeneration.

Required design scope

The supporting document is the primary specification. Preserve its details, including:

- Existing finite surface mineral deposits.
- Quarrying of remaining stone after exposed ore has been exhausted.
- Prospecting as a real occupation.
- Geological indicators that suggest nearby deposits without revealing exact locations.
- Professional prospecting equipment and assaying.
- Hidden, finite mineral deposits distributed across the world.
- Open-pit and strip mining.
- Actual excavation of soil and rock.
- Terraced or ramped access to deeper deposits.
- Excavated dirt and stone becoming usable physical resources.
- Underground mines, tunnels, and caves.
- Appropriate underground visibility and terrain cutaway behavior.
- Mine supports, minecarts, tracks, and related infrastructure.
- Interdependent blacksmithing, carpentry, masonry, hauling, and mining professions.
- Manufacturing chains for tools, supports, rails, carts, and extraction equipment.
- NPC and player interaction with mining operations.
- Resource exhaustion, economic consequences, and viable industry transitions.

Development requirements

Before implementation, audit the existing terrain, elevation, pathfinding, navigation, resource, inventory, profession, construction, and save systems.

Do not assume underground excavation is technically supported simply because surface mining already exists.

Plan the expansion in independently testable phases.

Acceptance principles

Minerals must remain finite. Excavation must have real material and labor costs. Extracted materials must enter the existing economy rather than appearing through arbitrary inventory generation.

Mining must interact with other industries and the settlement economy.

The player must be able to participate in the same underlying systems as NPCs wherever the design calls for it.

This is one independent future expansion.

---

EXPANSION B — SETTLEMENT ADVANCEMENT & REGIONAL ECONOMY

Supporting document: Settlement Advancement & Regional Economy Expansion

Purpose: Allow villages, towns, and larger settlements to develop distinct industrial capabilities and participate in an interconnected economy based on actual production, demand, and purchasing power.

This expansion is separate from the mining expansion, although the two must integrate.

Required design scope

The supporting document is the primary specification. Preserve its details, including:

- Settlement development from villages toward towns and larger population centers.
- Industry-specific settlement capabilities and skill progression.
- Distinctions between individual NPC skills and collective settlement capabilities.
- Knowledge, labor, tools, infrastructure, and production capacity as meaningful development requirements.
- Settlement specialization based on geography, resources, residents, and opportunity.
- Multiple settlements producing different goods.
- Regional supply and demand.
- Actual goods moving between settlements.
- Merchant and caravan behavior based on trade opportunities.
- Settlement purchasing power and economic limitations.
- Competition between producers.
- Production shortages, surpluses, and market changes.
- Economic consequences when a settlement loses workers, resources, infrastructure, or access to trade.
- The ability for settlements to adapt, stagnate, prosper, or decline through simulation.

Caravan decision

The existing 30-coin daily caravan mechanism is a temporary placeholder representing outside settlements that are not yet simulated.

It is not a permanent rule and must not become the foundation of the final regional economy.

Eventually, caravans must represent actual trade relationships between settlements.

A caravan should purchase goods because another settlement needs them and has the means to acquire them, not because the current village is automatically entitled to a daily income.

A settlement that produces highly desirable goods may attract substantial trade.

A settlement producing goods nobody currently needs may attract little or no trade.

Economic usefulness, actual demand, available supply, purchasing power, prices, and trade feasibility determine transactions.

Settlement skill distinction

Do not equate settlement population size with industrial competence.

A small mining village may have highly advanced mining capabilities while a large agricultural town has limited mining knowledge.

Settlement skills must be tied to meaningful capability rather than arbitrary population thresholds.

Current-build boundary

Keep the provisional caravan mechanism adjustable and documented during Builds 15–16.

Do not prematurely implement the entire regional economy while testing simulation equilibrium.

This is the second independent future expansion.

---

EXPANSION C — NPC JUDGMENT SYSTEM

Supporting document: NPC Judgment System Expansion

Purpose: Introduce persistent, subjective judgments between individuals that influence decisions throughout the simulation without replacing personal needs, practical reasoning, or NPC autonomy.

This is a major simulation-wide system, not a minor relationship-stat adjustment.

It must remain separate from both the mining and settlement-economy expansions.

Core design principle

An NPC's judgment of another NPC is one factor influencing a decision, not an absolute permission or prohibition.

For example:

John may have a strongly negative judgment of Verbal.

John also needs 50 iron, and Verbal may be the only available supplier.

John can choose to refuse the transaction because of his opinion, but he can also decide that obtaining the iron is more important and trade with Verbal anyway.

The negative judgment changes how John weighs the decision. It does not automatically prevent the transaction.

Required design scope

Use the accompanying NPC Judgment System Expansion document as the authoritative detailed design specification.

At minimum, the expansion must address:

- Individual judgments of other individuals.
- Positive, negative, and mixed personal experiences.
- Persistent, evolving opinions.
- Subjective perception rather than universal truth.
- The difference between directly witnessed events, communicated information, rumors, and assumptions.
- Personal needs, opportunities, risks, and obligations.
- Context-sensitive decision weighting.
- NPC autonomy and the ability to act contrary to personal preferences.
- Consequences of cooperation, conflict, betrayal, assistance, and repeated interactions.
- The effects of judgment on trade, work, cooperation, social interaction, relationships, rivalries, and civic behavior where appropriate.
- Compatibility with existing friendship, courtship, marriage, family, reputation, and political systems.
- Meaningful changes in judgment over time.
- Individual differences in how strongly judgments affect decisions.
- Simulation-wide integration rather than isolated scripted interactions.

Critical design constraints

Do not implement a simplistic rule such as:

"Negative opinion means refuse all interaction."

Do not turn the judgment score into a universal morality meter.

Do not make NPCs omniscient about events they could not know.

Do not replace economic needs or practical reasoning with relationship scores.

Do not assume the existing relationship and courtship mechanics already constitute this system.

The judgment system must influence existing decision-making while preserving the possibility of unexpected but rational behavior.

Implementation timing

This expansion was specifically intended to follow the establishment of a stable, functioning village simulation.

The purpose is to introduce a major new layer of interpersonal complexity after the current systems reach equilibrium.

It should be capable of disrupting established social and economic patterns through emergent behavior, allowing the team to observe how the simulation adapts.

Do not implement the judgment system during Build 15–16 equilibrium testing.

Development requirements

Before implementation:

1. Audit existing AI decision-making and relationship systems.
2. Identify every major decision category that may be affected.
3. Establish how subjective information is acquired and remembered.
4. Define save persistence and migration requirements.
5. Create deterministic and long-duration simulation tests.
6. Establish performance limits for large NPC populations.
7. Plan staged integration so failures can be isolated.
8. Preserve the design's distinction between opinion, practical necessity, and final choice.

This is the third independent future expansion.

---

PART III — ROADMAP AND DEVELOPMENT CONTROL

Three separate expansion plans

Create or register three independently tracked expansion objectives:

A. Mining & Industrial Development

B. Settlement Advancement & Regional Economy

C. NPC Judgment System

Each requires:

- Its own scope and supporting document.
- Its own requirements and dependencies.
- Its own implementation phases.
- Its own acceptance criteria.
- Its own automated and long-duration simulation tests.
- Its own integration review.
- Its own build and release decision.

These are three different major development objectives. Do not combine them into one undifferentiated backlog item.

Do not assign arbitrary build numbers merely to fill out the roadmap.

Review dependencies and propose the appropriate sequencing after the current stabilization work.

Current development priorities

Continue approved Build 15–16 work, including:

- Population and household sustainability.
- Wildlife sustainability.
- Resource and economic stability.
- Existing relationship and courtship behavior.
- Long-duration simulation testing.
- Regression testing.
- GitHub commits and remote staging pushes.
- Existing approved fixes and development tasks.

Do not stop active development because one future expansion requires additional planning.

Do not publish new builds outside the existing release authorization and test gates.

Source-of-truth requirements

Register these decisions and expansions in the existing permanent development ledger and requirements tracking system.

Preserve the three supporting design documents in the project documentation structure.

Record their relationship to the existing world-design rules.

Where a supporting document contains more detail than this master directive, retain that detail rather than replacing it with this summary.

If the documents contain an actual conflict with the current implementation or an established rule, identify the conflict rather than silently discarding either requirement.

Do not mark any expansion as implemented, tested, or complete merely because its plan has been registered.

---

PART IV — REQUIRED RESPONSE

After reviewing this directive and all three attached documents:

1. PR #1: Report its verified disposition and confirm that unique work was preserved.
2. Android saves: Report the current architecture, chosen technical approach, safe migration plan, and any real platform limitations.
3. Mining expansion: Confirm registration as an independent future development objective.
4. Settlement advancement expansion: Confirm registration as a second independent future development objective.
5. NPC judgment expansion: Confirm registration as a third independent future development objective.
6. Roadmap: Identify dependencies and propose sequencing without prematurely launching the expansions.
7. Current work: Report what approved Build 15–16 development and simulation work is continuing.

The owner has provided the required direction. Do not ask for the same decisions again.

Ask only about genuinely unresolved technical or design conflicts that cannot be handled under existing authority.

Preserve the current simulation, keep development moving, and maintain three clearly separated future expansion plans.
