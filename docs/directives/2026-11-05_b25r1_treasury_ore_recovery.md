# Owner decision, 2026-11-05: recover stranded settlement treasury ore (B25R1)

Saved as received (condensed formatting only). Register: B25-ECON-P7.

---

Owner decision: APPROVED — Recover stranded settlement treasury ore.

Implement this alongside the ongoing economy work, but do not jeopardize tonight's private Windows playtest.

Required behavior
1. When a quarry, mining business, or trader closes, ore already transferred into settlement treasury storage must remain available to the economy.
2. A settlement's own active trader receives first opportunity to collect available surplus ore.
3. Neighboring traders may collect remaining surplus, consistent with approved owner decision 32.
4. Protect ore required for local production, existing obligations, and legitimate settlement reserves. Do not permit traders to drain essential local inventory.
5. Use existing commercial purchasing, consignment, pricing, inventory-transfer, and settlement accounting mechanisms wherever applicable. Do not introduce free transfers or duplicate economic systems.
6. Preserve the existing 12-day consignment return rule.
7. Business closures must remain possible for legitimate economic reasons.

Verification requirements
- First investigate how treasury ore is stored, owned, reserved, and accounted for. Identify the correct integration point before modifying code.
- Add regression tests for closed quarries, closed traders, competing neighboring traders, insufficient funds, local reserve protection, failed transactions, and save/load continuity.
- Verify that ore and coins are conserved across every transaction.
- Include treasury-ore recovery in the existing 120-day economy simulations on seeds 1–4, reporting quantities recovered, quantities traded, trader survival, iron imports, production, starvation deaths, and conservation failures.
- Compare against the approved economy baseline and distinguish improvements from unintended changes.
- Record the implementation, rationale, test results, and exact commit SHA in the development documentation and decision register.

Scheduling and shipping
Continue the already-approved work on decisions 32 and 33 without interruption.
Investigate and implement this in parallel if practical. Do not restart completed simulations unnecessarily.
If treasury recovery is safe, tested, and ready before the final integrated validation begins, merge it into "wip/b25r1" and include it in that validation.
If it requires substantial additional work, isolate it on its own branch and defer its merge until after the B25R1 private playtest. Do not delay packaging solely for this enhancement.
Do not declare the feature complete until the relevant GitHub Actions evidence is available and verified against the exact commit.
Primary objective remains unchanged: deliver a stable, playable B25R1 Windows package as soon as the existing shipping blockers are resolved.
Proceed without additional approval unless an actual economic policy decision is required.
