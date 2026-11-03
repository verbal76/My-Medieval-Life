# Owner directive, 2026-11-03 (about 14:45 EST): Build 25 Revision 1, shared homesteading, outlaw communities and sustainable bandit populations

Saved verbatim. Given as the owner's answer to the four decision questions on the homesteading and runaway proposal
(docs/design/HOMESTEADING_B25R1.md sections 8 and 10, branch wip/b25r1-homestead). Register: B25R1-014, with the four decisions
recorded on B25R1-010 and B25R1-013.

---

MY MEDIEVAL LIFE — BUILD 25 REVISION 1

OWNER MASTER DIRECTIVE: SHARED HOMESTEADING, OUTLAW COMMUNITIES & SUSTAINABLE BANDIT POPULATIONS

Priority: Architectural clarification and approval for the active homesteading worker.

Purpose: Build one shared wilderness settlement system supporting lawful homesteads and outlaw communities, while establishing believable population movement between villages, wilderness settlements, and bandit clans.

Record this directive, all four owner decisions below, their rationale, dependencies, and implementation evidence in the GitHub requirements register and recovery documentation.

This directive supersedes the previous standalone bandit economy proposal wherever they conflict. Preserve compatible earlier requirements.

---

FOUR OWNER DECISIONS — APPROVED

Decision 1 — Homesteading and runaway judgment

APPROVED WITH THE FOLLOWING CLARIFICATIONS.

Use the game's existing NPC judgment and life-decision architecture, including the mechanisms used when residents consider founding businesses.

Homesteading is evaluated at meaningful household formation or relocation events, not continuously.

Factors include:

- Property ownership ambitions
- Occupation and resource suitability
- Financial resources
- Available village housing and employment
- Family relationships
- Isolation and personal safety
- Settlement prosperity
- Taxes as a minor consideration

The original 1–3% guidance remains a conservative population safeguard, not a random chance of departure.

Young-adult homesteading should initially remain around 2% or less of eligible household formations over five game years, subject to evidence from population simulations.

Runaway decisions are evaluated after sustained hardship or significant life events, at most once per season unless a new major event warrants reconsideration.

Possible outcomes include remaining home, seeking help, working while remaining home, moving to another settlement, independent survival, or approaching an outlaw community.

Bandit acceptance is a separate decision.

Approve this shared judgment architecture and proceed with implementation.

Decision 2 — Established adults homesteading

YES, INCLUDE IT NOW.

Established adults may occasionally choose to establish a wilderness homestead.

Their decision must have a substantially higher threshold and a much smaller population allowance than young adults forming new households.

Potential causes include:

- Prolonged inability to secure appropriate housing
- Significant changes in family circumstances
- Strong occupational or property ambitions
- A viable wilderness opportunity
- Changes in employment or household needs

Do not restrict this exclusively to a long housing wait if another meaningful life event provides a legitimate reason.

Existing adults should not routinely abandon established homes, spouses, children, businesses, or obligations.

Preserve household relationships, ownership, and economic responsibilities through relocation.

Validate that this additional pathway does not destabilize settlement populations.

Decision 3 — Minimum runaway age

OPTION 2: AGE 12 NORMALLY; YOUNGER ONLY IN EXTREME CIRCUMSTANCES.

Adolescents aged 12–15 may consider running away following persistent hardship.

Children younger than 12 may run away only under exceptional circumstances involving severe, sustained danger or deprivation, with a substantially higher decision threshold.

Age and maturity must influence survival choices, travel capability, available help, and the likelihood of seeking protection.

Younger children should strongly prefer assistance from relatives, guardians, or other safe households when such options exist.

Running away does not automatically mean joining bandits.

Do not turn children into adult fighters or grant them equipment or skills.

Preserve the existing FAM-07 / OD-11 orphan-placement behavior and reconcile it with the new runaway system.

Decision 4 — Adult bandits returning to ordinary society

OPTION 2: YES, BUILD IT NOW.

Adult bandits may choose to leave their clan and return to ordinary life through the same existing judgment architecture.

Possible motivations include:

- Marriage and family responsibilities
- Desire for lawful employment
- Fear of death or injury
- Dissatisfaction with clan leadership
- Improved opportunities elsewhere
- Changes in personal ambitions
- A desire to establish an independent lawful homestead

Leaving must not automatically erase criminal history, reputation, relationships, or consequences.

A former bandit retains identity, skills, possessions, injuries, family ties, and relevant history.

Leaving a clan should involve real movement and affiliation changes, not NPC replacement.

Clan children retain their existing opportunity to leave upon coming of age.

Implement focused tests for voluntary departure, persistent identity, lawful reintegration, and save/load.

---

1. Fundamental architecture

Bandit homesteading is ordinary homesteading practiced by an outlaw counterculture.

Bandits are persistent people who need food, shelter, clothing, tools, income, relationships, and protection.

Use the same underlying systems for lawful and outlaw wilderness settlements.

Do not create separate implementations of:

- Land occupation and construction
- Housing and household formation
- Farming, livestock, hunting, and gathering
- Occupations and organic skill progression
- Crafting and resource processing
- Inventory, ownership, storage, and trade
- Marriage, children, aging, inheritance, and mortality
- Travel, pathfinding, and offscreen simulation
- Save/load, conservation, and determinism

The differences should primarily concern legal recognition, faction affiliation, concealment, access restrictions, social relationships, and behavior.

Build one shared wilderness settlement foundation.

2. Persistent settlement identity

A wilderness settlement must retain its identity independently of its occupants' current legal status.

Preserve:

- Physical buildings and improvements
- Residents and households
- Ownership and occupancy
- Clan or faction control
- Stored goods, livestock, and equipment
- Discovery and concealment status
- Save/load continuity

