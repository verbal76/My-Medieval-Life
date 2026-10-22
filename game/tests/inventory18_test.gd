extends SceneTree
## INV-18 (Build 18; owner directive docs/directives/2026-10-22_build18_inventory_overhaul_inv18.md, decisions INV-Q1 and
## INV-Q2 in docs/directives/2026-10-22_build18_owner_decisions_inventory_tailor_armor.md; plan docs/build18/INV18_PLAN.md):
## every item has exactly one of eight categories; the player's pack holds 9, 18 or 27 kinds in each category by its
## upgrade level; worn gear takes no place; equip, unequip and swap are all or nothing; buying, transfers, gathering and
## crafting respect the category of the item; the refusals name it; saves of version 18 and before migrate with every
## item, count, wear and gear slot exactly once (a category over its capacity keeps everything); coins and goods are
## conserved. Run headless:
##   godot --headless --path game --script res://tests/inventory18_test.gd

const Census := preload("res://tests/census.gd")

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	_test_classification()
	_test_capacity()
	_test_equipment()
	_test_trade_and_transfer()
	_test_gain_and_messages()
	_test_save_and_migration()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


## `n` item ids of category `cat`, sorted, leaving out `skip`.
func _of(cat: String, n: int, skip := []) -> Array:
	var ids := GameData.items.keys().filter(func(id): return GameData.category(id) == cat and not skip.has(id))
	ids.sort()
	return ids.slice(0, n)


func _empty(p: PlayerState) -> void:
	for slot in PlayerState.GEAR:
		p.set(slot, "")
	p.inv.items.clear()
	p.inv.durability.clear()
	p.stolen.clear()


# ---------------------------------------------------------------- classification -------------
func _test_classification() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
	check(raw.categories.order == GameData.CATEGORIES and GameData.CATEGORIES.size() == 8, "eight categories, in tab order, the same in items.json and the code")
	var bad := []
	for id in raw.items:
		var c = raw.items[id].get("category")
		if not (c is String) or not c in GameData.CATEGORIES:
			bad.append(id)
	check(bad.is_empty() and raw.items.size() > 0, "every one of the %d registered items has exactly one valid category %s" % [raw.items.size(), bad])
	var each := {}
	for id in raw.items:
		each[raw.items[id].category] = int(each.get(raw.items[id].category, 0)) + 1
	check(GameData.CATEGORIES.all(func(c): return int(each.get(c, 0)) > 0), "every category holds some item %s" % each)
	# the owner's answers to INV-Q1 (2026-10-22)
	var want := {"copper_ring": "crafted", "gold_ring": "crafted", "amulet": "crafted", "wheat": "raw", "meat": "food",
		"wheat_seed": "raw", "oak_sapling": "raw", "red_berry_cutting": "raw", "herbal_tonic": "medicine",
		"lockpick": "tools", "padlock": "tools", "iron_sword": "weapons", "pickaxe": "tools", "iron_helmet": "armour",
		"bread": "food", "healing_tonic": "medicine", "log": "raw", "iron_bar": "crafted", "ore_sample": "general"}
	var wrong := want.keys().filter(func(id): return GameData.category(id) != want[id])
	check(wrong.is_empty(), "the owner's placements (INV-Q1) and the precedence rule hold %s" % [str(wrong)])


