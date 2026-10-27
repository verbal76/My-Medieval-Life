# Expansions 18-20 simulation and flight-recorder coverage matrix (X20-FINAL phase 2.1)

**Draft (planning commit): the column "Closed on `wip/x20-recorder`" is the plan until the implementation commits land.**

Owner directive `docs/directives/2026-10-27_x20_final_validation_recorder_release.md`, phase 2.1 (register X20-FINAL). Audit of the
code on **`87b69ab`** (`wip/x20-final`: the verified Expansion 20 baseline `3601211` with MP-INTERACT-01 merged last), worktree
`wip/x20-recorder`. Sources: the code (`game/scripts/**`), the feature switches (`game/data/judgment.json`, `economy.json`,
`recorder.json`, `capabilities.json`), the register on `staging/my-medieval-life` (records with `target_build` 18, 19 and 20: 133, 56
and 117; decisions and ideas are not systems and are not rows), `docs/expansion20/B19_RECOVERY_MATRIX.md`, the tests in `game/tests/`
and `tests/`, the simulation gate `tools/sim_suite.py`, and `game/data/recorder_coverage.json` with `docs/design/FLIGHT_RECORDER.md`.

**Rules of this matrix.** A documented design is never counted as an implementation; a register status is never counted as evidence by
itself (each "Status" below was read from the code). "Simulated" means a scenario of `tools/sim_suite.py` (the pre-build gate) runs the
system with its switch in the state named; a run that leaves a system switched off does not count as exercising it. "Recorded" means the
flight recorder writes events that let the system's behaviour be reconstructed. The column "Closed on `wip/x20-recorder`" names what this
branch added (section 4); everything else in "Missing" is still open.

Classes (the owner's five): **ACTIVE** implemented and active in the shipped game; **SWITCH** implemented behind a feature switch that is
off as shipped (the switch is named); **PARTIAL** partially implemented; **APPROVED-NI** approved but not implemented; **FUTURE** future
expansion work.

## 1. Summary

| Class | Rows | Of which simulated before this branch | Of which recorded before this branch |
|---|---|---|---|
| ACTIVE | 34 | 27 (most by the normal village alone, without a targeted scenario) | 14 fully or partly |
| SWITCH | 4 (aspirations, aspiration job choice, LE-01 economy model, judgment's report hook) | 0 (every gate scenario ran them off) | 1 partly (aspiration events, only if switched on) |
| PARTIAL | 3 (SET-C regional economy, DVW-B3 coin sinks umbrella, GP-POLISH umbrella) | 2 | 1 |
| APPROVED-NI | 6 (LE-02..LE-07, EMP-PERM-01, DVW-B3 heriot, SJD-G soak, F-1, FR-09) | n/a | n/a |
| FUTURE | 3 (Expansion 21+ hybrid, X20-OPEN-ITEMS record-only list, DVW-B6) | n/a | n/a |

Main gaps found (detail in sections 2 to 4):
1. **No gate scenario switched any Expansion 20 switch on**: aspirations (`judgment.json aspiration.enabled`), aspiration job choice
   (`aspiration.job_choice`), the LE-01 model (`economy.json enabled`) ran only in developer measurement runs (`--aspiration`, `--economy`),
   never in the gate, so the gate's evidence for them was nil (directive 2.4: "a simulation that leaves a new system disabled does not
   count").
2. **No gate scenario drove the owner's judgment chain end to end** (theft -> opinion -> gossip -> another's judgment -> later decision):
   `crime` exercised the crimes and the village response, but no later decision with the offender as counterparty was ever asked for.
3. **Recorder blind spots**: relations' help, talk, cooling, courting and proposals; judgment's fading, forgetting, retirement, personality
   change, grievances and betrayals, history records; contracts and credit (formation, delivery, payment, lapse, default, barter);
   production and consumption by actor; unmet needs with their reason; depletion; LE-01's records; multiplayer (joins, leaves, requests,
   syncs, host-and-guest state); the session's flags said "economy: no such flag in this build" although `economy.json` exists.
4. **Multiplayer has no simulation and no recorder at all**: its evidence is the network test harness (`game/tests/net_*`, 1 host + 1..3
   guests on one machine); host-owned time and disconnects are tested there, not in a black-box run.
