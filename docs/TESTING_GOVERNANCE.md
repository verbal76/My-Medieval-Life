# Testing governance: verify the test itself (TEST-GOV-01)

Owner directive 2026-11-06, `docs/directives/2026-11-06_permanent_testing_governance_and_test_audit.md` (verbatim).
Permanent: it applies to every agent and every session, and survives handoffs. Referenced from `CLAUDE.md` section 5.

## Why it exists

A red test says only that something did not meet an assertion, a comparison, a threshold or an execution requirement.
It is not by itself evidence that the game is wrong, and a green test is not by itself evidence that the game is right.
During Build 25 Revision 2 both happened: a chapel save test reported PASSED after a script error had stopped it (nine
checks never ran), a stuck-travel test could pass without ever reaching its stuck case, and simulation baseline
differences from an approved feature looked like failures. The goal: **every green test meaningful, every red test
trustworthy**; never every test green.

## Classify every failure (from evidence, never by guess)

| Class | Meaning |
|---|---|
| A. Game defect | The game breaks an approved rule: state, resources or progress wrongly lost or created; a system failing under valid play; a save/load changing state; determinism broken without an approved reason. |
| B. Outdated or wrong expectation | The test expects an older behaviour, conflicts with an approved change, measures an implementation detail, or assumes a particular entity, cell, order or state. |
| C. Defective test procedure | Wrong setup or fixture, wrong target, invalid assumptions, missing prerequisites, wrong comparison, the intended path not exercised, assertions silently skipped, success reported after a script error or early stop. |
| D. Infrastructure failure | Timeout, resources, CI configuration, a missing dependency or artifact, environment differences, orchestration, results collected or reported wrongly. |
| E. Legitimate evolution | An approved change gives different but valid results: a new world-generation version, a baseline from an earlier approved configuration, changed rules. |
| UNRESOLVED | The cause is not yet known: keep investigating; never close it by assumption. |

A failure may have several causes: record each one.

## Investigate before changing anything

Answer all three, with evidence:
1. **Is the game behaving correctly?** Against the approved rules, the register, the directives and the intended play.
2. **Is the test correct?** Setup, fixtures, assertions, the path it really runs, what it covers, how it reports. Does it
   reach every assertion? Can an error make it pass?
3. **Is the baseline or expectation applicable?** The world-generation version, save format, simulation rules and
   configuration it belongs to. The newest baseline is not automatically right.

## Correct

- The game is wrong: fix the game. The test is wrong: fix the test. Both: fix both. Infrastructure: repair it and rerun
  what it affected.
- Never weaken an assertion, widen a tolerance, remove a check or drop a failing seed to make CI green.
- A legitimate change to acceptance criteria is justified and documented (the test's comment, `docs/DECISIONS.md`).
- Where practical, show the corrected test catches the original defect (it fails on the old code or on an injected
  defect, then passes on the repair).

## Baselines (simulation baselines, golden hashes, fingerprints)

- Never re-recorded automatically or to get a pass. A baseline change needs the approved behavioural reason, established
  first (which approved change moved which value, shown by evidence such as a bisection) and the owner's permission
  (`tools/sim_gate.py --write` needs it; CLAUDE.md).
- A world-generation version keeps its own pins: an older generation's evidence is never overwritten for a newer one
  (`water_test` keeps GOLDEN_7 for Build 34's worlds beside generation 8's).

## Regression

After any correction: the corrected test, the suites covering the touched code, and the full suite before a build
candidate. A test that stops early must fail: a script error inside a test is a failure, not a pass.

## Reporting

Every failure report names its class, its evidence (commit, run, log line, reproduction), what was changed and why, and
what remains unverified. Counts, not percentages. A green automated suite is never reported as proof of behaviour on real
hardware or controllers: those stay owner playtest items.
