extends SceneTree
## B25R2-BRUSHOFF (start_test on fe7d8f8, 2026-11-07): Dialogue.brush_off read n.plan[0] without checking the plan, a SCRIPT
## ERROR when a busy villager between plans brushed the player off. Seed 1: an adult villager with no plan, then one at work, then one
## walking; each answer is a sentence, the working one says so.
##   godot --headless --path game -s res://tests/brushoff_empty_plan_test.gd

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var n: NPC = null
	for c: NPC in w.npcs:
		if c.alive and c.role == "adult":
			n = c
			break
	check(n != null, "an adult villager")
	if n != null:
		Dialogue.meet(w, n)                       # a villager the player has met (a stranger answers before the plan is read)
		check(Dialogue.met(w, n), "the villager has met the player")
		n.plan = []
		var t := Dialogue.brush_off(w, n)
		check(str(t) != "" and not str(t).begins_with("Don't know you"), "a villager with no plan brushes the player off without an error (%s)" % str(t))
		n.plan = [{"k": "work", "args": {}}]
		var t2 := str(Dialogue.brush_off(w, n))
		check(t2 != "", "a villager at work answers too (%s)" % t2)
		n.plan = [{"k": "go", "to": n.cell()}]
		check(str(Dialogue.brush_off(w, n)) != "", "and one walking somewhere")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
