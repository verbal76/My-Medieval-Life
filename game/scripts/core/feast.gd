class_name Feast
extends RefCounted
## DVW-B3-FEAST (owner, 2026-10-23, docs/directives/2026-10-23_owner_answers_coin_sinks.md): wedding feasts and seasonal feasts at
## the tavern, a coin sink people enjoy. A household (or the player) pays the tavern keeper for plates of food and ale out of the
## keeper's real stock; the guests who came eat and drink them.
##
## Money and goods: nothing is made. The host pays the keeper through World.trade (coins and goods move together, or nothing
## does), the goods are then eaten and drunk at once (hunger rises by the food value, the stats `eaten_<item>` and `eaten_food`
## are counted, as for a meal at the counter). There is no fund and no stored table, so there is nothing in the ledgers to add.
## The size of the feast follows the purse: guests are dropped until the host can pay (above the host's OD-19 reserve and at most
## spend_share of it), and below min_guests there is no feast (a household that cannot afford one does not hold it: WDR-022). The
## keeper never sells more than stock_share of any one item to a feast, so it cannot empty the tavern of the village's meals.
## Weddings: a wedding is the moment two people become partners (Relations.propose, Life.partner_player); this village has no
## other marriage rite. The couple's household(s) hold the feast on a later evening (wedding_delay_days .. wedding_window_days),
## the player's own wedding is paid for by the player at the counter (the partner and their household come, the player decides).
## Seasonal feasts: on the first day of the seasons named in `seasonal_seasons`, a household that can afford it and is fed may
## hold one (seasonal_chance), by a roll from the world seed, the day and the household (no shared random stream).
## Day: plan_day (17:00) chooses the feasts and who is asked; from 18:00 each invited person goes to the tavern yard (plan_attend,
## called from NPCBrain.decide); resolve (20:00) buys and feeds those who are there. A host who is not there, or too few guests,
## calls the feast off and nothing is paid. Saved in the World's optional key "feast"; a save without it starts empty.

const KEY := "feast"
const PLAYER := -2                    # Life.PLAYER_ID

var w: World
var weddings: Array = []              # {a, b, day, done}: partnerships awaiting their feast (a may be the player, PLAYER)
var plans: Array = []                 # today's feasts: {kind, host, invited: [ids], wedding: index or -1}
var planned_day := -1


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("feast")


# ---------------------------------------------------------------- weddings -------------------
## Two people have just become partners (Relations.propose): their wedding feast is owed. `a` may be the player (PLAYER).
func on_partnered(a: int, b: int) -> void:
	weddings.append({"a": a, "b": b, "day": w.day(), "done": false})
	w.stat("feast_weddings_due")
	if a == PLAYER or b == PLAYER:
		var other: NPC = w.npc(b if a == PLAYER else a)
		if other != null:
			w.note("You and %s may hold a wedding feast: ask the tavern keeper on an evening when %s family have come to the tavern." % [other.name, other.name + "'s"])


# ---------------------------------------------------------------- the day --------------------
func _is_season_start(day: int) -> bool:
	var seasons: Array = cfg().seasonal_seasons
	var t := float(day) * World.DAY
	return Life.day_of_year(t) == _season_first_day(Life.season_index(t)) and seasons.has(Life.season(t))


static func _season_first_day(idx: int) -> int:
	var lens: Array = GameData.b("calendar").season_days
	var d := 0
	for i in idx:
		d += int(lens[i])
	return d


## One uniform number 0..1 for (salt, a) today, from the world seed alone: the same village rolls the same, whatever else ran.
func _roll(salt: int, a: int) -> float:
	var r := RandomNumberGenerator.new()
	r.seed = int(w.seed) * 1000003 + w.day() * 7919 + a * 104729 + salt * 1299709 + 17
	return r.randf()


