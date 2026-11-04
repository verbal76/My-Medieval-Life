extends RefCounted
## B25R1-018 phase 3, second pass (owner directive 2026-11-03 section 4: "They should not be rows of identical houses ... Do not
## force every settlement into the same rectangular template"; owner B25R1-Q8: owned art, much better layouts): a settlement
## laid out the way a medieval place grows, as a pure function of the seed and the settlement.
##
## - A main street runs north-south through the place, bending gently (an integer wave: deterministic on every machine); in a
##   town it widens into a market place, a lens of open paving.
## - Cross streets branch from it east and west, bending too, of different lengths on each side; more are added, alternately
##   north and south, while buildings still need frontage.
## - Buildings front the streets: along a cross street they stand on its north side with their doors on it; along the main
##   street they stand gable-on beside it, a footpath from the door to the street. Each line of frontage takes the next
##   building where it fits; the gaps between them and the set-back from the street vary (terraced in a town, straggling in a
##   hamlet), and the houses differ in width, depth and roof (region_stamps.json house_*, manor; thatch looks).
## - Behind the houses: fenced gardens, vegetable plots, sheds, wood piles and barrels; wells along the streets; a fenced
##   churchyard with its graves beside each church.
## - A walled town (Higham) is planned inside, then walled round with a gate where the main street goes out north and south,
##   straight through the gates; outside the south gate the road runs on with houses straggling along it, and "the Way" runs
##   east-west under the walls. The castle stands beyond the north-east corner.
## Every household of the founding still has a home and every business its building (slot order as before: the businesses in
## settlements.json order, the homes in OffMapSettlement's household order, the spares, then the civic buildings, the walls,
## the castle and keep). Returns the same fields as before plus "props" (yard pieces, drawn and solid like buildings, not
## entered) and "entries" ([N, E, S, W] cells where the roads come in).

const OW := preload("res://scripts/core/overworld.gd")

var ow                           # the Overworld (its seed, hash32)
var si := 0
var stamps: Dictionary
var cx := 0
var cy := 0
var occ := {}                    # cell -> 1 street, 2 building, 3 path or kept open, 4 yard piece
var streets: Array = []          # arrays of cells (each street, the market, the footpaths)
var main := {}                   # y -> [left x, right x] of the main street
var straight := {}               # y -> centre x forced (through the town gates)
var mw := 3                      # main street width
var m_amp := 2
var m_per := 28
var market := Rect2i()           # rows and extent of the market place
var cross: Array = []            # {base, x0, x1, amp, per, salt}
var lines: Array = []            # frontage: {t: "N"/"M", ...cursor}
var gap_lo := 1
var gap_hi := 3
var placed: Array = []           # [{rect, stamp, home}] every building placed (for the yards)
var props: Array = []


func h(k: int, salt: int) -> int:
	return OW.hash32(ow.seed, si, k, salt)


## A smooth integer wave: control offsets in [-amp, amp] every `per` steps, joined linearly (one cell a step at most).
func wave(i: int, per: int, amp: int, salt: int) -> int:
	if amp <= 0:
		return 0
	var k := OW.fdiv(i, per)
	var t := i - k * per
	var a := h(k, salt) % (2 * amp + 1) - amp
	var b := h(k + 1, salt) % (2 * amp + 1) - amp
	return a + (b - a) * t / per


func mark(c: Vector2i, v: int) -> void:
	if v == 1 or not occ.has(c) or int(occ[c]) == 3:
		occ[c] = v


func main_x(y: int) -> int:
	if straight.has(y):
		return int(straight[y])
	return cx + wave(y, m_per, m_amp, 961)


func market_extra(y: int) -> int:
	if market.size.y <= 0 or y < market.position.y or y >= market.end.y:
		return 0
	var ramp := 4
	return market.size.x * mini(mini(y - market.position.y + 1, market.end.y - y), ramp) / ramp


