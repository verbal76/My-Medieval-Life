extends SceneTree
## GM-01 historical memory (Expansion 20 recovery R4; World Design Rule 009's verification scenario, the owner's "30 planks"
## of docs/directives/2026-10-19_memory_refuges_politics.md Part I): a real gift toward a real house in a running World,
## kept as a historical record with its references and links, handed down three generations by the family, told by the
## grandson from the record, the family graph and the house as it stands (still the family's, sold, destroyed), saved and
## loaded, and an older save loading with none. Run headless:
##   godot --headless --path game --script res://tests/history_test.gd

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
	test_three_generations()
	test_significance()
	test_old_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func plain_cfg() -> Dictionary:
	var c := JudgmentStore.default_cfg()
	c.traits.stubborn = {"resent_penalty": 0, "switch_penalty": 0, "override_penalty": 0}
	c.bonds.reach = "none"
	c.lies.chance_permille = 0
	return c


func last_fact(j: JudgmentStore, type: String) -> int:
	var best := -1
	for ev in j.facts:
		if str(j.fact(int(ev)).type) == type and int(ev) > best:
			best = int(ev)
	return best


## A child of `parent` (a villager), born into household `h`, grown up.
func child_of(w: World, parent: NPC, h: int) -> NPC:
	var other: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.sex != parent.sex and o != parent:
			other = o
			break
	var mom: NPC = parent if parent.sex == "female" else other
	var dad: NPC = other if parent.sex == "female" else parent
	var k := Life.birth(w, mom, dad, h)
	Life._set_role(w, k, "adult")
	return k


## The family_help scene of judgment_live_test: a grown child founds a household of their own and builds a house; their
## family can spare coins. Returns {w, c, from, h, builder, plot} or {} when this village has no such family.
func building_family() -> Dictionary:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var c := w.construction
	var from := -1
	for hh in w.households:
		var h0 := int(hh.id)
		var ad: Array = w.brain._members(h0).filter(func(o: NPC) -> bool: return o.role == "adult")
		if h0 < 3 or ad.size() != 2 or ad[0].partner != ad[1].id:
			continue
		var mom: NPC = ad[0] if ad[0].sex == "female" else ad[1]
		while not c.crowded(h0):
			Life.birth(w, mom, w.npc(mom.partner), h0)
		from = h0
		break
	var child: NPC = null
	for o: NPC in w.brain._members(from):
		if o.role == "adult" and c.responsible_adult(from) != o:
			child = o
	if from < 0 or child == null:
		w.dispose()
		return {}
	var nh := {"id": w.households.size(), "family": child.family, "home": "", "members": [], "pantry": Inventory.new(),
		"founded_from": from, "founded_day": w.day()}
	w.households.append(nh)
	var h := int(nh.id)
	w.households[from].members.erase(child.id)
	child.household = h
	nh.members.append(child.id)
	var ref := World.hh_ref(h)
	var rect := c.find_ground("house", w.building_door(str(w.households[from].home)), ref)
	var p := c.place("house", rect, ref)
	w.start_site(p, "house", ref)
	nh.build = str(p.id)
	child.coins = 5
	var family: Array = w.brain._members(from)
	for o: NPC in family:
		o.coins = 0
	family[0].coins = 400
	JudgmentLive.attach(w, plain_cfg())
	return {"w": w, "c": c, "from": from, "h": h, "builder": child, "plot": p}


