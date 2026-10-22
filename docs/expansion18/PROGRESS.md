# Expansion 18 prospective development: progress

Directive: `docs/directives/2026-10-21_parallel_prospective_development_18_19.md` (PROS-01, PROS-18). Reporting fields as
the directive lists them. Updated 2026-10-21. Design: `DESIGN.md`; caravan plan: `CARAVAN_REPLACEMENT.md`.

**Nothing here is integrated gameplay.** The code is isolated on `wip/expansion18-preparation`, runs only in its own
tests and the shadow harness, and waits for the reconciliation gate (after Build 17 is complete).

## Branch and latest pushed commit

- Branch: `wip/expansion18-preparation`, from `b721616` (staging: the released Build 16 plus records).
- **Build 17 baseline: `cd7439c`** (`origin/wip/build17`, merged one way on 2026-10-21 under SYNC-17,
  `docs/directives/2026-10-21_sync_expansions_with_build17.md`; the last pre-sync commit is `842ca59`, and the lead's
  safety snapshot `wip/expansion18-snapshot` `9cf9fe1`). Nothing of this branch goes into Build 17.
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
| Q18-11 framework (structure approved): levels 0-10, separate PayMultiplier and OutputMultiplier per industry from data profiles; ACTIVE profile `approved` since X18-CAPNUM (below); `neutral` (1.0) the baseline; UNAPPROVED candidates selectable only by tests and analysis | Q18-11 | `industries.gd`, `settlement_industries.json` `effects` | `capability_test.gd` |
| Output safeguard: output multiplier = less time per unit; every unit takes its full recipe inputs, its seam or its crop (mining, smithing, carpentry, farming fixtures on real recipes and work times; abstract settlements only where a finite source exists) | Q18-11 safeguards | `productivity.gd`, `ledger.gd` | `capability_test.gd`, `regional_test.gd` |
| No double counting: settlement = place-specific, Skills = portable; gains add once over the base; the settlement never touches the Skills' quantity effects | Q18-11, research (e) | `productivity.gd` | `capability_test.gd` |
| Curve analysis (three shapes, uniform and industry-differentiated magnitudes) and Q18-11B options | Q18-11A/B | `CAPABILITY_CURVES.md`; harness `--profiles` | `caravan_compare.gd` 30 days, 290 integrity checks |
| Deficit decomposition (outlets, local distribution, raw-material shortage, unmet demand, partners, prices, transport, money) and the local-market sensitivity | directive s.8 | `DEFICIT_ANALYSIS.md`; harness `--local`, `RegionalMarket.plan(local)` | `caravan_compare.gd` |
| Caravan subsidy replacement plan and shadow harness (live caravan unchanged) | s.7, CARAVAN-TMP | `game/tests/caravan_compare.gd`, `game/tests/fixtures/x18_regions.json`, `CARAVAN_REPLACEMENT.md` | `caravan_compare.gd` (10 and 30 days, seed 1) |

### Round 4 (2026-10-21): X18-SIM, X18-Q12 (booths, routes, postage window), X18-Q13 (signatures)

