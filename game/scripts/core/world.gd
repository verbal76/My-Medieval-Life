class_name World
extends RefCounted
## The whole simulated village: map, clock, people, resources and the rules that move goods and
## money. Headless: the view only reads this and listens to the signals.
##
## Invariants (tested in tests/run_tests.gd):
##  - coins are only created by the explicit caravan source and never destroyed (the manor
##    treasury counts as coins in the village);
##  - grain only enters by harvest and only leaves by being eaten, cooked, fed to animals or sold
##    to the caravan; the manor granary holds what the treasury bought;
##  - items only appear through extraction (mining, felling, hunting, slaughter, harvest) or recipes that
##    consume their inputs, and only vanish by being eaten, used up in a recipe or a building,
##    or worn out;
##  - a deposit never yields more than its amount; dead people stay dead.

signal tile_changed(cell: Vector2i, kind: String, value: int)   # kind: below | above | path
signal event(text: String)
signal npc_died(npc: NPC)
signal building_added(b: Dictionary)
signal bled(pos: Vector2)          # someone or something was slain here (drawn as blood; not saved)

const DAY := 1440.0

var map: VillageMap
var rng := RandomNumberGenerator.new()
var seed := 1
var minutes := 7.0 * 60.0          # game time since the start (day 0, 07:00)
var npcs: Array = []               # NPC
var by_id := {}
var households: Array = []         # {id, family, home, members, pantry}
var buildings := {}                # id -> dict
var stations := {}                 # id -> dict
var stalls := {}                   # id -> dict (kind, owner)
var trees: Array = []              # {x, y, trunk, top, bottom, state, regrow}: trunk is the stump tile
                                   # at (x, y), the only solid cell; the canopy (top at y - 1, bottom at y)
                                   # is drawn over the characters, who can walk behind it
var deposits: Array = []           # {x, y, ore, amount}
var fields: Array = []             # {id, x, y, w, h, state, ready, owner}
var plots: Array = []              # {id, x, y, w, h, door, price, owner, site}
var loot: Array = []               # {pos: Vector2, inv: Inventory, coins, from}
var fauna: Fauna                   # livestock in the pens, wild animals in the woods
var treasury := 0                  # the manor's coins: kept by the reeve's office, not in anyone's purse
var granary := Inventory.new()     # the manor's grain, bought from farmers' surplus, given out as relief
var last_reeve_day := -1           # the day the reeve's evening business last ran (never twice a day)
var last_payday := -1              # the day wages were last paid
var player := PlayerState.new()
var coin_sources := 0              # coins that entered the village (caravan)
var quests: Quests                 # side quests on offer (scripts/core/quests.gd)
var log_lines: Array = []
var stats := {}                    # running ledger (food made, eaten, exported, meals missed ...) for diagnostics; not saved
var last_hour := -1
var guard_posts: Array = []        # patrol points
var bandit_camp := Vector2i.ZERO
var sage_id := -1
var reeve_id := -1
var detail_radius := 34.0          # tiles: NPCs nearer the player get every-frame updates
var brain


func _init() -> void:
	GameData.ensure()


# ---------------------------------------------------------------- setup ----------------------
func setup(m: VillageMap, world_seed: int) -> void:
	map = m
	seed = world_seed
	rng.seed = world_seed
	brain = NPCBrain.new(self)
	for b in m.data.buildings:
		buildings[b.id] = b.duplicate(true)
	for s in m.data.stations:
		var st: Dictionary = s.duplicate(true)
		st.users = {}                  # npc id -> game minute their reservation lapses (capacity: st.get("capacity", 1))
		stations[st.id] = st
	for i in m.data.stalls.size():
		var s: Dictionary = m.data.stalls[i].duplicate(true)
		s.kind = ["raw", "food", "goods"][i % 3]
		s.owner = -1
		stalls[s.id] = s
	for t in m.data.trees:
		trees.append({"x": int(t.x), "y": int(t.y), "trunk": int(t.trunk), "top": int(t.top), "bottom": int(t.bottom),
				"state": "grown", "regrow": 0.0})
	for d in m.data.deposits:
		deposits.append({"x": int(d.x), "y": int(d.y), "ore": d.ore, "amount": int(d.amount)})
	for f in m.data.fields:
		var fd: Dictionary = f.duplicate(true)
		fd.state = "ripe"
		fd.crop = int(GameData.b("field_yield"))
		fd.ready = 0.0
		fd.owner = []
		fields.append(fd)
	for p in m.data.plots:
		var pd: Dictionary = p.duplicate(true)
		pd.owner = ""
		pd.site = {}
		plots.append(pd)
	bandit_camp = Vector2i(int(m.data.spawns.bandit_camp[0]), int(m.data.spawns.bandit_camp[1]))
	_guard_posts()
	Population.populate(self)
	_open_treasury()
	# the settlers' grain store: a finite stock of last year's harvest, 7 days of the village's food
	var settlers := 0
	for n: NPC in npcs:
		if n.role != "bandit":
			settlers += 1
	granary.add("wheat", ceili(settlers * 24.0 * float(GameData.b("hunger_per_hour")) * float(GameData.b("start_granary_days")) / 120.0))
	fauna = Fauna.new(self)
	fauna.populate()
	_assign_keepers()
	var sp = m.data.spawns.player
	player.pos = Vector2(int(sp[0]) + 0.5, int(sp[1]) + 0.5)
	give_start_kit(player)
	for n: NPC in npcs:
		by_id[n.id] = n
	index_interiors()
	_load_containers(m, [])
	serve_tables()                     # the tavern opens: the keepers set food out on its tables
	brain.dawn(false)                  # the first morning's snapshot of everyone's earnings
	quests = Quests.new(self)
	quests.refresh()
	quests.start_story()
	note("Day 1 begins in the village.")


## The manor's funds are the treasury; the reeve keeps only a purse. Used for a new world and to
## move an older save's reeve coins into the treasury.
func _open_treasury() -> void:
	for n: NPC in npcs:
		if n.id == reeve_id:
			var purse := mini(n.coins, int(GameData.b("reeve_purse")))
			treasury += n.coins - purse
			n.coins = purse


## Each pen gets a keeper: the farmers in id order, one pen each, and a start of feed in the trough.
func _assign_keepers() -> void:
	var farmers := []
	for n: NPC in npcs:
		if n.alive and n.job == "farmer":
			farmers.append(n)
	var ids := fauna.pens.keys()
	ids.sort()
	for i in ids.size():
		var pen: Dictionary = fauna.pens[ids[i]]
		if i < farmers.size():
			pen.owner = farmers[i].id
		pen.trough = fauna.daily_need(pen) * 2


## Patrol points along the village roads, away from the bandits' woods.
func _guard_posts() -> void:
	var road: Array = map.data.road
	for i in range(0, road.size(), max(1, road.size() / 24)):
		var c := Vector2i(int(road[i][0]), int(road[i][1]))
		if c.distance_to(bandit_camp) > 22.0 and c.y >= 26:
			guard_posts.append(c)


# ---------------------------------------------------------------- time -----------------------
func day() -> int:
	return int(minutes / DAY)


func hour() -> float:
	return fmod(minutes, DAY) / 60.0


func clock_text() -> String:
	var h := int(hour())
	var m := int(fmod(minutes, 60.0))
	return "Day %d  %02d:%02d" % [day() + 1, h, m]


func is_night() -> bool:
	var h := hour()
	return h >= 21.0 or h < 5.5


