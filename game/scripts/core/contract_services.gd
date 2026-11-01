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
##  - "harvest" (CON-06, CON02-S-4; Decision 2): cut `qty` ripe cells of a field the buyer holds (a villager household's farm
##    plot, FarmPlots, or ground the player holds, Farming), by the farming work's own rule (FarmPlots.harvest /
##    Farming.harvest_into: the crop and its seed back go straight into the owner's store, as a member's own cutting does: the
##    household's pantry, the player's chest at home). The crop stays the owner's: the worker never holds it, and cutting it
##    under the contract is not theft. No tool; the work trains Farming (DVW-B8).
## Not built (no existing system to perform them; recorded as dependencies, docs/build17/CON02_SERVICES.md): guard
## protection (no escort or guarding behaviour), transport between settlements (Expansion 18), building repair by
## contract (the manor's mend jobs; a villager's tool is mended for pay by LE-05 paid repair, World.work_repair's rule),
## construction steps and carrying (the hired carriers, kept as they are).
##
## Decision 2 (owner 2026-11-01) and CON-03..CON-08 (docs/expansion20/SERVICES.md): the terms of a service (`terms`):
##  pay        "on_delivery" (the default: each unit of work as it is done), "on_result" (CON-04: only units with a verifiable
##             result: a dig that brings up stone, a reading that shows ore), "base_bonus" (each unit, plus bonus_each for each
##             result), "favour" (Decision 2: nothing paid; a friend, partner or kin only, favour_refusal);
##  retain     CON-05: the share of each unit's pay held back until the work is complete (0..retain_max);
##  advance    CON-03: {amount, purpose}: coins set aside for the named expense of the work (a survey's assay fees), drawn only
##             when that expense is paid (spend_advance), the rest returned with the contract's other coins.
## Every coin of these is set aside when the contract opens and held in its `reserved`: nothing is created or promised unfunded.

const KINDS := ["dig", "survey", "harvest"]
const PAYS := ["on_delivery", "on_result", "base_bonus", "favour"]
const PURPOSES := {"survey": "assay_fee"}            # CON-03: the expense of each kind an advance may meet
const PAY_NAMES := {"on_delivery": "for the work done", "on_result": "for results only", "base_bonus": "a base and a bonus for each result",
	"favour": "as a favour, nothing paid"}


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
		"harvest":
			var p: Dictionary = w.plot(str(svc.get("site", {}).get("plot", "")))
			if p.is_empty() or FarmPlots.is_church(p):
				return "There is no such field."
			if not w.holds(_holder_ref(k, buyer_ref), p):
				return "That field is not yours to have harvested."
			if _crop_store(k, buyer_ref) == null:
				return "There is nowhere to bring the crop: a hired hand brings it to your chest at home."
			return ""
	return "That is not work anyone here does."


## The party that holds a field for `buyer_ref`: the player themselves, a villager's household.
static func _holder_ref(k, buyer_ref: String) -> String:
	if World.is_player_ref(buyer_ref):
		return buyer_ref
	var b: NPC = k._npc_of(buyer_ref)
	return World.hh_ref(b.household) if b != null and b.household >= 0 else ""


## Where a field's crop goes when it is cut for `buyer_ref` (CON-06: the crop stays the owner's): a villager household's pantry,
## the player's chest at home; null when there is none.
static func _crop_store(k, buyer_ref: String) -> Inventory:
	var w: World = k.w
	if World.is_player_ref(buyer_ref):
		var bp: PlayerState = w.player_for(buyer_ref)
		return bp.chest if bp != null and bp.home != "" and w.buildings.has(bp.home) else null
	var b: NPC = k._npc_of(buyer_ref)
	if b == null or b.household < 0 or b.household >= w.households.size():
		return null
	return w.households[b.household].pantry


