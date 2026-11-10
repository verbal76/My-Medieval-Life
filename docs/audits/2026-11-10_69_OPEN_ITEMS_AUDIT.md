# Status audit of the original 69 open items (B25-AUDIT-69-01)

Owner directive 2026-11-10 (`docs/directives/2026-11-10_69_open_items_audit.md`). Reporting only: no status was changed, nothing
merged, no baseline accepted. Prepared by the lead, 2026-11-10 ~17:30 UTC (12:30 EST).

## The original list

- **Document:** the owner's *Hot Attic Games — Independent Audit Open Items Register* v14, established 2026-11-08, saved verbatim
  as `docs/audits/2026-11-08_INDEPENDENT_AUDIT_OPEN_ITEMS_v14.md` (commit `02ad7aa`, 2026-11-08 07:33 UTC, branch
  `wip/requirements-control`) and as `docs/audits/2026-11-08_build25_master_audit_register.md` (commit `83e2994`, branch
  `docs/build25-audit-register`, whose later commits append engineering-status sections; latest `cfed787`).
- **Audited code:** `wip/b25r2-rev2` @ `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122`.
- **Count, as the register states it:** 6 EMP + 8 BIZ + 5 TRD + 6 INV + 6 SAV (SAV-01..05 and DOC-SAV-01) + 5 NPC + 5 LIFE + 8 REG +
  4 JUS + 7 MP + 6 PROP + 3 requirement references (REQ-JOB-02, REQ-B17F-JOBS, REQ-LE-03) = **69**. "These are NOT 69 confirmed bugs."
  All 69 are listed below with their original IDs; none was combined, dropped or redefined. Newer findings (F015, p:99, meal
  claims, household member ids, clan children, contract funds, phantom repair) are **not** among the 69 and are not counted.

## Evidence used

- Development line `wip/b25r2-rev2` @ `9fd18a5` (strict Tests 42774872922: 271 suites, 0 failed), commit history `fe7d8f8..9fd18a5`.
- Batch 3+4 merge candidate `fbfd6ad` (not merged; Tests 42788023867: 277 suites, 0 failed; gate 42788012219: the 33 baseline
  findings; campaign 42788018729: both seeds 365/365, 0 CRITICAL, 0 confirmed).
- Engineering-status sections of the master audit register (`cfed787`), the requirements register, PRs #5-#15/#19-#21 (merged
  `f0a854c` and later), code on `9fd18a5`.

**"Completed and verified"** below means: on the development line `9fd18a5`, with a failing-first test and the strict suite green
on a merge that also had a recorded 365-day campaign (0 CRITICAL, 0 confirmed). **Common caveat for every item on the development
line:** the simulation gate has been red since `df67e8e` with baseline-difference findings no owner has accepted (the 33 under
review); no item is owner-playtested; multiplayer items have no two-device test.

## Summary count

**Original open items: 69**

| Status | Count |
|---|---:|
| Completed and verified | 40 |
| Implemented, awaiting integration | 3 |
| Integrated, awaiting verification | 1 |
| In progress | 0 |
| Blocked | 4 |
| Not started | 21 |
| Superseded or no longer applicable | 0 |
| **Total** | **69** |

## Full reconciliation

