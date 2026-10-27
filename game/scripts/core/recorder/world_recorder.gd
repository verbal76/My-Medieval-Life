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
##   judgment (D5) and relations (D4): see the sections at the end (facts, beliefs, gossip, ledger posts, trust, every weighted
##                 choice in full, family-priority decisions; shared hours, gifts, harm)

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
		"flags": flags_of(world), "scenario": OS.get_environment("MML_SCENARIO")}
	for b in r.codes.decision_chain:
		r._chain.append(str(b.id))
		r._chain_factors[str(b.id)] = b.factors
	world.recorder = r
	if world.judgment != null:
		world.judgment.rec = r             # REC-19 D5: the judgment store reports to the recorder (JudgmentLive.attach does it for a later store)
		world.judgment.pers.rec = r        # X20-FINAL: the personality layer too
	r._write_session()
	return r


func _now() -> Array:
	return [w.day(), fmod(w.minutes, World.DAY)]


## X20-FINAL: the feature switches as this world runs them (the archive's own record of what was on; tools/recorder_archive.py
## compares them with what a scenario requires, so a run that left a system off cannot count as exercising it).
static func flags_of(world) -> Dictionary:
	var j = world.judgment
	var integ := {}
	if j != null:
		var dec: Dictionary = (j.cfg.get("decision", {}) as Dictionary).get("integration", {})
		var ks := dec.keys()
		ks.sort()
		for k in ks:
			if not str(k).begins_with("_"):
				integ[str(k)] = bool(dec[k]) and (str(k) != "job_choice" or j.asp.enabled)     # as JudgmentLive.on reads them (no call)
	return {"recorder": true, "judgment": j != null, "aspiration": j != null and j.asp.enabled,
		"job_choice": bool(integ.get("job_choice", false)), "economy": world.economy != null, "judgment_integration": integ}


## A person's reference is their permanent person id (ID-01): `p:<id>`. The player character is `p:<PlayerState.pid>`, the same
## kind of reference as anyone's and stable across succession (an heir who was the player's child keeps their own id); that the
## person is the player at the time is a role marker (`part`: the participant role gets the suffix `:player`), never a separate
## identity. `p:player` is only the fallback for a player without a pid (a bare test world).
## MP C: the player a person id names (World.player_of_id; the acting player when it names none here).
func _player_of(id: int) -> PlayerState:
	var p: PlayerState = w.player_of_id(id)
	return p if p != null else w.player


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
	_day_summaries()                            # X20-FINAL: the day's memory, resources and LE-01 summaries (once a day)
	if net == null or not is_instance_valid(net) or not net.has_guests():
		net_state_maybe()                       # X20-FINAL: the digest in a network session (once a game hour); a host with guests takes
		                                        # it at the end of its frame, as it marks the guests' sync (NetSession._host_step)
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
	snapshot(snapshot_values())


## The closing state: at the end of the session the same values go into session.json as "final_snapshot" (keyed by column),
## so the archive's last word is the world as it was left, not as it was at the last hour boundary.
func finish() -> void:
	if not finished and not stopped and w != null:
		var v := snapshot_values()
		var d := {}
		var cols: Array = COLUMNS.snapshot
		for i in v.size():
			d[cols[i + 1]] = v[i]
		meta["final_snapshot"] = d
	super.finish()


func snapshot_values() -> Array:
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
	var row := [int(_now()[0]), int(float(_now()[1]) / 60.0), alive, purses.size(), adults,
		employed, children, elders, bandits, snappedf(hunger_sum / nf, 0.1), snappedf(hunger_min if alive > 0 else 0.0, 0.1), starving,
		snappedf(hp_sum / nf, 0.001), idle, lost, fighting, guards, engaged, int(w.total_coins()), vcoins, int(w.treasury), int(w.coin_sources),
		int(purses[0]) if not purses.is_empty() else 0, int(purses[purses.size() / 2]) if not purses.is_empty() else 0,
		int(purses[-1]) if not purses.is_empty() else 0, snappedf(float(w.food_days), 0.01), w.granary.count("wheat"), _births, _deaths,
		ties, friends, courting, (w.judgment.facts.size() if w.judgment != null else NOT_EVALUATED), w.player.crimes.size(),
		int(_hour_n.get("events", 0)), int(_hour_n.get("trades", 0)), int(_hour_n.get("trade_coins", 0)), int(_hour_n.get("transfers", 0)),
		int(_hour_n.get("actions", 0)), int(_hour_n.get("actions_failed", 0)), int(_hour_n.get("walk_lost", 0)), int(_hour_n.get("crimes", 0)),
		int(_hour_n.get("chases", 0)), int(_hour_n.get("alerts", 0)), delta, wall_ms, OS.get_static_memory_usage()]
	_hour_n.clear()
	return row


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
		return snappedf(n.pos.distance_to(_player_of(n.target).pos), 0.01)
	var t: NPC = w.npc(n.target)
	return snappedf(n.pos.distance_to(t.pos), 0.01) if t != null else -1.0


func _chase_close(n: NPC, reason: String) -> void:
	var c: Dictionary = _chases[n.id]
	_chases.erase(n.id)
	var who := "guard" if n.job == "guard" else ("bandit" if n.role == "bandit" else "villager")
	var tref := ref_of(_player_of(int(c.target))) if Life.is_player_id(int(c.target)) else _pref(int(c.target))
	var mins := float(w.minutes) - float(c.t0)
	var outcome := "ok" if reason in ["target_slain", "robbed", "taken"] else ("abandoned" if reason in ["out_of_range", "near_bandit_camp", "blocked", "bandit_low_hp"] else "interrupted")
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
	var who := ref_of(_player_of(attacker)) if Life.is_player_id(attacker) else _pref(attacker)
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
	var off := ref_of(_player_of(offender)) if Life.is_player_id(offender) else _pref(offender)
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


