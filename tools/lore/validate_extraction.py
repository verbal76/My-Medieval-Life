"""Validate research batch files against the novel corpus.

Checks every research/extraction/batch_*.json (or the files given) for:
  - valid JSON with the required sections
  - a ledger entry for every chapter in the batch, with all_paragraphs_read true and the
    right paragraph count
  - every ref pointing at an existing paragraph inside the literary text
  - every quote being an exact substring of its paragraph (whitespace runs normalised)
  - allowed enum values (classification, entity type, certainty, ...)

Usage:
    python3 tools/lore/validate_extraction.py                       # all batches
    python3 tools/lore/validate_extraction.py research/extraction/batch_03.json
Exit status 1 if any problem is found.
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
NOVEL = REPO / "research" / "corpus" / "novel.json"
EXTRACTION = REPO / "research" / "extraction"

SECTIONS = ["entities", "relations", "spatial", "travel", "facts", "events", "unresolved", "opportunities"]
ENTITY_TYPES = {"person", "group", "polity", "place", "feature", "building", "item", "creature",
                "supernatural", "office", "occupation", "commodity", "currency", "custom", "text"}
CLASSES = {"CANON", "CANON-INFERRED"}
CERTAINTY = {"fixed", "constrained", "flexible"}
CONFIDENCE = {"high", "medium", "low"}
LAYERS = {"main", "backstory", "legend", "prophecy", "rumour", "epilogue"}
UNRESOLVED_KINDS = {"location", "identity", "contradiction", "missing_measure", "ambiguity", "document_error"}


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


def check_refs(refs, paras, where, problems, key="refs"):
    if not isinstance(refs, list) or not refs:
        problems.append(f"{where}: needs at least one ref in '{key}'")
        return
    for r in refs:
        p, q = r.get("p"), r.get("q", "")
        if p not in paras:
            problems.append(f"{where}: unknown paragraph {p!r}")
        elif not q or norm(q) not in norm(paras[p]):
            problems.append(f"{where}: quote not found in {p}: {q[:80]!r}")


def validate(path, novel):
    paras = novel["paragraphs"]
    chapters = {c["id"]: c for c in novel["chapters"]}
    problems = []
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        return [f"{path}: not valid JSON: {e}"]
    for s in SECTIONS + ["chapters", "ledger"]:
        if not isinstance(data.get(s), list):
            problems.append(f"missing list '{s}'")
    if problems:
        return problems
    ledger = {e.get("chapter"): e for e in data["ledger"]}
    for cid in data["chapters"]:
        if cid not in chapters:
            problems.append(f"unknown chapter {cid}")
            continue
        e = ledger.get(cid)
        if not e:
            problems.append(f"ledger: no entry for {cid}")
            continue
        if e.get("all_paragraphs_read") is not True:
            problems.append(f"ledger {cid}: all_paragraphs_read is not true")
        want = len(chapters[cid]["paragraphs"]) - 1
        if e.get("paragraphs_total") != want:
            problems.append(f"ledger {cid}: paragraphs_total {e.get('paragraphs_total')} != {want} body paragraphs")
        if not e.get("summary"):
            problems.append(f"ledger {cid}: empty summary")
    for i, e in enumerate(data["entities"]):
        w = f"entities[{i}] {e.get('name')!r}"
        if not e.get("name"):
            problems.append(f"{w}: no name")
        if e.get("type") not in ENTITY_TYPES:
            problems.append(f"{w}: bad type {e.get('type')!r}")
        check_refs(e.get("refs"), paras, w, problems)
    for i, r in enumerate(data["relations"]):
        w = f"relations[{i}] {r.get('a')!r} {r.get('rel')} {r.get('b')!r}"
        if r.get("classification") not in CLASSES:
            problems.append(f"{w}: bad classification")
        check_refs(r.get("refs"), paras, w, problems)
    for i, r in enumerate(data["spatial"]):
        w = f"spatial[{i}] {r.get('a')!r} {r.get('rel')} {r.get('b')!r}"
        if r.get("classification") not in CLASSES:
            problems.append(f"{w}: bad classification")
        if r.get("certainty") not in CERTAINTY:
            problems.append(f"{w}: bad certainty {r.get('certainty')!r}")
        check_refs(r.get("refs"), paras, w, problems)
    for i, r in enumerate(data["travel"]):
        check_refs(r.get("refs"), paras, f"travel[{i}] {r.get('from')!r}->{r.get('to')!r}", problems)
    for i, r in enumerate(data["facts"]):
        w = f"facts[{i}] {r.get('subject')!r}"
        if r.get("classification") not in CLASSES:
            problems.append(f"{w}: bad classification")
        check_refs(r.get("refs"), paras, w, problems)
    for i, r in enumerate(data["events"]):
        w = f"events[{i}] {r.get('label')!r}"
        if r.get("layer") not in LAYERS:
            problems.append(f"{w}: bad layer {r.get('layer')!r}")
        check_refs(r.get("refs"), paras, w, problems)
    for i, r in enumerate(data["unresolved"]):
        w = f"unresolved[{i}]"
        if r.get("kind") not in UNRESOLVED_KINDS:
            problems.append(f"{w}: bad kind {r.get('kind')!r}")
        check_refs(r.get("refs"), paras, w, problems)
    for i, r in enumerate(data["opportunities"]):
        check_refs(r.get("basis_refs"), paras, f"opportunities[{i}]", problems, key="basis_refs")
    return problems


def main(argv):
    novel = json.loads(NOVEL.read_text(encoding="utf-8"))
    files = [Path(a) for a in argv] or sorted(EXTRACTION.glob("batch_*.json"))
    bad = 0
    for f in files:
        problems = validate(f, novel)
        status = "OK" if not problems else f"{len(problems)} problems"
        print(f"{f.name}: {status}")
        for p in problems[:200]:
            print("   ", p)
        bad += bool(problems)
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