## 17:00: choose today's feasts and who is asked. Idempotent per day.
func plan_day() -> void:
	if planned_day == w.day():
		return
	planned_day = w.day()
	plans = []
	var keeper: NPC = w.tavern_keeper()
	if keeper == null:
		return
	var c := cfg()
	var hosts_today := {}                                  # household -> true: one feast a household a day
	for i in weddings.size():
		var wd: Dictionary = weddings[i]
		if bool(wd.done):
			continue
		var age: int = w.day() - int(wd.day)
		if age > int(c.wedding_window_days):
			wd.done = true
			w.stat("feast_wedding_lapsed")
			continue
		if age < int(c.wedding_delay_days):
			continue
		_plan_wedding(i, keeper, hosts_today)
	if _is_season_start(w.day()):
		for hh in w.households:
			if plans.size() >= int(c.max_feasts_a_day):
				break
			var hi: int = int(hh.id)
			if hosts_today.has(hi) or _roll(1, hi) >= float(c.seasonal_chance):
				continue
			_plan_seasonal(hi, keeper, hosts_today)


func _alive_adult(id: int) -> NPC:
	var n: NPC = w.npc(id)
	return n if n != null and n.alive and n.role == "adult" and n.clan == "" else null


## Who may be asked to a feast: living, not a bandit or a bandit's dependant, not on duty at the tavern or as a guard.
func _can_come(n: NPC) -> bool:
	return n != null and n.alive and n.role != "bandit" and n.clan == "" and n.job != "guard" and n.job != "tavernkeeper" and n.depth == 0


func _members_of(hi: int) -> Array:
	var out := []
	if hi >= 0 and hi < w.households.size():
		var ids: Array = (w.households[hi].members as Array).duplicate()
		ids.sort()
		for id in ids:
			var n: NPC = w.npc(int(id))
			if _can_come(n):
				out.append(n.id)
	return out


## The friends of `id` by regard, best first (ties broken by id), excluding `skip`; at most `limit`.
func _friends_of(id: int, limit: int, skip: Array) -> Array:
	var found := []
	for k in w.relations.ties:
		var ids: PackedStringArray = str(k).split(":")
		var a := int(ids[0])
		var b := int(ids[1])
		if a != id and b != id:
			continue
		var t: Dictionary = w.relations.ties[k]
		var o := b if a == id else a
		if bool(t.friends) and o >= 0 and not skip.has(o) and _can_come(w.npc(o)):
			found.append([-float(t.regard), o])
	found.sort()
	var out := []
	for f in found:
		if out.size() < limit:
			out.append(int(f[1]))
	return out


## The richest adult of the given households by free coins (coins above their reserve), ties by id; null if none.
func _richest(members: Array) -> NPC:
	var best: NPC = null
	var bf := -1
	for id in members:
		var n := _alive_adult(int(id))
		if n == null:
			continue
		var f := free_coins(n)
		if f > bf:
			bf = f
			best = n
	return best


func free_coins(n: NPC) -> int:
	return maxi(0, n.coins - w.reserve_of(n))


func _fed(hi: int) -> bool:
	return hi < 0 or w.brain.household_food_days(hi) >= float(cfg().min_food_days)


func _plan_wedding(i: int, keeper: NPC, hosts_today: Dictionary) -> void:
	var wd: Dictionary = weddings[i]
	var a: int = int(wd.a)
	var b: int = int(wd.b)
	var c := cfg()
	var na: NPC = w.npc(a) if a != PLAYER else null
	var nb: NPC = w.npc(b) if b != PLAYER else null
	var other: NPC = nb if a == PLAYER else na
	if a == PLAYER or b == PLAYER:
		other = nb if a == PLAYER else na
		if other == null or not other.alive or w.player.partner != other.id:
			wd.done = true
			return
		var guests := [other.id]
		for id in _members_of(other.household):
			if not guests.has(id):
				guests.append(id)
		for id in _friends_of(other.id, int(c.wedding_friends), guests):
			guests.append(id)
		plans.append({"kind": "wedding", "host": PLAYER, "invited": guests, "wedding": i})
		return
	if na == null or nb == null or not na.alive or not nb.alive or na.partner != nb.id:
		wd.done = true                                    # a death or a parting before the feast: none is held
		return
	var hs := [na.household]
	if nb.household != na.household:
		hs.append(nb.household)
	var members := []
	for hi in hs:
		for id in _members_of(int(hi)):
			if not members.has(id):
				members.append(id)
	var host := _richest(members)
	if host == null or hosts_today.has(host.household) or plans.size() >= int(c.max_feasts_a_day):
		return
	if not _fed(host.household):
		w.stat("feast_skipped_hungry")
		return
	var invited: Array = members.duplicate()
	for id in _friends_of(na.id, int(c.wedding_friends), invited):
		invited.append(id)
	if not _affordable(host, invited, "wedding", keeper):
		w.stat("feast_unaffordable")
		return
	hosts_today[host.household] = true
	plans.append({"kind": "wedding", "host": host.id, "invited": invited, "wedding": i})


