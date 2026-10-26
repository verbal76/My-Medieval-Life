extends SceneTree
## Build 22: the armour and weapon catalogue (ARMOR-CATALOG-01, ARMOR-MATERIALS-01, WEAPON-CATALOG-01, WEAPON-VISIBLE-01).
## Every catalogue piece has an icon, a recipe with a skill level and a seller, and every armour piece a worn picture of the
## pack's frame layout; worn bonuses apply and come off, once per item; tusks and antlers come only from killed animals;
## an order moves coins and goods and makes nothing from nothing, and is refused cleanly; the carried weapon is drawn in
## every direction and swung like the axe, by the player and villagers; the encyclopedia groups the weapons; a save keeps
## the gear. Run headless:
##   godot --headless --path game --script res://tests/gear_catalogue_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)


func _init() -> void:
	GameData.ensure()
	_test_catalogue_complete()
	_test_bonuses()
	_test_tusks_and_antlers()
	_test_orders()
	_test_weapon_drawn()
	_test_wiki_and_lists()
	_test_save()
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


## A maker at their post in working hours.
func _at_work(w: World, n: NPC) -> void:
	w.minutes = floorf(w.minutes / 1440.0) * 1440.0 + 10.0 * 60.0
	n.pos = Vector2(w.brain._workplace_cell(n)) + Vector2(0.5, 0.5)


# ---------------------------------------------------------------- the catalogue ----------------
func _test_catalogue_complete() -> void:
	var w := _world()
	var style: Dictionary = CharacterLook.style()
	var weapons := 0
	var pieces := 0
	var bad := []
	for id in GameData.items:
		var it: Dictionary = GameData.items[id]
		if not it.has("order"):
			continue
		pieces += 1
		if it.has("gear"):
			weapons += 1
		var why := []
		if not ResourceLoader.exists("res://assets/icons/%s.png" % id):
			why.append("no icon")
		var rid := GearOrders.recipe_of(id)
		var r: Dictionary = GameData.recipes.get(rid, {})
		if r.is_empty() or int(r.get("level", 0)) < 1 or int(r.get("level", 0)) > 10 or not GameData.skills.has(str(r.get("skill", ""))):
			why.append("no recipe with a skill level")
		elif not str(r.station) in ["anvil", "workbench"]:
			why.append("recipe at " + str(r.station))
		var maker := GearOrders.maker_job(id)
		if not GearOrders.MAKERS.has(maker) or _job(w, maker) == null:
			why.append("no seller (%s)" % maker)
		if int(it.get("value", 0)) <= 0 or int(it.get("durability", 0)) <= 0:
			why.append("no value or durability")
		if str(it.type) in ["armor", "head"]:
			var wl: Dictionary = (style.worn_layers as Dictionary).get(id, {})
			var opt = (style.layers.get(str(wl.get("layer", "")), {}) as Dictionary).get(str(wl.get("option", "")))
			if wl.is_empty() or opt == null or not ResourceLoader.exists(str(opt.sheet)):
				why.append("no worn picture")
			elif (load(str(opt.sheet)) as Texture2D).get_size() != Vector2(928, 256):
				why.append("worn sheet not 29 x 8 frames")
		for k in it.order.get("bring", {}):
			if not (r.get("in", {}) as Dictionary).has(k):
				why.append("brings %s the recipe does not take" % k)
		if not why.is_empty():
			bad.append("%s: %s" % [id, ", ".join(why)])
	check(bad.is_empty(), "every catalogue piece has an icon, a recipe with a skill level, a seller and (armour) a worn picture: " + "; ".join(bad.slice(0, 8)))
	var types: Dictionary = GameData.weapon_types.types
	check(types.size() == 16 and weapons == 16 * 4 * 30, "the master sheet's 16 types x 4 metals x 30 designs are items (%d)" % weapons)
	check(pieces >= weapons + 91, "and the 91 armour pieces with the existing gear (%d pieces)" % pieces)
	# classes and buffs: rare pieces carry a buff, plain ones none and no armour; cultural and rare are commissions
	var rare_no_buff := []
	for id in GameData.items:
		var it: Dictionary = GameData.items[id]
		match str(it.get("class", "")):
			"rare":
				if (it.get("bonus", {}) as Dictionary).is_empty() and not it.has("gear"):
					rare_no_buff.append(id)
				if (it.order.get("bring", {}) as Dictionary).is_empty():
					rare_no_buff.append(id + " (no commission)")
			"cultural":
				if (it.order.get("bring", {}) as Dictionary).is_empty():
					rare_no_buff.append(id + " (no commission)")
			"plain":
				if int(it.get("armor", 0)) != 0 or it.has("bonus"):
					rare_no_buff.append(id + " (plain with armour or bonus)")
	check(rare_no_buff.is_empty(), "rare armour has a buff, cultural and rare are commissions, plain hats have neither: " + ", ".join(rare_no_buff))
	for k in ["fire_damage", "stamina_regen", "damage", "max_hp", "max_stamina"]:
		var used := false
		for id in GameData.items:
			if (GameData.items[id].get("bonus", {}) as Dictionary).has(k):
				used = true
				break
		check(used and PlayerState.BONUS_NAMES.has(k), "the %s buff is used and named" % k)
	# existing items' values unchanged
	for pair in [["iron_armor", 80, 6], ["leather_armor", 30, 3], ["iron_helmet", 36, 2], ["leather_cap", 14, 1]]:
		check(GameData.value(pair[0]) == pair[1] and int(GameData.item(pair[0]).armor) == pair[2], "%s keeps its value and armour" % pair[0])
	check(int(GameData.item("iron_sword").damage) == 11 and GameData.value("iron_sword") == 48, "the iron sword keeps its numbers")


