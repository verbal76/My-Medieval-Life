class_name WikiChapel
extends RefCounted
## Wiki page for the chapel (DVW-B3-CHAPEL): the clergy, offerings, asking for help and the church's plot. Every statement is
## taken from the code named beside it (Chapel, FarmPlots.plan_church, NPCBrain._plan_evening); numbers come from balance.json
## "chapel" (GameData.b). Registered by one line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	var c: Dictionary = GameData.b("chapel")
	w.add_page("sys:chapel", "The chapel", "systems", [
		Wiki.p("The village has a small chapel east of Mill Road, between the sawmill's yard and the smithy, with a small fenced farm plot of its own next to it. Two villagers keep it: a preacher and a church assistant. Both are paid, but little: %d and %d coins a day, against %d for a manor hand. Their wage comes only from what the village gives the chapel. On a day the chapel's fund cannot pay, the wage is owed and paid when there is money again, for up to %d days, and nothing is made to pay it." % [int(c.wage.preacher), int(c.wage.church_assistant), int(GameData.b("manor_wage_per_day")), int(c.owed_days)]),
		Wiki.h("Offerings"),
		Wiki.p("Once a week, at the chapel's service, the pious give. Each villager is more or less devout, a fixed trait: some give nothing. Those who give hand over part of the coins they hold above what their household will need for the next few days, and their households give part of the wheat they hold beyond what they need to eat. Nothing is taken from anyone who has no spare. The coins go into the chapel's fund and the food into its store."),
		Wiki.p("You can give too. Talk to the preacher or the church assistant and choose to give coins or a piece of food. The chapel takes only food and seed corn, not goods."),
		Wiki.h("Asking for help"),
		Wiki.p("Everything given to the chapel is the first money and food used against hunger. When a household is running short of food, one of its members goes to the chapel and asks. The church fills the household's pantry from its store first, grain first; if its store runs short, it buys food from the villagers who have some to sell, with its own fund. Only then, if the household is still short, does the manor's relief step in, and it gives only what the church did not (see the manor's treasury and relief). A church with nothing gives nothing: a village can still go hungry."),
		Wiki.p("If you have almost no coins (%d or fewer) you can ask the church for food yourself, once a day: talk to the preacher and choose Ask the church for food. It gives up to %d pieces of what it holds." % [int(c.ask_player_max_coins), int(c.ask_player_units)]),
		Wiki.h("The church's plot"),
		Wiki.p("The plot is ploughed, sown and harvested like any family's field, by the same rules, and all its harvest goes into the chapel's store to be given as relief. Pious villagers with time to spare (the old, and those out of work) may volunteer to work it, and so may the very devout after their day's work; at most %d at a time. When nobody volunteers, the clergy work the plot themselves. The church buys its seed with its fund, from the farmers and the food merchant." % int(c.volunteers_max)),
		Wiki.h("The law"),
		Wiki.p("The preacher also teaches the law, as the reeve does but further: one lesson a day, up to level %d (see the skills)." % int(Law.cfg().teachers.preacher)),
		Wiki.links(["sys:manor_treasury", "sys:farmland"])], "chapel church preacher clergy offering donation alms relief charity volunteer plot assistant")
