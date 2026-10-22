class_name Discovery
extends RefCounted
## MIN-D: finite deposit discovery and settlement mining capability (Mining spec stage 2, sections 3, 8, 9 and 11,
## phase D; docs/build17/MIN_D_DISCOVERY.md).
##
## Opening a find: a clue's body (Prospecting: an ore, a grade and the cell it lies under) is geology, never a deposit
## record, until someone digs a trial pit with a shovel (owner MIN-E-Q4) on clear ground of the clue's search area within
## `trial.reach` cells of it. Then, and only then, it becomes an ordinary seam in World.deposits (owner OD-28: one
## deposit system everywhere) on the pit's cell, on the surface (OD-29: open workings stay on the surface): the same
## record, ore sprite, swing (World.work_mine), host rock (MIN-B), counting and save as the village's own seams. Its
## amount is the body's finite amount (the village map's per-seam amount for the ore x grade / 5, rounded up), counted
## `found_<ore>` (and `found_stone` for its host rock) so the ledger sees where it came from; it is never refilled. A
## trial pit costs `trial.minutes`, shovel wear and earns Mining xp, the same for the player and a villager (PAR-01);
## its earth (one cell's topsoil, dirt and spoil down to the rock) is left in a spoil pile beside it (MIN-D-Q3);
## most may miss, a misleading stain never yields, and a clue takes at most `trial.per_clue` pits (WDR-022: a failed
## venture costs time and resources).
##
## Capability (SET-A schema, capabilities.json): the settlement's mining level 1-4 is recomputed every dawn from what
## the village really has (its residents' skills and the tools they can use, tools held, deposits, stations, portals,
## structures, the manor's discovery records), never granted; it rises when the next level's needs hold and falls when
## one stops. Residents are the living adult villagers and the player while the family has a home here, by one rule
## (owner MIN-D-Q2); practitioners are counted by skill and equipment, not job titles (owner MIN-E-Q6).
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
var _wild := PackedByteArray()   # that ground less the settlement's footprint (Prospecting.wild_cells, ORE-PLACE-01)


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
	d._wild = Prospecting.wild_cells(world.map)
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
## was open in the village's layout and outside the settlement's footprint (ORE-PLACE-01) with open ground on its four sides (so a seam opened there blocks no road, door
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
	if _wild[cell.y * w.map.w + cell.x] == 0:     # ORE-PLACE-01: no trial pit inside the settlement's footprint
		return "That ground belongs to the village: no ore is sought there."
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


## Why `who` cannot dig a trial pit on `cell` of clue `c` with `tool` now ("" if they can): a tool of the trial's kind
## (`trial.tool`: a shovel, owner MIN-E-Q4: a trial pit moves earth down to the rock face, and earth is dug with a shovel).
func trial_refusal(who, c: Dictionary, cell: Vector2i, tool := "shovel") -> String:
	var kind := str(cfg().trial.get("tool", "shovel"))
	if tool == "" or not who.inv.has(tool) or str(GameData.item(tool).get("tool", "")) != kind:
		return "You need a %s to dig a trial pit." % OpenPits.tool_word(kind)
	return ground_refusal(c, cell)


## The earth a trial pit moves (MIN-D-Q3): one cell of the open pit's layers down to the rock (OpenPits.earth_column:
## 2 topsoil, 3 dirt, 3 spoil), {item: units}.
static func trial_earth() -> Dictionary:
	var out := {}
	for e in OpenPits.earth_column():
		out[str(e[0])] = int(out.get(str(e[0]), 0)) + int(e[1])
	return out


## Where a trial pit's earth is left: the cell south of the pit (its four sides are open ground, ground_refusal).
static func pile_cell(cell: Vector2i) -> Vector2i:
	return cell + Vector2i.DOWN


## `who` (the player or a villager) digs a trial pit on `cell` of clue `c`, by one rule (PAR-01): the pit is recorded,
## the shovel wears (`trial.wear`, Mining's tool_wear_save may spare it) and the work earns `trial.xp` Mining xp. The
## earth it moves (trial_earth) leaves the ground (counted trial_ground_<item>, the pool entering the books, and
## dug_<item>, the goods made) and lies in a spoil pile beside the pit (a loot pile on pile_cell, from `trial.pile_from`):
## physical, counted by the goods census, taken up by anyone and carried, tipped or put back into a pit like any earth
## (owner MIN-D-Q3). If the clue's body lies within `trial.reach` cells (Chebyshev) of the pit, the body is opened there
## as a seam. Returns {result: "ok" | "refused", why, found (the seam opened, or {}), broke, up, earth: {item: units}}.
func trial_dig(who, c: Dictionary, cell: Vector2i, tool := "shovel") -> Dictionary:
	var why := trial_refusal(who, c, cell, tool)
	if why != "":
		return {"result": "refused", "why": why}
	var tc: Dictionary = cfg().trial
	var ref := ref_of(who)
	var t: Array = dug.get(str(c.id), [])
	t.append([cell.x, cell.y, ref, w.day()])
	dug[str(c.id)] = t
	w.stat("trial_pits")
	var earth := trial_earth()
	var pile := Inventory.new()
	for id in earth:
		w.stat("trial_ground_" + str(id), float(earth[id]))
		w._work_goods(who, pile, str(id), int(earth[id]), "dug_")
	w.loot.append({"pos": Vector2(pile_cell(cell)) + Vector2(0.5, 0.5), "inv": pile, "coins": 0, "from": str(tc.get("pile_from", "a trial pit"))})
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
	return {"result": "ok", "why": "", "found": found, "broke": broke, "up": up, "earth": earth}


