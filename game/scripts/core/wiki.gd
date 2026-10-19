class_name Wiki
extends RefCounted
## The player's wiki (PL2-009): pages built from the game's own data so they cannot drift from it.
## Items (items.json), recipes (recipes.json), resource nodes (resources.json), skills, animals and
## balance numbers (balance.json), stations (village.json), jobs (Population.JOBS, NPCBrain) and the
## controls (GameUI.CONTROLS) each give pages; a few hand-written pages cover mechanics that exist
## (needs, resting, theft, trading, property, saving) and "Not in the game yet" lists what does not.
##
## Other systems add pages without touching this file:
##   Wiki.add_provider(func(w: Wiki): w.add_page("sys:fishing", "Fishing", "systems", [Wiki.p("...")]))
## A provider runs every time the wiki is built. Page ids are "kind:name"; a "links" block or a
## recipe block names other pages by id, and the test checks every link resolves.
##
## A page: {id, title, category, icon (an item id or ""), blocks, text (lower-case search text)}.
## Blocks: h (heading), p (paragraph), bullets (rows), links (page ids), note, stats (rows of
## [label, value]), controls (scheme), recipe (recipe id), chain (item id: its production chain).

const ICON := "res://assets/icons/%s.png"
const SCHEMES := {"kbm": "Keyboard and mouse", "gamepad": "Gamepad", "touch": "Touch"}
const STATION_NAMES := {"anvil": "Anvil", "armory_counter": "Armory counter", "forge": "Forge", "mine_cart": "Mine cart",
	"oven": "Oven", "sawhorse": "Sawhorse", "stove": "Stove", "tavern_counter": "Tavern counter", "well": "Well",
	"workbench": "Workbench"}
const ITEM_GROUPS := {"tool": "items_tools", "weapon": "items_gear", "armor": "items_gear", "head": "items_gear",
	"ring": "items_gear", "amulet": "items_gear", "food": "items_food", "resource": "items_materials"}
## What each profession does, in a line (checked against NPCBrain's plans when written).
const JOB_TEXT := {
	"miner": "Works the ore seams in the mine and sells ore to the smith and the raw-goods merchant.",
	"laborer": "Day labour: mines, hauls and does odd work where it is needed.",
	"woodcutter": "Fells trees with an axe and sells the logs.",
	"carpenter": "Buys logs and saws them into planks.",
	"smith": "Smelts ore into bars at the forge and forges tools, weapons and armour at the anvil.",
	"tanner": "Buys hides and makes leather.",
	"farmer": "Sows, tends and harvests the wheat fields, and keeps the animal pens.",
	"cook": "Cooks wheat and meat into pottage and roast meat.",
	"tavernkeeper": "Keeps The Well House and sells food and ale.",
	"hunter": "Hunts wild boar and rabbits for meat and hides.",
	"merchant": "Runs a market stall or shop and trades goods.",
	"guard": "Watches the village: stops thieves, returns stolen goods and fines the thief.",
	"reeve": "Runs the manor's accounts and posts its jobs on the job board.",
	"sage": "The village lorekeeper; tells the story.",
}

static var providers: Array = []     # Callables taking a Wiki, run by build()

var categories: Array = []           # [{id, title, blurb}] in display order
var pages := {}                      # id -> page


static func add_provider(c: Callable) -> void:
	if not providers.has(c):
		providers.append(c)


# --- block helpers ---------------------------------------------------------------------------
static func h(text: String) -> Dictionary:
	return {"t": "h", "text": text}


static func p(text: String) -> Dictionary:
	return {"t": "p", "text": text}


static func bullets(rows: Array) -> Dictionary:
	return {"t": "bullets", "rows": rows}


static func links(ids: Array, label := "") -> Dictionary:
	return {"t": "links", "ids": ids, "label": label}


static func note(text: String) -> Dictionary:
	return {"t": "note", "text": text}


static func stats(rows: Array) -> Dictionary:
	return {"t": "stats", "rows": rows}


static func icon_path(item_id: String) -> String:
	var path := ICON % item_id
	return path if ResourceLoader.exists(path) else ""


