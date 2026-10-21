class_name WikiTopics
extends RefCounted
## Wiki pages the Build 12 audit found missing (FR-06): magic, the employer's star, the journal and
## the map, causes of death, the caravan and the bandits. Every statement is taken from the code named
## beside it; numbers come from balance.json (GameData.b) where the code reads them there, and the few
## the code holds as literals are kept below with where they live. Registered by one line in Wiki.build.

## main.gd fireball / _projectiles_step: the bolt's base damage, speed (tiles a second) and range (tiles).
const FIREBALL_DAMAGE := 14
const FIREBALL_SPEED := 9
const FIREBALL_RANGE := 8
## Population.generate: each bandit's health and blow; NPCBrain._bandit: the night they stalk in.
const BANDIT_HP := 25
const BANDIT_DAMAGE := 4


static func _names(ids: Array) -> String:
	return Wiki._and_list(ids.map(func(id): return GameData.item_name(str(id)).to_lower()))


## "a", "a or b", "a, b or c".
static func _or_list(words: Array) -> String:
	return Wiki._and_list(words).replace(" and ", " or ") if words.size() > 1 else Wiki._and_list(words)


static func add_pages(w: Wiki) -> void:
	var sys := func(id: String, title: String, blocks: Array, keywords := "") -> void:
		w.add_page("sys:" + id, title, "systems", blocks, "", keywords)
	_magic(sys)
	_star(sys)
	_journal(sys)
	_causes(sys)
	_caravan(sys)
	_bandits(sys)


# main.gd fireball and _projectiles_step; game_ui.gd show_talk (Learn Fireball); quests.json
# the_sage_in_the_north; skills.json magic; World.continue_as_heir (spells are not inherited).
static func _magic(sys: Callable) -> void:
	sys.call("magic", "Magic: the Fireball", [
		Wiki.p("The one spell in the game is Fireball. The sage teaches it: talk to the sage in the hut at the north edge of the village and choose Learn Fireball (%d coins). The story quest The sage in the north leads you there. Learning it gives you your first Magic experience." % int(GameData.b("fireball_price"))),
		Wiki.p("Cast it with F (or K) on a keyboard, Y on a pad (beside a villager working a rock, tree or plant, Y talks to them instead) or the Fire button on a phone. A cast costs %d stamina and the spell then needs %s seconds before it can be cast again; with too little stamina, or while it is cooling down, nothing happens." % [int(GameData.b("fireball_stamina")), str(GameData.b("fireball_cooldown"))]),
		Wiki.p("The fireball flies straight ahead the way you face, %d tiles a second, up to %d tiles, and stops at anything solid in its way, such as a wall. It strikes the first person it meets, or else the first animal, for %d damage (less the target's armour). Striking a villager is a crime, as with the sword; bandits are fair game." % [FIREBALL_SPEED, FIREBALL_RANGE, FIREBALL_DAMAGE]),
		Wiki.p("Each cast teaches Magic, and one that lands teaches more. Higher Magic levels shorten the wait between casts, raise the damage and cut the stamina cost; the Magic page lists each level. Your heir does not inherit the spell and must learn it from the sage again."),
		Wiki.links(["skill:magic", "job:sage", "sys:needs", "sys:fighting", "sys:bandits", "sys:theft"])], "spell fireball fire cast sage")


# main.gd _sync_stars; Quests.employer; Quests (hire work lapses after its days; manor work by the next morning).
static func _star(sys: Callable) -> void:
	sys.call("employer_star", "The gold star over an employer", [
		Wiki.p("A gold star bobs over each villager you have taken a job or a quest from and who has not yet paid you: paid work you took when you asked \"Any work for me?\", or a request you accepted. The reeve wears one while you hold a job for the manor. Story quests do not show it."),
		Wiki.p("The star follows them about. When they are indoors under a roof it hangs over the building's door instead. It goes when the job is done and paid, when the work lapses (a day's hired work after its days are up, manor work by the next morning) or when the person who gave it dies."),
		Wiki.p("It is not the marker over a villager's head that shows they have something to ask of you; when someone has both, the star sits above the marker. The Journal's Quests page lists the same jobs, with what is still wanted."),
		Wiki.links(["sys:journal_map", "guide:money", "job:reeve"])], "star employer quest job marker paid")


