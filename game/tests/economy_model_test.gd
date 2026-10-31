extends SceneTree
## Expansion 20 LE-01 model: actors (profile, controller, household), needs derived from existing state, offers over real
## goods and reservations, bounded knowledge by existing means only, contract links to CON-01, the dawn and trade
## observers, persistence (enabled, old saves, D2 while disabled), determinism, cost, and that the model only observes.
## Every contract of docs/expansion20/LE01_DATA_CONTRACTS.md (LE-01 model section) has a check here.
## Run headless:  godot --headless --path game --script res://tests/economy_model_test.gd

const Census := preload("res://tests/census.gd")
const ON := {"enabled": true, "reservations": {"keep_finished": 50}, "events": {"capacity": 64, "save": true}, "needs": {"refresh_budget": 3}, "offers": {"keep_finished": 4}}
var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(on := true, seed := 1) -> World:
	EconomyFoundation.set_override(ON if on else {})
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_disabled()
	test_actors()
	test_needs()
	test_needs_pure_and_budget()
	test_offers()
	test_knowledge()
	test_trade_observer()
	test_contract_links()
	test_dawn()
	test_determinism()
	test_save()
	test_observes_only()
	test_cost()
	test_opinion_is_weighed()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0:
			out.append(n)
	return out


func first_job(w: World, job: String) -> NPC:
	for n: NPC in adults(w):
		if n.job == job:
			return n
	return null


func snap(w: World) -> Array:
	return [w.total_coins(), Census.goods(w)]


func open_contract(w: World, seller: NPC, buyer: NPC, item: String, qty: int, days := 5) -> Dictionary:
	buyer.coins = maxi(buyer.coins, 500)
	var c: Dictionary = w.contracts._new_record(World.npc_ref(buyer.id), World.npc_ref(seller.id), item, qty, 2, days, [])
	var ok: bool = w.contracts._open(c)
	assert(ok)
	return c


# ------------------------------------------------------------------------------------------------ switch off
func test_disabled() -> void:
	var w := new_world(false)
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	a.inv.add("wheat", 3)
	b.coins = 50
	check(w.economy == null, "off: no model built")
	check(w.trade(b, a, "wheat", 1, 1) and w.economy == null, "off: World.trade runs, nothing observed")
	check(not w.to_dict().has("economy"), "off: no save key")
	var f := FileAccess.open("res://data/economy.json", FileAccess.READ)
	var j: Dictionary = JSON.parse_string(f.get_as_text())
	check(j.enabled == false and j.has("needs") and j.has("offers"), "shipped economy.json: off, with needs and offers settings")
	var od: Dictionary = j.get("owner_decisions", {})
	var want := ["OD-LE-02B", "OD-LE-10", "OD-LE-04", "OD-LE-07", "OD-LE-08", "OD-LE-13B", "OD-LE-14", "OD-LE-15"]
	var all := JSON.stringify(od)
	check(want.all(func(x): return all.contains(x)), "economy.json lists every OWNER DECISION placeholder (and the two LE-02 settled)")
	check(EconOffers.VISIBILITY.contains("OD-LE-02B") and EconKnowledge.MEMORY.contains("OD-LE-10") and EconActor.BUSINESS_IDENTITY.contains("OD-LE-04")
		and EconNeeds.SUBSTITUTION.contains("OD-LE-08") and EconContractLinks.DEATH_OF_PARTY.contains("OD-LE-13B"), "placeholders are named in code with their decision ids")


