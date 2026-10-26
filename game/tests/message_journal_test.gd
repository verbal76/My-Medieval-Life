extends SceneTree
## GP-MESSAGE-JOURNAL (owner, 2026-10-26, docs/directives/2026-10-26_messages_journal_persistence.md, section 6): the journal's
## Messages page is the saved world's history, in the real game scene and through the game's own save and load:
##   1-6. messages received (one put away by a tap, one left to fade, a routine one not kept, a repeat kept once), saved, the game
##        closed and opened again: every kept message comes back, in order, with its day, time, category and words;
##   7-8. a Build 22 save (version 23, tests/fixtures/b22_save_v23_single.json, written by b7e1c91) and a Build 21 save (version 22,
##        tests/fixtures/mp_save_v22_couple.json, written by 6567c04) have no journal: they load with an empty one and everything
##        else as before;
##   9.   two saved worlds keep their own histories; a new game starts with none;
##   10.  keeping messages changes nothing in the simulation (same seed, same steps, with and without messages: the same world);
##   and the retention rules: per player, two tiers with their caps from game/data/message_journal.json, ordinary entries never
##   pushing out significant ones; a guest's messages are its own.
##   godot --headless --path game --script res://tests/message_journal_test.gd

var main
var checks := 0
var failures := 0
const DIR := "user://test_saves/message_journal_test/"


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	GameData.ensure()
	DirAccess.make_dir_recursive_absolute(DIR)
	_retention()
	_per_player()
	_old_saves()
	_determinism()
	main = _new_main()
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _new_main():
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	return m


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	await _save_and_reload()
	await _two_worlds()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- 1-6: receive, dismiss, fade, save, exit, reload -----------
func _save_and_reload() -> void:
	main.save_path = DIR + "a.json"
	main.new_game()
	main.ui.hide_all()
	var ui = main.ui
	var w: World = main.world
	var first: Array = w.player_messages()
	check(first.size() == 1 and str(first[0][2]).contains("Any work for me?"), "a new game's journal holds only its opening message (%d)" % first.size())
	ui.message("Contract made with Hugh Reed: 4 logs at 3 each.", 4.0, "contract")
	ui.message("You sell 2 apples for 6 coins.", 4.0, "trade")
	ui.message("You select the workbench.")                         # routine feedback: shown, not kept
	check(ui.toast.visible and ui.toast.text == "You select the workbench.", "a routine message shows as before")
	ui.message("The guard Ada saw you take it: you owe a fine of 10 coins.", 4.0, "crime")
	ui.dismiss_message()                                              # 2. put away by hand
	check(not ui.toast.visible, "a message tapped away goes from the screen")
	w.minutes += 75.0
	ui.message("You sell 2 apples for 6 coins.", 4.0, "trade")        # the same words again the same day: kept once
	ui.message("Hugh Reed: There's nothing the manor needs carried just now.", 4.0, "npc")
	ui.toast_t = 0.0001                                               # 3. left to fade
	await frames(2)
	check(not ui.toast.visible, "a message left alone fades from the screen")
	w.minutes += 1440.0
	ui.message("You sell 2 apples for 6 coins.", 4.0, "trade")        # the next day: kept again
	var before: Array = w.player_messages()
	check(before.size() == 7, "the opening, five kept messages and the next day's repeat: 7 entries (%d); the routine one not kept, the same-day repeat kept once" % before.size())
	check(before.any(func(e): return str(e[2]).begins_with("The guard Ada")) and before.any(func(e): return str(e[2]).begins_with("Hugh Reed:")),
		"the message tapped away and the one that faded are still in the journal")
	var ordered := true
	for i in range(1, before.size()):
		if int(before[i][0]) < int(before[i - 1][0]):
			ordered = false
	check(ordered, "in the order they came, by day and time")
	ui.show_journal(-1, false, true)
	var shown := _page_text(ui)
	check(shown.contains("Contract made with Hugh Reed") and shown.contains("Day 2"), "the Messages page shows them, by day")
	ui.hide_all()
	ui.show_journal(-1, false, true)
	check(_page_text(ui) == shown, "opening the page again erases nothing")
	ui.hide_all()
	check(main.save_game(false), "4. saved")
	var raw = JSON.parse_string(FileAccess.get_file_as_string(main.save_path))
	check(raw is Dictionary and (raw as Dictionary).has(MessageJournal.KEY) and int(raw.save_version) == World.SAVE_VERSION,
		"in the world's own save, under its optional key %s (save version %d unchanged)" % [MessageJournal.KEY, World.SAVE_VERSION])
	# 5. the game closed and opened again
	main.queue_free()
	await frames(2)
	main = _new_main()
	await frames(2)
	main.save_path = DIR + "a.json"
	main.continue_game()
	await frames(2)
	var after: Array = main.world.player_messages()
	check(JSON.stringify(after) == JSON.stringify(before), "6. every kept message is back, with its day, time, category and words (%d)" % after.size())
	main.ui.show_journal(-1, false, true)
	check(_page_text(main.ui) == shown, "and the Messages page reads as before")
	main.ui.hide_all()


