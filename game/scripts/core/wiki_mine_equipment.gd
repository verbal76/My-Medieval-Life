class_name WikiMineEquipment
extends RefCounted
## Wiki pages for MIN-EQUIP (who makes the underground's equipment and how it is bought, the manor's purchases and its
## shore work) and MIN-COLLAPSE (what happens to someone caught in a cave-in), owner MIN-F2-Q1/Q2
## (docs/build17/MIN_EQUIP_COLLAPSE.md). Every statement is taken from the code named beside it: MineSupply
## (mine_supply.gd), ManorWork.post_shore and its shore steps, NPCBrain._deliver_orders, MineWorks.caught. Registered
## with Wiki.add_provider (Wiki.build). The underground mechanics themselves (tunnels, supports' hold on the roof, track,
## the minecart's choice, shafts, backfill) are the mining pages' (wiki_mining.gd), linked when they are there.

const MINING_PAGES := ["sys:mining_underground", "sys:mine_stability", "sys:mine_backfill"]


static func add_pages(w: Wiki) -> void:
	var mining: Array = MINING_PAGES.filter(func(id): return w.pages.has(id))
	_equipment(w, mining)
	_collapse(w, mining)


# MineSupply.carpenter_work, _make, procure, manor_needs, shore_wanted, minecart_wanted, miner_cart_plan;
# ManorWork.post_shore, _shore_step; NPCBrain._deliver_orders; recipes.json.
static func _equipment(w: Wiki, mining: Array) -> void:
	w.add_page("sys:mine_equipment", "Mining equipment: who makes it, who buys it", "systems", [
		Wiki.p("The work below ground needs real equipment: timber supports to hold the roof, ladders for shafts, minecarts for the rails, and mallets to set them up with. Nobody hands them out: the village's own trades make them, from their own materials and time, and they are bought with real coins."),
		Wiki.h("Who makes what"),
		Wiki.bullets([
			"The carpenter makes timber supports at the sawhorse (a log and two planks), and ladders, mallets and minecarts at the workbench.",
			"The smith forges the metal: the nails a ladder (and a track section, and a ladder's repair) needs, and the axles and ironwork a minecart stands on. The carpenter buys them from the smith or the goods merchant, as it does for a handcart.",
			"A minecart is built from the carpenter's planks and cart wheels on the smith's axles and ironwork.",
			"Repairs use the carpenter's planks (a support) or planks and the smith's nails (a ladder).",
		]),
		Wiki.p("The carpenter makes them only for someone who needs one: an order from the manor, or a miner's household that needs a minecart. It keeps what it made for an order until the order is collected."),
		Wiki.h("How the manor gets them"),
		Wiki.p("Each evening the reeve weighs what the mine below ground needs. When the manor's works are short of stone and it could pay for tunnelling, but no rock face below ground is held by sound timber, it wants a support for the face; it wants planks for any support worn badly that still holds an open passage, a ladder for a finished shaft whose ladder has rotted or been crushed, and a mallet for its works yard to do that work with. It buys what a carpenter, smith or merchant has, from its treasury and at their price, into the works yard; what nobody has, it orders from a carpenter, paying the price in advance, and the finished piece is brought to the yard. It never spends below the reserve it keeps."),
		Wiki.p("Then the reeve posts the work on the job board: carry the support and the yard's mallet down and set it up beside the face, repair the worn support with a plank, or set the ladder into the shaft. Whoever takes the job is paid the board's usual rate for a repair, from the treasury, when it is done, and brings the mallet back to the yard. Once a face is held by a sound support, the manor can post its tunnelling job there."),
		Wiki.h("A miner's minecart"),
		Wiki.p("Where rails run from near a miner's seam below ground toward the way out, and pulling a minecart along them would save that miner walking, the miner's household needs a minecart. The carpenter builds one, and the miner buys it with their own coins and sets it down on those rails. Without rails there is no need, so no minecart is made or bought."),
		Wiki.h("You"),
		Wiki.p("You can make any of these yourself at the same stations with the same materials, buy from a carpenter who has one, or ask a villager for one through a contract. Nobody in the village lays track or sinks a shaft on their own: nothing they need calls for it. You can do both."),
		Wiki.links(["item:timber_support", "item:ladder", "item:minecart", "item:mallet", "item:nails", "recipe:make_timber_support", "recipe:make_ladder",
			"recipe:build_minecart", "recipe:forge_nails", "recipe:forge_cart_axle", "recipe:forge_cart_ironwork", "job:carpenter", "job:smith", "job:miner",
			"sys:manor_treasury", "place:mine"] + mining),
	], "", "mining equipment support ladder minecart mallet carpenter smith order manor repair shore")


# MineWorks.collapse, caught, _escape, is_trapped, _free_trapped; World.kill; World.damage_player; World._update_npc.
static func _collapse(w: Wiki, mining: Array) -> void:
	w.add_page("sys:mine_collapse", "Caught in a cave-in", "systems", [
		Wiki.p("A passage dug below ground that is too weakly held can cave in at dawn, and fill with fallen rock. Anyone standing in it lives or dies. The better the roof was held as it fell, the better their chance; luck decides the rest. There is no injury in between, and no treatment."),
		Wiki.h("If they die"),
		Wiki.p("A villager who dies in a cave-in dies like anyone else in the village: what they owned passes to their heir, their family remembers it, and the death is in the village's record. If it is you, your heir takes over, as after any death."),
		Wiki.h("If they live"),
		Wiki.p("A survivor scrambles out into an open passage right beside the cave-in, if there is one. If every way beside it is rock or rubble, they are trapped where they stand and can do nothing until someone digs the fallen rock out of that passage (you can dig at it from inside). They still grow hungry while they wait. Nobody comes to rescue a trapped villager on purpose: only digging out the rubble frees them."),
		Wiki.note("Injuries, wounds and their treatment are not in the game yet: a cave-in leaves you either unhurt or dead."),
		Wiki.links(["sys:mine_equipment", "sys:inheritance", "place:mine"] + mining),
	], "", "cave-in collapse mine tunnel trapped rubble death survive")
