extends SceneTree
## Dialogue perspective (REPAIR_AUDIT_DIALOGUE_CRIME_GUARDS steps S1 and S2; owner directive
## docs/directives/2026-10-24_master_gameplay_repair_dialogue_crime_guards.md, open items 01 and 02). The owner's reported
## cases rebuilt from procedural households (no family is named in the code):
##   the Dale witness: a relative who saw the player kill a child speaks to the player as the killer, "you" and "I saw";
##   one who only learned of it says "heard"/"they say"; one who knows nothing says nothing of it;
##   A4: news is what the speaker knows (seen, taken part in, told, rumoured), never the village record: the killing
##   told to the killer as "you", framed by how the speaker knows it ("I saw it myself", "<teller> told me", "they say");
##   a villager who learned nothing has no news; with judgment off, the villager's own memories only.
##   A5: village news as facts that travel by knowledge: the Lambert purchase (bought through Property.buy) told by a
##   member as "our family" and unknown to a stranger until told; the Oakley child's chapel food and Mum's missing axe;
##   the household learns of a death but not the killer; news is never judged and keeps out of the moral memory.
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
	test_news_from_knowledge(true)
	test_news_from_knowledge(false)
	test_lambert_facts()
	test_oakley_facts()
	test_news_not_judged()
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
	if away != null:
		away.pos = Vector2(5.5, 5.5)             # out of sight and out of earshot of the hue and cry
	if stranger != null:
		stranger.pos = Vector2(8.5, 5.5)
	_kill_before(w, child, elder, [away, stranger])
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
		var away_home := Dialogue.home(w, away)
		print("     %s household member who was not there: %s | home: %s" % [tag, heard, away_home])
		# A5 (REPAIR_AUDIT D2): the household learns of the death, not who did it, until told or seeing it
		check(not heard.contains("kill") and not heard.contains("murder"), "%s: a relative who was not there does not know who killed her" % tag)
		check(away_home.contains(child.name) and not away_home.contains("you"), "%s: but knows she died, and does not blame the listener" % tag)
		if judgment:
			var ev := -1
			for e in w.judgment.memories.get(elder.id, {}):
				if str(w.judgment.belief(elder.id, int(e)).type) == "killing":
					ev = int(e)
			w.judgment.learn(away.id, ev, "told", elder.id, 1, 900, w.judgment.belief(elder.id, ev).actors)
			heard = Dialogue.opening(w, away)
			print("     %s told by the witness: %s" % [tag, heard])
			check(not heard.contains("I saw") and (heard.contains("heard") or heard.contains("say")), "%s: told by the witness, a relative who was not there says they heard, not saw" % tag)
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
	var V = load("res://scripts/core/event_talk.gd")
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


# ---------------------------------------------------------------- A4: news from what the speaker knows
func test_news_from_knowledge(judgment: bool) -> void:
	var tag := "judgment on" if judgment else "judgment off"
	var w := _world(judgment)
	var pair := _child_and_relative(w)
	var child: NPC = pair[0]
	var elder: NPC = pair[1]
	var stranger: NPC = null
	var friend: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household != child.household and o.job != "guard" and EventTalk.relation(w, o, child) == "":
			if stranger == null:
				stranger = o
			elif friend == null:
				friend = o
				break
	stranger.pos = Vector2(10.5, 10.5)
	friend.pos = Vector2(12.5, 10.5)
	_kill_before(w, child, elder)
	var you := "%s %s" % [w.player.name, w.player.family]
	w.note("The %s household bought the farmland south-west of the market from the manor for 11 coins." % w.households[stranger.household].family)
	var said := Dialogue.news(w, elder)
	print("     %s news, the witness to the killer: %s" % [tag, said])
	check(said.contains("you killed") or said.contains("You killed"), "%s: the witness tells the killer \"you killed\"" % tag)
	check(said.contains(child.name) and not said.contains(you), "%s: names the child as family do, never the listener in the third person" % tag)
	check(said.contains("I saw") or said.contains("I was there"), "%s: and says they saw it" % tag)
	check(not said.contains("attacked"), "%s: the blow that killed is not told again beside the killing" % tag)
	var none := Dialogue.news(w, stranger)
	print("     %s news, a villager who knows nothing: %s" % [tag, none])
	check(not none.contains(child.name) and not none.contains("bought") and not none.contains("kill"), "%s: a villager who learned nothing has no news: the village record is not theirs" % tag)
	if judgment:
		var ev := -1
		for e in w.judgment.memories.get(elder.id, {}):
			if str(w.judgment.belief(elder.id, int(e)).type) == "killing":
				ev = int(e)
		check(ev > 0, "the witness holds the killing as a memory")
		var actors: Array = w.judgment.belief(elder.id, ev).actors
		w.judgment.learn(stranger.id, ev, "told", elder.id, 1, 900, actors)
		var told := Dialogue.news(w, stranger)
		print("     told by the witness: %s" % told)
		check((told.contains(elder.name) and (told.contains("told me") or told.contains("had it from"))) and told.contains("you killed"), "told by the witness, they say who told them, and that the listener did it")
		w.judgment.learn(friend.id, ev, "rumour", stranger.id, 2, 600, actors)
		var heard := Dialogue.news(w, friend)
		print("     a rumour: %s" % heard)
		check(heard.begins_with("They say") or heard.begins_with("I heard"), "further along it is a rumour: \"they say\", \"I heard\"")
	w.dispose()




