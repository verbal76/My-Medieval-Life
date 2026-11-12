class_name NetPrivacy
extends RefCounted
## MML-MP-07 (owner 2026-11-08, register B25-AUD-MP-07; docs/directives/2026-11-08_recovered_owner_messages.md "MP-07 — Multiplayer
## privacy"): "Criminal history, debts, relationships, private knowledge, personal history, and comparable personal information are not
## shared automatically ... The host must not expose private information through network snapshots, saved-state transfers, or
## synchronization packets. Privacy enforcement must apply to transmitted data, not merely to what the interface displays." Only assets
## are shareable, under the MP-05 mutual-consent tiers; an asset-sharing agreement grants no private information.
##
## The host filters what it sends each guest (the welcome, NetSession.world_for, and every section sync, NetSession.send_syncs) by
## recipient: `filter` takes a World.to_dict `d` (a shallow copy the caller owns: only its top-level keys are replaced, nothing nested
## is changed, so the host's world and the other guests' copies are untouched) and the recipient's player reference. What it removes is
## another player's: ties and trade contacts with anyone (Relations), killings count, debts, villagers' asks and refusals (Credit), crime
## cases open or closed (Justice), contracts (Contracts), stored goods in their chests, carts and homestead houses unless the MP-05 tier
## shares them (Chests, Carts, Homesteads), law lessons, the ties kept for their heir (tie_history), their prospecting samples
## and the assays only they know, what they know of prices (economy knowledge); and the villagers' judgment store
## (read on the host only). What stays: the public world, the recipient's own records whole, every record between villagers, and the
## other players' public look (NetSession.public_player) and their assets as the map shows them (buildings, carts, pens, plots).
## The player-to-player offers, sharing pairs and kept messages were filtered already (X20, MP-05); they are here too.
## Villagers' own knowledge (an NPC's memory and report) stays: it is the ordinary gameplay channel through which players learn of one
## another, as of villagers (the owner's rule), and the guest's conversations read it.

const PLAYER := "player"


## Filter `d` for the guest whose reference is `ref` (World.player_ref). `w`: the host's world (players, sharing tiers, holders).
static func filter(d: Dictionary, ref: String, w: World = null) -> void:
	var me_id := World.id_of_ref(ref) if ref != "" else 0
	if d.has("asset_shares"):
		var visible := {}
		for pair in d.asset_shares:
			if str(pair).split("|").has(ref):
				visible[pair] = d.asset_shares[pair]
		d["asset_shares"] = visible
	if d.has("player_offers"):
		var po: Dictionary = d.player_offers
		var mine: Array = (po.get("list", []) as Array).filter(func(o): return str(o["from"]) == ref or str(o.to) == ref)
		d["player_offers"] = {"next": po.get("next", 1), "list": mine}
	if d.has(MessageJournal.KEY):
		var mj: Dictionary = d[MessageJournal.KEY]
		if mj.has(ref):
			d[MessageJournal.KEY] = {ref: mj[ref]}
		else:
			d.erase(MessageJournal.KEY)
	if d.get("relations") is Dictionary:
		d["relations"] = _relations(d.relations, ref, me_id)
	if d.get("credit") is Dictionary:
		d["credit"] = _credit(d.credit, ref)
	if d.get("justice") is Dictionary:
		var j: Dictionary = d.justice
		var cases := {}
		for k in j.get("cases", {}):
			if not _other(str(k), ref):
				cases[k] = j.cases[k]
		d["justice"] = {"cases": cases, "closed": (j.get("closed", []) as Array).filter(func(c): return not _other(str(c.get("offender", "")), ref))}
	if d.get("contracts") is Dictionary:
		var ct: Dictionary = (d.contracts as Dictionary).duplicate(false)
		ct["list"] = (ct.get("list", []) as Array).filter(func(c): return _party_ok(str(c.get("buyer", "")), str(c.get("seller", "")), ref))
		d["contracts"] = ct
	if d.get("chests") is Dictionary and w != null:
		var ch: Dictionary = (d.chests as Dictionary).duplicate(false)
		var st := {}
		for uid in ch.get("stash", {}):
			var holder := _unit_holder(w, str(uid))
			if not _other(holder, ref) or w.asset_share_tier(holder, ref) > 0:
				st[uid] = ch.stash[uid]
		ch["stash"] = st
		d["chests"] = ch
	if d.get("carts") is Dictionary:
		var ca: Dictionary = (d.carts as Dictionary).duplicate(false)
		ca["carts"] = _loads(ca.get("carts", []) as Array, ref, w, 3)      # a cart stands on the map; its load is its owner's
		d["carts"] = ca
	if d.get("homesteads") is Dictionary:
		var hs: Dictionary = (d.homesteads as Dictionary).duplicate(false)
		hs["claims"] = _loads(hs.get("claims", []) as Array, ref, w, 1)
		d["homesteads"] = hs
	if d.get("prospecting") is Dictionary:
		d["prospecting"] = _prospecting(d.prospecting, ref)
	if d.get(EconomyFoundation.KEY) is Dictionary and (d[EconomyFoundation.KEY] as Dictionary).get("knowledge") is Dictionary:
		var ec: Dictionary = (d[EconomyFoundation.KEY] as Dictionary).duplicate(false)
		var kn: Dictionary = (ec.knowledge as Dictionary).duplicate(false)
		var strs: Array = kn.get("strings", [])
		kn["rows"] = (kn.get("rows", []) as Array).filter(func(r): return (r as Array).is_empty() or int(r[0]) >= strs.size() or not _other(str(strs[int(r[0])]), ref))
		ec["knowledge"] = kn                                 # what each knows of prices (EconKnowledge, column 0 the knower): another player's is theirs
		d[EconomyFoundation.KEY] = ec
	d.erase("judgment")                                     # the villagers' judgment store is read on the host only
	if d.get("law_lessons") is Dictionary:
		var ll: Dictionary = d.law_lessons
		if ll.has(ref):
			d["law_lessons"] = {ref: ll[ref]}
		else:
			d.erase("law_lessons")
	if d.get("tie_history") is Dictionary:
		var keep := {}
		var p: PlayerState = w.player_of_ref(ref) if w != null else null
		for k in d.tie_history:
			if p != null and (str(k) == str(p.pid) or (p.line > 0 and str(k) == str(p.line))):
				keep[k] = d.tie_history[k]
		if keep.is_empty():
			d.erase("tie_history")
		else:
			d["tie_history"] = keep