# ---------------------------------------------------------------- judgment (D5) -------------
## REC-19 stage D5 (Expansion 20, batch R3; REC-STORE, FAM-SAC-01): the judgment store's records as they change, called through
## JudgmentStore.rec (null unless a recorder is attached; set by attach and JudgmentLive.attach). Every call passes values the
## store has just computed: nothing here calls a store function (no catch-up, no gossip flush, no draw), so recording changes no
## belief, ledger, trust or choice.
##   fact       JudgmentStore.publish        one event per fact: type, actors (with shares), victims, beneficiaries, value, tags
##   belief     JudgmentStore.learn          one event per belief taken in (source, teller, hops, confidence); its ledger posts and
##                                           trust moves are its state rows; the object thread "fact:<id>" joins a fact's beliefs
##   gossip     JudgmentStore.tell           one event per telling that passed anything on (stories, news, a lie shown false); the beliefs it
##                                           gave are its children. A meeting with nothing to tell writes no row (D4 records the hour)
##   ledger     JudgmentStore._post          state rows judgment_good / judgment_bad:<actor>:fact:<id>, the contribution before and after
##   trust      JudgmentStore.trust_add      state row trust:<subject>, before and after
##   choice     JudgmentWeighting.choose     one decision with every candidate (feasible or not, with why) as an alternative and every
##                                           factor value, weighted contribution, family colour and stubborn penalty as factor rows, in
##                                           full (REC-STORE: no sampling; the storage cap stops the session, REC-D2)
##   family     JudgmentFamily._record       one event per family-priority decision (the rows of family_trace), linked to its choice
var _jlast_choice := 0                  # the last choice event (a family decision links to it)
var _jlast_trace = null                 # ...and the trace Array that choice returned
var _jgossip := {}                      # open gossip event id -> the row sequence when it began


## A person in the judgment store or the relations: a villager is p:<id>; a player id (Life.is_player_id) is the player's permanent ref.
func jref(id: int) -> String:
	if Life.is_player_id(id):
		var p = w.player_of_id(id)
		return ref_of(p) if p != null else _pref(id)
	return "p:%d" % id


## The event the store's state rows belong to: the one open now (a belief, a telling, an action), else a one-off of its own.
func _jctx(subsystem: String, subtype: String, actor: String, detail: String) -> int:
	var cur := current()
	if cur > 0:
		return cur
	return occurrence("judgment", subsystem, "judgment", subtype, actor, [[actor, "actor"]], [], "ok", "", detail)


func judgment_fact(id: int, type: String, actors: Array, victims: Array, beneficiaries: Array, value: int, tags: Array) -> void:
	var a0 := jref(int(actors[0][0])) if not actors.is_empty() else "world"
	var ev := begin("judgment", "fact", "judgment", "fact:" + type, a0, {"object": "fact:%d" % id, "detail": "fact=%d value=%d tags=%s" % [id, value, JSON.stringify(tags)]})
	for a in actors:
		participant(ev, jref(int(a[0])), "actor:%d" % int(a[1]))
	for v in victims:
		participant(ev, jref(int(v)), "victim")
	for b in beneficiaries:
		participant(ev, jref(int(b)), "beneficiary")
	end(ev)


## A belief taken in (JudgmentStore.learn, past its duplicate checks): open until learn returns, so its posts and trust moves join it.
func belief_begin(observer: int, fact: int, type: String, src: String, by: int, hops: int, conf: int, upgrade: bool) -> int:
	var o := jref(observer)
	var ev := begin("judgment", "belief", "judgment", src, o, {"object": "fact:%d" % fact,
		"detail": "fact=%d type=%s hops=%d conf=%d%s" % [fact, type, hops, conf, " upgrade" if upgrade else ""]})
	participant(ev, o, "observer")
	if by >= 0 or Life.is_player_id(by):
		participant(ev, jref(by), "teller")
	return ev


func gossip_begin(_teller: int, _listener: int) -> int:
	var ev := begin("judgment", "gossip", "judgment", "tell", jref(_teller))
	if ev > 0:
		_jgossip[ev] = seq
	return ev


## The telling ends: `told` moral stories passed; news told and a lie shown false are recorded under it as their own rows. With nothing at all recorded under it the event is
## dropped unwritten (no row, its id given back), so a meeting with nothing to tell costs no row.
func gossip_end(ev: int, teller: int, listener: int, told: int) -> void:
	if ev <= 0:
		return
	var at := int(_jgossip.get(ev, -1))
	_jgossip.erase(ev)
	if told == 0 and at == seq and _open.has(ev):
		_open.erase(ev)
		var i := _stack.rfind(ev)
		if i >= 0:
			_stack.remove_at(i)
		if next_event == ev + 1:
			next_event = ev
		return
	participant(ev, jref(teller), "teller")
	participant(ev, jref(listener), "listener")
	end(ev, "ok", "", "stories=%d" % told)        # its children say what else passed (news, a lie shown false)


func judgment_post(observer: int, fact: int, actor: int, og: int, ob: int, ng: int, nb: int) -> void:
	var o := jref(observer)
	var ev := _jctx("ledger", "post", o, "fact=%d" % fact)
	var a := jref(actor)
	if og != ng:
		state_change(ev, o, "judgment_good:%s:fact:%d" % [a, fact], og, ng, "judgment")
	if ob != nb:
		state_change(ev, o, "judgment_bad:%s:fact:%d" % [a, fact], ob, nb, "judgment")


func trust_move(a: int, b: int, before: int, after: int) -> void:
	var o := jref(a)
	state_change(_jctx("trust", "trust_move", o, ""), o, "trust:%s" % jref(b), before, after, "judgment")


const _JBASIS := {"forgo": "forgo", "none feasible": "none_feasible", "the family name alone cannot refuse": "family_name_cannot_refuse"}
const _JSOURCE := {"disposition": "judgment", "ambivalence": "judgment", "sole_source": "judgment",
	"aspiration": "aspiration", "standing": "judgment",     # R5 (WDR-011-C): the aspiration factor; actual standing is others' judgment
	"bond": "world_state", "security": "world_state", "wealth": "world_state", "property": "world_state", "stability": "world_state",
	"family_compat": "judgment", "shared_ambition": "aspiration", "need_wage": "world_state", "skill": "world_state", "growth": "world_state",
	"tenure": "world_state", "career_sat": "aspiration"}


