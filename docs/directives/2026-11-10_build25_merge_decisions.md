# Owner directive 2026-11-10: Build 25 merge decisions (verbatim)

Proceed with the following My Medieval Life Build 25 decisions:

1. Batch 3+4: Approved for merge once the pending comparison confirms no unexplained regressions. Do not automatically replace the accepted baseline. Preserve the old baseline and its comparison results.

2. ND-15: Minor floating-point differences after save/load are acceptable only when proven harmless to gameplay, inventory, money, contracts, deterministic outcomes, and subsequent simulation behavior. Establish and document numerical tolerances. Exact values must remain exact wherever required for correctness.

3. ND-16: Approved. Long-running campaigns should use the same save precision as actual gameplay. Preserve historical campaign results and label the new precision regime clearly. Do not compare incompatible results without accounting for the change.

4. ND-12: Approved for merge after Batch 3+4, provided its diagnostic-only scope and passing tests remain verified.

5. F015/P99: Do not merge yet. Investigate the population difference of 316 versus 203 on seed 2. Identify the exact causes of reduced births, arrivals, and any other population changes. Determine whether the difference is legitimate or an unintended side effect. Retain the improvements to starvation and smith purchasing without accepting unexplained population regressions.

6. Continue verification of the remaining fixes in dependency order. Do not merge branches with outstanding required gates.

7. Keep all 69 original requirements accounted for. Previously approved work should proceed when dependencies are satisfied. Do not treat a baseline update as proof that unresolved defects are fixed.

Report the completed merges, exact commit SHAs, test results, remaining blockers, and next actionable work. Do not claim release readiness until the complete release gate passes.
