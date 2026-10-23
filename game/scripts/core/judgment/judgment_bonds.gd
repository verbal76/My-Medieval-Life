class_name JudgmentBonds
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19; owner directive 2026-10-23, docs/directives/2026-10-23_x19_foundations_round.md
## sections 4 and 5; register X19-FOUND-BONDS, X19-FOUND-FAMREP): the history of a pair of people and the reputation of
## a family, kept apart from regard (liking), trust (X19-REGARD, JudgmentStore.trust), moral judgment (NET) and
## personality. Nothing here is a second copy of any of them; it only READS them and keeps what none of them holds.
##
## Per pair (unordered), a history record, created once the pair has reached friendship level (friend_level, Relations'
## befriend_at):
##   peak        the highest regard (milli) the pair ever reached; never lowered
##   familiar    one flag, never a counter: set when a pair that reached friendship level falls back below it (a former
##               friend). Separations and reunions after that change nothing, so they cannot stack.
##   betrayals   a deed done by one to the other, who had been a friend (or whose regard once reached friendship level),
##               firsthand to the victim. Never erased, never softened: history stays when feelings change.
## Per direction (victim -> actor), resentment: milli-points, separate from regard, trust and NET. Raised by a bad deed done
## to the victim and known to them firsthand (severity x share x resentment_permille_of_severity). It does not fade with
## time: a serious grievance (severity at least serious_severity) cannot soften at all before floor_days after it
## (default one in-game year, Life.year_days()); afterwards it only softens through personality growth (the store's
## personality_growth(person), Worker A; treated as 0 until it exists) at soften_milli_per_day, shipped 0 (inert,
## owner pending: no decay curve is invented). Reaching 0 is neutrality: it restores neither regard nor trust.
##
## The two progression bonuses (a multiplier on a regard GAIN, applied by Relations only when judgment is attached, before
## the existing daily caps, so no cap is raised and no days-known gate is shortened):
##   familiarity    +familiarity_permille (100 = 10%) once the familiar flag is set, SUSPENDED while the pair has active
##                  negative standing: resentment above zero in either direction, or either one's NET of the other
##                  below negative_net_below (0). Persists after the former friendship level is restored.
##   family         +family_permille (50 = 5%) when one of the two holds a positive inherited impression of the other's
##                  family (family_reputation) and has not replaced it with experience of the person (override).
##   both           combined_permille (120 = 12%, the owner's number, not 100 + 50), not a formula. When the inherited
##                  impression is only partly intact, the bonus runs between the single and combined values by its weight.
##
## Family reputation (own value, computed on demand, nothing stored): the observer's impression of a subject's family =
## transmit(sum over the subject's relatives R, in reach, of  max(NET(observer, R), 0) x inherit_weight
##                                                       - max(-NET(observer, R), 0) x spill_weight).
## NET(observer, R) already comes only from stories the observer remembers or was told (the judgment memories), so a
## descendant knows exactly what they remember or were told. A relative's wrongdoing therefore reaches the subject as a
## small negative (spill_weight) without the deed or the NET moving to the subject, and trust (trust_of) is never touched.
## Personal experience gradually overrides: every judged contribution the observer holds about the subject lowers the
## impression's weight by override_permille_per_experience (all of it at 1000). Familiarity is not inherited.
##
## UNRESOLVED (owner pending; built as interfaces, shipped inert): reach (X19-SPILL-REACH) is "none" (reach_fn can be
## replaced: subject -> [[relative, inherit permille, spill permille]]), transmit (X19-REP-TRANSMIT) is the identity
## (transmit_fn replaces it), and the limits (X19-BOND-LIMITS) are agent placeholders in judgment.json "bonds".
## Event-driven only: nothing runs per frame or per person; the dawn step scans only pairs that carry resentment, and
## only when softening is configured.

const FAR := 1024
const MAXRES := 1000000

var cfg: Dictionary
var _s: WeakRef                     # the owning JudgmentStore (weak: it holds this object)
var pairs := {}                     # pair key -> PackedInt64Array [peak milli, familiar 0/1]
var betrayal_log := {}              # pair key -> [[victim, actor, day, event type], ...]
var resent := {}                    # directed key (victim, actor) -> PackedInt64Array [value, last day, serious day (-1), softened to day]

