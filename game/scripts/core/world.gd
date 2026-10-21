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
##    consume their inputs (the player's approved skill effects, PL2-005, are the one exception: a saved
##    input and a bonus unit, counted as made_ like any recipe output), and only vanish by being eaten,
##    used up in a recipe or a building, worn out or left to spoil (a carcass, spoiled_);
##  - a deposit never yields more than its amount; dead people stay dead.

const PLANT_LAYER := "below1"      # the layer Shade drew the flowers and berry bushes in (village.json plants)
signal tile_changed(cell: Vector2i, kind: String, value: int)   # kind: below | above | path
signal tree_changed(t: Dictionary)                    # a tree's stage changed, it was felled, planted or cleared (the view redraws it)
signal tree_hit(t: Dictionary, side: int, hits: int)  # an axe blow that did not fell it: the cut mark, chips and leaves
signal tree_felled(t: Dictionary, side: int)          # a mature tree fell to the side (-1 left, 1 right) the blows came from
signal event(text: String)
signal npc_died(npc: NPC)
signal building_added(b: Dictionary)
signal bled(pos: Vector2)          # someone or something was slain here (drawn as blood; not saved)
signal level_tile_changed(level: int, cell: Vector2i, value: int)   # a seam below the surface changed (worked out): the level's view redraws it
signal player_level_changed(level: int)   # the player went through a portal (Main fades the surface or the level)
signal player_leveled(skill: String, level: int)   # DVW-A12 R6: player_xp raised a skill to a new level (Main shows the banner)

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
var stalls := {}                   # id -> dict (kind, owner, tenant: the merchant who keeps it)
var trees: Array = []              # the village's trees (Trees: the one tree model): {x, y, species, state, regrow, born, ...}.
                                   # (x, y) is the trunk's cell, the only solid one (growing and mature trees); the sprite is
                                   # drawn by TreeView and the characters walk behind its canopy. Trees the player planted
                                   # have planted: true. trunk/top/bottom are the old tile ids (map data), kept for the tests
var tree_damage := {}              # Vector2i -> {hits, side, at}: the axe blows a mature tree has taken (not saved: they heal)
var manor_orders: Array = []       # tools the manor paid a smith for in advance (EQ-19, OD-16 b): {smith, tool, for, paid, day}. Saved (older saves have none)
var vacancies: Array = []          # essential posts open after a death (B8-016, NPCBrain succession): {job, workplace, home, household, day, who}. Saved (older saves have none)
var deposits: Array = []           # {x, y, ore, amount}: the mine's seams (the sims, miners and the caravan's stone rule look at these only)
var boulders: Array = []           # the village's small grey boulders (B8-026): {x, y, ore: "stone", amount, boulder: true}, a few
                                   # pickaxe uses each, then gone (solid cleared). Found by deposit_at like a seam; the overworld's are Overworld.boulder_at
var plants: Array = []             # wild flowers and berry bushes (village generator v5): {id, x, y, kind, tile, state, regrow}.
                                   # state: ripe | picked (bare, ripe again on day `regrow`) | cleared (grubbed up for building).
                                   # The cell stays walkable; the tile is the plant's own, in layer below1.
var fields: Array = []             # {id, x, y, w, h, state, ready, owner, tenant}: worked by the farmers whose workplace it is
var plots: Array = []              # the land registry's parcels: {id, x, y, w, h, door, price, owner, tenant, rent,
                                   # due_day, arrears, missed, site, building} (scripts/core/property.gd)
var property: Property             # the manor's land office: sales, leases, rent, the land registry
var front_keepers := {}            # B14: house id -> the villager keeping its storefront now (not saved: a new evening picks again)
var business: Business             # the player's market stall and the villagers who buy from it (PL1-10)
var fitting: Fitting               # equipment the player places in their rooms: counters, shelves, stations (PL1-10 stage 3)
var counters: Counters             # skilled-trade counters: ring, the keeper walks over and serves (CTR-01..03, ARM-01)
var construction: Construction     # building kinds, placement, hired helpers, households that split
var loot: Array = []               # {pos: Vector2, inv: Inventory, coins, from}
var fauna: Fauna                   # livestock in the pens, wild animals in the woods
var farm: Farming                  # the player's field, pens and seeds (PL2-015, scripts/core/farming.gd)
var farm_plots: FarmPlots          # family farmland of any size, leased or bought, for every household (FARM-01..05, scripts/core/farm_plots.gd)
var treasury := 0                  # the manor's coins: kept by the reeve's office, not in anyone's purse
var granary := Inventory.new()     # the manor's grain, bought from farmers' surplus, given out as relief
var last_reeve_day := -1           # the day the reeve's evening business last ran (never twice a day)
var last_payday := -1              # the day wages were last paid
var player := PlayerState.new()
var coin_sources := 0              # coins that entered the village (caravan)
var caravan_purse := 0             # coins the caravan holds to spend on the village's goods (B7-014; starts at caravan_float); saved from version 9
var quests: Quests                 # side quests on offer (scripts/core/quests.gd)
var manor_work: ManorWork          # the reeve's jobs: the manor's goods carried and used (scripts/core/manor_work.gd)
var log_lines: Array = []
var profiling := false             # PERF-02: when true, prof collects microseconds per subsystem (diagnostics; changes nothing)
var prof := {}                     # subsystem -> {us, n}
var stats := {}                    # running ledger (food made, eaten, exported, meals missed ...) for diagnostics; not saved
var last_hour := -1
var guard_posts: Array = []        # patrol points
var bandit_camp := Vector2i.ZERO
var sage_id := -1
var reeve_id := -1
var detail_radius := 34.0          # tiles: NPCs nearer the player get every-frame updates
var brain
var chests: Chests            # PL2-002: storage units, locks and lockpicking
var carts: Carts              # B14: handcarts set down in the world (pulled storage)
var relations: Relations      # friendship, courting and marriage (CRT-01..07)
var contracts: Contracts      # CON-01: negotiated goods-procurement contracts (scripts/core/contracts.gd). Saved (older saves have none)
var underground: Underground  # MIN-A: the levels below the surface and their portals (generated from the seed, not saved)
var player_level := 0         # MIN-A: the depth the player is on (0 the surface, -1 the mine gallery); saved in "underground"
var villager_levels := [0]    # MIN-A: the levels villagers can reach; the surface until the NPC level router exists


func _init() -> void:
	GameData.ensure()


# ---------------------------------------------------------------- setup ----------------------
func setup(m: VillageMap, world_seed: int) -> void:
	map = m
	seed = world_seed
	rng.seed = world_seed
	m.overworld = Overworld.create(world_seed, m)
	brain = NPCBrain.new(self)
	chests = Chests.new(self)
	carts = Carts.new(self)
	relations = Relations.new(self)
	contracts = Contracts.new(self)
	property = Property.new(self)
	construction = Construction.new(self)
	business = Business.new(self)
	fitting = Fitting.new(self)
	counters = Counters.new(self)
	for b in m.data.buildings:
		buildings[b.id] = b.duplicate(true)
	for s in m.data.stations:
		var st: Dictionary = s.duplicate(true)
		st.users = {}                  # npc id -> game minute their reservation lapses (capacity: st.get("capacity", 1))
		stations[st.id] = st
	for i in m.data.stalls.size():
		var s: Dictionary = m.data.stalls[i].duplicate(true)
		s.kind = ["raw", "food", "goods"][i % 3]
		s.owner = MANOR                # the manor's market; Population lets each to its merchant
		s.tenant = ""
		stalls[s.id] = s
	Business.add_pitches(self, m)      # the manor's open pitches, for the player to rent (PL1-10)
	for t in m.data.trees + m.decor_trees():          # the woods, and the woodland at the map's edge: all one tree model
		trees.append(_new_tree(t))
	for t in trees:
		Trees.sync(t, minutes)
		m.set_solid(Vector2i(int(t.x), int(t.y)), Trees.solid(str(t.state)))
	_make_plants(m)
	season_plants()                    # SEED-03: the berry bushes are bare out of their seasons from the start
	for d in m.data.deposits:
		deposits.append({"x": int(d.x), "y": int(d.y), "ore": d.ore, "amount": int(d.amount)})
	underground = Underground.create(world_seed, m)     # MIN-A: hashed from the seed, no rng draw
	deposits.append_array(underground.seam_records())   # the gallery's seams: the same records, with their level
	_make_boulders(m)
	for f in m.data.fields:
		var fd: Dictionary = f.duplicate(true)
		fd.state = "ripe"
		fd.crop = int(GameData.b("field_yield"))
		fd.ready = 0.0
		fd.ripe_at = minutes             # the crop stands ripe, in sight, before the farmers cut it (field_ripe_wait_hours)
		fd.owner = MANOR               # the manor's open fields, worked by its farmers (field_workers)
		fd.tenant = ""
		fields.append(fd)
	for p in m.data.plots:
		var pd: Dictionary = p.duplicate(true)
		pd.owner = MANOR               # surveyed land for sale or lease
		pd.tenant = ""
		pd.site = {}
		pd.building = ""
		pd.price = property.land_price(int(pd.w), int(pd.h))
		plots.append(pd)
	bandit_camp = Vector2i(int(m.data.spawns.bandit_camp[0]), int(m.data.spawns.bandit_camp[1]))
	_guard_posts()
	Population.populate(self)
	_open_treasury()
	caravan_purse = int(GameData.b("caravan_float"))
	# the settlers' grain store: a finite stock of last year's harvest, 7 days of the village's food
	# (its need weighted by age: children eat less)
	granary.add("wheat", ceili(brain.village_day_food() * float(GameData.b("start_granary_days")) / 120.0))
	fauna = Fauna.new(self)
	farm = Farming.new(self)
	farm_plots = FarmPlots.new(self)
	fauna.populate()
	_assign_keepers()
	_init_ownership()
	var sp = m.data.spawns.player
	player.pos = Vector2(int(sp[0]) + 0.5, int(sp[1]) + 0.5)
	give_start_kit(player)
	Life.init_player(self)             # B8-029
	Skills.seed_villagers(self)        # PAR-01A: the settlers' history at their trades (only here and in an old save's migration)
	for n: NPC in npcs:
		by_id[n.id] = n
	index_interiors()
	_load_containers(m, [])
	serve_tables()                     # the tavern opens: the keepers set food out on its tables
	brain.dawn(false)                  # the first morning's snapshot of everyone's earnings
	quests = Quests.new(self)
	quests.refresh()
	quests.start_story()
	manor_work = ManorWork.new(self)
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
			set_tenant(pen, npc_ref(farmers[i].id))
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
	return Life.clock_text(minutes)               # "Spring, Year 1  Day 3  07:00" (B8-029)


func year() -> int:
	return Life.year(minutes)


func season() -> String:
	return Life.season(minutes)


## Age in years of someone born at game minute `born` (B8-029).
func age_years(born: float) -> float:
	return Life.age_years(born, minutes)


func is_night() -> bool:
	var h := hour()
	return h >= 21.0 or h < 5.5


# ---------------------------------------------------------------- update ---------------------
## Advance the world by `real_dt` seconds of play.
func update(real_dt: float) -> void:
	var gm: float = real_dt * float(GameData.b("game_minutes_per_second"))
	minutes += gm
	if map.overworld != null:
		map.overworld.clock = minutes
	var h := int(minutes / 60.0)
	var t := Time.get_ticks_usec() if profiling else 0
	if h != last_hour:
		last_hour = h
		_on_hour(h % 24)
		if profiling:
			t = _prof("hourly (incl. daily)", t)
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
	if profiling:
		t = _prof("villagers (all)", t)
	fauna.update(real_dt)
	if profiling:
		t = _prof("fauna", t)
	carts.update(real_dt)
	if profiling:
		t = _prof("carts", t)
	_update_player(real_dt, gm)
	if profiling:
		_prof("player", t)


## PERF-02: add the time since `t0` (microseconds) to subsystem `key`; returns now.
func _prof(key: String, t0: int) -> int:
	var now := Time.get_ticks_usec()
	var e: Dictionary = prof.get(key, {"us": 0, "n": 0})
	e.us += now - t0
	e.n += 1
	prof[key] = e
	return now


## Days of food the village holds for its people (all food in hands and pantries), updated hourly.
var food_days := 99.0


func _update_food_days() -> void:
	var points := 0.0
	# one valuation of food (NPCBrain.food_points: grain as cooked, raw meat as roasted for the logs held), so the
	# village's food days and famine read as a household's do (FSE-17; wheat counted at 20 here and 120 there before)
	var stores: Array = []
	for n: NPC in npcs:
		if n.alive and n.role != "bandit":
			stores.append(n.inv)
	for hh in households:
		stores.append(hh.pantry)
	stores.append(granary)                                              # wheat, and stores of a house fallen to the manor
	points += NPCBrain.store_points(stores)
	for f in NPCBrain.FOOD:
		points += table_food(f) * NPCBrain.food_points(f)
	if manor_work:
		points += manor_work.food_points()                              # grain the manor has bought or sent, on its way
	food_days = points / maxf(1.0, brain.village_day_food())          # children weighted by age


func famine() -> bool:
	return food_days < float(GameData.b("famine_food_days"))


func _on_hour(h: int) -> void:
	_grow_trees()
	farm.hour()                        # the player's crops (PL2-015)
	farm_plots.hour()                  # the households' farmland crops (FARM-03)
	_update_food_days()
	serve_tables()
	business.hour()                    # villagers walk to the player's open stall (PL1-10)
	carts.hour()                       # B14: the attendant unloads the player's cart at a cart stop
	relations.hour(h)                  # shared hours build friendships and romances (CRT-08)
	for f in fields:                   # a crop is ripe when it has grown, not at the next sunrise
		grow_field(f)
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
	# a carcass nobody took spoils after ANIMAL_LOOT_DAYS: no leftover markers (PL2-004); what spoils is counted
	# (spoiled_<item>), so the goods ledger accounts for it
	var kept := []
	for l in loot:
		if str(l.from).begins_with("the ") and l.has("t") and minutes - float(l.t) > ANIMAL_LOOT_DAYS * 1440.0:
			for id in (l.inv as Inventory).ids():
				stat("spoiled_" + str(id), float((l.inv as Inventory).count(id)))
		else:
			kept.append(l)
	loot = kept
	var d := day()
	for t in trees:                           # B14: fruit trees bear again (or lose their fruit with the season): redraw them
		if t.has("species") and not Trees.fruit_cfg(str(t.species)).is_empty():
			tree_changed.emit(t)
	if map.overworld != null:                 # wild flowers outside the village grow back too: their tile returns
		for c: Vector2i in map.overworld.plant_changes.keys():
			if int(map.overworld.plant_changes[c]) <= d:
				map.overworld.plant_changes.erase(c)
				var back: Dictionary = map.overworld.flower_at(c)
				if not back.is_empty():
					tile_changed.emit(c, "below", int(back.tile))
	season_plants()                    # wild plants ripen again, in their seasons (SEED-03)
	fauna.new_day()
	farm.daily_products()              # eggs, milk and wool wait in the player's pens (PL2-015)
	var t := Time.get_ticks_usec() if profiling else 0
	Life.dawn(self)                    # B8-029: roles by age, old-age deaths, partners, births
	if profiling:
		t = _prof("daily: life (ages, deaths, partners, births)", t)
	brain.dawn()
	if profiling:
		t = _prof("daily: brain dawn (work, succession)", t)
	manor_work.dawn()                  # undone manor jobs are released
	property.collect_rents()
	property.relet_stalls()
	brain.relet_pens()
	business.daily()                   # the stall's rent (PL1-10)
	construction.daily()               # helpers' days end; crowded households split; founders build
	farm_plots.daily()                 # households weigh taking farmland (FARM-05)
	if profiling:
		_prof("daily: manor, rents, business, construction", t)
	var cold := 0
	for hh in households:
		if not hh.pantry.remove("log"):
			cold += 1
		else:
			stat("burned_log")
	if cold > 0:
		note("%d households had no firewood last night." % cold)


func _update_npc(n: NPC, dt: float) -> void:
	var gm: float = dt * float(GameData.b("game_minutes_per_second"))
	n.hunger = maxf(0.0, n.hunger - gm / 60.0 * float(GameData.b("hunger_per_hour")) * NPCBrain.food_factor(n))     # a child more slowly
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
		var t := Time.get_ticks_usec() if profiling else 0
		brain.decide(n)
		if profiling:
			_prof("villagers: decide", t)
	var t2 := Time.get_ticks_usec() if profiling else 0
	_run_plan(n, dt, gm)
	if profiling:
		_prof("villagers: run plan (incl. walking)", t2)


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
				var st_id := str(s.get("args", {}).get("station", "")) if s.get("act", "") == "craft" else ""
				if st_id != "" and player_at_station(st_id):
					# the player is working there (Build 13): wait beside it, never work it together;
					# after station_wait_minutes give up and free the place, and plan again later
					s["waited"] = float(s.get("waited", 0.0)) + gm
					n.anim = "idle"
					n.doing = "waiting for the %s" % str(stations[st_id].type)
					if float(s.waited) >= float(GameData.b("station_wait_minutes")):
						brain.release_station(n, st_id)
						n.plan.clear()
						stat("station_gave_way")
					return
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
	var speed: float = float(GameData.b("walk_tiles_per_second")) * s.get("speed", 1.0) * Life.walk_factor(n)    # elders walk slower (B8-029)
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
		damage_player(gm / 60.0 * float(GameData.b("starve_damage_per_hour")), "hunger")     # TIME-04: the villagers' rule
	p.stamina = minf(p.stamina_cap(), p.stamina + real_dt * float(GameData.b("player_stamina_regen_per_second")))
	relations.player_tick(gm)          # time spent near villagers builds ties (CRT-10)
	p.fireball_cd = maxf(0.0, p.fireball_cd - real_dt)
	p.attack_cd = maxf(0.0, p.attack_cd - real_dt)


func damage_player(amount: float, source: String) -> void:
	var p := player
	if not p.alive:
		return
	p.hp -= maxf(0.0, amount * Skills.value(p, "combat", "damage_taken", 1.0) - p.defense() * 0.5) if source != "hunger" else amount
	p.last_damage = source              # what hurt the player last: the death screen's cause (B8-020)
	if p.hp <= 0.0:
		p.alive = false
		p.death_cause = source
		p.deaths += 1
		note("%s %s died (%s)." % [p.name, p.family, source])


