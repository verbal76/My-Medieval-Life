# Owner directive, 2026-10-21: Build 17 — REC-013 Final Owner Decisions

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

MY MEDIEVAL LIFE — BUILD 17
REC-013 FINAL OWNER DECISIONS
Manor Maintenance, Village Expansion, Logistics, Staffing and Job-Board Compensation
Repository: verbal76/My-Medieval-Life
Decision: REC-013 — All four owner questions answered
Scope: Record approved design, preserve Build 17 stability, and schedule substantial new systems appropriately.
1. OWNER AUTHORIZATION
I have answered all four outstanding REC-013 questions.
These are final owner-approved design decisions. They supersede conflicting provisional agent choices.
Update the authoritative requirements register, decision ledger, and relevant design documents.
Distinguish between:

* Owner-approved design.
* Functionality already implemented.
* Functionality requiring modification.
* Functionality scheduled for a later build.

Do not mark unfinished features as implemented merely because the decisions are approved.
REC-013 can be closed as an owner-decision item once the decisions are recorded. Any outstanding implementation must remain tracked separately.
Do not publish a new build or release without authorization.
2. REC-013 Q1 — REAL MAINTENANCE, VILLAGE EXPANSION AND ROAD CONSTRUCTION
OWNER DECISION: ADOPT REAL NEED-DRIVEN MAINTENANCE AND EXPAND THE SYSTEM TO SUPPORT SETTLEMENT GROWTH.
The manor must not generate artificial repair work merely because it has surplus treasury funds.
Instead, the reeve should identify actual village needs and create legitimate, funded work opportunities.
A. Structural deterioration and maintenance
Buildings and infrastructure must eventually experience wear and deterioration through time, use, and relevant environmental conditions.
Potentially affected structures include:

* Manor-owned buildings and houses.
* Wells and water infrastructure.
* Roads and paths.
* Fences and field boundaries.
* Pens and livestock structures.
* Other appropriate village infrastructure.

Deterioration should produce meaningful consequences, such as reduced effectiveness, reduced capacity, or eventual loss of function where appropriate.
When maintenance is necessary, the reeve may arrange a repair project.
Repairs require real materials, workers, time, and money.
Materials must be transported to the work location and consumed or incorporated through legitimate construction mechanics.
Do not allow materials to disappear from inventory without a corresponding recorded use.
Do not automatically restore structures when a treasury transaction occurs.
B. Village expansion
The reeve and manor should also recognize legitimate opportunities to expand the settlement.
Examples include:

* Housing shortages.
* Additional workshop capacity.
* Storage shortages.
* Agricultural expansion.
* Livestock facilities.
* New public infrastructure.
* Other buildings required by village growth.

Construction should be driven by actual settlement conditions, planned development, and available resources.
A well-funded manor may choose to invest in growth, but surplus money alone does not constitute a requirement to create meaningless work.
A construction project should have a defined purpose, location, material requirement, labor requirement, and funding source.
C. Roads to new locations and towns
Road construction must be part of the broader infrastructure and expansion system.
The manor should be able to commission roads connecting the village to:

* New resource locations.
* Farms and other outlying facilities.
* New settlement areas.
* Other villages and towns.
* Relevant trade destinations.

Roads must be actual infrastructure, not abstract connectivity granted by paying coins.
Depending on the existing terrain and construction systems, road development may require surveying, clearing, preparation, material transport, and labor.
A completed road should have meaningful effects on movement, accessibility, logistics, and trade where those systems support them.
Do not invent instant travel or teleportation.
Do not automatically generate new towns simply because a road is proposed. Respect the existing world-generation and regional settlement systems.
D. Work generation and project priority
The reeve should distinguish between:

1. Essential repairs and urgent infrastructure needs.
2. Routine maintenance.
3. Logistical work.
4. Necessary construction to support settlement growth.
5. Discretionary improvements and expansion.

Projects should respond to real conditions, priorities, resources, and funding.
The manor must be allowed to defer or cancel nonessential projects.
There is no guarantee that paid work will always be available.
E. Implementation scheduling
The broader structural wear, village expansion, and road-building systems are approved for a later build.
Do not force a major infrastructure rewrite into Build 17.
Preserve the existing Build 17 mine-support deterioration system.
Document the broader design and establish implementation dependencies.
Do not silently retain treasury-driven make-work as the approved long-term behavior.
3. REC-013 Q2 — FALLBACK FOR UNCLAIMED DELIVERIES
OWNER DECISION: USE AVAILABLE SALARIED MANOR STAFF AS A LOGISTICAL FALLBACK.
When a grain, relief, or other eligible manor delivery remains unclaimed for a reasonable period, the manor may assign the work to an available salaried manor hand or the reeve.
These workers do not receive an additional wage for duties already covered by their salary.
Requirements:

* A worker must actually be available.
* The goods must exist.
* Goods must be collected from their real location.
* Transport must respect carrying capacity and travel.
* The goods must arrive at the intended destination.
* The delivery must be recorded exactly once.
* Staff cannot simultaneously perform incompatible tasks.
* Assigned staff must respect their existing responsibilities and eligibility.

