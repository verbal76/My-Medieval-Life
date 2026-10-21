class_name Discovery
extends RefCounted
## MIN-D: finite deposit discovery and settlement mining capability (Mining spec stage 2, sections 3, 8, 9 and 11,
## phase D; docs/build17/MIN_D_DISCOVERY.md).
##
## Opening a find: a clue's body (Prospecting: an ore, a grade and the cell it lies under) is geology, never a deposit
## record, until someone digs a trial pit with a pickaxe on clear ground of the clue's search area within
## `trial.reach` cells of it. Then, and only then, it becomes an ordinary seam in World.deposits (owner OD-28: one
## deposit system everywhere) on the pit's cell, on the surface (OD-29: open workings stay on the surface): the same
## record, ore sprite, swing (World.work_mine), host rock (MIN-B), counting and save as the village's own seams. Its
## amount is the body's finite amount (the village map's per-seam amount for the ore x grade / 5, rounded up), counted
## `found_<ore>` (and `found_stone` for its host rock) so the ledger sees where it came from; it is never refilled. A
## trial pit costs `trial.minutes`, pickaxe wear and earns Mining xp, the same for the player and a villager (PAR-01);
## most may miss, a misleading stain never yields, and a clue takes at most `trial.per_clue` pits (WDR-022: a failed
## venture costs time and resources).
##
## Capability (SET-A schema, capabilities.json): the settlement's mining level 1-4 is recomputed every dawn from what
## the village really has (living practitioners and skills, tools held, deposits, stations, portals, structures, the
## manor's discovery records), never granted; it rises when the next level's needs hold and falls when one stops.
##
## Adoption (no player orders): at level 1 the labour market opens one prospector's place while unsampled ground is
## left and the manor could fund a survey (a villager takes it by the ordinary job rules, NPCBrain.seek_work). The
## manor commissions work through its ordinary job board (ManorWork, open to the player and every villager by the same
## rules, paid from the treasury for the labour whatever is found; owner MIN-C-Q1: the manor commissions, but is not the
## only employer): at level 1 one "survey" at a time (sample a clue it has heard nothing of, have the samples assayed,
## report at the manor), at level 2 one "trial" pit at a time for the best find it knows. A prospector may still
## prospect on its own and report as MIN-C built; a kit or ore is still ordered or sold by CON-01. No knowledge is sold
## and no rights are made (owner MIN-C-Q2). The rules are here; the UI and the villagers' plans only call them. Saved
## with the world ("discovery"); absent: nothing dug, levels recomputed.

const GEN_VERSION := 1
const INDUSTRY := "mining"
const SALT_DIG := 0x44494747

static var _cfg := {}
static var _caps := {}

var w: World
var dug := {}               # clue id -> [[x, y, who, day], ...]: trial pits dug round a stain (saved)
var levels := {}            # industry -> the level last computed (saved, for history; the truth is evaluate())
var history: Array = []     # {day, industry, from, to, why}: capability changes (saved)
var _open := PackedByteArray()   # the static layout's open ground (Prospecting._open_cells)


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/discovery.json"))
	return _cfg


static func caps() -> Dictionary:
	if _caps.is_empty():
		_caps = JSON.parse_string(FileAccess.get_file_as_string("res://data/capabilities.json"))
	return _caps


static func create(world: World) -> Discovery:
	var d := Discovery.new()
	d.w = world
	d._open = Prospecting._open_cells(world.map)
	d.levels[INDUSTRY] = int(d.evaluate(INDUSTRY).level)
	return d


static func ref_of(who) -> String:
	return Contracts.ref_of(who)


# ---------------------------------------------------------------- bodies and finds -----------
## The finite amount of ore a body holds: the village map's own per-seam amount for its ore (village.json deposits,
## the first seam of that ore) x grade / 5, rounded up, at least 1. No seam is bigger than the village's own.
func body_amount(ore: String, grade: int) -> int:
	var base := 0
	for d in w.map.data.deposits:
		if str(d.ore) == ore:
			base = int(d.amount)
			break
	return maxi(1, ceili(float(base) * float(clampi(grade, 1, 5)) / 5.0))


## The seam opened from clue `id` ({} while none): a deposit record carrying `found`.
func opened(id: String) -> Dictionary:
	for d in w.deposits:
		if str(d.get("found", "")) == id:
			return d
	return {}


