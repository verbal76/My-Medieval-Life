class_name JudgmentSocial
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19): the judgment system's read-only view of who is close to whom. Judgment never
## keeps a second relationships store (spec invariant 7; the owner's "no duplicated ledgers"): kinship lives in Life
## and NPC, friendship and regard in Relations. This base class is the adapter contract; JudgmentSocial itself is the
## fixture used by isolated tests (pairs set by hand), and JudgmentLive.Social reads the live World.
##
## Ids are people's ids: villagers' NPC.id, a player their person id (World.person_id: -2 the host's line, -line a guest's). The player is judged, and could judge, by
## exactly the same rules as anyone else (PAR: player and villagers by the same rules).

var _kin := {}
var _friends := {}
var _regard := {}
var _rel := {}                       # person -> [[relative, kind], ...] (fixture family graph for JudgmentBonds)
var _guards := {}                    # person -> true: a guard (fixture)
var _ver := 0                        # bumped by every fixture setter that changes the family graph


## A number that changes whenever the family graph (parents, children, partners) may have changed: JudgmentBonds keeps its
## derived relatives by it. The live adapter reads Life.kin_version.
func graph_version() -> int:
	return _ver



## A pair's key: both ids offset (the host's player id is -2), the lower in the high bits. MP C5: a guest's person id is
## far below zero (World.person_id), so the low half is masked to 32 bits; every key of a villager or the host is as before.
static func _k(a: int, b: int) -> int:
	return ((mini(a, b) + 1024) << 32) | ((maxi(a, b) + 1024) & 0xFFFFFFFF)


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


## Whether a person is a guard of the village (X19-MISINFO: a guard's reports show an invented crime false).
func is_guard(person: int) -> bool:
	return _guards.has(person)


# ---------------------------------------------------------------- fixture setters (tests) ------
func set_guard(person: int) -> JudgmentSocial:
	_guards[person] = true
	return self



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
	_ver += 1
	for pair in [[child, parent, "parent"], [parent, child, "child"]]:
		if not _rel.has(pair[0]):
			_rel[pair[0]] = []
		(_rel[pair[0]] as Array).append([pair[1], pair[2]])
	return self
