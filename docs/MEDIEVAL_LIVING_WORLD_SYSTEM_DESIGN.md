# Medieval Living World and Production Economy

**Document type:** Design reference / architectural aid  
**Status:** Conceptual, non-binding  
**Intended audience:** Hot Attic Games developers, repository agents, designers, and future contributors  
**Version:** 0.1 — 2026-10-17

> **Purpose:** Describe the intended behavior, principles, dependencies, and implementation considerations of a persistent medieval world simulator. This document is a guide to decisions, **not** a literal implementation blueprint or a claim that the described systems already exist. Examples are illustrative. Implementation should be adapted to the actual engine, project structure, performance budget, and testing results.

## 1. Vision and player fantasy

Build a medieval world that has an independent social and economic life. The player enters a world of people who work, travel, buy, sell, consume, make plans, own goods, form relationships, and experience consequences. The world is not populated by disposable NPCs whose sole purpose is to service the player. A player may become a miner, shepherd, blacksmith, merchant, tailor, farmer, builder, mercenary, or bandit—or mix professions—without being forced through a class or level ladder.

The key design aspiration is **systemic emergence**: consequences arise from interactions among consistent systems rather than being exclusively scripted. If a miner is killed on the road after selling ore, the coins on that miner are real possessions, their death is persistent, their household may lose income, and the smithy may lose a supplier. Those consequences depend on the actual state of the world; they are not guaranteed cutscenes or scripted quest outcomes.

### Guiding principles

