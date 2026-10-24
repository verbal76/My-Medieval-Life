class_name Guardianship
extends RefCounted
## Orphaned children (owner directive 2026-10-20, housing, succession and adoption, Parts 3-4; owner answers
## OD-11 and OD-12; register FAM-02..05, FAM-07). Each dawn, a household whose living members are all children
## (no adult or elder left to care for them) has its children taken in by another household, in the owner's
## order:
##   1. a surviving parent who lives elsewhere;
##   2. living grandparents, on either side;
##   3. the nearest eligible blood relative, by the actual family tree (siblings and grandparents' other
##      children before cousins), never a more distant one while a closer one is eligible;
##   4. another villager's household willing and able: a responsible adult, a home and room for the child.
## Among equally close candidates (OD-12): ability to provide care, then household capacity, then food, then
## the existing relationship with the child, then proximity, then the lower household id (deterministic).
## There is no adoption authority: the child simply becomes a dependant of the receiving household and uses
## its house. Genealogy (mother, father, children) is never changed; when the child takes the receiving
## family's surname, the birth surname is kept in `birth_family`. Occupancy changes with the household's
## members, so any housing need is the receiving household's own (crowding, HOUSE-01); no house is built.
## With no household able to take a child, the owner's fallback is the bandit clan (FAM-07, OD-11): the child joins
## the bandit camp as a dependant (join_clan).
## REC-001 (owner #46/#47: "Orphaned children should have possible adoption or guardianship paths. Family members may
## receive priority, followed by suitable willing households"; "The player must be eligible for ... adoption under the
## same basic systems as NPCs"):
##  - inheritance at once: an orphaned household's stores go with its children, shared out child by child (the last
##    takes the rest), into the pantry of the household that takes each in (a clan child carries its share), so the
##    food the parents left feeds their children and does not pass to the manor (escheat) while they live; the
##    receiving household's position (food need, members) is recomputed at once (NPCBrain.evaluate_household);
##  - the player in the same order: the player's household is the one the player's children are raised in (their
##    partner's, Life.births). The player's kinship to the child counts through the family tree (parent, grandparent,
##    relative), so a player's grandchild goes to the player's household before a more distant relative's;
##  - the player's choice (player_adopt): the player may take in an orphaned child (no living parent but the player)
##    who lives at the bandits' camp, with a household that is not kin, or with kin more distant than the player;
##    never one that kin at least as close already care for (family first). The player's household must pass the
##    same test as any villager's (a home of its own, a responsible adult, a sleeping place for the child).


static func dawn(w: World) -> void:
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false):
			continue
		var kids := orphans(w, h)
		for k: NPC in kids:
			place(w, k)


## The living children of household `h` when no adult or elder of it is alive; else [].
static func orphans(w: World, h: int) -> Array:
	var kids := []
	for o: NPC in w.brain._members(h):
		if not o.alive:
			continue
		if o.role != "child":
			return []
		kids.append(o)
	kids.sort_custom(func(a: NPC, b: NPC) -> bool: return a.id < b.id)
	return kids


## Find the child a home and move them there. Returns the tier that took them ("parent", "grandparent",
## "relative", "villager"), or "clan" when no household can and the child joins the bandit clan (FAM-07).
static func place(w: World, k: NPC) -> String:
	var tiers := candidates(w, k)
	for tier in ["parent", "grandparent", "relative", "villager"]:
		var hs: Array = tiers.get(tier, [])
		if hs.is_empty():
			continue
		move(w, k, int(hs[0]), tier)
		return tier
	join_clan(w, k)
	return "clan"