## One JudgmentWeighting.choose, in full: the decision, every candidate as an alternative (infeasible ones with why) and, for each
## feasible one, every factor value, its weighted contribution, the family colour and the stubborn penalties, then forgo.
func judgment_choice(chooser: int, profile: String, key: Array, r: Dictionary) -> void:
	var actor := jref(chooser)
	var chosen := "none" if r.get("chosen") == null else str(r.chosen)
	var policy := str(r.get("policy", ""))
	var ev := begin("judgment", "choice", "judgment", profile, actor, {"detail": "key=%s utility=%d policy=%s" % [JSON.stringify(key), int(r.get("utility", 0)), policy]})
	participant(ev, actor, "chooser")
	decision(ev, actor, "judgment_weighted", chosen, str(_JBASIS.get(policy, policy)), "colour_blocked" if bool(r.get("colour_blocked", false)) else "")
	var seen_cp := {}
	for row in r.get("trace", []):
		var opt := str(row.id)
		if opt == "forgo" and not row.has("counterparty"):
			alternative(ev, "forgo", "yes", true, "", int(row.get("utility", 0)))
			factor(ev, "forgo", "forgo", int(row.get("utility", 0)), "milli-points", "profile")
			if row.has("forgo_aspiration_offset"):
				factor(ev, "forgo", "forgo_aspiration_offset", int(row.forgo_aspiration_offset), "milli-points", "aspiration")
			continue
		var cp := int(row.get("counterparty", -1))
		if cp != -1 and not seen_cp.has(cp):
			seen_cp[cp] = true
			participant(ev, jref(cp), "counterparty")
		if not bool(row.get("feasible", true)):
			alternative(ev, opt, "yes", false, "not_feasible")
			factor(ev, opt, "why", str(row.get("why", "")), "text", "live_code")
			continue
		alternative(ev, opt, "yes", true, "", int(row.get("utility", 0)))
		if cp != -1:
			factor(ev, opt, "counterparty", jref(cp), "ref", "live_code")
		var f: Dictionary = row.get("factors", {})
		var names := f.keys()
		names.sort()
		for n in names:
			factor(ev, opt, str(n), int(f[n]), "milli-points (0-100000)", str(_JSOURCE.get(str(n), "live_code")))
		var c: Dictionary = row.get("contributions", {})
		var cn := c.keys()
		cn.sort()
		for n in cn:
			factor(ev, opt, "weighted:" + str(n), int(c[n]), "milli-points", "weight")
		if row.has("colour"):
			factor(ev, opt, "family_colour", int(row.colour), "milli-points", "judgment")
		if row.has("stubborn"):
			for k in ["resent", "switch", "override", "total"]:
				factor(ev, opt, "stubborn_" + k, int(row.stubborn.get(k, 0)), "milli-points", "personality")
		if row.has("aspiration"):                   # R5: which aspiration the factor came from
			var a: Dictionary = row.aspiration
			factor(ev, opt, "aspiration_domain", str(a.get("domain", "")) if str(a.get("domain", "")) != "" else "content", "text", "aspiration")
			factor(ev, opt, "aspiration_pressure", int(a.get("pressure", 0)), "milli-points", "aspiration")
			factor(ev, opt, "aspiration_fit", int(a.get("fit", 0)), "-1/0/+1", "aspiration")
			factor(ev, opt, "surv", int(a.get("surv", 0)), "permille", "aspiration")
		if row.has("scale"):                        # R5: the priority multiplier applied to each scaled weight
			var sk: Array = (row.scale as Dictionary).keys()
			sk.sort()
			for k in sk:
				factor(ev, opt, "scale:" + str(k), int(row.scale[k]), "permille", "aspiration")
	end(ev, "ok" if r.get("chosen") != null else "empty")
	_jlast_choice = ev
	_jlast_trace = r.get("trace")


## One family-priority decision (JudgmentFamily._record: the row it keeps in JudgmentStore.family_trace), linked to its weighing.
## R5 (WDR-011-C): one change of a villager's aspirations: a priority shift (success, setback, loss, marriage, with how the
## person met it), a change of the leading aspiration, or the survival level crossing a step of surv_record_step. Event code
## judgment/aspiration; the facts as factor rows. Never read by the simulation.
func aspiration_event(person: int, kind: String, facts: Dictionary) -> void:
	var actor := jref(person)
	var ev := begin("judgment", "aspiration", "judgment", kind, actor)
	participant(ev, actor, "person")
	var keys := facts.keys()
	keys.sort()
	for k in keys:
		factor(ev, kind, str(k), facts[k], "value", "aspiration")
	end(ev)


func judgment_family(row: Dictionary) -> void:
	var actor := jref(int(row.who))
	var ev := begin("judgment", "family", "judgment", str(row.kind), actor, {"detail": "household=%d chosen=%s utility=%d" % [int(row.household), str(row.chosen), int(row.utility)]})
	participant(ev, actor, "head" if str(row.kind) == "pay" else "person")
	var keys := row.keys()
	keys.sort()
	for k in keys:
		if k in ["day", "hour", "who", "household", "kind", "chosen", "utility", "trace"]:
			continue
		var v = row[k]
		if k == "for":
			participant(ev, jref(int(v)), "dependant")
			v = jref(int(v))
		factor(ev, str(row.chosen), str(k), v, "value", "judgment_family")
	if _jlast_choice > 0 and is_same(_jlast_trace, row.get("trace")):
		link(_jlast_choice, ev, "part_of", "family_trace")
	end(ev)


# ---------------------------------------------------------------- relations (D4) ------------
## REC-19 stage D4, Relations (Expansion 20, batch R3): shared hours, gifts and harm, each an event on the pair's tie
## (`tie:<a>:<b>`, Relations.key) with the regard and attraction before and after (floats, so no delta) and the people as
## participants. Reads the tie Dictionary the caller already holds; nothing is changed.
func _tie_rows(ev: int, a: int, b: int, t: Dictionary, before: Array) -> void:
	var ref := "tie:" + Relations.key(a, b)
	if float(before[0]) != float(t.regard):
		state_change(ev, ref, "regard", snappedf(float(before[0]), 0.0001), snappedf(float(t.regard), 0.0001), "relations")
	if float(before[1]) != float(t.attraction):
		state_change(ev, ref, "attraction", snappedf(float(before[1]), 0.0001), snappedf(float(t.attraction), 0.0001), "relations")
	if int(before[2]) != int(t.days_known):
		state_change(ev, ref, "days_known", int(before[2]), int(t.days_known), "relations")


static func tie_before(t: Dictionary) -> Array:
	return [float(t.regard), float(t.attraction), int(t.days_known)]


