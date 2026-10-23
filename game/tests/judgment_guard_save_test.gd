extends SceneTree
## Post-audit repairs D1 and D3 (Expansion 19, PROS-19): a saved "judgment" section never switches judgment on while the
## switch is off, and is carried through saves unchanged; a friend guard waives the fine (Build 18) with judgment off and
## only halves it (never 0) with judgment on. Run headless:
##   godot --headless --path game --script res://tests/judgment_guard_save_test.gd

var failures := 0
var checks := 0
const ME := Life.PLAYER_ID


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func reload(w: World) -> World:
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	return w2


func _init() -> void:
	test_foreign_section()
	test_enabled_restores()
	test_old_save()
	test_guard()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _saved_section() -> Dictionary:
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var victim: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard")[0]
	w.player.pos = victim.pos
	victim.inv.add("bread", 1)
	w.witness("theft", "bread", victim, {"bread": 1})
	var sec: Dictionary = JSON.parse_string(JSON.stringify(j.to_dict()))
	w.dispose()
	return sec


func test_foreign_section() -> void:
	check(not JudgmentLive.enabled(), "judgment.json still ships disabled")
	var sec := _saved_section()
	var base := new_world()
	var d: Dictionary = JSON.parse_string(JSON.stringify(base.to_dict()))
	d.judgment = sec
	var w := World.new()
	w.load_dict(VillageMap.load_default(), d)
	check(w.judgment == null, "judgment off + a saved judgment section: nothing is attached")
	var a: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard")[0]
	var plain := new_world()
	var pa: NPC = plain.npcs[w.npcs.find(a)]
	w.relations.helped(ME, a)
	plain.relations.helped(ME, pa)
	check(w.judgment == null and is_equal_approx(float(w.relations.peek(ME, a.id).regard), float(plain.relations.peek(ME, pa.id).regard)), "...and a Relations gain gets no judgment bonus (same as a world with no section)")
	plain.dispose()
	var want := JSON.stringify(sec)
	check(JSON.stringify(w.to_dict().judgment) == want, "...the section is written back byte-identical")
	var cur := w
	for i in 3:
		var nxt := reload(cur)
		check(nxt.judgment == null and JSON.stringify(nxt.to_dict().judgment) == want, "...and survives save/load cycle %d unchanged" % (i + 1))
		if cur != w:
			cur.dispose()
		cur = nxt
	cur.dispose()
	w.dispose()
	base.dispose()


func test_enabled_restores() -> void:
	var sec := _saved_section()
	var base := new_world()
	var d: Dictionary = JSON.parse_string(JSON.stringify(base.to_dict()))
	d.judgment = sec
	JudgmentLive.test_enabled = true
	var w := World.new()
	w.load_dict(VillageMap.load_default(), d)
	check(w.judgment != null and JSON.stringify(JSON.parse_string(JSON.stringify(w.judgment.to_dict()))) == JSON.stringify(sec), "judgment on: the saved section is restored and working")
	check(w.to_dict().has("judgment") and w.judgment_foreign.is_empty(), "...and nothing is held aside")
	var w2 := reload(w)
	check(w2.judgment != null and JSON.stringify(w2.judgment.to_dict()) == JSON.stringify(w.judgment.to_dict()), "...and saves and loads unchanged")
	JudgmentLive.test_enabled = false
	for x in [w, w2, base]:
		x.dispose()


func test_old_save() -> void:
	var base := new_world()
	var d: Dictionary = JSON.parse_string(JSON.stringify(base.to_dict()))
	check(not d.has("judgment"), "a save without the key has none")
	var w := World.new()
	w.load_dict(VillageMap.load_default(), d)
	check(w.judgment == null and not w.to_dict().has("judgment"), "...loads with judgment off and saves as it was")
	JudgmentLive.test_enabled = true
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	check(w2.judgment != null, "...and with the switch on gets a fresh store")
	JudgmentLive.test_enabled = false
	for x in [w, w2, base]:
		x.dispose()


func _guard(w: World) -> NPC:
	return w.npcs.filter(func(n: NPC) -> bool: return n.job == "guard" and n.alive)[0]


func test_guard() -> void:
	for on in [false, true]:
		var w := new_world()
		if on:
			JudgmentLive.attach(w)
		var g: NPC = _guard(w)
		w.relations.befriend(ME, g.id)
		var full := World.theft_fine_for({"bread": 1})
		w.player.coins = 200
		var said := w.guard_confront(g, {"bread": 1}, null, null)
		var paid := 200 - w.player.coins
		if on:
			check(paid >= 1 and paid == maxi(full / 2, 1) and said.contains("lowered"), "judgment on: a friend guard halves the fine, never 0 (%d of %d)" % [paid, full])
			w.player.coins = 200
			w.treasury += 0
			var tiny := w.guard_confront(g, {}, null, null)
			check(200 - w.player.coins >= 1, "judgment on: never below 1 coin (%s)" % str(200 - w.player.coins))
		else:
			check(paid == 0 and said.contains("let off with a warning"), "judgment off: a friend guard waives the fine with the Build 18 message")
		# a friend nearby, guard not a friend
		var w2 := new_world()
		if on:
			JudgmentLive.attach(w2)
		var g2: NPC = _guard(w2)
		var pal: NPC = w2.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard")[0]
		pal.pos = w2.player.pos
		w2.relations.befriend(ME, pal.id)
		w2.player.coins = 200
		w2.guard_confront(g2, {"bread": 1}, null, null)
		check(200 - w2.player.coins == full / 2, "judgment %s: a friend nearby halves the fine (%d of %d)" % ["on" if on else "off", 200 - w2.player.coins, full])
		w.dispose()
		w2.dispose()
