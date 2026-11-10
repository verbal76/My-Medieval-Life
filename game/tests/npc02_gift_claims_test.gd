extends SceneTree
## NPC-02 (Build 25 audit, docs/audits/2026-11-08_build25_master_audit_register.md): goods held for a contract (Living Economy
## claims, LE-03) may not leave by a path other than World.trade unless the claims allow it (World.claims_allow). A villager's
## gift (Relations.give, chosen through _spare_to_give) ignored them: a villager could give away goods already promised. Now a
## gift is chosen and given only from goods the claims let go.
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	c.market.drive = true
	EconomyFoundation.set_override(c)
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	for n: NPC in w.npcs:
		n.inv.remove("plank", n.inv.count("plank"))
	var car: NPC = null
	var lab: NPC = null
	var friend: NPC = null
	for n: NPC in w.npcs:
		if not n.alive or n.role != "adult" or n.household < 0:
			continue
		if n.job == "carpenter" and car == null:
			car = n
		elif n.job == "laborer" and lab == null:
			lab = n
		elif friend == null and n.job != "carpenter":
			friend = n
	check(car != null and lab != null and friend != null, "fixture: a carpenter, a buyer and someone to give to")
	car.inv.add("plank", 3)
	lab.coins = maxi(lab.coins, 3 * 4 + 400)
	var ct: Dictionary = w.contracts._new_record(World.npc_ref(lab.id), World.npc_ref(car.id), "plank", 3, 4, 5, [])
	check(w.contracts._open(ct), "fixture: all three planks are held for a contract")
	check(not w.claims_allow(car, "plank", 1), "fixture: the claims do not let a plank go")
	check(not w.relations._spare_to_give(car, "plank"), "a held plank is not chosen as a gift")
	var p0 := car.inv.count("plank")
	w.relations.give(car.id, friend, "plank", 1)
	check(car.inv.count("plank") == p0 and friend.inv.count("plank") == 0, "nor can it be given (carpenter %d, friend %d)" % [car.inv.count("plank"), friend.inv.count("plank")])
	car.inv.add("plank", 2)
	check(w.relations._spare_to_give(car, "plank"), "planks beyond the contract's three may be given")
	w.relations.give(car.id, friend, "plank", 1)
	check(friend.inv.count("plank") == 1 and car.inv.count("plank") == 4, "and one is (carpenter %d, friend %d)" % [car.inv.count("plank"), friend.inv.count("plank")])
	check(w.economy.claims.audit().is_empty(), "the contract's hold is intact (claims audit clean)")
	EconomyFoundation.set_override({})
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
