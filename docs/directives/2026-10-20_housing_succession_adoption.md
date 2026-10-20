# Owner directive, 2026-10-20: autonomous housing decisions, household succession and informal adoption

Saved verbatim from the owner's message (register HOUSE-01..08, FAM-01..08; EQ-07).

---

MY MEDIEVAL LIFE — MASTER DIRECTIVE

Autonomous Housing Decisions, Household Succession, and Informal Adoption

Claude,

I want to clarify how housing decisions should work in My Medieval Life and introduce the related rules for household succession and orphan care.

These systems are connected, but they are not the same development task.

The immediate priority is resolving EQ-07, the housing construction bottleneck in Build 15. Household succession and adoption are additional permanent design requirements that should be documented, evaluated against existing systems, and implemented in the appropriate development scope.

Do not allow the additional family mechanics to delay the housing fix or ongoing long-duration simulations.

---

PART 1 — AUTONOMOUS HOUSING DECISIONS

1. Fundamental design principle

This is a medieval life simulation.

A house should not automatically appear because a household has sufficient money, nor should the village act as a central authority that decides when every family receives a home.

The responsible adult in a household must recognize a housing need, decide to address it, and autonomously work toward building a house.

The simulation should model the decisions and work required to accomplish that goal.

2. Recognizing the need for a house

A household should evaluate its living conditions and circumstances.

Examples of reasons to seek housing include:

- A household becoming overcrowded.
- A newly married couple establishing its own household.
- An adult leaving the family home to establish an independent household.
- A household having no suitable permanent residence.
- A family requiring a replacement home.

Housing need should arise from actual circumstances, not arbitrary construction quotas.

Not every additional person requires a new house. Multiple generations and extended families may share a household.

Before initiating a construction project, determine whether the NPC actually needs an independent residence or already belongs to an existing household.

3. Who makes the decision?

The household's responsible adult makes the decision.

For a household with a father acting as its head, he would ordinarily make the decision.

If the father dies and the mother survives, she assumes responsibility. The reverse also applies.

Other independent adults may manage their own households.

Gender and physical strength must not restrict an NPC's ability to decide to build or personally perform construction.

We are not introducing arbitrary strength-based restrictions simply because the setting is medieval.

The important considerations are available resources, time, competing needs, and any existing skills or construction requirements.

4. A construction goal begins before the household can afford it

This is especially important.

A household should not need enough money to purchase every material before deciding that it needs a house.

Instead, recognizing the housing need creates a persistent goal.

The NPC should evaluate:

- What kind of house can be built using existing supported construction recipes?
- What materials are required?
- Which materials are already available?
- Which materials can be gathered or produced?
- Which materials must be purchased or traded for?
- How much money is required?
- What work can the household perform itself?
- Whether outside assistance would be useful.

A household that cannot afford a house today should still be capable of working toward one.

5. Obtaining money and materials

The responsible adult should pursue the housing goal through available economic and resource systems.

Possible actions include:

- Working to earn money.
- Saving money instead of spending it on lower-priority purchases.
- Purchasing construction materials.
- Gathering available timber, stone, and other resources.
- Producing materials through existing crafting or industrial systems.
- Trading goods or labor for supplies.
- Using materials already owned by the household.
- Obtaining help from relatives, neighbors, or other villagers.

These approaches are not mutually exclusive.

A villager may gather timber, purchase nails, trade for stone, and perform the construction personally.

The simulation should use existing resources and production chains rather than inventing free supplies.

6. Performing the construction

The household must be able to perform actual construction work.

A father, mother, or other responsible adult may build the house personally.

Other household members may contribute when appropriate.

The household may also obtain outside labor if it chooses.

Construction should:

- Consume actual materials.
- Require actual work.
- Take simulation time.
- Progress as materials and labor become available.
- Preserve unfinished progress.
- Allow interruptions for survival needs and other responsibilities.
- Resume when the household can continue.

The household should not abandon feeding itself or meeting essential survival needs merely to complete a building project.

Likewise, a temporary shortage of money or materials should not permanently erase the construction goal.

7. Avoid construction deadlocks

A household should not remain permanently stuck because it cannot obtain one resource or because its initial plan becomes impractical.

Investigate whether the existing system allows the household to reconsider its approach.

