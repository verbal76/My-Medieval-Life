class_name EconomyFoundation
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the single attach point of the foundation records (EconActor resolver,
## EconReservations, EconEvents). World calls attach() twice only: at the end of setup() and in load_dict(). With
## game/data/economy.json "enabled": false (the shipped state) attach() returns null: nothing is constructed, no
## save key is written, and no live code path references these classes. A test can switch it on with set_override().
## Format "mml-economy/1": see docs/expansion20/LE01_DATA_CONTRACTS.md.

const KEY := "economy"
const PATH := "res://data/economy.json"
static var _override := {}
static var _cfg := {}


var actors: EconActor
var reservations: EconReservations
var events: EconEvents


static func config() -> Dictionary:
	if not _override.is_empty():
		return _override
	if _cfg.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		_cfg = JSON.parse_string(f.get_as_text()) if f != null else {"enabled": false}
		if not _cfg is Dictionary:
			_cfg = {"enabled": false}
	return _cfg


## Tests only: replace the file's settings (e.g. {"enabled": true}); {} restores the file.
static func set_override(cfg: Dictionary) -> void:
	_override = cfg


static func enabled() -> bool:
	return bool(config().get("enabled", false))


## null when disabled. `saved` is World's "economy" save key (absent: empty records).
static func attach(world: World, saved := {}) -> EconomyFoundation:
	if not enabled():
		return null
	var cfg := config()
	var f := EconomyFoundation.new()
	f.actors = EconActor.new(world)
	f.events = EconEvents.new(cfg.get("events", {}))
	f.reservations = EconReservations.new(f.actors, cfg.get("reservations", {}))
	f.reservations.events = f.events
	f.actors.reservations = f.reservations
	f.reservations.load_dict(saved.get("reservations", {}))
	f.events.load_dict(saved.get("events", {}))
	return f


func is_empty() -> bool:
	return reservations.is_empty() and events.is_empty()


## {} when there is nothing to save (World then writes no key).
func to_dict() -> Dictionary:
	var d := {}
	if not reservations.is_empty():
		d["reservations"] = reservations.to_dict()
	var e := events.to_dict()
	if not events.is_empty() and not e.is_empty():
		d["events"] = e
	return d
