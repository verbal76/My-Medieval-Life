class_name WorldRecorder
extends FlightRecorder
## The flight recorder's instrumentation points for the live World (REC-19, stage D1 + first D2 choke points). Created only
## when the recorder is enabled (attach); World.recorder is null otherwise and every call site is one guarded line.
## It only reads: it never draws from w.rng, never calls planning or decision code, never changes game state.
##
## Instrumented here (see game/data/recorder_coverage.json for the status of each and everything that is not):
##   decide        NPCBrain.decide     one decision event: the branch of the priority chain that won, the guard values read,
##                                     the branches before it as passed over and after it as "not evaluated"
##   act           World._run_plan     one action event per executed step (outcome ok / failed), child of the plan's decision
##   interruption  World._walk, the station wait   walk lost / station give-up (interrupted / abandoned)
##   trade         World.trade         one transaction event, participants, coin and item state changes (accepted or refused)
##   transfer      World.transfer      the same for items without money
##   coin audit    hourly              recorded coin changes against each holder's purse and World.total_coins: any
##                                     difference is an "unattributed" event and an alert (REC-D4; no coin site is rewritten)
##   samples       hourly              hunger, health, cell, doing and coins of each living villager and the player (REC-D3)

var w                                   # the World
var _plan_ev := {}                      # npc id -> [decision event, the plan Array it made, interaction]
var _coin_seen := {}                    # holder ref -> coins at the last audit
var _coin_delta := {}                   # holder ref -> coin change recorded since the last audit
var _coin_net := 0                      # all recorded coin changes since the last audit (a trade nets to zero)
var _total_seen := 0
var _src_seen := 0
var _audited := false
var _inv_refs := {}                     # inventory instance id -> owner ref
var _inv_hour := -1
var _chain: Array = []                  # the decision chain's branch ids, in order
var _chain_factors := {}                # branch id -> factor names it reads
var samples_on := true
# SIM-GATE-01: what the hourly snapshot counts (read only; nothing here is read by the game)
var _hour_n := {}                       # counter -> events of that kind ended since the last snapshot
var _births := 0                        # life births and deaths recorded since the session began
var _deaths := 0
var _stats_seen := {}                   # w.stats at the last snapshot (only the keys that changed are written)
var _snap_us := 0                       # Time.get_ticks_usec at the last snapshot
var _chases := {}                       # fighter id -> {target, t0 (game minutes), d0, strikes, x, y}: a chase begun and not yet ended


## Create the recorder for `world` and attach it (World.recorder). `config` overrides recorder.json keys.
static func attach(world, config := {}) -> WorldRecorder:
	var r := WorldRecorder.new(config, {})
	r.w = world
	r.samples_on = bool(r.cfg.get("hourly_samples", true))
	r.meta = {"seed": int(world.seed), "save_version": World.SAVE_VERSION, "commit": OS.get_environment("MML_COMMIT") if OS.get_environment("MML_COMMIT") != "" else "unknown",
		"flags": {"recorder": true, "judgment": world.judgment != null, "economy": "no such flag in this build", "civic": "no such flag in this build"}}
	for b in r.codes.decision_chain:
		r._chain.append(str(b.id))
		r._chain_factors[str(b.id)] = b.factors
	world.recorder = r
	r._write_session()
	return r


func _now() -> Array:
	return [w.day(), fmod(w.minutes, World.DAY)]


## A person's reference is their permanent person id (ID-01): `p:<id>`. The player character is `p:<PlayerState.pid>`, the same
## kind of reference as anyone's and stable across succession (an heir who was the player's child keeps their own id); that the
## person is the player at the time is a role marker (`part`: the participant role gets the suffix `:player`), never a separate
## identity. `p:player` is only the fallback for a player without a pid (a bare test world).
static func ref_of(o) -> String:
	if o is NPC:
		return "p:%d" % o.id
	if o is PlayerState:
		return "p:%d" % o.pid if o.pid > 0 else "p:player"
	return "obj:?"


## A participant role, marked `:player` when the participant is the player character.
static func role_of(o, role: String) -> String:
	return role + ":player" if o is PlayerState else role


## A participant row for a person (NPC or PlayerState); `null` is skipped.
func part(ev: int, o, role: String) -> void:
	if o != null:
		participant(ev, ref_of(o), role_of(o, role))


func _xy(o) -> Dictionary:
	if o is NPC:
		var c: Vector2i = o.cell()
		return {"x": c.x, "y": c.y}
	if o is PlayerState:
		return {"x": int(o.pos.x), "y": int(o.pos.y)}
	return {}


## The owner of an inventory, by the stores the world keeps; "inv:?" for a store the recorder cannot name (chests, carts, stalls).
func inv_ref(inv: Inventory) -> String:
	var key := inv.get_instance_id()
	if _inv_refs.has(key):
		return str(_inv_refs[key])
	var hour_abs := int(w.minutes / 60.0)
	if _inv_hour != hour_abs:                    # rebuild at most once an hour, on a miss
		_inv_hour = hour_abs
		_inv_refs.clear()
		for n: NPC in w.npcs:
			_inv_refs[n.inv.get_instance_id()] = "p:%d" % n.id
		_inv_refs[w.player.inv.get_instance_id()] = ref_of(w.player)
		for i in w.households.size():
			_inv_refs[(w.households[i].pantry as Inventory).get_instance_id()] = World.hh_ref(i)
		_inv_refs[w.granary.get_instance_id()] = "granary"
		if _inv_refs.has(key):
			return str(_inv_refs[key])
	return "inv:?"


func _note_state_change(ref: String, prop: String, delta, authority: String) -> void:
	if authority != "audit" and authority != "summary" and prop == "coins" and typeof(delta) == TYPE_INT:
		_coin_delta[ref] = int(_coin_delta.get(ref, 0)) + int(delta)
		_coin_net += int(delta)


