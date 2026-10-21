extends SceneTree
## PROSPECTIVE (Expansion 19, PROS-19): the provisional live adapter (JudgmentLive) in a real World. Off by default and
## behaviour-neutral when off; when a test attaches a store: what the village sees becomes judged events, time together
## passes word on, the player and villagers are judged alike, the trade-choice prototype weighs judgment against need
## and price without leaving the live rule's candidates, saves keep the section, and runs are reproducible. Run headless:
##   godot --headless --path game --script res://tests/judgment_live_test.gd

var failures := 0
var checks := 0
const ME := Life.PLAYER_ID
const STEP := 0.5


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func new_world(seed := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	return w


func _init() -> void:
	test_off_by_default()
	test_observation()
	test_same_rules_live()
	test_trade_choice()
	test_save()
	test_running_world()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func adults(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "guard":
			out.append(n)
	return out


func test_off_by_default() -> void:
	check(not JudgmentLive.enabled(), "judgment.json ships with enabled false")
	var w := new_world()
	check(w.judgment == null, "a new world has no judgment store")
	check(not w.to_dict().has("judgment"), "...and its save has no judgment section (Build 16 layout unchanged)")
	w.dispose()


## A theft seen by villagers (World.witness, the player's channel): the victim and those who saw it judge the player.
func test_observation() -> void:
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var people := adults(w)
	var victim: NPC = people[0]
	w.player.pos = victim.pos
	var near := []
	for n: NPC in people.slice(1, 4):
		n.pos = victim.pos + Vector2(1, 0)
		n.anim = "idle"
		near.append(n)
	victim.inv.add("bread", 1)
	var seen := w.witness("theft", "bread", victim, {"bread": 1})
	check(seen >= 1, "the theft is seen (%d)" % seen)
	check(j.bad(victim.id, ME) == 1000, "the victim judges the player 1 BAD")
	var judged := 0
	for n: NPC in near:
		if j.bad(n.id, ME) > 0:
			judged += 1
	check(judged == near.size(), "every villager who saw it judges the player (%d of %d)" % [judged, near.size()])
	check(str(j.belief(near[0].id, 1).src) == "witnessed" and str(j.belief(victim.id, 1).src) == "participant", "...with provenance: witnessed, participant")
	var far: NPC = people[-1]
	check(j.ledger(far.id, ME)[2] == 0, "someone far away knows nothing (no omniscience)")
	w.dispose()


## The same assault by the player and by a villager, seen by the same people, posts the same points.
func test_same_rules_live() -> void:
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var people := adults(w)
	var victim: NPC = people[0]
	var attacker: NPC = people[1]
	var witness: NPC = people[2]
	for n in [attacker, witness]:
		n.pos = victim.pos
		n.anim = "idle"
	w.player.pos = victim.pos
	w.raise_alarm(w.aware_of_attack(victim.pos, victim), ME)
	w.raise_alarm(w.aware_of_attack(victim.pos, victim), attacker.id)
	check(j.bad(witness.id, ME) > 0 and j.ledger(witness.id, ME) == j.ledger(witness.id, attacker.id),
			"a villager's assault and the player's are judged by the same rules (%s and %s BAD)" % [JudgmentMath.pts(j.bad(witness.id, ME)), JudgmentMath.pts(j.bad(witness.id, attacker.id))])
	check(j.ledger(victim.id, ME) == j.ledger(victim.id, attacker.id) and j.bad(victim.id, ME) == 2000, "the victim: 2 BAD for each")
	w.dispose()


## The trade prototype: the candidates are the live rule's; judgment shifts the pick only among them.
func test_trade_choice() -> void:
	var w := new_world()
	var seller: NPC = null
	for n: NPC in adults(w):
		if n.job == "miner":
			seller = n
			break
	if seller == null:
		seller = adults(w)[0]
	seller.inv.add("iron_ore", 3)
	var live: NPC = w.brain._buyer_for(seller, "iron_ore")
	check(live != null, "the live rule finds a buyer for iron ore (%s)" % (live.job if live else "none"))
	var j := JudgmentLive.attach(w)
	var all := []
	for outlet in NPCBrain.OUTLETS.iron_ore:
		for b in w.brain._with_buy_role(outlet):
			if b != seller and b.alive and w.purchase_qty(b, seller, "iron_ore", 3) > 0:
				all.append(b)
	var pick: NPC = w.brain._buyer_for(seller, "iron_ore")
	check(pick != null and all.has(pick), "with judgment on, the buyer is one the live rule allows")
	check(pick == live, "...and while every judgment is neutral it is the live rule's own choice (%s)" % (pick.name if pick else "none"))
	if all.size() >= 2:
		var other: NPC = all[0] if pick != all[0] else all[1]
		j.set_ledger(seller.id, pick.id, 0, 60000)              # the seller comes to dislike that buyer (-60)
		var again: NPC = w.brain._buyer_for(seller, "iron_ore")
		check(again == other or again == pick, "a strong dislike may turn the seller to another buyer (%s -> %s)" % [pick.name, again.name])
		check(again != pick, "...and here it does: two buyers, the disliked one avoided")
		for b in all:
			if b != pick:
				j.set_ledger(seller.id, b.id, 0, 60000)
		var feasible_only: NPC = w.brain._buyer_for(seller, "iron_ore")
		check(feasible_only != null, "disliking every buyer, the seller still sells: need for coin outweighs opinion")
	else:
		print("note: only one iron buyer in this village; the two-buyer case is covered by judgment_test")
	# the shortcut (skip the full scan when the live pick must win) chooses exactly as the full scan, opinion by opinion
	var same := 0
	var tried := 0
	for k in 12:
		for b in all:
			j.set_ledger(seller.id, b.id, (k * 7919 + b.id * 31) % 5 * 15000, (k * 104729 + b.id * 17) % 5 * 15000)
		for b in [w.npcs[k % w.npcs.size()], w.npcs[(k * 7) % w.npcs.size()]]:
			j.set_ledger(seller.id, b.id, k * 9000, 0)
		JudgmentLive.shortcut = true
		var fast: NPC = w.brain._buyer_for(seller, "iron_ore")
		JudgmentLive.shortcut = false
		var full: NPC = w.brain._buyer_for(seller, "iron_ore")
		JudgmentLive.shortcut = true
		tried += 1
		if fast == full:
			same += 1
	check(same == tried, "the trade shortcut picks exactly as the full scan (%d of %d opinion mixes; %d shortcuts taken)" % [same, tried, int(j.stats.get("trade_shortcut", 0))])
	j.set_ledger(seller.id, pick.id, 900000, 0)
	var b2: NPC = w.brain._buyer_for(seller, "iron_ore")
	check(b2 == null or all.has(b2), "a liked buyer cannot be chosen outside the live rule (no infeasible sale)")
	w.dispose()


func test_save() -> void:
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var people := adults(w)
	var victim: NPC = people[0]
	w.player.pos = victim.pos
	victim.inv.add("bread", 1)
	w.witness("theft", "bread", victim, {"bread": 1})
	j.meet(victim.id, people[5].id)
	var d := w.to_dict()
	check(d.has("judgment") and int(d.save_version) == World.SAVE_VERSION, "with judgment attached the save carries a judgment section; SAVE_VERSION unchanged (%d)" % World.SAVE_VERSION)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w2.judgment != null and JSON.stringify(w2.judgment.to_dict()) == JSON.stringify(j.to_dict()), "the judgment section saves and loads unchanged")
	check(w2.judgment.bad(victim.id, ME) == 1000 and str(w2.judgment.belief(people[5].id, 1).src) == "told", "...the victim's judgment and the told villager's provenance survive")
	d.erase("judgment")
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	check(w3.judgment == null and not w3.to_dict().has("judgment"), "a Build 16 save (no section) loads with judgment off, and saves as it was")
	var bad := w.to_dict()
	bad.judgment = {"format": "mml-judgment/1", "version": 42}
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(bad)))
	check(w4.judgment != null and int(w4.to_dict().judgment.version) == 42, "a section from a newer game is kept and written back, not dropped")
	for x in [w, w2, w3, w4]:
		x.dispose()


