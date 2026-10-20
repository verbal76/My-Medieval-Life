# Owner directive, 2026-10-20: final development mandate (Build 15 closure, living-world philosophy, sequential builds)

Saved verbatim from the owner's message. It supersedes previous Build 15 closure instructions wherever they conflict
(register OVN-02; the design principle is WDR-020). All other approved requirements, owner decisions, engineering
authority, testing standards and roadmap requirements remain in force.

---

MY MEDIEVAL LIFE

FINAL DEVELOPMENT MANDATE

Build 15 Closure, Living-World Philosophy, Autonomous Development and Sequential Build Progression

TO: Main Development Session

Claude,

This is my final clarification regarding Build 15, economic equilibrium, release readiness, and the development philosophy of My Medieval Life.

This directive supersedes previous Build 15 closure instructions wherever they conflict. All other approved game-design requirements, owner decisions, engineering authority, testing standards, and roadmap requirements remain in force.

Do not interrupt any simulations or tests currently running.

I want you to complete Build 15, release it when its mandatory requirements are satisfied, and continue autonomously through Builds 16, 17, and 18 in their approved order.

But first, I want to establish a fundamental distinction that must govern the entire game's development.

---

1. THE FUNDAMENTAL DESIGN PRINCIPLE

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

My Medieval Life is not intended to produce a perfectly balanced, permanently prosperous village.

It is intended to simulate an autonomous medieval society in which individuals, households, businesses, institutions, and settlements make decisions based on their circumstances.

Those decisions must have real consequences.

A village may:

- Prosper and expand.
- Remain economically stable.
- Experience shortages.
- Accumulate wealth unevenly.
- Suffer unemployment.
- Fall into debt.
- Lose essential trades.
- Experience declining population.
- Recover through trade, adaptation, and investment.
- Stagnate for generations.
- Collapse entirely.

These are potentially legitimate simulation outcomes.

Do not automatically correct a struggling village simply because its economic statistics look unfavorable.

The purpose of the simulation is not to guarantee success.

The purpose is to make success, failure, and recovery possible through functioning systems.

---

2. DISTINGUISH BROKEN MECHANICS FROM LEGITIMATE OUTCOMES

This distinction is mandatory for all future testing and development.

A broken mechanic requires correction

Examples include:

- A blacksmith fails to purchase affordable, available iron because the purchasing logic never executes.
- A woodcutter cannot obtain an available axe because tool-replacement logic is broken.
- A household abandons construction because its persistent housing goal is lost.
- A villager references a nonexistent home and generates script errors.
- Currency or materials appear or disappear without a valid transaction.
- An NPC cannot change jobs despite satisfying the approved conditions.
- A construction project cannot progress because valid materials or labor are incorrectly rejected.
- A caravan fails to complete a transaction that the approved rules permit.
- A valid save cannot restore essential simulation state.
- An NPC enters a permanent invalid decision loop.

These are implementation defects.

Fix them, add regression tests, and preserve the intended gameplay behavior.

A legitimate outcome does not automatically require correction

Examples include:

- A blacksmith is genuinely bankrupt.
- A woodcutter cannot afford an axe.
- A merchant refuses an unprofitable transaction.
- A family cannot afford to finish its house.
- The manor refuses a loan.
- A business closes.
- A village experiences high unemployment.
- Bandits accumulate significant wealth.
- A settlement loses population.
- Construction slows because materials are expensive.
- Villagers choose occupations that turn out to be unsuccessful.

These conditions may result from legitimate gameplay.

Do not classify them as bugs merely because they produce unfavorable statistics.

Investigate whether the underlying systems function correctly.

If they do, preserve the outcome.

Unfavorable results are not proof of defective code.

---

3. ECONOMIC BALANCE IS NOT ECONOMIC EQUALITY

I do not require every village to reach the same population, employment rate, wealth distribution, or construction output.

Two simulations using different seeds should be allowed to develop differently.

One settlement might construct ten houses while another constructs two.

One manor might invest heavily in local industry while another hoards its treasury.

One village might recover from a shortage while another enters a prolonged decline.

This variation is desirable when it emerges from valid mechanics.

Do not introduce hidden subsidies, free tools, fabricated materials, guaranteed buyers, artificial employment, or automatic wealth redistribution to force economic convergence.

The existing finite-resource and accounting requirements remain mandatory.

Every coin must have a legitimate source, owner, and transfer.

Every item must have a legitimate production, import, ownership, consumption, or destruction history.

---

4. NPCS AND INSTITUTIONS MUST RESPOND TO THEIR CIRCUMSTANCES

Autonomy does not mean every NPC makes the correct decision.

It means NPCs can make decisions using the information, opportunities, resources, capabilities, and motivations available to them.

A struggling blacksmith may seek financing, change suppliers, sell equipment, change occupations, or fail.

