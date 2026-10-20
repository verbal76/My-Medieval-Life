class_name ManorWork
extends RefCounted
## The manor's work (owner, 2026-10-18): the reeve offers a choice of real jobs, made only by what the
## manor and the village actually need, to the player and to villagers by the same rules.
##
## Nothing here creates demand. The manor's existing evening business (NPCBrain.reeve_day) decides what
## it buys and gives, as before; what used to vanish or appear instantly now has to be carried or used:
##  - goods the manor buys (repairs and public works materials, grain for the granary, relief food) are
##    paid for at once and left as a *lot* where they were bought, the manor's, until carried to where
##    they go (the works yard, the granary, a household's pantry): "haul" jobs;
##  - relief grain is taken from the granary as a lot at the manor's door, for its household;
##  - materials in the works yard are used up mending the village's roads, bridges and well: "mend"
##    jobs, a load of `mend_load` materials and `mend_minutes` of work at a works site;
##  - stone for the works can be quarried from the village's own seams instead of bought: one "quarry"
##    job at a time, posted by the reeve while the manor can spend on repairs and its works lack stone.
## A household under a day of food is not left waiting: its relief is delivered at once, as before.
##
## Jobs are paid from the treasury, set aside when a job is taken (the treasury keeps
## `manor_job_reserve_days` of obligations after the wage) and paid when it is
## done; a job left undone is released at the next dawn after `manor_jobs.days`, its wage and goods
## back. Manor hands are already paid a day's wage: they take jobs unpaid. One job at a time per worker.
## Carried goods ride in the job's own load (never the worker's pack), so they cannot be sold, eaten or
## lost; a dead worker's load goes back. Every number is provisional — balance review pending.

const KINDS := ["haul", "quarry", "mend"]
const ORDER := ["pantry", "granary", "yard"]        # hauling priority by destination: relief first
const MATERIALS := ["plank", "stone", "log", "iron_bar"]

var w: World
var lots: Array = []          # {id, at: [x, y], inv: Inventory, to: {kind: yard|granary|pantry, hh}, why, src (where it lies, in words)}
var yard := Inventory.new()   # the manor's works yard (at the manor's door): materials for mending
var jobs: Array = []          # {id, kind, lot, qty, item, site: [x, y], wage, taker, day, reserved, load: Inventory}
var next_id := 1
var sites: Array = []         # works sites to mend: [cell, name], from the map; not saved
var last_refusal := ""        # why the last take() failed


func _init(world: World) -> void:
	w = world
	_find_sites()


static func cfg(key: String):
	return GameData.b("manor_jobs")[key]


## The village's works: the well and points along the roads, spread evenly (deterministic).
func _find_sites() -> void:
	sites.clear()
	for id in w.stations_of("well"):
		sites.append([w.station_use(id), "the well"])
	var road: Array = w.map.data.road
	var step := maxi(1, road.size() / 6)
	for i in range(step / 2, road.size(), step):
		var c := Vector2i(int(road[i][0]), int(road[i][1]))
		if not w.map.is_solid(c):
			sites.append([c, "the road " + w.where(Rect2i(c.x, c.y, 1, 1))])


# ---------------------------------------------------------------- places ---------------------
func yard_cell() -> Vector2i:
	return w.building_door(w.brain._manor_id())


func dest_cell(to: Dictionary) -> Vector2i:
	if str(to.kind) == "pantry":
		var hh: Dictionary = w.households[int(to.hh)]
		if str(hh.get("home", "")) != "" and w.buildings.has(str(hh.home)):
			return w.building_door(str(hh.home))
	return yard_cell()                  # the granary and the yard are at the manor


func dest_name(to: Dictionary) -> String:
	match str(to.kind):
		"granary":
			return "the manor's granary"
		"pantry":
			return "the %s family's house" % _family(int(to.hh))
	return "the manor's works yard"


func _family(h: int) -> String:
	for m in w.households[h].members:
		var o := w.npc(int(m))
		if o:
			return o.family
	return "empty"


