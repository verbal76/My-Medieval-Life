extends SceneTree
## Writes game/tests/fixtures/mp_save_v22_couple.json with the UNMODIFIED Build 21 code (6567c04): a version 22 save in which the host
## (a man) and a guest (a woman, away) are married players (MP-D8), each with a purse, a pack, a family chest and ties, and the host a
## villager friend: the save MP-PLAYER-FAMILY's migration to 23 must read with everything kept.
##   godot --headless --path game --script res://tests/gen_v22_family_fixture.gd -- OUT.json


func _init() -> void:
	GameData.ensure()

	var w := World.new()
	w.setup(VillageMap.load_default(), 3)
	for i in 300:
		w.update(0.5)
	var host := w.player
	host.sex = "male"
	host.born = w.minutes - Life.year_days() * World.DAY * 25.0
	host.coins = 77
	host.inv.add("bread", 3)
	host.chest.add("wheat", 6)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = "Fairlight"
	g.sex = "female"
	g.born = host.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "cd".repeat(32)
	g.coins = 41
	g.inv.add("apple", 4)
	g.pos = host.pos + Vector2(1, 0)
	w.add_guest(g)
	var ad: Array = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard")
	w.relations.talked(ad[0])
	w.as_actor(g, func(): w.relations.talked(ad[1]))
	var why := w.player_offer("partner", g.pid)
	var ans := w.player_answer(int(w.offers_to(g)[0].id), true, g) if why == "" else why
	g.away = true
	var d := w.to_dict()
	var out := "res://tests/fixtures/mp_save_v22_couple.json"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "", true))
	f.close()
	print("wrote %s: save %d, offer '%s', answer '%s', host partner %d, guest pid %d partner %d, households %d" % [out, int(d.save_version), why, ans,
		host.partner, g.pid, g.partner, (d.households as Array).size()])
	quit(0)
