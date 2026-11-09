extends SceneTree
## LIFE-05 (owner decision 2026-11-08, docs/directives/2026-11-09_overnight_autonomous_development.md): kin who joined the bandits
## inherit last, after everyone of the family at home; when only bandit kin are left, the eldest of them inherits.
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
	w.setup(VillageMap.load_default(), 8906)
	var adults: Array = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult")
	check(adults.size() >= 5, "fixture: five living adults")
	var dead: NPC = adults[0]
	var spouse: NPC = adults[1]
	var outlaw: NPC = adults[2]                  # the eldest child, gone to the bandits
	var son: NPC = adults[3]                     # a younger child at home
	for o: NPC in [dead, spouse, outlaw, son]:
		o.partner = -1
		o.mother = -1
		o.father = -1
		o.children = []
	dead.partner = spouse.id
	spouse.partner = dead.id
	dead.children = [outlaw.id, son.id]
	outlaw.mother = dead.id
	son.mother = dead.id
	outlaw.born = son.born - 400.0
	Life.kin_version += 1
	check(Life.heir_of(w, dead) == outlaw, "fixture: with nobody a bandit, the eldest adult child inherits (owner order)")
	outlaw.role = "bandit"
	check(Life.heir_of(w, dead) == son, "the eldest child joined the bandits: the child at home inherits instead")
	dead.children = [outlaw.id]
	Life.kin_version += 1
	check(Life.heir_of(w, dead) == spouse, "with the only adult child a bandit, the partner at home inherits")
	spouse.alive = false
	check(Life.heir_of(w, dead) == outlaw, "with nobody at home, the bandit child inherits last")
	spouse.alive = true
	outlaw.role = "adult"
	check(Life.heir_of(w, dead) == outlaw, "returned to ordinary life, the child inherits in the normal order again")
	outlaw.role = "bandit"
	var c0: int = w.total_coins()
	dead.coins += 0
	var spouse0 := spouse.coins
	var dead_coins := dead.coins
	w.kill(dead, "old age")
	check(spouse.coins >= spouse0 + dead_coins and outlaw.alive, "a real death: the estate goes to the partner, not the bandit child")
	check(w.total_coins() == c0, "no coin made or lost")
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
