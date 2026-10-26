class_name WikiGear
extends RefCounted
## The encyclopedia's pages for the Build 22 armour and weapon catalogue (ARMOR-CATALOG-01, ARMOR-MATERIALS-01,
## WEAPON-CATALOG-01): how pieces are made and ordered, the classes, the worn bonuses, tusks and antlers, and one page per
## weapon type with its metals and designs. Every number comes from the data (items.json, the weapon table and its
## generated catalogue, recipes, balance.json); the rules from GearOrders, PlayerState.bonus, Fauna.kill. Registered by one
## line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	_armoury(w)
	for t in GameData.weapon_types.get("types", {}):
		_weapon_type(w, str(t))
	w.add_page("todo:gear_orders", "Armour and weapon orders: what is still to come", "notyet", [
		Wiki.note("Not in the game yet. An order is made while you wait: the maker does not yet take it away to the forge and call you back when it is done. The tailor keeps no cloth or straw of their own, so you bring what a hat is made of. The makers do not yet make catalogue pieces for stock or for other villagers, and the hired help of your own shop does not make them: you make them yourself or order them. Steel, bronze, fur and silk are not goods of their own yet: iron and coal stand in for steel, copper for bronze, hides for fur and fine cloth for silk."),
		Wiki.links(["sys:armoury"], "See also")], "", "not implemented planned armour weapon order steel bronze silk fur")


## A weapon type's name in the plural ("knives").
static func plural(tid: String) -> String:
	var t: Dictionary = GameData.weapon_types.get("types", {}).get(tid, {})
	return str(t.get("plural", str(t.get("name", tid)) + "s"))


static func _armoury(w: Wiki) -> void:
	var counts := {"armor": 0, "head": 0, "weapon": 0}
	var bonus_ex := {}
	for id in GameData.items:
		var it: Dictionary = GameData.items[id]
		if not it.has("order"):
			continue
		if str(it.type) != "weapon" or it.has("gear"):         # the weapons of the pattern sheets (the two plain swords apart)
			counts[str(it.type)] = int(counts.get(str(it.type), 0)) + 1
		for k in it.get("bonus", {}):
			if not bonus_ex.has(k):
				bonus_ex[k] = str(id)
	var boar: Dictionary = GameData.b("animals").boar
	var deer: Dictionary = GameData.b("animals").deer
	var bonus_rows := []
	for k in PlayerState.BONUS_NAMES:
		if bonus_ex.has(k):
			bonus_rows.append("+%s: %s (for example the %s)." % [PlayerState.BONUS_NAMES[k], {"max_hp": "more health at most", "max_stamina": "more stamina at most",
				"fire_damage": "each fireball does that much more damage", "stamina_regen": "stamina comes back faster, that much more each second",
				"damage": "each blow does that much more damage"}.get(k, ""), GameData.item_name(bonus_ex[k]).to_lower()])
	w.add_page("sys:armoury", "Armour and weapons: the catalogue", "systems", [
		Wiki.p("Every body armour, helmet and outfit drawn for the villagers' world, and every weapon of the smith's pattern sheets, can be made and ordered: %d body armours and outfits, %d helmets, hats and hoods, and %d weapons (16 kinds, each in bronze, iron, steel and gold, 30 patterns of each)." % [counts.armor, counts.head, counts.weapon]),
		Wiki.h("Who makes them"),
		Wiki.p("The smith is the village's armourer and weapon smith: metal armour, helmets and every weapon, at the anvil with Smithing. The tanner makes the leather and cloth pieces (the Japanese robes, the French coats and hats, the mage's hats and hoods) at the workbench with Tanning or Crafting. The tailor sews the plain hats, hoods and bandanas. Talk to them and choose the order: pick the kind, then the piece (for a weapon, its metal and one of its 30 patterns)."),
		Wiki.p("You can make any piece yourself at an anvil or a workbench you may use, with its skill level and its materials in your pack: open the station and choose Armour and weapons."),
		Wiki.h("Classes"),
		Wiki.bullets(["Common: plain bronze, iron and leather. Made from the maker's own stock; you pay its materials and a small fee for the work.",
			"Fine: steel (iron worked with coal), a higher Smithing level, more armour or damage, a larger fee.",
			"Cultural: Viking, Mongol, Japanese and French pieces. A commission: you bring the special materials (hides, wool or fine cloth, feathers, tusks or antlers) and pay a higher fee for the work.",
			"Rare: the striking pieces (gold, the knights' and lords' helms, the jarl, the khaan, the shogun, the mage's hats, and the masterwork patterns 22 to 30 of every weapon). Commissioned only, at the highest levels, and each carries a worn bonus.",
			"Plain: the tailor's hats and bandanas: clothing, no armour, no bonus."]),
		Wiki.p("The maker supplies what the piece needs from its own stock (iron and copper bars, leather, coal, planks) and charges each at its base price, on top of the fee. If it has run out of something, you can bring that too, and then you do not pay for it. The maker must have the recipe's skill level: a smith not yet practised enough cannot make the finest pieces. The order is made while you wait, the coins go to the maker and nothing is made from nothing."),
		Wiki.h("Worn bonuses"),
		Wiki.p("Rarer pieces give a bonus while worn or held in the hand, once for each piece (a piece in the pack gives nothing). The Pack shows it under the piece:"),
		Wiki.bullets(bonus_rows),
		Wiki.h("Tusks and antlers"),
		Wiki.p("Boar tusks and antlers go into special armour and weapons. They come only from animals really killed: a grown wild boar gives %d tusks, a grown stag (a male deer) %d antlers, whoever kills it, you or the hunter. Hunters sell theirs to the goods merchant, where you can buy them." % [int(boar.get("tusks", 0)), int(deer.get("antlers_m", 0))]),
		Wiki.h("On your figure"),
		Wiki.p("Every armour, helmet, hat and outfit of the catalogue is drawn on you while you wear it, in every direction, and other players see it too; taking it off shows your own clothes again. The weapon in your hand is carried drawn at your side while you stand or walk, and an attack swings it, as the axe is swung. Guards and bandits carry theirs the same way, and anyone who fights swings the weapon they have."),
		Wiki.h("Weapons"),
		Wiki.p("Each kind has its own damage, speed and wear: a knife or rapier swings quickly for little damage, a greatsword or battle hammer slowly and heavily. Steel does more and lasts longer than iron, bronze less. Patterns 13 to 21 are finer work (one more damage, a level more), 22 to 30 masterwork (two more damage, two levels more, a commission with tusks or antlers, and a worn bonus)."),
		Wiki.links(["item:boar_tusk", "item:antler", "job:smith", "job:tanner", "station:anvil", "station:workbench", "skill:smithing", "skill:tanning", "todo:gear_orders"] +
			(GameData.weapon_types.get("types", {}) as Dictionary).keys().map(func(k): return "gear:" + str(k)), "See also")],
		"", "armour armor weapon catalogue armourer order commission rare cultural buff bonus fireball tusk antler smith tanner tailor")