For example, it might save money, obtain supplies through trade, or use another existing house recipe if that recipe is genuinely available.

Do not invent new building types or bypass resource requirements just to force successful construction.

The objective is believable autonomous behavior, not guaranteed housing regardless of circumstances.

---

PART 2 — BUILD 15 INVESTIGATION: EQ-07

The latest two completed 100-day simulations reported:

Metric| Seed 1| Seed 2
Final population| 118| 133
Starvation| 0| 0
Wild animals| 81| 74
Currency leaks| 0| 0
Houses built| 1| 1

In seed 2, three crowded households reportedly had enough money to afford a house, yet only one house was constructed during the entire simulation.

That suggests we need to inspect the complete construction decision and execution chain.

Required investigation

Trace a household from recognizing overcrowding through completing a home.

Determine:

1. Whether the household recognizes that it needs housing.
2. Whether an appropriate household decision-maker exists.
3. Whether a persistent construction goal is created.
4. Whether the goal is blocked by an unnecessary full-payment requirement.
5. Whether materials are reserved, purchased, gathered, or otherwise acquired.
6. Whether the household schedules construction labor.
7. Whether construction tasks are reachable and executable.
8. Whether competing AI priorities prevent progress.
9. Whether construction pauses and resumes correctly.
10. Whether houses can actually be completed and occupied.

Identify the specific root causes behind the one-house-per-100-days outcome.

Do not merely increase construction speed, inject money, spawn materials, or artificially create houses to make the metric look better.

Fix the decision or execution failures responsible for the bottleneck.

Add tests demonstrating that households with a legitimate housing need can establish a goal, acquire resources over time, and complete construction when the necessary resources and labor are genuinely available.

A valid outcome is not necessarily that every household gets a house. A valid outcome is that the household makes sensible progress and that failures have understandable causes.

---

PART 3 — HOUSEHOLD SUCCESSION

This is a separate but related permanent design requirement.

A household must continue functioning when one of its parents dies.

1. One parent dies

If the father dies and the mother survives, the mother assumes responsibility for the dependent children and household decisions.

If the mother dies and the father survives, the father retains or assumes that responsibility.

The surviving parent can:

- Manage household resources.
- Earn and spend money.
- Obtain food and other necessities.
- Decide whether housing is needed.
- Gather or purchase construction materials.
- Build a house personally.
- Manage the household's ongoing responsibilities.

The death of one parent must not make the household incapable of functioning.

2. Both parents die

If both parents die and dependent children remain, the children should not automatically establish independent households or initiate new construction projects.

Instead, the simulation should find an existing household to care for them.

The order of priority is defined below.

---

PART 4 — FAMILY REUNIFICATION AND INFORMAL ADOPTION

1. No formal adoption system

There is no adoption agency, court process, government approval, or formal adoption ceremony.

In this game, adoption simply means that another household takes a child in and raises that child.

Do not invent an administrative adoption system.

2. Priority order for dependent children

When both parents are dead, search for a suitable home in this order.

Priority 1: Living grandparents

Search both sides of the family.

If an eligible grandparent household exists, the children move into that household.

Priority 2: Nearest living blood relative

If no eligible grandparents exist, search the family tree for the nearest eligible blood relative.

Examples include adult siblings, aunts, uncles, cousins, and other relatives.

Use the actual genealogical relationships to determine closeness.

Do not randomly choose a distant relative while a closer eligible relative exists.

Priority 3: Another villager

If no eligible blood relatives exist, another villager's household may take the children in.

There is no requirement for a married couple or a special set of adoptive parents. The receiving household simply needs an appropriate responsible adult who can care for the children.

3. Household integration

Once the child moves into the receiving household:

- The child becomes a dependent member of that household.
- The receiving household assumes responsibility for the child's needs.
- The child uses the household's existing housing.
- The child does not independently initiate a house-building goal.
- Existing biological relationships remain preserved in genealogy.
- The child may take the receiving family's surname when appropriate.
- The child's original identity and parentage must not be erased.

A surname change must not overwrite or corrupt the underlying family tree.

4. Housing consequences

Taking in orphaned children can increase household occupancy.

That may eventually create a legitimate need for a larger or additional home.