# ------------------------------------------------------------------------------------------------ actors
func test_actors() -> void:
	var w := new_world()
	var e := w.economy.actors
	var a: NPC = adults(w)[0]
	var ref := World.npc_ref(a.id)
	var p := e.profile(ref)
	check(p.kind == "npc" and p.alive and p.household == World.hh_ref(a.household) and p.controller == ref, "profile: villager with household and itself as controller")
	check(p.location == (a.workplace if a.workplace != "" else a.home), "profile: location is the workplace or home id")
	var hp := e.profile(World.hh_ref(a.household))
	check(hp.kind == "hh" and hp.household == World.hh_ref(a.household) and hp.location == str(w.households[a.household].get("home", "")), "profile: household")
	check(e.profile("player").kind == "player" and e.profile("player").household == "" and e.coins("player") == w.player.coins, "profile: the host player")
	check(not e.exists("player:987654") and e.profile("player:987654").is_empty(), "a guest ref with no player in play does not exist")
	check(e.profile("manor").controller == "manor" and e.profile("manor").alive, "profile: manor")
	var sk: Array = w.stalls.keys()
	sk.sort()
	if not sk.is_empty():
		var sref := "stall:" + str(sk[0])
		check(e.exists(sref) and e.controller(sref) == w.holder_of(w.stalls[sk[0]]), "stall till controlled by its holder (ECON-P3)")
	check(e.judged_person(ref) == a.id and e.judged_person("manor") == -1 and e.judged_person("chapel") == -1, "judged_person maps to the shared judgment model's person (no economy-side opinion)")
	if not sk.is_empty():
		var hold: String = w.holder_of(w.stalls[sk[0]])
		check(e.judged_person("stall:" + str(sk[0])) == (JudgmentLive.person_of_ref(w, hold) if e.kind(hold) in ["npc", "player", "hh"] else -1), "a till is judged as its controller")
	check(e.profile("business:1").is_empty() and e.kind("business:1") == "", "no business identity (OWNER DECISION OD-LE-04/07)")


# ------------------------------------------------------------------------------------------------ needs
func test_needs() -> void:
	var w := new_world()
	var nd := w.economy.needs
	var a: NPC = adults(w)[0]
	var hr := World.hh_ref(a.household)
	var hh: Dictionary = w.households[a.household]
	var saved_econ: Dictionary = hh.get("econ", {}).duplicate()
	hh.econ = {"days": 0.5, "need": 10.0}
	var target := float(GameData.b("reserve_days"))
	var food := nd.derive(hr).filter(func(x): return x.kind == "food")
	check(food.size() == 1 and is_equal_approx(food[0].shortfall, target - 0.5) and food[0].qty == ceili((target - 0.5) * 10.0) and food[0].substitutes.has("wheat"), "food need: days below the OD-19 horizon, in missing days and points")
	hh.econ = {"days": target + 1.0, "need": 10.0}
	check(nd.derive(hr).filter(func(x): return x.kind == "food").is_empty(), "no food need when the household covers its horizon")
	hh.econ = saved_econ
	var wc := first_job(w, "woodcutter")
	if wc != null:
		var axes := wc.inv.count("axe")
		wc.inv.remove("axe", axes)
		var wr := World.npc_ref(wc.id)
		check(nd.derive(wr).any(func(x): return x.kind == "tool" and x.item == "axe"), "tool need: a woodcutter without an axe")
		wc.inv.add("axe", 1)
		check(not nd.derive(wr).any(func(x): return x.kind == "tool"), "no tool need with the axe")
		wc.inv.remove("axe", 1)
		wc.inv.add("axe", axes)
	var sm := first_job(w, "smith")
	if sm != null:
		var sr := World.npc_ref(sm.id)
		var ore := sm.inv.count("iron_ore")
		sm.inv.remove("iron_ore", ore)
		var want: int = w.brain.wants(sm, "iron_ore")
		var inp := nd.derive(sr).filter(func(x): return x.kind == "input" and x.item == "iron_ore")
		check(want > 0 and inp.size() == 1 and inp[0].qty == want, "input need equals NPCBrain.wants (SHOP-01) for iron ore (%d)" % want)
		sm.inv.add("iron_ore", ore)
	var s2: NPC = adults(w)[2]
	var b2: NPC = adults(w)[3]
	var held := s2.inv.count("plank")
	var c := open_contract(w, s2, b2, "plank", held + 4, 3)
	var cn := nd.derive(World.npc_ref(s2.id)).filter(func(x): return x.kind == "contract")
	check(cn.size() == 1 and cn[0].item == "plank" and cn[0].qty == 4 and cn[0].deadline == int(c.deadline_day), "contract need: owed beyond stock, with the deadline")
	var c2 := open_contract(w, s2, b2, "plank", 2, 6)
	cn = nd.derive(World.npc_ref(s2.id)).filter(func(x): return x.kind == "contract")
	check(cn.size() == 1 and cn[0].qty == 6 and cn[0].deadline == int(c.deadline_day), "contract needs of one item add up, earliest deadline")
	w.contracts.cancel(c, c.buyer)
	w.contracts.cancel(c2, c2.buyer)
	check(nd.derive(World.npc_ref(s2.id)).filter(func(x): return x.kind == "contract").is_empty(), "ended contracts: no contract need")
	# housing: the household's own site
	var p: Dictionary = w.plots[0]
	var keep_site: Dictionary = p.site.duplicate(true)
	var hb := a.household
	var had_build: bool = w.households[hb].has("build")
	var old_build = w.households[hb].get("build", "")
	p.site = {"kind": "house", "cost": {"plank": 5, "stone": 3}, "need": {"plank": 2, "stone": 3}, "done": false, "owner": World.hh_ref(hb)}
	w.households[hb].build = str(p.id)
	var hs := nd.derive(World.hh_ref(hb)).filter(func(x): return x.kind == "housing")
	check(hs.size() == 2 and hs[0].item == "plank" and hs[0].qty == 2 and hs[1].item == "stone" and hs[1].qty == 3, "housing need: what the household's site still needs")
	p.site = keep_site
	if had_build:
		w.households[hb].build = old_build
	else:
		w.households[hb].erase("build")
	check(nd.derive("player").is_empty() and nd.derive("manor").is_empty(), "no needs derived for the player (OD-LE-14) or institutions")
	var dead: NPC = adults(w)[4]
	dead.alive = false
	check(nd.derive(World.npc_ref(dead.id)).is_empty(), "a dead villager has no needs")
	var all := nd.derive(World.npc_ref(adults(w)[0].id)) + nd.derive(World.hh_ref(a.household))
	check(all.all(func(x): return x.has_all(["actor", "kind", "item", "qty", "shortfall", "target", "cover_days", "deadline", "substitutes", "source", "derived_day"])), "need record carries every field")


