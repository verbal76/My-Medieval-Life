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
## The player as seller or lender (PAR-02): a villager short of food and coins counts the player among the neighbours
## within reach (cheapest food first, villagers before the player on a tie); when the player is the one, the villager asks
## the player by barter (goods it can offer) or else on credit, by the same trust rule, and the player accepts or refuses
## (answer_request; a refusal is remembered `refuse_days`, an unanswered ask lapses at the next dawn). The player may in turn
## offer goods to a villager by barter or on credit from the trade window; the villager takes only what it can use. Trust
## is the one tie's regard (Relations ties are mutual, so the villager's regard for the player is the player's standing
## as a creditor); a default lowers it and the creditor's friends' regard like any creditor's.
## Death: a villager's debts pass to their heir (World._heir, the inheritance rule) as the heir takes the goods and
## coins; with no heir, or a slain debtor, the debt is written off (lost). A creditor's claims pass to their heir the
## same way, else are forgiven. The player's debts and claims pass the same way to the player's heir (the family line keeps
## the name "player"), written off where a villager's would be: slain by a person (not hunger, bad food, old age, a beast or
## a collapse), or owed to or by the very child who becomes the heir (on_player_died). Coins are never made or destroyed
## here: a repayment moves coins from debtor to creditor. Saved: optional "credit".
## Provisional values in balance.json "credit" (agent proposals).

var w
var debts: Array = []          # {id, creditor, debtor (refs), item, qty, value, made, due, state, ended}
var next_id := 1
var requests: Array = []       # villagers' asks of the player today: {id, npc, item, qty, mode (barter|credit), give, value, day}
var next_req := 1
var refused := {}              # villager id -> the day until which they do not ask the player again (saved with the asks)
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
	if World.is_player_ref(ref):
		return w.player
	return w.npc(World.ref_id(ref)) if ref.begins_with("npc:") else null


func _alive(ref: String) -> bool:
	var p = party(ref)
	return p != null and (p.alive if p is PlayerState else (p as NPC).alive)


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
	var nearby: int = w.local_supply(id, seller.pos, seller if seller is NPC else null)
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
	var pl: PlayerState = seller
	return maxi(0, pl.inv.count(id) - pl.stolen_count(id))     # stolen goods are not for sale (as in spare)


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
	if seller is PlayerState and not accepts(buyer, want):      # a villager takes only what it can use
		return no.call("%s has no use for %s." % [buyer.name, item])
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
			if seller is NPC and JudgmentLive.on(w, "barter_accept") and not JudgmentLive.barter_ok(w, seller, buyer):     # PROSPECTIVE (PROS-19, Q14)
				return no.call("%s would rather not swap with %s." % [sname, "you" if buyer == w.player else buyer.name])
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
	if buyer is NPC and (not buyer.alive or buyer.role in ["child", "bandit"]):
		return "%s does not deal on credit." % buyer.name
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
	if seller is NPC and JudgmentLive.on(w, "credit_lend"):     # PROSPECTIVE (PROS-19, Q14): off unless judgment is attached
		return JudgmentLive.lend_refusal(w, seller, buyer)
	return ""


## Sell `qty` of `id` to `buyer` on credit for the bill `value` (the ask), due credit.days later. Goods move now, coins
## later. Returns {result: "credited"|"failed", text, debt}.
func sell_on_credit(seller: Object, buyer: Object, id: String, qty: int, value: int) -> Dictionary:
	var no := credit_refusal(seller, buyer, value)
	if no == "":
		if available(seller, id) < qty or qty < 1:
			no = "%s has not that many to spare." % seller.name
		elif seller is PlayerState and not accepts(buyer, id):       # a villager borrows only what it can use
			no = "%s has no use for %s." % [buyer.name, GameData.item_name(id).to_lower()]
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
func repay(id: int, force := false, actor: PlayerState = null) -> bool:
	if actor != null and actor != w.player:
		return w.as_actor(actor, repay.bind(id, force))
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
	if w.judgment != null:
		JudgmentLive.on_deal(w, "trade_fair", _rid(str(d.debtor)), _rid(str(d.creditor)), int(d.value), late)    # a debt repaid; late is a fair deal with half the trust gain (X19-EVENT-Q)
	var reg: float = float(cfg().repay_regard) * (0.5 if late else 1.0)
	var t: Dictionary = w.relations.tie(_rid(str(d.creditor)), _rid(str(d.debtor)))
	w.relations._raise(t, reg, 0.0, true, Vector2i(_rid(str(d.creditor)), _rid(str(d.debtor))))
	w.stat("credit_repaid_late" if late else "credit_repaid")
	w.stat("credit_repaid_coins", float(d.value))
	if World.is_player_ref(str(d.debtor)) or World.is_player_ref(str(d.creditor)):
		w.note("%s repaid %d coins to %s%s." % [_name(str(d.debtor)), int(d.value), _name(str(d.creditor)), " (late)" if late else ""])
	return true


