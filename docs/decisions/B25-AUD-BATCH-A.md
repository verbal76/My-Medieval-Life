# B25-AUD-BATCH-A: eleven audit corrections (PRs #5-#15) and the B25R2-BRUSHOFF fix, merged at `f0a854c`

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01). Sources:
> - PRs #5-#15: bodies, commits, and the evidence files `docs/audits/2026-11-08_*_VERIFICATION.md` now on `wip/b25r2-rev2`;
> - issue #4 comments 1-3 and 13;
> - the audit register (`docs/build25-audit-register` `257475c`);
> - the owner's directives of 2026-11-08, recovered verbatim in
>   [`2026-11-08_recovered_owner_messages.md`](../directives/2026-11-08_recovered_owner_messages.md);
> - commit messages `0d252b4` and `f0a854c`;
> - the state file;
> - the lead session transcript, for times and the lead's checks.
>
> Times are UTC unless marked EST. Event times come from GitHub. The record was written on 2026-11-09, after the events.

## A. Identity and timeline
- **IDs:** audit items MML-MP-04, PROP-01, PROP-05, PROP-02, JUS-03, LIFE-01, SAV-01, PROP-04, JUS-01, INV-03 and MP-01, plus the
  register entry B25R2-BRUSHOFF. The register has no entry for the audit items yet (coverage register, section 8).
- **Build:** Build 25 Revision 2. Development line `wip/b25r2-rev2`.
- **Who:**
  - ChatGPT reproduced and corrected the eleven items, writing through the owner's GitHub account (commits by "Hot Attic Games").
  - The lead (Claude) integrated and verified them and fixed BRUSHOFF.
  - The owner authorized each step.
- **Timeline:**
  - 2026-11-08 07:30: the owner gives the v14 audit register (69 static findings, 0 runtime-confirmed).
  - 07:39-08:17: PRs #5-#9 red and green runs.
  - 17:36-17:55: PRs #10-#15 red and green runs.
  - 18:14: the owner's "Audit fix integration directive".
  - 18:15-18:19: integration branch `wip/b25-audit-integration` at `0d252b4`.
  - 18:20: strict run 42509510188 and gate 42509523836.
  - 19:34: campaign 42515726815.
  - 20:12: the owner's "Build 25 audit integration and merge directive", which approves the BRUSHOFF fix.
  - 20:13: `f0a854c`; strict run 42519022430.
  - 23:36: `wip/b25r2-rev2` fast-forwarded `fe7d8f8` → `f0a854c`.
  - 23:37: PRs #5-#15 closed as merged.

## B. Original situation
The owner paid for 13 static code audits of `fe7d8f8` (the development head after the B25R2 playtest fixes). The owner summarized them
as 69 records, "NOT 69 confirmed bugs", with "Zero runtime-confirmed failures". The handoff rules in issue #4:
- reproduce before changing code;
- never re-record baselines;
- validate on exact SHAs;
- preserve reasoning;
- get owner decisions on ambiguous rules.

The eleven items were those the owner's team could reproduce cheaply. Most concern host authority in multiplayer, where a guest's
network verb or access was not checked:

| Item | What the audit suspected (original intended behaviour in brackets) |
|---|---|
| MP-04 | A guest could create a free cart through the whitelisted `carts.place` verb (carts are bought) |
| PROP-01 | A guest could cancel another player's building site and receive its refund (only the site's owner may) |
| PROP-05 | A guest could execute an NPC shop sale at any price through `business.sell` (sales go through the host's customer logic) |
| PROP-02 | A guest could remove another player's fittings or shop stock (only the room's holder may) |
| JUS-03 | After an old-age death, the heir stayed pursued for the predecessor's crime (cases close at death) |
| LIFE-01 | A retired employee kept the employment and its wages; owed goods were not returned |
| SAV-01 | Famine state was lost on load (`food_days` defaulted to 99) |
| PROP-04 | A guest's new house was named for the host's family |
| JUS-01 | A dead guard stayed in a case's `pursuers` |
| INV-03 | A guest could get "own" access to another player's chest |
| MP-01 | The host's hourly tick ignored a guest attending their own stall, and NPC-sale trading XP went to the host |