func lot(id: int) -> Dictionary:
	for l in lots:
		if int(l.id) == id:
			return l
	return {}


func job(id: int) -> Dictionary:
	for j in jobs:
		if int(j.id) == id:
			return j
	return {}


# ---------------------------------------------------------------- what the manor needs moved ---
## The manor bought or set aside `qty` of `item` at `at`, to go to `to`: a lot, the manor's, until
## carried. Taken from `from` (a seller's stock, or the granary). Returns false if it is not there.
func consign(from: Inventory, at: Vector2i, item: String, qty: int, to: Dictionary, why: String, src: String) -> bool:
	if qty <= 0 or from.count(item) < qty:
		return false
	var l := {}
	for o in lots:
		if int(o.at[0]) == at.x and int(o.at[1]) == at.y and JSON.stringify(o.to) == JSON.stringify(to):
			l = o
			break
	if l.is_empty():
		l = {"id": next_id, "at": [at.x, at.y], "inv": Inventory.new(), "to": to, "why": why, "src": src}
		next_id += 1
		lots.append(l)
	w.transfer(from, l.inv, item, qty)
	return true


## How much of `id` the manor has on its way to a destination kind (in lots and job loads).
func bound(kind: String, id: String) -> int:
	var n := 0
	for l in lots:
		if str(l.to.kind) == kind:
			n += l.inv.count(id)
	for j in jobs:
		if j.kind == "haul" and str(j.to.kind) == kind:
			n += j.load.count(id)
	return n


## An emergency: up to `qty` of `id` the manor has waiting for one destination kind (grain bought for
## the granary, still at the farmer's) goes straight into `into`. Returns how many.
func take_bound(kind: String, id: String, qty: int, into: Inventory) -> int:
	var got := 0
	for l in lots.duplicate():
		if got >= qty or str(l.to.kind) != kind:
			continue
		var c := mini(qty - got, l.inv.count(id))
		if c > 0 and w.transfer(l.inv, into, id, c):
			got += c
	refresh()
	return got


## Goods waiting in lots for this household (relief on its way).
func pending_for(h: int) -> int:
	var n := 0
	for l in lots:
		if str(l.to.kind) == "pantry" and int(l.to.hh) == h:
			n += l.inv.total()
	for j in jobs:
		if j.kind == "haul" and str(j.to.kind) == "pantry" and int(j.to.hh) == h:
			n += j.load.total()
	return n


## An emergency: a household's relief still on its way is delivered at once by the manor's own people.
func deliver_now(h: int) -> void:
	for j in jobs.duplicate():
		if j.kind == "haul" and str(j.to.kind) == "pantry" and int(j.to.hh) == h:
			release(j)
			jobs.erase(j)
	for l in lots.duplicate():
		if str(l.to.kind) == "pantry" and int(l.to.hh) == h:
			_unload(l.inv, l.to)
			lots.erase(l)
	refresh()


func _unload(inv: Inventory, to: Dictionary) -> void:
	var into: Inventory = yard
	match str(to.kind):
		"granary":
			into = w.granary
		"pantry":
			into = w.households[int(to.hh)].pantry
	for id in inv.ids():
		w.transfer(inv, into, id, inv.count(id))


