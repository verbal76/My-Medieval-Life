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
##    job at a time, posted by the reeve while the manor can spend on repairs and its works lack stone;
##  - MIN-D (Discovery): the manor commissions prospecting as ordinary work: one "survey" at a time (take
##    `survey_samples` rock samples of a clue it has heard nothing of with one's own kit, have them assayed at a
##    smith's forge, paying the fees from the wage, and report the readings at the manor), and once its mining
##    capability allows, one "trial" pit at a time for the best find it knows (Discovery.trial_dig, a shovel: MIN-E-Q4).
##    Both are paid for the labour, whatever is found. Manor hands take no surveys (their wage is their pay, and
##    the assay fees are the worker's).
##  - MIN-E (OpenPits): for a find no trial pit can reach any more, the manor stakes an open pit near the readings it
##    knows and posts one "excavate" job at a time while it still wants the pit dug: dig a load (`carry_ore` units,
##    the carrying rule) with a shovel for the earth and a pickaxe for the rock (MIN-E-Q4; a load ends early when its
##    digger's tools can dig no cell left) into the job's load, tip the earth onto the pit's spoil heaps and bring any
##    stone to the works yard. Paid at the quarry job's rate a unit (no wage of its own); the pit may miss (WDR-022).
##  - MIN-F2 (Q2): while its works lack stone and a sound timber support holds a face below ground, one "tunnel" job at
##    a time: cut a load (`carry_ore` units) at that face with a pickaxe into the job's load (MineWorks.dig: real rock,
##    the tunnel extended, hidden ore exposed if it lies there) and bring it to the works yard; paid at the quarry job's
##    rate a unit (no wage of its own). The manor knows nothing of hidden ore: it picks the face by the works alone.
##  - MIN-F2 (Q5): a "backfill" order is the player's, never the manor's: made only by order_backfill (the player's
##    Backfill Tunnel action), its wage paid by the player and held in the order until done; a worker carries the spoil
##    the player leaves at the order's depot (the mouth's surface stand) down to the cell in loads and puts it back a
##    unit at a time (MineWorks.fill). Cancelled or given up, what is placed stays and the rest is left where it lies.
##  - MIN-EQUIP: "shore" jobs, posted when the works yard holds their goods (MineSupply.shore_wanted): set up a timber
##    support beside a face the manor would tunnel ("prop"), repair a worn support ("repair") or set a ladder into a
##    shaft whose ladder is gone ("ladder"), with the yard's goods and its mallet carried in the job's load (the mallet
##    comes back to the yard); paid at the mending rate (`mend_wage`: no wage of its own).
## A household under a day of food is not left waiting: its relief is delivered at once, as before.
##
## Jobs are paid from the treasury, set aside when a job is taken (the treasury keeps
## `manor_job_reserve_days` of obligations after the wage) and paid when it is
## done; a job left undone is released at the next dawn after `manor_jobs.days`, its wage and goods
## back. Manor hands are already paid a day's wage: they take jobs unpaid. One job at a time per worker.
## Carried goods ride in the job's own load (never the worker's pack), so they cannot be sold, eaten or
## lost; a dead worker's load goes back. Every number is provisional — balance review pending.

const KINDS := ["haul", "quarry", "mend", "survey", "trial", "excavate", "tunnel", "backfill", "shore"]
const ORDER := ["pantry", "granary", "yard"]        # hauling priority by destination: relief first
const MATERIALS := ["plank", "stone", "rubble", "log", "iron_bar"]       # STONE-04: rubble mends as raw stone does

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
		_post({"kind": "mend", "qty": int(cfg("mend_load")), "site": [site[0].x, site[0].y], "place": site[1], "wage": int(cfg("mend_wage"))})   # X18-D6: posted at the base rate; the taker's wage is set at acceptance (wage_for)
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
	_post({"kind": "quarry", "item": "stone", "qty": int(cfg("quarry_qty")), "wage": int(cfg("quarry_wage"))})   # X18-D6: posted at the base rate; the taker's wage is set at acceptance (wage_for)


## MIN-D, the reeve's evening: one survey of a clue the manor has heard nothing of, and one trial pit for the best
## find it knows, each one at a time (Discovery.survey_target, trial_target). The village's mining capability level
## never gates a posting (owner decision Q18-9: levels shape pay and output only); what is posted needs a real clue,
## a known find and the treasury's means.
func post_discovery() -> void:
	var dc: Dictionary = Discovery.cfg().manor
	for j in jobs.duplicate():           # work no longer possible or needed is taken down untaken
		if j.taker != "" or not j.kind in ["survey", "trial"]:
			continue
		var c := w.prospecting.clue(str(j.clue))
		if j.kind == "survey" and w.prospecting.samples_left(c) < int(j.qty):
			jobs.erase(j)
		elif j.kind == "trial" and (not w.discovery.opened(str(j.clue)).is_empty() or w.discovery.trials_left(c) <= 0):
			jobs.erase(j)
	if not jobs.any(func(j): return j.kind == "survey"):
		var c := w.discovery.survey_target()
		if not c.is_empty():
			_post({"kind": "survey", "clue": str(c.id), "qty": int(dc.survey_samples), "wage": int(dc.survey_wage), "taken": 0, "sids": []})
	if not jobs.any(func(j): return j.kind == "trial"):
		var t := w.discovery.trial_target()
		if not t.is_empty():
			_post({"kind": "trial", "clue": str(t.clue.id), "qty": 1, "site": [t.cell.x, t.cell.y], "wage": int(dc.trial_wage)})


