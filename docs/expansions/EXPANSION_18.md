# Expansion 18: Settlement Advancement & Regional Economy (EXP-B), shipped as Build 18

Status record under the owner's documentation reconciliation directive (`docs/directives/2026-10-31_documentation_reconciliation.md`,
DOC-RECON-01). Vocabulary and precedence: `docs/expansions/README.md`. Reconciled 2026-10-31 against the register on staging
(`aeaa012` plus `3ecf89f`) and the code on `origin/wip/expansion20` `ad281dc`. Register corrections are proposals until the lead
applies them (listed at the end).

**Overall status: PARTIAL.** Phases A-D of the owner's specification are implemented and were released in Build 18 (private
draft, 2026-10-23). **Phase E (an actual inter-settlement network) is not built**; the owner moved its successor into Expansion
22 (Settlement Advancement Phase 2), which is design only and not authorized. The register's EXP-B umbrella still says NOT
STARTED: that is stale.

Build 18 was a combined release (owner B18-SCOPE): track B was this expansion; tracks A (playtest corrections) and C (earlier
roadmap items) and the B18-DIR polish (inventory, tailor, armour, character creation, visuals) shipped with it and are recorded
in section 2b so they are not mistaken for unbuilt work.

## 1. Current approved scope

| Source | Date | What it settles |
|---|---|---|
| `docs/directives/My_Medieval_Life_Settlement_Advancement_Regional_Economy_Expansion.pdf` / `.txt` | 2026-10-20 | Primary specification: industry-specific capability from people, skills and infrastructure; off-map settlements with finite demand and budgets; growth and decline; phases A-E (s.10); acceptance (s.11), including "No fixed 30-coin quota remains" |
| `2026-10-20_two_decisions_three_expansions.md`; ROAD-01 | 2026-10-20 | Separate expansion EXP-B; Build 18 |
| `2026-10-21_parallel_prospective_development_18_19.md` (PROS-01), `2026-10-21_expansion18_master_directive.md`, `2026-10-21_expansion18_capability_simulations_contracts.md`, `2026-10-21_expansion18_decisions_q18_9_q18_10.md`, `2026-10-21_sync_expansions_with_build17.md` | 2026-10-21 | Prospective development (PROS-18), Q18-9 (capability never a permission gate), Q18-10..13 (trade, couriers, signing) |
| `2026-10-21_build17_od01_final_decisions.md` item 5 | 2026-10-21 | Regional caravan market (P1.3) assigned to Expansion 18, its numbers not approved |
| `2026-10-22_build18_master_integration.md` (B18-DIR), `2026-10-22_build18_master_overnight_execution.md` (B18-SCOPE, tracks A/B/C), `2026-10-22_build18_*` (inventory INV-18, axe and trees, ore placement, inventory/tailor/armour) | 2026-10-22 | The combined Build 18 |
| `2026-10-23_build18_decision_package_answers.md`, `2026-10-23_chapel_alms_build18_decisions.md`, `2026-10-23_reg_demo_d1_and_build18_target.md`, `2026-10-23_rel18_device_and_decision_package.md`, `2026-10-23_build18_overnight_completion_release.md` | 2026-10-23 | B18-DP-01..16, chapel and alms, regional demography, the release gate sequence, the private release |
| `2026-10-23_expansions_22_23_kickoff.md` (owner answer, Option 1) | 2026-10-23 | **Later owner decision:** Expansion 22 = Settlement Advancement Phase 2, building on what Build 18 shipped; "Do not rebuild or duplicate any functionality already delivered in Build 18"; E22-OD-01/02 design approvals only |
| D37 (Q18-11), `2026-10-27_39_decisions_current_first_reconciliation.md` | 2026-10-27 | No extra settlement-wide pay or output multipliers (1.0); individual skills carry the effect |

## 2. Implemented

### 2a. Expansion 18 scope proper (specification phases A-D)

