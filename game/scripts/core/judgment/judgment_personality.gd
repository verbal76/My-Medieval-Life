class_name JudgmentPersonality
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19; owner directive 2026-10-23 `x19_foundations_round`, sections 2 and 3): the
## personality FRAMEWORK that extends the store's temperament (tolerance, the `life` shifts of SJD-Q03/Q13). It holds,
## per person and each kept apart from moral judgment (NET), trust, regard, resentment and family reputation:
##   - TRAITS that drift from experience (`tolerance` extends JudgmentStore.tolerance; `stubbornness`);
##   - PRACTICAL WISDOM learnt from costly mistakes (per kind of situation, with a share carried to every situation);
##   - TEMPORARY EMOTION: anger with a timer in game days, a peak that is remembered, and a stubborn override;
##   - an EVENT HISTORY (`record`) of every experience, never erased even when the feelings it caused fade.
## The framework is mechanism only. NO number here is approved: every rate, limit and duration lives in judgment.json
## section "traits" as a placeholder that leaves the behaviour inert (owner formula pending, X19-PERS-FORMULA and
## X19-TRAIT-DIST); tests give fixture values. Each curve's SHAPE is one function in `curves` (below), replaceable
## without touching the rest. Approved and shipped: about 30% of villagers (a fixed per-person hash, never a roll per
## decision) have a potential for self-defeating stubbornness (`traits.stubbornness_share_permille`, 300).
## Event driven: the store calls `experience` when a firsthand deed touches a person; nothing runs per frame or per
## day (anger fades on read). With every rate at 0 `active` is false, nothing is recorded and nothing is saved.

const FORMAT_V := 1
const TRAITS := ["tolerance", "stubbornness"]
const T_TOL := 0
const T_STUB := 1
const CH_PROVOKE := 1       # history channels
const CH_POSITIVE := 2
const CH_MISTAKE := 3
const CH_REMIND := 4
const LOGW := 7             # a history row: day, channel, subject, severity (milli-points), delta trait 0, delta trait 1, extra (wisdom gain / anger)

var world_seed := 0
var c := {}                           # the "traits" config section
var active := false                   # any rate above 0: otherwise the whole layer is inert
var drift := {}                       # person -> [tolerance drift, stubbornness drift] permille from origin (saved)
var anger := {}                       # person -> [intensity at set, set day, duration days, peak, override until day] (saved)
var wisdom := {}                      # person -> {kind hash (0 = carried to every situation) -> permille} (saved)
var record := {}                       # person -> PackedInt64Array of LOGW-wide rows, oldest first, never erased (saved)

var _share := 300
var _start := 0
var _rate := 0
var _eff := {}
var _f_window := 0
var _f_gain := 0
var _f_cap := 0
var _d_gain := 0
var _d_cap := 0
var _soft := 0
var _floor := 0
var _recover := 1000
var _l_rate := 0
var _l_window := 0
var _l_accel := 0
var _l_cap := 0
var _l_transfer := 0
var _l_limit := 0
var _a_rate := 0
var _a_days := 0
var _a_remind := 0
var _a_cap := 0
var _o_at := 1000
var _o_days := 0

## The curve shapes, one place. Replace an entry (a Callable with the same arguments) to change a shape.
var curves := {
	"shift": JudgmentPersonality.curve_shift,
	"resistance": JudgmentPersonality.curve_resistance,
	"learn": JudgmentPersonality.curve_learn,
	"fade": JudgmentPersonality.curve_fade,
	"reminder": JudgmentPersonality.curve_reminder,
}


# ---------------------------------------------------------------- curves (pluggable shapes) ------
## Size of one experience's pull on a trait, permille: severity (milli-points) x rate (permille a point), made larger
## by how often the same kind happened lately (`freq` earlier ones within the window) and how long it lasted.
static func curve_shift(severity: int, rate: int, freq: int, f_gain: int, dur_days: int, d_gain: int) -> int:
	var v := JudgmentMath.mul_div(severity, rate, 1000)
	v = JudgmentMath.mul_div(v, 1000 + f_gain * freq, 1000)
	return JudgmentMath.mul_div(v, 1000 + d_gain * dur_days, 1000)


## How much of a pull still works when it pushes a value AWAY from its origin by `away` permille: 1000 at the origin,
## falling to `floor` at the soft limit `scale` and staying there (never 0: no wall). scale 0 switches resistance off.
static func curve_resistance(away: int, scale: int, floor_: int) -> int:
	if scale <= 0 or away <= 0:
		return 1000
	return maxi(maxi(floor_, 1), 1000 - JudgmentMath.mul_div(1000, away, scale))


