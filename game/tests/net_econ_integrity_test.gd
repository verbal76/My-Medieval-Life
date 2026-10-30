extends SceneTree
## X20-MP-ECON-INTEGRITY (owner directive 2026-10-30, docs/directives/2026-10-30_x20_background_development.md s.5; MP Batch D
## decision): "Transactions must remain authoritative, idempotent and exactly conserved. No duplicate money, lost inventory,
## duplicated delivery, or partially committed transaction may result from network faults." Real Godot processes on loopback, the
## harness of net_fault_test.gd: this process is guest Ann running the real game (main.gd) through tests/net_proxy.gd (a UDP relay
## that drops, repeats, delays, reorders or swallows ENet's datagrams); tests/net_host.gd is the host (flag "still": its world's
## simulation stopped while the network and the guests' requests go on, so every coin and good can be counted exactly before and
## after; "econ": the Living Economy on with its market driving); tests/net_fault_guest.gd is guest Bea, killed mid-transaction.
##
## Covered, with the economy off (shipped) and on: negotiated offers between players (sell, buy, gift) and player contracts (the
## buyer's coins set aside, deliveries paid) under repeated, late and swapped requests and a lossy network; the transaction
## authority (World.transactions) with guests as parties: shipments with goods in transit custody and coins in escrow, delivered,
## failed, replayed and stale ids; a request lost in a dropped connection; an Android host's and guest's pause; a guest leaving (and
## a guest killed) with open shipments and contracts; a guest's crafted request on a contract that is not its own (ownership); the
## host killed after a save and restored from it with a shipment and a contract open; a guest's death and succession with goods in
## transit and coins in escrow; and a stretch with the world running and the market driving. After each: the ledger (every coin and
## good in the village, the settlements, transit, escrow and the sinks) is exactly the same; every request applied at most once (and
## exactly once when nothing was lost); no shipment or escrow stranded; the buyer and seller of each transfer the right ones.
##   godot --headless --path game --script res://tests/net_econ_integrity_test.gd

var main
var failures := 0
var checks := 0
var dir := "user://test_net_econ/"
var port := 0
var dport := 0
var pport := 0
var host_proc := -1
var proxy_proc := -1
var bea_proc := -1
var seq := 0
var ann := 0
var host_pid := 0
var bea := 0
var flags := "still"
const KEY := "a0b1c2d3e4f5061728394a5b6c7d8e9f"
const KEY2 := "9f8e7d6c5b4a39281706f5e4d3c2b1a0"
const IT := "apple"
const WH := "wheat"


func check(cond: bool, what: String) -> void:
	checks += 1
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


func _init() -> void:
	port = 49700 + OS.get_process_id() % 40 * 4
	dport = port + 1
	pport = port + 2
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["status.json", "cmd.json", "host_save.json", "host_save.json.bak", "proxy.json", "proxy_status.json", "g2.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + f))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.save_path = dir + "guest_never_saves.json"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- helpers ----------------------
func spawn(script: String, args: Array) -> int:
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script, "--"] + args
	return OS.create_process(OS.get_executable_path(), a)


