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
		Wiki.links(ids, "The skills"),
		Wiki.links(["sys:trade_experience"], "See also")], "", "experience xp level tier rank perk")
	# X18 (owner D1-D9, 2026-10-23): what hours at a trade do, in plain words
	w.add_page("sys:trade_experience", "Experience at a trade", "systems", [
		Wiki.p("Besides skills, everyone in the village builds up experience at their trade simply by working at it: hours at the forge, at the seam, at the axe, in the fields, at the bench, at the stall. It belongs to the person: nobody gains from the experience of the person beside them, it is never lost while they stay, and it leaves the village with them."),
		Wiki.p("Experience makes a person's own work a little faster and, where they are paid by the job, a little better paid. The gain is small and grows smoothly with every hour worked; it is largest for smiths and carpenters and smaller for miners and woodcutters. Nothing is ever refused for lack of it: a newcomer may do any work and simply starts at the pace of a beginner. A person who is paid a set wage by the day, or whose price is agreed in a bargain or a contract, is not paid more for it, and it never makes the village's ore, grain or goods appear from nowhere: a quick hand finishes sooner, from the same stores and fields."),
		Wiki.p("Wages the manor offers for a job (mending, quarrying) are settled when someone takes the job, at that person's own experience, and the manor sets that sum aside then. Where several farmers cut one field together, the grain and the seed kept back for next year's sowing are shared by the work each did: a quicker cutter's share follows the ground they cut, not the hours they took."),
		Wiki.p("When the village's record of its trades names how practised someone is, it uses three words: a novice (still learning), a journeyman (practised) and a master. They are only names for how far along someone is. Your own experience counts too, and starts from nothing."),
		Wiki.p("Hours count for the work the trade really is: smithing, carpentry and tanning at the benches, mining and digging (surveys, trial pits, pits, tunnels, shoring and filling them), felling, farming (field work, clearing ground, fencing farmland, tending and slaughtering stock) and keeping a stall open for trade. Hunting, gathering, picking fruit, building and carrying or carting earn none."),
		Wiki.links(["sys:skills", "sys:manor_jobs", "sys:farming"], "Related")], "", "experience novice journeyman master trade practised pace pay hours")
