class_name RegionTrade
extends RefCounted
## REGION-NAV-01 S6, independent trade between the village and its neighbours (plan AD-6; owner 2026-11-02: "No instant inventory
## transfers between villages"; trade is the tradesperson's own decision). Each dawn a few village tradespeople (`per_day`, in
## villager order) weigh the fresh records they were told (Intel: NPC.intel, never the reeve's book directly):
##
##   buy in person   a record that a place has something their trade buys (NPCBrain.wants beyond what they hold, and nobody in
##                   the village sells it, Contracts._vendor): they weigh the reported price plus the walk (the trip's days of a
##                   day wage, `day_value`) against the item's local price; with the gain positive and their own coins above
##                   their reserve (World.reserve_of) paying for it, they walk there (Journeys, purpose "buy") and buy from that
##                   person at the site (SettlementFolk.buy_from: the settlement's books, deal on its side). Gone by the time
##                   they arrive (sale_cap 0, or the person away): nothing is bought and the record is marked out of date.
##   sell by courier a record that a place wants something they make (NPCBrain.TRADE_GOODS) and they hold more than they keep: by
##                   the courier's regular route from their booth (CourierService.book_route, the flat fee), asking the reported
##                   price; on arrival the party takes it only if its books still want it at no more than its price
##                   (CourierService._region_takes), else the goods come back. The courier's own rules: nothing at once.
## Nobody is made to trade: no fresh record, no gain, no funds, no trade. Nothing is created: every coin and good moves through
## the existing transfers (SettlementFolk, CourierService), so the village's ledgers and the settlements' audits hold.

static func cfg() -> Dictionary:
	var c: Dictionary = OffMapSettlement.data().get("trade", {})
	return {"per_day": int(c.get("per_day", 3)), "day_value": int(c.get("day_value", 4)), "min_gain": int(c.get("min_gain", 2)),
		"buy_max": int(c.get("buy_max", 6))}


## Dawn (World): a few tradespeople weigh what they were told.
static func dawn(w: World) -> void:
	if w.regions == null or w.map.overworld == null:
		return
	var done := 0
	for n: NPC in w.npcs:
		if done >= int(cfg().per_day):
			return
		if not n.alive or n.role != "adult" or n.intel.is_empty() or Journeys.active(n) or not w.manor_work.job_of(World.npc_ref(n.id)).is_empty():
			continue
		if consider(w, n) != "":
			done += 1


## What `n` decides to do with what they know: "buy" (set off), "sell" (booked), or "" (nothing worth it).
static func consider(w: World, n: NPC) -> String:
	var buy := best_buy(w, n)
	if not buy.is_empty():
		if Journeys.start(w, n, str(buy.place), {"kind": "buy", "about": str(buy.about), "item": str(buy.item), "qty": int(buy.qty), "price": int(buy.price)}) == "":
			w.stat("region_trade_trips")
			return "buy"
	if sell(w, n):
		return "sell"
	return ""


## The best purchase `n` would walk for: {place, about, item, qty, price, gain}, or {}.
static func best_buy(w: World, n: NPC) -> Dictionary:
	var c := cfg()
	var ints := Intel.interests(w, n)
	var spare := n.coins - w.reserve_of(n)
	var best := {}
	for r in n.intel:
		if not Intel.fresh(w, r) or str(r.side) != "have" or str(ints.get(str(r.item), "")) != "buys":
			continue
		var id := str(r.item)
		var want: int = mini(w.brain.wants(n, id) - n.inv.count(id), int(c.buy_max))
		if want <= 0 or w.contracts._vendor(n, id) != null:
			continue
		var price := int(r.price)
		var qty := mini(want, int(r.qty))
		if price > 0:
			qty = mini(qty, spare / price)
		if qty <= 0:
			continue
		var walk := int(ceil(2.0 * Envoys.trip_days(w, str(r.place)) + 1.0)) * int(c.day_value)
		var gain := qty * (World.buy_price_at(id, 0) - price) - walk
		if gain < int(c.min_gain):
			continue
		if best.is_empty() or gain > int(best.gain):
			best = {"place": str(r.place), "about": str(r.about), "item": id, "qty": qty, "price": price, "gain": gain}
	return best