# --- building --------------------------------------------------------------------------------
static func build() -> Wiki:
	GameData.ensure()
	var w := Wiki.new()
	w._core_categories()
	w._items()
	w._recipes()
	w._nodes()
	w._stations()
	w._skills()
	WikiSkills.add_pages(w)
	w._animals()
	w._jobs()
	w._controls()
	w._systems()
	WikiHome.add_pages(w)
	w._guides()
	WikiBusiness.add_pages(w)
	w._not_yet()
	WikiWorld.add_pages(w)
	WikiChests.add_pages(w)
	WikiProperty.add_pages(w)
	for c in providers:
		if c.is_valid():
			c.call(w)
	return w


func add_category(id: String, title: String, blurb := "") -> void:
	for c in categories:
		if c.id == id:
			return
	categories.append({"id": id, "title": title, "blurb": blurb})


func add_page(id: String, title: String, category: String, blocks: Array, icon := "", keywords := "") -> void:
	var parts := [title, keywords]
	for b in blocks:
		for k in ["text", "label"]:
			if b.has(k):
				parts.append(str(b[k]))
		for r in b.get("rows", []):
			parts.append(" ".join((r if r is Array else [r]).map(func(x): return str(x))))
		for l in b.get("ids", []):
			parts.append(page_title(str(l)))
		if b.get("t", "") == "recipe" or b.get("t", "") == "chain":
			parts.append(str(b.get("id", "")))
	pages[id] = {"id": id, "title": title, "category": category, "icon": icon, "blocks": blocks,
		"text": " ".join(parts.map(func(x): return str(x))).to_lower()}


func page_title(id: String) -> String:
	return pages[id].title if pages.has(id) else id


func in_category(cat: String) -> Array:
	var out := []
	for id in pages:
		if pages[id].category == cat:
			out.append(id)
	out.sort_custom(func(a, b): return pages[a].title.naturalnocasecmp_to(pages[b].title) < 0)
	return out


## Every link a page makes: its links blocks and recipe blocks.
func links_of(id: String) -> Array:
	var out := []
	for b in pages[id].blocks:
		if b.t == "links":
			out.append_array(b.ids)
		elif b.t == "recipe":
			out.append("recipe:" + b.id)
	return out


func broken_links() -> Array:
	var out := []
	for id in pages:
		for l in links_of(id):
			if not pages.has(l):
				out.append("%s -> %s" % [id, l])
	return out


static func _stem(t: String) -> String:
	return t.substr(0, t.length() - 1) if t.length() > 3 and t.ends_with("s") else t


## Full-text search: every word must occur in a page (a trailing plural s is ignored); title
## matches rank first, then pages whose title starts with the word.
func search(query: String) -> Array:
	var terms := []
	for t in query.to_lower().strip_edges().split(" ", false):
		terms.append(_stem(t))
	if terms.is_empty():
		return []
	var scored := []
	for id in pages:
		var pg: Dictionary = pages[id]
		var title: String = pg.title.to_lower()
		var score := 0
		var ok := true
		for t in terms:
			if title.contains(t):
				score += 10 + (5 if title.begins_with(t) else 0)
			elif pg.text.contains(t):
				score += 1
			else:
				ok = false
				break
		if ok:
			scored.append([score, pg.title, id])
	scored.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	return scored.map(func(s): return s[2])


# --- shared lookups --------------------------------------------------------------------------
func _iname(id: String) -> String:
	return GameData.item_name(id)


func _item_link(id: String) -> String:
	return "item:" + id


func _amounts(d: Dictionary) -> String:
	var parts := []
	for id in d:
		parts.append("%d %s" % [int(d[id]), _iname(id)])
	return ", ".join(parts)


## Recipes that make / use an item (ids, sorted).
func recipes_making(item: String) -> Array:
	var out := []
	for r in GameData.recipes:
		if GameData.recipes[r].out.has(item):
			out.append(r)
	out.sort()
	return out


func recipes_using(item: String) -> Array:
	var out := []
	for r in GameData.recipes:
		if GameData.recipes[r]["in"].has(item):
			out.append(r)
	out.sort()
	return out


func nodes_yielding(item: String) -> Array:
	var out := []
	for n in GameData.resources.nodes:
		if GameData.resources.nodes[n].get("yields", {}).has(item):
			out.append(n)
	out.sort()
	return out