| # | ID | Original finding (short) | Status | Commit / branch | Validation evidence | Outstanding | Dependency / blocker |
|---:|---|---|---|---|---|---|---|
| 1 | MML-EMP-01 | Succession may retrain a permanently employed NPC, leaving the employment record | Completed and verified | `7438665`, merged `72729e5` | Tests 42734267343, gate 42734190370 (baseline only), campaign 42734194963 | - | gate baseline |
| 2 | MML-EMP-02 | Mid-day save/load resets `earned_at_dawn` / `laboured_today` | Completed and verified | covered by SAV-02 `f67afdb`, merged `c9da5db` | sav02_day_state_test checks both maps after load (6/0, 4 red before); strict 42607051457, campaign 42627103286 | - | gate baseline |
| 3 | MML-EMP-03 | Hiring competition counts the wrong seekers | Completed and verified | `00e47a6`, merged `72729e5` | as #1 | register record stale (see D) | gate baseline |
| 4 | MML-EMP-04 | `skilled_place` sums time across stations, picks one | Not started | - | - | multi-station capacity reproduction | - |
| 5 | MML-EMP-05 | Unguarded `w.fields[0]` with zero fields | Not started | - | - | establish reachability, test | - |
| 6 | MML-EMP-06 | Unemployed excluded from `_day_labour` (intent?) | Not started | - | - | intent review against FAMILY-01 | - |
| 7 | MML-BIZ-01 | Founding ends employment before the business opens | Completed and verified | `82da3c6`, merged `72729e5` | as #1 | - | gate baseline |
| 8 | MML-BIZ-02 | Expansion pays for premises before the purchase is confirmed | Completed and verified | `82da3c6`, merged `72729e5` | as #1 | - | gate baseline |
| 9 | MML-BIZ-03 | Owner withdrawals before payroll; hiring budgets one wage (owner decision: option B) | Completed and verified | `93327ae`, merged `c9da5db` | strict 42607051457, campaign 42627103286; register INTEGRATION VERIFIED | - | gate baseline |
| 10 | MML-BIZ-04 | Venture tills escheat on migration (owner decision: household keeps them) | Completed and verified | `3e9b9a1`, merged `c9da5db` | as #9 | - | gate baseline |
| 11 | MML-BIZ-05 | Venture hand also hired as employee | Completed and verified | `2c05696`, merged `72729e5` | as #1 | - | gate baseline |
| 12 | MML-BIZ-06 | Venture close could erase a till if the final transfer fails | Not started | - | - | forced-refusal test; harden only if reachable | - |
| 13 | MML-BIZ-07 | Venture hand employed by a player keeps hand privileges | Not started | - | - | exclusivity rule + test (related to BIZ-05) | possibly an owner rule |
| 14 | MML-BIZ-08 | Hand ids as floats after load | Completed and verified | `4761957`, merged `e44d6b8` | Tests 42726254015 green; campaign with `72729e5` | - | gate baseline |
| 15 | MML-TRD-01 | Guest stall settlement assigns a PlayerState to NPC | Completed and verified | `1fa94b5`, merged `e44d6b8` | as #14 | two-device check not done | gate baseline |
| 16 | MML-TRD-02 | Merchant earnings gross, not net of commission (owner: net) | Completed and verified | `36fa011`, merged `c9da5db` | as #9 | - | gate baseline |
| 17 | MML-TRD-03 | Player claims count chest goods, transactions do not | Not started | - | - | reachability, test | - |
| 18 | MML-TRD-04 | Shipment with no room at either end stays open | Not started | - | - | capped-store test, recovery | - |
| 19 | MML-TRD-05 | Comments say the Living Economy is off | Completed and verified | `85ad919`, merged `93bb304` | Tests 42764399707 (269/0); docs/comments only | - | - |
| 20 | MML-INV-01 | Player stash missing from the goods census | Completed and verified | `35f241c`, merged `e44d6b8` | as #14 | - | gate baseline |
| 21 | MML-INV-02 | Stash, homestead chest, courier stores never spoil | **Blocked** | proposal `906f1a8` on `wip/b25-inv02-proposal` (off by default, not code for merge) | investigation report `docs/design/INV02_SPOILAGE_PROPOSAL.md` | implementation after decisions | **seven owner decisions** (storage classes, settlement spoilage, courier food, base rates, offline guest, most-perishable-first, preserving); B25-INV02-SPOIL-D1 approved in principle |
| 22 | MML-INV-03 | Any player gets "own" access to another player's stash | Completed and verified | PR #14, merged `f0a854c` | strict 42519022430, campaign 42515726815 | two-device check not done | gate baseline |
| 23 | MML-INV-04 | Stash goods unreachable after a lease/ownership change (owner decision) | Completed and verified | `969a8f4`, merged `c9da5db` | as #9 | - | gate baseline |
| 24 | MML-INV-05 | Rubble returned as dressed stone (owner: no conversion) | Completed and verified | `e42a37f`, merged `c9da5db` | as #9 | - | gate baseline |
| 25 | MML-INV-06 | Worn tools restored in barter/credit/restitution | Completed and verified | `916db07`, merged `72729e5` | as #1 | - | gate baseline |
| 26 | MML-SAV-01 | `food_days` not saved; famine lapses after reload | Completed and verified | PR #11, merged `f0a854c` | as #22 | - | gate baseline |
| 27 | MML-SAV-02 | Hour caches and market snapshot not saved (owner: preserve) | Completed and verified | `f67afdb`, merged `c9da5db` | as #9 | - | gate baseline |
| 28 | MML-SAV-03 | Reservation maps cleared on load (counters, farm, business, chapel, fauna) | **Implemented, awaiting integration** | counter part merged `e44d6b8` (`bf6a1de`); remaining maps `89a3b06` in `fbfd6ad` | sav03_reservations_reload_test 4 red -> 6/0; Tests 42788023867 on `fbfd6ad` | merge `fbfd6ad` | **Batch 3+4 merge + baseline decision** |
| 29 | MML-SAV-04 | Wildlife/combat transients intentionally not saved | **Blocked** | - | - | policy | **owner decision open** (register decision SAV-04) |
| 30 | MML-SAV-05 | Continuity tests use a different JSON precision than production | Not started | - | - | align tests (test-only change) | - |
| 31 | MML-DOC-SAV-01 | Comments say NPC plans are not saved | Not started (one of four comments fixed) | `counters.gd` corrected with SAV-03 | `9fd18a5` still: `fauna.gd:28`, `journeys.gd:9`, `npc_brain.gd:238` | correct three comments | - |
| 32 | MML-NPC-01 | Failed pathfinding retried without back-off | Not started | - | - | measure, then a bounded per-target back-off | - |
| 33 | MML-NPC-02 | Courtship gifts ignore contract holds | Completed and verified | `aca3a8b`, merged `72729e5` | as #1 | - | gate baseline |
| 34 | MML-NPC-03 | Manor-hand -> farmer bypasses job-change bookkeeping | **Implemented, awaiting integration** | `0bfbb9e` in `fbfd6ad` | npc03 test 2 red -> 4/0; Tests 42788023867 | merge `fbfd6ad`; miner part kept by design | **Batch 3+4 merge + baseline decision** |
| 35 | MML-NPC-04 | Evening companion may be away or underground | Not started | - | - | reproduction, availability filter | - |
| 36 | MML-NPC-05 | `noted` keys never pruned | Not started | - | - | optional 365-day measurement | - |
| 37 | MML-LIFE-01 | Retiring employee keeps wages | Completed and verified | PR #10, merged `f0a854c` | as #22 | - | gate baseline |
| 38 | MML-LIFE-02 | Dead employee's owed goods inherited | Completed and verified | `4266761`, merged `72729e5` | as #1 | - | gate baseline |
| 39 | MML-LIFE-03 | No sage succession (owner: qualified successor) | Completed and verified | merged `229f76e` | register INTEGRATION VERIFIED; strict + campaign | - | gate baseline |
| 40 | MML-LIFE-04 | Widowed NPCs cannot remarry (owner: may remarry) | Completed and verified | merged `229f76e` | as #39 | - | gate baseline |
| 41 | MML-LIFE-05 | Bandit child inherits first (owner: last) | Completed and verified | `cbd91f6`, merged `c9da5db` | as #9 | - | gate baseline |
| 42 | MML-REG-01 | Saved journey drops its `pathed` mark | Not started | - | - | reproduction | - |
| 43 | MML-REG-02 | Migration does not end a journey or resolve trade credit | **Blocked** (journey part done) | journey part `add5061`, merged `72729e5` | reg02 test 3 red -> 5/0 | the debt part | **owner question**: a migrating household's open loans |
| 44 | MML-REG-03 | Courier proceeds return under an absent sender | Not started | - | - | reproduction | - |
| 45 | MML-REG-04 | Couriers advance abstractly (owner: travel physically) | Not started (approved feature) | - | - | design + implementation | - |
| 46 | MML-REG-05 | Migration is instant (owner: travel physically) | Not started (approved feature) | - | - | design + implementation | - |
| 47 | MML-REG-06 | Off-map household changes leave the live resident stale | **Implemented, awaiting integration** | `fd55cdd` in `fbfd6ad` | reg06 test 5 red -> 15/0; Tests 42788023867 | merge `fbfd6ad` | **Batch 3+4 merge + baseline decision** |
| 48 | MML-REG-07 | Intel freshness too long for 8-day years (owner: one year) | Completed and verified | merged `53a56d3` | strict 42597744977, campaign 42570299554 | - | gate baseline |
| 49 | MML-REG-08 | Courier job stranded at a booth with a dead carrier | Not started | - | - | technical investigation | - |
| 50 | MML-JUS-01 | Dead guard stays a pursuer | Completed and verified | PR #13, merged `f0a854c` | as #22 | - | gate baseline |
| 51 | MML-JUS-02 | Joining the bandits skips shared termination | Completed and verified | `1497a5c`, merged `72729e5` | as #1 | - | gate baseline |
| 52 | MML-JUS-03 | Player's heir inherits the criminal case | Completed and verified | PR #9, merged `f0a854c` | as #22 | - | gate baseline |
| 53 | MML-JUS-04 | Witness penalties spread too far (owner: only once the crime reached them) | Completed and verified | merged `53a56d3` | as #48 | - | gate baseline |
| 54 | MML-MP-01 | Guest-owned shops never get NPC customers | Completed and verified | PR #15, merged `f0a854c` | as #22 | two-device check not done | gate baseline |
| 55 | MML-MP-02 | Guest stall/shop management has no mirror paths | Not started | - | - | implementation + multiplayer tests | - |
| 56 | MML-MP-03 | Verb decoding accepts arbitrary inventories | Completed and verified | merged `93bb304` (+ public tables / property rules `9fd18a5`) | Tests 42764399707 (269/0), 42774872922 (271/0); mp03 tests 35/67/75 | two-device check not done | gate baseline |
| 57 | MML-MP-04 | `carts.place` creates carts for free | Completed and verified | PR #5, merged `f0a854c` | as #22 | - | gate baseline |
| 58 | MML-MP-05 | Any player's cart usable by any player (owner: mutual three-tier sharing) | **Integrated, awaiting verification** | merged `242ca83` | full CI 42636628469 green; campaign 42664730920 0 CRITICAL | two-device, modified-client, reconnect and UI checks | device testing |
| 59 | MML-MP-06 | Away guest accepted at the gateway; reach checks missing | Not started | gateway-wide refusal written and withdrawn (broke rejoin, MP-D1) | - | per-verb rule | - |
| 60 | MML-MP-07 | Snapshots expose other players' private records (owner: never shared automatically) | Not started (approved) | - | register B25-AUD-MP-07 NOT STARTED | design + implementation | - |
| 61 | MML-PROP-01 | `cancel_site` without ownership check | Completed and verified | PR #6, merged `f0a854c` | as #22 | - | gate baseline |
| 62 | MML-PROP-02 | `Fitting.remove` without holding the building | Completed and verified | PR #8, merged `f0a854c` | as #22 | - | gate baseline |
| 63 | MML-PROP-03 | Lease end leaves the tenant's site on the parcel | Completed and verified | `Property._release` (PROP-06) + test `b727954`, merged `c9da5db` | 3 red -> 5/0; as #9 | - | gate baseline |
| 64 | MML-PROP-04 | Helper finishing a guest's site runs as the host | Completed and verified | PR #12, merged `f0a854c` | as #22 | - | gate baseline |
| 65 | MML-PROP-05 | `business.sell` allowed as a guest verb | Completed and verified | PR #7, merged `f0a854c` | as #22 | - | gate baseline |
| 66 | MML-PROP-06 | Migrating household loses property (owner: atomic estate sale) | Completed and verified | merged `96b071c` | strict 42587815471, campaign | - | gate baseline |
| 67 | MML-REQ-JOB-02 | Fixed per-job wages; offered compensation on the job board | Not started | register JOB-02: OWNER APPROVED, NOT STARTED | - | feature implementation | - |
| 68 | MML-REQ-B17F-JOBS | Unemployment 6-30 adults at day 365 | **Blocked** (owner-deferred) | register B17F-JOBS: idea, PROPOSED, NOT STARTED | - | owner direction | **owner deferral** ("deliberately deferred is not a defect") |
| 69 | MML-REQ-LE-03 | Living Economy stage LE-03 | Completed and verified | register LE-03: INTEGRATED, INTEGRATION VERIFIED | LE-03 claims, earmarks and budgets are in the code and its suites (le03_* green on every recent run) | - | - |

