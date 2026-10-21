class_name MiningCapabilityAdapter
extends RefCounted
## PROVISIONAL adapter (Expansion 18, PROS-18): the ONLY way the settlement model learns anything about mining, which
## Build 17 owns. Mapped to MIN-D as read on `origin/wip/b17-mind` b0506db (docs/build17/MIN_D_DISCOVERY.md; not yet in
## wip/build17, not on this branch): the settlement model never computes a mining level and never reads deposits.
##
## MIN-D's interface (what `live` reads, duck-typed because this branch has no Build 17 code):
##   World.discovery : Discovery
##     .evaluate("mining") -> {level: 0..4, holds: [bool per level], unmet: {level: [need names]}}  (derived now, no rng,
##                            changes nothing; "the truth is evaluate()")
##     .level("mining")    -> the level computed at the last dawn (or the start or load)
##     .history            -> [{day, industry, from, to, why}] (why: the needs lost on a fall)
##     .manor_finds()      -> the manor's findings with ore (MIN-C knowledge; the level-2 "records" need)
##   World.underground.portals[].ends[].level  (MIN-A; the level-4 portal need; depths are negative)
##   World._quarry_sources(ores), World.villagers_reach(d), World.level_of(d)  (the deposits MIN-D counts: ordinary seam
##                            records in World.deposits, including seams opened from finds, boulders and host rock)
## Level semantics (capabilities.json, mml-capabilities/1): 1 surface extraction, 2 prospecting and assay, 3 open pit,
## 4 underground; sequential (a level needs every lower level); 3 and 4 cannot hold until MIN-E/MIN-F build ramps and
## supports. MIN-D models ONE settlement, the village: any other settlement id is "unavailable" in the live game.
##
## The contract the settlement model relies on (dictionaries, so changes in MIN-D are mapped here only):
##   capability(id)     -> {level, last_dawn, source, provisional, since_day, unmet: {level: [names]}, history: [..], notes}
##   portals(id)        -> [depth]                 records(id) -> {"discovery": n}
##   deposit_access(id) -> [deposit level with reachable ore or stone]
##   local_supply(id)   -> {ore: units} the settlement's own reachable seams hold (for regional demand: what the
##                         village can dig itself is not an import need). Only while its mining level is 1 or more.
## Sources: fixture(table) for tests and abstract settlements; live(world); none().

const MAX_LEVEL := 4
const VILLAGE := "village"
const ORES := ["iron_ore", "coal", "copper_ore", "gold_ore", "stone"]

var _mode := "none"
var _fixture := {}
var _world = null


static func fixture(table: Dictionary) -> MiningCapabilityAdapter:
	var a := MiningCapabilityAdapter.new()
	a._mode = "fixture"
	a._fixture = table.duplicate(true)
	return a


static func live(world) -> MiningCapabilityAdapter:
	var a := MiningCapabilityAdapter.new()
	a._mode = "live"
	a._world = world
	return a


static func none() -> MiningCapabilityAdapter:
	return MiningCapabilityAdapter.new()


func mode() -> String:
	return _mode


## Whether the World carries MIN-D (World.discovery).
func has_min_d() -> bool:
	return _world != null and "discovery" in _world and _world.get("discovery") != null


func capability(settlement_id: String) -> Dictionary:
	match _mode:
		"fixture":
			var f: Dictionary = _fixture.get(settlement_id, {})
			return _shape(int(f.get("level", 0)), int(f.get("last_dawn", f.get("level", 0))), "fixture",
				int(f.get("since_day", -1)), f.get("unmet", {}), f.get("history", []), str(f.get("notes", "")))
		"live":
			if not has_min_d():
				return _shape(0, 0, "unavailable", -1, {}, [], "MIN-D (Build 17) is not on this branch")
			if settlement_id != VILLAGE:
				return _shape(0, 0, "unavailable", -1, {}, [], "MIN-D models the village only")
			var disc = _world.discovery
			var e: Dictionary = disc.evaluate("mining")
			var hist: Array = (disc.history as Array).filter(func(h): return str(h.industry) == "mining")
			var since := -1
			if not hist.is_empty():
				since = int(hist[hist.size() - 1].day)
			return _shape(int(e.level), int(disc.level("mining")), "min-d", since, e.get("unmet", {}), hist, "read from MIN-D")
	return _shape(0, 0, "none", -1, {}, [], "")


func portals(settlement_id: String) -> Array:
	if _mode == "fixture":
		return (_fixture.get(settlement_id, {}) as Dictionary).get("portals", []).duplicate()
	if _mode == "live" and settlement_id == VILLAGE and _world != null and "underground" in _world and _world.get("underground") != null:
		var out := []
		for p in _world.underground.portals:
			for e in p.ends:
				if int(e.level) < 0 and not out.has(int(e.level)):
					out.append(int(e.level))
		out.sort()
		return out
	return []


func records(settlement_id: String) -> Dictionary:
	if _mode == "fixture":
		return (_fixture.get(settlement_id, {}) as Dictionary).get("records", {}).duplicate()
	if _mode == "live" and settlement_id == VILLAGE and has_min_d():
		return {"discovery": (_world.discovery.manor_finds() as Array).size()}
	return {}


func deposit_access(settlement_id: String) -> Array:
	if _mode == "fixture":
		return (_fixture.get(settlement_id, {}) as Dictionary).get("deposit_access", []).duplicate()
	var out := []
	for d in _reachable(settlement_id):
		var lv := int(_world.level_of(d)) if _world.has_method("level_of") else 0
		if not out.has(lv):
			out.append(lv)
	out.sort()
	return out


## What the settlement's own reachable seams still hold, by ore, while its mining level is at least 1 (someone can dig
## it): regional demand counts it as the village's own supply (DESIGN.md "Ore demand"). On this branch (no MIN-D) the
## village's fixed seams in World.deposits stand in, all reachable as in Build 16; the level then comes from nobody, so
## the Build 16 rule "a miner and a pickaxe" is not re-derived: the seams count whenever any are left (provisional).
func local_supply(settlement_id: String) -> Dictionary:
	if _mode == "fixture":
		return (_fixture.get(settlement_id, {}) as Dictionary).get("local_supply", {}).duplicate()
	if _mode != "live" or settlement_id != VILLAGE or _world == null:
		return {}
	if has_min_d() and int(capability(settlement_id).level) < 1:
		return {}
	var out := {}
	for d in _reachable(settlement_id):
		out[str(d.ore)] = int(out.get(str(d.ore), 0)) + int(d.amount)
	return out


func _reachable(settlement_id: String) -> Array:
	if _mode != "live" or settlement_id != VILLAGE or _world == null:
		return []
	if _world.has_method("_quarry_sources") and _world.has_method("villagers_reach"):
		return (_world._quarry_sources(ORES) as Array).filter(func(d): return int(d.amount) > 0 and _world.villagers_reach(d))
	if "deposits" in _world:
		return (_world.deposits as Array).filter(func(d): return int(d.amount) > 0)
	return []


func _shape(level: int, last: int, source: String, since: int, unmet, hist, notes: String) -> Dictionary:
	return {"level": clampi(level, 0, MAX_LEVEL), "last_dawn": clampi(last, 0, MAX_LEVEL), "source": source,
		"provisional": true, "since_day": since, "unmet": (unmet as Dictionary).duplicate(true),
		"history": (hist as Array).duplicate(true), "notes": notes}