var friend_level := 25000           # milli regard of friendship (Relations befriend_at x 1000)
var _fam_p := 100
var _fa_p := 50
var _both_p := 120
var _serious := 1000
var _res_rate := 1000
var _floor := 0
var _soften := 0
var _neg_net := 0
var _qualify := 1
var _inh_w := 1000
var _spill_w := 300
var _override := 100
var _mode := "none"
var reach_fn := Callable()          # subject -> [[relative, inherit permille, spill permille], ...]; empty: by the mode
var growth_fn := Callable()         # person -> personality growth (a test seam; empty: the store's personality_growth when it exists, else 0)
var transmit_fn := Callable()       # (observer, subject, raw milli) -> milli; empty: the identity
var stats := {}


func _init(store, config: Dictionary = {}) -> void:
	_s = weakref(store)
	cfg = config
	_fam_p = int(cfg.get("familiarity_permille", 100))
	_fa_p = int(cfg.get("family_permille", 50))
	_both_p = int(cfg.get("combined_permille", 120))
	_serious = int(cfg.get("serious_severity", 1000))
	_res_rate = int(cfg.get("resentment_permille_of_severity", 1000))
	_floor = int(cfg.get("serious_floor_days", 0))
	_soften = int(cfg.get("soften_milli_per_day", 0))
	_neg_net = int(cfg.get("negative_net_below", 0))
	_qualify = int(cfg.get("qualify_net", 1))
	_inh_w = int(cfg.get("inherit_weight_permille", 1000))
	_spill_w = int(cfg.get("spill_weight_permille", 300))
	_override = int(cfg.get("override_permille_per_experience", 100))
	_mode = str(cfg.get("reach", "none"))
	var fl := int(cfg.get("friend_level", 0))
	if fl > 0:
		friend_level = fl * 1000
	else:
		var rel = GameData.b("relations")
		friend_level = int(round(float(rel.get("befriend_at", 25)) * 1000.0)) if rel is Dictionary else 25000


func store() -> JudgmentStore:
	return _s.get_ref() as JudgmentStore


func is_empty() -> bool:
	return pairs.is_empty() and betrayal_log.is_empty() and resent.is_empty()


static func _pk(a: int, b: int) -> int:
	return ((mini(a, b) + FAR) << 32) | (maxi(a, b) + FAR)


static func _dk(victim: int, actor: int) -> int:
	return ((victim + FAR) << 32) | (actor + FAR)


## One in-game year in days: the hard floor for a serious grievance, unless serious_floor_days sets another.
func floor_days() -> int:
	return _floor if _floor > 0 else Life.year_days()


# ---------------------------------------------------------------- history ------------------------
## Relations tells us a pair's regard changed (old -> new, 0..100). Keeps the peak and sets the familiar flag when a pair
## that reached friendship level has fallen back below it. Cheap: one dictionary lookup; a record exists only for pairs
## that reached friendship level.
func on_regard(a: int, b: int, old: float, now: float) -> void:
	var k := _pk(a, b)
	var rec = pairs.get(k)
	var top := int(round(maxf(old, now) * 1000.0))
	if rec == null:
		if top < friend_level:
			return
		rec = PackedInt64Array([top, 0])
		pairs[k] = rec
	elif top > rec[0]:
		rec[0] = top
	if rec[1] == 0 and rec[0] >= friend_level and int(round(now * 1000.0)) < friend_level:
		rec[1] = 1                                 # a former friend: one flag, whatever follows
		stats.familiar_set = int(stats.get("familiar_set", 0)) + 1


func peak(a: int, b: int) -> int:
	var rec = pairs.get(_pk(a, b))
	return 0 if rec == null else int(rec[0])


func familiar(a: int, b: int) -> bool:
	var rec = pairs.get(_pk(a, b))
	return rec != null and rec[1] == 1


func betrayals(a: int, b: int) -> Array:
	return (betrayal_log.get(_pk(a, b), []) as Array).duplicate(true)


