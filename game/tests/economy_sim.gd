extends SceneTree
## Long-run economy simulation with no player activity: builds the village for a seed, steps the
## real World for N game days and samples, every D days and at the end, people, food, work and
## money, materials, wildlife, building, trade and the currency, then checks the flow accounts:
## currency (end = start + caravan coins in + newcomers' purses - caravan coins out), each item (start + produced +
## imported - consumed - exported = end), each deposit (start - mined = end) and each animal kind
## (start + born - killed - starved = end). Any difference is printed as a leak, never hidden.
## Diagnostics only: the only thing it changes in the world is the player's hunger, kept full so
## the inert player (left where it starts, as in households_sim) never starves.
##   godot --headless --path game --script res://tests/economy_sim.gd -- --days 30 [--seed 1] [--every 1] [--out path.json]
##       [--watch-from DAY]   (B7-015: hourly lines for households near starving, and each death, from DAY)
##       [--set key=value]...   (override a top-level balance.json number for a comparison run, e.g. --set manor_job_reserve_days=10)
##       [--record DIR]   (REC-19: the flight recorder writes its archive under DIR; changes nothing in the run)
##       [--scenario crime_spree --at DAY]   (SIM-GATE-01: the player commits scripted crimes from DAY: a theft, a pocket picked,
##       a killing in sight of the village and a flight along a path, an assault, another killing; the village's own
##       witnesses, reports and guards respond; GP-CRIME-PURSUIT A3: a beaten player yields to a guard of the case
##       an hour after the second killing (day 2 15:00), if still alive and the case still open; tools/sim_suite.py)
##       [--judgment]   (attach a fresh judgment store; Build 19 ships judgment on already; prints its counts at the end)
##       [--economy]   (Expansion 20 LE-01: the economy model on, observing only; prints its record counts at the end)
##       [--market]    (Expansion 20 LE-03: the shipped economy.json switched on, the market driving; audits the claims at the end)
##       [--scenario strip_mine|contracts_fail|social_chain --at DAY]   (X20-FINAL phase 4, tools/sim_suite.py: economic stress
##       and the judgment chain through the game's own verbs; see _intervene and _scripted_step)
##       [--aspiration] [--job-choice]   (Expansion 20 R5, WDR-011-C: the NPC aspiration layer on, and its own job_choice flag;
##       both shipped off; a measurement run, never the gate's; prints the aspiration rows' leads at the end)
##       [--no-judgment]   (the Build 18 path: judgment off, as tools/sim_gate.py --sim-args=--no-judgment compares with the baseline)
##       [--capability L --cap-profile P] [--cap-scenario S] [--cap-industries a,b] [--cap-report] [--cap-at 30,60]   (Expansion 18 X18-SIM,
##       analysis only: tests/capability_metrics.gd)
## Steps of 0.5 s (one game minute), as households_sim, econ_report and earn_sim do; the abstract tier
## of World.update runs a distant NPC once per 0.5 s, so a larger step would change the rules applied.
## Exit code 1 if the currency or any item does not balance. SIM-01 (owner, 2026-10-21): run the longest duration once and
## read days 30, 90, 100 from its checkpoints (--every); a ledger broken at a checkpoint stops the run there (FATAL line).

const STEP := 0.5
const MATERIALS := ["iron_ore", "copper_ore", "gold_ore", "coal", "stone", "building_block", "log", "plank", "iron_bar", "copper_bar",
	"wheat", "meat", "hide", "leather", "pottage", "roast_meat", "ale", "pickaxe", "axe", "hammer"]
const Census := preload("res://tests/census.gd")
const CapMetrics := preload("res://tests/capability_metrics.gd")     # X18-SIM (Expansion 18): analysis switch, off unless asked
const MARKET_ROLES := Census.MARKET_ROLES

var w: World
var deaths := {}               # cause -> count (villagers)
var deaths_by_job := {}        # job or role -> count
var bandit_deaths := 0
var death_log: Array = []      # [day, name, job, cause]
var first_starvation_day := -1
var pending_cause := ""
var events := {"sites_started": 0, "sites_finished": 0, "sites_given_up": 0, "seams_worked_out": 0,
	"no_firewood_nights": 0, "caravans": 0, "tools_broke": 0}
var exhausted_day := {}        # deposit index -> day it reached 0
var starving_hours := 0        # villager-hours at zero hunger
var min_hunger := 100.0        # lowest villager hunger since the last sample
var player_min_hp := 0.0
var player_attacked := 0       # hours in which the player's health fell
var flows := {}                # "buyer_role>seller_role" -> {n, coins, items}: every sale (World.trade_hook)
var scenario := ""             # EQ-06 intervention scenario (see _intervene); "" = the player stays inactive
var scenario_day := 20
var scenario_log := {}
var watch_from := -1           # B7-015, FSE-16: from this day, log every hour the households with someone near starving
var watch_alive := {}          # npc id -> alive, for --watch-from's death lines
var watch_lost := {}           # households that lost someone to hunger while watched
var herd_log: Array = []       # FARM-08B: each pen kind's herd, a row on every day it changed (read only, changes nothing)
var herd_last := {}            # kind -> the last row's key, to keep only the days that changed
var herd_care := {}            # kind -> hours a pen had a hungry animal and too little in the trough, and why it was not fed
var flee_path := PackedVector2Array()   # SIM-GATE-01 crime_spree: the player's flight after a crime, cell by cell
const FLEE_TILES_PER_SECOND := 4.5      # the player's walking speed (docs: guards chase at 1.3 x walk_tiles_per_second)


