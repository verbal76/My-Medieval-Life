extends SceneTree
## PL2-008 and PL2-014: a modular property. Lease a plot, build a house, add a workshop and a kitchen
## later, then living quarters and a storeroom: every module is a building against the others on the
## same property with its own door, stations and roof; nothing earlier is pulled down; materials, rent
## and footprint are accounted; the rooms work, are reachable and survive a save. Pure World. Run:
##   godot --headless --path game --script res://tests/property_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func _init() -> void:
	test_modules()
	test_rules()
	test_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Finish a site at once with the materials it needs.
func finish(w: World, pl: Dictionary) -> void:
	for id in pl.site.need.duplicate():
		w.player.inv.add(id, int(pl.site.need[id]))
	w.deliver(pl, w.player.inv, World.PLAYER)


func reachable(w: World, b: Dictionary) -> bool:
	var sp = w.map.data.spawns.player
	var step := Vector2i(int(b.door[0]), int(b.door[1]) + 1)
	return not w.map.is_solid(step) and not w.map.find_path(step, Vector2i(int(sp[0]), int(sp[1]))).is_empty()


## Fell the trees around a plot (felling is its own mechanic; the modules need the ground clear).
func fell_around(w: World, pl: Dictionary) -> void:
	var box := Rect2i(int(pl.x) - 40, int(pl.y) - 40, int(pl.w) + 80, int(pl.h) + 80)
	for t in w.trees:
		if box.has_point(Vector2i(int(t.x), int(t.y))):
			t.state = "cleared"
			w.map.set_solid(Vector2i(int(t.x), int(t.y)), false)


## A house on leased open ground (not a survey plot), trees felled around it; returns its parcel.
func open_property(w: World) -> Dictionary:
	w.player.coins = 5000
	var c: Construction = w.construction
	var pl := c.place("house", c.find_ground("house", Vector2i(30, 30), World.PLAYER), World.PLAYER, true)
	finish(w, pl)
	fell_around(w, pl)
	return pl


## A leased plot with a finished house; returns the world.
func house_world() -> World:
	var w := new_world()
	w.player.coins = 2000
	var pl: Dictionary = w.plots[0]
	check(w.property.lease(pl, World.PLAYER) == "", "the plot is leased from the manor")
	w.start_site(pl, "house", World.PLAYER)
	finish(w, pl)
	fell_around(w, pl)
	return w


