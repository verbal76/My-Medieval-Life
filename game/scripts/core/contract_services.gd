class_name ContractServices
extends RefCounted
## CON-02 (owner directive 2026-10-21, `docs/directives/2026-10-21_build17_con01_final_decisions_service_contracts.md`
## section 2: service contracts OWNER APPROVED, inside the one CON-01 engine): the work a service contract asks for.
## This is not a second contract engine: the record, negotiation (evaluate, counters, buyer_answer), signing, the
## reservation, payment, lapse, cancellation, death and save are Contracts'. This module only answers, for each kind of
## service the game already performs, what Contracts asks of a kind: can this person do it (means), what the same work
## pays on the village's existing scale (going), how a villager seller does the next piece of it (plan, step) through
## the existing work system, and what happens to anything it holds when the contract ends (release).
##
## A service record is a CON-01 record with kind "service", item "" and: service (the kind), site (where: {pit} or
## {clue}), qty (units of work: units dug, readings reported), price_each (per unit of work), deadline, and the
## kind's progress: load {item: count} (goods dug for the buyer and still carried), sids (samples taken for it).
## A unit of work counts, and is paid from the coins set aside, only when it is done through the work system (a unit
## dug by OpenPits.dig, a reading assayed by Prospecting.assay and told to the buyer by Prospecting.share): accepting a
## contract makes no work, goods or knowledge (section 2, "Fulfillment").
##
## Kinds built (existing work systems only, PAR-01: the player and villagers by one rule):
##  - "dig" (MIN-E): dig `qty` units from an open pit the buyer owns (the player's, or the manor's by its reeve), with
##    the layer's tool (a shovel for earth, a pickaxe for rock: MIN-E-Q4), by OpenPits.dig; the earth is tipped on the pit's spoil heaps and any stone brought to the buyer (the
##    player's chest at home, the manor's works yard), as the manor's own excavate job does.
##  - "survey" (MIN-C/MIN-D; answers MIN-D-Q1, "the manor is not the only employer"): take `qty` rock samples of a
##    clue's area with one's own kit, have each assayed by a smith (the fee is the seller's, as on the manor's survey),
##    and tell the buyer each reading. Any buyer: the player, a villager or the manor.
## Not built (no existing system to perform them; recorded as dependencies, docs/build17/CON02_SERVICES.md): guard
## protection (no escort or guarding behaviour), transport between settlements (Expansion 18), building repair by
## contract (the manor's mend jobs only), harvesting another's field (the farming hire and theft rules are the paid
## work quests'), construction steps and carrying (the hired carriers, kept as they are).

const KINDS := ["dig", "survey"]


static func cfg() -> Dictionary:
	return GameData.b("contracts").get("services", {})


# ---------------------------------------------------------------- terms ----------------------
## Why `buyer_ref` cannot ask for this service at all ("" if it can): a known kind; a dig only in a pit the buyer owns;
## a survey of a real clue.
static func site_refusal(k, buyer_ref: String, svc: Dictionary) -> String:
	var w: World = k.w
	match str(svc.get("service", "")):
		"dig":
			var p := w.pits.pit(int(svc.get("site", {}).get("pit", -1)))
			if p.is_empty():
				return "There is no such pit."
			if str(p.owner) != buyer_ref:
				return "That pit is not yours to have dug."
			return ""
		"survey":
			return "" if not w.prospecting.clue(str(svc.get("site", {}).get("clue", ""))).is_empty() else "There is no such stain to survey."
	return "That is not work anyone here does."


## The service in words: "dig 6 units of your open pit north of the mine".
static func words(k, c: Dictionary) -> String:
	var w: World = k.w
	match str(c.get("service", "")):
		"dig":
			var p := w.pits.pit(int(c.site.pit))
			return "dig %d from %s open pit %s" % [int(c.qty), "the manor's" if str(c.buyer) == World.MANOR else ("your" if World.is_player_ref(c.buyer) else w.ref_name(c.buyer) + "'s"),
					w.where(OpenPits.rect(p)) if not p.is_empty() else "(gone)"]
		"survey":
			var cl := w.prospecting.clue(str(c.site.clue))
			return "survey %s %s: %d readings" % [w.prospecting.stain(cl), w.prospecting.place(cl), int(c.qty)]
	return "work"


## The going rate for a unit of this work: what the manor's own job board pays for the same work (ManorWork:
## an excavation load at the quarry rate a unit; a survey's wage over its samples).
static func going(svc: Dictionary) -> float:
	match str(svc.get("service", "")):
		"dig":
			return float(ManorWork.excavate_wage()) / float(maxi(1, ManorWork.excavate_load()))
		"survey":
			var dc: Dictionary = Discovery.cfg().manor
			return float(dc.survey_wage) / float(maxi(1, int(dc.survey_samples)))
	return 1.0


