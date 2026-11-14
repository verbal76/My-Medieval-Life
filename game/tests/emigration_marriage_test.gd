extends SceneTree
## B25-EMIG-MARRIAGE-D1 (owner 2026-11-12, docs/directives/2026-11-12_b25r2_owner_decisions.md, decision 1, option A): a married
## adult who leaves the village for work (Migration._work_out) takes their spouse along, as the land move does. If the spouse
## cannot relocate, nobody leaves alone: a permanent solo emigration must not free the spouse left behind to remarry
## (Life.free_to_partner frees a spouse whose partner is no longer alive in the village, and an emigrant counts as such). Temporary
## travel (a journey) does not dissolve a marriage. Checked:
##   1 a married adult without a trade leaves for work only with the spouse: both away in the same settlement, the pair kept
##   2 no villager is left behind with an emigrated spouse and free to court
##   3 a spouse who cannot relocate (an office-holder) keeps the couple in the village: nobody leaves alone
##   4 a living spouse on the road (alive, not away) still blocks courting
##   5 after a save and a load the couple is still away together and nobody is freed; the books balance
##   6 two identical runs make the same move (deterministic)
##   godot --headless --path game --script res://tests/emigration_marriage_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	GameData.ensure()
	Migration.walk = false            # REG-05 (B42): these decision-rule checks are of the move made at once (a world with no roads); the walk is reg05_household_walks_test
	var r1 := scenario(true)
	var r2 := scenario(false)
	check(r1 == r2 and str(r1) != "", "two identical runs make the same move (%s)" % str(r1))
	test_blocked_spouse()
	test_journey_keeps_marriage()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world(seed_ := 1) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed_)
	w.regions.step_day(w.day())
	return w


func _closed_market() -> Dictionary:
	var m := {}
	for j in ["manor_hand", "farmer", "woodcutter", "hunter", "miner", "prospector", "tailor", "barber", "preacher", "church_assistant"]:
		m[j] = {"pay": 9.0, "open": 0, "tool": "", "at": Vector2i.ZERO}
	return m


## A married couple (both movable adults) in an ordinary household; the husband or wife without a trade is the work mover. On day 0
## every couple still has young children at home (who keep parents from leaving, Life._may_move), so the couple's children are
## made grown first: the case of a couple whose children have grown up, or who have none.
func _couple(w: World) -> Array:
	for h in range(3, w.households.size()):
		if w.households[h].get("ended", false) or Migration._any_barred(w, w.brain._members(h)):
			continue
		var paired := false
		for o: NPC in w.brain._members(h):
			if o.role == "adult" and Life.has_partner(w, o) and w.npc(o.partner).household == h:
				paired = true
		if not paired:
			continue
		for o: NPC in w.brain._members(h):
			if o.role == "child":
				o.role = "adult"
				o.born -= 20.0 * float(Life.year_days()) * 1440.0
		break
	for h in range(3, w.households.size()):
		if w.households[h].get("ended", false):
			continue
		var ms: Array = w.brain._members(h)
		ms.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
		if Migration._any_barred(w, ms):
			continue
		for o: NPC in ms:
			if o.role == "adult" and Life.has_partner(w, o) and Life._may_move(w, o):
				var p := w.npc(o.partner)
				if p != null and p.household == h and Life._may_move(w, p):
					return [h, o, p]
	return []


func _left_behind_free(w: World) -> Array:
	var out := []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner >= 0:
			var o := w.npc(n.partner)
			if o != null and not o.alive and str(o.away) != "" and Life.free_to_partner(w, n):
				out.append("%s (partner %s away)" % [n.name, o.name])
	return out


func scenario(report: bool) -> String:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	s.biz.farm.rate = 12.0
	var c := _couple(w)
	if c.is_empty():
		check(false, "the fixture has a married couple of movable adults")
		return ""
	var h: int = c[0]
	var who: NPC = c[1]
	var sp: NPC = c[2]
	who.job = ""
	for o: NPC in w.brain._members(h):           # only this one is the work mover in the household
		if o != who and o.role == "adult" and o.job == "":
			o.job = "farmer"
	w.households[h].econ = {"streak": 3}
	who.job_since = w.day() - 10
	who.income_days = [0, 0, 0, 0, 0, 0, 0]       # B42-Q-EMIG-WORK: no job and nothing earned for a week (Migration.long_idle)
	var moved := Migration._work_out(w, s, _closed_market())
	var who_away := not who.alive and str(who.away) == "higham"
	var sp_away := not sp.alive and str(sp.away) == "higham"
	if report:
		check(moved and who_away and sp_away, "a married adult who leaves for work takes the spouse along (moved %s, mover away %s, spouse away %s)" % [moved, who_away, sp_away])
		var lb := _left_behind_free(w)
		check(lb.is_empty(), "nobody is left behind with an emigrated spouse and free to court (%s)" % str(lb))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	if report:
		var a := w2.npc(who.id)
		var b := w2.npc(sp.id)
		check(a != null and b != null and not a.alive and not b.alive and str(a.away) == str(b.away) and str(a.away) != "", "after a save and a load the couple is away together")
		check(_left_behind_free(w2).is_empty() and w2.regions.audit() == "", "and nobody in the village is freed; the settlements' books balance")
	return "%s|%s|%s|%s" % [moved, who.away, sp.away, w.regions.population()]


func test_blocked_spouse() -> void:
	var w := _world()
	var s: OffMapSettlement = w.regions.by_id["higham"]
	s.biz.farm.rate = 12.0
	var c := _couple(w)
	if c.is_empty():
		return
	var h: int = c[0]
	var who: NPC = c[1]
	var sp: NPC = c[2]
	who.job = ""
	for o: NPC in w.brain._members(h):
		if o != who and o.role == "adult" and o.job == "":
			o.job = "farmer"
	for hh in range(3, w.households.size()):     # only this household is short of work
		w.households[hh].econ = {"streak": 3 if hh == h else 0}
	who.job_since = w.day() - 10
	who.income_days = [0, 0, 0, 0, 0, 0, 0]       # B42-Q-EMIG-WORK: no job and nothing earned for a week (Migration.long_idle)
	w.reeve_id = sp.id                            # the spouse holds an office and cannot relocate
	var moved := Migration._work_out(w, s, _closed_market())
	check(not moved and who.alive and str(who.away) == "", "a spouse who cannot relocate keeps the couple in the village: nobody leaves alone (moved %s)" % moved)
	check(not Life.free_to_partner(w, sp) and not Life.free_to_partner(w, who), "and the marriage stands: neither is free to court")


func test_journey_keeps_marriage() -> void:
	var w := _world()
	var c := _couple(w)
	if c.is_empty():
		return
	var who: NPC = c[1]
	var sp: NPC = c[2]
	who.pos = Vector2(-50, -50)                   # out on the road (a journey keeps the traveller alive and not away)
	check(who.alive and str(who.away) == "" and not Life.free_to_partner(w, sp), "a living spouse on the road still blocks courting: travel does not dissolve a marriage")
