extends SceneTree
## PL2-002: chests, crates and barrels with ownership, locks and lockpicking. Pure World (no scene).
## Run headless:  godot --headless --path game --script res://tests/chests_test.gd

var failures := 0
var checks := 0


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


func _init() -> void:
	test_items()
	test_own_chest()
	test_household_chest()
	test_locked_refuses()
	test_decor_and_business()
	test_crates()
	test_own_lock()
	test_lockpick()
	test_witnessed()
	test_save_load()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A house with a chest spot, held by a household other than the player's, and the unit of its chest.
func foreign_house(w: World) -> Dictionary:
	for id in w.buildings:
		var b: Dictionary = w.buildings[id]
		if str(b.type) == "house" and w.holder_of(b).begins_with("hh:") and not w.chests.units_in(str(id)).is_empty():
			return w.chests.units_in(str(id))[0]
	return {}


## A house with a chest spot made the player's home.
func own_house(w: World) -> Dictionary:
	for id in w.buildings:
		var b: Dictionary = w.buildings[id]
		if str(b.type) == "house" and not w.holder_of(b).begins_with("hh:") and not w.chests.units_in(str(id)).is_empty():
			w.set_owner(b, World.PLAYER)
			w.set_tenant(b, "")
			w.player.home = str(id)
			return w.chests.units_in(str(id))[0]
	# every house is lived in at the start: give one to the player
	for id in w.buildings:
		var b: Dictionary = w.buildings[id]
		if str(b.type) == "house" and not w.chests.units_in(str(id)).is_empty():
			w.set_owner(b, World.PLAYER)
			w.set_tenant(b, "")
			w.player.home = str(id)
			return w.chests.units_in(str(id))[0]
	return {}


func put_in_room(w: World, u: Dictionary) -> void:
	w.player.pos = u.at + Vector2(0, 1)


func unlocked(w: World, u: Dictionary) -> void:
	w.chests.locks[u.id] = {"level": 0, "locked": false}


func test_items() -> void:
	GameData.ensure()
	check(GameData.items.has("lockpick") and GameData.items.has("padlock"), "lockpick and padlock are items")
	check(GameData.recipes.has("forge_lockpicks") and GameData.recipes.has("forge_padlock"), "both are forged at the anvil")
	check(GameData.recipes.forge_lockpicks.in.has("iron_bar") and GameData.recipes.forge_lockpicks.station == "anvil", "lockpicks come from iron bars")
	check(ResourceLoader.exists("res://assets/icons/lockpick.png") and ResourceLoader.exists("res://assets/icons/padlock.png"), "both have icons")


func test_own_chest() -> void:
	var w := new_world()
	var u := own_house(w)
	check(not u.is_empty(), "a house with a chest exists")
	var i := w.chests.info(u)
	check(i.access == "own" and i.store == w.player.chest and i.family, "the home chest is the family chest")
	w.player.inv.add("coal", 6)
	check(w.chests.store(u, "coal", 4) == "" and w.player.chest.count("coal") == 4 and w.player.inv.count("coal") == 2, "store 4 of 6 coal")
	var r := w.chests.take(u, "coal", 3)
	check(r.ok and w.player.chest.count("coal") == 1 and w.player.inv.count("coal") == 5 and w.player.crimes.is_empty(), "taking 3 back is free and no crime")
	check(not w.chests.take(u, "coal", 5).ok, "cannot take more than is there")
	check(w.chests.store(u, "iron_bar", 1) != "", "cannot store what you do not carry")
	# stolen marks go in and out with the goods
	w.player.inv.add("wheat", 2)
	w.player.mark_stolen("wheat", 5, 2)
	w.chests.store(u, "wheat", 2)
	check(w.player.chest_stolen.get("wheat", {}).get("5", 0) == 2, "stolen marks go into the chest with the goods")