1. **NPCs are inhabitants, not props.** Give persistent people identities, possessions, routines, constraints, and goals.
2. **Resources and money have provenance.** Items move through harvesting, production, inventory, transport, exchange, consumption, and loss.
3. **Production has meaningful intermediate stages.** Ore, ingots, yarn, cloth, planks, and leather are usable and tradable in their own right.
4. **One shared ruleset where practical.** Player and NPC crafting, ownership, transactions, and physical inventory should use compatible definitions.
5. **World reactions are conditional.** A death or shortage matters according to local dependencies, inventories, alternatives, and knowledge.
6. **Simulation is scalable.** Distant actors can be simulated abstractly without losing the integrity of the underlying world state.
7. **Complexity should create choices, not chores.** Allow specialization, hired labor, and eventual workshop production to reduce repetition.
8. **The world is host-owned and pauses when closed.** No requirement for offline, real-time simulation after the host stops the game.
9. **Data-driven and extensible.** Hundreds or thousands of resources, recipes, and item types should be possible without rewriting core logic.
These nine are this document's guiding principles. They are not the owner's numbered World Design Rules, which are
kept in `docs/WORLD_DESIGN_RULES.md` (rules 001-016 from the owner's original list, and 017 onward).

## 2. Confirmed direction versus open design questions

### Established design intent

- Medieval setting and a robust, interdependent resource/production economy.
- Persistent NPC lives, occupations, inventories, finances, and meaningful actions.
- Players may pursue productive trades and criminal paths, not only combat.
- Actual movement of resources and currency through the world.
- Persistent consequences when NPCs are interrupted, robbed, or killed.
- The game world is associated with its host; character belongings and world state belong to that world.
- When the game is shut down, simulation stops; it resumes when the world is opened again.
- Support for small shared multiplayer worlds is a desired direction; final network architecture is not yet fixed.
- The document is guidance, not a frozen specification.

### Proposals requiring decisions

- Birth, aging, children, natural death, inheritance, and generational continuity.
- Exact NPC needs and their simulation frequency.
- Whether currency is strictly conserved, can be minted, or can enter through explicit sinks/sources.
- Realism level for metallurgy, alchemy, medicine, and historical technology.
- Item quality, material grades, spoilage, durability, and repair formulas.
- How law, reputation, witnesses, investigations, and punishment operate.
- Whether the world uses fully continuous time or scheduled simulation ticks.
- How players learn recipes and whether all professions can ultimately be mastered.
- How much economic price formation is simulated versus rule-driven.
- Settlement scale, population cap, and world size.

Do not silently treat proposals as finalized requirements.

## 3. The core loop: living economy

**Natural resources → extraction/harvest → processing/refining → manufacture → transport → trade → household/workshop consumption → demand for new production.**

Currency moves between buyers and sellers. Goods and currency must be assigned to specific owners, inventories, storage locations, shipments, or world drops. Consumption, loss, breakage, and deliberate economic sources/sinks must be explicit.

The economy should work without a player present in every interaction. Producers respond to needs, opportunities, tools, stocks, skill, distance, risk, and available buyers. A village can function even if the player never visits it, subject to simulation budgets and world rules.

### Illustrative miner-to-smith transaction

1. A persistent miner owns a pickaxe, provisions, pack animal, home, and a small balance of coins.
2. The miner travels to a known ore deposit, works for several days, consumes supplies, and damages tools through use.
3. Extracted ore is removed from the deposit and added to an inventory or storage site.
4. The miner travels with a physically or abstractly represented cargo to a smithy or market.
5. The smith purchases ore with money the smith actually possesses, receiving the ore in a transactional transfer.
6. The miner carries earnings and may buy food, tools, feed, repairs, or household goods.
7. A player may encounter, trade with, escort, rob, or kill the miner. Loot consists of what is actually carried, not a generic drop table.
8. If the miner dies, their economic activity ceases. The household, mine, and buyers may react according to their knowledge and alternatives.
9. All states survive save/load and a transition between detailed and abstract simulation.

**Important:** The death of one miner does *not* automatically force a price spike or a quest. The system checks whether supply was constrained, other suppliers exist, inventory buffers are available, and relevant actors have learned of the event.

## 4. Resource taxonomy and industry networks

| Industry | Inputs / raw resources | Intermediate products | Outputs / dependencies |
|---|---|---|---|
| Forestry | Trees, bark, resin | Logs, planks, poles, charcoal | Construction, furniture, tool handles, fuel |
| Mining and quarrying | Iron ore, copper ore, tin ore, stone, clay, coal | Sorted ore, cut stone, prepared clay | Metallurgy, masonry, pottery |
| Agriculture | Seeds, land, water, manure | Grain, vegetables, flax, hemp | Food, feed, fiber, trade |
| Animal husbandry | Livestock, feed, pasture | Wool, milk, hides, fat, meat | Textiles, leather, food, candles |
| Textiles | Wool, flax, hemp, dyes | Clean fiber, yarn, thread, woven cloth | Clothing, rope, sails, furnishings |
| Leatherworking | Hides, tanning agents | Cured hide, leather | Boots, belts, bags, armor components |
| Metallurgy | Ore, flux, fuel | Bloom, iron stock, ingots, alloys | Nails, fittings, tools, weapons, armor |
| Carpentry | Timber, nails, adhesives | Boards, joints, components | Furniture, wagons, doors, buildings |
| Masonry and ceramics | Stone, clay, lime, sand | Blocks, bricks, mortar, tiles | Buildings, kilns, furnaces |
| Food and brewing | Grain, meat, vegetables, fruit | Flour, dough, preserved goods, mash | Bread, meals, ale, provisions |
| Herbalism and medicine | Herbs, plants, oils | Dried herbs, extracts, poultices | Treatments, dyes, trade goods |
| Transportation and trade | Animals, carts, containers | Packed cargo, shipments | Distribution, arbitrage, market access |

These are **families**, not exhaustive recipe lists. Resources should cross industry boundaries. For example, leather is useful to armorers, tailors, saddlers, and bookbinders.

## 5. Multi-stage production chains

### Wool to clothing

Sheep → shearing → raw fleece → cleaning/carding → fiber → spinning → yarn → weaving/knitting → cloth or garment material → cutting/sewing → finished clothing. Optional stages: dyeing, tailoring, repair. Living sheep can be sheared repeatedly with appropriate regrowth; slaughter yields different resources and consequences.

### Ore to finished sword

Locate deposit → extract ore → prepare ore and fuel → smelt to workable metal → refine/work iron or produce suitable steel → form blade → heat treatment appropriate to material → grind/polish → produce wooden grip, leather wrapping, fittings → assemble → maintain and repair.

**Historical realism note:** A medieval bloomery may produce a bloom rather than directly casting modern-style iron ingots. Game terminology and technology should be internally consistent even when simplified for playability.

### Wheat to bread

Cultivate land → sow → tend → harvest → thresh/winnow → grain → mill → flour → combine ingredients → dough → bake using fuel → bread → storage/sale/consumption.

### Wood to shelter

Harvest tree → log → saw/hew → beams and boards → joinery + nails/pegs + roofing + masonry → structure. Buildings consume material, require labor/tools, and may require maintenance.

### Cross-chain rule

An intermediate product should be usable by **multiple** downstream recipes and independently tradable when appropriate. Avoid a giant collection of isolated one-off recipe chains.

## 6. Resource gathering and environmental constraints

Gathering activities include mining, quarrying, logging, foraging, hunting, fishing, farming, animal husbandry, and salvage. Each activity may consider resource availability, access/ownership rights, season, tool suitability, worker skill, effort, weather, transport capacity, and danger.

- **Finite deposits:** Mining removes quantity from a specific deposit; exhaustion changes production and travel decisions.
- **Renewable resources:** Trees regrow, crops can be planted, animals reproduce or regrow wool, and fish populations may recover under appropriate rules.
- **Regional variation:** Soil, geology, climate, vegetation, and settlement history influence what can be produced economically.
- **Land rights:** Resources can be owned, leased, protected, disputed, or freely gathered depending on local rules.
- **Transport matters:** A valuable deposit far from a market may be less profitable than a mediocre one nearby.
- **No arbitrary duplication:** Reopening a chunk or moving out of view cannot restore consumed ore or sold goods unless explicit regeneration rules allow it.

## 7. Items, recipes, tools, workstations, and quality

### Resource and item definitions

Prefer stable data identifiers with descriptive metadata: category, material composition, mass/volume, stack behavior, quality, durability, value-related attributes, perishability, legal status, and supported uses. Not every item needs every attribute.

### Recipe definitions

Support multiple inputs, alternative acceptable materials, quantities, tools, required workstation, fuel/energy, time, skill/knowledge, environmental conditions, byproducts, waste, and quality modifiers. Recipes should be declarative and validated at load time.

### Workstations

Examples: campfire, drying rack, spinning wheel, loom, mill, kiln, tannery, forge, bloomery, anvil, carpenter's bench, and kitchen. A workstation may have ownership, capacity, condition, fuel, available tools, active jobs, and stored inputs/outputs.

### Quality and wear

Distinguish **material quality** from **craftsmanship quality**. A skilled smith with poor iron cannot necessarily create a top-tier blade, and high-grade metal does not compensate for every fabrication error. Tools and goods can degrade through use; repairs consume time, materials, and appropriate equipment.

### Recipe knowledge and progression

Possible learning paths: experimentation, observation, manuals, apprenticeships, mentors, trade practice, and exploration. Player power comes substantially from skills, knowledge, tools, infrastructure, and possessions rather than arbitrary character level alone. Specialization should be worthwhile without permanently locking a player into a class.

## 8. Persistent inhabitants and households

Each persistent NPC should have a stable identity and a manageable set of state variables, with additional detail loaded only when useful.

**Suggested categories:** identity; age and life stage if enabled; household and dependents; home; workplace and profession; skills and knowledge; needs; possessions and finances; relationships; affiliations; goals; current plan; memories of significant events; legal/reputation state; health; location and travel state; obligations and contracts.

Not every inhabitant needs generative AI or continuous deliberation. Utility scoring, finite-state machines, behavior trees, goal-oriented planning, and scheduled tasks may be combined according to complexity. Prefer predictable, inspectable decisions over opaque expensive behavior.

### Example daily and long-term behaviors

- A farmer checks crops, labor availability, season, weather, and food reserves.
- A blacksmith purchases fuel and metal according to orders, stock, and cash.
- A miner decides whether the expected earnings justify a distant deposit.
- A merchant compares markets and travel risk.
- A household buys food, repairs equipment, saves money, or takes on debt.
- An unemployed NPC may seek work, retrain, migrate, or turn to crime depending on circumstances.

### Birth, aging, inheritance, and mortality

These are **potential expansion systems**, not yet confirmed. If included, design for births, family formation, natural death, succession, inheritance, labor replacement, and intergenerational social history. Avoid introducing them before the basic production economy is stable.

## 9. Economy, markets, and money

### Inventory and currency conservation

Track inventories and account balances for actors, businesses, storage containers, shipments, and world drops. A purchase should be atomic: money transfers from buyer to seller while goods transfer from seller to buyer, or neither transfer commits. Money creation/destruction must be explicitly modeled if allowed.

### Supply, demand, and pricing

Possible factors: local stock, expected demand, quality, scarcity, travel cost, risk, season, taxes/tolls, seller urgency, contracts, and reputation. A simple bounded price model is preferable initially to a fragile full economic equilibrium model.

### Consumption and sinks

Food is eaten, fuel burned, equipment wears out, goods spoil, construction uses materials, and repairs require inputs. These sinks maintain demand. Avoid inventing consumption merely to force grinding; tie it to plausible world needs.

### Business behavior

Businesses may own stock, cash, tools, facilities, debts, wages, and recurring expenses. Merchants should not have infinite money or infinite inventory unless explicitly designated as a deliberate abstraction.

### Logistics

Goods move by carried inventory, carts, pack animals, ships if supported, and warehouse storage. Shipment delay, capacity, spoilage, theft, and route safety can shape trade and settlement development.

## 10. Crime, conflict, law, and consequences

Allow theft, robbery, trespass, assault, murder, fraud, and related behaviors where appropriate to the game's rating and design. The player can pursue a bandit livelihood, but victims and communities respond based on information and capability.

- **Actual loot:** A victim drops or transfers what they possess, subject to world rules.
- **Witnesses and knowledge:** Actors should not magically know about unwitnessed crimes. Reports, discovery, rumor, and investigation can propagate information.
- **Social impact:** Households lose members/income; employers lose labor; merchants may alter routes; guards may patrol risky areas.
- **Economic impact:** Supply chains may be disrupted, but only when the lost actor or cargo mattered.
- **Legal impact:** Jurisdictions, fines, imprisonment, bounty, confiscation, or other punishments are optional systems to specify later.
- **Avoid hardcoded outcomes:** Robbing a road repeatedly may cause merchants to avoid it, hire protection, or continue if profits justify the risk.

The economy and law should react to player actions without assuming the player is the center of every event.

## 11. Simulation levels and performance

The world may contain more persistent inhabitants than can be fully rendered and physically simulated at once. Separate **simulation truth** from **visual presentation**.

| Tier | When used | Behavior |
|---|---|---|
| Detailed | Near active players | Movement, animation, interaction, combat, physical inventory, immediate decisions |
| Abstract | Distant active regions | Scheduled travel, work, transactions, production, needs, encounters, event resolution |
| Dormant/paused | Host game closed | No elapsed simulation; save state and resume from same logical world time |

A distant miner may have an abstract travel state with route, cargo, departure time, and expected arrival. On approach, instantiate an appropriate physical actor without creating extra items or advancing the schedule twice.

### Transition invariants

- An NPC has exactly one authoritative logical state at a time.
- No duplicate inventory, coin, shipment, or production result during tier transitions.
- Events are resolved once, with idempotent handling where feasible.
- Distant actions respect world time, availability, and plausible capacity.
- If a player enters an area during an abstract encounter, the result should be consistent with the current authoritative state.
- Budget CPU work using scheduled ticks, batching, event queues, and capped decision frequency.

### Time semantics

The world clock advances only while the host is running the world, unless the design explicitly changes. Do not apply real-world elapsed time between shutdown and restart. Saving must preserve schedules, active production, travel, and outstanding events.

## 12. Persistence, multiplayer, and authority

**Current intent:** A character's possessions and history belong to the world they inhabit. The host's world is saved and resumes on reopening. The world does not keep running in the background while closed.

For future shared-world play, prefer a **host-authoritative** simulation: clients request actions; the host validates inventory changes, purchases, production, movement-sensitive interactions, and combat outcomes. Do not let each client independently create currency or goods.

Suggested persistent entity families: world, regions, deposits, items/stacks, containers, NPCs, households, businesses, settlements, workshops, production jobs, shipments, market offers, contracts, relationships, and significant events.

Use stable IDs, versioned save formats, migration support, and atomic or recoverable transactions. Determine early whether inventories represent item instances, fungible stacks, or a hybrid. Avoid prematurely fixing exact schema or network protocol in this reference document.

### Failure scenarios to test

- Save/load during a purchase or robbery.
- Player disconnects while transferring items.
- NPC changes simulation tier during a transaction.
- Host closes while a furnace is running or a caravan is traveling.
- Two buyers attempt to purchase the same goods.
- A miner dies while carrying cargo and coins.
- A deposit is exhausted during multiple workers' extraction attempts.
- A workshop's input inventory is removed mid-production.

## 13. Technical architecture recommendations

Favor separable, testable modules rather than one monolithic world script:

- **Catalogs:** resources, item types, recipes, skills, professions, workstations.
- **Inventory and ownership:** containers, stacks, transfer validation, provenance.
- **Production:** jobs, input reservations, work progress, output/byproducts, failures.
- **World resources:** deposits, regeneration, harvest rights, geography.
- **Economy:** offers, pricing, orders, currency, trade, business accounts.
- **NPC agency:** needs, goals, plans, routines, knowledge, reactions.
- **Logistics:** routes, transport capacity, shipments, travel risk.
- **Social/legal:** relationships, witnesses, reputation, crimes, institutions.
- **Simulation scheduler:** tier selection, events, time, work budgets.
- **Persistence/network:** save versions, authority, validation, synchronization.
- **Presentation:** animations, dialogue, UI, audio, map, feedback.

Implement definitions as project-appropriate structured data. Do not assume a particular language, plugin, database, or Godot node layout until the repository is inspected. Keep simulation logic usable in headless tests where possible.

## 14. Recommended vertical slice

**Goal:** Prove that one economic loop works end-to-end before expanding into hundreds of recipes or thousands of inhabitants.

**World:** One small settlement, one iron deposit, one miner, one blacksmith, one food supplier, a market, a road, and storage.

**Minimum playable scenario:**

1. Miner owns tools, provisions, and a known deposit.
2. Miner extracts a finite quantity of ore, consuming time and tool durability.
3. Ore exists in inventory and can be observed or taken.
4. Miner travels to smithy and sells ore for actual money.
5. Smithy receives ore and loses coins.
6. Smith processes ore using fuel and equipment into an intermediate material.
7. Smith manufactures an item and offers it for sale.
8. Miner buys food or tools with earned coins.
9. Player can buy, steal, escort, or interrupt the miner.
10. NPC death or loss of cargo changes future behavior where relevant.
11. Save/load and distance-based abstraction preserve every inventory and transaction.
12. Debug UI can explain *why* an NPC chose a task and *where* every resource moved.

### Acceptance tests

- Total ore extracted cannot exceed available deposit stock.
- Trades conserve goods and currency, except explicit sources/sinks.
- Production consumes required inputs once and creates outputs once.
- NPCs do not respawn automatically to restore a broken supply chain.
- Off-screen and on-screen outcomes agree within designed abstractions.
- Closing and reopening the game does not advance world time.
- A robbery transfers actual carried inventory; it does not spawn generic loot.
- The simulation recovers safely from interruption and save/load.
- NPCs can function without player-triggered quests.

## 15. Expansion roadmap (not a commitment)

**Phase A — Foundation:** data catalogs, inventory, ownership, time, saving, transactions.  
**Phase B — First economy loop:** mine → ore → smith → finished item → sale/consumption.  
**Phase C — More industries:** farming, food, forestry, textiles, leather, construction.  
**Phase D — Households and social response:** needs, income, relationships, crime reports, shortages.  
**Phase E — Regional economy:** multiple settlements, logistics, contracts, pricing, trade routes.  
**Phase F — Deep world simulation:** migration, institutions, specialized professions, optional generational systems.  
**Phase G — Multiplayer hardening:** host authority, desync prevention, world ownership, recovery tests.

Each phase should have an end-to-end testable outcome, not just an expanding list of items.

## 16. Risks and design tradeoffs

- **Scope explosion:** Recipe breadth is easier than meaningful integration. Prioritize complete chains.
- **CPU cost:** Thousands of fully thinking NPCs are unnecessary; use event-driven abstract simulation.
- **Economic deadlocks:** A missing worker or tool can halt production. Allow believable recovery paths without secretly fabricating goods.
- **Player frustration:** Historical fidelity should not require endless manual microsteps; support batching, delegation, and tools.
- **Runaway prices:** Scarcity can create instability; use bounded pricing, substitutes, buffers, and world-consistent intervention.
- **Save complexity:** Transactions and NPC state can corrupt or duplicate if persistence is careless.
- **Multiplayer exploitation:** Host must validate item creation, crafting, and currency movement.
- **Overly deterministic NPCs:** Routines need adaptation, but randomness must not make behavior incomprehensible.
- **Premature AI dependency:** Most economic choices do not require a language model; reserve expensive AI for cases that materially benefit.
- **Content authoring burden:** Build validation tools, recipe dependency inspection, and debugging views early.

## 17. Questions for future design reviews

1. Is aging and generational population change in scope for the initial game?
2. What is the target number of simultaneously simulated NPCs and settlements?
3. How realistic should seasons, spoilage, diseases, and animal populations be?
4. What is the initial minimum viable set of industries?
5. Are players free to learn all trades, or does specialization impose soft constraints?
6. How do land ownership, wages, debt, and taxation work?
7. What economic abstractions are acceptable when actors are distant?
8. What happens when an essential producer dies and no replacement exists?
9. How much of the world economy is visible to players through interfaces?
10. What are the minimum hardware targets, including Steam Deck?
11. What is the final multiplayer host/save architecture?
12. How will debugging expose the causes of shortages, prices, and NPC decisions?

## 18. Repository usage guidance for development agents

Treat this file as **design intent and evaluation criteria**, not permission to refactor or implement the entire game in one pass. Before writing code:

1. Inspect the repository, current architecture, and existing conventions.
2. Identify which described systems already exist and which are proposals.
3. Recommend a minimal vertical slice and list impacted files/components.
4. Preserve current functionality and save compatibility unless changes are explicitly approved.
5. Make incremental changes with tests for conservation, persistence, and simulation-tier transitions.
6. Document deviations and unresolved questions instead of inventing requirements.
7. Avoid implementing speculative systems such as births, advanced taxation, or complex politics without approval.

**Success criterion:** The game begins to feel like a medieval society in which goods, labor, money, and decisions have causes and consequences—even when the player does nothing.
