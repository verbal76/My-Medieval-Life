class_name Trees
extends RefCounted
## The one tree model, for the village's trees (World.trees) and the overworld's changed trees
## (Overworld.changes). Headless: no nodes; the view (TreeView) only draws what this says.
##
## A tree is a Dictionary {x, y, species, state, regrow, born, ...}; (x, y) is the trunk's cell and
## `species` one of the art variants in res://assets/trees/trees.json (oak_summer, oak_autumn,
## oak_snow, pine_summer, pine_snow). `state` is the growth stage, kept up to date lazily from the
## game clock (sync): there is no simulation of trees, a tree that nobody looks at costs nothing.
##
##   sapling -> young -> growing -> grown (MATURE) -> (felled) -> stump -> sapling ...
##
## `born` is the game minute the sapling began to grow; the later stages follow from the stage lengths
## in balance.json "tree_growth" (game days, provisional). A stump is due to sprout at the dawn of day
## `regrow`. Only a mature ("grown") tree can be felled. Saplings and young trees are not solid, a
## growing or mature tree's trunk is, a stump is not (paths stay clear). "cleared" is ground bought for
## building: nothing grows there.
##
## Development only: `--tree-growth N` on the command line makes every stage and the stump's
## regrowth N times faster, honoured only when OS.is_debug_build() (never in a release export);
## tests set Trees.growth_speed directly.

const DAY := 1440.0
const STAGES := ["sapling", "young", "growing", "grown"]
const ART := "res://assets/trees/"
const DAWN := 0.25                          # a stump sprouts at 06:00 of its day

static var growth_speed := 1.0
static var _cli_read := false
static var _art := {}
static var _textures := {}


## The growth speed-up in force (1 in a release build).
static func speed() -> float:
	if not _cli_read:
		_cli_read = true
		if OS.is_debug_build():
			var a := OS.get_cmdline_user_args()
			for i in a.size() - 1:
				if a[i] == "--tree-growth":
					growth_speed = maxf(1.0, float(a[i + 1]))
	return growth_speed


static func cfg() -> Dictionary:
	return GameData.b("tree_growth")


# ---------------------------------------------------------------- art ------------------------
## res://assets/trees/trees.json (mml-trees-art/1, Living Forest), with the fruit trees of
## fruit_trees.json (Craftpix, B14) merged into its variants; read once.
static func art() -> Dictionary:
	if _art.is_empty():
		_art = JSON.parse_string(FileAccess.get_file_as_string(ART + "trees.json"))
		if FileAccess.file_exists(ART + "fruit_trees.json"):
			var fruit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART + "fruit_trees.json"))
			for k in fruit.variants:
				_art.variants[k] = fruit.variants[k]
	return _art


static func texture(file: String) -> Texture2D:
	if not _textures.has(file):
		_textures[file] = load(ART + file)
	return _textures[file]


static func variant(species: String) -> Dictionary:
	return art().variants.get(species, art().variants.oak_summer)


## "oak" or "pine".
static func family_of(species: String) -> String:
	return species.get_slice("_", 0)


static func sapling_item(species: String) -> String:
	return family_of(species) + "_sapling"


## The species a sapling item plants: a summer or autumn variant of its family, by a hash of the cell.
static func planted_species(item: String, cell: Vector2i) -> String:
	var fam: String = str(GameData.item(item).get("plant", "oak"))
	var h := Overworld.hash32(cell.x, cell.y, 5, 17)
	if fam == "pine":
		return "pine_summer"
	if fam == "apple":
		return "apple_orchard"
	return "oak_summer" if h % 3 != 0 else "oak_autumn"


# ---------------------------------------------------------------- fruit (B14) ----------------
## The fruit settings of a fruit-tree species (balance.json "fruit_trees"), {} for other trees.
static func fruit_cfg(species: String) -> Dictionary:
	var f: Dictionary = GameData.b("fruit_trees")
	return f.get(species, {}) if f.has(species) and species != "_note" else {}


## Whether a tree's fruit hangs ripe now: a grown fruit tree, past its `fruit_day` (the day it bears
## again after picking; 0 for one never picked), in a fruiting season. Lazy like growth: nothing ticks.
static func fruit_ripe(t: Dictionary, day: int, season: String) -> bool:
	var f := fruit_cfg(str(t.get("species", "")))
	return not f.is_empty() and str(t.state) == "grown" and day >= int(t.get("fruit_day", 0)) and (f.seasons as Array).has(season)


## The species of a generated tree from the generator's group (leafy, autumn, mixed, conifer), its cell
## and whether it stands high up (mountain pines and oaks carry snow). Trees of a patch of 8 x 8 cells
## mostly share one species (natural clusters), the rest are mixed in by a hash of their own cell, so
## neither a grid of identical neighbours nor noise. Pure function of its arguments: a chunk that is
## unloaded and loaded again gives the same trees.
static func species_for(group: String, x: int, y: int, high: bool) -> String:
	var pool: Array
	if high:
		pool = ["pine_snow", "pine_snow", "pine_snow", "oak_snow"]
	else:
		match group:
			"leafy":
				pool = ["oak_summer", "oak_summer", "oak_summer", "oak_summer", "oak_autumn"]
			"autumn":
				pool = ["oak_autumn", "oak_autumn", "oak_autumn", "oak_summer", "pine_summer"]
			"conifer":
				pool = ["pine_summer", "pine_summer", "pine_summer", "oak_summer"]
			_:
				pool = ["oak_summer", "pine_summer", "oak_autumn", "pine_summer"]
	var patch := Overworld.hash32(x >> 3, y >> 3, 7, 95)
	var own := Overworld.hash32(x, y, 8, 96)
	return pool[(patch if own % 100 < 65 else own) % pool.size()]