## Relations.share: one shared hour of a pair (kind work, social or met), whatever it added.
func shared_hour(a: int, b: int, kind: String, t: Dictionary, before: Array) -> void:
	var ev := begin("relations", "shared", "relation", kind, jref(a), {"object": "tie:" + Relations.key(a, b)})
	participant(ev, jref(a), "person")
	participant(ev, jref(b), "person")
	_tie_rows(ev, a, b, t, before)
	end(ev)


## Before Relations.give moves the goods: the event and the counts and tie before.
func gift_begin(giver: int, from: Inventory, n: NPC, id: String, t: Dictionary) -> Array:
	var ev := begin("relations", "gift", "relation", "gift", jref(giver), {"object": "tie:" + Relations.key(giver, n.id), "detail": "item=%s" % id})
	return [ev, from.count(id), n.inv.count(id), tie_before(t)]


func gift_end(g: Array, giver: int, from: Inventory, n: NPC, id: String, t: Dictionary) -> void:
	var ev: int = g[0]
	if ev <= 0:
		return
	var gr := jref(giver)
	participant(ev, gr, "giver")
	participant(ev, jref(n.id), "receiver")
	state_change(ev, gr, "item:" + id, int(g[1]), from.count(id), "relations.gift")
	state_change(ev, jref(n.id), "item:" + id, int(g[2]), n.inv.count(id), "relations.gift")
	_tie_rows(ev, giver, n.id, t, g[3])
	end(ev)


## Relations.harmed: harm the acting player did (or that the villager saw); each tie it lowered is a child row set.
func harm_begin(actor: int, n: NPC, amount: float, spread: bool) -> int:
	var ev := begin("relations", "harm", "relation", "harm", jref(actor), {"detail": "amount=%s spread=%s" % [str(snappedf(amount, 0.0001)), str(spread)]})
	participant(ev, jref(n.id), "victim")
	return ev


func harm_tie(ev: int, a: int, b: int, t: Dictionary, before: Array) -> void:
	if ev > 0:
		_tie_rows(ev, a, b, t, before)


# ================================================================ X20-FINAL phase 3 (owner directive 2026-10-27)
## The gaps the Expansions 18-20 coverage matrix found (docs/expansion20/X18_X20_COVERAGE_MATRIX.md), filled with the same
## architecture: one guarded call at each site, values the site has already computed, no random draw, no state changed. The
## recorder's own reads (the daily summaries, the network digest) read plain fields and pure functions only.
##   flows        World.stat            production, consumption and unmet-need counters moved inside an open event (an action, a
##                                      decision, a verb): a state row on "world" (the counter before and after) under that event,
##                                      so the actor and the plan that produced, used or went without are known. Outside an event
##                                      the hourly snapshot's stats_delta already holds them.
##   contracts    Contracts._open, deliver, _pay_units, _end      object thread "contract:<id>", coins set aside, paid, returned
##   credit       Credit.sell_on_credit, repay, _default, barter  debts and swaps with their goods and coins
##   relations    Relations.helped, talked, dawn (cooling: one row a dawn), _villagers_court (an interest taken), ask_court and
##                propose (outcome and reason, suitor a villager or a player)
##   judgment     JudgmentStore._forget, make_history, tell_family_history; JudgmentPersonality._log; JudgmentBonds.on_belief
##   days         at the first hour of each day: judgment_day (the store's stats moved), world_day (deposits, trees, regions,
##                capability levels and changes, households), economy_model (LE-01 records and their integrity, when on)
##   network      NetSession (host and guest): joins, refusals, leaves, requests applied, host lost, a prediction the host
##                answered differently; syncs counted; one net_state digest an hour per participant (section hashes)
const _PRODUCE := ["made_", "mined_", "felled_", "dug_", "cut_", "farm_harvest_", "farm_made_"]
const _CONSUME := ["eaten_", "used_", "feed_eaten_", "burned_", "broke_", "spoiled_", "poached_lost_", "wild_eaten_"]
const _UNMET := ["missed_meal_", "station_busy_", "starved_", "skill_short_", "keeper_no_feed_", "keeper_no_coins_", "field_unsown_no_seed",
	"farm_plot_no_ground", "farm_plot_cannot_afford", "supports_failed", "work_refused", "assay_refused", "proposals_refused",
	"proposals_declined", "contracts_lapsed", "contracts_unsigned", "credit_defaulted", "wage_unpaid"]
var _day_seen := -1                     # the last day whose summaries were written
var _jstats_seen := {}                  # judgment stats at the last judgment_day
var _bstats_seen := {}                  # bonds stats at the last judgment_day
var _disc_hist := 0                     # discovery.history rows already reported
var _net_hour := -1                     # the last game hour a net_state digest was written
var _net_counts := {}                   # syncs sent / adopted and their bytes since the last digest
var net = null                          # the NetSession, when this world is in a network session (set by its hooks)
var _cool := []                         # Relations.dawn: [ties, regard sum, attraction sum] before the cooling


## World.stat (before it adds): a flow counter moved. Production, consumption and unmet needs are written under the open event.
func stat_moved(key: String, n: float, before: float) -> void:
	if stopped or finished:
		return
	var kind := ""
	for p in _UNMET:
		if key.begins_with(p):
			kind = "unmet"
			break
	if kind == "":
		for p in _PRODUCE:
			if key.begins_with(p):
				kind = "produced"
				break
	if kind == "":
		for p in _CONSUME:
			if key.begins_with(p):
				kind = "consumed"
				break
	if kind == "" or key == "eaten_food" or key == "spoiled_total" or "_by_" in key:
		return
	var cur := current()
	if cur <= 0:
		return
	var after := before + n
	state_change(cur, "world", "%s:%s" % [kind, key], int(before) if is_equal_approx(before, roundf(before)) else snappedf(before, 0.01),
		int(after) if is_equal_approx(after, roundf(after)) else snappedf(after, 0.01), "world.stat")


## A party reference of the game ("npc:<id>", "player", "player:<line>", "manor", "hh:<n>") as the recorder's ref.
func wref(r: String) -> String:
	if r.begins_with("npc:"):
		return "p:%d" % World.ref_id(r)
	if World.is_player_ref(r):
		return ref_of(w.player_for(r))
	return r


func _wpart(ev: int, r: String, role: String) -> void:
	participant(ev, wref(r), role + (":player" if World.is_player_ref(r) else ""))


