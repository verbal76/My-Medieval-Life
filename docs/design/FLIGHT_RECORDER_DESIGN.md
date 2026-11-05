> STATUS (2026-10-31, DOC-RECON-01): HISTORICAL — the Phase A/B design checkpoint ("nothing is implemented"); the recorder is now built (REC-19, REC-DIAG, REC-STORE) and its xlsx export is game/scripts/recorder_export/, not tools/recorder_xlsx.py. Current status: docs/expansions/STANDALONE_SYSTEMS.md section 12.

# Build 19 Simulation Flight Recorder: Phase A audit and Phase B design (2026-10-23)

Owner directive: `docs/directives/2026-10-23_build19_flight_recorder.md` (register REC-19). This is the Phase C checkpoint: nothing is
implemented. Audit facts were read from the Expansion 19 branch (Build 18 + judgment, off) and measured in one 10-day headless run
(seed 1, 104-109 people, no leaks). Labels: **V** verified, **E** estimated. Explanation layers (XEXPL-01) and identities (ID-01)
are shared, not duplicated: the recorder is XEXPL-01's developer layer and refers to people by ID-01's permanent ids.

## 1. Phase A findings

**Natural recording points (V).**

| Point | Where | Carries |
|---|---|---|
| Decision | `World._update_npc` -> `NPCBrain.decide(n)` (only when a plan is empty) | every villager choice of what to do next |
| Execution | `World._run_plan` -> `NPCBrain.act(n, act, args)`; `false` clears the plan | every action finished or failed (about 60 action kinds) |
| Interruption | `_walk` "lost", station give-up | abandoned plans |
| Hourly and daily systems | `World._on_hour`, `World._new_day` | settlements, couriers, farms, business, chapel, reeve, guard pay, caravan, life, mines, rents, construction |
| Trade | `World.trade` (already has a test-only `trade_hook`) | every purchase |
| Items | `Inventory.add/remove/remove_all/wear` (+ `World.transfer`, 61 callers) | almost every item change; 8 sites edit items directly |
| Money | **no helper**: about 120 purse sites in 18 files and 31 treasury sites | the hardest part |
| Relationships, judgment | `Relations._raise/share`, `JudgmentStore` | centralised |
| Ownership | `World.set_owner/set_tenant` | mostly centralised |

**Decision form (V).** The top-level `decide` and every job routine are fixed priority chains (the first branch that succeeds wins);
real alternative lists exist in recipe ordering, seller and buyer searches, the labour market, contracts, credit and courtship. The
only full decision trace (`JudgmentWeighting.choose`) is built and then thrown away; no decision trace survives today.

**Existing diagnostics (V).** `World.note` (text ring of 300, saved, shown in the log), `World.stats` (482 write-only counters, not
saved), structured records in contracts, credit, prospecting, discovery, courier and settlement journals, and `economy_sim.gd` (the
conservation and determinism harness). No spreadsheet or CSV writer exists in the game; Godot 4.7's `ZIPPacker` makes an in-game
`.xlsx` writer feasible (an `.xlsx` is zipped XML). Export to a place the player can reach already exists (`SaveTransfer` with the
system file picker; Android uses its storage picker, no new permission).

**Randomness (V).** `w.rng` is drawn at about 132 sites. The recorder must never call anything that draws from it, never run a
"what-if" planning call to list alternatives (planning functions set plans and draw randomness), and only record what the live code
already computed. Off-screen villagers step on a cadence that depends on where the player is, so recording on/off is compared in the
fixed-step headless harness.

**Volume (measured and E).** 367 trades a day at 109 people (V); about 600 units produced and 460 consumed a day (V); about 12-25
decisions and 30-60 actions per villager per day (E). Estimated 60-130 events per villager per day, each with 1-3 state changes.

## 2. Coverage matrix (current status)

Every row is today **Not instrumented** or **Partially instrumented** (a counter, a text note, or a structured record without
participants, before/after values or causal links). Target column: the implementation stage that instruments it (section 9).

