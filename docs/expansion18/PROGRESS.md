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
| Owner Q18-9 applied: levels never gate; their only effects are data-driven pay and output factors (all 1.0 until Q18-11) | Q18-9 | `industries.gd` (`pay_factor`, `output_factor`, `industry_of`), `ledger.gd` (`tick`), data `effects` | `regional_test.gd` `test_levels_scale_never_gate` |
| Owner Q18-10 applied: any party buys (traders, households, villagers, the manor) from its own purse; the buyer fetches the goods itself or pays a willing carter, as a separate matched transfer; nothing delivered free; CON-01 offer shape | Q18-10 | `report.gd` (`parties`), `ledger.gd`, `regional.gd`, `routes.gd` | `regional_test.gd` `test_buyers_and_carriage`, `test_competition`; `settlement_test.gd` (parties partition the village's purses and goods once) |
| Caravan subsidy replacement plan and shadow harness (live caravan unchanged) | s.7, CARAVAN-TMP | `game/tests/caravan_compare.gd`, `game/tests/fixtures/x18_regions.json`, `CARAVAN_REPLACEMENT.md` | `caravan_compare.gd` (10 and 30 days, seed 1) |

## Features implemented provisionally

- **Mining capability** comes only through `MiningCapabilityAdapter` (fixture / live / none), mapped to MIN-D's real
  interface as read on `origin/wip/b17-mind` b0506db (`World.discovery.evaluate/level/history/manor_finds`,
  `World.underground.portals`, `World._quarry_sources`, `villagers_reach`, `level_of`) and tested against a fake World with
  those members. Live on this branch (no Build 17 code): level 0, source `unavailable`.
- **The village's own ore** (`local_supply`) counts against its regional ore demand (MIN-D's reachable seams; on this
  branch the Build 16 seams) when a living adult has a pickaxe to hand; the mining level does not decide it (Q18-9,
  corrected 2026-10-21: an earlier version required level 1), it only scales it through the output factor (1.0).
- **Thresholds and first industries** in `settlement_industries.json` (agent proposals; Q18-2).
- **Market parameters** (`reserve_days` 6, `scarcity_premium` 1.0, `cash_floor` 20, `preferred_margin_pct` 10) and
  **transport** (carrier 12 units, handcart 60, terrain factors).
- **The village's parties** (Q18-10): traders' demand is the live `NPCBrain.wants`; households' demand is their share of
  the village's measured food use; the manor and villagers of no household have no demand rule yet; nobody is offered as
  a carter in the live shadow (Q18-12).
- **Carters** exist only as test fixtures (`carts_for_hire`); their fee is `helper_wage` for the round trip over a load.
- **Pay and output factors** all 1.0 (Q18-11).
- **CON-01 mapping** (`RegionalMarket.to_contract_offer`) is a shape only; `execute` stands in for CON-01 delivery.
- **Save section** `x18_settlements` (`mml-settlements/0`), attached/extracted from the save dictionary; not yet wired
  into `World.to_dict/load_dict`; no `SAVE_VERSION` bump.
- **Region fixtures** (three off-map settlements, closed purses) for measurement only (Q18-3, Q18-4).

## Dependencies awaiting Build 17

