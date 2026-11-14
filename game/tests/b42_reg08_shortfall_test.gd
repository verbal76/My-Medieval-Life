extends SceneTree
## B42-REG08-SHORTFALL (owner 2026-11-14: the REG-08 refund cap approved; "Record any unpaid shortfall so it remains visible and
## auditable"): a delivery that expires at its booth (CourierService._expire, REG-08) refunds its unearned flat fee only as far as the
## payer (the carrier, or a dead carrier's heir) holds the coins, and nothing when a dead carrier has no heir. The part not refunded is
## recorded on the delivery (refund_shortfall, refund_payer; saved), counted (courier_refund_shortfall, _cases), and written in its
## history and the village log; no coin is made. A full refund records nothing. FAILING FIRST before the change (nothing recorded).
##   godot --headless --path game --script res://tests/b42_reg08_shortfall_test.gd

const ITEM := "copper_ring"

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_cases()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func coin_gap(x: World) -> int:
	return x.total_coins() + x.regions.coins() - (x.coin_sources + x.regions.net_paid_by_village())


## A world and a route delivery the player booked to Wulstead, waiting at the village booth (its flat fee paid to the keeper).
func _booked() -> Array:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.couriers.daily()
	var cs := w.couriers
	var vb := cs.booth_of("village")
	var route := {}
	for r in cs.routes:
		if str(r.from) == str(vb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead":
			route = r
	w.note_settlement_trade(w.player, w.regions.by_id["wulstead"])
	w.player.coins = 100
	w.player.inv.add(ITEM, 3)
	var job: Dictionary = cs.book_route({"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead",
		"items": {ITEM: 3}, "route": route.id})
	return [w, job, cs._npc(str(job.courier))]


func test_cases() -> void:
	# a full refund: nothing recorded
	var f := _booked()
	var w: World = f[0]
	var j: Dictionary = f[1]
	var k: NPC = f[2]
	check(not j.has("error") and int(j.fee) > 0, "fixture: a delivery booked, its fee %d paid to the keeper" % int(j.get("fee", 0)))
	k.coins = 100
	var gap0 := coin_gap(w)
	w.couriers._expire(j, float(w.day()))
	check(int(j.get("refunded", -1)) == int(j.fee) and not j.has("refund_shortfall") and float(w.stats.get("courier_refund_shortfall_cases", 0.0)) == 0.0,
		"refunded in full: no shortfall recorded")
	check(coin_gap(w) == gap0, "no coin made or lost")
	# a capped refund: the shortfall recorded, saved
	var g := _booked()
	var w2: World = g[0]
	var j2: Dictionary = g[1]
	var k2: NPC = g[2]
	k2.coins = 2
	var gap2 := coin_gap(w2)
	var p0 := w2.player.coins
	w2.couriers._expire(j2, float(w2.day()))
	check(int(j2.refunded) == 2 and w2.player.coins == p0 + 2, "the keeper holds only 2 coins: 2 refunded")
	check(int(j2.get("refund_shortfall", 0)) == int(j2.fee) - 2 and str(j2.get("refund_payer", "")) == World.npc_ref(k2.id),
		"the unpaid %d is recorded on the delivery, naming the payer (%s)" % [int(j2.fee) - 2, str(j2.get("refund_payer", ""))])
	check(float(w2.stats.get("courier_refund_shortfall", 0.0)) == float(int(j2.fee) - 2) and float(w2.stats.get("courier_refund_shortfall_cases", 0.0)) == 1.0, "and counted")
	check(str((j2.history as Array).back()[1]).begins_with("unpaid refund"), "and written in its history (%s)" % str((j2.history as Array).back()))
	check(w2.log_lines.any(func(l): return str(l).contains("could not refund")), "and in the village log")
	check(coin_gap(w2) == gap2, "no coin made to cover it")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w2.to_dict())))
	var j3: Dictionary = w3.couriers.job(str(j2.id)) if w3.couriers.has_method("job") else {}
	for x in w3.couriers.jobs:
		if str(x.id) == str(j2.id):
			j3 = x
	check(int(j3.get("refund_shortfall", 0)) == int(j2.fee) - 2 and typeof(j3.get("refund_shortfall")) == TYPE_INT and str(j3.get("refund_payer", "")) == World.npc_ref(k2.id),
		"saved and loaded, the record stands (%s)" % str(j3.get("refund_shortfall", "none")))
	# a dead carrier with no heir: nothing refunded, the whole fee recorded
	var h := _booked()
	var w4: World = h[0]
	var j4: Dictionary = h[1]
	var k4: NPC = h[2]
	w4.kill(k4, "test: the keeper dies")
	k4.household = -1                            # (no heir: World._heir finds none for a villager of no household)
	var gap4 := coin_gap(w4)
	w4.couriers._expire(j4, float(w4.day()))
	check(int(j4.refunded) == 0 and int(j4.get("refund_shortfall", 0)) == int(j4.fee) and str(j4.get("refund_payer", "")) == World.npc_ref(k4.id),
		"a dead keeper with no heir: nothing refunded, the whole %d recorded against them" % int(j4.fee))
	check(coin_gap(w4) == gap4, "no coin made")