# ---------------------------------------------------------------- capacity -------------------
func _test_capacity() -> void:
	var w := _world()
	var p := w.player
	_empty(p)
	check(p.pack_level == 0 and p.pack_cap() == 9 and p.inv.max_stacks == 0 and p.inv.category_cap == 9, "a new pack: level 0, 9 places in each category, no overall kind limit")
	var raw := _of("raw", 19)
	for id in raw.slice(0, 9):
		p.inv.add(id, 3)
	check(p.inv.used("raw") == 9 and not p.inv.can_add(raw[9]) and not p.inv.add(raw[9]), "raw materials full at 9 of 9: a tenth kind is refused")
	check(p.inv.add(raw[0], 50) and p.inv.count(raw[0]) == 53, "more of a kind already carried still stacks (no stack limit)")
	var others := ["bread", "axe", "iron_sword", "leather_cap", "healing_tonic", "plank", "ore_sample"]
	check(others.all(func(id): return p.inv.add(id)), "every other category still takes a kind: categories are separate pools")
	check(p.inv.full_text(raw[9]) == "Raw materials inventory full: 9 of 9 slots.", "the refusal names the category: \"%s\"" % p.inv.full_text(raw[9]))
	p.pack_level = 1
	check(p.pack_cap() == 18 and p.inv.category_cap == 18 and p.inv.can_add(raw[9]), "the first upgrade opens the second row in every category (18)")
	for id in raw.slice(9, 18):
		p.inv.add(id)
	check(p.inv.used("raw") == 18 and not p.inv.can_add(raw[18]), "18 of 18 is full at level 1")
	check(p.inv.can_add("pottage") and p.inv.used("food") == 1, "the upgrade is global: food still has room")
	p.pack_level = 2
	check(p.pack_cap() == 27 and p.inv.can_add(raw[18]), "the second upgrade opens the third row (27)")
	p.pack_level = 7
	check(p.pack_level == 2, "the level cannot go past the second upgrade")
	p.pack_level = -3
	check(p.pack_level == 0, "nor below the start")
	# a 27-kind category at level 2 (made-up ids count as general: the rule, not the registry, is tested)
	_empty(p)
	p.pack_level = 2
	for i in 27:
		p.inv.add("test_thing_%d" % i)
	check(p.inv.used("general") == 27 and not p.inv.can_add("test_thing_27") and p.inv.can_add("bread"), "27 of 27 at level 2, and nothing past it")
	var total := 0
	for c in GameData.CATEGORIES:
		total += p.pack_cap()
	check(total == 216, "8 categories x 27 = 216 places when fully upgraded")
	# several goods at once (a harvest's crop and seed): both or neither
	_empty(p)
	p.pack_level = 0
	for id in _of("raw", 8, ["wheat", "wheat_seed"]):
		p.inv.add(id)
	check(p.inv.can_add("wheat") and p.inv.can_add("wheat_seed") and not p.inv.can_add_all({"wheat": 2, "wheat_seed": 1}),
		"one place left: each alone fits, the two together do not (can_add_all)")
	check(p.inv.full_text_all(["wheat", "wheat_seed"]) == "Raw materials inventory full: 8 of 9 slots, and this needs 2.", "and says so: \"%s\"" % p.inv.full_text_all(["wheat", "wheat_seed"]))
	w.dispose()


