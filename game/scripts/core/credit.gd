class_name Credit
extends RefCounted
## TRADE-CREDIT (owner Q18-5, 2026-10-23: "Barter + credit with trust"): goods-for-goods deals and recorded debts that must be
## repaid; unpaid debts hurt standing. One rule for every party, the player or a villager alike (PAR-02): the functions take
## the two parties as objects (NPC or PlayerState) and know nothing of who is playing.
##
## Barter: a buyer takes `want` from a seller and gives `give` in return, unit by unit at both sides' prices (the seller's
## ask for what it gives, World.player_quote / sell_price_at with both sides' Trading; the seller's bid for what it gets,
## buy_price_at), as many units of `give` as it takes for the seller to receive at least what it gives. Either side may
## refuse: the seller takes only what it can use (NPCBrain.wants, Relations.favourites), the giver offers only what is
## its own to spare. Goods move both ways; no coins move.
##
## Credit: the seller hands over goods now for a recorded debt in coins (the price at the sale, no interest), due credit.days
## later. Trust is the seller's regard for the buyer (Relations; the existing befriend_at threshold): below it, or while
## an earlier debt of that buyer stands unpaid, or past `limit` coins owed, or while the seller itself needs its coins
## (World.reserve_of), the seller refuses. Repaid in coins on or after the due day if the debtor can afford it above their
## reserve (World.can_afford); villagers repay at dawn, the player when they choose (the trade window). One day after the
## due day an unpaid debt is a default: regard falls (credit.default_regard; for the player's default it spreads to the
## creditor's kin and friends like any harm, Relations.harmed) and no further credit while it stands. A villager in
## need defaults legitimately; the debt stays on the record until repaid late or written off.
## Death: a villager's debts pass to their heir (World._heir, the inheritance rule) as the heir takes the goods and
## coins; with no heir, or a slain debtor, the debt is written off (lost). A creditor's claims pass to their heir the
## same way, else are forgiven. The player's death writes off every debt of theirs, as the heir starts with the kit
## only. Coins are never made or destroyed here: a repayment moves coins from debtor to creditor. Saved: optional "credit".
## Provisional values in balance.json "credit" (agent proposals).

var w
var debts: Array = []          # {id, creditor, debtor (refs), item, qty, value, made, due, state, ended}
var next_id := 1
var _hh_day := {}              # household -> the day it last made a deal (derived, not saved: one a day)

const OPEN := "open"
const DEFAULTED := "defaulted"
const REPAID := "repaid"
const LATE := "repaid late"
const LOST := "lost"


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("credit")


# ---------------------------------------------------------------- parties --------------------
static func ref_of(who) -> String:
	return Contracts.ref_of(who)


func party(ref: String):
	if ref == World.PLAYER:
		return w.player
	return w.npc(World.ref_id(ref)) if ref.begins_with("npc:") else null


func _alive(ref: String) -> bool:
	var p = party(ref)
	return p != null and (p is PlayerState or (p as NPC).alive)


func _name(ref: String) -> String:
	return w.ref_name(ref)


static func _rid(ref: String) -> int:
	return Contracts.rel_id(ref)


## The seller's regard for the buyer: the trust that credit rests on.
func trust(creditor_ref: String, debtor_ref: String) -> float:
	return float(w.relations.peek(_rid(creditor_ref), _rid(debtor_ref)).regard)


static func trust_needed() -> float:
	return float(Relations.cfg().befriend_at)


# ---------------------------------------------------------------- the record -----------------
static func standing(d: Dictionary) -> bool:
	return str(d.state) == OPEN or str(d.state) == DEFAULTED


func debts_of(creditor_ref := "", debtor_ref := "", all := false) -> Array:
	var out := []
	for d in debts:
		if (creditor_ref == "" or d.creditor == creditor_ref) and (debtor_ref == "" or d.debtor == debtor_ref) and (all or standing(d)):
			out.append(d)
	return out


## Coins `debtor` owes `creditor` now (open and defaulted debts).
func owed(creditor_ref: String, debtor_ref: String) -> int:
	var n := 0
	for d in debts_of(creditor_ref, debtor_ref):
		n += int(d.value)
	return n


