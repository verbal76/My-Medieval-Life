# Owner directive, 2026-10-23: Expansions 22 and 23 development kickoff, and the owner's renumbering answer

Saved verbatim: the directive as received, then the owner's answer to the numbering question it raised.

## The owner's answer (2026-10-23), verbatim

> Proceed with Option 1.
>
> Update OD-30 with a clear historical record explaining the renumbering. Expansion 22 is now Settlement Advancement Phase 2, building directly on the systems released in Build 18. Expansion 23 is Bandit Factions and Criminal Careers. Legacy moves to Expansion 24.
>
> Do not rebuild or duplicate any functionality already delivered in Build 18.
>
> Preserve the two newly approved Expansion 22 architectural decisions:
>
> E22-OD-01: Hybrid regional simulation with detailed nearby NPCs and abstract distant settlements that preserve individual identities, households, property, economic state, and history.
>
> E22-OD-02: Continuous geography with streamed regions, persistent world coordinates, and persistent player/NPC modifications.
>
> Both are design approvals only. They do not authorize implementation.
>
> Continue the read-only audit against the actual Build 18 implementation. Identify which parts of the original Settlement Advancement specification are already complete, partially complete, or still missing.
>
> I want Expansion 22 to extend the existing regional simulation, not replace it unnecessarily. Pay particular attention to how the existing five settlements, regional trade, migration, and worker experience can support the much larger continuous world.
>
> Do not begin implementation until we review the audit and approve the architecture.

(Option 1 as asked: "22 = Settlement Advancement phase 2 (building on what Build 18 shipped), 23 = Bandit Factions, Legacy moves to 24. I update OD-30 with a history line.")

## The directive (2026-10-23), verbatim

MY MEDIEVAL LIFE — EXPANSIONS 22 & 23

Development Kickoff Directive

Priority: Settlement Advancement & Regional Economy

Project: Hot Attic Games — My Medieval Life
Primary workstream: Expansion 22 — Settlement Advancement & Regional Economy
Secondary workstream: Expansion 23 — Bandit Factions & Criminal Careers
Authorization: Repository audit, architecture, requirements reconciliation, and safe isolated foundation work. No gameplay activation, staging/main merge, or release authorization.

1. Mission

Begin concrete development preparation for Expansions 22 and 23, prioritizing Expansion 22.

Use the existing standalone Settlement Advancement & Regional Economy specification as the primary authority. Use Permanent World Design Rule 016 and the existing bandit roadmap for Expansion 23.

Verify current repository state and historical expansion numbering before modifying registers.

Do not redesign these expansions from scratch or substitute generic city-builder mechanics for the approved simulation philosophy.

2. Expansion 22 — Settlement Advancement

The goal is a region of independently functioning settlements that develop according to their population, resources, industrial knowledge, housing, infrastructure, economy, and relationships with other settlements.

Settlements must be able to:

- Grow, stagnate, decline, or disappear through simulated causes.
- Develop different industrial specializations.
- Attract or lose residents and skilled workers.
- Construct housing and infrastructure when resources permit.
- Preserve, spread, or lose industrial capabilities through their inhabitants.
- Produce, consume, import, and export real goods.
- Form economic dependencies on other settlements.
- Experience genuine shortages and loss of economic activity.
- Operate without player participation.

Settlement size must not automatically grant universal industrial capabilities.

A smaller settlement with experienced miners and appropriate equipment may possess more advanced mining capability than a larger town.

Phase A — Architecture and regional ledger

Audit existing settlement, population, housing, production, trade, inventory, currency, transport, and industry-capability systems.

Identify the authoritative owners of all relevant data.

Produce a settlement capability and resource ledger design that can support both fully simulated and abstract settlements.

Determine which existing services can be reused from Expansions 18, 19, and 20.

Do not create duplicate economic ledgers or parallel NPC simulation systems.

Phase B — Settlement capability model

Prepare a model in which capabilities arise from actual conditions:

- Skilled workers and available labor.
- Tools and production equipment.
- Buildings and infrastructure.
- Accessible resources.
- Knowledge transfer and continuity.
- Industry dependencies.

Identify the exact existing Expansion 18 capability mechanisms and how they can be reused.

Keep unapproved progression formulas and classification thresholds unresolved.

Phase C — Abstract regional settlements

Design a computationally efficient representation for off-map settlements.

Each abstract settlement must maintain meaningful, conserved economic state, including:

- Population and household demand.
- Productive capabilities.
- Resource and finished-goods stocks.
- Available money and purchasing power.
- Imports and exports.
- Transport requirements.
- Production and consumption over time.

The abstract simulation must not invent currency or goods to satisfy trade.