var econ_roundtrip_bad := 0      # LE-06: checkpoints whose economy section did not load back exactly

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var arg := func(name: String, fallback: String) -> String:
		return args[args.find(name) + 1] if name in args and args.find(name) + 1 < args.size() else fallback
	var days := int(arg.call("--days", "30"))
	var seed := int(arg.call("--seed", "1"))
	var every := maxi(1, int(arg.call("--every", "1")))
	var out := str(arg.call("--out", ""))
	scenario = str(arg.call("--scenario", ""))   # EQ-06, EQ-05: a player intervention on day --at (default 20)
	scenario_day = int(arg.call("--at", "20"))
	watch_from = int(arg.call("--watch-from", "-1"))
	GameData.ensure()
	for i in args.size():                 # comparison runs: --set key=value overrides a balance number
		if args[i] == "--set" and i + 1 < args.size() and "=" in args[i + 1]:
			var kv: PackedStringArray = args[i + 1].split("=", true, 1)
			GameData.balance[kv[0]] = float(kv[1])
			print("balance override: %s = %s" % [kv[0], kv[1]])
	var cap_on := CapMetrics.wanted(args)          # X18-SIM: --capability L --cap-profile P --cap-scenario S (analysis only)
	var cap_info := CapMetrics.pre_setup(args) if cap_on else {}
	var t0 := Time.get_ticks_msec()
	JudgmentLive.test_disabled = "--no-judgment" in args
	if "--aspiration" in args or "--job-choice" in args:   # R5: set before the world (and its judgment store) is made
		var ov := {"enabled": "--aspiration" in args}
		if "--job-choice" in args:
			ov.job_choice = true
		JudgmentAspiration.override = ov
		print("aspiration: %s" % JSON.stringify(ov))
	if "--market" in args:                # EXPANSION 20 LE-03: the shipped economy.json switched on: the LE-02/LE-03 market drives
		var ecfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
		ecfg.enabled = true
		EconomyFoundation.set_override(ecfg)
		print("economy: enabled with the shipped settings (market drive %s)" % str(ecfg.get("market", {}).get("drive", false)))
	elif "--economy" in args:             # EXPANSION 20 LE-01: the economy model attached, observing only (never shipped on)
		EconomyFoundation.set_override({"enabled": true})
		print("economy: LE-01 model enabled (observing)")
	w = World.new()
	w.setup(VillageMap.load_default(), seed)
	var parts := [w.brain, w.property, w.business, w.construction, w.fauna, w.farm, w.quests, w.manor_work, w.carts, w.relations]
	if parts.has(null):                   # a game script failed to compile: stop with an error rather than run on broken
		printerr("economy_sim: the world did not set up (a script failed to load); see the errors above")
		quit(2)
		return
	if "--judgment" in args:              # PROSPECTIVE (PROS-19): a run with the judgment prototype attached
		JudgmentLive.attach(w)
		print("judgment: attached (prototype)")
	if "--record" in args:                # REC-19: the flight recorder writes its archive under DIR (off by default; the run is otherwise identical)
		WorldRecorder.attach(w, {"root": str(arg.call("--record", ""))})
		print("recorder: recording to ", w.recorder.dir)
	w.event.connect(_on_event)
	w.brain.track_misses = true
	w.trade_hook = _on_trade
	w.npc_died.connect(_on_died)
	player_min_hp = w.player.hp
	if cap_on:
		CapMetrics.post_setup(cap_info, w)
	var cap0 := CapMetrics.snapshot(w) if cap_on else {}
	var cap_at: PackedStringArray = str(arg.call("--cap-at", "")).split(",")
	var start := {"stats": w.stats.duplicate(), "goods": _all_goods(), "coins": _coins(), "coin_sources": w.coin_sources, "regions_coins": w.regions.coins(), "regions_goods": w.regions.goods(),
		"deposits": w.deposits.map(func(d): return int(d.amount)), "hosts": _hosts(), "boulders": _boulder_stone(), "pits": w.pits.ground_left(), "cut": w.mine_works.ground_cut(), "fill_out": w.mine_works.fill_out, "fill_in": w.mine_works.fill_in(), "animals": _animal_counts(), "alive": _villagers().size(),
		"households": w.households.size(), "npcs": w.npcs.size()}
	var samples: Array = [_sample(start)]
	_herd_day(0)
	_print_sample(samples[0])
	var per_day := int(1440.0 / float(GameData.b("game_minutes_per_second")) / STEP)
	var hp_before := w.player.hp
	var profile := "--profile" in args          # PERF-02: time per subsystem, printed at the end (changes nothing)
	w.profiling = profile
	w.map.profiling = profile
	var update_us := 0
	var harness_us := 0
	var reached := days               # the day the run got to: `days`, or the checkpoint where a ledger broke
	for d in days:
		if scenario != "" and d == scenario_day:
			_intervene(scenario)
		for i in per_day:
			if scenario == "crime_spree" and i % 60 == 0 and w.day() >= scenario_day:
				_crime_step(w.day() - scenario_day, int(fmod(w.minutes, World.DAY) / 60.0))
			elif (scenario == "social_chain" or scenario == "contracts_fail") and i % 60 == 0 and w.day() >= scenario_day:
				_scripted_step(w.day() - scenario_day, int(fmod(w.minutes, World.DAY) / 60.0))
			var tu := Time.get_ticks_usec()
			w.update(STEP)
			update_us += Time.get_ticks_usec() - tu
			w.player.hunger = 100.0            # the inert player is fed; it is not part of what is measured
			if not flee_path.is_empty():
				_flee_step()
			if i % 60 == 59:
				var th := Time.get_ticks_usec()
				_hourly()
				if watch_from >= 0 and d >= watch_from:
					_watch(d, i / 60)
				harness_us += Time.get_ticks_usec() - th
				if w.player.hp < hp_before:
					player_attacked += 1
				hp_before = w.player.hp
				player_min_hp = minf(player_min_hp, w.player.hp)
		_herd_day(d + 1)
		if (d + 1) % every == 0 or d + 1 == days:
			var ts := Time.get_ticks_usec()
			samples.append(_sample(start))
			_print_sample(samples[-1])
			min_hunger = 100.0
			harness_us += Time.get_ticks_usec() - ts
			if w.economy != null:                  # LE-06: the economy's save at each checkpoint, and whether it loads back exactly
				var ts2 := Time.get_ticks_usec()
				var ed: Dictionary = w.economy.to_dict()
				var es := JSON.stringify(ed)
				var back := EconomyFoundation.attach(w, JSON.parse_string(es))
				var exact := back != null and JSON.stringify(back.to_dict()) == es
				if not exact:
					econ_roundtrip_bad += 1
				print("ECONOMY day %d: save bytes %d (knowledge %d entries, %d bytes; forgotten %d); round trip exact %s; claims breaches %d; save+load %d ms" % [d + 1, es.length(),
					w.economy.knowledge.size(), JSON.stringify(ed.get("knowledge", {})).length(), w.economy.knowledge.unusable_forgotten, str(exact),
					w.economy.claims.audit().filter(func(x): return str(x.kind) != "unbacked").size(), (Time.get_ticks_usec() - ts2) / 1000])
			if cap_on and str(d + 1) in cap_at:      # X18-SIM: a milestone read from this one run (SIM-01), read only
				print("CAPABILITY@%d %s" % [d + 1, JSON.stringify(CapMetrics.report(cap_info, w, cap0, d + 1))])
			# SIM-01 (owner, 2026-10-21): one long run, checked at every checkpoint; a broken ledger stops it there, with
			# the day and the state, instead of after the remaining days. A village failing (hunger, decline) never stops it.
			var bad: Dictionary = samples[-1]
			if str(bad.regions.audit) != "" or int(bad.regions.coins_mismatch) != 0 or int(bad.regions.goods_mismatch) != 0 or int(bad.regions.people_mismatch) != 0:
				reached = d + 1
				print("FATAL day %d seed %d: the neighbouring settlements' books: %s (coins mismatch %d, goods mismatch %d, people mismatch %d)" % [reached, seed,
					str(bad.regions.audit), int(bad.regions.coins_mismatch), int(bad.regions.goods_mismatch), int(bad.regions.people_mismatch)])
				break
			if int(bad.currency.leak) != 0 or not (bad.ledger.items as Dictionary).is_empty():
				reached = d + 1
				print("FATAL day %d seed %d: currency leak %d; items %s; deposits %s; animals %s" % [reached, seed, int(bad.currency.leak),
					JSON.stringify(bad.ledger.items), JSON.stringify(bad.ledger.deposits), JSON.stringify(bad.ledger.animals)])
				break
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	if profile:
		_print_profile(update_us, harness_us, secs, days)
	if watch_from >= 0:
		for e in w.brain.miss_log:
			if watch_lost.has(int(e[5])) and int(e[0]) >= watch_from - 2:
				print("WATCH MISS ", str(e))
	var final: Dictionary = samples[-1]
	_print_final(final, start, seed, reached, secs)
	if w.judgment != null:
		print("judgment: %s; stats %s" % [JSON.stringify(w.judgment.counts()), JSON.stringify(w.judgment.stats)])
		print("judgment time (us): %s" % JSON.stringify(w.judgment.timing))
		print("judgment state hash: %d" % w.judgment.state_hash())       # byte-level comparison of every ledger, memory and fact
		if w.judgment.asp.enabled:
			var leads := {}
			var surv := 0
			for p in w.judgment.asp.rows:
				var l: String = w.judgment.asp.lead_of(int(p))
				leads[l if l != "" else "content"] = int(leads.get(l if l != "" else "content", 0)) + 1
				surv += 1 if int(w.judgment.asp.rows[p].surv) > 0 else 0
			print("aspiration: %d adults; leads %s; under survival pressure %d" % [w.judgment.asp.rows.size(), JSON.stringify(leads), surv])
			# which part puts each adult under pressure now (the highest of hunger, injury, danger), and how each danger memory was learnt
			var by := {"none": 0, "hunger": 0, "injury": 0, "danger": 0}
			var src := {}
			var vh := "violence".hash()
			for p in w.judgment.asp.rows:
				var n: NPC = w.npc(int(p))
				if n == null:
					continue
				var sparts: Dictionary = w.judgment.asp.survival_parts(n, w)
				var top := "none"
				var best := 0
				for k in ["hunger", "injury", "danger"]:
					if int(sparts[k]) > best:
						best = int(sparts[k])
						top = k
				by[top] += 1
				for ev in w.judgment.memories.get(n.id, {}):
					var m: PackedInt64Array = w.judgment.memories[n.id][ev]
					var t := int(m[JudgmentStore.M_TYPE])
					if w.judgment._pol[t] == -1 and w.judgment._famh[t] == vh and int(m[JudgmentStore.M_DAY]) >= w.day() - int(w.judgment.asp.c.get("danger_days", 8)):
						var sk: String = JudgmentStore.SOURCES[int(m[JudgmentStore.M_SRC])]
						src[sk] = int(src.get(sk, 0)) + 1
			print("aspiration survival now, by highest part: %s; recent violence memories by source: %s; saved level above 0: %d" % [JSON.stringify(by), JSON.stringify(src), surv])
	if cap_on:
		print("CAPABILITY " + JSON.stringify(CapMetrics.report(cap_info, w, cap0, reached)))
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify({"format": "economy-sim/1", "seed": seed, "days": days, "reached": reached, "every": every, "step": STEP,
			"seconds": secs, "start": _jsonable(start), "samples": samples, "deaths": death_log,
			"fingerprint": _fingerprint(), "misses": _miss_summary(), "flows": flows, "herd": herd_log, "herd_care": herd_care}, " ", false))
		f.close()
	var ok: bool = int(final.currency.leak) == 0 and (final.ledger.items as Dictionary).is_empty() and econ_roundtrip_bad == 0
	if w.economy != null:                 # EXPANSION 20 LE-01: what the model recorded (diagnostics; it decides nothing)
		var ec: EconomyFoundation = w.economy
		print("economy: events %d (ordered %s), knowledge %d, needs recorded %d (dirty %d), offers %d, reservations %d, unbacked %d, links %d" % [ec.events.size(),
			str(ec.events.ordered()), ec.knowledge.size(), ec.needs.recorded().size(), ec.needs.dirty.size(), ec.offers.records.size(), ec.reservations.records.size(),
			ec.reservations.unbacked().size(), ec.contract_links.links.size()])
		print("economy save bytes: %d" % JSON.stringify(ec.to_dict()).length())
		print("economy market: %s; deals %d" % [JSON.stringify(ec.market.stats), ec.market.deals.size()])
		print("economy claims: %s" % JSON.stringify(ec.claims.stats))
		var breaches: Array = ec.claims.audit().filter(func(x): return str(x.kind) != "unbacked")     # LE-03: integrity, not outcome
		print("economy audit: %d breaches %s; unbacked earmarks %d" % [breaches.size(), JSON.stringify(breaches.slice(0, 10)), ec.reservations.unbacked().size()])
		if not breaches.is_empty():
			ok = false
		var tc := 0                       # LE-01 till ownership: every till resolves to a controller and they add up to Business.tills
		var held := 0
		var lost: Array = []
		for t in ec.actors.till_refs():
			tc += ec.actors.coins(t)
			if ec.actors.coins(t) > 0:
				held += 1
				if ec.actors.controller(t) == "":
					lost.append(t)
		print("economy tills: %d refs, %d holding coins, coins %d (Business.tills %d), without a controller %s" % [ec.actors.till_refs().size(),
			held, tc, w.business.tills(), str(lost)])
	var rec = w.recorder
	w.dispose()
	if rec != null:
		print("recorder: %s; rows %s; chunks %d; %d bytes; peak buffer %d; early flushes %d" % [rec.completeness(), JSON.stringify(rec.counts), rec.chunks, rec.bytes, rec.peak_buffer, rec.early_flushes])
	quit(0 if ok else 1)


## PERF-02: where the time went. World.update's subsystems (World.prof), path searches (VillageMap), and
## the harness's own hourly checks and samples; shares are of the whole run's wall-clock.
func _print_profile(update_us: int, harness_us: int, secs: float, days: int) -> void:
	var total := secs * 1000000.0
	var alive := _villagers().size()
	print("PROFILE: %.1f s for %d days (%.2f s a day); %d villagers alive, %d animals alive at the end" % [secs, days, secs / days, alive,
		w.fauna.animals.filter(func(a): return a.alive).size()])
	var rows := []
	for k in w.prof:
		rows.append([k, int(w.prof[k].us), int(w.prof[k].n)])
	rows.append(["path searches (inside villagers)", w.map.path_us, w.map.path_calls])
	rows.append(["World.update (all)", update_us, 0])
	rows.append(["harness: hourly checks and samples", harness_us, 0])
	rows.sort_custom(func(a, b): return a[1] > b[1])
	for r in rows:
		print("  %-46s %8.1f s %5.1f%%  %s" % [r[0], r[1] / 1000000.0, 100.0 * r[1] / total, ("%d calls, %.0f us each" % [r[2], float(r[1]) / r[2]]) if r[2] > 0 else ""])


# ---------------------------------------------------------------- listeners ------------------
func _on_event(t: String) -> void:
	var at := t.find("has died (")
	if at >= 0:
		pending_cause = t.substr(at + 10, t.rfind(")") - at - 10)
	if " marks out " in t:
		events.sites_started += 1
	elif t.ends_with(" is finished."):
		events.sites_finished += 1
	elif "was given up" in t:
		events.sites_given_up += 1
	elif "seam at the mine is worked out" in t:
		events.seams_worked_out += 1
	elif "had no firewood last night" in t:
		events.no_firewood_nights += int(t.substr(t.find("] ") + 2).split(" ")[0])
	elif "merchant caravan passes through" in t or ("Traders from" in t and "pass through" in t):
		events.caravans += 1
	elif t.ends_with(" broke."):
		events.tools_broke += 1