func trials_left(c: Dictionary) -> int:
	return int(cfg().trial.per_clue) - (dug.get(str(c.id), []) as Array).size()


func dug_at(c: Dictionary, cell: Vector2i) -> bool:
	for t in dug.get(str(c.id), []):
		if int(t[0]) == cell.x and int(t[1]) == cell.y:
			return true
	return false


## What the manor knows of ore: its findings (Prospecting.findings) that found some.
func manor_finds() -> Array:
	return w.prospecting.findings(World.MANOR).filter(func(f): return str(f.ore) != "")


# ---------------------------------------------------------------- the trial pit --------------
func _static_open(c: Vector2i) -> bool:
	var m := w.map
	return c.x >= 0 and c.y >= 0 and c.x < m.w and c.y < m.h and _open[c.y * m.w + c.x] == 1


## Why a trial pit cannot be dug on `cell` of clue `c` whoever digs ("" if it can): inside the area, on ground that
## was open in the village's layout with open ground on its four sides (so a seam opened there blocks no road, door
## or yard), clear now (nothing planted, built, farmed or standing there), not dug before, the clue not yet opened and
## with pits left.
func ground_refusal(c: Dictionary, cell: Vector2i) -> String:
	var pr: Prospecting = w.prospecting
	if c.is_empty() or not pr.in_area(c, cell) or not w.map.in_village(cell):
		return "There is no sign of ore here to dig for."
	if not opened(str(c.id)).is_empty():
		return "A seam has already been opened by this stain."
	if trials_left(c) <= 0:
		return "Enough trial pits have been dug round this stain: there is nothing more to find here."
	if dug_at(c, cell):
		return "A trial pit has been dug here already."
	if not _static_open(cell):
		return "The ground here is not clear enough to dig."
	for dv in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not _static_open(cell + dv) or w.map.is_solid(cell + dv):
			return "The ground here is not clear enough to dig."
	var why := w.plant_refusal(cell)
	if why != "":
		return why
	if not w.farm_plots.plot_at(cell).is_empty() or not w.farm.parcel_at(cell).is_empty():
		return "That is farmland."
	if Vector2i(w.player.pos.floor()) == cell and w.player_level == 0:
		return "Someone is standing there."
	for n: NPC in w.npcs:
		if n.alive and n.depth == 0 and n.cell() == cell:
			return "Someone is standing there."
	return ""


## Why `who` cannot dig a trial pit on `cell` of clue `c` with `tool` now ("" if they can).
func trial_refusal(who, c: Dictionary, cell: Vector2i, tool := "pickaxe") -> String:
	if tool == "" or not who.inv.has(tool):
		return "You need a pickaxe to dig a trial pit."
	return ground_refusal(c, cell)


## `who` (the player or a villager) digs a trial pit on `cell` of clue `c`, by one rule (PAR-01): the pit is recorded,
## the pickaxe wears (`trial.wear`, Mining's tool_wear_save may spare it) and the work earns `trial.xp` Mining xp. If
## the clue's body lies within `trial.reach` cells (Chebyshev) of the pit, the body is opened there as a seam.
## Returns {result: "ok" | "refused", why, found (the seam opened, or {}), broke, up}.
func trial_dig(who, c: Dictionary, cell: Vector2i, tool := "pickaxe") -> Dictionary:
	var why := trial_refusal(who, c, cell, tool)
	if why != "":
		return {"result": "refused", "why": why}
	var tc: Dictionary = cfg().trial
	var ref := ref_of(who)
	var t: Array = dug.get(str(c.id), [])
	t.append([cell.x, cell.y, ref, w.day()])
	dug[str(c.id)] = t
	w.stat("trial_pits")
	var broke := w._work_wear(who, tool, int(tc.wear), "mining", "tool_wear_save")
	if broke and who is PlayerState and who.tool == tool:
		who.tool = ""
	var up := Skills.gain(who, "mining", int(tc.xp))
	var body: Dictionary = c.get("body", {})
	var found := {}
	if not body.is_empty() and maxi(absi(int(body.x) - cell.x), absi(int(body.y) - cell.y)) <= int(tc.reach):
		found = _open_seam(c, cell, ref)
	else:
		w.stat("trial_misses")
	return {"result": "ok", "why": "", "found": found, "broke": broke, "up": up}


