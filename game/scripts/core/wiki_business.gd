class_name WikiBusiness
extends RefCounted
## Wiki pages for the player's market stall (PL1-10): the "How do I sell from my own stall?" guide and the
## system page. Registered by one line in Wiki.build(); the numbers come from balance.json.


static func add_pages(w: Wiki) -> void:
	var rent := int(GameData.b("stall_rent_day"))
	var range_t := int(GameData.b("stall_range"))
	var evict := int(GameData.b("stall_evict_days"))
	w.add_page("guide:stall", "How do I sell from my own stall?", "guides", [
		Wiki.p("Find an open pitch in the market (beside the merchants' stalls) and press Use: \"Rent this market pitch\" costs %d coins a day, the first day at once." % rent),
		Wiki.bullets([
			"Open the stall again later with Use: \"Manage your market stall\".",
			"Put up: choose an item from your pack and how many. It moves into the stall's stock, priced at its market value.",
			"Price: type a number or use - and +. You may ask from 1 coin up to %d times the market value." % Business.PRICE_CAP,
			"Take back moves goods to your pack again; Close the stall returns everything, and the till too.",
			"Sales are paid into the till; press Collect to take the coins.",
			"Stand at the stall (within %d tiles) for villagers to buy: nobody buys while you are away, and there is no attendant yet." % range_t,
			"Rent is taken each morning from your coins, then the till. If you cannot pay, sales stop; after %d unpaid days the manor takes the pitch back and your goods and coins return to you." % evict,
		]),
		Wiki.p("Villagers buy only what they really need and can pay for: the smith ore and coal, the carpenter and builders planks, stone and logs, miners and woodcutters a missing tool, guards their gear, households firewood and food. They will not pay more than they would at the merchants, and they stop buying once the need is met."),
		Wiki.links(["sys:trading", "guide:money", "job:merchant"])], "", "market stall rent sell shop business")
	w.add_page("sys:stall", "Your market stall", "systems", [
		Wiki.p("An optional business: rent a pitch, stock it from your pack, set prices, and sell to villagers who need your goods. See the guide for the steps."),
		Wiki.stats([["Rent", "%d coins a day" % rent], ["Listings", "up to %d kinds of goods" % int(GameData.b("stall_max_listings"))],
			["Sales", "only while you stand within %d tiles" % range_t], ["Unpaid rent", "stopped, then reclaimed after %d days" % evict]]),
		Wiki.note("Not yet: larger stalls, shops, equipment placement and hired attendants (later stages)."),
		Wiki.links(["guide:stall"])], "", "market stall business demand")
