# Owner directive, 2026-11-02: immediate branch consolidation and worktree control (BRANCH-POL-01)

Received in session, verbatim:

> MY MEDIEVAL LIFE — IMMEDIATE BRANCH CONSOLIDATION AND WORKTREE CONTROL
>
> We consolidated four branches approximately two hours ago, yet development is already diverging again. Correct the underlying workflow problem, not merely the current branch structure.
>
> Owner authorization: Consolidate the active development work into one integration branch. Preserve all completed work, evidence, and running processes. Do not publish releases or start new long simulations.
>
> 1. Audit the current development state
>
> Identify the actual current integration branch and its HEAD SHA.
>
> Inspect all active MML development branches and worktrees, including:
>
> - "wip/b25-home-door"
> - "wip/b25-fr-investigate"
> - "wip/b25-farm-phase2"
> - "wip/requirements-control"
> - Any additional active worker branches
> - The four branches consolidated during the previous integration
>
> Determine which branches contain genuinely unique changes versus shared history.
>
> Do not use GitHub ahead/behind counts alone to determine the amount of new work.
>
> Inspect active workers, uncommitted files, pending commits, and ongoing tests before changing branches.
>
> 2. Establish one authoritative integration branch
>
> Use the existing designated integration branch if appropriate. Do not create another competing mainline.
>
> Preserve and integrate all completed, reviewed changes from active workstreams.
>
> Resolve conflicts based on the documented owner decisions and actual implementation requirements, not by automatically choosing the newest file.
>
> Do not discard work, overwrite uncommitted changes, or merge unfinished experimental code merely to make the branch graph look clean.
>
> Keep existing running workers and tests intact.
>
> 3. Bring active workers into alignment
>
> All workers must understand:
>
> - The exact authoritative integration branch and HEAD SHA
> - Which changes are already integrated
> - Which work remains outstanding
> - Where their completed changes must be submitted
> - Which files or systems they own
>
> Workers may use temporary isolated worktrees to avoid simultaneous edits, but they must not establish independent long-lived development mainlines.
>
> As each worker completes a validated unit of work, integrate it promptly into the authoritative branch.
>
> Do not wait until hundreds of unrelated commits accumulate before reconciling branches.
>
> 4. Preserve the three current assignments
>
> KI-HOME-DOOR: Continue root-cause investigation, safe homelessness handling, regression tests, and resumed Seed 2 validation.
>
> Flight Recorder findings: Continue the independent investigation of cart-hitch loops, wheat-sale failures, and contract cancellations. Do not make speculative fixes.
>
> Farming Phase 2: Continue implementing approved wheat yield 1.75, shared and seasonal farming, save compatibility, and targeted tests.
>
> Maintain clear ownership of each workstream.
>
> 5. Validate integration efficiently
>
> Reuse applicable existing test evidence.
>
> Run targeted tests for actual merged changes and affected interfaces.
>
> Do not start another full test campaign or 365-day simulation until the integration and required fixes are ready.
>
> Do not cancel the currently running GitHub test merely because integration is taking place.
>
> 6. Prevent this recurring
>
> Establish a permanent branch/worktree policy:
>
> - One authoritative integration branch.
> - Short-lived isolated worker branches.
> - Frequent integration of completed changes.
> - No unnecessary merging of unrelated historical branch ancestry.
> - No worker independently redefining the integration baseline.
> - No deleting branches or worktrees while they contain unmerged work.
> - Record exact integration SHAs and decisions.
> - Detect stale worker bases and overlapping file ownership early.
>
> Update "docs/CURRENT_STATE.md", "docs/OWNER_DECISIONS.md", and the development history with the integration policy and rationale.
>
> 7. Report back
>
> Provide:
>
> 1. Authoritative integration branch and SHA.
> 2. Branches inspected and unique work identified.
> 3. Changes successfully integrated.
> 4. Unfinished worker changes still isolated.
> 5. Conflicts encountered and their resolution.
> 6. Current worker assignments and status.
> 7. Targeted test evidence.
> 8. Remaining blockers.
> 9. Confirmation that no work was lost and no long simulation was unnecessarily restarted.
>
> Proceed with the authorized consolidation. Escalate genuine conflicts involving owner decisions. Do not publish or release anything.
