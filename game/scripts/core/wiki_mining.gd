class_name WikiMining
extends RefCounted
## Wiki pages for Build 17 mining and geology (WIKI-B17): deposits that run out and the grey rock after them, prospecting
## and trial pits, open pits, the adit gallery and the cave, tunnels and timber supports, track and minecarts, shafts and
## ladders, stability, backfilling, and the Build 17 ideas that are approved but not built yet ("Not in the game yet").
## Every statement is taken from the code named beside it; counts the player sees in a prompt come from the data files.
## Written for the player: no internals, no formula values. The developer's reference is docs/build17/README.md.
## Registered by one line in Wiki.build.

## Player-facing replacements for the technical texts of the mining resource nodes and materials (resources.json keeps
## its code-facing wording for the manifests). Wiki._nodes uses "where", "back", "notes" and "hint"; Wiki._items uses USE_TEXT.
const NODE_TEXT := {
	"iron_seam": {"back": "No. When the ore is out, the grey rock around it can still be quarried for stone, and then the cell opens."},
	"coal_seam": {"back": "No. When the coal is out, the grey rock around it can still be quarried for stone, and then the cell opens."},
	"copper_seam": {"back": "No. When the ore is out, the grey rock around it can still be quarried for stone, and then the cell opens."},
	"gold_seam": {"back": "No. When the ore is out, the grey rock around it can still be quarried for stone, and then the cell opens."},
	"stone_seam": {
		"where": "In the mine north of the village and in the mine gallery under the hill, and as the grey rock left round every worked-out ore seam.",
		"back": "No. When the stone is out, the rock is gone and the cell is open ground."},
	"boulder": {"back": "No. A boulder broken up is gone for good and its cell is open ground."},
	"prospect_clue": {
		"where": "On wild open ground away from the houses, lanes, fields and market (the woods, the hills and the village's edges): a rust-red stain, black streaks, green-stained pebbles or a glitter of flecks in the gravel. A stain marks a search area a few cells wide, not a deposit.",
		"back": "No. A spot sampled stays sampled, and when every spot round a stain has been sampled it stays sampled out. The stain itself stays.",
		"notes": "One rock sample for each spot sampled. A sample is worth nothing until a smith assays it at the forge, for a fee."},
	"open_pit": {
		"where": "Marked out on clear common ground in the village by you, with a shovel or a pickaxe in hand, or by the manor. A square pit with a clear walkway round it and spoil heaps beside it. Pits are on the surface only.",
		"back": "No. A pit's ground only goes down as it is dug, and rises only when earth is put back.",
		"notes": "One unit a dig, of the layer the cell is down to: topsoil, then dirt, then spoil, then stone. The edge of a pit is dug two layers down, the next ring three and the middle all four, so the sides are terraced; a ramp stays walkable. A cell dug down to the rock near a stain's ore opens a seam.",
		"hint": "Earth is dug with a shovel and rock with a pickaxe. The smith sells them, or forge one at the anvil (2 iron bars and a plank)."},
	"tunnel_rock": {
		"where": "The rock beside the floor of the mine gallery and the cave under the hill, and of any deeper level, where the hill's rock is thick enough all round.",
		"back": "No. A cell cut through stays open; no rock grows back.",
		"notes": "One unit a cut: each cell of rock gives stone first, then spoil, and the last unit opens the cell as floor. Rock is cut only within reach of a timber support.",
		"hint": "You need a pickaxe to cut rock, and a timber support standing within 2 cells of the face."},
}

const USE_TEXT := {
	"topsoil": ["Put back into an open pit cell whose last unit dug was topsoil, or tipped onto the pit's spoil heaps and taken back from them. It has no buyer."],
	"dirt": ["Put back into an open pit cell whose last unit dug was dirt, or tipped onto the pit's spoil heaps and taken back from them. It has no buyer."],
	"spoil": ["Put back into an open pit cell, or into a passage below ground (by you, or by a worker on your paid order). It has no buyer."],
	"ore_sample": ["Taken to a smith at the forge to be assayed for a fee; the sample is used up and the smith tells you what it showed."],
	"timber_support": ["Set up on the floor of a tunnel with a mallet; rock within 2 cells of it may be cut. It wears, and is repaired with a plank."],
	"track_section": ["Laid one a cell with a mallet on a tunnel floor or in the mine's yard; a minecart runs on it."],
	"ladder": ["Set into a finished shaft with a mallet so that it can be climbed. It wears, and is repaired with a plank and nails."],
}


