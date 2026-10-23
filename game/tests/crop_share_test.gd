extends SceneTree
## FARM-08-Q-CROP (owner, 2026-10-22, option B): a field's crop goes to the farmers who cut it, in proportion to their
## cutting work, whoever finishes first; equal work equal shares, no work no share; the seed kept back and the pen's
## feed come first as before; indivisible units by largest remainder, ties to the smaller id; nothing made or lost.
## Run headless:
##   godot --headless --path game --script res://tests/crop_share_test.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL ", what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	_test_split()
	_test_harvest()
	_test_seed_share()
	_test_rate_share()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_split() -> void:
	check(Farming.split_crop(10, {3: 1.0, 1: 1.0, 2: 1.0}) == {1: 4, 2: 3, 3: 3}, "10 among three equal cutters: 4/3/3, the odd unit to the smallest id")
	check(Farming.split_crop(9, {5: 90.0, 9: 45.0}) == {5: 6, 9: 3}, "twice the work, twice the share")
	check(Farming.split_crop(7, {4: 0.0, 2: 30.0}) == {2: 7}, "no work, no share")
	check(Farming.split_crop(0, {1: 1.0}).is_empty() and Farming.split_crop(5, {}).is_empty(), "nothing to share: nothing shared")
	var ok := true
	var r := RandomNumberGenerator.new()
	r.seed = 7
	for k in 200:
		var sh := {}
		for i in r.randi_range(1, 5):
			sh[r.randi_range(1, 40)] = r.randf_range(0.5, 120.0)
		var t := r.randi_range(0, 500)
		var out := Farming.split_crop(t, sh)
		var sum := 0
		for id in out:
			sum += int(out[id])
		if (t > 0 and sum != t) or Farming.split_crop(t, sh) != out:
			ok = false
	check(ok, "200 random splits: the parts always add up to the whole, and the same input gives the same split")


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


## A ripe field with farmers a and b of it cutting: a's cutting ends now; b has worked `b_worked` of 90 minutes.
func _setup(w: World, b_worked: float, crop: int) -> Array:
	var f: Dictionary = w.fields[0]
	var farmers: Array = w.npcs.filter(func(n): return n.alive and n.job == "farmer")
	var a: NPC = farmers[0]
	var b: NPC = farmers[1]
	a.workplace = str(f.id)
	b.workplace = str(f.id)
	for o: NPC in w.field_workers(f):
		if o != a and o != b:
			o.workplace = str(w.fields[1].id)
	for pid in w.fauna.pens:
		w.fauna.pens[pid].trough = 100000            # no pen needs feed here (the feed case sets its own)
	f.state = "ripe"
	f.crop = crop
	f.ripe_at = -1.0e9
	for n: NPC in [a, b]:
		n.inv.remove("wheat", n.inv.count("wheat"))
		n.inv.remove("wheat_seed", n.inv.count("wheat_seed"))
		n.plan = [w.brain.work(90.0, "harvest", {"field": f.id, "min": 90.0}, "work")]
		n.work_left = 90.0
	b.work_left = 90.0 - b_worked
	return [f, a, b]


func _wheat(w: World, ns: Array) -> int:
	var t := 0
	var hhs := {}
	for n: NPC in ns:
		t += n.inv.count("wheat") + n.inv.count("wheat_seed")
		hhs[n.household] = true
	for h in hhs:
		if int(h) >= 0:
			t += w.households[int(h)].pantry.count("wheat")
	return t


