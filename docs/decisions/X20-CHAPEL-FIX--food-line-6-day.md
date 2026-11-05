# X20-CHAPEL-FIX (food line): chapel food alms only to households under 6 days of food

## Identification
- Decision ID: X20-CHAPEL-FIX, food-alms line. It had no register ID of its own; it is recorded in X20-CHAPEL-FIX's history
  for 2026-11-02.
- Date: 2026-11-02
- Project / build: My Medieval Life, Build 25
- Decided by: **the lead agent, provisionally.** It was not an owner decision.
- Source of authority: the merge `35fbd48` (`wip/b25-chapel-food` `fa75bd1`), the register history of X20-CHAPEL-FIX, and
  [`docs/DEVELOPMENT_CHANGELOG.md`](../DEVELOPMENT_CHANGELOG.md), entry "X20-CHAPEL-FIX follow-up: the chapel's food store".
- Status: **SUPERSEDED** on 2026-11-02 by the owner's 14-day line in [CHAPEL-PURPOSE](CHAPEL-PURPOSE.md), implemented at
  `8b203c5`. This record is kept unchanged as history.

## Original problem
The chapel's food store grew without limit, to 763 and 2,142 wheat over a year at yield 2.0. It never spoiled, and its only
outflow was relief on request. A weekly `Chapel.food_alms` was added to give the surplus away, and it needed an eligibility
line.

## Owner's direction (quoted)
None for this line. The owner had approved the X20-CHAPEL-FIX correction, which set a 14-day essentials line for *money*
alms. The food line was the lead's choice.

## Interpretation and the choice made
From the changelog and the register history:
- `food_alms` keeps a reserve of 4 weeks of relief for 14 days.
- It gives the rest to households below `goods_keep_days` of food, counting what their coins can buy, poorest per member
  first. `goods_keep_days` is 6 days, PROVISIONAL.
- The lead kept the 6-day line rather than the 14-day essentials line.

## Reasoning and alternatives
- **Recorded reason:** "Below 6 days a household offers no wheat, so food given as alms cannot be offered straight back."
  Households offered wheat to the chapel above `goods_keep_days`. A 14-day food line would have let a household receive alms
  and offer wheat back in the same week.
- **Alternative considered:** the 14-day essentials line used for money. Why it was rejected: the reason above.
- **Other alternatives:** UNKNOWN.
- **Status of both values:** both were recorded as agent-provisional.

## Consequences (while in force)
- Food alms reached only households under 6 days of food. Money alms used 14 days.
- The default fingerprint changed to `b01fbf44`.

## Why it was superseded
The owner's chapel purpose directive (2026-11-02) said: "Keep the 14-day hardship assessment consistent across food and
financial aid". The give-and-take problem behind the 6-day choice was then handled differently:
- the household *giving* threshold moved to 14 days instead, at `8b203c5`;
- that change is put to the owner as CHAPEL-GIVE-14-Q, still OPEN.

So the reason for the 6-day line was kept, but solved on the giving side rather than the alms side.

## Implementation
- `35fbd48` (merged), with tests on the branch: chapel_test 137, conservation 8, net_econ_integrity 126, migration 109,
  wiki_test, all 0 failures (local).
- Replaced in `8b203c5`.

## When to reconsider
Not applicable while it is superseded. Restoring a 6-day food line would contradict the owner's 14-day instruction and would
need the owner.