## The body of clue `c` is opened on `cell`: an ordinary seam record (with its MIN-B host rock), solid like every seam,
## drawn with its ore's sprite. Counted found_<ore> and found_stone (the ledger: a finite pool entering the books).
func _open_seam(c: Dictionary, cell: Vector2i, ref: String) -> Dictionary:
	var body: Dictionary = c.body
	var ore := str(body.ore)
	var d := {"x": cell.x, "y": cell.y, "ore": ore, "amount": body_amount(ore, int(body.grade)), "found": str(c.id), "found_by": ref, "found_day": w.day()}
	_enter_seam(d)
	w.map.set_solid(cell, true)
	w.tile_changed.emit(cell, "below", int(w.map.data.tiles.ore.get(ore, w.map.data.tiles.ore.stone)))
	w.note("A trial pit by %s %s strikes %s: a new seam is opened." % [w.prospecting.stain(c), w.prospecting.place(c), GameData.item_name(ore).to_lower()])
	return d


## A seam found (a trial pit's, a pit's or, MIN-F2, a tunnel's): an ordinary World.deposits record with its MIN-B host
## rock, entering the books as found_<ore> (and found_stone), never refilled (OD-28).
func _enter_seam(d: Dictionary) -> void:
	w.deposits.append(d)
	w._add_host_rock()                        # MIN-B: the grey rock round the ore, as every ore seam has
	w.stat("found_" + str(d.ore), float(d.amount))
	if d.has("host"):
		w.stat("found_stone", float(d.host.amount))
	w.stat("seams_found")


## MIN-F2 (Q2): hidden ore below ground (Underground.hidden, generated from the seed before anyone digs) beside a cell a
## tunnel or shaft has just opened is exposed as an ordinary seam on its level: its amount as generated, its host
## rock, found_<ore>, drawn by its level's view. Nobody knew of it before; it is mined by work_mine like any seam.
func open_hidden(h: Dictionary, ref: String) -> Dictionary:
	var d := {"x": int(h.x), "y": int(h.y), "ore": str(h.ore), "amount": int(h.amount), "level": int(h.level), "found": "tunnel", "found_by": ref, "found_day": w.day()}
	_enter_seam(d)
	w.stat("seams_found_below")
	w.level_tile_changed.emit(int(h.level), Vector2i(int(h.x), int(h.y)), int(w.map.data.tiles.ore.get(str(h.ore), w.map.data.tiles.ore.stone)))
	w.note("A tunnel below ground strikes %s: a new seam is opened." % GameData.item_name(str(h.ore)).to_lower())
	return d


## MIN-E: a pit dug down to the rock within reach of clue `c`'s body opens it on `cell` by the trial pit's own rule
## (OpenPits._expose): the same ordinary seam, host rock, counting and note.
func expose(c: Dictionary, cell: Vector2i, ref: String) -> Dictionary:
	return _open_seam(c, cell, ref)


## Where party `ref` would look for clue `c`'s ore: the mean of the cells where the samples it knows of found the ore,
## else the stain.
func aim(c: Dictionary, ref: String) -> Vector2:
	var sum := Vector2.ZERO
	var k := 0
	for r in w.prospecting.records:
		if str(r.clue) == str(c.id) and str(r.ore) != "" and w.prospecting.knows(ref, r):
			sum += Vector2(int(r.x), int(r.y))
			k += 1
	return sum / float(k) if k > 0 else Vector2(int(c.x), int(c.y))


## The cells a party would dig for clue `c`, best first: clear cells (ground_refusal), nearest the mean of the cells
## where the samples it knows of found the ore (else the stain), ties in the clue's hashed spot order.
func dig_cells(c: Dictionary, ref: String) -> Array:
	var at := aim(c, ref)
	var ranked := []
	var spots: Array = c.spots
	for i in spots.size():
		var cell: Vector2i = spots[i]
		if ground_refusal(c, cell) == "":
			ranked.append([Vector2(cell).distance_squared_to(at), i, cell])
	ranked.sort()
	return ranked.map(func(r): return r[2])


## The next cell the manor would have dug for clue `c`, or (-1, -1).
func next_cell(c: Dictionary, ref := World.MANOR) -> Vector2i:
	var cells := dig_cells(c, ref)
	return cells[0] if not cells.is_empty() else Vector2i(-1, -1)