## The ripe cells of field `plot_id` held for `buyer_ref`, in row order: the player's own cells (Farming) on it, or its household
## cells (FarmPlots).
static func ripe_cells(k, buyer_ref: String, plot_id: String) -> Array:
	var w: World = k.w
	var p: Dictionary = w.plot(plot_id)
	var out := []
	if p.is_empty():
		return out
	if World.is_player_ref(buyer_ref):
		var r := Rect2i(int(p.x), int(p.y), int(p.w), int(p.h))
		for c: Vector2i in w.farm.cells:
			if r.has_point(c) and str(w.farm.cells[c].state) == "ripe":
				out.append(c)
	elif w.farm_plots != null:
		for c: Vector2i in w.farm_plots.cells:
			if str(w.farm_plots.cells[c].plot) == plot_id and str(w.farm_plots.cells[c].state) == "ripe":
				out.append(c)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


## Cut one ripe cell for the buyer of harvest contract `c` into the owner's store by the farming work's own rule. The goods cut.
static func _cut(k, c: Dictionary, cell: Vector2i) -> Dictionary:
	var w: World = k.w
	if not ripe_cells(k, str(c.buyer), str(c.site.plot)).has(cell):
		return {}
	var store := _crop_store(k, str(c.buyer))
	if store == null:
		return {}
	var got: Dictionary = w.farm.harvest_into(cell, store) if World.is_player_ref(str(c.buyer)) else w.farm_plots.harvest(cell, store)
	if not got.is_empty():
		w.stat("service_harvest_cells")
	return got


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
		"harvest":
			var p: Dictionary = w.plot(str(c.site.get("plot", "")))
			return "harvest %d cells of %s field %s" % [int(c.qty), "your" if World.is_player_ref(c.buyer) else w.ref_name(c.buyer) + "'s",
					w.where(Rect2i(int(p.x), int(p.y), int(p.w), int(p.h))) if not p.is_empty() else "(gone)"]
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
		"harvest":
			# CON-06: no job board pays for cutting; the manor's mending wage a minute (its day labour) for a cell's minutes
			return harvest_minutes() * float(ManorWork.cfg("mend_wage")) / float(maxi(1, int(ManorWork.cfg("mend_minutes"))))
	return 1.0


## The game minutes cutting one cell takes (the player's harvest seconds at the game's clock, FarmPlots.task_minutes' rule).
static func harvest_minutes() -> float:
	return maxf(1.0, float(Farming.cfg().harvest_seconds) * float(GameData.b("game_minutes_per_second")))


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
			elif n.coins - w.reserve_of(n) + int(svc.get("advance", 0)) < fee:      # CON-03: a buyer's advance meets the fees
				out.why = "coins"
			else:
				var per := (float(Prospecting.cfg().sample_minutes) * Skills.value(n, "mining", "mine_time", 1.0) + float(Prospecting.cfg().assay.minutes)) \
						* float(cfg().get("overhead", 1.25)) + float(cfg().get("survey_walk_minutes", 60))
				out.rate = 1.0 / per
				out.cap = mini(mini(w.prospecting.samples_left(c), (n.coins - w.reserve_of(n) + int(svc.get("advance", 0))) / fee), Contracts._by_time(float(out.rate) * mins))
				out.cost = fee
				out.route = "service"
		"harvest":
			# CON-06: any able adult cuts by hand (no tool, no level); the field's ripe cells now are the work there is
			var ripe := ripe_cells(k, str(svc.get("buyer", "")), str(svc.get("site", {}).get("plot", ""))) if svc.has("buyer") else []
			if ripe.is_empty():
				out.why = "source"
			else:
				var per := CapabilityHook.time(harvest_minutes(), "farming", n) * float(cfg().get("overhead", 1.25)) + float(cfg().get("harvest_walk_minutes", 30)) / float(maxi(1, ripe.size()))
				out.rate = 1.0 / per
				out.cap = mini(ripe.size(), Contracts._by_time(float(out.rate) * mins))
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
		"harvest":
			return _plan_harvest(k, n, c)
	return false


## The act at the end of a villager's walk or work (NPCBrain act "svc_step").
static func step(k, n: NPC, c: Dictionary) -> bool:
	match str(c.service):
		"dig":
			return _step_dig(k, n, c)
		"survey":
			return _step_survey(k, n, c)
		"harvest":
			return _step_harvest(k, n, c)
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
	k._pay_units(c, 1, 1 if str(r.get("item", "")) == "stone" else 0)      # CON-04: a unit's result is stone brought up
	return true


