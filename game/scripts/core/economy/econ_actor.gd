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
## Consumers: EconReservations (what an owner holds, whether it is alive), EconEvents (actor refs), EconNeeds, EconOffers,
## EconKnowledge and EconContractLinks (LE-01 model), and economy_sim.gd diagnostics.
##
## LE-01 model additions (read-only, uncached): "player:<pid>" (a guest player, MP C3) resolves through World.player_of_ref,
## and "player" is the host (World.player_of_ref), not whoever is acting; profile(ref) {ref, kind, name, alive, household,
## controller, location}; controller(ref) for a till (the stall's or the building's holder, World.holder_of, the ECON-P3
## till owner); household_of(ref). A business is still a till plus its holder: OWNER DECISION OD-LE-04 / OD-LE-07
## (BUSINESS_IDENTITY below) decides whether it becomes an actor of its own.

## OWNER DECISION OD-LE-04 / OD-LE-07: business founding, ownership, inheritance, and business/household account separation
## beyond ECON-P3's tills. Placeholder: no "business:" ref exists; nothing reads this but the tests and the LE-01 note.
const BUSINESS_IDENTITY := "OWNER DECISION OD-LE-04/OD-LE-07: undecided; a business is its till plus its holder"

var w: World
var reservations: EconReservations = null       # set by EconomyFoundation; the source of reserved()/available()


func _init(world: World) -> void:
	w = world


func kind(ref: String) -> String:
	if ref == World.PLAYER or ref == World.MANOR or ref == "chapel":
		return ref
	if ref.begins_with("player:"):
		return World.PLAYER
	for k in ["npc", "hh", "stall", "shop", "region"]:
		if ref.begins_with(k + ":"):
			return k
	return ""


func exists(ref: String) -> bool:
	match kind(ref):
		"player":
			return _player(ref) != null
		"manor":
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
			return _player(ref).coins
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
			return _player(ref).inv.count(item) + _player(ref).chest.count(item)
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
			srcs = [_player(ref).inv.items, _player(ref).chest.items]
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


## LE-01: the household ref ("hh:<n>") a villager belongs to, the household itself, or "" (players, the manor, tills).
func household_of(ref: String) -> String:
	match kind(ref):
		"hh":
			return ref
		"npc":
			var n: NPC = w.npc(_num(ref))
			return World.hh_ref(n.household) if n != null and n.household >= 0 and n.household < w.households.size() else ""
	return ""


## LE-01: who controls a till (a stall's or a shop building's holder: the tenant, else the owner; ECON-P3), or the actor
## itself for every other kind. "" when the ref does not exist.
func controller(ref: String) -> String:
	if not exists(ref):
		return ""
	match kind(ref):
		"stall":
			return w.holder_of(_stall(ref))
		"shop":
			return w.holder_of(w.buildings.get(ref.trim_prefix("shop:"), {}))
	return ref


## LE-01: where the actor is found, as an id the world already uses (a home or workplace building, a stall id, a shop's
## building, a settlement id); "" when it has none. A place, not a position: travel is LE-02's question.
func location(ref: String) -> String:
	if not exists(ref):
		return ""
	match kind(ref):
		"npc":
			var n: NPC = w.npc(_num(ref))
			return n.workplace if n.workplace != "" else n.home
		"hh":
			return str(w.households[_num(ref)].get("home", ""))
		"player":
			return _player(ref).home
		"stall":
			return "stall:" + ref.trim_prefix("stall:")
		"shop":
			return ref.trim_prefix("shop:")
		"region":
			return ref.trim_prefix("region:").get_slice("/", 0)
	return ""


## LE-01: one actor's identity as the model sees it, read now (never cached): {ref, kind, name, alive, household,
## controller, location}. {} for an unknown ref.
func profile(ref: String) -> Dictionary:
	if not exists(ref):
		return {}
	return {"ref": ref, "kind": kind(ref), "name": name_of(ref), "alive": alive(ref), "household": household_of(ref),
		"controller": controller(ref), "location": location(ref)}


## The person the shared Expansion 19 judgment model judges for this actor (JudgmentLive.person_of_ref: a villager, a player,
## a household's responsible adult), a till answering to its controller; -1 when nobody is judged (the manor, the chapel,
## a settlement, an unknown ref). A ref mapping only: the economy keeps no opinion, trust or reputation of its own (owner
## rule 2026-10-26, carryover directive s.7) and nothing in LE-01 calls this to decide.
func judged_person(ref: String) -> int:
	var c := controller(ref)
	return JudgmentLive.person_of_ref(w, c) if c != "" and kind(c) in ["npc", "player", "hh"] else -1


func _player(ref: String) -> PlayerState:
	return w.player_of_ref(ref)


func _num(ref: String) -> int:
	return int(ref.get_slice(":", 1)) if ref.contains(":") else -1


func _stall(ref: String) -> Dictionary:
	var k := ref.trim_prefix("stall:")
	return w.stalls[k] if w.stalls.has(k) else w.stalls.get(_num(ref), {})


func _shop(ref: String):
	var b: Dictionary = w.buildings.get(ref.trim_prefix("shop:"), {})
	return b.shop if b.has("shop") else null
