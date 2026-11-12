# Build 25: the original 69 items, living tracker (B25-TRACK-69-02)

Owner directive 2026-11-10 (`docs/directives/2026-11-10_phantom_repair_decisions_69_tracker.md`). The 69 IDs of the owner's v14
register (`docs/audits/2026-11-08_INDEPENDENT_AUDIT_OPEN_ITEMS_v14.md`, `02ad7aa`) are fixed: never added to, removed, merged or
redefined. Baseline reconciliation: `docs/audits/2026-11-10_69_OPEN_ITEMS_AUDIT.md` at `6bacff0` (evidence per item). Newly
found defects are kept apart in `docs/audits/B25_NEW_DEFECTS_REGISTER.md`. Update a row only with evidence, and log the change
at the bottom.

Columns (each a separate fact; Y = done with evidence, N = not, part = partly, n/a = does not apply):
**Code** implemented; **Focused** failing-first or focused tests passed; **Full CI** strict suite green on a commit carrying it;
**Sim** recorded 365-day campaign passed (0 CRITICAL, 0 confirmed) on a commit carrying it; **Merged** on the development line
`wip/b25r2-rev2`; **Device** player/device verification done; **Release** release-gate verification done (requires an accepted
simulation baseline, which no commit has since `df67e8e`). No item is release-verified: the Release column is N everywhere.

## Counts (as of the log's last entry)

| Status | Count |
|---|---:|
| Completed and verified (engineering: Code, Focused, Full CI, Sim, Merged) | 43 |
| Implemented, awaiting integration | 0 |
| Integrated, awaiting verification | 21 |
| In progress | 0 |
| Blocked | 1 |
| Not started | 4 |
| **Total** | **69** |
| Device verified | 0 |
| Release-gate verified | 0 |

## Tracker