func test_modules() -> void:
	var w := house_world()
	var c: Construction = w.construction
	var pl: Dictionary = w.plots[0]
	var house: Dictionary = w.buildings["house_plot0"]
	var rent0 := w.property.rent_of(pl)
	var wall0 := w.map.is_solid(Vector2i(int(pl.x), int(pl.y) + 4))
	var floor0: Array = (w.interiors["house_plot0"].floor as Array).duplicate(true)
	check(not w.property.building_on(pl).is_empty() and w.property.estate_parcels(pl).size() == 1, "the house stands: a property of one building")
	check(c.may_build("carpentry", World.PLAYER, pl) == "" and c.may_build("storage", World.PLAYER, pl) == "", "any module may be added to a finished house (no choice is final)")
	# a workshop added later
	var slot := c.find_module_slot("carpentry", pl, World.PLAYER)
	check(slot.size == c.footprint("carpentry"), "there is legal ground against the house for a workshop (%s)" % str(slot))
	var coins0 := w.player.coins
	var m1 := c.place("carpentry", slot, World.PLAYER, false, pl)
	check(not m1.is_empty() and w.property.estate_id(m1) == "plot0" and w.player.coins == coins0 - w.property.land_price(slot.size.x, slot.size.y), "the carpenter's shop is marked out on bought ground, the same property (%s)" % c.why)
	check(w.property.estate_parcels(pl).size() == 2 and w.property.has_module(pl, "carpentry"), "the property now has two parcels, one a carpenter's shop site")
	check(c.may_build("kitchen", World.PLAYER, pl) != "", "no second building starts while one is going up")
	var cost: Dictionary = c.cost_of("carpentry")
	finish(w, m1)
	var shop := w.property.building_on(m1)
	check(str(shop.kind) == "carpentry" and str(shop.parcel) == str(m1.id) and w.owner_of(shop) == World.PLAYER, "the shop stands, the player's")
	for id in cost:
		check(w.stats.get("used_building_" + id, 0.0) >= float(cost[id]), "its %s are counted as used" % id)
	check(w.stations.has("ws_workshop_%s_workbench" % m1.id) and w.stations.has("ws_workshop_%s_sawhorse" % m1.id), "its workbench and sawhorse work stations")
	check(w.station_refusal("ws_workshop_%s_workbench" % m1.id) == "", "the player may use the workbench")
	check(reachable(w, shop) and reachable(w, house), "both doors are reachable from the village")
	check(w.map.is_solid(Vector2i(int(m1.x), int(m1.y) + 4)) or w.map.is_solid(Vector2i(int(m1.x) + 1, int(m1.y) + 4)), "the shop has solid walls")
	check(w.interiors.has(str(shop.id)) and w.place_of(Vector2(int(m1.x) + 4.5, int(m1.y) + 4.5)) == str(shop.id) and w.roof_over(Vector2(int(m1.x) + 4.5, int(m1.y) + 4.5)) == str(shop.id), "it has its own inside and its own roof")
	# earlier investment is untouched
	check(w.buildings.has("house_plot0") and w.buildings["house_plot0"] == house and w.map.is_solid(Vector2i(int(pl.x), int(pl.y) + 4)) == wall0 and w.interiors["house_plot0"].floor == floor0, "the house, its walls and its rooms are as they were")
	check(w.property.rent_of(pl) == rent0 and w.tenant_of(pl) == World.PLAYER and w.tenant_of(m1) == "", "the house keeps its lease; the bought shop ground has none")
	# the same on open ground (the survey plots are boxed in by roads and houses): a house on leased
	# ground, then a kitchen (leased), living quarters and a storeroom
	var w2 := new_world()
	var pl2 := open_property(w2)
	c = w2.construction
	var hid := "house_" + str(pl2.id)
	check(w2.property.building_on(pl2).kind == "house" and w2.tenant_of(pl2) == World.PLAYER, "a house stands on leased open ground")
	var rent_house := int(pl2.rent)
	var k := c.find_module_slot("kitchen", pl2, World.PLAYER)
	check(k.size == c.footprint("kitchen"), "there is ground for a kitchen (%s)" % str(k))
	var m2 := c.place("kitchen", k, World.PLAYER, true, pl2)
	check(not m2.is_empty() and w2.tenant_of(m2) == World.PLAYER and int(m2.rent) == w2.property.rent_of(m2) and int(m2.rent) > 0, "the kitchen's ground is leased: its own rent of %d a week (%s)" % [int(m2.get("rent", 0)), c.why])
	finish(w2, m2)
	check(w2.stations.has("ws_workshop_%s_stove" % m2.id) and reachable(w2, w2.property.building_on(m2)), "the kitchen has a stove and a way in")
	check(int(pl2.rent) == rent_house, "the house's own rent is unchanged by the room (%d)" % rent_house)
	# living quarters add beds; a storeroom adds a chest
	var beds0 := c.beds_in(hid)
	var m3 := c.place("quarters", c.find_module_slot("quarters", pl2, World.PLAYER), World.PLAYER, false, pl2)
	check(not m3.is_empty(), "living quarters are marked out (%s)" % c.why)
	finish(w2, m3)
	check(c.beds_in(hid) > beds0 and w2.property.rooms_of(hid).size() == 2, "the quarters add beds to the house (%d -> %d)" % [beds0, c.beds_in(hid)])
	var m4 := c.place("storage", c.find_module_slot("storage", pl2, World.PLAYER), World.PLAYER, false, pl2)
	check(not m4.is_empty(), "a storeroom is marked out (%s)" % c.why)
	finish(w2, m4)
	check(w2.property.rooms_of(hid).size() == 3 and w2.property.estate_buildings(pl2).size() == 4, "four buildings, one property; the house has three rooms to sleep and store in")
	for b in w2.property.estate_buildings(pl2):
		check(reachable(w2, b), "%s is reachable" % str(b.id))
	check(c.may_build("kitchen", World.PLAYER, pl2) != "" and c.may_build("smithy", World.PLAYER, pl2) == "" and c.may_build("apothecary", World.PLAYER, pl2) == "", "no profession lock-in: a smithy and an apothecary can still be added, but not a second kitchen")
	check(w2.property.end_lease(pl2, World.PLAYER) != "", "the house's lease cannot end while rooms stand on the property")
	var sold := w2.property.sell(m3, World.PLAYER)
	check(sold == "" and w2.owner_of(m3) == World.MANOR, "a room can be sold back on its own (%s)" % sold)
	check(w2.buildings.has(hid) and w2.interiors.has(hid), "the house is still there")