static func _plan_harvest(k, n: NPC, c: Dictionary) -> bool:
	var w: World = k.w
	var b: NPCBrain = w.brain
	if Contracts.left(c) <= 0:
		return false
	var fp: FarmPlots = w.farm_plots
	for cell: Vector2i in ripe_cells(k, str(c.buyer), str(c.site.plot)):
		if fp != null and float(fp.busy.get(cell, -1.0)) >= float(w.minutes):
			continue                                    # a member of the household is on its way to cut it
		if fp != null:
			fp.busy[cell] = w.minutes + 180.0
		c.cell = [cell.x, cell.y]
		n.doing = "harvesting %s field" % ("the player's" if World.is_player_ref(c.buyer) else w.ref_name(c.buyer) + "'s")
		var stand: Vector2i = cell if not w.map.is_solid(cell) else b.beside(cell, n.cell())
		n.plan = [b.go(stand), b.work(CapabilityHook.time(harvest_minutes(), "farming", n), "svc_step", {"id": int(c.id)}, "gather", cell)]
		return true
	return false


static func _step_harvest(k, n: NPC, c: Dictionary) -> bool:
	var w: World = k.w
	if not c.has("cell") or Contracts.left(c) <= 0:
		return false
	var cell := Vector2i(int(c.cell[0]), int(c.cell[1]))
	c.erase("cell")
	if w.farm_plots != null:
		w.farm_plots.busy.erase(cell)
	if _cut(k, c, cell).is_empty():
		return false
	Skills.gain(n, "farming", Skills.action_xp("harvest"))       # Decision 2 (8): the work trains Farming, as a member's cutting does
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
		var a: NPC = w.prospecting.assayer_for(n, int(c.get("advance", 0)))
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
		var drawn := spend_advance(k, c, int(Prospecting.cfg().assay.fee))     # CON-03: the advance meets this assay's fee
		for o: NPC in (w.npcs if a == null and drawn > 0 else []):
			if o.alive and o.job == "smith" and n.pos.distance_to(o.pos) <= 3.5 and pr.assayer_refusal(n, o) == "":
				a = o
				break
		if a != null and str(pr.assay(n, a, int(pending[0])).result) == "ok":
			return true
		_undraw(k, c, drawn)
		if a != null:
			return false
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
	var found := 0
	for r in recs:
		if Contracts.left(c) - told <= 0:
			break
		if k.w.prospecting.share(r, str(c.buyer)):
			told += 1
			if str(r.get("ore", "")) != "":
				found += 1                         # CON-04: a reading's result is a trace of ore (a barren one is none)
	if told > 0:
		k._pay_units(c, told, found)
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
	var told := tell(k, c, recs)
	if told > 0:
		spend_advance(k, c, told * int(Prospecting.cfg().assay.fee))     # CON-03: the fees the player paid for these readings
	return told


## Decision 2 / CON-06: the player cuts ripe cell `cell` of the field they are hired to harvest (the farm target "contract_harvest",
## a timed action as the player's own harvest): the crop goes to the owner's store, the player earns the Farming experience the
## work trains and is paid the unit. Returns the line to show.
static func player_harvest(k, c: Dictionary, cell: Vector2i, actor: PlayerState = null) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if k.w.mirrors():
		return k.w.mirror("ContractServices:player_harvest", player_harvest.bind(k, c, cell), [c, cell])
	if actor != null and actor != k.w.player:
		return k.w.as_actor(actor, player_harvest.bind(k, c, cell))
	if not Contracts.is_open(c) or str(c.get("service", "")) != "harvest" or not k.w.is_acting_ref(str(c.seller)) or Contracts.left(c) <= 0:
		return "You are not hired to harvest that."
	var got := _cut(k, c, cell)
	if got.is_empty():
		return "Nothing there is ripe to cut, or the store is full."
	k.w.player_xp("farming", Skills.action_xp("harvest"))
	k._pay_units(c, 1)
	return "You cut %s for %s." % [", ".join(got.keys().map(func(id): return "%d %s" % [int(got[id]), GameData.item_name(str(id)).to_lower()])), k.w.ref_name(str(c.buyer))]


