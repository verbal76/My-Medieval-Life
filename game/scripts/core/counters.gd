class_name Counters
extends RefCounted
## Skilled-trade counters (CTR-01..03, ARM-01; owner directives 2026-10-20 and 2026-10-21): a business's customer counter
## (a station whose type is in KEEPERS, e.g. the Smithy and Armory's armory_counter) has no keeper standing at it. The
## player at the counter rings for service (a prompt, A): the business's available keeper walks there by the ordinary path
## (no teleport) and serves while the player is there; the trade itself is the ordinary shop window (World.at_post is
## true for a keeper serving a counter). A keeper is available when alive, awake, in working hours, not fighting, not
## hungry enough to eat and not on a building contract; work in hand (forging at the anvil) is put down, and the station
## is freed, since a recipe takes its materials only when it is done. Otherwise the player is told why. One service a
## counter at a time: a second ring while a keeper is coming says so. A service is not saved (villagers' plans are not):
## after loading nobody is serving until rung for again.
##
## One mechanism for every skilled business: a new counter needs only its station type and its keepers' jobs here.

const KEEPERS := {"armory_counter": ["smith"]}            # counter station type -> the jobs that keep it
const NAMES := {"armory_counter": "the armoury"}

var w: World
var serving := {}            # counter station id -> the id of the villager coming to it or serving at it


func _init(world: World) -> void:
	w = world


func is_counter(id: String) -> bool:
	return w.stations.has(id) and KEEPERS.has(str(w.stations[id].type))


## Every counter in the village, in id order.
func all() -> Array:
	var out := []
	for t in KEEPERS:
		out += w.stations_of(t)
	out.sort()
	return out


func counter_name(id: String) -> String:
	return str(NAMES.get(str(w.stations[id].type), "the counter"))


## The villagers who keep counter `id`: its trade's jobs, those working in its building first, then the rest; by id.
func keepers(id: String) -> Array:
	var st: Dictionary = w.stations[id]
	var jobs: Array = KEEPERS[str(st.type)]
	var here := []
	var other := []
	for n: NPC in w.npcs:
		if not n.alive or not (n.job in jobs):
			continue
		var b := str(w.stations[n.workplace].get("building", "")) if w.stations.has(n.workplace) else n.workplace
		(here if b == str(st.get("building", "")) else other).append(n)
	return here + other


## Why `n` cannot come to a counter now ("" = they can).
func why_not(n: NPC) -> String:
	var h := w.hour()
	if not n.alive:
		return "is dead"
	if w.asleep(n):
		return "is asleep"
	if h < NPCBrain.WORK_START or h >= NPCBrain.WORK_END:
		return "keeps the counter from %d:00 to %d:00" % [int(NPCBrain.WORK_START), int(NPCBrain.WORK_END)]
	if n.target != -1:
		return "is fighting"
	if n.hunger < float(GameData.b("eat_below")):
		return "is off eating"
	if not w.construction.contract_of(n).is_empty():
		return "is hired out carrying for a building"
	return ""


## The villager serving or coming to counter `id`, or null.
func server(id: String) -> NPC:
	if not serving.has(id):
		return null
	var n: NPC = w.npc(int(serving[id]))
	if n == null or not n.alive or n.plan.is_empty() or not n.plan.any(func(s): return str(s.get("act", "")) == "serve_counter"):
		serving.erase(id)
		return null
	return n


## Whether `n` stands serving at a counter.
func serving_at(n: NPC) -> String:
	for id in serving:
		if int(serving[id]) == n.id and server(id) == n and n.pos.distance_to(Vector2(w.station_use(id)) + Vector2(0.5, 0.5)) <= 2.5:
			return id
	return ""


## The player rings at counter `id`: the first available keeper comes. {ok, npc, text}.
func summon(id: String) -> Dictionary:
	var name := counter_name(id)
	var s := server(id)
	if s != null:
		return {"ok": true, "npc": s, "text": "%s %s is %s." % [s.name, s.family, "here to serve" if serving_at(s) == id else "on the way to %s" % name]}
	var ks := keepers(id)
	if ks.is_empty():
		return {"ok": false, "npc": null, "text": "Nobody keeps %s now." % name}
	var pick: NPC = null
	var reasons := []
	for n: NPC in ks:
		var no := why_not(n)
		if no == "":
			pick = n
			break
		reasons.append("%s %s %s" % [n.name, n.family, no])
	if pick == null:
		return {"ok": false, "npc": null, "text": "Nobody can come to %s now: %s." % [name, "; ".join(reasons)]}
	for st in pick.plan:                     # work in hand is put down; a recipe takes its materials only when done
		if str(st.get("act", "")) == "craft":
			w.brain.release_station(pick, str(st.args.get("station", "")))
	var at := w.station_use(id)
	pick.plan = [w.brain.go(at), w.brain.work(float(GameData.b("counter_serve_minutes")), "serve_counter", {"counter": id}, "idle", w.brain._station_at(id))]
	pick.doing = "coming to %s" % name
	serving[id] = pick.id
	w.stat("counter_summons")
	return {"ok": true, "npc": pick, "text": "%s %s is coming to %s." % [pick.name, pick.family, name]}


## A serving keeper's time at the counter is up: they stay while the player is still at it, otherwise go back to work.
func served(n: NPC, id: String) -> bool:
	if w.player.pos.distance_to(Vector2(w.station_use(id)) + Vector2(0.5, 0.5)) <= 3.0 and why_not(n) == "":
		n.plan = [w.brain.work(float(GameData.b("counter_serve_minutes")), "serve_counter", {"counter": id}, "idle", w.brain._station_at(id))]
		n.work_left = float(n.plan[0].min)
		return true
	serving.erase(id)
	n.doing = ""
	return true
