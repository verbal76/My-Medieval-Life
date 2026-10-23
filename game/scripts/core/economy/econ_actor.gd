class_name EconActor
extends RefCounted
## Expansion 20 (Living Economy), LE-01: ONE read-only resolver over the economic actors that exist today. DISABLED and
## isolated: World builds it only when game/data/economy.json "enabled" is true; nothing in live play calls it.
##
## It re-implements nothing: it reads the existing owners through World.npc / households / treasury / granary /
## chapel / stalls / buildings[].shop and Regions.party (settlement/settlement_party.gd). It never moves a coin or a
## good and never caches (every call reads the owner's current state), so it cannot disagree with the census
## (settlement/holdings.gd).
##
## Refs (today's, unchanged): "npc:<id>", "hh:<n>", "player", "manor", "region:<settlement>/<holder>", plus read-only
## refs this resolver defines for owners that have no ref yet: "chapel" (World.chapel's fund and store),
## "stall:<id>" (a stall's till) and "shop:<building id>" (a shop's till), coins only.
## NO BUSINESS IDENTITY: a business is still its owner's ref, a building or a stall id (OD-LE-04 and OD-LE-07 are
## open); no "business:" ref is invented here.
##
## What each kind holds:
##   npc        coins NPC.coins, goods NPC.inv        (a dead villager exists, is not alive; what the body still holds is shown)
##   hh         coins 0 (purses are not pooled), goods the pantry; an ended household is not alive and holds nothing
##   player     coins PlayerState.coins, goods pack + chest
##   manor      coins World.treasury, goods the granary
##   chapel     coins Chapel.coins, goods Chapel.store
##   stall/shop coins the till, no goods
##   region     coins SettlementParty.purse(), goods held_items(); a dissolved household or unknown holder does not exist
## Consumers: EconReservations (what an owner holds, whether it is alive), EconEvents (actor refs), and economy_sim.gd
## diagnostics later.

var w: World
var reservations: EconReservations = null       # set by EconomyFoundation; the source of reserved()/available()


func _init(world: World) -> void:
	w = world


func kind(ref: String) -> String:
	if ref == World.PLAYER or ref == World.MANOR or ref == "chapel":
		return ref
	for k in ["npc", "hh", "stall", "shop", "region"]:
		if ref.begins_with(k + ":"):
			return k
	return ""


func exists(ref: String) -> bool:
	match kind(ref):
		"player", "manor":
			return true
		"chapel":
			return w.chapel != null
		"npc":
			return w.npc(_num(ref)) != null
		"hh":
			var h := _num(ref)
			return ref.length() > 3 and h >= 0 and h < w.households.size()
		"stall":
			return w.stalls.has(ref.trim_prefix("stall:")) or w.stalls.has(_num(ref))
		"shop":
			return _shop(ref) != null
		"region":
			return w.regions != null and w.regions.party(ref) != null
	return false


## Exists and can act or hold: a living villager, a household that has not ended, a live settlement party.
func alive(ref: String) -> bool:
	if not exists(ref):
		return false
	match kind(ref):
		"npc":
			return w.npc(_num(ref)).alive
		"hh":
			return not bool(w.households[_num(ref)].get("ended", false))
	return true


func coins(ref: String) -> int:
	if not exists(ref):
		return 0
	match kind(ref):
		"npc":
			return w.npc(_num(ref)).coins
		"player":
			return w.player.coins
		"manor":
			return w.treasury
		"chapel":
			return w.chapel.coins
		"stall":
			return int(_stall(ref).get("till", 0))
		"shop":
			return int(_shop(ref).get("till", 0))
		"region":
			return w.regions.party(ref).purse()
	return 0


## Units of `item` held (not net of reservations; see available).
func count(ref: String, item: String) -> int:
	if not exists(ref):
		return 0
	match kind(ref):
		"npc":
			return w.npc(_num(ref)).inv.count(item)
		"hh":
			return 0 if not alive(ref) else (w.households[_num(ref)].pantry as Inventory).count(item)
		"player":
			return w.player.inv.count(item) + w.player.chest.count(item)
		"manor":
			return w.granary.count(item)
		"chapel":
			return w.chapel.store.count(item)
		"region":
			return w.regions.party(ref).held(item)
	return 0


## A copy of the goods held, {item: n}.
func goods(ref: String) -> Dictionary:
	var out := {}
	if not exists(ref):
		return out
	var srcs: Array = []
	match kind(ref):
		"npc":
			srcs = [w.npc(_num(ref)).inv.items]
		"hh":
			srcs = [w.households[_num(ref)].pantry.items] if alive(ref) else []
		"player":
			srcs = [w.player.inv.items, w.player.chest.items]
		"manor":
			srcs = [w.granary.items]
		"chapel":
			srcs = [w.chapel.store.items]
		"region":
			srcs = [w.regions.party(ref).held_items()]
	for s in srcs:
		for id in s:
			if int(s[id]) > 0:
				out[id] = int(out.get(id, 0)) + int(s[id])
	return out


## Held of `item` ("coins" for money) as the actor's holding, the one the reservation record is bounded by.
func holding(ref: String, item: String) -> int:
	return coins(ref) if item == EconReservations.COINS else count(ref, item)


## Units of `item` ("coins" too) set aside by the reservation record (0 when it is not attached).
func reserved(ref: String, item: String) -> int:
	return reservations.reserved(ref, item) if reservations != null else 0


func name_of(ref: String) -> String:
	if kind(ref) == "chapel":
		return "the chapel"
	return w.ref_name(ref) if kind(ref) in ["npc", "hh", "player", "manor"] else ref


func _num(ref: String) -> int:
	return int(ref.get_slice(":", 1)) if ref.contains(":") else -1


func _stall(ref: String) -> Dictionary:
	var k := ref.trim_prefix("stall:")
	return w.stalls[k] if w.stalls.has(k) else w.stalls.get(_num(ref), {})


func _shop(ref: String):
	var b: Dictionary = w.buildings.get(ref.trim_prefix("shop:"), {})
	return b.shop if b.has("shop") else null
