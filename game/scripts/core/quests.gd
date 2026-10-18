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
## asks "Any work for me?" (never as a dawn offer or a marker). The player brings what was
## asked; the wage comes from the employer's purse, in full or not at all. A harvest hand may cut
## up to the asked-for wheat from the employer's field without it being theft, and the farmers of
## that field leave it to them meanwhile. Work left undone lapses after `days` days.
## A quest with "teach" raises one of the player's skills to a level when it is done.
##
## Promised coins are set aside (owner, 2026-10-18): a quest with a reward, or work with a wage, is
## offered only by someone who can pay it, and the coins are reserved when the player accepts
## (`reserved` on the accepted quest, saved with it), so the giver cannot spend them elsewhere. The
## exact sum is paid on completion; it goes back to the giver (or the manor's treasury) when the
## quest lapses, its giver dies or the player dies. Reserved coins are counted in reserved_total().
## Work for the manor ("manor": true) is asked of the reeve and paid from the treasury: only while
## the treasury keeps its reserve after the wage, once a day, and only while the village's own
## deposits can give what is asked; the goods go into the manor's repairs.
## Wheat cut for harvest work is the employer's (owner, 2026-10-18): work that lapses with it uncut
## or kept leaves the player holding the farmer's wheat, marked stolen from them (settle_harvest).

var w                         # World
const NUMBER_WORDS := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]
var offers := {}              # npc id -> quest id offered (not yet accepted)
var last_refusal := ""        # why the last accept() failed, for the conversation


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
	for id in g.get("deposit_left", {}):           # work at the village's own seams, while they last
		if deposit_left(id) < int(g.deposit_left[id]):
			return false
	if t.get("manor", false) and w.player.manor_day == w.day():
		return false                               # one day's work for the manor a day
	if promised(t) > 0 and not can_fund(n, t):
		return false
	return true


## The coins a quest promises: the wage for work, else the reward.
static func promised(t: Dictionary) -> int:
	return int(t.get("wage", 0)) if t.get("hire", false) else int(t.get("reward", 0))


## Whether this giver can set the promised coins aside now: their own purse, or for the manor's work
## the treasury, keeping its reserve of treasury_reserve_days of obligations (as day labour does).
func can_fund(n: NPC, t: Dictionary) -> bool:
	var pay := promised(t)
	if t.get("manor", false):
		return w.treasury - pay >= w.brain.daily_obligations() * float(GameData.b("treasury_reserve_days"))
	return n != null and n.coins >= pay


## Set the promised coins aside for this accepted quest. False if the giver cannot.
func _reserve(q: Dictionary, n: NPC, t: Dictionary) -> bool:
	var pay := promised(t)
	q.reserved = 0
	if pay <= 0:
		return true
	if not can_fund(n, t):
		return false
	if t.get("manor", false):
		w.treasury -= pay
	else:
		n.coins -= pay
	q.reserved = pay
	return true


## The reserved coins go back to whoever set them aside (the giver, or the treasury for the manor's
## work). A giver who has died gets them before what they leave is passed on (on_giver_died).
func _release(q: Dictionary) -> void:
	var held := int(q.get("reserved", 0))
	q.reserved = 0
	if held <= 0:
		return
	if template(q.id).get("manor", false):
		w.treasury += held
	else:
		var n: NPC = w.npc(int(q.giver))
		if n:
			n.coins += held


## Coins set aside for the player's accepted quests (part of the village's money, not spendable).
func reserved_total() -> int:
	var t := 0
	for q in w.player.quests:
		t += int(q.get("reserved", 0))
	return t


## How much of an ore (or stone) the village's own deposits still hold.
func deposit_left(id: String) -> int:
	var left := 0
	for d in w.deposits:
		if d.ore == id:
			left += int(d.amount)
	return left


func field_of(n: NPC) -> Dictionary:
	for f in w.fields:
		if f.id == n.workplace:
			return f
	return {}


# ---------------------------------------------------------------- paid work ------------------
## Whether this villager's work is the kind that can hire the player (a farmer, a woodcutter, a
## miner: any job a hire template names), so "Any work for me?" is worth asking.
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
		if not t.get("hire", false) or str(t.giver.get("job", "")) != n.job:
			continue
		if t.get("manor", false):
			if w.player.manor_day == w.day():
				return "You've done your day for the manor. Come back tomorrow."
			if not can_fund(n, t):
				return "The manor's chest can't spare a wage just now. Ask me another day."
			return "The stone pits are worked out. There's no quarrying to be had."
		if not can_fund(n, t):
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
	last_refusal = ""
	if hire != "" and (not t.get("hire", false) or not _wants(n, t) or not active_from(n).is_empty()):
		return {}
	if t.is_empty():
		return {}
	if w.player.quests.size() >= int(GameData.b("quest_max_active")):
		last_refusal = "You have too many tasks already (%d)." % int(GameData.b("quest_max_active"))
		return {}
	var q := {"id": t.id, "giver": n.id, "day": w.day(), "target": -1}
	if not _reserve(q, n, t):
		# the giver spent what they meant to pay since offering it: the offer is withdrawn
		offers.erase(n.id)
		last_refusal = "%s can no longer pay what they offered." % n.name
		return {}
	if t.get("manor", false):
		w.player.manor_day = w.day()
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