## The player's open harvest contract (as the hired hand) covering ripe cell `cell`, or {}.
static func harvest_for_player(k, cell: Vector2i) -> Dictionary:
	for c in k.open_of(k.w.acting_ref(), "seller"):
		if str(c.get("service", "")) == "harvest" and Contracts.left(c) > 0 and ripe_cells(k, str(c.buyer), str(c.site.plot)).has(cell):
			return c
	return {}


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
	for p in w.plots:
		if w.holds(buyer_ref, p) and not ripe_cells(k, buyer_ref, str(p.id)).is_empty():
			out.append({"service": "harvest", "site": {"plot": str(p.id)}, "label": "Harvest your field %s" % w.where(Rect2i(int(p.x), int(p.y), int(p.w), int(p.h)))})
	var at: Vector2 = w.player.pos
	var cl := w.prospecting.clues.filter(func(c): return w.prospecting.samples_left(c) > 0)
	cl.sort_custom(func(a, b): return at.distance_to(Vector2(int(a.x), int(a.y))) < at.distance_to(Vector2(int(b.x), int(b.y))) \
			or (at.distance_to(Vector2(int(a.x), int(a.y))) == at.distance_to(Vector2(int(b.x), int(b.y))) and str(a.id) < str(b.id)))
	for c in cl.slice(0, int(cfg().get("survey_options", 3))):
		out.append({"service": "survey", "site": {"clue": str(c.id)}, "label": "Survey %s %s" % [w.prospecting.stain(c), w.prospecting.place(c)]})
	return out


# ---------------------------------------------------------------- Decision 2 / CON-03..CON-08: terms ---
## The terms in words, for the contract window: "at 6 a unit", "6 for each result", "held back 25% until done".
static func terms_words(terms: Dictionary, price_each: int) -> String:
	var t := ""
	match str(terms.get("pay", "on_delivery")):
		"on_result":
			t = "%d for each unit with a result, nothing for the rest" % price_each
		"base_bonus":
			t = "%d a unit and %d more for each result" % [price_each, int(terms.get("bonus_each", 0))]
		"favour":
			return "as a favour, nothing paid"
		_:
			t = "at %d a unit" % price_each
	if float(terms.get("retain", 0.0)) > 0.0:
		t += ", %d%% held back until it is all done" % roundi(100.0 * float(terms.retain))
	var adv = terms.get("advance", {})
	if adv is Dictionary and int(adv.get("amount", 0)) > 0:
		t += ", %d coins advanced for the assay fees" % int(adv.amount)
	return t


## A line on what the chosen pay means for the buyer, for the contract window.
static func terms_help(terms: Dictionary) -> String:
	match str(terms.get("pay", "on_delivery")):
		"on_result":
			return "Paid only for units that bring something: stone from a dig, a trace of ore from a reading. A worker asks more a unit for the risk; a barren one pays nothing."
		"base_bonus":
			return "Each unit is paid, and each one that brings something earns the bonus too. The most it could cost is set aside."
		"favour":
			return "Nothing is paid. Only a friend, partner or kin does work for nothing, and only when they can spare the time."
	return "Each unit of work is paid as it is done, from the coins set aside."

