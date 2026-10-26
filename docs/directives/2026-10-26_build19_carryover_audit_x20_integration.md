Owner directive, 2026-10-26, verbatim.

MY MEDIEVAL LIFE

OWNER DIRECTIVE — BUILD 19 CARRYOVER AUDIT AND EXPANSION 20 INTEGRATION

OBJECTIVE

I want to prevent unfinished systems from accumulating across successive builds and eventually causing cascading integration failures.

Mini Build 22 has already been pushed. Do not restart it or unnecessarily repackage it.

Expansion 20 is now the active development effort.

Before advancing too far into the Living Economy, reconcile and incorporate the unfinished Build 19 requirements.

Nothing previously authorized, implemented or partially implemented should be abandoned simply because development advanced to another build number.

However, don't assume that an outdated requirements-register status proves a feature is absent.

Audit the actual code first.

---

1. ESTABLISH THE TRUE DEVELOPMENT BASELINE

Review:

- "wip/build19"
- "wip/build22"
- "wip/expansion19-preparation"
- "wip/expansion20"
- "wip/expansion20-preparation"
- "staging/my-medieval-life"

Also review:

- "docs/requirements/requirements.json"
- "docs/requirements/views/BUILD_19.md"
- "docs/requirements/views/BUILD_20.md"
- "docs/expansion20/X20_OPEN_ITEMS.md"
- Build 19 acceptance records.
- Build 19 release notes.
- Relevant design specifications.
- Current development and recovery handoffs.

Determine which branch contains the most recent integrated implementation of each system.

The Build 22 development branch and the Expansion 20 foundation branch must be reconciled without discarding either one's work.

Do not blindly overwrite a newer implementation with code from an older preparation branch.

---

2. AUDIT ALL 18 BUILD 19 CARRYOVERS

The Expansion 20 tracking document identifies these unfinished Build 19 requirements:

Judgment and NPC behavior

1. "SJD-E" — First gated integration of the Judgment System.
2. "SJD-F" — Incremental judgment integration across trade, aid, friendship, courtship, employment, crime and politics.
3. "SJD-G" — Extended simulation, calibration, performance and save-migration validation.
4. "SJD-H" — Final judgment review and release-readiness gate.
5. "PROS-19" — Prospective judgment, memory and decision-system integration.
6. "X19-FOUND" — Personality, relationship history and family-reputation foundations.
7. "DVW-B1" — Villager relationships, memories of favors and harms, and gossip.
8. "DVW-B2" — Assault, killing, fines and inherited consequences.

Memory and information

9. "GM-01" — Generational memory and historical consequences.
10. "X19-MISINFO" — Deliberate lies, misinformation and correction.
11. "X19-STORY-LIFE" — Family stories and reputation across generations.

Simulation and diagnostics

12. "REC-19" — Full simulation flight recorder.
13. "REC-DIAG" — Simulation diagnostics and investigation.
14. "REC-STORE" — Complete preservation of recorded decisions and alternatives.
15. "B19-EMERGE" — Emergent-behavior verification and classification.

World rules and integrity

16. "WDR-009-C" — Emergent Gameplay world-design compliance.
17. "WDR-011-C" — NPC Self-Improvement and Prosperity compliance.
18. "FIX-D1D2" — Disabled judgment and economy features preserve saved data without activating.

These are the exact carryover requirements identified in the register.

Do not omit them.

Do not treat an umbrella requirement as an additional independent implementation if its constituent work already exists.

For every requirement, establish:

- Intended behavior.
- Actual current implementation.
- Branch and commit containing the code.
- Whether it is integrated into the latest playable build.
- Whether it is enabled.
- Whether its tests pass.
- What functionality is actually missing.
- What must be implemented.
- Dependencies on other systems.
- Whether it requires an owner decision.

Distinguish between:

Not implemented, partially implemented, implemented but not integrated, integrated but disabled, implemented but unverified, and completed.

These are different conditions.

---

3. VERIFY THE NINE BUILD 19 ITEMS AWAITING ACCEPTANCE

The following requirements were recorded as implemented but awaiting verification:

- "FAM-SAC-01"
- "FIX-D3"
- "FIX-RECF1"
- "SJD-B"
- "SJD-C"
- "SJD-D"
- "X19-FOUND-BONDS"
- "X19-FOUND-FAMREP"
- "X19-FOUND-PERS"

Confirm they remain present and functional on the latest integrated development branch.

Do not rebuild working features.

Reuse existing applicable test evidence.

Where additional verification is genuinely required, perform targeted checks.

Leave real-device or owner-playtest acceptance clearly identified rather than falsely marking it complete.

---

4. INVESTIGATE THE BUILD 19 COMPLETION CONTRADICTION

This requires particular attention.

The requirements register says Build 19 was completed and accepted as the development milestone.

However, it also identifies Judgment System rollout stages E through H as incomplete or not started.

Determine whether:

1. The rollout stages were actually completed under different requirement identifiers.
2. Their code exists but was never properly integrated.
3. They were superseded by a later implementation.
4. The register was not updated.
5. The release was marked complete while material scope remained unfinished.

Present the evidence for whichever explanation is correct.

Do not change the register merely to make the completion percentage look better.

Do not mark unimplemented features complete.

Also do not duplicate an existing live Judgment System because an old planning entry still says NOT STARTED.

The actual implementation is the deciding evidence.

---

5. MAKE BUILD 19 RECOVERY PART OF EXPANSION 20

This is the central instruction.

All legitimately unfinished, previously approved Build 19 work is now a mandatory integration and completion workstream within the active Expansion 20 development effort.

It must not be pushed indefinitely into Expansion 21, 22, 23 or later.

Do not reopen the already-pushed Mini Build 22 just to change its scope.

Use the active development line following Build 22.

Preserve its baseline and save compatibility.

Reconcile source branches before starting new implementations.

Required integration order

First: establish foundations.

Verify personality, relationship history, memory structures, judgment records, and save integrity.

Second: complete the judgment integration.

Ensure the approved NPC judgment mechanics genuinely influence their intended decisions.

They must affect behavior, not simply collect unused scores.

Third: complete misinformation and historical memory.

Implement the approved propagation, correction and persistence mechanics.

Fourth: integrate the simulator and diagnostics.

Make sure judgment, memory and NPC decision changes can be measured and explained.

Fifth: verify interactions with the Living Economy.

The economy must use the same NPC knowledge, judgment, trust and decision systems.

Do not construct a competing reputation or decision engine inside the economy.

Use the existing shared model.

Independent Android polish and interface work may proceed in parallel where it does not interfere with these systems.

---

6. PREVENT INTEGRATION CASCADES

I do not want unfinished systems becoming buried under increasingly complicated dependencies.

For each integration, verify:

- Existing system behavior remains intact.
- Data ownership is clear.
- Shared systems are reused.
- No duplicate economic or reputation ledger is introduced.
- Determinism remains intact.
- Inventory and currency are conserved.
- Save compatibility remains intact.
- Disabled systems remain disabled.
- Enabled systems behave according to approved rules.
- New behavior does not introduce unnecessary population-wide processing.

Test integrations incrementally.

Do not merge five interdependent systems simultaneously and then attempt to discover which one broke the simulation.

Preserve known-good baselines.

When a legitimate new feature changes the baseline, document and explain the differences before accepting the new one.

---

7. LIVING ECONOMY DEPENDENCY RULE

Continue work on LE-01 where it is independent of unfinished judgment integration.

However, before activating economic decisions that depend on NPC opinions, relationships, knowledge or trust, verify that the underlying systems are correct.

An NPC deciding whether to purchase iron from someone they dislike must use the approved shared Judgment System.

Their opinion should influence the decision alongside need, price, scarcity and alternatives.

It must not automatically prohibit the transaction.

Do not create a second judgment implementation inside the economy.

Do not invent economic policies covered by unresolved owner decisions.

Prepare those decisions for owner review.

---

8. CORRECT THE REQUIREMENTS-REGISTER CI FAILURE

The latest requirements CI failure identifies nonexistent ".claude/worktrees/..." paths referenced in:

"docs/CURRENT_DEVELOPMENT_STATE.md"

The GitHub runner does not have those session-local worktrees.

