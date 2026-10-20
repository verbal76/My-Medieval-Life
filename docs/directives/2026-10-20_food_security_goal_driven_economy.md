# Owner directive, 2026-10-20: food security, household production, land use, markets and goal-driven economic behavior

Saved verbatim. It supersedes any conflicting interpretation in the earlier food-economy prompts. Register: FSE-00 (the
directive) and its children FSE-01 to FSE-07 (the deliverables). The audit and plan it asks for are in
`docs/design/FOOD_SECURITY_AUDIT.md`.

---

MY MEDIEVAL LIFE

FINAL MASTER DIRECTIVE — FOOD SECURITY, HOUSEHOLD PRODUCTION, LAND USE, MARKETS, AND GOAL-DRIVEN ECONOMIC BEHAVIOR

Project: My Medieval Life
Status: Owner-approved design direction
Applies to: Build 16 audit and foundations, subsequent living-economy development, and all systems affected by these requirements

Claude, this is the final consolidated directive covering our discussion of agriculture, food security, household self-sufficiency, hunting, animal husbandry, land rental, market stalls, and individual economic decision-making.

It supersedes any conflicting interpretation in the earlier food-economy prompts.

Read it as a unified design requirement, not a collection of independent features.

The objective is not simply to add farming or hunting.

The objective is to create people who pursue their own goals within a functioning, interconnected economy.

Their economic activities should emerge from their needs, resources, opportunities, experience, relationships, priorities, and personal circumstances.

Do not reduce this to a rigid decision tree or a single mathematical optimization formula.

---

1. CENTRAL DESIGN PHILOSOPHY

Every villager is an individual participating in the same world economy.

The player is also a villager.

Everyone operates under the same rules for:

- Skills and experience.
- Production and crafting.
- Food consumption.
- Land ownership and rental.
- Hunting and animal husbandry.
- Market transactions.
- Inventory and resource conservation.
- Employment and household activities.
- Financial obligations.
- Economic opportunities.

The difference between the player and an NPC is who makes decisions.

The player is controlled by a human.

NPC villagers make decisions through their AI.

Villagers do not merely react to prices. They make economic decisions in pursuit of the lives they want to build.

This is the governing principle for everything that follows.

---

2. FIRST: AUDIT WHAT ACTUALLY EXISTS

Before implementing new systems, audit the current simulation.

Do not assume that the presence of wheat, food consumption, wildlife, or farmer occupations proves that complete agricultural and hunting systems exist.

Determine exactly what is implemented.

Agriculture

Answer:

1. Are villagers actually planting crops?
2. Are crops associated with real fields or plots?
3. Are seeds consumed when planted?
4. Do crops grow over time?
5. Are growing seasons represented?
6. Are crops harvested through actual villager activity?
7. Does harvested food enter real inventories?
8. Are yields limited by land, labor, seed, and growing time?
9. Can crops fail?
10. Is seed grain retained for subsequent planting?
11. Does soil quality, weather, skill, or other existing factors affect production?
12. Are farmers producing food independently of player involvement?

Food consumption

Determine:

1. How much food does one villager consume daily?
2. How much does one villager consume annually?
3. Do children have different requirements?
4. What does a typical household consume?
5. How much food does the entire village require annually?
6. How much food is produced locally?
7. How much is imported?
8. How much is exported?
9. How much spoils?
10. How much remains in storage?
11. Are there any unexplained sources of food?
12. Can current production sustain the village without imports?

Hunting

Determine:

1. Do villagers actively hunt?
2. Is hunting limited to professional hunters?
3. Can a hungry nonhunter hunt?
4. Are real wildlife entities removed through hunting?
5. Are carcasses processed into meat and other products?
6. Do the resulting goods enter the economy?
7. Is hunting limited by wildlife populations?
8. Can excessive hunting deplete local wildlife?
9. Do hunting activities award the same experience to players and NPCs?

Animal husbandry

Determine:

1. Which livestock species currently exist?
2. Can villagers own them?
3. Can they breed?
4. Do they require food and care?
5. Can villagers obtain useful products from them?
6. Are animal populations and products properly accounted for?
7. Can nonprofessional households maintain livestock?

Land and commerce

Determine:

1. Who owns agricultural land?
2. Can villagers rent plots?
3. Are rent payments represented as actual transactions?
4. Can villagers operate market stalls?
5. Can households sell surplus goods?
6. Can villagers pursue more than one source of income?
7. Do occupations unnecessarily restrict activities?
8. Can the player participate in these same systems?

