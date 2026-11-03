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
	w.add_page("sys:leaving_home", "Leaving home: homesteaders, runaways and outlaws", "systems", [
		Wiki.p("Villagers make the big choices of their lives themselves, weighing what they want and what they fear."),
		Wiki.bullets([
			"A young adult setting up a household may choose a homestead in the open country instead of a home in the village, and very rarely an established adult does after a hard turn in life. Few ever go: the village needs its people.",
			"A homestead household clears its land, buys and carries the materials, builds its house, grows a field on its land, fells or quarries for sale and walks to the village market. If it cannot feed itself or finish its house it gives up and comes back.",
			"A young person in a household that has gone hungry and poor for years, or has lost a parent or its home, may leave: to relatives or another household who will take them in, to a neighbouring settlement, to fend for themselves, or to the bandits' camp. Children under 12 hardly ever do.",
			"The bandits decide whom they take in: a grown recruit may join the band, a child may be kept at the camp but never made to fight, and many are sent away.",
			"A bandit may leave the band for an ordinary life, keeping what they carry and what they did."]),
		Wiki.links(["sys:homesteads", "guide:homestead"])], "", "runaway bandit homestead leave home outlaw")
	w.add_page("todo:homestead_more", "More for a homestead", "notyet", [Wiki.note("Not in the game yet. A homestead has only its house and its field: no extra rooms, lofts, workshops or pens out in the country yet, no wells, and no hired helpers carry materials there. The bandits still live at their camp by the village.")], "", "not implemented planned homestead")
