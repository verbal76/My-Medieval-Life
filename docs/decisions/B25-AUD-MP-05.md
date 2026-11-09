# B25-AUD-MP-05: mutual three-tier asset sharing between players (PR #19), two cart defects, rebase onto the development line

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01). Sources:
> - issue #4 comments 6, 7 and 8;
> - PR #19, its body and commits;
> - `docs/audits/2026-11-08_MP05_OWNER_IMPLEMENTATION.md`;
> - commits `dea9683`, `767ea22`, `a898541`, `be307f8`, `a66294c`, `2e74066` and `242ca83`;
> - the lead's tool calls and results from 12:41 to 15:35 UTC, in the session record;
> - Actions runs, including the status of 42664730920 read at 18:3x UTC;
> - the state file.
>
> Times are UTC.

## A. Identity and timeline
- **IDs:**
  - audit item MML-MP-05; proposed register id B25-AUD-MP-05;
  - related: MP-07 (privacy), INV-03 (chests, PR #14), MP-04 (carts, PR #5).
- **Timeline:**
  - **2026-11-08:**
    - 18:52: the owner's design (issue #4 comment 6).
    - 18:58: the owner's clarification that sharing is two-way (comment 7).
    - 19:11-19:16: ChatGPT's commits.
    - 19:14: focused run 42514021833 fails at `8686193`.
    - 19:16: focused run 42514210368 passes 22/0 at `e66d4f9`, after "recognize canonical plural tools/weapons categories in
      tier-3 rule".
    - 19:23: draft PR #19 opened.
    - 19:37: merged onto the integration branch (`dea9683`).
    - 19:39: brush-off guard, `767ea22`.
  - **2026-11-09:**
    - 12:42-12:54: the lead's security review and the first fix, `a898541`.
    - 13:03-13:22: the second defect found and fixed, `be307f8`.
    - 13:33: full Tests 42626491122 on `be307f8`.
    - 14:35: the rebase onto `c9da5db`, as `wip/b25-mp05-on-dev`: `a66294c`, `2e74066`, `242ca83`.
    - 14:38: full Tests 42636628469.
    - 17:27: recorded campaign 42664730920.

## B. Original situation and the owner's requirements
The audit (011) asked how players share chests, carts and property. The owner's rules (issue #4 comments 6 and 7; overnight
directive 2026-11-09):
- No sharing by default.
- Sharing is between two specific players, proposed and accepted. It is "BOTH WAYS, not one-way". This supersedes the
  recommendation in comment 6 that one player could grant access alone.
- Three cumulative tiers:
  1. materials;
  2. plus finished goods;
  3. plus tools and property use.
- Either player may revoke.
- Ownership, sale and demolition are never transferred.
- Theft and ownership rules apply outside sharing.
- The host validates every action.

