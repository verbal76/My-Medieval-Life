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
		Wiki.links(["item:nails", "item:mallet", "item:pickaxe", "recipe:forge_nails", "recipe:make_mallet", "skill:mining", "skill:carpentry"])],
		"cliff steps stairs walkway mountain plateau climb rim nails mallet carpentry")


# Contracts (evaluate, means, price_terms, obligations, ContractServices (means, going, plan, step, player_report, player_harvest,
# terms_refusal, price_needed, pay_for, hold_of, spend_advance, favour_refusal, ruling, npc_hire), dispute, rule, propose, fund_refusal, formal, face_to_face, npc_sign,
# buyer_answer, counter_offer, deliver, cancel, _lapse, dawn, on_death, plan, order_input); GameUI.show_contract.
static func _contracts(sys: Callable) -> void:
	var c := Contracts.cfg()
	var sv := ContractServices.cfg()
	var sl := int(sv.formal_total) if sv.get("formal_total") != null else int(c.formal_total)     # CON-08: the services' own line, once set
	sys.call("contracts", "Contracts", [
		Wiki.p("Anyone can offer anyone else a contract for goods: so many of an item, at so much each, by a day. Talk to a villager and choose Propose a contract. A short form takes you through it a step at a time: the goods, how many, the price for each and how many days they have, each with large - and + buttons and Next and Back; the last step says the whole agreement in one sentence, such as \"Emma delivers 10 logs by the end of day 5 for 30 coins\", and you confirm it with Propose. It is an offer, not an order. They accept, refuse and say why, or answer with their own terms: their least price, the quantity they can manage, or a later day. You can agree to their terms or leave it."),
		Wiki.h("How they decide"),
		Wiki.p("They weigh what they can really do: whether they hold the goods already; whether they can mine it (a pickaxe, the skill, a seam with ore left), fell it (an axe and a tree), harvest it from their own ripe field, or make it (the skill, a workplace to use and the materials in hand); or buy it from someone selling it for less than you offer. They count the hours of work left before the day you name, less what they have already promised (other contracts, tools the manor ordered from a smith, a manor job, a day carrying at a building site, minding your stall), keep %d%% of their estimate spare in case things go wrong, and take on at most %d contracts at once. Their least price is the most of: what the goods would fetch anyway, what the materials cost them, and what the same hours earn them in their own trade. A household short of what it needs for food, fuel and rent takes a sure income for less; a friend, partner or relative asks a friend's price; a buyer who has ended contracts with them early is asked %d%% more for each. Nobody contracts with someone known for their crimes." % [roundi(float(c.risk_margin) * 100.0), int(c.max_open_per_seller), roundi(float(c.cancel_premium) * 100.0)]),
		Wiki.h("Signing"),
		Wiki.p("A small agreement, under %d coins in all, is made with a word. A bigger contract, goods or work, is signed, and only face to face: you must be with the other party when it is agreed, and a villager who wants one walks over to sign it. Nothing is signed from a distance. Until it is signed nothing is set aside, and an agreement not signed within %d days is dropped." % [int(c.formal_total), int(c.offer_days)]),
		Wiki.h("Payment and delivery"),
		Wiki.p("When they agree, the whole price is set aside from the buyer's purse: it cannot be spent on anything else, and it is paid out unit by unit as the goods are handed over. Goods can come a few at a time. A villager working on a contract mines, fells, makes or buys what it owes and brings it to a villager buyer's workplace, or to your family chest if you have a home; otherwise you collect it in the contract window. When you are the one supplying, you hand the goods over in the same window and are paid for each."),
		Wiki.h("Ending a contract"),
		Wiki.p("Either side can end a contract: what was delivered stays paid, and the rest of the coins set aside go back to the buyer. A contract not finished by its day lapses the next morning: the coins go back, and the one who did not deliver loses the buyer's regard. There is no fine. A contract cannot be changed once agreed; end it and offer another. If either side dies, it ends and the coins go back first. You can keep up to %d contracts as buyer and %d as supplier." % [int(c.max_open_player), int(c.max_open_player)]),
		Wiki.h("Hiring for work"),
		Wiki.p("A contract can be for work instead of goods, in the same window and by the same rules. Choose Or hire (the villager's name) for work: dig your own open pit (so many units, with their own shovel for the earth and pickaxe for the rock; the earth goes on the pit's spoil heaps and any stone to your chest, or you collect it from them in the contract window), survey a stain (so many readings, with their own prospector's kit, each assayed by a smith and told to you), or harvest your own field (so many ripe cells, cut by hand and brought to your chest at home: the crop stays yours, the worker never keeps it, so you need a home for it to go to). The price is for each unit of the work, judged against what the manor pays for the same work. The coins are set aside when it is agreed (or when it is signed, for %d coins or more) and paid as each unit is really done: agreeing does no work. Ending it early or letting it lapse works as for goods: the units done stay paid and the rest of the coins go back. Doing the work trains the worker's skill, as the same work does anywhere." % sl),
		Wiki.h("How hired work is paid"),
		Wiki.p("Before you propose, the last step lets you choose how the work is paid. For the work done is the usual way: every unit is paid as it is done, a survey reading whatever it shows and a pit by the unit dug, whether or not it finds anything. For results only pays only the units that bring something: a dig that brings up stone, a reading that shows a trace of ore. A barren one pays nothing, so a worker asks about %d times as much a unit for the risk, and may turn it down. A base and a bonus pays every unit and adds a bonus for each one with a result. Whatever you choose, the most it could cost is set aside when it is agreed, and what is not earned comes back to you. A harvest is always paid for the work: every cell cut is the result." % roundi(float(sv.get("result_premium", 2.0)))),
		Wiki.p("You can also hold back part of each payment, up to %d%%, until the whole job is done: it is paid over when the last unit is finished. For a survey you can advance the assay fees: they are set aside with the price and paid out only when a smith is paid to assay a sample for the job, so a worker short of coins can still take it on; what is not spent comes back to you, and a worker paid an advance does not ask for the fees again in the price." % roundi(100.0 * float(sv.get("retain_max", 0.5)))),
		Wiki.h("Favours"),
		Wiki.p("Work does not always need paying. Choose to pay as a favour and nothing is set aside or paid: a friend, partner or relative may do it for you for nothing, if they can spare the time and are not already doing you a favour. Anyone else asks for pay. A favour is never a signed contract, however big the job. A favour done earns the regard a help does."),
		Wiki.h("Disputes"),
		Wiki.p("If a job with pay held back ends before it is done, the coins held back stay held until the reeve rules on them. Either side can bring it before the reeve in the contract window; if nobody does, the reeve rules after %d days all the same. The reeve goes by the agreement and the record of the work, and either side can win: when the work was all done, when the buyer ended it, when the worker died after doing some of it, or when there was no work left to do on the buyer's ground, the worker is paid what was held back; when the worker gave up or let the day pass with work still to be done, it goes back to the buyer. Nothing is taken by anyone else." % int(sv.get("dispute_days", 3))),
		Wiki.h("Working for hire"),
		Wiki.p("Villagers can hire you too. When one offers you work it waits in their contract window for %d days. Hired to harvest a field, face its ripe cells and Use offers to harvest them for the owner: each cell takes the time your own harvest does, the crop goes straight into the owner's store and never into your pack, and you are paid for each cell and learn farming from the work. Cutting a field you are hired for is not theft." % int(c.offer_days)),
		Wiki.h("Villagers' own contracts"),
		Wiki.p("Villagers use the same contracts. A business that has none of the materials its trade works and finds nobody selling any orders them from another villager who can supply them, at its own buying price; up to %d such orders are made each morning. If nobody in the village can, the order is offered to you: talk to them and it is in their contract window for %d days, where you can agree, decline or counter with your own quantity, price and days. They pay up to %d%% over their own price, want no fewer than they can use and no more than they asked for, and answer with the most they will pay." % [int(c.npc_orders_per_day), int(c.offer_days), roundi((float(c.npc_counter_tolerance) - 1.0) * 100.0)]),
		Wiki.p("A household with a ripe field it cannot cut itself, because its members are too hurt or too few to do it within a couple of days, may hire help: only if the crop is worth more than the pay and it can spare the coins. It asks villagers of other households in turn, one who has served it well before first; any of them may say no. If nobody will, the work is offered to you. A household that can cut its own field hires nobody, and nobody is sure to be found."),
		Wiki.links(["sys:trading", "sys:decay", "sys:manor_jobs", "sys:prospecting", "sys:open_pits", "sys:mining", "sys:farming", "job:miner", "job:smith"])], "contract order supply deliver commission negotiate counteroffer deadline procurement hire service favour harvest bonus retention dispute reeve advance")


