class_name EventTalk
extends RefCounted
## What a villager knows of the listener, for what they say (REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS step S1; the audit's
## knowledge reader, D1, starts here). Read only: nothing here changes the world. It answers in words and people, never
## in numbers: the wording is DialogueVoice's (ui), which never reads the judgment store itself (SJD-Q10: attitudes show
## through dialogue and behaviour, the numbers stay in developer diagnostics).
##
## The speaker is the villager `n`; the listener is the acting player, World.player (World.as_actor makes it a guest
## for a guest's verbs and talk). What the speaker knows of the listener comes from the records that exist:
##   - the speaker's memory (NPC.memory), keyed by the listener's name: "saw <listener> attack <victim>" (a witness,
##     World.player_assault), "<victim> died (slain by <listener>)" (the household, World.kill);
##   - the judgment store (when attached), whose beliefs carry how they were learned (witnessed, told, rumour). Its
##     records name every player as Life.PLAYER_ID until multiplayer Batch C; A8: a player's fact carries the tag
##     "by:<player ref>", so it names the right player (a guest's deed is never pinned on the host, nor the host's on a
##     guest); an untagged fact (an older save) names the player only while one is in play.
## Nobody knows what they did not see or learn: a villager with none of these records says nothing of it.

const CLOSE := ["parent", "child", "partner", "sibling", "grandchild", "grandparent"]


## "Wat Ashdown": the listener, as the village names them in its record and its memories.
static func listener_name(w: World) -> String:
	return "%s %s" % [w.player.name, w.player.family]


## Whether a record that names "the player" (Life.PLAYER_ID) names this listener: only while one player is in play.
static func player_id_is_listener(w: World) -> bool:
	return w.players.size() == 1 and w.is_acting_ref(Life.PLAYER_ID)


static func full(o) -> String:
	return "%s %s" % [o.name, o.family]


## How many people (villagers alive or dead, and players) answer to this full name.
static func count_named(w: World, full: String) -> int:
	var k := 0
	for o: NPC in w.npcs:
		if full(o) == full:
			k += 1
	for p in w.players.values():
		if full(p) == full:
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


## The person of this full name the speaker most likely means: their own relative first, then the lowest id.
static func _person(w: World, n: NPC, full: String) -> NPC:
	var best: NPC = null
	for o: NPC in w.npcs:
		if full(o) != full:
			continue
		if relation(w, n, o) != "":
			return o
		if best == null:
			best = o
	return best


## The dead person a household memory "<first> died (...)" is about: of the speaker's household or family.
static func dead_named(w: World, n: NPC, first: String) -> NPC:
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
	var kill_prefix := "saw %s kill " % you
	var slain := " died (slain by %s)" % you
	for m in n.memory:
		var s := str(m)
		if s.begins_with(saw_prefix):
			_know(known, _person(w, n, s.substr(saw_prefix.length())), "assault", "saw", n)
		elif s.begins_with(kill_prefix):
			_know(known, _person(w, n, s.substr(kill_prefix.length())), "killing", "saw", n)
		elif s.ends_with(slain):
			_know(known, dead_named(w, n, s.substr(0, s.length() - slain.length())), "killing", "heard", n)
	if w.judgment != null:
		var mem: Dictionary = w.judgment.memories.get(n.id, {})
		var evs := mem.keys()
		evs.sort()
		for ev in evs:
			var b: Dictionary = w.judgment.belief(n.id, int(ev))
			if b.is_empty() or not str(b.type) in ["killing", "assault"]:
				continue
			var f: Dictionary = w.judgment.fact(int(ev))
			if f.is_empty() or (f.victims as Array).is_empty():
				continue
			var tags := _tags(f.tags)
			var named := false
			for a in b.actors:
				named = named or (Life.is_player_id(int(a[0])) and person_of_id(w, int(a[0]), tags) == w.player)
			if not named:
				continue                         # A8: the speaker believes someone else did it (another player, by its tag)
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
	if w.judgment == null:
		return false
	for ev in w.judgment.memories.get(n.id, {}):
		var b: Dictionary = w.judgment.belief(n.id, int(ev))
		if not b.is_empty() and str(b.type) == "killing":
			var f: Dictionary = w.judgment.fact(int(ev))
			if not f.is_empty() and (f.victims as Array).has(o.id) and (b.actors as Array).any(func(a): return person_of_id(w, int(a[0]), _tags(f.tags)) == w.player):
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