func test_needs_pure_and_budget() -> void:
	var w := new_world()
	var nd := w.economy.needs
	var before := JSON.stringify(w.to_dict().merged({"economy": null}, true))
	var econs := JSON.stringify(w.households.map(func(h): return h.get("econ", {})))
	var s0 := snap(w)
	var refs := []
	for n: NPC in adults(w):
		refs.append(World.npc_ref(n.id))
	for h in w.households.size():
		refs.append(World.hh_ref(h))
	for r in refs:
		nd.derive(r)
	check(snap(w) == s0 and JSON.stringify(w.households.map(func(h): return h.get("econ", {}))) == econs, "deriving every actor's needs moves nothing and rewrites no household position")
	check(JSON.stringify(w.to_dict().merged({"economy": null}, true)) == before, "deriving needs leaves the whole saved world unchanged")
	for r in ["npc:%d" % adults(w)[4].id, "npc:%d" % adults(w)[1].id, World.hh_ref(0), "player", "manor", "npc:%d" % adults(w)[2].id]:
		nd.mark(r)
	check(nd.dirty.size() == 4, "only villagers and households are marked (player and manor have no derived needs)")
	var done := nd.refresh(2)
	var sorted := done.duplicate()
	sorted.sort()
	check(done.size() == 2 and done == sorted and nd.dirty.size() == 2, "refresh works the dirty set in sorted order within its limit")
	nd.refresh()
	check(nd.dirty.is_empty(), "the rest at the next refresh (budget %d)" % nd.refresh_budget)
	var r0: String = refs[0]
	var got := nd.needs_of(r0)
	check(got == nd.derive(r0), "needs_of: derives a stale actor on demand")


