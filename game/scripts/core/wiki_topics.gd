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
	_neighbours(sys)
	_couriers(sys)
	_bandits(sys)
	_opinions(sys)


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
		Wiki.p("Open it with M on a keyboard, LB on a pad or the Map button on a phone; the same key, the X or B closes it. It draws the whole village small: grass, trees, rock, water and paths in their colours, fields by how ripe they are, the pens, plots and buildings. The named buildings, the Manor, the Mine, the Market, the Fields, the Animal pens and the Plots for sale are labelled, your home is outlined in gold, a red pulsing dot is you and a pale box shows what the screen shows now. Out in the country beyond the village the map still shows only the village: your dot waits at its edge with an arrow pointing your way and how far you are, for example \"You: 57 tiles south-west of the village\", so head the other way to come back."),
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
	var lux: Dictionary = GameData.b("luxury")
	sys.call("caravan", "The merchant caravan", [
		Wiki.p("Every %d days, at noon, a merchant caravan passes through. It is the traders of the five neighbouring settlements (see The neighbouring settlements): the village's trade with the world outside. It deals with the village's merchants, smiths and sage, with households and the manor for food when the village has none to offer them, and with you only for two things, a plough horse and costly goods (see below), and each visit is written in the Journal's village record, with the settlements whose traders came. What you sell to the merchants and the smith may end up on its carts." % every),
		Wiki.p("Which traders come depends on the road: %s, and all of them on the very first visit. A trader sells only what it has brought and buys only with the coins in its own purse, so a visit can be a poor one: a trader may come with nothing to sell, or with no money to buy." % Wiki._and_list(OffMapSettlement.data().settlements.map(func(s): return "%s's %s" % [str(s.name), _every_time(maxi(1, ceili(float(s.miles) / 20.0)))]))),
		Wiki.h("What it buys"),
		Wiki.p("It buys the merchants' and smiths' surplus (the smiths' %s), what each holds above half of the most they stock, at %d%% of its value. It never buys the mine's raw %s. While the village has less than %d days of food it buys no food, and it leaves behind as many axes and pickaxes as villagers need: workers whose trade needs one they lack, and householders building a home without an axe." % [_names(GameData.resources.exports.smith_caps.keys()), 80, _names(NPCBrain.NOT_EXPORTED), int(GameData.b("caravan_food_reserve_days"))]),
		Wiki.p("Nobody is served first for their trade. It buys one piece at a time, each from the seller who needs the sale most: the one holding the most surplus for its stock, and the one whose coins fall furthest short of the inputs its trade lacks. A seller well stocked, with coins to restock, may sell nothing when the purse is short."),
		Wiki.p("It also buys from the producers: what hunters hold beyond their own stock of meat, hides and pelts, and tanners beyond their leather (each keeps %s), within the traders' purses and the same food rule." % Wiki._and_list((GameData.b("caravan_producer_keep") as Dictionary).keys().map(func(k): return "%d %s" % [int(GameData.b("caravan_producer_keep")[k]), GameData.item_name(k).to_lower()]))),
		Wiki.p("It buys only what a settlement still wants (what its people, workshops and council would use, less what it makes itself), and it pays from the traders' own purses: every coin it pays the village is a coin that settlement had, and every coin the village pays it goes into the trader's purse. No coin is made for it. So a surplus nobody wants, or one the traders cannot pay for, stays on the shelf."),
		Wiki.h("What it sells"),
		Wiki.bullets([
			"Ore and coal: once the village's own seams of one are down to %d or less, each smith buys up to %s." % [int(GameData.b("caravan_import_when_left")), Wiki._and_list((GameData.b("caravan_import_stock") as Dictionary).keys().map(func(k): return "%d %s" % [int(GameData.b("caravan_import_stock")[k]), GameData.item_name(k).to_lower()]))],
			"Stone: once the village's stone (its stone seams, the grey rock of worked-out seams and its boulders) is down to %d or less, a cart of up to %d at %s times its value, for the raw-goods merchants." % [int(GameData.b("caravan_import_when_left")), int(stone.load), str(stone.markup)],
			"Medicine: up to %d pieces a visit for the sage's Apothecary, the scarcest first (%s)." % [int(GameData.b("caravan_apothecary_per_visit")), _names((GameData.b("caravan_apothecary_stock") as Dictionary).keys())],
			"Seed: up to %d a visit for the food merchant, the scarcest first (%s)." % [int(farm.caravan_seed_per_visit), _names((farm.caravan_seed_stock as Dictionary).keys())],
			"Food: a trader may bring food from its own settlement's farms, herds and cookshop, and sells it at that place's own prices (they rise and fall with the place's harvests and shortages, and the nearest trader is not always the cheapest). A settlement lets go only of food it can spare: what is left once its people's needs for the next %d days are counted, less what they already hold and what its fields and herds will make. A farm or herd that cannot pay its wages and bills may sell some of the food its place would rather keep, but no more than the money it is short, so a hard-pressed place can sell food it will go without. The village buys it only when it cannot find that food here: a household with none to be had in the village (it pays from its own coins), the manor when its granary is under target (from money above its reserve), and the food merchant, cook or tavern when their stock is short. The coins go to the trader and leave the village." % int(GameData.b("reserve_days")),
			"Luxuries: %s. Only the traders of %s carry them, from the stock they hold; nothing makes more, so when they have sold what they hold, there are no more. Every coin paid goes into the trader's purse and leaves the village." % [Wiki._and_list((lux.items as Array).map(func(k): return "%s at %d coins" % [GameData.item_name(str(k)).to_lower(), Luxury.price(str(k))])), Wiki._and_list(_luxury_places())]]),
		Wiki.p("Luxuries are bought for show and kept: nobody eats or uses them up. A villager buys one on a visit day only if they are an adult with a taste for such things (a fixed trait), their household has food in hand, and the price is no more than half of what they hold beyond their reserve and %d coins of savings; each takes the dearest it can afford, owns at most %s of a kind, and no more than %d villagers buy on one visit, those with the most to spare first. A household short of money or food buys none. You buy them yourself at the wagon (see below). The game has no measure of a person's standing yet, so owning them does not change how anyone is treated (see Not in the game yet)." % [int(lux.keep_coins), Wiki._and_list((lux.items as Array).map(func(k): return "%d %s" % [int(lux.own_max[k]), GameData.item_name(str(k)).to_lower()])), int(lux.buyers_per_visit)]),
		Wiki.p("At the wagon: while the caravan is in the village (visit days, from noon for %d hours, its wagon at the market road), stand beside it and you are offered each luxury a trader on the road still holds, one at a time, if you have the coins and room in your pack. You can also buy food there (%s), one unit at a time, from what the traders on the road hold: the cheapest trader's price for that food, paid into its purse; the coins leave the village and a trader that has none left sells no more." % [int(farm.caravan_horse.hours), Wiki._and_list(CaravanFood.FOODS.map(func(k): return GameData.item_name(str(k)).to_lower()))]),
		Wiki.p("Plough horse: while the caravan is in the village (visit days, from noon for %d hours, its wagon at the market road), you can buy a plough horse for %d coins if you have a horse pen with room (see How do I keep animals). The horse is one of a settlement's own, led along by its trader; %s keep horses, and the nearest one on the road that day sells. If no trader who has come has a horse, there is none for sale that day. The coins go to that settlement and leave the village." % [int(farm.caravan_horse.hours), int(farm.caravan_horse.price), Wiki._and_list(_horse_places())]),
		Wiki.p("Buyers pay from their own coins and keep back what their household will need over the next %d days: food it has not got, a log a night, medicine for anyone hurt, rent falling due, less wages it can count on. They spend that money only on food, firewood and medicine, so a smith or sage with a hungry family buys less stock, and one with full stores buys freely." % int(GameData.b("reserve_days"))),
		Wiki.h("Newcomers"),
		Wiki.p("When a trade falls short (a %s dies or retires, or the last farmer, woodcutter or miner), the post stays open for %d days; then an adult without a trade, a labourer or a manor hand takes it as an apprentice. If nobody can, a newcomer comes with the next caravan (at the latest %d days after the death), with %d coins of their own, takes the post and its workplace, and lodges with the dead worker's household or in an empty house." % [_or_list(NPCBrain.SKILLED), int(GameData.b("succession_days")), int(GameData.b("newcomer_max_days")), int(GameData.b("newcomer_coins"))]),
		Wiki.links(["sys:neighbours", "sys:trading", "job:merchant", "job:smith", "job:sage", "place:mine", "item:stone", "item:spice", "item:fine_cloth", "item:jewellery", "sys:journal_map", "guide:animals", "animal:horse", "todo:luxury_status"])], "caravan trade export import newcomer merchant trader luxury luxuries spices fine cloth jewellery")


