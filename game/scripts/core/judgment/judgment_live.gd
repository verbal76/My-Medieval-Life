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
##   choices       Q14 (owner, 2026-10-21): judgment is one weighted influence inside the EXISTING decision points, by
##                 the one shared interface (JudgmentWeighting.choose); the live code still decides who is feasible:
##                   trade_sell      NPCBrain._buyer_for     whom a villager sells to
##                   trade_buy_from  NPCBrain._seller_of     whom a household buys timber from
##                   hire_choice     Construction._keep_building   whom a building household hires to carry
##                   work_accept     Construction.hire, Business.hire  whether a villager takes the work offered
##                   befriend        Relations._befriend_if_close  whether close villagers become friends
##                   court_choice    Relations._villagers_court    whom a single villager takes an interest in
##                 each on only with a store attached and its decision.integration flag set; feasibility (stock,
##                 coins, purchase_qty, can_hire, can_court, regard thresholds) and conservation are never overridden.


static var shortcut := true          # tests turn it off to compare with the full scan
const LIVE_ORDER_STEP := 10000      # live_order: 100 points for the live rule's first choice, 10 less for each after


## Whether decision point `domain` consults judgment: a store attached and decision.integration[domain] set.
static func on(w, domain: String) -> bool:
	if w == null or w.judgment == null:
		return false
	return bool((w.judgment.cfg.decision.get("integration", {}) as Dictionary).get(domain, false))


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

	## Q06: trust in a teller reuses the existing relationship number, Relations' regard (one tie a pair), 0..100.
	func regard(a: int, b: int) -> int:
		return roundi(float(w.relations.peek(a, b).regard))


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


## Round 2 (cost): whether the live rule's first pick must win whatever the other candidates are, so the full scan can
## be skipped with the same result. True only under the shipped trade_sell form (argmax, no per-person spread, only
## live_order, necessity and disposition weighed; necessity is the same for every candidate): another buyer can win
## only by a disposition advantage worth more than live_order's step, and no other can have a disposition above the
## best the seller holds of anyone in their ledger (or 50, for someone they have no opinion of).
static func _first_stands(j: JudgmentStore, seller: int, first: int, profile := "trade_sell") -> bool:
	var dc: Dictionary = j.cfg.decision
	var wt: Dictionary = dc.profiles[profile].weights
	if str(dc.selection) != "argmax" or int(dc.get("trait_spread_permille", 0)) > 0:
		return false
	for k in wt:
		if not (str(k) in ["live_order", "necessity", "disposition"]) and int(wt[k]) != 0:
			return false
	var wd := int(wt.get("disposition", 0))
	var wo := int(wt.get("live_order", 0))
	var d0 := j.disposition(seller, first)
	var best := int(dc.disposition_mid)
	for s in (j.ledgers.get(seller, {}) as Dictionary):
		if int(s) != first:
			best = maxi(best, j.disposition(seller, int(s)))
	var gain := JudgmentMath.mul_div(wd, best, 1000) - JudgmentMath.mul_div(wd, d0, 1000)
	var step := JudgmentMath.mul_div(wo, 100000, 1000) - JudgmentMath.mul_div(wo, 100000 - LIVE_ORDER_STEP, 1000)
	return gain <= step


## Prototype of the first live domain: whom villager `n` sells `id` to. The candidates are exactly the live rule's
## (OUTLETS order, NPCBrain buy roles, World.purchase_qty, the one rule for every sale); judgment weighs among them
## with the live order of preference (live_order), the seller's need for coin and the price each would pay (trade_sell
## profile; price weighs 0 until calibrated), so with every judgment neutral the live choice stands and any change is
## judgment's. Returns the buyer or null.
static func pick_buyer(w, brain, n: NPC, id: String) -> NPC:
	var t := Time.get_ticks_usec()
	var b := _pick_buyer(w, brain, n, id)
	var tm: Dictionary = w.judgment.timing
	tm.trade_us = int(tm.get("trade_us", 0)) + Time.get_ticks_usec() - t
	return b


static func _pick_buyer(w, brain, n: NPC, id: String) -> NPC:
	var first: NPC = null                     # the live rule's own pick: the first who can buy, in OUTLETS order
	for outlet in NPCBrain.OUTLETS.get(id, []):
		for b in brain._with_buy_role(outlet):
			if b != n and b.alive and w.purchase_qty(b, n, id, maxi(1, n.inv.count(id))) > 0:
				first = b
				break
		if first != null:
			break
	if first == null:
		return null
	if shortcut and _first_stands(w.judgment, n.id, first.id, "trade_sell"):
		w.judgment._stat("trade_choices")
		w.judgment._stat("trade_shortcut")
		return first
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



# ---------------------------------------------------------------- Q14: the other existing decision points ------------
## Among `people` (in the live rule's own order of preference), the one `chooser` picks under `profile`: the live order
## and the chooser's judgment of each (plus any `extra` factors per person id). With every judgment neutral the live
## rule's first stands. null when `people` is empty.
static func _pick(w, chooser: int, people: Array, profile: String, key: Array, extra := {}) -> NPC:
	if people.is_empty():
		return null
	if extra.is_empty() and shortcut and _first_stands(w.judgment, chooser, people[0].id, profile):
		w.judgment._stat(profile + "_choices")
		return people[0]
	var cands := []
	for i in people.size():
		var o: NPC = people[i]
		var f := {"live_order": maxi(0, 100000 - LIVE_ORDER_STEP * i)}
		for k in extra.get(o.id, {}):
			f[k] = extra[o.id][k]
		cands.append({"id": o.id, "counterparty": o.id, "factors": f})
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, chooser, profile, cands, key)
	w.judgment._stat(profile + "_choices")
	for o in people:
		if r.chosen != null and o.id == int(r.chosen):
			if o != people[0]:
				w.judgment._stat(profile + "_changed")
			return o
	return people[0]