# ---------------------------------------------------------------- decide --------------------
## Before NPCBrain.decide: open the decision event and read the values the guards will read (the planner changes none of them).
func decide_begin(n: NPC) -> Dictionary:
	_plan_ev.erase(n.id)
	var c := n.cell()
	var ev := begin("brain", "decide", "decision", "plan_next", ref_of(n), {"x": c.x, "y": c.y})
	return {"ev": ev, "hunger": n.hunger, "hp_ratio": n.hp / maxf(0.001, n.max_hp), "hour": w.hour(), "role": n.role, "job": n.job,
		"clan": n.clan}


## After NPCBrain.decide with the branch that took the decision (the chain's own return value).
func decide_end(pre: Dictionary, n: NPC, branch: String) -> void:
	var ev: int = pre.ev
	if ev <= 0:
		return
	var actor := ref_of(n)
	participant(ev, actor, "actor")
	decision(ev, actor, "plan_next", branch, "first_passing_branch")
	var won := _chain.find(branch)
	var seen := {}                                  # a factor read by several branches is stored once, under the first that read it
	for i in _chain.size():
		var opt: String = _chain[i]
		if won >= 0 and i > won:
			alternative(ev, "after:" + branch, NOT_EVALUATED, NOT_EVALUATED, "not_reached")      # every later branch of the chain, one row
			break
		if i == won:
			alternative(ev, opt, "yes", true)
		else:
			alternative(ev, opt, "yes", false, "guard_or_planner_declined")
		for f in _chain_factors[opt]:
			if not seen.has(f):
				seen[f] = true
				factor(ev, opt, str(f), _factor_value(pre, str(f)), str(codes.factor_units.get(f, "")), str(codes.factor_sources.get(f, "")))
	var steps := []
	for s in n.plan:
		steps.append(str(s.k) + (":" + str(s.act) if s.has("act") else ""))
		if steps.size() >= 6:
			break
	_note_branch(branch)
	if not n.plan.is_empty():
		_plan_ev[n.id] = [ev, n.plan, _open_interaction(ev)]
	end(ev, "ok" if not n.plan.is_empty() else "empty", "", "doing=%s; plan=%s" % [n.doing, ",".join(steps)])


func _open_interaction(ev: int) -> int:
	return int((_open[ev] as Array)[EV_INTERACTION]) if _open.has(ev) else ev


func _note_branch(branch: String) -> void:
	if not _chain.has(branch):
		unknown_codes["decision_chain:" + branch] = int(unknown_codes.get("decision_chain:" + branch, 0)) + 1


func _factor_value(pre: Dictionary, f: String):
	match f:
		"hunger": return snappedf(float(pre.hunger), 0.01)
		"hp_ratio": return snappedf(float(pre.hp_ratio), 0.001)
		"hour": return snappedf(float(pre.hour), 0.01)
		"role": return str(pre.role)
		"job": return str(pre.job)
		"clan": return str(pre.clan)
		"eat_below": return float(GameData.b("eat_below"))
		"seek_below": return float(GameData.b("rest").seek_below)
	return NOT_EVALUATED


# ---------------------------------------------------------------- act -----------------------
## Before a plan step's action: its event is a child of the plan's decision (only while the plan is the one the decision made).
func act_begin(n: NPC, step: Dictionary) -> int:
	var parent := -1
	var inter := -1
	var pe = _plan_ev.get(n.id)
	if pe != null and is_same(pe[1], n.plan):
		parent = int(pe[0])
		inter = int(pe[2])
	var c := n.cell()
	var opts := {"parent": parent, "x": c.x, "y": c.y, "detail": _args_text(step.get("args", {}))}
	if inter >= 0:
		opts["interaction"] = inter
	var ev := begin("brain", "act", "action", str(step.act), ref_of(n), opts)
	participant(ev, ref_of(n), "actor")
	return ev


func act_end(ev: int, n: NPC, ok: bool) -> void:
	end(ev, "ok" if ok else "failed", "" if ok else "act_returned_false")
	if n.plan.is_empty():
		_plan_ev.erase(n.id)


func _args_text(args: Dictionary) -> String:
	if args.is_empty():
		return ""
	var t := JSON.stringify(args)
	return t if t.length() <= 160 else t.substr(0, 157) + "..."


## A plan given up: walk lost (interrupted) or a station wait run out (abandoned). Call before the plan is cleared.
func interruption(n: NPC, subtype: String, outcome: String, reason: String, detail := "") -> void:
	var parent := -1
	var inter := -1
	var pe = _plan_ev.get(n.id)
	if pe != null and is_same(pe[1], n.plan):
		parent = int(pe[0])
		inter = int(pe[2])
	var c := n.cell()
	var opts := {"parent": parent, "x": c.x, "y": c.y, "detail": detail}
	if inter >= 0:
		opts["interaction"] = inter
	var ev := begin("brain", "walk" if subtype.begins_with("walk") else "station", "interruption", subtype, ref_of(n), opts)
	participant(ev, ref_of(n), "actor")
	end(ev, outcome, reason)
	_plan_ev.erase(n.id)


# ---------------------------------------------------------------- trade / transfer ----------
## Before World.trade mutates: returns the open event and the values before.
func trade_begin(buyer: Object, seller: Object, id: String, qty: int, total: int) -> Array:
	var ev := begin("economy", "trade", "transaction", "trade", ref_of(buyer), _xy(buyer).merged({"detail": "item=%s qty=%d total=%d" % [id, qty, total]}))
	return [ev, int(buyer.coins), int(seller.coins), buyer.inv.count(id), seller.inv.count(id)]


