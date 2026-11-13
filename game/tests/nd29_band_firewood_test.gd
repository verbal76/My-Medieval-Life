extends SceneTree
## ND-29 (owner 2026-11-12, B25-ND29-BAND-CAMPFIRE, answer "fuel only for now"): the outlaw band's camp is fuelled through the
## villagers' own system: its household pantry's logs are burned at dawn (World), and a claim's market errand (Homesteads._errand)
## buys firewood when the pantry has none. Firewood is a necessity, so it is bought after the household's food and before the
## field's seed: it came after the seed, and the band spent its last coins on seed and went without a fire every night while
## sellers held logs (chain 12 gate eq_s1: the band's household cold 30 of 30 nights). No cold health effect exists for anyone.
##   godot --headless --path game --script res://tests/nd29_band_firewood_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var band: int = w.wilds.band_household() if w.wilds != null else -1
	check(band >= 0, "fixture: the outlaw band has a household (%d)" % band)
	if band < 0:
		finish()
		return
	var c: Dictionary = w.wilds.band_claim()
	var members: Array = w.brain._members(band)
	check(not c.is_empty() and not members.is_empty(), "fixture: the band's camp claim and its members")
	while w.hour() < 9.0:
		w.update(1.0)
	var n: NPC = members[0]
	var pantry: Inventory = w.households[band].pantry
	pantry.remove("log", pantry.count("log"))
	n.inv.remove("log", n.inv.count("log"))
	for f in ["wheat"]:
		pantry.add(f, 200)                         # food in hand: the food step has nothing to do
	n.hunger = 100.0
	n.coins = 40
	c.trade = "farmer"                             # a field's trade: the seed step would buy seed
	for id in pantry.items.keys():
		if str(id).ends_with("_seed"):
			pantry.remove(id, pantry.count(id))
	var seller = w.brain._seller_of("log", n)
	check(seller != null and w.brain.buy_qty(n, seller, "log", 2, true) > 0, "fixture: a seller holds logs the bandit can pay for")
	var trip := {"tried": {"tool": true, "meal": true}, "n": 0}
	var did: bool = w.homesteads._errand(n, c, trip)
	check(did and n.doing == "buying firewood", "with no log on the camp's hearth, the market errand buys firewood first (doing: %s)" % n.doing)
	# with logs on the hearth it does not buy firewood again
	pantry.add("log", 2)
	var trip2 := {"tried": {"tool": true, "meal": true}, "n": 0}
	w.homesteads._errand(n, c, trip2)
	check(n.doing != "buying firewood", "with logs on the hearth, no firewood is bought (doing: %s)" % n.doing)
	# the dawn burn: a log on the camp's hearth is burned and the band is not counted cold; none, and it is
	var before := int(w.stats.get("cold_hh_%d" % band, 0))
	pantry.remove("log", pantry.count("log"))
	pantry.add("log", 1)
	w.burn_firewood()
	check(int(w.stats.get("cold_hh_%d" % band, 0)) == before and pantry.count("log") == 0, "a lit camp fire burns its log and the band is not cold")
	w.burn_firewood()
	check(int(w.stats.get("cold_hh_%d" % band, 0)) == before + 1, "a camp with no log is cold that night")
	finish()


func finish() -> void:
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