## trade_buy_from (NPCBrain._seller_of): whom household member `buyer` buys `id` from. The candidates are the live
## rule's, in its order: carpenters and raw-goods merchants with stock, then (for logs) woodcutters with logs.
static func pick_seller(w, brain, id: String, buyer: NPC) -> NPC:
	var people := []
	for o: NPC in w.npcs:
		if o.alive and o != buyer and not w.asleep(o) and (o.job == "carpenter" or brain.buy_role(o) == "merchant_raw") and o.inv.has(id):
			people.append(o)
	if id == "log":
		for o: NPC in w.npcs:
			if o.alive and o != buyer and not w.asleep(o) and o.job == "woodcutter" and o.inv.has(id):
				people.append(o)
	return _pick(w, buyer.id, people, "trade_buy_from", [w.day(), id.hash()])


## hire_choice (Construction._keep_building): whom household `h` hires to carry for its house. The candidates are the
## live rule's (hirable, of another household, in villager order) who would take the work (work_refusal); the choice
## is the household's responsible adult's.
static func pick_helper(w, h: int, wage: int) -> NPC:
	var boss: NPC = w.construction.responsible_adult(h)
	var people := []
	for o: NPC in w.npcs:
		if o.household != h and w.construction.can_hire(o) == "":
			if boss == null or work_refusal(w, o, boss.id, wage) == "":
				people.append(o)
	if boss == null:
		return people[0] if not people.is_empty() else null
	return _pick(w, boss.id, people, "hire_choice", [w.day(), h])


## work_accept (Construction.hire, Business.hire): why `worker` turns down work for `employer` (a person id: the player
## -2, or a household's responsible adult), or "": they weigh their need for coin (under 50 coins), the wage, and what
## they think of the employer against doing without (work_accept profile). With a neutral judgment they always accept
## (the live rule); a strong dislike can make someone with enough coin refuse; need outweighs dislike.
static func work_refusal(w, worker: NPC, employer: int, wage: int) -> String:
	if not on(w, "work_accept") or worker == null or employer == worker.id:
		return ""
	var need := JudgmentMath.clampi_((50 - worker.coins) * 2000, 0, 100000)
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, worker.id, "work_accept",
			[{"id": "accept", "counterparty": employer, "factors": {"necessity": need, "wage": 100000 if wage > 0 else 0}}], [w.day(), employer])
	w.judgment._stat("work_offers")
	if str(r.chosen) == "accept":
		return ""
	w.judgment._stat("work_refused")
	return "%s would rather not work for %s." % [worker.name, "you" if employer == Life.PLAYER_ID else "them"]


## befriend (Relations._befriend_if_close): whether two villagers whose regard has reached befriend_at become friends:
## closeness (regard) weighed with what each thinks of the other (the lower of the two). With neutral judgments they
## always do (the live rule); a dislike can hold back a friendship that is only just close enough; great closeness
## outweighs it. Positive judgment never makes friends of people not close enough (the live threshold stands).
static func befriend_ok(w, a: int, b: int, regard: float) -> bool:
	if not on(w, "befriend"):
		return true
	var j: JudgmentStore = w.judgment
	var disp := mini(j.disposition(a, b), j.disposition(b, a))
	var at := float(Relations.cfg().befriend_at)
	var wt: Dictionary = j.cfg.decision.profiles.befriend.weights
	var u := JudgmentMath.mul_div(int(wt.closeness), roundi(clampf(regard, 0.0, 100.0) * 1000.0), 1000) + JudgmentMath.mul_div(int(wt.disposition), disp, 1000)
	var bar := JudgmentMath.mul_div(int(wt.closeness), roundi(at * 1000.0), 1000) + JudgmentMath.mul_div(int(wt.disposition), int(j.cfg.decision.disposition_mid), 1000)
	j._stat("befriend_checks")
	if u >= bar:
		return true
	j._stat("befriend_held_back")
	return false


## court_choice (Relations._villagers_court): whom single villager `n` takes an interest in, among the live rule's
## candidates (those they may court and have come to know, attraction at least interest_at), in its order: attraction
## weighed with what `n` thinks of each. With neutral judgments the most attractive (the first of equals) stands.
static func pick_court(w, n: NPC, people: Array, attraction: Dictionary) -> NPC:
	if people.is_empty():
		return null
	var cands := []
	for o: NPC in people:
		cands.append({"id": o.id, "counterparty": o.id, "factors": {"attraction": roundi(clampf(float(attraction[o.id]), 0.0, 100.0) * 1000.0)}})
	var r := JudgmentWeighting.choose(w.judgment, w.judgment.cfg, n.id, "court_choice", cands, [w.day(), n.id])
	w.judgment._stat("court_choices")
	for o: NPC in people:
		if r.chosen != null and o.id == int(r.chosen):
			return o
	return people[0]
