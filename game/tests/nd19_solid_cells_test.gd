extends SceneTree
## ND-19: villagers stood on solid (wall) cells inside the village (sim gate, playtest probe: "on_solid_in_village"). Two causes:
##   (1) a walk laid its path before a cell on it turned solid (a farm fence or a stall put up meanwhile) and walked on through
##       it: World._walk now finds its way again when the next cell of its path has turned solid;
##   (2) a fencer stood beside the gate on the fence's own line and was left standing in the fence it put up: FarmPlots.fence_stand
##       puts the fencer beside the gate off the line (inside the plot or outside it).
## (1) is shown on one villager whose way is blocked mid-walk; both over the probe's own world (seed 1, three days, every minute):
## no villager steps into a village cell that was already solid, and no fencer stands in its own fence once it is up.
##   godot --headless --path game --script res://tests/nd19_solid_cells_test.gd
var checks := 0
var failures := 0


func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("ok   " if ok else "FAIL: ") + msg)
	if not ok:
		failures += 1


func _init() -> void:
	GameData.ensure()
	_blocked_walk()
	_probe_world()
	print("nd19_solid_cells_test: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


## (1) on one walk: three cells ahead on its path turn solid; it walks round them and arrives.
func _blocked_walk() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var n: NPC = null
	var to := Vector2i(-1, -1)
	var path := PackedVector2Array()
	for o: NPC in w.npcs:
		if not o.alive or o.depth != 0 or o.role != "adult" or not w.map.in_village(o.cell()) or w.map.is_solid(o.cell()):
			continue
		for d in [Vector2i(16, 0), Vector2i(-16, 0), Vector2i(0, 16), Vector2i(0, -16)]:
			var c: Vector2i = o.cell() + d
			if w.map.in_village(c) and not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == "" \
					and w.place_of(o.pos) == "":
				var pp := w.map.find_path(o.cell(), c)
				if pp.size() >= 14 and pp.size() <= 30:
					n = o
					to = c
					path = pp
					break
		if n != null:
			break
	check(n != null, "setup: a villager with an open walk of 14 to 30 cells")
	if n == null:
		w.dispose()
		return
	n.plan = [w.brain.go(to), w.brain.wait(n, 600.0)]
	n.work_left = 0.0
	w.update(0.5)
	check(n.path.size() > 6 and n.path_i < n.path.size() - 4, "setup: the walk has laid its path (%d cells, at %d)" % [n.path.size(), n.path_i])
	var blocked := []
	for k in range(n.path_i + 2, mini(n.path_i + 5, n.path.size() - 1)):
		var c := Vector2i(n.path[k].floor())
		blocked.append(c)
		w.map.set_solid(c, true)                 # a stall or a fence put up across the way after the path was laid
	var stepped := false
	var arrived := false
	for i in 240:
		w.update(0.5)
		if blocked.has(n.cell()):
			stepped = true
		if n.cell() == to:
			arrived = true
			break
	check(not stepped, "the villager does not walk into the cells that turned solid across its path (%s)" % str(blocked))
	check(arrived, "and still reaches where it was going (%s; at %s, doing %s)" % [str(to), str(n.cell()), n.doing])
	check(int(w.stats.get("walk_repath", 0)) >= 1, "the walk found its way again (walk_repath %d)" % int(w.stats.get("walk_repath", 0)))
	for c in blocked:
		w.map.set_solid(c, false)
	w.dispose()


## (1) and (2) over the probe's world: every minute for three days.
func _probe_world() -> void:
	var w := World.new()
	w.setup(VillageMap.load_default(), 1)
	var last := {}                 # npc id -> its cell at the last minute
	var was_solid := {}            # cell -> solid at the last minute (only cells villagers stood on or walked into)
	var into := []
	var fencers := []
	var fenced := 0
	for m in 3 * 24 * 60:
		var before := {}
		for n: NPC in w.npcs:
			if n.alive and n.depth == 0:
				var c := n.cell()
				before[n.id] = c
		w.update(0.5)
		w.player.hunger = 100.0
		for n: NPC in w.npcs:
			if not n.alive or n.depth != 0 or not before.has(n.id):
				continue
			var c := n.cell()
			if c == before[n.id] or not w.map.in_village(c) or not w.map.is_solid(c):
				continue
			if bool(was_solid.get(c, false)) and into.size() < 6:
				into.append("day %d %02d:%02d %s (%s) into %s" % [w.day(), w.hour(), int(w.minutes) % 60, n.name, n.doing, str(c)])
		for n: NPC in w.npcs:
			if n.alive and n.depth == 0 and n.doing == "fencing the family's farmland":
				for p in w.plots:
					if FarmPlots.is_farm(p) and bool(p.farm.get("fence", false)) and w.farm.fence_cells(w.farm_plots.rect_of(p)).has(n.cell()) \
							and w.map.is_solid(n.cell()) and fencers.size() < 6:
						fencers.append("day %d %02d:%02d %s at %s (%s)" % [w.day(), w.hour(), int(w.minutes) % 60, n.name, str(n.cell()), str(p.id)])
		# the cells every villager is beside, as they are now: the next minute's "already solid"
		was_solid.clear()
		for n: NPC in w.npcs:
			if n.alive and n.depth == 0:
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var c := n.cell() + Vector2i(dx, dy)
						if w.map.in_village(c):
							was_solid[c] = w.map.is_solid(c)
	for p in w.plots:
		if FarmPlots.is_farm(p) and bool(p.farm.get("fence", false)):
			fenced += 1
	check(fenced >= 2, "setup: villagers put up fences in the three days (%d fenced plots)" % fenced)
	check(into.is_empty(), "no villager walks into a village cell that was already solid (%s)" % "; ".join(into))
	check(fencers.is_empty(), "no fencer stands in its own fence once it is up (%s)" % "; ".join(fencers))
	w.dispose()