# game_ui.gd show_journal, _journal_items, _quest_items, show_resources, show_pause, CONTROLS;
# main.gd key bindings; game_ui.gd toggle_map / show_map; village_map_view.gd.
static func _journal(sys: Callable) -> void:
	sys.call("journal_map", "The Journal and the village map", [
		Wiki.h("The Journal"),
		Wiki.p("Open it with B on a keyboard, the D-pad's up on a pad, or Journal in the pause menu (Menu on a pad or a phone). It is a book of two pages at a time; Earlier and Later turn the pages, and it opens at the newest."),
		Wiki.bullets(["Village record: what has happened in the village, under a heading for each day with the time of each entry: deaths, robberies, the caravan's visits, posts that open and more.",
			"Quests: each quest and job you have taken, who asked and on which day, what they want (with how much you already have) and whether it is ready to hand in, your work for the manor and its next step, and a reminder of how to earn money.",
			"Resources: every resource you can gather, where it is, the tool it needs and where to get one, what it gives and whether it comes back; choose one to see what its products are used for."]),
		Wiki.h("The village map"),
		Wiki.p("Open it with M on a keyboard, LB on a pad or the Map button on a phone; the same key, the X or B closes it. It draws the whole village small: grass, trees, rock, water and paths in their colours, fields by how ripe they are, the pens, plots and buildings. The named buildings, the Manor, the Mine, the Market, the Fields, the Animal pens and the Plots for sale are labelled, your home is outlined in gold, a red pulsing dot is you and a pale box shows what the screen shows now."),
		Wiki.p("Tap or click a spot on the map to close it and look there. Recenter (C, pressing the right stick, or the Recenter button) brings the view back to you."),
		Wiki.links(["sys:employer_star", "sys:gather", "place:mine", "controls:kbm", "controls:gamepad", "controls:touch"])], "journal map book record quests log")


# World.kill and its callers: World._update_npc (starvation), Life._natural_deaths / _player_dawn (old age),
# main.gd _hit (slain by the player), NPCBrain.fight (slain by a bandit or guard), Fauna._bite (killed by a
# wolf or bear); World.damage_player and GameUI.death_text (the player's death screen); World.player_eat.
static func _causes(sys: Callable) -> void:
	var lf: Dictionary = GameData.b("life")
	var spoiled := []
	for id in GameData.items:
		if GameData.items[id].has("harm"):
			spoiled.append(id)
	var biters := []
	var an: Dictionary = GameData.b("animals")
	for id in an:
		if not str(id).begins_with("_") and bool(an[id].get("people", false)):
			biters.append(str(an[id].get("one", an[id].name)).to_lower())
	sys.call("death_causes", "Causes of death", [
		Wiki.p("Villagers and you die of the same few things. The death screen and the village record name the cause."),
		Wiki.bullets([
			"Starvation: at 0 food health drains away, %s health a game hour, for you as for a villager, until it runs out (\"You starved.\")." % str(GameData.b("starve_damage_per_hour")),
			"Old age: from age %d a small daily chance, rising with age, and certain at %d (\"You died of old age.\")." % [int(lf.mortality_from), int(lf.mortality_certain_at)],
			"Slain: killed in a fight, by a bandit, a guard or you; for you the screen says who (\"Killed by Wat the guard.\").",
			"Wild beasts: a %s that bites someone to death (\"Killed by a wolf.\")." % " or a ".join(biters),
			"Spoiled food (you only): eating a %s costs health, and it can be the last of it (\"Spoiled food made you fatally sick.\")." % _names(spoiled),
			"A death with no recorded cause reads \"You died of your wounds.\""]),
		Wiki.p("There is no sickness, bleeding, falling or weather to die of. A villager who dies of hunger or old age leaves their coins and goods to their heir (see Inheritance); what someone slain carried lies where they fell, for anyone to take. When you die, your heir takes over."),
		Wiki.links(["sys:death", "sys:ageing", "sys:inheritance", "sys:needs", "sys:bandits", "sys:fighting", "animal:wolf", "animal:bear", "guide:heal"])], "death die died killed starve old age slain")