static func add_pages(w: Wiki) -> void:
	var sys := func(id: String, title: String, blocks: Array, keywords := "") -> void:
		w.add_page("sys:" + id, title, "systems", blocks, "", keywords)
	_overview(sys)
	_prospecting(sys)
	_open_pits(sys)
	_underground(sys)
	_minecarts(sys)
	_shafts(sys)
	_stability(sys)
	_backfill(sys)
	_not_yet(w)


static func _mc() -> Dictionary:
	return MineWorks.cfg()


# World.deposit_at, mine_unit, work_mine, _open_quarried, nearest_seam, quarry_stone_left; main.gd deposit prompt;
# NPCBrain._miner (labourers, miners, the manor's quarry); Discovery.dawn, evaluate (capabilities.json).
static func _overview(sys: Callable) -> void:
	var host := int(GameData.b("quarry_host_stone"))
	sys.call("mining", "Mining and quarrying", [
		Wiki.p("Every deposit in the game is finite. Stand in front of a seam or a boulder with a pickaxe and the prompt names it and says how much is left: Mine iron ore (14 left). A swing takes one unit (now and then a second, with Mining skill), and the seam goes down by what is taken. Nothing ever puts it back. The ore in the ground was there from the start: prospecting and digging find it, they do not make it."),
		Wiki.h("Worked-out seams and boulders"),
		Wiki.p("When an ore seam gives its last ore it is drawn as hollow grey rock, but it is not finished. The rock around the ore can be quarried for plain stone: the prompt now reads Mine stone, with a count of its own (%d stone to start with, the same round any ore). A gold seam's grey rock is plain stone and needs no Mining 3. When the last stone is out the rock is gone, and the cell is open ground you can walk onto. A boulder is quarried the same way and leaves open ground too." % host),
		Wiki.h("Where the ore is"),
		Wiki.p("The seams in the mine yard either side of the track; the seams on the walls of the gallery and the cave under the hill, which you reach through the adit and the cave's mouth (see the underground pages); seams found by prospecting; and ore hidden deep in the rock that a tunnel or a shaft may uncover. The stone is in the stone seams, the grey rock round worked-out seams and the boulders."),
		Wiki.h("Who mines"),
		Wiki.p("Villagers mine by the same rules as you: the same pickaxe, the same skill levels, the same wear. Miners and labourers walk into the adit or the cave when the ore they want lies below, dig it and carry it out. They sell ore and stone at ordinary prices to the smith and the raw-goods merchant, on their own account: there is no mining wage. Labourers quarry stone while the raw-goods merchant buys it; a miner whose ore is worked out takes what someone will buy, or the manor's trial pit and excavation work. The manor posts a quarry job for its works yard. A buyer can also order ore or stone from a miner by contract. Only when the village's own seams, grey rock and boulders are nearly gone does the caravan bring ore and stone."),
		Wiki.h("Mining skill"),
		Wiki.p("Mining trains whenever you swing at a seam or boulder, take a rock sample, dig a trial pit or an open pit, cut a tunnel or sink a shaft. It opens gold at level 3 and, higher up, makes the pickaxe last longer and the work quicker."),
		Wiki.h("The village's mining level"),
		Wiki.p("Every dawn the game works out how far the village's mining has come, from what its people really have: miners and tools, a prospector, a smith and a forge, a find the manor knows, pits dug, supports set up. The levels are Surface extraction, Prospecting and assay, Open-pit excavation and Underground mining. A rise or fall is written in the Journal's village record. The level is only reported: it never stops you, a villager or the manor from prospecting, digging or tunnelling. At present nothing in the village can meet the needs of the third and fourth levels, so the report stops at the second."),
		Wiki.links(["guide:mine", "place:mine", "sys:prospecting", "sys:open_pits", "sys:mining_underground", "sys:minecarts", "sys:mine_shafts", "sys:mine_stability", "sys:mine_backfill",
				"sys:manor_jobs", "sys:contracts", "sys:caravan", "skill:mining", "job:miner", "node:stone_seam", "node:boulder", "item:pickaxe"])],
			"mine mining quarry quarrying ore seam deposit finite depleted worked out left stone boulder grey rock pickaxe miner")


