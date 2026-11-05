# Owner directive 2026-11-01: Expansion 20 economic maturation, chapel correction and integrity

Verbatim, as received in the coordinating session on 2026-11-01. Register: X20-ECON-MATURE (and children).

---

MY MEDIEVAL LIFE — EXPANSION 20

MASTER DIRECTIVE: ECONOMIC MATURATION, CHAPEL CORRECTION & INTEGRITY

Priority: High — Foundational economy validation
Repository: My Medieval Life
Current chapel correction branch: "wip/x20-chapel"
Chapel correction commit: "ae8641d"
Build 25 source branch: "wip/expansion20"
Requirements and reporting branch: "wip/requirements-control"

1. OWNER DIRECTIVE — THE ECONOMY MUST EVOLVE

My Medieval Life is not designed to remain an entry-level subsistence economy.

The starting settlement is the beginning of the game, not its intended permanent economic condition.

As simulation time passes, villagers should have opportunities to develop skills, improve their livelihoods, change occupations, establish businesses, open shops, build commercial relationships, accumulate capital, negotiate contracts, and participate in an increasingly developed marketplace.

The town square should evolve into a functioning center of commerce as the settlement develops.

Businesses should emerge from actual economic opportunities and available resources. Some should succeed, some should fail, and some should expand or change ownership.

Villagers should be capable of economic advancement, but prosperity is never guaranteed.

Do not evaluate the entire economic system as though the settlement is supposed to remain in its initial condition.

From this point forward, economic validation must distinguish between:

- Starting economic conditions.
- Early settlement development.
- Intermediate economic development.
- Established commercial activity.
- Mature, evolving economic behavior.

These are analytical stages, not mandatory scripted milestones. Do not force towns to reach a particular stage by a fixed date.

The purpose is to verify that genuine economic progression is possible and that the systems supporting it function correctly.

---

2. FIRST TASK — AUDIT WHAT THE CURRENT SIMULATIONS ACTUALLY EXERCISE

Before making further economic changes, investigate the existing 365-day simulation framework.

Determine whether the simulations genuinely exercise the game's complete economic progression systems or primarily repeat starting-condition behaviors.

Inspect the actual code paths, simulation setup, NPC decision systems, and available telemetry.

Specifically establish whether the simulations support and exercise:

1. Villagers gaining experience and developing skills.
2. Movement into better-paid or more specialized occupations.
3. Job creation, recruitment, employment changes, and unemployment.
4. Independent production and selling.
5. NPC business formation.
6. Shop establishment and operation.
7. Shop inventories, restocking, and customer purchases.
8. Merchant activity.
9. Town-square market activity.
10. Independent buyer-seller negotiations.
11. Quantity-based procurement and labor contracts.
12. Capital accumulation and reinvestment.
13. Business growth, contraction, failure, and replacement.
14. Supply-and-demand price responses.
15. Household savings and discretionary spending.
16. Resource depletion, replenishment, and sustainable production.
17. Economic effects of population growth and changing household needs.
18. Taxes, manor treasury activity, chapel giving, and charitable relief.
19. Economic continuity across save/load boundaries.
20. The interaction between Living Economy and the other economic systems.

Do not assume a feature is working because its code exists.

For each system, classify it as:

- Implemented and exercised in simulation.
- Implemented but not exercised.
- Partially implemented.
- Not implemented.
- Unable to determine from existing evidence.

Provide source-code references and actual simulation evidence.

Do not invent missing systems or silently implement features that require new design decisions.

---

3. NEW ECONOMIC EVALUATION FRAMEWORK

Replace static, end-of-year-only economic assessments with longitudinal economic-development analysis.

Annual totals remain useful, but they are no longer sufficient.

Record economic snapshots at minimum on:

Days 1, 30, 90, 180, 270, and 365.

Also capture periodic interval data so we can see trends rather than only isolated snapshots.

Where the simulation supports it, analyze additional runs extending to days 730, 1,095, and 1,825.

These longer horizons are diagnostic tools, not a requirement to run every configuration for five years.

First determine how long it reasonably takes the game's actual economic mechanisms to produce measurable development.

Do not impose arbitrary development deadlines.

A. Employment and professional development

Measure:

- Total employment and unemployment.
- Available jobs by occupation.
- Workers entering or leaving occupations.
- Skilled versus unskilled employment.
- Experience and skill progression.
- Wage and compensation changes.
- Independent versus employed workers.
- New employment opportunities.
- Job vacancies and unmet labor demand.
- Occupational mobility.
- Workers unable to advance and the reasons why.