func _test_harvest() -> void:
	# equal work: equal grain, whoever finishes first
	var grain := []
	for first in ["a", "b"]:
		var w := _world()
		var s := _setup(w, 90.0, 101)
		var f: Dictionary = s[0]
		var a: NPC = s[1]
		var b: NPC = s[2]
		var before := _wheat(w, [a, b])
		var fin: NPC = a if first == "a" else b
		var other: NPC = b if first == "a" else a
		other.work_left = 0.0          # both worked the full 90 minutes
		check(w.brain.act(fin, "harvest", {"field": f.id, "min": 90.0}), "the cutting completes (%s first)" % first)
		check(_wheat(w, [a, b]) - before == 101, "all 101 units are in the cutters' hands, pantries and seed: none made or lost (%s first)" % first)
		check(f.state == "tilled" and not w.brain.act(other, "harvest", {"field": f.id, "min": 90.0}), "the field is cut once; the other cutter's step finds nothing more")
		var seed := fin.inv.count("wheat_seed")
		var ga: int = a.inv.count("wheat") + (w.households[a.household].pantry.count("wheat") if a.household >= 0 else 0)
		var gb: int = b.inv.count("wheat") + (w.households[b.household].pantry.count("wheat") if b.household >= 0 else 0)
		grain.append([ga, gb, seed])
	check(grain[0][2] == grain[1][2] and absi(grain[0][0] - grain[0][1]) <= 1 and grain[0][0] + grain[0][1] == grain[1][0] + grain[1][1],
		"equal work gives equal grain (within the one odd unit) and the same total whoever finishes first: %s" % str(grain))
	# unequal work: a full cutting against half of one
	var w2 := _world()
	var s2 := _setup(w2, 45.0, 100)
	var a2: NPC = s2[1]
	var b2: NPC = s2[2]
	var before2 := _wheat(w2, [a2, b2])
	check(w2.brain.act(a2, "harvest", {"field": s2[0].id, "min": 90.0}), "a finishes; b has cut 45 of 90 minutes")
	var seed2 := a2.inv.count("wheat_seed")
	var expect := Farming.split_crop(100 - seed2, {a2.id: 90.0, b2.id: 45.0})
	check(_wheat(w2, [a2, b2]) - before2 == 100, "the whole crop is accounted for")
	check(int(expect[a2.id]) + int(expect[b2.id]) == 100 - seed2 and int(expect[a2.id]) >= 2 * int(expect[b2.id]) - 1, "twice the work, about twice the grain: %s" % str(expect))
	check(b2.plan.is_empty(), "b's cutting ends with the field cut (share in hand)")
	# no cutting work, no share
	var w3 := _world()
	var s3 := _setup(w3, 0.0, 60)
	var b3: NPC = s3[2]
	b3.plan = [w3.brain.go(b3.cell())]      # on the way, not cutting
	check(w3.brain.act(s3[1], "harvest", {"field": s3[0].id, "min": 90.0}) and b3.inv.count("wheat") == 0, "a farmer of the field not cutting at the time gets no share")
	# the pen's feed comes first
	var w4 := _world()
	var s4 := _setup(w4, 90.0, 80)
	var f4: Dictionary = s4[0]
	var a4: NPC = s4[1]
	var b4: NPC = s4[2]
	b4.work_left = 0.0
	var pen: Dictionary = {}
	for pid in w4.fauna.pens:
		var k := w4.pen_keeper(w4.fauna.pens[pid])
		if k != null and w4.fauna.daily_need(w4.fauna.pens[pid]) > 0:
			pen = w4.fauna.pens[pid]
			k.workplace = str(f4.id)
			if k != a4 and k != b4:
				k.plan = []
			break
	if pen.is_empty():
		check(false, "a pen with a keeper and a need")
		return
	pen.trough = 0
	var need := w4.fauna.daily_need(pen) * 4
	check(w4.brain.act(a4, "harvest", {"field": f4.id, "min": 90.0}), "the cutting completes with a hungry pen on the field")
	var feed_step := a4.plan.filter(func(st): return st.k == "work" and str(st.get("act", "")) == "feed_pen")
	check(feed_step.size() == 1 and int(feed_step[0].args.qty) == need, "the finisher carries %d feed to the pen first, as before" % need)


func _grain(w: World, n: NPC) -> int:
	return n.inv.count("wheat") + (w.households[n.household].pantry.count("wheat") if n.household >= 0 else 0)