## Why these terms cannot be offered for this work ("" if they can): a known pay structure; a result only where the work has a
## verifiable one; a bonus with base_bonus; a retention within retain_max; an advance only for a named expense of the kind and no
## more than that expense could come to (CON-03: no unrestricted transfer disguised as an advance); a favour asks for nothing and
## carries no money terms. Goods contracts take no service terms.
static func terms_refusal(svc: Dictionary, qty: int, price_each: int, terms: Dictionary) -> String:
	if terms.is_empty():
		return ""
	var pay := str(terms.get("pay", "on_delivery"))
	if svc.is_empty():
		return "" if pay == "on_delivery" and float(terms.get("retain", 0.0)) <= 0.0 and int((terms.get("advance", {}) as Dictionary).get("amount", 0)) <= 0 \
				and int(terms.get("bonus_each", 0)) <= 0 else "Goods are paid for as they are handed over."
	if not PAYS.has(pay):
		return "That's no way to pay for work."
	var kind := str(svc.get("service", ""))
	var adv: Dictionary = terms.get("advance", {}) if terms.get("advance", {}) is Dictionary else {}
	if pay == "favour":
		if price_each != 0 or float(terms.get("retain", 0.0)) > 0.0 or int(adv.get("amount", 0)) > 0 or int(terms.get("bonus_each", 0)) > 0:
			return "A favour is done for nothing: there is nothing to pay or hold back."
		return ""
	if pay in ["on_result", "base_bonus"] and kind == "harvest":
		return "Every cell cut is the work done: pay for the work."
	if pay == "base_bonus" and int(terms.get("bonus_each", 0)) <= 0:
		return "Name the bonus for each result."
	if pay != "base_bonus" and int(terms.get("bonus_each", 0)) > 0:
		return "A bonus goes with a base price."
	var retain := float(terms.get("retain", 0.0))
	if retain < 0.0 or retain > float(cfg().get("retain_max", 0.5)):
		return "No more than %d%% of the pay can be held back." % roundi(100.0 * float(cfg().get("retain_max", 0.5)))
	var amount := int(adv.get("amount", 0))
	if amount < 0:
		return "That's no kind of advance."
	if amount > 0:
		if str(adv.get("purpose", "")) != str(PURPOSES.get(kind, "")) or not PURPOSES.has(kind):
			return "An advance is only for a named expense of the work (a survey's assay fees)."
		if amount > qty * int(Prospecting.cfg().assay.fee):
			return "An advance cannot be more than the expense it is for (%d coins)." % (qty * int(Prospecting.cfg().assay.fee))
	return ""


## The terms of a service as kept on its record: only the known keys, typed.
static func clean_terms(terms: Dictionary) -> Dictionary:
	var out := {"pay": str(terms.get("pay", "on_delivery")) if PAYS.has(str(terms.get("pay", "on_delivery"))) else "on_delivery"}
	if int(terms.get("bonus_each", 0)) > 0:
		out.bonus_each = int(terms.bonus_each)
	if float(terms.get("retain", 0.0)) > 0.0:
		out.retain = float(terms.retain)
	var adv = terms.get("advance", {})
	if adv is Dictionary and int(adv.get("amount", 0)) > 0:
		out.advance = {"amount": int(adv.amount), "purpose": str(adv.get("purpose", ""))}
	return out


## A saved record's terms (older saves have none of the new keys: the default, paid as the work is done).
static func load_terms(t) -> Dictionary:
	var d: Dictionary = t if t is Dictionary else {}
	var out: Dictionary = d.duplicate(true)
	out.merge(clean_terms(d), true)
	for k in ["partial", "all_at_once"]:
		if out.has(k):
			out[k] = bool(out[k])
	if out.has("deposit"):
		out.deposit = int(out.deposit)
	return out


## CON-04: the price a unit must carry for the seller to expect its least price `least` under these terms. Paid for results only,
## the seller bears the risk that a unit has none, so it asks result_premium times as much (it never knows the ground better than
## the samples will show); with a base and a bonus it counts only the base (the bonus is not sure); a favour asks nothing.
static func price_needed(least: int, terms: Dictionary) -> int:
	match str(terms.get("pay", "on_delivery")):
		"on_result":
			return ceili(float(least) * float(cfg().get("result_premium", 2.0)))
		"favour":
			return 0
	return least


## CON-04: what `units` of work with `results` verifiable results earn under the contract's agreed pay structure.
static func pay_for(c: Dictionary, units: int, results: int) -> int:
	if not Contracts.is_service(c):
		return units * int(c.price_each)
	var t: Dictionary = c.get("terms", {})
	match str(t.get("pay", "on_delivery")):
		"on_result":
			return results * int(c.price_each)
		"base_bonus":
			return units * int(c.price_each) + results * int(t.get("bonus_each", 0))
		"favour":
			return 0
	return units * int(c.price_each)


## CON-05: the part of `pay` held back until the work is complete (whole coins, rounded down).
static func hold_of(c: Dictionary, pay: int) -> int:
	if not Contracts.is_service(c):
		return 0
	return mini(pay, floori(float(pay) * float((c.get("terms", {}) as Dictionary).get("retain", 0.0))))


