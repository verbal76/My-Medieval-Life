class_name EconRentals
extends RefCounted
## LE05-RENTAL (owner directive 2026-10-31, docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md, LE-05 B; behind the
## Living Economy switch: built only with the economy, acting only with market.drive and market.rental). A worker short of its
## trade's tool may RENT one: a willing owner with a spare lends it; the renter's deposit (the tool's value) is escrowed by the
## transaction authority (EconTransactions.lend); the fee is the value of the wear the renter's use consumes (the tool's value x the
## durability used / its full durability), billed each dawn for the wear so far; the tool goes back at the term's end or earlier.
## The record names the owner throughout (owner_of); the tool's wear travels with it (X20-WEAR-TRANSFER).
##
## Every end is one rule (end_rental through the authority, once): the renter pays for the wear it used, valued at the tool's value,
## from the escrow first; the rest of the deposit comes back. A tool that comes back (returned, the renter died holding it) goes to
## its owner with its wear. A tool that does not (broken in use, lost, stolen, sold or given away, not held at the term's end) was
## used up as far as the owner is concerned: the renter pays the whole of the durability it had when lent. An owner who dies is
## succeeded by its estate (EconTransactions.estate_of: its household, else the manor), which then receives the fees and the tool;
## a renter who dies is settled to its estate. Deterministic (no RNG; sorted iteration); saved under economy "rentals", bounded.

const OPEN := "open"
const ENDS := ["returned", "broken", "lost", "settled"]

var w: World
var f: EconomyFoundation
var cfg: Dictionary
var records := {}          # txid -> record (open ones, and the last keep_closed closed ones)
var considered := {}       # renter ref -> [day, act]: what it chose today (a worker weighs it once a day; saved, pruned at dawn)
var keep_closed := 30


func _init(foundation: EconomyFoundation, world: World, market_cfg: Dictionary) -> void:
	f = foundation
	w = world
	cfg = market_cfg


func active() -> bool:
	return bool(cfg.get("drive", false)) and bool(cfg.get("rental", false))


func term_days() -> int:
	return int(cfg.get("rental_days", 3))


# ------------------------------------------------------------------------------------------------ terms
## The deposit: the tool's value (a new one's), in whole coins.
static func deposit_for(item: String) -> int:
	return maxi(1, int(ceil(GameData.value(item))))


## The fee for `used` durability of `item`: the value that wear consumed, rounded up to whole coins.
static func fee_for(item: String, used: int) -> int:
	var full := int(GameData.item(item).get("durability", 0))
	if full <= 0 or used <= 0:
		return 0
	return int(ceil(GameData.value(item) * float(mini(used, full)) / float(full) - 0.000001))


## The durability a day's work wears off `item` (the existing work rates, World.work_mine / work_felled: a pickaxe 1 a swing of
## mine_minutes, an axe 3 a felling of chop_minutes, over the working day); 0 for a tool with no such rate.
static func daily_wear(item: String) -> float:
	var day := (NPCBrain.WORK_END - NPCBrain.WORK_START) * 60.0
	match item:
		"axe":
			return day / float(GameData.b("chop_minutes")) * 3.0
		"pickaxe":
			return day / float(GameData.b("mine_minutes")) * 1.0
	return 0.0


## The fee a renter expects to pay over a term (the value a term's work wears off, never more than the tool's value).
func expected_fee(item: String) -> int:
	var full := int(GameData.item(item).get("durability", 0))
	return fee_for(item, mini(full, int(ceil(daily_wear(item) * float(term_days())))))


# ------------------------------------------------------------------------------------------------ reads
func open_records() -> Array:
	var ids: Array = records.keys()
	ids.sort()
	return ids.filter(func(id): return records[id].state == OPEN).map(func(id): return records[id])


## The open rental of `item` held by `renter` (a ref), {} none.
func open_for(renter: String, item: String) -> Dictionary:
	for r in open_records():
		if str(r.renter) == renter and str(r.item) == item:
			return r
	return {}


## Who owns the unit of `item` that `holder` (a ref) has on rent, "" when it holds none on rent.
func owner_of(holder: String, item: String) -> String:
	return str(open_for(holder, item).get("owner", ""))


## Coins held in escrow by open rentals (inside the village: World.total_coins counts them).
func escrow() -> int:
	var k := 0
	for r in open_records():
		k += int(r.deposit)
	return k


