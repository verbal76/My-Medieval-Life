# LE-07 gate 9: calibration review of the provisional Living Economy parameters (2026-11-03)

- **Gate:** LE-07 gate 9, "the PROVISIONAL LE-02..LE-05 parameters reviewed against the long-run evidence (measured, not pass/fail;
  WDR-022)".
- **Evidence:** economy-on year, run 41536810831, on `4b51c92`, seed 1, 365 days, read 2026-11-02 21:25 EST.
  - The run recorded no script errors, no currency or item leaks and no claim breaches.
  - Save and load round trips were exact at all 37 checkpoints.
  - Record: `docs/release/build25_reconciliation/CAMPAIGN_4b51c92_2026-11-03.md` on `wip/requirements-control`.
- **Reviewer:** the lead, under B25-FINISH-01.
- **What it decides:** nothing about outcomes. A village may struggle; the review asks only whether any provisional value is
  producing behaviour that contradicts its own rule.

## What the year shows (day 365)

| Area | Measure | Reading |
|---|---|---|
| LE-02 market | 2,396 bids and 4,177 asks posted; 778 negotiations, 441 settled, 274 with no agreement; 287 contracts opened; 106,942 encounters | The market trades all year. About one negotiation in three ends without agreement, through counters beyond the limit and refusals. That is the bargaining rule at work, not a stall. |
| LE-02 prices | asks lowered 4,541 times, raised 119; bids raised 1,465 times, lowered 35 | Sellers lower their asks far more often than they raise them, and buyers raise their bids. This is the expected path for goods with more sellers than buyers (the wheat glut of KI-FR-WHEATSALE). No price fell below its floor; the audit is clean. |
| LE-03 affordability | 14,041 bids not posted as unaffordable, against 2,396 posted | The largest single figure. Villagers want things they cannot pay for: the X20-ECON-AFFORD question. It is the provisional reserve rule (OD-19) and household incomes at work, not a defect (no coin is missing). Carried to X20-ECON-AFFORD's analysis of the final run. |
| LE-03 claims | 4,400 offers cut to the yield, 986 cut as stale, 596 trades refused because the seller's goods were claimed, 103 inputs earmarked | The claims rule prevents double-selling; 1 unbacked earmark at the end, not a breach. |
| LE-02 knowledge | 11,321 entries (559,446 bytes) held; 51,044 forgotten; 2,235,133 word-of-mouth passes | Knowledge stays bounded by `max_hearsay` 40 and `half_life_days` 7: forgetting keeps up with telling. The economy save is 838,681 bytes at day 365 (583,548 at day 30). It grows slowly and is not unbounded. |
| LE-05 rentals | 212 opened (129 axes, 83 pickaxes), 200 returned, 5 lost, 4 broken, 11 forgone; 504 coins of fees paid | Rental works as designed. Losses and breakages are few. Escrow at the end is 32 coins, one rental open, counted. |
| LE-05 repairs | 18 repairs (12 axes, 5 pickaxes, 1 kit); 1,147 wear points mended | Low but steady. |
| Settlement | contracts refused 436; buyers refused 41; no funds 33 | Refusals are spread over causes; none dominates. |
| The village | 374 alive (444 births, 97 deaths); nobody starved; no famine; 131 of 194 adults without a job | Outcomes (WDR-022). The jobless count is the B25-ECON-P2 question (first tool), which waits for the owner. |

## Review of the provisional values

| Parameter group | Values (`economy.json`, `judgment.json` market profiles) | Finding | Change |
|---|---|---|---|
| Knowledge: half_life_days 7, max_hearsay 40 | as shipped | Bounded and working; save size acceptable | None |
| Market drive: bid and ask steps, limits | as shipped | Prices move in the direction supply and demand set; no runaway, no floor breach | None |
| Claims: offers_cut_yield, stale cut | as shipped | Prevents double-selling with no breach | None |
| LE-05 rental fee and deposit | as shipped | 212 rentals, 2.4 % lost | None |
| LE-05 route risk (PROVISIONAL expected-loss term) | as shipped | Courier losses were rare in the year; the term has little to act on | None; revisit with the regional trade's first year (the final flight) |
| Construction wage priority (s.6 observation) | non-necessity | A founder's wage yields to its own open bids; the house is still built | None. A balance question, not a defect |

**Conclusion:** no provisional value contradicts its own rule in a year's evidence; none is changed. The values stay PROVISIONAL
for the owner's later balance review. The affordability gap and the job gap are recorded for X20-ECON-AFFORD and B25-ECON-P2. They
are outcomes, not calibration defects.

The final candidate's year-long flight (B25-FINISH-01, with the Living Economy on and the regional trade running) is read
against this review. Any change there is recorded here.