Code on `ad281dc`: `game/scripts/core/settlement/` (`regions.gd`, `offmap.gd`, `regional.gd`, `industries.gd`, `facts.gd`,
`profile.gd`, `experience.gd`, `productivity.gd`, `capability_hook.gd`, `couriers.gd`, `routes.gd`, `formal_contracts.gd`,
`settlement_party.gd`, `migration.gd`, `ledger.gd`, `holdings.gd`, `settlement_save.gd`, `mining_adapter.gd`, `report.gd`);
data `settlements.json`, `settlement_industries.json`, `capabilities.json`, `couriers.json`. Expansion 18 merged into Build 18
at `d63d8d7`; profile save fix `0e1a88b`.

| Requirement | What | Tests (on `ad281dc`) | Validation |
|---|---|---|---|
| SET-A | Requirement ids, cross-industry skill schema, save compatibility (capability history saved under `SettlementSave.KEY`, `world.gd:137`, kept on load `0e1a88b`) | `settlement_test`, `profile_test` | TARGETED TESTS PASSED |
| SET-B, X18-CAPCOMP, X18-CAPNUM, X18-SIM, X18-D1..D9 | Per-industry capability from experience, tools, facilities; bounded modifiers; comparative simulations | `capability_test`, `capability_metrics`, `settlement_test` | INTEGRATION VERIFIED (CAPCOMP, CAPNUM); TARGETED (SET-B, SIM) |
| SET-C-FIVE, SET-C-SIM, ECON-P1.3 | Five off-map settlements as lighter-detail economies; the caravan is their traders, paying only from real tills (`balance.json` `_caravan_note`: daily allowance, purse float and per-visit cap removed) | `regions_test`, `regional_test`, `regions_sim` | INTEGRATION VERIFIED |
| SET-C (umbrella of C) | Close-out (`docs/expansion18/CLOSEOUT_SET_A_B_C_WDR002.md`@X20): 10 MET, 1 PARTIAL (credit parity), 1 NOT MET (100/365-day multi-seed runs). Both since met: TRADE-CREDIT integrated (`a2ea741`); 365-day seeds 1-4 on the integrated Build 18 game (runs 39874405723 and 39904513181, leak 0, no FATAL). Only the multi-generation run is outstanding, and the owner deferred it to SET-D-MULTIGEN | as above + `credit_test` | Register PARTIAL: **INTEGRATED (applied in the register 2026-10-31) / INTEGRATION VERIFIED**, multigeneration carried by SET-D-MULTIGEN |
| SET-D | Growth and decline, trades opening and closing from real demand and workers | `settlement_development_test`, `settlement_life_test` | TARGETED TESTS PASSED |
| TRADE-CREDIT | Barter and credit with trust, recorded debts | `credit_test` | TARGETED TESTS PASSED |
| MIGRATE-18, REG-DEMO-01, REG-BUY-01, REG-BUY-P1, REG-COURIER-01, REG-PARTY-01, REG-EVAL-01, REG-INV-01 | Two-way migration; settlement demography; the village buys from the settlements; couriers wired; one trading-party interface; evaluation and investigation | `migration_test`, `regional_food_test`, `courier_live_test`, `regions_test` | INTEGRATION VERIFIED (most) |
| X18-Q12, -BOOTH, -POST, X18-Q13, LAW-SKILL | Couriers, booths, postage popup; signing (small unsigned, formal signed); Law skill | `courier_test`, `courier_desk_test`, `contract_sign_test` | INTEGRATION VERIFIED |
| X18-STONECUT, STONE-02..06, SKILL-TRADES-18 | Professional stonecutter; stone dressing rules; Stoneworking; iron chisel; Carpentry, Masonry, Tanning | `stone_test` | TARGETED / INTEGRATION VERIFIED |
| WDR-002-C, WDR-004-C, WDR-012-C, PROS-18, SYNC-17 | Professional interdependency; economic consequences; competition and rivalry; prospective implementation; sync with Build 17 | `competition_test`, `run_tests` | as in the register |
| DVW-B3-CHAPEL, -FEAST, -LUX, DVW-B5 | Coin sinks: chapel offerings, wedding and seasonal feasts, luxury imports; announced taxes with hysteresis | `chapel_test`, `feast_test`, `luxury_test` | INTEGRATION VERIFIED |

