extends SceneTree
## PROP-01: a guest must not cancel someone else's unfinished building
## or choose a different inventory to receive the recovered materials.
var checks := 0
var failures := 0
func check(cond: bool, name: String) -> void:
	checks += 1
	if cond:
		print("ok   " + name)
	else:
		failures += 1
		printerr("FAIL: " + name)
func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 6001)
	w.player.coins = 1000
	var pl: Dictionary = w.plots[0]
	check(w.property.lease(pl, World.PLAYER) == "", "PROP-01: host leases a construction plot")
	w.start_site(pl, "house", World.PLAYER)
	var material := str(pl.site.need.keys()[0])
	w.player.inv.add(material, 1)
	w.deliver(pl, w.player.inv, World.PLAYER)
	check(not pl.site.is_empty() and not bool(pl.site.get("done", false)) and w.site_delivered(pl).has(material), "PROP-01: host site has delivered materials")

	var guest := PlayerState.new()
	guest.name = "Guest"
	guest.family = "Test"
	guest.sex = "female"
	guest.born = w.player.born
	Identity.register_player(w, guest)
	w.give_start_kit(guest)
	guest.net_key = "d".repeat(32)
	guest.pos = Vector2(float(pl.x), float(pl.y))
	w.add_guest(guest)
	var before_guest := guest.inv.count(material)
	var before_site := JSON.stringify(pl.site)
	var r := NetActions.apply_verb(w, guest, "cancel_site", [NetActions.enc(w, pl), {"$inv": "pack"}])
	check(not bool(r.get("ok", false)), "PROP-01: guest cannot cancel host-owned site")
	check(JSON.stringify(pl.site) == before_site, "PROP-01: forged cancellation does not remove host site")
	check(guest.inv.count(material) == before_guest, "PROP-01: forged cancellation does not transfer host materials")

	# Ordinary host-initiated cancellation still refunds exactly what was delivered.
	var before_host := w.player.inv.count(material)
	var returned := w.cancel_site(pl, w.player.inv)
	check(pl.site.is_empty() and int(returned.get(material, 0)) == 1, "PROP-01: rightful owner cancellation clears the site")
	check(w.player.inv.count(material) == before_host + 1, "PROP-01: rightful owner gets exactly one material back")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