## Households that could take the child in, by tier, each list best first. Relatives are kept to the
## nearest eligible distance (FAM-03: never a more distant one while a closer one is eligible).
static func candidates(w: World, k: NPC) -> Dictionary:
	var out := {}
	var parents := []
	for pid in [k.mother, k.father]:
		var p := w.npc(int(pid)) if int(pid) >= 0 else null
		if p != null and p.alive and p.role != "bandit" and _eligible(w, p.household, k):
			parents.append(p.household)
		elif Life.is_player_id(int(pid)) and _player_eligible(w, k):
			parents.append(player_household(w))
	out.parent = _ranked(w, k, parents)
	var grand := []
	for pid in [k.mother, k.father]:
		var p = Life.parent_of(w, int(pid)) if int(pid) != -1 else null
		if p == null:
			continue
		for gid in [p.mother, p.father]:
			var g := w.npc(int(gid)) if int(gid) >= 0 else null
			if g != null and g.alive and g.role != "bandit" and _eligible(w, g.household, k) and not grand.has(g.household):
				grand.append(g.household)
			if Life.is_player_id(int(gid)) and _player_eligible(w, k) and not grand.has(player_household(w)):
				grand.append(player_household(w))
	out.grandparent = _ranked(w, k, grand)
	var dist := kin_distances(w, k)
	var best := 1 << 30
	var near := []
	var ids := dist.keys()
	ids.sort()
	for id in ids:
		var hh := -1
		if Life.is_player_id(int(id)):
			if not _player_eligible(w, k):
				continue
			hh = player_household(w)
		else:
			var o := w.npc(int(id))
			if o == null or not o.alive or o.role == "child" or o.role == "bandit" or not _eligible(w, o.household, k):
				continue
			hh = o.household
		var d := int(dist[id])
		if d < best:
			best = d
			near = []
		if d == best and not near.has(hh):
			near.append(hh)
	out.relative = _ranked(w, k, near)
	var others := []
	for h in w.households.size():
		if _eligible(w, h, k) and Life.has_room(w, h, k):
			others.append(h)
	out.villager = _ranked(w, k, others)
	return out


## Genealogical distance from the child to every relative reachable through parent and child links (the
## dead too, as links: a dead parent still joins a child to its grandparents and aunts). A parent is 1, a
## grandparent or sibling 2, an aunt or uncle 3, a first cousin 4. The living player is a node like any villager
## (Life.PLAYER_ID, REC-001); an earlier generation's player (FORMER_PLAYER) is not.
static func kin_distances(w: World, k: NPC) -> Dictionary:
	var dist := {k.id: 0}
	var queue := [k.id]
	while not queue.is_empty():
		var id: int = queue.pop_front()
		var o = (w.player if w.player.alive else null) if Life.is_player_id(id) else w.npc(id)
		if o == null:
			continue
		var next: Array = [o.mother, o.father] + o.children
		for nid in next:
			var n := int(nid)
			if (n < 0 and not Life.is_player_id(n)) or dist.has(n):
				continue
			dist[n] = int(dist[id]) + 1
			queue.append(n)
	dist.erase(k.id)
	return dist


## A household that can care for a child: not ended, not the child's own, a house of its own and a
## responsible adult (an adult, or an elder when it has none).
static func _eligible(w: World, h: int, k: NPC) -> bool:
	if h < 0 or h >= w.households.size() or h == k.household:
		return false
	var hh: Dictionary = w.households[h]
	if hh.get("ended", false) or not w.buildings.has(str(hh.home)):
		return false
	var ra := w.construction.responsible_adult(h)
	return ra != null and ra.role != "child"


