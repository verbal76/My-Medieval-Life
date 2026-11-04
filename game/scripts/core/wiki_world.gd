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


# Countryside (animals_near, travellers_near, chunk_animals, _caravan); balance.json "countryside". Villagers on the road: Journeys,
# SeedTravelers (settlements.json "seed_travelers"), RegionTrade.
static func _countryside(w: Wiki) -> void:
	var c := Countryside.cfg()
	w.add_page("place:countryside", "The countryside", "systems", [
		Wiki.p("Beyond the village the land goes on: meadows, woods, hills and mountains, crossed by dirt trails. It is not empty. Wild animals live out there: rabbits, birds, deer, foxes and, in the denser woods, boar. They wander about near where they live, stroll a little, then stand and graze, and the same ones are always found in the same places."),
		Wiki.p("Travellers use the trails. Pedlars carrying a pack, pilgrims and wayfarers come in along the trails towards the village gates, stop at the gate for a short while, then turn round and walk back the way they came. Most set out in the morning and early afternoon, so the trails are quiet at night. On the caravan's visit days (see the merchant caravan) its wagon and driver come in along a trail in the morning and leave along it in the evening."),
		Wiki.p("Not everyone on the road is a passer-by. Real people of the village travel too, on their own errands: a tradesperson walking to a neighbouring settlement to buy what they were told it has, the reeve's envoy on a survey, and, at the start of a new game, %d villagers who set out to buy one ordinary thing at another settlement with their own coins. Each walks the road there, buys from the seller face to face at the settlement's price, and walks home with it to take up their ordinary life again; a seller away on the caravan road is waited for a few mornings, and an item sold out or too dear by then means they come home with nothing. They keep their home, family, work and purse while away. They take food for the road from their household's pantry (at most half of it) and buy more at the settlement for the way home, rest by the road at night and eat from their pack; with no food and no coins they go hungry, and the dangers of the road are theirs too. If what they meant to buy is gone, they buy something else ordinary on sale there." % int(SeedTravelers.cfg().count)),
		Wiki.h("Meeting them"),
		Wiki.p("When you come near one of the countryside's animals it behaves as the village's wild animals do: it runs from you, a boar may turn and fight, and you can hunt it (Attack, or tap it in attack mode) for its meat and hide, as in the village's woods. One you kill is gone for good: the countryside does not breed them back where you hunted. One you leave alone and walk away from goes on living out there."),
		Wiki.p("You can talk to a traveller: walk up and use them, or tap them and you walk over. They are passing through and carry nothing to sell, but they know the roads: ask, and they tell you the way and the distance to each of the settlements, which then show on your Region map."),
		Wiki.p("A villager on the road is met as in the village: walk up and use them, or tap them and you walk over, to talk to them; they stop for a word and say where they are going. While away they trade nothing at home. They can be attacked like anyone else, with the same consequences, and one slain on the road leaves what they carried where they fell."),
		Wiki.p("Trees, rocks and flowers out there are worked just as in the village: tap a tree to fell it with an axe, a rock to break it for stone with a pickaxe, a flower to pick it. Wolves and bears are not out in the countryside. Only what is near you is shown, a handful at a time."),
		Wiki.p("The world goes on where you cannot see it. A villager on an errand walks the whole road and buys what they went for whether you watch or not, so you can meet them anywhere along the way, and they carry on once you have passed. Only what is near your view is drawn and animated: zoom out and more of the world comes to life on the screen. Trees sway a little in the breeze, saplings most."),
		Wiki.p("When a crowd gathers where you are, someone only passing the time (resting, taking the air, at play, keeping company) may go on to what they would do next a little sooner. Nobody leaves an errand, a purchase or their work for it, and nobody you are talking to, trading with or walking up to, nor a trader at their trade or someone with a quest for you, goes anywhere because of a crowd."),
		Wiki.links(["sys:caravan", "place:mine", "todo:other_towns"])],
		"countryside overworld wild animals travellers pedlar pilgrim wayfarer villagers journey errand trails roads gate caravan wagon deer fox rabbit boar bird hunt talk roads directions")
