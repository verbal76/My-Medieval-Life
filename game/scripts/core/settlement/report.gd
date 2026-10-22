class_name SettlementReport
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-B/C reporting; PROS-18): the village's inventories and economy as a settlement,
## aggregated read-only from the holders that already exist (villagers, markets, households, the granary, the
## treasury, the manor's work, carts, stalls; SettlementHoldings). It keeps no ledger of its own and moves nothing:
## a report is a snapshot (spec s.11 "causes traceable to real inputs"; the wiki and the simulations read it).
##
## Goods are grouped by who may sell or use them:
##   market   the merchants' and tavern's stock, tables, villagers' built stalls, goods riding in carts
##   private  villagers' own packs and household pantries
##   public   the manor's granary, its work (lots, yard, job loads), troughs and building sites
##   player   the player's pack, chest and premises (the player's, not the settlement's)
##   loot     goods lying where someone fell (nobody's yet)
## Coins: SettlementHoldings.coins (equal to World.total_coins); the coins the five neighbouring settlements hold and the coins that came from
## outside are reported apart, as "outside".

const GROUPS := {"markets": "market", "stalls": "market", "carts": "market", "npcs": "private", "households": "private",
	"granary": "public", "manor_work": "public", "troughs": "public", "sites": "public", "player": "player", "loot": "loot"}


static func village(w: World, mining: MiningCapabilityAdapter = null) -> Dictionary:
	var h := SettlementHoldings.holders(w)
	var groups := {"market": {}, "private": {}, "public": {}, "player": {}, "loot": {}}
	var hs := h.keys()
	hs.sort()
	for k in hs:
		var grp: String = GROUPS.get(k, "public")
		for id in h[k]:
			groups[grp][id] = int(groups[grp].get(id, 0)) + int(h[k][id])
	var coins := SettlementHoldings.coins(w)
	var facts := SettlementFacts.from_world(w, mining)
	var cap := SettlementIndustries.evaluate(facts)
	var food := 0.0
	var all := SettlementHoldings.total(h)
	for f in NPCBrain.FOOD:
		food += float(all.get(f, 0)) * float(GameData.item(f).get("food", 0))
	var day_need: float = w.brain.village_day_food()
	return {
		"id": facts.id, "day": int(w.minutes / World.DAY), "population": facts.population,
		"goods": groups, "goods_total": all,
		"coins": coins, "coins_total": SettlementHoldings.coin_sum(coins),
		"outside": {"settlement_coins": w.regions.coins(), "coin_sources": w.coin_sources},
		"food_points": food, "food_days": food / maxf(1.0, day_need),
		"capabilities": cap.levels, "blocked": cap.blocked, "mining_source": str(facts.external.mining.source),
		"transport": facts.transport, "structures": facts.structures,
		"workforce": workforce(w),
	}


## X18-CAPCOMP part 1: each industry's workforce level (hours-weighted average of its active workers' own experience
## levels, last season) and the same average of their effective levels; "no active workers" where nobody worked. A
## report for planning only: it changes nobody's level, work or pay.
static func workforce(w: World) -> Dictionary:
	var out := {}
	var caps: Dictionary = (SettlementIndustries.data().get("experience", {}) as Dictionary).get("caps_days", {})
	var inds := caps.keys()
	inds.sort()
	for ind in inds:
		out[ind] = w.experience.workforce(str(ind), w.minutes)
	return out


## Goods used up a day, measured from the World's running ledger between two stats snapshots `days` apart: what was
## eaten and used in recipes or buildings ({item: units a day}). The village's demand for the regional market comes
## from what it actually uses, not from a table.
static func measured_use(stats0: Dictionary, stats1: Dictionary, days: float) -> Dictionary:
	var out := {}
	for k in stats1:
		var key := str(k)
		var item := ""
		if key.begins_with("eaten_") and key != "eaten_food":
			item = key.substr(6)
		elif key.begins_with("used_") and not key.begins_with("used_building_") and key != "used_medicine":
			item = key.substr(5)
		if item == "" or not GameData.items.has(item):
			continue
		var n := float(stats1[k]) - float(stats0.get(k, 0))
		if n > 0.0:
			out[item] = float(out.get(item, 0.0)) + n / maxf(1.0, days)
	return out


