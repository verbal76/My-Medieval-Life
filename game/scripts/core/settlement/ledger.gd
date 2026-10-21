class_name SettlementLedger
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-C; PROS-18): the books of one PARTY to regional trade. A party is a whole abstract
## off-map settlement (spec s.7 intermediate phase: "abstract off-map settlements with distinct finite stocks, needs,
## productive strengths and budgets"), or one buyer or seller inside a settlement (owner Q18-10, 2026-10-21: "Anyone may
## purchase goods from another settlement, including individual villagers, households, merchants, businesses, and
## settlement treasuries"). `settlement` names the place a party belongs to (routes run between places); parties of
## the same place do not trade through the regional market (that is the local market's business).
##
## The live village is NOT one of these: its goods and coins stay in the World's own holders (no duplicated ledger);
## its parties enter regional calculations only as read-only snapshots (SettlementReport.parties), and in this
## prospective branch nothing writes back to the World.
##
## Every change is an explicit, journaled line (spec s.7 "explicit restocking and settlement-accounting rules; avoid
## unexplained daily currency creation"):
##   produce          goods made by the party's modeled labour (`production` a day; the only way goods enter a ledger
##                    besides trade). The capability output multiplier (Q18-11) speeds up work only where the work has a
##                    finite source: a good with `reserves` (its deposit, depleted unit by unit: "deplete" lines) or with
##                    a `recipes` entry (its inputs, taken from stock unit by unit: "use_input" lines). Elsewhere (a
##                    field's crop, labour with no modeled source) the multiplier does not raise the quantity: faster work
##                    there only saves time. A multiplier never creates a raw material.
##   consume          goods its people use up (`needs` a day); what it lacks is a recorded shortage, never filled
##   income           coins from an explicit, configured income line (`income_per_day`; 0 by default; Q18-3)
##   buy/sell         matched goods-for-coins transfers with another party (RegionalMarket.execute)
##   carriage_paid /  a matched coins-for-carriage payment from a buyer to the carter who hauls its goods (Q18-10: a
##   carriage_earned  willing carter, negotiated and paid; never free, never bundled into the price)
## so goods(end) = goods(start) + produced - consumed + bought - sold and coins likewise, checked by `balanced()`.

var id := ""
var name := ""
var settlement := ""              # the place the party belongs to (routes are between places); its own id if a settlement
var kind := "settlement"          # settlement | household | trader | treasury | villager | carter
var pos := Vector2i.ZERO          # its place on the regional map (route planning), in tiles
var population := 0
var coins := 0
var stock := Inventory.new()
var needs := {}                   # item -> units a day its people use
var production := {}              # item -> units a day its labour makes
var income_per_day := 0           # explicit outside income (Q18-3); 0 = closed purse
var transport := {"handcart": 0}  # what it can carry on its own trips (TradeRoutes.capacity)
var can_travel := true            # false: it cannot fetch goods itself (a treasury), so it must hire a carter
var carts_for_hire := false       # true: it offers carriage to others for a fee (a carter or delivery service)
var capabilities := {}            # {industry: level} (fixtures; SettlementIndustries for real facts)
var sale_limit = null             # null: anything beyond its reserve is for sale; else {item: most units for sale}
                                  # (a household's pantry is not for sale; its members' own packs are)
var reserves := {}                # {item: units} the finite deposit its production of that good draws on (mining)
var recipes := {}                 # {item: {input: units per unit}} what each unit of a made good consumes
var profile := ""                 # capability profile for analysis only ("" = the active one, neutral)
var local_supply := {}            # {item: units} it can still extract itself (its own reachable seams, through the
                                  # mining adapter): counted against its demand, never as stock or for sale
var journal: Array = []           # [{day, kind, item, n, coins, with}]
var start := {}                   # the opening books (balanced() checks against them)
var keep_journal := true


static func make(d: Dictionary) -> SettlementLedger:
	var l := SettlementLedger.new()
	l.id = str(d.id)
	l.name = str(d.get("name", d.id))
	l.settlement = str(d.get("settlement", d.id))
	l.kind = str(d.get("kind", "settlement"))
	var p: Array = d.get("pos", [0, 0])
	l.pos = Vector2i(int(p[0]), int(p[1]))
	l.population = int(d.get("population", 0))
	l.coins = int(d.get("coins", 0))
	for k in d.get("stock", {}):
		l.stock.add(str(k), int(d.stock[k]))
	for k in d.get("needs", {}):
		l.needs[str(k)] = float(d.needs[k])
	for k in d.get("production", {}):
		l.production[str(k)] = float(d.production[k])
	l.income_per_day = int(d.get("income_per_day", 0))
	l.transport = (d.get("transport", {"handcart": 0}) as Dictionary).duplicate()
	l.can_travel = bool(d.get("can_travel", true))
	l.carts_for_hire = bool(d.get("carts_for_hire", false))
	l.capabilities = (d.get("capabilities", {}) as Dictionary).duplicate()
	for k in d.get("reserves", {}):
		l.reserves[str(k)] = int(d.reserves[k])
	for k in d.get("recipes", {}):
		l.recipes[str(k)] = (d.recipes[k] as Dictionary).duplicate()
	l.profile = str(d.get("profile", ""))
	l.open_books()
	return l


