extends SceneTree
## B25 Decisions 5, 6 and 7 (owner 2026-11-01, docs/directives/2026-11-01_nine_owner_decisions_consolidated.md): the new
## materials (tin, bronze, steel, silk, fur; tusks and antlers from Build 22) each come by a real pathway and are used;
## nothing is made from nothing (inputs leave as outputs arrive, coins move between purses); armour bonuses are physical,
## regional or elemental, and a bonus whose mechanic is not in the game is never applied; ordinary clothing is cosmetic;
## an older save's settlements gain the new outputs without anything else changing. Run headless:
##   godot --headless --path game --script res://tests/materials_b25_test.gd

var failures := 0
var checks := 0

const NEW := ["tin_ore", "tin_bar", "bronze_bar", "steel_bar", "silk", "fur"]


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	_test_data()
	_test_metallurgy()
	_test_tin_sources()
	_test_fur_and_silk()
	_test_bonus_kinds()
	_test_sword_bonus()
	_test_latent()
	_test_clothing()
	_test_save()
	_test_wiki()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_value := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_value)
	return w


func _job(w: World, job: String) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.job == job and n.role == "adult":
			return n
	return null


func _units(inv: Inventory, ids: Array) -> Dictionary:
	var d := {}
	for id in ids:
		d[id] = inv.count(id)
	return d


## The villagers' units of `item`, or ("") their coins.
func _village(w: World, item: String) -> int:
	var t := 0
	for n: NPC in w.npcs:
		t += n.inv.count(item) if item != "" else n.coins
	return t


## The traders' stock of `item` on the road, or ("") the coins in their tills.
func _traders(road: Array, item: String) -> int:
	var t := 0
	for s: OffMapSettlement in road:
		t += s.trader_has(item) if item != "" else (0 if s.trader().is_empty() else int(s.trader().till))
	return t


# ---------------------------------------------------------------- data -------------------------
func _test_data() -> void:
	for id in NEW:
		var made := false
		var used := false
		for r in GameData.recipes:
			var rec: Dictionary = GameData.recipes[r]
			made = made or (rec.out as Dictionary).has(id)
			used = used or (rec["in"] as Dictionary).has(id)
		var src := ResourceNodes.sources_of(id)
		check(ResourceLoader.exists("res://assets/icons/%s.png" % id), "%s has an icon" % id)
		check(made or not src.is_empty(), "%s has a source: %s" % [id, str(src.map(func(s): return s.get("kind", s) if s is Dictionary else s)).left(120)])
		check(used, "%s is used by a recipe" % id)
	for id in ["boar_tusk", "antler"]:
		var uses := 0
		for r in GameData.recipes:
			if (GameData.recipes[r]["in"] as Dictionary).has(id):
				uses += 1
		check(uses >= 3, "%s is used by %d recipes" % [id, uses])
	var steel := 0
	var bronze := 0
	for r in GameData.recipes:
		var rin: Dictionary = GameData.recipes[r]["in"]
		steel += 1 if rin.has("steel_bar") else 0
		bronze += 1 if rin.has("bronze_bar") else 0
	check(steel > 100 and bronze > 100, "steel and bronze bars go into the armour and every steel and bronze weapon (%d, %d recipes)" % [steel, bronze])
	check(not GameData.recipes.forge_bronze_armor["in"].has("copper_bar") and GameData.recipes.forge_bronze_armor["in"].has("bronze_bar"), "bronze armour is made of bronze, not copper standing in")
	check(GameData.recipes.forge_steel_armor["in"].has("steel_bar"), "steel armour is made of steel bars")


# ---------------------------------------------------------------- metallurgy -------------------
## The player's own work at the forge: inputs leave the pack as the product arrives (World.work_craft).
func _craft(w: World, r: String, give: Dictionary) -> void:
	var p := w.player
	p.skills["smithing"] = Skills.xp_for_level(5)
	p.skills["tanning"] = Skills.xp_for_level(5)
	p.skills["crafting"] = Skills.xp_for_level(5)
	for k in give:
		p.inv.add(k, int(give[k]))
	var rec: Dictionary = GameData.recipes[r]
	var ids: Array = (rec["in"] as Dictionary).keys() + (rec.out as Dictionary).keys()
	var before := _units(p.inv, ids)
	var res := w.player_craft(r)
	var after := _units(p.inv, ids)
	var ok := str(res.get("result", "")) == "ok"
	for k in rec.out:
		ok = ok and int(after[k]) == int(before[k]) + int(rec.out[k])
	for k in rec["in"]:
		var used := int(before[k]) - int(after[k])
		ok = ok and (used == int(rec["in"][k]) or used == 0)      # a practised hand may save the inputs (PAR-01)
	check(ok, "%s: %s in, %s out (%s)" % [r, str(rec["in"]), str(rec.out), str(res)])