## The body of clue `c` is opened on `cell`: an ordinary seam record (with its MIN-B host rock), solid like every seam,
## drawn with its ore's sprite. Counted found_<ore> and found_stone (the ledger: a finite pool entering the books).
func _open_seam(c: Dictionary, cell: Vector2i, ref: String) -> Dictionary:
	var body: Dictionary = c.body
	var ore := str(body.ore)
	var d := {"x": cell.x, "y": cell.y, "ore": ore, "amount": body_amount(ore, int(body.grade)), "found": str(c.id), "found_by": ref, "found_day": w.day()}
	w.deposits.append(d)
	w._add_host_rock()                        # MIN-B: the grey rock round the ore, as every ore seam has
	w.stat("found_" + ore, float(d.amount))
	if d.has("host"):
		w.stat("found_stone", float(d.host.amount))
	w.stat("seams_found")
	w.map.set_solid(cell, true)
	w.tile_changed.emit(cell, "below", int(w.map.data.tiles.ore.get(ore, w.map.data.tiles.ore.stone)))
	w.note("A trial pit by %s %s strikes %s: a new seam is opened." % [w.prospecting.stain(c), w.prospecting.place(c), GameData.item_name(ore).to_lower()])
	return d


## The cells a party would dig for clue `c`, best first: clear cells (ground_refusal), nearest the mean of the cells
## where the samples it knows of found the ore (else the stain), ties in the clue's hashed spot order.
func dig_cells(c: Dictionary, ref: String) -> Array:
	var sum := Vector2.ZERO
	var k := 0
	for r in w.prospecting.records:
		if str(r.clue) == str(c.id) and str(r.ore) != "" and w.prospecting.knows(ref, r):
			sum += Vector2(int(r.x), int(r.y))
			k += 1
	var aim := sum / float(k) if k > 0 else Vector2(int(c.x), int(c.y))
	var ranked := []
	var spots: Array = c.spots
	for i in spots.size():
		var cell: Vector2i = spots[i]
		if ground_refusal(c, cell) == "":
			ranked.append([Vector2(cell).distance_squared_to(aim), i, cell])
	ranked.sort()
	return ranked.map(func(r): return r[2])


## The next cell the manor would have dug for clue `c`, or (-1, -1).
func next_cell(c: Dictionary, ref := World.MANOR) -> Vector2i:
	var cells := dig_cells(c, ref)
	return cells[0] if not cells.is_empty() else Vector2i(-1, -1)


## The find the manor would dig for now: {clue, cell} for the most certain clue it knows traces at (at least
## `manor.min_confidence`), not yet opened, with pits left and clear ground; {} below `manor.trial_level` or with none.
func trial_target() -> Dictionary:
	var mc: Dictionary = cfg().manor
	if level() < int(mc.trial_level):
		return {}
	var finds := manor_finds()
	finds.sort_custom(func(a, b): return float(a.confidence) > float(b.confidence) or (float(a.confidence) == float(b.confidence) and str(a.clue) < str(b.clue)))
	for f in finds:
		if float(f.confidence) < float(mc.min_confidence):
			continue
		var c: Dictionary = w.prospecting.clue(str(f.clue))
		if c.is_empty() or not opened(str(c.id)).is_empty() or trials_left(c) <= 0:
			continue
		var cell := next_cell(c)
		if cell.x >= 0:
			return {"clue": c, "cell": cell}
	return {}


## How long the player's trial pit takes (seconds), timed as their mining swing is.
static func player_secs() -> float:
	return float(cfg().trial.minutes) / float(GameData.b("game_minutes_per_second")) * 0.6


# ---------------------------------------------------------------- commissioned surveys -------
## Whether the treasury can set a survey's wage aside (the manor's jobs' rule, ManorWork.can_fund).
func can_fund_survey() -> bool:
	return w.treasury - int(cfg().manor.survey_wage) >= w.brain.daily_obligations() * float(GameData.b("manor_job_reserve_days"))