## Post the jobs the manor's goods need: a haul for each part of a lot not yet covered (up to
## `haul_max` a trip), and a mend for each `mend_load` in the yard not yet claimed. No other job is
## ever posted here.
func refresh() -> void:
	# a lot emptied another way (an emergency took from it) drops the jobs it no longer needs
	for l in lots.duplicate():
		var covered := 0
		for j in jobs.duplicate():
			if int(j.get("lot", -1)) == int(l.id) and j.taker == "":
				if covered + int(j.qty) > l.inv.total():
					jobs.erase(j)
				else:
					covered += int(j.qty)
		if l.inv.total() == 0 and not jobs.any(func(j): return int(j.get("lot", -1)) == int(l.id)):
			lots.erase(l)
	for l in lots:
		var covered := 0
		for j in jobs:
			if int(j.get("lot", -1)) == int(l.id):
				covered += int(j.qty)
		var left: int = l.inv.total() - covered
		while left > 0:
			var q := mini(left, int(cfg("haul_max")))
			_post({"kind": "haul", "lot": int(l.id), "qty": q, "to": l.to.duplicate(), "src": str(l.src), "at": l.at.duplicate(), "wage": int(cfg("haul_wage"))})
			left -= q
	# a mend that has not yet taken its load from the yard claims it
	var claimed := 0
	for j in jobs:
		if j.kind == "mend" and j.load.total() == 0:
			claimed += int(cfg("mend_load"))
	var free := yard.total() - claimed
	while free >= int(cfg("mend_load")) and not sites.is_empty():
		var site: Array = sites[next_id % sites.size()]
		_post({"kind": "mend", "qty": int(cfg("mend_load")), "site": [site[0].x, site[0].y], "place": site[1], "wage": int(cfg("mend_wage"))})
		free -= int(cfg("mend_load"))


func _post(j: Dictionary) -> void:
	j.id = next_id
	next_id += 1
	j.taker = ""
	j.day = -1
	j.reserved = 0
	j.load = Inventory.new()
	jobs.append(j)


## The reeve's evening: stone for the works from the village's own seams (one job at a time), while
## the manor is spending on repairs and its yard and lots hold too little stone to mend with.
func post_quarry() -> void:
	if jobs.any(func(j): return j.kind == "quarry"):
		return
	if w.quests.deposit_left("stone") < int(cfg("quarry_qty")):
		return
	if _works_stock("stone") >= 2 * int(cfg("mend_load")):
		return
	_post({"kind": "quarry", "item": "stone", "qty": int(cfg("quarry_qty")), "wage": int(cfg("quarry_wage"))})


## Materials for the works the manor already holds or has bought: the yard and lots bound for it.
func _works_stock(id := "") -> int:
	var n := yard.count(id) if id != "" else yard.total()
	for l in lots:
		if str(l.to.kind) == "yard":
			n += l.inv.count(id) if id != "" else l.inv.total()
	for j in jobs:
		if j.kind == "haul" and str(j.to.kind) == "yard":
			n += j.load.count(id) if id != "" else j.load.total()
	return n


## Whether the manor still wants materials for its works: it buys no more while it holds
## `works_stock_max` it has not yet used.
func works_want() -> bool:
	return _works_stock() < int(cfg("works_stock_max"))


# ---------------------------------------------------------------- taking and doing a job -----
## Who is doing a job: "player" or World.npc_ref(id).
func job_of(who: String) -> Dictionary:
	for j in jobs:
		if j.taker == who:
			return j
	return {}


func is_staff(who: String) -> bool:
	if not who.begins_with("npc:"):
		return false
	var n := w.npc(int(who.substr(4)))
	return n != null and n.job == "manor_hand"


## Whether the treasury can set this wage aside (manor hands are already paid: no wage). A day's job
## is a small, short promise: it keeps `manor_job_reserve_days` of obligations after the wage, the
## same line the evening's repairs are bought above (B7-009; the 10 days stay for hiring staff). The
## treasury starts at 270, under the 460 that ten days need, so with the long reserve no paid work
## existed until about day 12.
func can_fund(j: Dictionary, who: String) -> bool:
	if is_staff(who):
		return true
	return w.treasury - int(j.wage) >= w.brain.daily_obligations() * float(GameData.b("manor_job_reserve_days"))


## The jobs open to this worker now, most needed first (relief, the granary, the yard, mending,
## quarrying); a quarry needs a pickaxe.
func open_for(who: String) -> Array:
	var out := []
	for j in jobs:
		if j.taker != "" or not can_fund(j, who):
			continue
		if j.kind == "quarry" and not _has_pick(who):
			continue
		out.append(j)
	out.sort_custom(func(a, b): return _rank(a) < _rank(b) or (_rank(a) == _rank(b) and int(a.id) < int(b.id)))
	return out