## Permanent death: the next of the family line takes over. The world is not reset.
## Decision (recorded in docs/BUILD_DECISIONS.md, owner 2026-10-18): the heir keeps the house, the chest
## and what the family owns or leases, starts every skill from nothing and carries only the starting kit;
## what the dead carried stays where they fell.
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
## heir keeps the family's home, chest and everything the family owns or leases (all held as
## "player", the family: World "ownership"), starts every skill from nothing and carries only the
## starting kit (owner rule); its coins are new to the village, counted in coin_sources.
func continue_as_heir() -> void:
	var p := player
	contracts.on_player_died()             # CON-01: coins the player set aside come back to them first, to lie with the rest
	var bag := Inventory.new()
	for id in p.inv.items:
		bag.add(id, p.inv.items[id])
	if bag.total() > 0 or p.coins > 0:
		loot.append({"pos": p.pos, "inv": bag, "coins": p.coins, "from": "%s %s" % [p.name, p.family]})
		_loot_on_player_level(loot[loot.size() - 1])
	quests.release_all()                   # what givers set aside for the dead player's quests goes back
	manor_work.release_player()            # and the manor's work they had taken
	var heir := PlayerState.new()
	heir.family = p.family
	heir.generation = p.generation + 1
	heir.name = ["Alys", "Hob", "Maud", "Piers", "Emma", "Jack", "Agnes", "Will"][(p.generation) % 8]
	heir.sprite = p.heir_sprite
	heir.heir_sprite = p.sprite
	var kid := Life.player_heir_child(self)        # B8-029: the player's own eldest child of 16+, if there is one
	Life.retire_player_id(self)
	if kid != null:
		Life.make_heir(self, heir, kid, p)
	else:
		heir.born = Life.born_for_age(float(Life.cfg().player_start_age[0]), minutes)    # a relative: a young adult
		heir.sex = "female" if heir.name in Life.FEMALE else "male"
	heir.home = p.home
	heir.chest = p.chest
	heir.chest_stolen = p.chest_stolen
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
	_set_player_level(0)                   # MIN-A: the heir starts at home, on the surface
	quests.start_story()                   # the heir must seek the sage again: spells are not inherited
	# whoever was fighting the dead player has no quarrel with the heir
	for n: NPC in npcs:
		if n.target == -2:
			n.target = -1
			n.plan.clear()
	note("%s %s (generation %d) takes up the family's life." % [heir.name, heir.family, heir.generation])


# ---------------------------------------------------------------- economy --------------------
## Diagnostics only (tests/economy_sim.gd): called as hook(buyer, seller, id, qty, total) after each sale.
var trade_hook := Callable()


## Atomic sale: either goods and coins both move or nothing does. Parties are NPC or PlayerState.
## `total_price` (optional) is the whole bill when the units are priced one by one (player_buy_many).
func trade(buyer: Object, seller: Object, id: String, qty: int, price_each: int, total_price := -1) -> bool:
	var total := qty * price_each if total_price < 0 else total_price
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
	if trade_hook.is_valid():
		trade_hook.call(buyer, seller, id, qty, total)
	if business:
		business.stalls.after_trade(seller, id, qty, total)     # a merchant's sale at their market stall: its session (STALL-05)
	return true


## Move items between two inventories without money (gifts, deposits, pantry).
func transfer(from: Inventory, to: Inventory, id: String, qty: int) -> bool:
	if not from.has(id, qty) or not to.can_add(id):
		return false
	from.remove(id, qty)
	to.add(id, qty)
	return true


func sell_price(vendor: NPC, id: String, skip := {}) -> int:
	return sell_price_at(id, vendor.inv.count(id), local_supply(id, vendor.pos, vendor, skip))


## How many of `id` other sellers offer within local_supply.radius of `at` (B14, owner: "pricing ...
## determined by availability for sale in a certain diameter"): what traders (local_supply.jobs, and
## anyone keeping a counter) hold for sale (a craftsman's own materials do not count), and the stock of
## the player's open stall and shops. A seller among many asks less; a lone one more. `skip`: a stall
## or shop left out (the one being compared with).
func local_supply(id: String, at: Vector2, except: Object = null, skip := {}) -> int:
	var cfg: Dictionary = GameData.b("local_supply")
	var r2 := float(cfg.radius) * float(cfg.radius)
	var jobs: Array = cfg.jobs
	var n := 0
	for o: NPC in npcs:
		if o == except or not o.alive or o.role in ["child", "bandit"] or o.pos.distance_squared_to(at) > r2:
			continue
		if (o.job in jobs or at_post(o)) and o.inv.has(id) and not brain.keeps(o, id) \
				and (o.job == "merchant" or not NPCBrain.BUYS.get(brain.buy_role(o), {}).has(id)):     # a trade's own materials are not for sale
			n += o.inv.count(id)
	for s: Dictionary in business.premises() + business.stalls.npc_built():     # and villagers' built stalls (STALL-06)
		if s != skip and s.has("stock") and Vector2(int(s.x), int(s.y)).distance_squared_to(at) <= r2:
			n += int(s.stock.get(id, 0))
	return n


## OD-19 (owner, 2026-10-20) and PAR-02A: a person's foreseeable necessities over reserve_days, from what they can know
## now (no knowledge of the future): {food, fuel, medicine, rent, income, need, held, reserve}, in coins at today's
## asking prices. `need` is the household's (food: its members' need less the food its pantry and members hold; fuel:
## a log a night less the logs held; medicine: one for each member hurt below medicine_use_below with none to hand;
## rent: leases falling due; income: the wages paid members can expect after the first day, while the treasury can
## pay them). `reserve` is what `who` keeps of their own coins: the need less what the rest of the household holds.
## The same calculation for the player (their own food and leases) and every villager; it guides the villagers'
## spending (can_afford) and is shown to the player, who decides for themselves.
func necessity(who) -> Dictionary:
	var days := float(GameData.b("reserve_days"))
	var people: Array = [who]
	var stores: Array = [who.inv]
	if not (who is NPC) and player.home != "" and buildings.has(player.home):
		stores.append(player.chest)                  # FSE-18: the player's family chest, by the households' rule
	var ref := PLAYER
	if who is NPC:
		ref = World.npc_ref(who.id)
		if who.household >= 0 and not households[who.household].get("ended", false):
			people = brain._members(who.household)
			stores = [households[who.household].pantry]
			for m: NPC in people:
				stores.append(m.inv)
			ref = World.hh_ref(who.household)
	var need_pts := 0.0
	for p in people:
		need_pts += (NPCBrain.food_factor(p) if p is NPC else 1.0) * 24.0 * float(GameData.b("hunger_per_hour")) * days
	var have_pts := NPCBrain.store_points(stores)       # all it holds, by the one valuation (FSE-17)
	var logs := 0
	var meds := 0
	for inv: Inventory in stores:
		logs += inv.count("log")
		for m in NPCBrain.MEDICINES:
			meds += inv.count(m)
	var food := ceili(maxf(0.0, need_pts - have_pts) * _market_price("food"))
	var fuel := 0
	if who is NPC and who.household >= 0:
		fuel = ceili(maxf(0.0, ceilf(days) - float(logs)) * _market_price("log"))
	var hurt := 0
	for p in people:
		if p.alive and p.hp < p.hp_cap() * float(GameData.b("home_production").medicine_use_below):
			hurt += 1
	var medicine := ceili(float(maxi(0, hurt - meds)) * _market_price("medicine"))
	var rent := 0
	for r in property.records():
		if tenant_of(r) == ref and int(r.get("rent", 0)) > 0 and int(r.get("due_day", 1 << 30)) <= day() + int(ceilf(days)):
			rent += int(r.rent) + int(r.get("arrears", 0))
	var income := 0
	if who is NPC and treasury >= int(brain.daily_obligations()):
		for p in people:
			var wage := int(GameData.b(str(p.job) + "_wage_per_day")) if p is NPC and str(p.job) in ["guard", "reeve"] else 0
			income += wage * maxi(0, int(ceilf(days)) - 1)
	var need := maxi(0, food + fuel + medicine + rent - income)
	var held := 0
	for p in people:
		if p != who:
			held += int(p.coins)
	return {"food": food, "fuel": fuel, "medicine": medicine, "rent": rent, "income": income, "need": need, "held": held,
		"reserve": maxi(0, need - held)}


## The coins `who` keeps back for their foreseeable necessities (necessity().reserve; PAR-02A), cached for the game hour.
func reserve_of(who) -> int:
	var key := (World.npc_ref(who.id) if who is NPC else PLAYER) + "@" + str(int(minutes / 60.0))
	if not _reserve_cache.has(key):
		if _reserve_cache.size() > 4000:
			_reserve_cache.clear()
		_reserve_cache[key] = int(necessity(who).reserve)
	return int(_reserve_cache[key])


var _reserve_cache := {}              # (who @ game hour) -> reserve (reserve_of; derived, not saved)
var _price_cache := {}                # (kind @ game hour) -> coins a unit (_market_price; derived, not saved)


## What the market asks now, by what anyone can see: a food point at the cheapest food on sale, a log, a medicine,
## the lowest asking price among the villagers holding one for sale (else its base value).
func _market_price(kind: String) -> float:
	var key := kind + "@" + str(int(minutes / 60.0))
	if _price_cache.has(key):
		return float(_price_cache[key])
	if _price_cache.size() > 200:
		_price_cache.clear()
	var ids: Array = NPCBrain.FOOD if kind == "food" else (NPCBrain.MEDICINES if kind == "medicine" else ["log"])
	var best := INF
	for id in ids:
		var per := NPCBrain.food_points(id) if kind == "food" else 1.0
		if per <= 0.0:
			continue
		var p := float(GameData.value(id))
		for o: NPC in npcs:
			if o.alive and o.role == "adult" and o.inv.has(id) and not brain.keeps(o, id):
				p = minf(p, float(sell_price(o, id)))
		best = minf(best, p / per)
	_price_cache[key] = 0.0 if best == INF else best
	return float(_price_cache[key])


## The cheapest food unit on sale now, [price, food points] ([0, 0] when none is): what a coin can really buy, by the
## asking prices of the villagers selling cooked food or grain (the relief reckoning, NPCBrain.household_food_days).
func cheapest_food_unit() -> Array:
	var key := "unit@" + str(int(minutes / 60.0))
	if _price_cache.has(key):
		return _price_cache[key]
	var best := [0, 0]
	var per := INF
	for o: NPC in npcs:
		if not o.alive or not (o.job in ["tavernkeeper", "farmer"] or brain.buy_role(o) == "merchant_food"):
			continue
		for id in NPCBrain.FOOD:
			if o.inv.count(id) - brain.reserve(o, id) <= 0:
				continue
			var pts := NPCBrain.food_points(id)
			var price := sell_price(o, id)
			if pts > 0.0 and price > 0 and float(price) / pts < per:
				per = float(price) / pts
				best = [price, int(pts)]
	_price_cache[key] = best
	return best


## Whether an item is a necessity a reserve is kept for (OD-19 section 3): food, fuel, medicine.
static func is_necessity(id: String) -> bool:
	return id in NPCBrain.FOOD or id in NPCBrain.MEDICINES or id == "log"


## Whether `buyer` will pay `price` (OD-19 section 3, PAR-02A): a necessity for their own household (`for_need`: food,
## firewood, medicine to use) out of any of their coins, reserved ones included; anything else (stock for their trade,
## materials, goods for resale) with what is left above their reserve (reserve_of). One exception, the decision's
## "business purchases may still be economically justified when necessary to generate income": a trader holding none
## of `id`, an input of their own trade (NPCBrain.BUYS), may buy one unit with reserved coins to keep earning; with any
## in hand they work it first. The one rule for every purchase, whoever sells, the player or a villager (PAR-02).
func can_afford(buyer: NPC, price: int, for_need := false, id := "") -> bool:
	if for_need:
		return buyer.coins >= price
	if buyer.coins - price >= reserve_of(buyer):
		return true
	return id != "" and buyer.inv.count(id) == 0 and NPCBrain.BUYS.get(brain.buy_role(buyer), {}).has(id) and buyer.coins >= price


## SHOP-01, TRADE-01: how many of the `offered` units of `id` business `buyer` buys from `seller` (the player or a
## villager) in one sale; 0 when it buys none. Its need (NPCBrain.wants: an input its trade has the skill to use, up to
## its want), cut a unit at a time until its own coins pay the whole bill at the sale's prices (sale_prices) and leave
## its reserve (OD-19); the reserve's one-unit exception (can_afford) covers a single-unit sale only. The one rule for
## every sale to a business, whoever sells (PAR-02).
func purchase_qty(buyer: NPC, seller: Object, id: String, offered: int) -> int:
	var q: int = mini(offered, brain.wants(buyer, id))
	if q <= 0:
		return 0
	var prices := sale_prices(buyer, seller, id, q)
	var bill := 0
	for c in prices:
		bill += int(c)
	var keep := reserve_of(buyer)
	while q > 0:
		if buyer.coins >= bill and (buyer.coins - bill >= keep or (q == 1 and can_afford(buyer, bill, false, id))):
			return q
		q -= 1
		bill -= int(prices[q])
	return 0


## The unit prices `buyer` pays `seller` for `qty` of `id`, unit by unit as its stock fills (player_quote for the
## player, with the friend's price; the same buy price and both sides' Trading, deal_price, for a villager).
func sale_prices(buyer: NPC, seller: Object, id: String, qty: int) -> Array:
	if seller == player:
		return player_quote(buyer, id, qty, false)
	var out := []
	var stock := buyer.inv.count(id)
	for k in maxi(0, qty):
		out.append(deal_price(buy_price_at(id, stock + k), buyer, seller))
	return out


## Why business `buyer` will not take all `qty` of `id` from `seller` ("" when it will): the clear reason a sale is refused.
func sale_refusal(buyer: NPC, seller: Object, id: String, qty: int) -> String:
	var who := buyer.name
	var item := GameData.item_name(id).to_lower()
	var got := purchase_qty(buyer, seller, id, qty)
	if got >= qty:
		return ""
	if not NPCBrain.BUYS.get(brain.buy_role(buyer), {}).has(id):
		return "%s does not buy %s." % [who, item]
	var unit: int = brain.batch_unit(buyer, id)
	if unit <= 0:
		return "%s has no use for %s: their trade's recipes for it need more skill than they have." % [who, item]
	var need: int = brain.wants(buyer, id)
	if need <= 0:
		return "%s has all the %s they can use." % [who, item]
	if got < mini(qty, need):
		return "%s cannot afford %s right now: they keep a reserve." % [who, ("more than %d" % got) if got > 0 else "any"]
	return "%s can use only %d more %s." % [who, need, item]


func buy_price(vendor: NPC, id: String) -> int:
	return buy_price_at(id, vendor.inv.count(id))


## What a seller holding `stock` asks for one, with `nearby` more for sale around them (local_supply):
## dearer as stock runs low and when nobody near sells it, cheaper among many sellers.
static func sell_price_at(id: String, stock: int, nearby := 0) -> int:
	var cfg: Dictionary = GameData.b("local_supply")
	var m := clampf(1.5 - 0.05 * stock - float(cfg.weight) * mini(nearby, int(cfg.cap)), float(GameData.b("price_min")) + 0.2, float(GameData.b("price_max")))
	return maxi(1, roundi(GameData.value(id) * m))


## What a buyer holding `stock` pays for one: less as they fill up.
static func buy_price_at(id: String, stock: int) -> int:
	var m := clampf(1.2 - 0.04 * stock, 0.4, 1.2) * float(GameData.b("sell_ratio"))
	return maxi(1, roundi(GameData.value(id) * m))


## The player's price for each of `qty` units of `id` bought from (`buying`) or sold to `n`, unit by unit
## at the stock each one leaves: buying runs the seller's stock down so each unit costs the same or more,
## selling fills the buyer up so each unit fetches the same or less (Build 13 economy rule 2: a bulk deal
## never pays the opening price for every unit). The player's Trading factor applies to each unit.
func player_quote(n: NPC, id: String, qty: int, buying: bool) -> Array:
	var out := []
	var stock := n.inv.count(id)
	var f := deal_factor(player, n) if buying else deal_factor(n, player)     # both sides' Trading (PAR-01)
	if relations.player_friend(n):              # a friend's price (CRT-06)
		f *= 1.0 - float(Relations.cfg().friend_price) if buying else 1.0 + float(Relations.cfg().friend_price)
	var nearby := local_supply(id, n.pos, n) if buying else 0
	for k in maxi(0, qty):
		var base := sell_price_at(id, stock - k, nearby) if buying else buy_price_at(id, stock + k)
		out.append(maxi(1, roundi(base * f)))
	return out


## Buy `qty` of `id` from `vendor` at player_quote prices, all or nothing: the vendor must hold them, the
## pack must have room and the player's own coins must cover the whole bill. Returns {result, text, bought, paid}.
func player_buy_many(vendor: NPC, id: String, qty: int) -> Dictionary:
	var prices := player_quote(vendor, id, qty, true)
	var bill := 0
	for c in prices:
		bill += int(c)
	if qty < 1 or not vendor.inv.has(id, qty) or not player.inv.can_add(id):
		return {"result": "failed", "text": "They do not have that many, or your pack is full.", "bought": 0, "paid": 0}
	if player.coins < bill:
		return {"result": "failed", "text": "You cannot afford that (%d coins)." % bill, "bought": 0, "paid": 0}
	if not trade(player, vendor, id, qty, 0, bill):
		return {"result": "failed", "text": "The trade fell through.", "bought": 0, "paid": 0}
	deal_xp(player, vendor, bill)
	player_xp("trading", Skills.trade_xp(bill))           # the player's Trading xp for the deal (DVW-A12 R13)
	return {"result": "bought", "text": "", "bought": qty, "paid": bill}


func player_price_factor(buying: bool) -> float:
	var f := Skills.value(player, "trading", "price_bonus")
	return 1.0 - f if buying else 1.0 + f


## PAR-01 (owner OD-18.1): the price factor of a deal between `buyer` and `seller`, the player or villagers alike:
## each side's Trading price_bonus pulls the price their way (1 + the seller's - the buyer's). `null` is a party with
## no skills (the caravan, the manor).
func deal_factor(buyer, seller) -> float:
	var up := Skills.value(seller, "trading", "price_bonus") if seller != null else 0.0
	var down := Skills.value(buyer, "trading", "price_bonus") if buyer != null else 0.0
	return 1.0 + up - down


## A unit price `base` between `buyer` and `seller` after their Trading (deal_factor).
func deal_price(base: int, buyer, seller) -> int:
	return maxi(1, roundi(float(base) * deal_factor(buyer, seller)))


## The Trading experience of a deal worth `coins`, the player's rule (Skills.trade_xp), for each villager in it (the
## player's own is awarded by player_buy_many and player_sell_many through player_xp, DVW-A12 R13).
func deal_xp(buyer, seller, coins: int) -> void:
	for who in [buyer, seller]:
		if who is NPC:
			Skills.gain(who, "trading", Skills.trade_xp(coins))


func total_coins() -> int:
	var n := player.coins + treasury
	if quests:
		n += quests.reserved_total()
	if manor_work:
		n += manor_work.reserved_total()
	if contracts:
		n += contracts.reserved_total()           # CON-01: buyers' coins set aside for contracts
	for a: NPC in npcs:
		n += a.coins
	for l in loot:
		n += int(l.coins)
	if business:
		n += business.tills()
	return n


# ---------------------------------------------------------------- resources ------------------
func deposit_at(c: Vector2i, level := 0) -> Dictionary:
	for d in deposits:
		if d.x == c.x and d.y == c.y and level_of(d) == level:
			return d
	if level != 0:
		return {}                                        # MIN-A: below the surface only seams (no boulders, no overworld)
	for b in boulders:
		if b.x == c.x and b.y == c.y and int(b.amount) > 0:
			return b
	if map.overworld != null:
		return map.overworld.boulder_at(c)               # a rock of the world outside the village ({} inside it)
	return {}


## The village's boulders, from the map (VillageMap.decor_boulders): fresh ones, three uses each.
func _make_boulders(m: VillageMap) -> void:
	boulders.clear()
	for c in m.decor_boulders():
		boulders.append({"x": int(c.x), "y": int(c.y), "ore": "stone", "amount": ResourceNodes.boulder_uses(Vector2i(int(c.x), int(c.y))), "boulder": true})


## Show the boulders already broken (a loaded world): their tiles go and their cells open. The view
## calls it after it is built, like the worked-out seams (main.gd _apply_world_changes).
func sync_boulders() -> void:
	for b in boulders:
		if int(b.amount) <= 0:
			_remove_boulder(b)


