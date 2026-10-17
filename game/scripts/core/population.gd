class_name Population
extends RefCounted
## Creates the starting population: households in every home, 100 villagers with jobs, tools,
## stock and coins, plus the bandit band. Deterministic for a world seed.
## Counts are GAME EXPANSION choices recorded in docs/BUILD_DECISIONS.md.

const JOBS := {
	"miner": 8, "laborer": 3, "woodcutter": 6, "carpenter": 2, "smith": 2, "tanner": 2,
	"farmer": 10, "cook": 3, "tavernkeeper": 2, "hunter": 4, "merchant": 6, "guard": 6,
	"reeve": 1, "sage": 1,
}
const CHILDREN := 26
const ELDERS := 18

const FIRST := ["Adam", "Agnes", "Alan", "Alice", "Amice", "Avice", "Bartholomew", "Beatrice", "Cecily",
	"Christian", "Clement", "Denise", "Edith", "Edmund", "Elias", "Ellen", "Emma", "Geoffrey", "Gilbert",
	"Godfrey", "Hawise", "Henry", "Hugh", "Isabel", "Ivo", "Joan", "John", "Juliana", "Katherine",
	"Lettice", "Mabel", "Margery", "Martin", "Matilda", "Nicholas", "Osbert", "Petronilla", "Philip",
	"Ralph", "Reginald", "Richard", "Robert", "Roger", "Rose", "Sabina", "Simon", "Stephen", "Sybil",
	"Thomas", "Walter", "Wat", "William"]
const FAMILY := ["Ashby", "Barley", "Brook", "Cooper", "Dale", "Fairweather", "Fletcher", "Ford",
	"Greenhill", "Hayward", "Holt", "Lambert", "Marsh", "Mercer", "Oakley", "Reed", "Shepherd", "Stone",
	"Thatcher", "Underwood", "Ward", "Webb", "Wright"]
const BANDITS := ["Black Hob", "Gib Crookback", "Ned of the Holt", "Sly Tom", "Red Ankarette", "Jack Wolfshead"]


static func populate(w: World) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = w.seed * 7919 + 13
	var homes := []
	for id in w.buildings:
		if w.buildings[id].type == "house":
			homes.append(id)
	homes.sort()
	var tavern := _first(w, "tavern")
	var manor := _first(w, "manor")
	var hut := _first(w, "hut")

	# households
	var fam := FAMILY.duplicate()
	_shuffle(fam, rng)
	var all_homes := [tavern, manor, hut] + homes
	for i in all_homes.size():
		w.households.append({"id": i, "family": fam[i % fam.size()], "home": all_homes[i], "members": [], "pantry": Inventory.new()})
	w.households[2].family = "Lorekeeper"

	# job list in a fixed order, then spread over homes
	var jobs := []
	for j in JOBS:
		for k in JOBS[j]:
			jobs.append(j)
	var placed := {}            # household index -> list of jobs
	var fixed := {0: ["tavernkeeper", "tavernkeeper", "cook", "cook", "cook"], 1: ["reeve", "guard", "guard"], 2: ["sage"]}
	for h in fixed:
		placed[h] = fixed[h].duplicate()
		for j in fixed[h]:
			jobs.erase(j)
	_shuffle(jobs, rng)
	var hi := 3
	for j in jobs:
		placed[hi] = placed.get(hi, []) + [j]
		hi = 3 + (hi - 2) % (all_homes.size() - 3)
	var kids := CHILDREN
	var elders := ELDERS
	var extra := {0: ["child"], 1: ["elder", "child"]}
	for h in extra:
		for r in extra[h]:
			placed[h].append(r)
		kids -= extra[h].count("child")
		elders -= extra[h].count("elder")
	hi = 3
	for k in kids:
		placed[hi].append("child")
		hi = 3 + (hi - 2) % (all_homes.size() - 3)
	for k in elders:
		placed[hi].append("elder")
		hi = 3 + (hi - 2) % (all_homes.size() - 3)

	var next_id := 1
	var counters := {}
	var fields := w.fields
	var stall_ids := w.stalls.keys()
	stall_ids.sort()
	var vsheet := 0
	var gsheet := 0
	for h in range(all_homes.size()):
		var hh: Dictionary = w.households[h]
		var door := w.building_door(hh.home)
		for what in placed.get(h, []):
			var n := NPC.new()
			n.id = next_id
			next_id += 1
			n.household = h
			n.family = hh.family
			n.home = hh.home
			n.name = FIRST[rng.randi() % FIRST.size()]
			n.pos = Vector2(door) + Vector2(0.5, 0.5)
			n.coins = rng.randi_range(int(GameData.b("start_coins_villager")[0]), int(GameData.b("start_coins_villager")[1]))
			if what == "child":
				n.role = "child"
				n.coins = 0
				n.hp = 15.0
				n.max_hp = 15.0
			elif what == "elder":
				n.role = "elder"
				n.coins = 10
				n.hp = 20.0
				n.max_hp = 20.0
			else:
				n.job = what
				var c := int(counters.get(what, 0))
				counters[what] = c + 1
				_equip(w, n, what, c, fields, stall_ids)
			if n.job == "guard":
				n.sprite = "res://assets/characters/guard_%02d.png" % (gsheet % 6)
				gsheet += 1
			else:
				n.sprite = "res://assets/characters/villager_%02d.png" % (vsheet % 48)
				vsheet += 1
			n.hunger = rng.randf_range(60.0, 100.0)
			hh.members.append(n.id)
			w.npcs.append(n)
		hh.pantry.add("pottage", 3)

	for i in int(GameData.b("bandits")):
		var b := NPC.new()
		b.id = next_id
		next_id += 1
		b.role = "bandit"
		b.name = BANDITS[i % BANDITS.size()]
		b.sprite = "res://assets/characters/bandit_%02d.png" % (i % 6)
		b.pos = Vector2(w.bandit_camp) + Vector2(rng.randf_range(-3, 3), rng.randf_range(-2, 2)) + Vector2(0.5, 0.5)
		b.hp = 25.0
		b.max_hp = 25.0
		b.damage = 4.0
		b.coins = rng.randi_range(5, 15)
		b.inv.add("copper_sword")
		b.hunger = 100.0
		w.npcs.append(b)


