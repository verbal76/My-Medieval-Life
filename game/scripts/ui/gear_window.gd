class_name GearWindow
extends RefCounted
## ARMOR-CATALOG-01, WEAPON-CATALOG-01 (Build 22): the armour and weapon catalogue in two windows that share one picker:
##  - ordering from a maker (the smith, the tanner, the tailor: GearOrders), from the talk window;
##  - making it yourself at a station (the anvil, the workbench), from the craft window.
## Over two thousand pieces stay findable by grouping: first a kind (body armour, helmets and hats, then each weapon type),
## then for armour a list of pieces, for a weapon type the metal (bronze, iron, steel, gold) and the 30 designs as a grid
## of icons; picking one shows what it is, what it needs and the button to order or make it. What the player sees comes
## from core (GearOrders.terms, World.player_craft_refusal); the window decides nothing.

const ARMOUR_GROUPS := [["body", "Body armour and outfits", "armor"], ["head", "Helmets and hats", "head"], ["other", "Plain swords", "weapon"]]
const COLS := 6


## The pieces in reach of this window: a maker's catalogue (order) or the station's (craft), as item ids.
static func pieces(ui, mode: String, ctx) -> Array:
	if mode == "order":
		return GearOrders.catalogue((ctx as NPC).job)
	var st_type: String = ui.main.world.stations[ctx].type
	var out := []
	for r in GameData.recipes_at(st_type):
		var id := str(GameData.recipes[r].out.keys()[0])
		if GameData.orderable(id) and not out.has(id):
			out.append(id)
	return out


## The group an item belongs to: a weapon's type, or body / head / other.
static func group_of(id: String) -> String:
	var it := GameData.item(id)
	if it.has("gear"):
		return str(it.gear.wtype)
	match str(it.get("type", "")):
		"armor":
			return "body"
		"head":
			return "head"
	return "other"


static func _rank(g: String) -> int:
	return {"body": 0, "head": 1, "other": 3}.get(g, 2)


static func group_name(g: String) -> String:
	for a in ARMOUR_GROUPS:
		if a[0] == g:
			return a[1]
	var t: Dictionary = GameData.weapon_types.get("types", {}).get(g, {})
	return WikiGear.plural(g).capitalize() if not t.is_empty() else g.capitalize()


## The window: `group` "" shows the kinds; an armour group its list; a weapon type its metals and designs (`metal`),
## with `pick` the design chosen.
static func show(ui, mode: String, ctx, group := "", metal := "", pick := "") -> void:
	var w: World = ui.main.world
	var all := pieces(ui, mode, ctx)
	var title := ("%s, %s: order armour and weapons" % [(ctx as NPC).name, (ctx as NPC).job]) if mode == "order" else "The %s: armour and weapons" % w.stations[ctx].type
	ui._open("gear", title + "  ·  you have %d coins" % w.player.coins, ui.main.paused)
	if group == "":
		ui.panel_back = func(): _back(ui, mode, ctx)
		ui._label("Choose what kind of piece. Cultural and rare pieces are commissions: you bring the special materials and pay for the work." if mode == "order" else "Choose what kind of piece to make. Each needs its Smithing, Tanning or Crafting level and its materials in your pack.", 15)
		var groups := []
		for id in all:
			var g := group_of(id)
			if not groups.has(g):
				groups.append(g)
		# armour first, then the weapon types by name, the plain swords last
		groups.sort_custom(func(a, b): return _rank(a) < _rank(b) or (_rank(a) == _rank(b) and group_name(a) < group_name(b)))
		var grid := GridContainer.new()
		grid.columns = 2
		ui.panel_body.add_child(grid)
		for g in groups:
			var first: String = all.filter(func(i): return group_of(i) == g)[0]
			var n := all.filter(func(i): return group_of(i) == g).size()
			var b: Button = ui._button("%s (%d)" % [group_name(g), n], func(): show(ui, mode, ctx, g), true, grid)
			b.name = "Group " + g
			b.icon = _tex(first)
			b.expand_icon = false
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		return
	ui.panel_back = func(): show(ui, mode, ctx)
	var mine := all.filter(func(i): return group_of(i) == group)
	if not GameData.weapon_types.get("types", {}).has(group):
		for id in mine:
			_row(ui, mode, ctx, id, func(): show(ui, mode, ctx, group))
		return
	# a weapon type: the metal, then the designs
	var metals := []
	for id in mine:
		var m := str(GameData.item(id).gear.metal)
		if not metals.has(m):
			metals.append(m)
	if metal == "" or not metals.has(metal):
		metal = metals[0]
	var bar := HBoxContainer.new()
	ui.panel_body.add_child(bar)
	for m in metals:
		var mb: Button = ui._button(str(GameData.weapon_types.metals[m].name), func(): show(ui, mode, ctx, group, m), true, bar)
		mb.name = "Metal " + m
		mb.disabled = m == metal
	var designs := mine.filter(func(i): return str(GameData.item(i).gear.metal) == metal)
	if pick == "" or not designs.has(pick):
		pick = designs[0]
	_row(ui, mode, ctx, pick, func(): show(ui, mode, ctx, group, metal, pick))
	ui._label("Patterns 1 to 12 are plain, 13 to 21 finer work (a level more), 22 to 30 masterwork: rare, commissioned with special materials, each with a worn bonus.", 14, Color(0.8, 0.78, 0.7))
	var grid := GridContainer.new()
	grid.columns = COLS
	ui.panel_body.add_child(grid)
	for id in designs:
		var it := GameData.item(id)
		var b := Button.new()
		b.name = "Design " + id
		b.icon = _tex(id)
		b.text = str(int(it.gear.design))
		b.tooltip_text = str(it.name)
		b.custom_minimum_size = Vector2(84, 56)
		b.expand_icon = true
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.disabled = id == pick
		var pid: String = id
		b.pressed.connect(func(): show(ui, mode, ctx, group, metal, pid))
		grid.add_child(b)


