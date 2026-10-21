# Expansion 18 prospective development: progress

Directive: `docs/directives/2026-10-21_parallel_prospective_development_18_19.md` (PROS-01, PROS-18). Reporting fields as
the directive lists them. Updated 2026-10-21. Design: `DESIGN.md`; caravan plan: `CARAVAN_REPLACEMENT.md`.

**Nothing here is integrated gameplay.** The code is isolated on `wip/expansion18-preparation`, runs only in its own
tests and the shadow harness, and waits for the reconciliation gate (after Build 17 is complete).

## Branch and latest pushed commit

- Branch: `wip/expansion18-preparation`, from `b721616` (staging: the released Build 16 plus records; no Build 17 code).
- Latest pushed commit: see `git log origin/wip/expansion18-preparation -1` (the commit carrying this file; the hash is
  reported to the lead with each push).

## Features implemented and tested

| Feature | Spec | Code | Tests (run on this branch) |
|---|---|---|---|
| Settlement capability per industry, derived from people, skills, tools, stock, structures, transport; falls when a need stops holding; unmet needs named | s.4, s.9, s.11 b.3 | `industries.gd`, `facts.gd`, `game/data/settlement_industries.json` | `settlement_test.gd` |
| Specialization and leaders across settlements, independent of population | s.3, s.11 b.2 | `industries.gd` | `settlement_test.gd` |
| Level history (rise, regression, day) | s.4 | `industries.gd` | `settlement_test.gd` |
| Settlement inventories and economic report from the existing holders, read-only (goods by group, coins by holder = `World.total_coins`, outside money, food days, capabilities) | s.8, s.11 | `holdings.gd`, `report.gd` | `settlement_test.gd` (incl. "report changes nothing in the World") |
| Regional supply and demand over N settlements; purchasing power; unmet need with reasons | s.5, s.6, s.11 b.4, b.6 | `regional.gd`, `ledger.gd` | `regional_test.gd` |
| Trade routes and transport (terrain grid, abstract routes, haulage as wages, cart capacity) | s.5 logistics, s.8 | `routes.gd` | `regional_test.gd` |
| Competition (cheapest delivered wins, lost sales, capacity spill) and cooperation (preferred partner within a margin, no discount or gift) | s.6 row 5, s.7 | `regional.gd` | `regional_test.gd` |
| Conservation, genuine trade (every transfer matched), settlement independence, determinism | s.5 accounting, s.9, s.11 b.5 | all | `regional_test.gd`, `settlement_test.gd`, `caravan_compare.gd` integrity checks |
| Caravan subsidy replacement plan and shadow harness (live caravan unchanged) | s.7, CARAVAN-TMP | `game/tests/caravan_compare.gd`, `game/tests/fixtures/x18_regions.json`, `CARAVAN_REPLACEMENT.md` | `caravan_compare.gd` (10 and 30 days, seed 1) |

## Features implemented provisionally

- **Mining capability** comes only through `MiningCapabilityAdapter` (fixture / live duck-typed / none). Live on this
  branch: level 0, source `unavailable`. The live hook names (`World.mining_capability(id)`, `World.mining_levels`,
  `World.mining_portals(id)`, `World.discovery_records(id)`) are guesses until MIN-D lands.
- **Thresholds and first industries** in `settlement_industries.json` (agent proposals; Q18-2).
- **Market parameters** (`reserve_days` 6, `scarcity_premium` 1.0, `cash_floor` 20, `preferred_margin_pct` 10) and
  **transport** (carrier 12 units, handcart 60, terrain factors).
- **Village snapshot for regional trade**: its traders' coins (market roles only) buy; traders' and producers' goods
  sell; demand from measured daily use (`eaten_`, `used_` stats). Smiths' and households' coins do not buy in the shadow.
- **Save section** `x18_settlements` (`mml-settlements/0`), attached/extracted from the save dictionary; not yet wired
  into `World.to_dict/load_dict`; no `SAVE_VERSION` bump.
- **Region fixtures** (three off-map settlements, closed purses) for measurement only (Q18-3, Q18-4).

## Dependencies awaiting Build 17

