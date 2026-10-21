class_name WikiContracts
extends RefCounted
## Wiki pages for contracts (CON-01) and goods that spoil and wear (DVW-B4). Every statement is taken from the code
## named beside it; numbers come from balance.json (GameData.b). Registered by one line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	var sys := func(id: String, title: String, blocks: Array, keywords := "") -> void:
		w.add_page("sys:" + id, title, "systems", blocks, "", keywords)
	_contracts(sys)
	_decay(sys)


# Contracts (evaluate, means, min_price, propose, fund_refusal, deliver, cancel, _lapse, dawn, on_death, plan,
# order_input); GameUI.show_contract.
static func _contracts(sys: Callable) -> void:
	var c := Contracts.cfg()
	sys.call("contracts", "Contracts", [
		Wiki.p("Anyone can offer anyone else a contract for goods: so many of an item, at so much each, by a day. Talk to a villager and choose Propose a contract: pick the goods, how many, the price for each and how many days they have, and propose it. It is an offer, not an order. They accept, refuse and say why, or answer with their own terms: their least price, the quantity they can manage, or a later day. You can agree to their terms or leave it."),
		Wiki.h("How they decide"),
		Wiki.p("They weigh what they can really do: whether they hold the goods already; whether they can mine it (a pickaxe, the skill, a seam with ore left), fell it (an axe and a tree), harvest it from their own ripe field, or make it (the skill, a workplace to use and the materials in hand); or buy it from someone selling it for less than you offer. They count the hours of work left before the day you name, less what they have already promised, and take on at most %d contracts at once. Their least price is what the goods would fetch anyway; a household short of what it needs for food, fuel and rent takes a sure income for less, and a friend asks a friend's price. Nobody contracts with someone known for their crimes." % int(c.max_open_per_seller)),
		Wiki.h("Payment and delivery"),
		Wiki.p("When they agree, the whole price is set aside from the buyer's purse: it cannot be spent on anything else, and it is paid out unit by unit as the goods are handed over. Goods can come a few at a time. A villager working on a contract mines, fells, makes or buys what it owes and brings it to a villager buyer's workplace, or to your family chest if you have a home; otherwise you collect it in the contract window. When you are the one supplying, you hand the goods over in the same window and are paid for each."),
		Wiki.h("Ending a contract"),
		Wiki.p("Either side can end a contract: what was delivered stays paid, and the rest of the coins set aside go back to the buyer. A contract not finished by its day lapses the next morning: the coins go back, and the one who did not deliver loses the buyer's regard. There is no fine. A contract cannot be changed once agreed; end it and offer another. If either side dies, it ends and the coins go back first. You can keep up to %d contracts as buyer and %d as supplier." % [int(c.max_open_player), int(c.max_open_player)]),
		Wiki.h("Villagers' own contracts"),
		Wiki.p("Villagers use the same contracts. A business that has none of the materials its trade works and finds nobody selling any orders them from another villager who can supply them, at its own buying price; up to %d such orders are made each morning. If nobody in the village can, the order is offered to you: talk to them and it is in their contract window for %d days." % [int(c.npc_orders_per_day), int(c.offer_days)]),
		Wiki.links(["sys:trading", "sys:decay", "job:miner", "job:smith"])], "contract order supply deliver commission negotiate counteroffer deadline procurement")


# Decay (dawn, spoil_inv, spoil_dict, wear_clothes, condition, keeping_text); Carts.update, fall_apart, condition.
static func _decay(sys: Callable) -> void:
	var d := Decay.cfg()
	var r := func(id: String) -> String: return str(snappedf(float(d.spoil.get(id, 0.0)) * 100.0, 0.1))
	sys.call("decay", "Spoiling and wear", [
		Wiki.p("Goods do not keep for ever. Every morning a little of each stack of food spoils, wherever it is kept: in a pack, a pantry or chest, the granary, a cart, on a table or a stall. Grain keeps best: about %s in a hundred wheat are lost a day. Potatoes, cheese, carrots and ale keep well; apples, eggs, bread, berries and cooked dishes spoil within weeks (pottage and roast meat about %s in a hundred a day); milk and raw meat within days. Each item's own page and its description in your pack say how it keeps." % [r.call("wheat"), r.call("pottage")]),
		Wiki.h("Clothes, armour and carts"),
		Wiki.p("Clothes and armour wear a little every day they are worn, by you and by villagers alike. Your pack shows how much wear each has left, and how it looks: new, worn, well worn or falling apart. When it wears out it is gone. A handcart wears with the ground it is pulled over: it lasts about %d tiles of pulling, and when it falls apart its load is left lying where it stood for its owner to take up. The prompt beside your cart says its condition." % int(d.cart_tiles)),
		Wiki.links(["item:wheat", "item:plain_clothes", "item:handcart", "sys:contracts"])], "spoil spoilage rot decay wear worn clothes armour cart durability keep")