## --watch-from (B7-015, FSE-16): each game hour, every household with a member under 25 hunger: its pantry, members
## (job, hunger, health, coins, food carried, what they are doing), its food days and relief standing, and the market;
## and each death as it happens. Diagnostics only: the world's hourly caches are restored after reading, so watching
## leaves the run exactly as it would be without it.
func _watch(d: int, hr: int) -> void:
	var pc: Dictionary = w._price_cache.duplicate()
	var rc: Dictionary = w._reserve_cache.duplicate()
	for n: NPC in w.npcs:
		if watch_alive.get(n.id, true) and not n.alive and n.role != "bandit":
			print("WATCH DEATH d%d h%d %s %s id=%d job=%s role=%s hh=%d hunger=%.0f starved=%s" % [w.day(), int(w.hour()), n.name, n.family, n.id, n.job, n.role, n.household, n.hunger, str(n.hunger <= 0.0)])
			if n.hunger <= 0.0:
				watch_lost[n.household] = true
		watch_alive[n.id] = n.alive
	for h in w.households.size():
		var mem: Array = w.brain._members(h)
		var low := false
		for m: NPC in mem:
			low = low or m.hunger < 25.0
		if not low:
			continue
		var hh: Dictionary = w.households[h]
		var ms := []
		for m: NPC in mem:
			var carry := {}
			for id in m.inv.items:
				if id in NPCBrain.FOOD or id in ["meat", "log", "wheat_seed", "egg", "milk", "carrot", "potato"]:
					carry[id] = m.inv.items[id]
			ms.append("%s(%s,%s,hu%.0f,hp%.0f,c%d,%s,'%s')" % [m.name, m.job if m.job != "" else m.role, "sleep" if w.asleep(m) else "up", m.hunger, m.hp, m.coins, str(carry), m.doing])
		var fd: float = w.brain.household_food_days(h)
		print("WATCH HH d%d h%d hh%d %s pantry=%s fd=%.2f trig=%s pend=%d relief_days=%s unit=%s granary=%d treas=%d mkt=%.0f | %s" % [w.day(), int(w.hour()), h, str(hh.get("family", "")),
			str((hh.pantry as Inventory).items), fd, str(fd < float(GameData.b("relief_trigger_days"))), w.manor_work.pending_for(h), str(hh.get("relief_days", [])),
			str(w.cheapest_food_unit()), w.granary.count("wheat"), w.treasury, w.brain.market_food_points, " ".join(ms)])
	var clock := int(w.hour())                 # the game's clock hour (the loop's day starts at the world's start hour)
	if clock == 16 or clock == 17:
		_watch_relief(w.day(), clock)
	w._price_cache = pc
	w._reserve_cache = rc


var watch_relief_before := {}      # hh -> relief_days size at 16:00, to see whom the 17:00 relief helped


## --watch-from: the manor's evening relief (World runs reeve_day at 17:00). At 16:00: the households under the relief
## trigger, the granary, the treasury, and every seller relief could buy from (wheat surplus or pottage); at 17:00: the
## households it helped, in order, and what it spent.
func _watch_relief(d: int, hr: int) -> void:
	if hr == 16:
		var qual := []
		for h in w.households.size():
			watch_relief_before[h] = (w.households[h].get("relief_days", []) as Array).size()
			if not w.brain._members(h).is_empty():
				var fd: float = w.brain.household_food_days(h)
				if fd < float(GameData.b("relief_trigger_days")):
					qual.append("hh%d:%.2f" % [h, fd])
		var sellers := []
		for o: NPC in w.npcs:
			if o.alive and (o.job == "farmer" or w.brain.buy_role(o) == "merchant_food") and w.brain.surplus_wheat(o) > 0:
				sellers.append("%s(%s) wheat+%d" % [o.name, o.job, w.brain.surplus_wheat(o)])
			elif o.alive and (o.job == "tavernkeeper" or w.brain.buy_role(o) == "merchant_food") and o.inv.has("pottage"):
				sellers.append("%s(%s) pottage %d" % [o.name, o.job, o.inv.count("pottage")])
		print("WATCH RELIEF-PRE d%d qualifying=%s granary=%d treasury=%d obligations=%.0f sellers=%s" % [d, " ".join(qual), w.granary.count("wheat"),
			w.treasury, w.brain.daily_obligations(), str(sellers)])
		watch_relief_spent = float(w.stats.get("gov_relief_bought", 0.0))
		watch_relief_grain = float(w.stats.get("gov_relief_grain", 0.0))
	else:
		var helped := []
		for h in w.households.size():
			if (w.households[h].get("relief_days", []) as Array).size() > int(watch_relief_before.get(h, 0)) or \
					(not (w.households[h].get("relief_days", []) as Array).is_empty() and int((w.households[h].relief_days as Array)[-1]) == w.day()):
				helped.append("hh%d" % h)
		print("WATCH RELIEF-POST d%d helped=%s bought=%.0f grain=%.0f" % [d, " ".join(helped), float(w.stats.get("gov_relief_bought", 0.0)) - watch_relief_spent,
			float(w.stats.get("gov_relief_grain", 0.0)) - watch_relief_grain])


var watch_relief_spent := 0.0
var watch_relief_grain := 0.0


func _on_died(n: NPC) -> void:
	var cause := pending_cause.split(" by ")[0] if pending_cause.begins_with("slain") else pending_cause
	pending_cause = ""
	if n.role == "bandit":
		bandit_deaths += 1
		return
	deaths[cause] = int(deaths.get(cause, 0)) + 1
	var job: String = n.job if n.job != "" else n.role
	deaths_by_job[job] = int(deaths_by_job.get(job, 0)) + 1
	death_log.append([w.day() + 1, "%s %s" % [n.name, n.family], job, cause])
	if cause == "starvation" and first_starvation_day < 0:
		first_starvation_day = w.day() + 1


## EQ-06 / EQ-05 intervention scenarios: the player acts once, on day `scenario_day`, through the same calls the game
## uses, and the run shows what the world does with it. Coins the player brings from outside are counted as coming
## into the village (World.coin_sources), so the ledger still balances. The crime consequences of a killing (guards,
## regard) live in main.gd and do not run headless (DVW-A12).
##   kill_smiths  the player kills every smith (World.kill, as a sword blow does)
##   corner_wheat a rich player (3000 coins from outside) buys every sack of wheat on sale (World.player_buy_many)
##   gift_coins   a rich player (2000 coins from outside) gives 100 coins each to the poorest households' providers
##   hunt_out     the player kills every wild deer and boar (Fauna.kill, as a hunt does); the game is left as loot
## X20-FINAL phase 4 (economic stress, legitimate world changes only; nothing is created):
##   strip_mine   the player works every surface seam of iron ore, copper ore and coal out (World.work_mine: the ledger's
##                mined_ count, no tool worn) and carries the ore out of the valley (the ledger's exported_ count); the
##                village's smiths, miners and manor then meet depleted seams
##   contracts_fail  see _scripted_step (the player's orders, accepted on the villagers' own terms, then partly cancelled)
func _intervene(name: String) -> void:
	var p := w.player
	match name:
		"kill_smiths":
			for n: NPC in w.npcs.duplicate():
				if n.alive and n.job == "smith":
					w.kill(n, "slain by %s %s" % [p.name, p.family])
					scenario_log.killed = int(scenario_log.get("killed", 0)) + 1
		"corner_wheat":
			p.coins += 3000
			w.coin_sources += 3000
			w.stat("scenario_coins_in", 3000)       # counted as coins from outside in the ledger
			for n: NPC in w.npcs:
				if not n.alive or not (n.job == "farmer" or w.brain.buy_role(n) == "merchant_food"):
					continue
				var q := n.inv.count("wheat")
				while q > 0:
					var r := w.player_buy_many(n, "wheat", mini(q, 10))
					if str(r.result) != "bought":
						break
					q -= int(r.bought)
					scenario_log.wheat = int(scenario_log.get("wheat", 0)) + int(r.bought)
		"gift_coins":
			p.coins += 2000
			w.coin_sources += 2000
			w.stat("scenario_coins_in", 2000)       # counted as coins from outside in the ledger
			var poor := []
			for hh in w.households:
				if hh.get("ended", false):
					continue
				var ra := w.construction.responsible_adult(int(hh.id))
				if ra != null:
					poor.append([w.property.purse(World.hh_ref(int(hh.id))), int(hh.id), ra])
			poor.sort()
			for row in poor.slice(0, 10):
				var ra: NPC = row[2]
				p.coins -= 100
				ra.coins += 100
				scenario_log.given = int(scenario_log.get("given", 0)) + 100
		"strip_mine":
			var bag := Inventory.new()
			for dep in w.deposits:
				if int(dep.get("level", 0)) != 0 or not (str(dep.get("ore", "")) in ["iron_ore", "copper_ore", "coal"]):
					continue
				for k in 4000:
					if str(w.work_mine(p, dep, bag, "").result) != "ok":
						break
				scenario_log.seams = int(scenario_log.get("seams", 0)) + 1
			for id in bag.items.keys():
				var q := bag.count(id)
				if q > 0:
					bag.remove(id, q)
					w.stat("exported_" + str(id), float(q))      # carried out of the valley: counted as exported in the ledger
					scenario_log["exported_" + str(id)] = q
		"hunt_out":
			for a: Animal in w.fauna.animals.duplicate():
				if a.alive and a.wild() and a.species in ["deer", "boar"]:
					var bag: Inventory = w.fauna.kill(a)
					w.stat("hunted_" + a.species)
					w.loot.append({"pos": a.pos, "inv": bag, "coins": 0, "from": "the " + a.species, "t": w.minutes})
					scenario_log.hunted = int(scenario_log.get("hunted", 0)) + 1
	print("SCENARIO %s on day %d: %s" % [name, w.day(), JSON.stringify(scenario_log)])


## SIM-GATE-01 crime_spree: the player's crimes, by day after --at and hour of the game clock: day 0 10:00 a theft from a
## household's crate, 11:00 a pocket picked, 14:00 a killing in sight of the village and a flight; day 1 14:00 an assault; day 2
## 14:00 another killing and flight. A step after the player's death is skipped and logged (the village's answer, not the script's). Each uses the game's own verbs (player_take,
## pickpocket, player_hit_npc); witnesses, reports, alarms, guards and chases are the village's own response. The player is
## put beside the victim (the harness's player is otherwise inert). Victims: adult villagers who are not guards, in id order,
## the one with the most villagers in sight (witness_radius) for the violent crimes.
func _crime_step(day_n: int, hour: int) -> void:
	var p := w.player
	var step := ""
	if not p.alive:
		if [day_n, hour] in [[0, 10], [0, 11], [0, 14], [1, 14], [2, 14], [2, 15]]:
			scenario_log["skipped_%d_%d" % [day_n, hour]] = "the player is dead"
		return
	if hour == 6:
		w.rest_recover(p, 480.0, true)        # the scripted player sleeps the night, as any player does (PAR-03)
	match [day_n, hour]:
		[0, 10]:
			step = "theft"
			for c in w.containers:
				if w.container_pick(c) == "" or w.container_owner(c) == null:
					continue
				for o in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
					var cell: Vector2i = Vector2i(int(c.x), int(c.y)) + o
					if not w.map.is_solid(cell):
						p.pos = Vector2(cell) + Vector2(0.5, 0.5)
						if w.player_container_reach(c) == "":
							scenario_log.theft = w.player_take(c)
							break
				if scenario_log.has("theft"):
					break
		[0, 11]:
			step = "pickpocket"
			var v := _crime_victim(false)
			if v != null:
				p.pos = v.pos + Vector2(0.4, 0)
				scenario_log.pickpocket = w.pickpocket(v).get("ok", false)
		[1, 14]:
			step = "assault"
			var v := _crime_victim(true)
			if v != null:
				p.pos = v.pos + Vector2(0.4, 0)
				scenario_log.assault = w.player_hit_npc(v, 1.0).get("dealt", 0.0)
		[2, 15]:
			# A3: the player, beaten, gives themselves up to a guard who knows of the case (the scenario walks them there)
			step = "yield"
			scenario_log.status_before_yield = w.justice.status("player")
			for g: NPC in w.npcs:
				if g.alive and g.job == "guard" and w.justice.knows(g, "player") and g.depth == 0 and not w.asleep(g):
					for k in 8:
						var c := Vector2i((g.pos + Vector2.RIGHT.rotated(TAU * k / 8.0) * 2.0).floor())
						if not w.map.is_solid(c) and w.place_of(Vector2(c) + Vector2(0.5, 0.5)) == w.place_of(g.pos):
							p.pos = Vector2(c) + Vector2(0.5, 0.5)
							break
					break
			flee_path = PackedVector2Array()
			var hp0 := p.hp
			p.hp = minf(p.hp, p.hp_cap() * float(Justice.cfg().yield_below) * 0.9)
			var y := w.player_yield()
			scenario_log.yielded = bool(y.ok)
			scenario_log.yield_text = str(y.text)
			if not y.ok:
				p.hp = hp0
			scenario_log.status_after_yield = w.justice.status("player")
		[0, 14], [2, 14]:
			step = "killing"
			var v := _crime_victim(true)
			if v != null:
				p.pos = v.pos + Vector2(0.4, 0)
				var killed := false
				for k in 20:                            # blow after blow, as a player would strike
					if w.player_hit_npc(v, 10.0).get("killed", false):
						killed = true
						break
				scenario_log["killing_%d" % day_n] = killed
				_start_flight()
	if step != "":
		scenario_log.steps = int(scenario_log.get("steps", 0)) + 1
		print("CRIME day %d %02d:00 %s: %s" % [w.day(), hour, step, JSON.stringify(scenario_log)])


