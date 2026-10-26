extends SceneTree
## GP-MARKET-SPACING (owner, 2026-10-26: "The booths are too close together. Space them farther apart"; generator v16): the
## market's stalls, drawn as the 53 x 43 px Craftpix shelf, stand apart, each reads as its own stall and can be reached and walked
## between:
##   * no two shelves' drawings overlap; side by side there is open ground between them (at least a tile) and three walkable
##     cells between their footprints; a row's customers have a clear lane before the shelves of the row behind;
##   * every stall's use cell is walkable and reached from the village square; no stall stands in a building, on a road, a tree,
##     a plant, a container or another station;
##   * ids, kinds, the merchants' stalls, the tailor's and barber's pitches and the open pitches are as before;
##   * a built stall keeps the same spacing (Stalls.SPACING);
##   * a save made before (the Build 20 save, and a Build 21 save 22 with the old places) has its market moved, every tenant,
##     stock, price and till kept, a courier booth at a stall following it, collision where the stalls now stand.
##   godot --headless --path game --script res://tests/market_spacing_test.gd

var checks := 0
var failures := 0
const OLD := {"stall0": Vector2i(36, 63), "stall1": Vector2i(40, 63), "stall2": Vector2i(44, 63), "stall3": Vector2i(48, 63),
	"stall4": Vector2i(52, 63), "stall5": Vector2i(56, 63), "pitch0": Vector2i(42, 61), "pitch1": Vector2i(50, 61),
	"pitch2": Vector2i(46, 61), "pitch3": Vector2i(54, 61)}       # Build 21's places (generator v15, Business.PITCHES)


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


