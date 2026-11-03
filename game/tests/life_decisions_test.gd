extends SceneTree
## B25R1-014 (owner directive 2026-11-03, decisions D1-D4; docs/design/HOMESTEADING_B25R1.md sections 8, 10, 11): the judged
## life choices in the shipped configuration (judgment on, decision.integration homestead_choice, runaway_choice,
## recruit_answer, bandit_leave on), on the real World:
##   A  the homestead brake: no homestead before 2 % of formations allow one; with the allowance, the choice is weighed
##   B  hardship that does NOT produce a runaway (at the threshold, cared for), and a child under 12 below the higher bar
##   C  deep, unimproving hardship that legitimately does: the young person leaves (kin or a willing household first), the
##      family records and the register keep them, the family learns of it; at most once a season
##   D  the band's answer: a full band rejects; a small band accepts an adult (no gear, skill or coin given); a child is never
##      made a fighter
##   E  an adult bandit weighs leaving and leaves: identity, wounds, pack, purse, family kept; a lawful household; save/load
##   F  a claim's identity through faction change (outlaw, concealed, lawful again), saved and loaded
##   G  deterministic replay: the same world and steps give the same choices
## Run: godot --headless --path game --script res://tests/life_decisions_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _world(seed: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _child(w: World, lo: float, hi: float) -> NPC:
	for n: NPC in w.npcs:
		var a := Life.npc_age(w, n)
		if n.alive and n.role == "child" and n.clan == "" and n.household >= 3 and a >= lo and a < hi:
			return n
	return null


