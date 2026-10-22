# Close-out audit: SET-A, SET-B, SET-C and WDR-002-C

Branch `wip/b18-closeout` (from `wip/build18` 1daa61f). Audited 2026-10-23 against the source acceptance criteria. The register is
not edited here; this file is the evidence for the lead. Sources: `docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf`
(cited "spec s.N"), `docs/directives/2026-10-21_master_expansion_roadmap.md` (Expansion 18), owner answers Q18-1..Q18-16 (register),
`docs/WORLD_DESIGN_RULES.md` Rule 002. Status: MET, PARTIAL, NOT MET. Open owner decision Q18-11 (final capability percentages) is
not touched; X18-SIM runs separately.

Changes made by this audit: `game/tests/interdependency_test.gd` (new, 22 checks, in `tests.yml`), `test_continuity` added to
`game/tests/settlement_test.gd` (6 checks), one stale sentence corrected in `DESIGN.md` section 2 (carpentry, masonry and tanning have skills).

## SET-A: phase A "Design and ledger" (release evidence: validated register, design docs, explicit assumptions)

| # | Criterion (source) | Evidence | Status |
|---|---|---|---|
| A1 | "Requirements IDs" (s.10 A; s.13 "Register this expansion as a distinct major initiative in the permanent requirements ledger") | SET-A..E, SET-C-SIM/FIVE, REG-*, X18-*, Q18-1..16 in `requirements.json`; `tools/check_requirements.py`: 789 records, 0 problems | MET |
| A2 | "cross-industry skill schema" | `game/data/settlement_industries.json` (`mml-capabilities/1`): industries, levels, need kinds incl. `industry` (cross-industry) and `any`; `SettlementIndustries.validate` refuses cycles and unknown kinds; `settlement_test` `test_data`, `test_min_d_schema`; skills carpentry/masonry/tanning exist (Q18-1) | MET |
| A3 | "save compatibility" (s.10 A; s.11 b.9 "Existing save games ... continue to work; migration is documented") | Settlement and regions state is optional save keys with absent-means-default: `regions` (`regions_test` `test_old_save`: an older save founds the five settlements and its `caravan_purse` becomes the traders' coins, deterministic), `couriers`, `x18_experience` (`experience_test`); `World.SAVE_VERSION` comment documents each; INT-233. Capability levels are derived, never stored, so nothing needs migrating. The provisional section `x18_settlements` (`SettlementSave`) is **not wired** into `World.to_dict/load_dict` (only tested in `settlement_test` `test_save_section`), so non-mining level history is not persisted (see B5) | PARTIAL |
| A4 | "dependency audit" (s.10 A; s.13 "First audit existing economy, professions, caravan code, settlement representation, persistence and simulation harness") | Audit text exists in `DESIGN.md` sections 6 and 10 ("What exists and is reused"), `CARAVAN_REPLACEMENT.md`, `RESEARCH_DIGEST.md`, `DEFICIT_ANALYSIS.md`; there was no single dependency table. Added below (section "Dependency audit") | MET (table added here) |
| A5 | "Register ... in the ... Interlocking Systems Manifest. Cross-reference, but do not merge it into, the Mining & Industrial Development Expansion" (s.13) | INT-216, 219, 230-233, 250-252, 260, 270-290 in `SYSTEM_INTERACTION_MANIFEST.md` (Settlements group); mining is read only through `MiningCapabilityAdapter` (mining `external`), `test_mining_adapter` | MET |
| A6 | "propose phased implementation with testable requirements, dependencies and migration plans" (s.13); "explicit assumptions" | `DESIGN.md`, `PROGRESS.md`, `DECISIONS_PENDING.md`, register children of EXP-B; assumptions in `DESIGN.md` sections 2-12 and `settlements.json` notes (agent values marked provisional) | MET |

**SET-A: 5 MET, 1 PARTIAL, 0 NOT MET.** Can close once A3's gap is settled: either wire `SettlementSave` (below) or record that
non-mining level history is deliberately not saved (levels are derived; the history only feeds a report). No owner decision is
needed for wiring; one line from the lead suffices to choose "do not persist history".

### Dependency audit (SET-A)

| This expansion needs | From | State |
|---|---|---|
| Skills per person, tools in pack/shared store | Skills, PAR-01, MIN-SKILLCAP (`Discovery.practitioners`) | live; `test_rule_parity` proves the same counts |
| Mining level | MIN-D `Discovery.evaluate("mining")` via `MiningCapabilityAdapter` | live; never derived twice |
| Per-worker experience, pay and work-time factors | `WorkExperience`, `CapabilityHook` (X18-CAPCOMP/CAPNUM) | live (hook on); INT-216 |
| Holdings and coin census | `SettlementHoldings` (was `tests/census.gd`) | live; sums to `World.total_coins` |
| Journals/conservation of the five settlements | `OffMapSettlement.audit`, `Regions.audit`, `economy_sim.gd` FATAL line | live |
| Contract offer shape, couriers, signatures | CON-01, `couriers.gd`, `formal_contracts.gd` | live / partial (X18-Q12, Q13 records) |
| Migration both ways, taxes | `migration.gd` (MIGRATE-18) | in development |
| Credit and barter (Q18-5) | `credit.gd` (credit parity worker) | in development elsewhere |
| Settlement growth, infrastructure (SET-D), physical network (SET-E) | none | not started, out of phases A-C |

## SET-B: phase B "Settlement capability model" (release evidence: "Unit tests for unlocks, loss of specialists, generational continuity")

| # | Criterion (source) | Evidence | Status |
|---|---|---|---|
| B1 | "Each settlement maintains an industry capability profile, derived from the actual capabilities of its residents and infrastructure" (s.4) | `SettlementFacts.from_world` + `SettlementIndustries.evaluate/levels` (practitioners by skill and tool, `stock`, `structure`, `station`, `transport`, `records`, `industry`, `any` needs); `settlement_test` `test_levels_from_facts`, `test_live_village`, `test_rule_parity`. Computed on demand by `SettlementReport`; no daily maintained profile in the live World (see B5) | PARTIAL |
| B2 | "Individual NPC skills remain distinct; settlement proficiency does not magically grant expertise to every villager" | The level grants nothing (Q18-9: no gate, no skill); effects are per worker from their own experience (`WorkExperience`, `test_master_and_apprentice`); `regional_test` `test_levels_scale_never_gate`; `capability_test` `test_never_blocks`, `test_no_double_counting` | MET |
| B3 | "No automatic technology unlock merely because a population threshold is crossed"; "No universal ladder"; "A small mining village can outclass a larger farming town" | `settlement_test` `test_levels_from_facts` (300 people give the same levels), `test_specialization` (12-person hollow leads mining, 90-person town leads farming, different profiles) | MET |
| B4 | "Buildings, tools, trained residents, accessible resources and knowledge transmission must underpin real capabilities" | needs kinds above; hammer/anvil/forge/axe cases in `test_levels_from_facts`; shared tool serves one member | MET |
| B5 | Capability progression: "Experience", "Specialists", "Infrastructure", "Knowledge continuity ... population loss can erode capacity", "Industry interdependence ... actual outputs", "Settlement specialization" (s.4) | Experience: `experience.gd` (hours of work, owner D1-D9, `experience_test`). Specialists/loss: `test_levels_from_facts` (last smith dies -> 0). Infrastructure: new `test_continuity` (no anvil, no forge -> 0). Continuity: new `test_continuity` (apprentice carries the trade on after the master's death; nobody trained -> 0; fall recorded with its day); succession by apprentice in `aging_test`. Interdependence: carpentry needs forestry; smithing needs iron by mine or bars (`any`). Specialization: `test_specialization`. Decay: skills and experience do not decay by owner decision (experience never decays, leaves with the person); erosion is by loss of people and tools | MET |
| B6 | Phase gate "Unit tests for unlocks, loss of specialists, generational continuity" | unlocks: `test_levels_from_facts`, `capability_test` `test_levels_0_to_10`; loss of specialists: same + `test_continuity`; continuity: `test_continuity`, `aging_test` succession | MET (continuity test added) |
| B7 | s.12 deferred: "Exact settlement classifications and thresholds", "decay and specialist certification", "which cross-industry prerequisites are mandatory" | Levels per industry are provisional data (Q18-2); the effect percentages are Q18-11 (open, X18-SIM). No settlement tier label exists | PARTIAL (owner decision Q18-11) |
| B8 | Persistence of the profile and its history (s.4 "Knowledge continuity ... records"; save compatibility) | Not persisted: `SettlementSave` is not called by `World`; no dawn `SettlementIndustries.record`. Mining history is saved by MIN-D | NOT MET |
| B9 | Player-facing documentation (WIKI-01) | The wiki documents MIN-D's mining capability (`wiki_excavation.gd`) and the neighbouring settlements. It has no page for the other settlement capabilities, which is correct while they are report-only; nothing player-facing is claimed | MET (nothing live to document) |

**SET-B: 6 MET, 2 PARTIAL, 1 NOT MET.** Not closable yet.
What remains: (1) decide whether the derived all-industry settlement profile is a live system. Under X18-CAPCOMP the owner made
individual experience the basis of performance and pay and the settlement/workforce level "a reporting and planning metric", so the
profile currently has no consumer in play. Smallest implementation if wanted: in `World._new_day` call
`SettlementFacts.from_world` + `SettlementIndustries.evaluate` + `SettlementIndustries.record`, and add `SettlementSave.attach/extract`
to `to_dict/load_dict` (optional key, no version bump), with one save round-trip test and a "village skills" wiki page. About a day of
work; touches `world.gd` (save), so do it when no other worker holds that file. (2) Q18-11 percentages: owner decision (open).
If the owner prefers, B1/B8 can be recorded as superseded by X18-CAPCOMP and the record closed on B2-B6.

## SET-C: phase C "Abstract regional economy" (release evidence: "Accounting and 100/365-day multi-seed tests")

| # | Criterion (source) | Evidence | Status |
|---|---|---|---|
| C1 | "Create abstract off-map settlements with distinct finite stocks, needs, productive strengths and budgets" (s.7) | Five settlements as economies of their own (Q18-3, Q18-4): `offmap.gd`, `regions.gd`, `game/data/settlements.json`; `regions_test` `test_founding`, `test_daily_step` | MET |
| C2 | "Generate caravan orders from modeled demand and purchasing power rather than a fixed daily purchasing obligation"; "No fixed 30-coin quota remains" (s.7, s.11 b.7) | `balance.json` `_caravan_note`: `caravan_allowance`, float and ceiling gone (ECON-P1.3); traders carry only stock and pay from their tills (`Regions.visiting`); `regions_test` `test_world_caravan`; INT-231. `grep caravan_allowance` finds only the note | MET |
| C3 | "Use explicit restocking and settlement-accounting rules; avoid unexplained daily currency creation" | settlement journals and flow lines, `audit()` every day; `regions_test` `test_daily_step`; `economy_sim.gd` FATAL line; `conservation_test` | MET |
| C4 | "Support variable arrivals and empty trips when no worthwhile trade exists"; "A caravan may arrive with substantial buying power when real demand and funds exist, or buy nothing when demand is absent" (s.11 b.4) | arrivals staggered by distance (`test_staggered_step`, `Regions.visiting`); `regional_test` `test_no_demand_no_sale`, `test_genuine_trade`; a trader buys only what the village has beyond its keep | MET |
| C5 | "Imported and exported goods and money reconcile exactly across merchant and settlement inventories" (s.11 b.5) | `regional_test` `test_long_run_conservation`, `test_genuine_trade`, `test_refused_line`; `OffMapSettlement.audit`, `Regions.audit`; `conservation_test`; INT-270/271 flow lines; 30-day sims seeds 1,2: 0 currency and item leaks (register) | MET |
| C6 | "A starving but cash-poor town does not conjure purchasing power; trade failure is observable" (s.11 b.6) | `regional_test` `test_cash_poor_town` (unmet reason `funds`, no gift, no credit), `regions_test` `test_hunger_and_treasury` | MET |
| C7 | "Viable trade needs demand, supply, purchasing power, price and competition, logistics, accounting" (s.5) | `regional.gd` plan/execute, `routes.gd`, `test_competition`, `test_buyers_and_carriage`, `test_routes`, `test_independence` | MET |
| C8 | "Multi-seed 100-day, 365-day and multi-generation tests examine production, food, housing, population, industry employment, prices, trade and resilience" (s.11 b.8; phase C evidence "Accounting and 100/365-day multi-seed tests") | Evidence is 30-day seeds 1 and 2 (`economy_sim`), 90 days seed 1, `regions_sim` 200 days seed 1 (`docs/investigations/2026-10-23_regional_economy.md`), settlement-life test 15 and 40 years in `settlement_life_test`. No 100-day and 365-day multi-seed run of the live game with the regions is recorded | NOT MET |
| C9 | "Existing save games ... continue to work; migration is documented" (s.11 b.9) | `test_old_save`; INT-233; `SAVE_VERSION` comment | MET |
| C10 | "A village can prosper or decline without direct player intervention, with causes traceable to real inputs" (s.11 b.1) | settlements decline in isolation (Higham-on-the-Way loses 10 of 99 after about day 150, recorded unmodified); `test_hunger_and_treasury`; cause lines in `OffMapSettlement` journals; village-side outcomes in the economy report | MET |
| C11 | Variable-demand goods flows with credit/barter (Q18-5, "barter and credit with trust") | Credit parity is another worker's task (`credit.gd`, TRADE-CREDIT); `regional_test` still carries a stale line "(Q18-5 open)" in `test_cash_poor_town` | PARTIAL (other worker) |
| C12 | Illustrative cases s.6: no guaranteed sale of surplus, competition by price and distance | `test_no_demand_no_sale`, `test_competition`, `test_cooperation` | MET |

**SET-C: 10 MET, 1 PARTIAL, 1 NOT MET.** Not closable now.
What remains: the 100-day and 365-day multi-seed runs (the register's four-seed gate) of the integrated game with the settlements and
the multi-generation run; both are SIM-01 long runs for the lead to schedule (one run per seed to the longest duration, milestones
read from checkpoints `economy_sim.gd --every`), not code. No code gap was found that the runs would be expected to fix. Credit and
barter (C11) closes with the credit worker. No owner decision is involved except that a settlement failing in these runs is an
outcome, not a defect (WDR-022).

## WDR-002-C: Rule 002 "Professional Interdependency"

Rule text: "Every production profession must supply at least one good or resource required by a different profession." "Model
cross-profession demand so trades form production chains instead of isolated menus." Verification: "Run a complete chain with
inventories, payment, shortages and demand."

| # | Criterion | Evidence | Status |
|---|---|---|---|
| W1 | Every production profession supplies a good required by a different profession | `docs/systems/MATERIAL_INTERDEPENDENCY.md` (generated by `tools/check_materials.py`): carpenter, cook, farmer, hunter, laborer, miner, smith, tanner, woodcutter pass (10 professions audited, 9 pass). **Sage fails**: its tonics and poultice are bought by no other profession (`supplies nobody: open`); the check still reports "sage supplies_nobody" | NOT MET (1 of 10) |
| W2 | Cross-profession demand modelled as chains | `NPCBrain.BUYS`, `OUTLETS`, `wants`, `TRADE_STATIONS`; recipes consume other trades' outputs (`build_handcart`, `craft_plough`, `forge_iron_sword` needing leather, `brew_strong_tonic` needing the cook's ale) | MET |
| W3 | Verification scenario: a complete chain with inventories, payment, shortages and demand | New `game/tests/interdependency_test.gd`, 22 checks, 0 failures, on the real World and trade/craft rules: farmer -> cook (wheat, paid) -> pottage -> tavernkeeper (paid); woodcutter -> carpenter (log, paid) -> planks -> smith (paid). It checks inventories moved with nothing lost or made except by the recipe, payment coin for coin, village coins unchanged, shortage stops the next link, a stocked buyer buys nothing (demand met), a buyer with no coins buys nothing | MET |
| W4 | Every material consumed by at least 3 recipes across 2 professions (Rule 001, reported by the same tool) | Not part of WDR-002-C: 21 open findings belong to WDR-001/WDR-007-C | out of scope |

**WDR-002-C: 2 MET, 1 NOT MET** (W4 excluded). Not closable: the sage.
What is missing: the sage is the one production profession that supplies no other profession. The register's `next_action` already
names it ("the sage's supply link"). Smallest implementation: add a real demand for the sage's medicines from another trade with an
existing need, for example the guards keeping a healing good for their work (`NPCBrain.KEEPS`/`BUYS` for `guard`, restocked from the
sage and paid from the guard's coins), after which `tools/check_materials.py` reports the sage as supplying the guard and the sage
finding closes (the exception file is not the right route for a genuine gap). That is a new gameplay mechanic (a guard behaviour
that moves coins and healing goods, so it changes the simulation fingerprint), which `CLAUDE.md` section 11 reserves for owner
authorization: owner decision needed on which trade should depend on the sage (guards' kit, the tavern's ale-and-tonic
service, or the tanner's bandages bought back). Until then the finding stays open and honest in the generated report.

## Summary

| Record | MET | PARTIAL | NOT MET | Closable now |
|---|---|---|---|---|
| SET-A | 5 | 1 | 0 | After the A3 choice (wire `SettlementSave` or record that history is not persisted) |
| SET-B | 6 | 2 | 1 | No: profile persistence/live use (lead's call, small) and Q18-11 (owner) |
| SET-C | 10 | 1 | 1 | No: 100/365-day multi-seed runs (SIM-01) and credit (other worker) |
| WDR-002-C | 2 | 0 | 1 | No: the sage's supply link (owner decision on the mechanic) |

## Wiki and Documentation

Pages created: none (nothing player-facing was added; the settlement profile is report-only and the wiki already covers mining capability
and the neighbouring settlements). Technical references changed: this file; `DESIGN.md` section 2 (stale "crafting stands in" sentence
corrected). Wiki validation was not run (no wiki input changed). Remaining: a "village skills" wiki page if B1/B8 are made live.

## Tests run

`interdependency_test.gd` 22/0; `settlement_test.gd` 88/0 (including the 6 new checks); `python3 -m unittest discover -s tests` 110 OK; `check_requirements.py` 0 problems. No materials or interaction input changed, so those checks were not rerun.
