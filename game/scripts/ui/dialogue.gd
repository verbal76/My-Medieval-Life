class_name Dialogue
extends RefCounted
## What a villager says to the player, in their own voice, built only from the simulation's state:
## their job and what they are doing, their hunger, their household's reckoning (hh.econ), what
## they remember of the player (NPC.memory) and the village record (World.log_lines). Presentation
## only: nothing here changes the world, except `meet`, which adds a memory. Wording varies by the
## villager's id and the day, never by a random number generator.

const NUMBERS := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"eleven", "twelve"]
# what each job is, in the worker's words, from what npc_brain.gd has them do
const JOB_WORDS := {
	"miner": "I dig ore in the mine and sell it to the smiths and the merchants.",
	"prospector": "I read the ground for signs of ore, take samples and have the smith assay them.",
	"laborer": "I break stone and coal in the mine and sell it at the market.",
	"woodcutter": "I fell trees and sell the logs to the carpenters and the cooks.",
	"carpenter": "I saw logs into planks for the smiths and the market.",
	"smith": "I smelt ore into bars and forge tools, swords and armour.",
	"tanner": "I tan hides into leather.",
	"cook": "I cook pottage, roast meat and brew ale for the tavern.",
	"farmer": "I work my field: sow it, tend it and bring in the wheat.",
	"hunter": "I hunt game in the woods and sell the meat and hides.",
	"tavernkeeper": "I keep the tavern and serve pottage, roast meat and ale.",
	"guard": "I keep watch over the village for the manor, against the bandits in the woods.",
	"reeve": "I keep the manor: it pays the guards and its hands, and feeds households that run short.",
	"sage": "I study lore, and I teach the rules of fire to those who can pay. I am the village apothecary too: bandages, poultices and tonics, and I buy wild flowers for them.",
	"manor_hand": "I work for the manor, for a day's wage.",
}
const STALL_WORDS := {"raw": "ore, stone, logs and planks", "food": "food: grain, meat, pottage and ale",
	"goods": "tools, weapons, armour and leather"}


## A choice among lines that changes with the villager and the day, the same on every machine.
static func _pick(w: World, n: NPC, options: Array, salt := 0) -> String:
	return options[posmod(n.id * 7 + w.day() * 13 + salt * 5, options.size())]


static func _player_name(w: World) -> String:
	return "%s %s" % [w.player.name, w.player.family]


static func _article(word: String) -> String:
	return ("an " if word.substr(0, 1).to_lower() in ["a", "e", "i", "o", "u"] else "a ") + word


## "Reed's", "Hobbs'": a name's possessive.
static func possessive(name: String) -> String:
	return name + ("'" if name.ends_with("s") or name.ends_with("S") else "'s")


## One sentence: first letter capital, closed with a full stop unless it already ends in . ! ? or a quote.
static func sentence(text: String) -> String:
	var t := text.strip_edges()
	if t == "":
		return ""
	t = t.substr(0, 1).to_upper() + t.substr(1)
	if not t[t.length() - 1] in [".", "!", "?", "\"", "”"]:
		t += "."
	return t


## Whether a village-record line can be repeated by a villager as news: not addressed to the player
## ("You ...", "Your ..."), not a bare heading.
static func _repeatable(text: String) -> bool:
	var t := text.strip_edges()
	return t != "" and not (t.begins_with("You ") or t.begins_with("Your ") or t.begins_with("You'") or t.contains(" you ") or t.contains(" your "))


static func _job_name(job: String) -> String:
	return job.replace("_", " ")


# ---------------------------------------------------------------- what they know of the player
static func met(w: World, n: NPC) -> bool:
	return n.memory.has("met " + _player_name(w))


## Record that this villager has spoken with the player (once), so later meetings are friendlier.
static func meet(w: World, n: NPC) -> void:
	if n.role != "bandit" and not met(w, n):
		n.remember("met " + _player_name(w))


static func attacked(w: World, n: NPC) -> bool:
	return n.memory.has("attacked by " + w.player.name)


## The animal of theirs this villager knows the player killed (the latest), or "".
static func animal_killed(w: World, n: NPC) -> String:
	var prefix := "%s killed my " % w.player.name
	for i in range(n.memory.size() - 1, -1, -1):
		if str(n.memory[i]).begins_with(prefix):
			return str(n.memory[i]).substr(prefix.length())
	return ""


