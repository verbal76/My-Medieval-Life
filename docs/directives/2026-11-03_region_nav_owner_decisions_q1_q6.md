# Owner decisions, 2026-11-03: REGION-NAV-Q1..Q6 (Build 25 regional stages, crafters, geography, trade path, sequence)

Received in session, verbatim:

> Claude, I've reviewed your Build 25 regional development investigation and the six decisions you presented.
>
> Thank you for identifying the unauthorized changes and documenting them. We are going to correct the outstanding work without discarding functioning systems.
>
> OWNER DECISIONS — BUILD 25
>
> Decision 1 — Stage structure
>
> Retain the original eight approved stages, S1 through S8, as the official development milestones.
>
> You may use internal subtasks for engineering and testing, but those subtasks do not replace, redefine, or independently complete an approved stage.
>
> Each stage must satisfy its original acceptance criteria before being declared complete.
>
> Decision 2 — Work performed out of sequence
>
> Accept the existing settlement-building implementation in S2 and the road correction in S3.
>
> Do not undo functioning code merely to rearrange commit history.
>
> However, document the work under the original requirements it satisfies. If an earlier stage's acceptance criteria remain unmet, that stage remains open regardless of where the code was implemented.
>
> Decision 3 — Settlement geography
>
> Approve retaining the existing regional trade coordinates rather than rebuilding settlements around the originally proposed compass bearings.
>
> This approval is conditional on verifying that the physical locations, regional distances, road connections, travel times, and economic geography all agree.
>
> There must be one consistent geographical model, not separate coordinates for economic simulation and physical travel.
>
> Document this as an explicitly approved design amendment, including the technical rationale.
>
> Decision 4 — Independent crafters
>
> Choose option C.
>
> Independent crafting and self-employment must exist within the regional economy.
>
> A person must be able to produce goods or perform skilled work independently, negotiate compensation, and sell the results without necessarily owning a formal business or working for another business.
>
> Examples include a blacksmith performing private repairs, a carpenter producing furniture for sale, or an independent miner selling extracted materials.
>
> This must integrate with our existing skill progression, household ownership, inventory, negotiated transactions, and conservation rules.
>
> Do not create a disconnected economy or automatically treat every employed worker household as an independent business.
>
> Independent crafters must be discoverable and accessible to the player and to envoys when they are actively offering goods or services.
>
> Envoys must interview every relevant independent crafter as well as business owners, consistent with the approved regional information-gathering requirements.
>
> Do not replace individual interviews with a single household representative unless that person is genuinely the independent seller.
>
> Decision 5 — S2 trade implementation
>
> Conditionally approve retaining the existing courier hand-over mechanism rather than rebuilding everything around "SettlementParty.deal".
>
> However, this is not permission to weaken the original trading requirements.
>
> Verify that the existing implementation provides correct two-sided accounting, actual goods and currency transfers, inventory conservation, save/load consistency, and deterministic behavior.
>
> If "SettlementParty.deal" provides required semantics that the courier mechanism lacks, preserve or integrate those semantics.
>
> Document why the chosen implementation is correct and what tests establish equivalence.
>
> Decision 6 — Development sequence
>
> Finish S2's outstanding requirements first.
>
> Then finish S3's remaining approved tests and documentation.
>
> Once each stage satisfies its complete acceptance criteria, report its completion with exact commit SHAs and test evidence.
>
> After S2 and S3 are verified, proceed directly into S4, followed by S5, S6, S7, and S8 in the original approved order.
>
> Do not request another approval merely to advance between already-approved stages when their prerequisites have been satisfied.
>
> DEVELOPMENT GOVERNANCE
>
> The previously established governance rule remains in force.
>
> You may independently resolve ordinary technical implementation problems, but you may not silently change approved scope, milestone order, stage definitions, acceptance criteria, or release assignments.
>
> If you discover a necessary change, explain the reason, impact, alternatives, and your recommendation, then obtain owner approval before implementing the roadmap change.
>
> This does not prevent you from making routine engineering decisions within approved requirements.
>
> VALIDATION AND EFFICIENCY
>
> Reuse existing passing tests when their evidence applies to the exact source being evaluated.
>
> Complete the missing S2 save/load and conservation coverage, the required S3 tests, and any focused validation necessary for independent crafting and the approved trade implementation.
>
> Do not launch redundant year-long simulations or repeat entire validation campaigns without a technical reason.
>
> Preserve the previously validated Build 25 baseline, existing save compatibility, determinism, and economy conservation.
>
> Keep all work within Build 25. Do not defer approved regional functionality to a later build or expansion.
>
> REQUIRED PROGRESS REPORTING
>
> From now on, report progress by actual approved work packages, never by arbitrary completion percentages.
>
> For each of S1 through S8, show:
>
> - Completed
> - Actively developing
> - Testing
> - Blocked
> - Not started
>
> Include the outstanding deliverables, current test evidence, active blocker, and next action.
>
> Provide a concise summary such as: "Eight approved packages: two complete, one in testing, five outstanding," using only verified facts.
>
> Keep the permanent work-package register, decision records, and project state documentation synchronized with actual development.
>
> IMMEDIATE ACTION
>
> Record these six owner decisions permanently.
>
> Complete the outstanding S2 work, including independent crafters and save/load verification.
>
> Finish S3's three missing tests and required records.
>
> Then proceed through the remaining approved regional stages without unnecessary approval interruptions.
>
> Report genuine blockers or new owner-level decisions as they arise.
>
> Do not merge, package, publish, or promote Build 25 until the approved release requirements are satisfied.
>
> Proceed.