## Take the current holdings as the opening books (balanced() measures every line from here).
func open_books() -> void:
	start = {"coins": coins, "stock": stock.items.duplicate(), "reserves": reserves.duplicate()}
	journal.clear()


## A day's production, use and income. Fractional rates accumulate deterministically: on day `day` the party makes
## floor(rate * (day + 1)) - floor(rate * day) units, so 0.5 a day is one unit every second day. Production is scaled by
## its industry's output factor at the party's level (Q18-9; 1.0 = no effect, the provisional default): a level never
## stops production, it only scales it.
func tick(day: int) -> void:
	var ids := production.keys()
	ids.sort()
	for k in ids:
		var ind := SettlementIndustries.industry_of(k)
		var bounded: bool = reserves.has(k) or recipes.has(k)
		var f := SettlementIndustries.output_multiplier(ind, int(capabilities.get(ind, 0)), profile) if bounded and ind != "" else 1.0
		var n := _due(float(production[k]) * f, day)
		if reserves.has(k):
			n = mini(n, int(reserves[k]))
			if n > 0:
				reserves[k] = int(reserves[k]) - n
				_log(day, "deplete", k, n, 0, "")
		if recipes.has(k):
			var ins: Dictionary = recipes[k]
			for id in ins:
				n = mini(n, stock.count(id) / maxi(1, int(ins[id])))
			for id in ins:
				if n > 0:
					stock.remove(id, n * int(ins[id]))
					_log(day, "use_input", id, n * int(ins[id]), 0, k)
		if n > 0 and stock.add(k, n):
			_log(day, "produce", k, n, 0, "")
	ids = needs.keys()
	ids.sort()
	for k in ids:
		var want := _due(float(needs[k]), day)
		var have := mini(want, stock.count(k))
		if have > 0:
			stock.remove(k, have)
			_log(day, "consume", k, have, 0, "")
		if want > have:
			_log(day, "shortage", k, want - have, 0, "")
	if income_per_day > 0:
		coins += income_per_day
		_log(day, "income", "", 0, income_per_day, "")


static func _due(rate: float, day: int) -> int:
	return int(floor(rate * float(day + 1) + 1e-9)) - int(floor(rate * float(day) + 1e-9))


func _log(day: int, kind_: String, item: String, n: int, c: int, with: String) -> void:
	if keep_journal:
		journal.append({"day": day, "kind": kind_, "item": item, "n": n, "coins": c, "with": with})


## Lines of a kind summed: {item: n} (goods) and coins.
func totals() -> Dictionary:
	var out := {"produce": {}, "consume": {}, "shortage": {}, "buy": {}, "sell": {}, "deplete": {}, "use_input": {},
		"coins_in": 0, "coins_out": 0, "income": 0,
		"carriage_paid": 0, "carriage_earned": 0}
	for e in journal:
		if out.has(e.kind) and e.item != "" and out[e.kind] is Dictionary:
			out[e.kind][e.item] = int(out[e.kind].get(e.item, 0)) + int(e.n)
		match str(e.kind):
			"sell":
				out.coins_in += int(e.coins)
			"buy":
				out.coins_out += int(e.coins)
			"income":
				out.income += int(e.coins)
			"carriage_paid":
				out.carriage_paid += int(e.coins)
			"carriage_earned":
				out.carriage_earned += int(e.coins)
	return out


## Whether the books balance from the opening: every good and coin accounted for by a journal line. "" when they
## do, else what does not.
func balanced() -> String:
	var t := totals()
	var c0 := int(start.coins) + int(t.income) + int(t.coins_in) - int(t.coins_out) + int(t.carriage_earned) - int(t.carriage_paid)
	if c0 != coins:
		return "%s coins %d, books say %d" % [id, coins, c0]
	for k in start.get("reserves", {}):
		if int(start.reserves[k]) - int(t.deplete.get(k, 0)) != int(reserves.get(k, 0)):
			return "%s reserve of %s %d, books say %d" % [id, k, int(reserves.get(k, 0)), int(start.reserves[k]) - int(t.deplete.get(k, 0))]
	var ids := {}
	for k in start.stock:
		ids[k] = true
	for k in stock.items:
		ids[k] = true
	for k in ids:
		var want := int(start.stock.get(k, 0)) + int(t.produce.get(k, 0)) - int(t.consume.get(k, 0)) \
			- int(t.use_input.get(k, 0)) + int(t.buy.get(k, 0)) - int(t.sell.get(k, 0))
		if want != stock.count(k):
			return "%s %s %d, books say %d" % [id, k, stock.count(k), want]
	return ""


func to_dict() -> Dictionary:
	return {"id": id, "name": name, "settlement": settlement, "kind": kind, "pos": [pos.x, pos.y], "population": population,
		"coins": coins, "stock": stock.items.duplicate(), "needs": needs.duplicate(), "production": production.duplicate(),
		"income_per_day": income_per_day, "transport": transport.duplicate(), "can_travel": can_travel,
		"carts_for_hire": carts_for_hire, "capabilities": capabilities.duplicate(), "reserves": reserves.duplicate(),
		"recipes": recipes.duplicate(true)}


static func from_dict(d: Dictionary) -> SettlementLedger:
	return make(d)
