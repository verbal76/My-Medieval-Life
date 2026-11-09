extends SceneTree
## SAV-03, counter part (Build 25 audit, docs/audits/2026-11-08_build25_master_audit_register.md): Counters.serving (which
## keeper is coming to or serving a skilled trade's counter) was not saved, but the keeper's plan with its serve_counter step is.
## After a load, the counter showed nobody serving: a second ring could send a second keeper, and the first keeper's finish
## (Counters.served) would then erase the second one's entry. The serving map is rebuilt from the restored plans on load.
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
	var ids: Array = w.counters.all().filter(func(c): return str(w.stations[c].type) == "armory_counter")
	check(not ids.is_empty(), "fixture: an armoury counter")
	var id: String = ids[0]
	w.minutes = floorf(w.minutes / World.DAY) * World.DAY + 10.0 * 60.0
	for n: NPC in w.counters.keepers(id):
		n.anim = "idle"
		n.hunger = 100.0
		n.target = -1
		n.plan = [w.brain.work(120, "", {}, "work")]
	w.player.pos = Vector2(w.station_use(id)) + Vector2(0.5, 1.5)
	var r: Dictionary = w.counters.summon(id)
	var keeper: NPC = r.get("npc")
	check(bool(r.ok) and keeper != null and w.counters.server(id) == keeper, "a keeper is coming to the counter (%s)" % str(r.get("text", "")))
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	var k2: NPC = w2.npc(keeper.id) if keeper != null else null
	check(k2 != null and k2.plan.any(func(s): return str(s.get("act", "")) == "serve_counter"), "after a save and load the keeper's plan still goes to the counter")
	check(w2.counters.server(id) == k2, "and the counter knows that keeper is coming (serving %s)" % str(w2.counters.serving))
	var again: Dictionary = w2.counters.summon(id)
	check(bool(again.ok) and again.get("npc") == k2 and not str(again.text).contains("is coming"), "ringing again names the same keeper, nobody else is sent (%s)" % str(again.get("text", "")))
	var sent := 0
	for n: NPC in w2.npcs:
		if n.alive and n.plan.any(func(s): return str(s.get("act", "")) == "serve_counter" and str(s.get("args", {}).get("counter", "")) == id):
			sent += 1
	check(sent == 1, "exactly one keeper is on the way (%d)" % sent)
	w.dispose()
	w2.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
