class_name WikiHomestead
extends RefCounted
## B25R1-010 (owner directive 2026-11-03): the wiki's pages for homesteading in the open country, what is built: the player's
## claim, house, chest and bed; and, under "Not in the game yet", villagers choosing to homestead (their decision awaits the
## owner) and what a homestead cannot have yet. Numbers from balance.json "homestead" and the house's cost. Called from Wiki.build().


static func add_pages(w: Wiki) -> void:
	var cf: Dictionary = GameData.b("homestead")
	var cost: Dictionary = GameData.b("house_cost")
	var ids: Array = cost.keys()
	ids.sort()
	var cost_text := ", ".join(ids.map(func(id): return "%d %s" % [int(cost[id]), GameData.item_name(str(id)).to_lower()]))
	w.add_page("guide:homestead", "How do I make a homestead in the open country?", "guides", [
		Wiki.p("Walk out of the village into open country, well away from the village and from the other settlements, and off the roads. Stand where you want the door of your house and face north: the target says Claim this land and mark out a homestead here when the ground is free to claim. Use it. The land is yours without paying anyone, and a frame for a house is marked out north of you."),
		Wiki.p("A homestead house is the village's own house and takes the same materials: %s. Bring them to the frame (stand at its door step and Use it); you can bring them a few at a time. Trees standing on the house's ground must be felled first: the logs are yours; stumps and saplings there are grubbed up for you. When the last load is in and the ground is clear, the house stands." % cost_text),
		Wiki.p("Walk in through the door. The chest inside is yours to store things in, and you can sleep in its beds. Your homestead is saved with your game and stays where you built it."),
		Wiki.links(["sys:homesteads", "sys:property"])], "", "homestead land claim country house build wilderness")
	w.add_page("sys:homesteads", "Homesteads in the open country", "systems", [
		Wiki.p("Land outside the village's and every settlement's land may be claimed for a homestead without buying it. Claiming does not make a village or a new lordship, and nobody collects rent for it."),
		Wiki.bullets([
			"Not claimable: the village and the country close round it (about %d tiles), the land round each neighbouring settlement (about %d tiles), the roads and the ground beside them, other people's claims, cliffs, mountain tops and rocks." % [int(cf.village_control), int(cf.site_control)],
			"A few trees on the house's ground are fine (at most %d): fell the grown ones before the house can stand; the rest are cleared." % int(cf.max_clear),
			"Nothing is free: every plank, block and log is one you gathered or bought, and the house goes up only when all of it is in.",
			"You can have one unfinished homestead at a time.",
			"The country is not safe: animals live in the woods out there and there is nobody to call for help. A homestead far from the village means a long walk to market.",
			"A homestead you have claimed, or one you come near, is one you know of."]),
		Wiki.links(["guide:homestead", "sys:property"])], "", "homestead claim wilderness land country")
	w.add_page("todo:homestead_more", "Villagers' homesteads, and more for a homestead", "notyet", [Wiki.note("Not in the game yet. Villagers do not yet decide to leave the village and make homesteads of their own: how they will choose is waiting for a decision. A homestead has only its house: no extra rooms, lofts, workshops, fields or pens out in the country yet, and no hired helpers carry materials there.")], "", "not implemented planned homestead")