func read_json(name: String) -> Dictionary:
	var f := FileAccess.open(dir + name, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if typeof(d) == TYPE_DICTIONARY else {}


func status() -> Dictionary:
	return read_json("status.json")


func command(d: Dictionary, wait_for := true) -> void:
	seq += 1
	d["seq"] = seq
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	if wait_for:
		await until(func(): return int(status().get("seq", -1)) >= seq, 8.0)


func proxy(cfg: Dictionary) -> void:
	var f := FileAccess.open(dir + "proxy.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(cfg))
	f.close()
	await wait(0.4)


func until(cond: Callable, secs: float) -> bool:
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func wait(secs: float) -> void:
	await until(func(): return false, secs)


func rec(pid: int) -> Dictionary:
	return status().get("players", {}).get(str(pid), {})


func conn() -> Array:
	return (status().get("connected", []) as Array).map(func(x): return int(x))


func net_d() -> Dictionary:
	return status().get("net_d", {})


func has(pid: int, item: String) -> int:
	return int(rec(pid).get("inv", {}).get(item, 0))


func coins(pid: int) -> int:
	return int(rec(pid).get("coins", 0))


func in_game() -> bool:
	return main.guest_world and main.net.connected() and not main.net.reconnecting


## How many times the host applied request `rid` of player `pid` (its log of the last 200).
func times(pid: int, rid: int) -> int:
	return (net_d().get("log", []) as Array).filter(func(e): return int(e[0]) == pid and int(e[1]) == rid).size()


## Every coin and good in the world now (net_host "ledger").
func led() -> Dictionary:
	await command({"cmd": "ledger"})
	return status().get("ledger", {})


## What differs between two ledgers' goods (item: [before, after]).
static func goods_diff(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := {}
	var ga: Dictionary = a.get("goods", {})
	var gb: Dictionary = b.get("goods", {})
	for k in ga.keys() + gb.keys():
		if int(ga.get(k, 0)) != int(gb.get(k, 0)):
			out[k] = [int(ga.get(k, 0)), int(gb.get(k, 0))]
	return out


## The exact conservation check: every coin (village, settlements, transit and escrow, outside) and every good (every holder,
## settlements, transit custody, sunk) as before.
func same(a: Dictionary, b: Dictionary, what: String) -> void:
	var gd := goods_diff(a, b)
	check(not a.is_empty() and int(a.coins) == int(b.coins) and gd.is_empty() and str(b.get("audit", "x")) == "",
		"%s: every coin and good conserved (coins %d -> %d, in transit %s; goods differing %s; regional audit \"%s\")" % [what, int(a.get("coins", 0)), int(b.get("coins", 0)), str(b.get("transit", {})), str(gd), str(b.get("audit", ""))])


func offer_to_me(kind: String) -> Dictionary:
	for o in main.world.offers_to(main.world.player):
		if str(o.kind) == kind:
			return o
	return {}


## The host offers Ann `kind` (net_host "offer", World.player_offer as the host) and waits until her copy has it.
func host_offers(kind: String, item: String, qty: int, price: int, days := 0) -> Dictionary:
	await command({"cmd": "offer", "kind": kind, "to": ann, "item": item, "qty": qty, "price": price, "days": days})
	await until(func(): return not offer_to_me(kind).is_empty(), 8.0)
	return offer_to_me(kind)


## An offer on the host's record from `from_ref` of `kind`.
func host_offer(kind: String, from_ref: String) -> Dictionary:
	for o in status().get("offers", []):
		if str(o.kind) == kind and str(o["from"]) == from_ref:
			return o
	return {}


## Ann answers (accepts) offer `id` through her own world (World.player_answer -> the host): the request's number.
func accept(id: int) -> int:
	main.world.player_answer(id, true)
	return main.net.last_request()


func ann_ref() -> String:
	return str(rec(ann).get("ref", ""))


## A player contract on the host's record, by id.
func contract(id: int) -> Dictionary:
	for c in status().get("contracts", []):
		if int(c.id) == id:
			return c
	return {}


## The newest open (accepted, Contracts.is_open) contract between the host and Ann (as the host has it).
func open_contract() -> Dictionary:
	var best := {}
	for c in status().get("contracts", []):
		if str(c.state) == "accepted" and (str(c.buyer) == ann_ref() or str(c.seller) == ann_ref()) and (best.is_empty() or int(c.id) > int(best.id)):
			best = c
	return best


func tx(d: Dictionary) -> Dictionary:
	d["cmd"] = "tx"
	await command(d)
	return status().get("tx_last", {})


func shipment(txid: String) -> Dictionary:
	for s in status().get("shipments", []):
		if str(s.txid) == txid:
			return s
	return {}


func start_host(mode: String) -> bool:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	seq = 0
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"seq": 0, "cmd": ""}))
	f.close()
	host_proc = spawn("res://tests/net_host.gd", [str(port), str(dport), mode, dir, "3", flags])
	return await until(func(): return status().get("hosting", false), 90.0)


func join() -> bool:
	main.net.join("127.0.0.1", pport, KEY, "Ann", "oak")
	return await until(func(): return main.guest_world and main.net.connected(), 40.0)


## Everyone stood together by the host (net_host "stage"), repeated until the host's record and Ann's copy agree.
func stage() -> void:
	for attempt in 4:
		await command({"cmd": "stage"})
		main.move_to = Vector2.INF
		await wait(0.8)
		var sp: Array = status().get("spot", [])
		if sp.size() != 2:
			continue
		var want := Vector2(float(sp[0]), float(sp[1])) + Vector2(1, 0)
		var hp: Array = rec(ann).get("pos", [0, 0])
		if main.world.player.pos.distance_to(want) < 0.1 and Vector2(float(hp[0]), float(hp[1])).distance_to(want) < 0.1:
			return


## Ann's copy agrees with the host's record of her (purse and the goods named).
func agrees(items: Array) -> bool:
	if main.world == null or main.world.player.coins != coins(ann):
		return false
	for it in items:
		if main.world.player.inv.count(it) != has(ann, it):
			return false
	return true


# ---------------------------------------------------------------- the run ----------------------
func _run() -> void:
	proxy_proc = spawn("res://tests/net_proxy.gd", [str(pport), str(port), dir])
	var up := await start_host("new") and await until(func(): return read_json("proxy_status.json").get("up", false), 20.0)
	check(up, "the host (its world still, the network going) and the relay are up")
	if up and await join():
		check(true, "Ann joins through the relay")
		await _economy("off")
		await _offers()
		await _contract()
		await _lossy()
		await _authority()
		await _dropped()
		await _host_pause()
		await _guest_pause()
		await _leaving()
		await _ownership()
		await _host_crash()
		await _succession()
		# the same with the Living Economy on (its market driving): a new world
		await command({"cmd": "quit"}, false)
		await until(func(): return not main.guest_world, 15.0)
		await until(func(): return not OS.is_process_running(host_proc), 15.0)
		flags = "still,econ"
		if await start_host("new") and await join():
			await _economy("on")
			await _offers()
			await _contract()
			await _authority()
			await _host_crash()
			await _live()
		else:
			check(false, "the host with the economy on, and Ann in it")
	_finish()