func _test_metallurgy() -> void:
	var w := _world()
	_craft(w, "smelt_tin", {"tin_ore": 2, "coal": 1})
	_craft(w, "alloy_bronze", {"copper_bar": 3, "coal": 1})
	_craft(w, "make_steel", {"iron_bar": 1, "coal": 1})
	check(GameData.recipes.alloy_bronze["in"].has("tin_bar") and GameData.recipes.alloy_bronze["in"].has("copper_bar"), "bronze needs copper and tin")
	check(GameData.recipes.make_steel["in"].has("iron_bar") and GameData.recipes.make_steel["in"].has("coal") and int(GameData.recipes.make_steel.level) >= 3, "steel is iron worked with coal, a skilled smith's work")
	# the village smith smelts tin it holds and keeps a couple of bronze and steel bars for orders
	var smith := _job(w, "smith")
	smith.skills["smithing"] = Skills.xp_for_level(5)
	smith.inv.items.clear()
	smith.inv.add("tin_ore", 2)
	smith.inv.add("coal", 1)
	w.minutes = floorf(w.minutes / 1440.0) * 1440.0 + 10.0 * 60.0
	smith.pos = Vector2(w.brain._workplace_cell(smith)) + Vector2(0.5, 0.5)
	w.brain._smith(smith)
	check(str(smith.doing) == "smelt tin", "the smith smelts tin ore it holds (%s)" % smith.doing)
	smith.inv.items.clear()
	smith.inv.add("copper_bar", 3)
	smith.inv.add("tin_bar", 1)
	smith.inv.add("coal", 1)
	smith.plan = []
	w.brain._smith(smith)
	check(str(smith.doing).contains("bronze") or str(smith.doing).contains("forge"), "and alloys bronze from copper and tin (%s)" % smith.doing)


# ---------------------------------------------------------------- tin --------------------------
func _test_tin_sources() -> void:
	var w := _world()
	# below ground: one hidden vein on each level, placed last
	var levels := {}
	for h in w.underground.hidden:
		if str(h.ore) == "tin_ore":
			levels[int(h.level)] = int(h.amount)
	check(levels.size() >= 2 and levels.values().all(func(a): return a == 24), "a hidden tin vein of 24 lies on each level below ground (%s)" % str(levels))
	var near := true
	for d in w.deposits:
		if str(d.ore) == "tin_ore":
			near = false
	check(near, "no tin is known at the start: it is found, not given")
	# a tunnel opening beside it exposes an ordinary seam, which mining empties
	var h: Dictionary = {}
	for x in w.underground.hidden:
		if str(x.ore) == "tin_ore":
			h = x
			break
	var opened: Array = w.mine_works.expose_beside(int(h.level), Vector2i(int(h.x), int(h.y)), "test")
	var seam: Dictionary = {}
	for d in w.deposits:
		if str(d.ore) == "tin_ore":
			seam = d
	check(opened.size() == 1 and not seam.is_empty() and int(seam.amount) == 24, "a cut beside it exposes it as a seam of 24")
	var got := w.mine_unit(seam)
	check(got == "tin_ore" and int(seam.amount) == 23, "mining it gives tin ore one unit at a time, never refilled")
	# Garton's diggings: a finite reserve worked by its miners
	var garton: OffMapSettlement = w.regions.by_id.get("garton")
	var q: Dictionary = garton.biz.get("quarry", {})
	check(not q.is_empty() and (q.out as Dictionary).has("tin_ore") and int(q.reserves.get("tin_ore", 0)) == 200, "Garton's diggings hold a finite tin reserve of 200")
	var res0 := int(q.reserves.tin_ore)
	var stock0 := int(q.stock.get("tin_ore", 0))
	for d in 10:
		garton.step_day(maxi(w.regions.day, 0) + 1 + d)
	var dug := res0 - int(q.reserves.tin_ore)
	check(dug >= 0 and int(garton.flows.produced.get("tin_ore", 0)) == dug, "what the diggings bring up comes off the reserve (%d dug)" % dug)
	# the caravan: while the village knows no tin seam (above, the one found holds 23: no import), the smiths buy tin
	# from a trader's real stock, the coins going to that trader
	var smith0 := _job(w, "smith")
	smith0.inv.items.clear()
	smith0.coins = 500
	w.brain._caravan_imports(w.regions.list)
	check(smith0.inv.count("tin_ore") == 0, "with a found tin seam of its own the village imports none")
	w = _world()
	var smith := _job(w, "smith")
	smith.inv.items.clear()
	smith.coins = 500
	var road: Array = w.regions.list
	var seller: OffMapSettlement = w.regions.seller_for("tin_ore", road)
	check(seller != null, "a trader on the road carries tin")
	var had := _traders(road, "tin_ore")
	var v0 := _village(w, "tin_ore")
	var c0 := _village(w, "") + _traders(road, "")
	w.brain._caravan_imports(road)
	var bought := smith.inv.count("tin_ore")
	check(bought > 0 and bought <= int(GameData.b("caravan_import_stock").tin_ore), "the smith buys tin from the caravan (%d)" % bought)
	check(_traders(road, "tin_ore") == had - (_village(w, "tin_ore") - v0), "it leaves the traders' stock (none made for the sale)")
	check(_village(w, "") + _traders(road, "") == c0, "and the coins go into the traders' tills")


