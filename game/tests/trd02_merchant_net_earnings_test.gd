extends SceneTree
## TRD-02 (owner decision 2026-11-08, docs/directives/2026-11-09_overnight_autonomous_development.md): a merchant's recorded
## earnings from a market-stall session are the actual net proceeds (the sale less the stall's commission), not the gross.
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
	var st: Stalls = w.business.stalls
	var s: Dictionary = w.stalls.stall0
	var m: NPC = w.party(w.tenant_of(s))
	check(m != null and m.job == "merchant" and st.is_merchant_stall(s), "fixture: stall0 is a merchant's")
	m.pos = Vector2(int(s.use[0]) + 0.5, int(s.use[1]) + 0.5)
	m.target = -1
	m.anim = "idle"
	var buyer: NPC = null
	for o: NPC in w.npcs:
		if o.alive and o.role == "adult" and o != m and o.job != "merchant":
			buyer = o
			break
	buyer.coins = 500
	var item := ""
	for id in m.inv.ids():
		if buyer.inv.can_add(id) and GameData.value(id) > 0:
			item = id
			break
	m.inv.add(item, 30)
	var e0 := m.earned
	var c0 := w.total_coins()
	var frac0 := int(s.get("frac", 0))
	check(w.trade(buyer, m, item, 4, 10), "the merchant sells 4 at 10 at the stall")
	m.pos = Vector2(5, 5)
	st.hour()                                            # the merchant left the stall: the session settles
	var commission := (40 * st.pct() + frac0) / 100
	check(commission > 0, "fixture: the stall took a commission (%d)" % commission)
	check(m.earned == e0 + 40 - commission, "recorded earnings are the net %d, not the gross 40 (earned %d -> %d)" % [40 - commission, e0, m.earned])
	check(w.total_coins() == c0, "no coin made or lost")
	var e1 := m.earned
	check(w.trade(buyer, m, item, 1, 10) and m.earned == e1 + 10, "away from the stall a sale pays no commission: its whole price is earned")
	print("%d checks, %d failures" % [checks, fails])
	quit(1 if fails > 0 else 0)
