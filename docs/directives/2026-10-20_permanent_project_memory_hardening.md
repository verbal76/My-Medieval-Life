# Owner directive, 2026-10-20: permanent project memory hardening

Saved verbatim from the owner's message (register MEM-02; it extends MEM-01, `docs/directives/2026-10-20_project_memory_hardening.md`).

---

MY MEDIEVAL LIFE — PERMANENT PROJECT MEMORY HARDENING

Claude,

Your latest audit successfully accounted for all 231 open entries, assigned them to the development roadmap or appropriate holding categories, and added validation preventing unassigned open items.

That is good progress. Now I want to make sure none of this work, design history, or development progress can be lost between sessions, context resets, or container restarts.

I do not want the project depending on your conversation memory. I want the GitHub repository itself to contain everything necessary for you, or a completely new development agent, to resume the project accurately.

1. Establish a permanent project memory system

Create or update "docs/PROJECT_MEMORY.md" as the central index for the project.

It must link to the existing authoritative sources for:

- World Design Rules and governing gameplay principles.
- The complete requirements register and development ledger.
- The open-items audit and 231-entry reconciliation.
- The Builds 15–19 roadmap and Build 20+ backlog.
- The Mining & Industrial Development expansion.
- The Settlement Advancement & Regional Economy expansion.
- The NPC Judgment System expansion.
- Unresolved owner decisions, including the 14 judgment-system questions.
- Technical architecture, save compatibility, and known limitations.
- Current development progress, simulation results, blockers, and next tasks.

Do not duplicate the entire contents of these documents. Create a reliable index that points to their authoritative locations.

2. Make session recovery mandatory

Update the existing "CLAUDE.md" project instructions, or the appropriate supported project instruction file, to require the following at the beginning of every development session:

1. Identify the repository, active branch, and latest remote commit.
2. Read "docs/PROJECT_MEMORY.md".
3. Read the current development-state document.
4. Review the development ledger, requirements register, roadmap, and unresolved decisions.
5. Review the applicable design specifications for the current work.
6. Check Git status and recent commits.
7. Determine what was completed, what remains unverified, and what work is authorized next.
8. Resume approved development without asking the owner to repeat documented decisions.

Do not assume that a file will be read automatically merely because it exists. Make the startup instructions explicit.

3. Maintain a live development handoff

Create or update "docs/CURRENT_DEVELOPMENT_STATE.md".

This must be a concise, regularly maintained record of:

- Current active build.
- Active development and staging branches.
- Last verified pushed commit.
- Current tasks and their progress.
- Latest simulation results and test coverage.
- Known defects and unresolved failures.
- Hardware checks still required.
- Blocked work and outstanding owner decisions.
- Next approved tasks in priority order.
- Any interrupted processes that need restarting.

Update this file at meaningful development checkpoints and before ending a session.

A new agent should be able to read it and immediately understand where development stopped.

4. Harden the requirements register

Preserve all 231 open entries and the 142 completed or superseded approved items already identified.

Every requirement must retain its stable identifier, description, approval status, build assignment, dependencies, current status, and completion criteria.

When an item is marked complete, record the relevant implementation and verification evidence.

Maintain a clear distinction between:

- Approved but not started.
- In progress.
- Implemented but not verified.
- Verified complete.
- Blocked.
- Deferred.
- Proposed.
- Awaiting owner decision.
- Superseded, with a reference to the replacing item.

Do not silently delete, merge, close, or reclassify requirements.

Extend the existing automated register validation where practical to detect missing identifiers, missing assignments, broken document references, unsupported completion claims, and unresolved decisions incorrectly marked as resolved.

5. Preserve the five-build roadmap

The current proposed roadmap is:

- Build 15: Simulation Stabilization.
- Build 16: Long-Term Equilibrium.
- Build 17: Mining & Industrial Development.
- Build 18: Settlement Advancement & Regional Economy.
- Build 19: NPC Judgment System.

Keep the three expansion documents separate and authoritative.

Maintain the Build 20+ backlog, multiplayer work, deferred features, external dependencies, and owner decisions as distinct categories.

Do not silently move requirements between builds or expand a build's scope without documenting the reason.

The 14 judgment-system questions remain unresolved until explicitly answered by the owner.

6. Preserve work through GitHub

The remote GitHub repository is the permanent source of truth.

After meaningful development milestones, commit and push approved code, tests, documentation, and tracking updates to the appropriate remote staging or WIP branch.

Do not leave essential information solely in:

- Conversation history.
- Claude's temporary memory.
- Local container files.
- Uncommitted changes.
- Private artifacts outside the repository.

Preserve historical decisions and completion evidence through version control.

Do not create a competing tracking system if the existing ledger and requirements register can be extended.

7. Test the memory recovery system

Perform a simulated fresh-session recovery using only files committed to GitHub.

Verify that an agent with no knowledge of our previous conversations can determine:

1. What My Medieval Life is intended to become.
2. Which development rules must be followed.
3. What Builds 15–19 contain.
4. Which requirements are complete, open, blocked, or deferred.
5. What the three future expansions require.
6. Which owner decisions remain unanswered.
7. What the latest verified simulation results show.
8. What work should be performed next.
9. What must not be started without approval.

If anything is missing, repair the documentation and repeat the recovery check.

8. Keep development moving

This is an approved project-infrastructure improvement, not a reason to stop active development.

Continue Build 15–16 stabilization, long-duration simulations, testing, fixes, and approved GitHub work.

Do not begin implementing Builds 17–19 as part of this task.

Do not publish additional builds outside existing release authorization and quality gates.

If the memory-hardening task is blocked, preserve its current progress and continue other approved work.

9. Completion report

When finished, report:

1. The permanent project memory index location.
2. The startup instructions that require Claude to read it.
3. The current development-state handoff location.
4. The number of requirements verified against the register.
5. Any missing, duplicated, or inconsistent records discovered.
6. The automated safeguards added.
7. The results of the simulated fresh-session recovery.
8. The verified GitHub branch and commit containing the work.

Acceptance standard: If your entire conversation context disappears tomorrow, a new development session must be able to recover the project's approved design, outstanding requirements, current progress, and next authorized tasks from GitHub alone.

The objective is not merely to save documentation. It is to establish a persistent, maintained, and tested development memory that prevents approved work from being forgotten.
