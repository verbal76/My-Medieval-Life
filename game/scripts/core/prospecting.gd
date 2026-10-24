class_name Prospecting
extends RefCounted
## MIN-C prospecting and assay (Mining spec stage 2 and section 4, "reading the land"; docs/build17/MIN_C_PROSPECTING.md).
##
## Clues: stains on the ground (a rust-red stain, black streaks, green-stained pebbles, a glitter of flecks), placed from
## the world seed by integer hashing over blocks of the village (Overworld.hash32, salts of their own; never world.rng,
## never the overworld's chunks) and the village's static layout. A clue marks a search area of `radius` cells round its
## stain, not a deposit and not its place. Some clues lie over a mineral body (geology: an ore, a grade and the cell it
## lies under, somewhere in the area), others mislead (no body). A body is never a deposit record: nothing is hidden in
## World.deposits, and opening a body into a finite deposit is MIN-D's. Generated, not saved, like Underground.
##
## Samples: with a prospector's kit (forged at the anvil) anyone, the player or a villager, takes a rock sample from an
## open cell of a clue's area: one per cell, a finite number per clue (`samples_per_clue`), the same time, wear and
## Mining xp for everyone (PAR-01). A sample is an item (ore_sample, counted mined_ore_sample as the rock it is); where
## it was taken is kept in the holder's bag (`bags`, oldest first, matched to the samples in their pack).
##
## Assay: a smith at a forge reads one sample for a fee, with fuel (coal, counted used_coal), at the forge for the
## assay's minutes. The reading is seeded by the sample and the assayer (no world.rng draw): it can find the body's ore and
## an estimate of its grade, miss it, or, over a misleading stain, report traces that are not there. Its stated
## confidence grows with the assayer's Smithing and the sampler's Mining, never to certainty. Each reading is a record
## known only to those who hold it (the sampler and the assayer; a villager prospector reports finds to the manor):
## the "discovery log with provenance" SET-A's capability needs read (MIN_A_ARCHITECTURE.md section 9).
##
## Conservation: the sample's coins (the fee) move from the holder's purse to the assayer's; the sample and the fuel
## are used up and counted; nothing else is made or destroyed. Saved with the world ("prospecting"); absent: none.

const GEN_VERSION := 3                  # 3 (Build 18, DVW-B3-CHAPEL): the chapel and its plot are off the wild ground (154 of seeds 1-300 differ); 2 (ORE-PLACE-01): nothing inside the settlement footprint
const ITEM := "ore_sample"
const KIT := "prospecting_kit"
const JOB := "prospector"
const SALT_CLUE := 0x50524F53
const SALT_BODY := 0x424F4459
const SALT_SPOT := 0x53504F54
const SALT_ASSAY := 0x41535359

static var _cfg := {}

var w: World
var clues: Array = []          # generated: {id, x, y, ore (what the stain looks like), r, samples, spots: [Vector2i], body: {ore, grade, x, y} or {}}
var taken := {}                # clue id -> [[x, y, who], ...]: the cells sampled, and by whom (saved)
var samples := {}              # str(sample id) -> {id, clue, x, y, by, skill, day}: samples not yet assayed (saved)
var bags := {}                 # holder ref -> [sample ids], oldest first: where the samples in a pack came from (saved)
var records: Array = []        # assays: {id, sample, clue, x, y, ore ("" barren), grade, confidence, by, assayer, day, known_by} (saved)
var next_sample := 1
var next_record := 1
var _kit_asked := {}           # villager ref -> the day it last ordered a kit (not saved: one order a day)


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/prospecting.json"))
	return _cfg


static func create(world: World) -> Prospecting:
	var p := Prospecting.new()
	p.w = world
	p.clues = generate(world.seed, world.map)
	return p


