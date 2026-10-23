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
	test_q10_no_numbers_in_ui()
	test_q06_live_trust()
	test_q14_befriend()
	test_q14_court()
	test_q14_buy_from()
	test_q14_hiring()
	test_event_feeds()
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



# ---------------------------------------------------------------- owner decisions, 2026-10-21 --------
## Q10: no judgment number reaches the normal game screens: no UI script reads the judgment store at all (attitudes show
## only through behaviour: trade, prices, help, friendship, courtship, work); the developer inspector stays.
func test_q10_no_numbers_in_ui() -> void:
	var files := ["res://scripts/main.gd"]
	var d := DirAccess.open("res://scripts/ui")
	if d != null:
		for f in d.get_files():
			if f.ends_with(".gd"):
				files.append("res://scripts/ui/" + f)
	var view := DirAccess.open("res://scripts/view")
	if view != null:
		for f in view.get_files():
			if f.ends_with(".gd"):
				files.append("res://scripts/view/" + f)
	var hits := []
	for f in files:
		var text := FileAccess.open(f, FileAccess.READ).get_as_text()
		if text.contains("judgment") or text.contains("Judgment"):
			hits.append(f)
	check(files.size() > 1 and hits.is_empty(), "no UI script reads judgment (%d scripts checked; %s)" % [files.size(), str(hits)])
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var people := adults(w)
	j.set_ledger(people[0].id, ME, 0, 5000)
	var ins := j.inspect(people[0].id, ME)
	check(ins.has("net") and ins.has("permanent") and ins.has("memories"), "the developer inspector still gives the numbers and the reasons")
	w.dispose()


## Q06 in the live world: liking is still the existing Relations regard (no second friendship system); trust (X19-REGARD) starts as a first impression of it.
func test_q06_live_trust() -> void:
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var people := adults(w)
	var a: NPC = people[0]
	var b: NPC = people[1]
	var c: NPC = people[2]
	w.relations.tie(a.id, b.id).regard = 80.0
	check(j.social.regard(a.id, b.id) == 80 and j.social.regard(a.id, c.id) == 0, "the adapter reads Relations' regard (80 for a friend, 0 for a stranger)")
	check(j.credibility(a.id, b.id) == 600 and j.credibility(a.id, c.id) == 500, "so a liked teller starts a little more trusted (first impression, X19-REGARD: 0.6) than a stranger (0.5)")
	w.dispose()


## Q14 befriend (Relations._befriend_if_close): judgment holds back a friendship that is only just close enough; great
## closeness outweighs a dislike; with neutral judgment the live rule stands; never friends below the live threshold.
func test_q14_befriend() -> void:
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var people := adults(w)
	var a: NPC = people[3]
	var b: NPC = people[4]
	var at := float(Relations.cfg().befriend_at)
	check(JudgmentLive.befriend_ok(w, a.id, b.id, at + 5.0), "neutral judgment: close enough is enough (the live rule)")
	j.set_ledger(a.id, b.id, 0, 40000)
	check(not JudgmentLive.befriend_ok(w, a.id, b.id, at + 5.0), "a strong dislike (-40) holds back a friendship that is only just close enough")
	check(JudgmentLive.befriend_ok(w, a.id, b.id, 90.0), "...but great closeness (regard 90) outweighs it")
	var t := w.relations.tie(a.id, b.id)
	t.regard = at + 5.0
	w.relations._befriend_if_close(a.id, b.id, t)
	check(not w.relations.friends(a.id, b.id), "through the live hook: they do not become friends yet")
	t.regard = 90.0
	w.relations._befriend_if_close(a.id, b.id, t)
	check(w.relations.friends(a.id, b.id), "through the live hook: with time together they do")
	j.set_ledger(a.id, people[5].id, 900000, 0)
	var t2 := w.relations.tie(a.id, people[5].id)
	t2.regard = at - 1.0
	w.relations._befriend_if_close(a.id, people[5].id, t2)
	check(not w.relations.friends(a.id, people[5].id), "a high opinion never makes friends of people not yet close enough")
	w.dispose()


## Q14 court_choice (Relations._villagers_court): whom a single villager takes an interest in.
func test_q14_court() -> void:
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var people := adults(w)
	var n: NPC = people[0]
	var o1: NPC = people[1]
	var o2: NPC = people[2]
	check(JudgmentLive.pick_court(w, n, [o1, o2], {o1.id: 50.0, o2.id: 45.0}) == o1, "neutral judgment: the most attractive (the live rule)")
	j.set_ledger(n.id, o1.id, 0, 40000)
	check(JudgmentLive.pick_court(w, n, [o1, o2], {o1.id: 50.0, o2.id: 45.0}) == o2, "a strong dislike of the slightly more attractive one turns the interest to the other")
	check(JudgmentLive.pick_court(w, n, [o1, o2], {o1.id: 90.0, o2.id: 40.0}) == o1, "...but much greater attraction outweighs the dislike")
	check(JudgmentLive.pick_court(w, n, [], {}) == null, "no candidate the live rule allows: no interest (judgment never adds one)")
	w.dispose()


