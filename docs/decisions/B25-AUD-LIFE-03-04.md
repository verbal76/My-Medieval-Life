# B25-AUD-LIFE-03-04: sage succession and widow remarriage (PRs #16, #17), two integration defects, merged at `229f76e`

> **Reconstructed 2026-11-09 by the documentation agent** (HAG-FORENSICS-01). Sources:
> - PRs #16 and #17;
> - issue #4 comments 4 and 8;
> - `docs/audits/2026-11-08_LIFE03_OWNER_IMPLEMENTATION.md` and `docs/audits/2026-11-08_LIFE04_OWNER_IMPLEMENTATION.md`;
> - commits `46d934c`, `494af9a` (the same change as `d6e9994`) and `229f76e`;
> - the state file;
> - Actions runs.
>
> Times are UTC.

## A. Identity and timeline
- **IDs:** audit items MML-LIFE-03 and MML-LIFE-04. Proposed register ids B25-AUD-LIFE-03 and B25-AUD-LIFE-04 (coverage register,
  section 8).
- **Who:** ChatGPT implemented the features. The lead found and fixed two defects at integration.
- **Timeline:**
  - 2026-11-08 18:22: the owner's decisions are posted to issue #4.
  - 19:04-19:18: focused runs 42513138777, 42513313395 and 42514346703, all green.
  - 19:23: draft PRs opened.
  - 19:37: merged onto `wip/b25-audit-integration` (`d67fa11`, `4d7cc77`).
  - 19:56: `46d934c`.
  - 21:17: strict runs 42524448237 and 42524437969 fail on `aspiration_test`.
  - 22:33: `494af9a`; strict run 42530864510 passes.
  - 2026-11-09 03:43: recorded campaign 42557922632.
  - 08:40: merge `229f76e`, pushed to `wip/b25r2-rev2`.

## B. Original situation
The audit raised two policy questions:
- LIFE-03: the sage could never be replaced, so the sage's services and teachable magic were lost for good at death.
- LIFE-04: a widowed person could not court again.

The owner answered on 2026-11-08 (issue #4 comment 4):
- LIFE-03 "APPROVED IN PRINCIPLE ... a qualified apprentice may eventually succeed ... no instant replacement or blanket spell
  grant".
- LIFE-04 "APPROVED. A surviving spouse may court and remarry ... Preserve the original marriage/deceased spouse".

The overnight directive of 2026-11-09 restates both decisions.

## C. Evidence and investigation
- **PR #16 (LIFE-03):** delayed succession by a person with healing skill. Focused run 42513313395: 9/0.
- **PR #17 (LIFE-04):** remarriage for NPCs and players; the former spouse is kept. Focused run 42514346703: 15/0.
- **Defect 1, found by the lead during integration verification, while writing `owner_features_integration_test`; recorded in
  `46d934c` (the transcript shows the fix written at 19:49 UTC):**
  - PR #16's guard was `Skills.level(o, "healing") < 1`. `Skills.level` is 1 for every untrained person, so the guard excluded
    nobody: any adult without a trade could become the sage.
  - The new `owner_features_integration_test` (floor 16) gives 16/0 with the fix and 3 failures with PR #16 as merged.
- **Defect 2, found by the strict suite:**
  - In runs 42524448237 (`46d934c`) and 42524437969 (`6e02171`), `aspiration_test` Q8 failed 3 checks ("partnered, too soon,
    nothing weighed").
  - Cause, from `494af9a`'s message: PR #17 made `can_court` and dawn courting use `Life.free_to_partner`. For a villager that
    was `not has_partner`, and `has_partner` also requires the partner's record to point back. So a living partner whose record
    does not point back counted as free, and a partnered villager could marry.
  - Before PR #17, any living partner blocked.

## D. Communication and coordination
- **Requested by:** the owner. The rules were agreed in ChatGPT; that conversation is not available, and issue #4 holds the
  decisions.
- **Implemented by:** ChatGPT (PRs).
- **Reviewed, fixed and tested by:** the lead.
- **Constraints passed on:**
  - the owner's 2026-11-08 directives (recovered): "validate with targeted tests"; "no instant replacement or blanket spell grant";
  - the PRs' own merge gates.
- **Affected workstreams:** PROP-06's branch carries the same LIFE-04 fix (`d6e9994`) because it was built on the PR #16/#17
  merges.

## E. Decision and rationale
- **LIFE-03:** a successor needs healing level 2, `SAGE_HEALING = 2`. This is the lead's engineering choice: level 2 is the level
  the healing tonic needs, per the commit. A trained newcomer comes when nobody local qualifies.
  - Alternative: keep PR #16's guard. Rejected because the guard was a no-op.
- **LIFE-04:** `free_to_partner` frees a person only when their partner is dead or gone, for villagers and players alike.
  `has_partner` is unchanged, because pregnancy and migration read it.
  - This keeps the owner's rule ("a living spouse cannot be bypassed; widowhood frees", commit message) and the old behaviour for
    the living.
  - No other alternative is recorded.
- **Approval:** owner decisions. Both fixes are engineering corrections inside them.

## F. Implementation and verification

| Evidence | Commit | Result |
|---|---|---|
| `aspiration_test`, `life04_remarriage_test`, relations, family, family_first (local) | `494af9a` | 159/0, 15/0, 80/0, 51/0, 104/0 |
| Strict Tests 42530864510 | `494af9a` | passed |
| Gate 42530880459 | `494af9a` | 33 blocking findings, all baseline-difference kind (one more day-10/30 value than the development branch's 32, from the features' changed village); determinism identical |
| Campaign 42536147616 (`record: false`, the lead's input error) | `494af9a` | 365/365 both seeds, no fatal stop, no leaks; no recorder findings, so not comparable (KNOWN_ISSUES KI-11) |
| Recorded campaign 42557922632 | `494af9a` | seed 1: 365/365, 0 CRITICAL, 17 HIGH, 46 MEDIUM, 0 confirmed. Seed 2: 365/365, 0 / 91 / 35, 0 confirmed; archive ok |

- **Merge:** `229f76e` merges `f0a854c` and `494af9a`. The merged tree equals `494af9a`'s (the tested tree): `tests.yml` and the
  floors conflicted only where both sides added lines.
- Pushed to `wip/b25r2-rev2` at 2026-11-09 08:40 UTC. PRs #16 and #17 were marked merged at 08:40:59.

## G. Consequences and next action
- Courting eligibility now depends on the partner's life state, not on whether the partner's record points back.
- The sage post can be refilled.
- Seed 1's HIGH findings fell from 48 (Batch A) to 17 on this branch. Nobody has attributed this change (KNOWN_ISSUES KI-06).
- Not done:
  - LIFE-04 player and guest remarriage was not tested on real devices;
  - the owner has not playtested either feature.
- Register: records B25-AUD-LIFE-03 and B25-AUD-LIFE-04 at INTEGRATED and INTEGRATION VERIFIED, once the lead runs the commands.
  They are not COMPLETE.
