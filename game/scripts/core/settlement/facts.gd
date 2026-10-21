class_name SettlementFacts
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-B; PROS-18): the facts a settlement's capability is derived from, read from the
## live World without changing it (spec s.4: residents, skills, tools, infrastructure, knowledge). The live game has
## one settlement, the village ("village"); fixtures for other settlements are written in the same shape:
##   {id, name, population,
##    practitioners: [{job, skills: {skill: level}, id}]  living ADULT villagers (MIN-D's rule: role "adult"; not
##                                                        children, elders or bandits; not the player),
##    tools: {item: n}       tools as MIN-D counts them: living villagers' packs, household stores, the manor's yard,
##    stock: {item: n}       every good the settlement's people and institutions hold (SettlementHoldings, the census),
##                           less the player's own and loot,
##    stations: {type: n}    station types; structures: {what: n} fields, stalls (and MIN-E/F's built structures later),
##    transport: {handcart: n, carry: 0|1}  handcarts set down or held; carrying by hand (MIN-D: carry_ore > 0 and an adult),
##    deposit_access: [level], records: {what: n}, portals: [depth]   from MIN-D through the mining adapter,
##    external: {mining: {...}}                                       the mining capability from the adapter.}
## The player's goods and skills are theirs, not the settlement's (MIN-D decision 4, its open question 2; agent decision
## here so the two models agree).

const VILLAGE := "village"


static func from_world(w: World, mining: MiningCapabilityAdapter = null, id := VILLAGE, name := "the village") -> Dictionary:
	if mining == null:
		mining = MiningCapabilityAdapter.live(w)
	var prac := []
	var pop := 0
	var tools := {}
	var add := func(inv: Inventory) -> void:
		for k in inv.items:
			tools[k] = int(tools.get(k, 0)) + int(inv.items[k])
	for n: NPC in w.npcs:
		if not n.alive:
			continue
		add.call(n.inv)
		if n.role == "bandit":
			continue
		pop += 1
		if n.role == "adult":
			prac.append({"job": n.job, "skills": _levels(n), "id": n.id})
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
	return {"id": id, "name": name, "population": pop, "practitioners": prac, "tools": tools, "stock": stock,
		"stations": stations, "structures": structures,
		"transport": {"handcart": w.carts.carts.size() + int(tools.get("handcart", 0)), "carry": carry},
		"deposit_access": mining.deposit_access(id), "records": mining.records(id), "portals": mining.portals(id),
		"external": {"mining": mining.capability(id)}}


static func _levels(who) -> Dictionary:
	var out := {}
	var ks: Array = who.skills.keys()
	ks.sort()
	for k in ks:
		var l := Skills.level(who, str(k))
		if l > 0:
			out[str(k)] = l
	return out