For each answer, identify the relevant code or data, current behavior, limitations, and missing functionality.

Distinguish verified implementation from planned features.

---

3. CALCULATE THE ACTUAL FOOD REQUIREMENT

We need to know how much productive land is required to sustain one person.

Use the simulation's actual food-consumption units.

Calculate:

- Food consumed by one adult per day.
- Food consumed by one adult per year.
- Food consumed by a child, where applicable.
- Food consumed by a household.
- Food consumed by the village.
- Expected edible yield per cultivated plot.
- Seed required for the next planting.
- Expected losses and spoilage.
- Growing time and seasonal availability.
- Labor needed to plant, maintain, and harvest.
- Land required to sustain one person under normal conditions.

Where the game uses abstract land units rather than historical acres, report the results in the actual game units.

Do not invent precision unsupported by the simulation.

Show the formulas and assumptions.

For example:

Annual edible food requirement = daily consumption × days per year.

Net edible harvest = total harvest − seed retained − spoilage − other required uses.

Land requirement = annual food requirement ÷ expected annual net edible yield per unit of land.

Adjust these calculations to the actual crop and production systems.

Also estimate the effect of poor harvests, insufficient labor, and seasonal shortages.

The calculation is a planning tool, not a survival guarantee.

A village may fail to grow enough food.

---

4. HOUSEHOLD GARDENS AND AGRICULTURAL LAND

Villagers must be able to obtain access to small agricultural plots.

A person does not need to be a professional farmer to grow food.

Examples:

- A blacksmith grows vegetables for the household.
- A carpenter rents a small garden.
- A miner grows food during periods of limited work.
- A farmer rents larger fields for commercial production.
- A merchant maintains a small plot for household security.

Support meaningful scales of cultivation:

1. Small household gardens.
2. Subsistence plots.
3. Mixed household and commercial plots.
4. Larger commercial agricultural holdings.

Land must exist within the world's available land supply.

Plots cannot be created without available space.

Land rentals should reflect actual size, productive potential, availability, and local conditions.

Small plots should be economically accessible when local conditions permit, but do not guarantee every household access to land.

Rent must be paid to a legitimate owner.

Payments must conserve coins.

Landlords must not receive magically generated rent income.

Renters must face real obligations and consequences if they cannot pay.

Agricultural production requires actual resources, including seeds, labor, time, tools, and any other existing requirements.

---

5. ANIMAL HUSBANDRY AND RENTED PEN SPACE

Villagers must be able to obtain land or appropriate space for keeping livestock.

This may be for household consumption, commercial production, or both.

Where supported by the simulation, households should be able to:

- Purchase or otherwise legitimately acquire animals.
- Maintain pens or suitable grazing areas.
- Feed and care for animals.
- Breed livestock.
- Collect applicable animal products.
- Slaughter animals for food where supported.
- Retain products for household use.
- Sell surplus products.

Animal ownership must be represented in the simulation.

Livestock must not appear without a source.

Reproduction must respect actual breeding and population rules.

Animal products must be conserved through the existing accounting systems.

Animal husbandry consumes resources, labor, space, and time.

Do not invent new livestock species or products without identifying that as additional development scope.

---

6. HUNTING, GATHERING, AND SURVIVAL

Villagers should be able to hunt when hunger, opportunity, profit, or personal preference makes hunting attractive.

Hunting must not be exclusive to professional hunters.

A blacksmith may hunt to feed their family.

A farmer may hunt during winter.

A merchant may hunt for recreation or supplemental income if the game's supported motives allow it.

A villager saving for a house may hunt to avoid spending money on food.

However, hunting must remain a real activity with real constraints.

Consider:

- Wildlife availability.
- Relevant skills.
- Equipment.
- Physical condition.
- Travel time.
- Danger.
- Household needs.
- Opportunity cost.
- Existing hunting rights or restrictions.

Hunting must remove real animals.

Carcasses and harvested products must enter the existing goods-accounting systems.

Wildlife populations must respond to hunting pressure.

Do not spawn prey to rescue hungry villagers.

A villager may fail to find food.

They may lack equipment.

They may be injured.

They may decide hunting is too risky.

These are legitimate outcomes.

