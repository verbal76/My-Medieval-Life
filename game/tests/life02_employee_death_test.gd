extends SceneTree
## LIFE-02 (Build 25 audit): an employee who dies carrying their employer's goods (Employment record `owed`: what they mined, cut
## or made for the employer and have not yet delivered) hands those goods over before anything passes on. Before the fix
## World.kill passed everything they carried to their heir (_inherit) or left it where they fell (loot), and the record was only
## erased at the next dawn (Employment.daily), so the employer's goods went to the heir or the looter. Now the employment ends at
## the death: the owed goods go to the employer's store (Employment._hand_over, the dismissal rule), what does not fit stays with
## the dead and passes on as theirs; the rest of their own goods pass as before. Both a natural death and a slaying; the goods
## ledger balances.
##   godot --headless --path game --script res://tests/life02_employee_death_test.gd

const ORE := "iron_ore"
const OWED := 3
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL: ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	GameData.ensure()
	test_death("old age")
	test_death("slain by Rob")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## A home of the player's own with its chest (as business_founding_test.gd: the coins and materials given here).
func player_home(w: World) -> void:
	if w.player.home != "" and w.buildings.has(w.player.home):
		return
	var sp = w.map.data.spawns.player
	var c: Construction = w.construction
	var rect := c.find_ground("house", Vector2i(int(sp[0]), int(sp[1])), World.PLAYER)
	w.player.coins += w.property.land_price(rect.size.x, rect.size.y)
	var p: Dictionary = c.place("house", rect, World.PLAYER)
	for id in p.site.need.duplicate():
		w.player.inv.add(id, int(p.site.need[id]))
	w.deliver(p, w.player.inv)
	w.property.set_home(str(p.building))


## Every unit of `id` held anywhere a death can move it: packs, the employer's store, pantries, loot.
func ledger(w: World, store: Inventory, id: String) -> int:
	var t := w.player.inv.count(id) + store.count(id)
	for n: NPC in w.npcs:
		t += n.inv.count(id)
	for hh in w.households:
		t += (hh.pantry as Inventory).count(id)
	for l in w.loot:
		t += (l.inv as Inventory).count(id)
	return t


func loot_count(w: World, id: String) -> int:
	var t := 0
	for l in w.loot:
		t += (l.inv as Inventory).count(id)
	return t


func test_death(cause: String) -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	w.judgment.cfg.decision.integration.work_accept = false      # the villager's own yes is JudgmentLive's test; here the terms
	player_home(w)
	w.player.coins += 500
	var n: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o.household >= 0 and o.job in Construction.HIRABLE and w.employment.refusal(o) == "" \
				and w._heir(o) != null:
			n = o
			break
	check(n != null, "%s: fixture: an employable adult with an heir" % cause)
	if n == null:
		return
	check(w.employment.employ(n, "miner") == "", "%s: fixture: the player employs them as a miner" % cause)
	var store: Inventory = w.construction.store_of(World.PLAYER)
	var rec: Dictionary = w.employment.record_of(n)
	n.inv.remove(ORE, n.inv.count(ORE))
	n.inv.add(ORE, OWED)                       # the ore they dug for the employer, not yet carried home (as act_mine records it)
	rec.owed[ORE] = OWED
	n.inv.add("bread", 1)                      # and something of their own
	var heir: NPC = w._heir(n)
	var heir_ore := heir.inv.count(ORE)
	var in_store := store.count(ORE)
	var loot_ore := loot_count(w, ORE)
	var total := ledger(w, store, ORE)
	w.kill(n, cause)
	check(store.count(ORE) - in_store == OWED, "%s: the employer's ore goes to the employer's store (%d)" % [cause, store.count(ORE) - in_store])
	check(heir.inv.count(ORE) == heir_ore, "%s: the heir does not inherit the employer's ore" % cause)
	check(loot_count(w, ORE) == loot_ore, "%s: nor does it lie where they fell for a looter" % cause)
	check(not w.employment.is_employed(n), "%s: the employment ends with the death" % cause)
	check(ledger(w, store, ORE) == total, "%s: the goods ledger balances (%d -> %d)" % [cause, total, ledger(w, store, ORE)])
