extends SceneTree
## SJD-G (Gate G, full soak and calibration): the save-migration and long-horizon checks of the judgment store, and the
## shortcut fix found by the soak.
##   1. Every committed save fixture with a judgment section (Build 19's save 20, Build 20's 21, Build 21's 21 guest and 22
##      couple, Build 22's 23, and Build 24's 23 with a full section: tests/fixtures/b24_save_v23_judgment.json, written by
##      gen_b24_judgment_fixture.gd with Build 24's judgment and world code) loads with its judgment state intact: every
##      fact, memory, contribution, ledger entry and trust value comes back as saved, nothing kept unread, and a Build 24
##      section re-saves byte for byte.
##   2. After loading, the approved fading (SJD-Q02, X19-DECAY) and permanence (Q02/Q11, X19-ASSAULT) hold over long horizons:
##      lifetime totals never change, permanent parts never fade, fading parts follow the store's own integer steps, nothing
##      goes negative, permanent memories stay.
##   3. JudgmentSoak.metrics changes nothing (state hash and saved section identical before and after).
##   4. The trade shortcut under the shipped "margin" selection chooses exactly as the full scan, also where a NET beyond
##      +-50 points meets a family-name colour (the double clamp of JudgmentWeighting._choose).
##   godot --headless --path game --script res://tests/judgment_soak_test.gd

var failures := 0
var checks := 0

const FIXTURES := ["b19_save_v20_seed3.json", "b20_save_v21_single.json", "mp_save_v21_guest.json", "mp_save_v22_couple.json",
	"b22_save_v23_single.json", "b24_save_v23_judgment.json"]


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	for f in FIXTURES:
		test_fixture(f)
	test_long_horizon()
	test_metrics_read_only()
	test_margin_shortcut()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _load(name: String) -> Array:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/" + name))
	var w := World.new()
	w.load_dict(VillageMap.load_default(), d)
	return [w, d]


## Rows of a saved section's list, as text (the order is the store's own sorted order).
static func _rows(sec: Dictionary, key: String, width := -1) -> Array:
	var out := []
	for r in sec.get(key, []):
		out.append(JSON.stringify(r if width < 0 else (r as Array).slice(0, width)))
	return out


func test_fixture(name: String) -> void:
	var lw := _load(name)
	var w: World = lw[0]
	var saved: Dictionary = lw[1].judgment
	check(w.judgment != null and w.judgment.unread.is_empty(), "%s: the judgment section (version %d) loads, nothing kept unread" % [name, int(saved.version)])
	var back: Dictionary = JSON.parse_string(JSON.stringify(w.judgment.to_dict()))     # numbers as the saved file has them
	for key in ["memories", "contrib", "ledgers"]:
		check(_rows(back, key) == _rows(saved, key), "%s: every %s row comes back as saved (%d)" % [name, key, (saved.get(key, []) as Array).size()])
	check(_rows(back, "facts", 10) == _rows(saved, "facts", 10), "%s: every fact comes back as saved (%d)" % [name, (saved.facts as Array).size()])
	if saved.has("trust"):
		check(JSON.stringify(back.trust) == JSON.stringify(saved.trust), "%s: trust as saved" % name)
	for l in saved.ledgers:
		var o := int(l[0])
		var s := int(l[1])
		if w.judgment.net(o, s) != int(l[5]) + int(l[7]) - int(l[6]) - int(l[8]):
			check(false, "%s: NET of %d about %d as saved" % [name, o, s])
			break
	if int(saved.version) == 3:
		var again := World.new()
		again.load_dict(VillageMap.load_default(), lw[1])
		var w2 := World.new()
		var d2 := again.to_dict()
		w2.load_dict(VillageMap.load_default(), d2)
		check(JSON.stringify(w2.to_dict().judgment) == JSON.stringify(d2.judgment), "%s: a Build 24 section re-saves byte for byte after a second load" % name)
		check(int(back.version) == 3, "%s: re-saved as version 3 (aspirations off: no aspire key)" % name)
		again.dispose()
		w2.dispose()
	w.dispose()