# ---------------------------------------------------------------- generation -----------------
## The clues of a village for a seed: per block of `block` cells, a hashed chance of a stain on an open cell of the
## block (the static layout only: no road, building, plot, field, pen, stall, station, tree, plant, container or seam),
## its look by the ores' weights, and for `true_percent` of them a body under a hashed cell within the radius.
## Each clue's spots (the open cells of its area) are in a hashed order. Same seed, same clues, on every machine.
static func generate(world_seed: int, m: VillageMap) -> Array:
	var c := cfg()
	var open := wild_cells(m)              # ORE-PLACE-01: natural evidence only on wild ground
	var bs := int(c.block)
	var r := int(c.radius)
	var ores: Array = c.ores.keys()
	ores.sort()
	var weight := 0
	for o in ores:
		weight += int(c.ores[o].weight)
	var out := []
	for by in range(0, (m.h + bs - 1) / bs):
		for bx in range(0, (m.w + bs - 1) / bs):
			if Overworld.hash32(world_seed, SALT_CLUE, bx, by) % 100 >= int(c.clue_percent):
				continue
			var cell := Vector2i(-1, -1)
			for k in 8:
				var hk := Overworld.hash32(world_seed, SALT_CLUE + 1 + k, bx, by)
				var cc := Vector2i(bx * bs + hk % bs, by * bs + (hk >> 8) % bs)
				if _is_open(open, m, cc):
					cell = cc
					break
			if cell.x < 0:
				continue
			var hb := Overworld.hash32(world_seed, SALT_BODY, cell.x, cell.y)
			var pick := (hb >> 8) % weight
			var ore: String = ores[0]
			for o in ores:
				pick -= int(c.ores[o].weight)
				if pick < 0:
					ore = o
					break
			var clue := {"id": "c%d_%d" % [cell.x, cell.y], "x": cell.x, "y": cell.y, "ore": ore, "r": r,
					"samples": int(c.samples_per_clue), "body": {}, "spots": []}
			var spots := []
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var sc := cell + Vector2i(dx, dy)
					if Vector2(dx, dy).length() <= float(r) + 0.01 and _is_open(open, m, sc):
						spots.append([Overworld.hash32(world_seed, SALT_SPOT, sc.x, sc.y), sc.x, sc.y])
			spots.sort()
			clue.spots = spots.map(func(s): return Vector2i(int(s[1]), int(s[2])))
			if hb % 100 < int(c.true_percent):
				var hg := Overworld.hash32(world_seed, SALT_BODY + 1, cell.x, cell.y)
				var span := 2 * r - 1
				var at := Vector2i(cell.x + hg % span - (r - 1), cell.y + (hg >> 8) % span - (r - 1))
				if not _is_open(open, m, at):
					at = clue.spots[0]           # ORE-PLACE-01: a body never lies under the settlement; the first hashed spot
				clue.body = {"ore": ore, "grade": 1 + (hg >> 16) % 5, "x": at.x, "y": at.y}
			out.append(clue)
	return out


## One byte per village cell: 1 where a stain or a sample spot may lie (the static layout's open ground).
static func _open_cells(m: VillageMap) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(m.w * m.h)
	var d: Dictionary = m.data
	for y in m.h:
		var row: String = d.solid[y]
		for x in m.w:
			b[y * m.w + x] = 1 if row[x] == "0" else 0
	var shut := func(x: int, y: int) -> void:
		if x >= 0 and y >= 0 and x < m.w and y < m.h:
			b[y * m.w + x] = 0
	for c: Vector2i in m.sealed:
		shut.call(c.x, c.y)
	for c in d.road:
		shut.call(int(c[0]), int(c[1]))
	for key in ["buildings", "plots", "legacy_plots", "fields", "pens"]:
		for e in d.get(key, []):
			for y in range(int(e.y) - 1, int(e.y) + int(e.h) + 1):
				for x in range(int(e.x) - 1, int(e.x) + int(e.w) + 1):
					shut.call(x, y)
	for key in ["trees", "plants", "deposits", "containers", "stalls"]:
		for e in d.get(key, []):
			shut.call(int(e.x), int(e.y))
	for st in d.get("stations", []):
		shut.call(int(st.use[0]), int(st.use[1]))
		shut.call(int(st.at[0]), int(st.at[1]))
	for t in m.decor_trees():
		shut.call(int(t.x), int(t.y))
	return b