## X20-FINAL phase 4 scripted steps, by day after --at and hour of the game clock, through the game's own verbs:
##   social_chain (the owner's chain: a crime seen -> opinions -> gossip -> another's judgment -> a later decision): day 0 11:00 and
##     day 1 11:00 the player picks the pocket of the adult with the most villagers in sight (two crimes, under the notoriety at
##     which everyone refuses, so each villager's own judgment answers); day 3 10:00 the player, with 600 coins from outside, offers
##     every adult villager a small contract (one unit of something they hold, twice its price, two days): each answer is the
##     villager's contract_accept judgment of the player (witnesses, those told, those who heard nothing); the flight recorder
##     traces it (tools/recorder_archive.py chains).
##   contracts_fail: day 0 09:00 the player, with 3000 coins from outside, orders goods from every adult tradesperson (their own
##     goods, a quantity of 8, three days), accepting a counteroffer on its terms; day 2 09:00 the player cancels every third open
##     contract. The harness player has no home, so goods for the player wait for a chest that is not there and those contracts
##     lapse at their deadline: the lapse path (coins back, the broken promise judged).
func _scripted_step(day_n: int, hour: int) -> void:
	var p := w.player
	if not p.alive:
		return
	var key := "%d_%d" % [day_n, hour]
	if scenario_log.has("done_" + key):
		return
	var did := ""
	match [scenario, day_n, hour]:
		["social_chain", 0, 11], ["social_chain", 1, 11]:
			var v := _crime_victim(true)
			if v != null:
				p.pos = v.pos + Vector2(0.4, 0)
				scenario_log["pickpocket_" + str(day_n)] = w.pickpocket(v).get("ok", false)
				scenario_log["victim_" + str(day_n)] = v.id
				did = "pickpocket"
		["social_chain", 3, 10]:
			p.coins += 600
			w.coin_sources += 600
			w.stat("scenario_coins_in", 600)
			var ans := {}
			for n: NPC in w.npcs:
				if not n.alive or n.role != "adult" or n.job == "guard":
					continue
				var item := ""
				var ids: Array = n.inv.items.keys()
				ids.sort()
				for id in ids:
					if n.inv.count(str(id)) > 0 and not GameData.item(str(id)).is_empty() and not Skills.is_gear(str(id)):
						item = str(id)
						break
				if item == "":
					continue
				p.pos = n.pos + Vector2(0.4, 0)           # face to face, as a player asking would stand
				var r: Dictionary = w.contracts.propose(w.player_ref(p), n, item, 1, maxi(1, w.sell_price(n, item)) * 2, 2)
				var a := str(r.get("answer", ""))
				if (r.get("terms", {}) as Dictionary).get("judgment", false):
					a = "refused_by_judgment"
				ans[a] = int(ans.get(a, 0)) + 1
				if r.has("contract"):
					w.contracts.cancel(r.contract, w.player_ref(p))     # the answer was the point: the slot is freed for the next (max_open_player)
			scenario_log.offers = ans
			did = "offers"
		["contracts_fail", 0, 9]:
			p.coins += 3000
			w.coin_sources += 3000
			w.stat("scenario_coins_in", 3000)
			var ans := {}
			for n: NPC in w.npcs:
				if not n.alive or n.role != "adult" or n.job in ["", "guard", "farmer", "laborer"]:
					continue
				var item := ""
				var ids: Array = n.inv.items.keys()
				ids.sort()
				for id in ids:
					if not GameData.item(str(id)).is_empty() and not Skills.is_gear(str(id)) and not (str(id) in NPCBrain.FOOD):
						item = str(id)
						break
				if item == "":
					continue
				var price := maxi(1, w.sell_price(n, item))
				p.pos = n.pos + Vector2(0.4, 0)           # face to face: a formal contract is signed in person (Q18-13)
				var r: Dictionary = w.contracts.propose(w.player_ref(p), n, item, 8, price, 3)
				if str(r.get("answer", "")) == "counter":
					r = w.contracts.propose(w.player_ref(p), n, item, int(r.qty), int(r.price_each), int(r.days), r.get("history", []))
				var a := str(r.get("answer", ""))
				ans[a] = int(ans.get(a, 0)) + 1
			scenario_log.orders = ans
			did = "orders"
		["contracts_fail", 2, 9]:
			var k := 0
			var cancelled := 0
			for c in w.contracts.open_of(w.player_ref(p), "buyer"):
				if k % 3 == 0 and w.contracts.cancel(c, w.player_ref(p)) == "":
					cancelled += 1
				k += 1
			scenario_log.cancelled = cancelled
			did = "cancel"
	if did != "":
		scenario_log["done_" + key] = true
		print("SCENARIO %s day %d %02d:00 %s: %s" % [scenario, w.day(), hour, did, JSON.stringify(scenario_log)])


func _crime_victim(violent: bool) -> NPC:
	var best: NPC = null
	var best_n := -1
	for n: NPC in w.npcs:
		if not n.alive or n.role != "adult" or n.job == "guard" or n.depth != 0 or w.place_of(n.pos) != "":
			continue
		var k := w.near(n.pos, float(GameData.b("witness_radius"))).size() if violent else 0
		if k > best_n:
			best = n
			best_n = k
	return best


## After a killing the player walks away along a path to the open cell farthest from them within 40 cells (the guards'
## pursuit is the village's own: NPCBrain.fight).
func _start_flight() -> void:
	var from := Vector2i(floori(w.player.pos.x), floori(w.player.pos.y))
	var best := from
	var best_d := 0
	for dy in range(-40, 41, 4):
		for dx in range(-40, 41, 4):
			var c := from + Vector2i(dx, dy)
			if w.map.is_solid(c) or absi(dx) + absi(dy) <= best_d:
				continue
			var path := w.map.find_path(from, c)
			if path.size() > 1:
				best = c
				best_d = absi(dx) + absi(dy)
	flee_path = w.map.find_path(from, best)
	scenario_log.flight_cells = flee_path.size()


func _flee_step() -> void:
	var left := FLEE_TILES_PER_SECOND * STEP
	while left > 0.0 and not flee_path.is_empty():
		var to := flee_path[0] + Vector2(0.5, 0.5)
		var d := to - w.player.pos
		if d.length() <= left:
			w.player.pos = to
			left -= d.length()
			flee_path.remove_at(0)
		else:
			w.player.pos += d.normalized() * left
			left = 0.0
	if not w.player.alive:
		flee_path = PackedVector2Array()


## GP-CRIME-PURSUIT (A1-A3): the player's case and the response so far, from Justice and the w.stats counters (read only).
func _justice() -> Dictionary:
	var j := {"status": w.justice.status("player"), "tier": w.justice.known_tier("player"), "open_cases": w.justice.cases.size(),
		"closed_cases": w.justice.closed.size(), "crimes": (w.justice.case_of("player").get("crimes", []) as Array).size(),
		"guards_on_case": w.npcs.filter(func(n: NPC) -> bool: return n.alive and not n.pursuit.is_empty()).size()}
	for k in ["pursuits", "responses", "searches", "reacquired", "shared", "joined", "sightings", "hue_and_cry", "hue_and_cry_guards", "bell",
			"bell_guards", "released_searched", "released_case_closed", "settled_yielded", "settled_taken", "settled_fined", "returned_items"]:
		j[k] = int(w.stats.get("justice_" + k, 0))
	return j


func _hourly() -> void:
	for n: NPC in _villagers():
		min_hunger = minf(min_hunger, n.hunger)
		if n.hunger <= 0.0:
			starving_hours += 1
	for i in w.deposits.size():
		if int(w.deposits[i].amount) <= 0 and not exhausted_day.has(i):
			exhausted_day[i] = w.day() + 1
	_herd_hour()


## FARM-08B: an hour in which a pen holds a hungry animal and its trough cannot feed it, and what the keeper was doing:
## none (no keeper), asleep, holding grain (in hand or at home: a care failure), or without grain (feed short).
func _herd_hour() -> void:
	var below := float(GameData.b("animal_eat_below"))
	for id in w.fauna.pens:
		var pen: Dictionary = w.fauna.pens[id]
		var k := str(pen.kind)
		var feed := int(GameData.b("animals")[k].feed)
		var hungry := false
		for a: Animal in w.fauna.animals:
			if a.alive and a.area == pen.id and a.hunger < below:
				hungry = true
				break
		if not hungry or int(pen.trough) >= feed:
			continue
		var row: Dictionary = herd_care.get(k, {"hours": 0, "no_keeper": 0, "asleep": 0, "keeper_has_grain": 0, "no_grain": 0})
		row.hours = int(row.hours) + 1
		var kp: NPC = w.pen_keeper(pen)
		var has := kp != null and (kp.inv.has("wheat") or (kp.household >= 0 and (w.households[kp.household].pantry as Inventory).has("wheat")))
		var why := "no_keeper" if kp == null or not kp.alive else ("asleep" if w.asleep(kp) else ("keeper_has_grain" if has else "no_grain"))
		row[why] = int(row[why]) + 1
		if why == "no_grain":
			var ng := _no_grain_why(kp, pen)
			row[ng] = int(row.get(ng, 0)) + 1
		herd_care[k] = row


## FARM-08B: why a keeper without grain went short: an awake farmer or food merchant held grain to spare (a full three-day
## lot, or only part of one), only sleeping sellers did, grain lay only in other households' chests, or nowhere but the
## granary; and whether the keeper could pay for a full lot.
func _no_grain_why(kp: NPC, pen: Dictionary) -> String:
	var lot := w.fauna.daily_need(pen) * 3
	var best := 0
	var asleep := false
	for o: NPC in w.npcs:
		if not o.alive or o == kp or not (o.job == "farmer" or w.brain.buy_role(o) == "merchant_food"):
			continue
		var spare: int = o.inv.count("wheat") - w.brain.reserve(o, "wheat")
		if spare <= 0:
			continue
		if w.asleep(o):
			asleep = true
		else:
			best = maxi(best, spare)
	if best >= lot:
		return "ng_lot_held" if kp.coins >= World.sell_price_at("wheat", best) * lot else "ng_lot_no_coins"
	if best > 0:
		return "ng_part_lot"
	if asleep:
		return "ng_sellers_asleep"
	for i in w.households.size():
		if i != kp.household and (w.households[i].pantry as Inventory).has("wheat"):
			return "ng_chests_only"
	return "ng_none"


