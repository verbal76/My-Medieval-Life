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
| `wip/build18` | `3704bfe` (2026-10-23) | Build 18 integration; chapel and the five settlements merged; targeted checks on the merge (chapel, regions, save transfer) |
| `wip/build17` | `dfec7ec` | Build 17, frozen (private playtest draft from code `cd7439c`) |
| `wip/expansion19-preparation` | `c4b10e4` | Build 19 judgment prototype, switched off, isolated (PROS-01); synced with Build 17 only |
| `wip/expansion20-preparation`, `wip/expansion21-preparation` | `d82f173`, `0eeb3df` | documents only; Builds 20 and 21 not authorized |
| `wip/b18-wagefix` | `cf76ed2` | necessity-wage correction for off-map businesses (REG-INV-01); held for the owner (REG-WAGE-D1), not merged |
| `wip/multiplayer` | `d18d7d1` | MP-01, excluded from Build 18; never merge without the owner |
| `main` | | changes only when the owner merges |

## Workers in flight

Each is a record in IN DEVELOPMENT; the validator requires it to be named here.

| Record | Worker | Branch | Started from | Notes |
|---|---|---|---|---|
| DVW-B3-FEAST | feast worker (Sonnet subagent) | `wip/b18-feast` | `wip/build18` 2e059fa (merge onto 3704bfe; the regions merge also changed `World.load_dict`) | wedding and seasonal feasts at the tavern (`docs/directives/2026-10-23_owner_answers_coin_sinks.md`); stays out of the settlement scripts (the regions worker owns them) |
| DVW-B3-LUX | luxury worker (Sonnet subagent) | `wip/b18-luxury` | `wip/build18` 36beb67 | luxury imports sold by the settlement traders (caravan); stays out of the tavern and feast code |
| REG-DEMO-01 | demography worker (Sonnet subagent) | `wip/b18-demography` | `wip/build18` 7fc4426 | ages, births, age deaths, growing up, households, inheritance in the off-map settlements |
| REG-PARTY-01 | party worker (Sonnet subagent) | `wip/b18-party` | `wip/build18` 7fc4426 | one trading-party interface over the five settlements for RegionalMarket and couriers |

On their reports:
1. Review the work.
2. Merge it into `wip/build18`.
3. Run targeted integration and conservation checks on the merge commit (the suites the change touches, conservation runs); not broad suites without a specific reason (owner 2026-10-23, MSW-01). For the regions merge: the chapel and settlements share the settlement holdings script and the economy ledger.
4. Update the records: INTEGRATED, `test_commit`.
5. Regenerate the views.

## Next actions (lead)

1. Merge the feast worker when it reports (chapel and regions are merged).
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
- regional economy (REG-INV-01 report `docs/investigations/2026-10-23_regional_economy.md`): REG-WAGE-D1 (merge the wage correction), REG-BUY-D1, REG-CIRC-D1;
- chapel review, non-blocking: CHAPEL-R1..R5 (player volunteering, offerings funding wages, old-save plants, ore layout, chapel art); the chapel's economic values are provisional working values;
- Builds 20 and 21 authorization.