# ---------------------------------------------------------------- equipment ------------------
func _test_equipment() -> void:
	var w := _world()
	var p := w.player
	_empty(p)
	var coins0 := w.total_coins()
	# crafted goods (where rings and the amulet go) filled to 9 with the copper ring among them
	var crafted := _of("crafted", 8, ["copper_ring", "gold_ring", "amulet"])
	for id in crafted:
		p.inv.add(id, 2)
	p.inv.add("copper_ring")
	check(p.inv.used("crafted") == 9 and not p.inv.can_add("gold_ring"), "crafted goods full (9 of 9) with the copper ring in the pack")
	check(w.player_equip("copper_ring") and p.ring == "copper_ring" and p.inv.used("crafted") == 8 and p.inv.count("copper_ring") == 1,
		"wearing the ring moves it out of its place (8 of 9): one ring, worn")
	check(not p.inv.in_category("crafted").has("copper_ring"), "the worn ring is in its gear slot, not the grid")
	p.inv.add("gold_ring")
	check(p.inv.used("crafted") == 9, "the freed place takes another kind (the gold ring)")
	var why := w.unequip_refusal("ring")
	check(why == "Crafted goods inventory full: 9 of 9 slots." and p.ring == "copper_ring" and p.inv.count("copper_ring") == 1,
		"taking the ring off with no room is refused, named, and it stays worn: \"%s\"" % why)
	# a swap: the gold ring's place is freed as the copper ring takes one: allowed, nothing made or lost
	check(w.player_equip("gold_ring") and p.ring == "gold_ring" and p.inv.count("copper_ring") == 1 and p.inv.count("gold_ring") == 1
		and p.inv.used("crafted") == 9, "swapping rings in a full category works: each place handed over")
	# a swap that would need a new place: two gold rings (one stays in the pack) for the copper one worn
	w.player_equip("copper_ring")
	p.inv.add("gold_ring")
	check(p.inv.count("gold_ring") == 2 and p.inv.used("crafted") == 9, "two gold rings in the pack, the copper one worn, 9 of 9")
	why = w.equip_refusal("gold_ring")
	check(why != "" and p.ring == "copper_ring" and p.inv.count("gold_ring") == 2 and p.inv.count("copper_ring") == 1,
		"putting on a gold ring would send the copper one back to a full category: refused, nothing moved (\"%s\")" % why)
	# a second, unworn unit takes a place; with one, taking the worn one off needs no new place
	_empty(p)
	p.inv.add("iron_sword", 2)
	w.player_equip("iron_sword")
	check(p.inv.positions("iron_sword") == 1 and p.inv.used("weapons") == 1, "a second sword, unworn, takes a place")
	check(w.player_unequip("weapon") and p.weapon == "" and p.inv.count("iron_sword") == 2, "taking off a worn sword whose twin is in the pack needs no new place")
	# durability kept through equip and unequip
	_empty(p)
	p.inv.add("pickaxe")
	p.inv.durability["pickaxe"] = 37
	w.player_equip("pickaxe")
	w.player_unequip("tool")
	check(int(p.inv.durability.pickaxe) == 37 and p.inv.count("pickaxe") == 1, "the wear left is kept through equip and unequip")
	# conservation over the whole sequence: the store is one; equip and unequip never make or remove a unit
	_empty(p)
	var kit := {"iron_armor": 1, "leather_armor": 1, "leather_cap": 1, "axe": 1, "pickaxe": 1, "iron_sword": 1}
	for id in kit:
		p.inv.add(id, kit[id])
	var before := p.inv.items.duplicate()
	for id in kit:
		w.player_equip(id)
	w.player_equip("leather_armor")
	for slot in PlayerState.GEAR:
		w.player_unequip(slot)
	check(p.inv.items == before, "equip, swap and unequip leave every count as it was")
	# the appearance hook still sees what is worn (CC-01)
	w.player_equip("iron_armor")
	check(CharacterLook.player_sheet(p) != null and p.worn_counts().has("iron_armor"), "the look is still drawn with the armour worn")
	check(w.total_coins() == coins0, "no coin moved")
	w.dispose()