# Prospecting (stain, sample_refusal, take_sample, assayer_refusal, assay, reading, reading_text, findings, plan); Discovery
# (ground_refusal, trial_dig, _open_seam, prospector_place); prospecting.json, discovery.json; recipe forge_prospecting_kit.
static func _prospecting(sys: Callable) -> void:
	var pc := Prospecting.cfg()
	var dc := Discovery.cfg()
	sys.call("prospecting", "Prospecting and trial pits", [
		Wiki.p("Here and there on open ground in the village the soil is stained: rust-red, black streaks, green-stained pebbles, a glitter of flecks in the gravel. A stain is a clue, not a deposit. It marks a search area a few cells wide: any ore lies somewhere inside it, not necessarily at the stain, and some stains lie over nothing at all. They are faint, so look for them. Stains are only on the village's own ground, and they are the same every time you play the same world."),
		Wiki.h("Taking samples"),
		Wiki.p("You need a prospector's kit, forged at an anvil from an iron bar, a plank and leather. Stand inside a stain's search area and choose Take a rock sample here; the prompt says what the stain is and how many samples are left round it. A sample takes about half an hour and wears the kit, and trains Mining. Each spot gives one sample, and a stain gives only a few in all (%d), so choose the spots with care. The rock sample goes in your pack and remembers where it was taken. It is worth nothing until it is assayed. Without a kit the prompt tells you what the stain is and how to sample it." % int(pc.samples_per_clue)),
		Wiki.h("Having a sample assayed"),
		Wiki.p("The village's assayer is the smith. With a rock sample in your pack, talk to a smith at the forge and choose Ask (the smith's name) to assay a rock sample (%d coins). The smith must be awake and at the forge with a coal to burn and the forge free; the coal and the sample are used up, you pay the fee, and after a wait of about %d minutes the smith tells you what it showed, in words: \"traces of iron ore, middling (about 7 in 10 sure)\", or \"nothing worth mining\"." % [int(pc.assay.fee), int(pc.assay.minutes)]),
		Wiki.p("A reading is never certain. A sample taken over ore may still read as nothing, and one taken over a misleading stain may still read as traces. The nearer the spot is to the ore, and the better the smith and the sampler, the more a reading can be trusted, but the smith only ever says how sure they are. The grade runs from poor through lean, middling and good to rich. A reading is known only to the people who were there: you and the smith, and the manor once a surveyor or prospector has told it."),
		Wiki.h("Trial pits"),
		Wiki.p("To find out for certain, dig. With a shovel, face clear ground inside a stain's search area and choose Dig a trial pit here. It takes about %d hours, wears the shovel and trains Mining; the earth it moves (topsoil, dirt and spoil) is left in a pile beside the pit, for anyone to take or tip into an open pit. If ore lies close to the pit, a new seam opens there: it is solid, drawn with its ore, finite like every other seam, and has its grey rock to quarry afterwards. If not, the message says \"The trial pit finds no ore.\" A stain allows only a few pits (%d), a pit cannot go on a road, a building, a yard, a field, planted ground or a spot where someone stands, and ore under such ground cannot be reached this way. Where earlier samples found ore is the place to dig. A pit that finds nothing is a failed venture, and costs the time and the wear." % [roundi(float(dc.trial.minutes) / 60.0), int(dc.trial.per_clue)]),
		Wiki.p("Digging an open pit down to the rock can open a stain's ore too; see Open pits."),
		Wiki.h("Villagers and the manor"),
		Wiki.p("Villagers prospect by the same rules. A prospector takes samples with a kit it buys or has a smith forge for it by contract, has them assayed, and tells the manor what they showed. The place of prospector opens in the village when nobody prospects, some stain has ground left to sample and the manor could pay for a survey. The manor also asks for prospecting on its job board: a survey of a stain, and a trial pit for the best find it knows. Anyone may take those jobs, and the manor pays for the labour whatever is found. You can hire a villager to survey a stain for you by contract."),
		Wiki.links(["sys:mining", "sys:open_pits", "sys:manor_jobs", "sys:contracts", "item:prospecting_kit", "item:ore_sample", "recipe:forge_prospecting_kit", "node:prospect_clue", "job:smith", "station:forge", "skill:mining", "todo:selling_finds"])],
			"prospect prospecting prospector clue stain sample assay assayer reading trial pit survey kit find")


