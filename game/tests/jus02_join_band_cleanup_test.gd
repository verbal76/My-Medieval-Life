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
	var m: NPC = null
	var buyer: NPC = null
	var hand: NPC = null
	for n: NPC in w.npcs:
		if not n.alive or n.role != "adult" or n.household < 0:
			continue
		if m == null and w.stalls.has(n.workplace) and w.tenant_of(w.stalls[n.workplace]) == World.npc_ref(n.id):
			m = n
		elif buyer == null and n.job == "farmer":
			buyer = n
		elif hand == null and n.job in Construction.HIRABLE and w.employment.refusal(n, "miner") == "":
			hand = n
	check(m != null and buyer != null and hand != null, "fixture: a stall-holder, a buyer and someone to employ")
	var stall: String = m.workplace
	m.inv.add("bread", 3)
	buyer.coins = maxi(buyer.coins, 400)
	var ct: Dictionary = w.contracts._new_record(World.npc_ref(buyer.id), World.npc_ref(m.id), "bread", 3, 4, 5, [])
	check(w.contracts._open(ct) and w.contracts.is_open(ct), "fixture: the stall-holder owes bread on an open contract")
	w.player.coins += 2000
	check(w.employment.employ(hand) == "" and w.employment.is_employed(hand), "fixture: the player employs another villager")
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