# ---------------------------------------------------------------- A4: what the speaker knows, and how
## GP-DIALOGUE A4 (REPAIR_AUDIT D1): every event the speaker `n` holds a memory of, with how they came to know it. With
## judgment attached this is the speaker's judgment memories (JudgmentStore.memories: belief and fact, source, teller);
## without it, the villager's own memory strings (NPC.memory), which is all the Build 18 path has. Nobody is told
## anything here: a villager who learned nothing knows nothing (the omniscient village record is not read).
##
## Each item: {key, type, how: "saw" | "part" (took part: the victim, the beneficiary, the household) | "told" (by `teller`)
## | "rumour" (further along), teller: NPC or null, actors, victims, benef: [person], hh: the household an event is about
## (-1 none), tags: {place, price, item, cause, by, rent}, day, sev, perm, ev (the fact id, -1 from memory)}. A person is
## an NPC, a PlayerState, or null (unknown or gone).
static func events(w: World, n: NPC) -> Array:
	var out := []
	if w.judgment != null:
		var mem: Dictionary = w.judgment.memories.get(n.id, {})
		var evs := mem.keys()
		evs.sort()
		for ev in evs:
			var b: Dictionary = w.judgment.belief(n.id, int(ev))
			var f: Dictionary = w.judgment.fact(int(ev))
			if b.is_empty() or f.is_empty() or str(b.type) == "meeting":
				continue
			var tags := _tags(f.tags)
			var how: String = {"participant": "part", "witnessed": "saw", "told": "told", "rumour": "rumour"}.get(str(b.src), "rumour")
			var it := {"key": "ev:%d" % int(ev), "ev": int(ev), "type": str(b.type), "how": how,
				"teller": w.npc(int(b.by)) if int(b.by) >= 0 else null, "day": int(f.day), "tags": tags,
				"actors": (b.actors as Array).map(func(a): return person_of_id(w, int(a[0]), tags)),
				"victims": (f.victims as Array).map(func(v): return person_of_id(w, int(v), tags)),
				"benef": (f.beneficiaries as Array).map(func(v): return person_of_id(w, int(v), tags)),
				"hh": int(tags.get("hh", -1)), "sev": int(w.judgment.definition(str(b.type)).get("severity", 0)), "perm": bool(b.permanent)}
			if tags.has("place"):
				it.place = place_words(w, str(tags.place))
			out.append(it)
	# the villager's own memory strings are knowledge too (the hue and cry, a killing seen): kept when no judgment
	# memory tells the same event (the same kind, of the same victim), the surer way of knowing winning
	for it in _from_memory(w, n):
		var dup := -1
		for i in out.size():
			if str(out[i].type) == str(it.type) and _same(out[i].victims, it.victims):
				dup = i
				break
		if dup < 0:
			out.append(it)
		elif HOW.find(str(it.how)) < HOW.find(str(out[dup].how)):
			out[dup].how = it.how
	return out


## A fact's tags as a dictionary: "place:<id>", "price:<n>", "hh:<index>", "item:<id>", "cause:<kind>", "by:<player ref>".
static func _tags(tags: Array) -> Dictionary:
	var o := {}
	for t in tags:
		var s := str(t)
		var i := s.find(":")
		if i > 0:
			o[s.substr(0, i)] = s.substr(i + 1)
	return o


## The person a fact names: a villager by id; Life.PLAYER_ID is the player the fact's "by" tag names (multiplayer: the
## right player), else, with one player in play, that player; else null (a player the speaker cannot tell apart).
static func person_of_id(w: World, id: int, tags: Dictionary):
	if Life.is_player_id(id):
		if tags.has("by"):
			return w.player_of_ref(str(tags.by))
		return w.host_player() if w.players.size() == 1 else null
	return w.npc(id)


