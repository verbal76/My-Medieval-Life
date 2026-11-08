extends SceneTree
## PROP-04: building finished by helper retains the real site owner's family name.
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
	w.setup(VillageMap.load_default(), 8404)
	var guest := PlayerState.new()
	guest.name = "Gwen"
	guest.family = "Blackthorn"
	guest.sex = "female"
	guest.born = w.player.born
	Identity.register_player(w, guest)
	w.give_start_kit(guest)
	guest.net_key = "9".repeat(32)
	w.add_guest(guest)
	var owner_ref := w.player_ref(guest)
	var plot: Dictionary = w.plots[0]
	w.start_site(plot, "house", owner_ref)
	check(str(plot.site.owner) == owner_ref, "PROP-04: construction site belongs to guest")
	for id in plot.site.need.duplicate():
		w.player.inv.add(id, int(plot.site.need[id]))
	w.deliver(plot, w.player.inv, World.PLAYER) # host/helper delivers the last load
	check(bool(plot.site.done), "PROP-04: helper completed the guest site")
	var house: Dictionary = w.buildings.get(str(plot.building), {})
	check(not house.is_empty() and str(house.owner) == owner_ref, "PROP-04: house ownership remains guest's")
	check(str(house.name).contains(guest.family), "PROP-04: house name reflects guest owner's family")
	check(not str(house.name).contains(w.player.family), "PROP-04: host family name is not substituted")
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
