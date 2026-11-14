extends SceneTree
## B42-MP-PANTRY-PRIVACY (owner decision 2026-11-14): "Household pantry information is private by default. Other players may access it
## only through explicitly authorized sharing permissions. Preserve legitimate household access and verify behavior across multiplayer
## sessions, reconnects, and save/load." What the host sends a guest (the welcome, NetSession.welcome_view; every section sync,
## NetSession._private_for before NetSync.changed) holds a player household's pantry, and the figures read from it (`econ`), only for
## that household's own players (a player couple's two players, Life.is_couple; a player married to a villager, whose household it is,
## Guardianship.player_household) and for a player one of them shares with at MP-05 tier 2 or 3 (B42-Q-PANTRY-TIER, owner 2026-11-14)
## Everyone else's copy holds the household without them. Villagers' own households stay as
## they were. The host's world is unchanged; the views load on a guest; they hold across the host's save and load and a reconnect.
## In the MP-07 style (mp07_private_records_test): the view checked as the JSON text that goes over the wire.
##   godot --headless --path game -s tests/mp_pantry_privacy_test.gd
var checks := 0
var failures := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


func _guest(w: World, name: String, fam: String, sex: String) -> PlayerState:
	var g := PlayerState.new()
	g.name = name
	g.family = fam
	g.sex = sex
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = name.to_lower().left(1).repeat(32)
	w.add_guest(g)
	g.pos = w.player.pos
	return g


## The households of guest `pid`'s welcome, as the text sent (JSON round trip).
func view_hh(w: World, pid: int) -> Array:
	var d: Dictionary = JSON.parse_string(JSON.stringify(NetSession.welcome_view(w, pid)))
	return d.households


