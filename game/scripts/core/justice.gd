class_name Justice
extends RefCounted
## GP-CRIME-PURSUIT step A1 (owner directive 2026-10-24, open item 03 A and D; docs/design/REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS.md
## J1): the authorities' file on each offender. One case per player, keyed by the player's reference ("player" for the
## host, "player:<pid>" for a guest; never the shared person id -2), so a guest's crime is never the host's.
##
## It extends the player's own crime record (PlayerState.crimes, which now also holds "assault", "guard_assault" and
## "killing"): each crime in a case points at its record entry (`rec`) and holds only what enforcement needs. It is not
## a second ledger of morality: the judgment GOOD/BAD ledgers, Relations' regard and notoriety stay as they are and
## stay authoritative for what people think; a case only drives what the guards do.
##
## Knowledge, never omniscience. A crime is in the case whether anyone saw it or not, but a guard knows of it only
## through the channels the world has: seeing it (World.raise_alarm, World.witness), being told (World.deliver_report),
## and (A3) the hue and cry and another guard's word. The tier a guard acts on is that of the crimes THAT guard knows.
## The last-known place is written only when a guard actually sees the offender (or is told where they were seen).
##
## A case is saved under the optional World key "justice" (absent in a Build 20 save: no cases; no save_version change).
## Numbers: balance.json "justice" (agent proposals; the hue and cry's earshot PROPOSED for the owner).
##
## Case: {offender: ref, name, opened: minute, crimes: [crime], known: {guard id: [crime index]}, aware: {villager id:
##   crime index} (who knows who did a violent crime: witnesses, the hue and cry's hearers), pursuers: {guard id: true},
##   last: [x, y, minute, level] (where a guard last saw them, or was told they were seen; [] never), guard_struck: blows
##   at guards, resisted: bool (struck a guard or killed again while a guard was on the case)}.
## Crime: {kind, day, t, victim, at: [x, y], seen: witnesses, rec: index in PlayerState.crimes, settled: "" | "fined" |
##   "yielded" | "taken" | "lapsed"}.
## Status (status()): "clear" (nothing outstanding that a guard knows), "pursued" (a guard is on it), "wanted" (outstanding
## and known, nobody on it now). A closed case (the offender died: owner answer 3, "case ends; stain stays") moves to
## `closed` (the last justice.closed_kept), with its resolution.

var w
var cases := {}            # offender ref -> case
var closed: Array = []     # the last closed cases (oldest first): case + {resolution, closed_t}


func _init(world) -> void:
	w = world


static func cfg() -> Dictionary:
	return GameData.b("justice")


static func severity(kind: String) -> int:
	var s: Dictionary = cfg().severity
	return int(s.get(kind, s._default))


static func is_theft(kind: String) -> bool:
	return (cfg().theft_kinds as Array).has(kind)


static func is_violent(kind: String) -> bool:
	return (cfg().violent_kinds as Array).has(kind)


static func tier_rank(tier: String) -> int:
	return (cfg().tiers as Array).find(tier)


static func response(tier: String) -> Dictionary:
	return cfg().response[tier]


func is_empty() -> bool:
	return cases.is_empty() and closed.is_empty()


func case_of(ref: String) -> Dictionary:
	return cases.get(ref, {})


## The offender's case, opened when it is first needed.
func _open(ref: String) -> Dictionary:
	if cases.has(ref):
		return cases[ref]
	var p: PlayerState = w.player_of_ref(ref)
	var c := {"offender": ref, "name": ("%s %s" % [p.name, p.family]) if p != null else ref, "opened": w.minutes, "crimes": [],
		"known": {}, "aware": {}, "pursuers": {}, "last": [], "guard_struck": 0, "resisted": false}
	cases[ref] = c
	return c


