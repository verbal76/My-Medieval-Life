# Owner directive, 2026-10-23: Expansions 19, 20 and 21 progress

Verbatim (sent after Build 18's private draft release):

> MY MEDIEVAL LIFE — EXPANSIONS 19, 20, AND 21 PROGRESS DIRECTIVE
>
> Build 18 has successfully completed its release pipeline and is available for private playtesting.
>
> Now verify that Expansions 19, 20, and 21 are actively progressing according to their existing approved scopes, dependencies, and development plans.
>
> Do not assume they are running. Verify their actual status.
>
> PHASE 1 — WORKSTREAM AUDIT
>
> Inspect the current repository, branches, commits, worktrees, recovery handoffs, task registers, and any active development agents.
>
> For each expansion, determine:
>
> 1. Original approved scope and objectives.
> 2. Current development branch and latest commit.
> 3. Completed and verified work.
> 4. Work currently in progress.
> 5. Remaining authorized tasks.
> 6. Outstanding decisions or blockers.
> 7. Whether an agent or development process is actually active.
> 8. Dependencies on Build 18 or another expansion.
> 9. Next concrete implementation milestone.
>
> Distinguish between work that is completed, running, paused, blocked, and not started.
>
> Do not describe an inactive workstream as active merely because it has a branch or an assigned task.
>
> PHASE 2 — EXPANSION 19
>
> Expansion 19 previously completed its performance round, including:
>
> - Spreading daily updates across simulation hours.
> - Meeting the 16 MB memory target at 500 residents.
> - Reducing trade-hook overhead to approximately 5%.
> - Preserving determinism and resource conservation.
>
> The remaining identified performance hotspot was gossip, reaching approximately 76 ms in a phone frame.
>
> Check whether this work has progressed since the last report.
>
> Verify the status of the gossip optimization and any remaining worker-idle concerns.
>
> Continue previously approved implementation where safe.
>
> Do not restart completed performance work or repeat the earlier benchmark campaign without a specific reason.
>
> PHASE 3 — EXPANSION 20
>
> Expansion 20 previously completed its LE-00 audit but had not begun implementation.
>
> Read the actual approved Expansion 20 scope and audit findings.
>
> Determine whether implementation has now started.
>
> If it has not started, identify the reason and whether an approved, dependency-free task can begin immediately.
>
> Resume authorized work without reopening settled design decisions.
>
> Do not interpret the audit itself as implementation completion.
>
> PHASE 4 — EXPANSION 21
>
> Locate the Expansion 21 specification, approval record, and implementation plan.
>
> Determine:
>
> - Whether its scope is defined.
> - Whether development has been authorized.
> - Whether work has started.
> - Which dependencies remain.
> - What work can safely proceed now.
>
> If Expansion 21 has an approved implementation scope, begin or continue the next dependency-free task.
>
> If its scope has not been approved, do not invent features or begin speculative implementation.
>
> Instead, prepare a concise decision packet identifying what requires my approval.
>
> PHASE 5 — COORDINATE DEVELOPMENT
>
> Keep Expansions 19, 20, and 21 moving without introducing unnecessary concurrency.
>
> Rules:
>
> - Maximum two active development agents unless I explicitly approve more.
> - One clearly defined task per agent.
> - Avoid overlapping file ownership.
> - Preserve existing branch and worktree isolation.
> - Do not merge unfinished expansion work into the Build 18 release branch.
> - Do not modify the frozen Build 18 release artifacts.
> - Do not start redundant simulations or full test suites.
> - Reuse valid existing test evidence.
> - Apply RCA-01 and MSW-01.
> - Record completed work and remaining dependencies.
>
> Prioritize actual implementation progress over repeated planning, reporting, and auditing.
>
> If an agent has completed its task, assign the next approved task rather than leaving it idle unnecessarily.
>
> PHASE 6 — OWNER DECISION AUTHORITY
>
> You may independently resolve minor, reversible implementation questions that clearly follow approved designs.
>
> Record every delegated decision, including the original question, options, selection, rationale, and affected systems.
>
> Do not independently approve major new mechanics, economic rules, architectural changes, or changes to established gameplay intent.
>
> If one expansion is blocked by an owner decision, continue approved independent work on another expansion.
>
> Do not stop all development because one workstream needs clarification.
>
> PHASE 7 — CONTINUOUS PROGRESS AND RECOVERY
>
> Maintain the existing recovery handoff and task registers.
>
> Before approximately 70–75% context utilization, preserve the current state so work can resume after Claude's typical 80% compaction point.
>
> For each workstream, maintain:
>
> - Current commit.
> - Active task.
> - Assigned worker.
> - Latest passing verification.
> - Next action.
> - Known blockers.
>
> Do not create another elaborate management system if the existing records already serve this purpose.
>
> PHASE 8 — REPORT TO OWNER
>
> Give me a concise status report in this format:
>
> Expansion| Status| Latest commit| Active work| Next milestone| Blocker
> 19| | | | |
> 20| | | | |
> 21| | | | |
>
> Then report:
>
> 1. What actually advanced during this session.
> 2. Which agents are currently working.
> 3. Which approved tasks will be worked on next.
> 4. Any owner decisions that genuinely cannot be delegated.
> 5. Whether any workstream is unnecessarily idle.
>
> FINAL DIRECTIVE
>
> Build 18 is delivered. Keep the development pipeline moving.
>
> Verify the real status of Expansions 19, 20, and 21, resume approved work, and advance the next available milestones.
>
> Do not spend the session merely producing another audit.
>
> Do not expand scope or invent requirements.
>
> Do not wait for my approval on routine implementation decisions.
>
> Continue productive development within existing authorization and report meaningful progress.