# OpenPits (open_pit, site_refusal, dig, dig_ground_refusal, tip, take, backfill, manor_target); Discovery.expose;
# ManorWork.post_pits (excavate); ContractServices (dig); main.gd _pit_targets; open_pit.json.
static func _open_pits(sys: Callable) -> void:
	var oc := OpenPits.cfg()
	var n := int(oc.size)
	sys.call("open_pits", "Open pits", [
		Wiki.p("An open pit is a square hole dug from the surface, %d cells by %d, with a spoil heap or two beside it. It is dug down in layers: topsoil, then dirt, then spoil (broken rock and gravel) with a shovel, then stone with a pickaxe. Every unit dug is a real item that goes into your pack; nothing is lost, and the ground of a pit is finite." % [n, n]),
		Wiki.h("Marking one out"),
		Wiki.p("With a shovel or a pickaxe in your hand and nothing else in front of you, face clear ground and choose Mark out an open pit here (%d by %d, with its spoil heaps). The ground must be common land and clear: no road, building, plot, field, pen, stall, tree, plant or farmland, nothing lying or parked on it and nobody standing there, with walkable ground round it and room for the heaps. A pit, its walkway and its heaps take the ground: nobody can claim land over it, plant on it or set a stall there. Marking a pit out claims nothing and nobody owns the ground. It is your pit to dig; the manor's pits are dug only through its jobs." % [n, n]),
		Wiki.h("Digging"),
		Wiki.p("Face a cell of your pit and choose Dig, which names the layer and how many units of it are left. It trains Mining and wears the tool the layer takes: the shovel for earth, the pickaxe for rock. The pit is dug a bench at a time, the shallowest cell first, so the topsoil comes off first. The edge of the pit goes two layers down, the next ring three and the middle all four, so the sides are terraced. A cell that is dug down becomes a wall you cannot walk through; the exception is the ramp, a line of cells from the north edge to the middle, which stays walkable at every depth so that you can walk in and out. You cannot dig the cell you stand on, a cell with someone or something on it, or a cell if that would cut off a walkable part of the pit. The stone at the bottom is ordinary stone."),
		Wiki.h("Earth and the heaps"),
		Wiki.p("Topsoil, dirt and spoil are worth nothing to any buyer, and today their only uses are to be tipped onto the pit's spoil heaps and taken back from them, and to be put back into the pit. Facing a heap, choose Tip your earth onto the spoil heap, or Take earth from it. A heap is a mound that blocks the way while it holds anything: storage takes ground. Earth can also be carried in your pack or a handcart."),
		Wiki.h("Uncovering ore"),
		Wiki.p("A cell (not the ramp) dug down to the rock, near where a stain's ore lies, opens a seam exactly as a trial pit does: \"The pit strikes iron ore: a new seam is opened.\" It is an ordinary finite seam, mined from the floor or ramp beside it. A pit that reaches the rock near nothing finds nothing, and has cost the time and the wear."),
		Wiki.h("Hired and manor digging"),
		Wiki.p("In the talk window you can hire a villager to dig your pit by contract: so many units, paid for each unit as it is dug. They dig with their own shovel and pickaxe, tip the earth onto your spoil heaps and bring any stone to your family chest, or you collect it in the contract window if you have no home. The manor marks out its own pit only for a find it knows that no trial pit can reach any more, and posts an excavation job for it on its job board, which anyone with the tool for the layer being dug can take."),
		Wiki.links(["sys:mine_backfill", "sys:prospecting", "sys:manor_jobs", "sys:contracts", "sys:mining", "item:topsoil", "item:dirt", "item:spoil", "item:stone", "node:open_pit", "item:shovel", "item:pickaxe", "skill:mining", "item:handcart", "todo:earth_reuse", "todo:bigger_pits"])],
			"open pit excavation dig digging topsoil dirt spoil heap ramp terrace staked mark out")


