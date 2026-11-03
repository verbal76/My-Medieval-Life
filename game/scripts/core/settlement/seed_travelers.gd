class_name SeedTravelers
extends RefCounted
## B25R1-009, seed travelers (owner 2026-11-03, docs/directives/2026-11-03_b25r1_seed_travelers.md: "We are seeding reasons for
## existing people to travel, not seeding fake people into the countryside"). At the founding of a new world (World.setup, once:
## never on loading a save, never again later) a few of the village's own residents (settlements.json "seed_travelers".count) are
## given one simple reason to travel: walk to another settlement and buy one ordinary trade item there from a merchant, with their
## own coins, and walk home with it. Everything after that is the existing simulation:
##
##   the person     an ordinary villager (World.npcs: their household, home, job, purse, relations, judgment, mortality), never a
##                  copy and never a new person; the village's population and registers are unchanged
##   the walk       Journeys (REGION-NAV-01 AD-4): the village path to the gate, the road network (Overworld.road_route), the
##                  settlement's site, and back; food for the road from the household's pantry and bought at the site
##                  (Journeys.provision, buy_food); rest by the road at night, eat from the pack, danger and death on the road as
##                  for anyone (World: bandits, combat, Journeys.end "died")
##   the purchase   RegionTrade.at_site / act_buy (REGION-NAV-01 S6): face to face with the seller at their door, at the settlement's
##                  price, through SettlementFolk.buy_from (the settlement's books via SettlementParty.deal, the village side as the
##                  courier edge books it): no coin or good is created or destroyed
##   the fallbacks  the existing ones: no road (Journeys.start refuses, nobody is sent), a road closed on the way (they turn home),
##                  the seller away on the caravan road (they wait up to `wait_mornings` mornings at the site, then go home with
##                  nothing), sold out or too dear by then (the record is out of date, they go home with nothing)
##   afterwards     Journeys.end clears the journey and the brain plans their ordinary day; later travel comes only from their own
##                  motives (RegionTrade.dawn on what they were told, an envoy's posting): nothing here runs again
##
## Who: living adults of a village household with a home, not in a post the village cannot spare for a few days (`skip_jobs`: the
## keepers of the village's own counters, the guards, the reeve, the clergy), with coins above their reserve (World.reserve_of) to
## pay for the item. Ranked by a hash of the world seed and their id (no rng draw, so nothing else in the world's founding moves),
## each takes the first destination, in an order hashed the same way (places no earlier seed traveller took first), where someone
## sells an affordable ordinary item (price at most `max_price`, room in their pack): the settlement's keepers and crafters (who
## keep their stock at home) first, its trader (whose stock mostly goes on the caravan road) only where no keeper sells one. A
## trader on the caravan road every day (Regions.cadence 1) is never met at their door, so is never chosen. Residents of the other settlements are household records (OffMapSettlement.hh), not NPCs that
## walk the world: making one a walker would duplicate them, so only the starting village's residents are seed travelers (a
## limitation recorded in docs/region_nav/SEED_TRAVELERS_B25R1.md).
##
## The journey's purpose is the ordinary buying purpose ({kind: "buy", about, item, qty: 1, price}) marked `seed: true` and with
## `wait`, saved with the journey (NPC.journey): a save made mid-journey resumes it (Journeys.resume plans from where they stand).

const SALT := 0x5EED


static func cfg() -> Dictionary:
	var c: Dictionary = OffMapSettlement.data().get("seed_travelers", {})
	return {"count": int(c.get("count", 3)), "max_price": int(c.get("max_price", 15)), "wait_mornings": int(c.get("wait_mornings", 3)),
		"skip_jobs": c.get("skip_jobs", ["guard", "reeve", "sage", "tavernkeeper", "cook", "merchant", "preacher", "church_assistant", "manor_hand"])}


