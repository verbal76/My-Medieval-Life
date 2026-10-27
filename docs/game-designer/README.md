> **HISTORICAL / SUPERSEDED DESIGN SOURCE — NOT ACTIVE DEVELOPMENT AUTHORITY (owner, 2026-10-27).** This file records early Game Designer interview material, a prototype decision or an obsolete design proposal. Retain it for provenance, not as a current specification, task list, owner approval or permission to implement features. Current guidance comes from `CLAUDE.md`, `docs/PROJECT_MEMORY.md`, `docs/requirements/requirements.json`, later applicable owner directives and validated game code. See `docs/directives/2026-10-27_39_decisions_current_first_reconciliation.md`. An old design idea needs new owner confirmation before becoming active.

# Game Designer ("Bob") spec: stored copies

This folder holds the corrected specification that the Game Designer tool ("Bob") generated for this game. The game
appears there under its working title, *The Well*. The owner supplied it on 2026-10-17 as
`The_Well_corrected_two_documents.zip` (owner message #27). It is stored here verbatim under register entry
REC-004 (`docs/requirements/requirements.json`).

| File | What it is |
|---|---|
| `THE_WELL_SPEC_v1.md` | Bob's build specification (his `CLAUDE.md`, renamed on storing so that agents working here do not load it as instructions; its bytes are unchanged), "Spec version 1 (Initial Build)", with the owner's interview answers in Part A |
| `MASTER_PROMPT.md` | Bob's prompt for an agent building the prototype from that specification |
| `CORRECTION_NOTES.md` | Bob's note on the 2026-10-17 interpretation correction and the decisions still open |
| `SPEC_RECONCILIATION.md` | Not Bob's. The project's comparison of the spec with what the repository records, item by item |

## Status: reference, not rules

- These files are a reference. They record what the owner answered in the Game Designer interview and what Bob
  recommended. They are not this project's rules or design.
- The repository's root `CLAUDE.md` is the single source of project rules. As it says, it wins where another document
  disagrees. Owner decisions and directives also win over the spec: `docs/DECISIONS.md`, `docs/directives/` and the
  register. `SPEC_RECONCILIATION.md` shows where the spec agrees with them and where it differs.
- A spec item is not approved because it appears here. Bob's recommendations (Parts B and C) and his defaults stay
  proposals until the owner decides. Open questions go to the owner and are recorded in the register.
- `THE_WELL_SPEC_v1.md` (Bob's `CLAUDE.md`) is Bob's document, not an instruction file for agents working in this
  repository. Its own text calls itself "authoritative" and asks to be read as the root `CLAUDE.md`. That does not apply
  here.

## Never edited

The three files from the owner's upload are byte-for-byte copies of the originals. They are never edited, corrected
or reformatted. Corrections and comparisons go in `SPEC_RECONCILIATION.md` or in the project's own documents.

| File | sha256 |
|---|---|
| `THE_WELL_SPEC_v1.md` | `eba65fb1d7df86e1a0f7b174494d51c8ce95604958e69423c77188280445a86d` |
| `MASTER_PROMPT.md` | `32a6c55718ecfe9615facc09b7432a95e458a2590451fee3caa82cc1c2300a8b` |
| `CORRECTION_NOTES.md` | `c152884b1898f356fc8760a50fab2b4e7de216e2abdf0c42182944c20ffe204e` |

## Not supplied

The handoff documents that Bob's spec refers to were never supplied to the project, so they are not here
(`CORRECTION_NOTES.md`; `docs/requirements/RECOVERY_2026-10-19.md`, "Coverage: Gaps (not covered, or only partly)"). These include
`docs/EXCLUSIONS.md`, `docs/REQUIREMENTS_LEDGER.md`, `docs/ARCHITECTURE_DECISIONS.md`, Bob's own `docs/GAME_DESIGN.md`
and `game-designer/project.json`.