## The static layout's open ground (_open_cells) less the settlement's footprint (ORE-PLACE-01, owner 2026-10-22: natural deposits belong outside the developed
## village): the wild ground where a stain, a sample spot, a mineral body or a trial pit may lie. The footprint is the
## layout's buildings, plots, fields and pens with `settlement.structures` cells round them, its roads with `roads` and
## the market (stalls) with `market`. Only natural evidence and the search for it are kept out: staking an open pit on
## common ground (OpenPits) keeps the plain open ground, and the mine yard's seams are the village map's own.
static func wild_cells(m: VillageMap) -> PackedByteArray:
	var b := _open_cells(m)
	var d: Dictionary = m.data
	var shut := func(x: int, y: int) -> void:
		if x >= 0 and y >= 0 and x < m.w and y < m.h:
			b[y * m.w + x] = 0
	var fp: Dictionary = cfg().get("settlement", {})
	var ring := func(x0: int, y0: int, w: int, h: int, mg: int) -> void:
		for y in range(y0 - mg, y0 + h + mg):
			for x in range(x0 - mg, x0 + w + mg):
				shut.call(x, y)
	for key in ["buildings", "plots", "legacy_plots", "fields", "pens"]:
		for e in d.get(key, []):
			ring.call(int(e.x), int(e.y), int(e.w), int(e.h), int(fp.get("structures", 0)))
	for c in d.road:
		ring.call(int(c[0]), int(c[1]), 1, 1, int(fp.get("roads", 0)))
	for e in d.get("stalls", []):
		ring.call(int(e.x), int(e.y), 1, 1, int(fp.get("market", 0)))
	return b


