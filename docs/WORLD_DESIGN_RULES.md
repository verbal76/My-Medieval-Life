# World Design Rules

The owner's permanent World Design Rules for My Medieval Life. Each rule is an entry in the requirements register
(`docs/requirements/requirements.json`, ids `WDR-001` onward). Each rule's compliance work is a separate approved
requirement (`WDR-001-C` onward), so that no rule is marked satisfied only because code compiles. Numbers are
permanent: a rule is never renumbered or reused, and new rules continue from 017.

## Source

**Rules 001–016:**
- The owner's "World Design Rules — Expanded Reference and Examples", annotated companion to the original approved
  Version 1.0, 19 October 2026. The PDF is kept at `docs/directives/My_Medieval_Life_World_Design_Rules_Expanded.pdf`;
  it was supplied by the owner on 2026-10-19.
- Its primary source is `My_Medieval_Life_World_Design_Rules_v1.docx`. That file is not in the repository; the PDF
  reproduces its mandatory rules.
- The bullet text under each rule below is copied verbatim from the PDF.
- The "Example" and "Verification" lines are the companion's illustrations. They "illustrate desired behavior, not
  verified implementation".

**Rules 017–019:** from the owner directive `docs/directives/2026-10-19_memory_refuges_politics.md`, section 40.

## Original purpose and enforcement (verbatim)

- These are enduring design requirements, not a Build 11 punch list. New content and refactors must honor them. The existing Interlocking Systems Manifest remains the authoritative dependency record and must be maintained during development. This document specifies desired behavior; it does not certify that any feature has already been implemented.
- Maintain unique identifiers for materials, recipes, professions, factions, NPCs, relationships and system interactions. Update the existing manifest as changes are made.
- Build player-facing wiki content from authoritative game data where practical; avoid divergent manual copies of recipes and mechanics.
- Test connected gameplay loops, not just isolated features. Validate NPC autonomy, resource deductions, economy, save/load and multi-generation persistence.
- Use periodic or event-driven NPC planning rather than expensive per-frame full-world decision-making.
- Treat the numerical material-coverage thresholds as mandatory for standard materials. Document and justify exceptions for genuinely specialized materials.

## Rule 001 — Material Interdependency

- Every standard crafting material must be consumed by at least three meaningfully different recipes across at least two distinct professions.
- Track recipe count, consuming professions and any approved exceptions per material in the Interlocking Systems Manifest.
- Automatically flag materials below either threshold.

*Example:* Planks can build a named house, a cart, and furniture across professions. The Downs-to-Miller gift of 30 planks must actually move and be consumed.
*Verification:* Audit every standard material for three distinct recipes and two professions; test actual deductions.

## Rule 002 — Professional Interdependency

- Every production profession must supply at least one good or resource required by a different profession.
- Model cross-profession demand so trades form production chains instead of isolated menus.

*Example:* Grain moves from farmer to miller to baker to household. Timber moves through harvest, carpentry and cart construction.
*Verification:* Run a complete chain with inventories, payment, shortages and demand.

## Rule 003 — Meaningful Recipes

- Recipes must produce practical, distinct gameplay value.
- Cosmetic variants or near-duplicate recipes must not be counted solely to satisfy Rule 001.

*Example:* A cart enables hauling, a stairway opens a route, and medicine treats illness; three differently colored carts are not three meaningful recipes.
*Verification:* Document distinct gameplay purpose for every counted recipe.

## Rule 004 — Economic Consequences

- Supply, shortages, production and trade must influence prices, availability, jobs and behavior across professions.
- Scarcity and surpluses should produce observable responses rather than decorative statistics.

*Example:* Depleted iron and coal affect smithing, prices, employment and imports; manor labor reserves and caravan money caps alter the same economy.
*Verification:* Compare 100- and 365-day simulations, including wealth, jobs, supplies and trade.

## Rule 005 — Living World Independence

- NPCs, households and businesses must continue making economic and personal decisions without player initiation.
- The village must evolve during ordinary gameplay even when the player does not intervene.

*Example:* With no player intervention, households eat, work, trade, pursue housing and change over generations.
*Verification:* Idle-player test: verify independent transactions, decisions, construction attempts and persistence.

## Rule 006 — Interlocking Systems Documentation

- Document every new or changed material, recipe, profession and cross-system dependency in the existing Interlocking Systems Manifest.
- Maintain unique interaction IDs, dependency references and cross-system impact notes; avoid duplicate or orphaned entries.

*Example:* A cart touches crafting, ownership, inventory, NPC hauling, pathfinding, trade and saves.
*Verification:* Validate existing manifest IDs, cross-system references and change impact.