func _finish() -> void:
	for p in [host_proc, proxy_proc, bea_proc]:
		if p > 0 and OS.is_process_running(p):
			OS.kill(p)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## The parties set up (from outside the world, before the ledger is first read): Ann and the host with apples and coins, two
## settlement traders with wheat and coins, Bea (economy off) with her own.
func _economy(which: String) -> void:
	ann = main.net.my_pid
	host_pid = int(status().host_pid)
	if which == "off":
		bea_proc = spawn("res://tests/net_fault_guest.gd", [str(port), KEY2, "Bea", "oak", "g2.json", dir])
		check(await until(func(): return bool(read_json("g2.json").get("welcomed", false)) and conn().size() == 2, 60.0), "Bea joins directly (a third process)")
		bea = int(read_json("g2.json").get("pid", 0))
		await command({"cmd": "give_pid", "pid": bea, "id": IT, "n": 6, "coins": 50})
	await stage()
	await command({"cmd": "give_pid", "pid": ann, "id": IT, "n": 30, "coins": 200})
	await command({"cmd": "give_host", "id": IT, "n": 30})
	await command({"cmd": "trader_stock", "k": 0, "id": WH, "n": 40, "coins": 300})
	await command({"cmd": "trader_stock", "k": 1, "id": WH, "n": 10, "coins": 300})
	await until(func(): return agrees([IT]), 5.0)
	var l := await led()
	check(bool(l.get("econ", false)) == (which == "on") and bool(l.get("drive", false)) == (which == "on") and bool(status().get("still", false)),
		"economy %s (market driving: %s); the host's world still while the requests go on" % [which, str(l.get("drive", false))])


# ---------------------------------------------------------------- negotiated offers under repeats -----
func _offers() -> void:
	var net: NetSession = main.net
	var l0 := await led()
	var a_c := coins(ann)
	var a_i := has(ann, IT)
	var h_c := coins(host_pid)
	var h_i := has(host_pid, IT)
	var d0 := int(net_d().get("duplicates", 0))
	var o := await host_offers("sell", IT, 3, 9)
	check(not o.is_empty(), "the host offers Ann 3 apples for 9 coins")
	net.faults = {"dup": true, "reorder": true, "delay_ms": 150}
	var rids := [accept(int(o.id))]
	main.world.player_offer("buy", host_pid, IT, 1, null, 4)
	rids.append(net.last_request())
	main.world.player_offer("gift", host_pid, IT, 1)
	rids.append(net.last_request())
	await wait(1.6)                                    # the reordered pair and the late copies all sent
	net.faults = {}
	var ar := ann_ref()
	await until(func(): return not host_offer("buy", ar).is_empty() and not host_offer("gift", ar).is_empty(), 6.0)
	await command({"cmd": "answer", "id": int(host_offer("buy", ar).get("id", -1))})
	await command({"cmd": "answer", "id": int(host_offer("gift", ar).get("id", -1))})
	await until(func(): return coins(ann) == a_c - 13 and has(ann, IT) == a_i + 3, 6.0)
	await wait(0.5)
	check(coins(ann) == a_c - 13 and has(ann, IT) == a_i + 3 and coins(host_pid) == h_c + 13 and has(host_pid, IT) == h_i - 3,
		"sell, buy and gift, every request sent twice, late and swapped: each done once (Ann %d coins %d apples; host %d coins %d apples)" % [coins(ann) - a_c, has(ann, IT) - a_i, coins(host_pid) - h_c, has(host_pid, IT) - h_i])
	check(rids.all(func(r): return times(ann, r) == 1) and int(net_d().get("duplicates", 0)) > d0,
		"each of Ann's requests applied exactly once (%s), the repeats answered from the record (%d)" % [str(rids.map(func(r): return times(ann, r))), int(net_d().get("duplicates", 0)) - d0])
	check(rids.all(func(r): return net.replies.has(r) and bool(net.replies[r].ok)), "Ann has one answer to each")
	same(l0, await led(), "offers under repeats")
	check(await until(func(): return agrees([IT]), 5.0), "Ann's copy agrees with the host's record of her")