# ---------------------------------------------------------------- trade, transfer ------------
func _test_trade_and_transfer() -> void:
	var w := _world()
	var p := w.player
	var vendor: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job == "smith":
			vendor = n
			break
	# the axe the owner could not buy: tools full, food not
	for id in _of("tools", 9, ["axe"]):
		if not p.inv.has(id):
			p.inv.add(id)
	p.coins = 200
	vendor.inv.add("axe", 1)
	vendor.inv.add("bread", 1)
	var goods0 := Census.goods(w)
	var coins0 := w.total_coins()
	var pc := p.coins
	var vc := vendor.coins
	var axes := vendor.inv.count("axe")
	var bread := p.inv.count("bread")
	check(p.inv.used("tools") >= 9 and not w.trade(p, vendor, "axe", 1, 10), "a new tool cannot be bought with tools full")
	check(p.coins == pc and vendor.coins == vc and vendor.inv.count("axe") == axes and not p.inv.has("axe"), "nothing is paid and nothing moves")
	var r := w.player_buy_many(vendor, "axe", 1)
	check(r.result == "failed" and str(r.text).begins_with("Tools inventory full: "), "buying many says which category is full: \"%s\"" % r.text)
	check(w.trade(p, vendor, "bread", 1, 2) and p.inv.count("bread") == bread + 1 and p.coins == pc - 2, "food can still be bought")
	check(w.trade(vendor, p, "bread", 1, 2) and p.coins == pc and p.inv.count("bread") == bread, "and sold back")
	check(Census.goods(w) == goods0 and w.total_coins() == coins0, "goods and coins conserved through the refused and the done trades")
	# the family chest: a transfer into a full category is refused, from it to a category with room works
	p.chest.add("axe", 1)
	check(not w.transfer(p.chest, p.inv, "axe", 1) and p.chest.count("axe") == 1 and not p.inv.has("axe"), "taking a new tool from the chest is refused with tools full")
	p.chest.add("apple", 2)
	check(w.transfer(p.chest, p.inv, "apple", 2) and p.inv.count("apple") == 2, "food comes out of the chest")
	check(Census.goods(w) == goods0.merged({"axe": int(goods0.get("axe", 0)) + 1, "apple": int(goods0.get("apple", 0)) + 2}, true), "goods conserved through the chest (only what was put in by hand added)")
	w.dispose()


# ---------------------------------------------------------------- gain, messages -------------
func _test_gain_and_messages() -> void:
	var w := _world()
	var p := w.player
	_empty(p)
	for id in _of("crafted", 9, ["plank"]):
		p.inv.add(id)
	var loot0 := w.loot.size()
	var got := w.player_gain("plank", 3)
	check(got == 0 and w.loot.size() == loot0 + 1 and w.loot[-1].inv.count("plank") == 3 and not p.inv.has("plank"),
		"made goods with no place are set down at the player's feet, none lost")
	check(w.pack_full_text(["plank"]) == "Crafted goods inventory full: 9 of 9 slots.", "and the message names the category")
	var r := w.player_loot(w.loot.size() - 1)
	check(int(r.left) == 3 and str(r.why).begins_with("Crafted goods inventory full"), "picking them up again says why they stay")
	check(w.pack_full_text(["bread"]) == "Your pack is full." and p.inv.can_add("bread"), "a category with room is never called full")
	# the trade window names the full category (TRADE-AXE-01 adapted)
	var src := FileAccess.get_file_as_string("res://scripts/ui/game_ui.gd")
	check(not src.contains("kinds. You can buy more") and src.contains("inventory full: %d of %d slots. You can buy more"), "the trade window's full-pack notice is per category")
	w.dispose()


# ---------------------------------------------------------------- saves ----------------------
## A save as version 18 wrote it: the shared pack of 24 kinds, no pack_level.
func _v18(w: World, items: Dictionary, wear: Dictionary, gear: Dictionary) -> Dictionary:
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	d.save_version = 18
	d.format = "mml-save/18"
	d.player.erase("pack_level")
	d.player.inv = {"items": items.duplicate(), "durability": wear.duplicate(), "max_stacks": 24}
	for slot in PlayerState.GEAR:
		d.player[slot] = str(gear.get(slot, ""))
	d.player.stolen = {}
	return d