## The Build 24 fixture's store carried far ahead: fading by the approved rate, permanence, lifetime totals.
func test_long_horizon() -> void:
	var lw := _load("b24_save_v23_judgment.json")
	var w: World = lw[0]
	var j: JudgmentStore = w.judgment
	var before := {}
	var perm_mem := 0
	for o in j.memories:
		for ev in j.memories[o]:
			perm_mem += 1 if ((j.memories[o][ev] as PackedInt64Array)[JudgmentStore.M_FLAGS] & 1) == 1 else 0
	for o in j.ledgers:
		for s in j.subjects(int(o)):
			before[[int(o), int(s)]] = j.ledger(int(o), int(s))
	var perm_entries := 0
	var fading_entries := 0
	for k in before:
		perm_entries += 1 if int(before[k][5]) + int(before[k][6]) > 0 else 0
		fading_entries += 1 if int(before[k][3]) + int(before[k][4]) > 0 else 0
	check(perm_entries > 0 and fading_entries > 0 and perm_mem > 0, "the Build 24 fixture holds fading and permanent judgments (%d, %d) and permanent memories (%d)" % [fading_entries, perm_entries, perm_mem])
	var d0 := j.day
	var half := int(j.c("decay").get("half_life_days", 16))
	for step in [half, 365]:
		j.advance_day(d0 + step)
		var ok_life := true
		var ok_perm := true
		var ok_fade := true
		var ok_sign := true
		for k in before:
			var b: Array = before[k]
			var a: Array = j.ledger(int(k[0]), int(k[1]))
			ok_life = ok_life and a[0] == b[0] and a[1] == b[1] and a[2] == b[2]
			ok_perm = ok_perm and a[5] == b[5] and a[6] == b[6]
			for p in [3, 4]:
				var v := int(b[p])
				for i in step:
					v -= j._decay_step(v)
				ok_fade = ok_fade and int(a[p]) == v
			for p in 7:
				ok_sign = ok_sign and int(a[p]) >= 0
		check(ok_life, "day +%d: lifetime GOOD, BAD and the contribution count never change (spec s.5.2: lifetime totals preserved)" % step)
		check(ok_perm, "day +%d: permanent (murder, assault) parts never fade (SJD-Q02, X19-ASSAULT)" % step)
		check(ok_fade, "day +%d: fading parts follow the approved integer steps (X19-DECAY %d permille a day)" % [step, int(j.c("decay").ordinary_permille_per_day)])
		check(ok_sign, "day +%d: no ledger value below 0 (spec s.5.1)" % step)
	var left := 0
	for o in j.ledgers:
		for s in j.subjects(int(o)):
			var a: Array = j.ledger(int(o), int(s))
			left += 1 if int(a[3]) + int(a[4]) > 0 else 0
	check(left == 0, "a game year later (365 days, 45 game years) every ordinary judgment has faded to 0 (%d left): a calibration observation for SJD-H" % left)
	var perm_after := 0
	for o in j.memories:
		for ev in j.memories[o]:
			perm_after += 1 if ((j.memories[o][ev] as PackedInt64Array)[JudgmentStore.M_FLAGS] & 1) == 1 else 0
	check(perm_after == perm_mem, "permanent memories all kept (%d of %d)" % [perm_after, perm_mem])
	w.dispose()


