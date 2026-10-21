# Owner directive, 2026-10-21: Permanent Wiki Maintenance Directive (Build 17 and all future builds and expansions)

Saved verbatim from the owner's message (CLAUDE.md section 9a). Recorded as the standing rule WIKI-01 and in CLAUDE.md
("Wiki and documentation maintenance").

---

I would make this a standalone, permanent development directive, not just an addendum to MIN-F2.

That way, Claude treats wiki maintenance as part of every future development task across My Medieval Life, not something we remember to request after several expansions have already been completed.

The wiki should serve two purposes: a player-facing game manual and an accurate technical reference for the simulation. Those should be clearly separated so players can learn the game without having to read developer documentation.

# MY MEDIEVAL LIFE — PERMANENT WIKI MAINTENANCE DIRECTIVE
## Applies to Build 17 and All Future Builds and Expansions

Claude, the owner is establishing an ongoing documentation requirement for My Medieval Life.

**The wiki must be maintained and expanded continuously as the game develops.**

This is a standing instruction, not a one-time documentation cleanup.

Every completed feature, significant behavioral change, new mechanic, revised economic rule, or gameplay system must be evaluated for corresponding wiki updates.

The wiki must accurately reflect the game as it exists, while clearly distinguishing implemented features from planned future development.

## 1. Documentation is part of feature completion

A feature is not considered fully documented until its relevant wiki pages have been reviewed and updated.

This applies to:

- New gameplay mechanics.
- Changes to existing mechanics.
- New occupations and production chains.
- Crafting recipes and equipment.
- Economic systems and contracts.
- NPC behavior and decision-making.
- Mining and geological systems.
- Construction and settlement expansion.
- Farming and resource management.
- Health and mortality.
- Politics, law, and relationships.
- Player interactions and controls.
- Save systems and other player-visible functionality.

Documentation must be updated as part of the same development workstream whenever practical.

Do not postpone routine documentation until several builds have accumulated undocumented changes.

## 2. Maintain two clearly separated documentation layers

### A. Player-facing wiki

Explain how the game actually works from the player's perspective.

Use clear, accessible language.

Document:

- What a feature does.
- How the player accesses it.
- What tools or materials are required.
- How the mechanic operates.
- What it costs.
- What can go wrong.
- What happens when an action succeeds or fails.
- How the mechanic interacts with other systems.

Include practical examples where they improve understanding.

Avoid exposing unnecessary internal implementation details.

Do not reveal hidden mechanics or exact values that the owner intends players to discover naturally.

### B. Developer and simulation reference

Maintain the technical documentation needed to understand, maintain, and extend the game.

Document:

- Relevant system architecture.
- Data structures and ownership.
- Simulation update timing.
- Economic and material conservation rules.
- Deterministic behavior.
- NPC decision processes.
- Dependencies between systems.
- Save/load requirements.
- Important configuration parameters.
- Known limitations.
- Applicable tests and validation evidence.

Where possible, link the technical documentation to the corresponding requirements and owner decisions.

The player-facing and technical layers should reference one another without becoming unnecessarily repetitive.

## 3. Update existing pages before creating duplicates

Before adding a new wiki page:

1. Search for an existing page covering the subject.
2. Determine whether the new information belongs there.
3. Update that page when appropriate.
4. Create a new page only when the subject warrants its own section.
5. Add links from related pages.
6. Update navigation and indexes.

Do not create multiple contradictory explanations of the same mechanic.

Use consistent terminology across the wiki, game interface, requirements, and decision records.

## 4. Build 17 documentation reconciliation

Perform a focused wiki review of Build 17's implemented changes.

Pay particular attention to:

**Mining and geology**
- Surface prospecting and discoveries.
- Samples, assays, and trial pits.
- Ore depletion and finite deposits.
- Open-pit excavation.
- Underground excavation.
- Tunnel stability and collapse.
- Timber supports and maintenance.
- Minecarts and physical hauling.
- Shafts and underground levels.
- Player-directed backfilling.
- Recoverable topsoil and spoil.
- Mining rights and common-ground access.

**Production and equipment**
- Raw stone versus finished building blocks.
- Stoneworking.
- Shovels and pickaxes.
- Carpenter and smith involvement in mining-equipment production.
- Equipment durability and replacement.
- Legitimate equipment procurement.

**Economy and labor**
- Independent mining.
- Manor jobs.
- Negotiated goods contracts.
- Existing service contracts.
- Contract payment and cancellation.
- Existing job-board behavior.
- Actual ownership and transfer of goods.

**Mortality**
- Current mine-collapse survival/death outcomes.
- Existing NPC death handling.
- Explicit limitations of the current system.

