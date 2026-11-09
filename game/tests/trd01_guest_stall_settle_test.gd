extends SceneTree
## TRD-01 (Build 25 audit, docs/audits/2026-11-08_build25_master_audit_register.md): when a market stall's session was a guest
## player's, Stalls.settle must pay that player the net (the till less the manor's commission), take the commission once and end
## the session. Before the fix the guest's PlayerState was assigned to an NPC variable: a runtime error left the session open, so
## the next settle charged the commission again on the same gross. Coins are conserved throughout.
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
	g.net_key = "7".repeat(32)
	g.coins = 500
	w.add_guest(g)
	var s: Dictionary = {}
	for id in w.stalls:
		s = w.stalls[id]
		break
	check(not s.is_empty(), "fixture: a market stall")
	var c0 := w.total_coins()
	w.player.coins -= 100                                   # a buyer's 100 coins are in the till (record_sale's precondition)
	s.till = int(s.get("till", 0)) + 100
	s.frac = 0
	w.business.stalls.record_sale(s, w.player_ref(g), "plank", 1, 100)
	check(w.total_coins() == c0, "fixture: the sale's coins sit in the till (total unchanged)")
	var g0 := g.coins
	var t0 := w.treasury
	var r: Dictionary = w.business.stalls.settle(s)
	var com := int(r.get("commission", -1))
	var net := int(r.get("net", -1))
	check(com > 0 and net > 0 and com + net == 100, "the session settles: commission %d, net %d" % [com, net])
	check(g.coins == g0 + net, "the guest who sold is paid the net (%d -> %d)" % [g0, g.coins])
	check(w.treasury == t0 + com, "the manor takes its commission once (%d)" % (w.treasury - t0))
	check(not s.has("session") and int(s.get("till", -1)) == 0, "the session is ended and the till emptied")
	var t1 := w.treasury
	w.business.stalls.settle(s)
	check(w.treasury == t1 and g.coins == g0 + net, "a second settle moves nothing")
	check(w.total_coins() == c0, "no coin made or lost")
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