## A crime by player `ref` (its record entry already appended to that player's crimes): `kind`, against `victim` (an NPC
## or null), at `at`, seen by `seen` people (the witnesses' count of the record). Returns the crime's index in the case.
## A blow at a guard or a killing while a guard is on the case is resistance (lethal force may follow, response.lethal).
func record(ref: String, kind: String, victim, at: Vector2, seen: int, rec := -1) -> int:
	var c := _open(ref)
	var cr := {"kind": kind, "day": w.day(), "t": w.minutes, "victim": victim.id if victim != null else -1, "at": [at.x, at.y],
		"seen": seen, "rec": rec, "settled": ""}
	c.crimes.append(cr)
	if kind == "guard_assault":
		c.guard_struck = int(c.guard_struck) + 1
	if (kind == "guard_assault" or kind == "killing") and not (c.pursuers as Dictionary).is_empty():
		c.resisted = true
	if kind == "guard_assault" and _known_rank(c) >= tier_rank("murder"):
		c.resisted = true
	w.stat("justice_crimes_" + kind)
	return c.crimes.size() - 1


## Guard `g` now knows of crimes `cis` of `ref`'s case (seeing them, being told, A3: hearing the hue and cry, another
## guard's word). Settled crimes are not learned. `at` (optional): where the offender was seen, at minute `t`.
func learn(g: NPC, ref: String, cis: Array, at := Vector2.INF, t := -1.0) -> void:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty() or g == null:
		return
	var key := str(g.id)
	var k: Array = c.known.get(key, [])
	for ci in cis:
		var i := int(ci)
		if i >= 0 and i < c.crimes.size() and not k.has(i) and str(c.crimes[i].settled) == "":
			k.append(i)
	k.sort()
	c.known[key] = k
	if at != Vector2.INF:
		saw_at(ref, at, t if t >= 0.0 else w.minutes, 0)


## Where the offender was last seen by the authorities (a guard's eyes, or a place a report or the hue and cry named):
## kept only when newer than what the case holds.
func saw_at(ref: String, at: Vector2, t: float, level := 0) -> void:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return
	if (c.last as Array).is_empty() or float(c.last[2]) <= t:
		c.last = [at.x, at.y, t, level]


## The crimes guard `g` knows of in `ref`'s case that are still outstanding.
func known_by(g: NPC, ref: String) -> Array:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty() or g == null:
		return []
	return (c.known.get(str(g.id), []) as Array).filter(func(i): return str(c.crimes[int(i)].settled) == "")


## Whether guard `g` knows of anything outstanding against `ref`.
func knows(g: NPC, ref: String) -> bool:
	return not known_by(g, ref).is_empty()


## The tier of a set of crimes (indices into the case's crimes; settled ones ignored): multiple_murder for two or more
## killings, murder for one, assault for any blow, repeated_theft for repeat_theft thefts within repeat_days (settled
## ones count towards the repeat, one must be outstanding), theft, else minor.
func tier_of(c: Dictionary, cis: Array) -> String:
	var kills := 0
	var blows := 0
	var thefts := 0
	for ci in cis:
		var cr: Dictionary = c.crimes[int(ci)]
		if str(cr.settled) != "":
			continue
		match str(cr.kind):
			"killing":
				kills += 1
			"assault", "guard_assault":
				blows += 1
			_:
				if is_theft(str(cr.kind)):
					thefts += 1
	if kills >= 2:
		return "multiple_murder"
	if kills == 1:
		return "murder"
	if blows > 0:
		return "assault"
	if thefts > 0:
		var recent := 0
		for cr in c.crimes:
			if is_theft(str(cr.kind)) and w.day() - int(cr.day) <= int(cfg().repeat_days):
				recent += 1
		return "repeated_theft" if recent >= int(cfg().repeat_theft) else "theft"
	return "minor"


## The tier guard `g` acts on: of the outstanding crimes they know.
func tier_for(g: NPC, ref: String) -> String:
	var c: Dictionary = cases.get(ref, {})
	return "minor" if c.is_empty() else tier_of(c, known_by(g, ref))


## The case's tier over every outstanding crime any guard knows of (what the authorities as a whole know).
func known_tier(ref: String) -> String:
	var c: Dictionary = cases.get(ref, {})
	return "minor" if c.is_empty() else tier_of(c, _known_all(c))


func _known_all(c: Dictionary) -> Array:
	var all := []
	for key in c.known:
		for i in c.known[key]:
			if not all.has(int(i)):
				all.append(int(i))
	all.sort()
	return all