## What this villager saw the player take (the latest), in plain words, or "".
static func theft_seen(w: World, n: NPC) -> String:
	var prefix := "saw %s take " % _player_name(w)
	for i in range(n.memory.size() - 1, -1, -1):
		var m: String = n.memory[i]
		if m.begins_with(prefix):
			return _plain_what(w, n, m.substr(prefix.length()))
	return ""


## Whether this villager caught the player stealing from them: a hand in their pocket, their own
## goods offered back to them, or (a guard) a theft they stopped.
static func caught(w: World, n: NPC) -> bool:
	var prefix := "caught %s " % _player_name(w)
	for m in n.memory:
		if str(m).begins_with(prefix):
			return true
	return false


## "3 wheat from f2" as the speaker would say it: "3 wheat from my field" or "... Walter Reed's field".
static func _plain_what(w: World, n: NPC, what: String) -> String:
	var at := what.rfind(" from ")
	if at < 0:
		return what
	var fid := what.substr(at + 6)
	for f in w.fields:
		if str(f.id) != fid:
			continue
		var workers := w.field_workers(f)
		if workers.has(n):
			return what.substr(0, at) + " from my field"
		for fo: NPC in workers:
			return what.substr(0, at) + " from %s field" % possessive(full_name(fo))
		return what.substr(0, at) + " from a field"
	return what.substr(0, at) + " from a field"


# ---------------------------------------------------------------- who they are
## Name and family, once: "Old Lorekeeper" is already of the Lorekeepers.
static func full_name(n: NPC) -> String:
	if n.family == "" or n.name.ends_with(n.family):
		return n.name
	return "%s %s" % [n.name, n.family]


## "Denise Reed, a child of the Reed family"
static func describe(w: World, n: NPC) -> String:
	if n.role == "bandit":
		return "%s, a bandit from the woods" % n.name
	var who := full_name(n)
	if n.id == w.sage_id:
		return who + ", the village sage"
	if n.id == w.reeve_id:
		return who + ", the reeve of the manor"
	var what := n.role if n.role != "adult" else (_job_name(n.job) if n.job != "" else "")
	var line := ("%s, of the %s family, out of work" % [who, n.family]) if what == "" else ("%s, %s of the %s family" % [who, _article(what), n.family])
	var bond := bond_words(w, n)
	return line + ("  ·  " + bond if bond != "" else "")


## How the player stands with a villager, for the talk window: partner, courting, friend, or "".
static func bond_words(w: World, n: NPC) -> String:
	var st := w.relations.stage(Life.PLAYER_ID, n.id)
	if st == "partners":
		return "your partner"
	if st == "courting":
		return "courting you"
	return "your friend" if w.relations.player_friend(n) else ""


## How a villager feels about the player, in words (the gift window): from their regard and attraction.
static func regard_words(w: World, n: NPC) -> String:
	var t: Dictionary = w.relations.peek(Life.PLAYER_ID, n.id)
	var a := float(t.attraction)
	var g := float(t.regard)
	var c := Relations.cfg()
	if a >= float(c.propose_at):
		return "is plainly in love with you"
	if a >= float(c.court_at):
		return "is sweet on you"
	if a > 0.0:
		return "seems to like your company"
	if g >= float(c.befriend_at):
		return "thinks well of you"
	if g > 0.0:
		return "is warming to you"
	return "hardly knows you"


## A villager is busy while walking somewhere, at work with their hands, or fighting: then they
## only call out a line as they carry on. Standing about, minding a stall or resting, they talk.
static func busy(n: NPC) -> bool:
	if n.target != -1:
		return true
	if n.plan.is_empty():
		return false
	var s: Dictionary = n.plan[0]
	return s.k == "go" or (s.k == "work" and s.get("anim", "work") == "work")