Distinguish new jobs from jobs that merely changed ownership or were reassigned.

B. Businesses and shops

Measure:

- Number of active businesses.
- Number of shops.
- Businesses existing at simulation start.
- Businesses created during the simulation.
- Business openings and closures.
- Business ownership.
- Employees per business.
- Inventory availability.
- Production and sales.
- Operating revenue and expenses.
- Profitability and losses where modeled.
- Capital invested.
- Business expansion or contraction.
- Business failures and their causes.
- Business survival and replacement rates.

Do not infer business development solely from the number of jobs.

C. Town-square marketplace

Determine whether the town square is genuinely developing into an active commercial center.

Measure:

- Number of participating merchants.
- Number of active sellers and buyers.
- Market inventory.
- Goods offered.
- Successful transactions.
- Transaction value.
- Market activity by product category.
- Price changes.
- Unfilled demand.
- Unsold supply.
- Market participation over time.
- New merchants entering the market.
- Market activity attributable to newly established businesses.

Distinguish the town-square marketplace from unrelated economic transactions elsewhere in the simulation.

If the game does not currently distinguish these sources, report that limitation rather than fabricating market-square metrics.

D. Household economic advancement

Measure:

- Household income.
- Cash holdings.
- Savings.
- Essential expenses.
- Disposable income.
- Purchasing power.
- Food and heating security.
- Employment stability.
- Wealth distribution.
- Movement between economic conditions.
- Households entering or leaving hardship.
- Households accumulating capital.
- Households establishing independent income sources.

Track households longitudinally wherever possible.

A household becoming wealthier should be distinguishable from a wealthier household simply entering the population.

E. Production, resources, and trade

Measure:

- Production by item category.
- Goods consumed.
- Goods sold.
- Goods stored.
- Inventory shortages.
- Resource bottlenecks.
- Price changes.
- Contract formation and completion.
- Negotiated quantities and prices.
- Failed negotiations.
- Production capacity changes.
- Supply meeting or failing to meet demand.
- Changes in trade volume as businesses develop.

Preserve the existing resource sustainability and depletion rules.

Do not invent separate underground resource regeneration or arbitrary new production rules.

---

4. REEVALUATE THE 12,600 UNAFFORDABLE BIDS

The chapel report identified approximately 12,600 unaffordable bids in the economy-on simulation.

Do not automatically classify that annual total as evidence of a broken economy.

Determine:

1. When the bids occurred.
2. Which households generated them.
3. What goods they were attempting to purchase.
4. Whether the bids represented essentials or discretionary goods.
5. Whether households lacked money, income, available credit mechanisms, or other required resources.
6. Whether the same households repeatedly generated impossible bids.
7. Whether the goods were available at reasonable prices.
8. Whether the problem improved as jobs and businesses developed.
9. Whether economic advancement reduced the affordability problem.
10. Whether persistent failures were caused by a genuine simulation defect.

Report unaffordable bids by 30-day interval, product category, household economic condition, and cause where measurable.

Normalize by population, active households, and purchasing opportunities.

Do not judge economic health from raw cumulative counts alone.

A large number of early failures followed by improving affordability is fundamentally different from an economy that never improves.

Identify which pattern the game actually produces.

---

5. REEVALUATE FIREWOOD SHORTAGES

The chapel report showed between 790 and 4,000 nights without firewood in corrected runs.

Investigate whether these shortages reflect:

- Early settlement conditions.
- Seasonal demand.
- Insufficient production.
- Resource availability.
- Labor shortages.
- Transportation or distribution problems.
- Unaffordable prices.
- Poor purchasing decisions.
- Inventory management.
- Households failing to prepare for winter.
- Actual defects in the economic or survival systems.

Measure shortages by season, household, income level, and simulation period.

Distinguish isolated hardship from persistent systemic failure.

Determine whether improved employment, commerce, and production actually reduce shortages as the settlement matures.

Do not eliminate hardship through artificial resource creation, guaranteed prosperity, or hidden subsidies.

---

6. CHAPEL ECONOMY CORRECTION

The current chapel correction has produced encouraging results.

Reported comparisons against Build 25:

Metric| Build 25| Corrected
Chapel share of all coins| 77–83%| 0.9–1.2%
Median household cash| 4–11| 161–203
Manor treasury, normal economy| 1–5| 221–646
Jobs| 45–46| 51–63
Nights without firewood| 4,022–4,988| 790–4,000

