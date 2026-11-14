extends SceneTree
## B42-NAV (Build 42, Agent L): villagers stranded outside the village, and the back-off bypass (MML-NPC-01). Chain 12 flight
## campaign (runs 43332151718 and 43332156022, b3c9eb5; code unchanged on 0bbee94): 24 of the 47 starvation deaths not on an
## envoy's journey were villagers standing "lost" outside the village with food at home. Each had walked out (a chapel parcel
## carried to the outlaws' camp or a homestead household, chapel._dest: a household with no house in the village is found where a
## member stands; or a companion followed, "spending time with ..."), and every walk back failed with no path: the world's path
## search (VillageMap.find_path_world) refuses a box of more than WORLD_PATH_CELLS = 140 cells round its ends, and a box that fits
## can still cut off the only way round. Separately (flight finding F009), a plan whose first walk was found cleared the failed-walk
## count before its next walk failed, so the back-off never began: seed 2's preacher made the same chapel delivery plan to the
## camp every game minute, 200 to 554 times a day. Checked:
##  1. a villager set down where the campaign's victims starved (their seed and cell) and sent home to eat walks home and eats,
##     never standing lost (the cells' direct search fails: the fixture shows the defect's geometry);
##  2. a chapel parcel carried to the outlaws' camp from the south of the village (a walk out the bounded search allows): the
##     carrier delivers it and is back in the village within the day (B42-NAV routes only walks into the village; a walk out
##     beyond the search is refused as before);
##  3. a chapel delivery to a household out of every reach (its member far beyond any road): the carrier's plans are bounded by
##     the back-off (World._walk_failed), not made every game minute;
##  4. a walk that is found and arrives still clears the count (a normal plan is untouched).
##   godot --headless --path game -s res://tests/b42_nav_stranding_test.gd

var checks := 0
var failures := 0


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("ok   " if ok else "FAIL ") + what)


func minutes_step(w: World) -> int:
	return int(1.0 / float(GameData.b("game_minutes_per_second")) / 0.5)


func run_hours(w: World, hours: float, each := Callable()) -> void:
	var per := maxi(1, minutes_step(w))
	for m in int(60.0 * hours):
		for i in per:
			w.update(0.5)
		if each.is_valid() and bool(each.call()):
			return


func world(seed: int) -> World:
	var w := World.new()
	w.setup(VillageMap.load_default(), seed)
	run_hours(w, 24.0 + 8.0)                 # 8 in the morning of day 2
	return w


func open_near(w: World, c: Vector2i) -> Vector2i:
	for r in range(0, 8):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := c + Vector2i(dx, dy)
				if not w.map.is_solid_world(q) and (w.map.overworld == null or w.map.overworld.site_at(q).is_empty()):
					return q
	return c


## An adult (not a guard, not clergy, not on a journey or a claim) living in a house of the village.
func housed_adult(w: World, skip := []) -> NPC:
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 3 and n.depth == 0 and n.journey.is_empty() and n.target == -1 and n.job != "guard" \
				and not Chapel.is_clergy(n) and w.buildings.has(n.home) and not skip.has(n.id) and not w.homesteads.drives(n) \
				and not w.life.drives(n):
			return n
	return null


## The housed adult (housed_adult's kind) whose home meal is farthest from `at` by the path search's box (the larger side), as the
## campaign's victims' homes were (their homes' doors 129 to 176 cells across the box from where they stood).
func farthest_housed(w: World, at: Vector2i, skip: Array) -> NPC:
	var best: NPC = null
	var bd := -1
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and n.household >= 3 and n.depth == 0 and n.journey.is_empty() and n.target == -1 and n.job != "guard" \
				and not Chapel.is_clergy(n) and w.buildings.has(n.home) and not skip.has(n.id) and not w.homesteads.drives(n) \
				and not w.life.drives(n):
			var t := w.home_cell(n, "table")
			var d := maxi(absi(t.x - at.x), absi(t.y - at.y))
			if d > bd:
				bd = d
				best = n
	return best