func test_rules() -> void:
	var w := new_world()
	var c: Construction = w.construction
	w.player.coins = 2000
	var pl: Dictionary = w.plots[0]
	check(c.may_build("kitchen", World.PLAYER, pl) != "" and c.may_build("storage", World.PLAYER) != "" and c.may_build("quarters", World.PLAYER) != "", "a room is not built before the property exists, and storage and quarters do not stand alone")
	check(c.may_build("house", World.PLAYER) == "" and c.may_build("smithy", World.PLAYER) != "", "a new property starts with a house (the owner's rule), a standalone shop only after a house")
	w.property.buy(pl, World.PLAYER)
	w.start_site(pl, "house", World.PLAYER)
	check(c.may_build("smithy", World.PLAYER, pl) != "", "nothing is added before the first building stands")
	finish(w, pl)
	fell_around(w, pl)
	var far := Rect2i(40, 40, 9, 10)
	check(c.can_place("smithy", far, World.PLAYER, pl) != "", "a module far from the property is refused (it must stand against it)")
	var onto := Rect2i(int(pl.x), int(pl.y) + int(pl.h), 9, 10)
	check(c.can_place("smithy", onto, World.PLAYER, pl) != "", "a module may not cover the house's door")
	# another family's property cannot be added to
	var stranger := World.new()
	stranger.setup(VillageMap.load_default(), 1)
	var sp: Dictionary = stranger.plots[0]
	check(stranger.construction.may_build("smithy", World.PLAYER, sp) != "", "land that is not yours cannot be built on")
	# the footprint of every module is its stamp's, and every module kind has a stamp and a cost
	for kind in Construction.MODULES:
		check(w.map.data.stamps.has(Construction.stamp_name(kind)) and not c.cost_of(kind).is_empty(), "%s has a stamp and a cost" % kind)
	for kind in ["smithy", "carpentry", "bakehouse", "kitchen", "apothecary"]:
		check(not c.stations_of_kind(kind).is_empty(), "%s has working stations" % kind)


func test_save() -> void:
	var w := new_world()
	var pl := open_property(w)
	var c: Construction = w.construction
	var m1 := c.place("bakehouse", c.find_module_slot("bakehouse", pl, World.PLAYER), World.PLAYER, false, pl)
	finish(w, m1)
	var m2 := c.place("quarters", c.find_module_slot("quarters", pl, World.PLAYER), World.PLAYER, true, pl)
	check(not m1.is_empty() and not m2.is_empty(), "two rooms are added before saving, one of them still a site")
	var hid := "house_" + str(pl.id)
	var d: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	var m := VillageMap.load_default()
	w2.load_dict(m, d)
	var pl2: Dictionary = w2.plot(str(pl.id))
	check(w2.property.estate_parcels(pl2).size() == 3 and w2.property.estate_id(w2.plot(str(m2.id))) == str(pl.id), "the property loads with its three parcels")
	check(w2.buildings.has(hid) and w2.buildings.has("workshop_" + str(m1.id)) and w2.interiors.has("workshop_" + str(m1.id)), "the house and the bakehouse load with their insides")
	check(w2.stations.has("ws_workshop_%s_oven" % m1.id), "the oven works after loading")
	check(not w2.plot(str(m2.id)).site.is_empty() and not w2.plot(str(m2.id)).site.done, "the quarters' site is kept")
	var mid := Vector2i(int(m1.x) + 4, int(m1.y) + 4)
	check(m.is_solid(Vector2i(int(m1.x), int(m1.y) + 4)) and w2.place_of(Vector2(mid) + Vector2(0.5, 0.5)) == "workshop_" + str(m1.id), "collision and insides are rebuilt from the save")
	check(w2.construction.may_build("quarters", World.PLAYER, pl2) != "", "one quarters at a time: the site counts")
	finish(w2, w2.plot(str(m2.id)))
	check(w2.construction.beds_in(hid) > 3 and w2.property.rooms_of(hid).size() == 2, "after loading, the quarters can be finished and add beds")
	# a save with no estate field (a version-14 save) loads: every parcel is its own property
	var old: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	for p in old.plots:
		p.erase("estate")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), old)
	check(w3.property.estate_parcels(w3.plot(str(pl.id))).size() == 1 and w3.buildings.has(hid), "an older save without estates still loads, each parcel on its own")