Gathering wild resources should follow the same principles wherever supported.

---

7. MARKET CONDITIONS INFLUENCE BEHAVIOR

Market prices matter.

They should influence decisions about buying versus producing necessities.

When food is inexpensive and readily available, some villagers may prefer purchasing it.

When food is expensive or scarce, growing, hunting, gathering, or raising food may become more attractive.

But price is not the sole deciding factor.

A villager earning substantial income from blacksmithing may reasonably prefer to buy food.

Another villager may continue farming despite low market prices because they value self-sufficiency.

A household may keep livestock even when meat is cheap because they want a reliable food supply.

A frugal villager may avoid purchases whenever practical.

Do not make every NPC follow the same price threshold.

Do not program universal behavior such as:

"If food price is below X, buy."

"If food price is above X, farm."

Instead, evaluate the individual's broader circumstances.

---

8. LONG-TERM GOALS DRIVE ECONOMIC CHOICES

This is one of the most important requirements in this directive.

Villagers have goals beyond satisfying immediate needs.

They may want to:

- Build or purchase a house.
- Acquire land.
- Start a business.
- Purchase better tools.
- Expand a farm.
- Raise a family.
- Save for future security.
- Accumulate wealth.
- Support relatives.
- Become more independent.
- Pursue other goals already supported by the simulation.

These goals influence everyday decisions.

Example: Saving for a house

A villager wants to build a house.

They decide to conserve money.

Instead of buying all their food, they rent a small plot and grow vegetables.

They occasionally hunt.

They raise chickens if resources permit.

They repair their own equipment where qualified.

They sell surplus produce at the market.

Their objective is not necessarily to maximize immediate income.

Their objective is to preserve or accumulate money for the house.

Even if food is cheap, they may still produce it themselves because keeping their money serves a higher-priority goal.

But this must remain an individual decision.

Another villager saving for a house may decide that working additional hours and buying food is more efficient.

Both approaches are legitimate.

The simulation should support both without forcing either.

---

9. TIME, LABOR, AND OPPORTUNITY COST

Every economic activity competes for limited time.

A blacksmith tending a garden is not simultaneously working at the forge unless the simulation legitimately supports both activities.

A villager hunting cannot also operate a market stall at the same moment.

A household maintaining livestock must allocate time to animal care.

Villagers should consider the value of their time.

For example:

A skilled smith may earn more money working than they would save by farming.

An unemployed villager may find gardening economically attractive because they have available time but little income.

A villager saving for a house may willingly accept lower immediate earnings in exchange for greater independence or reduced expenses.

These decisions do not need to be mathematically optimal.

Villagers may misjudge opportunity costs.

They may pursue habits, preferences, or personal goals that are not financially optimal.

That is acceptable.

---

10. PERSONALITY, PREFERENCES, AND INDIVIDUAL DIFFERENCES

Use existing character traits, relationships, preferences, memories, needs, and decision-making systems wherever available.

Different villagers should value different things.

Examples:

Frugal villager: Prefers saving money, repairing possessions, producing necessities, and avoiding unnecessary purchases.

Entrepreneurial villager: Seeks commercial opportunities, produces surplus goods, and invests in business expansion.

Cautious villager: Maintains food reserves, avoids risky investments, and prioritizes household security.

Specialist: Prefers developing their profession and purchasing goods from others.

Self-sufficient villager: Maintains a garden, livestock, and household supplies even when market purchases are affordable.

These are examples of possible behavior, not mandatory new personality classes.

Do not create a rigid personality template that forces identical behavior.

Do not introduce a second, disconnected personality system if existing AI mechanisms can express these differences.

Individual priorities should be capable of changing as circumstances change.

---

11. HOUSEHOLD MARKET STALLS AND SMALL COMMERCE

Villagers must be able to sell surplus goods without necessarily changing their primary occupation.

Examples:

- A blacksmith sells vegetables.
- A farmer sells eggs.
- A carpenter sells surplus crafted goods.
- A hunter sells meat or hides.
- A household sells extra produce from its garden.

Support market stalls or equivalent small-scale commerce through the existing market architecture where practical.

Stall ownership or operation should have real requirements, including suitable space, available time, inventory, and any legitimate market fees.

Do not generate customers or guarantee sales.

Buyers must have actual money.

Goods must physically or logically transfer from seller to buyer through the existing inventory system.

Coins must be conserved.