func trade_end(t: Array, buyer: Object, seller: Object, id: String) -> void:
	var ev: int = t[0]
	if ev <= 0:
		return
	var b := ref_of(buyer)
	var s := ref_of(seller)
	part(ev, buyer, "buyer")
	part(ev, seller, "seller")
	state_change(ev, b, "coins", t[1], int(buyer.coins), "world.trade")
	state_change(ev, s, "coins", t[2], int(seller.coins), "world.trade")
	state_change(ev, b, "item:" + id, t[3], buyer.inv.count(id), "world.trade")
	state_change(ev, s, "item:" + id, t[4], seller.inv.count(id), "world.trade")
	_hour_n["trade_coins"] = int(_hour_n.get("trade_coins", 0)) + maxi(0, int(t[1]) - int(buyer.coins))
	end(ev, "ok")


## A trade the rules refused: the reason is read from the same conditions World.trade tested.
func trade_refused(buyer: Object, seller: Object, id: String, qty: int, price_each: int, total: int) -> void:
	var reason := "invalid_trade"
	if not (qty <= 0 or price_each < 0 or buyer == seller):
		if int(buyer.coins) < total:
			reason = "buyer_short_of_coins"
		elif not seller.inv.has(id, qty):
			reason = "seller_lacks_item"
		else:
			reason = "buyer_inventory_full"
	var ev := begin("economy", "trade", "transaction", "trade", ref_of(buyer), _xy(buyer).merged({"detail": "item=%s qty=%d total=%d" % [id, qty, total]}))
	part(ev, buyer, "buyer")
	part(ev, seller, "seller")
	end(ev, "refused", reason)


func transfer_begin(from: Inventory, to: Inventory, id: String, qty: int) -> Array:
	var ev := begin("economy", "transfer", "transaction", "transfer", inv_ref(from), {"detail": "item=%s qty=%d" % [id, qty]})
	return [ev, from.count(id), to.count(id)]


func transfer_end(t: Array, from: Inventory, to: Inventory, id: String) -> void:
	var ev: int = t[0]
	if ev <= 0:
		return
	var a := inv_ref(from)
	var b := inv_ref(to)
	participant(ev, a, "giver")
	participant(ev, b, "receiver")
	state_change(ev, a, "item:" + id, t[1], from.count(id), "world.transfer")
	state_change(ev, b, "item:" + id, t[2], to.count(id), "world.transfer")
	end(ev, "ok")


func transfer_refused(from: Inventory, to: Inventory, id: String, qty: int) -> void:
	var ev := begin("economy", "transfer", "transaction", "transfer", inv_ref(from), {"detail": "item=%s qty=%d" % [id, qty]})
	participant(ev, inv_ref(from), "giver")
	participant(ev, inv_ref(to), "receiver")
	end(ev, "refused", "from_lacks_item" if not from.has(id, qty) else "to_cannot_take")


## Every event that ends is tallied for the next hourly snapshot (SIM-GATE-01); the row itself is written by the base class.
func end(id: int, outcome := "ok", reason := "", detail := "") -> void:
	var row = _open.get(id)
	super.end(id, outcome, reason, detail)
	if row == null:
		return
	var cat := str(row[12])
	var sub := str(row[13])
	_hour_n["events"] = int(_hour_n.get("events", 0)) + 1
	var key := ""
	match cat:
		"transaction":
			key = "trades" if sub == "trade" else "transfers"
		"action":
			key = "actions"
			if outcome != "ok":
				_hour_n["actions_failed"] = int(_hour_n.get("actions_failed", 0)) + 1
		"interruption":
			key = "walk_lost" if sub == "walk_lost" else ""
		"crime":
			key = "crimes"
		"combat":
			key = "chases"
		"life":
			if sub == "birth":
				_births += 1
			elif sub == "death":
				_deaths += 1
	if key != "":
		_hour_n[key] = int(_hour_n.get(key, 0)) + 1


func alert(severity: String, rule: String, entities: String, values: String, ev := -1) -> int:
	_hour_n["alerts"] = int(_hour_n.get("alerts", 0)) + 1
	return super.alert(severity, rule, entities, values, ev)


# ---------------------------------------------------------------- the hour ------------------
## Called at each game-hour boundary (World._on_hour): write the buffer, audit the coins, take the hourly samples and the
## village snapshot.
func hour() -> void:
	flush()
	if stopped or finished:
		return
	_audit_coins()
	_close_stale_chases()
	if samples_on:
		for n: NPC in w.npcs:
			if n.alive:
				var c := n.cell()
				sample("p:%d" % n.id, snappedf(n.hunger, 0.1), snappedf(n.hp, 0.1), c.x, c.y, n.doing, n.coins)
		sample(ref_of(w.player), snappedf(w.player.hunger, 0.1), snappedf(w.player.hp, 0.1), int(w.player.pos.x), int(w.player.pos.y), "", w.player.coins)
	snapshot_row()