func _plan_seasonal(hi: int, keeper: NPC, hosts_today: Dictionary) -> void:
	var c := cfg()
	var members := _members_of(hi)
	var host := _richest(members)
	if host == null or free_coins(host) < int(c.seasonal_min_free_coins) or not _fed(hi):
		return
	var invited: Array = members.duplicate()
	for id in _friends_of(host.id, int(c.seasonal_friends), invited):
		invited.append(id)
	if not _affordable(host, invited, "seasonal", keeper):
		w.stat("feast_unaffordable")
		return
	hosts_today[hi] = true
	plans.append({"kind": "seasonal", "host": host.id, "invited": invited, "wedding": -1})


func _affordable(host: NPC, invited: Array, kind: String, keeper: NPC) -> bool:
	var order := _order(host, invited)
	return not _fit(host, order, kind, keeper, _budget(host, kind)).is_empty()


func _budget(host: NPC, kind: String) -> int:
	var share := float(cfg().wedding_spend_share if kind == "wedding" else cfg().seasonal_spend_share)
	return mini(host.coins, floori(float(free_coins(host)) * share))


## Host first, then the rest by id (those dropped for want of money are the last asked).
func _order(host: NPC, invited: Array) -> Array:
	var rest := invited.duplicate()
	rest.sort()
	var out := [host]
	for id in rest:
		if int(id) != host.id:
			var n: NPC = w.npc(int(id))
			if n != null:
				out.append(n)
	return out


# ---------------------------------------------------------------- the evening ----------------
func venue() -> Vector2i:
	var counters: Array = w.stations_of("tavern_counter")
	if counters.is_empty():
		return Vector2i.ZERO
	return w.station_use(counters[0]) + Vector2i(-6, 4)


## Called from NPCBrain.decide: between the end of work and the feast, an invited villager walks to the tavern yard and waits.
func plan_attend(n: NPC) -> bool:
	if plans.is_empty() or planned_day != w.day():
		return false
	var h := w.hour()
	var rh := float(cfg().resolve_hour)
	if h < NPCBrain.WORK_END or h >= rh:
		return false
	for p in plans:
		if (p.invited as Array).has(n.id) and n.depth == 0 and n.role != "bandit":
			n.doing = "going to a feast at the tavern"
			n.plan = [w.brain.go(w.brain.wander_cell(venue(), 3)), w.brain.work((rh + 0.1 - h) * 60.0, "", {}, "idle")]
			return true
	return false


func _present(ids: Array) -> Array:
	var out := []
	var v := Vector2(venue())
	var r := float(cfg().near_tiles)
	for id in ids:
		var n: NPC = w.npc(int(id))
		if n != null and n.alive and n.depth == 0 and not w.asleep(n) and n.pos.distance_to(v) <= r:
			out.append(n)
	return out


## 20:00: every feast of the day is bought and eaten, or called off.
func resolve() -> void:
	if planned_day != w.day():
		return
	var keeper: NPC = w.tavern_keeper()
	for p in plans:
		if int(p.host) == PLAYER:
			w.stat("feast_player_unhosted")           # the player did not pay: nothing is bought
			continue
		var host: NPC = w.npc(int(p.host))
		var kind: String = p.kind
		if keeper == null or host == null or not host.alive:
			w.stat("feast_called_off")
			continue
		var present := _present(p.invited)
		if not present.has(host):
			w.stat("feast_called_off")
			continue
		var order := [host]
		var ids := []
		for g: NPC in present:
			if g != host:
				ids.append(g.id)
		ids.sort()
		for id in ids:
			order.append(w.npc(int(id)))
		var q := _fit(host, order, kind, keeper, _budget(host, kind))
		if q.is_empty():
			w.stat("feast_called_off_cost")
			continue
		var done := _serve(host, q, keeper)
		if done.guests > 0:
			w.stat("feast_" + kind)
			if int(p.wedding) >= 0:
				weddings[int(p.wedding)].done = true
			if kind == "wedding":
				w.note("%s %s hold a wedding feast at the tavern." % [host.name, host.family])
			else:
				w.note("%s %s hold a seasonal feast at the tavern." % [host.name, host.family])
	plans = []


