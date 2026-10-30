MML — LE-03 and Settlement Food Trading: Coordinated Recovery and Integration

(Owner message, 2026-10-30, recorded verbatim in substance by the lead; sections as given.)

Resume active development of Living Economy LE-03 and settlement-to-settlement food trading. These are approved parallel workstreams, but they must converge on one authoritative economic transaction system.

Do not pause independent multiplayer work. Do not merge either economic branch until its applicable tests and integration checks pass.

1. Immediate LE-03 CI repair — investigate run 41118607622 on wip/x20-le03 (tests/test_requirements.py::ValidationTest::test_document_references_in_any_field_must_exist expected cr.validate(new) to report NO_SUCH_FILE; 164 tests, one failed). Determine validator, fixture or interpretation; correct the actual cause without weakening the requirement that nonexistent document references must be detected. Focused requirements tests first, then applicable CI; reuse valid evidence. Inspect the queued LE-03 long simulation and whether its results stay valid after the fix.

2. Investigate the cancelled food-trade simulation 41118155447 on wip/x20-settle-food: who or what cancelled it, whether a newer run superseded it, whether useful results were retained; document a deliberate replacement or schedule an accidental one's replacement without duplicating work.

3. Establish one authoritative transaction mechanism: all purchases, sales and settlement food transfers share one mechanism for verifying buyer funds and seller inventory; reserving or validating before commit; moving money and goods together atomically; rejecting insufficient funds, insufficient stock, invalid quantities and unavailable participants; preventing duplicate execution, replayed transactions, double spending and item creation or destruction; handling interrupted or rejected transactions without partial changes; deterministic simulation and save/load. Preserve legitimate rules and gameplay; no artificial subsidies, emergency supplies, guaranteed trade or automatic rescue.

4. Integrate settlement food trading through the same transaction authority as ordinary market buying: genuine shortages and surpluses, legitimate offers, available food for actual payment; inventories, purchasing power, transport or delivery rules and existing decision-making respected; no food without a legitimate source; no payment without a completed transaction; no additional settlement-only currency or inventory system.

5. Test realistic economic failure: two buyers for the last inventory; multiple transactions on the same funds; interrupted and rejected transfers; save/load and deterministic replay; settlement shortages and genuine surpluses; unaffordable offers and unsuccessful negotiations; repeated transactions across days; decline, migration, starvation and settlement failure when they naturally follow. Distinguish legitimate collapse from defects (money leakage, inventory duplication, inaccessible stock, deadlocked trading).

6. Coordinate the two workers: agree the authoritative transaction interface and ownership before integration; no parallel implementations; one worker owns the shared transaction authority, the other integrates food trading through it; preserve both workers' committed changes.

7. Acceptance before merging: validator failure corrected; both branches passing applicable tests; shared transaction behaviour tested across ordinary purchases and settlement transfers; no double spending, duplicated or lost goods, unintended currency creation; determinism and persistence passing; relevant long-run simulations completed and interpreted; activation only after all approved Living Economy acceptance conditions, then automatic as authorized; no irreversible migration or public release without the owner.

8. Reporting and autonomy: routine engineering without approval; report root causes, fixes, SHAs, CI links, test results, simulation findings, blockers; escalate only major architectural conflicts, irreversible changes, paid infrastructure, contradictions with settled design, or public release. Proceed now.
