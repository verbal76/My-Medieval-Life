# HAG-MEM-02: GitHub as the permanent project memory, with CI reporting and recorded reasoning

## Identification
- Decision ID: HAG-MEM-02 (register `docs/requirements/requirements.json`; it depends on DOC-CONT-01)
- Date: 2026-11-02
- Project / build: My Medieval Life, during Build 25. It is a permanent Hot Attic Games operating requirement, not tied to a
  build.
- Decided by: owner
- Source of authority: [`docs/directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md`](../directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md)
  (Version 1.0)
- Status: register approval OWNER APPROVED; implementation in progress (copied 2026-11-02; the register is authoritative)
- Supersedes: nothing. It extends DOC-CONT-01 ([`docs/directives/2026-11-01_permanent_documentation_ai_continuity.md`](../directives/2026-11-01_permanent_documentation_ai_continuity.md)),
  which set up the state file, the changelog and the 11-step recovery.

## Original problem
In the owner's words (Part 10, "First permanent decision record"): conversations have finite context, and handoffs by hand
waste time, consume tokens and risk losing decisions, findings and history. The directive also notes that ChatGPT ("Bob")
reads the repository, its workflow runs and its artifacts, so both assistants need to recover the project from GitHub alone.

Gaps found during this implementation's reconnaissance (2026-11-02):
- No record of *why* decisions were made, apart from short "why" cells in `docs/DECISIONS.md` and the changelog.
- No durable record of known issues.
- `tests.yml` stopped at the first failing suite and wrote no summary or JSON.

## Owner's direction (quoted)
> Decision: Establish GitHub as the permanent project memory and require detailed CI reporting and documented development reasoning.
>
> Why: ChatGPT and Claude conversations have finite context. Repeated manual handoffs waste time, consume tokens, and risk losing decisions, technical findings, and development history.
>
> Desired outcome: A new AI conversation can recover any project by examining authoritative repository documents and the latest 20 GitHub Actions runs.
>
> Additional requirement: Significant owner conversations must preserve the reasons for decisions, not merely their implementation results.
>
> Development principle: Move expensive testing to GitHub while preserving rigorous verification and conserving Claude's development context.

(Part 10 of the directive.) Also:

> Our objective is to eliminate manual conversation handoffs permanently.

## Interpretation (lead agent and documentation worker)
- Reuse what DOC-CONT-01 built. The state file (component B), the changelog (C), the register and its DECISIONS view
  (D, status part) and the recovery procedure (F) already existed. The new pieces are:
  - the rationale standard and records (D, reasoning part): this folder;
  - [`docs/KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) (E);
  - additions to the index [`docs/PROJECT_MEMORY.md`](../PROJECT_MEMORY.md) (A);
  - recovery aligned to the directive's 10 steps (F);
  - CI reporting.
- The register stays the only status record. Rationale records link to it and never compete with it.
- CI reporting (`tools/ci_report.py`, on branch `docs/hag-memory-rationale-2026-11-02` for the lead to merge into the
  Build 25 source):
  - Every suite runs even after a failure.
  - Markdown summary plus `ci-report.json`.
  - Outcome words TESTED, FAILED or INCOMPLETE, never VALIDATED or RELEASED.

### No automatic reporting branch for now (lead agent's decision, 2026-11-02)
Part 4 of the directive allows "an appropriate reporting branch or established repository mechanism when automation must
persist records independently". None is set up now:
- **Commit SHAs stay stable.** Automatic commits to a tested code branch would change the SHA under validation, which Part 4
  forbids for code branches.
- **Nothing needs persisting automatically yet.** Durable conclusions are written by the lead into the changelog and known
  issues, with run links, at each checkpoint (Part 7). The run summaries and JSON reports cover the latest 20 runs.
- **The records branch is shared.** It is `wip/requirements-control`, written by the lead, and an automated writer there
  would race its pushes.

Reconsider if conclusions are being lost because artifacts expired before anyone recorded them.

## Reasoning and alternatives
- Why: the owner's stated reasons, quoted above.
- Alternatives the owner considered: UNKNOWN. The directive does not record any.
- Assumptions stated by the owner: ChatGPT is connected to the repositories, with read and write access.

## Consequences
- Applies to every Hot Attic Games repository and every session, Claude or ChatGPT.
- New obligations:
  - write a rationale record for lasting decisions (Part 5);
  - update the records at checkpoints (Part 7);
  - CI runs must report even on failure, and never collapse IMPLEMENTED, TESTED, VALIDATED, PACKAGED, RELEASED and
    "uploaded to Steam" into one word (Part 3).
- It does not authorize gameplay changes, public releases, or edits to frozen release candidates (Builds 22, 23 and 24 are
  frozen).
- It does not change owner-authority rules (Part 9).

## Implementation
- The directive is saved verbatim and HAG-MEM-02 is in the register (`0a57308`, `wip/requirements-control`).
- Documentation on `wip/requirements-control`:
  - this folder;
  - [`docs/KNOWN_ISSUES.md`](../KNOWN_ISSUES.md);
  - [`docs/PROJECT_MEMORY.md`](../PROJECT_MEMORY.md) sections;
  - [`docs/handoffs/CURRENT_SESSION_RECOVERY.md`](../handoffs/CURRENT_SESSION_RECOVERY.md);
  - the "Snapshot last verified" convention in [`docs/CURRENT_DEVELOPMENT_STATE.md`](../CURRENT_DEVELOPMENT_STATE.md).
- CI on `docs/hag-memory-rationale-2026-11-02`, commit `4309029`:
  - `tools/ci_report.py` and `tests/test_ci_report.py` (10 tests);
  - `tests.yml`, `requirements.yml`, and a summary-only step in `release.yml`;
  - actionlint clean.
- Not yet run in GitHub Actions. The first dispatch after the lead merges it is the real check.

## When to reconsider
The owner set no review trigger (UNKNOWN). Suggested by the documentation worker, not the owner: review it if a fresh
session cannot recover the state from the repository and the latest 20 runs, or if CI reporting hides or misstates a failure.
