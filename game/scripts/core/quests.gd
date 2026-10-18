class_name Quests
extends RefCounted
## Side quests (owner-approved, 2026-10-18). Each dawn, villagers with a real need offer a quest
## from game/data/quests.json: goods to bring them, or a bandit who robbed them. A villager with
## an offer shows a marker over their head (what the quest is about; story quests a pennant). The player accepts in conversation and hands the goods over;
## goods go to the giver and the reward comes from the giver's purse, so nothing is created.
## Offers are saved with the world; accepted quests with the player.
##
## Paid work ("hire": true; owner-approved: the player can work and earn money) uses the same
## machinery: a villager whose work needs doing and who can pay the wage offers it when the player
## asks "Do you have work for me?" (never as a dawn offer or a marker). The player brings what was
## asked; the wage comes from the employer's purse, in full or not at all. A harvest hand may cut
## up to the asked-for wheat from the employer's field without it being theft, and the farmers of
## that field leave it to them meanwhile. Work left undone lapses after `days` days.
## A quest with "teach" raises one of the player's skills to a level when it is done.

var w                         # World
const NUMBER_WORDS := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]
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
		if t.get("story", false) or t.get("hire", false):
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


## The marker over a villager's head (owner's scheme): "story" (a pennant) for the giver of an
## unfinished story quest, else their offer's kind ("skill", "food", "mineral", "combat", "wood",
## "tool"), or "" for nobody.
func marker(n: NPC) -> String:
	for q in w.player.quests:
		if int(q.giver) == n.id and template(q.id).get("story", false):
			return "story"
	if offers.has(n.id):
		return str(template(offers[n.id]).get("marker", "skill"))
	return ""


func diamond(n: NPC) -> bool:
	return marker(n) != ""


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
	for sk in g.get("player_below", {}):           # a teacher has nothing to teach a player who knows it
		if w.player.level(sk) >= int(g.player_below[sk]):
			return false
	if g.has("field_ripe"):                        # a farmer whose own field holds this much ripe wheat
		var f := field_of(n)
		if f.is_empty() or f.state != "ripe" or int(f.get("crop", 0)) < int(g.field_ripe):
			return false
	if t.get("hire", false) and n.coins < int(t.wage):
		return false
	return true


func field_of(n: NPC) -> Dictionary:
	for f in w.fields:
		if f.id == n.workplace:
			return f
	return {}


# ---------------------------------------------------------------- paid work ------------------
## Whether this villager's work is the kind that can hire the player (a farmer, a woodcutter, a
## miner: any job a hire template names), so "Do you have work for me?" is worth asking.
func hires(n: NPC) -> bool:
	if n.role != "adult" or n.job == "":
		return false
	for t in templates():
		if t.get("hire", false) and str(t.giver.get("job", "")) == n.job:
			return true
	return false


## The work this villager offers the player now, or {}.
func hire_offer(n: NPC) -> Dictionary:
	if not active_from(n).is_empty():
		return {}
	for t in templates():
		if t.get("hire", false) and _wants(n, t):
			return t
	return {}


## Why there is no work: the employer cannot pay the wage, or nothing needs doing.
func no_work_line(n: NPC) -> String:
	for t in templates():
		if t.get("hire", false) and str(t.giver.get("job", "")) == n.job and n.coins < int(t.wage):
			return "I can't pay anyone just now. I've hardly a coin to my name."
	return "Not today. There's nothing I can't manage myself just now."


## The accepted harvest work on this field, or {} (its farmers leave the field to the hired hand).
func hired_on(f: Dictionary) -> Dictionary:
	for q in w.player.quests:
		var t := template(q.id)
		if not t.has("harvest"):
			continue
		var n: NPC = w.npc(int(q.giver))
		if n and n.alive and n.workplace == f.id and int(q.get("harvested", 0)) < int(t.harvest):
			return q
	return {}


## The player cut `cut` wheat from this field: how much of it the harvest work covers (not theft).
func hired_harvest(f: Dictionary, cut: int) -> int:
	var q := hired_on(f)
	if q.is_empty():
		return 0
	var ok := mini(cut, int(template(q.id).harvest) - int(q.get("harvested", 0)))
	q.harvested = int(q.get("harvested", 0)) + ok
	return ok


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