## FARM-08B: the herds at the end of a day: adults by sex, young, the well fed, the females ready to breed and whether a
## mate is there, the trough, and the running counts of births and deaths by cause; kept only when something changed.
func _herd_day(day: int) -> void:
	var now: float = w.minutes
	var wheat := {"farmers": 0, "granary": w.granary.count("wheat"), "pantries": 0, "others": 0}
	for o: NPC in w.npcs:
		if o.alive:
			wheat["farmers" if o.job == "farmer" else "others"] += o.inv.count("wheat")
	for hh in w.households:
		wheat.pantries += (hh.pantry as Inventory).count("wheat")
	for id in w.fauna.pens:
		var pen: Dictionary = w.fauna.pens[id]
		var k := str(pen.kind)
		var r := {"m": 0, "f": 0, "young": 0, "elderly": 0, "fed": 0, "ready_f": 0, "mate": false}
		for a: Animal in w.fauna.animals:
			if not a.alive or a.area != pen.id:
				continue
			if not a.adult(now):
				r.young += 1
				continue
			r[a.sex] += 1
			if a.elderly(now):
				r.elderly += 1
			if w.fauna.well_fed(a):
				r.fed += 1
				if a.sex == "f" and a.breeds(now) and now >= a.next_birth:
					r.ready_f += 1
				if a.sex == "m" and a.breeds(now):
					r.mate = true
		var st := {}
		for key in w.stats:
			var sk := str(key)
			if sk.ends_with("_" + k) and (sk.begins_with("born_") or sk.begins_with("starved_") or sk.begins_with("old_age_") \
					or sk.begins_with("slaughter_") or sk.begins_with("keeper_no_feed_") or sk.begins_with("keeper_no_coins_") or sk.begins_with("farm_bought_")) \
					or sk.begins_with("eaten_%s_by_" % k) or sk.begins_with("fox_took_" + k):
				st[sk] = int(w.stats[key])
		var key_now := str([r, st])
		if herd_last.get(k, "") == key_now:
			continue
		herd_last[k] = key_now
		herd_log.append({"day": day, "season": w.season(), "kind": k, "herd": r, "trough": int(pen.trough),
			"need": w.fauna.daily_need(pen), "keeper": w.pen_keeper(pen) != null, "stats": st, "wheat": wheat,
			"keeper_coins": w.pen_keeper(pen).coins if w.pen_keeper(pen) != null else -1})


# ---------------------------------------------------------------- sampling -------------------
func _villagers() -> Array:
	return w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role != "bandit")


func _st(k: String) -> float:
	return float(w.stats.get(k, 0.0))


## CON-01: contracts over the run (counters from World.stats) and those on record now, by item and by who to whom.
## Expansion 18 couriers (X18-Q12, X18-Q13): booths, deliveries by who booked them and how they ended, the villagers' own postings,
## the notarised documents and the Law the keepers reached.
func _couriers_summary() -> Dictionary:
	var cs := w.couriers
	var by_state := {}
	var by_villager := 0
	for j in cs.jobs:
		by_state[str(j.state)] = int(by_state.get(str(j.state), 0)) + 1
		if str(j.sender).begins_with("npc:"):
			by_villager += 1
	var docs := {}
	for a in cs.agreements:
		docs[str(a.state)] = int(docs.get(str(a.state), 0)) + 1
	var law := []
	for b in cs.booths:
		if str(b.keeper).begins_with("npc:") and not bool(b.get("shop", false)):
			law.append(Skills.level(w.npc(int(str(b.keeper).trim_prefix("npc:"))), "law"))
	return {"booths": cs.booths.size(), "shop_booths": cs.booths.filter(func(b): return bool(b.get("shop", false))).size(), "routes": cs.routes.size(),
		"deliveries": cs.jobs.size(), "by_state": by_state, "booked_by_villagers": by_villager, "villager_posts_stat": int(w.stats.get("courier_posts_villager", 0)),
		"documents": docs, "keeper_law": law}


func _contracts_summary() -> Dictionary:
	var items := {}
	var pairs := {}
	for c in w.contracts.list:
		items[str(c.item)] = int(items.get(str(c.item), 0)) + 1
		var p := "%s>%s:%s" % [str(c.buyer).get_slice(":", 0), str(c.seller).get_slice(":", 0), str(c.state)]
		pairs[p] = int(pairs.get(p, 0)) + 1
	return {"made": int(_st("contracts_made")), "units": int(_st("contract_units")), "paid": int(_st("contract_paid")),
		"lapsed": int(_st("contracts_lapsed")), "cancelled": int(_st("contracts_cancelled")), "offers_to_player": int(_st("contract_offers_to_player")),
		"reserved_now": w.contracts.reserved_total(), "on_record_by_item": items, "on_record_by_parties": pairs}


