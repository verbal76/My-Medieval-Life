# Owner directive 2026-10-30: Build 24 review remediation and Expansion 20 integration

Verbatim, as received in the coordinating session on 2026-10-30. Register: X20-B24-REMED.

---

MY MEDIEVAL LIFE — BUILD 24 REVIEW REMEDIATION AND EXPANSION 20 INTEGRATION

Continue from the current authoritative project state, decision register, worker branches, and existing test evidence.

This is a continuation directive, not a request to restart completed work or reopen approved decisions.

BASELINES AND BRANCH PROTECTION

Build 24 is the frozen private playtest baseline:

- Tag: build-24
- Frozen commit: 4611d86b0a36cc8ad05268cd821884dfa7caee8d
- Shipped game code: e8cc44b

Preserve its tag, branch, release artifacts, and existing evidence exactly.

All new repairs and development belong in the appropriate Expansion 20 workstreams.

BUILD 24 CODE-REVIEW FINDINGS

The independent review identified eight defects, tracked under X20-B24-REVIEW.

Current reported status:

- Findings 4, 5, and 8: fixed and merged in f8b3f10.
- Findings 6 and 7: fixed on LE-04 branch at 74b99de, awaiting integration.
- Findings 1, 2, and 3: assigned to Worker B.

Continue from these results, verifying current branch and commit status before taking further action.

For the remaining findings, require regression tests that reproduce the original defects before fixes are applied.

Investigate shared root causes and related ownership transitions, not merely the examples identified by the reviewer.

Specifically ensure:

- Businesses cannot continue operating with no workers.
- Migrating characters and households retain their rightful possessions and earnings.
- Storefront tills and stall proceeds transfer to the correct previous owner.
- Death, migration, eviction, property transfers, and household dissolution cannot create or destroy money or goods.
- Recorder diagnostics accurately reflect real transactions.

Maintain a per-finding register showing verification, fix commit, test evidence, integration status, and whether the defect remains in frozen Build 24.

LIVING ECONOMY

LE-03 is completed and frozen at 8fff5ce.

Continue LE-04 from its current checkpoint without duplicating completed work.

Preserve the approved account-separation rules, including individual purses rather than invented pooled household money.

Use World.transactions as the authoritative transaction path for the manor, households, chapel, businesses, tills, contracts, and applicable settlement transfers.

Ensure reserved coins and goods cannot be spent or promised twice.

Handle contract expiration, cancellation, delivery, death, estate transitions, and ownership changes consistently with existing approved rules.

If an unresolved gameplay policy or non-additive save migration is required, present the decision and its consequences before implementing it.

Keep unapproved wages, services, and other deferred systems behind disabled switches.

LE-06 SAVE-GROWTH BLOCKER

The economy's save section reached approximately 2 MB after 30 simulated days, primarily from price knowledge propagation.

Treat bounded storage and long-term save/load verification as mandatory activation gates.

Do not enable the economy until LE-06 resolves the growth problem with evidence that preserves the intended knowledge and market behavior.

Do not introduce new unbounded persistent state in LE-04 or related expansions.

MULTIPLAYER AND ECONOMY INTEGRITY

Multiplayer Batch D is approved and merged at de8d225.

MP-INET-RELAY remains Option A: free connection methods only. No paid relay, commercial service, or recurring infrastructure expense.

Preserve the approved reconnect, duplicate-request protection, and host behavior.

Complete X20-MP-ECON-INTEGRITY when the relevant systems are integrated.

Fault-inject multiplayer transactions involving trades, offers, contracts, and shipments.

Prove exact conservation of currency and goods, correct transaction ownership, and idempotency across disconnects, retries, duplicate messages, host recovery, and interrupted transactions.

Reuse existing multiplayer test evidence where applicable.

JUDGMENT CALIBRATION

Continue SJD-G within its approved simulation budget.

Evaluate judgment on/off behavior, score inflation, duplicate postings, behavioral loops, courtship pacing, conservation, determinism, performance, and old-save loading.

Do not introduce unapproved judgment decay, caps, or weight changes.

Present any proposed calibration changes at SJD-H for owner approval.

TESTING AND GITHUB ACTIONS BUDGET

Respect the existing per-worker simulation limits.

Reuse passing CI and simulation evidence for the exact applicable commits.

Do not rerun complete test campaigns for reassurance.

Prefer focused regression tests and local validation when sufficient.

Do not launch additional expensive GitHub Actions campaigns without approval.

Do not cancel already running jobs merely because a newer test exists unless there is a genuine technical or budget reason.

INTEGRATION AND RELEASE RULES

Keep worker branches isolated until their integration requirements are met.

Verify integration against the current authoritative source rather than assuming older test evidence applies after material changes.

Preserve determinism, save compatibility, economic conservation, and approved gameplay decisions.

Do not modify frozen Build 24.

Do not publish a release or activate unfinished systems.

NEXT REPORT

Provide a concise but complete milestone report covering:

1. All eight Build 24 findings and their current disposition.
2. Exact repair commits and integration status.
3. LE-04 progress and remaining work.
4. LE-06 save-growth risk and activation readiness.
5. Food-trade integration and transaction-authority coverage.
6. Multiplayer/economy integrity testing status.
7. SJD-G calibration progress.
8. CI status, simulation evidence, and budget implications.
9. Genuine blockers or decisions requiring owner approval.
10. Whether Expansion 20 is approaching a suitable next frozen playtest candidate.

Continue authorized work without waiting for unnecessary confirmations. Escalate only genuine owner decisions, compatibility risks, or proposed changes to approved rules.
