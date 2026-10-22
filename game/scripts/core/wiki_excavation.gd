class_name WikiExcavation
extends RefCounted
## Wiki pages for digging (Build 17, owner directive 2026-10-21, the consolidated fourteen decisions;
## docs/build17/MIN_PARITY_SHOVELS.md): shovels and pickaxes (MIN-SHOVEL), the earth a trial pit moves (MIN-D3), where
## anyone may dig (MIN-RIGHTS) and the village's mining capability (MIN-D2, MIN-SKILLCAP). Every statement is taken from
## the code named beside it; exact balance numbers are left for play. Registered by Wiki.build as a provider.


static func add_pages(w: Wiki) -> void:
	var sys := func(id: String, title: String, blocks: Array, keywords := "") -> void:
		w.add_page("sys:" + id, title, "systems", blocks, "", keywords)
	_tools(sys)
	_trial_earth(sys)
	_where(sys)
	_capability(sys)


# open_pit.json layers' tool; OpenPits.tool_of, tool_needed, dig_refusal; Discovery.trial_refusal (trial.tool);
# MineWorks.tool_kind, dig_refusal; recipes forge_shovel_blade, make_shovel_haft, assemble_shovel; NPCBrain._carpenter_shovel,
# _smith (forge_shovel_blade for the carpenter), _buy_tool, BUYS merchant_goods shovel; Inventory.wear.
static func _tools(sys: Callable) -> void:
	sys.call("digging_tools", "Shovels and pickaxes", [
		Wiki.p("Digging needs the right tool for what is in the ground. Loose earth (topsoil, dirt and spoil) is dug with a shovel; rock and stone are broken with a pickaxe. A pickaxe will not shift earth and a shovel will not break rock: the game tells you which you need when you try."),
		Wiki.bullets([
			"An open pit: its upper layers (topsoil, then dirt, then spoil) take a shovel; the stone beneath them takes a pickaxe.",
			"A trial pit goes down through the earth to the rock face, so it takes a shovel.",
			"Below ground, cutting into the rock takes a pickaxe; rock that has fallen in, or spoil packed back into a passage, is loose and is dug out with a shovel.",
			"Seams of ore and stone are mined with a pickaxe, as always."]),
		Wiki.h("Making a shovel"),
		Wiki.p("A shovel is made in two parts. The smith forges the iron blade at the anvil from an iron bar; the carpenter makes the wooden haft from a plank at the workbench; the two are fitted together at the workbench. You can make all three yourself with the skills, the materials and the stations, by the same recipes the villagers use."),
		Wiki.p("The carpenter makes shovels when the goods merchant wants some to sell, buying the blade from the smith, so you can usually buy one at the goods stall. A miner who needs a shovel for posted digging work buys one there with its own coins if one is for sale."),
		Wiki.h("Wear"),
		Wiki.p("Every unit dug wears the tool used, a shovel just as a pickaxe; skill in Mining sometimes spares it. A worn-out tool breaks and is gone. Nothing mends a shovel or a pickaxe: buy or make another."),
		Wiki.links(["item:shovel", "item:pickaxe", "item:shovel_blade", "item:shovel_haft", "recipe:forge_shovel_blade", "recipe:make_shovel_haft",
				"recipe:assemble_shovel", "item:topsoil", "item:dirt", "item:spoil", "job:carpenter", "job:smith", "skill:mining"])],
		"shovel spade pickaxe dig earth topsoil dirt spoil rock tool wear blade haft")


# Discovery.trial_dig, trial_earth, pile_cell (a loot pile "a trial pit"); World.player_loot; OpenPits.backfill, tip;
# Census (loot); Decay (piles not from "the ..." do not rot).
static func _trial_earth(sys: Callable) -> void:
	sys.call("trial_pit_earth", "The earth from a trial pit", [
		Wiki.p("A trial pit is dug down through the topsoil, the dirt below it and the broken spoil above the rock. That earth is not lost: it is heaped in a spoil pile on the ground just south of the pit, whether you dug the pit or a villager did."),
		Wiki.p("The pile is ordinary goods lying on the ground. Anyone can take it up and carry it away like any goods, tip it on an open pit's spoil heap, or put it back into an open pit you are filling (the last layer dug goes back first, so topsoil goes back on top). Earth does not rot, and it has no buyer at the market."),
		Wiki.note("The trial pit itself is not filled back: only open pits take earth back. Nobody fills in a tunnel below ground on their own."),
		Wiki.links(["sys:digging_tools", "item:topsoil", "item:dirt", "item:spoil"])],
		"trial pit earth spoil pile topsoil dirt backfill heap carry")


# OpenPits.site_refusal, ground_refusal (World.plant_refusal: parcels, buildings, fields, pens, farmland); Discovery.ground_refusal;
# Underground.under_rock and MineWorks.rock_refusal (tunnels only under the hill's bare rock); Property.can_claim; no permit code.
static func _where(sys: Callable) -> void:
	sys.call("digging_ground", "Where you may dig", [
		Wiki.p("Open common ground of the village is open to everyone with the right tools: you and the villagers alike may stake an open pit or dig a trial pit there. The manor asks no permit, fee or share for it, and owns nothing found there just because it runs the village."),
		Wiki.p("Ground that somebody holds is not yours to dig: a parcel or house another household or the manor holds, the manor's fields, farmland and animal pens are refused, as are roads, doorways, the market and worked places. Below ground, tunnels are cut only into the hill's bare rock, under no one's land."),
		Wiki.p("You may hire someone to dig your own pit by a contract: then they dig it with your agreement."),
		Wiki.links(["sys:digging_tools", "sys:contracts"])],
		"dig where common ground land owner parcel permit rights field pit trial tunnel")


# Discovery.player_resident, residents, practitioner, practitioners, tool_stock, evaluate, dawn; capabilities.json.
static func _capability(sys: Callable) -> void:
	sys.call("mining_capability", "The village's mining capability", [
		Wiki.p("The village's skill at mining is judged afresh each morning from what its people really have: those able to mine, with the right tools in hand or at home, prospectors' kits, a smith to assay ore, the forge, what has been found, and the works dug. When it rises or falls the journal says so, and why."),
		Wiki.p("People count for what they can do, not for their trade's name: anyone with a pickaxe and the skill counts as a miner, anyone with a shovel as a digger, anyone with a prospector's kit as a prospector. A tool kept at home serves one person, not the whole household."),
		Wiki.p("You count by exactly the same rules while your family has a home in the village: your skills and the tools in your pack or your family chest. Counting them changes nothing about whose they are; they stay yours. Without a home here you are not counted."),
		Wiki.note("The level is only reported: it never stops anyone from digging, prospecting or taking work."),
		Wiki.links(["sys:digging_tools", "skill:mining", "job:miner", "job:smith"])],
		"mining capability level village skill equipment resident prospector miner digger")