func _sample(start: Dictionary) -> Dictionary:
	var s := {"day": w.day(), "clock": w.clock_text(), "fingerprint": _fingerprint()}       # the determinism gate compares these (PERF-03)
	s.justice = _justice()                # GP-CRIME-PURSUIT: the case record and the guards' response (read only)
	# people
	var by_role := {}
	var by_job := {}
	for n: NPC in w.npcs:
		if n.alive:
			by_role[n.role] = int(by_role.get(n.role, 0)) + 1
			if n.role != "bandit":
				var j: String = n.job if n.job != "" else "(" + n.role + ")"
				by_job[j] = int(by_job.get(j, 0)) + 1
	var vill := _villagers()
	s.people = {"alive": vill.size(), "by_role": by_role, "by_job": by_job, "deaths": deaths.duplicate(),
		"deaths_by_job": deaths_by_job.duplicate(), "bandit_deaths": bandit_deaths, "births": w.npcs.size() - int(start.npcs),
		"households": w.households.size(), "households_founded": int(_st("households_founded"))}
	# food
	var groups := _holders()
	var pts := {}
	var total_pts := 0.0
	for g in groups:
		var p := 0.0
		for f in NPCBrain.FOOD:
			p += int(groups[g].get(f, 0)) * float(GameData.item(f).food)
		pts[g] = roundi(p)
		total_pts += p
	var need := maxf(1.0, w.brain.village_day_food())
	var hunger_sum := 0.0
	var at_zero := 0
	for n: NPC in vill:
		hunger_sum += n.hunger
		if n.hunger <= 0.0:
			at_zero += 1
	s.food = {"points_by_holder": pts, "days_of_need": snappedf(total_pts / need, 0.01), "game_food_days": snappedf(w.food_days, 0.01),
		"day_need_points": roundi(need), "granary_wheat": w.granary.count("wheat"), "famine": w.famine(),
		"made": _keys_with("made_", ["wheat", "pottage", "roast_meat", "ale", "meat"]),
		"eaten_points": int(_st("eaten_food")), "starvation_deaths": int(deaths.get("starvation", 0)), "first_starvation_day": first_starvation_day,
		"starving_villager_hours": starving_hours, "at_zero_hunger_now": at_zero,
		"mean_hunger": snappedf(hunger_sum / maxf(1.0, vill.size()), 0.1), "min_hunger_since_last": snappedf(min_hunger, 0.1),
		"missed_meal_no_money": int(_st("missed_meal_no_money")), "missed_meal_no_food_for_sale": int(_st("missed_meal_no_food_for_sale")),
		"relief_grain": int(_st("gov_relief_grain")), "relief_bought_coins": int(_st("gov_relief_bought"))}
	# work
	var adults := 0
	var with_job := 0
	var with_place := 0
	var lost := 0
	for n: NPC in vill:
		if n.role == "adult":
			adults += 1
			if n.job != "":
				with_job += 1
			if n.workplace != "":
				with_place += 1
			if n.doing == "lost":
				lost += 1
	s.work = {"adults": adults, "with_job": with_job, "with_workplace": with_place, "unemployed": adults - with_job,
		"lost": lost, "job_changes": int(_st("job_changes")),
		"spec_switches": int(_st("spec_switches")), "wage_offers_raised": int(_st("wage_offers_raised")), "wage_offers_eased": int(_st("wage_offers_eased")), "stall_relocations": int(_st("stall_relocations"))}
	# money
	var cash := []
	for h in w.households.size():
		if not w.brain._members(h).is_empty():
			cash.append(w.property.purse(World.hh_ref(h)))
	cash.sort()
	var cash_total := 0
	for c in cash:
		cash_total += int(c)
	var trade := {}
	for n: NPC in vill:
		var r: String = w.brain.buy_role(n)
		if not NPCBrain.BUYS.has(r):
			continue
		var cheapest := 1 << 30
		for id in NPCBrain.BUYS[r]:
			cheapest = mini(cheapest, w.buy_price(n, id))
		if not trade.has(r):
			trade[r] = {"n": 0, "coins": 0, "min": 1 << 30, "below_price": 0, "below_floor": 0, "zero": 0}
		var t: Dictionary = trade[r]
		t.n += 1
		t.coins += n.coins
		t.min = mini(int(t.min), n.coins)
		if n.coins < cheapest:
			t.below_price += 1
		if n.coins - cheapest < w.reserve_of(n):
			t.below_floor += 1            # cannot buy stock: sales to it need coins - price >= its reserve (OD-19)
		if n.coins == 0:
			t.zero += 1
	var merchants := 0
	for n: NPC in vill:
		if n.job == "merchant":
			merchants += n.coins
	s.money = {"household_cash": {"n": cash.size(), "min": cash[0] if not cash.is_empty() else 0, "median": cash[cash.size() / 2] if not cash.is_empty() else 0,
		"max": cash[-1] if not cash.is_empty() else 0, "total": cash_total}, "traders": trade, "treasury": w.treasury, "merchant_funds": merchants,
		"gov": _keys_with("gov_", ["tax", "wages", "rent", "land_sales", "repairs", "public_works", "procurement", "relief_bought", "fines", "tools", "loot_recovered"]),
		"od16": {"manor_tool_coins": int(_st("gov_tools")), "axes_given": int(_st("gov_tool_given_axe")), "axe_advances": int(_st("gov_tool_advance_axe")),
			"axes_delivered": int(_st("gov_tool_delivered_axe")), "pickaxes_given": int(_st("gov_tool_given_pickaxe")), "pickaxe_advances": int(_st("gov_tool_advance_pickaxe")),
			"loot_coins_recovered": int(_st("gov_loot_recovered")), "bandit_market_trips": int(_st("bandit_market_trips")),
			"bandit_coins": w.npcs.filter(func(o: NPC) -> bool: return o.alive and o.role == "bandit").reduce(func(acc: int, o: NPC) -> int: return acc + o.coins, 0),
			"loot_coins": w.loot.reduce(func(acc: int, l) -> int: return acc + int(l.coins), 0)}}
	# materials
	var held := {}
	for g in groups:
		var row := {}
		for id in MATERIALS:
			if int(groups[g].get(id, 0)) != 0:
				row[id] = int(groups[g][id])
		held[g] = row
	var left := {}
	for d in w.deposits:
		left[d.ore] = int(left.get(d.ore, 0)) + int(d.amount)
	var tree_states := {}
	for t in w.trees:
		tree_states[t.state] = int(tree_states.get(t.state, 0)) + 1
	var by_job_held := {}             # what villagers carry, by job: who holds the stock
	for n: NPC in vill:
		var j: String = n.job if n.job != "" else n.role
		if not by_job_held.has(j):
			by_job_held[j] = {}
		for id in n.inv.items:
			if id in MATERIALS:
				by_job_held[j][id] = int(by_job_held[j].get(id, 0)) + int(n.inv.items[id])
	s.materials = {"held": held, "held_by_job": by_job_held, "deposit_left": left, "deposits": w.deposits.map(func(d): return [d.ore, int(d.amount)]),
		"deposits_exhausted": w.deposits.filter(func(d): return int(d.amount) <= 0).size(), "trees": tree_states,
		"mined": _keys_with("mined_", ["iron_ore", "copper_ore", "gold_ore", "coal", "stone"]),
		"dug": _keys_with("dug_", ["topsoil", "dirt", "spoil", "stone"]), "pits": w.pits.pits.size(), "pit_seams": int(_st("pit_seams")),
		"underground": _keys_with("", ["tunnel_cells_opened", "supports_set_up", "supports_repaired", "shore_jobs_posted", "manor_job_tunnel", "manor_job_shore", "gov_mine_equipment", "minecart_hauls", "minecarts_set_down_by_miners", "shafts_sunk", "tunnel_collapses", "collapse_deaths", "collapse_survivors", "seams_found_below"]),
		"felled_trees": int(_st("trees_felled")), "felled_logs": int(_st("felled_log")), "burned_logs": int(_st("burned_log")),
		"broke": _keys_with("broke_", ["pickaxe", "axe", "hammer"])}
	# wildlife
	var sp := {}
	for a: Animal in w.fauna.animals:
		if not a.alive:
			continue
		if not sp.has(a.species):
			sp[a.species] = {"wild": 0, "penned": 0, "adult": 0, "young": 0}
		sp[a.species]["wild" if a.wild() else "penned"] += 1
		sp[a.species]["adult" if a.adult(w.minutes) else "young"] += 1
	var kinds: Array = GameData.b("animals").keys().filter(func(k): return k != "_note")
	s.wildlife = {"species": sp, "hunted": _keys_with("hunted_", kinds), "slaughtered": _keys_with("slaughtered_", kinds),
		"poached": _keys_with("poached_", kinds), "starved": _keys_with("starved_", kinds), "born": _keys_with("born_", kinds)}
	# building
	var open := 0
	var done := 0
	for p in w.plots:
		if not p.site.is_empty():
			if p.site.get("done", false):
				done += 1
			else:
				open += 1
	var houses := 0
	var workshops := 0
	for b in w.buildings.values():
		if World.is_built(b):
			if str(b.get("kind", "house")) == "house":
				houses += 1
			else:
				workshops += 1
	s.building = {"sites_started": events.sites_started, "sites_finished": events.sites_finished, "sites_given_up": events.sites_given_up,
		"open_sites": open, "finished_sites": done, "houses_built": houses, "workshops_built": workshops,
		"households": w.households.size(), "households_split": int(_st("households_founded")), "helpers_now": w.construction.contracts.size(),
		"helper_wages": int(_st("helper_wages")), "helper_bought": int(_st("helper_bought")),
		"lofts_started": int(_st("loft_started")), "quarters_started": int(_st("quarters_started")), "rooms_started": int(_st("room_started")),
		"orphans_taken_in": int(_st("orphans_taken_in")), "orphans_unplaced": int(_st("orphans_unplaced"))}
	s.growth = _growth()
	# trade
	var exp := {}
	var imp := {}
	for k in w.stats:
		if str(k).begins_with("exported_"):
			exp[str(k).substr(9)] = int(w.stats[k])
		elif str(k).begins_with("imported_"):
			imp[str(k).substr(9)] = int(w.stats[k])
	var mw: ManorWork = w.manor_work
	var open_kinds := {}
	for j in mw.jobs:
		var k := "%s_%s" % [j.kind, "taken" if j.taker != "" else "open"]
		open_kinds[k] = int(open_kinds.get(k, 0)) + 1
	s.manor_work = {"jobs_now": open_kinds, "taken": int(_st("manor_jobs_taken")), "done": int(_st("manor_jobs_done")),
		"done_by_kind": {"haul": int(_st("manor_job_haul")), "quarry": int(_st("manor_job_quarry")), "mend": int(_st("manor_job_mend"))},
		"wages": int(_st("gov_manor_jobs")), "lots": mw.lots.size(), "lot_goods": mw.goods(), "yard": mw.yard.total(), "mended": int(_st("works_mended"))}
	s.trade = {"caravans": events.caravans, "exported": exp, "imported": imp, "coins_in": int(_st("caravan_coins_in")),
		"coins_out": int(_st("caravan_coins_out")), "coin_sources": w.coin_sources}
	# currency and flow accounts
	var c := _coins()
	# coins from outside: the caravan's purchases, newcomers' purses (they come in from outside), and a scenario's grant (EQ-06)
	var c_in := int(_st("caravan_coins_in")) - int(start.stats.get("caravan_coins_in", 0)) \
			+ int(_st("newcomer_coins_in")) - int(start.stats.get("newcomer_coins_in", 0)) \
			+ int(_st("scenario_coins_in")) - int(start.stats.get("scenario_coins_in", 0)) \
			+ int(_st("outlaw_coins_in")) - int(start.stats.get("outlaw_coins_in", 0))        # BANDIT-RETURN: the outlaws' purses come in from outside
	var c_out := int(_st("caravan_coins_out")) - int(start.stats.get("caravan_coins_out", 0))
	var src_delta := w.coin_sources - int(start.coin_sources)
	s.currency = {"holders": c, "total": c.total, "world_total_coins": w.total_coins(), "start_total": start.coins.total,
		"external_in": c_in, "external_out": c_out, "leak": int(c.total) - int(start.coins.total) - c_in + c_out,
		"coin_sources_delta": src_delta, "coin_sources_mismatch": src_delta - (c_in - c_out),
		"holders_mismatch": int(c.total) - w.total_coins()}
	s.ledger = _ledger(start)
	s.regions = _regions(start)
	s.player = {"alive": w.player.alive, "hp": snappedf(w.player.hp, 0.1), "min_hp": snappedf(player_min_hp, 0.1), "hours_hurt": player_attacked}
	s.events = events.duplicate()
	s.farm = _farm()
	return s


## SET-C-SIM: the five neighbouring settlements. Their coins changed by exactly what the village paid them less what they
## paid it (the village's coin_sources moved the other way), and their goods by what crossed the boundary, their own
## production and their own use; each settlement's books balance (OffMapSettlement.audit). Mismatches are printed, never hidden.
func _regions(start: Dictionary) -> Dictionary:
	var r: Regions = w.regions
	var coins_now := r.coins()
	var net := r.net_paid_by_village()
	var made := {}
	var used := {}
	var in_v := {}
	var out_v := {}
	for st in r.list:
		for k in st.flows.produced:
			made[k] = int(made.get(k, 0)) + int(st.flows.produced[k])
		for k in st.flows.used:
			used[k] = int(used.get(k, 0)) + int(st.flows.used[k])
		for k in st.flows.from_village:
			in_v[k] = int(in_v.get(k, 0)) + int(st.flows.from_village[k])
		for k in st.flows.to_village:
			out_v[k] = int(out_v.get(k, 0)) + int(st.flows.to_village[k])
		for k in st.flows.outside_in:           # REG-COURIER-01: goods the couriers handed to a settlement's party, and took from it
			in_v[k] = int(in_v.get(k, 0)) + int(st.flows.outside_in[k])
		for k in st.flows.outside_out:
			out_v[k] = int(out_v.get(k, 0)) + int(st.flows.outside_out[k])
	var now_goods := r.goods()
	var bad_goods := {}
	var ids := {}
	for k in start.regions_goods:
		ids[k] = true
	for k in now_goods:
		ids[k] = true
	for k in ids:
		# the settlements' goods now = at the start + made - used + bought from the village - sold to it (the run starts at day 0)
		var d := int(now_goods.get(k, 0)) - int(start.regions_goods.get(k, 0))
		var f := int(made.get(k, 0)) - int(used.get(k, 0)) + int(in_v.get(k, 0)) - int(out_v.get(k, 0))
		if d != f:
			bad_goods[k] = d - f
	# MIGRATE-18: people crossing the boundary: the village's count out less in is what the settlements took in less sent
	return {"people_mismatch": r.net_migrants_counted() - r.net_migrants_from_village(), "migrants_in": int(_st("migrants_in")), "migrants_out": int(_st("migrants_out")),
		"moves": r.move_counts.duplicate(), "audit": r.audit(), "coins": coins_now, "coins_start": int(start.regions_coins), "coins_delta": coins_now - int(start.regions_coins),
		"village_paid_net": net, "coins_mismatch": (coins_now - int(start.regions_coins)) - net,
		"goods_mismatch": bad_goods.size(), "goods_mismatch_items": bad_goods, "population": r.population(),
		"settlements": r.summary(), "made": made, "used": used, "bought_from_village": in_v, "sold_to_village": out_v}


## FARM-08 (owner, 2026-10-21): the farming economy for the shared-yield comparison: the fields, the pens and their
## feed, the grain flows and the market's grain price. Prices are read with the caches restored (a reading must not
## change the run, as for --watch-from).
func _farm() -> Dictionary:
	var pc: Dictionary = w._price_cache.duplicate()
	var rc: Dictionary = w._reserve_cache.duplicate()
	var price := 0
	var farmers_wheat := 0
	for o: NPC in w.npcs:
		if o.alive and o.job == "farmer":
			farmers_wheat += o.inv.count("wheat")
			if o.inv.count("wheat") > 0:
				var pr := w.sell_price(o, "wheat")
				price = pr if price == 0 else mini(price, pr)
	w._price_cache = pc
	w._reserve_cache = rc
	var fields := {}
	for f in w.fields:
		fields[str(f.state)] = int(fields.get(str(f.state), 0)) + 1
	var pens := {}
	for id in w.fauna.pens:
		var pen: Dictionary = w.fauna.pens[id]
		var k := str(pen.kind)
		var row: Dictionary = pens.get(k, {"animals": 0, "well_fed": 0, "trough": 0, "keepers": 0})
		for a: Animal in w.fauna.animals:
			if a.alive and a.area == pen.id:
				row.animals = int(row.animals) + 1
				if w.fauna.well_fed(a):
					row.well_fed = int(row.well_fed) + 1
		row.trough = int(row.trough) + int(pen.trough)
		row.keepers = int(row.keepers) + (1 if w.pen_keeper(pen) != null else 0)
		pens[k] = row
	var st := {}
	for k in ["made_wheat", "used_wheat_seed", "made_wheat_seed", "farm_seed_saved", "field_unsown_no_seed", "feed_eaten_wheat",
			"farm_made_milk", "farm_made_egg", "farm_made_wool", "exported_wheat", "imported_wheat_seed", "gov_relief_grain"]:
		st[k] = int(_st(k))
	for k in w.stats:
		if str(k).begins_with("slaughtered_") or str(k).begins_with("starved_cow") or str(k).begins_with("starved_sheep") \
				or str(k).begins_with("starved_chicken") or str(k).begins_with("starved_pig"):
			st[k] = int(w.stats[k])
	return {"wheat_price": price, "farmers_wheat": farmers_wheat, "granary_wheat": w.granary.count("wheat"), "famine": w.famine(),
		"food_days": snappedf(w.food_days, 0.01), "fields": fields, "pens": pens, "stats": st}


