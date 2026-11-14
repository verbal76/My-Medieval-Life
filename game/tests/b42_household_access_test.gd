extends SceneTree
## B42 household access (owner directive 2026-11-14 to Agent Q, on B42-MP-PANTRY-PRIVACY and B42-Q-PANTRY-TIER): "Players keep full
## access to their own household's records and pantry. Married players in the same household keep household access. Household
## membership grants access independently of the asset-sharing tiers. Outsiders stay restricted by the approved tiers (pantry at tier
## 2 and 3 only). Reconnecting, saving, loading, and changing household membership (marrying in, leaving) must not wrongly grant or
## revoke access." Checked on what the host sends (NetSession.welcome_view; the section sync, NetSession._private_for then
## NetSync.changed against what the copy holds), as the JSON text that goes over the wire:
##  1. marrying in by the players' own offer and answer gives the couple their household's pantry, at once and on the next sync;
##  2. membership, not sharing: the couple keep it with no agreement between them, after one given and withdrawn; an outsider has it
##     at tier 2 and 3 only, and loses it when the agreement is withdrawn, on the sync as well as a fresh welcome;
##  3. a reconnect (a fresh welcome, and a sync from an empty copy) and the host's save and load change none of it;
##  4. a guest marrying a villager makes that household hers (its pantry hers, private from the others); when he dies she has left
##     it, by the game's own rule (Guardianship.player_household), and gets no more than anyone else;
##  5. a couple's household stays its players' when one of them dies;
##  6. the host's world is never changed by any view.
##   godot --headless --path game -s tests/b42_household_access_test.gd
var checks := 0
var failures := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


func _guest(w: World, name: String, sex: String) -> PlayerState:
	var g := PlayerState.new()
	g.name = name
	g.family = name + "son"
	g.sex = sex
	g.born = w.player.born
	Identity.register_player(w, g)
	w.give_start_kit(g)
	g.net_key = name.to_lower().left(1).repeat(32)
	w.add_guest(g)
	g.pos = w.player.pos
	return g


## The households guest `p` is welcomed with (a fresh join or a reconnect), as the text sent.
func welcome_hh(w: World, p: PlayerState) -> Array:
	return (JSON.parse_string(JSON.stringify(NetSession.welcome_view(w, p.pid))) as Dictionary).households


## The households section a sync sends `p` whose copy holds `sent` (a NetSync digest; {} a copy with nothing), or null if none.
func sync_hh(w: World, p: PlayerState, sent: Dictionary):
	var d: Dictionary = w.to_dict()
	NetSession._private_for(d, w.player_ref(p), w)
	var ch: Dictionary = JSON.parse_string(JSON.stringify(NetSync.changed(d, sent)))
	return ch.get("households")


func digest(w: World, p: PlayerState) -> Dictionary:
	return NetSync.digest(NetSession.welcome_view(w, p.pid))


## Whether household `h` of `hh` comes with its pantry and figures (`marker` the item put in it).
func whole(hh, h: int, marker: String) -> bool:
	if not (hh is Array) or h >= (hh as Array).size():
		return false
	var r: Dictionary = hh[h]
	return not r.has("pantry_private") and JSON.stringify(r.get("pantry", {})).contains(marker) and r.has("econ")


func withheld(hh, h: int, marker: String) -> bool:
	if not (hh is Array) or h >= (hh as Array).size():
		return false
	var r: Dictionary = hh[h]
	return bool(r.get("pantry_private", false)) and not JSON.stringify(r).contains(marker) and not r.has("econ")


func share(w: World, from: PlayerState, to: PlayerState, tier: int) -> bool:
	if w.player_offer("asset_share", to.pid, "", tier, from) != "":
		return false
	return w.player_answer(int(w.offers.back().id), true, to) == ""


func wed(w: World, a: PlayerState, b: PlayerState) -> String:
	var why := w.player_offer("partner", b.pid, "", 1, a)
	if why != "":
		return why
	for o in w.offers:
		if str(o.kind) == "partner" and str(o.to) == w.player_ref(b):
			return w.player_answer(int(o.id), true, b)
	return "no offer recorded"


