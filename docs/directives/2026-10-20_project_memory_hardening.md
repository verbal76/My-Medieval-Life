# Owner directive, 2026-10-20: persistent project memory hardening (verbatim)

MY MEDIEVAL LIFE — PERSISTENT PROJECT MEMORY HARDENING

Claude,

Before we proceed further into the development roadmap, I want to harden the project's persistent memory.

My concern is losing requirements, design decisions, unfinished work, or implementation details when a conversation gets too long, a context window resets, a container restarts, or a new development session begins.

The GitHub repository must be capable of restoring the complete development state without relying on previous conversation history.

This is an approved infrastructure and documentation task. It does not replace or interrupt current Build 15–16 development.

1. Establish a permanent project memory entry point

Create or update a clearly identified project memory index, preferably "docs/PROJECT_MEMORY.md".

This document must tell any new Claude session:

- What My Medieval Life is and its governing design principles.
- Where the authoritative World Design Rules are stored.
- Where the development ledger and requirements register are stored.
- Where approved expansion specifications are stored.
- Where the build roadmap and current work status are stored.
- Where technical architecture and save-system documentation are stored.
- Where unresolved owner decisions and blockers are tracked.
- How to determine the next approved development task.
- What work must not begin without further authorization.

The index should link to the existing authoritative files rather than duplicating their entire contents.

2. Preserve the five-build roadmap

The memory system must explicitly track:

- Build 15: Simulation Stabilization.
- Build 16: Long-Term Simulation Equilibrium.
- Build 17: Mining & Industrial Development.
- Build 18: Settlement Advancement & Regional Economy.
- Build 19: NPC Judgment System.

Builds 17–19 are approved future expansion objectives, not authorization to begin implementation immediately.

Record their dependencies, current status, and associated design documents.

If implementation must span additional builds, preserve the approved objectives and flag the scheduling issue rather than silently changing the roadmap.

3. Preserve every requirement and owner decision

Audit the existing development ledger, requirements register, open-items audit, and three expansion documents.

Ensure every approved requirement has a persistent identifier and an authoritative record containing:

- Description and source.
- Approval status.
- Assigned or proposed build.
- Dependencies.
- Implementation status.
- Acceptance criteria.
- Verification evidence when completed.
- Outstanding decisions or blockers.

Maintain explicit distinctions between approved requirements, proposals, unresolved questions, implemented features, and verified features.

Do not treat an unresolved question as an approved decision.

In particular, preserve the NPC Judgment System's 14 open design questions as unresolved unless an explicit owner answer exists.

Do not delete or silently merge requirements just because they appear similar.

4. Establish a session recovery document

Create or update a persistent session handoff file, preferably "docs/CURRENT_DEVELOPMENT_STATE.md".

It must record:

- Current active build and branch.
- Last verified remote commit.
- Work currently in progress.
- Most recent test results and their limitations.
- Known defects and blockers.
- Work completed but not yet verified.
- Next approved tasks in priority order.
- Outstanding owner decisions.
- Any running tests or processes that cannot be assumed to survive a restart.

Keep this concise enough that a new session can recover quickly, while linking to detailed records.

5. Make memory recovery part of the development workflow

Use the repository's existing Claude project instructions, such as "CLAUDE.md", or the equivalent supported mechanism.

Require the development agent at the start of every new session to:

1. Confirm the active repository and remote branch.
2. Read the project memory index.
3. Read the current development state.
4. Read the relevant roadmap, requirements, and owner decisions.
5. Review the current Git status and recent commits.
6. Identify the highest-priority approved work.
7. Resume without asking the owner to repeat decisions already documented.

If "CLAUDE.md" already exists, update it without discarding its current instructions.

Do not assume that a document will be read automatically simply because it exists. Establish an explicit startup instruction and verify it is discoverable.

6. Require persistent checkpoints

After meaningful work, update the relevant requirements and development records.

Before ending a session or changing tasks, preserve:

- What was changed.
- What passed testing.
- What remains untested.
- What failed.
- What must happen next.

Commit and push the updated records and approved development work to the appropriate remote GitHub staging or WIP branch.

Do not rely on uncommitted local files or container storage as the only copy of important information.

Do not claim a push succeeded without verifying the remote result.

7. Prevent requirements from disappearing

Extend the existing validation system where practical.

At minimum, check that:

- Every approved requirement has a stable identifier.
- Referenced expansion documents exist.
- Build assignments refer to known builds or explicitly designated future work.
- Completed items have verification evidence.
- Unresolved owner decisions are not silently marked resolved.
- No approved item disappears from the register without an explicit, traceable disposition.

Use automated checks where feasible and a documented review process for matters automation cannot determine.

Do not create a second, competing requirements database.

8. Test the recovery process

Perform a simulated fresh-session recovery using only the committed repository contents.

Demonstrate that another development agent could determine:

1. The current development priorities.
2. The state of Builds 15 and 16.
3. The three future expansions and their supporting documents.
4. All outstanding approved requirements.
5. The unresolved judgment-system questions.
6. The current blockers and pending tests.
7. The next safe development task.

Identify any missing information and correct the documentation.

A successful recovery test must not depend on recalling this conversation.

9. Do not interrupt approved development

Continue the existing Build 15–16 simulation work, bug fixes, testing, and remote GitHub preservation.

Do not start implementing Builds 17–19 as part of this memory-hardening task.

Do not publish new builds outside the existing release gates.

Required completion report

When the memory system is hardened, report:

- The permanent memory entry-point file.
- The startup instructions used by Claude.
- The development-state handoff file.
- How many approved and outstanding requirements were reconciled.
- Whether any requirements were missing or duplicated.
- The automated safeguards added.
- The results of the fresh-session recovery test.
- The verified remote branch and commit containing the changes.

Success means the project can survive a complete loss of conversation context and resume from GitHub without losing approved work, design intent, or unresolved decisions.