func _debt(id: int) -> Dictionary:
	for d in debts:
		if int(d.id) == id:
			return d
	return {}


func _end(d: Dictionary, state: String) -> void:
	d.state = state
	d.ended = w.day()


# ---------------------------------------------------------------- prices ---------------------
## The unit prices `buyer` pays `seller` for `qty` of `id`, each at the stock it leaves (the sale's rule; the player's
## friend price through player_quote).
func ask_prices(seller: Object, buyer: Object, id: String, qty: int) -> Array:
	if buyer == w.player and seller is NPC:
		return w.player_quote(seller, id, qty, true)
	var out := []
	var stock: int = seller.inv.count(id)
	var nearby: int = w.local_supply(id, seller.pos, seller) if seller is NPC else 0
	for k in maxi(0, qty):
		out.append(w.deal_price(World.sell_price_at(id, maxi(0, stock - k), nearby), buyer, seller))
	return out


## The unit prices `seller` bids for `qty` of `id` it takes in (the buy side, as the stock fills).
func bid_prices(seller: Object, buyer: Object, id: String, qty: int) -> Array:
	if buyer == w.player and seller is NPC:
		return w.player_quote(seller, id, qty, false)
	var out := []
	var stock: int = seller.inv.count(id)
	for k in maxi(0, qty):
		out.append(w.deal_price(World.buy_price_at(id, stock + k), seller, buyer))
	return out


static func _sum(a: Array) -> int:
	var n := 0
	for c in a:
		n += int(c)
	return n


## What `seller` will let go of: its stock for sale, less what it keeps and owes (NPCBrain.for_sale / reserve).
func available(seller: Object, id: String) -> int:
	if seller is NPC:
		var n: NPC = seller
		if not n.alive or n.role in ["child", "bandit"] or w.brain.keeps(n, id):
			return 0
		return maxi(0, n.inv.count(id) - w.brain.reserve(n, id))
	return (seller as PlayerState).inv.count(id)


## What `giver` can spare of `id` in a deal: its own, not what its trade keeps, owes or (a villager) must have for its
## household's necessities; the player's goods marked stolen are not offered.
func spare(giver: Object, id: String) -> int:
	if giver is NPC:
		var n: NPC = giver
		if World.is_necessity(id) or n.role in ["child", "bandit"]:
			return 0
		return available(n, id)
	var p: PlayerState = giver
	return maxi(0, p.inv.count(id) - p.stolen_count(id))


## Whether `seller` would take `id` in barter: something its trade works or it is glad of (no use, no deal).
func accepts(seller: Object, id: String) -> bool:
	if seller is NPC:
		return w.brain.wants(seller, id) > 0 or w.relations.favourites(seller).has(id)
	return true


# ---------------------------------------------------------------- barter ---------------------
## The barter of `qty` of `want` from `seller` for `give` from `buyer`: {ok, give_qty, ask, offered, why}. give_qty is the
## fewest units of `give` that bring the seller what it asks (their bids unit by unit); why says the refusal.
func barter_quote(seller: Object, buyer: Object, want: String, qty: int, give: String) -> Dictionary:
	var no := func(why: String) -> Dictionary: return {"ok": false, "give_qty": 0, "ask": 0, "offered": 0, "why": why}
	if seller == buyer or qty < 1 or want == give:
		return no.call("Nothing to swap.")
	var sname: String = seller.name
	var item := GameData.item_name(want).to_lower()
	if available(seller, want) < qty:
		return no.call("%s has no %s to spare." % [sname, item])
	if not buyer.inv.can_add(want):
		return no.call("There is no room for %s." % item)
	if not accepts(seller, give):
		return no.call("%s has no use for %s." % [sname, GameData.item_name(give).to_lower()])
	var have := spare(buyer, give)
	if have < 1:
		return no.call("%s has no %s to spare." % [buyer.name, GameData.item_name(give).to_lower()])
	var ask := _sum(ask_prices(seller, buyer, want, qty))
	var bids := bid_prices(seller, buyer, give, mini(have, 99))
	var got := 0
	for k in bids.size():
		got += int(bids[k])
		if got >= ask:
			if not seller.inv.can_add(give):
				return no.call("%s has no room for %s." % [sname, GameData.item_name(give).to_lower()])
			return {"ok": true, "give_qty": k + 1, "ask": ask, "offered": got, "why": ""}
	return no.call("That is not worth enough: %s asks %d coins' worth and your %s fetch %d." % [sname, ask, GameData.item_name(give).to_lower(), got])


