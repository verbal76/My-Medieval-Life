class_name WikiFarming
extends RefCounted
## PL2-015: the wiki's pages for farming and livestock by the player. Every number comes from balance.json
## "farming" (the rules are in Farming, farming.gd), so the text cannot drift from the game.


static func add_pages(w: Wiki) -> void:
	var f: Dictionary = Farming.cfg()
	var crops: Dictionary = f.crops
	var crop_lines := []
	var ids: Array = crops.keys()
	ids.sort()
	for id in ids:
		var c: Dictionary = crops[id]
		crop_lines.append("%s: ripe in %s game days of spring or summer growth, %d %s a cell and %d seed back; seed costs %d coins." % [
				c.name, str(c.days), int(c.yield), GameData.item_name(str(c.item)).to_lower(), int(c.seeds_back), int(c.seed_price)])
	var rates: Dictionary = f.season_rate
	w.add_page("sys:farming", "Farming: your own field", "systems", [
		Wiki.p("On ground you own or lease from the manor you can farm. Fell the trees (an axe), dig out the stumps (an axe), pull up saplings and grub up wild plants by hand, and mine boulders away (a pickaxe). Then face a cleared cell and Use to till it. Each tilled cell joins your field, so a field can be any shape."),
		Wiki.p("Tilling by hand takes %.0f seconds a cell and %.0f stamina (you need that much to begin). A hand plough, made at the workbench from planks and iron bars, does it in %.1f seconds for %.0f stamina. There are no horses or oxen, so nothing pulls the plough but you." % [
				float(f.till.hand.seconds), float(f.till.hand.stamina), float(f.till.plough.seconds), float(f.till.plough.stamina)]),
		Wiki.p("Sow a tilled cell with seed from your pack (Use). Crops grow by the hour at the season's pace: spring and summer full speed, autumn at %d%%, winter not at all, and nothing can be sown in winter. A ripe cell is harvested with Use: you get its crop and some seed back, so a field can be sown again without buying seed. Seed is sold by the farmers and by the food stall's merchant." % roundi(float(rates.get("Autumn", 0.5)) * 100.0)),
		Wiki.bullets(crop_lines),
		Wiki.p("Wheat, carrots, potatoes and herbs sell to the cook and the food merchant (and to the sage, for herbs), at the market or from your own stall. The manor's own fields and their farmers are not affected: their crops are theirs, and taking them is theft."),
		Wiki.links(["guide:farm_start", "guide:animals", "item:plough", "recipe:craft_plough", "item:wheat_seed", "item:carrot", "item:potato", "animal:chicken", "sys:property"])])
	w.add_page("guide:farm_start", "How do I start a farm?", "guides", [
		Wiki.p("You need no coins to begin the work, only ground. Buy or lease a plot from the manor (the reeve's land office, or walk onto a plot and Use), then clear it: Use on a tree felled with an axe, then on its stump, on saplings, wild plants and boulders."),
		Wiki.p("Till the soil by hand, which is slow and tiring, or make a hand plough at the workbench (%s) and carry it: tilling is then about three times quicker and far easier. Put the plough in your hand from the pack to make Use till the soil in front of you straight away." % ", ".join((GameData.recipes["craft_plough"].in as Dictionary).keys().map(func(k): return "%d %s" % [int(GameData.recipes["craft_plough"].in[k]), GameData.item_name(str(k)).to_lower()]))),
		Wiki.p("Buy a few seeds from a farmer or at the food stall (Trade): they sell from their own stock, so a seller can run out. Farmers keep seed back from each harvest, and the caravan brings the food stall more, so try again later. Face a tilled cell and Use to sow. Come back when it is ripe and Use to harvest. Keep some seed back for the next sowing, sell the rest, or bake and cook it. In winter nothing can be sown, so clear and till then."),
		Wiki.links(["sys:farming", "guide:animals", "recipe:craft_plough", "item:plough"])])
	var pens := []
	for kind in f.pens:
		var s: Array = f.pens[kind]
		pens.append("%s pen: %d by %d tiles, about %d planks; %s from the keeper." % [str(kind).capitalize(), int(s[0]), int(s[1]), Farming.new(null).pen_planks(Rect2i(0, 0, int(s[0]), int(s[1]))), "%d coins an adult" % int(f.animal_price[kind])])
	w.add_page("guide:animals", "How do I keep animals?", "guides", [
		Wiki.p("Open the plot's window (Use on your ground) and choose Fence a pen: it goes in front of you, on your own cleared ground, with a gate in the middle of the top side. A pen holds one kind of animal."),
		Wiki.bullets(pens),
		Wiki.p("Stand at the keeper's pen gate to buy stock: they sell you young and adult animals of each sex out of their own pen (they keep their breeding stock), and the coins are theirs. Buy a male and a female so they breed. Feed your animals wheat at your pen's gate (Use at the trough); a hungry animal that is not fed loses health and dies, and only well-fed adults breed and give products."),
		Wiki.p("Eggs (a hen, daily), milk (a cow, %d a day) and wool (a sheep, every %d days) gather in the pen, up to %d of each. Use at the gate to collect them. Sell them to the cook or the food and goods merchants, or from your stall; press cheese from milk and bake egg bread at a food table; weave wool into cloth at the workbench and sew bandages from it. A pen animal you slaughter gives meat and hide, as any." % [
				int(f.products.cow.qty), roundi(float(f.products.sheep.days)), int(f.product_cap)]),
		Wiki.links(["animal:cow", "animal:sheep", "guide:farm_start", "item:egg", "item:milk", "item:wool", "recipe:press_cheese", "recipe:weave_cloth", "recipe:sew_bandages", "recipe:bake_egg_bread"])])
