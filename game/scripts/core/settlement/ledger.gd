class_name SettlementLedger
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-C; PROS-18): an abstract settlement's books -- the off-map settlements of the
## regional economy (spec s.7 intermediate phase: "abstract off-map settlements with distinct finite stocks, needs,
## productive strengths and budgets") and the fixtures standing in for further settlements until SET-E. The live
## village is NOT one of these: its goods and coins stay in the World's own holders (no duplicated ledger); the
## village enters regional calculations only as a read-only snapshot (SettlementReport.as_ledger), and in this
## prospective branch nothing writes back to it.
##
## Every change is an explicit, journaled line (spec s.7 "explicit restocking and settlement-accounting rules; avoid
## unexplained daily currency creation"):
##   produce   goods made by the settlement's modeled labour (its `production`, a day's output; like extraction or
##             a recipe in the village, the only way goods enter a ledger besides trade)
##   consume   goods its people use up (its `needs`, a day's use); what it lacks is a recorded shortage, never filled
##   income    coins from an explicit, configured income line (`income_per_day`; 0 by default; owner question Q18-3)
##   buy/sell  matched transfers with another settlement (RegionalMarket.execute), equal and opposite
## so goods(end) = goods(start) + produced - consumed + bought - sold and coins likewise, checked by `balanced()`.

var id := ""
var name := ""
var pos := Vector2i.ZERO          # its place on the regional map (route planning), in tiles
var population := 0
var coins := 0
var stock := Inventory.new()
var needs := {}                   # item -> units a day its people use
var production := {}              # item -> units a day its labour makes
var income_per_day := 0           # explicit outside income (Q18-3); 0 = closed purse
var transport := {"handcart": 0}  # vehicles it can send (TradeRoutes.capacity)
var capabilities := {}            # {industry: level} (fixtures; SettlementIndustries for real facts)
var sale_limit = null             # null: anything beyond its reserve is for sale; else {item: most units for sale}
                                  # (the village snapshot: only its traders' and producers' goods, not pantries)
var local_supply := {}            # {item: units} it can still extract itself (its own reachable seams, through the
                                  # mining adapter): counted against its demand, never as stock or for sale
var journal: Array = []           # [{day, kind, item, n, coins, with}]
var start := {}                   # the opening books (balanced() checks against them)
var keep_journal := true


static func make(d: Dictionary) -> SettlementLedger:
	var l := SettlementLedger.new()
	l.id = str(d.id)
	l.name = str(d.get("name", d.id))
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
	l.capabilities = (d.get("capabilities", {}) as Dictionary).duplicate()
	l.open_books()
	return l


## Take the current holdings as the opening books (balanced() measures every line from here).
func open_books() -> void:
	start = {"coins": coins, "stock": stock.items.duplicate()}
	journal.clear()


## A day's production, use and income. Fractional rates accumulate deterministically: on day `day` the settlement
## makes floor(rate * (day + 1)) - floor(rate * day) units, so 0.5 a day is one unit every second day.
func tick(day: int) -> void:
	var ids := production.keys()
	ids.sort()
	for k in ids:
		var n := _due(float(production[k]), day)
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


func _log(day: int, kind: String, item: String, n: int, c: int, with: String) -> void:
	if keep_journal:
		journal.append({"day": day, "kind": kind, "item": item, "n": n, "coins": c, "with": with})


## Lines of a kind summed: {item: n} (goods) and coins.
func totals() -> Dictionary:
	var out := {"produce": {}, "consume": {}, "shortage": {}, "buy": {}, "sell": {}, "coins_in": 0, "coins_out": 0, "income": 0}
	for e in journal:
		if out.has(e.kind) and e.item != "":
			out[e.kind][e.item] = int(out[e.kind].get(e.item, 0)) + int(e.n)
		if e.kind == "sell":
			out.coins_in += int(e.coins)
		elif e.kind == "buy":
			out.coins_out += int(e.coins)
		elif e.kind == "income":
			out.income += int(e.coins)
	return out


## Whether the books balance from the opening: every good and coin accounted for by a journal line. "" when they
## do, else what does not.
func balanced() -> String:
	var t := totals()
	var c0 := int(start.coins) + int(t.income) + int(t.coins_in) - int(t.coins_out)
	if c0 != coins:
		return "%s coins %d, books say %d" % [id, coins, c0]
	var ids := {}
	for k in start.stock:
		ids[k] = true
	for k in stock.items:
		ids[k] = true
	for k in ids:
		var want := int(start.stock.get(k, 0)) + int(t.produce.get(k, 0)) - int(t.consume.get(k, 0)) \
			+ int(t.buy.get(k, 0)) - int(t.sell.get(k, 0))
		if want != stock.count(k):
			return "%s %s %d, books say %d" % [id, k, stock.count(k), want]
	return ""


func to_dict() -> Dictionary:
	return {"id": id, "name": name, "pos": [pos.x, pos.y], "population": population, "coins": coins,
		"stock": stock.items.duplicate(), "needs": needs.duplicate(), "production": production.duplicate(),
		"income_per_day": income_per_day, "transport": transport.duplicate(), "capabilities": capabilities.duplicate()}


static func from_dict(d: Dictionary) -> SettlementLedger:
	return make(d)