## CON-03: draw up to `amount` of the contract's advance for its named expense, paid to the seller as it meets it (an assay's
## fee). Recorded on the contract's history; never more than is left of the advance. Returns the coins drawn.
static func spend_advance(k, c: Dictionary, amount: int) -> int:
	var d := mini(amount, int(c.get("advance", 0)))
	if d <= 0 or not Contracts.is_open(c):
		return 0
	c.advance = int(c.advance) - d
	c.reserved = int(c.reserved) - d
	c.advance_spent = int(c.get("advance_spent", 0)) + d
	k._add_coins(str(c.seller), d)
	c.history.append({"day": k.w.day(), "by": str(c.seller), "what": "advance", "qty": d, "price_each": 0, "days": 0,
		"purpose": str((c.terms.get("advance", {}) as Dictionary).get("purpose", ""))})
	k.w.stat("service_advance_spent", d)
	if k.w.recorder != null:
		k.w.recorder.contract_settled(c, "advance", d, str(c.seller), k._coins(str(c.seller)))
	return d


## An advance drawn for an expense that was not met after all goes back into the contract (the seller still holds the coins).
static func _undraw(k, c: Dictionary, d: int) -> void:
	if d <= 0:
		return
	k._add_coins(str(c.seller), -d)
	c.advance = int(c.advance) + d
	c.reserved = int(c.reserved) + d
	c.advance_spent = int(c.get("advance_spent", 0)) - d
	c.history.pop_back()
	k.w.stat("service_advance_spent", -d)
	if k.w.recorder != null:
		k.w.recorder.contract_settled(c, "advance_back", -d, str(c.seller), k._coins(str(c.seller)))


## CON-05: the reeve's ruling on a retention in dispute, from the agreement and the contract's own records only ({to, why}):
##  - the work was complete (every unit done): the seller (the retention was earned);
##  - a party died: the seller for work verifiably done (nobody broke the agreement), the buyer if none was done;
##  - the buyer ended it early: the seller (the work done was done to the agreement);
##  - the seller ended it, or let the deadline pass with work that could still be done: the buyer (the remedy for the breach);
##  - the deadline passed because the buyer's site had no work left to do (the pit dug out, nothing ripe, no stain): the seller.
## Either party may prevail; nothing is confiscated: the coins go to one of the two.
static func ruling(k, c: Dictionary) -> Dictionary:
	var buyer := str(c.buyer)
	var seller := str(c.seller)
	var hist: Array = c.get("history", [])
	var last: Dictionary = hist[-1] if not hist.is_empty() else {}
	if int(c.delivered) >= int(c.qty):
		return {"to": seller, "why": "the work was all done"}
	if str(c.get("why", "")).ends_with("died"):
		return {"to": seller, "why": "the work done was done, and death broke no promise"} if int(c.delivered) > 0 else {"to": buyer, "why": "no work was done"}
	if str(last.get("what", "")) == "cancel":
		return {"to": seller, "why": "the buyer ended it with the work done to the agreement"} if str(last.by) == buyer \
				else {"to": buyer, "why": "the worker gave up the work unfinished"}
	if str(c.state) == "lapsed":
		return {"to": seller, "why": "there was no more work to be done on the buyer's ground"} if not workable(k, c) \
				else {"to": buyer, "why": "the work was not finished by the deadline"}
	return {"to": buyer, "why": "the work was not finished"}


## Whether the contract's site still has work the seller could do (CON-05's evidence for a lapse).
static func workable(k, c: Dictionary) -> bool:
	var w: World = k.w
	match str(c.get("service", "")):
		"dig":
			var p := w.pits.pit(int(c.site.get("pit", -1)))
			return not p.is_empty() and remaining(p) > 0
		"survey":
			var cl := w.prospecting.clue(str(c.site.get("clue", "")))
			return not cl.is_empty() and w.prospecting.samples_left(cl) > 0
		"harvest":
			return not ripe_cells(k, str(c.buyer), str(c.site.get("plot", ""))).is_empty()
	return false


