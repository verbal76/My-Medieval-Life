extends SceneTree
## Found in the simulation batch's recorded campaign (42734194963, seed 1, finding F002 and the day-243 cluster): a hungry villager
## whose household pays for their meal (NPCBrain._payer_for: the family's purse, or its richest member) was sent to buy that meal
## from the food seller nearest them (_vendor_with_food) even when the payer WAS that seller. World.trade refuses a trade with oneself
## ("invalid_trade"), the plan failed, and the same plan was made again the next minute: p:64 was refused 1262 times in one day. The
## seller is never the payer for their own goods: the household pays with someone else's purse, or the villager does not plan that
## purchase. The same holds for grain bought from a farmer of the household.
##   godot --headless --path game --script res://tests/self_trade_payer_test.gd

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
	w.setup(VillageMap.load_default(), 1)
	var v: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.job == "tavernkeeper" and o.household >= 0:
			v = o
			break
	check(v != null, "fixture: a tavernkeeper in a household")
	if v == null:
		quit(1)
		return
	var hungry: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o != v and o.role in ["adult", "elder"] and o.job not in ["tavernkeeper", "guard"]:
			hungry = o
			break
	# the hungry villager joins the tavernkeeper's household; the tavernkeeper is its richest member and the only food seller
	if hungry.household >= 0:
		w.households[hungry.household].members.erase(hungry.id)
	hungry.household = v.household
	if not w.households[v.household].members.has(hungry.id):
		w.households[v.household].members.append(hungry.id)
	for m in w.households[v.household].members:
		var o := w.npc(m)
		if o != null and o != v:
			o.coins = 0
	v.coins = 500
	v.inv.add("pottage", 5)
	for o: NPC in w.npcs:
		if o != v and (o.job == "tavernkeeper" or w.brain.buy_role(o) == "merchant_food"):
			for f in NPCBrain.COOKED:
				o.inv.remove(f, o.inv.count(f))
	(w.households[v.household].pantry as Inventory).items.clear()
	hungry.inv.items.clear()                     # nothing of their own to eat or cook
	hungry.hunger = 10.0
	hungry.plan.clear()
	hungry.pos = v.pos + Vector2(2, 0)
	w.brain._plan_eat(hungry)
	var self_trade := false
	for st in hungry.plan:
		if str(st.get("act", "")) in ["buy_food", "buy_from"]:
			var a: Dictionary = st.get("args", {})
			if int(a.get("vendor", -1)) == v.id and int(a.get("payer", hungry.id)) == v.id:
				self_trade = true
	check(not self_trade, "the hungry villager is not sent to buy from the tavernkeeper with the tavernkeeper's own purse (plan %s)" % str(hungry.plan.map(func(s): return [s.get("act", s.get("k")), s.get("args", {})])))
	# with a purse of their own, they buy from the tavernkeeper as anyone does (control)
	hungry.coins = 50
	hungry.plan.clear()
	w.brain._plan_eat(hungry)
	var buys := hungry.plan.any(func(s): return str(s.get("act", "")) == "buy_food" and int((s.get("args", {}) as Dictionary).get("vendor", -1)) == v.id and int((s.get("args", {}) as Dictionary).get("payer", hungry.id)) == hungry.id)
	check(buys, "with coins of their own they buy the meal from the tavernkeeper (control)")
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
