# Build 25 closure audit (2026-11-02)

Owner directive: `docs/directives/2026-11-02_complete_current_build_before_packaging.md` (B25-CLOSE-01), "complete the current
build, not package an incomplete development snapshot".

- **Scope authority:** B25-SCOPE-D1, `docs/directives/2026-11-01_build25_scope_clarification.md`. Build 25 is the consolidation
  build: all approved expansion work and all approved recoverable work.
- **Earlier audit this updates:** `BUILD25_RECONCILIATION.md` (2026-11-01). That audit's section C "missing scope" is re-checked
  below against the code and the register.
- **Note on the register's numbering:** its build keys are expansion numbers. The view `BUILD_25.md` is Expansion 25 (weather,
  not authorized). The consolidation build's records are the Expansion 20 records (`target_build` 20) plus the `B25-*` and
  FR records.

Integration branch: `wip/expansion20`. Frozen candidate SHA: see section 3.

## 0. Scope correction (owner, 2026-11-02, B25-SCOPE-REGION)

The regional economy and world navigation (REGION-NAV-01) is **mandatory Build 25 scope**. The scope correction is in
`docs/directives/2026-11-02_build25_scope_correction_regional_economy.md`, and the behaviour it adds is in
`..._regional_economy_navigation_envoys_master.md`.

**What it adds to the acceptance criteria:**
- multiple villages, generated and reachable;
- discovery, and travel by the player and by villagers;
- a toggleable world map;
- envoy surveys of every accessible owner and crafter, with their source;
- reports that reach the leadership and the people they concern;
- independent, negotiated trade between villages, with goods and money conserved;
- regional demand in the business-founding measurement;
- integrity and determinism;
- Android and desktop performance.

**Effect on the closure position:**
- The `4b51c92` freeze is superseded. `4b51c92` stays a tested baseline.
- Its two campaigns are baseline evidence, not final validation.
- Plan: `docs/region_nav/IMPLEMENTATION_PLAN.md`, on `wip/region-nav`.
- Final validation will be one consolidated Living Economy campaign after targeted validation of the whole scope.

## 1. Classification of every outstanding item

### A. Required for this build and unfinished

**Plus REGION-NAV-01 in full (section 0).**

| Item | What is missing | Why it cannot be finished now | Needs |
|---|---|---|---|
| LE-07 release-readiness gates. Gates 1, 4, 6, 9: NEEDS RUN; gate 11: NEEDS DEVICE; gate 10: register settling (`docs/expansion20/LE07_GATE_STATUS.md` on the source) | Gates 4, 6 and 9 need a year-long economy-on run. Gate 11 needs a mid-range Android phone. Gate 1 needs the full suites on the final SHA. | MML-CONSERVE-01 and B25-CLOSE-01: no 365-day campaign without owner approval. Gate 11 is a device check. | **Owner approval of one campaign**, plus a device check or an owner ruling on gate 11 (OD-LE-15 calls it "a target to profile, not a success claim"). |
| Living Economy activation by default (B25-LE-ACTIVATE-D1; B25-NINE acceptance: "Living Economy activated by default once the LE-07 readiness gates pass") | The one-line switch, with its wiki pages, applied after gates 1-12 pass | Waits on LE-07 | As above |
| X20-MERGED-VALIDATION (VERIFICATION FAILED on `ad281dc` because of X20-TELL-GUARD, which is now fixed) and the validation step of the Build 25 plan (a 30-day baseline, full suites including the network suites, year-long normal runs on seeds 1 and 2 and an economy run on seed 1) | Year-long runs on the final SHA | The same approval | The same campaign |
| X20-ECON-MATURE, X20-ECON-MATURE-REPORT, X20-ECON-LONGITUDINAL (economic maturation report, 16 charts, snapshots at days 1/30/90/180/270/365); X20-ECON-AFFORD | Not started; each is an analysis of year-long evidence | Needs that year-long evidence | The same campaign, then analysis |
| B25-BIZ-OWN acceptance ("whether villagers found, buy, sell, hire and expand on their own over a year") | The code is integrated, but no villager founds a business in the runs. The economic investigation traced this to demand (benches 2-20 % busy against a 0.35 founding threshold) and recorded owner questions **B25-ECON-P1..P5** | It is a balance question for the owner, not a defect | **Owner decisions B25-ECON-P1..P5**, or an owner ruling that zero founding is an acceptable outcome under WDR-022 |

### B. Implemented, awaiting integration or verification