A family may save for a house, borrow money, postpone construction, or remain crowded.

A manor may commission tools, provide loans, purchase supplies, invest in infrastructure, or decline to intervene.

Bandits may spend their wealth, trade, retain it, lose it, or have it recovered through legitimate gameplay.

Caravans may buy local surplus when actual trade conditions justify the purchase.

These possibilities must follow approved game rules.

Do not create an invisible central authority that automatically rescues the economy.

Do not require every NPC to behave optimally.

Do not override legitimate individual decisions merely to improve simulation metrics.

Where the design of a new decision-making behavior has not been approved, record an owner decision rather than inventing a new gameplay rule.

The future NPC Judgment System must remain consistent with this philosophy.

---

5. BUILD 15 — FINAL CLOSURE STANDARD

Build 15 is a stabilization milestone.

Its purpose is to establish that the approved foundational systems function correctly.

It is not intended to guarantee permanent economic equilibrium.

The OD-16 work is reportedly staged at "3e326fd", with test suites passing and year-long simulations underway.

Allow those simulations to finish.

Evaluate the results against the existing mandatory Build 15 release requirements.

Specifically, determine whether:

1. The game initializes and runs without release-blocking script errors.
2. Required gameplay systems execute their intended functions.
3. Essential NPC decisions and actions operate according to approved rules.
4. Currency and resource accounting remain valid.
5. Save/load behavior preserves essential world state.
6. Construction, trade, employment, tool acquisition, and household systems function when their legitimate prerequisites are satisfied.
7. Economic transactions do not create unexplained resources or money.
8. The test suites and applicable release gates pass.
9. Known noncritical issues are documented.
10. The required build artifacts are successfully produced and validated.

These criteria supplement, rather than replace, the previously approved ten-condition release gate.

Do not add a requirement that the village must be prosperous, growing, fully employed, or economically equal.

A village that legitimately declines can pass Build 15.

A village that appears prosperous while silently generating script errors or resources cannot.

---

6. INTERPRETING THE CURRENT YEAR-LONG SIMULATIONS

When the current seed 1 and seed 2 simulations finish, review their results.

Investigate:

- Script errors.
- Resource and currency integrity.
- Invalid world states.
- Broken purchasing or production behavior.
- Permanently blocked actions.
- Save/load failures.
- Essential system execution.

Also record population, employment, housing, construction, industry, wildlife, trade, and wealth distribution.

However, these economic statistics are observations, not automatic pass/fail thresholds unless an existing approved requirement explicitly establishes one.

For example:

Two houses completed instead of six is not automatically a failure.

Determine why.

If builders cannot finish because a valid gameplay action is broken, correct it.

If they cannot finish because of legitimate debt, shortages, labor availability, or individual decisions, record the outcome and continue.

A village losing population is not automatically a failure.

Determine whether the decline follows valid aging, mortality, migration, resource constraints, and household rules.

If it does, preserve the outcome.

Do not keep rerunning 365-day simulations in pursuit of favorable statistics.

---

7. RELEASE BUILD 15 WHEN IT IS FUNCTIONALLY COMPLETE

If the current validation passes the mandatory gates:

1. Finalize the Build 15 readiness record.
2. Record the tested source commit.
3. Document known noncritical limitations.
4. Produce and validate the required game builds.
5. Publish Build 15 using the previously authorized private-draft release procedure.
6. Verify the release and artifacts.
7. Mark Build 15 complete.
8. Begin Build 16 immediately.

Do not insert additional discretionary optimization, balancing, cleanup, or new features between passing the release gates and publishing.

If a mandatory defect remains, fix that specific defect.

Use the shortest reliable reproduction and validation process appropriate to the failure.

Do not automatically begin another complete year-long testing cycle unless the approved gate requires it or the correction cannot otherwise be validated reliably.

A failed release gate must never be concealed or waived.

---

8. BUILD 16 — LONG-TERM EQUILIBRIUM AND ADAPTATION

Build 16 must implement its full approved requirements.

However, interpret equilibrium correctly.

Equilibrium means the world's systems can interact consistently over time, not that every settlement must become permanently stable or prosperous.

Build 16 should establish functioning long-term mechanisms for:

- Population and household change.
- Production and consumption.
- Employment and occupational transitions.
- Resource availability and depletion.
- Economic exchange and wealth circulation.
- Financial pressure and legitimate recovery opportunities.
- Construction and settlement needs.
- Social and family continuity.
- The remaining approved Build 16 systems.

Do not assume every shortage requires an automatic supply correction.

Do not assume every bankruptcy requires a bailout.

Do not assume every declining population requires intervention.

Ensure that NPCs and institutions can respond through approved mechanics.

Allow those responses to succeed or fail.

