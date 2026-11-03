extends SceneTree
## LE-07 (Living Economy release readiness; design s.16 "Test strategy and release acceptance", s.17 gate "All mandatory release
## gates green") and the activation mechanism (X20-ACTIVATION-AUTHORITY, owner 2026-10-31: "Prepare the activation mechanism and
## validation evidence, but wait for my explicit authorization before enabling it in the normal game"). The gates that can be
## automated in a short headless run; the long ones (multi-seed year runs, profiling on a phone, platform builds) are the lead's
## (docs/expansion20/ACTIVATION.md, the checklist). Never enables the economy in the shipped data: the switch is a test override.
##   default   the shipped switch is on (B25-LE-ACTIVATE-D1); with it off nothing is built or saved; reserved switches stay off
##   accounting  a day with the economy on: every coin accounted for (the world's coins less what crossed its boundary never moves)
##   determinism two runs of the same seed and code give the same fingerprint (economy_sim's)
##   persistence the economy section saves and loads exactly
##   bounded   the saved records stay within their configured bounds
##   activation  a Build 24 save (save_version 23) switched on: nothing else in it changes, the economy starts empty and runs with the
##             ledger exact; an economy save switched off: the section is parked unchanged, its escrow still counted; on again: resumed
## Run headless:  godot --headless --path game --script res://tests/le07_gates_test.gd

const STEP := 0.5
const SEED := 2

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func on_cfg() -> Dictionary:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	c.enabled = true
	return c


func new_world(on: bool) -> World:
	EconomyFoundation.set_override(on_cfg() if on else EconomyFoundation.off_config())
	var w := World.new()
	w.setup(VillageMap.load_default(), SEED)
	return w