## Rule 007 — Automated Compliance

- Generate a material interdependency report from actual recipe data showing recipe and profession coverage.
- Flag violations, broken references and undocumented exceptions during development/integration.

*Example:* An automated report flags a material with only two recipes, a profession supplying nobody, or an orphaned recipe.
*Verification:* Run positive and negative compliance fixtures in CI.

## Rule 008 — Player Knowledge and In-Game Wiki

- Provide a comprehensive, accessible in-game wiki with pictures, descriptions, uses, acquisition methods, recipes, professions and related systems.
- Include practical "How do I…?" guides and search/categories.
- Generate factual values from current game data wherever possible; keep guidance synchronized with implemented behavior.

*Example:* The wiki explains how to build and use a cart with current ingredients and controls, without presenting future elections as playable.
*Verification:* Compare wiki values with actual data and test navigation on touch and controller.

## Rule 009 — Emergent Gameplay

- Design interactions that create unscripted opportunities, setbacks and stories through shared systems.
- Player choices and NPC actions should have second-order consequences across the world.

*Example:* Thomas Downs donates 30 planks to William Miller; the planks build a specific house. Descendants can recall the gift if family knowledge passed down.
*Verification:* Test provenance, transfer, construction, generations, dialogue, save/load and consequences.

## Rule 010 — Depth Without Obscurity

- Make complexity arise from meaningful mechanics, not confusing UI or hidden rules.
- Give players usable explanations, feedback and tools without forcing a single career or playstyle.

*Example:* Sword reach and attack timing should be understandable without overlapping sprites. Obstructed cart routes should show useful feedback.
*Verification:* Playtest clarity and responsiveness on keyboard, phone and controller.

## Rule 011 — NPC Self-Improvement and Prosperity

- Every NPC must pursue a better life according to their personality, means, age, circumstances and ambitions.
- Track five aspiration domains: food/security, money/wealth, goods/property, professional growth, and family/household development.
- Priorities must change after successes and setbacks; NPCs may fail, be content, or choose different definitions of success.
- Link ambitions to actual purchases, production, relationships, housing, inheritance and employment.

*Example:* An NPC may prioritize food, then wealth, property and family; another may prefer stability. Heirs do not automatically inherit ancestor skills.
*Verification:* Test five aspiration domains and adaptation after illness, loss, marriage or prosperity.

## Rule 012 — NPC Competition and Economic Rivalry

- NPCs, households and businesses compete for employment, customers, workers, materials, land, property, contracts and social advancement.
- Competitors respond to market conditions through pricing, specialization, expansion, relocation, hiring or business failure.
- The player participates in the same competitive economy and receives no automatic preferential treatment.

*Example:* Two carpenters compete for timber, customers and workers, adjusting prices or specializing in carts.
*Verification:* Test market response, hiring, failure and equal rules for player and NPCs.

## Rule 013 — Finite Resources and Actual Consumption

- Households and businesses must draw goods from real inventories and money from real budgets; no infinite or purely decorative production.
- Deduct inputs for food, fuel, smithing, carpentry, farming, livestock, construction and household growth.
- Support harvesting, production, imports, replenishment and believable regeneration alongside depletion and overuse.
- Scarcity must affect market prices and NPC behavior; consequences and inventory changes must persist through save/load.

*Example:* Thirty planks leave the donor inventory, enter recipient stock and are consumed once; mines and wildlife face finite depletion.
*Verification:* Run conservation, save/load and long-run resource exhaustion/recovery tests.

## Rule 014 — Graveyards, Ancestry and NPC Legacy

- Every deceased NPC must leave a persistent historical record and a named headstone in a graveyard.
- Headstone interaction must display birth/death dates, occupations, career milestones, accomplishments, family links and important life events.
- Include a remembrance attributed to an actual family member, friend, rival or community member, consistent with recorded relationships and events.
- Support linked family trees, multiple generations, expanding burial grounds and historical records without retaining full active-NPC simulation state.
- Political, criminal and professional careers must remain visible in memorial biographies.

*Example:* A grave records William Miller's dates, family, profession, named house, recorded deed and remembrance by a knowledgeable relative.
*Verification:* Persist family trees, historical facts, graves and memorials across generations.

## Rule 015 — Political Authority, Social Hierarchy and Civic Employment

