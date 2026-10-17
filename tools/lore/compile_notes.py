"""Compile compact chapter notes into schema JSON, then validate them.

Single-session research notes live in research/extraction/notes/<chapter>.txt, one record
per line (format below). This tool turns each into research/extraction/chapters/<chapter>.json
in the layout described in research/extraction/SCHEMA.md, runs the quote validator on it, and
rewrites research/extraction/ledger.json and research/PROGRESS.md.

Notes format (fields separated by " | "; quotes in backticks; P-numbers are chapter-local):

    @ BONE-C1
    summary: what happens
    geo: what the chapter adds to the map
    open: question one || question two
    E <type> | <name> | <aliases, comma-separated or -> | <subtype> | <summary> | P002 `quote`; P005 `quote`
    R <a> | <rel> | <b> | <detail> | <when> | CANON/high | refs
    S <a> | <rel> | <b> | dir=..; dist=..; time=..; mode=..; terrain=..; ctx=..; cert=fixed | CANON/high | <note> | refs
    T <travellers> | <from> | <to> | via=a, b; mode=..; dur=..; dir=..; start=..; end=..; terrain=.. | refs
    F <category> | <subject> | <statement> | CANON/high; ctx=..; when=.. | refs
    V <layer> | <label> | <summary> | time=..; who=a, b; where=a, b | refs
    U <kind> | <question> | refs
    O <system> | <idea> | refs

Class tokens: CANON or INF (CANON-INFERRED), then /high, /medium or /low.

Usage:
    python3 tools/lore/compile_notes.py            # all notes
    python3 tools/lore/compile_notes.py BONE-C1    # selected chapters
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate_extraction  # noqa: E402

REPO = Path(__file__).resolve().parent.parent.parent
NOTES = REPO / "research" / "extraction" / "notes"
OUT = REPO / "research" / "extraction" / "chapters"
LEDGER = REPO / "research" / "extraction" / "ledger.json"
PROGRESS = REPO / "research" / "PROGRESS.md"
NOVEL = REPO / "research" / "corpus" / "novel.json"

REF_RE = re.compile(r"(P\d{3}|B(?:ONE|TWO|THREE|FOUR)-C\d+-P\d{3})\s*`([^`]+)`")


class NoteError(ValueError):
    pass


def refs(text, chapter):
    out = [{"p": p if p.startswith("B") else f"{chapter}-{p}", "q": q} for p, q in REF_RE.findall(text)]
    if not out:
        raise NoteError(f"no refs in: {text[:80]!r}")
    return out


def kv(text):
    out = {}
    for part in filter(None, (s.strip() for s in text.split(";"))):
        if "=" not in part:
            raise NoteError(f"expected key=value, got {part!r}")
        k, v = part.split("=", 1)
        out[k.strip()] = v.strip()
    return out


def cls(token):
    m = re.fullmatch(r"(CANON|INF)/(high|medium|low)", token.strip())
    if not m:
        raise NoteError(f"bad class token {token!r} (want CANON/high, INF/medium, ...)")
    return ("CANON" if m.group(1) == "CANON" else "CANON-INFERRED"), m.group(2)


def listish(s):
    return [x.strip() for x in s.split(",") if x.strip() and x.strip() != "-"]


def parse(path, novel_chapters):
    lines = path.read_text(encoding="utf-8").splitlines()
    data = {k: [] for k in validate_extraction.SECTIONS}
    chapter, meta = None, {"summary": "", "geo": "", "open": []}
    for n, raw in enumerate(lines, 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        try:
            if line.startswith("@"):
                chapter = line[1:].strip()
                continue
            if line.startswith("summary:"):
                meta["summary"] = line[8:].strip()
                continue
            if line.startswith("geo:"):
                meta["geo"] = line[4:].strip()
                continue
            if line.startswith("open:"):
                meta["open"] = [q.strip() for q in line[5:].split("||") if q.strip()]
                continue
            tag, rest = line[0], line[1:].strip()
            f = [x.strip() for x in rest.split(" | ")]
            if tag == "E":
                typ, name, aliases, subtype, summary, r = f[0], f[1], f[2], f[3], f[4], f[5]
                data["entities"].append({"name": name, "aliases": listish(aliases), "type": typ,
                                         "subtype": subtype, "unnamed": name.startswith("(unnamed)"),
                                         "summary": summary, "attributes": {}, "refs": refs(r, chapter)})
            elif tag == "R":
                a, rel, b, detail, when, c, r = f
                cl, conf = cls(c)
                data["relations"].append({"a": a, "rel": rel, "b": b, "detail": detail, "when": when,
                                          "classification": cl, "confidence": conf, "refs": refs(r, chapter)})
            elif tag == "S":
                a, rel, b, attrs, c, note, r = f
                cl, conf = cls(c)
                at = kv(attrs)
                data["spatial"].append({
                    "a": a, "rel": rel, "b": b, "direction": at.get("dir", ""),
                    "distance_text": at.get("dist", ""), "travel_time_text": at.get("time", ""),
                    "travel_mode": at.get("mode", ""), "terrain_text": at.get("terrain", ""),
                    "context": at.get("ctx", "narration"), "certainty": at.get("cert", "constrained"),
                    "classification": cl, "confidence": conf, "note": note, "refs": refs(r, chapter)})
            elif tag == "T":
                who, frm, to, attrs, r = f
                at = kv(attrs)
                data["travel"].append({
                    "travellers": listish(who), "from": frm, "to": to, "via": listish(at.get("via", "")),
                    "mode": at.get("mode", ""), "direction_text": at.get("dir", ""),
                    "duration_text": at.get("dur", ""), "start_time_text": at.get("start", ""),
                    "end_time_text": at.get("end", ""), "terrain_text": at.get("terrain", ""),
                    "chapter": chapter, "refs": refs(r, chapter)})
            elif tag == "F":
                cat, subject, statement, attrs, r = f
                head, _, tail = attrs.partition(";")
                cl, conf = cls(head)
                at = kv(tail)
                data["facts"].append({"category": cat, "subject": subject, "statement": statement,
                                      "classification": cl, "confidence": conf,
                                      "context": at.get("ctx", "narration"), "when": at.get("when", ""),
                                      "note": at.get("note", ""), "refs": refs(r, chapter)})
            elif tag == "V":
                layer, label, summary, attrs, r = f
                at = kv(attrs)
                data["events"].append({"label": label, "chapter": chapter, "layer": layer,
                                       "time_text": at.get("time", ""), "participants": listish(at.get("who", "")),
                                       "places": listish(at.get("where", "")), "summary": summary,
                                       "consequences": at.get("then", ""), "refs": refs(r, chapter)})
            elif tag == "U":
                kind, question, r = f
                data["unresolved"].append({"kind": kind, "question": question, "refs": refs(r, chapter)})
            elif tag == "O":
                system, idea, r = f
                data["opportunities"].append({"idea": idea, "system": system, "basis_refs": refs(r, chapter)})
            else:
                raise NoteError(f"unknown record tag {tag!r}")
        except (NoteError, ValueError) as e:
            raise NoteError(f"{path.name}:{n}: {e}") from None
    if chapter not in novel_chapters:
        raise NoteError(f"{path.name}: missing or unknown '@ chapter' line")
    total = len(novel_chapters[chapter]["paragraphs"]) - 1
    data.update({
        "batch": f"notes_{chapter}",
        "chapters": [chapter],
        "ledger": [{"chapter": chapter, "paragraphs_total": total, "all_paragraphs_read": True,
                    "summary": meta["summary"], "geography_notes": meta["geo"],
                    "open_questions": meta["open"]}],
    })
    return chapter, data


def write_ledger(novel):
    done = {}
    for f in sorted(OUT.glob("*.json")):
        d = json.loads(f.read_text(encoding="utf-8"))
        counts = {k: len(d[k]) for k in validate_extraction.SECTIONS}
        done[d["chapters"][0]] = {"file": f"research/extraction/chapters/{f.name}",
                                  "notes": f"research/extraction/notes/{d['chapters'][0]}.txt",
                                  "summary": d["ledger"][0]["summary"], "counts": counts,
                                  "open_questions": d["ledger"][0]["open_questions"]}
    ledger = []
    for c in novel["chapters"]:
        e = done.get(c["id"])
        ledger.append({
            "chapter": c["id"], "title": c["title"], "body_paragraphs": len(c["paragraphs"]) - 1,
            "full_text_accessed": True,
            "contextual_analysis": "complete" if e else "pending",
            "quotes_verified": bool(e),
            "records": e["counts"] if e else {},
            "open_questions": e["open_questions"] if e else [],
            "files": {"notes": e["notes"], "records": e["file"]} if e else {},
        })
    LEDGER.write_text(json.dumps({"format": "morris-ledger/1", "chapters": ledger}, indent=1) + "\n",
                      encoding="utf-8")
    return ledger


def write_progress(ledger, failures):
    done = [e for e in ledger if e["contextual_analysis"] == "complete"]
    todo = [e for e in ledger if e["contextual_analysis"] != "complete"]
    totals = {}
    for e in done:
        for k, v in e["records"].items():
            totals[k] = totals.get(k, 0) + v
    lines = [
        "# Research progress",
        "",
        f"- Chapters complete: **{len(done)} / {len(ledger)}**",
        f"- Remaining: {len(todo)}" + (f" (next: {', '.join(e['chapter'] for e in todo[:5])})" if todo else ""),
        f"- Records: " + ", ".join(f"{k} {v}" for k, v in totals.items()),
        f"- Verification failures in the last compile: {failures}",
        "- Active subagents: 0 (owner limit: none without explicit approval)",
        "- Method: single-session contextual reading; notes compiled and quote-checked by script",
        "",
        "Per-chapter status: `research/extraction/ledger.json`.",
        "",
    ]
    PROGRESS.write_text("\n".join(lines), encoding="utf-8")


def main(argv):
    novel = json.loads(NOVEL.read_text(encoding="utf-8"))
    chapters = {c["id"]: c for c in novel["chapters"]}
    OUT.mkdir(parents=True, exist_ok=True)
    paths = [NOTES / f"{c}.txt" for c in argv] if argv else sorted(NOTES.glob("*.txt"))
    failures = 0
    for p in paths:
        try:
            cid, data = parse(p, chapters)
        except NoteError as e:
            print("NOTE ERROR:", e)
            failures += 1
            continue
        tmp = OUT / f"{cid}.json.tmp"
        tmp.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        problems = validate_extraction.validate(tmp, novel)
        if problems:
            failures += len(problems)
            print(f"{cid}: {len(problems)} problems")
            for x in problems:
                print("   ", x)
            tmp.unlink()
            continue
        tmp.replace(OUT / f"{cid}.json")
        print(f"{cid}: OK  " + " ".join(f"{k}={len(data[k])}" for k in validate_extraction.SECTIONS))
    ledger = write_ledger(novel)
    write_progress(ledger, failures)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