## The lines of an item's production chain, from raw materials: "Pickaxe: 2 Iron bar + 1 Plank at the Anvil".
func chain_lines(item: String, depth := 0, seen := []) -> Array:
	var rs := recipes_making(item)
	if rs.is_empty() or seen.has(item):
		return []
	var r: Dictionary = GameData.recipes[rs[0]]
	var out := ["%s%s: %s at the %s" % ["    ".repeat(depth), _iname(item), " + ".join(r["in"].keys().map(func(i): return "%d %s" % [int(r["in"][i]), _iname(i)])), STATION_NAMES.get(r.station, str(r.station).capitalize())]]
	for i in r["in"]:
		out.append_array(chain_lines(i, depth + 1, seen + [item]))
	return out


# --- generated pages -------------------------------------------------------------------------
func _core_categories() -> void:
	add_category("guides", "How do I...?", "Short answers to common questions")
	add_category("items_tools", "Tools", "Pickaxes, axes and hammers")
	add_category("items_gear", "Weapons and armour", "Swords, armour, caps, rings and amulets")
	add_category("items_food", "Food and drink", "What you can eat")
	add_category("items_materials", "Materials", "Ore, wood, bars, hides and more")
	add_category("recipes", "Recipes", "What can be made, and where")
	add_category("resources", "Gathering", "Where resources are found, and what they need")
	add_category("stations", "Stations", "Forge, anvil, stove and the rest")
	add_category("skills", "Skills", "What each skill unlocks")
	add_category("animals", "Animals", "Livestock and wild game")
	add_category("jobs", "Professions", "What the villagers do")
	add_category("controls", "Controls", "Keyboard, gamepad and touch")
	add_category("systems", "How the game works", "Needs, trade, theft, property and saving")
	add_category("notyet", "Not in the game yet", "Ideas that are not built")


func _items() -> void:
	for id in GameData.items:
		var it: Dictionary = GameData.items[id]
		var rows := [["Type", str(it.type).capitalize()], ["Base price", "%d coins" % int(it.value)]]
		if it.has("food"):
			rows.append(["Eating restores", "%d food" % int(it.food)])
		if it.has("heal"):
			rows.append(["Heals", "%d health" % int(it.heal)])
		if it.has("harm"):
			rows.append(["Costs", "%d health (spoiled)" % int(it.harm)])
		if it.has("damage"):
			rows.append(["Damage", str(int(it.damage))])
		if it.has("armor"):
			rows.append(["Armour", str(int(it.armor))])
		if it.has("durability"):
			rows.append(["Durability", "%d uses" % int(it.durability)])
		if it.has("speed"):
			rows.append(["Work speed", "x%s" % str(it.speed)])
		if it.has("tool"):
			rows.append(["Works as", str(it.tool)])
		for k in it.get("bonus", {}):
			rows.append(["Bonus", "+%d %s" % [int(it.bonus[k]), str(k).replace("_", " ")]])
		if it.has("plant"):
			rows.append(["Grows into", "a %s tree" % it.plant])
		var blocks := [stats(rows)]
		var from_nodes := nodes_yielding(id)
		if not from_nodes.is_empty():
			blocks.append(h("Where to get it"))
			blocks.append(links(from_nodes.map(func(n): return "node:" + n)))
		var making := recipes_making(id)
		if not making.is_empty():
			blocks.append(h("How to make it"))
			for r in making:
				blocks.append({"t": "recipe", "id": r})
			blocks.append({"t": "chain", "id": id})
		var using := recipes_using(id)
		if not using.is_empty():
			blocks.append(h("Used to make"))
			for r in using:
				blocks.append({"t": "recipe", "id": r})
		var uses := []
		for u in GameData.resources.materials.get(id, []):
			uses.append(str(u.text))
		if not uses.is_empty():
			blocks.append(h("Other uses"))
			blocks.append(bullets(uses))
		if from_nodes.is_empty() and making.is_empty():
			blocks.append(p("It is not gathered or made by the player; buy it from a merchant or find it in the world, or it is part of your starting kit."))
		add_page(_item_link(id), it.name, ITEM_GROUPS.get(it.type, "items_materials"), blocks, icon_path(id), id.replace("_", " "))