## Do it: both ways at once or not at all. Returns {result: "bartered"|"failed", text, give_qty}.
func barter(seller: Object, buyer: Object, want: String, qty: int, give: String) -> Dictionary:
	var q := barter_quote(seller, buyer, want, qty, give)
	if not bool(q.ok):
		return {"result": "failed", "text": str(q.why), "give_qty": 0}
	var k: int = q.give_qty
	seller.inv.remove(want, qty)
	buyer.inv.add(want, qty)
	buyer.inv.remove(give, k)
	seller.inv.add(give, k)
	_note_deal(seller, buyer)
	w.stat("barter_deals")
	w.stat("barter_units", float(qty + k))
	var text := "%s swaps %d %s for %d %s." % [buyer.name, qty, GameData.item_name(want).to_lower(), k, GameData.item_name(give).to_lower()]
	if buyer == w.player or seller == w.player:
		w.note(text)
	return {"result": "bartered", "text": text, "give_qty": k}


func _note_deal(seller: Object, buyer: Object) -> void:
	w.relations.note_trade(seller.id if seller is NPC else Life.PLAYER_ID, buyer.id if buyer is NPC else Life.PLAYER_ID, w.day())


# ---------------------------------------------------------------- credit ---------------------
## Why `seller` will not sell `buyer` goods worth `value` coins on credit, "" when it will.
func credit_refusal(seller: Object, buyer: Object, value: int) -> String:
	if seller == buyer or value < 1:
		return "No credit for that."
	var c := ref_of(seller)
	var b := ref_of(buyer)
	var sname: String = seller.name
	if seller is NPC and (not seller.alive or seller.role in ["child", "bandit"]):
		return "%s does not lend." % sname
	if trust(c, b) < trust_needed():
		return "%s does not know you well enough to sell on credit." % sname if buyer == w.player else "%s does not trust %s enough." % [sname, buyer.name]
	for d in debts_of(c, b):
		if str(d.state) == DEFAULTED:
			return "%s will not lend again while an old debt of %d coins stands unpaid." % [sname, int(d.value)]
	var cap := int(cfg().limit)
	if owed(c, b) + value > cap:
		return "%s will not lend more than %d coins at a time (%d owed)." % [sname, cap, owed(c, b)]
	if seller is NPC and seller.coins < w.reserve_of(seller):
		return "%s is short of coins themselves and sells for coin only." % sname
	return ""


## Sell `qty` of `id` to `buyer` on credit for the bill `value` (the ask), due credit.days later. Goods move now, coins
## later. Returns {result: "credited"|"failed", text, debt}.
func sell_on_credit(seller: Object, buyer: Object, id: String, qty: int, value: int) -> Dictionary:
	var no := credit_refusal(seller, buyer, value)
	if no == "":
		if available(seller, id) < qty or qty < 1:
			no = "%s has not that many to spare." % seller.name
		elif not buyer.inv.can_add(id):
			no = "There is no room for it."
	if no != "":
		return {"result": "failed", "text": no, "debt": {}}
	seller.inv.remove(id, qty)
	buyer.inv.add(id, qty)
	var d := {"id": next_id, "creditor": ref_of(seller), "debtor": ref_of(buyer), "item": id, "qty": qty, "value": value,
			"made": w.day(), "due": w.day() + int(cfg().days), "state": OPEN, "ended": -1}
	next_id += 1
	debts.append(d)
	_note_deal(seller, buyer)
	w.stat("credit_extended")
	w.stat("credit_coins", float(value))
	var text := "%s takes %d %s from %s on credit: %d coins due by day %d." % [buyer.name, qty, GameData.item_name(id).to_lower(), seller.name, value, int(d.due)]
	if buyer == w.player or seller == w.player:
		w.note(text)
	return {"result": "credited", "text": text, "debt": d}