## C. Evidence and investigation
Each item got a test-only reproduction on the audited code first (red), then the correction (green). Each ran on one Actions runner.

| PR | Item | Red run (checks/failures) | Green run | Fix commit | Correction |
|---|---|---|---|---|---|
| #5 | MP-04 | 42459686569 (6/2) | 42459774174 (6/0) | `32cab1d` | `carts.place` removed from `NetActions.VERBS`; `player_set_down_cart` kept |
| #6 | PROP-01 | 42461697475 (7/5) | 42461831319 (7/0) | `cf744a1` | host checks the site's owner and pays the refund only to the requester |
| #7 | PROP-05 | 42461609614 (8/5) | 42461726200 (8/0) | `c5e2db9` | `business.sell` no longer guest-whitelisted |
| #8 | PROP-02 | 42461880196 (13/5) | 42461995223 (13/0) | `ee3727e` | the room-holder check runs before any fitting removal, shop closure or refund |
| #9 | JUS-03 | 42462198471 (9/5) | 42462279977 (9/0) | `6ab511f` | old-age death calls `justice.on_death` |
| #10 | LIFE-01 | 42505788262 (10/4) | 42505882421 (10/0) | `ed6ce70` | `Employment.end` at retirement (goods, permissions, slots) |
| #11 | SAV-01 | 42505790508 (5/3) | 42505924495 (5/0) | `f5287a2` | `food_days` saved; recomputed for older saves |
| #12 | PROP-04 | 42506634010 (5/2) | 42506716192 (5/0) | `d29dd50` | house named for the site's actual owner |
| #13 | JUS-01 | 42506631586 (6/3) | 42506737179 (6/0) | `f9c4679` | a dead guard is released from pursuit |
| #14 | INV-03 | 42506955329 (7/3) | 42507116945 (7/0) | `3329e42` | chest and container access isolated by actor reference |
| #15 | MP-01 | 42507246263 (11/4) | 42507374909 (11/0) | `6f61278` | host recognizes guest stall attendance; guest gets the XP |

**Failed attempts kept on record:**
- INV-03's run 42506825276 failed on a test-only type error and is not defect evidence (issue #4 comment 3).
- MP-01's run 42507064870 failed before the test was corrected at `012e80d` ("require guest, not host, to receive NPC-sale
  trading XP"). Its failing line was not read during this recovery.

**Confirmed and not confirmed.** The eleven defects are confirmed by red/green runs on the audited code. The other 58 audit records
stayed static suspicions or owner questions at that point.