## SIM-GATE-01: the village in one row (FlightRecorder.COLUMNS.snapshot). Reads only: no random draw, no call that changes
## state (judgment's counts() flushes its gossip, so its facts are counted directly).
func snapshot_row() -> void:
	var alive := 0
	var adults := 0
	var employed := 0
	var children := 0
	var elders := 0
	var bandits := 0
	var hunger_sum := 0.0
	var hunger_min := 100.0
	var starving := 0
	var hp_sum := 0.0
	var idle := 0
	var lost := 0
	var fighting := 0
	var guards := 0
	var engaged := 0
	var vcoins := 0
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		if n.role == "bandit":
			bandits += 1
			continue
		alive += 1
		vcoins += n.coins
		hunger_sum += n.hunger
		hunger_min = minf(hunger_min, n.hunger)
		hp_sum += n.hp / maxf(1.0, n.max_hp)
		if n.hunger <= 0.0:
			starving += 1
		match n.role:
			"adult":
				adults += 1
				if n.job != "":
					employed += 1
			"child":
				children += 1
			"elder":
				elders += 1
		if n.doing == "idle":
			idle += 1
		elif n.doing == "lost":
			lost += 1
		if n.target != -1:
			fighting += 1
		if n.job == "guard":
			guards += 1
			if n.target != -1:
				engaged += 1
	var purses := []
	for h in w.households.size():
		if not w.brain._members(h).is_empty():
			purses.append(w.property.purse(World.hh_ref(h)))
	purses.sort()
	var ties := 0
	var friends := 0
	var courting := 0
	if w.relations != null:
		for k in w.relations.ties:
			var t: Dictionary = w.relations.ties[k]
			ties += 1
			if bool(t.get("friends", false)):
				friends += 1
			if str(t.get("stage", "")) != "":
				courting += 1
	var delta := {}
	for k in w.stats:
		var v = w.stats[k]
		var was = _stats_seen.get(k, 0)
		if typeof(v) in [TYPE_INT, TYPE_FLOAT] and v != was:
			delta[k] = snappedf(float(v) - float(was), 0.01)
			_stats_seen[k] = v
	var now_us := Time.get_ticks_usec()
	var wall_ms = snappedf((now_us - _snap_us) / 1000.0, 0.1) if _snap_us > 0 else NOT_EVALUATED
	_snap_us = now_us
	var nf := float(maxi(1, alive))
	snapshot([int(_now()[0]), int(float(_now()[1]) / 60.0), alive, purses.size(), adults,
		employed, children, elders, bandits, snappedf(hunger_sum / nf, 0.1), snappedf(hunger_min if alive > 0 else 0.0, 0.1), starving,
		snappedf(hp_sum / nf, 0.001), idle, lost, fighting, guards, engaged, int(w.total_coins()), vcoins, int(w.treasury), int(w.coin_sources),
		int(purses[0]) if not purses.is_empty() else 0, int(purses[purses.size() / 2]) if not purses.is_empty() else 0,
		int(purses[-1]) if not purses.is_empty() else 0, snappedf(float(w.food_days), 0.01), w.granary.count("wheat"), _births, _deaths,
		ties, friends, courting, (w.judgment.facts.size() if w.judgment != null else NOT_EVALUATED), w.player.crimes.size(),
		int(_hour_n.get("events", 0)), int(_hour_n.get("trades", 0)), int(_hour_n.get("trade_coins", 0)), int(_hour_n.get("transfers", 0)),
		int(_hour_n.get("actions", 0)), int(_hour_n.get("actions_failed", 0)), int(_hour_n.get("walk_lost", 0)), int(_hour_n.get("crimes", 0)),
		int(_hour_n.get("chases", 0)), int(_hour_n.get("alerts", 0)), delta, wall_ms, OS.get_static_memory_usage()])
	_hour_n.clear()


# ---------------------------------------------------------------- chases --------------------
## SIM-GATE-01: NPCBrain.fight, every tick a fighter has a target. A chase opens when the fighter's target is new to the
## recorder (the code that set NPC.target is not named: raise_alarm, deliver_report, a blow answered ...) and ends at the
## line of fight() that clears the target, with that line's reason; one cleared elsewhere (the player's death, a kill by
## someone else) is closed at the next hour as cleared_elsewhere. Reads positions only.
func chase_tick(n: NPC) -> void:
	var c = _chases.get(n.id)
	if c != null and int(c.target) == n.target:
		return
	if c != null:
		_chase_close(n, "retargeted")
	var cell := n.cell()
	_chases[n.id] = {"target": n.target, "t0": w.minutes, "day0": w.day(), "d0": _chase_dist(n), "strikes": 0, "x": cell.x, "y": cell.y}


func chase_strike(n: NPC) -> void:
	if _chases.has(n.id):
		_chases[n.id].strikes = int(_chases[n.id].strikes) + 1


## The line of fight() that clears the target: `reason` is its reason code (recorder_codes.json "reasons").
func chase_end(n: NPC, reason: String) -> void:
	if _chases.has(n.id):
		_chase_close(n, reason)


func _chase_dist(n: NPC) -> float:
	if Life.is_player_id(n.target):
		return snappedf(n.pos.distance_to(w.player.pos), 0.01)
	var t: NPC = w.npc(n.target)
	return snappedf(n.pos.distance_to(t.pos), 0.01) if t != null else -1.0


func _chase_close(n: NPC, reason: String) -> void:
	var c: Dictionary = _chases[n.id]
	_chases.erase(n.id)
	var who := "guard" if n.job == "guard" else ("bandit" if n.role == "bandit" else "villager")
	var tref := ref_of(w.player) if Life.is_player_id(int(c.target)) else _pref(int(c.target))
	var mins := float(w.minutes) - float(c.t0)
	var outcome := "ok" if reason in ["target_slain", "robbed"] else ("abandoned" if reason in ["out_of_range", "near_bandit_camp", "blocked", "bandit_low_hp"] else "interrupted")
	var ev := begin("combat", "chase", "combat", "chase_" + who, ref_of(n), {"parent": -1, "x": int(c.x), "y": int(c.y)})
	participant(ev, ref_of(n), who)
	participant(ev, tref, "target:player" if Life.is_player_id(int(c.target)) else "target")
	end(ev, outcome, reason, "start_day=%d start_minute=%.2f minutes=%.2f seconds=%.2f d0=%.2f d_end=%.2f strikes=%d" % [int(c.day0),
		fmod(float(c.t0), World.DAY), mins, mins / maxf(0.001, float(GameData.b("game_minutes_per_second"))), float(c.d0), _chase_dist(n), int(c.strikes)])