# ---------------------------------------------------------------- worn bonuses ----------------
func _test_bonuses() -> void:
	var w := _world()
	var p := w.player
	for id in ["gold_armor", "gold_armor", "shogun_helm_green", "viking_warrior_armor", "steel_butcher_knife_25"]:
		p.inv.add(id)
	var hp0 := p.hp_cap()
	var st0 := p.stamina_cap()
	var dmg0 := p.damage()
	check(w.player_equip("gold_armor"), "gold armour put on")
	check(is_equal_approx(p.hp_cap(), hp0 + 10.0), "+10 health while the gold armour is worn (%s -> %s)" % [hp0, p.hp_cap()])
	check(is_equal_approx(p.hp_cap(), hp0 + 10.0) and p.inv.count("gold_armor") == 2, "two in the pack, one worn: counted once")
	# stamina regeneration: a second of the player's update
	p.stamina = 10.0
	w._update_one_player(1.0, 0.0)
	var regen := float(GameData.b("player_stamina_regen_per_second"))
	check(is_equal_approx(p.stamina, 10.0 + regen + 1.0), "the gold armour's +1 stamina a second is regenerated (%s)" % p.stamina)
	check(w.player_unequip("armor"), "gold armour taken off")
	check(is_equal_approx(p.hp_cap(), hp0), "health back as it was when it comes off")
	p.stamina = 10.0
	w._update_one_player(1.0, 0.0)
	check(is_equal_approx(p.stamina, 10.0 + regen), "and the regeneration too")
	# melee damage
	w.player_equip("viking_warrior_armor")
	check(is_equal_approx(p.damage(), (2.0 + 1.0) * Skills.value(p, "combat", "damage_mult", 1.0)), "+1 melee damage from the tusked mail (%s)" % p.damage())
	w.player_equip("steel_butcher_knife_25")
	var knife := float(GameData.item("steel_butcher_knife_25").damage)
	check(is_equal_approx(p.damage(), (knife + 1.0 + 2.0) * Skills.value(p, "combat", "damage_mult", 1.0)), "the butcher knife's own +2 adds to it while held")
	w.player_unequip("armor")
	w.player_unequip("weapon")
	check(is_equal_approx(p.damage(), dmg0), "melee damage back without them")
	# fireball damage: the same shot at a sturdy boar with and without the shogun helm
	var a := w.fauna.spawn(w.fauna.woods.keys()[0] if not w.fauna.woods.is_empty() else "", "boar", "m", null)
	a.hp = 1000.0
	var base := float(w.player_fireball_hit(a.pos).dealt)
	w.player_equip("shogun_helm_green")
	var hot := float(w.player_fireball_hit(a.pos).dealt)
	check(is_equal_approx(hot, base + 4.0), "+4 fireball damage with the shogun helm (%s -> %s)" % [base, hot])
	w.player_unequip("head")
	check(is_equal_approx(float(w.player_fireball_hit(a.pos).dealt), base), "and back without it")
	check(is_equal_approx(p.stamina_cap(), st0), "stamina cap unchanged by pieces without a stamina buff")