# game/data/settlements.json, OffMapSettlement, Regions (SET-C-SIM, SET-C-FIVE); docs/expansion18/SETTLEMENTS.md for the lore.
static func _neighbours(sys: Callable) -> void:
	var d := OffMapSettlement.data()
	var rows := []
	for s in d.settlements:
		rows.append("%s, %s %s about %d miles away: %s." % [str(s.name), "an" if str(s.kind)[0] in "aeiou" else "a", str(s.kind), int(s.miles), _names_plain(s.industries)])
	sys.call("neighbours", "The neighbouring settlements", [
		Wiki.p("Five other places lie along the road: Wulstead, Netherton, Garton, Higham-on-the-Way and Bourton Abbas, named in the old tale of the Well at the World's End. You cannot walk to them yet, but they are real: each is a small economy of its own, with households that have money and food, workshops and farms that make and sell things, and a council, steward or abbey that collects a tax and a market toll and pays its officials. They run by the same rules as the village, in less detail, a day at a time. Their people live a life too: they are born, grow up and come of age at sixteen, marry from eighteen and set up households of their own that go to work for a trade, and die of old age as the village's people do, as the years pass (a year is eight days). A household whose last grown member dies leaves its money and food to kin in the same place, or, with none, to the council."),
		Wiki.bullets(rows),
		Wiki.h("What they do for you"),
		Wiki.p("Their traders are the caravan (see The merchant caravan). They bring what their places have: ore and coal and stone from Garton's diggings and Bourton Abbas's quarry, medicines from the herb gardens, seed and cuttings from the farms, food they can spare, costly goods (spices, fine cloth, jewellery) from %s, and plough horses from %s. They take from the village what their people and workshops still need, and pay for it from their own purses. The traders also trade with each other every few days, so Garton's ore can reach a forge in Higham." % [Wiki._and_list(_luxury_places()), Wiki._and_list(_horse_places())]),
		Wiki.h("Growing, shrinking and changing trades"),
		Wiki.p("A place has no fixed size and no fixed trades. When its people keep going without something it could make (planks, leather, ale, cloth) week after week, a household that has the savings and is not earning much may take up that trade and open the workshop with its own money, provided the place has what the workshop needs to work. A workshop, farm or quarry whose families have all died or gone shuts after two weeks: its money goes to the council, and its stock is bought up by the traders or kept by the council. The fields, woods and quarry stay, and another household may open them again. All of this follows from the households' own sums, not from a plan."),
		Wiki.h("What can go wrong"),
		Wiki.p("Nothing is made for them. A place with a poor harvest, or whose workshops sell little, has little money to spend, and its traders buy less. A household that cannot buy food goes hungry, and one that stays hungry loses people; the council gives day labour and buys food for the hungry while it has money to spare. A place can shrink: one with few young people may dwindle as its old die, and one whose families grow faster than its harvests may lose people to hunger or to the road. Nothing rescues it, and what the village sells it or buys from it can matter."),
		Wiki.h("People coming and going"),
		Wiki.p("People move between the village and these places, always for a reason, and always with the caravan, so the nearer places see more of it. A villager or a whole household may leave for hunger (when the village is short of food and the manor's relief cannot reach them, and the other place has food to spare), for work (an adult with no trade, in a household that cannot get by, when the village has no work open and the other place pays well), for land (a household that has long waited for a home it could not pay for), or to marry. Folk arrive the same ways: a household that cannot buy food comes to a village with food to spare; a worker from a household short of work takes a post the village could not fill, before anyone else is sent for; a young couple who married there and can pay for a house on the manor's market come to take it; and a bride or groom comes to marry someone from the village after the two have known each other a while. They bring their name, age, skills, purse and belongings, and the village's rules for houses and jobs apply to them as to anyone. Someone who left the village and comes back is the same person as before, not a stranger: those who knew them still know them, and their family is still their family. The reeve, the guards, the clergy and the market traders do not leave. Each place writes its own tax announcements and its comings and goings in a record of its own, and taxes there follow the manor's own rule: a rate changes only after notice."),
		Wiki.h("Not in the game yet"),
		Wiki.p("You cannot visit them in person, swap goods for goods or owe or be owed money. Goods and word go between you only by the caravan and by courier (see Couriers and the courier booth)."),
		Wiki.links(["sys:caravan", "sys:couriers", "sys:trading", "sys:manor_treasury", "animal:horse"])], "neighbouring settlements towns Wulstead Netherton Garton Higham Bourton Abbas trade traders caravan")


