# Build 25 consolidation: implementation plan (dependency order)

From the reconciliation (`BUILD25_RECONCILIATION.md`, section C) and the owner's 2026-11-01 decisions (B25-SCOPE-D1, B25-CAREER-D1,
B25-BUSINESS-D2, B25-EMPLOY-D3, B25-AMBITION-D4). Each workstream is done on its own `wip/` branch from the Build 25 source, with targeted
tests, and integrated into `wip/expansion20` (the Build 25 source) one at a time. Heavy validation runs once, on the integrated result.

## Step 0: integrate what is ready (no dependencies)

- Chapel correction, observation-only instrumentation (proven neutral) and the gossip fix: `wip/x20-tell-guard` (`552febf`), a
  fast-forward of `wip/expansion20`. After the judgment, history, family and bandit suites pass on it. The previous source `ad281dc`
  stays reachable as the rollback point.

## Workstream 1: career system (sequential inside, the critical path)

1a. **Ambition on, mappings corrected** (B25-AMBITION-IMPL): verify each profession's skill against the recipes and work acts
    (carpenter → carpentry, tanner → tanning, farmer → farming, stonecutter → masonry, as SKILL-TRADES-18 moved the work), in the
    ambition layer's own mapping; switch on `aspiration.enabled` and `integration.job_choice` only. Targeted: aspiration and job choice tests.
1b. **Skilled places without fixed headcount** (B25-EMPLOY-IMPL): replace `staff_target` (starting count) with places derived from real
    signals: free workplace capacity (forge, anvil, bench), unmet demand the game already records (traders unable to buy, open needs,
    orders), and the employer's ability to pay; places can close when demand and money go. Skilled trades enter `job_market`.
1c. **Skill-aware hiring and career decisions** (B25-CAREER-IMPL): `seek_work` and `pick_job` weigh skill and growth (the existing job
    choice profile) for those who are not in need too, at a slow pace; vacancy filling (`_apprentice_for`) weighs candidates' skill and
    allows candidates from other trades; retraining by learning on the job. No promotion at a threshold (X18-D3).
1d. **Apprenticeship and professional standing** (B25-CAREER-IMPL): needs owner decision Q1 below for the meaning of the titles;
    training by working beside a skilled worker.

## Workstream 2: business formation and employment (after 1b)

2a. **Independent business founding** (B25-BUSINESS-IMPL): a qualified, motivated villager with capital weighs opening a workshop
    (rent or buy an existing building through the property rules, or build through the construction rules), its tools and stock bought
    through the normal trade; a till of its own (existing business money rules). Demand and competition from existing signals. Can fail
    and close (existing failure and succession paths).
2b. **Businesses employing workers**: an owner-run business opens places (feeding 1b) as its sales justify and its till can pay;
    wages through the existing wage paths. Overlaps permanent employment (EMP-PERM-01, the player employing villagers) which shares the
    employment record.

## Workstream 3: Living Economy remainder (independent of 1 and 2; economy stays off by default)

LE-05 remainder (paid commercial repair, route risk, construction hiring, `World.transactions` links); services under the existing
switch; activation preparation (calibration evidence, dependency check); LE-07 release-readiness gates.

## Workstream 4: Expansion 21 phase 1 port (independent)

Port `8ac88f5` (civic offices and records, data, test, documents) from the Build 18 base to current code, civic switch off; no political
gameplay.

## Workstream 5: documents (independent, documentation only)

Trader analysis and `--trader-diag` (`3f58ce6`), JUICE-00 (`bebf1f3`), ROAD-02 sources (`e1e8236`), the register and directives into the
Build 25 source (the integration of `wip/requirements-control`, which the owner keeps isolated until authorized).

## Validation (after the workstreams are integrated)

Targeted tests per workstream; then a new 30-day baseline (three identical runs), the full suites including the network suites outside
`tests.yml`, and year-long runs (normal seeds 1 and 2, economy on seed 1) with the development snapshot and an observation-only career
panel (per person: job, skills, earnings at each checkpoint; job changes with reason), read at days 1, 30, 90, 180, 270, 365.

## Parallel work

Workstreams 3, 4 and 5 can run beside workstream 1 on separate branches; workstream 2 waits for 1b. Integration is sequential.

## Owner decisions needed (only these block specific parts)

- **Q1 (blocks 1d only):** what the titles mean. Option A (recommended): titles are roles. An apprentice works and learns under a
  skilled worker at lower pay; a journeyman is an employed skilled worker; a master may run a workshop and take apprentices. A villager
  becomes eligible through skill and experience and takes the role only through an opportunity and their own decision. Option B: titles
  stay descriptive only (X18-D3 as is), and the career differences come from the places and businesses in 1b to 2b.
- **Q2 (blocks section C item 15 only):** do approvals never placed in any build (JOB-02, CON-07, CON-02-KINDS, CON-03..06, CON-08, PIT-02,
  FSE-10, PL2-015-BUYANIMALS) belong to Build 25?
- **Q3 (blocks C14 only):** FARM-YIELD-D1 (the farming yield behind the shared and seasonal farming models).
- **Q4 (not blocking):** the judgment-weighted witness report switch (the remaining part of X19-SWITCHES-D1).