| Dependency | Build 17 item | Effect here |
|---|---|---|
| Mining capability levels 1-4, hidden deposits | MIN-D (`wip/b17-mind` b0506db, to be merged into `wip/build17`) | adapter mapped to its interface (fake-World tests); mining level is 0 live on this branch until the reconciliation; smithing 2's "mining 1 or iron bars" alternative uses it |
| Discovery records with provenance | MIN-C | `records` needs (none used by non-mining industries yet) |
| Underground portals | MIN-F / OD-29 | `portal` needs (mining 4 is MIN-D's) |
| Procurement contracts | CON-01 (`contracts.gd`, goods only; parties "player", "npc:<id>", "manor") | purchases become CON-01 contracts; `to_contract_offer` gives the shape, `execute` stands in; households and off-map parties need references (Q18-13); carriage needs service terms (Q18-12) |
| Quarry chain, stone after ore | MIN-B | stone imports in the caravan (`_caravan_stone`) become regional supply or local quarrying |
| Rules moved into `core/` | DVW-A12 (OD-28) | pay and output factors apply to the wages and outputs those rules compute (never gates, Q18-9) |
| Save versions | Build 17's last `SAVE_VERSION` (17 on `wip/build17`) | the provisional section is versioned from there |
| `census.gd` holders | any new Build 17 holders (contract reserves, underground stores) | must be added to `SettlementHoldings.holders` at reconciliation |

## Known integration risks

1. **Census move.** Build 17 may add holders to `tests/census.gd` (it has not as of `origin/wip/build17` read on
   2026-10-21); a merge would then put them in the wrong file. Reconcile by moving them into `SettlementHoldings`.
2. **Two capability files and loops until the reconciliation.** MIN-D created `game/data/capabilities.json` and
   `Discovery.evaluate`. Resolved by plan (DESIGN.md section 8): the vocabulary is already aligned and tested
   (`test_min_d_schema`); at the reconciliation the non-mining industries move into `capabilities.json` and
   `Discovery.evaluate` calls the one evaluator. Until then mining is only consumed, never derived here. Remaining
   incompatibilities: MIN-D's `need_holds` reads the World per need while this branch reads a facts snapshot (folded in
   step 4); MIN-D keeps its own history (this branch's `record` and save key are to be dropped, step 6).
3. **The only coin faucet.** Replacing the 30-coin allowance changes the village's money supply. With every party
   buying (Q18-10) the 30-day shadow turns the village from +1986 net (caravan, 486 coins created) to -948 net (genuine
   trade, none created; households buy grain from Riverford). Under WDR-022 a legitimate outcome, and the largest
   behaviour change of Build 18 (CARAVAN_REPLACEMENT.md).
3a. **MIN-D's level gates.** The lead removed them on Build 17 for Q18-9; at the reconciliation check that no gate came
   back (this branch's `test_levels_scale_never_gate` covers only the settlement model).
4. **Newcomer succession rides the caravan** (`succession_caravan`); it must be decoupled before the caravan can fail
   to come.
5. **Ore, coal, stone imports** become demand- and supply-dependent. Fixed in part: the village snapshot counts its own
   reachable seams (`local_supply`) against ore demand. Still open: daily extraction
   rate (how fast miners can dig it) is not modelled, only what is left; seams opened from finds count once MIN-D is in.
6. **EQ-21/EQ-22 producer purchases** (`caravan_line_need`) must move into the regional model, not be duplicated.
7. **Living Economy overlap** (EXP-D merchants and regional links): keep one merchant model.
8. **Performance.** Facts and report walk every holder; fine daily on desktop (not measured on Android).

## Outstanding owner decisions

Decided 2026-10-21 (`docs/directives/2026-10-21_expansion18_decisions_q18_9_q18_10.md`) and applied here: **Q18-9**
(levels affect pay and output only, never a gate) and **Q18-10** (anyone may buy; the buyer fetches or pays a willing
carter; nothing free, nothing created).

Q18-11, Q18-12 and Q18-13 are in the register on staging as open owner questions.

Open: Q18-1 (skills for farming, carpentry, masonry, tanning), Q18-2 (thresholds, first industries), Q18-3 (closed purse
or explicit regional income), Q18-4 (number and character of off-map regions), Q18-5 (barter and credit), Q18-6 (may
abstract regions meet "two settlements develop different profiles"), Q18-7 (migration out), Q18-8 (SET-E stays 20+), as
worded in the engineering plan, section 5. New:

- **Q18-11:** What pay factor and output factor should each capability level give, and for which industries (mining
  only first, or every industry in the schema)? Until answered every factor is 1.0 (no effect).
- **Q18-12:** May a party hire a willing villager or carter to haul goods between settlements, and on what terms (a day
  wage as `helper_wage`, a fee per load, or negotiated like a CON-01 contract with service terms)? CON-01 is goods only
  and `Construction.hire` carries only to one's own building site. Overlaps OD-LE-03 and MIN-D's open question 1.
- **Q18-13:** CON-01 knows "player", "npc:<id>" and "manor"; should it gain household and off-map party references, or
  should a household buy through a named member and a region through a named merchant?

## Integration-readiness estimate (from tests actually run)

- Run on this branch (latest round, private `XDG_DATA_HOME`): `settlement_test` (66 checks), `regional_test` (67 checks),
  `caravan_compare` 10 days (20 checks), all passing; in the round before, `caravan_compare` 30 days seed 1 (50 checks); the regression set `run_tests` (3535),
  `world_test` (200), `start_test` (499 steps), `parity_test` (55), `conservation_test` (8), `business_test` (160) passing;
  `python3 -m unittest discover -s tests` passing (this round); `economy_sim --days 30 --seed 1` (`LEAKS: currency 0; items {}`) run in the
  first round, when the one live-code touch (the census move) was made; nothing in live code changed since.
- Estimate: the model layer (capability, report, regional market, routes, rules) is tested in isolation and ready for
  reconciliation review. Live integration (save wiring, dawn recompute, replacing the caravan, contracts, MIN-D) has not
  started and is untested. Roughly **a third of SET-A..D by scope**: SET-A schema and SET-B model largely prototyped;
  SET-C's market prototyped in shadow with the owner's Q18-9/Q18-10 rules; SET-D (growth, migration, housing) not started:
  it needs population and housing change driven by the regional economy, which depends on live trade (SET-C integration,
  CON-01, Q18-12/13) and, for mining towns, MIN-D's live adoption, so it is held until those settle.
