class_name EconRouteRisk
extends RefCounted
## Expansion 20 (Living Economy), LE-05 "route risk in prices" (design s.5: buyers and sellers weigh "travel and risk";
## docs/expansion20/LE05_IMPLEMENTATION.md s.2). A per-route LOSS RECORD over a rolling window, and the expected loss on a trip
## that CON-01's delivered price reads from it (Contracts.route_risk_per_unit). Built with the economy foundation only
## (EconomyFoundation.attach: null while economy.json "enabled" is false, so the default game records nothing and saves nothing).
##
## What is counted (only losses that already happen in the game; nothing is invented, nothing moves):
##   carried  the value set out on a route: a courier's load as it leaves (CourierService._depart) and the payment it collects
##            on arrival for the way back (_arrive); goods handed over on a CON-01 delivery (Contracts.deliver);
##   lost     the value that did not arrive: a courier's journey interrupted on the road (its load dropped where it fell,
##            CourierService.interrupt) and a delivery's goods a bandit took from the seller who owed them (NPCBrain robbery,
##            the stolen item owed on one of the victim's open goods contracts); a loss is counted as carried too, so the
##            loss rate lost / carried stays within 0..1.
## Values are GameData.value per unit (a coin is 1). Caravans: the regional caravan is the settlements' traders (Regions),
## an abstraction with no loss event on the road (E22-OD-04: physical caravans are Expansion 22), so nothing is recorded for it.
##
## A route is the pair of places (CourierService.place_of: "village" or a settlement id), unordered ("a|b"), or the one place
## when both ends are in it ("village" for every in-village delivery).
##
## The record OBSERVES: it never creates, destroys or moves a coin or a good. Deterministic: integer values, day buckets,
## sorted keys when saved; no random draws. Bounded: one bucket a route a day, days older than the window dropped at dawn.
## Saved inside the "economy" section under the optional key "route_risk" (absent: an empty record).

const VILLAGE := "village"

var cfg := {}
var routes := {}          # route key -> {day (int) -> [carried value, lost value, trips, losses]}


func _init(market_cfg := {}) -> void:
	cfg = market_cfg


## The record of `w`'s economy, or null while the economy is off (or `w` is not a World: an abstract test fixture).
static func of(w) -> EconRouteRisk:
	if w == null or not (w is World) or w.economy == null:
		return null
	return w.economy.route_risk


## The place a party is in (CourierService.place_of's rule): "region:<settlement>/<holder>" is in <settlement>, else the village.
static func place_of(ref: String) -> String:
	return ref.trim_prefix("region:").split("/")[0] if ref.begins_with("region:") else VILLAGE


## The route between two places, the same either way round.
static func route(a: String, b: String) -> String:
	if a == b:
		return a
	return (a + "|" + b) if a < b else (b + "|" + a)


## The route between two parties' places.
static func route_of(a_ref: String, b_ref: String) -> String:
	return route(place_of(a_ref), place_of(b_ref))


## The value of a load: goods at GameData.value each, coins at 1.
static func value_of(items: Dictionary, coins := 0) -> int:
	var v := coins
	var ks: Array = items.keys()
	ks.sort()
	for id in ks:
		v += GameData.value(str(id)) * int(items[id])
	return v


## The window over which the loss rate is read (PROVISIONAL market.risk_window_days).
func window_days() -> int:
	return maxi(1, int(cfg.get("risk_window_days", 30)))


## Pricing reads the record only when the market drives with market.route_risk on.
func pricing() -> bool:
	return bool(cfg.get("drive", false)) and bool(cfg.get("route_risk", false))


func _bucket(key: String, day: int) -> Array:
	if not routes.has(key):
		routes[key] = {}
	var r: Dictionary = routes[key]
	if not r.has(day):
		r[day] = [0, 0, 0, 0]
	return r[day]


## A load of `value` set out on `key` on `day` (one trip).
func note_carried(key: String, day: int, value: int) -> void:
	if value <= 0:
		return
	var b := _bucket(key, day)
	b[0] = int(b[0]) + value
	b[2] = int(b[2]) + 1


## A load of `value` did not arrive on `key` on `day`. `counted` true: its value was already counted as carried (a courier's load,
## counted when it left); false: it is counted as carried now as well (a delivery's goods taken before they were handed over).
func note_lost(key: String, day: int, value: int, counted: bool) -> void:
	if value <= 0:
		return
	var b := _bucket(key, day)
	if not counted:
		b[0] = int(b[0]) + value
		b[2] = int(b[2]) + 1
	b[1] = int(b[1]) + value
	b[3] = int(b[3]) + 1


## The record of `key` over the window ending on `day`: {carried, lost, trips, losses, rate}. rate = lost / carried, in 0..1,
## exactly 0.0 when nothing was lost.
func totals(key: String, day: int) -> Dictionary:
	var out := {"carried": 0, "lost": 0, "trips": 0, "losses": 0, "rate": 0.0}
	var r: Dictionary = routes.get(key, {})
	var from := day - window_days() + 1
	for d in r:
		if int(d) < from or int(d) > day:
			continue
		var b: Array = r[d]
		out.carried = int(out.carried) + int(b[0])
		out.lost = int(out.lost) + int(b[1])
		out.trips = int(out.trips) + int(b[2])
		out.losses = int(out.losses) + int(b[3])
	if int(out.lost) > 0:
		out.rate = clampf(float(out.lost) / float(maxi(int(out.lost), int(out.carried))), 0.0, 1.0)
	return out


## The observed loss rate on `key` over the window ending on `day` (0.0 with no recorded loss).
func rate(key: String, day: int) -> float:
	return float(totals(key, day).rate)


## The expected loss carrying one unit worth `value` over `key` (PROVISIONAL rule, docs/expansion20/LE05_IMPLEMENTATION.md s.2):
## the observed loss rate times the value carried, times market.risk_weight. Exactly 0.0 with no recorded loss.
func expected_loss(key: String, day: int, value: float) -> float:
	var r := rate(key, day)
	if r <= 0.0:
		return 0.0
	return r * value * float(cfg.get("risk_weight", 1.0))


## Dawn: days that left the window are dropped (bounded save).
func dawn(day: int) -> void:
	var from := day - window_days() + 1
	for key in routes.keys():
		var r: Dictionary = routes[key]
		for d in r.keys():
			if int(d) < from:
				r.erase(d)
		if r.is_empty():
			routes.erase(key)


func is_empty() -> bool:
	return routes.is_empty()


func to_dict() -> Dictionary:
	var keys: Array = routes.keys()
	keys.sort()
	var out := {}
	for key in keys:
		var r: Dictionary = routes[key]
		var ds: Array = r.keys()
		ds.sort()
		var rows := []
		for d in ds:
			var b: Array = r[d]
			rows.append([int(d), int(b[0]), int(b[1]), int(b[2]), int(b[3])])
		out[str(key)] = rows
	return {"routes": out}


func load_dict(d: Dictionary) -> void:
	routes = {}
	var rs: Dictionary = d.get("routes", {})
	for key in rs:
		var r := {}
		for row in rs[key]:
			r[int(row[0])] = [int(row[1]), int(row[2]), int(row[3]), int(row[4])]
		if not r.is_empty():
			routes[str(key)] = r