## MIN-E, the reeve's evening: the manor's open pit is dug a load at a time (one "excavate" job at a time) while it is
## still wanted (OpenPits.manor_wants: its find not opened, cells not yet down to the rock); with no pit, one is staked
## for a find no trial pit can reach any more (OpenPits.manor_target) when the treasury could pay a load's digging.
func post_pits() -> void:
	var pp: OpenPits = w.pits
	for j in jobs.duplicate():           # a pit no longer wanted takes its untaken job down
		if j.kind == "excavate" and j.taker == "" and not pp.manor_wants(pp.pit(int(j.pit))):
			jobs.erase(j)
	if jobs.any(func(j): return j.kind == "excavate"):
		return
	var job := {"kind": "excavate", "qty": excavate_load(), "wage": excavate_wage()}
	var p := pp.manor_pit()
	if p.is_empty():
		if not can_fund(job, ""):
			return
		var t := pp.manor_target()
		if t.is_empty():
			return
		p = pp.open_pit(World.MANOR, t.origin, str(t.clue.id))
		if p.is_empty():
			return
	job.pit = int(p.id)
	_post(job)


## MIN-F2 (Q2), the reeve's evening: one tunnel job at a time while the works lack stone (the quarry's rule) and a sound
## support holds a face below ground (MineWorks.manor_face); a job whose face is gone is taken down untaken.
func post_tunnels() -> void:
	for j in jobs.duplicate():
		if j.kind == "tunnel" and j.taker == "" and w.mine_works.face_refusal(int(j.level), Vector2i(int(j.site[0]), int(j.site[1]))) != "":
			jobs.erase(j)
	if jobs.any(func(j): return j.kind == "tunnel"):
		return
	if _works_stock("stone") >= 2 * int(cfg("mend_load")):
		return
	var job := {"kind": "tunnel", "qty": excavate_load(), "wage": excavate_wage()}
	if not can_fund(job, ""):
		return
	var f: Dictionary = w.mine_works.manor_face()
	if f.is_empty():
		return
	job.level = int(f.level)
	job.site = [f.cell.x, f.cell.y]
	_post(job)


## MIN-F2 (Q5): the player orders floor cell `cell` of `level` backfilled with `units` units of spoil, paying the wage
## (backfill.order_rate a unit, at least 1) now: it is held in the order until a worker finishes it. The order's depot is
## the surface stand of the mouth that leads to that level, where the player leaves the spoil. "" or why not.
func order_backfill(level: int, cell: Vector2i, units: int, actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, order_backfill.bind(level, cell, units))
	var why: String = w.mine_works.fill_ground_refusal(level, cell)
	if why != "":
		return why
	for j in jobs:
		if j.kind == "backfill" and int(j.level) == level and int(j.site[0]) == cell.x and int(j.site[1]) == cell.y:
			return "That passage is already ordered filled."
	var room: int = MineWorks.cell_units() - w.mine_works.fill_at(level, cell)
	units = clampi(units, 1, room)
	var wage := maxi(1, units * int(MineWorks.cfg().backfill.order_rate))
	if w.player.coins < wage:
		return "The order's wage is %d coins: you have too few." % wage
	var leg := w.underground.next_leg(0, level)
	if leg.is_empty():
		return "There is no way down to that passage."
	var j := {"kind": "backfill", "payer": w.acting_ref(), "level": level, "site": [cell.x, cell.y], "qty": units, "placed": 0,
		"depot": [int(leg.from.stand.x), int(leg.from.stand.y)], "stock": Inventory.new(), "wage": wage}
	_post(j)
	j.reserved = wage
	w.player.coins -= wage
	w.stat("backfill_orders")
	return ""


## The player's open backfill order for `cell` of `level`, or {}.
func backfill_order(level: int, cell: Vector2i) -> Dictionary:
	for j in jobs:
		if j.kind == "backfill" and int(j.level) == level and int(j.site[0]) == cell.x and int(j.site[1]) == cell.y:
			return j
	return {}


## MIN-F2 (Q5): the player leaves `qty` spoil from `from` at an order's depot (standing there). Units moved.
func stock_backfill(j: Dictionary, from: Inventory, qty: int, actor: PlayerState = null) -> int:
	if actor != null and actor != w.player:
		return w.as_actor(actor, stock_backfill.bind(j, from, qty))
	var item := str(MineWorks.cfg().backfill.item)
	var q := mini(qty, from.count(item))
	if q > 0:
		w.transfer(from, j.stock, item, q)
	return q


## The spoil an order still needs brought to its depot (placed, carried and waiting counted).
func backfill_needs(j: Dictionary) -> int:
	return maxi(0, int(j.qty) - int(j.placed) - j.load.total() - (j.stock as Inventory).total())


## MIN-F2 (Q5): the player cancels an order: the wage held goes back to the player; a worker on it sets down what they
## carry where they stand; the spoil at the depot is left lying there; the fill placed stays in the passage.
func cancel_backfill(j: Dictionary, actor: PlayerState = null) -> void:
	if actor != null and actor != w.player:
		w.as_actor(actor, cancel_backfill.bind(j))
		return
	if j.taker != "":
		var o = _who(str(j.taker))
		if o != null and j.load.total() > 0:
			_drop(j.load, o.pos, int(o.depth) if o is NPC else w.player_level, "spoil a worker set down")
		j.taker = ""
	if (j.stock as Inventory).total() > 0:
		_drop(j.stock, Vector2(int(j.depot[0]), int(j.depot[1])) + Vector2(0.5, 0.5), 0, "the backfill order's spoil")
	w.player.coins += int(j.reserved)
	j.reserved = 0
	jobs.erase(j)
	w.stat("backfill_orders_cancelled")


