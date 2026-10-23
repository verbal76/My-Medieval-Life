class_name WikiProperty
extends RefCounted
## The wiki's pages for the modular property (PL2-008, PL2-014): how a house grows into a homestead,
## one page for each room that can be added, and the rules in a few lines. Called from Wiki.build();
## every number comes from the game's own data (balance.json, the building stamps).


static func add_pages(w: Wiki) -> void:
	var cost_text := func(kind: String) -> String:
		var cost: Dictionary = GameData.b("house_cost") if kind == "house" else (GameData.b("workshop_cost") as Dictionary).get(kind, {})
		var ids: Array = cost.keys()
		ids.sort()
		return ", ".join(ids.map(func(id): return "%d %s" % [int(cost[id]), GameData.item_name(str(id)).to_lower()]))
	var village: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/village.json"))
	var stations_text := func(kind: String) -> String:
		var st: Dictionary = village.stamps.get(Construction.stamp_name(kind), {})
		var names: Array = []
		for s in st.get("stations", []):
			names.append(str(Wiki.STATION_NAMES.get(str(s.type), str(s.type))).to_lower())
		return " and ".join(names)
	var price := func(kind: String) -> int:
		return int((GameData.b("module_price") as Dictionary).get(kind, GameData.b("workshop_price")))
	var rent_pct := roundi(float(GameData.b("weekly_rent_share")) * 100.0)
	w.add_page("sys:property_modules", "Growing a property: rooms and workshops", "systems", [
		Wiki.p("A property starts with a house on ground you lease or buy from the manor. Nothing about it is final: later you can add rooms and workshops against what already stands, one at a time, without pulling anything down."),
		Wiki.p("Open the Build menu (H) and choose Open beside your property, or walk up to your house and use the ground. Each room is Choose a place: the footprint (9 by 10 tiles; a small room 5 by 6) must stand against a building of the property, share at least %d tiles of wall with it, leave every door clear and have a clear way to its own door. Trees in the way must be felled first. Roads, other people's land, houses and fields are not available." % Construction.ATTACH_MIN),
		Wiki.p("Each room is its own piece of ground, bought or leased from the manor on the spot like any ground, and its own frame: bring the materials (or hire a helper) and it stands when the last load is in. Its rent is its own, about %d%% of what it is worth a week, so a bigger property costs more rent; the house's lease is untouched. A room is worth less than a fresh building but can be sold back on its own. The first building (the house) cannot be sold or given up while rooms stand on the property." % rent_pct),
		Wiki.bullets([
			"One room of each kind to a property; a room being built must be finished before the next is begun.",
			"Rooms are separate buildings with their own door, walls, roof and inside; the roof of the one you stand in fades. Their stations work as anywhere else.",
			"Where two rooms of your property stand side by side, a doorway is cut through the wall they share, so you can walk from one into the other without going out into the street. It opens only where nothing is in the way on either side (the wall must be bare and the floor inside it free and reachable), so it appears when the second room is finished, and not at all if furniture lines the wall. A house's east wall is lined with furniture, so a room to its east gets no doorway; the suggested place for a new room goes to the house's west side when that gives one. Rooms one above the other have a yard between them and no doorway. Nothing in either room is moved, and the street doors stay.",
			"No room ties you to a trade: anyone may use a forge, an oven or a workbench they have leave to use, and a house can have a smithy, a kitchen and a bakehouse together.",
			"A standalone shop (a workshop on its own ground) is still possible once you own a house; it just does not need to be. Storerooms and living quarters only come as rooms of a property.",
			"Older saves load as they were: every existing building is a property of its own."]),
		Wiki.links(["guide:property_rooms", "sys:property", "guide:rent", "station:forge", "station:stove", "station:workbench"])])
	var kinds := {
		"smithy": "A forge for smelting and an anvil for forging, in a room of its own.",
		"carpentry": "A workbench and a sawhorse: planks are sawn at the sawhorse.",
		"bakehouse": "An oven for roasting and a stove for cooking and brewing.",
		"kitchen": "A stove for cooking pottage and brewing ale; a smaller room than the bakehouse.",
		"apothecary": "A stove set apart for brewing the poultices and tonics, with a chest and tables for the herbs.",
		"storage": "A bare room with a chest and tables. Standing at its chest opens the family chest, so what you keep is at hand from either room.",
		"quarters": "More beds: the beds of living quarters count as the house's, so a household can grow without having to split and leave.",
		"room": "Two beds in a room a third the size of living quarters, for a house with too little ground beside it for them. Its beds count as the house's, like the quarters'."}
	var pages: Array = []
	for kind in Construction.MODULES:
		var st: String = stations_text.call(kind)
		var id: String = "property:" + str(kind)
		pages.append(id)
		w.add_page(id, World.cap(Construction.kind_name(kind)) + " (a room to add)", "systems", [
			Wiki.p(kinds[kind]),
			Wiki.stats([["Materials", cost_text.call(kind)], ["Worth with its ground", "%d coins" % price.call(kind)], ["Stations", st if st != "" else "none"],
				["Ground", "%d by %d tiles, against the property" % [int(village.stamps.get(Construction.stamp_name(kind), {}).get("w", 9)), int(village.stamps.get(Construction.stamp_name(kind), {}).get("h", 10))]]]),
			Wiki.links(["sys:property_modules", "guide:property_rooms"] + (["station:" + str(village.stamps.get(Construction.stamp_name(kind), {}).get("stations", [{"type": "stove"}])[0].type)] if st != "" else []))],
			"", "room module add property " + str(kind))
	w.add_page("guide:property_rooms", "Add a room or workshop to my house", "guides", [
		Wiki.p("Lease or buy ground and build a house (Build menu). When it stands, open the Build menu again: your property is listed with Open. It shows the rooms you have and each room you can add, with its materials."),
		Wiki.p("The two plots the manor sells in a new village lie on open ground in the north-east, with room on every side for rooms (a side with trees waits until they are felled); a village saved before keeps its plots where they were. Choose a place, move the footprint against the house (it starts at the nearest ground that works, preferring a place where a doorway between the rooms can be cut) and place it. It turns red with the reason where it cannot go: a tree to fell, a road, a house, or a door it would block."),
		Wiki.p("When it is placed, the ground is yours (or leased) and the frame is up. Deliver the materials. The room's stations appear at once when it is finished."),
		Wiki.links(pages + ["sys:property_modules"], "The rooms")])
