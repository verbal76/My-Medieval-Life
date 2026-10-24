extends SceneTree
## Expansion 19 (owner decision SJD-Q02, 2026-10-21; rate approved X19-DECAY, 2026-10-23): demonstrates the long-term
## effect of the ordinary judgment decay at several rates beside the approved one. A judgment-only scenario over 365 game days (a game
## year is 8 days: 365 days is about 45 game years): on day 0 Bob is robbed ten times by a thief (10 BAD), sees the same
## thief murder his cousin (kin: 3 x 0.55 = 1.65 BAD, permanent), and is helped twenty times by a neighbour
## (20 x 0.5 = 10 GOOD). It prints Bob's NET judgment of each at days 0, 8, 30, 90, 180 and 365 for several rates,
## the approved one (judgment.json decay.ordinary_permille_per_day, 42: a half-life of 16 game days, 2 game years) always
## among them and marked, and the disposition the trade decisions would read. It checks the invariants: the murder part
## never decays at any rate, fading parts never grow and never go below 0, the lifetime totals are kept, the approved
## rate's half-life is the configured half_life_days, and the result is deterministic.
##   godot --headless --path game --script res://tests/judgment_decay_demo.gd

var failures := 0
var checks := 0
const BOB := 1
const COUSIN := 2
const THIEF := 7
const HELPER := 8
const RATES := [0, 1, 2, 3, 5, 10]
const DAYS := [0, 8, 30, 90, 180, 365]


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)
	else:
		print("ok   ", what)


func _init() -> void:
	var decay: Dictionary = JudgmentStore.default_cfg().decay
	var approved := int(decay.ordinary_permille_per_day)
	var rates: Array = RATES.duplicate()
	if not rates.has(approved):
		rates.append(approved)                               # the configured rate is always demonstrated (X19-DECAY: 42)
	rates.sort()
	check(approved > 0 and roundi(log(0.5) / log(1.0 - approved / 1000.0)) == int(decay.half_life_days), "the approved rate %d permille a day halves in the configured %d days" % [approved, int(decay.half_life_days)])
	print("Q02 decay demonstration: Bob's NET judgment, points, at days 0, 8, 30, 90, 180, 365 (the disposition the decisions read, 0..100, below each rate)")
	print("rate permille/day | half-life days | thief: 10 thefts             | thief: 10 thefts + murder of kin | helper: 20 helps")
	var hashes := {}
	for rate in rates:
		var r := run(rate)
		var line := "%3d%s | %14s | " % [rate, " (approved)" if rate == approved else "           ", "none" if rate == 0 else "%d" % roundi(log(0.5) / log(1.0 - rate / 1000.0))]
		for who in ["thief", "both", "helper"]:
			var bits := []
			for d in DAYS:
				bits.append("%s" % JudgmentMath.pts(int(r[who][d])).trim_suffix("0").trim_suffix("0"))
			line += ", ".join(bits) + " | "
		print(line)
		hashes[rate] = r.hash
		check(int(r.perm_part[365]) == int(r.perm_part[0]) and int(r.perm_part[0]) == 1650, "rate %d: the murder's part is 1.65 BAD on day 0 and on day 365 (never decays)" % rate)
		check(r.monotone, "rate %d: fading parts never grow and never go below 0" % rate)
		check(int(r.life_bad) == 11650 and int(r.life_good) == 10000, "rate %d: the lifetime totals stay (11.65 BAD, 10 GOOD) as history" % rate)
		if rate > 0:
			check(int(r.thief[365]) > -10000 and int(r.both[365]) <= -1650, "rate %d: after a year the thefts have faded but the murder holds the opinion at least at -1.65" % rate)
		print("     disposition toward the thief (thefts + murder): day 0 %s, day 90 %s, day 365 %s" % [JudgmentMath.pts(int(r.disp[0])), JudgmentMath.pts(int(r.disp[90])), JudgmentMath.pts(int(r.disp[365]))])
	check(run(approved).hash == hashes[approved], "the same scenario gives the same result twice")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func run(rate: int) -> Dictionary:
	var c := JudgmentStore.default_cfg()
	c.decay.ordinary_permille_per_day = rate
	c.interpret.morality_spread_permille = 0
	var j := JudgmentStore.new(c, JudgmentSocial.new().set_kin(BOB, COUSIN), 3)
	for i in 10:
		j.observe(j.publish("theft", [THIEF], [BOB]), BOB)
	var j2 := JudgmentStore.new(c, JudgmentSocial.new().set_kin(BOB, COUSIN), 3)
	for i in 10:
		j2.observe(j2.publish("theft", [THIEF], [BOB]), BOB)
	j2.observe(j2.publish("killing", [THIEF], [COUSIN]), BOB)
	for i in 20:
		j2.observe(j2.publish("help_minor", [HELPER], [], [BOB]), BOB)
	var out := {"thief": {}, "both": {}, "helper": {}, "perm_part": {}, "disp": {}, "monotone": true}
	var last := [1 << 40, 1 << 40, 1 << 40]
	for d in 366:
		if d > 0:
			j.advance_day(d)
			j2.advance_day(d)
		var l := j2.ledger(BOB, THIEF)
		var g := j2.ledger(BOB, HELPER)
		for v in [l[3], l[4], g[3]]:
			if int(v) < 0:
				out.monotone = false
		if int(l[4]) > last[0] or int(g[3]) > last[1]:
			out.monotone = false
		last = [int(l[4]), int(g[3]), 0]
		if DAYS.has(d):
			out.thief[d] = j.net(BOB, THIEF)
			out.both[d] = j2.net(BOB, THIEF)
			out.helper[d] = j2.net(BOB, HELPER)
			out.perm_part[d] = int(l[6])
			out.disp[d] = j2.disposition(BOB, THIEF)
	out.life_bad = j2.ledger(BOB, THIEF)[1]
	out.life_good = j2.ledger(BOB, HELPER)[0]
	out.hash = j2.state_hash()
	return out
