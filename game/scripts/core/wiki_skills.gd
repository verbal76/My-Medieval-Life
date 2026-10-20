class_name WikiSkills
extends RefCounted
## Wiki pages for the skill system (PL2-005). The per-skill pages come from Wiki._skills (their
## tier lines are printed by Skills.tier_text from skills.json); this adds the page about the curve:
## the xp each level needs and the rank names, from the same data. Registered in Wiki.build.


static func add_pages(w: Wiki) -> void:
	var rows := []
	for lv in range(1, Skills.max_level() + 1):
		var need := "top level" if lv >= Skills.max_level() else "%d xp to the next level" % Skills.step(lv)
		var rank := Skills.rank(lv) if Skills.rank(lv) != Skills.rank(lv - 1) else ""
		rows.append(["Level %d" % lv, "starts at %d xp; %s%s" % [Skills.xp_for_level(lv), need, ("  (" + rank + ")") if rank != "" else ""]])
	var ids := GameData.skills.keys().map(func(k): return "skill:" + str(k))
	w.add_page("sys:skills", "Skills and levels", "systems", [
		Wiki.p("Every skill grows by use and runs from level 1 to level %d. Early levels come quickly and later ones take long play: a first day of mining or chopping earns a level or two, not a tier. Every perk on a skill's page is applied in the game." % Skills.max_level()),
		Wiki.p("Villagers have skills by the same rules: the same work earns them the same experience, the same levels open the same recipes and seams (a miner needs Mining 3 for gold, as you do), and the same perks apply to them. The first villagers begin with the experience of their years at their trade before the game began; after that, everyone learns only by doing, whatever their trade: a new job brings no experience and takes none away, and a newcomer starts from what they learn here."),
		Wiki.stats(rows),
		Wiki.links(ids, "The skills")], "", "experience xp level tier rank perk")
