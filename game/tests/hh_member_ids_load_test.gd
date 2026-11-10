extends SceneTree
## B25-INV-BANDIT-CHILD, second finding (investigation docs/audits/2026-11-10_INVESTIGATIONS_P52_BANDIT_CHILDREN.md): a save's JSON
## reads every number as a float, and World.load_dict kept each household's "members" as read (the couple's ids and the
## homestead claims' members were already made whole numbers on load). Array.erase / has / find with a villager's int id do
## not match a float, so after any load a villager who moved household, died out of one or was placed elsewhere stayed listed
## in the old one: in campaign 42788018729 (seed 1, resumed from a save every segment) p:142, moved out of the bandit household
## 25 on day 183, stayed listed there as a phantom adult, and household 27's orphans were placed again every dawn. About fifteen
## code paths remove a member by id (Life, Construction, Guardianship, LifeDecisions, Homesteads, main). Now the ids are
## whole numbers on load, as the couple's are. Checked:
##   1 after a save and load every household's members are whole numbers
##   2 a member removed by id after a load is removed (the pattern every household change uses), and found by has / find
##   3 a save written after the load is the same as the save before it (nothing dropped, reordered or reinterpreted)
##   4 two identical loads agree (deterministic)
##   godot --headless --path game --script res://tests/hh_member_ids_load_test.gd

var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var text := JSON.stringify(w.to_dict(), "", true, true)
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	var floats := 0
	var total := 0
	for hh in w2.households:
		for m in hh.members:
			total += 1
			if typeof(m) != TYPE_INT:
				floats += 1
	check(total > 0 and floats == 0, "after a save and load every household member id is a whole number (%d of %d are not)" % [floats, total])
	var h := -1
	var id := -1
	for i in w2.households.size():
		if (w2.households[i].members as Array).size() >= 2:
			h = i
			id = int(w2.households[i].members[0])
			break
	var ms: Array = w2.households[h].members
	check(ms.has(id) and ms.find(id) == 0, "a member is found by their id after the load (has, find)")
	var n0 := ms.size()
	ms.erase(id)                                   # the pattern of every household change (Life, Construction, Guardianship, ...)
	check(ms.size() == n0 - 1 and not ms.has(id), "a member removed by id after the load is removed (%d -> %d)" % [n0, ms.size()])
	var w3 := World.new()
	w3.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	var again := JSON.stringify(w3.to_dict(), "", true, true)
	var p0: Dictionary = JSON.parse_string(text)
	var p1: Dictionary = JSON.parse_string(again)
	check(JSON.stringify(p0.households) == JSON.stringify(p1.households), "the households saved again after the load are the same as before it (nothing dropped or reordered)")
	var w4 := World.new()
	w4.load_dict(VillageMap.load_default(), JSON.parse_string(text))
	check(JSON.stringify(w4.to_dict().households) == JSON.stringify(w3.to_dict().households), "two identical loads agree (deterministic)")
	w.dispose()
	w2.dispose()
	w3.dispose()
	w4.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
