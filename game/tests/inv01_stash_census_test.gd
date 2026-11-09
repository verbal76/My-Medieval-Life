extends SceneTree
## INV-01 (Build 25 audit, docs/audits/2026-11-08_build25_master_audit_register.md on docs/build25-audit-register): the goods
## census (Holdings.holders, used by the conservation checks and the flight recorder's item ledger) must count goods a player
## keeps in their own containers other than the family chest (Chests.stash). Without it, storing goods there looks like
## goods destroyed and taking them out like goods created.
var checks := 0
var fails := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		fails += 1


func census(w: World, id: String) -> int:
	return int(SettlementHoldings.total(SettlementHoldings.holders(w)).get(id, 0))


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8906)
	var b: Dictionary = {}
	for o: NPC in w.npcs:
		if o.alive and o.household >= 0 and o.home != "" and w.buildings.has(o.home) and o.home != w.player.home \
				and not w.chests.units_in(o.home).is_empty() and w.owner_of(w.buildings[o.home]) == World.hh_ref(o.household):
			b = w.buildings[o.home]
			break
	check(not b.is_empty(), "fixture: a house with chests")
	w.set_owner(b, w.acting_ref())
	var u: Dictionary = w.chests.units_in(str(b.id))[0]
	var i: Dictionary = w.chests.info(u)
	check(str(i.access) == "own" and not bool(i.family), "fixture: the player's own stash, not the family chest")
	w.player.inv.add("log", 3)
	var before := census(w, "log")
	check(w.chests.store(u, "log", 3) == "", "the player stores 3 logs in it")
	check(census(w, "log") == before, "storing them changes no total in the census (%d -> %d)" % [before, census(w, "log")])
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	check(census(w2, "log") == before, "after a save and load the census still counts them (%d)" % census(w2, "log"))
	var r: Dictionary = w.chests.take(u, "log", 3)
	check(bool(r.ok) and census(w, "log") == before, "taking them out again changes no total either (%d)" % census(w, "log"))
	w.dispose()
	w2.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
