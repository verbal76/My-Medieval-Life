extends SceneTree
## MP-01: host-world trading AI must see a guest's attended open pitch.
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
	w.setup(VillageMap.load_default(), 8601)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Trade"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "7".repeat(32)
	g.coins = 500
	w.add_guest(g)
	var rented: String = str(w.as_actor(g, w.business.rent))
	check(rented == "", "MP-01: guest rents an open market pitch")
	if rented != "":
		w.dispose()
		quit(1)
		return
	var s: Dictionary = w.as_actor(g, w.business.mine)
	check(not s.is_empty() and w.tenant_of(s) == w.player_ref(g), "MP-01: pitch belongs to guest")
	g.inv.add("plank", 3)
	var listed: String = str(w.as_actor(g, w.business.list_item.bind(s, "plank", 3)))
	check(listed == "" and not s.stock.is_empty(), "MP-01: guest lists real stock")
	g.pos = w.business.use_cell(s)
	w.player.pos = g.pos + Vector2(200, 200)
	check(bool(w.as_actor(g, w.business.attended.bind(s))), "MP-01: guest considers their own open pitch attended")
	check(w.business.attended(s), "MP-01: host hourly AI also sees near guest attending pitch")
	check(w.business.player_near(s), "MP-01: host seller-distance check targets guest, not host")
	g.pos = g.pos + Vector2(200, 200)
	w.player.pos = w.business.use_cell(s)
	check(not w.business.attended(s), "MP-01: host proximity cannot make an absent guest's pitch attended")
	check(not w.business.player_near(s), "MP-01: seller-distance check uses guest position when host is near")
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
