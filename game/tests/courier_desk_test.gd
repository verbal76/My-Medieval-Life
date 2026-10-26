extends SceneTree
## GP-BUSINESS-COURIER (owner, 2026-10-24: "... Or speak to a courier. Just make that the business desk, like in all businesses."),
## in the real game scene: a business's courier booth stands at its desk, never on a work station; the courier is reached from the
## desk's menu (not as a separate booth prompt at the same place), and choosing it opens the ordinary courier window for that booth;
## goods a business sends leave from the booth at its desk and the payment collected comes back to that booth, where the owner takes
## it, coins and goods conserved; a player's own desk (a storefront) opens a booth there; a booth an older save put at a smith's
## forge (Build 21) is seated at the desk on load, nothing it holds changed; a merchant's booth stays at the merchant's stall.
##   godot --headless --path game --script res://tests/courier_desk_test.gd

const ITEM := "copper_ring"           # a made good no villager's day touches in these few days
const Census := preload("res://tests/census.gd")

var main
var checks := 0
var failures := 0


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
	main.save_path = "user://test_saves/courier_desk_test/save1.json"
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


func coin_gap(x: World) -> int:
	return x.total_coins() + x.regions.coins() - (x.coin_sources + x.regions.net_paid_by_village())


func item_gap(x: World) -> int:
	var made := 0
	for k in ["made_", "mined_", "felled_", "dug_", "cut_", "farm_harvest_"]:
		made += int(x.stats.get(k + ITEM, 0))
	var used := 0
	for k in ["eaten_", "used_", "used_building_", "used_works_", "used_repairs_", "burned_", "broke_", "spoiled_"]:
		used += int(x.stats.get(k + ITEM, 0))
	return int(Census.goods(x).get(ITEM, 0)) + int(x.stats.get("exported_" + ITEM, 0)) - int(x.stats.get("imported_" + ITEM, 0)) - made + used


func run_days(x: World, days: float) -> void:
	var dt := 10.0 / float(GameData.b("game_minutes_per_second"))
	for i in int(days * 144.0):
		x.player.hp = x.player.max_hp
		x.player.hunger = 100.0
		x.update(dt)


## Stand on the desk's keeper cell facing the desk (World.station_in_reach) and find what is offered.
func _at_desk(w: World, d: Dictionary) -> Dictionary:
	w.player.pos = Vector2(d.use) + Vector2(0.5, 0.5)
	var step: Vector2i = (d.at as Vector2i) - (d.use as Vector2i)
	main.player_sprite.dir = {Vector2i(0, 1): 0, Vector2i(1, 0): 2, Vector2i(0, -1): 4, Vector2i(-1, 0): 6}.get(step, 0)
	main._find_target()
	return main.target if str(main.target.get("kind", "")) == "desk" else {}