# ---------------------------------------------------------------- fur and silk -----------------
func _test_fur_and_silk() -> void:
	var w := _world()
	_craft(w, "dress_fur_hide", {"hide": 1})
	_craft(w, "dress_fur", {"rabbit_pelt": 3})
	_craft(w, "weave_fine_cloth", {"silk": 2})
	# the tanner dresses fur for a buyer
	var tanner := _job(w, "tanner")
	tanner.skills["tanning"] = Skills.xp_for_level(5)
	tanner.skills["crafting"] = Skills.xp_for_level(5)
	check(w.brain._buyer_for(tanner, "fur") != null, "the goods merchant buys fur")
	check(w.brain._buyer_for(tanner, "fine_cloth") != null, "and fine cloth")
	# raw silk: from the weavers of the towns (abstract production) and Higham's trader, never from nothing
	var weavers := 0
	for s: OffMapSettlement in w.regions.list:
		if s.biz.has("weaver") and float((s.biz.weaver.out as Dictionary).get("silk", 0.0)) > 0.0:
			weavers += 1
	check(weavers >= 1, "the towns' weavers produce raw silk (%d)" % weavers)
	var higham: OffMapSettlement = w.regions.by_id.get("higham")
	check(higham.trader_has("silk") > 0, "Higham-on-the-Way's trader holds raw silk")
	# the tanner buys silk from the caravan only while it can weave it and someone wants fine cloth
	tanner.inv.items.clear()
	tanner.coins = 400
	var road: Array = w.regions.list
	var had := _traders(road, "silk")
	var v0 := _village(w, "silk")
	var c0 := _village(w, "") + _traders(road, "")
	w.brain._caravan_imports(road)
	var got := tanner.inv.count("silk")
	check(got > 0 and got <= 4, "the tanner buys raw silk from the caravan (%d)" % got)
	check(_traders(road, "silk") == had - (_village(w, "silk") - v0) and _village(w, "") + _traders(road, "") == c0, "from the traders' stock, the coins to their tills")
	var t2 := _job(_world(), "tanner")
	t2.skills["crafting"] = 0
	check(not w.brain._can_make(t2, "weave_fine_cloth"), "a tanner who cannot weave silk buys none (Crafting 3)")