func _drop(inv: Inventory, at: Vector2, level: int, from: String) -> void:
	var bag := Inventory.new()
	for id in inv.ids():
		w.transfer(inv, bag, id, inv.count(id))
	var l := {"pos": at, "inv": bag, "coins": 0, "from": from, "t": w.minutes}
	if level != 0:
		l.level = level
	w.loot.append(l)


func is_player_order(j: Dictionary) -> bool:
	return World.is_player_ref(str(j.get("payer", "")))


## MIN-EQUIP, the reeve's evening (after the manor's purchases, MineSupply.procure): one shore job for each piece of shore
## work the manor wants (MineSupply.shore_wanted) whose goods, and a mallet, the works yard holds and no other shore job
## has claimed.
func post_shore() -> void:
	var claimed := {}
	for j in jobs:
		if j.kind == "shore" and j.load.total() == 0:
			var g := MineSupply.goods_for(str(j.mode))
			for id in g:
				claimed[id] = int(claimed.get(id, 0)) + int(g[id])
	var mallet_free: bool = yard.count("mallet") > jobs.filter(func(j): return j.kind == "shore" and j.load.total() == 0).size()
	for s in w.mine_works.supply.shore_wanted():
		if not mallet_free:
			return
		var g := MineSupply.goods_for(str(s.mode))
		var ok := true
		for id in g:
			if yard.count(id) - int(claimed.get(id, 0)) < int(g[id]):
				ok = false
		if not ok:
			continue
		for id in g:
			claimed[id] = int(claimed.get(id, 0)) + int(g[id])
		_post({"kind": "shore", "mode": str(s.mode), "level": int(s.level), "site": [s.cell.x, s.cell.y], "qty": 1, "wage": int(cfg("mend_wage"))})
		w.stat("shore_jobs_posted")
		mallet_free = yard.count("mallet") > jobs.filter(func(j): return j.kind == "shore" and j.load.total() == 0).size()


## A load of excavation: what a villager carries (balance.json carry_ore, the miners' carrying rule).
static func excavate_load() -> int:
	return int(ResourceNodes.number(OpenPits.cfg().manor.load))


## A load's wage at the quarry job's rate a unit (quarry_wage for quarry_qty), rounded up: no wage of its own.
static func excavate_wage() -> int:
	return ceili(float(cfg("quarry_wage")) * float(excavate_load()) / float(cfg("quarry_qty")))


## The samples a survey has taken that are not yet assayed (still carried by its taker).
func _survey_pending(j: Dictionary) -> Array:
	return (j.get("sids", []) as Array).filter(func(s): return w.prospecting.samples.has(str(int(s))))


## The next spot a survey would sample: the first of the clue's spots (hashed order) unsampled and open now.
func survey_spot(j: Dictionary) -> Vector2i:
	var pr: Prospecting = w.prospecting
	var c := pr.clue(str(j.clue))
	if c.is_empty() or pr.samples_left(c) <= 0:
		return Vector2i(-1, -1)
	for cell: Vector2i in c.spots:
		if not pr.sampled(c, cell) and not w.map.is_solid(cell):
			return cell
	return Vector2i(-1, -1)


## The party a job's taker is: the player or a villager (null if gone).
func _who(who: String):
	if World.is_player_ref(who):
		return w.player
	return w.npc(int(who.substr(4)))


## The smith nearest `at` who could assay a sample of `who`'s now (Prospecting.assayer_refusal), or null.
func _assayer_near(who, at: Vector2, reach: float) -> NPC:
	var best: NPC = null
	var bd := reach
	for o: NPC in w.npcs:
		if o.alive and o.job == "smith" and w.prospecting.assayer_refusal(who, o) == "":
			var d := o.pos.distance_to(at)
			if d <= bd:
				bd = d
				best = o
	return best


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
	return n != null and n.job in ["manor_hand", "reeve"]          # LOG-01: the reeve is salaried too, never paid twice


## X18-D6 (owner, 2026-10-23, "Set wage when taken"): a posted job carries the BASE wage; the wage it pays is fixed when a
## worker takes it, at that worker's own effective level in the job's industry (mending: carpentry; quarrying: mining),
## rounded to the nearest coin (D8). The treasury check and the sum set aside both use it: one payment, no new money.
## Jobs of other kinds, a player's order and the salaried staff pay their posted wage as before.
func wage_for(j: Dictionary, who: String) -> int:
	var base := int(j.get("wage", 0))
	if is_player_order(j) or is_staff(who):
		return base
	var ind := {"mend": "carpentry", "quarry": "mining"}.get(str(j.get("kind", "")), "") as String
	return CapabilityHook.pay(base, ind, who) if ind != "" and who != "" else base


## Whether the treasury can set this wage aside (manor hands are already paid: no wage). A day's job
## is a small, short promise: it keeps `manor_job_reserve_days` of obligations after the wage, the
## same line the evening's repairs are bought above (B7-009; the 10 days stay for hiring staff). The
## treasury starts at 270, under the 460 that ten days need, so with the long reserve no paid work
## existed until about day 12.
func can_fund(j: Dictionary, who: String) -> bool:
	if is_player_order(j):
		return true                   # MIN-F2: the player's order holds its wage already
	if is_staff(who):
		return true
	return w.treasury - wage_for(j, who) >= w.brain.daily_obligations() * float(GameData.b("manor_job_reserve_days"))