func _rank(j: Dictionary) -> int:
	if j.kind == "haul":
		return ORDER.find(str(j.to.kind))
	return 3 if j.kind == "mend" else 4


func _has_pick(who: String) -> bool:
	if who == "player":
		return w.player.tool_of("pickaxe") != ""
	var n := w.npc(int(who.substr(4)))
	return n != null and n.inv.has("pickaxe")


## Take a job: its wage is set aside from the treasury. False (with last_refusal) if it cannot be.
func take(j: Dictionary, who: String) -> bool:
	last_refusal = ""
	if not job_of(who).is_empty():
		last_refusal = "You are already doing work for the manor."
		return false
	if j.is_empty() or j.taker != "":
		last_refusal = "Someone else has taken that work."
		return false
	if not can_fund(j, who):
		last_refusal = "The manor's chest can't spare that wage today."
		return false
	j.reserved = 0 if is_staff(who) else int(j.wage)
	w.treasury -= int(j.reserved)
	j.taker = who
	j.day = w.day()
	w.stat("manor_jobs_taken")
	return true


## Give a job up: the wage back to the treasury, what it carried back where it came from (a quarry's
## stone to the yard). The job stays posted for someone else.
func release(j: Dictionary) -> void:
	w.treasury += int(j.reserved)
	j.reserved = 0
	if j.load.total() > 0:
		match str(j.kind):
			"haul":
				var l := lot(int(j.lot))
				if l.is_empty():
					l = {"id": int(j.lot), "at": j.at.duplicate(), "inv": Inventory.new(), "to": j.to.duplicate(), "why": "returned", "src": str(j.src)}
					lots.append(l)
				for id in j.load.ids():
					w.transfer(j.load, l.inv, id, j.load.count(id))
			_:
				for id in j.load.ids():
					w.transfer(j.load, yard, id, j.load.count(id))
	j.taker = ""
	j.day = -1
	if j.kind == "quarry":
		jobs.erase(j)              # the reeve posts it again when the works still lack stone


## The next thing a job needs: "take" (at the lot or the yard), "mine" (a quarry short of stone),
## "put" (at its destination), "mend" (at its site).
func step(j: Dictionary) -> String:
	match str(j.kind):
		"haul":
			return "take" if j.load.total() == 0 else "put"
		"quarry":
			return "mine" if j.load.count("stone") < int(j.qty) and j.taker != "player" else "put"
		"mend":
			return "take" if j.load.total() == 0 else "mend"
	return ""


## Where the next step is done.
func step_cell(j: Dictionary) -> Vector2i:
	match step(j):
		"take":
			if j.kind == "haul":
				return Vector2i(int(j.at[0]), int(j.at[1]))
			return yard_cell()
		"put":
			if j.kind == "haul":
				return dest_cell(j.to)
			return yard_cell()
		"mend":
			return Vector2i(int(j.site[0]), int(j.site[1]))
	return yard_cell()


## The job in words, for the reeve's list and the journal.
func describe(j: Dictionary) -> String:
	match str(j.kind):
		"haul":
			var l := lot(int(j.lot))
			var what := _goods_words(j.load if j.load.total() > 0 or l.is_empty() else l.inv, int(j.qty))
			return "Carry %s from %s to %s" % [what, str(j.src), dest_name(j.to)]
		"quarry":
			return "Quarry %d stone for the manor's works and bring it to the works yard" % int(j.qty)
		"mend":
			return "Mend %s with %d loads of materials from the works yard (%d hours)" % [str(j.get("place", "the road")), int(j.qty), roundi(float(cfg("mend_minutes")) / 60.0)]
	return ""


## "10 planks", "6 wheat", "1 iron bar": counted goods in words.
static func count_words(id: String, c: int) -> String:
	var name := GameData.item_name(id).to_lower()
	if c != 1 and id in ["plank", "log", "iron_bar", "copper_bar", "gold_bar", "hide"]:
		name += "s"
	return "%d %s" % [c, name]