func tree_at(c: Vector2i) -> Dictionary:
	for t in trees:
		if t.x == c.x and (t.y == c.y or t.y - 1 == c.y):
			sync_tree(t)
			return t
	if map.overworld != null:
		var t: Dictionary = map.overworld.tree_at(c)         # a tree of the world outside the village ({} inside it)
		if not t.is_empty():
			sync_tree(t)
		return t
	return {}


## A village tree of the map's own trees: a stage and a species from its cell (some are saplings, young
## or growing when the game starts, and grow on by the clock).
func _new_tree(t: Dictionary) -> Dictionary:
	var tr := {"x": int(t.x), "y": int(t.y), "trunk": int(t.trunk), "top": int(t.top), "bottom": int(t.bottom),
			"state": "grown", "regrow": 0.0, "born": Trees.initial_born(int(t.x), int(t.y))}
	tr.species = _tree_species(tr)
	return tr


## The species of a village tree from the tiles the map draws it with (its group: leafy, autumn, mixed,
## conifer) and a hash of its cell. Trees by the houses (fruit_trees.orchard_house_range of a door, not in
## the woods) are the cottagers' orchards: one in orchard_share of them is an apple tree (B14).
func _tree_species(t: Dictionary) -> String:
	var ft: Dictionary = GameData.b("fruit_trees")
	var cell := Vector2i(int(t.x), int(t.y))
	if (Overworld.hash32(cell.x, cell.y, 11, 23) >> 5) % int(ft.orchard_share) == 0 and not _in_woods(cell):
		for id in buildings:
			if str(buildings[id].get("type", "")) == "house" and Vector2(building_door(id)).distance_to(Vector2(cell)) <= float(ft.orchard_house_range):
				return "apple_orchard"
	var group := "mixed"
	for k in map.overworld.tiles.trees:
		if int(k.top) == int(t.top):
			group = str(k.group)
			break
	return Trees.species_for(group, int(t.x), int(t.y), false)


func _in_woods(c: Vector2i) -> bool:
	for wd in map.data.get("woods", []):
		if c.x >= int(wd.x) and c.x < int(wd.x) + int(wd.w) and c.y >= int(wd.y) and c.y < int(wd.y) + int(wd.h):
			return true
	return false


## Pick a fruit tree's ripe fruit (B14): returns {item: count}, {} if none hangs; it bears again
## fruit_trees regrow_seasons later (whole days), in a fruiting season.
func pick_fruit(t: Dictionary) -> Dictionary:
	if not Trees.fruit_ripe(t, day(), season()):
		return {}
	var f := Trees.fruit_cfg(str(t.species))
	var r := Life.season_range_days(f.regrow_seasons)
	t.fruit_day = day() + rng.randi_range(r.x, r.y)
	if t.get("ow", false):
		map.overworld.note_tree(t)
	tree_changed.emit(t)
	stat("picked_" + str(f.item), float(f.yield))
	stat("made_" + str(f.item), float(f.yield))
	return {str(f.item): int(f.yield)}


## The map's wild plants, all ripe (their place and tile are map data; load_dict applies a save's state).
func _make_plants(m: VillageMap) -> void:
	plants = []
	for pl in m.data.get("plants", []):
		plants.append({"id": str(pl.id), "x": int(pl.x), "y": int(pl.y), "kind": str(pl.kind), "tile": int(pl.tile),
				"state": "ripe", "regrow": 0.0})


## The wild plant at a cell (exactly), {} if none. A grubbed-up one is not found.
func plant_at(c: Vector2i) -> Dictionary:
	for pl in plants:
		if pl.x == c.x and pl.y == c.y and pl.state != "cleared":
			return pl
	if map.overworld != null:
		return map.overworld.flower_at(c)           # a wild flower of the world outside the village ({} inside it; PL2-006)
	return {}


## Pick a ripe plant: returns what it gave (item id -> count, from its resources.json node), {} if it
## is not ripe. The plant is bare until plant_regrow_seasons (provisional; whole days) later, at dawn.
func pick_plant(pl: Dictionary) -> Dictionary:
	if pl.is_empty() or pl.state != "ripe":
		return {}
	var got := ResourceNodes.products(ResourceNodes.def_for("plant", str(pl.kind)))
	pl.state = "picked"
	var r := Life.season_range_days(GameData.b("plant_regrow_seasons"))
	pl.regrow = day() + rng.randi_range(r.x, r.y)
	if pl.get("ow", false):
		map.overworld.note_flower(Vector2i(pl.x, pl.y), int(pl.regrow))
		tile_changed.emit(Vector2i(pl.x, pl.y), "below", -1)
	else:
		tile_changed.emit(Vector2i(pl.x, pl.y), PLANT_LAYER, -1)
	stat("plants_picked")
	for id in got:
		stat("made_" + id, float(got[id]))     # the economy ledger's production count (economy_sim)
	return got


## SEED-02/SEED-04: the planting material whoever picked plant `pl` recovers from it, {item: 1} or {}: balance.json
## propagation.kinds[kind] (its item, by its chance). The roll is a hash of the plant's cell, the day and the world seed,
## so it is deterministic and draws nothing from the world's RNG. The same rule for the player and villagers; the caller
## adds the item and counts it (made_), as with the picked goods.
func propagation_drop(pl: Dictionary) -> Dictionary:
	var k: Dictionary = propagation_cfg(str(pl.get("kind", "")))
	if k.is_empty():
		return {}
	var roll := float(Overworld.hash32(int(pl.x), int(pl.y), day(), seed + 41) % 10000) / 10000.0
	return {str(k.item): 1} if roll < float(k.chance) else {}


## The propagation settings of a wild plant kind ({} if it has none).
static func propagation_cfg(kind: String) -> Dictionary:
	return (GameData.b("propagation").kinds as Dictionary).get(kind, {})


## The wild plant kind an item plants ("" if it plants none): items.json `propagates`.
static func propagates(item: String) -> String:
	return str(GameData.item(item).get("propagates", "")) if GameData.items.has(item) else ""


## SEED-03: whether a wild plant kind bears in the present season (balance.json plant_seasons; unlisted: always).
func plant_in_season(kind: String) -> bool:
	var s: Dictionary = GameData.b("plant_seasons")
	return not s.has(kind) or (s[kind] as Array).has(season())


## SEED-03, at dawn (and when a world is made): a ripe plant out of its seasons goes bare until its seasons come round;
## a young planted one that has grown (its `regrow` day) and a bare one whose regrow day has come are ripe again, if in
## season. Bare plants keep their place and are perennial: picking never removes a plant.
func season_plants() -> void:
	var d := day()
	for pl in plants:
		if pl.state == "young" and d >= pl.regrow:
			pl.state = "picked"                       # grown: it bears like any bush, in its seasons
		if pl.state == "ripe" and not plant_in_season(str(pl.kind)):
			pl.state = "picked"
			pl.regrow = float(d)
			tile_changed.emit(Vector2i(pl.x, pl.y), PLANT_LAYER, -1)
		elif pl.state == "picked" and d >= pl.regrow and plant_in_season(str(pl.kind)):
			pl.state = "ripe"
			tile_changed.emit(Vector2i(pl.x, pl.y), PLANT_LAYER, int(pl.tile))


## Why `item` (a cutting or flower seed) cannot be planted at `cell`, "" if it can: the sapling rule (free, walkable
## grass, away from roads, doors, buildings, fields, plots and trees), inside the village.
func plant_bush_refusal(cell: Vector2i, item: String) -> String:
	if propagates(item) == "":
		return "That cannot be planted."
	if not map.in_village(cell):
		return "Plant it in the village, on open grass."
	return plant_refusal(cell)


## SEED-02: plant a cutting or flower seed at `cell` (check plant_bush_refusal first): the item is used up (taken from
## `from` and counted used_), and a young wild plant of its kind stands there, belonging to no one like any wild plant; it
## bears propagation grow_seasons later (season_plants). Returns the plant, {} if refused.
func plant_bush(cell: Vector2i, item: String, from: Inventory) -> Dictionary:
	if plant_bush_refusal(cell, item) != "" or not from.has(item):
		return {}
	var kind := propagates(item)
	var tiles := []
	for pl in plants:
		if str(pl.kind) == kind and not tiles.has(int(pl.tile)) and not pl.get("planted", false):
			tiles.append(int(pl.tile))
	tiles.sort()
	var tile := int(tiles[Overworld.hash32(cell.x, cell.y, 7, 29) % tiles.size()]) if not tiles.is_empty() else -1
	from.remove(item, 1)
	stat("used_" + item)
	stat("plants_planted_" + kind)
	var pl := {"id": "sown%d" % plants.size(), "x": cell.x, "y": cell.y, "kind": kind, "tile": tile, "state": "young",
			"regrow": float(day() + roundi(Life.seasons_to_days(float(propagation_cfg(kind).grow_seasons)))), "planted": true}
	plants.append(pl)
	return pl


## PAR-01 (owner OD-18.1): the goods `who` makes go to `into`: the player's pack through player_gain (counted, a
## full pack sets it down), anyone else's inventory with the same ledger count (`kind` + id).
func _work_goods(who, into: Inventory, id: String, n: int, kind: String) -> void:
	if n <= 0:
		return
	if who is PlayerState and into == player.inv:
		player_gain(id, n, kind)
		return
	into.add(id, n)
	stat(kind + id, float(n))


## Wear `tool` by `amount` unless the skill's `save_key` spares it; a break is counted. True if it broke.
func _work_wear(who, tool: String, amount: int, skill: String, save_key: String) -> bool:
	if tool == "" or not who.inv.has(tool):
		return false
	if who.inv.wear(tool, 0 if rng.randf() < Skills.value(who, skill, save_key) else amount):
		stat("broke_" + tool)
		return true
	return false


## PAR-01: one swing at a seam, for the player, a miner or a manor hand alike: the same gate (gold ore needs Mining
## level 3), the same tier effects (an extra ore, a pickaxe spared wear) and the same experience (8 xp an ore).
## The ore goes to `into`. Returns {result: "ok" | "gold" | "out", ore, n, broke, up} (up: a new Mining level, or 0).
func work_mine(who, d: Dictionary, into: Inventory, tool := "pickaxe") -> Dictionary:
	if str(d.get("ore", "")) == "gold_ore" and not Skills.has(who, "mining", "gold"):
		return {"result": "gold"}
	var ore := mine_unit(d)
	if ore == "":
		return {"result": "out"}
	var k := 1
	if rng.randf() < Skills.value(who, "mining", "ore_extra_chance") and mine_unit(d) != "":
		k += 1
	_work_goods(who, into, ore, k, "mined_")
	var broke := _work_wear(who, tool, 1, "mining", "tool_wear_save")
	return {"result": "ok", "ore": ore, "n": k, "broke": broke, "up": Skills.gain(who, "mining", 8 * k)}


## PAR-01: a tree has fallen to `who`'s axe: `logs` (fell's count, with the Woodcutting log_bonus) go to `into`, the axe
## wears (3) unless spared, and the work earns 12 Woodcutting xp, the same for everyone. Returns {broke, up}.
func work_felled(who, logs: int, into: Inventory, tool := "axe") -> Dictionary:
	_work_goods(who, into, "log", logs, "felled_")
	stat("trees_felled")
	var broke := _work_wear(who, tool, 3, "woodcutting", "axe_wear_save")
	return {"broke": broke, "up": Skills.gain(who, "woodcutting", 12)}


## PAR-01 and PAR-04 (owner OD-18.1, 18.4): one way to make a recipe, for the player and every villager: the recipe's
## skill level is needed, the inputs come out of `inv` (the crafter's pack, or a household's pantry) unless a practised
## hand saves them (save_chance), a bonus unit may come (bonus_chance, never gear), outputs go back to `inv`, anvil work
## wears the crafter's hammer if they have one, and the recipe's xp is earned. Every unit is counted for the ledger.
## Returns {result: "ok" | "level" | "materials", up}.
func work_craft(who, recipe: String, inv: Inventory) -> Dictionary:
	var r: Dictionary = GameData.recipes[recipe]
	if Skills.level(who, str(r.skill)) < int(r.level):
		return {"result": "level"}
	if not inv.remove_all(r["in"]):
		return {"result": "materials"}
	if rng.randf() < Skills.value(who, str(r.skill), "save_chance"):
		for id in r["in"]:
			inv.add(id, int(r["in"][id]))                  # a practised hand wastes nothing
	else:
		for id in r["in"]:
			stat("used_" + id, float(r["in"][id]))
	var bonus := rng.randf() < Skills.value(who, str(r.skill), "bonus_chance")
	for id in r.out:
		_work_goods(who, inv, id, int(r.out[id]) + (1 if bonus and not Skills.is_gear(str(id)) else 0), "made_")
	if str(r.station) == "anvil":
		_work_wear(who, "hammer", 2, str(r.skill), "")
	return {"result": "ok", "up": Skills.gain(who, str(r.skill), int(r.xp))}


## DVW-A12 R15: the player's reach, the distances the interface's target choice (main.gd _find_target) has always
## used, kept here so a host can refuse an action out of reach. A target is chosen near a probe TARGET_PROBE tiles in
## front of the player: people, loot and containers within TARGET_REACH of it (containers also within
## CONTAINER_REACH of the player); a seam, tree, plant or field in the probe's cell or one of its four neighbours, so
## (the probe being less than a tile ahead) never more than CELL_REACH cells off the player's own cell on either axis.
const TARGET_PROBE := 0.9
const TARGET_REACH := 1.5
const CONTAINER_REACH := 2.2
const CELL_REACH := 2
const STATION_REACH := 1.2       # a crafting station is offered (its window opened) closer than this to where it is used


## DVW-A12 R15: why the player cannot reach the point `at` (a pile, a container), "" if they can: a wall between
## (reaches), else farther than `reach` tiles.
func player_reach_point(at: Vector2, reach: float) -> String:
	if not reaches(player.pos, at):
		return "A wall is in the way."
	if player.pos.distance_to(at) > reach:
		return "That is out of reach."
	return ""


## DVW-A12 R15: why the player cannot reach container `c` (its cell's middle, within CONTAINER_REACH), "" if they can.
func player_container_reach(c: Dictionary) -> String:
	return player_reach_point(Vector2(int(c.x) + 0.5, int(c.y) + 0.5), CONTAINER_REACH)


## DVW-A12 R15: why the player cannot reach the cell `cell` (a seam, a tree, a plant), "" if they can: a wall between
## (reaches, to the cell's middle), else more than CELL_REACH cells off the player's cell on either axis. `tall`: a
## tree, which is also found by the cell above its trunk (tree_at), so that cell counts too.
func player_reach_cell(cell: Vector2i, tall := false) -> String:
	if not reaches(player.pos, Vector2(cell) + Vector2(0.5, 0.5)):
		return "A wall is in the way."
	var pc := Vector2i(floori(player.pos.x), floori(player.pos.y))
	for c: Vector2i in ([cell, cell + Vector2i(0, -1)] if tall else [cell]):
		if absi(c.x - pc.x) <= CELL_REACH and absi(c.y - pc.y) <= CELL_REACH:
			return ""
	return "That is out of reach."


## DVW-A12 R15: why the player cannot reach field `f`, "" if they can: its nearest cell more than CELL_REACH cells off
## the player's cell on either axis. (No wall test: the interface never made one for a field.)
func player_reach_field(f: Dictionary) -> String:
	var px := floori(player.pos.x)
	var py := floori(player.pos.y)
	var nx := clampi(px, int(f.x), int(f.x) + int(f.w) - 1)
	var ny := clampi(py, int(f.y), int(f.y) + int(f.h) - 1)
	if absi(nx - px) > CELL_REACH or absi(ny - py) > CELL_REACH:
		return "That is out of reach."
	return ""


