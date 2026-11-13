extends SceneTree
## ND-29 probe (not a CI test; owner 2026-11-12 23:10: "Verify ... long-term sustainability"): an ordinary homestead whose people
## hold no axe and whose hearth is bare (homestead_test's fixture: Homesteads.begin, the claimant arrives), run for --days game
## days (default 40: ten deadwood_seasons cycles). Each dawn: logs gathered as deadwood by the claim, its hearth, cold nights,
## the mature trees within deadwood_radius and how many wait for their deadwood, the claim's status; at the end the goods
## ledger for logs (SettlementHoldings: held now = held at the start + made + felled - burned - used ...) is not checked here
## (economy_sim does); this reads the claim only. Read only after the fixture.
## --no-axe: the claim's people never hold an axe (the probe takes any axe they come by out of the world, so the goods ledger is
## not this probe's business): the deadwood-only homestead, as a poor claim or one whose axe broke lives. Without it the natural
## course is read (at seed 1 the homesteader buys an axe on the first market trip and fells).
##   godot --headless --path game --script res://tests/nd29_homestead_firewood_probe.gd -- [--days 40] [--seed 1] [--no-axe]

func _init() -> void:
	GameData.ensure()
	var args := OS.get_cmdline_user_args()
	var days := int(args[args.find("--days") + 1]) if "--days" in args else 40
	var seed := int(args[args.find("--seed") + 1]) if "--seed" in args else 1
	var no_axe := "--no-axe" in args
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	var hs: Homesteads = w.homesteads
	var cands := []
	for h in w.households.size():
		var o: NPC = w.construction.founder_of(h)
		if o != null and Life.npc_age(w, o) <= 30.0 and hs.gate(h, [o]) == "":
			cands.append([w.property.purse(World.hh_ref(h)), h, o])
	cands.sort()
	var n: NPC = cands[-1][2]
	w.treasury -= 300
	n.coins += 300                                  # the family's savings for the start (a conserved transfer, as homestead_test)
	hs.begin(int(cands[-1][1]), n, [n])
	var c := hs.claim_of(n)
	n.pos = Vector2(Homesteads.step_of(c)) + Vector2(0.5, 0.5)
	n.plan.clear()
	hs._arrive(n, c)
	n.inv.remove("axe", n.inv.count("axe"))
	n.inv.remove("log", n.inv.count("log"))
	var h: int = n.household
	var pantry: Inventory = w.households[h].pantry
	pantry.remove("log", pantry.count("log"))
	var r := int(Homesteads.cfg().deadwood_radius)
	var o: Overworld = w.map.overworld
	var last_day := -1
	print("PROBE seed %d claim %s household %d homesteader p:%d no_axe %s" % [seed, str(c.id), h, n.id, no_axe])
	var mine := 0                                   # logs this claim's people gathered as deadwood (pack +1 while gathering)
	var before := {}
	while w.day() < days:
		for m: NPC in w.brain._members(h):
			before[m.id] = m.inv.count("log")
			if no_axe and m.inv.has("axe"):
				m.inv.remove("axe", m.inv.count("axe"))
		w.update(1.0)
		for m: NPC in w.brain._members(h):
			if m.doing == "gathering deadwood" and m.inv.count("log") == int(before.get(m.id, 0)) + 1:
				mine += 1
		if w.day() != last_day and w.hour() >= 7.0:
			last_day = w.day()
			var grown := 0
			var waiting := 0
			var home := Homesteads.house_of(c).get_center()
			for cy in range(Overworld.chunk_of(home - Vector2i(r, r)).y, Overworld.chunk_of(home + Vector2i(r, r)).y + 1):
				for cx in range(Overworld.chunk_of(home - Vector2i(r, r)).x, Overworld.chunk_of(home + Vector2i(r, r)).x + 1):
					for t in o.chunk_trees(Vector2i(cx, cy)):
						if t.is_empty() or str(t.state) != "grown" or absi(int(t.x) - home.x) > r or absi(int(t.y) - home.y) > r:
							continue
						grown += 1
						if int(hs.deadwood.get("%d,%d" % [int(t.x), int(t.y)], 0)) > w.day():
							waiting += 1
			var axes := 0
			var alive := 0
			for m: NPC in w.brain._members(h):
				alive += 1
				axes += 1 if m.inv.has("axe") else 0
			print("DAY %d status %s alive %d axes %d hearth %d claim_deadwood %d all_deadwood %d cold %d trees %d waiting %d bought_firewood_trips %d" % [w.day(), str(c.status), alive, axes,
				pantry.count("log"), mine, int(w.stats.get("gathered_deadwood", 0)), int(w.stats.get("cold_hh_%d" % h, 0)), grown, waiting, int(hs.counts.get("trips", 0))])
	quit(0)
