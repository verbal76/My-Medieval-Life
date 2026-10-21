class_name WikiContracts
extends RefCounted
## Wiki pages for contracts (CON-01), goods that spoil and wear (DVW-B4) and ways through a cliff (B14-07). Every
## statement is taken from the code named beside it; numbers come from balance.json (GameData.b). Registered by one
## line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	var sys := func(id: String, title: String, blocks: Array, keywords := "") -> void:
		w.add_page("sys:" + id, title, "systems", blocks, "", keywords)
	_contracts(sys)
	_decay(sys)
	_cliff_ways(sys)


# Terrain (span, cost, refusal, targets_at, build); Overworld (is_top, is_rim, is_solid, note_tree, note_work, plant_refusal);
# recipes forge_nails, make_mallet; NPCBrain._smith, _carpenter_mallet (made to order for the goods merchant).
static func _cliff_ways(sys: Callable) -> void:
	var c := Terrain.cfg()
	var line := func(what: String) -> String:
		var k: Dictionary = c[what]
		var items := ", ".join((k.get("items", {}) as Dictionary).keys().map(func(id): return Terrain.count_of(id, int(k["items"][id]))))
		return "%s and %s level %d%s" % [GameData.item_name(str(k.tool)).to_lower(), str(GameData.skills[str(k.skill)].name), int(k.level),
				(", with " + items + " for each cell of rock") if items != "" else ""]
	sys.call("cliff_ways", "Cliff steps, stairs and walkways", [
		Wiki.p("The mountains outside the village are plateaus ringed by a cliff. Their tops are open ground among the pines and boulders, but nobody can walk up: you make the way yourself. Face the cliff's rocky rim from the ground, or from a top, and Use offers what you can make through it, up to %d cells of rock deep, straight on to the open ground beyond. A choice you cannot make yet is still shown, with what it needs." % int(c.max_span)),
		Wiki.h("Steps, stairs and walkways"),
		Wiki.p("Steps are cut into the rock: a %s. Wooden stairs are built against it: a %s. Both lead from the ground up to a top, or from a top down. A walkway joins one top to another across the rim between them: a %s. Each takes time and stamina, wears the tool and teaches the skill, as other work does; the planks and nails are used up." % [line.call("steps"), line.call("stairs"), line.call("walkway")]),
		Wiki.p("Nails are forged from an iron bar at the anvil, a dozen at a time; a mallet is made from a log and a plank at the workbench. The smith forges nails and the carpenter makes mallets when the goods merchant wants them, so you can buy them at the goods stall."),
		Wiki.h("Always a way back"),
		Wiki.p("A way runs both ways and is never undone, so whoever goes up can come down the same way. No way is cut from the ground through to the ground on the other side: a mountain range is never tunnelled. Nothing grows back to close a top: a tree felled on a top never grows again, and nothing can be planted there. In the village too, there is no corner you can walk into and not out of."),
		Wiki.links(["item:nails", "item:mallet", "item:pickaxe", "recipe:forge_nails", "recipe:make_mallet", "skill:mining", "skill:crafting"])],
		"cliff steps stairs walkway mountain plateau climb rim nails mallet carpentry")


