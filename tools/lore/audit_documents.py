"""Check the research documents' gazetteer and entity list against the novel.

The geography document opens with a "seed gazetteer": place strings with a candidate
type and a paragraph-hit count. The lore document has a frequency-ranked "named-entity
discovery inventory". Both were produced by keyword matching. This tool recounts every
string against research/corpus/novel.json (body paragraphs AND chapter titles, which the
documents did not search) and writes research/corpus/gazetteer_audit.json with:

  - strings that never occur in the novel (not canon)
  - strings that only occur in chapter titles (the documents reported 0 hits)
  - strings that only occur in lower case (a common noun such as "a white horse", not a name)
  - counts that differ from the documents'

Usage:
    python3 tools/lore/audit_documents.py
"""
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
GEO = REPO / "research" / "sources" / "My_Medieval_Life_Morris_Geography_Map_Reference.md"
LORE = REPO / "research" / "sources" / "My_Medieval_Life_Morris_Complete_Lore_Extraction.md"
NOVEL = REPO / "research" / "corpus" / "novel.json"
OUT = REPO / "research" / "corpus" / "gazetteer_audit.json"

ROW = re.compile(r"^\| (.+?) \| (.+?) \| (\d+) \| (.*) \|$")
INVENTORY = re.compile(r"^- \*\*(.+?)\*\* — (\d+) appearances$")


def variants(s):
    """The documents mix straight and curly apostrophes; the novel uses straight ones."""
    return {s, s.replace("’", "'")}


def count(novel, s, ignore_case=False):
    body = [p for c in novel["chapters"] for p in c["paragraphs"][1:]]
    titles = [c["paragraphs"][0] for c in novel["chapters"]]
    pat = re.compile(r"(?<![A-Za-z])" + "|".join(re.escape(v) for v in variants(s)) + r"(?![A-Za-z])",
                     re.I if ignore_case else 0)
    in_body = [p for p in body if pat.search(novel["paragraphs"][p])]
    in_titles = [p.rsplit("-P", 1)[0] for p in titles if pat.search(novel["paragraphs"][p])]
    return in_body, in_titles


def main():
    novel = json.loads(NOVEL.read_text(encoding="utf-8"))
    rows = []
    for line in GEO.read_text(encoding="utf-8").splitlines():
        m = ROW.match(line)
        if m and m.group(1) != "Location string":
            rows.append((m.group(1).strip(), m.group(2).strip(), int(m.group(3))))
    gaz = []
    for name, kind, doc_hits in rows:
        body, titles = count(novel, name)
        any_case, _ = count(novel, name, ignore_case=True)
        status = ("absent_from_novel" if not body and not titles else
                  "chapter_title_only" if not body else
                  "count_differs" if len(body) != doc_hits else "ok")
        if status == "absent_from_novel" and any_case:
            status = "common_noun_only"
        gaz.append({"string": name, "document_type": kind, "document_hits": doc_hits,
                    "novel_paragraph_hits": len(body), "any_case_paragraph_hits": len(any_case),
                    "chapter_title_hits": titles,
                    "first_paragraphs": body[:10], "status": status})
    inv = []
    for line in LORE.read_text(encoding="utf-8").splitlines():
        m = INVENTORY.match(line)
        if m:
            body, titles = count(novel, m.group(1))
            inv.append({"string": m.group(1), "document_count": int(m.group(2)),
                        "novel_paragraph_hits": len(body), "chapter_title_hits": len(titles)})
    out = {
        "format": "morris-gazetteer-audit/1",
        "note": ("Counts are paragraphs containing the exact string (word-bounded). Chapter titles are "
                 "counted separately. A string absent from the novel is not Morris canon. Whether each "
                 "string names a person, place or faction is decided in the registries, not here."),
        "gazetteer": gaz,
        "gazetteer_summary": {s: sum(1 for g in gaz if g["status"] == s)
                              for s in ("ok", "count_differs", "chapter_title_only", "common_noun_only",
                                        "absent_from_novel")},
        "entity_inventory": inv,
    }
    OUT.write_text(json.dumps(out, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(REPO)}: gazetteer {out['gazetteer_summary']}, inventory {len(inv)} strings")
    for g in gaz:
        if g["status"] != "ok":
            print(f"  {g['status']:20} {g['string']!r}: doc {g['document_hits']}, novel {g['novel_paragraph_hits']}"
                  f" (any case {g['any_case_paragraph_hits']})"
                  f"{', titles ' + ','.join(g['chapter_title_hits']) if g['chapter_title_hits'] else ''}")


if __name__ == "__main__":
    main()
