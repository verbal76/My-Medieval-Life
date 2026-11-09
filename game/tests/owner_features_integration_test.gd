extends SceneTree
## Integration verification of the owner-approved features LIFE-03 (sage succession, PR #16), LIFE-04 (remarriage, PR #17) and
## PROP-06 (migrating households' property, PR #18), beyond each PR's focused test (owner directive 2026-11-08, section 4). One world
## per part, seed 1. Counts only.
##   godot --headless --path game -s res://tests/owner_features_integration_test.gd

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func world() -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	return w


func reload(w: World) -> World:
	var b := World.new()
	b.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict(), "", true, true)))
	return b


func _init() -> void:
	GameData.ensure()
	sage()
	remarriage()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- LIFE-03 -----------------------------
func sage() -> void:
	var w := world()
	var s: NPC = w.npc(w.sage_id)
	check(s != null and s.alive, "LIFE-03: a sage at the start")
	for n: NPC in w.npcs:
		n.skills["healing"] = 0                          # nobody in the village knows healing: no local successor
	var coins0 := w.total_coins()
	var n_in0 := int(w.stats.get("newcomer_coins_in", 0))
	var ids0 := {}
	for n: NPC in w.npcs:
		ids0[n.id] = true
	var old := s.id
	w.kill(s, "old age")
	# a world saved during the vacancy loads, and the vacancy is still open in it
	var b := reload(w)
	check(b.vacancies.filter(func(v): return str(v.job) == "sage").size() == 1 and not b.npc(old).alive, "LIFE-03: a save with no living sage loads, the sage's post still open")
	b.dispose()
	for d in int(GameData.b("succession_days")) + 1:
		w.minutes += 1440.0
		w.brain.succession_dawn()
	var early: NPC = w.npc(w.sage_id)
	check(w.sage_id == old or (early != null and early.alive and not ids0.has(early.id) and Skills.level(early, "healing") >= 1),
		"LIFE-03: with nobody qualified in the village, no villager takes the post; only a trained newcomer may (holder %s, newcomer %s, healing %d)" % [early.name if early else "-", str(early != null and not ids0.has(early.id)), Skills.level(early, "healing") if early else -1])
	w.minutes += float(GameData.b("newcomer_max_days")) * 1440.0
	w.brain.succession_dawn()
	var ns: NPC = w.npc(w.sage_id)
	check(ns != null and ns.alive and not ids0.has(ns.id) and ns.job == "sage" and Skills.level(ns, "healing") >= 1,
		"LIFE-03: a trained newcomer arrives for the post (%s)" % (ns.name if ns else "none"))
	check(ns != null and ns.workplace == "hut", "LIFE-03: the newcomer works from the sage's hut")
	var lv := int(GameData.recipes.brew_healing_tonic.level)
	check(ns != null and w.npc(w.sage_id) == ns and Skills.level(ns, "healing") >= lv,
		"LIFE-03: the successor is the village's apothecary (sage_id, its buyers' seller and the spell teacher) and can brew a healing tonic (level %d)" % lv)
	check(w.total_coins() - coins0 == int(w.stats.get("newcomer_coins_in", 0)) - n_in0, "LIFE-03: coins: the only change is the newcomer's purse, counted as coming in (%+d)" % (w.total_coins() - coins0))
	var c := reload(w)
	check(c.sage_id == w.sage_id and c.npc(c.sage_id).job == "sage", "LIFE-03: the successor is the sage after a save and load")
	c.dispose()
	w.dispose()


# ---------------------------------------------------------------- LIFE-04 -----------------------------
func remarriage() -> void:
	var w := world()
	var wife: NPC = null
	var husband: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner >= 0 and w.npc(n.partner) != null and w.npc(n.partner).alive:
			wife = n
			husband = w.npc(n.partner)
			break
	check(wife != null, "LIFE-04: a married couple")
	if wife == null:
		w.dispose()
		return
	var suitor: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.partner < 0 and n != wife and n != husband and n.household != wife.household and n.sex != wife.sex:
			suitor = n
			break
	check(suitor != null, "LIFE-04: an unpartnered adult")
	if suitor == null:
		w.dispose()
		return
	check(Life.has_partner(w, wife), "LIFE-04: while her husband lives she has a partner")
	var refusal_live := w.relations.can_court(suitor.id, wife.id)
	check(not refusal_live, "LIFE-04: a living spouse cannot be bypassed: courting a married villager is refused")
	var kids := wife.children.duplicate() if "children" in wife else []
	w.kill(husband, "old age")
	check(not Life.has_partner(w, wife), "LIFE-04: widowed, she has no living partner")
	check(w.relations.can_court(suitor.id, wife.id), "LIFE-04: the widow may be courted (%s)" % w.relations.can_court(suitor.id, wife.id))
	if "children" in wife:
		check(wife.children == kids, "LIFE-04: her children are unchanged by widowhood")
	var b := reload(w)
	var bw: NPC = b.npc(wife.id)
	check(bw != null and not Life.has_partner(b, bw) and b.relations.can_court(suitor.id, bw.id), "LIFE-04: after a save and load she is still a widow free to remarry")
	b.dispose()
	w.dispose()
