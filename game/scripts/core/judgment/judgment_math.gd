class_name JudgmentMath
extends RefCounted
## PROSPECTIVE (Expansion 19, PROS-19): the fixed-point arithmetic and seeded hashing the judgment system uses, so
## every result is exact on every machine (spec s.5.1: "integer milli-points ... for deterministic replay and save
## compatibility"; CLAUDE.md section 6). Points are integer milli-points (1000 = 1 point); fractions are integer
## permille (1000 = 1.0). Random draws come from a hash of the world seed and the ids involved, never from World.rng,
## so turning judgment on cannot shift any existing random stream (spec s.16).

const ONE := 1000


## a * b / d, rounded half away from zero (GDScript's integer division truncates toward zero).
static func mul_div(a: int, b: int, d: int) -> int:
	var p := a * b
	var neg := (p < 0) != (d < 0)
	var q := absi(p) / absi(d)
	var r := absi(p) % absi(d)
	if r * 2 >= absi(d):
		q += 1
	return -q if neg else q


## a x p (permille), rounded.
static func scale(a: int, permille: int) -> int:
	return mul_div(a, permille, ONE)


static func clampi_(v: int, lo: int, hi: int) -> int:
	return mini(hi, maxi(lo, v))


## A 31-bit hash of a list of integers (32-bit FNV-1a over each integer's eight bytes, kept below 2^56 at every step
## so nothing overflows): the same inputs give the same value everywhere.
static func hash_ints(xs: Array) -> int:
	var h := 2166136261
	for x in xs:
		var v := int(x)
		for i in 8:
			h = h ^ ((v >> (i * 8)) & 0xFF)
			h = (h * 16777619) & 0xFFFFFFFF
	return (h ^ (h >> 16)) & 0x7FFFFFFF


## A seeded roll in 0..999 from the ids involved (no RNG state is kept or advanced).
static func roll(xs: Array) -> int:
	return hash_ints(xs) % 1000


## Points as text for traces: -6590 -> "-6.590".
static func pts(milli: int) -> String:
	var s := "-" if milli < 0 else ""
	return "%s%d.%03d" % [s, absi(milli) / 1000, absi(milli) % 1000]
