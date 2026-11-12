extends SceneTree
## MML-MP-07 (owner 2026-11-08, register B25-AUD-MP-07): private records are never shared automatically between players. The host's
## welcome (NetSession.welcome_view, as world_for sends it) and its section syncs (NetSession._private_for before NetSync.changed) give
## a guest the public world, its own records whole and the other players' public look only: none of another player's ties, trade
## contacts, killings, debts, villagers' asks or refusals, crime cases, contracts, stored goods (unless the MP-05 tier shares them), law
## lessons, heir's ties or kept messages, and not the villagers' judgment store. The host's world is unchanged; the view is
## deterministic; the guest loads it; an asset-sharing agreement shares assets, never private records.
var checks := 0
var failures := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


func _guest(w: World, name: String, fam: String) -> PlayerState:
	var g := PlayerState.new()
	g.name = name
	g.family = fam
	g.sex = "female"
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = name.to_lower().left(1).repeat(32)
	w.add_guest(g)
	g.pos = w.player.pos
	return g


## A built house with a chest, let to `ref` (World.holder_of: the tenant), not anyone's home (its chest a stash unit, Chests.info).
func _house(w: World, ref: String, taken: Array) -> String:
	var ids: Array = w.buildings.keys()
	ids.sort()
	for bid in ids:
		var b: Dictionary = w.buildings[bid]
		if taken.has(bid) or str(b.get("type", "")) != "house" or w.chests.units_in(str(bid)).is_empty():
			continue
		b["tenant"] = ref
		taken.append(bid)
		return str(bid)
	return ""