func _close_stale_chases() -> void:
	var ids := _chases.keys()
	ids.sort()
	for id in ids:
		var n: NPC = w.npc(int(id))
		if n == null or not n.alive or n.target != int(_chases[id].target):
			if n == null:
				_chases.erase(id)
				continue
			_chase_close(n, "cleared_elsewhere")


## REC-D4: balance auditing, not a rewrite of the coin sites. A holder's purse is compared with its last audited balance
## plus the coin changes the recorder saw; World.total_coins with its last value plus those changes plus the change in
## World.coin_sources (coins crossing the village boundary). A difference is an "unattributed" event and an alert.
func _audit_coins() -> void:
	var total: int = w.total_coins()
	var src: int = int(w.coin_sources)
	var holders := {}
	for n: NPC in w.npcs:
		holders["p:%d" % n.id] = n.coins
	holders[ref_of(w.player)] = w.player.coins
	holders["manor"] = w.treasury
	if not _audited:
		_audited = true
		_coin_seen = holders
		_total_seen = total
		_src_seen = src
		_coin_delta.clear()
		_coin_net = 0
		return
	for ref in holders:
		var cur: int = holders[ref]
		if _coin_seen.has(ref):
			var expected: int = int(_coin_seen[ref]) + int(_coin_delta.get(ref, 0))
			if cur != expected:
				_unattributed(str(ref), expected, cur, "coin.unattributed_holder", "warning")
		_coin_seen[ref] = cur
	var expected_total := _total_seen + _coin_net + (src - _src_seen)
	if total != expected_total:
		_unattributed("world", expected_total, total, "coin.unattributed_total", "violation")
	_total_seen = total
	_src_seen = src
	_coin_delta.clear()
	_coin_net = 0


func _unattributed(ref: String, expected: int, actual: int, rule: String, severity: String) -> void:
	var ev := begin("audit", "coins", "audit", "unattributed_coins", ref, {"parent": -1})
	participant(ev, ref, "holder")
	state_change(ev, ref, "coins", expected, actual, "audit")
	alert(severity, rule, ref, "expected=%d actual=%d delta=%d" % [expected, actual, actual - expected], ev)
	end(ev, "unattributed")


# ================================================================ D3: identity, life, employment, government, crime, player, save and load
## The pass events (reeve_day, pay_guards): the manor's treasury and granary at the start, so the end can write the summary rows.
var _pass := {}


## One complete event in a single call. parts: [[ref, role], ...]; changes: [[ref, prop, before, after, authority], ...].
func occurrence(system: String, subsystem: String, category: String, subtype: String, actor: String, parts: Array, changes: Array,
		outcome := "ok", reason := "", detail := "", opts := {}) -> int:
	var ev := begin(system, subsystem, category, subtype, actor, opts)
	for p in parts:
		participant(ev, str(p[0]), str(p[1]))
	for c in changes:
		state_change(ev, str(c[0]), str(c[1]), c[2], c[3], str(c[4]))
	end(ev, outcome, reason, detail)
	return ev


static func _pref(id: int) -> String:
	if id > 0:
		return "p:%d" % id
	return "player_view" if id == -2 else ("none" if id == -1 else "former_player")


func _loot_coins() -> int:
	var n := 0
	for l in w.loot:
		n += int(l.coins)
	return n


## Live ties that name the player's view id (-2): the continuity a succession keeps (ID-D1).
func _player_view_ties() -> int:
	var n := 0
	for k in w.relations.ties:
		var parts: PackedStringArray = str(k).split(":")
		if parts.size() == 2 and (Life.is_player_id(int(parts[0])) or Life.is_player_id(int(parts[1]))):
			n += 1
	return n


# ---------------------------------------------------------------- identity ------------------
## The register learns a person (Identity.register_npc / register_member / register_player). `how`: birth, newcomer, outlaw, arrival,
## founding, member, settlement_birth, player; the event subtype is "registered_" + how.
func identity_registered(id: int, how: String, where: String, name: String, mother: int, father: int) -> void:
	var ref := "p:%d" % id
	occurrence("identity", "register", "identity", "registered_" + how, ref, [[ref, "person"]], [[ref, "where", "unregistered", where, "identity"]],
			"ok", "", "%s; mother=%s father=%s%s" % [name, _pref(mother), _pref(father), "; band id" if id >= World.BAND_START else ""])


## The register moves a person (Identity.move): leave and return (same id), death, ancestor, player.
func identity_move(id: int, before: String, after: String) -> void:
	var sub := "moved"
	if after == Identity.DEAD:
		sub = "died"
	elif after == Identity.ANCESTOR:
		sub = "became_ancestor"
	elif after == Identity.PLAYER:
		sub = "became_player"
	elif after == Identity.VILLAGE:
		sub = "returned_to_village"
	elif before == Identity.VILLAGE:
		sub = "left_village"
	var ref := "p:%d" % id
	occurrence("identity", "register", "identity", sub, ref, [[ref, "person"]], [[ref, "where", before, after, "identity"]], "ok", "", "from=%s to=%s" % [before, after])


## Before Identity.succeed: the player role changes hands. Returns the open event and what the end compares with.
func succession_begin(parent: PlayerState) -> Array:
	var ev := begin("identity", "succession", "identity", "succession", ref_of(parent), _xy(parent))
	return [ev, ref_of(parent), _player_view_ties(), w.tie_history.size()]