## Whether the debtor can pay the debt now, above their reserve (World.can_afford: a villager in need cannot).
func can_repay(d: Dictionary) -> bool:
	var p = party(str(d.debtor))
	if p == null or not _alive(str(d.debtor)) or int(d.value) > p.coins:
		return false
	return not (p is NPC) or w.can_afford(p, int(d.value))


## The debtor pays the creditor in coins. False when they cannot (the player may always choose to pay what they hold).
func repay(id: int, force := false) -> bool:
	var d := _debt(id)
	if d.is_empty() or not standing(d):
		return false
	var deb = party(str(d.debtor))
	var cre = party(str(d.creditor))
	if deb == null or cre == null or not _alive(str(d.creditor)) or deb.coins < int(d.value):
		return false
	if deb is NPC and not force and not w.can_afford(deb, int(d.value)):
		return false
	var late: bool = str(d.state) == DEFAULTED
	deb.coins -= int(d.value)
	cre.coins += int(d.value)
	if deb is NPC:
		deb.spent += int(d.value)
	if cre is NPC:
		cre.earned += int(d.value)
	_end(d, LATE if late else REPAID)
	var reg: float = float(cfg().repay_regard) * (0.5 if late else 1.0)
	var t: Dictionary = w.relations.tie(_rid(str(d.creditor)), _rid(str(d.debtor)))
	w.relations._raise(t, reg, 0.0)
	w.stat("credit_repaid_late" if late else "credit_repaid")
	w.stat("credit_repaid_coins", float(d.value))
	if str(d.debtor) == World.PLAYER or str(d.creditor) == World.PLAYER:
		w.note("%s repaid %d coins to %s%s." % [_name(str(d.debtor)), int(d.value), _name(str(d.creditor)), " (late)" if late else ""])
	return true


func _default(d: Dictionary) -> void:
	d.state = DEFAULTED
	var amount := float(cfg().default_regard)
	var cre := str(d.creditor)
	var deb := str(d.debtor)
	if deb == World.PLAYER:
		var c = party(cre)
		if c is NPC:
			w.relations.harmed(c, amount)               # the creditor's regard falls, and their kin's and friends' (CRT-12)
	else:
		w.relations._raise(w.relations.tie(_rid(cre), _rid(deb)), -amount, 0.0, false)
		if cre != World.PLAYER:                          # and the creditor's friends think less of the debtor
			var share := float(Relations.cfg().friend_harm_share)
			for o: NPC in w.npcs:
				if o.alive and o.id != _rid(deb) and o.id != _rid(cre) and w.relations.friends(o.id, _rid(cre)):
					w.relations._raise(w.relations.tie(o.id, _rid(deb)), -amount * share, 0.0, false)
	w.stat("credit_defaulted")
	w.stat("credit_default_coins", float(d.value))
	if deb == World.PLAYER or cre == World.PLAYER:
		w.note("%s did not repay %d coins to %s by day %d: it is a default." % [_name(deb), int(d.value), _name(cre), int(d.due)])


# ---------------------------------------------------------------- dawn -----------------------
## Each dawn: debts fall due and are repaid by villagers who can (a debt is repaid from the due day on), unpaid ones a day
## past it default; then villagers short of food for their household barter or buy on credit; old ended records are dropped.
func dawn() -> void:
	var d: int = w.day()
	_hh_day.clear()
	for x in debts.duplicate():
		if str(x.state) != OPEN:
			continue
		if not _alive(str(x.debtor)) or not _alive(str(x.creditor)):
			continue
		var deb = party(str(x.debtor))
		if deb is NPC and d >= int(x.due) and can_repay(x):
			repay(int(x.id))
		elif d > int(x.due):
			_default(x)
		elif deb is PlayerState and d == int(x.due):
			w.note("Your debt of %d coins to %s falls due today." % [int(x.value), _name(str(x.creditor))])
	_villager_deals()
	var keep := int(cfg().keep_days)
	debts = debts.filter(func(x): return standing(x) or d - int(x.ended) <= keep)