## Whether a generated tree starts fully grown (about 70%): one hash, for the cheap collision test.
static func starts_mature(x: int, y: int) -> bool:
	return Overworld.hash32(x, y, 9, 97) % 100 < 70


## The game minute a generated tree began to grow: before the game's start, by a hash of its cell, so
## the world begins with trees of every stage (about 70% mature, the rest growing, young or saplings
## in their own time of the stage) that go on growing by the clock.
static func initial_born(x: int, y: int) -> float:
	var r := Overworld.hash32(x, y, 9, 97) % 100
	var frac := float(Overworld.hash32(x, y, 10, 98) % 100) / 100.0
	if r < 70:
		return -1.0e7
	var age := 0.0
	var stages := ["growing", "young", "sapling"]
	var pick: String = stages[0] if r < 82 else (stages[1] if r < 92 else stages[2])
	for s in ["sapling", "young", "growing"]:
		if s == pick:
			age += frac * stage_minutes(s)
			break
		age += stage_minutes(s)
	return -age


# ---------------------------------------------------------------- growth ---------------------
static func solid(state: String) -> bool:
	return state == "growing" or state == "grown"


static var _lens_speed := -1.0
static var _lens_year := -1
static var _lens := {}


## Game minutes a stage lasts (before the development speed-up).
static func stage_minutes(stage: String) -> float:
	var sp := speed()
	if sp != _lens_speed or Life.year_days() != _lens_year:
		_lens_speed = sp
		_lens_year = Life.year_days()
		var c := cfg()
		for k in ["sapling", "young", "growing"]:          # tree_growth.<stage>_seasons, calendar seasons (TIME-02)
			_lens[k] = Life.seasons_to_days(float(c.get(k + "_seasons", 0.5))) * DAY / sp
	return _lens.get(stage, 0.0)


## The stage a tree born `age` game minutes ago has reached.
static func stage_at(age: float) -> String:
	if age >= stage_minutes("sapling") + stage_minutes("young") + stage_minutes("growing"):
		return "grown"
	var t := stage_minutes("sapling")
	if age < t:
		return "sapling"
	t += stage_minutes("young")
	return "young" if age < t else "growing"


## The game minute a sapling is born at, for a record without one (a test's, an old save's).
static func born_of(t: Dictionary) -> float:
	return float(t.born) if t.has("born") else float(t.get("regrow", 0.0)) * DAY


## The game minute at which the tree's state will next change by itself, or INF.
static func next_change(t: Dictionary) -> float:
	match str(t.state):
		"stump":
			return float(t.regrow) * DAY
		"sapling", "young", "growing":
			var at := born_of(t)
			for s in STAGES:
				at += stage_minutes(s)
				if s == t.state:
					return at
	return INF


## Bring a tree's stage up to the game clock `now`; true if it changed. `hold`: someone stands on the
## cell, so it does not become solid yet (a young tree waits to be a growing one).
static func sync(t: Dictionary, now: float, hold := false) -> bool:
	var before := str(t.state)
	if t.state == "stump":
		if now < float(t.regrow) * DAY:
			return false
		t.state = "sapling"
		t.born = float(t.regrow) * DAY
	if t.state in ["sapling", "young", "growing"]:
		var s := stage_at(now - born_of(t))
		if hold and solid(s) and not solid(str(t.state)):
			s = "young"
		t.state = s
	return str(t.state) != before


## The day (a number, the fraction is the time of day) a tree felled at game minute `now` sprouts again:
## tree_regrow_seasons (in whole days) later at dawn, quicker when growth is sped up for development.
static func regrow_day(now: float, days: int) -> float:
	return floorf(now / DAY) + (float(days) + DAWN) / speed()


## What a tree is called in a prompt.
static func describe(state: String) -> String:
	return {"sapling": "A sapling", "young": "A young tree", "growing": "A growing tree", "grown": "A mature tree",
			"stump": "A stump", "cleared": "Cleared ground"}.get(state, "A tree")


## Why a tree cannot be felled, "" if it can: only a mature one.
static func refusal(state: String) -> String:
	match state:
		"grown":
			return ""
		"stump":
			return "Only a stump is left. It sprouts again in a few days."
		"cleared":
			return "The ground was cleared for building. Nothing grows here now."
		"sapling":
			return "It is only a sapling: it has to grow into a mature tree first."
		"young":
			return "It is too young to fell: let it grow into a mature tree first."
	return "It is not yet a mature tree: let it grow first."


## A few words for a prompt: what the tree is waiting for.
static func hint(state: String) -> String:
	return {"sapling": "it is growing", "young": "too young to fell, it is growing", "growing": "not mature yet, it is growing",
			"stump": "it sprouts again in a few days", "cleared": "nothing grows here now"}.get(state, "")
