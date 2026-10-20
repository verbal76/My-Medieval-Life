# Owner follow-up, 2026-10-20: agricultural audit findings and implementation authorization

Saved verbatim. It supplements, and does not replace, the master food-security directive
(`docs/directives/2026-10-20_food_security_goal_driven_economy.md`, FSE-00). It answers the agent's report of four
agricultural gaps found on the seed-2 year run (village fields ignore seasons; village sowing uses no seed; village land
yields about a quarter of a player plot per cell; no land planning). Register: FSE-11 (seed consumption), FSE-12
(agricultural parity), FSE-13 (seasonal farming), FSE-14 (dynamic land planning), FSE-15 (recalculated land
requirement), FSE-16 (the per-death starvation report, with B7-015).

---

MY MEDIEVAL LIFE — BUILD 16

Owner Follow-Up: Agricultural Audit Findings and Implementation Authorization

Claude, I saw your seed-2 agricultural findings after sending the previous master food-economy directive.

This message supplements that directive. It does not replace it.

Register all four identified agricultural gaps as tracked Build 16 tasks. However, distinguish between fixing existing defects, developing foundational systems, and activating major economic changes.

1. Complete the starvation investigation first

Finish the seed-2 investigation into the 11 starvation deaths before materially changing agricultural production.

For each death, establish:

- Household food inventory and access to available food.
- Available coins and food prices.
- Whether the household qualified for manor relief.
- Whether relief was requested, available, and delivered.
- Whether the household had reasonable alternative food sources.
- Whether the NPC recognized and attempted those alternatives.
- Whether the death resulted from legitimate circumstances, poor judgment, or a broken mechanic.

Food existing somewhere in the village does not automatically mean a starving household could obtain it.

Likewise, being outside the manor's relief rules does not automatically constitute a defect.

Determine whether the simulation followed its established rules correctly.

Preserve the existing seed-2 annual baseline.

2. Seed consumption — approved for correction

Village farmers currently save seed but do not consume it when sowing.

Correct this through the existing inventory and agricultural systems.

Seeds must have a legitimate source and be consumed during planting.

Farmers must not sow without sufficient seed.

Seed reserves for future planting should influence household and farm decisions.

Maintain conservation accounting and add deterministic tests.

3. Agricultural parity — approved for development

The reported difference between village and player wheat yields violates our intended player–villager parity unless there is a legitimate, explicitly modeled reason.

Investigate why village fields yield approximately 0.35 wheat per cell per day while player plots yield approximately 1.5.

Determine whether this comes from different crop definitions, labor requirements, land abstractions, growth rules, or duplicated code.

Establish a shared underlying agricultural model for player and NPC farming.

Do not arbitrarily increase village yields or decrease player yields just to make the numbers match.

Use actual land, seed, time, labor, seasons, skills, and resources.

Test the economic consequences before activating changes that materially affect food supply.

4. Seasonal farming — approved for implementation and testing, not immediate baseline activation

Village farming must ultimately obey the same seasonal rules as player farming.

Winter should interrupt crop production where the agricultural model requires it.

Autumn and other seasons should affect production consistently.

This means villagers must be able to prepare for winter by storing food, planning production, purchasing supplies, hunting, raising animals, and using other legitimate survival strategies.

But do not immediately switch the live simulation to seasonal farming without understanding the consequences.

First preserve the current baseline.

Then implement and test the corrected seasonal model in isolation.

Compare annual food production, seasonal inventories, prices, household food access, starvation, and population outcomes.

Bring any major balance consequences back for owner review before activating the corrected seasonal model in the release baseline.

Do not create artificial winter food supplies or guaranteed rescues.

5. Dynamic land planning — approved for design and foundations

The six existing fields must not remain the permanent agricultural capacity of a growing village.

However, the answer is not to automatically create another field whenever population increases.

Land use must eventually emerge from household goals, farming businesses, market demand, land availability, labor, rental arrangements, and economic opportunities.

Villagers should be able to rent small plots for household food production or larger areas for commercial farming.

They should also be able to rent suitable land for livestock pens.

Land ownership, rental payments, production, and inventories must all be legitimate parts of the economy.

Some villagers will expand cultivation because food is expensive.

Others will do so because they want to save money for a house.

Others will specialize in their professions and buy food instead.

Some will produce food continuously because they prefer self-sufficiency.

These are individual economic decisions, not mandatory population-based production quotas.

Implement safe architectural foundations where appropriate. Schedule the larger land-rental and agricultural expansion for the dedicated living-economy build if it exceeds Build 16's reasonable scope.

6. Recalculate land requirements after parity corrections

Your current figures establish an important baseline:

- Six fields producing 43,920 wheat annually.
- Approximately 120 wheat produced per day.
- One adult consuming approximately 72 food points daily.
- Approximately 0.6 wheat per adult daily when converted into pottage.
- Approximately 220 wheat per adult annually.
- Approximately 38 adults supported per field under the existing model.

However, these estimates depend on year-round growth, current yields, and sowing without seed consumption.

Do not treat 1.7 field cells per adult as a permanent land requirement.

Recalculate productive capacity after implementing the corrected seed, seasonal, and agricultural parity rules.

Include actual labor availability and net edible yield after seed retention and losses.

7. Preserve the larger economic design

The previous master directive remains authoritative.

Villagers must make decisions based on their needs, goals, preferences, skills, resources, relationships, and local market conditions.

A villager saving for a house may grow food, hunt, keep livestock, and sell surplus to preserve money.

Another villager may buy food and earn more through their profession.

A household may maintain several sources of food and income.

Do not force every villager into the same economic strategy.

All activities must require actual time, labor, resources, and legitimate transactions.

Maintain player–villager parity and conservation of goods and coins.

8. Development workflow

Continue the current starvation investigation and approved Build 16 work.

Do not stop productive development while waiting for another owner response.

Document the four agricultural findings and their implementation dependencies.

Commit and push completed approved work to the remote GitHub staging branch.

Keep experimental seasonal and agricultural balance changes isolated until validated.

Do not merge, publish, or create a new distributable build without owner approval.

Required next report

When the seed-2 starvation investigation finishes, report:

1. The root cause of each of the 11 deaths.
2. Which deaths indicate defects and which are legitimate simulation outcomes.
3. The four agricultural tasks and their implementation status.
4. The impact of any completed seed or parity corrections.
5. What remains for the dedicated living-economy build.
6. Any major design decision that genuinely requires owner approval.

The governing objective remains unchanged: villagers must be capable of pursuing their own economic goals through real opportunities and resources, while the world remains free to produce genuine hardship, scarcity, and failure.

Proceed with the investigation and approved work without disrupting the existing simulation baseline.
