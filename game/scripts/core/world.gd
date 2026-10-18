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
	points += granary.count("wheat") * float(GameData.item("wheat").food)
	food_days = points / maxf(1.0, people * 24.0 * float(GameData.b("hunger_per_hour")))


func famine() -> bool:
	return food_days < float(GameData.b("famine_food_days"))


func _on_hour(h: int) -> void:
	_update_food_days()
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
	p.stamina = minf(100.0, p.stamina + real_dt * float(GameData.b("player_stamina_regen_per_second")))
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


## People within `r` tiles of a point (alive, visible).
func near(p: Vector2, r: float) -> Array:
	var out := []
	for n: NPC in npcs:
		if n.alive and not n.hidden and n.pos.distance_to(p) <= r:
			out.append(n)
	return out


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
	p.site = {"need": (GameData.b("house_cost") as Dictionary).duplicate(), "done": false}
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
		for j in int(p.h) - 1:
			for i in int(p.w):
				map.set_solid(Vector2i(int(p.x) + i, int(p.y) + j), true)
		map.set_solid(Vector2i(int(p.door[0]), int(p.door[1]) - 1), false)
		building_added.emit(b)
		note("The %s is finished." % b.name)
		return true
	return false


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
		witness("theft", "%d wheat from %s" % [n, f.id], victim)
	return n


## Record what the village saw the player do: people within sight (not asleep indoors) remember it,
## and so does the victim. Returns how many saw it.
func witness(kind: String, what: String, victim: NPC) -> int:
	var seen := []
	for n: NPC in near(player.pos, float(GameData.b("witness_radius"))):
		if n.role != "bandit":
			seen.append(n)
			n.remember("saw %s %s take %s" % [player.name, player.family, what])
	if victim and not seen.has(victim):
		victim.remember("found %s missing" % what)
	player.crimes.append({"day": day(), "kind": kind, "what": what, "victim": victim.id if victim else -1, "witnesses": seen.size()})
	if seen.size() > 0:
		note("%s %s was seen taking %s%s." % [player.name, player.family, what, (" (" + victim.name + " " + victim.family + "'s)") if victim else ""])
	stat("player_" + kind)
	return seen.size()


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


## Hold a weapon, wear armour or take a tool in hand; "" in a slot means nothing there.
func player_equip(id: String) -> bool:
	if not player.inv.has(id):
		return false
	match GameData.item(id).get("type", ""):
		"weapon":
			player.weapon = id
		"armor":
			player.armor = id
		"tool":
			player.tool = id
		_:
			return false
	return true


func player_unequip(slot: String) -> void:
	player.set(slot, "")


## Drop items on the ground where the player stands: they can be picked up again by anyone looking.
func player_drop(id: String, qty: int) -> bool:
	if qty <= 0 or not player.inv.remove(id, qty):
		return false
	for slot in ["weapon", "armor", "tool"]:
		if player.get(slot) == id and not player.inv.has(id):
			player.set(slot, "")
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
		"save_version": 3, "format": "mml-save/3", "seed": seed, "minutes": minutes,
		"treasury": treasury, "granary": granary.to_dict(), "last_reeve_day": last_reeve_day, "last_payday": last_payday,
		"village": {"format": map.data.format, "seed": map.data.seed},
		"npcs": ns, "households": hh, "buildings": buildings, "stalls": stalls, "trees": trees,
		"deposits": deposits, "fields": fields, "plots": plots, "loot": lt, "fauna": fauna.to_dict(),
		"player": player.to_dict(), "coin_sources": coin_sources, "log": log_lines, "quest_offers": quests.to_dict(),
		"sage_id": sage_id, "reeve_id": reeve_id,
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
			for j in int(b.h) - 1:
				for i in int(b.w):
					map.set_solid(Vector2i(int(b.x) + i, int(b.y) + j), true)
			map.set_solid(Vector2i(int(b.door[0]), int(b.door[1]) - 1), false)
