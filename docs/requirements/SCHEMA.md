# The requirements register: schema and procedure

Owner directives: 2026-10-19 (requirements preservation) and 2026-10-23 (master reconciliation and development control,
`docs/directives/2026-10-23_master_requirements_reconciliation.md`, register REQ-CTRL-01).

## One source of truth

- **`docs/requirements/requirements.json`** (`mml-requirements/2`) is the **only manually maintained list** of
  requirements, proposals, ideas, World Design Rules and **owner decisions**. Decisions are records of kind `decision`
  in the same file: that is the decision register. No other document holds a requirement's or a decision's current
  state.
- **The register is edited only on `staging/my-medieval-life`**, by the lead, with `tools/requirements_update.py`.
  - A build or task branch carries a copy, synchronized from staging, and never edits it.
  - The pre-push hook refuses a push that changes the register on any other branch, unless the new copy is a version
    that already exists on staging.
  - The one exception is `wip/requirements-control`, the isolated consolidation branch the owner required for
    REQ-CTRL-02: register corrections are made and validated there, then staging is fast-forwarded to it.
- **Generated, never edited:**
  - `docs/DEVELOPMENT_LEDGER.md` (every record);
  - `docs/requirements/views/STATUS.md` (scorecard for Builds 18–21);
  - `BUILD_18.md` to `BUILD_21.md`;
  - `DECISIONS.md` (open owner decisions);
  - `BACKLOG.md` (Build 20+ and unassigned);
  - `QUEUES.md` (workers, untested work, owner playtest queue);
  - the baseline reconciliation reports.

  Regenerate them with `python3 tools/check_requirements.py --write`.