# ---------------------------------------------------------------- a contract: coins set aside, deliveries --
func _contract() -> void:
	var net: NetSession = main.net
	var l0 := await led()
	var h_c := coins(host_pid)
	var a_c := coins(ann)
	var o := await host_offers("contract", IT, 4, 3, 2)
	net.faults = {"dup": true, "delay_ms": 100}
	var r1 := accept(int(o.id))
	await until(func(): return not open_contract().is_empty(), 6.0)
	await wait(0.4)
	var c := open_contract()
	var l1 := await led()
	check(not c.is_empty() and str(c.buyer) == World.PLAYER and str(c.seller) == ann_ref() and int(c.reserved) == 12 and coins(host_pid) == h_c - 12 and times(ann, r1) == 1,
		"Ann accepts the host's contract (sent twice): one contract, the host the buyer, Ann the seller, 12 coins set aside once (%s)" % str(c))
	check(int(l1.reserved) == int(l0.reserved) + 12, "the coins set aside are held by the contract (escrow %d)" % (int(l1.reserved) - int(l0.reserved)))
	same(l0, l1, "contract opened")
	if c.is_empty():
		net.faults = {}
		return
	var a_i := has(ann, IT)
	await until(func(): return not main.world.contracts.get_contract(int(c.id)).is_empty(), 4.0)
	var rids := []
	for k in 2:
		main.world.player_contract_deliver(int(c.id), 2)
		rids.append(net.last_request())
		await wait(0.3)
	await wait(0.6)
	net.faults = {}
	await until(func(): return int(contract(int(c.id)).get("delivered", 0)) >= 4, 6.0)
	await wait(0.4)
	var c2 := contract(int(c.id))
	check(int(c2.delivered) == 4 and int(c2.paid) == 12 and int(c2.reserved) == 0 and has(ann, IT) == a_i - 4 and coins(ann) == a_c + 12 and coins(host_pid) == h_c - 12,
		"two deliveries of 2, each sent twice: 4 delivered once, Ann paid 12 once, nothing left set aside (%s)" % str(c2))
	check(rids.all(func(r): return times(ann, r) == 1), "each delivery request applied exactly once")
	main.world.player_contract_deliver(int(c.id), 2)
	var r3: int = net.last_request()
	await until(func(): return net.replies.has(r3), 4.0)
	check(int(contract(int(c.id)).delivered) == 4 and has(ann, IT) == a_i - 4, "a further delivery on the finished contract moves nothing")
	same(l0, await led(), "contract delivered")
	check(await until(func(): return agrees([IT]), 5.0), "Ann's copy agrees")


# ---------------------------------------------------------------- a lossy, repeating, reordering network --
func _lossy() -> void:
	var net: NetSession = main.net
	var l0 := await led()
	var a_c := coins(ann)
	var a_i := has(ann, IT)
	var r0 := net.reconnects
	await proxy({"loss": 0.2, "dup": 0.2, "reorder": 0.2, "delay_ms": 30, "jitter_ms": 40, "seed": 23})
	var rids := []
	var done := 0
	for i in 3:
		var o := await host_offers("sell", IT, 1, 2)
		if o.is_empty():
			continue
		rids.append(accept(int(o.id)))
		if await until(func(): return has(ann, IT) == a_i + done + 1, 8.0):
			done += 1
	await proxy({})
	await wait(1.0)
	var ps := read_json("proxy_status.json")
	check(done == 3 and has(ann, IT) == a_i + 3 and coins(ann) == a_c - 6 and rids.all(func(r): return times(ann, r) == 1),
		"20%% loss, 20%% repeats, 20%% reordering: three sales, each once (apples +%d, coins %d; relay dropped %d, repeated %d, reordered %d; reconnects %d)" % [has(ann, IT) - a_i, coins(ann) - a_c, int(ps.get("dropped", 0)), int(ps.get("duplicated", 0)), int(ps.get("reordered", 0)), net.reconnects - r0])
	same(l0, await led(), "lossy network")
	check(await until(func(): return agrees([IT]), 6.0), "Ann's copy agrees")


# ---------------------------------------------------------------- the authority with guests as parties --
func _authority() -> void:
	var l0 := await led()
	var a_c := coins(ann)
	var a_w := has(ann, WH)
	var a_i := has(ann, IT)
	var r := await tx({"op": "ship", "txid": "net/ann:1", "buyer": "pid:%d" % ann, "seller": "trader:0", "item": WH, "qty": 5, "total": 15})
	check(bool(r.get("ok", false)) and str(r.state) == "open" and coins(ann) == a_c - 15 and str(r.refs[0]) == ann_ref(),
		"a shipment to Ann: her 15 coins in escrow, the goods in transit custody (buyer %s)" % str(r.get("refs", [])))
	same(l0, await led(), "shipment opened")
	var again := await tx({"op": "ship", "txid": "net/ann:1", "buyer": "pid:%d" % ann, "seller": "trader:0", "item": WH, "qty": 5, "total": 15})
	check(bool(again.get("replay", false)) and coins(ann) == a_c - 15 and shipment("net/ann:1").get("qty", 0) == 5.0,
		"the same shipment asked again (a repeated request): a replay, nothing moves")
	r = await tx({"op": "ship", "txid": "net/ann:2", "buyer": "trader:1", "seller": "pid:%d" % ann, "item": IT, "qty": 2, "total": 6})
	check(bool(r.get("ok", false)) and has(ann, IT) == a_i - 2, "a shipment from Ann: two apples in custody (still hers), the trader's coins in escrow")
	var d1 := await tx({"op": "deliver", "txid": "net/ann:1"})
	var d1b := await tx({"op": "deliver", "txid": "net/ann:1"})
	check(bool(d1.get("ok", false)) and str(d1b.get("code", "")) == "duplicate" and has(ann, WH) == a_w + 5, "delivered once to Ann (the repeat a duplicate): 5 wheat in her pack")
	var f2 := await tx({"op": "fail", "txid": "net/ann:2"})
	var f2b := await tx({"op": "deliver", "txid": "net/ann:2"})
	check(bool(f2.get("ok", false)) and str(f2b.get("code", "")) == "not_open" and has(ann, IT) == a_i and coins(ann) == a_c - 15,
		"the other failed: the apples back to Ann, the trader refunded; a late delivery of it refused")
	r = await tx({"op": "ship", "txid": "net/ann:4", "buyer": "pid:%d" % ann, "seller": "trader:0", "item": WH, "qty": 1, "total": 3})
	var late := await tx({"op": "ship", "txid": "net/ann:3", "buyer": "pid:%d" % ann, "seller": "trader:0", "item": WH, "qty": 1, "total": 3})
	check(bool(r.get("ok", false)) and not bool(late.get("ok", true)) and str(late.get("code", "")) == "stale_id" and coins(ann) == a_c - 18,
		"a delayed older id after a newer one: refused (stale), nothing moves")
	await tx({"op": "deliver", "txid": "net/ann:4"})
	same(l0, await led(), "shipments with Ann")
	check((status().get("shipments", []) as Array).is_empty(), "no shipment left open")
	await until(func(): return agrees([IT, WH]), 5.0)
	check(agrees([IT, WH]), "Ann's copy agrees")