func resentment(victim: int, actor: int) -> int:
	var r = resent.get(_dk(victim, actor))
	return 0 if r == null else int(r[0])


## Active negative standing (documented): resentment above zero in either direction, or either one's NET of the other
## below negative_net_below. Reads the judgment ledgers; used only for pairs that carry the familiar flag.
func negative_standing(a: int, b: int) -> bool:
	if resentment(a, b) > 0 or resentment(b, a) > 0:
		return true
	var s := store()
	return s != null and (s.net(a, b) < _neg_net or s.net(b, a) < _neg_net)


## The store learned `ev` firsthand (participant or witness) for the first time: a victim of a bad deed gains resentment
## toward each actor, and a betrayal is recorded when the actor had been their friend.
func on_belief(observer: int, ev: int) -> void:
	var s := store()
	if s == null or not s.facts.has(ev):
		return
	var f: PackedInt64Array = s.facts[ev]
	var t := f[JudgmentStore.F_TYPE]
	if s._pol[t] >= 0:
		return
	var vic := JudgmentStore._fact_people(f, 0)
	if not vic.has(observer):
		return
	var sev: int = s._sev[t]
	for a in JudgmentStore._fact_actors(f):
		var actor := int(a[0])
		if actor == observer:
			continue
		var add := JudgmentMath.mul_div(JudgmentMath.mul_div(sev, int(a[1]), 1000), _res_rate, 1000)
		var dk := _dk(observer, actor)
		var r: PackedInt64Array = resent.get(dk, PackedInt64Array([0, -1, -1, s.day]))
		if r[0] == 0:
			r[3] = s.day                           # a fresh grievance: any softening counts from now
		r[0] = mini(MAXRES, r[0] + add)
		r[1] = s.day
		if sev >= _serious:
			r[2] = s.day
		resent[dk] = r
		stats.grievances = int(stats.get("grievances", 0)) + 1
		var k := _pk(observer, actor)
		var was_friend: bool = peak(observer, actor) >= friend_level or s.social.friends(observer, actor)
		if was_friend:
			if not betrayal_log.has(k):
				betrayal_log[k] = []
			(betrayal_log[k] as Array).append([observer, actor, f[JudgmentStore.F_DAY], str(s._types[t])])
			stats.betrayals = int(stats.get("betrayals", 0)) + 1


## The daily step (Store.begin_day): resentment softens only through personality growth, and a serious grievance not
## before its floor. With softening shipped at 0 or no personality_growth, this does nothing and costs nothing.
func dawn(d: int) -> void:
	if _soften <= 0 or resent.is_empty():
		return
	var s := store()
	if s == null or not (growth_fn.is_valid() or s.has_method("personality_growth")):
		return
	var ks := resent.keys()
	ks.sort()
	for dk in ks:
		var r: PackedInt64Array = resent[dk]
		var start := int(r[3])                     # softened up to this day
		if r[2] >= 0:
			start = maxi(start, int(r[2]) + floor_days())   # a serious grievance: nothing before its floor
		var days := d - start
		r[3] = maxi(int(r[3]), d)
		if days <= 0 or r[0] <= 0:
			continue
		var victim := int((dk >> 32) - FAR)
		var g := maxi(0, int(growth_fn.call(victim) if growth_fn.is_valid() else s.call("personality_growth", victim)))
		r[0] = maxi(0, r[0] - JudgmentMath.mul_div(_soften * days, g, 1000))
		resent[dk] = r


# ---------------------------------------------------------------- family reputation --------------
## The relatives whose stories count toward `subject`'s family: [[relative, inherit permille, spill permille], ...].
func reach(subject: int) -> Array:
	if reach_fn.is_valid():
		return reach_fn.call(subject)
	if _mode == "none":
		return []
	var s := store()
	if s == null:
		return []
	var out := []
	for r in s.social.relatives(subject):
		var kind := str(r[1])
		if kind == "parent" or kind == "child" or (_mode == "family" and (kind == "sibling" or kind == "partner")):
			out.append([int(r[0]), _inh_w, _spill_w])
	return out