# Underground (portals, level_at); LevelView; MineWorks (cut_refusal, dig, place_support, hidden); main.gd _works_targets,
# _through_portal; World.player_through; underground.json; mine_works.json.
static func _underground(sys: Callable) -> void:
	var mc := _mc()
	sys.call("mining_underground", "The adit, the gallery and the cave", [
		Wiki.p("The mine hill is hollow. Walk into the timbered adit in its south face (or tap it) and you go below, into the mine gallery; walk out of it to come back up. The hill's rock and everything on the surface fades out as you go in, as a house's roof does, and the gallery shows with you in it. Away from you the dark deepens, but it only sets the mood: you can always see yourself and the way."),
		Wiki.p("A second opening in the hill's south face, a little west of the adit, leads to the cave under the hill. It lies deeper than the gallery and is a place of its own: from the gallery you reach the cave only by a shaft, never by walking. Gallery and cave are not made up as you go. Each is the same shape every time you play the same world, and what you change in them is saved."),
		Wiki.h("What is down there"),
		Wiki.p("Winding passages and chambers, and ordinary seams on their walls: iron ore, coal, copper and stone in the gallery, coal, iron ore and copper in the cave. They are finite and mined like any seam, with the same count and the same grey rock after. Villagers go below as well. Miners and labourers walk in through the adit or the cave's mouth, mine, and carry the ore out. Nobody fights below ground: attacks and Fireball are refused (\"Nothing to fight here.\"), and the animals stay up on the surface. A handcart will not go in (\"Set the cart down first: it will not go through the adit.\"); a minecart can, on rails."),
		Wiki.h("Cutting a tunnel"),
		Wiki.p("You can cut new passages into the rock beside a floor with a pickaxe. Face the rock and choose Cut into the rock; the prompt says how many of its %d units are left. Each cell of rock gives stone first and then spoil, which go into your pack; the last unit opens the cell as floor. You cut from an open face, standing at it, and a timber support must stand within %d cells of the face first: unsupported rock is not cut. You cannot cut into a seam, into a shaft, or where the rock above is too thin (\"the hill would give way\"). Tunnels stay inside the hill. Cutting trains Mining and wears the pickaxe." % [MineWorks.cell_units(), int(mc.support.reach)]),
		Wiki.p("A timber support is made at the sawhorse from a log and two planks. With one in your pack and a mallet, choose Set up a timber support here on a tunnel floor. Supports wear and rock held by too little timber can fall: see Stability and collapse."),
		Wiki.h("Hidden ore"),
		Wiki.p("Some ore lies hidden in the deep rock of every level, away from any floor, and nobody knows of it. When a tunnel or a shaft opens a cell next to it, it becomes an ordinary seam and the village record says so (\"A tunnel below ground strikes iron ore: a new seam is opened.\"). It is finite, with grey rock after it, like any other."),
		Wiki.links(["sys:minecarts", "sys:mine_shafts", "sys:mine_stability", "sys:mine_backfill", "sys:mining", "place:mine", "item:timber_support", "recipe:make_timber_support", "item:mallet", "node:tunnel_rock", "item:stone", "item:spoil", "skill:mining"])],
			"adit gallery cave underground tunnel tunnelling cut rock timber support hidden ore below cutaway dark mouth hill")