## Owner questions answered

1. **Finished and verified:** 40 (each with the common caveat: unaccepted gate baseline, no playtest, no two-device test).
2. **Coded but awaiting merge or testing:** 4: three in the Batch 3+4 candidate (SAV-03 remaining maps, NPC-03, REG-06) and MP-05
   (merged, device checks outstanding).
3. **Still requiring actual development:** 21 not started, plus the remaining parts of the 4 blocked items once decided: 25.
4. **Blocked by the same dependency:** the three awaiting integration all wait on the one Batch 3+4 merge and its baseline decision.
   Three of the four blocked items wait on owner decisions (INV-02's seven, SAV-04, REG-02's debt question); B17F-JOBS waits on the
   owner's deferral being lifted.
5. **Largest remaining:** REG-04 and REG-05 (physical courier and migration travel: new movement systems), MP-07 (privacy
   minimization across every shared snapshot), MP-02 (guest management mirror paths across stall and shop verbs), INV-02 (a
   spoilage system across storage classes, once decided), REQ-JOB-02 (job-board compensation feature), NPC-01 (path-retry back-off
   across all planners).
6. **Can be done independently now, while testing continues:** SAV-05 (test-only), DOC-SAV-01 (three comments), EMP-04, EMP-05,
   EMP-06, BIZ-06, BIZ-07, TRD-03, TRD-04, NPC-04, NPC-05, REG-01, REG-03, REG-08 (reproduce-first investigations, small fixes
   only if reproduced), then NPC-01 and MP-06.