## Best first, by the owner's order for equally suited homes (OD-12): ability to provide care (the
## household keeps what it needs for its people with the child too), capacity (sleeping places to spare),
## food (days in hand), the existing relationship with the child (the best regard of its members), how
## near its house is to the child, then the lower household id.
static func _ranked(w: World, k: NPC, hs: Array) -> Array:
	var keyed := []
	for h: int in hs:
		var members: Array = w.brain._members(h)
		var able := 1 if w.property.purse(World.hh_ref(h)) >= w.construction._keep(h, members.size() + 1) else 0
		var room: int = w.construction.beds_in(str(w.households[h].home)) - w.construction.beds_needed(h, k)
		var food: float = w.brain.household_food_days(h)
		var tie := 0.0
		for o: NPC in members:
			tie = maxf(tie, float(w.relations.peek(o.id, k.id).get("regard", 0.0)))
		var near := -k.pos.distance_to(Vector2(w.household_cell(h, k.cell())))
		keyed.append([able, room, food, tie, near, -h, h])
	keyed.sort_custom(func(a: Array, b: Array) -> bool:
		for i in 6:
			if a[i] != b[i]:
				return a[i] > b[i]
		return false)
	return keyed.map(func(x: Array) -> int: return int(x[6]))


## FAM-07 (owner, OD-11, 2026-10-20: "If no suitable household can take the child, the child joins the bandit clan ...
## Preserve the child's identity, age, genealogy, and existing relationships. Joining the bandit clan does not instantly
## make a child an adult or grant adult combat abilities."). Interim handling until bandit factions (WDR-016-C): the
## child leaves the household (NPC.clan = "bandit", saved), lives and sleeps at the camp, eats with the band (the camp's
## meal, as the bandits' own), and is never a bandit's prey or in a fight. The child's name, age, role, parents,
## children and relationships are untouched. At coming of age they leave for kin or a household with room if one can
## take them (leave_camp), else stay with the band (Life, the change of role).
static func join_clan(w: World, k: NPC) -> void:
	var old := k.household
	if old >= 0:
		_take_share(w, k, old, k.inv)            # REC-001: the child carries its share of what the parents left
		(w.households[old].members as Array).erase(k.id)
	k.household = -1
	k.home = ""
	k.workplace = ""
	k.clan = "bandit"
	k.plan.clear()
	k.pos = Vector2(w.bandit_camp) + Vector2(0.5, 1.5)
	w.stat("orphans_to_clan")
	if w.recorder != null:
		w.recorder.clan_joined(k, old)      # REC-19
	w.note("No household can take in %s %s: the child goes to the bandits' camp." % [k.name, k.family])
	if old >= 0 and not w.property._anyone_alive(old):
		w.property.household_ended(old)


## FAM-07 (owner, clarified 2026-10-20): at coming of age a child raised in the bandit clan is not bound to it. The
## simplest compatible rule, until NPC Judgment and bandit factions (FAM-08): the young adult goes where the guardianship
## order finds a place (kin first, then a household with room), joins that household as an adult without a trade (the
## job market then treats them as any other) and leaves the clan; with no place, "" and they stay with the band.
## Their name, family tree and relationships are untouched either way. Returns the tier, or "".
static func leave_camp(w: World, n: NPC) -> String:
	var tiers := candidates(w, n)
	for tier in ["parent", "grandparent", "relative", "villager"]:
		var hs: Array = tiers.get(tier, [])
		if hs.is_empty():
			continue
		n.clan = ""
		move(w, n, int(hs[0]), tier)
		w.stat("clan_left_at_age")
		w.note("%s %s comes of age and leaves the bandits' camp for the village." % [n.name, n.family])
		return tier
	return ""


## The child joins household `h` as a dependant (the brain's _lodge: household, surname, home). The birth
## surname is kept when it changes; parents and children links are untouched. The household the child
## leaves ends when nobody in it is alive any more (its goods and coins as any ended household's).
static func move(w: World, k: NPC, h: int, tier: String) -> void:
	var old := k.household
	var was_family := k.family
	if old >= 0:
		_take_share(w, k, old, w.households[h].pantry)
		(w.households[old].members as Array).erase(k.id)
	w.brain._lodge(k, h)
	if k.family != was_family and k.birth_family == "":
		k.birth_family = was_family
	k.plan.clear()
	w.stat("orphans_taken_in")
	w.stat("orphans_taken_in_by_" + tier)
	var host := w.construction.responsible_adult(h)
	if w.recorder != null:
		w.recorder.guardianship(k, old, h, tier, host)      # REC-19
	w.note("%s %s is taken in by %s (%s)." % [k.name, was_family, "the %s household" % w.households[h].family if host == null else "%s %s" % [host.name, host.family], tier])
	if old >= 0 and not w.property._anyone_alive(old):
		w.property.household_ended(old)
	w.brain.evaluate_household(h)                 # REC-001: its members and food need change at once
	if old >= 0 and not w.households[old].get("ended", false):
		w.brain.evaluate_household(old)


