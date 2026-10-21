class_name WikiManor
extends RefCounted
## Wiki pages for the manor's reserve and relief (TREAS-01), orphans and adoption (FAM-02..07, REC-001) and posts
## passing on (B8-016, EQ-04). Every statement is taken from the code named beside it; numbers come from balance.json
## (GameData.b). Registered by one line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	var sys := func(id: String, title: String, blocks: Array, keywords := "") -> void:
		w.add_page("sys:" + id, title, "systems", blocks, "", keywords)
	_treasury(sys)
	_orphans(sys)
	_posts(sys)


# NPCBrain.reeve_day (tax, repairs, the granary), _relief, _relief_from_granary, _relief_offers, pay_guards;
# Property._pay_manor; World.guard_confront (fines); Property.household_ended (escheat).
static func _treasury(sys: Callable) -> void:
	var b := func(k: String) -> int: return int(GameData.b(k))
	sys.call("manor_treasury", "The manor's treasury and relief", [
		Wiki.p("The manor keeps the village's reserve: its treasury, and its granary. Coins come into the treasury only from someone who pays them: households' tax, the price of land and houses the manor sells, rent and leases, stall and shop rent, fines, and coins left lying that a guard brings in. Goods come into the granary only by purchase, or when a household dies out and its stores pass to the manor. Nothing is made: the treasury spends only what it holds, and the granary gives only what is in it."),
		Wiki.h("What it pays for"),
		Wiki.p("Each day it pays the sage, the reeve, the guards and the manor's hands their wages. In the evening it buys, from the villagers who sell them and at their prices: tools for workers who lack them, materials for repairs and public works, and the farmers' spare grain for the granary (up to %d days of the village's food, never in a famine and never what a farm needs for its own household and animals). The coins go to the sellers, so they stay in the village." % b.call("granary_target_days")),
		Wiki.h("Relief"),
		Wiki.p("A household that can cover less than %d days of food (its pantry and what its coins would buy) gets food up to %d days, the hungriest first. The manor gives from its own stores first: the granary's grain, in whole pots, then any other food it holds. Only what its stores cannot cover does it buy, from food sellers and farmers with grain to spare, or from another household's food beyond what that household needs; the food becomes the manor's and is given from there. Relief is carried to the household, or brought at once when it has less than a day of food." % [b.call("relief_trigger_days"), b.call("relief_fill_days")]),
		Wiki.p("The treasury keeps a reserve: relief buys with money above %d days of the manor's wages, and in an emergency (under a day of food) down to one day's wages. With no money above that, or no food for sale anywhere, no relief is bought: a village can go hungry. A household that keeps needing relief is named in the village record." % b.call("treasury_reserve_days")),
		Wiki.links(["job:reeve", "sys:property", "sys:caravan", "sys:theft", "sys:inheritance"])], "treasury manor granary relief tax reserve hunger famine")


# Guardianship (dawn, place, candidates, move, _take_share, player_adopt); game_ui.gd _relation_choices ("Offer a home").
static func _orphans(sys: Callable) -> void:
	sys.call("orphans", "Orphans and adoption", [
		Wiki.p("When a child's parents and every other grown member of the household are dead, the child is taken in the next morning, in this order: a surviving parent who lives elsewhere; a grandparent; the nearest relative by the family tree (a grown brother or sister before an aunt or uncle, before a cousin); and only then another household able to take a child. A household can take a child in when it has a home of its own, a grown-up to care for them and a sleeping place to spare. Among equally close ones the household best able to provide comes first, then the one with more room, more food, the closer bond with the child and the nearer home."),
		Wiki.p("The child joins the household as one of its own and may take its family name; the birth parents stay recorded. What the parents left at home goes with the children, shared among them, into the pantry of the household that takes each in. With no household able to take a child, the child goes to the bandits' camp and is fed there with the band; at coming of age they leave for the village if a household will take them."),
		Wiki.h("Offering a home"),
		Wiki.p("You can take in an orphan by the same rules. Your household is the one you share with your partner, where your own children grow up, so you need a partner, a home with a free sleeping place and someone grown to care for the child. Talk to the child and choose Offer a home. You can take in a child living at the bandits' camp, or one living with a household that is not family; a child that family as close to them as you are already cares for stays with that family. Your grandchildren and other kin come to your household in the morning order as any relative's would."),
		Wiki.links(["sys:family", "sys:inheritance", "sys:bandits", "sys:ageing"])], "orphan adopt adoption guardian foster child offer home")


# NPCBrain._open_vacancy, _post_left, succession_dawn, succession_caravan, _apprentice_for, _install, _newcomer_for,
# _reeve_succession, _guard_posts, _take_guard_post.
static func _posts(sys: Callable) -> void:
	var b := func(k: String) -> int: return int(GameData.b(k))
	sys.call("posts", "Posts passing on", [
		Wiki.p("The village's trades and offices outlive the people in them. When a skilled worker dies, retires or leaves the trade (because it did not keep their household fed), and the trade falls short, the post opens. After %d days an adult without a trade, a labourer or a manor hand takes it up, someone of the late worker's household first, with the late master's tools if their heir has them spare. If nobody can, a newcomer comes with the next caravan, at the latest %d days on, with %d coins of their own." % [b.call("succession_days"), b.call("newcomer_max_days"), b.call("newcomer_coins")]),
		Wiki.p("The reeve's office passes on the same way: when the reeve dies, the office opens that evening and is filled by the same rule, and the new reeve keeps the manor. The treasury is the manor's, so taxes, wages and relief go on in between; only public works wait for a reeve."),
		Wiki.p("The watch is kept at %d guards while the manor can pay for them: when a guard dies, the manor opens a guard's post that evening if its treasury holds more than %d days of its wages with %d days of a guard's wage to spare. The new guard takes the thinner shift and a guard's training (%d health), but no sword or armour unless the late guard's heir has them to pass on, or a newcomer brings them." % [int(Population.JOBS.guard), b.call("treasury_reserve_days"), b.call("manor_hire_runway_days"), int(Population.GUARD_STATS.hp)]),
		Wiki.links(["job:reeve", "job:guard", "sys:caravan", "sys:ageing", "sys:manor_treasury"])], "succession post vacancy apprentice newcomer reeve guard watch office")
