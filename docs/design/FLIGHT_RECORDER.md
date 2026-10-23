# Flight recorder: implemented data contract (REC-19, schema `mml-recorder/1`)

Status: stage D1 (core) and the first D2 choke points, on `wip/recorder`. Design and decisions: `docs/design/FLIGHT_RECORDER_DESIGN.md`,
`docs/directives/2026-10-23_recorder_decisions.md` (REC-D1 to REC-D4). Developer reference only; the recorder is not a player feature and
has no wiki page (it is off by default and absent from public releases).

## 1. What exists

| Piece | File |
|---|---|
| Core: tables, context stack, object threads, bounded buffer, chunk writer, session record, recovery, storage cap | `game/scripts/core/recorder/flight_recorder.gd` (`FlightRecorder`) |
| Archive reader and chunk format | `game/scripts/core/recorder/recorder_archive.gd` (`RecorderArchive`) |
| The game's instrumentation points (decide, act, interruptions, trade, transfer, coin audit, hourly samples) | `game/scripts/core/recorder/world_recorder.gd` (`WorldRecorder extends FlightRecorder`) |
| Switch and limits | `game/data/recorder.json` (`mml-recorder-config/1`) |
| The one code table (shared with XEXPL-01 later) | `game/data/recorder_codes.json` (`mml-recorder-codes/1`) |
| Coverage, status per system, never wider than what is instrumented | `game/data/recorder_coverage.json` (`mml-recorder-coverage/1`) |
| Tests | `game/tests/recorder_test.gd`; the on/off determinism comparison is `economy_sim.gd --record DIR` |

Switch: `recorder.json "enabled"` is `false`. `World.setup` creates a recorder only when `FlightRecorder.enabled()` is true
(`FlightRecorder.test_enabled` for tests, or `WorldRecorder.attach(world, {"root": dir})` as `economy_sim.gd --record DIR` does).
When off, `World.recorder` is `null`: no object, no file, no directory; each instrumentation point is one guarded call
(`if recorder != null`). The recorder never draws from `w.rng` or any generator, never calls planning or decision code, and never
changes game state; it stores what the instrumented code already computed. The world's `to_dict` has no recorder section.

## 2. Hooks in the game (what changed outside `scripts/core/recorder/`)

- `NPCBrain.decide` is now a wrapper: with no recorder it calls `_decide(n)`, which is the unchanged priority chain except that each
  `return` names the winning branch (read only by the recorder).
- `World._act_step` wraps the two `brain.act` calls of `_run_plan` (event begins before the action, ends with ok or failed).
- `World._walk` (two "lost" returns) and the station wait give-up call `recorder.interruption` before the plan is cleared.
- `World.trade` and `World.transfer`: begin before the mutation, end after it (before and after values), refused calls recorded too.
- `World._on_hour` calls `recorder.hour()` first: flush, coin audit, hourly samples. `World.dispose` calls `recorder.finish()`.

## 3. Tables

Rows are JSON arrays; the first column of every row is `seq`, the session-wide row sequence. Entity references are the existing ids:
`p:<NPC.id>`, `p:player`, `hh:<n>`, `manor`, `granary`, `world`, and `inv:?` for a store whose owner the recorder cannot name.
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

Same run with and without `--record`: every checkpoint of `economy_sim` (fingerprint including the RNG state, currency, ledgers) is identical
(fingerprint `cc3edc39e29c7b7b95e293a4f28cb463` both ways). Wall time 72.8 s unrecorded, 92.2 s recorded (+27%). Rows over the 10 days:
event 65,759; participant 68,531; decision 51,149; alternative 840,516; factor 388,321; state_change 9,019; sample 26,686; alert 499;
link 0 (total about 1.45 million). Archive 10.5 MB for 10 days; per day 0.5 MB (day 1) growing to 1.6 MB (day 10) as villagers decide
more often (8,300 decisions on day 10), 4.5 to 19 MB uncompressed. `alternative` is 46% of the bytes, `factor` 26%, `event` 12%.
Peak buffer 30,447 rows (one busy game hour; no early flush at the 50,000 default). Two-day run: 1.2 MB, 137,204 rows.
The decision detail is the dominant cost; limiting `alternative` and `factor` rows to the winner is the first reduction if volume matters.

## 7. Known limits (also in `recorder_coverage.json`)

Not recorded: production and consumption effects, life events, employment, government, crime, relations, contracts, credit, business,
stalls, property, construction, farming, mining, manor work, chapel, feasts, quests, settlements, judgment, most player verbs, save and load
(stages D3 to D6). Coin changes outside `World.trade` are detected hourly, not attributed. Item changes outside `World.trade`/`transfer` are
not seen. Chests, carts, stalls and loot appear as `inv:?` in transfers. Decision records stop at the top-level branch. Jobs that run
`_plan_job` internally (most villagers by day) show only `job` as the chosen branch.