# ---------------------------------------------------------------- update ---------------------
## Advance the world by `real_dt` seconds of play.
func update(real_dt: float) -> void:
	var gm: float = real_dt * float(GameData.b("game_minutes_per_second"))
	minutes += gm
	var h := int(minutes / 60.0)
	if h != last_hour:
		last_hour = h
		_on_hour(h % 24)
	for n: NPC in npcs:
		if not n.alive:
			continue
		var near := n.pos.distance_to(player.pos) < detail_radius
		if near:
			_update_npc(n, real_dt)
		else:
			# Abstract tier: same rules, updated in larger scheduled steps.
			n.tick_acc += real_dt
			if n.tick_acc >= 0.5:
				_update_npc(n, n.tick_acc)
				n.tick_acc = 0.0
	fauna.update(real_dt)
	_update_player(real_dt, gm)


## Days of food the village holds for its people (all food in hands and pantries), updated hourly.
var food_days := 99.0


func _update_food_days() -> void:
	var points := 0.0
	var people := 0
	for n: NPC in npcs:
		if n.alive and n.role != "bandit":
			people += 1
			for f in NPCBrain.FOOD:
				points += n.inv.count(f) * float(GameData.item(f).food)
	for hh in households:
		for f in NPCBrain.FOOD:
			points += hh.pantry.count(f) * float(GameData.item(f).food)
	for f in NPCBrain.FOOD:
		points += table_food(f) * float(GameData.item(f).food)
	points += granary.count("wheat") * float(GameData.item("wheat").food)
	food_days = points / maxf(1.0, people * 24.0 * float(GameData.b("hunger_per_hour")))


func famine() -> bool:
	return food_days < float(GameData.b("famine_food_days"))


func _on_hour(h: int) -> void:
	_update_food_days()
	serve_tables()
	for f in fields:                   # a crop is ripe when it has grown, not at the next sunrise
		if f.state == "growing" and minutes >= f.ready:
			f.state = "ripe"
			f.crop = int(GameData.b("field_yield"))
			_field_tiles(f)
	if h == 6:
		_new_day()
	if h == 17 and last_reeve_day != day():
		last_reeve_day = day()
		brain.reeve_day()
	if h == 18 and last_payday != day():
		last_payday = day()
		brain.pay_guards()
	if h == 12 and day() % int(GameData.b("caravan_every_days")) == 1:
		brain.caravan()


func _new_day() -> void:
	var d := day()
	for t in trees:
		if t.state != "grown" and d >= t.regrow:
			if t.state == "stump":
				t.state = "sapling"
				t.regrow = d + 2
				tile_changed.emit(Vector2i(t.x, t.y), "below", map.data.tiles.sapling)
			else:
				t.state = "grown"
				tile_changed.emit(Vector2i(t.x, t.y), "below", t.trunk)
				tile_changed.emit(Vector2i(t.x, t.y - 1), "above", t.top)
				tile_changed.emit(Vector2i(t.x, t.y), "above", t.bottom)
				map.set_solid(Vector2i(t.x, t.y), true)
	fauna.new_day()
	brain.dawn()
	var cold := 0
	for hh in households:
		if not hh.pantry.remove("log"):
			cold += 1
	if cold > 0:
		note("%d households had no firewood last night." % cold)


func _update_npc(n: NPC, dt: float) -> void:
	var gm: float = dt * float(GameData.b("game_minutes_per_second"))
	n.hunger = maxf(0.0, n.hunger - gm / 60.0 * float(GameData.b("hunger_per_hour")))
	if n.hunger <= 0.0:
		n.hp -= gm / 60.0 * float(GameData.b("starve_damage_per_hour"))
		if n.hp <= 0.0:
			kill(n, "starvation")
			return
	n.attack_cd = maxf(0.0, n.attack_cd - dt)
	if n.target != -1:
		brain.fight(n, dt)
		return
	if n.plan.is_empty():
		brain.decide(n)
	_run_plan(n, dt, gm)


func _run_plan(n: NPC, dt: float, gm: float) -> void:
	var guard := 0
	while not n.plan.is_empty() and guard < 4:
		guard += 1
		var s: Dictionary = n.plan[0]
		match s.k:
			"go":
				if _walk(n, s, dt):
					n.plan.pop_front()
					continue
				return
			"work":
				n.anim = s.get("anim", "work")
				if s.has("face"):
					n.facing = (Vector2(s.face) + Vector2(0.5, 0.5) - n.pos)
				n.work_left -= gm
				if n.work_left <= 0.0:
					n.plan.pop_front()
					if s.has("act") and not brain.act(n, s.act, s.get("args", {})):
						n.plan.clear()
					if not n.plan.is_empty() and n.plan[0].k == "work":
						n.work_left = float(n.plan[0].min)
				return
			"do":
				n.plan.pop_front()
				if not brain.act(n, s.act, s.get("args", {})):
					n.plan.clear()
					return
				if not n.plan.is_empty() and n.plan[0].k == "work":
					n.work_left = float(n.plan[0].min)
			_:
				n.plan.pop_front()


## Move along a path to s.to; returns true on arrival.
func _walk(n: NPC, s: Dictionary, dt: float) -> bool:
	var to: Vector2i = s.to
	if not s.has("pathed"):
		s.pathed = true
		n.path = map.find_path(n.cell(), to)
		n.path_i = 0
		if n.path.is_empty() and n.cell() != to:
			n.plan.clear()
			n.doing = "lost"
			return false
	if n.path_i >= n.path.size():
		n.anim = "idle"
		if not n.plan.is_empty() and n.plan.size() > 1 and n.plan[1].k == "work":
			n.work_left = float(n.plan[1].min)
		return true
	var speed: float = float(GameData.b("walk_tiles_per_second")) * s.get("speed", 1.0)
	var budget := speed * dt
	n.anim = "carry" if n.inv.total() >= 4 and n.role == "adult" else "walk"
	while budget > 0.0 and n.path_i < n.path.size():
		var goal: Vector2 = n.path[n.path_i] + Vector2(0.5, 0.5)
		var d := goal - n.pos
		var l := d.length()
		if l <= budget:
			n.pos = goal
			budget -= l
			n.path_i += 1
		else:
			n.pos += d / l * budget
			n.facing = d
			budget = 0.0
	if n.path_i >= n.path.size():
		if n.plan.size() > 1 and n.plan[1].k == "work":
			n.work_left = float(n.plan[1].min)
		return true
	return false


# ---------------------------------------------------------------- player ---------------------
func _update_player(real_dt: float, gm: float) -> void:
	var p := player
	if not p.alive:
		return
	p.hunger = maxf(0.0, p.hunger - gm / 60.0 * float(GameData.b("player_hunger_per_hour")))
	if p.hunger <= 0.0:
		damage_player(gm / 60.0 * 3.0, "hunger")
	p.stamina = minf(p.stamina_cap(), p.stamina + real_dt * float(GameData.b("player_stamina_regen_per_second")))
	p.fireball_cd = maxf(0.0, p.fireball_cd - real_dt)
	p.attack_cd = maxf(0.0, p.attack_cd - real_dt)


func damage_player(amount: float, source: String) -> void:
	var p := player
	if not p.alive:
		return
	p.hp -= maxf(0.0, amount - p.defense() * 0.5) if source != "hunger" else amount
	if p.hp <= 0.0:
		p.alive = false
		p.deaths += 1
		note("%s %s died (%s)." % [p.name, p.family, source])


## Permanent death: the next of the family line takes over. The world is not reset.
## Decision (recorded in docs/BUILD_DECISIONS.md): the heir keeps the house, the chest and half
## of each skill's experience; what the dead carried stays where they fell.
## The starting kit (balance.json): coins, health and the few things a wanderer carries. A new
## player starts with it, and so does every heir (owner rule: an heir inherits only this).
func give_start_kit(p: PlayerState) -> void:
	p.coins = int(GameData.b("start_coins_player"))
	p.max_hp = float(GameData.b("player_max_hp"))
	p.hp = p.max_hp
	var kit: Dictionary = GameData.b("player_start_items")
	for id in kit:
		p.inv.add(id, int(kit[id]))
	p.armor = GameData.b("player_start_armor")