Only describe these features as playable or implemented when their code has actually landed and passed the appropriate verification.

## 5. Document future decisions without presenting them as completed features

The owner has approved future development involving:

- Reuse of excavated earth.
- Larger and deeper open pits.
- Prospecting-information trading.
- Restricted contract advances.
- Negotiated service compensation.
- Contract disputes and legal remedies.
- Agricultural labor contracts.
- Independent NPC service hiring.
- Separate service-contract signing thresholds.
- A comprehensive medieval health and medical system.

These decisions must be recorded and traceable.

However, **approved does not mean implemented**.

Do not describe planned systems as available gameplay.

Keep future mechanics in clearly identified planned-feature or developer-roadmap documentation.

Do not publish speculative player instructions for systems that do not yet exist.

## 6. Future medical-system documentation

The game already has an apothecary and potions.

Preserve and document their actual existing behavior.

The future medical expansion will build upon these systems.

Create appropriate documentation placeholders for:

- Health.
- Injuries.
- Illness.
- Treatment.
- Recovery.
- Medical practitioners.
- Apothecary integration.
- Potions and medicinal supplies.
- Medical economics.
- Mortality and lasting consequences.

These are future topics, not authorization to implement them during Build 17.

For Build 17, document only the binary survival/death collapse behavior actually implemented.

## 7. Integrate wiki updates into the development workflow

For every future feature or change, follow this sequence:

1. Review the relevant owner decisions and requirements.
2. Implement the approved functionality.
3. Validate the functionality.
4. Update affected wiki pages.
5. Update relevant technical references.
6. Check navigation, terminology, and links.
7. Include documentation status in the completion report.

If a feature changes during development, revise the documentation to match the final behavior.

If a feature is removed or replaced, remove or clearly correct obsolete instructions.

Do not leave outdated information in place simply because it was accurate in an earlier build.

## 8. Documentation verification

Use the existing wiki validation tools and tests where available.

Check for:

- Broken internal links.
- Missing referenced pages.
- Duplicate or conflicting explanations.
- Invalid navigation entries.
- Incorrect feature status.
- Outdated terminology.
- Incorrect recipes or material requirements.
- Unsupported claims about gameplay behavior.

When documentation changes are narrow, use the relevant targeted validation rather than rerunning unrelated simulation tests.

Do not repeatedly run the entire test suite merely because wiki text changed.

## 9. Release documentation gate

Before recommending a build for release, verify that:

- All newly released player-facing mechanics are documented.
- Changed mechanics have updated instructions.
- Obsolete instructions are corrected.
- Technical documentation reflects the released implementation.
- Relevant wiki checks pass.
- Known limitations are identified accurately.

A missing or outdated wiki entry should be tracked as a documentation defect.

Distinguish material player-facing documentation errors from minor editorial improvements.

Do not automatically block an otherwise ready build over trivial wording or formatting issues.

## 10. Required reporting

In every substantial feature-completion report, include a brief **Wiki and Documentation** section stating:

- Which wiki pages were created.
- Which existing pages were updated.
- Which technical references changed.
- Whether wiki validation passed.
- Whether any documentation work remains.

When no documentation changes are necessary, explicitly state why.

Do not claim the wiki was updated unless the corresponding changes were actually made.

## 11. Documentation quality standards

The wiki must remain:

**Accurate:** It describes real implemented behavior.

**Current:** It changes alongside the game.

**Organized:** Related mechanics are easy to find.

**Consistent:** Terminology and rules agree across pages.

**Useful:** Players can understand how to play, and developers can understand how systems operate.

**Traceable:** Significant technical rules connect to approved requirements and decisions.

**Maintainable:** Documentation is integrated into normal development instead of becoming a separate recurring reconstruction project.

## 12. Immediate action

1. Record this as a permanent project-wide development requirement.
2. Add wiki review and update tasks to the existing feature-completion workflow.
3. Identify the wiki pages affected by Build 17.
4. Update the pages for features already merged and verified.
5. Have active workers update documentation for the features they are implementing.
6. Avoid duplicating documentation work across parallel workers.
7. Run the appropriate wiki validation after integration.
8. Report any significant documentation gaps before final Build 17 release review.

Do not delay active implementation merely to rewrite unrelated historical wiki pages.

The immediate objective is to keep Build 17 documentation accurate and establish a sustainable process for every subsequent expansion.

**Standing owner requirement: A feature should not be considered complete without accurate corresponding documentation.**

**A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.**

One addition I'd strongly recommend: have Claude place this requirement in the repository's persistent agent instructions, such as `CLAUDE.md` if that's what the project uses, as well as the requirements register. That makes it much less likely a future Claude session or parallel worker will overlook wiki maintenance.
