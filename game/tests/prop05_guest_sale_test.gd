extends SceneTree
## PROP-05: the server must reject a fabricated direct NPC sale guest verb.
## Only the host AI should initiate business.sell after choosing a real customer and price.
var checks := 0
var failures := 0
func check(cond: bool, label: String) -> void:
	checks += 1
	if cond:
		print("ok   " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 5005)
	w.player.coins = 200
	var rented := w.business.rent()
	check(rented == "", "PROP-05: host rented a pitch")
	var s: Dictionary = w.business.mine()
	w.player.inv.add("plank", 2)
	check(w.business.list_item(s, "plank", 2) == "", "PROP-05: host listed two planks")
	var n: NPC = null
	for candidate: NPC in w.npcs:
		if candidate.alive and candidate.role == "adult" and candidate.household >= 0:
			n = candidate
			break
	if n == null:
		check(false, "PROP-05: available villager buyer")
		w.dispose()
		quit(1)
		return
	n.coins = maxi(n.coins, 100)
	n.pos = w.business.use_cell(s)
	var g := PlayerState.new()
	g.name = "Guest"
	g.family = "Test"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "c".repeat(32)
	g.pos = n.pos
	w.add_guest(g)
	var before_stock := int(s.stock.get("plank", 0))
	var before_buyer_goods := n.inv.count("plank")
	var before_till := int(s.till)
	# Host must reject a guest asking to sell the HOST's stock to a villager
	# at an arbitrary zero-coin price, even though all decoded objects exist.
	var result := NetActions.apply_verb(w, g, "business.sell",
		[NetActions.enc(w, s), NetActions.enc(w, n), "plank", 1, 0, false])
	check(not bool(result.get("ok", false)), "PROP-05: guest cannot invoke internal business.sell")
	check(int(s.stock.get("plank", 0)) == before_stock, "PROP-05: foreign stock unchanged")
	check(n.inv.count("plank") == before_buyer_goods, "PROP-05: no free goods transferred to NPC")
	check(int(s.till) == before_till, "PROP-05: foreign till unchanged")
	# Normal host-driven sale continues to work through the internal function.
	var legal := w.business.sell(s, n, "plank", 1, 5)
	check(legal and int(s.stock.get("plank", 0)) == before_stock - 1, "PROP-05: host AI sale still transfers one item")
	check(int(s.till) == before_till + 5, "PROP-05: host AI sale receives normal price")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