func _recipes() -> void:
	for id in GameData.recipes:
		var r: Dictionary = GameData.recipes[id]
		var out_id: String = r.out.keys()[0]
		var st: String = STATION_NAMES.get(r.station, str(r.station).capitalize())
		var blocks := [
			stats([["Needs", _amounts(r["in"])], ["Makes", _amounts(r.out)], ["At", st],
				["Skill", "%s %d" % [str(r.skill).capitalize(), int(r.level)]], ["Work time", "%d game minutes" % int(r.minutes)],
				["Experience", "%d" % int(r.xp)]]),
			links(r["in"].keys().map(func(i): return _item_link(i)), "Ingredients"),
			links(r.out.keys().map(func(i): return _item_link(i)), "Products"),
			links(["station:" + r.station, "skill:" + r.skill], "See also")]
		add_page("recipe:" + id, "Make: " + _iname(out_id) + " (" + st.to_lower() + ")", "recipes", blocks, icon_path(out_id), id.replace("_", " "))


func _nodes() -> void:
	for id in GameData.resources.nodes:
		var n: Dictionary = GameData.resources.nodes[id]
		var rows := [["Where", str(n.get("where", "?"))]]
		if str(n.get("tool", "")) != "":
			rows.append(["Needs", "a %s" % str(n.tool)])
		if str(n.get("skill", "")) != "":
			rows.append(["Skill", "%s %d" % [str(n.skill).capitalize(), int(n.get("level", 1))]])
		var y := []
		for i in n.get("yields", {}):
			y.append(_iname(i))
		rows.append(["Gives", ", ".join(y)])
		rows.append(["Comes back?", str(n.get("regeneration", "?")).split(" Once")[0].split("; ")[0]])
		var blocks := [stats(rows)]
		if str(n.get("tool_hint", "")) != "":
			blocks.append(p(str(n.tool_hint)))
		if str(n.get("yield_notes", "")) != "":
			blocks.append(p(str(n.yield_notes)))
		blocks.append(links(n.get("yields", {}).keys().map(func(i): return _item_link(i)), "Products"))
		if str(n.get("skill", "")) != "":
			blocks.append(links(["skill:" + str(n.skill)], "Skill"))
		add_page("node:" + id, n.name, "resources", blocks, icon_path(str(n.get("icon", ""))), str(n.get("category", "")))


func _stations() -> void:
	var village: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/village.json"))
	var names := {}
	for b in village.buildings:
		names[str(b.id)] = str(b.get("name", b.type)).capitalize() if not b.get("name") else str(b.name)
	var where := {}
	for s in village.stations:
		var t := str(s.type)
		var place: String = names.get(str(s.get("building", "")), "outdoors") if s.get("building") != null else "outdoors"
		if not where.has(t):
			where[t] = []
		if not where[t].has(place):
			where[t].append(place)
	for t in where:
		var rs := GameData.recipes_at(t)
		var blocks := [p("Found: %s." % ", ".join(where[t]))]
		if rs.is_empty():
			blocks.append(p("No crafting here; it is a place to use (trade, draw water, ride)."))
		else:
			blocks.append(h("Recipes"))
			for r in rs:
				blocks.append({"t": "recipe", "id": r})
		add_page("station:" + t, STATION_NAMES.get(t, t.capitalize()), "stations", blocks, "", t)
	for t in GameData.recipes.values().map(func(r): return str(r.station)):
		if not pages.has("station:" + t):
			add_page("station:" + t, STATION_NAMES.get(t, t.capitalize()), "stations", [h("Recipes")] + GameData.recipes_at(t).map(func(r): return {"t": "recipe", "id": r}))


func _skills() -> void:
	for id in GameData.skills:
		var s: Dictionary = GameData.skills[id]
		var rows := []
		for l in Skills.shown_levels(id):
			rows.append(["Level " + str(l), Skills.tier_text(id, l)])
		var blocks := [p("Levels 1 to %d. You gain experience by doing the work; see Skills and levels for the curve." % Skills.max_level()), stats(rows)]
		var rl := []
		for r in GameData.recipes:
			if GameData.recipes[r].skill == id:
				rl.append("recipe:" + r)
		rl.sort()
		if not rl.is_empty():
			blocks.append(links(rl, "Recipes that train it"))
		var nl := []
		for n in GameData.resources.nodes:
			if str(GameData.resources.nodes[n].get("skill", "")) == id:
				nl.append("node:" + n)
		if not nl.is_empty():
			blocks.append(links(nl, "Gathering that trains it"))
		add_page("skill:" + id, s.name, "skills", blocks, "", id)