The equilibrium objective is mechanical consistency and meaningful adaptation, not guaranteed economic success.

---

9. BUILDS 17 AND 18 — NEW SYSTEMS WILL DISRUPT EXISTING CONDITIONS

Proceed sequentially:

Build 15 → Build 16 → Build 17 → Build 18

Build 17 introduces mining and industrial development.

Build 18 introduces settlement advancement and regional economic interactions.

These systems will change the existing economy.

Mining may create new employment, wealth, industries, shortages, and trade dependencies.

Settlement expansion may increase demand for housing, food, materials, and labor.

Regional trade may create prosperity in some locations and hardship in others.

These consequences are part of the simulation.

Do not continuously retune earlier systems to preserve a predetermined economic outcome whenever new mechanics are introduced.

Fix actual defects and implement approved adaptation mechanisms.

Allow the world to evolve.

Do not skip mandatory requirements or advance build labels prematurely.

---

10. AUTONOMOUS ENGINEERING AUTHORITY

You remain authorized to make routine engineering decisions independently.

You may:

- Diagnose and fix implementation defects.
- Select appropriate algorithms and architecture.
- Improve test coverage.
- Correct accounting and state-management errors.
- Configure CI.
- Optimize performance while preserving behavior.
- Commit and push validated work.
- Produce approved private releases.
- Continue independent development while tests run.
- Document and defer genuinely noncritical issues.

Do not repeatedly request my approval for routine technical implementation decisions.

However, changes to the intended game rules, major economic philosophy, NPC behavior requirements, or unresolved owner-design decisions still require my authorization.

Do not interpret this mandate as approval to invent unapproved mechanics.

---

11. AVOID PERPETUAL STABILIZATION

I do not want Build 15 to remain open indefinitely because each simulation exposes another economic condition that could be improved.

Use this decision rule:

Is the observed problem caused by a mechanic failing to perform its approved function?

If yes, it is a defect.

Fix it if it blocks the current release.

Is the observed problem a consequence of functioning mechanics interacting with finite resources and autonomous decisions?

If yes, it is a legitimate simulation outcome.

Record it and proceed.

Is the observed problem an opportunity for better economic adaptation or additional NPC behavior?

If yes, classify it as future development under the appropriate approved requirement or request an owner decision if needed.

Do not confuse these three categories.

Do not add unnecessary release blockers.

Do not weaken legitimate release blockers.

---

12. PERMANENT TESTING PHILOSOPHY

Future tests must distinguish between:

Mechanical correctness: The system performs its approved function.

Simulation integrity: State, resources, ownership, accounting, and saves remain valid.

Economic outcomes: The results produced by the interactions of those systems.

Mechanical correctness and simulation integrity are mandatory.

Economic outcomes should be measured and analyzed, but unfavorable results are not automatically defects.

Do not write tests that require arbitrary prosperity, identical village growth, or a fixed number of houses unless those outcomes are explicitly part of an approved requirement.

Preserve deterministic reproduction for a given seed and source revision.

Preserve valid randomness and meaningful differences between seeds.

---

13. RECORD THIS AS AN AUTHORITATIVE DESIGN PRINCIPLE

Save this mandate in the repository's authoritative design documentation and project memory.

Update the requirements and development guidance so future sessions understand:

The game must simulate a functioning world, not guarantee a successful world.

Preserve this principle through context compaction, session changes, and future builds.

Do not silently replace it with a requirement for universal prosperity or permanent equilibrium.

---

14. FINAL EXECUTION ORDER

Your next actions are:

1. Finish the currently running OD-16 year-long validation.
2. Classify any remaining findings as actual defects, legitimate outcomes, or future improvements.
3. Resolve mandatory Build 15 defects, if any.
4. Complete the existing release gates.
5. Publish the validated Build 15 private draft.
6. Begin and complete Build 16's approved requirements.
7. Begin and complete Build 17's approved requirements.
8. Proceed to Build 18.
9. Continue development autonomously without waiting for routine engineering approvals.

Preserve all work in GitHub and maintain accurate build status.

Do not claim a build is complete before its mandatory requirements and validation are satisfied.

Do not allow noncritical balancing concerns to prevent advancement.

---

FINAL OWNER MANDATE

I am not trying to create a medieval village that always wins.

I am trying to create a medieval world that lives.

Its people should work, trade, marry, raise families, build homes, struggle, prosper, make mistakes, adapt, and sometimes fail.

Its villages should grow, stagnate, decline, recover, or disappear as the consequences of the world around them.

I do not want the simulation secretly correcting every hardship.

I want the systems to function, the resources to be real, the decisions to have consequences, and the outcomes to emerge naturally.

Fix what is broken. Preserve what is legitimate. Balance what needs balancing without eliminating variation.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.

Finish Build 15 and move forward.

You have my authorization to proceed.