func succession_end(t: Array, parent: PlayerState, heir: PlayerState, kid: NPC) -> void:
	var ev: int = t[0]
	if ev <= 0:
		return
	part(ev, parent, "predecessor")
	part(ev, heir, "heir")
	state_change(ev, "role:player", "holder", str(t[1]), ref_of(heir), "identity")
	var snap: int = ((w.tie_history.get(str(parent.pid), {}) as Dictionary).get("ties", {}) as Dictionary).size()
	end(ev, "ok", "", "generation=%d; predecessor=%s heir=%s; heir_is_the_players_child=%s; live_view_ties(-2) before=%d after=%d; tie_history_for_predecessor=%d" % [
			heir.generation, t[1], ref_of(heir), str(kid != null), int(t[2]), _player_view_ties(), snap])
	_inv_hour = -1                                  # the heir's pack is a new inventory


# ---------------------------------------------------------------- life ----------------------
func birth(k: NPC, mother, father, h: int) -> void:
	var ref := ref_of(k)
	var ev := begin("life", "birth", "life", "birth", ref, _xy(k))
	part(ev, k, "child")
	part(ev, mother, "mother")
	part(ev, father, "father")
	state_change(ev, ref, "alive", "unborn", true, "life")
	state_change(ev, "hh:%d" % h, "household", "members", "members+1", "life")
	end(ev, "ok", "", "%s %s; household=%d" % [k.name, k.family, h])


## Before World.kill mutates.
func death_begin(n: NPC, cause: String) -> Array:
	var ev := begin("life", "death", "life", "death", ref_of(n), _xy(n).merged({"detail": "cause=" + cause}))
	return [ev, n.coins]


func death_end(t: Array, n: NPC, cause: String, heir: NPC) -> void:
	var ev: int = t[0]
	if ev <= 0:
		return
	var ref := ref_of(n)
	part(ev, n, "deceased")
	part(ev, heir, "heir")
	state_change(ev, ref, "alive", true, false, "life")
	var moved: int = int(t[1]) - int(n.coins)
	if moved != 0:
		state_change(ev, ref, "coins", int(t[1]), int(n.coins), "life.inherit")
		if heir != null and not cause.begins_with("slain"):
			state_change(ev, ref_of(heir), "coins", int(heir.coins) - moved, int(heir.coins), "life.inherit")
		else:
			var lc := _loot_coins()
			state_change(ev, "loot", "coins", lc - moved, lc, "life.inherit")      # what lay with the dead lies where they fell
	end(ev, "ok", "", "cause=%s; role=%s job=%s household=%d age=%.1f" % [cause, n.role, n.job, n.household, Life.npc_age(w, n)])


func player_died(p: PlayerState, cause: String) -> void:
	var ref := ref_of(p)
	occurrence("life", "death", "life", "death", ref, [[ref, role_of(p, "deceased")]], [[ref, "alive", true, false, "life"]], "ok", "",
			"cause=%s; generation=%d; the player character died: succession follows when the heir takes over" % [cause, p.generation], _xy(p))


## A villager's role changed with their age (Life.sync_roles): child to adult at 16, adult to elder.
func role_changed(n: NPC, before: String) -> void:
	var ref := ref_of(n)
	occurrence("life", "role", "life", "role_changed", ref, [[ref, "person"]], [[ref, "role", before, n.role, "life"]], "ok", "",
			"age=%.1f; job=%s" % [Life.npc_age(w, n), n.job], _xy(n))


func partnered(a, b) -> void:
	var ra := ref_of(a)
	var rb := ref_of(b)
	var ev := begin("life", "partner", "life", "partnership", ra, _xy(a))
	part(ev, a, "partner")
	part(ev, b, "partner")
	state_change(ev, ra, "partner", "none", rb, "life")
	state_change(ev, rb, "partner", "none", ra, "life")
	end(ev)


## Guardianship.move: an orphaned child taken in by a household.
func guardianship(k: NPC, old_h: int, h: int, tier: String, host: NPC) -> void:
	var ref := ref_of(k)
	var ev := begin("life", "guardianship", "life", "guardianship_placement", ref, _xy(k))
	part(ev, k, "ward")
	part(ev, host, "host")
	state_change(ev, ref, "household", old_h, h, "life")
	end(ev, "ok", "", "tier=%s" % tier)


## Guardianship.join_clan: no household took the orphan.
func clan_joined(k: NPC, old_h: int) -> void:
	var ref := ref_of(k)
	occurrence("life", "guardianship", "life", "guardianship_clan", ref, [[ref, "ward"]], [[ref, "household", old_h, k.household, "life"]], "ok", "", "no household could take the child", _xy(k))


# ---------------------------------------------------------------- employment ----------------
func job_changed(n: NPC, old: String, job: String, why: String, place: String) -> void:
	var ref := ref_of(n)
	var sub := "job_lost" if job == "" else ("job_taken" if old == "" else "job_switched")
	occurrence("employment", "job", "employment", sub, ref, [[ref, "worker"]], [[ref, "job", old, job, "employment"]], "ok", "",
			"%s%s" % [why, "; place=" + place if place != "" else ""], _xy(n))


func vacancy_opened(v: Dictionary, cause: String) -> void:
	var size: int = w.vacancies.size()
	occurrence("employment", "vacancy", "employment", "vacancy_opened", "world", [], [["world", "vacancies", size - 1, size, "employment"]], "ok", "",
			"job=%s; workplace=%s; left by %s; %s" % [v.get("job", ""), v.get("workplace", ""), v.get("who", ""), cause])


## After `_install`: the vacancy `v` (already removed from World.vacancies) is filled by `n`.
func vacancy_filled(n: NPC, v: Dictionary, why: String) -> void:
	var ref := ref_of(n)
	var size: int = w.vacancies.size()
	occurrence("employment", "vacancy", "employment", "vacancy_filled", ref, [[ref, "hired"]], [["world", "vacancies", size + 1, size, "employment"]], "ok", "",
			"job=%s; %s" % [v.get("job", ""), why], _xy(n))


