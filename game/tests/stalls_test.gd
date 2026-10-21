extends SceneTree
## STALL-01..STALL-06 and the stall commission's part of TREAS-01 (owner directive 2026-10-21, Q8, Q10, Q12, Q13):
## a stall built from three planks of the builder's own pack on clear ground; goods moved into it exist in one place;
## OPEN STALL sells unattended to real buyers through Business's one sale path; the open session's proceeds cannot be
## taken; CLOSE STALL settles 5% to the treasury exactly, the fraction carried in hundredths, the rest to the seller;
## selling out closes and settles; it reopens at once; the manor's pitches and the merchants' stalls pay the same 5%,
## once; a villager household builds, stocks, opens and sells out by the same rules; coins and goods are conserved;
## save and load keep it all. Pure World, deterministic (seed 1). Run:
##   godot --headless --path game --script res://tests/stalls_test.gd

const Census := preload("res://tests/census.gd")

var failures := 0
var checks := 0
var w: World
var map: VillageMap


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	map = VillageMap.load_default()
	w = World.new()
	w.setup(map, 1)
	w.minutes = 1440.0 + 10.0 * 60.0            # day 1, 10:00 (each part checks its own coins: the test sets purses)
	var built := _build()
	_stock(built)
	_unattended(built)
	_settlement(built)
	_sell_out_reopen(built)
	_pitch()
	_merchant()
	_npc_cycle()
	_save_load(built)
	_save_exact()
	_vacancy()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _adult(job: String, skip: Array = []) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job == job and not skip.has(n):
			return n
	return null


