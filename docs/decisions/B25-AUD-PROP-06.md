# B25-AUD-PROP-06: a departing household's property settled as one transaction (PR #18 corrected); PROP-03 eviction test

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01). Sources:
> - PR #18 and issue #4 comments 5 and 8;
> - the owner's PROP-06 directive, saved verbatim:
>   [`2026-11-08_prop06_estate_tenancy_migration.md`](../directives/2026-11-08_prop06_estate_tenancy_migration.md);
> - the 2026-11-09 overnight directive;
> - commits `6e02171`, `2a37653`, `96b071c` and `b727954`;
> - the gate logs of 42524440558 and 42528190244, read in this recovery;
> - the state file.
>
> Times are UTC.

## A. Identity and timeline
- **IDs:** audit items MML-PROP-06 and MML-PROP-03. Proposed register ids B25-AUD-PROP-06 and B25-AUD-PROP-03.
- **Timeline:**
  - 2026-11-08 18:50: the owner's PROP-06 rule (issue #4 comment 5).
  - 19:15 and 19:17: focused runs. 42514107196 failed at `831d704`. 42514264240 passed 10/0 at `207d97d`, after the test was
    changed to "isolate sale accounting from pre-existing family rent obligations".
  - 19:23: PR #18.
  - 19:37: merged onto the integration branch (`a69069f`).
  - 20:40, and again at 21:42: the owner's PROP-06 directive (the same text sent twice).
  - 21:17: `6e02171`.
  - 21:49: `2a37653`.
  - 23:26: `a7071aa`.
  - 2026-11-09 03:43: recorded campaign 42557925404.
  - 08:41: merge commit `96b071c`; its strict run 42587815471 passed.
  - 09:39: `wip/b25r2-rev2` fast-forwarded to `96b071c`.
  - 09:41: the PROP-03 test `b727954`.

## B. Original situation
The audit asked what happens to the property of a household that leaves the village.

The owner ruled on 2026-11-08 18:50:
- owned property may be sold before leaving, and the household keeps the proceeds;
- leased property is surrendered, with the manor taking the land, improvements and materials left on the parcel;
- personal belongings and money go with the family.

The directive then added the rules PR #18 did not meet:
- "Multi-parcel estates ... must be allowed to migrate";
- tenants keep their leases under the new landlord;
- "Failed sales must be atomic"; "Complete rollback after failure";
- 18 numbered test cases.

## C. Evidence and investigation
- **PR #18 as merged (`a69069f`), from `6e02171`'s message:** it "refused any household with an estate or let property (blocking
  migration for good) and sold piece by piece with no rollback".
  - The new `prop06_estate_transaction_test`, which holds the directive's 18 cases, failed 19 checks on PR #18's code.
- **Expectations that assumed no proceeds:** `settle_review_test` (5 checks) and `migration_test` (1 check) already failed on
  `a69069f`, because they assumed the manor pays nothing when a household leaves. Their expected values now add the sale
  proceeds, and the exact equalities stay. This is a changed test expectation. The commit gives its reason; it does not cite
  TEST-GOV-01's classes by name (this record classes it as "outdated expectation").
- **The Lorekeeper's hut:**
  - The lead found it while writing the directive's cases. `Property.held_by` lists parcels and homes only, so an owned building
    that is not a home type was neither sold nor surrendered.
  - Fixed in `2a37653`: the test went 61/0, and the hut check fails on `6e02171`. The floor rose from 57 to 61.
  - The owner's overnight directive of 2026-11-09 then said "The Lorekeeper's hut is included when selling owned property".
- **PROP-03:** on `f0a854c`, `Property._release` cleared the tenancy at the end of a lease or on eviction, but left the former
  tenant's unfinished site on the parcel. The manor could then not let it again. PROP-06's `_release` change fixes this.
  - `b727954` pins the eviction path: `prop03_eviction_site_test` 5/0 on `96b071c`.
  - Its commit message says the test fails 4 checks with `f0a854c`'s `property.gd`. The lead's later state-file entry says 3.
    Nobody re-measured it. Both statements are kept.