## Permadeath. What the dead carried lies where they fell, for anyone to take, the heir too. The
## heir keeps the family's house, chest and plots, starts every skill from nothing and carries
## only the starting kit (owner rule); its coins are new to the village, counted in coin_sources.
func continue_as_heir() -> void:
	var p := player
	var bag := Inventory.new()
	for id in p.inv.items:
		bag.add(id, p.inv.items[id])
	if bag.total() > 0 or p.coins > 0:
		loot.append({"pos": p.pos, "inv": bag, "coins": p.coins, "from": "%s %s" % [p.name, p.family]})
	var heir := PlayerState.new()
	heir.family = p.family
	heir.generation = p.generation + 1
	heir.name = ["Alys", "Hob", "Maud", "Piers", "Emma", "Jack", "Agnes", "Will"][(p.generation) % 8]
	heir.sprite = p.heir_sprite
	heir.heir_sprite = p.sprite
	heir.home = p.home
	heir.chest = p.chest
	heir.chest_stolen = p.chest_stolen
	heir.plots = p.plots
	heir.deaths = p.deaths
	give_start_kit(heir)
	coin_sources += heir.coins
	heir.spells = {}
	if heir.home != "" and buildings.has(heir.home):
		var b: Dictionary = buildings[heir.home]
		heir.pos = Vector2(b.door[0] + 0.5, b.door[1] + 0.5)
	else:
		var sp = map.data.spawns.player
		heir.pos = Vector2(int(sp[0]) + 0.5, int(sp[1]) + 0.5)
	player = heir
	quests.start_story()                   # the heir must seek the sage again: spells are not inherited
	# whoever was fighting the dead player has no quarrel with the heir
	for n: NPC in npcs:
		if n.target == -2:
			n.target = -1
			n.plan.clear()
	note("%s %s (generation %d) takes up the family's life." % [heir.name, heir.family, heir.generation])


# ---------------------------------------------------------------- economy --------------------
## Atomic sale: either goods and coins both move or nothing does. Parties are NPC or PlayerState.
func trade(buyer: Object, seller: Object, id: String, qty: int, price_each: int) -> bool:
	var total := qty * price_each
	if qty <= 0 or price_each < 0 or buyer == seller:
		return false
	if int(buyer.coins) < total or not seller.inv.has(id, qty) or not buyer.inv.can_add(id):
		return false
	seller.inv.remove(id, qty)
	buyer.inv.add(id, qty)
	buyer.coins -= total
	seller.coins += total
	if buyer is NPC:
		buyer.spent += total
	if seller is NPC:
		seller.earned += total
	return true


## Move items between two inventories without money (gifts, deposits, pantry).
func transfer(from: Inventory, to: Inventory, id: String, qty: int) -> bool:
	if not from.has(id, qty) or not to.can_add(id):
		return false
	from.remove(id, qty)
	to.add(id, qty)
	return true


func sell_price(vendor: NPC, id: String) -> int:
	var stock := vendor.inv.count(id)
	var m := clampf(1.5 - 0.05 * stock, float(GameData.b("price_min")) + 0.2, float(GameData.b("price_max")))
	return maxi(1, roundi(GameData.value(id) * m))


func buy_price(vendor: NPC, id: String) -> int:
	var stock := vendor.inv.count(id)
	var m := clampf(1.2 - 0.04 * stock, 0.4, 1.2) * float(GameData.b("sell_ratio"))
	return maxi(1, roundi(GameData.value(id) * m))


func player_price_factor(buying: bool) -> float:
	var lv := player.level("trading")
	var f := 0.0
	if lv >= 2:
		f = 0.05
	if lv >= 3:
		f = 0.10
	return 1.0 - f if buying else 1.0 + f


func total_coins() -> int:
	var n := player.coins + treasury
	for a: NPC in npcs:
		n += a.coins
	for l in loot:
		n += int(l.coins)
	return n


# ---------------------------------------------------------------- resources ------------------
func deposit_at(c: Vector2i) -> Dictionary:
	for d in deposits:
		if d.x == c.x and d.y == c.y:
			return d
	return {}


func tree_at(c: Vector2i) -> Dictionary:
	for t in trees:
		if t.x == c.x and (t.y == c.y or t.y - 1 == c.y):
			return t
	return {}


## Take one unit from a deposit. Returns the ore id or "" if it is exhausted.
func mine_unit(d: Dictionary) -> String:
	if d.is_empty() or int(d.amount) <= 0:
		return ""
	d.amount = int(d.amount) - 1
	if d.amount == 0:
		tile_changed.emit(Vector2i(d.x, d.y), "below", map.data.tiles.depleted_rock)
		note("A %s seam at the mine is worked out." % GameData.item_name(d.ore).to_lower())
	return d.ore


## Fell a grown tree: returns the number of logs (0 if it is not grown).
func fell(t: Dictionary, bonus: int) -> int:
	if t.is_empty() or t.state != "grown":
		return 0
	t.state = "stump"
	var r: Array = GameData.b("tree_regrow_days")
	t.regrow = day() + rng.randi_range(int(r[0]), int(r[1]))
	tile_changed.emit(Vector2i(t.x, t.y), "below", t.trunk)       # the stump under the canopy
	tile_changed.emit(Vector2i(t.x, t.y - 1), "above", -1)
	tile_changed.emit(Vector2i(t.x, t.y), "above", -1)
	map.set_solid(Vector2i(t.x, t.y), false)
	return 4 + bonus


func nearest_tree(from: Vector2i, max_d := 60.0) -> Dictionary:
	var best := {}
	var bd := max_d
	for t in trees:
		if t.state != "grown" or t.get("claimed", -1) != -1:
			continue
		var d := from.distance_to(Vector2i(t.x, t.y))
		if d < bd:
			bd = d
			best = t
	return best


func nearest_deposit(from: Vector2i, ores: Array) -> Dictionary:
	var best := {}
	var bd := 1e9
	for dp in deposits:
		if int(dp.amount) <= 0 or not ores.has(dp.ore):
			continue
		var d := from.distance_to(Vector2i(dp.x, dp.y))
		if d < bd:
			bd = d
			best = dp
	return best


func _field_tiles(f: Dictionary) -> void:
	var v: int = map.data.tiles.field[{"tilled": "tilled", "growing": "growing", "ripe": "ripe"}[f.state]]
	for j in int(f.h):
		for i in int(f.w):
			tile_changed.emit(Vector2i(int(f.x) + i, int(f.y) + j), "field", v)


func set_field(f: Dictionary, state: String) -> void:
	f.state = state
	if state == "growing":
		f.ready = minutes + float(GameData.b("field_grow_days")) * DAY
	_field_tiles(f)


# ---------------------------------------------------------------- people ---------------------
func npc(id: int) -> NPC:
	return by_id.get(id)


func kill(n: NPC, cause: String) -> void:
	if not n.alive:
		return
	n.alive = false
	n.hp = 0.0
	n.plan.clear()
	if cause.begins_with("slain"):
		bled.emit(n.pos)
	n.target = -1
	var heir := _heir(n)
	if heir != null and not cause.begins_with("slain"):
		_inherit(n, heir)
	elif n.inv.total() > 0 or n.coins > 0:
		# what someone slain carried lies where they fell (it can be looted), as it always has
		var bag := Inventory.new()
		for id in n.inv.items:
			bag.add(id, n.inv.items[id])
		n.inv = Inventory.new()
		loot.append({"pos": n.pos, "inv": bag, "coins": n.coins, "from": n.name})
		n.coins = 0
	var who := "%s %s" % [n.name, n.family] if n.family != "" else n.name
	var role := n.job if n.job != "" else n.role
	note("%s the %s has died (%s)." % [who, role, cause])
	if n.household >= 0:
		var hh: Dictionary = households[n.household]
		for m in hh.members:
			var o := npc(m)
			if o and o.alive:
				o.remember("%s died (%s)" % [n.name, cause])
	brain.on_death(n)
	npc_died.emit(n)


