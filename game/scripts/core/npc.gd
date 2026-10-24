class_name NPC
extends RefCounted
## One persistent inhabitant. Everything here is saved; the path is recomputed after loading.

var id := 0
var name := ""
var family := ""
## Bumped whenever any villager's job, workplace or life changes: NPCBrain caches who holds each
## trading role and rebuilds it when this moves (PERF-04).
static var roles_version := 0

var household := -1
var role := "adult"          # adult | child | elder | bandit
var job := "":               # miner, woodcutter, smith, ... ("" for children and elders)
	set(v):
		job = v
		roles_version += 1
var sprite := ""
var home := ""               # building id
var workplace := "":         # station, stall, field or building id
	set(v):
		workplace = v
		roles_version += 1
var inv := Inventory.new()
var coins := 0
var hunger := 100.0          # 100 = full
var hp := 30.0
var max_hp := 30.0
var damage := 3.0
var armor := 0.0
var alive := true:
	set(v):
		alive = v
		roles_version += 1
var pos := Vector2.ZERO      # tile coordinates (float); the feet are at the centre of a tile
var depth := 0               # MIN-A: the depth they are on (0 the surface, -1 the mine gallery); saved only below the surface
var plan: Array = []         # steps: {k: go|work|do, ...}
var path := PackedVector2Array()
var path_i := 0
var work_left := 0.0         # game minutes left on the current work step
var doing := "idle"          # what the NPC is doing, shown to the player
var anim := "idle"           # "sleep": lying in bed (World.asleep); indoors is where pos is (World.place_of)
var facing := Vector2.DOWN
var attack_cd := 0.0
var target := -1             # npc id being fought (-1 none, -2 the player)
var target_ref := ""         # A7, A8: with target -2, which player ("player", "player:<pid>"; "" the acting player, as before). Not saved, as target is not
var pursuit := {}            # A2 (GP-CRIME-PURSUIT): a guard on a player's case: {ref, state: pursuing | responding | searching, at: [x, y] last-known, t, until, cells: [[x, y]], i, share}; {} none. Saved (optional key): the wanted hunt survives save and load (Justice)
var chase_route := false     # S3: a guard chasing a player is following `path` round what stands between them (NPCBrain.fight; not saved, as `target` is not)
var memory: Array = []       # notable events this NPC knows about
var skills := {}             # skill -> xp, as the player's (PAR-01: the same curve, gates and effects; Skills)
var talked := {}             # A6 (GP-DIALOGUE): what this villager has told each listener: {player ref: {event key: day}}; saved (optional key), so nothing is said over and over
var report := {}             # an attack this villager knows of and will tell a guard: {offender, t, how} (PAR-05)
var earned := 0
var spent := 0
var tick_acc := 0.0          # for abstract (distant) simulation
var income_days: Array = []  # coins earned on each of the last 7 days (sales and wages), oldest first
var job_since := 0           # the day this villager took up the current job
var left_job := ""           # the job given up at the last change (not taken up again for a while)
# B8-029: age and explicit relationships (Life). A shared house implies none of these.
var born := 0.0              # game minutes (negative: older than the game); age in years is Life.age_years
var sex := "male"            # male | female
var mother := -1             # npc id; a player's person id (World.person_id: -2 the host's line); -1 unknown
var birth_family := ""       # the surname born with, kept when a child taken in takes another (FAM-04); "" unchanged
var clan := ""               # "bandit": an orphan no household could take, a dependant of the bandit camp (FAM-07, OD-11); "" none
var father := -1
var partner := -1            # npc id, a player's person id, -1 none
var children: Array = []     # npc ids
var away := ""               # MIGRATE-18: the settlement this villager moved to (alive is false then; Migration); "" otherwise
var became_player := false   # ID-01: this child became the player character (Life.make_heir): the record is kept (alive is false), not a body


func cell() -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


## Average daily earnings over the last `days` recorded days (0 with no history).
func avg_income(days := 5) -> float:
	var recent := income_days.slice(-days)
	if recent.is_empty():
		return 0.0
	var t := 0.0
	for v in recent:
		t += float(v)
	return t / recent.size()


## Keep the last 8 memories, but never forget having met someone ("met <name>"): a villager who
## knows the player stays acquainted however busy the village gets.
## The health a rest restores to (PlayerState.hp_cap's counterpart; villagers wear no health gear).
func hp_cap() -> float:
	return max_hp


func level(skill: String) -> int:
	return Skills.level(self, skill)