## The village's parties to regional trade, as read-only SettlementLedger snapshots (owner Q18-10, 2026-10-21: anyone
## may buy from another settlement). Every coin and good is in exactly one party, as the World holds it:
##   trader  "<place>/npc:<id>"  each villager whose trade buys inputs or stock (NPCBrain.BUYS: merchants, smith,
##           carpenter, tanner, sage, cook, tavernkeeper): its own purse and pack; it wants what NPCBrain.wants says (the
##           live rule, not a second one); it sells its pack beyond what it keeps; it carries one pack a round
##   household "<place>/hh:<n>"  the other living members' purses and packs and the pantry: its members' packs are for
##           sale (beyond what they keep), the pantry is not; it needs its share of the village's measured daily food
##           use (by members); it carries one pack a round if it has an adult, more with its own handcarts
##   villager "<place>/npc:<id>"  a villager of no household: their own purse and pack (no demand rule yet)
##   treasury "<place>/manor"  the manor's treasury and granary: it can buy, but cannot travel (a carter must haul for
##           it); no demand rule of its own yet (the reeve's buying is the live rule; provisional: none)
## The player is not a party here (the player buys by hand). Bandits and loot are nobody's party. Its own reachable
## seams (the mining adapter: MIN-D's deposits and level) count against the ore demand of the traders who buy ore.
## COPIES: a plan executed on them changes nothing in the World (live trade is the caravan's until SET-C).
static func parties(w: World, food_use: Dictionary, place := SettlementFacts.VILLAGE, mining: MiningCapabilityAdapter = null) -> Array:
	if mining == null:
		mining = MiningCapabilityAdapter.live(w)
	var days := float(RegionalMarket.cfg().reserve_days)
	var own_ore := mining.local_supply(place)
	var levels := SettlementIndustries.levels(SettlementFacts.from_world(w, mining, place))
	var out := []
	var pop := 0
	var members := {}             # household -> [NPC] not trading on their own account
	for o: NPC in w.npcs:
		if not o.alive or o.role == "bandit":
			continue
		pop += 1
		var role: String = w.brain.buy_role(o)
		if NPCBrain.BUYS.has(role) and o.role == "adult":
			var needs := {}
			var held := {}
			for id in NPCBrain.BUYS[role]:
				var want: int = w.brain.wants(o, id)
				if want > 0 or o.inv.count(id) > 0:
					needs[id] = float(want + o.inv.count(id)) / days
			for id in o.inv.items:
				if not w.brain.keeps(o, id):
					held[id] = int(o.inv.items[id])
			var t := SettlementLedger.make({"id": "%s/npc:%d" % [place, o.id], "name": "%s %s" % [o.name, o.family],
				"settlement": place, "kind": "trader", "coins": o.coins, "stock": o.inv.items, "needs": needs,
				"transport": {"carry": 1}, "capabilities": levels})
			t.sale_limit = held
			for ore in own_ore:
				if (NPCBrain.BUYS[role] as Dictionary).has(ore):
					t.local_supply[ore] = int(own_ore[ore])
			out.append(t)
		elif o.household >= 0:
			if not members.has(o.household):
				members[o.household] = []
			members[o.household].append(o)
		else:                         # a villager of no household buys and sells on their own account
			var v := SettlementLedger.make({"id": "%s/npc:%d" % [place, o.id], "name": "%s %s" % [o.name, o.family],
				"settlement": place, "kind": "villager", "coins": o.coins, "stock": o.inv.items,
				"needs": {}, "transport": {"carry": 1 if o.role == "adult" else 0}, "can_travel": o.role == "adult",
				"capabilities": levels})
			var vs := {}
			for id in o.inv.items:
				if not w.brain.keeps(o, id):
					vs[id] = int(o.inv.items[id])
			v.sale_limit = vs
			out.append(v)
	# every household, its pantry with it (one whose members all trade on their own account still has a pantry)
	for h in w.households.size():
		var ms: Array = members.get(h, [])
		var stock := Inventory.new()
		var sale := {}
		var coins := 0
		var adults := 0
		for o: NPC in ms:
			coins += o.coins
			if o.role == "adult":
				adults += 1
			for id in o.inv.items:
				stock.add(id, int(o.inv.items[id]))
				if not w.brain.keeps(o, id):
					sale[id] = int(sale.get(id, 0)) + int(o.inv.items[id])
		var pantry: Inventory = w.households[h].pantry
		for id in pantry.items:
			stock.add(id, int(pantry.items[id]))
		var needs := {}
		for id in food_use:
			if NPCBrain.FOOD.has(id):
				needs[id] = float(food_use[id]) * float(ms.size()) / float(maxi(1, pop))
		var hl := SettlementLedger.make({"id": "%s/hh:%d" % [place, h], "name": "the %s household" % str(w.households[h].family),
			"settlement": place, "kind": "household", "coins": coins, "stock": stock.items, "needs": needs,
			"transport": {"carry": 1 if adults > 0 else 0, "handcart": w.carts.of(World.hh_ref(h)).size()},
			"can_travel": adults > 0, "capabilities": levels})
		hl.sale_limit = sale
		out.append(hl)
	var tr := SettlementLedger.make({"id": "%s/manor" % place, "name": "the manor", "settlement": place, "kind": "treasury",
		"coins": w.treasury, "stock": w.granary.items, "needs": {}, "transport": {"carry": 0}, "can_travel": false,
		"capabilities": levels})
	tr.sale_limit = {}
	out.append(tr)
	return out


## The coins and goods the parties hold, as a check that parties() partitions the World's holdings without counting
## anything twice: {coins, goods}.
static func party_totals(ps: Array) -> Dictionary:
	var coins := 0
	var goods := {}
	for l: SettlementLedger in ps:
		coins += l.coins
		for k in l.stock.items:
			goods[k] = int(goods.get(k, 0)) + int(l.stock.items[k])
	return {"coins": coins, "goods": goods}