func _default(d: Dictionary) -> void:
	d.state = DEFAULTED
	var amount := float(cfg().default_regard)
	var cre := str(d.creditor)
	var deb := str(d.debtor)
	if World.is_player_ref(deb):
		var c = party(cre)
		if c is NPC:
			w.relations.harmed(c, amount)               # the creditor's regard falls, and their kin's and friends' (CRT-12)
	else:
		w.relations._raise(w.relations.tie(_rid(cre), _rid(deb)), -amount, 0.0, false, Vector2i(_rid(cre), _rid(deb)))
		var share := float(Relations.cfg().friend_harm_share)      # and the creditor's friends think less of the debtor
		for o: NPC in w.npcs:                                      # (the player's friends too: PAR-02)
			if o.alive and o.id != _rid(deb) and o.id != _rid(cre) and w.relations.friends(o.id, _rid(cre)):
				w.relations._raise(w.relations.tie(o.id, _rid(deb)), -amount * share, 0.0, false, Vector2i(o.id, _rid(deb)))
	if w.judgment != null:
		JudgmentLive.on_deal(w, "trade_cheat", _rid(deb), _rid(cre), int(d.value))      # PROSPECTIVE (PROS-19): a debt not repaid
	w.stat("credit_defaulted")
	w.stat("credit_default_coins", float(d.value))
	if World.is_player_ref(deb) or World.is_player_ref(cre):
		w.note("%s did not repay %d coins to %s by day %d: it is a default." % [_name(deb), int(d.value), _name(cre), int(d.due)])


# ---------------------------------------------------------------- dawn -----------------------
## Each dawn: debts fall due and are repaid by villagers who can (a debt is repaid from the due day on), unpaid ones a day
## past it default; then villagers short of food for their household barter or buy on credit; old ended records are dropped.
func dawn() -> void:
	var d: int = w.day()
	_hh_day.clear()
	requests.clear()                                     # an ask unanswered by the next dawn lapses
	for k in refused.keys():
		if int(refused[k]) <= d:
			refused.erase(k)
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
		var s: Object = best.seller
		var id: String = best.id
		var qty := clampi(ceili(w.brain.household_day_food(b.household) / maxf(1.0, NPCBrain.food_points(id))), 1, int(cfg().max_units))
		qty = mini(qty, available(s, id))
		var bill := _sum(ask_prices(s, b, id, qty))
		if b.coins >= bill:
			continue                                     # they can pay: the ordinary market serves them
		if s == w.player:                                # the player is the neighbour to ask: the villager asks them
			if _ask_player(b, id, qty, bill):
				_hh_day[b.household] = w.day()
				continue
			best = _cheapest_food(b, reach, true)        # nothing the player could be asked: the other neighbours
			if best.is_empty():
				continue
			s = best.seller
			id = best.id
			qty = mini(clampi(ceili(w.brain.household_day_food(b.household) / maxf(1.0, NPCBrain.food_points(id))), 1, int(cfg().max_units)), available(s, id))
			bill = _sum(ask_prices(s, b, id, qty))
			if b.coins >= bill:
				continue
		_hh_day[b.household] = w.day()
		if _barter_for_food(s, b, id, qty):
			continue
		sell_on_credit(s, b, id, qty, bill)


func _barter_for_food(s: Object, b: NPC, want: String, qty: int) -> bool:
	for give in b.inv.ids():
		if NPCBrain.FOOD.has(give) or spare(b, give) < 1 or not accepts(s, give):
			continue
		if bool(barter_quote(s, b, want, qty, give).ok):
			return str(barter(s, b, want, qty, give).result) == "bartered"
	return false


