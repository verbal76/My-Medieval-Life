extends SceneTree
## B25-P99-PAYER-01 (owner 2026-11-10, docs/directives/2026-11-10_seed2_findings_f015_p99.md): found in the recorded campaign
## 42788018729 (fbfd6ad, seed 2, F001/F002): the smith p:99 was refused a trade 10269 times in a row, "refused_by_rules /
## below_reserve", 553 times on day 196 alone, every minute "buying iron ore for the forge". NPCBrain._smith planned the forge's
## inputs (and its planks, and the ore an open manor order lacks) on `n.coins >= 10` (or the list price) only, while the buy_from
## act sells by its own rule: the bargained price (World.deal_price), above the buyer's reserve (World.can_afford). The planner
## also never read the failure memo (buy_held), so the same refused purchase was planned again the next minute. The same streak
## is in every smith of that campaign (p:14, p:28, p:29, p:100, p:123: coal and iron ore). A purchase is now planned only for
## what the act would sell (NPCBrain.buy_qty, the act's own rule). Checked:
##   1 a smith with coins >= 10 but none above the reserve is not sent to buy ore or coal (60 decisions), nothing changes hands
##   2 a smith who can pay above the reserve is sent, for the quantity the act then sells, and pays exactly the deal price
##   (the forge's planks follow the same rule in the code; not reachable from a fresh world here: a buyer's chisel comes first)
##   3 the ore a manor order lacks (paid in advance: the whole purse, X20-FIREWOOD) is planned only when the act would sell it
##   4 after a refusal nothing changed is not planned again (buy_held), within the hour
##   5 the same plans after a save and load and on two identical worlds (deterministic); coins conserved
##   godot --headless --path game --script res://tests/smith_forge_purchase_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	case_below_reserve()
	case_can_pay()
	case_order()
	case_held()
	case_save_load_and_replay()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


## A world whose smith `s` holds nothing and a raw-goods merchant `v` holds ore and coal, and a carpenter `c` planks. Returns {w, s, v, c}.
func setup(seed := 1) -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var s: NPC = null
	var v: NPC = null
	var c: NPC = null
	for o: NPC in w.npcs:
		if not o.alive:
			continue
		if s == null and o.job == "smith":
			s = o
		elif v == null and w.brain.buy_role(o) == "merchant_raw":
			v = o
		elif c == null and o.job == "carpenter":
			c = o
	s.inv.items.clear()
	w.manor_orders.clear()
	if s.household >= 0:                      # an empty larder and no firewood: the household's necessity reserve is real
		(w.households[s.household].pantry as Inventory).items.clear()
		for m in w.households[s.household].members:
			var o := w.npc(m)
			if o != null and o != s:
				o.inv.items.clear()
				o.coins = 0
	for id in ["iron_ore", "coal"]:
		v.inv.add(id, 10)
	c.inv.add("plank", 10)
	for o: NPC in w.npcs:                     # only v sells ore and coal
		if o != v and w.brain.buy_role(o) == "merchant_raw":
			for id in ["iron_ore", "coal"]:
				o.inv.remove(id, o.inv.count(id))
	s.pos = v.pos + Vector2(2, 0)
	s.plan.clear()
	return {"w": w, "s": s, "v": v, "c": c}


func _buy(n: NPC) -> Dictionary:
	for st in n.plan:
		if str(st.get("act", "")) == "buy_from":
			return st
	return {}


func _coins(w: World) -> int:
	var t := w.treasury
	for o: NPC in w.npcs:
		t += o.coins
	return t


## The smith's purse set to `above` coins over its reserve (never below 10, the old planner's bar).
func _purse(w: World, s: NPC, above: int) -> void:
	s.coins = 0
	var r := w.reserve_of(s)
	s.coins = maxi(10, r + above)
	w._reserve_cache.clear()


func case_below_reserve() -> void:
	var t := setup()
	var w: World = t.w
	var s: NPC = t.s
	var v: NPC = t.v
	_purse(w, s, 0)
	var up := w.deal_price(w.sell_price(v, "coal"), s, v)
	check(s.coins >= 10 and not w.can_afford(s, up), "fixture: the smith has %d coins (>= 10) but none to spend above its reserve %d (coal %d)" % [s.coins, w.reserve_of(s), up])
	var c0 := _coins(w)
	var planned := 0
	var refused := 0
	for i in 60:
		s.plan.clear()
		w.brain._smith(s)
		var st := _buy(s)
		if not st.is_empty():
			planned += 1
			if not w.brain.act(s, "buy_from", st.args):
				refused += 1
		w.minutes += 1.0
	check(planned == 0, "a smith with no coins above its reserve is not sent to buy ore or coal in 60 decisions (%d planned, %d refused)" % [planned, refused])
	check(_coins(w) == c0 and s.inv.count("coal") == 0 and s.inv.count("iron_ore") == 0, "and nothing changes hands")
	w.dispose()