## World.journey_hook for a buying trip: at the site, go to the person and buy. True when that gave them work.
static func at_site(w: World, n: NPC) -> bool:
	var p: Dictionary = n.journey.get("purpose", {})
	if str(p.get("kind", "")) != "buy" or bool(p.get("done", false)):
		return false
	var hr := w.hour()
	if hr < float(SettlementFolk.WORK_FROM) or hr + 0.5 >= float(SettlementFolk.WORK_TO):
		n.doing = "waiting for the morning to buy"
		n.plan = [w.brain.work(30.0, "", {}, "idle")]
		return true
	var who := {}
	for q in SettlementFolk.people(w, str(n.journey.to)):
		if str(q.ref) == str(p.about):
			who = q
	if who.is_empty():
		_out_of_date(w, n, p, "gone")
		return false
	n.doing = "buying %s from %s" % [GameData.item_name(str(p.item)).to_lower(), who.name]
	n.plan = [w.brain.go(Vector2i(who.spot) + Vector2i(0, 1)), w.brain.work(10.0, "region_buy", {}, "talk")]
	return true


## The brain's act at the seller: as much as the person will sell, the buyer can pay and wants, up to what they set out for.
static func act_buy(w: World, n: NPC) -> bool:
	var p: Dictionary = n.journey.get("purpose", {})
	if str(p.get("kind", "")) != "buy" or bool(p.get("done", false)):
		return true
	p.done = true
	var who := {}
	for q in SettlementFolk.people(w, str(n.journey.to)):
		if str(q.ref) == str(p.about):
			who = q
	if who.is_empty() or not SettlementFolk.present(w, who):
		_out_of_date(w, n, p, "away")
		return true
	if n.pos.distance_to(Vector2(who.spot) + Vector2(0.5, 1.5)) > 3.0:
		_out_of_date(w, n, p, "could not reach them")            # (a trade is made face to face, never from afar)
		return true
	var party: SettlementParty = w.regions.party(str(who.ref))
	var s: OffMapSettlement = w.regions.by_id[str(n.journey.to)]
	var price: int = s.price(str(p.item))
	var qty: int = mini(int(p.qty), party.sale_cap(str(p.item)) if party != null else 0)
	if price > 0:
		qty = mini(qty, (n.coins - w.reserve_of(n)) / price)
	if qty <= 0:
		_out_of_date(w, n, p, "sold out" if party != null and party.sale_cap(str(p.item)) <= 0 else "too dear")
		return true
	var why := SettlementFolk.buy_from(w, World.npc_ref(n.id), who, str(p.item), qty)
	if why != "":
		_out_of_date(w, n, p, why)
		return true
	w.stat("region_trade_bought", qty)
	w.stat("region_trade_bought_" + str(p.item), qty)
	w.note("%s %s bought %d %s at %s." % [n.name, n.family, qty, GameData.item_name(str(p.item)).to_lower(), w.map.overworld.site(str(n.journey.to)).get("name", "")])
	return true


## The trip found the record no longer true: the buyer marks it so (not acted on again) and goes home with nothing bought.
static func _out_of_date(w: World, n: NPC, p: Dictionary, why: String) -> void:
	p.done = true
	for r in n.intel:
		if str(r.about) == str(p.about) and str(r.item) == str(p.item) and str(r.side) == "have":
			r.kind = "out_of_date"
			r.why = why
	w.stat("region_trade_out_of_date")


## A sale by the courier's route: the record of a place wanting what `n` makes and holds beyond what they keep. True if booked.
static func sell(w: World, n: NPC) -> bool:
	var cs: CourierService = w.couriers
	if cs == null:
		return false
	var me := World.npc_ref(n.id)
	if cs.jobs.any(func(j): return str(j.sender) == me and not str(j.state) in ["fulfilled", "returned", "interrupted"]):
		return false
	var ints := Intel.interests(w, n)
	var rc: Dictionary = CourierService.cfg().routes
	for r in n.intel:
		if not Intel.fresh(w, r) or str(r.side) != "want" or str(ints.get(str(r.item), "")) != "makes":
			continue
		var id := str(r.item)
		var extra := n.inv.count(id) - (1 if w.brain.keeps(n, id) else 0)
		var qty := mini(mini(extra, int(r.qty)), int(rc.load_units) * int(rc.loads_per_departure))
		if int(r.price) > 0:
			qty = mini(qty, int(CourierService.cfg().contracts.small_value) / int(r.price))      # (a payment above the line is a formal contract: not sent by route)
		if qty <= 0 or qty * int(r.price) <= int(rc.fee_per_load):
			continue
		var sb := cs.booth_of_keeper(me)
		if sb.is_empty():
			sb = cs.booth_of("village")
		var rt := {}
		for x in cs.routes:
			if str(x.from) == str(sb.get("id", "")) and str(cs.booth(str(x.to)).get("settlement", "")) == str(r.place):
				rt = x
		if rt.is_empty():
			continue
		var order := {"sender": me, "recipient": str(r.about), "recipient_kind": "business", "settlement": str(r.place), "items": {id: qty},
			"route": rt.id, "collect": {"kind": "coins", "amount": qty * int(r.price)}, "proceeds": "deliver", "intel": true}
		var job := cs.book_route(order)
		if not job.has("error"):
			w.stat("region_trade_sent")
			w.stat("region_trade_sent_" + id, qty)
			var ex: Dictionary = Envoys.book(w).get("exports", {})
			ex[n.job] = w.day()                          # S7: the day this trade last sent goods to a neighbouring place
			Envoys.book(w).exports = ex
			return true
	return false