## The jobs open to this worker now, most needed first (relief, the granary, the yard, mending,
## quarrying); a quarry needs a pickaxe.
func open_for(who: String) -> Array:
	var out := []
	for j in jobs:
		if j.taker != "" or not can_fund(j, who):
			continue
		if j.kind in ["quarry", "trial", "excavate", "tunnel"] and not can_dig(j, who):
			continue
		if j.kind in ["tunnel", "backfill", "shore"] and World.is_player_ref(who):
			continue                 # MIN-F2: the player tunnels and fills with their own hands (and orders the fill)
		if j.kind == "backfill" and (is_staff(who) or (j.stock as Inventory).total() + j.load.total() == 0):
			continue                 # a player's order pays its own workers, and waits for the player's spoil
		if j.kind == "survey" and (is_staff(who) or not _has_kit(who) or _who(who).coins < int(j.qty) * int(Prospecting.cfg().assay.fee)):
			continue                 # the assay fees are paid on the way, the wage at the end: a worker needs them in hand
		out.append(j)
	out.sort_custom(func(a, b): return _rank(a) < _rank(b) or (_rank(a) == _rank(b) and int(a.id) < int(b.id)))
	return out


func _rank(j: Dictionary) -> int:
	if j.kind == "haul":
		return ORDER.find(str(j.to.kind))
	return {"mend": 3, "quarry": 4, "survey": 5, "trial": 6, "excavate": 7, "tunnel": 8, "backfill": 9, "shore": 2}.get(str(j.kind), 10)     # MIN-EQUIP: shoring with the yard's goods comes before mending


func _has_kit(who: String) -> bool:
	var o = _who(who)
	return o != null and o.inv.has(Prospecting.KIT)


func _has_pick(who: String) -> bool:
	return _has_tool(who, "pickaxe")


func _has_tool(who: String, kind: String) -> bool:
	return OpenPits.held_tool(_who(who), kind) != ""


## Owner MIN-E-Q4 (2026-10-21): whether `who` holds the tool a digging job needs: a quarry's rock a pickaxe; a trial pit's
## earth a shovel (Discovery trial.tool); an excavation some cell of its pit whose next layer they can dig with what they
## hold (a shovel for the earth, a pickaxe for the rock); a tunnel's face the kind of its next unit (MineWorks.tool_kind:
## rock a pickaxe, rubble or fill a shovel). The same rule for the player and every villager.
func can_dig(j: Dictionary, who: String) -> bool:
	match str(j.kind):
		"trial":
			return _has_tool(who, str(Discovery.cfg().trial.get("tool", "shovel")))
		"excavate":
			var p := w.pits.pit(int(j.get("pit", -1)))
			var kinds := OpenPits.kinds_held(_who(who))
			if p.is_empty() or kinds.is_empty():
				return false
			return w.pits.next_dig(p, yard_cell(), Vector2i(-1, -1), kinds).x >= 0
		"tunnel":
			if not j.has("site"):
				return _has_pick(who)
			return _has_tool(who, w.mine_works.tool_kind(int(j.level), Vector2i(int(j.site[0]), int(j.site[1]))))
	return _has_pick(who)


## MIN-SHOVEL: whether an open job of the manor's earthwork (a trial pit, or an excavation whose next cells are earth),
## fundable for `who`, is closed to them only for want of a shovel (a miner then buys one, NPCBrain._miner).
func shovel_would_open(who: String) -> bool:
	var o = _who(who)
	if o == null or OpenPits.held_tool(o, "shovel") != "":
		return false
	for j in jobs:
		if j.taker != "" or not can_fund(j, who) or not str(j.kind) in ["trial", "excavate"]:
			continue
		if str(j.kind) == "trial":
			return true
		var p := w.pits.pit(int(j.get("pit", -1)))
		if not p.is_empty() and not can_dig(j, who) and w.pits.next_dig(p, yard_cell(), Vector2i(-1, -1), OpenPits.kinds_held(o) + ["shovel"]).x >= 0:
			return true
	return false


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
	if not is_player_order(j):
		j.reserved = 0 if is_staff(who) else wage_for(j, who)
		w.treasury -= int(j.reserved)
	j.taker = who
	j.day = w.day()
	w.stat("manor_jobs_taken")
	return true


## Give a job up: the wage back to the treasury, what it carried back where it came from (a quarry's
## stone to the yard). The job stays posted for someone else.
func release(j: Dictionary) -> void:
	if is_player_order(j):
		# MIN-F2: the player's order keeps its wage; spoil carried goes back into the depot only where the worker stands
		# at it, else it is set down where they stand (the fill placed stays)
		var o = _who(str(j.taker))
		if j.load.total() > 0 and o != null:
			var at_depot: bool = (o is PlayerState or int(o.depth) == 0) and Vector2(o.pos).distance_to(Vector2(int(j.depot[0]), int(j.depot[1])) + Vector2(0.5, 0.5)) < 2.0
			if at_depot:
				for id in j.load.ids():
					w.transfer(j.load, j.stock, id, j.load.count(id))
			else:
				_drop(j.load, o.pos, int(o.depth) if o is NPC else w.player_level, "spoil a worker set down")
		j.taker = ""
		j.day = -1
		return
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
			"excavate":
				var p := w.pits.pit(int(j.pit))      # MIN-E: earth back onto its pit's heaps, stone to the yard
				if not p.is_empty():
					w.pits.tip(p, j.load, true)
				for id in j.load.ids():
					w.transfer(j.load, yard, id, j.load.count(id))
			_:
				for id in j.load.ids():
					w.transfer(j.load, yard, id, j.load.count(id))
	j.taker = ""
	j.day = -1
	if j.kind == "excavate":
		j.erase("site")
	if j.kind in ["quarry", "survey", "trial", "excavate", "tunnel", "shore"]:
		jobs.erase(j)              # the reeve posts it again when the works still lack stone (or the find is still wanted)