# ---------------------------------------------------------------- a request lost in a dropped connection --
func _dropped() -> void:
	var net: NetSession = main.net
	var l0 := await led()
	var a_c := coins(ann)
	var a_i := has(ann, IT)
	var o := await host_offers("sell", IT, 2, 5)
	await proxy({"blackhole": true})
	var rid := accept(int(o.id))                       # sent into the void: the connection is gone before ENet gets it through
	var lost := await until(func(): return net.reconnecting, 25.0)
	await until(func(): return bool(rec(ann).get("away", false)), 15.0)
	same(l0, await led(), "connection lost with an answer in flight")
	await proxy({})
	var back := await until(func(): return in_game(), 40.0)
	await wait(0.6)
	var n := times(ann, rid)
	check(lost and back and n <= 1 and (n == 0 or (has(ann, IT) == a_i + 2 and coins(ann) == a_c - 5)) and (n == 1 or (has(ann, IT) == a_i and coins(ann) == a_c)),
		"the answer sent as the connection died: applied %d time(s), all or nothing (apples %+d, coins %+d); Ann back by herself" % [n, has(ann, IT) - a_i, coins(ann) - a_c])
	same(l0, await led(), "after the reconnection")
	check(await until(func(): return agrees([IT]), 5.0), "Ann's copy is the host's again")
	var d0 := int(net_d().get("duplicates", 0))
	var c0 := coins(ann)
	net.rpc_id(1, "c_request", rid, "verb", {"path": "player_answer", "a": [int(o.id), true]})
	await wait(0.8)
	check(times(ann, rid) == n and coins(ann) == c0 and int(net_d().get("duplicates", 0)) == d0 + 1, "the same request number sent again after the reconnection: not applied")
	var left: Array = (status().get("offers", []) as Array).filter(func(x): return int(x.id) == int(o.id))
	if n == 0 and not left.is_empty():
		var rid2 := accept(int(o.id))
		await until(func(): return times(ann, rid2) == 1, 5.0)
		await wait(0.3)
		check(times(ann, rid2) == 1 and has(ann, IT) == a_i + 2 and coins(ann) == a_c - 5, "answered again under a new number: done once")
	same(l0, await led(), "dropped connection")


# ---------------------------------------------------------------- an Android host paused -------------
func _host_pause() -> void:
	var net: NetSession = main.net
	var l0 := await led()
	var a_c := coins(ann)
	var o := await host_offers("sell", IT, 1, 3)
	await command({"cmd": "suspend", "secs": 3.0}, false)
	await wait(0.6)
	net.faults = {"dup": true}
	var rid := accept(int(o.id))
	net.faults = {}
	var done := await until(func(): return times(ann, rid) >= 1, 15.0)
	await wait(0.8)
	check(done and times(ann, rid) == 1 and coins(ann) == a_c - 3 and in_game(), "an answer (sent twice) while the host's app was frozen: applied once when it came back")
	same(l0, await led(), "host paused")


# ---------------------------------------------------------------- an Android guest paused -------------
func _guest_pause() -> void:
	var net: NetSession = main.net
	var l0 := await led()
	var a_c := coins(ann)
	var res0 := int(net_d().get("resumes", 0))
	var o := await host_offers("sell", IT, 1, 3)
	var rid := accept(int(o.id))
	await until(func(): return net.replies.has(rid), 6.0)
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await proxy({"blackhole": true})
	main.process_mode = Node.PROCESS_MODE_DISABLED
	await wait(5.0)
	await proxy({})
	main.process_mode = Node.PROCESS_MODE_INHERIT
	main._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var back := await until(func(): return in_game() and int(net_d().get("resumes", 0)) > res0, 30.0)
	check(back and times(ann, rid) == 1 and coins(ann) == a_c - 3, "Ann's app paused after a purchase and resumed: back with her token, the purchase applied once")
	var d0 := int(net_d().get("duplicates", 0))
	net.rpc_id(1, "c_request", rid, "verb", {"path": "player_answer", "a": [int(o.id), true]})
	await until(func(): return int(net_d().get("duplicates", 0)) > d0, 3.0)
	check(times(ann, rid) == 1 and coins(ann) == a_c - 3 and int(net_d().get("duplicates", 0)) == d0 + 1, "the purchase's request repeated across the resumed connection: answered from the record, not applied")
	same(l0, await led(), "guest paused")
	check(await until(func(): return agrees([IT]), 5.0), "Ann's copy agrees")