## Q14 trade_buy_from (NPCBrain._seller_of): whom a household buys timber from.
func test_q14_buy_from() -> void:
	var w := new_world()
	var sellers := []
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and (o.job == "carpenter" or w.brain.buy_role(o) == "merchant_raw"):
			sellers.append(o)
	var buyer: NPC = null
	for o: NPC in adults(w):
		if not sellers.has(o):
			buyer = o
			break
	if sellers.size() < 2 or buyer == null:
		print("note: fewer than two timber sellers in this village")
		w.dispose()
		return
	for o: NPC in w.npcs:
		o.inv.remove("log", o.inv.count("log"))
	sellers[0].inv.add("log", 5)
	sellers[1].inv.add("log", 5)
	var live: NPC = w.brain._seller_of("log", buyer)
	var j := JudgmentLive.attach(w)
	check(w.brain._seller_of("log", buyer) == live, "neutral judgment: the live rule's seller (%s)" % live.name)
	j.set_ledger(buyer.id, live.id, 0, 60000)
	var other: NPC = w.brain._seller_of("log", buyer)
	check(other != live and other.inv.has("log"), "a strong dislike sends the buyer to the other seller who has logs")
	var none_left: NPC = other
	none_left.inv.remove("log", none_left.inv.count("log"))
	check(w.brain._seller_of("log", buyer) == live, "the only seller left is used despite the dislike: need outweighs it")
	live.inv.remove("log", live.inv.count("log"))
	j.set_ledger(buyer.id, live.id, 900000, 0)
	check(w.brain._seller_of("log", buyer) == null, "no seller with logs: no purchase, however well liked (feasibility)")
	w.dispose()


## Q14 hire_choice and work_accept (Construction._keep_building, Construction.hire, Business.hire).
func test_q14_hiring() -> void:
	var w := new_world()
	var j := JudgmentLive.attach(w)
	var wage := int(GameData.b("helper_wage"))
	var worker: NPC = adults(w)[0]
	worker.coins = 200
	check(JudgmentLive.work_refusal(w, worker, ME, wage) == "", "neutral judgment: work is taken (the live rule)")
	j.set_ledger(worker.id, ME, 0, 40000)
	var why := JudgmentLive.work_refusal(w, worker, ME, wage)
	check(why != "" and not why.contains("-") and not why.contains("0"), "a villager with coin to spare who strongly dislikes the employer turns the work down, in words not numbers (\"%s\")" % why)
	worker.coins = 0
	check(JudgmentLive.work_refusal(w, worker, ME, wage) == "", "...the same villager with no coin takes it: need outweighs the dislike")
	worker.coins = 200
	j.set_ledger(worker.id, ME, 0, 0)
	check(JudgmentLive.work_refusal(w, worker, ME, 0) == "", "an unpaid favour is still done by someone neutral (the live rule)")
	# a household choosing a helper
	var h := -1
	for i in w.households.size():
		if w.construction.responsible_adult(i) != null:
			h = i
			break
	var hirable := []
	for o: NPC in w.npcs:
		if o.household != h and w.construction.can_hire(o) == "":
			hirable.append(o)
	if h < 0 or hirable.size() < 2:
		print("note: not enough hirable villagers here (%d)" % hirable.size())
		w.dispose()
		return
	var boss: NPC = w.construction.responsible_adult(h)
	check(JudgmentLive.pick_helper(w, h, wage) == hirable[0], "neutral judgment: the live rule's helper (the first hirable)")
	j.set_ledger(boss.id, hirable[0].id, 0, 60000)
	var second: NPC = JudgmentLive.pick_helper(w, h, wage)
	check(second != hirable[0] and w.construction.can_hire(second) == "", "the household's head, disliking the first, hires another who can be hired")
	for o in hirable:
		j.set_ledger(boss.id, o.id, 0, 60000)
	check(w.construction.can_hire(JudgmentLive.pick_helper(w, h, wage)) == "", "disliking everyone, they still hire: the work must be done")
	hirable[0].coins = 300
	j.set_ledger(hirable[0].id, boss.id, 0, 40000)
	for o in hirable:
		j.set_ledger(boss.id, o.id, 0, 0)
	check(JudgmentLive.pick_helper(w, h, wage) != hirable[0], "someone who would turn the work down is not hired")
	w.dispose()


# ---------------------------------------------------------------- the event feeds (PROS-19, SJD-Q12) ----------------
## The latest event of `type` in the store (as j.fact says it), or {}.
func last_fact(j: JudgmentStore, type: String) -> Dictionary:
	var best := {}
	for ev in j.facts:
		var f := j.fact(int(ev))
		if str(f.type) == type and (best.is_empty() or int(f.id) > int(best.id)):
			best = f
	return best


