extends SceneTree
## INV-03: a guest may not freely fill a separate player's family chest.
var checks := 0
var fails := 0
func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8503)
	var plot: Dictionary = w.plots[0]
	w.start_site(plot, "house", World.PLAYER)
	for id in plot.site.need.duplicate():
		w.player.inv.add(id, int(plot.site.need[id]))
	w.deliver(plot, w.player.inv, World.PLAYER)
	var house: Dictionary = w.buildings[str(plot.building)]
	w.property.set_home(str(house.id))
	var units := w.chests.units_in(str(house.id))
	check(not units.is_empty(), "INV-03: real family house contains chest units")
	if units.is_empty():
		w.dispose()
		quit(1)
		return
	var unit: Dictionary = units[0]
	check(w.chests.info(unit).access == "own", "INV-03: host may use its own family chest")
	var guest := PlayerState.new()
	guest.name = "Gwen"
	guest.family = "Other"
	guest.sex = "female"
	guest.born = w.player.born
	Identity.register_player(w, guest)
	w.give_start_kit(guest)
	guest.net_key = "8".repeat(32)
	w.add_guest(guest)
	var foreign: Dictionary = w.as_actor(guest, w.chests.info.bind(unit))
	check(foreign.access == "foreign", "INV-03: guest sees host family chest as foreign, not own")
	guest.inv.add("plank", 1)
	var guest_before: int = guest.inv.count("plank")
	var host_before: int = w.player.chest.count("plank")
	var result: String = str(w.as_actor(guest, w.chests.store.bind(unit, "plank", 1)))
	check(result == "That is not yours to fill.", "INV-03: guest cannot freely put goods in another player's chest")
	check(guest.inv.count("plank") == guest_before, "INV-03: rejected store does not consume guest's goods")
	check(w.player.chest.count("plank") == host_before, "INV-03: host chest unchanged")
	check(w.chests.info(unit).access == "own", "INV-03: host retains own access after guest attempt")
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