func test_household_chest() -> void:
	var w := new_world()
	var u := foreign_house(w)
	check(not u.is_empty(), "a household's chest exists")
	unlocked(w, u)
	var i := w.chests.info(u)
	check(i.access == "foreign" and i.owner != null and i.business == false, "another household's chest is foreign")
	put_in_room(w, u)
	w.player.inv.add("coal", 2)
	check(w.chests.store(u, "coal", 1) != "" and i.store.count("coal") == 0 or i.store == w.households[i.owner.household].pantry, "you cannot store into another household's chest")
	check(w.chests.store(u, "coal", 1) == "That is not yours to fill.", "the refusal says it is not yours")
	i.store.add("wheat", 5)
	var pantry_before: int = i.store.count("wheat")
	var r := w.chests.take(u, "wheat", 2)
	check(r.ok and r.get("theft", false) and w.player.inv.count("wheat") >= 2 and i.store.count("wheat") == pantry_before - 2, "taking is theft: goods move out of their pantry")
	check(not w.player.crimes.is_empty() and w.player.crimes[-1].kind == "theft", "the theft is on the record")
	check(w.player.stolen.get("wheat", {}).has(str(i.owner.id)), "the wheat is marked as stolen from its owner")
	check(w.chests.store(u, "coal", 1) != "", "still cannot store")


func test_locked_refuses() -> void:
	var w := new_world()
	var u := foreign_house(w)
	var i := w.chests.info(u)
	i.store.add("wheat", 3)
	w.chests.locks[u.id] = {"level": 2, "locked": true}
	check(w.chests.is_locked(u), "the chest is locked")
	var r := w.chests.take(u, "wheat", 1)
	check(not r.ok and r.text == "It is locked." and i.store.count("wheat") >= 3 and w.player.inv.count("wheat") == 0, "a locked chest refuses")
	check(w.chests.cannot_pick(u) != "", "no lockpick: cannot pick")


func test_decor_and_business() -> void:
	var w := new_world()
	var manor := w.chests.units_in("b25")
	check(not manor.is_empty() and w.chests.info(manor[0]).access == "decor", "a chest in a building nobody holds is decorative")
	var mu: Dictionary = w.chests.units_in("b_manor")[0]
	check(w.chests.info(mu).access == "foreign" and w.chests.lock_of(mu).level == 3, "the manor's chests are the reeve's and locked hard")
	w.player.inv.add("coal", 1)
	check(w.chests.store(manor[0], "coal", 1) != "" and w.player.inv.count("coal") == 1, "nothing is stored in a decorative chest")
	check(not w.chests.take(manor[0], "coal", 1).ok, "and nothing taken from it")
	var tav := ""
	for id in w.buildings:
		if str(w.buildings[id].type) == "tavern":
			tav = str(id)
	var tu := w.chests.units_in(tav)
	var ti := w.chests.info(tu[0])
	check(ti.access == "foreign" and ti.business and ti.owner == w.tavern_keeper(), "the tavern's chest is the keeper's business stock")
	check(w.chests.lock_of(tu[0]).level == 2 and w.chests.is_locked(tu[0]), "the tavern locks its chest")
	check(w.chests.goods(tu[0]).all(func(id): return not w.brain.KEEPS.get("tavernkeeper", []).has(id)), "business goods exclude work tools")


func test_crates() -> void:
	var w := new_world()
	var own_crate := {}
	var other := {}
	for c in w.containers:
		if c.kind == "table":
			continue
		var b = w.buildings.get(c.at)
		if b != null and w.holder_of(b).begins_with("hh:") and other.is_empty():
			other = c
	check(not other.is_empty(), "a household's crate exists")
	var oi := w.chests.info(w.chests.unit_of_container(other))
	check(oi.access == "foreign" and oi.store == w.households[oi.owner.household].pantry, "a household's crate is its pantry")
	check(w.chests.lock_of(w.chests.unit_of_container(other)).level == 0, "crates are not locked")
	var u := own_house(w)
	for c in w.containers:
		if c.kind != "table" and c.at == w.player.home:
			own_crate = c
	if not own_crate.is_empty():
		var cu := w.chests.unit_of_container(own_crate)
		w.player.inv.add("log", 3)
		check(w.chests.info(cu).access == "own" and w.chests.store(cu, "log", 3) == "" and w.chests.info(cu).store.count("log") == 3, "a crate in your house is yours to fill")
		check(w.chests.take(cu, "log", 1).ok and w.player.crimes.is_empty(), "and to empty, with no crime")
	check(not u.is_empty(), "own house found for crate test")


