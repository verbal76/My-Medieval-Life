extends SceneTree
## INV-02 PROTOTYPE (B25-INV02-SPOIL-D1; docs/design/INV02_SPOILAGE_PROPOSAL.md; not approved, off by default): with
## Decay.storage_on the holders today's rule does not reach (a player's stash, a homestead chest, a pen's trough) spoil,
## each storage class scales the item's base rate, every unit lost is counted as spoiled_<item> (the goods census and the
## ledger agree), two worlds of the same seed spoil alike, and with the prototype off nothing of this happens.
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func census(w: World, id: String) -> int:
	return int(SettlementHoldings.goods(w).get(id, 0))


func fixture(on: bool) -> World:
	Decay.storage_on = on
	var w := World.new()
	w.setup(VillageMap.load_default(), 4242)
	w.chests.stash["inv02_chest"] = Inventory.new()
	w.chests.stash["inv02_chest"].add("milk", 400)
	var barrel := ""
	for c in w.containers:
		if str(c.kind) == "barrel":
			barrel = str(c.id)
			break
	if barrel != "":
		w.chests.stash[barrel] = Inventory.new()
		w.chests.stash[barrel].add("milk", 400)
	if w.homesteads != null and not w.homesteads.claims.is_empty():
		(w.homesteads.claims[0].store as Inventory).add("milk", 400)
	return w


func _init() -> void:
	GameData.ensure()
	var off := fixture(false)
	var m0 := int(off.chests.stash["inv02_chest"].count("milk"))
	for i in 5:
		Decay.dawn(off)
	check(int(off.chests.stash["inv02_chest"].count("milk")) == m0, "prototype off: a stash does not spoil (today's rule)")
	var w := fixture(true)
	var w2 := fixture(true)
	var barrel := ""
	for c in w.containers:
		if str(c.kind) == "barrel":
			barrel = str(c.id)
			break
	check(barrel != "", "fixture: the village has a barrel")
	var g0 := census(w, "milk")
	var s0 := float(w.stats.get("spoiled_milk", 0.0))
	for i in 10:
		Decay.dawn(w)
		Decay.dawn(w2)
	var chest_left := int(w.chests.stash["inv02_chest"].count("milk"))
	var barrel_left := int(w.chests.stash[barrel].count("milk")) if barrel != "" else 0
	check(chest_left < 400, "on: milk in a chest at home spoils (%d of 400 left)" % chest_left)
	check(barrel_left > chest_left, "on: milk in a barrel (cellar) keeps better than in a chest (%d vs %d)" % [barrel_left, chest_left])
	if not w.homesteads.claims.is_empty():
		check(int((w.homesteads.claims[0].store as Inventory).count("milk")) < 400, "on: a homestead chest spoils")
	var lost := g0 - census(w, "milk")
	var counted := int(float(w.stats.get("spoiled_milk", 0.0)) - s0)
	check(lost > 0 and lost == counted, "every unit lost is counted as spoiled_milk (%d lost, %d counted)" % [lost, counted])
	check(SettlementHoldings.goods(w) == SettlementHoldings.goods(w2), "two worlds of the same seed spoil exactly alike")
	Decay.storage_on = false
	off.dispose()
	w.dispose()
	w2.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