| Feature | Owner source | Code | Tests (run on this branch) |
|---|---|---|---|
| Capability analysis switch on the real production systems (work time and the manor's productive wages; off in the game, fingerprint-identical) and a comparative simulation grid | X18-SIM | `capability_hook.gd`, X18 HOOKs in `npc_brain.gd`, `construction.gd`, `manor_work.gd`; `tests/capability_metrics.gd`, `economy_sim.gd` flags | `capability_test` 49; 59 economy_sim runs, all LEAKS 0; `CAPABILITY_SIMULATIONS.md` |
| Courier booths (existing stalls, job rule), regular routes (flat fee a load at the booth), special deliveries (negotiated, fee from the work), known recipients only (acquaintances, businesses traded with: `Relations.trades` via one World.trade hook), locations from records, physical journeys, payment collection, deposits, refusals, interruptions | X18-Q12, X18-Q12-BOOTH, X18-Q12-POST | `couriers.gd`, `couriers.json`, `relations.gd`, `world.gd` (hook) | `courier_test` 44 |
| The postage-style courier window (UI only collects choices; core decides) | X18-Q12-POST | `ui/courier_window.gd`, `tests/courier_window_shot.gd` | rendered and looked at (xvfb, opengl3): form with service, item, quantity, known recipient (a business by prior trade), delivery place, collect-payment, payment kind and amount, proceeds, courier, offer; the review shows the instruction and fee at the top |
| Formal agreements: small unsigned; formal and ownership need signatures; face to face or a notary courier carrying the document; no remote signing; completed, rejected, interrupted | X18-Q13 | `formal_contracts.gd` | `contract_sign_test` 20 |

Not done in round 4 (stated plainly): the 90-day runs, the `revised_bounded` model's runs and the regional harness by
profile, held until after the SYNC-17 Build 17 merge so results stay on one baseline (CAPABILITY_SIMULATIONS.md s.4).

### SYNC-17 (2026-10-21): Build 17 `cd7439c` merged one way; the evaluator follows Build 17's rule

| What | Resolution |
|---|---|
| Conflicts | `tests/census.gd` (kept the delegation; Build 17's new holders, contract escrow goods, open-pit spoil and contracts' reserved coins, moved into `SettlementHoldings`); `manor_work.gd` and `npc_brain.gd` (Build 17's mining plan, `seam_steps` and `mine_works.cart_fetch_plan`, taken whole; the X18 mining HOOK moved into `NPCBrain.seam_steps`; Build 17's contract felling in `contracts.gd` gained the same off-in-game chop HOOK); `economy_sim.gd` (Build 17's `reached` and FATAL kept; the CAPABILITY line reports on `reached` days); `tests.yml` (Build 17's suites, then this branch's). Register and ledger files are Build 17's, untouched. |
| PROS-18 correction (MIN-SKILLCAP, MIN-D2) | Practitioners by Skills level and tool kind, never by title (`jobs` only for farming, where only farmers work the manor's fields); a shared household tool serves one member; the resident player counts by the villagers' rule. Live village: `Discovery.practitioners`/`tool_stock` themselves; snapshots: the same rule (`practitioner_count`). `settlement_industries.json` rewritten to skill+tool needs; `facts.gd` reads `Discovery.residents()`; the mining adapter's "can anyone dig" is `Discovery.practitioners` (a pickaxe in the manor's yard makes nobody a miner). No new eligibility rule. |
| Mining live | The adapter now reads the live MIN-D (`source "min-d"`); a worked-out village still has quarry stone (Build 17's host rock and boulders), never ore. |
| Fixture | `tests/fixtures/x18_min_d_mining.json` refreshed from `cd7439c`'s `capabilities.json` (skill+tool, shovels for excavators). |
| Stoneworking | X18-STONECUT, STONE-02..06 documented only (below); Build 17's `dress_stone` unchanged. |

### X18-CAPNUM (2026-10-22): the approved capability modifier profile (owner Q18-11A closed)

| What | Where | Tests |
|---|---|---|
| `approved` profile, ACTIVE: mining, forestry +5%/+2% front-loaded; trade, tanning +10%/+4% intermediate; carpentry, smithing +15%/+6% owner's shape; farming F1 +10% work rate/+4% pay intermediate; `revised_bounded` marked SUPERSEDED, the others UNAPPROVED | `settlement_industries.json` `effects` | `capability_test` (values at L10, shapes, the F1 table 0-10) |
| Farming is a work rate only (`yield_fixed`): abstract settlements never grow more crop | `industries.gd` `yield_fixed`, `ledger.gd` | `capability_test` `test_capnum_ledger_yield`, `regional_test` |
| Farming hook sites (off in the game): manor field cutting and sowing (already), household plots' tilling, sowing, cutting, pen feeding and collecting (milk, eggs, wool), the player's tilling, sowing, harvesting seconds; the harvest hand's wage | `npc_brain.gd`, `farm_plots.gd`, `farming.gd`, `quests.gd` (X18 HOOK) | `capability_test` `test_capnum_farm_sites`, `test_capnum_farm_pay` |
| Durations and pay at levels 0, 5, 10 in every industry; determinism (same seed twice, and against the hook off) | `capability_hook.gd` | `capability_test` `test_capnum_durations`, `test_capnum_determinism` |
| Live hook decision: stays OFF in the game until X18-CAPCOMP (DESIGN.md section 9a) | `capability_hook.gd` | economy_sim fingerprint unchanged with the hook off |

### Owner D1 (2026-10-22): starting experience, implemented

| What | Where | Tests |
|---|---|---|
| Once, for a new world and a save with no experience section: days = cap x recorded skill level / 10 per industry (only with xp in the skill); farming from PAR-01A's working history for farmers; the player none; marked `seeded`, kept in `start`; never overwrites; format `mml-x18-experience/1` (0 read, never seeded over) | `settlement/experience.gd` (`seed_once`, `start_days`, `farming_start_days`), `world.gd` (setup after PAR-01A; load when the section is absent) | `experience_test` 61 (formula per industry, the seed-1 smiths 8 and 6, farming from PAR-01A, once only, no overwrite, older-save migration, format 0, determinism, round-trip) |

D1 is no longer open below; D2 is in its final form in `DECISIONS_PENDING.md`.

### Review against the register (2026-10-22, owner directive `2026-10-22_expansions_18_19_20_directive.md`)

Register on staging read for PROS-18 and its children, X18-*, Q18-*, X18-STONECUT (STONE-02..06 appear only in its
notes), X18-CAPCOMP, X18-CAPNUM, CAP-TOOLHOLDER. Pending decisions with options: `DECISIONS_PENDING.md`.

**(a) Implemented and verified (on this branch, in the prospective modules; the live hook off):**
- Q18-9 (levels never gate), Q18-10 (any party buys; fetch or paid carter): `regional_test`, `settlement_test`.
- Q18-11 structure and Q18-11A numbers: X18-CAPNUM, the `approved` profile and its hook sites (`capability_test`).
- Q18-11B and X18-CAPCOMP part 1: experience by hours, caps, straight-line individual level, hours-weighted workforce
  report, experience kept across industries and on departure dropped; workforce and effective levels kept apart
  (`experience_test`); per-worker hook path prepared, not enabled.
- PROS-18 components: capability model, holdings and report, regional market, routes, competition and cooperation,
  caravan replacement plan (shadow harness), conservation and determinism tests; SYNC-17 to Build 17 `cd7439c`.
- X18-Q12, X18-Q12-BOOTH, X18-Q12-POST, X18-Q13: rules, fees, known recipients, physical journeys, signatures and the
  postage window implemented and tested in the prospective module (`courier_test` 44, `contract_sign_test` 20; the
  window rendered and looked at). **Not wired into the live game loop** (a reconciliation step; live use also needs
  Q18-14..16 and the fee coefficients).
- X18-SIM: 59 comparative runs and the report (`CAPABILITY_SIMULATIONS.md`); the owner has since approved the numbers.
  The deferred 90-day and regional-by-profile runs are not needed any more: the owner's 2026-10-22 directives forbid new
  long campaigns, and the approved profile is verified by focused tests and two 30-day ledger runs.

**(b) Approved, not yet implemented, needing no unapproved value (done in this round):**
- Compatibility of experience tracking and the per-worker path with mining, forestry, farming, production and CON-01/02:
  tested (`experience_test` `test_production_compat`, `test_contract_compat`; `capability_test` farm sites).
- Workforce experience structurally separate from the facility-limited effective level, no caps invented
  (`WorkExperience.effective_level`, `facility_cap`, empty `facilities.caps`; `test_effective_kept_apart`).
- The industry workforce report in the settlement report (`SettlementReport.workforce`; `test_report`).
- Nothing else approved is implementable without an open value: SET-A..E as phases are covered in part by PROS-18's
  prospective modules; their live parts wait for the decisions below.

**(c) Blocked on an owner decision:**
- Switching the per-worker modifiers on (X18-CAPCOMP, X18-CAPNUM live): D1 starting experience, D2 facility limits,
  D5 level rounding, D6 wages at posting (`DECISIONS_PENDING.md`); D3 thresholds; D4 unattributed activities (trade's
  modifiers cannot act until D4 gives trade hours).
- X18-STONECUT and STONE-02..06: the Stoneworking starting levels and migration credit, dressing efficiency values,
  chisel wear and the chisel recipe.
- SET-C live trade and SET-D growth: Q18-1..8. Live courier booths: Q18-14, Q18-15, Q18-16, the fee coefficients.
- Mining's 0-10 mapping of MIN-D's stages: reconciliation item.
- CAP-TOOLHOLDER: record only, by the owner's instruction (review at reconciliation or if it causes a problem).

### X18-CAPCOMP part 1 (2026-10-22): workforce experience (owner-approved components only)

| What | Where | Tests |
|---|---|---|
| Experience per person and industry from hours worked (1 day per 8 hours), never decaying, leaving with the person; caps 12/18/24; straight-line individual level; hours-weighted workforce level of the last season (report only; "no active workers") | `settlement/experience.gd`, `settlement_industries.json` `experience`; `World` (`_note_work`, `note_player_work`, dawn prune, optional save key `x18_experience`); `main.gd` (player actions) | `experience_test` 31 |
| Per-worker hook path prepared, not enabled (each worker's own level; the Q18-11B effective level is per worker) | `capability_hook.gd`, every hook site passes the worker | `experience_test` `test_per_worker_path` |
| Not implemented (not approved): facility caps, starting experience (tracking starts empty), thresholds | DESIGN.md section 9b | — |

## Features implemented provisionally

- **Mining capability** comes only through `MiningCapabilityAdapter` (fixture / live / none), reading MIN-D's interface
  (`World.discovery.evaluate/level/history/manor_finds/practitioners`, `World.underground.portals`,
  `World._quarry_sources`, `villagers_reach`, `level_of`). Since SYNC-17 the live game has MIN-D: source `min-d`, the level
  `Discovery.evaluate("mining")` gives (tested); a fake World still tests the edges.
- **The village's own ore** (`local_supply`) counts against its regional ore demand (MIN-D's reachable seams) when a
  resident can dig by Build 17's rule (Mining 1 and a pickaxe of their own or their household's); the mining level does
  not decide it (Q18-9), it only scales it through the output factor (1.0).
- **Thresholds and first industries** in `settlement_industries.json` (agent proposals; Q18-2).
- **Market parameters** (`reserve_days` 6, `scarcity_premium` 1.0, `cash_floor` 20, `preferred_margin_pct` 10) and
  **transport** (carrier 12 units, handcart 60, terrain factors).
- **The village's parties** (Q18-10): traders' demand is the live `NPCBrain.wants`; households' demand is their share of
  the village's measured food use; the manor and villagers of no household have no demand rule yet; nobody is offered as
  a carter in the live shadow (Q18-12).
- **Carters** exist only as test fixtures (`carts_for_hire`); their fee is `helper_wage` for the round trip over a load.
- **Pay and output multipliers**: the active profile is the owner's `approved` one (X18-CAPNUM); the live hook stays off
  in the game until X18-CAPCOMP gives a live 0-10 effective level; the candidate profiles' numbers are analysis only; mining's multipliers stay 1.0 until MIN-D's 1-4 stages are mapped to 0-10 (reconciliation item, DESIGN.md
  section 8 step 8).
- **Region fixtures** now carry capabilities, finite reserves and Eastmarch's smelting by the real recipe (analysis).
- **CON-01 mapping** (`RegionalMarket.to_contract_offer`) is a shape only; `execute` stands in for CON-01 delivery.
- **Save section** `x18_settlements` (`mml-settlements/0`), attached/extracted from the save dictionary; not yet wired
  into `World.to_dict/load_dict`; no `SAVE_VERSION` bump.
- **Region fixtures** (three off-map settlements, closed purses) for measurement only (Q18-3, Q18-4).

## Dependencies awaiting Build 17

| Dependency | Build 17 item | Effect here |
|---|---|---|
| Mining capability levels 1-4, hidden deposits | MIN-D (in `wip/build17`, merged here at `cd7439c`) | the adapter reads it live; smithing 2's "mining 1 or iron bars" alternative uses it; the one-evaluator plan's step 4 is partly done (practitioners and tool stock delegate to Discovery) |
| Discovery records with provenance | MIN-C | `records` needs (none used by non-mining industries yet) |
| Underground portals | MIN-F / OD-29 | `portal` needs (mining 4 is MIN-D's) |
| Procurement contracts | CON-01 (`contracts.gd`, goods only; parties "player", "npc:<id>", "manor") | purchases become CON-01 contracts; `to_contract_offer` gives the shape, `execute` stands in; households and off-map parties need references (Q18-13); carriage needs service terms (Q18-12) |
| Quarry chain, stone after ore | MIN-B | stone imports in the caravan (`_caravan_stone`) become regional supply or local quarrying |
| Rules moved into `core/` | DVW-A12 (OD-28) | pay and output factors apply to the wages and outputs those rules compute (never gates, Q18-9) |
| Save versions | Build 17's last `SAVE_VERSION` (17 on `wip/build17`) | the provisional section is versioned from there |
| `census.gd` holders | Build 17's holders | done at SYNC-17 for `cd7439c` (contract escrow, open-pit spoil, contracts' reserved coins); any later holder must be added to `SettlementHoldings.holders` at the next sync |

## Known integration risks

1. **Census move.** Build 17 added holders to `tests/census.gd` by `cd7439c` (contracts, pits); moved into
   `SettlementHoldings` at SYNC-17. A later Build 17 holder needs the same move at the next sync.
1a. **Tool holders count as practitioners (Build 17's rule, adopted as is).** Anyone with the skill level asked (every
   Skills level is at least 1) and a tool of the kind in their pack or household store counts, whatever their job. In the
   starting village (seed 1) the only hammer holders are the two smiths (smithing 8 and 6), so the village reads
   smithing 3 (master smithy) and falls to 0 when they die (tested). By the same rule a villager carrying a tool for sale
   would count for a level-1 need; that is Build 17's MIN-SKILLCAP rule, followed here without change. If it should
   exclude goods held for sale, the change belongs in `Discovery.practitioner` (Build 17), not in a second rule here.
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

Q18-11 (master directive 2026-10-21): the STRUCTURE is approved and implemented (levels 0-10, separate pay and output
multipliers, diminishing returns, industries may differ, base values from the existing systems). Open:

- **Q18-11A (numbers): CLOSED 2026-10-22** (Option A for six industries, farming F1); implemented as X18-CAPNUM (above).
- **Q18-11B (composition): ANSWERED 2026-10-22, option 2** (people's experience capped by facilities; workforce and
  effective levels per industry; shortages never erase experience; modifiers use the effective level; X18-CAPCOMP). Open
  for owner approval: the experience measure, facility caps, tenure rules and thresholds. Not implemented.
- **Q18-12** and **Q18-13** were decided by the owner on 2026-10-21 and are implemented in round 4 (above). New questions
  from that work: **Q18-14** which skill gives a courier legal standing to notarise (no "law" skill exists; provisional
  trading 5); **Q18-15** which businesses are "major" for their own booth (provisional: the market traders); **Q18-16**
  where the village booth stands when no market stall is free (provisional: a stall built by the STALL rules); the fee
  coefficients and the small-agreement threshold (UNAPPROVED defaults in `couriers.json`).
- New from X18-CAPNUM (agent questions, nothing chosen): **whole-coin rounding** (the real 6-coin harvest wage x 1.04
  = 6.24 rounds back to 6, so a +4% pay modifier never shows on it; `CapabilityHook.pay` rounds to the nearest coin as in
  X18-SIM; options: keep, round up, or carry fractions); **which farm tasks count beyond the owner's list** (slaughter,
  clearing ground, fencing keep their times); **the F1 table at level 5** (7.8% shown, 7.853% from the approved
  intermediate shape; implemented as the shape).
