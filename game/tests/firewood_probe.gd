extends SceneTree
## X20-FIREWOOD investigation probe (read only): steps the real World as economy_sim does (same seed, same 0.5 s step, the
## inert player kept fed, brain.track_misses on) and prints, once a game day, the chain from iron to axes to woodcutters to
## firewood: the woodcutters (with and without an axe), the woodcutter places open and grown trees, the manor's tool orders
## (smith, tool, for whom, age), each smith's coins, ore, coal, bars, planks and axes, what the raw-goods merchants hold, the
## OD-16/EQ-19 statistics, the skill and station refusals of the forging recipes, logs held and the cold households; and every
## note of a woodcutter leaving the trade. Changes nothing in the world.
##   godot --headless --path game --script res://tests/firewood_probe.gd -- --days 60 [--seed 1] [--from 0]

const STEP := 0.5
var w: World
var wc_prev := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: String) -> String:
		return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback
	var days := int(arg.call("--days", "60"))
	var seed := int(arg.call("--seed", "1"))
	var from := int(arg.call("--from", "0"))
	GameData.ensure()
	w = World.new()
	w.setup(VillageMap.load_default(), seed)
	w.brain.track_misses = true
	w.event.connect(_on_event)
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for d in days:
		for i in per_day:
			w.update(STEP)
			w.player.hunger = 100.0
		if d + 1 >= from:
			print("AXE " + JSON.stringify(_line(d + 1)))
	quit(0)


func _on_event(t: String) -> void:
	if (" leaves work as a woodcutter" in t) or (" loses the work as woodcutter" in t) or ("woodcutter" in t and "has died" in t) \
			or ("retired in old age" in t and "woodcutter" in t) or "The manor cannot fill" in t:
		print("NOTE d%d %s" % [w.day(), t])


func _st(k: String) -> int:
	return int(w.stats.get(k, 0.0))


func _line(day: int) -> Dictionary:
	var wc := 0
	var wc_axe := 0
	var wc_coins := []
	var smiths := []
	var raw := {"iron_ore": 0, "coal": 0, "iron_bar": 0, "axe": 0}
	var goods_axes := 0
	var axes_others := 0
	var carp_planks := 0
	var now := {}
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		if n.job == "woodcutter":
			wc += 1
			now[n.id] = true
			if n.inv.has("axe"):
				wc_axe += 1
			else:
				wc_coins.append([n.id, n.coins, w.brain.tool_price(n, "axe"), not w.brain._order_for(n).is_empty()])
		elif n.inv.has("axe"):
			axes_others += n.inv.count("axe")
		if n.job == "smith":
			smiths.append([n.id, n.level("smithing"), n.coins, n.inv.count("iron_ore"), n.inv.count("coal"), n.inv.count("iron_bar"),
				n.inv.count("plank"), n.inv.count("axe"), n.inv.count("pickaxe"), n.doing])
		var role: String = w.brain.buy_role(n)
		if role == "merchant_raw":
			for k in raw:
				raw[k] += n.inv.count(k)
		if role == "merchant_goods":
			goods_axes += n.inv.count("axe")
		if n.job == "carpenter":
			carp_planks += n.inv.count("plank")
	var left := []
	for id in wc_prev:
		if not now.has(id):
			var o := w.npc(int(id))
			left.append([id, o.job if o != null else "?", o.alive if o != null else false, o.role if o != null else "?", o.inv.has("axe") if o != null else false])
	wc_prev = now
	var orders := []
	for x in w.manor_orders:
		orders.append([int(x.smith), str(x.tool), int(x["for"]), w.day() - int(x.day)])
	var trees := 0
	for t in w.trees:
		if t.state == "grown":
			trees += 1
	var reserve: float = w.brain.daily_obligations() * float(GameData.b("treasury_reserve_days"))     # (job_market's own formulas, without calling it)
	var manor_open: int = maxi(0, int((w.treasury - reserve) / (float(w.brain.manor_hand_wage()) * float(GameData.b("manor_hire_runway_days")))))
	var logs := 0
	for hh in w.households:
		if not hh.get("ended", false):
			logs += (hh.pantry as Inventory).count("log")
	var wood_logs := 0
	for n: NPC in w.npcs:
		if n.alive and n.job in ["woodcutter", "carpenter", "merchant"]:
			wood_logs += n.inv.count("log")
	var st := {}
	for k in w.stats:
		var s := str(k)
		if s.begins_with("gov_tool") or s.begins_with("skill_short_forge") or s.begins_with("skill_short_smelt") or s in ["station_busy_anvil", "station_busy_forge", "wage_offers_raised"]:
			st[s] = int(w.stats[k])
	return {"day": day, "wc": wc, "wc_axe": wc_axe, "wc_no_axe": wc_coins, "wc_open": maxi(0, trees / int(GameData.b("trees_per_woodcutter")) - wc), "trees": trees, "left": left,
		"manor_open": manor_open, "treasury": w.treasury, "orders": orders, "smiths": smiths, "raw": raw, "goods_axes": goods_axes,
		"axes_others": axes_others, "carp_planks": carp_planks, "hh_logs": logs, "seller_logs": wood_logs, "cold": _st("cold_cash_lt3") + _st("cold_cash_3_19") + _st("cold_cash_20_99") + _st("cold_cash_100up"),
		"deposits": w.deposits.filter(func(d): return str(d.ore) in ["iron_ore", "coal"]).reduce(func(a: int, d) -> int: return a + int(d.amount), 0), "st": st}