## World.setup: designate the seed travelers and send them. Returns the NPCs sent (in the order chosen).
static func designate(w: World) -> Array:
	var out := []
	var c := cfg()
	if int(c.count) <= 0 or w.regions == null or w.map.overworld == null:
		return out
	var cands := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.home != "" and not n.job in c.skip_jobs and not Journeys.active(n) \
				and w.manor_work.job_of(World.npc_ref(n.id)).is_empty():
			cands.append(n)
	cands.sort_custom(func(a: NPC, b: NPC) -> bool:
		var ha := Overworld.hash32(w.seed, a.id, SALT)
		var hb := Overworld.hash32(w.seed, b.id, SALT)
		return ha < hb if ha != hb else a.id < b.id)
	var sites: Array = w.map.overworld.sites
	for n: NPC in cands:
		if out.size() >= int(c.count):
			break
		var order := range(sites.size())
		var k0 := Overworld.hash32(w.seed, n.id, SALT + 1) % maxi(1, sites.size())
		order = order.slice(k0) + order.slice(0, k0)          # a rotation: destinations spread over the settlements
		var fresh: Array = order.filter(func(k): return not out.any(func(o: NPC) -> bool: return str(o.journey.to) == str(sites[k].id)))
		order = fresh + order.filter(func(k): return not fresh.has(k))      # a place nobody else is going to first
		for k in order:
			var errand := errand_at(w, n, str(sites[k].id))
			if errand.is_empty():
				continue
			var purpose := {"kind": "buy", "about": str(errand.about), "item": str(errand.item), "qty": 1, "price": int(errand.price),
				"seed": true, "wait": int(c.wait_mornings)}
			if Journeys.start(w, n, str(sites[k].id), purpose) != "":
				continue
			w.stat("seed_travelers")
			w.stat("seed_travelers_to_" + str(sites[k].id))
			w.note("%s %s sets out for %s to buy %s." % [n.name, n.family, str(sites[k].name), GameData.item_name(str(errand.item)).to_lower()])
			out.append(n)
			break
	return out


## The one ordinary item `n` can buy at settlement `sid` with their own coins: {about (the seller's ref), item, price}, or {}. Every
## (seller, item) a keeper or crafter there sells at a price `n` can pay above their reserve, no dearer than max_price, with room in
## their pack; only if there is none, the trader's; one of them chosen by a hash of the seed and `n` (in seller and item order).
static func errand_at(w: World, n: NPC, sid: String, present_only := false) -> Dictionary:
	var s: OffMapSettlement = w.regions.by_id.get(sid)
	if s == null or w.map.overworld.road_route(Journeys.gate_index(w), sid).is_empty():
		return {}
	var spare := n.coins - w.reserve_of(n)
	var keepers := []
	var traders := []
	for p in SettlementFolk.people(w, sid):
		if str(p.role) == "official" or (str(p.business) == "trader" and Regions.cadence(s) <= 1):
			continue
		if present_only and not SettlementFolk.present(w, p):
			continue
		var party: SettlementParty = w.regions.party(str(p.ref))
		if party == null:
			continue
		var ids: Array = party.held_items().keys()
		ids.sort()
		for id in ids:
			var price: int = s.price(str(id))
			if party.sale_cap(str(id)) > 0 and price > 0 and price <= int(cfg().max_price) and price <= spare and n.inv.can_add(str(id)):
				(traders if str(p.business) == "trader" else keepers).append({"about": str(p.ref), "item": str(id), "price": price})
	var pool := keepers if not keepers.is_empty() else traders
	if pool.is_empty():
		return {}
	return pool[Overworld.hash32(w.seed, n.id, SALT + 2) % pool.size()]


## At the site (RegionTrade.at_site), before going to the seller: true when the errand's seller is at their door and still sells
## the item at a price the traveller can pay. If not, another ordinary item on sale there now (errand_at, present sellers only)
## takes its place, recorded in the purpose (`instead_of`); false when nothing is on sale to them (they wait or go home).
static func refresh(w: World, n: NPC, p: Dictionary) -> bool:
	var sid := str(n.journey.to)
	var s: OffMapSettlement = w.regions.by_id.get(sid)
	if s == null:
		return false
	var spare := n.coins - w.reserve_of(n)
	for q in SettlementFolk.people(w, sid):
		if str(q.ref) == str(p.about) and SettlementFolk.present(w, q):
			var party: SettlementParty = w.regions.party(str(q.ref))
			var price: int = s.price(str(p.item))
			if party != null and party.sale_cap(str(p.item)) > 0 and price > 0 and price <= spare:
				return true
	var e := errand_at(w, n, sid, true)
	if e.is_empty():
		return false
	if not p.has("instead_of"):
		p.instead_of = str(p.item)
	p.about = str(e.about)
	p.item = str(e.item)
	p.price = int(e.price)
	w.stat("seed_travelers_changed_item")
	return true
