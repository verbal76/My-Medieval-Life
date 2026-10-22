extends SceneTree
## PROSPECTIVE (Expansion 18, X18-Q13; PROS-18): small agreements need no signatures; formal contracts and ownership
## transfers need every party's signature, face to face or before a travelling notary courier; no remote, instant
## signing; incomplete, rejected, interrupted and completed agreements; the notary's fee held and paid or returned with
## every coin accounted. Smoke tests of the owner's 2026-10-21 rules on a real seeded village; not wired into the game.
##   godot --headless --path game --script res://tests/contract_sign_test.gd

var checks := 0
var failures := 0
var w: World
var rg: Regions
var cs: CourierService
var fa: FormalAgreements


func check(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("ok   " + what)
	else:
		failures += 1
		print("FAIL: " + what)


func _init() -> void:
	GameData.ensure()
	w = World.new()
	w.setup(VillageMap.load_default(), 1)
	cs = CourierService.new(w)
	fa = FormalAgreements.new(cs)
	var keeper: NPC = w.npcs.filter(func(n): return n.alive and w.construction.can_hire(n) == "")[0]
	keeper.inv.add("plank", 3)                       # fixture: planks for a booth stall if no market stall is free
	var free := ""
	for sid in w.stalls:
		if str(w.stalls[sid].get("tenant", "")) == "":
			free = sid
	cs.open_booth("npc:%d" % keeper.id, free)
	rg = Regions.create(1)
	rg.by_id["wulstead"].trader().till = 300             # fixture: Wulstead's trader holds 300 coins
	rg.by_id["wulstead"].reopen_books()
	var east := rg.party("wulstead/trader")
	cs.open_region_booth(east)
	cs.links = TradeRoutes.table([SettlementLedger.make({"id": "village"}), east], [["village", "wulstead", 900, {"road": 1.0}]])
	test_classes()
	test_face_to_face()
	test_no_remote_signing()
	test_notary()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func adults() -> Array:
	return w.npcs.filter(func(n): return n.alive and n.role == "adult" and n.job in ["", "laborer", "manor_hand", "farmer", "woodcutter", "miner"])


func ref(n: NPC) -> String:
	return "npc:%d" % n.id


func coins() -> int:
	return w.total_coins() + cs.held_coins() + cs.regions["wulstead/trader"].purse()


func test_classes() -> void:
	var a: NPC = adults()[1]
	var b: NPC = adults()[2]
	var small := fa.draft("commercial", [ref(a), ref(b)], 20)
	check(str(small.class) == "small" and fa.binding(small) and small.signatures.is_empty(), "a small agreement (20 coins) is binding without signatures")
	check(fa.sign_face_to_face(small, ref(a), ref(b)) != "", "and asks for none")
	var big := fa.draft("commercial", [ref(a), ref(b)], 400)
	check(str(big.class) == "formal" and not fa.binding(big), "a formal commercial contract (400 coins) is not binding until signed")
	var own := fa.draft("ownership", [ref(a), ref(b)], 5)
	check(str(own.class) == "formal", "an ownership transfer always needs signatures, however small")


func test_face_to_face() -> void:
	var a: NPC = adults()[1]
	var b: NPC = adults()[2]
	var ag := fa.draft("ownership", [ref(a), ref(b)], 150)
	a.pos = Vector2(40.5, 66.5)
	b.pos = Vector2(60.5, 66.5)
	check(fa.sign_face_to_face(ag, ref(a), ref(b)) != "" and not fa.binding(ag), "apart, they cannot sign together (incomplete)")
	b.pos = a.pos + Vector2(1, 0)
	check(fa.sign_face_to_face(ag, ref(a), ref(b)) == "" and fa.binding(ag) and str(ag.state) == "signed", "standing together they sign without a notary: binding")


func test_no_remote_signing() -> void:
	var a: NPC = adults()[1]
	var b: NPC = adults()[2]
	var ag := fa.draft("commercial", [ref(a), ref(b)], 300)
	check(fa.sign(ag, ref(a)) == "" and not fa.binding(ag), "the holder signs its copy; one signature is not enough (incomplete)")
	check(fa.sign(ag, ref(b)) != "" and not ag.signatures.has(ref(b)), "the other party cannot sign a document it does not hold: no remote, instant signing")
	check(fa.sign(ag, "region:wulstead/trader") != "", "nor can someone who is not a party")


func test_notary() -> void:
	var a: NPC = adults()[1]
	var notary: NPC = adults()[3]
	var plain: NPC = adults()[4]
	var c: Dictionary = CourierService.cfg().notary
	var ag := fa.draft("commercial", [ref(a), "region:wulstead/trader"], 500)
	a.coins += 50
	notary.skills[str(c.skill)] = Skills.xp_for_level(int(c.min_level))       # fixture: a courier with the provisional legal standing
	plain.skills[str(c.skill)] = 0
	check(fa.send_with_notary(ag, ref(plain), ref(a), "region:wulstead/trader") != "", "a courier without legal standing cannot notarise (provisional check: %s %d)" % [str(c.skill), int(c.min_level)])
	var before := coins()
	check(fa.send_with_notary(ag, ref(notary), ref(a), "region:wulstead/trader") == "" and str(ag.state) == "with_notary" and str(ag.holder) == ref(notary),
		"sent with a qualified notary: the sender signs before it, it carries the document; the fee is held at the booth")
	check(coins() == before, "holding the fee moves coins, creates none")
	check(fa.sign(ag, "region:wulstead/trader") != "", "Wulstead cannot sign before the notary arrives")
	fa.tick(float(ag.due) - 0.01)
	check(not ag.signatures.has("region:wulstead/trader"), "nothing is signed while the document is on the road")
	fa.tick(float(ag.due) + 0.01)
	check(ag.signatures.has("region:wulstead/trader") and not fa.binding(ag), "the notary arrives and Wulstead signs; not binding until the document is back")
	var n0 := notary.coins
	fa.tick(float(ag.back) + 0.01)
	check(fa.binding(ag) and str(ag.holder) == ref(a) and notary.coins - n0 == int(ag.fee), "back with both signatures: the contract is complete; the notary is paid its fee (%d)" % int(ag.fee))
	check(coins() == before, "every coin accounted for")
	var lw: Dictionary = CourierService.cfg().law
	check(int(notary.skills.law) == Skills.xp_for_level(int(c.min_level)) + 2 * int(lw.witness_xp) + int(lw.carry_xp),
		"LAW-SKILL: the notary learned from it: two signatures witnessed and a document carried home (Law %d xp)" % int(notary.skills.law))
	# rejected
	var rj := fa.draft("ownership", [ref(a), "region:wulstead/trader"], 80)
	rj.refuse = true
	a.coins += 20
	fa.send_with_notary(rj, ref(notary), ref(a), "region:wulstead/trader")
	fa.tick(float(rj.due) + 0.01)
	fa.tick(float(rj.back) + 0.01)
	check(str(rj.state) == "rejected" and not fa.binding(rj) and str(rj.holder) == ref(a), "Wulstead refuses: the document comes back unsigned by it; rejected, not binding")
	# interrupted
	var it := fa.draft("ownership", [ref(a), "region:wulstead/trader"], 80)
	a.coins += 20
	var a0 := a.coins
	var before2 := coins()
	fa.send_with_notary(it, ref(notary), ref(a), "region:wulstead/trader")
	w.kill(notary, "waylaid on the road")
	fa.tick(float(it.due) + 0.01)
	check(str(it.state) == "interrupted" and not fa.binding(it) and a.coins == a0, "the notary is waylaid: the agreement is interrupted, incomplete; the held fee goes back")
	check(coins() == before2, "and every coin is still accounted for")
