# Standard session recovery (any Claude session, ChatGPT or engineer)

This procedure follows owner directive DOC-CONT-01, section 11 (`docs/directives/2026-11-01_permanent_documentation_ai_continuity.md`),
and works alongside `CLAUDE.md` section 0. Use it after a context compaction, in a fresh session, or as an external assistant with
only GitHub access. Do not rebuild state from a conversation summary. The repository is the record.

## The 11 steps

1. **Identify the repository and objective.**
   - Repository: `verbal76/My-Medieval-Life`, a Godot 4.7 medieval village simulation.
   - The objective is the current build named in `docs/CURRENT_DEVELOPMENT_STATE.md`. As of 2026-11-01 that is Build 25, the
     consolidation build.
2. **Read the root agent instructions:** `CLAUDE.md` (project rules, release and save policy, what needs the owner).
3. **Open the current-state entry point,** `docs/CURRENT_DEVELOPMENT_STATE.md`, **from branch `wip/requirements-control`.**
   - Copies on `staging/my-medieval-life`, `wip/expansion20` and other branches are stale and carry a banner saying so.
   - Anything under `docs/handoffs/archive/`, or marked HISTORICAL, is history, not current state.
4. **Fetch current branch heads:** `git fetch origin`, then compare with the heads the state file names (integration branch, records
   branch, every worker branch). A newer head than recorded means work landed after the last checkpoint. Read its commits before
   acting.
5. **Read recent changelog entries:** the top of `docs/DEVELOPMENT_CHANGELOG.md`, plus `git log` on the integration branch since
   the last entry.
6. **Review the applicable owner decisions.**
   - Register records of kind `decision` are listed in `docs/requirements/views/DECISIONS.md`.
   - The owner's verbatim words are in `docs/directives/` (dated files, newest last).
   - An APPROVED decision has an `owner_answer`. A proposal or recommendation is not an approval. Do not reopen settled decisions.
7. **Review the active and suspended workstreams** in the "Workers and branches" table of the state file.
   - Never treat an unmerged branch as disposable.
   - Never start a second worker on a branch someone already holds.
8. **Identify the latest verified integration SHA** and what "verified" means for it. Use the levels in the changelog:
   IMPLEMENTED, COMPILED, TESTED, VALIDATED, INTEGRATED, PACKAGED, RELEASED. Results apply only to the SHA they name.
9. **Inspect recent CI results:**
   - GitHub Actions runs of `long-sims.yml`, `tests.yml` and `release.yml`.
   - Check whether anything is still running before starting anything. Never restart or cancel a running simulation (SIM-02).
   - Artifacts expire; the durable conclusions are in the changelog and in `docs/release/`.
10. **Identify outstanding defects and dependencies:** the "Known defects" and "Outstanding owner decisions" sections of the state
    file, and `docs/requirements/views/QUEUES.md` and `STATUS.md`.
11. **Resume the next authorized action** from the state file's "Next authorized actions". If it is blocked on the owner, ask, and
    continue with the next unblocked item.

## Reports a reader can build from the repository

| Report | Sources |
|---|---|
| Current status | `docs/CURRENT_DEVELOPMENT_STATE.md` |
| Last 24 hours | the newest dated section of `docs/DEVELOPMENT_CHANGELOG.md`; `git log --since="24 hours ago"` on the integration branch and `wip/requirements-control` |
| Build history | the changelog and its index of earlier records; `docs/expansions/README.md`; GitHub Releases |
| Owner decisions | `docs/requirements/views/DECISIONS.md`; `docs/directives/`; `docs/DECISIONS.md` (older narrative log) |
| Technical progress | `docs/requirements/views/STATUS.md` and `BUILD_NN.md` (by expansion number); the register's implementation and verification fields |
| Release readiness | the state file's tests and defects sections; the register's LE-07 gate records; `docs/release/` |

## Before a compaction or the end of a session

Do this early, at about 70-75% context where it can be measured.

1. Record any new owner words: save them verbatim in `docs/directives/`, then add the register record with
   `tools/requirements_update.py`.
2. Update `docs/CURRENT_DEVELOPMENT_STATE.md`: position, workers table, tests, next actions.
3. Add changelog entries for the milestones reached.
4. Run `python3 tools/check_requirements.py --write`. It must report 0 problems.
5. Commit and push `wip/requirements-control` and any worker branches. Confirm the remote heads. Local uncommitted work is not
   preserved by GitHub; say so if any remains.

Earlier recovery notes are in `docs/handoffs/archive/` (history only).
