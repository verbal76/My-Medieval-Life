# Decision rationale records

This folder keeps **why** the project decided what it did (owner directive HAG-MEM-02, Part 2D and Part 5,
[`docs/directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md`](../directives/2026-11-02_hag_permanent_github_memory_reporting_directive.md)).
It complements the records that already exist. It does not replace them.

## How the records fit together

| Question | Authoritative record |
|---|---|
| What is the status of a requirement or owner decision (OPEN, APPROVED, PROVISIONAL, SUPERSEDED...; implementation, verification and release status) | The register, [`docs/requirements/requirements.json`](../requirements/requirements.json), read through [`docs/requirements/views/DECISIONS.md`](../requirements/views/DECISIONS.md) and [`STATUS.md`](../requirements/views/STATUS.md) |
| What exactly did the owner say | [`docs/directives/`](../directives/), verbatim and never edited |
| What happened, when, on which commit | [`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md) |
| Older one-line decisions with who decided | [`docs/DECISIONS.md`](../DECISIONS.md) (narrative log, kept) |
| **Why** a lasting decision was made, what else was considered, what must not change casually | **This folder** |

**The register stays authoritative for status.** A rationale record names its register ID and links to it. It never holds a
status of its own that could disagree. Its "Status" line is copied from the register on the date shown, and it says so. When
they differ, the register wins; correct the record with a dated note.

A record is not an approval. Writing one never turns a proposal, a recommendation or a discussion into an owner decision.

## When to write one

Write a record before implementing a significant change, or at the same checkpoint, when an owner discussion or directive
introduces or changes a lasting decision. Part 5 of the directive lists examples: gameplay mechanics, generation rules,
economic systems, NPC behaviour, architecture, significant UI changes, test requirements, release policy, rejecting a
feature, accepting a technical compromise, changing priorities. Small engineering choices stay in commit messages and the
changelog.

## Rules

- **Never invent.** Write only what a committed source supports: a directive, the register's text and history, the
  changelog, a commit message, a report in the repository. Where the reasoning, the alternatives or an objection were not
  recorded, write **UNKNOWN**. Do not supply a plausible reason.
- **Keep the owner's words separate from interpretation.** Owner quotations go under "Owner's direction (quoted)" with their
  source file. Anything the lead or a worker inferred, recommended or chose goes under "Interpretation" and says who.
- **Name who decided.** Owner, lead agent, or worker. An agent-provisional value is not an owner decision.
- **Never delete or rewrite a superseded record.** Set its status line to SUPERSEDED, name the record that replaced it,
  and leave the rest as written. The replacing record links back. The superseded example below shows both.
- **Conversations not in the repository** (for example a ChatGPT discussion) are cited only through the owner's supplied
  instruction or the committed record. Never claim access to a conversation that is not available.
- **Link evidence, don't copy it.** Commits, tests and Actions run IDs are links or SHAs. Actions artifacts expire, so the
  durable conclusion goes in the changelog or [`docs/KNOWN_ISSUES.md`](../KNOWN_ISSUES.md) with the run link.

## File naming

`docs/decisions/<REGISTER-ID>.md`, for example `B25-BIZ-TENANT-Q.md`. When one register entry holds several lasting
decisions, or the decision had no register ID of its own, add a short suffix to the related ID:
`X20-CHAPEL-FIX--food-line-6-day.md`. List every record in the index at the end of this file.

## Template

```markdown
# <REGISTER-ID>: <short title>

## Identification
- Decision ID: <REGISTER-ID> (register: docs/requirements/requirements.json)
- Date: <YYYY-MM-DD>
- Project / build: My Medieval Life, Build <N>
- Decided by: owner | lead agent | worker (say which)
- Source of authority: <directive file, or register field, or commit>
- Status: <copied from the register on YYYY-MM-DD; the register is authoritative>
- Supersedes / superseded by: <record links, or none>

## Original problem
What prompted it, what was wrong or missing, what outcome the owner wanted. Cite evidence (run IDs, reports).

## Owner's direction (quoted)
> Brief verbatim quotation. (source file)

## Interpretation
How the lead or a worker read the direction, and any provisional values they chose. Say who.

## Reasoning and alternatives
- Why this approach: <recorded reason, or UNKNOWN>
- Alternatives genuinely considered: <from the register's options or the directive, or UNKNOWN>
- Why they were rejected: <recorded, or UNKNOWN>
- Benefits and disadvantages identified: <recorded, or UNKNOWN>
- Assumptions: <recorded, or UNKNOWN>

## Consequences
Systems affected; constraints that now apply; what must not change without the owner; new dependencies or risks.

## Implementation
Tasks (register IDs), branches, commits, tests with counts and where they ran, Actions runs, current completion status.

## When to reconsider
The circumstances or evidence that would justify reviewing it. UNKNOWN if the owner set none; say who proposes any trigger.
```

## Permanent records versus CI artifacts (Part 4)

- GitHub Actions artifacts and logs expire. Durable conclusions (a defect's cause, a fix, a measurement, a verification
  result) are written into [`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md) and, for defects and
  investigations, [`docs/KNOWN_ISSUES.md`](../KNOWN_ISSUES.md), each with the run link. Raw logs and large archives are not
  committed.
