"""Merge the per-chapter extractions into world registries with stable ids, and run the checks.

Reads research/extraction/chapters/*.json (compiled by compile_notes.py) and the hand-curated
identity decisions in research/registries/merges.json, then writes to research/registries/:

    ids.json            name -> stable entity id; existing ids are never reassigned
    entities.json       one record per entity, merged across chapters
    relations.json, spatial.json, travel.json, facts.json, events.json,
    unresolved.json, opportunities.json
                        every record with a content-derived id and entity ids resolved
    checks.json, CHECKS.md
                        coverage, quote re-verification, duplicate candidates, spatial
                        contradictions, dangling names, Gutenberg exclusion

Names used in relations, journeys or events that have no entity record of their own become
implicit entities (`"implicit": true`), so every reference resolves to an id.

All output is deterministic: same inputs give byte-identical files.

Usage:
    python3 tools/lore/build_registries.py
"""
import hashlib
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate_extraction  # noqa: E402

REPO = Path(__file__).resolve().parent.parent.parent
CHAPTERS = REPO / "research" / "extraction" / "chapters"
NOVEL = REPO / "research" / "corpus" / "novel.json"
OUT = REPO / "research" / "registries"
MERGES = OUT / "merges.json"

PREFIX = {"person": "per", "group": "grp", "polity": "pol", "place": "plc", "feature": "fea",
          "building": "bld", "item": "itm", "creature": "cre", "supernatural": "sup",
          "office": "off", "occupation": "occ", "commodity": "com", "currency": "cur",
          "custom": "cus", "text": "txt", "implicit": "imp"}
BOOKS = {"BONE": 1, "BTWO": 2, "BTHREE": 3, "BFOUR": 4}
CERT_RANK = {"fixed": 3, "constrained": 2, "flexible": 1}
OPPOSITE = {"north_of": "south_of", "south_of": "north_of", "east_of": "west_of",
            "west_of": "east_of", "upstream_of": "downstream_of", "downstream_of": "upstream_of"}
GUTENBERG = re.compile(r"gutenberg|\bebook\b|transcriber|www\.|http", re.I)


def chapter_key(cid):
    book, num = cid.split("-")
    return BOOKS[book], int(num[1:])


def para_key(pid):
    book, c, p = pid.split("-")
    return BOOKS[book], int(c[1:]), int(p[1:])


def slug(name):
    s = re.sub(r"^\(unnamed\) ", "", name).lower().replace("'", "")
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")[:48]


def rid(prefix, *parts):
    h = hashlib.sha1("\x1f".join(parts).encode()).hexdigest()[:10]
    return f"{prefix}-{h}"


def load_chapters():
    out = {}
    for f in CHAPTERS.glob("*.json"):
        out[f.stem] = json.loads(f.read_text())
    return dict(sorted(out.items(), key=lambda kv: chapter_key(kv[0])))


