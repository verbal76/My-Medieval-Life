class_name EconNeeds
extends RefCounted
## Expansion 20 (Living Economy), LE-01: the need record (design s.3 Need, s.4). DISABLED and isolated: World builds it only
## when game/data/economy.json "enabled" is true. It DERIVES needs from state the game already keeps and changes none of
## it: it calls no function that writes (no evaluate_household, no hourly price or reserve cache), draws no random number,
## moves no coin or good, and nothing in live play reads it to decide.
##
## Need {actor, kind, item, qty, shortfall, target, cover_days, deadline, substitutes, source, derived_day}:
##   food      "hh:<n>"   the household's days of food (hh.econ.days, written each dawn by NPCBrain.evaluate_household) below
##                         the OD-19 horizon (reserve_days): target = reserve_days, shortfall = the missing days, qty = the
##                         missing food points (missing days x hh.econ.need); substitutes = NPCBrain.EDIBLE (all food counts)
##   tool      "npc:<id>" a trade's tool (NPCBrain.JOB_TOOL) not held and not on a manor order (EQ-19), or an axe for the
##                         adult responsible for building the household's home (NPCBrain.local_tool_need's two rules)
##   input     "npc:<id>" an input its trade still buys (NPCBrain.wants, SHOP-01: BUYS caps in whole batches)
##   contract  any party  units owed on an open CON-01 contract as seller beyond what it holds (Contracts.left); deadline =
##                         the contract's deadline_day (it lapses the dawn after)
##   housing   "hh:<n>"   what the household's own building site still needs (site.need, World.start_site/deliver)
## Not derived for the player (who decides for themselves; OWNER DECISION OD-LE-14 governs what the player is shown) nor for
## tills, the chapel or settlements (their own modules keep their needs: off-map need_rate, Chapel).
##
## Not here, by design: urgency and strategy. The design asks for "changing urgency, not a universal fixed rank" (s.4); the
## weighing of competing needs is the decision model of LE-03 (no owner decision is open on it). LE-01 records only the
## facts a weighing needs (shortfall, cover_days, deadline). Material substitution beyond food: OWNER DECISION OD-LE-08
## (SUBSTITUTION below), so `substitutes` is empty for every other kind.
##
## Cost: needs are derived per actor, only for actors in the dirty set (marked by a trade, a contract change, a dawn of
## their household) or asked for directly; refresh(limit) works the dirty set in sorted order, at most `limit` actors a
## call, the rest carried to the next call. No population scan.
## Deterministic: actors sorted, needs sorted by (kind, item). Saved (design s.4: "Persist goals through saves").

## OWNER DECISION OD-LE-08 (barter, rental, repair and resource substitution): which materials may stand in for others.
## Placeholder: no material substitutes are recorded; nothing reads this but the tests and the LE-01 note.
const SUBSTITUTION := "OWNER DECISION OD-LE-08: undecided; no material substitutes"
const KINDS := ["contract", "food", "housing", "input", "tool"]

var actors: EconActor
var refresh_budget := 64
var table := {}                 # actor ref -> {day, needs: Array}
var dirty := {}                 # actor ref -> true


func _init(actors_: EconActor, cfg := {}) -> void:
	actors = actors_
	refresh_budget = maxi(1, int(cfg.get("refresh_budget", 64)))


func mark(ref: String) -> void:
	if ref != "" and actors.kind(ref) in ["npc", "hh"]:
		dirty[ref] = true


## Re-derive up to `limit` dirty actors (sorted); returns the refs done.
func refresh(limit := -1) -> Array:
	var n := refresh_budget if limit < 0 else limit
	var refs: Array = dirty.keys()
	refs.sort()
	var done := refs.slice(0, mini(n, refs.size()))
	for r in done:
		dirty.erase(r)
		_store(r)
	return done


## The actor's needs as last derived (copies); derives them first when it is dirty or has none recorded today.
func needs_of(ref: String) -> Array:
	if dirty.has(ref) or not table.has(ref) or int(table[ref].day) != actors.w.day():
		dirty.erase(ref)
		_store(ref)
	var out := []
	for x in table.get(ref, {"needs": []}).needs:
		out.append(x.duplicate(true))
	return out


func _store(ref: String) -> void:
	var list := derive(ref)
	if list.is_empty():
		table.erase(ref)
	else:
		table[ref] = {"day": actors.w.day(), "needs": list}