func _goods_less(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := {}
	for id in a:
		if int(a[id]) != int(b.get(id, 0)):
			out[id] = int(a[id]) - int(b.get(id, 0))
	for id in b:
		if not a.has(id):
			out[id] = -int(b[id])
	return out


func _busy_all() -> void:
	for n: NPC in w.npcs:
		n.plan = [{"k": "work", "min": 99999.0, "anim": "work"}]


# ---------------------------------------------------------------- STALL-01: building ----------
func _build() -> Dictionary:
	var st: Stalls = w.business.stalls
	var p := w.player
	p.inv.items.clear()
	var c := st.find_site(World.PLAYER)
	check(c.x >= 0 and st.site_refusal(c, World.PLAYER) == "", "there is clear ground for a stall near the market (%s)" % str(c))
	check(st.site_refusal(Vector2i(int(w.stalls.stall0.x), int(w.stalls.stall0.y)), World.PLAYER) != "", "not on another stall")
	var road: Array = map.data.road[0]
	check(st.site_refusal(Vector2i(int(road[0]), int(road[1])), World.PLAYER) != "", "not on the road")
	check(Stalls.cost().size() == 1 and int(Stalls.cost().get("plank", 0)) == 3,"a stall costs three planks (owner Q10)")
	p.inv.add("plank", 2)
	var n0 := w.stalls.size()
	check(w.construction.build_stall(World.PLAYER, c, p.inv) != "" and w.stalls.size() == n0 and p.inv.count("plank") == 2, "two planks build nothing and take nothing")
	p.inv.add("plank", 3)
	var used := float(w.stats.get("used_building_plank", 0.0))
	var goods := Census.goods(w)
	check(w.construction.build_stall(World.PLAYER, c, p.inv) == "", "built through the construction system with three planks")
	var s: Dictionary = w.business.stalls.built(World.PLAYER)[0]
	check(p.inv.count("plank") == 2 and float(w.stats.get("used_building_plank", 0.0)) == used + 3.0, "the three planks left the pack and are counted as used in building")
	check(_goods_less(goods, Census.goods(w)) == {"plank": 3}, "the only goods gone are the three planks consumed")
	check(Stalls.is_built(s) and w.owner_of(s) == World.PLAYER and w.holds(World.PLAYER, s) and not st.is_open(s), "the stall is the player's, closed")
	check(map.is_solid(Vector2i(int(s.x), int(s.y))) and map.is_solid(Vector2i(int(s.x) + 1, int(s.y))) and not map.is_solid(Vector2i(int(s.use[0]), int(s.use[1]))), "its awning is solid with a free place to serve from")
	check(st.site_refusal(c, World.PLAYER) != "", "the ground is taken now")
	check(w.business.premises().has(s) and w.business.mine().is_empty() and w.business.rent_of(s) == 0, "one of the player's premises, not a rented pitch, no rent (the 5% lease)")
	return s


# ---------------------------------------------------------------- STALL-02: its own inventory --
func _stock(s: Dictionary) -> void:
	var b: Business = w.business
	var p := w.player
	p.inv.add("plank", 18)
	p.inv.add("axe", 1)
	var goods := Census.goods(w)
	check(b.stalls.open(s, World.PLAYER) != "", "an empty stall cannot be opened")
	check(b.list_item(s, "plank", 20) == "" and b.list_item(s, "axe", 1) == "", "goods go into the stall")
	check(p.inv.count("plank") == 0 and int(s.stock.plank) == 20 and int(s.stock.axe) == 1, "they left the pack for the stall's stock")
	check(Census.goods(w) == goods, "and exist in one place only: no good gained or lost")
	check(b.unlist(s, "plank", 5) == "" and p.inv.count("plank") == 5 and int(s.stock.plank) == 15 and Census.goods(w) == goods, "taken back, still one place")
	b.list_item(s, "plank", 5)


# ---------------------------------------------------------------- STALL-03: open, unattended ----
func _unattended(s: Dictionary) -> void:
	var b: Business = w.business
	var st: Stalls = b.stalls
	check(st.open(s, World.PLAYER) == "" and st.is_open(s), "OPEN STALL")
	w.player.pos = Vector2(3, 3)
	check(not b.player_near(s) and b.attended(s), "it sells with nobody at it")
	_busy_all()
	var wc := _adult("woodcutter")
	wc.plan = []
	wc.inv.items.erase("axe")
	wc.coins = 100
	b.heading.clear()
	b.hour()
	check(b.heading.has(wc.id) and wc.plan.size() == 2 and wc.plan[1].act == "buy_stall" and str(wc.plan[1].args.stall) == str(s.id),
		"the hourly round sends a woodcutter who needs an axe to the stall, the player far away")
	var coins := w.total_coins()
	var purse := w.player.coins
	var paid := wc.coins
	check(b.arrive(wc, {"stall": s.id, "item": "axe"}) and wc.inv.has("axe"), "he buys the axe with nobody at the stall")
	paid -= wc.coins
	check(paid > 0 and int(s.till) == paid and st.unsettled(s) == paid and str(s.sales[-1].by) == "unattended", "his %d coins are in the till as the session's sales" % paid)
	check(w.player.coins == purse and st.withdrawable(s) == 0, "the proceeds are not the player's yet: nothing can be taken while it is open (Q13)")
	check(w.total_coins() == coins, "coins conserved by the sale")
	check(b.offer(wc, s).is_empty(), "the need met, he buys nothing more")
	var farmer := _adult("farmer")
	farmer.coins = 500
	check(b.offer(farmer, s).is_empty(), "a villager with no need for its goods buys nothing")


# ---------------------------------------------------------------- STALL-04, -05: closing ---------
func _settlement(s: Dictionary) -> void:
	var b: Business = w.business
	var st: Stalls = b.stalls
	var buyer := _adult("carpenter")
	buyer.coins = 2000
	buyer.inv.items.clear()
	# finish the axe's session first: a whole sale of its own
	var axe_gross := st.unsettled(s)
	var t0 := w.treasury
	var p0 := w.player.coins
	var r := st.close(s)
	var c_axe: int = (axe_gross * 5) / 100
	check(int(r.commission) == c_axe and w.treasury == t0 + c_axe and w.player.coins == p0 + axe_gross - c_axe and int(s.till) == 0, "CLOSE STALL: the axe's %d coins settled, %d to the manor" % [axe_gross, c_axe])
	check(not st.is_open(s) and int(s.stock.plank) == 20, "sales stop; the unsold goods stay in the stall")
	check(not b.attended(s), "a closed stall sells nothing")
	var frac0 := int(s.frac)
	# 30 coins sold: 1.5 coins due, 1 paid, half a coin carried
	check(st.open(s, World.PLAYER) == "", "opened again at once")
	var coins := w.total_coins()
	t0 = w.treasury
	p0 = w.player.coins
	check(b.sell(s, buyer, "plank", 3, 10), "a sale of 3 planks at 10")
	var due := st.due(s)
	r = st.close(s)
	var h := 30 * 5 + frac0
	check(int(r.gross) == 30 and int(r.commission) == h / 100 and int(s.frac) == h % 100, "30 coins sold: %d coin to the manor, %d hundredths carried (Q8)" % [h / 100, h % 100])
	check(due == Vector2i(int(r.commission), int(s.frac)), "the window's figure is what was settled")
	check(w.treasury == t0 + h / 100 and w.player.coins == p0 + 30 - h / 100 and w.total_coins() == coins, "only whole coins moved: treasury +%d, the seller +%d, none made or lost" % [h / 100, 30 - h / 100])
	var frac1 := int(s.frac)
	# 10 more: the carried fraction makes up the next coin
	st.open(s, World.PLAYER)
	t0 = w.treasury
	b.sell(s, buyer, "plank", 1, 10)
	r = st.close(s)
	h = 10 * 5 + frac1
	check(int(r.commission) == h / 100 and int(s.frac) == h % 100 and w.treasury == t0 + h / 100, "10 coins sold with %d hundredths carried: %d coin, %d carried" % [frac1, h / 100, h % 100])
	# the owner's example: 100 sold, 5 to the treasury, 95 to the seller
	s.frac = 0
	st.open(s, World.PLAYER)
	t0 = w.treasury
	p0 = w.player.coins
	b.sell(s, buyer, "plank", 10, 10)
	r = st.close(s)
	check(int(r.commission) == 5 and int(r.net) == 95 and w.treasury == t0 + 5 and w.player.coins == p0 + 95 and int(s.frac) == 0, "100 sold: 5 to the treasury, 95 to the seller")
	check(s.settlements.size() >= 3 and int(s.settlements[-1].gross) == 100 and int(s.settlements[-1].commission) == 5, "each settlement is recorded")
	# no session is settled twice; an empty session charges nothing
	t0 = w.treasury
	p0 = w.player.coins
	r = st.close(s)
	check(int(r.commission) == 0 and int(r.net) == 0 and w.treasury == t0 and w.player.coins == p0, "closing again settles nothing more")


func _sell_out_reopen(s: Dictionary) -> void:
	var b: Business = w.business
	var st: Stalls = b.stalls
	var buyer := _adult("carpenter")
	var left := int(s.stock.get("plank", 0))
	check(left > 0 and st.open(s, World.PLAYER) == "", "open with %d planks left" % left)
	var t0 := w.treasury
	var p0 := w.player.coins
	var frac0 := int(s.get("frac", 0))
	var notes := w.log_lines.size()
	check(b.sell(s, buyer, "plank", left, 2), "the last planks sell")
	var h := left * 2 * 5 + frac0
	check(s.stock.is_empty() and not st.is_open(s) and not s.has("session"), "sold out: the stall closed itself")
	check(w.treasury == t0 + h / 100 and w.player.coins == p0 + left * 2 - h / 100 and str(s.settlements[-1].why) == "sold out", "and settled (%d to the manor)" % (h / 100))
	check(w.log_lines.size() > notes and str(w.log_lines[-1]).contains("sold out"), "with a notice: " + str(w.log_lines[-1]))
	w.player.inv.add("log", 4)
	check(st.open(s, World.PLAYER) != "", "nothing to sell: it stays closed")
	check(b.list_item(s, "log", 4) == "" and st.open(s, World.PLAYER) == "" and st.is_open(s), "restocked and reopened at once")
	st.close(s)


# ---------------------------------------------------------------- Q12: the pitches ---------------
func _pitch() -> void:
	var b: Business = w.business
	var st: Stalls = b.stalls
	var p := w.player
	p.coins = 200
	check(b.rent() == "", "a pitch is rented as before (%d coins a day)" % Business.rent_day())
	var s := b.mine()
	check(st.is_open(s) and st.is_market(s), "a rented pitch is an open market stall")
	p.inv.add("plank", 4)
	b.list_item(s, "plank", 4)
	p.pos = b.use_cell(s)
	var buyer := _adult("carpenter")
	var coins := w.total_coins()
	var t0 := w.treasury
	var c0 := float(w.stats.get("gov_stall_commission", 0.0))
	var frac0 := int(s.get("frac", 0))
	check(b.sell(s, buyer, "plank", 3, 10), "a sale at the pitch")
	var h := 30 * 5 + frac0
	check(b.collect(s) == 30 - h / 100 and w.treasury == t0 + h / 100, "collecting closes the pitch's session: %d to the manor" % (h / 100))
	check(float(w.stats.get("gov_stall_commission", 0.0)) == c0 + float(h / 100), "the commission is counted once")
	check(st.close(s).commission == 0 and w.treasury == t0 + h / 100, "and never again for the same sales")
	# the daily rent is the pitch's own charge and stays; it is not a commission
	w.minutes += 1440.0
	var p1 := p.coins
	b.daily()
	check(p.coins == p1 - Business.rent_day() and w.treasury == t0 + h / 100 + Business.rent_day(), "the morning's rent is the pitch's rent, apart from the 5%")
	check(w.total_coins() == coins, "coins conserved at the pitch")
	check(b.close(s) != "" and w.tenant_of(s) == "", "the pitch is given up")
	w.minutes -= 1440.0


# ---------------------------------------------------------------- Q12: the merchants' stalls -----
func _merchant() -> void:
	var st: Stalls = w.business.stalls
	var s: Dictionary = w.stalls.stall0
	var m: NPC = w.party(w.tenant_of(s))
	check(m != null and m.job == "merchant" and st.is_merchant_stall(s), "stall0 is a merchant's")
	m.pos = Vector2(int(s.use[0]) + 0.5, int(s.use[1]) + 0.5)
	m.target = -1
	m.anim = "idle"
	check(w.at_post(m) and st.is_open(s), "the merchant at the stall: it is open")
	var buyer := _adult("farmer")
	buyer.coins = 500
	var item: String = ""
	for id in m.inv.ids():
		if buyer.inv.can_add(id) and GameData.value(id) > 0:
			item = id
			break
	m.inv.add(item, 30)
	var coins := w.total_coins()
	var mc := m.coins
	var bc := buyer.coins
	var t0 := w.treasury
	var frac0 := int(s.get("frac", 0))
	check(w.trade(buyer, m, item, 4, 10), "a villager buys 4 %s at 10 from the merchant at the stall" % item)
	check(buyer.coins == bc - 40 and m.coins == mc and int(s.till) == 40 and st.unsettled(s) == 40, "the 40 coins wait in the stall's till, not the merchant's purse (Q13)")
	check(w.total_coins() == coins, "coins conserved (the till counts)")
	st.hour()
	check(int(s.till) == 40, "while the merchant is at the stall it stays open")
	m.pos = Vector2(5, 5)
	st.hour()
	var h := 40 * 5 + frac0
	check(int(s.till) == 0 and not s.has("session") and w.treasury == t0 + h / 100 and m.coins == mc + 40 - h / 100, "the merchant left the stall: the session settled, %d to the manor, %d to the merchant" % [h / 100, 40 - h / 100])
	check(w.total_coins() == coins, "coins conserved by the merchant's settlement")
	var t1 := w.treasury
	st.hour()
	check(w.treasury == t1, "settled once only")
	var mc2 := m.coins
	check(w.trade(buyer, m, item, 1, 10) and m.coins == mc2 + 10 and int(s.get("till", 0)) == 0, "away from the stall a merchant's sale is not a stall sale (no commission)")


# ---------------------------------------------------------------- STALL-06: a household ----------
func _npc_cycle() -> void:
	var st: Stalls = w.business.stalls
	var b: Business = w.business
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.home != "" and w.buildings.has(o.home) and st.of_household(o.household).is_empty() and o.job != "merchant":
			n = o
			break
	check(n != null, "a household adult")
	var house: Dictionary = w.buildings[n.home]
	var pantry: Inventory = w.households[n.household].pantry
	var keep := int(NPCBrain.hp_cfg().poultice_keep)
	pantry.items.erase("herbal_poultice")
	pantry.add("herbal_poultice", keep + 4)
	n.inv.items.erase("plank")
	n.coins = 0
	check(not st.plan_npc(n, house), "no planks and no coins to buy them: no stall")
	n.inv.add("plank", 3)
	st._looked.clear()
	var goods := Census.goods(w)
	check(st.plan_npc(n, house) and str(n.plan[-1].get("act", "")) == "build_stall", "with surplus and three planks of their own they set out to build one: " + n.doing)
	var a: Dictionary = n.plan[-1].args
	check(w.brain.act(n, "build_stall", a), "the villager builds it")
	var s := st.of_household(n.household)
	check(not s.is_empty() and w.holds(World.hh_ref(n.household), s) and n.inv.count("plank") == 0, "the household's stall, from their own planks")
	check(_goods_less(goods, Census.goods(w)) == {"plank": 3}, "only the three planks were used")
	check(st.plan_npc(n, house) and str(n.plan[-1].get("act", "")) == "stall_stock", "then they go to stock it: " + n.doing)
	goods = Census.goods(w)
	check(w.brain.act(n, "stall_stock", n.plan[-1].args), "stocked and opened")
	check(st.is_open(s) and int(s.stock.get("herbal_poultice", 0)) == 4 and pantry.count("herbal_poultice") == keep, "the surplus moved from the pantry into the stall; the household keeps its %d" % keep)
	check(Census.goods(w) == goods, "goods in one place only")
	check(not st.plan_npc(n, house), "an open stall needs nothing more")
	# a hurt villager of another household buys a poultice; a household member does not buy its own goods
	var mate: NPC = null
	var buyer: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o != n and o.job != "merchant":
			if o.household == n.household and mate == null:
				mate = o
			elif o.household != n.household and buyer == null:
				buyer = o
	for who: NPC in [mate, buyer]:
		if who != null:
			who.hp = who.max_hp * 0.3
			for m in NPCBrain.MEDICINES:
				who.inv.items.erase(m)
			who.coins = 100
	if mate != null:
		check(b.offer(mate, s).is_empty(), "a member of the household does not buy from its own stall")
	for m in NPCBrain.MEDICINES:
		(w.households[buyer.household].pantry as Inventory).items.erase(m)
	var o := b.offer(buyer, s)
	check(o.get("item", "") == "herbal_poultice", "a hurt villager needs a poultice: " + str(o))
	var head := w.party(World.hh_ref(n.household))
	var b2 := _adult("carpenter")
	b2.coins = 500
	var hc := head.coins
	var t0 := w.treasury
	var coins := w.total_coins()
	check(b.arrive(buyer, {"stall": s.id, "item": "herbal_poultice"}) and buyer.inv.has("herbal_poultice"), "the villager buys it at the unattended stall")
	var price := b.price_of(s, "herbal_poultice") if s.stock.has("herbal_poultice") else GameData.value("herbal_poultice")
	check(head.coins == hc and int(s.till) == price, "the household's proceeds wait in the till")
	# the rest sells out: the stall closes and settles to the household
	var rest := int(s.stock.get("herbal_poultice", 0))
	var frac0 := int(s.get("frac", 0))
	check(b.sell(s, b2, "herbal_poultice", rest, price), "the rest sells")
	var gross := price * (rest + 1)
	var h := gross * 5 + frac0
	check(not st.is_open(s) and s.stock.is_empty(), "sold out: closed")
	check(w.treasury == t0 + h / 100 and head.coins == hc + gross - h / 100, "settled: %d to the manor, %d to the household" % [h / 100, gross - h / 100])
	check(w.total_coins() == coins, "coins conserved through the household's stall")
	# restock when there is surplus again
	pantry.add("herbal_poultice", 2)
	check(st.plan_npc(n, house) and w.brain.act(n, "stall_stock", n.plan[-1].args) and st.is_open(s) and int(s.stock.herbal_poultice) == 2, "more surplus: restocked and reopened")
	check(w.business.stalls.npc_built().has(s) and not w.business.premises().has(s), "a villager's stall, not one of the player's premises")


# ---------------------------------------------------------------- save and load -------------------
func _save_load(s: Dictionary) -> void:
	var st: Stalls = w.business.stalls
	w.player.inv.add("plank", 3)
	w.business.list_item(s, "plank", 3)
	st.open(s, World.PLAYER)
	s.till = 7
	st.record_sale(s, World.PLAYER, "plank", 1, 7)
	s.frac = 35
	var coins := w.total_coins()
	var goods := Census.goods(w)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var map2 := VillageMap.load_default()
	var w2 := World.new()
	w2.load_dict(map2, d)
	var s2: Dictionary = w2.stalls[str(s.id)]
	check(Stalls.is_built(s2) and w2.owner_of(s2) == World.PLAYER and w2.business.stalls.is_open(s2), "save and load keep the built stall, open")
	check(int(s2.stock.plank) == int(s.stock.plank) and int(s2.till) == 7 and w2.business.stalls.unsettled(s2) == 7 and int(s2.frac) == 35, "its stock, till, open session and carried fraction")
	check(map2.is_solid(Vector2i(int(s2.x), int(s2.y))), "it is drawn solid again")
	check(w2.total_coins() == coins and Census.goods(w2) == goods, "every coin and good is there after loading")
	var t0 := w2.treasury
	var r := w2.business.stalls.close(s2)
	var h := 7 * 5 + 35
	check(int(r.commission) == h / 100 and w2.treasury == t0 + h / 100 and int(s2.frac) == h % 100, "the loaded session settles with the carried fraction (%d coin)" % (h / 100))
	# an older save: no built stalls, no session fields
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	for id in old.stalls.keys():
		if bool(old.stalls[id].get("built", false)):
			old.stalls.erase(id)
		else:
			for k in ["open", "session", "frac", "settlements"]:
				old.stalls[id].erase(k)
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.business.stalls.built().is_empty() and not w3.business.stalls.is_open(w3.stalls.pitch0), "an older save loads with no built stalls and nothing open")


