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


static func ref_of(o) -> String:
	if o is NPC:
		return "p:%d" % o.id
	if o is PlayerState:
		return "p:player"
	return "obj:?"


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
		_inv_refs[w.player.inv.get_instance_id()] = "p:player"
		for i in w.households.size():
			_inv_refs[(w.households[i].pantry as Inventory).get_instance_id()] = World.hh_ref(i)
		_inv_refs[w.granary.get_instance_id()] = "granary"
		if _inv_refs.has(key):
			return str(_inv_refs[key])
	return "inv:?"


func _note_state_change(ref: String, prop: String, delta, authority: String) -> void:
	if authority != "audit" and prop == "coins" and typeof(delta) == TYPE_INT:
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
	participant(ev, b, "buyer")
	participant(ev, s, "seller")
	state_change(ev, b, "coins", t[1], int(buyer.coins), "world.trade")
	state_change(ev, s, "coins", t[2], int(seller.coins), "world.trade")
	state_change(ev, b, "item:" + id, t[3], buyer.inv.count(id), "world.trade")
	state_change(ev, s, "item:" + id, t[4], seller.inv.count(id), "world.trade")
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
	participant(ev, ref_of(buyer), "buyer")
	participant(ev, ref_of(seller), "seller")
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


# ---------------------------------------------------------------- the hour ------------------
## Called at each game-hour boundary (World._on_hour): write the buffer, audit the coins, take the hourly samples.
func hour() -> void:
	flush()
	if stopped or finished:
		return
	_audit_coins()
	if samples_on:
		for n: NPC in w.npcs:
			if n.alive:
				var c := n.cell()
				sample("p:%d" % n.id, snappedf(n.hunger, 0.1), snappedf(n.hp, 0.1), c.x, c.y, n.doing, n.coins)
		sample("p:player", snappedf(w.player.hunger, 0.1), snappedf(w.player.hp, 0.1), int(w.player.pos.x), int(w.player.pos.y), "", w.player.coins)


## REC-D4: balance auditing, not a rewrite of the coin sites. A holder's purse is compared with its last audited balance
## plus the coin changes the recorder saw; World.total_coins with its last value plus those changes plus the change in
## World.coin_sources (coins crossing the village boundary). A difference is an "unattributed" event and an alert.
func _audit_coins() -> void:
	var total: int = w.total_coins()
	var src: int = int(w.coin_sources)
	var holders := {}
	for n: NPC in w.npcs:
		holders["p:%d" % n.id] = n.coins
	holders["p:player"] = w.player.coins
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
