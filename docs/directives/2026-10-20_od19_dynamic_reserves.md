# Owner decision, 2026-10-20: OD-19, dynamic necessity-based financial reserves

Saved verbatim. Given in answer to the OD-19 question (the universal coin-reserve threshold; the first answer field was
"[No preference]" and the owner's decision came in the second, which had asked about the pickpocket's cry; that theft
question remains open as OD-20). Register: OD-19 (answered), PAR-02 (updated), PAR-02A (new).

---

MY MEDIEVAL LIFE — OD-19

Owner Decision: Dynamic Necessity-Based Financial Reserves

Claude, the owner rejects a fixed 15-coin trader reserve and a fixed 2-coin household reserve.

Replace arbitrary fixed reserves with dynamic, needs-based financial planning.

Every villager, including merchants, smiths, farmers, and other occupations, should evaluate the money required to meet their foreseeable necessities.

The reserve must reflect actual circumstances, not an arbitrary occupation-specific number.

1. Calculate foreseeable necessities

Evaluate relevant existing simulation data, including:

- Household food requirements.
- Food already available in storage.
- Number of household members and dependents.
- Upcoming rent or housing obligations, where implemented.
- Essential heating and fuel requirements.
- Medicine or other urgent necessities.
- Existing debts or obligations, where supported.
- Expected income and when it can reasonably be obtained.
- Available resources that reduce the need to purchase necessities.

Do not invent expenses or economic systems that do not currently exist. Structure the calculation so additional real obligations can be incorporated as those systems are developed.

Avoid double-counting resources or obligations.

2. Calculate a dynamic reserve

Determine how much money the household reasonably needs to retain to meet its foreseeable necessities.

This value should change as circumstances change.

A household with abundant stored food may need less money reserved for food.

A household facing an imminent shortage may need more.

A merchant with substantial available resources and no immediate obligations may have a low reserve or none.

Do not hardcode a universal 15-coin or 2-coin minimum.

Do not substitute another arbitrary universal reserve.

3. Distinguish necessities from discretionary spending

The reserve is intended to protect essential needs, not prevent the household from satisfying them.

A villager should be able to spend reserved funds on the necessities for which those funds are being protected.

Examples include food, necessary fuel, medicine, and due obligations.

Purchasing additional inventory for resale, luxury goods, or nonessential materials should be evaluated against the household's remaining financial needs.

Business purchases may still be economically justified when necessary to generate income. Evaluate those decisions according to the agent's circumstances and available information rather than applying an unconditional prohibition.

4. Preserve individual decision-making

The reserve is part of an agent's financial judgment, not a magical restriction imposed by the game world.

An NPC may decide to take a financial risk, accept hardship, or prioritize another urgent need when its existing decision-making rules support that choice.

Such decisions must have real consequences.

Do not secretly prevent poverty, hunger, insolvency, or business failure.

A village is allowed to fail. The simulation is not.

5. Player–villager parity

Use the same underlying financial information and calculations for the player and NPC villagers.

NPC AI uses the calculation to guide spending decisions.

The human player remains free to decide how to spend their own money.

Do not create a player-specific transaction rule that changes prices, available money, or economic accounting.

The difference is decision-making control, not different world rules.

6. Local knowledge and realistic planning

Villagers must not have perfect knowledge of future events.

Calculate reserves using information they can reasonably know, such as their stored food, household needs, known prices, obligations, and anticipated income.

Do not grant NPCs advance knowledge of future harvests, deaths, price changes, or economic disruptions.

A villager may misjudge future needs.

7. Implementation and testing

Replace the current fixed reserve logic with a shared necessity-planning calculation and NPC spending policy.

Test at least these scenarios:

- A well-stocked household with few expenses.
- A household with dependents and little food.
- A merchant with substantial inventory but limited cash.
- A household with an upcoming obligation.
- A villager buying essential food using reserved money.
- A villager deciding whether to buy discretionary goods.
- A villager whose expected income fails to arrive.
- Player and NPC transactions following identical accounting rules.
- Changing household needs producing changing reserve recommendations.

Preserve deterministic behavior, economic conservation, and save compatibility.

Do not add hidden rescue mechanisms.

Record this as the definitive OD-19 decision and update PAR-02 accordingly.

Continue approved development, testing, commits, and remote GitHub staging. Do not publish a build or merge without authorization.

Required acknowledgment: Confirm that the reserve is a dynamic assessment of foreseeable necessities, not a fixed coin threshold, and that it guides NPC decisions without artificially preventing legitimate economic failure.
