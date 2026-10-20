# Owner directive, 2026-10-20: context compaction readiness (non-interrupting)

Saved verbatim from the owner's message. Register: OVN-01 (this directive supplements it).

---

CONTEXT COMPACTION READINESS — NON-INTERRUPTING DIRECTIVE

Claude,

Our current conversation context is approximately 78% utilized. I expect context compaction may become necessary during overnight development.

I want you to prepare for that transition without interrupting approved development.

Do not stop coding, cancel tests, terminate simulations, or pause the overnight development plan simply to prepare for compaction.

At the next natural, safe checkpoint, verify that the following information is preserved in the remote GitHub repository:

1. The complete overnight autonomous development directive and engineering decision authority.
2. The mandatory sequential roadmap: Build 15 → Build 16 → Build 17 → Build 18.
3. Current build status and remaining mandatory requirements.
4. All approved owner decisions and unresolved design questions.
5. Active branches, latest commits, and staging status.
6. Currently running simulations and their progress, including where results will be saved.
7. Tests completed, tests pending, and any known failures.
8. Approved implementation work currently underway.
9. Skipped noncritical items and their required follow-up.
10. The exact next development actions.

Update "docs/CURRENT_DEVELOPMENT_STATE.md", "docs/PROJECT_MEMORY.md", and the development ledger as necessary.

Commit and push any necessary documentation updates, verifying the remote commit hash.

Ensure the repository's session-start instructions explain how a fresh or compacted Claude session can recover the complete development state.

If compaction occurs, immediately recover the project state from the authoritative GitHub documentation before making further development decisions.

Do not assume that information missing from compacted conversation context was never approved.

Do not repeat completed work or restart running processes merely because compaction occurred.

Do not initiate a container restart or discard the current working environment as part of this preparation.

Most importantly: preparing for compaction is not permission to stop overnight development.

Continue implementing, testing, committing, and advancing through the approved builds according to the existing authorization.

I want a seamless handoff, not a shutdown.