## Who inherits: a surviving adult of the household first, then an elder, then a child (lowest id
## first, so the choice is deterministic). Null when nobody in the household survives.
func _heir(n: NPC) -> NPC:
	if n.household < 0:
		return null
	for role in ["adult", "elder", "child"]:
		for m in households[n.household].members:
			var o := npc(m)
			if o and o.alive and o != n and o.role == role:
				return o
	return null


## Inheritance: food goes into the household's pantry, coins and everything else to the heir. Nothing
## is created or lost.
func _inherit(n: NPC, heir: NPC) -> void:
	var pantry: Inventory = households[n.household].pantry
	for id in n.inv.ids():
		var c := n.inv.count(id)
		if NPCBrain.FOOD.has(id):
			pantry.add(id, c)
		else:
			heir.inv.add(id, c)
		stat("inherited_items", c)
	n.inv = Inventory.new()
	if n.coins > 0:
		heir.coins += n.coins
		stat("inherited_coins", n.coins)
		n.coins = 0
	heir.remember("inherited what %s left" % n.name)


func stat(key: String, n := 1.0) -> void:
	stats[key] = float(stats.get(key, 0.0)) + n


func note(text: String) -> void:
	var line := "[%s] %s" % [clock_text(), text]
	log_lines.append(line)
	if log_lines.size() > 300:
		log_lines.pop_front()
	event.emit(line)


func alive_count(role := "") -> int:
	var c := 0
	for n: NPC in npcs:
		if n.alive and (role == "" or n.role == role):
			c += 1
	return c


## People within `r` tiles of a point who are awake and in the same place: inside the same building,
## or both outdoors (walls stand between a building's inside and the rest of the world).
func near(p: Vector2, r: float) -> Array:
	var out := []
	var here := place_of(p)
	for n: NPC in npcs:
		if n.alive and not asleep(n) and n.pos.distance_to(p) <= r and place_of(n.pos) == here:
			out.append(n)
	return out


# ---------------------------------------------------------------- interiors -------------------
## Every roofed building has an interior (village.json buildings[].interior, made by
## tools/build_village.py; a house the player builds gets the house stamp's): `area` the cells under
## its roof reached from its doors, `floor` the walkable ones, `roof` the cells its roof covers (the
## view fades them while the player is under them), `spots` the beds, tables, hearths and chests with
## the cell to use each from. Owner rule: one entry mechanic for everyone; people walk in through the
## door and stay visible to anyone inside the same building. Map data, not saved.
var interiors := {}                # building id -> interior
var place_ids: Array = []          # building ids, indexed by place_idx / roof_idx
var place_idx := PackedInt32Array()  # cell -> index of the building whose area holds it, -1 outdoors
var roof_idx := PackedInt32Array()   # cell -> index of the building whose roof covers it, -1 none


## The interior a building has: its own from the map, or a built house's from the house stamp.
func interior_for(b: Dictionary) -> Dictionary:
	for mb in map.data.buildings:
		if mb.id == b.id:
			return mb.get("interior", {})
	var stamp: Dictionary = map.data.stamps.house
	if b.type != "player_house" or not stamp.has("interior"):
		return {}
	var o := Vector2i(int(b.x), int(b.y))
	var si: Dictionary = stamp.interior
	var out := {}
	for k in ["doors", "area", "floor", "roof"]:
		out[k] = si[k].map(func(c): return [int(c[0]) + o.x, int(c[1]) + o.y])
	out.spots = si.spots.map(func(s):
		var d: Dictionary = s.duplicate(true)
		d.at = [int(s.at[0]) + o.x, int(s.at[1]) + o.y]
		d.use = [int(s.use[0]) + o.x, int(s.use[1]) + o.y]
		return d)
	return out


## (Re)build the interiors and the cell lookups (at start, on load, when a house is finished).
func index_interiors() -> void:
	interiors.clear()
	place_ids.clear()
	place_idx.resize(map.w * map.h)
	place_idx.fill(-1)
	roof_idx.resize(map.w * map.h)
	roof_idx.fill(-1)
	var ids := buildings.keys()
	ids.sort()
	for id in ids:
		var it := interior_for(buildings[id])
		if it.is_empty() or it.area.is_empty():
			continue
		interiors[id] = it
		place_ids.append(id)
		for c in it.roof:
			roof_idx[int(c[1]) * map.w + int(c[0])] = place_ids.size() - 1
		for c in it.area:
			place_idx[int(c[1]) * map.w + int(c[0])] = place_ids.size() - 1


func _cell_lookup(idx: PackedInt32Array, p: Vector2) -> String:
	var x := floori(p.x)
	var y := floori(p.y)
	if x < 0 or y < 0 or x >= map.w or y >= map.h or idx.is_empty():
		return ""
	var i := idx[y * map.w + x]
	return place_ids[i] if i >= 0 else ""


## The building whose inside a point (tiles) is in, "" outdoors.
func place_of(p: Vector2) -> String:
	return _cell_lookup(place_idx, p)


## The building whose roof covers a point, "" for none (inside it, or behind its eaves).
func roof_over(p: Vector2) -> String:
	return _cell_lookup(roof_idx, p)


func asleep(n: NPC) -> bool:
	return n.alive and n.anim == "sleep"


## A villager's own spot of a kind ("bed", "table", "chest", "hearth") in their home: the household
## shares them out by member order (beds first, then the straw pallets); {} if the home has none.
func home_spot(n: NPC, kind: String) -> Dictionary:
	var it: Dictionary = interiors.get(n.home, {})
	var mine := []
	for s in it.get("spots", []):
		if s.kind == kind:
			mine.append(s)
	if mine.is_empty():
		return {}
	var i := 0
	if n.household >= 0:
		i = maxi(0, (households[n.household].members as Array).find(n.id))
	return mine[i % mine.size()]


## The cell to go to for a home spot (the use cell), or the home's door when it has none.
func home_cell(n: NPC, kind: String) -> Vector2i:
	var s := home_spot(n, kind)
	if s.is_empty():
		return building_door(n.home)
	return Vector2i(int(s.use[0]), int(s.use[1]))


## Collision of a built house: the house stamp's (walls and furniture solid, floor walkable), or the
## whole footprint for a stamp without one; the doorway is open.
func _house_collision(b: Dictionary) -> void:
	var mask: Array = map.data.stamps.house.get("solid", [])
	for j in int(b.h) - 1:
		for i in int(b.w):
			var s := true if mask.is_empty() else str(mask[j])[i] == "1"
			map.set_solid(Vector2i(int(b.x) + i, int(b.y) + j), s)
	map.set_solid(Vector2i(int(b.door[0]), int(b.door[1]) - 1), false)


func building_door(id: String) -> Vector2i:
	var b: Dictionary = buildings[id]
	return Vector2i(int(b.door[0]), int(b.door[1]))


func station_use(id: String) -> Vector2i:
	var s: Dictionary = stations[id]
	return Vector2i(int(s.use[0]), int(s.use[1]))


func stations_of(kind: String) -> Array:
	var out := []
	for id in stations:
		if stations[id].type == kind:
			out.append(id)
	out.sort()
	return out