## Decision 2: whether `n` will do this work for `buyer_ref` for nothing ("" if it will): only for a friend, partner or kin (the
## ties that already get a friend's price, Contracts.close_to), never for the manor, not while its own household is short of its
## reserve, not with another favour already promised, and, with judgment attached, not for one it will not deal with.
static func favour_refusal(k, n: NPC, buyer_ref: String) -> String:
	var w: World = k.w
	var rid: int = Contracts.rel_id(buyer_ref)
	if rid == -1:
		return "The manor's work is paid work."
	if not k.close_to(n, rid):
		return "I'd do it for pay, but not for nothing."
	if n.coins < w.reserve_of(n):
		return "I can't give my time away just now; my household needs what I earn."
	for c in k.open_of(World.npc_ref(n.id), "seller"):
		if str((c.get("terms", {}) as Dictionary).get("pay", "")) == "favour":
			return "I've a favour promised already; ask me when it's done."
	if w.judgment != null and JudgmentLive.on(w, "contract_accept"):        # PROSPECTIVE (PROS-19, Q14): off unless judgment is attached
		var no := JudgmentLive.contract_refusal(w, n, buyer_ref)
		if no != "":
			return no
	return ""


## A service contract opened (its coins set aside): counted by kind and pay structure.
static func on_open(k, c: Dictionary) -> void:
	k.w.stat("service_contracts_made_" + str(c.service))
	var pay := str((c.get("terms", {}) as Dictionary).get("pay", "on_delivery"))
	if pay != "on_delivery":
		k.w.stat("service_pay_" + pay)
	if Contracts.formal_of(Contracts.set_aside(c), Contracts.svc_of(c)):
		k.w.stat("service_contracts_formal")
	else:
		k.w.stat("service_contracts_informal")


## A service done in full (Decision 2 (10): repeat work and reputation): the buyer remembers who served it well (npc_hire asks them
## first), and a favour done earns the regard of a help given.
static func on_fulfilled(k, c: Dictionary) -> void:
	var w: World = k.w
	w.stat("services_completed")
	w.stat("services_completed_" + str(c.service))
	var b: NPC = k._npc_of(str(c.buyer))
	if b != null:
		b.remember("well served by %s, who did %s" % [w.ref_name(str(c.seller)), k.describe(c)])
	if str((c.get("terms", {}) as Dictionary).get("pay", "")) == "favour":
		w.stat("service_favours_done")
		var rid: int = Contracts.rel_id(str(c.seller))
		if b != null and rid != -1:
			w.relations.helped(rid, b, float(Relations.cfg().help_regard) * 0.5)


## Whether `seller_ref` has done a service in full for `buyer_ref` still on record (keep_days): the one to ask again.
static func served(k, buyer_ref: String, seller_ref: String) -> bool:
	return k.list.any(func(c): return Contracts.is_service(c) and str(c.state) == "fulfilled" and str(c.buyer) == buyer_ref and str(c.seller) == seller_ref)


# ---------------------------------------------------------------- CON-07: villagers hiring -------
## CON-07 (CON02-S-5): each dawn, villagers with a genuine need for work they cannot practically do themselves look for someone to do
## it, through the one engine (propose, evaluate, buyer_answer). Phased by industry (the directive): agriculture first (CON-06),
## since the mining and survey work the game performs is done for pits and stains villagers do not own. No demand is made up, no
## worker is sure to be found, nothing is accepted for them: each step is the eight questions, in _hire_harvest. At most
## hire_per_day new hirings a dawn; balance contracts.services.npc_hire false switches it off.
static func npc_hire(k) -> void:
	if not bool(cfg().get("npc_hire", true)) or k.w.farm_plots == null:
		return
	var made := 0
	for b: NPC in k.w.npcs:
		if made >= int(cfg().get("hire_per_day", 2)):
			return
		if _hire_harvest(k, b):
			made += 1