# ---------------------------------------------------------------- contracts -----------------
## Contracts._open succeeded: the buyer's coins are set aside on the contract (object thread contract:<id>).
func contract_opened(c: Dictionary, buyer_after: int) -> void:
	var total := int(c.reserved)
	var ev := begin("contracts", "contract", "contract", "opened", wref(str(c.seller)), {"object": "contract:%d" % int(c.id),
		"detail": "contract=%d item=%s qty=%d price_each=%d days=%d deadline_day=%d kind=%s route=%s" % [int(c.id), str(c.get("item", "")),
		int(c.qty), int(c.price_each), int(c.days), int(c.deadline_day), str(c.get("kind", "goods")), str(c.get("route", ""))]})
	_wpart(ev, str(c.buyer), "buyer")
	_wpart(ev, str(c.seller), "seller")
	state_change(ev, wref(str(c.buyer)), "coins", buyer_after + total, buyer_after, "contracts")
	state_change(ev, "contract:%d" % int(c.id), "coins", 0, total, "contracts")
	state_change(ev, "contract:%d" % int(c.id), "state", "offered", "accepted", "contracts")
	end(ev)


## Contracts.deliver moved the goods (before _pay_units pays for them): the item rows of both sides.
func contract_goods(c: Dictionary, units: int, from: Inventory, to: Inventory) -> void:
	var id := str(c.item)
	var ev := begin("contracts", "contract", "contract", "delivered", wref(str(c.seller)), {"object": "contract:%d" % int(c.id),
		"detail": "contract=%d item=%s units=%d" % [int(c.id), id, units]})
	_wpart(ev, str(c.seller), "seller")
	_wpart(ev, str(c.buyer), "buyer")
	state_change(ev, wref(str(c.seller)), "item:" + id, from.count(id) + units, from.count(id), "contracts")
	state_change(ev, inv_ref(to) if inv_ref(to) != "inv:?" else wref(str(c.buyer)), "item:" + id, to.count(id) - units, to.count(id), "contracts")
	end(ev)


## Contracts._pay_units paid `pay` for `units` from the coins set aside.
func contract_paid(c: Dictionary, units: int, pay: int, seller_after: int) -> void:
	var ev := begin("contracts", "contract", "contract", "paid", wref(str(c.seller)), {"object": "contract:%d" % int(c.id),
		"detail": "contract=%d units=%d pay=%d delivered=%d of %d" % [int(c.id), units, pay, int(c.delivered), int(c.qty)]})
	_wpart(ev, str(c.seller), "seller")
	_wpart(ev, str(c.buyer), "buyer")
	state_change(ev, "contract:%d" % int(c.id), "coins", int(c.reserved) + pay, int(c.reserved), "contracts")
	state_change(ev, wref(str(c.seller)), "coins", seller_after - pay, seller_after, "contracts")
	end(ev)


## Contracts._end: the contract ends in `state` (fulfilled, cancelled, lapsed); what was still set aside went back to the buyer.
func contract_ended(c: Dictionary, was: String, held: int, buyer_after: int) -> void:
	var ev := begin("contracts", "contract", "contract", str(c.state), wref(str(c.seller)), {"object": "contract:%d" % int(c.id),
		"detail": "contract=%d why=%s delivered=%d of %d paid=%d" % [int(c.id), str(c.get("why", "")), int(c.delivered), int(c.qty), int(c.paid)]})
	_wpart(ev, str(c.seller), "seller")
	_wpart(ev, str(c.buyer), "buyer")
	if held > 0:
		state_change(ev, "contract:%d" % int(c.id), "coins", held, 0, "contracts")
		state_change(ev, wref(str(c.buyer)), "coins", buyer_after - held, buyer_after, "contracts")
	state_change(ev, "contract:%d" % int(c.id), "state", was, str(c.state), "contracts")
	end(ev, "ok" if str(c.state) == "fulfilled" else "failed", "", "")


# ---------------------------------------------------------------- credit --------------------
func _party_ref(o) -> String:
	return ref_of(o) if (o is NPC or o is PlayerState) else "obj:?"


## Credit.sell_on_credit: the goods went over and a debt was recorded.
func credit_extended(seller: Object, buyer: Object, id: String, qty: int, d: Dictionary) -> void:
	var s := _party_ref(seller)
	var b := _party_ref(buyer)
	var ev := begin("credit", "debt", "credit", "extended", s, _xy(buyer).merged({"object": "debt:%d" % int(d.id),
		"detail": "debt=%d item=%s qty=%d value=%d due_day=%d" % [int(d.id), id, qty, int(d.value), int(d.due)]}))
	part(ev, seller, "creditor")
	part(ev, buyer, "debtor")
	state_change(ev, s, "item:" + id, seller.inv.count(id) + qty, seller.inv.count(id), "credit")
	state_change(ev, b, "item:" + id, buyer.inv.count(id) - qty, buyer.inv.count(id), "credit")
	state_change(ev, "debt:%d" % int(d.id), "state", "none", "open", "credit")
	end(ev)


## Credit.repay: the debtor paid the creditor.
func credit_repaid(d: Dictionary, deb, cre, late: bool) -> void:
	var v := int(d.value)
	var ev := begin("credit", "debt", "credit", "repaid_late" if late else "repaid", _party_ref(deb), {"object": "debt:%d" % int(d.id),
		"detail": "debt=%d value=%d" % [int(d.id), v]})
	part(ev, deb, "debtor")
	part(ev, cre, "creditor")
	state_change(ev, _party_ref(deb), "coins", int(deb.coins) + v, int(deb.coins), "credit")
	state_change(ev, _party_ref(cre), "coins", int(cre.coins) - v, int(cre.coins), "credit")
	state_change(ev, "debt:%d" % int(d.id), "state", "defaulted" if late else "open", str(d.state), "credit")
	end(ev)


func credit_defaulted(d: Dictionary) -> void:
	var ev := begin("credit", "debt", "credit", "defaulted", wref(str(d.debtor)), {"object": "debt:%d" % int(d.id),
		"detail": "debt=%d value=%d due_day=%d" % [int(d.id), int(d.value), int(d.due)]})
	_wpart(ev, str(d.debtor), "debtor")
	_wpart(ev, str(d.creditor), "creditor")
	state_change(ev, "debt:%d" % int(d.id), "state", "open", "defaulted", "credit")
	end(ev, "failed", "", "")