## The Build 18 path (judgment off): what the villager's own memory strings say, and nothing more.
static func _from_memory(w: World, n: NPC) -> Array:
	var out := []
	for i in n.memory.size():
		var s := str(n.memory[i])
		var it := {}
		if s.begins_with("saw ") and s.contains(" kill ") and not s.contains(" killed "):
			var who = _named(w, s.substr(4, s.find(" kill ") - 4))
			var vic := _person_named(w, n, s.substr(s.find(" kill ") + 6))
			if who != null and vic != null:
				it = {"type": "killing", "how": "saw", "actors": [who], "victims": [vic], "benef": []}
		elif s.begins_with("saw ") and s.contains(" attack "):
			var who = _named(w, s.substr(4, s.find(" attack ") - 4))
			var vic := _person_named(w, n, s.substr(s.find(" attack ") + 8))
			if who != null and vic != null:
				it = {"type": "assault", "how": "saw", "actors": [who], "victims": [vic], "benef": []}
		elif s.ends_with(")") and s.contains(" died ("):
			var dead := dead_named(w, n, s.substr(0, s.find(" died (")))
			if dead != null:
				it = {"type": "death", "how": "part", "actors": [], "victims": [dead], "benef": [], "tags": {"cause": _cause_kind(s.substr(s.find(" died (") + 7).trim_suffix(")"))}}
		elif s.begins_with("heard the hue and cry: ") or s.begins_with("heard the alarm bell: "):
			var rest := s.substr(s.find(": ") + 2)
			for verb in [" killed ", " attacked "]:
				if rest.contains(verb):
					var who = _named(w, rest.substr(0, rest.find(verb)))
					var vic := _person_named(w, n, rest.substr(rest.find(verb) + verb.length()))
					if vic != null:
						it = {"type": "killing" if verb == " killed " else "assault", "how": "rumour", "actors": [who] if who != null else [], "victims": [vic], "benef": []}
					break
		if not it.is_empty():
			it.merge({"key": "mem:%d" % i, "ev": -1, "teller": null, "day": w.day(), "tags": it.get("tags", {}), "hh": -1, "sev": 0, "perm": true})
			out.append(it)
	return out


## A player or villager by full name ("Wat Ashdown"), the players first; null for none.
static func _named(w: World, full_name: String):
	for p in w.players.values():
		if full(p) == full_name:
			return p
	for o: NPC in w.npcs:
		if full(o) == full_name:
			return o
	return null


static func _person_named(w: World, n: NPC, full_name: String) -> NPC:
	return _person(w, n, full_name)


## "slain" | "starvation" | "old_age" | "other": how someone died, never who did it.
static func _cause_kind(cause: String) -> String:
	if cause.begins_with("slain"):
		return "slain"
	if cause == "starvation":
		return "starvation"
	if cause == "old age":
		return "old_age"
	return "other"


## What the person is to the speaker, for the wording: "you" (the listener: compared as the player, never by name), "i",
## "kin" (with `rel`), "household", "player" (another player), "npc", or "none".
static func role_of(w: World, n: NPC, who) -> Dictionary:
	if who == null:
		return {"kind": "none"}
	if who is PlayerState:
		return {"kind": "you"} if who == w.player else {"kind": "player", "who": who}
	var o: NPC = who
	if o == n:
		return {"kind": "i"}
	var rel := relation(w, n, o)
	if rel == "household":
		return {"kind": "household", "who": o, "rel": rel}
	if rel != "":
		return {"kind": "kin", "who": o, "rel": rel}
	return {"kind": "npc", "who": o}


## Whether the listener (the acting player) is one of the people an event item names.
static func listener_in(w: World, it: Dictionary) -> bool:
	for k in ["actors", "victims", "benef"]:
		for p in it.get(k, []):
			if p is PlayerState and p == w.player:
				return true
	return false


## Whether the speaker, their household or their kin is one of the people an event item names (or the household it is about).
static func ours(w: World, n: NPC, it: Dictionary) -> bool:
	if int(it.get("hh", -1)) >= 0 and int(it.hh) == n.household:
		return true
	for k in ["actors", "victims", "benef"]:
		for p in it.get(k, []):
			if p is NPC and (p == n or relation(w, n, p) != ""):
				return true
	return false