# ---------------------------------------------------------------- buying and eating ----------
func _menu(kind: String) -> Array:
	return cfg().wedding_menu if kind == "wedding" else cfg().seasonal_menu


## What the keeper would sell for the guests in `order` (host first): one plate each, from the menu in order of preference while
## the keeper's share of that dish lasts, and ale for the grown (ale_per_adult); prices fixed at the start (the host's deal price).
## {items: {id: qty}, prices, rations: [[guest, dish, ale]], cost}. Guests who get nothing are not counted.
func _quote(host, order: Array, kind: String, keeper: NPC) -> Dictionary:
	var c := cfg()
	var menu: Array = _menu(kind)
	var stock := {}
	var prices := {}
	for id in menu + ["ale"]:
		stock[id] = floori(float(keeper.inv.count(id)) * float(c.stock_share))
		if stock[id] > 0:
			prices[id] = w.deal_price(w.sell_price(keeper, id), host, keeper)
	var items := {}
	var rations := []
	var cost := 0
	for g in order:
		var dish := ""
		for d in menu:
			if int(stock[d]) > 0:
				dish = d
				break
		if dish == "":
			break
		var ale := 0 if (g is NPC and g.role == "child") else mini(int(c.ale_per_adult), int(stock["ale"]))
		stock[dish] = int(stock[dish]) - 1
		stock["ale"] = int(stock["ale"]) - ale
		items[dish] = int(items.get(dish, 0)) + 1
		cost += int(prices[dish])
		if ale > 0:
			items["ale"] = int(items.get("ale", 0)) + ale
			cost += ale * int(prices["ale"])
		rations.append([g, dish, ale])
	return {"items": items, "prices": prices, "rations": rations, "cost": cost}


## The largest feast for the first guests of `order` that fits `budget` and has at least min_guests, or {}.
func _fit(host, order: Array, kind: String, keeper: NPC, budget: int) -> Dictionary:
	var minimum := int(cfg().min_guests)
	for k in range(order.size(), 0, -1):
		var q := _quote(host, order.slice(0, k), kind, keeper)
		if q.rations.size() >= minimum and int(q.cost) <= budget:
			return q
	return {}


## Pay the keeper for what the quote lists and feed the guests their plates; items that cannot be bought (a full pack) feed nobody.
## {guests, coins}.
func _serve(host, q: Dictionary, keeper: NPC) -> Dictionary:
	var bought := {}
	var paid := 0
	var ids: Array = (q.items as Dictionary).keys()
	ids.sort()
	for id in ids:
		var qty: int = int(q.items[id])
		var price: int = int(q.prices[id])
		if w.trade(host, keeper, id, qty, price):
			host.inv.remove(id, qty)                   # eaten and drunk on the spot
			bought[id] = qty
			paid += qty * price
			w.stat("eaten_" + id, qty)
			w.stat("feast_item_" + id, qty)
	if paid > 0:
		w.deal_xp(host, keeper, paid)
	var fed := 0
	for r in q.rations:
		var pts := 0.0
		var any := false
		for part in [[r[1], 1], ["ale", int(r[2])]]:
			if int(part[1]) > 0 and bought.has(part[0]):
				pts += float(GameData.item(part[0]).food) * int(part[1])
				any = true
		if any:
			var g = r[0]
			g.hunger = minf(100.0, g.hunger + pts)
			w.stat("eaten_food", pts)
			fed += 1
	w.stat("feast_guests", fed)
	w.stat("feast_coins", paid)
	return {"guests": fed, "coins": paid}


# ---------------------------------------------------------------- the player -----------------
func _player_wedding_plan() -> Dictionary:
	if planned_day != w.day():
		return {}
	for p in plans:
		if int(p.host) == PLAYER:
			return p
	return {}


## Whether the tavern keeper can take a feast now (the evening, the keeper there).
func player_open() -> bool:
	var h := w.hour()
	return w.tavern_keeper() != null and h >= NPCBrain.WORK_END and h < NPCBrain.SLEEP - 0.5