func _page_text(ui) -> String:
	var t := ""
	for l in ui.panel_body.find_children("*", "Label", true, false):
		t += (l as Label).text + "\n"
	return t


# ---------------------------------------------------------------- 9: two worlds -------------------------------------------
func _two_worlds() -> void:
	var a_msgs: Array = main.world.player_messages()
	main.save_path = DIR + "b.json"
	main.new_game()
	main.ui.hide_all()
	check(main.world.player_messages().size() == 1, "a new game starts afresh (only its opening message), whatever was loaded before")
	main.ui.message("Hired: Fell trees for the carpenter. It is written in your journal.", 4.0, "work")
	var b_msgs: Array = main.world.player_messages()
	main.save_game(false)
	main.save_path = DIR + "a.json"
	main.continue_game()
	await frames(2)
	check(JSON.stringify(main.world.player_messages()) == JSON.stringify(a_msgs), "loading the first world shows its own messages")
	main.save_path = DIR + "b.json"
	main.continue_game()
	await frames(2)
	check(JSON.stringify(main.world.player_messages()) == JSON.stringify(b_msgs) and b_msgs.size() == 2, "and the second world its own")


# ---------------------------------------------------------------- retention --------------------------------------------------
func _retention() -> void:
	var sig := MessageJournal.cap_of("significant")
	var ord := MessageJournal.cap_of("ordinary")
	check(sig >= ord and ord > 0, "two tiers from game/data/message_journal.json: significant %d, ordinary %d" % [sig, ord])
	check(MessageJournal.tier_of("crime") == "significant" and MessageJournal.tier_of("trade") == "ordinary" and MessageJournal.tier_of("") == "",
		"crime is significant, trade ordinary, an untagged message not kept")
	var j := MessageJournal.new()
	var t := 0
	for i in 10:
		j.record("player", t, "crime", "crime %d" % i)
		t += 1
	for i in ord + 50:                                         # far more ordinary messages than the ordinary cap
		j.record("player", t, "trade", "sale %d" % i)
		t += 1
	var e := j.entries("player")
	var crimes := e.filter(func(x): return str(x[1]) == "crime").size()
	var sales := e.filter(func(x): return str(x[1]) == "trade")
	check(crimes == 10 and sales.size() == ord and str(sales[0][2]) == "sale 50", "a flood of ordinary messages trims the oldest ordinary ones only (%d crimes kept, %d sales, oldest %s)" % [crimes, sales.size(), sales[0][2]])
	for i in sig + 5:
		j.record("player", t, "family", "family %d" % i)
		t += 1
	e = j.entries("player")
	var sigs := e.filter(func(x): return MessageJournal.tier_of(str(x[1])) == "significant")
	check(sigs.size() == sig and e.filter(func(x): return str(x[1]) == "trade").size() == ord, "past the significant cap the oldest significant go, the ordinary ones stay (%d, %d)" % [sigs.size(), ord])
	check(JSON.stringify(MessageJournal.from_dict(JSON.parse_string(JSON.stringify(j.to_dict()))).to_dict()) == JSON.stringify(j.to_dict()), "the journal survives a save's round trip unchanged")
	var bytes := JSON.stringify(j.to_dict()).length()
	print("size: a full journal of %d entries is %d bytes of JSON (%.0f bytes an entry)" % [e.size(), bytes, float(bytes) / e.size()])
	var real := MessageJournal.new()                           # with words of a real message's length
	var said := "Contract made with Hugh Reed: 4 logs at 3 coins each, within 3 days (12 coins, set aside)."
	for i in sig:
		real.record("player", 1000000 + i, "contract", said + str(i))
	for i in ord:
		real.record("player", 3000000 + i, "trade", "You sell 2 apples for 6 coins. " + str(i))
	var rb := JSON.stringify(real.to_dict(), "", true, true).length()
	print("size: a full journal with real words (%d entries): about %d KB in a save (%.0f bytes an entry)" % [sig + ord, rb / 1024, float(rb) / (sig + ord)])