## Wisdom gained from one costly mistake: cost (milli-points) x rate, accelerated by `repeats` similar earlier ones.
static func curve_learn(cost: int, rate: int, repeats: int, accel: int) -> int:
	return JudgmentMath.mul_div(JudgmentMath.mul_div(cost, rate, 1000), 1000 + accel * repeats, 1000)


## An emotion's strength `elapsed` days after it was set, fading to 0 over `duration` days (linear).
static func curve_fade(intensity: int, elapsed: int, duration: int) -> int:
	if duration <= 0 or elapsed >= duration:
		return 0
	return JudgmentMath.mul_div(intensity, duration - maxi(elapsed, 0), duration)


## Anger after a reminder: today's level plus `remind` permille of the remembered peak, never above `cap` of the peak
## (modest: a reminder cannot bring back the whole first rage).
static func curve_reminder(cur: int, peak: int, remind: int, cap: int) -> int:
	return maxi(cur, mini(cur + JudgmentMath.mul_div(peak, remind, 1000), JudgmentMath.mul_div(peak, cap, 1000)))


# ---------------------------------------------------------------- set up --------------------------
func _init(config: Dictionary = {}, seed := 0) -> void:
	world_seed = seed
	configure(config)


func configure(config: Dictionary) -> void:
	c = config
	_share = clampi(int(c.get("stubbornness_share_permille", 300)), 0, 1000)
	_start = int(c.get("stubbornness_start_permille", 0))
	_rate = int(c.get("rate_permille_per_point", 0))
	_eff = c.get("effects", {})
	var f: Dictionary = c.get("frequency", {})
	_f_window = int(f.get("window_days", 0))
	_f_gain = int(f.get("gain_permille", 0))
	_f_cap = int(f.get("cap", 0))
	var d: Dictionary = c.get("duration", {})
	_d_gain = int(d.get("gain_permille_per_day", 0))
	_d_cap = int(d.get("cap_days", 0))
	var s: Dictionary = c.get("soft_limit", {})
	_soft = int(s.get("scale_permille", 0))
	_floor = int(s.get("floor_permille", 0))
	_recover = int(c.get("recovery_gain_permille", 1000))
	var l: Dictionary = c.get("learning", {})
	_l_rate = int(l.get("rate_permille_per_point", 0))
	_l_window = int(l.get("repeat_window_days", 0))
	_l_accel = int(l.get("accel_permille_per_repeat", 0))
	_l_cap = int(l.get("repeat_cap", 0))
	_l_transfer = int(l.get("transfer_permille", 0))
	_l_limit = int(l.get("limit_permille", 0))
	var e: Dictionary = c.get("emotion", {})
	_a_rate = int(e.get("anger_permille_per_point", 0))
	_a_days = int(e.get("anger_days", 0))
	_a_remind = int(e.get("reminder_permille", 0))
	_a_cap = int(e.get("reminder_cap_permille", 0))
	_o_at = int(e.get("override_threshold_permille", 1000))
	_o_days = int(e.get("override_days", 0))
	active = _rate > 0 or _l_rate > 0 or _a_rate > 0


func is_empty() -> bool:
	return drift.is_empty() and anger.is_empty() and wisdom.is_empty() and record.is_empty()


func clear() -> void:
	drift.clear()
	anger.clear()
	wisdom.clear()
	record.clear()


# ---------------------------------------------------------------- reading ------------------------
## Whether `person` has the potential for self-defeating stubbornness: a fixed hash of the world seed and the id, so
## about stubbornness_share_permille / 1000 of any population (approved: about 30%); never a roll per decision.
func holds_stubbornness(person: int) -> bool:
	return _share > 0 and JudgmentMath.hash_ints([world_seed, person, 7211]) % 1000 < _share


func trait_drift(person: int, which: int) -> int:
	return int((drift[person] as Array)[which]) if drift.has(person) else 0


## The tolerance drift (permille) that JudgmentStore.tolerance adds to temperament and the `life` shift.
func tolerance_drift(person: int) -> int:
	return trait_drift(person, T_TOL)


## Stubbornness level in permille: 0 for a person without the potential; else the starting level plus drift, never
## below 0. While a stubborn override is running (see `provoke`) a holder is at least back at the starting level.
func stubbornness(person: int, today: int) -> int:
	if not holds_stubbornness(person):
		return 0
	var lv := maxi(0, _start + trait_drift(person, T_STUB))
	if anger.has(person) and int((anger[person] as Array)[4]) > today:
		lv = maxi(lv, _start)
	return lv


## Whether the person is inside an emotional override of their stubbornness today.
func overriding(person: int, today: int) -> bool:
	return holds_stubbornness(person) and anger.has(person) and int((anger[person] as Array)[4]) > today


## Anger today, permille, fading from the day it was set.
func anger_at(person: int, today: int) -> int:
	if not anger.has(person):
		return 0
	var a: Array = anger[person]
	return int(curves.fade.call(int(a[0]), today - int(a[1]), int(a[2])))


