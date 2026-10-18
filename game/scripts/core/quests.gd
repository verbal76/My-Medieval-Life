class_name Quests
extends RefCounted
## Side quests (owner-approved, 2026-10-18). Each dawn, villagers with a real need offer a quest
## from game/data/quests.json: goods to bring them, or a bandit who robbed them. A villager with
## an offer shows a green diamond. The player accepts in conversation and hands the goods over;
## goods go to the giver and the reward comes from the giver's purse, so nothing is created.
## Offers are saved with the world; accepted quests with the player.

var w                         # World
var offers := {}              # npc id -> quest id offered (not yet accepted)


func _init(world) -> void:
	w = world


static func templates() -> Array:
	return GameData.quests


static func template(id: String) -> Dictionary:
	for q in GameData.quests:
		if q.id == id:
			return q
	return {}


## Re-check every villager's offers at dawn: drop those whose need has passed, then offer new ones,
## lowest villager id first, up to quest_max_offers at a time.
func refresh() -> void:
	for id in offers.keys():
		var n: NPC = w.npc(int(id))
		if n == null or not n.alive or not _wants(n, template(offers[id])):
			offers.erase(id)
	var busy := {}
	for q in w.player.quests:
		busy[int(q.giver)] = true
	for t in templates():
		if t.get("story", false):
			continue
		for n: NPC in w.npcs:
			if offers.size() >= int(GameData.b("quest_max_offers")):
				return
			if n.alive and not offers.has(n.id) and not busy.has(n.id) and _wants(n, t):
				offers[n.id] = t.id


## Give the player every story quest they do not have yet and have not finished (a new game, and
## each heir, who must learn everything anew).
func start_story() -> void:
	for t in templates():
		if not t.get("story", false) or w.player.quests.any(func(q): return q.id == t.id):
			continue
		if t.has("learn") and w.player.spells.get(t.learn, false):
			continue
		var giver := _giver_of(t)
		w.player.quests.append({"id": t.id, "giver": giver.id if giver else -1, "day": w.day(), "target": -1})
		w.note("%s %s: %s" % [w.player.name, w.player.family, t.get("start", t.title)])


func _giver_of(t: Dictionary) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and _wants(n, t):
			return n
	return null


## The player learned a spell: story quests that ask for it are done.
func on_learned(spell: String) -> void:
	for q in w.player.quests.duplicate():
		if template(q.id).get("learn", "") == spell:
			complete(q)


## Who shows the green diamond: villagers with an offer, and the giver of each unfinished story quest.
func diamond(n: NPC) -> bool:
	if offers.has(n.id):
		return true
	for q in w.player.quests:
		if int(q.giver) == n.id and template(q.id).get("story", false):
			return true
	return false


func _wants(n: NPC, t: Dictionary) -> bool:
	if t.is_empty() or n.role == "bandit":
		return false
	var g: Dictionary = t.giver
	if g.has("job") and n.job != g.job:
		return false
	if g.has("role") and n.role != g.role:
		return false
	for id in g.get("fewer_than", {}):
		if n.inv.count(id) >= int(g.fewer_than[id]):
			return false
	if g.has("household_food_below") and w.brain.household_food_days(n.household) >= float(g.household_food_below):
		return false
	if g.get("robbed", false) and robber_of(n) == null:
		return false
	return true


## The living bandit who robbed this villager (their memory says "robbed by <name>"), or null.
func robber_of(n: NPC) -> NPC:
	for m in n.memory:
		if str(m).begins_with("robbed by "):
			var who := str(m).substr(10)
			for b: NPC in w.npcs:
				if b.alive and b.role == "bandit" and b.name == who:
					return b
	return null


func offer_of(n: NPC) -> Dictionary:
	return template(str(offers.get(n.id, "")))


## The player's accepted quest from this villager, or {}.
func active_from(n: NPC) -> Dictionary:
	for q in w.player.quests:
		if int(q.giver) == n.id:
			return q
	return {}


func accept(n: NPC) -> Dictionary:
	var t := offer_of(n)
	if t.is_empty() or w.player.quests.size() >= int(GameData.b("quest_max_active")):
		return {}
	var q := {"id": t.id, "giver": n.id, "day": w.day(), "target": -1}
	if t.get("kill", "") == "robber":
		var r := robber_of(n)
		q.target = r.id if r else -1
	offers.erase(n.id)
	w.player.quests.append(q)
	w.note("%s %s agreed to help %s %s: %s." % [w.player.name, w.player.family, n.name, n.family, str(t.title).to_lower()])
	return q


func ready(q: Dictionary) -> bool:
	var t := template(q.id)
	if t.has("need"):
		return w.player.inv.has_all(t.need)
	if t.has("learn"):
		return w.player.spells.get(t.learn, false)
	var target: NPC = w.npc(int(q.target))
	return target == null or not target.alive


## Hand over the goods (they go to the giver) and take the reward from the giver's purse.
## Returns the coins paid, or -1 if the quest is not ready.
func complete(q: Dictionary) -> int:
	var n: NPC = w.npc(int(q.giver))
	var t := template(q.id)
	if n == null or not n.alive or not ready(q):
		return -1
	if t.has("need"):
		w.player.inv.remove_all(t.need)
		for id in t.need:
			n.inv.add(id, int(t.need[id]))
	var pay := mini(int(t.reward), n.coins)
	n.coins -= pay
	n.spent += pay
	w.player.coins += pay
	w.player.quests.erase(q)
	n.remember("helped by %s" % w.player.name)
	w.stat("quests_done")
	w.note("%s %s finished \"%s\" for %s %s%s." % [w.player.name, w.player.family, t.title, n.name, n.family, (" (%d coins)" % pay) if pay > 0 else ""])
	return pay


## Quests whose giver has died fail; they are dropped from the player's list with a note.
func drop_failed() -> void:
	for q in w.player.quests.duplicate():
		var n: NPC = w.npc(int(q.giver))
		if template(q.id).get("story", false):
			continue                         # a story quest waits for a new giver (see start_story)
		if n == null or not n.alive:
			w.player.quests.erase(q)
			w.note("\"%s\" can no longer be finished: %s." % [template(q.id).get("title", q.id), "the one who asked has died"])


## A line the giver says, with {need} and {target} filled in.
func line(q_or_t: Dictionary, key: String) -> String:
	var t := template(q_or_t.get("id", ""))
	var s: String = t.get(key, "")
	var need := []
	for id in t.get("need", {}):
		need.append("%d %s" % [int(t.need[id]), GameData.item_name(id).to_lower()])
	s = s.replace("{need}", " and ".join(need))
	var target: NPC = w.npc(int(q_or_t.get("target", -1))) if q_or_t.has("target") else null
	if target == null and t.get("kill", "") == "robber":
		var giver: NPC = w.npc(int(q_or_t.get("giver", -1)))
		if giver:
			target = robber_of(giver)
	return s.replace("{target}", target.name if target else "the thief")


func to_dict() -> Dictionary:
	var out := {}
	for id in offers:
		out[str(id)] = offers[id]
	return out


func load_dict(d: Dictionary) -> void:
	offers.clear()
	for id in d:
		offers[int(id)] = str(d[id])