# ---------------------------------------------------------------- A5: the Lambert purchase, as a fact
## A household whose surname no other household has, with an adult and another member; and an adult of another household.
func _household(w: World) -> Array:
	for i in w.households.size():
		var fam: String = w.households[i].family
		if w.households.filter(func(o): return o.family == fam).size() != 1:
			continue
		var adult: NPC = null
		var other: NPC = null
		for m in w.households[i].members:
			var o := w.npc(m)
			if o == null or not o.alive:
				continue
			if adult == null and o.role == "adult" and o.job != "guard":
				adult = o
			elif other == null and o.role != "child":
				other = o
		if adult != null and other != null:
			return [i, adult, other]
	return []


func test_lambert_facts() -> void:
	var w := _world(true)
	var hs := _household(w)
	var h: int = hs[0]
	var adult: NPC = hs[1]
	var member: NPC = hs[2]
	var fam: String = w.households[h].family
	var outsider: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household != h and o.job != "guard":
			outsider = o
			break
	outsider.pos = Vector2(5.5, 5.5)
	var parcel: Dictionary = {}
	for r in w.property.market():
		if w.property.is_parcel(r) and w.property.building_on(r).is_empty():
			parcel = r
			break
	check(not parcel.is_empty(), "a parcel the manor sells")
	adult.coins += w.property.price_of(parcel) + 5
	var price := w.property.price_of(parcel)
	var why := w.property.buy(parcel, "hh:%d" % h)
	check(why == "", "the household buys it through the land office (%s)" % why)
	JudgmentLive.on_news(w, "fenced", "hh:%d" % h, ["place:" + str(parcel.id)], JudgmentLive.at_of(w, "hh:%d" % h))
	var said := Dialogue.news(w, member)
	print("     %s, a member: %s" % [Dialogue.full_name(member), said])
	check(said.contains("Our family bought") or said.contains("We bought"), "a member says \"our family\" or \"we\" bought it")
	check(not said.contains("%s household" % fam) and not said.contains("the %ss" % fam), "never their own household as a third party")
	check(said.contains("%d coins" % price) and said.contains(w.property.describe(parcel)), "the price and the place are kept")
	var none := Dialogue.news(w, outsider)
	check(not none.contains("bought"), "an outsider who saw nothing and was told nothing does not know of it (%s)" % none)
	var ev := -1
	for e in w.judgment.memories.get(member.id, {}):
		if str(w.judgment.belief(member.id, int(e)).type) == "land_bought":
			ev = int(e)
	w.judgment.learn(outsider.id, ev, "told", member.id, 1, 900, w.judgment.belief(member.id, ev).actors)
	var told := Dialogue.news(w, outsider)
	print("     %s, an outsider told of it: %s" % [Dialogue.full_name(outsider), told])
	check(told.contains("the %ss bought" % fam) or told.contains("The %ss bought" % fam), "told of it, an outsider names the household: \"the %ss\"" % fam)
	w.dispose()


# ---------------------------------------------------------------- A5: the Oakley child, as facts
func test_oakley_facts() -> void:
	var w := _world(true)
	var kid: NPC = null
	var mum: NPC = null
	for c: NPC in w.npcs:
		if c.alive and c.role == "child" and c.mother >= 0:
			var m := w.npc(c.mother)
			if m != null and m.alive and m.household == c.household:
				kid = c
				mum = m
				break
	check(kid != null, "a child living with their mother")
	JudgmentLive.on_news(w, "relief", "hhid:%d" % kid.household, ["giver:chapel"], null)
	JudgmentLive.on_news(w, "no_tool", "npc:%d" % mum.id, ["item:axe"], null)
	var said := Dialogue.news(w, kid)
	print("     %s (child): %s" % [Dialogue.full_name(kid), said])
	check(said.contains("church gave us food"), "the child says the church gave \"us\" food")
	check(said.contains("Mum has no axe"), "and calls their mother \"Mum\"")
	check(not said.contains("%s %s" % [mum.name, mum.family]) and not said.contains("household"), "never their own family as strangers")
	var stranger: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household != kid.household:
			stranger = o
			break
	check(not Dialogue.news(w, stranger).contains("axe"), "a villager of another household was not told: they do not know")
	w.dispose()


# ---------------------------------------------------------------- A5: news is known and told, never judged
func test_news_not_judged() -> void:
	var w := _world(true)
	var hs := _household(w)
	var h: int = hs[0]
	var member: NPC = hs[2]
	var j: JudgmentStore = w.judgment
	var ledger0 := JSON.stringify(j.to_dict().ledgers)
	var ord0 := j.ordinary_count(member.id)
	var next0 := j.next_event
	for k in 20:
		JudgmentLive.on_news(w, "relief", "hhid:%d" % h, ["giver:manor"], null)
	check(JSON.stringify(j.to_dict().ledgers) == ledger0, "news moves no ledger (Q01: NEUTRAL)")
	check(j.ordinary_count(member.id) == ord0, "and takes no room among the moral memories")
	check(j.next_event == next0 and j.next_news > JudgmentStore.NEWS_BASE, "news has ids of its own: the moral events' ids are untouched")
	var news := (j.memories.get(member.id, {}) as Dictionary).keys().filter(func(e): return int(e) >= JudgmentStore.NEWS_BASE).size()
	check(news <= int(j.c("memory").news_capacity), "a person holds at most news_capacity news (%d)" % news)
	# a death: the household knows, a stranger far off does not
	var victim: NPC = w.npc(int(w.households[h].members[0]))
	var far: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.household != h and o.role == "adult" and EventTalk.relation(w, o, victim) == "":
			far = o
			break
	far.pos = victim.pos + Vector2(80, 0)
	w.kill(victim, "starvation")
	var knows_death := func(o: NPC) -> bool:
		return EventTalk.events(w, o).any(func(it): return str(it.type) == "death" and (it.victims as Array).has(victim))
	check(knows_death.call(member), "the household learns of the death")
	check(not knows_death.call(far), "a villager far off, of another household, does not")
	w.dispose()