## FARM-CROP-SEED (owner, 2026-10-23): the seed kept back is split by work like the grain; nothing made or lost.
func _test_seed_share() -> void:
	# the earlier model: seed_keep (2) of the crop, equal work: one seed each
	var w := _world()
	var s := _setup(w, 90.0, 101)
	var a: NPC = s[1]
	var b: NPC = s[2]
	b.work_left = 0.0
	var before := _wheat(w, [a, b])
	check(w.brain.act(a, "harvest", {"field": s[0].id, "min": 90.0}) and a.inv.count("wheat_seed") == 1 and b.inv.count("wheat_seed") == 1,
		"equal work: the 2 seed kept back are shared one each, not both to the cutter who finishes")
	check(_wheat(w, [a, b]) - before == 101, "seed and grain together are the whole crop: none made or lost")
	# twice the work: the larger share first (largest remainder, ties to the smaller id)
	var w2 := _world()
	var s2 := _setup(w2, 45.0, 100)
	var a2: NPC = s2[1]
	var b2: NPC = s2[2]
	w2.brain.act(a2, "harvest", {"field": s2[0].id, "min": 90.0})
	var seeds2 := a2.inv.count("wheat_seed") + b2.inv.count("wheat_seed")
	check(seeds2 == 2 and a2.inv.count("wheat_seed") == Farming.split_crop(2, {a2.id: 90.0, b2.id: 45.0})[a2.id], "twice the work, the seed follows the work: %d and %d" % [a2.inv.count("wheat_seed"), b2.inv.count("wheat_seed")])
	# a cutter whose seed store is full keeps the whole share as grain (as the finisher always did)
	var w3 := _world()
	var s3 := _setup(w3, 90.0, 101)
	var a3: NPC = s3[1]
	var b3: NPC = s3[2]
	b3.work_left = 0.0
	a3.inv.add("wheat_seed", int(Farming.seed_cfg().seed_cap))
	var before3 := _wheat(w3, [a3, b3])
	w3.brain.act(a3, "harvest", {"field": s3[0].id, "min": 90.0})
	check(a3.inv.count("wheat_seed") == int(Farming.seed_cfg().seed_cap) and _wheat(w3, [a3, b3]) - before3 == 101, "a full seed store keeps its share as grain; the total is unchanged")
	# the shared-manor model: seeds_back a sown cell, split by work
	GameData.balance["shared_manor_farming"] = 1
	var w4 := _world()
	var s4 := _setup(w4, 90.0, 101)
	var a4: NPC = s4[1]
	var b4: NPC = s4[2]
	b4.work_left = 0.0
	s4[0].sown = 7
	w4.brain.act(a4, "harvest", {"field": s4[0].id, "min": 90.0})
	check(a4.inv.count("wheat_seed") + b4.inv.count("wheat_seed") == 7 and absi(a4.inv.count("wheat_seed") - b4.inv.count("wheat_seed")) == 1,
		"shared model: 7 seed back are split 4 and 3 by equal work (%d, %d)" % [a4.inv.count("wheat_seed"), b4.inv.count("wheat_seed")])
	GameData.balance["shared_manor_farming"] = 0


## Owner D7 (2026-10-23): shares are minutes x the cutter's own work rate (base-minute equivalents).
func _test_rate_share() -> void:
	var w := _world()
	var s := _setup(w, 88.0, 100)
	var a: NPC = s[1]
	var b: NPC = s[2]
	w.experience.credit(World.npc_ref(a.id), "farming", 18.0 * 480.0, 0.0)          # a: level 10, 10% faster
	var rate := CapabilityHook.rate("farming", a)
	check(absf(rate - 1.1) < 1e-6, "a, at farming level 10, works at rate 1.1")
	b.inv.remove("wheat_seed", b.inv.count("wheat_seed"))
	# a's cutting took 80 minutes at 1.1 = 88 base-minute equivalents; b has worked 88 of 90 at rate 1: equal ground cut
	var sh: Dictionary = w.brain._cutting_shares(a, s[0], 80.0)
	check(absf(float(sh[a.id]) - 88.0) < 1e-6 and absf(float(sh[b.id]) - 88.0 * CapabilityHook.rate("farming", b)) < 1e-6,
		"a's 80 minutes at rate 1.1 count as 88; b's 88 minutes at their rate count as %.1f" % float(sh[b.id]))