# ------------------------------------------------------------------------------------------------ offers
func test_offers() -> void:
	var w := new_world()
	var of := w.economy.offers
	var rs := w.economy.reservations
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	var ar := World.npc_ref(a.id)
	var br := World.npc_ref(b.id)
	a.inv.add("wheat", 6)
	b.coins = 40
	var base := a.inv.count("wheat")
	var s0 := snap(w)
	var x := of.post("ask", ar, "wheat", 4, 3, w.day() + 2)
	check(x.ok and rs.available(ar, "wheat") == base - 4, "an ask reserves the goods it offers")
	check(not of.post("ask", ar, "wheat", base - 3, 3).ok, "an ask beyond the unreserved stock is refused")
	check(not of.post("ask", ar, "iron_bar", 1, 3).ok and not of.post("bid", br, "wheat", 100, 3).ok, "no ask without goods, no bid without coins")
	check(not of.post("trade", ar, "wheat", 1, 1).ok and not of.post("ask", ar, "wheat", 0, 1).ok and not of.post("ask", ar, "coins", 1, 1).ok and not of.post("ask", ar, "wheat", 1, -1).ok, "bad side, quantity, item or price refused")
	var y := of.post("bid", br, "wheat", 5, 4)
	check(y.ok and rs.available(br, "coins") == 40 - 20 and rs.get_record(of.get_offer(y.id).reservation).item == "coins", "a bid reserves its coins")
	check(snap(w) == s0, "posting moves no coin and no good")
	var o: Dictionary = of.get_offer(x.id)
	check(o.visibility == EconOffers.VISIBILITY and o.state == "open" and o.location == w.economy.actors.location(ar), "offer record: visibility (OD-LE-02B D01, local), open, located")
	check(of.open_for("wheat").size() == 2 and of.open_for("wheat", "bid").size() == 1 and of.open_of(ar).size() == 1, "indexes by item, side and actor")
	check(w.economy.knowledge.knows(ar, ar, "wheat", "sells") and w.economy.knowledge.knowers_of(ar, "wheat") == [ar], "only the poster knows of its offer (OD-LE-02B undecided)")
	# a fill after a real trade
	# LE-03: the trade that fills an offer names that offer's reservation (EconMarket._settle does), else the ask would yield first
	check(w.trade(b, a, "wheat", 3, 3, -1, [int(of.get_offer(x.id).reservation)]), "a live trade of 3 that fills the ask")
	check(of.record_fill(x.id, 3) and of.remaining(x.id) == 1 and rs.reserved(ar, "wheat") == 1, "record_fill books 3 and shrinks the reservation to the rest")
	check(not of.record_fill(x.id, 2), "a fill beyond what remains is refused")
	check(of.record_fill(x.id, 1) and of.get_offer(x.id).state == "filled" and rs.reserved(ar, "wheat") == 0, "the last unit fills the offer")
	var s1 := snap(w)
	check(of.withdraw(y.id) and rs.available(br, "coins") == b.coins and snap(w) == s1, "withdraw releases the bid's coins, moves nothing")
	check(not of.withdraw(y.id), "a finished offer cannot be withdrawn again")
	var z := of.post("ask", ar, "wheat", 1, 2, w.day())
	check(of.expire_due(w.day()).is_empty() and of.expire_due(w.day() + 1) == [z.id] and rs.reserved(ar, "wheat") == 0, "expiry the day after its last day releases it")
	var v := of.post("ask", ar, "wheat", 1, 2)
	a.inv.remove("wheat", a.inv.count("wheat"))
	check(not of.backed(v.id), "an ask whose goods left by a live trade is reported unbacked, not repaired")
	for i in 6:
		a.inv.add("wheat", 1)
		of.withdraw(of.post("ask", ar, "wheat", 1, 1).id)
	var finished := of.records.values().filter(func(q): return q.state != "open").size()
	check(finished <= 4, "finished offers bounded (keep %d)" % finished)