# ---------------------------------------------------------------- guests leaving mid-transaction -------
func _leaving() -> void:
	var net: NetSession = main.net
	var l0 := await led()
	var b_c := coins(bea)
	var b_w := has(bea, WH)
	var b_i := has(bea, IT)
	var s1 := await tx({"op": "ship", "txid": "net/bea:1", "buyer": "pid:%d" % bea, "seller": "trader:0", "item": WH, "qty": 4, "total": 12})
	var s2 := await tx({"op": "ship", "txid": "net/bea:2", "buyer": "trader:1", "seller": "pid:%d" % bea, "item": IT, "qty": 3, "total": 9})
	check(bool(s1.get("ok", false)) and bool(s2.get("ok", false)) and coins(bea) == b_c - 12 and has(bea, IT) == b_i - 3, "Bea in two shipments: her coins in escrow, her apples in transit")
	OS.kill(bea_proc)
	var gone := await until(func(): return not conn().has(bea) and bool(rec(bea).get("away", false)), 25.0)
	check(gone, "Bea's game killed mid-transaction: the host drops her (away, every record kept)")
	same(l0, await led(), "Bea gone with two shipments open")
	var d := await tx({"op": "deliver", "txid": "net/bea:1"})
	var f := await tx({"op": "fail", "txid": "net/bea:2"})
	check(bool(d.get("ok", false)) and bool(f.get("ok", false)) and has(bea, WH) == b_w + 4 and has(bea, IT) == b_i and coins(bea) == b_c - 12,
		"both close while she is away: the wheat she paid for is hers, her apples back with her (coins %+d, wheat %+d, apples %+d)" % [coins(bea) - b_c, has(bea, WH) - b_w, has(bea, IT) - b_i])
	same(l0, await led(), "shipments closed for an absent guest")
	# Ann leaves with a contract open (the host's coins set aside for her apples), comes back, and delivers
	var o := await host_offers("contract", IT, 2, 4, 3)
	var r1 := accept(int(o.id))
	await until(func(): return not open_contract().is_empty(), 6.0)
	var c := open_contract()
	var a_c := coins(ann)
	main.leave_guest_world("")
	var away := await until(func(): return bool(rec(ann).get("away", false)), 10.0)
	var cl := contract(int(c.get("id", -1)))
	check(away and str(cl.get("state", "")) == "accepted" and int(cl.get("reserved", 0)) == 8, "Ann leaves with the contract open: it stays open, the host's 8 coins still set aside (%s)" % str(cl))
	same(l0, await led(), "Ann gone with a contract open")
	check(await join(), "Ann comes back")
	var d0 := int(net_d().get("duplicates", 0))
	net.rpc_id(1, "c_request", r1, "verb", {"path": "player_answer", "a": [int(o.id), true]})
	await wait(0.8)
	check(times(ann, r1) == 1 and int(net_d().get("duplicates", 0)) == d0 + 1, "her acceptance repeated from before she left: not applied again")
	await stage()
	await until(func(): return not main.world.contracts.get_contract(int(c.id)).is_empty(), 4.0)
	main.world.player_contract_deliver(int(c.id), 2)
	await until(func(): return int(contract(int(c.id)).get("delivered", 0)) == 2, 6.0)
	check(int(contract(int(c.id)).get("paid", 0)) == 8 and coins(ann) == a_c + 8, "she delivers: paid the 8 coins once")
	same(l0, await led(), "guests leaving")


# ---------------------------------------------------------------- ownership: a contract not one's own ----
func _ownership() -> void:
	var net: NetSession = main.net
	var l0 := await led()
	# the host supplies Ann (the host the seller, Ann the buyer, her coins set aside)
	var o := await host_offers("supply", IT, 2, 2, 2)
	accept(int(o.id))
	await until(func(): return not open_contract().is_empty() and str(open_contract().seller) == World.PLAYER, 6.0)
	var c := open_contract()
	var h_i := has(host_pid, IT)
	var rid := net.request("verb", {"path": "contracts.deliver", "a": [{"$r": "contract", "k": int(c.get("id", -1))}, 2, null]})
	await until(func(): return net.replies.has(rid), 5.0)
	await wait(0.3)
	check(has(host_pid, IT) == h_i and int(contract(int(c.get("id", -1))).get("delivered", -1)) == 0,
		"Ann's crafted request to hand over the host's goods on a contract she buys under is refused: the host's pack untouched (%d -> %d apples; %s)" % [h_i, has(host_pid, IT), str(net.replies.get(rid, {}).get("text", ""))])
	same(l0, await led(), "a crafted delivery")
	await until(func(): return not main.world.contracts.get_contract(int(c.id)).is_empty(), 4.0)
	main.world.contracts.cancel(main.world.contracts.get_contract(int(c.id)), main.world.acting_ref())
	await until(func(): return str(contract(int(c.id)).get("state", "")) != "accepted", 5.0)
	check(str(contract(int(c.id)).get("state", "")) == "cancelled" and int(contract(int(c.id)).get("reserved", -1)) == 0, "Ann, the buyer, ends it herself: her coins come back")
	# a villager's offer to the host: Ann may not take it up (or turn it down) for the host
	await command({"cmd": "npc_offer", "item": IT, "qty": 2, "price": 3, "days": 2})
	var cid := int(str(status().get("why_last", "-1")))
	var ra := net.request("verb", {"path": "contracts.accept_offer", "a": [{"$r": "contract", "k": cid}]})
	var rd := net.request("verb", {"path": "contracts.decline_offer", "a": [{"$r": "contract", "k": cid}]})
	await until(func(): return net.replies.has(ra) and net.replies.has(rd), 5.0)
	await wait(0.3)
	var raw := _contract_state(cid)
	check(cid >= 0 and raw == "offered", "Ann's crafted acceptance and refusal of the villager's offer to the host are refused: still the host's to answer (%s)" % raw)
	same(l0, await led(), "ownership")


