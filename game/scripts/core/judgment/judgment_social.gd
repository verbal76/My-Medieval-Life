class_name JudgmentSocial
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19): the judgment system's read-only view of who is close to whom. Judgment never
## keeps a second relationships store (spec invariant 7; the owner's "no duplicated ledgers"): kinship lives in Life
## and NPC, friendship and regard in Relations. This base class is the adapter contract; JudgmentSocial itself is the
## fixture used by isolated tests (pairs set by hand), and JudgmentLive.Social reads the live World.
##
## Ids are people's ids: villagers' NPC.id, the player Life.PLAYER_ID (-2). The player is judged, and could judge, by
## exactly the same rules as anyone else (PAR: player and villagers by the same rules).

var _kin := {}
var _friends := {}
var _regard := {}
var _rel := {}                       # person -> [[relative, kind], ...] (fixture family graph for JudgmentBonds)


## A pair's key: both ids offset to stay positive (the player is -2), the lower in the high bits.
static func _k(a: int, b: int) -> int:
	return ((mini(a, b) + 1024) << 32) | (maxi(a, b) + 1024)


## Family: parents, children, siblings, partners.
func kin(a: int, b: int) -> bool:
	return _kin.has(_k(a, b))


func friends(a: int, b: int) -> bool:
	return _friends.has(_k(a, b))


## The existing relationship number between two people, 0..100 (Q06: trust in a teller reuses it; in the live game
## Relations' regard, one tie a pair). The fixture's default is 0: strangers.
func regard(a: int, b: int) -> int:
	return int(_regard.get(_k(a, b), 0))


## A person's relatives as [[id, kind], ...], kind "parent", "child", "sibling" or "partner" (JudgmentBonds family
## reputation reads it through its reach). The live adapter reads Life's family graph; the fixture's is set by hand.
func relatives(person: int) -> Array:
	return (_rel.get(person, []) as Array).duplicate()


# ---------------------------------------------------------------- fixture setters (tests) ------
func set_kin(a: int, b: int) -> JudgmentSocial:
	_kin[_k(a, b)] = true
	return self


func set_friends(a: int, b: int) -> JudgmentSocial:
	_friends[_k(a, b)] = true
	return self


func set_regard(a: int, b: int, r: int) -> JudgmentSocial:
	_regard[_k(a, b)] = r
	return self


## `parent` is the parent of `child` (both directions of the family graph).
func set_parent(child: int, parent: int) -> JudgmentSocial:
	for pair in [[child, parent, "parent"], [parent, child, "child"]]:
		if not _rel.has(pair[0]):
			_rel[pair[0]] = []
		(_rel[pair[0]] as Array).append([pair[1], pair[2]])
	return self