func _goods_words(inv: Inventory, most: int) -> String:
	var parts := []
	var left := most
	for id in inv.ids():
		var c := mini(inv.count(id), left)
		if c > 0:
			parts.append(count_words(id, c))
			left -= c
	return " and ".join(parts) if not parts.is_empty() else "the goods"


## Do the next step for this worker, where they stand. Returns true when the step was done; a
## finished job pays its wage.
func do_step(j: Dictionary, who: String, pack: Inventory) -> bool:
	match step(j):
		"take":
			if j.kind == "haul":
				var l := lot(int(j.lot))
				if l.is_empty():
					release(j)
					jobs.erase(j)
					return false
				var want := int(j.qty)
				for id in l.inv.ids():
					var c := mini(want, l.inv.count(id))
					w.transfer(l.inv, j.load, id, c)
					want -= c
					if want <= 0:
						break
				if l.inv.total() == 0:
					lots.erase(l)
				return j.load.total() > 0
			# mend: a load of materials from the yard, the most plentiful first
			var want := int(cfg("mend_load"))
			while want > 0 and yard.total() > 0:
				var best := ""
				for id in yard.ids():
					if best == "" or yard.count(id) > yard.count(best):
						best = id
				w.transfer(yard, j.load, best, 1)
				want -= 1
			return j.load.total() > 0
		"put":
			if j.kind == "haul":
				_unload(j.load, j.to)
				_finish(j, who)
				return true
			# quarry: the stone goes into the yard (the player brings it in their pack)
			if who == "player":
				if pack.count("stone") < int(j.qty):
					return false
				w.transfer(pack, yard, "stone", int(j.qty))
				w.player.trim_stolen()
			else:
				w.transfer(j.load, yard, "stone", j.load.count("stone"))
			_finish(j, who)
			return true
		"mend":
			for id in j.load.ids():
				w.stat("used_repairs_" + id, j.load.count(id))
			j.load = Inventory.new()
			w.stat("works_mended")
			_finish(j, who)
			return true
	return false


## A villager quarrying: one unit from the nearest stone seam into the job's load.
func mine_into(j: Dictionary, n: NPC, dep: Dictionary) -> bool:
	var r := w.work_mine(n, dep, j.load)                    # the player's swing (PAR-01)
	if r.result != "ok":
		return false
	if r.broke:
		w.note("%s %s's pickaxe broke." % [n.name, n.family])
	return true


func _finish(j: Dictionary, who: String) -> void:
	var pay := int(j.reserved)
	j.reserved = 0
	if who == "player":
		w.player.coins += pay
	else:
		var n := w.npc(int(who.substr(4)))
		if n:
			n.coins += pay
			n.earned += pay
	w.stat("gov_wages", pay)
	w.stat("gov_manor_jobs", pay)
	w.stat("manor_jobs_done")
	w.stat("manor_job_" + str(j.kind))
	jobs.erase(j)
	refresh()


## Dawn: work taken more than `days` ago and not done is released for someone else.
func dawn() -> void:
	for j in jobs.duplicate():
		if j.taker != "" and w.day() - int(j.day) >= int(cfg("days")):
			var who: String = j.taker
			release(j)
			if who == "player":
				w.note("Your work for the manor lapsed: \"%s\" was not done in time." % describe(j))
	refresh()


func on_death(n: NPC) -> void:
	var j := job_of(World.npc_ref(n.id))
	if not j.is_empty():
		release(j)


## The player died: their job goes back.
func release_player() -> void:
	var j := job_of("player")
	if not j.is_empty():
		release(j)