## The clue the manor would commission a survey of: the first (generation order) it has heard nothing of, with at
## least `manor.survey_samples` samples left, not opened; {} below `manor.survey_level` or with none.
func survey_target() -> Dictionary:
	var mc: Dictionary = cfg().manor
	if level() < int(mc.survey_level):
		return {}
	var pr: Prospecting = w.prospecting
	for c in pr.clues:
		if pr.samples_left(c) < int(mc.survey_samples) or not opened(str(c.id)).is_empty():
			continue
		if pr.records.any(func(r): return str(r.clue) == str(c.id) and pr.knows(World.MANOR, r)):
			continue
		return c
	return {}


# ---------------------------------------------------------------- capability -----------------
## The settlement's level in `industry` now: {level, holds: [bool per level], unmet: {level: [need kinds]}}. Derived
## from the world alone (no rng, nothing changed).
func evaluate(industry := INDUSTRY) -> Dictionary:
	var ls: Array = caps().industries[industry].levels
	var holds := []
	var unmet := {}
	var lv := 0
	var climbing := true
	for l in ls:
		var miss := []
		for need in l.needs:
			if not need_holds(need):
				miss.append(need_name(need))
		holds.append(miss.is_empty())
		if not miss.is_empty():
			unmet[int(l.level)] = miss
		if climbing and miss.is_empty():
			lv = int(l.level)
		else:
			climbing = false
	return {"level": lv, "holds": holds, "unmet": unmet}


## The level last computed (a dawn, or the world's start or load).
func level(industry := INDUSTRY) -> int:
	return int(levels.get(industry, 0))


func level_name(lv: int, industry := INDUSTRY) -> String:
	for l in caps().industries[industry].levels:
		if int(l.level) == lv:
			return str(l.name)
	return "none"


## A need in a word or two for the history and the journal: "a pickaxe", "a prospector", "an assayer", "a discovery".
static func need_name(need: Dictionary) -> String:
	if need.has("as"):
		return "an " + str(need.as) if str(need.as).substr(0, 1) in ["a", "e", "i", "o", "u"] else "a " + str(need.as)
	match str(need.kind):
		"deposit_access":
			return "ore to reach"
		"practitioners":
			var jobs: Array = need.get("jobs", [])
			return "%d %s" % [int(need.get("count", 1)), "/".join(jobs) if not jobs.is_empty() else "worker"] + ("s" if int(need.get("count", 1)) > 1 else "") \
					+ ((" with %s %d" % [str(need.skill), int(need.get("min_level", 1))]) if need.has("skill") else "")
		"tool_stock":
			return GameData.item_name(str(need.tool)).to_lower()
		"transport":
			return "transport"
		"station":
			return "a " + str(need.type)
		"records":
			return "a recorded discovery"
		"portal":
			return "a way below ground"
		"structure":
			return str(need.what).replace("_", " ")
	return str(need.kind)


## Whether one need holds in the world now.
func need_holds(need: Dictionary) -> bool:
	match str(need.kind):
		"deposit_access":
			var lv := int(need.get("level", 0))
			for d in w._quarry_sources(["iron_ore", "coal", "copper_ore", "gold_ore", "stone"]):
				if int(d.amount) > 0 and World.level_of(d) == lv and w.villagers_reach(d):
					return true
			return false
		"practitioners":
			return practitioners(need).size() >= int(need.get("count", 1))
		"tool_stock":
			return tool_stock(str(need.tool)) >= int(need.get("count", 1))
		"transport":
			for k in need.get("any", []):
				if str(k) == "handcart" and (not w.carts.carts.is_empty() or tool_stock("handcart") > 0):
					return true
				if str(k) == "carry" and int(GameData.b("carry_ore")) > 0 and w.npcs.any(func(o): return o.alive and o.role == "adult"):
					return true          # the village's miners carry ore in their packs, as they do today
			return false
		"station":
			return w.stations_of(str(need.type)).size() >= int(need.get("count", 1))
		"records":
			return manor_finds().size() >= int(need.get("count", 1))
		"portal":
			if w.underground == null:
				return false
			for p in w.underground.portals:
				for e in p.ends:
					if int(e.level) <= int(need.get("min_depth", -1)):
						return true
			return false
		"structure":
			return structures(str(need.what)) >= int(need.get("count", 1))
	return false


