class_name DialogueVoice
extends RefCounted
## How a villager words what they know (REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS steps S1 and S2): the speaker's own voice
## for the listener ("you"), themselves, their household and their family. Presentation only: nothing here changes the
## world. What the speaker knows, and how they meet the listener, are EventTalk's (core); the wording is data
## (res://data/dialogue_events.json, mml-dialogue-events/1).
##
## S2 (the stopgap for news, until the event-perspective layer D1-D4): a village-record line is a sentence written when
## the event happened; it is re-voiced for the speaker only where the people it names can be told apart by name: the
## listener ("you"), the speaker ("I"), the speaker's own household ("our family", "we", "us") and the speaker's
## relatives ("Mum", "my daughter Rose"). A line whose subject would need a verb the data does not list, or whose names
## are shared, is left as it is. The record has no participant data beyond its words, so nothing is guessed.

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


## home()'s line for a household death the speaker remembers ("<first> died (<cause>)").
static func home_death(w: World, n: NPC, first: String, cause: String) -> String:
	var o := EventTalk.dead_named(w, n, first)
	var t: Dictionary = data().home_death
	var extra := {"victim": first, "cause": cause}
	var kind := "other"
	if cause == "starvation":
		kind = "starvation"
	elif cause == "old age":
		kind = "old_age"
	elif cause.begins_with("slain by "):
		var killer := cause.substr(9)
		kind = "listener" if killer == EventTalk.listener_name(w) else "slain"
		extra.killer = killer
	return _fill(Dialogue._pick(w, n, t[kind], 9), w, n, o, extra)


# ---------------------------------------------------------------- S2: re-voicing the village record
## The names in a record line the speaker would say otherwise: [{s, kind (you | i | we | kin), phrase}], longest first.
## Only names that belong to one person (or one household) are listed: a shared name is left alone.
static func mentions(w: World, n: NPC) -> Array:
	var out := []
	var you := EventTalk.listener_name(w)
	if EventTalk.count_named(w, you) == 1:
		out.append({"s": you, "kind": "you"})
	var me := EventTalk.full(n)
	if me != you and EventTalk.count_named(w, me) == 1:
		out.append({"s": me, "kind": "i"})
	if n.household >= 0:
		var fam: String = w.households[n.household].family
		var same := 0
		for hh in w.households:
			if hh.family == fam:
				same += 1
		if same == 1:
			out.append({"s": "The %s household" % fam, "kind": "we"})
			out.append({"s": "the %s household" % fam, "kind": "we"})
	for o: NPC in w.npcs:
		if o == n or EventTalk.relation(w, n, o) == "":
			continue
		var full := EventTalk.full(o)
		if full != you and full != me and EventTalk.count_named(w, full) == 1:
			out.append({"s": full, "kind": "kin", "phrase": name_for(w, n, o)})
	out.sort_custom(func(a, b): return a.s.length() > b.s.length() or (a.s.length() == b.s.length() and a.s < b.s))
	return out


const SUBJECT := {"you": "you", "i": "I", "we": "we"}
const OBJECT := {"you": "you", "i": "me", "we": "us"}
const POSSESSIVE := {"you": "your", "i": "my", "we": "our"}


## One record line in the speaker's own voice (see the class note), or the line unchanged. `state` carries what the
## reply has said already: the first time the speaker's household is the subject it is "our family", then "we".
static func revoice(w: World, n: NPC, text: String, ments: Array, state: Dictionary) -> String:
	var news: Dictionary = data().news
	var t := text.strip_edges()
	var died := RegEx.create_from_string(str(news.died)).search(t)
	if died != null:
		for m in ments:
			if died.get_string("victim") == m.s and m.kind != "you":
				t = str(news.died_kin).format({"victim": m.s, "cause": died.get_string("cause")})
				break
	var verbs: Dictionary = news.verbs
	var word_re := RegEx.create_from_string("^\\s+([A-Za-z]+)")
	for m in ments:
		var from := 0
		while true:
			var i := t.find(m.s, from)
			if i < 0:
				break
			var after := t.substr(i + m.s.length())
			var rep := ""
			var cut := 0                               # characters after the name the replacement also takes
			if after.begins_with("'s ") or after.begins_with("' "):
				cut = 2 if after.begins_with("'s") else 1
				rep = Dialogue.possessive(m.phrase) if m.kind == "kin" else POSSESSIVE[m.kind]
			else:
				var wm := word_re.search(after)
				var word := wm.get_string(1) if wm != null else ""
				if m.kind == "kin":
					rep = m.phrase
				elif verbs.has(word):
					var form = verbs[word]
					var verb: String = form if form is String else str(form[m.kind])
					if m.kind == "we" and i == 0 and not bool(state.get("we_said", false)):
						rep = "our family"                 # third person: the verb stays as written
					else:
						rep = SUBJECT[m.kind]
						after = after.substr(0, wm.get_start(1)) + verb + after.substr(wm.get_end(1))
					if m.kind == "we":
						state.we_said = true
				elif i == 0:
					if m.kind != "we":
						return text                        # a subject whose verb the data does not list: unchanged
					rep = "our family"
					state.we_said = true
				elif word.length() > 2 and word.ends_with("s") and word == word.to_lower():
					return text                            # perhaps a verb in the present ("leaves"): unchanged
				else:
					rep = OBJECT[m.kind]
			if i == 0:
				rep = _cap(rep)
			t = t.substr(0, i) + rep + after.substr(cut)
			from = i + rep.length()
	return t


## Whether a record line is an attack whose victim's death by the same hand is also on the record (`deaths`: the
## "victim|cause" keys of the record's death lines): the death tells it.
static func attack_told_by_death(text: String, deaths: Dictionary) -> bool:
	var a := RegEx.create_from_string(str(data().news.attacked)).search(text.strip_edges())
	return a != null and deaths.has("%s|slain by %s" % [a.get_string("victim"), a.get_string("attacker")])


## The "victim|cause" keys of every death line in these record texts.
static func death_keys(texts: Array) -> Dictionary:
	var re := RegEx.create_from_string(str(data().news.died))
	var out := {}
	for t in texts:
		var d := re.search(str(t).strip_edges())
		if d != null:
			out["%s|%s" % [d.get_string("victim"), d.get_string("cause")]] = true
	return out
