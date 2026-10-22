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
		Wiki.p("The mine is a rocky hill north of the village, a quarry face of bare stone with ledges along its top. The timbered adit is cut into its south face; a rail track runs from it down to the cart stop in the dirt yard, and the ore seams lie in the yard either side of the track. Walk into the adit to go below into the gallery; a second opening a little west of it leads to the cave. Boulders stand on the highland above."),
		Wiki.p("You cannot climb the hill: the rock is solid. Work the seams from the yard with a pickaxe (the smith sells them), or go below through the adit or the cave's mouth. Gold needs Mining level 3. Trees do not grow on or beside the rim. Mining and quarrying has the rules, and the underground pages what is below."),
		Wiki.links(["sys:mining", "sys:mining_underground", "sys:open_pits", "item:pickaxe", "recipe:forge_pickaxe", "skill:mining", "job:miner"]),
	]
	if not seams.is_empty():
		blocks.append(Wiki.links(seams, "Seams and boulders"))
	w.add_page("place:mine", "The mine", "systems", blocks, "", "quarry rock adit seams track yard")
	_countryside(w)


# Countryside (animals_near, travellers_near, chunk_animals, _caravan); balance.json "countryside".
static func _countryside(w: Wiki) -> void:
	var c := Countryside.cfg()
	w.add_page("place:countryside", "The countryside", "systems", [
		Wiki.p("Beyond the village the land goes on: meadows, woods, hills and mountains, crossed by dirt trails. It is not empty. Wild animals live out there: rabbits, birds, deer, foxes and, in the denser woods, boar. They wander about near where they live, stroll a little, then stand and graze, and the same ones are always found in the same places."),
		Wiki.p("Travellers use the trails. Pedlars carrying a pack, pilgrims and wayfarers come in along the trails towards the village gates, stop at the gate for a short while, then turn round and walk back the way they came. Most set out in the morning and early afternoon, so the trails are quiet at night. On the caravan's visit days (see the merchant caravan) its wagon and driver come in along a trail in the morning and leave along it in the evening."),
		Wiki.h("What they are"),
		Wiki.p("They are scenery, not part of the village. You cannot talk to the travellers, trade with them, rob them or hurt them, and you cannot hunt the animals of the countryside; the village's own woods are where the game is. Travellers carry no coins or goods that you can get, and nothing they do changes the village's money, food or people. Wolves and bears are not out in the countryside: nothing out there bites."),
		Wiki.p("Only what is near you is shown, a handful at a time. Where the countryside goes, nobody can follow: the towns the travellers come from are not on the map."),
		Wiki.links(["sys:caravan", "place:mine", "todo:other_towns"])],
		"countryside overworld wild animals travellers pedlar pilgrim wayfarer trails roads gate caravan wagon deer fox rabbit boar bird")