func _test_save_and_migration() -> void:
	var map := VillageMap.load_default()
	var w := _world()
	var p := w.player
	_empty(p)
	p.pack_level = 1
	p.inv.add("iron_sword")
	p.inv.add("log", 30)
	p.inv.durability["iron_sword"] = 55
	w.player_equip("iron_sword")
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(int(d.save_version) == World.SAVE_VERSION and World.SAVE_VERSION >= 19 and int(d.player.pack_level) == 1, "the save is version 19 or later and holds the pack level")
	var w2 := World.new()
	w2.load_dict(map, d)
	check(w2.player.pack_level == 1 and w2.player.inv.category_cap == 18 and w2.player.inv.items == p.inv.items
		and w2.player.inv.durability == p.inv.durability and w2.player.weapon == "iron_sword" and w2.player.inv.positions("iron_sword") == 0,
		"load: level, items, wear and the worn sword come back; the sword takes no place")
	w2.dispose()

	var raw := _of("raw", 20)
	var full24 := {}
	for c in GameData.CATEGORIES:
		for id in _of(c, 3):
			full24[id] = 1 + full24.size()
	for id in _of("raw", 5):                     # general holds one item: two more raw materials make 24
		if full24.size() < 24:
			full24[id] = 1 + full24.size()
	var over := {}
	for id in raw:
		over[id] = 2
	for id in ["bread", "axe", "iron_sword", "plank"]:
		over[id] = 1
	var cases := {
		"empty": [{}, {}, {}],
		"partial": [{"log": 6, "bread": 2, "pickaxe": 1}, {"pickaxe": 120}, {"tool": "pickaxe"}],
		"full 24": [full24, {}, {}],
		"20 raw materials": [over, {"axe": 9}, {"tool": "axe", "weapon": "iron_sword"}],
		"all six slots worn": [{"iron_sword": 1, "axe": 1, "iron_armor": 1, "iron_helmet": 1, "amulet": 1, "gold_ring": 1, "plank": 4},
			{"iron_sword": 10, "axe": 3, "iron_armor": 200, "iron_helmet": 90},
			{"weapon": "iron_sword", "tool": "axe", "armor": "iron_armor", "head": "iron_helmet", "amulet": "amulet", "ring": "gold_ring"}],
		"stacks": [{"log": 500, "stone": 999, "wheat": 77, "bread": 40}, {}, {}],
	}
	check(full24.size() == 24, "(the full fixture holds 24 kinds across all eight categories)")
	for name in cases:
		var c: Array = cases[name]
		var old := _v18(w, c[0], c[1], c[2])
		check(SaveStore.inspect_text(JSON.stringify(old), World.SAVE_VERSION).state == "ok", "%s: a version 18 save is read" % name)
		var w3 := World.new()
		w3.load_dict(map, JSON.parse_string(JSON.stringify(old)))
		var q := w3.player
		var same: bool = q.inv.items.size() == c[0].size() and c[0].keys().all(func(id): return q.inv.count(id) == int(c[0][id]))
		var wear: bool = c[1].keys().all(func(id): return int(q.inv.durability.get(id, -1)) == int(c[1][id]))
		var gear: bool = PlayerState.GEAR.all(func(s): return str(q.get(s)) == str(c[2].get(s, "")))
		check(same and wear and gear and q.pack_level == 0 and q.inv.category_cap == 9 and q.inv.max_stacks == 0,
			"%s: every item, count, wear and gear slot exactly once; pack level 0" % name)
		var again: Dictionary = JSON.parse_string(JSON.stringify(w3.to_dict()))
		var w4 := World.new()
		w4.load_dict(map, again)
		check(w4.player.inv.items == q.inv.items and int(again.save_version) == World.SAVE_VERSION, "%s: saved again as the current version, the same" % name)
		w4.dispose()
		var m := SaveTransfer.migrate(old, map)
		check(m.ok and (m.data.player.inv.items as Dictionary).size() == c[0].size(), "%s: an imported save migrates the same way (%s)" % [name, m.get("reason", "")])
		if name == "20 raw materials":
			check(q.inv.used("raw") == 20 and not q.inv.can_add("wool") and q.inv.can_add(raw[0]),
				"over capacity (20 / 9): all kept, more of a carried kind stacks, no new kind")
			check(q.inv.can_add("pottage") and q.inv.full_text("wool").begins_with("Raw materials inventory full: 20 of 9"), "other categories unaffected; the message says 20 of 9")
		if name == "all six slots worn":
			check(GameData.CATEGORIES.all(func(cat): return q.inv.used(cat) == (1 if cat == "crafted" else 0)), "the six worn items take no place (only the planks do)")
		w3.dispose()
	w.dispose()