## Take on this villager's offer, or (with `hire`, a template id) the work they offer when asked.
func accept(n: NPC, hire := "") -> Dictionary:
	var t := offer_of(n) if hire == "" else template(hire)
	if hire != "" and (not t.get("hire", false) or not _wants(n, t) or not active_from(n).is_empty()):
		return {}
	if t.is_empty() or w.player.quests.size() >= int(GameData.b("quest_max_active")):
		return {}
	var q := {"id": t.id, "giver": n.id, "day": w.day(), "target": -1}
	if t.get("kill", "") == "robber":
		var r := robber_of(n)
		q.target = r.id if r else -1
	if hire == "":
		offers.erase(n.id)
	w.player.quests.append(q)
	if hire != "":
		w.note("%s %s hired %s %s for a day's work: %s, for %d coins." % [n.name, n.family, w.player.name, w.player.family, str(t.title).to_lower(), int(t.wage)])
		w.stat("hired_jobs_taken")
	else:
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


## Whether the employer can pay this work's wage in full now (always true for a quest).
func can_pay(q: Dictionary) -> bool:
	var t := template(q.id)
	var n: NPC = w.npc(int(q.giver))
	return not t.get("hire", false) or (n != null and n.coins >= int(t.wage))


## What the last completed quest taught ("Crafting is now level 2. Unlocked: ..."), or "".
var last_learned := ""


## Hand over the goods (they go to the giver) and take the reward from the giver's purse (for
## work, the whole wage, or nothing changes hands); a teacher raises the skill they teach.
## Returns the coins paid, -1 if the quest is not ready, -2 if an employer cannot pay the wage.
func complete(q: Dictionary) -> int:
	var n: NPC = w.npc(int(q.giver))
	var t := template(q.id)
	last_learned = ""
	if n == null or not n.alive or not ready(q):
		return -1
	if not can_pay(q):
		return -2
	if t.has("need"):
		w.player.inv.remove_all(t.need)
		for id in t.need:
			n.inv.add(id, int(t.need[id]))
	var hired: bool = t.get("hire", false)
	var pay := int(t.wage) if hired else mini(int(t.reward), n.coins)
	n.coins -= pay
	n.spent += pay
	w.player.coins += pay
	w.player.quests.erase(q)
	if t.has("teach"):
		var sk := str(t.teach.skill)
		var lv := int(t.teach.level)
		if w.player.raise_to(sk, lv):
			var s: Dictionary = GameData.skills[sk]
			var unlock: String = s.unlocks.get(str(lv), "")
			last_learned = "%s is now level %d.%s" % [s.name, lv, (" Unlocked: " + unlock) if unlock != "" else ""]
			w.note("%s %s taught %s %s: %s" % [n.name, n.family, w.player.name, w.player.family, last_learned])
			w.stat("quests_taught")
	n.remember(("hired %s" if hired else "helped by %s") % w.player.name)
	if hired:
		w.stat("hired_jobs_done")
		w.stat("hired_wages", pay)
	else:
		w.stat("quests_done")
	w.note("%s %s finished \"%s\" for %s %s%s." % [w.player.name, w.player.family, t.title, n.name, n.family, (" (%d coins)" % pay) if pay > 0 else ""])
	return pay


## Quests whose giver has died fail; they are dropped from the player's list with a note. Paid
## work left undone for more than its `days` lapses the same way (checked at dawn).
func drop_failed() -> void:
	for q in w.player.quests.duplicate():
		var n: NPC = w.npc(int(q.giver))
		var t := template(q.id)
		if t.get("story", false):
			continue                         # a story quest waits for a new giver (see start_story)
		if n == null or not n.alive:
			w.player.quests.erase(q)
			w.note("\"%s\" can no longer be finished: %s." % [t.get("title", q.id), "the one who asked has died"])
		elif t.get("hire", false) and w.day() - int(q.day) > int(t.get("days", 1)):
			w.player.quests.erase(q)
			w.note("\"%s\" lapsed: the work for %s %s was not done in time." % [t.title, n.name, n.family])


## A line the giver says, with {need} and {target} filled in.
func line(q_or_t: Dictionary, key: String) -> String:
	var t := template(q_or_t.get("id", ""))
	var s: String = t.get(key, "")
	var need := []
	for id in t.get("need", {}):
		need.append("%d %s" % [int(t.need[id]), GameData.item_name(id).to_lower()])
	s = s.replace("{need}", " and ".join(need)).replace("{wage}", NUMBER_WORDS[int(t.get("wage", 0))] if int(t.get("wage", 0)) < NUMBER_WORDS.size() else str(int(t.get("wage", 0))))
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