## The needs of one actor, read from the game's state now, sorted by (kind, item). Pure: writes nothing.
func derive(ref: String) -> Array:
	var out := []
	if not actors.alive(ref):
		return out
	var w := actors.w
	match actors.kind(ref):
		"hh":
			var h := int(ref.get_slice(":", 1))
			var hh: Dictionary = w.households[h]
			var econ: Dictionary = hh.get("econ", {})
			if not econ.is_empty():
				var target := float(GameData.b("reserve_days"))
				var cover := float(econ.get("days", 0.0))
				if cover < target:
					out.append(_need(ref, "food", "", ceili((target - cover) * float(econ.get("need", 0.0))), target - cover, target, cover, -1, NPCBrain.EDIBLE.duplicate(), "hh.econ.days < reserve_days (OD-19)"))
			var site: Dictionary = w.plot(str(hh.get("build", ""))).get("site", {}) if str(hh.get("build", "")) != "" else {}
			if not site.is_empty() and not bool(site.get("done", false)):
				var ids: Array = (site.get("need", {}) as Dictionary).keys()
				ids.sort()
				for id in ids:
					var q := int(site.need[id])
					if q > 0:
						out.append(_need(ref, "housing", str(id), q, q, q, -1.0, -1, [], "site.need of " + str(hh.build)))
		"npc":
			var n: NPC = w.npc(int(ref.get_slice(":", 1)))
			if n.role == "adult":
				var tool: String = NPCBrain.JOB_TOOL.get(n.job, "")
				if tool != "" and not n.inv.has(tool) and w.brain._order_for(n).is_empty():
					out.append(_need(ref, "tool", tool, 1, 1, 1, -1.0, -1, [], "JOB_TOOL of " + n.job))
				elif tool != "axe" and not n.inv.has("axe") and n.household >= 0 and str(w.households[n.household].get("build", "")) != "" \
						and w.construction.responsible_adult(n.household) == n:
					out.append(_need(ref, "tool", "axe", 1, 1, 1, -1.0, -1, [], "builds the household's home"))
				var caps: Dictionary = NPCBrain.BUYS.get(w.brain.buy_role(n), {})
				var ids: Array = caps.keys()
				ids.sort()
				for id in ids:
					var q: int = w.brain.wants(n, str(id))
					if q > 0:
						out.append(_need(ref, "input", str(id), q, q, int(caps[id]), -1.0, -1, [], "NPCBrain.wants (SHOP-01)"))
	if w.contracts != null and actors.kind(ref) in ["npc", "player"]:
		var owed := {}                  # item -> [units left on every open contract, earliest deadline, ids]
		for c in w.contracts.open_of(ref, "seller"):
			if str(c.get("kind", "goods")) == "service":
				continue
			var o: Array = owed.get(str(c.item), [0, 1 << 30, []])
			o[0] += Contracts.left(c)
			o[1] = mini(int(o[1]), int(c.deadline_day))
			o[2].append(int(c.id))
			owed[str(c.item)] = o
		var items: Array = owed.keys()
		items.sort()
		for id in items:
			var short: int = int(owed[id][0]) - actors.count(ref, id)
			if short > 0:
				out.append(_need(ref, "contract", id, short, short, int(owed[id][0]), -1.0, int(owed[id][1]), [], "contracts " + JSON.stringify(owed[id][2])))
	out.sort_custom(_before)
	return out


static func _before(a: Dictionary, b: Dictionary) -> bool:
	if a.kind != b.kind:
		return a.kind < b.kind
	if a.item != b.item:
		return a.item < b.item
	return int(a.deadline) < int(b.deadline)


func _need(ref: String, kind: String, item: String, qty: int, shortfall: float, target: float, cover: float, deadline: int, subs: Array, source: String) -> Dictionary:
	return {"actor": ref, "kind": kind, "item": item, "qty": qty, "shortfall": snappedf(shortfall, 0.001), "target": snappedf(target, 0.001),
		"cover_days": snappedf(cover, 0.001), "deadline": deadline, "substitutes": subs, "source": source, "derived_day": actors.w.day()}


## Every recorded need of one kind (sorted by actor, then item): a query over the table, not a fresh derivation.
func recorded(kind := "") -> Array:
	var out := []
	var refs: Array = table.keys()
	refs.sort()
	for r in refs:
		for x in table[r].needs:
			if kind == "" or x.kind == kind:
				out.append(x.duplicate(true))
	return out


func is_empty() -> bool:
	return table.is_empty() and dirty.is_empty()


func to_dict() -> Dictionary:
	var refs: Array = table.keys()
	refs.sort()
	var t := {}
	for r in refs:
		t[r] = table[r].duplicate(true)
	var d: Array = dirty.keys()
	d.sort()
	return {"table": t, "dirty": d}


func load_dict(d: Dictionary) -> void:
	table = {}
	dirty = {}
	var t: Dictionary = d.get("table", {})
	for r in t:
		var list := []
		for x in t[r].get("needs", []):
			list.append({"actor": str(x.actor), "kind": str(x.kind), "item": str(x.item), "qty": int(x.qty), "shortfall": float(x.shortfall),
				"target": float(x.target), "cover_days": float(x.cover_days), "deadline": int(x.deadline), "substitutes": (x.get("substitutes", []) as Array).map(func(s): return str(s)),
				"source": str(x.source), "derived_day": int(x.derived_day)})
		table[str(r)] = {"day": int(t[r].get("day", 0)), "needs": list}
	for r in d.get("dirty", []):
		dirty[str(r)] = true
