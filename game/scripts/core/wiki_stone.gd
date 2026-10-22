class_name WikiStone
extends RefCounted
## The wiki's page for stoneworking (STONE-01, owner decision 2026-10-21: raw quarry stone and finished building blocks
## are separate goods; docs/build17/STONE_01_BLOCKS.md). Every statement is taken from the code named beside it; numbers
## come from recipes.json (dress_stone) and balance.json (house_cost, workshop_cost). Registered by one line in Wiki.build.


static func add_pages(w: Wiki) -> void:
	_stoneworking(w)
	w.add_page("todo:stonecutters", "Stonecutters and villagers dressing their own stone", "notyet", [   # STONE-02, X18-STONECUT
		Wiki.note("Not in the game yet. A stonecutter's trade: a villager who keeps a workshop, buys or quarries raw stone, dresses it into blocks and sells them to anyone who wants them, or makes them to order. Also not built yet: villagers who are not labourers dressing blocks for their own house or repairs. Both will use the same dressing as today: the same workbench, mallet, stone and time. Also planned: how much of the stone becomes blocks depending on the worker's skill, the rest left as chips and spoil. Also planned: an iron chisel, made by smiths, used with the mallet. Today dressing trains and needs your Masonry skill and a mallet, and two stone always make two blocks."),
		Wiki.links(["sys:stoneworking", "recipe:dress_stone", "job:laborer"], "See also")], "", "not implemented planned stonecutter mason")


# recipe dress_stone (World.work_craft: tool, exact; player_craft_refusal); NPCBrain._mason, _block_demand, BUYS.merchant_raw,
# OUTLETS, KEEPS.laborer; Construction.SELLERS; balance house_cost, workshop_cost, shop_equipment, farm_plot.gate_stone;
# World.site_cost (older sites keep their stone).
static func _stoneworking(w: Wiki) -> void:
	var r: Dictionary = GameData.recipes["dress_stone"]
	var stone_in := int(r["in"]["stone"])
	var out := int(r.out["building_block"])
	var house := int(GameData.b("house_cost").get("building_block", 0))
	w.add_page("sys:stoneworking", "Stoneworking: building blocks", "systems", [
		Wiki.p("Stone comes out of the ground rough. Quarried stone (from stone seams, the grey rock left when an ore seam is worked out, and boulders) is raw stone; a house or a workshop is built of building blocks, dressed from that stone by hand. Nothing turns stone into blocks by itself: someone has to do the work."),
		Wiki.h("Dressing stone"),
		Wiki.p("At a workbench, with a mallet in your pack, %d raw stone are dressed into %d building blocks in %d minutes of work. It needs %s level %d and teaches it; the mallet wears with use. A skilled hand works faster, but never gets more blocks than the stone allows." % [stone_in, out, int(r.minutes), str(GameData.skills[str(r.skill)].name), int(r.level)]),
		Wiki.p("A mallet is made from a log and a plank at the workbench, or bought at the goods stall when the carpenter has made some."),
		Wiki.h("What needs blocks"),
		Wiki.p("Houses (%d blocks), every workshop and every room added to a property take building blocks; each room's page lists how many. Raw stone is still what the oven, stove and forge you fit in a room take, what the gate of family farmland takes, and what the manor mends the roads, bridges and well with. A building site marked out before blocks were needed still takes the stone it was planned with." % house),
		Wiki.h("Who makes them"),
		Wiki.p("No trade is needed to dress stone: you can dress your own at any workbench you may use, with a mallet, two stone at a time, for your own building or to sell. Among the villagers, the labourers are the stoneworkers. When the raw-goods merchants want blocks for builders, or the village's building sites need more than are on sale, a labourer with a mallet dresses the stone they have quarried at a workbench and sells the blocks to the raw-goods merchant; a labourer without one buys a mallet first. When nobody wants blocks, nobody dresses any. Builders and their hired helpers buy blocks from the raw-goods merchants and the labourers, as they buy planks and logs. The caravan brings raw stone, never blocks, and does not carry the village's blocks away."),
		Wiki.links(["item:stone", "item:building_block", "item:mallet", "recipe:dress_stone", "recipe:make_mallet", "skill:masonry", "job:laborer", "sys:property_modules", "todo:stonecutters"])],
		"", "stone block building block mason stoneworking dress quarry mallet workbench construction house")
