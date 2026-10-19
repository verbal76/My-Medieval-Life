class_name WikiWorld
extends RefCounted
## Wiki pages about places in the village (B8-004). Registered by one line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	var seams: Array = []
	for id in GameData.resources.get("nodes", {}):
		var n: Dictionary = GameData.resources.nodes[id]
		if str(n.get("category", "")) == "mineral":
			seams.append("node:" + id)
	var blocks: Array = [
		Wiki.p("The mine is a rocky hill north of the village, a quarry face of bare stone with ledges along its top. The timbered adit is cut into its south face; a rail track runs from it down to the cart stop in the dirt yard, and the ore seams lie in the yard either side of the track."),
		Wiki.p("You cannot climb the hill: the rock is solid. Work the seams from the yard with a pickaxe (the smith sells them). Gold needs Mining level 3. Trees do not grow on or beside the rim."),
		Wiki.links(["item:pickaxe", "recipe:forge_pickaxe", "skill:mining", "job:miner"]),
	]
	if not seams.is_empty():
		blocks.append(Wiki.links(seams, "Seams and boulders"))
	w.add_page("place:mine", "The mine", "systems", blocks, "", "quarry rock adit seams track yard")