Correct the underlying documentation or validation design so that:

- GitHub branch references can be validated independently of local worktrees.
- Ephemeral local worktree locations are not required to exist on CI runners.
- Actual missing branches and missing committed artifacts are still detected.
- Requirements integrity checks remain meaningful.

Do not simply disable the validator.

Do not change feature-completion statuses to force a green result.

Reconcile the actual development state and regenerate the requirements views from the authoritative register.

---

9. PRODUCE A BUILD 19 RECOVERY MATRIX

Before major implementation begins, produce a complete audit matrix.

For each of the 18 unfinished requirements and nine verification requirements, show:

Field| Required information
Requirement ID| Exact register ID
Original scope| What was promised
Current implementation| What actually exists
Source location| Branch, commit and files
Current integration| Present in active development branch?
Actual functionality| Working, disabled, incomplete or absent
Validation| Tests and results
Remaining work| Specific implementation tasks
Dependencies| Required systems and sequencing
Disposition| Complete, verify, integrate, implement or genuinely blocked

Provide totals by disposition.

Include evidence for all findings.

Preserve the records in the repository.

This must become a maintained recovery workstream rather than another document that gets forgotten.

---

10. EXECUTE THE RECOVERY WORK

After the audit:

1. Integrate code that already exists and is correct.
2. Finish partially implemented systems.
3. Implement missing previously approved functionality.
4. Resolve integration defects.
5. Run focused tests.
6. Confirm save and simulation integrity.
7. Update the requirements register.
8. Continue the Living Economy on the reconciled foundation.

Do not stop after producing the report.

You are authorized to implement the outstanding, previously approved requirements.

If an item has an unresolved policy decision that materially changes gameplay, preserve that specific decision for the owner. Do not guess it.

Continue independent approved work while waiting for such decisions.

Where multiple requirements describe the same functionality, satisfy them with one shared implementation and link the evidence to each applicable requirement.

Do not inflate the amount of work by implementing duplicates.

---

11. SIMULATION DISCIPLINE

Do not immediately launch another enormous simulation campaign.

Use existing evidence where applicable.

Proceed with targeted tests and short deterministic runs as components are integrated.

Increase simulation length only when the system is sufficiently stable to produce meaningful results.

Preserve historical baselines.

Long 100-day and 365-day campaigns remain part of the final Judgment System validation requirements, but should be scheduled intelligently after integration rather than repeatedly run against unfinished code.

Report meaningful changes, failures and first divergence points.

---

12. DEVELOPMENT CHECKPOINTS

Maintain an up-to-date recovery document containing:

- Build 22 source baseline.
- Active Expansion 20 branch.
- Current integrated commit.
- All 18 Build 19 carryovers.
- Nine pending verification items.
- Current implementation status.
- Remaining dependencies.
- Test evidence.
- Worker assignments.
- Any unresolved owner decisions.
- Next executable task.

Update it before session compaction.

Treat approximately 80% context consumption as the practical recovery checkpoint.

Do not lose partially completed work or worker branch changes.

---

13. COMPLETION REQUIREMENT

Do not report that the Build 19 recovery is complete until every item has a justified disposition.

An item can be:

- Implemented and verified.
- Already satisfied by a demonstrably equivalent implementation.
- Awaiting specifically identified owner-device verification.
- Blocked by a documented unresolved owner decision.
- Explicitly deferred by the owner.

It cannot simply disappear from the requirements register.

Previously approved functionality must not be silently deferred because another expansion has started.

No unauthorized public release or broad feature activation.

Mini Build 22 stays intact.

Expansion 20 continues on the reconciled foundation.

FINAL DIRECTIVE

My concern is not the numbering of the builds.

My concern is allowing unfinished systems to accumulate until future implementation becomes a cascade of failures.

I want the unfinished Build 19 scope audited, recovered, integrated and completed within the current Expansion 20 effort.

Preserve everything already accomplished.

Do not duplicate working code.

Do not hide incomplete requirements.

Do not introduce new incompatible systems to compensate for unfinished old ones.

Close the backlog before it becomes technical debt embedded throughout the Living Economy.

Proceed with the audit and authorized recovery implementation.
