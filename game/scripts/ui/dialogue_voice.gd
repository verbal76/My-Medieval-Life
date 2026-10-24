class_name DialogueVoice
extends RefCounted
## How a villager words what they know (REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS steps S1 and A4-A6): the speaker's own voice
## for the listener ("you"), themselves, their household and their family. Presentation only: nothing here changes the
## world. What the speaker knows, and how they meet the listener, are EventTalk's (core); the wording is data
## (res://data/dialogue_events.json, mml-dialogue-events/2).
##
## A4 (the perspective renderer, REPAIR_AUDIT D4): an event the speaker knows (EventTalk.events: the people in it and how
## the speaker learned it) is said from the speaker's place in it, from the data's clause for its type and the frame for
## how they know it. The people are told apart by who they are, never by their names, so two people of one name, or a
## household sharing a surname, are never confused. (The S2 stopgap, which re-voiced lines of the village record, went
## with the record's use as news: a villager tells only what they know.)

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue_events.json"))
		assert(d is Dictionary, "bad data file res://data/dialogue_events.json")
		_data = d
	return _data




static func _role_pick(table, role: String):
	if table is Dictionary:
		return table.get(role, table.get("default"))
	return table


## How the speaker names `o`: "Mum", "my daughter Rose", "our Hugh"; or their full name when not family.
static func name_for(w: World, n: NPC, o: NPC) -> String:
	var rel := EventTalk.relation(w, n, o)
	if rel == "":
		return Dialogue.full_name(o)
	var by_sex: Dictionary = data().kin[rel]
	return str(_role_pick(by_sex.get(o.sex, by_sex.male), n.role)).format({"name": o.name})


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


static func _fill(line: String, w: World, n: NPC, victim: NPC, extra := {}) -> String:
	var v := name_for(w, n, victim) if victim != null else str(extra.get("victim", "them"))
	var f := {"victim": v, "Victim": _cap(v), "them": ("her" if victim != null and victim.sex == "female" else "him")}
	for k in extra:
		if k == "victim":
			continue
		f[k] = extra[k]
		f[_cap(k)] = _cap(str(extra[k]))
	return line.format(f)




## The opening line of a speaker who knows the listener harmed someone (violence), or "".
static func witness_line(w: World, n: NPC, k: Dictionary) -> String:
	if k.is_empty():
		return ""
	var st := EventTalk.stance(w, n, k)
	var lines: Array = _role_pick(data().witness[k.crime][k.how][st], n.role)
	return _fill(Dialogue._pick(w, n, lines, 8), w, n, k.victim)


## The line a busy speaker calls out who knows the listener harmed someone, or "".
static func witness_brush(w: World, n: NPC, k: Dictionary) -> String:
	if k.is_empty():
		return ""
	return Dialogue._pick(w, n, data().witness_brush[EventTalk.stance(w, n, k)], 6)


## home()'s line for a household death the speaker remembers ("<first> died (<cause>)"). A5: the memory says only that
## they were slain; who did it is what the speaker knows of the killing (EventTalk.killer_of: seen or told), else nobody.
## (An older save's memory may still name the killer: "slain by <name>".)
static func home_death(w: World, n: NPC, first: String, cause: String) -> String:
	var o := EventTalk.dead_named(w, n, first)
	var t: Dictionary = data().home_death
	var extra := {"victim": first, "cause": cause, "they": "she" if o != null and o.sex == "female" else "he"}
	var kind := "other"
	if cause == "starvation":
		kind = "starvation"
	elif cause == "old age":
		kind = "old_age"
	elif cause.begins_with("slain by "):
		var killer := cause.substr(9)
		kind = "listener" if killer == EventTalk.listener_name(w) else "slain"
		extra.killer = killer
	elif cause == "slain":
		var k = EventTalk.killer_of(w, n, o) if o != null else null
		if k == null:
			kind = "slain_unknown"
		elif k is PlayerState and k == w.player:
			kind = "listener"
		else:
			kind = "slain"
			extra.killer = person(w, n, k, "subj", {})
	return _fill(Dialogue._pick(w, n, t[kind], 9), w, n, o, extra)


# ---------------------------------------------------------------- A4: the perspective renderer
static func talk() -> Dictionary:
	return data().talk


## How the speaker names a person in an event, as `form`: "subj" (the subject), "obj" or "poss" ("your", "Mum's").
## `said` (the reply so far) turns "our family" into "we" after its first time.
static func person(w: World, n: NPC, who, form: String, said: Dictionary) -> String:
	var r := EventTalk.role_of(w, n, who)
	match str(r.kind):
		"you":
			return {"subj": "you", "obj": "you", "poss": "your"}[form]
		"i":
			return {"subj": "I", "obj": "me", "poss": "my"}[form]
		"none":
			return {"subj": "someone", "obj": "someone", "poss": "someone's"}[form]
		"player":
			var pn := EventTalk.full(r.who)
			return Dialogue.possessive(pn) if form == "poss" else pn
	var phrase := name_for(w, n, r.who)
	return Dialogue.possessive(phrase) if form == "poss" else phrase


