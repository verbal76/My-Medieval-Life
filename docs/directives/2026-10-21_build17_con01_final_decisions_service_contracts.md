# Owner directive, 2026-10-21: Build 17 Master Owner Directive — CON-01 Final Decisions, Service Contracts, Integration and Release Preparation

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

MY MEDIEVAL LIFE — BUILD 17 MASTER OWNER DIRECTIVE
CON-01 Final Decisions, Service Contracts, Integration and Release Preparation
Repository: `verbal76/My-Medieval-Life`
Primary branch: `wip/build17`
Last reported HEAD: `d86e89f`
Date: October 21, 2026
PRIMARY INSTRUCTION
I am approving all nine CON-01 owner questions using their currently documented defaults and recommended dispositions for Build 17.
These are owner-approved gameplay defaults pending hands-on playtesting, not permanent balance values.
I am also explicitly approving service contracts as part of the universal CON-01 system.
Record these decisions in the authoritative owner-decision register, update the appropriate Build 17 documentation, and continue implementation, integration, testing, and GitHub pushes.
Do not stop ongoing MIN-E development or unrelated authorized Expansion 18, Expansion 19, or FARM-08 work.
Do not publish Build 17 until its required development and verification gates are complete and release publication is authorized.
SECTION 1 — FINAL OWNER ANSWERS TO Q-C1 THROUGH Q-C9
Q-C1 — Manor tool orders
APPROVED: Keep the existing manor tool-order system separate from CON-01 for Build 17.
The manor pays the blacksmith in advance so the blacksmith can obtain the necessary materials.
The advance is a real economic transaction and must not be silently converted to payment upon delivery.
Preserve the existing order, material, inventory, and financial behavior.
Continue counting manor orders as existing obligations when evaluating a blacksmith's availability for other contracts.
Future consolidation is permissible only if the universal contract system can support the original advance-payment terms without changing the economic outcome.
Do not undertake that consolidation as part of this approval.
Q-C2 — Paid work quests
APPROVED: Keep existing paid work quests separate for Build 17.
The established rule remains that quest wages are paid in full upon successful completion or not paid at all.
Do not convert these quests to per-unit payment.
Preserve the existing quest interface, completion conditions, and payment behavior.
The approval of service contracts does not authorize changing existing paid work quests.
Q-C3 — Alternative earnings
APPROVED: `opportunity_weight = 1.0`.
A seller should consider what the same amount of working time could earn through their existing occupation or business.
Keep the existing opportunity-cost calculation.
This is a provisional economic balance value pending playtesting.
Q-C4 — Risk margin
APPROVED: `risk_margin = 0.15`.
Retain the existing 15% uncertainty allowance in work-time estimates.
This is a scheduling and feasibility buffer, not an automatic 15% profit margin.
Do not confuse the two.
Q-C5 — Cancellation premium
APPROVED: `cancel_premium = 0.10`.
A buyer who previously ended contracts early with the same seller may be charged an additional 10% per recorded early cancellation.
Keep the existing 14-day record-retention window.
Preserve existing lapse and relationship consequences.
Do not introduce permanent blacklisting or additional penalties without owner approval.
Future integration with Expansion 19's judgment system may be evaluated later, but do not prematurely replace the current deterministic rule.
Q-C6 — Formal contract threshold
APPROVED: `formal_total = 50` coins.
Contracts worth 50 coins or more require formal signing.
Contracts below that amount remain ordinary agreements and do not require signatures.
Keep the existing behavior permitting small unsigned agreements to be concluded remotely.
Formal contracts require physical signing. No instantaneous remote signing.
Courier-assisted document signing belongs to Expansion 18.
Q-C7 — Signing distance
APPROVED: `sign_reach = 3` tiles.
Both parties must be within three tiles, in the same place and on the same level, for face-to-face signing.
The manor may continue to be represented by its authorized reeve.
This is provisional pending playtesting.
Q-C8 — Unsigned agreement expiration
APPROVED: `offer_days = 2`.
A formal agreement that has not been signed within two days expires.
No goods or money are transferred or reserved before the required signatures are completed.
If either party dies before signing, preserve the existing cancellation behavior.
Keep the deadline provisional for later review, especially when Expansion 18 introduces travel between settlements.
Q-C9 — Buyer counteroffers
APPROVED: `npc_counter_tolerance = 0.25`.
A villager buyer may negotiate up to 25% above its initial offer, subject to actual purchasing power.
Preserve the existing quantity requirements and maximum 10-day wait.
A buyer must never agree to spend coins it does not actually possess or have available.
Keep all existing deterministic counteroffer behavior.
SECTION 2 — SERVICE CONTRACTS ARE NOW OWNER-APPROVED
Decision: YES.
The universal CON-01 system must support contracts for labor and services, not only goods procurement.
This applies equally to:

* Player hiring an NPC.
* NPC hiring the player.
* NPC hiring another NPC.

Use the existing shared contract engine, negotiation system, counteroffer mechanics, economic evaluations, relationship considerations, and signing rules.
Do not create a second contract engine.
Goods versus services
A goods contract is fulfilled through the agreed delivery of goods.
A service contract is fulfilled through performance of the agreed work.
Examples include:

* Hiring a carpenter to repair a building.
* Hiring a miner to excavate an area.
* Hiring a farmer to harvest a field.
* Hiring a laborer for a specified job.
* Hiring a guard to provide protection.
* Hiring someone to transport goods.

These are examples of the intended contract capability, not instructions to invent entirely new occupations, combat systems, or gameplay features in Build 17.
Service-contract requirements
The existing contract system should support the relevant terms for a service, including:

1. Service or work requested.
2. Contracting parties.
3. Work location.
4. Quantity, duration, or completion objective as applicable.
5. Agreed compensation.
6. Required materials or equipment.
7. Completion conditions.
8. Deadline or schedule where applicable.
9. Existing obligations and availability.
10. Negotiation and counteroffers.

NPCs must evaluate whether they can actually perform the service using existing skills, tools, schedules, household obligations, competing opportunities, and relationship considerations.
The player and NPCs must use the same underlying rules.
Fulfillment
Accepting a service contract does not mean the work is complete.
Work must actually be performed through the relevant existing game systems.
Payment must come from real available funds.
Do not create goods, currency, labor progress, or completed work merely because a contract was accepted.
Maintain deterministic behavior, save/load integrity, and resource conservation.
Scope control
Implement the reusable service-contract capability within CON-01 using existing supported gameplay services.
Do not expand this task into a new guard AI system, regional transportation system, remote settlement system, or comprehensive occupation overhaul.
Where a service requires gameplay functionality that does not yet exist, preserve the contract architecture and record the dependency instead of fabricating a substitute.
Service-payment questions
Preserve the existing CON-01 payment framework wherever applicable.
Do not silently impose new permanent rules for service advances, progress payments, incomplete work, or disputed completion.
If a specific service cannot be implemented consistently without an additional economic decision, document the exact issue and present the available options for owner review.
Do not let one unresolved service subtype block completion of otherwise functional Build 17 systems.
SECTION 3 — PRESERVE EXISTING SPECIAL PAYMENT RULES
The approval of service contracts does not override previously approved mechanics.
Manor tool orders: Maintain advance payment.
Paid work quests: Maintain full payment on completion or no payment.
Manor job board: Preserve existing job and wage rules.
Existing hired carriers and stall attendants: Preserve their current behavior.
These systems may be considered for future consolidation, but no automatic migration into CON-01 is authorized.
CON-01 should continue accounting for these commitments when calculating an NPC's available working time.
Avoid duplicate reservations, duplicate obligations, and double payment.
SECTION 4 — NPC OFFERS AND LOGGING
The current NPC-to-player offer behavior is approved provisionally.
The reported 55 offer-related log entries during a 30-day simulation are not a Build 17 release blocker by themselves.
Do not suppress legitimate NPC offers or alter economic behavior merely to reduce logging.
Preserve the existing system for Build 17 and flag the player-facing notification experience for post-build playtesting.
Any later interface improvements should distinguish actionable offers from background historical events.
SECTION 5 — BUILD 17 DEVELOPMENT AND INTEGRATION
Continue all previously authorized Build 17 work.
In particular:

* Continue MIN-E open-pit development.
* Verify the final status of MIN-D integration and its deterministic gate.
* Preserve the Build 16 baseline separately.
* Integrate CON-01 service-contract support without breaking existing goods contracts.
* Check the authoritative Build 17 register for all remaining mandatory requirements.
* Reconcile mining, contracting, inventory, production, and NPC behavior.
* Preserve player/NPC parity and save compatibility.

Do not assume Build 17 is complete merely because CON-01 has merged.
Do not assume MIN-E is the final outstanding workstream without inspecting the full requirement register.
SECTION 6 — TESTING AND DEVELOPMENT EFFICIENCY
Reuse passing test evidence from the exact applicable source commit.
Do not repeatedly run full test suites merely for reassurance.
For service-contract code changes, run focused tests covering:

* Negotiation in all three party directions.
* Counteroffers.
* Service feasibility and available labor.
* Actual work completion.
* Payment and reservation accounting.
* Contract expiration and cancellation.
* Save/load.
* Deterministic behavior.
* Noninterference with existing goods contracts.
* Preservation of manor and quest payment rules.

Run broader regression testing only where changes invalidate previous evidence or an integration gate requires it.
Once MIN-E and the approved CON-01 changes are integrated, record the appropriate new Build 17 determinism baseline and perform the required matching verification.
Report actual conservation discrepancies. Do not mask them by adjusting simulation targets.
A village is allowed to fail. The simulation is not.
SECTION 7 — EXPANSION BOUNDARIES
Expansion 18 continues on its isolated branch.
It owns:

* Courier occupations and booths.
* Regular transportation routes.
* Special negotiated deliveries.
* Physical intersettlement transport.
* Courier-assisted remote formal signing.
* Regional settlement and capability systems.

Expansion 19 continues on its isolated branch.
It owns the more advanced NPC judgment, memory, trust, reputation, and related decision weighting.
Do not prematurely merge either expansion into Build 17.
Do not duplicate their systems inside CON-01.
Keep the contract engine extensible so those systems can use it later.
FARM-08 experiments may continue independently, but experimental balancing features remain disabled unless separately authorized.
SECTION 8 — RECORD THE DECISIONS AND PUSH
Update the appropriate authoritative documents, including:

* `docs/build17/CON01_COMPLETION.md`
* The Build 17 requirement and status register.
* The owner-decision log.
* Any relevant architecture or integration documentation.

Record Q-C1 through Q-C9 as:
OWNER APPROVED — BUILD 17 DEFAULT — REVIEW AFTER PLAYTESTING.
Record service-contract support as:
OWNER APPROVED — IMPLEMENTATION AUTHORIZED.
Do not misrepresent service contracts as completed until implemented and tested.
Commit and push completed authorized changes to the appropriate development branch.
Report the exact pushed commit SHA and test evidence.
SECTION 9 — FINAL STATUS RESPONSE
After recording these decisions and continuing the authorized work, provide a concise status report containing:

1. Confirmation that Q-C1 through Q-C9 have been recorded as approved.
2. Confirmation that service contracts are authorized.
3. Which service-contract capabilities are implemented versus still pending.
4. Current Build 17 branch HEAD and pushed commits.
5. Current MIN-D and MIN-E status.
6. Applicable test and determinism results.
7. Any remaining mandatory Build 17 requirements.
8. Any genuine owner decisions still required.
9. The next critical-path development steps.

Do not ask me to approve the same nine provisional settings again before Build 17 playtesting.
Do not treat this approval as permission to publish a release.
Continue development toward a complete, playable, properly verified Build 17 candidate.
