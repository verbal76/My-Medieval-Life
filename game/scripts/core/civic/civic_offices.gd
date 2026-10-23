class_name CivicOffices
extends RefCounted
## P21-01 (Expansion 21, owner directive 2026-10-23, VP-01): the civic office registry. Stable ids for today's posts, per
## jurisdiction, derived from the game's own data and never stored: `village/reeve`, `village/guard/1..N` (N is
## Population.JOBS.guard), `village/sage`, and for each of the five settlements in game/data/settlements.json a jurisdiction
## of its own (`wulstead`, ...) that names its government and nothing more (its officials stay OffMapSettlement's).
## The authority text is DESCRIPTIVE (what the post does today in code; data/civic.json "authority"); no rule reads it and it
## grants no power. Elections, terms, eligibility and powers are owner decisions not yet made.
##   CivicOffices.offices() -> [{id, jurisdiction, kind, slot, title, authority}], deterministic order.

const VILLAGE := "village"
const KINDS := ["reeve", "guard", "sage"]
static var _cfg := {}


static func config() -> Dictionary:
	if _cfg.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/civic.json"))
		assert(d is Dictionary and str(d.get("format", "")) == "mml-civic/1", "bad data file civic.json")
		_cfg = d
	return _cfg


static func guard_count() -> int:
	return int(Population.JOBS.guard)


static func office_id(kind: String, slot := 0) -> String:
	return "%s/%s/%d" % [VILLAGE, kind, slot] if kind == "guard" else "%s/%s" % [VILLAGE, kind]


## The kind of office a job fills ("guard", "reeve", "sage"), or "" for a job that is no office.
static func kind_of_job(job: String) -> String:
	return job if KINDS.has(job) else ""


static func jurisdictions() -> Array:
	var out := [{"id": VILLAGE, "name": str(config().get("village_name", "the manor village")), "kind": "village", "government": "the manor and its reeve"}]
	for s in OffMapSettlement.data().settlements:
		out.append({"id": str(s.id), "name": str(s.name), "kind": "settlement", "government": str(s.get("government", {}).get("name", ""))})
	return out


static func offices() -> Array:
	var auth: Dictionary = config().authority
	var out := [
		{"id": office_id("reeve"), "jurisdiction": VILLAGE, "kind": "reeve", "slot": 0, "title": "Reeve", "authority": str(auth.reeve)},
	]
	for i in range(1, guard_count() + 1):
		out.append({"id": office_id("guard", i), "jurisdiction": VILLAGE, "kind": "guard", "slot": i, "title": "Guard of the watch", "authority": str(auth.guard)})
	out.append({"id": office_id("sage"), "jurisdiction": VILLAGE, "kind": "sage", "slot": 0, "title": "Sage", "authority": str(auth.sage)})
	return out


static func office(id: String) -> Dictionary:
	for o in offices():
		if o.id == id:
			return o
	return {}