func _animals() -> void:
	var an: Dictionary = GameData.b("animals")
	for id in an:
		if str(id).begins_with("_"):
			continue
		var a: Dictionary = an[id]
		var wild: bool = a.kind == "wild"
		var rows := [["Kind", "wild game" if wild else "livestock (kept in a pen)"], ["Health", str(int(a.hp))],
			["Meat", str(int(a.get("meat", 0)))], ["Hides", str(int(a.get("hide", 0)))]]
		if a.has("feed"):
			rows.append(["Feed", "%d wheat a meal" % int(a.feed)])
		rows.append(["Newborn until", "%s days old (juvenile)" % str(a.get("juvenile_days", "?"))])
		rows.append(["Adult from", "%s days old; only adults breed" % str(a.get("grow_days", "?"))])
		rows.append(["Elderly from", "%s days old (slower)" % str(a.get("elder_days", "?"))])
		var dd: Array = a.get("death_days", [])
		if dd.size() == 2:
			rows.append(["Dies of old age", "between %d and %d days old" % [int(dd[0]), int(dd[1])]])
		rows.append(["Young per litter", str(int(a.get("litter", 1)))])
		var blocks := [stats(rows)]
		var node: String = "node:wild_" + id if wild else "node:" + id + "_pen"
		var ls := [node, "item:meat"]
		if int(a.get("hide", 0)) > 0:
			ls.append("item:hide")
		blocks.append(links(ls))
		blocks.append(p("Animals get hungry and die unfed like villagers; a well-fed male and female breed, and young are half size until grown." if not wild else "Wild animals graze and breed in the woods. Hunting them takes a weapon."))
		add_page("animal:" + id, str(a.name), "animals", blocks, icon_path(str(GameData.resources.nodes.get(node.trim_prefix("node:"), {}).get("icon", ""))), id)


func _jobs() -> void:
	var tools_kept: Dictionary = NPCBrain.KEEPS
	for j in Population.JOBS:
		var blocks := [p(JOB_TEXT.get(j, "")), stats([["In the village", str(int(Population.JOBS[j]))]])]
		var buys: Dictionary = NPCBrain.BUYS.get(j, {})
		if not buys.is_empty():
			blocks.append(p("Buys: " + ", ".join(buys.keys().map(func(i): return _iname(i))) + "."))
			blocks.append(links(buys.keys().map(func(i): return _item_link(i)), "Buys"))
		if tools_kept.has(j):
			blocks.append(links(tools_kept[j].map(func(i): return _item_link(i)), "Keeps for work"))
		add_page("job:" + j, str(j).replace("_", " ").capitalize(), "jobs", blocks, "", j)


func _controls() -> void:
	for s in SCHEMES:
		add_page("controls:" + s, SCHEMES[s], "controls", [{"t": "controls", "scheme": s}], "", "controls keys buttons " + s)