static func _ids(k: String) -> Array:
	return Array(k.split(":")).map(func(s): return int(s))


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8807)
	var ann := _guest(w, "Ann", "Miller")
	var bran := _guest(w, "Bran", "Smith")
	var aref: String = w.player_ref(ann)
	var bref: String = w.player_ref(bran)
	var aid: int = w.person_id(ann)
	var bid: int = w.person_id(bran)
	var hid: int = w.person_id(w.host_player())
	var vs: Array = w.npcs.filter(func(n): return n.alive and n.role == "adult")
	var v1: NPC = vs[0]
	var v2: NPC = vs[1]
	var v3: NPC = vs[2]
	# -- private records of each player
	w.relations.tie(bid, v1.id).regard = 7.0
	w.relations.tie(aid, v1.id).regard = 3.0
	w.relations.tie(hid, v2.id).regard = 5.0
	w.relations.tie(aid, bid).regard = 1.0                     # Ann's own tie with Bran: hers too
	w.relations.tie(v1.id, v2.id).regard = 2.0                  # between villagers
	w.relations.note_trade(bid, v1.id, 1)
	w.relations.note_trade(aid, v2.id, 1)
	w.relations.interests[v3.id] = bid
	w.relations.killings = 3
	w.relations.guest_killings = {bref: 2, aref: 1}
	var dn := 0
	for pair in [[World.npc_ref(v1.id), bref], [World.npc_ref(v1.id), aref], [World.PLAYER, World.npc_ref(v2.id)], [World.npc_ref(v2.id), World.npc_ref(v3.id)], [bref, aref]]:
		dn += 1
		w.credit.debts.append({"id": 900 + dn, "creditor": pair[0], "debtor": pair[1], "item": "bread", "qty": 1, "value": 4, "made": 1, "due": 9, "state": "open", "ended": -1})
	w.credit.requests = [{"id": 1, "npc": v1.id, "item": "bread", "qty": 1, "mode": "credit", "give": "", "value": 4, "day": 1, "give_qty": 0, "to": bref},
		{"id": 2, "npc": v2.id, "item": "bread", "qty": 1, "mode": "credit", "give": "", "value": 4, "day": 1, "give_qty": 0, "to": aref},
		{"id": 3, "npc": v3.id, "item": "bread", "qty": 1, "mode": "credit", "give": "", "value": 4, "day": 1, "give_qty": 0}]
	w.credit.refused = {v1.id: 5}
	w.credit.refused_by = {bref: {v2.id: 5}, aref: {v3.id: 5}}
	w.justice.record(bref, "theft", v1, v1.pos, 1)
	w.justice.record(aref, "theft", v2, v2.pos, 1)
	w.justice.record(World.PLAYER, "assault", v3, v3.pos, 1)
	w.contracts.list.append({"id": 9001, "buyer": bref, "seller": World.npc_ref(v1.id), "item": "bread", "qty": 2, "price_each": 3, "days": 4, "deadline_day": 9, "state": "offered", "delivered": 0, "paid": 0, "reserved": 0, "made_day": 1, "history": []})
	w.contracts.list.append({"id": 9002, "buyer": aref, "seller": World.npc_ref(v2.id), "item": "bread", "qty": 2, "price_each": 3, "days": 4, "deadline_day": 9, "state": "offered", "delivered": 0, "paid": 0, "reserved": 0, "made_day": 1, "history": []})
	w.contracts.list.append({"id": 9003, "buyer": World.npc_ref(v2.id), "seller": World.npc_ref(v3.id), "item": "bread", "qty": 2, "price_each": 3, "days": 4, "deadline_day": 9, "state": "offered", "delivered": 0, "paid": 0, "reserved": 0, "made_day": 1, "history": []})
	var taken := []
	var hb := _house(w, bref, taken)
	var ha := _house(w, aref, taken)
	check(hb != "" and ha != "" and w.holder_of(w.buildings[hb]) == bref and w.holder_of(w.buildings[ha]) == aref, "setup: Bran and Ann each hold a house")
	var ub: String = str(w.chests.units_in(hb)[0].id)
	var ua: String = str(w.chests.units_in(ha)[0].id)
	w.chests.stash[ub] = Inventory.new()
	w.chests.stash[ub].add("log", 4)
	w.chests.stash[ua] = Inventory.new()
	w.chests.stash[ua].add("log", 2)
	var cb: Dictionary = w.carts.place(bref, w.player.pos)
	(cb.store as Inventory).add("log", 3)
	var ca: Dictionary = w.carts.place(aref, w.player.pos)
	(ca.store as Inventory).add("log", 1)
	w.law_lessons = {bref: [1, 2], aref: [1, 1]}
	w.tie_history = {str(bran.pid): {"day": 1, "ties": {}}, str(ann.pid): {"day": 1, "ties": {}}}
	w.messages.by_ref[bref] = [[0, "note", "Bran's private note"]]
	w.messages.by_ref[aref] = [[0, "note", "Ann's own note"]]
	if w.judgment == null:
		w.judgment_foreign = {"facts": ["about Bran"]}       # a judgment section the host writes: never sent
	w.prospecting.samples["9101"] = {"id": 9101, "clue": "c1", "x": 1, "y": 1, "by": bref, "skill": 0, "day": 1}
	w.prospecting.samples["9102"] = {"id": 9102, "clue": "c1", "x": 2, "y": 1, "by": aref, "skill": 0, "day": 1}
	w.prospecting.bags[bref] = [9101]
	w.prospecting.bags[aref] = [9102]
	w.prospecting.records.append({"id": 9201, "sample": 9100, "clue": "c1", "x": 3, "y": 1, "ore": "iron_ore", "grade": 2, "confidence": 0.8, "by": bref, "assayer": World.npc_ref(v1.id), "day": 1, "known_by": [bref, World.npc_ref(v1.id)]})
	w.prospecting.records.append({"id": 9202, "sample": 9099, "clue": "c1", "x": 4, "y": 1, "ore": "", "grade": 0, "confidence": 0.8, "by": aref, "assayer": World.npc_ref(v1.id), "day": 1, "known_by": [aref, World.npc_ref(v1.id)]})
	var econ_on: bool = w.economy != null
	if econ_on:
		econ_on = w.economy.knowledge.learn(bref, World.npc_ref(v1.id), "bread", EconKnowledge.SELLS, 5)
		econ_on = econ_on and w.economy.knowledge.learn(aref, World.npc_ref(v2.id), "bread", EconKnowledge.SELLS, 6)
		econ_on = econ_on and w.economy.knowledge.learn(World.npc_ref(v3.id), World.npc_ref(v1.id), "bread", EconKnowledge.SELLS, 5)
	bran.coins = 77
	bran.inv.add("bread", 5)

	var before := JSON.stringify(w.to_dict(), "", true)
	var d: Dictionary = NetSession.welcome_view(w, ann.pid)
	var again: Dictionary = NetSession.welcome_view(w, ann.pid)
	check(JSON.stringify(w.to_dict(), "", true) == before, "the host's world is unchanged by building a guest's view")
	check(JSON.stringify(d, "", true) == JSON.stringify(again, "", true), "a guest's view is deterministic")
	var host_d := w.to_dict()
	# -- relations
	var ties: Dictionary = d.relations.ties
	check(not ties.keys().any(func(k): return (_ids(k).has(bid) or _ids(k).has(hid)) and not _ids(k).has(aid)), "no tie of Bran's or the host's with anyone else in Ann's view (relationships are private)")
	check(ties.has(Relations.key(aid, v1.id)) and ties.has(Relations.key(aid, bid)), "Ann's own ties stay, her tie with Bran among them")
	var npc_ties: int = host_d.relations.ties.keys().filter(func(k): return _ids(k).all(func(i): return i >= 0)).size()
	check(npc_ties > 0 and ties.keys().filter(func(k): return _ids(k).all(func(i): return i >= 0)).size() == npc_ties, "every tie between villagers stays (%d)" % npc_ties)
	check(not (d.relations.trades as Dictionary).keys().any(func(k): return _ids(k).has(bid)) and (d.relations.trades as Dictionary).has(Relations.key(aid, v2.id)), "trade contacts: Bran's gone, Ann's own stay")
	check(not (d.relations.interests as Dictionary).values().any(func(x): return int(x) == bid), "no villager's courting of Bran")
	check(int(d.relations.killings) == 0 and d.relations.get("guest_killings", {}) == {aref: 1}, "killings: the host's and Bran's withheld, Ann's own kept")
	# -- credit
	var debts: Array = d.credit.debts
	check(not debts.any(func(x): return (str(x.creditor) in [bref, World.PLAYER] or str(x.debtor) in [bref, World.PLAYER]) and not aref in [str(x.creditor), str(x.debtor)]), "no debt of Bran's or the host's with others in Ann's view")
	check(debts.any(func(x): return str(x.debtor) == aref and str(x.creditor) != bref) and debts.any(func(x): return str(x.creditor) == bref and str(x.debtor) == aref), "Ann's own debts stay, the one between her and Bran included")
	check(debts.any(func(x): return not World.is_player_ref(str(x.creditor)) and not World.is_player_ref(str(x.debtor))), "debts between villagers stay")
	check((d.credit.requests as Array).size() == 1 and str(d.credit.requests[0].get("to", "")) == aref, "villagers' asks: only those put to Ann")
	check((d.credit.get("refused", {}) as Dictionary).is_empty() and d.credit.get("refused_by", {}).keys() == [aref], "refusals: only Ann's own")
	# -- justice
	var cases: Dictionary = d.get("justice", {}).get("cases", {})
	check(not cases.has(bref) and not cases.has(World.PLAYER), "no crime case of Bran's or the host's (criminal history is private)")
	check(cases.has(aref), "Ann's own case stays")
	check(not (d.get("justice", {}).get("closed", []) as Array).any(func(c): return str(c.offender) in [bref, World.PLAYER]), "no closed case of another player's")
	# -- contracts
	var cl: Array = d.contracts.list
	check(not cl.any(func(c): return str(c.buyer) == bref or str(c.seller) == bref or ((str(c.buyer) == World.PLAYER or str(c.seller) == World.PLAYER) and not aref in [str(c.buyer), str(c.seller)])), "no contract of Bran's or the host's")
	check(cl.any(func(c): return int(c.id) == 9002) and cl.any(func(c): return int(c.id) == 9003), "Ann's own contract and the villagers' stay")
	# -- stored goods (assets, unshared)
	check(not (d.chests.stash as Dictionary).has(ub) and (d.chests.stash as Dictionary).has(ua), "chest goods: Bran's unshared chest withheld, Ann's own kept")
	var vc: Dictionary = (d.carts.carts as Array).filter(func(c): return int(c.id) == int(cb.id))[0]
	var vca: Dictionary = (d.carts.carts as Array).filter(func(c): return int(c.id) == int(ca.id))[0]
	check(str(vc.owner) == bref and Inventory.from_dict(vc.store).total() == 0 and Inventory.from_dict(vca.store).count("log") == 1, "Bran's cart stands in Ann's view (owner, place) with its load withheld; Ann's cart load kept")
	# -- welcome-only sections
	check(host_d.has("judgment") and not d.has("judgment"), "the villagers' judgment store is not sent")
	check(d.get("law_lessons", {}) == {aref: [1, 1]}, "law lessons: Ann's own only")
	check(d.get("tie_history", {}).keys() == [str(ann.pid)], "heir's ties: Ann's own only")
	check(d.get(MessageJournal.KEY, {}).keys() == [aref], "kept messages: Ann's own only")
	var pr: Dictionary = d.prospecting
	check(not pr.bags.has(bref) and not pr.samples.has("9101") and not (pr.records as Array).any(func(r): return int(r.id) == 9201), "prospecting: Bran's samples and the assay only he knows withheld (private knowledge)")
	check(pr.bags.has(aref) and pr.samples.has("9102") and (pr.records as Array).any(func(r): return int(r.id) == 9202), "prospecting: Ann's own samples and assays kept")
	if econ_on:
		var kn: Dictionary = d[EconomyFoundation.KEY].knowledge
		var knowers: Array = (kn.rows as Array).map(func(r): return str(kn.strings[int(r[0])]))
		check(not knowers.has(bref) and not knowers.has(World.PLAYER) and knowers.has(aref) and knowers.has(World.npc_ref(v3.id)), "price knowledge: Bran's and the host's withheld, Ann's own and the villagers' kept")
	else:
		check(false, "price knowledge: the economy is on and records what players and villagers know (setup)")
	# -- players: Bran's public look, Ann whole
	var pb: Dictionary = d.players.by_pid[str(bran.pid)]
	var pa: Dictionary = d.players.by_pid[str(ann.pid)]
	check(pb.has("pos") and pb.has("appearance") and str(pb.get("name", "")) == "Bran" and int(pb.get("coins", 0)) == 0 and JSON.stringify(pb).find("bread") < 0, "Bran's public record: name, look and place; no purse or pack")
	check(int(pa.get("coins", -1)) == ann.coins, "Ann's own record comes whole")
	for k in ["buildings", "stalls", "plots", "households", "npcs", "trees", "fields", "treasury", "fauna"]:
		check(JSON.stringify(d.get(k)) == JSON.stringify(host_d.get(k)), "public section %s is the host's" % k)
	# -- the guest loads it
	var copy := World.new()
	copy.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(d)))
	var me := copy.player_by_pid(ann.pid)
	check(copy.load_error == "" and me != null, "Ann's machine loads the view")
	if me != null:
		copy.set_local_player(me)
		check(copy.credit.request_for(v2.id).size() == 1 and copy.justice.case_of(aref).size() > 0 and copy.justice.case_of(bref).is_empty(), "her copy reads her own ask and case, and none of Bran's")
		check(float(copy.relations.peek(bid, v1.id).regard) == 0.0 and float(copy.relations.peek(aid, v1.id).regard) == 3.0, "her copy holds her ties, not Bran's")
	# -- the other way round: Bran's view holds none of Ann's
	var db: Dictionary = NetSession.welcome_view(w, bran.pid)
	check(not (db.relations.ties as Dictionary).has(Relations.key(aid, v1.id)) and not db.get("justice", {}).get("cases", {}).has(aref) and not (db.chests.stash as Dictionary).has(ua), "Bran's view holds none of Ann's ties, cases or chest goods")
	# -- syncs: the changed sections sent to Ann carry none of Bran's records
	var sd := host_d.duplicate(false)
	NetSession._private_for(sd, aref, w)
	var ch := NetSync.changed(sd, {})
	var wire := JSON.stringify(ch)
	check(ch.has("relations") and ch.has("credit") and ch.has("justice") and not ch.has("judgment"), "a first sync to Ann carries the filtered sections")
	check(wire.find("Bran's private note") < 0 and not (ch.justice.cases as Dictionary).has(bref) and not (ch.relations.ties as Dictionary).has(Relations.key(bid, v1.id)), "the sync's wire payload holds none of Bran's records")
	check(JSON.stringify(host_d, "", true) == JSON.stringify(w.to_dict(), "", true), "the host's own sections unchanged by the sync filter")
	# -- MP-05: an asset-sharing agreement shares assets, not private records
	w.asset_shares[World._asset_share_key(aref, bref)] = 3
	var ds: Dictionary = NetSession.welcome_view(w, ann.pid)
	var sc: Dictionary = (ds.carts.carts as Array).filter(func(c): return int(c.id) == int(cb.id))[0]
	check((ds.chests.stash as Dictionary).has(ub) and Inventory.from_dict(sc.store).count("log") == 3, "MP-05 tier 3 with Bran: his chest and cart goods are shared with Ann")
	check(not ds.get("justice", {}).get("cases", {}).has(bref) and not (ds.relations.ties as Dictionary).has(Relations.key(bid, v1.id)) and not (ds.credit.debts as Array).any(func(x): return str(x.debtor) == bref and str(x.creditor) != aref), "and still none of his cases, ties or debts (sharing grants no private information)")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
