class_name SettlementFacts
extends RefCounted
## PROSPECTIVE (Expansion 18, SET-B; PROS-18): the facts a settlement's capability is derived from, read from the
## live World without changing it (spec s.4: residents, skills, tools, infrastructure, knowledge). The live game has
## one settlement, the village ("village"); fixtures for other settlements are written in the same shape:
##   {id, name, population,
##    practitioners: [{job, skills: {skill: level}}]  living adult villagers (no bandits), skills as levels (PAR-01),
##    stock: {item: n}                                every good the settlement's people and institutions hold
##                                                    (SettlementHoldings, the census), less the player's own goods,
##    structures: {kind: n}                           station types, plus "field" and "stall",
##    transport: {handcart: n}                        handcarts set down as carts and handcarts held as items,
##    records: {what: n}, portals: [depth]            from MIN-C/MIN-F through the mining adapter (provisional),
##    external: {mining: {...}}}                      the mining capability from MiningCapabilityAdapter.
## The player is a resident, but their pack and premises are theirs: they count as a practitioner (skills, PAR-01, one
## rule for player and villagers) and not as the settlement's stock (agent decision, recorded in DESIGN.md).

const VILLAGE := "village"


static func from_world(w: World, mining: MiningCapabilityAdapter = null, id := VILLAGE, name := "the village") -> Dictionary:
	if mining == null:
		mining = MiningCapabilityAdapter.live(w)
	var prac := []
	var pop := 0
	for n: NPC in w.npcs:
		if not n.alive or n.role == "bandit":
			continue
		pop += 1
		if n.role == "child":
			continue
		prac.append({"job": n.job, "skills": _levels(n), "id": n.id})
	prac.append({"job": "", "skills": _levels(w.player), "id": -1})
	var g := SettlementHoldings.holders(w)
	g.erase("player")
	g.erase("loot")                                 # goods lying where someone fell belong to nobody yet
	var stock := SettlementHoldings.total(g)
	var structures := {}
	for sid in w.stations:
		var t := str(w.stations[sid].get("type", ""))
		structures[t] = int(structures.get(t, 0)) + 1
	structures["field"] = w.fields.size()
	structures["stall"] = w.stalls.size() + w.business.stalls.npc_built().size()
	var handcarts := w.carts.carts.size() + int(stock.get("handcart", 0))
	return {"id": id, "name": name, "population": pop, "practitioners": prac, "stock": stock,
		"structures": structures, "transport": {"handcart": handcarts},
		"records": mining.records(id), "portals": mining.portals(id),
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
