# Owner directive 2026-10-30: Expansion 20 background development

Verbatim, as received in the coordinating session on 2026-10-30. Register: X20-BACKGROUND.

---

MY MEDIEVAL LIFE — EXPANSION 20 BACKGROUND DEVELOPMENT DIRECTIVE

PRIMARY OBJECTIVE

Continue Expansion 20 development, integration, and validation without requiring unnecessary owner intervention.

Upwardly Build 83 remains my primary development and release priority. My Medieval Life should continue making progress independently within the decisions and constraints already approved.

Do not rush a new MML build simply to increase the build number.

Our objective is a stable, integrated, economically functional next private playtest build.

1. CURRENT INTEGRATION

The food-trade and LE-03 integration was pushed to "wip/expansion20" at "5195c2c".

The LE-04 milestone from Worker A, "353d12b", has been merged locally, with 41 targeted suites running against the combined code.

Allow the existing validation to finish.

If the suites pass, commit and push the combined integration.

If failures occur, investigate and correct genuine regressions before merging. Do not weaken tests or alter expected results merely to obtain a passing status.

Pay particular attention to the interaction between findings 2 and 7, which both involve household departure and till ownership.

Verify that:

- Household funds and business funds remain correctly attributed.
- Departing households cannot duplicate or lose coins or inventory.
- Tills cannot transfer to unauthorized households.
- Unstaffed businesses stop operating.
- Existing saves remain compatible.
- The transaction ledger preserves exact conservation.

2. BASELINE SIMULATION

After the combined integration passes, run the single planned baseline simulation against the exact merged commit.

Use existing simulation instrumentation and reporting rather than creating another framework.

Report:

- Starting and ending economic balances.
- Coin and inventory conservation.
- Business closures and ownership transitions.
- Household migration and estate handling.
- Food-market transaction activity.
- Any stranded contracts, inventory, or escrow.
- Determinism and save/load integrity.
- Any crashes, exceptions, or simulation stalls.

Reuse the results for subsequent work wherever they remain applicable.

Do not repeat a passing simulation without a demonstrated technical reason.

3. LE-06 — SAVE-GROWTH BLOCKER

Worker A's highest priority is LE-06.

The economy-on save increased by approximately 1.97 MB over 30 days. This is unacceptable for long-running settlements.

Identify and correct the sources of unbounded growth while preserving the intended market knowledge, gossip, prices, transaction integrity, and economic behavior.

Do not solve the problem by indiscriminately deleting meaningful knowledge or changing the economy's intended outcomes.

Use the approved budget of one baseline run and one 365-day economy-on run.

Report save-size growth, memory implications, market behavior, conservation, determinism, and save compatibility.

Any non-additive save migration or change to economic outcomes requires my approval before implementation.

Do not enable the Living Economy by default until LE-06 and its required validation pass.

4. TRADER REOPENING

Worker B should complete the approved settlement business reopening rule.

An unstaffed business must close and stop trading.

A new household may subsequently establish or reopen that business through the existing ownership and business-creation rules.

Reopening must not resurrect the former owner's coins, inventory, workforce, contracts, or obligations.

Verify that the settlement's trading network can recover rather than permanently disappearing as households migrate.

Use focused tests and the previously approved limited simulation budget.

5. MULTIPLAYER / ECONOMY INTEGRITY

Once the combined economic integration is stable, begin X20-MP-ECON-INTEGRITY.

Test transactions, negotiated offers, contracts, deliveries, escrow, and ownership changes across:

- Disconnects and reconnects.
- Repeated or delayed requests.
- Host recovery and restored saves.
- Duplicate message delivery.
- Guest departure during an active transaction.
- Interrupted settlement and payment.
- Multiplayer succession and ownership changes where applicable.

Transactions must remain authoritative, idempotent and exactly conserved.

No duplicate money, lost inventory, duplicated delivery, or partially committed transaction may result from network faults.

Preserve existing multiplayer behavior and save compatibility.

6. JUDGMENT CALIBRATION

Allow Worker D's SJD-G calibration and existing GitHub Actions runs to finish.

Evaluate the reported 100-day and 365-day outcomes, including reputation distribution, social feedback loops, relationships, courtship, trade decisions, determinism, performance, and conservation.

Do not change scoring weights, decay rules, or caps without my approval.

Escalate genuine balance decisions with evidence and recommendations.

7. DEVELOPMENT AND TESTING DISCIPLINE

Continue using separate worker branches and controlled integration into "wip/expansion20".

Do not modify the frozen Build 24 release.

Avoid redundant GitHub Actions runs and repeated full simulation campaigns.

Reuse passing evidence for unchanged source commits.

Prefer targeted tests after localized changes.

Keep the approved simulation budgets intact.

Do not publish a public release or promote a new build without authorization.

A new private playtest should be proposed only when a coherent, stable milestone has passed the necessary gates.

8. OWNER ESCALATION

Continue autonomously within approved specifications.

Interrupt me only for:

- A genuine design decision not already covered.
- A change to intended economic or social behavior.
- A non-additive save migration.
- A material compatibility or determinism risk.
- A major test failure requiring a change in direction.
- An additional expensive simulation campaign outside the approved budget.
- Authorization to package or release the next private build.

For ordinary implementation details, use engineering judgment and proceed.

9. REPORTING

Keep the development register and recovery handoff updated with committed and pushed milestones.

Provide concise milestone reports containing:

- Exact branch and commit.
- Completed integration.
- Passing and failing validation.
- Active worker assignments.
- Known blockers.
- Any owner decisions required.
- Next integration checkpoint.

Do not present locally merged or uncommitted work as pushed or released.

FINAL DIRECTION

My Medieval Life should continue progressing steadily in the background.

Prioritize correctness, economic sustainability, multiplayer transaction integrity, save compatibility, and long-term simulation stability.

Do not sacrifice those requirements to accelerate the next build number.

Upwardly Build 83 remains the primary release priority.

Proceed with Expansion 20 under these constraints.