func has_goods(hh: Array, h: int) -> bool:
	var p := JSON.stringify(hh[h].get("pantry", {}))
	return p.contains("bread") or p.contains("wheat")


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8808)
	var ann := _guest(w, "Ann", "Miller", "female")
	var bran := _guest(w, "Bran", "Smith", "male")
	var cat := _guest(w, "Cat", "Weaver", "female")
	var aref := w.player_ref(ann)
	var cref := w.player_ref(cat)
	# Ann and Bran married: their couple household (MP-PLAYER-FAMILY)
	ann.partner = w.person_id(bran)
	bran.partner = w.person_id(ann)
	var hc := Life.found_couple_household(w, ann, bran)
	check(hc >= 0 and Life.is_couple_h(w, hc), "setup: Ann and Bran's household")
	w.households[hc].pantry.add("bread", 5)
	w.households[hc].econ = {"days": 3.5, "members": 0}
	# the host married to a villager: the villager's household is the host's
	var v: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.partner == -1 and n.sex == "female":
			v = n
			break
	w.player.partner = v.id
	v.partner = w.person_id(w.player)
	var hv := v.household
	check(Guardianship.player_household(w, w.player) == hv, "setup: the host's household is their villager partner's")
	w.households[hv].pantry.add("wheat", 4)
	var wheat: int = w.households[hv].pantry.count("wheat")
	# a household of villagers only
	var hx := -1
	for h in w.households.size():
		if h != hv and h != hc and not w.households[h].get("ended", false) and not w.brain._members(h).is_empty():
			hx = h
			break
	w.households[hx].pantry.add("bread", 2)
	var host_before := JSON.stringify(w.to_dict().households)

	# 1. who sees which pantry
	var c_hh := view_hh(w, cat.pid)
	check(not has_goods(c_hh, hc) and not c_hh[hc].has("econ"), "Cat (no household, no sharing): Ann and Bran's pantry and its figures are not sent")
	check(not has_goods(c_hh, hv), "Cat: the host's household pantry is not sent")
	check(c_hh[hc].has("couple") and str(c_hh[hc].family) == str(w.households[hc].family), "Cat: the couple's household itself is sent (family, couple)")
	check(JSON.stringify(c_hh[hx].pantry) == JSON.stringify(JSON.parse_string(JSON.stringify(w.households[hx].pantry.to_dict()))),
		"Cat: a villagers' household pantry is sent as before")
	var a_hh := view_hh(w, ann.pid)
	check(has_goods(a_hh, hc) and a_hh[hc].has("econ"), "Ann: her own household's pantry and figures whole")
	check(not has_goods(a_hh, hv), "Ann: the host's household pantry is not sent")
	check(has_goods(view_hh(w, bran.pid), hc), "Bran: his own household's pantry whole")
	check(JSON.stringify(w.to_dict().households) == host_before, "the host's world is unchanged by the views")

	# 2. sharing (B42-Q-PANTRY-TIER, owner 2026-11-14: "Tier 2 and 3: moderate sharing also shows the pantry"): tier 1 does not
	check(w.player_offer("asset_share", cat.pid, "", 1, ann) == "", "setup: Ann offers Cat tier 1")
	w.player_answer(int(w.offers.back().id), true, cat)
	check(w.asset_share_tier(aref, cref) == 1 and not has_goods(view_hh(w, cat.pid), hc), "Cat with tier 1 from Ann: still no pantry")
	for t in [2, 3]:
		check(w.player_offer("asset_share", cat.pid, "", t, ann) == "", "setup: Ann offers Cat tier %d" % t)
		w.player_answer(int(w.offers.back().id), true, cat)
		c_hh = view_hh(w, cat.pid)
		check(w.asset_share_tier(aref, cref) == t and has_goods(c_hh, hc) and not has_goods(c_hh, hv), "Cat with tier %d from Ann: Ann's household pantry sent, the host's still not" % t)

	# 3. the sync: a change to the couple's pantry goes to its players, never to anyone else
	w.asset_share_revoke(cat.pid, ann)
	check(w.asset_share_tier(aref, cref) == 0, "setup: Ann withdraws the agreement")
	var sent := {}
	for p: PlayerState in [ann, cat]:
		sent[p.pid] = NetSync.digest(NetSession.welcome_view(w, p.pid))
	w.households[hc].pantry.add("bread", 3)
	for p: PlayerState in [ann, cat]:
		var d: Dictionary = w.to_dict()
		NetSession._private_for(d, w.player_ref(p), w)
		var ch: Dictionary = JSON.parse_string(JSON.stringify(NetSync.changed(d, sent[p.pid])))
		if p == ann:
			check(ch.has("households") and has_goods(ch.households, hc), "sync: Ann gets her household's changed pantry")
		else:
			check(not ch.has("households") or not has_goods(ch.households, hc), "sync: Cat gets nothing of the changed pantry")

	# 4. a guest loads its view; the host keeps every pantry
	var gw := World.new()
	gw.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(NetSession.welcome_view(w, cat.pid))))
	check(gw.load_error == "" and gw.households.size() == w.households.size() and gw.households[hc].pantry.total() == 0, "Cat's copy loads, the household there without goods")
	gw.dispose()
	check(w.households[hc].pantry.count("bread") == 8 and w.households[hv].pantry.count("wheat") == wheat, "the host keeps every pantry whole")

	# 5. the host saves and loads; the guests come back (a fresh welcome): the same views
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.load_error == "" and w2.households[hc].pantry.count("bread") == 8, "save and load: the pantry is kept whole in the host's save")
	var cat2 := w2.player_by_pid(cat.pid)
	var ann2 := w2.player_by_pid(ann.pid)
	check(cat2 != null and ann2 != null, "save and load: the guests are kept")
	if cat2 != null and ann2 != null:
		check(not has_goods(view_hh(w2, cat2.pid), hc) and not has_goods(view_hh(w2, cat2.pid), hv), "after the load, Cat's rejoining welcome: still no player household's pantry")
		check(has_goods(view_hh(w2, ann2.pid), hc), "after the load, Ann's rejoining welcome: her household's pantry whole")
	check(Guardianship.player_household(w2, w2.player) == hv, "after the load, the host's household is still its partner's")
	w2.dispose()
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
