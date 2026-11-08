extends SceneTree
## PROP-06 — sale proceeds for owned land; lease surrender conveys site
## and delivered materials to manor; no involuntary owned-property forfeiture.
var checks := 0
var fails := 0
func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8906)
	var h := 3
	var people: Array = w.brain._members(h)
	check(not people.is_empty(), "PROP-06: living family exists")
	var ref := World.hh_ref(h)
	# Isolate the owned-sale accounting from the household\'s existing rent bills.
	for r in w.property._all_things():
		if w.tenant_of(r) == ref:
			w.set_tenant(r, "")
		if w.owner_of(r) == ref:
			w.set_owner(r, World.MANOR)
	var land: Dictionary = w.plots[0]
	w.set_owner(land, ref)
	w.set_tenant(land, "")
	var price: int = w.property.sale_value(land)
	var head: NPC = w.party(ref)
	var before: int = head.coins
	w.treasury = maxi(w.treasury, price + 3000)
	var treasury: int = w.treasury
	check(Migration._settle_departure_property(w,people),"PROP-06: leaving family can sell owned land")
	check(w.owner_of(land) == World.MANOR,"PROP-06: sold parcel returns to manor ownership")
	check(head.coins == before + price and w.treasury == treasury - price,"PROP-06: actual sale proceeds go to migrating family's purse")
	# If the manor cannot pay, the family must retain title and remain.
	w.set_owner(land,ref)
	w.treasury = maxi(0, price - 1)
	check(not Migration._settle_departure_property(w,people),"PROP-06: no treasury funds means depart cannot forcibly seize title")
	check(w.owner_of(land) == ref,"PROP-06: unpaid property stays owned by the household")
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 8907)
	var h2 := 3
	var ref2 := World.hh_ref(h2)
	var parcel: Dictionary = w2.plots[0]
	w2.set_owner(parcel, World.MANOR)
	w2.set_tenant(parcel, ref2)
	parcel.site = {"owner": ref2, "kind": "house", "done": false, "cost": {"log": 5}, "need": {"log": 2}}
	var granary: int = w2.granary.count("log")
	check(Migration._settle_departure_property(w2,w2.brain._members(h2)),"PROP-06: leaving family can surrender leased parcel")
	check(w2.tenant_of(parcel) == "","PROP-06: surrendered lease has no old tenant")
	check(parcel.site.is_empty(),"PROP-06: unfinished lease site cleared for reallocation")
	check(w2.granary.count("log") == granary + 3,"PROP-06: delivered logs left on leased site go to manor")
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails>0 else 0)