## A group of people (an event's beneficiaries or victims): "us" when the speaker is among them, "you" for the listener,
## "the <Family>s" for a whole household that is not the speaker's, else the first one or two as named.
static func group(w: World, n: NPC, people: Array, form: String, hh: int, said: Dictionary) -> String:
	var live := people.filter(func(p): return p != null)
	if live.is_empty():
		return "someone" if form != "poss" else "someone's"
	if live.size() == 1:
		return person(w, n, live[0], form, said)
	if live.has(n) or (hh >= 0 and hh == n.household):
		return {"subj": "we", "obj": "us", "poss": "our"}[form]
	if live.has(w.player):
		return {"subj": "you", "obj": "you", "poss": "your"}[form]
	if hh >= 0:
		var fam := str(w.households[hh].family) + "s"
		return ("the " + fam) if form != "poss" else ("the %s'" % fam)
	var a := person(w, n, live[0], "obj", said)
	var b := person(w, n, live[1], "obj", said)
	return ("%s and %s" % [a, b]) if form != "poss" else ("%s and %s's" % [a, b])


## The subject person class for a clause's verb: "i", "we", "you", else "default".
static func person_class(w: World, n: NPC, who) -> String:
	var r := EventTalk.role_of(w, n, who)
	return str(r.kind) if str(r.kind) in ["i", "you"] else "default"


## One event item (EventTalk.events) as the speaker says it: its type's clause with the people from the speaker's side,
## framed by how they know it. "" for a type the data does not word.
static func event_line(w: World, n: NPC, it: Dictionary, said: Dictionary) -> String:
	var types: Dictionary = talk().types
	if not types.has(str(it.type)):
		return ""
	var c := clause(w, n, it, said)
	if c == "":
		return ""
	return frame(w, n, it, c)


## The bare clause of an event item, with no frame ("you killed my daughter Rose").
static func clause(w: World, n: NPC, it: Dictionary, said: Dictionary) -> String:
	var t: Dictionary = talk().types.get(str(it.type), {})
	if t.is_empty():
		return ""
	var actors: Array = it.get("actors", [])
	var a0 = actors[0] if not actors.is_empty() else null
	var key := person_class(w, n, a0)
	var hh := int(it.get("hh", -1))
	var by_household: bool = hh >= 0 and (talk().household_types as Array).has(str(it.type)) and (actors.is_empty() or (a0 is NPC and a0.household == hh))
	if by_household:
		key = "we" if hh == n.household else "default"
	var tags: Dictionary = it.get("tags", {})
	var line := ""
	if str(it.type) == "death":
		line = str(t.get(str(tags.get("cause", "")), t.default))
	elif (it.get("victims", []) as Array).is_empty() and t.has("novictim"):
		line = str(t.novictim)
	elif str(it.type) == "gift" and not tags.has("item") and t.has("noitem"):
		line = str(t.noitem)
	else:
		line = str(t.get(key, t.get("default", "")))
	var subj := ""
	if by_household:
		subj = household(w, n, hh, said)
	else:
		subj = person(w, n, a0, "subj", said)
	var f := {"A": subj, "As": person(w, n, a0, "poss", said) if a0 != null else "their",
		"A2": person(w, n, actors[1], "obj", said) if actors.size() > 1 else "someone",
		"V": group(w, n, it.get("victims", []), "obj", -1, said), "Vs": group(w, n, it.get("victims", []), "poss", -1, said),
		"B": group(w, n, it.get("benef", []), "obj", hh, said), "Bs": group(w, n, it.get("benef", []), "poss", hh, said),
		"item": _item_words(str(tags.get("item", ""))), "price": str(tags.get("price", "")), "rent": str(tags.get("rent", "")),
		"place": str(it.get("place", "somewhere")), "cause": str(tags.get("cause", "")),
		"thing": GameData.item_name(str(tags.get("item", ""))).to_lower() if tags.has("item") else "",
		"G": str((talk().givers as Dictionary).get(str(tags.get("giver", "")), "someone"))}
	return line.format(f)


## How the speaker names their own household ("our family" the first time, then "we") or another ("the Lamberts").
static func household(w: World, n: NPC, hh: int, said: Dictionary) -> String:
	if hh == n.household:
		var first := not bool(said.get("we", false))
		said.we = true
		return str(talk().household_word.first) if first else str(talk().household_word.then)
	return "the %ss" % str(w.households[hh].family)


static func _item_words(id: String) -> String:
	if id == "":
		return ""
	return Dialogue._article(GameData.item_name(id).to_lower())