# NPCBrain.caravan, _caravan_imports, _caravan_stone, _caravan_apothecary, _caravan_seeds, local_tool_need,
# succession_caravan; World.update (noon on the caravan's day); resources.json exports.
static func _caravan(sys: Callable) -> void:
	var every := int(GameData.b("caravan_every_days"))
	var farm: Dictionary = GameData.b("farming")
	var stone: Dictionary = GameData.b("caravan_stone")
	sys.call("caravan", "The merchant caravan", [
		Wiki.p("Every %d days, at noon, a merchant caravan passes through. It is the village's trade with the world outside: it deals with the village's merchants, smiths and sage, not with you, and each visit is written in the Journal's village record. What you sell to the merchants and the smith may end up on its carts." % every),
		Wiki.h("What it buys"),
		Wiki.p("It buys the merchants' and smiths' surplus (the smiths' %s), what each holds above half of the most they stock, at %d%% of its value. It never buys the mine's raw %s. While the village has less than %d days of food it buys no food, and it leaves behind as many axes and pickaxes as villagers need: workers whose trade needs one they lack, and householders building a home without an axe." % [_names(GameData.resources.exports.smith_caps.keys()), 80, _names(NPCBrain.NOT_EXPORTED), int(GameData.b("caravan_food_reserve_days"))]),
		Wiki.p("Nobody is served first for their trade. It buys one piece at a time, each from the seller who needs the sale most: the one holding the most surplus for its stock, and the one whose coins fall furthest short of the inputs its trade lacks. A seller well stocked, with coins to restock, may sell nothing when the purse is short."),
		Wiki.p("It also buys from the producers: what hunters hold beyond their own stock of meat, hides and pelts, and tanners beyond their leather (each keeps %s), within the same purse and the same food rule." % Wiki._and_list((GameData.b("caravan_producer_keep") as Dictionary).keys().map(func(k): return "%d %s" % [int(GameData.b("caravan_producer_keep")[k]), GameData.item_name(k).to_lower()]))),
		Wiki.p("It pays from its own purse, which starts at %d coins. It spends at most %d a visit and never more than it holds. The region's demand adds up to %d coins a day (never taking the purse past %d), less as the village's coins near %d a head and nothing at that, and every coin the village pays it for goods goes into it. So a surplus it cannot pay for stays on the shelf." % [int(GameData.b("caravan_float")), int(GameData.b("caravan_coins")), int(GameData.b("caravan_allowance")), int(GameData.b("caravan_float")), int(GameData.b("caravan_ceiling_per_head"))]),
		Wiki.h("What it sells"),
		Wiki.bullets([
			"Ore and coal: once the village's own seams of one are down to %d or less, each smith buys up to %s." % [int(GameData.b("caravan_import_when_left")), Wiki._and_list((GameData.b("caravan_import_stock") as Dictionary).keys().map(func(k): return "%d %s" % [int(GameData.b("caravan_import_stock")[k]), GameData.item_name(k).to_lower()]))],
			"Stone: once the village's stone (its stone seams, the grey rock of worked-out seams and its boulders) is down to %d or less, a cart of up to %d at %s times its value, for the raw-goods merchants." % [int(GameData.b("caravan_import_when_left")), int(stone.load), str(stone.markup)],
			"Medicine: up to %d pieces a visit for the sage's Apothecary, the scarcest first (%s)." % [int(GameData.b("caravan_apothecary_per_visit")), _names((GameData.b("caravan_apothecary_stock") as Dictionary).keys())],
			"Seed: up to %d a visit for the food merchant, the scarcest first (%s)." % [int(farm.caravan_seed_per_visit), _names((farm.caravan_seed_stock as Dictionary).keys())]]),
		Wiki.p("Buyers pay from their own coins and keep back what their household will need over the next %d days: food it has not got, a log a night, medicine for anyone hurt, rent falling due, less wages it can count on. They spend that money only on food, firewood and medicine, so a smith or sage with a hungry family buys less stock, and one with full stores buys freely." % int(GameData.b("reserve_days"))),
		Wiki.h("Newcomers"),
		Wiki.p("When a trade falls short (a %s dies or retires, or the last farmer, woodcutter or miner), the post stays open for %d days; then an adult without a trade, a labourer or a manor hand takes it as an apprentice. If nobody can, a newcomer comes with the next caravan (at the latest %d days after the death), with %d coins of their own, takes the post and its workplace, and lodges with the dead worker's household or in an empty house." % [_or_list(NPCBrain.SKILLED), int(GameData.b("succession_days")), int(GameData.b("newcomer_max_days")), int(GameData.b("newcomer_coins"))]),
		Wiki.links(["sys:trading", "job:merchant", "job:smith", "job:sage", "place:mine", "item:stone", "sys:journal_map"])], "caravan trade export import newcomer merchant")