func case_can_pay() -> void:
	var t := setup()
	var w: World = t.w
	var s: NPC = t.s
	var v: NPC = t.v
	_purse(w, s, 200)
	w.brain._smith(s)
	var st := _buy(s)
	check(not st.is_empty() and str(st.args.item) in ["coal", "iron_ore"], "a smith who can pay above its reserve is sent to buy the forge's inputs (plan %s)" % str(st.get("args", {})))
	if st.is_empty():
		w.dispose()
		return
	var item := str(st.args.item)
	var q := int(st.args.qty)
	var up := w.deal_price(w.sell_price(v, item), s, v)
	var sc := s.coins
	var vc := v.coins
	var c0 := _coins(w)
	var ok: bool = w.brain.act(s, "buy_from", st.args)
	check(ok and s.inv.count(item) == q and s.coins == sc - up * q and v.coins == vc + up * q,
		"and the act sells the whole planned quantity (%d %s) at the deal price %d each" % [q, item, up])
	check(_coins(w) == c0, "coins conserved")
	w.dispose()


func case_order() -> void:
	var t := setup()
	var w: World = t.w
	var s: NPC = t.s
	var v: NPC = t.v
	var up := w.deal_price(w.sell_price(v, "iron_ore"), s, v)
	var lp := w.sell_price(v, "iron_ore")
	s.coins = lp if up > lp else 0            # the list price, short of the deal price (or nothing at all)
	var planned := 0
	for i in 30:
		s.plan.clear()
		if w.brain._fetch_for_order(s, {"iron_bar": 2}):
			if not _buy(s).is_empty():
				planned += 1
		w.minutes += 1.0
	check(planned == 0, "the ore a manor order lacks is not planned when the purse cannot pay the deal price %d (purse %d; %d planned)" % [up, s.coins, planned])
	s.coins = up * 4
	s.plan.clear()
	var st := _buy(s) if w.brain._fetch_for_order(s, {"iron_bar": 2}) else {}
	check(not st.is_empty() and w.brain.act(s, "buy_from", st.args) and s.inv.count(str(st.args.item)) == int(st.args.qty),
		"with the purse to pay, the order's ore is planned and the act sells all of it (plan %s)" % str(st.get("args", {})))
	w.dispose()


func case_held() -> void:
	var t := setup()
	var w: World = t.w
	var s: NPC = t.s
	var v: NPC = t.v
	_purse(w, s, 200)
	w.brain._smith(s)
	var st := _buy(s)
	if st.is_empty():
		check(false, "fixture: a planned purchase to refuse")
		w.dispose()
		return
	var item := str(st.args.item)
	w.brain.buy_failed[s.id] = {"vendor": v.id, "item": item, "price": w.deal_price(w.sell_price(v, item), s, v), "stock": v.inv.count(item), "purse": s.coins, "at": w.minutes}
	s.plan.clear()
	w.brain._smith(s)
	var again := _buy(s)
	check(again.is_empty() or str(again.args.item) != item or int(again.args.vendor) != v.id,
		"a purchase refused with nothing changed since is not planned again within the hour (plan %s)" % str(again.get("args", {})))
	w.dispose()


func case_save_load_and_replay() -> void:
	var t := setup()
	var w: World = t.w
	var s: NPC = t.s
	_purse(w, s, 200)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var s2 := w2.npc(s.id)
	s.plan.clear()
	s2.plan.clear()
	w.brain._smith(s)
	w2.brain._smith(s2)
	check(JSON.stringify(_buy(s)) == JSON.stringify(_buy(s2)) and not _buy(s).is_empty(), "after a save and load the smith plans the same purchase (%s)" % str(_buy(s2).get("args", {})))
	var a := setup()
	var b := setup()
	_purse(a.w, a.s, 0)
	_purse(b.w, b.s, 0)
	(a.s as NPC).plan.clear()
	(b.s as NPC).plan.clear()
	a.w.brain._smith(a.s)
	b.w.brain._smith(b.s)
	check(JSON.stringify((a.s as NPC).plan) == JSON.stringify((b.s as NPC).plan), "two identical worlds give the same plan (deterministic)")
	w.dispose()
	w2.dispose()
	a.w.dispose()
	b.w.dispose()