## The next thing a job needs: "take" (at the lot or the yard), "mine" (a quarry short of stone),
## "put" (at its destination), "mend" (at its site).
func step(j: Dictionary) -> String:
	match str(j.kind):
		"haul":
			return "take" if j.load.total() == 0 else "put"
		"quarry":
			return "mine" if j.load.count("stone") < int(j.qty) and not World.is_player_ref(j.taker) else "put"
		"mend":
			return "take" if j.load.total() == 0 else "mend"
		"survey":
			if int(j.taken) < int(j.qty) and survey_spot(j).x >= 0:
				return "sample"
			return "assay" if not _survey_pending(j).is_empty() else "report"
		"trial":
			return "dig"
		"shore":
			if int(j.get("done", 0)) > 0:
				return "put"
			return "take" if j.load.total() == 0 else "prop"
		"tunnel":
			var face := Vector2i(int(j.site[0]), int(j.site[1]))
			if j.load.total() < int(j.qty) and w.mine_works.face_refusal(int(j.level), face) == "":
				return "cut"
			return "put" if j.load.total() > 0 else "cut"
		"backfill":
			var site := Vector2i(int(j.site[0]), int(j.site[1]))
			var full: bool = w.mine_works.fill_at(int(j.level), site) >= MineWorks.cell_units()
			if int(j.placed) >= int(j.qty) or full:
				return "return" if j.load.total() > 0 else "done"
			return "fetch" if j.load.total() == 0 else "fill"
		"excavate":
			var p := w.pits.pit(int(j.pit))
			if j.load.total() < int(j.qty) and w.pits.manor_wants(p) and (j.load.total() == 0 or excavate_cell(j).x >= 0):
				return "excavate"               # (a load ends early when its digger's tools can dig no cell left, MIN-E-Q4)
			for id in OpenPits.earth_items():
				if j.load.count(id) > 0:
					return "tip"
			return "put" if j.load.total() > 0 else "excavate"
	return ""


## MIN-E: the cell an excavation digs next: the one its taker was sent to while it can still be dug, else the pit's
## next (OpenPits.next_dig) from where the taker stands. `planning`: a villager choosing where to go may pick the cell
## it stands on (it steps off it to dig).
func excavate_cell(j: Dictionary, planning := false) -> Vector2i:
	var p := w.pits.pit(int(j.pit))
	if p.is_empty():
		return Vector2i(-1, -1)
	var o = _who(str(j.taker))
	var kinds: Array = OpenPits.kinds_held(o) if o != null else []     # MIN-E-Q4: only cells its digger's tools can dig
	if o != null and kinds.is_empty():
		return Vector2i(-1, -1)
	if j.has("site"):
		var c := Vector2i(int(j.site[0]), int(j.site[1]))
		if w.pits.dig_ground_refusal(p, c) == "" and (kinds.is_empty() or kinds.has(w.pits.tool_needed(p, c))):
			return c
	var from: Vector2i = Vector2i(o.pos.floor()) if o != null else yard_cell()
	return w.pits.next_dig(p, from, from if planning else Vector2i(-1, -1), kinds)