## The main street over rows a..b (inclusive), added where not there yet.
func add_main(a: int, b: int) -> void:
	var cells: Array[Vector2i] = []
	for y in range(mini(a, b), maxi(a, b) + 1):
		if main.has(y):
			continue
		var l := main_x(y) - (mw - 1) / 2
		var e := market_extra(y)
		main[y] = [l - e, l + mw - 1 + e]
		for x in range(l - e, l + mw + e):
			cells.append(Vector2i(x, y))
			mark(Vector2i(x, y), 1)
	if not cells.is_empty():
		streets.append(cells)


func cross_y(c: Dictionary, x: int) -> int:
	return int(c.base) + wave(x, int(c.per), int(c.amp), int(c.salt))


## A cross street at `base`, x0..x1, two cells deep, bending; its north side is frontage (two lines, outward from the main
## street). The main street is extended to reach it.
func add_cross(base: int, x0: int, x1: int, amp: int) -> Dictionary:
	var c := {"base": base, "x0": x0, "x1": x1, "amp": amp, "per": maxi(2 * amp + 2, 14 + h(cross.size(), 962) % 12), "salt": 970 + cross.size()}
	add_main(base - 3, base + 4)
	var cells: Array[Vector2i] = []
	for x in range(x0, x1 + 1):
		var y := cross_y(c, x)
		for dy in 2:
			cells.append(Vector2i(x, y + dy))
			mark(Vector2i(x, y + dy), 1)
	streets.append(cells)
	cross.append(c)
	var ml: int = main[base][0]
	var mr: int = main[base][1]
	if x0 < ml - 2:
		lines.append({"t": "N", "c": cross.size() - 1, "d": -1, "cur": ml - 2, "dead": false})
	if x1 > mr + 2:
		lines.append({"t": "N", "c": cross.size() - 1, "d": 1, "cur": mr + 2, "dead": false})
	return c


func gap() -> int:
	return gap_lo + h(placed.size() + props.size() * 7, 963) % (gap_hi - gap_lo + 1)


## Whether `r` is open ground (nothing planned on it) with no other building within `g` cells.
func fits(r: Rect2i, g: int) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if occ.has(Vector2i(x, y)):
				return false
	if g > 0:
		var gr := r.grow(g)
		for y in range(gr.position.y, gr.end.y):
			for x in range(gr.position.x, gr.end.x):
				if int(occ.get(Vector2i(x, y), 0)) == 2 and not r.has_point(Vector2i(x, y)):
					return false
	return true


