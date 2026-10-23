class_name SettlementFacts
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-B; PROS-18): the facts a settlement's capability is derived from, read from the
## live World without changing it (spec s.4: residents, skills, tools, infrastructure, knowledge). The live game has
## one settlement, the village ("village"); fixtures for other settlements are written in the same shape:
##   {id, name, population,
##    practitioners: [{job, skills: {skill: level}, tools: {kind: n}, store, id}]   the RESIDENTS by Build 17's rule
##        (Discovery.residents: every living adult villager, then the player while resident; MIN-D2), each with the tools
##        of each kind in their own pack and the key of the store they share (a household's pantry, the resident
##        player's home chest),
##    stores: {key: {kind: n}}  the shared stores' tools (a shared tool serves one practitioner, MIN-SKILLCAP),
##    tools: {item: n}       tools as MIN-D counts them (villagers' packs, household stores, the manor's yard, the resident
##                           player's pack and chest),
##    stock: {item: n}       every good the settlement's people and institutions hold (SettlementHoldings, the census),
##                           less the player's own and loot,
##    stations: {type: n}    station types; structures: {what: n} fields, stalls (and MIN-E/F's built structures later),
##    transport: {handcart: n, carry: 0|1}  handcarts set down or held; carrying by hand (MIN-D: carry_ore > 0 and an adult),
##    deposit_access: [level], records: {what: n}, portals: [depth]   from MIN-D through the mining adapter,
##    external: {mining: {...}}                                       the mining capability from the adapter,
##    discovery: Discovery   the live village only: practitioners and tool stock are then MIN-D's own counts.}
## SYNC-17 (Build 17 cd7439c): the evaluator follows MIN-SKILLCAP and MIN-D2 (skill and tool, never title; the resident
## player counts by the villagers' rule; a shared tool counts once).

const VILLAGE := "village"


static func from_world(w: World, mining: MiningCapabilityAdapter = null, id := VILLAGE, name := "the village") -> Dictionary:
	if mining == null:
		mining = MiningCapabilityAdapter.live(w)
	var disc = w.get("discovery") if "discovery" in w else null
	var residents: Array = disc.residents() if disc != null else w.npcs.filter(func(o): return o.alive and o.role == "adult")
	var prac := []
	var stores := {}
	for o in residents:
		var store := ""
		if o is PlayerState:
			store = "player"
			stores[store] = _tool_kinds(o.chest)
		elif o.household >= 0 and o.household < w.households.size():
			store = "hh%d" % o.household
			stores[store] = _tool_kinds(w.households[o.household].pantry)
		prac.append({"job": o.job if o is NPC else "", "skills": _levels(o), "tools": _tool_kinds(o.inv), "store": store,
			"id": o.id if o is NPC else -1})
	var pop := 0
	for n: NPC in w.npcs:
		if n.alive and n.role != "bandit":
			pop += 1
	var tools := {}
	var add := func(inv: Inventory) -> void:
		for k in inv.items:
			tools[k] = int(tools.get(k, 0)) + int(inv.items[k])
	for n: NPC in w.npcs:
		if n.alive:
			add.call(n.inv)
	for hh in w.households:
		add.call(hh.pantry)
	add.call(w.manor_work.yard)
	var g := SettlementHoldings.holders(w)
	g.erase("player")
	g.erase("loot")                                 # goods lying where someone fell belong to nobody yet
	var stock := SettlementHoldings.total(g)
	var stations := {}
	for sid in w.stations:
		var t := str(w.stations[sid].get("type", ""))
		stations[t] = int(stations.get(t, 0)) + 1
	var structures := {"field": w.fields.size(), "stall": w.stalls.size() + w.business.stalls.npc_built().size()}
	var carry := 1 if int(GameData.b("carry_ore")) > 0 and not prac.is_empty() else 0
	return {"id": id, "name": name, "population": pop, "practitioners": prac, "stores": stores, "tools": tools, "stock": stock,
		"stations": stations, "structures": structures,
		"transport": {"handcart": w.carts.carts.size() + int(tools.get("handcart", 0)), "carry": carry},
		"deposit_access": mining.deposit_access(id), "records": mining.records(id), "portals": mining.portals(id),
		"external": {"mining": mining.capability(id)}, "discovery": disc}


## Tools in an inventory by tool kind (items.json `tool`; a rusty pickaxe is a pickaxe), as Discovery.count_kind counts.
static func _tool_kinds(inv: Inventory) -> Dictionary:
	var out := {}
	for id in inv.ids():
		var kind := str(GameData.item(id).get("tool", ""))
		if kind == "":
			continue
		out[kind] = int(out.get(kind, 0)) + inv.count(id)
	return out


static func _levels(who) -> Dictionary:
	var out := {}
	var ks: Array = who.skills.keys()
	ks.sort()
	for k in ks:
		var l := Skills.level(who, str(k))
		if l > 0:
			out[str(k)] = l
	return out


## The facts without the live Discovery reference (for JSON, determinism comparisons and abstract use).
static func plain(facts: Dictionary) -> Dictionary:
	var f := facts.duplicate()
	f.erase("discovery")
	return f