## MIN-E: the spoil heap an excavation tips onto: the first of its pit's with room (or its first).
func heap_cell(j: Dictionary) -> Vector2i:
	var p := w.pits.pit(int(j.pit))
	if p.is_empty() or (p.heaps as Array).is_empty():
		return yard_cell()
	for h in p.heaps:
		if (h.inv as Inventory).total() < w.pits.heap_cap(p):
			return Vector2i(int(h.x), int(h.y))
	return Vector2i(int(p.heaps[0].x), int(p.heaps[0].y))


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
		"mend", "dig":
			return Vector2i(int(j.site[0]), int(j.site[1]))
		"excavate":
			var c := excavate_cell(j)
			return c if c.x >= 0 else yard_cell()
		"tip":
			return heap_cell(j)
		"fetch", "return":
			return Vector2i(int(j.depot[0]), int(j.depot[1]))
		"sample":
			return survey_spot(j)
		"assay":
			var best := yard_cell()
			var bd := 1e9
			for o: NPC in w.npcs:
				if o.alive and o.role == "adult" and o.job == "smith":
					var c: Vector2i = w.brain._workplace_cell(o)
					if Vector2(c).distance_to(Vector2(yard_cell())) < bd:
						bd = Vector2(c).distance_to(Vector2(yard_cell()))
						best = c
			return best
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
		"survey":
			var c := w.prospecting.clue(str(j.clue))
			return "Survey %s %s: take %d rock samples with your prospector's kit, have a smith assay them (the fees are yours) and tell the manor what they show" % [w.prospecting.stain(c), w.prospecting.place(c), int(j.qty)]
		"trial":
			var c := w.prospecting.clue(str(j.clue))
			return "Dig a trial pit by %s %s with a shovel, looking for ore (%d hours)" % [w.prospecting.stain(c), w.prospecting.place(c), roundi(float(Discovery.cfg().trial.minutes) / 60.0)]
		"shore":
			return {"prop": "Take a timber support and the mallet from the works yard and set the support up below ground beside the rock face the manor will tunnel",
				"repair": "Take a plank and the mallet from the works yard and repair a worn timber support below ground",
				"ladder": "Take a ladder and the mallet from the works yard and set it into a shaft below ground"}.get(str(j.mode), "Shore work below ground")
		"tunnel":
			return "Cut a load of %d from the rock face below ground with a pickaxe and bring it to the works yard" % int(j.qty)
		"backfill":
			return "For the player: carry spoil from the mine's mouth down below ground and put %d back into a passage (%d placed)" % [int(j.qty), int(j.placed)]
		"excavate":
			var p := w.pits.pit(int(j.pit))
			return "Dig a load of %d from the manor's open pit %s (a shovel for earth, a pickaxe for rock), tip the earth on its spoil heap and bring any stone to the works yard" % [int(j.qty), w.where(OpenPits.rect(p)) if not p.is_empty() else "in the village"]
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
	if j.kind == "shore":
		return _shore_step(j, who)
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
					if id in MATERIALS and (best == "" or yard.count(id) > yard.count(best)):
						best = id                  # MIN-F2: tunnel spoil kept in the yard mends nothing
				if best == "":
					break
				w.transfer(yard, j.load, best, 1)
				want -= 1
			return j.load.total() > 0
		"put":
			if j.kind == "haul":
				_unload(j.load, j.to)
				_finish(j, who)
				return true
			# quarry: the stone goes into the yard (the player brings it in their pack); an excavation's rides in its load
			if j.kind in ["excavate", "tunnel"]:
				for id in j.load.ids():
					w.transfer(j.load, yard, id, j.load.count(id))
			elif World.is_player_ref(who):
				if pack.count("stone") < int(j.qty):
					return false
				w.transfer(pack, yard, "stone", int(j.qty))
				w.player.trim_stolen()
			else:
				w.transfer(j.load, yard, "stone", j.load.count("stone"))
			_finish(j, who)
			return true
		"sample":
			var o = _who(who)
			var pr: Prospecting = w.prospecting
			var cell := survey_spot(j)
			if o == null or cell.x < 0:
				return false
			var r := pr.take_sample(o, pr.clue(str(j.clue)), cell)
			if r.result != "ok":
				last_refusal = str(r.why)
				return false
			j.taken = int(j.taken) + 1
			(j.sids as Array).append(int(r.sample))
			if r.broke and o is NPC:
				w.note("%s %s's prospector's kit is worn out." % [o.name, o.family])
			return true
		"assay":
			var o = _who(who)
			if o == null:
				return false
			var a := _assayer_near(o, o.pos, 3.5)
			if a == null:
				last_refusal = "There is no smith at the forge here who can assay a sample now."
				return false
			var r := w.prospecting.assay(o, a, int(_survey_pending(j)[0]) if not _survey_pending(j).is_empty() else -1)
			if r.result != "ok":
				last_refusal = str(r.why)
				return false
			return true
		"report":
			# the readings of the survey's samples are told to the manor (Prospecting.share), barren ones too
			for rec in w.prospecting.records:
				if (j.sids as Array).has(int(rec.sample)) and str(rec.by) == who:
					w.prospecting.share(rec, World.MANOR)
			w.stat("surveys_reported")
			_finish(j, who)
			return true
		"dig":
			var o = _who(who)
			var dv: Discovery = w.discovery
			var c := w.prospecting.clue(str(j.clue))
			if o == null:
				return false
			var tool := OpenPits.held_tool(o, str(Discovery.cfg().trial.get("tool", "shovel")))
			var cell := Vector2i(int(j.site[0]), int(j.site[1]))
			if dv.ground_refusal(c, cell) != "":
				var other := dv.next_cell(c)          # the ground changed: the next best clear cell, or the job ends
				if other.x < 0:
					last_refusal = "There is no clear ground left to dig there."
					release(j)
					return false
				j.site = [other.x, other.y]
				last_refusal = "The ground there is taken: the reeve marks another spot."
				return false
			var r := dv.trial_dig(o, c, cell, tool)
			if r.result != "ok":
				last_refusal = str(r.why)
				return false
			j.found = not (r.found as Dictionary).is_empty()
			if r.broke and o is NPC:
				w.note("%s %s's %s broke." % [o.name, o.family, GameData.item_name(tool).to_lower()])
			_finish(j, who)
			return true
		"excavate":
			var o = _who(who)
			var p := w.pits.pit(int(j.pit))
			var cell := excavate_cell(j)
			if o == null or p.is_empty() or cell.x < 0:
				last_refusal = "There is nothing in the pit that can be dug now."
				if j.load.total() == 0 and not World.is_player_ref(who):
					release(j)
				return false
			var tool := OpenPits.held_tool(o, w.pits.tool_needed(p, cell))     # MIN-E-Q4: a shovel for earth, a pickaxe for rock
			var r := w.pits.dig(o, p, cell, j.load, tool)
			if r.result != "ok":
				last_refusal = str(r.why)
				j.erase("site")
				return false
			if not (r.exposed as Dictionary).is_empty():
				j.found = true
			if r.broke and o is NPC:
				w.note("%s %s's %s broke." % [o.name, o.family, GameData.item_name(tool).to_lower()])
			return true
		"cut":
			var o = _who(who)
			var face := Vector2i(int(j.site[0]), int(j.site[1]))
			if o == null or w.mine_works.face_refusal(int(j.level), face) != "":
				last_refusal = "The rock face cannot be cut now."
				if j.load.total() == 0 and not World.is_player_ref(who):
					release(j)
				return false
			var ctool := OpenPits.held_tool(o, w.mine_works.tool_kind(int(j.level), face))   # rock a pickaxe, rubble a shovel
			var r: Dictionary = w.mine_works.dig(o, face, j.load, ctool)
			if r.result != "ok":
				last_refusal = str(r.why)
				return false
			if not (r.exposed as Array).is_empty():
				j.found = true
			if r.opened:
				var nf: Dictionary = w.mine_works.manor_face(int(j.level), face)     # the heading goes on from here
				if not nf.is_empty():
					j.site = [nf.cell.x, nf.cell.y]
			if r.broke and o is NPC:
				w.note("%s %s's %s broke." % [o.name, o.family, GameData.item_name(ctool).to_lower()])
			return true
		"fetch":
			var want: int = mini(int(GameData.b("carry_ore")), int(j.qty) - int(j.placed))
			var item := str(MineWorks.cfg().backfill.item)
			var q := mini(want, (j.stock as Inventory).count(item))
			if q <= 0:
				last_refusal = "There is no spoil at the depot yet."
				return false
			w.transfer(j.stock, j.load, item, q)
			return true
		"fill":
			var o = _who(who)
			if o == null:
				return false
			var r: Dictionary = w.mine_works.fill(o, Vector2i(int(j.site[0]), int(j.site[1])), j.load)
			if r.result != "ok":
				last_refusal = str(r.why)
				return false
			j.placed = int(j.placed) + 1
			if step(j) == "done":
				_finish(j, who)
			return true
		"return":
			for id in j.load.ids():
				w.transfer(j.load, j.stock, id, j.load.count(id))
			if step(j) == "done":
				_finish(j, who)
			return true
		"done":
			_finish(j, who)
			return true
		"tip":
			var p := w.pits.pit(int(j.pit))
			if p.is_empty():
				release(j)
				return false
			var moved := w.pits.tip(p, j.load)
			if moved.is_empty():
				last_refusal = "The spoil heaps are full or blocked."
				return false
			if j.load.total() == 0:
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


