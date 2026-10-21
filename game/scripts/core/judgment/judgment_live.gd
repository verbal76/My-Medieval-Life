class_name JudgmentLive
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19): the provisional adapter between the live World and the judgment prototype.
## OFF by default: World.judgment is null unless judgment.json "enabled" is true (it is false) or a test attaches a
## store (attach). Every hook in live code is one guarded line, `if judgment != null`, so with it off the game runs
## exactly as before (proved by the determinism gate, tools/sim_gate.py, and the existing suites).
##
## What it connects, and what it leaves alone:
##   observation   World.witness (a theft seen, PAR-05's one channel for seeing), World.raise_alarm (an attack by
##                 anyone, the player or a villager), World.kill (a villager slain by the player): the same `seen`
##                 lists become an event's witnesses. Who sees, and what guards do, is unchanged.
##   conversation  Relations.share (an hour two people spend together) lets them tell each other what they know.
##   the day       World._new_day: memories fade, old events retire.
##   saving        World.to_dict/load_dict: a "judgment" section only when a store is attached (SAVE_VERSION unchanged).
##   one choice    NPCBrain._buyer_for (whom a villager sells to): the prototype of the first live domain (SJD-Q14
##                 open; the reconciliation recommends trade). The live code still finds who can buy; judgment only
##                 weighs among them (JudgmentWeighting).


const LIVE_ORDER_STEP := 10000      # live_order: 100 points for the live rule's first choice, 10 less for each after


static func enabled() -> bool:
	return bool(JudgmentStore.default_cfg().get("enabled", false))


## Attach a judgment store to `w` (reading kinship and friendship from the live world). Returns it.
static func attach(w, config: Dictionary = {}) -> JudgmentStore:
	var j := JudgmentStore.new(config, Social.new(w), int(w.seed))
	j.day = w.day()
	w.judgment = j
	return j


## The live world's kinship and friendship, read on demand: nothing is copied (spec invariant 7).
class Social extends JudgmentSocial:
	var w

	func _init(world) -> void:
		w = world

	func kin(a: int, b: int) -> bool:
		var pa = Life.parent_of(w, a)
		var pb = Life.parent_of(w, b)
		if pa == null or pb == null:
			return false
		if int(pa.partner) == b or int(pb.partner) == a:
			return true
		return Life.kin(a, int(pa.mother), int(pa.father), b, int(pb.mother), int(pb.father))

	func friends(a: int, b: int) -> bool:
		return w.relations.friends(a, b)


static func _ids(people: Array) -> Array:
	var out := []
	for n in people:
		if n is NPC and n.role != "bandit":
			out.append(n.id)
	return out


## A theft seen (World.witness): the thief is the player (World.witness is the player's channel today).
static func on_theft(w, kind: String, victim: NPC, seen: Array, value: int) -> void:
	var type := "pickpocket" if kind == "pickpocket" else "theft"
	var ev: int = w.judgment.publish(type, [Life.PLAYER_ID], [victim.id] if victim != null else [], [], value)
	if ev > 0:
		w.judgment.observe_all(ev, _ids(seen))


## An attack (World.raise_alarm): anyone's, the player's (-2) or a villager's (a bandit's robbery included).
static func on_attack(w, attacker: int, aware: Dictionary) -> void:
	var v: NPC = aware.get("victim", null)
	var ev: int = w.judgment.publish("assault", [attacker], [v.id] if v != null else [])
	if ev > 0:
		w.judgment.observe_all(ev, _ids(aware.seen))


## A villager slain by the player (World.kill): those who see the body fall.
static func on_killing(w, n: NPC, killer: int) -> void:
	var ev: int = w.judgment.publish("killing", [killer], [n.id])
	if ev > 0:
		var seen: Array = w.near(n.pos, float(GameData.b("witness_radius")))
		seen.erase(n)
		w.judgment.observe_all(ev, _ids(seen))


## Prototype of the first live domain: whom villager `n` sells `id` to. The candidates are exactly the live rule's
## (OUTLETS order, NPCBrain buy roles, World.purchase_qty, the one rule for every sale); judgment weighs among them
## with the live order of preference (live_order), the seller's need for coin and the price each would pay (trade_sell
## profile; price weighs 0 until calibrated), so with every judgment neutral the live choice stands and any change is
## judgment's. Returns the buyer or null.
static func pick_buyer(w, brain, n: NPC, id: String) -> NPC:
	var cands := []
	var people := {}
	var top := 1
	for outlet in NPCBrain.OUTLETS.get(id, []):
		for b in brain._with_buy_role(outlet):
			if b == n or not b.alive or people.has(b.id):
				continue
			var q: int = w.purchase_qty(b, n, id, maxi(1, n.inv.count(id)))
			if q <= 0:
				continue
			var unit := int(w.sale_prices(b, n, id, 1)[0])
			top = maxi(top, unit)
			people[b.id] = b
			cands.append({"id": b.id, "counterparty": b.id, "unit": unit})
	if cands.is_empty():
		return null
	var need := JudgmentMath.clampi_((50 - n.coins) * 2000, 0, 100000)      # under 50 coins a seller needs the sale more
	for i in cands.size():
		var c: Dictionary = cands[i]
		c.factors = {"live_order": maxi(0, 100000 - LIVE_ORDER_STEP * i), "necessity": need, "price": JudgmentMath.mul_div(int(c.unit), 100000, top)}
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, n.id, "trade_sell", cands, [w.day(), id.hash()])
	w.judgment._stat("trade_choices")
	if r.chosen == null or not people.has(r.chosen):
		return null
	if int(r.chosen) != int(cands[0].id):
		w.judgment._stat("trade_choices_changed")         # judgment moved the choice from the live rule's first pick
	return people[r.chosen]
