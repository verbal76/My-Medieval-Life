# Owner directive, 2026-11-03: one temporary Validation and Integration Agent for Build 25 (VAL-AGENT-01)

Received in session, verbatim:

> MY MEDIEVAL LIFE — BUILD 25
>
> Authorize One Temporary Validation Agent
>
> You are authorized to launch exactly one additional subagent to assist with Build 25 development.
>
> 1. Agent assignment
>
> Create one Validation and Integration Agent.
>
> The main Claude session remains the sole development lead, responsible for implementation, stage sequencing, integration, and final decisions within the approved requirements.
>
> The validation agent operates independently, in parallel, with a read-only mandate unless specifically authorized otherwise.
>
> Do not pause the main development session while the agent works.
>
> 2. Immediate assignment — REGION-NAV-01, Stage 2
>
> Review the current S2 implementation on "wip/region-nav", including:
>
> - Independent crafters and household self-employment.
> - Production, purchasing, inventory, profit, and household accounting.
> - Courier hand-over versus "SettlementParty.deal" equivalence.
> - Save/load and deterministic simulation behavior.
> - Regional road distances, courier delivery times, and NPC travel consistency.
> - Interactions with the existing Living Economy.
> - Household transitions, estate handling, and conservation of goods and money.
>
> Inspect existing test results and GitHub evidence first. Identify which acceptance criteria have already been proven and which remain unverified.
>
> 3. Test efficiency
>
> Do not duplicate tests already running or completed successfully on the applicable exact source SHA.
>
> The agent should primarily inspect code, test coverage, existing artifacts, logs, and documentation.
>
> Only recommend additional tests when a specific requirement lacks evidence or an actual defect is suspected.
>
> Do not initiate another full simulation campaign or 365-day run.
>
> 4. Independence and safety
>
> The validation agent must not:
>
> - Change production code without authorization.
> - Merge branches or modify the main development worktree.
> - Reorder, split, or redefine the approved eight stages.
> - Introduce new economic rules or change gameplay requirements.
> - Package or publish a build.
> - Interrupt existing simulations or tests.
> - Ask the owner for routine technical decisions already covered by approved requirements.
>
> Use an isolated read-only checkout or equivalent separation where appropriate.
>
> 5. Reporting
>
> Provide a concise report to the main Claude session containing:
>
> 1. Verified: requirements supported by actual evidence.
> 2. Unverified: requirements awaiting evidence.
> 3. Defects: confirmed issues, with files, reproduction details, and severity.
> 4. Integration risks: interactions with existing Build 25 systems.
> 5. Recommended actions: specific corrections or missing focused tests.
>
> Distinguish confirmed defects from suspected risks.
>
> Record significant findings in the established GitHub documentation and decision framework through the main agent, without creating competing edits.
>
> 6. Agent lifecycle
>
> After S2 validation, the agent may review S3's remaining journey tests and subsequent completed stages as directed by the main Claude session.
>
> Use the agent only while there is meaningful independent validation work. Shut it down when its assignment is complete or when the additional token cost outweighs its value.
>
> Do not create further agents without owner approval.
>
> 7. Main development directive
>
> Continue the approved eight-stage REGION-NAV-01 implementation sequence.
>
> Do not wait for the validation agent unless it identifies a genuine blocking defect.
>
> When the agent reports a defect, the main Claude session owns the correction and integration.
>
> Objective: increase useful parallel progress while preserving Build 25 correctness, minimizing Claude token usage, and maintaining one authoritative development process.
>
> Proceed without requesting additional approval.