| Item | State |
|---|---|
| KI-HOME-DOOR fix (FR-REPAIR-01) | Integrated `34e1041`. Verified by `home_ref_test` 40/0 and a 32-day seed 2 resume with 0 errors (against 447 on the old code). Rechecked on the candidate (section 3). |
| Farming Phase 2 (FARM-YIELD-D1, B25-NINE-D3; FSE-12, FSE-13, FARM-06) | **Integrated** in the candidate (section 3): yield 1.75, both switches on, old-save seed-corn start, wiki. Its year-long behaviour in the normal game is new and is covered by the proposed campaign. |
| KI-FR-CARTHITCH fix | **Integrated** in the candidate: the held cart is used; a skipped stop still parks the cart; villagers let go of carts on load. Covered by `home_test::test_cart_hitch_loop`. |
| B25-CAREER-IMPL, B25-CAREER-SYSTEM | **In the code** (skill-aware hiring and suitability, `npc_brain.gd` B25-CAREER-IMPL blocks, merged with B25-EMPLOY-IMPL at `265ddc1`). The register still says NOT STARTED, which is stale and is corrected now. Longitudinal verification needs the campaign. |
| B25-BIZ-D1..D5, B25-BUSINESS-IMPL, B25-EMPLOY-IMPL, B25-AMBITION-IMPL, EMP-PERM-01, CON-03..08, CHAPEL-PURPOSE, X20-CHAPEL-FIX, X20-TELL-GUARD, LE-05 remainder, P21-00..02 (Expansion 21 phase 1, switched off), FLIGHT-REC-01 | Integrated, with targeted tests passing. The full CI on `0d194c8` (run 41509578455) is green. Year-long verification is pending (A). |

### C. Investigated and legitimately closed

| Item | Conclusion |
|---|---|
| KI-FR-WHEATSALE (12 MEDIUM findings) | Expected market outcome: a wheat glut against small merchant demand (WDR-022). No code change. The analyser's classification is to be refined later, not in this build. |
| KI-FR-CONTRACTS (580 cancelled) | Expected: standing offers to an absent player in a run with no player. No code change. |
| KI-01 farming scarcity at yield 1.5 | Closed by calibration: yield 1.75, chosen by the pre-written rule from Dispatch B. |
| KI-REC-RUNNER | Closed by segmented flight mode. |
| X20-GO-BETWEEN, X20-JUDG-MIGRATION, X20-TRADER-PAY | Deferred by the owner (recorded decisions). |

### D. Explicitly assigned to a future build, or needing an owner placement answer

- **Explicitly assigned to a future build:**
  - Expansions 21 (beyond phase 1) to 27: not authorized (P21-MAYOR, WEATHER-01 and so on).
  - PL2-015 deferred-on-purpose farming items (BUYANIMALS, COOPS, HIRED, TRAP, WATER, OTHER), marked `20+`.
  - CRT-06 remainder (needs elections).
  - JUICE-JD2..JD5: open owner questions, presentation.
- **Owner placement still open (reconciliation Q2, never answered):** JOB-02, CON-02-KINDS, PIT-02, FSE-10. These are
  approvals that were never placed in any build. They are not counted as Build 25 scope until the owner says so; they are
  not built.
- **CHAPEL-LENDING:** the concept is approved and the proposal is written. Its acceptance asks only for the proposal ("nothing
  built until the design is approved"), and the nine owner questions are open.
- **X19-SWITCHES-D1:** an open owner decision (the judgment-weighted witness-report switch).
- **XEXPL-01:** not placed.
- **Open decisions that do not block this build's code:** CHAPEL-GIVE-14-Q, BRANCH-POL-Q1.

## 2. Scope ambiguities needing an owner decision

1. **Year-long validation campaign.** Required by LE-07, the Build 25 validation plan and the maturation report. The proposal is
   in section 4.
2. **B25-ECON-P1..P5.** Zero business founding. Either decide the balance questions, or rule that the outcome is acceptable
   for this build.
3. **LE-07 gate 11 (phone performance).** A device check by the owner, or a ruling that it is profiled rather than blocking.
4. **Reconciliation Q2.** Do JOB-02, CON-02-KINDS, PIT-02 and FSE-10 belong to Build 25? Recommendation: no, they are future
   scope, because they were never placed in a build.

## 3. Candidate and targeted validation

Filled in when the integration lands (see the changelog entry of the same date). Evidence reused:
- Tests run 41509578455 on `0d194c8`: the full `tests.yml`, green.
- The home-door evidence above.
- Farming Dispatch A and B (yield 1.75 food-secure on both seeds, with economy and farming on).

## 4. Proposed campaign (needs owner approval)

**One dispatch of `long-sims.yml` on the frozen candidate SHA.**
- Flight mode: seeds 1 and 2, 365 days, every 10, 100-day segments. This is the normal game, now with shared and seasonal
  farming on.
- One economy-on run (`--market`) on seed 1, 365 days.

**What it settles:**
- KI-HOME-DOOR and the cart-hitch fix at year length;
- the new farming default in the normal game;
- LE-07 gates 4, 6 and 9;
- the X20-MERGED-VALIDATION rerun;
- the input to X20-ECON-MATURE.

**What it reuses (not rerun):**
- the full CI on `0d194c8`, plus targeted suites for the three changes since;
- Dispatch B (yield 1.75 with the economy on, both seeds);
- the seed 1 flight year on `8acbdea` (clean) as the before-picture;
- the determinism and save gates already passed (LE-07 gates 2, 3, 5, 7, 8).

**Cost:** GitHub runner time only. On earlier evidence that is about 2-4 hours of wall time per seed. Claude reads the results
once.
