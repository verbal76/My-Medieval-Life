# Standalone approved systems: status record

Owner directive 2026-10-31, `docs/directives/2026-10-31_documentation_reconciliation.md` (DOC-RECON-01). Conventions,
precedence and status vocabulary: `docs/expansions/README.md`. This file covers every owner-approved system that no
expansion file owns. Expansions 17-27 and multiplayer have their own files in `docs/expansions/` (`EXPANSION_NN.md`); where a system here
overlaps one of them, this file points there instead of repeating it.

**Pending authority switch (DOC-AUTH-01, owner 2026-10-31).** When the owner approves the final revised specification
set, this file is re-based on it; until then the precedence in the README applies.

**Evidence base (2026-10-31).** Register: `docs/requirements/requirements.json` on `wip/requirements-control` (= staging
`aeaa012` + the DOC-RECON-01 start commit). Code and tests: `origin/wip/expansion20` @ `ad281dc` (the Build 25 candidate; read
with `git grep` / `git show`, nothing run). "In X" means the commit is an ancestor of that head. Code existing is not
validation; a missing test is not missing functionality. Proposed register corrections are listed at the end and were
handed to the lead; this file shows the register's status and marks a proposed correction with **(proposed)**.

**Authorization.** The current sequence is Build 25 (Expansion 20 validation and freeze), Build 26 (repository recovery and
consolidation), Build 27 (Expansion 21, only on the owner's explicit authorization) (owner, 2026-10-31, BUILD-SEQ-25-27). No
system in this file has an implementation authorization beyond Build 26 consolidation. An approved requirement with no build
placement (register target `owner decision`, `20+` or `unassigned`) is shown as **DESIGN ONLY, NOT AUTHORIZED**: the design
is approved and preserved, and building it needs the owner to place it in a build.

---

## 1. Housing (HOUSE-*)

**Approved scope.** `docs/directives/2026-10-20_housing_succession_adoption.md` Parts 1-2 and 6 (HOUSE-01..07); OD-13
(`2026-10-20_owner_answers_OD11_OD12_OD13.md`: bed sharing, living-quarters expansions, HOUSE-08/09); OD-14
(`2026-10-20_od14_housing_expansion_procedural_villages.md` Phase 1: small attached rooms HOUSE-10, alternatives HOUSE-11);
sleeping loft (`2026-10-20_sleeping_loft_and_long_run_reliability.md`, HOUSE-12). Rules WDR-020 (autonomous housing).

| Status | Records | Evidence |
|---|---|---|
| IMPLEMENTED (COMPLETE) | HOUSE-01..10 | `game/scripts/core/construction.gd` (KINDS incl. `quarters`, `room`), `housing_test.gd`, `housing_trace.gd`; Build 16 365-day runs (REC-001 evidence: houses built 13/9/7/12, seeds 1-4) |
| IMPLEMENTED, targeted tests only | HOUSE-12 sleeping loft | `construction.gd` `start_site(p, "loft")`; `housing_test.gd` `test_sleeping_loft`. Open: a loft finished in a year-long run |
| PARTIAL | WDR-020-C | compliance audit against the rule's verification scenario not done |
| DEFERRED | HOUSE-11 upper floors / attic alternatives | owner deferral; `docs/design/UPPER_FLOORS_SCOPE.md` (estimate) |

**Remaining approved:** WDR-020-C audit. **Open owner decisions:** none. **Dependencies:** construction, property, timber
supply (OD-16). **Next authorized phase:** none beyond Build 26 consolidation.

## 2. Family, aging, succession, adoption (FAM-*, ID-D*, related)

**Approved scope.** `2026-10-20_housing_succession_adoption.md` Parts 3-4 and 6 (FAM-01..06); OD-11/OD-12 (orphan care,
equal relatives; FAM-07 bandit clan for unplaced orphans); `2026-10-20_fam07_clarification_living_economy.md` (FAM-08);
`2026-10-23_family_sacrifice_responsibility.md` (FAM-SAC-01); calendar and aging B8-029 / OWN-03 (8-day year); adoption
REC-001; identity decisions `2026-10-23_id_d2_succession_decisions.md` (ID-D1, ID-D2) and the 39-decision reconciliation
D38 (ID-D3). Courtship and friendship: `2026-10-19_courtship_friendship.md` (CRT-01..12). Player-to-player families belong to
the multiplayer file (MP-PLAYER-FAMILY, CRT-03, MP-ADOPTION-AGENCY).

| Status | Records | Evidence |
|---|---|---|
| IMPLEMENTED | FAM-01..07, REC-001, OWN-03, B8-029, CRT-01/02/04/05/07..12 | `guardianship.gd`, `life.gd`, `identity.gd`; tests `family_test`, `family_first_test`, `succession_test`, `aging_test`, `relations_test` (all in X). FAM-SAC-01 combined suites on X `4f50ffb`. Most carry TARGETED TESTS PASSED and open device checks |
| Assessed in `EXPANSION_19.md` | ID-01 persistent identity (code in X: `identity.gd`, `identity_test`; commits `84d1880`, `45d68d3` in X via `801d24b`/`b2f7dc2`); FAM-SAC-01 | register still says ID-01 "IN DEVELOPMENT"; that file carries the correction |
| PARTIAL | CRT-06 friendship benefits (votes wait on elections, Expansion 21); WDR-021-C (compliance audit) | `world.gd::player_quote`, `dialogue.gd::news` |
| DESIGN ONLY, NOT AUTHORIZED | FAM-08 (an adult raised in the bandit clan chooses its future) | no code in X (searched) |
| PROVISIONAL decision | ID-D3 identity-gate baseline: promote only after a same-commit conservation, determinism and first-divergence audit (owner D38, 2026-10-27; ruling 2026-10-28) | |

**Open owner decisions:** none open; ID-D3 is conditional on evidence. **Dependencies:** judgment (Expansion 19), politics
(CRT-06 votes, Expansion 21), multiplayer families. **Next authorized phase:** none beyond Build 26.

## 3. Food security and farming (FSE-*, FARM-*, PL2-015-*)

**Approved scope.** `2026-10-20_food_security_goal_driven_economy.md` (FSE-00..10), `2026-10-20_agricultural_findings_followup.md`
(FSE-12..18), `2026-10-20_od22_od23_od24_farms_leases_stalls.md` (FARM-01..07), OD-25/26/27 (2026-10-21),
`2026-10-21_fse12_fse13_farming_decision.md` (shared per-cell model as direction; **no yield approved; both switches off**),
`2026-10-22_farm08_q_crop_decision.md` (crop shared by cutting work), `2026-10-23_owner_answers_seed_share.md`, B18-DP-04
(farming deferrals, `docs/build18/FARMING_RETAINED_DEFERRED.md`, on X only).

| Status | Records | Evidence |
|---|---|---|
| IMPLEMENTED | FSE-01..09, FSE-14..18, FSE-B05..B12, FARM-01..05, FARM-07, FARM-08A/B/C, FARM-09, FARM-CROP-01, FARM-CROP-SEED, PL2-007, PL2-015 | `farming.gd`, `farm_plots.gd`; `farming_test`, `farm_plots_test`, `farm_place_test`, `world_test`; FSE-00 umbrella INTEGRATED (verification NOT TESTED as an umbrella) |
| PARTIAL (built behind switches, off) | FSE-12 shared model, FSE-13 seasonal village fields, FARM-06 manor seed and labour, FARM-08 shared-yield comparison | `farming.gd` `shared_manor()`, `seasonal_fields()`, `wheat_yield()`; `balance.json` in X: `shared_manor_farming 0`, `seasonal_village_farming 0`, `shared_wheat_yield 0`. Comparison: `docs/design/FARM08_YIELD_COMPARISON.md` ("awaiting the owner's approval") |
| DESIGN ONLY, NOT AUTHORIZED | FSE-10 (gardens, rented land and pens, side hunting, household stalls); PL2-015-BUYANIMALS, -COOPS, -HIRED, -OTHER, -TRAP, -WATER | wiki "Not in the game yet: Oxen, coops, watering, trapping and hired farmhands" (`wiki.gd` `_not_yet`, X) |
| SUPERSEDED | FSE-11 (by FARM-06) | |

**Open owner decision (not registered as a decision record):** the shared wheat yield and whether to switch on
`shared_manor_farming` and `seasonal_village_farming`. The owner asked on 2026-10-21: "Report the comparison results and your
proposed value for my approval before enabling either switch globally." New decision record **(proposed)**: FARM-YIELD-D1.
**Dependencies:** Living Economy (LE-03 hired farmhands, LE-05 animals and trapping), Expansion 25 (weather for coops and
watering), CON-06 farm labour contracts. **Next authorized phase:** none beyond Build 26.

## 4. Couriers and transport (X18-Q12)

Owned by `docs/expansions/EXPANSION_18.md`: X18-Q12, X18-Q12-BOOTH, X18-Q12-POST are IMPLEMENTED (INTEGRATION
VERIFIED; `couriers.json`, `courier_test`, `courier_live_test`, `courier_desk_test` in X; gameplay check open). Sources:
`2026-10-21_courier_booths_known_recipients.md`, `2026-10-21_courier_contract_interface_pricing.md`. Courier fee coefficients
stay provisional (CON-08-Q). Not repeated here.

## 5. Service contracts beyond CON-01/02 (CON-02-KINDS, CON-03..08)

**Approved scope.** CON-01/CON-02 (Expansion 17 file). Further service contracts: owner answers CON02-S-1..S-6
(`2026-10-21_build17_con01_final_decisions_service_contracts.md`, `2026-10-21_build17_consolidated_14_decisions.md`), each
APPROVED as a direction with the current behaviour as default until built. Detail: `docs/build17/CON02_SERVICES.md` (on X only).

| Status | Records | Notes |
|---|---|---|
| IMPLEMENTED | CON-UX-01 (contract window) | `2026-10-23_owner_answers_contract_window.md` |
| DESIGN ONLY, NOT AUTHORIZED | CON-02-KINDS (more service kinds), CON-03 restricted service advances (S-1), CON-04 work / results / base-plus-bonus pay (S-2), CON-05 protections and disputes before the local authority (S-3), CON-06 agricultural labour contracts (S-4), CON-07 villagers hiring services (S-5), CON-08 own formal-signing threshold (S-6; 50 coins stays, CON-08-Q) | No code in X: no service advances or disputes (`wiki_mining.gd` lists them as not in the game). LE-03 did not build negotiated services (`docs/expansion20/LE03_IMPLEMENTATION.md` s.2.4, X); `economy.json` `market.services` is `false` and nothing reads it |

**Dependencies:** OD-LE-07 (advances, coordinate), OD-LE-06 (local authority), OD-LE-13 (breach). **Open owner decisions:**
build placement for each. **Next authorized phase:** none.

## 6. Procedural villages (PVG-01..07)

**Approved scope.** `2026-10-20_od14_housing_expansion_procedural_villages.md` Phase 2: expansion-aware placement, realistic
density, per-home housing options, reserved expansion space, growth over generations, validation before acceptance,
deterministic generation and persistence.

**Status:** all seven DESIGN ONLY, NOT AUTHORIZED (register: "procedural village generation not yet scheduled"). No code in X
(no procedural village generator; the village is the fixed generator v6, OWN-04). **Dependencies:** construction and
property, HOUSE-10/12, roads (MAINT-01), settlements (Expansion 18), Expansion 22 continuous geography (E22-OD-02).
**Open owner decisions:** build placement. **Next authorized phase:** none.

## 7. Health, maintenance, job-board pay, mining follow-ons

| Record | Approved scope (source) | Status | Evidence |
|---|---|---|---|
| HEALTH-01 | Medieval health, injury and medicine (`2026-10-21_build17_minf2_q1_q2_decisions.md`) | DESIGN ONLY, NOT AUTHORIZED | `wiki_mining.gd` lists injuries, illness, treatment as not in the game; health exists only as hit points, rest (PAR-03) and medicine items |
| MAINT-01 | Need-driven maintenance, village expansion, road building (`2026-10-21_build17_rec013_final_decisions.md`) | DESIGN ONLY, NOT AUTHORIZED | No code. Related: goods decay DVW-B4 (`decay.gd`), Expansion 22 E22-CONDITION |
| JOB-02 | Offered pay on the manor job board, weighed by workers (same source) | DESIGN ONLY, NOT AUTHORIZED | Related, not the same design: LE-04 `EconMarket.wage_bargain` (negotiated manor wages behind `market.negotiated_wages`, off) in X. No status change proposed; the lead should note the overlap |
| PIT-02 | Larger, deeper open pits, strata, ramps (`2026-10-21_build17_consolidated_14_decisions.md`, MIN-E-Q5) | DESIGN ONLY, NOT AUTHORIZED | wiki "not yet" text only |
| EARTH-01 | Reuse of excavated earth (same source) | DESIGN ONLY, NOT AUTHORIZED | wiki "not yet" text only |
| INFO-01 | Sharing and selling prospecting information (same source, MIN-C-Q2) | DESIGN ONLY, NOT AUTHORIZED | no code |

**Open owner decisions:** build placement for each. **Next authorized phase:** none.

## 8. Crime, guards, dialogue and gossip (GP-CRIME*, GP-DIALOGUE*, GP-GOSSIP*, GP-REPAIR-SOCIAL)

**Approved scope.** `2026-10-24_master_gameplay_repair_dialogue_crime_guards.md`; owner answers
`2026-10-24_owner_answers_crime_repair.md` (hue and cry / bell; yield and be fined; "case ends; stain stays") and the
refinement in `2026-10-24_multiplayer_batch_c_g2.md` (the bell carries farther but does not inform every NPC regardless of
distance; no automatic universal refusal of known killers: judgment decides). Opinion may refuse a transaction
(`2026-10-26_npc_judgment_refusal_correction.md`).

| Status | Records | Evidence |
|---|---|---|
| IMPLEMENTED (INTEGRATION VERIFIED; device check open) | GP-CRIME-PURSUIT, GP-DIALOGUE-PERSPECTIVE, GP-GOSSIP-NATURAL, GP-REPAIR-SOCIAL; DVW-B2 (assault and killing as fined crimes; satisfied by GP-CRIME-PURSUIT) | `justice.gd`, `law.gd`; `justice_test`, `pursuit_test`, `manhunt_test`, `dialogue_perspective_test` in X; commit `d6d4aab` |
| DEFERRED | FR-09 crime from desperation (owner: "no desperation crime yet"; register target 19 has passed) | no code |

GP-REPAIR-SOCIAL's next action ("owner: approve earshot distances; decide on trade refusal for known killers") is stale:
both were answered in `2026-10-24_multiplayer_batch_c_g2.md` **(proposed note)**. **Open owner decisions:** none.
**Next authorized phase:** none.

## 9. Equipment and armour (ARMOR-*)

**Approved scope.** `2026-10-22_build18_owner_decisions_inventory_tailor_armor.md` (ARMOR-Q option A),
`2026-10-22_build18_master_integration.md` (ARMOR-01), owner message 2026-10-26 (ARMOR-CATALOG-01, ARMOR-MATERIALS-01),
D16 answer B CONDITIONAL (2026-10-27) and the 2026-10-28 ruling: Build 22's four categories, items and visuals stand; numbers,
buffs (including the fireball buff) and material choices stay PROVISIONAL.

| Status | Records | Evidence |
|---|---|---|
| IMPLEMENTED (targeted tests; device check open) | ARMOR-01, ARMOR-CATALOG-01, ARMOR-MATERIALS-01, TAILOR-18 | `armour_worn_test`, `gear_catalogue_test`, `equip_test` in X |
| PROVISIONAL decision | ARMOR-CATALOG-D1 (numbers, buffs, materials, cloth headgear) | |

ARMOR-CATALOG-01's next action ("owner approves the catalogue proposal; then a Build 22 worker implements it") is stale: it is
implemented and D16 is answered **(proposed note)**. **Open owner decisions:** the balance and art review that would end
ARMOR-CATALOG-D1's PROVISIONAL state. **Next authorized phase:** none.

## 10. Assets, art and audio pipeline

**Approved scope.** Asset integration policy (owner 2026-10-18/19, CLAUDE.md s.3; `2026-10-19_asset_integration_system.md`),
OWN-01 (skill, registry, scaling standard), B14-12 (sprite list), audio `2026-10-23_game_music.md` (MUSIC-18, SFX-18).

| Status | Records | Evidence |
|---|---|---|
| IMPLEMENTED | OWN-01, B14-12, OWN-23, B14-11; MUSIC-18 and SFX-18 (TARGETED TESTS PASSED; device audio check open) | `.claude/skills/asset-integration-pipeline/`, `tools/assets/`, `docs/assets/`; `game/scripts/core/audio.gd`, `audio_test` in X; commits `6beb4b3`, `7d50095` in X |
| PARTIAL, art-blocked | B12A-07 (blocked), B14-10, B8-007, PL1-07, PL1-13, PL2-010, PL2-013, DVW-A13 | crop stages, tool swings, sitting poses, stove, sawhorse, furniture, feathers |
| Stale | FR-08 "Music and sound" (IMPLEMENTATION BLOCKED, "no audio supplied") | delivered by MUSIC-18 and SFX-18 → SUPERSEDED **(proposed)** |
| DEFERRED | REC-012 Tiny Ranch pack (on hold, not cancelled) | |
| DESIGN ONLY, NOT AUTHORIZED | FR-02 Forgotten Memories waterfalls, fences, props | |

**Open owner decisions:** none. **Next authorized phase:** asset work continues only inside authorized builds.

## 11. Wiki (WIKI-*)

**Approved scope.** WIKI-01 permanent rule (`2026-10-21_permanent_wiki_maintenance.md`), WDR-008, FR-06, PL2-009, UI-WIKI-01,
GP-WIKI-LAYOUT, REL18-WIKI.

| Status | Records | Evidence |
|---|---|---|
| IMPLEMENTED | PL2-009, FR-06, UI-WIKI-01, GP-WIKI-LAYOUT, REL18-WIKI, WDR-008-C | `game/scripts/core/wiki*.gd` (18 providers), `wiki_test` in X; "Not in the game yet" pages (`wiki.gd` `_not_yet`, `wiki_mining.gd`) |
| Standing rule | WIKI-01 | applies to every workstream |
| PARTIAL, probably stale | WIKI-B17 (Build 17 wiki reconciliation; "what remains is unrecorded") | the Build 18 release gate REL18-WIKI (INTEGRATION VERIFIED) covers Build 17 mechanics → COMPLETE **(proposed; lead to confirm)** |

**Next authorized phase:** wiki pages follow each authorized feature; LE-05 tool rental is behind its switch, so the
`todo:tool_rental` page should be re-checked when rental is switched on.

## 12. Flight recorder (REC-19, REC-D*, REC-DIAG, REC-STORE)

Owned by `docs/expansions/EXPANSION_19.md` (REC-19, REC-STORE, REC-DIAG, REC-D1..D4, FIX-RECF1 and REC-F1, which it proposes
as SUPERSEDED by FIX-RECF1). In short: IMPLEMENTED (`game/scripts/core/recorder/*`, `game/scripts/recorder_export/*`,
`tools/recorder_archive.py`, `recorder_test` in X), off by default in every build (REC-D1); remaining: REC-19 stage D5 / D4
relations and the REC-DIAG gaps (premises till moves, rents, attendants' wages, construction events) in Expansion 20 scope.
`docs/design/FLIGHT_RECORDER_DESIGN.md` names `tools/recorder_xlsx.py`, which was never written; the export was built in
GDScript (`recorder_export/xlsx_writer.gd`, X).

## 13. Time model (TIME-*)

**Approved scope.** OD-21 (`2026-10-20_od21_time_model.md`): 24-hour days, 8-day years, four 2-day seasons; every timed system
classified; no automatic retuning.

| Status | Records | Evidence |
|---|---|---|
| IMPLEMENTED (COMPLETE) | TIME-01, TIME-02, TIME-04 | `docs/design/TIME_MODEL.md`; `balance.json` calendar note (X) |
| Proposals delivered, nothing retuned | TIME-03 (PROPOSED; `docs/design/TIME03_RETUNING_PROPOSALS.md`) | each retuning still needs the owner |

**Next authorized phase:** none.

## 14. Game feel (JUICE-00; decisions JD1-JD6)

**Approved scope.** `2026-10-22_game_juice_preliminary_assessment.md`: "planning and evaluation only. Do not implement effects
or change gameplay without approval." Also `2026-10-22_build18_master_overnight_execution.md` Part 9 (a restrained
game-feel pass: responsive input, clear feedback; delivered through the GP-* controls work, Expansion 20 file).

| Status | Item | Evidence |
|---|---|---|
| Deliverable on an unmerged branch | JUICE-00 assessment `docs/juice/PRELIMINARY_ASSESSMENT.md` | only on `origin/wip/juice-assessment` (`bebf1f3`, not in X or staging). Register says INTEGRATED / INTEGRATION VERIFIED / COMPLETE; correct is IMPLEMENTED ON TASK BRANCH until Build 26 recovers the document **(proposed)** |
| Not started (needs approval) | Phases J1 quick wins, J2 activity effects, J3 sound, J4 atmosphere, J5 social visibility | no effects helper, no day/night tint, no "Reduce effects" setting in X (`game_ui.gd` `LOG_LINES 2` unchanged) |

Decisions in the assessment (section 6), assessed against later owner decisions:

| Id | Question (quoted from the assessment) | Assessment |
|---|---|---|
| JD1 | "Audio: may the owned Living Forest sounds be integrated as FR-08's first slice ... Which events get sound first? Default volumes?" | Answered in substance by the owner's audio directive 2026-10-23 (MUSIC-18, SFX-18: music, ambience, SFX bus, volume sliders). The remaining Living Forest chop and fall sounds are asset-pipeline work. Register as SUPERSEDED **(proposed)** |
| JD2 | "Day and night: should the picture darken at night (how dark at midnight; interiors; underground already dark)?" | Genuine and open. Touches Expansion 25 (seasons and weather presentation) |
| JD3 | "Villager chatter: how often may villagers show what they are doing in bubbles (OWN-19 extension)?" | Genuine and open |
| JD4 | "Screen shake and haptics: allowed at all, on which events, and default on or off?" | Genuine and open |
| JD5 | "Notifications: which village notes the player sees in the corner log by default, and whether a filter exists." | Genuine and open (the shared 2-line log is unchanged in X) |
| JD6 | "Effect art source: Puny Skills effect sprites versus procedural pixels" | Not an owner question under the asset integration policy (CLAUDE.md s.3: the team decides asset use); not registered |

Also an owner question: approval to start phase J1 (the directive says "wait for approval"). **Next authorized phase:**
none; no juice implementation is authorized.

## 15. Designing Virtual Worlds items (DVW-*)

**Source.** `docs/reference/DESIGNING_VIRTUAL_WORLDS.md` (owner-adopted A- and B-items). 30 records.

| Status | Records |
|---|---|
| IMPLEMENTED | 19: DVW-A1, A2, A4..A8, A10, A11, A12, A14, B1, B2, B3-CHAPEL, B3-FEAST, B3-LUX, B4, B5, B8 (11 still OPEN for device or acceptance checks) |
| PARTIAL | DVW-A3 (money-supply re-measure; closure unrecorded), DVW-A13 (feathers still have no use); DVW-B3 umbrella: three chosen coin sinks built, heriot "not chosen" by the owner on 2026-10-23 (`2026-10-23_owner_answers_coin_sinks.md`) → PARTIALLY IMPLEMENTED **(proposed; register says NOT STARTED)** |
| DESIGN ONLY, NOT AUTHORIZED | DVW-A9 (escape from predators and bandits), DVW-B7 (life chronicle, titles, memorial; overlaps GM-01 and Expansion 24), DVW-B9 (readable danger: howl and roar cues, lethal-need warnings) |
| DEFERRED | DVW-B6 wildlife wandering in from the overworld (owner 2026-10-21; its target, Build 18, has passed: needs re-placement) |
| PROPOSED (not approved) | DVW-B10..B13 |

## 16. World Design Rule compliance (WDR-*-C)

22 compliance records. Rules themselves: `docs/WORLD_DESIGN_RULES.md`.

| Status | Records |
|---|---|
| IMPLEMENTED (COMPLETE) | WDR-005-C, WDR-006-C, WDR-007-C |
| IMPLEMENTED, OPEN (checks pending) | WDR-002-C, WDR-004-C, WDR-008-C, WDR-009-C, WDR-011-C, WDR-012-C |
| PARTIAL | WDR-001-C (open material violations, `docs/systems/MATERIAL_INTERDEPENDENCY.md`), WDR-010-C (device playtest), WDR-013-C (deposits), WDR-015-C (politics, VP-01), WDR-018-C, WDR-020-C, WDR-021-C (compliance audits), WDR-022-C (closure unrecorded) |
| DESIGN ONLY, NOT AUTHORIZED | WDR-014-C (graves, legacy: Expansion 24), WDR-016-C (bandit factions: Expansion 23), WDR-017-C (generational memory), WDR-019-C (political agency: Expansion 21) |
| OPEN DECISION | WDR-003-C meaningful recipes (OWNER DECISION REQUIRED) |

## 17. Feature requests (FR-*)

| Status | Records |
|---|---|
| IMPLEMENTED | FR-04, FR-05, FR-06, FR-07 |
| DESIGN ONLY, NOT AUTHORIZED | FR-01 lizards and spiders (Expansion 26), FR-02 props, FR-03 campfire for cooking outside the village (the only campfire in X is the bandit camp's, `main.gd`) |
| DEFERRED | FR-09 crime from desperation (target 19 passed), FR-10 archery |
| OPEN DECISION | FR-11 personality, prestige and migration (2026-10-17 list; largely covered since by judgment, Expansion 19, and free migration, X20-SCOPE; the go-between and dislike-driven migration stay deferred, owner 2026-10-31). The owner should say whether anything of FR-11 remains |
| Stale | FR-08 music and sound → SUPERSEDED by MUSIC-18 / SFX-18 **(proposed)** |

## 18. Early-build defect families (summary)

Counts from the register (records, by approval / implementation / completion). Only open, non-integrated records are named.

| Family | Records | Done (INTEGRATED) | Superseded | Open, not integrated |
|---|---|---|---|---|
| B7- | 17 | 14 | 1 | B7-007 (PARTIAL: deposits never refill; stone imports fixed; see Expansion 17), B7-016 (BLOCKED: merchants at 0 coins; check against the Living Economy market before Build 27) |
| B8- / B8R- | 25 / 20 | 24 / 18 | 0 / 2 | B8-007 (PARTIAL, art) |
| B12A- | 11 | 4 | 4 | B12A-05 accessibility (PROPOSED; owner D36h now names a "UI accessibility roadmap" → OWNER APPROVED **(proposed)**), B12A-07 (BLOCKED, art), B12A-08 (DEFERRED umbrella) |
| B13- | 15 | 14 | 0 | B13-15 Android signing stability (BLOCKED) → SUPERSEDED by ANDROID-RELEASE-SIGNING **(proposed)** |
| B14- / B14R- | 13 / 12 | 11 / 12 | 0 | B14-09 (Expansion 26), B14-10 (PARTIAL, art) |
| EQ- | 17 | 16 | 0 | EQ-05 (PARTIAL: no hidden protection; WDR-022 classification) |
| PAR- | 10 | 10 | 0 | none |
| PERF- | 6 | 5 | 0 | PERF-01 (PARTIAL: closure unrecorded) |
| PL1- / PL2- | 13 / 21 | 10 / 13 | 0 | PL1-07, PL1-13, PL2-010, PL2-013 (art), PL1-11 cloud saves (PARTIAL, stage 1), PL2-015-* (section 3) |

## 19. Recovered owner requests and early owner records (REC-001..017, OWN-*, K-*)

| Status | Records |
|---|---|
| IMPLEMENTED | REC-001, 004, 005, 013, 017; OWN-01, 03..07, 10, 11, 13..16, 18, 20, 23, 25..27; K-1, K-2 |
| PARTIAL | OWN-08 post-audit remediation, OWN-19 quest markers and busy-villager bubbles, OWN-22 platforms, OWN-28 living-world intent (its Morris world and magic parts are parked by OD-03) |
| DEFERRED | REC-006 castles, dungeons, caves; REC-007 several settlements (abstract settlements exist since Expansion 18; walking to them is not in the game); REC-011 main storyline; REC-012 Tiny Ranch pack |
| OPEN DECISION | REC-003 Android API 36 (builds already comply; owner D36f "Android toolchain maintenance only" may answer it: owner to confirm), REC-008 near/far simulation tiers, REC-014 revisit the foundations with "the recent research" (unspecified) |
| Superseded by later owner decisions **(proposed)** | REC-002 over-the-air updates on Mote (OD-17 D36e, 2026-10-27: "no automatic or silent updater and no Mote infrastructure"); REC-009 combat style (parked by OD-03 and OD-17 D36c → DEFERRED); REC-010 class progression and "system jobs" (OD-17 D36b: "the present skill and career system, no class lock"; the tech/research-tree part was not addressed); OWN-29 era, county, Godot, Android, PCG32 (OD-03: engine and platforms current, era and county parked) |
| PROPOSED (not approved) | OWN-02 wildlife balance follow-up; Q-11 design-gap phased sequence (historical; OD-09 D35 → SUPERSEDED **(proposed)**) |

## 20. Owner-action items (AR-*, ENV-*, Q-*)

| Record | What the owner must do | Status |
|---|---|---|
| AR-OWNER | Audit remediation checklist: release environment, visibility, private infrastructure | BLOCKED on the owner |
| AR-P0-3 | Delete the unrelated `inventory/registry` branch by hand | BLOCKED on the owner |
| AR-P1-2 | Delete PR #1's branch `claude/charming-albattani-8jjfya` (push-triggered workflow) | PARTIAL |
| ENV-RTK | RTK token tool persistent in the cloud environment | BLOCKED (external) |
| Q-08 | Resource depletion and wildlife sustainability (owner decision) | BLOCKED; much since covered by EQ-02, Expansion 17 deposits and WDR-018 |
| Q-10 | Hot Attic Games read-only registry | BLOCKED (owner/external) |

Done: AR-P0-1, AR-P0-2, Q-03..Q-06. Superseded: AR-P1-1 (by B13-15).

## 21. Proposed register changes

The machine-readable list (status changes, new decision records, conflicts, missing sources) was handed to the lead
(scratchpad `recon/standalone.json`). Summary: FR-08, B13-15, REC-002, REC-010, OWN-29, Q-11 to SUPERSEDED; REC-009 to
DEFERRED; B12A-05 to OWNER APPROVED; DVW-B3 to PARTIALLY IMPLEMENTED; JUICE-00 to IMPLEMENTED ON TASK BRANCH; WIKI-B17 to
COMPLETE (to confirm); notes on DVW-B6, F-1, FR-09
(past targets), GP-REPAIR-SOCIAL and ARMOR-CATALOG-01 (stale next actions). New decisions: FARM-YIELD-D1, JUICE-JD1 (as
superseded), JUICE-JD2..JD5, JUICE-J1. No genuine owner-versus-owner conflict was found in this scope: each disagreement has
a later owner decision.