# ---------------------------------------------------------------- building -------------------
## Saves made before the village generator moved the building plots (they lay over houses b20-b22)
## keep the plots where they were. Move each plot to its place on the map, with its owner, its
## building site and the house built on it, and the player with them if they stood on it; the trees
## the generator cleared from the new plots go too. Nothing owned is lost.
func _move_plots_to_map(m: VillageMap) -> void:
	var placed := {}
	for mp in m.data.plots:
		placed[mp.id] = mp
	for p in plots:
		var mp: Dictionary = placed.get(p.id, {})
		if mp.is_empty() or (int(p.x) == int(mp.x) and int(p.y) == int(mp.y)):
			continue
		var old := Rect2(float(p.x), float(p.y), float(p.w), float(p.h))
		var shift := Vector2(int(mp.x) - int(p.x), int(mp.y) - int(p.y))
		p.x = int(mp.x)
		p.y = int(mp.y)
		p.door = [int(mp.door[0]), int(mp.door[1])]
		if buildings.has("house_" + p.id):
			var b: Dictionary = buildings["house_" + p.id]
			b.x = p.x
			b.y = p.y
			b.door = p.door.duplicate()
		if old.has_point(player.pos):
			player.pos += shift
		note("The manor's surveyor marked %s out anew, at the forest edge north of the east houses." % p.id)
	var on_map := {}
	for t in m.data.trees:
		on_map[Vector2i(int(t.x), int(t.y))] = true
	trees = trees.filter(func(t): return on_map.has(Vector2i(int(t.x), int(t.y))))


func plot(id: String) -> Dictionary:
	for p in plots:
		if p.id == id:
			return p
	return {}


func start_site(p: Dictionary) -> void:
	var cost: Dictionary = (GameData.b("house_cost") as Dictionary).duplicate()
	p.site = {"cost": cost, "need": cost.duplicate(), "done": false}
	var frame: int = map.data.tiles.frame
	tile_changed.emit(Vector2i(int(p.x) + 4, int(p.y) + 8), "below", frame)
	note("A building site is marked out on %s." % p.id)


## Deliver materials from `inv` to a site; returns true when the house is complete.
func deliver(p: Dictionary, inv: Inventory) -> bool:
	if p.site.is_empty() or p.site.done:
		return false
	var need: Dictionary = p.site.need
	for id in need.keys():
		var n := mini(int(need[id]), inv.count(id))
		if n > 0:
			inv.remove(id, n)
			need[id] = int(need[id]) - n
			if need[id] <= 0:
				need.erase(id)
	if need.is_empty():
		p.site.done = true
		var b := {"id": "house_" + p.id, "type": "player_house", "x": p.x, "y": p.y, "w": p.w, "h": p.h,
				  "door": p.door, "name": "%s family house" % player.family}
		buildings[b.id] = b
		_house_collision(b)
		index_interiors()
		building_added.emit(b)
		note("The %s is finished." % b.name)
		return true
	return false


## What a site has had delivered so far, item -> count (sites from older saves have no "cost":
## the house cost is assumed).
func site_delivered(p: Dictionary) -> Dictionary:
	var cost: Dictionary = p.site.get("cost", GameData.b("house_cost"))
	var out := {}
	for id in cost:
		var n := int(cost[id]) - int(p.site.need.get(id, 0))
		if n > 0:
			out[id] = n
	return out


## How far a site is, 0..1, by loads delivered out of all it needs.
func site_progress(p: Dictionary) -> float:
	if p.site.is_empty():
		return 0.0
	if p.site.done:
		return 1.0
	var cost: Dictionary = p.site.get("cost", GameData.b("house_cost"))
	var total := 0
	for id in cost:
		total += int(cost[id])
	var given := 0
	var got := site_delivered(p)
	for id in got:
		given += int(got[id])
	return float(given) / float(maxi(total, 1))


## Give up an unfinished site (owner rule: cancelling returns everything). Every delivered load goes
## back into `inv`; what it has no room for is left in a bundle at the plot's door. The frame comes
## down and the plot stays the owner's. Returns what was given back.
func cancel_site(p: Dictionary, inv: Inventory) -> Dictionary:
	if p.site.is_empty() or p.site.done:
		return {}
	var back := site_delivered(p)
	var left := Inventory.new()
	for id in back:
		if not inv.add(id, int(back[id])):
			left.add(id, int(back[id]))
	if not left.items.is_empty():
		loot.append({"pos": Vector2(float(p.door[0]) + 0.5, float(p.door[1]) + 0.5), "inv": left, "coins": 0, "from": "your building site"})
	p.site = {}
	tile_changed.emit(Vector2i(int(p.x) + 4, int(p.y) + 8), "below", -1)
	note("The building site on %s was given up; its materials were taken back." % p.id)
	return back


# ---------------------------------------------------------------- the player's actions -------
## Take crop from a ripe field: the player gathers a handful at a time, a farmer the rest. Returns
## the wheat taken. A field with nothing left is tilled again.
func take_crop(f: Dictionary, most: int) -> int:
	if f.state != "ripe":
		return 0
	var n := mini(most, int(f.get("crop", GameData.b("field_yield"))))
	f.crop = int(f.get("crop", GameData.b("field_yield"))) - n
	stat("made_wheat", n)
	if int(f.crop) <= 0:
		set_field(f, "tilled")
	return n


## The player harvests a handful from a field. A field is the farmers' who work it: taking from it
## without being one of them is theft, and anyone within sight remembers it.
func player_harvest(f: Dictionary) -> int:
	var n := take_crop(f, int(GameData.b("harvest_handful")))
	if n <= 0:
		return 0
	player.inv.add("wheat", n)
	if not f.owner.is_empty():
		var victim: NPC = null
		for o in f.owner:
			var fo := npc(int(o))
			if fo and fo.alive:
				victim = fo
				break
		if victim:
			player.mark_stolen("wheat", victim.id, n)
		witness("theft", "%d wheat from %s" % [n, f.id], victim, {"wheat": n})
	return n


## Record what the village saw the player do: people within sight (awake, and in the same building as
## the player or, outdoors, outside: World.near) remember it,
## and so does the victim. A guard among them stops the player (guard_confront): `taken` (item ->
## count) goes back into `back`, or to the victim. `deed` is what they saw, "take <what>" by default.
## Returns how many saw it; what a guard said is in last_guard.
func witness(kind: String, what: String, victim: NPC, taken := {}, back: Inventory = null, deed := "") -> int:
	var seen := []
	var guard: NPC = null
	last_guard = ""
	for n: NPC in near(player.pos, float(GameData.b("witness_radius"))):
		if n.role != "bandit":
			seen.append(n)
			n.remember("saw %s %s %s" % [player.name, player.family, deed if deed != "" else "take " + what])
			if n.job == "guard" and n.target == -1 and (guard == null or n.pos.distance_to(player.pos) < guard.pos.distance_to(player.pos)):
				guard = n
	if victim and not seen.has(victim) and deed == "":
		victim.remember("found %s missing" % what)
	player.crimes.append({"day": day(), "kind": kind, "what": what, "victim": victim.id if victim else -1, "witnesses": seen.size()})
	if seen.size() > 0:
		note("%s %s was seen %s%s." % [player.name, player.family, ("taking " + what) if deed == "" else deed.replace("try to", "trying to"),
				(" (" + victim.name + " " + victim.family + "'s)") if victim and deed == "" else ""])
	stat("player_" + kind)
	if guard:
		last_guard = guard_confront(guard, taken, back, victim)
	return seen.size()


# ---------------------------------------------------------------- theft, shops, containers -----
## What the last guard to stop the player said ("" if none); main shows it.
var last_guard := ""


