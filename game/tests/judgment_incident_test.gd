extends SceneTree
## X20-JUDG-C3 (owner, 2026-10-31, docs/directives/2026-10-31_sjdh_decisions_le05_authorization.md C3): wrongdoing is
## counted by incident. A continuous fight (blows between the same aggressor and victim with no gap longer than
## self_defence.fight_minutes, the existing X19-EVENT-Q fight window) is one assault incident however many blows it holds;
## distinct offences keep their own facts (a killing, a theft); every victim has their own incident; a robbery that took
## nothing is an attempted robbery (still wrongdoing, never a theft and never nothing); a new encounter after a genuine
## disengagement (the window passed) is a new incident; an incident under way survives a save and load.
##   godot --headless --path game --script res://tests/judgment_incident_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	test_one_fight_one_incident()
	test_distinct_offences_kept()
	test_victims_apart()
	test_attempted_robbery()
	test_new_encounter()
	test_save_keeps_incident()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func world(seed := 1) -> World:
	JudgmentLive.test_disabled = false
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func adults(w: World) -> Array:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard" and n.household >= 0)


func bandit(w: World) -> NPC:
	return w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "bandit")[0]


func facts_of(j: JudgmentStore, type: String, actor: int, victim := -999) -> Array:
	var out := []
	var ids := j.facts.keys()
	ids.sort()
	for ev in ids:
		var f := j.fact(int(ev))
		if str(f.type) != type or int((f.actors as Array)[0][0]) != actor:
			continue
		if victim != -999 and not (f.victims as Array).has(victim):
			continue
		out.append(int(ev))
	return out


## One blow as the live game strikes it (NPCBrain.fight: note_blow, then the alarm that judges it).
func blow(w: World, attacker: int, v: NPC, seen := []) -> void:
	w.judgment.note_blow(attacker, v.id)
	JudgmentLive.on_attack(w, attacker, {"seen": seen, "victim": v})


func at(j: JudgmentStore, minute: int) -> void:
	j.clock_abs = j.day * 1440 + minute


func test_one_fight_one_incident() -> void:
	var w := world()
	var j: JudgmentStore = w.judgment
	var b := bandit(w)
	var v: NPC = adults(w)[0]
	var late: NPC = adults(w)[1]
	for i in 6:
		at(j, 600 + i * 2)                           # a blow every two minutes: one continuous fight
		blow(w, b.id, v, [late] if i == 4 else [])
	var a := facts_of(j, "assault", b.id, v.id)
	check(a.size() == 1, "six blows in one continuous fight are one assault incident (%d)" % a.size())
	check(a.size() == 1 and j.belief(late.id, int(a[0])).size() > 0, "...and someone who saw only a later blow knows that same incident")
	check(int(j.stats.get("assault_blows_in_incident", 0)) == 5, "...the other five blows are counted in it (%d)" % int(j.stats.get("assault_blows_in_incident", 0)))
	check(j.contribution(v.id, int(a[0]), b.id)[1] > 0 and _bad_contribs(j, v.id, b.id) == 1,
		"...so the victim holds one assault judgment against the attacker, not six")
	w.dispose()


func _bad_contribs(j: JudgmentStore, observer: int, actor: int) -> int:
	var n := 0
	for ev in j.contrib.get(observer, {}):
		if j.has_fact(int(ev)) and str(j.fact(int(ev)).type) == "assault" and j.contribution(observer, int(ev), actor)[1] > 0:
			n += 1
	return n


func test_distinct_offences_kept() -> void:
	var w := world()
	var j: JudgmentStore = w.judgment
	var b := bandit(w)
	var ppl := adults(w)
	var v: NPC = ppl[2]
	at(j, 700)
	blow(w, b.id, v)
	JudgmentLive.on_robbery(w, b, v, 12, w.aware_of_attack(v.pos, v))
	at(j, 702)
	blow(w, b.id, v)
	JudgmentLive.on_killing(w, v, b.id)
	check(facts_of(j, "assault", b.id, v.id).size() == 1, "an assault, a robbery and a killing in one fight: one assault incident")
	check(facts_of(j, "theft", b.id, v.id).size() == 1, "...the robbery that took something is its own theft")
	check(facts_of(j, "killing", b.id, v.id).size() == 1, "...and the killing is its own, the gravest (never folded into the assault)")
	w.dispose()


func test_victims_apart() -> void:
	var w := world()
	var j: JudgmentStore = w.judgment
	var b := bandit(w)
	var ppl := adults(w)
	at(j, 800)
	blow(w, b.id, ppl[3])
	at(j, 801)
	blow(w, b.id, ppl[4])
	at(j, 802)
	blow(w, b.id, ppl[3])
	blow(w, b.id, ppl[4])
	check(facts_of(j, "assault", b.id, ppl[3].id).size() == 1 and facts_of(j, "assault", b.id, ppl[4].id).size() == 1,
		"two people struck in the same brawl: an incident for each, each victim identifiable")
	w.dispose()


func test_attempted_robbery() -> void:
	var w := world()
	var j: JudgmentStore = w.judgment
	var b := bandit(w)
	var v: NPC = adults(w)[5]
	at(j, 900)
	blow(w, b.id, v)
	JudgmentLive.on_robbery(w, b, v, 0, w.aware_of_attack(v.pos, v))
	check(facts_of(j, "theft", b.id, v.id).is_empty(), "a robbery that took nothing is not a theft")
	var att := facts_of(j, "attempted_robbery", b.id, v.id)
	check(att.size() == 1, "...it is an attempted robbery")
	check(att.size() == 1 and j.contribution(v.id, int(att[0]), b.id)[1] > 0, "...which the victim judges as wrongdoing (never consequence-free)")
	at(j, 902)
	blow(w, b.id, v)
	JudgmentLive.on_robbery(w, b, v, 0, w.aware_of_attack(v.pos, v))
	check(facts_of(j, "attempted_robbery", b.id, v.id).size() == 1, "...tried again in the same fight: the same attempt, not a second")
	w.dispose()


func test_new_encounter() -> void:
	var w := world()
	var j: JudgmentStore = w.judgment
	var b := bandit(w)
	var v: NPC = adults(w)[6]
	var gap := int(j.cfg.self_defence.fight_minutes)
	at(j, 1000)
	blow(w, b.id, v)
	at(j, 1000 + gap + 1)                         # the fight ended: no blow for longer than the window
	blow(w, b.id, v)
	check(facts_of(j, "assault", b.id, v.id).size() == 2, "a new encounter after the fight ended is a new incident")
	w.dispose()


func test_save_keeps_incident() -> void:
	var w := world()
	var j: JudgmentStore = w.judgment
	var b := bandit(w)
	var v: NPC = adults(w)[7]
	at(j, 1100)
	blow(w, b.id, v)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var j2: JudgmentStore = w2.judgment
	at(j2, 1102)
	blow(w2, b.id, w2.npc(v.id))
	check(facts_of(j2, "assault", b.id, v.id).size() == 1, "a fight under way at a save goes on as the same incident after loading")
	var old: Dictionary = JSON.parse_string(JSON.stringify(d))
	for r in old.judgment.get("fights", []):
		(r as Array).resize(5)                       # a section from before incidents: [a, b, aggressor, first, last]
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.judgment != null and w3.judgment.unread.is_empty(), "...and a save from before incidents still loads (its fights without an incident)")
	w.dispose()
	w2.dispose()
	w3.dispose()