- Stoneworking (owner FYI, 2026-10-21): X18-STONECUT (a professional stonecutter trade), STONE-02 (villagers dressing their
  own stone), STONE-03 (repair materials by kind of work), STONE-04 (dressing efficiency by skill, waste conserved),
  STONE-05 (a dedicated Stoneworking skill), STONE-06 (an iron chisel by smiths, used with the mallet) are Expansion 18
  requirements, documented only, not implemented. Integration needs: Build 17's STONE-01 `dress_stone` recipe and
  mallet stay as they are; the stonecutter's capability goes into the one evaluator as a new industry (masonry) with
  Stoneworking practitioners and the chisel as a `tool`; its output multiplier must act on dressing time only (waste
  conserved, STONE-04); masonry settles the masonry part of Q18-1. Open owner values: starting levels and migration
  credit, efficiency values, chisel wear, chisel recipe.
- Reconciliation item (not an owner question yet): how MIN-D's mining stages 1-4 map to the 0-10 scale.

Earlier open questions: Q18-1 (skills for farming, carpentry, masonry, tanning), Q18-2 (thresholds, first industries),
Q18-3 (closed purse or explicit regional income), Q18-4 (number and character of off-map regions), Q18-5 (barter and
credit), Q18-6 (may abstract regions meet "two settlements develop different profiles"), Q18-7 (migration out), Q18-8
(SET-E stays 20+), as worded in the engineering plan, section 5.