Define the transition requirements between abstract and fully simulated settlement states, including conservation, persistence, and deterministic replay.

Do not assume every remote NPC must receive full individual simulation.

Phase D — Settlement development

Map the conditions that drive:

- Housing demand and construction.
- Population growth and migration.
- Business creation and closure.
- Infrastructure development.
- Industrial specialization.
- Loss of skilled workers.
- Settlement decline.

Avoid scripted settlement-level advancement tiers that bypass underlying systems.

Phase E — Persistent regional networks

Prepare the architecture for:

- Trade routes.
- Travel distances.
- Merchant and caravan capacity.
- Supply and demand across settlements.
- Competition between suppliers.
- Transport costs.
- Interrupted routes.
- Regional economic dependencies.

The temporary 30-coin-per-day caravan allowance from earlier builds is not permanent economic design. Identify how it can eventually be retired without disrupting existing builds.

3. Expansion 22 — Player understanding

The player must be able to discover why settlements prosper or decline.

Plan player-facing views for:

- Settlement population and development.
- Local industries and capabilities.
- Important shortages and surpluses.
- Trade routes and major imports or exports.
- Housing and infrastructure needs.
- Economic changes over time.

Explanations must derive from actual simulation records and respect the player's knowledge.

Also plan complete developer diagnostics for settlement changes, conservation, and trade failures.

Do not implement a separate explanation engine.

4. Expansion 23 — Bandit Factions & Criminal Careers

Begin the architecture audit and requirements reconciliation only.

Use the existing bandit roadmap phases:

- BAN-A: Existing-system audit.
- BAN-B: Faction identity, membership, resources, and hideouts.
- BAN-C: Criminal careers and activities.
- BAN-D: Leadership, succession, and faction continuity.
- BAN-E: Cross-system integration and simulation validation.

Map future capabilities for:

- Autonomous bandit factions.
- Recruitment and membership.
- Faction leadership and competition.
- Hideouts, supplies, equipment, and money.
- Theft, burglary, robbery, livestock theft, smuggling, raiding, and fencing.
- Player participation in criminal careers.
- Stolen-goods ownership and movement.
- Territorial activity.
- Guard investigations, bounties, and enforcement.
- Faction survival, division, and collapse.
- Criminal reputation and historical records.

Preserve distinctions between criminal reputation, ordinary social judgment, and legal status.

Do not implement new criminal actions or faction behavior in this phase.

5. Cross-expansion integration

Document dependencies on:

Expansion 19: Personality, trust, reputation, knowledge, and decision influences.

Expansion 20: Finite resources, economic actors, contracts, transactions, credit, and market activity.

Expansion 21: Government authority, public spending, guards, jurisdiction, and law enforcement.

Expansion 22: Settlement populations, regional movement, industrial capability, and intersettlement trade.

Expansion 23: Bandit organizations, criminal activity, stolen goods, and regional security.

Preserve one authoritative owner per kind of state.

6. Development execution

Before starting, inspect active workers, worktrees, branches, and uncommitted changes.

Do not exceed available development slots.

For Expansion 22, complete the audit and begin isolated, reusable foundation work where the existing specification and repository establish sufficient requirements.

Any code must be backward-compatible and disabled by default.

Use narrowly targeted tests for changes, including deterministic replay, save/load, inventory and currency conservation, and baseline behavior when disabled.

Reuse valid prior test evidence.

Maintain a recovery handoff before approximately 80% context usage.

7. Owner decision packet

Ask only decisions that affect the architecture or breadth of the simulation.

For Expansion 22, prioritize:

1. How off-map settlements are simulated.
2. How settlements are represented geographically.
3. How population and migration operate across the region.
4. How industrial knowledge persists or disappears.
5. How regional trade and transportation function.

For Expansion 23, prioritize:

1. Faction territory and jurisdiction.
2. How many factions can exist and how they emerge.
3. How faction leadership changes.
4. How criminal activities integrate with actual world inventories and travel.

Do not ask isolated hypothetical social questions.

Do not invent defaults for unresolved owner decisions.

8. Required deliverables

Provide:

1. Expansion 22 architecture and capability audit.
2. Phases A–E dependency map.
3. Current implementation versus missing capability matrix.
4. Proposed regional simulation data model.
5. Safe isolated foundation changes completed, with commits and tests.
6. Expansion 23 BAN-A audit and proposed architecture.
7. Integration and performance risks.
8. A concise owner decision packet with genuinely blocking questions.
9. Recommended next development assignment.

Priority instruction: Expansion 22 receives the majority of available development effort. Expansion 23 must not delay its foundation.

Design objective: Build a living region, not a decorative collection of towns.
