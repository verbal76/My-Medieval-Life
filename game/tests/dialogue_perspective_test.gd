extends SceneTree
## Dialogue perspective (REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS steps S1 and S2; owner directive
## docs/directives/2026-10-24_master_gameplay_repair_dialogue_crime_guards.md, open items 01 and 02). The owner's reported
## cases rebuilt from procedural households (no family is named in the code):
##   the Dale witness: a relative who saw the player kill a child speaks to the player as the killer, "you" and "I saw";
##   one who only learned of it says "heard"/"they say"; one who knows nothing says nothing of it;
##   the Lambert self-reference: a household's purchase and fence, told by a member, in the first person, oldest first;
##   the Oakley child: the chapel's food and the mother's missing axe, told by her child as "us" and "Mum".
## Run headless:
##   godot --headless --path game --script res://tests/dialogue_perspective_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	test_witness(true)
	test_witness(false)
	test_guest_listener()
	test_stance()
	print("dialogue_perspective_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(judgment: bool) -> World:
	JudgmentLive.test_disabled = not judgment
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	JudgmentLive.test_disabled = false
	return w


func _open(w: World, c: Vector2i) -> bool:
	return not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == ""


## An open outdoor spot with room around it.
func _spot(w: World) -> Vector2:
	for y in range(60, 120):
		for x in range(60, 160):
			if _open(w, Vector2i(x, y)) and _open(w, Vector2i(x + 1, y)) and _open(w, Vector2i(x, y + 2)):
				return Vector2(x + 0.5, y + 0.5)
	return Vector2(116.5, 86.5)


## A child, and an adult or elder of the same household who is not a guard.
func _child_and_relative(w: World) -> Array:
	for c: NPC in w.npcs:
		if not c.alive or c.role != "child" or c.household < 0:
			continue
		for e: NPC in w.npcs:
			if e.alive and e != c and e.role in ["elder", "adult"] and e.household == c.household and e.job != "guard":
				return [c, e]
	return []


## The player kills `child` at `at` with `watcher` 2 tiles off; everyone else is moved far away.
func _kill_before(w: World, child: NPC, watcher: NPC, keep := []) -> void:
	var at := _spot(w)
	for n: NPC in w.npcs:
		if n != child and n != watcher and not keep.has(n) and n.alive and n.pos.distance_to(at) < 14.0:
			n.pos = at + Vector2(40, 40)
	w.player.pos = at
	child.pos = at + Vector2(0.8, 0)
	watcher.pos = at + Vector2(0, 2.0)
	for o: NPC in [child, watcher]:
		o.plan.clear()
		o.anim = "idle"
	var h := w.player_hit_npc(child, 999.0)
	check(h.killed, "the child is killed")


func _all(w: World, n: NPC) -> String:
	return " | ".join([Dialogue.opening(w, n), Dialogue.brush_off(w, n), Dialogue.home(w, n)])


# ---------------------------------------------------------------- S1: the Dale witness
func test_witness(judgment: bool) -> void:
	var tag := "judgment on" if judgment else "judgment off"
	var w := _world(judgment)
	check((w.judgment != null) == judgment, "%s: the world is set up as asked" % tag)
	var pair := _child_and_relative(w)
	var child: NPC = pair[0]
	var elder: NPC = pair[1]
	# another member of the household, far away: learns of the death as family, does not see it
	var away: NPC = null
	for m in w.households[child.household].members:
		var o := w.npc(m)
		if o and o.alive and o != child and o != elder and o.role != "child" and o.job != "guard":
			away = o
			break
	# a villager of another household who sees nothing
	var stranger: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household != child.household and o.family != child.family and o.job != "guard":
			stranger = o
			break
	_kill_before(w, child, elder)
	var you := "%s %s" % [w.player.name, w.player.family]
	var open := Dialogue.opening(w, elder)
	print("     %s witness %s (%s) to the killer: %s" % [tag, Dialogue.full_name(elder), elder.role, open])
	check(open.begins_with("You ") or open.contains(" you "), "%s: the witness speaks to the killer as \"you\"" % tag)
	check(open.contains("I saw") or open.contains("I was there") or open.contains("I saw you"), "%s: and says they saw it" % tag)
	check(open.contains("kill") or open.contains("murder"), "%s: and that it was a killing" % tag)
	check(open.contains(child.name), "%s: and names the child as they know her (%s)" % [tag, child.name])
	check(not open.contains("don't know you") and not open.contains("stranger") and not open.contains(you), "%s: not greeted as a stranger, nor named in the third person" % tag)
	var brush := Dialogue.brush_off(w, elder)
	print("     %s witness, busy: %s" % [tag, brush])
	check(not brush.contains("Don't know you") and not brush.contains("stranger") and not brush.contains("Who are you"), "%s: a busy witness does not brush the killer off as a stranger" % tag)
	var home := Dialogue.home(w, elder)
	print("     %s witness at home: %s" % [tag, home])
	check(home.contains(child.name) and not home.contains("slain by") and not home.contains(you), "%s: home names the child from the family's side, without the record's cause text" % tag)
	check(home.contains("you") or home.contains("your"), "%s: and holds the listener to it" % tag)
	if away != null:
		away.pos = elder.pos + Vector2(60, 0)
		var heard := Dialogue.opening(w, away)
		print("     %s household member who was not there: %s" % [tag, heard])
		check(not heard.contains("I saw") and (heard.contains("heard") or heard.contains("say")), "%s: a relative who was not there says they heard, not saw" % tag)
	if stranger != null:
		var none := _all(w, stranger)
		check(not none.contains(child.name) and not none.contains("kill"), "%s: a villager who saw and learned nothing says nothing of it" % tag)
	w.dispose()


# ---------------------------------------------------------------- S1: the listener is the acting player
func test_guest_listener() -> void:
	var w := _world(true)
	var host := w.player
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Fairlight"
	Identity.register_player(w, g)
	w.give_start_kit(g)
	w.add_guest(g)
	var pair := _child_and_relative(w)
	var child: NPC = pair[0]
	var elder: NPC = pair[1]
	var at := _spot(w)
	for n: NPC in w.npcs:
		if n != child and n != elder and n.alive and n.pos.distance_to(at) < 14.0:
			n.pos = at + Vector2(40, 40)
	g.pos = at
	host.pos = at + Vector2(30, 0)
	child.pos = at + Vector2(0.8, 0)
	elder.pos = at + Vector2(0, 2.0)
	child.plan.clear()
	elder.plan.clear()
	var h: Dictionary = w.player_hit_npc(child, 999.0, g)
	check(h.killed, "the guest kills the child")
	var to_guest: String = w.as_actor(g, func(): return Dialogue.opening(w, elder))
	var to_host := Dialogue.opening(w, elder)
	print("     witness to the guest: %s" % to_guest)
	print("     witness to the host:  %s" % to_host)
	check(to_guest.contains("I saw") and to_guest.contains(child.name), "the witness accuses the guest who did it")
	check(not to_host.contains("kill") and not to_host.contains("murder"), "and not the host, who was elsewhere")
	w.dispose()


# ---------------------------------------------------------------- S1: knowledge, relation, personality
func test_stance() -> void:
	var w := _world(true)
	var V = load("res://scripts/ui/dialogue_voice.gd")
	check(V != null, "the perspective reader exists")
	if V == null:
		w.dispose()
		return
	var pair := _child_and_relative(w)
	var child: NPC = pair[0]
	var elder: NPC = pair[1]
	# a child of another household watches too
	var kid: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "child" and o.household != child.household:
			kid = o
			break
	_kill_before(w, child, elder, [kid])
	kid.pos = elder.pos + Vector2(1, 0)
	var k: Dictionary = V.violence(w, kid)
	check(k.is_empty(), "a child placed there after the killing knows nothing of it")
	var ke: Dictionary = V.violence(w, elder)
	check(str(ke.get("crime", "")) == "killing" and str(ke.get("how", "")) == "saw" and ke.get("victim") == child, "the witness knows it was a killing, saw it, and of whom")
	# the same knowledge in a child's mouth is fear, not a confrontation
	check(V.stance(w, kid, {"crime": "killing", "how": "saw", "victim": child, "rel": ""}) == "afraid", "a child who saw a stranger's killing is afraid")
	var s: String = V.stance(w, elder, ke)
	check(s in ["confront", "afraid", "guarded"], "the witness's stance comes from their relation, role, health and temperament: %s" % s)
	w.dispose()
