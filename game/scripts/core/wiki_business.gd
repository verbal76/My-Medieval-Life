class_name WikiBusiness
extends RefCounted
## Wiki pages for the player's market stall (PL1-10): the "How do I sell from my own stall?" guide and the
## system page. Registered by one line in Wiki.build(); the numbers come from balance.json.


static func add_pages(w: Wiki) -> void:
	var rent := int(GameData.b("stall_rent_day"))
	var range_t := int(GameData.b("stall_range"))
	var evict := int(GameData.b("stall_evict_days"))
	var pct := Stalls.pct()
	w.add_page("guide:stall", "How do I sell from my own stall?", "guides", [
		Wiki.p("Find an open pitch in the market (beside the merchants' stalls) and press Use: \"Rent this market pitch\" costs %d coins a day, the first day at once." % rent),
		Wiki.bullets([
			"Open the stall again later with Use: \"Manage your market stall\".",
			"Put up: choose an item from your pack and how many. It moves into the stall's stock, priced at its market value.",
			"Price: type a number or use - and +. You may ask from 1 coin up to %d times the market value." % Business.PRICE_CAP,
			"Take back moves goods to your pack again; Give up the pitch returns everything, and the till too, after the manor's share.",
			"Sales are paid into the till and wait there while the stall is open. Close the stall to settle them: the manor takes %d%% of the sales, the rest is yours. Open it again whenever you like; it closes by itself when it sells out (see the market stall guide)." % pct,
			"Stand at the stall (within %d tiles) for villagers to buy, or hire an attendant to stand there for you (see the attendant guide). With neither, nobody buys: nothing sells unattended." % range_t,
			"Larger stall: pay %d coins to the manor once for %d kinds of goods instead of %d, a display for one item that draws buyers from further off, and %d coins a day rent instead of %d." % [int(GameData.b("stall_large_cost")), int(GameData.b("stall_large_listings")), int(GameData.b("stall_max_listings")), int(GameData.b("stall_large_rent_day")), rent],
			"The window keeps your revenue, expenses (rent, upgrade, wages) and profit.",
			"The till is the business's money, apart from your purse. Put in and Take out move coins between them whenever you choose; Collect takes the lot. A failing stall never quietly spends your food money.",
			"Rent is taken each morning from the till first (never the open sales), then from your purse, but only from coins above what you keep for food and fuel. If you cannot pay, sales stop; after %d unpaid days the manor takes the pitch back and your goods and coins return to you." % evict,
		]),
		Wiki.p("Villagers buy only what they really need and can pay for: the smith ore and coal, the carpenter and builders planks, building blocks, stone and logs, miners and woodcutters a missing tool, guards their gear, households firewood and food. They will not pay more than they would at the merchants, and they stop buying once the need is met."),
		Wiki.links(["guide:market_stall", "guide:shop", "guide:attendant", "sys:trading", "guide:money", "job:merchant"])], "", "market stall rent sell shop business larger display")
	var cost: Dictionary = Stalls.cost()
	var cost_text := ", ".join(cost.keys().map(func(k): return "%d %s" % [int(cost[k]), GameData.item_name(k).to_lower()]))
	w.add_page("guide:market_stall", "How do I build and run a market stall?", "guides", [
		Wiki.p("Anyone can build a market stall of their own: you, and the village's households too. It costs %s from your pack and no rent; instead the manor takes %d%% of what it sells." % [cost_text, pct]),
		Wiki.p("The village's own merchants face the same prices you do: a stall that sells more cheaply among many rivals earns less. A merchant whose household cannot live on the stall may move to an empty stall of the same kind where its goods should fetch clearly more, and one that still cannot get by gives up the trade and leaves the stall empty for the manor to let again."),
		Wiki.bullets([
			"Build: carry %s, stand outdoors on clear ground facing up and press Use: \"Build a market stall here\". The ground must be open (no road, tree, plant, field, pen or someone else's land) and at least 3 tiles from another stall; the cell you stand on is where buyers come." % cost_text,
			"Stock: press Use at the stall (\"Manage your market stall\") and Put up goods from your pack. They are in the stall now, not in your pack; Take back returns them.",
			"OPEN STALL: it sells while you are anywhere else. Villagers who really need its goods and can pay come and buy, at your prices.",
			"While it is open the sales wait in its till: they are not yours to take or spend until you close it.",
			"CLOSE STALL: sales stop and the session is settled. The manor takes %d%% of that session's sales (only what was really sold); the rest goes to your purse. Unsold goods stay in the stall. You may open it again at once." % pct,
			"When everything has sold, the stall closes by itself and settles, with a notice.",
			"The %d%% is exact over time: a share smaller than a coin is carried in hundredths to the stall's next settlement, so only whole coins ever change hands (100 coins of sales: 5 to the manor, 95 to you)." % pct,
		]),
		Wiki.p("Every market stall pays the same %d%%: the stalls people build, the manor's pitches and the merchants' stalls (a merchant's sales at the stall settle when they leave it). A pitch still has its daily rent of %d coins as well; a built stall has no rent. Shops and storefronts are counters, not stalls, and keep their own terms." % [pct, rent]),
		Wiki.links(["guide:stall", "guide:money", "job:merchant"])], "", "market stall build planks open close settle commission manor sold out")
	w.add_page("sys:stall", "Your market stall", "systems", [
		Wiki.p("An optional business: rent a pitch, stock it from your pack, set prices, and sell to villagers who need your goods. See the guide for the steps."),
		Wiki.stats([["Rent", "%d coins a day" % rent], ["Listings", "up to %d kinds of goods" % int(GameData.b("stall_max_listings"))],
			["Sales", "only while you stand within %d tiles" % range_t], ["Unpaid rent", "stopped, then reclaimed after %d days" % evict]]),
		Wiki.note("Not yet: attendants who craft at the shop's stations from its stock (production chains)."),
		Wiki.links(["guide:stall", "guide:shop", "guide:attendant"])], "", "market stall business demand")
	var licence := int(GameData.b("shop_licence_day"))
	var wage := int(GameData.b("attendant_wage"))
	w.add_page("guide:shop", "How do I open a shop?", "guides", [
		Wiki.p("A shop is a counter in a room you built (a house, a workshop, a storeroom or living quarters), with shelves and, if you like, a workshop's equipment. You need planks from the carpenter, and iron bars and stone for the stations."),
		Wiki.bullets([
			"Stand in your own room and press Use: \"Fit out this room\". Choose a piece and Place: the footprint follows the mouse, arrow keys, stick or a tap, green where it can go and red with the reason where it cannot. Nothing may shut off a door, a bed or part of the room.",
			"Pieces: a shop counter, shelves (up to %d, each %d more kinds of goods), stock chests (up to %d, each a back room of %d pieces that refills a shelf that sells out), and an oven, stove, workbench, forge and anvil. Each takes materials from your pack, which come back if you take the piece up." % [int(GameData.b("shop_max_shelves")), int(GameData.b("shop_shelf_listings")), int(GameData.b("shop_max_chests")), int(GameData.b("shop_store_per_chest"))],
			"Stand at the counter and press Use: \"Open a shop here\". The licence is %d coins a day to the manor, the first day at once." % licence,
			"The shop sells %d kinds of goods before any shelves. Put up, price, take back, collect the till and close it as with a stall. Closing returns everything; the counter and shelves stay." % int(GameData.b("shop_listings")),
			"What the shop is follows its equipment: a forge and an anvil make it a smithy, an oven a bakery, a workbench a carpenter's shop, a stove a kitchen. The stations work as any workshop's (you use them; villagers need your leave).",
			"The window shows revenue, expenses (licence, wages) and profit. Goods are not costed.",
		]),
		Wiki.p("Villagers buy only what they really need and can pay for, as at a stall, and only while you are near or an attendant is at the counter."),
		Wiki.links(["guide:stall", "guide:attendant", "guide:property_rooms"])], "", "shop counter shelves equipment business smithy bakery fit out")
	w.add_page("guide:attendant", "How do I hire an attendant?", "guides", [
		Wiki.p("An attendant minds your stall or shop while you are away. Open the stall's or shop's window and look under Attendant."),
		Wiki.bullets([
			"Hire an adult without a trade of their own (out of work, a manor hand with no job taken, or a labourer): %d coins a day, today's wage at once, then every morning from the till first and then your purse (only coins above what you keep for food and fuel)." % wage,
			"They are a real villager: they walk to the counter in the working day (7 to 18), eat, and sleep at night. Nothing sells before they are at the counter, and nothing sells at night.",
			"Customers are the same as ever: only villagers with a real need and coins to pay for it, at your prices.",
			"If neither the till nor your purse can pay the wage, the attendant leaves. Let go whenever you like; closing the stall or shop also lets them go.",
			"One attendant for each stall or shop. Sales they make are marked in the record.",
		]),
		Wiki.links(["guide:stall", "guide:shop"])], "", "attendant hire wage employee shop stall away")
