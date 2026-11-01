class_name EconRepairs
extends RefCounted
## LE-05 paid commercial repair (owner directive 2026-10-31, docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md, LE-05 A:
## "Paid commercial repair services and their associated financial transactions may depend on the economy system"; register
## LE05-RENTAL-REPAIR, LE-05). Behind the Living Economy switch: built only with the economy, acting only with market.drive and
## market.paid_repair. Basic repair (World.work_repair: the player, a smith for itself and its household) is unchanged and stays
## normal play; this adds only the PAID path between a villager and a smith outside its household.
##
## The one rule (World.repair_terms, the same for everyone, PAR-01): the materials are the forge recipe's share of the wear, the
## minutes its share of the recipe's time. The PRICE (`quote`) is what the smith gives up, from existing measures only: those
## materials at the smith's own selling price (World.sell_price) plus the minutes at its own earnings a working minute
## (NPC.avg_income over the working day: the CON-01 travel/opportunity measure, Contracts.travel_per_unit). No new number.
##
## Who and when (event-driven, design s.14): a villager's tool that wears past balance repair.npc_min_missing (the share at which a
## smith mends its household's tools) in World._work_wear marks it a candidate (`on_wear`); at dawn, at most market.repair_per_dawn
## candidates (by ref) weigh paying a smith against doing without for now, through the shared engine (JudgmentWeighting, profile
## market_buy: the share of the tool's life gone, the price against its purse, its opinion of each smith). A household with a smith
## of its own is left to that smith (the existing free path). The smith's word is the rental owner's rule (market_sell): it may
## refuse. Paying is never preferred by rule; without the coins it is infeasible.
##
## Money: the agreed price leaves the customer's purse into ESCROW at the order (World.transactions.hold_coins; World.total_coins
## counts `escrow`), and is paid to the smith as earnings when the work is done (release_coins), or refunded when the order cannot be
## done in time, the tool went, or a party died (the customer's refund to its estate). The tool is mended where it lies, in its
## holder's pack (as a household's tools are, LE05-REPAIR): it keeps its holder, identity and ownership; nothing changes hands but
## coins. Deterministic (no RNG; sorted iteration); saved under economy "repairs", bounded (open orders, the last keep_closed closed,
## one candidate flag per villager).

const OPEN := "open"
const ENDS := ["done", "cancelled", "settled"]

var w: World
var f: EconomyFoundation
var cfg: Dictionary
var records := {}          # txid -> record (open ones, and the last keep_closed closed ones)
var candidates := {}       # customer ref -> true: a tool of its wore past the share (cleared when weighed)
var keep_closed := 30


func _init(foundation: EconomyFoundation, world: World, market_cfg: Dictionary) -> void:
	f = foundation
	w = world
	cfg = market_cfg


func active() -> bool:
	return bool(cfg.get("drive", false)) and bool(cfg.get("paid_repair", false))


func order_days() -> int:
	return maxi(1, int(cfg.get("repair_order_days", 3)))


static func min_share() -> float:
	return float(GameData.b("repair").get("npc_min_missing", 0.5))


