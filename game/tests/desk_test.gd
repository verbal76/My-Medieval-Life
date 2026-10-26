extends SceneTree
## GP-BUSINESS-DESK (owner, 2026-10-24: "that table, that person is standing near is where the smithy does business. So maybe you
## click on that and it asks if you want to talk to the smithy to buy something or sell something. Or speak to a courier. Just
## make that the business desk, like in all businesses."), in the real game scene:
##   * every business has one desk on drawn furniture (the tavern's counter, the smithy's table with the open ledger, the
##     sawmill's table, each merchant's stall, the service pitches, a storefront), its cell solid and its keeper's cell free;
##   * a counter desk is offered only beside it and facing it, never from behind or facing away;
##   * using it opens a short menu (GameUI.show_desk): trade with the keeper when the keeper is there (the ordinary shop window,
##     buying and selling unchanged), otherwise it says nobody is there and offers what the counter rules allow (ring for
##     service), and each choice is done as Use on it would;
##   * the player's own stall is a desk too (manage it; open a courier booth there), actor-aware for a guest;
##   * saves: a Build 21 save (save 22) and the Build 20 save (save 21) load; the desks need nothing saved.
##   godot --headless --path game --script res://tests/desk_test.gd

var main
var checks := 0
var failures := 0
const DIRS := {Vector2i(0, 1): 0, Vector2i(1, 0): 2, Vector2i(0, -1): 4, Vector2i(-1, 0): 6}    # step toward the desk -> PlayerSprite.dir


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/desk_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _buttons(n: Node, out: Array) -> Array:
	if n is Button:
		out.append(n)
	for c in n.get_children():
		_buttons(c, out)
	return out


func _named(prefix: String) -> Button:
	for b: Button in _buttons(main.ui.panel_body, []):
		if b.name.begins_with(prefix):
			return b
	return null


## Stand the player on a free cell beside desk `d` (not its keeper's cell), facing it; true when a cell was found.
func _stand_at(w: World, d: Dictionary) -> bool:
	var at: Vector2i = d.at
	var cells := []
	for step: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if at - step != d.use:
			cells.append(step)
	cells.append(at - (d.use as Vector2i))             # last: the keeper's own cell, facing the desk (World.station_in_reach)
	for step: Vector2i in cells:
		var c: Vector2i = at - step
		if w.map.is_solid(c) or not DIRS.has(step):
			continue
		w.player.pos = Vector2(c) + Vector2(0.5, 0.5)
		main.player_sprite.dir = DIRS[step]
		if w.reaches(w.player.pos, Vector2(at) + Vector2(0.5, 0.5)) or w.reaches(w.player.pos, Vector2(d.use) + Vector2(0.5, 0.5)):
			return true
	return false


func _target_desk(w: World) -> Dictionary:
	main._find_target()
	return main.target if str(main.target.get("kind", "")) == "desk" else {}