7. **Accidental omissions:** none of the 69 is missing from the list above. Two scope gaps were flagged in the original register and
   remain: Audits 009/009B (regional), 011 (multiplayer, ~40-50 % reviewed) and 012 (construction/property, ~45-55 % reviewed) were
   PARTIAL, so unreviewed code there may hold defects the 69 never counted. 49 of the 69 items have no record of their own in the
   requirements register (their status lives only in the master audit register); this audit is the cross-check.
8. **Before Build 25 is feature-complete and ready for a player build (for these 69):** merge Batch 3+4 after the owner's baseline
   decision; owner decisions on INV-02, SAV-04, REG-02 debt and B17F-JOBS; the 21 not-started items (four of them substantial
   features: REG-04, REG-05, MP-07, JOB-02); MP-05 device checks; then the release gates (suites, gate with an accepted baseline,
   four-seed runs, save migration, three-platform export). Outside the 69, the newer fix branches (F015/P99, meal claims, contract
   funds, member ids, phantom repair, clan pantry) also need integration.

## Completion roadmap

| Order | Workstream | Items | Size | Depends on |
|---:|---|---|---|---|
| 1 | Baseline attribution, owner decision, Batch 3+4 merge | SAV-03, NPC-03, REG-06 | merge only (code done) | attribution report (running), owner approval |
| 2 | Owner decisions | INV-02 (7), SAV-04, REG-02 debt, B17F-JOBS | decisions | owner |
| 3 | Small reproduce-first batch (one branch, one campaign) | SAV-05, DOC-SAV-01, EMP-04/05/06, BIZ-06/07, TRD-03/04, NPC-04/05, REG-01/03/08 | 14 small items; several may close as "not reproducible" with a test | none; can start now |
| 4 | Medium fixes | NPC-01, MP-06, REG-02 debt part (after 2) | medium | 2 for REG-02 |
| 5 | Multiplayer verification and features | MP-05 device checks, MP-02, MP-07 | medium-large | two devices for MP-05 |
| 6 | Approved features | REG-04, REG-05, REQ-JOB-02, INV-02 (after 2) | large | 2 for INV-02 |