However, the decision to build belongs to the receiving household's responsible adult, not to the dependent children.

The normal autonomous housing process then applies.

Do not automatically construct a house when adoption occurs.

5. Unresolved edge cases

If no eligible household is immediately available, do not delete the child, invent a family, or silently force an invalid placement.

Preserve the child's state and identify what temporary-care behavior the existing simulation can support.

If a new mechanic or owner decision is required, register it explicitly rather than guessing.

Likewise, preserve any unresolved questions about how to choose between equally close relatives.

---

PART 5 — IMPLEMENTATION BOUNDARIES

Immediate Build 15 priority

Resolve EQ-07 and the autonomous housing decision and construction workflow.

Implement the smallest technically sound changes necessary to make the existing housing system function according to these rules.

Family succession and adoption

Inspect the existing mortality, household, genealogy, kinship, and adoption code.

Determine which parts already exist, which are incomplete, and which are entirely missing.

Document the complete approved design in the authoritative World Design Rules and requirements register.

Implement straightforward corrections where they are necessary for Build 15 housing correctness and can be safely tested.

Assign larger family succession or adoption work to an appropriate later build if it would otherwise threaten Build 15 stabilization.

Do not automatically place the entire new family system in Build 15.

Do not close an item simply because the design has been documented.

Integration requirements

The systems must eventually work together:

- Mortality changes household leadership.
- Household leadership determines who makes decisions.
- Family relationships determine where dependent orphans go.
- Household membership determines occupancy.
- Occupancy influences housing need.
- Housing need creates autonomous construction goals.
- Construction goals drive economic and labor decisions.

Avoid disconnected shortcuts that produce contradictory household states.

---

PART 6 — VERIFICATION

Add or update tests covering the relevant implemented functionality.

Housing scenarios should include:

- A household recognizes overcrowding.
- A household begins saving for a house without having the full purchase price.
- A household gathers some materials and purchases others.
- A mother can independently initiate and complete construction.
- Construction resumes after a temporary shortage.
- Survival needs appropriately interrupt construction.
- Construction does not generate free materials.

Family scenarios should include, when those mechanics are implemented:

- Father dies; mother remains responsible.
- Mother dies; father remains responsible.
- Both parents die; grandparents take in the children.
- No grandparents; nearest eligible blood relative takes them in.
- No relatives; another villager takes them in.
- Biological genealogy survives household transfers and surname changes.
- Dependent orphans do not independently demand or construct homes.
- Receiving households correctly recalculate occupancy and housing needs.

Use tests appropriate to the actual implementation stage. Do not claim future family mechanics are verified merely because the housing tests pass.

Continue the ongoing 365-day simulations, and rerun affected housing simulations after implementing EQ-07 changes.

Clearly distinguish old simulation results from results generated using the corrected code.

---

PART 7 — PROJECT MEMORY AND DEVELOPMENT CONTINUITY

Record these decisions in the existing permanent project memory system.

Update the relevant:

- World Design Rules.
- Requirements register.
- Development ledger.
- Current development handoff.
- Build roadmap, where new requirements need assignments.

Preserve the distinction between approved design, implemented code, and verified behavior.

Do not create unnecessary duplicate documents.

Continue approved development, testing, and commits to the remote GitHub staging branch.

Do not publish a new distributable build outside the existing release gates.

---

REQUIRED RESPONSE

Before or alongside implementation, report:

1. What currently causes EQ-07 to produce only one house per 100 days.
2. Which housing decision and construction mechanics already exist.
3. What specific Build 15 corrections you are making.
4. Which household succession and adoption mechanics already exist.
5. Which new family requirements are documented for later work.
6. Any genuine design decisions requiring owner input.
7. How you will verify the housing fix.
8. The GitHub branch and commits containing the changes.

Final governing principle:

My Medieval Life is about people living autonomous lives.

A villager who needs a house should recognize that need, decide to do something about it, and work toward making it happen.

A family that loses a parent should continue under the surviving parent.

Children who lose both parents should first go to grandparents, then the nearest eligible blood relative, and finally another villager's household.

These are connected consequences of the same living world, but housing construction and family succession must remain separately tracked development responsibilities.

Fix the housing bottleneck first. Preserve the family rules permanently. Do not let scope expansion derail Build 15.
