extends SceneTree
## LIFE-04 — widowed villagers and players may remarry, old spouses retained.
var checks := 0
var failures := 0
func check(ok: bool, what: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + what)
	if not ok:
		failures += 1

func _init() -> void:
	GameData.ensure()
	var w := World.new()
	w.setup(VillageMap.load_default(), 8714)
	var lo: float = float(Life.cfg().partner_min_age)
	var eligible: Array = []
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and Life.npc_age(w,n) >= lo:
			eligible.append(n)
	var widow: NPC = eligible[0]
	var deceased: NPC = eligible[1]
	var suitor: NPC = null
	for n: NPC in eligible:
		if n != widow and n != deceased and not Life.kin(widow.id, widow.mother, widow.father, n.id, n.mother, n.father):
			suitor = n
			break
	check(suitor != null, "LIFE-04: unrelated adult suitor exists")
	if suitor == null:
		quit(1)
		return
	widow.partner = deceased.id
	deceased.partner = widow.id
	deceased.alive = false
	suitor.partner = -1
	check(not Life.has_partner(w, widow), "LIFE-04: deceased spouse is no longer living partner")
	check(w.relations.can_court(widow.id,suitor.id), "LIFE-04: widow may court unrelated adult")
	Life._link_partners(widow,suitor)
	check(widow.partner == suitor.id and suitor.partner == widow.id,"LIFE-04: remarriage forms reciprocal live link")
	check(widow.past_partners.has(deceased.id),"LIFE-04: widow retains former spouse history")
	var copy := NPC.from_dict(widow.to_dict())
	check(copy.past_partners.has(deceased.id) and copy.partner == suitor.id,"LIFE-04: historical spouse survives NPC save/load")
	var p: PlayerState = w.player
	var former: NPC = eligible[2]
	former.alive = false
	p.partner = former.id
	former.partner = w.person_id(p)
	var other: NPC = null
	for n: NPC in eligible:
		if n != widow and n != deceased and n != former and n != suitor and n.alive and not Life.kin(w.acting_id(), p.mother,p.father,n.id,n.mother,n.father):
			other = n
			break
	check(other != null,"LIFE-04: unrelated adult NPC available for widowed player")
	if other != null:
		other.partner = -1
		check(Life.partner_refusal(w,other) == "", "LIFE-04: widowed player may propose again")
		check(Life.partner_player(w,other) == "" and p.partner == other.id,"LIFE-04: player remarries successfully")
		check(p.past_partners.has(former.id),"LIFE-04: player remembers deceased former spouse")
		check(PlayerState.from_dict(p.to_dict()).past_partners.has(former.id),"LIFE-04: player former spouse survives save/load")
	# A deceased player's spouse no longer blocks a new player-to-player union.
	var w2 := World.new()
	w2.setup(VillageMap.load_default(), 8715)
	var old_npc: NPC = null
	for n: NPC in w2.npcs:
		if n.alive and n.role == "adult":
			old_npc = n
			break
	var guest := PlayerState.new()
	guest.name = "Gwen"
	guest.family = "Widow"
	guest.sex = "female"
	guest.born = w2.player.born
	Identity.register_player(w2, guest)
	w2.give_start_kit(guest)
	guest.net_key = "b".repeat(32)
	w2.add_guest(guest)
	guest.pos = w2.player.pos
	w2.player.partner = old_npc.id
	old_npc.partner = w2.acting_id()
	old_npc.alive = false
	check(w2.players_partner_refusal(w2.player,guest) == "", "LIFE-04: widowed player may court a second player")
	check(w2.player_offer("partner", guest.pid) == "", "LIFE-04: widowed player proposes to second player")
	var offer_id: int = int(w2.offers.back().id)
	check(str(w2.as_actor(guest,w2.player_answer.bind(offer_id,true))) == "", "LIFE-04: player-to-player remarriage accepted")
	check(w2.player.past_partners.has(old_npc.id) and w2.player.partner == w2.person_id(guest),
		"LIFE-04: former spouse retained after new player marriage")
	print("%d checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