## The find the manor would dig for now: {clue, cell} for the most certain clue it knows traces at (at least
## `manor.min_confidence`), not yet opened, with pits left and clear ground; {} with none. The capability level is never a gate (owner, Q18-9).
func trial_target() -> Dictionary:
	var mc: Dictionary = cfg().manor
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
## least `manor.survey_samples` samples left, not opened; {} with none. The capability level is never a gate (owner, Q18-9).
func survey_target() -> Dictionary:
	var mc: Dictionary = cfg().manor
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


## Owner MIN-D-Q2 (2026-10-21): whether the player is a resident of the village for its capability, by the villagers'
## rule: a villager is one by living here (a household and a home); the player is one while the family has a home in the
## village (PlayerState.home, a building that stands). Losing or giving up the home ends it; the next evaluation (each
## dawn) counts them no more.
func player_resident() -> bool:
	var p: PlayerState = w.player
	return p != null and p.home != "" and w.buildings.has(p.home)


## The village's residents for its capability, in a fixed order: every living adult villager (villager order), then the
## player while resident (player_resident). One list, one rule for all (owner MIN-D-Q2: no bonus, no exclusion).
func residents() -> Array:
	var out: Array = w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "adult")
	if player_resident():
		out.append(w.player)
	return out


## How many tools of `kind` an inventory holds: items of that id or of that tool kind (a rusty pickaxe is a pickaxe).
static func count_kind(inv: Inventory, kind: String) -> int:
	var n := 0
	for id in inv.ids():
		if id == kind or str(GameData.item(id).get("tool", "")) == kind:
			n += inv.count(id)
	return n


## The store a resident shares with their household: a villager's household pantry, the resident player's home chest;
## null with none. Key: who shares it ("hh<i>", "player").
func _shared_store(o) -> Array:
	if o is PlayerState:
		return ["player", (o as PlayerState).chest] if player_resident() else ["", null]
	var n: NPC = o
	if n.household >= 0 and n.household < w.households.size():
		return ["hh%d" % n.household, w.households[n.household].pantry]
	return ["", null]


## Whether resident `o` meets a practitioners need by themselves (owner MIN-E-Q6, MIN-SKILLCAP: real skill and equipment,
## never a job title): their Skills level in `skill` at least `min_level`; a tool of kind `tool` they can use (their own
## pack, or one of their household's store, or for the player their home chest, that `used` has not already given to
## another member: a shared tool serves one practitioner); `jobs` only where the game's own rule makes a trade the sole
## performer (the assayer is a smith, MIN-C-Q3). The same rule for the player and a villager (PAR-01, MIN-D-Q2).
func practitioner(o, need: Dictionary, used := {}) -> bool:
	var jobs: Array = need.get("jobs", [])
	if not jobs.is_empty() and not (o is NPC and jobs.has((o as NPC).job)):
		return false
	if need.has("skill") and Skills.level(o, str(need.skill)) < int(need.get("min_level", 1)):
		return false
	var kind := str(need.get("tool", ""))
	if kind == "" or count_kind(o.inv, kind) > 0:
		return true
	var st := _shared_store(o)
	if st[1] == null:
		return false
	var k := "%s/%s" % [st[0], kind]
	if count_kind(st[1], kind) - int(used.get(k, 0)) > 0:
		used[k] = int(used.get(k, 0)) + 1
		return true
	return false


## The residents who meet a practitioners need (practitioner), in residents() order.
func practitioners(need: Dictionary) -> Array:
	var used := {}
	return residents().filter(func(o) -> bool: return practitioner(o, need, used))


## How many of `tool` (by id or tool kind) the settlement holds: living villagers' packs, the households' stores, the
## manor's works yard, and the resident player's pack and home chest (owner MIN-D-Q2: counted while resident, by the
## villagers' rule; counting moves nothing: the player's goods stay the player's).
func tool_stock(tool: String) -> int:
	var n := 0
	for o: NPC in w.npcs:
		if o.alive:
			n += count_kind(o.inv, tool)
	for hh in w.households:
		n += count_kind(hh.pantry as Inventory, tool)
	n += count_kind(w.manor_work.yard, tool)
	if player_resident():
		n += count_kind(w.player.inv, tool) + count_kind(w.player.chest, tool)
	return n


## Built mining structures of a kind: pit ramps (MIN-E: an open pit whose ramp is dug down to its floor, OpenPits);
## timber supports (MIN-F: those set up below the surface, MineWorks). Counted for the capability level only (Q18-9).
func structures(what: String) -> int:
	if what == "pit_ramp" and w.pits != null:
		return w.pits.ramps_done()
	if what == "timber_support" and w.mine_works != null:
		return w.mine_works.support_count()
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
## The prospector's place in the labour market (NPCBrain.job_market): open while nobody prospects (whatever the
## village's mining capability level: never a gate, owner decision Q18-9), some clue has ground left to sample and the manor could fund a survey
## (the paid work a prospector can count on; it may also prospect on its own, as MIN-C built). Its pay is what
## prospectors have earned, or before any has, a survey's wage over `manor.pay_estimate_days`.
func prospector_place(avg_pay: float) -> Dictionary:
	var mc: Dictionary = cfg().manor
	var open := 0
	if not w.npcs.any(func(o): return o.alive and o.job == Prospecting.JOB) \
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
