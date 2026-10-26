class_name MessageJournal
extends RefCounted
## GP-MESSAGE-JOURNAL (owner, 2026-10-26, docs/directives/2026-10-26_messages_journal_persistence.md): the messages shown to each
## player that are worth keeping, held by the World and saved with it (World.to_dict, optional key "messages"; absent in a save
## from before it: an empty journal, nothing else changed). The journal's Messages page reads it.
##
## A message is kept only when its source gives it a category of game/data/message_journal.json ("crime", "trade", ...); an
## untagged message (routine interface feedback: a target chosen, a refusal, a menu answer) is shown and not kept. Entries are
## kept per player, by the player's reference (World.player_ref: "player" for the host, "player:<pid>" for a guest), in the order
## they came, each as [world minutes, category, text]: the minutes give the day and the time it was shown. Retention is bounded
## per player in two tiers: past a tier's cap its oldest entry goes, so ordinary messages never push out significant ones. The
## same words again the same day, straight after themselves, are not kept twice (a refusal or a greeting repeated).
## Presentation history only: nothing in the simulation reads it, and recording draws no random number.

const DATA := "res://data/message_journal.json"
const KEY := "messages"                  # the World's optional save key

static var _cfg: Dictionary = {}

var by_ref: Dictionary = {}              # player reference -> Array of [minutes, category, text], oldest first


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA)) if FileAccess.file_exists(DATA) else null
		_cfg = d if d is Dictionary else {"tiers": {}}
	return _cfg


## The tier of a category: "significant", "ordinary", or "" (not kept).
static func tier_of(category: String) -> String:
	if category == "":
		return ""
	var tiers: Dictionary = cfg().get("tiers", {})
	for t in ["significant", "ordinary"]:
		if (tiers.get(t, {}).get("categories", []) as Array).has(category):
			return t
	return ""


static func cap_of(tier: String) -> int:
	return int(cfg().get("tiers", {}).get(tier, {}).get("cap", 0))


## Keep `text` for player `ref` at world time `minutes`, when `category` is one the journal keeps. True when kept.
func record(ref: String, minutes: float, category: String, text: String) -> bool:
	var tier := tier_of(category)
	if tier == "" or text.strip_edges() == "" or ref == "":
		return false
	var list: Array = by_ref.get(ref, [])
	var day := int(minutes / World.DAY)
	if not list.is_empty():
		var last: Array = list[-1]
		if str(last[2]) == text and int(float(last[0]) / World.DAY) == day:
			return false
	list.append([int(minutes), category, text])
	_trim(list, tier)
	by_ref[ref] = list
	return true


## Past the tier's cap, drop that tier's oldest entries (never the other tier's).
func _trim(list: Array, tier: String) -> void:
	var cap := cap_of(tier)
	var n := 0
	for e in list:
		if tier_of(str(e[1])) == tier:
			n += 1
	var i := 0
	while n > cap and i < list.size():
		if tier_of(str(list[i][1])) == tier:
			list.remove_at(i)
			n -= 1
		else:
			i += 1


## The entries of player `ref`, oldest first (a copy).
func entries(ref: String) -> Array:
	return (by_ref.get(ref, []) as Array).duplicate(true)


func is_empty() -> bool:
	for k in by_ref:
		if not (by_ref[k] as Array).is_empty():
			return false
	return true


func to_dict() -> Dictionary:
	var out := {}
	var refs: Array = by_ref.keys()
	refs.sort()
	for r in refs:
		if not (by_ref[r] as Array).is_empty():
			out[r] = (by_ref[r] as Array).duplicate(true)
	return out


## From a save's "messages" (absent or malformed: empty). Numbers come back from JSON as floats; they are kept as ints.
static func from_dict(d) -> MessageJournal:
	var j := MessageJournal.new()
	if not (d is Dictionary):
		return j
	for r in d:
		var list := []
		if d[r] is Array:
			for e in d[r]:
				if e is Array and e.size() >= 3:
					list.append([int(e[0]), str(e[1]), str(e[2])])
		if not list.is_empty():
			j.by_ref[str(r)] = list
	return j