## The player's feast set up: {ok, text, q, order, kind}. kind "wedding": the player's partner's family who have come; otherwise
## the villagers in the tavern yard, nearest first, up to `size` guests besides the player.
func _player_setup(kind: String, size: int) -> Dictionary:
	var keeper: NPC = w.tavern_keeper()
	if keeper == null or not player_open():
		return {"ok": false, "text": "The tavern keeper only lays on a feast in the evening."}
	var guests := []
	if kind == "wedding":
		var p := _player_wedding_plan()
		if p.is_empty():
			return {"ok": false, "text": "There is no wedding feast to hold tonight."}
		guests = _present(p.invited)
		if not guests.any(func(g): return g.id == w.player.partner):
			return {"ok": false, "text": "Your partner has not come to the tavern yet."}
		guests = guests.slice(0, int(cfg().wedding_friends) + 8)
	else:
		guests = _present(w.npcs.map(func(n): return n.id))
		guests = guests.filter(func(g): return g != keeper and g.role != "bandit" and g.clan == "")
		var v := Vector2(venue())
		guests.sort_custom(func(a, b): return a.pos.distance_to(v) < b.pos.distance_to(v) if a.pos.distance_to(v) != b.pos.distance_to(v) else a.id < b.id)
		guests = guests.slice(0, size)
	if guests.is_empty():
		return {"ok": false, "text": "There is nobody here to feast with."}
	var order := [w.player] + guests
	var q := _fit(w.player, order, kind, keeper, w.player.coins)
	if q.is_empty():
		return {"ok": false, "text": "You cannot pay for a feast just now, or the keeper has too little to lay on (the tavern sets aside only part of its stock)."}
	return {"ok": true, "q": q, "order": order, "kind": kind, "keeper": keeper}


## The feasts the player may hold at the counter now: [{label, kind, size}], each priced by what the keeper would charge.
func player_choices() -> Array:
	var out := []
	if not player_open():
		return out
	var wed := _player_setup("wedding", 0)
	if wed.ok:
		out.append({"label": "Hold our wedding feast (%d coins, %d at the table)" % [int(wed.q.cost), wed.q.rations.size()], "kind": "wedding", "size": 0})
	var last := 0
	for size in cfg().player_sizes:
		var s := _player_setup("seasonal", int(size))
		if s.ok and s.q.rations.size() > last and s.q.rations.size() > 1:
			last = s.q.rations.size()
			out.append({"label": "Stand a feast for the room (%d coins, %d at the table)" % [int(s.q.cost), s.q.rations.size()], "kind": "seasonal", "size": int(size)})
	return out


## The player pays for a feast: {ok, text}. Coins go to the keeper, the plates are eaten by those at the table.
func player_feast(kind: String, size: int) -> Dictionary:
	var s := _player_setup(kind, size)
	if not s.ok:
		return s
	var done := _serve(w.player, s.q, s.keeper)
	if done.guests <= 0:
		return {"ok": false, "text": "The keeper could not lay the table."}
	var reg := float(cfg().player_regard)
	for g in s.order:
		if g is NPC:
			w.relations._raise(w.relations.tie(PLAYER, g.id), reg, 0.0, true, Vector2i(PLAYER, g.id))
	w.stat("feast_player")
	if kind == "wedding":
		var p := _player_wedding_plan()
		weddings[int(p.wedding)].done = true
		w.stat("feast_wedding")
		plans.erase(p)
		return {"ok": true, "text": "You pay %d coins to the tavern keeper, and %d sit down to your wedding feast." % [done.coins, done.guests]}
	w.stat("feast_seasonal")
	return {"ok": true, "text": "You pay %d coins to the tavern keeper, and %d sit down to eat and drink." % [done.coins, done.guests]}


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	return {"weddings": weddings.duplicate(true), "plans": plans.duplicate(true), "planned_day": planned_day}


func load_dict(d: Dictionary) -> void:
	weddings = []
	for wd in d.get("weddings", []):
		weddings.append({"a": int(wd.a), "b": int(wd.b), "day": int(wd.day), "done": bool(wd.get("done", false))})
	plans = []
	for p in d.get("plans", []):
		plans.append({"kind": str(p.kind), "host": int(p.host), "invited": (p.invited as Array).map(func(v): return int(v)), "wedding": int(p.get("wedding", -1))})
	planned_day = int(d.get("planned_day", -1))