The owner also listed security checks to do before merging: real host and guest, modified clients, reconnect, UI menus, privacy,
and tools or property outside chests (PR #19 body; state file).

## C. Evidence and investigation
1. **Integration conflict.** `chests.gd` conflicted with INV-03 (PR #14) in `info()` and `_info_container()`. `dea9683` took
   MP-05's version, which keeps INV-03's rule (another player's property is foreign unless it is the acting player's) and adds the
   sharing state. Both regression suites were run on the result.
2. **Review findings, 2026-11-09, by the lead, reading the PR #19 diff.** Verified as correct:
   - chest takes are filtered by tier (`goods`);
   - an offer's tier is bounded to 1-3;
   - each guest receives only its own agreements (`_private_for`, as MP-07 asks);
   - revocation is mutual.
3. **Defect 1: revocation did not release a cart.**
   - Revoking a tier-3 agreement cut chest access at once, but a former partner already pulling the other's cart kept it, because
     `Carts.update` let go only when the puller died or left.
   - Fix `a898541`: a player puller lets go as soon as `Carts.may_use` fails, and the cart stays its owner's.
   - Two checks added to `mp05_mutual_asset_share_test`: 1 failure without the fix, 24/0 with it. Floor 22 → 24.
4. **Defect 2: villagers' carts were never parked.**
   - The lead ran the other cart suites locally after fix 1: `home_test` failed 3 and `underground_struct_test` failed 1.
   - The lead ran both suites with and without fix 1: they failed on `767ea22` too, so PR #19 had introduced the defect, not fix 1.
   - Cause: PR #19 made `Carts.park` release a cart only when the acting player may use it. The simulation parks household and
     mine carts with the host as the acting player, so the host, who may not use that cart, never released it.
   - Fix `be307f8`: the guard now stops only one player making another player let go of a cart they may not use.
   - Results: home_test 124/0, underground_struct_test 90/0, mp05 24/0, mp04_cart_gateway 6/0.
5. **Old-branch failures.** Full Tests 42626491122 on `be307f8` failed three suites: `settle_review_test` (5), `aspiration_test`
   Q8 (3) and `migration_test` (1). No script errors, floors or crashes were involved; these were ordinary assertion failures.
   - Hypothesis (the lead's): `wip/b25-mp05-integration` carries PRs #16-#18 as originally merged. Those are the raw PR #17
     courting defect and PR #18's settlement, both already corrected on the development line.
   - Test: the lead rebuilt MP-05 on the current development head (`242ca83` = `c9da5db` + PR #19 merge + both fixes, by clean
     cherry-picks). All three suites pass locally there (settle_review 112/0, migration 109/0, aspiration 159/0), and so does full
     CI 42636628469.
   - This confirms the hypothesis by exclusion: the same suites pass once the old PR code is replaced. It is not a bisection.
   - The same settle_review and migration failures had already been seen on `a69069f` and fixed by `6e02171`
     ([B25-AUD-PROP-06](B25-AUD-PROP-06.md)), which supports the attribution.

## D. Communication and coordination
- **Owner:** the rules, posted to issue #4 by ChatGPT. The ChatGPT conversation is not available.
- **ChatGPT:** PR #19.
- **Lead:**
  - review;
  - both fixes;
  - the rebase;
  - CI;
  - the campaign decision. The state file says MP-05 changes cart pulling and parking, so it needs its own recorded campaign.
- **Affected workstreams:**
  - INV-03 (merged rule);
  - MP-04 (cart gateway: suite re-run 6/0);
  - MP-07 (privacy: `_private_for`);
  - REG-04 and REG-05 (future journeys will move carts).

## E. Decision and rationale
- **Fix 1:** cart access follows the agreement continuously, which the owner's "Either player may revoke" requires.
- **Fix 2:** keep the simulation's parking as it was before MP-05, and guard only player against player. The alternative of
  leaving the guard broke villager logistics.
- **Rebase rather than merging the old branch:** the old branch carried superseded PR code. Rebuilding on the tested development
  head avoids reintroducing it.
- **Approval:** owner design. The fixes are engineering corrections inside it.
- **Known limitation, accepted for now and recorded:** a guest promoted to host after the host is lost holds only its own pairs'
  agreements, so other pairs' agreements are lost. Pending offers already behave the same way.

## F. Verification status (2026-11-09 18:3x UTC)

| Evidence | Commit | Result |
|---|---|---|
| Focused 42514210368 | `e66d4f9` | 22/0 |
| Local suites after both fixes | `be307f8` | listed in C4 |
| Full Tests 42626491122 | `be307f8` | failed 3 suites, attributed to old PR code (C5) |
| Full Tests 42636628469 | `242ca83` | passed |
| Recorded campaign 42664730920 | `242ca83` | **running.** Segment 1 of both seeds passed; segment 2 in progress at the last check (18:00 UTC update). Never cancel it (SIM-02) |

**Not done:**
- real two-device host and guest test;
- modified-client request forging;
- reconnect;
- UI menu walk (touch and pad).

## G. Consequences and next action
- MP-05 is not on the development line. `wip/b25r2-rev2` is at `c9da5db`.
- Next, by the lead's plan in the state file: when campaign 42664730920 is clean, fast-forward `wip/b25r2-rev2` to `242ca83`,
  close PR #19 naming the SHA, and update the state file and the audit register.
- The device and security checks remain, and need the owner or real devices.
- `wip/b25-mp05-integration` (`be307f8`) is superseded by `wip/b25-mp05-on-dev`. Keep it until the merge (BRANCH-POL-01).
