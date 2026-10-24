extends SceneTree
## GP-CRIME-PURSUIT step A1 (owner directive 2026-10-24, open item 03 A and D; audit J1): the authorities' case record.
##   - one case per offender, keyed by the player's reference ("player", "player:<pid>"), never the shared -2;
##   - the record (PlayerState.crimes) now holds assaults, blows at guards and killings, and notoriety is unchanged by it;
##   - tiers: theft, repeated theft, assault, murder, multiple murder, from the crimes a guard knows;
##   - a guard knows only what it saw or was told: an unseen crime is in the case, known to nobody;
##   - a fine paid settles the theft; an outstanding crime lapses after its tier's wanted days (murder never);
##   - saved and loaded; a Build 20 save (no "justice") loads with no cases; the offender's death closes the case.
## Run headless:
##   godot --headless --path game --script res://tests/justice_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	test_theft()
	test_unseen()
	test_violence()
	test_guest()
	test_save()
	test_death_and_lapse()
	print("justice_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


## An open outdoor spot away from the bandit camp; everyone else moved 60 tiles off, and nobody asleep.
func _stage(w: World, keep: Array) -> Vector2:
	for y in range(60, 120):
		for x in range(60, 160):
			var c := Vector2i(x, y)
			var ok := true
			for dx in range(-3, 4):
				ok = ok and not w.map.is_solid(c + Vector2i(dx, 0)) and w.place_of(Vector2(c + Vector2i(dx, 0)) + Vector2(0.5, 0.5)) == ""
			if not ok or Vector2(c).distance_to(Vector2(w.bandit_camp)) < 30.0:
				continue
			var at := Vector2(c) + Vector2(0.5, 0.5)
			for n: NPC in w.npcs:
				if not keep.has(n) and n.alive and n.pos.distance_to(at) < 30.0:
					n.pos = at + Vector2(0, 60) if at.y < 100 else at - Vector2(0, 60)
			for n: NPC in keep:
				n.anim = "idle"
				n.plan.clear()
				n.depth = 0
			w.player.pos = at
			return at
	return Vector2.ZERO


func _first(w: World, f: Callable, skip := []) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and not skip.has(n) and f.call(n):
			return n
	return null


func _guard(w: World, skip := []) -> NPC:
	return _first(w, func(n: NPC) -> bool: return n.job == "guard", skip)


func _adult(w: World, skip := []) -> NPC:
	return _first(w, func(n: NPC) -> bool: return n.role == "adult" and n.job != "guard", skip)


func test_theft() -> void:
	var w := _world()
	var g := _guard(w)
	var v := _adult(w)
	var at := _stage(w, [g, v])
	g.pos = at + Vector2(3, 0)
	v.pos = at + Vector2(-2, 0)
	w.player.inv.add("bread", 1)
	w.player.coins = 100
	w.witness("theft", "a loaf", v, {"bread": 1}, null)
	var c := w.justice.case_of("player")
	check(not c.is_empty() and c.crimes.size() == 1 and c.crimes[0].kind == "theft", "a theft opens the player's case, keyed \"player\"")
	check(int(c.crimes[0].rec) == w.player.crimes.size() - 1, "the case points at the player's own record entry")
	check(w.justice.known_by(g, "player") == [0] or str(c.crimes[0].settled) == "fined", "the guard who saw it knows of it")
	check(str(c.crimes[0].settled) == "fined" and w.justice.status("player") == "clear", "the fine paid settles it: nothing outstanding")
	check(not (c.last as Array).is_empty(), "the last-known place is where the guard saw the player")
	# a second theft soon after: repeated theft (the paid one counts toward the repeat)
	w.player.coins = 0
	w.player.inv.add("bread", 1)
	w.witness("theft", "a loaf", v, {"bread": 1}, null)
	check(w.justice.tier_for(g, "player") == "repeated_theft", "a second theft within the repeat days is repeated theft (%s)" % w.justice.tier_for(g, "player"))
	check(w.justice.status("player") == "pursued" or w.justice.status("player") == "wanted", "unpaid, it stays outstanding (%s)" % w.justice.status("player"))
	w.dispose()


func test_unseen() -> void:
	var w := _world()
	var g := _guard(w)
	var v := _adult(w)
	var at := _stage(w, [v])
	v.pos = at + Vector2(0, 0.6)
	v.anim = "sleep"                  # asleep: sees nothing
	v.home = ""
	w.player.inv.add("bread", 1)
	var seen := w.witness("theft", "a loaf", null, {"bread": 1}, null)
	var c := w.justice.case_of("player")
	check(seen == 0 and c.crimes.size() == 1, "an unseen theft is in the case all the same")
	check(c.known.is_empty() and w.justice.known_tier("player") == "minor" and not w.justice.knows(g, "player"), "but no guard knows of it")
	check(w.justice.status("player") == "clear", "so nobody is after the player")
	w.dispose()


func test_violence() -> void:
	var w := _world()
	var g := _guard(w)
	var a := _adult(w)
	var b := _adult(w, [a])
	var wit := _adult(w, [a, b])
	var g2 := _guard(w, [g])
	var at := _stage(w, [g, a, b, wit, g2])
	g.pos = at + Vector2(4, 0)
	a.pos = at + Vector2(0.6, 0)
	b.pos = at + Vector2(-0.6, 0)
	wit.pos = at + Vector2(0, 3)
	g2.pos = at + Vector2(0, 50)
	var notor := w.relations.notoriety()
	w.player_hit_npc(a, 1.0)
	var c := w.justice.case_of("player")
	check(w.player.crimes[-1].kind == "assault" and int(w.player.crimes[-1].witnesses) >= 2, "an assault is on the player's record, with its witnesses")
	check(w.relations.notoriety() == notor, "notoriety is unchanged by it (blows were never counted there)")
	check(w.justice.tier_for(g, "player") == "assault", "the guard who saw it acts on an assault")
	check(str(wit.report.get("ref", "")) == "player" and (wit.report.get("cis", []) as Array).has(0), "the witness's report names the player and the crime")
	check(not w.justice.knows(g2, "player"), "a guard far off knows nothing")
	w.deliver_report(wit, g2)
	check(w.justice.knows(g2, "player") and w.justice.tier_for(g2, "player") == "assault", "until told: then they know of the assault")
	# a killing in sight: murder; another: multiple murder
	w.player_hit_npc(a, 500.0)
	check(not a.alive and w.player.crimes[-1].kind == "killing", "a killing is on the record")
	check(w.justice.tier_for(g, "player") == "murder", "the guard who saw it now acts on a murder (%s)" % w.justice.tier_for(g, "player"))
	check(w.justice.tier_for(g2, "player") == "assault", "the guard told only of the blow still knows only that")
	b.pos = w.player.pos + Vector2(0.5, 0)
	w.player_hit_npc(b, 500.0)
	check(w.justice.tier_for(g, "player") == "multiple_murder", "a second killing seen: multiple murder")
	check(w.justice.score("player") == 2000 * 3 + 3000 * 2, "the severity score is the catalog's: three blows and two killings (%d)" % w.justice.score("player"))
	# a blow at a guard is its own kind
	w.player.pos = g.pos + Vector2(0.5, 0)
	w.player_hit_npc(g, 1.0)
	check(w.player.crimes[-1].kind == "guard_assault" and int(c.guard_struck) == 1, "a blow at a guard is recorded as one")
	w.dispose()


func test_guest() -> void:
	var w := _world()
	var gu := PlayerState.new()
	gu.name = "Gwen"
	gu.family = "Fairlight"
	Identity.register_player(w, gu)
	w.give_start_kit(gu)
	w.add_guest(gu)
	var g := _guard(w)
	var a := _adult(w)
	var at := _stage(w, [g, a])
	gu.pos = at
	w.player.pos = at + Vector2(0, 40)
	g.pos = at + Vector2(3, 0)
	a.pos = at + Vector2(0.6, 0)
	w.player_hit_npc(a, 1.0, gu)
	var ref := w.player_ref(gu)
	check(ref.begins_with("player:") and not w.justice.case_of(ref).is_empty(), "a guest's blow opens the guest's case (%s)" % ref)
	check(w.justice.case_of("player").is_empty() and w.player.crimes.is_empty(), "the host has no case and nothing on the record")
	check(gu.crimes.size() == 1 and gu.crimes[0].kind == "assault", "the blow is on the guest's own record")
	check(w.justice.knows(g, ref) and not w.justice.knows(g, "player"), "the guard knows it of the guest, not the host")
	w.dispose()


func test_save() -> void:
	var w := _world()
	var g := _guard(w)
	var a := _adult(w)
	var at := _stage(w, [g, a])
	g.pos = at + Vector2(3, 0)
	a.pos = at + Vector2(0.6, 0)
	w.player_hit_npc(a, 500.0)
	var before := JSON.stringify(w.justice.to_dict(), "", true)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	check(d.has("justice"), "the case is saved under \"justice\"")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(JSON.stringify(Justice._norm(JSON.parse_string(before).cases.player), "", true) == JSON.stringify(w2.justice.case_of("player"), "", true), "and loads as it was")
	check(w2.justice.tier_for(w2.npc(g.id), "player") == "murder" and w2.justice.status("player") in ["wanted", "pursued"], "the loaded case still names the murder the guard knows")
	d.erase("justice")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d)
	check(w3.load_error == "" and w3.justice.cases.is_empty() and not w3.to_dict().has("justice"), "a Build 20 save (no \"justice\") loads with no cases and saves none")
	w.dispose()
	w2.dispose()
	w3.dispose()