# ------------------------------------------------------------------------------------------------ knowledge
func test_knowledge() -> void:
	var w := new_world()
	var k := w.economy.knowledge
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	var ar := World.npc_ref(a.id)
	var br := World.npc_ref(b.id)
	for src in ["notice", "rumour"]:
		check(not k.learn(br, ar, "wheat", "sells", 3, src) and k.is_empty(), "source %s refused (%s)" % [src, EconKnowledge.SOURCES_REFUSED[src]])
	check(int(k.refused.notice) == 1, "refusals counted for diagnostics")
	check(not k.learn(br, ar, "wheat", "sells", 3, "word_of_mouth") and not k.learn(br, ar, "wheat", "sells", 3, "word_of_mouth", -1, "", -1, br) and k.is_empty(),
		"word of mouth (OD-LE-10 D09) needs a teller other than the knower")
	check(not k.learn(br, ar, "wheat", "sells", 3, "telepathy") and not k.learn(br, "npc:999999", "wheat", "sells") and not k.learn(br, br, "wheat", "sells", 1, "dealing"), "unknown source or party, or self-knowledge by dealing, refused")
	check(k.learn(br, ar, "wheat", "sells", 3, "dealing"), "dealing: learned")
	var e: Dictionary = k.known_by(br)[0]
	check(e.price_each == 3 and e.source == "dealing" and e.seen_day == w.day() and k.age(e) == 0 and e.location == w.economy.actors.location(ar), "entry: price, source, age, location")
	w.minutes += World.DAY * 2
	check(k.learn(br, ar, "wheat", "sells", 5, "contract") and k.size() == 1, "news on the same (knower, subject, item, side) refreshes one entry")
	e = k.known_by(br)[0]
	check(e.price_each == 5 and e.seen_day == w.day() and e.learned_day == w.day() - 2 and e.source == "dealing", "price and seen day refreshed; first source and day kept")
	check(not e.has("trust") and not e.has("regard") and not e.has("opinion") and not e.has("confidence"), "no trust, regard or opinion stored in economic knowledge (shared Expansion 19 model)")
	check(k.reliability(e) == 1.0, "reliability (OD-LE-10 D09): a fresh firsthand price is fully believed")
	w.minutes += World.DAY * 30
	check(k.knows(br, ar, "wheat", "sells") and k.age(k.known_by(br)[0]) == 30 and k.reliability(k.known_by(br)[0]) < 0.1,
		"firsthand knowledge is kept; its reliability falls with age (stale, OD-LE-10 D09)")
	check(k.known_by(ar).is_empty() and k.knowers_of(ar, "wheat") == [br], "knowledge is per knower: the seller learned nothing from this")
	check(k.known_by(br, "wheat", "buys").is_empty() and k.known_by(br, "wheat", "sells").size() == 1, "query by item and side")


func test_trade_observer() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	a.inv.add("wheat", 4)
	b.coins = 50
	var ar := World.npc_ref(a.id)
	var br := World.npc_ref(b.id)
	var n0 := w.economy.events.size()
	check(w.trade(b, a, "wheat", 2, 3), "a live trade with the model on")
	var k := w.economy.knowledge
	check(k.knows(br, ar, "wheat", "sells") and k.knows(ar, br, "wheat", "buys") and k.known_by(br)[0].price_each == 3, "both parties learn by dealing, at the price paid")
	var ev: Array = w.economy.events.query(br, "trade")
	check(w.economy.events.size() == n0 + 1 and ev.size() == 1 and ev[0].actor == br and ev[0].other == ar and ev[0].qty == 2 and ev[0].coins == 6, "the trade is noted as an event")
	var nd := w.economy.needs
	check(nd.dirty.has(ar) and nd.dirty.has(br) and nd.dirty.has(World.hh_ref(a.household)) and nd.dirty.has(World.hh_ref(b.household)), "parties and their households marked for their needs")
	var c := new_world()
	var cp: NPC = adults(c)[0]
	cp.inv.add("wheat", 2)
	c.player.coins = 30
	check(c.trade(c.player, cp, "wheat", 1, 2) and c.economy.knowledge.knows("player", World.npc_ref(cp.id), "wheat", "sells"), "the player learns by dealing like anyone (PAR-01)")


