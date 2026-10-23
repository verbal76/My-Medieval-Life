class_name Identity
extends RefCounted
## ID-01 (owner, 2026-10-23, docs/directives/2026-10-23_identity_foundation_approval.md; design docs/design/IDENTITY.md):
## one permanent identity for every person, never reused.
##
## World.next_person_id is the one counter; a person's id is the NPC id for a villager, the member's sixth entry for a person in a
## settlement (OffMapSettlement.M_ID) and PlayerState.pid for a player character. World.people is the register: id -> {name, family,
## sex, born, mother, father, where, since}, identity and whereabouts only (never pruned). Detailed state stays in exactly one place
## at a time: the NPC record when in the village (or kept, alive false, while away or dead), the settlement member when abstract.
##
## `where`: "village", a settlement id, "dead", "player" (the current player character) or "ancestor" (a former one).
##
## This file holds the register's helpers and the one-time upgrade of a save from before version 20.

const VILLAGE := "village"
const DEAD := "dead"
const PLAYER := "player"
const ANCESTOR := "ancestor"
const BORN_TOLERANCE := 2.0       # days: a member's birth day is a whole day, an NPC's a minute (the match of an away villager)


## Where an NPC record says the person is.
static func where_of(n: NPC) -> String:
	if n.alive:
		return VILLAGE
	if n.away != "":
		return n.away
	if n.became_player:
		return PLAYER
	return DEAD


## A link in an NPC's or a member's record as a person id: the player (-2) is the current player's own id.
static func link(w: World, v: int) -> int:
	if v == Life.PLAYER_ID and w.player.pid > 0:
		return w.player.pid
	return v


static func entry_of(w: World, n: NPC) -> Dictionary:
	return {"name": n.name, "family": n.family, "sex": n.sex, "born": n.born, "mother": link(w, n.mother), "father": link(w, n.father),
		"where": where_of(n), "since": w.day()}


## A villager enters the world (population, birth, newcomer, outlaw, arrival): the register learns them.
static func register_npc(w: World, n: NPC) -> void:
	w.people[n.id] = entry_of(w, n)


## A villager's name or family changed (they joined a household): the register says so.
static func sync_name(w: World, n: NPC) -> void:
	if w.people.has(n.id):
		w.people[n.id].name = n.name
		w.people[n.id].family = n.family


## The person is now `where` (from today).
static func move(w: World, id: int, where: String) -> void:
	if w.people.has(id):
		w.people[id].where = where
		w.people[id].since = w.day()


## The register for a person of a settlement (a member). `who` is the member's carried identity ({n, f}), possibly empty.
static func register_member(w: World, id: int, sid: String, sex: int, born_day: int, who: Dictionary, mother := -1, father := -1) -> void:
	w.people[id] = {"name": str(who.get("n", "")), "family": str(who.get("f", "")), "sex": "female" if sex == 1 else "male",
		"born": float(born_day) * World.DAY, "mother": mother, "father": father, "where": sid, "since": w.day()}


## A player character is given an id and entered as the current player.
static func register_player(w: World, p: PlayerState, mother := -1, father := -1) -> void:
	if p.pid <= 0:
		p.pid = w.new_person_id()
	w.people[p.pid] = {"name": p.name, "family": p.family, "sex": p.sex, "born": p.born, "mother": mother, "father": father,
		"where": PLAYER, "since": w.day()}