# ------------------------------------------------------------------------------------------------ whether to rent
## How many of `item` `o` could lend: what it holds beyond what its own work keeps (its trade's tool, NPCBrain.keeps).
func spare(o: NPC, item: String) -> int:
	var keep := 1 if (NPCBrain.JOB_TOOL.get(o.job, "") == item or w.brain.keeps(o, item)) else 0
	return maxi(0, o.inv.count(item) - keep)


## Whether owner `o` is willing to lend `item` to `renter_ref`: the shared engine (market_sell: its need for coin; the price at its
## own floor, 50 points, since the fee only pays the wear; a spare it does not advertise, 50 points, as a sale without an ask; its
## opinion of the renter) against keeping it. Refusal is a valid outcome; a needy owner may still lend to someone it dislikes.
func owner_willing(o: NPC, renter_ref: String, item: String) -> bool:
	if spare(o, item) <= 0 or not w.claims_allow(o, item, 1):
		return false
	var fs := {"necessity": JudgmentLive.coin_need(o), "price": 50000, "surplus": 50000}
	return str(f.market._weigh(o, "market_sell", renter_ref, fs, [w.day(), item.hash(), o.id, renter_ref.hash()]).chosen) == "deal"


## The owners who could lend `n` a `item` now (alive, awake adults with a spare), by id.
func lenders(n: NPC, item: String) -> Array:
	var out := []
	for o: NPC in w.npcs:
		if o.alive and o != n and o.role == "adult" and not w.asleep(o) and spare(o, item) > 0:
			out.append(o)
	return out


## NPCBrain._get_tool, while the market drives with rental on: worker `n`, short of its trade's `item`, weighs buying it from
## `seller` (the seller the existing path would go to, null: none it can pay), renting it from each willing owner (it can pay the
## deposit), or doing without for now (the profile's forgo), through the shared engine (market_buy: need, what it costs against
## its purse, the number of sources, its opinion of each). Once a day per worker. Returns {act: "buy" | "rent" | "wait", owner}.
## Waiting on the manor's tool for it (EQ-19, a commission) is the existing way of borrowing: then it does not rent.
func consider(n: NPC, item: String, seller: NPC) -> Dictionary:
	var me := World.npc_ref(n.id)
	if not active() or not open_for(me, item).is_empty() or n.inv.has(item):
		return {"act": "buy"}
	if not w.brain._order_for(n).is_empty() or f.market.tool_orders.values().has(n.id):
		return {"act": "buy"}                        # the manor's tool is coming: the existing path (it waits)
	var was: Array = considered.get(me, [-1, ""])
	if int(was[0]) == w.day():
		return {"act": "wait" if str(was[1]) in ["rent", "wait"] else "buy"}     # today's choice holds (a rent tried today: wait)
	considered[me] = [w.day(), "buy"]
	var cands := []
	var coins := maxi(1, n.coins)
	if seller != null:
		var price := w.sell_price(seller, item)
		cands.append({"id": "buy", "counterparty": f.actors.judged_person(World.npc_ref(seller.id)),
			"factors": {"necessity": 100000, "price": clampi(100000 - 100000 * price / coins, 0, 100000)}})
	var owners := {}
	var dep := deposit_for(item)
	var fee := expected_fee(item)
	for o: NPC in lenders(n, item):
		var ok := n.coins >= dep and owner_willing(o, me, item)
		var c := {"id": "rent:%d" % o.id, "counterparty": f.actors.judged_person(World.npc_ref(o.id)),
			"factors": {"necessity": 100000, "price": clampi(100000 - 100000 * fee / coins, 0, 100000)}}
		if not ok:
			c["feasible"] = false
			c["why"] = "no_deposit" if n.coins < dep else "owner_unwilling"
		cands.append(c)
		owners["rent:%d" % o.id] = o
	if owners.is_empty():
		return {"act": "buy"}                        # nobody could lend: the existing path, unchanged
	var r := JudgmentWeighting.choose(w.judgment, f.market._judgment_cfg(), n.id, "market_buy", cands, [w.day(), item.hash(), n.id])
	var ch := str(r.chosen) if r.chosen != null else "forgo"
	w.stat("rent_weighed")
	if ch.begins_with("rent:"):
		w.stat("rent_chosen")
		considered[me] = [w.day(), "rent"]
		return {"act": "rent", "owner": owners[ch]}
	if ch == "buy":
		w.stat("rent_buy_chosen")
		return {"act": "buy"}
	w.stat("rent_forgone")
	considered[me] = [w.day(), "wait"]
	return {"act": "wait"}