# ---------------------------------------------------------------- can it be done -------------
## Contracts.means for a service: {stock 0, rate (units a work minute), cap (units by the deadline), route
## "service", cost (coins a unit the seller pays out: the assay fee), why}.
static func means(k, n: NPC, svc: Dictionary, days: int) -> Dictionary:
	var w: World = k.w
	var out := {"stock": 0, "rate": 0.0, "cap": 0, "route": "", "recipe": "", "cost": 0, "why": "none"}
	var mins: float = k._work_minutes(n, days)
	match str(svc.get("service", "")):
		"dig":
			var p := w.pits.pit(int(svc.get("site", {}).get("pit", -1)))
			if OpenPits.kinds_held(n).is_empty() or (not p.is_empty() and w.pits.next_dig(p, n.cell(), n.cell(), OpenPits.kinds_held(n)).x < 0 and remaining(p) > 0):
				out.why = "tool:shovel" if OpenPits.held_tool(n, "shovel") == "" else "tool:pickaxe"     # MIN-E-Q4: earth a shovel, rock a pickaxe
			elif p.is_empty() or remaining(p) <= 0:
				out.why = "source"
			else:
				var per := _dig_minutes(p) * Skills.value(n, "mining", "mine_time", 1.0) * float(cfg().get("overhead", 1.25))
				out.rate = 1.0 / per
				out.cap = mini(remaining(p), Contracts._by_time(float(out.rate) * mins))
				out.route = "service"
		"survey":
			var c := w.prospecting.clue(str(svc.get("site", {}).get("clue", "")))
			var fee := int(Prospecting.cfg().assay.fee)
			if not n.inv.has(Prospecting.KIT):
				out.why = "tool:kit"
			elif c.is_empty() or w.prospecting.samples_left(c) <= 0:
				out.why = "source"
			elif n.coins - w.reserve_of(n) < fee:
				out.why = "coins"
			else:
				var per := (float(Prospecting.cfg().sample_minutes) * Skills.value(n, "mining", "mine_time", 1.0) + float(Prospecting.cfg().assay.minutes)) \
						* float(cfg().get("overhead", 1.25)) + float(cfg().get("survey_walk_minutes", 60))
				out.rate = 1.0 / per
				out.cap = mini(mini(w.prospecting.samples_left(c), (n.coins - w.reserve_of(n)) / fee), Contracts._by_time(float(out.rate) * mins))
				out.cost = fee
				out.route = "service"
		_:
			out.why = "skill"
	return out


## Units still to dig in pit `p` (every cell down to its ring's depth).
static func remaining(p: Dictionary) -> int:
	var left := 0
	for i in OpenPits.size() * OpenPits.size():
		left += maxi(0, OpenPits.cap(i) - int(p.dug[i]))
	return left


## Minutes a unit of the pit's next bench takes (its shallowest undug layer).
static func _dig_minutes(p: Dictionary) -> float:
	var least := 1 << 30
	for i in OpenPits.size() * OpenPits.size():
		if int(p.dug[i]) < OpenPits.cap(i):
			least = mini(least, int(p.dug[i]))
	return OpenPits.minutes_of(least) if least < (1 << 30) else 25.0


# ---------------------------------------------------------------- doing it -------------------
## A villager seller's next piece of a service contract (Contracts.plan, working hours). True if a plan was made.
static func plan(k, n: NPC, c: Dictionary) -> bool:
	match str(c.service):
		"dig":
			return _plan_dig(k, n, c)
		"survey":
			return _plan_survey(k, n, c)
	return false


## The act at the end of a villager's walk or work (NPCBrain act "svc_step").
static func step(k, n: NPC, c: Dictionary) -> bool:
	match str(c.service):
		"dig":
			return _step_dig(k, n, c)
		"survey":
			return _step_survey(k, n, c)
	return false


static func _load(c: Dictionary) -> Inventory:
	var inv := Inventory.new()
	for id in c.get("load", {}):
		inv.items[id] = int(c.load[id])
	return inv


static func _store(c: Dictionary, inv: Inventory) -> void:
	c.load = inv.items.duplicate()


static func _earth(inv: Inventory) -> int:
	var e := 0
	for id in OpenPits.earth_items():
		e += inv.count(id)
	return e