## The most anger the person has ever felt (remembered, so a reminder can modestly revive it).
func anger_peak(person: int) -> int:
	return int((anger[person] as Array)[3]) if anger.has(person) else 0


## Practical wisdom in a kind of situation, permille: what was learnt there plus what carried over from everywhere.
func practical_wisdom(person: int, kind: String) -> int:
	if not wisdom.has(person):
		return 0
	var w: Dictionary = wisdom[person]
	return clampi(int(w.get(kind_code(kind), 0)) + int(w.get(0, 0)), 0, 1000)


## The part of wisdom that applies to every situation (the share carried over from lessons anywhere).
func general_wisdom(person: int) -> int:
	return int((wisdom[person] as Dictionary).get(0, 0)) if wisdom.has(person) else 0


## Growth permille for other systems (Worker B's resentment softening): positive development only, 0 = none. The
## tolerance drift above origin, the stubbornness shed below the starting level (holders) and carried-over wisdom,
## added and capped at 1000. Never negative: a worsening is not growth.
func growth(person: int) -> int:
	var g := maxi(0, trait_drift(person, T_TOL)) + general_wisdom(person)
	if holds_stubbornness(person):
		g += mini(maxi(0, -trait_drift(person, T_STUB)), _start)
	return clampi(g, 0, 1000)


static func kind_code(kind: String) -> int:
	return kind.hash() & 0x7FFFFFFF


## How many rows of `channel` (and `subject`, unless -1) the person's history holds within `window` days before today.
func recent(person: int, channel: int, subject: int, today: int, window: int) -> int:
	if window <= 0 or not record.has(person):
		return 0
	var rows: PackedInt64Array = record[person]
	var n := 0
	var i := rows.size() - LOGW
	while i >= 0 and rows[i] > today - window:
		if rows[i + 1] == channel and (subject < 0 or rows[i + 2] == subject):
			n += 1
		i -= LOGW
	return n


func history(person: int) -> PackedInt64Array:
	return record.get(person, PackedInt64Array())


# ---------------------------------------------------------------- experiences --------------------
## A meaningful experience: `kind` "provocation" (a wrong done to them) or "positive" (kindness, security). `severity`
## in milli-points, `duration_days` how long it lasted (0: a single event). Moves each trait the config names for it
## (frequency, severity and duration are the inputs); a provocation also raises anger. Recorded in the history.
func experience(person: int, kind: String, severity: int, today: int, duration_days := 0) -> void:
	if not active or severity <= 0:
		return
	var ch := CH_PROVOKE if kind == "provocation" else CH_POSITIVE
	var freq := mini(recent(person, ch, -1, today, _f_window), _f_cap)
	var mag := int(curves.shift.call(severity, _rate, freq, _f_gain, mini(duration_days, _d_cap), _d_gain))
	var ds := [0, 0]
	var ef: Dictionary = _eff.get(kind, {})
	for i in TRAITS.size():
		var w := int(ef.get(TRAITS[i], 0))
		if w == 0 or mag == 0 or (i == T_STUB and not holds_stubbornness(person)):
			continue
		ds[i] = _apply(person, i, JudgmentMath.mul_div(mag, w, 1000))
	var shown := 0
	if ch == CH_PROVOKE:
		shown = _provoke(person, severity, today)
	_log(person, today, ch, 0, severity, ds[0], ds[1], shown)


## Move a trait by `want` permille: a push away from the origin meets the soft limit's rising resistance (never a
## wall); a push back toward it is the recovery, scaled by recovery_gain. Returns the change made.
func _apply(person: int, which: int, want: int) -> int:
	var rec: Array = drift.get(person, [0, 0])
	var cur := int(rec[which])
	var out := (cur >= 0 and want > 0) or (cur <= 0 and want < 0)
	var amt := want
	if cur != 0 and out:
		amt = JudgmentMath.mul_div(want, int(curves.resistance.call(absi(cur), _soft, _floor)), 1000)
	elif not out:
		amt = JudgmentMath.mul_div(want, _recover, 1000)
	rec[which] = cur + amt
	drift[person] = rec
	return amt


## Anger from a provocation: adds to what is left, restarts the timer, remembers the peak; strong enough anger starts
## a stubborn override for override_days (holders only).
func _provoke(person: int, severity: int, today: int) -> int:
	if _a_rate <= 0 or _a_days <= 0:
		return 0
	var cur := anger_at(person, today)
	var lvl := mini(1000, cur + JudgmentMath.mul_div(severity, _a_rate, 1000))
	var old: Array = anger.get(person, [0, 0, 0, 0, 0])
	var until := int(old[4])
	if lvl >= _o_at and _o_days > 0 and holds_stubbornness(person):
		until = maxi(until, today + _o_days)
	anger[person] = [lvl, today, _a_days, maxi(int(old[3]), lvl), until]
	return lvl