## D. Communication and coordination
- **Owner:** the rule (issue #4) and the directive, given in the lead session.
- **ChatGPT:** PR #18.
- **Lead:**
  - the correction;
  - the hut finding. How the owner learned of it is not recorded; the overnight directive of 2026-11-09 06:48 UTC names it;
  - the PROP-03 test.
- **Interactions the lead checked, recorded in the state file:**
  - BIZ-04 venture tills follow `keep_till`'s venture-owner rule (case 18);
  - the INV-04 stash belongs to players only, so NPC migration does not touch it;
  - REG-02 (stale journey, trade credit) is outside the settlement;
  - REG-05 must call this settlement where its walk starts.

## E. Decision and rationale
The decision is `Migration._settle_departure_property`: plan, preflight, then execute. The steps are in `6e02171`'s message:
1. Every parcel and building the household owns is sold to the manor at `sale_value`, once each. Whole estates are included, and
   modules are sold before their anchor.
2. Let property is sold with the tenant's lease intact.
3. The household's own leases are surrendered through `Property._release`.
4. A preflight checks titles, tenancy, the manor's funds and the payee before anything changes.
5. If any step still fails, every touched record is restored: records, treasury, purses, pantries, granary, loot, stats, players'
   coins and the log.
6. On insolvency, nothing changes.
7. Materials on the household's own unfinished site go to its pantry.

**Why.** The owner's directive requires every one of these points. Alternative: keep PR #18. It was rejected because it broke
three of the owner's rules (estates, tenants, atomicity).

**Approval.** This is an owner decision. The settlement design is the lead's engineering choice within it.

**Risk named at the time.** Settlement now pays proceeds, so the simulated economy changes. The gate shows 33 baseline-difference
findings. The campaign was clean.

## F. Implementation and verification

| Evidence | Commit | Result |
|---|---|---|
| `prop06_estate_transaction_test` | `2a37653` | 61/0, floor 61; PR #18 code: 19 failures |
| Ten related suites, local: prop06_migration_property 10, migration 109, home_ref 40, settle_review 112, till_ownership 71, settlement_life 54, settlement_folk 36, business_money 37, business_ownership 165, property 123 | `6e02171` | 0 failures |
| Strict 42524437969 | `6e02171` | failed: `aspiration_test` Q8, the PR #17 defect (see [B25-AUD-LIFE-03-04](B25-AUD-LIFE-03-04.md)), fixed here as `d6e9994` |
| Strict 42530867151 | `d6e9994` | failed only `start_test` (BRUSHOFF, fixed in `a7071aa`) |
| Strict 42535255473 | `a7071aa` | passed |
| Gates 42524440558, 42528190244, 42535257321 | `6e02171`, `2a37653`, `a7071aa` | 33 blocking findings each, all baseline-difference; determinism identical ("the recorder changes nothing and the run is reproducible") |
| Campaign 42540721533 (`record: false`) | `a7071aa` | 365/365, no fatal stop; not comparable |
| Recorded campaign 42557925404 | `a7071aa` | seed 1: 365/365, 0 CRITICAL, 17 HIGH, 0 confirmed. Seed 2: 365/365, 0 / 91, 0 confirmed; archive ok |
| Strict 42587815471 | `96b071c` (merge of `229f76e` and `a7071aa`) | passed |
| `prop03_eviction_site_test` | `96b071c` | 5/0 |

The campaign results were the same as for LIFE-03/04. The lead noted the reason in the state file: "its settlement runs only when
a household leaves".

## G. Consequences and next action
- Migration can no longer be blocked forever by property ownership.
- The manor's treasury now pays sale proceeds.
- REG-05 (physical migration, approved, not implemented) must start this settlement where the walk starts.
- PROP-03 is fixed through PROP-06 and pinned by its own test, merged at `c9da5db`.
- Not done: the owner has not playtested migration with property.