## How much an event matters to the speaker talking to this listener (lower first; the directive's conversation
## priorities): 0 it involves the listener and the speaker or their people; 1 a serious harm to the speaker or their
## people (severity 2000 or more, a death); 2 it involves the listener; 3 the speaker's own people or household; 4 news of
## anyone else.
static func news_tier(w: World, n: NPC, it: Dictionary) -> int:
	var li := listener_in(w, it)
	var ou := ours(w, n, it)
	var serious := int(it.get("sev", 0)) >= 2000 or str(it.type) in ["killing", "death"]
	if li and ou:
		return 0
	if ou and serious:
		return 1
	if li:
		return 2
	if ou:
		return 3
	return 4


## The `k` events the speaker would tell first (news_tier, then the newest), with what another event already tells
## left out: an attack whose victim the same hand killed, as the speaker knows it.
static func news_items(w: World, n: NPC, k: int) -> Array:
	return news_candidates(w, n).slice(0, k)


## Every event the speaker could tell, gravest for them first, with what another tells left out (see news_items).
static func news_candidates(w: World, n: NPC) -> Array:
	var all := events(w, n)
	var keep := []
	for it in all:
		if str(it.type) in ["meeting"]:
			continue
		var kl := _killed_too(all, it) if str(it.type) in ["assault", "death"] else {}
		if not kl.is_empty():
			if HOW.find(str(it.how)) < HOW.find(str(kl.how)):
				kl.how = it.how                    # the attack seen tells how the speaker knows the killing it led to
				kl.teller = it.teller
			continue
		keep.append(it)
	keep.sort_custom(func(a, b):
		var ta := news_tier(w, n, a)
		var tb := news_tier(w, n, b)
		if ta != tb:
			return ta < tb
		if int(a.day) != int(b.day):
			return int(a.day) > int(b.day)
		if int(a.ev) != int(b.ev):
			return int(a.ev) > int(b.ev)
		return str(a.key) > str(b.key))
	return keep


const HOW := ["saw", "part", "told", "rumour"]     # how surely one knows, surest first


## The killing in `all` of the same victim as attack `a` (by the same hand) or death `a`, or {}: the killing tells it.
static func _killed_too(all: Array, a: Dictionary) -> Dictionary:
	for it in all:
		if str(it.type) == "killing" and _same(it.get("victims", []), a.get("victims", [])) and (str(a.type) == "death" or _same(it.get("actors", []), a.get("actors", [])) or (it.get("actors", []) as Array).is_empty()):
			return it
	return {}


static func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true


## A parcel or building as the village names it today ("the farmland south-west of the market"), by its id.
static func place_words(w: World, id: String) -> String:
	var thing: Dictionary = w.plot(id)
	if thing.is_empty():
		thing = w.buildings.get(id, {})
	return w.property.describe(thing) if not thing.is_empty() else "some land"


## Who the speaker believes killed `victim` (a killing they know of: seen, told, rumoured), or null when they do not know.
static func killer_of(w: World, n: NPC, victim: NPC) -> Variant:
	for it in events(w, n):
		var seen_fall: bool = str(it.type) == "assault" and str(it.how) == "saw" and not victim.alive
		if (str(it.type) == "killing" or seen_fall) and (it.victims as Array).has(victim) and not (it.actors as Array).is_empty():
			return it.actors[0]
	return null



# ---------------------------------------------------------------- A6: related events as one, priority, what was said
static var _rules: Array = []


## The merge rules (game/data/dialogue_events.json "merge"): which related events are told as one (REPAIR_AUDIT D3).
static func rules() -> Array:
	if _rules.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue_events.json"))
		_rules = (d.merge.rules as Array) if d is Dictionary else []
	return _rules


static func _field(it: Dictionary, f: String) -> String:
	match f:
		"hh":
			return str(it.get("hh", -1))
		"victim":
			return str((it.get("victims", []) as Array).map(func(p): return p.get_instance_id() if p != null else 0))
	return str((it.get("tags", {}) as Dictionary).get(f, ""))


static func _same_by(a: Dictionary, b: Dictionary, fields: Array) -> bool:
	for f in fields:
		if _field(a, str(f)) != _field(b, str(f)) or _field(a, str(f)) in ["", "-1"]:
			return false
	return true


