class_name NPC
extends RefCounted
## One persistent inhabitant. Everything here is saved; the path is recomputed after loading.

var id := 0
var name := ""
var family := ""
var household := -1
var role := "adult"          # adult | child | elder | bandit
var job := ""                # miner, woodcutter, smith, ... ("" for children and elders)
var sprite := ""
var home := ""               # building id
var workplace := ""          # station, stall, field or building id
var inv := Inventory.new()
var coins := 0
var hunger := 100.0          # 100 = full
var hp := 30.0
var max_hp := 30.0
var damage := 3.0
var armor := 0.0
var alive := true
var hidden := false          # indoors (asleep at home)
var pos := Vector2.ZERO      # tile coordinates (float); the feet are at the centre of a tile
var plan: Array = []         # steps: {k: go|work|do, ...}
var path := PackedVector2Array()
var path_i := 0
var work_left := 0.0         # game minutes left on the current work step
var doing := "idle"          # what the NPC is doing, shown to the player
var anim := "idle"
var facing := Vector2.DOWN
var attack_cd := 0.0
var target := -1             # npc id being fought (-1 none, -2 the player)
var memory: Array = []       # notable events this NPC knows about
var earned := 0
var spent := 0
var tick_acc := 0.0          # for abstract (distant) simulation
var income_days: Array = []  # coins earned on each of the last 7 days (sales and wages), oldest first
var job_since := 0           # the day this villager took up the current job
var left_job := ""           # the job given up at the last change (not taken up again for a while)


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
func remember(text: String) -> void:
	memory.append(text)
	if memory.size() > 8:
		for i in memory.size():
			if not str(memory[i]).begins_with("met "):
				memory.remove_at(i)
				return
		memory.pop_front()                  # only acquaintances (many heirs): the oldest goes


func to_dict() -> Dictionary:
	return {
		"id": id, "name": name, "family": family, "household": household, "role": role, "job": job,
		"sprite": sprite, "home": home, "workplace": workplace, "inv": inv.to_dict(), "coins": coins,
		"hunger": hunger, "hp": hp, "max_hp": max_hp, "damage": damage, "armor": armor, "alive": alive,
		"hidden": hidden, "pos": [pos.x, pos.y], "doing": doing, "memory": memory.duplicate(),
		"earned": earned, "spent": spent, "income_days": income_days.duplicate(), "job_since": job_since, "left_job": left_job,
	}


static func from_dict(d: Dictionary) -> NPC:
	var n := NPC.new()
	for k in ["id", "household", "coins", "earned", "spent"]:
		n.set(k, int(d[k]))
	for k in ["name", "family", "role", "job", "sprite", "home", "workplace", "doing"]:
		n.set(k, str(d[k]))
	for k in ["hunger", "hp", "max_hp", "damage", "armor"]:
		n.set(k, float(d[k]))
	n.alive = bool(d.alive)
	n.hidden = bool(d.hidden)
	n.inv = Inventory.from_dict(d.inv)
	n.pos = Vector2(float(d.pos[0]), float(d.pos[1]))
	n.memory = d.memory.duplicate()
	n.income_days = d.get("income_days", []).duplicate()         # older saves: no history yet
	n.job_since = int(d.get("job_since", 0))
	n.left_job = str(d.get("left_job", ""))
	return n