The corrected simulations reportedly completed 365 days without currency or item leaks, with 37 successful save reloads and deterministic replay evidence.

Treat these as reported evidence to verify against the underlying artifacts.

Chapel policy

The chapel should function as a religious and charitable institution, not as a permanent sink accumulating most of the settlement's currency.

Giving must remain voluntary.

Households must retain meaningful control over their money.

The chapel should be able to support clergy expenses and distribute appropriate relief without becoming financially unstable.

Provisional parameters

The following existing correction parameters are approved for continued evaluation, not permanently frozen as universal balancing rules:

- Donation amount: 10% of available spare coins.
- Reserve: 14 days of clergy wages.
- Hardship threshold: below two weeks of essentials.
- Alms exclusion: households holding six weeks or more of essentials.
- Existing weighted giving-decision logic.

Keep these configurable where practical.

Do not retune them solely to force preferred economic results.

Evaluate their behavior over early, developing, and mature economic conditions.

Required chapel checks

Verify:

- Donations are genuinely voluntary.
- Households do not donate essential survival funds.
- Giving behavior responds to household circumstances.
- The chapel can cover its legitimate expenses.
- Alms reach eligible households.
- Funds are not hoarded indefinitely.
- Relief does not create currency.
- No household receives duplicate or invalid payments.
- Economic behavior remains deterministic.
- Save/load integrity is preserved.

Clarify whether the earlier statement that modest and comfortable households gave "almost all the coins" refers to their share of total donations or nearly all of their personal cash.

Those are not equivalent.

---

7. KNOWN GOSSIP DEFECT — X20-TELL-GUARD

The recent simulations reported:

- Zero script errors in one run.
- Two in another.
- Twelve in the economy-on run.

All reported errors were attributed to the existing X20-TELL-GUARD defect at:

"judgment_store.gd:1490"

The chapel correction was not identified as the source.

Owner authorization: Apply the narrowly scoped correction to this known gossip defect.

Before editing, inspect the actual code and proposed two-line fix.

Confirm that the correction addresses the real failure mechanism and does not suppress legitimate errors.

Preserve judgment records, gossip behavior, reputation consequences, and determinism.

Run focused regression tests for the affected code.

Confirm the known script error no longer occurs under a representative reproducing scenario.

Do not simply filter it out of logs.

Do not broaden this into an unrelated rewrite of the gossip system.

---

8. BRANCH INTEGRATION

The chapel correction is currently reported on:

"wip/x20-chapel" at "ae8641d"

The Build 25 source remains on:

"wip/expansion20"

Owner authorization: Integrate the verified chapel correction and narrowly scoped gossip fix into the active Expansion 20 development source, provided the integration is clean and the relevant correctness checks pass.

Before integration:

- Inspect the actual diff.
- Confirm the source commit.
- Identify unrelated modifications.
- Resolve conflicts without discarding other Expansion 20 work.
- Preserve the released Build 25 artifacts.
- Preserve rollback capability.
- Run focused integration and regression checks.

Do not publish a new public release.

Do not overwrite released Build 25 artifacts.

Do not silently merge unrelated experimental changes.

---

9. LONGITUDINAL SIMULATION STRATEGY

Avoid wasting CI resources by running large campaigns before we know what the existing tests measure.

Phase A — Instrumentation and audit

Inspect the existing simulation framework.

Reuse available logs, data, snapshots, and test artifacts.

Determine which economic-development measurements already exist and which are missing.

Implement only the instrumentation needed for meaningful longitudinal evaluation.

Do not change gameplay rules during this phase.

Phase B — Baseline evaluation

Use the existing three corrected 365-day simulations wherever their underlying data supports the required analysis.

Do not rerun them merely to reproduce known results.

Where historical measurements are unavailable, use a small representative set of new runs with the necessary instrumentation.

Compare normal economy and Living Economy configurations.

Use matched seeds where possible.

Phase C — Development over time

Analyze how the economy changes from day 1 through day 365.

Determine whether jobs, businesses, shops, market participation, and household purchasing power genuinely develop.

Identify systems that fail to progress.

Phase D — Longer-horizon evaluation

If the economy has not reached meaningful commercial maturity by day 365, determine whether more time is needed or whether a system is preventing development.

Run targeted longer-horizon simulations only when they answer a specific unresolved question.

Use 730, 1,095, or 1,825 days as appropriate.