### 2b. Shipped with Build 18 (tracks A and C, B18-DIR)

All INTEGRATED in Build 18 (`61ec528`), present on `ad281dc`: INV-18 (`inventory18_test`), TAILOR-18 and BARBER-01
(`tailor_barber_test`), CC-01, ARMOR-01 (completed in Build 22 `b7e1c91`), MAP-01, CON-UX-01, TRADE-UI-02, TRADE-AXE-01,
VER-CON-50ORE (`contract_50ore_test`), UI-HUD-01, UI-HUNGER-01, UI-PROGRESS-01, UI-WIKI-01, VIS-ANIMAL-01, VIS-AXE-01,
VIS-CROP-01, VIS-DOOR-01, VIS-STEPS-01, VIS-TREE-02, ORE-PLACE-01, WORLD-LIFE-01, BANDIT-RETURN (`outlaw_return_test`), B14-11,
MUSIC-18, SFX-18, DVW-B8, ECON-P3, FARM-CROP-01, FARM-CROP-SEED, PL1-10, PL2-008, PL2-014, PL2-015, ROOMS-18. PL2-008 and
PL2-014 have verification NOT TESTED in the register (code exists; validation not recorded).

### 2c. Build 18 release gates

| Gate | Status | Evidence |
|---|---|---|
| REL18-SUITES | IMPLEMENTED | all 85 suites on `5bdecb7` (game code = `61ec528`) |
| REL18-DET | IMPLEMENTED | `sim_gate` PASS, seeds 1-2, days 10/30 |
| REL18-LONGRUN | IMPLEMENTED | runs 39874405723 and 39904513181, seeds 1-4 x 365 days, leak 0, no FATAL, no script error (`docs/build18/LONG_RUNS_365*.md`@X20) |
| REL18-SAVE | IMPLEMENTED | a real Build 17 save loads (`docs/build18/SAVE_MIGRATION.md`@X20; `chapel_test::test_b17_save`) |
| REL18-WIKI | IMPLEMENTED | `wiki_test` passes |
| REL18-EXPORT, REL18-PACKAGE | IMPLEMENTED | release run 39935635926, three platforms from `61ec528`, checksums verified |
| REL18-DEVICE | NOT STARTED | no device playtest recorded |
| REL18-OWNER | NOT STARTED | private draft only; public publication needs the owner |

## 3. Partial

| Requirement | Done | Remaining |
|---|---|---|
| EXP-B (umbrella) | SET-A, SET-B, SET-C, SET-D | SET-E (phase E) and SET-D-MULTIGEN. Register NOT STARTED: **PARTIALLY IMPLEMENTED (applied in the register 2026-10-31)** |
| DVW-B3 (coin sinks umbrella) | Chapel offerings, wedding and seasonal feasts, luxury imports | "heriot" from its title has no record and no code (`git grep -i heriot` on `ad281dc` finds nothing). Register NOT STARTED: **PARTIALLY IMPLEMENTED (applied in the register 2026-10-31)**, heriot remaining (placement for the owner; it touches inheritance, Expansion 24) |

## 4. Remaining approved work

| Requirement | Status | Note |
|---|---|---|
| SET-E actual inter-settlement network (persistent settlements, routes, logistics, competition, merchant AI) | DESIGN ONLY, NOT AUTHORIZED | Target 20+; the owner's 2026-10-23 renumbering makes Expansion 22 the settlement phase 2, whose phase E "Persistent regional networks" is its successor. E22-OD-01/02 approved as design only; Expansion 22 is not authorized (sequence 20 -> 21 -> 23 -> 22 ...) |
| SET-D-MULTIGEN multigenerational verification | DESIGN ONLY, NOT AUTHORIZED | Owner deferred the extended campaign (`2026-10-23_chapel_alms_build18_decisions.md`, B18-DP-05) |
| Q18-8 visiting other settlements in person | DESIGN ONLY | Stays at Build 20 or later with SET-E (decision APPROVED) |
| DVW-B3 heriot | see section 3 | |