## 1. Set down at `cell` (seed's world), hungry, food in the pantry, sent home to eat (NPCBrain._home_meal, the victims' plan).
func strand_case(w: World, seed: int, cell: Vector2i, used: Array) -> void:
	var at := open_near(w, cell)
	var n := farthest_housed(w, at, used)
	if n == null:
		check(false, "seed %d: an adult with a house" % seed)
		return
	used.append(n.id)
	var direct := w.map.find_path_world(at, w.home_cell(n, "table"))
	n.pos = Vector2(at) + Vector2(0.5, 0.5)
	n.path = PackedVector2Array()
	n.hunger = 30.0
	(w.households[n.household].pantry as Inventory).add("bread", 4)
	n.doing = "going home to eat"
	n.plan = w.brain._home_meal(n)
	var target: Vector2i = n.plan[0].to
	check(World.short_of(direct, target), "seed %d fixture: from %s the bounded direct search finds no way to the home meal at %s, or one that stops short (the defect's geometry)" % [seed, at, target])
	var fails := [0]
	var ate := [false]
	var at_meal := [Vector2i.ZERO]
	var h0 := n.hunger
	run_hours(w, 10.0, func() -> bool:
		fails[0] = maxi(fails[0], n.path_fails)
		if n.doing == "lost":
			fails[0] = maxi(fails[0], 1)
		if n.hunger > h0 + 20.0:
			ate[0] = true
			at_meal[0] = n.cell()
			return true
		return false)
	var home := absi(at_meal[0].x - target.x) + absi(at_meal[0].y - target.y) <= 3
	print("  seed %d: villager %d (household %d) from %s (direct search %s, box %dx%d) to %s: ate %s at %s, failed walks seen %d" % [seed, n.id, n.household, at,
		("short, ending %s" % Vector2i(direct[direct.size() - 1]) if World.short_of(direct, target) else "found") if not direct.is_empty() else "none", absi(at.x - target.x) + 21, absi(at.y - target.y) + 21, target, ate[0], at_meal[0], fails[0]])
	check(ate[0] and home and fails[0] == 0, "seed %d: set down at %s (where a campaign villager starved), sent home to eat: walks home and eats there, no failed walk" % [seed, at])


func test_strandings() -> void:
	# [seed, cells]: the chain 12 victims' last cells (Agent I's traces, the archive's samples)
	var cases := [[1, [Vector2i(162, 122), Vector2i(140, 98)]], [2, [Vector2i(3, 160), Vector2i(6, 161), Vector2i(30, 176), Vector2i(-40, 149)]],
		[4, [Vector2i(23, 142), Vector2i(20, 148)]]]
	for cs in cases:
		var w := world(int(cs[0]))
		var used := []
		for c: Vector2i in cs[1]:
			strand_case(w, int(cs[0]), c, used)


## 2. A chapel parcel for the outlaws' household, carried from the chapel's door to the camp (chapel._dest: where a member stands).
func test_camp_round_trip() -> void:
	var w := world(2)
	var c: Chapel = w.chapel
	var band: int = w.wilds.band_household() if w.wilds != null else -1
	if c == null or not c.present or band < 0 or w.brain._members(band).is_empty():
		check(false, "seed 2 fixture: a chapel and the outlaw band")
		return
	var carrier: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and Chapel.is_clergy(n) and w.farm_plots.able(n):
			carrier = n
			break
	if carrier == null:
		check(false, "seed 2 fixture: a clergy member")
		return
	c.parcels.clear()
	c.store.add("wheat", 6)
	# the parcel lies in the south of the village, set down there by an earlier carrier (chapel.release_stale), so the walk out
	# to the camp fits the bounded search, as the campaign's did (seed 2 p:1000017: from (84,39) to (1,148), a box of 104x131);
	# the walk home to a house in the north of the village then does not (B42-NAV routes it in by a gate or a road)
	var lie := open_near(w, Vector2i(40, 86))
	var p := c._parcel(band, lie, true, "relief")
	w.transfer(c.store, p.inv, "wheat", 6)
	carrier.pos = Vector2(lie) + Vector2(0.5, 0.5)
	carrier.hunger = 100.0
	check(c.plan_deliver(carrier), "seed 2: the clergy member takes up the parcel for the outlaws")
	var dest: Vector2i = carrier.plan[2].to
	var pid := int(p.id)
	var d0 := float(w.stats.get("chapel_deliveries", 0))
	var delivered := [false]
	var lost := [0]
	run_hours(w, 12.0, func() -> bool:
		if carrier.doing == "lost":
			lost[0] += 1
		if c.parcel(pid).is_empty() or not carrier.plan.any(func(s) -> bool: return str(s.get("act", "")) == "church_deliver"):
			delivered[0] = float(w.stats.get("chapel_deliveries", 0)) > d0
			return true
		return false)
	var drop := carrier.cell()
	delivered[0] = delivered[0] and absi(drop.x - dest.x) + absi(drop.y - dest.y) <= 3
	print("  seed 2: carrier %d from %s to the camp %s (box %dx%d): delivered %s at %s, lost %d minutes" % [carrier.id, lie, dest,
		absi(dest.x - lie.x) + 21, absi(dest.y - lie.y) + 21, delivered[0], drop, lost[0]])
	check(delivered[0], "seed 2: the carrier walks to the outlaws' camp and puts the parcel in their pantry there")
	var home := w.home_cell(carrier, "door")
	print("  seed 2: from %s the carrier's home door %s is %dx%d by the search's box: direct search %s" % [drop, home, absi(home.x - drop.x) + 21,
		absi(home.y - drop.y) + 21, "none or short" if World.short_of(w.map.find_path_world(drop, home), home) else "found"])
	var back := [false]
	var lost2 := [0]
	run_hours(w, 14.0, func() -> bool:
		if carrier.doing == "lost":
			lost2[0] += 1
		if w.map.in_village(carrier.cell()):
			back[0] = true
			return true
		return false)
	print("  seed 2: carrier %d after the delivery: now at %s, lost %d minutes, failed walks %d" % [carrier.id, carrier.cell(), lost2[0], carrier.path_fails])
	check(back[0] and carrier.alive, "seed 2: the carrier walks back into the village after delivering at the camp (from %s)" % drop)


