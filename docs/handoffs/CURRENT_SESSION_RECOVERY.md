# Session recovery: start here (any Claude or ChatGPT session, or an engineer)

The one entry point for recovering My Medieval Life from GitHub alone. Owner directives:
- HAG-MEM-02, Part 8 (`docs/directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md`);
- DOC-CONT-01 (`docs/directives/2026-11-01_permanent_documentation_ai_continuity.md`).

It works alongside `CLAUDE.md` section 0. The repository is the record. Never rebuild state from a conversation summary.

## The 10 steps

1. **Identify the repository and the active branches.**
   - Repository: `verbal76/My-Medieval-Life`, a Godot 4.7 medieval village simulation (Hot Attic Games).
   - Current development (the Build 25 source): **`wip/expansion20`**.
   - Records (register, directives, state file): **`wip/requirements-control`**. Read every document below from this branch.
     Copies elsewhere are stale and carry a banner saying so.
   - `staging/my-medieval-life` is behind. `main` changes only by the owner.
   - Run `git fetch origin` and compare the heads with those named in the state file. A newer head means work landed after the
     last checkpoint, so read those commits first.
2. **Read the permanent memory and the authoritative requirements.**
   - `CLAUDE.md` (rules, what needs the owner) and [`docs/PROJECT_MEMORY.md`](../PROJECT_MEMORY.md) (the index).
   - The register, [`docs/requirements/requirements.json`](../requirements/requirements.json), read through
     [`views/STATUS.md`](../requirements/views/STATUS.md) and [`views/QUEUES.md`](../requirements/views/QUEUES.md). It is the
     only source of requirement and decision status.
3. **Read the current snapshot,** [`docs/CURRENT_DEVELOPMENT_STATE.md`](../CURRENT_DEVELOPMENT_STATE.md).
   - Check its "Snapshot last verified" line. If that is older than the newest commits or runs, treat the snapshot as stale
     where they disagree.
4. **Read recent changes and owner decisions, with their reasons.**
   - The top of [`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md), plus `git log` since its newest entry on both
     branches.
   - [`views/DECISIONS.md`](../requirements/views/DECISIONS.md) for decision status.
   - [`docs/decisions/`](../decisions/README.md) for why.
   - `docs/directives/` for the owner's exact words.
   - A proposal or recommendation is not an approval. Never answer an open owner decision.
5. **Inspect the latest 20 GitHub Actions runs and their jobs**
   (`https://github.com/verbal76/My-Medieval-Life/actions`, or the API's workflow-runs list).
   - For each run, note its workflow, branch, SHA, status and conclusion. Note which are still running.
   - The workflows are `tests.yml`, `requirements.yml`, `long-sims.yml` (including flight-recorder campaigns) and
     `release.yml`.
6. **Read the reports and the failure evidence.**
   - Open each run's job summary.
   - `tests.yml` and `requirements.yml` upload `ci-report.json` (format `mml-ci-report/1`) with every suite's result and
     first failure lines. Long simulations upload `summary.json` and logs. Flight campaigns upload findings and a workbook.
   - A green run is not proof that every feature passed. Check what it actually ran:
     - which suites;
     - whether any were skipped;
     - whether it was a read-only "recover" run that simulated nothing.
   - Known defects, outcomes and past investigations are in [`docs/KNOWN_ISSUES.md`](../KNOWN_ISSUES.md). Read it before
     starting a new investigation.
7. **Verify release and package status.**
   - GitHub Releases (Build 24, `4611d86`, is the latest private draft; it is frozen) and the state file's "Position" table.
   - The levels are distinct: IMPLEMENTED, COMPILED, TESTED, VALIDATED, INTEGRATED, PACKAGED, RELEASED (changelog header), and
     uploading to Steam is separate again.
   - Results apply only to the SHA they name.
8. **Identify active tests and workstreams before starting anything.**
   - Check the state file's "Workers and branches" table and the running Actions runs.
   - Never restart, cancel or duplicate a running simulation (SIM-02).
   - Never start a second worker on a branch someone holds.
   - Never treat an unmerged branch as disposable.
9. **Reconcile conflicts** by authority, then chronology, then commit evidence:
   - the owner's latest directive and the register beat any handoff or summary;
   - newer commits and runs beat an older snapshot;
   - `docs/handoffs/archive/` and anything marked HISTORICAL is history only.
10. **Summarise the current state and pick the next authorized action** from the state file's "Next authorized actions".
    - If it is blocked on the owner, record the question with options and continue with the next unblocked item.

## Where things are recorded

| Need | Record |
|---|---|
| Status of a requirement or decision | The register and its views (generated; never hand-edit) |
| Why a decision was made | [`docs/decisions/`](../decisions/README.md) |
| What happened, when, on which commit | [`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md) |
| Defects and investigations | [`docs/KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) |
| Current work, workers, blockers, next action | [`docs/CURRENT_DEVELOPMENT_STATE.md`](../CURRENT_DEVELOPMENT_STATE.md) |
| Release evidence | `docs/release/` and GitHub Releases |

**Durable versus temporary.** Actions artifacts and logs expire. Every durable conclusion must be written into the changelog or
known issues, with the run link:
- a cause;
- a fix;
- a measurement;
- a verification result.

Automation never commits reports to a code branch under test, because a commit would change the SHA being validated. There
is no automatic reporting branch; see [the HAG-MEM-02 decision record](../decisions/HAG-MEM-02.md).

## Checkpoint: before a compaction or the end of a session

Do this early, at about 70-75% context where it can be measured.

1. Save any new owner words verbatim in `docs/directives/`, and add the register record with `tools/requirements_update.py`.
2. Write a rationale record in `docs/decisions/` for each lasting decision (HAG-MEM-02, Part 5).
3. Update the state file (position, workers, tests, next actions) and its "Snapshot last verified" line.
4. Add changelog entries for the milestones reached, and known-issues entries for defects found, causes established or
   approaches that failed.
5. Run `python3 tools/check_requirements.py --write`. It must report 0 problems.
6. Commit and push `wip/requirements-control` and every worker branch, then confirm the remote heads. Say plainly if any work
   is local only; GitHub does not hold uncommitted work.

The earlier 11-step version of this procedure (DOC-CONT-01) is in git history. Its content is kept in the steps above. Older
recovery notes are in `docs/handoffs/archive/` (history only).
