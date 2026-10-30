# Parallel development plan and interface contracts (2026-10-30)

Owner directive: `docs/directives/2026-10-30_master_development_resumption.md` (register X20-RESUME). Lead: the coordinating
session (integration, register, handoff, releases). Integration branch: `wip/expansion20` (Build 24 = `4611d86`; Build 24 stays a
reproducible checkpoint by its tag `build-24`). Workers branch from `4611d86`, commit and push only their own branch, never edit the
register (`docs/requirements/`), and report to the lead.

## Workstreams and ownership

| Stream | Register | Branch | Owns (may edit) | Must not edit |
|---|---|---|---|---|
| A Living Economy | LE-03 (then LE-04..LE-07) | `wip/x20-le03` | `game/scripts/core/economy/`, `game/data/economy.json`, the village buying paths (`npc_brain.gd` buying and `npc_orders`, `World.trade` and its guards, `business_money.gd`, `contracts.gd` market hooks), LE tests | `game/scripts/core/settlement/`, `game/scripts/net/`, net UI |
| B Settlement food trade | X20-SETTLE-FOOD | `wip/x20-settle-food` | `game/scripts/core/settlement/` (`regional.gd`, `regions.gd` road trade, `offmap.gd` food buying, `settlement_party.gd`, `ledger.gd`), `game/data/settlements.json`, regional tests | the village's `World.trade`, `economy/`, `net/` |
| C Multiplayer Batch D | MP-MASTER Batch D, MP-INET, MP-D6 | `wip/mp-batchd` | `game/scripts/net/`, `game/scripts/ui/net_window.gd` and new net UI, net parts of `main.gd` (host/join/menus), `game/export_presets.cfg` network permissions, net tests | `economy/`, `settlement/`, `World.trade` |

## Shared interfaces (contracts)

1. **One authoritative transaction per economy layer.** Village actors (villagers, players, tills, the manor) trade only through
   `World.trade` (A owns it; LE-03 makes it the single path with validate-then-commit semantics). Settlement-to-settlement trade uses the
   existing settlement layer's `RegionalMarket.execute` and `SettlementLedger` buy/sell lines (B extends; no new purchase path). Where
   the village and a settlement trade, the existing caravan/courier path stays as it is. Nobody adds a third path.
2. **Multiplayer guests act through the host's verb path** (`net_actions.gd` to the host's `World` calls). C changes transport,
   sessions and reconnection, never the game verbs; A's changes to `World.trade` reach guests automatically through that path.
3. **Saves:** optional keys only, each in its own section: A `economy`, B the `regions`/settlement sections, C none expected
   (session state is not saved; if C needs a key it asks the lead). No `SAVE_VERSION` change without the lead; old saves must load.
4. **Shared documents** (`docs/DECISIONS.md`, `docs/SYSTEM_INTERACTION_MANIFEST.md`): each worker appends rows and INT entries in
   its own range (A INT-6xx, B INT-62x, C INT-64x; check the next free number on base); the lead resolves textual conflicts at merge.
5. **Simulation baseline:** `docs/release/sim_baseline.json`. A keeps the economy switch off until activation readiness; with it off,
   G0 must stay identical. B changes settlement behaviour in shipped play, so B's G0 will differ: B reports the differences with
   conservation evidence; the lead replaces the baseline once per integration, with evidence. C must keep G0 identical.
6. **Long runs** go to GitHub Actions (`long-sims.yml`): the container is reclaimed while idle.

## Sequencing

A and C are independent. B is independent of A (separate economy layer); if B finds it needs a village-side transaction, it asks the
lead. Integration order when ready: whichever finishes first, after its targeted suites and an Actions G0; the lead merges into
`wip/expansion20`, re-runs only the affected suites and one G0. Living Economy activation happens only when every X20-RESUME readiness
condition holds (no second buying path, conservation, save/load and replay, migration, long-run calibration, dependencies, no critical
defect), recorded with commit, evidence and configuration.
