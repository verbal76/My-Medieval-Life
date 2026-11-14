class_name Demo
extends RefCounted
## DEMO-01 (owner 2026-11-03): the demo build's allowance of active play, per world. One source with the full game: the demo is the
## same game exported with the "demo" feature tag (export_presets.cfg); the full game never applies any of this.
##
## The allowance (game/data/demo.json: 120 minutes) belongs to a world: it is kept in the save's metadata (`meta.demo`, beside the
## world's stable id `meta.save_id`), so saving, loading, restarting, renaming or copying the file keeps it, every character in the
## world (an heir, a guest) shares it, and a new world starts with a fresh one. It lives outside World: the simulation is the same in
## both builds.
##
## The clock is Main's frame time, counted only where Main advances the world (not paused, not on a menu or the title, not while
## loading, not while the application is in the background, and not through windows that pause the world). It is monotonic: a frame
## never counts more than `max_step` (a frame after a suspension, a stall or a system-clock jump counts no more than that) and never
## less than nothing. Tests drive it with their own frame times (tick): no real waiting.
##
## meta.demo = {allowance: seconds, active: seconds used, warned: [seconds-remaining thresholds already shown], expired: bool}.

const PATH := "res://data/demo.json"

static var _cfg := {}
static var force := -1                  # tests: 1 the demo build, 0 the full game, -1 the export's feature tag


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_cfg = j if j is Dictionary else {}
	return _cfg


## Whether this is the demo build (the "demo" export feature; tests set `force`).
static func is_demo() -> bool:
	return force == 1 if force >= 0 else OS.has_feature("demo")


## B42-DEMO-SAVE-OVERWRITE (owner 2026-11-14, B4: "Demo overwrites full-game saves: a player-data protection defect"): the demo
## keeps its worlds in a folder of its own, "demo/" beside the full game's save (on Windows and Linux both editions have one user
## folder, named by config/name; on Android each app has its own storage). So nothing the demo does (New game, Continue, autosave,
## its previous and kept worlds, backups, Import) reaches the full game's save slot, and nothing the full game does reaches the
## demo's. A demo world goes on in the full game when the player chooses it there ("Continue your demo world", Main.continue_demo_world:
## the full game's own world is kept aside first), or by Export and Import as on Android.
const SLOT_DIR := "demo"


## The save slot of an edition for the full game's slot `base` ("user://save1.json" -> "user://demo/save1.json" in the demo).
static func slot(base: String, demo := is_demo()) -> String:
	return base.get_base_dir().path_join(SLOT_DIR).path_join(base.get_file()) if demo else base


## B42-DEMO-SAVE-OVERWRITE, existing players: before Build 42 the demo saved in the full game's slot. The first time the demo finds
## its own slot empty, the worlds it had made there (a readable save with a demo record that the full game has not marked its own)
## are COPIED into its slot: the world in the slot (or its backup), the previous game and the kept used-up worlds. Nothing is moved
## or removed, so the full game's Continue still finds a world it found before. Returns the files written.
static func adopt_legacy(base: String, demo_slot: String) -> Array:
	var out := []
	var stem := base.get_basename()
	var pairs := []
	var cur := base if FileAccess.file_exists(base) else base + SaveStore.BAK
	pairs.append([cur, demo_slot])
	pairs.append([stem + ".previous.json", demo_slot.get_basename() + ".previous.json"])
	var dir := base.get_base_dir()
	if DirAccess.dir_exists_absolute(dir):
		var names := Array(DirAccess.get_files_at(dir))
		names.sort()
		for f in names:
			if f.begins_with(stem.get_file() + ".expired-") and f.ends_with(".json"):
				pairs.append([dir.path_join(f), demo_slot.get_base_dir().path_join(f)])
	for pr in pairs:
		var from: String = pr[0]
		var to: String = pr[1]
		if FileAccess.file_exists(to) or not FileAccess.file_exists(from):
			continue
		var text := FileAccess.get_file_as_string(from)
		var r := SaveStore.inspect_text(text, World.SAVE_VERSION)
		if r.state != "ok":
			continue
		var meta = (r.data as Dictionary).get("meta", {})
		if not (meta is Dictionary) or not (meta.get("demo") is Dictionary) or str(meta.get("edition", "")) == "full":
			continue
		if bool(SaveStore.write_text(to, text).ok):
			out.append(to)
	return out


## The world's demo record, made whole (a world from before the demo, or the full game's, starts its allowance now).
static func state(meta: Dictionary) -> Dictionary:
	if not (meta.get("demo") is Dictionary):
		meta["demo"] = {}
	var d: Dictionary = meta["demo"]
	if not d.has("allowance"):
		d["allowance"] = float(cfg().get("allowance_seconds", 7200))
	d["allowance"] = maxf(0.0, float(d.allowance))
	d["active"] = clampf(float(d.get("active", 0.0)), 0.0, float(d.allowance))
	if not (d.get("warned") is Array):
		d["warned"] = []
	d["warned"] = (d.warned as Array).map(func(x): return int(x))
	d["expired"] = bool(d.get("expired", false)) or float(d.active) >= float(d.allowance)
	return d


static func remaining(meta: Dictionary) -> float:
	var d := state(meta)
	return maxf(0.0, float(d.allowance) - float(d.active))


static func expired(meta: Dictionary) -> bool:
	return bool(state(meta).expired)


## One frame of active play of `delta` seconds: counted (at most max_step, never negative) and the events it crossed, in order:
## "warn:<seconds remaining>" for each threshold passed for the first time in this world, then "expired" once.
static func tick(meta: Dictionary, delta: float) -> Array:
	var d := state(meta)
	var out := []
	if bool(d.expired):
		return out
	var step := clampf(delta, 0.0, float(cfg().get("max_step", 0.25)))
	if is_nan(delta) or is_inf(delta):
		step = 0.0
	d.active = minf(float(d.allowance), float(d.active) + step)
	var left := float(d.allowance) - float(d.active)
	var marks: Array = (cfg().get("warn_at", [1800, 600, 300, 60]) as Array).map(func(x): return int(x))
	marks.sort()
	marks.reverse()
	for m in marks:
		if left <= float(m) and not (d.warned as Array).has(m):
			(d.warned as Array).append(m)
			out.append("warn:%d" % m)
	if left <= 0.0:
		d.expired = true
		out.append("expired")
	return out


## "1h 42m", "12m", "45s": what is left, for the timer and the warnings.
static func text(seconds: float) -> String:
	var s := maxi(0, int(ceil(seconds)))
	if s >= 3600:
		return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%dm" % ceili(float(s) / 60.0)
	return "%ds" % s


static func warning(mark: int) -> String:
	if mark >= 60:
		return "Demo: %d minute%s of play left in this world. Your world is saved and can be continued in the full game." % [mark / 60, "" if mark == 60 else "s"]
	return "Demo: less than a minute of play left in this world."


const CREATION_NOTE := "This is the demo of Forge My Life. Each world you start has 120 minutes of play: the clock runs only while you play, never while the game is paused or on a menu. You may start as many worlds as you like. A demo world saves as normal and can be continued, with nothing lost, in the full game."
const EXPIRED_NOTE := "This world's 120 minutes of demo play are used up. It has been saved, and it is kept: the full game of Forge My Life continues it exactly where you left off, with everyone and everything in it. You can start a new world in the demo at any time."