## The manor's hiring competition moved its offer (raised or eased): the wage a hand is offered is the base plus `raise`.
func wage_offer(kind: String, before: int, after: int, open_left: int, seekers: int) -> void:
	occurrence("employment", "wage", "employment", "wage_offer_" + kind, "manor", [], [["manor", "wage_raise", before, after, "employment"]], "ok", "",
			"manor_hand; places still open=%d, seekers who did not take them=%d" % [open_left, seekers])


# ---------------------------------------------------------------- government ----------------
## A daily pass of the manor (reeve_day, pay_guards): its own events (tax, wages, relief transfers, job losses) are its children;
## the end writes the treasury and granary before and after as summary rows (not counted again by the coin audit).
func pass_begin(subtype: String) -> int:
	var ev := begin("government", subtype, "civic", subtype, "manor")
	if ev > 0:
		_pass[ev] = {"treasury": w.treasury, "granary": w.granary.items.duplicate()}
	return ev


func pass_end(ev: int, detail := "") -> void:
	if ev <= 0:
		return
	var snap: Dictionary = _pass.get(ev, {})
	_pass.erase(ev)
	if not snap.is_empty():
		state_change(ev, "manor", "coins", int(snap.treasury), int(w.treasury), "summary")
		var ids: Array = (snap.granary as Dictionary).keys()
		for id in w.granary.items:
			if not ids.has(id):
				ids.append(id)
		ids.sort()
		for id in ids:
			var b: int = int((snap.granary as Dictionary).get(id, 0))
			var a: int = w.granary.count(str(id))
			if a != b:
				state_change(ev, "granary", "item:" + str(id), b, a, "summary")
	end(ev, "ok", "", detail)


## Coins between the manor's treasury and a person, recorded right after both sides changed. kind: tax, wage, repairs, granary, tools,
## works, relief. `to_manor`: the person paid the manor (tax); else the manor paid the person.
func manor_flow(kind: String, o, amount: int, to_manor: bool) -> void:
	var ref := ref_of(o)
	var auth := "gov." + kind
	var ev := begin("government", "manor", "civic", kind, ref if to_manor else "manor", _xy(o))
	part(ev, o, "payer" if to_manor else "payee")
	participant(ev, "manor", "payee" if to_manor else "payer")
	var after: int = int(o.coins)
	state_change(ev, ref, "coins", after + amount if to_manor else after - amount, after, auth)
	var t: int = int(w.treasury)
	state_change(ev, "manor", "coins", t - amount if to_manor else t + amount, t, auth)
	end(ev)


func layoff(n: NPC) -> void:
	var ref := ref_of(n)
	occurrence("government", "pay_guards", "civic", "layoff", "manor", [[ref, "laid_off"]], [], "ok", "", "the manor could not keep its hands on", _xy(n))


func wage_unpaid(who: String) -> void:
	occurrence("government", "pay_guards", "civic", "wage_unpaid", "manor", [], [], "failed", "treasury_short", who)


# ---------------------------------------------------------------- crime ---------------------
## World.witness: what the village saw the player do (the player's crime record grew by one). Stays open: a guard's confrontation is its child.
func witness_begin(kind: String, what: String, victim: NPC, seen: Array, worth: int) -> int:
	var p: PlayerState = w.player
	var ev := begin("crime", "witness", "crime", kind, ref_of(p), _xy(p).merged({"detail": "%s; worth=%d; witnesses=%d" % [what, worth, seen.size()]}))
	part(ev, p, "offender")
	part(ev, victim, "victim")
	for s in seen:
		part(ev, s, "witness")
	state_change(ev, ref_of(p), "crimes", p.crimes.size() - 1, p.crimes.size(), "life")
	return ev


## Before World.guard_confront mutates: the player's coins and goods and the treasury.
func guard_begin(g: NPC) -> Array:
	var p: PlayerState = w.player
	var ev := begin("crime", "guard", "crime", "guard_confront", ref_of(g), _xy(g))
	return [ev, p.coins, w.treasury, p.inv.items.duplicate()]


func guard_end(t: Array, g: NPC, owner: NPC, fine: int, paid: int, warned: bool) -> void:
	var ev: int = t[0]
	if ev <= 0:
		return
	var p: PlayerState = w.player
	part(ev, g, "guard")
	part(ev, p, "offender")
	part(ev, owner, "owner")
	var ref := ref_of(p)
	state_change(ev, ref, "coins", int(t[1]), int(p.coins), "gov.fine")
	state_change(ev, "manor", "coins", int(t[2]), int(w.treasury), "gov.fine")
	var before: Dictionary = t[3]
	var ids: Array = before.keys()
	for id in p.inv.items:
		if not ids.has(id):
			ids.append(id)
	ids.sort()
	for id in ids:
		var b: int = int(before.get(id, 0))
		var a: int = p.inv.count(str(id))
		if a != b:
			state_change(ev, ref, "item:" + str(id), b, a, "gov.fine")
	end(ev, "ok", "", "fine=%d paid=%d warned=%s%s" % [fine, paid, str(warned), "; could not pay it all: the guard draws a weapon" if paid < fine else ""])


## World.raise_alarm: who saw an attack; the guards that took it on; the reports are its children.
func alarm_begin(attacker: int, aware: Dictionary) -> int:
	var who := ref_of(w.player) if Life.is_player_id(attacker) else _pref(attacker)
	var ev := begin("crime", "alarm", "crime", "raise_alarm", who)
	participant(ev, who, "attacker")
	for s in aware.get("seen", []):
		part(ev, s, "witness")
	part(ev, aware.get("victim", null), "victim")
	return ev


