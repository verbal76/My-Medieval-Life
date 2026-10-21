class_name MiningCapabilityAdapter
extends RefCounted
## PROVISIONAL interface (Expansion 18, PROS-18): how the settlement capability model reads a settlement's MINING
## capability, which Build 17 owns (MIN-D, village mining capability levels 1-4 and hidden deposits, being written on
## wip/b17-mind and not final). The settlement model never computes a mining level or looks at deposits itself
## (directive: "Do not create duplicate mining systems or assume unfinished production behavior is final").
##
## The contract the settlement model relies on (a dictionary, so MIN-D's real shape can be mapped in one place):
##   capability(settlement_id) -> {"level": int 0..4, "source": String, "provisional": bool,
##                                 "since_day": int (-1 unknown), "notes": String}
##   portals(settlement_id)    -> Array of int depths (MIN-F/OD-29 underground portals; [] when none)
##   records(settlement_id)    -> {what: count} discovery records with provenance (MIN-C; {} when none)
##
## Three sources, chosen when the adapter is made:
##   fixture(table)  test fixtures: {settlement_id: {"level", "portals", "records"}}
##   live(world)     reads MIN-D's state from the World when it exists (duck-typed: World.mining_capability(id) or a
##                   World.mining_levels dictionary; both names are guesses until MIN-D lands, see
##                   docs/expansion18/PROGRESS.md "Dependencies"); on this branch (Build 16 code) neither exists, so
##                   the level is 0 with source "unavailable" -- never a value invented here
##   none()          no mining knowledge at all (level 0, source "none")

const MAX_LEVEL := 4

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


func capability(settlement_id: String) -> Dictionary:
	match _mode:
		"fixture":
			var f: Dictionary = _fixture.get(settlement_id, {})
			return _shape(int(f.get("level", 0)), "fixture", int(f.get("since_day", -1)), str(f.get("notes", "")))
		"live":
			if _world != null and _world.has_method("mining_capability"):
				var d = _world.mining_capability(settlement_id)
				if d is Dictionary:
					return _shape(int(d.get("level", 0)), "min-d", int(d.get("since_day", -1)), "read from MIN-D")
				return _shape(int(d), "min-d", -1, "read from MIN-D")
			if _world != null and "mining_levels" in _world:
				var t = _world.get("mining_levels")
				if t is Dictionary and t.has(settlement_id):
					return _shape(int(t[settlement_id]), "min-d", -1, "read from MIN-D")
			return _shape(0, "unavailable", -1, "MIN-D (Build 17) is not on this branch")
	return _shape(0, "none", -1, "")


func portals(settlement_id: String) -> Array:
	if _mode == "fixture":
		return (_fixture.get(settlement_id, {}) as Dictionary).get("portals", []).duplicate()
	if _mode == "live" and _world != null and _world.has_method("mining_portals"):
		return _world.mining_portals(settlement_id)
	return []


func records(settlement_id: String) -> Dictionary:
	if _mode == "fixture":
		return (_fixture.get(settlement_id, {}) as Dictionary).get("records", {}).duplicate()
	if _mode == "live" and _world != null and _world.has_method("discovery_records"):
		return _world.discovery_records(settlement_id)
	return {}


func _shape(level: int, source: String, since: int, notes: String) -> Dictionary:
	return {"level": clampi(level, 0, MAX_LEVEL), "source": source, "provisional": true, "since_day": since, "notes": notes}