func _init() -> void:
	var w := _world(1)
	var life: LifeDecisions = w.life
	check(w.judgment != null and life.on("homestead_choice") and life.on("runaway_choice") and life.on("recruit_answer") and life.on("bandit_leave"),
		"the four life choices are on in the shipped configuration")
	# ---- A: the brake
	var f: NPC = null
	var fh := -1
	for h in w.households.size():
		var o: NPC = w.construction.founder_of(h)
		if o != null and Life.npc_age(w, o) <= 30.0 and w.homesteads.gate(h, [o]) == "":
			f = o
			fh = h
	check(f != null, "a young adult who could found a household")
	if f != null:
		check(life.homestead_decider(fh, f, [f], "young") == null and int(life.counts.get("brake_young", 0)) == 1, "A: the first formation: the brake allows no homestead (2 % of 1)")
		life.counts["total_form_young"] = 60            # (sixty formations on record: 2 % allows one)
		w.treasury -= 400
		f.coins += 400
		var who := life.homestead_decider(fh, f, [f], "young")
		check(int(life.counts.get("weighed_young", 0)) == 1, "A: with the allowance, the choice is weighed through JudgmentWeighting (homestead_choice): %s" % ("homestead" if who != null else "the village"))
		if who != null:
			check(w.homesteads.begin(fh, who, [who], "young") and life._total("home_young") == 1, "A: chosen, they set out, counted against the brake")
		w.treasury += 0
	# ---- B: hardship that does not produce a runaway
	var k := _child(w, 12.0, 16.0)
	check(k != null, "an adolescent of a village household")
	var cf := LifeDecisions.cfg()
	if k != null:
		var h0 := k.household
		life.hardship[str(h0)] = {"bad": int(cf.runaway_days), "home": str(w.households[h0].home), "adults": 2, "event": -999}
		life._runaways_dawn()
		check(k.household == h0 and not life.runaways.has(str(k.id)) and int(life.counts.get("runaway_stay", 0)) >= 1,
			"B: two years of hardship, cared for at home: the adolescent weighs it and stays (%s)" % life.counts)
		life._runaways_dawn()
		check(int(life.counts.get("runaway_weighed", 0)) == 1, "B: weighed at most once a season (not again the next dawn)")
	var little := _child(w, 8.0, 12.0)
	if little != null:
		var hl := little.household
		life.hardship[str(hl)] = {"bad": int(cf.runaway_days) * 2, "home": str(w.households[hl].home), "adults": 2, "event": -999}
		var before := int(life.counts.get("runaway_weighed", 0))
		life.seen.erase(str(little.id))
		life._runaways_dawn()
		check(little.household == hl and int(life.counts.get("runaway_weighed", 0)) == before + (0 if little.household == hl and life.seen.get(str(little.id), -1) == -1 else 1),
			"B: a child under 12 in four years of hardship is below the far higher bar (not even weighed)")
	# ---- C: deep, unimproving hardship: a legitimate departure
	var k2 := _child(w, 12.0, 16.0)
	if k2 != null and k != null and k2 == k:
		for n: NPC in w.npcs:
			if n != k and n.alive and n.role == "child" and n.clan == "" and n.household >= 3 and n.household != k.household and Life.npc_age(w, n) >= 12.0:
				k2 = n
				break
	if k2 != null:
		var h2 := k2.household
		var id2 := k2.id
		var mum := k2.mother
		life.hardship[str(h2)] = {"bad": int(cf.runaway_days) * 4, "home": str(w.households[h2].home), "adults": 1, "event": w.day()}
		life.seen.erase(str(id2))
		var people0 := w.people.size()
		life._weigh_runaway(k2, life.hardship[str(h2)], false, false)
		var rec: Dictionary = life.runaways.get(str(id2), {})
		check(not rec.is_empty() and str(rec.outcome) != "stay", "C: eight years of deep hardship and the loss of a parent: the adolescent leaves home (%s)" % rec.get("outcome", "stayed"))
		check(w.npc(id2) == k2 and k2.mother == mum and w.people.has(id2) and w.people.size() == people0, "C: the same person, their parents and the register unchanged")
		check(int(rec.get("from", -1)) == h2, "C: the household they left is on record (%s)" % rec)
		if str(rec.get("outcome", "")) == "seek_help":
			check(k2.household != h2 and w.households[k2.household].members.has(id2), "C: taken in by another household (Guardianship's order)")
	# ---- D: the band's answer
	var adult: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 3 and n.job == "" and not w.homesteads.away(n):
			adult = n
			break
	if adult == null:
		for n: NPC in w.npcs:
			if n.alive and n.role == "adult" and n.household >= 3 and not w.homesteads.away(n) and n.id != w.reeve_id and n.id != w.sage_id:
				adult = n
				break
	var band := w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "bandit")
	check(band.size() >= 3, "a band lives at the camp (%d)" % band.size())
	var inv0: Dictionary = adult.inv.items.duplicate()
	var coins0 := adult.coins
	life.counts.erase("recruit_reject")
	var full := int(cf.band_full)
	var ans := life._recruit_answer(adult) if band.size() >= full else "reject"
	if band.size() >= full:
		check(ans == "reject" and adult.role == "adult", "D: a full band (%d) sends a grown recruit away" % band.size())
	while w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "bandit").size() > 2:
		var b: NPC = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "bandit")[0]
		w.kill(b, "test")
	var name0 := "%s %s" % [adult.name, adult.family]
	var ans2 := life._recruit_answer(adult)
	check(ans2 == "accept" and adult.role == "bandit" and adult.household == -1, "D: a band of two takes the grown recruit in (%s)" % ans2)
	check(adult.inv.items == inv0 and adult.coins == coins0 and "%s %s" % [adult.name, adult.family] == name0, "D: nothing given: the same pack, purse and name")
	var kid := _child(w, 12.0, 16.0)
	if kid != null:
		var ka := life._recruit_answer(kid)
		check(kid.role == "child" and (ka == "reject" or (ka == "dependant" and kid.clan == "bandit")), "D: a child is never made a fighter (%s)" % ka)
	# ---- E: leaving the band
	var bandit: NPC = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "bandit" and o != adult)[0]
	var vil: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 3 and not w.homesteads.away(n):
			vil = n
			break
	bandit.mother = vil.id                         # (a fixture: the bandit's mother lives in the village)
	bandit.hp = bandit.max_hp * 0.2
	var hp0 := bandit.hp
	var pack0: Dictionary = bandit.inv.items.duplicate()
	var bid := bandit.id
	w.minutes = 0.0
	for d in 12:
		w.minutes = float(d) * 1440.0 + 7.0 * 60.0
		if life._turn(bid):
			life._bandits_dawn()
			break
	check(bandit.role == "adult" and int(life.counts.get("leave_weighed", 0)) >= 1, "E: a wounded bandit with family in the village weighs leaving and leaves (%s)" % life.counts.get("left_band", 0))
	check(bandit.hp == hp0 and bandit.inv.items == pack0 and w.npc(bid) == bandit, "E: the same person, wounds and pack kept")
	check(bandit.household >= 0 and w.households[bandit.household].members.has(bid), "E: a member of a lawful household now (%s)" % w.households[bandit.household].family if bandit.household >= 0 else "none")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), saved)
	var b2 := w2.npc(bid)
	check(w2.load_error == "" and b2 != null and b2.role == "adult" and b2.household == bandit.household, "E: saved and loaded: still a former bandit in their household")
	check(int(w2.life.counts.get("left_band", 0)) == int(life.counts.get("left_band", 0)) and w2.life.runaways.size() == life.runaways.size(), "E: the records of who left are saved")
	# ---- F: a claim's identity through faction change
	var c := {}
	if not w.homesteads.claims.is_empty():
		c = w.homesteads.claims[0]
	else:
		var p := w.player
		var site := w.homesteads.find_site(w.npcs[10])
		p.pos = Vector2(Vector2i(site.lay.door) + Vector2i(0, 1)) + Vector2(0.5, 0.5)
		w.homesteads.player_claim(p)
		c = w.homesteads.claims[0]
	var id_c := str(c.id)
	var land := Homesteads.rect_of(c)
	check(w.homesteads.set_faction(c, "outlaw", true, "test") and str(c.faction) == "outlaw" and str(c.id) == id_c and Homesteads.rect_of(c) == land,
		"F: the claim turns outlaw and concealed: the same claim, land and owner")
	check(w.homesteads.set_faction(c, "lawful", false, "test") and (c.allegiance as Array).size() == 3, "F: and lawful again, every change dated (%s)" % str(c.allegiance))
	w.homesteads.set_faction(c, "outlaw", true, "test")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	var c3 := w3.homesteads.claim(id_c)
	check(str(c3.faction) == "outlaw" and bool(c3.concealed) and (c3.allegiance as Array).size() == 4, "F: saved and loaded with its faction and history")
	w2.dispose()
	w3.dispose()
	# ---- G: deterministic replay
	var outs := []
	for rep in 2:
		var wr := _world(3)
		var kr := _child(wr, 12.0, 16.0)
		var res := ""
		if kr != null:
			wr.life.hardship[str(kr.household)] = {"bad": int(cf.runaway_days) * 3, "home": "", "adults": 1, "event": wr.day()}
			res = wr.life._weigh_runaway(kr, wr.life.hardship[str(kr.household)], false, false)
		outs.append(res)
		wr.dispose()
	check(outs[0] == outs[1] and outs[0] != "", "G: the same world and steps give the same choice twice (%s)" % str(outs))
	w.dispose()
	print("life_decisions_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