## REC-001: the share of an orphaned household's stores (its pantry) that goes with child `k` into `into`: of each
## good, the count divided by the living children still in it, rounded down, so the last child to leave takes the
## rest. Nothing moves from a household that still has a living adult or elder (its stores are theirs). Goods only
## move (World.transfer).
static func _take_share(w: World, k: NPC, old: int, into: Inventory) -> void:
	var left := 0
	for o: NPC in w.brain._members(old):
		if o.alive and o.role != "child":
			return
		if o.alive:
			left += 1
	if left <= 0 or into == null:
		return
	var pantry: Inventory = w.households[old].pantry
	var moved := 0
	for id in pantry.ids():
		var n := pantry.count(id) / left
		if n > 0 and w.transfer(pantry, into, id, n):
			moved += n
	if moved > 0:
		w.stat("orphan_inherited_items", moved)


## The household the player's family lives in with the player's partner (where the player's own children are raised,
## Life.births), or -1: without a partner the player has no household of villagers to raise a child in.
static func player_household(w: World) -> int:
	var p := w.player
	if not p.alive or p.partner < 0:
		return -1
	var o := w.npc(p.partner)
	if o == null or not o.alive or not Life.is_player_id(o.partner):
		return -1
	return o.household


## Whether the player's household can take child `k` in, by the test every household passes (_eligible, has_room).
static func _player_eligible(w: World, k: NPC) -> bool:
	var h := player_household(w)
	return h >= 0 and _eligible(w, h, k) and Life.has_room(w, h, k)


## Why the player cannot take child `k` in ("" if they can): REC-001's rules, above.
static func player_adopt_refusal(w: World, k: NPC) -> String:
	if k == null or not k.alive or k.role != "child":
		return "Only a child can be taken in."
	if not w.player.alive or Life.age_years(w.player.born, w.minutes) < float(Life.cfg().partner_min_age):
		return "You are too young to take in a child."
	for pid in [k.mother, k.father]:
		var p := w.npc(int(pid)) if int(pid) >= 0 else null
		if p != null and p.alive:
			return "%s has a parent living." % k.name
	var h := player_household(w)
	if h < 0:
		return "You have no household to raise a child in."
	if k.household == h:
		return "%s already lives with your family." % k.name
	if not _eligible(w, h, k):
		return "Your household has no home of its own to take a child into."
	if not Life.has_room(w, h, k):
		return "There is no sleeping place for %s in your home." % k.name
	# family first: kin at least as close as the player who already care for the child keep them
	var dist := kin_distances(w, k)
	var mine := int(dist.get(Life.PLAYER_ID, 1 << 30))
	if k.household >= 0 and k.clan == "":
		for o: NPC in w.brain._members(k.household):
			if o.alive and o.role != "child" and dist.has(o.id) and int(dist[o.id]) <= mine:
				return "%s is cared for by family." % k.name
	return ""


## The player takes child `k` into their household (REC-001): "" when done, else why not. The child becomes a
## dependant there as any taken-in child does (move); one from the bandits' camp leaves the clan.
static func player_adopt(w: World, k: NPC, actor: PlayerState = null) -> String:
	if actor != null and actor != w.player:
		return w.as_actor(actor, player_adopt.bind(w, k))
	var why := player_adopt_refusal(w, k)
	if why != "":
		return why
	k.clan = ""
	move(w, k, player_household(w), "player")
	w.stat("player_adoptions")
	return ""