## MIN-EQUIP: a shore job's step. "take": its goods and the mallet from the works yard into the job's load; "prop": set
## up, repair or set the ladder (MineWorks, with the load's goods and mallet); "put": the mallet (and anything left)
## back into the yard, and the job is done and paid.
func _shore_step(j: Dictionary, who: String) -> bool:
	match step(j):
		"take":
			var g := MineSupply.goods_for(str(j.mode))
			if not yard.has_all(g) or not yard.has("mallet"):
				last_refusal = "The works yard lacks what the job needs."
				release(j)
				return false
			for id in g:
				w.transfer(yard, j.load, id, int(g[id]))
			w.transfer(yard, j.load, "mallet", 1)
			return true
		"prop":
			var o = _who(who)
			if o == null:
				return false
			var c := Vector2i(int(j.site[0]), int(j.site[1]))
			var mw: MineWorks = w.mine_works
			var r: Dictionary = {}
			match str(j.mode):
				"prop":
					r = mw.place_support(o, c, j.load)
				"repair":
					r = mw.repair(o, c, j.load)
				"ladder":
					r = mw.install_ladder(o, c, j.load)
			if r.get("result", "") != "ok":
				last_refusal = str(r.get("why", ""))
				release(j)                                 # the place changed: the goods go back, the work is weighed again
				return false
			j.done = 1
			return true
		"put":
			for id in j.load.ids():
				w.transfer(j.load, yard, id, j.load.count(id))
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
	if World.is_player_ref(who):
		w.player.coins += pay
	else:
		var n := w.npc(int(who.substr(4)))
		if n:
			n.coins += pay
			n.earned += pay
	if is_player_order(j):
		w.stat("player_order_wages", pay)     # MIN-F2: the player's coins, held in the order
		if (j.stock as Inventory).total() > 0:  # spoil left at the depot stays there, the player's to take up
			_drop(j.stock, Vector2(int(j.depot[0]), int(j.depot[1])) + Vector2(0.5, 0.5), 0, "the backfill order's spoil")
	else:
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
			if World.is_player_ref(who):
				w.note("Your work for the manor lapsed: \"%s\" was not done in time." % describe(j))
	refresh()


func on_death(n: NPC) -> void:
	var j := job_of(World.npc_ref(n.id))
	if not j.is_empty():
		release(j)