| # | ID | Finding | Status | Code | Focused | Full CI | Sim | Merged | Device | Release | Commit / branch |
|---:|---|---|---|---|---|---|---|---|---|---|---|
| 1 | MML-EMP-01 | Succession may retrain a permanently employed NPC, leaving the employment record | Completed and verified | Y | Y | Y | Y | Y | N | N | `7438665`, merged `72729e5` |
| 2 | MML-EMP-02 | Mid-day save/load resets `earned_at_dawn` / `laboured_today` | Completed and verified | Y | Y | Y | Y | Y | N | N | covered by SAV-02 `f67afdb`, merged `c9da5db` |
| 3 | MML-EMP-03 | Hiring competition counts the wrong seekers | Completed and verified | Y | Y | Y | Y | Y | N | N | `00e47a6`, merged `72729e5` |
| 4 | MML-EMP-04 | `skilled_place` sums time across stations, picks one | Integrated, awaiting verification | n/a | Y | Y | N | Y | N | N | owner 2026-11-12: resolved as not reproducible, guarded (guard test `31496e9`); merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 5 | MML-EMP-05 | Unguarded `w.fields[0]` with zero fields | Integrated, awaiting verification | n/a | Y | Y | N | Y | N | N | owner 2026-11-12: resolved as not reproducible, guarded (`94b297c`); merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 6 | MML-EMP-06 | Unemployed excluded from `_day_labour` (intent?) | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | owner 2026-11-12 Allow day labour: `b0d9cca` (wip/b25-owner-decisions); merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 7 | MML-BIZ-01 | Founding ends employment before the business opens | Completed and verified | Y | Y | Y | Y | Y | N | N | `82da3c6`, merged `72729e5` |
| 8 | MML-BIZ-02 | Expansion pays for premises before the purchase is confirmed | Completed and verified | Y | Y | Y | Y | Y | N | N | `82da3c6`, merged `72729e5` |
| 9 | MML-BIZ-03 | Owner withdrawals before payroll; hiring budgets one wage (owner decision: option B) | Completed and verified | Y | Y | Y | Y | Y | N | N | `93327ae`, merged `c9da5db` |
| 10 | MML-BIZ-04 | Venture tills escheat on migration (owner decision: household keeps them) | Completed and verified | Y | Y | Y | Y | Y | N | N | `3e9b9a1`, merged `c9da5db` |
| 11 | MML-BIZ-05 | Venture hand also hired as employee | Completed and verified | Y | Y | Y | Y | Y | N | N | `2c05696`, merged `72729e5` |
| 12 | MML-BIZ-06 | Venture close could erase a till if the final transfer fails | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | `a999e1a`, merged on the development line `e21bfc6` (chain 8; Tests 43257628284; gate 43257634345); 365-day campaign not run |
| 13 | MML-BIZ-07 | Venture hand employed by a player keeps hand privileges | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | owner 2026-11-12 Refuse while a hand: `b0d9cca`; merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 14 | MML-BIZ-08 | Hand ids as floats after load | Completed and verified | Y | Y | Y | Y | Y | N | N | `4761957`, merged `e44d6b8` |
| 15 | MML-TRD-01 | Guest stall settlement assigns a PlayerState to NPC | Completed and verified | Y | Y | Y | Y | Y | N | N | `1fa94b5`, merged `e44d6b8` |
| 16 | MML-TRD-02 | Merchant earnings gross, not net of commission (owner: net) | Completed and verified | Y | Y | Y | Y | Y | N | N | `36fa011`, merged `c9da5db` |
| 17 | MML-TRD-03 | Player claims count chest goods, transactions do not | Integrated, awaiting verification | n/a | Y | Y | N | Y | N | N | owner 2026-11-12: resolved as not reproducible, guarded (`ae7f1dd`); merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 18 | MML-TRD-04 | Shipment with no room at either end stays open | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | `efb0b93`, merged `e21bfc6` (chain 8); campaign not run |
| 19 | MML-TRD-05 | Comments say the Living Economy is off | Completed and verified | Y | Y | Y | n/a (docs) | Y | N | N | `85ad919`, merged `93bb304` |
| 20 | MML-INV-01 | Player stash missing from the goods census | Completed and verified | Y | Y | Y | Y | Y | N | N | `35f241c`, merged `e44d6b8` |
| 21 | MML-INV-02 | Stash, homestead chest, courier stores never spoil | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | F1-F6 behind the off switch `0498dc3` (flag-off identical fingerprint); owner validation (4 seeds x 365 days flag on) pending; merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 22 | MML-INV-03 | Any player gets "own" access to another player's stash | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #14, merged `f0a854c` |
| 23 | MML-INV-04 | Stash goods unreachable after a lease/ownership change (owner decision) | Completed and verified | Y | Y | Y | Y | Y | N | N | `969a8f4`, merged `c9da5db` |
| 24 | MML-INV-05 | Rubble returned as dressed stone (owner: no conversion) | Completed and verified | Y | Y | Y | Y | Y | N | N | `e42a37f`, merged `c9da5db` |
| 25 | MML-INV-06 | Worn tools restored in barter/credit/restitution | Completed and verified | Y | Y | Y | Y | Y | N | N | `916db07`, merged `72729e5` |
| 26 | MML-SAV-01 | `food_days` not saved; famine lapses after reload | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #11, merged `f0a854c` |
| 27 | MML-SAV-02 | Hour caches and market snapshot not saved (owner: preserve) | Completed and verified | Y | Y | Y | Y | Y | N | N | `f67afdb`, merged `c9da5db` |
| 28 | MML-SAV-03 | Reservation maps cleared on load (counters, farm, business, chapel, fauna) | Completed and verified | Y | Y | Y (fbfd6ad 42788023867) | Y (42788018729) | Y (b2cd024) | N | N | counter part merged `e44d6b8` (`bf6a1de`); remaining maps `89a3b06` in `fbfd6ad`; merged `b2cd024` (Tests 42940243926, gate 42940247768) |
| 29 | MML-SAV-04 | Wildlife/combat transients intentionally not saved | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | owner option (a): reload-determinism test + docs `ae69d32`, no defect found; merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 30 | MML-SAV-05 | Continuity tests use a different JSON precision than production | Integrated, awaiting verification | Y | Y | Y | N | Y | n/a | N | `c1d4b7c`/`0d6a484` merged with ND-15 at chain step 6, development line `5503614` |
| 31 | MML-DOC-SAV-01 | Comments say NPC plans are not saved | Integrated, awaiting verification | Y | Y | Y | N | Y | n/a | N | `c1d4b7c` merged at chain step 6 (`5503614`) |
| 32 | MML-NPC-01 | Failed pathfinding retried without back-off | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | walk back-off `5cb29b4` + bandit/guard/fighter exemption `baaec84` (ND-21); merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 33 | MML-NPC-02 | Courtship gifts ignore contract holds | Completed and verified | Y | Y | Y | Y | Y | N | N | `aca3a8b`, merged `72729e5` |
| 34 | MML-NPC-03 | Manor-hand -> farmer bypasses job-change bookkeeping | Completed and verified | Y | Y | Y (fbfd6ad 42788023867) | Y (42788018729) | Y (b2cd024) | N | N | `0bfbb9e` in `fbfd6ad`; merged `b2cd024` (Tests 42940243926, gate 42940247768) |
| 35 | MML-NPC-04 | Evening companion may be away or underground | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | `d0628a9`, merged `e21bfc6` (chain 8); campaign not run (it changes the simulation) |
| 36 | MML-NPC-05 | `noted` keys never pruned | Integrated, awaiting verification | n/a | Y | Y | N | Y | N | N | owner 2026-11-12: not a defect, guarded (`51e20b8`); merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 37 | MML-LIFE-01 | Retiring employee keeps wages | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #10, merged `f0a854c` |
| 38 | MML-LIFE-02 | Dead employee's owed goods inherited | Completed and verified | Y | Y | Y | Y | Y | N | N | `4266761`, merged `72729e5` |
| 39 | MML-LIFE-03 | No sage succession (owner: qualified successor) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `229f76e` |
| 40 | MML-LIFE-04 | Widowed NPCs cannot remarry (owner: may remarry) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `229f76e` |
| 41 | MML-LIFE-05 | Bandit child inherits first (owner: last) | Completed and verified | Y | Y | Y | Y | Y | N | N | `cbd91f6`, merged `c9da5db` |
| 42 | MML-REG-01 | Saved journey drops its `pathed` mark | Integrated, awaiting verification | n/a | Y | Y | N | Y | N | N | owner 2026-11-12: resolved as not reproducible, guarded (`e5e6871`); merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 43 | MML-REG-02 | Migration does not end a journey or resolve trade credit | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | debt part (owner option (b)): `3bb486d` (wip/b25-reg02-debt); journey part merged `72729e5`; merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 44 | MML-REG-03 | Courier proceeds return under an absent sender | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | owner 2026-11-12 Estate + timeout: `b0d9cca`; merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 45 | MML-REG-04 | Couriers advance abstractly (owner: travel physically) | Not started | N | N | N | N | N | N | N | - |
| 46 | MML-REG-05 | Migration is instant (owner: travel physically) | Not started | N | N | N | N | N | N | N | - |
| 47 | MML-REG-06 | Off-map household changes leave the live resident stale | Completed and verified | Y | Y | Y (fbfd6ad 42788023867) | Y (42788018729) | Y (b2cd024) | N | N | `fd55cdd` in `fbfd6ad`; merged `b2cd024` (Tests 42940243926, gate 42940247768) |
| 48 | MML-REG-07 | Intel freshness too long for 8-day years (owner: one year) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `53a56d3` |
| 49 | MML-REG-08 | Courier job stranded at a booth with a dead carrier | Integrated, awaiting verification | Y | Y | Y | N | Y | N | N | owner 2026-11-12 Estate + timeout: `b0d9cca`; merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 50 | MML-JUS-01 | Dead guard stays a pursuer | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #13, merged `f0a854c` |
| 51 | MML-JUS-02 | Joining the bandits skips shared termination | Completed and verified | Y | Y | Y | Y | Y | N | N | `1497a5c`, merged `72729e5` |
| 52 | MML-JUS-03 | Player's heir inherits the criminal case | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #9, merged `f0a854c` |
| 53 | MML-JUS-04 | Witness penalties spread too far (owner: only once the crime reached them) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `53a56d3` |
| 54 | MML-MP-01 | Guest-owned shops never get NPC customers | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #15, merged `f0a854c` |
| 55 | MML-MP-02 | Guest stall/shop management has no mirror paths | Not started | N | N | N | N | N | N | N | - |
| 56 | MML-MP-03 | Verb decoding accepts arbitrary inventories | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `93bb304` (+ public tables / property rules `9fd18a5`) |
| 57 | MML-MP-04 | `carts.place` creates carts for free | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #5, merged `f0a854c` |
| 58 | MML-MP-05 | Any player's cart usable by any player (owner: mutual three-tier sharing) | Integrated, awaiting verification | Y | Y | Y | Y | Y | N (two-device pending) | N | merged `242ca83` |
| 59 | MML-MP-06 | Away guest accepted at the gateway; reach checks missing | Integrated, awaiting verification | Y | Y | Y | n/a | Y | N | N | `cda94b8` (+ guest trust ND-20 `fccab06`); two-device check pending; merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 60 | MML-MP-07 | Snapshots expose other players' private records (owner: never shared automatically) | Integrated, awaiting verification | Y | Y | Y | n/a | Y | N | N | `0092913` (owner family-links decision 2026-11-12 applied); two-device check pending; merged on the development line `b3c9eb5` (chain 12 = chain 11 + ND-26 + station_tap fix; Tests 43321399738 green; gate 43321404909: 32 baseline findings only, determinism identical); 365-day campaign not run |
| 61 | MML-PROP-01 | `cancel_site` without ownership check | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #6, merged `f0a854c` |
| 62 | MML-PROP-02 | `Fitting.remove` without holding the building | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #8, merged `f0a854c` |
| 63 | MML-PROP-03 | Lease end leaves the tenant's site on the parcel | Completed and verified | Y | Y | Y | Y | Y | N | N | `Property._release` (PROP-06) + test `b727954`, merged `c9da5db` |
| 64 | MML-PROP-04 | Helper finishing a guest's site runs as the host | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #12, merged `f0a854c` |
| 65 | MML-PROP-05 | `business.sell` allowed as a guest verb | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #7, merged `f0a854c` |
| 66 | MML-PROP-06 | Migrating household loses property (owner: atomic estate sale) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `96b071c` |
| 67 | MML-REQ-JOB-02 | Fixed per-job wages; offered compensation on the job board | Not started | N | N | N | N | N | N | N | register JOB-02: OWNER APPROVED, NOT STARTED |
| 68 | MML-REQ-B17F-JOBS | Unemployment 6-30 adults at day 365 | Blocked | n/a | n/a | n/a | n/a | n/a | N | N | measured `48d8aee` (docs/audits/2026-11-12_B17F_JOBS_MEASUREMENT.md): supply of adults outgrows posts; any employment change awaits the owner |
| 69 | MML-REQ-LE-03 | Living Economy stage LE-03 | Completed and verified | Y | Y | Y | Y | Y | N | N | register LE-03: INTEGRATED, INTEGRATION VERIFIED |

