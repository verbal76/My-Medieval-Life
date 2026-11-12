extends SceneTree
## INV-02 probe (NOT committed): food units in every holder at checkpoints, including holders Decay.dawn does not reach.
##   godot --headless --path game -s tests/_inv02_probe.gd -- --days 60 --seed 1 --every 10 [--on]
const STEP := 0.5
var FOODS: Array = []


func _food(d: Dictionary) -> int:
	var n := 0
	for id in d:
		if FOODS.has(str(id)):
			n += int(d[id])
	return n


func _inv(inv: Inventory) -> int:
	return _food(inv.items) if inv != null else 0


func _line(w: World) -> Dictionary:
	var out := {"day": w.day()}
	var g := SettlementHoldings.holders(w)
	for k in g:
		out["census." + str(k)] = _food(g[k])
	var st := 0
	var barrels := 0
	var kinds := {}
	for c in w.containers:
		kinds[str(c.id)] = str(c.kind)
	for k in w.chests.stash:
		st += _inv(w.chests.stash[k])
		if kinds.get(str(k), "") == "barrel":
			barrels += _inv(w.chests.stash[k])
	out["x.stash"] = st
	out["x.stash_barrels"] = barrels
	out["x.stash_units"] = w.chests.stash.size()
	var hs := 0
	var hn := 0
	if w.homesteads != null:
		for c in w.homesteads.claims:
			hs += _inv(c.store)
			hn += 1
	out["x.homestead_stores"] = hs
	out["x.homestead_claims"] = hn
	var tr := 0
	for id in w.fauna.pens:
		tr += int(w.fauna.pens[id].trough)
	out["x.troughs_wheat"] = tr
	var bs := 0
	var cg := 0
	if w.couriers != null:
		for b in w.couriers.booths:
			bs += _inv(b.store)
		for j in w.couriers.jobs:
			if str(j.state) in ["in_transit", "returning"]:
				cg += _food(j.cargo)
	out["x.booth_stores"] = bs
	out["x.courier_cargo"] = cg
	var om_p := 0
	var om_b := 0
	var om_g := 0
	var om_t := 0
	if w.regions != null:
		for s: OffMapSettlement in w.regions.list:
			for h in s.hh:
				om_p += _food(h.pantry)
			for t in s.biz:
				om_b += _food(s.biz[t].stock)
			for o in s.own:
				om_b += _food(s.own[o].stock)
			om_g += _food(s.gov.granary)
			for t in s.trips:
				om_t += _food(t.pack)
	out["offmap.pantries"] = om_p
	out["offmap.business_stock"] = om_b
	out["offmap.granaries"] = om_g
	out["offmap.trips"] = om_t
	var sp := {}
	for k in w.stats:
		var ks := str(k)
		if ks.begins_with("decay_") or ks.begins_with("inv02_spoiled_") or ks == "spoiled_total":
			sp[ks] = int(w.stats[k])
	out["spoil"] = sp
	var eaten := 0
	for k in w.stats:
		if str(k).begins_with("eaten_"):
			eaten += int(w.stats[k])
	out["eaten_units"] = eaten
	return out


func _init() -> void:
	GameData.ensure()
	var args := OS.get_cmdline_user_args()
	var arg := func(n: String, d: String) -> String:
		var i := args.find(n)
		return args[i + 1] if i >= 0 and i + 1 < args.size() else d
	var days := int(arg.call("--days", "60"))
	var seed := int(arg.call("--seed", "1"))
	var every := int(arg.call("--every", "10"))
	FOODS = NPCBrain.EDIBLE.duplicate()
	for id in Decay.cfg().spoil:
		if not FOODS.has(str(id)):
			FOODS.append(str(id))
	if "--on" in args:
		Decay.storage_on = true
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	print("INV02 " + JSON.stringify(_line(w)))
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for d in days:
		for i in per_day:
			w.update(STEP)
			w.player.hunger = 100.0
		if (d + 1) % every == 0 or d + 1 == days:
			print("INV02 " + JSON.stringify(_line(w)))
	w.dispose()
	quit(0)
