class_name SettlementSave
extends RefCounted
## PROVISIONAL save section (Expansion 18, PROS-18): what the settlement model keeps between sessions, in its own key
## of the save dictionary, "x18_settlements", so World.SAVE_VERSION is not bumped on this branch (Build 17 owns the
## next save versions; SET phases bump from Build 17's last version at integration, ENGINEERING_PLAN s.2 item 6).
##
## World.load_dict ignores keys it does not know, so a save carrying the section loads in the live game unchanged,
## and a save without it (every save of version 14-16) gives the default state: no history, no off-map settlements.
## The hook into World.to_dict/load_dict is NOT made on this branch (it would touch world.gd, which Build 17 rewrites);
## attach()/extract() take the save dictionary, and the integration step calls them from World.
##
## Section shape (format mml-settlements/0, provisional; becomes /1 at integration):
##   {"format", "capabilities": {settlement_id: {levels, since, history}}, "regions": [SettlementLedger.to_dict()],
##    "agreements": [[a, b, kind]], "day": int}

const KEY := "x18_settlements"
const FORMAT := "mml-settlements/0"


static func default_state() -> Dictionary:
	return {"format": FORMAT, "capabilities": {}, "regions": [], "agreements": [], "day": -1}


## Put the settlement state into a save dictionary (a deep copy).
static func attach(save: Dictionary, state: Dictionary) -> void:
	var s := state.duplicate(true)
	s.format = FORMAT
	save[KEY] = s


## The settlement state of a save dictionary: the default for a save without the section (every save before this
## expansion); a section of an unknown format is refused with a message, never reinterpreted (CLAUDE.md s.7).
static func extract(save: Dictionary) -> Dictionary:
	if not save.has(KEY):
		return default_state()
	var s = save[KEY]
	if not s is Dictionary or str(s.get("format", "")) != FORMAT:
		return {"error": "settlement section of unknown format %s; kept, not loaded" % str((s as Dictionary).get("format", "?") if s is Dictionary else "?")}
	var out := default_state()
	for k in out:
		if s.has(k):
			out[k] = s[k]
	# JSON turns ints into floats: normalise what the model compares
	out.day = int(out.day)
	for sid in out.capabilities:
		var c: Dictionary = out.capabilities[sid]
		for k in c.get("levels", {}):
			c.levels[k] = int(c.levels[k])
		for k in c.get("since", {}):
			c.since[k] = int(c.since[k])
		var hist := []
		for e in c.get("history", []):
			hist.append({"day": int(e.day), "industry": str(e.industry), "from": int(e.from), "to": int(e.to)})
		c.history = hist
	return out


## LEGACY: the provisional "regions" list of ledger fixtures (REG-PARTY-01: the five settlements are OffMapSettlement, saved in the
## save's "regions" key by Regions.to_dict, and trade through SettlementParty; this section is kept so an x18 save of the earlier
## prospective model still loads). Off-map ledgers of a state (their books opened at load).
static func regions(state: Dictionary) -> Array:
	var out := []
	for d in state.get("regions", []):
		out.append(SettlementLedger.from_dict(d))
	return out


static func store_regions(state: Dictionary, ledgers: Array) -> void:
	state.regions = ledgers.map(func(l): return l.to_dict())