## Villagers whose household is short of food (below the relief trigger) and cannot pay for it get it from a neighbour by
## barter first, else on credit from one who trusts them. At most one deal for a household a day, in villager order.
func _villager_deals() -> void:
	var relief := float(GameData.b("relief_trigger_days"))
	var reach := float(cfg().reach)
	for b: NPC in w.npcs:
		if not b.alive or b.role != "adult" or b.household < 0 or _hh_day.has(b.household):
			continue
		if w.brain.household_food_days(b.household) >= relief:
			continue
		var best := _cheapest_food(b, reach)
		if best.is_empty():
			continue
		var s: NPC = best.seller
		var id: String = best.id
		var qty := clampi(ceili(w.brain.household_day_food(b.household) / maxf(1.0, NPCBrain.food_points(id))), 1, int(cfg().max_units))
		qty = mini(qty, available(s, id))
		var bill := _sum(ask_prices(s, b, id, qty))
		if b.coins >= bill:
			continue                                     # they can pay: the ordinary market serves them
		_hh_day[b.household] = w.day()
		if _barter_for_food(s, b, id, qty):
			continue
		sell_on_credit(s, b, id, qty, bill)


func _barter_for_food(s: NPC, b: NPC, want: String, qty: int) -> bool:
	for give in b.inv.ids():
		if NPCBrain.FOOD.has(give) or spare(b, give) < 1 or not accepts(s, give):
			continue
		if bool(barter_quote(s, b, want, qty, give).ok):
			return str(barter(s, b, want, qty, give).result) == "bartered"
	return false


## The seller within `reach` tiles of `buyer` (another household, adult) with the cheapest food per point to spare.
func _cheapest_food(buyer: NPC, reach: float) -> Dictionary:
	var best := {}
	var per := INF
	for s: NPC in w.npcs:
		if not s.alive or s == buyer or s.role != "adult" or s.household == buyer.household or s.pos.distance_to(buyer.pos) > reach:
			continue
		for id in NPCBrain.FOOD:
			var pts := NPCBrain.food_points(id)
			if pts <= 0.0 or available(s, id) < 1 or not buyer.inv.can_add(id):
				continue
			var price := float(ask_prices(s, buyer, id, 1)[0]) / pts
			if price < per:
				per = price
				best = {"seller": s, "id": id}
	return best


# ---------------------------------------------------------------- death ----------------------
## A villager died (World.kill, before the inheritance): `heir` is who takes what they leave (null: nobody, or slain).
func on_death(n: NPC, heir: NPC) -> void:
	var me := ref_of(n)
	for x in debts:
		if not standing(x):
			continue
		if x.debtor == me:
			if heir != null and ref_of(heir) != x.creditor:
				x.debtor = ref_of(heir)
				w.stat("credit_passed")
			else:
				_end(x, LOST)
				w.stat("credit_lost")
		elif x.creditor == me:
			if heir != null and ref_of(heir) != x.debtor:
				x.creditor = ref_of(heir)
				w.stat("credit_passed")
			else:
				_end(x, LOST)


## The player died: debts of theirs and owed them are written off (the heir starts with the kit only, and strangers).
func on_player_died() -> void:
	for x in debts:
		if standing(x) and (x.debtor == World.PLAYER or x.creditor == World.PLAYER):
			_end(x, LOST)
			w.stat("credit_lost")


# ---------------------------------------------------------------- saving ---------------------
func to_dict() -> Dictionary:
	var out := []
	for x in debts:
		out.append((x as Dictionary).duplicate())
	return {"next_id": next_id, "debts": out}


func load_dict(dd: Dictionary) -> void:
	debts.clear()
	next_id = int(dd.get("next_id", 1))
	for x in dd.get("debts", []):
		debts.append({"id": int(x.id), "creditor": str(x.creditor), "debtor": str(x.debtor), "item": str(x.item), "qty": int(x.qty),
				"value": int(x.value), "made": int(x.made), "due": int(x.due), "state": str(x.state), "ended": int(x.get("ended", -1))})
