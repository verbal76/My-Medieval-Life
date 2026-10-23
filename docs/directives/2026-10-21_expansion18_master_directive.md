# Owner directive, 2026-10-21: Expansion 18 Master Directive

Saved verbatim from the owner's message (CLAUDE.md section 9a). The owner attached three research papers on tenure,
training, wages and productivity (uploaded files `TenureExperience.pdf`, `9501lync.pdf`, `c8781.pdf`; not committed);
their digest is `docs/expansion18/RESEARCH_DIGEST.md` on `wip/expansion18-preparation`.

---

# MY MEDIEVAL LIFE — EXPANSION 18 MASTER DIRECTIVE
## Settlement Capabilities, Regional Trade, Compensation, Productivity, and Economic Integration

**Owner-approved design decisions and development instructions**

### 1. Development context

Continue Expansion 18 development on the existing remote GitHub branch:

`wip/expansion18-preparation`

Latest reported branch head: `8eec56e`. Verify the current remote head before making changes.

Expansion 18 was branched independently from the released Build 16 baseline plus records, staging commit `b721616`.

**Build 17 remains priority one.**

Expansion 18 must remain isolated until its reconciliation gate. Do not merge unfinished Build 17 code into Expansion 18, and do not merge Expansion 19 into Expansion 18.

Continue approved development, testing, documentation, commits, and remote pushes. Do not publish a distributable build without explicit owner approval.

### 2. Existing Expansion 18 work

Preserve the existing tested systems:

- Settlement industry capability evaluation.
- Read-only settlement economic reports.
- Regional supply and demand calculations.
- Atomic transfers of goods and coins.
- Terrain-based regional routes.
- Paid hauling and cart capacity.
- Competition between suppliers.
- Deterministic simulation behavior.
- Conservation accounting.
- Isolated save round-trip testing.

Previously reported evidence includes 97 passing checks, a 60-day conservation simulation involving four settlements, and a clean 30-day economy simulation.

The existing caravan and live village behavior must remain unchanged until approved integration.

Do not repeat passing test campaigns unnecessarily.

### 3. Q18-9 — Capability levels must never gate activities

**OWNER DECISION: APPROVED**

Settlement capability levels affect:

1. Compensation and pay scales.
2. Production output and productivity.

Capability levels do not grant, deny, unlock, or restrict permission to perform activities.

A settlement at mining level 0 can still mine if miners have appropriate tools, access, and workable ore.

The same principle applies to farming, smithing, carpentry, and other productive industries.

Actual resource and equipment requirements still apply.

A low capability level must not cause existing resources to disappear from supply calculations.

For example, locally available ore must be included in a settlement's supply assessment whenever the relevant ore, miner, and pickaxe exist, regardless of mining capability level.

Correct the previously identified mining-level gate in the regional demand estimate.

### 4. Q18-10 — Universal regional purchasing

**OWNER DECISION: APPROVED**

Any economic participant may purchase goods from another settlement.

Eligible participants include:

- Individual villagers.
- Villagers without households.
- Households acting through their existing representation.
- Independent producers.
- Merchants and traders.
- Businesses and workshops.
- Settlement treasuries and manors.
- The player.

Do not restrict regional purchasing to merchants.

Every purchase requires a willing seller, an agreed price, available money, and actual goods.

#### Transportation

Buyers have two approved options:

**Self-collection:** Travel to the selling settlement, collect the goods, and transport them back using their actual carrying capacity and available equipment.

**Paid delivery:** Negotiate with a willing carter or delivery provider to transport the goods.

No automatic free delivery is permitted.

No invisible transportation, teleportation, or creation of goods is permitted.

Delivery compensation must be transferred between real economic participants.

Preserve the existing negotiated-contract architecture.

The precise compensation structure for delivery services remains subject to Q18-12. Do not invent a mandatory day-wage or per-load system.

### 5. Q18-11 — Capability progression

**OWNER DECISIONS: APPROVED**

All productive industries use a capability scale from **level 0 through level 10**.

Level 0 represents baseline capability, not inability to perform the activity.

Capability progression affects both compensation and production output.

Different industries may have different compensation and productivity adjustments.

Industries include farming, mining, smithing, carpentry, and other applicable productive activities.

Higher capability should generally improve productive efficiency and influence compensation, while actual payments and commercial arrangements remain subject to the existing negotiated economy.

#### Mathematical framework

Use separate multipliers for compensation and output:

`AdjustedPay = BasePay × PayMultiplier(industry, level)`

`AdjustedOutput = BaseOutput × OutputMultiplier(industry, level)`

The base values must come from the existing economic and production systems. Do not introduce arbitrary replacement base wages or recipes.

Use a diminishing-returns progression as the initial modeling approach.

**IMPORTANT: The numerical values below are research-informed design proposals, not approved implementation constants.**

One candidate level-10 example is:

- Maximum production improvement: +20%.
- Maximum compensation improvement: +8%.
- Level 0: no capability bonus.
- Level 10: full proposed bonus.

A proposed progression is:

| Level | Production bonus | Compensation bonus |
|---|---:|---:|
| 0 | 0.0% | 0.00% |
| 1 | 3.6% | 1.44% |
| 2 | 6.8% | 2.72% |
| 3 | 9.6% | 3.84% |
| 4 | 12.0% | 4.80% |
| 5 | 14.0% | 5.60% |
| 6 | 15.8% | 6.32% |
| 7 | 17.2% | 6.88% |
| 8 | 18.4% | 7.36% |
| 9 | 19.4% | 7.76% |
| 10 | 20.0% | 8.00% |

These percentages must remain configurable and inactive as finalized balancing rules until owner approval.

Develop the framework and analyze alternative values without silently selecting permanent rates.

