# CHAPEL-PURPOSE: the chapel maintains itself, not enriches itself

## Identification
- Decision ID: CHAPEL-PURPOSE (register, kind `approved`). Related:
  - CHAPEL-LENDING (concept approved, proposal only);
  - B25-CHAPEL-FOOD-Q (answered by this directive);
  - CHAPEL-GIVE-14-Q (OPEN);
  - X20-CHAPEL-FIX (the earlier correction).
- Date: 2026-11-02
- Project / build: My Medieval Life, Build 25
- Decided by: owner
- Source of authority: [`docs/directives/2026-11-02_chapel_economic_purpose_correction.md`](../directives/2026-11-02_chapel_economic_purpose_correction.md)
- Status: approval OWNER APPROVED; implementation INTEGRATED; verification NOT TESTED in the register's sense; completion
  OPEN. Copied 2026-11-02; the register is authoritative.
- Supersedes: the lead's provisional 6-day food alms line,
  [X20-CHAPEL-FIX--food-line-6-day](X20-CHAPEL-FIX--food-line-6-day.md).

## Original problem
- **First correction (X20-CHAPEL-FIX, 2026-11-01).** The chapel was absorbing 77-83% of the village's coins. The fix brought
  that to 0.9-1.2% (runs 41279031310 and 41279051834 on `ae8641d`).
- **Then the food store.** At yield 2.0 the chapel ended the year with 763 and 2,142 wheat, mostly from its own plot. The store
  never spoiled, and its only outflow was relief on request. ([`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md),
  "X20-CHAPEL-FIX follow-up".)
- **The open question.** The lead asked the owner what the church should do with food it does not need (B25-CHAPEL-FOOD-Q).
- **The owner's statement of the problem:** the chapel "is not intended to accumulate money and food indefinitely while
  villagers struggle or starve".

## Owner's direction (quoted)
> The chapel is a charitable institution serving the village. It is not intended to accumulate money and food indefinitely while villagers struggle or starve.
>
> Think of it as a community savings and emergency assistance institution.

> Preserve the existing 14-day household hardship assessment for ordinary charitable eligibility.
>
> Distinguish that assessment from the existing emergency food trigger. Households facing imminent hunger must receive higher priority and faster assistance.

> Keep the 14-day hardship assessment consistent across food and financial aid, while preserving faster emergency intervention for imminent starvation.

> The chapel should accumulate resources when the village is prosperous and use those resources when villagers need help.
>
> It should maintain itself, not enrich itself.

> Do not guarantee survival when supplies genuinely do not exist.
>
> However, preventable starvation caused by charitable food sitting unused in storage is unacceptable.

## Interpretation (lead agent and the worker on `wip/b25-chapel-purpose`)
Implemented at `8b203c5`:
- **Food reserve.** The chapel keeps only an emergency reserve of 7 days of recent relief (PROVISIONAL). Clergy eat at home;
  there is no chapel livestock; seed is never given.
- **Weekly food alms** at the 14-day line, shared a portion at a time.
- **A daily emergency path** that finds households itself, with priority to missed meals, then children and elders.
- **Fastest-spoiling food goes out first.** The store has no age record, so "older usable food first" could not be applied
  literally.
- **Delivery** by clergy or volunteers in parcels that stay the chapel's until handed over.
- **Money:** the reserve audit found nothing held beyond legitimate needs, so no change.
- **The giving rule (agent choice, PROVISIONAL, put to the owner as CHAPEL-GIVE-14-Q, still OPEN).** Households offer wheat
  only above 14 days of food, so alms food is not offered straight back.

## Reasoning and alternatives
- The owner's reasons are quoted above: charity, not enrichment; and no preventable starvation while charitable food sits in
  storage.
- **Alternatives for surplus food** were put to the owner in B25-CHAPEL-FOOD-Q (register text, written by the lead):
  - A: sow only to need. The worker and the lead recommended this.
  - B: sell the surplus and give the coins as alms.
  - C: pass it to the manor's granary.
  - D: leave it, and let spoilage cap it.
- **The owner's answer chose none of these by letter.** It set the purpose: accumulate when prosperous, use it when needed.
  The register notes "No sowing cap was asked for." Why A-D were not taken: UNKNOWN beyond that.
- **Lending** was approved as a concept only. The owner said: "Do not invent interest rates, collateral seizure, repayment
  schedules, or debt enforcement without an approved design."

## Consequences
- **Systems affected:** the chapel's food store and alms, money alms, decay (the chapel store spoils), relief delivery,
  household giving, and instrumentation.
- **The 14-day line now governs both food and money aid.** Changing it, or removing the emergency path, needs the owner.
- **Conservation still holds:** only goods and coins move. The default fingerprint changed from `b01fbf44` to `fdbdde28`,
  because the emergency round now reaches households that never asked.
- **Open owner questions:** CHAPEL-GIVE-14-Q, and the nine lending questions in `docs/expansion20/CHAPEL_LENDING_PROPOSAL.md`
  on the Build 25 source.

## Implementation
- Branch `wip/b25-chapel-purpose`, commits `2745be7`, `933c1da`, `c5be409`, `780dcfd` and `8ec9a85`; merged as `8b203c5`.
- Tests: chapel_test 173, run_tests 3602, conservation 8, net_econ_integrity 126, migration 109, save_transfer 21,
  elder_provision 11, wiki_test, all 0 failures (local).
- Starvation investigation (stress test at yield 0.5): three deaths on day 34 in a village-wide famine. The chapel held 1 grain
  and 0 coins, and the households had asked and been delivered food. None was preventable. One defect was fixed: the last odd
  grain was never given.
- Not done: a run past day 40 on this code. The year-long evidence comes from the flight campaign 41469410306 on `8acbdea`.

## When to reconsider
The owner set no trigger (UNKNOWN). The directive's own test is preventable starvation while the chapel holds usable food or
funds. Evidence of that would reopen the implementation, not the purpose.