# ---------------------------------------------------------------- what they say
## What they say when the conversation opens: 1-3 short sentences.
static func opening(w: World, n: NPC) -> String:
	if n.role == "bandit":
		return "Your purse or your life."
	var animal := animal_killed(w, n)
	if animal != "" and not attacked(w, n):
		return _pick(w, n, ["You killed my %s. Get away from me." % animal, "That %s was mine, and you killed it. Keep away." % animal])
	if attacked(w, n):
		return _pick(w, n, {
			"child": ["You hurt me! Go away!", "Go away! You hit me!"],
			"elder": ["You raised your hand to me. I have nothing to say to you.", "Keep away from me. I remember what you did."],
		}.get(n.role, ["You attacked me. Stay away from me.", "You! After what you did to me? Keep your distance."]))
	var stolen := theft_seen(w, n)
	if stolen != "":
		return _pick(w, n, {
			"child": ["I saw you take %s! That's stealing!", "You took %s. I saw you!"],
			"elder": ["I saw you take %s. Shame on you.", "These old eyes saw you take %s. I won't forget it."],
		}.get(n.role, ["I saw you take %s. I'll be watching you.", "I know what you did: I saw you take %s."])) % stolen
	if caught(w, n):
		return _pick(w, n, ["I caught you stealing. Keep your hands to yourself.", "Thief. I know what you are; I caught you at it."])
	var lines: Array = [_greeting(w, n)]
	if n.id == w.sage_id:
		lines.append("Fire answers those who learn its rules. I can teach you to call it.")
	elif n.id == w.reeve_id:
		lines.append("The manor sells or leases land wherever it lies clear: pick your spot and build there; the coins go to the manor. The two clearings at the forest edge north of the east houses are surveyed already.")
		if w.property.market().any(func(r): return w.property.is_home(r) or not w.property.building_on(r).is_empty()):
			lines.append("And the manor has an empty house to sell or let. Ask me about land and houses.")
	else:
		lines.append(_doing(w, n))
	var hungry := _hunger(w, n) if not _eating(n) else ""
	if hungry != "":
		lines.append(hungry)
	return " ".join(lines)


static func _greeting(w: World, n: NPC) -> String:
	var you := w.player.name
	if met(w, n):
		return _pick(w, n, {
			"child": ["Hello again, %s!" % you, "It's you again!"],
			"elder": ["Ah, %s. Good to see you again." % you, "You again, %s. Sit a while." % you],
		}.get(n.role, ["Good day to you, %s." % you, "Hello again, %s." % you, "Ah, %s. What can I do for you?" % you]), 1)
	return _pick(w, n, {
		"child": ["Who are you? I've never seen you before.", "Are you new? What's your name?"],
		"elder": ["A new face. Not many strangers come this way.", "I don't know you, stranger. Where have you come from?"],
	}.get(n.role, ["I don't know you. You're new here?", "Good day, stranger.", "You're not from this village, are you?"]), 1)


## NPC.doing as words: a recipe's id becomes "making <what it makes>".
static func _doing_words(n: NPC) -> String:
	var r := n.doing.replace(" ", "_")
	if GameData.recipes.has(r):
		return "making %s" % GameData.item_name(GameData.recipes[r].out.keys()[0]).to_lower()
	return n.doing


## What they are doing right now (NPC.doing), said aloud.
static func _doing(w: World, n: NPC) -> String:
	var d := _doing_words(n)
	if d.begins_with("out of work: needs "):
		return "I can't work: I need %s." % d.substr(19)
	match d:
		"playing":
			return _pick(w, n, ["I'm playing!", "We're playing a game. Want to play?"], 2)
		"lost":
			return "I seem to have lost my way."
		"idle", "":
			return "I'm not doing much just now."
	return _pick(w, n, ["Right now I'm %s." % d, "I'm %s just now." % d], 2)


static func _eating(n: NPC) -> bool:
	return n.doing in ["eating", "going home to eat", "buying a meal", "eating on the family's tab", "buying grain for porridge"]


static func _hunger(w: World, n: NPC) -> String:
	if n.hunger <= 0.0:
		return "I'm starving." if n.role != "child" else "I'm so hungry it hurts."
	if n.hunger < float(GameData.b("eat_below")):
		return {"child": "I'm hungry!", "elder": "My stomach is empty, though."}.get(n.role, "And I could do with something to eat.")
	return ""


## "What do you do?"
static func work(w: World, n: NPC) -> String:
	if n.role == "bandit":
		return "What I like. Hand over your purse."
	if n.role == "child":
		return _pick(w, n, ["Me? I play! I'm too little to work.", "I play all day. When I'm big I'll work like the grown-ups."], 3)
	if n.role == "elder":
		return _pick(w, n, ["My working days are done. I take the air and watch the village go by.", "I'm too old for work now. I walk a little and watch the young ones."], 3)
	var lines: Array = []
	if n.job == "":
		lines.append("I have no work just now.")
	elif n.job == "merchant" and w.stalls.has(n.workplace):
		lines.append("I keep a stall in the market and sell %s." % STALL_WORDS.get(str(w.stalls[n.workplace].get("kind", "")), "what I can"))
	elif n.job == "farmer" and not w.brain._keeper_pen(n).is_empty():
		lines.append(JOB_WORDS.farmer.trim_suffix(".") + ", and I keep the %s." % str(GameData.b("animals")[w.brain._keeper_pen(n).kind].name).to_lower())
	else:
		lines.append(JOB_WORDS.get(n.job, "I work as %s." % _article(_job_name(n.job))))
	var days := w.day() - n.job_since
	if n.left_job != "" and n.job != "":
		lines.append("I was %s before; I took this up %s." % [_article(_job_name(n.left_job)), _days_ago(days)])
	elif n.left_job != "":
		lines.append("I used to be %s." % _article(_job_name(n.left_job)))
	if n.job != "" and not n.job in ["guard", "reeve", "sage", "manor_hand"] and n.income_days.size() >= 3 and n.avg_income(5) < 0.5:
		lines.append("Nobody has paid me anything these last few days.")
	return " ".join(lines.slice(0, 3))