def build(chapters, merges, old_ids):
    merge = {k: v["into"] for k, v in merges["merge"].items()}
    drop = set(merges["drop"])

    def canon(name):
        seen = set()
        while name in merge and name not in seen:
            seen.add(name)
            name = merge[name]
        return name

    # Entities, merged by canonical name, in reading order.
    ents = {}
    for cid, d in chapters.items():
        for e in d["entities"]:
            name = canon(e["name"])
            rec = ents.setdefault(name, {"name": name, "types": [], "subtypes": [], "unnamed": True,
                                         "aliases": [], "merged_from": [], "summaries": [],
                                         "attributes": {}, "chapters": [], "refs": [],
                                         "implicit": False})
            if e["type"] not in rec["types"]:
                rec["types"].append(e["type"])
            if e["subtype"] and e["subtype"] not in rec["subtypes"]:
                rec["subtypes"].append(e["subtype"])
            if e["name"] == name:
                rec["unnamed"] = rec["unnamed"] and e["unnamed"]
            elif e["name"] not in rec["merged_from"]:
                rec["merged_from"].append(e["name"])
            for a in e["aliases"] + ([e["name"]] if e["name"] != name else []):
                if a != name and a not in rec["aliases"]:
                    rec["aliases"].append(a)
            rec["summaries"].append({"chapter": cid, "text": e["summary"]})
            for k, v in e.get("attributes", {}).items():
                rec["attributes"].setdefault(k, v)
            if cid not in rec["chapters"]:
                rec["chapters"].append(cid)
            rec["refs"].extend(e["refs"])

    # Every name used elsewhere must resolve; unknown names become implicit entities.
    dangling = defaultdict(set)

    def use(name, cid, kind):
        if name in drop or not name:
            return None
        name = canon(name)
        if name not in ents:
            dangling[name].add(cid)
            ents[name] = {"name": name, "types": ["implicit"], "subtypes": [kind],
                          "unnamed": name.startswith("(unnamed)"), "aliases": [], "merged_from": [],
                          "summaries": [], "attributes": {}, "chapters": [], "refs": [],
                          "implicit": True}
        if cid not in ents[name]["chapters"]:
            ents[name]["chapters"].append(cid)
        return name

    # Stable ids: keep every id already issued; new names get type prefix + slug.
    def assign_ids():
        ids = dict(old_ids)
        taken = set(ids.values())
        for name in sorted(ents):
            if name in ids:
                continue
            base = f"{PREFIX[ents[name]['types'][0]]}-{slug(name)}"
            new, n = base, 2
            while new in taken:
                new, n = f"{base}-{n}", n + 1
            ids[name] = new
            taken.add(new)
        return ids

    recs = {k: [] for k in validate_extraction.SECTIONS if k != "entities"}
    for cid, d in chapters.items():
        for r in d["relations"]:
            a, b = use(r["a"], cid, "relation"), use(r["b"], cid, "relation")
            recs["relations"].append(dict(r, a=a, b=b, chapter=cid))
        for r in d["spatial"]:
            a, b = use(r["a"], cid, "place"), use(r["b"], cid, "place")
            recs["spatial"].append(dict(r, a=a, b=b, chapter=cid))
        for t in d["travel"]:
            trav = [x for x in (use(n, cid, "traveller") for n in t["travellers"]) if x]
            via = [x for x in (use(n, cid, "place") for n in t["via"]) if x]
            recs["travel"].append(dict(t, travellers=trav, via=via,
                                       **{"from": use(t["from"], cid, "place"),
                                          "to": use(t["to"], cid, "place")}))
        for x in d["facts"]:
            recs["facts"].append(dict(x, subject=use(x["subject"], cid, "subject"), chapter=cid))
        for v in d["events"]:
            parts = [x for x in (use(n, cid, "participant") for n in v["participants"]) if x]
            places = [x for x in (use(n, cid, "place") for n in v["places"]) if x]
            recs["events"].append(dict(v, participants=parts, places=places))
        for u in d["unresolved"]:
            recs["unresolved"].append(dict(u, chapter=cid))
        for o in d["opportunities"]:
            recs["opportunities"].append(dict(o, chapter=cid, classification="GAME EXPANSION"))

    ids = assign_ids()

    # Identity links (possible same-as), from merges.json and from the chapters' own relations.
    links = defaultdict(list)
    for ln in merges["link"]:
        a, b = canon(ln["a"]), canon(ln["b"])
        if a in ents and b in ents:
            links[a].append({"id": ids[b], "name": b, "basis": ln["basis"]})
            links[b].append({"id": ids[a], "name": a, "basis": ln["basis"]})

    # Best geographic certainty for each entity, from the spatial records that name it.
    cert = {}
    for s in recs["spatial"]:
        for n in (s["a"], s["b"]):
            if n and CERT_RANK[s["certainty"]] > CERT_RANK.get(cert.get(n), 0):
                cert[n] = s["certainty"]

    PREFIXES = {"relations": "rel", "spatial": "spa", "travel": "trv", "facts": "fct",
                "events": "evt", "unresolved": "unr", "opportunities": "opp"}
    out = {}
    for sec, items in recs.items():
        rows, seen = [], set()
        for r in items:
            key = json.dumps(r, sort_keys=True)
            new = rid(PREFIXES[sec], key)
            if new in seen:  # identical record repeated: keep one
                continue
            seen.add(new)
            r = dict(r, id=new)
            for fld in ("a", "b", "subject", "from", "to"):
                if fld in r and r[fld]:
                    r[fld + "_id"] = ids[r[fld]]
            for fld in ("travellers", "via", "participants", "places"):
                if fld in r:
                    r[fld + "_ids"] = [ids[n] for n in r[fld]]
            rows.append(dict(sorted(r.items())))
        out[sec] = rows

    spatial_types = {"place", "feature", "building", "polity", "implicit"}
    entities = []
    for name in sorted(ents, key=lambda n: ids[n]):
        e = ents[name]
        e["refs"] = sorted({(r["p"], r["q"]) for r in e["refs"]}, key=lambda t: (para_key(t[0]), t[1]))
        e["refs"] = [{"p": p, "q": q} for p, q in e["refs"]]
        e["chapters"].sort(key=chapter_key)
        rec = {"id": ids[name], **e, "first_chapter": e["chapters"][0] if e["chapters"] else None,
               "classification": "CANON", "possible_same_as": links.get(name, [])}
        if set(e["types"]) & spatial_types:
            rec["geo_certainty"] = cert.get(name, "unplaced")
        entities.append(rec)
    out["entities"] = entities
    return out, ids, dangling


