# Expansion status records: the authoritative entry point for what is designed, built and remaining

Owner directive 2026-10-31 (`docs/directives/2026-10-31_documentation_reconciliation.md`, register DOC-RECON-01). One file per
expansion (17-27), one for multiplayer and one for standalone approved systems. Each states the current approved scope,
what is implemented, partial, remaining, deferred or superseded, the open owner decisions, dependencies, evidence and the
next authorized phase. The requirements register (`docs/requirements/requirements.json`) holds the same statuses; when
these files and the register disagree, the register's latest history line with an owner source wins and the file is
corrected.

## Pending authority switch (owner, 2026-10-31, DOC-AUTH-01)

The owner is preparing a revised, complete set of expansion specifications
(`docs/directives/2026-10-31_document_authority_replacement_policy.md`). When the owner explicitly approves the FINAL set,
it becomes the sole authoritative specification and these status records are re-based on it. Older documents then become
historical evidence only: nothing is reintroduced from them, omissions are asked about, and code differences are
reported, not changed. A draft does not switch authority. Until the switch, the precedence below applies.

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

## Register changes made from these files (2026-10-31)

The register corrections these files proposed were applied on `wip/requirements-control` (commit `1c9f7db`, with a history line
each), with four exceptions:
- WIKI-B17 stays unchanged until its completion is confirmed;
- DVW-B3-HERIOT was not added, because the owner did not choose heriot on 2026-10-23;
- P21-03..P21-05 are recorded as aliases of VP-01A..E, not as new records;
- E25-OD-07 is PROVISIONAL until the owner confirms it.
Where a file still says a record is PROPOSED, that is the record's own approval status (an agent or owner-starter proposal),
not a pending correction.
