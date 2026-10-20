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
	"ring": "items_gear", "amulet": "items_gear", "food": "items_food", "resource": "items_materials", "medicine": "items_medicine"}
## What each profession does, in a line (checked against NPCBrain's plans when written).
const JOB_TEXT := {
	"miner": "Works the ore seams in the mine and sells ore to the smith and the raw-goods merchant.",
	"laborer": "Day labour: mines, hauls and does odd work where it is needed.",
	"woodcutter": "Fells trees with an axe and sells the logs.",
	"carpenter": "Buys logs and saws them into planks.",
	"smith": "Smelts ore into bars at the forge and forges tools, weapons and armour at the anvil.",
	"tanner": "Buys hides, pelts and wool: makes leather, weaves wool into cloth and sews bandages for the Apothecary.",
	"farmer": "Sows, tends and harvests the wheat fields (keeping seed back), and keeps the animal pens: feeds them, collects the eggs, milk and wool, and sells them.",
	"cook": "Cooks wheat and meat into pottage and roast meat, and at the kitchen's preparation table presses milk into cheese and bakes egg bread for the tavern and the food stall.",
	"tavernkeeper": "Keeps The Well House and sells food and ale.",
	"hunter": "Hunts wild boar and rabbits for meat and hides.",
	"merchant": "Runs a market stall or shop and trades goods.",
	"guard": "Watches the village: stops thieves, returns stolen goods and fines the thief.",
	"reeve": "Runs the manor's accounts and posts its jobs on the job board.",
	"sage": "The village lorekeeper; tells the story and keeps the Apothecary (medicine brewed from flowers, bandages from the tanner).",
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


## "a", "a and b", "a, b and c".
static func _and_list(words: Array) -> String:
	if words.size() <= 1:
		return "".join(words)
	return ", ".join(words.slice(0, words.size() - 1)) + " and " + str(words[-1])


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
	WikiFarming.add_pages(w)
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
	add_category("items_medicine", "Medicine", "Bandages, poultices and tonics that heal")
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
		var diet: String = {"graze": "It grazes in its wood.", "seeds": "It picks seeds in its wood.",
			"hunt": "It hunts %s in its wood." % ", ".join((a.get("prey", []) as Array).map(func(k): return str(an[k].name).to_lower())),
			"omnivore": "It eats ripe berries near its wood and hunts %s." % ", ".join((a.get("prey", []) as Array).map(func(k): return str(an[k].name).to_lower()))}.get(str(a.get("diet", "graze")), "")
		if a.has("raids"):
			diet += " At night a hungry one takes %s from the pens." % str(an[a.raids].name).to_lower()
		if bool(a.get("people", false)):
			diet += " Struck, it fights back (%d a bite), and a starving one goes for a person alone in its wood." % int(a.bite)
		blocks.append(p("Animals get hungry and die unfed like villagers; a well-fed male and female breed, and young are half size until grown." if not wild
				else "Wild animals feed and breed in the woods. " + diet + " Hunting them takes a weapon."))
		var rs := Refuges.spec(id)
		if wild and not rs.is_empty():             # WR-01: the breeding refuges, as Refuges implements them
			var rc := Refuges.cfg()
			blocks.append(p(("Breeding refuge: each wood they live in hides a %s with a breeding pair that nobody can see, hunt or strike "
				+ "and no predator reaches. In %s, at most once every %d days, it raises a litter of %d that comes out as juveniles a "
				+ "little later, but only while that wood or another holds fewer than %d (%d%% of the %d it can carry) and can feed them; "
				+ "otherwise the young stay hidden. They head off %d to %d tiles from the refuge, each to a spot away from others of their kind, "
				+ "and settle there; when their own wood is fuller, some cross unseen to another wood, and a few are lost on the way. "
				+ "A wood hunted empty stays empty until they come, and fills again only slowly.")
				% [str(rs.site), _and_list((rs.seasons as Array).map(func(s): return str(s).to_lower())), int(rs.interval_days),
				int(a.get("litter", 1)) * maxi(1, int(rs.stock) / 2), Refuges.release_limit(int(a.get("woods_cap", 0))),
				roundi(float(rc.release_below) * 100.0), int(a.get("woods_cap", 0)), int(rs.disperse[0]), int(rs.disperse[1])]))
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
		p("Taking or selling goods marked as stolen, or being seen picking a pocket, brings the guards: they return the goods and fine you %d coins plus %d%% of what the goods are worth, so taking a whole chest costs far more than one loaf. Witnesses within %d tiles count. Pick pockets only when nobody is looking, ideally asleep victims, and do not sell stolen goods to anyone nearby." % [int(GameData.b("theft_fine")), roundi(float(GameData.b("theft_fine_share")) * 100.0), int(GameData.b("witness_radius"))]),
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
	sys.call("fighting", "Fighting with the sword", [
		p("A swing takes %.1f seconds (less as your Combat grows). The blow lands on the swing's slash, %.2f seconds after you press, on the nearest person or animal within %.1f tiles in front of you (or right beside you), so you need not walk into them. A wall, a fence or a tree between you stops the blow. Bandits and anyone fighting you are struck before a bystander." % [float(GameData.b("player_combat").swing_time), float(GameData.b("player_combat").windup), float(GameData.b("player_combat").reach)]),
		p("Pressing Attack again near the end of a swing (the last %.2f seconds) is remembered and swings again at once; pressing faster than that does not swing faster. Space or J on a keyboard, X on a pad, or a right-click on the target." % float(GameData.b("player_combat").buffer)),
		p("On a phone, the Attack button swings at a bandit, someone fighting you or game within reach; with none near it turns attack mode on, and a tap on someone walks you into sword reach and strikes. Striking a villager or a keeper's animal is a crime."),
		links(["skill:combat", "sys:theft", "controls:touch", "controls:kbm", "controls:gamepad"])])
	sys.call("trading", "Trading", [
		p("Talk to a merchant or villager to buy and sell. Prices depend on each item's base value and on supply: a seller asks more as their stock runs low, and a buyer offers less as they fill up. A seller also asks less when other traders (or your own stall and shops) offer the same thing within %d tiles, and the most when nobody near sells it: so you can make a scarce thing yourself, pay the lone seller's price, or make and sell it to bring the price down. In a bulk deal every unit is priced in turn, so buying a seller's last few costs more each and selling a buyer a big stack fetches less each; the quantity control shows the real total. Merchants have limited coins and stock: they never buy what they cannot pay for, and a trade either completes or does not happen. Villagers buy what their work needs." % int(GameData.b("local_supply").radius)),
		links(["guide:money", "job:merchant", "sys:theft"])])
	sys.call("home_work", "Villagers at home: food, medicine and wounds", [
		p("Villagers look after their own households. In the evening an adult gathers wild flowers or berries near home (what they pick is gone until it grows back, for you as for them) and brews flowers into herbal poultices at the home's hearth, keeping %d in store. Berries go into the pantry as food." % int(GameData.b("home_production").poultice_keep)),
		p("Villagers do not heal by themselves. One badly hurt (below %d%% of their health) uses a medicine they carry or the household keeps, or walks to the Apothecary and buys one with their own coins." % roundi(float(GameData.b("home_production").medicine_use_below) * 100.0)),
		p("A household can add a storefront: a counter by its door (%s). Use the door of a house you hold to build yours; it opens as your shop with no rent or licence. Industrious villagers buy the materials with their own coins and build one, and in the evening an adult sells the household's spare poultices and berries there, to you and to their neighbours." % ", ".join(Business.storefront_cost().keys().map(func(k): return "%d %s" % [int(Business.storefront_cost()[k]), GameData.item(k).name.to_lower()]))),
		p("Carts are made from the village's own materials: the carpenter saws cart wheels from planks, the smith forges the axle and the ironwork from iron bars, planks and coal, and a handcart is put together from two wheels, the axle, the ironwork and four planks at a workbench. You can make every part yourself, or buy the parts and assemble them. A storefront household with coins to spare does the same, or buys the carpenter's finished handcart when that is cheaper."),
		p("A handcart in your pack is set down from the inventory (Set it down) and becomes a cart in the world that holds %d kinds of goods. Pull your cart to take it along a step behind you (you walk at %d%% of your speed) and let go of it anywhere; open it to store and take goods like a chest. Only the owner, their family or their hired help may pull or fill a cart: taking from someone else's is theft. Park your cart at a cart stop by the market and the attendant of your market stall unloads it into the stall's store each hour. A household with a cart and spare goods loads them in the morning, pulls them to the merchants who buy them and brings the cart home, with whatever did not sell." % [int(Carts.cfg().stacks), roundi(Carts.pull_speed() * 100.0)]),
		p("Some of the trees by the houses are apple trees. A grown one bears apples in summer and autumn: pick them, as villagers short of berries do, and the tree is bare for a few days. Felled, it gives logs like any tree, and sometimes an apple sapling to plant."),
		links(["item:herbal_poultice", "item:flower", "guide:heal", "job:sage", "sys:property", "recipe:build_handcart", "recipe:make_cart_wheel", "recipe:forge_cart_axle", "recipe:forge_cart_ironwork", "item:apple", "sys:theft"])])
	sys.call("theft", "Theft and guards", [
		p("Pickpocketing needs Stealth; sleeping victims are easier. Goods you steal are marked as theirs. A guard who sees a theft, hears the victim within %d tiles, or questions you about a stolen item returns the goods and fines you %d coins plus %d%% of their value. Every theft is on your record with what was taken, how many and what it was worth." % [int(GameData.b("guard_call_radius")), int(GameData.b("theft_fine")), roundi(float(GameData.b("theft_fine_share")) * 100.0)]),
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
		p("Households are not families: people who share a house are not automatically related. Family links are real and explicit: mother, father, partner and children. Partners come from courting (see Friendship and courting): two unmarried, unrelated adults aged %d to %d (villagers court someone at most %d years apart), of either sex. A new couple moves into one of their homes if it has a free bed; with no room they live apart for a while. Children are born only to a mother and father who are partners: a mother aged %d to %d, enough food, and no baby in the last year. A baby needs no free bed: a house that grows too full for its beds is what sends a grown son or daughter (with their partner) out to found a home of their own." % [int(lf.partner_min_age), int(lf.partner_max_age), int(lf.partner_max_gap), int(lf.birth_mother_min_age), int(lf.birth_mother_max_age)]),
		p("A newborn joins the parents' household and grows through the stages. The player's own partner and children are made through the same links."),
		p("Couples make homes of their own. Partners who live apart, or a grown son or daughter and their partner in a full family house, leave to found a household when they and their families can spare enough: they buy or lease an empty house, or buy ground and start a house with a quarter of the materials paid for, building the rest as they earn. Until it stands they sleep where they did."),
		links(["sys:ageing", "sys:inheritance", "sys:property", "sys:courting"])])
	var rc: Dictionary = GameData.b("relations")
	sys.call("courting", "Friendship and courting", [
		p("Friendships and romances start the way they do in life: from time spent together, over many days. The time you spend near someone counts as you play, most for the person nearest you (whose name is up to talk to). Villagers count the hours they spend near each other: working side by side at the same trade or place most, then an evening's company, then simply being about the same place. A conversation adds a little, less each time that day, so talking over and over does next to nothing. Not every pair clicks: some people warm to each other quickly, most slowly and some hardly at all, however much time they spend together; couples who are courting grow closer faster. Gifts work the same with anyone. Defending people counts too: put down a bandit, a wolf or a bear where villagers can see, and they think better of you. Crimes they see, and worse those done to them, count against you."),
		p("Nothing can be rushed. There is a limit to how much anyone can warm to you in one day, whatever you do, and courting and marriage need you to have known each other on many separate days: about %d days before they will court, and about %d before they will marry you. Single villagers with coins or a gift to spare go looking for company in the evenings, buying a little something on the way, so they find partners sooner than those with nothing to spare." % [int(rc.court_min_days), int(rc.marry_min_days)]),
		p("Gifts and help add to that. Talk to a villager and choose Give a gift: food, flowers, ale, clothes and jewellery are always welcome. Some gifts suit a person better and count double: what their trade uses (coal for a smith, seed for a farmer, a pickaxe or ale for a miner) and what they need now (food when they are hungry, medicine when they are hurt). The gift list marks those with a star and says why. One gift a day counts; the same gift again and again counts for less."),
		p("Help counts too: a request done for someone, or work done for them, raises how well they think of you. Once they think well enough of you a Befriend choice appears; there is nothing to ask. Friends sell to you about %d%% cheaper and buy about %d%% dearer, carry for your building site without a wage, tell you who in the village is courting whom, and stand up for you: a guard who is your friend lets you off a theft with a warning, and a friend nearby talks the fine down by half." % [roundi(float(rc.friend_price) * 100.0), roundi(float(rc.friend_price) * 100.0)]),
		p("Gifts to someone you could marry also draw them to you. When they are drawn to you, Ask to court appears; ask too early and they say you hardly know each other. While courting, keep up the gifts and visits: Propose when the time is right. Propose too soon (before %d days of courting, or before they are truly in love) and they say it is too soon, and cool a little. Feelings fade slowly if you stay away." % int(rc.propose_min_days)),
		p("A proposal can be refused even after a good courtship. Some people do not mean to marry at all. Someone else courting them may hold more of their heart. They may not think well enough of you: harm you have done them lowers it, and so does harm to their family or friends, such as robbing their mother or a friend. Nobody will court or marry someone who has killed a villager, or who has been seen stealing again and again; that reputation takes time to fade, and a killing never does."),
		p("Villagers court each other the same way: they take an interest in someone they have come to know, bring gifts or spend time together, court, and propose. Anyone may court anyone of the same age range who is not kin and not already spoken for, man or woman."),
		links(["sys:family", "sys:trading"])])
	sys.call("inheritance", "Inheritance", [
		p("When a villager dies their coins and goods go to the family first: the eldest adult child, then the partner, then other kin; only with no family does the household take them. A household with nobody left leaves the goods where they fell and its house returns to the manor."),
		p("If you die of old age or any other cause, your heir is your eldest living child aged %d or more, who keeps your name and look; with none, a new heir of your family takes over. The heir keeps the house, the chest and what the family owns or leases, starts every skill from nothing and carries only the starting kit." % int(lf.adolescent_until)),
		links(["sys:death", "sys:saving", "sys:family"])])
	sys.call("animal_life", "Animals through life", [
		p("Animals are newborn, juvenile, adult and elderly by their age in game days. Only adults breed, and breeding slows as an area fills up. The elderly move slower and die of old age somewhere in their last stage. Young animals are drawn with the baby art. Each animal's page lists its stage lengths."),
		links(["animal:cow", "animal:pig", "animal:sheep", "animal:chicken", "animal:boar", "animal:rabbit", "animal:deer", "animal:wolf", "animal:fox", "animal:bear", "animal:bird", "sys:calendar"])])
	sys.call("saving", "Saving and your heir", [
		p("Saves are versioned and keep your world. Resting at home and the pause menu's Save write the save; Continue loads it. If you die, an heir takes over: see Inheritance."),
		p("Your save lives inside the game, and uninstalling the game deletes it, as can installing a test build that cannot update the old one. To keep your world, open Settings, Saves: Copy my save to a file puts a copy wherever you choose (Documents, Downloads, a cloud folder), and Keep a copy up to date rewrites that copy every time the game saves. After reinstalling, choose Import a save file and pick your copy: the game checks it, keeps a backup of it and of any save it replaces, brings it up to this version and continues your world. A file it cannot use (damaged, from a newer version, or from before the village was rebuilt) is refused and nothing changes. On Android you pick the file again after each reinstall. Inside the game, each save keeps the one before it as a backup, and the first save of each day keeps the previous save under that day's date, the last three days; if a save and its backup cannot be read, Continue loads the newest of those."),
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
		"player_shops": ["Player shops: production chains and trade perks", "You can rent and enlarge a market stall, open a shop in a room you built, fit it with equipment and hire an attendant (see the guides). Not built yet: attendants and hired workers who craft at the shop's stations from its stock, shops in houses you only rent from a neighbour, a stall display shown over the stall, and trading skill perks on your sales."],
		"cloud_saves": ["Cloud saves", "Saves stay on your device. There is no cloud sync or online play."],
		"farm_more": ["Draught animals, coops, watering, trapping and hired farmhands", "You can farm and keep animals yourself (see the farming guides), but there are no horses or oxen to pull a plough, no roofed coops or shelters, no watering or weather, no traps for rabbits, no animals from the caravan and no hired farmhands yet."],
	}
	for id in items:
		add_page("todo:" + id, items[id][0], "notyet", [note("Not in the game yet. " + items[id][1])], "", "not implemented planned")