## Credit.barter: goods for goods.
func barter(seller: Object, buyer: Object, want: String, qty: int, give: String, k: int) -> void:
	var s := _party_ref(seller)
	var b := _party_ref(buyer)
	var ev := begin("credit", "barter", "credit", "barter", b, _xy(buyer).merged({"detail": "want=%s qty=%d give=%s qty=%d" % [want, qty, give, k]}))
	part(ev, buyer, "buyer")
	part(ev, seller, "seller")
	state_change(ev, s, "item:" + want, seller.inv.count(want) + qty, seller.inv.count(want), "credit")
	state_change(ev, b, "item:" + want, buyer.inv.count(want) - qty, buyer.inv.count(want), "credit")
	state_change(ev, b, "item:" + give, buyer.inv.count(give) + k, buyer.inv.count(give), "credit")
	state_change(ev, s, "item:" + give, seller.inv.count(give) - k, seller.inv.count(give), "credit")
	end(ev)


# ---------------------------------------------------------------- relations: the other channels
## Relations.helped / talked: one event on the tie with what moved.
func tie_event(kind: String, a: int, b: int, t: Dictionary, before: Array, detail := "") -> void:
	var ev := begin("relations", kind, "relation", kind, jref(a), {"object": "tie:" + Relations.key(a, b), "detail": detail})
	participant(ev, jref(a), "person")
	participant(ev, jref(b), "person")
	_tie_rows(ev, a, b, t, before)
	end(ev)


## Relations.dawn: the ties that cooled without contact, as one row a dawn (sums before and after; per-tie rows would be thousands).
func cooling_begin(ties: Dictionary) -> void:
	_cool = _tie_sums(ties)


func cooling_end(ties: Dictionary) -> void:
	if _cool.is_empty():
		return
	var after := _tie_sums(ties)
	var ev := begin("relations", "cooling", "relation", "cooling", "world", {"detail": "ties=%d cooled=%d" % [int(after[0]), int(after[3])]})
	state_change(ev, "world", "regard_sum", snappedf(float(_cool[1]), 0.01), snappedf(float(after[1]), 0.01), "relations")
	state_change(ev, "world", "attraction_sum", snappedf(float(_cool[2]), 0.01), snappedf(float(after[2]), 0.01), "relations")
	end(ev)
	_cool = []


func _tie_sums(ties: Dictionary) -> Array:
	var r := 0.0
	var a := 0.0
	var cooled := 0
	var d: int = w.day()
	for k in ties:
		var t: Dictionary = ties[k]
		r += float(t.regard)
		a += float(t.attraction)
		if int(t.last) < d - 1:
			cooled += 1
	return [ties.size(), r, a, cooled]


## Relations._villagers_court: an unpartnered adult took an interest in someone (the start of a courtship).
func court_interest(n: NPC, target: NPC, pool: int, judged: bool, attraction: float) -> void:
	var ev := begin("relations", "court", "relation", "interest", ref_of(n), _xy(n).merged({"object": "tie:" + Relations.key(n.id, target.id),
		"detail": "candidates=%d judged=%s attraction=%s" % [pool, str(judged), str(snappedf(attraction, 0.01))]}))
	part(ev, n, "suitor")
	part(ev, target, "chosen")
	end(ev)


## Before Relations.ask_court / propose: the tie as it stands.
func court_begin(kind: String, a: int, n: NPC) -> Array:
	var t: Dictionary = w.relations.peek(a, n.id)
	var ev := begin("relations", "court", "relation", kind, jref(a), _xy(n).merged({"object": "tie:" + Relations.key(a, n.id)}))
	return [ev, str(t.get("stage", "")), tie_before(t) if t.has("regard") else [0.0, 0.0, 0]]


## After it: accepted ("" answer) or refused with the answer's words, the stage before and after, and what moved.
func court_end(r: Array, kind: String, a: int, n: NPC, answer: String) -> void:
	var ev: int = r[0]
	if ev <= 0:
		return
	participant(ev, jref(a), "suitor:player" if Life.is_player_id(a) else "suitor")
	part(ev, n, "asked")
	var t: Dictionary = w.relations.peek(a, n.id)
	var stage := str(t.get("stage", ""))
	if kind == "proposal" and answer == "" and int(n.partner) == a:
		stage = "partners"
	if stage != str(r[1]):
		state_change(ev, "tie:" + Relations.key(a, n.id), "stage", str(r[1]) if str(r[1]) != "" else "none", stage if stage != "" else "none", "relations")
	if t.has("regard"):
		_tie_rows(ev, a, n.id, t, r[2])
	var why := ""
	if answer != "":
		why = "refused_by_rules"
	end(ev, "ok" if answer == "" else "refused", why, "answer=" + (answer.left(120) if answer != "" else "yes"))


# ---------------------------------------------------------------- judgment over time --------
## JudgmentStore._forget: a memory faded below the threshold (at dawn) or was crowded out (while something new was learnt: the
## open belief is its parent).
func memory_forgot(observer: int, fact: int, type: String) -> void:
	var o := jref(observer)
	var ev := begin("judgment", "memory", "judgment", "forgot", o, {"object": "fact:%d" % fact, "detail": "fact=%d type=%s; %s" % [fact, type,
		"crowded out while learning" if current() > 0 else "faded"]})
	participant(ev, o, "observer")
	state_change(ev, o, "memory:fact:%d" % fact, "held", "forgotten", "judgment")
	end(ev)


## JudgmentPersonality._log: one change of a person's traits, wisdom or anger (channel 1 provocation, 2 positive, 3 mistake, 4 reminder).
func personality_change(person: int, ch: int, subject: int, sev: int, d0: int, d1: int, extra: int) -> void:
	var names := {1: "provocation", 2: "positive", 3: "mistake", 4: "reminder"}
	var o := jref(person)
	var ev := begin("judgment", "personality", "judgment", str(names.get(ch, "channel_%d" % ch)), o, {"detail": "subject=%d severity=%d" % [subject, sev]})
	participant(ev, o, "person")
	if d0 != 0:
		factor(ev, "trait", "tolerance_delta", d0, "permille", "personality")
	if d1 != 0:
		factor(ev, "trait", "stubbornness_delta", d1, "permille", "personality")
	if extra != 0:
		factor(ev, "trait", "wisdom_or_anger", extra, "permille", "personality")
	end(ev)


