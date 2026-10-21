# 22_Bandits (text extracted from the owner's docx, 2026-10-21)

Source: docs/roadmap/source/22_Bandits.docx (Expansion Documentation Pack, supplied by the owner 2026-10-21). Paragraphs as in the original; tables flattened one cell per line.

Expansion 22 — Bandit Factions and Outlaw Careers
My Medieval Life | Implementation-ready design baseline | 21 October 2026
DOCUMENT STATUS: Consolidates approved requirements with explicitly labeled proposed implementation stages. Proposed numbering for 21–23 is not yet an owner-approved register assignment.
Governing constraints
Owner-approved directives and existing repository rules take precedence over proposed engineering detail. The world remains finite and autonomous. Every item, coin, event, death, relationship and political action needs legitimate provenance. A village may fail; the simulation may not cheat to save it. Preserve seeded determinism, save migrations, the existing development ledger, Interlocking Systems Manifest, and in-game Wiki. Expansion means active coding on an isolated branch; Build means final acceptance and packaging; Release means published three-platform artifacts.
Authoritative references
docs/WORLD_DESIGN_RULES.md, Rule 016
docs/DEVELOPMENT_LEDGER.md, WDR-016-C
docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md, orphan fallback
Purpose
Bandits are autonomous people and factions, not disposable hostile spawns. Player and NPC may discover factions, join, advance, challenge leadership, run a hideout and face consequences.
Factions may grow, fracture, decline or collapse naturally without scripted prosperity.
Persistent faction state
Store faction ID, name, members, ranks, leader, succession rules, hideout, territory, supplies, treasury, relationships, recruitment conditions, planned actions and recorded crimes.
Faction members require real food, shelter, tools, weapons, labor and currency. Raid loot transfers from actual victims. Stolen goods retain provenance where possible.
Criminal careers
Support theft, burglary, livestock theft, robbery, smuggling, raids and fencing. A successful theft changes real ownership. Detection depends on witnesses, evidence and information transmission.
Separate reputation among bandits, households, merchants and law enforcement. A feared outlaw may be respected by allies but hated by victims.
Leadership and economy
Members may seek advancement or challenge leaders by faction-specific methods such as support or duels. Failed challenges have meaningful risks.
Leaders allocate jobs, raids, recruitment, supplies, loot division and hideout decisions. Members may refuse orders based on judgment, danger, needs and relationships.
Fencing, negotiated sales and purchases must use existing Living Economy infrastructure rather than a duplicate black-market ledger.
Law and families
Guards investigate and pursue crimes using actual funding, staffing, evidence and knowledge. Bounties must be authorized and funded, not infinite.
Approved orphan fallback: when no eligible household accepts a child, the child joins the bandit clan while remaining a child with intact genealogy and no adult combat ability.
Phases (proposed)
P22-A audit current bandit, crime, guard and child-care behavior.
P22-B faction identities, membership, ranks and persistent state.
P22-C real hideout needs, stockpiles, loot and supply chain.
P22-D autonomous crime, investigation and faction rivalries.
P22-E player career, leadership and historical records.
P22-F long-run faction economy, crime provenance and device validation.
Acceptance
A bandit faction steals a real animal; victim loses it, faction receives it, witnesses report only plausible knowledge.
A player joins, advances, challenges leadership and can fail. NPC succession proceeds without player involvement.
Bandit food and wages have valid sources. No infinite loot or unbounded respawn.
Unplaced children retain age, family history and child-specific behavior.
Open implementation details
Specific faction ranks, recruitment requirements, leadership contest rules, raid tactics and settlement legal consequences require documented defaults or owner decisions if irreversible.
Handoff checklist
Reconcile this specification against current branch and owner decisions before coding.
Create or update existing development-register tasks, not a second backlog.
Record data schema and save migrations; protect inventory, currency and history conservation.
Use narrow tests for changed code and reuse relevant green CI.
Keep expansion work on remote GitHub staging/WIP branch; do not publish a build until the build stage.
Update in-game Wiki, developer documentation and Interlocking Systems Manifest.