extends SceneTree
## MML-REQ-JOB-02 (owner REC-013 Q4, 2026-10-21, docs/directives/2026-10-21_build17_rec013_final_decisions.md section 5):
## offered compensation on the manor's job board that workers can accept or reject. Checks the owner's settled points:
## each funded posting offers pay; an eligible worker weighs it and may decline ("the offered compensation is insufficient,
## another opportunity is better, or other needs take priority"); the manor may raise its offer to attract a worker; a job may
## stay unfilled; the manor never offers what it cannot fund; the accepted pay is set aside on taking and paid once, in full,
## on completion (no coins made or lost); salaried hands get no extra pay; the player chooses on the board; a player's own order
## and CON-01 are untouched; the switch off keeps the board exactly as before; a save keeps an offer mid-way.
##   godot --headless --path game --script res://tests/job02_offered_pay_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	var c: Dictionary = ManorWork.offer_cfg()
	check(not c.is_empty() and c.get("enabled") == false, "shipped: offered pay is behind its switch, off until the owner's JOB-02 answers")
	_test_off()
	c.enabled = true
	_test_weighing()
	_test_raise_and_pay()
	_test_limits()
	_test_save()
	c.enabled = false
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 1440.0 + 8.0 * 60.0
	w.treasury = 5000
	w.manor_work.jobs.clear()
	return w


## An adult of `job` in a household with plenty of food, earning `per_day` of late.
func _worker(w: World, job: String, per_day: int, but: Array = []) -> NPC:
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and not but.has(o) and not (o.job in ["guard", "reeve", "sage"]) \
				and not but.any(func(b: NPC) -> bool: return b.household == o.household):
			if job == "manor_hand":
				w.brain._change_job(o, "manor_hand", "a test")
			else:
				o.job = job
			o.income_days = [per_day, per_day, per_day, per_day, per_day]
			(w.households[o.household].pantry as Inventory).add(NPCBrain.FOOD[0], 200)
			return o
	return null


func _post(w: World, kind: String, wage: int) -> Dictionary:
	w.manor_work._post({"kind": kind, "qty": 4, "item": "stone", "wage": wage, "to": {"kind": "yard"}, "lot": -1, "at": [20, 20], "src": "a test"})
	return w.manor_work.jobs[w.manor_work.jobs.size() - 1]


func _ref(n: NPC) -> String:
	return World.npc_ref(n.id)


func _test_off() -> void:
	var w := _world()
	var rich := _worker(w, "laborer", 40)
	var j := _post(w, "haul", 2)
	check(w.manor_work.accepts(j, _ref(rich)), "switch off: every offer is accepted, as before")
	check(w.manor_work.seek(rich) and j.taker == _ref(rich), "switch off: a well-earning labourer still takes the first open job (the board unchanged)")
	w.manor_work.release(j)
	j.declined_by = [_ref(rich)]
	w.manor_work.raise_offers()
	check(int(j.wage) == 2 and not j.has("raised"), "switch off: the manor never raises an offer")


func _test_weighing() -> void:
	var w := _world()
	var mw := w.manor_work
	var rich := _worker(w, "laborer", 20)        # asks 5 for a quarter-day haul
	var idle := _worker(w, "", 0, [rich])        # has earned nothing: any offer is worth it
	var hand := _worker(w, "manor_hand", 20, [rich, idle])
	var j := _post(w, "haul", 2)
	check(rich != null and idle != null and hand != null, "fixture: a well-earning labourer, an adult out of work, a manor hand")
	check(mw.asking_for(j, rich) == 5, "a labourer earning 20 a day asks 5 for a quarter day's carrying (got %d)" % mw.asking_for(j, rich))
	var t0 := w.treasury
	var coins0 := w.total_coins()
	check(not mw.seek(rich) and j.taker == "", "the labourer declines a 2-coin haul below what his own work earns: the job stays open")
	check((j.declined_by as Array) == [_ref(rich)], "the refusal is noted on the posting, once")
	check(not mw.seek(rich) and (j.declined_by as Array).size() == 1, "asking again the same day neither takes it nor notes him twice")
	check(w.treasury == t0 and w.total_coins() == coins0, "a refusal moves no coin")
	check(mw.open_for(_ref(rich)).has(j), "the declined job is still on the board (no forced acceptance, no removal)")
	# need first: the same labourer, his household out of food, takes it
	var hh: Dictionary = w.households[rich.household]
	for m: NPC in w.npcs:
		if m.alive and m.household == rich.household:
			m.coins = 0
	for inv: Inventory in w.brain.household_stores(rich.household):
		for id in inv.ids():
			if NPCBrain.food_points(id) > 0:
				inv.remove(id, inv.count(id))
	print("     food days now %.2f" % w.brain.household_food_days(rich.household))
	check(w.brain.household_food_days(rich.household) < float(GameData.b("relief_trigger_days")) and mw.accepts(j, _ref(rich)),
			"a household short of food takes any offer (other needs come first)")
	(hh.pantry as Inventory).add(NPCBrain.FOOD[0], 200)
	# the out-of-work adult and the salaried hand
	check(mw.accepts(j, _ref(idle)), "an adult who has earned nothing accepts any offer")
	check(mw.accepts(j, _ref(hand)) and mw.is_staff(_ref(hand)), "the salaried hand does the board's work as before (no weighing: the wage is his pay)")
	check(mw.seek(hand) and j.taker == _ref(hand) and int(j.reserved) == 0 and w.treasury == t0, "the hand takes it unpaid: no extra wage, nothing set aside")
	mw.release(j)
	check(mw.accepts(j, World.PLAYER), "the player is never refused by the weighing: the player chooses on the board")
	# another opportunity: the labourer passes over a job he declines and takes the next he accepts
	var good := _post(w, "quarry", 25)
	rich.inv.add("pickaxe", 1)
	check(mw.open_for(_ref(rich))[0] == j, "the haul is the most needed open job for him")
	check(mw.seek(rich) and good.taker == _ref(rich) and j.taker == "", "he passes the haul over and takes the quarrying, whose offer reaches his asking")