# ---------------------------------------------------------------- Decision 6 -------------------
func _test_bonus_kinds() -> void:
	var bad := []
	var kinds := {}
	for id in GameData.items:
		var it: Dictionary = GameData.items[id]
		if not it.has("class") or it.has("gear"):
			continue
		var k := str(it.get("bonus_kind", ""))
		if it.get("clothing", false):
			if k != "":
				bad.append(id + " clothing with a bonus kind")
			continue
		if str(it.type) in ["armor", "head"] and not k in ["physical", "regional", "rare", "elemental"]:
			bad.append(id + " has no bonus kind")
		kinds[k] = int(kinds.get(k, 0)) + 1
		if k == "physical" and it.has("bonus"):
			bad.append(id + " physical with a bonus")
		for b in it.get("bonus", {}):
			var spec: Dictionary = GameData.bonuses.get(b, {})
			if spec.is_empty() or not spec.get("active", false):
				bad.append("%s: %s is not an active bonus" % [id, b])
			elif not (spec.kinds as Array).has(k) and not (k == "elemental" and (spec.kinds as Array).has("rare")):
				bad.append("%s: %s is not a %s bonus" % [id, b, k])
		if k == "elemental":
			var el := false
			for b in (it.get("bonus", {}) as Dictionary).keys() + (it.get("latent", {}) as Dictionary).keys():
				el = el or GameData.bonuses.get(b, {}).has("element")
			if not el:
				bad.append(id + " elemental without an element")
		if str(it["class"]) in ["common", "fine"] and str(it.type) in ["armor", "head"] and k != "physical":
			bad.append(id + " common/fine but " + k)
	check(bad.is_empty(), "every piece's bonuses fit its kind: physical none, regional techniques, elemental an element: " + ", ".join(bad.slice(0, 8)))
	check(kinds.has("physical") and kinds.has("regional") and kinds.has("elemental") and kinds.has("rare"), "all kinds are used: " + str(kinds))
	var classes := {}
	for id in GameData.items:
		if GameData.items[id].has("class"):
			classes[str(GameData.items[id]["class"])] = true
	for c in ["common", "fine", "cultural", "rare"]:
		check(classes.has(c), "the catalogue class %s is kept" % c)
	for b in GameData.bonuses:
		if str(b).begins_with("_"):
			continue
		var spec: Dictionary = GameData.bonuses[b]
		if spec.get("active", false):
			check(PlayerState.BONUS_NAMES.has(b), "active bonus %s is applied and named" % b)
		else:
			check(spec.has("needs"), "inactive bonus %s says what it needs" % b)


func _test_sword_bonus() -> void:
	var w := _world()
	var p := w.player
	for id in ["samurai_armor_lime", "iron_sword", "iron_katana_05", "iron_battle_axe_05", "iron_butcher_knife_05"]:
		p.inv.add(id)
	var mult := Skills.value(p, "combat", "damage_mult", 1.0)
	w.player_equip("iron_sword")
	var bare := p.damage()
	check(w.player_equip("samurai_armor_lime"), "samurai armour put on")
	check(is_equal_approx(p.damage(), bare + 1.0 * mult), "+1 melee damage with a sword in hand (%s -> %s)" % [bare, p.damage()])
	w.player_equip("iron_katana_05")
	check(is_equal_approx(p.damage(), (float(GameData.item("iron_katana_05").damage) + 1.0) * mult), "and with a katana")
	for id in ["iron_butcher_knife_05", "iron_battle_axe_05"]:
		check(GameData.items.has(id), id + " exists")
		if GameData.items.has(id):
			w.player_equip(id)
			check(not p.sword_in_hand() and is_equal_approx(p.damage(), float(GameData.item(id).get("damage", 2)) * mult), "but not with a %s (%s)" % [id, p.damage()])
	w.player_unequip("weapon")
	check(is_equal_approx(p.damage(), 2.0 * mult), "nor bare-handed")
	w.player_unequip("armor")
	w.player_equip("iron_katana_05")
	check(is_equal_approx(p.damage(), float(GameData.item("iron_katana_05").damage) * mult), "and nothing without the armour: not tied to the wearer")


func _test_latent() -> void:
	var w := _world()
	var p := w.player
	for id in ["mongol_cherbi_armor", "mage_hat_cyan"]:
		p.inv.add(id)
		w.player_equip(id)
	check(p.bonus("mounted_mobility") == 0.0 and p.bonus("frost_damage") == 0.0, "a latent bonus is never applied")
	check(is_equal_approx(p.bonus("max_stamina"), 5.0) and is_equal_approx(p.bonus("fire_damage"), 2.0), "the pieces' active bonuses are")
	check(PlayerState.latent_text("mage_hat_cyan").contains("needs") and not PlayerState.bonus_text("mage_hat_cyan").contains("frost"), "the frost is shown only as needing an ice spell: " + PlayerState.latent_text("mage_hat_cyan"))
	check(not PlayerState.bonus_text("mongol_cherbi_armor").contains("mount"), "mounted mobility is not shown as working")