func alarm_end(ev: int, guards_answered: int) -> void:
	end(ev, "ok", "", "guards_answered=%d" % guards_answered)


## World.report_crime: `n` will carry word of an attack or a theft to a guard.
func report(n: NPC, offender: int, how: String, crime: String) -> void:
	var ref := ref_of(n)
	var off := ref_of(w.player) if Life.is_player_id(offender) else _pref(offender)
	occurrence("crime", "report", "crime", "report_crime", ref, [[ref, "reporter"], [off, "offender"]], [[ref, "report", "none", "%s %s" % [crime, off], "life"]], "ok", "", "how=%s" % how, _xy(n))


## NPCBrain: a bandit robbed a villager (called right after the coins and the item moved).
func robbery(b: NPC, victim: NPC, take: int, stolen: String) -> void:
	var rb := ref_of(b)
	var rv := ref_of(victim)
	var ch := [[rb, "coins", int(b.coins) - take, int(b.coins), "crime.robbery"], [rv, "coins", int(victim.coins) + take, int(victim.coins), "crime.robbery"]]
	if stolen != "":
		ch.append([rb, "item:" + stolen, b.inv.count(stolen) - 1, b.inv.count(stolen), "crime.robbery"])
		ch.append([rv, "item:" + stolen, victim.inv.count(stolen) + 1, victim.inv.count(stolen), "crime.robbery"])
	occurrence("crime", "robbery", "crime", "robbery", rb, [[rb, "robber"], [rv, "victim"]], ch, "ok", "", "coins=%d item=%s" % [take, stolen], _xy(b))


# ---------------------------------------------------------------- player verbs --------------
## A verb of the player that changes the world (trade, take, strike, craft, loot). The event is the parent of what the verb
## triggers (a trade, a witness, a death). Its state rows are a summary of the player's coins and pack (and the target's health):
## authority "summary" repeats what a child event recorded and is not counted again; a coin change no child recorded (loot) is
## attributed to the player's purse for the hourly audit.
func verb_begin(kind: String, detail := "", target = null) -> Array:
	var p: PlayerState = w.player
	var ev := begin("player", "verb", "verb", kind, ref_of(p), _xy(p).merged({"detail": detail}))
	part(ev, p, "actor")
	part(ev, target, "target")
	return [ev, p.coins, p.inv.items.duplicate(), target, float(target.hp) if target is NPC else 0.0, int(_coin_delta.get(ref_of(p), 0))]


func verb_end(t: Array, outcome := "ok", reason := "", detail := "") -> void:
	var ev: int = t[0]
	if ev <= 0:
		return
	var p: PlayerState = w.player
	var ref := ref_of(p)
	if p.coins != int(t[1]):
		state_change(ev, ref, "coins", int(t[1]), int(p.coins), "summary")
		var rest: int = (int(p.coins) - int(t[1])) - (int(_coin_delta.get(ref, 0)) - int(t[5]))      # what no child event attributed
		if rest != 0:
			_coin_delta[ref] = int(_coin_delta.get(ref, 0)) + rest
	var before: Dictionary = t[2]
	var ids: Array = before.keys()
	for id in p.inv.items:
		if not ids.has(id):
			ids.append(id)
	ids.sort()
	for id in ids:
		var b: int = int(before.get(id, 0))
		var a: int = p.inv.count(str(id))
		if a != b:
			state_change(ev, ref, "item:" + str(id), b, a, "summary")
	if t[3] is NPC and float((t[3] as NPC).hp) != float(t[4]):
		state_change(ev, ref_of(t[3]), "hp", snappedf(float(t[4]), 0.1), snappedf(float((t[3] as NPC).hp), 0.1), "summary")
	end(ev, outcome, reason, detail)


# ---------------------------------------------------------------- save and load -------------
## World.load_dict finished: a session note that the world was loaded, its save version, and whether every person kept their id.
func world_loaded(d: Dictionary) -> void:
	meta["seed"] = int(w.seed)
	meta["save_version"] = World.SAVE_VERSION
	_audited = false                                # the audit takes its balances afresh from the loaded world
	_inv_hour = -1
	_plan_ev.clear()
	var saved_version := int(d.get("save_version", 0))
	var in_save: bool = d.get("people") is Dictionary
	var same := true
	var saved_count := 0
	if in_save:
		saved_count = (d.people as Dictionary).size()
		for k in d.people:
			same = same and w.people.has(int(k))
		same = same and saved_count == w.people.size()
	var upgraded := not in_save
	var ev := begin("world", "save", "system", "world_loaded", "world", {"detail": "save_version=%d (running %d); identity=%s; ids_unchanged=%s; people=%d; next_person_id=%d next_band_id=%d; day=%d" % [
			saved_version, World.SAVE_VERSION, "upgraded once on load (ids assigned, none reassigned)" if upgraded else "register read from the save", str(same) if in_save else "n/a (ids assigned on load)",
			w.people.size(), w.next_person_id, w.next_band_id, w.day()]})
	state_change(ev, "world", "people", saved_count if in_save else 0, w.people.size(), "identity")
	if in_save and not same:
		alert("violation", "identity.ids_changed_on_load", "world", "saved people=%d, loaded people=%d" % [saved_count, w.people.size()], ev)
	end(ev)
	_write_session()


func saved(d: Dictionary) -> void:
	occurrence("world", "save", "system", "world_saved", "world", [], [], "ok", "", "save_version=%d; people=%d; next_person_id=%d next_band_id=%d; day=%d" % [
			int(d.get("save_version", 0)), w.people.size(), w.next_person_id, w.next_band_id, w.day()])
