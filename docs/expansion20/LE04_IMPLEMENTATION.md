# Expansion 20, LE-04: implementation note and handoff (organic finance, merchants and manor behaviour)

Register LE-04 (gate "Costs, default and refusal paths"; branch `wip/x20-le04`, from LE-03's frozen `8fff5ce`). Authority: owner
directive 2026-10-30 (X20-RESUME s.4), the lead's LE-04 brief (2026-10-30), design s.10, s.12, s.17; owner answers OD-LE-03 (D02),
OD-LE-04 (D03), OD-LE-07 (D06), OD-LE-11 (D10), OD-LE-13B (D12). Excluded: lending, interest, manor emergency loans (OD-LE-05B,
OD-LE-06). Everything new is behind `game/data/economy.json` `"enabled": false` (and `market.drive`); developer reference only.
Every integration goes through the transaction authority (`docs/expansion20/TRANSACTION_AUTHORITY.md`).

## Status (keep current)

| Part | State | Where |
|---|---|---|
| Build 24 review items 6 and 7 (till handover, stall commission record) | done `3073b95` | `business_money.gd::keep_till`, `stalls.gd::settle`; `till_ownership_test` |
| 1a Village parties of the authority (manor, households, chapel, tills) | done `74b99de` | `econ_transactions.gd`; INT-607; `le04_test` |
| 1b The manor's tools through the economy (buy via the authority, else CON-01 commission) | done `74b99de` | `econ_market.gd::manor_tools`; INT-608 |
| 1 Business identity and separate accounts (recorded contributions and distributions; one owner per business) | done (see commit log) | section 1; `le04_test::test_business_accounts` |
| 2 Contract estate claims on death (OD-LE-13B) | not started; migration plan first | section 2 |
| 3 Speculation and stockpiling (OD-LE-11) | not started | |
| 4 Negotiated wages and services behind off flags (OD-LE-03 D02) | not started | |
| Milestone evidence: one G0 (seeds 1,2, 30 days) + one `--market` run | not run | the G0 may differ only by items 6 and 7 |

Rules for whoever continues: the switch stays off; G0 identical except the item 6/7 fixes (report differences with conservation
evidence); no unbounded saved state (the economy's save size is an activation blocker, LE-06); a migration that is not purely an
added optional key is stopped and reported to the lead; Actions only at the milestone; tests failing first, then the fix.

## 1. Business identity and separate accounts (OD-LE-04 D03, OD-LE-07 D06)

Owner answers: "One owner per business initially, ownership recorded separately from household money and estate inheritance";
"Business tills, stock and obligations are separate from household holdings (ECON-P3). Owners can make explicit recorded
contributions, legitimate profit distributions or estate transfers; no silent pooling." A business is its till (`stall:`, `shop:`,
`front:`, `counter:`) and its one owner is the till's controller (`EconActor.controller`, the ECON-P3 / B18-DP-01 rule). With the
economy on, every move between a till and its owner's purse (necessity draw, owner pay, float top-up, the player's own till moves)
is a recorded coin transfer through the authority (`EconTransactions.transfer_coins`), journalled with its purpose
(`coins:necessity`, `coins:owner_pay`, `coins:topup`, `coins:kept`, `coins:contribution`, `coins:distribution`); such a move is
neither earned nor spent; coins an offer holds back cannot be contributed (claims). No new saved record: ownership stays the
existing owner/tenant records and the controller rule (one owner per till). Economy off: `BusinessMoney._move` exactly as before.

## 2. Contract estate claims (OD-LE-13B D12): plan

To be written before any code (save migration plan; additive optional key only).
