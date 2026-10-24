class_name DialogueVoice
extends RefCounted
## Who is speaking to whom, and what the speaker knows (REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS steps S1 and S2). Read only:
## nothing here changes the world. The wording is data (res://data/dialogue_events.json, mml-dialogue-events/1).
##
## The speaker is the villager `n`; the listener is the acting player, World.player (World.as_actor makes it a guest
## for a guest's verbs and talk). What the speaker knows of the listener comes from the records that exist:
##   - the speaker's memory (NPC.memory), keyed by the listener's name: "saw <listener> attack <victim>" (a witness,
##     World.player_assault), "<victim> died (slain by <listener>)" (the household, World.kill);
##   - the judgment store (when attached), whose beliefs carry how they were learned (witnessed, told, rumour). Its
##     records name every player as Life.PLAYER_ID until multiplayer Batch C, so they are read only while the listener
##     is the one player in play (a guest's deed is never pinned on the host, nor the host's on a guest).
## Nobody knows what they did not see or learn: a villager with none of these records says nothing of it.
##
## S2 (the stopgap for news, until the event-perspective layer D1-D4): a village-record line is a sentence written when
## the event happened; it is re-voiced for the speaker only where the people it names can be told apart by name: the
## listener ("you"), the speaker ("I"), the speaker's own household ("our family", "we", "us") and the speaker's
## relatives ("Mum", "my daughter Rose"). A line whose subject would need a verb the data does not list, or whose names
## are shared, is left as it is. The record has no participant data beyond its words, so nothing is guessed.


const CLOSE := ["parent", "child", "partner", "sibling", "grandchild", "grandparent"]

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue_events.json"))
		assert(d is Dictionary, "bad data file res://data/dialogue_events.json")
		_data = d
	return _data


## "Wat Ashdown": the listener, as the village names them in its record and its memories.
static func listener_name(w: World) -> String:
	return "%s %s" % [w.player.name, w.player.family]


## Whether a record that names "the player" (Life.PLAYER_ID) names this listener: only while one player is in play.
static func player_id_is_listener(w: World) -> bool:
	return w.players.size() == 1 and w.is_acting_ref(Life.PLAYER_ID)


static func _full(o) -> String:
	return "%s %s" % [o.name, o.family]


## How many people (villagers alive or dead, and players) answer to this full name.
static func _count_named(w: World, full: String) -> int:
	var k := 0
	for o: NPC in w.npcs:
		if _full(o) == full:
			k += 1
	for p in w.players.values():
		if _full(p) == full:
			k += 1
	return k


# ---------------------------------------------------------------- relations
## What `o` is to the speaker `n`: parent, child, partner, sibling, grandchild, grandparent (Life's family graph),
## "household" (same household, no recorded kinship), or "".
static func relation(w: World, n: NPC, o: NPC) -> String:
	if o == null or o == n:
		return ""
	if n.mother == o.id or n.father == o.id:
		return "parent"
	if o.mother == n.id or o.father == n.id:
		return "child"
	if n.partner == o.id and o.partner == n.id:
		return "partner"
	if (n.mother != -1 and n.mother == o.mother) or (n.father != -1 and n.father == o.father):
		return "sibling"
	for pid in [o.mother, o.father]:
		var p := w.npc(pid) if pid >= 0 else null
		if p != null and (p.mother == n.id or p.father == n.id):
			return "grandchild"
	for pid in [n.mother, n.father]:
		var p := w.npc(pid) if pid >= 0 else null
		if p != null and (p.mother == o.id or p.father == o.id):
			return "grandparent"
	if n.household >= 0 and o.household == n.household:
		return "household"
	return ""


static func _role_pick(table, role: String):
	if table is Dictionary:
		return table.get(role, table.get("default"))
	return table


## How the speaker names `o`: "Mum", "my daughter Rose", "our Hugh"; or their full name when not family.
static func name_for(w: World, n: NPC, o: NPC) -> String:
	var rel := relation(w, n, o)
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


# ---------------------------------------------------------------- what the speaker knows of the listener
## The person of this full name the speaker most likely means: their own relative first, then the lowest id.
static func _person(w: World, n: NPC, full: String) -> NPC:
	var best: NPC = null
	for o: NPC in w.npcs:
		if _full(o) != full:
			continue
		if relation(w, n, o) != "":
			return o
		if best == null:
			best = o
	return best


## The dead person a household memory "<first> died (...)" is about: of the speaker's household or family.
static func _dead_named(w: World, n: NPC, first: String) -> NPC:
	var best: NPC = null
	for o: NPC in w.npcs:
		if o.alive or o.name != first:
			continue
		var rel := relation(w, n, o)
		if rel in CLOSE:
			return o
		if rel == "household" and best == null:
			best = o
	return best


## The gravest harm the speaker knows the listener did to someone else:
## {crime: "killing" | "assault", how: "saw" | "heard", victim: NPC, rel: relation(n, victim)}, or {} when none.
## A harm done to the speaker themselves is Dialogue.attacked's.
static func violence(w: World, n: NPC) -> Dictionary:
	var you := listener_name(w)
	var known := {}                              # victim id -> {crime, how, victim}
	var saw_prefix := "saw %s attack " % you
	var slain := " died (slain by %s)" % you
	for m in n.memory:
		var s := str(m)
		if s.begins_with(saw_prefix):
			_know(known, _person(w, n, s.substr(saw_prefix.length())), "assault", "saw", n)
		elif s.ends_with(slain):
			_know(known, _dead_named(w, n, s.substr(0, s.length() - slain.length())), "killing", "heard", n)
	if w.judgment != null and player_id_is_listener(w):
		var mem: Dictionary = w.judgment.memories.get(n.id, {})
		var evs := mem.keys()
		evs.sort()
		for ev in evs:
			var b: Dictionary = w.judgment.belief(n.id, int(ev))
			if b.is_empty() or not str(b.type) in ["killing", "assault"]:
				continue
			var named := false
			for a in b.actors:
				named = named or Life.is_player_id(int(a[0]))
			if not named:
				continue                         # the speaker believes someone else did it
			var f: Dictionary = w.judgment.fact(int(ev))
			if f.is_empty() or (f.victims as Array).is_empty():
				continue
			var how := "saw" if str(b.src) in ["witnessed", "participant"] else "heard"
			_know(known, w.npc(int(f.victims[0])), str(b.type), how, n)
	var best := {}
	var ids := known.keys()
	ids.sort()
	for id in ids:
		var k: Dictionary = known[id]
		var o: NPC = k.victim
		if not o.alive and k.crime == "assault" and k.how == "saw" and _killed_by_listener(w, n, o):
			k.crime = "killing"
		k.rel = relation(w, n, o)
		if best.is_empty() or _grave(k) > _grave(best):
			best = k
	return best