## The seller within `reach` tiles of `buyer` (another household, adult; the player too, unless `no_player`, refused or
## already asked) with the cheapest food per point to spare.
func _cheapest_food(buyer: NPC, reach: float, no_player := false) -> Dictionary:
	var best := {}
	var per := INF
	var judged := JudgmentLive.on(w, "food_seller")          # PROSPECTIVE (PROS-19, Q14): off unless judgment is attached
	var cands := []                                          # each neighbour's cheapest food, in the live rule's order
	for s: NPC in w.npcs:
		if not s.alive or s == buyer or s.role != "adult" or s.household == buyer.household or s.pos.distance_to(buyer.pos) > reach:
			continue
		var mine := INF
		var mine_id := ""
		for id in NPCBrain.FOOD:
			var pts := NPCBrain.food_points(id)
			if pts <= 0.0 or available(s, id) < 1 or not buyer.inv.can_add(id):
				continue
			var price := float(ask_prices(s, buyer, id, 1)[0]) / pts
			if price < mine:
				mine = price
				mine_id = id
		if mine_id != "":
			cands.append({"seller": s, "id": mine_id, "per": mine})
			if mine < per:
				per = mine
				best = {"seller": s, "id": mine_id}
	var p: PlayerState = w.player
	if not (no_player or not p.alive or w.player_level != 0 or p.pos.distance_to(buyer.pos) > reach or refused.has(buyer.id) or request_for(buyer.id).size() > 0):
		var mine := INF                                       # the player is last: a villager wins a tie
		var mine_id := ""
		for id in NPCBrain.FOOD:
			var pts := NPCBrain.food_points(id)
			if pts <= 0.0 or available(p, id) < 1 or not buyer.inv.can_add(id):
				continue
			var price := float(ask_prices(p, buyer, id, 1)[0]) / pts
			if price < mine:
				mine = price
				mine_id = id
		if mine_id != "":
			cands.append({"seller": p, "id": mine_id, "per": mine})
			if mine < per:
				per = mine
				best = {"seller": p, "id": mine_id}
	if judged and cands.size() > 1:
		var order := []                                       # by price, ties in the order found (the live rule's)
		for i in cands.size():
			order.append([float(cands[i].per), i])
		order.sort_custom(func(x, y): return x[0] < y[0] or (x[0] == y[0] and x[1] < y[1]))
		var ranked := []
		for o in order:
			ranked.append(cands[int(o[1])])
		var pick := JudgmentLive.pick_food_seller(w, buyer, ranked)
		return {"seller": pick.seller, "id": pick.id}
	return best


# ---------------------------------------------------------------- asks of the player ---------
## The asks `npc_id` has put to the player (empty when none).
func request_for(npc_id: int) -> Array:
	return requests.filter(func(r): return int(r.npc) == npc_id)


## The villager `b` asks the player for `qty` of `id` (bill `bill` at the player's ask): by barter if it has goods the
## player is offered at a fair rate, else on credit if the one rule lets the player lend. False when neither is possible.
func _ask_player(b: NPC, id: String, qty: int, bill: int) -> bool:
	var p: PlayerState = w.player
	qty = mini(qty, available(p, id))
	if qty < 1:
		return false
	var r := {"id": next_req, "npc": b.id, "item": id, "qty": qty, "mode": "", "give": "", "give_qty": 0, "value": bill, "day": w.day()}
	for give in b.inv.ids():
		if NPCBrain.FOOD.has(give) or spare(b, give) < 1:
			continue
		var q := barter_quote(p, b, id, qty, give)
		if bool(q.ok):
			r.mode = "barter"
			r.give = give
			r.give_qty = int(q.give_qty)
			break
	if r.mode == "":
		if credit_refusal(p, b, bill) != "":
			return false
		r.mode = "credit"
	next_req += 1
	requests.append(r)
	w.stat("credit_asks_of_player")
	var what := GameData.item_name(id).to_lower()
	if r.mode == "barter":
		w.note("%s asks you for %d %s, offering %d %s in barter. Talk to them to answer." % [b.name, qty, what, int(r.give_qty), GameData.item_name(str(r.give)).to_lower()])
	else:
		w.note("%s asks you for %d %s on credit: %d coins by day %d. Talk to them to answer." % [b.name, qty, what, bill, w.day() + int(cfg().days)])
	return true