# ------------------------------------------------------------------ succession ----------------
## The player has died and `heir` takes over. The predecessor becomes an ancestor under their own id and a snapshot of the
## village's ties with them at this moment is kept under that id (history only: no rule reads it; the live ties with the player id
## (-2) go on to the heir exactly as in Build 18, ID-D1). `kid`, when the heir is the player's own child, keeps their record and id.
static func succeed(w: World, parent: PlayerState, heir: PlayerState, kid: NPC) -> void:
	if parent.pid <= 0:
		register_player(w, parent)
	var ties := {}
	var keys: Array = w.relations.ties.keys()
	keys.sort()
	for k in keys:
		var parts: PackedStringArray = str(k).split(":")
		if parts.size() == 2 and (int(parts[0]) == Life.PLAYER_ID or int(parts[1]) == Life.PLAYER_ID):
			var other := int(parts[1]) if int(parts[0]) == Life.PLAYER_ID else int(parts[0])
			ties[str(other)] = (w.relations.ties[k] as Dictionary).duplicate(true)
	w.tie_history[str(parent.pid)] = {"day": w.day(), "ties": ties}
	move(w, parent.pid, ANCESTOR)
	if kid != null:
		heir.pid = kid.id
		move(w, kid.id, PLAYER)
		if w.people.has(kid.id):
			w.people[kid.id].name = heir.name
	else:
		register_player(w, heir)


# ------------------------------------------------------------------ the upgrade of a save from before version 20 ----------------
## Give an older save its identities, deterministically (no random numbers; every walk in a fixed order). The world has been loaded
## (NPC records, player, settlements); nothing is merged, deleted or reassigned. Fills World.next_person_id, people and
## identity_report. Returns "" or the reason it cannot be done (the caller then refuses the load and leaves the file alone).
static func upgrade(w: World, from_version: int) -> String:
	var seen := {}
	var top := 0
	for n: NPC in w.npcs:
		if seen.has(n.id):
			return "two villagers in the save share the id %d (%s %s and %s %s)" % [n.id, n.name, n.family, (seen[n.id] as NPC).name, (seen[n.id] as NPC).family]
		seen[n.id] = n
		top = maxi(top, n.id)
	w.next_person_id = top + 1
	w.people = {}
	for n: NPC in w.npcs:
		w.people[n.id] = entry_of(w, n)
	var notes: Array = []
	var reunited := {}                          # member (settlement id, household, member index) -> the villager's id
	var counts := {"villagers": w.npcs.size(), "away": 0, "reunited": 0, "away_unmatched": 0, "away_ambiguous": 0, "members": 0, "new_ids": 0}
	# a villager who is away and still in a settlement: matched to one member (name, family, sex, birth day), never guessed
	var away: Array = w.npcs.filter(func(n: NPC) -> bool: return not n.alive and n.away != "" and not n.became_player)
	away.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
	var cand_of_npc := {}                       # npc id -> [member refs]
	var cand_of_member := {}                    # member ref -> [npc ids]
	for n: NPC in away:
		counts.away += 1
		cand_of_npc[n.id] = []
		var s: OffMapSettlement = w.regions.by_id.get(n.away) if w.regions != null else null
		if s == null:
			continue
		for hi in s.hh.size():
			var mem: Array = s.hh[hi].mem if (s.hh[hi] as Dictionary).has("mem") else []
			for j in mem.size():
				if _matches(n, mem[j]):
					var ref := "%s/%d/%d" % [s.id, hi, j]
					(cand_of_npc[n.id] as Array).append(ref)
					if not cand_of_member.has(ref):
						cand_of_member[ref] = []
					(cand_of_member[ref] as Array).append(n.id)
	var take := {}                              # member ref -> npc id, for a one-to-one match
	for n: NPC in away:
		var cands: Array = cand_of_npc[n.id]
		if cands.size() == 1 and (cand_of_member[cands[0]] as Array).size() == 1:
			take[cands[0]] = n.id
			counts.reunited += 1
		elif cands.is_empty():
			counts.away_unmatched += 1
			notes.append({"kind": "away_unmatched", "npc": n.id, "name": "%s %s" % [n.name, n.family], "settlement": n.away,
				"why": "no member of that settlement has this name, family, sex and birth day; the villager's record and any member stay separate people"})
		else:
			counts.away_ambiguous += 1
			notes.append({"kind": "away_ambiguous", "npc": n.id, "name": "%s %s" % [n.name, n.family], "settlement": n.away,
				"members": cands.duplicate(), "why": "%d members could be this villager (or one member could be several); each keeps a separate id, nothing was merged" % cands.size()})
	if w.regions != null:
		for s: OffMapSettlement in w.regions.list:
			for hi in s.hh.size():
				var h: Dictionary = s.hh[hi]
				if not h.has("mem"):
					continue
				for j in (h.mem as Array).size():
					var ref := "%s/%d/%d" % [s.id, hi, j]
					if take.has(ref):
						OffMapSettlement.set_member_id(h.mem[j], int(take[ref]))        # the villager's own register entry already says where they are
		counts.new_ids = w.regions.assign_member_ids(w)           # the rest, in settlement, household, member order
		counts.members = int(counts.new_ids) + int(counts.reunited)
	# a villager who came back under an old build was made a new person: the old (away) record stays as it is, and the case is reported
	for n: NPC in away:
		for o: NPC in w.npcs:
			if o.alive and o.id != n.id and o.name == n.name and o.family == n.family and o.sex == n.sex and absf(o.born - n.born) <= BORN_TOLERANCE * World.DAY:
				notes.append({"kind": "returned_as_new_record", "old": n.id, "new": o.id, "name": "%s %s" % [n.name, n.family],
					"why": "an older build made a returning migrant a new villager; both records are kept and their ties are not merged"})
				break
	var former := 0
	for n: NPC in w.npcs:
		for k in ["mother", "father", "partner"]:
			if int(n.get(k)) == Life.FORMER_PLAYER:
				former += 1
	if w.player.generation > 1 or former > 0:
		notes.append({"kind": "former_players", "generations_before": w.player.generation - 1, "links_to_former_player": former,
			"why": "earlier player characters left no records of their own in this save; they get no register entry and the links to a former player stay as they are"})
	register_player(w, w.player)
	w.identity_report = {"from_version": from_version, "day": w.day(), "next_person_id": w.next_person_id, "counts": counts, "notes": notes}
	return verify(w)


