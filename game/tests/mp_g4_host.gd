extends "res://tests/net_host.gd"
## Build 42 G4 (MML-MP-05, MP-06, MP-07 multi-process check): the test host of tests/net_host.gd (the real game, main.gd, hosting in
## its own Godot process, driven through cmd.json and reporting through status.json), with the few extra commands
## tests/mp_g4_loopback_test.gd needs. Every other command is net_host.gd's own. Extra report: g4.json in the same directory.
##   g4_private  {tag}   private records of the host made directly (a test fixture, as mp07_private_records_test makes them): a tie
##                       and a trade contact with a villager, a debt to them, a crime case, a contract, a law lesson and a kept
##                       message carrying the marker "HOSTSECRET-<tag>"; coins and a loaf in the host's pack
##   g4_cart             a handcart of the host's beside the host, three logs in it
##   g4_revoke   {pid}   the host ends its asset-sharing agreement with that player (World.asset_share_revoke, its window's button)
## Args as net_host.gd.

var g4_cart_id := -1


func _commands() -> void:
	var f := FileAccess.open(dir + "cmd.json", FileAccess.READ)
	if f == null:
		return
	var c = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(c) != TYPE_DICTIONARY or int(c.seq) <= last_seq or not str(c.get("cmd", "")).begins_with("g4_"):
		super._commands()
		return
	last_seq = int(c.seq)
	var w: World = main.world
	match str(c.cmd):
		"g4_private":
			_g4_private(w, str(c.get("tag", "a")))
		"g4_cart":
			var hp: PlayerState = w.host_player()
			var cart: Dictionary = w.carts.place(World.PLAYER, hp.pos + Vector2(0, 1))
			(cart.store as Inventory).add("log", 3)
			w.stat("imported_log", 3.0)
			w.stat("imported_handcart", 1.0)                     # entered in the books as from outside, as net_host's "give" does
			g4_cart_id = int(cart.get("id", -1))
		"g4_revoke":
			why_last = w.asset_share_revoke(int(c.pid))


func _g4_private(w: World, tag: String) -> void:
	var hp: PlayerState = w.host_player()
	var hid: int = w.person_id(hp)
	var v: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0:
			v = n
			break
	if v == null:
		return
	var n0 := 9900 + w.credit.debts.size()
	w.relations.tie(hid, v.id).regard = 6.0
	w.relations.note_trade(hid, v.id, 1)
	w.credit.debts.append({"id": n0, "creditor": World.npc_ref(v.id), "debtor": World.PLAYER, "item": "bread", "qty": 1, "value": 4, "made": w.day(),
		"due": w.day() + 9, "state": "open", "ended": -1})
	w.justice.record(World.PLAYER, "theft", v, v.pos, w.day())
	w.contracts.list.append({"id": n0 + 50, "buyer": World.PLAYER, "seller": World.npc_ref(v.id), "item": "bread", "qty": 2, "price_each": 3, "days": 4,
		"deadline_day": w.day() + 9, "state": "offered", "delivered": 0, "paid": 0, "reserved": 0, "made_day": w.day(), "history": []})
	w.law_lessons[World.PLAYER] = [1, 2]
	w.messages.record(World.PLAYER, w.minutes, "family", "HOSTSECRET-" + tag)
	if not (w.messages.by_ref.get(World.PLAYER, []) as Array).any(func(e): return str(e[2]) == "HOSTSECRET-" + tag):
		var mine: Array = w.messages.by_ref.get(World.PLAYER, [])
		mine.append([w.minutes, "note", "HOSTSECRET-" + tag])
		w.messages.by_ref[World.PLAYER] = mine


func _status() -> void:
	super._status()
	if not started or main.world == null:
		return
	var w: World = main.world
	var cart := {}
	if g4_cart_id >= 0:
		var cd: Dictionary = w.carts.by_id(g4_cart_id)
		if not cd.is_empty():
			cart = {"id": g4_cart_id, "owner": str(cd.owner), "puller": str(cd.get("puller", "")), "logs": (cd.store as Inventory).count("log"),
				"pos": [cd.pos.x, cd.pos.y] if cd.get("pos") is Vector2 else []}
	var out := {"seq": last_seq, "shares": w.asset_shares.duplicate(), "host_id": w.person_id(w.host_player()), "host_coins": w.host_player().coins,
		"cart": cart, "why": why_last, "offers": w.offers.duplicate(true)}
	var f := FileAccess.open(dir + "g4.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out))
		f.close()
