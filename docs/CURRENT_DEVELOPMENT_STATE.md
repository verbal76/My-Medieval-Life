# Current development state — active handoff

**Updated 2026-10-31 (DOC-RECON-01).** Session state only; requirement status lives in the register
(`docs/requirements/requirements.json`) and the status records `docs/expansions/` (entry point `docs/expansions/README.md`).
Fetch current heads before acting. The previous handoff (2026-10-27 to 2026-10-31, with the full Expansion 20 worker history) is
archived at `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_to_2026-10-31.md`.

## Build sequence (owner, 2026-10-31, BUILD-SEQ-25-27)

- **Build 24** (`4611d86`, tag `build-24`): latest private three-platform draft. Frozen; never altered. Builds 22 and 23 frozen.
- **Build 25** (Expansion 20 validation and freeze): `wip/expansion20` at `ad281dc9431b782582513ef8a083c962b5039b8f`.
  - Integrated: LE-00..04 and LE-06, LE-05 partial (repair in normal play; rental behind the switch), food trade, trader
    reopening, all eight Build 24 review findings, multiplayer Batch D and integrity tests, bandit intelligence, judgment
    calibration C1-C5, wear transfer, opening splash.
  - The economy is OFF by default; no release is authorized.
  - 30-day baseline replaced at `ad281dc` (three identical local runs; conservation exact).
  - **X20-MERGED-VALIDATION** (lead): Actions 41233948995 (normal settings, seeds 1 and 2) and 41233970504 (economy on, seed 1)
    on `ad281dc`, dispatched 2026-10-31 19:22 UTC. Report per `docs/directives/2026-10-31_x20_yearlong_validation_release_readiness.md`,
    then STOP for the owner's review. Never rerun, cancel or duplicate these runs.
  - **X20-COMPLETE** (lead) stays in development: remaining LE-07, EMP-PERM-01, the LE-05 remainder and economy activation.
    Where they go after the Build 25 freeze is an open owner decision (X20-REMAINING-PLACEMENT).
- **Build 26** (repository recovery and consolidation): a separate branch from the exact frozen Build 25 SHA.
  - Bring staging's directives and register together with `wip/expansion20`'s code and notes. They diverged at `5b82a69`:
    446 commits only on staging, 678 only on `wip/expansion20`. The `wip/expansion20` register copy (789 records) holds
    nothing staging lacks.
  - Recover the stranded work: `wip/expansion21-preparation` (`8ac88f5`), `wip/roadmap-docs` (`e1e8236`),
    `wip/x20-trader-inv` (`3f58ce6`), `wip/juice-assessment` (`bebf1f3`).
  - Not started; needs the Build 25 freeze first.
- **Build 27:** Expansion 21 only after Build 26 is frozen and the owner explicitly authorizes it.

## Documentation

- **DOC-RECON-01** (lead): documentation reconciliation on the isolated branch `wip/requirements-control` (REQ-CTRL-02). It is
  not merged into staging or the gameplay baseline without the owner's authorization.
- **DOC-AUTH-01:** a revised owner specification set will supersede older design documents on the owner's explicit final
  approval, not before.

## Next actions

1. When 41233948995 and 41233970504 finish: the consolidated validation report, then stop for the owner's review.
2. Owner decisions open from the reconciliation: see `docs/requirements/views/DECISIONS.md` and the "Outstanding owner
   decisions" section of each `docs/expansions/` file.
3. No new expansion work. Expansions 22-27 are not authorized; Expansion 21 waits for Build 27.