## DVW-A12 R1: whether the player may start mining seam or boulder `d`, and how long the swing takes. A pickaxe is
## needed (the best one in the pack), and gold ore needs Mining level 3 (work_mine checks it again at the swing).
## The time: balance.json mine_minutes at the game's speed, by the pickaxe's speed and the Mining mine_time effect.
## Returns {ok: true, tool, secs} or {ok: false, why}.
func player_mine_plan(d: Dictionary) -> Dictionary:
	var p := player
	var far := player_reach_cell(Vector2i(int(d.x), int(d.y)))       # R15
	if far != "":
		return {"ok": false, "why": far}
	var pick := p.tool_of("pickaxe")
	if pick == "":
		return {"ok": false, "why": "Requires a pickaxe. The smith sells them."}
	if str(d.get("ore", "")) == "gold_ore" and not Skills.has(p, "mining", "gold"):
		return {"ok": false, "why": "Gold needs Mining level 3."}
	var secs := float(GameData.b("mine_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.6 / float(GameData.item(pick).get("speed", 1.0)) * Skills.value(p, "mining", "mine_time", 1.0)
	return {"ok": true, "tool": pick, "secs": secs}


## DVW-A12 R1: the player's swing at seam `d` with pickaxe `tool`, when the swing's time is up: work_mine, as a miner's
## (PAR-01), into the pack (a full pack sets the ore down: `full`); a broken pickaxe leaves the hand empty.
## Returns work_mine's result plus `full` (the pack could not take the ore).
func player_mine(d: Dictionary, tool: String) -> Dictionary:
	var p := player
	var full := not p.inv.can_add(str(d.get("ore", "stone")))
	var r := work_mine(p, d, p.inv, tool)
	r["full"] = full
	if r.result == "ok" and r.broke and p.tool == tool:
		p.tool = ""
	return r


## DVW-A12 R2: whether the player may start felling tree `t`, and how long the whole felling takes. An axe is needed
## (the best one in the pack), and only a mature tree can be felled (Trees.refusal). The time: balance.json
## chop_minutes at the game's speed, by the axe's speed and the Woodcutting chop_time effect; the felling is
## Trees.cfg().chops blows of an equal share of it. Returns {ok: true, tool, secs} or {ok: false, why}.
func player_fell_plan(t: Dictionary) -> Dictionary:
	var p := player
	var far := player_reach_cell(Vector2i(int(t.x), int(t.y)), true)       # R15
	if far != "":
		return {"ok": false, "why": far}
	var axe := p.tool_of("axe")
	if axe == "":
		return {"ok": false, "why": "Requires an axe. The smith sells them."}
	var secs := float(GameData.b("chop_minutes")) / float(GameData.b("game_minutes_per_second")) * 0.5 / float(GameData.item(axe).get("speed", 1.0))
	secs *= Skills.value(p, "woodcutting", "chop_time", 1.0)
	var why := Trees.refusal(str(t.state))
	if why != "":
		return {"ok": false, "why": why}
	return {"ok": true, "tool": axe, "secs": secs}


## DVW-A12 R2: one blow of the player's axe `tool` at tree `t` from `side`. A tree no longer mature (felled by someone
## else meanwhile) takes no blow: result "gone". Until the last blow: "blow". The last fells it ("felled"): its logs
## (with the Woodcutting log_bonus) go to the pack through work_felled, as a woodcutter's (PAR-01), or are set down if
## the pack is full (`full`); the tree may drop saplings (sapling_drop, with the sapling_bonus), and `saplings` holds
## those the pack took whole; a broken axe leaves the hand. Returns {result, logs, full, saplings, broke, up}.
func player_chop(t: Dictionary, side: int, tool: String) -> Dictionary:
	var p := player
	if t.state != "grown":
		return {"result": "gone"}
	var r := chop_tree(t, side, int(Skills.value(p, "woodcutting", "log_bonus")))
	if int(r.logs) <= 0:
		return {"result": "blow"}
	var full := not p.inv.can_add("log")
	var f := work_felled(p, int(r.logs), p.inv, tool)
	var drop := sapling_drop(t, Skills.value(p, "woodcutting", "sapling_bonus"))
	var saplings := {}
	for id in drop:
		if player_gain(id, int(drop[id])) == int(drop[id]):
			saplings[id] = int(drop[id])
	if f.broke and p.tool == tool:
		p.tool = ""
	return {"result": "felled", "logs": int(r.logs), "full": full, "saplings": saplings, "broke": f.broke, "up": f.up}


## DVW-A12 R3: why the player cannot make `recipe` now, in the game's words ("" if they can): the recipe's skill level,
## then its materials in the pack. The station is checked apart (station_refusal).
func player_craft_refusal(recipe: String) -> String:
	var r: Dictionary = GameData.recipes[recipe]
	if player.level(r.skill) < int(r.level):
		return "Needs %s level %d." % [GameData.skills[r.skill].name, int(r.level)]
	if not player.inv.has_all(r.in):
		return "You do not have the materials."
	return ""


## DVW-A12 R3: the player sets to work on `recipe` at `station` (the craft window's; without one, a station of the
## recipe's kind within 2 tiles of the player). Refused if the station is not theirs to use (station_refusal), then by
## player_craft_refusal. The time: the recipe's minutes at the game's speed, by the skill's craft_time effect; the
## station is held for the player meanwhile (reserve_for_player). Returns {ok: true, station, secs} or {ok: false, why}.
func player_craft_begin(recipe: String, station := "") -> Dictionary:
	var r: Dictionary = GameData.recipes[recipe]
	var p := player
	if station != "" and stations.has(station) and (Vector2(station_use(station)) + Vector2(0.5, 0.5)).distance_to(p.pos) >= STATION_REACH:
		return {"ok": false, "why": "That is out of reach."}         # R15: the craft window opens only this close
	if station == "":
		for id in stations_of(str(r.station)):
			if (Vector2(station_use(id)) + Vector2(0.5, 0.5)).distance_to(p.pos) < 2.0:
				station = id
	if station != "":
		var no := station_refusal(station)
		if no != "":
			return {"ok": false, "why": no}
	var why := player_craft_refusal(recipe)
	if why != "":
		return {"ok": false, "why": why}
	var secs := float(r.minutes) / float(GameData.b("game_minutes_per_second")) * 0.5 * Skills.value(p, str(r.skill), "craft_time", 1.0)
	if station != "":
		reserve_for_player(station, secs * float(GameData.b("game_minutes_per_second")) + 1.0)
	return {"ok": true, "station": station, "secs": secs}


## DVW-A12 R3: the player's work on `recipe` is done: work_craft from the pack into the pack, as a villager's (PAR-01,
## PAR-04). Returns work_craft's result.
func player_craft(recipe: String) -> Dictionary:
	return work_craft(player, recipe, player.inv)


## PAR-01: a blow of `dmg` (the attacker's, after their own Combat effects) landing on villager `n`: their Combat
## damage_taken, then half their armour, as the player's damage_player applies the player's. Returns what it took.
func harm_npc(n: NPC, dmg: float) -> float:
	var dealt := maxf(0.5, dmg * Skills.value(n, "combat", "damage_taken", 1.0) - n.armor * 0.5)
	n.hp -= dealt
	return dealt


## DVW-A12 R7: the damage of one blow of the player's: their weapon's (PlayerState.damage), doubled by the Combat
## tier's crit_chance. Returns {dmg, crit}.
func player_strike() -> Dictionary:
	var d := player.damage()
	if rng.randf() < Skills.value(player, "combat", "crit_chance"):
		return {"dmg": d * 2.0, "crit": true}
	return {"dmg": d, "crit": false}


## DVW-A12 R7: the player's sword blow lands on villager `n`: player_strike, player_hit_npc, and 4 Combat xp a blow.
## Returns player_hit_npc's result plus {crit, up} (up: a new Combat level, or 0).
func player_melee_npc(n: NPC) -> Dictionary:
	var s := player_strike()
	var h := player_hit_npc(n, float(s.dmg))
	h["crit"] = s.crit
	h["up"] = player.gain("combat", 4)
	return h


## DVW-A12 R8: a blow of the player's (a sword's or a spell's) of `dmg` lands on villager `n`: harm_npc (their Combat
## damage_taken and armour, PAR-01); the blow wakes a sleeper and the noise wakes those near, who then see it (owner
## rule); attacking anyone but a bandit is assault (player_assault), and a bandit fights back; at no health they die,
## slain by the player, and a bandit put down near villagers is a defence (CRT-10). Returns {dealt, killed}.
func player_hit_npc(n: NPC, dmg: float) -> Dictionary:
	var dealt := harm_npc(n, dmg)
	wake_near(n.pos, float(GameData.b("sleep_wake_radius")))
	if n.role != "bandit":
		player_assault(n)
	elif n.target == -1:
		n.target = -2
	var killed := false
	if n.hp <= 0.0:
		kill(n, "slain by %s %s" % [player.name, player.family])
		killed = true
		if n.role == "bandit":
			relations.defended(n.pos)        # villagers who saw a bandit put down think better of the player (CRT-10)
	return {"dealt": dealt, "killed": killed}


## DVW-A12 R11: Fireball (owner, DECISIONS.md:57). Its base damage, its speed (tiles a second), how far it flies, and
## how near it must pass someone to strike them.
const FIREBALL_DAMAGE := 14.0
const FIREBALL_SPEED := 9.0
const FIREBALL_RANGE := 8.0
const FIREBALL_HIT_RADIUS := 0.6


## DVW-A12 R11: the player casts Fireball: refused if it is not known (with the reason), or silently while it cools
## down or without the stamina (balance fireball_cooldown and fireball_stamina, by the Magic tier); a cast starts the
## cooldown, spends the stamina and earns 6 Magic xp. Returns {ok, why}.
func player_cast_fireball() -> Dictionary:
	var p := player
	if not p.spells.get("fireball", false):
		return {"ok": false, "why": "You do not know any spells. The Sage in the hut north of the tavern teaches them."}
	var cd := Skills.value(p, "magic", "fireball_cooldown", float(GameData.b("fireball_cooldown")))
	var cost := float(GameData.b("fireball_stamina")) * Skills.value(p, "magic", "fireball_stamina", 1.0)
	if p.fireball_cd > 0.0 or p.stamina < cost:
		return {"ok": false, "why": ""}
	p.fireball_cd = cd
	p.stamina -= cost
	player_xp("magic", 6)
	return {"ok": true, "why": ""}


## DVW-A12 R11: a fireball in flight at `pos` strikes the first villager within FIREBALL_HIT_RADIUS, else the first
## animal: FIREBALL_DAMAGE by the Magic fireball_damage tier, as the player's blow (player_hit_npc, player_hit_animal),
## and a spell that lands earns 6 more Magic xp (`up`: a new level, shown by the caller after the hit). Returns {who:
## the one struck or null, before: their health before, dealt, guard: a guard's words, up}.
func player_fireball_hit(pos: Vector2) -> Dictionary:
	var dmg := FIREBALL_DAMAGE * Skills.value(player, "magic", "fireball_damage", 1.0)
	for n: NPC in present(pos, FIREBALL_HIT_RADIUS):
		var before := n.hp
		var h := player_hit_npc(n, dmg)
		return {"who": n, "before": before, "dealt": h.dealt, "guard": "", "up": player.gain("magic", 6)}
	for a: Animal in fauna.near(pos, FIREBALL_HIT_RADIUS):
		var before := a.hp
		var h := player_hit_animal(a, dmg)
		return {"who": a, "before": before, "dealt": dmg, "guard": h.guard, "up": player.gain("magic", 6)}
	return {"who": null}


## DVW-A12 R10: a blow of the player's of `dmg` lands on animal `a`. Still alive, it is provoked (a wolf or a bear
## fights back, B14). Killed: Combat xp by Skills.kill_xp (per kill, as a villager's, FSE-B12), the wildlife ledger
## (hunted_ or slaughtered_, FSE-B10), its meat and hide left where it fell, a wolf or bear put down near people a
## defence (CRT-10); livestock is theft from its keeper, known the way a theft is (witness, PAR-05): the keeper
## remembers it, and one who saw it comes after the player. Returns {killed, guard: a guard's words, "" for none}.
func player_hit_animal(a: Animal, dmg: float) -> Dictionary:
	a.hp -= dmg
	if a.hp > 0.0:
		fauna.provoke(a, "player")
		return {"killed": false, "guard": ""}
	player_xp("combat", Skills.kill_xp(a.species, player.damage()))
	var keeper: NPC = null
	if not a.wild():
		keeper = pen_keeper(fauna.pens[a.area])
	var what := a.label().to_lower()
	var beast := a.wild() and bool(a.spec().get("people", false))
	stat(("hunted_" if a.wild() else "slaughtered_") + a.species)
	var bag: Inventory = fauna.kill(a)
	if beast:
		relations.defended(a.pos)
	if bag.total() > 0:
		loot.append({"pos": a.pos, "inv": bag, "coins": 0, "from": "the " + what, "t": minutes})
	var guard := ""
	if keeper != null:
		var saw := near(player.pos, float(GameData.b("witness_radius"))).has(keeper)
		witness("livestock", "%s's %s" % [keeper.name, what], keeper, {}, null, "kill %s %s's %s" % [keeper.name, keeper.family, what])
		keeper.remember(("%s killed my %s" % [player.name, what]) if saw else ("found my %s dead" % what))
		if saw and keeper.role == "adult" and keeper.target == -1:
			keeper.target = -2
		guard = last_guard
		note("%s %s killed one of %s %s's animals." % [player.name, player.family, keeper.name, keeper.family])
	return {"killed": true, "guard": guard}


## DVW-A12 R9: attacking a villager is a crime: the victim remembers it and thinks worse of the player, an adult fights
## back, and those who see it (aware_of_attack, witness_radius, PAR-05) remember it; the guards among them answer, and
## the victim and the other witnesses carry word to a guard (raise_alarm, report_crime). Nobody else knows.
func player_assault(victim: NPC) -> void:
	var p := player
	victim.remember("attacked by %s" % p.name)
	relations.harmed(victim, float(Relations.cfg().victim_harm))
	if victim.role == "adult":
		victim.target = -2
	var aware := aware_of_attack(p.pos, victim)
	for n: NPC in aware.seen:
		if n.role != "bandit":
			n.remember("saw %s %s attack %s %s" % [p.name, p.family, victim.name, victim.family])
			relations.harmed(n, float(Relations.cfg().witness_harm))
	raise_alarm(aware, -2)
	stat("player_assault")
	note("%s %s attacked %s %s." % [p.name, p.family, victim.name, victim.family])


## PAR-01: a villager's blow, by the player's Combat rules: damage_mult, a crit_chance double blow.
func npc_blow(n: NPC) -> float:
	var dmg := n.damage * Skills.value(n, "combat", "damage_mult", 1.0)
	if rng.randf() < Skills.value(n, "combat", "crit_chance"):
		dmg *= 2.0
	return dmg


## Take one unit from a deposit. Returns the ore id or "" if it is exhausted.
func mine_unit(d: Dictionary) -> String:
	if d.is_empty() or int(d.amount) <= 0:
		return ""
	d.amount = int(d.amount) - 1
	if d.get("boulder", false):
		if d.get("ow", false):
			map.overworld.note_rock(Vector2i(int(d.x), int(d.y)), int(d.amount))
		if d.amount == 0:
			_remove_boulder(d)
		return "stone"
	if d.amount == 0:
		if level_of(d) != 0:
			level_tile_changed.emit(level_of(d), Vector2i(d.x, d.y), map.data.tiles.depleted_rock)     # MIN-A: drawn on its level
		else:
			tile_changed.emit(Vector2i(d.x, d.y), "below", map.data.tiles.depleted_rock)
		note("A %s seam at the mine is worked out." % GameData.item_name(d.ore).to_lower())
	return d.ore


## A broken boulder leaves open ground: the tile is erased and the cell can be walked.
func _remove_boulder(b: Dictionary) -> void:
	var cell := Vector2i(int(b.x), int(b.y))
	if b.get("ow", false):
		tile_changed.emit(cell, "below", -1)
		return
	map.set_solid(cell, false)
	for lay in map.data.layers:                 # the boulder is in whichever "below" layer the map drew it
		if str(lay.name).begins_with("below") and [int(map.data.tiles.ore.stone), MapView.SMALL_BOULDER_TILE].has(int(lay.data[cell.y * map.w + cell.x])):
			lay.data[cell.y * map.w + cell.x] = -1
			tile_changed.emit(cell, str(lay.name), -1)


## Fell a mature tree: returns the number of logs (0 if it is not mature: only a mature tree can be
## felled). It leaves a stump, falling to `side` (-1 left, 1 right: the side the blows came from); the
## stump sprouts tree_regrow_seasons later (whole days; Trees.sync) and grows through the stages again.
func fell(t: Dictionary, bonus: int, side := 1) -> int:
	if t.is_empty() or t.state != "grown":
		return 0
	var cell := Vector2i(int(t.x), int(t.y))
	t.state = "stump"
	var r := Life.season_range_days(GameData.b("tree_regrow_seasons"))
	t.regrow = Trees.regrow_day(minutes, rng.randi_range(r.x, r.y))
	t.erase("born")
	tree_damage.erase(cell)
	if t.get("ow", false):
		map.overworld.note_tree(t)             # a tree outside the village: the change is saved, the rest of the world is not
	else:
		map.set_solid(cell, false)
	tree_felled.emit(t, side)
	tree_changed.emit(t)
	return 4 + bonus


## One axe blow at a mature tree from `side`: the cut marks show the damage, and the last of
## balance.json tree_growth.chops blows fells it. Returns {hits, chops, logs}: logs is 0 until it falls.
## A hurt tree heals after heal_minutes (the damage is not saved).
func chop_tree(t: Dictionary, side: int, bonus: int) -> Dictionary:
	var chops := int(Trees.cfg().chops)
	if t.is_empty() or t.state != "grown":
		return {"hits": 0, "chops": chops, "logs": 0}
	var cell := Vector2i(int(t.x), int(t.y))
	var hits := tree_hits(cell) + 1
	tree_damage[cell] = {"hits": hits, "side": side, "at": minutes}
	if hits >= chops:
		return {"hits": hits, "chops": chops, "logs": fell(t, bonus, side)}
	tree_hit.emit(t, side, hits)
	return {"hits": hits, "chops": chops, "logs": 0}


## The axe blows the tree at a cell has taken and not yet healed.
func tree_hits(cell: Vector2i) -> int:
	var d: Dictionary = tree_damage.get(cell, {})
	if d.is_empty():
		return 0
	if minutes - float(d.at) > float(Trees.cfg().heal_minutes):
		tree_damage.erase(cell)
		return 0
	return int(d.hits)


## A mature tree's sapling(s) for the player: balance.json tree_growth sapling_count with chance
## sapling_chance. Returns {item: count} ({} for none).
func sapling_drop(t: Dictionary, bonus := 0.0) -> Dictionary:
	var c: Dictionary = Trees.cfg()
	if rng.randf() >= float(c.sapling_chance):
		return {}
	var n := int(c.sapling_count) + (1 if rng.randf() < bonus else 0)       # a woodsman's chance of a second sapling
	return {Trees.sapling_item(str(t.get("species", "oak_summer"))): n}


## Bring a tree's stage up to the game clock (growth is lazy: nothing simulates a tree), keeping the
## collision and the view in step. A young tree does not become a solid growing one under somebody's
## feet. True if it changed.
func sync_tree(t: Dictionary) -> bool:
	var cell := Vector2i(int(t.x), int(t.y))
	if map.overworld != null:
		map.overworld.clock = minutes
	var hold: bool = t.state == "young" and Trees.next_change(t) <= minutes and _someone_on(cell)
	if not Trees.sync(t, minutes, hold):
		return false
	if t.get("ow", false):
		map.overworld.note_tree(t)
	else:
		map.set_solid(cell, Trees.solid(str(t.state)))
	tree_changed.emit(t)
	return true


## Hourly: every tree that is not full grown (the village's, and the ones the player changed outside it)
## catches up with the clock; a hurt tree heals. Untouched overworld trees have no record, no cost.
func _grow_trees() -> void:
	for t in trees:
		if t.state in ["stump", "sapling", "young", "growing"]:
			sync_tree(t)
	if map.overworld != null:
		map.overworld.clock = minutes
		var cells: Array = map.overworld.changes.keys()
		cells.sort()
		for c: Vector2i in cells:
			var t: Dictionary = map.overworld.changes.get(c, {})
			if not t.is_empty() and t.state in ["stump", "sapling", "young", "growing"]:
				sync_tree(t)
	for c: Vector2i in tree_damage.keys():
		tree_hits(c)


## Why the player cannot plant a sapling at a cell, "" if they can: free, walkable grass, not on a
## road, a door, a field, a plot or a building, and not beside another tree.
func plant_refusal(cell: Vector2i) -> String:
	if not map.in_village(cell):
		return map.overworld.plant_refusal(cell) if map.overworld != null else "You cannot plant here."
	if map.is_solid(cell):
		return "Something is in the way there."
	if place_of(Vector2(cell) + Vector2(0.5, 0.5)) != "":
		return "You cannot plant indoors."
	if _road_cells().has(cell):
		return "You cannot plant on the road."
	if _exit_cells().has(cell):
		return "That is the path out of the village."
	for t in trees:
		if t.state != "cleared" and absi(int(t.x) - cell.x) <= 1 and absi(int(t.y) - cell.y) <= 1:
			return "There is a tree here already." if (t.x == cell.x and t.y == cell.y) else "Too close to another tree."
	var near := Rect2i(cell - Vector2i(1, 1), Vector2i(3, 3))
	for b in buildings.values():
		if Rect2i(int(b.x), int(b.y), int(b.w), int(b.h) + 1).grow(1).has_point(cell):
			return "Too near a building."
		if Vector2i(int(b.door[0]), int(b.door[1])).distance_to(cell) < 3.0:
			return "Keep the doorway clear."
	for pl in plots:
		if Rect2i(int(pl.x), int(pl.y), int(pl.w), int(pl.h) + 1).has_point(cell):
			return "That ground is surveyed for building."
	for f in fields:
		if Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)).grow(1).has_point(cell):
			return "That is a field."
	for pen in fauna.pens.values():
		if Rect2i(int(pen.x), int(pen.y), int(pen.w), int(pen.h)).grow(1).has_point(cell):
			return "That is a pen."
	for id in stalls:
		if near.has_point(Vector2i(int(stalls[id].x), int(stalls[id].y))) or near.has_point(Vector2i(int(stalls[id].use[0]), int(stalls[id].use[1]))):
			return "That is the market."
	for id in stations:
		if near.has_point(Vector2i(int(stations[id].at[0]), int(stations[id].at[1]))) or near.has_point(Vector2i(int(stations[id].use[0]), int(stations[id].use[1]))):
			return "Something is worked there."
	for e in containers + deposits:
		if near.has_point(Vector2i(int(e.x), int(e.y))) and level_of(e) == 0:     # a seam below the surface is under rock
			return "Something stands there."
	if not plant_at(cell).is_empty():
		return "Wild plants grow there."
	return ""