## A day of the real village with judgment on, twice from the same seed: villagers meet and pass word on, and both
## runs (conservation with judgment on: economy_sim.gd --judgment) end in the same world and the same judgment state.
func test_running_world() -> void:
	var hashes := []
	var prints := []
	for run in 2:
		var w := new_world(3)
		var j := JudgmentLive.attach(w)
		var people := adults(w)
		var victim: NPC = people[0]
		w.player.pos = victim.pos
		victim.inv.add("bread", 1)
		w.witness("theft", "bread", victim, {"bread": 1})          # something to talk about
		w.raise_alarm(w.aware_of_attack(victim.pos, victim), people[1].id)
		var steps := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
		for i in steps:
			w.update(STEP)
			w.player.hunger = 100.0
		var cn := j.counts()
		if run == 0:
			print("one day: %s; stats %s" % [JSON.stringify(cn), JSON.stringify(j.stats)])
			check(int(j.stats.get("tellings", 0)) > 0, "villagers who spend time together pass word on (%d tellings)" % int(j.stats.get("tellings", 0)))
			var told := 0
			for o in j.memories:
				for ev in j.memories[o]:
					if str(j.belief(o, ev).src) in ["told", "rumour"]:
						told += 1
			check(told > 0, "some villagers now know of the theft or the attack only by word of mouth (%d beliefs)" % told)
		hashes.append(j.state_hash())
		var parts := PackedStringArray([str(w.minutes), str(w.rng.state), str(w.treasury)])
		for n: NPC in w.npcs:
			parts.append("%d|%d|%s|%s" % [n.id, n.coins, n.pos, n.inv.items])
		prints.append("|".join(parts).md5_text())
		w.dispose()
	check(hashes[0] == hashes[1], "same seed, same judgment state after a day")
	check(prints[0] == prints[1], "same seed, same world after a day with judgment on")
