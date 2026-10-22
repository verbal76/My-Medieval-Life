# Current development state

The session handoff (MEM-01, owner 2026-10-20; reshaped by REQ-CTRL-01, owner 2026-10-23). It holds **only
session-specific state**: branches, workers, what is in flight, next actions. It never restates a requirement's status.
That is in the register, `docs/requirements/requirements.json`, and its generated views in `docs/requirements/views/`.

Update it at every checkpoint: after a merge, when a worker starts or stops, before a context handoff (at about 70–75%
context, where measurable) and before a session ends. The previous long-form state file is archived in
`docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_to_2026-10-23.md` (history only).

**Updated:** 2026-10-23 (staging fast-forwarded to the reconciled register, REQ-CTRL-02).

## Read first (after a compaction or in a new session)

1. `CLAUDE.md` section 0. Then this file.
2. `docs/requirements/views/STATUS.md` (where each build stands), `BUILD_18.md` (the active build), `DECISIONS.md` (open
   owner decisions), `QUEUES.md` (workers, untested work, playtest queue).
3. The record of any task you resume, in `docs/requirements/requirements.json`; the procedure in
   `docs/requirements/SCHEMA.md`.

Never reconstruct state from a conversation summary: these files are the record.

## Branches

| Branch | Head | Role |
|---|---|---|
| `staging/my-medieval-life` | see `git log origin/staging/my-medieval-life -1` | records: the only branch where the register is edited |
| `wip/build18` | `840e0ed` (2026-10-23) | Build 18 integration; + village buying from the settlements and live couriers; 30-day conservation on 840e0ed running |
| `wip/build17` | `dfec7ec` | Build 17, frozen (private playtest draft from code `cd7439c`) |
| `wip/expansion19-preparation` | `c4b10e4` | Build 19 judgment prototype, switched off, isolated (PROS-01); synced with Build 17 only |
| `wip/expansion20-preparation`, `wip/expansion21-preparation` | `d82f173`, `0eeb3df` | documents only; Builds 20 and 21 not authorized |
| `wip/multiplayer` | `d18d7d1` | MP-01, excluded from Build 18; never merge without the owner |
| `main` | | changes only when the owner merges |

## Workers in flight

Each is a record in IN DEVELOPMENT; the validator requires it to be named here.

| Record | Worker | Branch | Started from | Notes |
|---|---|---|---|---|
| MIGRATE-18 (+ DVW-B5 settlement taxes) | migration worker (Sonnet subagent) | `wip/b18-migration` | `wip/build18` 840e0ed | people move between the village and the five; the settlements use TaxPolicy; owns offmap.gd |
| X18-Q12-BOOTH, X18-Q12-POST, X18-Q13, LAW-SKILL (+ REG-BUY-01 player food) | courier-completion worker (Sonnet subagent) | `wip/b18-courier2` | `wip/build18` 840e0ed | villagers book couriers, shop booths, notary path, settlement carriers; player buys food at the wagon; owns couriers.gd and the courier window |
| TRADE-CREDIT | credit worker (Sonnet subagent) | `wip/b18-credit` | `wip/build18` 840e0ed | barter and credit with trust; owns relations/trade-window code |
| X18-SIM | capability-sim worker (Sonnet subagent) | `wip/b18-capsim` | `wip/build18` 421525c | comparative capability simulations and report; no constants adopted (Q18-11) |

On their reports:
1. Review the work.
2. Merge it into `wip/build18`.
3. Run targeted integration and conservation checks on the merge commit (the suites the change touches, conservation runs); not broad suites without a specific reason (owner 2026-10-23, MSW-01). For the regions merge: the chapel and settlements share the settlement holdings script and the economy ledger.
4. Update the records: INTEGRATED, `test_commit`.
5. Regenerate the views.

## Next actions (lead)

1. Merge the courier and buying workers when they report (targeted checks; one 30-day conservation run per seed on the combined result), then REG-EVAL-01 against the preserved baseline (`docs/investigations/evidence_2026-10-23_regional/`).
2. The approved, unblocked Build 18 work in `docs/requirements/views/BUILD_18.md` ("Open, ready" and "not started" with
   design SPECIFIED). The audit's highest-value items:
   - wiring the couriers, formal contracts and Law notary (X18-Q12, X18-Q12-BOOTH, X18-Q12-POST, X18-Q13, LAW-SKILL);
   - ECON-P3, DVW-B5, DVW-B3-FEAST;
   - now unblocked by the regions merge: TRADE-CREDIT, MIGRATE-18, DVW-B3-LUX (couriers still use the old SettlementLedger parties).
3. Human reviews flagged by the reconciliation (`docs/requirements/RECONCILIATION_2026-10-23.md`, "Needs review").
4. The Build 18 release gate (REL18-*) only when the work is integrated; no distributable without the owner.

## Waiting on the owner

Every open decision is in `docs/requirements/views/DECISIONS.md`. In this session:
- the calendar question: X19-DECAY held as PROVISIONAL pending the owner's view of the 8-day year;
- the stone values (STONE-D1, STONE-D2);
- Build 18 target (owner 2026-10-23, `docs/directives/2026-10-23_reg_demo_d1_and_build18_target.md`): playable within five hours; punch list fixed; blockers to the owner promptly; REG-CIRC-D1 deferred until REG-EVAL-01;
- Build 18 packaging gate (REL18-PACKAGE): no test package until every Build 18 punch-list item is closed or accepted as permanently blocked;
- chapel review, non-blocking: CHAPEL-R1..R5 (player volunteering, offerings funding wages, old-save plants, ore layout, chapel art); the chapel's economic values are provisional working values;
- Builds 20 and 21 authorization.