## 5. Deferred and superseded

| Record | Status | Decision |
|---|---|---|
| DVW-B6 wildlife wandering in from the overworld | DEFERRED | Owner 2026-10-21 deferred it to Build 18; still NOT STARTED, approval DEFERRED |
| F-1 NPC workshop construction | DEFERRED | approval DEFERRED |
| REG-CIRC-D1, REG-X20-D2, REG-X20-D4 (settlement coin circulation; hunger migration with no food) | DEFERRED decisions | as recorded in the register |
| CARAVAN-TMP (daily caravan allowance as a stand-in) | SUPERSEDED | by ECON-P1.3 / SET-C-FIVE (allowance removed, Build 18) |
| Q18-11 settlement-wide multipliers | Settled | D37 answer A (2026-10-27): none (1.0); supersedes the earlier X18-CAPNUM percentages as far as settlement-wide factors go |
| B17F-DEPLETE, B17F-SIMREPORT, CAP-TOOLHOLDER | Ideas (PROPOSED) | not approved work |

## 6. Outstanding owner decisions

- **REL18-DEVICE and REL18-OWNER.** The owner set the device-playtest sequence on 2026-10-23 and later ruled (2026-10-24,
  `2026-10-24_owner_start_multiplayer_now.md`) that personal playtesting is never a development prerequisite. Build 18 is frozen
  and superseded by Builds 19-24. Whether these two gates stay open as records, or close as not applicable, is the owner's call;
  nothing is blocked by them.
- Placement of SET-E's successor (Expansion 22) and SET-D-MULTIGEN: awaits authorization of Expansion 22.
- DVW-B3 heriot: placement.

No open Q18-*, X18-D*, B18-DP-*, CHAPEL-R*, STONE-D*, COMP-R1 or REG-*-D1 decision remains (all disposition APPROVED or DEFERRED).

## 7. Dependencies

Built on Expansion 17's capability schema (`capabilities.json`, MIN-D) and contracts (CON-01). Expansion 19 synchronized with
Build 18 (REG-DEMO, identity); Expansion 20 (Living Economy) reads the settlements' tills and stocks (X20-SETTLE-FOOD, LE-03) and
free migration (X20-MIGRATE, REG-X20-D1) extends MIGRATE-18. Expansion 22 extends, and must not rebuild, this work.

## 8. Implementation and validation references

| Item | Reference |
|---|---|
| Branches | prospective `wip/expansion18-preparation`; integration `wip/build18`; release `61ec528` |
| Release | private draft "My Medieval Life Build 18", run 39935635926 (2026-10-23); throwaway Android key (pre-policy); `docs/release/BUILD_18_PACKET.md`@X20 |
| Long runs | 39874405723 and 39904513181 (seeds 1-4 x 365 days) |
| Design and close-out | `docs/expansion18/*`@X20 (DESIGN.md header still says "PROSPECTIVE ... nothing integrated": stale, on the validating branch, not edited here), `docs/design/EXPANSIONS_22_23_AUDIT.md` (E22-P1 audit of what Build 18 delivered) |
| Stranded | `origin/wip/x18-readiness` `0182466` (`INTEGRATION_READINESS.md`): superseded by the Build 18 integration |

## 9. Next authorized phase

Expansion 18 is closed except the items in section 4, none authorized. Sequence (owner, 2026-10-31): Build 25 = Expansion 20
validation and freeze; Build 26 = recovery and consolidation (the `docs/expansion18/` and `docs/build18/` notes that live only on
`wip/expansion20` come home then); Build 27 = Expansion 21 only if authorized. Expansion 22 (successor of SET-E) follows 21 and 23
in the owner's order and needs its own authorization.

## 10. Missing sources

- The three research papers behind the capability numbers (`TenureExperience.pdf`, `9501lync.pdf`, `c8781.pdf`), attached by the
  owner to the Expansion 18 master directive: never committed on any branch (`docs/expansion18/RESEARCH_DIGEST.md`@X20 line 1
  says so). The digest preserves their findings; the papers themselves need recovery from the owner if wanted.