## The living adult villagers who meet a practitioners need (its jobs, if named; its skill level, if named).
func practitioners(need: Dictionary) -> Array:
	var jobs: Array = need.get("jobs", [])
	return w.npcs.filter(func(o: NPC) -> bool:
		return o.alive and o.role == "adult" and (jobs.is_empty() or jobs.has(o.job)) \
				and (not need.has("skill") or Skills.level(o, str(need.skill)) >= int(need.get("min_level", 1))))


## How many of `tool` the settlement holds: living villagers' packs, the households' stores and the manor's works yard
## (the player's own goods are theirs, not the settlement's).
func tool_stock(tool: String) -> int:
	var n := 0
	for o: NPC in w.npcs:
		if o.alive:
			n += o.inv.count(tool)
	for hh in w.households:
		n += (hh.pantry as Inventory).count(tool)
	n += w.manor_work.yard.count(tool)
	return n


## Built mining structures of a kind: pit ramps (MIN-E) and timber supports (MIN-F) are not built yet, so none.
func structures(_what: String) -> int:
	return 0


## Dawn: the levels are recomputed from the world; a change is noted and kept in the history with what is missing.
func dawn() -> void:
	for industry in caps().industries:
		var e := evaluate(industry)
		var was := level(industry)
		var now := int(e.level)
		if now == was:
			continue
		levels[industry] = now
		var why := ""
		if now < was:
			why = ", ".join(e.unmet.get(now + 1, []))
			w.note("The village's %s falls to level %d (%s): it has lost %s." % [industry, now, level_name(now, industry).to_lower(), why])
		else:
			w.note("The village's %s rises to level %d: %s." % [industry, now, level_name(now, industry).to_lower()])
		history.append({"day": w.day(), "industry": industry, "from": was, "to": now, "why": why})
		w.stat("capability_%s_changes" % industry)


# ---------------------------------------------------------------- adoption -------------------
## The prospector's place in the labour market (NPCBrain.job_market): open while the village's mining is at least
## `manor.prospector_level`, nobody prospects, some clue has ground left to sample and the manor could fund a survey
## (the paid work a prospector can count on; it may also prospect on its own, as MIN-C built). Its pay is what
## prospectors have earned, or before any has, a survey's wage over `manor.pay_estimate_days`.
func prospector_place(avg_pay: float) -> Dictionary:
	var mc: Dictionary = cfg().manor
	var open := 0
	if level() >= int(mc.prospector_level) and not w.npcs.any(func(o): return o.alive and o.job == Prospecting.JOB) \
			and w.prospecting.clues.any(func(c): return w.prospecting.samples_left(c) > 0) and can_fund_survey():
		open = 1
	var pay := avg_pay if avg_pay > 0.0 else float(mc.survey_wage) / maxf(1.0, float(mc.pay_estimate_days))
	return {"pay": pay, "open": open, "tool": "", "at": Vector2i(w.map.data.mine.yard[0], w.map.data.mine.yard[1])}


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	return {"gen": GEN_VERSION, "dug": dug.duplicate(true), "levels": levels.duplicate(), "history": history.duplicate(true)}


## A save without discovery (Build 16, or Build 17 before MIN-D) loads with nothing dug and the levels computed from
## the world as it stands, with no history. Seams opened are in the save's deposits (with `found`): their cells are
## solid again unless quarried away. Pits round a clue the generator no longer makes are dropped with it.
func load_dict(d: Dictionary) -> void:
	dug = {}
	for id in d.get("dug", {}):
		if w.prospecting.clue(str(id)).is_empty():
			continue
		dug[str(id)] = (d.dug[id] as Array).map(func(t): return [int(t[0]), int(t[1]), str(t[2]), int(t[3])])
	history = []
	for h in d.get("history", []):
		history.append({"day": int(h.day), "industry": str(h.industry), "from": int(h.from), "to": int(h.to), "why": str(h.get("why", ""))})
	levels = {}
	for k in d.get("levels", {}):
		levels[str(k)] = int(d.levels[k])
	for industry in caps().industries:
		if not levels.has(industry):
			levels[industry] = int(evaluate(industry).level)
	for sd in w.deposits:
		if sd.has("found") and World.level_of(sd) == 0 and (int(sd.amount) > 0 or (sd.has("host") and int(sd.host.amount) > 0)):
			w.map.set_solid(Vector2i(int(sd.x), int(sd.y)), true)