#### Research considerations

The owner reviewed research concerning worker experience, training, wages, and productivity.

Relevant findings included:

- Productivity improvements associated with tenure may exceed wage improvements.
- One research estimate reported weighted average annual tenure-related productivity gains of 7.9% versus wage gains of 3.2%.
- Other training studies reported wage gains of approximately 4.4%–11% and productivity improvements of approximately 16%–17%.
- Returns differ across occupations and experience levels.

These findings are background for game balancing, not direct medieval economic measurements or justification for applying modern annual returns to each capability level.

Avoid assuming every industry progresses identically.

#### Economic safeguards

A productivity improvement must not create raw materials from nothing.

For example:

- Mining must consume or deplete the appropriate ore deposit according to existing rules.
- Smithing must consume the appropriate inputs.
- Carpentry must consume its required materials.
- Farming must obey existing agricultural production and resource rules.

Increased productivity may mean faster work, more efficient use of labor, or a justified reduction in waste where the underlying system supports it.

Do not multiply finished goods without accounting for their required inputs.

Do not apply the same skill benefit twice through overlapping individual experience and settlement capability calculations.

### 6. Industry capability and actual assets

Preserve the existing principle that settlement capabilities are derived from what the settlement actually possesses.

A settlement's capability may change when it gains or loses relevant workers, tools, facilities, or other established productive assets.

Population alone must not determine industrial capability.

A small mining settlement may have greater mining capability than a large agricultural settlement.

**UNRESOLVED OWNER DETAIL:** The exact weighting of individual experience versus tools, facilities, and infrastructure has not yet been approved.

Do not invent that weighting or introduce a permanent advancement system without asking.

Preserve the existing capability evaluator until reconciliation determines the authoritative implementation.

### 7. MIN-D compatibility and one-evaluator rule

MIN-D contains the authoritative Build 17 mining capability interface.

Expansion 18 must read its actual interface through the existing read-only adapter.

Do not copy MIN-D's evaluator into Expansion 18.

Do not create a second mining capability authority.

Do not merge unfinished Build 17 into the preparation branch merely to obtain mining data.

Preserve and refine the documented reconciliation plan in the Expansion 18 design document, section 8.

At reconciliation, the final game must have one authoritative capability evaluator.

Mining must continue using the same ore-bearing objects, depletion rules, and sustainability mechanics across surface, open-pit, and underground environments.

Mining capability must not create deposits, regenerate ore, or bypass resource constraints.

### 8. Regional economy and conservation

All goods, money, and resources must remain accounted for.

Goods and payment must transfer atomically.

Regional trade must not create coins through transport charges, market activity, or artificial allowances.

The previous isolated comparison reported:

- Existing caravan: +1,986 village coins over 30 days, including 486 coins created by its allowance.
- Genuine regional trade with household grain purchases: −948 village coins over 30 days, with no coins created.

These results came from a limited seed and test-region configuration. They are not general economic conclusions.

Investigate whether economic deficits arise from:

- Actual production shortages.
- Unmet demand.
- Lack of willing trading partners.
- Prices and affordability.
- Transportation costs.
- Uneven money distribution.
- Insufficient opportunities for settlements to sell their own output.

Do not automatically correct deficits by creating currency.

A settlement must be permitted to experience economic hardship when the simulation produces that outcome.

### 9. Open decisions

The following questions remain unresolved.

**Q18-11 numerical balancing:** Exact industry-specific compensation and productivity percentages remain unapproved.

**Q18-11 capability composition:** Determine how worker experience, tools, facilities, and infrastructure contribute to the capability rating. Present options for owner approval.

**Q18-12:** Final contract pricing terms for hauling and paid services.

**Q18-13:** Whether contracts directly support households and off-map settlements as parties, or use named representatives.

Preserve the other previously recorded open Expansion 18 questions.

Do not treat a recommendation, placeholder, or proposed percentage as an owner-approved rule.

Ask targeted questions only when a decision genuinely blocks the next implementation step. Continue independent approved work in the meantime.

### 10. Testing requirements

Reuse existing passing evidence whenever the exact source and tested behavior remain applicable.

Add targeted tests for:

1. Capability levels 0 through 10.
2. Capability never blocking otherwise valid actions.
3. Level-0 mining contributing actual available ore to regional supply.
4. Compensation and productivity calculations remaining separate.
5. Different industries supporting different modifiers.
6. Conservation of coins, goods, and raw materials.
7. Resource inputs matching increased production.
8. No duplicate application of experience or capability bonuses.
9. Regional purchasing by all approved participant types.
10. Self-collection and paid transportation.
11. Deterministic outcomes for identical seeds and inputs.
12. Save/load compatibility when integration reaches that stage.
13. One authoritative capability evaluator after reconciliation.

Do not rerun unrelated full suites solely for reassurance.

### 11. Required next actions

1. Correct the remaining Q18-9 mining supply estimate gate.
2. Verify the correction with targeted tests.
3. Preserve the MIN-D read-only adapter and single-evaluator reconciliation plan.
4. Record Q18-9, Q18-10, and the approved structural portions of Q18-11 in the decision log and requirements register.
5. Keep proposed capability multipliers configurable and clearly marked as unapproved.
6. Analyze candidate industry-specific curves without introducing unapproved economic constants.
7. Continue other approved Expansion 18 work that is independent of unresolved decisions.
8. Commit and push completed work to the remote preparation branch.
9. Report the exact commit, test results, unresolved decisions, and genuine blockers.

**Build 17 remains priority one. No new distributable release is authorized.**

The overarching design principle is that capabilities influence economic performance, but the simulation remains governed by real resources, willing economic participants, negotiated arrangements, and conserved goods and currency.
