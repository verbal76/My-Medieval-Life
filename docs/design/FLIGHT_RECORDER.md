# Flight recorder: implemented data contract (REC-19, schema `mml-recorder/2`)

Status: stage D1 (core), the D2 choke points and the D3 systems (identity, life, employment, government, crime, player verbs, save and load), on `wip/recorder`, merged with the identity foundation (ID-01, save version 20). Schema 2 (SIM-GATE-01, 2026-10-24, `wip/sim-gate`): the hourly village snapshot, combat chase events and the closing snapshot; the pre-build simulation gate and the analysis workbook that read it are in `docs/design/SIM_GATE_AUDIT.md`. A schema 1 archive reads the same (it has no snapshot table). Expansion 20 batch R3 (`wip/x20-r1r3`): stage D5 judgment and the D4 relations' shared hours, gifts and harm (same schema 2: new event kinds and codes, no new table). X20-FINAL phase 3 (`wip/x20-recorder`, 2026-10-27): flows, contracts, credit, relations' other channels, memory over time, daily summaries and multiplayer (same schema 2). Design and decisions: `docs/design/FLIGHT_RECORDER_DESIGN.md`,
`docs/directives/2026-10-23_recorder_decisions.md` (REC-D1 to REC-D4). Developer reference only; the recorder is not a player feature and
has no wiki page (it is off by default). Since SIM-GATE-01's amendment the Windows and Linux game offer it as a testing option
(Settings, Saves, "Record gameplay", off by default) with an export of the recording (section 8); Android does not.

## 1. What exists

| Piece | File |
|---|---|
| Core: tables, context stack, object threads, bounded buffer, chunk writer, session record, recovery, storage cap | `game/scripts/core/recorder/flight_recorder.gd` (`FlightRecorder`) |
| Archive reader and chunk format | `game/scripts/core/recorder/recorder_archive.gd` (`RecorderArchive`) |
| The game's instrumentation points (decide, act, interruptions, trade, transfer, coin audit, hourly samples; D3: identity, life, employment, government, crime, player verbs, save and load) | `game/scripts/core/recorder/world_recorder.gd` (`WorldRecorder extends FlightRecorder`) |
| Switch and limits | `game/data/recorder.json` (`mml-recorder-config/1`); the desktop setting `GameSettings.record_gameplay` sets `FlightRecorder.live_enabled` |
| Analysis, workbook and export (desktop and CI only; not in the Android package) | `game/scripts/recorder_export/` (`recorder_analysis.gd`, `workbook_builder.gd`, `xlsx_writer.gd`, `live_export.gd`), `game/data/sim_workbook.json` |
| The one code table (shared with XEXPL-01 later) | `game/data/recorder_codes.json` (`mml-recorder-codes/1`) |
| Coverage, status per system, never wider than what is instrumented | `game/data/recorder_coverage.json` (`mml-recorder-coverage/1`) |
| Tests | `game/tests/recorder_test.gd`; the on/off determinism comparison is `economy_sim.gd --record DIR` |

Switch: `recorder.json "enabled"` is `false`. `World.setup` creates a recorder only when `FlightRecorder.enabled()` is true
(`FlightRecorder.test_enabled` for tests, `FlightRecorder.live_enabled` for the desktop setting, or `WorldRecorder.attach(world, {"root": dir})`
as `economy_sim.gd --record DIR` and the CI gate do).
When off, `World.recorder` is `null`: no object, no file, no directory; each instrumentation point is one guarded call
(`if recorder != null`). The recorder never draws from `w.rng` or any generator, never calls planning or decision code, and never
changes game state; it stores what the instrumented code already computed. The world's `to_dict` has no recorder section.

## 2. Hooks in the game (what changed outside `scripts/core/recorder/`)

- `NPCBrain.decide` is now a wrapper: with no recorder it calls `_decide(n)`, which is the unchanged priority chain except that each
  `return` names the winning branch (read only by the recorder).
- `World._act_step` wraps the two `brain.act` calls of `_run_plan` (event begins before the action, ends with ok or failed).
- `World._walk` (two "lost" returns) and the station wait give-up call `recorder.interruption` before the plan is cleared.
- `World.trade` and `World.transfer`: begin before the mutation, end after it (before and after values), refused calls recorded too.
- `World._on_hour` calls `recorder.hour()` first: flush, coin audit, hourly samples, the village snapshot. `World.dispose` calls
  `recorder.finish()` (which writes the closing snapshot into `session.json`).
- `NPCBrain.fight` (schema 2): `chase_tick` at its top, `chase_strike` with each blow, `chase_end` before each line that clears the target.