## A shelf's drawing in pixels (StallShelf: centred on the footprint's bottom edge, DROP below it).
func _art(s: Dictionary) -> Rect2:
	var mid := Vector2((int(s.x) + 1) * 16, (int(s.y) + 1) * 16)
	return Rect2(mid + Vector2(-StallShelf.HALF_W, -StallShelf.H + StallShelf.DROP), Vector2(StallShelf.W, StallShelf.H))


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var ids: Array = w.stalls.keys()
	ids.sort()
	check(ids == ["pitch0", "pitch1", "pitch2", "pitch3", "stall0", "stall1", "stall2", "stall3", "stall4", "stall5"], "the same ten market stalls by id (%s)" % str(ids))
	check(str(w.stalls.pitch2.service) == "tailor" and str(w.stalls.pitch3.service) == "barber" and str(w.stalls.pitch0.service) == "" and str(w.stalls.pitch1.service) == "", "the tailor's and the barber's pitches and the two open pitches as before")
	check(["raw", "food", "goods", "raw", "food", "goods"] == range(6).map(func(i): return str(w.stalls["stall%d" % i].kind)), "the merchants' stalls keep their kinds")
	# the drawings never overlap; side by side, open ground between them
	var overlap := []
	var tight := []
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Dictionary = w.stalls[ids[i]]
			var b: Dictionary = w.stalls[ids[j]]
			if _art(a).intersects(_art(b)):
				overlap.append("%s/%s" % [ids[i], ids[j]])
			if int(a.y) == int(b.y) and absi(int(a.x) - int(b.x)) < Stalls.SPACING.x:
				tight.append("%s/%s" % [ids[i], ids[j]])
	check(overlap.is_empty(), "no two shelves' drawings overlap (%s)" % str(overlap))
	check(tight.is_empty(), "side by side they are at least %d tiles apart (%s)" % [Stalls.SPACING.x, str(tight)])
	var gap_px := 9999.0
	var lane_px := 9999.0
	for i in ids.size():
		for j in ids.size():
			var a: Dictionary = w.stalls[ids[i]]
			var b: Dictionary = w.stalls[ids[j]]
			if i != j and int(a.y) == int(b.y) and int(b.x) > int(a.x):
				gap_px = minf(gap_px, _art(b).position.x - _art(a).end.x)
			if int(b.y) > int(a.y) and absi(int(a.x) - int(b.x)) < 3:
				lane_px = minf(lane_px, _art(b).position.y - float((int(a.use[1]) + 1) * 16))
	check(gap_px >= 16.0, "at least a tile of open ground between neighbouring shelves (%d px)" % int(gap_px))
	check(lane_px >= 16.0, "a clear lane of at least a tile between a row's customers and the shelves behind them (%d px)" % int(lane_px))
	# walkable: between neighbours, every use cell reached from the square; nothing stands on anything else
	var hub := Vector2i(w.map.data.spawns.player[0], w.map.data.spawns.player[1])
	var reach_ok := true
	var free_ok := true
	var between_ok := true
	var why := []
	for id in ids:
		var s: Dictionary = w.stalls[id]
		var use := Vector2i(int(s.use[0]), int(s.use[1]))
		if w.map.is_solid(use) or w.map.find_path(hub, use).is_empty():
			reach_ok = false
			why.append(id)
		for c in [Vector2i(int(s.x), int(s.y)), Vector2i(int(s.x) + 1, int(s.y)), use]:
			if w.place_of(Vector2(c) + Vector2(0.5, 0.5)) != "" or not w.tree_at(c).is_empty() or not w.plant_at(c).is_empty():
				free_ok = false
			for r in w.map.data.road:
				if Vector2i(int(r[0]), int(r[1])) == c:
					free_ok = false
		var right := Vector2i(int(s.x) + 2, int(s.y))
		var walk := 0
		for k in 3:
			if not w.map.is_solid(right + Vector2i(k, 0)):
				walk += 1
		var has_right := ids.any(func(o): return int(w.stalls[o].y) == int(s.y) and int(w.stalls[o].x) == int(s.x) + Stalls.SPACING.x)
		between_ok = between_ok and (not has_right or walk == 3)
	check(reach_ok, "every stall's customer cell is walkable and reached from the village square (%s)" % str(why))
	check(free_ok, "no stall or customer cell in a building, on a road, a tree or a plant")
	check(between_ok, "three walkable cells between neighbouring stalls in a row")
	var stall_cells_solid := ids.all(func(id): return w.map.is_solid(Vector2i(int(w.stalls[id].x), int(w.stalls[id].y))) and w.map.is_solid(Vector2i(int(w.stalls[id].x) + 1, int(w.stalls[id].y))))
	check(stall_cells_solid, "every stall's two cells are solid (collision where it is drawn)")
	var crates_ok := true
	for i in 6:
		var s: Dictionary = w.stalls["stall%d" % i]
		crates_ok = crates_ok and w.containers.any(func(c): return str(c.get("at", "")) == "stall%d" % i and int(c.x) == int(s.x) + 1 and int(c.y) == int(s.y))
	check(crates_ok, "each merchant's crate or barrel moved with its stall (its container)")
	# a built stall keeps the market's spacing
	var biz: Business = w.business
	var probe := Vector2i(int(w.stalls.stall2.x), int(w.stalls.stall2.y) + 4)
	check(biz.stalls.site_refusal(probe, "player").contains("too close"), "a stall built 4 rows in front of another is refused (%s)" % biz.stalls.site_refusal(probe, "player"))
	var ok_site := Vector2i(int(w.stalls.stall2.x), int(w.stalls.stall2.y) + 5)
	print("note: 5 rows in front: '%s'" % biz.stalls.site_refusal(ok_site, "player"))
	var site := biz.stalls.find_site("player")
	var far_enough := site.x >= 0 and ids.all(func(id): return absi(site.x - int(w.stalls[id].x)) >= Stalls.SPACING.x or absi(site.y - int(w.stalls[id].y)) >= Stalls.SPACING.y)
	check(far_enough, "a site for a built stall keeps the spacing from every stall (%s)" % str(site))
	# --- an older save: the market moves, everything it holds stays
	w.couriers.daily()
	var vb := w.couriers.booth_of(SettlementFacts.VILLAGE)
	w.player.coins = 300
	check(biz.rent(w.stalls.pitch1) == "", "the player rents pitch1")
	w.player.inv.add("plank", 4)
	check(biz.list_item(w.stalls.pitch1, "plank", 4) == "" and biz.set_price(w.stalls.pitch1, "plank", 3) == "", "and puts up planks at 3 coins")
	w.stalls.pitch1.till = 5
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	for id in OLD:                                         # as Build 21 saved them
		d.stalls[id].x = OLD[id].x
		d.stalls[id].y = OLD[id].y
		d.stalls[id].use = [OLD[id].x, OLD[id].y + 1]
	var vb_stall := str(vb.get("stall", ""))
	if vb_stall != "" and OLD.has(vb_stall):
		for b in d.couriers.booths:
			if str(b.id) == str(vb.id):
				b.x = OLD[vb_stall].x
				b.y = OLD[vb_stall].y
	var tenants := {}
	for id in ids:
		tenants[id] = w.tenant_of(w.stalls[id])
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var moved := ids.all(func(id): return int(w2.stalls[id].x) == int(w.stalls[id].x) and int(w2.stalls[id].y) == int(w.stalls[id].y) and int(w2.stalls[id].use[1]) == int(w.stalls[id].y) + 1)
	check(w2.load_error == "" and moved, "a save with the old market loads with every stall at its new place")
	check(ids.all(func(id): return w2.tenant_of(w2.stalls[id]) == tenants[id]), "every tenant kept (merchants, tailor, barber, the player)")
	var p1: Dictionary = w2.stalls.pitch1
	check(int(p1.stock.plank) == 4 and w2.business.price_of(p1, "plank") == 3 and int(p1.till) == 5, "the player's pitch keeps its stock, price and till")
	check(ids.all(func(id): return w2.map.is_solid(Vector2i(int(w2.stalls[id].x), int(w2.stalls[id].y)))), "collision where the stalls now stand")
	var vb2 := w2.couriers.booth_of(SettlementFacts.VILLAGE)
	check(vb_stall == "" or (int(vb2.x) == int(w2.stalls[vb_stall].x) and int(vb2.y) == int(w2.stalls[vb_stall].y)), "the village's courier booth follows its stall (%s)" % vb_stall)
	var m: NPC = w2.npcs.filter(func(n): return n.alive and n.job == "merchant")[0]
	check(w2.stalls.has(m.workplace) and w2.tenant_of(w2.stalls[m.workplace]) == World.npc_ref(m.id), "a merchant still keeps its stall by id")
	w2.dispose()
	# the Build 20 save (save 21, the old market) loads the same way
	var d21: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/b20_save_v21_single.json"))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d21)
	check(w3.load_error == "" and ["stall0", "stall5", "pitch0", "pitch3"].all(func(id): return int(w3.stalls[id].x) == int(w.stalls[id].x) and int(w3.stalls[id].y) == int(w.stalls[id].y)), "the Build 20 save loads with its market at the new places")
	w3.dispose()
	w.dispose()
	print("\nmarket_spacing_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
