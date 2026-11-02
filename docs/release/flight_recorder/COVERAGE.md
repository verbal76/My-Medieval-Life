# Flight recorder coverage audit (FLIGHT-REC-01)

Owner directive 2026-11-02 (`docs/directives/2026-11-02_permanent_flight_recorder_simulation_system.md`, section 4), register
FLIGHT-REC-01. Audited 2026-11-02 against the Build 25 source (`91cf244`) and the recorder's own coverage matrix
(`game/data/recorder_coverage.json`, which stays the authority: a system it does not list as instrumented is not recorded).

How to read this: **Recorded** means the recorder writes rows for it as it happens. **Seen indirectly** means no event row, but
the campaign analysis still sees it through the hourly village snapshot (its `stats_delta`: every `World.stats` counter that
changed in the hour), the villagers' hourly samples, or the harness's checkpoint lines in `sim.log` (CHAPEL, JOBS, BIZ, FUNNEL,
ORE, CAPMS, ECON10). **Gap** means nothing in the run shows it beyond its end effects.

## Normal integrated play (what a flight recorder run switches on)

The default campaign runs the shipped switches (`sim_args` empty). The recorded session's flags show: judgment attached, the
career ambition (aspiration layer with its job choice) on, business founding on, every judgment integration on, the LE-01
economy model **off** (Living Economy LE-02 to LE-06 stay behind the off switch in Build 25).