# ------------------------------------------------------------------------------------------------ contracts
func test_contract_links() -> void:
	var w := new_world()
	var cl := w.economy.contract_links
	var rs := w.economy.reservations
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	var ar := World.npc_ref(a.id)
	a.inv.add("plank", 5)
	a.inv.add("log", 6)
	var c := open_contract(w, a, b, "plank", 3, 4)
	var v := cl.view(int(c.id))
	check(v.open and v.owed == 3 and v.owed == w.contracts.held_for_ref(ar, "plank") and v.escrow == int(c.reserved) and v.escrow > 0 and not v.overdue, "view: owed is the contract's hold (RECON-01), escrow the buyer's set-aside")
	check(cl.view(999999).is_empty(), "view of no contract: empty")
	var s0 := snap(w)
	var e := cl.earmark(int(c.id), "log", 4)
	check(e.ok and rs.get_record(e.id).purpose == "contract:%d" % int(c.id) and rs.get_record(e.id).expiry == int(c.deadline_day) and rs.get_record(e.id).owner == ar, "earmark: the seller's input reserved for the contract until its deadline")
	check(snap(w) == s0, "earmarking moves nothing")
	check(not cl.earmark(int(c.id), "log", a.inv.count("log")).ok, "earmark beyond the unreserved stock refused")
	check(not cl.earmark(int(c.id), "coins", 1).ok, "coins are the contract's escrow, not earmarked")
	check(not cl.earmark(int(c.id), "plank", a.inv.count("plank") - 2).ok and cl.earmark(int(c.id), "plank", a.inv.count("plank") - 3).ok, "the contract's own goods can be earmarked only beyond its hold")
	check(cl.view(int(c.id)).inputs.size() == 2, "view lists the linked inputs")
	w.contracts.deliver(c, 1)
	check(cl.view(int(c.id)).owed == w.contracts.held_for_ref(ar, "plank"), "a delivery shrinks owed with the hold")
	check(cl.sweep().is_empty() and rs.reserved(ar, "log") == 4, "sweep keeps the claims of an open contract")
	w.contracts.cancel(c, c.buyer)
	check(cl.sweep() == [int(c.id)] and rs.reserved(ar, "log") == 0 and rs.reserved(ar, "plank") == 0 and cl.is_empty(), "the contract ended (cancelled by its rules): sweep releases its claims")
	var c3 := open_contract(w, a, b, "plank", 1, 2)
	check(not cl.earmark(int(c3.id), "log", a.inv.count("log") + 1).ok, "an earmark over the whole holding refused")
	var other: NPC = adults(w)[2]
	other.inv.add("log", 3)
	var c4 := open_contract(w, other, b, "plank", 1, 2)
	check(cl.earmark(int(c4.id), "log", 2).ok, "another seller's earmark")
	w.contracts.cancel(c4, c4.buyer)
	var c5: Dictionary = w.contracts.get_contract(int(c4.id))
	check(not cl.earmark(int(c5.id), "log", 1).ok, "a contract no longer open takes no earmark")
	w.contracts.cancel(c3, c3.buyer)
	check(EconContractLinks.DEATH_OF_PARTY.contains("OD-LE-13B"), "death of a party: OD-LE-13B placeholder; the contract module's on_death decides")


func test_dawn() -> void:
	var w := new_world()
	var a: NPC = adults(w)[0]
	var b: NPC = adults(w)[1]
	var ar := World.npc_ref(a.id)
	var br := World.npc_ref(b.id)
	a.inv.add("wheat", 5)
	var of := w.economy.offers
	var o := of.post("ask", ar, "wheat", 2, 3, w.day())
	var r := w.economy.reservations.reserve(ar, "wheat", 1, "x", w.day())
	var c := open_contract(w, a, b, "wheat", 1, 3)
	w.economy.dawn(w.day() + 1)
	check(of.get_offer(o.id).state == "expired" and w.economy.reservations.get_record(r.id).state == "expired", "dawn: offers and reservations past expiry expire")
	check(w.economy.knowledge.knows(br, ar, "wheat", "sells") and w.economy.knowledge.known_by(br)[0].source == "contract" and w.economy.contract_cursor == int(c.id), "dawn: a new contract's parties learn its terms (source contract)")
	var n := w.economy.knowledge.size()
	w.economy.dawn(w.day() + 1)
	check(w.economy.knowledge.size() == n, "a contract is told once (cursor)")


# ------------------------------------------------------------------------------------------------ determinism, saves
func run_ops(w: World) -> String:
	var ad := adults(w)
	for i in 5:
		ad[i].inv.add("wheat", 4 + i)
		ad[i].inv.add("log", 3)
		ad[i].coins = 40
	var of := w.economy.offers
	for i in [4, 1, 3, 0, 2]:
		of.post("ask", World.npc_ref(ad[i].id), "wheat", 2, 2 + i, w.day() + i)
		of.post("bid", World.npc_ref(ad[(i + 1) % 5].id), "log", 1, 3)
	w.trade(ad[1], ad[0], "wheat", 1, 2)
	w.trade(ad[2], ad[3], "log", 1, 3)
	of.record_fill(0, 1)
	var c := open_contract(w, ad[2], ad[4], "log", 1, 3)
	w.economy.contract_links.earmark(int(c.id), "wheat", 1)
	w.economy.dawn(w.day() + 2)
	w.economy.needs.mark(World.npc_ref(ad[0].id))
	return JSON.stringify(w.economy.to_dict())