## A guard stops the player (theft seen, a pocket picked, stolen goods offered for sale; agent
## proposal): what was taken goes back where it came from (`back`) or to its owner, and the player
## pays `theft_fine` to the manor's treasury. One who cannot pay it all pays what they have and the
## guard comes after them, as for an attack (main.gd::_crime). Coins and goods only move.
func guard_confront(g: NPC, taken: Dictionary, back: Inventory, owner: NPC) -> String:
	var returned := []
	for id in taken:
		var k := mini(int(taken[id]), player.inv.count(id))
		var to: Inventory = back if back != null else (owner.inv if owner and owner.alive else null)
		if k > 0 and to != null and to.can_add(id):
			player.inv.remove(id, k)
			to.add(id, k)
			player.unmark(id, owner.id if owner else -1, k)
			returned.append("%d %s" % [k, GameData.item_name(id).to_lower()])
	for slot in ["weapon", "armor", "tool"]:
		if player.get(slot) != "" and not player.inv.has(player.get(slot)):
			player.set(slot, "")
	var fine := int(GameData.b("theft_fine"))
	var paid := mini(fine, player.coins)
	player.coins -= paid
	treasury += paid
	stat("gov_fines", paid)
	g.remember("caught %s %s stealing" % [player.name, player.family])
	var who := "%s %s" % [g.name, g.family]
	var text := "The guard %s stops you." % who
	if not returned.is_empty():
		text += " The %s goes back to %s." % [", ".join(returned), "its owner" if owner == null else owner.name]
	text += " You pay a fine of %d coins to the manor." % paid if paid == fine else " You can pay only %d of the %d coins' fine: %s draws a weapon!" % [paid, fine, g.name]
	if paid < fine:
		g.target = -2
	note("The guard %s stopped %s %s for theft%s." % [who, player.name, player.family, " and fined them %d coins" % paid if paid > 0 else ""])
	return text


## The nearest guard on duty (out and not fighting) within `r` tiles of a point, or null.
func guard_near(at: Vector2, r: float) -> NPC:
	var best: NPC = null
	for n: NPC in near(at, r):
		if n.job == "guard" and n.target == -1 and (best == null or n.pos.distance_to(at) < best.pos.distance_to(at)):
			best = n
	return best


## Containers (village.json "containers", made by tools/build_village.py from the crates, barrels and
## dishes Shade drew). Ownership model (agent proposal; the owner's rule that they hold their owners'
## stock): a crate or barrel by a house IS its household's pantry; one in or by the tavern holds the
## tavern keeper's stock (the keeper's own goods); the one beside a stall, and the stall itself when
## its merchant is away, hold the merchant's stock. Only a tavern table has goods of its own: a dish
## or mug a keeper set out from their stock while the tavern is open, cleared back to them at closing
## (saved). So every good in a container is still exactly one owner's: nothing is made or lost.
var containers: Array = []         # {id, kind: crate|barrel|table, x, y, at: building or stall id, dish; tables: inv, keeper}


func _load_containers(m: VillageMap, saved: Array) -> void:
	containers.clear()
	var state := {}
	for s in saved:
		state[str(s.id)] = s
	for c in m.data.get("containers", []):
		var cd: Dictionary = c.duplicate(true)
		cd.x = int(cd.x)
		cd.y = int(cd.y)
		if cd.kind == "table":
			var s: Dictionary = state.get(cd.id, {})
			cd.inv = Inventory.from_dict(s.get("inv", {}))
			cd.keeper = int(s.get("keeper", -1))
			state.erase(cd.id)
		containers.append(cd)
	# a table the map no longer has gives its dish back to the keeper who set it out
	for id in state:
		var k := npc(int(state[id].get("keeper", -1)))
		if k == null or not k.alive:
			k = tavern_keeper()
		var inv := Inventory.from_dict(state[id].get("inv", {}))
		if k:
			for item in inv.ids():
				k.inv.add(item, inv.count(item))


func _containers_to_dict() -> Array:
	var out := []
	for c in containers:
		if c.kind == "table":
			out.append({"id": c.id, "inv": c.inv.to_dict(), "keeper": c.keeper})
	return out


func container(id: String) -> Dictionary:
	for c in containers:
		if c.id == id:
			return c
	return {}


## The tavern keeper who keeps the tavern's stock: the first alive one, by id.
func tavern_keeper() -> NPC:
	for n: NPC in npcs:
		if n.alive and n.job == "tavernkeeper":
			return n
	return null


## The household living in a building (-1 if nobody alive does).
func household_in(building: String) -> int:
	for hh in households:
		if hh.home == building:
			for m in hh.members:
				var o := npc(int(m))
				if o and o.alive:
					return int(hh.id)
	return -1


func _is_tavern(at: String) -> bool:
	return buildings.has(at) and buildings[at].type == "tavern"


## The goods a container holds (see `containers`), or null when nobody owns it now (an empty house,
## a stall without a merchant, a tavern without keepers).
func container_store(c: Dictionary) -> Inventory:
	if c.kind == "table":
		return c.inv
	var o := container_owner(c)
	if o == null:
		return null
	if stalls.has(c.at) or _is_tavern(c.at):
		return o.inv
	return households[o.household].pantry


## Whose goods they are: the one who notices them missing and whose they are if sold back.
func container_owner(c: Dictionary) -> NPC:
	if stalls.has(c.at):
		var m := npc(int(stalls[c.at].owner))
		return m if m and m.alive else null
	if _is_tavern(c.at):
		if c.kind == "table":
			var k := npc(int(c.get("keeper", -1)))
			if k and k.alive:
				return k
		return tavern_keeper()
	var h := household_in(c.at)
	if h < 0:
		return null
	for role in ["adult", "elder", "child"]:
		for m in households[h].members:
			var o := npc(int(m))
			if o and o.alive and o.role == role:
				return o
	return null


## "the tavern's", "Ellen Mercer's", "the Reed household's" (for prompts and messages).
func container_whose(c: Dictionary) -> String:
	if _is_tavern(c.at):
		return "the tavern's"
	var o := container_owner(c)
	if o == null:
		return "nobody's"
	if stalls.has(c.at):
		return "%s %s's" % [o.name, o.family]
	return "the %s household's" % households[o.household].family


## Where it is, for what witnesses remember: "a table in the tavern", "Ellen Mercer's stall".
func container_place(c: Dictionary) -> String:
	if _is_tavern(c.at):
		return "a table in the tavern" if c.kind == "table" else "the tavern's stores"
	if stalls.has(c.at):
		return container_whose(c) + " stall"
	return "%s %s" % [container_whose(c), c.kind]


## What can be taken from it, item ids in order (a merchant's or keeper's work tools are not stock).
func container_goods(c: Dictionary) -> Array:
	var store := container_store(c)
	if store == null:
		return []
	if c.kind != "table" and (stalls.has(c.at) or _is_tavern(c.at)):
		return brain.for_sale(container_owner(c))
	return store.ids()


## The item one take takes: the one there is most of (the first by id on a tie).
func container_pick(c: Dictionary) -> String:
	var store := container_store(c)
	var best := ""
	for id in container_goods(c):
		if best == "" or store.count(id) > store.count(best):
			best = id
	return best


## The player takes one item from a container that is not theirs: theft (owner rule), witnessed like
## a field's wheat, and the item is marked as stolen from its owner. Returns the item taken, "" if
## there was nothing, or "full" if the pack has no room.
func player_take(c: Dictionary) -> String:
	var id := container_pick(c)
	if id == "":
		return ""
	if not player.inv.can_add(id):
		return "full"
	var store := container_store(c)
	var victim := container_owner(c)
	store.remove(id)
	player.inv.add(id)
	if victim:
		player.mark_stolen(id, victim.id, 1)
	witness("theft", "%s from %s" % [GameData.item_name(id).to_lower(), container_place(c)], victim, {id: 1}, store)
	if c.kind == "table":
		show_tables()
	return id


## Food set out on the tavern's tables: hourly while the tavern is open (tavern_hours), each empty
## table gets one dish or mug of its kind from a keeper who has more than `table_keep` of it (else
## any cooked food they have to spare); at closing every table is cleared back to its keeper.
func serve_tables() -> void:
	var hours: Array = GameData.b("tavern_hours")
	var open := hour() >= float(hours[0]) and hour() < float(hours[1])
	var keep := int(GameData.b("table_keep"))
	var keepers := []
	for n: NPC in npcs:
		if n.alive and n.job == "tavernkeeper":
			keepers.append(n)
	var turn := 0                      # the keepers take the tables in turn
	for c in containers:
		if c.kind != "table":
			continue
		turn += 1
		if not open:
			if c.inv.total() > 0:
				var k := npc(int(c.keeper))
				if (k == null or not k.alive) and not keepers.is_empty():
					k = keepers[0]
				if k:
					for id in c.inv.ids():
						transfer(c.inv, k.inv, id, c.inv.count(id))
			continue
		if c.inv.total() > 0:
			continue
		for i in keepers.size():
			var k: NPC = keepers[(turn + i) % keepers.size()]
			var dish: String = c.dish if k.inv.count(c.dish) > keep else ""
			if dish == "":
				for f in NPCBrain.COOKED:
					if k.inv.count(f) > keep:
						dish = f
						break
			if dish != "":
				transfer(k.inv, c.inv, dish, 1)
				c.keeper = k.id
				break
	show_tables()