static func _days_ago(days: int) -> String:
	if days <= 0:
		return "today"
	if days == 1:
		return "yesterday"
	return "%s days ago" % (NUMBERS[days] if days < NUMBERS.size() else str(days))


static func _members(w: World, h: int) -> Array:
	var out := []
	for m in w.households[h].members:
		var o := w.npc(m)
		if o and o.alive:
			out.append(o)
	return out


static func _home_name(w: World, id: String) -> String:
	var b: Dictionary = w.buildings.get(id, {})
	if b.has("name"):
		return str(b.name)
	return {"manor": "the manor", "hut": "the hut", "smithy": "the smithy", "tavern": "the tavern"}.get(str(b.get("type", "")), "")


## "How are things at home?": who they live with, how the pantry stands, and the household's
## troubles from its reckoning (hh.econ), the manor's relief and their memories of deaths.
static func home(w: World, n: NPC) -> String:
	if n.household < 0:
		return "Home is the woods. Mind your own business."
	var hh: Dictionary = w.households[n.household]
	var others := _members(w, n.household).filter(func(o: NPC) -> bool: return o != n)
	var lines: Array = []
	var where := _home_name(w, hh.home)
	var at := (" at " + where) if where != "" else ""
	if others.is_empty():
		lines.append("I live alone%s." % at)
	else:
		var names: Array = others.slice(0, 2).map(func(o: NPC) -> String: return o.name)
		var rest := others.size() - names.size()
		var with_whom: String = " and ".join(names) if rest == 0 else ", ".join(names) + " and %s other%s" % [NUMBERS[rest] if rest < NUMBERS.size() else str(rest), "" if rest == 1 else "s"]
		lines.append("I live%s with %s." % [at, with_whom])
	var econ: Dictionary = hh.get("econ", {})
	var days: float = float(econ.days) if econ.has("days") else w.brain.household_food_days(n.household)
	var kid := n.role == "child"
	var we := "We" if not others.is_empty() else "I"
	if days < 1.0:
		lines.append("There's hardly anything to eat at home." if kid else "%s have hardly any food left." % we)
	elif days < float(GameData.b("relief_trigger_days")):
		lines.append("There isn't much to eat." if kid else "Food is getting short.")
	elif days < float(GameData.b("household_savings_days")):
		lines.append("We have food!" if kid else "%s have enough to eat, for now." % we)
	else:
		lines.append("We have lots of food!" if kid else "%s have plenty put by." % we)
	# one trouble, the gravest first
	var death := ""
	for i in range(n.memory.size() - 1, -1, -1):
		var m: String = n.memory[i]
		if m.ends_with(")") and m.contains(" died ("):
			var who := m.substr(0, m.find(" died ("))
			var cause := m.substr(m.find(" died (") + 7).trim_suffix(")")
			death = ("%s starved to death." % who) if cause == "starvation" else ("We lost %s: %s." % [who, cause])
			break
	var relief: Array = hh.get("relief_days", []).filter(func(d) -> bool: return int(d) > w.day() - 7)
	if death != "":
		lines.append(death)
	elif not relief.is_empty():
		lines.append("The manor has had to send us food this week.")
	elif econ.has("sustainable") and not bool(econ.sustainable) and int(econ.get("streak", 0)) > 0:
		lines.append(("What %s earn doesn't cover what %s need." % [we.to_lower(), we.to_lower()]) if not kid else "The grown-ups worry about money.")
	elif hh.pantry.count("log") < 1:
		lines.append(("%s have no firewood for tonight." % we) if not kid else "It's cold at home. We've no wood.")
	return " ".join(lines.slice(0, 3))