def checks(chapters, novel, reg, dangling, merges):
    paras = novel["paragraphs"]
    body = [p for c in novel["chapters"] for p in c["paragraphs"][1:]]
    cited = set()

    def walk(x):
        if isinstance(x, dict):
            if "p" in x and "q" in x:
                cited.add(x["p"])
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(list(chapters.values()))

    per_chapter = []
    for c in novel["chapters"]:
        b = c["paragraphs"][1:]
        n = sum(1 for p in b if p in cited)
        per_chapter.append({"chapter": c["id"], "body_paragraphs": len(b), "cited": n})

    quote_problems = []
    for cid in chapters:
        path = CHAPTERS / f"{cid}.json"
        quote_problems += [f"{cid}: {p}" for p in validate_extraction.validate(path, novel)]

    # Duplicate candidates: same type, high token overlap, not already linked.
    stop = {"unnamed", "the", "of", "a", "in", "and", "to", "on", "by", "at"}
    linked = {(min(e["id"], l["id"]), max(e["id"], l["id"]))
              for e in reg["entities"] for l in e["possible_same_as"]}
    toks = {e["id"]: {w for w in re.findall(r"[a-z]+", e["name"].lower())
                      if w not in stop and len(w) > 2} for e in reg["entities"]}
    dups = []
    ents = reg["entities"]
    for i, a in enumerate(ents):
        for b in ents[i + 1:]:
            ta, tb = toks[a["id"]], toks[b["id"]]
            if ta and tb and set(a["types"]) & set(b["types"]):
                j = len(ta & tb) / len(ta | tb)
                if j >= 0.67 and (a["id"], b["id"]) not in linked:
                    dups.append({"a": a["name"], "b": b["name"], "score": round(j, 2)})

    # Spatial contradictions: opposite directions claimed for the same ordered pair.
    claims = defaultdict(list)
    for s in reg["spatial"]:
        if s["rel"] in OPPOSITE and s["a"] and s["b"]:
            claims[(s["a"], s["b"])].append((s["rel"], s["id"], s["context"]))
            claims[(s["b"], s["a"])].append((OPPOSITE[s["rel"]], s["id"], s["context"]))
    contra = []
    for (a, b), cl in sorted(claims.items()):
        if a > b:
            continue
        rels = {c[0] for c in cl}
        for r in sorted(rels):
            if OPPOSITE[r] in rels and r < OPPOSITE[r]:
                contra.append({"a": a, "b": b, "relations": sorted(rels),
                               "records": sorted({c[1] for c in cl}),
                               "contexts": sorted({c[2] for c in cl})})

    gut = [p for p in body if GUTENBERG.search(paras[p])]
    bad_refs = sorted(p for p in cited if p not in paras)
    b = novel["boundaries"]
    return {
        "format": "morris-checks/1",
        "chapters_extracted": len(chapters), "chapters_in_novel": len(novel["chapters"]),
        "body_paragraphs": len(body), "body_paragraphs_cited": sum(1 for p in body if p in cited),
        "chapters_below_50pct_cited": [c for c in per_chapter if c["cited"] * 2 < c["body_paragraphs"]],
        "quote_problems": quote_problems,
        "refs_outside_tale": bad_refs,
        "gutenberg": {"tale_lines": b["tale"], "excluded_header": b["gutenberg_header"],
                      "excluded_footer": b["gutenberg_footer"],
                      "tale_paragraphs_matching_gutenberg_terms": gut},
        "counts": {k: len(v) for k, v in reg.items()},
        "merged_names": len(merges["merge"]),
        "implicit_entities": sorted(dangling),
        "duplicate_candidates": dups,
        "spatial_contradictions": contra,
        "unresolved_by_kind": dict(sorted(
            {k: sum(1 for u in reg["unresolved"] if u["kind"] == k)
             for k in {u["kind"] for u in reg["unresolved"]}}.items())),
    }