var _road_set := {}
var _exit_set := {}


func _road_cells() -> Dictionary:
	if _road_set.is_empty():
		for c in map.data.road:
			_road_set[Vector2i(int(c[0]), int(c[1]))] = true
		_road_set[Vector2i(-1, -1)] = false
	return _road_set


func _exit_cells() -> Dictionary:
	if _exit_set.is_empty():
		for e in map.exits():
			for c: Vector2i in e.trail:
				_exit_set[c] = true
		_exit_set[Vector2i(-1, -1)] = false
	return _exit_set


## Plant the sapling `item` at a cell (check plant_refusal first): a new tree, a sapling, saved with the
## world. Returns the tree record, {} if the cell is refused.
func plant_tree(cell: Vector2i, item: String) -> Dictionary:
	if plant_refusal(cell) != "":
		return {}
	var species := Trees.planted_species(item, cell)
	var t := {}
	if map.in_village(cell):
		t = {"x": cell.x, "y": cell.y, "trunk": -1, "top": -1, "bottom": -1, "species": species, "state": "sapling",
				"regrow": 0.0, "born": minutes, "planted": true}
		trees.append(t)
		map.set_solid(cell, false)
	else:
		t = map.overworld.plant(cell, species, minutes)
	stat("trees_planted")
	tree_changed.emit(t)
	return t


## DVW-A12 R6: the player earns `n` xp in `skill` (PlayerState.gain); a new level is announced by player_leveled.
## Returns the new level, or 0.
func player_xp(skill: String, n: int) -> int:
	var up := player.gain(skill, n)
	if up > 0:
		player_leveled.emit(skill, up)
	return up


## DVW-A12 R6: the player tries the lock of chest unit `u` (Chests.attempt) and earns Stealth xp for it: 4 when it
## opens, 1 otherwise. Returns Chests.attempt's result.
func player_pick_lock(u: Dictionary) -> Dictionary:
	var r: Dictionary = chests.attempt(u)
	player_xp("stealth", 4 if r.result == "open" else 1)
	return r


## DVW-A12 R5: the player takes what lies in loot pile `i`: each kind of goods whole, as far as the pack takes it, and
## all its coins; a pile left empty is gone. Returns {items: [[id, n], ...] taken in the pile's order, coins, left:
## the goods still in the pile, far: why it is out of reach, R15, "" if it is not (then nothing is taken)}.
func player_loot(i: int) -> Dictionary:
	var l: Dictionary = loot[i]
	var far := player_reach_point(l.pos, TARGET_PROBE + TARGET_REACH)
	if far != "":
		return {"items": [], "coins": 0, "left": l.inv.total(), "far": far}
	var items := []
	for id in l.inv.ids():
		var n: int = l.inv.count(id)
		if player.inv.add(id, n):
			l.inv.remove(id, n)
			items.append([id, n])
	var coins := int(l.coins)
	player.coins += coins
	l.coins = 0
	var left: int = l.inv.total()
	if left == 0:
		loot.remove_at(i)
	return {"items": items, "coins": coins, "left": left, "far": ""}


## DVW-A12 R4: the player plants the sapling `item` from the pack at `cell`: refused ({}) without one in the pack or
## where plant_refusal says no; else the tree is planted (plant_tree) and the sapling is used up, counted for the
## ledger (used_, SEED-02). Returns the tree record, {} if refused.
func player_plant_sapling(cell: Vector2i, item: String) -> Dictionary:
	if not player.inv.has(item) or plant_refusal(cell) != "":
		return {}
	var t := plant_tree(cell, item)
	if not t.is_empty():
		player.inv.remove(item, 1)
		stat("used_" + item)
	return t


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


## The nearest seam of one of `ores` with something left on `level` (MIN-A: the surface unless named).
func nearest_deposit(from: Vector2i, ores: Array, level := 0) -> Dictionary:
	var best := {}
	var bd := 1e9
	for dp in deposits:
		if int(dp.amount) <= 0 or not ores.has(dp.ore) or level_of(dp) != level:
			continue
		var d := from.distance_to(Vector2i(dp.x, dp.y))
		if d < bd:
			bd = d
			best = dp
	return best


func _field_tiles(f: Dictionary) -> void:
	var base: int = map.data.tiles.field[{"tilled": "tilled", "growing": "growing", "ripe": "ripe"}[f.state]]
	var cols := int(map.data.atlases[0].columns)
	for j in int(f.h):
		for i in int(f.w):
			tile_changed.emit(Vector2i(int(f.x) + i, int(f.y) + j), "field", field_cell_tile(base, int(f.w), int(f.h), i, j, cols))


## Tile for cell (i, j) of a w x h field from a 4x4 edge set whose top-left tile is `base`: columns
## are narrow / left / middle / right, rows top / middle / bottom / narrow, so the crop closes
## cleanly on every side (tools/build_village.py field_cell_tile is the same rule).
static func field_cell_tile(base: int, w: int, h: int, i: int, j: int, cols: int) -> int:
	var col := 0 if w == 1 else (1 if i == 0 else (3 if i == w - 1 else 2))
	var row := 3 if h == 1 else (0 if j == 0 else (2 if j == h - 1 else 1))
	return base + row * cols + col


## Days a sown field takes to ripen: field_grow_seasons calendar seasons (TIME-02). The one place to make it
## depend on the season (B8-029's calendar arrives with seasons later: a hook, not a mechanic yet).
## A field's hour: under FSE-13's switch it grows an hour's share at the season's rate, as the player's crops do; it is
## ripe when it has grown (not at the next sunrise).
func grow_field(f: Dictionary) -> void:
	if f.state == "growing" and Farming.seasonal_fields():
		f.progress = float(f.get("progress", 0.0)) + farm.season_rate() / (field_grow_days(f) * 24.0)
		f.ready = 1.0e18 if float(f.progress) < 1.0 else minutes     # (not INF: fields are saved as JSON)
	if f.state == "growing" and minutes >= f.ready:
		f.state = "ripe"
		# the old field model's fixed yield; under the shared model (FSE-12) the crop of the cells sown (Farming.sow_field)
		f.crop = Farming.field_crop(int(f.get("sown", 0))) if Farming.shared_manor() else int(GameData.b("field_yield"))
		f.ripe_at = f.ready
		_field_tiles(f)


func field_grow_days(_f: Dictionary) -> float:
	return Life.seasons_to_days(float(GameData.b("field_grow_seasons")))


## Whether the farmers may cut this ripe field: it has stood ripe for field_ripe_wait_hours (PL2-007: they
## used to cut it within the hour it ripened, so the player never saw a ripe field).
func field_cuttable(f: Dictionary) -> bool:
	return f.state == "ripe" and minutes >= float(f.get("ripe_at", 0.0)) + float(GameData.b("field_ripe_wait_hours")) * 60.0


func set_field(f: Dictionary, state: String) -> void:
	f.state = state
	if state == "growing":
		f.ready = minutes + field_grow_days(f) * DAY
		if Farming.seasonal_fields():     # FSE-13: ripe when its seasonal growth is done (hour())
			f.progress = 0.0
			f.ready = 1.0e18
	elif state == "ripe":
		f.ripe_at = minutes
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
	if cause.begins_with("slain by %s" % player.name) and n.role != "bandit":
		relations.slain_by_player(n)       # family and friends never forget it (CRT-12)
	quests.on_giver_died(n)                # coins set aside for the player's quest pass on with the rest
	contracts.on_death(n)                  # and those set aside for its contracts (CON-01)
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
	if n.household >= 0 and not property._anyone_alive(n.household):
		property.household_ended(n.household)
	npc_died.emit(n)


## Who inherits (B8-029, owner 2026-10-19): the family first (Life.heir_of: eldest adult child, partner, other
## kin); with no family heir, a surviving adult of the household, then an elder, then a child (lowest id
## first, so the choice is deterministic). Null when nobody survives.
func _heir(n: NPC) -> NPC:
	if n.household < 0:
		return null
	var kin := Life.heir_of(self, n)       # B8-029: the family graph first (children, partner, other kin)
	if kin != null:
		return kin
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


## Everyone within `r` tiles of a point and in the same place, asleep or awake: who can be reached,
## tapped, talked to (waking them) or struck. Awareness (witnesses, guards) uses `near`.
func present(p: Vector2, r: float) -> Array:
	var out := []
	var here := place_of(p)
	for n: NPC in npcs:
		if n.alive and n.pos.distance_to(p) <= r and place_of(n.pos) == here:
			out.append(n)
	return out


## Wake a sleeper (owner rule: sleeping limits awareness, it does not make anyone untouchable). They
## get up and decide afresh; at night they go back to bed later. Returns true if they were asleep.
func wake(n: NPC) -> bool:
	if not asleep(n):
		return false
	n.anim = "idle"
	n.plan.clear()
	return true


## PAR-03 (owner OD-18.3): the one recovery model, the player's, for everyone. A rest of `minutes` that lasted to the
## morning (`to_morning`) or at least rest.day_minutes restores health to its cap (and the player's stamina).
## A rest cut short (a villager woken: its plan is cleared, so it never ends) restores nothing. True if it qualified.
func rest_recover(who, minutes: float, to_morning: bool) -> bool:
	if not to_morning and minutes < float(GameData.b("rest").day_minutes):
		return false
	who.hp = who.hp_cap()
	if who is PlayerState:
		who.stamina = who.stamina_cap()
	else:
		stat("rests_recovered")
	return true


## A noise (a fight) wakes the sleepers within `r` tiles in the same place; they can then witness.
func wake_near(p: Vector2, r: float) -> void:
	for n: NPC in present(p, r):
		wake(n)


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


## The interior a building has: its own from the map, or a built building's from its stamp (a
## house's or a workshop's: one interior system for every building).
func interior_for(b: Dictionary) -> Dictionary:
	for mb in map.data.buildings:
		if mb.id == b.id:
			return mb.get("interior", {})
	var stamp := stamp_of(b)
	if not is_built(b) or not stamp.has("interior"):
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


## A house with a finished sleeping loft (HOUSE-12, owner 2026-10-20): its interior gains the loft's
## sleeping places, bed spots marked `loft` whose bed and use cell is the ladder, a floor cell inside the
## house (the first floor cell, in the interior's order, that is no door and no other spot's place). Nobody
## walks up there: a loft sleeper goes to the ladder and is hidden while asleep (in_loft). The spots come
## after the house's own beds, so the sleep order gives them to the later sleepers.
func _with_loft(b: Dictionary, it: Dictionary) -> Dictionary:
	var beds := int(b.get("loft", 0))
	if beds <= 0 or it.is_empty():
		return it
	var out: Dictionary = it.duplicate(true)
	var taken := {}
	for c in out.get("doors", []):
		taken[Vector2i(int(c[0]), int(c[1]))] = true
	for s in out.get("spots", []):
		taken[Vector2i(int(s.at[0]), int(s.at[1]))] = true
	var ladder := Vector2i(-1, -1)
	for c in out.get("floor", []):
		var v := Vector2i(int(c[0]), int(c[1]))
		if not taken.has(v):
			ladder = v
			break
	if ladder.x < 0:
		return it
	for i in beds:
		out.spots.append({"kind": "bed", "at": [ladder.x, ladder.y], "use": [ladder.x, ladder.y], "head": "left", "tile": -1, "loft": true})
	return out


## A villager asleep up in their house's loft (HOUSE-12): not drawn on the ground floor.
func in_loft(n: NPC) -> bool:
	return n.alive and n.anim == "sleep" and bool(home_spot(n, "bed").get("loft", false))


## An interior with the chair spots found in its own tiles (Furniture.with_chairs, PL1-07/PL2-013): the
## map's layers for the map's buildings, the stamp's for one the player builds.
func _with_chairs(b: Dictionary, it: Dictionary) -> Dictionary:
	if it.is_empty():
		return it
	for mb in map.data.buildings:
		if mb.id == b.id:
			var lays := {}
			for l in map.data.layers:
				if Furniture.LAYERS.has(str(l.name)):
					lays[str(l.name)] = l.data
			return Furniture.with_chairs(it, lays, map.w, Vector2i.ZERO)
	var stamp := stamp_of(b)
	return Furniture.with_chairs(it, stamp.get("layers", {}), int(stamp.w), Vector2i(int(b.x), int(b.y)))


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
		var it := _with_loft(buildings[id], _with_chairs(buildings[id], interior_for(buildings[id])))
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


## Whether the player at `from` and something at `to` are on the same side of every wall (PL2-011): not
## across a building's boundary (inside to outside, or one building to another) unless one of them stands
## in that building's doorway, and not through a building that neither is in. Used by every way of
## targeting (the target list, taps, gathering, using).
func reaches(from: Vector2, to: Vector2) -> bool:
	var a := place_of(from)
	var b := place_of(to)
	if a != b:
		var door_ok := false
		for id in [a, b]:
			if id != "" and buildings.has(id):
				var dc := Vector2(building_door(id)) + Vector2(0.5, 0.5)
				if dc.distance_to(from) <= 1.3 or dc.distance_to(to) <= 1.3:
					door_ok = true
		if not door_ok:
			return false
	var ra := roof_over(from)
	var rb := roof_over(to)
	var steps := ceili(from.distance_to(to) / 0.25)
	for k in range(1, steps):
		var s := from.lerp(to, float(k) / float(steps))
		var in_b := place_of(s)
		if in_b == "":
			in_b = roof_over(s)
		if in_b != "" and not [a, b, ra, rb].has(in_b):
			return false
	return true


## The building whose roof covers a point, "" for none (inside it, or behind its eaves).
func roof_over(p: Vector2) -> String:
	return _cell_lookup(roof_idx, p)


const LODGERS := ["guard", "cook"]     # sleep on the straw pallets where their household lives


func asleep(n: NPC) -> bool:
	return n.alive and n.anim == "sleep"


## A villager's own spot of a kind ("bed", "table", "chest", "hearth") in their home: the household
## shares them out by member order (beds first, then the straw pallets); {} if the home has none.
func home_spot(n: NPC, kind: String) -> Dictionary:
	var mine := []
	var pallets := []
	for room in (property.rooms_of(n.home) if kind == "bed" else [n.home]):     # living quarters and small rooms add beds
		for s in interiors.get(room, {}).get("spots", []):
			if s.kind == kind:
				(pallets if int(s.get("tile", -1)) % 100000 == 593 else mine).append(s)
	mine.append_array(pallets)          # the beds of every room before the house's straw pallets
	if mine.is_empty():
		return {}
	var i := 0
	if n.household >= 0 and str(households[n.household].home) == n.home:
		i = maxi(0, _sleep_order(n.household).find(n.id))
	elif n.household >= 0:
		# lodging with the family they came from until their own house stands: the next free place
		var host := household_in(n.home)
		i = (households[host].members as Array).size() if host >= 0 else 0
	return mine[i % mine.size()]


## A household's members in the order they take its sleeping places (beds first, then straw pallets):
## the family before those lodging for their work, guards and cooks (owner rule: villagers with homes
## sleep in their own beds; pallets are for guards and cooks).
func _sleep_order(hh: int) -> Array:
	var family := []
	var lodgers := []
	for id in households[hh].members:
		var m := npc(int(id))
		(lodgers if m != null and m.job in LODGERS else family).append(int(id))
	return family + lodgers


## The cell to go to for a home spot (the use cell), or the home's door when it has none.
func home_cell(n: NPC, kind: String) -> Vector2i:
	var s := home_spot(n, kind)
	if s.is_empty():
		return building_door(n.home)
	return Vector2i(int(s.use[0]), int(s.use[1]))


## Someone (the player or a villager) is standing on cell `c`, so it must not become solid.
func _someone_on(c: Vector2i) -> bool:
	var r := Rect2(Vector2(c) - Vector2(0.35, 0.25), Vector2(1.7, 1.45))     # the cell, widened by the feet
	if player.alive and r.has_point(player.pos):
		return true
	for n: NPC in npcs:
		if n.alive and r.has_point(n.pos):
			return true
	return false


## Collision of a built building: its stamp's (walls, furniture and stations solid, floor walkable),
## or the whole footprint for a stamp without one; the doorway is open.
func _built_collision(b: Dictionary) -> void:
	var mask: Array = stamp_of(b).get("solid", [])
	for j in int(b.h) - 1:
		for i in int(b.w):
			var s := true if mask.is_empty() else str(mask[j])[i] == "1"
			map.set_solid(Vector2i(int(b.x) + i, int(b.y) + j), s)
	map.set_solid(Vector2i(int(b.door[0]), int(b.door[1]) - 1), false)


## Where household `h` is found: its house's door, or, for a household with no house standing (homeless, or its home
## not a building), `fallback` (a member's cell). Seed 2 at shared_wheat_yield 2.5 (FARM-08 run): a couple of a homeless
## household looked up the door of a home that was not there, 37 script errors.
func household_cell(h: int, fallback: Vector2i) -> Vector2i:
	var home := str(households[h].get("home", "")) if h >= 0 and h < households.size() else ""
	return building_door(home) if home != "" and buildings.has(home) else fallback


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
	trees = trees.filter(func(t): return t.get("planted", false) or on_map.has(Vector2i(int(t.x), int(t.y))))


func plot(id: String) -> Dictionary:
	for p in plots:
		if p.id == id:
			return p
	return {}


## Generic construction (owner rules, 2026-10-18: a frame site with a progress bar, materials only and
## no extra build time, cancelling returns everything, NPCs build by the same rules; property phase 2).
## A site is marked out on a parcel (`p.site`: kind, cost, need, done, owner) for a building of any
## kind (Construction.KINDS: a house, or a workshop once the builder owns a house). It will be its
## `owner`'s, the parcel's holder by default (the owner, or the tenant on leased ground), whoever
## brings the materials: the player, a hired helper or a villager founding a household.
func start_site(p: Dictionary, kind := "house", owner := "") -> void:
	var cost: Dictionary = construction.cost_of(kind).duplicate()
	var ground := property.describe(p)
	farm.give_up_cells(p)              # a field on the ground is ploughed under for the building (PL2-015)
	p.site = {"kind": kind, "cost": cost, "need": cost.duplicate(), "done": false, "owner": owner if owner != "" else holder_of(p)}
	if kind != "loft":                 # a loft goes up under the house's own roof: no frame on its floor
		var frame: int = map.data.tiles.frame
		tile_changed.emit(_frame_cell(p), "below", frame)
	note("%s marks out %s on %s." % [ref_name(str(p.site.owner), true), Construction.kind_name(kind, true), ground])


## The frame stands at the middle of the site, a row above its door step.
func _frame_cell(p: Dictionary) -> Vector2i:
	return Vector2i(int(p.x) + int(p.w) / 2, int(p.y) + int(p.h) - 2)


## Deliver materials from `inv` to a site; returns true when the building is complete. Anyone may
## deliver (`by`, a reference, for the record): the building is the site's owner's.
func deliver(p: Dictionary, inv: Inventory, by := "") -> bool:
	if p.site.is_empty() or p.site.done:
		return false
	var need: Dictionary = p.site.need
	var given := 0
	for id in need.keys():
		var n := mini(int(need[id]), inv.count(id))
		if n > 0:
			inv.remove(id, n)
			given += n
			need[id] = int(need[id]) - n
			if need[id] <= 0:
				need.erase(id)
	if given > 0 and by != "" and by != str(p.site.get("owner", "")):
		stat("site_loads_by_others", given)
	if need.is_empty():
		_finish_site(p)
		return true
	return false


