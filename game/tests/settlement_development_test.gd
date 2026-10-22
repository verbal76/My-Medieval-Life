extends SceneTree
## Expansion 18, SET-D (owner B18-DP-05): settlements grow, decline and specialize by the village's own rules at off-map detail.
##   - a trade the settlement lacks opens when its goods go unmet week after week and a household settled in another trade has
##     the savings for its working reserve; with no unmet demand nothing opens
##   - a business with no living worker household closes (till to the treasury, stock to the traders or the granary); coins and
##     goods are conserved; the place (horses, reserve) is kept and can open again
##   - a business's output follows its living workers
##   - deterministic; saved and loaded without a trace; an older save (no `closed`, `dev`, `idle`) loads and goes on
##   godot --headless --path game --script res://tests/settlement_development_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_opening()
	test_no_demand_no_opening()
	test_closing()
	test_closing_books()
	test_reopening()
	test_capacity_follows_workers()
	test_determinism_save_old_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _json(d: Dictionary) -> String:
	return JSON.stringify(d, "", true, true)


func _netherton() -> OffMapSettlement:
	return Regions.create(1).by_id["netherton"]


## Run `days` days; each day add `unmet` (item -> units) to the settlement's unmet-demand record, as buyers who found nothing would.
func _run(o: OffMapSettlement, from: int, days: int, unmet: Dictionary) -> void:
	for d in range(from, from + days):
		for item in unmet:
			OffMapSettlement._add(o.flows.unmet, item, int(unmet[item]))
		o.step_day(d)


func test_opening() -> void:
	var o := _netherton()
	check(not o.biz.has("tanner") and not o.biz.has("cook"), "Netherton starts with no tannery and no cookshop")
	var coins0 := o.coins()
	_run(o, 0, 15, {"leather": 40})
	check(o.biz.has("tanner"), "a tannery opens where leather goes unmet week after week")
	check(int(o.flows.biz_opened) >= 1, "the opening is counted (%d)" % int(o.flows.biz_opened))
	var t: Dictionary = o.biz.tanner
	check(t.workers.size() == 1 and str(o.hh[t.workers[0]].trade) == "tanner", "one household took up the trade and works it")
	var told := false
	for e in o.journal:
		told = told or "opened the tannery" in str(e.text)
	check(told, "the settlement's journal records it")
	check(o.audit() == "", "coins and goods balance after the opening (%s)" % o.audit())
	check(o.coins() == coins0, "the opening created no coin")
	var worker_biz_ok := true
	for h in o.hh:
		if h.alive and h.trade != "official":
			worker_biz_ok = worker_biz_ok and o.biz.has(OffMapSettlement.TRADE_BIZ[h.trade]) and o.biz[OffMapSettlement.TRADE_BIZ[h.trade]].workers.has(h.id)
	check(worker_biz_ok, "every working household belongs to the business of its trade")


func test_no_demand_no_opening() -> void:
	var o := _netherton()
	for d in 60:
		o.flows.unmet = {}
		o.step_day(d)
	check(int(o.flows.biz_opened) == 0, "with nothing unmet, nothing opens (60 days)")


func _empty_trade(o: OffMapSettlement, bt: String) -> void:
	for i in (o.biz[bt].workers as Array).duplicate():
		if o.hh[i].alive:
			o.release_household(i)


func test_closing() -> void:
	var o := _netherton()
	for d in 3:
		o.step_day(d)
	var horses_before := o.horses()
	_empty_trade(o, "herd")
	check(o._workers(o.biz.herd) == 0, "the herd's only household left")
	var coins_before := o.coins()
	var goods_before := o.goods()
	for d in range(3, 40):
		o.flows.unmet = {}
		o.step_day(d)
		if not o.biz.has("herd"):
			break
	check(not o.biz.has("herd") and o.closed.has("herd"), "a business with no worker household closes after two weekly looks")
	check(int(o.flows.biz_closed) == 1, "the closing is counted")
	check(o.closed.herd.workers.is_empty() and int(o.closed.herd.till) == 0 and o.closed.herd.stock.is_empty(), "its till and stock were handed on")
	check(o.audit() == "", "coins and goods balance after the closing (%s)" % o.audit())
	check(o.horses() == horses_before, "the place keeps its horses")
	check(not o.biz.merchant.is_empty(), "the traders never close")


