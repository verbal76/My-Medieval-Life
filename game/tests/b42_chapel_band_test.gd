extends SceneTree
## B42-Q-BAND-CHAPEL-RELIEF (owner 2026-11-14: "Exclude band (Recommended): the chapel no longer gives parcels to the outlaw band,
## matching 'fend for themselves, as outlaws'"; ND-23 excluded the band from the manor's relief, 2026-11-12). The chapel's
## emergency round (Chapel.relief_round) and its food alms (Chapel.food_alms) set food aside in parcels for every short
## household, the outlaw band's too, and its carriers took them to the camp beyond the village: the chain 12 campaign's main
## way out for villagers who then starved there (B42-NAV). Checked: with the band's household and a village household both
## emptied of food and cash and the chapel's store full, neither round sets a parcel aside for the band, and the village
## household still gets one.
##   godot --headless --path game --script res://tests/b42_chapel_band_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func empty(w: World, h: int) -> void:
	(w.households[h].pantry as Inventory).items.clear()
	for o: NPC in w.brain._members(h):
		o.inv.items.clear()
		w.treasury += o.coins
		o.coins = 0


func parcels_for(c: Chapel, h: int) -> int:
	return c.parcels.filter(func(p: Dictionary) -> bool: return int(p.hh) == h).size()


func _init() -> void:
	GameData.ensure()
	for round in ["relief_round", "food_alms"]:
		var w := World.new()
		w.setup(VillageMap.load_default(), 2)
		var c: Chapel = w.chapel
		var band: int = w.wilds.band_household() if w.wilds != null else -1
		var village := -1
		for h in range(3, w.households.size()):
			var ms: Array = w.brain._members(h)
			if h != band and not w.households[h].get("band", false) and not ms.is_empty() and not ms.any(func(o): return Chapel.is_clergy(o)) \
					and ms.any(func(o): return o.role == "adult"):
				village = h
				break
		check(c != null and c.present and band >= 0 and not w.brain._members(band).is_empty() and village >= 0,
			"%s fixture: seed 2 has the chapel, the outlaw band's household (%d) and a village household (%d)" % [round, band, village])
		if c == null or band < 0 or village < 0:
			continue
		empty(w, band)
		empty(w, village)
		c.parcels.clear()
		c.store.add("wheat", 400)
		check(c.projected_days(band) < float(GameData.b("relief_trigger_days")), "%s fixture: the band's household is short of food (%.2f days)" % [round, c.projected_days(band)])
		if round == "relief_round":
			c.relief_round()
		else:
			c.food_alms()
		check(parcels_for(c, band) == 0, "%s: no chapel parcel for the outlaw band (%d)" % [round, parcels_for(c, band)])
		check(parcels_for(c, village) > 0, "%s: a hungry village household still gets one (%d)" % [round, parcels_for(c, village)])
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
