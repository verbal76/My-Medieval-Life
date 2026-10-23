# Owner directive, 2026-10-21: Expansion 18 — Capability Balancing, Economic Simulations, and Smoke Testing

Saved verbatim from the owner's message (CLAUDE.md section 9a).

---

# MY MEDIEVAL LIFE — EXPANSION 18
## Capability Balancing, Economic Simulations, and Smoke Testing

Claude, we have approved the 0–10 capability scale, industry-specific productivity and compensation adjustments, and the Q18-12/Q18-13 contract rules.

**Do not finalize capability percentages yet. We want simulation evidence first.**

### 1. Run comparative capability simulations

Use the existing deterministic simulation framework and actual production, inventory, labor, and economic systems.

Test at least three candidate progression models:

- **Conservative:** Level 10 produces approximately 10% more output with 5% higher compensation.
- **Moderate:** Level 10 produces approximately 20% more output with 8% higher compensation.
- **Aggressive:** Level 10 produces approximately 35% more output with 15% higher compensation.

These are test hypotheses, not approved balancing values.

Use diminishing returns where appropriate and compare capability levels 0, 2, 5, 8, and 10.

Test farming, mining, smithing, carpentry, and other implemented productive industries.

### 2. Test actual economic consequences

Measure:

- Units produced per worker and per working day.
- Labor compensation and production costs.
- Material consumption and resource depletion.
- Finished-goods availability and shortages.
- Business profitability.
- Household purchasing power.
- Trade volume between settlements.
- Effects on market prices.
- Wealth concentration and economic inequality.
- Settlement survival and sustainability.

Run scenarios with different settlement sizes, resources, worker availability, and infrastructure.

Compare identical seeds and initial conditions across candidate models. Include a no-bonus baseline.

Do not invent unsupported production systems or fabricate results for industries that are not implemented.

### 3. Test interactions between capability and resources

Higher capability must not create resources.

A skilled miner may work faster, but cannot extract more ore than the deposit contains.

A skilled smith may improve throughput, but still requires the appropriate material inputs.

Test resource-rich, resource-poor, labor-rich, and labor-poor settlements.

Check whether higher capability creates unsustainable resource consumption or unfairly advantages particular industries.

### 4. Smoke-test the approved contract rules

**Q18-12 — Transportation**

- Regular routes use established flat-rate fees per load or scheduled delivery.
- Special deliveries to a requested person or location use negotiated contracts.
- Buyers may collect their own goods.
- Payment and goods must transfer correctly.
- No free transportation or artificial currency creation.

**Q18-13 — Formal contracts**

- Ordinary small agreements do not require notarization.
- Formal commercial contracts and ownership transfers require signatures.
- Parties meeting face-to-face may sign without a notary.
- When parties cannot meet, a courier with legal skill may act as a notary and physically transport the documents for signing and return.
- Test incomplete, rejected, interrupted, and successfully completed agreements.
- No remote instant signing.

Test these behaviors using existing systems where implemented. If a required feature is not yet implemented, identify it clearly and continue approved development rather than reporting a hypothetical test as passing.

### 5. Simulation duration and evidence

Use appropriate deterministic horizons, including 30-day and 90-day economic runs where supported.

Run longer simulations only where they reveal meaningful effects not visible in shorter tests.

Reuse existing green CI and test evidence. Do not rerun unrelated full suites.

For each candidate model, report:

| Metric | Baseline | Conservative | Moderate | Aggressive |
|---|---|---|---|---|
| Production output | | | | |
| Labor cost | | | | |
| Net business profit | | | | |
| Household purchasing power | | | | |
| Resource depletion | | | | |
| Trade volume | | | | |
| Economic failures | | | | |

Include numerical results, simulation seeds, duration, and any important assumptions.

### 6. Recommendations

Recommend the progression that best balances:

1. Meaningful benefits from capability advancement.
2. Sustainable production.
3. Reasonable labor compensation.
4. Healthy regional trade.
5. Viable small and developing settlements.
6. Realistic resource constraints.
7. Avoidance of runaway economic advantages.

Identify whether different industries need different curves.

Do not automatically choose the moderate model.

If the results indicate that all three models are unsuitable, propose and test a revised model.

### 7. Development workflow

Build 17 remains priority one.

Continue on the appropriate isolated Expansion 18 preparation branch. Commit and push approved work to GitHub.

No distributable build or release without owner authorization.

**Return a concise comparative simulation report, targeted smoke-test results, actual failures, and your recommended values. Do not implement permanent balancing constants until I review the evidence.**
