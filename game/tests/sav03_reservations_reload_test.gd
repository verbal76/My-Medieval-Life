extends SceneTree
## SAV-03, the other reservation maps (Build 25 audit, docs/audits/2026-11-08_build25_master_audit_register.md): four maps say who
## is already on the way to a piece of work so a second villager is not sent too, and none of them is saved, though the plans that
## made them are: FarmPlots.busy (cells a member is coming to work: fp_work), Fauna.claims (the animal a hunter is after: hunt),
## Chapel.booked (a household's member on the way to ask for food: church_ask) and Business.heading (a buyer walking to a stall:
## buy_stall). After a load they were empty, so the same work could be handed out twice. They are rebuilt from the restored plans
## on load, as Counters.serving is (sav03_counter_reload_test). NPCBrain.buy_failed is a memo of failed purchases, not a
## reservation: losing it only means one retry, and it stays unsaved.
##   godot --headless --path game --script res://tests/sav03_reservations_reload_test.gd

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
	var ps: Array = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult" and o.household >= 0)
	ps.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
	var farmer: NPC = ps[0]
	var hunter: NPC = ps[1]
	var asker: NPC = ps[2]
	var buyer: NPC = ps[3]
	var prey: Animal = w.fauna.nearest_game(hunter.pos, 100000.0)
	check(prey != null, "fixture: an animal to hunt")
	var cell := Vector2i(7, 9)
	farmer.plan = [w.brain.go(cell), w.brain.work(40.0, "fp_work", {"plot": "p0", "task": "till", "crop": "", "cells": [[cell.x, cell.y]]}, "work", cell)]
	hunter.plan = [w.brain.go(prey.cell()), w.brain.work(60.0, "hunt", {"animal": prey.id}, "work", prey.cell())]
	asker.plan = [w.brain.go(Vector2i(10, 10)), w.brain.doit("church_ask", {})]
	buyer.plan = [w.brain.go(Vector2i(12, 12)), w.brain.doit("buy_stall", {"stall": "s0", "item": "bread", "pantry": true})]
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var f2: NPC = w2.npc(farmer.id)
	check(f2 != null and f2.plan.any(func(s): return str(s.get("act", "")) == "fp_work"), "after a load the farm member's plan still works the plot")
	check(float(w2.farm_plots.busy.get(cell, -1.0)) > float(w2.minutes), "and the cell is kept for them (busy %s)" % str(w2.farm_plots.busy.get(cell, "none")))
	check(int(w2.fauna.claims.get(prey.id, -1)) == hunter.id, "the hunter's quarry is still claimed (%s)" % str(w2.fauna.claims))
	check(int(w2.chapel.booked.get(asker.household, -1)) == w2.day(), "the household's member is still booked to ask at the chapel today (%s)" % str(w2.chapel.booked))
	check(w2.business.heading.has(buyer.id), "the buyer walking to the stall is still counted as heading there (%s)" % str(w2.business.heading))
	w.dispose()
	w2.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
