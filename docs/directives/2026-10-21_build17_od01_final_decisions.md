# Owner directive, 2026-10-21: Build 17 — OD-01 Final Owner Decisions

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

MY MEDIEVAL LIFE — BUILD 17
OD-01 FINAL OWNER DECISIONS
Mining Sustainability, Resource Ownership, Prospecting, Regional Trade and Mine-Shift Quest
Repository: verbal76/My-Medieval-Life
Workstream: Build 17
Decision: OD-01 fully answered
Authorization: Update the authoritative decision and requirements records. Implement only the necessary Build 17 changes. Do not publish a release.
1. OWNER DIRECTIVE
I have answered every outstanding component of OD-01.
Record these as final owner-approved decisions, not provisional agent recommendations.
Close OD-01 once its six decisions are accurately recorded.
Do not reopen these questions unless an actual contradiction or new requirement is discovered.
Preserve existing Build 17 functionality except where a decision explicitly requires a change.
2. MINE-SHIFT QUEST — RETIRE
OWNER DECISION: RETIRE THE QUEST.
Remove the fixed-reward quest titled "A shift in the mine," which currently pays 8 coins for delivering 6 iron ore.
Independent miners should instead earn income by selling their extracted goods at negotiated market prices or fulfilling negotiated procurement contracts.
Use the existing CON-01 system where applicable.
Do not replace the retired quest with a different hard-coded mining wage.
Do not automatically pay miners merely because they extracted ore.
Preserve unrelated job-board activities, including legitimate paid excavation, surveying, quarrying, and construction jobs.
Ensure the retired quest cannot continue appearing as a newly offered job.
Handle any existing saved or active instances safely without corrupting saves or duplicating payments.
3. P1.1 — REJECT MANDATORY DEMAND-DRIVEN MINING
OWNER DECISION: REJECT.
Independent miners decide whether to mine based on their own needs, inventory, expected sales, and economic opportunities.
Do not require an existing buyer order before mining can begin.
Do not automatically force miners into day labor after two days without orders.
Miners may reasonably extract and retain goods in anticipation of future sales.
Their decisions should still respond to actual market conditions, available storage, labor opportunities, and resource scarcity.
Preserve NPC agency.
This is not authorization for miners to extract unlimited resources without considering their economic circumstances.
4. P1.2 — REJECT AUTOMATIC MANOR MINING RIGHTS
OWNER DECISION: REJECT.
The manor does not automatically own all mineral deposits.
Do not introduce the proposed universal 10% mining royalty.
Do not impose universal manor-controlled mining quotas.
Do not create a mandatory 60-stone reserve.
Do not apply automatic export restrictions based on that rejected reserve.
Independent miners may work resources according to the game's legitimate ownership and access rules.
Specific ownership rights and voluntary negotiated agreements may still apply where supported.
The manor may purchase resources, hire workers, or operate resources it legitimately controls.
Do not confuse legitimate ownership or contractual rights with automatic ownership of every deposit.
5. P1.3 — ASSIGN REGIONAL CARAVAN MARKETS TO EXPANSION 18
OWNER DECISION: EXPANSION 18 OWNS THIS WORK.
Finite regional markets, caravan purchasing capacity, regional supply and demand, and changing regional prices belong to Expansion 18.
Do not implement a competing caravan economy in Build 17.
Preserve the existing Build 17 caravan behavior unless another previously approved Build 17 requirement specifically changes it.
Do not import unfinished Expansion 18 systems into Build 17.
The eventual integration must use actual regional inventories, economic transactions, and conserved resources.
Do not treat this decision as approval of the original P1.3 numerical settings, including its proposed 5% price change per visit.
6. P1.4 — SUPERSEDED BY BUILD 17 PROSPECTING
OWNER DECISION: SUPERSEDED.
The original daily random-chance prospecting proposal is replaced by Build 17's existing MIN-C and MIN-D prospecting mechanics.
Retain:

* Prospecting clues.
* Sampling.
* Assays.
* Trial pits.
* Discovery of existing hidden deposits.
* The existing common ore depletion and sustainability mechanics.

Do not add an arbitrary daily probability that magically reveals a deposit.
Do not introduce the proposed special six-coin-per-day prospecting wage.
Continue using legitimate existing jobs, labor arrangements, and negotiated contracts.
Deposits must remain consistent with the approved world-generation and resource systems.
No automatic ore regeneration or free ore creation is authorized.
7. P1.5 — REJECT SPECIAL DISTANT QUARRY
OWNER DECISION: REJECT.
Do not introduce the proposed special off-map quarry that automatically provides stone through a fixed daily cart journey.
Reject the proposed 20-stone delivery quantity and 1.5–2-coin delivery pricing as unapproved gameplay rules.
Stone must come from legitimate sources, including local quarrying and actual regional trade.
Do not introduce a magical emergency stone supply.
Preserve the existing approved Build 17 stone mechanics.
Expansion 18 may later provide additional legitimate regional trading opportunities through its finite economy.
That does not authorize a separate unlimited off-map quarry.
8. ECONOMIC AND SIMULATION REQUIREMENTS
These decisions must preserve the fundamental design principles:

* Deposits follow the same existing depletion and sustainability mechanics in all environments.
* Independent miners retain economic agency.
* No universal manor ownership of resources.
* No automatic mining-specific wages.
* Negotiated procurement contracts use real goods, prices, quantities, and funds.
* Resources cannot appear from nowhere.
* Goods and currency must remain accounted for.
* NPC behavior must remain deterministic.
* Save compatibility must be maintained.
* Existing unrelated jobs and systems must not be broken.

A village may exhaust its resources or experience economic hardship as a legitimate simulation outcome.
Do not artificially prevent failure by inventing resources, payments, or supply.
A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT.
9. DOCUMENTATION AND IMPLEMENTATION
Update the authoritative requirements register, generated ledger, and decision documentation.
Mark:

* OD-01: ANSWERED / CLOSED.
* Mine-shift quest: RETIRE.
* ECON-P1.1: REJECTED.
* ECON-P1.2: REJECTED.
* P1.3: ASSIGNED TO EXPANSION 18.
* ECON-P1.4: SUPERSEDED BY MIN-C/MIN-D.
* ECON-P1.5: REJECTED.

Use the repository's actual status values and conventions.
Do not mark unfinished code as implemented simply because the owner approved its design.
Determine whether retiring the mine-shift quest requires code changes, data changes, save-migration handling, or targeted regression tests.
Make the necessary changes on the appropriate Build 17 development branch.
Avoid unrelated modifications and unnecessary full test campaigns.
Preserve valid existing test evidence and run focused verification where behavior changes.
Do not merge unrelated workstreams or publish release packages without authorization.
10. REQUIRED RESPONSE
Report:

1. All six OD-01 decisions recorded.
2. Files and registers updated.
3. Whether OD-01 is formally closed.
4. Whether the mine-shift quest was removed from future job generation.
5. How existing active quests and saves are handled.
6. Any implementation changes and targeted test results.
7. Exact branch and commit HEAD.
8. Any remaining genuine blockers.

After recording OD-01, retrieve REC-013 from its authoritative source.
Present REC-013 with its exact wording, original purpose, existing behavior, available choices, and your recommendation.
Do not answer REC-013 for me. We will continue resolving owner questions one at a time.