func test_determinism() -> void:
	var s1 := run_ops(new_world())
	var s2 := run_ops(new_world())
	check(s1 == s2 and s1.length() > 200, "same operations on two worlds: identical serialized model")
	var d: Dictionary = JSON.parse_string(s1)
	check(d.has_all(["offers", "knowledge", "needs", "contracts", "reservations", "events"]), "every part saved when non-empty")
	var tb: Array = d.knowledge.strings          # LE-06 format 2: rows over a string table (knower, subject, item, side first)
	var keys: Array = d.knowledge.rows.map(func(r): return "%s|%s|%s|%s" % [tb[int(r[0])], tb[int(r[1])], tb[int(r[2])], tb[int(r[3])]])
	var sk := keys.duplicate()
	sk.sort()
	var ids: Array = d.offers.records.map(func(o): return int(o.id))
	var si := ids.duplicate()
	si.sort()
	check(keys == sk and ids == si, "saved knowledge and offers in sorted order")


func test_save() -> void:
	var w := new_world()
	var full := run_ops(w)
	var d := w.to_dict()
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w2.economy != null and JSON.stringify(w2.economy.to_dict()) == JSON.stringify(w.economy.to_dict()), "enabled: the whole model round-trips (offers, knowledge, needs, links, cursor)")
	var o2: Array = w2.economy.offers.open_for("wheat")
	check(o2.size() == w.economy.offers.open_for("wheat").size() and w2.economy.offers.next_id == w.economy.offers.next_id, "offer indexes rebuilt on load")
	var any_k: Dictionary = w.economy.knowledge.entries.values()[0]
	check(w2.economy.knowledge.knowers_of(any_k.subject, any_k.item) == w.economy.knowledge.knowers_of(any_k.subject, any_k.item), "knowledge indexes rebuilt on load")
	# an LE-01 foundation save (reservations and events only) loads with an empty model
	var older: Dictionary = JSON.parse_string(JSON.stringify(d))
	for k in ["needs", "offers", "knowledge", "contracts", "contract_cursor"]:
		older.economy.erase(k)
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), older)
	check(w3.economy.offers.is_empty() and w3.economy.knowledge.is_empty() and w3.economy.needs.is_empty() and w3.economy.contract_links.is_empty() and not w3.economy.reservations.is_empty(), "a foundation-only save loads: model parts empty, reservations kept")
	var none: Dictionary = JSON.parse_string(JSON.stringify(d))
	none.erase("economy")
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), none)
	check(w4.economy != null and w4.economy.is_empty(), "a save without the key loads with an empty model")
	# D2: off, the section with every new part is carried byte-identical
	EconomyFoundation.set_override({})
	var want := JSON.stringify(JSON.parse_string(JSON.stringify(d)).economy)
	var cur: Dictionary = JSON.parse_string(JSON.stringify(d))
	var ok := true
	for i in 3:
		var wc := World.new()
		wc.load_dict(VillageMap.load_default(), cur)
		ok = ok and wc.economy == null
		cur = JSON.parse_string(JSON.stringify(wc.to_dict()))
	check(ok and JSON.stringify(cur.economy) == want, "off: the model's section kept byte-identical through 3 save cycles (D2)")
	EconomyFoundation.set_override(ON)
	var w5 := World.new()
	w5.load_dict(VillageMap.load_default(), cur)
	check(JSON.stringify(w5.economy.to_dict()) == JSON.stringify(w.economy.to_dict()), "on again: the kept section restored as before")
	check(int(d.get("save_version", d.get("version", -1))) == World.SAVE_VERSION or not d.has("save_version"), "no save version change (still %d)" % World.SAVE_VERSION)


# ------------------------------------------------------------------------------------------------ observes only
func fingerprint(w: World) -> String:
	var d := w.to_dict()
	d.erase("economy")
	return JSON.stringify(d)