## One piece: icon, name, class, its numbers and worn bonus, what it needs and costs, and the Order or Make button.
static func _row(ui, mode: String, ctx, id: String, again: Callable) -> void:
	var w: World = ui.main.world
	var it := GameData.item(id)
	var h := HBoxContainer.new()
	h.name = "Piece " + id
	h.add_child(ui._icon(id))
	var parts := [str(it.name), str(it.get("class", "common")).capitalize()]
	if it.has("damage"):
		parts.append("damage %d" % int(it.damage))
		if float(it.get("attack_speed", 1.0)) != 1.0:
			parts.append("speed x%s" % str(snappedf(float(it.attack_speed), 0.01)))
	if it.has("armor"):
		parts.append("armour %d" % int(it.armor))
	if PlayerState.bonus_text(id) != "":
		parts.append("worn: " + PlayerState.bonus_text(id))
	var rid := GearOrders.recipe_of(id)
	var r: Dictionary = GameData.recipes.get(rid, {})
	var why := ""
	var btn := ""
	if mode == "order":
		var t := GearOrders.terms(w, ctx, id, w.player)
		parts.append("%d coins" % int(t.price))
		if not (t.from_player as Dictionary).is_empty():
			parts.append("you bring " + GearOrders.amounts(t.from_player))
		why = str(t.why)
		btn = "Order"
	else:
		parts.append("needs " + GearOrders.amounts(r.get("in", {})))
		parts.append("%s %d" % [GameData.skills[str(r.skill)].name, int(r.level)])
		why = w.player_craft_refusal(rid)
		var st := w.station_refusal(ctx)
		why = st if st != "" else why
		btn = "Make"
	var l := Label.new()
	l.text = "  ·  ".join(parts) + ("" if why == "" else "\n" + why)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b: Button = ui._button(btn, func():
		if mode == "order":
			var res: Dictionary = w.player_order_gear(ctx, id)
			if res.ok:
				ui.sfx("coin")
				ui.message("%s makes you a %s (%d coins paid)." % [(ctx as NPC).name, str(it.name).to_lower(), int(res.paid)], 4.0, "trade")
			else:
				ui.message(str(res.why))
			again.call()
		else:
			ui.main.craft(rid, str(ctx)), why == "", h)
	b.name = btn
	ui.panel_body.add_child(h)


static func _back(ui, mode: String, ctx) -> void:
	if mode == "order":
		ui._talk_view(ctx, "Anything else?")
	else:
		ui.show_craft(str(ctx))


static func _tex(id: String) -> Texture2D:
	var path := "res://assets/icons/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null