## The last load is in: the building stands, its owner's (the site's owner), with its interior, its
## collision, its roof and, for a workshop, its stations. Its materials are used up in it (counted in
## stats "used_building_<item>" for the goods ledger).
func _finish_site(p: Dictionary) -> void:
	p.site.done = true
	var kind := str(p.site.get("kind", "house"))
	if kind == "loft":
		_finish_loft(p)
		return
	var by := str(p.site.get("owner", holder_of(p)))
	var fam := player.family if by == PLAYER else (str(households[ref_id(by)].family) if by.begins_with("hh:") else "the manor's")
	var b := {"id": ("house_" if kind == "house" else "workshop_") + str(p.id), "type": "player_house" if kind == "house" else "workshop",
			  "kind": kind, "stamp": Construction.stamp_name(kind), "x": p.x, "y": p.y, "w": p.w, "h": p.h,
			  "door": p.door, "name": "%s family %s" % [fam, Construction.kind_name(kind)],
			  "owner": by, "tenant": "", "parcel": p.id}
	if kind != "house":
		b.allow = []
	var cost: Dictionary = p.site.get("cost", {})
	for id in cost:
		stat("used_building_" + str(id), float(cost[id]))
	buildings[b.id] = b
	p.building = b.id
	tile_changed.emit(_frame_cell(p), "below", -1)
	_built_collision(b)
	_workshop_stations(b)
	index_interiors()
	building_added.emit(b)
	note("%s is finished." % cap(property.describe(b)))
	property._settle(by)               # a family's first house becomes its home
	construction.on_finished(b)        # a founding household moves in


## A sleeping loft is finished (HOUSE-12): no new building; the house gains its loft (World._with_loft) and
## the parcel's site goes back to the finished house it heads. Its materials are used up in it.
func _finish_loft(p: Dictionary) -> void:
	var b := property.building_on(p)
	var cost: Dictionary = p.site.get("cost", {})
	for id in cost:
		stat("used_building_" + str(id), float(cost[id]))
	b.loft = int(Construction.loft_cfg().beds)
	p.site = {"kind": "house", "cost": {}, "need": {}, "done": true, "owner": str(p.site.get("owner", holder_of(p)))}
	index_interiors()
	note("The sleeping loft in %s is finished." % property.describe(b))


## "the Reed family's house" -> "The Reed family's house".
static func cap(s: String) -> String:
	return s if s == "" else s[0].to_upper() + s.substr(1)


## Buildings put up in the game (from a stamp) rather than drawn on the map: houses and workshops.
static func is_built(b: Dictionary) -> bool:
	return str(b.get("type", "")) in ["player_house", "workshop"]


## The stamp a built building is drawn from (village.json "stamps"): the house, or a workshop's.
func stamp_of(b: Dictionary) -> Dictionary:
	var stamps: Dictionary = map.data.stamps
	return stamps.get(str(b.get("stamp", "house")), stamps.house)


## A workshop's stations, from its stamp, placed with it (map data, not saved: made again on load).
## Their ids sort after the map's ("ws_..."), so villagers try the village's own stations first.
func _workshop_stations(b: Dictionary) -> void:
	if str(b.get("type", "")) != "workshop":
		return
	for s in stamp_of(b).get("stations", []):
		var id := "ws_%s_%s" % [b.id, s.type]
		stations[id] = {"id": id, "type": s.type, "building": b.id, "users": {}, "owner": owner_of(b), "tenant": "",
				"at": [int(b.x) + int(s.at[0]), int(b.y) + int(s.at[1])], "use": [int(b.x) + int(s.use[0]), int(b.y) + int(s.use[1])]}


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
		loot.append({"pos": Vector2(float(p.door[0]) + 0.5, float(p.door[1]) + 0.5), "inv": left, "coins": 0, "from": "the building site"})
	if str(p.site.get("kind", "")) == "loft":          # a loft given up: the house it was for stands as it was
		p.site = {"kind": "house", "cost": {}, "need": {}, "done": true, "owner": str(p.site.get("owner", holder_of(p)))}
		note("The sleeping loft planned in %s was given up; its materials were taken back." % property.describe(p))
		return back
	p.site = {}
	tile_changed.emit(_frame_cell(p), "below", -1)
	note("The building site on %s was given up; its materials were taken back." % property.describe(p))
	return back


## Materials lying on unfinished sites, item -> count (the goods ledger counts them as still held).
func site_goods() -> Dictionary:
	var out := {}
	for p in plots:
		if not p.site.is_empty() and not p.site.get("done", false):
			var got := site_delivered(p)
			for id in got:
				out[id] = int(out.get(id, 0)) + int(got[id])
	return out


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


## The player harvests a handful from a field. A field is the manor's, and its crop the farmers' who
## work it (field_workers): taking from it without being one of them is theft, and anyone within sight remembers it, except what a farmer
## hired the player to cut there (Quests.hired_harvest).
func player_harvest(f: Dictionary) -> int:
	var n := take_crop(f, int(GameData.b("harvest_handful")))
	if n <= 0:
		return 0
	player.inv.add("wheat", n)
	var taken := n - quests.hired_harvest(f, n)
	var victim := field_owner(f)
	if victim != null and taken > 0:
		player.mark_stolen("wheat", victim.id, taken)
		witness("theft", "%d wheat from %s" % [taken, f.id], victim, {"wheat": taken})
	return n


## Record what the village saw the player do: people within sight (awake, and in the same building as
## the player or, outdoors, outside: World.near) remember it,
## and so does the victim. A guard among them stops the player (guard_confront): `taken` (item ->
## count) goes back into `back`, or to the victim. `deed` is what they saw, "take <what>" by default.
## Returns how many saw it; what a guard said is in last_guard.
func witness(kind: String, what: String, victim: NPC, taken := {}, back: Inventory = null, deed := "", radius := -1.0) -> int:
	var seen := []
	var guard: NPC = null
	last_guard = ""
	for n: NPC in near(player.pos, radius if radius >= 0.0 else float(GameData.b("witness_radius"))):
		if n.role != "bandit":
			seen.append(n)
			n.remember("saw %s %s %s" % [player.name, player.family, deed if deed != "" else "take " + what])
			relations.harmed(n, float(Relations.cfg().witness_harm))          # a crime seen lowers the tie (CRT-10)
			if n.job == "guard" and n.target == -1 and (guard == null or n.pos.distance_to(player.pos) < guard.pos.distance_to(player.pos)):
				guard = n
	if victim and not seen.has(victim) and deed == "":
		victim.remember("found %s missing" % what)
	if victim:
		relations.harmed(victim, float(Relations.cfg().victim_harm))
	var worth := goods_value(taken)
	var count := 0
	for id in taken:
		count += int(taken[id])
	player.crimes.append({"day": day(), "kind": kind, "what": what, "victim": victim.id if victim else -1, "witnesses": seen.size(),
			"items": taken.duplicate(), "qty": count, "value": worth})
	if worth > 0:
		stat("player_stolen_value", worth)
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


## The base value of goods {id: qty} (what a theft is counted by, Build 13).
static func goods_value(goods: Dictionary) -> int:
	var v := 0
	for id in goods:
		v += GameData.value(str(id)) * int(goods[id])
	return v


## A guard's fine for a crime over `goods`: theft_fine, plus theft_fine_share of what they are worth.
static func theft_fine_for(goods: Dictionary) -> int:
	return int(GameData.b("theft_fine")) + roundi(float(goods_value(goods)) * float(GameData.b("theft_fine_share")))


## A guard stops the player (theft seen, a pocket picked, stolen goods offered for sale; agent
## proposal): what was taken goes back where it came from (`back`) or to its owner, and the player
## pays theft_fine_for(taken) (a base fine plus a share of the goods' value) to the manor's treasury. One who cannot pay it all pays what they have and the
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
	var fine := theft_fine_for(taken)
	# friends back the player up (CRT-06): a guard who is a friend lets them off with a warning; a friend
	# among those near speaks up and halves the fine
	var spoke: NPC = null
	if relations.player_friend(g):
		fine = 0
	else:
		for o: NPC in near(player.pos, float(GameData.b("witness_radius"))):
			if o != g and o != owner and relations.player_friend(o):
				spoke = o
				break
		if spoke != null:
			fine = fine / 2
	var paid := mini(fine, player.coins)
	player.coins -= paid
	treasury += paid
	stat("gov_fines", paid)
	g.remember("caught %s %s stealing" % [player.name, player.family])
	var who := "%s %s" % [g.name, g.family]
	var text := "The guard %s stops you." % who
	if not returned.is_empty():
		text += " The %s goes back to %s." % [", ".join(returned), "its owner" if owner == null else owner.name]
	if spoke != null:
		text += " Your friend %s speaks up for you." % spoke.name
	if fine == 0 and relations.player_friend(g):
		text += " \"Don't let me catch you at it again, friend.\" You are let off with a warning."
	else:
		text += " You pay a fine of %d coins to the manor." % paid if paid == fine else " You can pay only %d of the %d coins' fine: %s draws a weapon!" % [paid, fine, g.name]
	if paid < fine:
		g.target = -2
	note("The guard %s stopped %s %s for theft%s." % [who, player.name, player.family, " and fined them %d coins" % paid if paid > 0 else ""])
	return text


## The nearest guard on duty (out and not fighting) within `r` tiles of a point, or null.
## PAR-05 (owner OD-18.5 and the final directive, section 9): who learns of an attack, for any attacker, the player
## or a villager, by the one channel the world has for seeing: `seen`, the people who see it (near the blow,
## witness_radius: awake and in the same place, the rule a theft is seen by). The victim knows too. There is no
## hearing. Detection only: the response is raise_alarm, and word passes on by report (report_crime).
func aware_of_attack(at: Vector2, victim: NPC) -> Dictionary:
	var seen := near(at, float(GameData.b("witness_radius")))
	seen.erase(victim)
	return {"seen": seen, "victim": victim}


## The response to an attack (aware_of_attack): every free guard who saw it takes on the attacker (`attacker` an NPC
## id, or -2 for the player); the victim and the others who saw it carry a report to a guard (report_crime). Returns
## how many guards answered at once.
func raise_alarm(aware: Dictionary, attacker: int) -> int:
	var k := 0
	for n: NPC in aware.seen:
		if n.job == "guard":
			if n.target == -1 and n.id != attacker:
				n.target = attacker
				k += 1
		elif n.role != "bandit" and n.id != attacker:
			report_crime(n, attacker, "saw")
	var v: NPC = aware.get("victim", null)
	if v != null and v.alive and v.role != "bandit" and v.id != attacker:
		if v.job == "guard":
			if v.target == -1:
				v.target = attacker
		else:
			report_crime(v, attacker, "victim")
	if k > 0:
		stat("guards_alarmed", k)
	return k


## PAR-05: `n` knows of an attack by `offender` (an NPC id, -2 the player) and will tell a guard: when one is in sight
## they report it (NPCBrain._report), and seek one out within report.range tiles. The report lapses after
## report.hours. `how`: "saw" or "victim". `crime`: "attack", or "theft" for a caught pickpocket (PICK-01). Saved with
## the villager (older saves: an attack).
func report_crime(n: NPC, offender: int, how: String, crime := "attack") -> void:
	n.report = {"offender": offender, "t": minutes, "how": how}
	if crime != "attack":
		n.report.crime = crime
	stat("crime_reports_made")


## Whether the offender of a report can still be pursued: alive (the player alive, or the villager).
func offender_alive(offender: int) -> bool:
	if offender == -2:
		return player.alive
	var o := npc(offender)
	return o != null and o.alive


## The guard a report reaches: `g` takes on the offender when free (PAR-05's response). True when delivered.
## A theft (PICK-01, owner OD-20): the guard now knows of it, and answers it as a guard who sees a theft does
## (guard_confront: the fine) if the thief is in the guard's sight then; it is not an attack, so no chase.
func deliver_report(n: NPC, g: NPC) -> bool:
	var off := int(n.report.offender)
	var crime := str(n.report.get("crime", "attack"))
	n.report = {}
	if not offender_alive(off):
		return true
	stat("crime_reports_delivered")
	if crime == "theft":
		g.remember("told by %s %s of a theft" % [n.name, n.family])
		stat("theft_reports_delivered")
		if off == -2 and g.target == -1 and near(player.pos, float(GameData.b("witness_radius"))).has(g):
			last_guard = guard_confront(g, {}, null, null)
		return true
	g.remember("told by %s %s of an attack" % [n.name, n.family])
	if g.target == -1 and g.id != off:
		g.target = off
	return true


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


## Whose goods they are: the one who notices them missing and whose they are if sold back. Derived
## from who holds the stall or building (holder_of): a stall's merchant, the tavern's keepers (the
## household the manor lets it to), a house's household (its head). The player's and the manor's
## houses hold nothing in their crates (the player's things are in the family chest).
func container_owner(c: Dictionary) -> NPC:
	if stalls.has(c.at):
		return party(holder_of(stalls[c.at]))
	if _is_tavern(c.at):
		if c.kind == "table":
			var k := npc(int(c.get("keeper", -1)))
			if k and k.alive:
				return k
		return tavern_keeper()
	if not buildings.has(c.at):
		return null
	var ref := holder_of(buildings[c.at])
	return party(ref) if ref.begins_with("hh:") else null


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
## there was nothing, "full" if the pack has no room, or "far" if it is out of the player's reach (DVW-A12 R15:
## player_container_reach says why).
func player_take(c: Dictionary) -> String:
	if player_container_reach(c) != "":
		return "far"
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
	if (int(player.crimes[-1].witnesses) if not player.crimes.is_empty() else 0) == 0:
		player_xp("stealth", 3)                      # a theft nobody saw teaches Stealth (DVW-A12 R6)
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
	if n.home != "" and int(front_keepers.get(n.home, -1)) == n.id and buildings.get(n.home, {}).has("front"):
		var f: Dictionary = buildings[n.home].front               # keeping the household's storefront (B14)
		return Vector2(int(f.use[0]) + 0.5, int(f.use[1]) + 0.5)
	for id in counters.serving:                                    # come to a skilled trade's counter (CTR-02)
		if int(counters.serving[id]) == n.id:
			return Vector2(station_use(id)) + Vector2(0.5, 0.5)
	if n.job == "tavernkeeper" and stations.has(n.workplace):
		return Vector2(station_use(n.workplace)) + Vector2(0.5, 0.5)
	if n.job == "merchant" and stalls.has(n.workplace) and tenant_of(stalls[n.workplace]) == npc_ref(n.id):
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
		if (n.workplace == post or int(counters.serving.get(post, -1)) == n.id) and at_post(n) and (best == null or n.id < best.id):
			best = n
	return best


## "tavern", "food stall": the shop's name in prompts.
func shop_name(n: NPC) -> String:
	if n.home != "" and int(front_keepers.get(n.home, -1)) == n.id and at_post(n):
		return "the %s family's storefront" % n.family
	for id in counters.serving:
		if int(counters.serving[id]) == n.id:
			return counters.counter_name(id)
	if n.job == "tavernkeeper":
		return "tavern"
	return {"raw": "ore and timber stall", "food": "food stall", "goods": "tools and arms stall"}.get(stalls[n.workplace].kind, "stall")


## DVW-A12 R14: how near (tiles) the player must stand to a villager for their pocket to be within reach, awake or
## asleep (lead decision under the owner's standing directive, 2026-10-21: the sleeper's window used to offer it at
## any distance a target is chosen from).
const PICKPOCKET_REACH := 1.8


## DVW-A12 R14: whether villager `n` is someone whose pocket the player can reach: within PICKPOCKET_REACH, and never
## a child (owner, B8-010). The talk window offers the try only then; pickpocket() refuses it otherwise.
func pickpocket_in_reach(n: NPC) -> bool:
	return player.pos.distance_to(n.pos) <= PICKPOCKET_REACH and n.role != "child"


## The chance a try at an awake victim works: the base plus the Stealth tier's steps, at most the cap.
func pickpocket_chance() -> float:
	return minf(float(GameData.b("pickpocket_chance")) + float(GameData.b("pickpocket_chance_per_level")) * Skills.value(player, "stealth", "pickpocket_steps"), float(GameData.b("pickpocket_chance_max")))


## The player tries to pick the pocket of the villager beside them (owner rule). The chance grows
## with Stealth (pickpocket_chance + pickpocket_chance_per_level x the tier's pickpocket_steps, at most
## pickpocket_chance_max). Success: a few coins, or one thing they carry (marked as stolen from them),
## and they find it missing later. Caught: they remember it, anyone in sight sees the try, and a guard
## who sees it stops the player (guard_confront); Stealth's guard_radius shortens how far a caught try is seen.
## PICK-01 (owner OD-20, 2026-10-21): there is no cry a guard hears;
## otherwise the victim and those who saw it carry a theft report to a guard (report_crime, as PAR-05's attack), and
## a theft nobody sees is known to no guard. Each try earns Stealth xp (DVW-A12 R6): 8 when it works, 2 otherwise; a
## pocket out of reach is no try (`refused`, R14). Returns {ok, what, text} (and `refused`).
func pickpocket(n: NPC) -> Dictionary:
	var r := _pickpocket_try(n)
	if not r.get("refused", false):
		player_xp("stealth", 8 if r.ok else 2)
	return r


func _pickpocket_try(n: NPC) -> Dictionary:
	if not n.alive or n.role == "bandit":
		return {"ok": false, "what": "", "text": "There is nobody to rob."}
	if n.role == "child":                       # owner, 2026-10-18 (B8-010): never a child's pocket
		return {"ok": false, "what": "", "text": "You will not rob a child."}
	if player.pos.distance_to(n.pos) > PICKPOCKET_REACH:          # DVW-A12 R14: beside them, awake or asleep
		return {"ok": false, "what": "", "text": "%s is out of reach." % n.name, "refused": true}
	var chance := pickpocket_chance()
	var sleeping := asleep(n)
	if sleeping:                        # a sleeper is unaware: easier, but a fumble wakes them
		chance = minf(chance + float(GameData.b("pickpocket_asleep_bonus")), float(GameData.b("pickpocket_asleep_max")))
	var who := "%s %s" % [n.name, n.family]
	last_guard = ""
	if rng.randf() < chance:
		var what := ""
		var got := {}
		var worth := 0
		if n.coins > 0:
			var k := mini(n.coins, rng.randi_range(1, int(GameData.b("pickpocket_coins_max"))))
			n.coins -= k
			player.coins += k
			what = "%d coin%s" % [k, "" if k == 1 else "s"]
			worth = k
		else:
			var ids := []
			for id in n.inv.ids():
				if not brain.keeps(n, id) and player.inv.can_add(id):
					ids.append(id)
			if ids.is_empty():
				return {"ok": true, "what": "", "text": "%s's pockets are empty." % n.name}
			var id: String = ids[rng.randi() % ids.size()]
			n.inv.remove(id)
			player.inv.add(id)
			player.mark_stolen(id, n.id, 1)
			what = "1 " + GameData.item_name(id).to_lower()
			got = {id: 1}
			worth = goods_value(got)
		n.remember("found %s missing" % what)
		player.crimes.append({"day": day(), "kind": "pickpocket", "what": "%s from %s" % [what, who], "victim": n.id, "witnesses": 0,
				"items": got, "qty": maxi(1, got.size()), "value": worth})
		stat("player_pickpocket")
		return {"ok": true, "what": what, "text": "You lift %s from %s unseen." % [what, who]}
	wake(n)                             # a fumble wakes a sleeper: now they know
	n.remember("caught %s %s picking my pocket" % [player.name, player.family])
	# Stealth's guard_radius: a practised hand's fumble is noticed over a shorter distance (as a quiet lock, lockpick_quiet)
	var sight := float(GameData.b("witness_radius")) * Skills.value(player, "stealth", "guard_radius", 1.0)
	var seen := witness("pickpocket", "a try at %s's purse" % who, n, {}, null, "try to pick %s's pocket" % who, sight)
	var text := "%s catches your hand in their pocket!" % n.name
	if last_guard == "":
		# no guard saw it: the victim and the others who saw it will tell one (PICK-01)
		for o: NPC in near(player.pos, sight):
			if o != n and o.role != "bandit" and o.job != "guard":
				report_crime(o, -2, "saw", "theft")
		if n.alive and n.job != "guard":
			report_crime(n, -2, "victim", "theft")
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
	if not can_afford(buyer, price, false, id) or not trade(buyer, player, id, 1, price):
		return {"result": "failed", "text": "They cannot afford it right now."}
	if not owners.is_empty():
		player.unmark(id, int(owners[0]), 1)
	return {"result": "sold", "text": ""}


