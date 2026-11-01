# Owner directive 2026-11-01: Build 25 chapel economy correction

Verbatim, as received in the coordinating session on 2026-11-01. Register: X20-CHAPEL-FIX.

---

MY MEDIEVAL LIFE — BUILD 25 CHAPEL ECONOMY CORRECTION

Voluntary Donations, Alms Distribution, and Economic Circulation

Claude, the owner has reviewed the Build 25 economic simulation report and is establishing the following rules for the chapel economy.

Fundamental decision: A religious donation must be voluntary. The chapel has no authority to automatically take coins from villagers.

The current report shows the chapel accumulating approximately 75–85% of circulating coins while household cash declines dramatically. This is not acceptable as the normal long-term outcome of the chapel's collection and distribution mechanics.

We need to correct the underlying behavior, not manipulate the economic reporting.

1. Audit the existing implementation first

Inspect the actual source code governing:

- Weekly religious services.
- Piety thresholds.
- Chapel offerings.
- Donation amounts.
- Household financial reserves.
- Chapel treasury accounting.
- Clergy wages and expenses.
- Alms eligibility.
- Charitable distributions.
- Reputation or relationship consequences of donating or declining.

Identify exactly how coins are currently transferred.

Determine whether offerings are automatically deducted, whether villagers make an actual independent decision, and whether there are any penalties for declining.

Report the findings briefly, then implement the corrections below without waiting for routine approval.

2. Donations must be voluntary

Every eligible villager must make an individual decision about whether to contribute.

Piety may influence the probability of donating, but piety must never automatically trigger a payment.

A villager with high piety may decline.

A villager with low piety may occasionally contribute.

Donation decisions should account for:

- Personal piety.
- Available household cash.
- Food and essential supplies.
- Outstanding obligations.
- Expected near-term expenses.
- Household dependents.
- Existing personality and generosity traits, where available.
- Existing social and economic circumstances.

Use the game's established NPC decision-making framework rather than introducing an isolated random donation system.

Donation amounts must be variable and affordable.

No villager should donate coins required for reasonable household survival or essential obligations.

A villager with insufficient disposable resources should normally contribute nothing.

Declining a donation must not automatically cause a loss of piety, reputation, relationships, or social standing.

Do not introduce compulsory tithes, religious taxes, collection enforcement, or hidden deductions.

If a separate legitimate tax system exists elsewhere in the game, leave it separate from voluntary chapel donations.

3. Chapel spending and redistribution

The chapel should not function as a permanent sink that accumulates most of the village's money.

Preserve legitimate expenses such as clergy support and necessary chapel operations.

Implement a modest, economically justified operating reserve based on actual anticipated expenses rather than an arbitrary percentage of village wealth.

After legitimate expenses and the operating reserve are funded, surplus offerings should be distributed through charitable alms.

The owner's established principle is:

Offerings support the priest, and what remains goes to the poorest households.

Alms should consider genuine economic hardship, including:

- Available cash.
- Household wealth and usable resources.
- Dependents.
- Essential expenses.
- Food security.
- Ability to obtain necessities through trade.
- Other existing indicators of poverty.

Do not treat a household as financially secure merely because it has several days of food stored.

Likewise, do not automatically give money to a wealthy household simply because it temporarily has little cash.

Use the existing household and economy systems wherever possible.

Charitable distributions must be actual conserved transfers from the chapel treasury to recipient households.

No coins may be created, duplicated, destroyed, or transferred without a corresponding accounting entry.

4. Preserve believable NPC behavior

Do not force villagers to donate or force households to spend money immediately after receiving alms.

Villagers must retain their own economic agency.

Chapel donations should reflect individual beliefs and circumstances.

Alms should help households participate in the existing living economy without creating an artificial guaranteed income or unlimited financial support.

The chapel should remain financially capable of operating, but it must not systematically drain the village economy.

Do not hardcode the chapel's share of total coins to a predetermined number.

The economy must reach its outcomes through actual NPC decisions, transactions, expenses, and redistribution.

5. Instrument the chapel economy

Extend the existing economic reporting to measure:

- Number of villagers attending religious services.
- Number eligible to consider donating.
- Number choosing to donate.
- Number declining.
- Donation participation rate.
- Total donated coins.
- Average and median donation.
- Donations by household wealth bracket.
- Chapel operating expenses.
- Clergy wages.
- Operating reserve.
- Alms paid.
- Number of households receiving alms.
- Household cash and wealth before and after alms.
- Chapel treasury balance.
- Chapel share of total circulating coins.
- Household cash distribution over time.

Where practical, distinguish voluntary refusal from inability to afford a donation.

Do not invent measurements that the simulation does not record.

6. Validation

Use the established Build 25 economic simulation and conservation framework.

Compare the corrected implementation against the current Build 25 baseline using equivalent seeds and economic conditions.

Preserve the existing conservation requirements:

- Zero coin leaks.
- Zero holder mismatches.
- Zero item leaks.
- No duplication through donations or alms.
- Correct save/load behavior.
- Deterministic outcomes for identical seeds and inputs.

Measure whether the correction improves:

- Household purchasing power.
- Coin circulation.
- Chapel wealth concentration.
- Poverty relief.
- Market participation.
- Long-term economic sustainability.

Do not manipulate economic scores or inject coins to manufacture improvement.

Inspect results across the complete simulation period, not merely at the final checkpoint.

If the chapel still accumulates an excessive share of village wealth, identify the actual mechanism responsible before making further adjustments.

7. Scope and execution

This is a targeted correction to chapel economic behavior.

Do not redesign the entire religious system, government, taxation, or general economy.

Do not change unrelated NPC behavior.

Preserve established Build 25 functionality and save compatibility.

Reuse existing passing test evidence where applicable. Run targeted tests for changed systems, followed by the necessary economic simulations.

Avoid redundant full-suite runs.

Document the original behavior, the corrections, the exact code changes, and the measured before-and-after results.

Keep the recovery handoff updated.

8. Owner's final intent

Religion may influence generosity, but it does not authorize confiscation.

A donation is a choice, not a tax.

The chapel should support its clergy and provide meaningful assistance to the poor, not gradually absorb the community's money.

The corrected economy should emerge from believable individual decisions and conserved transactions.

Begin with the code audit, implement the corrections, and return the measured economic results and updated circulation charts. Do not stop for routine approvals.