# game/data/couriers.json, CourierService (couriers.gd), CourierWindow (ui/courier_window.gd), main.gd (the booth action),
# Regions.village_route_table; REG-COURIER-01, X18-Q12, X18-Q12-BOOTH, X18-Q12-POST.
static func _couriers(sys: Callable) -> void:
	var r: Dictionary = CourierService.cfg().routes
	var names := []
	for sp in OffMapSettlement.data().settlements:
		names.append(str(sp.name))
	sys.call("couriers", "Couriers and the courier booth", [
		Wiki.p("A courier carries your goods to someone you know, here or in one of the neighbouring settlements (%s), and can bring back payment. Every settlement has a courier booth kept by its own trader, and the village has one at a market stall, kept by a villager. Stand beside the village booth and choose the courier option to open the courier form." % Wiki._and_list(names)),
		Wiki.h("Sending something"),
		Wiki.p("Fill in the form like a parcel slip: the service, the item and how many, whom to deliver to, where, whether the courier should collect payment (coins or an item, and how much), and whether the payment comes back to you or waits for you at your booth. Review shows the instruction in plain words and the fee before you confirm. Nothing is sent until you confirm."),
		Wiki.bullets([
			"Regular route: the courier leaves the booth every %d days for the settlement and takes up to %d goods a load for a flat fee of %d coins a load, paid when you book. Your goods wait at the booth until it leaves." % [int(r.every_days), int(r.load_units), int(r.fee_per_load)],
			"Special delivery: a courier carries it at once, for a fee you agree. You offer a price; the courier accepts it if it covers the work (the days there and back, the loads, the stops) and otherwise names the least it will take. The fee is held at the booth and paid to the courier only when the work is done.",
		]),
		Wiki.h("Shop booths"),
		Wiki.p("A business with a shop may keep a courier booth of its own: the merchants and the smith at their stalls and workplaces, and you at a market stall you have built (stand beside it and choose to open a booth). A shop booth has its own regular route to each settlement, at the same flat fee; the goods wait in that booth and the village's courier carries them. The fee goes to the courier, never to the shop's own keeper. When no market stall is free the village's booth is a stall its keeper builds near the market from their own planks."),
		Wiki.h("Formal contracts and the notary"),
		Wiki.p("A small agreement (a payment of %d coins or less) needs no signature. A payment worth more is a formal contract and must be signed: only a special delivery, carried by a courier who knows the law (Law %d or more, shown beside their name in the form), can carry it. You sign before the courier as it leaves, the other party signs before the courier when it arrives, and the courier brings the document back; it binds only then. Nothing is signed from afar or at once, and a regular route cannot carry such a payment. A recipient who will not sign sends the goods back; a courier who dies on the road loses the document, and the contract is not made. The courier learns some Law from every signature witnessed and every document carried home." % [int(CourierService.cfg().contracts.small_value), int(CourierService.cfg().notary.min_level)]),
		Wiki.h("Carters"),
		Wiki.p("For a special delivery you may also hire the trader of a settlement you have dealt with, who carries on its own way home to that settlement for a fee agreed like any other and paid only when the work is done. Nobody carries for nothing."),
		Wiki.h("Whom you can send to"),
		Wiki.p("Only people and businesses you know: villagers you have come to know, and shops or traders you have really dealt with. A settlement's trader is someone you know once you have bought from or sold to the caravan's trader from that place. There are no typed addresses and no strangers; the form lists only those you may send to."),
		Wiki.h("The road"),
		Wiki.p("Nothing is instant. The courier takes your goods on the road, and the days it takes depend on how many miles lie between the places. At the end it hands the goods over, takes the payment you asked for if the other side can and will pay (if not, the goods come back to you), and returns. The delivery counts as done only when the courier is home and every part is settled. Proceeds come back to your pack, or wait at the village booth if you asked, or if your pack was full; go to the booth and collect them there."),
		Wiki.h("What can go wrong"),
		Wiki.p("A courier who dies on the road drops the load where they fell; it can be found by anyone, and the fee that was held goes back to you. A recipient who has died, cannot take the goods or refuses the payment sends the goods back. Without a keeper, the village booth waits until another villager takes it over at dawn. You need the goods and the fee in hand when you book. A settlement whose trader is gone cannot be reached."),
		Wiki.h("Not in the game yet"),
		Wiki.p("You cannot carry a document for someone yourself yet: only the village's couriers and the settlements' traders do. A villager's own sending is limited to the goods that the caravan would also take from a merchant or smith. Property, land and house sales are still settled in person."),
		Wiki.links(["sys:neighbours", "sys:caravan", "sys:trading", "skill:law"])], "courier couriers booth deliver delivery send post parcel route special delivery fee regular route settlements notary formal contract signing carter shop booth")