func _test_raise_and_pay() -> void:
	var w := _world()
	var mw := w.manor_work
	var lab := _worker(w, "laborer", 12)          # asks 3 for a haul
	var j := _post(w, "haul", 2)
	var coins0 := w.total_coins()
	check(not mw.seek(lab), "offered 2, the labourer asking 3 declines")
	mw.dawn()
	check(int(j.wage) == 3 and int(j.base_wage) == 2 and int(j.raised) == 1, "at dawn the manor raises the refused offer by a quarter of its first offer, at least a coin (2 -> 3)")
	check((j.declined_by as Array).is_empty(), "the refusals are forgotten: a new day, a new weighing")
	check(w.total_coins() == coins0, "raising an offer moves no coin")
	mw.dawn()
	check(int(j.wage) == 3, "no refusal since the last dawn: the offer stays")
	var t0 := w.treasury
	check(mw.seek(lab) and j.taker == _ref(lab), "offered 3, the labourer accepts")
	check(int(j.reserved) == 3 and w.treasury == t0 - 3 and w.total_coins() == coins0, "the agreed pay is set aside from the treasury on taking, nothing made")
	var c0 := lab.coins
	mw._finish(j, _ref(lab))
	check(lab.coins == c0 + 3 and w.total_coins() == coins0, "paid once, in full, on completion: the pay moved, no coin made or lost")
	check(not mw.jobs.has(j), "the job is done and off the board: it cannot be paid twice")


func _test_limits() -> void:
	var w := _world()
	var mw := w.manor_work
	var rich := _worker(w, "laborer", 40)          # asks 10 for a haul: more than the manor will ever offer
	var j := _post(w, "haul", 2)
	for d in 6:
		mw.seek(rich)
		mw.raise_offers()
	check(int(j.wage) == 4 and int(j.raised) == 2, "the offer rises no higher than twice the first offer (2 -> 4; got %d)" % int(j.wage))
	check(j.taker == "" and not mw.seek(rich), "nobody willing at the manor's best offer: the job stays unfilled (no guaranteed hiring)")
	# the manor's funds: no offer it could not pay
	var k := _post(w, "mend", 4)
	mw.seek(rich)
	var line: float = w.brain.daily_obligations() * float(GameData.b("manor_job_reserve_days"))
	w.treasury = int(ceil(line)) + 4
	mw.raise_offers()
	check(int(k.wage) == 4 and not k.has("raised"), "a treasury that could not fund the raised offer does not raise it")
	# a player's own order is the player's: the manor never raises it
	var o := _post(w, "backfill", 5)
	o.payer = World.PLAYER
	o.declined_by = [_ref(rich)]
	mw.raise_offers()
	check(int(o.wage) == 5, "a player's own order keeps the player's wage")


func _test_save() -> void:
	var w := _world()
	var mw := w.manor_work
	var lab := _worker(w, "laborer", 20)
	var j := _post(w, "mend", 4)
	mw.seek(lab)
	mw.raise_offers()
	mw.seek(lab)
	check(int(j.wage) == 5 and (j.declined_by as Array).size() == 1, "fixture: an offer raised once and refused again today")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var j2: Dictionary = w2.manor_work.job(int(j.id))
	check(not j2.is_empty() and int(j2.wage) == 5 and int(j2.base_wage) == 4 and int(j2.raised) == 1 and (j2.declined_by as Array) == [_ref(lab)],
			"save and load keep the offer, its first rate, its raises and today's refusals")
	check(w2.total_coins() == w.total_coins(), "save and load keep every coin")
	w2.manor_work.raise_offers()
	check(int(j2.wage) == 6, "after loading, the manor's dawn raise goes on from where it was")