## JudgmentBonds.on_belief: a victim's grievance against an actor (and a betrayal when the actor had been their friend).
func grievance(victim: int, actor: int, fact: int, added: int, total: int, betrayal: bool) -> void:
	var v := jref(victim)
	var ev := begin("judgment", "bonds", "judgment", "betrayal" if betrayal else "grievance", v, {"object": "fact:%d" % fact,
		"detail": "fact=%d added=%d" % [fact, added]})
	participant(ev, v, "victim")
	participant(ev, jref(actor), "actor")
	state_change(ev, v, "resentment:%s" % jref(actor), total - added, total, "judgment")
	end(ev)


## JudgmentStore.make_history: a significant deed became a historical record; tell_family_history: a parent passed records on.
func history_made(ev_id: int, h: Dictionary) -> void:
	var a := jref(int(h.actors[0])) if not (h.actors as Array).is_empty() else "world"
	var ev := begin("judgment", "history", "judgment", "history_made", a, {"object": "fact:%d" % ev_id,
		"detail": "fact=%d type=%s value=%d known=%d" % [ev_id, str(h.type), int(h.value), (h.known as Dictionary).size()]})
	for x in h.actors:
		participant(ev, jref(int(x)), "actor")
	end(ev)


func history_told(parent: int, child: int, n: int) -> void:
	if n <= 0:
		return
	var ev := begin("judgment", "history", "judgment", "history_told", jref(parent), {"detail": "records=%d" % n})
	participant(ev, jref(parent), "parent")
	participant(ev, jref(child), "child")
	end(ev)


# ---------------------------------------------------------------- the day's summaries --------
## At the first hour boundary of each game day (WorldRecorder.hour): what changed over the day in memory, the world's resources
## and the LE-01 model. Reads plain fields and pure functions only (judgment.stats, not counts(), which flushes gossip).
func _day_summaries() -> void:
	var d: int = w.day()
	if d == _day_seen:
		return
	var first := _day_seen < 0
	_day_seen = d
	if w.judgment != null:
		var j = w.judgment
		var ev := begin("judgment", "day", "summary", "judgment_day", "world", {"detail": "day=%d facts=%d history=%d" % [d, j.facts.size(), j.history.size()]})
		var moved := _moved(j.stats, _jstats_seen)
		if not first:
			for k in moved:
				factor(ev, "day", "stat:" + str(k), moved[k], "count", "judgment")
		var bm := _moved(j.bonds.stats, _bstats_seen)
		if not first:
			for k in bm:
				factor(ev, "day", "bonds:" + str(k), bm[k], "count", "judgment")
		var mem := 0
		for o in j.memories:
			mem += (j.memories[o] as Dictionary).size()
		factor(ev, "day", "memories_held", mem, "count", "judgment")
		factor(ev, "day", "people_remembering", j.memories.size(), "count", "judgment")
		factor(ev, "day", "aspiration_on", str(j.asp.enabled), "flag", "judgment")
		end(ev)
	var wd := begin("world", "day", "summary", "world_day", "world", {"detail": "day=%d" % d})
	var by_ore := {}
	var out := 0
	for dep in w.deposits:
		var ore := str(dep.get("ore", "?"))
		by_ore[ore] = int(by_ore.get(ore, 0)) + int(dep.get("amount", 0))
		if int(dep.get("amount", 0)) <= 0:
			out += 1
	var ores := by_ore.keys()
	ores.sort()
	for ore in ores:
		factor(wd, "deposits", "left:" + str(ore), int(by_ore[ore]), "units", "world_state")
	factor(wd, "deposits", "worked_out", out, "seams", "world_state")
	factor(wd, "deposits", "seams", w.deposits.size(), "seams", "world_state")
	var mature := 0
	for t in w.trees:
		if str(t.get("state", "")) == "mature":
			mature += 1
	factor(wd, "trees", "standing", w.trees.size(), "trees", "world_state")
	factor(wd, "trees", "mature", mature, "trees", "world_state")
	var hh := 0
	for h in w.households.size():
		if not w.households[h].get("ended", false) and not w.brain._members(h).is_empty():
			hh += 1
	factor(wd, "people", "households_with_members", hh, "households", "world_state")
	if w.regions != null:
		factor(wd, "regions", "coins", int(w.regions.coins()), "coins", "world_state")
		var goods: Dictionary = w.regions.goods()
		var gt := 0
		for g in goods:
			gt += int(goods[g])
		factor(wd, "regions", "goods", gt, "units", "world_state")
	if w.discovery != null:
		var inds: Array = w.discovery.levels.keys()
		inds.sort()
		for ind in inds:
			factor(wd, "capability", "level:" + str(ind), int(w.discovery.levels[ind]), "level", "world_state")
		var hist: Array = w.discovery.history
		for i in range(mini(_disc_hist, hist.size()), hist.size()):
			var r: Dictionary = hist[i]
			factor(wd, "capability", "change:%s" % str(r.get("industry", "")), "%s->%s %s" % [str(r.get("from", "")), str(r.get("to", "")), str(r.get("why", "")).left(80)], "text", "world_state")
		_disc_hist = hist.size()
	if w.contracts != null:
		var open := 0
		for c in w.contracts.list:
			if Contracts.is_open(c):
				open += 1
		factor(wd, "contracts", "open", open, "contracts", "world_state")
		factor(wd, "contracts", "reserved_coins", int(w.contracts.reserved_total()), "coins", "world_state")
	if w.credit != null:
		factor(wd, "credit", "debts_open", w.credit.debts_of("", "", false).size(), "debts", "world_state")
	end(wd)
	if w.economy != null:
		var ec = w.economy
		var em := begin("economy", "model", "summary", "economy_model", "world", {"detail": "LE-01 (observing only)"})
		factor(em, "model", "events", ec.events.size(), "count", "economy_model")
		factor(em, "model", "events_ordered", str(ec.events.ordered()), "flag", "economy_model")
		factor(em, "model", "knowledge", ec.knowledge.size(), "count", "economy_model")
		factor(em, "model", "needs_recorded", ec.needs.recorded().size(), "count", "economy_model")
		factor(em, "model", "needs_dirty", ec.needs.dirty.size(), "count", "economy_model")
		factor(em, "model", "offers", ec.offers.records.size(), "count", "economy_model")
		factor(em, "model", "reservations", ec.reservations.records.size(), "count", "economy_model")
		factor(em, "model", "unbacked", ec.reservations.unbacked().size(), "count", "economy_model")
		factor(em, "model", "contract_links", ec.contract_links.links.size(), "count", "economy_model")
		end(em, "ok" if ec.reservations.unbacked().is_empty() and ec.events.ordered() else "failed", "", "")
		if not ec.reservations.unbacked().is_empty():
			alert("violation", "economy.unbacked_reservation", "world", "unbacked=%d" % ec.reservations.unbacked().size(), em)