## The settlements whose traders carry luxuries from the start (settlements.json "start", DVW-B3-LUX).
static func _luxury_places() -> Array:
	var out := []
	for sp in OffMapSettlement.data().settlements:
		for k in (sp.get("start", {}).get("merchant", {}) as Dictionary):
			if Luxury.is_luxury(str(k)):
				out.append(str(sp.name))
				break
	return out


## The settlements that keep working horses to sell (settlements.json "horses").
static func _horse_places() -> Array:
	return OffMapSettlement.data().settlements.filter(func(s): return int(s.get("horses", 0)) > 0).map(func(s): return str(s.name))


static func _every_time(n: int) -> String:
	return {1: "every time", 2: "every second time", 3: "every third time", 4: "every fourth time"}.get(n, "every %dth time" % n)


static func _names_plain(ids: Array) -> String:
	var out := []
	for i in ids:
		out.append(str(i))
	return "known for " + Wiki._and_list(out)


# Population.generate (the band), NPCBrain._bandit, _prey_for, fight (robbing, fleeing), act "poach",
# _guard; main.gd _hit; World.kill (loot); Relations.defended; quests.json bandit_trouble.
static func _bandits(sys: Callable) -> void:
	sys.call("bandits", "Bandits", [
		Wiki.p("A band of %d bandits lives at a camp in the woods north-east of the village. Each has %d health, a copper sword and a few coins. They do not talk: \"Your purse or your life.\"" % [int(GameData.b("bandits")), BANDIT_HP]),
		Wiki.p("By day they lurk about the camp and poach: a hungry bandit eats what the band holds (food bought at the market, stolen or poached; meat roasted over the camp fire), and with nothing left goes after wild game near the camp. A band with no food goes hungry. At night (from 21:00 until 04:30) they go stalking. A bandit within 18 tiles of you comes for you, striking about %d a blow (less your armour). Otherwise they pick the villager outdoors nearest the camp who has a few coins and no guard close by, rob them of half their coins and one thing they do not keep for their work, and go back to the camp." % BANDIT_DAMAGE),
		Wiki.p("Guards on duty attack any bandit they can see (within %d tiles, and not through a wall), but do not follow one into the camp. A bandit badly hurt (below 30%% of its health) breaks off and runs back to the camp." % int(GameData.b("witness_radius"))),
		Wiki.p("An attack is known only to those who see it (not through a wall) and to its victim, the same for you and for a bandit. A guard who sees it answers it; the victim and the others who saw it go and tell a guard (one within %d tiles), who then comes after the attacker. Word that has not reached a guard within %d hours is let go. Everyone else hears of it only as gossip, later, and may judge it differently (see What villagers think of you)." % [int(GameData.b("report").range), int(GameData.b("report").hours)]),
		Wiki.p("A guard who comes after you does not stop at a wall or a corner: they find the way round and keep coming. Out of their sight they search where they last saw you; a guard told of your attack goes to where you were seen and searches there. A killing raises the hue and cry, and the guards who hear it come. How the guards hunt, when you are wanted, and how to yield are in Theft and guards."),
		Wiki.p("A parent or guardian out of doors with the children, or with a spouse or parent, does not leave them to it when a bandit comes near: they step between the bandit and the family, send them home and run to tell a guard, or stand and fight if they are cornered or very stubborn. They can be hurt or killed doing it, and one badly hurt runs rather than die. A wolf or bear that has turned on one of the family is met the same way, except that no guard comes against a beast (see What villagers think of you). So are you, near their children, if they know you for a killer."),
		Wiki.p("Stolen coins do not stay in the woods. By day a bandit who can afford some food slips into the market and buys a little from a stall with no guard close by; a badly hurt bandit lies up at the camp until healed. Coins left lying where someone fell are collected by a guard on duty after %d hours, if it lies within %d tiles of the guard's rounds, and go to the manor's treasury; the goods stay where they lie." % [int(GameData.b("loot_recover_hours")), int(GameData.b("guard_loot_range"))]),
		Wiki.p("Fight them with the sword or a fireball. Striking a bandit is no crime, and your sword strikes them before any bystander. One put down stays dead and drops what it carried, stolen goods included, for anyone to pick up; villagers who see it think better of you. A villager a bandit robbed may ask you to deal with that bandit as a quest (Bandit trouble) and pay you for it."),
		Wiki.p("A band wiped out is not gone for ever. Some time after the last bandit falls, a few outlaws drift in from outside along the roads and make camp in the woods again, and the band grows from there as orphaned children grow up among them."),
		Wiki.links(["sys:fighting", "sys:magic", "job:guard", "skill:combat", "sys:death_causes", "sys:courting", "sys:opinions"])], "bandit camp robber thief outlaw poach")