- Settlements must support appropriately scaled governance: mayor/elder, council, guard captain, guards, tax collector, bailiff/magistrate, clerks/stewards and household servants as applicable.
- Officials must perform actual work affecting taxes, law, security, construction, public spending, property and trade.
- Use an actual public treasury with revenue from taxes, fees, fines, rents or duties and expenditures for wages, infrastructure and supplies.
- Leadership must change by locally appropriate succession methods such as election, appointment, council selection or inheritance.
- NPCs and players may seek office or advancement; wealth, influence, reputation, family and public service should matter without guaranteeing success.
- Guards must patrol, investigate and respond to crimes based on funding, staffing and equipment.
- Domestic workers must have real duties, needs, compensation/support and opportunities; preserve political careers in historical records.

*Example:* Every eligible NPC votes individually for mayor using memory, interests and policy; a finite treasury funds guards and civic work.
*Verification:* Count ballots and verify budgets, offices, patrols, elections and succession.

## Rule 016 — Bandit Factions, Criminal Careers and Outlaw Leadership

- Banditry must be a playable profession and autonomous NPC career, not only hostile enemy spawning.
- Support criminal activities such as theft, burglary, robbery, livestock theft, smuggling, raiding and fencing stolen goods with consequences.
- Allow players and NPCs to discover/join bandit factions, meet entry requirements, build faction reputation and rise through ranks.
- Provide leadership challenges through duels, faction support or other faction-specific methods; failure must carry consequences.
- Leaders must manage recruitment, roles, hideouts, inventories, loot division, raids, supplies, territory and faction relations.
- Track distinct reputations among bandits, villagers and guards; authorities respond with patrols, investigations, bounties or enforcement.
- Bandits require real food, money, equipment and shelter; factions can split, change leaders, dissolve, recruit or persist without the player.
- Record outlaw careers, relationships and succession in the historical and graveyard systems.

*Example:* A player can join bandits, steal livestock, fence goods, advance, challenge leadership and provision a hideout; NPC factions evolve independently.
*Verification:* Test crime consequences, faction economy, leadership and guard enforcement.

## Original mandatory acceptance checks (verbatim)

- Materials report shows ≥3 distinct consuming recipes and ≥2 professions for every non-exempt standard material.
- Each production profession supplies another; at least one multi-step production chain works end to end.
- NPCs consume real inventory and funds, pursue independent goals, compete and adapt to shortages over extended simulation time.
- Treasury income and expenses, guard staffing, law enforcement and leadership succession change the settlement without player direction.
- A player can join a bandit faction, advance, challenge its leader and manage the faction; NPC factions also progress autonomously.
- Deaths create permanent interactive headstones with accurate career, kinship and relationship-grounded remembrance data.
- Wiki data agrees with actual recipes, materials and profession mechanics.
- Manifest IDs and dependency references validate after changes; save/load preserves world, inventories, family histories and faction/government states.
- Implementation note: This is the approved design specification to hand to agents. Any unimplemented mechanics should be tracked as development work; do not mark rules satisfied solely because the code compiles or a task was checked off.

## Companion validation scenarios (from the expanded reference)