# ------------------------------------------------------------------------------------------------ opening
## A rental of one `item` from `owner` (a villager) to `renter` (a villager or a player), at the owner's word: validated and
## committed by the authority (EconTransactions.lend). {ok, code, txid}.
func open(renter: Object, owner: NPC, item: String) -> Dictionary:
	var rr := Contracts.ref_of(renter)
	if not active():
		return {"ok": false, "code": "off", "txid": ""}
	if owner == null or not owner.alive or int(GameData.item(item).get("durability", 0)) <= 0:
		return {"ok": false, "code": "unknown_party", "txid": ""}
	if not open_for(rr, item).is_empty():
		return {"ok": false, "code": "already_renting", "txid": ""}
	if not owner_willing(owner, rr, item):
		w.stat("rent_owner_refused")
		return {"ok": false, "code": "owner_unwilling", "txid": ""}
	var dep := deposit_for(item)
	var tx: Dictionary = w.transactions.lend(w.transactions.next_txid("rent"), rr, World.npc_ref(owner.id), item, dep)
	if not bool(tx.ok):
		w.stat("rent_refused_" + str(tx.code))
		return tx
	records[str(tx.txid)] = {"txid": str(tx.txid), "renter": rr, "owner": World.npc_ref(owner.id), "item": item, "deposit": dep,
		"lent_wear": int(tx.wear), "paid": 0, "made_day": w.day(), "due_day": w.day() + term_days(), "state": OPEN, "closed_day": -1, "why": ""}
	w.stat("rent_opened")
	w.stat("rent_opened_" + item)
	return tx


# ------------------------------------------------------------------------------------------------ wear and fees
## The holder object of a ref (an NPC or a PlayerState), null when gone.
func _holder(ref: String) -> Object:
	var k := f.actors.kind(ref)
	if k == "npc":
		return w.npc(World.ref_id(ref))
	if k == "player":
		return w.player_of_ref(ref)
	return null


## The durability the renter's use has consumed so far (the unit it holds against what it had when lent).
func used(r: Dictionary) -> int:
	var h = _holder(str(r.renter))
	var full := int(GameData.item(str(r.item)).get("durability", 0))
	if h == null or not h.inv.has(str(r.item)):
		return int(r.lent_wear)
	return maxi(0, int(r.lent_wear) - int(h.inv.durability.get(str(r.item), full)))


## The fee owed so far beyond what was paid.
func owed(r: Dictionary) -> int:
	return maxi(0, fee_for(str(r.item), used(r)) - int(r.paid))


## Each dawn: the day's fee paid to the owner from the renter's purse (what it can; the rest is settled from the deposit at the end).
func _bill(r: Dictionary) -> void:
	var due := owed(r)
	var h = _holder(str(r.renter))
	if due <= 0 or h == null:
		return
	var pay := mini(due, maxi(0, int(h.coins)))
	if pay <= 0:
		return
	var tx: Dictionary = w.transactions.transfer_coins(w.transactions.next_txid("rent_fee"), str(r.renter), str(r.owner), pay, "rent_fee", true)
	if bool(tx.ok):
		r.paid = int(r.paid) + pay
		w.stat("rent_fees_paid", float(pay))


# ------------------------------------------------------------------------------------------------ ending
## End rental `r` once (`outcome` "returned" with the unit back, else one of ENDS without it): the authority pays the fee still owed
## (for "returned", the wear used; otherwise the whole durability it had when lent) from the escrow to the owner and the rest back to
## the renter (or `refund_to`, its estate). `from_inv`: where the unit is when it comes back.
func _end(r: Dictionary, outcome: String, why: String, from_inv: Inventory = null, refund_to := "") -> Dictionary:
	if str(r.state) != OPEN:
		return {"ok": str(r.state) == outcome, "code": "duplicate" if str(r.state) == outcome else "not_open", "state": str(r.state)}
	var item := str(r.item)
	var back := outcome == "returned" or (outcome == "settled" and from_inv != null)
	var use := used(r) if back else int(r.lent_wear)
	var fee := mini(int(r.deposit), maxi(0, fee_for(item, use) - int(r.paid)))
	var to := refund_to if refund_to != "" else str(r.renter)
	var tx: Dictionary = w.transactions.end_rental(w.transactions.next_txid("rent_end"), str(r.owner), to, item, from_inv if back else null,
		int(r.deposit), fee)
	if not bool(tx.ok):
		w.stat("rent_end_refused_" + str(tx.code))
		return tx
	r.paid = int(r.paid) + fee
	r.state = outcome
	r.closed_day = w.day()
	r.why = why
	w.stat("rent_" + outcome)
	w.stat("rent_fees_settled", float(fee))
	_prune()
	return tx


