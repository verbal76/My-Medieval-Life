# Current development state — active handoff

**Updated 2026-10-31 (DOC-RECON-01).** Session state only; requirement status lives in the register
(`docs/requirements/requirements.json`) and the status records `docs/expansions/` (entry point `docs/expansions/README.md`).
Fetch current heads before acting. The previous handoff (2026-10-27 to 2026-10-31, with the full Expansion 20 worker history) is
archived at `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_to_2026-10-31.md`.

## Build 25 scope (owner, 2026-11-01, B25-SCOPE-D1; controls)

**Build 25 scope (owner, 2026-11-01, B25-SCOPE-D1, `docs/directives/2026-11-01_build25_scope_clarification.md`; controls):**
Build 25 is the consolidation build: all previously approved expansion work and all approved, recoverable work from abandoned or
superseded branches. Assigning work to Build 25 does not make it present; the read-only audit B25-SCOPE-AUDIT establishes what is.
The 2026-10-31 sequence below is preserved as history; its Build 26 recovery assignments no longer control Build 25 scope.

**B25-SCOPE-AUDIT** (lead): reported 2026-11-01, `docs/release/build25_reconciliation/BUILD25_RECONCILIATION.md`: SCOPE INCOMPLETE,
specific approved work missing (section C). Plan: `docs/release/build25_reconciliation/IMPLEMENTATION_PLAN.md`.

**Owner decisions 2026-11-01** (`docs/directives/2026-11-01_career_business_employment_final_decisions.md`): B25-CAREER-D1, B25-BUSINESS-D2,
B25-EMPLOY-D3, B25-AMBITION-D4, all APPROVED for Build 25 implementation (B25-CAREER-SYSTEM and children).

**REDUCED-RESOURCE MODE (owner 2026-11-01, resource directive; until the owner restores normal priority):** one Claude coding worker
at a time; no new agents; computation through GitHub Actions (`long-sims.yml`: seeds, days, every, set, variants, sim_args; read results
from compact lines, not raw logs); minimal reporting. Build 25 source now `265ddc1` (skilled employment merged). Next active worker after the reset: business founding and permanent
employment (none running now). Suspended at a safe checkpoint with "WIP (suspended):" commits pushed to their
branches: wip/b25-juice, wip/b25-report, wip/b25-materials, wip/b25-capability, wip/b25-services (each from `2c0a780`; heads juice `efd0cd0` untested beyond its own test, report `f15faf8` partly tested,
materials `041a67c` untested, capability `f891a11` partly tested, services `68df430` does not compile yet; worktrees kept under
`.claude/worktrees/agent-*`). No GitHub Actions jobs running. Resume order after the reset:
business founding and permanent employment; then the suspended branches one at a time (finish, targeted tests, merge); then farming
yield by simulation (Actions variants of shared_wheat_yield), LE-07 gates on the integrated candidate and economy activation
(B25-LE-ACTIVATE-D1), validation once at the end (Actions: 30-day gate, full suites, year-long runs), packaging only on owner authorization.

**Next actions (Build 25):** Build 25 source `wip/expansion20` at `2c0a780` (chapel, instrumentation, gossip fix, civic records,
recovered documents, career ambition `7dfd3d5`, Living Economy remainder `63c0144`, save continuity `2c0a780`). Owner decisions of
2026-11-01 recorded: B25-CAREER-D1..B25-AMBITION-D4, B25-NINE-D1..D9, B25-LE-ACTIVATE-D1 (economy on by default once the LE-07 gates
pass). Workers (each on its own branch from the Build 25 source; merge one at a time after targeted tests):
wip/b25-employ (skilled places without fixed headcount, skill-aware hiring; from `7dfd3d5`), wip/b25-juice (J1+J2),
wip/b25-report (witness reporting), wip/b25-materials (Decisions 5-7), wip/b25-capability (Decisions 1 and 8),
wip/b25-services (Decision 2, CON-03..08). Still to start: business founding and permanent employment (after employ), farming yield
by simulation (Decision 3, after the economy work is merged), LE-07 gates on the integrated candidate then economy activation,
validation once at the end (new 30-day baseline, full suites incl. network, year-long runs), packaging on the owner's authorization.

## Historical build sequence (owner, 2026-10-31, BUILD-SEQ-25-27; superseded for Build 25 scope by B25-SCOPE-D1)

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
- **Build 26 scope additions (owner 2026-10-31, `docs/directives/2026-10-31_doc_recon_review_decisions.md`):** planning,
  reconciliation and dependency analysis (not implementation) of LE-07, EMP-PERM-01, the LE-05 remainder and economy activation
  preparation; recovery of Expansion 21 phase 1 without activating political gameplay. The economy stays disabled by default.
- **Build 27:** Expansion 21 only after Build 26 is frozen and the owner explicitly authorizes it.

## Documentation

- **DOC-RECON-01** (lead): documentation reconciliation reviewed by the owner at `3098a5f` (2026-10-31); stays isolated until the owner authorizes integration; owner decisions of that review recorded on top, on the isolated branch `wip/requirements-control` (REQ-CTRL-02). It is
  not merged into staging or the gameplay baseline without the owner's authorization.
- **DOC-AUTH-01:** a revised owner specification set will supersede older design documents on the owner's explicit final
  approval, not before.

- **X20-ECON-SUSTAIN** (lead): economic sustainability analysis of the Build 25 runs; per-checkpoint samples come from a read-only
  recover job on `wip/val-recover` (`885723b`, workflow change only, no simulation). Analysis scripts in the report's appendix.
- **X20-CHAPEL-FIX** (lead, implemented on task branch, owner directive 2026-11-01): voluntary chapel giving through the decision
  framework, an operating reserve and hardship-based alms, on `wip/x20-chapel` at `ae8641d` (also `wip/x20-chapel-econ`, same commit);
  `wip/expansion20` unchanged. Year-long comparison done (Actions 41279031310, 41279051834): chapel share 77-83% -> about 1%, median
  household cash 4-11 -> 161-203 coins, leaks 0. Report `docs/release/chapel_fix/chapel_report.html`. Waiting for the owner's review;
  merging into the Build 25 source needs the owner. All script errors in the runs are X20-TELL-GUARD (12 in the economy-on run).

## Next actions

1. When 41233948995 and 41233970504 finish: the consolidated validation report, then stop for the owner's review.
2. Owner decisions open from the reconciliation: see `docs/requirements/views/DECISIONS.md` and the "Outstanding owner
   decisions" section of each `docs/expansions/` file.
3. No new expansion work. Expansions 22-27 are not authorized; Expansion 21 waits for Build 27.