Households should consider their own future needs before selling surplus.

For example, a farmer may retain enough seed for next season rather than selling every harvested unit.

A household may keep food for winter instead of selling everything during harvest.

But individuals may make mistakes and sell too much.

Do not prevent every bad decision.

---

12. MULTIPLE INCOME STREAMS

A villager's occupation must not be an exclusive activity restriction.

A blacksmith can earn income from smithing, grow vegetables, keep animals, and operate a market stall.

A farmer may also hunt, craft tools, or perform paid labor.

A merchant may own livestock or cultivate land.

A household may receive income from several activities.

All income must originate from legitimate transactions or production.

All activities require actual time and resources.

The simulation must not treat side activities as free production.

Skills and experience must follow the existing PAR-01 rules.

A villager earns experience by performing an activity, whether it is their primary occupation or not.

Changing occupations does not grant experience.

Previously earned experience remains with the individual.

---

13. FINANCIAL PLANNING AND OD-19

Integrate these systems with the dynamic necessity-based reserve.

A household must consider:

- Immediate food requirements.
- Household stores.
- Dependents.
- Rent and other obligations.
- Expected income.
- Necessary tools and supplies.
- Future production requirements.
- Long-term savings goals.

Distinguish three concepts:

Immediate necessities: Resources needed for foreseeable survival and obligations.

Goal-directed savings: Money the household wants to retain for housing, land, business expansion, or another objective.

Discretionary resources: Money and goods the household is more willing to spend or trade.

These are planning priorities, not magically separated currencies.

A villager saving for a house may be reluctant to spend money on food if they can reasonably produce it themselves.

However, the villager must still be able to reconsider priorities during an emergency.

No absolute financial lock should prevent a household from buying essential food with its own money.

A household may make poor decisions.

Its plans may fail.

Do not guarantee financial success.

---

14. HOUSEHOLD AND MARKET FEEDBACK

Individual choices must influence the larger economy.

Examples:

If food prices rise, more households may attempt self-production.

That may increase demand for seeds, tools, livestock, and land.

If many households produce their own food, demand for market food may decline.

If production exceeds household needs, surplus may enter the market.

More market stalls may increase competition.

If households save aggressively for housing, spending patterns may change.

If livestock production expands, demand for feed and pen space may rise.

If many villagers hunt, wildlife populations may decline.

If professional workers spend more time producing their own food, their occupational output may fall.

These changes should emerge from actual actions and resource flows.

Do not impose artificial price stabilization.

Do not force economic equilibrium.

Do not guarantee that shortages are resolved.

A village is allowed to fail. The simulation is not.

---

15. LOCAL KNOWLEDGE AND IMPERFECT DECISIONS

Villagers must make decisions using information they can reasonably possess.

They may know:

- Their household inventory.
- Their available money.
- Their goals.
- Their skills.
- Their obligations.
- Prices they have observed.
- Nearby opportunities.
- Information learned through existing relationships and communication.

They must not know future harvest results, future prices, or distant inventory quantities without a legitimate information source.

Villagers may make mistakes.

They may misunderstand market conditions.

They may overestimate a harvest.

They may buy livestock they cannot afford to feed.

They may save too aggressively.

They may abandon a promising opportunity.

They may prioritize personal goals over immediate economic efficiency.

These are legitimate behaviors if they emerge from the simulation rather than broken logic.

---

16. PLAYER–VILLAGER PARITY

All new mechanics must comply with PAR-00 through PAR-05.

The player must be able to participate in the same underlying systems.

The player may:

- Rent agricultural land.
- Grow crops.
- Keep livestock.
- Hunt and gather.
- Operate a market stall.
- Sell surplus goods.
- Pursue multiple income sources.
- Save toward housing or other goals.

NPCs must use the same mechanics.

The player chooses actions manually.

NPCs choose through their AI.

Neither receives free resources, skill levels, special production advantages, or different economic accounting because of their classification.

---

17. REQUIRED TESTING

Create deterministic tests covering the relevant implemented systems.

At minimum, plan for:

1. One villager's annual food consumption.
2. Productive land required per villager.
3. Crop planting, growth, and harvest.
4. Seed retention and consumption.
5. Failed harvests.
6. Nonfarmers growing food.
7. Land rental and rent payments.
8. Livestock acquisition, care, reproduction, and production.
9. Nonhunters hunting for food.
10. Hunting pressure affecting wildlife populations.
11. Households buying food when it is economically attractive.
12. Households producing food when market prices rise.
13. Households producing food despite low prices because of personal goals.
14. Villagers saving money toward housing.
15. Villagers choosing paid work over self-production.
16. Villagers maintaining multiple income streams.
17. Households selling surplus goods.
18. Market stalls transferring real goods and coins.
19. Villagers retaining food or seed instead of selling everything.
20. Individual villagers making different choices under similar market conditions.
21. Financial reserves responding to household production and goals.
22. Activities awarding experience outside the villager's primary occupation.
23. No simultaneous impossible labor allocation.
24. No unexplained creation or destruction of goods or coins.
25. Player and NPC participation through the same underlying systems.

Measure annual production, consumption, imports, exports, spoilage, household food security, land use, market participation, and economic outcomes wherever supported.

Preserve deterministic behavior.

---

18. BUILD 16 SCOPE AND DEVELOPMENT SEQUENCING

Do not assume every feature described here belongs in Build 16.

The existing Build 16 parity work and dynamic reserve are reportedly complete, with 27 test suites passing.

Preserve that progress.

Continue the current post-parity simulations and starvation investigations.

First audit existing food-production and economic systems.

Then classify the findings into:

A. Existing functionality: Already implemented and working.

B. Defects: Existing promised behavior that is broken and should be repaired.

C. Build 16 foundations: Small, necessary improvements that can be safely integrated without destabilizing the current release.

D. Future living-economy features: Larger systems requiring their own implementation milestones and testing.

Do not disguise new feature development as a bug fix.

Do not rush a complete agriculture, husbandry, land-rental, or market-stall system into Build 16 merely because it appears in this directive.

The larger interconnected economy should be planned as a coherent subsequent build where necessary.

Preserve baseline simulation results before introducing changes that materially alter village behavior.

Continue other approved development while the audit and design work proceed.

Commit and push work to the appropriate remote GitHub staging branch.

Do not merge or publish a new build without owner approval.

---

19. REQUIRED DELIVERABLES

Provide:

1. Current-system audit: What actually exists, with code references and evidence.

2. Food sustainability calculation: How much food and productive land are required to sustain one villager, one household, and the village.

3. Gap analysis: Missing agriculture, husbandry, hunting, rental, commerce, and AI behavior.

4. Cross-system dependency map: How these features connect to skills, inventory, land, households, markets, labor, wildlife, and financial planning.

5. Implementation roadmap: Which work belongs in Build 16 and which belongs in the dedicated living-economy build.

6. Testing strategy: How we will establish that the systems operate correctly and that economic consequences emerge naturally.

7. Unresolved design questions: Only those genuinely requiring owner decisions. Do not ask questions already answered in this directive.

Do not claim a feature is implemented simply because it is documented.

Do not claim a test passed unless it actually ran.

---

20. REQUIRED ACKNOWLEDGMENT

Claude, acknowledge the following explicitly before proceeding:

I understand that villagers must not be programmed to follow identical economic behavior based only on market prices.

I understand that immediate needs, long-term goals, personal preferences, available resources, skills, relationships, local knowledge, and opportunity costs must all influence their decisions.

I understand that a villager saving for a house may choose to grow food, hunt, raise animals, and sell surplus goods specifically to preserve money, even when food is relatively inexpensive.

I understand that another villager may choose to work for income and purchase food instead, and that both choices can be valid.

I understand that villagers may maintain gardens, livestock, market stalls, and multiple income streams without changing their primary occupation.

I understand that these activities require real time, labor, resources, and economic transactions.

I understand that no outcome is guaranteed and that legitimate shortages, poverty, business failures, and starvation must remain possible.

I understand that the player and villagers operate under the same world rules.

I will audit existing functionality before implementing new systems, preserve Build 16 progress, and organize substantial new features into the appropriate subsequent build.

Record this directive in the repository's authoritative design documentation, identify its dependencies, and continue approved development.

FINAL GOVERNING PRINCIPLE

We are not creating villagers who simply buy food when it is cheap and grow food when it is expensive.

We are creating people who have needs, ambitions, responsibilities, preferences, opportunities, and limited resources.

They make decisions about how to spend their time, earn their living, feed their families, and pursue their goals.

Those individual decisions collectively create the economy of My Medieval Life.
