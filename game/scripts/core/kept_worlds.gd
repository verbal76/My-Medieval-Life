class_name KeptWorlds
extends RefCounted
## B25-DEMO-KEPT-WORLDS (owner 2026-11-12, option A; DEMO-01 "Do not delete expired worlds", "Expired worlds must remain
## identifiable in world selection"): the demo's kept worlds, listed on the title screen. A kept world is a save file beside the
## game's own save, in the same folder:
##   save1.json                 the current world (Continue)
##   save1.previous.json        the world before it (kept when a new world was started)
##   save1.expired-<id>.json    a world whose demo time is used up, moved aside when a later new world needed the previous slot
##   save1.kept-<id>.json       a world with demo time left, moved aside the same way (the demo never removes one to make room)
## (<id> is the world's stable id, meta.save_id, a number added when that name is taken: two files never share a name.)
##
## This class only reads: a listed file is inspected (SaveStore.inspect) and its header read (the character, the village or
## homestead, the day, when it was last saved, its demo time); it is never written, renamed or removed here. Main moves files
## (Main.continue_kept_world, Main._keep_previous_game), always to a name no file has.

const EXPIRED := ".expired-"
const KEPT := ".kept-"


## Every kept world's file for the game's save at `save_path`: the current one, the previous one, then the expired and the kept
## ones (by name). Only files that exist.
static func files(save_path: String) -> Array:
	var out := []
	for p in [save_path, save_path.get_basename() + ".previous.json"]:
		if FileAccess.file_exists(p):
			out.append(p)
	var dir := save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		return out
	var stem := save_path.get_basename().get_file()
	var more := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json") and (f.begins_with(stem + EXPIRED) or f.begins_with(stem + KEPT)):
			more.append(dir.path_join(f))
	more.sort()
	return out + more


## What the list shows of one file: {path, file, role ("current", "previous", "expired", "kept"), ok, reason (when not ok),
## save_id, character, settlement, day, last_played (a date and time, or ""), saved_at, expired, remaining (demo seconds left),
## used (demo seconds used), demo (whether the world has a demo record)}.
static func info(path: String, save_path: String) -> Dictionary:
	var role := "kept"
	if path == save_path:
		role = "current"
	elif path == save_path.get_basename() + ".previous.json":
		role = "previous"
	elif path.get_file().contains(EXPIRED):
		role = "expired"
	var e := {"path": path, "file": path.get_file(), "role": role}
	var r := SaveStore.inspect(path, World.SAVE_VERSION)
	if r.state != "ok":
		e["ok"] = false
		e["reason"] = str(r.get("reason", r.state))
		return e
	var d: Dictionary = r.data
	var meta: Dictionary = (d.get("meta", {}) as Dictionary).duplicate(true)       # a copy: Demo.state fills it in, the file is not touched
	var p: Dictionary = d.get("player", {}) if d.get("player") is Dictionary else {}
	e["ok"] = true
	e["save_id"] = str(meta.get("save_id", ""))
	e["character"] = ("%s %s" % [str(p.get("name", meta.get("character", "?"))), str(p.get("family", ""))]).strip_edges()
	e["settlement"] = settlement(d)
	e["day"] = int(float(d.get("minutes", 0.0)) / 1440.0) + 1
	e["saved_at"] = int(meta.get("saved_at", 0))
	e["last_played"] = local_time(int(meta.saved_at)) if meta.has("saved_at") else ""
	e["demo"] = meta.get("demo") is Dictionary
	e["expired"] = Demo.expired(meta) if e.demo else false
	e["remaining"] = Demo.remaining(meta) if e.demo else 0.0
	e["used"] = float(Demo.state(meta).active) if e.demo else 0.0
	return e


## "2026-11-13 04:46": a save's time (Unix seconds, UTC) on this device's clock.
static func local_time(unix: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))          # minutes from UTC
	return Time.get_datetime_string_from_unix_time(unix + bias * 60, true).left(16)


## Every kept world of `save_path`, in the order of `files`.
static func list(save_path: String) -> Array:
	return files(save_path).map(func(p): return info(p, save_path))


## Where the character lives, from the save alone: a homestead the player claimed, else the home village (the game's village has
## one name in every world, game/data/civic.json village_name).
static func settlement(d: Dictionary) -> String:
	var hs = d.get("homesteads")
	if hs is Dictionary:
		for c in (hs.get("claims", []) as Array):
			if c is Dictionary and str(c.get("owner", "")) == World.PLAYER:
				return "a homestead in the open country"
	var village := str(CivicOffices.config().get("village_name", "the manor village"))
	return village.substr(0, 1).to_upper() + village.substr(1)


## The name a world is kept under when it is moved aside: "<save>.expired-<id>.json" or "<save>.kept-<id>.json", a number added
## while that name is taken, so a kept file is never written over.
static func kept_name(save_path: String, meta: Dictionary) -> String:
	var m := meta.duplicate(true)
	var spent := m.has("demo") and Demo.expired(m)
	var id := str(m.get("save_id", "")).validate_filename()
	var base := save_path.get_basename() + (EXPIRED if spent else KEPT) + (id if id != "" else "world")
	var to := base + ".json"
	var k := 2
	while FileAccess.file_exists(to):
		to = "%s-%d.json" % [base, k]
		k += 1
	return to


## A line for the list: "Ada Demo, The manor village, day 3. Last played 2026-11-13 01:20. Demo time used up."
static func describe(e: Dictionary) -> String:
	if not bool(e.get("ok", false)):
		return "%s: this file cannot be read (%s). It is kept as it is." % [str(e.file), str(e.get("reason", ""))]
	var s := "%s, %s, day %d." % [str(e.character), str(e.settlement), int(e.day)]
	s += (" Last played %s." % str(e.last_played)) if str(e.last_played) != "" else ""
	if bool(e.expired):
		s += " Demo time used up: continue it in the full game."
	elif bool(e.demo):
		s += " Demo time left: %s." % Demo.text(float(e.remaining))
	return s