def render_checks(c):
    L = ["# Registry checks", "",
         "Generated by `tools/lore/build_registries.py`. Do not edit by hand.", "",
         "| Check | Result |", "|---|---|",
         f"| Chapters extracted | {c['chapters_extracted']} / {c['chapters_in_novel']} |",
         f"| Body paragraphs cited at least once | {c['body_paragraphs_cited']} / {c['body_paragraphs']} |",
         f"| Quote verification problems | {len(c['quote_problems'])} |",
         f"| References outside the tale | {len(c['refs_outside_tale'])} |",
         f"| Tale paragraphs matching Gutenberg terms | {len(c['gutenberg']['tale_paragraphs_matching_gutenberg_terms'])} |",
         f"| Names merged by `merges.json` | {c['merged_names']} |",
         f"| Implicit entities (named only in relations, journeys or events) | {len(c['implicit_entities'])} |",
         f"| Duplicate candidates for review | {len(c['duplicate_candidates'])} |",
         f"| Spatial contradictions | {len(c['spatial_contradictions'])} |", "",
         "Gutenberg exclusion: the tale is lines "
         f"{c['gutenberg']['tale_lines'][0]}-{c['gutenberg']['tale_lines'][1]} of `pg169.txt`; header lines "
         f"{c['gutenberg']['excluded_header'][0]}-{c['gutenberg']['excluded_header'][1]} and footer lines "
         f"{c['gutenberg']['excluded_footer'][0]}-{c['gutenberg']['excluded_footer'][1]} are excluded. "
         "Every reference points into the tale.", "",
         "## Record counts", "", "| Registry | Records |", "|---|---|"]
    L += [f"| {k} | {v} |" for k, v in sorted(c["counts"].items())]
    L += ["", "## Unresolved records by kind", "", "| Kind | Records |", "|---|---|"]
    L += [f"| {k} | {v} |" for k, v in c["unresolved_by_kind"].items()]
    L += ["", "## Chapters with under half their paragraphs cited", ""]
    L += [f"- {x['chapter']}: {x['cited']} / {x['body_paragraphs']}" for x in c["chapters_below_50pct_cited"]] or ["None."]
    L += ["", "Uncited paragraphs were read but gave no record of their own (dialogue, repetition, "
          "description already captured).", "", "## Spatial contradictions", ""]
    for x in c["spatial_contradictions"]:
        L.append(f"- {x['a']} / {x['b']}: {', '.join(x['relations'])} ({', '.join(x['contexts'])}; "
                 f"{', '.join(x['records'])})")
    if not c["spatial_contradictions"]:
        L.append("None.")
    L += ["", "## Duplicate candidates (review; not merged)", ""]
    L += [f"- {x['a']} / {x['b']} ({x['score']})" for x in c["duplicate_candidates"]] or ["None."]
    L += ["", "## Implicit entities", "", ", ".join(c["implicit_entities"]) or "None.", ""]
    if c["quote_problems"]:
        L += ["## Quote problems", ""] + [f"- {p}" for p in c["quote_problems"]] + [""]
    return "\n".join(L)


def main():
    novel = json.loads(NOVEL.read_text())
    chapters = load_chapters()
    merges = json.loads(MERGES.read_text())
    ids_path = OUT / "ids.json"
    old = json.loads(ids_path.read_text())["ids"] if ids_path.exists() else {}
    reg, ids, dangling = build(chapters, merges, old)
    chk = checks(chapters, novel, reg, dangling, merges)

    def dump(name, obj):
        (OUT / name).write_text(json.dumps(obj, indent=1, ensure_ascii=False, sort_keys=False) + "\n")

    dump("ids.json", {"format": "morris-ids/1", "ids": dict(sorted(ids.items()))})
    for sec, rows in reg.items():
        dump(f"{sec}.json", {"format": f"morris-{sec}/1", "records": rows})
    dump("checks.json", chk)
    (OUT / "CHECKS.md").write_text(render_checks(chk))
    print(f"entities {len(reg['entities'])}, implicit {len(dangling)}, "
          f"quote problems {len(chk['quote_problems'])}, contradictions {len(chk['spatial_contradictions'])}, "
          f"duplicate candidates {len(chk['duplicate_candidates'])}, "
          f"cited {chk['body_paragraphs_cited']}/{chk['body_paragraphs']}")
    return 1 if chk["quote_problems"] or chk["refs_outside_tale"] else 0


if __name__ == "__main__":
    sys.exit(main())