static func _know(known: Dictionary, o: NPC, crime: String, how: String, n: NPC) -> void:
	if o == null or o == n:
		return
	var k: Dictionary = known.get(o.id, {"crime": crime, "how": how, "victim": o})
	if crime == "killing":
		k.crime = "killing"
	if how == "saw":
		k.how = "saw"
	known[o.id] = k


## Whether the speaker has any record that the listener's hand killed `o` (memory or belief), beyond the attack seen.
static func _killed_by_listener(w: World, n: NPC, o: NPC) -> bool:
	if n.memory.has("%s died (slain by %s)" % [o.name, listener_name(w)]):
		return true
	if w.judgment == null or not player_id_is_listener(w):
		return false
	for ev in w.judgment.memories.get(n.id, {}):
		var b: Dictionary = w.judgment.belief(n.id, int(ev))
		if not b.is_empty() and str(b.type) == "killing":
			var f: Dictionary = w.judgment.fact(int(ev))
			if not f.is_empty() and (f.victims as Array).has(o.id):
				return true
	return false


static func _grave(k: Dictionary) -> int:
	var rel := str(k.get("rel", ""))
	return (100 if k.crime == "killing" else 0) + (10 if k.how == "saw" else 0) + (2 if rel in CLOSE else (1 if rel == "household" else 0))


## How the speaker meets the listener they know did this: "confront", "afraid" or "guarded". From what they know (a
## killing seen is the most frightening), their relation to the victim (grief makes the family bold), their role and
## health (a child, an elder or someone hurt is more afraid; a guard less), their temperament (judgment's tolerance
## and anger, when attached) and their tie to the listener (a friend is slower to confront).
static func stance(w: World, n: NPC, k: Dictionary) -> String:
	var bold: int = {"child": -3, "elder": -1}.get(n.role, 0)
	if n.job == "guard":
		bold += 2
	if n.hp < n.max_hp * 0.5:
		bold -= 2
	var rel := str(k.get("rel", ""))
	bold += 3 if rel in CLOSE else (2 if rel == "household" else 0)
	var v: NPC = k.get("victim")
	if v != null and rel == "" and w.relations.friends(n.id, v.id):
		bold += 1
	if k.get("crime") == "killing" and k.get("how") == "saw":
		bold -= 1
	if w.judgment != null:
		bold += clampi((1000 - w.judgment.tolerance(n.id)) / 100, -2, 2)
		if w.judgment.pers != null and w.judgment.pers.anger_at(n.id, w.day(), int(fmod(w.minutes, 1440.0))) > 0:
			bold += 1
	if player_id_is_listener(w) and w.relations.player_friend(n):
		bold -= 1
	if bold <= -2:
		return "afraid"
	return "confront" if bold >= 2 else "guarded"


## The opening line of a speaker who knows the listener harmed someone (violence), or "".
static func witness_line(w: World, n: NPC, k: Dictionary) -> String:
	if k.is_empty():
		return ""
	var st := stance(w, n, k)
	var lines: Array = _role_pick(data().witness[k.crime][k.how][st], n.role)
	return _fill(Dialogue._pick(w, n, lines, 8), w, n, k.victim)


## The line a busy speaker calls out who knows the listener harmed someone, or "".
static func witness_brush(w: World, n: NPC, k: Dictionary) -> String:
	if k.is_empty():
		return ""
	return Dialogue._pick(w, n, data().witness_brush[stance(w, n, k)], 6)


## home()'s line for a household death the speaker remembers ("<first> died (<cause>)").
static func home_death(w: World, n: NPC, first: String, cause: String) -> String:
	var o := _dead_named(w, n, first)
	var t: Dictionary = data().home_death
	var extra := {"victim": first, "cause": cause}
	var kind := "other"
	if cause == "starvation":
		kind = "starvation"
	elif cause == "old age":
		kind = "old_age"
	elif cause.begins_with("slain by "):
		var killer := cause.substr(9)
		kind = "listener" if killer == listener_name(w) else "slain"
		extra.killer = killer
	return _fill(Dialogue._pick(w, n, t[kind], 9), w, n, o, extra)


# ---------------------------------------------------------------- S2: re-voicing the village record
## The names in a record line the speaker would say otherwise: [{s, kind (you | i | we | kin), phrase}], longest first.
## Only names that belong to one person (or one household) are listed: a shared name is left alone.
static func mentions(w: World, n: NPC) -> Array:
	var out := []
	var you := listener_name(w)
	if _count_named(w, you) == 1:
		out.append({"s": you, "kind": "you"})
	var me := _full(n)
	if me != you and _count_named(w, me) == 1:
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
		if o == n or relation(w, n, o) == "":
			continue
		var full := _full(o)
		if full != you and full != me and _count_named(w, full) == 1:
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