func _known_rank(c: Dictionary) -> int:
	return tier_rank(tier_of(c, _known_all(c)))


## The case's severity score: the sum of severity() over outstanding crimes (all of them, known or not; diagnostics and
## the workbook; it never touches a ledger).
func score(ref: String) -> int:
	var c: Dictionary = cases.get(ref, {})
	var s := 0
	for cr in c.get("crimes", []):
		if str(cr.settled) == "":
			s += severity(str(cr.kind))
	return s


## "clear", "pursued" or "wanted" (see the header); "" when there is no open case.
func status(ref: String) -> String:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return ""
	if not (c.pursuers as Dictionary).is_empty():
		return "pursued"
	return "wanted" if not _known_all(c).filter(func(i): return str(c.crimes[i].settled) == "").is_empty() else "clear"


## Crimes `cis` (or, with [], every outstanding one) are settled `how` ("fined", "yielded", "taken", "lapsed"): they no
## longer count in any guard's tier. Returns how many were settled.
func settle(ref: String, cis: Array, how: String) -> int:
	var c: Dictionary = cases.get(ref, {})
	if c.is_empty():
		return 0
	var k := 0
	for i in c.crimes.size():
		if (cis.is_empty() or cis.has(i)) and str(c.crimes[i].settled) == "":
			c.crimes[i].settled = how
			k += 1
	if k > 0:
		w.stat("justice_settled_" + how, k)
	if cis.is_empty():
		c.resisted = false
	return k


## Dawn: an outstanding crime older than its tier's wanted_days lapses (murder never: wanted_days -1).
func dawn() -> void:
	for ref in cases.keys():
		var c: Dictionary = cases[ref]
		for i in c.crimes.size():
			var cr: Dictionary = c.crimes[i]
			if str(cr.settled) != "":
				continue
			var t := tier_of(c, [i]) if not is_theft(str(cr.kind)) else "theft"
			var days := int(response(t).wanted_days)
			if days >= 0 and w.day() - int(cr.day) > days:
				cr.settled = "lapsed"
				w.stat("justice_settled_lapsed")


## The offender died (owner answer 3, 2026-10-24: "Case ends; stain stays"): the case closes and nobody hunts the heir;
## the family's existing reputation (JudgmentBonds) carries the stain.
func on_death(ref: String) -> void:
	close(ref, "died")


func close(ref: String, resolution: String) -> void:
	if not cases.has(ref):
		return
	var c: Dictionary = cases[ref]
	cases.erase(ref)
	c.resolution = resolution
	c.closed_t = w.minutes
	c.pursuers = {}
	closed.append(c)
	while closed.size() > int(cfg().closed_kept):
		closed.pop_front()
	w.stat("justice_closed_" + resolution)


# ---------------------------------------------------------------- save
func to_dict() -> Dictionary:
	return {"cases": cases.duplicate(true), "closed": closed.duplicate(true)}


func load_dict(d: Dictionary) -> void:
	cases = {}
	for ref in d.get("cases", {}):
		cases[str(ref)] = _norm(d.cases[ref])
	closed = (d.get("closed", []) as Array).map(func(c): return _norm(c))


## JSON brings every number back a float: the indices and ids are ints again.
static func _norm(c: Dictionary) -> Dictionary:
	var o: Dictionary = c.duplicate(true)
	var known := {}
	for key in o.get("known", {}):
		known[str(key)] = (o.known[key] as Array).map(func(i): return int(i))
	o.known = known
	var aware := {}
	for key in o.get("aware", {}):
		aware[str(key)] = int(o.aware[key])
	o.aware = aware
	var pursuers := {}
	for key in o.get("pursuers", {}):
		pursuers[str(key)] = true
	o.pursuers = pursuers
	o.guard_struck = int(o.get("guard_struck", 0))
	o.resisted = bool(o.get("resisted", false))
	for cr in o.get("crimes", []):
		for k in ["day", "victim", "seen", "rec"]:
			cr[k] = int(cr.get(k, -1))
		cr.settled = str(cr.get("settled", ""))
	return o