Do not teleport goods or instantly complete ordinary deliveries.
Urgent food relief
Preserve the existing protection for households facing immediate hunger.
Urgent relief must not be delayed merely because nobody accepted a public job-board posting.
Where existing code grants immediate relief, do not remove that protection without a safe replacement.
The long-term implementation should reconcile urgent relief with real inventories and physical logistics without introducing starvation through a transitional implementation error.
The exact fallback delay should be determined through the existing scheduling and urgency mechanics rather than inventing an arbitrary universal number.
4. REC-013 Q3 — SHARED JOB BOARD FOR MANOR HANDS
OWNER DECISION: RETAIN THE SHARED JOB BOARD.
Salaried manor hands remain eligible to take appropriate work from the same job board used by independent workers and the player.
They do not receive additional wages for work already covered by their salary.
Preserve legitimate job-specific eligibility restrictions.
Examples include specialist qualifications, work authorization, and existing exclusions where justified by the job's requirements.
Do not automatically make every manor hand eligible for every specialized task.
Do not give manor hands universal priority over independent workers.
Worker selection should respect availability, suitability, current responsibilities, and existing job-assignment mechanics.
A manor hand who is already performing an assigned duty must not be double-booked.
Idle salaried hands remain salaried according to existing employment rules.
The fallback-delivery requirement in Q2 should integrate with this shared scheduling system.
5. REC-013 Q4 — OFFERED COMPENSATION AND WORKER CHOICE
OWNER DECISION: REPLACE THE LONG-TERM FIXED-WAGE DESIGN WITH OFFERED COMPENSATION THAT WORKERS CAN ACCEPT OR REJECT.
The manor's job board should operate as a real labor marketplace.
Each funded job posting offers compensation.
Eligible workers evaluate whether the offered payment is worthwhile and decide whether to accept.
Compensation should respond to relevant economic circumstances, including:

* Labor availability.
* Competing work opportunities.
* Demand for workers.
* Job duration.
* Difficulty and required skills.
* Travel requirements where applicable.
* Market conditions.
* The manor's available funds.

These factors should influence offered compensation and worker willingness. Do not assume that every factor requires a new numerical subsystem.
A. Worker agency
Workers must not automatically accept every available job.
A worker may decline because the offered compensation is insufficient, another opportunity is better, or other needs take priority.
The manor may need to increase its offer to attract a worker.
A job may remain unfilled if no suitable worker is willing to accept its terms.
Do not guarantee employment or successful hiring.
B. Actual economic transactions
Before a job is funded, the manor must have a legitimate source of money.
Accepted compensation must be paid according to the agreed job terms and existing completion rules.
Preserve the previously approved principle that paid work quests are paid in full upon successful completion or not paid at all, unless a distinct existing contract type explicitly supports other terms.
Do not create currency to cover wages.
Do not pay the same compensation twice.
Do not automatically pay an additional job-board wage to salaried manor hands for ordinary salaried duties.
C. Relationship to existing systems
Integrate with the existing job board and labor systems rather than creating an isolated competing economy.
Preserve CON-01 negotiated procurement contracts as their own legitimate commercial arrangements.
Do not turn every job-board posting into a goods procurement contract.
The manor's posted work offers and negotiated commercial contracts may coexist.
Existing job-specific payment amounts may serve as provisional starting offers until the new compensation behavior is implemented.
However, the old fixed rates are not the final owner-approved compensation model.
Do not treat 2 coins per haul, 4 coins per repair, 6 coins per quarry task, or 6 coins per four-hour day as immutable universal wage rules.
D. Scope and scheduling
This decision establishes the approved design direction.
Evaluate the current job-board implementation and identify the smallest safe integration path.
Do not rewrite the entire labor economy merely to close REC-013.
If a full dynamic compensation implementation would destabilize Build 17, schedule it as an explicitly tracked later-build requirement.
Preserve existing functionality until its replacement is tested.
6. CORE SIMULATION CONSTRAINTS
All four REC-013 decisions must obey these principles:

* Workers have agency.
* Work arises from genuine needs or legitimate discretionary projects.
* No guaranteed employment.
* No invented treasury money.
* No invented construction materials.
* No teleportation of goods.
* No automatic project completion without required work.
* No duplicated wages.
* No duplicated goods.
* No worker double-booking.
* No arbitrary forced acceptance of work.
* Preserve deterministic simulation behavior.
* Preserve save compatibility.
* Integrate with existing economy, construction, NPC, and logistics systems.

A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
7. IMPLEMENTATION AND DOCUMENTATION INSTRUCTIONS

1. Update REC-013 and its four component decisions in the authoritative requirements register.
2. Record the owner's exact choices and their consequences.
3. Mark REC-013 as answered or closed using the repository's established status conventions.
4. Create or update separately tracked implementation requirements for functionality not yet built.
5. Preserve currently working Build 17 systems unless a narrowly scoped change is necessary and safe.
6. Identify dependencies with construction, structural decay, roads, village expansion, NPC labor, the reeve, the job board, and Expansion 18.
7. Do not duplicate existing systems.
8. Continue other approved development while future-build features remain scheduled.
9. Commit and push approved documentation and development work to the appropriate remote GitHub staging or WIP branch.
10. Reuse applicable passing tests and CI evidence. Run targeted checks only where changes require them.
11. Do not package, export, or publish a new playable build without my authorization.

8. REQUIRED COMPLETION REPORT
Provide a concise but complete report identifying:

* The final recorded decisions for REC-013 Q1 through Q4.
* Documents and requirements updated.
* Which functionality is already implemented.
* Which functionality remains to be developed.
* The planned build or dependency for each outstanding feature, without inventing an approved release date.
* Any contradictions with existing systems.
* Exact remote branch and commit.
* Whether REC-013 is formally closed.

Then retrieve the next unresolved owner question:
Quarry stone versus building blocks.
Present its original wording, source, current implementation, consequences of each option, and your recommendation.
Do not choose the answer for me.
Continue resolving owner decisions one question at a time.
