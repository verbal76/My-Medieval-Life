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


static func _k(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]


## Family: parents, children, siblings, partners.
func kin(a: int, b: int) -> bool:
	return _kin.has(_k(a, b))


func friends(a: int, b: int) -> bool:
	return _friends.has(_k(a, b))


# ---------------------------------------------------------------- fixture setters (tests) ------
func set_kin(a: int, b: int) -> JudgmentSocial:
	_kin[_k(a, b)] = true
	return self


func set_friends(a: int, b: int) -> JudgmentSocial:
	_friends[_k(a, b)] = true
	return self