func test_metrics_read_only() -> void:
	var lw := _load("b24_save_v23_judgment.json")
	var w: World = lw[0]
	var j: JudgmentStore = w.judgment
	for i in 240:                         # two game hours: queued and scheduled meetings, a dawn under way
		w.update(0.5)
	j.begin_day(j.day + 3)                # a dawn queued, not applied: ledgers wait to be decayed
	var h0 := j.state_hash()
	var q0 := j.gossip_queued()
	var m := JudgmentSoak.metrics(j)
	check(j.state_hash() == h0 and j.gossip_queued() == q0 and j.pending(int(j._queue[0]) if not j._queue.is_empty() else 0) == not j._queue.is_empty(),
		"JudgmentSoak.metrics changes nothing: same state hash, same queued meetings, the dawn still pending")
	check(int(m.n.ledger_entries) > 0 and m.net.has("p50") and int(m.subj.n) > 0, "...and reports the ledgers (%d entries, NET p50 %d)" % [int(m.n.ledger_entries), int(m.net.p50)])
	var mine := 0
	for o in j.ledgers:
		for s in j.subjects(int(o)):
			if j.net(int(o), int(s)) <= -10000 or j.net(int(o), int(s)) >= 10000:
				mine += 1
	check(int(m.net.abs_ge_10_25_50[0]) == mine, "its decayed-on-a-copy NET counts agree with the store's own reads (%d at 10 points or more)" % mine)
	w.dispose()


## The shipped "margin" selection: the shortcut picks exactly as the full scan, with saturated opinions and a family colour.
func test_margin_shortcut() -> void:
	JudgmentLive.test_disabled = false
	var w := World.new()
	w.setup(VillageMap.load_default(), 3)
	var j: JudgmentStore = w.judgment
	check(str(j.cfg.decision.selection) == "margin", "the shipped selection is margin (SJD-Q09)")
	var seller: NPC = null
	var all := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.job != "miner" and not (j.pers.active and j.pers.holds_stubbornness(n.id)):
			n.inv.add("iron_ore", 3)
			var cand := []
			for outlet in NPCBrain.OUTLETS.iron_ore:
				for b in w.brain._with_buy_role(outlet):
					if b != n and b.alive and w.purchase_qty(b, n, "iron_ore", 3) > 0 and not cand.has(b):
						cand.append(b)
			if cand.size() >= 2:
				seller = n
				all = cand
				break
			n.inv.remove("iron_ore", 3)
	check(seller != null, "a seller with two or more possible iron buyers (%d)" % all.size())
	if seller == null:
		w.dispose()
		return
	var same := 0
	var tried := 0
	var taken0 := int(j.stats.get("trade_shortcut", 0))
	for k in 40:
		for x in j.subjects(seller.id):                # each mix starts from no opinion of anyone
			j.set_ledger(seller.id, int(x), 0, 0)
		for b in all:                                  # opinions from strong dislike (-90) to strong liking (+90): saturated dispositions
			var unit := 15000 if k % 2 == 0 else 300          # every other mix mild (opinions within 2 points): the shortcut applies
			var g: int = (k * 7919 + b.id * 31) % 7 * unit
			var bad: int = (k * 104729 + b.id * 17) % 7 * unit
			j.set_ledger(seller.id, b.id, g, bad)
		if k % 3 == 0:                                 # the family name: the seller's opinion of a buyer's kin colours the buyer
			for b in all:
				for r in j.bonds.reach(b.id):
					if int(r[0]) != seller.id and not all.has(w.npc(int(r[0]))):
						j.set_ledger(seller.id, int(r[0]), (k % 2) * 80000, (1 - k % 2) * 80000)
		JudgmentLive.shortcut = true
		var fast: NPC = w.brain._buyer_for(seller, "iron_ore")
		JudgmentLive.shortcut = false
		var full: NPC = w.brain._buyer_for(seller, "iron_ore")
		JudgmentLive.shortcut = true
		tried += 1
		same += 1 if fast == full else 0
	var taken := int(j.stats.get("trade_shortcut", 0)) - taken0
	check(same == tried, "margin: the shortcut picks exactly as the full scan (%d of %d opinion mixes)" % [same, tried])
	check(taken > 0 and taken < tried, "...taking the shortcut only where nobody else can come within the margin (%d of %d)" % [taken, tried])
	w.dispose()