func test_three_generations() -> void:
	var s := building_family()
	if s.is_empty():
		check(false, "this village has a family that can found a household (history_test needs one)")
		return
	var w: World = s.w
	var j: JudgmentStore = w.judgment
	var builder: NPC = s.builder
	var p: Dictionary = s.plot
	var h := int(s.h)
	var giver: NPC = w.construction.responsible_adult(int(s.from))
	var total := w.total_coins()
	# generation 1: the gift (Construction._family_help, the live rule) and the house
	s.c._family_help(h)
	var ev := last_fact(j, "help_build")
	check(ev > 0 and builder.coins > 5 and w.total_coins() == total, "gen 1: the family gives the builder coins toward the house (%d), nothing made or lost" % (builder.coins - 5))
	var given := builder.coins - 5
	var refs := j.refs_of(ev)
	check(int(refs.household) == h and int(refs.giver_household) == int(s.from) and str(refs.plot) == str(p.id) and int(refs.qty) == given,
			"the deed names the household helped, the giving household, the plot and the amount (%s)" % JSON.stringify(refs))
	check((refs.links as Array).has(["contributed", "plot:" + str(p.id)]), "...linked: it contributed to that plot's house")
	check(j.history.has(ev), "a gift this large toward a house is significant: it is history")
	var known: Dictionary = j.history[ev].known
	check(known.has(giver.id) and known.has(builder.id) and str(known[builder.id][0]) == "participant", "giver and receiver know it firsthand")
	w._finish_site(p)
	var bid := "house_" + str(p.id)
	check(w.buildings.has(bid) and str(j.refs_of(ev).building) == bid and (j.refs_of(ev).links as Array).has(["built", "building:" + bid]),
			"the house is finished: the record now names the building it went into (%s)" % bid)
	# the fact retires with the ordinary horizon; the history does not
	j.advance_day(j.day + int(j.cfg.memory.horizon_days) + 2)
	check(not j.facts.has(ev) and not j.fact_refs.has(ev) and j.history.has(ev) and str(j.refs_of(ev).building) == bid,
			"past the memory horizon the fact retires; its historical record stays, with its references")
	# generation 2 and 3: told by the family at home, not known by anyone else
	var son := child_of(w, builder, h)
	var grandson := child_of(w, son, h)
	var stranger: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and not known.has(o.id) and o.household != h and o.household != int(s.from):
			stranger = o
			break
	check(j.tell_family_history(builder.id, son.id) == 1 and str(known[son.id][0]) == "family" and int(known[son.id][1]) == builder.id and int(known[son.id][2]) == 1,
			"gen 2: the builder tells their child the family history (told by the parent, one generation on)")
	check(j.tell_family_history(son.id, grandson.id) == 1 and int(known[grandson.id][2]) == 2, "gen 3: and the child tells theirs (two generations on)")
	check(j.tell_family_history(son.id, grandson.id) == 0, "...told once")
	# the listener: the player, a grandchild of the giver
	var bridge := child_of(w, giver, int(s.from))
	w.player.father = bridge.id
	w.player.mother = -1
	var hist := EventTalk.history(w, grandson)
	check(not hist.is_empty() and int(hist.ev) == ev and int(hist.listener_gen) == 2 and int(hist.speaker_gen) == 2 and str(hist.state) == "ours",
			"the grandson knows the record; the listener is the giver's grandchild, the builder his grandparent; the house is still theirs (%s)" % JSON.stringify(hist))
	var line := DialogueVoice.history_line(w, grandson, hist)
	print("     line: " + line)
	check(line.to_lower().contains("your grand") and line.contains("my grand") and line.contains("%d coins" % given) and line.contains(str(giver.family)),
			"the grandson's line is built from the record, the lineage and the house: the listener's grandparent, his own, the amount, the family name")
	check(stranger == null or EventTalk.history(w, stranger).is_empty(), "someone neither present nor told knows nothing of it")
	var opening := Dialogue.opening(w, grandson)
	check(opening.contains("%d coins" % given), "talking to him, he tells it (%s)" % opening)
	check(not Dialogue.opening(w, grandson).contains("%d coins" % given), "...once: he remembers having told this listener")
	# saved and loaded (inside the judgment section; the save's own version is unchanged)
	var text := JSON.stringify(j.to_dict())
	var k := JudgmentStore.new(j.cfg)
	check(k.load_dict(JSON.parse_string(text)) == "" and JSON.stringify(k.to_dict()) == text, "the history and references save and load byte-identically")
	var d: Dictionary = JSON.parse_string(text)
	check(int(d.version) == 3 and d.has("history"), "...in the judgment section, version 3, key history")
	var wd := w.to_dict()
	check(int(wd.save_version) == World.SAVE_VERSION and wd.judgment.has("history"), "the world save carries it in its judgment section; save_version unchanged (%d)" % World.SAVE_VERSION)
	# variants: the house sold, then gone
	var b: Dictionary = w.buildings[bid]
	var sold := w.property.sell(b, World.hh_ref(h))
	var st := EventTalk.history(w, grandson)
	check(sold == "" and str(st.state) == "sold" and str(st.owner) == "the manor", "sold back to the manor: the record reads the house as no longer theirs (%s %s)" % [sold, JSON.stringify(st)])
	var sl := DialogueVoice.history_line(w, grandson, st)
	print("     sold: " + sl)
	check(sl.contains("the manor") and not sl.contains("our house"), "...and the line says so")
	w.buildings.erase(bid)            # nothing in the game pulls a house down yet: the record reads the world as it stands
	var gone := EventTalk.history(w, grandson)
	var gl := DialogueVoice.history_line(w, grandson, gone)
	print("     destroyed: " + gl)
	check(str(gone.state) == "destroyed" and (gl.contains("stands no more") or gl.contains("gone")), "the house gone: the line remembers it without claiming it stands")
	w.dispose()


## The significance rule (judgment.json history): small help is not history; help that is a real share of the house is.
func test_significance() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 2)
	var j := JudgmentLive.attach(w, plain_cfg())
	var a: NPC = w.npcs[3]
	var b: NPC = w.npcs[4]
	var hc: Dictionary = j.cfg.history
	var small := JudgmentLive.on_build_help(w, a.id, b, int(hc.min_value) - 1, 0, 1, "parcelX", 0)
	check(small > 0 and not j.history.has(small) and j.fact_refs.has(small), "under history.min_value: a judged deed with references, not history")
	var share := JudgmentLive.on_build_help(w, a.id, b, 50, 0, 1, "parcelX", 1000)
	check(not j.history.has(share), "50 coins toward a 1000-coin house (under %d permille): not history" % int(hc.significant_share_permille))
	var big := JudgmentLive.on_build_help(w, a.id, b, 300, 0, 1, "parcelX", 1000)
	check(j.history.has(big), "300 coins toward a 1000-coin house: history")
	check(j.ledger(b.id, a.id)[0] > 0, "the gift is judged as before (help_build GOOD)")
	w.dispose()


## A Build 22 save (judgment section version 2, no references or history) loads with none and writes version 3.
func test_old_save() -> void:
	var text := FileAccess.get_file_as_string("res://tests/fixtures/b22_save_v23_single.json")
	var d: Dictionary = JSON.parse_string(text)
	check(d.has("judgment") and int(d.judgment.version) == 2 and not d.judgment.has("history"), "fixture: a Build 22 save, judgment section version 2")
	var w := World.new()
	w.load_dict(VillageMap.load_default(), d)
	check(w.judgment != null and w.judgment.unread.is_empty() and w.judgment.history.is_empty() and w.judgment.fact_refs.is_empty(),
			"it loads with no historical records and no references, nothing kept unread")
	var out := w.to_dict()
	check(int(out.judgment.version) == 3 and not out.judgment.has("history"), "re-saved as version 3, with nothing invented")
	w.dispose()