D3 hooks (each a guarded `if recorder != null:` call; none changes what the game does):

| System | Where | Call |
|---|---|---|
| Identity | `Identity.register_npc` (founding, birth, newcomer, outlaw, arrival), `register_member` (member, settlement_birth), `register_player`, `move`, `succeed` | `identity_registered`, `identity_move`, `succession_begin/end` |
| Life | `Life.birth`, `Life.sync_roles`, `World.kill`, `World.damage_player`, `Life._player_dawn`, `Life.partner_player`, `Relations` (proposal accepted), `Guardianship.move`, `join_clan` | `birth`, `role_changed`, `death_begin/end`, `player_died`, `partnered`, `guardianship`, `clan_joined` |
| Employment | `NPCBrain._change_job`, `_open_vacancy`, `_post_left`, `_reeve_succession`, `_guard_posts`, `_install`, `_hiring_competition` | `job_changed`, `vacancy_opened`, `vacancy_filled`, `wage_offer` |
| Government | `NPCBrain.reeve_day`, `pay_guards` (a pass each), the coin sites of tax, repairs, granary, tools, works, relief, wages, `MineSupply.procure` | `pass_begin/end`, `manor_flow`, `layoff`, `wage_unpaid` |
| Crime | `World.witness`, `guard_confront`, `raise_alarm`, `report_crime`, `NPCBrain.fight` (robbery) | `witness_begin`, `guard_begin/end`, `alarm_begin/end`, `report`, `robbery` |
| Player verbs | `World.player_buy_many`, `player_sell`, `player_take`, `player_craft`, `player_hit_npc`, `player_loot`: each is a wrapper that calls the unchanged `_player_*` body between `verb_begin` and `verb_end` (without a recorder the wrapper is one `if` and a call) | `verb_begin/end` |
| Save and load | end of `World.load_dict` (attaches a recorder when enabled), `main.gd save_game` | `world_loaded`, `saved` |

D5 and D4 hooks (Expansion 20, batch R3; REC-19, REC-STORE, FAM-SAC-01). The judgment store holds the recorder in `JudgmentStore.rec`
(null unless a recorder is attached: `WorldRecorder.attach` sets it, `JudgmentLive.attach` sets it for a store made later, as on load;
never saved). Each call passes values the store has already computed; the recorder calls no store function (no catch-up, no gossip
flush, no draw), so recording changes no belief, ledger, trust or choice.

| System | Where | Call |
|---|---|---|
| Judgment facts | `JudgmentStore.publish` | `judgment_fact` |
| Beliefs | `JudgmentStore.learn` (after its duplicate checks: open until it returns) | `belief_begin`, `end` |
| Gossip | `JudgmentStore.tell` (now a wrapper around the unchanged `_tell`) | `gossip_begin`, `gossip_end` |
| Ledger posts | `JudgmentStore._post` (each contribution that changes) | `judgment_post` |
| Trust | `JudgmentStore.trust_add` | `trust_move` |
| Weighted choices | `JudgmentWeighting.choose` (the final result, after the family-name re-run) | `judgment_choice` |
| Family priority | `JudgmentFamily._record` (the `family_trace` row) | `judgment_family` |
| Relations | `Relations.share`, `give`, `harmed` | `shared_hour`, `gift_begin/end`, `harm_begin`, `harm_tie`, `end` |

X20-FINAL phase 3 hooks (owner directive 2026-10-27; `docs/expansion20/X18_X20_COVERAGE_MATRIX.md` names the gaps they close; INT-570).
Each is one guarded call; `Relations.ask_court` and `propose` became wrappers (as the player verbs and `JudgmentStore.tell` are) around
the unchanged bodies `_ask_court` and `_propose`, called alone with no recorder or on a guest.

| System | Where | Call |
|---|---|---|
| Production, consumption, unmet needs | `World.stat` (before it adds) | `stat_moved` |
| Contracts | `Contracts._open`, `deliver`, `_pay_units`, `_end` | `contract_opened`, `contract_goods`, `contract_paid`, `contract_ended` |
| Credit | `Credit.sell_on_credit`, `repay`, `_default`, `barter` | `credit_extended`, `credit_repaid`, `credit_defaulted`, `barter` |
| Relations | `Relations.helped`, `talked`, `dawn`, `_villagers_court`, `ask_court`, `propose` | `tie_event`, `cooling_begin/end`, `court_interest`, `court_begin/end` |
| Memory and temperament | `JudgmentStore._forget`, `make_history`, `tell_family_history`; `JudgmentPersonality._log` (`pers.rec`, set with `JudgmentStore.rec`); `JudgmentBonds.on_belief` | `memory_forgot`, `history_made`, `history_told`, `personality_change`, `grievance` |
| The day | `WorldRecorder.hour` (the first hour of each day) | `_day_summaries` |
| Multiplayer | `NetSession.host`, `c_hello` (joined, refused), `_on_peer_disconnected`, `_lost`, `s_welcome`, `apply_requests`, `send_syncs`, `s_sync`, `s_reply`; `WorldRecorder.hour` | `net_event`, `net_request`, `net_sync`, `net_state_maybe` |

