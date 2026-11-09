MY MEDIEVAL LIFE — OVERNIGHT AUTONOMOUS DEVELOPMENT DIRECTIVE

OWNER APPROVALS, CONTINUITY, AND SAFE BLOCKER RECOVERY

The owner will be unavailable for an extended period.

Continue previously authorized development, testing, integration, and audit-backlog remediation without requiring routine check-ins.

The objective is maximum productive progress while preserving every owner decision, all development evidence, and the integrity of the game.

1. CURRENT PRIORITIES

Complete the three active recorded 365-day campaigns:

- LIFE-03/04
- PROP-06
- JUS-04/REG-07

Validate each campaign against its existing acceptance requirements.

Merge eligible batches in the previously authorized sequence, without force-pushing.

After integration, verify the combined state and update the GitHub development records.

Continue MP-05 verification and other authorized Build 25 work.

2. PRESERVE ALL OWNER DECISIONS

The owner answered numerous questions on November 8, 2026.

Before proceeding, reconcile the decision register, development documentation, and current implementation against these approved decisions.

These decisions supersede older audit-register entries that incorrectly describe them as unanswered.

Approved decisions

LIFE-03: Qualified healer/apprentice succession is approved.

LIFE-04: Widows and widowers may remarry. Preserve previous marriage history and family relationships.

LIFE-05: Bandit heirs inherit last. Rehabilitation and return to ordinary life are permitted, but criminal history remains.

PROP-06: Outright-owned property may be sold before migration, with proceeds retained. Leased property is surrendered to the manor, including improvements and construction materials, without compensation. Personal belongings and money remain with the migrating household.

Multi-parcel estate sales must be atomic. Existing tenants retain their leases under the new landlord. Failed sales must fully roll back. The Lorekeeper's hut is included when selling owned property.

MP-05: Cross-player asset sharing is mutual and reciprocal, requires proposal and acceptance, and defaults to no sharing.

Approved tiers:

1. Materials.
2. Materials and finished goods.
3. Materials, finished goods, tools, and property use.

Either player may revoke sharing. Ownership, sale authority, and demolition authority are not transferred.

MP-07: Private records are not automatically shared between players. Players learn private information through ordinary gameplay. Asset-sharing agreements do not grant access to private information.

JUS-04: Criminal reputation consequences may affect relatives only after the relevant crime information has actually reached them through the game's knowledge systems.

REG-04: Couriers physically travel.

REG-05: Migrating households physically travel.

REG-07: Trade intelligence remains valid for no longer than one eight-day game year.

EMP-03: Count everyone actively seeking work for hiring-competition purposes.

BIZ-03: Option B approved. Employee payroll takes priority over owner withdrawals. Hiring affordability must account for existing workforce obligations plus the proposed employee.

BIZ-04: A living household retains its business money when migrating. Investigate venture tills and ownership transfers to ensure this rule is followed.

TRD-02: Record actual net proceeds rather than gross amounts when calculating the relevant merchant earnings.

INV-04: Goods left behind in sold property transfer to the purchaser, subject to existing tenant rights and other established ownership protections.

INV-05: Do not permit unapproved conversion of rubble or waste into dressed stone. Reproduce the suspected recovery issue and correct it consistently with established material rules.

SAV-02: Preserve saved economic state correctly during loading and continuation.

PROP-03: Surrendered leased property, improvements, and materials pass to the manor without compensation. Eviction and unfinished construction recovery still require technical investigation.

Decisions still requiring investigation

REG-08: Courier stranded-delivery recovery remains a technical investigation. Do not assume the issue is resolved.

SAV-04: The exact requirement for uninterrupted wildlife/combat continuity versus deterministic continuation from a saved state remains an unanswered owner decision. Do not independently invent a new policy.

If any other decision appears unresolved, search the existing decision history and repository records before asking the owner again.

Do not reopen settled decisions merely because an older audit document predates their approval.

3. ABSOLUTE RULE — SAVE WORK BEFORE SWITCHING TASKS

