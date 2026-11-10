extends SceneTree
## JUS-02 (Build 25 audit, docs/audits/2026-11-08_build25_master_audit_register.md): a villager who runs off to the bandits
## (LifeDecisions._join_band) leaves the village's life as a migrant does: the same existing clean-up (no new policy). Before,
## household, job and plan were changed in place and nothing else: an employment record, a market stall's tenancy and an open
## contract stayed attached to someone no longer in the village's life. Coins and goods are conserved.
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
	player_home(w)
	w.player.coins += 500
	var m: NPC = null
	var buyer: NPC = null
	var hand: NPC = null
	for n: NPC in w.npcs:
		if not n.alive or n.role != "adult" or n.household < 0 or n.job == "guard":
			continue
		if hand == null and n.job in Construction.HIRABLE and w.employment.refusal(n) == "":
			hand = n
		elif buyer == null and n.job == "farmer":
			buyer = n
		elif m == null and n.job != "farmer" and not (n.job in Construction.HIRABLE):
			m = n
	var ok := m != null and buyer != null and hand != null and not w.stalls.is_empty()
	check(ok, "fixture: a stall-holder, a buyer and someone to employ")
	if not ok:
		quit(1)
		return
	var sid: String = (w.stalls.keys() as Array)[0]
	w.set_tenant(w.stalls[sid], World.npc_ref(m.id))
	m.workplace = sid
	var stall: String = m.workplace
	m.inv.add("bread", 3)
	buyer.coins = maxi(buyer.coins, 400)
	var ct: Dictionary = w.contracts._new_record(World.npc_ref(buyer.id), World.npc_ref(m.id), "bread", 3, 4, 5, [])
	check(w.contracts._open(ct) and w.contracts.is_open(ct), "fixture: the stall-holder owes bread on an open contract")
	check(w.employment.employ(hand, "miner") == "" and w.employment.is_employed(hand), "fixture: the player employs another villager")
	var c0 := w.total_coins()
	w.life._join_band(m, true)
	w.life._join_band(hand, true)
	check(m.role == "bandit" and hand.role == "bandit", "fixture: both have joined the band")
	check(w.tenant_of(w.stalls[stall]) != World.npc_ref(m.id), "the stall is no longer let to a bandit")
	check(not w.contracts.is_open(ct), "the contract no longer stands on someone gone to the band (state %s)" % str(ct.state))
	check(not w.employment.is_employed(hand), "the employment ended")
	check(w.total_coins() == c0, "no coin made or lost (%d -> %d)" % [c0, w.total_coins()])
	w.dispose()
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)


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
