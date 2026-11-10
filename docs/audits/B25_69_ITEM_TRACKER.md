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
| Completed and verified (engineering: Code, Focused, Full CI, Sim, Merged) | 40 |
| Implemented, awaiting integration | 3 |
| Integrated, awaiting verification | 1 |
| In progress | 0 |
| Blocked | 4 |
| Not started | 21 |
| **Total** | **69** |
| Device verified | 0 |
| Release-gate verified | 0 |

## Tracker

| # | ID | Finding | Status | Code | Focused | Full CI | Sim | Merged | Device | Release | Commit / branch |
|---:|---|---|---|---|---|---|---|---|---|---|---|
| 1 | MML-EMP-01 | Succession may retrain a permanently employed NPC, leaving the employment record | Completed and verified | Y | Y | Y | Y | Y | N | N | `7438665`, merged `72729e5` |
| 2 | MML-EMP-02 | Mid-day save/load resets `earned_at_dawn` / `laboured_today` | Completed and verified | Y | Y | Y | Y | Y | N | N | covered by SAV-02 `f67afdb`, merged `c9da5db` |
| 3 | MML-EMP-03 | Hiring competition counts the wrong seekers | Completed and verified | Y | Y | Y | Y | Y | N | N | `00e47a6`, merged `72729e5` |
| 4 | MML-EMP-04 | `skilled_place` sums time across stations, picks one | Not started | N | N | N | N | N | N | N | - |
| 5 | MML-EMP-05 | Unguarded `w.fields[0]` with zero fields | Not started | N | N | N | N | N | N | N | - |
| 6 | MML-EMP-06 | Unemployed excluded from `_day_labour` (intent?) | Not started | N | N | N | N | N | N | N | - |
| 7 | MML-BIZ-01 | Founding ends employment before the business opens | Completed and verified | Y | Y | Y | Y | Y | N | N | `82da3c6`, merged `72729e5` |
| 8 | MML-BIZ-02 | Expansion pays for premises before the purchase is confirmed | Completed and verified | Y | Y | Y | Y | Y | N | N | `82da3c6`, merged `72729e5` |
| 9 | MML-BIZ-03 | Owner withdrawals before payroll; hiring budgets one wage (owner decision: option B) | Completed and verified | Y | Y | Y | Y | Y | N | N | `93327ae`, merged `c9da5db` |
| 10 | MML-BIZ-04 | Venture tills escheat on migration (owner decision: household keeps them) | Completed and verified | Y | Y | Y | Y | Y | N | N | `3e9b9a1`, merged `c9da5db` |
| 11 | MML-BIZ-05 | Venture hand also hired as employee | Completed and verified | Y | Y | Y | Y | Y | N | N | `2c05696`, merged `72729e5` |
| 12 | MML-BIZ-06 | Venture close could erase a till if the final transfer fails | Not started | N | N | N | N | N | N | N | - |
| 13 | MML-BIZ-07 | Venture hand employed by a player keeps hand privileges | Not started | N | N | N | N | N | N | N | - |
| 14 | MML-BIZ-08 | Hand ids as floats after load | Completed and verified | Y | Y | Y | Y | Y | N | N | `4761957`, merged `e44d6b8` |
| 15 | MML-TRD-01 | Guest stall settlement assigns a PlayerState to NPC | Completed and verified | Y | Y | Y | Y | Y | N | N | `1fa94b5`, merged `e44d6b8` |
| 16 | MML-TRD-02 | Merchant earnings gross, not net of commission (owner: net) | Completed and verified | Y | Y | Y | Y | Y | N | N | `36fa011`, merged `c9da5db` |
| 17 | MML-TRD-03 | Player claims count chest goods, transactions do not | Not started | N | N | N | N | N | N | N | - |
| 18 | MML-TRD-04 | Shipment with no room at either end stays open | Not started | N | N | N | N | N | N | N | - |
| 19 | MML-TRD-05 | Comments say the Living Economy is off | Completed and verified | Y | Y | Y | n/a (docs) | Y | N | N | `85ad919`, merged `93bb304` |
| 20 | MML-INV-01 | Player stash missing from the goods census | Completed and verified | Y | Y | Y | Y | Y | N | N | `35f241c`, merged `e44d6b8` |
| 21 | MML-INV-02 | Stash, homestead chest, courier stores never spoil | Blocked | proposal only | N | N | N | N | N | N | proposal `906f1a8` on `wip/b25-inv02-proposal` (off by default, not code for merge) |
| 22 | MML-INV-03 | Any player gets "own" access to another player's stash | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #14, merged `f0a854c` |
| 23 | MML-INV-04 | Stash goods unreachable after a lease/ownership change (owner decision) | Completed and verified | Y | Y | Y | Y | Y | N | N | `969a8f4`, merged `c9da5db` |
| 24 | MML-INV-05 | Rubble returned as dressed stone (owner: no conversion) | Completed and verified | Y | Y | Y | Y | Y | N | N | `e42a37f`, merged `c9da5db` |
| 25 | MML-INV-06 | Worn tools restored in barter/credit/restitution | Completed and verified | Y | Y | Y | Y | Y | N | N | `916db07`, merged `72729e5` |
| 26 | MML-SAV-01 | `food_days` not saved; famine lapses after reload | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #11, merged `f0a854c` |
| 27 | MML-SAV-02 | Hour caches and market snapshot not saved (owner: preserve) | Completed and verified | Y | Y | Y | Y | Y | N | N | `f67afdb`, merged `c9da5db` |
| 28 | MML-SAV-03 | Reservation maps cleared on load (counters, farm, business, chapel, fauna) | Implemented, awaiting integration | Y | Y | Y (fbfd6ad 42788023867) | Y (42788018729) | N | N | N | counter part merged `e44d6b8` (`bf6a1de`); remaining maps `89a3b06` in `fbfd6ad` |
| 29 | MML-SAV-04 | Wildlife/combat transients intentionally not saved | Blocked | N | N | N | N | N | N | N | - |
| 30 | MML-SAV-05 | Continuity tests use a different JSON precision than production | Not started | N | N | N | N | N | N | N | - |
| 31 | MML-DOC-SAV-01 | Comments say NPC plans are not saved | Not started | part (1 of 4 comments) | N | N | N | N | N | N | `counters.gd` corrected with SAV-03 |
| 32 | MML-NPC-01 | Failed pathfinding retried without back-off | Not started | N | N | N | N | N | N | N | - |
| 33 | MML-NPC-02 | Courtship gifts ignore contract holds | Completed and verified | Y | Y | Y | Y | Y | N | N | `aca3a8b`, merged `72729e5` |
| 34 | MML-NPC-03 | Manor-hand -> farmer bypasses job-change bookkeeping | Implemented, awaiting integration | Y | Y | Y (fbfd6ad 42788023867) | Y (42788018729) | N | N | N | `0bfbb9e` in `fbfd6ad` |
| 35 | MML-NPC-04 | Evening companion may be away or underground | Not started | N | N | N | N | N | N | N | - |
| 36 | MML-NPC-05 | `noted` keys never pruned | Not started | N | N | N | N | N | N | N | - |
| 37 | MML-LIFE-01 | Retiring employee keeps wages | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #10, merged `f0a854c` |
| 38 | MML-LIFE-02 | Dead employee's owed goods inherited | Completed and verified | Y | Y | Y | Y | Y | N | N | `4266761`, merged `72729e5` |
| 39 | MML-LIFE-03 | No sage succession (owner: qualified successor) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `229f76e` |
| 40 | MML-LIFE-04 | Widowed NPCs cannot remarry (owner: may remarry) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `229f76e` |
| 41 | MML-LIFE-05 | Bandit child inherits first (owner: last) | Completed and verified | Y | Y | Y | Y | Y | N | N | `cbd91f6`, merged `c9da5db` |
| 42 | MML-REG-01 | Saved journey drops its `pathed` mark | Not started | N | N | N | N | N | N | N | - |
| 43 | MML-REG-02 | Migration does not end a journey or resolve trade credit | Blocked | part | part | part | part | part | N | N | journey part `add5061`, merged `72729e5` |
| 44 | MML-REG-03 | Courier proceeds return under an absent sender | Not started | N | N | N | N | N | N | N | - |
| 45 | MML-REG-04 | Couriers advance abstractly (owner: travel physically) | Not started | N | N | N | N | N | N | N | - |
| 46 | MML-REG-05 | Migration is instant (owner: travel physically) | Not started | N | N | N | N | N | N | N | - |
| 47 | MML-REG-06 | Off-map household changes leave the live resident stale | Implemented, awaiting integration | Y | Y | Y (fbfd6ad 42788023867) | Y (42788018729) | N | N | N | `fd55cdd` in `fbfd6ad` |
| 48 | MML-REG-07 | Intel freshness too long for 8-day years (owner: one year) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `53a56d3` |
| 49 | MML-REG-08 | Courier job stranded at a booth with a dead carrier | Not started | N | N | N | N | N | N | N | - |
| 50 | MML-JUS-01 | Dead guard stays a pursuer | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #13, merged `f0a854c` |
| 51 | MML-JUS-02 | Joining the bandits skips shared termination | Completed and verified | Y | Y | Y | Y | Y | N | N | `1497a5c`, merged `72729e5` |
| 52 | MML-JUS-03 | Player's heir inherits the criminal case | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #9, merged `f0a854c` |
| 53 | MML-JUS-04 | Witness penalties spread too far (owner: only once the crime reached them) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `53a56d3` |
| 54 | MML-MP-01 | Guest-owned shops never get NPC customers | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #15, merged `f0a854c` |
| 55 | MML-MP-02 | Guest stall/shop management has no mirror paths | Not started | N | N | N | N | N | N | N | - |
| 56 | MML-MP-03 | Verb decoding accepts arbitrary inventories | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `93bb304` (+ public tables / property rules `9fd18a5`) |
| 57 | MML-MP-04 | `carts.place` creates carts for free | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #5, merged `f0a854c` |
| 58 | MML-MP-05 | Any player's cart usable by any player (owner: mutual three-tier sharing) | Integrated, awaiting verification | Y | Y | Y | Y | Y | N (two-device pending) | N | merged `242ca83` |
| 59 | MML-MP-06 | Away guest accepted at the gateway; reach checks missing | Not started | N | N | N | N | N | N | N | gateway-wide refusal written and withdrawn (broke rejoin, MP-D1) |
| 60 | MML-MP-07 | Snapshots expose other players' private records (owner: never shared automatically) | Not started | N | N | N | N | N | N | N | - |
| 61 | MML-PROP-01 | `cancel_site` without ownership check | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #6, merged `f0a854c` |
| 62 | MML-PROP-02 | `Fitting.remove` without holding the building | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #8, merged `f0a854c` |
| 63 | MML-PROP-03 | Lease end leaves the tenant's site on the parcel | Completed and verified | Y | Y | Y | Y | Y | N | N | `Property._release` (PROP-06) + test `b727954`, merged `c9da5db` |
| 64 | MML-PROP-04 | Helper finishing a guest's site runs as the host | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #12, merged `f0a854c` |
| 65 | MML-PROP-05 | `business.sell` allowed as a guest verb | Completed and verified | Y | Y | Y | Y | Y | N | N | PR #7, merged `f0a854c` |
| 66 | MML-PROP-06 | Migrating household loses property (owner: atomic estate sale) | Completed and verified | Y | Y | Y | Y | Y | N | N | merged `96b071c` |
| 67 | MML-REQ-JOB-02 | Fixed per-job wages; offered compensation on the job board | Not started | N | N | N | N | N | N | N | register JOB-02: OWNER APPROVED, NOT STARTED |
| 68 | MML-REQ-B17F-JOBS | Unemployment 6-30 adults at day 365 | Blocked | N | N | N | N | N | N | N | register B17F-JOBS: idea, PROPOSED, NOT STARTED |
| 69 | MML-REQ-LE-03 | Living Economy stage LE-03 | Completed and verified | Y | Y | Y | Y | Y | N | N | register LE-03: INTEGRATED, INTEGRATION VERIFIED |

## Change log

| Date (UTC) | Item | Change | Evidence |
|---|---|---|---|
| 2026-11-10 17:30 | all 69 | baseline reconciliation | `docs/audits/2026-11-10_69_OPEN_ITEMS_AUDIT.md` `6bacff0` |
| 2026-11-10 18:00 | all 69 | tracker created with the seven verification columns; no status changed | this file |