## `observer`'s inherited impression of `subject`'s family, milli-points (positive or negative): the stories they hold
## about the subject's relatives, the good as an inheritance, the bad as a small spillover. Not the subject's own NET.
func family_reputation(observer: int, subject: int) -> int:
	var s := store()
	if s == null:
		return 0
	var raw := 0
	for r in reach(subject):
		var rel := int(r[0])
		if rel == observer or rel == subject:
			continue
		var n := s.net(observer, rel)
		if n > 0:
			raw += JudgmentMath.mul_div(n, int(r[1]), 1000)
		elif n < 0:
			raw += JudgmentMath.mul_div(n, int(r[2]), 1000)
	if transmit_fn.is_valid():
		return int(transmit_fn.call(observer, subject, raw))
	return raw


## How much of the inherited impression is left, permille: experience of the person replaces it (each contribution the
## observer holds about the subject, override_permille_per_experience).
func inherited_weight(observer: int, subject: int) -> int:
	var s := store()
	if s == null:
		return 0
	if family_reputation(observer, subject) < _qualify:
		return 0
	var used := int((s.ledger(observer, subject) as Array)[2]) * _override
	return maxi(0, 1000 - used)


# ---------------------------------------------------------------- the multiplier -----------------
## The multiplier on a regard gain between a and b, permille (1000: none). Called by Relations for every positive regard
## gain when judgment is attached; two dictionary lookups unless the pair is a former friend or reach is configured.
func gain_permille(a: int, b: int) -> int:
	var fam := false
	var rec = pairs.get(_pk(a, b))
	if rec != null and rec[1] == 1:
		fam = not negative_standing(a, b)
	var w := 0
	if _mode != "none" or reach_fn.is_valid():
		w = maxi(inherited_weight(a, b), inherited_weight(b, a))
	if not fam and w == 0:
		return 1000
	var bonus: int
	if fam and w > 0:
		bonus = _fam_p + JudgmentMath.mul_div(_both_p - _fam_p, w, 1000)
	elif fam:
		bonus = _fam_p
	else:
		bonus = JudgmentMath.mul_div(_fa_p, w, 1000)
	return 1000 + bonus


## A gain scaled by gain_permille (the float Relations works in).
func boost(a: int, b: int, gain: float) -> float:
	var m := gain_permille(a, b)
	return gain if m == 1000 else gain * float(m) / 1000.0


# ---------------------------------------------------------------- saving --------------------------
## The optional "bonds" key of the judgment section; older saves have none.
func to_dict() -> Dictionary:
	var ps := []
	var ks := pairs.keys()
	ks.sort()
	for k in ks:
		var r: PackedInt64Array = pairs[k]
		ps.append([int((k >> 32) - FAR), int((k & 0xFFFFFFFF) - FAR), r[0], r[1]])
	var bs := []
	var bk := betrayal_log.keys()
	bk.sort()
	for k in bk:
		for row in betrayal_log[k]:
			bs.append((row as Array).duplicate())
	var rs := []
	var rk := resent.keys()
	rk.sort()
	for k in rk:
		var r: PackedInt64Array = resent[k]
		rs.append([int((k >> 32) - FAR), int((k & 0xFFFFFFFF) - FAR), r[0], r[1], r[2], r[3]])
	return {"pairs": ps, "betrayals": bs, "resentment": rs}


func load_dict(d: Dictionary) -> void:
	pairs.clear()
	betrayal_log.clear()
	resent.clear()
	for r in d.get("pairs", []):
		pairs[_pk(int(r[0]), int(r[1]))] = PackedInt64Array([int(r[2]), int(r[3])])
	for r in d.get("betrayals", []):
		var k := _pk(int(r[0]), int(r[1]))
		if not betrayal_log.has(k):
			betrayal_log[k] = []
		(betrayal_log[k] as Array).append([int(r[0]), int(r[1]), int(r[2]), str(r[3])])
	for r in d.get("resentment", []):
		resent[_dk(int(r[0]), int(r[1]))] = PackedInt64Array([int(r[2]), int(r[3]), int(r[4]), int(r[5])])