| System | Interaction types | Execution location | Today | Target stage |
|---|---|---|---|---|
| Decisions | priority chain branch, job routine branch, recipe order, seller/buyer search, labour market, succession, construction helper | `decide`, `_plan_job`, `_crafter`, `_seller_of`, `_buyer_for`, `job_market`, `_apprentice_for`, `construction` | Not | D2 (top level), D4 (lists) |
| Actions | about 60 `act` kinds (eat, buy, sell, craft, mine, chop, harvest, sow, hunt, deliver, sign, rest, forage, poach, recover loot ...) | `NPCBrain.act` | Partial (counters) | D2 |
| Interruptions | lost path, station give-up, failed act | `_walk`, `_run_plan` | Partial | D2 |
| Trade and transfer | purchases, gifts, pantry, deposits | `World.trade`, `World.transfer` | Partial | D2 |
| Production and consumption | work outputs, crafting, eating | `work_goods`, `work_mine`, `work_felled`, `work_craft`, eat acts | Partial | D2 |
| Needs | hunger, health, rest | per-tick in `_update_npc` | Not | D3 (hourly samples, not per tick) |
| Life | births, deaths, ageing, partners, succession, guardianship, orphans | `Life.dawn`, `make_heir`, `Guardianship` | Partial | D3 |
| Employment | job change, vacancies, posts, hiring, wages | `seek_work`, `_change_job`, `_install`, `pay_guards`, `_hiring_competition` | Partial | D3 |
| Government | tax, relief, tools, works, granary, guard pay | `reeve_day`, `pay_guards` | Partial | D3 |
| Crime | witness, confrontation, alarm, report, robbery, pickpocket | `World.witness`, `guard_confront`, `raise_alarm`, `report_crime`, `_prey_for` | Partial | D3 |
| Relationships | shared hours, gifts, help, harm, courtship, marriage | `relations.gd` | Partial (current state only) | D4 |
| Contracts, credit | offer, counter, accept, decline, deliver, lapse, debt, repay, default | `contracts.gd`, `credit.gd` | Partial (records) | D4 |
| Business, stalls, property, construction | tills, wages, stall sales, leases, rents, sites, deliveries | `business*.gd`, `stalls.gd`, `property.gd`, `construction.gd` | Partial | D4 |
| Farming, mining, manor work, chapel, feasts, quests | | their scripts | Partial | D4 |
| Settlements (abstract) | daily phases (births, marriages, market, production, wages, tax, eating, businesses), road trade, migration, couriers | `offmap.step_day`, `regions`, `migration`, `couriers` | Partial (flows, journals) | D6 (aggregate transitions only) |
| Judgment (Expansion 19) | facts, beliefs, gossip, ledgers, decision weighting | `JudgmentStore`, `JudgmentLive` | Partial (structured, traces discarded) | D5 |
| Player | about 40 `player_*` verbs and UI calls | `world.gd`, `main.gd` | Partial | D3 |
| Save/load, succession | | `to_dict`, `load_dict`, `make_heir` | Partial | D3 |
| Expansions 20, 21, 22 (hybrid), 23 | their future systems | | Not applicable until built | hooks defined in D1; instrumented with each feature |

The matrix is kept as data (`recorder_coverage.json`) and exported as the Coverage sheet; each row's status is set by tests that
exercise the path, never by a list of system names.

## 3. Diagnostic schema (relational; schema `mml-recorder/1`)

| Table | Key fields |
|---|---|
| session | session id, build, commit, seed, save version, flags (judgment, economy, civic ...), start/end, recording mode, chunk count, record counts per table, completeness |
| event | event id (session sequence), interaction id, parent id, correlation id, day, minute, tick, settlement, x, y, system, subsystem, category, subtype, actor, outcome (ok, failed, refused, interrupted, abandoned), reason code, rule id |
| participant | event id, entity ref (permanent id: `p:<id>`, household, business, settlement, office, resource), role |
| decision | event id, actor, decision kind, chosen option, basis (first-passing branch, highest score, nearest, cheapest, rule), tie-break inputs |
| alternative | event id, option, evaluated (yes / not evaluated), feasible, rejection code, score |
| factor | event id, option, factor, value, unit, source (need, personality, relation, trust, price, stock, law ...), evaluated flag |
| state_change | event id, entity ref, property (typed: item, coins, treasury, deposit, owner, job, hunger, health, household, residence, office, relation, ledger ...), before, after, delta, authority (the owning system) |
| link | from event, to event, kind (caused, fulfils, obligation, part of, same object), via (contract id, debt id, plan id ...) |
| alert | alert id, severity (violation, warning), rule, entities, values, event, day |
| sample | day, hour, entity, needs and balances (hourly samples for per-tick quantities) |

Values are typed; codes come from one table (`recorder_codes.json`, the same code table XEXPL-01's in-world and player layers will
read). Anything the engine did not evaluate is stored as "not evaluated", never as an invented value.

## 4. Causal mapping

Links are made only where the code knows the cause; nothing is linked because it happened nearby in time.
- **Plan context:** `decide` opens a decision event; every action of that plan carries it as parent; every state change inside an
  action carries the action as parent (a context stack in the recorder, set and cleared at the choke points).