## The renter gives the tool back (a villager at dawn, a player by its verb): it must hold it. {ok, code}.
func give_back(r: Dictionary, why: String) -> Dictionary:
	var h = _holder(str(r.renter))
	if h == null or not h.inv.has(str(r.item)):
		return {"ok": false, "code": "not_held"}
	return _end(r, "returned", why, h.inv)


## World._work_wear: `who`'s `tool` just broke in use. A rented one ends "broken" (the renter pays its whole lent durability).
func on_broke(who: Object, tool: String) -> void:
	var r := open_for(Contracts.ref_of(who), tool)
	if not r.is_empty() and not who.inv.has(tool):
		_end(r, "broken", "broke in use")


## World.kill, before the inheritance: a renter who died gives back what it holds on rent, its estate settled (refund to the
## estate); an owner who died is succeeded by its estate in every rental of its tools.
func on_death(n: NPC) -> void:
	var me := World.npc_ref(n.id)
	for r in open_records():
		if str(r.renter) == me:
			var est: Dictionary = w.transactions.estate_of(me)
			var to := str(est.get("ref", "")) if not est.is_empty() else "-"
			if n.inv.has(str(r.item)):
				_end(r, "settled", "renter died", n.inv, to)
			else:
				_end(r, "settled", "renter died; the tool was not held", null, to)
		elif str(r.owner) == me:
			var est2: Dictionary = w.transactions.estate_of(me)
			r.owner = str(est2.get("ref", World.MANOR)) if not est2.is_empty() else World.MANOR
			w.stat("rent_owner_inherited")


## The market's dawn: each open rental (by id) is billed; one whose tool its renter no longer holds ends "lost" (stolen, sold, given
## away, dropped); one at its term's end, or whose renter no longer needs it (another trade, a tool of its own besides), is given
## back. Considerations older than today are forgotten.
func dawn(day: int) -> void:
	for k in considered.keys():
		if int(considered[k][0]) < day:
			considered.erase(k)
	if records.is_empty():
		return
	for r in open_records():
		var h = _holder(str(r.renter))
		if h == null:
			continue                           # (a renter gone without a death: a guest away; its rental waits for it)
		var item := str(r.item)
		if not h.inv.has(item):
			_end(r, "lost", "not held by the renter")
			continue
		_bill(r)
		var done := day >= int(r.due_day)
		if h is NPC and ((NPCBrain.JOB_TOOL.get((h as NPC).job, "") != item and not w.brain.keeps(h, item)) or h.inv.count(item) > 1):
			done = true
		if done:
			if give_back(r, "term ended" if day >= int(r.due_day) else "no longer needed").get("ok", false) == false:
				w.stat("rent_return_failed")


func _prune() -> void:
	var done: Array = records.keys().filter(func(id): return records[id].state != OPEN)
	if done.size() <= keep_closed:
		return
	done.sort_custom(func(a, b): return [int(records[a].closed_day), a] < [int(records[b].closed_day), b])
	for i in done.size() - keep_closed:
		records.erase(done[i])


# ------------------------------------------------------------------------------------------------ save
func is_empty() -> bool:
	return records.is_empty() and considered.is_empty()


func to_dict() -> Dictionary:
	var ids: Array = records.keys()
	ids.sort()
	var rs := []
	for id in ids:
		rs.append((records[id] as Dictionary).duplicate())
	var ks: Array = considered.keys()
	ks.sort()
	var c := {}
	for k in ks:
		c[k] = [int(considered[k][0]), str(considered[k][1])]
	return {"records": rs, "considered": c}


func load_dict(d: Dictionary) -> void:
	records = {}
	considered = {}
	for r in d.get("records", []):
		records[str(r.txid)] = {"txid": str(r.txid), "renter": str(r.renter), "owner": str(r.owner), "item": str(r.item), "deposit": int(r.deposit),
			"lent_wear": int(r.lent_wear), "paid": int(r.paid), "made_day": int(r.made_day), "due_day": int(r.due_day), "state": str(r.state),
			"closed_day": int(r.closed_day), "why": str(r.why)}
	for k in d.get("considered", {}):
		considered[str(k)] = [int(d.considered[k][0]), str(d.considered[k][1])]