## The events as the speaker would tell them (REPAIR_AUDIT D3, D5): each rule's related events joined into one group (in
## the order they happened), the rest alone; each group {rule (the rule's id, "" alone), items (oldest first), times,
## tier (the gravest of its items, news_tier), day (the newest), keys (what it tells, for the said history)}; gravest
## first, then the newest.
static func groups(w: World, n: NPC, items: Array) -> Array:
	var used := {}
	var out := []
	for r in rules():
		var types: Array = r.types
		var fields: Array = r.get("same", [])
		var days := int(r.get("days", 7))
		if bool(r.get("count", false)):
			var buckets := {}
			for i in items.size():
				var it: Dictionary = items[i]
				if used.has(i) or str(it.type) != str(types[0]):
					continue
				var key := "|".join(fields.map(func(f): return _field(it, str(f))))
				if not buckets.has(key):
					buckets[key] = []
				buckets[key].append(i)
			var bkeys := buckets.keys()
			bkeys.sort()
			for key in bkeys:
				var idx: Array = buckets[key]
				var newest := 0
				for i in idx:
					newest = maxi(newest, int(items[i].day))
				idx = idx.filter(func(i): return newest - int(items[i].day) <= days and _same_by(items[i], items[idx[0]], fields))
				if idx.size() < 2:
					continue
				for i in idx:
					used[i] = true
				var its := idx.map(func(i): return items[i])
				its.sort_custom(func(a, b): return int(a.day) < int(b.day) or (int(a.day) == int(b.day) and int(a.ev) < int(b.ev)))
				out.append({"rule": str(r.id), "items": [its[-1]], "times": its.size(), "all": its})
			continue
		for i in items.size():
			if used.has(i) or str(items[i].type) != str(types[0]):
				continue
			for j in items.size():
				if j == i or used.has(j) or str(items[j].type) != str(types[1]):
					continue
				if not _same_by(items[i], items[j], fields) or absi(int(items[i].day) - int(items[j].day)) > days:
					continue
				used[i] = true
				used[j] = true
				out.append({"rule": str(r.id), "items": [items[i], items[j]], "times": 2, "all": [items[i], items[j]]})
				break
	for i in items.size():
		if not used.has(i):
			out.append({"rule": "", "items": [items[i]], "times": 1, "all": [items[i]]})
	for g in out:
		var tier := 9
		var day := 0
		var keys := []
		for it in g.all:
			tier = mini(tier, news_tier(w, n, it))
			day = maxi(day, int(it.day))
			keys.append(str(it.key))
		g.tier = tier
		g.day = day
		g.keys = keys
	out.sort_custom(func(a, b):
		if int(a.tier) != int(b.tier):
			return int(a.tier) < int(b.tier)
		if int(a.day) != int(b.day):
			return int(a.day) > int(b.day)
		return str(a["keys"][-1]) > str(b["keys"][-1]))
	return out


## What the speaker has already told this listener (NPC.talked, by the listener's player reference): key -> the day.
static func told(w: World, n: NPC) -> Dictionary:
	return n.talked.get(w.acting_ref(), {})


## Record that the speaker has told the listener these things today (NPC.talked; the newest TALKED_KEEP kept a listener).
## Like Dialogue.meet, the one thing talking changes: so nothing is said over and over.
const TALKED_KEEP := 40


static func mark_said(w: World, n: NPC, keys: Array) -> void:
	if keys.is_empty() or n.role == "bandit":
		return
	var ref := w.acting_ref()
	var t: Dictionary = n.talked.get(ref, {})
	for k in keys:
		t[str(k)] = w.day()
	if t.size() > TALKED_KEEP:
		var ks := t.keys()
		ks.sort_custom(func(a, b): return int(t[a]) < int(t[b]) or (int(t[a]) == int(t[b]) and str(a) < str(b)))
		for i in t.size() - TALKED_KEEP:
			t.erase(ks[i])
	n.talked[ref] = t


## Whether every key of a group was told this listener before.
static func all_said(w: World, n: NPC, keys: Array) -> bool:
	var t := told(w, n)
	for k in keys:
		if not t.has(str(k)):
			return false
	return not keys.is_empty()


## Whether a key was told this listener today.
static func said_today(w: World, n: NPC, key: String) -> bool:
	return int(told(w, n).get(key, -1)) == w.day()
