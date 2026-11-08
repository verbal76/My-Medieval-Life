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
	print("%d checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
