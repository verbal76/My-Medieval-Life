# 23_Legacy (text extracted from the owner's docx, 2026-10-21)

Source: docs/roadmap/source/23_Legacy.docx (Expansion Documentation Pack, supplied by the owner 2026-10-21). Paragraphs as in the original; tables flattened one cell per line.

Expansion 23 — Generational Memory and Living History
My Medieval Life | Implementation-ready design baseline | 21 October 2026
DOCUMENT STATUS: Consolidates approved requirements with explicitly labeled proposed implementation stages. Proposed numbering for 21–23 is not yet an owner-approved register assignment.
Governing constraints
Owner-approved directives and existing repository rules take precedence over proposed engineering detail. The world remains finite and autonomous. Every item, coin, event, death, relationship and political action needs legitimate provenance. A village may fail; the simulation may not cheat to save it. Preserve seeded determinism, save migrations, the existing development ledger, Interlocking Systems Manifest, and in-game Wiki. Expansion means active coding on an isolated branch; Build means final acceptance and packaging; Release means published three-platform artifacts.
Authoritative references
docs/directives/2026-10-19_memory_refuges_politics.md, Part I §§1–9
docs/WORLD_DESIGN_RULES.md, Rules 014, 017 and 021
docs/DEVELOPMENT_LEDGER.md, GM-01, DVW-B7, WDR-014-C
Purpose and integration
The world remembers actual events, their causes and their consequences across generations. This expansion deepens the historical foundations shared with Expansion 19 Judgment; avoid duplicate memory systems.
Player heirs and NPC descendants know their lineage but do not automatically inherit firsthand memories or predecessor skills.
Event and provenance model
Persist stable event ID, world time, location, participants and roles, witnesses, resource quantities, affected property, outcomes, causal links, significance and source of knowledge.
Link events to actual consumed resources, buildings, family ties, ownership and subsequent consequences. Never claim a donated plank built a house unless its use can be traced.
Bound storage with significance thresholds and historical summaries, without erasing meaningful links.
Knowledge and interpretation
Knowledge is acquired by witnessing, participating, conversation, family stories, gossip, written records or public announcements. Track firsthand versus secondhand, rumor versus documented fact.
Different NPCs interpret the same battle or transaction differently. History influences gratitude, distrust, trade, marriage, politics, crime reporting and dialogue but never determines decisions mechanically.
Family trees and graves
Maintain ancestry, marriages, descendants, households, inheritance, surnames, property history and deaths across many generations. Preserve genealogical identity after informal adoption or surname change.
Every deceased NPC leaves a named interactive headstone with birth/death dates, occupation, career, achievements, family links, important events and a remembrance grounded in an actual knowledgeable character.
Connect graves to life chronicle, family tree, property records, village history and in-game Wiki. Do not keep every dead NPC as an active simulated agent.
Dialogue from facts
Use reusable context-sensitive grammar/templates to reference actual relatives, buildings, quantities, events and knowledge sources; do not invent personalized historical claims.
Track already-discussed topics and allow credible gaps, distorted rumors and forgotten events.
Phases (proposed)
P23-A audit event, memory, family and save systems; reconcile Expansion 19 integration.
P23-B stable causal event IDs and knowledge provenance.
P23-C family transmission, belief and historically grounded dialogue.
P23-D graves, chronicles, property histories and genealogy UI.
P23-E political, crime and battle integration; long-run multigenerational tests.
Acceptance
Thomas gives William exactly 30 planks, William uses them in a named house, and descendants accurately explain the connection after both men die.
A character who never learned the story does not know it; rumor is not firsthand knowledge.
A grave biography references actual careers and relationships. Death, adoption, inheritance and save/load do not corrupt lineage.
Historic facts influence but do not force NPC judgment or political votes.
Open implementation details
Determine archival retention thresholds, dialogue grammar coverage and cross-generation memory decay as reversible engineering parameters; preserve owner-required permanent historical facts.
Handoff checklist
Reconcile this specification against current branch and owner decisions before coding.
Create or update existing development-register tasks, not a second backlog.
Record data schema and save migrations; protect inventory, currency and history conservation.
Use narrow tests for changed code and reuse relevant green CI.
Keep expansion work on remote GitHub staging/WIP branch; do not publish a build until the build stage.
Update in-game Wiki, developer documentation and Interlocking Systems Manifest.