func _run() -> void:
	main.new_game()
	var w: World = main.world
	var cs: CourierService = w.couriers
	cs.daily()
	var vb := cs.booth_of(SettlementFacts.VILLAGE)
	check(not vb.is_empty(), "the village has its courier booth")
	# --- a smith's booth stands at the smithy's desk, not at the forge
	var smith: NPC = w.npcs.filter(func(n): return n.alive and n.job == "smith")[0]
	var sref := World.npc_ref(smith.id)
	var desk := BusinessDesks.of_business(w, sref)
	check(str(desk.get("kind", "")) == "counter" and str(w.stations[str(desk.id)].type) == "armory_counter", "the smith's business desk is the smithy's ledger table")
	check(cs.is_business(sref) and cs.open_shop_booth(sref) == "", "the smith opens a courier booth for the business")
	var sb := cs.booth_of_keeper(sref)
	check(Vector2i(int(sb.x), int(sb.y)) == desk.at, "it stands at the desk (%d, %d)" % [int(sb.x), int(sb.y)])
	var forge: String = w.stations_of("forge")[0]
	check(Vector2i(int(sb.x), int(sb.y)) != w.station_use(forge) and Vector2i(int(sb.x), int(sb.y)) != Vector2i(int(w.stations[forge].at[0]), int(w.stations[forge].at[1])), "never on a work station (the forge)")
	check(str(cs.location(sref, "business").what).begins_with("the desk of"), "a delivery to the smith's business is addressed to its desk (%s)" % str(cs.location(sref, "business").what))
	# --- the desk's menu offers the courier; the booth has no separate prompt there
	var t := _at_desk(w, desk)
	check(not t.is_empty() and t.options.any(func(o): return str(o.kind) == "courier_booth" and str(o.booth) == str(sb.id)), "the desk's menu offers the courier (%s)" % str(main.target.get("label", "")))
	check(str(t.get("label", "")).ends_with("or the courier"), "and its prompt says so")
	check(not main.target_options.any(func(o): return str(o.get("kind", "")) == "courier_booth"), "no separate courier-booth prompt at the desk")
	main.ui.show_desk(t)
	var cbtn := _named("Desk_courier_booth")
	check(cbtn != null, "the menu has a courier button")
	if cbtn != null:
		cbtn.pressed.emit()
	check(main.courier_window != null and str(main.courier_window.booth_id) == str(sb.id), "choosing it opens the courier window for the smithy's booth")
	main.ui.hide_all()
	# --- the business sends goods from the booth at its desk; the payment comes back to that booth
	var wul: OffMapSettlement = w.regions.by_id["wulstead"]
	w.note_settlement_trade(smith, wul)
	smith.inv.add(ITEM, 5)
	smith.coins = 100
	var rts := cs.routes.filter(func(r): return str(r.from) == str(sb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead")
	check(not rts.is_empty(), "the smithy's booth has a route to Wulstead")
	var gap0 := coin_gap(w)
	var item0 := item_gap(w)
	var job: Dictionary = cs.book_route({"sender": sref, "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead",
		"items": {ITEM: 5}, "route": rts[0].id, "collect": {"kind": "coins", "amount": 7}, "proceeds": "deposit"}) if not rts.is_empty() else {"error": "no route"}
	check(not job.has("error") and (sb.store as Inventory).count(ITEM) == 5 and smith.inv.count(ITEM) == 0, "the goods are handed over at the desk's booth (%s)" % str(job.get("error", "")))
	if not job.has("error"):
		run_days(w, float(rts[0].days) * 2.0 + 3.5)
		check(str(job.state) == "fulfilled", "delivered and home (%s, %s)" % [str(job.state), str(job.get("outcome", ""))])
		check(int(cs.waiting(str(sb.id), sref).get("coins", 0)) == 7, "the 7 coins collected wait at the booth at the smithy's desk")
		var c0 := smith.coins
		check(int(cs.withdraw(str(sb.id), sref).coins) == 7 and smith.coins == c0 + 7, "and the smith takes them there")
		check(coin_gap(w) == gap0 and item_gap(w) == item0, "coins and goods balance")
	# --- an older save (Build 21) had the smith's booth at the forge: on load it stands at the desk, nothing it holds changed
	sb.x = w.station_use(forge).x
	sb.y = w.station_use(forge).y
	(sb.store as Inventory).add("iron_bar", 2)
	var bars := (sb.store as Inventory).count("iron_bar")
	sb.coins = int(sb.coins) + 3
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var sb2 := w2.couriers.booth_of_keeper(sref)
	check(w2.load_error == "" and Vector2i(int(sb2.x), int(sb2.y)) == desk.at, "a booth saved at the forge is seated at the desk on load")
	check((sb2.store as Inventory).count("iron_bar") == bars and int(sb2.coins) == int(sb.coins) and w2.couriers.routes.size() == cs.routes.size(), "with its goods, coins and routes as saved (bars %d, coins %d/%d, routes %d/%d)" % [(sb2.store as Inventory).count("iron_bar"), int(sb2.coins), int(sb.coins), w2.couriers.routes.size(), cs.routes.size()])
	w2.dispose()
	# --- a merchant's booth stays at the merchant's stall (unchanged)
	var m: NPC = w.npcs.filter(func(n): return n.alive and n.job == "merchant")[0]
	var mref := World.npc_ref(m.id)
	check(cs.open_shop_booth(mref) == "", "a merchant opens a booth")
	var mb := cs.booth_of_keeper(mref)
	var ms: Dictionary = w.stalls[str(m.workplace)]
	check(Vector2i(int(mb.x), int(mb.y)) == Vector2i(int(ms.x), int(ms.y)) and str(mb.stall) == str(m.workplace), "at the merchant's own stall, as before")
	# --- the player's storefront is their desk: a booth is opened there, from the desk's menu
	var biz: Business = w.business
	var b := {}
	var ids: Array = w.buildings.keys()
	ids.sort()
	for id in ids:
		var x: Dictionary = w.buildings[id]
		if str(x.get("type", "")) == "house" and biz.front_place(x).size() > 0:
			b = x
			break
	var hh := w.household_in(str(b.id))
	if hh >= 0:
		for mm in w.households[hh].members:
			w.npc(int(mm)).alive = false
	w.set_owner(b, World.MANOR)
	w.set_tenant(b, "")
	w.player.coins = 500
	check(w.property.lease(b, World.PLAYER) == "", "the player leases a house")
	for id in Business.storefront_cost():
		w.player.inv.add(id, int(Business.storefront_cost()[id]))
	check(biz.build_storefront(b) == "" and b.has("front"), "and builds a storefront")
	var pd := BusinessDesks.of_business(w, World.PLAYER)
	check(str(pd.get("kind", "")) == "front" and str(pd.building) == str(b.id), "the storefront is the player's desk")
	var pt := _at_desk(w, pd)
	var front_ok := not pt.is_empty()
	if pt.is_empty():                                     # the player's own storefront is offered by the door (Main._find_target fronts)
		var desks: Array = main.target_options.filter(func(o): return str(o.get("kind", "")) == "desk")
		pt = desks[0] if not desks.is_empty() else {}
	check(not pt.is_empty() and pt.options.any(func(o): return str(o.kind) == "courier_shop_booth"), "its menu offers opening a courier booth there")
	if not pt.is_empty():
		main.ui.show_desk(pt)
		var ob := _named("Desk_courier_shop_booth")
		if ob != null:
			ob.pressed.emit()
	var pb := cs.booth_of_keeper(World.PLAYER)
	check(not pb.is_empty() and Vector2i(int(pb.x), int(pb.y)) == pd.at, "the player's booth stands at the storefront's desk (%s)" % main.ui.toast.text)
	print("note: storefront desk found by facing it: %s" % front_ok)
	print("\ncourier_desk_test: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	quit(1 if failures > 0 else 0)