func _guides() -> void:
	var pick: Dictionary = GameData.resources.nodes.iron_seam
	var plank_r: Dictionary = GameData.recipes.saw_planks
	var plot: int = int(GameData.b("plot_price"))
	var house: int = int(GameData.b("house_price"))
	var rent_pct: int = roundi(float(GameData.b("weekly_rent_share")) * 100.0)
	var guide := func(id: String, title: String, blocks: Array) -> void:
		add_page("guide:" + id, title, "guides", blocks, "", "how do i")
	guide.call("money", "Earn money", [
		p("Sell what you gather or make, and take jobs. Mine ore and sell it to the smith or the raw-goods merchant; fell trees and sell logs or planks; hunt for meat and hides; pick berries and flowers; cook at the stove. The reeve's job board and villagers who ask for work pay coins; hand in the goods to be paid."),
		links(["guide:mine", "guide:planks", "guide:cook", "sys:trading", "job:reeve"])])
	guide.call("pickaxe", "Get a pickaxe", [
		p(str(pick.tool_hint)),
		p("You start with a rusty pickaxe: it works, but more slowly and it wears out."),
		links(["item:pickaxe", "item:rusty_pickaxe", "recipe:forge_pickaxe", "station:anvil", "guide:mine"])])
	guide.call("planks", "Make planks", [
		p("Fell a tree with an axe to get logs, then saw them at the sawhorse: %s makes %s." % [_amounts(plank_r["in"]), _amounts(plank_r.out)]),
		{"t": "chain", "id": "plank"}, links(["recipe:saw_planks", "item:log", "item:plank", "node:tree", "station:sawhorse"])])
	guide.call("mine", "Mine", [
		p("Stand in front of a seam or boulder with a pickaxe and press Use (E, or A on a pad), or press G for Gather mode and click it. Mining skill unlocks more ore and slower tool wear. Seams do not refill; boulders do not come back either."),
		links(["node:iron_seam", "node:coal_seam", "node:copper_seam", "node:stone_seam", "node:boulder", "skill:mining", "sys:gather"])])
	guide.call("smelt", "Smelt and forge", [
		p("Ore becomes bars at the forge (ore and coal), and bars become tools, weapons and armour at the anvil. Smithing skill gates the better recipes."),
		{"t": "chain", "id": "iron_sword"}, links(["station:forge", "station:anvil", "skill:smithing", "recipe:smelt_iron", "job:smith"])])
	guide.call("cook", "Cook", [
		p("Cook at the stove (pottage, ale, herbal tonic) or the oven (roast meat). Cooked food restores more food than raw wheat or meat."),
		links(["station:stove", "station:oven", "recipe:cook_pottage", "recipe:roast_meat", "recipe:brew_tonic", "skill:cooking"])])
	guide.call("heal", "Heal", [
		p("Health does not come back by itself. Rest in your own bed (it restores full health and stamina and saves the game), or use medicine from your pack: %s. Medicine is never used up when you are already at full health, and never heals past your maximum. You start with two linen bandages. The sage at the hut keeps the Apothecary: buy medicine there, or sell wild flowers that the sage brews into poultices and tonics. You can brew them yourself at a stove, and the herbal tonic too. At 0 health you die and your heir takes over." % _medicine_list()),
		links(["sys:needs", "sys:resting", "item:herbal_tonic", "recipe:brew_tonic", "item:flower", "sys:death"])])
	guide.call("rent", "Rent or buy a house or plot", [
		p("The manor sells and lets empty houses and plots of ground. A plot costs about %d coins, a house with its ground about %d; renting costs about %d%% of the price a week, and two missed weeks end a lease. Walk to the door of an empty house to see the offer." % [plot, house, rent_pct]),
		links(["sys:property", "sys:saving"])])
	guide.call("theft", "Avoid trouble with theft", [
		p("Taking or selling goods marked as stolen, or being seen picking a pocket, brings the guards: they return the goods and fine you %d coins. Witnesses within %d tiles count. Pick pockets only when nobody is looking, ideally asleep victims, and do not sell stolen goods to anyone nearby." % [int(GameData.b("theft_fine")), int(GameData.b("witness_radius"))]),
		links(["sys:theft", "skill:stealth", "job:guard"])])
	guide.call("sprint", "Sprint", [
		p("Hold Shift (keyboard) or press LT (gamepad) to sprint; it uses stamina and ends when you run out."),
		links(["sys:needs", "controls:kbm", "controls:gamepad"])])
	guide.call("save", "Save and carry on", [
		p("Resting in your bed saves; the pause menu has Save and Save and quit to title. Continue on the title screen loads it."),
		links(["sys:saving", "sys:death"])])


