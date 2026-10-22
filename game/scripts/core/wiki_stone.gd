class_name WikiStone
extends RefCounted
## The wiki's page for stoneworking (STONE-01, owner decision 2026-10-21: raw quarry stone and finished building blocks
## are separate goods; docs/build17/STONE_01_BLOCKS.md). Every statement is taken from the code named beside it; numbers
## come from recipes.json (dress_stone) and balance.json (house_cost, workshop_cost). Registered by one line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	_stoneworking(w)
	w.add_page("todo:stonecutters", "Stonecutters: what is still to come", "notyet", [   # X18-STONECUT
		Wiki.note("Not in the game yet. The stonecutter does not yet keep a workshop of its own with a stock of stone, tools and blocks, hire help, or hire help (hiring belongs to a later build): it buys stone and sells blocks to the raw-goods merchant and to builders, and may take an order for blocks through an ordinary goods contract. Villagers also do not yet tell routine mending from rebuilding when they choose between raw stone and blocks: houses and workshops take blocks, hearths, fittings and the manor's mending take raw stone, as before."),
		Wiki.links(["sys:stoneworking", "recipe:dress_stone", "job:stonecutter", "job:laborer"], "See also")], "", "not implemented planned stonecutter workshop orders")


# recipes dress_stone, forge_chisel (World.work_craft: tool list; player_craft_refusal); NPCBrain._mason, _stonecutter, stonecutter_place,
# _fetch_dress_tool, _block_demand, BUYS.merchant_raw, BUYS.stonecutter, OUTLETS, KEEPS; Construction.SELLERS, _dress_own; balance house_cost, workshop_cost, shop_equipment, farm_plot.gate_stone;
# World.site_cost (older sites keep their stone).
static func _stoneworking(w: Wiki) -> void:
	var r: Dictionary = GameData.recipes["dress_stone"]
	var stone_in := int(r["in"]["stone"])
	var out := int(r.out["building_block"])
	var house := int(GameData.b("house_cost").get("building_block", 0))
	w.add_page("sys:stoneworking", "Stoneworking: building blocks", "systems", [
		Wiki.p("Stone comes out of the ground rough. Quarried stone (from stone seams, the grey rock left when an ore seam is worked out, and boulders) is raw stone; a house or a workshop is built of building blocks, dressed from that stone by hand. Nothing turns stone into blocks by itself: someone has to do the work."),
		Wiki.h("Dressing stone"),
		Wiki.p("At a workbench, with a mallet and an iron chisel in your pack, %d raw stone are dressed in %d minutes of work into %d building blocks and one piece of rubble. Rubble is not stone to dress: it cannot be dressed again, but it serves as raw stone for raw-stone work (fitting a hearth, the farmland gate, mending the roads, bridges and well) and the raw-goods merchant buys it. Nothing is lost: every stone becomes a block or rubble. It needs %s level %d and teaches it. A mallet and a chisel each wear a use for every batch." % [stone_in, int(r.minutes), out, str(GameData.skills[str(r.skill)].name), int(r.level)]),
		Wiki.p("Your Masonry skill is the whole of your skill here, the same for everyone whatever their trade: at Masonry 3 and 7 the work goes faster, at 5, 7, 9 and 10 a practised hand sometimes turns the rubble of a batch into a third block: three stone make three blocks and no rubble. Never more blocks than the stone used, and the less practised make more rubble. No title gives anything more."),
		Wiki.p("A mallet is made from a log and a plank at the workbench, or bought at the goods stall when the carpenter has made some. An iron chisel is forged by the smith from one iron bar at the anvil, and the goods stall sells them when the smith has made some. A chisel wears out after 150 batches and is gone; without both tools the work is refused."),
		Wiki.h("What needs blocks"),
		Wiki.p("Houses (%d blocks), every workshop and every room added to a property take building blocks; each room's page lists how many. Raw stone is still what the oven, stove and forge you fit in a room take, what the gate of family farmland takes, and what the manor mends the roads, bridges and well with. A building site marked out before blocks were needed still takes the stone it was planned with." % house),
		Wiki.h("Who makes them"),
		Wiki.p("No trade is needed to dress stone: anyone with Masonry, a mallet and an iron chisel can dress at any workbench they may use, three stone at a time, for their own building or to sell. The villagers are under the same rule. A villager building their own house, who finds no blocks on sale, dresses stone themselves when they have the tools (or can pay for them) and the stone, and puts the blocks into the house. The labourers dress the stone they have quarried when the raw-goods merchants want blocks or building sites need more than are on sale, and buy a missing mallet or chisel first."),
		Wiki.p("The stonecutter is a trade of its own, taken up by a villager without work when blocks are wanted and stone is on sale. It buys raw stone with its own coins, dresses it and sells the blocks to the raw-goods merchant and to builders, and its rubble to the merchant too. Nothing is given to it: when nobody wants blocks it dresses none and earns nothing, and it may fail like any other trade. Builders and their hired helpers buy blocks from the raw-goods merchants, the labourers and the stonecutters, as they buy planks and logs. The caravan brings raw stone, never blocks, and does not carry the village's blocks away."),
		Wiki.links(["item:stone", "item:building_block", "item:mallet", "item:chisel", "recipe:dress_stone", "recipe:make_mallet", "recipe:forge_chisel", "skill:masonry", "job:laborer", "job:stonecutter", "sys:property_modules", "todo:stonecutters"])],
		"", "stone block building block mason stoneworking dress quarry mallet workbench construction house")