# MineWorks (lay_track, track_refusal, set_down_minecart, crossing_ok, cart_haul_plan, haul_costs); Carts (pull_speed_for, cross);
# main.gd set_down_cart, _cart_targets; NPCBrain._miner; recipes make_track_section, build_minecart.
static func _minecarts(sys: Callable) -> void:
	var mc := _mc()
	sys.call("minecarts", "Track and minecarts", [
		Wiki.p("A track section is made at the workbench from planks and nails. With one in your pack and a mallet, choose Lay a track section here: one section a cell, on a tunnel floor or on the mine's open yard within %d cells of a mouth, so that rails can run out of the adit or the cave onto the surface. The rails are drawn on the ground and block nothing." % int(mc.track.surface_reach)),
		Wiki.p("A minecart is built at the workbench from cart wheels, axles, ironwork and planks, the handcart's own parts. Open your pack and choose Set it down on a track cell and it becomes a cart standing on its rails. Pull it as you pull a handcart: it follows you only along the track, at nearly walking pace (a handcart is slower), and open it to load and unload. Pulled off the rails it stays where the rails end, and if you walk on it is let go. It wears as you pull it, like a handcart."),
		Wiki.p("A minecart goes through the adit or the cave's mouth with its puller only when track lies on both sides of the mouth (\"The minecart runs only on its rails: lay track on both sides of the mouth.\"). It never goes up or down a shaft: goods change level only in someone's hands (\"A minecart does not go up or down a ladder: set it down, and carry its load.\")."),
		Wiki.h("Carry it or take the cart"),
		Wiki.p("You choose. Villagers choose by the walk. A miner below ground with a full load, whose household owns a minecart parked on rails near the seam, takes the cart when the way along the rails costs fewer steps than carrying the load out, loads it, hauls it to the end of the rails nearest the way out and takes the load into the pack; otherwise it carries the load out itself. Only one worker uses a cart at a time, and a claim not used for a day is let go. A minecart belongs to the household or person who set it down."),
		Wiki.links(["sys:mining_underground", "sys:mine_shafts", "item:track_section", "recipe:make_track_section", "item:minecart", "recipe:build_minecart", "item:handcart", "item:mallet", "station:workbench", "job:miner"])],
			"minecart mine cart track rails rail haul hauling carry")


# MineWorks (shaft_refusal, dig_shaft, ladder_refusal, install_ladder, _link), Underground.add_level; mine_works.json shaft, ladder;
# main.gd _works_targets, _shaft_dig.
static func _shafts(sys: Callable) -> void:
	var mc := _mc()
	sys.call("mine_shafts", "Shafts, ladders and deeper levels", [
		Wiki.p("A shaft goes down from a tunnel floor to the level below. To begin you need a pickaxe, a ladder in your pack, and a timber support within %d cells of the floor cell you face. Choose Sink a shaft to the level below here, and then Dig the shaft on, one swing at a time (%d in all). The mouth is an open hole from the first swing and cannot be walked on. When it breaks through, the landing below opens as floor and the message says so." % [int(mc.support.reach), MineWorks.shaft_units()]),
		Wiki.p("A shaft is not a way until a ladder is set in it. The ladder is made at the workbench from planks and nails; choose Set a ladder into the shaft with a mallet. From then on you and the villagers can climb: walk at the ladder to go down or up. A ladder wears, rots through in time, and is repaired with a plank and nails; see Stability and collapse."),
		Wiki.p("A shaft cannot be sunk on a way in or out, on a support or track, where it would cut a passage in two, or where there is no rock face below to set the ladder against. The first shaft to reach a level below the cave makes that level: solid rock but for its landing, with ore hidden in it. The mine goes no deeper than %d levels below the surface, and the rock goes no deeper there (\"The rock goes no deeper here.\")." % absi(int(mc.shaft.deepest))),
		Wiki.p("There is no hoist or windlass. Goods go up and down a ladder only in someone's hands, and a minecart or handcart never does."),
		Wiki.links(["sys:mining_underground", "sys:minecarts", "sys:mine_stability", "item:ladder", "recipe:make_ladder", "item:timber_support", "item:mallet", "station:workbench"])],
			"shaft ladder deeper level descend climb sink down mine deep")


