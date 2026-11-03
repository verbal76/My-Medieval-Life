extends SceneTree
## B25R1-016 section 12: the targeted-scenario harness for rare living-world features (game/data/flight_scenarios.json). Each
## scenario is a fresh world of its seed with the flight recorder on; its documented start is applied through the systems' own
## scenario entry points (LifeDecisions.set_hardship / weigh_runaway / recruit / leave_band, Homesteads.begin / set_faction, and
## World.kill for an orphaning), which set a record or run a decision exactly as the dawn would: no rule, weight or probability is
## changed. Then the normal game runs for the scenario's days. The result is what the recorder saw against what the scenario
## expects; a step whose system is absent is "not run", never faked. Results are TARGETED evidence: tools/flight_lives.py
## --targeted DIR reports them apart from the organic campaign (a scenario proves a mechanic can work, not how often it happens).
##   godot --headless --path game --script res://tests/flight_scenarios.gd -- --out DIR [--only NAME]
## Writes DIR/targeted.json and DIR/<scenario>/ (each scenario's archive). Exit 1 only on a script-level failure (a scenario
## whose expected events did not appear is reported, not failed: that is the evidence).

const POSTS := ["reeve", "sage", "guard", "priest"]
var out_dir := ""
var picked := {}            # role -> NPC chosen by an earlier step of the same scenario


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var only := ""
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			out_dir = args[i + 1]
		elif args[i] == "--only" and i + 1 < args.size():
			only = args[i + 1]
	if out_dir == "":
		printerr("flight_scenarios: --out DIR")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/flight_scenarios.json"))
	var results := []
	for sc in defs.scenarios:
		if only != "" and str(sc.name) != only:
			continue
		results.append(run(sc))
		print("SCENARIO %s: %s" % [sc.name, results[-1].result])
	var f := FileAccess.open(out_dir + "/targeted.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"format": "mml-flight-targeted/1", "commit": OS.get_environment("MML_COMMIT"), "label": "targeted (not organic)",
		"scenarios": results}, " ", false))
	f.close()
	quit(0)


func run(sc: Dictionary) -> Dictionary:
	picked = {}
	var w := World.new()
	w.setup(VillageMap.load_default(), int(sc.seed))
	var dir := out_dir + "/" + str(sc.name)
	DirAccess.make_dir_recursive_absolute(dir)
	var rec := WorldRecorder.attach(w, {"root": dir})
	rec.meta["scenario"] = "targeted:" + str(sc.name)
	_minutes(w, 61)
	var steps_log := []
	var not_run := ""
	for st in sc.steps:
		var r := step(w, st)
		steps_log.append({"op": str(st.op), "result": r})
		if r.begins_with("not run"):
			not_run = r
			break
	if not_run == "":
		_minutes(w, int(sc.days) * 1440)
	rec.finish()
	var seen := {}
	for e in RecorderArchive.read_table(FlightRecorder._abs(rec.dir), "event"):
		seen[str(e.subtype)] = int(seen.get(str(e.subtype), 0)) + 1
	var missing := []
	for want in sc.expect:
		var any := false
		for k in str(want).split("|"):
			any = any or seen.has(k)
		if not any:
			missing.append(str(want))
	var interesting := {}
	for k in seen:
		if (FlightRecorder.default_codes().get("chronicle", {}) as Dictionary).has(k) or str(k).begins_with("guardianship"):
			interesting[k] = seen[k]
	w.dispose()
	var result := not_run if not_run != "" else ("observed" if missing.is_empty() else "not observed: " + ", ".join(missing))
	return {"name": sc.name, "cases": sc.cases, "seed": sc.seed, "days": sc.days, "start": sc.start, "steps": steps_log, "result": result,
		"observed": interesting, "missing": missing, "archive": FlightRecorder._abs(rec.dir), "people": picked.keys().map(func(k): return "%s=p:%d" % [k, picked[k].id])}


func _minutes(w: World, minutes: int) -> void:
	for i in minutes:
		w.update(0.5)
		w.player.hunger = 100.0


# ---------------------------------------------------------------- people, chosen deterministically (lowest household, then id)
func pick(w: World, who: String) -> NPC:
	if picked.has(who):
		return picked[who]
	var c: NPC = null
	var pool := w.npcs.filter(func(n: NPC) -> bool: return n.alive and n.household >= 0 and not (n.job in POSTS))
	pool.sort_custom(func(a: NPC, b: NPC) -> bool: return a.household < b.household or (a.household == b.household and a.id < b.id))
	for n: NPC in pool:
		var age := Life.npc_age(w, n)
		match who:
			"young_adult":
				if n.role == "adult" and n.partner < 0 and age < 25.0:
					c = n
			"established_adult":
				if n.role == "adult" and n.partner >= 0 and age >= 25.0:
					c = n
			"youth":
				if age >= 12.0 and age < 16.0:
					c = n
			"adult":
				if n.role == "adult" and n.partner < 0:
					c = n
			"child":
				if age < 12.0 and w.npc(n.mother) != null and w.npc(n.mother).alive and w.npc(n.father) != null and w.npc(n.father).alive:
					c = n
		if c != null:
			break
	if who == "bandit":
		for n: NPC in w.npcs:
			if n.alive and n.role == "bandit":
				c = n
				break
	if who == "orphan_if_unplaced" and picked.has("child"):
		var k: NPC = picked["child"]
		c = k if k.alive and k.clan == "" and k.household < 0 else null
	if c != null:
		picked[who] = c
	return c


func step(w: World, st: Dictionary) -> String:
	var hs = w.get("homesteads") if "homesteads" in w else null
	var ld = w.get("life") if "life" in w else null
	var op := str(st.op)
	if op == "run":
		_minutes(w, int(st.days) * 1440)
		return "ran %d days" % int(st.days)
	if op in ["hardship", "weigh_runaway", "recruit", "leave_band"] and (ld == null or not ld.has_method("set_hardship")):
		return "not run: LifeDecisions (B25R1-014) is not in this build"
	if op in ["homestead_begin", "faction"] and (hs == null or not hs.has_method("begin")):
		return "not run: Homesteads (B25R1-010) is not in this build"
	var who := str(st.get("who", ""))
	var n := pick(w, who) if who != "" else null
	match op:
		"homestead_begin":
			if n == null:
				return "no %s in this village" % who
			var leaving := [n]
			if n.partner >= 0 and w.npc(n.partner) != null and w.npc(n.partner).alive:
				leaving.append(w.npc(n.partner))
			return "set out: %s" % str(hs.begin(n.household, n, leaving, str(st.path)))
		"faction":
			var cl: Array = hs.claims
			if cl.is_empty():
				return "no claim to turn"
			return "faction: %s" % str(hs.set_faction(cl[-1], str(st.faction), bool(st.get("concealed", false)), "targeted scenario"))
		"hardship":
			if n == null:
				return "no %s in this village" % who
			ld.set_hardship(n.household, int(st.bad), w.day() if bool(st.get("event", false)) else -999)
			return "hardship on hh:%d for p:%d" % [n.household, n.id]
		"weigh_runaway":
			return "no %s" % who if n == null else "weighed: %s" % str(ld.weigh_runaway(n))
		"recruit":
			return "no %s" % who if n == null else "answer: %s" % str(ld.recruit(n))
		"leave_band":
			return "no bandit alive" if n == null else "left: %s" % str(ld.leave_band(n))
		"orphan":
			if n == null:
				return "no child with both parents alive"
			for pid in [n.mother, n.father]:
				var p := w.npc(pid)
				if p != null and p.alive:
					w.kill(p, "scenario")
			return "orphaned p:%d" % n.id
	return "unknown op " + op