## REGION-NAV-01 S7 (plan AD-7: regional demand reaches business founding only through real work; the 35 % gate unchanged): a
## founding is counted with its cause: "regional" when the founder's trade sent goods to a neighbouring place within the last
## `regional_days`, else "local".
static func note_founding(w: World, n: NPC) -> void:
	var last := int((Envoys.book(w).get("exports", {}) as Dictionary).get(n.job, -100000))
	var cause := "regional" if w.day() - last <= int(OffMapSettlement.data().get("trade", {}).get("regional_days", 30)) else "local"
	w.stat("ventures_founded_cause_" + cause)


## REGION-NAV-01 S7 measurement (the directive's Phase 7 and the B25-ECON P2/P3 findings; measured only, nothing decided):
##   busy        each crafting trade's busy share (NPCBrain.skilled_place: the share of a working day each worker spends at
##               its stations) against the founding gate (skilled_places.busy_share)
##   exports     the day each trade last sent goods to a neighbouring place, and the units sent and bought so far
##   foundings   ventures founded, by cause (regional, local)
##   p2_jobless_no_tool  adults with no job, no coins above their reserve and no tool, while a tool trade (NPCBrain.JOB_TOOL) has a
##               place open (the first-tool finding)
##   p3_idle_stock       trade goods (the crafting trades' inputs and products) held by elders and adults with no job, against
##               what the working holders of those trades hold (the retiree-stock finding)
static func measure(w: World) -> Dictionary:
	var out := {"day": w.day(), "busy": {}, "gate": float(GameData.b("skilled_places").busy_share), "exports": (Envoys.book(w).get("exports", {}) as Dictionary).duplicate(),
		"sent": int(w.stats.get("region_trade_sent", 0.0)), "bought": int(w.stats.get("region_trade_bought", 0.0)),
		"foundings": {"regional": int(w.stats.get("ventures_founded_cause_regional", 0.0)), "local": int(w.stats.get("ventures_founded_cause_local", 0.0))},
		"p2_jobless_no_tool": 0, "p3_idle_stock": 0, "p3_working_stock": 0}
	var jobs := NPCBrain.TRADE_STATIONS.keys()
	jobs.sort()
	for job in jobs:
		var any := false
		for o: NPC in w.npcs:
			if o.alive and o.role == "adult" and o.job == job:
				any = true
				break
		if any:
			out.busy[job] = snappedf(float(w.brain.skilled_place(job).busy), 0.001)
	var tool_open := false
	for job in NPCBrain.JOB_TOOL:
		if int(w.brain.skilled_place(job).open) > 0 or w.brain.open_posts(job) > 0:
			tool_open = true
	var goods := {}
	for job in jobs:
		for id in Intel.trade_products(job):
			goods[id] = true
		for id in NPCBrain.BUYS.get(job, {}):
			goods[str(id)] = true
	for o: NPC in w.npcs:
		if not o.alive:
			continue
		var idle := o.role == "elder" or (o.role == "adult" and o.job == "")
		if tool_open and o.role == "adult" and o.job == "" and o.coins <= w.reserve_of(o) and not o.inv.has("axe") and not o.inv.has("pickaxe"):
			out.p2_jobless_no_tool += 1
		var held := 0
		for id in goods:
			held += o.inv.count(str(id))
		if idle:
			out.p3_idle_stock += held
		elif o.role == "adult" and NPCBrain.TRADE_STATIONS.has(o.job):
			out.p3_working_stock += held
	return out