## Change log

| Date (UTC) | Item | Change | Evidence |
|---|---|---|---|
| 2026-11-10 17:30 | all 69 | baseline reconciliation | `docs/audits/2026-11-10_69_OPEN_ITEMS_AUDIT.md` `6bacff0` |
| 2026-11-10 18:00 | all 69 | tracker created with the seven verification columns; no status changed | this file |
| 2026-11-10 18:40 | DOC-SAV-01, SAV-05 | Not started -> In progress (WP-1) | `c1d4b7c`, `0d6a484`; SAV-05 reproduction: default-precision copies differ in 98 villagers after load |
| 2026-11-11 02:45 | SAV-03, NPC-03, REG-06 | Implemented, awaiting integration -> Completed and verified: Batch 3+4 merged onto `wip/b25r2-rev2` at `b2cd024` (owner approval B25-BATCH34-MERGE-D1; attribution: no unexplained regressions) | Tests 42940243926, gate 42940247768 (33 = fbfd6ad set), campaign 42788018729 |
| 2026-11-12 02:00 | WP-1 (12 items) | Branches from `1f7043b`: 3 fixed (BIZ-06, NPC-04, TRD-04); 5 not reproducible, guarded by test, pending owner review (NPC-05, EMP-05, TRD-03, EMP-04, REG-01); 4 need owner rules (REG-08, REG-03, BIZ-07, EMP-06) | WP-1 worker report; CI runs 43125171165, 43125390800, 43125800056, 43126231844, 43126611502, 43126958329, 43127189432, 43127967701 |

- 2026-11-12 16:25 EST (lead, Extra Life directive): 21 rows updated from today's evidence: owner decisions (docs/directives/2026-11-12_extra_life_owner_decisions.md), chain 8 merged at `e21bfc6`, chain 11 `1d03eea` (Tests 43298116326, gate 43298122299). Release column N everywhere (no accepted baseline).
- 2026-11-12 18:50 EST (lead): 15 rows Implemented, awaiting integration -> Integrated, awaiting verification: chain 12 `b3c9eb5` (chain 11 `1d03eea` + ND-26 watchdog `b1a2fa8` + station_tap test fix) fast-forwarded onto `wip/b25r2-rev2`. Tests 43321399738 green (all 12 shards); Build and release 43321404909 (build 39): gate 32 blocking findings, all eq_s1 differences from the df67e8e baseline of another version, determinism identical, judgment chains complete; six packages built, both APKs signed with the permanent key, Linux full/demo launch clean, Windows full/demo smoke passed. No 365-day campaign run on chain 12; Release column N (no accepted baseline). Counts 43 / 0 / 21 / 0 / 1 / 4.
