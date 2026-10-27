# Current development state — active handoff

**Updated 2026-10-27 (documentation-only authority cleanup).** Fetch current heads before acting. The previous handoff is preserved at `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_pre_2026-10-27_authority_cleanup.md` as an archived audit snapshot, **not active tasks**.

## Current baseline and mandatory release gate

- **Build 22**: existing private three-platform draft (`wip/build22` `b7e1c91`, run `40398771937`, 2026-10-26). Frozen, not reopened.
- **Expansion 20**: authorized in development on `wip/expansion20` (last observed `0dc0014`). LE-01 foundation with off switch, Android UI and Messages journal, and R1–R4 of Build 19 recovery have been integrated. Remaining recovery verification and LE-02–LE-07 are not finished, regardless of prior draft documents.
- **Aspirations R5**: isolated `wip/x20-r5` (last observed `bbfc6e2`), six domains including social standing, survival and family protections, measurement; switches off until valid integration. Q8=A (individual proposal acceptance with existing hard limits) is approved policy, not an assertion that it is already merged.
- **Multiplayer MP-INTERACT-01**: isolated `wip/x20-mp-interact` (`0ce4c9e` at last observation), implemented and targeted UI/network tests, **NOT YET INTEGRATED**. Two open owner questions MP-INTERACT-Q1/Q2 remain. Merge **LAST** onto the frozen combined X20 baseline and validate on Android/Windows/Linux with actual host/guest, input methods and real device gaps correctly identified.
- **RELEASE BLOCKER:** **NO Expansion 20 APK, Windows or Linux build of ANY KIND, private draft included, before MP-INTERACT-01 is merged last and validated.** Publishing remains separately controlled; Build 22 stays frozen.
- **Requirements**: owner reconciled 39 decisions on staging `5484ce1`; DCR-01 continuity added at `866af5c`. At this recorded point: 2 open multiplayer questions and 2 provisional (armour/identity); read latest register for counts. Future decisions are design only, not blanket work permission.

## Next actions (current work only)

1. Fetch latest staging and every active `wip/` worker branch. Check in-progress CI/simulations and local worktrees before running or assigning anything; never duplicate a live test.
2. Proceed with currently authorized recovery/aspirations and Living Economy work only in their dependency order and isolated worktrees. Coordinate SIM-F2/SIM-F3 fixes touching `npc_brain.gd` after R5 integration. Resolve LE-01 storefront/counter till actor gaps before future finance code; maintain conservation, Judgment and family rules.
3. After all other approved Expansion 20 batches are integrated and tested, integrate MP-INTERACT-01 **LAST**. Run applicable combined/targeted validation and cross-platform input-to-transaction paths; disclose untested actual device combinations.
4. Only when the blocker is satisfied, report release readiness and ask for/observe the applicable owner release authorization. Documentation changes do not authorize builds.

## Sources

Live statuses: `docs/requirements/requirements.json`, `docs/requirements/views/`; binding rules: `CLAUDE.md`, `docs/WORLD_DESIGN_RULES.md`, applicable owner directives (2026-10-27 multiplayer, aspirations, 39 decisions, DCR-01); current roadmap: `docs/EXPANSION_ROADMAP.md` active header. All earlier content in `docs/handoffs/archive/CURRENT_DEVELOPMENT_STATE_pre_2026-10-27_authority_cleanup.md` is historical only.
