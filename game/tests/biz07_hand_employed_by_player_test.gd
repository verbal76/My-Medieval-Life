extends SceneTree
## BIZ-07 (Build 25 audit, WP-1; related to BIZ-05): a venture's hands (independent craftspeople at its benches, B25-BIZ-D2) keep
## their place by the keeper's leave (World.permit) and the venture's list (venture.hands). Employment's terms (Employment.refusal,
## obligation) do not look at venture hands, and a hand's job is the trade, so a player holding a workshop of that trade can employ
## a venture's hand: the test shows the hire happens and the hand then is both the venture's hand (leave at its benches, on its
## list) and the player's paid employee, one person in two places (what BIZ-05 ruled out for the venture's own hiring, and
## B25-BIZ-D4 "one employer at a time" rules out between employers). FAILING-FIRST reproduction: the fix is an exclusivity rule
## the owner has not chosen (refuse the employment while they are a hand; or the employment ends the hand's place), so no game
## code changes and the test is not in the CI suite list.
##   godot --headless --path game --script res://tests/biz07_hand_employed_by_player_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_hand_employed()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## The fixtures of biz05_hand_not_hired_test.gd.
func world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	w.judgment.cfg.decision.integration.work_accept = false      # the villager's own yes is JudgmentLive's test; here the terms
	return w


func of_job(w: World, job: String) -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.job == job)


## The fixtures of biz03_payroll_priority_test.gd: the village's best smith founds, builds and opens a smithy.
func founder(w: World) -> NPC:
	var s: NPC = null
	for o: NPC in of_job(w, "smith"):
		if s == null or Skills.level(o, "smithing") > Skills.level(s, "smithing"):
			s = o
	var key := World.npc_ref(s.id)
	if not w.experience.minutes.has(key):
		w.experience.minutes[key] = {}
	w.experience.minutes[key]["smithing"] = 480.0 * 60.0
	s.coins += 3000
	w.brain.evaluate_household(s.household)
	return s


func smithy_full(w: World) -> void:
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	var past := []
	for i in int(GameData.b("skilled_places").window_days):
		var d := {}
		for kind in NPCBrain.TRADE_STATIONS.smith:
			for st in w.stations_of(kind):
				if w.ventures.venture_at(st).is_empty():
					d[st] = {"smith": day}
		past.append(d)
	w.station_load = {"day": w.day(), "today": {}, "past": past}


func open_one(w: World) -> Array:
	var s := founder(w)
	smithy_full(w)
	w.ventures.found(s, w.ventures.eligible(s))
	var hh: Dictionary = w.households[s.household]
	var p: Dictionary = w.plot(str(hh.build))
	var pantry: Inventory = hh.pantry
	for id in p.site.need.duplicate():
		pantry.add(id, int(p.site.need[id]))
	w.deliver(p, pantry)
	var b: Dictionary = w.buildings.get(str(p.get("building", "")), {})
	w.minutes += 1440.0
	w.station_load = {}
	w.ventures.daily()
	return [s, b]


func test_hand_employed() -> void:
	var w := world()
	var r := open_one(w)
	var s: NPC = r[0]
	var b: Dictionary = r[1]
	check(b.has("venture"), "fixture: the smithy is open")
	if not b.has("venture"):
		return
	var v: Dictionary = b.venture
	var hand: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.household != s.household and o.job in Construction.HIRABLE \
				and w.employment.obligation(o) == "":
			hand = o
			break
	check(hand != null, "fixture: an adult to be the smithy's hand")
	if hand == null:
		return
	hand.job = "smith"
	v.hands.append(hand.id)
	w.permit(b, World.npc_ref(hand.id), true)
	# the player holds a workshop with a forge or anvil of their own (another building with smith stations) and a home with a chest
	var shop: Dictionary = {}
	for st in w.stations:
		var sd: Dictionary = w.stations[st]
		var bb: Dictionary = w.buildings.get(str(sd.get("building", "")), {})
		if str(sd.type) in NPCBrain.TRADE_STATIONS.smith and not bb.is_empty() and str(bb.id) != str(b.id):
			shop = bb
			break
	check(not shop.is_empty(), "fixture: a building with smith stations besides the smithy")
	if shop.is_empty():
		return
	shop.owner = World.PLAYER
	shop.tenant = ""
	w.player.home = str(shop.id)
	w.player.coins += 1000
	var makes: Array = w.employment.makes("smith", World.PLAYER)
	check(not makes.is_empty(), "fixture: the player's stations make something (%s)" % str(makes.slice(0, 3)))
	if makes.is_empty():
		return
	var why: String = w.employment.employ(hand, "smith", -1, "", str(makes[0]))
	print("BIZ-07 reproduction: the player employs the smithy's hand: %s" % ("hired" if why == "" else why))
	var employed: bool = w.employment.is_employed(hand)
	var still_hand: bool = Ventures.is_hand(v, hand.id) or (v.hands as Array).has(hand.id)
	var leave: bool = (b.get("allow", []) as Array).has(World.npc_ref(hand.id))
	print("BIZ-07 state: employed by the player %s; on the venture's hands %s; leave at its benches %s" % [str(employed), str(still_hand), str(leave)])
	check(not (employed and (still_hand or leave)), "one person in one place: a player's employee is not also the venture's hand with its leave (employed %s, hand %s, leave %s)" % [str(employed), str(still_hand), str(leave)])
