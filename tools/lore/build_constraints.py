"""Compile the spatial registry into world-generation constraints.

Reads research/registries/spatial.json, travel.json and entities.json and writes
research/registries/worldgen_constraints.json: one node per place-like entity and one
constraint per spatial record, typed for a constraint solver.

    kind       direction | distance | travel_time | containment | adjacency | sequence |
               visibility | flow | beyond | crossing | between | other
    strength   hard  = fixed certainty, stated in narration
               soft  = constrained, or stated by a speaker in dialogue, a tale or a rumour
               info  = flexible, or a relation a solver cannot use directly
    measure    numbers parsed from the text's own words ("some twenty miles" -> 20, approximate),
               with the unit as written; miles are added only for units with a fixed English
               length (furlong, mile, yard). Leagues, days and hours are left unconverted:
               their conversion is a generator setting, not a fact (docs/world/H_WORLD_GENERATOR_SPEC.md).

Nothing here assigns coordinates. Output is deterministic.

Usage:
    python3 tools/lore/build_constraints.py
"""
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
REG = REPO / "research" / "registries"

KIND = {
    "north_of": "direction", "south_of": "direction", "east_of": "direction", "west_of": "direction",
    "distance_from": "distance", "within": "containment", "contains": "containment",
    "surrounds": "containment", "on": "containment", "outside": "containment", "around": "containment",
    "near": "adjacency", "adjacent_to": "adjacency", "borders": "adjacency", "at_foot_of": "adjacency",
    "across_from": "adjacency", "overlooks": "visibility", "visible_from": "visibility",
    "on_route": "sequence", "route_next": "sequence", "leads_to": "sequence",
    "upstream_of": "flow", "downstream_of": "flow", "flows_from": "flow", "flows_into": "flow",
    "beyond": "beyond", "between": "between", "crossing_of": "crossing", "crosses": "crossing",
    "higher_than": "other", "other": "other",
}
BEARING = {"north_of": 0, "east_of": 90, "south_of": 180, "west_of": 270}
NUM = {"a": 1, "an": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
       "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "fifteen": 15, "twenty": 20,
       "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "hundred": 100, "dozen": 12,
       "score": 20, "half-score": 10, "half": 0.5}
UNITS = {"furlong": 0.125, "mile": 1.0, "yard": 1 / 1760, "league": None, "day": None,
         "hour": None, "night": None}
APPROX = re.compile(r"\b(some|about|nigh|little less than|more than|not above|wellnigh|or more|or)\b")
PLACE_TYPES = {"place", "feature", "building", "polity", "implicit"}


def measures(text):
    """Find '<number words> <unit>' phrases; return [{value, unit, miles, approximate, text}]."""
    out = []
    t = text.lower().replace("a mile and a half", "1.5 mile").replace("half a mile", "0.5 mile")
    for m in re.finditer(r"((?:[\d.]+|[a-z-]+)(?: [a-z-]+)?) (furlong|mile|yard|league|day|hour|night)s?\b", t):
        words = m.group(1).split()
        val = None
        for w in words:
            if re.fullmatch(r"[\d.]+", w):
                val = float(w)
            elif w in NUM:
                val = NUM[w] if val is None else val * NUM[w] if w in ("hundred", "score") else NUM[w]
        if val is None or re.match(r"\s+(before|after|past|of daylight|left)\b", t[m.end():]):
            continue  # a time of day ("two hours before sunset"), not a duration
        unit = m.group(2)
        out.append({"value": val, "unit": unit,
                    "miles": round(val * UNITS[unit], 4) if UNITS[unit] else None,
                    "approximate": bool(APPROX.search(t)), "text": m.group(0)})
    return out


def strength(s):
    spoken = s["context"] not in ("narration", "narrator", "")
    if s["certainty"] == "flexible" or KIND.get(s["rel"], "other") == "other":
        return "info"
    if s["certainty"] == "fixed" and not spoken and s["classification"] == "CANON":
        return "hard"
    return "soft"


def build():
    ents = json.loads((REG / "entities.json").read_text())["records"]
    spatial = json.loads((REG / "spatial.json").read_text())["records"]
    by_name = {e["name"]: e for e in ents}
    used = {s["a"] for s in spatial} | {s["b"] for s in spatial}
    nodes = [{"id": e["id"], "name": e["name"], "type": e["types"][0],
              "certainty": e.get("geo_certainty", "unplaced"), "unnamed": e["unnamed"]}
             for e in ents if set(e["types"]) & PLACE_TYPES or e["name"] in used]
    cons = []
    for s in spatial:
        if not (s["a"] and s["b"]):
            continue
        text = " ".join(x for x in (s.get("distance_text"), s.get("travel_time_text"), s.get("direction")) if x)
        c = {"id": s["id"].replace("spa-", "wgc-"), "source": s["id"], "kind": KIND.get(s["rel"], "other"),
             "rel": s["rel"], "a": s["a_id"], "b": s["b_id"], "a_name": s["a"], "b_name": s["b"],
             "strength": strength(s), "certainty": s["certainty"],
             "classification": s["classification"], "confidence": s["confidence"],
             "context": s["context"], "chapter": s["chapter"], "text": text,
             "terrain": s.get("terrain_text", ""), "mode": s.get("travel_mode", ""),
             "refs": [r["p"] for r in s["refs"]]}
        if s["rel"] in BEARING:
            c["bearing_deg"] = BEARING[s["rel"]]
            c["note"] = "a lies in this compass direction from b; the tolerance is a solver setting"
        m = measures(text)
        if m:
            c["measures"] = m
        if s["a"] not in by_name or s["b"] not in by_name:
            c["strength"] = "info"
        cons.append(c)
    cons.sort(key=lambda c: c["id"])
    nodes.sort(key=lambda n: n["id"])
    counts = {}
    for c in cons:
        counts[f"{c['kind']}/{c['strength']}"] = counts.get(f"{c['kind']}/{c['strength']}", 0) + 1
    return {"format": "morris-worldgen-constraints/1",
            "note": "Derived from spatial.json by tools/lore/build_constraints.py. No coordinates. "
                    "Strength: hard = fixed narration, soft = constrained or spoken, info = not solver-usable.",
            "counts": dict(sorted(counts.items())), "nodes": nodes, "constraints": cons}


def main():
    out = build()
    (REG / "worldgen_constraints.json").write_text(json.dumps(out, indent=1, ensure_ascii=False) + "\n")
    print(f"{len(out['nodes'])} nodes, {len(out['constraints'])} constraints")
    for k, v in out["counts"].items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