A lawful homestead may become outlaw-controlled, or an outlaw settlement may become lawful, when justified by actual events.

Changing affiliation must not recreate the settlement or its residents.

3. Sustainable bandit recruitment

Bandit communities require believable, continuing sources of potential recruits.

Sources include:

- Existing unplaced orphans under FAM-07
- Youth runaways
- Displaced or impoverished adults
- Criminal fugitives
- Voluntary outlaw recruits
- Existing relationships with clan members
- Children raised in outlaw households who later choose that life

Recruitment must use real, persistent NPCs.

Do not generate replacement bandits merely because existing members die.

Bandit populations may grow, decline, split, relocate, or disappear naturally.

Measure recruitment and population changes over multiple generations.

4. Youth hardship and runaway behavior

Persistent household hardship may influence young people's decisions.

Relevant conditions include chronic hunger, poverty, household instability, loss of parents, and loss of shelter.

One bad day must not trigger flight.

Use accumulated conditions and meaningful life events, not continuous random checks.

Possible decisions include:

- Remaining with the household
- Seeking relatives or other assistance
- Finding work while staying home
- Relocating to another settlement
- Attempting independent survival
- Seeking protection from an outlaw community

Joining bandits is never automatic.

Bandits may accept, reject, or take a runaway in as a noncombatant dependent.

Children must retain their actual age, abilities, and developmental limitations.

Families and population records must continue to account for missing members.

5. Skilled outlaw workers

Bandits may become blacksmiths, armorers, carpenters, farmers, livestock keepers, miners, leatherworkers, merchants, and other skilled workers.

Use the existing Living Economy, skill, crafting, and employment systems.

Skills improve through actual work.

A skilled outlaw smith may produce exceptional weapons and armor through legitimate materials, recipes, tools, production time, and workmanship.

Do not create arbitrary bandit-only equipment bonuses.

6. Hidden settlements, workshops, and markets

Outlaw communities may construct concealed homes, workshops, farms, animal enclosures, storage facilities, and trading posts.

These locations must physically exist in the persistent wilderness.

They should require actual construction materials, work, and resources.

A player may discover them through exploration or appropriate in-world information.

Discovery should persist through the existing landmark system.

Outlaw markets may restrict transactions to clan members or trusted outsiders.

Use existing merchant, ownership, inventory, and transaction systems.

Do not invent goods or money.

7. Food production and economic independence

Outlaw households may farm, raise livestock, hunt, gather, preserve food, craft equipment, and trade.

They do not need to survive entirely through raids.

Raiding supplements their economy and may respond to needs, opportunity, risk, and existing judgment.

A prosperous outlaw community may raid infrequently.

A struggling community may become more desperate.

All raids must transfer actual goods and money.

8. Combat, equipment, and discovery rewards

Outlaw settlements may be defended by actual residents.

Members may fight, flee, surrender, or abandon a settlement according to existing systems.

Bandits may own high-quality weapons and armor made, purchased, or stolen through legitimate simulation processes.

Players discovering and overcoming hidden outlaw workshops or settlements may obtain equipment and valuables actually present there.

Do not fabricate rewards independently of the world's inventory and production systems.

9. Changing allegiance and settlement evolution

Support natural transitions:

- Ordinary resident to outlaw
- Outlaw to lawful resident
- Lawful homestead to outlaw settlement
- Outlaw settlement to lawful homestead
- Small camp to established woodland community
- Active settlement to abandoned settlement

Preserve identity, relationships, buildings, inventories, and history throughout transitions.

Do not force conversions simply to demonstrate the mechanic.

10. Implementation coordination

The homesteading worker owns the shared life-decision architecture and wilderness settlement foundation.

Do not start a competing worker modifying the same household, family, faction, or decision systems.

The four decisions above constitute owner approval to proceed with the proposed shared judgment architecture, subject to these clarifications.

Continue parallel work on unrelated systems.

Reuse existing code wherever practical.

Identify genuine architectural blockers rather than inventing duplicate systems.

11. Validation and measurement

Validate:

- Young-adult and established-adult homesteading
- Severe hardship and age-appropriate runaway decisions
- Hardship scenarios where a child does not run away
- Bandit acceptance and rejection
- Adult bandit departure and reintegration
- Settlement identity through faction changes
- Persistent household and family relationships
- Conservation of NPCs, money, items, livestock, and materials
- Real crafting and skill progression
- Food production and consumption
- Hidden settlement discovery
- Actual equipment ownership and looting
- Offscreen settlement operation
- Save/load and deterministic replay
- Long-term village and bandit population stability

Track departures, recruitment, births, deaths, age distribution, occupations, food production, trade, raids, and settlement survival.

Use focused tests and reuse valid CI evidence for the exact source commit wherever possible.

12. Scope and release protection

Build 25 Revision 1 remains the release target.

Do not automatically defer shared outlaw-homesteading functionality to a later expansion.

Include the shared foundation and approved life-decision pathways now.

Where larger features require substantial new infrastructure, identify the dependency and explain the tradeoff rather than silently excluding approved functionality.

Preserve the original Build 25 private draft as the rollback.

Do not introduce unfinished or unverified economic systems into the release candidate.

---

Owner's intended result

A bandit clan should be capable of becoming a living woodland community.

Its residents can build homes, raise families, grow food, maintain livestock, develop skills, craft valuable equipment, trade, recruit members, and occasionally raid.

A player discovering such a settlement should encounter real people, real possessions, and real economic activity.

Some residents may join outlaw society. Others may eventually leave it.

Bandits are not disposable monsters. They are people living within the same persistent world as everyone else.

Record these four approvals, update the worker's instructions, and proceed without another approval loop for decisions already settled here.