# Contracts (evaluate, means, price_terms, obligations, ContractServices (means, going, plan, step, player_report), propose, fund_refusal, formal, face_to_face, npc_sign,
# buyer_answer, counter_offer, deliver, cancel, _lapse, dawn, on_death, plan, order_input); GameUI.show_contract.
static func _contracts(sys: Callable) -> void:
	var c := Contracts.cfg()
	sys.call("contracts", "Contracts", [
		Wiki.p("Anyone can offer anyone else a contract for goods: so many of an item, at so much each, by a day. Talk to a villager and choose Propose a contract: pick the goods, how many, the price for each and how many days they have, and propose it. It is an offer, not an order. They accept, refuse and say why, or answer with their own terms: their least price, the quantity they can manage, or a later day. You can agree to their terms or leave it."),
		Wiki.h("How they decide"),
		Wiki.p("They weigh what they can really do: whether they hold the goods already; whether they can mine it (a pickaxe, the skill, a seam with ore left), fell it (an axe and a tree), harvest it from their own ripe field, or make it (the skill, a workplace to use and the materials in hand); or buy it from someone selling it for less than you offer. They count the hours of work left before the day you name, less what they have already promised (other contracts, tools the manor ordered from a smith, a manor job, a day carrying at a building site, minding your stall), keep %d%% of their estimate spare in case things go wrong, and take on at most %d contracts at once. Their least price is the most of: what the goods would fetch anyway, what the materials cost them, and what the same hours earn them in their own trade. A household short of what it needs for food, fuel and rent takes a sure income for less; a friend, partner or relative asks a friend's price; a buyer who has ended contracts with them early is asked %d%% more for each. Nobody contracts with someone known for their crimes." % [roundi(float(c.risk_margin) * 100.0), int(c.max_open_per_seller), roundi(float(c.cancel_premium) * 100.0)]),
		Wiki.h("Signing"),
		Wiki.p("A small agreement, under %d coins in all, is made with a word. A bigger contract, goods or work, is signed, and only face to face: you must be with the other party when it is agreed, and a villager who wants one walks over to sign it. Nothing is signed from a distance. Until it is signed nothing is set aside, and an agreement not signed within %d days is dropped." % [int(c.formal_total), int(c.offer_days)]),
		Wiki.h("Payment and delivery"),
		Wiki.p("When they agree, the whole price is set aside from the buyer's purse: it cannot be spent on anything else, and it is paid out unit by unit as the goods are handed over. Goods can come a few at a time. A villager working on a contract mines, fells, makes or buys what it owes and brings it to a villager buyer's workplace, or to your family chest if you have a home; otherwise you collect it in the contract window. When you are the one supplying, you hand the goods over in the same window and are paid for each."),
		Wiki.h("Ending a contract"),
		Wiki.p("Either side can end a contract: what was delivered stays paid, and the rest of the coins set aside go back to the buyer. A contract not finished by its day lapses the next morning: the coins go back, and the one who did not deliver loses the buyer's regard. There is no fine. A contract cannot be changed once agreed; end it and offer another. If either side dies, it ends and the coins go back first. You can keep up to %d contracts as buyer and %d as supplier." % [int(c.max_open_player), int(c.max_open_player)]),
		Wiki.h("Hiring for work"),
		Wiki.p("A contract can be for work instead of goods, in the same window and by the same rules. Choose Or hire (the villager's name) for work: dig your own open pit (so many units, with their pickaxe; the earth goes on the pit's spoil heaps and any stone to your chest, or you collect it from them in the contract window), or survey a stain (so many readings, with their own prospector's kit, each assayed by a smith at their cost and told to you). The price is for each unit of the work, judged against what the manor pays for the same work. The coins are set aside when it is agreed (or when it is signed, for 50 coins or more) and paid as each unit is really done: agreeing does no work. A survey reading is paid whatever it shows, and a pit by the unit dug, whether or not it finds ore. Ending it early or letting it lapse works as for goods: the units done stay paid and the rest of the coins go back."),
		Wiki.h("Villagers' own contracts"),
		Wiki.p("Villagers use the same contracts. A business that has none of the materials its trade works and finds nobody selling any orders them from another villager who can supply them, at its own buying price; up to %d such orders are made each morning. If nobody in the village can, the order is offered to you: talk to them and it is in their contract window for %d days, where you can agree, decline or counter with your own quantity, price and days. They pay up to %d%% over their own price, want no fewer than they can use and no more than they asked for, and answer with the most they will pay." % [int(c.npc_orders_per_day), int(c.offer_days), roundi((float(c.npc_counter_tolerance) - 1.0) * 100.0)]),
		Wiki.links(["sys:trading", "sys:decay", "sys:manor_jobs", "sys:prospecting", "sys:open_pits", "sys:mining", "job:miner", "job:smith"])], "contract order supply deliver commission negotiate counteroffer deadline procurement")


# Decay (dawn, spoil_inv, spoil_dict, wear_clothes, condition, keeping_text); Carts.update, fall_apart, condition.
static func _decay(sys: Callable) -> void:
	var d := Decay.cfg()
	var r := func(id: String) -> String: return str(snappedf(float(d.spoil.get(id, 0.0)) * 100.0, 0.1))
	sys.call("decay", "Spoiling and wear", [
		Wiki.p("Goods do not keep for ever. Every morning a little of each stack of food spoils, wherever it is kept: in a pack, a pantry or chest, the granary, a cart, on a table or a stall. Grain keeps best: about %s in a hundred wheat are lost a day. Potatoes, cheese, carrots and ale keep well; apples, eggs, bread, berries and cooked dishes spoil within weeks (pottage and roast meat about %s in a hundred a day); milk and raw meat within days. Each item's own page and its description in your pack say how it keeps." % [r.call("wheat"), r.call("pottage")]),
		Wiki.h("Clothes, armour and carts"),
		Wiki.p("Clothes and armour wear a little every day they are worn, by you and by villagers alike. Your pack shows how much wear each has left, and how it looks: new, worn, well worn or falling apart. When it wears out it is gone. A handcart wears with the ground it is pulled over: it lasts about %d tiles of pulling, and when it falls apart its load is left lying where it stood for its owner to take up. The prompt beside your cart says its condition." % int(d.cart_tiles)),
		Wiki.links(["item:wheat", "item:plain_clothes", "item:handcart", "sys:contracts"])], "spoil spoilage rot decay wear worn clothes armour cart durability keep")
