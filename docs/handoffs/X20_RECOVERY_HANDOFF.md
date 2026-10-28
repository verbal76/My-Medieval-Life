# Expansion 20 recovery handoff (Medieval development PAUSED, 2026-10-28)

Owner decision 2026-10-28 (`docs/directives/2026-10-28_x20_checkpoint_build_and_pause.md`, register X20-CHECKPOINT): Build 24 is a
private checkpoint of Expansion 20; after it, **all Medieval development is paused** (Upwardly is the studio's priority). Expansion 20 is
not abandoned and not complete. Resume only on the owner's explicit instruction. Statuses here are a snapshot; the register
(`docs/requirements/requirements.json`, views in `docs/requirements/views/`) is authoritative.

## 1. Where everything is

| What | Branch | Commit |
|---|---|---|
| Expansion 20 integration (all groundwork below) | `wip/expansion20` | Build 24's commit (see the register's X20-CHECKPOINT and the Build 24 release) |
| Register, directives, handoff | `staging/my-medieval-life` | latest |
| Build 23 (previous checkpoint, MP-INTERACT-01) | `wip/x20-final` | `c79b12c` |
| Build 22 (frozen) | `wip/build22` | `b7e1c91` |
| Merged task branches (kept for history) | `wip/x20-migrate` `b9c585a`, `wip/x20-sword` `8fd01fa`, `wip/x20-foundation` `3a6eee8`, `wip/x20-tillkeep` `00cfa87`, `wip/x20-le02` `01e6823` | merged into `wip/expansion20` |

Accepted simulation baseline: `docs/release/sim_baseline.json` on `wip/expansion20` (replaced 2026-10-28 for free migration; evidence
`docs/release/SIM_BASELINE_CHANGES_X20_MIGRATE.md`; previous kept as `sim_baseline_pre_x20_migrate.json`).

## 2. Feature state in Build 24

**Active (playable):** everything through Build 23 (MP-INTERACT-01 player-to-player interaction, Messages journal, Android UI, village
fixes), plus GP-SWORD-VIS (visible sword held, swung and returned; armed NPCs too), X20-MIGRATE (free migration, REG-X20-D1), the
storefront-till rules (LE-01 till ownership; ended-household escheat fixed; X20-TILL-KEEP, TILL-D1: a leaving household keeps its till),
REC-DIAG (flight-recorder diagnostics and the abnormal-run report; tooling, not gameplay).

**Built but switched OFF (owner review needed before activation):** the Living Economy (`game/data/economy.json` `"enabled": false`:
LE-01 model and the LE-02 market: adaptive bids and asks, haggling, settlement, offers seen only in person and by word of mouth, per-unit
procurement contracts, renegotiation; `market.drive` is true but does nothing while the economy is off), aspirations (six domains, R5),
job choice, witness reporting decisions. All LE-02 parameters are PROVISIONAL (`docs/DECISIONS.md` 2026-10-28; LE02_IMPLEMENTATION.md).

**Awaiting implementation (Expansion 20, register NOT STARTED):** LE-03, LE-04, LE-05, LE-06, LE-07, EMP-PERM-01, GP-POLISH (the batch
record; most of its children are integrated), SJD-G, SJD-H, B19-RECOVERY (remaining R6-R8), EXP-D (the umbrella, closes with LE-07).

**Awaiting real-device verification (integrated, automated tests only):** about 50 records carry a `playtest` need, among them
MP-INTERACT-01 (all nine host/guest platform pairs), GP-SWORD-VIS, MP-PLAYER-FAMILY, WEAPON-VISIBLE-01, the Android UI items
(GP-ANDROID-*), GP-JOYSTICK, GP-LOCKPICK, GP-ANVIL and the other GP- items. Query: register records with `target_build` 20 and a
`playtest` field.

## 3. Remaining Expansion 20 work, in order (when resumed)

Authority: `docs/directives/2026-10-27_complete_expansion20_first.md` (X20-COMPLETE, now suspended) and
`docs/directives/2026-10-27_x20_scope_and_free_migration.md` (X20-SCOPE: the FUTURE Living Economy answers OD-LE-03, -04, -08, -11, -13B,
-14 are in scope; lending, interest and manor emergency loans excluded).
1. **LE-03** production, job choice and household budgets. Start here: LE-02 left two buying channels (the villagers' existing routines and
   `npc_orders` do not read reservations, so goods or coins behind an offer can leave through them; the market only reports and trims):
   unify them; food bids and household budgets; negotiated wages and services behind their switch (OD-LE-03/D02); job choice stays behind
   its gate.
2. **LE-04** finance, merchants, manor: business identity and separate accounts (OD-LE-04/D03, OD-LE-07/D06; the till holder rule is the
   current owner), stockpiling and speculation (OD-LE-11/D10), contracts through the estate (OD-LE-13B/D12, needs a save migration);
   no lending.
3. **LE-05** construction, ecology, mining, bandits, regional links: rental and repair (OD-LE-08/D07), the player's market journal
   (OD-LE-14/D13), settlement-to-settlement food trade (REG-X20-D3 approved under REG-BUY-D1: a live path is missing), travel and risk
   costs in prices; mining under the existing depletion rules; no mining-only economic rules.
4. **Carryovers:** EMP-PERM-01 permanent employment; GP-POLISH remainder; SJD-G calibration soak; SJD-H is the owner's review.
5. **LE-06** multi-seed long runs on GitHub Actions (economy on and off), calibration of every provisional parameter, performance on a
   mid-range phone target (OD-LE-15: ~500 NPCs, ~4 ms a frame to profile); include migration and abandoned businesses (owner, X20-SCOPE).
6. **LE-07** release readiness; a completed Expansion 20 release still needs everything above (X20-COMPLETE).
REC-DIAG gaps left on purpose: player premises' till moves, rents and attendants' wages, construction not yet recorded as events.

## 4. Owner decisions

Deferred by the owner (2026-10-28 cleanup): MP-INTERACT-Q1 (player-to-player service contracts), MP-INTERACT-Q2 (Talk priority for
players), REG-X20-D2 (hunger migration when no food is for sale), REG-X20-D4 (re-evaluate settlement circulation). Provisional:
ARMOR-CATALOG-D1 (armour numbers, the owner's balance and art review), ID-D3 (identity baseline: needs a same-commit audit before
promotion). Answered in this period: X20-SCOPE, REG-X20-D1 (free migration), TILL-D1 (household keeps its till), REG-X20-D3 (approved
under REG-BUY-D1).

## 5. Working notes for whoever resumes

- Session start: CLAUDE.md section 0. Register edited on staging only (`tools/requirements_update.py`).
- The cloud container is reclaimed while a session is idle: local runs longer than ~20 minutes die. Run simulation gates on GitHub
  Actions (`long-sims.yml`, seeds 1,2, days 30, every 10; compare day-30 fingerprints with `sim_baseline.json`) or stay active.
- `tools/sim_gate.py --write` records a new baseline (only with evidence and a DECISIONS row).
- Tests that matter for this area: `le02_market_test`, `economy_model_test`, `economy_foundation_test`, `till_ownership_test`,
  `business_money_test`, `migration_test`, `sword_visual_test`, `recorder_test`, `contracts_test`, `mp_interact_ui_test`,
  `net_interact_test`, `net_mp4_test`, `run_tests`, `start_test`, `world_test`.
- `net_interact_test` can fail timing checks when the machine is fully loaded; rerun once on an idle machine before treating it as real.