func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8809)
	var ann := _guest(w, "Ann", "female")
	var bran := _guest(w, "Bran", "male")
	var cat := _guest(w, "Cat", "female")
	var dora := _guest(w, "Dora", "female")
	var aref := w.player_ref(ann)
	var bref := w.player_ref(bran)
	var cref := w.player_ref(cat)

	# -- 1. marrying in
	var before := {}
	for p: PlayerState in [ann, bran, cat]:
		before[p.pid] = digest(w, p)
	check(wed(w, ann, bran) == "", "setup: Ann and Bran marry by offer and answer")
	var hc := Life.couple_household(w, ann, bran)
	check(hc >= 0 and Life.is_couple_h(w, hc), "setup: their couple household (%d)" % hc)
	w.households[hc].pantry.add("bread", 5)
	w.households[hc].econ = {"days": 2.0, "members": 0}
	for p: PlayerState in [ann, bran]:
		check(whole(welcome_hh(w, p), hc, "bread"), "1. %s, married in: the household's pantry and figures whole in the welcome" % p.name)
		check(whole(sync_hh(w, p, before[p.pid]), hc, "bread"), "1. %s: and on the next sync to the copy held before the wedding" % p.name)
	check(withheld(welcome_hh(w, cat), hc, "bread"), "1. Cat, an outsider: the household without its pantry")
	var cs = sync_hh(w, cat, before[cat.pid])
	check(cs == null or withheld(cs, hc, "bread"), "1. Cat: nor on the sync")

	# -- 2. membership, not sharing
	check(w.asset_share_tier(aref, bref) == 0 and whole(welcome_hh(w, ann), hc, "bread") and whole(welcome_hh(w, bran), hc, "bread"),
			"2. no agreement between Ann and Bran: both keep their household's pantry (membership, not tiers)")
	check(share(w, ann, bran, 1), "setup: Ann gives Bran tier 1")
	w.asset_share_revoke(bran.pid, ann)
	check(w.asset_share_tier(aref, bref) == 0 and whole(welcome_hh(w, bran), hc, "bread") and whole(welcome_hh(w, ann), hc, "bread"),
			"2. an agreement given and withdrawn between them: both still keep it")
	check(share(w, bran, cat, 1) and w.asset_share_tier(bref, cref) == 1 and withheld(welcome_hh(w, cat), hc, "bread"), "2. Cat at tier 1 from Bran: still without it")
	var c1 := digest(w, cat)
	for t in [2, 3]:
		check(share(w, bran, cat, t) and w.asset_share_tier(bref, cref) == t and whole(welcome_hh(w, cat), hc, "bread"), "2. Cat at tier %d from Bran: the pantry" % t)
	check(whole(sync_hh(w, cat, c1), hc, "bread"), "2. and the sync brings it to her copy")
	var c3 := digest(w, cat)
	w.asset_share_revoke(cat.pid, bran)
	check(w.asset_share_tier(bref, cref) == 0 and withheld(welcome_hh(w, cat), hc, "bread"), "2. the agreement withdrawn: Cat's welcome without it")
	check(withheld(sync_hh(w, cat, c3), hc, "bread"), "2. and the sync takes it out of her copy")
	check(whole(welcome_hh(w, ann), hc, "bread") and whole(welcome_hh(w, bran), hc, "bread"), "2. Ann and Bran keep theirs throughout")

	# -- 3. reconnect, save and load
	for p: PlayerState in [ann, bran]:
		check(whole(sync_hh(w, p, {}), hc, "bread"), "3. %s reconnecting (a sync to an empty copy): the pantry whole" % p.name)
	check(withheld(sync_hh(w, cat, {}), hc, "bread"), "3. Cat reconnecting: without it")
	var w2 := World.new()
	w2.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(w.to_dict())))
	check(w2.load_error == "" and w2.households[hc].pantry.count("bread") == 5, "3. the host saves and loads: the pantry kept whole in the save")
	var ann2 := w2.player_by_pid(ann.pid)
	var bran2 := w2.player_by_pid(bran.pid)
	var cat2 := w2.player_by_pid(cat.pid)
	if ann2 != null and bran2 != null and cat2 != null:
		check(whole(welcome_hh(w2, ann2), hc, "bread") and whole(welcome_hh(w2, bran2), hc, "bread"), "3. after the load, Ann's and Bran's rejoining welcomes: the pantry whole")
		check(withheld(welcome_hh(w2, cat2), hc, "bread") and w2.asset_share_tier(bref, cref) == 0, "3. after the load, Cat's: without it (no agreement came back)")
		var gw := World.new()
		gw.load_dict(VillageMap.load_default(), JSON.parse_string(JSON.stringify(NetSession.welcome_view(w2, ann2.pid))))
		check(gw.load_error == "" and gw.households[hc].pantry.count("bread") == 5, "3. Ann's copy loads with her household's pantry")
		gw.dispose()
	else:
		check(false, "3. the guests are kept by the load")
	w2.dispose()

	# -- 4. a guest marries a villager, then is widowed
	var v: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 0 and n.partner == -1 and n.sex == "male" and not Life.is_couple_h(w, n.household):
			v = n
			break
	check(v != null, "setup: an unmarried villager")
	var hv := v.household
	w.households[hv].pantry.add("wheat", 4)
	w.households[hv].econ = {"days": 1.0, "members": 1}
	var d_before := digest(w, dora)
	var c_before := digest(w, cat)
	check(whole(welcome_hh(w, cat), hv, "wheat"), "4. before: a villagers' household, its pantry public as before")
	dora.partner = v.id
	v.partner = w.person_id(dora)
	check(Guardianship.player_household(w, dora) == hv, "setup: Dora marries him; his household is hers")
	var dsw = sync_hh(w, dora, d_before)               # her copy held it whole already (a villagers' household): nothing to send, or it whole
	check(whole(welcome_hh(w, dora), hv, "wheat") and (dsw == null or whole(dsw, hv, "wheat")), "4. Dora, married in: its pantry whole (welcome; the sync takes nothing from her copy)")
	check(withheld(welcome_hh(w, cat), hv, "wheat") and withheld(sync_hh(w, cat, c_before), hv, "wheat"), "4. Cat: now a player household's, its pantry withheld (welcome and sync)")
	check(whole(welcome_hh(w, dora), hv, "wheat") and withheld(welcome_hh(w, dora), hc, "bread"), "4. Dora sees her own household's pantry, not Ann and Bran's")
	var d_wed := digest(w, dora)
	w.kill(v, "illness")
	check(not v.alive and Guardianship.player_household(w, dora) == -1, "setup: he dies; by the game's rule she is no longer of that household")
	var ds = sync_hh(w, dora, d_wed)
	check(not withheld(welcome_hh(w, dora), hv, "wheat") and (ds == null or not withheld(ds, hv, "wheat")),
			"4. widowed: Dora sees the household as anyone sees a villagers' household, no more and no less (welcome and sync)")
	check(JSON.stringify(welcome_hh(w, dora)[hv]) == JSON.stringify(welcome_hh(w, cat)[hv]), "4. the same as Cat sees it")

	# -- 5. a couple's household after one of them dies
	bran.alive = false
	check(whole(welcome_hh(w, ann), hc, "bread"), "5. Bran dead: Ann keeps their household's pantry")
	check(withheld(welcome_hh(w, cat), hc, "bread"), "5. and Cat is still without it")
	bran.alive = true

	# -- 6. the host's world
	var host := JSON.stringify(w.to_dict().households)
	for p: PlayerState in [ann, bran, cat, dora]:
		NetSession.welcome_view(w, p.pid)
		sync_hh(w, p, {})
	check(JSON.stringify(w.to_dict().households) == host and w.households[hc].pantry.count("bread") == 5, "6. the host's households unchanged by every view")
	w.dispose()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