func run(w: World, hours: float) -> void:
	var steps := int(hours * 60.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	for i in steps:
		w.update(STEP)
		w.player.hunger = 100.0              # the idle player is fed, as in economy_sim


func ledger(w: World) -> int:
	return w.total_coins() - w.coin_sources


## economy_sim's fingerprint (the determinism gate's measure, PERF-03).
func fingerprint(w: World) -> String:
	var parts := PackedStringArray([str(w.minutes), str(w.treasury), str(w.coin_sources), str(w.rng.state), str(w.granary.items)])
	for n: NPC in w.npcs:
		parts.append("%d|%s|%d|%s|%s|%s|%s" % [n.id, n.alive, n.coins, n.pos, n.hunger, n.job, n.inv.items])
	for a: Animal in w.fauna.animals:
		parts.append("%d|%s|%s" % [a.id, a.pos, a.hunger])
	for dp in w.deposits:
		parts.append(str(dp.amount))
	for hh in w.households:
		parts.append(str(hh.pantry.items))
	return "|".join(parts).md5_text()


func _init() -> void:
	test_default()
	test_running_gates()
	test_activation_old_save()
	test_activation_current_save()
	test_switch_off_and_on()
	EconomyFoundation.set_override({})
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func test_default() -> void:
	EconomyFoundation.set_override(EconomyFoundation.off_config())
	var shipped: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	check(bool(shipped.get("enabled", false)), "the shipped switch is on (economy.json enabled true; B25-LE-ACTIVATE-D1, owner 2026-11-01)")
	var m: Dictionary = shipped.market
	check(not bool(m.get("services", true)), "market.services stays off and empty (CON-03..08 are built in contract_services.gd, outside it: X20-SERVICES-SCOPE)")
	check(not bool(m.get("negotiated_wages", true)), "market.negotiated_wages stays off (built, not reviewed)")
	var w := new_world(false)
	var st := EconomyFoundation.activation_state(w)
	check(not st.enabled and not st.attached and not st.parked and w.economy == null, "economy off: nothing built")
	check(not w.to_dict().has(EconomyFoundation.KEY), "economy off: no economy key in the save")


func test_running_gates() -> void:
	var a := new_world(true)
	var b := new_world(true)
	check(a.economy != null and EconomyFoundation.activation_state(a).attached, "switch on (test override): the economy is built")
	var c0 := ledger(a)
	run(a, 26.0)
	run(b, 26.0)
	check(ledger(a) == c0, "accounting: a day with the economy on, every coin accounted for (%d -> %d)" % [c0, ledger(a)])
	var fa := fingerprint(a)
	check(fa == fingerprint(b), "determinism: two runs of seed %d give the same fingerprint (%s)" % [SEED, fa.substr(0, 8)])
	var s := JSON.stringify(a.to_dict())
	var back := World.new()
	back.load_dict(VillageMap.load_default(), JSON.parse_string(s))
	check(back.economy != null and JSON.stringify(back.economy.to_dict()) == JSON.stringify(a.economy.to_dict()),
		"persistence: the economy section loads back exactly (%d bytes)" % JSON.stringify(a.economy.to_dict()).length())
	check(ledger(back) == ledger(a), "persistence: the ledger is the same after loading")
	# (no fingerprint gate through save/load: the base game's fingerprint is not kept by a JSON save even with the economy off,
	# e.g. float positions and hunger; LE-06's measure is the economy section's exact load-back, checked above, and the ledger)
	run(back, 3.0)
	check(ledger(back) == ledger(a), "the loaded world runs on with its ledger exact")
	var cfg := on_cfg()
	var ev: Dictionary = a.economy.to_dict()
	check(a.economy.events.ring.size() <= int(cfg.events.capacity) and a.economy.market.deals.size() <= int(cfg.market.keep_deals)
			and a.economy.rentals.records.size() <= a.economy.rentals.keep_closed + a.economy.rentals.open_records().size()
			and a.economy.repairs.records.size() <= a.economy.repairs.keep_closed + a.economy.repairs.open_records().size(),
		"bounded: events, deals, rentals and repairs within their bounds (%d keys saved)" % ev.size())


func test_activation_old_save() -> void:
	var text := FileAccess.get_file_as_string("res://tests/fixtures/b24_save_v23_single.json")
	var d: Dictionary = JSON.parse_string(text)
	check(int(d.get("save_version", 0)) == 23 and not d.has(EconomyFoundation.KEY), "the fixture is a Build 24 save (save_version 23) with no economy section")
	EconomyFoundation.set_override(EconomyFoundation.off_config())
	var off := World.new()
	off.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	EconomyFoundation.set_override(on_cfg())
	var on := World.new()
	on.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(on.economy != null and on.economy.is_empty(), "switched on: the old save loads with an empty economy (nothing to migrate)")
	var a := off.to_dict()
	var b := on.to_dict()
	b.erase(EconomyFoundation.KEY)
	check(JSON.stringify(a) == JSON.stringify(b), "switched on: nothing else in the save changes on loading (no destructive migration)")
	check(on.total_coins() == off.total_coins(), "and every coin is where it was")
	var c0 := ledger(on)
	run(on, 26.0)
	check(ledger(on) == c0, "the activated old save runs a day (through a dawn) with the ledger exact (%d -> %d)" % [c0, ledger(on)])
	check(not on.economy.is_empty(), "and the economy has begun to record (needs, offers, events)")


## LE-07 checklist item 7, second half: a save written by this build with the economy off (the shipped state until activation;
## Build 25's businesses, employment and ventures running, so their records are in it) loads with the switch on with nothing
## else in it changed, and runs through a dawn with the ledger exact. The Build 24 fixture above predates those systems.
func test_activation_current_save() -> void:
	var w := new_world(false)
	run(w, 26.0)
	var text := JSON.stringify(w.to_dict())
	var d: Dictionary = JSON.parse_string(text)
	check(int(d.get("save_version", 0)) == World.SAVE_VERSION and not d.has(EconomyFoundation.KEY),
		"a save of this build with the economy off (save_version %d) has no economy section" % World.SAVE_VERSION)
	EconomyFoundation.set_override(EconomyFoundation.off_config())
	var off := World.new()
	off.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	EconomyFoundation.set_override(on_cfg())
	var on := World.new()
	on.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(on.economy != null and on.economy.is_empty(), "switched on: this build's economy-off save loads with an empty economy")
	var a := off.to_dict()
	var b := on.to_dict()
	b.erase(EconomyFoundation.KEY)
	check(JSON.stringify(a) == JSON.stringify(b), "switched on: nothing else in this build's save changes on loading")
	check(on.total_coins() == off.total_coins(), "and every coin is where it was")
	var c0 := ledger(on)
	run(on, 26.0)
	check(ledger(on) == c0, "the activated save runs a day (through a dawn) with the ledger exact (%d -> %d)" % [c0, ledger(on)])
	check(not on.economy.is_empty(), "and the economy has begun to record")


func test_switch_off_and_on() -> void:
	var w := new_world(true)
	# an open rental (escrow) so switching off has something to park
	var r: NPC = w.npcs.filter(func(n): return n.alive and n.job == "woodcutter")[0]
	var o: NPC = w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.household != r.household and n.job not in ["woodcutter", "smith", "merchant"])[0]
	r.inv.remove("axe", r.inv.count("axe"))
	r.inv.durability.erase("axe")
	r.coins = 100
	o.inv.remove("axe", o.inv.count("axe"))
	o.inv.add("axe", 2)
	o.coins = 20
	var opened := w.economy.rentals.open(r, o, "axe")
	var dep := w.economy.rentals.escrow()
	check(opened.ok and dep > 0, "an open rental holds %d coins in escrow" % dep)
	var c0 := ledger(w)
	var s := JSON.stringify(w.to_dict())
	EconomyFoundation.set_override(EconomyFoundation.off_config())
	var off := World.new()
	off.load_dict(VillageMap.load_default(), JSON.parse_string(s))
	var st := EconomyFoundation.activation_state(off)
	check(off.economy == null and st.parked and int(st.parked_coins) == dep, "switched off: the section is parked with its escrow (%d)" % int(st.parked_coins))
	check(ledger(off) == c0, "switched off: the ledger is exact (the parked escrow is counted)")
	var s2 := off.to_dict()
	check(JSON.stringify(s2.get(EconomyFoundation.KEY, {})) == JSON.stringify(JSON.parse_string(s).get(EconomyFoundation.KEY, {})), "switched off: the section is written back unchanged")
	check(r.inv.count("axe") == 1 and off.npc(r.id).inv.count("axe") == 1, "the rented axe stays with its renter while parked")
	EconomyFoundation.set_override(on_cfg())
	var again := World.new()
	again.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(s2)))
	check(again.economy != null and again.economy.rentals.escrow() == dep and not again.economy.rentals.open_for(World.npc_ref(r.id), "axe").is_empty(),
		"switched on again: the rental resumes where it stood")
	check(ledger(again) == c0, "and the ledger is exact")