## Where stone dug for the buyer goes: the player's chest at their home, the manor's works yard; null when it has
## nowhere to go yet (a player without a home collects it in the contract window).
static func _stone_to(k, c: Dictionary) -> Inventory:
	var w: World = k.w
	if c.buyer == World.MANOR:
		return w.manor_work.yard
	if World.is_player_ref(c.buyer) and w.player_for(c.buyer).home != "" and w.buildings.has(w.player_for(c.buyer).home):
		return w.player_for(c.buyer).chest
	return null


static func _plan_dig(k, n: NPC, c: Dictionary) -> bool:
	var w: World = k.w
	var b: NPCBrain = w.brain
	var p := w.pits.pit(int(c.site.pit))
	var load := _load(c)
	var kinds := OpenPits.kinds_held(n)                     # MIN-E-Q4: the cells its digger's tools can dig
	var work_left: bool = Contracts.left(c) > 0 and not p.is_empty() and not kinds.is_empty()
	var cell: Vector2i = w.pits.next_dig(p, n.cell(), n.cell(), kinds) if work_left else Vector2i(-1, -1)
	var full := load.total() >= ManorWork.excavate_load()
	if _earth(load) > 0 and not p.is_empty() and (full or cell.x < 0):
		var hc: Vector2i = Vector2i(int(p.heaps[0].x), int(p.heaps[0].y)) if not (p.heaps as Array).is_empty() else n.cell()
		for h in p.heaps:
			if (h.inv as Inventory).total() < w.pits.heap_cap(p):
				hc = Vector2i(int(h.x), int(h.y))
				break
		var stand: Vector2i = w.pits.stand_beside(hc, n.cell())
		n.doing = "tipping earth for %s" % w.ref_name(c.buyer)
		n.plan = [b.go(stand if stand.x >= 0 else b.beside(hc, n.cell())), b.doit("svc_step", {"id": int(c.id)})]
		return true
	if load.count("stone") > 0 and (full or cell.x < 0) and _stone_to(k, c) != null:
		var at: Vector2i = w.manor_work.yard_cell() if c.buyer == World.MANOR else w.building_door(w.player.home)
		n.doing = "bringing stone to %s" % w.ref_name(c.buyer)
		n.plan = [b.go(at), b.doit("svc_step", {"id": int(c.id)})]
		return true
	if cell.x < 0 or full:
		return false
	var i := OpenPits.index(p, cell)
	c.cell = [cell.x, cell.y]
	n.doing = "digging %s open pit" % ("the manor's" if c.buyer == World.MANOR else w.ref_name(c.buyer) + "'s")
	n.plan = [b.go(w.pits.stand_for(p, i, n.cell())), b.work(OpenPits.minutes_of(int(p.dug[i])) * Skills.value(n, "mining", "mine_time", 1.0),
			"svc_step", {"id": int(c.id)}, "swing", cell)]
	return true


static func _step_dig(k, n: NPC, c: Dictionary) -> bool:
	var w: World = k.w
	var p := w.pits.pit(int(c.site.pit))
	var load := _load(c)
	if p.is_empty():
		return false
	# at a heap: tip the earth; at the buyer's: leave the stone
	var hc_near := false
	for h in p.heaps:
		if n.pos.distance_to(Vector2(int(h.x), int(h.y)) + Vector2(0.5, 0.5)) <= 2.0:
			hc_near = true
	if hc_near and _earth(load) > 0:
		var moved: Dictionary = w.pits.tip(p, load)
		_store(c, load)
		k._maybe_finish(c)
		return not moved.is_empty()
	var to := _stone_to(k, c)
	if to != null and load.count("stone") > 0 and _earth(load) == 0:
		w.transfer(load, to, "stone", load.count("stone"))
		_store(c, load)
		k._maybe_finish(c)
		return true
	if Contracts.left(c) <= 0 or not c.has("cell"):
		return false
	var cell := Vector2i(int(c.cell[0]), int(c.cell[1]))
	var tool := OpenPits.held_tool(n, w.pits.tool_needed(p, cell))
	var r: Dictionary = w.pits.dig(n, p, cell, load, tool)
	c.erase("cell")
	if r.result != "ok":
		return false
	_store(c, load)
	if r.broke:
		w.note("%s %s's %s broke." % [n.name, n.family, GameData.item_name(tool).to_lower()])
	k._pay_units(c, 1)
	return true


static func _pending(k, c: Dictionary) -> Array:
	return (c.get("sids", []) as Array).filter(func(s): return k.w.prospecting.samples.has(str(int(s))))


## Readings taken for this contract that the buyer has not been told yet.
static func _untold(k, c: Dictionary) -> Array:
	var pr: Prospecting = k.w.prospecting
	return pr.records.filter(func(r): return (c.get("sids", []) as Array).has(int(r.sample)) and str(r.by) == str(c.seller) and not pr.knows(str(c.buyer), r))