static func _is_open(open: PackedByteArray, m: VillageMap, c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < m.w and c.y < m.h and open[c.y * m.w + c.x] == 1


## The clues as text (tests: identical for a seed).
func fingerprint() -> String:
	var parts := PackedStringArray()
	for c in clues:
		var b: Dictionary = c.body
		parts.append("%s %s %d %s %s" % [c.id, c.ore, c.spots.size(), str(c.spots.slice(0, 3)),
				("%s/%d@%d,%d" % [b.ore, int(b.grade), int(b.x), int(b.y)]) if not b.is_empty() else "-"])
	return "\n".join(parts)


# ---------------------------------------------------------------- lookups --------------------
func clue(id: String) -> Dictionary:
	for c in clues:
		if c.id == id:
			return c
	return {}


func in_area(c: Dictionary, cell: Vector2i) -> bool:
	return not c.is_empty() and Vector2(cell - Vector2i(int(c.x), int(c.y))).length() <= float(c.r) + 0.01


## The clue whose search area holds `cell` (one with samples left first), or {}.
func area_at(cell: Vector2i) -> Dictionary:
	var any := {}
	for c in clues:
		if in_area(c, cell):
			if samples_left(c) > 0:
				return c
			if any.is_empty():
				any = c
	return any


func samples_left(c: Dictionary) -> int:
	return int(c.samples) - (taken.get(str(c.id), []) as Array).size()


func sampled(c: Dictionary, cell: Vector2i) -> bool:
	for t in taken.get(str(c.id), []):
		if int(t[0]) == cell.x and int(t[1]) == cell.y:
			return true
	return false


## How many samples `ref` has taken from clue `c`.
func taken_by(c: Dictionary, ref: String) -> int:
	return (taken.get(str(c.id), []) as Array).filter(func(t): return str(t[2]) == ref).size()


## "a rust-red stain in the soil", the look of a clue's stain.
func stain(c: Dictionary) -> String:
	return str(cfg().ores.get(str(c.get("ore", "")), {}).get("stain", "a stain in the soil"))


## Where a clue lies, in the village's words ("north of the mine").
func place(c: Dictionary) -> String:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("prospecting.place", place.bind(c), [c])
	return w.where(Rect2i(int(c.x), int(c.y), 1, 1))


static func grade_name(g: int) -> String:
	var names: Array = cfg().grades
	return str(names[clampi(g, 1, names.size()) - 1])


static func ref_of(who) -> String:
	return Contracts.ref_of(who)


# ---------------------------------------------------------------- samples --------------------
## The samples `who` carries, oldest first, matched to their pack: a sample gone from the pack (dropped, sold, left to
## an heir) takes its place in the bag with it, oldest first; a sample in the pack with no bag entry is of unknown origin.
func bag_of(who) -> Array:
	var ref := ref_of(who)
	var bag: Array = bags.get(ref, [])
	var have: int = who.inv.count(ITEM)
	while bag.size() > have:
		samples.erase(str(bag.pop_front()))
	bags[ref] = bag
	return bag


## Why `who` cannot take a sample from `cell` of clue `c` now ("" if they can).
func sample_refusal(who, c: Dictionary, cell: Vector2i) -> String:
	if c.is_empty() or not in_area(c, cell) or not w.map.in_village(cell):
		return "There is no sign of ore here to sample."
	if not who.inv.has(KIT):
		return "You need a prospector's kit to take samples (forged at an anvil: an iron bar, a plank and leather)."
	if samples_left(c) <= 0:
		return "The ground round this stain has been sampled out."
	if sampled(c, cell):
		return "This spot has been sampled already: try another round the stain."
	if w.map.is_solid(cell):
		return "There is no open ground there to sample."
	if not who.inv.can_add(ITEM):
		return who.inv.full_text(ITEM)
	return ""


## `who` (the player or a villager) takes a rock sample from `cell` of clue `c`, by one rule (PAR-01): the kit wears,
## the sample (an ore_sample, counted mined_ore_sample) goes to their pack and its origin to their bag, and the work
## earns sample_xp Mining xp. Returns {result: "ok" | "refused", why, sample, broke, up}.
func take_sample(who, c: Dictionary, cell: Vector2i) -> Dictionary:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("prospecting.take_sample", take_sample.bind(who, c, cell), [who, c, cell])
	var why := sample_refusal(who, c, cell)
	if why != "":
		return {"result": "refused", "why": why}
	var ref := ref_of(who)
	var t: Array = taken.get(str(c.id), [])
	t.append([cell.x, cell.y, ref])
	taken[str(c.id)] = t
	var id := next_sample
	next_sample += 1
	samples[str(id)] = {"id": id, "clue": str(c.id), "x": cell.x, "y": cell.y, "by": ref, "skill": Skills.level(who, "mining"), "day": w.day()}
	var bag := bag_of(who)
	w._work_goods(who, who.inv, ITEM, 1, "mined_")
	bag.append(id)
	var broke := w._work_wear(who, KIT, int(cfg().kit_wear), "mining", "tool_wear_save")
	if broke and who is PlayerState and who.tool == KIT:
		who.tool = ""
	w.stat("prospect_samples")
	return {"result": "ok", "why": "", "sample": id, "broke": broke, "up": Skills.gain(who, "mining", int(cfg().sample_xp))}


## How long the player's sampling takes (seconds), as their mining swing is timed: sample_minutes at the game's speed.
static func player_secs() -> float:
	return float(cfg().sample_minutes) / float(GameData.b("game_minutes_per_second")) * 0.6


# ---------------------------------------------------------------- assay ----------------------
## Why smith `a` cannot assay a sample of `who`'s now ("" if they can): a smith with the assay's Smithing level, awake
## and at the forge's workplace, with no assay already in hand, with the fuel and a forge they may use; `who`
## holds a sample whose origin is known and the fee.
func assayer_refusal(who, a: NPC) -> String:
	var ac: Dictionary = cfg().assay
	if a == null or not a.alive or a.role != "adult" or a.job != "smith":
		return "Only a smith at a forge can assay ore."
	if who.inv.count(ITEM) <= 0:
		return "You have no rock sample to assay."
	if bag_of(who).is_empty():
		return "Nobody knows where this sample was taken: it cannot be assayed."
	if w.asleep(a):
		return "%s is asleep." % a.name
	if Skills.level(a, str(ac.skill)) < int(ac.level):
		return "%s cannot assay ore yet." % a.name
	if a.pos.distance_to(Vector2(w.brain._workplace_cell(a)) + Vector2(0.5, 0.5)) > 3.0:
		return "%s is not at the forge." % a.name
	if a.plan.any(func(s): return str(s.get("act", "")) == "assay_done"):
		return "%s is busy with an assay. Come back shortly." % a.name
	if not a.inv.has_all(ac.fuel):
		return "%s has no coal to fire the forge." % a.name
	if w.brain._station_for(a, str(ac.station)) == "":
		return "The forge is in use."
	if int(who.coins) < int(ac.fee):
		return "An assay costs %d coins." % int(ac.fee)
	return ""


## Smith `a` assays the oldest sample `who` carries (or sample `pick`, if they carry it: MIN-D, a survey's own first): the sample and the fuel are used up, the fee passes from `who`'s
## purse to the smith's, the smith works the forge for the assay's minutes (the forge is theirs meanwhile) and earns
## Smithing xp, and the reading becomes a record that `who` and the smith know. Returns {result: "ok" | "refused", why,
## record, up}.
func assay(who, a: NPC, pick := -1) -> Dictionary:
	# MP C (World.mirror): a guest's verb goes to the host
	if w.mirrors():
		return w.mirror("prospecting.assay", assay.bind(who, a, pick), [who, a, pick])
	var why := assayer_refusal(who, a)
	if why != "":
		return {"result": "refused", "why": why}
	var ac: Dictionary = cfg().assay
	var bag := bag_of(who)
	var sid: int = pick if pick >= 0 and bag.has(pick) else int(bag.front())
	bag.erase(sid)
	var s: Dictionary = samples.get(str(sid), {})
	samples.erase(str(sid))
	who.inv.remove(ITEM, 1)
	w.stat("used_" + ITEM)
	a.inv.remove_all(ac.fuel)
	for id in ac.fuel:
		w.stat("used_" + str(id), float(ac.fuel[id]))
	var fee := int(ac.fee)
	who.coins -= fee
	a.coins += fee
	a.earned += fee
	if who is NPC:
		who.spent += fee
	w.stat("assay_fees", fee)
	var st: String = w.brain._station_for(a, str(ac.station))
	var mins := float(ac.minutes) * Skills.value(a, str(ac.skill), "craft_time", 1.0)
	w.stations[st].users[a.id] = w.minutes + mins + float(w.map.data.w) + 60.0
	# the assay is the smith's next work: after the piece in hand (a craft half done is not thrown away), else at once
	var steps := [w.brain.go(w.station_use(st)), w.brain.work(mins, "assay_done", {"station": st}, "work", w.brain._station_at(st))]
	var at := 0
	for i in a.plan.size():
		if str(a.plan[i].get("k", "")) == "work":
			at = i + 1
			break
	for i in steps.size():
		a.plan.insert(at + i, steps[i])
	if at == 0:
		a.doing = "assaying a sample"
	var rec := reading(s, a)
	rec.id = next_record
	next_record += 1
	rec.by = ref_of(who)
	rec.assayer = World.npc_ref(a.id)
	rec.day = w.day()
	rec.known_by = [rec.by, rec.assayer]
	rec.known_by.sort()
	records.append(rec)
	w.stat("assays")
	if str(rec.ore) != "":
		w.stat("assay_traces")
	return {"result": "ok", "why": "", "record": rec, "up": Skills.gain(a, str(ac.skill), int(ac.xp))}


## What smith `a` reads in sample `s`: {sample, clue, x, y, ore ("" barren), grade (0 barren, 1-5), confidence}.
## The assayer's stated confidence is base + per_assayer_level x Smithing + per_sampler_level x the sampler's Mining
## (at sampling), between least and most: never certain. Over a body, the ore is found with that chance, less the
## farther the sample was taken from it (near_body: the share left at the area's edge), its grade within one step
## (two below fine_grade_from); over no body, traces of the stain's ore are reported with (1 - confidence) x false_trace.
## Seeded by the world seed, the sample and the assayer (Overworld.hash32): no world.rng draw.
func reading(s: Dictionary, a: NPC) -> Dictionary:
	var ac: Dictionary = cfg().assay
	var c := clue(str(s.get("clue", "")))
	var rel := clampf(float(ac.base) + float(ac.per_assayer_level) * Skills.level(a, str(ac.skill)) + float(ac.per_sampler_level) * int(s.get("skill", 1)),
			float(ac.least), float(ac.most))
	var sid := int(s.get("id", 0))
	var u := float(Overworld.hash32(w.seed, SALT_ASSAY, sid, a.id) % 100000) / 100000.0
	var h2 := Overworld.hash32(w.seed, SALT_ASSAY + 1, sid, a.id)
	var ore := ""
	var grade := 0
	var body: Dictionary = c.get("body", {})
	if not body.is_empty():
		var d := Vector2(int(s.x), int(s.y)).distance_to(Vector2(int(body.x), int(body.y)))
		var near := clampf(1.0 - d / (float(c.r) + 2.0), 0.0, 1.0)
		if u < rel * (float(ac.near_body) + (1.0 - float(ac.near_body)) * near):
			ore = str(body.ore)
			var spread := 1 if rel >= float(ac.fine_grade_from) else 2
			grade = clampi(int(body.grade) + h2 % (2 * spread + 1) - spread, 1, 5)
	elif not c.is_empty() and u < (1.0 - rel) * float(ac.false_trace):
		ore = str(c.ore)
		grade = 1
	return {"sample": sid, "clue": str(s.get("clue", "")), "x": int(s.get("x", 0)), "y": int(s.get("y", 0)), "ore": ore, "grade": grade,
			"confidence": snappedf(rel, 0.05)}


## The words of a reading: "traces of iron ore, middling (the smith is about 7 in 10 sure)".
func reading_text(rec: Dictionary) -> String:
	var sure := roundi(float(rec.confidence) * 10.0)
	if str(rec.ore) == "":
		return "nothing worth mining (about %d in 10 sure)" % sure
	return "traces of %s, %s (about %d in 10 sure)" % [GameData.item_name(str(rec.ore)).to_lower(), grade_name(int(rec.grade)), sure]


# ---------------------------------------------------------------- knowledge ------------------
func record(id: int) -> Dictionary:
	for r in records:
		if int(r.id) == id:
			return r
	return {}


func knows(ref: String, rec: Dictionary) -> bool:
	return (rec.get("known_by", []) as Array).has(ref)


## `ref` learns a record (it is told). True if it did not know it.
func share(rec: Dictionary, ref: String) -> bool:
	if rec.is_empty() or knows(ref, rec):
		return false
	var kb: Array = rec.known_by
	kb.append(ref)
	kb.sort()
	return true


## What `ref` knows of each clue, from the assays it holds (clues in generation order): {clue, ore (the ore most often
## found, "" none), traces, barren, grade (the mean estimate, rounded), confidence (1 - the product of (1 - each
## finding's confidence), at most 0.95: never certain), x, y}. MIN-D's discovery reads this.
func findings(ref: String) -> Array:
	var out := []
	for c in clues:
		var mine := records.filter(func(r): return str(r.clue) == str(c.id) and knows(ref, r))
		if mine.is_empty():
			continue
		var by_ore := {}
		var barren := 0
		for r in mine:
			if str(r.ore) == "":
				barren += 1
			else:
				by_ore[str(r.ore)] = int(by_ore.get(str(r.ore), 0)) + 1
		var best := ""
		var ores := by_ore.keys()
		ores.sort()
		for o in ores:
			if best == "" or int(by_ore[o]) > int(by_ore[best]):
				best = o
		var grade := 0.0
		var doubt := 1.0
		for r in mine:
			if str(r.ore) == best and best != "":
				grade += float(r.grade)
				doubt *= 1.0 - float(r.confidence)
		var n := int(by_ore.get(best, 0))
		out.append({"clue": str(c.id), "x": int(c.x), "y": int(c.y), "ore": best, "traces": n, "barren": barren,
				"grade": roundi(grade / float(n)) if n > 0 else 0, "confidence": minf(0.95, 1.0 - doubt) if n > 0 else 0.0})
	return out


# ---------------------------------------------------------------- villagers ------------------
## A prospector's day (NPCBrain._plan_job): report a find the manor has not heard of; take the samples carried to a
## smith who can assay them (with the fee in hand) once the bag is full or no ground is left; get a kit (buy one, or
## order one from a smith by a CON-01 contract); else take a sample at the nearest clue it has not done with. With
## nothing to do, the manor's open work (NPCBrain._idle_at_work), as any worker idle in its trade.
func plan(n: NPC) -> bool:
	var b: NPCBrain = w.brain
	var me := World.npc_ref(n.id)
	for rec in records:
		if str(rec.by) == me and str(rec.ore) != "" and not knows(World.MANOR, rec):
			n.doing = "reporting a find to the manor"
			n.plan = [b.go(w.building_door(b._manor_id())), b.doit("report_find", {"id": int(rec.id)})]
			return true
	if w.hour() < float(GameData.b("manor_jobs").get("latest_start", 15)) and w.manor_work.seek_kind(n, ["survey"]):
		return true                       # MIN-D: the manor's commissioned survey, paid work, before prospecting on its own
	var bag := bag_of(n)
	var spot := next_spot(n) if bag.size() < int(cfg().carry_samples) else {}
	if not bag.is_empty() and spot.is_empty():
		var a := assayer_for(n)
		if a != null:
			n.doing = "taking samples to the assayer"
			n.plan = [b.go(b._workplace_cell(a))]
			for i in bag.size():                  # one sample at a time: the smith's assay, then the next (a little slack)
				n.plan.append_array([b.doit("assay", {"assayer": a.id}), b.work(float(cfg().assay.minutes) + 10.0, "", {}, "idle")])
			return true
		return b._idle_at_work(n, "waiting for an assayer")
	if not n.inv.has(KIT):
		return _get_kit(n)
	if spot.is_empty():
		return b._idle_at_work(n, "no ground left to prospect")
	var c: Dictionary = spot.clue
	n.doing = "prospecting %s" % stain(c)
	n.plan = [b.go(spot.cell), b.work(float(cfg().sample_minutes) * Skills.value(n, "mining", "mine_time", 1.0), "prospect",
			{"clue": str(c.id), "x": spot.cell.x, "y": spot.cell.y}, "work", spot.cell)]
	return true


## The next place `n` would sample: the nearest clue with samples left that it has taken fewer than samples_per_visit
## from, at the first of its spots (hashed order) that is unsampled and open now. {clue, cell} or {}.
func next_spot(n: NPC) -> Dictionary:
	var me := World.npc_ref(n.id)
	var best := {}
	var bd := 1e9
	for c in clues:
		if samples_left(c) <= 0 or taken_by(c, me) >= int(cfg().samples_per_visit) or not n.inv.has(KIT):
			continue
		var d := Vector2(n.cell()).distance_to(Vector2(int(c.x), int(c.y)))
		if d >= bd:
			continue
		for cell: Vector2i in c.spots:
			if not sampled(c, cell) and not w.map.is_solid(cell):
				best = {"clue": c, "cell": cell}
				bd = d
				break
	return best


## The smith who could assay `n`'s samples (awake, with the fuel and the level; `n` with the fee), the nearest to `n`.
func assayer_for(n: NPC) -> NPC:
	var ac: Dictionary = cfg().assay
	if n.coins < int(ac.fee):
		return null
	var best: NPC = null
	var bd := 1e9
	for o: NPC in w.npcs:
		if o == n or not o.alive or o.role != "adult" or o.job != "smith" or w.asleep(o) or not o.inv.has_all(ac.fuel) \
				or Skills.level(o, str(ac.skill)) < int(ac.level):
			continue
		var d := n.pos.distance_to(Vector2(w.brain._workplace_cell(o)))
		if d < bd:
			bd = d
			best = o
	return best


## A prospector without a kit buys one a smith or the goods merchant has for sale; with none for sale it orders one
## from a smith by the same CON-01 offer as anyone (the item's value, a few days), once a day, and waits for it.
func _get_kit(n: NPC) -> bool:
	var b: NPCBrain = w.brain
	var me := World.npc_ref(n.id)
	for o: NPC in w.npcs:
		if o.alive and o != n and (o.job == "smith" or b.buy_role(o) == "merchant_goods") and o.inv.has(KIT) and not b.keeps(o, KIT) \
				and n.coins >= w.sell_price(o, KIT):
			n.doing = "buying a prospector's kit"
			n.plan = [b.go(b._workplace_cell(o)), b.doit("buy_from", {"vendor": o.id, "item": KIT, "qty": 1})]
			return true
	var k: Contracts = w.contracts
	var waiting := k.waiting_on(me, KIT)                     # open, offered, or agreed and to be signed face to face (Q18-13)
	if not waiting and int(_kit_asked.get(me, -1)) != w.day():
		_kit_asked[me] = w.day()
		var price := GameData.value(KIT)
		var days := int(Contracts.cfg().npc_order_days)
		if k.fund_refusal(me, price) == "":
			var smiths := []
			for s: NPC in w.npcs:
				if s != n and s.alive and s.role == "adult" and s.job == "smith":
					smiths.append(s)
			if JudgmentLive.on(w, "contract_seller"):        # PROSPECTIVE (PROS-19, Q14): off unless judgment is attached
				smiths = JudgmentLive.seller_order(w, n, smiths, [w.day(), KIT.hash()])
			for s: NPC in smiths:
				var r := k.propose(me, s, KIT, 1, price, days)
				if r.has("contract") or r.has("signing") or k.meet_counter(n, s, KIT, 1, price, 1, r):     # a smith's counter, by every buyer's rule
					break
	return b._idle_at_work(n, "waiting for a prospector's kit")


## The act at the end of a villager's sampling work (NPCBrain.act "prospect").
func npc_sample(n: NPC, a: Dictionary) -> bool:
	var r := take_sample(n, clue(str(a.clue)), Vector2i(int(a.x), int(a.y)))
	if r.result != "ok":
		return false
	if r.broke:
		w.note("%s %s's prospector's kit is worn out." % [n.name, n.family])
	return true


## The act on reaching the smith (NPCBrain.act "assay"): the oldest sample carried is assayed (the smith is then at
## the forge for the assay's minutes; the prospector waits and hands over the next). Refused (the smith away, busy or out of coal), the prospector waits
## the same time beside the forge before planning again, so a refusal costs time and never loops.
func npc_assay(n: NPC, a: Dictionary) -> bool:
	var r := assay(n, w.npc(int(a.assayer)))
	if r.result != "ok":
		w.stat("assay_refused")
		n.doing = "waiting for the assayer"
	return true


## The act at the manor (NPCBrain.act "report_find"): the manor learns the find (and every find of the reporter's).
func report(n: NPC, id: int) -> bool:
	var me := World.npc_ref(n.id)
	var told := false
	for rec in records:
		if str(rec.by) == me and str(rec.ore) != "" and share(rec, World.MANOR):
			told = true
	if told:
		w.stat("prospect_reports")
		n.remember("reported traces of ore to the manor")
	return told or not record(id).is_empty()


# ---------------------------------------------------------------- save -----------------------
func to_dict() -> Dictionary:
	var b := {}
	for ref in bags:
		if not (bags[ref] as Array).is_empty():
			b[ref] = (bags[ref] as Array).duplicate()
	return {"gen": GEN_VERSION, "taken": taken.duplicate(true), "samples": samples.duplicate(true), "bags": b,
			"records": records.duplicate(true), "next_sample": next_sample, "next_record": next_record}


## A save without prospecting (Build 16, or Build 17 before MIN-C) loads with nothing sampled, carried or known.
## Cells sampled of a clue the generator no longer makes (a GEN_VERSION change) are kept by its id, inert: the player's
## work is never silently dropped (SAVE rule, CLAUDE.md section 7); records keep.
func load_dict(d: Dictionary) -> void:
	taken = {}
	for id in d.get("taken", {}):
		taken[str(id)] = (d.taken[id] as Array).map(func(t): return [int(t[0]), int(t[1]), str(t[2])])
	samples = {}
	for k in d.get("samples", {}):
		var s: Dictionary = (d.samples[k] as Dictionary).duplicate()
		for f in ["id", "x", "y", "skill", "day"]:
			s[f] = int(s.get(f, 0))
		samples[str(k)] = s
	bags = {}
	for ref in d.get("bags", {}):
		bags[str(ref)] = (d.bags[ref] as Array).map(func(v): return int(v))
	records = []
	for r in d.get("records", []):
		var rec: Dictionary = (r as Dictionary).duplicate(true)
		for f in ["id", "sample", "x", "y", "grade", "day"]:
			rec[f] = int(rec.get(f, 0))
		rec.confidence = float(rec.get("confidence", 0.0))
		records.append(rec)
	next_sample = int(d.get("next_sample", 1))
	next_record = int(d.get("next_record", 1))