- Every substantial CI run now writes a Markdown job summary and a `ci-report.json` (format `mml-ci-report/1`) artifact
  (`tools/ci_report.py`, used by `tests.yml` and `requirements.yml`; `long-sims.yml` and the flight-recorder workflows
  already wrote summaries). Those are for inspecting the latest runs; the repository documents are the permanent record.
- **Automation does not commit to code branches.** No workflow writes reports back into `wip/expansion20` or any branch
  under test, because a commit would change the SHA being validated. See the decision
  [HAG-MEM-02](HAG-MEM-02.md), "No automatic reporting branch for now".

## Index

| Record | Decided by | Status (register, 2026-11-02) |
|---|---|---|
| [HAG-MEM-02](HAG-MEM-02.md): GitHub as permanent memory, CI reporting, recorded reasoning | Owner | APPROVED, in implementation |
| [B25-BIZ-TENANT-Q](B25-BIZ-TENANT-Q.md): a tenant may build a standalone workshop (Option B) | Owner | APPROVED, integrated `3c7e45b` |
| [CHAPEL-PURPOSE](CHAPEL-PURPOSE.md): the chapel maintains itself, not enriches itself; 14-day line for food and money | Owner | APPROVED, integrated `8b203c5` |
| [X20-CHAPEL-FIX--food-line-6-day](X20-CHAPEL-FIX--food-line-6-day.md): 6-day food alms line | Lead agent (provisional) | SUPERSEDED by CHAPEL-PURPOSE |
| [FLIGHT-REC-01](FLIGHT-REC-01.md): "Run flight recorder" standing campaign | Owner | APPROVED, integrated `cad96c4` |
| [B25-OVN-0211](B25-OVN-0211.md): overnight autonomous development; never idle on one question | Owner | APPROVED (session directive) |
| [BRANCH-POL-01](BRANCH-POL-01.md): one code integration branch, short-lived worker branches | Owner | APPROVED. Its named branch `wip/expansion20` is no longer the development line: see the 2026-11-09 note below |
| [DEV-GOV-01](DEV-GOV-01.md): roadmap authority | Owner | APPROVED |
| [REGION-NAV-AD1](REGION-NAV-AD1.md): regional navigation architecture decision 1 | Owner | APPROVED (amended 2026-11-03) |

### Records reconstructed 2026-11-09 (HAG-FORENSICS-01)

Written after the events by the documentation agent, from GitHub (PRs, issue #4, commits, Actions runs), the owner's directives and
the lead session record. Each file says which. The three rows above (BRANCH-POL-01, DEV-GOV-01, REGION-NAV-AD1) existed but were
missing from this index; they were added at the same time.

**Note on BRANCH-POL-01 (2026-11-09, documentation agent).** Its rule text names `wip/expansion20` as the one code integration branch.
Since 2026-11-03 the owner's own directives have named the development line differently:
- "Branch: wip/b25r1" (2026-11-04);
- "Development branch: wip/b25r2-rev2" (2026-11-08).

Both are recovered in `docs/directives/2026-11-0{4,8}_recovered_owner_messages.md`. The record is not edited. The current line is
`wip/b25r2-rev2` (see `docs/CURRENT_DEVELOPMENT_STATE.md`). Whether to amend the rule text is for the owner and the lead
(coverage register HR-09).

| Record | Decided by | Status (register; proposed B25-AUD-* ids are listed in `docs/audits/2026-11-09_HISTORICAL_COVERAGE_REGISTER.md`) |
|---|---|---|
| [B25-AUD-BATCH-A](B25-AUD-BATCH-A.md): eleven audit corrections (PRs #5-#15) and the B25R2-BRUSHOFF fix | Owner (authorization); ChatGPT and lead (engineering) | merged `f0a854c` |
| [B25-AUD-LIFE-03-04](B25-AUD-LIFE-03-04.md): sage succession, widow remarriage, two integration defects | Owner | merged `229f76e` |
| [B25-AUD-PROP-06](B25-AUD-PROP-06.md): atomic departure settlement; PROP-03 eviction test | Owner | merged `96b071c`, test at `c9da5db` |
| [B25-AUD-JUS04-REG07](B25-AUD-JUS04-REG07.md): crime knowledge reaches relatives; one-year market intelligence | Owner (policy); ChatGPT (thresholds) | merged `53a56d3` |
| [B25-AUD-BACKLOG-2026-11-09](B25-AUD-BACKLOG-2026-11-09.md): LIFE-05, BIZ-03, BIZ-04, TRD-02, INV-04, INV-05, SAV-02; EMP-03 unchanged | Owner | merged `c9da5db` |
| [B25-CI-FLAKE-C9DA5DB](B25-CI-FLAKE-C9DA5DB.md): two net suites failing on CI judged a timing flake, re-run | Lead agent | applied; cause unknown |
| [B25-AUD-MP-05](B25-AUD-MP-05.md): mutual three-tier asset sharing, two cart defects, rebase | Owner (design); lead (fixes) | not merged; `242ca83` campaign running |
| [B25-VALIDATION-2026-11](B25-VALIDATION-2026-11.md): campaigns, gate reading, baseline `df67e8e` kept | Owner (baseline); lead (merge rule) | in force |
| [B25R2-PLAYTEST-FIXES](B25R2-PLAYTEST-FIXES.md): hosting for 4, cave follow, Host a game, stutter | Owner | on `wip/b25r2-rev2` since `fe7d8f8` |