static func _weapon_type(w: Wiki, tid: String) -> void:
	var t: Dictionary = GameData.weapon_types.types[tid]
	var ids := []
	for id in GameData.items:
		if GameData.is_catalogue_weapon(id) and str(GameData.items[id].gear.wtype) == tid:
			ids.append(str(id))
	var blocks := [Wiki.p("The %s: %d patterns in each of four metals, made at the anvil (Smithing) or ordered from the smith. It swings at x%s the usual speed." % [str(t.name), ids.size() / 4, str(snappedf(float(t.speed), 0.01))])]
	for mid in GameData.weapon_types.metals:
		var m: Dictionary = GameData.weapon_types.metals[mid]
		var mine := ids.filter(func(i): return str(GameData.items[i].gear.metal) == mid)
		if mine.is_empty():
			continue
		blocks.append(Wiki.h("%s %s" % [str(m.name), plural(tid)]))
		var rows := []
		for tier in [1, 2, 3]:
			var one: Array = mine.filter(func(i): return int(GameData.items[i].gear.tier) == tier)
			if one.is_empty():
				continue
			var it: Dictionary = GameData.items[one[0]]
			var r: Dictionary = GameData.recipes[GearOrders.recipe_of(one[0])]
			var line := "damage %d, wear %d, %d coins, Smithing %d; %s" % [int(it.damage), int(it.durability), int(it.value), int(r.level), GearOrders.amounts(r["in"])]
			if PlayerState.bonus_text(one[0]) != "":
				line += "; worn: " + PlayerState.bonus_text(one[0])
			rows.append(["Patterns %d-%d" % [int(GameData.items[one[0]].gear.design), int(GameData.items[one[-1]].gear.design)], line])
		blocks.append(Wiki.stats(rows))
		blocks.append({"t": "designs", "ids": mine})
	blocks.append(Wiki.links(["sys:armoury", "station:anvil", "skill:smithing", "job:smith"], "See also"))
	w.add_page("gear:" + tid, plural(tid).capitalize(), "items_gear", blocks, Wiki.icon_path(ids[0]) if not ids.is_empty() else "",
		"weapon %s %s bronze iron steel gold pattern" % [str(t.name), tid])