func test_own_lock() -> void:
	var w := new_world()
	var u := own_house(w)
	check(w.chests.set_own_lock(u, true) != "", "no padlock: cannot lock")
	w.player.inv.add("padlock", 1)
	check(w.chests.set_own_lock(u, true) == "" and not w.player.inv.has("padlock") and w.chests.is_locked(u), "a padlock locks your chest and is used up")
	check(w.chests.lock_of(u).level == 2, "the padlock is level 2")
	w.player.inv.add("coal", 1)
	check(w.chests.store(u, "coal", 1) == "", "you still have your key: store into your locked chest")
	check(w.chests.set_own_lock(u, false) == "" and not w.chests.is_locked(u), "turn the key to unlock")
	check(w.chests.set_own_lock(u, true) == "" and w.chests.is_locked(u) and not w.player.inv.has("padlock"), "and lock again without another padlock")
	var f := foreign_house(w)
	check(w.chests.set_own_lock(f, true) != "", "you cannot lock someone else's chest")


func test_lockpick() -> void:
	var w := new_world()
	var u := foreign_house(w)
	var i := w.chests.info(u)
	i.store.add("wheat", 4)
	w.chests.locks[u.id] = {"level": 2, "locked": true}
	put_in_room(w, u)
	for n: NPC in w.npcs:
		n.pos = Vector2(1, 1)         # nobody near
	check(w.chests.attempt(u, 0.0).result == "cant", "no lockpick: no attempt")
	w.player.inv.add("lockpick", 3)
	# chance depends on skill and lock level
	var c2 := w.chests.pick_chance(u)
	w.chests.locks[u.id] = {"level": 3, "locked": true}
	var c3 := w.chests.pick_chance(u)
	w.chests.locks[u.id] = {"level": 1, "locked": true}
	var c1 := w.chests.pick_chance(u)
	check(c1 > c2 and c2 > c3, "harder locks are harder (%.2f > %.2f > %.2f)" % [c1, c2, c3])
	w.player.gain("stealth", 400)
	check(w.chests.pick_chance(u) > c1 or w.chests.pick_chance(u) == float(GameData.b("lockpick_max")), "more Stealth, better chance")
	w.chests.locks[u.id] = {"level": 2, "locked": true}
	check(w.chests.pick_minutes(u) == 2.0 * float(GameData.b("lockpick_minutes")), "a level 2 lock takes twice as long")
	var f := w.chests.attempt(u, 0.99, 0.99)
	check(f.result == "fail" and w.player.inv.count("lockpick") == 3 and w.chests.is_locked(u), "failure: still locked, pick kept")
	var b := w.chests.attempt(u, 0.99, 0.0)
	check(b.result == "broke" and w.player.inv.count("lockpick") == 2 and w.chests.is_locked(u), "a snapped pick is used up")
	var o := w.chests.attempt(u, 0.0)
	check(o.result == "open" and not w.chests.is_locked(u) and w.player.inv.count("lockpick") == 2, "success opens the lock")
	check(w.chests.take(u, "wheat", 2).ok, "and the goods can be taken (as theft)")
	check(w.player.crimes.any(func(c): return c.kind == "lockpicking"), "every attempt is on the record")
	# locked again from the next day
	w.minutes += 1440.0
	check(w.chests.is_locked(u), "the owner locks up again by the next day")