When encountering a definite blocker:

1. Stop making changes to the blocked task.
2. Record the exact blocker, reproduction evidence, and reason progress cannot continue.
3. Preserve all completed and unfinished source changes in the appropriate isolated Git branch.
4. Commit the work with an accurate status indicating whether it is complete, experimental, or blocked.
5. Push the branch to GitHub.
6. Verify the remote branch contains the expected commit SHA.
7. Record relevant test results, failures, workflow IDs, artifacts, and remaining tasks.
8. Update the development state, audit register, and decision documentation.
9. Ensure another development session could resume the task without reconstructing the investigation.
10. Move to the next highest-priority authorized, unblocked issue.

Do not leave important work solely in temporary files, uncommitted changes, or a Claude session's working memory.

Never force-push, overwrite another branch's work, or merge an unverified change merely to preserve progress.

If a GitHub push itself is blocked, preserve a durable local commit and patch, document the recovery location and exact blocker, and clearly report that the work is not remotely backed up.

4. KEEP WORK MOVING

A blocker affecting one task must not automatically stop the entire development session.

Examples:

- A missing owner decision blocks one feature.
- An unresolved simulation defect blocks one merge.
- A GitHub infrastructure problem blocks a particular validation workflow.
- A test failure requires a deeper investigation than the current task permits.

Preserve the work and move to another independent authorized issue.

Continue until no useful authorized work remains, a session/resource limit is reached, or a blocker prevents all further safe progress.

Do not bypass genuine failures to maintain momentum.

5. REMAINING AUDIT BACKLOG

Use the 69-item audit register as the original tracking baseline, but reconcile every item against newer GitHub implementation, verification, and owner-decision evidence.

Do not assume the old OPEN labels remain accurate.

Do not assume every finding represents a confirmed defect.

Prioritize high-risk unresolved items, particularly:

- Employment and apprenticeship consistency.
- Save/load and deterministic continuation.
- Multiplayer authorization and host/guest ownership.
- Business transactions and conserved assets.
- Property and lease recovery.
- Inventory conservation.
- Regional couriers and migration.

Investigate and reproduce suspected defects before modifying production behavior.

Keep completed, verified, blocked, deferred, and uninvestigated items distinct.

6. DEVELOPMENT AND TESTING STANDARDS

For every correction:

- Record the root cause and why the correction was necessary.
- Use the smallest safe implementation.
- Add or update appropriate regression tests.
- Preserve determinism and economy conservation.
- Never weaken assertions to manufacture passing results.
- Never silently re-record baselines.
- Verify against exact commit SHAs.
- Keep gameplay changes within approved requirements.
- Preserve evidence in GitHub.

Reuse successful test evidence when valid.

Avoid unnecessary repeated 365-day simulations and excessive GitHub Actions consumption.

Do not initiate additional paid independent audit agents, raise spending limits, or publish releases.

7. CONTINUITY AND HANDOFF

Update the authoritative repository state whenever:

- A task is completed.
- A defect is confirmed.
- A correction is committed.
- A campaign finishes.
- A merge occurs.
- A blocker is encountered.
- Work moves to another task.

Record what was done, why it was done, what was tested, what remains, and the next exact action.

Use permanent GitHub records so another session can recover the project without requiring the owner to prepare a handoff document.

8. REPORTING

Use counts rather than percentages wherever possible.

Report significant milestones, actual blockers, and decisions genuinely requiring owner approval.

Do not interrupt the owner with routine progress questions.

Continue automatically on independent authorized work whenever possible.

FINAL DIRECTIVE

The owner has already supplied numerous decisions. Respect them.

The owner wants development to continue while unavailable.

A definite blocker means preserve the work, record the evidence, safely checkpoint it in GitHub, and proceed to another authorized task.

Do not lose progress. Do not invent policy. Do not conceal failures. Do not waste time waiting for an answer when other legitimate work can continue.

Continue development under these rules.