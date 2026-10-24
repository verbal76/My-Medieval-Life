extends SceneTree
## GP-SMITHY-WORKBENCH and GP-SHARPEN (owner, 2026-10-24), in the real game scene: the smithy's workbench is the table
## drawn with a hammer and tongs (its prompt "Use the workbench" only facing that table, never from the grinding wheel);
## at the grinding wheel the smith, when there, sharpens each worn weapon for 1 coin paid to the smith: wear mended to
## full, no damage bonus; refused when the smith is away, the weapon is whole, or the payer has no coin; a villager pays
## by the same rule; coins move purse to purse.
##   godot --headless --path game --script res://tests/sharpen_test.gd

var main
var checks := 0
var failures := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL " + what)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://test_saves/sharpen_test/save1.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func labels() -> Array:
	return main.target_options.map(func(t): return str(t.get("label", ""))) if not main.target_options.is_empty() else ([str(main.target.get("label", ""))] if not main.target.is_empty() else [])


func _run() -> void:
	main.new_game()
	main.ui.hide_all()
	var w: World = main.world
	var p := w.player
	var map: VillageMap = main.map
	# the workbench's table is drawn with the hammer and tongs (tile 1249), its sack and pots gone
	var vals := []
	for l in map.data.layers:
		if str(l.name).begins_with("below"):
			vals.append(int(l.data[47 * map.w + 79]) % 100000)
	check(vals.has(1249) and not vals.has(2559), "the workbench table at (79, 47) shows a hammer and tongs (%s)" % str(vals))
	var wb: Dictionary = {}
	for id in w.stations:
		if str(w.stations[id].type) == "workbench" and str(w.stations[id].building) == "b4":
			wb = w.stations[id]
	check(Vector2i(int(wb.at[0]), int(wb.at[1])) == Vector2i(79, 47), "the smithy's workbench station is that table")
	check(not World.station_in_reach(wb, Vector2(80.5, 46.5), Vector2.UP) and World.station_in_reach(wb, Vector2(79.5, 46.5), Vector2.DOWN),
		"facing the grinding wheel offers no workbench; facing the table does")
	# sharpening
	var smith := w.smith_at_grindstone()
	var smiths := w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.job == "smith")
	if smith == null and not smiths.is_empty():
		smith = smiths[0]
		smith.pos = Vector2(78.5, 46.5)
		smith.plan = [w.brain.work(600, "", {}, "idle")]
	check(w.smith_at_grindstone() == smith and smith != null, "a smith at the grinding wheel")
	p.inv.add("iron_sword")
	var full := int(GameData.item("iron_sword").durability)
	p.inv.durability["iron_sword"] = full - 30
	p.coins = 5
	p.pos = Vector2(80.5, 46.5)
	main.player_sprite.face(Vector2.UP)
	main._find_target()
	var labs := labels()
	check(labs.any(func(l): return l.begins_with("Sharpen your iron sword (1 coin")), "the wheel offers to sharpen the worn sword (%s)" % str(labs))
	var c0 := w.total_coins()
	var s0 := smith.coins
	var dmg := float(GameData.item("iron_sword").damage)
	check(w.player_sharpen("iron_sword") == "" and World.weapon_wear(p.inv, "iron_sword") == 0 and p.coins == 4 and smith.coins == s0 + 1 and w.total_coins() == c0,
		"sharpened: wear mended to full, 1 coin to the smith, no coin made or lost")
	check(float(GameData.item("iron_sword").damage) == dmg, "no damage bonus")
	check(w.player_sharpen("iron_sword") != "", "a whole weapon is not sharpened again")
	p.inv.durability["iron_sword"] = full - 5
	p.coins = 0
	check(w.player_sharpen("iron_sword").contains("coin"), "without a coin it is refused")
	p.coins = 3
	var was := smith.pos
	smith.pos = Vector2(20.5, 60.5)
	check(w.player_sharpen("iron_sword").contains("not at the grinding wheel"), "with the smith away it is refused")
	smith.pos = was
	# a guard pays by the same rule
	var guard: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.job == "guard" and guard == null:
			guard = n
	var gw := ""
	for id in guard.inv.ids():
		if str(GameData.item(id).get("type", "")) == "weapon":
			gw = id
	guard.inv.durability[gw] = int(GameData.item(gw).durability) - 10
	guard.coins = 2
	var c1 := w.total_coins()
	check(w.npc_sharpen(guard, gw) == "" and World.weapon_wear(guard.inv, gw) == 0 and guard.coins == 1 and w.total_coins() == c1, "a guard has his %s sharpened by the same rule and pays" % gw)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
