# 21_Politics (text extracted from the owner's docx, 2026-10-21)

Source: docs/roadmap/source/21_Politics.docx (Expansion Documentation Pack, supplied by the owner 2026-10-21). Paragraphs as in the original; tables flattened one cell per line.

Expansion 21 — Living Village Politics
My Medieval Life | Implementation-ready design baseline | 21 October 2026
DOCUMENT STATUS: Consolidates approved requirements with explicitly labeled proposed implementation stages. Proposed numbering for 21–23 is not yet an owner-approved register assignment.
Governing constraints
Owner-approved directives and existing repository rules take precedence over proposed engineering detail. The world remains finite and autonomous. Every item, coin, event, death, relationship and political action needs legitimate provenance. A village may fail; the simulation may not cheat to save it. Preserve seeded determinism, save migrations, the existing development ledger, Interlocking Systems Manifest, and in-game Wiki. Expansion means active coding on an isolated branch; Build means final acceptance and packaging; Release means published three-platform artifacts.
Authoritative references
docs/directives/2026-10-19_memory_refuges_politics.md, Part III §§18–32
docs/WORLD_DESIGN_RULES.md, Rules 015 and 019
docs/DEVELOPMENT_LEDGER.md, VP-01 and WDR-015-C
Purpose and authority
The village governs itself without player intervention. NPCs and players may hold mayor/leader, constable, guard captain, and guard positions. Other appropriate offices include council, bailiff, tax collector, clerk and steward. Selection varies by local political structure.
Every office has responsibilities, constraints and succession. A mayor cannot conjure supplies, guards or treasury money. A guard must have actual equipment and a funded role.
Election model
Every eligible voter evaluates real candidates individually, using firsthand knowledge, testimony, family memory, credible gossip, conduct, competence, security and economic interests. A voter may abstain. Count actual ballots; never manufacture totals to fit a predetermined winner.
Persist nomination, eligibility, candidate records, election schedule, voter decisions, vote tally, tie resolution, terms, resignation, vacancies and succession. Replaying a save must not duplicate an election.
Campaigning includes service, promises, gatherings, endorsements and debates. It must not become a repetitive persuasion-click minigame. NPCs can campaign, win and govern independently.
Public finance and law
Treasury receives actual taxes, rents, fees, fines or duties. Civic salaries, roads, defenses and equipment consume real resources and labor. Unfunded services may fail.
Officeholders direct lawful spending, guard priorities, public projects, taxation and appointments subject to established rules. Political decisions change the living economy and public safety.
Judgment and generational history
An inherited favor or grievance may tip a decision but never override all competing needs. A secret crime influences voting only when credibly discovered.
Track promises, scandals, election results, office careers, civic projects and historical outcomes. Descendants may recall real facts, not invented stories.
Phases (proposed)
P21-A audit existing civic, treasury, guard and judgment systems.
P21-B office/treasury state and actual civic work.
P21-C individual voting and election lifecycle.
P21-D autonomous NPC and player candidacy, campaigns and UI.
P21-E policies, historical memory and long-run validation.
Acceptance
Each eligible voter casts a reproducible ballot or abstains; counted votes equal results.
A descendant remembers the actual 30-plank house assistance but may vote against the donor family for other reasons.
Mayor commissions a project only with actual resources; guards cannot be paid without treasury funds.
Death in office triggers succession and history persists across save/load.
Open implementation details
Exact office terms, franchise/eligibility, campaign timing, vote privacy and local succession mechanisms need documented defaults or explicit owner decisions where material. Do not silently impose a universal government.
Handoff checklist
Reconcile this specification against current branch and owner decisions before coding.
Create or update existing development-register tasks, not a second backlog.
Record data schema and save migrations; protect inventory, currency and history conservation.
Use narrow tests for changed code and reuse relevant green CI.
Keep expansion work on remote GitHub staging/WIP branch; do not publish a build until the build stage.
Update in-game Wiki, developer documentation and Interlocking Systems Manifest.