# ---------------------------------------------------------------- villagers -----------------
## A villager doing a manor job plans its next step. False if there is none to plan.
func plan(n: NPC) -> bool:
	var who := World.npc_ref(n.id)
	var j := job_of(who)
	if j.is_empty():
		return false
	var b: NPCBrain = w.brain
	n.doing = "working for the manor"
	match step(j):
		"mine":
			if not n.inv.has("pickaxe"):
				release(j)
				return false
			var d: Dictionary = w.nearest_deposit(n.cell(), ["stone"])
			if d.is_empty():
				release(j)
				return false
			var at := Vector2i(d.x, d.y)
			n.plan = [b.go(b.beside(at, n.cell())), b.work(float(GameData.b("mine_minutes")) * Skills.value(n, "mining", "mine_time", 1.0), "mj_mine", {"job": int(j.id), "x": d.x, "y": d.y}, "work", at)]
		"mend":
			var at := step_cell(j)
			n.plan = [b.go(b.beside(at, n.cell())), b.work(float(cfg("mend_minutes")), "mj_step", {"job": int(j.id)}, "work", at)]
		_:
			n.plan = [b.go(b.beside(step_cell(j), n.cell())), b.doit("mj_step", {"job": int(j.id)})]
	return true


## A villager looking for the manor's work takes the most needed open job they can do.
func seek(n: NPC) -> bool:
	var who := World.npc_ref(n.id)
	var open := open_for(who)
	if open.is_empty() or not take(open[0], who):
		return false
	return plan(n)


func act(n: NPC, what: String, a: Dictionary) -> bool:
	var j := job(int(a.get("job", -1)))
	if j.is_empty() or j.taker != World.npc_ref(n.id):
		return true
	if what == "mj_mine":
		var d: Dictionary = w.deposit_at(Vector2i(int(a.x), int(a.y)))
		if d.is_empty() or not mine_into(j, n, d):
			return true             # the seam is gone: the next plan finds another
		return true
	do_step(j, World.npc_ref(n.id), n.inv)
	return true


# ---------------------------------------------------------------- accounts and saving --------
## Goods the manor holds in lots, the yard and job loads (the goods census counts them).
func goods() -> Dictionary:
	var out := {}
	var add := func(inv: Inventory) -> void:
		for id in inv.ids():
			out[id] = int(out.get(id, 0)) + inv.count(id)
	for l in lots:
		add.call(l.inv)
	add.call(yard)
	for j in jobs:
		add.call(j.load)
	return out


func food_points() -> float:
	var p := 0.0
	var g := goods()
	for f in NPCBrain.FOOD:
		p += int(g.get(f, 0)) * float(GameData.item(f).food)
	return p


## Wages set aside for jobs taken (counted in World.total_coins).
func reserved_total() -> int:
	var t := 0
	for j in jobs:
		t += int(j.reserved)
	return t


func to_dict() -> Dictionary:
	var ls := []
	for l in lots:
		ls.append({"id": l.id, "at": l.at, "inv": l.inv.to_dict(), "to": l.to, "why": l.why, "src": l.src})
	var js := []
	for j in jobs:
		var d: Dictionary = j.duplicate()
		d.load = j.load.to_dict()
		js.append(d)
	return {"lots": ls, "yard": yard.to_dict(), "jobs": js, "next_id": next_id}


func load_dict(d: Dictionary) -> void:
	lots.clear()
	jobs.clear()
	for l in d.get("lots", []):
		var to: Dictionary = l.to.duplicate()
		if to.has("hh"):
			to.hh = int(to.hh)
		lots.append({"id": int(l.id), "at": [int(l.at[0]), int(l.at[1])], "inv": Inventory.from_dict(l.inv), "to": to, "why": str(l.why), "src": str(l.get("src", "the manor's door"))})
	yard = Inventory.from_dict(d.get("yard", {}))
	for jd in d.get("jobs", []):
		var j: Dictionary = jd.duplicate()
		for k in ["id", "lot", "qty", "wage", "day", "reserved"]:
			if j.has(k):
				j[k] = int(j[k])
		for k in ["site", "at"]:
			if j.has(k):
				j[k] = [int(j[k][0]), int(j[k][1])]
		if j.has("to") and j.to.has("hh"):
			j.to.hh = int(j.to.hh)
		j.load = Inventory.from_dict(jd.get("load", {}))
		jobs.append(j)
	next_id = int(d.get("next_id", 1))
