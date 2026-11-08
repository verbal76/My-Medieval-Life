extends SceneTree
## JUS-03: an old-age death must close the offender's criminal case,
## including a guest line, before an heir reuses that same player reference.
var checks := 0
var failures := 0

func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		printerr("FAIL: " + what)

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8003)
	var ref := w.acting_ref()
	w.justice.record(ref, "killing", null, w.player.pos, 1)
	check(not w.justice.case_of(ref).is_empty(), "JUS-03: host has an open murder case")
	w.player.born = w.minutes - Life.years_to_minutes(80.0)
	Life._player_dawn_one(w)
	check(not w.player.alive and str(w.player.death_cause) == "old age", "JUS-03: host dies of old age")
	check(w.justice.case_of(ref).is_empty(), "JUS-03: old-age death closes host justice case")
	var closed := w.justice.closed.filter(func(c): return str(c.get("offender", "")) == ref and str(c.get("resolution", "")) == "died")
	check(closed.size() == 1, "JUS-03: death archives the case with reason died, once")
	w.continue_as_heir()
	check(w.player.alive and w.acting_ref() == ref and w.justice.case_of(ref).is_empty(), "JUS-03: heir keeps family reference but no wanted case")

	var guest := PlayerState.new()
	guest.name = "Guest"
	guest.family = "Test"
	guest.sex = "female"
	guest.born = w.minutes - Life.years_to_minutes(80.0)
	Identity.register_player(w, guest)
	w.give_start_kit(guest)
	guest.net_key = "a".repeat(32)
	guest.pos = w.player.pos + Vector2(3, 0)
	w.add_guest(guest)
	var guest_ref := w.player_ref(guest)
	w.justice.record(guest_ref, "killing", null, guest.pos, 1)
	check(not w.justice.case_of(guest_ref).is_empty(), "JUS-03: guest has its own criminal case")
	w.as_actor(guest, Life._player_dawn_one.bind(w))
	check(not guest.alive and str(guest.death_cause) == "old age", "JUS-03: guest dies of old age")
	check(w.justice.case_of(guest_ref).is_empty(), "JUS-03: guest old-age death closes only guest case")
	check(w.justice.case_of(ref).is_empty(), "JUS-03: host heir remains free of old criminal case")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
