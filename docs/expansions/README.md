# Expansion status records: the authoritative entry point for what is designed, built and remaining

Owner directive 2026-10-31 (`docs/directives/2026-10-31_documentation_reconciliation.md`, register DOC-RECON-01). One file per
expansion (17-27), one for multiplayer and one for standalone approved systems. Each states the current approved scope,
what is implemented, partial, remaining, deferred or superseded, the open owner decisions, dependencies, evidence and the
next authorized phase. The requirements register (`docs/requirements/requirements.json`) holds the same statuses; when
these files and the register disagree, the register's latest history line with an owner source wins and the file is
corrected.

## Precedence (owner, 2026-10-31)

1. Latest explicit owner decision (`docs/directives/`, register `owner_answer` / owner approval).
2. Later owner-approved amendments and clarifications.
3. Current approved expansion specifications.
4. Earlier approved specifications.
5. Historical proposals, agent recommendations and superseded plans.

A newer agent recommendation never overrides an owner decision. A document is not authoritative because it sits on the
active branch. Where two owner decisions conflict and the later cannot be established, the conflict is listed for the
owner, not resolved by an agent.

## Status vocabulary (used in every file here)

| Status | Meaning | Register fields |
|---|---|---|
| IMPLEMENTED | Built and integrated; evidence: commit and tests (and validation where run) | implementation INTEGRATED (verification as recorded) |
| PARTIAL | Some approved parts built; the file says what remains | PARTIALLY IMPLEMENTED |
| APPROVED, NOT IMPLEMENTED | Owner-approved and authorized, not built | approval OWNER APPROVED, implementation NOT STARTED |
| DESIGN ONLY, NOT AUTHORIZED | Design approved or proposed; implementation not authorized | e.g. Expansions 22-27, [FUTURE] answers |
| DEFERRED | Owner deferred | approval DEFERRED or disposition DEFERRED |
| SUPERSEDED | Replaced by a newer decision (named) | approval SUPERSEDED or disposition SUPERSEDED |
| OPEN DECISION | Waits on the owner | OWNER DECISION REQUIRED, or an open decision record |

Validation is stated separately: code existing is not validation, and a missing test is not missing functionality.

## Build and expansion numbers

Build numbers are release checkpoints; expansion numbers are design scopes (owner, 2026-10-31, BUILD-SEQ-25-27). The
register's views named `BUILD_NN.md` are by expansion number. Current sequence: Build 25 = Expansion 20 validation and
freeze; Build 26 = repository recovery and consolidation; Build 27 = Expansion 21 begins, only on the owner's explicit
authorization.