## Stats `prefix + id` for each id with a non-zero value.
func _keys_with(prefix: String, ids: Array) -> Dictionary:
	var out := {}
	for id in ids:
		var v := _st(prefix + str(id))
		if v != 0.0:
			out[id] = int(v)
	return out


## Every coin, by who holds it. World.total_coins counts the same holders.
func _coins() -> Dictionary:
	var out := {"villagers": 0, "bandits": 0, "dead": 0, "player": w.player.coins, "treasury": w.treasury, "loot": 0,
		"quest_reserves": w.quests.reserved_total(), "manor_wages_reserved": w.manor_work.reserved_total(),
		"contract_reserves": w.contracts.reserved_total(),   # CON-01: buyers' coins set aside for contracts
		"stall_tills": w.business.tills(),
		"chapel": w.chapel.coins,
		"courier_booths": w.couriers.held_coins() if w.couriers != null else 0}                  # DVW-B3-CHAPEL: the offerings fund; takings held in stall tills until settled (STALL-05)
	for n: NPC in w.npcs:
		out["dead" if not n.alive else ("bandits" if n.role == "bandit" else "villagers")] += n.coins
	for l in w.loot:
		out.loot += int(l.coins)
	var t := 0
	for k in out:
		t += int(out[k])
	out.total = t
	return out


## Every item, by holder group: id -> count. The groups together are run_tests' _all_goods plus the
## pens' troughs (wheat put out as feed).
func _holders() -> Dictionary:
	return Census.holders(w)


func _all_goods() -> Dictionary:
	var out := {}
	var g := _holders()
	for k in g:
		for id in g[k]:
			out[id] = int(out.get(id, 0)) + int(g[k][id])
	return out


func _animal_counts() -> Dictionary:
	var out := {}
	for a: Animal in w.fauna.animals:
		if a.alive:
			out[a.species] = int(out.get(a.species, 0)) + 1
	return out


## The flow accounts since `start`. Items: held(start) + produced + imported - consumed - exported
## = held(now); produced = made_ (recipes, harvest, kills, home cooking) + mined_ + felled_ + dug_ (MIN-E open pits);
## consumed = eaten_ + used_ (recipes, home cooking) + used_building_ + used_works_ + used_repairs_
## + feed_eaten_ (troughs) + burned_ (firewood) + broke_ (tools) + poached_lost_ (the bandits' game) + spoiled_ (carcasses left to spoil)
## + backfilled_ (earth put back into a pit); MIN-F: cut_ (rock cut from a tunnel face) is produced too.
## Only non-zero residuals are kept, with their terms.
func _ledger(start: Dictionary) -> Dictionary:
	var st0: Dictionary = start.stats
	var d := func(k: String) -> int: return int(_st(k)) - int(st0.get(k, 0))
	var now := _all_goods()
	var ids := {}
	for id in now:
		ids[id] = true
	for id in start.goods:
		ids[id] = true
	for k in w.stats:
		for p in ["made_", "mined_", "felled_", "dug_", "cut_", "imported_", "exported_", "eaten_", "used_building_", "used_works_", "used_repairs_", "used_", "feed_eaten_", "burned_", "broke_", "poached_lost_", "spoiled_", "wild_eaten_", "farm_harvest_", "backfilled_", "filled_"]:
			if str(k).begins_with(p):
				ids[str(k).substr(p.length())] = true
				break
	ids.erase("food")                     # eaten_food is points, not an item
	for id in ids.keys():
		if not GameData.items.has(id):
			ids.erase(id)                     # counters that are not goods, e.g. eaten_deer_by_wolf (predation)
	var bad := {}
	var flows := {}
	var table := {}                       # DVW-A4: every good's faucets (produced, imported) and drains (consumed, exported)
	var keys := ids.keys()
	keys.sort()
	for id in keys:
		var produced: int = d.call("made_" + id) + d.call("mined_" + id) + d.call("felled_" + id) + d.call("farm_harvest_" + id) + d.call("dug_" + id) + d.call("cut_" + id)
		var consumed: int = d.call("eaten_" + id) + d.call("used_" + id) + d.call("used_building_" + id) + d.call("used_works_" + id) \
			+ d.call("used_repairs_" + id) + d.call("feed_eaten_" + id) + d.call("burned_" + id) + d.call("broke_" + id) + d.call("poached_lost_" + id) + d.call("spoiled_" + id) \
			+ d.call("wild_eaten_" + id) + d.call("backfilled_" + id) + d.call("filled_" + id)
		if id == "wheat":                     # farmers keep seed back from the grain they cut (Farming.save_seed)
			consumed += d.call("farm_seed_saved")
		elif id == "wheat_seed":
			produced += d.call("farm_seed_saved")
		var imported: int = d.call("imported_" + id)
		var exported: int = d.call("exported_" + id)
		var s0 := int(start.goods.get(id, 0))
		var s1 := int(now.get(id, 0))
		var residual := s1 - (s0 + produced + imported - consumed - exported)
		var row := {"start": s0, "produced": produced, "imported": imported, "consumed": consumed, "exported": exported, "end": s1}
		table[id] = row
		if id in MATERIALS or residual != 0:
			flows[id] = row
		if residual != 0:
			row.residual = residual
			bad[id] = row
	var dep := []
	var mined_by_ore := {}
	# MIN-D: a seam opened by a trial pit during the run starts at 0 here and enters the books as found_<ore> (its host
	# rock as found_stone): start + found - end = mined
	for i in w.deposits.size():
		var ore: String = w.deposits[i].ore
		var s0 := int(start.deposits[i]) if i < (start.deposits as Array).size() else 0
		mined_by_ore[ore] = int(mined_by_ore.get(ore, 0)) + s0 - int(w.deposits[i].amount)
	for ore in ["iron_ore", "coal", "copper_ore", "gold_ore"]:
		if d.call("found_" + ore) != 0:
			mined_by_ore[ore] = int(mined_by_ore.get(ore, 0)) + d.call("found_" + ore)
	# MIN-B: the other stone pools: worked-out seams' host rock, the village's boulders (villagers quarry both now)
	var hosts_now := _hosts()
	var host_fall := 0
	for i in hosts_now.size():
		host_fall += (int(start.hosts[i]) if i < (start.hosts as Array).size() else 0) - int(hosts_now[i])
	mined_by_ore["stone"] = int(mined_by_ore.get("stone", 0)) + host_fall + d.call("found_stone") + int(start.boulders) - _boulder_stone()
	for ore in mined_by_ore:
		var counted: int = d.call("mined_" + ore)
		if counted != int(mined_by_ore[ore]):
			dep.append({"ore": ore, "taken_from_deposits": mined_by_ore[ore], "mined_counted": counted})
	# MIN-E: the open pits' ground, a pool per item: start + staked (pit_ground_) - end = dug - backfilled. MIN-D-Q3: a
	# trial pit's earth enters the books as trial_ground_ when it is dug (all of it at once: nothing is left in a trial pit)
	var pits_now: Dictionary = w.pits.ground_left()
	var pit_ids := {}
	for id in pits_now:
		pit_ids[id] = true
	for id in start.get("pits", {}):
		pit_ids[id] = true
	for k in w.stats:
		if str(k).begins_with("pit_ground_"):
			pit_ids[str(k).substr(11)] = true
		if str(k).begins_with("trial_ground_"):
			pit_ids[str(k).substr(13)] = true
	for id in pit_ids:
		var fall: int = int(start.get("pits", {}).get(id, 0)) + d.call("pit_ground_" + id) + d.call("trial_ground_" + id) - int(pits_now.get(id, 0))
		var net: int = d.call("dug_" + id) - d.call("backfilled_" + id)
		if fall != net:
			dep.append({"pit": id, "taken_from_pits": fall, "dug_counted": net})
	# MIN-F: the rock cut from the tunnels, a pool per item: (now - start) of MineWorks.ground_cut (rock and rubble) plus,
	# for spoil, the fill dug out again (MIN-F2) = cut_; and the fill in the ground: start + filled_spoil - dug again = now
	var cut_now: Dictionary = w.mine_works.ground_cut()
	var fill_out: int = w.mine_works.fill_out - int(start.get("fill_out", 0))
	for id in ["stone", "spoil"]:
		var taken: int = int(cut_now.get(id, 0)) - int(start.get("cut", {}).get(id, 0)) + (fill_out if id == "spoil" else 0)
		if taken != d.call("cut_" + id):
			dep.append({"tunnel": id, "taken_from_rock": taken, "cut_counted": d.call("cut_" + id)})
	if w.mine_works.fill_in() - int(start.get("fill_in", 0)) != d.call("filled_spoil") - fill_out:
		dep.append({"backfill": "spoil", "fill_rise": w.mine_works.fill_in() - int(start.get("fill_in", 0)), "filled_counted": d.call("filled_spoil") - fill_out})
	var animals := {}
	var now_a := _animal_counts()
	var kinds: Array = GameData.b("animals").keys().filter(func(k): return k != "_note")
	for k in kinds:
		var preyed := 0                       # B14 forest animals: kills by predators and the fox's raids
		for sk in w.stats:
			if str(sk).begins_with("eaten_%s_by_" % k):
				preyed += d.call(str(sk))
		var expect: int = int(start.animals.get(k, 0)) + d.call("born_" + k) - d.call("hunted_" + k) - d.call("slaughtered_" + k) \
			- d.call("poached_" + k) - d.call("starved_" + k) - preyed - d.call("fox_took_" + k) - d.call("old_age_" + k)
		if expect != int(now_a.get(k, 0)):
			animals[k] = {"expected": expect, "counted": int(now_a.get(k, 0))}
	return {"items": bad, "flows": flows, "table": table, "deposits": dep, "animals": animals}


## A digest of the world's state: equal digests mean the same run (used to check that the ledger
## counters change nothing).
func _fingerprint() -> String:
	var parts := PackedStringArray([str(w.minutes), str(w.treasury), str(w.coin_sources), str(w.rng.state), str(w.granary.items)])
	for n: NPC in w.npcs:
		parts.append("%d|%s|%d|%s|%s|%s|%s" % [n.id, n.alive, n.coins, n.pos, n.hunger, n.job, n.inv.items])
	for a: Animal in w.fauna.animals:
		parts.append("%d|%s|%s" % [a.id, a.pos, a.hunger])
	for dp in w.deposits:
		parts.append(str(dp.amount))
	for hh in w.households:
		parts.append(str(hh.pantry.items))
	return "|".join(parts).md5_text()


## MIN-B: each deposit's host rock left (0 for a seam with none), in deposit order.
func _hosts() -> Array:
	return w.deposits.map(func(d): return int(d.host.amount) if d.has("host") else 0)