func _systems() -> void:
	var gmps: float = float(GameData.b("game_minutes_per_second"))
	var sys := func(id: String, title: String, blocks: Array) -> void:
		add_page("sys:" + id, title, "systems", blocks, "", "")
	sys.call("needs", "Health, food and stamina", [
		p("Three bars top left. Health: how much you can take; at 0 you die. Food: falls %s a game hour; at 0 you starve and lose health, so eat. Stamina: spent by Fireball (%d) and sprinting; it refills by itself. A bar turns red and blinks when low." % [str(GameData.b("player_hunger_per_hour")), int(GameData.b("fireball_stamina"))]),
		p("Time: one real second is %s game minutes, so a day lasts about %d real minutes." % [str(gmps), roundi(1440.0 / gmps / 60.0)]),
		links(["guide:heal", "sys:resting", "sys:sprint"])])
	sys.call("resting", "Resting and sleeping", [
		p("Your bed in your own house: rest until morning (or two hours by day). It restores full health and stamina and saves. You need a house first: see Rent or buy."),
		links(["guide:rent", "sys:property", "sys:saving"])])
	sys.call("sprint", "Sprint", [
		p("Sprinting multiplies your speed by %s and costs %d stamina a second (less what you regenerate). It cannot start when stamina is nearly empty. Shift (hold), or LT on a pad to turn it on or off." % [str(GameData.b("sprint_speed")), int(GameData.b("sprint_stamina_per_sec"))]),
		links(["sys:needs", "controls:kbm", "controls:gamepad"])])
	sys.call("gather", "Gather mode and working", [
		p("Gather mode (G on keyboard, Gather on touch, D-pad down on a pad) gathers the resource you pick again and again until it is used up or something interrupts you: you walk away, you are hurt, your pack is full or the tool is gone. Cancel stops work at once: Esc or right-click, B on a pad."),
		p("Several things may be usable at once: Q or Tab (D-pad left or right) chooses the next one."),
		links(["guide:mine", "node:tree", "node:flower_patch", "controls:kbm"])])
	sys.call("trading", "Trading", [
		p("Talk to a merchant or villager to buy and sell. Prices depend on each item's base value; merchants have limited coins and stock, and a trade either completes or does not happen. Villagers buy what their work needs."),
		links(["guide:money", "job:merchant", "sys:theft"])])
	sys.call("theft", "Theft and guards", [
		p("Pickpocketing needs Stealth; sleeping victims are easier. Goods you steal are marked as theirs. A guard who sees a theft, hears the victim within %d tiles, or questions you about a stolen item returns the goods and fines you %d coins." % [int(GameData.b("guard_call_radius")), int(GameData.b("theft_fine"))]),
		links(["skill:stealth", "job:guard", "guide:theft"])])
	sys.call("property", "Land, houses, workshops and rent", [
		p("The manor sells and lets ground and empty houses; rent is weekly. You can build on ground you hold from the Build menu, with materials and hired helpers. A new property starts with a house, and rooms and workshops (a smithy, a carpenter's shop, a kitchen, living quarters and more) can be added to it later without pulling anything down. A rented home you cannot pay for is lost after missed weeks."),
		links(["guide:rent", "sys:resting", "sys:property_modules", "guide:property_rooms"])])
	var cal: Dictionary = GameData.b("calendar")
	var lf: Dictionary = GameData.b("life")
	var yd: int = int(cal.year_days)
	sys.call("calendar", "Calendar and seasons", [
		p("A year is %d game days, in the seasons %s (%s days each). The clock shows the season, year, day and time, for example 'Spring, Year 1  Day 3  07:00'. A day lasts about %d real minutes, so a year is about %d real minutes." % [yd, ", ".join(cal.seasons), ", ".join(cal.season_days.map(func(x): return str(int(x)))), roundi(1440.0 / gmps / 60.0), roundi(1440.0 / gmps / 60.0 * yd)]),
		p("Everyone's age is counted in these years from their birth date, so people and animals keep ageing wherever you are."),
		links(["sys:ageing", "sys:animal_life", "sys:needs"])])
	sys.call("ageing", "Ageing and life stages", [
		p("Villagers are children until %d, adolescents until %d, adults until %d and elders after that. Children are drawn smaller (adolescents three quarters size), hold no job and are nobody's apprentice. A child who turns %d becomes an adult without a trade and takes a vacant job. An adult who turns %d retires and the post opens; elders walk slower." % [int(lf.child_until), int(lf.adolescent_until), int(lf.elder_from), int(lf.adolescent_until), int(lf.elder_from)]),
		p("From age %d a villager (and you) can die of old age: a small daily chance that rises with age, certain at %d. The sage and the reeve keep their posts for life." % [int(lf.mortality_from), int(lf.mortality_certain_at)]),
		links(["sys:calendar", "sys:family", "sys:inheritance", "sys:death"])])
	sys.call("family", "Families, partners and births", [
		p("Households are not families: people who share a house are not automatically related. Family links are real and explicit: mother, father, partner and children. Two unmarried, unrelated adults of opposite sex aged %d to %d (at most %d years apart) may become partners, and one moves into the other's home if it has a free bed. Children are born only to partners: a mother aged %d to %d, a free bed in the house, enough food, and no baby in the last year." % [int(lf.partner_min_age), int(lf.partner_max_age), int(lf.partner_max_gap), int(lf.birth_mother_min_age), int(lf.birth_mother_max_age)]),
		p("A newborn joins the parents' household and grows through the stages. The player's own partner and children are made through the same links."),
		links(["sys:ageing", "sys:inheritance", "sys:property"])])
	sys.call("inheritance", "Inheritance", [
		p("When a villager dies their coins and goods go to the family first: the eldest adult child, then the partner, then other kin; only with no family does the household take them. A household with nobody left leaves the goods where they fell and its house returns to the manor."),
		p("If you die of old age or any other cause, your heir is your eldest living child aged %d or more, who keeps your name and look; with none, a new heir of your family takes over. The heir keeps the house, the chest and what the family owns or leases, starts every skill from nothing and carries only the starting kit." % int(lf.adolescent_until)),
		links(["sys:death", "sys:saving", "sys:family"])])
	sys.call("animal_life", "Animals through life", [
		p("Animals are newborn, juvenile, adult and elderly by their age in game days. Only adults breed, and breeding slows as an area fills up. The elderly move slower and die of old age somewhere in their last stage. Young animals are drawn with the baby art. Each animal's page lists its stage lengths."),
		links(["animal:cow", "animal:pig", "animal:sheep", "animal:chicken", "animal:boar", "animal:rabbit", "sys:calendar"])])
	sys.call("saving", "Saving and your heir", [
		p("Saves are versioned and keep your world. Resting at home and the pause menu's Save write the save; Continue loads it. If you die, an heir takes over: see Inheritance."),
		links(["sys:inheritance", "sys:death", "guide:save"])])
	sys.call("death", "Death", [
		p("At 0 health, or of old age, you die. The world carries on. What you carried stays where you fell, for anyone to take, your heir too. Your heir inherits the house and chest and starts with the starting kit."),
		links(["sys:inheritance", "sys:saving", "guide:heal", "sys:ageing"])])
	sys.call("chains", "Production chains", [
		p("Raw materials become goods through stations:"),
		{"t": "chain", "id": "pickaxe"}, {"t": "chain", "id": "iron_sword"}, {"t": "chain", "id": "leather_armor"}, {"t": "chain", "id": "plank"}, {"t": "chain", "id": "roast_meat"}, {"t": "chain", "id": "ale"},
		links(["guide:planks", "guide:smelt", "guide:cook"])])


## "Linen bandage (15 health, 3 coins), ..." from items.json's medicines.
func _medicine_list() -> String:
	var out := []
	for id in GameData.items:
		var it: Dictionary = GameData.items[id]
		if str(it.get("type", "")) == "medicine":
			out.append("%s (%d health, %d coins)" % [GameData.item_name(id), int(it.get("heal", 0)), GameData.value(id)])
	return ", ".join(out)


func _not_yet() -> void:
	var items := {
		"player_shops": ["Player shops: larger stalls and attendants", "You can rent a market stall and sell from it, and build workshops on your own property (see the guides), but larger stalls, placing equipment yourself and hired attendants who sell while you are away are not built yet."],
		"cloud_saves": ["Cloud saves", "Saves stay on your device. There is no cloud sync or online play."],
		"plough": ["Hand plough and farming by the player", "You cannot till or sow fields yourself; the farmers do it. You can harvest ripe wheat."],
	}
	for id in items:
		add_page("todo:" + id, items[id][0], "notyet", [note("Not in the game yet. " + items[id][1])], "", "not implemented planned")
