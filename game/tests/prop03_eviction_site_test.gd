extends SceneTree
## PROP-03 (owner decision 2026-11-08, docs/directives/2026-11-09_overnight_autonomous_development.md): a lease that ends by
## eviction (rent unpaid for rent_evict_missed weeks) passes the land, its improvements and the materials delivered to an
## unfinished site to the manor without compensation; the former tenant's site does not stay attached, so the manor can let or
## sell the parcel again.
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func goods(w: World, id: String) -> int:
	var n: int = w.granary.count(id) + int(w.site_goods().get(id, 0))
	for hh in w.households:
		n += (hh.pantry as Inventory).count(id)
	for o: NPC in w.npcs:
		n += o.inv.count(id)
	for l in w.loot:
		n += (l.inv as Inventory).count(id)
	return n


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8907)
	var h := 3
	var ref := World.hh_ref(h)
	for o: NPC in w.brain._members(h):
		o.coins = 0                                       # the tenant household cannot pay its rent
	var parcel: Dictionary = w.plots[0]
	w.set_owner(parcel, World.MANOR)
	w.set_tenant(parcel, ref, 5)
	parcel.site = {"owner": ref, "kind": "house", "done": false, "cost": {"log": 5}, "need": {"log": 2}}     # 3 logs delivered
	var g0 := w.granary.count("log")
	var logs0 := goods(w, "log")
	var c0 := w.total_coins()
	var weeks := int(GameData.b("rent_evict_missed"))
	for i in weeks:
		parcel.due_day = w.day()
		w.property.collect_rents()
	check(w.tenant_of(parcel) == "", "after %d unpaid weeks the manor took the lease back" % weeks)
	check((parcel.site as Dictionary).is_empty(), "the former tenant's unfinished site is not left on the parcel")
	check(w.granary.count("log") == g0 + 3, "the 3 logs delivered to it went to the manor, uncompensated")
	check(w.property.for_sale(parcel), "the manor can let or sell the parcel again")
	check(goods(w, "log") == logs0 and w.total_coins() == c0, "no goods or coins made or lost")
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
