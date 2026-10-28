# Owner direction — TILL-D1 and current decision-register cleanup (2026-10-28)

## Owner's words (this conversation)
> "Yes I agree with option A and also whatever documents you found those open questions for make sure that they are updated to reflect that answers have already been given and they are no longer open"

This answers **TILL-D1: OPTION A**. Coins earned by a **living household** in its storefront till remain that household's property when it surrenders its house, its lease ends or is taken back, or it migrates. Transfer the existing till balance to the household's own real funds before the property changes hands; the next holder inherits an empty till. Preserve monetary conservation, legitimate individual/household ownership, save/load and recorded transfers. Do not confuse this with the already-established distinct rule for a **household that actually ends** (escheat to the manor where appropriate). This is a **policy approval, not a claim that the correction is already implemented or tested**.

## Reconciliation of remaining entries previously shown as OPEN

Only previously evidenced owner policy should be marked APPROVED; do not treat a recommendation as owner authorization. The owner's immediate project priority is to deliver the current Medieval testing build, preserve progress, then pause Medieval work in favor of Upwardly. Unanswered optional questions must be parked with `DEFERRED` disposition rather than repeatedly presented as immediate blockers.

- **MP-INTERACT-Q1 — DEFERRED, not answered.** Existing player-to-player goods contracts are implemented; player-to-player **service/work** contracts have not been expressly authorized in the current build. No new service-contract feature to delay the playtest. Preserve the question for later owner choice.
- **MP-INTERACT-Q2 — DEFERRED, not answered.** Keep the presently implemented and tested target-selection behavior (nearest eligible person, other player selectable by tap/click/Next). Do not silently add player-first Talk priority during this release cycle; revisit only if requested or supported by device playtest.
- **REG-X20-D2 — DEFERRED, not answered.** The lack-of-food-to-buy hunger-migration case is a documented engineering/policy question. Preserve the finding; do not falsely claim this correction is implemented or approved on the basis of a recommendation.
- **REG-X20-D3 — ALREADY APPROVED AS POLICY.** The earlier owner-approved `REG-BUY-D1` explicitly permits **settlement-to-settlement food sales** governed by real stock, household needs, willingness and payment. The missing live RegionalMarket/road-trade integration remains real **future engineering work**, not an unanswered permission to trade. Do not claim it is implemented, or trigger new implementation solely from this clerical reconciliation.
- **REG-X20-D4 — DEFERRED, not answered.** Preserve the documented money-circulation imbalance and the existing `REG-CIRC-D1` deferral. Do not introduce artificial coin recirculation, minting or an economy redesign while this project is being paused.

The historical 39-answer owner reconciliation dated 2026-10-27 is already reflected in the authoritative register for the Living Economy decisions. Do not reopen or reask those resolved answers simply because an older decision packet or snapshot still labels them open. `ARMOR-CATALOG-D1` and `ID-D3` have **conditional/provisional owner answers**, not unqualified final approval; maintain those conditions until their specified review/evidence gates.

## Administrative action

Update only the authoritative `docs/requirements/requirements.json` on `staging/my-medieval-life`; append dated history to every changed record, preserve prior owner words and historical snapshots, and regenerate the views with `python3 tools/check_requirements.py --write` on the same staging branch. Note the status explicitly as approved versus deferred versus provisional. **No gameplay implementation, build, test campaign, feature activation, or release is authorized by this register cleanup.**