## Sell `qty` of `id` (the quantity control, PL1-03), each unit at its player_quote price, so the buyer's
## offer falls as they fill up (Build 13 economy rule 2). Checked first: you carry them, the buyer still
## wants that many and their own coins cover the whole bill and their reserve (rule 1: no buying without the
## money; OD-18.2, OD-19, TRADE-01: the villagers' rule, purchase_qty; refused with sale_refusal's reason), so
## nothing is half-sold for those reasons. Each unit goes through player_sell (marked goods first,
## recognition, guard questions), so a stolen piece being recognised stops the sale at that unit; `sold`
## says how many went and `paid` what they fetched. Returns {result, text, sold, paid}.
func player_sell_many(buyer: NPC, id: String, qty: int) -> Dictionary:
	if qty < 1 or not player.inv.has(id, qty):
		return {"result": "failed", "text": "You do not carry that many.", "sold": 0, "paid": 0}
	var no := sale_refusal(buyer, player, id, qty)       # TRADE-01: the villagers' rule (purchase_qty)
	if no != "":
		return {"result": "failed", "text": no, "sold": 0, "paid": 0}
	var sold := 0
	var paid := 0
	for i in qty:
		var price: int = player_quote(buyer, id, 1, false)[0]      # the live price: the buyer's stock has grown by `sold`
		var r: Dictionary = player_sell(buyer, id, price)
		if r.result != "sold":
			r["sold"] = sold
			r["paid"] = paid
			if sold > 0:
				player_xp("trading", Skills.trade_xp(paid))      # what was sold before it stopped (DVW-A12 R13)
			return r
		sold += 1
		paid += price
	deal_xp(buyer, player, paid)
	player_xp("trading", Skills.trade_xp(paid))               # the player's Trading xp for the deal (DVW-A12 R13)
	return {"result": "sold", "text": "", "sold": sold, "paid": paid}


func player_eat(id: String) -> bool:
	var it: Dictionary = GameData.item(id)
	if not it.has("food") or not player.inv.remove(id):
		return false
	player.hunger = minf(100.0, player.hunger + float(it.food))
	if it.has("heal"):
		player.hp = minf(player.hp_cap(), player.hp + float(it.heal))
	if it.has("stamina"):
		player.stamina = minf(player.stamina_cap(), player.stamina + float(it.stamina))
	if it.has("harm"):
		damage_player(float(it.harm), "spoiled food")
	stat("eaten_food", float(it.food))
	stat("eaten_" + id)
	return true


## Use a medicine (items.json type "medicine": it heals `heal` health and feeds nobody). Consumed only
## when it heals: at full health nothing is used up. Never above the health cap (PL1-04).
func player_use_medicine(id: String) -> bool:
	var it: Dictionary = GameData.item(id)
	if not it.has("heal") or it.has("food") or not player.alive or player.hp >= player.hp_cap() - 0.001:
		return false
	if not player.inv.remove(id):
		return false
	player.hp = minf(player.hp_cap(), player.hp + float(it.heal))
	stat("used_medicine")
	stat("used_" + id)
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
	_loot_on_player_level(loot[loot.size() - 1])
	return true


## What the player's own work makes (mining, felling, crafting): counted for the goods ledger as `kind` + id
## (made_, mined_, felled_), as the villagers' work is, and put in the pack; what the pack cannot hold is set
## down where the player stands, never lost (DVW-A7). Returns how many went into the pack.
func player_gain(id: String, n: int, kind := "made_") -> int:
	if n <= 0:
		return 0
	stat(kind + id, float(n))
	if player.inv.add(id, n):
		return n
	var bag := Inventory.new()
	bag.add(id, n)
	loot.append({"pos": player.pos + Vector2(0, 0.4), "inv": bag, "coins": 0, "from": "dropped by %s" % player.name})
	_loot_on_player_level(loot[loot.size() - 1])
	return 0


## DVW-A12 R12: the player learns Fireball from `teacher` (the sage, DECISIONS.md:57): balance.json fireball_price
## coins go from the player to the teacher, the spell is known, 100 Magic xp is earned, and a story quest to learn it is
## completed (Quests.on_learned). Refused if it is known already or the player cannot pay. `thanks`: the story's
## thanks line from the teacher, read before the quest is completed ("" for none). Returns {ok, why, thanks}.
func player_learn_fireball(teacher: NPC) -> Dictionary:
	var price := int(GameData.b("fireball_price"))
	if player.spells.get("fireball", false):
		return {"ok": false, "why": "You know Fireball."}
	if player.coins < price:
		return {"ok": false, "why": "You need %d coins." % price}
	player.coins -= price
	teacher.coins += price
	player.spells["fireball"] = true
	player.gain("magic", 100)
	var story: Dictionary = quests.active_from(teacher)
	var thanks := quests.line(story, "thanks") if not story.is_empty() else ""
	quests.on_learned("fireball")
	return {"ok": true, "why": "", "thanks": thanks}


## The player buys a building plot; the price goes to the manor's treasury (Property.buy).
func buy_plot(p: Dictionary) -> bool:
	return property.buy(p, PLAYER) == ""


# ---------------------------------------------------------------- ownership ------------------
## One owner reference for everything that can be owned or held (agent proposal on the owner's rules
## of 2026-10-18; docs/BUILD_DECISIONS.md "Property and land"): a String,
##   "manor"     the manor: unsold land, empty houses, the manor house, tavern and smithy, the fields,
##               pens, stalls and stations (its coins are `treasury`);
##   "player"    the player's family, their own household: it outlives each character, so the heir
##               holds all the family held;
##   "hh:<id>"   a villager household (index into `households`);
##   "npc:<id>"  one villager, only as a tenant of their work (a stall's merchant, a pen's keeper);
##               people own land and buildings only as households (owner rule).
## Every property record (buildings, plots, stalls, fauna pens, fields, stations) has `owner` (a
## reference) and `tenant` (a reference, "" for none: who has the use of it); a let one also `rent`
## (coins a week), `due_day`, `arrears`, `missed`. These functions are the only way to ask and to
## change who owns or holds a thing; Property (the land office) deals through them.
const MANOR := "manor"
const PLAYER := "player"
const ANIMAL_LOOT_DAYS := 3.0     # a carcass left lying spoils after this many days
const SAVE_VERSION := 17          # 17: Build 17 underground (MIN-A): "underground" {gen, player_level}, deposits and loot may carry "level" (absent = the surface); a 16 to 14 save loads with the player on the surface and the gallery's seams full (absent keys are defaults; no migration); 16: Build 16 farmland and stalls (FARM-01..09: World "farm_plots" cells and parcels marked "farm"; STALL-01..06: built stalls and every stall's open, session, frac and settlements in World.stalls); a 15 or 14 save loads with no farmland and every stall closed with nothing unsettled (absent keys are defaults; no migration); 15: PAR-01 villagers' skills (NPC.skills; a 14 save's villagers are given, once, a plausible history in their trade on load, Skills.seed_villagers; a 15 save is never re-seeded); 14: B8-029 aging (NPC, PlayerState and Animal carry born, sex, mother, father, partner, children; owner: older saves are disposable); 13: the village laid out anew (tools/build_village.py generator v6: buildings, roads, trees, deposits and stations stand elsewhere; owner 2026-10-19: older saves are disposable, none is migrated: SaveStore.MIN_VERSION refuses them and keeps the file); 12: the tree lifecycle (trees carry species and a growth stage; planted trees; the overworld's changed trees carry species, stage and planted; owner: older saves are disposable, none is migrated); 11: the caravan's purse (caravan_purse; economy work, no migration); 10: the overworld (its seed, and the trees felled in it; owner: older saves are disposable, none is migrated);  9: wild plants, picked or ripe (older saves load with every plant ripe);  8: the manor's work (lots, works yard, jobs); 7: quest rewards set aside (reserved); 6: property phase 2 (site kinds, workshops, helpers' contracts, founded households)


static func hh_ref(h: int) -> String:
	return "hh:%d" % h


static func npc_ref(id: int) -> String:
	return "npc:%d" % id


## The number in "hh:<id>" or "npc:<id>"; -1 for the manor, the player or nobody.
static func ref_id(ref: String) -> int:
	return int(ref.get_slice(":", 1)) if ref.contains(":") else -1


func owner_of(thing: Dictionary) -> String:
	return str(thing.get("owner", MANOR))


func tenant_of(thing: Dictionary) -> String:
	return str(thing.get("tenant", ""))


## Who has the use of it: the tenant, or the owner when it is not let.
func holder_of(thing: Dictionary) -> String:
	var t := tenant_of(thing)
	return t if t != "" else owner_of(thing)


## Owns it or leases it.
func holds(ref: String, thing: Dictionary) -> bool:
	return ref != "" and (owner_of(thing) == ref or tenant_of(thing) == ref)


func set_owner(thing: Dictionary, ref: String) -> void:
	thing.owner = ref
	if str(thing.get("type", "")) in ["workshop", "player_house"]:          # a workshop's stations change hands with it
		for id in stations:
			if str(stations[id].get("building", "")) == str(thing.get("id", "")):
				stations[id].owner = ref


## Let it to `ref` for `rent` coins a week (the first week counts from today), or end the letting
## with ref "".
func set_tenant(thing: Dictionary, ref: String, rent := 0) -> void:
	thing.tenant = ref
	if ref == "" or rent <= 0:
		for k in ["rent", "due_day", "arrears", "missed"]:
			thing.erase(k)
		return
	thing.rent = rent
	thing.due_day = day() + Property.WEEK
	thing.arrears = 0
	thing.missed = 0


## The villager a reference names, alive: the one for "npc:<id>", the head of a household (its first
## adult, elder or child by member order) for "hh:<id>"; null for the manor, the player or nobody.
func party(ref: String) -> NPC:
	if ref.begins_with("npc:"):
		var o := npc(ref_id(ref))
		return o if o and o.alive else null
	if ref.begins_with("hh:"):
		var h := ref_id(ref)
		if h < 0 or h >= households.size():
			return null
		for role in ["adult", "elder", "child"]:
			for m in households[h].members:
				var o := npc(int(m))
				if o and o.alive and o.role == role:
					return o
	return null


## "the manor", "Wat Ashdown", "the Reed household", "Ellen Mercer" (for messages); `subject` for the
## start of a sentence.
func ref_name(ref: String, subject := false) -> String:
	if ref == PLAYER:
		return "%s %s" % [player.name, player.family]
	if ref == MANOR:
		return "The manor" if subject else "the manor"
	if ref.begins_with("hh:") and ref_id(ref) < households.size():
		return ("The %s household" if subject else "the %s household") % households[ref_id(ref)].family
	var o := npc(ref_id(ref))
	return "%s %s" % [o.name, o.family] if o else "nobody"


## Where a stretch of ground lies, for names the player reads: "north of the tavern", "beside the
## Reed family's house", "east of the market". The nearest landmark: the named buildings, the houses
## (by the family who live or lived there), the well, the market, the mine, the fields and the pens;
## `exclude` a building not to name it by itself, `avoid` a name not to name it by ("the Stone family's
## house north of the Stone family's house").
func where(r: Rect2i, exclude := "", avoid := "") -> String:
	var best := ""
	var bd := 1e9
	var bc := Vector2.ZERO
	for lm in _landmarks():
		if str(lm[0]) == exclude or (avoid != "" and str(lm[1]) == avoid):
			continue
		var lr: Rect2i = lm[2]
		var gap := Vector2(maxi(0, maxi(lr.position.x - r.end.x, r.position.x - lr.end.x)), maxi(0, maxi(lr.position.y - r.end.y, r.position.y - lr.end.y))).length()
		if gap < bd:
			bd = gap
			best = lm[1]
			bc = Vector2(lr.position) + Vector2(lr.size) / 2.0
	if best == "":
		return "in the village"
	if bd <= 1.0:
		return "beside " + best
	var d := (Vector2(r.position) + Vector2(r.size) / 2.0) - bc
	var ns := "north" if d.y < 0 else "south"
	var ew := "west" if d.x < 0 else "east"
	var dir := ns if absf(d.y) > 2.0 * absf(d.x) else (ew if absf(d.x) > 2.0 * absf(d.y) else ns + "-" + ew)
	return "%s of %s" % [dir, best]


## [id, name, rect] of each landmark, in a fixed order.
## The family living in house `id` (or the player's, for the player's own house), "" for none: the
## name on the house's sign (Build 8 request).
func home_family(id: String) -> String:
	for hh in households:
		if str(hh.home) == id and not hh.get("ended", false):
			return str(hh.family)
	if buildings.has(id) and holder_of(buildings[id]) == PLAYER:
		return player.family
	return ""


func _landmarks() -> Array:
	var out := []
	var ids := buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = buildings[id]
		var name := str(Property.PLACES.get(str(b.get("type", "")), ""))
		if name == "" and str(b.get("type", "")) in ["house", "player_house"]:
			var fam := ""
			var old := false
			for hh in households:
				if str(hh.home) == str(id):
					fam = str(hh.family)
					old = hh.get("ended", false)
			if fam == "" and holder_of(b) == PLAYER:
				fam = player.family
			name = ("the %s family's %shouse" % [fam, "old " if old else ""]) if fam != "" else ""
		if name != "":
			out.append([id, name, Rect2i(int(b.x), int(b.y), int(b.w), int(b.h))])
	for id in stations:
		if str(stations[id].type) == "well":
			out.append([id, "the well", Rect2i(int(stations[id].at[0]), int(stations[id].at[1]), 1, 1)])
	var groups := [["market", "the market", stalls.values()], ["fields", "the fields", fields], ["pens", "the animal pens", fauna.pens.values() if fauna else []]]
	for g in groups:
		var items: Array = g[2]
		if items.is_empty():
			continue
		var gr := Rect2i(int(items[0].x), int(items[0].y), int(items[0].get("w", 1)), int(items[0].get("h", 1)))
		for e in items:
			gr = gr.merge(Rect2i(int(e.x), int(e.y), int(e.get("w", 1)), int(e.get("h", 1))))
		out.append([g[0], g[1], gr])
	var mine: Dictionary = map.data.get("mine", {})
	if mine.has("entrance"):
		out.append(["mine", "the mine", Rect2i(int(mine.entrance[0]), int(mine.entrance[1]), 1, 1)])
	return out


## The farmers who work a field (alive, by id): those whose workplace it is. Derived, so a farmer who
## changes work stops being one at once (audit defect 1).
func field_workers(f: Dictionary) -> Array:
	var out := []
	for n: NPC in npcs:
		if n.alive and n.job == "farmer" and n.workplace == str(f.id):
			out.append(n)
	return out


## DVW-A12 R16: whether opening chest unit `u` (a chest, crate, barrel or cart) is theft: it is not the player's own
## (Chests.info access "own") nor only for show ("decor").
func chest_is_theft(u: Dictionary) -> bool:
	return not str(chests.info(u).access) in ["own", "decor"]


## DVW-A12 R16: whether taking from container `c` (a table, a shelf, a stall left alone) is theft: always (owner rule,
## player_take: it is never the player's).
func container_is_theft(_c: Dictionary) -> bool:
	return true


## DVW-A12 R16: whether harvesting field `f` is theft: someone works it (field_owner).
func field_is_theft(f: Dictionary) -> bool:
	return field_owner(f) != null


## DVW-A12 R17: whose field `f` is for a harvest: the first farmer working it (field_workers), whose wheat the player
## takes in theft (player_harvest); null when nobody works it.
func field_owner(f: Dictionary) -> NPC:
	var workers := field_workers(f)
	return workers[0] if not workers.is_empty() else null


## The keeper of a pen (its tenant), alive, or null.
func pen_keeper(pen: Dictionary) -> NPC:
	return party(tenant_of(pen))


## Who may use a station. The village's own stations (the smithy's, the tavern's, the well) are the
## manor's and open to all. A workshop's are used by the workshop's owner or tenant (owner rule) and
## by those they give leave to: its `allow` list of references, "all" for anyone (agent proposal).
## A villager asks as their household (npc_may_use).
func may_use(ref: String, station: Dictionary) -> bool:
	var b: Dictionary = buildings.get(str(station.get("building", "")), {})
	if str(b.get("type", "")) == "workshop":
		var allow: Array = b.get("allow", [])
		return holds(ref, b) or allow.has(ref) or allow.has("all")
	return holder_of(station) == MANOR or holds(ref, station)


func npc_may_use(n: NPC, station: Dictionary) -> bool:
	return may_use(npc_ref(n.id), station) or (n.household >= 0 and may_use(hh_ref(n.household), station))


## A workshop's owner (or tenant) lets others use its stations, or stops them: `ref` a reference, or
## "all" for anyone.
func permit(b: Dictionary, ref: String, on: bool) -> void:
	var allow: Array = b.get("allow", [])
	if on and not allow.has(ref):
		allow.append(ref)
	elif not on:
		allow.erase(ref)
	b.allow = allow


## Villagers actually using a station now (PL2-001): alive, awake, not fighting, their current plan step
## is the work at that station and they stand at its use cell. Someone merely heading there, asleep,
## fighting, gone elsewhere or dead is not "using" it, and their reservation is cleared once they no
## longer have the station's work in their plan (a task switch).
func station_workers(id: String) -> Array:
	var st: Dictionary = stations[id]
	var out := []
	var users: Dictionary = st.users
	var at := Vector2(station_use(id)) + Vector2(0.5, 0.5)
	for u in users.keys():
		var o := npc(int(u))
		var held := o != null and o.alive and float(users[u]) >= minutes and o.plan.any(func(s): return str(s.get("args", {}).get("station", "")) == id)
		if not held:
			users.erase(u)
			continue
		var using: bool = o.target == -1 and not asleep(o) and not o.plan.is_empty() and o.plan[0].k == "work" \
				and str(o.plan[0].get("args", {}).get("station", "")) == id and o.pos.distance_to(at) <= 2.5 \
				and o.anim != "idle"           # one waiting beside it for the player (Build 13) is not using it
		if using:
			out.append(o)
	out.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
	return out