## Whether reference `x` names a player other than the recipient `ref`.
static func _other(x: String, ref: String) -> bool:
	return World.is_player_ref(x) and x != ref


## A record between two parties stays unless another player is a party and the recipient is not.
static func _party_ok(a: String, b: String, ref: String) -> bool:
	if a == ref or b == ref:
		return true
	return not _other(a, ref) and not _other(b, ref)


## A person id (Relations: "a:b" keys) of a player other than the recipient (`me_id`).
static func _other_id(id: int, me_id: int) -> bool:
	return Life.is_player_id(id) and id != me_id


static func _pair_ok(k: String, me_id: int) -> bool:
	var ids := k.split(":")
	if ids.size() != 2:
		return true
	if int(ids[0]) == me_id or int(ids[1]) == me_id:
		return true                                         # the recipient's own (with a villager or another player)
	return not _other_id(int(ids[0]), me_id) and not _other_id(int(ids[1]), me_id)


static func _relations(r: Dictionary, ref: String, me_id: int) -> Dictionary:
	var o := r.duplicate(false)
	var ties := {}
	for k in r.get("ties", {}):
		if _pair_ok(str(k), me_id):
			ties[k] = r.ties[k]
	o["ties"] = ties
	var tr := {}
	for k in r.get("trades", {}):
		if _pair_ok(str(k), me_id):
			tr[k] = r.trades[k]
	o["trades"] = tr
	var ins := {}
	for k in r.get("interests", {}):
		if not _other_id(int(k), me_id) and not _other_id(int(r.interests[k]), me_id):
			ins[k] = r.interests[k]
	o["interests"] = ins
	if ref != PLAYER:
		o["killings"] = 0                                   # the host's own count
	if r.has("guest_killings"):
		var gk: Dictionary = r.guest_killings
		if gk.has(ref):
			o["guest_killings"] = {ref: gk[ref]}
		else:
			o.erase("guest_killings")
	return o


static func _credit(c: Dictionary, ref: String) -> Dictionary:
	var o := c.duplicate(false)
	o["debts"] = (c.get("debts", []) as Array).filter(func(x): return _party_ok(str(x.get("creditor", "")), str(x.get("debtor", "")), ref))
	if c.has("requests"):
		o["requests"] = (c.requests as Array).filter(func(x): return str(x.get("to", PLAYER)) == ref)
	if c.has("refused") and ref != PLAYER:
		o["refused"] = {}                                   # the host's own refusals (a guest's are under refused_by)
	if c.has("refused_by"):
		var rb: Dictionary = c.refused_by
		if rb.has(ref):
			o["refused_by"] = {ref: rb[ref]}
		else:
			o.erase("refused_by")
	return o


## Prospecting (MIN-C): another player's samples in hand and the assays only they know (where ore lies is private knowledge until
## told); the cells sampled stay (the ground shows them).
static func _prospecting(pr: Dictionary, ref: String) -> Dictionary:
	var o := pr.duplicate(false)
	var bags := {}
	var mine := []
	for h in pr.get("bags", {}):
		if not _other(str(h), ref):
			bags[h] = pr.bags[h]
			mine.append_array((pr.bags[h] as Array).map(func(x): return str(int(x))))
	o["bags"] = bags
	var sm := {}
	for k in pr.get("samples", {}):
		if not _other(str(pr.samples[k].get("by", "")), ref) or mine.has(str(k)):
			sm[k] = pr.samples[k]
	o["samples"] = sm
	o["records"] = (pr.get("records", []) as Array).filter(func(r): return (r.get("known_by", []) as Array).has(ref) or not (r.get("known_by", []) as Array).any(func(x): return _other(str(x), ref)))
	return o


## Records with an owner and a "store" (carts, homestead claims): another player's keeps its record, its store emptied, unless the
## MP-05 tier between them is at least `tier`.
static func _loads(list: Array, ref: String, w: World, tier: int) -> Array:
	var out := []
	for c in list:
		var owner := str(c.get("owner", ""))
		if _other(owner, ref) and (w == null or w.asset_share_tier(owner, ref) < tier):
			out.append((c as Dictionary).merged({"store": {}}, true))
		else:
			out.append(c)
	return out


## Whose a storage unit is (a player reference, a household's, or ""): its building's holder (Chests.info).
static func _unit_holder(w: World, uid: String) -> String:
	var bid := ""
	if uid.begins_with("chest:"):
		bid = uid.split(":")[1]
	else:
		var c: Dictionary = w.container(uid)
		if not c.is_empty():
			bid = str(c.get("at", ""))
	if bid == "" or not w.buildings.has(bid):
		return ""
	return w.holder_of(w.buildings[bid])
