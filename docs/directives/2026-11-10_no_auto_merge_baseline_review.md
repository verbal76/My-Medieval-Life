# Owner directive, 2026-11-10: no automatic merge; review the 33 baseline findings first

Received 2026-11-10 about 12:00 UTC (07:00 EST) in the lead session. Saved verbatim below; never edited. Register id
B25-BASELINE-REVIEW-01.

---

Continue the 365-day campaign validation on "fbfd6ad" as planned.

Do not merge automatically when the campaign finishes.

The 33 baseline findings remain blocking until we have reviewed their causes and determined whether the differences are intentional, acceptable changes or actual defects.

Once the campaign finishes:

1. Verify both seeds and inspect the actual artifacts.
2. Investigate any food-purchase loops, F015 starvation behavior, conservation failures, or other defects.
3. Produce a categorized comparison of all 33 baseline findings, explaining the old behavior, new behavior, cause, and whether each difference is expected or concerning.
4. Recommend which findings should be accepted, corrected, or investigated further.
5. Report the results and request my approval before accepting a new baseline or merging.

Do not re-record baselines, weaken tests, or bypass the gate to obtain a passing result.

Continue independent investigations and documentation while waiting. Preserve all existing work.