# ---------------------------------------------------------------- shared game: per player -----------------------------------
func _per_player() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 4)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Fairlight"
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.pos = w.player.pos + Vector2(3, 0)
	g.net_key = "ab".repeat(32)
	w.add_guest(g)
	w.player_tell("You sell 1 apple for 3 coins.", "trade")
	w.as_actor(g, func(): w.player_tell("You buy 1 loaf for 2 coins.", "trade"))
	var host: Array = w.messages.entries(w.player_ref(w.player))
	var guest: Array = w.messages.entries(w.player_ref(g))
	check(host.size() == 1 and guest.size() == 1 and str(host[0][2]).begins_with("You sell") and str(guest[0][2]).begins_with("You buy"),
		"in a shared world each player keeps their own messages (%s / %s)" % [w.player_ref(w.player), w.player_ref(g)])
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(JSON.stringify(w2.messages.to_dict()) == JSON.stringify(w.messages.to_dict()), "both are saved in the host's world")
	check(NetActions.VERBS.has("player_tell"), "a guest's message goes to the host as a player verb (World.player_tell)")
	w.dispose()
	w2.dispose()


# ---------------------------------------------------------------- 7-8: older saves --------------------------------------------
func _old_saves() -> void:
	for f in [["b22_save_v23_single.json", 23, "Build 22"], ["mp_save_v22_couple.json", 22, "Build 21"]]:
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/" + str(f[0])))
		check(d is Dictionary and int(d.save_version) == int(f[1]) and not (d as Dictionary).has(MessageJournal.KEY), "%s save (version %d) with no message journal" % [f[2], f[1]])
		var w := World.new()
		w.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
		check(w.load_error == "" and w.messages.is_empty() and w.player_messages().is_empty(), "%s: loads, with an empty journal (%s)" % [f[2], w.load_error])
		var out := w.to_dict()
		check(not out.has(MessageJournal.KEY), "%s: an empty journal writes no key: the save is as it was" % f[2])
		# everything else as an unchanged load gives it: the same load without the journal code path is the same world
		var w2 := World.new()
		var d2: Dictionary = JSON.parse_string(JSON.stringify(d))
		d2[MessageJournal.KEY] = {}
		w2.load_dict(VillageMap.load_default(), d2)
		check(JSON.stringify(w2.to_dict()) == JSON.stringify(out), "%s: an empty journal key or none load the same world" % f[2])
		if int(f[1]) == World.SAVE_VERSION:
			var same := []
			var differ := []
			for k in d:
				if out.has(k):
					(same if JSON.stringify(out[k]) == JSON.stringify(d[k]) else differ).append(k)
			check(not out.has(MessageJournal.KEY) and out.keys().size() >= (d as Dictionary).keys().size() - 1,
				"%s: every section of the save is written back (%d the same as saved, %d re-derived on load: %s)" % [f[2], same.size(), differ.size(), differ])
			print("  sections re-derived on load (as before this change): %s" % [differ])
		w.player_tell("You sell 1 apple for 3 coins.", "trade")
		var w3 := World.new()
		w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
		check(w3.player_messages().size() == 1, "%s: after a message the next save keeps it" % f[2])
		for x in [w, w2, w3]:
			x.dispose()


# ---------------------------------------------------------------- 10: determinism ---------------------------------------------
func _determinism() -> void:
	var a := World.new()
	a.setup(VillageMap.load_default(), 7)
	var b := World.new()
	b.setup(VillageMap.load_default(), 7)
	for i in 600:
		a.update(0.5)
		b.update(0.5)
		if i % 20 == 0:
			b.player_tell("A message on step %d." % i, "village" if i % 40 == 0 else "trade")
	check(not b.messages.is_empty() and a.messages.is_empty(), "one world kept messages, the other none")
	var da := a.to_dict()
	var db := b.to_dict()
	db.erase(MessageJournal.KEY)
	check(a.rng.state == b.rng.state and a.minutes == b.minutes, "the same random state and clock with and without messages")
	check(JSON.stringify(da) == JSON.stringify(db), "and the same world in every saved section but the journal")
	a.dispose()
	b.dispose()