- **Historical, not authoritative:**
  - `docs/DECISIONS.md` (the narrative decision log, mostly agent engineering decisions);
  - `docs/directives/` (the owner's words, verbatim: the evidence a record cites);
  - `docs/requirements/LEDGER_ARCHIVE_*`, `RECOVERY_*` and the frozen `baseline_*.json`;
  - build reports, plans and audits.

  A record cites these documents; they never override it.
- **The reconciliation of 2026-10-23:**
  - `docs/requirements/reconciliation_2026-10-23.json` holds one line for every original record on every branch copy;
  - `RECONCILIATION_2026-10-23.md` is its summary.

## Record types

| `kind` | Meaning | Counted as build work? |
|---|---|---|
| `approved` | Owner-approved requirement (or compliance with an owner rule) | Yes, unless `umbrella`, deferred, superseded or rejected |
| `proposal` | Agent or document proposal awaiting the owner | No |
| `idea` | Unapproved idea or finding | No |
| `rule` | An owner World Design Rule (text in `docs/WORLD_DESIGN_RULES.md`) | No (its compliance is a `WDR-nnn-C` record) |
| `rejected` | A proposal the owner rejected | No |
| `decision` | An owner decision or open owner question | No (tracked in the decision register) |

`umbrella: true` marks a directive, expansion or parent entry whose children carry the work. It is listed but not
counted, so nothing is counted twice.

## Fields

Every record:
- `id`: stable, never reused or deleted;
- `aliases`: other numberings of the same record found in documents;
- `kind`, `title`, `description`, `system`;
- `source`: the document or owner decision;
- `owner_wording`;
- `target_build`;
- `workstream`, `priority`;
- `parent`, `depends_on`, `related`, `decisions` (the owner decisions it rests on);
- `notes`;
- `history`: a list of `{date, change, why}`, append-only. The first line is the creation reference; the latest is the
  last material update.

Requirement records (every kind except `decision`):

| Group | Fields |
|---|---|
| Status dimensions (all required) | `approval_status`, `implementation_status`, `verification_status`, `release_status`, `completion` |
| Design | `design` (SPECIFIED, PARTIAL, OWNER DECISION REQUIRED, DESIGN WORK REQUIRED, UNKNOWN); `effort` (XS, S, M, L, XL, UNKNOWN) |
| Development | `assigned_worker`, `branch`, `commits`, `implementation` (code location and notes), `remaining_work`, `next_action` |
| Verification | `integrated_in` (the builds that contain every recorded commit, computed at migration), `task_branches`, `tests` (automated evidence), `test_commit`, `gameplay_verification`, `playtest` (device or playtest needs), `playtest_done` (the record of one), `platform_verification`, `known_defects` |
| Release | `acceptance` (criteria), `required_validation` |
| Superseding | `superseded_by` |
| Migration | `migrated_from_status` (the v1 status at migration), `legacy_evidence` (evidence carried from a v1 record) |

A field that is absent is **unknown**, never "fine". Reports print UNKNOWN for it. Values are never invented.

Decision records: `title` (the exact question), `disposition`, `owner_answer` (the owner's words, or a pointer to
them), `blocks_implementation`, `target_build`, `supersedes`, `superseded_by`, `related`, `source`. The requirements it
affects are derived: every record naming it in `decisions`, `depends_on`, `related` or `parent`.

## Status values

- **approval_status:** PROPOSED · OWNER APPROVED · OWNER DECISION REQUIRED · DEFERRED · REJECTED · SUPERSEDED.
- **implementation_status:**
  - NOT STARTED, READY;
  - IN DEVELOPMENT: a named worker and branch, and named in the state file;
  - PARTIALLY IMPLEMENTED;
  - IMPLEMENTED ON TASK BRANCH;
  - INTEGRATED: merged into the target build's integration branch;
  - IMPLEMENTATION BLOCKED;
  - NOT APPLICABLE: rules, directives, closed records.

  PARTIALLY IMPLEMENTED is an addition to the directive's list: many records have part of their scope in the code and
  part not, and none of the listed values says that truthfully.
- **verification_status:**
  - NOT TESTED;
  - TARGETED TESTS PASSED: its own tests passed somewhere;
  - INTEGRATION VERIFIED: the suite passed on the integrated build;
  - GAMEPLAY VERIFIED: reached and checked through play;
  - OWNER PLAYTESTED;
  - VERIFICATION FAILED: names `known_defects`;
  - NOT APPLICABLE.
- **release_status:** NOT READY · RELEASE BLOCKED · RELEASE CANDIDATE · RELEASE READY · RELEASED · UNKNOWN (legacy
  records whose build is not recorded) · NOT APPLICABLE.
- **completion:**
  - OPEN;
  - COMPLETE: integrated and at least INTEGRATION VERIFIED, with no open playtest need;
  - CLOSED: superseded or rejected.
- **disposition (decisions):**
  - OPEN;
  - APPROVED: the owner's answer is recorded;
  - PROVISIONAL: an answer held, or an agent reading awaiting confirmation; never final;
  - SUPERSEDED;
  - REOPENED;
  - DEFERRED.

Nothing is promoted by a commit, a merge or an unrelated passing test. A dimension changes only with evidence, and
every change adds a history line.

## Builds

`target_build` takes one of these values:

| Value | Meaning |
|---|---|
| `15` to `21` | That build |
| `20+` | The owner's "Build 20 or later" backlog, not assigned |
| `unassigned` | Approved, but no build assigned |
| `owner decision` | The build waits on an owner decision |
| `owner action` | Owner or external action, not development work |
| `multiplayer` | The multiplayer track |

The register's `builds` map records each build's name, whether **implementation is authorized**, and its release.
- Builds 20 and 21 are **not authorized**: the validator refuses any of their records beyond READY.
- Build 19 is authorized only as isolated prospective work (PROS-01) until Build 18 is complete.

Change these entries only on the owner's word, with a history line on the build's anchor record.

## Procedure

It is part of normal work, and nobody needs reminding. Each step is `tools/requirements_update.py`, then
`tools/check_requirements.py --write`, then a commit on staging.

| When | Do |
|---|---|
| The owner approves something (directive, message, answer) | Save long wording verbatim in `docs/directives/`. Search the register (ids, aliases, titles). Add or update the record with `source`, `approval`, acceptance criteria, `depends_on` and `decisions`; set `target_build` only when the owner set it, otherwise `unassigned` |
| The owner answers or changes a decision | `decision` record: the disposition, `owner_answer` (the words, or a pointer to the saved directive). An earlier decision is SUPERSEDED with `superseded_by`, never deleted. Update affected requirements and list the downstream consequences in their history |
| A worker starts | READY → IN DEVELOPMENT with `assigned_worker` and `branch`; name the id in `docs/CURRENT_DEVELOPMENT_STATE.md` |
| Code lands on its task branch | IMPLEMENTED ON TASK BRANCH, `commits`, `tests`, `remaining_work`, `known_defects` |
| Merged into the build | INTEGRATED, `integrated_in`. Run the full suite on the integration commit before recording INTEGRATION VERIFIED with `test_commit` |
| The owner playtests, or a device check | `playtest_done` and the outcome. GAMEPLAY VERIFIED or OWNER PLAYTESTED; VERIFICATION FAILED with `known_defects` if it failed |
| A defect is found | Add it to the requirement's `known_defects` (or the release-gate record it blocks). A broken mechanic in released code gets its own approved record |
| Complete | `completion` COMPLETE only when integrated, at least INTEGRATION VERIFIED, and every `playtest` need done |

## Workers

Include this in every worker brief:

**Before starting**
1. Read the record in `docs/requirements/requirements.json`.
2. Confirm it is `OWNER APPROVED`.
3. Confirm its `target_build`.
4. Read its `depends_on` and `decisions`.
5. Read its `acceptance`.
6. Check that `docs/requirements/views/QUEUES.md` shows no other worker on it.

**While working**
- Stay in scope.
- Preserve recorded decisions.
- Report new dependencies.
- Keep engineering choices (`docs/DECISIONS.md`, agent decision) apart from owner decisions (ask the lead).
- Do not edit the register: report to the lead.

**When finished, report:**
- the commits;
- the tests run, with counts and commit;
- whether the work is integrated;
- what still needs gameplay or owner verification;
- known limitations.

Local tests passing never makes a requirement complete.

## Before a release

`docs/requirements/views/BUILD_<n>.md` must show:
- every approved in-scope record COMPLETE, or DEFERRED with the owner's approval;
- no open blocking decision;
- the release-gate records (`REL<n>-*`: suites, determinism, long runs, save compatibility, export, device and owner
  playtest, wiki, the owner's publishing approval) complete.

Readiness in the views is computed, never typed.

## Change control

When implementation or play shows that an approved design causes a problem:
1. State the original intent and the observed problem.
2. Name the affected records.
3. Recommend the smallest adjustment and record it as a proposal or a REOPENED decision.
4. Ask the owner when gameplay behaviour meaningfully changes.
5. Keep the earlier decision in history (SUPERSEDED, `superseded_by`).
6. After approval, update the dependent records.

Engineering changes that keep the design intent go ahead without a question. An approved decision states intent; it
does not oblige the project to keep a flawed implementation.

## Validation and enforcement

`tools/check_requirements.py` checks:
- duplicate ids and aliases, and missing fields;
- invalid values and contradictions between the dimensions;
- broken parent, dependency, related, decision and superseding references;
- invalid builds, and work on unauthorized builds;
- missing acceptance criteria;
- unapproved records marked as release candidates;
- INTEGRATED without integration evidence, and verified without test or playtest evidence;
- IN DEVELOPMENT without a worker;
- lost records and silent status changes against any git ref (`--against`) and the frozen baselines;
- paths that exist nowhere, and stale generated files.

An unfinished requirement is never a failure. Evidence a script cannot check, such as whether a test really covers
a feature, is listed in the views for human review.

**Where it runs:**
- the pre-push hook (also guards the register on non-staging branches);
- `.github/workflows/requirements.yml`: the validator only, on register, tool or directive changes, no game suites;
- `.github/workflows/tests.yml`, alongside the game suites.