# Decay (dawn, spoil_inv, spoil_dict, wear_clothes, condition, keeping_text); Carts.update, fall_apart, condition.
static func _decay(sys: Callable) -> void:
	var d := Decay.cfg()
	var r := func(id: String) -> String: return str(snappedf(float(d.spoil.get(id, 0.0)) * 100.0, 0.1))
	sys.call("decay", "Spoiling and wear", [
		Wiki.p("Goods do not keep for ever. Every morning a little of each stack of food spoils, wherever it is kept: in a pack, a pantry or chest, the granary, a cart, on a table or a stall. Grain keeps best: about %s in a hundred wheat are lost a day. Potatoes, cheese, carrots and ale keep well; apples, eggs, bread, berries and cooked dishes spoil within weeks (pottage and roast meat about %s in a hundred a day); milk and raw meat within days. Each item's own page and its description in your pack say how it keeps." % [r.call("wheat"), r.call("pottage")]),
		Wiki.h("Clothes, armour and carts"),
		Wiki.p("Clothes and armour wear a little every day they are worn, by you and by villagers alike. Your pack shows how much wear each has left, and how it looks: new, worn, well worn or falling apart. When it wears out it is gone. Wear stays with a thing when it changes hands: a worn tool, weapon or piece of clothing sold, given, put up at a stall, stored, inherited or picked up is just as worn for its new owner. When you hold several of one kind, the one you have been using is the worn one, and it goes with the last of them. A handcart wears with the ground it is pulled over: it lasts about %d tiles of pulling, and when it falls apart its load is left lying where it stood for its owner to take up. The prompt beside your cart says its condition." % int(d.cart_tiles)),
		Wiki.links(["item:wheat", "item:plain_clothes", "item:handcart", "sys:contracts"])], "spoil spoilage rot decay wear worn clothes armour cart durability keep")