## One villager's weighing of hiring help to cut its household's ripe field (the eight questions of CON02-S-5, in order):
##  1 need: ripe cells on a plot its household holds; 2 own hands: more ripe cells than the household's able members can cut in
##  hire_days of the time their days leave (FarmPlots.free_minutes); 3 worth it: the crop of the cells it hires for is worth more
##  than their pay at the going rate; 4 affordable: its coins above its reserve set aside for it (fund_refusal); 5 a worker: a
##  villager outside the household who can and will (asked in turn: one who served it before first); 6 terms: the worker's answer
##  and buyer_answer on a counter; 7 feasible: the worker's own means by the deadline (evaluate); 8 obligations: no other hiring of
##  its own open or offered, and none already for that field. With no villager willing, the work is offered to the player.
static func _hire_harvest(k, b: NPC) -> bool:
	var w: World = k.w
	if not b.alive or b.role != "adult" or b.household < 0:
		return false
	var me := World.npc_ref(b.id)
	if not k.open_of(me, "buyer").is_empty() or k._offered_by(b):
		return false                                                       # 8: its own hiring already in hand
	var members: Array = w.brain._members(b.household)
	members.sort_custom(func(x: NPC, y: NPC) -> bool: return x.id < y.id)
	var first: NPC = null
	for o: NPC in members:
		if o.alive and o.role == "adult":
			first = o
			break
	if first != b:
		return false                                                       # one voice for the household: its first adult
	var hh := World.hh_ref(b.household)
	var days := int(cfg().get("hire_days", 2))
	for p in w.farm_plots.plots_of(hh):
		if FarmPlots.is_church(p) or k.list.any(func(c): return Contracts.is_service(c) and str(c.service) == "harvest" and str(c.site.get("plot", "")) == str(p.id) \
				and str(c.state) in ["accepted", "offered", "signing"]):
			continue                                                       # 8: that field is already being seen to
		var ripe := ripe_cells(k, me, str(p.id))
		if ripe.is_empty():
			continue                                                       # 1: no need
		var own := floori(w.farm_plots.free_minutes(b.household) * float(days) / harvest_minutes())
		var need := ripe.size() - own
		if need <= 0:
			w.stat("service_hire_own_hands")
			continue                                                       # 2: the household can cut it itself
		var svc := {"service": "harvest", "site": {"plot": str(p.id)}}
		var price := maxi(1, ceili(going(svc)))
		var crop: Dictionary = Farming.crops().get(str(w.farm_plots.cells[ripe[0]].get("crop", "")), {})
		if crop.is_empty() or float(GameData.value(str(crop.item))) * float(crop.get("yield", 1)) <= float(price):
			w.stat("service_hire_not_worth")
			continue                                                       # 3: the pay would cost more than the crop is worth
		var qty := need
		while qty > 0 and k.fund_refusal(me, qty * price) != "":
			qty -= 1
		if qty <= 0:
			w.stat("service_hire_cannot_afford")
			continue                                                       # 4: it cannot set the coins aside
		w.stat("service_hire_sought")
		var sellers := []
		for s: NPC in w.npcs:
			if s.alive and s.role == "adult" and s.household != b.household:
				sellers.append(s)
		sellers.sort_custom(func(x: NPC, y: NPC) -> bool:
			var sx := served(k, me, World.npc_ref(x.id))
			var sy := served(k, me, World.npc_ref(y.id))
			return sx and not sy or (sx == sy and x.id < y.id))
		for s: NPC in sellers.slice(0, int(cfg().get("hire_asks", 6))):  # 5: asked in turn, one it knows first
			var r: Dictionary = k.propose(me, s, "", qty, price, days, [], svc)
			if r.has("contract") or r.has("signing"):
				w.stat("service_hired")
				return true
			if str(r.get("answer", "")) == "counter" and str(k.buyer_answer(b, "", qty, price, 1, int(r.qty), int(r.price_each), int(r.days)).answer) == "accept":
				var a: Dictionary = k.propose(me, s, "", int(r.qty), int(r.price_each), int(r.days), r.get("history", []), svc)   # 6: a counter met
				if a.has("contract") or a.has("signing"):
					w.stat("service_hired")
					return true
		w.stat("service_hire_nobody")
		k.offer_to_player(b, "", qty, price, days, svc)                     # nobody here would: the player may take it up
		return true
	return false