## The player died: their job goes back.
func release_player() -> void:
	var j := job_of(w.acting_ref())          # MP Batch B: the dying player's own job ("player" in single player)
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
			var d: Dictionary = w.nearest_seam(n, ["stone"])          # MIN-A: the gallery's stone too
			if d.is_empty():
				release(j)
				return false
			n.plan = b.seam_steps(n, d, "mj_mine", {"job": int(j.id)})
		"mend":
			var at := step_cell(j)
			n.plan = [b.go(b.beside(at, n.cell())), b.work(float(cfg("mend_minutes")), "mj_step", {"job": int(j.id)}, "work", at)]
		"sample":
			if not n.inv.has(Prospecting.KIT):
				release(j)
				return false
			var at := survey_spot(j)
			n.doing = "surveying a stain for the manor"
			n.plan = [b.go(at), b.work(float(Prospecting.cfg().sample_minutes) * Skills.value(n, "mining", "mine_time", 1.0), "mj_step", {"job": int(j.id)}, "work", at)]
		"assay":
			var a := w.prospecting.assayer_for(n)
			if a == null:
				if n.coins < int(Prospecting.cfg().assay.fee):
					release(j)                       # the fees are the worker's: without them the survey is given up
					return false
				n.doing = "waiting for an assayer"
				n.plan = [b.work(45, "", {}, "idle")]
				return true
			n.doing = "taking the survey's samples to the assayer"
			n.plan = [b.go(b._workplace_cell(a)), b.doit("mj_step", {"job": int(j.id)}), b.work(float(Prospecting.cfg().assay.minutes) + 10.0, "", {}, "idle")]
		"excavate":
			var p := w.pits.pit(int(j.pit))
			j.erase("site")
			var at := excavate_cell(j, true)
			if p.is_empty() or at.x < 0:
				release(j)
				return false
			j.site = [at.x, at.y]
			var i := OpenPits.index(p, at)
			n.doing = "digging the manor's open pit"
			n.plan = [b.go(w.pits.stand_for(p, i, n.cell())), b.work(OpenPits.minutes_of(int(p.dug[i])) * Skills.value(n, "mining", "mine_time", 1.0), "mj_step", {"job": int(j.id)}, "swing", at)]
		"prop":
			var site := Vector2i(int(j.site[0]), int(j.site[1]))
			var lv := int(j.level)
			var mc: Dictionary = MineWorks.cfg().support if str(j.mode) != "ladder" else MineWorks.cfg().ladder
			n.doing = {"prop": "setting up a timber support for the manor", "repair": "repairing a timber support for the manor", "ladder": "setting a ladder in a shaft for the manor"}.get(str(j.mode), "shoring for the manor")
			var stand: Vector2i = w.mine_works.fill_stand(lv, site, n.cell() if n.depth == lv else site)
			n.plan = [b.go(stand, 1.0, lv), b.work(float(mc.get("repair_minutes", mc.minutes)) if str(j.mode) == "repair" else float(mc.minutes), "mj_step", {"job": int(j.id)}, "work", site)]
		"cut":
			var face := Vector2i(int(j.site[0]), int(j.site[1]))
			var lv := int(j.level)
			if OpenPits.held_tool(n, w.mine_works.tool_kind(lv, face)) == "" or w.mine_works.face_refusal(lv, face) != "":
				release(j)
				return false
			n.doing = "cutting a tunnel for the manor"
			n.plan = [b.go(b.beside(face, n.cell() if n.depth == lv else face, lv), 1.0, lv),
				b.work(w.mine_works.npc_minutes_at(lv, face, n), "mj_step", {"job": int(j.id)}, "swing", face)]
		"fill":
			var site := Vector2i(int(j.site[0]), int(j.site[1]))
			var lv := int(j.level)
			n.doing = "backfilling a passage below ground for the player"
			n.plan = [b.go(w.mine_works.fill_stand(lv, site, n.cell() if n.depth == lv else site), 1.0, lv),
				b.work(float(MineWorks.cfg().backfill.minutes), "mj_step", {"job": int(j.id)}, "work", site)]
		"fetch":
			if (j.stock as Inventory).total() == 0:
				release(j)
				return false
			n.doing = "fetching spoil for a backfill"
			n.plan = [b.go(Vector2i(int(j.depot[0]), int(j.depot[1]))), b.doit("mj_step", {"job": int(j.id)})]
		"return":
			n.plan = [b.go(Vector2i(int(j.depot[0]), int(j.depot[1]))), b.doit("mj_step", {"job": int(j.id)})]
		"done":
			n.plan = [b.doit("mj_step", {"job": int(j.id)})]
		"tip":
			n.doing = "tipping earth on the spoil heap"
			var hc := step_cell(j)
			var stand := w.pits.stand_beside(hc, n.cell())
			n.plan = [b.go(stand if stand.x >= 0 else b.beside(hc, n.cell())), b.doit("mj_step", {"job": int(j.id)})]
		"dig":
			if OpenPits.held_tool(n, str(Discovery.cfg().trial.get("tool", "shovel"))) == "":
				release(j)
				return false
			var at := step_cell(j)
			n.doing = "digging a trial pit for the manor"
			n.plan = [b.go(b.beside(at, n.cell())), b.work(float(Discovery.cfg().trial.minutes) * Skills.value(n, "mining", "mine_time", 1.0), "mj_step", {"job": int(j.id)}, "swing", at)]
		_:
			n.plan = [b.go(b.beside(step_cell(j), n.cell())), b.doit("mj_step", {"job": int(j.id)})]
	return true


## A villager takes an open job of one of `kinds` they can do (a prospector takes the manor's surveys first).
func seek_kind(n: NPC, kinds: Array) -> bool:
	var who := World.npc_ref(n.id)
	if not job_of(who).is_empty() or n.role != "adult":
		return false
	for j in open_for(who):
		if kinds.has(str(j.kind)) and take(j, who):
			return plan(n)
	return false


## LOG-01 (owner REC-013 Q2, 2026-10-21): the reeve carries an unclaimed delivery only when no manor hand is free to
## take it, by the same board rules (first come, one job at a time, no wage: the reeve is salaried). Urgent relief keeps
## deliver_now. True with a plan.
func reeve_fallback(n: NPC) -> bool:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "manor_hand" and job_of(World.npc_ref(o.id)).is_empty():
			return false             # a free hand will take it on its own round
	return seek_kind(n, ["haul"])


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
		var d: Dictionary = w.deposit_at(Vector2i(int(a.x), int(a.y)), int(a.get("level", 0)))
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
		if j.has("stock"):
			add.call(j.stock)               # MIN-F2: spoil left at a backfill order's depot
	return out


func food_points() -> float:
	var p := 0.0
	var g := goods()
	for f in NPCBrain.EDIBLE:
		p += int(g.get(f, 0)) * NPCBrain.food_points(f)     # the one valuation (FSE-17)
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
		if j.has("stock"):
			d.stock = (j.stock as Inventory).to_dict()
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
		for k in ["id", "lot", "qty", "wage", "day", "reserved", "taken", "level", "placed"]:
			if j.has(k):
				j[k] = int(j[k])
		for k in ["site", "at", "depot"]:
			if j.has(k):
				j[k] = [int(j[k][0]), int(j[k][1])]
		if j.has("sids"):
			j.sids = (j.sids as Array).map(func(v): return int(v))
		if j.has("to") and j.to.has("hh"):
			j.to.hh = int(j.to.hh)
		j.load = Inventory.from_dict(jd.get("load", {}))
		if jd.has("stock"):
			j.stock = Inventory.from_dict(jd.stock)
		jobs.append(j)
	next_id = int(d.get("next_id", 1))