static func _equip(w: World, n: NPC, job: String, idx: int, fields: Array, stall_ids: Array) -> void:
	var inv := n.inv
	match job:
		"miner", "laborer":
			inv.add("pickaxe")
			n.workplace = "mine"
		"woodcutter":
			inv.add("axe")
			n.workplace = "forest"
		"hunter":
			inv.add("meat")
			n.workplace = "forest"
			n.damage = 5.0
		"carpenter":
			inv.add("log", 6)
			inv.add("plank", 6)
			n.coins = 60
			n.workplace = w.stations_of("sawhorse")[0]
		"smith":
			_give(inv, {"hammer": 1, "iron_bar": 4, "coal": 4, "iron_ore": 4, "plank": 2, "pickaxe": 1, "axe": 1, "iron_sword": 1, "leather": 1})
			n.coins = 120
			n.workplace = w.stations_of("forge")[0]
		"tanner":
			inv.add("hide", 2)
			inv.add("leather", 2)
			n.coins = 60
			n.workplace = w.stations_of("workbench")[0]
		"farmer":
			inv.add("wheat", 4)
			var f: Dictionary = fields[idx % fields.size()]
			f.owner.append(n.id)
			n.workplace = f.id
		"cook":
			inv.add("wheat", 10)
			inv.add("meat", 3)
			inv.add("log", 4)
			n.coins = 60
			n.workplace = w.stations_of("stove")[0]
		"tavernkeeper":
			inv.add("pottage", 12)
			inv.add("roast_meat", 4)
			inv.add("ale", 8)
			n.coins = 120
			n.workplace = w.stations_of("tavern_counter")[0]
		"merchant":
			var sid: String = stall_ids[idx % stall_ids.size()]
			var stall: Dictionary = w.stalls[sid]
			stall.owner = n.id
			n.workplace = sid
			n.coins = int(GameData.b("start_coins_trader"))
			match stall.kind:
				"raw":
					_give(inv, {"iron_ore": 4, "coal": 4, "stone": 12, "log": 6, "plank": 6})
				"food":
					_give(inv, {"pottage": 6, "wheat": 6, "ale": 4})
				"goods":
					_give(inv, {"pickaxe": 1, "axe": 1, "leather": 2, "copper_sword": 1})
		"guard":
			inv.add("iron_sword")
			inv.add("leather_armor")
			n.hp = 45.0
			n.max_hp = 45.0
			n.damage = 8.0
			n.armor = 3.0
			n.workplace = "day" if idx % 2 == 0 else "night"
		"reeve":
			n.coins = 300
			n.workplace = "manor"
			w.reeve_id = n.id
		"sage":
			n.coins = 30
			n.workplace = "hut"
			w.sage_id = n.id
			n.name = "Old Lorekeeper"


static func _give(inv: Inventory, items: Dictionary) -> void:
	for id in items:
		inv.add(id, int(items[id]))


static func _first(w: World, kind: String) -> String:
	var ids := w.buildings.keys()
	ids.sort()
	for id in ids:
		if w.buildings[id].type == kind:
			return id
	return ""


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
