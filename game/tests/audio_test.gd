extends SceneTree
## MUSIC-18 and SFX-18: the music slots and tracks, the Ogg fallback, the buses and sliders, the ambience (never
## duplicate players), the sound effects (files, rate limit) and safety without an audio device. Run:
##   godot --headless --path game --script res://tests/audio_test.gd

var failures := 0


func check(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _players(a: Node) -> int:
	return a.find_children("*", "AudioStreamPlayer", true, false).size()


## Update until the song for this hour is playing (a WAV loads in the background).
func _settle(a: GameAudio, hour: float) -> void:
	for i in 300:
		a.update(1.0, {"hour": hour})
		var c: GameAudio.Voice = a._current(a.music_voices)
		if c != null and c.id == a.music_id and c.level >= 1.0:
			return
		OS.delay_msec(20)


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	# the slot and the ambience for a time and a place
	var T := func(h: float, l := 0, extra := {}) -> Dictionary:
		var c := {"hour": h, "level": l}
		c.merge(extra, true)
		return c
	check(GameAudio.slot_for(T.call(7.0)) == "morning", "07:00 on the surface is morning")
	check(GameAudio.slot_for(T.call(5.9)) == "night", "05:54 is still night")
	check(GameAudio.slot_for(T.call(6.0)) == "morning", "06:00 is morning")
	check(GameAudio.slot_for(T.call(10.0)) == "day", "10:00 is day")
	check(GameAudio.slot_for(T.call(17.9)) == "day", "17:54 is day")
	check(GameAudio.slot_for(T.call(18.0)) == "night", "18:00 is evening, the night song")
	check(GameAudio.slot_for(T.call(23.0)) == "night", "23:00 is night")
	check(GameAudio.slot_for(T.call(12.0, -1)) == "night", "the mine at noon plays the night song")
	check(GameAudio.slot_for(T.call(12.0, -2)) == "night", "the cave at noon plays the night song")
	check(GameAudio.slot_for(T.call(13.0, 0, {"title": true})) == "morning", "the title screen is morning, whatever the hour")
	check(GameAudio.slot_for(T.call(13.0, -1, {"title": true, "fight": true})) == "morning", "the title wins over everything")
	# priority: fight, countryside, underground, time of day
	check(GameAudio.slot_for(T.call(12.0, 0, {"countryside": true})) == "countryside", "the countryside plays Plain Sight, day or night")
	check(GameAudio.slot_for(T.call(23.0, 0, {"countryside": true})) == "countryside", "the countryside at night too")
	check(GameAudio.slot_for(T.call(12.0, 0, {"countryside": true, "fight": true})) == "fight", "a fight beats the countryside")
	check(GameAudio.slot_for(T.call(12.0, 0, {"fight": true})) == "fight", "a fight beats the time of day")
	check(GameAudio.slot_for(T.call(12.0, -1, {"countryside": true})) == "countryside", "the countryside beats underground")
	check(GameAudio.slot_for(T.call(12.0, -1, {"fight": true})) == "fight", "a fight beats underground")
	check(GameAudio.ambience_for(T.call(12.0)) == ["birds", ""], "village by day: birds, nothing else")
	check(GameAudio.ambience_for(T.call(12.0, 0, {"summer": true})) == ["birds", "cicada"], "a summer day adds cicadas")
	check(GameAudio.ambience_for(T.call(23.0, 0, {"summer": true})) == ["crickets", ""], "village at night: crickets, no cicadas")
	check(GameAudio.ambience_for(T.call(12.0, 0, {"countryside": true})) == ["forest", "wind"], "the countryside by day: the woods and the wind")
	check(GameAudio.ambience_for(T.call(23.0, 0, {"countryside": true})) == ["crickets", "wind"], "the countryside at night: crickets and wind")
	check(GameAudio.ambience_for(T.call(12.0, -1)) == ["dungeon", ""], "drips in the mine gallery")
	check(GameAudio.ambience_for(T.call(12.0, -2)) == ["cave_wind", ""], "wind in the cave")
	check(GameAudio.ambience_for(T.call(12.0, -3)) == ["dungeon", ""], "drips in the shafts below the cave")
	check(GameAudio.ambience_for(T.call(12.0, 0, {"title": true})) == ["", ""], "no ambience on the title screen")

	var a := GameAudio.new()
	root.add_child(a)
	var cfg: Dictionary = a.cfg
	check(not cfg.is_empty() and cfg.tracks.size() == 5, "music.json lists the three songs and the two pack songs")
	check(a.track_for_slot("morning") == "sunrise_over_the_village" and a.track_for_slot("day") == "prosperous_village" \
			and a.track_for_slot("night") == "misted_ancient", "each time of day has the owner's song")
	check(a.track_for_slot("fight") == "fair_fight" and a.track_for_slot("countryside") == "plain_sight", "fight and countryside have the Minifantasy songs")
	check(cfg.slot_priority == ["fight", "countryside", "underground", "time of day"], "the priority order is recorded")
	for t: Dictionary in cfg.tracks:
		if t.has("url"):
			check(str(t.sha256).length() == 64 and int(t.bytes) > 1000000 and str(t.url).begins_with("https://github.com/verbal76/My-Medieval-Life/releases/download/"), "%s: URL, size and sha256 recorded" % t.id)
		check(ResourceLoader.exists("res://" + str(t.ogg)), "%s: the Ogg is in the project" % t.id)
		var want: String = ("res://" + str(t.wav)) if t.has("wav") and ResourceLoader.exists("res://" + str(t.wav)) else "res://" + str(t.ogg)
		check(a.music_path(str(t.id)) == want, "%s plays from %s (the WAV when present, else the Ogg)" % [t.id, want.get_extension()])
	for s in cfg.slots:
		check(a.track_for_slot(s) in cfg.tracks.map(func(t): return t.id), "slot %s names a listed song" % s)

	# headless: no audio device, nothing loaded, nothing fails
	check(not a.active and DisplayServer.get_name() == "headless", "headless audio is inactive")
	a.update(0.1, T.call(12.0))
	check(a.slot == "day" and a.music_id == "prosperous_village" and a.ambience_ids == ["birds", ""], "inactive audio still follows the time of day")
	check(a.play_sfx("coin", 0), "an effect is accepted without a device")
	check(a.step("grass", 0), "a footstep is accepted without a device")

	# buses and the sliders
	check(AudioServer.get_bus_index("Music") != -1 and AudioServer.get_bus_index("SFX") != -1, "Music and SFX buses exist")
	for v: GameAudio.Voice in a.music_voices:
		check(v.player.bus == "Music", "a music player is on the Music bus")
	for layer: Array in a.amb_voices:
		for v: GameAudio.Voice in layer:
			check(v.player.bus == "SFX", "an ambience player is on the SFX bus")
	check(a._sfx_pool.all(func(p): return p.bus == "SFX"), "effect players are on the SFX bus")
	var st := GameSettings.new()
	st.music = 0.5
	st.sfx = 0.25
	st.apply(self)
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.5)) < 0.01, "the Music slider reaches the Music bus")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) - linear_to_db(0.25)) < 0.01, "the Sound-effects slider reaches the SFX bus")
	st.music = 0.0
	st.apply(self)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music at zero mutes the bus")

	# with a device: the crossfade, the gap and no duplicate players
	a.active = true
	var n0 := _players(a)
	for round in 4:
		for lvl in [0, -1, -2, -3, 0]:
			for h in [7.0, 12.0, 20.0]:
				for extra in [{}, {"countryside": true, "summer": true}, {"fight": true}]:
					for i in 2:
						a.update(0.5, T.call(h, lvl, extra))
	check(_players(a) == n0, "repeated updates never add a player (%d players)" % n0)
	var sounding := 0
	for layer: Array in a.amb_voices:
		check(layer.filter(func(v): return v.player.playing).size() <= 2, "a layer has at most two players sounding")
		if a._current(layer) != null:
			sounding += 1
	check(sounding <= 2, "at most two ambience layers at once")
	_settle(a, 12.0)
	check(a.ambience_ids == ["birds", ""], "outdoors by day: birds")
	var bed: GameAudio.Voice = a._current(a.amb_voices[0])
	check(bed != null and bed.id == "birds" and (bed.player.stream as AudioStreamOggVorbis).loop, "the birds loop")
	check(a._current(a.amb_voices[1]) == null, "no second layer in the village in winter")
	a.update(3.0, T.call(12.0, 0, {"countryside": true}))
	check(a.ambience_ids == ["forest", "wind"] and a._current(a.amb_voices[1]).id == "wind", "the countryside: woods and wind, two layers")
	var cur: GameAudio.Voice = a._current(a.music_voices)
	a.update(0.5, T.call(12.0, 0, {"fight": true}))
	check(a.music_id == "fair_fight", "a fight starts the fight song")
	for i in 12:
		a.update(0.5, T.call(12.0, 0, {"fight": true}))
	cur = a._current(a.music_voices)
	check(cur != null and cur.id == "fair_fight" and cur.player.playing and cur.level >= 0.99, "the fight song is up within 6 s")
	a.update(0.5, T.call(12.0))
	check(a.music_id == "prosperous_village", "without the fight the slot's song returns")
	_settle(a, 12.0)
	cur = a._current(a.music_voices)
	check(cur != null and cur.id == "prosperous_village" and cur.player.playing, "the daytime song plays")
	a.update(0.5, T.call(20.0))
	var fading := a.music_voices.filter(func(v): return v.target == 0.0 and v.level > 0.0)
	check(fading.size() == 1 and a.music_id == "misted_ancient", "a new slot fades the old song out as the new one begins")
	for i in 20:
		a.update(0.5, T.call(20.0))
	cur = a._current(a.music_voices)
	check(cur != null and cur.id == "misted_ancient" and cur.level >= 0.99, "the evening song is up after the fade")
	check(a.music_voices.all(func(v): return v == cur or not v.player.playing), "the old song has stopped")
	cur.player.stop()                                    # the song ends
	a.update(0.5, T.call(20.0))
	check(a.gap_left > 0.0 and not cur.player.playing, "a finished song is followed by a quiet gap")
	for i in 20:
		a.update(0.5, T.call(20.0))
	cur = a._current(a.music_voices)
	check(cur != null and cur.player.playing and cur.id == "misted_ancient", "after the gap the song plays again")

	# the effects: files for every id and the loops, the rate limit
	for id in cfg.sfx.ids:
		check(ResourceLoader.exists(a.sfx_path(str(id))), "effect %s is imported" % id)
	for id in cfg.ambience.db_by_id:
		check(ResourceLoader.exists(a.sfx_path(id)), "ambience loop %s is imported" % id)
	for base in cfg.sfx.variants:
		for i in range(1, int(cfg.sfx.variants[base]) + 1):
			check(("%s_%d" % [base, i]) in cfg.sfx.ids, "%s_%d is listed" % [base, i])
	var b := GameAudio.new()
	root.add_child(b)
	check(b.play_sfx("coin", 1000), "the first coin sounds")
	check(not b.play_sfx("coin", 1100), "a repeat inside the gap is dropped")
	check(b.play_sfx("chest_open", 1100), "another effect is not held by it")
	check(b.play_sfx("coin", 1400), "after the gap the coin sounds again")
	check(not b.play_sfx("not_an_effect", 5000), "an unknown effect is ignored")
	var before := b.played.size()
	for i in 200:
		b.play_sfx("door_wood", 10000 + i)
	check(b.played.size() - before == 1, "200 door events in 200 ms sound once")
	# variants: never the same twice running; the gap is shared by the variants
	var seen := []
	for i in 40:
		check(b.play_variant("bush_rustling", 100000 + i * 1000), "variant %d sounds" % i) if i == 0 else b.play_variant("bush_rustling", 100000 + i * 1000)
		seen.append(b.played[-1])
	var repeats := 0
	for i in range(1, seen.size()):
		if seen[i] == seen[i - 1]:
			repeats += 1
	check(repeats == 0 and seen.size() == 40 and seen.any(func(x): return x != seen[0]), "a variant never repeats the one before it")
	check(b.play_variant("hit_on_wood", 500000) and not b.play_variant("hit_on_wood", 500050), "variants share their base's gap")
	# footsteps: soft, spaced, never faster than the minimum gap
	var steps: Dictionary = cfg.sfx.steps
	check(float(steps.db) <= -14.0 and float(steps.db) >= -18.0, "footsteps sit 14-18 dB under the other effects (%.0f)" % steps.db)
	check(float(steps.pitch_spread) > 0.0 and float(steps.pitch_spread) <= 0.05, "footsteps vary their pitch by 5% at most")
	var c0 := b.played.size()
	for i in 50:
		b.step("stone", 800000 + i * 100)              # a sprint: a step every 100 ms
	check(b.played.size() - c0 <= 50 * 100 / int(steps.min_gap_ms) + 1, "a sprint's steps are held to the minimum gap")
	for g in ["grass", "dirt", "stone"]:
		check(b.step(g, 900000 + hash(g) % 1000 * 1000), "a %s step sounds" % g)
	b.swing()
	b.hit(false)
	b.hit(true)
	check(b.played.size() <= 16, "the played list stays short")

	# Main owns one audio node
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	check(main.audio != null and main.audio.get_parent() == main, "Main owns the audio node")
	check(main.get_children().filter(func(c): return c is GameAudio).size() == 1, "Main has exactly one audio node")

	print("audio_test: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