# ---------------------------------------------------------------- Decision 7 -------------------
func _test_clothing() -> void:
	var bad := []
	var n := 0
	for id in GameData.items:
		var it: Dictionary = GameData.items[id]
		if it.get("clothing", false):
			n += 1
			if int(it.get("armor", 0)) != 0 or it.has("bonus") or it.has("latent"):
				bad.append(id)
	check(n >= 30 and bad.is_empty(), "%d ordinary garments, none with armour or a bonus: %s" % [n, ", ".join(bad)])
	for id in ["villager_straw_hat", "plain_clothes", "musketeer_hat_red", "traveller_robe", "ninja_bandana_red"]:
		check(GameData.item(id).get("clothing", false), "%s is clothing" % id)
	for id in ["mage_hat_red", "sorcerer_hood_cyan"]:
		check(not GameData.item(id).get("clothing", false) and not (GameData.item(id).get("bonus", {}) as Dictionary).is_empty(), "%s is magical equipment, not clothing" % id)
	var w := _world()
	var p := w.player
	p.inv.add("traveller_straw_hat")
	p.inv.add("traveller_robe")
	var hp := p.hp_cap()
	var st := p.stamina_cap()
	var dm := p.damage()
	var df := p.defense()
	w.player_equip("traveller_straw_hat")
	w.player_equip("traveller_robe")
	check(p.head == "traveller_straw_hat" and p.armor == "traveller_robe", "clothing is worn")
	check(p.hp_cap() == hp and p.stamina_cap() == st and p.damage() == dm and p.defense() == df, "and changes nothing but looks")


# ---------------------------------------------------------------- saves ------------------------
func _test_save() -> void:
	var w := _world()
	for id in NEW:
		w.player.inv.add(id, 2)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var same := true
	for id in NEW:
		same = same and w2.player.inv.count(id) == 2
	check(same, "a save keeps the new materials")
	# an older save: Garton's diggings without tin and the weavers without silk gain them, nothing else changes
	var g: Dictionary = d.regions
	var sets: Array = g.get("list", g.get("settlements", []))
	var old := {}
	for s in sets:
		var biz: Dictionary = s.biz
		if biz.has("quarry") and (biz.quarry.out as Dictionary).has("tin_ore"):
			biz.quarry.out.erase("tin_ore")
			biz.quarry.reserves.erase("tin_ore")
			old[str(s.id)] = biz.quarry.duplicate(true)
		if biz.has("weaver"):
			biz.weaver.out.erase("silk")
	check(not old.is_empty(), "the test save had Garton's diggings (%s)" % str(old.keys()))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d)
	var garton: OffMapSettlement = w3.regions.by_id.get("garton")
	var q: Dictionary = garton.biz.quarry
	check((q.out as Dictionary).has("tin_ore") and int(q.reserves.tin_ore) == 200, "an older save's diggings gain the tin and its reserve")
	var kept := true
	for k in old.garton.out:
		kept = kept and is_equal_approx(float(q.out[k]), float(old.garton.out[k]))
	for k in old.garton.reserves:
		kept = kept and int(q.reserves[k]) == int(old.garton.reserves[k])
	check(kept and int(q.stock.get("tin_ore", 0)) == int(old.garton.stock.get("tin_ore", 0)), "and nothing it had changes; no tin enters any stock")
	var silk := true
	for s: OffMapSettlement in w3.regions.list:
		if s.biz.has("weaver"):
			silk = silk and (s.biz.weaver.out as Dictionary).has("silk")
	check(silk, "the weavers gain raw silk")


func _test_wiki() -> void:
	var wk := Wiki.build()
	for id in NEW:
		check(wk.pages.has("item:" + id), "the encyclopedia has a page for " + id)
	var txt := JSON.stringify(wk.pages["sys:armoury"])
	check(txt.contains("Clothing") or txt.contains("clothing"), "the catalogue page says ordinary clothing is for looks")
	var todo := JSON.stringify(wk.pages["todo:gear_orders"])
	check(todo.contains("Fireball") and todo.contains("horses"), "the not-yet page names the elemental and riding bonuses that do nothing yet")
	check(not todo.contains("stand in"), "and no longer says the new materials are stand-ins")
