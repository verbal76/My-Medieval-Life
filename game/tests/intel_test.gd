extends SceneTree
## REGION-NAV-01 S5, the intel network (plan AD-5). Acceptance (plan, S5): knowledge only through a teller; staleness. Also: the
## envoy tells the tradespeople the reeve's book has news for; word of mouth passes only what concerns the listener's trade;
## every retelling keeps the day the record was collected; a villager's knowledge is saved. Pure World. Run headless:
##   godot --headless --path game --script res://tests/intel_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _rec(item: String, side: String, day: int, about := "region:wulstead/smithy") -> Dictionary:
	return {"about": about, "person": "Someone", "role": "keeper", "place": "wulstead", "item": item, "side": side, "qty": 4, "price": 9,
		"kind": "confirmed", "told_by": "npc:0", "collected_day": day, "heard_day": day}


## A villager whose trade buys `item`, and one whose trade has nothing to do with it.
func _buyer_of(w: World, item: String) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and Intel.interests(w, n).get(item, "") == "buys":
			return n
	return null


func _init() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.minutes = 10.0 * 1440.0 + 9.0 * 60.0
	# a thing some village trade buys
	var item := ""
	var buyer: NPC = null
	for id in ["iron_bar", "iron_ore", "log", "wheat", "hide", "plank", "coal", "wool", "stone"]:
		buyer = _buyer_of(w, id)
		if buyer != null:
			item = id
			break
	check(buyer != null, "a village tradesperson buys %s (%s, the %s)" % [item, buyer.name if buyer else "-", buyer.job if buyer else "-"])
	var other: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n != buyer and not Intel.interests(w, n).has(item):
			other = n
			break
	# the reeve's book knows; nobody else does until told
	var r := _rec(item, "have", w.day() - 2)
	w.intel_book = {"records": [r], "visits": {"wulstead": {"day": w.day() - 2, "met": 1, "absent": 0, "failed": false}}, "home": {World.npc_ref(buyer.id): {"wants": {item: 3}, "has": {}, "day": w.day()}}, "home_day": w.day()}
	var nobody := true
	for n: NPC in w.npcs:
		if not n.intel.is_empty():
			nobody = false
	check(nobody, "a record in the reeve's book is known to no villager until someone tells them")
	var tell := Intel.to_tell(w, Envoys.book(w))
	check(tell.size() == 1 and tell[0][0] == buyer, "the envoy is to tell the one tradesperson the book has news for (%s)" % buyer.name)
	# the envoy tells them (the act at their side)
	var envoy: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n != buyer and n != other:
			envoy = n
			break
	Envoys.post(w)
	var j: Dictionary = {}
	for x in w.manor_work.jobs:
		if str(x.kind) == "envoy":
			j = x
	w.manor_work.take(j, World.npc_ref(envoy.id))
	j.stage = "tell"
	j.tell = [World.npc_ref(buyer.id)]
	Envoys.act(w, envoy, "envoy_tell", {"job": int(j.id), "to": World.npc_ref(buyer.id)})
	check(buyer.intel.size() == 1 and str(buyer.intel[0].told_by) == World.npc_ref(envoy.id) and int(buyer.intel[0].collected_day) == int(r.collected_day),
		"%s now knows it, told by the envoy, with the day it was collected" % buyer.name)
	# word of mouth: only what concerns the listener's trade, told by the teller
	Intel.share(w, buyer.id, other.id)
	check(other.intel.is_empty(), "an hour with %s (the %s, whose trade does not use %s) passes nothing on" % [other.name, other.job, item])
	var second := _buyer_of_except(w, item, [buyer, envoy])
	if second != null:
		Intel.share(w, buyer.id, second.id)
		check(second.intel.size() == 1 and str(second.intel[0].told_by) == World.npc_ref(buyer.id) and int(second.intel[0].collected_day) == int(r.collected_day),
			"an hour with %s (who also buys %s) passes it on: told by %s, still dated the day it was collected" % [second.name, item, buyer.name])
	# a fresher record replaces an older one; an older never replaces a fresher
	var newer := _rec(item, "have", w.day())
	check(Intel.hear(w, buyer, newer, "npc:0") and buyer.intel.size() == 1 and int(buyer.intel[0].collected_day) == w.day(), "fresher word of the same thing replaces the older")
	check(not Intel.hear(w, buyer, r, "npc:0"), "older word of it is not news")
	# staleness and forgetting
	var c := Intel.cfg()
	check(Intel.fresh(w, _rec(item, "have", w.day() - int(c.stale_days))) and not Intel.fresh(w, _rec(item, "have", w.day() - int(c.stale_days) - 1)), "a record is acted on for %d days from its collection, then it is stale" % int(c.stale_days))
	var old := _rec(item, "want", w.day() - int(c.forget_days) - 1, "region:wulstead/other")
	check(not Intel.hear(w, buyer, old, "npc:0"), "word older than %d days is not taken in" % int(c.forget_days))
	buyer.intel.append(old.duplicate())
	Intel._trim(w, buyer)
	check(not buyer.intel.any(func(x): return str(x.about) == "region:wulstead/other"), "and is forgotten")
	check(Intel.to_tell(w, {"records": [_rec(item, "have", w.day() - int(c.stale_days) - 1)], "home": {World.npc_ref(buyer.id): {}}}).is_empty(), "the envoy does not tell stale records")
	# saved and loaded
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.npc(buyer.id).intel.size() == buyer.intel.size() and str(w2.npc(buyer.id).intel[0].told_by) == str(buyer.intel[0].told_by), "what a villager knows is saved and loaded")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _buyer_of_except(w: World, item: String, but: Array) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and not but.has(n) and Intel.interests(w, n).get(item, "") == "buys":
			return n
	return null