## A reminder of a past wrong (a retelling, the wrongdoer seen again): modestly reactivates remembered anger. Returns
## the anger after the reminder. Nothing happens for a person who was never angry.
func remind(person: int, today: int) -> int:
	if not active or _a_remind <= 0 or not anger.has(person):
		return anger_at(person, today)
	var a: Array = anger[person]
	var cur := anger_at(person, today)
	var lvl := int(curves.reminder.call(cur, int(a[3]), _a_remind, _a_cap))
	if lvl > cur:
		anger[person] = [lvl, today, _a_days, int(a[3]), int(a[4])]
		_log(person, today, CH_REMIND, 0, 0, 0, 0, lvl)
	return lvl


## A costly mistake of a kind (`kind` names the kind of situation, `cost` in milli-points). The lesson grows faster
## when similar mistakes repeat within the window, and a share carries over to every situation. Wisdom only grows.
func mistake(person: int, kind: String, cost: int, today: int) -> int:
	if _l_rate <= 0 or cost <= 0:
		return 0
	var code := kind_code(kind)
	var reps := mini(recent(person, CH_MISTAKE, code, today, _l_window), _l_cap)
	var gain := int(curves.learn.call(cost, _l_rate, reps, _l_accel))
	var w: Dictionary = wisdom.get(person, {})
	var cur := int(w.get(code, 0))
	gain = JudgmentMath.mul_div(gain, int(curves.resistance.call(cur, _l_limit, _floor)), 1000)
	w[code] = cur + gain
	w[0] = int(w.get(0, 0)) + JudgmentMath.mul_div(gain, _l_transfer, 1000)
	wisdom[person] = w
	_log(person, today, CH_MISTAKE, code, cost, 0, 0, gain)
	return gain


func _log(person: int, today: int, ch: int, subject: int, sev: int, d0: int, d1: int, extra: int) -> void:
	var rows: PackedInt64Array = record.get(person, PackedInt64Array())
	rows.append_array(PackedInt64Array([today, ch, subject, sev, d0, d1, extra]))
	record[person] = rows


# ---------------------------------------------------------------- saving -------------------------
## The optional "traits" key of the judgment section: lists sorted by person, so the same state writes the same text.
## {} when nothing has been recorded (a save without the key loads as defaults).
func to_dict() -> Dictionary:
	if is_empty():
		return {}
	var dr := []
	for p in _sorted(drift):
		dr.append([int(p), int(drift[p][0]), int(drift[p][1])])
	var an := []
	for p in _sorted(anger):
		var a: Array = anger[p]
		an.append([int(p), int(a[0]), int(a[1]), int(a[2]), int(a[3]), int(a[4])])
	var ws := []
	for p in _sorted(wisdom):
		for k in _sorted(wisdom[p]):
			ws.append([int(p), int(k), int(wisdom[p][k])])
	var lg := []
	for p in _sorted(record):
		var rows: PackedInt64Array = record[p]
		for i in range(0, rows.size(), LOGW):
			var row := [int(p)]
			for k in LOGW:
				row.append(rows[i + k])
			lg.append(row)
	return {"v": FORMAT_V, "drift": dr, "anger": an, "wisdom": ws, "log": lg}


## "" when the saved key can be read (absent or empty is fine), else why not (a newer layout is kept, never dropped).
static func error_of(d) -> String:
	if d == null or (d is Dictionary and (d as Dictionary).is_empty()):
		return ""
	if not (d is Dictionary):
		return "judgment section 'traits' is not a dictionary: kept unread"
	if int((d as Dictionary).get("v", 0)) > FORMAT_V:
		return "judgment section 'traits' version %d is newer than this game's %d: kept unread" % [int(d.v), FORMAT_V]
	return ""


func load_dict(d: Dictionary) -> void:
	clear()
	for r in d.get("drift", []):
		drift[int(r[0])] = [int(r[1]), int(r[2])]
	for r in d.get("anger", []):
		anger[int(r[0])] = [int(r[1]), int(r[2]), int(r[3]), int(r[4]), int(r[5])]
	for r in d.get("wisdom", []):
		if not wisdom.has(int(r[0])):
			wisdom[int(r[0])] = {}
		wisdom[int(r[0])][int(r[1])] = int(r[2])
	for r in d.get("log", []):
		var rows: PackedInt64Array = record.get(int(r[0]), PackedInt64Array())
		for k in LOGW:
			rows.append(int(r[1 + k]))
		record[int(r[0])] = rows


static func _sorted(d: Dictionary) -> Array:
	var ks := d.keys()
	ks.sort()
	return ks
