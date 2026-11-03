extends SceneTree
## REGION-NAV-01 S7, regional demand and the founding measurement (plan AD-7: regional demand reaches business founding only through
## real work; the 35 % gate unchanged). Acceptance (plan, S7): busy share before and after; foundings with cause. Also the
## first-tool (P2) and retiree-stock (P3) findings, measured only. Pure World. Run headless:
##   godot --headless --path game --script res://tests/region_demand_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _run(w: World, minutes: float) -> void:
	var until := w.minutes + minutes
	while w.minutes < until:
		w.update(0.5)


func _crafter(w: World) -> NPC:
	for job in ["smith", "carpenter", "tanner", "stonecutter"]:
		for n: NPC in w.npcs:
			if n.alive and n.role == "adult" and n.job == job:
				return n
	return null


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 2.0 * 1440.0 + 7.0 * 60.0
	return w


func _init() -> void:
	# a crafter hears of a place wanting what their workshop makes
	var w := _world()
	var n := _crafter(w)
	check(n != null, "the village has a crafting trade (%s, the %s)" % [n.name if n else "-", n.job if n else "-"])
	var products := Intel.trade_products(n.job)
	check(not products.is_empty() and Intel.interests(w, n).get(products[0], "") == "makes", "news of a place wanting one of the %s's products (%d products) concerns them" % [n.job, products.size()])
	# a recipe they can make, whose product a place is told to want at a good price, ranks first in what they choose to make
	var recipes := []
	for r in GameData.recipes:
		var rec: Dictionary = GameData.recipes[r]
		if NPCBrain.TRADE_STATIONS.get(n.job, []).has(str(rec.get("station", ""))) and w.brain._can_make(n, r):
			recipes.append(r)
	recipes.sort()
	check(recipes.size() >= 2, "the %s can make several things (%d)" % [n.job, recipes.size()])
	var last: String = w.brain.by_return(n, recipes)[recipes.size() - 1]
	var prod: String = (GameData.recipes[last].out as Dictionary).keys()[0]
	n.intel = [{"about": "region:higham/smithy", "person": "Someone", "role": "keeper", "place": "higham", "item": prod, "side": "want", "qty": 6, "price": 500,
		"kind": "confirmed", "told_by": "npc:0", "collected_day": w.day(), "heard_day": w.day()}]
	check(w.brain.by_return(n, recipes)[0] == last, "told that Higham will pay well for %s, the %s now ranks that recipe (%s) first, where it was last: regional demand becomes station work" % [prod, n.job, last])
	n.intel[0].collected_day = w.day() - 60
	check(w.brain.by_return(n, recipes)[0] != last or recipes.size() == 1, "stale news no longer moves them")
	n.intel.clear()
	# busy share before and after: measured for every crafting trade, the gate beside it
	var before := RegionTrade.measure(w)
	check((before.busy as Dictionary).has(n.job) and float(before.gate) > 0.0, "the busy share of each crafting trade is measured (%s %.3f), with the founding gate (%.2f)" % [n.job, float(before.busy.get(n.job, -1.0)), float(before.gate)])
	_run(w, 1440.0)
	var after := RegionTrade.measure(w)
	check(int(after.day) == int(before.day) + 1 and (after.busy as Dictionary).has(n.job), "and again a day later (%s %.3f -> %.3f): before and after are read the same way" % [n.job, float(before.busy.get(n.job, 0.0)), float(after.busy.get(n.job, 0.0))])
	# foundings with their cause
	var b := Envoys.book(w)
	b.exports = {n.job: w.day()}
	RegionTrade.note_founding(w, n)
	var other: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job != "" and o.job != n.job:
			other = o
			break
	RegionTrade.note_founding(w, other)
	var m := RegionTrade.measure(w)
	check(int(m.foundings.regional) == 1 and int(m.foundings.local) == 1, "a founding in a trade that recently sent goods to a neighbour counts as regional, another as local (%s)" % str(m.foundings))
	# P2 and P3, measured only
	var elder: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "elder":
			elder = o
			break
	var p3 := int(m.p3_idle_stock)
	if elder != null:
		elder.inv.add("iron_ore", 5)
		check(int(RegionTrade.measure(w).p3_idle_stock) == p3 + 5, "trade stock held by an elder is counted in the retiree-stock measure (P3: %d, working holders %d)" % [p3 + 5, int(m.p3_working_stock)])
	check(int(m.p2_jobless_no_tool) >= 0, "the first-tool measure is read (P2: %d jobless adults without coins or a tool while a tool trade has a place)" % int(m.p2_jobless_no_tool))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check((Envoys.book(w2).get("exports", {}) as Dictionary).has(n.job), "the record of each trade's last export is saved")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
