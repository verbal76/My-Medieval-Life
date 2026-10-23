class_name WikiFeast
extends RefCounted
## Wiki page for feasts (DVW-B3-FEAST): wedding feasts and seasonal feasts at the tavern. Every statement is taken from the code
## named beside it (Feast, Relations.propose, GameUI._feast_choices); numbers come from balance.json "feast" (GameData.b).
## Registered by one line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	var c: Dictionary = GameData.b("feast")
	var seasons := ", ".join(c.seasonal_seasons).to_lower()
	w.add_page("sys:feasts", "Feasts at the tavern", "systems", [
		Wiki.p("Villagers spend coins on feasts at the tavern, and so can you. A feast is a table of real food and ale: the host pays the tavern keeper for plates and mugs out of the keeper's own stock, and the guests eat and drink them. The coins go to the keeper and nothing is made: when the keeper runs short of a dish, the next dish on the menu is served, and when there is too little left, the feast is smaller or is not held."),
		Wiki.h("Wedding feasts"),
		Wiki.p("When two villagers become partners, their household holds a wedding feast at the tavern on one of the next evenings (from %d to %d days after). The couple, their households and a few friends are asked. The host is whoever in the two households has the most coins to spare. Roast meat is served first, then pottage and bread, with ale for the grown. A household that cannot afford it, or has too little food of its own, holds none: the feast is tried again the next evening until the days are up, then dropped." % [int(c.wedding_delay_days), int(c.wedding_window_days)]),
		Wiki.p("When you and a villager become partners you are owed one too, but you pay for it. From the next day, in the evening, your partner's family go to the tavern; once they are there, talk to the tavern keeper and choose Hold our wedding feast. You pay the keeper and everyone at the table eats and drinks."),
		Wiki.h("Seasonal feasts"),
		Wiki.p("On the first day of %s, a household that has coins to spare and food in the house may hold a feast at the tavern for itself and a couple of friends. Not every household does: some years it is a few, some none." % seasons),
		Wiki.h("Holding a feast yourself"),
		Wiki.p("In the evening (from the end of the working day until near bedtime) talk to the tavern keeper and choose Stand a feast for the room. Those in the tavern yard sit down, nearest first, up to the table you choose, and you pay the price shown. The keeper sells only part of the tavern's stock to a feast, so the village's own meals are not taken. Guests think a little better of whoever pays."),
		Wiki.h("What can go wrong"),
		Wiki.bullets([
			"The host is not at the tavern when the feast is due, or fewer than %d come: nothing is bought and nothing is paid." % int(c.min_guests),
			"The host cannot pay for everyone: the last guests are left off the table.",
			"The tavern has sold what it had: the table is smaller, or there is none.",
		]),
		Wiki.links(["sys:courting", "sys:family", "sys:trading", "sys:calendar"])], "feast wedding tavern ale banquet marriage partner season celebration coins sink")