Shortest responsible path: 1 now (closes 3, reaching 43 of 69); 2 in parallel (unblocks 4); 3 as one batch with one
recorded campaign (up to 14 more); then 4 and 5; 6 last. Every batch goes through failing-first tests, strict CI, the gate and a
recorded campaign before merge; none of this changes or accepts a baseline.

## Discrepancies

1. **B25-AUD-EMP-03** in the requirements register reads "IMPLEMENTED ON TASK BRANCH / TARGETED TESTS PASSED", branch
   `wip/b25-emp03`; the fix `00e47a6` is on the development line (merged `72729e5`). The record is stale; to be corrected by a
   register update with this evidence.
2. **B25-AUD-REG-08** has no implementation or verification status at all (an empty record).
3. **ID collisions:** the register's `MP-01` (an older two-player LAN prototype requirement, SUPERSEDED) and `WORLD-LIFE-01` are not
   MML-MP-01 / MML-LIFE-01; a search by bare ID gives the wrong record.
4. **Partial items recorded as merged:** the master audit register lists "REG-02 journey part" and "SAV-03 counter part" as merged;
   neither item is complete (REG-02's debt part awaits the owner; SAV-03's other maps are in `fbfd6ad`).
5. **DOC-SAV-01** is not listed anywhere as started, but one of its four comments (`counters.gd`) was corrected with SAV-03; three
   remain wrong on `9fd18a5`.
6. **"Verified" and the gate:** the master register and the requirements register mark merged items INTEGRATION VERIFIED on
   strict CI and recorded campaigns, while the simulation gate has been red since `df67e8e` on unaccepted baseline differences. The
   items are verified by their own tests and campaigns; the gate's baseline is outstanding for all of them (the 33 under review).
7. The verbatim v14 copy still shows SAV-01, LIFE-01, PROP-01/02/05 and JUS-03 as "awaiting integration": historical text, kept
   unedited as a verbatim record; the master register's later sections supersede it.