## The next spot of the clue to sample: the first of its spots (hashed order) unsampled and open now.
static func _spot(k, c: Dictionary) -> Vector2i:
	var pr: Prospecting = k.w.prospecting
	var cl := pr.clue(str(c.site.clue))
	if cl.is_empty() or pr.samples_left(cl) <= 0:
		return Vector2i(-1, -1)
	for cell: Vector2i in cl.spots:
		if not pr.sampled(cl, cell) and not k.w.map.is_solid(cell):
			return cell
	return Vector2i(-1, -1)


static func _buyer_cell(k, c: Dictionary) -> Vector2i:
	var w: World = k.w
	if c.buyer == World.MANOR:
		return w.building_door(w.brain._manor_id())
	if World.is_player_ref(c.buyer):
		return Vector2i(w.player_for(c.buyer).pos.floor())
	var b: NPC = k._npc_of(c.buyer)
	return b.cell() if b != null else Vector2i(-1, -1)


static func _plan_survey(k, n: NPC, c: Dictionary) -> bool:
	var w: World = k.w
	var b: NPCBrain = w.brain
	var sids: Array = c.get("sids", [])
	if not _untold(k, c).is_empty():
		var at := _buyer_cell(k, c)
		if at.x < 0:
			return false
		n.doing = "telling %s what the samples show" % w.ref_name(c.buyer)
		n.plan = [b.go(at if c.buyer == World.MANOR else b.beside(at, n.cell())), b.doit("svc_step", {"id": int(c.id)})]
		return true
	var pending := _pending(k, c)
	var spot := _spot(k, c) if sids.size() < int(c.qty) and n.inv.has(Prospecting.KIT) else Vector2i(-1, -1)
	if not pending.is_empty() and (spot.x < 0 or pending.size() >= int(Prospecting.cfg().carry_samples)):
		var a: NPC = w.prospecting.assayer_for(n)
		if a == null:
			return false
		n.doing = "taking samples to the assayer for %s" % w.ref_name(c.buyer)
		n.plan = [b.go(b._workplace_cell(a)), b.doit("svc_step", {"id": int(c.id), "assayer": a.id}), b.work(float(Prospecting.cfg().assay.minutes) + 10.0, "", {}, "idle")]
		return true
	if spot.x < 0:
		return false
	n.doing = "surveying %s for %s" % [w.prospecting.stain(w.prospecting.clue(str(c.site.clue))), w.ref_name(c.buyer)]
	c.cell = [spot.x, spot.y]
	n.plan = [b.go(spot), b.work(float(Prospecting.cfg().sample_minutes) * Skills.value(n, "mining", "mine_time", 1.0), "svc_step", {"id": int(c.id)}, "work", spot)]
	return true


static func _step_survey(k, n: NPC, c: Dictionary) -> bool:
	var w: World = k.w
	var pr: Prospecting = w.prospecting
	var untold := _untold(k, c)
	if not untold.is_empty() and (c.buyer == World.MANOR and n.pos.distance_to(Vector2(_buyer_cell(k, c))) <= 3.0 or k.face_to_face(c.seller, c.buyer)):
		return tell(k, c, untold) > 0
	var pending := _pending(k, c)
	if not pending.is_empty():
		var a: NPC = null                         # a smith at the forge here who can assay it now
		for o: NPC in w.npcs:
			if o.alive and o.job == "smith" and n.pos.distance_to(o.pos) <= 3.5 and pr.assayer_refusal(n, o) == "":
				a = o
				break
		if a != null:
			return str(pr.assay(n, a, int(pending[0])).result) == "ok"
		if _spot(k, c).x < 0 or not c.has("cell"):
			return false
	if not c.has("cell"):
		return false
	var cell := Vector2i(int(c.cell[0]), int(c.cell[1]))
	c.erase("cell")
	var r: Dictionary = pr.take_sample(n, pr.clue(str(c.site.clue)), cell)
	if r.result != "ok":
		return false
	var sids: Array = c.get("sids", [])
	sids.append(int(r.sample))
	c.sids = sids
	if r.broke:
		w.note("%s %s's prospector's kit is worn out." % [n.name, n.family])
	return true


## The seller tells the buyer readings taken for the contract (each a unit of work): shared with the buyer
## (Prospecting.share) and paid one by one from the coins set aside. Returns the readings told.
static func tell(k, c: Dictionary, recs: Array) -> int:
	var told := 0
	for r in recs:
		if Contracts.left(c) - told <= 0:
			break
		if k.w.prospecting.share(r, str(c.buyer)):
			told += 1
	if told > 0:
		k._pay_units(c, told)
	return told


