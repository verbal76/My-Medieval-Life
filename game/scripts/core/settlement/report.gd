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
## Coins: SettlementHoldings.coins (equal to World.total_coins); the caravan's purse and the coins that came from
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
		"outside": {"caravan_purse": w.caravan_purse, "coin_sources": w.coin_sources},
		"food_points": food, "food_days": food / maxf(1.0, day_need),
		"capabilities": cap.levels, "blocked": cap.blocked, "mining_source": str(facts.external.mining.source),
		"transport": facts.transport, "structures": facts.structures,
	}


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


## The village as a read-only SettlementLedger snapshot for regional calculations (shadow planning): every good its
## people and institutions hold counts against its need (pantries and the granary too), but only its traders' and
## producers' goods (markets, stalls, carts, villagers' packs) are for sale, and only its traders' coins buy. A COPY:
## executing a plan on it changes nothing in the World (live trade is the caravan's until SET-C is integrated).
## Its own reachable seams (through the mining adapter: MIN-D's deposits and level) count against its ore demand.
static func as_ledger(w: World, needs: Dictionary, id := SettlementFacts.VILLAGE, mining: MiningCapabilityAdapter = null) -> SettlementLedger:
	if mining == null:
		mining = MiningCapabilityAdapter.live(w)
	var h := SettlementHoldings.holders(w)
	var stock := {}
	var sale := {}
	for k in ["markets", "stalls", "carts", "npcs", "households", "granary"]:
		for item in h.get(k, {}):
			stock[item] = int(stock.get(item, 0)) + int(h[k][item])
			if k in ["markets", "stalls", "carts", "npcs"]:
				sale[item] = int(sale.get(item, 0)) + int(h[k][item])
	var coins := SettlementHoldings.coins(w)
	var facts := SettlementFacts.from_world(w, mining, id)
	var l := SettlementLedger.make({"id": id, "name": "the village", "population": facts.population,
		"coins": int(coins.markets), "stock": stock, "needs": needs, "transport": facts.transport,
		"capabilities": SettlementIndustries.levels(facts)})
	l.sale_limit = sale
	l.local_supply = mining.local_supply(id)
	return l