# ---------------------------------------------------------------- tusks and antlers ------------
func _test_tusks_and_antlers() -> void:
	var w := _world()
	var none := true
	for n: NPC in w.npcs:
		if n.inv.count("boar_tusk") > 0 or n.inv.count("antler") > 0:
			none = false
	check(none and w.player.inv.count("boar_tusk") == 0, "no tusk or antler exists at the start: they are not stock from nothing")
	var wood: String = w.fauna.woods.keys()[0] if not w.fauna.woods.is_empty() else ""
	var boar := w.fauna.spawn(wood, "boar", "f", null)
	boar.born = w.minutes - 400.0 * 1440.0
	var bag := w.fauna.kill(boar)
	check(bag.count("boar_tusk") == 2 and int(w.stats.get("made_boar_tusk", 0)) == 2, "a grown boar killed gives 2 tusks, counted made_")
	var piglet := w.fauna.spawn(wood, "boar", "m", null)
	check(w.fauna.kill(piglet).count("boar_tusk") == 0, "a young boar gives none")
	var stag := w.fauna.spawn(wood, "deer", "m", null)
	stag.born = w.minutes - 400.0 * 1440.0
	var sb := w.fauna.kill(stag)
	check(sb.count("antler") == 2 and int(w.stats.get("made_antler", 0)) == 2, "a grown stag gives 2 antlers")
	var doe := w.fauna.spawn(wood, "deer", "f", null)
	doe.born = w.minutes - 400.0 * 1440.0
	check(w.fauna.kill(doe).count("antler") == 0, "a doe gives none")
	check(NPCBrain.OUTLETS.get("boar_tusk", []).has("merchant_goods") and NPCBrain.BUYS.merchant_goods.has("antler"), "hunters sell them to the goods merchant")


# ---------------------------------------------------------------- orders -----------------------
func _units(w: World, n: NPC, ids: Array) -> Dictionary:
	var d := {}
	for id in ids:
		d[id] = w.player.inv.count(id) + n.inv.count(id)
	return d


func _test_orders() -> void:
	var w := _world()
	var p := w.player
	var smith := _job(w, "smith")
	_at_work(w, smith)
	smith.skills["smithing"] = Skills.xp_for_level(5)
	smith.inv.add("iron_bar", 10)
	smith.inv.add("leather", 4)
	p.coins = 1000
	# a common piece from the maker's stock
	var id := "iron_sword_01"
	var r: Dictionary = GameData.recipes[GearOrders.recipe_of(id)]
	var ids: Array = (r["in"] as Dictionary).keys() + [id]
	var before := _units(w, smith, ids)
	var coins := p.coins + smith.coins
	var t := GearOrders.terms(w, smith, id, p)
	var res := w.player_order_gear(smith, id)
	check(res.ok and p.inv.count(id) == 1, "the smith makes an iron sword to order")
	check(p.coins + smith.coins == coins and int(res.paid) == int(t.price), "the price goes from the buyer to the smith, no coin made (%d)" % int(res.paid))
	var after := _units(w, smith, ids)
	var used_ok := true
	for k in r["in"]:
		var used: int = int(before[k]) - int(after[k])
		used_ok = used_ok and (used == int(r["in"][k]) or used == 0)       # all used, or all saved by a practised hand
	check(used_ok and int(after[id]) == int(before[id]) + 1, "its inputs were used by the recipe and one sword made")
	# a commission: the buyer brings the special materials
	var c := "viking_warrior_armor"
	var ok_t := GearOrders.terms(w, smith, c, p)
	check(str(ok_t.why).begins_with("You need"), "without the tusks and hides the commission is refused: " + str(ok_t.why))
	var coins1 := p.coins
	check(not w.player_order_gear(smith, c).ok and p.coins == coins1, "and nothing changes hands")
	p.inv.add("boar_tusk", 2)
	p.inv.add("hide", 3)
	coins = p.coins + smith.coins
	res = w.player_order_gear(smith, c)
	check(res.ok and p.inv.count(c) == 1 and p.inv.count("boar_tusk") == 0 and p.inv.count("hide") == 0, "with them it is made, and they are used")
	check(p.coins + smith.coins == coins, "coins conserved for the commission")
	# refusals: the wrong maker, asleep, too little skill
	var tanner := _job(w, "tanner")
	check(not GearOrders.terms(w, tanner, "steel_armor", p).why.is_empty(), "a tanner does not forge steel armour")
	smith.skills["smithing"] = Skills.xp_for_level(1)
	check(str(GearOrders.terms(w, smith, "gold_armor", p).why).contains("needs Smithing"), "a smith below the recipe's level cannot make it")
	smith.skills["smithing"] = Skills.xp_for_level(5)
	w.minutes = floorf(w.minutes / 1440.0) * 1440.0 + 2.0 * 60.0
	check(not GearOrders.terms(w, smith, "iron_sword_01", p).why.is_empty() or not w.asleep(smith), "a sleeping smith takes no order")
	check(NetActions.VERBS.has("player_order_gear"), "ordering is a player verb a guest can use")
	# the tanner's and tailor's pieces
	_at_work(w, tanner)
	tanner.skills["crafting"] = Skills.xp_for_level(5)
	tanner.skills["tanning"] = Skills.xp_for_level(5)
	p.inv.add("fine_cloth", 2)
	p.inv.add("gold_bar", 1)
	tanner.inv.add("wool_cloth", 1)
	check(w.player_order_gear(tanner, "mage_hat_red").ok and p.inv.has("mage_hat_red"), "the tanner makes a mage's hat to commission")
	var tailor := _job(w, "tailor")
	_at_work(w, tailor)
	p.inv.add("wool_cloth", 1)
	check(w.player_order_gear(tailor, "ninja_bandana_red").ok, "the tailor sews a bandana from the buyer's cloth")