- **Generational memory:** trace the real 30-plank gift into a named house and record event provenance, family knowledge transmission, descendant dialogue, relationships and individual voting (GM-01, VP-01).
- **Wildlife recovery:** diagnose the zero-wildlife result by species, hunting, breeding and predation; test protected refuges and gradual dispersal without instant respawn (WR-01, B14R-12).
- **Population and housing:** investigate the fall from 100 to 69 and zero new houses over 365 days through needs, resources, construction, household aspirations and mortality, rather than assuming causes (B14R-12).
- **Real-device testing:** automated tests do not establish Android touch, physical controller or Windows performance (the register's real-device verification queue).

## Rules 017 onward

### 017 Generational Memory and Living History

Owner directive 2026-10-19 (`docs/directives/2026-10-19_memory_refuges_politics.md`, section 40), verbatim:

> "Significant actions must be capable of becoming persistent historical events whose consequences can influence future
> generations. NPC knowledge must have plausible sources, familial relationships must be understood, and memories must
> connect to actual people, resources, properties, and outcomes."

It overlaps rules 009 and 014 and extends them; it does not replace them.

### 018 Protected Ecological Continuity

Same directive, section 40, verbatim:

> "Wildlife populations must be finite and responsive to hunting and environmental pressures while protected breeding
> refuges allow gradual, habitat-dependent recovery through reproduction and dispersal."

It extends rule 013 for wildlife.

### 019 Living Political Agency and Democratic Consequences

Same directive, section 40, verbatim:

> "Eligible NPCs must cast genuine individual votes based on their knowledge, relationships, family histories,
> interests, and assessment of candidates. Political offices must have real responsibilities and consequences.
> Elections, governance, and political succession must continue independently of the player and persist across
> generations."

It adds individual voting and democratic consequence to rule 015 (offices, treasury, succession) without duplicating it.

### 020 Autonomous Housing

Owner directive 2026-10-20 (`docs/directives/2026-10-20_housing_succession_adoption.md`), final governing principle, verbatim:

> "My Medieval Life is about people living autonomous lives.
>
> A villager who needs a house should recognize that need, decide to do something about it, and work toward making it
> happen."

Part 1 of the same directive is the full rule. A household's responsible adult, of either sex, recognizes a real housing need. They keep it as a goal before the household can afford it, and work toward it through real work, saving, buying, gathering and help. The construction consumes real materials and takes real time; it yields to survival needs and resumes after shortages. There are no quotas, no free supplies and no new building types to force success. Register: HOUSE-01..09 under EQ-07.

**Owner answer of 2026-10-20 (OD-13), part of this rule:**
- Young children may share beds, within reasonable age limits, and couples share a bed.
- Existing village houses can take living-quarters expansions even though they were generated without land parcels.
- Expansions consume real resources, labour and construction time; no bed or house is ever generated free.

### 021 Household Succession and Family Care

Same directive, final governing principle, verbatim:

> "A family that loses a parent should continue under the surviving parent.
>
> Children who lose both parents should first go to grandparents, then the nearest eligible blood relative, and
> finally another villager's household.
>
> These are connected consequences of the same living world, but housing construction and family succession must
> remain separately tracked development responsibilities."

Parts 3 and 4 of the same directive are the full rule. Adoption is informal, with no authority. Genealogy is never overwritten, and a surname may change without corrupting the tree. Orphaned children never found households or build. A housing need that taking in children creates belongs to the receiving household's responsible adult. Register: FAM-01..07.

**Owner answers of 2026-10-20 (`docs/directives/2026-10-20_owner_answers_OD11_OD12_OD13.md`), part of this rule:**
- **Unplaced orphans (OD-11).** The guardianship order is the surviving parent, then living grandparents, then the nearest eligible blood relative, then another villager's household willing and able to take the child. If no suitable household can take the child, the child joins the bandit clan. That is the intended fallback: there is no temporary care and no orphanage. The child keeps their identity, age, genealogy and relationships, and stays a child, without adult combat abilities.
- **Equally close relatives (OD-12).** Blood relationship sets the order of consideration. Among equally close relatives, the best-suited is chosen: ability to provide care, then household capacity, then access to food and necessities, then the existing relationship with the child, then geographic proximity, then a deterministic tie-breaker.

### 022 A Village Is Allowed to Fail; the Simulation Is Not

Owner's final development mandate, 2026-10-20 (`docs/directives/2026-10-20_final_development_mandate.md`), sections 1-4,
11 and 12. Its own words: "A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT." and "The game must simulate a
functioning world, not guarantee a successful world."

- **Outcomes may be unfavourable.** A village may prosper, stagnate, decline, lose its trades or collapse. Unfavourable
  statistics are not proof of defective code, and two seeds may develop differently.
- **Three categories, kept apart, for every finding:**
  1. a **defect**: a mechanic fails to perform its approved function (logic that never runs, a tool that cannot be
     obtained though one is available, a lost goal, script errors, coins or items without a valid transaction, an
     invalid loop, a save that loses state). Fix it with a regression test, if it blocks the current release.
  2. a **legitimate outcome**: functioning mechanics meeting finite resources and autonomous decisions (bankruptcy, an
     unaffordable tool, a refused deal, unemployment, decline). Record it and proceed.
  3. a **future improvement**: an opportunity for better adaptation or new NPC behaviour. Classify it under its
     approved requirement, or ask the owner when its design is not approved.
- **No hidden rescue.** No hidden subsidies, free tools, fabricated materials, guaranteed buyers, artificial
  employment, automatic wealth redistribution or invisible central authority to force convergence. Institutions act
  only through approved rules (the manor may commission tools, lend, buy or decline).
- **Mandatory, always:** mechanical correctness and simulation integrity (state, resources, ownership, accounting,
  saves); every coin and item with a legitimate history; deterministic reproduction for a seed and revision.
- **Tests:** never require arbitrary prosperity, identical growth or a fixed number of houses unless an approved
  requirement says so. Economic outcomes are measured and analysed, not pass/fail thresholds.
- **Builds:** do not rerun year-long simulations in pursuit of favourable statistics, nor retune earlier systems to
  preserve a predetermined outcome when new systems arrive (Builds 17, 18).

## Related, not numbered as rules

- The living-world document's nine guiding principles (`docs/MEDIEVAL_LIVING_WORLD_SYSTEM_DESIGN.md` section 1).
- The project rules in `CLAUDE.md`.
- The compliance record in `docs/LIVING_WORLD_ALIGNMENT.md`.