## The player answers a villager's ask. Returns {result: "bartered"|"credited"|"refused"|"failed", text}. An accepted ask is
## re-checked by the rules as they stand now; a refusal is remembered (refuse_days) and costs nothing.
func answer_request(req_id: int, accept: bool, actor: PlayerState = null) -> Dictionary:
	if actor != null and actor != w.player:
		return w.as_actor(actor, answer_request.bind(req_id, accept))
	var r := {}
	for x in requests:
		if int(x.id) == req_id:
			r = x
	if r.is_empty():
		return {"result": "failed", "text": "That ask has lapsed."}
	requests.erase(r)
	var b: NPC = w.npc(int(r.npc))
	if b == null or not b.alive:
		return {"result": "failed", "text": "They are gone."}
	if not accept:
		refused[b.id] = w.day() + int(cfg().refuse_days)
		return {"result": "refused", "text": "You turn %s down." % b.name}
	if str(r.mode) == "barter":
		var q := barter(w.player, b, str(r.item), int(r.qty), str(r.give))
		return {"result": q.result, "text": q.text}
	var bill := _sum(ask_prices(w.player, b, str(r.item), int(r.qty)))
	var c := sell_on_credit(w.player, b, str(r.item), int(r.qty), bill)
	return {"result": c.result, "text": c.text}


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


## Whether `cause` (PlayerState.death_cause) is a killing by a person, the villagers' "slain" (hunger, bad food, old age,
## a beast and a mine collapse are not).
static func slain_cause(cause: String) -> bool:
	return not (cause in ["", "hunger", "spoiled food", "old age"] or cause.begins_with("a ") or cause.begins_with("crushed"))


## The player died (World.continue_as_heir, before the heir): their debts and the claims on them pass to the player's heir by
## the villagers' rule. The heir carries the name "player", so the records stay as they are; written off (lost) where a
## villager's would be: the player was slain, or the other party is the child who now becomes the heir (`kid`, or null).
func on_player_died(slain := false, kid: NPC = null) -> void:
	var kid_ref := ref_of(kid) if kid != null else ""
	for x in debts:
		if not standing(x) or not (w.is_acting_ref(x.debtor) or w.is_acting_ref(x.creditor)):
			continue                           # MP Batch B: only the dying player's own debts and claims (one player: every player's)
		var other: String = x.creditor if w.is_acting_ref(x.debtor) else x.debtor
		if slain or other == kid_ref:
			_end(x, LOST)
			w.stat("credit_lost")
		else:
			w.stat("credit_passed")


# ---------------------------------------------------------------- saving ---------------------
## Nothing to save: no debt, ask or remembered refusal.
func is_empty() -> bool:
	return debts.is_empty() and requests.is_empty() and refused.is_empty()


func to_dict() -> Dictionary:
	var out := []
	for x in debts:
		out.append((x as Dictionary).duplicate())
	var d := {"next_id": next_id, "debts": out}
	if not requests.is_empty() or not refused.is_empty():       # optional, like the key itself
		var rs := []
		for x in requests:
			rs.append((x as Dictionary).duplicate())
		var rf := {}
		for k in refused:
			rf[str(k)] = int(refused[k])
		d["requests"] = rs
		d["next_req"] = next_req
		d["refused"] = rf
	return d


func load_dict(dd: Dictionary) -> void:
	debts.clear()
	requests.clear()
	refused.clear()
	next_id = int(dd.get("next_id", 1))
	next_req = int(dd.get("next_req", 1))
	for x in dd.get("requests", []):
		requests.append({"id": int(x.id), "npc": int(x.npc), "item": str(x.item), "qty": int(x.qty), "mode": str(x.mode), "give": str(x.give),
				"give_qty": int(x.give_qty), "value": int(x.value), "day": int(x.day)})
	var rf: Dictionary = dd.get("refused", {})
	for k in rf:
		refused[int(k)] = int(rf[k])
	for x in dd.get("debts", []):
		debts.append({"id": int(x.id), "creditor": str(x.creditor), "debtor": str(x.debtor), "item": str(x.item), "qty": int(x.qty),
				"value": int(x.value), "made": int(x.made), "due": int(x.due), "state": str(x.state), "ended": int(x.get("ended", -1))})