## A contract's state on the host, any parties (net_host status lists player contracts; a villager's offer to the host is one).
func _contract_state(cid: int) -> String:
	for x in status().get("contracts", []):
		if int(x.id) == cid:
			return str(x.state)
	return "(gone)"


# ---------------------------------------------------------------- the host killed and restored ---------
func _host_crash() -> void:
	var net: NetSession = main.net
	await stage()
	var s := await tx({"op": "ship", "txid": "net/crash:1", "buyer": "pid:%d" % ann, "seller": "trader:0", "item": WH, "qty": 3, "total": 9, "days": 3})
	var o := await host_offers("contract", IT, 2, 5, 3)
	accept(int(o.id))
	await until(func(): return not open_contract().is_empty() and int(open_contract().reserved) == 10, 6.0)
	var c := open_contract()
	check(bool(s.get("ok", false)) and not c.is_empty(), "a shipment to Ann (escrow) and a contract (the host's coins set aside) open")
	await command({"cmd": "save"})
	var l_save := await led()
	var a_c := coins(ann)
	var a_i := has(ann, IT)
	var a_w := has(ann, WH)
	var o2 := await host_offers("sell", IT, 1, 3)
	var rid := accept(int(o2.id))
	await until(func(): return times(ann, rid) == 1, 6.0)
	check(coins(ann) == a_c - 3, "after the save Ann buys an apple (applied: coins %+d)" % (coins(ann) - a_c))
	var r0 := net.reconnects
	OS.kill(host_proc)
	check(await until(func(): return net.reconnecting, 20.0), "the host killed: Ann waits for it")
	host_proc = -1
	seq = 0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "status.json"))
	var f := FileAccess.open(dir + "cmd.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"seq": 0, "cmd": ""}))
	f.close()
	host_proc = spawn("res://tests/net_host.gd", [str(port), str(dport), "continue", dir, "3", flags])
	var back := await until(func(): return in_game() and net.reconnects > r0, 90.0)
	check(back and net.my_pid == ann, "the host restored from its save: Ann back by herself, the same character")
	var l_load := await led()
	same(l_save, l_load, "the restored world against the save")
	check(int(l_load.get("open", 0)) == int(l_save.get("open", -1)) and int(l_load.get("reserved", 0)) == int(l_save.get("reserved", -1)),
		"the open shipments (%d) and the coins set aside (%d) as saved" % [int(l_load.get("open", 0)), int(l_load.get("reserved", 0))])
	var sh := shipment("net/crash:1")
	check(str(sh.get("buyer", "")) == ann_ref() and str(sh.get("seller", "")).begins_with("region:") and str(sh.get("state", "")) == "open",
		"the shipment kept its buyer (Ann) and seller (the trader), still open")
	check(coins(ann) == a_c and has(ann, IT) == a_i, "the purchase after the save is undone with the rest of the unsaved moment, nothing half-kept (coins %d = %d)" % [coins(ann), a_c])
	await until(func(): return agrees([IT, WH]), 5.0)
	check(agrees([IT, WH]), "Ann's copy is the restored host's")
	var d0 := int(net_d().get("duplicates", 0))
	net.rpc_id(1, "c_request", rid, "verb", {"path": "player_answer", "a": [int(o2.id), true]})
	await wait(0.8)
	check(times(ann, rid) == 0 and coins(ann) == a_c, "her request from before the crash, sent again to the restored host: not applied (duplicates %+d)" % (int(net_d().get("duplicates", 0)) - d0))
	var rep := await tx({"op": "ship", "txid": "net/crash:1", "buyer": "pid:%d" % ann, "seller": "trader:0", "item": WH, "qty": 3, "total": 9, "days": 3})
	check(bool(rep.get("replay", false)) and coins(ann) == a_c, "the shipment asked again after the restore: a replay, nothing moves")
	var d := await tx({"op": "deliver", "txid": "net/crash:1"})
	var dd := await tx({"op": "deliver", "txid": "net/crash:1"})
	check(bool(d.get("ok", false)) and str(dd.get("code", "")) == "duplicate" and has(ann, WH) == a_w + 3, "delivered once after the restore")
	await stage()
	await until(func(): return not main.world.contracts.get_contract(int(c.id)).is_empty(), 4.0)
	main.world.player_contract_deliver(int(c.id), 2)
	await until(func(): return int(contract(int(c.id)).get("delivered", 0)) == 2, 6.0)
	check(int(contract(int(c.id)).get("paid", 0)) == 10 and coins(ann) == a_c + 10, "the contract saved open is delivered and paid once")
	same(l_save, await led(), "host crash and restore")
	check((status().get("shipments", []) as Array).is_empty(), "no shipment left open")


# ---------------------------------------------------------------- death and succession ----------------
func _succession() -> void:
	var net: NetSession = main.net
	await stage()
	var ref := ann_ref()
	await tx({"op": "ship", "txid": "net/heir:1", "buyer": "pid:%d" % ann, "seller": "trader:0", "item": WH, "qty": 2, "total": 6})
	await tx({"op": "ship", "txid": "net/heir:2", "buyer": "trader:1", "seller": "pid:%d" % ann, "item": IT, "qty": 2, "total": 6})
	var o := await host_offers("contract", IT, 2, 2, 3)
	accept(int(o.id))
	await until(func(): return not open_contract().is_empty(), 6.0)
	var c := open_contract()
	var l1 := await led()
	check(int(l1.get("open", 0)) == 2 and not c.is_empty(), "Ann in two shipments (escrow, transit) and a contract")
	var players0 := (status().players as Dictionary).size()
	await command({"cmd": "kill_guest"})
	check(await until(func(): return not bool(rec(ann).get("alive", true)), 6.0), "Ann dies")
	same(l1, await led(), "Ann dead (what she had lies with her)")
	var dead := ann
	net.faults = {"dup": true}
	var rid := net.request("heir", {})
	net.faults = {}
	var got := await until(func(): return net.my_pid != dead and main.world.player.alive, 10.0)
	await wait(0.8)
	ann = net.my_pid
	var hr := rec(ann)
	check(got and str(hr.get("ref", "")) == ref and times(dead, rid) == 1 and (status().players as Dictionary).size() == players0,
		"the heir asked for twice: one heir, carrying the line's reference %s (players %d -> %d)" % [str(hr.get("ref", "")), players0, (status().players as Dictionary).size()])
	var l2 := await led()
	var kit_c := int(hr.get("coins", 0))
	var exp: Dictionary = l1.duplicate(true)
	exp.coins = int(l1.coins) + kit_c
	for k in hr.get("inv", {}):
		exp.goods[k] = int(exp.goods.get(k, 0)) + int(hr.inv[k])
	same(exp, l2, "the succession (the heir's starting kit the only addition)")
	check(str(contract(int(c.get("id", -1))).get("state", "")) == "cancelled" and int(l2.reserved) == int(l1.reserved) - 4,
		"the dead's contract ended: the host's 4 coins set aside came back")
	var h_w := has(ann, WH)
	var h_i := has(ann, IT)
	var d := await tx({"op": "deliver", "txid": "net/heir:1"})
	var f := await tx({"op": "fail", "txid": "net/heir:2"})
	check(bool(d.get("ok", false)) and bool(f.get("ok", false)) and has(ann, WH) == h_w + 2 and has(ann, IT) == h_i + 2,
		"the shipments close to the heir under the line's reference: the wheat paid for and the apples sent come to the family")
	same(exp, await led(), "succession")
	check((status().get("shipments", []) as Array).is_empty(), "no shipment left open")


# ---------------------------------------------------------------- the world running, the market driving --
func _live() -> void:
	var net: NetSession = main.net
	await command({"cmd": "still", "on": false})
	await stage()
	var l0 := await led()
	var a_c := coins(ann)
	var a_i := has(ann, IT)
	var h_c := coins(host_pid)
	var h_i := has(host_pid, IT)
	await proxy({"loss": 0.1, "dup": 0.2, "reorder": 0.2, "delay_ms": 20, "jitter_ms": 30, "seed": 5})
	var done := 0
	var rids := []
	for i in 3:
		await command({"cmd": "clear_villagers"})
		var o := await host_offers("sell", IT, 1, 2)
		if o.is_empty():
			continue
		net.faults = {"dup": true}
		rids.append(accept(int(o.id)))
		net.faults = {}
		if await until(func(): return has(ann, IT) == a_i + done + 1, 8.0):
			done += 1
	await proxy({})
	await wait(0.8)
	var l1 := await led()
	await command({"cmd": "still", "on": true})
	check(done == 3 and has(ann, IT) == a_i + 3 and coins(ann) == a_c - 6 and has(host_pid, IT) == h_i - 3 and coins(host_pid) == h_c + 6 and rids.all(func(r): return times(ann, r) == 1),
		"the world running and the market driving, a lossy network and every answer sent twice: three sales, each once")
	var leak := (int(l1.village) - int(l1.flow_in)) - (int(l0.village) - int(l0.flow_in))
	check(leak == 0 and str(l1.get("audit", "x")) == "" and float(l1.minutes) > float(l0.minutes),
		"the village's currency ledger balances while it ran (%.0f game minutes; leak %d), the regional books too" % [float(l1.minutes) - float(l0.minutes), leak])
