extends SceneTree
## PROP-02: a fabricated guest verb cannot remove someone else's shop counter.
## This exercises an actual built house/storage module with a fitted counter.
var checks := 0
var failures := 0
func check(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("ok   " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)
func finish(w: World, pl: Dictionary) -> void:
	for id in pl.site.need.duplicate():
		w.player.inv.add(id, int(pl.site.need[id]))
	w.deliver(pl, w.player.inv, World.PLAYER)

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 7002)
	w.player.coins = 5000
	var plot: Dictionary = w.plots[0]
	check(w.property.lease(plot, World.PLAYER) == "", "PROP-02: host leases land")
	w.start_site(plot, "house", World.PLAYER)
	finish(w, plot)
	var box := Rect2i(int(plot.x) - 40, int(plot.y) - 40, int(plot.w) + 80, int(plot.h) + 80)
	for tree in w.trees:
		if box.has_point(Vector2i(int(tree.x), int(tree.y))):
			tree.state = "cleared"
			w.map.set_solid(Vector2i(int(tree.x), int(tree.y)), false)
	var c: Construction = w.construction
	var slot := c.find_module_slot("storage", plot, World.PLAYER)
	var module: Dictionary = c.place("storage", slot, World.PLAYER, false, plot)
	check(not module.is_empty(), "PROP-02: host starts a storage room")
	if module.is_empty():
		w.dispose()
		quit(1)
		return
	finish(w, module)
	var b: Dictionary = w.property.building_on(module)
	check(not b.is_empty(), "PROP-02: host storage room exists")
	for id in Fitting.cost("counter"):
		w.player.inv.add(id, int(Fitting.cost("counter")[id]))
	var cell := Vector2i(-1, -1)
	var cells: Array = w.fitting.floor_set(b).keys()
	cells.sort_custom(func(x: Vector2i, y: Vector2i): return x.y < y.y or (x.y == y.y and x.x < y.x))
	for cc: Vector2i in cells:
		if w.fitting.why_not(b, "counter", cc) == "":
			cell = cc
			break
	check(cell != Vector2i(-1, -1), "PROP-02: a counter can be placed in the owner's room")
	if cell == Vector2i(-1, -1):
		w.dispose()
		quit(1)
		return
	check(w.fitting.place(b, "counter", cell) == "", "PROP-02: host places a real counter")
	check(w.business.open_shop(b) == "", "PROP-02: host opens its shop")
	w.player.inv.add("plank", 2)
	check(w.business.list_item(b.shop, "plank", 2) == "", "PROP-02: shop has stock")
	var guest := PlayerState.new()
	guest.name = "Guest"
	guest.family = "Test"
	guest.sex = "female"
	guest.born = w.player.born
	Identity.register_player(w, guest)
	w.give_start_kit(guest)
	guest.net_key = "e".repeat(32)
	guest.pos = Vector2(float(b.x) + 1.0, float(b.y) + 1.0)
	w.add_guest(guest)
	var mat := str(Fitting.cost("counter").keys()[0])
	var before_items := guest.inv.count(mat)
	var r := NetActions.apply_verb(w, guest, "fitting.remove", [NetActions.enc(w, b), "counter"])
	check(not bool(r.get("ok", false)) or str(r.get("result", "")) == "That is not your room.", "PROP-02: foreign fitting removal refused")
	check(w.fitting.count(b, "counter") == 1, "PROP-02: forged request leaves counter in place")
	check(b.has("shop") and int(b.shop.stock.get("plank", 0)) == 2, "PROP-02: foreign shop and stock remain intact")
	check(guest.inv.count(mat) == before_items, "PROP-02: no stolen fitting materials")
	check(w.fitting.remove(b, "counter") == "", "PROP-02: rightful owner can still remove its counter")
	check(w.fitting.count(b, "counter") == 0 and not b.has("shop"), "PROP-02: owner removal closes its own shop")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