# MineWorks (stability, dawn, collapse, _collapse_shaft, rubble, clear, repair, soundly_held, support_condition); mine_works.json
# stability, support, ladder; main.gd _works_fix; World.note. The outcome for a person caught in a collapse is not written here.
static func _stability(sys: Callable) -> void:
	sys.call("mine_stability", "Stability and collapse", [
		Wiki.p("The gallery and the cave as they were made are sound rock and are never in danger. What you dig is not. Every cell of tunnel that was cut, and every shaft, is weighed once a day at dawn by what holds it up: the sound timber supports standing near it (a support right beside it counts for more than one two cells off), and a little by earth backfilled into the cells round it. The less holds a passage, the more likely it is to fall that day. Nothing about it is certain either way: a well-held passage can stand for ever, and a passage held by nothing will not stand for long."),
		Wiki.h("Wear and repair"),
		Wiki.p("Timber wears. Every dawn each support and ladder loses a little of its soundness; the prompt to repair a worn support shows how sound it is (\"Repair the timber support (80% sound)\"). Face it with a mallet and a plank in your pack and choose Repair to make it whole again, or a ladder with a plank and nails. A support that wears right through fails and is gone, and the passage it held is weighed without it; a ladder that rots through cannot be climbed until it is replaced, and a replaced support or ladder is set up like a new one. Backfill never mends timber."),
		Wiki.h("When rock falls"),
		Wiki.p("A fall fills the passage cell with fallen rock, which blocks it, crushes the support standing on it and leaves any track under it. The village record says where (\"A tunnel below ground has caved in\"). A shaft that falls fills as deep as it was dug, crushes its ladder and is a way no more. Fallen rock is dug out with a shovel, one unit of spoil a swing, under a support within reach, just as rock is cut; it gives spoil, never stone or ore."),
		Wiki.p("Anyone standing in a passage as it falls lives or dies; the better the roof was held, the better their chance. A survivor scrambles into an open passage beside it, or, with none, is trapped until the fallen rock is dug out with a shovel. See Caught in a cave-in. Who makes and repairs the timber, and how the manor buys it, is on Mining equipment."),
		Wiki.links(["sys:mine_collapse", "sys:mine_equipment", "sys:mining_underground", "sys:mine_shafts", "sys:mine_backfill", "item:timber_support", "recipe:make_timber_support", "item:ladder", "item:plank", "item:nails", "item:mallet", "sys:journal_map"])],
			"stability collapse cave in caved fall rock support wear repair rubble timber unsafe")


# MineWorks (fill, fill_refusal, fill_ground_refusal, fill_out); ManorWork (order_backfill, stock_backfill, cancel_backfill, do_step,
# release); OpenPits.backfill; main.gd _fill_own, _works_targets, _pit_targets.
static func _backfill(sys: Callable) -> void:
	var mc := _mc()
	var rate := int(mc.backfill.order_rate)
	sys.call("mine_backfill", "Backfilling pits and tunnels", [
		Wiki.p("Earth can go back where it came from, and only by your choice."),
		Wiki.h("Open pits"),
		Wiki.p("At your own pit, face a dug cell with the earth in your pack and choose Put back a unit of dirt (or topsoil, spoil or stone, whichever the last unit dug from that cell was). The last dug goes back first, and the ground rises by it. A cell filled back through a layer is level again."),
		Wiki.h("Tunnels"),
		Wiki.p("Below ground, face a passage cell with spoil in your pack and choose Put spoil back into the passage; it takes a unit at a time, up to %d, and a full cell is solid again. A passage cell cannot be filled where it is a way in or out (a mouth, the foot of a ladder), a collapsed cell or a shaft. Cells beside a filled one are held a little more firmly by it, but it is never a support and never mends timber. Dug out again, the fill comes back as spoil, never stone or ore." % MineWorks.cell_units()),
		Wiki.p("You can instead order it done. Choose Backfill Tunnel: order this passage filled, which shows how much spoil it needs and the wage for the worker (%d coin a unit). The wage is paid by you when you order, and is held in the order until the work is done. Leave the spoil at the mouth of the mine that leads down to it (\"Leave spoil for the backfill order\"). Villagers other than the manor's hands can take the order from the job board, carry the spoil down in loads and put it back, and are paid when it is done. You can cancel: the wage comes back to you, and the fill already placed stays." % rate),
		Wiki.p("Only you can start a backfill. Nobody else, villager or manor, ever fills a tunnel by their own choice, and you cannot take a backfill job yourself: fill by hand."),
		Wiki.links(["sys:open_pits", "sys:mining_underground", "sys:mine_stability", "sys:manor_jobs", "item:spoil", "item:dirt", "item:topsoil"])],
			"backfill fill put back spoil tunnel order passage earth")