func test_witnessed() -> void:
	var w := new_world()
	var u := foreign_house(w)
	var i := w.chests.info(u)
	w.chests.locks[u.id] = {"level": 1, "locked": true}
	put_in_room(w, u)
	for n: NPC in w.npcs:
		n.pos = Vector2(1, 1)
	w.player.inv.add("lockpick", 3)
	w.player.coins = 50
	var bystander: NPC = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard")[0]
	bystander.pos = w.player.pos + Vector2(0.5, 0)
	bystander.anim = "idle"
	# the bystander is in the same place only if the player is inside the building
	var same := w.place_of(bystander.pos) == w.place_of(w.player.pos)
	check(same and w.place_of(w.player.pos) != "", "the player and a bystander share the room")
	var r := w.chests.attempt(u, 0.99, 0.99)
	check(r.seen >= 1, "a failed try is seen by the bystander")
	check(w.player.crimes[-1].kind == "lockpicking" and w.player.crimes[-1].witnesses >= 1, "a crime with witnesses is recorded")
	check(w.last_guard == "" and w.player.coins == 50, "no guard: no fine")
	# a guard in the room fines the player as for theft
	bystander.job = "guard"
	bystander.target = -1
	var coins := w.player.coins
	var t := w.treasury
	var r2 := w.chests.attempt(u, 0.99, 0.99)
	check(w.last_guard != "" and w.player.coins == coins - int(GameData.b("theft_fine")) and w.treasury == t + int(GameData.b("theft_fine")), "a guard who sees it fines the player")
	check(r2.text.contains("guard") or r2.text.contains("Guard"), "the guard's words are in the message")
	# the radius matters: someone 2.5 tiles away sees a loud try but not a quiet success
	bystander.job = "farmer"
	bystander.pos = w.player.pos + Vector2(1.5, 0)
	check(w.place_of(bystander.pos) == w.place_of(w.player.pos), "the bystander is still in the room")
	var seen_quiet := w.witness("lockpicking", "x", i.owner, {}, null, "pick x", 1.0)
	var seen_loud := w.witness("lockpicking", "x", i.owner, {}, null, "try to pick x", 4.0)
	check(seen_quiet == 0 and seen_loud >= 1, "noise: a short radius misses the bystander, a loud one does not")
	check(float(GameData.b("lockpick_quiet")) < 1.0, "a quiet success carries less far than a failure")


func test_save_load() -> void:
	var w := new_world()
	var u := own_house(w)
	w.player.inv.add("padlock", 1)
	w.chests.set_own_lock(u, true)
	w.player.inv.add("coal", 5)
	w.chests.store(u, "coal", 5)
	# a second house held by the player: its chest is a stash, saved with the world
	var other := {}
	for id in w.buildings:
		if str(id) != w.player.home and str(w.buildings[id].type) == "house" and not w.chests.units_in(str(id)).is_empty():
			w.set_owner(w.buildings[id], World.PLAYER)
			w.set_tenant(w.buildings[id], "")
			other = w.chests.units_in(str(id))[0]
			break
	w.player.inv.add("log", 4)
	check(w.chests.store(other, "log", 4) == "", "store into a second house's chest")
	var f := foreign_house(w)
	w.chests.locks[f.id] = {"level": 3, "locked": true}
	w.player.inv.add("lockpick", 2)
	w.chests.attempt(f, 0.0)
	var picked_open := not w.chests.is_locked(f)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), d)
	var u2 := w2.chests.unit(u.id)
	check(w2.chests.is_locked(u2) and w2.chests.lock_of(u2).level == 2, "your lock survives a save")
	check(w2.player.chest.count("coal") == 5, "the family chest's contents survive")
	check(w2.chests.info(w2.chests.unit(other.id)).store.count("log") == 4, "a stash survives")
	check(w2.chests.lock_of(w2.chests.unit(f.id)).level == 3, "an owner's lock level survives")
	check(picked_open and not w2.chests.is_locked(w2.chests.unit(f.id)), "a lock picked today is still open after loading")
	var d0: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	d0.erase("chests")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), d0)
	check(w3.chests.locks.is_empty() and w3.chests.stash.is_empty(), "an older save without chests loads with defaults")
