class_name Intel
extends RefCounted
## REGION-NAV-01 S5, the intel network (plan AD-5): economic knowledge about the neighbouring settlements, always with its source.
##
## Where knowledge lives:
##   the reeve's book    World.intel_book (Envoys): what envoys reported, kept by the office
##   a villager          NPC.intel: the records they were told, at most `keep` (the freshest kept), saved
## How it moves (only through a teller; nobody knows a record nobody told them):
##   the envoy           after the home survey, goes to the tradespeople whose wants or trade goods match the book's records (at
##                       most `tell_max` a mission, those with the most to hear first) and tells them (Envoys, envoy_tell)
##   word of mouth       in an hour two villagers share (Relations.share, the hour the gossip of JudgmentStore also passes in),
##                       each tells the other the records about the listener's own trade (what it buys, what it makes), at most
##                       `share_max` an hour; the listener hears it from the teller
## Every record keeps its collected_day through every retelling; told_by and heard_day are the last teller and the day heard.
## Ageing: a record older than `stale_days` (by collected_day) is stale: kept but not to be acted on (S6 reads fresh()); one older
## than `forget_days` is forgotten by a villager the next time they share or are told. The reeve's book keeps its records until
## the next envoy to that place replaces them.

static func cfg() -> Dictionary:
	var c: Dictionary = OffMapSettlement.data().get("intel", {})
	return {"stale_days": int(c.get("stale_days", 4)), "forget_days": int(c.get("forget_days", 8)), "keep": int(c.get("keep", 24)),
		"share_max": int(c.get("share_max", 3)), "tell_max": int(c.get("tell_max", 6)), "tell_minutes": float(c.get("tell_minutes", 15.0))}


static func age(w: World, r: Dictionary) -> int:
	return w.day() - int(r.get("collected_day", -100000))


static func fresh(w: World, r: Dictionary) -> bool:
	return str(r.get("kind", "")) == "confirmed" and age(w, r) <= int(cfg().stale_days)


## The items a villager's trade buys and makes (what records about them concern): its raw goods (NPCBrain.TRADE_GOODS) and the
## products of the recipes made at its trade's stations (S7: a crafter hears of a place wanting what their workshop makes).
static func interests(w: World, n: NPC) -> Dictionary:
	var role: String = w.brain.buy_role(n)
	var key := role + "|" + n.job
	if _interests.has(key):
		return _interests[key]                         # (the same for every villager of the role and trade: built once)
	var out := {}
	for id in trade_products(n.job):
		out[id] = "makes"
	for id in NPCBrain.TRADE_GOODS.get(n.job, []):
		out[str(id)] = "makes"
	for id in NPCBrain.BUYS.get(role, {}):
		out[str(id)] = "buys"
	_interests[key] = out
	return out


static var _interests := {}


static var _products := {}


## The products of the recipes made at trade `job`'s stations (NPCBrain.TRADE_STATIONS), sorted; cached per trade.
static func trade_products(job: String) -> Array:
	if _products.has(job):
		return _products[job]
	var kinds: Array = NPCBrain.TRADE_STATIONS.get(job, [])
	var out := {}
	if not kinds.is_empty():
		for r in GameData.recipes:
			var rec: Dictionary = GameData.recipes[r]
			if kinds.has(str(rec.get("station", ""))):
				for id in rec.get("out", {}):
					out[str(id)] = true
	var list := out.keys()
	list.sort()
	_products[job] = list
	return list


## The best price `n` was told a neighbouring place would pay for `id` (a fresh "want" record), or 0.
static func told_price(w: World, n: NPC, id: String) -> int:
	var best := 0
	for r in n.intel:
		if str(r.item) == id and str(r.side) == "want" and fresh(w, r):
			best = maxi(best, int(r.price))
	return best


## Whether record `r` concerns `n`: something they buy that a place has, or something they make that a place wants.
static func concerns(w: World, n: NPC, r: Dictionary, ints: Dictionary = {}) -> bool:
	if str(r.get("kind", "")) != "confirmed":
		return false
	var i := ints if not ints.is_empty() else interests(w, n)
	var why := str(i.get(str(r.item), ""))
	return (why == "buys" and str(r.side) == "have") or (why == "makes" and str(r.side) == "want")


static func _key(r: Dictionary) -> String:
	return "%s|%s|%s" % [str(r.about), str(r.item), str(r.side)]


## `listener` hears record `r` from `teller` (a villager reference): kept if newer than what they know of the same thing.
## True if it was news to them.
static func hear(w: World, listener: NPC, r: Dictionary, teller: String) -> bool:
	if age(w, r) > int(cfg().forget_days):
		return false
	var k := _key(r)
	for i in listener.intel.size():
		var x: Dictionary = listener.intel[i]
		if _key(x) == k:
			if int(x.collected_day) >= int(r.collected_day):
				return false
			listener.intel.remove_at(i)
			break
	var c: Dictionary = r.duplicate()
	c.told_by = teller
	c.heard_day = w.day()
	listener.intel.append(c)
	_trim(w, listener)
	w.stat("intel_heard")
	return true


static func _trim(w: World, n: NPC) -> void:
	var fd := int(cfg().forget_days)
	n.intel = n.intel.filter(func(x): return age(w, x) <= fd)
	if n.intel.size() > int(cfg().keep):
		n.intel.sort_custom(func(a, b): return int(a.collected_day) > int(b.collected_day) or (int(a.collected_day) == int(b.collected_day) and _key(a) < _key(b)))
		n.intel.resize(int(cfg().keep))


## Relations.share: an hour together; each tells the other what concerns the other's trade.
static func share(w: World, a: int, b: int) -> void:
	var na := w.npc(a)
	var nb := w.npc(b)
	if na == null or nb == null or not na.alive or not nb.alive:
		return
	if na.intel.is_empty() and nb.intel.is_empty():
		return
	_pass(w, na, nb)
	_pass(w, nb, na)


static func _pass(w: World, teller: NPC, listener: NPC) -> void:
	if teller.intel.is_empty() or listener.role != "adult":
		return
	_trim(w, teller)
	var ints := interests(w, listener)
	if ints.is_empty():
		return
	var told := 0
	var recs: Array = teller.intel.duplicate()
	recs.sort_custom(func(x, y): return int(x.collected_day) > int(y.collected_day) or (int(x.collected_day) == int(y.collected_day) and _key(x) < _key(y)))
	for r in recs:
		if told >= int(cfg().share_max):
			break
		if concerns(w, listener, r, ints) and hear(w, listener, r, World.npc_ref(teller.id)):
			told += 1
			w.stat("intel_word_of_mouth")


## The villagers the envoy should tell, with what (from the reeve's book): [[npc, records]], most to hear first, at most tell_max.
static func to_tell(w: World, b: Dictionary) -> Array:
	var out := []
	for ref in (b.home as Dictionary).keys():
		var o := w.npc(int(str(ref).substr(4)))
		if o == null or not o.alive:
			continue
		var ints := interests(w, o)
		var recs := (b.records as Array).filter(func(r): return fresh(w, r) and concerns(w, o, r, ints))
		if not recs.is_empty():
			out.append([o, recs])
	out.sort_custom(func(x, y): return x[1].size() > y[1].size() or (x[1].size() == y[1].size() and x[0].id < y[0].id))
	if out.size() > int(cfg().tell_max):
		out.resize(int(cfg().tell_max))
	return out
