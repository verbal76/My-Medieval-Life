class_name WikiHome
extends RefCounted
## The wiki's pages for a home's furniture (PL2-013): sitting, sleeping, the home oven and the food table.
## Registered by one line in Wiki.build(); the rules behind them are Furniture's (scripts/core/furniture.gd).


static func add_pages(w: Wiki) -> void:
	var sys := func(id: String, title: String, blocks: Array, kw := "") -> void:
		w.add_page("sys:" + id, title, "systems", blocks, "", kw)
	sys.call("sitting", "Sitting on chairs", [
		Wiki.p("Inside your own house, face a chair (a wooden stool) and use it to sit. You are drawn seated on it, the legs under the table. Move, press any button, use the stick or tap to stand up again, on the free cell beside the chair."),
		Wiki.p("The family sits on its own chairs to eat, too. Every chair works the same in every house, including one you build."),
		Wiki.links(["sys:sleeping", "sys:food_table", "sys:resting"])], "chair stool seat sit stand")
	sys.call("sleeping", "Sleeping in your bed", [
		Wiki.p("Use your bed inside your own house and you lie down in it for the night (or two hours by day) and wake standing beside it. It restores full health and stamina and saves. B, Esc or a tap wakes you early: you get up beside the bed and the night is not slept."),
		Wiki.p("Your family sleeps in their beds the same way: lying on the bed, not standing in it. Guards and cooks lodge on the straw pallets."),
		Wiki.links(["sys:resting", "sys:sitting", "guide:rent"])], "bed lie wake sleep rest pallet")
	sys.call("home_oven", "The home oven", [
		Wiki.p("The oven or hearth in your own house cooks like the village ovens: it uses the Oven recipes (roasting meat with a log) and nothing else. It does not smelt: ore is smelted at the Forge."),
		Wiki.h("Recipes")] + GameData.recipes_at("oven").map(func(r): return {"t": "recipe", "id": r}) + [
		Wiki.links(["sys:food_table", "station:oven", "station:forge"])], "oven hearth cook roast bake home")
	sys.call("food_table", "The food table", [
		Wiki.p("A table in your own house is a food-preparation station: work that needs no heat, done by hand from what you already have. It is separate from cooking, which needs the oven or the stove."),
		Wiki.h("Recipes")] + GameData.recipes_at("prep").map(func(r): return {"t": "recipe", "id": r}) + [
		Wiki.links(["sys:home_oven", "sys:sitting"])], "table food prepare preparation bread dough knead")
	w.add_page("station:prep", "Food table", "stations", [
		Wiki.p("A table where food is prepared without heat: one in your own house, and the preparation table in the tavern kitchen beside the oven, where the cook presses cheese and bakes egg bread from the pens' milk and eggs. Anyone may use the tavern's when it is free."),
		Wiki.h("Recipes")] + GameData.recipes_at("prep").map(func(r): return {"t": "recipe", "id": r}) + [
		Wiki.links(["sys:food_table"])], "", "prep table food")