# ------------------------------------------------------------------------------------------------ terms
## The price smith `s` asks to mend the worn `item` in `tool_inv`: the repair's materials at its own selling prices plus its
## minutes at its earnings a working minute, rounded up; 0 when nothing can be mended.
func quote(s: NPC, tool_inv: Inventory, item: String) -> int:
	var t := World.repair_terms(tool_inv, item)
	if t.is_empty():
		return 0
	var k := 0.0
	var ins: Array = (t["in"] as Dictionary).keys()
	ins.sort()
	for inp in ins:
		k += float(w.sell_price(s, str(inp))) * float(t["in"][inp])
	var per_minute := s.avg_income() / maxf(1.0, (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0)
	k += float(t.minutes) * per_minute
	return maxi(1, int(ceil(k - 0.000001)))


# ------------------------------------------------------------------------------------------------ reads
func open_records() -> Array:
	var ids: Array = records.keys()
	ids.sort()
	return ids.filter(func(id): return records[id].state == OPEN).map(func(id): return records[id])


## The open order for `customer`'s (a ref) `item`, {} none.
func open_for(customer: String, item: String) -> Dictionary:
	for r in open_records():
		if str(r.customer) == customer and str(r.item) == item:
			return r
	return {}


## Coins held in escrow by open orders (inside the village: World.total_coins counts them).
func escrow() -> int:
	var k := 0
	for r in open_records():
		k += int(r.price)
	return k


## Whether `n`'s household has a smith of its own (who mends the household's tools for nothing: the existing path).
func _has_own_smith(n: NPC) -> bool:
	if n.job == "smith":
		return true
	if n.household < 0:
		return false
	for o: NPC in w.npcs:
		if o.alive and o.household == n.household and o.job == "smith":
			return true
	return false


## The smiths who could mend `item` of customer `n` now: living adult smiths outside its household, at the recipe's Smithing level
## and holding the materials (World.repair_refusal), by id.
func smiths_for(n: NPC, item: String) -> Array:
	var out := []
	for s: NPC in w.npcs:
		if s.alive and s != n and s.job == "smith" and s.role == "adult" and (n.household < 0 or s.household != n.household) \
				and w.repair_refusal(s, item, n.inv, s.inv) == "":
			out.append(s)
	return out


## Whether smith `s` takes the order (the rental owner's rule, market_sell: its need for coin; the price at its own floor, 50
## points, since the quote is its cost; work it does not advertise, 50 points; its opinion of the customer). Refusal is valid.
func smith_willing(s: NPC, customer_ref: String, item: String) -> bool:
	var fs := {"necessity": JudgmentLive.coin_need(s), "price": 50000, "surplus": 50000}
	return str(f.market._weigh(s, "market_sell", customer_ref, fs, [w.day(), item.hash(), s.id, customer_ref.hash(), "repair".hash()]).chosen) == "deal"


# ------------------------------------------------------------------------------------------------ whether to pay
## World._work_wear: `who`'s `tool` wore. A villager's repairable tool past the share is a candidate for tomorrow's dawn.
func on_wear(who: Object, tool: String) -> void:
	if not (who is NPC) or not active():
		return
	var t := World.repair_terms(who.inv, tool)
	if not t.is_empty() and float(t.missing) >= min_share() * float(t.full):
		candidates[World.npc_ref((who as NPC).id)] = true


## Villager `n` weighs paying a smith to mend its worn `item` against doing without for now (the shared engine, market_buy).
## Returns {act: "repair" | "wait" | "none", smith}. "none": nothing to weigh (no smith able, its own household's smith, an order
## already open, nothing worn enough).
func consider(n: NPC, item: String) -> Dictionary:
	var me := World.npc_ref(n.id)
	if not active() or not n.alive or n.role != "adult" or not open_for(me, item).is_empty() or _has_own_smith(n):
		return {"act": "none"}
	var t := World.repair_terms(n.inv, item)
	if t.is_empty() or float(t.missing) < min_share() * float(t.full):
		return {"act": "none"}
	var coins := maxi(1, n.coins)
	var need := clampi(100000 * int(t.missing) / maxi(1, int(t.full)), 0, 100000)
	var cands := []
	var smiths := {}
	for s: NPC in smiths_for(n, item):
		var price := quote(s, n.inv, item)
		var c := {"id": "repair:%d" % s.id, "counterparty": f.actors.judged_person(World.npc_ref(s.id)),
			"factors": {"necessity": need, "price": clampi(100000 - 100000 * price / coins, 0, 100000)}}
		if w.claims_free_coins(n, item, false) < price:
			c["feasible"] = false
			c["why"] = "no_funds"
		elif not smith_willing(s, me, item):
			c["feasible"] = false
			c["why"] = "smith_unwilling"
		cands.append(c)
		smiths["repair:%d" % s.id] = [s, price]
	if smiths.is_empty():
		return {"act": "none"}
	var r := JudgmentWeighting.choose(w.judgment, f.market._judgment_cfg(), n.id, "market_buy", cands, [w.day(), item.hash(), n.id, "repair".hash()])
	var ch := str(r.chosen) if r.chosen != null else "forgo"
	w.stat("paid_repair_weighed")
	if ch.begins_with("repair:"):
		w.stat("paid_repair_chosen")
		return {"act": "repair", "smith": smiths[ch][0], "price": int(smiths[ch][1])}
	w.stat("paid_repair_forgone")
	return {"act": "wait"}


# ------------------------------------------------------------------------------------------------ the order
## An order: `customer` (a villager) pays smith `s` `price` to mend its worn `item`; the price into escrow by the authority. {ok, code, txid}.
func open(customer: NPC, s: NPC, item: String, price: int) -> Dictionary:
	if not active():
		return {"ok": false, "code": "off", "txid": ""}
	if customer == null or s == null or not customer.alive or not s.alive or price <= 0:
		return {"ok": false, "code": "unknown_party", "txid": ""}
	var cr := World.npc_ref(customer.id)
	if not open_for(cr, item).is_empty():
		return {"ok": false, "code": "already_ordered", "txid": ""}
	var tx: Dictionary = w.transactions.hold_coins(w.transactions.next_txid("repair"), cr, price, "repair")
	if not bool(tx.ok):
		w.stat("paid_repair_refused_" + str(tx.code))
		return tx
	records[str(tx.txid)] = {"txid": str(tx.txid), "customer": cr, "smith": World.npc_ref(s.id), "item": item, "price": price,
		"made_day": w.day(), "due_day": w.day() + order_days(), "state": OPEN, "closed_day": -1, "why": ""}
	w.stat("paid_repair_opened")
	w.stat("paid_repair_opened_" + item)
	return tx


## NPCBrain._smith: the first open order of smith `n` it can do now (by id), as {txid, holder: NPC, item}; {} none.
func job_for(n: NPC) -> Dictionary:
	if not active():
		return {}
	var me := World.npc_ref(n.id)
	for r in open_records():
		if str(r.smith) != me:
			continue
		var c := w.npc(World.ref_id(str(r.customer)))
		if c != null and c.alive and w.repair_refusal(n, str(r.item), c.inv, n.inv) == "":
			return {"txid": str(r.txid), "holder": c, "item": str(r.item)}
	return {}


## Whether order `txid` is open for smith `n` and customer `holder` (the brain's act checks it before the work).
func is_open(txid: String, n: NPC, holder: NPC) -> bool:
	var r: Dictionary = records.get(txid, {})
	return not r.is_empty() and str(r.state) == OPEN and str(r.smith) == World.npc_ref(n.id) and str(r.customer) == World.npc_ref(holder.id)


## The work is done (World.work_repair returned ok): the escrow is paid to the smith as its earnings.
func complete(txid: String) -> Dictionary:
	var r: Dictionary = records.get(txid, {})
	if r.is_empty() or str(r.state) != OPEN:
		return {"ok": false, "code": "not_open"}
	return _end(r, "done", "mended", str(r.smith), int(r.price))


## End order `r` once: `pay` of the escrow to `payee` (the smith), the rest refunded to `refund_to` (the customer, or its estate).
func _end(r: Dictionary, outcome: String, why: String, payee := "", pay := 0, refund_to := "") -> Dictionary:
	if str(r.state) != OPEN:
		return {"ok": false, "code": "not_open"}
	var to := refund_to if refund_to != "" else str(r.customer)
	var tx: Dictionary = w.transactions.release_coins(w.transactions.next_txid("repair_end"), payee, pay, to, int(r.price), "repair")
	if not bool(tx.ok):
		w.stat("paid_repair_end_refused_" + str(tx.code))
		return tx
	r.state = outcome
	r.closed_day = w.day()
	r.why = why
	w.stat("paid_repair_" + outcome)
	if pay > 0:
		w.stat("paid_repair_coins", float(pay))
	_prune()
	return tx


## World.kill: a customer who died is refunded to its estate; a smith who died leaves its orders undone, refunded to the customers.
func on_death(n: NPC) -> void:
	var me := World.npc_ref(n.id)
	candidates.erase(me)
	for r in open_records():
		if str(r.customer) == me:
			var est: Dictionary = w.transactions.estate_of(me)
			_end(r, "settled", "customer died", "", 0, str(est.get("ref", "")) if not est.is_empty() else "-")
		elif str(r.smith) == me:
			_end(r, "cancelled", "smith died")


## The market's dawn: open orders past their day, or whose tool went or is no longer worn, are refunded (all of them once the
## switch is off: nothing stays held for work that will not be done); then up to repair_per_dawn candidates (by ref) weigh an order.
func dawn(day: int) -> void:
	for r in open_records():
		var c := w.npc(World.ref_id(str(r.customer)))
		if c == null or not c.alive:
			continue                                   # (settled by on_death)
		if not active():
			_end(r, "cancelled", "paid repair switched off")
		elif World.repair_terms(c.inv, str(r.item)).is_empty():
			_end(r, "cancelled", "nothing left to mend")
		elif day > int(r.due_day):
			_end(r, "cancelled", "not done in time")
	if candidates.is_empty() or not active():
		candidates.clear()
		return
	var refs: Array = candidates.keys()
	refs.sort()
	var budget := maxi(1, int(cfg.get("repair_per_dawn", 6)))
	for ref in refs.slice(0, mini(budget, refs.size())):
		candidates.erase(ref)
		var n := w.npc(World.ref_id(str(ref)))
		if n == null or not n.alive:
			continue
		var ids: Array = n.inv.durability.keys()
		ids.sort()
		for id in ids:
			var ch := consider(n, str(id))
			if str(ch.act) == "repair":
				open(n, ch.smith, str(id), int(ch.price))


func _prune() -> void:
	var done: Array = records.keys().filter(func(id): return records[id].state != OPEN)
	if done.size() <= keep_closed:
		return
	done.sort_custom(func(a, b): return [int(records[a].closed_day), a] < [int(records[b].closed_day), b])
	for i in done.size() - keep_closed:
		records.erase(done[i])


# ------------------------------------------------------------------------------------------------ save
func is_empty() -> bool:
	return records.is_empty() and candidates.is_empty()


func to_dict() -> Dictionary:
	var ids: Array = records.keys()
	ids.sort()
	var rs := []
	for id in ids:
		rs.append((records[id] as Dictionary).duplicate())
	var cs: Array = candidates.keys()
	cs.sort()
	return {"records": rs, "candidates": cs}


func load_dict(d: Dictionary) -> void:
	records = {}
	candidates = {}
	for r in d.get("records", []):
		records[str(r.txid)] = {"txid": str(r.txid), "customer": str(r.customer), "smith": str(r.smith), "item": str(r.item),
			"price": int(r.price), "made_day": int(r.made_day), "due_day": int(r.due_day), "state": str(r.state),
			"closed_day": int(r.closed_day), "why": str(r.why)}
	for c in d.get("candidates", []):
		candidates[str(c)] = true


## LE-07 / activation: the coins a saved "repairs" section holds in escrow (open orders), for World.total_coins while the section is
## parked (economy off).
static func saved_escrow(d: Dictionary) -> int:
	var k := 0
	for r in d.get("records", []):
		if str(r.get("state", "")) == OPEN:
			k += int(r.get("price", 0))
	return k
