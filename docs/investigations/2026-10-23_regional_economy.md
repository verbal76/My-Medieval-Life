# Regional economy investigation (REG-INV-01), 2026-10-23

Owner directive: `docs/directives/2026-10-23_regional_economy_investigation.md`. Code: `wip/build18` (`36beb67` for the runs
below; settlement code `game/scripts/core/settlement/offmap.gd`, `regions.gd`). No balance value was changed. Every probe
below was a throwaway script on a scratch copy; nothing it changed was committed.

## Evidence

| Run | What | Result |
|---|---|---|
| `regions_sim` 200 days, seed 1, settlements alone | baseline | Higham 99 → 89 people (10 deaths from about day 100); Higham coins about 3,300 → 1,823; Garton 1,404 → 2,874; all books balance |
| probe, same, road coin flows | where Higham's coins go | Higham paid Garton 1,497 coins on the road (ore and coal for its forge) and took in 6; Garton's households hold the gain (1,121 → 2,385) |
| probe, road trade off | is the trade the cause? | Higham keeps all 99 people, coins flat at 3,314 |
| probe, traders also carry finished goods | is the missing return channel enough? | No: road trade flows both ways for the others, but Higham still nets −1,661 and loses 22 |
| probe, trader wage reserve consistent with its buying rule | the dying households | 0 deaths, but Higham's trader then hardly imports ore (a different design, not a fix) |
| `regions_sim` 200 days with the necessity-wage correction (`wip/b18-wagefix`) | the narrow PAR-02A fix | Higham 98 of 99 (1 death); other settlements unchanged; books balance |
| `economy_sim` 90 days, seed 1 (village with the five) | village sustainability | no leaks; village 104 → 129 people, food 17 days, treasury 498, unemployed 14; settlements' coins 9,249 → 4,610; the village took in 4,927 from the traders and paid back 288 |

## 1. Higham's decline

Two causes, one legitimate and one a defect:

- **Legitimate economics (keep).** Higham's forge needs ore and coal it cannot dig; it buys them from Garton through the
  traders' road trade and sells Garton nothing back. Its coins fall by exactly what Garton gains. A town that imports more
  than it exports grows poorer; WDR-022 allows that.
- **Defect (fix proposed, held for the owner: REG-WAGE-D1).** Only Higham's merchant and smith households died. A
  trader's wage reserve is fixed at 85% of its founding till (`offmap.gd`, founding), while its wholesale buying may spend
  down to 20 coins plus half that reserve. After buying ore, Higham's trader sat permanently below its wage reserve, so its
  own households were never paid and starved beside a till of about 170 coins (the smith likewise, below its reserve of
  40). That contradicts PAR-02A (owner, OD-19): "The reserve is intended to protect essential needs, not prevent the
  household from satisfying them". The correction on `wip/b18-wagefix` (`cf76ed2`) pays a worker household that is already
  hungry and cannot buy a day's food its wage even below the reserve; nothing else changes.
- **A circulation gap (owner decision: REG-CIRC-D1).** Garton's households cannot spend what they earn: Garton has no
  cook, tanner or weaver, and the traders' road trade carries only raw materials, seeds and medicines (`settlements.json`
  `carry`), so the coins never return. Simply letting the traders carry finished goods did not help Higham (it then exported
  its own food and goods), so the return channel is a design choice, not a constant to tune.

## 2. Is the village sustainable?

Over 90 days, yes: it grows, eats and saves. But the regional money flows one way. The old caravan's purse refilled by
itself (an outside money source); the traders now spend only their settlements' finite coins, and the village buys back
almost nothing (seeds, medicines, now luxuries). The settlements lost half their coins in 90 days; the village's net intake
per 15 days is 676, 847, 1,083, 729, 716, 588, tapering as the traders run short ("traders unable to buy" rises 0 → 9). In a
year the settlements' coins will be near their floors, the caravan's income to the village will fall towards what the
village spends with them, and the settlements' own economies will be short of coin. That is what this world's rules
produce today, not a ledger fault; the missing piece is the village's ability to buy from them (section 3). The year-long
picture belongs to the Build 18 long runs (REL18-LONGRUN), which should report the regional coin trend.

## 3. The village buying from the settlements (REG-BUY-01)

Approved in principle by Q18-10 (owner: "Anyone may purchase goods from another settlement, including individual villagers,
households, merchants, businesses, and settlement treasuries"). Dependencies:
1. **REG-PARTY-01:** one trading-party interface over the five settlements. RegionalMarket (`regional.gd`) and the couriers
   still trade with the prospective `SettlementLedger` parties (with configured income lines), not with the five.
2. **What a settlement releases (REG-BUY-D1, owner):** whether its sellers may sell food their own households will need.
3. **Carriage:** on the traders' visits (exists), by courier (REG-COURIER-01), or self-collection (visiting a settlement is
   Q18-8, kept for Build 20+).
4. **TRADE-CREDIT** (approved) for barter and credit, after the cash path works.

## 4. Courier booths on the five settlements (REG-COURIER-01)

`couriers.gd` is prospective: not in the live game loop, driven only by tests, and its off-map parties are
`SettlementLedger`s. Work: the REG-PARTY-01 interface (booth per settlement served by its trader); route lengths from
`settlements.json` miles; known recipients from real trade with the five; couriers stepped in the live World and saved;
wiki pages; tests. Size L. No new owner decision found (X18-Q12, -BOOTH, -POST, -Q13 are decided; fee coefficients stay the
provisional X18-FEES).

## 5. Settlement demographics (REG-DEMO-01)

Households are counts (adults, children) with no ages: nobody is born, ages, grows up or dies of age; only hunger removes
people. Under the approved 8-day year the village ages a calendar year every 8 days, so over a year the village turns over
generations while the settlements are frozen and can only shrink. Work, under SET-C-SIM's "same rules, lighter detail": ages
(per member or by cohort), births and age deaths from the village's life rules (`balance.json` "life"), children becoming
workers, household formation and dissolution, inheritance by a recorded rule (today a dead household's coins and pantry go
to the treasury), save migration. MIGRATE-18 depends on it (people who move need an age and a household).

## Recommended order

1. REG-WAGE-D1: merge the necessity-wage correction (small, tested; owner's yes).
2. REG-DEMO-01 (no owner decision needed; L).
3. REG-PARTY-01 (engineering; M), then REG-BUY-01 once REG-BUY-D1 is answered, then REG-COURIER-01 (L).
4. MIGRATE-18 and TRADE-CREDIT on top.
5. REG-CIRC-D1 when the owner chooses; the long runs (REL18-LONGRUN) report the regional coin trend either way.
