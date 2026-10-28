extends SceneTree
## Temporary probe (not committed).

func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	cfg.enabled = true
	EconomyFoundation.set_override(cfg)
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var m := w.economy.market
	for n: NPC in w.npcs:
		n.inv.remove("plank", n.inv.count("plank"))
	var car: NPC = w.npc(82)
	var sm: NPC = w.npc(47)
	car.inv.add("plank", 7)
	sm.inv.add("plank", 7)
	var need := m.need_for(World.npc_ref(sm.id), "plank")
	print("need ", need)
	print("ceiling ", m.buyer_ceiling(sm, "plank", need), " cash ", m.cash_for(sm), " spendable ", w.spendable(sm), " coins ", sm.coins)
	var id := m.post_bid(sm, "plank", need)
	print("bid ", id, " ", w.economy.offers.get_offer(id), " stats ", m.stats)
	print("for_sale ", m.for_sale(car, "plank"), " floor ", m.seller_floor(car, "plank", 3, "npc:47"), " ask ", m.ask_price(car, "plank", 7))
	w.judgment.set_ledger(sm.id, car.id, 0, 40000)
	print("disp ", w.judgment.personal_disposition(sm.id, car.id), " neutral ", w.judgment.personal_disposition(car.id, sm.id))
	var r := m.negotiate(sm, car, "plank", 3, id, -1)
	print("neg ", r)
	EconomyFoundation.set_override({})
	quit(0)