## "Any news?": what they know happened to them (a theft they found), then the latest lines of
## the village record that name them or their family, else the latest village news.
static func news(w: World, n: NPC) -> String:
	var lines: Array = []
	var prefix := "found "
	for i in range(n.memory.size() - 1, -1, -1):
		var m: String = n.memory[i]
		if m.begins_with(prefix) and m.ends_with(" missing"):
			lines.append("Someone took %s." % _plain_what(w, n, m.substr(prefix.length(), m.length() - prefix.length() - 8)).trim_suffix("."))
			break
	var ours := RegEx.create_from_string("\\b%s\\b" % n.family) if n.family != "" else null
	var about: Array = []
	var other: Array = []
	for i in range(w.log_lines.size() - 1, -1, -1):
		var line: String = w.log_lines[i]
		var text := line.substr(line.find("] ") + 2) if line.begins_with("[") and line.find("] ") > 0 else line
		if not _repeatable(text):
			continue
		text = sentence(text)
		if about.has(text) or other.has(text) or lines.has(text):
			continue
		if ours and ours.search(text) and about.size() < 2:
			about.append(text)
		elif other.size() < 2:
			other.append(text)
		if about.size() >= 2 and other.size() >= 2:
			break
	if not about.is_empty():
		lines.append(_pick(w, n, ["Have you heard?", "People are talking."], 4) + " " + " ".join(about))
	elif not other.is_empty():
		lines.append(("Nothing about us. But they say: " if lines.is_empty() else "And they say: ") + other[0])
	if w.relations.player_friend(n):             # a friend tells the player who is courting (CRT-06)
		var gossip := _courting_gossip(w, n)
		if gossip != "":
			lines.append(gossip)
	if lines.is_empty():
		return "Nothing much has happened." if n.role != "child" else "Nothing happens here. It's boring!"
	return " ".join(lines)


## The line a busy villager calls out as they carry on: cold if they know of the player's crime,
## wary to a stranger, friendly to someone they have spoken with.
static func brush_off(w: World, n: NPC) -> String:
	if n.role == "bandit":
		return "Your purse or your life."
	if attacked(w, n):
		return _pick(w, n, ["Stay away from me.", "Keep your distance!", "Don't come near me!"], 6)
	if animal_killed(w, n) != "":
		return _pick(w, n, ["You killed my %s!" % animal_killed(w, n), "Keep away from my animals!"], 6)
	if theft_seen(w, n) != "" or caught(w, n):
		return _pick(w, n, ["Thief! Keep away.", "I saw what you did.", "Stay away from me, thief."], 6)
	if n.target != -1:
		return "Not now!"
	var you := w.player.name
	if not met(w, n):
		match n.role:
			"child":
				return _pick(w, n, ["Who are you?", "Can't stop, stranger!", "Don't know you!"], 6)
			"elder":
				return _pick(w, n, ["Who might you be? Another time.", "Not now, stranger."], 6)
		return _pick(w, n, ["Who are you? I've work to do.", "Don't know you. I'm busy.", "Not now, stranger."], 6)
	if _eating(n):
		return "Can't stop, I need to eat!"
	match n.role:
		"child":
			return _pick(w, n, ["Can't catch me!", "Later, %s! I'm playing!" % you], 6)
		"elder":
			return _pick(w, n, ["Another time, %s." % you, "Not now, dear. I'm on my way."], 6)
	if n.plan[0].k == "work":
		return _pick(w, n, ["Can't talk, I'm %s!" % _doing_words(n), "Sorry, %s, can't stop now!" % you], 6)
	return _pick(w, n, ["Sorry, can't stop now!", "I have to be somewhere, %s!" % you, "Can't talk right now!"], 6)


## Between friends: who in the village is courting whom (the newest courtship the villager knows of).
static func _courting_gossip(w: World, n: NPC) -> String:
	var best := -1
	var pair: Array = []
	for k in w.relations.ties:
		var t: Dictionary = w.relations.ties[k]
		if str(t.stage) != "courting" or int(t.since) <= best:
			continue
		var ids: PackedStringArray = str(k).split(":")
		var a := w.npc(int(ids[0]))
		var b := w.npc(int(ids[1]))
		if a != null and b != null and a != n and b != n and a.alive and b.alive:
			best = int(t.since)
			pair = [a, b]
	if pair.is_empty():
		return ""
	return "Between you and me, %s %s is courting %s %s." % [pair[0].name, pair[0].family, pair[1].name, pair[1].family]
