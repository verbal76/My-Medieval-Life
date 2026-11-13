# Prerequisites for REG-04, REG-05, MP-02 and JOB-02 (investigation, no implementation)

Written 2026-11-12 for the owner's chain 12 direction (`docs/directives/2026-11-12_build39_chain12_direction.md`: "Investigate
prerequisites for REG-04, REG-05, MP-02, and JOB-02 without bypassing owner decisions") and the 2026-11-10 direction ("For
larger systems, including REG-04, REG-05, MP-02, MP-07 and JOB-02, prepare implementation dependencies and test plans before
coding", `docs/directives/2026-11-10_phantom_repair_decisions_69_tracker.md`). Code read at `wip/b25r2-rev2` `b3c9eb5`;
register read on `wip/requirements-control` `518a7a1`. Nothing here is implemented, and nothing here answers an owner
question: section 6 lists them as questions.

Status of all four (register and `docs/audits/B25_69_ITEM_TRACKER.md` rows 45, 46, 55, 67): approved (REG-04, REG-05,
JOB-02) or audit-confirmed (MP-02), **not started**. No branch holds work on any of them (`git branch -r`: the only
related branches, `wip/b18-couriers`, `wip/b18-courier2`, `wip/b18-migration` and `wip/x20-migrate`, are the original
abstract systems, already merged).

## 1. MML-REG-04: couriers travel physically

### Owner decision and source
- Register `B25-AUD-REG-04` (OWNER APPROVED, owner 2026-11-08), acceptance: "a living carrier on real road legs; no double
  delivery; save/load; conservation".