Avoid automatically running every seed and configuration for every duration.

Phase E — Targeted corrections

If the audit identifies genuine defects, prioritize them by their impact on economic progression.

Apply narrow, evidence-supported fixes within established owner-approved rules.

For changes that alter economic policy or game design, document the options and request approval before implementation.

Do not silently invent new mechanics, guaranteed growth, or economic subsidies.

---

10. ECONOMIC MATURATION REPORTING

Create a comprehensive report that shows the settlement's economic evolution rather than just its final condition.

Use our established detailed reporting standards, with charts, raw data, and clear interpretation.

Required charts

1. Population and employment over time.
2. Occupations and skill development.
3. New jobs created by period.
4. Businesses opened and closed.
5. Active shops and merchants.
6. Town-square market transactions.
7. Market volume and product availability.
8. Household income and cash distribution.
9. Household movement into and out of hardship.
10. Affordable versus unaffordable purchasing attempts.
11. Production versus consumption.
12. Essential resource shortages.
13. Chapel donations, alms, and reserves.
14. Manor treasury and other currency holders.
15. Currency circulation and conservation.
16. Economic comparison between normal and Living Economy configurations.

Where a metric is unavailable, clearly mark it as unmeasured and identify what instrumentation is required.

Do not invent values.

Reporting questions

The executive summary must answer:

- Did the economy actually develop?
- What changed between days 1 and 365?
- Did villagers move into better occupations?
- Were new businesses established?
- Did shops open and operate?
- Did the town-square marketplace become more active?
- Did households become more economically secure?
- Did trade become more sophisticated?
- Did affordability improve?
- Did essential shortages decline?
- Which economic systems stagnated?
- What prevented further development?
- Was the chapel correction beneficial across different economic stages?
- Did the economy remain internally consistent and deterministic?

Distinguish measured results, interpretations, and recommendations.

Do not confuse correlation between different simulation histories with proof that a particular fix caused the outcome.

---

11. ACCEPTANCE CRITERIA

The work is successful when we can demonstrate, using actual simulation evidence:

1. The known gossip script defect is corrected.
2. The chapel correction is integrated without unrelated regressions.
3. Currency and item conservation remain intact.
4. Save/load and deterministic behavior remain valid.
5. The economic simulation's actual progression coverage is documented.
6. Economic development can be measured across time.
7. Business and marketplace progression are verified or clearly identified as missing.
8. Affordability and firewood shortages are analyzed by cause and stage of development.
9. The report distinguishes starting conditions from mature economic behavior.
10. Genuine progression blockers are identified and prioritized.

Do not require every household to become prosperous.

Do not require every business to succeed.

Do not require every town to develop identically.

A realistic economy can experience unemployment, shortages, bankruptcy, inequality, and economic decline.

What we must verify is that villagers and businesses have functioning opportunities to develop and respond to changing circumstances.

---

12. AUTONOMY, TESTING, AND HANDOFF

Proceed autonomously through code inspection, existing-data analysis, instrumentation, the authorized gossip correction, chapel integration, focused validation, and report generation.

Do not stop repeatedly for routine approvals.

Use efficient GitHub Actions workflows and avoid redundant long-running tests.

Preserve a durable handoff before context compaction.

Record the economic maturation framework in the requirements and decision register so future evaluations use the same standard.

Maintain separate records for:

- Verified defects.
- Missing instrumentation.
- Existing design limitations.
- Economic tuning questions.
- Proposed new features.
- Owner-approved decisions.

Do not convert an unmeasured feature into a claimed defect.

Do not perform unrelated game redesign.

Do not publish a new release without authorization.

---

FINAL OWNER DIRECTIVE

My Medieval Life is a game about a living society that changes over time.

The economy must be evaluated as a developing system, not a static starting village.

A villager who begins with nothing should have a genuine opportunity to improve their circumstances.

A settlement that begins with limited trade should be capable of developing shops, merchants, skilled occupations, contracts, and a functioning marketplace.

Some villagers will succeed. Others will struggle. Businesses will open and close. Markets will expand and contract.

That is the intended simulation.

Our job is not to guarantee prosperity.

Our job is to verify that the systems enabling economic development actually work.

Fix the known gossip defect, integrate the successful chapel correction, investigate the remaining economic concerns, establish the longitudinal evaluation framework, and deliver the evidence.

Do not judge the economy solely by its day-one conditions or its day-365 totals. Show me how the society evolves between them.