## D. Communication and coordination
- **2026-11-08 (EST), the owner tells the lead in a series of messages:**
  - 03:03: that ChatGPT fixed MP-04.
  - 12:34: "retrieve completed audit corrections" (#5-#9).
  - 12:44: "two more fixes" (#10, #11).
  - 13:14: the "Audit fix integration directive" (all eleven; phases A-C; "Do not re-record baselines to manufacture passing
    tests").
  - 14:37: the "Integration, testing and merge directive".
  - 15:12: the "Build 25 audit integration and merge directive". It holds Phase 1, "CORRECT B25R2-BRUSHOFF / APPROVED", and Phase
    6, which authorizes the merge into `wip/b25r2-rev2` once the gates pass.

  All six are now saved verbatim (recovered file above).
- ChatGPT posted progress to issue #4 (comments 1-3) and said it would not write to `wip/requirements-control` while the lead
  updated it ("Canonical records branch deliberately untouched").
- The lead integrated. No conversation between the lead and ChatGPT exists other than these GitHub posts. ChatGPT's internal
  reasoning beyond its posts is UNRECOVERABLE.

## E. Decision and rationale
- **Decision:** integrate the eleven as one batch with the BRUSHOFF fix, test the combined commit, then fast-forward the
  development branch.
  - The batching was the owner's choice: "Batch compatible changes to minimize repeated expensive CI runs" and "Do not allow
    completed corrections to accumulate indefinitely".
  - The corrections themselves are ChatGPT's engineering choices, each the smallest change that turns its red test green.
- **Merge order** (#5 as the base, then #9-#15, then #6-#8) and the conflict rule (every `tests.yml` line kept; the three
  `net_actions.gd` edits touch different lines) are the lead's. The lead's local merge check of 2026-11-08 is recorded in the
  state file.
- **Floors.** Five suites (#5-#9) had no check-count floor. The lead measured them on the branch and added them in `0d252b4`:
  mp04 6, prop01 7, prop05 8, prop02 13, jus03 9. The other six PRs brought their own floors, and they matched.
- **BRUSHOFF.** Strict run 42509510188 on `0d252b4`: 238 of 239 suites passed. The failure was `start_test` 523/0 with 1 SCRIPT
  ERROR, `Dialogue.brush_off` reading `n.plan[0]` on an empty plan (`dialogue.gd:526`). It was already failing on `fe7d8f8` and
  is untouched by every PR, so it is pre-existing. The owner approved fixing it in the batch. Fix `f0a854c`:
  `brushoff_empty_plan_test` 5/0, and 1 failure with the same script error on the old code.
- **Evidence reuse.** The campaign and gate ran on `0d252b4`. The lead reused them for `f0a854c` on this argument (the lead's, in
  the state file): `brush_off` is called only from `main.gd`'s player talk, never by the simulation. The argument is not tested
  separately.
- **Baseline.** Gate 42509523836 had 32 blocking findings, all "difference from the old accepted baseline" (`df67e8e`), the same
  as the development branch's own. Its day-10 and day-30 equilibrium values were identical to the generation 8 candidate. The
  baseline was not replaced: TEST-AUDIT-Q2 needs the owner's explicit approval, and the directive forbids changing it.
- **Risks named at the time:**
  - LIFE-01 changes simulated wages.
  - SAV-01 adds a save key, so the generation 8 candidate might not apply.

  The state file records both.

## F. Implementation and verification

| Evidence | Commit | Result |
|---|---|---|
| Stage A, 11 audit suites, local | `0d252b4` | 87 checks, 0 failures, 0 script errors; every count equals its floor |
| Strict Tests 42509510188 | `0d252b4` | 238/239 suites; `start_test` script error (BRUSHOFF) |
| Gate (in 42509523836) | `0d252b4` | 32 blocking, all baseline-difference; determinism and conservation clean |
| Campaign 42515726815, 365 days, flight recorder on, recorded | `0d252b4` | seed 1: 365/365, 0 CRITICAL, 48 HIGH, 65 MEDIUM, 0 confirmed defects. Seed 2: 365/365, 0 / 99 / 45, 0 confirmed. Same as reference `1f2ff4f` (0/48, 0/99) |
| Strict Tests 42519022430 | `f0a854c` | passed; 0 failed suites; floors met |

- `f0a854c` was pushed to `wip/b25r2-rev2` by fast-forward at 2026-11-08 23:36 UTC.
- GitHub marked PRs #5-#15 merged at 23:37 UTC.
- The audit register's "Integration status" section and issue #4 comment 13 record it.
- Not done: the multiplayer items were not checked on real devices. Every MP item was tested headless only.

## G. Consequences and next action
- The development line now enforces host authority for carts, sites, sales, fittings and chests. Later multiplayer work builds on
  these checks; MP-05's chest rules merged over INV-03's (see [B25-AUD-MP-05](B25-AUD-MP-05.md)).
- The audit register still lists the other records:
  - MP-02, MP-03, MP-06, PROP-03 (later fixed, see [B25-AUD-PROP-06](B25-AUD-PROP-06.md));
  - EMP-01, EMP-02, LIFE-02, REG-01..03, REG-06, REG-08, JUS-02;
  - BIZ-01/02/05/06, TRD-01/03..05, INV-01/02/06, SAV-03..06, NPC-01..05.

  They are open: static suspicions not yet reproduced.
- **Remaining:**
  - the register records for these items (coverage register, section 8);
  - real two-device checks for the MP and PROP items.
