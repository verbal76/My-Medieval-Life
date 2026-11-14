extends SceneTree
## REG-03 (Build 25 audit, WP-1; overlaps REG-08 investigation F3). A courier delivery comes home (CourierService._home) with what
## it collected (coins asked of the recipient) and any goods sent back. Before the owner's rule, a sender who died while it was away
## had it deposited at the booth under their own reference, which nobody could withdraw. Owner rule 2026-11-12
## (docs/directives/2026-11-12_extra_life_owner_decisions.md item 2, "Estate + timeout"): "a dead sender's proceeds go to their heir
## or estate by the existing death rule, as any of their coins". _home now redirects them to the heir (World._heir; with no heir
## the coins go to the manor and goods stay deposited). Fixture: a villager merchant sends goods to Wulstead's trader asking 7
## coins and dies while they are on the road; the delivery comes home. Checked: nothing is lost or made; no proceeds are left in a
## deposit only the dead sender could withdraw; the job records the heir who received them. In CI (tests.yml).
## Not covered here (reported to the lead, Build 42; owned with the courier and migration work): a sender who has MIGRATED
## (away != "") is not redirected, and CourierService.interrupt refunds a special delivery's fee to the sender unchecked.
##   godot --headless --path game --script res://tests/reg03_courier_sender_dies_test.gd

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
	test_sender_dies()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func coin_gap(x: World) -> int:
	return x.total_coins() + x.regions.coins() - (x.coin_sources + x.regions.net_paid_by_village())


func run_days(x: World, days: float) -> void:
	var dt := 10.0 / float(GameData.b("game_minutes_per_second"))
	for i in int(days * 144.0):
		x.player.hp = x.player.max_hp
		x.player.hunger = 100.0
		x.update(dt)


func test_sender_dies() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.couriers.daily()
	var cs := w.couriers
	var vb := cs.booth_of("village")
	var m: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.job == "merchant" and str(vb.keeper) != World.npc_ref(o.id):
			m = o
			break
	check(m != null, "fixture: a villager merchant to send goods")
	if m == null:
		return
	var mref := World.npc_ref(m.id)
	var route := {}
	for r in cs.routes:
		if str(r.from) == str(vb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead":
			route = r
	w.note_settlement_trade(m, w.regions.by_id["wulstead"])
	m.inv.add(ITEM, 5)
	m.coins = maxi(m.coins, 100)
	var job: Dictionary = cs.book_route({"sender": mref, "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead",
		"items": {ITEM: 5}, "route": route.id, "collect": {"kind": "coins", "amount": 7}, "proceeds": "purse"})
	check(not job.has("error"), "fixture: the merchant books a route delivery asking 7 coins, proceeds to the purse (%s)" % str(job.get("error", "ok")))
	if job.has("error"):
		return
	var guard := 0
	while str(job.state) == "at_booth" and guard < 6:
		run_days(w, 0.5)
		guard += 1
	check(str(job.state) == "in_transit", "fixture: the goods are on the road (%s)" % str(job.state))
	var hh := m.household
	w.kill(m, "test: the sender dies while the goods are on the road")
	var gap0 := coin_gap(w)
	run_days(w, float(route.days) * 2.0 + 2.0)
	check(str(job.state) in ["fulfilled", "returned"], "the delivery comes home (%s, %s)" % [str(job.state), str(job.get("outcome", ""))])
	check(coin_gap(w) == gap0, "nothing is lost or made (coin gap %d, was %d)" % [coin_gap(w), gap0])
	var dep: Dictionary = (vb.deposits as Dictionary).get(mref, {})
	print("REG-03 state: deposit at the village booth for the dead sender %s: %s; household %d" % [mref, str(dep), hh])
	check(dep.is_empty() or (int(dep.get("coins", 0)) == 0 and (dep.get("items", {}) as Dictionary).is_empty()),
		"no proceeds are left in a deposit only the dead sender could withdraw (%s)" % str(dep))
	check(str(job.get("heir", "")) != "" and str(job.heir) != mref, "owner rule 2026-11-12 (estate): the proceeds went to the sender's heir (%s)" % str(job.get("heir", "")))