func test_observes_only() -> void:
	var on := new_world(true, 2)
	var off := new_world(false, 2)
	var steps := int(1440.0 / float(GameData.b("game_minutes_per_second")) / 0.5)
	for i in steps:
		on.update(0.5)
		off.update(0.5)
	check(on.day() == 1 and off.day() == 1, "a full day with a dawn stepped on both worlds")
	check(on.total_coins() == off.total_coins() and Census.goods(on) == Census.goods(off), "one day, model on vs off: the same coins and goods")
	check(fingerprint(on) == fingerprint(off), "one day, model on vs off: the whole saved world identical apart from the economy key")
	check(on.economy.events.size() > 0 and on.economy.knowledge.size() > 0, "the model observed the day (%d events, %d knowledge entries)" % [on.economy.events.size(), on.economy.knowledge.size()])
	check(on.economy.events.ordered(), "events in strict order")


func test_cost() -> void:
	var w := new_world()
	var ad := adults(w)
	var t0 := Time.get_ticks_usec()
	for i in 200:
		ad[i % 5].inv.add("wheat", 1)
		w.trade(ad[(i + 1) % 5], ad[i % 5], "wheat", 1, 0)
	var small := float(Time.get_ticks_usec() - t0) / 200.0
	for i in 500:
		var n := NPC.new()
		n.id = 200000 + i
		n.household = -1
		n.role = "adult"
		w.npcs.append(n)
		w.by_id[n.id] = n
	t0 = Time.get_ticks_usec()
	for i in 200:
		ad[i % 5].inv.add("wheat", 1)
		w.trade(ad[(i + 1) % 5], ad[i % 5], "wheat", 1, 0)
	var big := float(Time.get_ticks_usec() - t0) / 200.0
	print("timing: us/trade small=%.1f big(+500)=%.1f" % [small, big])
	check(big < 5.0 * maxf(small, 5.0), "observing a trade does not scan the population")
	for n: NPC in w.npcs.slice(w.npcs.size() - 500):
		w.economy.needs.mark(World.npc_ref(n.id))
	check(w.economy.needs.refresh().size() == w.economy.needs.refresh_budget, "a refresh is bounded by its budget")


# ------------------------------------------------------------------------------------------------ opinion is weighed
## Owner rule 2026-10-26: an NPC may refuse a deal because of their opinion, but no numerical cutoff refuses automatically and
## no rule keeps every deal possible. The economy keeps no opinion; the decision seam LE-02 will use is the shared
## JudgmentWeighting.choose (trade_buy). With the SAME strong dislike for the seller, the outcome must depend on need, on
## alternatives and on the person (shipped personality spread). Nothing here asserts that a trade succeeds.
func test_opinion_is_weighed() -> void:
	var c: Dictionary = JudgmentStore.default_cfg().duplicate(true)
	var j := JudgmentStore.new(c, JudgmentSocial.new(), 7)
	const SELLER := 9000
	const OTHER := 9001
	var choosers := range(100, 160)
	for p in choosers:
		j.set_ledger(p, SELLER, 0, 40000)                   # the same strong dislike in every chooser
	var buy := func(p: int, need: int, alternative := false) -> String:
		var cands := [{"id": "disliked", "counterparty": SELLER, "factors": {"necessity": need, "affordability": 70000, "urgency": need}}]
		if alternative:
			cands.append({"id": "other", "counterparty": OTHER, "factors": {"necessity": need, "affordability": 70000, "urgency": need}})
		return str(JudgmentWeighting.choose(j, c, p, "trade_buy", cands).chosen)
	var p0: int = choosers[0]
	check(buy.call(p0, 100000) == "disliked" and buy.call(p0, 0) == "forgo", "the same dislike: bought from in great need, refused with no need (no fixed cutoff)")
	check(buy.call(p0, 100000, true) == "other", "with an alternative on the same terms the disliked seller is passed over")
	var split := false
	var levels := 0
	for need in range(0, 100001, 2500):
		var outs := {}
		for p in choosers:
			outs[buy.call(p, need)] = true
		if outs.size() > 1:
			split = true
			levels += 1
	check(split, "same dislike and circumstances: one person deals, another refuses (personality; %d need levels split)" % levels)
	check(j.net(p0, SELLER) == -40000, "weighing a deal leaves the opinion unchanged")
	check(not FileAccess.get_file_as_string("res://scripts/core/economy/econ_knowledge.gd").contains("regard >=") and not FileAccess.get_file_as_string("res://scripts/core/economy/econ_offers.gd").contains("regard"), "no regard threshold in the economy model")
