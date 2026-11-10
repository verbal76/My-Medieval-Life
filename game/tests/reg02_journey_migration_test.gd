extends SceneTree
## REG-02, journey part (Build 25 audit, docs/audits/2026-11-08_build25_master_audit_register.md): a villager who leaves the
## village with their household (Migration._gone) while on a journey must not carry the open trip into the settlement, and one who
## comes back (Migration._reactivate) must not resume a trip that belonged to their old life. The journey ends, counted, on
## departure. The debt part of REG-02 (a household's open loans) is an owner question and is not touched here.
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
	w.minutes = 1440.0 + 6.0 * 60.0 + 30.0
	var s: OffMapSettlement = w.regions.by_id["wulstead"]
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.job != "guard":
			n = o
			break
	n.inv.add("bread", 4)
	check(Journeys.start(w, n, "garton", {"kind": "visit"}) == "" and Journeys.active(n), "fixture: %s sets off for Garton" % n.name)
	var ms := w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.household == n.household)
	var ended0 := float(w.stats.get("journey_ended_emigrated", 0.0))
	var bt: String = (s.biz.keys() as Array)[0]
	var went := Migration._household_out(w, s, ms, true, "work", bt)
	check(went and not n.alive and n.away == s.id, "fixture: the household leaves for Wulstead")
	check(n.journey.is_empty(), "the open journey ended when they left (journey %s)" % str(n.journey))
	check(float(w.stats.get("journey_ended_emigrated", 0.0)) == ended0 + 1.0, "and its end is counted")
	n.journey = {"to": "garton", "leg": "out"}            # an older save could still hold one
	Migration._reactivate(w, n, {"age": 30, "sk": {}}, 0)
	check(n.journey.is_empty(), "someone who comes back starts with no old trip")
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