## Draw each table's dish while it has food on it, and the bare table when it has none (the tile
## Shade drew there, recorded in village.json, in its layer: tile_changed kind = that layer).
func show_tables() -> void:
	for c in containers:
		if c.kind == "table" and c.has("tile"):
			tile_changed.emit(Vector2i(c.x, c.y), str(c.layer), int(c.tile) if c.inv.total() > 0 else -1)


## Food on the tavern's tables (for the village's food reckoning).
func table_food(id: String) -> int:
	var n := 0
	for c in containers:
		if c.kind == "table":
			n += c.inv.count(id)
	return n


## Where a shopkeeper serves: the tavern counter or their stall (tile centre), INF for anyone else.
func shop_post(n: NPC) -> Vector2:
	if n.job == "tavernkeeper" and stations.has(n.workplace):
		return Vector2(station_use(n.workplace)) + Vector2(0.5, 0.5)
	if n.job == "merchant" and stalls.has(n.workplace) and int(stalls[n.workplace].owner) == n.id:
		var s: Dictionary = stalls[n.workplace]
		return Vector2(int(s.use[0]) + 0.5, int(s.use[1]) + 0.5)
	return Vector2.INF


## A shopkeeper standing at their counter or stall: they always serve the player.
func at_post(n: NPC) -> bool:
	var at := shop_post(n)
	return n.alive and not asleep(n) and n.target == -1 and at != Vector2.INF and n.pos.distance_to(at) <= 2.5


## Who serves at a counter (a tavern_counter station id) or a stall (a stall id) now, or null.
func shopkeeper_at(post: String) -> NPC:
	var best: NPC = null
	for n: NPC in npcs:
		if n.workplace == post and at_post(n) and (best == null or n.id < best.id):
			best = n
	return best


## "tavern", "food stall": the shop's name in prompts.
func shop_name(n: NPC) -> String:
	if n.job == "tavernkeeper":
		return "tavern"
	return {"raw": "ore and timber stall", "food": "food stall", "goods": "tools and arms stall"}.get(stalls[n.workplace].kind, "stall")


## The player tries to pick the pocket of the villager beside them (owner rule). The chance grows
## with Stealth (pickpocket_chance + pickpocket_chance_per_level a level, at most
## pickpocket_chance_max). Success: a few coins, or one thing they carry (marked as stolen from them),
## and they find it missing later. Caught: they remember it, anyone in sight sees the try, and a guard
## who sees it or is within `guard_call_radius` of their shout stops the player (guard_confront).
## Returns {ok, what, text}.
func pickpocket(n: NPC) -> Dictionary:
	if not n.alive or asleep(n) or n.role == "bandit":
		return {"ok": false, "what": "", "text": "There is nobody to rob."}
	var lv := player.level("stealth")
	var chance := minf(float(GameData.b("pickpocket_chance")) + float(GameData.b("pickpocket_chance_per_level")) * (lv - 1), float(GameData.b("pickpocket_chance_max")))
	var who := "%s %s" % [n.name, n.family]
	last_guard = ""
	if rng.randf() < chance:
		var what := ""
		if n.coins > 0:
			var k := mini(n.coins, rng.randi_range(1, int(GameData.b("pickpocket_coins_max"))))
			n.coins -= k
			player.coins += k
			what = "%d coin%s" % [k, "" if k == 1 else "s"]
		else:
			var ids := []
			for id in n.inv.ids():
				if not NPCBrain.KEEPS.get(n.job, []).has(id) and player.inv.can_add(id):
					ids.append(id)
			if ids.is_empty():
				return {"ok": true, "what": "", "text": "%s's pockets are empty." % n.name}
			var id: String = ids[rng.randi() % ids.size()]
			n.inv.remove(id)
			player.inv.add(id)
			player.mark_stolen(id, n.id, 1)
			what = "1 " + GameData.item_name(id).to_lower()
		n.remember("found %s missing" % what)
		player.crimes.append({"day": day(), "kind": "pickpocket", "what": "%s from %s" % [what, who], "victim": n.id, "witnesses": 0})
		stat("player_pickpocket")
		return {"ok": true, "what": what, "text": "You lift %s from %s unseen." % [what, who]}
	n.remember("caught %s %s picking my pocket" % [player.name, player.family])
	var seen := witness("pickpocket", "a try at %s's purse" % who, n, {}, null, "try to pick %s's pocket" % who)
	var text := "%s catches your hand in their pocket!" % n.name
	if last_guard == "":
		var g := guard_near(n.pos, float(GameData.b("guard_call_radius")))
		if g:
			last_guard = guard_confront(g, {}, null, n)
	if last_guard != "":
		text += " " + last_guard
	elif seen > 1:
		text += " Others saw it too."
	return {"ok": false, "what": "", "text": text}


## The player sells one `id` to `buyer` at `price` (the trade window). Stolen goods (agent proposal):
## the owner, or anyone of the owner's household, knows their own: they refuse, remember it, and a guard
## within `guard_call_radius` of them stops the player. Sold to anyone else they fetch the usual price
## (the buyer cannot tell), but a guard within sight may question the seller (guard_question_chance):
## the piece goes back to its owner and the fine is paid. Marked goods are sold first.
## Returns {result: sold|recognised|questioned|failed, text}.
func player_sell(buyer: NPC, id: String, price: int) -> Dictionary:
	player.trim_stolen()
	var marks: Dictionary = player.stolen.get(id, {})
	var owners := marks.keys()
	owners.sort_custom(func(a, b): return int(a) < int(b))
	last_guard = ""
	for o in owners:
		var owner := npc(int(o))
		if owner and (owner == buyer or (owner.household >= 0 and owner.household == buyer.household)):
			var item := GameData.item_name(id).to_lower()
			buyer.remember("caught %s %s selling me my own %s" % [player.name, player.family, item])
			player.crimes.append({"day": day(), "kind": "fencing", "what": "%s back to %s %s" % [item, buyer.name, buyer.family], "victim": owner.id, "witnesses": 1})
			stat("player_fencing")
			note("%s %s knew the %s %s %s offered was theirs." % [buyer.name, buyer.family, item, player.name, player.family])
			var text := "\"That %s is ours! You stole it!\" %s will not buy it." % [item, buyer.name]
			var g := guard_near(buyer.pos, float(GameData.b("guard_call_radius")))
			if g:
				last_guard = guard_confront(g, {id: int(marks[o])}, null, owner)
				text += " " + last_guard
			return {"result": "recognised", "text": text}
	if not owners.is_empty():
		var g := guard_near(player.pos, float(GameData.b("witness_radius")))
		if g and rng.randf() < float(GameData.b("guard_question_chance")):
			var owner := npc(int(owners[0]))
			g.remember("questioned %s %s about stolen %s" % [player.name, player.family, GameData.item_name(id).to_lower()])
			last_guard = guard_confront(g, {id: 1}, null, owner)
			return {"result": "questioned", "text": "The guard %s asks where you got that %s. %s" % [g.name, GameData.item_name(id).to_lower(), last_guard]}
	if not trade(buyer, player, id, 1, price):
		return {"result": "failed", "text": "They cannot afford it right now."}
	if not owners.is_empty():
		player.unmark(id, int(owners[0]), 1)
	return {"result": "sold", "text": ""}