func claim(r: Rect2i, v: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			occ[Vector2i(x, y)] = v


## Footpath cells (open, kept free, paved as a lane).
func path(cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		return
	for c in cells:
		mark(c, 3)
	streets.append(cells)


func line_pos(ln: Dictionary) -> Vector2i:
	if str(ln.t) == "N":
		var c: Dictionary = cross[int(ln.c)]
		return Vector2i(int(ln.cur), cross_y(c, int(ln.cur)))
	return Vector2i(main_x(int(ln.cur)) + int(ln.s) * 6, int(ln.cur))


## Try to place stamp `sn` on line `ln` at its cursor, then a few cells on; on success advance the cursor past it and return
## {rect, door, spot}; {} when the line has no room (it is then dead).
func try_line(ln: Dictionary, sn: String, setback: int, g: int) -> Dictionary:
	var sd: Dictionary = stamps[sn]
	var w := int(sd.w)
	var hh := int(sd.h)
	var dx := int(sd.door[0])
	var dy := int(sd.door[1])
	var start: int = int(ln.cur)
	for attempt in (60 if str(ln.t) == "N" else 30):
		var r := Rect2i()
		var spot := Vector2i.ZERO
		var foot: Array[Vector2i] = []
		if str(ln.t) == "N":
			var c: Dictionary = cross[int(ln.c)]
			var left: int = int(ln.cur) if int(ln.d) > 0 else int(ln.cur) - w + 1
			if left < int(c.x0) or left + w - 1 > int(c.x1):
				break                               # past the street's end (dead below if even the narrowest house cannot fit)
			var top_min := 1 << 30
			for x in range(left, left + w):
				top_min = mini(top_min, cross_y(c, x))
			var y0 := top_min - setback - hh
			r = Rect2i(left, y0, w, hh)
			spot = Vector2i(left + dx, y0 + dy + 1)
			for y in range(maxi(spot.y, r.end.y), cross_y(c, spot.x)):
				foot.append(Vector2i(spot.x, y))
		else:
			var s := int(ln.s)
			var top: int = int(ln.cur) if int(ln.d) > 0 else int(ln.cur) - dy - 1
			var sy := top + dy + 1
			if int(ln.d) < 0 and int(ln.has("lim")) and top < int(ln.lim):
				ln.dead = true
				return {}
			if int(ln.d) > 0 and ln.has("lim") and maxi(sy, top + hh - 1) > int(ln.lim):
				ln.dead = true
				return {}
			var edge := 1 << 30 if s < 0 else -(1 << 30)
			for y in range(top, maxi(sy, top + hh - 1) + 1):
				if not main.has(y):
					ln.cur = start
					return {}                       # (the main street does not reach so far yet: it may later)
				edge = mini(edge, int(main[y][0])) if s < 0 else maxi(edge, int(main[y][1]))
			var sg := 1 + h(int(ln.cur), 964) % 2
			var left := edge - sg - w if s < 0 else edge + sg + 1
			r = Rect2i(left, top, w, hh)
			spot = Vector2i(left + dx, sy)
			if s < 0:
				for x in range(spot.x + 1, int(main[sy][0])):
					foot.append(Vector2i(x, sy))
			else:
				for x in range(int(main[sy][1]) + 1, spot.x):
					foot.append(Vector2i(x, sy))
		var ok := fits(r, g)
		if ok and not r.has_point(spot):
			ok = not occ.has(spot) or int(occ[spot]) == 1
		for c in foot:
			ok = ok and (not occ.has(c) or int(occ[c]) != 2 and int(occ[c]) != 4)
		if ok:
			claim(r, 2)
			if not r.has_point(spot) and not occ.has(spot):
				foot.push_front(spot)
			path(foot)
			if str(ln.t) == "N":
				var cc: Dictionary = cross[int(ln.c)]
				cc.lo = mini(int(cc.get("lo", r.position.x)), r.position.x)
				cc.hi = maxi(int(cc.get("hi", r.end.x - 1)), r.end.x - 1)
				ln.cur = r.end.x + g if int(ln.d) > 0 else r.position.x - 1 - g
			else:
				ln.cur = spot.y + 1 + g if int(ln.d) > 0 else r.position.y - 1 - g
			return {"rect": r, "door": Vector2i(r.position.x + dx, r.position.y + dy), "spot": spot}
		ln.cur = int(ln.cur) + int(ln.d)
	ln.cur = start                                  # nothing this wide fits on: a narrower building may
	if w <= 7:
		ln.dead = true
	return {}


## The best line (nearest the middle) that takes stamp `sn`; adds cross streets while none does.
func place(sn: String, home: bool, filter: Callable = Callable()) -> Dictionary:
	for grow in 12:
		var order: Array = []
		for k in lines.size():
			var ln: Dictionary = lines[k]
			if bool(ln.dead) or (filter.is_valid() and not filter.call(ln)):
				continue
			var p := line_pos(ln)
			order.append([(p - Vector2i(cx, cy)).length_squared() + (0 if str(ln.t) == "M" else 40), k])
		order.sort()
		for o in order:
			var ln: Dictionary = lines[int(o[1])]
			var sb := 0 if gap_hi <= 2 else h(placed.size(), 965) % 2
			var res := try_line(ln, sn, sb, gap())
			if not res.is_empty():
				placed.append({"rect": res.rect, "stamp": sn, "home": home, "t": str(ln.t)})
				res["ln"] = int(o[1])
				return res
		if filter.is_valid():
			return {}
		grow_town()
	return {}


var _grow_n := 0
var cross_len := Vector2i(16, 32)
var spacing := Vector2i(13, 17)


## One more cross street, alternately north and south of those there are, the main street extended to it; and the main
## street's own frontage lines run on.
func grow_town() -> void:
	_grow_n += 1
	var ys: Array = main.keys()
	var north := _grow_n % 2 == 1
	var sp := spacing.x + h(_grow_n, 966) % (spacing.y - spacing.x + 1)
	var lo := 1 << 30
	var hi := -(1 << 30)
	for c in cross:
		lo = mini(lo, int(c.base))
		hi = maxi(hi, int(c.base))
	if market.size.y > 0:
		lo = mini(lo, market.position.y + sp - 2)       # (the first street north of the market runs along its top)
	var base: int = lo - sp if north else hi + sp
	var lw := cross_len.x + h(_grow_n, 967) % (cross_len.y - cross_len.x + 1)
	var le := cross_len.x + h(_grow_n, 968) % (cross_len.y - cross_len.x + 1)
	if h(_grow_n, 969) % 4 == 0:
		lw = 0 if h(_grow_n, 960) % 2 == 0 else lw
		le = le if lw == 0 else le
	var mx := main_x(base)
	add_cross(base, mx - maxi(lw, 2), mx + maxi(le, 2), 1 + h(_grow_n, 959) % 2)
	for ln in lines:
		if str(ln.t) == "M" and not ln.has("lim"):
			ln.dead = false


## The yard pieces behind a building: a fenced garden, a plot, a shed, a wood pile or barrels, where there is room.
func yard(b: Dictionary, k: int) -> void:
	var pool := ["garden", "garden_w", "plot", "shed", "woodpile", "barrels", "garden", "plot", "haystack", "apples", "casks"]
	var sn: String = pool[h(k, 971) % pool.size()]
	var sd: Dictionary = stamps[sn]
	var r: Rect2i = b.rect
	for t in 3:
		var x := r.position.x + (h(k * 3 + t, 972) % maxi(1, r.size.x - int(sd.w) + 1))
		var at := Vector2i(x, r.position.y - int(sd.h) - t)
		var pr := Rect2i(at, Vector2i(int(sd.w), int(sd.h)))
		if fits(pr, 0):
			claim(pr, 4)
			props.append({"stamp": sn, "rect": pr, "look": "", "id": sn})
			return


func well_by(b: Dictionary, k: int) -> void:
	var r: Rect2i = b.rect
	for side in [1, -1]:
		var pr := Rect2i(Vector2i(r.end.x + 1 if side > 0 else r.position.x - 3, r.end.y - 3), Vector2i(2, 3))
		if fits(pr.grow(1), 0):
			claim(pr, 4)
			props.append({"stamp": "well", "rect": pr, "look": "", "id": "well"})
			return


func home_stamp(kind: String, q: int, manors: Array) -> String:
	var town := kind.contains("town")
	if town and manors[0] > 0 and h(q, 973) % 9 == 0:
		manors[0] -= 1
		return "manor"
	var pool: Array = ["house_9", "house_9", "house_11", "house_7", "house_9d", "house_11d", "house_13", "house_9", "house_7d", "house_11"] if town \
		else ["house_7", "house_7d", "house_9", "house_9", "house_11", "house", "house_7", "house_9d"]
	return pool[h(q, 974) % pool.size()]


func plan_site(spec: Dictionary, center: Vector2i, stamps_in: Dictionary, lay: Dictionary, site_index: int, plan: Dictionary) -> Dictionary:
	stamps = stamps_in
	si = site_index
	cx = center.x
	cy = center.y
	var kind := str(spec.kind)
	var town := kind.contains("town")
	var hamlet := kind == "hamlet"
	var walled := bool(plan.get("walls", false))
	mw = 3 if town else 2
	m_amp = 2 if town else 3
	m_per = 26 + h(0, 975) % 10
	if walled:
		gap_lo = 0; gap_hi = 1
		spacing = Vector2i(13, 15)
		cross_len = Vector2i(32, 46)
	elif town:
		gap_lo = 1; gap_hi = 2
		spacing = Vector2i(14, 17)
		cross_len = Vector2i(34, 50)
	elif hamlet:
		gap_lo = 3; gap_hi = 6
		spacing = Vector2i(16, 22)
		cross_len = Vector2i(20, 34)
	else:
		gap_lo = 1; gap_hi = 4
		spacing = Vector2i(15, 19)
		cross_len = Vector2i(28, 42)
	# --- what stands: the businesses, the homes, the spares (slot order as before), then the civic buildings
	var trades: Dictionary = spec.trades
	var items: Array = []
	var tids := trades.keys()
	tids.sort()
	for t in trades.keys():
		items.append(["work", str(t), str((lay.stamps as Dictionary).get(t, "house")), -1])
	var hid := 0
	for t in tids:
		for k in int(trades[t]):
			items.append(["home", "", "house", hid])
			hid += 1
	for k in int(plan.get("spare", maxi(1, hid / 8))):
		items.append(["home", "", "house", -1])
	var manors := [int(plan.get("manors", 2 if walled else 1 if town else 0))]
	for q in items.size():
		if str(items[q][0]) == "home":
			items[q][2] = home_stamp(kind, q, manors)
	# --- the skeleton: the main street, the market, the first cross street
	if town:
		var mh := 16 + h(1, 976) % 7
		market = Rect2i(0, cy - mh / 2 - 2, 8 + h(2, 976) % 4, mh)      # (size.x: the market's half width beyond the street)
	add_main(cy - 16, cy + 16)
	for s in [-1, 1]:
		lines.append({"t": "M", "s": s, "d": -1, "cur": cy - 1, "dead": false})
		lines.append({"t": "M", "s": s, "d": 1, "cur": cy, "dead": false})
	var mcross := add_cross(market.end.y + 1 if town else cy + 3, cx - cross_len.y, cx + cross_len.y, 1)
	var keep_open := func(a: Vector2i, step: Vector2i, n: int) -> void:
		for k in n:
			mark(a + step * k, 3)
			mark(a + step * k + Vector2i(step.y, step.x).abs(), 3)
	var slots := []
	var civ: Array = plan.get("civic", [])
	var civ_res := {}
	# civic buildings first: they take their places before the houses fill in round them
	var south_lines := func(ln: Dictionary) -> bool:
		return str(ln.t) == "N" and int(ln.c) == 0
	for ci in civ.size():
		var cv: Dictionary = civ[ci]
		var sn := str(cv.stamp)
		var sd: Dictionary = stamps[sn]
		var at := str(cv.at)
		var res := {}
		if at == "square" and market.size.y > 0:
			var dxx := int(cv.get("dx", 4))
			var yy := market.position.y + int(cv.get("dy", 2))
			var mx := main_x(yy)
			var p := Vector2i(mx + dxx if dxx >= 0 else mx + dxx - int(sd.w) + 1, yy)
			var r := Rect2i(p, Vector2i(int(sd.w), int(sd.h)))
			claim(r, 2)
			res = {"rect": r, "door": p + Vector2i(int(sd.door[0]), int(sd.door[1])), "spot": p + Vector2i(int(sd.door[0]), int(sd.door[1]) + 1)}
		elif at == "west" or at == "east":
			var s := -1 if at == "west" else 1
			var dist := int(cv.get("dist", 44 if town else 22))
			var c: Dictionary = cross[0]
			var want := cx + s * dist
			if s < 0 and int(c.x0) > want - int(sd.w) - 16:
				_extend_cross(0, want - int(sd.w) - 16)
			if s > 0 and int(c.x1) < want + int(sd.w) + 16:
				_extend_cross(0, want + int(sd.w) + 16)
			var ln: Dictionary = {"t": "N", "c": 0, "d": s, "cur": want, "dead": false}
			var key := "%s_%d" % [at, s]
			if civ_res.has(key):
				ln.cur = civ_res[key]
			res = try_line(ln, sn, 0, 2)
			if not res.is_empty():
				civ_res[key] = int(ln.cur) + s
				_churchyard(sn, ln)
				civ_res[key] = int(ln.cur) + s * 2
		elif at.begins_with("north"):
			if not civ_res.has("north"):
				var top: int = main.keys().min()
				var nb := top - 2
				add_cross(nb, cx - cross_len.y - 8, cx + cross_len.y + 8, 1)
				civ_res["north"] = cross.size() - 1
			var s := -1 if at == "north_west" else 1
			var nc := int(civ_res.north)
			for ln in lines:
				if str(ln.t) == "N" and int(ln.c) == nc and int(ln.d) == s:
					res = try_line(ln, sn, 0, 2)
					if not res.is_empty():
						_churchyard(sn, ln)
					break
		if res.is_empty():                       # "front", or no room where it was asked: the best frontage there is
			res = place(sn, false)
			if res.has("ln"):
				_churchyard(sn, lines[int(res.ln)])
		civ_res[ci] = res
	# the businesses near the middle, then the homes; in a walled town some homes straggle outside the gates
	var outside := (items.size() / 6) if walled else 0
	var where := []
	where.resize(items.size())
	for q in items.size() - outside:
		where[q] = place(str(items[q][2]), str(items[q][0]) == "home")
	# the yards and wells behind and beside the houses
	for k in placed.size():
		var b: Dictionary = placed[k]
		if b.home or h(k, 977) % 3 == 0:
			yard(b, k)
		if h(k, 978) % (7 if town else 5) == 0:
			well_by(b, k)
	_trim()
	_market_stalls()
	_street_furniture(town)
	var bbox := Rect2i(Vector2i(cx, cy), Vector2i(1, 1))
	for c in occ:
		bbox = bbox.expand(c)
	bbox.size += Vector2i(1, 1)
	var wr := Rect2i()
	var wall_slot := {}
	var way := {}
	if walled:                                    # the walls round it all, a gate where the main street goes out
		wr = bbox.grow_individual(6, 10, 6, 10)
		var gx_n := main_x(int(main.keys().min()))
		var gx_s := main_x(int(main.keys().max()))
		for y in range(wr.position.y - 3, wr.position.y + 12):
			straight[y] = gx_n
		for y in range(wr.end.y - 12, wr.end.y + 3):
			straight[y] = gx_s
		add_main(wr.position.y - 2, wr.end.y + 1)
		claim(Rect2i(wr.position, Vector2i(wr.size.x, 9)), 2)
		claim(Rect2i(Vector2i(wr.position.x, wr.end.y - 9), Vector2i(wr.size.x, 9)), 2)
		claim(Rect2i(wr.position, Vector2i(5, wr.size.y)), 2)
		claim(Rect2i(Vector2i(wr.end.x - 5, wr.position.y), Vector2i(5, wr.size.y)), 2)
		for y in range(wr.position.y, wr.end.y):              # (the gates stay street)
			for x in range(int(main[y][0]) - 1, int(main[y][1]) + 2):
				occ[Vector2i(x, y)] = 1
		var nm := "walls_%s" % str(spec.id)
		stamps[nm] = ow._wall_stamp(wr.size.x, wr.size.y, [gx_n - wr.position.x], [gx_s - wr.position.x])
		ow._solid_rows[nm] = stamps[nm].solid
		var gc := Vector2i(gx_s, wr.end.y - 1)
		wall_slot = {"kind": "civic", "trade": "", "stamp": nm, "hh": -1, "rect": wr, "door": gc, "spot": gc, "look": "", "id": "walls"}
		# outside: the road on south past the gate, houses straggling along it; the Way east-west under the south wall
		add_main(wr.end.y + 2, wr.end.y + 22)
		way = add_cross(wr.end.y + 3, wr.position.x - 4, wr.end.x + 4, 1)
		gap_lo = 2; gap_hi = 5
		for s in [-1, 1]:
			lines.append({"t": "M", "s": s, "d": 1, "cur": wr.end.y + 7, "dead": false, "lim": wr.end.y + 22})
		var sub := func(ln: Dictionary) -> bool:
			return str(ln.t) == "M" and ln.has("lim") or str(ln.t) == "N" and int(ln.c) == cross.size() - 1
		for q in range(items.size() - outside, items.size()):
			where[q] = place(str(items[q][2]), true, sub)
			if where[q].is_empty():
				where[q] = place(str(items[q][2]), true)
		for k in range(placed.size() - outside, placed.size()):
			if k >= 0 and placed[k].home:
				yard(placed[k], k + 500)
	for q in items.size():
		var res: Dictionary = where[q]
		var it: Array = items[q]
		var sn := str(it[2])
		var look := ""
		if sn.begins_with("house") and h(q, 943) % 100 < (35 if town else 60):
			look = "thatch"
		slots.append({"kind": it[0], "trade": it[1], "stamp": sn, "hh": it[3], "rect": res.rect, "door": res.door, "spot": res.spot, "look": look})
	for ci in civ.size():
		var cv: Dictionary = civ[ci]
		var res: Dictionary = civ_res[ci]
		slots.append({"kind": "civic", "trade": "", "stamp": str(cv.stamp), "hh": -1, "rect": res.rect, "door": res.door,
			"spot": res.spot, "look": str(cv.get("look", "")), "id": str(cv.get("id", cv.stamp))})
	if not wall_slot.is_empty():
		slots.append(wall_slot)
	var rect := Rect2i(Vector2i(cx, cy), Vector2i(1, 1))
	for c in occ:
		rect = rect.expand(c)
	rect.size += Vector2i(1, 1)
	if walled and bool(plan.get("castle", false)):   # the castle beyond the walls' north-east corner, its gate to the south
		var cr := Rect2i(wr.end.x + 3, wr.position.y - 18, 34, 32)
		var cn := "castle_%s" % str(spec.id)
		stamps[cn] = ow._wall_stamp(cr.size.x, cr.size.y, [], [cr.size.x / 2])
		ow._solid_rows[cn] = stamps[cn].solid
		var cg := Vector2i(cr.position.x + cr.size.x / 2, cr.end.y - 1)
		slots.append({"kind": "civic", "trade": "", "stamp": cn, "hh": -1, "rect": cr, "door": cg, "spot": cg, "look": "white", "id": "castle"})
		var kd: Dictionary = stamps.keep
		var ka := Vector2i(cr.position.x + (cr.size.x - int(kd.w)) / 2, cr.position.y + 9)
		var kdoor := ka + Vector2i(int(kd.door[0]), int(kd.door[1]))
		slots.append({"kind": "civic", "trade": "", "stamp": "keep", "hh": -1, "rect": Rect2i(ka, Vector2i(int(kd.w), int(kd.h))),
			"door": kdoor, "spot": kdoor + Vector2i(0, 1), "look": "", "id": "keep"})
		claim(cr, 2)
		rect = rect.merge(cr)
	rect = rect.grow(3)
	# the ways in reach the site's edges: the main street north and south, the market's (or the Way's) street east and west
	add_main(rect.position.y, rect.end.y - 1)
	var ec: Dictionary = way if not way.is_empty() else cross[0]
	var ey := cross_y(ec, int(ec.x1))
	var wy := cross_y(ec, int(ec.x0))
	var ext: Array[Vector2i] = []
	for x in range(int(ec.x1) + 1, rect.end.x):
		ext.append(Vector2i(x, ey))
	for x in range(rect.position.x, int(ec.x0)):
		ext.append(Vector2i(x, wy))
	for c in ext:
		mark(c, 1)
	streets.append(ext)
	var gate := Vector2i(main_x(rect.end.y - 1), rect.end.y - 1)
	var entries := [Vector2i(main_x(rect.position.y), rect.position.y), Vector2i(rect.end.x - 1, ey), gate, Vector2i(rect.position.x, wy)]
	var sq := Rect2i()
	if market.size.y > 0:
		var l := 1 << 30
		var r := -(1 << 30)
		for y in range(market.position.y, market.end.y):
			l = mini(l, int(main[y][0]))
			r = maxi(r, int(main[y][1]))
		sq = Rect2i(l, market.position.y, r - l + 1, market.size.y)
	return {"rect": rect, "slots": slots, "gate": gate, "streets": streets, "square": sq, "walled": walled, "props": props,
		"entries": entries}


## Each cross street but the first cut back to a few cells past its last building (it was laid long for the frontage it
## might need); the cut cells are open ground again.
func _trim() -> void:
	var gone := {}
	for k in range(1, cross.size()):
		var c: Dictionary = cross[k]
		var mx := main_x(int(c.base))
		var lo := mini(int(c.get("lo", mx)), mx - 3) - 3
		var hi := maxi(int(c.get("hi", mx)), mx + 3) + 3
		for x in range(int(c.x0), int(c.x1) + 1):
			if x >= lo and x <= hi:
				continue
			var y := cross_y(c, x)
			for dy in 2:
				var cell := Vector2i(x, y + dy)
				if int(occ.get(cell, 0)) == 1 and not _on_main(cell):
					occ.erase(cell)
					gone[cell] = true
		c.x0 = maxi(int(c.x0), lo)
		c.x1 = mini(int(c.x1), hi)
	if gone.is_empty():
		return
	for k in streets.size():
		var kept: Array[Vector2i] = []
		for cell: Vector2i in streets[k]:
			if not gone.has(cell):
				kept.append(cell)
		streets[k] = kept


func _on_main(cell: Vector2i) -> bool:
	return main.has(cell.y) and cell.x >= int(main[cell.y][0]) and cell.x <= int(main[cell.y][1])


func _prop(sn: String, at: Vector2i, need_street: bool) -> bool:
	var sd: Dictionary = stamps[sn]
	var r := Rect2i(at, Vector2i(int(sd.w), int(sd.h)))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var v := int(occ.get(Vector2i(x, y), 0))
			if (need_street and v != 1) or (not need_street and v != 0):
				return false
	claim(r, 4)
	props.append({"stamp": sn, "rect": r, "look": "", "id": sn})
	return true


## Market stalls round the edge of the market place, inside it, the middle left open (Larchrow's stall).
func _market_stalls() -> void:
	if market.size.y <= 0:
		return
	var n := 0
	for k in 24:
		if n >= 6:
			return
		var y := market.position.y + 2 + (h(k, 980) % maxi(1, market.size.y - 5))
		var side := -1 if k % 2 == 0 else 1
		var x: int = int(main[y][0]) + 1 if side < 0 else int(main[y][1]) - 2
		if absi(y - cy) <= 1 or int(main[y][1]) - int(main[y][0]) < 10:
			continue
		var r := Rect2i(Vector2i(x, y), Vector2i(2, 2)).grow(1)
		var clear := true
		for yy in range(r.position.y, r.end.y):
			for xx in range(r.position.x, r.end.x):
				clear = clear and _on_main(Vector2i(xx, yy)) and int(occ.get(Vector2i(xx, yy), 0)) == 1
		if clear and _prop("stall", Vector2i(x, y), true):
			n += 1


## A signpost where each cross street leaves the main street; lamp posts along a town's main street.
func _street_furniture(town: bool) -> void:
	for k in cross.size():
		var c: Dictionary = cross[k]
		var y := cross_y(c, main_x(int(c.base))) - 1
		if main.has(y):
			_prop("signpost", Vector2i(int(main[y][1]) + 1, y), false)
	if not town:
		return
	var ys: Array = main.keys()
	ys.sort()
	for i in range(0, ys.size(), 9):
		var y: int = ys[i]
		var side := -1 if (i / 9) % 2 == 0 else 1
		_prop("lamp", Vector2i(int(main[y][0]) - 1 if side < 0 else int(main[y][1]) + 1, y - 1), false)


func _extend_cross(k: int, to_x: int) -> void:
	var c: Dictionary = cross[k]
	var cells: Array[Vector2i] = []
	var r := range(to_x, int(c.x0)) if to_x < int(c.x0) else range(int(c.x1) + 1, to_x + 1)
	for x in r:
		var y := cross_y(c, x)
		for dy in 2:
			cells.append(Vector2i(x, y + dy))
			mark(Vector2i(x, y + dy), 1)
	streets.append(cells)
	if to_x < int(c.x0):
		c.x0 = to_x
	else:
		c.x1 = to_x


## Beside a church or the abbey, on the same frontage: its fenced churchyard, the graves inside.
func _churchyard(sn: String, ln: Dictionary) -> void:
	if not (sn.contains("church") or sn == "abbey"):
		return
	var yd := "churchyard" if sn == "abbey" or sn == "church_tower" else "churchyard_s"
	var res := try_line(ln, yd, 0, 1)
	if not res.is_empty():
		occ_retag(res.rect, 4)
		props.append({"stamp": yd, "rect": res.rect, "look": "", "id": "churchyard"})


func occ_retag(r: Rect2i, v: int) -> void:
	claim(r, v)