## 3. A delivery to a household out of every reach: the first walk (to the parcel at the chapel's door) is found, the second is not.
func test_backoff_two_walk_plan() -> void:
	var w := world(1)
	var c: Chapel = w.chapel
	var carrier: NPC = null
	for n: NPC in w.npcs:
		if n.alive and n.role == "adult" and Chapel.is_clergy(n) and w.farm_plots.able(n):
			carrier = n
			break
	var hh := -1
	var member: NPC = null
	for h in range(3, w.households.size()):
		var ms: Array = w.brain._members(h)
		if carrier != null and h != carrier.household and not w.households[h].get("band", false) and not ms.is_empty() and ms[0].role == "adult":
			hh = h
			member = ms[0]
			break
	if c == null or not c.present or carrier == null or member == null:
		check(false, "seed 1 fixture: a chapel, a clergy member and another household")
		return
	# the household loses its house (between homes: chapel._dest finds it where its first member stands), and that member stands far
	# beyond the village and any road (pinned there each minute: not simulated as a walker)
	var away := open_near(w, Vector2i(w.map.w + 900, w.map.h + 900))
	w.households[hh].home = ""
	c.parcels.clear()
	c.store.add("wheat", 4)
	var p := c._parcel(hh, c.door_cell(), true, "relief")
	w.transfer(c.store, p.inv, "wheat", 4)
	carrier.pos = Vector2(c.door_cell()) + Vector2(1.5, 0.5)
	carrier.plan.clear()
	carrier.hunger = 100.0
	var pin := func() -> void:
		member.pos = Vector2(away) + Vector2(0.5, 0.5)
		member.plan = [w.brain.wait(member, 600.0)]
		carrier.hunger = 100.0
	pin.call()
	var trips0 := int(w.stats.get("chapel_carry_trips", 0))
	var dec0 := int(w.brain.decide_calls.get(carrier.id, 0))
	var lost := [0]
	run_hours(w, 6.0, func() -> bool:
		pin.call()
		if carrier.doing == "lost":
			lost[0] += 1
		return false)
	var trips := int(w.stats.get("chapel_carry_trips", 0)) - trips0
	var decides := int(w.brain.decide_calls.get(carrier.id, 0)) - dec0
	print("  seed 1: carrier %d, parcel for household %d (member at %s): %d carrying plans, %d decisions, %d lost minutes, failed walks %d in six game hours" % [
		carrier.id, hh, away, trips, decides, lost[0], carrier.path_fails])
	check(trips >= 2, "the carrier tries the delivery (%d plans)" % trips)
	check(trips <= 40 and decides <= 15, "the unreachable delivery is planned a bounded number of times in six game hours, not once a minute (%d plans, %d decisions)" % [trips, decides])
	check(carrier.path_fails >= 2, "the failed walks are counted across the plans despite each plan's first walk being found (%d)" % carrier.path_fails)


## 4. A plan of two walks, both found: the count from an earlier failure is cleared when the plan's last walk is found.
func test_found_clears() -> void:
	var w := world(1)
	var n := housed_adult(w)
	n.path_fails = 3
	n.path_fail_at = w.minutes
	var a := n.cell()
	var door := w.building_door(n.home)
	n.plan = [w.brain.go(w.brain.wander_cell(a, 3)), w.brain.go(door), w.brain.wait(n, 30.0)]
	n.doing = "testing"
	run_hours(w, 1.0 / 60.0)
	check(n.path_fails == 3, "a plan's first walk found leaves an earlier run of failures counted (%d)" % n.path_fails)
	run_hours(w, 2.0, func() -> bool: return n.plan.size() <= 1)
	check(n.path_fails == 0, "the plan's last walk found clears it (%d)" % n.path_fails)


func _init() -> void:
	GameData.ensure()
	test_found_clears()
	test_backoff_two_walk_plan()
	test_strandings()
	test_camp_round_trip()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