func gain(skill: String, xp: int) -> int:
	return Skills.gain(self, skill, xp)


func remember(text: String) -> void:
	memory.append(text)
	if memory.size() > 8:
		for i in memory.size():
			if not str(memory[i]).begins_with("met "):
				memory.remove_at(i)
				return
		memory.pop_front()                  # only acquaintances (many heirs): the oldest goes


func to_dict() -> Dictionary:
	var d := {
		"id": id, "name": name, "family": family, "household": household, "role": role, "job": job,
		"sprite": sprite, "home": home, "workplace": workplace, "inv": inv.to_dict(), "coins": coins,
		"hunger": hunger, "hp": hp, "max_hp": max_hp, "damage": damage, "armor": armor, "alive": alive,
		"pos": [pos.x, pos.y], "doing": doing, "memory": memory.duplicate(),
		"earned": earned, "spent": spent, "income_days": income_days.duplicate(), "job_since": job_since, "left_job": left_job,
		"born": born, "sex": sex, "mother": mother, "father": father, "partner": partner, "children": children.duplicate(),
		"birth_family": birth_family,
		"clan": clan,
		"skills": skills.duplicate(),
		"report": report.duplicate(),
	}
	if not pursuit.is_empty():
		d.pursuit = pursuit.duplicate(true)  # A2: written only for a guard on a case
	if not talked.is_empty():
		d.talked = talked.duplicate(true)    # A6: written only once they have told a player something
	if depth != 0:
		d.level = depth                  # MIN-A: written only below the surface
	if away != "":
		d.away = away                    # MIGRATE-18: written only for a villager who moved away
	if became_player:
		d.became_player = true           # ID-01: written only for a child who became the player
	return d


static func from_dict(d: Dictionary) -> NPC:
	var n := NPC.new()
	for k in ["id", "household", "coins", "earned", "spent"]:
		n.set(k, int(d[k]))
	for k in ["name", "family", "role", "job", "sprite", "home", "workplace", "doing"]:
		n.set(k, str(d[k]))
	for k in ["hunger", "hp", "max_hp", "damage", "armor"]:
		n.set(k, float(d[k]))
	n.alive = bool(d.alive)
	# save_version 1-3 had "hidden" (at home on the door step): World._move_indoors puts them inside
	n.inv = Inventory.from_dict(d.inv)
	n.pos = Vector2(float(d.pos[0]), float(d.pos[1]))
	n.away = str(d.get("away", ""))                           # MIGRATE-18: older saves: nobody has moved away
	n.became_player = bool(d.get("became_player", false))     # ID-01: older saves: no child had been kept as the player
	n.depth = int(d.get("level", 0))                          # MIN-A: older saves and the surface: none
	n.memory = d.memory.duplicate()
	n.income_days = d.get("income_days", []).duplicate()         # older saves: no history yet
	n.job_since = int(d.get("job_since", 0))
	n.left_job = str(d.get("left_job", ""))
	n.born = float(d.get("born", 0.0))
	n.sex = str(d.get("sex", "male"))
	for k in ["mother", "father", "partner"]:
		n.set(k, int(d.get(k, -1)))
	n.children = (d.get("children", []) as Array).map(func(c): return int(c))
	n.birth_family = str(d.get("birth_family", ""))          # older saves: none changed
	n.clan = str(d.get("clan", ""))                           # older saves: none
	n.report = (d.get("report", {}) as Dictionary).duplicate()        # older saves: none
	n.pursuit = (d.get("pursuit", {}) as Dictionary).duplicate(true)  # A2: older saves (a Build 20 save): no guard on a case
	for ref in d.get("talked", {}):                                   # A6: older saves: nothing told yet
		var t := {}
		for k in d.talked[ref]:
			t[str(k)] = int(d.talked[ref][k])
		n.talked[str(ref)] = t
	if not n.pursuit.is_empty():
		n.pursuit.i = int(n.pursuit.get("i", 0))
		if str(n.pursuit.get("state", "")) == "pursuing":
			n.target = World.id_of_ref(str(n.pursuit.get("ref", World.PLAYER)))     # a guard who had the offender in sight at the save still has (fight() checks the sight at once); MP C6: that player's own id
			if n.target == -1:
				n.target = Life.PLAYER_ID
	for k in d.get("skills", {}):                             # older saves (< 15): World.load_dict seeds them (Skills.seed_villagers)
		n.skills[str(k)] = int(d.skills[k])
	return n