| Expansion 20 / Build 25 system | Coverage | Where the campaign reads it | Meaningful gaps |
|---|---|---|---|
| NPC decisions (NPCBrain.decide) | Recorded, branch level | decision events (`plan_next`, plan steps), empty decisions | Job routines inside a branch, seller and buyer searches, the labour market's scoring |
| Actions (about 60 act kinds) | Recorded in full | action events ok/failed with args: the failure streaks, impossible tasks | A failure's cause is only `act_returned_false` (the act code does not say why) |
| Interruptions | Recorded: walk lost, station wait given up | interruption events: impossible tasks, station contention | Other abandonments (a plan dropped by a higher branch) are not events; "mutual interruption" is inferred from contention, not recorded |
| Trade (World.trade) | Recorded in full, refusals with reason | trade events and participants: refused-purchase streaks, duplicate trades, item outcomes | Sales made by code that does not call World.trade |
| Currency | Audited hourly, not attributed (REC-D4) | `coin.unattributed_holder` warnings, `coin.unattributed_total` violations; the harness ledger is the authority | About 150 coin sites (wages, rents, tax, tills, rewards) appear only as unattributed holder changes |
| Inventory and transfers | Partly recorded | transfer events; the harness item ledger (FATAL) | Direct Inventory.add/remove sites; chests, carts, stalls show as `inv:?` |
| Food production and consumption | Seen indirectly (counters) | `stats_delta` made_/eaten_/spoiled_ per hour, snapshot food_days, villager hunger samples | No event per meal; the abstract settlements' food is not per meal |
| Farming (fields, family plots, pens) | Actions recorded; the farming scripts are not | sow, harvest, fp_* actions; farm counters | Crop growth and yields inside farming.gd |
| Mining, prospecting | Actions recorded; the mining scripts are not | mine, prospect, assay actions; ORE line | Seam depletion inside the mining scripts (the daily world summary names deposits left) |
| Employment and succession | Recorded: job changes, vacancies, wage offers | job state changes (flip-flops, churn), JOBS line (looked and found none) | Who applied and why they were passed over; a fruitless job search is a counter, not an event |
| Career ambition (B25-AMBITION, aspiration layer) | Recorded while on (it is on in Build 25) | judgment aspiration and job_choice events | Daily satisfaction with no change |
| Business founding, ventures, tills (TILL-D1) | Partly recorded | till events (sale, settle, owner pay, top-up, commission, escheat), ownership changes, BIZ and FUNNEL lines | Construction sites and deliveries, the player's own shop till |
| Contracts and credit | Recorded as object threads | contract and debt threads, the archive's transition checks, contract failure detector | Offer and counter-offer bargaining |
| Chapel: services, offerings, alms, food relief (X20-CHAPEL) | **Not instrumented** in the recorder; seen indirectly | `church_ask` actions, `fact:relief` judgment facts, `chapel_*` counters in `stats_delta`, the CHAPEL checkpoint line (fund, reserve, store, asked, relieved, alms households) | Which household was considered or refused relief and why: the chapel relief detector works window by window (10 days), not household by household |
| Government (reeve day, guards' pay, tax, repairs, relief purchases) | Recorded as daily passes and their children | civic events, treasury in the snapshot | The tax-rate decision's factors; which household relief chose |
| Manor work | **Not instrumented** | mj_* actions, manor wage events | Job lots, reservations and refunds |
| Crime, combat, bandit AI | Recorded (crime events, chases, robberies, reports) | crime and chase events | Pickpocket odds, bandit raids on stalls |
| Relationships, courting, households | Recorded (shared hours, gifts, harm, help, talk, cooling, courting, proposals) | relation events | Per-tie cooling (one row a dawn) |
| Judgment (facts, beliefs, gossip, trust, weighted choices, family priority) | Recorded in full | judgment events; the archive's chain check | Ledger decay and personality drift over time |
| Life (births, deaths with context, ageing) | Recorded | deaths with cause and the deceased's means (starved with or without means), births | Pregnancy and fertility checks that did not lead to a birth |
| Settlements and migration | Partly recorded (moves, settlement deaths, a daily settlement summary) | migration events, settlement_day factors | The settlements' abstract daily phases and couriers |
| Settlement food trade | Seen indirectly | settlement_day summaries, caravan counters | No event per settlement purchase |
| Feasts, quests | **Not instrumented** | counters and the villagers' `doing` text | Everything inside them |
| Living Economy LE-01 to LE-06 (market, reservations, rentals) | Off in normal play; when switched on, LE-01 is a daily summary only | `summary/economy_model` (with `--economy` or `--market`) | Market deals and claims are not rows |
| Multiplayer (MP-INTERACT-01) | Recorded in network sessions only | not exercised by a headless single-world run | Not part of a flight recorder campaign |
| Save and load | Recorded (load note, save event) | each chained segment's session starts with `world_loaded` and the previous one ends with `world_saved` | |

### Upcoming expansion integrations

The matrix row "Expansions 20, 21, 22 (hybrid), 23 — Not instrumented: hooks in D1; instrumented with each feature" stands: each
new system adds its own recorder calls and coverage row when it lands. Until then the campaign sees a new system only through
`World.stats` counters and its effects on villagers. Expansion 21's civic records (`--civic`) observe only and are not recorded.

## What the analyser can and cannot find

- It reads every row of the event, participant, state_change, sample, snapshot and alert tables; tools/recorder_archive.py reads
  every row of every table for the integrity checks. Decision alternatives and factors are checked for integrity but not mined
  for behaviour (their volume; they explain a choice once a finding names it).
- Behaviour in uninstrumented systems (chapel, manor work, feasts, farming and mining scripts) is found only when it shows in
  actions, villagers' hunger, coins and `doing`, or the counters. A loop entirely inside one of those scripts would be missed.
- A failed action's reason is not recorded by the game (`act_returned_false`), so a streak says *what* failed, not *why*.

## Recording does not change outcomes (neutrality proof)

Seed 1, 10 game days, normal play, the end-of-run fingerprint (`economy_sim.gd` `_fingerprint`: time, treasury, coin sources,
the random stream, granary, every villager's coins, position, hunger, job and pack, every animal, deposit and pantry):

| Run | Fingerprint |
|---|---|
| Build 25 harness (`91cf244`), no recorder | `b01fbf44fd1dc38760a9aebc15fddf5c` |
| Build 25 harness (`91cf244`), `--record` | `b01fbf44fd1dc38760a9aebc15fddf5c` |
| This branch's harness (status, extinction watch), `--record --status` | `b01fbf44fd1dc38760a9aebc15fddf5c` |
| Chained: segment 1 to day 5 saved, resumed to day 10 with `--record` | `c8cae8dfa4105e9fcca53464aeae839d` |
| Chained: the same save resumed to day 10 without the recorder | `c8cae8dfa4105e9fcca53464aeae839d` |

The recorder and the new harness switches leave the run identical; a chained run is deterministic from its save and the recorder
does not change it either. A chained run differs from an unbroken one (`c8ca...` against `b01f...`) because a save does not hold
movement in progress (save_continuity_test.gd), so chained runs are compared with chained runs of the same segment length.