Switch for a whole process: `MML_RECORD=DIR` (environment) makes `FlightRecorder.enabled()` true and roots every session there, named
`s<unix>_p<process id>` so several processes (the network harness's host and guests) share one directory. The game never sets it.

## 3. Tables

Rows are JSON arrays; the first column of every row is `seq`, the session-wide row sequence. Entity references:
`p:<permanent person id>`, `hh:<n>`, `manor`, `granary`, `loot`, `world`, `role:player`, and `inv:?` for a store whose owner the recorder cannot name.
A person is always `p:<id>` with the permanent id of the identity register (`World.people`, ID-01): a villager's NPC id, a settlement member's or
player character's band id (1,000,000 and up). **The player is not a separate identity.** The player character is `p:<PlayerState.pid>`, an
ordinary person reference that stays the same for that person for good; that the person held the player role at the time is a role marker on the
participant row (`buyer:player`, `offender:player`, `heir:player`; `WorldRecorder.role_of`), never a different ref. Across a succession the
two characters are two refs (the predecessor `p:A`, the heir `p:B`); when the heir is the player's own child they keep the child's village id, so
every earlier record of that child (their birth, their trades as a villager) is on the same ref as their later ones as the player. The office that
passes between them is the entity `role:player` (its `holder` property changes in the succession event). `p:player` appears only for a player
without a pid (a bare test world; never in a World built by `setup` or loaded from a version 20 save).
A value the engine did not evaluate is the string `not evaluated`, never an invented value.

| Table | Columns after `seq` |
|---|---|
| event | `id, parent, interaction, object, day, minute, settlement, x, y, system, subsystem, category, subtype, actor, outcome, reason, rule, detail` |
| participant | `event, ref, role` |
| decision | `event, actor, kind, chosen, basis, tiebreak` |
| alternative | `event, option, evaluated, feasible, reason, score` |
| factor | `event, option, factor, value, unit, source, evaluated` |
| state_change | `event, ref, prop, before, after, delta, authority` (`prop` is `coins` or `item:<id>`; `delta` only when both values are integers) |
| link | `from, to, kind, via` (object threads: `same_object` to the object's previous event) |
| alert | `id, severity, rule, entities, values, event, day` |
| sample | `day, hour, entity, hunger, hp, x, y, doing, coins` |
| snapshot | (schema 2) `day, hour, alive, households, adults, employed, children, elders, bandits, mean_hunger, min_hunger, starving, mean_hp, idle, lost, fighting, guards, guards_engaged, total_coins, villager_coins, treasury, coin_sources, hh_purse_min, hh_purse_median, hh_purse_max, food_days, granary_wheat, births, deaths, ties, friends, courting, facts, player_crimes, events_h, trades_h, trade_coins_h, transfers_h, actions_h, actions_failed_h, walk_lost_h, crimes_h, chases_h, alerts_h, stats_delta, wall_ms, mem_bytes` |
| session | not a chunked table: `session.json` (below) |

`event.parent` is the open event when this one began (decision -> action -> trade); `event.interaction` is the root of that chain.
`outcome` is one of ok, failed, refused, interrupted, abandoned, unfinished, unattributed, empty. `minute` is the game minute of the day.
There is no separate tick column: the clock is the game minute, and `seq` orders events within it.

Context rules (links only where the code knows the cause): `begin` pushes an event, `end` pops it and writes its row; anything recorded in
between is its child. A plan's actions are children of the decision that made the plan, only while `n.plan` is still the array that decision
produced (otherwise no parent is claimed). Object threads (`opts.object`, e.g. `contract:5`) add a `same_object` link to the object's
previous event; the mechanism is in the core and tested, and no game system uses it yet.

### What the first choke points record

- **decide**: one event per call (`category decision`, `subtype plan_next`), a `decision` row with `chosen` = the branch of
  `recorder_codes.json "decision_chain"` that returned, `basis first_passing_branch`; `alternative` rows: each earlier branch as
  `evaluated yes, feasible false, reason guard_or_planner_declined` (the chain does not say whether the guard was false or the planner
  returned no plan), the winner `feasible true`, and ONE row `after:<winner>` standing for every later branch, `not evaluated`
  (one row, not one per branch, to keep volume down; the meaning is the same). `factor` rows: the guard values read (hunger, `eat_below`,
  health ratio, `seek_below`, hour, role, job, clan), each stored once under the first branch that reads it. Values are read before the call;
  the planner changes none of them. A priority chain has no scores, so `score` is `not evaluated`. Outcome `empty` when no plan resulted.
- **act**: one event per executed plan step (`subtype` = the act kind, `detail` = args summary, at most 160 characters), outcome `ok` or
  `failed` (reason `act_returned_false`; the code gives no finer reason). Only actions run by `World._run_plan`.
- **interruptions**: `walk_lost` (interrupted, reason `no_path` or `no_level_route`), `station_giveup` (abandoned,
  `station_wait_exceeded`).
- **trade / transfer**: one event each, participants (buyer, seller / giver, receiver), `state_change` rows for both purses
  (trade only) and the item count of both sides, before and after. A refused call is an event with outcome `refused` and a reason.
- **coin audit (REC-D4)**: at every hour boundary each villager's purse, the player's and the manor treasury are compared with the last
  audited balance plus the coin changes recorded since; `World.total_coins` with its last value plus all recorded changes plus the change in
  `World.coin_sources`. A difference becomes an event (`unattributed_coins`, outcome `unattributed`, a state change with authority `audit`)
  and an alert (`coin.unattributed_holder` warning; `coin.unattributed_total` violation). It names the holder and the amount, not the code
  site: about 150 coin sites are not instrumented and their changes appear here. Example found while testing: a tavern keeper's sale through
  `World.trade` moves part of the price into the till (`BusinessMoney`), which is not recorded, so the keeper's purse is flagged.
- **samples (REC-D3)**: each hour, hunger, health, cell, doing and coins of every living villager and the player. Samples never replace
  interaction records.

### Schema 2 (SIM-GATE-01): the village snapshot and chases

- **snapshot**: one row at every hour boundary, after the samples. Levels at that moment (villagers alive, not bandits; households
  with a living member; adults with a job; hunger and health means; villagers at zero hunger; `doing` "idle" and "lost"; villagers
  with a target; guards and guards with a target; `World.total_coins`, the villagers' coins, the treasury, `coin_sources`; the
  households' purses, min, median, max; `food_days`; granary wheat; ties, friendships and courting pairs from `Relations.ties`;
  judgment facts (`facts.size()`, not `counts()`, which flushes gossip); the player's crime count), the recorder's own counts
  since the last snapshot (`*_h`: events ended, accepted trades and the coins they moved, transfers, plan-step actions and failed
  ones, walk-lost interruptions, crime events, chases, alerts), births and deaths recorded since the session began, `stats_delta`
  (every `w.stats` counter that changed in the hour, as {key: change}; unchanged state is not repeated) and two measurements of the
  machine, `wall_ms` (since the last snapshot) and `mem_bytes` (`OS.get_static_memory_usage`), which differ between runs and are
  never compared for determinism. About 48 values an hour: 2 to 3 KB a game day.
- **final_snapshot**: the same values, keyed by column, written into `session.json` by `finish()`: the world as the session left
  it (the last hourly row is taken before that hour's own processing, so a newcomer arriving at the hour is in the closing
  snapshot only). The gate reconciles it with the simulation's own output.
- **chase** (`category combat`, `system combat`, `subsystem chase`, `subtype chase_guard | chase_bandit | chase_villager`): one event
  per chase, written when it ends, actor the fighter, participants the fighter and the target (`target:player` for the player),
  outcome `ok` (`target_slain`, `robbed`), `abandoned` (`blocked`: the straight-line step hit a wall, the SIM-F4 rule and the owner's
  corner case; `out_of_range`: beyond 25 tiles; `near_bandit_camp`; `bandit_low_hp`) or `interrupted` (`target_gone`,
  `retargeted`, `cleared_elsewhere`: cleared by other code, seen at the next hour), detail `start_day start_minute minutes seconds
  d0 d_end strikes`. A target set far away and dropped on the same tick is a chase of 0 seconds (`out_of_range`): the late reports
  of `REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS.md` section 9 show as these.

### D3 events (what each records)

All are `event` rows with participants and `state_change` rows; a pass or verb is the parent of what it causes, so `parent` joins them.

- **Identity** (`category identity`, `system identity`): `registered_<how>` (`founding`, `birth`, `newcomer`, `outlaw`, `arrival`, `member`,
  `settlement_birth`, `player`: state change `where` `unregistered` -> `village` / a settlement id / `player`; detail names mother and father as
  permanent refs and says "band id" for 1,000,000 and up), `left_village`, `returned_to_village` (the same ref, `where` village <-> settlement),
  `died`, `became_ancestor`, `became_player`. The register's own `where` values are the states. **succession**: one event on the predecessor, its
  participants the predecessor (`predecessor:player`) and the heir (`heir:player`) as two different refs, one state change `role:player holder
  p:A -> p:B`, detail with the generation, whether the heir is the player's own child, the count of live ties that use the player's view id (-2)
  before and after (they are equal: the village's view of the player goes on to the heir) and the size of the snapshot kept under the
  predecessor's id. The identity moves are its children.
- **Life** (`category life`): `birth` (child, mother, father, household), `death` (cause in the detail; state change `alive` true -> false;
  the purse as two coin state changes, to the heir, or to `loot` for the slain, so they net to zero), `role_changed` (child -> adult at 16,
  adult -> elder), `partnership` (both people, `partner` state change each), `guardianship_placement` (household before and after, tier,
  host), `guardianship_clan`. A player character's death is a `death` on their ref.
- **Employment** (`category employment`): `job_taken` / `job_lost` / `job_switched` (state change `job`), `vacancy_opened` and `vacancy_filled`
  (state change on `world` `vacancies`, +1 / -1; a fill is also a job change on the same person), `wage_offer_raised` / `_eased` (state change
  `wage_raise` on `manor`).
- **Government** (`category civic`): `reeve_day` and `pay_guards` passes (treasury and granary before and after as `summary` rows, which the
  coin audit does not count again); under them one event per coin movement (`tax`, `wage`, `repairs`, `granary`, `tools`, `works`, `relief`,
  `mine_supply`) with two coin state changes (the person and `manor`, equal and opposite, authority `gov.<kind>`), `layoff`, `wage_unpaid`
  (outcome failed, reason `treasury_short`). Relief goods move through `World.transfer`, so those transfers are children of the pass.
- **Crime** (`category crime`): `theft` (any `kind` World.witness is given; the player as `offender:player`, the victim, each witness; the player's
  `crimes` count before and after), `guard_confront` (child of the witness; the player's coins and the treasury before and after with the fine,
  the goods returned as item changes, detail `fine= paid= warned=`), `raise_alarm` (attacker, witnesses, victim; its `report_crime` events are
  children), `robbery` (robber and victim coin and item changes).
- **Player verbs** (`category verb`, `system player`): `buy`, `sell`, `take`, `strike`, `craft`, `loot`; actor the player's ref; outcome ok or
  failed with a reason (`too_far`, `pack_full`, `nothing_to_take`, `buy_failed`, `sale_failed`, `recognised`, `questioned`, `craft_refused`).
  State rows are a summary of the player's purse and pack and the target's health, authority `summary`; a purse change that no child event
  recorded (loot) is credited to the player's purse for the hourly audit, so it is not an unattributed alert.
- **Save and load** (`category system`): `world_loaded` (save version, running version, whether the register was read from the save or
  upgraded once, `ids_unchanged`, the people count before and after as a state change on `world`; violation alert
  `identity.ids_changed_on_load` if a version 20 save loads with a different set of ids) and `world_saved`. A loaded game with the recorder
  enabled starts a new session; the audit takes its balances afresh.

### D5 and D4 events (Expansion 20, R3)

- **Judgment** (`system judgment`, `category judgment`): `fact` events (subtype `fact:<event type>`; actor the first actor; participants
  `actor:<share permille>`, `victim`, `beneficiary`; detail `fact=<id> value= tags=`; object thread `fact:<id>`); `belief` events (subtype
  the source: participant, witnessed, told, rumour; participants `observer` and `teller`; detail fact, type, hops, confidence, `upgrade`;
  object thread `fact:<id>`, so a fact's beliefs follow it); its state rows are the ledger posts (`judgment_good:<actor>:fact:<id>` and
  `judgment_bad:...` on the observer, the contribution before and after, authority `judgment`) and trust moves (`trust:<subject>` on the one
  who trusts, 0..100000 milli-points before and after). `gossip` events (subtype `tell`, teller and listener, `stories=<n>` moral stories; news told and a lie shown false
  are their own child rows) are the parents of the beliefs they gave; a telling with nothing recorded under it is dropped
  unwritten. State rows outside a belief or telling (a correction, a trust move from a live hook) go on the event open at the time (an action,
  a verb), else on a one-off `ledger` / `trust` event.
- **Weighted choices** (`subsystem choice`, subtype the profile): a `decision` row (kind `judgment_weighted`, chosen option or `none`,
  basis the selection policy: `margin`, `argmax`, `forgo`, `none_feasible`, `family_name_cannot_refuse`; tiebreak `colour_blocked` when the
  family name alone would have refused); one `alternative` per candidate (feasible with its utility as score; infeasible with reason
  `not_feasible` and a `why` factor in the live code's words) and one for `forgo` with its utility; for each feasible candidate one `factor` row
  per factor value (unit milli-points 0-100000; source `judgment` for disposition, ambivalence and sole_source, else `live_code`), one
  `weighted:<factor>` row per weighted contribution, `family_colour` and `stubborn_resent/switch/override/total` when present, and its
  `counterparty`. Nothing is sampled or reduced (REC-STORE); the storage cap stops the session (REC-D2).
- **Family priority** (`subsystem family`, subtype the kind: `meal_pantry`, `meal_buy`, `pay`, `work`, `danger`): household, chosen and utility
  in the detail, the rule's values (tier, temperament, price, threat, dependants, cornered, the dependant paid for) as factor rows, and a
  `part_of` link from its weighted choice, whose factors carry `family_child_need`, `family_spouse_need`, `family_parent_need`, `self_need`,
  `self_floor` and the rest of the family profile.
- **Relations** (`system relations`, `category relation`): `shared` (subtype work, social or met), `gift`, `harm`, each on the tie
  `tie:<a>:<b>` with `regard`, `attraction` (floats, no delta) and `days_known` before and after (only those that changed); a gift also
  records `item:<id>` leaving the giver and reaching the receiver (authority `relations.gift`); a harm records every tie it lowered.

### X20-FINAL events (phase 3)

- **Flows** (no event of their own): a state row on `world` under the event open at the time (an action, a decision, a verb), prop
  `produced:<counter>`, `consumed:<counter>` or `unmet:<counter>` (the `w.stats` key, e.g. `produced:mined_iron_ore`,
  `unmet:missed_meal_no_money`), before and after the world counter, authority `world.stat`. The actor is the event's actor, so a
  chain reads: decision (the branch), action (`work_mine`), `produced:mined_iron_ore`; or decision (`eat`) with
  `unmet:missed_meal_no_food_for_sale` and no plan. Counters moved outside any event stay in the snapshot's `stats_delta` only.
- **Contracts** (`system contracts`, `category contract`, object `contract:<id>`): `opened` (buyer and `contract:<id>` coins, state
  offered -> accepted), `delivered` (items of seller and receiver), `paid` (from `contract:<id>` to the seller), and one end:
  `fulfilled` (ok), `cancelled` or `lapsed` (failed; why in the detail; the coins still set aside back to the buyer; state before ->
  after). An offer or a signing that never opened appears only as its end. The thread's coin rows sum to zero once it ends.
- **Credit** (`system credit`, `category credit`): `extended` (object `debt:<id>`, the goods both sides), `repaid` / `repaid_late`
  (coins both sides), `defaulted` (failed), `barter` (goods both ways).
- **Relations**: `help` and `talk` (tie rows), `cooling` (one a dawn: `regard_sum` and `attraction_sum` of all ties on `world`, the
  ties and those cooled in the detail), `interest` (a suitor's choice: candidates, whether judgment chose), `court_ask` and `proposal`
  (outcome ok or refused, reason `refused_by_rules`, the answer's words, `stage` before and after, participant `suitor` or
  `suitor:player`, the partnership a child event).
- **Judgment over time**: `forgot` (object `fact:<id>`, `memory:fact:<id>` held -> forgotten; a child of the belief that crowded it out,
  else faded at dawn), `provocation` / `positive` / `mistake` / `reminder` (personality: trait deltas, wisdom or anger as factors),
  `grievance` / `betrayal` (resentment before and after), `history_made` and `history_told`.
- **Summaries** (`category summary`, one a day each): `judgment_day` (factors: every judgment stat and bonds stat moved over the day,
  memories held, people remembering, aspiration on), `world_day` (deposits left by ore, seams worked out, trees standing and mature,
  households with members, regional coins and goods, capability levels and their changes, open contracts and reserved coins, open
  debts), `economy_model` (LE-01 when on: events, ordered, knowledge, needs recorded and dirty, offers, reservations, unbacked,
  contract links; outcome failed and a violation alert `economy.unbacked_reservation` if a reservation is unbacked).
- **Network** (`system net`, subsystem the role, `category network`): `host_started`, `guest_joined`, `guest_refused`, `guest_left`,
  `joined_host` and `host_lost` (guest), `request` (each request the host applied: kind, path, text; failed when the result says so),
  `prediction_differs` (a guest's own run of a verb gave another result than the host's), `net_state` (once a game hour per
  participant: players with coins and alive, peers, `section` factors with the hash of each shared `World.to_dict` section, `sync`
  factors counting the syncs sent or adopted and their bytes since the last digest). A guest's world never simulates, so its archive
  has these and its load only (no hourly audit there).
- **Session flags** (`session.json flags`): `recorder`, `judgment`, `aspiration`, `job_choice`, `economy`, and each judgment decision
  domain as `JudgmentLive.on` reads it; plus `scenario` (`MML_SCENARIO`, the gate's run name).

## 4. Archive on disk

```
<root>/<session>/session.json
<root>/<session>/d<DDDD>/<table>.h<HH>.p<P>.jsonl.gz     one chunk per table per flush; DDDD game day, HH hour, P part
<root>/<session>/recovery.json                           only after a later start examined an interrupted session
```
`root` is `recorder.json "root"` (`user://recorder`) or the `--record` directory. `session` is `s<unix start>` (a suffix if taken).

A chunk is one standard gzip file (written with `PackedByteArray.compress`, so any gzip tool or Python's `gzip` module reads it; Godot's
`FileAccess.open_compressed` writes its own container that nothing else opens). Its text is JSON lines: a header
`{schema, session, table, day, hour, part, columns, first_seq, last_seq}`, one array per row, and a footer
`{"footer": true, "rows": N, "sha256": <sha256 of the row lines, each followed by "\n">}`. A chunk set is one game day (a flush never mixes
days). Rows are buffered (default 50,000, `buffer_rows`), flushed at every game-hour boundary and early when the buffer fills; nothing is
dropped. An event row is written when the event ends, so a child can appear in an earlier chunk than its parent; join by ids.

`session.json` (rewritten at every flush and at the end): schema, session, `start_unix`, `ended`, `completeness`, chunk count, bytes,
storage cap, `counts` per table, `last_seq`, buffer bound and `peak_buffer_rows`, `early_flushes`, `recovered`, `unknown_codes`, a pointer
to `recorder_coverage.json`, and the caller's metadata: `seed`, `save_version`, `commit` (the `MML_COMMIT` environment variable, else
`unknown`), `flags` (`judgment` attached or not; the design's `economy` and `civic` flags do not exist in this build).

**Storage cap (REC-D2).** `storage_cap_bytes` (default 1 GiB). After a flush that brings the session to or past the cap the recorder stops,
keeps everything written, and sets `completeness` to `incomplete: storage cap reached at day D, sequence S` (also `incomplete_at`). The cap
can be exceeded by at most one flush. Nothing is deleted or overwritten.

**Recovery.** At the start of a session the recorder looks at earlier sessions under the same root that never wrote `ended`, skipping any
whose `session.json` changed within `live_grace_seconds` (120; it may still be recording), and any that already have a `recovery.json`.
Each chunk that is unreadable, lacks its footer or does not match it is listed under `recovered` in the new `session.json` and in a
`recovery.json` in the old session. Nothing is deleted. A chunk is written in one call, so an interruption leaves the earlier chunks whole.

## 5. Reading an archive

```python
import gzip, json, glob
def rows(session_dir, table):
    for f in sorted(glob.glob(f"{session_dir}/d*/{table}.*.gz")):
        lines = gzip.open(f, "rt").read().splitlines()
        head, foot = json.loads(lines[0]), json.loads(lines[-1])
        assert foot.get("footer") and foot["rows"] == len(lines) - 2     # else the chunk is truncated
        for line in lines[1:-1]:
            yield dict(zip(head["columns"], json.loads(line)))
```
In GDScript: `RecorderArchive.read_chunk(path)`, `read_table(session_dir, table)`, `scan_session(session_dir)`.
To walk a chain: an action's `parent` is its decision's `id`; `interaction` is shared by the whole chain; a trade's `state_change` rows have
`event` = the trade's `id`.

## 6. Measurements (seed 1, 10 game days, headless fixed step, 104-109 villagers; this machine)

After D3, on the branch merged with the identity foundation (commit of this stage), `economy_sim.gd --days 10 --seed 1 --every 5` with and without
`--record` (run side by side on four cores): the fingerprint (every villager, animal, deposit, pantry and the RNG state) is identical at days 0, 5 and
10 (`29bf72b0...`, `bf163f02...`, `cc3edc39e29c7b7b95e293a4f28cb463`), currency and item ledgers leak nothing. Wall time 71.4 s unrecorded,
91.3 s recorded (+28%; D1+D2 alone measured +27%: the D3 hooks add no measurable cost, since they fire a few hundred times in ten days).
Rows over the 10 days: event 66,001 (+242 over D2); participant 69,246; decision 51,149; alternative 840,516; factor 388,321;
state_change 9,597 (+578); sample 26,686; alert 280 (was 499: wages, taxes and purchases are now attributed instead of flagged); link 0 (total
about 1.45 million). Archive 10,496,423 bytes for 10 days in 1,737 chunks, unchanged to the first decimal from D2 (the decision detail is the
volume); 0 unknown codes, 0 early flushes, peak buffer 30,447 rows. D3 event mix over the 10 days: tax 67, wages 80, repairs 119, reeve_day 10,
pay_guards 10, robbery 30, raise_alarm 32, report_crime 40, deaths 8, births 7, settlement births 29, plus the founding registrations.
`alternative` is 46% of the bytes, `factor` 26%, `event` 12%. The decision detail is the dominant cost; limiting `alternative` and `factor` rows to
the winner is the first reduction if volume matters.

## 7. Known limits (also in `recorder_coverage.json`)

Since X20-FINAL phase 3 (section 3) contracts, credit, relations' other channels, memory over time, flows by actor, the day's summaries and
multiplayer are recorded. Still not recorded: business tills, stalls, property, construction and the manor's works as events (their coins are
detected by the hourly audit, named by holder and amount; the world total balances); courier deliveries (counted in `stats_delta` only);
capability multipliers per unit; the settlements' daily phases beyond the daily totals; ledger decay (applied lazily on read: visible in the
values every choice records); memory fading per memory (only the forgetting); the player's closeness ticks; moves and the per-tick villager
and animal network snapshots. Coin changes outside the instrumented sites are detected hourly, not attributed. Item changes outside
`World.trade`/`transfer`, the verbs' summaries, contracts, credit and gifts are not item rows. Chests, carts, stalls and loot appear as `inv:?`
in transfers. Decision records stop at the top-level branch. Jobs that run `_plan_job` internally show only `job` as the chosen branch.

## 7a. Independent verification (X20-FINAL phase 5)

`tools/recorder_archive.py` checks, besides the archive's integrity (section 4): event ids 1..N each once and every row naming a recorded event;
nobody decides, acts, trades or is born again after their death; roles only child -> adult -> elder; contract and debt threads open once,
move only while open, end once and leave no coins set aside; the snapshots' growing counters never fall and values stay in range; the
recorded flags against the scenario's (`require_flags`); the coverage matrix's rows exercised (`recorder_coverage.json exercise`,
`require_rows`); the owner's judgment chain (`chains`: crime facts, believers, those who only heard, later choices about the offender by
believers); measures for review (re-decisions, choice profiles, flows). `--participants HOST GUEST...` compares network participants'
digests hour by hour (a section differing three or more consecutive hours is a problem). `tools/sim_suite.py` blocks on every problem.

## 8. Desktop recording and export (SIM-GATE-01 amendment, 2026-10-24)

- **Setting:** Settings, Saves, "Record gameplay: on/off" (Windows and Linux only; `Main.recording_supported` needs a PC build and
  the export scripts, which the Android package does not carry). Off by default; stored as `[developer] record_gameplay` in
  `user://settings.cfg`. Switching it on attaches a recorder to the running world at once (and to every game started or loaded);
  switching it off closes the session. Nothing in the game reads the recorder, so recording changes no decision and draws no
  random number.
- **Storage:** the recorder's own bounds: a buffer of at most `buffer_rows` (50,000) rows, written to chunk files at every game
  hour (incremental), under `user://recorder/<session>/` (Linux `~/.local/share/godot/app_userdata/My Medieval Life/recorder`,
  Windows `%APPDATA%\Godot\app_userdata\My Medieval Life\recorder`); at `storage_cap_bytes` (1 GiB) it stops, keeps everything
  and marks the session incomplete. Measured: about 0.5 to 0.6 MB a game day for a village of about 110 people.
- **Export:** "Export the recording..." writes into `Documents/My Medieval Life/recordings/` (`user://recordings` when the system
  has no Documents folder): `<session>_day<N>.xlsx` (the workbook: every sheet and chart of `game/data/sim_workbook.json`, with
  up to 20,000 event records), `<session>_day<N>_analysis.json` (the analysis as data) and `<session>_day<N>_archive.zip` (the
  session's chunk files and `session.json`), then opens the folder. With no recording running it exports the newest session.
- **Android:** the export folder and the workbook definition are excluded from the Android preset (`exclude_filter`), the setting
  is not shown, and nothing in the shipped code names the export scripts (`tests/test_sim_gate.py` checks the preset and the
  references; the release workflow lists the APK's files).