func test_death_and_lapse() -> void:
	var w := _world()
	var g := _guard(w)
	var a := _adult(w)
	var at := _stage(w, [g, a])
	g.pos = at + Vector2(3, 0)
	a.pos = at + Vector2(0.6, 0)
	w.player_hit_npc(a, 1.0)
	check(w.justice.status("player") != "", "an open case")
	w.damage_player(9999.0, "a test")
	check(w.justice.cases.is_empty() and w.justice.closed.size() == 1 and str(w.justice.closed[0].resolution) == "died", "the offender's death closes it (owner: the case ends)")
	# lapse: an outstanding theft past its wanted days is let go at dawn; a killing never
	var w2 := _world()
	var g2 := _guard(w2)
	var v := _adult(w2)
	var at2 := _stage(w2, [g2, v])
	g2.pos = at2 + Vector2(3, 0)
	v.pos = at2 + Vector2(-2, 0)
	w2.player.coins = 0
	w2.player.inv.add("bread", 1)
	w2.witness("theft", "a loaf", v, {"bread": 1}, null)
	var c := w2.justice.case_of("player")
	c.crimes.append({"kind": "killing", "day": 0, "t": 0.0, "victim": -1, "at": [0, 0], "seen": 1, "rec": -1, "settled": ""})
	w2.justice.learn(g2, "player", [1])
	w2.minutes += float(int(Justice.response("theft").wanted_days) + 1) * World.DAY
	w2.justice.dawn()
	check(str(c.crimes[0].settled) == "lapsed" and str(c.crimes[1].settled) == "", "a theft lapses after its wanted days; a killing does not")
	w.dispose()
	w2.dispose()