## The stone the village's boulders still hold.
func _boulder_stone() -> int:
	var n := 0
	for b in w.boulders:
		n += maxi(0, int(b.amount))
	return n


func _jsonable(d: Dictionary) -> Dictionary:
	return {"coins": d.coins, "goods": d.goods, "deposits": d.deposits, "animals": d.animals, "alive": d.alive, "households": d.households}


# ---------------------------------------------------------------- output ---------------------
func _print_sample(s: Dictionary) -> void:
	var tr: Dictionary = s.money.traders
	var insolvent := 0
	for r in tr:
		insolvent += int(tr[r].below_floor)
	var held: Dictionary = s.materials.held
	var sum := func(id: String) -> int:
		var n := 0
		for g in held:
			n += int(held[g].get(id, 0))
		return n
	var wild := 0
	var penned := 0
	for k in s.wildlife.species:
		wild += int(s.wildlife.species[k].wild)
		penned += int(s.wildlife.species[k].penned)
	print("day %3d: alive %d (starved %d, other deaths %d), food %.1f days, mean hunger %.0f, unemployed %d, hh cash min/med/max %d/%d/%d, treasury %d, traders unable to buy %d, ore left %s, logs %d planks %d trees %d, wild %d penned %d, sites %d/%d houses %d hh %d, coins %d (leak %d), item leaks %d" % [
		s.day, s.people.alive, s.food.starvation_deaths, _sumd(s.people.deaths) - int(s.food.starvation_deaths), s.food.days_of_need, s.food.mean_hunger,
		s.work.unemployed, s.money.household_cash.min, s.money.household_cash.median, s.money.household_cash.max, s.money.treasury, insolvent,
		s.materials.deposit_left, sum.call("log"), sum.call("plank"), int(s.materials.trees.get("grown", 0)), wild, penned,
		s.building.sites_finished, s.building.sites_started, s.building.houses_built, s.building.households, s.currency.total, s.currency.leak, (s.ledger.items as Dictionary).size()])
	print("  growth: %s" % JSON.stringify(s.growth))
	var rg: Dictionary = s.regions
	var per := []
	for st in rg.settlements:
		per.append("%s %d people %dc (treasury %d, trader %d, %d hungry, %d died)" % [st.id, st.population, st.coins, st.treasury, st.trader, st.hungry, st.deaths])
	print("  neighbours: %d people, %d coins (village paid net %d); %s%s" % [rg.population, rg.coins, rg.village_paid_net, "; ".join(per),
		("  AUDIT " + str(rg.audit)) if str(rg.audit) != "" else ""])
	print("  migration (MIGRATE-18): %d to the settlements, %d to the village; by reason %s" % [rg.migrants_out, rg.migrants_in, JSON.stringify(rg.moves)])


## What holds back births, partnering and new households (EQ-07; read only): beds against people, couples
## who could have a child and what stops them, single adults, crowded households and whether they can pay
## for a new home, and empty houses on the market.
func _growth() -> Dictionary:
	var c := Life.cfg()
	var con := w.construction
	var fp := con.footprint("house")
	var house_cost := w.property.land_price(fp.x, fp.y) + ceili(con.estimate(con.cost_of("house")) * float(GameData.b("found_start_share")))
	var beds := 0
	var living := 0
	var full := 0
	for h in w.households.size():
		var hh: Dictionary = w.households[h]
		if hh.get("ended", false) or w.brain._members(h).is_empty():
			continue
		living += Life._living_in(w, h)
		if w.buildings.has(str(hh.home)):
			beds += con.beds_in(str(hh.home))
			if not Life.has_room(w, h):
				full += 1
	var couples := {"fertile": 0, "full_house": 0, "low_food": 0, "recent_child": 0, "could": 0}
	var single := {"female": 0, "male": 0, "female_room": 0, "male_room": 0}
	for n: NPC in w.npcs:
		if not n.alive or n.role != "adult":
			continue
		var a := Life.npc_age(w, n)
		if not Life.has_partner(w, n):
			if a >= float(c.partner_min_age) and a <= float(c.partner_max_age):
				single[n.sex] += 1
				if Life.has_room(w, n.household):
					single[n.sex + "_room"] += 1
			continue
		if n.sex != "female" or a < float(c.birth_mother_min_age) or a > float(c.birth_mother_max_age):
			continue
		couples.fertile += 1
		var recent := false
		for cid in n.children:
			var k := w.npc(int(cid))
			if k != null and Life.age_years(k.born, w.minutes) < float(c.birth_min_gap_years):
				recent = true
		if not Life.has_room(w, n.household):
			couples.full_house += 1                  # no longer a bar to a birth (EQ-08); counted for crowding
		if w.brain.household_food_days(n.household) < float(c.birth_min_food_days):
			couples.low_food += 1
		elif recent:
			couples.recent_child += 1
		else:
			couples.could += 1
	var crowded := 0
	var can_split := 0
	var best_spare: int = -1000000000
	for h in w.households.size():
		if con.crowded(h):
			crowded += 1
			var spare: int = w.property.purse(World.hh_ref(h)) - con._keep(h, w.brain._members(h).size() - 1)
			best_spare = maxi(best_spare, spare)
			if spare >= house_cost:
				can_split += 1
	var empty_houses := 0
	for r in w.property.market():
		if w.property.is_home(r) or w.property.is_home(w.property.unit(r).back()):
			empty_houses += 1
	return {"beds": beds, "living": living, "households_full": full, "fertile_couples": couples, "single_adults": single,
		"crowded_households": crowded, "crowded_can_afford_home": can_split, "best_crowded_spare": best_spare if crowded > 0 else 0,
		"house_start_cost": house_cost, "house_materials": con.estimate(con.cost_of("house")), "couples_needing_home": con.couples_needing_home().size(),
		"courtships": int(_st("courtships")), "gifts_given": int(_st("gifts_given")), "house_price": int(GameData.b("house_price")), "empty_houses_for_sale": empty_houses,
		"partnerships": int(_st("partnerships")), "households_founded": int(_st("households_founded"))}


func _sumd(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n


func _print_final(s: Dictionary, start: Dictionary, seed: int, days: int, secs: float) -> void:
	print("=== seed %d, %d days, %.1f s (%.2f s per game day)" % [seed, days, secs, secs / maxf(1.0, days)])
	print("people: alive %d of %d; by job %s; deaths %s (by job %s); bandits killed %d; births %d; households %d -> %d (split %d)" % [
		s.people.alive, start.alive, s.people.by_job, s.people.deaths, s.people.deaths_by_job, s.people.bandit_deaths, s.people.births,
		start.households, s.people.households, s.people.households_founded])
	print("food: %s" % JSON.stringify(s.food))
	print("work: %s" % JSON.stringify(s.work))
	print("money: %s" % JSON.stringify(s.money))
	print("materials: %s" % JSON.stringify(s.materials))
	print("deposits exhausted on day: %s" % JSON.stringify(exhausted_day))
	print("wildlife: %s" % JSON.stringify(s.wildlife))
	print("building: %s" % JSON.stringify(s.building))
	print("growth: %s" % JSON.stringify(s.growth))
	print("trade: %s" % JSON.stringify(s.trade))
	print("manor work: %s" % JSON.stringify(s.manor_work))
	print("contracts: %s" % JSON.stringify(_contracts_summary()))
	print("couriers: %s" % JSON.stringify(_couriers_summary()))
	var cr := {}                       # TRADE-CREDIT: barter and credit over the run, and the debts on record
	for k in w.stats:
		if str(k).begins_with("credit_") or str(k).begins_with("barter_"):
			cr[str(k)] = int(w.stats[k])
	var open_debts := 0
	for d in w.credit.debts:
		open_debts += 1 if Credit.standing(d) else 0
	cr["standing_debts_now"] = open_debts
	print("credit: %s" % JSON.stringify(cr))
	print("currency: %s" % JSON.stringify(s.currency))
	print("player: %s" % JSON.stringify(s.player))
	print("events: %s" % JSON.stringify(s.events))
	print("ledger flows: %s" % JSON.stringify(s.ledger.flows))
	print("LEAKS: currency %d; items %s; deposits %s; animals %s" % [s.currency.leak, JSON.stringify(s.ledger.items),
		JSON.stringify(s.ledger.deposits), JSON.stringify(s.ledger.animals)])
	print("trade flows (buyer>seller): %s" % JSON.stringify(flows))
	print("missed meals: %s" % JSON.stringify(_miss_summary()))
	print("deaths: %s" % JSON.stringify(death_log))
	_print_faucets(s)
	print("fingerprint %s" % _fingerprint())


## DVW-A4: what entered and left the village over the run, kept apart from trade inside it. Coins: the
## caravan's purchases and newcomers' purses in, the caravan's sales out. Goods: made, mined, felled and
## harvested, and imported, in; eaten, used, built with, burned, broken and lost, and exported, out.
func _print_faucets(s: Dictionary) -> void:
	var c: Dictionary = s.currency
	print("FAUCETS AND DRAINS (whole run)")
	print("  coins: in %d (caravan buys %d, newcomers %d), out %d (caravan sells); held %d -> %d" % [int(c.external_in),
		int(_st("caravan_coins_in")), int(_st("newcomer_coins_in")), int(c.external_out), int(c.start_total), int(c.total)])
	print("  %-22s %7s %8s %8s %8s %8s %7s" % ["good", "start", "made", "imported", "used", "exported", "end"])
	var t: Dictionary = s.ledger.table
	var ids := t.keys()
	ids.sort()
	for id in ids:
		var r: Dictionary = t[id]
		if int(r.produced) + int(r.imported) + int(r.consumed) + int(r.exported) == 0:
			continue                          # held, never made or used: nothing flowed
		print("  %-22s %7d %8d %8d %8d %8d %7d" % [id, int(r.start), int(r.produced), int(r.imported), int(r.consumed), int(r.exported), int(r.end)])


## Missed meals (NPCBrain.miss_log): counts by job, by hour of day, by cause, and the first day.
func _miss_summary() -> Dictionary:
	var by_job := {}
	var by_hour := {}
	var by_cause := {}
	var by_day := {}
	for m in w.brain.miss_log:
		by_job[m[2]] = int(by_job.get(m[2], 0)) + 1
		var hr := str(int(m[1]))
		by_hour[hr] = int(by_hour.get(hr, 0)) + 1
		by_cause[m[3]] = int(by_cause.get(m[3], 0)) + 1
		var dk := str(int(m[0]) / 30)
		by_day[dk] = int(by_day.get(dk, 0)) + 1
	return {"total": w.brain.miss_log.size(), "by_job": by_job, "by_hour": by_hour, "by_cause": by_cause, "by_30_days": by_day, "first": w.brain.miss_log.slice(0, 12)}


func _role_of(o: Object) -> String:
	if o is NPC:
		var r: String = w.brain.buy_role(o)
		return r if r != "" else (o.role as String)
	return "player"


func _on_trade(buyer: Object, seller: Object, id: String, qty: int, total: int) -> void:
	var k := "%s>%s" % [_role_of(buyer), _role_of(seller)]
	if not flows.has(k):
		flows[k] = {"n": 0, "coins": 0, "items": {}}
	flows[k].n += qty
	flows[k].coins += total
	flows[k].items[id] = int(flows[k].items.get(id, 0)) + qty