## Why the player cannot work at a station now, or "" if they can (audit defect 3, property phase 2):
## a workshop that is not theirs needs its holder's leave; at a station they do not hold, a villager's
## reservation is respected while they are at it or on their way (the player waits or uses another
## station; the owner of a workshop never waits in it).
func station_refusal(id: String) -> String:
	if Furniture.is_home_station(id):          # a home's oven or food table (PL2-013): its household's, nobody queues
		return Furniture.home_refusal(self, id)
	var st: Dictionary = stations[id]
	var b: Dictionary = buildings.get(str(st.get("building", "")), {})
	if not may_use(PLAYER, st):
		return "This %s is in %s; you need leave to use it." % [st.type, property.describe(b)]
	if holds(PLAYER, b if not b.is_empty() else st):
		return ""
	var busy := station_workers(id)
	if busy.size() >= int(st.get("capacity", 1)):
		var o: NPC = busy[0]
		return "%s %s is using the %s. Wait a little, or use another." % [o.name, o.family, st.type]
	return ""


## The player works at a station for `mins` game minutes: villagers count it as taken meanwhile.
func reserve_for_player(id: String, mins: float) -> void:
	if stations.has(id):
		stations[id].player_until = minutes + mins


## The player's work at a station ended or was cut short: the place is free at once (Build 13).
func release_player_station(id: String) -> void:
	if stations.has(id):
		stations[id].erase("player_until")


## Whether the player is working at station `id` now.
func player_at_station(id: String) -> bool:
	return stations.has(id) and float(stations[id].get("player_until", -1.0)) > minutes


## Owners at the start (agent proposal): a house and the sage's hut are their household's own; the
## manor house and the tavern are the manor's, let rent-free to the reeve's household and the tavern
## keepers' (they live there as its officers); the smithy, every other building and every station
## the manor's (a station belongs to its building's owner).
func _init_ownership() -> void:
	var ids := buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = buildings[id]
		if not b.has("owner"):
			set_owner(b, MANOR)
			set_tenant(b, "")
			for hh in households:
				if hh.home == id:
					if str(b.type) in ["house", "hut", "player_house"]:
						set_owner(b, hh_ref(int(hh.id)))
					else:
						set_tenant(b, hh_ref(int(hh.id)))
					break
	_station_owners()


## Stations come from the map on every load: each is its building's owner's (the manor's outdoors).
func _station_owners() -> void:
	for id in stations:
		var st: Dictionary = stations[id]
		st.owner = owner_of(buildings[st.building]) if st.has("building") and buildings.has(st.building) else MANOR
		st.tenant = ""


## Break the world <-> brain reference cycle so a finished world is freed.
func dispose() -> void:
	brain = null
	fauna = null
	construction = null


# ---------------------------------------------------------------- save / load ----------------
func to_dict() -> Dictionary:
	var hh := []
	for h in households:
		var c: Dictionary = h.duplicate(true)
		c.pantry = h.pantry.to_dict()
		hh.append(c)
	var lt := []
	for l in loot:
		lt.append({"pos": [l.pos.x, l.pos.y], "inv": l.inv.to_dict(), "coins": l.coins, "from": l.from, "t": l.get("t", minutes)})
		if level_of(l) != 0:
			lt[lt.size() - 1].level = level_of(l)            # MIN-A: written only below the surface
	var ns := []
	for n: NPC in npcs:
		ns.append(n.to_dict())
	return {
		"save_version": SAVE_VERSION, "format": "mml-save/%d" % SAVE_VERSION, "seed": seed, "minutes": minutes, "next_parcel": property.next_parcel,
		"construction": construction.to_dict(),
		"manor_work": manor_work.to_dict(),
		"treasury": treasury, "granary": granary.to_dict(), "last_reeve_day": last_reeve_day, "last_payday": last_payday,
		"village": {"format": map.data.format, "seed": map.data.seed},
		"overworld": map.overworld.to_dict() if map.overworld != null else {},
		"npcs": ns, "households": hh, "buildings": buildings, "stalls": stalls, "trees": trees, "plants": plants,
		"vacancies": vacancies, "manor_orders": manor_orders, "deposits": deposits, "boulders": boulders.map(func(b): return [int(b.x), int(b.y), int(b.amount)]), "fields": fields, "plots": plots, "loot": lt, "fauna": fauna.to_dict(), "farm": farm.to_dict(), "farm_plots": farm_plots.to_dict(),
		"player": player.to_dict(), "coin_sources": coin_sources, "caravan_purse": caravan_purse, "log": log_lines, "quest_offers": quests.to_dict(),
		"sage_id": sage_id, "reeve_id": reeve_id, "containers": _containers_to_dict(), "chests": chests.to_dict(), "carts": carts.to_dict(),
		"relations": relations.to_dict(), "contracts": contracts.to_dict(),
		"underground": {"gen": Underground.GEN_VERSION, "player_level": player_level},
	}


func load_dict(m: VillageMap, d: Dictionary) -> void:
	map = m
	seed = int(d.seed)
	rng.seed = seed + int(d.minutes)
	var ow: Dictionary = d.get("overworld", {})
	m.overworld = Overworld.create(int(ow.get("seed", seed)), m)
	m.overworld.load_dict(ow)
	brain = NPCBrain.new(self)
	chests = Chests.new(self)
	carts = Carts.new(self)
	carts.load_dict(d.get("carts", {}))           # saves before B14 have no carts
	relations = Relations.new(self)
	relations.load_dict(d.get("relations", {}))   # saves before CRT-01 have no ties: everyone starts as strangers
	contracts = Contracts.new(self)
	contracts.load_dict(d.get("contracts", {}))   # saves before CON-01 have no contracts: nothing open, nothing set aside
	property = Property.new(self)
	property.next_parcel = int(d.get("next_parcel", 0))
	construction = Construction.new(self)
	business = Business.new(self)
	fitting = Fitting.new(self)
	counters = Counters.new(self)
	minutes = float(d.minutes)
	last_hour = int(minutes / 60.0)
	for s in m.data.stations:
		var st: Dictionary = s.duplicate(true)
		st.users = {}                  # npc id -> game minute their reservation lapses (capacity: st.get("capacity", 1))
		stations[st.id] = st
	buildings = d.buildings
	_migrate_construction(d)
	var bids := buildings.keys()
	bids.sort()
	for id in bids:
		_workshop_stations(buildings[id])
	stalls = d.stalls
	Business.add_pitches(self, m)      # saves made before the pitches existed get them
	trees = d.trees
	# a tree's tiles are map data, not state: take them from the map (saves made before the
	# two-tile trees hold other tiles and no bottom)
	var kinds := {}
	for t in m.data.trees + m.decor_trees():
		kinds[Vector2i(int(t.x), int(t.y))] = t
	var have := {}
	for t in trees:
		have[Vector2i(int(t.x), int(t.y))] = true
	for c: Vector2i in kinds:                  # saves from before the map's edge woodland was made of trees
		if not have.has(c):
			trees.append(_new_tree(kinds[c]))
	for t in trees:
		var k: Dictionary = kinds.get(Vector2i(int(t.x), int(t.y)), {})
		if not k.is_empty():
			t.trunk = int(k.trunk)
			t.top = int(k.top)
			t.bottom = int(k.bottom)
		if not t.has("species"):
			t.species = _tree_species(t) if not k.is_empty() else "oak_summer"
		if not t.has("born"):
			t.born = -1.0e7 if t.state == "grown" else Trees.born_of(t)
	# a plant's place and tile are map data; its state is the save's (older saves: every plant ripe)
	_make_plants(m)
	var saved_plants := {}
	for pl in d.get("plants", []):
		saved_plants[str(pl.id)] = pl
	for pl in plants:
		var sp: Dictionary = saved_plants.get(str(pl.id), {})
		if not sp.is_empty():
			pl.state = str(sp.state)
			pl.regrow = float(sp.regrow)
	for sp in d.get("plants", []):     # SEED-02: plants grown from cuttings and seed are not map data: the save holds them
		if sp.get("planted", false):
			plants.append({"id": str(sp.id), "x": int(sp.x), "y": int(sp.y), "kind": str(sp.kind), "tile": int(sp.tile),
					"state": str(sp.state), "regrow": float(sp.regrow), "planted": true})
	vacancies = d.get("vacancies", [])
	manor_orders = d.get("manor_orders", [])
	deposits = d.deposits
	# a seam the map gained after the save was made (the gold seam, Build 13; the gallery's seams, Build 17) starts
	# full; seams are matched by (level, x, y) (MIN-A: a level seam may share (x, y) with one above it)
	underground = Underground.create(seed, m)
	var have_seam := {}
	for sd in deposits:
		have_seam[Vector3i(level_of(sd), int(sd.x), int(sd.y))] = true
	for md in m.data.deposits:
		if not have_seam.has(Vector3i(0, int(md.x), int(md.y))):
			deposits.append({"x": int(md.x), "y": int(md.y), "ore": md.ore, "amount": int(md.amount)})
	for us in underground.seam_records():
		if not have_seam.has(Vector3i(int(us.level), int(us.x), int(us.y))):
			deposits.append(us)
	_make_boulders(m)                  # a save from before boulders has none broken
	for sb in d.get("boulders", []):
		for b in boulders:
			if b.x == int(sb[0]) and b.y == int(sb[1]):
				b.amount = int(sb[2])
	fields = d.fields
	plots = d.plots
	coin_sources = int(d.coin_sources)
	# save_version 1-8 kept no caravan purse: an older world's caravan arrives with its float, as a new
	# one does (it is the caravan's own, not the village's: no village coin changes hands)
	caravan_purse = int(d.caravan_purse) if d.has("caravan_purse") else int(GameData.b("caravan_float"))
	log_lines = d.log
	sage_id = int(d.sage_id)
	reeve_id = int(d.reeve_id)
	for h in d.households:
		var c: Dictionary = h.duplicate(true)
		c.pantry = Inventory.from_dict(h.pantry)
		households.append(c)
	for l in d.loot:
		loot.append({"pos": Vector2(l.pos[0], l.pos[1]), "inv": Inventory.from_dict(l.inv), "coins": int(l.coins), "from": l.from, "t": float(l.get("t", minutes))})
		if int(l.get("level", 0)) != 0:
			loot[loot.size() - 1].level = int(l.level)          # MIN-A: left below the surface
	for nd in d.npcs:
		var n := NPC.from_dict(nd)
		npcs.append(n)
		by_id[n.id] = n
	player = PlayerState.from_dict(d.player)
	_load_underground(d.get("underground", {}))      # MIN-A: the level the player was on (absent: the surface)
	if int(d.get("save_version", 0)) < 15:
		Skills.seed_villagers(self)    # PAR-01: an older save's villagers had no skills
	_migrate_property(d)
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
	farm = Farming.new(self)
	if d.has("fauna"):
		fauna.load_dict(d.fauna)
		fauna.seed_new_species()              # B14: the forest animals join an older save's woods
	else:
		# save_version 1 (before animals): the deer count is dropped and the pens and woods are
		# stocked as in a new game. Nothing the player owned is lost.
		fauna.populate()
		_assign_keepers()
	farm.load_dict(d.get("farm", {}))          # PL2-015: older saves have no field and no pens of the player's
	farm_plots = FarmPlots.new(self)
	farm_plots.load_dict(d.get("farm_plots", {}))   # FARM-01..05: older saves have no farmland
	property.settle_ended_households()      # saves before property: a house whose family died out goes to the manor
	bandit_camp = Vector2i(int(m.data.spawns.bandit_camp[0]), int(m.data.spawns.bandit_camp[1]))
	_guard_posts()
	# the tables' dishes are saved; a save from before containers gets its tables set from the
	# keepers' stock (the crates, barrels and stalls are their owners' stock, so they need nothing)
	_load_containers(m, d.get("containers", []))
	chests.load_dict(d.get("chests", {}))
	if not d.has("containers"):
		serve_tables()
	brain.dawn(false)
	quests = Quests.new(self)
	quests.load_dict(d.get("quest_offers", {}))      # older saves: no offers yet; the next dawn makes them
	quests.start_story()                             # saves from before the storyline get its quests
	if int(d.get("save_version", 1)) < 7:
		quests.migrate_reserves()
	manor_work = ManorWork.new(self)
	manor_work.load_dict(d.get("manor_work", {}))    # older saves: nothing in lots, the yard or jobs
	if int(d.get("save_version", 1)) == 7:
		quests.drop_manor_quarry()                   # version 7's single manor job gives way to the job board
	_move_plots_to_map(m)
	# re-apply world changes to the collision map
	if map.overworld != null:
		map.overworld.clock = minutes
	for t in trees:
		if t.state in ["stump", "sapling", "young", "growing"]:
			Trees.sync(t, minutes)             # grown since the save was made (the clock is the save's: nothing yet)
		map.set_solid(Vector2i(int(t.x), int(t.y)), Trees.solid(str(t.state)))
	for id in buildings:
		var b: Dictionary = buildings[id]
		if is_built(b):
			_built_collision(b)
			fitting.restore(b)             # the equipment the player placed (PL1-10 stage 3)
	index_interiors()
	construction.load_dict(d.get("construction", {}))
	Life.sync_roles(self)              # B8-029: roles follow age on load
	if int(d.get("save_version", 1)) < 4:
		_move_indoors(d)
	_unstick()


## Anyone saved standing where the map now has furniture or a wall (a bed added to a home by a later
## map) steps to the nearest open cell in the same place, so nobody loads stuck.
func _unstick() -> void:
	for n: NPC in npcs:
		if not n.alive or not map.is_solid(n.cell()):
			continue
		var here := place_of(n.pos)
		var best := Vector2i(-1, -1)
		for r in range(1, 4):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var c := n.cell() + Vector2i(dx, dy)
					if best == Vector2i(-1, -1) and not map.is_solid(c) and place_of(Vector2(c) + Vector2(0.5, 0.5)) == here:
						best = c
			if best != Vector2i(-1, -1):
				break
		if best != Vector2i(-1, -1):
			n.pos = Vector2(best) + Vector2(0.5, 0.5)
			n.plan.clear()


## Saves before property phase 2 (save_version 1-5): every building site was a house's and kept no
## kind; a built house was drawn from the house stamp. They get the kind and stamp they had, so
## nothing changes: the same site, the same house, the same progress.
func _migrate_construction(d: Dictionary) -> void:
	if int(d.get("save_version", 1)) >= 6:
		return
	for p in d.get("plots", []):
		if p.get("site", {}) is Dictionary and not (p.site as Dictionary).is_empty() and not p.site.has("kind"):
			p.site.kind = "house"
	for id in buildings:
		var b: Dictionary = buildings[id]
		if str(b.get("type", "")) == "player_house" and not b.has("stamp"):
			b.kind = "house"
			b.stamp = "house"


## Saves before property (save_version 1-4) kept ownership six ways: a plot's owner "" or "player"
## and the player's plot list, a field's list of farmer ids, a stall's merchant id, a pen's keeper id
## (Fauna.load_dict), and none for buildings. Each becomes the one owner reference (World
## "ownership"): plots "" -> the manor's, "player" (or listed in player.plots) -> the player's; a
## field is the manor's (its farmers are those working it); a stall is the manor's, let to its
## merchant if they live; buildings get their starting owners, and a house the player built is the
## player's and stands on its plot. Nothing moves: plots, houses and the player stay where they are.
## Saves made with property (5) already hold all of it, and nothing here changes them.
func _migrate_property(d: Dictionary) -> void:
	var mine: Array = d.player.get("plots", [])
	for p in plots:
		if not p.has("tenant"):
			var was := str(p.get("owner", ""))
			set_owner(p, PLAYER if was == PLAYER or mine.has(p.id) else MANOR)
			set_tenant(p, "")
		if not p.has("building"):
			p.building = "house_" + str(p.id) if buildings.has("house_" + str(p.id)) else ""
		p.price = property.land_price(int(p.w), int(p.h))
	for f in fields:
		if not f.has("tenant"):
			f.owner = MANOR                 # was the list of its farmers' ids
			f.tenant = ""
	for id in stalls:
		var s: Dictionary = stalls[id]
		if not s.has("tenant"):
			var o := npc(int(s.get("owner", -1)))
			s.owner = MANOR
			s.tenant = npc_ref(o.id) if o and o.alive and o.job == "merchant" and o.workplace == id else ""
	for id in buildings:
		var b: Dictionary = buildings[id]
		if b.type == "player_house" and not b.has("owner"):
			b.owner = PLAYER                # only the player built houses before property
			b.tenant = ""
			var pid := str(id).trim_prefix("house_")
			if not plot(pid).is_empty():
				b.parcel = pid
				plot(pid).building = id
	_init_ownership()                       # the other buildings' owners (only those without one)


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


# ---------------------------------------------------------------- underground (MIN-A) --------
## The level a record (a deposit, loot) lies on: absent is the surface (docs/build17/MIN_A_ARCHITECTURE.md).
static func level_of(r: Dictionary) -> int:
	return int(r.get("level", 0))


## Rules that compare two positions also compare their levels: a level is one depth of the world.
static func same_level(a: int, b: int) -> bool:
	return a == b


## Whether the village's own workers can reach a seam: it lies on a level they can walk to (World.villager_levels;
## the surface only until the NPC level router exists). What they count as "the village's ore left" uses this.
func villagers_reach(d: Dictionary) -> bool:
	return villager_levels.has(level_of(d))


## Collision for the player: on the surface the surface's own (VillageMap.is_solid_world, unchanged), below it the
## level's map (rock everywhere off it).
func solid_for_player(c: Vector2i) -> bool:
	if player_level == 0 or underground == null:
		return map.is_solid_world(c)
	return underground.is_solid(player_level, c)


## A walking route for the player on the level they are on (the surface's VillageMap.find_path_world, unchanged).
func path_for_player(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	if player_level == 0 or underground == null:
		return map.find_path_world(from, to)
	return underground.find_path(player_level, from, to)


## The player steps in direction `dir`: standing on a portal's stand and heading for its door, they go through it and
## stand on the other end's stand, on its level. {} when there is no portal there; {refused: why} when they may not
## (a cart is not taken through: carts below are MIN-F's rails); else {level, pos, portal}.
func player_through(dir: Vector2) -> Dictionary:
	if underground == null or not player.alive:
		return {}
	var hit := underground.portal_from(player_level, Vector2i(floori(player.pos.x), floori(player.pos.y)), dir)
	if hit.is_empty():
		return {}
	if not carts.pulled_by(PLAYER).is_empty():
		return {"refused": "Set the cart down first: it will not go through the adit."}
	player.pos = Vector2(hit.to.stand) + Vector2(0.5, 0.5)
	_set_player_level(int(hit.to.level))
	return {"level": player_level, "pos": player.pos, "portal": str(hit.portal.id)}


func _set_player_level(level: int) -> void:
	if level == player_level:
		return
	player_level = level
	player_level_changed.emit(level)


## Loot set down by the player below the surface lies on their level (the surface's lists and the guards skip it).
func _loot_on_player_level(l: Dictionary) -> void:
	if player_level != 0:
		l.level = player_level


## The saved level of the player ("underground"; absent: the surface). A player saved on a level that is gone comes
## up at the first portal's surface stand; one saved on rock (a changed generator) stands on the nearest floor.
func _load_underground(u: Dictionary) -> void:
	player_level = int(u.get("player_level", 0))
	if player_level == 0 or underground == null:
		return
	var c := Vector2i(floori(player.pos.x), floori(player.pos.y))
	var lm := underground.map_at(player_level, c)
	if lm == null:
		player_level = 0
		if not underground.portals.is_empty():
			player.pos = Vector2(underground.portals[0].ends[0].stand) + Vector2(0.5, 0.5)
		return
	if lm.is_solid(c):
		player.pos = Vector2(lm.nearest_walkable(c)) + Vector2(0.5, 0.5)