## A clause framed by how the speaker knows it: seen, taken part in, told by someone, or heard as a rumour.
static func frame(w: World, n: NPC, it: Dictionary, c: String) -> String:
	var how := str(it.get("how", "rumour"))
	var teller: NPC = it.get("teller")
	if how == "told" and teller == null:
		how = "rumour"
	if how == "saw" and EventTalk.role_of(w, n, (it.get("actors", [null]) + [null])[0]).kind == "i":
		how = "part"                               # one's own deed is not "seen"
	var lines: Array = talk().frames[how]
	var line := str(Dialogue._pick(w, n, lines, 11 + str(it.get("key", "")).hash() % 7))
	var tname := name_for(w, n, teller) if teller != null else ""
	return Dialogue.sentence(line.format({"c": c, "C": _cap(c), "T": tname}))


# ---------------------------------------------------------------- A6: related events as one
## A group of related events (EventTalk.groups) as the speaker says it: one event alone as event_line; a rule's events
## joined by its line (dialogue_events.json "merge"), every event's own facts kept, framed by how the speaker knows the
## first. A gift from the listener to the speaker's own people is thanks.
static func group_line(w: World, n: NPC, g: Dictionary, said: Dictionary) -> String:
	var items: Array = g.items
	var first: Dictionary = items[0]
	if str(g.rule) == "":
		if str(first.type) == "gift" and _gift_to_ours(w, n, first):
			var c := clause_as(w, n, first, said, "you_to_ours")
			return Dialogue.sentence(_cap(c)) if c != "" else ""
		return event_line(w, n, first, said)
	var rule: Dictionary = {}
	for r in EventTalk.rules():
		if str(r.id) == str(g.rule):
			rule = r
	var actors: Array = first.get("actors", [])
	var a0 = actors[0] if not actors.is_empty() else null
	var hh := int(first.get("hh", -1))
	var key := "we" if hh >= 0 and hh == n.household else person_class(w, n, a0)
	var line := str((rule.line as Dictionary).get(key, rule.line.default))
	var c1 := clause(w, n, first, said)
	var c2 := clause(w, n, items[1], said) if items.size() > 1 else ""
	var pr := _pronoun(w, n, first)
	var tags: Dictionary = first.get("tags", {})
	var f := {"c1": c1, "C1": _cap(c1), "C2": _cap(c2), "c2": c2, "P": pr[0], "have": pr[1], "times": Dialogue.NUMBERS[mini(int(g.times), 12)] if int(g.times) <= 12 else str(g.times),
		"G": str((talk().givers as Dictionary).get(str(tags.get("giver", "")), "someone")),
		"B": group(w, n, first.get("benef", []), "obj", hh, said)}
	return frame(w, n, first, line.format(f))


## The first event's subject as a pronoun starting a sentence, and its verb "have"/"has": We, You, I, They, He, She.
static func _pronoun(w: World, n: NPC, it: Dictionary) -> Array:
	var hh := int(it.get("hh", -1))
	if hh >= 0 and (talk().household_types as Array).has(str(it.type)):
		return ["We", "have"] if hh == n.household else ["They", "have"]
	var actors: Array = it.get("actors", [])
	var r := EventTalk.role_of(w, n, actors[0] if not actors.is_empty() else null)
	match str(r.kind):
		"you":
			return ["You", "have"]
		"i":
			return ["I", "have"]
		"none":
			return ["They", "have"]
	var who = r.get("who")
	return (["She", "has"] if who != null and who.sex == "female" else ["He", "has"])


static func _gift_to_ours(w: World, n: NPC, it: Dictionary) -> bool:
	var actors: Array = it.get("actors", [])
	if actors.is_empty() or not (actors[0] is PlayerState and actors[0] == w.player):
		return false
	for b in it.get("benef", []):
		if b is NPC and (b == n or EventTalk.relation(w, n, b) != ""):
			return true
	return false


## An event's clause from a named variant of its type ("you_to_ours"), the people as in clause().
static func clause_as(w: World, n: NPC, it: Dictionary, said: Dictionary, variant: String) -> String:
	var t: Dictionary = talk().types.get(str(it.type), {})
	if not t.has(variant):
		return clause(w, n, it, said)
	var tags: Dictionary = it.get("tags", {})
	return str(t[variant]).format({"B": _cap(group(w, n, it.get("benef", []), "subj", -1, said)), "item": _item_words(str(tags.get("item", ""))) if tags.has("item") else "a present"})


## What a speaker says who has already told this listener everything they know (A6 said history).
static func said_line(w: World, n: NPC, kind: String, stance := "") -> String:
	var s: Dictionary = data().said
	var lines: Array = s[kind] if kind != "again_witness" else s.again_witness[stance]
	return Dialogue._pick(w, n, lines, 13)