- **Object threads:** contracts, debts, stall sales, courier jobs, construction sites, vacancies and offices carry an object id; every
  event touching the object links to its previous event (`fulfils`, `obligation`), so a contract's offer, acceptance, deliveries,
  lapse and the default that followed form one traversable chain across days.
- **System passes:** hourly and daily passes (reeve's day, settlement step) open a pass event; their changes are its children.
- **Failures as causes:** a failed purchase records the missing seller or the shortfall (the reason the code returned), which links
  to the shortage's state (no seller had stock: the stock samples of that hour).
- **Unattributed changes** (a coin or item change outside any open event) are recorded under an "unattributed" event and raised as an
  alert: that is how hidden creation or loss is found.
The exporter offers backward and forward traversal (all ancestors of an event, all descendants of an action, all events of an
entity) as precomputed columns and a small query script.

## 5. Storage

- **Buffer:** a bounded ring in memory (default 50,000 rows); flushed at each game-hour boundary.
- **Archive:** append-only chunk files per table per game day under `user://recorder/<session>/`, gzip compressed
  (`FileAccess.open_compressed`, available on Android, Windows and Linux); each chunk has a header (schema, session, first and last
  sequence) and a footer (row count, checksum). An interrupted chunk lacks its footer and is reported as truncated on the next start
  (recovery keeps everything before it).
- **Limits:** configurable storage cap per session. **When the cap is reached the recorder stops and marks the session incomplete
  with the exact day and sequence; it never drops older records or samples silently** (owner decision R-2 below).
- **Rotation:** one chunk set per game day; sessions are listed and deletable from the export screen.
- Writing happens off the simulation's decision path (flush at the hour boundary; a background thread may compress), so it cannot
  change outcomes.

## 6. Excel export and package

- **Package** (`mml-recorder-<session>.zip`): the workbook(s), the complete archive chunks, `session.json`, `coverage.json`,
  `dictionary.json`, `alerts.json`, and a `README.txt` explaining the tables for ChatGPT or another tool.
- **Workbook:** the owner's sheets (Overview, Interactions, Events, Participants, Decisions, Decision Factors, Alternatives, State
  Changes, Causal Links, Activities, Inventory, Currency, Transactions, Contracts, Production, Relationships, Judgment, Gossip,
  Population, Households, Businesses, Settlements, Politics, Crime, Alerts, Coverage, Metadata, Data Dictionary). Topic sheets are
  filtered views of the event and state tables (no duplicate copies), with event ids for linking.
- **Size:** a sheet holds 1,048,575 rows; larger tables continue in numbered sheets (`Events 2`), and beyond a workbook size limit
  (about 200 MB) in numbered workbooks. Nothing is discarded; the archive is authoritative and the export reports both counts.
- **Writer:** an in-game streaming `.xlsx` writer (zipped XML through `ZIPPacker`, rows written as they are read from the archive,
  never the whole sheet in memory), so Android can export without a computer; plus `tools/recorder_xlsx.py` (Python) to convert an
  archive on a PC, producing the same workbook (tested to agree).
- **Agreement check:** the export counts rows per table in the archive and in the workbook and writes both to Metadata; a mismatch
  is an alert.

## 7. Export workflow

- **Desktop (Windows, Linux):** Settings, Diagnostics: start or stop recording, see the session size and completeness, Export: the
  system folder picker saves the package (the existing `SaveTransfer` path).
- **Android:** the same screen; Export opens the Android storage picker (Downloads, Drive, a USB stick); no new permission (the
  existing SAF route). Large sessions export in steps with a progress bar; the game is paused while exporting.
- **Headless:** `economy_sim.gd --record <dir>` records a run and writes the package, for long autonomous runs on GitHub Actions.

## 8. Estimates (E; to be measured in Phase E)

Assumptions: 60-130 events per villager per day, 1-3 state changes each, about 20 decisions per villager per day with about 8
factors and 3 alternatives each, about 60-90 bytes per row uncompressed, gzip about 8-10x.

| Village | Rows per game day | Uncompressed per day | Compressed per day | 100 game days compressed | Workbook rows per 100 days |
|---|---|---|---|---|---|
| 100 people | 40-60 k | 3-5 MB | 0.4-0.6 MB | 40-60 MB | 4-6 M (several sheets) |
| 500 people | 200-300 k | 15-25 MB | 2-3 MB | 200-300 MB | 20-30 M (several workbooks) |
| 1,000 people | 400-600 k | 30-50 MB | 4-6 MB | 400-600 MB | 40-60 M (archive needed) |

