# Expansion 18: integration readiness for Build 18 (evidence note, not a merge)

Prepared 2026-10-22 on `wip/x18-readiness` (from `origin/wip/expansion18-preparation` `3de7a8f`). Rules applied: owner
directive `2026-10-22_build18_master_overnight_execution.md` part 7 (experience and effective capability distinct;
facilities may limit effective capability, never erase experience; 0-10 framework; capability never blocks employment;
no invented D2-D9 values; no incomplete modifier active; integrate only completed, approved, compatible systems with
unfinished behaviour off).

## Per system (tests run headless on this branch, 2026-10-22)

| System | Implemented | Switch and default | Tests (result) | Owner decisions still needed |
|---|---|---|---|---|
| X18-CAPCOMP part 1: experience by person and industry (`settlement/experience.gd`, `WorkExperience`) | Hours credited from work steps (`npc_brain`, player action hooks), caps, straight-line level, hours-weighted workforce report, effective level computed (never stored; `facilities.caps` empty so effective = experience), D1 starting experience seeded once (`seed_once`), forgotten at dawn after death/departure | **Live and recording**: always on, a record only. Nothing reads it for pay or output while `CapabilityHook.per_worker` is false | `experience_test` 61 checks, 0 failures | D2 facility limits (nothing limits yet: effective = experience), D3 thresholds, D4 unattributed work (trade, building, hauling credit nothing), D9 emigrants |
| X18-CAPNUM: approved modifier profile (`settlement_industries.json` `effects`, `CapabilityHook`) | `approved` profile data; pay and output multipliers; per-worker path prepared | **OFF**: `CapabilityHook.forced = {}`, `per_worker = false`, `experience = null`; every call returns base. Only analysis runs (`economy_sim --capability`) force it. Fingerprint identical with it off | `capability_test` 72 checks, 0 failures | D2 (effective level), D4, D5 rounding (floor vs interpolate), D6 posted wages, D7 crop shares, D8 whole coins; mining needs the MIN-D stage to 0-10 mapping, so mining stays 1.0 |
| X18-Q12 couriers (`settlement/couriers.gd`, `couriers.json`, `ui/courier_window.gd`) | Booths on existing stalls, regular routes, special deliveries, known recipients, journeys, collection, deposits, refusals, interruptions; postage-style window | **Not wired into the game loop** (no caller in `main.gd` or the brain; tests and a screenshot script drive it). The only live touch is the `Relations.trades` record via a `World.trade` hook | `courier_test` 44 checks, 0 failures | Q18-14 (notary skill), Q18-15 (major businesses' booths), Q18-16 (village booth with no free stall), fee coefficients |
| X18-Q13 formal contracts (`settlement/formal_contracts.gd`, `FormalAgreements`) | Small agreements unsigned; formal and ownership transfers need signatures, face to face or via a notary courier; no remote signing | **Not wired** (tests drive it). Documented as reconciling with Build 17's CON-01 (acceptance waits for signatures); provisional adapter | `contract_sign_test` 20 checks, 0 failures | Q18-14 (notary qualification is a provisional data check) |
| Settlement model, specialization, report, holdings (`industries.gd`, `facts.gd`, `holdings.gd`, `report.gd`) | Capability per industry from people, skills, tools, stock; read-only report | Read-only, driven by tests/report; no live behaviour | `settlement_test` 83 checks, 0 failures | Q18-2 thresholds, Q18-1 skills |
| Regional trade, routes, ledger (`regional.gd`, `routes.gd`, `ledger.gd`) | Supply/demand, routes, competition, cooperation, conservation | Isolated; caravan unchanged | `regional_test` 71 checks, 0 failures | Q18-3 to Q18-8 (purse, off-map regions, barter, migration) |
| `settlement_save.gd`, `mining_adapter.gd`, `productivity.gd`, `capability_hook.gd` | Optional save section for settlements; mining adapter reads live MIN-D; no-double-counting rules | Not called by the game | covered by the above | MIN-D stage mapping |

Not run (not needed for this note): `caravan_compare`, `economy_sim`, the full suites.

## Save format

- `World.SAVE_VERSION` is **unchanged** (still 17 on this branch). No version bump, no migration.
- New optional save keys: `x18_experience` (written only once non-empty: seeded or worked; loading a save without it seeds
  starting experience once, per D1) and `x18_settlements` (`SettlementSave`, optional). Absent keys are defaults.
- Consequence for Build 18 (v18, going to v19): the experience section is an optional key and needs no version of its own,
  but a v18/v19 save without it will be seeded on load (D1 `seed_once`), which is deterministic but is a behaviour on
  load that should be listed in the save notes. If `x18_experience` is integrated, the version bump owner should decide
  whether it rides in v19 or stays an optional key.

## Merge compatibility (`git merge --no-commit --no-ff origin/wip/build18`, aborted)

Conflicting files: **`game/scripts/core/npc_brain.gd` only** (auto-merged: `.github/workflows/tests.yml`, `farm_plots.gd`,
`farming.gd`, `world.gd`, `main.gd`). The conflict is in the X18 HOOK work-step credit and capability sites, which are
small and mark themselves ("X18 HOOK").

## Recommended integration set (hooks off, nothing activated)

1. **Integrate now, behaviour-neutral:** X18-CAPCOMP part 1 experience *recording* (`experience.gd`, the world and
   brain credit hooks, `x18_experience` optional key, D1 seeding). It is approved (owner D1, CAPCOMP part 1), tested, and
   affects nothing until the hook is on. Resolve the `npc_brain.gd` conflict by hand, keeping Build 18's side and
   re-adding the credit call.
2. **Integrate as dormant code:** `CapabilityHook` with the `approved` profile (X18-CAPNUM), off by default
   (`forced` empty, `per_worker` false). Keep it off: the per-worker path needs D2, D4, D5, D6, D8 first.
3. **Do not integrate yet:** couriers (Q12) and formal contracts (Q13) are not wired and still depend on Q18-14 to Q18-16
   and a CON-01 reconciliation; regional trade, routes and the settlement report depend on Q18-1 to Q18-8 and SET-C/D.
4. **Decisions that unlock activation:** D2 (facility limits; recommended: none now, condition cap later), D4 (unattributed
   work; trade is the largest effect), D5 (rounding), D6 (posted wages), D7 (crop shares, needs `wip/farm-cropshare`),
   D8 (whole coins), D3 and D9 (non-blocking). Capability never blocks employment in any of these options.