func count_of(j: JudgmentStore, type: String) -> int:
	var k := 0
	for ev in j.facts:
		if str(j.fact(int(ev)).type) == type:
			k += 1
	return k


## Each live act that now feeds the store reaches it with the right people; trivia stays out; the same act twice in two
## worlds gives the same state. Acts with no live source are listed in docs/expansion19/DESIGN.md section 9.3.
func test_event_feeds() -> void:
	var hashes := []
	for run in 2:
		var w := new_world(5)
		var j := JudgmentLive.attach(w)
		var people := adults(w)
		var a: NPC = people[0]
		var b: NPC = people[1]
		var onlooker: NPC = people[2]
		var far: NPC = people[-1]
		w.player.pos = a.pos
		for o in [b, onlooker]:
			o.pos = a.pos + Vector2(1, 0)
			o.anim = "idle"
		far.pos = a.pos + Vector2(200, 0)
		var n0: int = j.facts.size()
		# gift: the first one that earns regard; a second the same day and a non-gift are trivia
		w.player.inv.add("bread", 3)
		w.player.inv.add("rotten_apple", 1)
		w.relations.give(ME, a, "bread")
		var g := last_fact(j, "gift")
		check(not g.is_empty() and g.actors[0][0] == ME and g.beneficiaries == [a.id] and int(g.value) == GameData.value("bread"), "a gift is a gift event: giver the actor, receiver the beneficiary, worth in coins")
		check(str(j.belief(a.id, int(g.id)).src) == "participant" and str(j.belief(onlooker.id, int(g.id)).src) == "witnessed" and j.belief(far.id, int(g.id)).is_empty(), "...the receiver is a participant, a bystander sees it, someone far away does not")
		w.relations.give(ME, a, "bread")
		w.relations.give(ME, a, "rotten_apple")
		check(count_of(j, "gift") == 1, "a second gift the same day and a rotten apple are trivia: no more events")
		# help: a quest done is a kindness; a paid hire is not
		var smith: NPC = null
		for n: NPC in w.npcs:
			if n.job == "smith":
				smith = n
		if smith != null:
			smith.coins = 200
			smith.inv.remove("iron_ore", smith.inv.count("iron_ore"))
			w.quests.offers[smith.id] = "ore_for_the_forge"
			var q: Dictionary = w.quests.accept(smith)
			var need: Dictionary = Quests.template("ore_for_the_forge").need
			for id in need:
				w.player.inv.add(id, int(need[id]))
			w.quests.complete(q)
			var h := last_fact(j, "help_minor")
			check(not h.is_empty() and h.actors[0][0] == ME and h.beneficiaries == [smith.id], "a quest done is a help_minor event: the player the actor, the giver the beneficiary")
		# help_build: relatives' money toward a home
		JudgmentLive.on_help(w, b.id, a, "help_build", 40)
		var hb := last_fact(j, "help_build")
		check(not hb.is_empty() and hb.actors[0][0] == b.id and hb.beneficiaries == [a.id] and int(hb.value) == 40, "a relative's help toward a home is help_build (family help, Construction)")
		# rescue: someone digs another out of a cave-in; digging yourself out is no rescue
		var cell := Vector2i(3, 3)
		w.mine_works.trapped[World.npc_ref(a.id)] = MineWorks.key(0, cell)
		w.mine_works.trapped[World.PLAYER] = MineWorks.key(1, cell)
		w.mine_works._free_trapped(0, cell, w.player)
		var r := last_fact(j, "rescue")
		check(not r.is_empty() and r.actors[0][0] == ME and r.beneficiaries == [a.id], "freeing a trapped villager is a rescue: the digger the actor, the freed the beneficiary")
		w.mine_works._free_trapped(1, cell, w.player)
		check(count_of(j, "rescue") == 1, "...the player digging themself out is not")
		var crowd: NPC = b
		w.player.pos = a.pos
		w.relations.defended(a.pos)
		var df := last_fact(j, "rescue")
		check(int(df.id) > int(r.id) and df.actors[0][0] == ME and df.beneficiaries.has(a.id) and df.beneficiaries.has(b.id) and not df.beneficiaries.has(far.id), "putting down a bandit or beast among villagers is a rescue of those near (not those far off)")
		check(str(j.belief(crowd.id, int(df.id)).src) == "participant", "...and they know who did it")
		# contracts and debts: a promise kept is a fair deal, a promise broken a cheat
		var seller_ref := World.npc_ref(a.id)
		var buyer_ref := World.npc_ref(b.id)
		var c: Dictionary = w.contracts._new_record(buyer_ref, seller_ref, "bread", 2, 3, 5, [])
		c.state = "accepted"
		c.reserved = 6
		w.contracts._pay_units(c, 2)
		var tf := last_fact(j, "trade_fair")
		check(not tf.is_empty() and tf.actors[0][0] == a.id and tf.beneficiaries == [b.id] and int(tf.value) == 6, "a contract fulfilled is trade_fair: the seller the actor, the buyer the beneficiary, coins paid")
		check(j.trust_of(b.id, a.id) > 0, "...and the buyer now trusts the seller more (X19-REGARD)")
		var c2: Dictionary = w.contracts._new_record(buyer_ref, seller_ref, "bread", 4, 3, 1, [])
		c2.state = "accepted"
		c2.reserved = 12
		w.contracts._lapse(c2)
		var tc := last_fact(j, "trade_cheat")
		check(not tc.is_empty() and tc.actors[0][0] == a.id and tc.victims == [b.id] and int(tc.value) == 12, "a contract let lapse is trade_cheat: the seller the actor, the buyer the victim, the coins' worth undelivered")
		var d := {"id": 900, "creditor": seller_ref, "debtor": buyer_ref, "item": "bread", "qty": 1, "value": 7, "made": 0, "due": 0, "state": "open", "ended": -1}
		w.credit.debts.append(d)
		b.coins = 100
		check(w.credit.repay(900, true), "(a debt is repaid)")
		var tf2 := last_fact(j, "trade_fair")
		check(int(tf2.id) > int(tf.id) and tf2.actors[0][0] == b.id and tf2.beneficiaries == [a.id] and int(tf2.value) == 7, "a debt repaid on time is trade_fair: the debtor the actor")
		var d2 := {"id": 901, "creditor": seller_ref, "debtor": buyer_ref, "item": "bread", "qty": 1, "value": 9, "made": 0, "due": 0, "state": "open", "ended": -1}
		w.credit.debts.append(d2)
		w.credit._default(d2)
		var tc2 := last_fact(j, "trade_cheat")
		check(int(tc2.id) > int(tc.id) and tc2.actors[0][0] == b.id and tc2.victims == [a.id] and int(tc2.value) == 9, "a debt not repaid is trade_cheat: the debtor the actor, the creditor the victim")
		# the player in a deal: no deal with a party who is not a person
		var before: int = j.facts.size()
		JudgmentLive.on_deal(w, "trade_fair", -1, a.id, 10)
		check(j.facts.size() == before, "a party that is not a person (a household) publishes nothing")
		# an unseen pickpocket is a fact nobody learns
		var vic: NPC = onlooker
		vic.coins = 50
		w.player.pos = vic.pos
		var got := false
		for i in 60:
			var res := w.pickpocket(vic)
			if bool(res.get("ok", false)) and str(res.get("what", "")) != "":
				got = true
				break
		if got:
			var pp := last_fact(j, "pickpocket")
			check(not pp.is_empty() and pp.victims == [vic.id] and int(pp.value) > 0, "an unseen pickpocket is published as a fact (the victim knows only that something is missing)")
		# a bandit's robbery: theft by an NPC, seen as the attack is
		var bandit: NPC = a
		var aware := w.aware_of_attack(far.pos, b)
		aware.seen = [onlooker]
		JudgmentLive.on_robbery(w, bandit, b, 25, aware)
		var th := last_fact(j, "theft")
		check(not th.is_empty() and th.actors[0][0] == bandit.id and th.victims == [b.id] and int(th.value) == 25, "a robbery is a theft by the robber (a villager's theft, not only the player's)")
		check(str(j.belief(onlooker.id, int(th.id)).src) == "witnessed" and str(j.belief(b.id, int(th.id)).src) == "participant", "...the victim and those who saw it know")
		# a villager kills a villager
		JudgmentLive.on_killing(w, b, a.id)
		var k := last_fact(j, "killing")
		check(not k.is_empty() and k.actors[0][0] == a.id and k.victims == [b.id], "a villager's killing is the same killing event as the player's")
		# a partnership: a neutral fact for the two
		var single: NPC = null
		for n in adults(w):
			if n != a and n.partner == -1 and Life.partner_refusal(w, n) == "":
				single = n
				break
		if single != null:
			var net0: int = j.net(single.id, ME)
			Life.partner_player(w, single)
			JudgmentLive.on_marriage(w, ME, single.id)
			var m := last_fact(j, "marriage")
			check(not m.is_empty() and j.net(single.id, ME) == net0 and not j.belief(single.id, int(m.id)).is_empty(), "a marriage is a recorded neutral fact for the two of them, and means nothing morally (Q01)")
		hashes.append(j.state_hash())
		check(j.facts.size() > n0, "(events were published)")
		w.dispose()
	check(hashes[0] == hashes[1], "the same acts in two worlds give the same judgment state")
