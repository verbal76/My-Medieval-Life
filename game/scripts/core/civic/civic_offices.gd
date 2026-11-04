class_name CivicOffices
extends RefCounted
## P21-01 (Expansion 21, owner directive 2026-10-23, VP-01): the civic office registry. Stable ids for today's posts, per
## jurisdiction, derived from the game's own data and never stored: `village/reeve`, `village/guard/1..N` (N is
## Population.JOBS.guard), `village/sage`, and for each of the five towns in game/data/settlements.json a jurisdiction
## of its own (`wulstead`, ...) that names its government and its hamlets, nothing more (its officials stay OffMapSettlement's).
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


## B25R1-Q9 (owner decision): a hamlet is a local civic place (its gatherings, local trade and visiting merchants, news and
## gossip, local work and cooperative tasks), never a jurisdiction: it has no mayor, council, elections or government of its
## own. Its people stay under their lord's town (settlements.json government.lord), which lists it among its `hamlets`; a
## hamlet with no lord (Rushford, Ashcombe) belongs to no jurisdiction.
static func jurisdictions() -> Array:
	var out := [{"id": VILLAGE, "name": str(config().get("village_name", "the manor village")), "kind": "village", "government": "the manor and its reeve", "hamlets": []}]
	var list: Array = OffMapSettlement.data().settlements
	for s in list:
		if bool(s.get("hamlet", false)):
			continue
		var hs: Array = []
		for t in list:
			if bool(t.get("hamlet", false)) and str(t.get("government", {}).get("lord", "")) == str(s.id):
				hs.append(str(t.id))
		out.append({"id": str(s.id), "name": str(s.name), "kind": "settlement", "government": str(s.get("government", {}).get("name", "")), "hamlets": hs})
	return out


## The jurisdiction a settlement's residents are under (B25R1-Q9): a town its own, a hamlet its lord's town, "" for a hamlet
## with no lord or an unknown id.
static func jurisdiction_of(settlement_id: String) -> String:
	for s in OffMapSettlement.data().settlements:
		if str(s.id) == settlement_id:
			return str(s.get("government", {}).get("lord", "")) if bool(s.get("hamlet", false)) else settlement_id
	return ""


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
