extends SceneTree
## REG-08 (Build 25 audit, WP-1; investigation docs/decisions/REG-08-INVESTIGATION-2026-11-09.md, finding F1; owner decision
## B25-AUD-REG-08 OPEN): a regular-route delivery waits at the booth ("at_booth") until its carrier leaves. When the carrier (the
## carrier booth's keeper) is dead and nobody can be hired to keep the booth (CourierService.daily needs Construction.can_hire),
## CourierService._depart skips the job every departure and tick interrupts only in_transit/returning jobs: the job never ends,
## its goods stay in the booth's store and the sender's flat fee is gone. This is the FAILING-FIRST reproduction. The fix needs the
## owner's policy (who receives the goods, how and when a waiting job ends, whether the fee is refunded), so no game code changes
## here and this test is not in the CI suite list until a policy is chosen; it then becomes the fix's acceptance test.
## What must already hold (and does): nothing is lost or made while it waits, and a save keeps it as it was.
## What fails today: the job ends (a terminal state) within three departures with no carrier, and its goods leave the booth.
##   godot --headless --path game --script res://tests/reg08_stranded_route_job_test.gd

const Census := preload("res://tests/census.gd")
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
	test_stranded()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func coin_gap(x: World) -> int:
	return x.total_coins() + x.regions.coins() - (x.coin_sources + x.regions.net_paid_by_village())


## courier_live_test's item_gap: the census less what crossed the boundary, was made or was used (the run's counters are not
## saved, so a loaded world counts from its own start)
func items(x: World) -> int:
	var made := 0
	for k in ["made_", "mined_", "felled_", "dug_", "cut_", "farm_harvest_"]:
		made += int(x.stats.get(k + ITEM, 0))
	var used := 0
	for k in ["eaten_", "used_", "used_building_", "used_works_", "used_repairs_", "burned_", "broke_", "spoiled_"]:
		used += int(x.stats.get(k + ITEM, 0))
	return int(Census.goods(x).get(ITEM, 0)) + int(x.stats.get("exported_" + ITEM, 0)) - int(x.stats.get("imported_" + ITEM, 0)) - made + used


## A village with no free hands: every adult has work of their own (the failing village WDR-022 allows), so nobody can be hired to
## keep the booth. Re-applied each day, since the job market moves people.
func no_free_hands(x: World) -> void:
	for n: NPC in x.npcs:
		if n.alive and n.role == "adult" and n.job in Construction.HIRABLE:
			n.job = "farmer"


func run_days(x: World, days: float) -> void:
	var dt := 10.0 / float(GameData.b("game_minutes_per_second"))
	for d in int(ceil(days)):
		no_free_hands(x)
		for i in 144:
			x.player.hp = x.player.max_hp
			x.player.hunger = 100.0
			x.update(dt)


func test_stranded() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.couriers.daily()
	var cs := w.couriers
	var vb := cs.booth_of("village")
	var route := {}
	for r in cs.routes:
		if str(r.from) == str(vb.id) and str(cs.booth(str(r.to)).settlement) == "wulstead":
			route = r
	check(not route.is_empty(), "fixture: the village booth's route to Wulstead")
	if route.is_empty():
		return
	w.note_settlement_trade(w.player, w.regions.by_id["wulstead"])      # the player knows Wulstead's trader (courier_live_test)
	w.player.coins = 100
	w.player.inv.add(ITEM, 3)
	var gap0 := coin_gap(w)
	var job: Dictionary = cs.book_route({"sender": "player", "recipient": "region:wulstead/trader", "recipient_kind": "business", "settlement": "wulstead",
		"items": {ITEM: 3}, "route": route.id})
	check(not job.has("error") and str(job.state) == "at_booth", "fixture: a route delivery is booked and waits at the booth (%s)" % str(job.get("error", job.get("state", ""))))
	if job.has("error"):
		return
	no_free_hands(w)
	var keeper := w.npc(int(str(vb.keeper).trim_prefix("npc:")))
	w.kill(keeper, "test: the booth's keeper dies before the route leaves")
	run_days(w, 1.0)
	check(not cs.alive(str(cs.booth_of("village").keeper)), "fixture: no new keeper can be found (nobody free to hire)")
	check(str(job.state) == "at_booth", "fixture: the delivery still waits at the booth")
	# saved and loaded while it waits
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var j2: Dictionary = {}
	for j in w2.couriers.jobs:
		if int(j.id) == int(job.id):
			j2 = j
	check(not j2.is_empty() and str(j2.state) == "at_booth" and coin_gap(w2) == coin_gap(w), "saved and loaded, it waits as it was and the coins balance")
	var item2 := items(w2)
	var departures := 4                                   # 9 days: past the 7-day wait (REG-08 owner rule 2026-11-12)
	run_days(w2, float(departures * int(route.every_days)) + 1.0)
	var vb2 := w2.couriers.booth_of("village")
	print("REG-08 state after %d departures with no carrier: job %s; %d %s in the booth's store; booth keeper %s" % [departures, str(j2.state),
		(vb2.store as Inventory).count(ITEM), ITEM, str(vb2.keeper)])
	check(coin_gap(w2) == gap0, "nothing is lost or made while it waits (coin gap %d, was %d)" % [coin_gap(w2), gap0])
	check(items(w2) == item2, "every %s is still counted (%d, was %d at the load)" % [ITEM, items(w2), item2])
	# owner rule 2026-11-12 (Estate + timeout): the waiting delivery ends and its goods go back
	check(str(j2.state) != "at_booth", "with no carrier for %d departures the waiting delivery ends (state %s)" % [departures, str(j2.state)])
	check((vb2.store as Inventory).count(ITEM) == 0, "and its goods leave the booth's store (%d there)" % (vb2.store as Inventory).count(ITEM))