# Population.generate (the band), NPCBrain._bandit, _prey_for, fight (robbing, fleeing), act "poach",
# _guard; main.gd _hit; World.kill (loot); Relations.defended; quests.json bandit_trouble.
static func _bandits(sys: Callable) -> void:
	sys.call("bandits", "Bandits", [
		Wiki.p("A band of %d bandits lives at a camp in the woods north-east of the village. Each has %d health, a copper sword and a few coins. They do not talk: \"Your purse or your life.\"" % [int(GameData.b("bandits")), BANDIT_HP]),
		Wiki.p("By day they lurk about the camp and poach: a hungry bandit eats what the band holds (food bought at the market, stolen or poached; meat roasted over the camp fire), and with nothing left goes after wild game near the camp. A band with no food goes hungry. At night (from 21:00 until 04:30) they go stalking. A bandit within 18 tiles of you comes for you, striking about %d a blow (less your armour). Otherwise they pick the villager outdoors nearest the camp who has a few coins and no guard close by, rob them of half their coins and one thing they do not keep for their work, and go back to the camp." % BANDIT_DAMAGE),
		Wiki.p("Guards on duty attack any bandit they can see (within %d tiles, and not through a wall), but do not follow one into the camp. A bandit badly hurt (below 30%% of its health) breaks off and runs back to the camp." % int(GameData.b("witness_radius"))),
		Wiki.p("An attack is known only to those who see it (not through a wall) and to its victim, the same for you and for a bandit. A guard who sees it answers it; the victim and the others who saw it go and tell a guard (one within %d tiles), who then comes after the attacker. Word that has not reached a guard within %d hours is let go." % [int(GameData.b("report").range), int(GameData.b("report").hours)]),
		Wiki.p("Stolen coins do not stay in the woods. By day a bandit holding %d coins or more slips into the market and buys a little food from a stall with no guard close by. Coins left lying where someone fell are collected by a guard on duty after %d hours, if it lies within %d tiles of the guard's rounds, and go to the manor's treasury; the goods stay where they lie." % [int(GameData.b("bandit_spend_min")), int(GameData.b("loot_recover_hours")), int(GameData.b("guard_loot_range"))]),
		Wiki.p("Fight them with the sword or a fireball. Striking a bandit is no crime, and your sword strikes them before any bystander. One put down stays dead (the band never grows back) and drops what it carried, stolen goods included, for anyone to pick up; villagers who see it think better of you. A villager a bandit robbed may ask you to deal with that bandit as a quest (Bandit trouble) and pay you for it."),
		Wiki.links(["sys:fighting", "sys:magic", "job:guard", "skill:combat", "sys:death_causes", "sys:courting"])], "bandit camp robber thief outlaw poach")
