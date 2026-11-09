# Owner directive, 2026-11-09: Urgent work preservation and disk safety

Received 2026-11-09 in the lead session (about 17:00 EST). Saved verbatim below; never edited. Register id HAG-PRESERVE-01.
The event record is `docs/audits/2026-11-09_WORK_PRESERVATION_EVENT.md`.

---

MML — URGENT WORK PRESERVATION AND DISK SAFETY DIRECTIVE

Owner authorization — November 9, 2026

You reported approximately 144 MB of free disk space and 74 uncommitted files in an existing development worktree.

Preserving all work is now the highest operational priority.

Do not lose, overwrite, discard, or silently abandon any development work, including work belonging to other agents.

1. IMMEDIATE SAFETY CHECK

Before any cleanup, merge, reset, or further disk-intensive operation:

1. Check available disk space and inode availability.
2. Inventory every Git worktree, including active and idle agent worktrees.
3. Identify all uncommitted, staged, unstaged, and untracked files.
4. Record each worktree's branch, HEAD SHA, owning agent, and current assignment.
5. Identify the 74 uncommitted files and determine whether they are development work, generated files, temporary artifacts, or something else.
6. Determine whether any file belongs to an active agent before touching it.

Do not assume an idle worktree contains disposable files.

2. PRESERVE EVERYTHING FIRST

Use the repository's established checkpoint and recovery procedures:

"python3 tools/checkpoint.py"

Review its actual behavior and available options before execution.

Preserve all working-tree changes, including untracked files, without modifying their original worktrees.

Create recoverable snapshots with clear source branch and commit identifiers.

Where possible, create an independent off-machine copy using the established "--offsite" process.

A local checkpoint on the same nearly full disk is not sufficient protection against storage failure.

Do not report anything as safely backed up until restoration has been verified.

Verification must establish that:

- Every relevant file was captured.
- File contents match the originals.
- Uncommitted and untracked changes can be restored.
- Branch identities and commit ancestry are preserved.
- The backup can be recovered independently of the original working directory.

If storage is insufficient to complete the checkpoint, stop disk-intensive work and report the limitation rather than risking corruption or incomplete backups.

Never delete originals to make room for an unverified backup.

3. PROTECT THE THREE ACTIVE AGENTS

The current assignments are:

- Lead: EMP-03.
- Helper 1: MP-05 security testing.
- Helper 2: REG-08 investigation.

Each agent must preserve its own work and avoid overlapping writes.

Coordinate a safe checkpoint. If necessary, temporarily pause writes or disk-intensive operations while preserving their state.

Do not terminate active simulations or agents unless continuing would create an immediate risk of data loss.

Do not share writable worktrees between agents.

Confirm that EMP-03 was branched from the correct current development source, "wip/b25r2-rev2", and not from an outdated PROP-06 snapshot.

4. DISK RECOVERY — ONLY AFTER VERIFIED PRESERVATION

After the work is safely backed up:

1. Measure actual disk usage.
2. Identify the largest directories and files.
3. Distinguish rebuildable caches and temporary outputs from irreplaceable development evidence.
4. Identify safe opportunities to reclaim space without touching source code, agent worktrees, Git history, or important test artifacts.
5. Recheck disk space after any approved cleanup.

No destructive Git commands, forced resets, broad deletions, or speculative cleanup.

Do not remove another agent's worktree or files just because they appear inactive.

If safe cleanup cannot provide adequate free space, report the storage constraint and recommend an alternative.

5. GITHUB ACCOUNTABILITY

Document the preservation event in the existing GitHub development records.

Record:

- Initial free space.
- Worktree inventory and branch SHAs.
- Number of protected files.
- Checkpoint method.
- Backup destination and verification evidence, without exposing credentials or secrets.
- Any remaining unprotected data.
- Any disk space reclaimed.
- Whether the three agents can safely continue.

Commit and push the documentation to an authorized branch.

Never commit secrets, private credentials, or large binary backups to the normal source repository.

6. REPORT BACK

Give me a concise report with:

1. Files discovered and files successfully preserved.
2. Backup location and whether independent restoration was verified.
3. Current free disk space.
4. Branch and worktree isolation status.
5. Status of the three agents.
6. Remaining risks or decisions requiring my approval.

Preserve first, verify second, clean up third, resume normal development fourth.

If you cannot establish a verified recovery path, do not claim the files are safe.

This directive authorizes preservation and investigation, not deletion of unverified work.