## Everybody away from the counters and stalls (asleep at home is not needed: far off and idle).
func _clear_keepers(w: World) -> void:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult":
			n.pos = Vector2(10.5, 70.5)
			n.plan = [w.brain.work(600, "", {}, "idle")]


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var ui: GameUI = main.ui
	var desks := BusinessDesks.all(w)
	var ids := desks.map(func(d): return str(d.id))
	var tav: String = w.stations_of("tavern_counter")[0]
	var arm: String = w.stations_of("armory_counter")[0]
	var saw: String = w.stations_of("sawmill_counter")[0]
	check(ids.has(tav) and ids.has(arm) and ids.has(saw), "the tavern's counter, the smithy's ledger table and the sawmill's table are desks (%s, %s, %s)" % [tav, arm, saw])
	check(str(w.stations[arm].building) == str(w.stations[w.stations_of("forge")[0]].building), "the smithy's desk stands in the smithy (its building)")
	var counters_ok := true
	for d in desks:
		if str(d.kind) == "counter":
			counters_ok = counters_ok and w.map.is_solid(d.at) and not w.map.is_solid(d.use) and str(d.building) != ""
	check(counters_ok, "every counter desk is drawn furniture (solid) with a free cell for its keeper, in a building")
	var merchants := w.npcs.filter(func(n): return n.alive and n.job == "merchant")
	var one_each := true
	for n: NPC in merchants:
		var d := BusinessDesks.of_business(w, World.npc_ref(n.id))
		one_each = one_each and str(d.get("kind", "")) == "stall" and str(d.post) == str(n.workplace)
	check(not merchants.is_empty() and one_each, "each merchant's desk is their own stall (%d merchants)" % merchants.size())
	var smith: NPC = w.npcs.filter(func(n): return n.alive and n.job == "smith")[0]
	check(str(BusinessDesks.of_business(w, World.npc_ref(smith.id)).get("id", "")) == arm, "the smith's desk is the ledger table, not the forge")
	var carp := w.npcs.filter(func(n): return n.alive and n.job == "carpenter")
	check(carp.is_empty() or str(BusinessDesks.of_business(w, World.npc_ref(carp[0].id)).get("id", "")) == saw, "a carpenter's desk is the sawmill's table")
	var tk := w.npcs.filter(func(n): return n.alive and n.job == "tavernkeeper")
	check(not tk.is_empty() and str(BusinessDesks.of_business(w, World.npc_ref(tk[0].id)).get("id", "")) == tav, "the tavernkeeper's desk is the tavern's counter")
	# --- the smithy's desk with nobody at it: it says so and offers ringing for service
	_clear_keepers(w)
	w.counters.serving.clear()
	var ad := BusinessDesks.by_id(w, arm)
	check(_stand_at(w, ad), "the player stands beside the smithy's desk, facing it")
	var t := _target_desk(w)
	check(not t.is_empty() and str(t.desk.id) == arm, "facing the desk offers it (%s)" % str(main.target.get("label", "")))
	check(not t.is_empty() and str(t.options[0].kind) == "summon" and str(t.status).begins_with("Nobody is at the desk"), "nobody at it: '%s', and ringing for service is offered" % str(t.get("status", "")))
	main.player_sprite.dir = (int(main.player_sprite.dir) + 4) % 8
	main._find_target()
	check(not (str(main.target.get("kind", "")) == "desk" and str(main.target.desk.id) == arm), "facing away, the desk is not offered")
	var far := w.player.pos
	w.player.pos = Vector2(ad.at) + Vector2(0.5, 3.5)
	main._find_target()
	check(not (str(main.target.get("kind", "")) == "desk"), "two cells off, not offered")
	w.player.pos = far
	_stand_at(w, ad)
	t = _target_desk(w)
	if not t.is_empty():
		ui.show_desk(t)
	check(ui.panel_kind == "desk" and _named("Desk_summon") != null and ui.title_label.text.to_lower().contains("smith"), "Use opens the desk's short menu (%s)" % ui.title_label.text)
	# make a smith available (working hours, fed, awake) and ring
	w.minutes = floorf(w.minutes / 1440.0) * 1440.0 + 10.0 * 60.0          # 10:00, working hours
	for n: NPC in w.npcs.filter(func(x): return x.alive and x.job == "smith"):
		n.hunger = 100.0
	var ring := _named("Desk_summon")
	if ring != null:
		ring.pressed.emit()
	var server := w.counters.server(arm)
	check(server != null and server.job == "smith", "ringing from the menu brings a smith to the desk (%s)" % ui.toast.text)
	if server != null:
		server.pos = Vector2(w.station_use(arm)) + Vector2(0.5, 0.5)
		server.plan = [w.brain.work(60, "serve_counter", {"counter": arm}, "idle")]
		w.counters.serving[arm] = server.id
		t = _target_desk(w)
		check(not t.is_empty() and str(t.options[0].kind) == "shop" and t.options[0].npc == server and str(t.status).contains("is at the desk"), "with the smith at it, the desk trades with them (%s)" % str(t.get("status", "")))
		if not t.is_empty():
			ui.show_desk(t)
		var trade := _named("Desk_shop")
		if trade != null:
			trade.pressed.emit()
		check(ui.panel_kind == "trade", "choosing trade opens the ordinary shop window (%s)" % ui.panel_kind)
		ui.hide_all()
		# buying at the desk is the ordinary trade: the smith's goods for coins, conserved
		var sale: Array = w.brain.for_sale(server)
		check(not sale.is_empty(), "the smith has goods for sale (%s)" % str(sale))
		if not sale.is_empty():
			var item := str(sale[0])
			w.player.coins = 2000
			var total := w.total_coins()
			var had := w.player.inv.count(item)
			var r: Dictionary = w.player_buy_many(server, item, 1)
			check(w.player.inv.count(item) == had + 1 and w.total_coins() == total, "buying one %s from the smith at the desk: in the pack, coins conserved (%s)" % [item, str(r.get("text", r))])
	w.counters.serving.clear()
	# --- the sawmill's desk: the carpenters keep it as the smiths keep theirs
	_clear_keepers(w)
	var swd := BusinessDesks.by_id(w, saw)
	check(_stand_at(w, swd), "the player stands at the sawmill's table, facing it")
	t = _target_desk(w)
	check(not t.is_empty() and str(t.desk.id) == saw and str(t.options[0].kind) in ["summon", "info"], "the sawmill's desk offers ringing for a carpenter (%s)" % str(main.target.get("label", "")))
	# --- the tavern: its keeper at the counter trades from the desk
	_clear_keepers(w)
	var keeper: NPC = tk[0]
	keeper.pos = w.shop_post(keeper)
	keeper.plan = [w.brain.work(600, "", {}, "idle")]
	var td := BusinessDesks.by_id(w, tav)
	check(_stand_at(w, td), "the player stands at the tavern's counter, facing it")
	t = _target_desk(w)
	check(not t.is_empty() and str(t.options[0].kind) == "shop" and t.options[0].npc == keeper, "the tavernkeeper at the counter: trade from the desk (%s)" % str(main.target.get("label", "")))
	# --- a merchant's stall: the merchant away, the stall's goods are not offered as a trade
	var m: NPC = merchants[0]
	var sd := BusinessDesks.by_id(w, str(m.workplace))
	var s: Dictionary = w.stalls[str(m.workplace)]
	w.player.pos = w.business.use_cell(s)
	main.player_sprite.dir = 4
	t = _target_desk(w)
	check(not t.is_empty() and str(t.desk.id) == str(sd.id) and str(t.options[0].kind) != "shop", "a merchant's stall with the merchant away is a desk with no trade (%s)" % str(t.get("status", "")))
	m.pos = w.shop_post(m)
	t = _target_desk(w)
	check((not t.is_empty() and str(t.options[0].kind) == "shop") or str(main.target.get("kind", "")) == "shop", "with the merchant at it, trade (%s)" % str(main.target.get("label", "")))
	# --- the player's own pitch: manage it; open a courier booth there when the village has a courier
	w.player.coins = 300
	var free: Array = w.business.sorted_ids().filter(func(id): return w.business.is_free_pitch(w.stalls[id]))
	var vb: Dictionary = w.couriers.booth_of(SettlementFacts.VILLAGE) if w.couriers != null else {}
	var pick := str(free.filter(func(id): return vb.is_empty() or str(vb.stall) != str(id))[0])     # a pitch with no courier booth at it
	check(w.business.rent(w.stalls[pick]) == "", "the player rents a pitch")
	w.player.pos = w.business.use_cell(w.stalls[pick])
	main.player_sprite.dir = 4
	t = _target_desk(w)
	check(not t.is_empty() and str(t.desk.id) == pick and str(t.status) == "Your own business." and str(t.options[0].kind) == "stall", "your own pitch is your desk: manage it")
	check(vb.is_empty() or t.options.any(func(o): return str(o.kind) == "courier_shop_booth"), "and it offers opening a courier booth there")
	# a guest's own pitch is the guest's desk (actor-aware)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Fairlight"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "ab".repeat(32)
	w.add_guest(g)
	g.coins = 200
	var gpick := str(w.business.sorted_ids().filter(func(id): return w.business.is_free_pitch(w.stalls[id]))[0])
	check(w.business.rent(w.stalls[gpick], g) == "", "a guest rents a pitch")
	var gd := BusinessDesks.of_business(w, w.player_ref(g))
	check(str(gd.get("id", "")) == gpick, "the guest's desk is the guest's own pitch, not the host's")
	var mine_for_guest: bool = w.as_actor(g, func(): return main._desk_is_mine(gd))
	var mine_for_host: bool = main._desk_is_mine(gd)
	check(mine_for_guest and not mine_for_host, "it is the guest's own desk for the guest, not for the host")
	# --- saves: nothing new is saved; a Build 21 save (22) and the Build 20 save (21) load with their desks
	var d22: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	check(int(d22.save_version) == World.SAVE_VERSION, "the desks add no save version of their own (the current version, %d)" % World.SAVE_VERSION)   # Build 22: 23 since MP-PLAYER-FAMILY
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d22)
	check(w2.load_error == "" and BusinessDesks.all(w2).size() == BusinessDesks.all(w).size(), "a save 22 loads with the same desks (%d)" % BusinessDesks.all(w2).size())
	w2.dispose()
	var d21: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/b20_save_v21_single.json"))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d21)
	check(w3.load_error == "" and BusinessDesks.all(w3).map(func(d): return str(d.id)).has(arm), "the Build 20 save (21) loads and has the smithy's desk")
	w3.dispose()
	print("\ndesk_test: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	quit(1 if failures > 0 else 0)