func player_eat(id: String) -> bool:
	var it: Dictionary = GameData.item(id)
	if not it.has("food") or not player.inv.remove(id):
		return false
	player.hunger = minf(100.0, player.hunger + float(it.food))
	if it.has("harm"):
		damage_player(float(it.harm), "spoiled food")
	stat("eaten_food", float(it.food))
	stat("eaten_" + id)
	return true


## Hold a weapon, wear armour, a cap or helmet, an amulet or a ring, or take a tool in hand: the
## item goes in the slot its type names (PlayerState.GEAR); "" in a slot means nothing there.
func player_equip(id: String) -> bool:
	var slot: String = GameData.item(id).get("type", "")
	if not player.inv.has(id) or not slot in PlayerState.GEAR:
		return false
	player.set(slot, id)
	player.fit_caps()
	return true


func player_unequip(slot: String) -> void:
	player.set(slot, "")
	player.fit_caps()


## Drop items on the ground where the player stands: they can be picked up again by anyone looking.
func player_drop(id: String, qty: int) -> bool:
	if qty <= 0 or not player.inv.remove(id, qty):
		return false
	for slot in PlayerState.GEAR:
		if player.get(slot) == id and not player.inv.has(id):
			player.set(slot, "")
	player.fit_caps()
	var bag := Inventory.new()
	bag.add(id, qty)
	loot.append({"pos": player.pos + Vector2(0, 0.4), "inv": bag, "coins": 0, "from": "dropped by %s" % player.name})
	return true


## The player buys a building plot; the price goes to the manor's treasury.
func buy_plot(p: Dictionary) -> bool:
	if p.owner != "" or player.coins < int(p.price):
		return false
	player.coins -= int(p.price)
	treasury += int(p.price)
	p.owner = "player"
	player.plots.append(p.id)
	stat("gov_land_sales", float(p.price))
	note("%s %s bought %s from the manor." % [player.name, player.family, p.id])
	return true


## Break the world <-> brain reference cycle so a finished world is freed.
func dispose() -> void:
	brain = null
	fauna = null


# ---------------------------------------------------------------- save / load ----------------
func to_dict() -> Dictionary:
	var hh := []
	for h in households:
		var c: Dictionary = h.duplicate(true)
		c.pantry = h.pantry.to_dict()
		hh.append(c)
	var lt := []
	for l in loot:
		lt.append({"pos": [l.pos.x, l.pos.y], "inv": l.inv.to_dict(), "coins": l.coins, "from": l.from})
	var ns := []
	for n: NPC in npcs:
		ns.append(n.to_dict())
	return {
		"save_version": 4, "format": "mml-save/4", "seed": seed, "minutes": minutes,
		"treasury": treasury, "granary": granary.to_dict(), "last_reeve_day": last_reeve_day, "last_payday": last_payday,
		"village": {"format": map.data.format, "seed": map.data.seed},
		"npcs": ns, "households": hh, "buildings": buildings, "stalls": stalls, "trees": trees,
		"deposits": deposits, "fields": fields, "plots": plots, "loot": lt, "fauna": fauna.to_dict(),
		"player": player.to_dict(), "coin_sources": coin_sources, "log": log_lines, "quest_offers": quests.to_dict(),
		"sage_id": sage_id, "reeve_id": reeve_id, "containers": _containers_to_dict(),
	}


func load_dict(m: VillageMap, d: Dictionary) -> void:
	map = m
	seed = int(d.seed)
	rng.seed = seed + int(d.minutes)
	brain = NPCBrain.new(self)
	minutes = float(d.minutes)
	last_hour = int(minutes / 60.0)
	for s in m.data.stations:
		var st: Dictionary = s.duplicate(true)
		st.users = {}                  # npc id -> game minute their reservation lapses (capacity: st.get("capacity", 1))
		stations[st.id] = st
	buildings = d.buildings
	stalls = d.stalls
	trees = d.trees
	# a tree's tiles are map data, not state: take them from the map (saves made before the
	# two-tile trees hold other tiles and no bottom)
	var kinds := {}
	for t in m.data.trees:
		kinds[Vector2i(int(t.x), int(t.y))] = t
	for t in trees:
		var k: Dictionary = kinds.get(Vector2i(int(t.x), int(t.y)), {})
		if not k.is_empty():
			t.trunk = int(k.trunk)
			t.top = int(k.top)
			t.bottom = int(k.bottom)
	deposits = d.deposits
	fields = d.fields
	plots = d.plots
	coin_sources = int(d.coin_sources)
	log_lines = d.log
	sage_id = int(d.sage_id)
	reeve_id = int(d.reeve_id)
	for h in d.households:
		var c: Dictionary = h.duplicate(true)
		c.pantry = Inventory.from_dict(h.pantry)
		households.append(c)
	for l in d.loot:
		loot.append({"pos": Vector2(l.pos[0], l.pos[1]), "inv": Inventory.from_dict(l.inv), "coins": int(l.coins), "from": l.from})
	for nd in d.npcs:
		var n := NPC.from_dict(nd)
		npcs.append(n)
		by_id[n.id] = n
	player = PlayerState.from_dict(d.player)
	if d.has("treasury"):
		treasury = int(d.treasury)
		granary = Inventory.from_dict(d.granary)
		last_reeve_day = int(d.last_reeve_day)
		last_payday = int(d.last_payday)
	else:
		# save_version 1-2 (before the manor treasury): the reeve's coins were the village's funds;
		# they move into the treasury and the reeve keeps a purse. Total coins are unchanged. The
		# day's business is marked done if the save was made after 17:00 / 18:00.
		_open_treasury()
		last_reeve_day = day() if hour() >= 17.0 else day() - 1
		last_payday = day() if hour() >= 18.0 else day() - 1
	fauna = Fauna.new(self)
	if d.has("fauna"):
		fauna.load_dict(d.fauna)
	else:
		# save_version 1 (before animals): the deer count is dropped and the pens and woods are
		# stocked as in a new game. Nothing the player owned is lost.
		fauna.populate()
		_assign_keepers()
	bandit_camp = Vector2i(int(m.data.spawns.bandit_camp[0]), int(m.data.spawns.bandit_camp[1]))
	_guard_posts()
	# the tables' dishes are saved; a save from before containers gets its tables set from the
	# keepers' stock (the crates, barrels and stalls are their owners' stock, so they need nothing)
	_load_containers(m, d.get("containers", []))
	if not d.has("containers"):
		serve_tables()
	brain.dawn(false)
	quests = Quests.new(self)
	quests.load_dict(d.get("quest_offers", {}))      # older saves: no offers yet; the next dawn makes them
	quests.start_story()                             # saves from before the storyline get its quests
	_move_plots_to_map(m)
	# re-apply world changes to the collision map
	for t in trees:
		if t.state != "grown":
			map.set_solid(Vector2i(int(t.x), int(t.y)), false)
	for id in buildings:
		var b: Dictionary = buildings[id]
		if b.type == "player_house":
			_house_collision(b)
	index_interiors()
	if int(d.get("save_version", 1)) < 4:
		_move_indoors(d)


## Saves before interiors (save_version 1-3) had villagers "hidden" at home, standing on the door
## step: each is put inside their home, at their own bed (or the home's first spot), to go on from
## there. A later save holds where they really are.
func _move_indoors(d: Dictionary) -> void:
	for nd in d.npcs:
		var n := npc(int(nd.id))
		if n == null or not bool(nd.get("hidden", false)) or not interiors.has(n.home):
			continue
		var s := home_spot(n, "bed")
		var c := home_cell(n, "bed") if not s.is_empty() else Vector2i(int(interiors[n.home].floor[0][0]), int(interiors[n.home].floor[0][1]))
		n.pos = Vector2(c) + Vector2(0.5, 0.5)
		n.plan.clear()
