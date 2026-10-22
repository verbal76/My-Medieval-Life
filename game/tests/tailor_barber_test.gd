extends SceneTree
## TAILOR-18 / BARBER-18 (owner 2026-10-23): a new world has one tailor and one barber, each at a manor service pitch; a
## save with neither opens their places in the labour market; the barber's visit (5 coins, hair, beard, hair colour).
## Run: godot --headless --path game --script res://tests/tailor_barber_test.gd

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	var map := VillageMap.load_default()
	var w := World.new()
	w.setup(map, 1)
	var by := func(job: String) -> Array: return w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job == job)
	var t: NPC = (by.call("tailor") as Array)[0] if (by.call("tailor") as Array).size() == 1 else null
	var b: NPC = (by.call("barber") as Array)[0] if (by.call("barber") as Array).size() == 1 else null
	check(t != null and b != null, "a new world has exactly one tailor and one barber")
	if t == null or b == null:
		quit(1)
		return
	for pair in [[t, "pitch2", "tailor"], [b, "pitch3", "barber"]]:
		var n: NPC = pair[0]
		var s: Dictionary = w.stalls[pair[1]]
		check(n.workplace == pair[1] and w.tenant_of(s) == World.npc_ref(n.id) and str(s.service) == pair[2] and not bool(s.open),
			"the %s keeps %s (let to them, not open for sales)" % [pair[2], pair[1]])
		check(n.household >= 0 and n.home != "" and w.households[n.household].members.has(n.id), "the %s is housed in a household" % pair[2])
	check(w.business.free_pitch().id == "pitch0" and w.tenant_of(w.stalls.pitch0) == "" and w.tenant_of(w.stalls.pitch1) == "", "the player's pitches stay free")
	# the service rules: at the post, awake
	b.pos = Vector2(w.brain._workplace_cell(b)) + Vector2(0.5, 0.5)
	b.anim = "idle"
	var p := w.player
	p.appearance = CharacterLook.normalize(CharacterLook.random_recipe(RandomNumberGenerator.new(), "male"))
	p.appearance.picks.hair = "m1"
	p.appearance.picks["facial-hair"] = ""
	CharacterLook.set_swatch(p.appearance, "hair", 0)
	var want: Dictionary = p.appearance.duplicate(true)
	check(not w.player_barber_visit(b, want).ok and w.barber_refusal(b, want) == "Nothing would change.", "no change, no charge")
	want.picks.hair = "f2"
	want.picks["facial-hair"] = "beard2"
	CharacterLook.set_swatch(want, "hair", 3)
	want.picks.clothes = "tunic"           # not the barber's to change
	want.swatches.skin = 6
	var before: Dictionary = p.appearance.duplicate(true)
	p.coins = 4
	var r := w.player_barber_visit(b, want)
	check(not r.ok and r.why == "A visit costs 5 coins; you have 4." and p.appearance == before and p.coins == 4, "short of coins: refused, nothing changed (\"%s\")" % r.why)
	p.coins = 20
	b.anim = "sleep"
	check(not w.player_barber_visit(b, want).ok and p.coins == 20 and p.appearance == before, "a barber asleep does nothing")
	b.anim = "idle"
	var away := b.pos
	b.pos = Vector2(5, 5)
	check(w.barber_refusal(b, want).ends_with("is not at work.") and p.coins == 20, "a barber away from the pitch does nothing")
	b.pos = away
	var bad: Dictionary = want.duplicate(true)
	bad.picks.hair = "zz"
	check(w.barber_refusal(b, bad) == "The barber cannot do that.", "only the creator's own styles")
	var total0 := w.total_coins()
	var bc := b.coins
	r = w.player_barber_visit(b, want)
	check(r.ok and p.coins == 15 and b.coins == bc + 5 and w.total_coins() == total0, "the visit: 5 coins to the barber's purse exactly, total unchanged")
	var a: Dictionary = p.appearance
	check(a.picks.hair == "f2" and a.picks["facial-hair"] == "beard2" and a.swatches.hair == 3 and a.swatches.facial_hair == 3,
		"hair, beard and hair colour changed (the beard takes the hair colour)")
	check(a.picks.clothes == before.picks.clothes and a.swatches.skin == before.swatches.skin, "clothes and skin untouched")
	check(CharacterLook.texture(a) != CharacterLook.texture(before), "the sheet is drawn from the new recipe")
	# save and load
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(map, d)
	check(w2.player.appearance == CharacterLook.normalize(a), "the new looks persist through save and load")
	check((w2.npcs.filter(func(n): return w2.is_tailor(n))).size() == 1 and (w2.npcs.filter(func(n): return w2.is_barber(n))).size() == 1, "the loaded world has its tailor and barber")
	check(w2.tenant_of(w2.stalls.pitch2) != "" and w2.tenant_of(w2.stalls.pitch3) != "", "and they still keep their pitches")
	# an older save: no tailor, no barber
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	for n in old.npcs:
		if str(n.get("job", "")) in ["tailor", "barber"]:
			n.job = ""
			n.workplace = ""
	for id in ["pitch2", "pitch3"]:
		old.stalls.erase(id)
	var w3 := World.new()
	w3.load_dict(map, old)
	check(w3.stalls.has("pitch2") and w3.tenant_of(w3.stalls.pitch2) == "" and w3.tenant_of(w3.stalls.pitch3) == "", "an older save gets the service pitches, vacant")
	var m: Dictionary = w3.brain.job_market()
	check(int(m.tailor.open) == 1 and int(m.barber.open) == 1, "its labour market opens one tailor's and one barber's place")
	check(w3.npcs.size() == w.npcs.size(), "no villager is made on load")
	# an adult who becomes free takes the place
	var free: NPC = null
	for n: NPC in w3.npcs:
		if n.alive and n.role == "adult" and n.job == "" :
			free = n
			break
	if free == null:
		for n: NPC in w3.npcs:
			if n.alive and n.role == "adult" and n.job == "manor_hand":
				free = n
				break
	if free == null:
		free = w3.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job == "woodcutter")[0]
		w3.brain._change_job(free, "", "test")
	w3.brain._change_job(free, "tailor", "test")
	check(w3.tenant_of(w3.stalls.pitch2) == World.npc_ref(free.id) and free.workplace == "pitch2" and int(w3.brain.job_market().tailor.open) == 0, "the villager who takes it keeps the pitch; the place closes")
	free.alive = false
	check(int(w3.brain.job_market().tailor.open) == 1 and w3.tenant_of(w3.stalls.pitch2) == "", "if the tailor dies the pitch is freed and the place reopens")
	print("tailor_barber_test: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