# NPC judgment, Expansion 19 (Build 19): game/data/judgment.json and game/scripts/core/judgment/*.gd; docs/expansion19/DESIGN.md.
# Player-facing words only: no numbers the owner wants found by play, no internals. Described as playable only what has landed
# and passed its tests (judgment_test, judgment_live_test, judgment_personality_test, judgment_bonds_test, judgment_x19_test,
# family_first_test).
static func _opinions(sys: Callable) -> void:
	sys.call("opinions", "What villagers think of you", [
		Wiki.p("Every villager keeps their own opinion of everyone, you included. It comes from what they see, what they do with you and what they are told, and it is never shown as a number: you see it in how they treat you, who sells to you, lends to you, takes work from you, befriends or courts you, and what they say. Two villagers who saw the same deed may judge it differently. The one it happened to takes it hardest. A relative or friend of the victim is angry for them; a relative or friend of the wrongdoer is slower to condemn; someone who already dislikes the victim may even approve."),
		Wiki.h("How word travels"),
		Wiki.p("Villagers talk when they spend time together, and what they know of a deed passes on, easily between friends and less readily between strangers. Nobody hears of a deed the moment it happens, so news reaches the far side of the village slowly and may never reach some people. A story is believed more when the teller is someone the listener trusts, and less after it has passed through many mouths. Trust is not the same as liking: it grows slowly from fair dealing (a contract kept, a debt repaid) and is lost quickly by cheating or by accusing someone falsely. A rumour that turns out true makes the teller more trusted, and one shown false makes them less."),
		Wiki.p("Ask a villager for the news and they tell only what they know: what they saw, what they took part in, and what someone told them, and they say which (\"I saw it myself\", \"Hugh told me\", \"they say\"). A villager who has heard nothing has no news. The village's own news (land bought, leased or fenced, food from the manor or the church, someone without the tool of their trade, a death) travels the same way, from those it concerns and those who saw it. A household hears of a death in the family at once, but not who did it unless one of them saw it or is told."),
		Wiki.p("They tell it as it touches them: their own household is \"our family\" or \"we\", their mother is \"Mum\" to a child, and you are \"you\". What touches them most comes first: something between you and their own people, then a harm to their family, then you, then their family's affairs, then anyone else. Related events are told as one (\"Our family bought that farmland ... We have already fenced it off.\"), and an attack that ended in a death is told once, as the killing. What they have told you once they do not tell you again; a grief is touched on at most once a day. A witness to your crime says it to your face once a day; asked again, they have nothing more to say. Someone whose family you helped, who knows of it, thanks you."),
		Wiki.h("Memory and time"),
		Wiki.p("Nobody remembers everything. An ordinary slight, an unfair price or a small kindness fades over a few years and is mostly forgotten after that. A killing or an assault is never forgotten by anyone who knows of it, and neither is a betrayal by a friend. A debt paid late counts as a fair deal, but earns less trust than one paid on time."),
		Wiki.h("Fights and guards"),
		Wiki.p("A blow that answers a blow in the same fight is not counted as an attack, and killing someone who struck first in that fight is not counted as a killing. A guard who stops an attacker is not a killer in anyone's eyes. Striking first, or killing someone who has not struck, is."),
		Wiki.h("Lies"),
		Wiki.p("Now and then someone with a serious grudge, or a rivalry, against another villager makes up a story about them and tells it as if true. It happens rarely, and a villager does it at most about once a year. A made-up crime is shown false when a guard hears it (the village's reports show no such crime) or when someone close to the accused, who knows how they live, hears it. Those who learn that it was false change their mind about the accused, and trust the teller less."),
		Wiki.h("Your family name"),
		Wiki.p("People see a newcomer partly through their family. What someone thinks of your parents, children, brothers and sisters and spouse counts most, then your grandparents, aunts and uncles, nieces and nephews and in-laws, then your cousins, even your second cousins, each less than the one before. A good name opens a door a little and a bad one closes it a little. It never decides alone: nobody turns you down only for your family's name, and as people deal with you themselves, what they have seen of you replaces it. A family also hands down its stories: when a child comes of age, the parents tell them, at home, the deeds they cannot forget (a killing, an assault, a betrayal) and the great kindnesses, while ordinary deeds are not passed on."),
		Wiki.h("Temperament"),
		Wiki.p("Villagers are not alike. Some forgive quickly and others hold a grudge, and their lives change them: being wronged makes a person less forgiving, kindness softens them, and hard times that go on harden them. A minority of villagers can become stubborn. A stubborn villager is slow to deal with someone they resent and slow to give up what they chose before, even when another choice would be better for them. They learn from costly mistakes (a meal missed with food to hand, coins lost, a purchase refused, an injury), and what they learn makes them less stubborn. Anger lasts about a day. Meeting the person who wronged them, or hearing the story told again, brings some of it back. While a stubborn villager is very angry they simply refuse the one who wronged them, even when they need the deal."),
		Wiki.h("A family looks after its own"),
		Wiki.p("The parent or guardian in charge of a household puts the children first, then the spouse, then their own parents, and themself last. They give up their own meal when the family is short, pay for the others, and look for paid work before an evening's leisure. In danger they step between the threat and the family (see Bandits). Personality changes how soon and how much, never the order, and a rare few put themselves first."),
		Wiki.h("What can go wrong"),
		Wiki.p("Opinions can be mistaken, or built on a lie. A good name takes years to earn and can be lost in a day. A family can still go hungry and a village can still fail: nothing makes sure it succeeds."),
		Wiki.links(["sys:courting", "sys:theft", "sys:family", "sys:bandits", "sys:trading", "sys:fighting"])], "opinion opinions reputation gossip rumour rumor lie lies liar memory forgive grudge anger stubborn stubbornness personality temperament family name trust story stories")