# The Build 17 ideas the owner has approved that are not built yet, and the health placeholders (HEALTH-01). What exists today
# is named in each; the apothecary and potions: guide:heal, sys:home_work, job:sage, sys:caravan.
static func _not_yet(w: Wiki) -> void:
	var items := {
		"earth_reuse": ["Reusing excavated earth", "Topsoil, dirt and spoil can be tipped onto a pit's heaps and put back, and that is all: they have no buyer and no other use. Not built yet: topsoil on farmland, dirt and spoil for road embankments, grading building plots, defensive earthworks and landscaping."],
		"bigger_pits": ["Larger and deeper open pits", "Open pits are one size, with a straight ramp and the same four layers everywhere. Not built yet: larger pits, spiral and switchback ramps, varied strata, and pits in the country outside the village."],
		"selling_finds": ["Sharing and selling prospecting information", "A reading is known to those who were told it, and the manor learns finds from the surveyors and prospectors who report. Not built yet: telling the reeve or a neighbour what you found, selling a find, or rights over a find or over the seam it leads to."],
		"contract_advances": ["Advances on contracts", "A contract's coins are set aside when it is agreed and paid as work is done, and a worker pays their own costs, such as an assay's fees. Not built yet: a buyer advancing a worker money for named costs."],
		"contract_results_pay": ["Pay for results and bonuses", "Contracts pay for work done: a barren survey reading is paid like a find, and a pit that finds nothing is paid by the unit dug. Not built yet: a bonus for what the work turns up, or a price that depends on the result."],
		"contract_disputes": ["Contract disputes", "A contract that is not finished by its day lapses, the coins go back and the worker loses regard. Not built yet: a complaint about the quality or timing of work, a share held back until the whole is done, or the manor judging between the two sides."],
		"farm_labour_contracts": ["Farm labour by contract", "A farmer cannot hire a villager by contract to harvest a field; the paid work the player can ask for keeps its own fixed rules. Not built yet: harvest and other field work offered as a service contract, with the rules about whose field may be cut."],
		"villagers_hire": ["Villagers hiring services on their own", "Today only you hire a villager for work (to dig your pit or to survey a stain). Villagers order goods from each other, but no villager yet decides by themselves to hire work done: the manor posts its own jobs instead."],
		"service_signing": ["A separate signing line for service contracts", "A work contract of 50 coins or more is signed face to face, the same line as a contract for goods. Not built yet: a different threshold for hiring labour."],
		"injuries": ["Injuries", "Health is one number. A blow, a bite, starvation or spoiled food lowers it; it does not come back by itself, and at 0 you die. Not built yet: injuries of different kinds and severity, bleeding, wounds that linger, or accidents that hurt and leave a person to recover."],
		"illness": ["Illness", "Not built yet: illness and disease. Today the only sickness is spoiled food, which costs health at once."],
		"treatment": ["Treatment and recovery", "Medicine heals a set amount at once: bandages, poultices and tonics from the sage's Apothecary, from a stove, or from a villager's household, and your own bed restores you fully. Not built yet: treatment that takes time, rest to recover, or an injury that needs care."],
		"practitioners": ["Healers and practitioners", "The sage keeps the Apothecary, buys flowers and brews the medicines, and the tanner sews bandages for it. Not built yet: physicians or other healers who treat the sick and hurt."],
		"medical_costs": ["Medical costs", "Medicines are bought from the Apothecary or made at home at their ordinary price. Not built yet: charges for treatment, or a household going without care for want of coins."],
		"lasting_harm": ["Lasting harm", "Not built yet: disability, scars or other lasting consequences of injury or illness. Today a villager who is hurt uses a medicine if they have one, and does not heal otherwise."],
	}
	for id in items:
		var links := ["guide:heal", "sys:resting", "sys:death_causes", "job:sage"] if id in ["injuries", "illness", "treatment", "practitioners", "medical_costs", "lasting_harm"] else \
				["sys:contracts", "sys:open_pits", "sys:prospecting", "sys:manor_jobs"]
		w.add_page("todo:" + id, items[id][0], "notyet", [Wiki.note("Not in the game yet. " + items[id][1]), Wiki.links(links, "See also")], "", "not implemented planned")
