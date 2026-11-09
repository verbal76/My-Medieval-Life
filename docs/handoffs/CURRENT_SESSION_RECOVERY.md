# Session recovery: start here (any Claude or ChatGPT session, or an engineer)

The one entry point for recovering My Medieval Life from GitHub alone. Owner directives:
- HAG-MEM-02, Part 8 (`docs/directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md`);
- DOC-CONT-01 (`docs/directives/2026-11-01_permanent_documentation_ai_continuity.md`).

It works alongside `CLAUDE.md` section 0. The repository is the record. Never rebuild state from a conversation summary.

## The 10 steps

1. **Identify the repository and the active branches.**
   - Repository: `verbal76/My-Medieval-Life`, a Godot 4.7 medieval village simulation (Hot Attic Games).
   - Current development (the Build 25 source): **`wip/b25r2-rev2`** (Build 25 Revision 2, "Play Test Build One"). The pointer
     at the top of the state file names its live SHA, the pending integrations and the running Actions.
     - *Correction 2026-11-09 (documentation agent, HAG-FORENSICS-01):* this step used to name `wip/expansion20`. That branch stopped
       being the development line on 2026-11-03. The line moved to `wip/b25r1`, then `wip/b25r2-playtest`, then `wip/b25r2-rev2`,
       as the owner's directives named them. `wip/expansion20` (`a459186`, the Build 25 draft), `wip/b25r1` and
       `wip/b25r2-playtest` are now frozen history. Never resume work on them because an older document names them.
   - Records (register, directives, state file, changelog, known issues, decision records): **`wip/requirements-control`**. Read
     every document below from this branch. Copies elsewhere are stale and carry a banner saying so.
   - The independent audit's register is on branch `docs/build25-audit-register`, with tracking issue #4. Pull requests from
     ChatGPT arrive on `audit/*` and `feature/*` branches; the lead integrates them.
   - `staging/my-medieval-life` is historical. `main` changes only by the owner.
   - Run `git fetch origin` and compare the heads with those named in the state file. A newer head means work landed after the
     last checkpoint, so read those commits first.
   - The history for 2026-11-03..09 was reconstructed after the fact. Its account of what was recovered and what is still missing
     is `docs/audits/2026-11-09_HISTORICAL_COVERAGE_REGISTER.md`. The owner's messages that were never saved at the time are in
     `docs/directives/2026-11-0*_recovered_owner_messages.md`.
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
   - GitHub Releases and the state file's top pointer. As of 2026-11-09:
     - `build-34` was published (public) on 2026-11-06 from `a9e9f6e`, as the B25R1 family playtest;
     - `build-25` is a private draft (files from `a459186`);
     - Build 24 (`4611d86`) is frozen;
     - the owner's provisional Play Test Build One package is an Actions artifact, not a release.

     (Corrected 2026-11-09; this step used to name Build 24 as the latest and point to the "Position" table, which is now history.)
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

## Decision authority (HAG-AUTH-01, 2026-11-09)

- **Owner resolutions of 2026-11-09 (`docs/directives/2026-11-09_owner_resolutions_hag_auth_01.md`), in force:** one lead plus up
  to two additional agents (PAR-AGENTS-01); no automatic creation or publication of any release, private drafts included
  (REL-OWNER-01); code line `wip/b25r2-rev2`, records `wip/requirements-control`, kept separate (BRANCH-POL-Q1/Q2); only the owner
  promotes a simulation baseline (BASELINE-AUTH-01); apparent conflicts get the full analysis in `docs/requirements/SCHEMA.md`
  (DECISION-CONFLICT-01). Do not reopen them because an older document says otherwise.

- Before acting on any decision, open `docs/requirements/views/AUTHORITY.md` on the records branch: it names the current development
  line and frozen branches, every record's lifecycle, and for each superseded decision the record that governs now and why.
  A document that disagrees with an ACTIVE register record is historical unless the register says otherwise.

## Notes from the independent recovery test (2026-11-09, HAG-FORENSICS-01)

- **Start here even if your checkout says otherwise.** `main` has no CLAUDE.md, and the local checkout's default branch may be an
  old one (for example `wip/b16-integration`, whose CLAUDE.md still names staging and Build 24). Old branches' copies of CLAUDE.md
  are stale. Always read CLAUDE.md and every record from `wip/requirements-control` (`git fetch origin wip/requirements-control`,
  then `git show origin/wip/requirements-control:CLAUDE.md`). The CLAUDE.md on the development line `wip/b25r2-rev2` also still
  carries an old banner naming `wip/expansion20`; the records branch copy is authoritative.
- **CLAUDE.md commit `f78515b`** is titled "PROPOSED" but was accepted by the lead and is in force, except the text of the
  section 5a rule (BRANCH-POL-01), which still named `wip/expansion20`. *Resolved 2026-11-09 15:10 EST: the owner confirmed `wip/b25r2-rev2` and the separate records branch (BRANCH-POL-Q1, BRANCH-POL-Q2, DEV-LINE-B25); the rule text now names `wip/b25r2-rev2`.*
- **No checkout or a full disk:** steps that run tools (`branch_audit.py`, `check_requirements.py`) need a checkout. Without one,
  read the generated views in `docs/requirements/views/` from the records branch and use `git show`/`git log origin/<branch>`.
- **A red "sim-gate" is not by itself a regression.** Since the baseline `df67e8e` was recorded for an older generator/save
  version, the gate reports every difference from it as blocking (32-33 findings). The owner has not accepted a new baseline
  (TEST-AUDIT-Q2). Read the findings: if all are "difference from a baseline of another version" and determinism is identical,
  it is the known state, not a new failure.
- **Build views:** `docs/requirements/views/BUILD_*.md` follow the register's build keys, where "25" is an expansion number (Weather,
  Seasons and Disasters), not Build 25. The Build 25 work is in the B25-* and B25-AUD-* records (STATUS and QUEUES views).

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