# ---------------------------------------------------------------- drawn weapons ----------------
func _test_weapon_drawn() -> void:
	var s := ActorSprite.new()
	var root := Node2D.new()
	get_root().add_child(root)
	root.add_child(s)
	s.setup(str("res://assets/characters/villager_00.png"))
	s.wield("iron_katana_05")
	var shown := 0
	for d in 8:
		for a in ["idle", "walk"]:
			s.dir = d
			s.play(a)
			s._process(0.05)
			if s.weapon_icon.visible and s.weapon_icon.texture != null:
				shown += 1
	check(shown == 16, "the weapon is drawn standing and walking in all eight directions (%d of 16)" % shown)
	s.play("work")
	s._process(0.05)
	check(not s.weapon_icon.visible, "not while working")
	s.strike()
	s._process(0.05)
	check(s.anim == "swing" and s.tool_item == "iron_katana_05" and s.tool_icon.visible and s.striking, "a blow is the axe's swing with the weapon in hand")
	for k in 10:
		s._process(0.1)
	check(s.anim == "idle" and not s.striking, "and plays through once")
	s.wield("")
	s.play("idle")
	s._process(0.05)
	check(not s.weapon_icon.visible, "putting it away hides it")
	var w := _world()
	var guard := _job(w, "guard")
	check(guard != null and ActorSprite.npc_weapon(guard) != "", "a guard carries a weapon: " + (ActorSprite.npc_weapon(guard) if guard else ""))
	var smith := _job(w, "smith")
	smith.anim = "idle"
	check(smith.inv.has("iron_sword") and ActorSprite.npc_weapon(smith) == "", "a smith's swords for sale are not carried")
	smith.anim = "sword"
	check(ActorSprite.npc_weapon(smith) == "iron_sword", "but swung in a fight")
	root.queue_free()


# ---------------------------------------------------------------- encyclopedia and lists -------
func _test_wiki_and_lists() -> void:
	var t0 := Time.get_ticks_msec()
	var wk := Wiki.build()
	var ms := Time.get_ticks_msec() - t0
	var per_type := 0
	for t in GameData.weapon_types.types:
		if wk.pages.has("gear:" + str(t)):
			per_type += 1
	check(per_type == 16 and wk.pages.has("sys:armoury") and wk.pages.has("todo:gear_orders"), "a page for every weapon type and the catalogue")
	check(not wk.pages.has("item:iron_katana_05") and not wk.pages.has("recipe:forge_iron_katana_05"), "no page for each of the 1,920 weapons")
	check(wk.pages.has("item:boar_tusk") and wk.pages.has("item:antler") and wk.pages.has("item:gold_armor"), "tusks, antlers and armour pieces have pages")
	check(wk.pages.size() < 900, "the encyclopedia stays a readable size (%d pages, built in %d ms)" % [wk.pages.size(), ms])
	check(Skills.recipes_at("smithing", 3).size() < 60, "the skills list groups the weapon patterns")


# ---------------------------------------------------------------- saves ----------------------
func _test_save() -> void:
	var w := _world()
	var p := w.player
	for id in ["gold_battle_axe_23", "viking_jarl_armor", "mage_hat_cyan"]:
		p.inv.add(id)
		w.player_equip(id)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.player.weapon == "gold_battle_axe_23" and w2.player.armor == "viking_jarl_armor" and w2.player.head == "mage_hat_cyan", "a save keeps the catalogue gear worn")
	check(is_equal_approx(w2.player.hp_cap(), w.player.hp_cap()) and is_equal_approx(w2.player.bonus("fire_damage"), 2.0), "and its bonuses")