## A built stall with stock, an open session made of real sales and a carried fraction survives to_dict / load_dict
## exactly: the record is identical, a second round trip is identical, and the session goes on and settles as it would have.
func _save_exact() -> void:
	var b: Business = w.business
	var st: Stalls = b.stalls
	var s: Dictionary = st.built(World.PLAYER)[0]
	st.close(s)
	w.player.inv.add("plank", 8)
	b.list_item(s, "plank", 8)
	b.set_price(s, "plank", 7)
	s.frac = 65
	check(st.open(s, World.PLAYER) == "", "open with planks at 7 and 65 hundredths carried")
	var buyer := _adult("carpenter")
	buyer.coins = 500
	check(b.sell(s, buyer, "plank", 3, 7), "3 planks sold in the session (21 coins)")
	var before: String = JSON.stringify(JSON.parse_string(JSON.stringify(s)), "", true)          # as a save writes it (numbers as JSON numbers)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var s2: Dictionary = w2.stalls[str(s.id)]
	check(JSON.stringify(s2, "", true) == before, "the stall's record is the same after loading, field for field")
	check(w2.business.stalls.is_open(s2) and w2.business.stalls.unsettled(s2) == 21 and int(s2.till) == 21 and int(s2.frac) == 65 and int(s2.stock.plank) == int(s.stock.plank) and int(s2.prices.plank) == 7,
		"open, 21 coins of session sales in the till, 65 hundredths carried, the planks at 7")
	var d2: Dictionary = JSON.parse_string(JSON.stringify(w2.to_dict(), "", true, true))
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d2)
	check(JSON.stringify(w3.stalls[str(s.id)], "", true) == before, "and after a second save and load")
	# the session continues in both worlds alike and settles the same
	var r1 := []
	for ww: World in [w, w2]:
		var ss: Dictionary = ww.stalls[str(s.id)]
		var by: NPC = null
		for n: NPC in ww.npcs:
			if n.alive and n.role == "adult" and n.job == "carpenter":
				by = n
				break
		by.coins = 500
		ww.business.sell(ss, by, "plank", 2, 7)
		var t0 := ww.treasury
		var r := ww.business.stalls.close(ss)
		r1.append([int(r.gross), int(r.commission), int(r.net), int(ss.frac), ww.treasury - t0])
	var h := 35 * 5 + 65
	check(r1[0] == r1[1] and r1[0] == [35, h / 100, 35 - h / 100, h % 100, h / 100], "the loaded session settles exactly as the unsaved one: %s" % str(r1[0]))