## The player as a survey seller: readings the player took for this contract (their samples of its clue, assayed
## since it was made) are told to the buyer in the contract window (face to face). Returns the readings told.
static func player_report(k, c: Dictionary, actor: PlayerState = null) -> int:
	# MP C (World.mirror): a guest's verb goes to the host
	if k.w.mirrors():
		return k.w.mirror("ContractServices:player_report", player_report.bind(k, c), [c])
	if actor != null and actor != k.w.player:
		return k.w.as_actor(actor, player_report.bind(k, c))
	if not Contracts.is_open(c) or not World.is_player_ref(c.seller) or str(c.get("service", "")) != "survey":
		return 0
	if c.buyer != World.MANOR and not k.face_to_face(k.w.acting_ref(), c.buyer):
		return 0
	var pr: Prospecting = k.w.prospecting
	var recs := pr.records.filter(func(r): return World.is_player_ref(str(r.by)) and str(r.clue) == str(c.site.clue) and int(r.day) >= int(c.made_day) \
			and not pr.knows(str(c.buyer), r))
	return tell(k, c, recs)


## The player collects stone dug for them that has nowhere to be brought (no home): from the seller's load, face to face.
static func player_collect(k, c: Dictionary, actor: PlayerState = null) -> int:
	# MP C (World.mirror): a guest's verb goes to the host
	if k.w.mirrors():
		return k.w.mirror("ContractServices:player_collect", player_collect.bind(k, c), [c])
	if actor != null and actor != k.w.player:
		return k.w.as_actor(actor, player_collect.bind(k, c))
	if not World.is_player_ref(c.buyer) or str(c.get("service", "")) != "dig":
		return 0
	var load := _load(c)
	var n := load.count("stone")
	if n <= 0 or not k.face_to_face(k.w.acting_ref(), c.seller) or not k.w.player.inv.can_add("stone"):
		return 0
	k.w.transfer(load, k.w.player.inv, "stone", n)
	_store(c, load)
	k._maybe_finish(c)
	return n


## Whether the service's work is all done and nothing of the buyer's is still carried.
static func finished(c: Dictionary) -> bool:
	return Contracts.left(c) <= 0 and (c.get("load", {}) as Dictionary).is_empty()


## The contract ended: what the seller still carries of the buyer's goes where it belongs (earth onto the pit's heaps,
## stone to the buyer: its chest at home or its pack, the manor's yard), as ManorWork.release does for its jobs.
static func release(k, c: Dictionary) -> void:
	if (c.get("load", {}) as Dictionary).is_empty():
		return
	var w: World = k.w
	var load := _load(c)
	var p := w.pits.pit(int(c.get("site", {}).get("pit", -1)))
	if not p.is_empty():
		w.pits.tip(p, load, true)
	var to := _stone_to(k, c)
	if to == null:
		var bp := w.player_of_ref(c.buyer)
		to = bp.inv if bp != null else (w.manor_work.yard as Inventory)
	for id in load.ids():
		w.transfer(load, to, id, load.count(id))
	_store(c, load)


## Goods dug for buyers and still carried on service contracts (the goods census counts them).
static func goods(k) -> Dictionary:
	var out := {}
	for c in k.list:
		for id in c.get("load", {}):
			out[id] = int(out.get(id, 0)) + int(c.load[id])
	return out


## The services a seller could be asked for by `buyer_ref` now, for the talk window: [{service, site, label}].
static func options(k, buyer_ref: String) -> Array:
	var w: World = k.w
	var out := []
	for p in w.pits.pits:
		if str(p.owner) == buyer_ref and remaining(p) > 0:
			out.append({"service": "dig", "site": {"pit": int(p.id)}, "label": "Dig your open pit %s" % w.where(OpenPits.rect(p))})
	var at: Vector2 = w.player.pos
	var cl := w.prospecting.clues.filter(func(c): return w.prospecting.samples_left(c) > 0)
	cl.sort_custom(func(a, b): return at.distance_to(Vector2(int(a.x), int(a.y))) < at.distance_to(Vector2(int(b.x), int(b.y))) \
			or (at.distance_to(Vector2(int(a.x), int(a.y))) == at.distance_to(Vector2(int(b.x), int(b.y))) and str(a.id) < str(b.id)))
	for c in cl.slice(0, int(cfg().get("survey_options", 3))):
		out.append({"service": "survey", "site": {"clue": str(c.id)}, "label": "Survey %s %s" % [w.prospecting.stain(c), w.prospecting.place(c)]})
	return out