func test_closing_books() -> void:
	var o: OffMapSettlement = Regions.create(1).by_id["garton"]
	for d in 5:
		o.step_day(d)
	var herd: Dictionary = o.biz.herd
	var till := int(herd.till)
	var stock := (herd.stock as Dictionary).duplicate()
	var coins0 := o.coins()
	var goods0 := o.goods()
	var gov0 := int(o.gov.coins)
	o._close_business("herd")
	check(o.coins() == coins0 and _json(o.goods()) == _json(goods0), "closing moves coins and goods and creates or destroys none")
	check(int(o.gov.coins) >= gov0 + till, "the till went to the treasury (%d, and the traders' payment for stock: %d in all)" % [till, int(o.gov.coins) - gov0])
	var placed := 0
	for k in stock:
		placed += int(o.gov.granary.get(k, 0)) + int(o.biz.merchant.stock.get(k, 0))
	var total := 0
	for k in stock:
		total += int(stock[k])
	check(placed >= total, "the stock is now the traders' or the treasury's (%d of %d)" % [placed, total])
	check(o.audit() == "", "and the books balance")


func test_reopening() -> void:
	var o := _netherton()
	for d in 3:
		o.step_day(d)
	_empty_trade(o, "herd")
	for d in range(3, 30):
		o.flows.unmet = {}
		o.step_day(d)
	check(o.closed.has("herd"), "the herd closed")
	# a farm household with savings (the books are told where the coins came from: an outside inflow)
	for i in o.biz.farm.workers:
		if o.hh[i].alive:
			o.hh[i].coins += 200
			o.flows.outside_coins_in += 200
			break
	_run(o, 30, 30, {"wool": 30, "meat": 30})
	check(o.biz.has("herd") and not o.closed.has("herd"), "the place opens again when its goods are unmet and a household can fund it")
	check(o.audit() == "", "the books balance after the reopening (%s)" % o.audit())


func test_capacity_follows_workers() -> void:
	var o: OffMapSettlement = Regions.create(1).by_id["garton"]
	var b: Dictionary = o.biz.forest
	var n := o._workers(b)
	var wood := float(b.out.log)
	b.acc = {}
	b.stock = {}
	var p0 := int(o.flows.produced.get("log", 0))
	o._produce()
	var made1 := int(o.flows.produced.get("log", 0)) - p0
	check(made1 == int(floor(wood * n)), "a business makes its workers' share a day (%d workers, %d logs)" % [n, made1])
	# a second, bigger business: the farm, with and without one household
	var f: Dictionary = o.biz.farm
	var fn := o._workers(f)
	f.acc = {}
	f.stock = {}
	var w0 := int(o.flows.produced.get("wheat", 0))
	o._produce()
	var full := int(o.flows.produced.get("wheat", 0)) - w0
	o.hh[f.workers[0]].alive = false
	f.acc = {}
	f.stock = {}
	w0 = int(o.flows.produced.get("wheat", 0))
	o._produce()
	var less := int(o.flows.produced.get("wheat", 0)) - w0
	check(full == int(floor(float(f.out.wheat) * fn)) and less == int(floor(float(f.out.wheat) * (fn - 1))) and less < full, "capacity follows the living workers (%d workers: %d wheat, one fewer: %d)" % [fn, full, less])


func test_determinism_save_old_save() -> void:
	var a := Regions.create(2)
	var b := Regions.create(2)
	for d in 130:
		a.step_day(d)
		b.step_day(d)
	check(_json(a.to_dict()) == _json(b.to_dict()), "the same seed gives the same openings and closings (130 days, byte-identical)")
	var opened := 0
	for s: OffMapSettlement in a.list:
		opened += int(s.flows.biz_opened)
	check(opened > 0, "the settlements opened businesses by themselves in 130 days (%d)" % opened)
	var text := _json(a.to_dict())
	var l := Regions.from_dict(JSON.parse_string(text), 2)
	check(l != null and _json(l.to_dict()) == text, "saved as JSON and loaded, the settlements are exactly as they were (closed places included)")
	for d in range(130, 160):
		a.step_day(d)
		l.step_day(d)
	check(_json(a.to_dict()) == _json(l.to_dict()), "thirty days on, the loaded copy and the original are still identical")
	check(a.audit() == "", "and the books balance (%s)" % a.audit())
	# an older save: no closed, dev or idle
	var old: Dictionary = JSON.parse_string(_json(a.to_dict()))
	for sd in old.settlements:
		sd.erase("closed")
		sd.erase("dev")
		for t in sd.biz:
			sd.biz[t].erase("idle")
	var o := Regions.from_dict(old, 2)
	check(o != null, "a save from before SET-D loads")
	for d in range(160, 190):
		o.step_day(d)
	check(o.audit() == "", "and goes on with balanced books (%s)" % o.audit())