## The merchant-hiring code (NPCBrain._install) lets only a vacant merchants' stall: never a vacant pitch (the player's
## to rent, PL1-10) or a built stall left by a household that died out (the manor's, STALL-01).
func _vacancy() -> void:
	var st: Stalls = w.business.stalls
	var s: Dictionary = {}
	for x in st.npc_built():
		s = x
	var h := World.ref_id(w.holder_of(s))
	w.property.household_ended(h)
	check(w.owner_of(s) == World.MANOR and w.tenant_of(s) == "", "a household that dies out leaves its built stall to the manor, untenanted until the morning")
	var p1: Dictionary = w.stalls.pitch1
	check(w.tenant_of(p1) == "" and w.tenant_of(w.stalls.pitch0) == "", "both pitches are vacant")
	var idle: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job == "" and n.household >= 0 and n.household != h:
			idle = n
			break
	if idle == null:
		idle = _adult("laborer")
	var job0 := idle.job
	w.brain._install(idle, {"job": "merchant", "workplace": "stall0", "household": idle.household}, "test")
	check(idle.job == job0 and w.tenant_of(s) == "" and w.tenant_of(p1) == "" and w.tenant_of(w.stalls.pitch0) == "",
		"with every merchants' stall let, nobody is made a merchant of a pitch or the built stall")
	w.brain._install(idle, {"job": "merchant", "workplace": "pitch1", "household": idle.household}, "test")
	check(idle.job == job0 and w.tenant_of(p1) == "", "not even when the post names a pitch")
	var m: NPC = w.party(w.tenant_of(w.stalls.stall3))
	w.set_tenant(w.stalls.stall3, "")
	w.brain._install(idle, {"job": "merchant", "workplace": "stall0", "household": idle.household}, "test")
	check(idle.job == "merchant" and idle.workplace == "stall3" and w.tenant_of(w.stalls.stall3) == World.npc_ref(idle.id), "a vacant merchants' stall is still let as before")
	check(m != null, "(stall3's merchant set aside for the test)")
	w.minutes += 1440.0
	st.daily()
	check(w.tenant_of(s) == World.MANOR and s.stock.is_empty() and not st.is_open(s), "the next morning the stall is the manor's, closed, its goods in the granary")