## {key: change} of the numeric entries of `now` against `seen` (then updated), sorted keys.
func _moved(now: Dictionary, seen: Dictionary) -> Dictionary:
	var out := {}
	var ks := now.keys()
	ks.sort()
	for k in ks:
		var v = now[k]
		if typeof(v) in [TYPE_INT, TYPE_FLOAT] and v != seen.get(k, 0):
			out[k] = int(v) - int(seen.get(k, 0)) if typeof(v) == TYPE_INT else snappedf(float(v) - float(seen.get(k, 0.0)), 0.01)
			seen[k] = v
	return out


# ---------------------------------------------------------------- network (multiplayer) ------
## NetSession hooks, on the host (the authoritative world) and on a guest (its copy, which never simulates: no hourly audit runs
## there, so a guest's archive holds its network events and its digests only). `who` is a PlayerState or null.
func net_event(session, kind: String, who, detail := "", outcome := "ok") -> void:
	net = session
	var role := str(session.role) if session != null else ""
	var ev := begin("net", role if role != "" else "session", "network", kind, ref_of(who) if who != null else "world", {"detail": detail})
	if who != null:
		participant(ev, ref_of(who), "player")
	end(ev, outcome, "", "")
	flush_soon()


## Host: a guest's request applied (a verb or an action), with its result.
func net_request(session, who: PlayerState, kind: String, r: Dictionary) -> void:
	net = session
	var ok := bool(r.get("ok", true)) and str(r.get("result", "")) != "failed"
	var ev := begin("net", "host", "network", "request", ref_of(who) if who != null else "world", {"detail": "kind=%s path=%s text=%s" % [kind,
		str(r.get("path", "")), str(r.get("text", "")).left(100)]})
	if who != null:
		participant(ev, ref_of(who), "player")
	end(ev, "ok" if ok else "failed", "", "")


## Syncs sent (host) or adopted (guest): counted for the next digest, never one row each (several a second).
func net_sync(session, sent: bool, sections: int, nbytes: int, hour_mark := false) -> void:
	net = session
	var k := "sent" if sent else "adopted"
	_net_counts[k] = int(_net_counts.get(k, 0)) + 1
	_net_counts[k + "_sections"] = int(_net_counts.get(k + "_sections", 0)) + sections
	_net_counts[k + "_bytes"] = int(_net_counts.get(k + "_bytes", 0)) + nbytes
	if not sent and hour_mark:
		net_state_maybe()                    # X20: the sync the host marked at its hour: this copy now holds what the host's digest saw


## One digest a game hour per participant: role, the players this machine knows, each shared section's hash (NetSync.digest of
## World.to_dict, the hashes the host's syncs compare), and the syncs since the last one. tools/recorder_archive.py
## --participants compares the host's and guests' digests hour by hour.
func net_state_maybe() -> void:
	if net == null or not is_instance_valid(net) or str(net.role) == "" or stopped or finished:
		return
	var hk := int(w.minutes / 60.0)
	if hk == _net_hour:
		return
	_net_hour = hk
	var ev := begin("net", str(net.role), "network", "net_state", ref_of(w.player), {"detail": "role=%s minute=%d" % [str(net.role), int(w.minutes)]})
	var players := []
	for p: PlayerState in w.player_list():
		players.append("%s coins=%d alive=%s away=%s" % [ref_of(p), int(p.coins), str(p.alive), str(p.away)])
	factor(ev, "net", "players", "; ".join(players), "text", "network")
	factor(ev, "net", "peers", (net.by_peer as Dictionary).size() if str(net.role) == "host" else 1, "count", "network")
	var d: Dictionary = w.to_dict()
	var dig: Dictionary = net_digest(d)
	var ks := dig.keys()
	ks.sort()
	for k in ks:
		factor(ev, "section", str(k), str(dig[k]), "hash", "network")
	if str(net.role) == "host":                # X20: each guest is sent only its own offers (NetSession._private_for): what its copy should hold
		for id in net.by_peer:
			var g: PlayerState = w.player_by_pid(int(net.by_peer[id]))
			if g != null:
				var dd := d.duplicate(false)
				NetSession._private_for(dd, w.player_ref(g))
				factor(ev, "for", "%s|player_offers" % ref_of(g), str(net_digest(dd).get("player_offers", "absent")), "hash", "network")     # keyed as that guest's own digests name it (its actor)
	for k in _net_counts:
		factor(ev, "sync", str(k), int(_net_counts[k]), "count", "network")
	_net_counts.clear()
	end(ev)
	flush_soon()


## X20: the hash of each shared section as both machines can compare it: by content (a JSON round trip, keys sorted: numbers read
## from a save or a sync are floats where a new world's are ints), without the live fields the faster snapshots carry instead of the
## sections (a villager's or an animal's place, facing and animation: NetSync.NPC_LIVE, NetSession.s_animals). Reads only.
static func net_digest(d: Dictionary) -> Dictionary:
	var out := {}
	for k in NetSync.KEYS:
		if not d.has(k):
			continue
		var v = JSON.parse_string(JSON.stringify(d[k]))
		if k == "npcs" and v is Array:
			for n in v:
				if n is Dictionary:
					for f in NetSync.NPC_LIVE:
						n.erase(f)
		elif k == "fauna" and v is Dictionary:
			for a in v.get("animals", []):
				if a is Dictionary:
					a.erase("pos")
					a.erase("hp")              # the snapshots' (s_animals) too
		out[k] = hash(JSON.stringify(v, "", true))
	return out


## A guest's world never reaches an hour boundary (it does not simulate): write what is buffered now.
func flush_soon() -> void:
	if net != null and is_instance_valid(net) and str(net.role) == "guest":
		flush()