## Whether member `m` could be villager `n` (same name, family, sex and birth day, within BORN_TOLERANCE days).
static func _matches(n: NPC, m: Array) -> bool:
	if not OffMapSettlement.has_who(m):
		return false
	var who: Dictionary = OffMapSettlement.who_of(m)
	return str(who.get("n", "")) == n.name and str(who.get("f", "")) == n.family and int(m[OffMapSettlement.M_SEX]) == (1 if n.sex == "female" else 0) \
			and absf(float(m[OffMapSettlement.M_BORN]) - n.born / World.DAY) <= BORN_TOLERANCE


## The register's invariants: "" when they hold, else what is wrong.
static func verify(w: World) -> String:
	var used := {}
	var top := 0
	for n: NPC in w.npcs:
		if not w.people.has(n.id):
			return "villager %d (%s) has no register entry" % [n.id, n.name]
		used[n.id] = "villager"
		top = maxi(top, n.id)
	if w.regions != null:
		for s: OffMapSettlement in w.regions.list:
			for h in s.hh:
				for m in (h.mem if (h as Dictionary).has("mem") else []):
					var id := OffMapSettlement.member_id(m)
					if id <= 0:
						return "a member of %s has no id" % s.id
					if used.has(id) and used[id] != "villager":
						return "id %d is used twice (%s and a member of %s)" % [id, used[id], s.id]
					if used.get(id, "") == "villager" and (w.by_id.get(id) as NPC) != null and (w.by_id.get(id) as NPC).alive:
						return "id %d is a living villager and a member of %s" % [id, s.id]
					used[id] = s.id
					top = maxi(top, id)
					if not w.people.has(id):
						return "member %d of %s has no register entry" % [id, s.id]
	if w.player.pid <= 0 or not w.people.has(w.player.pid):
		return "the player has no register entry"
	top = maxi(top, w.player.pid)
	for id in w.people:
		top = maxi(top, int(id))
	if w.next_person_id <= top:
		return "the id counter (%d) is not above the highest id (%d)" % [w.next_person_id, top]
	return ""
