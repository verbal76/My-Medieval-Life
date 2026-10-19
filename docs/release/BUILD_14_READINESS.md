# Build 14 readiness (2026-10-19)

Answers part I of the owner's directive `docs/directives/2026-10-19_build14_readiness_requirements_preservation.md`.
The owner authorised Builds 14, 15 and 16 on 2026-10-19 ("For builds 14,15,16 of all test come back green you have my
permission to push the 3 build package for each"), as private draft releases (`docs/DECISIONS.md`).

## Candidate

- **Commit:** the staging commit that adds this report. Its game code is identical to `386498b` (the readiness work
  since then is documents, the register and Python tools). The packet (`BUILD_14_PACKET.md`) names the exact hash.
- **Contents:** single player only. Multiplayer stays on `wip/multiplayer` and is not in the build.
- **Changes since Build 13:** listed for testers in `BUILD_14_TESTER_NOTES.md`.

## Simulations (B14R-01)

Full results are in `LONG_RUN_SIMULATION.md`, section "Build 14 candidate".

**100 days, seeds 1 and 2:**
- Money, every item and every animal kind balance exactly.
  - The first runs showed 15 "leaks". All were ledger gaps, not duplication, and `a5cf3e8` closed them.
- No starvation. All deaths are of old age.
- The currency grows about 1.8 times, against about tenfold a year under Build 7 rules.
- Unemployment rises to 24 (seed 1) and 13 (seed 2). Missed meals: 738 and 234, from money, not supply.
- Wildlife collapses, from 54 to 6 and 2.

**365 days (seed 1):**
- Population falls from 100 to 69.
- Wildlife reaches 0 by day 320.
- No house is built.
- Recorded as B14R-12. The wildlife part is what the approved breeding refuges (WR-01) address. The population and
  housing part is a slow decline over about 45 game years and is not reached in normal play.
- It does not block a test build, and it is listed in the tester notes.

## The two economy changes made without an owner decision (B14R-02)

Four configurations, plus two moderate caravan settings, are in `LONG_RUN_SIMULATION.md`.

**Manor reserve (B7-009):**
- More paid manor work and fewer missed meals.
- No effect on the money supply.
- Recommendation: keep it.

**Caravan money limit (B7-014):**
- Stops the runaway money supply: 5,217 coins at day 100 with it, against 11,639 without.
- It also cuts the caravan's buying, so laborers earn less and missed meals rise.
- Recommendation: keep it, and consider an allowance of 30 coins a day (missed meals 589, coins 5,913 in one run).

Both stay with the owner; Build 14 ships the current settings.

## Deposits running out by day 10 (B14R-03)

Investigated without changing the resource model.

**What happens:**
- Iron ore (300), coal (200), copper ore (60) and gold ore (8) are worked out by about game day 10, about two hours of play.
- Stone lasts to about day 40–100.

**Causes**, from `ECONOMY_SUSTAINABILITY_PROPOSALS.md` section 1, confirmed by the new runs:
- Miners mine whenever a merchant's stock is under a fixed cap, with no demand check and no quota.
- In the first ten days the caravan also buys the surplus (57 iron bars exported).

**Effect:**
- No production stops: after day 10 the caravan sells ore (401 iron ore, 235 coal, 109 copper ore over 100 days), and
  the forge makes 330 bars.
- The player can no longer mine these locally.

**Sustainable options** (unchanged, awaiting the owner as OD-1/B7-007):
- P1.1: demand-driven mining.
- P1.2: the manor's mining rights and quotas.
- P1.3: a finite regional caravan market.
- P1.4: prospecting for a finite set of hidden seams.
- P1.5: a distant quarry.

Bigger deposits are not proposed.

## Saves

- The format is unchanged (version 14).
- A save made by the Build 13 code (`4e76f72`) loads, runs, re-saves and reloads in the candidate code.

## Tests

All suites must be green on the exact commit before the build is triggered:
- the Python suites and generators of CLAUDE.md section 5;
- `check_requirements.py`;
- every Godot suite, run locally;
- the CI run of `tests.yml` on that commit.

The results are recorded in the packet.

## Not verified

- No phone, tablet, controller or Windows PC has been used. The device checks are the register's real-device
  verification queue (`docs/DEVELOPMENT_LEDGER.md`).
- **Android signing:** the stable test-key secrets still do not exist (`ANDROID_SIGNING.md`).
  - The APK is signed with a throwaway key, as every build so far.
  - Installing it over an earlier build fails, so testers must uninstall first, which deletes the phone's save.
