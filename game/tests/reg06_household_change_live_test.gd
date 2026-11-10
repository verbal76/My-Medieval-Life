extends SceneTree
## B25-AUD-REG-06 (audit 009B): a settlement resident who is live (materialised by SettlementPeople) while the settlement's own day
## changes their household record: their household closes and they are fostered or inherited by another (_after_loss), they marry
## and found a household (_marry), or a village bride weds them (wed_in). SettlementPeople.live[id].hh still names the household they
## were in when they became live, so a later fold credited what they carried to the old household, or, when it had closed, to the
## treasury. The settlement folds a live member back before the change (OffMapSettlement._fold_live, the rule release_person,
## release_household and _remove_member already follow), so what they carry reaches the household they belonged to at that moment
## and passes on with it by the settlement's own rule.
##   godot --headless --path game --script res://tests/reg06_household_change_live_test.gd

var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	test_fostered_child()
	test_marry()
	test_wed_in()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


## [household index, member index, person id] of the first member matching `adult` and not on a trip, in a household with
## `need_child` children at least; [] when none.
func _member(s: OffMapSettlement, adult: bool, need_child := false) -> Array:
	for h in s.hh:
		if not bool(h.alive) or (need_child and int(h.children) < 1):
			continue
		for j in h.mem.size():
			var id := OffMapSettlement.member_id(h.mem[j])
			if s._is_adult(h.mem[j]) == adult and id > 0 and SettlementTrips.of_person(s, id).is_empty():
				return [int(h.id), j, id]
	return []


## A household loses its last adult while one of its children is live: the child is folded first, their coins reach their own
## household's purse, and pass with it to the household that takes the children in; the treasury receives nothing.
func test_fostered_child() -> void:
	var w := _world()
	var r := w.regions
	var p: SettlementPeople = r.people
	var s: OffMapSettlement = null
	var c := []
	for x: OffMapSettlement in r.list:
		c = _member(x, false, true)
		if not c.is_empty():
			s = x
			break
	check(s != null, "a settlement household with a child to make live (%s)" % ("" if s == null else s.id))
	if s == null:
		w.dispose()
		return
	var h: Dictionary = s.hh[int(c[0])]
	var n = p.materialise(int(c[2]))
	check(n != null and p.live.has(int(c[2])), "the child is live")
	n.coins = 5                                      # what the child carries (an errand's change)
	for j in range(h.mem.size() - 1, -1, -1):        # its adults are lost, as the old-age rule removes them
		if s._is_adult(h.mem[j]):
			s._remove_member(h, j)
	var gov0 := int(s.gov.coins)
	var purse := int(h.coins)
	var total0 := 0
	for e in s.hh:
		if e.alive and int(e.id) != int(h.id):
			total0 += int(e.coins)
	s._after_loss(h)
	check(not bool(h.alive), "the household with no adult left closes")
	check(not p.live.has(int(c[2])) and not w.by_id.has(int(c[2])), "the live child was folded before the household changed")
	p.fold_all()                                     # (before the fix, this later fold booked the child's coins to the closed household's treasury)
	var f := p.find(int(c[2]))
	check(not f.is_empty() and int(f.h.id) != int(h.id), "the child is now a member of household %s" % ("-" if f.is_empty() else str(f.h.id)))
	var total := 0
	for e in s.hh:
		if e.alive and int(e.id) != int(h.id):
			total += int(e.coins)
	check(total == total0 + purse + 5, "what the child carried passed with the household's purse to the heir (%d, expected %d)" % [total - total0, purse + 5])
	check(int(s.gov.coins) == gov0, "the treasury received none of it (%d -> %d)" % [gov0, int(s.gov.coins)])
	check(r.audit() == "", "the settlements' books balance (%s)" % r.audit())
	w.dispose()


## Two members marry while the bride is live: she is folded first, and nothing she carries is left booked to her old household
## after she has left it.
func test_marry() -> void:
	var w := _world()
	var r := w.regions
	var p: SettlementPeople = r.people
	var done := false
	for s: OffMapSettlement in r.list:
		var wf := []
		var mf := []
		for h in s.hh:
			if not h.alive:
				continue
			for j in h.mem.size():
				var m: Array = h.mem[j]
				if not s._is_adult(m) or int(m[OffMapSettlement.M_PAIR]) == 1 or not SettlementTrips.of_person(s, OffMapSettlement.member_id(m)).is_empty():
					continue
				if int(m[OffMapSettlement.M_SEX]) == 1 and wf.is_empty():
					wf = [int(h.id), j, OffMapSettlement.member_id(m)]
				elif int(m[OffMapSettlement.M_SEX]) == 0 and mf.is_empty():
					mf = [int(h.id), j, OffMapSettlement.member_id(m)]
		if wf.is_empty() or mf.is_empty() or int(wf[0]) == int(mf[0]):
			continue
		var n = p.materialise(int(wf[2]))
		n.coins = 4
		var nh := s.hh.size()
		s._marry(s.hh[int(wf[0])], int(wf[1]), s.hh[int(mf[0])], int(mf[1]))
		check(not p.live.has(int(wf[2])) and not w.by_id.has(int(wf[2])), "%s: the live bride was folded before she left her household" % s.id)
		var f := p.find(int(wf[2]))
		check(not f.is_empty() and int(f.h.id) == nh, "and she is a member of the new household %d" % nh)
		p.fold_all()                                 # a later fold (a save) moves nothing more to the old household
		check(r.audit() == "", "the settlements' books balance (%s)" % r.audit())
		done = true
		break
	check(done, "a settlement with an unpartnered man and woman of different households")
	w.dispose()


## A village bride weds a live member: he is folded first and his new household is the one his record names.
func test_wed_in() -> void:
	var w := _world()
	var r := w.regions
	var p: SettlementPeople = r.people
	var s: OffMapSettlement = r.by_id["cressbrook"]
	var g := _member(s, true)
	check(not g.is_empty(), "a Cressbrook adult to marry")
	if g.is_empty():
		w.dispose()
		return
	var n = p.materialise(int(g[2]))
	n.coins = 3
	var gh0 := int(g[0])
	var bride := {"id": 0, "sex": 1, "age": 20.0, "unw": 0, "n": "Ada", "f": "Brook", "sk": {}}
	var hi := s.wed_in(gh0, int(g[1]), bride, 0, {})
	check(not p.live.has(int(g[2])) and not w.by_id.has(int(g[2])), "the live groom was folded before he left his household")
	var f := p.find(int(g[2]))
	check(not f.is_empty() and int(f.h.id) == hi, "and he is a member of the new household %d" % hi)
	w.dispose()