| Dependency | Build 17 item | Effect here |
|---|---|---|
| Mining capability levels 1-4, hidden deposits | MIN-D (`wip/b17-mind`, not final) | adapter reads it; mining level is 0 live until then; smithing 2's "mining 1 or iron bars" alternative uses it |
| Discovery records with provenance | MIN-C | `records` needs (none used by non-mining industries yet) |
| Underground portals | MIN-F / OD-29 | `portal` needs (mining 4 is MIN-D's) |
| Procurement contracts | CON-01 (`contracts.gd`) | SET-C orders should become CON-01 contracts between a regional buyer and village sellers; `RegionalMarket.execute` is the stand-in |
| Quarry chain, stone after ore | MIN-B | stone imports in the caravan (`_caravan_stone`) become regional supply or local quarrying |
| Rules moved into `core/` | DVW-A12 (OD-28) | capability gates on recipes and jobs read those rules |
| Save versions | Build 17's last `SAVE_VERSION` (17 on `wip/build17`) | the provisional section is versioned from there |
| `census.gd` holders | any new Build 17 holders (contract reserves, underground stores) | must be added to `SettlementHoldings.holders` at reconciliation |

## Known integration risks

1. **Census move.** Build 17 may add holders to `tests/census.gd` (it has not as of `origin/wip/build17` read on
   2026-10-21); a merge would then put them in the wrong file. Reconcile by moving them into `SettlementHoldings`.
2. **Data file collision.** MIN-D may create `game/data/capabilities.json` with mining levels (the SET-A sketch). This
   branch uses `settlement_industries.json` with mining external; at integration the two must become one file and one
   evaluator (mining's needs evaluated by MIN-D or moved into the generic evaluator; never both).
3. **The only coin faucet.** Replacing the 30-coin allowance changes the village's money supply; the shadow harness
   shows genuine demand from the fixture regions takes a fraction of what the caravan buys (CARAVAN_REPLACEMENT.md).
   Under WDR-022 that is a legitimate outcome, but it is the largest behaviour change of Build 18.
4. **Newcomer succession rides the caravan** (`succession_caravan`); it must be decoupled before the caravan can fail
   to come.
5. **Ore, coal, stone imports** become demand- and supply-dependent; the village snapshot does not yet count the mine's
   own capacity (deposits are MIN-D's), so the shadow overstates import demand for ore.
6. **EQ-21/EQ-22 producer purchases** (`caravan_line_need`) must move into the regional model, not be duplicated.
7. **Living Economy overlap** (EXP-D merchants and regional links): keep one merchant model.
8. **Performance.** Facts and report walk every holder; fine daily on desktop (not measured on Android).

## Outstanding owner decisions

Q18-1 (skills for farming, carpentry, masonry, tanning), Q18-2 (thresholds, first industries), Q18-3 (closed purse or
explicit regional income), Q18-4 (number and character of off-map regions), Q18-5 (barter and credit), Q18-6 (may abstract
regions meet "two settlements develop different profiles"), Q18-7 (migration out), Q18-8 (SET-E stays 20+): as worded in
the engineering plan, section 5. New from this work:

- **Q18-9:** Should a settlement capability level ever *gate* an action (e.g. no toolmaking without smithing 2), or only
  be reported until MIN-D's adoption rules exist? Recommendation: report only in Build 18's first slice; gate only where
  the need is already physical (a forge, a smith) so a gate never blocks what the world could do.
- **Q18-10:** Who in the village buys from the region: the traders only (this branch), or also the manor treasury and
  households? Recommendation: traders and the treasury (public works), households through the market.

## Integration-readiness estimate (from tests actually run)

- Run on this branch: `settlement_test` (45 checks), `regional_test` (52 checks), `caravan_compare` 10 and 30 days seed 1
  (integrity checks pass), and the regression set `run_tests`, `world_test`, `start_test`, `parity_test`,
  `conservation_test`, `business_test`, `python3 -m unittest discover -s tests`, `economy_sim --days 30 --seed 1`
  (`LEAKS: currency 0; items {}`).
- Estimate: the model layer (capability, report, regional market, routes, rules) is tested in isolation and ready for
  reconciliation review. Live integration (save wiring, dawn recompute, replacing the caravan, contracts, MIN-D) has not
  started and is untested. Roughly **a third of SET-A..D by scope**: SET-A schema and SET-B model largely prototyped;
  SET-C's market prototyped in shadow; SET-D (growth, migration, housing) not started.
