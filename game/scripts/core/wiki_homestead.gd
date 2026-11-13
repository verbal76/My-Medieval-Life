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
			"A bandit may leave the band for an ordinary life, keeping what they carry and what they did. One with a family on a homestead of their own may give up raiding and stay on the land.",
			"A homestead household that is starving on its land may turn to living outside the law instead of coming back: the same people and house, an outlaw homestead now."]),
		Wiki.links(["sys:homesteads", "guide:homestead", "sys:outlaw_camp", "sys:wild_water"])], "", "runaway bandit homestead leave home outlaw")
	var wc: Dictionary = GameData.b("wilds")
	var well: Dictionary = wc.well_cost
	var wids: Array = well.keys()
	wids.sort()
	w.add_page("sys:wild_water", "Water out in the country", "systems", [
		Wiki.p("Everyone living out in the country needs water every day. A homestead draws it from a stream close by, or from a well dug on its land. Land with no water near, where the household cannot pay for a well's materials, is not chosen for a homestead."),
		Wiki.bullets([
			"A well takes %s, carried to the spot, and then a long day's digging." % ", ".join(wids.map(func(id): return "%d %s" % [int(well[id]), GameData.item_name(str(id)).to_lower()])),
			"Somebody of the household walks to the water and fetches it; the household keeps a little in store.",
			"A day without water hurts everybody who went without, and a homestead that stays dry for several days is given up."]),
		Wiki.p("At your own homestead's door you can also fence a pen beside the house (for animals you buy from the village's keepers) and mark out a smithy or a carpentry workshop: bring their materials, fell any trees on the ground, then Use them to build. A finished workshop's forge, anvil, bench or sawhorse are yours to craft at. A pen is staked out at its corners until its logs are in and the work is done; then it is fenced all round, with a gate in the middle of its bottom side where you feed the animals. The fence keeps people out; walk in through the gate."),
		Wiki.p("On your own homestead you can dig a well too: stand on your claim's land beside the house and Use Mark out a well here, bring its stone and logs, then Use it again and again to dig. You can see how far it has come: a patch of dug earth with the stone heaped beside it while materials are still wanted, then the stone ring of the shaft while you dig, then the finished well."),
		Wiki.links(["sys:homesteads", "sys:leaving_home"])], "", "water well stream drink homestead thirst")
	w.add_page("sys:outlaw_camp", "The bandits' camp in the wild", "systems", [
		Wiki.p("The bandits do not live by the village. They are a household of their own at a hidden camp out in the open country, off the roads and in cover. You only find it when you come close."),
		Wiki.bullets([
			"They live there as any homestead does: they build a house from real materials, fetch water, fell trees, grow food, keep animals and walk to market.",
			"Now and then they raid: some of them walk the road to the village in the afternoon, wait for dark by the old camp ground and rob whoever they catch outdoors, then go home with what they took. A hungry, poor band raids more often than a fed one; guards and wounds make them think twice.",
			"An outlaw with a smith's skill can work at a smithy built at the camp and make weapons the ordinary way, from real metal and tools. The band sells what it makes to its own; it trades with an outsider only one it trusts. A trusted friend who talks to an outlaw at the camp can buy the weapons and tools they carry beyond the one of each they keep; a stranger is eyed warily and turned away.",
			"The camp keeps a fire as every household does: it burns a log each night, and a night without one is a cold one. The band buys firewood at market when it can pay; with no axe, one of them gathers fallen branches and deadwood from the grown trees near the camp instead, an hour's work for one log. A tree that has given its wood has none to give again for some days, so the wood near the camp can run out and the fire with it.",
			"The camp is defended by the people who live there: they fight or flee. Whatever is in its stores, or on its people, is really there: take it and it is theft.",
			"Children born at the camp grow up in the band; at coming of age they may leave for kin in the village."]),
		Wiki.links(["sys:leaving_home", "sys:wild_water", "sys:homesteads"])], "", "bandit camp outlaw raid hideout smith wild firewood deadwood fire")
	w.add_page("todo:homestead_more", "More for a homestead", "notyet", [Wiki.note("Not in the game yet. No extra rooms or lofts go up out in the country, and no hired helpers carry materials there. Streams are not yet in the open country; until they come, every homestead digs a well.")], "", "not implemented planned homestead")