5. **The independent verifier did not check** event-id completeness, references between tables, state transitions (life, contracts,
   jobs), flags, whether required systems were exercised, or multiplayer participant consistency.

## 2. Expansion 18 (settlement, production and regional economy)

| # | Feature or system | Exp. | Status (from the code) | Owner-approved behaviour (register) | Automated tests | Simulation (before) | Recorder (before) | Missing coverage | Required additional verification | Closed on `wip/x20-recorder` |
|---|---|---|---|---|---|---|---|---|---|---|
| 18.1 | Settlement capability levels (industry levels from real assets, reported never a gate) | 18 | ACTIVE (`Discovery.evaluate` each dawn; `capabilities.json`) | SET-A, SET-B, SET-D, X18-SIM | capability_test (17), settlement_development_test | normal village (levels move only with assets); X18-SIM analysis runs (`--capability`) outside the gate | none | levels and their changes not recorded | daily level per industry in the record; long run shows rise and fall | daily `world_day` event carries the levels (section 4) |
| 18.2 | Capability modifiers on work time and pay, per worker (X18 HOOK sites) | 18 | ACTIVE (`CapabilityHook`, per-worker since 2026-10-23) | X18-CAPCOMP, X18-CAPNUM (revised_bounded) | capability_test, experience_test (20) | normal village (every work unit passes the hook) | none (work actions recorded, multiplier not) | which multiplier a worker's unit used | covered by the item ledger (capability never creates a resource) | production rows name the actor; multiplier itself still not recorded (open, low value) |
| 18.3 | Industry specialization and settlement development (growth, decline) | 18 | ACTIVE for the five off-map settlements (`settlement/offmap.gd`, `industries.gd`) | SET-D, SET-C-FIVE, SET-C-SIM, REG-EVAL-01 | settlement_test, settlement_life_test, settlement_development_test, regions_test | every run (regions stepped each day; `regions.audit` checked every checkpoint) | settlement register transitions only (identity moves) | regional daily phases not recorded | regions' books every checkpoint (exists, blocking) | daily `world_day` event: regional coins and goods totals |
| 18.4 | Skills and tools affecting productivity (PAR-01, STONE-04/05, SKILL-TRADES-18, DVW-B8) | 18 | ACTIVE | STONE-04, STONE-05, SKILL-TRADES-18, DVW-B8, LAW-SKILL | skills_test, trade_skills_test, stone_test, experience_test, parity_test | normal village | none (tool wear and breakage only in the ledger) | tool breakage by actor | — | production/consumption rows include `broke_<tool>` by actor |
| 18.5 | Resource extraction and depletion (mining seams, open pits, mine works, prospecting) | 18 | ACTIVE | ORE-PLACE-01, MIN-C..F (Build 17), STONE-02/03 | underground_*_test, openpit_test, prospecting_test, quarry_test, parity_mining_test | normal village (seams worked; deposit ledger at checkpoints) | none | depletion not recorded; no depletion scenario | a scenario that works deposits out and shows the village's response | `strip_mine` stress scenario; `world_day` deposits left and worked out; `deposit_out` event |
| 18.6 | Forestry sustainability (felling, replanting, tree lifecycle) | 18 | ACTIVE | VIS-TREE-02, WORLD-LIFE-01 | tree_test, ecology_test, wildlife_test | normal village | none | felling by actor | long run trees and logs | production rows (`felled_log`) by actor; `world_day` trees standing |
| 18.7 | Farming and food production (fields, shared crop, seed, livestock, plough) | 18 | ACTIVE | FARM-CROP-01, FARM-CROP-SEED, PL2-015, B14-11 | farming_test, farm_plots_test, crop_share_test, herd_test, horse_test, field_work_test | normal village; food_start, corner_wheat, hunt_out | none (granary and food days in the snapshot) | harvest and eating by actor; why a meal was missed | — | production/consumption rows; `unmet` rows with the reason (`missed_meal_no_money`, `no_food_for_sale`, `field_unsown_no_seed`) |
| 18.8 | Regional supply and demand; settlement inventories; buying from the five settlements | 18 | ACTIVE | REG-BUY-01, REG-BUY-P1, REG-PARTY-01, REG-INV-01, ECON-P1.3 | regional_test, regional_food_test, party_test | every run; no_caravan scenario (trade cut) | trades with settlement parties appear as trades (`inv:?` for some stores) | regional stock levels over time | — | `world_day` regional totals |
| 18.9 | Trade routes, transportation, cartage and courier services | 18 | ACTIVE | REG-COURIER-01, X18-Q12, X18-Q12-BOOTH, X18-Q12-POST, GP-BUSINESS-COURIER | courier_test, courier_live_test, courier_desk_test, desk_test | normal village (villager postings) | none (courier coins show as unattributed holder alerts) | courier jobs not recorded | courier deliveries in a long run | stats rows (`courier_*`) in the hourly snapshot (existing); deliveries still not events (open) |
| 18.10 | Merchant competition and economic rivalry | 18 | ACTIVE | WDR-012-C | competition_test (4) | normal village | trades and refused trades | — | — | — |
| 18.11 | Contract formation and fulfilment (CON-01, signing, services, 50-ore) | 18 | ACTIVE | X18-Q13, VER-CON-50ORE, CON-UX-01, TRADE-UI-02 | contracts_test (22), contract_sign_test, contract_50ore_test, services_test | NPC-to-NPC orders in the normal village; no failed-contract scenario | **none** (`recorder_coverage.json`: Not instrumented) | formation, delivery, payment, cancellation and lapse unrecorded; their coins became unattributed alerts | a scenario with contracts that lapse; contract state transitions verified | `contract` events (open, deliver/pay, end with state and why) on the object thread `contract:<id>`, coin state rows; `contracts_fail` scenario; verifier checks contract transitions |
| 18.12 | Barter and credit with trust (debts, repayment, default) | 18 | ACTIVE | TRADE-CREDIT | credit_test (13) | normal village (villagers' food deals) | **none** | debts and defaults unrecorded | — | `credit` events (extended, repaid, late, defaulted, barter) with coins and goods |
| 18.13 | Payments and ownership transfers; business tills | 18 | ACTIVE | ECON-P3, PL1-10, X18-Q13 | business_money_test, property_test | normal village | trade, transfer, manor flows; tills not (alerts) | till movements | — | — (the hourly audit keeps naming them; open) |
| 18.14 | Currency and inventory conservation | 18 | ACTIVE | WDR-022, SIM-01 | conservation_test, economy_sim ledgers | every run (blocking) | coin audit (REC-D4), item rows for trade/transfer | item changes outside trade/transfer not seen | — | production/consumption rows attribute item flows to actors |
| 18.15 | Migration both ways with the settlements | 18 | ACTIVE | MIGRATE-18, REG-DEMO-01 | migration_test (9) | every run | identity moves (left, returned) | — | — | — |
| 18.16 | Coin sinks: chapel offerings, feasts, luxury imports | 18 | ACTIVE (heriot: APPROVED-NI) | DVW-B3-CHAPEL, DVW-B3-FEAST, DVW-B3-LUX (DVW-B3 umbrella PARTIAL) | chapel_test, feast_test, luxury_test | normal village | none | — | — | consumption rows where they use goods |
| 18.17 | Predictable taxes with hysteresis | 18 | ACTIVE | DVW-B5 | tax_test | normal village; poverty scenario added | manor tax flows | — | — | `poverty` stress scenario (`--set tax_rate_normal`) |
| 18.18 | Inventory pools, gear, armour, tailor, barber, character creator | 18 | ACTIVE (player-facing) | INV-18, ARMOR-01, TAILOR-18, BARBER-01, CC-01 | inventory18_test, armour_worn_test, tailor_barber_test, character_look_test | player verbs only (harness player inert) | player verbs | — | device playtest (REL18-DEVICE) | — |
| 18.19 | Save/load continuity (Build 18 keys) | 18 | ACTIVE | REL18-SAVE | save fixtures, start_test | probe_saveload (2 seeds, 2 days) | world_loaded / world_saved | archive across a save in the middle of a run | save, load and continue with the recorder on | `saveload_rec` probe run recorded (section 5) |
| 18.20 | SET-C abstract regional economy (finite demand) | 18 | PARTIAL (SET-C umbrella; SET-C-FIVE and SET-C-SIM done) | SET-C | regions_test | every run | — | — | — | — |
| 18.21 | NPC workshop construction | 18 | APPROVED-NI, DEFERRED | F-1 | — | — | — | — | — | — |
| 18.22 | Wildlife wandering in from the overworld | 18 | FUTURE (DEFERRED) | DVW-B6 | — | — | — | — | — | — |

## 3. Expansion 19 (judgment, personality, memory, relationships)

All of the judgment layer is **ON** as shipped (`judgment.json enabled: true`, 13 decision domains `true`, `report` false). The gate's
`b18_s1` run is the judgment-off comparison path (`--no-judgment`), never evidence for judgment.

| # | Feature or system | Exp. | Status | Owner-approved behaviour | Automated tests | Simulation (before) | Recorder (before) | Missing coverage | Required additional verification | Closed on `wip/x20-recorder` |
|---|---|---|---|---|---|---|---|---|---|---|
| 19.1 | Individual opinions: facts, beliefs, signed interpretation, ledgers | 19 | ACTIVE | PROS-19, SJD-C, X19-SCOPE | judgment_test (33), judgment_x19_test | every judgment-on run | facts, beliefs, ledger posts (D5) | — | — | — |
| 19.2 | Personality differences (tolerance, stubbornness, anger, practical wisdom, growth) | 19 | ACTIVE | X19-FOUND-PERS | judgment_personality_test (16) | every run | stubborn penalties as factors of choices only | trait changes over time unrecorded | — | `personality` event per change (channel, subject, severity, trait deltas) |
| 19.3 | Positive and negative judgments; trust and reputation | 19 | ACTIVE | SJD-C, X19-REGARD | judgment_test, judgment_live_test | every run | ledger posts, trust moves | — | — | — |
| 19.4 | Friendship, regard, courting, proposals | 19/20 | ACTIVE | DVW-B1, CRT-01..12 | relations_test (13), family_test | every run | shared hours, gifts, harm (R3); **help, talk, cooling, courting, proposals not** | courtship and proposal outcomes and refusals unrecorded | NPC and player proposals traced with their reason | `help`, `talk`, `cooling` (daily aggregate), `court_interest`, `court_ask` and `proposal` events with outcome and reason |
| 19.5 | Family relationships, family reputation and family stories | 19 | ACTIVE | X19-FOUND-FAMREP, X19-STORY-LIFE | judgment_bonds_test (14), judgment_x19_test | every run | family colour as a factor | stories and history passed down unrecorded | — | `history` events (made, told to a child) |
| 19.6 | Family-first decision priorities (FAMILY-01, FAM-SAC-01) | 19 | ACTIVE (`integration.family_first` true) | FAM-SAC-01 | family_first_test (11) | every run | family-priority events (D5) | — | — | — |
| 19.7 | Gossip, rumours, misinformation and corrections | 19/20 | ACTIVE | X19-MISINFO, GP-GOSSIP-NATURAL | judgment_x19_test, dialogue_perspective_test | every run | gossip tellings, beliefs, lies shown false | — | the chain to a later decision | `social_chain` scenario and the chain trace (section 5) |
| 19.8 | Memory formation, decay, forgetting, permanent memories | 19 | ACTIVE | SJD-Q11, X19-DECAY | judgment_test, judgment_decay_demo | every run (decay only visible in long runs) | formation only; **fading, forgetting, retirement not** | memory decay unverifiable from the archive | long run: memories forgotten, facts retired, permanent kept | `forgot` events per forgotten memory; daily `judgment_day` event (stats moved: forgotten, expired, kept_permanent, ...) |
| 19.9 | Resentment, grievances, betrayals, reconciliation (bonds) | 19 | ACTIVE (softening shipped at 0) | X19-FOUND-BONDS | judgment_bonds_test | every run | none | grievances and betrayals unrecorded | — | `grievance` and `betrayal` events |
| 19.10 | Negotiation and trade preferences (13 decision domains) | 19 | ACTIVE | SJD-E, SJD-F, X19-SCOPE | judgment_live_test (20: one per domain) | every run | every weighted choice in full (REC-STORE) | — | — | — |
| 19.11 | NPC reactions to crimes; criminal reputation; guard response | 19/20 | ACTIVE | DVW-B2, GP-CRIME-PURSUIT, FIX-D3 | justice_test, manhunt_test, pursuit_test, judgment_guard_save_test | crime scenario; probes pursuit and manhunt | witness, guard, alarm, report, robbery, chases | — | — | — |
| 19.12 | NPC choices that differ by personality or experience | 19 | ACTIVE | B19-EMERGE, WDR-009-C | judgment_test test_need_vs_opinion, judgment_live_test | every run | choices with factors | no automated check that similar situations got different answers | analysis: choices of the same profile with different chosen options | verifier `choice_diversity` measure per profile |
| 19.13 | Save/load of memory and relationships | 19 | ACTIVE | FIX-D1D2, X19-SCOPE | judgment_guard_save_test, save fixtures | probe_saveload | world_loaded | — | — | recorded save/load probe |
| 19.14 | Crime from desperation | 19 | APPROVED-NI (DEFERRED) | FR-09 | — | — | — | — | — | — |
| 19.15 | Personality, prestige and migration (owner list) | 19 | APPROVED-NI (OWNER DECISION REQUIRED) | FR-11 | — | — | — | — | — | — |

## 4. Expansion 20 (aspirations, Living Economy foundation, multiplayer and the release fixes)

| # | Feature or system | Exp. | Status | Owner-approved behaviour | Automated tests | Simulation (before) | Recorder (before) | Missing coverage | Required additional verification | Closed on `wip/x20-recorder` |
|---|---|---|---|---|---|---|---|---|---|---|
| 20.1 | NPC aspirations, six domains, changing priorities, survival pressure, household hardship | 20 | SWITCH `judgment.json aspiration.enabled` (false) | WDR-011-C, R5 | aspiration_test (16) | **none in the gate** (R5 measurement runs only) | aspiration events and choice factors, when on | never exercised by the gate | flags-on scenarios, recorded, with on/off neutrality | `x20_on_s1` (30 days) with its unrecorded twin, `stress_on`, `social_chain` all with `--aspiration --job-choice --economy` |
| 20.2 | Aspiration job choice | 20 | SWITCH `aspiration.job_choice` (with the layer on) | WDR-011-C (FAD Q2 PROVISIONAL weights) | aspiration_test | none | choice factors when on | as 20.1 | as 20.1 | as 20.1 |
| 20.3 | Individual proposal preferences (WDR-011-Q8 A) | 20 | SWITCH (aspirations on only) | WDR-011-Q8 | aspiration_test | none | none (proposals unrecorded) | as 20.1 + proposals | proposals with the reason refused | `proposal` events with outcome and reason |
| 20.4 | Player/NPC equality rules (proposals, contracts, D39, Rule 012) | 20 | ACTIVE; the proposal-equality fix is in progress on another branch (X20-FINAL phase 1) | X20-FINAL, D39, WDR-012 | relations_test, contracts_test | normal village (NPC side only) | — | player-side proposals | after the fix: the same rules for both sides, recorded | `proposal` / `court_ask` events record suitor kind (player or villager) |
| 20.5 | Living Economy LE-01 foundation (actors, needs, offers, reservations, knowledge, contract links) | 20 | SWITCH `economy.json enabled` (false); observes only when on | LE-01, E20-P1, FIX-D1D2 | economy_foundation_test (12), economy_model_test (14) | **none in the gate** | none; session flags wrongly said "no such flag" | integrity (unbacked reservations) never checked in a run | flags-on scenarios; unbacked count 0 | daily `economy_model` event (counts, unbacked reservations, links); session flags name the real switches; verifier fails a run whose recorded flags differ from its scenario's |
| 20.6 | LE-02..LE-07 (adaptive prices, production and budgets, finance, ecology links, long-run, release) | 20 | APPROVED-NI | LE-02..LE-07, EXP-D | — | — | — | — | not to be invented (directive 2.4) | — |
| 20.7 | Inventory and currency integrity under Expansion 20 | 20 | ACTIVE | WDR-022 | conservation_test | every run | coin audit | flags-on runs never checked | flags-on ledgers | flags-on scenarios check the same ledgers |
| 20.8 | NPC judgment integration with aspirations (standing, career satisfaction factors) | 20 | SWITCH (with 20.1) | WDR-011-C | aspiration_test | none | factors when on | as 20.1 | as 20.1 | as 20.1 |
| 20.9 | Generational memory and history (the 30-planks chain) | 20 | ACTIVE | GM-01 | history_test (3) | every run (rare) | none | history records unrecorded | — | `history` events |
| 20.10 | Multiplayer: host-owned world, synchronization, network messages | 20 | ACTIVE (LAN) | MP Batch A-C, MP-D1..D8 | multiplayer_a1/b/c_test, net_g1/batch_b/c/fauna/family_test (separate processes) | **none** (no black-box run) | **none** | joins, leaves, requests, syncs, participant state unrecorded | 1 host + 2 guests and 1 host + 3 guests on the net harness, recorded, with participant digests compared | net hooks (host and guest) and an hourly `net_state` digest per participant; `tools/recorder_archive.py --participants` compares them; recording in the harness by the `MML_RECORD` environment variable (no change to the harness) |
| 20.11 | Multiplayer player interaction (MP-INTERACT-01) | 20 | ACTIVE on `87b69ab` (merged last) | MP-INTERACT-01 | net_interact_test, mp_interact_ui_test | none | none | as 20.10 | as 20.10 + device checks | `net_request` events name each player action and its result |
| 20.12 | Multiplayer save/load, disconnect and reconnect, time stopping without the host | 20 | ACTIVE | MP-D1, MP Batch B | net_batch_b_test, multiplayer_b_test | none | none | — | net harness | `net_join` / `net_leave` / `net_host_lost` events |
| 20.13 | Players' families (MP-PLAYER-FAMILY) | 20 | ACTIVE | MP-PLAYER-FAMILY | player_family_test, net_family_test | none | births and partnerships (life) | — | — | — |
| 20.14 | Bandit stalk (SIM-F3) and chisel re-decision (SIM-F2) fixes | 20 | APPROVED, in progress on another worker's branch (not on `87b69ab`) | SIM-F2, SIM-F3 | — | — | decisions show the loops (empty decisions, repeated choices) | — | after integration: the recorder counts of re-decisions | verifier `redecisions` measure (empty decisions per actor-day, repeated identical choices) |
| 20.15 | Gameplay polish batch (input, HUD, Android, wiki, lockpick, stalls...) | 20 | ACTIVE (player-facing), GP-POLISH umbrella PARTIAL | GP-* records | ui and shot tests | — | player verbs | — | device playtests (register `playtest`) | — |
| 20.16 | The flight recorder and gate themselves | 20 | ACTIVE (off as shipped; desktop setting) | REC-19, REC-STORE, SIM-GATE-01, REC-DIAG | recorder_test, tests/test_sim_gate.py | every recorded gate run | — | — | — | verifier extensions (section 5) |
| 20.17 | Judgment Gates G (soak) and H (owner review) | 20 | APPROVED-NI | SJD-G, SJD-H | — | — | — | — | the long runs of section 6 are the soak's evidence | — |
| 20.18 | Permanent employment by the player | 20 | APPROVED-NI | EMP-PERM-01 | — | — | — | — | — | — |
| 20.19 | Expansion 21+ and the open-items list | 20+ | FUTURE | X20-OPEN-ITEMS (record only) | — | — | — | — | — | — |

## 5. Verification added by this branch (what checks the 15 points)

`tools/recorder_archive.py` (independent, standard library only) now also checks, for every archive: event ids 1..N each once;
every `parent` and every participant, decision, alternative, factor, state_change and link row naming a recorded event; life transitions
(nobody acts, decides, trades or is born again after their death; role changes only child -> adult -> elder); job transitions (each
change starts from the last recorded job); contract transitions (open -> deliveries -> one end; nothing after the end; coins set aside
and returned balance); the recorded flags against the scenario's required flags; the hourly snapshots (counters never fall, values in
range); and it counts each system's events against the rows above (`exercised`), so a required system with no event is a finding.
`--participants A B ...` compares multiplayer participants' `net_state` digests hour by hour. `tools/sim_suite.py` reads those results:
an invalid transition, a flags mismatch or a required system not exercised blocks the gate; the counts go in `gate.json`.

## 6. Still open after this branch

- Business tills, stalls, property and construction coin movements are still detected by the hourly audit, not attributed (the audit
  names holder and amount; the world total balances).
- Courier deliveries are counted (stats) but not events; capability multipliers per unit are not recorded.
- Ledger decay is applied lazily when an entry is read, so it is visible in the values each choice reads, not as its own rows.
- Multiplayer black-box runs need the net harness (owned by the network worker) started with `MML_RECORD`; nothing here runs them.
- Physical-device checks (touch, controller, two devices on a LAN) stay in the register's `playtest` field.