- **CPU:** building a row in GDScript costs roughly 5-15 microseconds. A game day lasts 12 real minutes, so at 100 people about 70
  rows a second (about 1 ms a second, near zero); at 1,000 people about 700 a second (about 10 ms a second, about 1% of a frame
  budget averaged, with bursts at hour boundaries spread by the flush). Headless simulation runs about 7 seconds a game day today;
  recording would add an estimated 15-40% to headless runs.
- **Memory:** the ring buffer (default 50,000 rows) is about 10-25 MB; nothing else grows.
- **Disk:** as in the table; a phone with a 1 GB cap holds about 160-250 game days at 100 people.
- **Export time:** writing millions of workbook rows in GDScript is slow (estimated minutes for a 100-day, 100-person session on a
  phone); the PC converter is faster.

## 9. Implementation order (after approval)

- **D1 Core:** recorder class (attached only when enabled, never draws randomness), schema, codes table, ring buffer, chunk writer,
  recovery, session metadata; on/off determinism test in `economy_sim` (fingerprints identical).
- **D2 Choke points:** decide (which branch, with the guard values it read; later branches "not evaluated"), act (outcome and
  reason), interruptions, trade, transfer, inventory changes (an owner tag on each inventory, diagnostic only), coins (before/after
  balances of the participants at each event, reconciled against `total_coins`; changes outside any event raise "unattributed").
- **D3 Systems:** hourly and daily passes, life and succession, employment and government, crime, needs samples, player verbs,
  save/load.
- **D4 Records:** relations, contracts, credit, business, stalls, property, construction, farming, mining, manor work, chapel,
  feasts, quests; decision lists (recipes, sellers, labour market).
- **D5 Expansion 19:** judgment facts, beliefs, gossip, ledgers, and the decision traces `JudgmentWeighting` already builds.
- **D6 Settlements:** abstract daily phases as aggregate transitions with inputs and outputs (no invented individual acts);
  migration and couriers; detailed/abstract transitions when Expansion 22 builds them.
- **D7 Validation:** invariant checks (identity, conservation, reservations, ownership, disabled flags, load restoration) at day
  boundaries; anomaly warnings computed at export time from the archive (no simulation cost).
- **D8 Export:** package, in-game streaming workbook writer, PC converter, the export screen.
- Hooks for Expansions 20-23 are defined in D1 (code table entries, entity kinds) and filled as each feature is built.

## 10. Build 19 integration and tests

- Branch: `wip/recorder` from the Expansion 19 branch after the identity foundation joins it (the recorder needs permanent ids).
- Tests: on/off fingerprints identical (`economy_sim`, several seeds); a 100-day player-idle autonomous run recorded and exported;
  a multi-day causal trace (a contract that lapsed traced back through its offer, the missing input and the failed purchases);
  archive and workbook counts agree; recovery after an interrupted session; storage cap stops with the session marked incomplete;
  invariants raise on seeded faults (a coin created, a goods double claim, a reused id); Android export checked by the owner on a
  phone (automation cannot reach a phone).
- Release: the recorder ships switched off in normal builds; Build 19 is released only when its own acceptance criteria pass.

## 11. Risks and dependencies

1. **Identity foundation (ID-01)** must land first: the recorder's entity references are permanent ids.
2. **Money** has no single choke point: D2's balance reconciliation catches unattributed changes but cannot name the line that made
   them until the hottest sites move to one transfer helper (a separate, approved refactor if wanted).
3. **Decision depth:** the priority chain records which branch won and the values its guards read; it cannot report scores the code
   never computes. Richer factors appear only where the code ranks options (and where Expansion 19 weighting runs).
4. **Volume:** 500-1,000 people produce hundreds of MB per 100 days; phones need the cap; spreadsheets need splitting.
5. **Determinism:** recorded on/off must stay identical; any accidental call into planning code or `w.rng` would break it (tested).
6. **Scope:** the directive's breadth is large; D1-D3 give a useful recorder early; D4-D8 follow.

## 12. Decisions for the owner

- **R-1 Where it runs:** recording available in playtest and development builds only (Settings, Diagnostics), off by default,
  never in public releases? (Recommended.)
- **R-2 When storage fills:** stop and mark the session incomplete (recommended, never loses evidence silently), or rotate out the
  oldest days (keeps recording, loses the start)?
- **R-3 Per-tick quantities** (hunger, movement steps, work minutes): recorded as hourly samples and as events only when they cross a
  threshold (starving, arriving), rather than every frame? (Recommended; per-frame recording would multiply volume about 100 times.)
- **R-4 Money refactor:** move the hottest coin sites to one transfer helper (better attribution, touches Build 18 code paths, gate
  must stay identical), or rely on balance reconciliation only (no gameplay code change)?