## Whether the promised coins are set aside, or (a quest accepted before reserving, from an older
## save) the giver can set them aside now.
func can_pay(q: Dictionary) -> bool:
	var t := template(q.id)
	if int(q.get("reserved", 0)) >= promised(t):
		return true
	return can_fund(w.npc(int(q.giver)), t)


## What the last completed quest taught ("Crafting is now level 2. Unlocked: ..."), or "".
var last_learned := ""


## Hand over the goods (they go to the giver; for the manor's work, into its repairs) and pay the
## promised coins set aside for it, exactly; a teacher raises the skill they teach.
## Returns the coins paid, -1 if the quest is not ready, -2 if the coins are not set aside and the
## giver cannot pay (only a quest from an older save, accepted before reserving).
func complete(q: Dictionary) -> int:
	var n: NPC = w.npc(int(q.giver))
	var t := template(q.id)
	last_learned = ""
	if n == null or not n.alive or not ready(q):
		return -1
	if int(q.get("reserved", 0)) < promised(t):
		_release(q)
		if not _reserve(q, n, t):
			return -2
	if t.has("need"):
		w.player.inv.remove_all(t.need)
		w.player.trim_stolen()
		for id in t.need:
			if t.get("manor", false):
				w.stat("used_works_" + id, int(t.need[id]))       # used up in mending
			else:
				n.inv.add(id, int(t.need[id]))
	var hired: bool = t.get("hire", false)
	var pay := int(q.get("reserved", 0))
	q.reserved = 0
	if t.get("manor", false):
		w.stat("gov_wages", pay)
		w.stat("gov_player_work", pay)
	else:
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
			_release(q)
			w.player.quests.erase(q)
			w.note("\"%s\" can no longer be finished: %s." % [t.get("title", q.id), "the one who asked has died"])
		elif t.get("hire", false) and w.day() - int(q.day) > int(t.get("days", 1)):
			_release(q)
			w.player.quests.erase(q)
			w.note("\"%s\" lapsed: the work for %s %s was not done in time." % [t.title, n.name, n.family])
			settle_harvest(q, n)


## Saves before reserving (save_version 1-6): each accepted quest's promised coins are set aside now
## if its giver can pay them; otherwise completing it pays only once they can (can_pay).
func migrate_reserves() -> void:
	for q in w.player.quests:
		if not q.has("reserved"):
			var t := template(q.id)
			var n: NPC = w.npc(int(q.giver))
			if not _reserve(q, n, t):
				q.reserved = 0


## A giver dies: the coins set aside for their quest go back into their purse first, so they pass to
## their heir (or lie where they fell) with the rest. The quest is dropped at the next dawn.
func on_giver_died(n: NPC) -> void:
	for q in w.player.quests:
		if int(q.giver) == n.id and not template(q.id).get("manor", false):
			_release(q)


## The player died: what was set aside for their quests goes back (the heir starts without them).
func release_all() -> void:
	for q in w.player.quests:
		_release(q)


## Harvest work that lapsed: the wheat cut for it (q.harvested) is still the farmer's. What the player
## carries of it is marked stolen from them, then what lies in the home chest; the farmer knows who
## kept it (they remember catching the player), and it is a theft on the player's record.
func settle_harvest(q: Dictionary, n: NPC) -> void:
	var owed := int(q.get("harvested", 0))
	if owed <= 0 or n == null:
		return
	var p: PlayerState = w.player
	var carried := mini(owed, p.inv.count("wheat") - p.stolen_count("wheat"))
	p.mark_stolen("wheat", n.id, carried)
	var marked := 0
	for o in p.chest_stolen.get("wheat", {}):
		marked += int(p.chest_stolen.wheat[o])
	var stored := mini(owed - carried, maxi(0, p.chest.count("wheat") - marked))
	if stored > 0:
		var m: Dictionary = p.chest_stolen.get("wheat", {})
		m[str(n.id)] = int(m.get(str(n.id), 0)) + stored
		p.chest_stolen["wheat"] = m
	n.remember("caught %s %s keeping the wheat I hired them to cut" % [p.name, p.family])
	p.crimes.append({"day": w.day(), "kind": "theft", "what": "%d wheat cut for %s %s and kept" % [owed, n.name, n.family], "victim": n.id, "witnesses": 1})
	w.stat("player_theft")
	w.note("%s %s kept the %d wheat %s %s hired them to cut." % [p.name, p.family, owed, n.name, n.family])


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
