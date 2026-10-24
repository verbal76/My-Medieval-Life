extends SceneTree
## Writes game/tests/fixtures/mp_save_v21_guest.json with the UNMODIFIED Batch B code (805a1c9): a version 21 save with one guest
## who has its own records (purse, pack, skills, a killing and an assault on its record and case, a judgment fact tagged by it,
## a tie it made, which save 21 kept under -2 as everyone's) and the host's records.
##   godot --headless --path game --script res://tests/gen_v21_guest_fixture.gd -- OUT.json


func _init() -> void:
	GameData.ensure()

	var w := World.new()
	w.setup(VillageMap.load_default(), 3)
	for i in 300:
		w.update(0.5)
	var host := w.player
	host.coins = 77
	host.inv.add("bread", 3)
	var g := PlayerState.new()
	g.name = "Gwen"
	g.family = ""
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = "cd".repeat(32)
	g.coins = 41
	g.inv.add("apple", 4)
	g.skills["combat"] = 120
	g.pos = host.pos + Vector2(2, 0)
	w.add_guest(g)
	var ad: Array = w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.role == "adult" and n.job != "guard")
	var v1: NPC = ad[0]
	var v2: NPC = ad[1]
	var v3: NPC = ad[2]
	# the guest talks with one villager (in save 21 the tie is under -2, the host's and everyone's)
	w.as_actor(g, func(): w.relations.talked(v3))
	# the guest strikes one villager and kills another, in sight of a third
	v1.pos = g.pos + Vector2(0.6, 0)
	v2.pos = g.pos + Vector2(-0.6, 0)
	v1.hp = 1.0
	w.player_hit_npc(v2, 1.0, g)
	w.player_hit_npc(v1, 500.0, g)
	g.away = true
	var d := w.to_dict()
	var out := "res://tests/fixtures/mp_save_v21_guest.json"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "", true))
	f.close()
	print("wrote %s: save %d, guest pid %d, host pid %d, judgment %s, guest crimes %d, guest killings %s" % [out, int(d.save_version), g.pid, host.pid,
		str(d.has("judgment")), g.crimes.size(), str(w.relations.guest_killings)])
	quit(0)