- `docs/directives/2026-11-09_overnight_autonomous_development.md` line 61: "REG-04: Couriers physically travel."
- Full text, `docs/directives/2026-11-08_recovered_owner_messages.md` lines 1135-1157 ("REG-04 — Couriers physically
  travel"): "Couriers must physically travel between locations. A delivery cannot be completed merely because an abstract
  elapsed-day counter reaches its destination while its carrier remains somewhere else. Reuse the existing physical journey
  and road systems wherever possible. One courier cannot simultaneously occupy several different routes. The system must
  account for: Actual road movement. Departure and arrival. Cargo ownership and conservation. Carrier capacity. Interrupted
  trips. Death and hazards. Save/load continuity. Returning to the origin. Multiple legitimate deliveries on a single
  physical journey. Do not replace one unrealistic abstraction with another hidden abstraction." Lines 1336 and 1348: "The
  existing journey systems can support real physical travel, but carrier movement, cargo, route occupancy, and actual arrival
  events must be connected correctly"; "Coordinate REG-04 and REG-05 carefully because both depend on physical travel and
  identity continuity. Avoid creating duplicate travel architectures."
- Audit origin: `docs/audits/2026-11-08_INDEPENDENT_AUDIT_OPEN_ITEMS_v14.md` MML-REG-04 (Audit 009): "NPC courier deliveries
  advance abstractly by elapsed days, while named villager couriers stay in village and may nominally serve overlapping jobs."
- Responsibility note: the 2026-11-08 message says "ChatGPT retains responsibility for implementing and individually testing
  these corrections" (MP-07, REG-04, REG-05); see question R4-Q1.

### Current code paths
- `game/scripts/core/settlement/couriers.gd` (`CourierService`, 1528 lines):
  - `tick(day)` (831): routes depart on `next_day`, then each job moves by day number alone: `in_transit` → `_arrive` when
    `day >= arrive`; `returning` → `_home` when `day >= back`. The courier never moves; only `alive(courier)` is checked.
  - `_depart` (893): goods leave the booth's store into `j.cargo`; `arrive = day + r.days`. Every job waiting on the route
    leaves at once with the same keeper, so one keeper is on several routes at the same time (the audit's finding).
  - `_arrive` (913) and `_home` (1002): the hand-over, the collection, notary signing (`formal().sign_before_notary`), the
    escrow release; REG-03 heir/estate return (owner 2026-11-12) inside `_home`.
  - `_expire` (857): REG-08 timeout (owner 2026-11-12), 7 days at the booth.
  - `interrupt` (1088), `_drop_load` (1124): a dead courier's load becomes a loot pile.
  - `capacity` (517): `TradeRoutes.capacity` from the household's handcarts; `journey_days` (531): from `links` (the
    settlements' miles), 0.25 days within one place; `quote` (546) prices the fee from those days.
  - `spoil_day`, `_spoiled_terms` (1149, 1212): INV-02 F3 spoilage on the road (behind its off switch), driven by days carried.
  - `daily` (1285), `villagers_post` (1371): villagers' own postings by the regular route.
- Callers: `World` (`world.gd:499` `couriers.step()` hourly; `:310`, `:590` `couriers.daily()`); `main.gd:3530`.
- Carriers today: the village booth's keeper (a live villager, `npc:<id>`), shop-booth routes carried by the village keeper,
  and each settlement's trader party (`region:<id>/trader`, off-map).
- Travel systems to reuse (one architecture, shared with REG-05):
  - `game/scripts/core/journeys.gd` (`Journeys`): a live villager walking to a settlement and back by road
    (`start`, `resume`, `leg_done`, `end`, `night_and_food`, `provision`); saved as the optional NPC key `journey`; the route is
    a pure function of the seed. Precedent: envoys are manor jobs that start a journey
    (`settlement/envoys.gd:87, 107, 153`), and `World.journey_hook` (`world.gd:128, 182`) runs the purpose at the site.
  - `game/scripts/core/settlement/trips.gd` (`SettlementTrips`): an off-map settlement person's walk (one saved trip record,
    pack and coins on it, `Presence.road_tiles` pace, rest 20:00-06:00), with `SettlementPeople` (`people.gd`) turning the
    record into a live NPC in view and back (materialise and fold).
  - Route hazards: `EconRouteRisk` (`_note_carried` records the value carried).
- UI and network: `game/scripts/ui/courier_window.gd`; guest verbs `couriers.book_route`, `couriers.negotiate`,
  `couriers.book_special`, `couriers.open_shop_booth` (`net_actions.gd` VERBS, C3).
- Manifest: `docs/SYSTEM_INTERACTION_MANIFEST.md` INT-271, INT-280..283, INT-320, INT-322 describe the abstract behaviour and
  need updating with the change.

### Dependencies
- REG-03 and REG-08 (owner 2026-11-12, `b0d9cca`, merged in chain 12): their code sits in `_home` and `_expire`, and stays.
- REG-05 must use the same travel pieces (owner: no duplicate travel architecture). Build the shared piece once (a carrier or
  migrant purpose on `Journeys` for village people, a trip purpose on `SettlementTrips` for settlement people).
- INV-02 F3 (spoilage on the road, off switch): the days carried become the walked days.
- X18-Q13 notary signing on arrival: needs a real arrival event.
- `Journeys` food and night rules (`provision`, `buy_food`): who pays the carrier's food (question R4-Q6).
- Booth keeping (the keeper is away while walking), courier booth stalls (`Stalls`), shop booths.
- Living Economy and regional ledgers: `Regions.audit`, the village ledgers (`imported_*`, `exported_*`, `coin_sources`).

### Save format
- Today: the optional World key `couriers` (`mml-couriers-world/1`) holds jobs with `state`, `depart`, `arrive`, `back`,
  `cargo`; the NPC key `journey` holds a walk. SAVE_VERSION is 23.
- The change adds a link from a job to its walker (and a trip or journey purpose naming the delivery or deliveries) and drops
  the meaning of `arrive`/`back` as completion days. A save made mid-journey must load with the walker where it was.
- **Migration needed:** saves with jobs `in_transit` or `returning` and no walker (every save made before REG-04). Options
  are an engineering choice except where they change play (question R4-Q5).
- **Version bump: likely needed.** An older build opening a REG-04 save would complete walked deliveries by their old day
  numbers while the walker also travels; refusing older builds (as save 22 and 23 did) avoids that. Bump the courier
  format to `mml-couriers-world/2` as well.

### Simulation and baseline impact
- Large: delivery times, regional trade flows, booth keepers' working days and villagers' postings all change, so the 365-day
  results and the gate's fingerprint change. The owner's rule (2026-11-08 message): "investigate differences against the
  accepted baseline before proposing any new baseline. Do not automatically regenerate or accept simulation baselines."
- The chain 12 baseline is itself awaiting the owner. Landing REG-04 on top of an unapproved baseline would mix two sets of
  differences (question G-Q1).

### Test strategy
- Focused (new `reg04_courier_walks_test`): a delivery completes only when the carrier's position reaches the recipient;
  the carrier is on one route at a time; several deliveries on one walk; capacity respected; return to origin; carrier
  killed mid-road (load where they fell, escrow back, REG-03 estate rule); road closed (turned back); save at each leg and
  reload (position, cargo, state continue); conservation of goods and coins at every step (the existing ledgers).
- Regression: `courier_test`, `courier_live_test`, `courier_desk_test`, `reg03_courier_sender_dies_test`,
  `reg08_stranded_route_job_test`, `journey_test`, `journey_s3_test`, `envoy_test`, `region_trade_test`, `regions_test`.
- Guest path: a guest's booking still works (`net_c_test`-style), and the walker is seen by guests (snapshot).
- Gate and one 365-day four-seed campaign; the baseline difference investigated and presented to the owner.

### Rough size
Large. Changes in `couriers.gd` (tick, depart, arrive, home, interrupt, quote), a courier purpose in `Journeys` and in
`SettlementTrips`, save migration, wiki (courier pages) and manifest entries, 1 new test suite of about 30-50 checks, plus
the gate and campaign. Several days of focused work; it should go before REG-05, which reuses its pieces.

## 2. MML-REG-05: migrating households travel physically

### Owner decision and source
- Register `B25-AUD-REG-05` (OWNER APPROVED, owner 2026-11-08), acceptance: "arrival-triggered adoption; one journey system
  shared with REG-04; PROP-06 settlement where the walk starts".
- `docs/directives/2026-11-09_overnight_autonomous_development.md` line 63: "REG-05: Migrating households physically travel."
- Full text, `docs/directives/2026-11-08_recovered_owner_messages.md` lines 1159-1186 ("REG-05 — Households physically
  migrate"): "Migrating villagers and households must physically travel between settlements. They cannot instantly disappear
  from one settlement and appear in another. Preserve: Individual identities. Family and household membership. Carried
  possessions and coins. Property ownership and previously approved surrender rules. Physical location during travel. Aging
  and mortality. Interrupted journeys. Save/load continuity. Economic conservation. Population transfers must occur at
  appropriate departure and arrival points. Reuse existing "Journeys", "SettlementTrips", "SettlementPeople", and regional
  systems as appropriate." Line 1338: "Converting this into physical travel requires persistent in-transit records and proper
  departure/arrival transactions, not merely a cosmetic walking animation."
- PROP-06 directive (`docs/directives/2026-11-08_prop06_estate_tenancy_migration.md` section 6): "Property liquidation should
  occur at the appropriate actual departure point, not when a household merely considers migrating. An interrupted or
  cancelled departure must not leave an unintended completed property settlement."
- Audit origin: v14 MML-REG-05 (Audit 009): "Household migration is immediate on a caravan day, not physically walked."

### Current code paths
- `game/scripts/core/settlement/migration.gd` (`Migration`, 1034 lines). Its header says so: "a move is immediate on the day
  ... (provisional; the road itself is not walked)".
  - `visit(w)` (60), called on caravan visit days from `npc_brain.gd:5608`; `_try` (74) per reason (hunger, work, land,
    marriage) and direction.
  - Out (village → settlement): `_hunger_out` (659), `_work_out` (688), `_land_out` (745), `_marry_out` (977) →
    `_household_out` (643) → `_pre_leave` (141: quests, contracts, rentals, repairs), `_settle_departure_property` (167, PROP-06
    atomic sale and surrender, with `_snapshot`/`_restore`; its comment: "REG-05's physical departure must call it at the start
    of the walk"), `_pack` (121), `_take_own` (321), `_gone` (354: the NPC stays in `World.npcs`, not alive, `away` set), then
    the settlement's `receive_person`/`receive_household` at once.
  - In (settlement → village): `_work_in` (789), `_hunger_in` (862), `_household_in` (887), `_land_in` (916), `_marry_in`
    (1009) → `_villager` (418) or `_reactivate` (447) makes the villager at once; `_house` (512), `_place` (559), `_settled`
    (582), `_arrived` (494).
  - `_book` (392): the boundary ledgers and the `migrants_in/out` counts.
- The physical precedent already in the game: a runaway (B25R1-014) walks by `Journeys` to a settlement and, on arrival,
  `LifeDecisions.at_site` (`life_decisions.gd:400`) calls `Migration._pre_leave`, `_pack`, `receive_person` and `_gone`:
  one person, arrival-triggered. REG-05 generalises this to households and both directions.
- Settlement side: `SettlementTrips` (trips.gd) and `SettlementPeople` (people.gd) for settlement people on the road.
- REG-02 (merged): a migrant's journey and trade credit are resolved at departure (`reg02_journey_migration_test`).
- BIZ-04 (merged): a household keeps its business money when it migrates (`biz04_venture_till_migration_test`).

### Dependencies
- REG-04's travel pieces (build those first, then reuse).
- PROP-06 (merged `96b071c`): the property settlement moves from "the move" to "the start of the walk".
- REG-02 debt rule (owner option (b), `3bb486d`): when it applies during a walk (question R5-Q7).
- Household and family records (`World.households`, `Life`), aging and death on the road (`Life` daily steps must reach
  people in transit), the census and reports (who counts where during the walk: question R5-Q6).
- Housing on arrival (`Construction._home_plan`, `_house`), village vacancies (`open_vacancies`), settlement household
  formation (`OffMapSettlement.receive_household`).
- Multiplayer: migrating villagers become visible walkers that guests receive in snapshots.

### Save format
- New in-transit state: a migrating party (members, household, goods, coins, from, to, leg, since). Village-side people stay
  live NPCs with a `journey` purpose; settlement-side people a trip record; members' household links kept.
- No data migration of old saves is needed (every move in an old save is already finished).
- **Version bump: needed.** An older build opening a save with a household on the road would read an unknown journey purpose
  and send the walkers home again after their property was sold at departure, or lose the party record. Refuse older builds.

### Simulation and baseline impact
- Large: moves take days instead of happening at noon on a caravan day; population counts, households, housing and jobs at
  both ends shift in time. Gate fingerprint and every 365-day measure change. Same baseline procedure as REG-04.

### Test strategy
- Focused (new `reg05_household_walks_test`): departure only at the start of the walk (PROP-06 settlement at that point);
  every member, item and coin conserved from departure to arrival; arrival hands over to the destination (both directions);
  death on the road (estate by the existing rules); road closed or turned back (question R5-Q4); save and reload
  mid-journey; ageing during the walk; household and family links intact; no person counted twice or nowhere.
- Regression: `migration_test`, `emigration_marriage_test`, `prop06_migration_property_test`, `reg02_journey_migration_test`,
  `biz04_venture_till_migration_test`, `journey_test`, the runaway tests, `region_sim_test`, `regions_test`.
- Gate and one 365-day four-seed campaign; baseline differences investigated and presented.

### Rough size
Large, larger than REG-04: two directions, group travel, the in-transit record, PROP-06's timing, the census. About as much
code again as REG-04 on top of the shared pieces, one new suite of about 40-60 checks, wiki ("settlements", migration pages),
manifest entries and the save bump.

## 3. MML-MP-02: guest stall and shop management has no mirror paths

### Owner decision and source
- Not an owner policy item: a code-supported audit finding. `docs/audits/2026-11-08_INDEPENDENT_AUDIT_OPEN_ITEMS_v14.md`
  MML-MP-02 (Audit 011, MEDIUM): "Guest stall/shop UI management methods—including arrears, collect/deposit/withdraw till,
  close, listing/unlisting, fetching stock and workroom stock/fetch—may change only the guest's local copy because they lack
  `w.mirrors()` dispatch and `NetActions.VERBS` registration."
- Owner authority to fix: `docs/directives/2026-11-10_phantom_repair_decisions_69_tracker.md` (prepare dependencies and test
  plans before coding) and the chain 12 direction (investigate prerequisites). The applicable owner rules are the existing
  multiplayer decisions: the host validates every action (Batch C, MP-03), MP-05's sharing tiers, MP-D1.
- There is no register entry with this id (tracker row 55 only); the lead may add one.

### Current code paths (confirmed at `b3c9eb5`)
The stall window (`game/scripts/ui/stall_window.gd`, opened from `game_ui.gd:4349`, `fit_window.gd:33, 39`, `main.gd:267`)
calls these on the guest's copy. Mirrored today (`w.mirror`, in `NetActions.VERBS`): `business.rent`, `set_price`,
`upgrade`, `set_display`, `open_shop`, `store_item`, `hire`, `build_storefront`, `open_front`. **Not mirrored**, so on a
guest they change only its own copy, which the host's next sync overwrites:

| Function | File:line | Host-side check today |
|---|---|---|
| `Business.list_item` | `business.gd:648` | `is_mine` |
| `Business.unlist` | `business.gd:669` | none (no `is_mine`) |
| `Business.collect` | `business.gd:700` | none |
| `Business.deposit` | `business.gd:713` | none |
| `Business.withdraw` | `business.gd:724` | none |
| `Business.close` | `business.gd:739` | none |
| `Business.pay_arrears` | `business.gd:821` | none |
| `Business.fetch` | `business.gd:953` | none |
| `Business.dismiss` | `business.gd:1066` | none (no `actor` parameter either) |
| `Stalls.open` / `Stalls.close` | `stalls.gd:266, 244` | `open_refusal(s, ref)` for open; none for close |
| `BusinessWorks.add_order` / `cancel_order` | `business_works.gd:115, 125` | `order_refusal` for add; neither has an `actor` parameter |
| `BusinessWorks.stock_work` / `fetch_work` / `shelve` | `business_works.gd:134, 149, 167` | `is_mine` for stock_work only; none for fetch_work and shelve (shelve has no `actor` parameter) |

Most already take an `actor` parameter and call `w.as_actor`, so the host side half exists; the ownership checks are
missing because the host's own interface only ever showed the host's own stall. A guest verb must not be added without them
(the MP-03 rule: a forged request names someone else's stall).

### Dependencies
- MP-03 store authorization (merged `93bb304`, public tables and property rules `9fd18a5`): the decoding and reach rules a
  new verb uses.
- MP-01 (guest-owned shops get NPC customers, merged `f0a854c`), TRD-01 (guest stall settle), MP-06 away rule
  (`AWAY_VERBS`: these are not away verbs), MP-05 (whether a sharing partner may manage: question M2-Q2).
- `NetActions.VERBS` and `World.mirror` (`world.gd:987-998`); `NetSync` sections that carry stalls back to the guest.
- Protocol: new verbs change what a host accepts; bump `NetProtocol.VERSION` to `mml-net/6` so mixed builds are refused
  clearly (both devices need the same build in any case).

### Save format
None: the stall and shop records are unchanged; only who may change them over the network.

### Simulation and baseline impact
None for single-player and the gate's simulation (guest-only path). The determinism fingerprint should be identical; if it is
not, that is a defect in the change.

### Test strategy
- New `mp02_guest_stall_management_test` (host and guest processes, the `net_c_test` pattern): each of the 16 actions from a
  guest changes the host's world exactly as the host's own action would (coins, goods, wear pools, till, stats), and the
  guest's copy agrees after sync.
- Forged requests (the `mp05_forged_client_test` pattern): another player's stall, a villager's stall, an amount above the
  till, out of reach, while away: each refused with no change.
- Regression: `business_test`, `business_works_test`, `stalls_test`, `stall_putup_test`, `stall_rent_pitch_test`,
  `mp01_guest_stall_attendance_test`, `trd01_guest_stall_settle_test`, `mp03_*`, `mp06_*`, `net_c_test`.
- Device check: added to `docs/release/MULTIPLAYER_HARDWARE_TEST_PROCEDURES.md` once built (a guest runs its stall).

### Rough size
Medium. About 16 mirror stubs, the missing ownership and reach checks, a protocol bump, two test suites (about 40-60 checks),
a wiki line that guests manage their stalls as hosts do. One to two days.

## 4. MML-REQ-JOB-02: offered compensation on the manor job board

### Owner decision and source
- Register `JOB-02` (OWNER APPROVED, owner decision REC-013 Q4, 2026-10-21; parent `REC-013`), owner wording: "Replace the
  long-term fixed-wage design with offered compensation that workers can accept or reject." Acceptance: "Offers respond to
  labour availability, competing work, demand, duration, difficulty and skills, travel, market conditions and the manor's
  funds"; "Workers may decline; the manor may raise offers; no guaranteed hiring"; "Today's fixed per-job rates are
  provisional starting offers only". Its `next_action`: "Design the smallest safe path (e.g. workers compare the posted pay
  with their own trade's earnings, CON-01's opportunity rule) and propose its build".
- Full text, `docs/directives/2026-10-21_build17_rec013_final_decisions.md` section 5 ("REC-013 Q4 — OFFERED COMPENSATION AND
  WORKER CHOICE"), including: "Each funded job posting offers compensation. Eligible workers evaluate whether the offered
  payment is worthwhile and decide whether to accept." "Do not assume that every factor requires a new numerical subsystem."
  "Workers must not automatically accept every available job." "The manor may need to increase its offer to attract a
  worker. A job may remain unfilled if no suitable worker is willing to accept its terms." "Before a job is funded, the manor
  must have a legitimate source of money." "paid work quests are paid in full upon successful completion or not paid at
  all". "Do not automatically pay an additional job-board wage to salaried manor hands." "Preserve CON-01 negotiated
  procurement contracts as their own legitimate commercial arrangements." "Do not treat 2 coins per haul, 4 coins per repair,
  6 coins per quarry task, or 6 coins per four-hour day as immutable universal wage rules." "Evaluate the current job-board
  implementation and identify the smallest safe integration path. Do not rewrite the entire labor economy merely to close
  REC-013." Section 6 adds: no forced acceptance, determinism, save compatibility.
- Related owner decisions that constrain it: `X18-D6` (APPROVED, "Option 2, wage set at acceptance": a posted wage is fixed
  when taken, at the taker's level); `Q18-11` (no settlement-wide pay multipliers; individual skills shape pay); `OD-LE-03`
  D02 answer C ("Existing wage and hiring rules remain intact ... Broader negotiated wages and services are layered into
  LE-03 behind flags; do not replace functioning pay or invent universal wages").
- Audit row: v14 MML-REQ-JOB-02 ("Confirm current requirements/decision register and actual current branch before calling
  missing approved functionality"): confirmed here, still not started.

### Current code paths
- `game/scripts/core/manor_work.gd` (`ManorWork`): jobs posted with a fixed base `wage` from `GameData` (`haul_wage`,
  `mend_wage`, `quarry_wage`, discovery `survey_wage`/`trial_wage`, `excavate_wage`, clearing `lc.wage`) in `refresh` (216),
  `post_quarry` (262), `post_clearing` (275), `post_paving` (312), `post_discovery` (339), `post_pits` (362),
  `post_tunnels` (386), `post_shore` (504); envoys post through `_post` too (`envoys.gd:87`).
  - `wage_for` (614): the base, skill-adjusted (`CapabilityHook.pay`, mend and quarry), then `EconMarket.wage_bargain`
    when `market.negotiated_wages` is on (shipped **off**, `game/data/economy.json:71`).
  - `can_fund` (630): the treasury keeps `manor_job_reserve_days` of obligations after the wage.
  - `open_for` (640), `_rank` (662): the open jobs, most needed first.
  - `take` (720): reserves the wage from the treasury (staff take it unpaid); mirrored for guests (`manor_work.take`).
  - `seek` (1449), `seek_kind` (1428), `reeve_fallback` (1441, LOG-01): **a villager takes the first open job it can do;
    nobody declines** (the gap JOB-02 names).
  - `_finish` (1267): paid in full on completion; `release` (745) returns the wage; `dawn` (1291) releases stale jobs.
- `EconMarket.wage_bargain` (`economy/econ_market.gd:1226`, LE-04 behind the off flag): a comfortable worker asks up to
  `wage_max_factor` (1.25) x the wage; a needy one takes the wage; an unaffordable ask means the job is not taken. The same
  rule serves `Employment.asking` (`employment.gd:128`) and building helpers (`construction.gd:334`). Tested by
  `le04_test` `test_negotiated_wages`. This is the nearest existing mechanism, but it is not a worker choice between jobs.
- Who calls `seek`: `NPCBrain` day planning (manor hands, labourers, and since EMP-06, 2026-11-12, the unemployed when short of
  food: `emp06_unemployed_day_labour_test`).
- UI: the job board in the manor window; guests take jobs through the mirrored `manor_work.take`.

### Dependencies
- BIZ-03 payroll priority (merged), EMP-03 seeker counting (merged), EMP-06 day labour (merged in chain 12): the labour
  market JOB-02 prices against.
- `Employment.market_wage` and NPC income history (`avg_income`, `income_days`): a worker's own alternative earnings.
- `JudgmentLive.coin_need`: need, already used by `wage_bargain`.
- Treasury rules (`daily_obligations`, `manor_job_reserve_days`), LOG-01 reeve fallback, salaried hands (REC-013 Q3).
- CON-01 contracts stay separate (owner).
- The Living Economy flags (`market.drive`, `negotiated_wages`): whether JOB-02 builds on them (question J2-Q6).

### Save format
- Today `ManorWork.to_dict` (1503) saves each job with its `wage`, `taker`, `day`, `reserved`.
- JOB-02 would add per posting: the current offer, when it was last raised, and possibly who declined it (for the raise
  rule). As optional keys with defaults (absent: the offer is the old `wage`), an older save loads unchanged and no data
  migration is needed. A version bump is needed only if an older build would misread the new fields (for example if `wage`
  stops meaning the amount to reserve); keeping `wage` as the current offer avoids that.

### Simulation and baseline impact
- Large: who works, when, for how much and how much stays in the treasury all change, across every 365-day run. Unfilled jobs
  (hauls, mends, relief deliveries) delay repairs and relief, which feed food, roads and decay. Owner WDR-022: measure the
  outcomes (employment, unfilled jobs, treasury), never pass/fail thresholds unless a requirement sets one.
- Urgent relief must stay protected (REC-013 Q2: `deliver_now` for a household under a day of food), otherwise an unfilled
  relief haul could starve a household: a gameplay consequence to keep in view, not a rule to invent.
- Shipping behind an off switch first (as LE-04 and INV-02 did) would keep the current baseline until the owner compares
  runs (question J2-Q6).

### Test strategy
- Focused (new `job02_offered_pay_test`): a worker declines an offer below its alternative; the manor raises an unfilled offer
  by its rule; the job stays unfilled when nobody accepts; an offer is funded before it is taken and never above the
  treasury rule; paid once, in full, on completion; salaried hands get no extra pay; CON-01 untouched; deterministic for a
  seed; save and reload mid-offer.
- Regression: `job_board_test`, `le04_test`, `emp03_seeker_count_test`, `emp06_unemployed_day_labour_test`,
  `skilled_employment_test`, `health_jobs_test`, `envoy_test`, the mining job tests.
- Gate and a 365-day four-seed campaign with and without the feature (if switched), measurements reported, baseline
  differences presented to the owner.

### Rough size
Medium to large, mostly decided by the answers to section 6. The smallest path the register suggests (workers compare the
posted pay with their own trade's earnings; an unfilled offer rises each day it waits, within the treasury rule) is a change
in `seek`/`open_for`/`wage_for` plus a daily raise step and save fields: about one to two days with tests, then the
campaign. Covering employment and building helpers too is larger.

## 5. Cross-cutting

- **Order** (from `docs/audits/B25_69_REMAINING_WORK_PACKAGES.md` WP-4 and the dependencies above): MP-02 (no simulation
  change, can go now), then REG-04, then REG-05 (reuses REG-04's pieces), JOB-02 independently. REG-04, REG-05 and JOB-02 each
  change the simulation and so the baseline; one at a time keeps each difference attributable.
- **DCR-01 classification** (CLAUDE.md section 9): REG-04 and REG-05 are intentional revisions of approved Expansion 18
  behaviour (REG-COURIER-01's day-counted journeys; MIGRATE-18's "immediate on the day, provisional"), approved by the
  owner; JOB-02 is an intentional revision of the fixed rates, approved, constrained by X18-D6 and OD-LE-03 (question J2-Q2);
  MP-02 is a compatible correction.
- **Documentation with each:** the wiki pages for couriers, settlements and migration, the job board and multiplayer, and the
  manifest entries (INT-271, INT-280..283, INT-320, INT-322 for couriers; the migration INT entries; a new one for guest stall
  verbs), in the same change (WIKI-01).

## 6. Questions for the owner (not answered here)

General
- **G-Q1.** The chain 12 baseline is awaiting your approval. Should REG-04, REG-05 or JOB-02 (each changes the simulation and
  the baseline) be started only after that baseline is decided, or may work begin now on branches and wait for it before
  merging?
- **G-Q2.** Should REG-04, REG-05 and JOB-02 first ship behind an off switch (as LE-04 and INV-02 did), so the accepted
  baseline stays until you compare runs with the switch on and off?

REG-04 (couriers)
- **R4-Q1.** The 2026-11-08 message says ChatGPT implements MP-07, REG-04 and REG-05 and Claude integrates. MP-07 has since
  been implemented by the lead's workers. Are Claude's workers authorised to implement REG-04 and REG-05 too?
- **R4-Q2.** Must the settlements' own couriers (the trader parties, off-map) walk as well, using the settlements' trip
  system, or only the village's courier?
- **R4-Q3.** A delivery inside the village (a special delivery to someone in the same place, today a quarter day): must the
  courier walk it across the village too?
- **R4-Q4.** One keeper carries the routes to all five settlements. While walking, they cannot be on another route or at the
  booth. Is it acceptable that routes then leave later than their schedule (every N days) and that the booth is unattended
  while the keeper is away, or should a booth have another way to be kept?
- **R4-Q5.** Saves made before the change may hold deliveries already on the road (by day count, with no walker). Should those
  finish by the old rule after loading, or should a walker be put on the road for each at the point it would have reached?
- **R4-Q6.** On a journey of several days the courier eats and rests on the road. Who pays for the courier's food: the
  courier's own purse (covered by the fee), or something else?
- **R4-Q7.** The fee is worked out from the journey days when booked. With real walking the time varies. Does the fee stay as
  quoted at booking?
- **R4-Q8.** A load larger than the courier can carry: refuse it at the booth, or carry it over several journeys?
- **R4-Q9.** Losses on the road: should a load be lost only by what physically happens to the walker (bandits, animals,
  death), with the present value-based route risk removed, or should the route risk stay as well?

REG-05 (migration)
- **R5-Q1.** Does a household walk together as one party (children with their parents), or each person on their own walk?
- **R5-Q2.** What a household cannot carry (a full pantry, a cart, furniture): sold before leaving, left behind (to whom), or
  carried in several trips?
- **R5-Q3.** Moves happen today only on caravan visit days. With real walking, may a household leave on any day once its
  reason holds, or only on visit days?
- **R5-Q4.** A household that has started walking (its property already settled at departure, PROP-06) and then cannot go on
  (road closed, the reason gone, a death): does it turn back, and if so, where does it live on return, or does it carry on?
- **R5-Q5.** Coming to the village: if no home can be had when the party arrives (one was available when it set out), what
  happens to it?
- **R5-Q6.** While a household is on the road, does it count in the village's population, the settlement's, or neither ("on
  the road") in reports, the census, taxes and the Lorekeeper's records?
- **R5-Q7.** A migrant's job or office (for example the reeve), rent and debts (REG-02 option (b)): ended at departure or at
  arrival?
- **R5-Q8.** A marriage move: is the couple married before the bride walks, or on arrival?

MP-02 (guest stall management)
- **M2-Q1.** Must a guest stand at its stall to collect, deposit or withdraw the till and change its stock, or may it manage
  from anywhere as the stall window allows the host today?
- **M2-Q2.** Under MP-05 tier 3 ("property use"), may a sharing partner run the other player's stall (list goods, take from or
  put into the till, open or close it), or does running a stall stay with its owner only?

JOB-02 (offered compensation)
- **J2-Q1.** How should the manor set and raise an offer: start from today's rate and raise it by how much, how often, up to
  what limit?
- **J2-Q2.** X18-D6 fixes a posted wage at acceptance by the taker's skill. Is the offer one posted figure that each worker
  accepts or declines (with skill still adjusting the pay at acceptance), or is the offer made to each worker separately?
- **J2-Q3.** What does a worker weigh an offer against: its own trade's recent earnings, the market wage, other open jobs, its
  household's need? May a worker whose household is short of food decline?
- **J2-Q4.** May the manor lower an offer when many people are seeking work, or only raise it?
- **J2-Q5.** On the job board, does the player see the offer and only accept or decline, or may the player ask for more?
- **J2-Q6.** Should JOB-02 build on the Living Economy's negotiated-wage switch (LE-04, shipped off) or replace it, and should
  it ship behind a switch?
- **J2-Q7.** Does JOB-02 cover only the manor's job board, or also building helpers and business employment, which today
  share the same wage rule?