## Integration-readiness estimate (from tests actually run)

- **X18-CAPNUM (2026-10-22, on `cd7439c` + this branch, private `XDG_DATA_HOME`):** `capability_test` 72, `regional_test`
  71, `settlement_test` 83; Build 17's `farming_test` 217, `farm_plots_test` 104, `herd_test` 19, `world_test` 339,
  `conservation_test` 8, `run_tests` 3544: all passing. `economy_sim --days 30 --seed 1`: hook off, fingerprint
  `1c755f53d12c72bd470b7913fb5e52a6`, identical to the SYNC-17 run before the change, `LEAKS: currency 0; items {}`,
  wheat made 3600; approved profile forced at level 10 (`--capability 10 --cap-profile approved`): reached day 30, no
  FATAL, `LEAKS: currency 0; items {}; deposits []; animals {}`, wheat made 3600 (unchanged: the crop is the land's),
  fingerprint `e9894d13...` (differs, as faster work must). Both are 30-day ledger checks, not the economic campaign.

- **SYNC-17 (on the merged `cd7439c` baseline, private `XDG_DATA_HOME`, one Godot at a time, after `--import`):**
  this branch's `settlement_test` 83, `capability_test` 50 (incl. "the hook is off in the game: every work time and
  wage is exactly the existing one"), `regional_test` 71, `courier_test` 44, `contract_sign_test` 20; Build 17's
  `parity_mining_test` 62, `equip_test` 51, `discovery_test` 65, `job_board_test` 28, `contracts_test` 138,
  `services_test` 51, `quarry_test` 39, `wiki_test` (all passed), `conservation_test` 8: all passing, 0 failures.
  `economy_sim --days 30 --seed 1` (no capability flags): reached day 30, no FATAL, `LEAKS: currency 0; items {};
  deposits []; animals {}`, alive 110, no starvation, 308 s. `python3 -m unittest discover -s tests` 105 OK;
  `check_requirements` 0 problems, `check_interactions` 0, `check_resources` 0.
- The X18-SIM model runs (59, `CAPABILITY_SIMULATIONS.md`) were on the Build 16 baseline; they and the deferred runs
  (90-day, `revised_bounded`, regional harness by profile) are to be redone on this baseline, under SIM-01 and SIM-02.

- Run on this branch (latest round, private `XDG_DATA_HOME`): `capability_test` (42 checks), `settlement_test` (66),
  `regional_test` (71), `caravan_compare` 10 days (110 checks, six shadow sets) and 30 days seed 1 (290 checks), all
  passing. Directive section 10 coverage: items 1 (levels 0-10), 2 (never blocking), 4 (pay vs output), 5 (per
  industry), 6 (conservation incl. raw materials), 7 (inputs match production), 8 (no double counting), 11
  (determinism) in `capability_test`; 3 (level-0 ore) in `settlement_test`; 9 (all participant types) and 10
  (self-collection, paid carter behind fixtures, Q18-12) in `regional_test` and `settlement_test`; 12 (save/load) and 13
  (one evaluator) wait for the reconciliation. Earlier rounds: the regression set `run_tests` (3535),
  `world_test` (200), `start_test` (499 steps), `parity_test` (55), `conservation_test` (8), `business_test` (160) passing;
  `python3 -m unittest discover -s tests` passing (this round); `economy_sim --days 30 --seed 1` (`LEAKS: currency 0; items {}`) run in the
  first round, when the one live-code touch (the census move) was made; nothing in live code changed since.
- Estimate: the model layer (capability, report, regional market, routes, rules) is tested in isolation and ready for
  reconciliation review. Live integration (save wiring, dawn recompute, replacing the caravan, contracts, MIN-D) has not
  started and is untested. Roughly **a third of SET-A..D by scope**: SET-A schema and SET-B model largely prototyped;
  SET-C's market prototyped in shadow with the owner's Q18-9/Q18-10 rules; SET-D (growth, migration, housing) not started:
  it needs population and housing change driven by the regional economy, which depends on live trade (SET-C integration,
  CON-01, Q18-12/13) and, for mining towns, MIN-D's live adoption, so it is held until those settle.

## 2026-10-23: the capability hook is switched on (branch `wip/b18-capability`)

The owner answered D2 to D9 (and FARM-CROP-SEED) on 2026-10-23. Implemented: effective level = experience (wear cap seam);
bands novice/journeyman/master; the D4 attribution table; D5 interpolation; D6 wages fixed at acceptance (manor mend and
quarry jobs, the harvest hand); D7 crop shares by minutes x work rate; seed split by work; D8 and D9 unchanged. The hook
reads each worker's own level (`CapabilityHook.bind` from the World). Register ids: X18-D2..D9, X18-CAPCOMP, X18-CAPNUM.
Interaction entries INT-216 to INT-219; decisions in `docs/DECISIONS.md` (2026-10-23, "X18 capability hook ON").
