"""Rebuild the paragraph corpus of The Well at the World's End from the research sources.

The two owner-supplied research documents in research/sources/ quote paragraphs of
Project Gutenberg eBook 169 under stable ids like BONE-C1-P009 (book, chapter,
paragraph). Neither quotes every paragraph, but together they cover almost all of
them. This tool collects every quoted paragraph, checks that the two documents agree
wherever they quote the same id, and writes:

    research/corpus/paragraphs.json   {"format", "source_sha256", "chapters", "paragraphs", "missing"}

"missing" lists body paragraph numbers that fall inside a chapter's numbering but are
quoted by neither document (P001, the chapter heading, is never quoted and is not
counted as missing). The corpus is a reconstruction from the extraction documents,
not an independently verified edition of the novel.

Usage:
    python3 tools/lore/build_corpus.py
"""
import hashlib
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
SOURCES = REPO / "research" / "sources"
LORE = SOURCES / "My_Medieval_Life_Morris_Complete_Lore_Extraction.md"
GEO = SOURCES / "My_Medieval_Life_Morris_Geography_Map_Reference.md"
OUT = REPO / "research" / "corpus" / "paragraphs.json"

BOOKS = {"ONE": 1, "TWO": 2, "THREE": 3, "FOUR": 4}
ID_RE = re.compile(r"^\*\*(B(ONE|TWO|THREE|FOUR)-C(\d+)-P(\d+))\b")
CHAPTER_RE = re.compile(r"^- BOOK (ONE|TWO|THREE|FOUR) · CHAPTER (\d+): (.+)$")


def sort_key(pid):
    m = re.match(r"B(\w+)-C(\d+)-P(\d+)", pid)
    return BOOKS[m.group(1)], int(m.group(2)), int(m.group(3))


def quoted_paragraphs(path):
    """{id: text} for every '**ID ...' line followed by a '> ' quote line."""
    found, current = {}, None
    for line in path.read_text(encoding="utf-8").splitlines():
        m = ID_RE.match(line)
        if m:
            current = m.group(1)
            continue
        if current and line.startswith("> "):
            text = line[2:]
            if current in found and found[current] != text:
                raise ValueError(f"{path.name}: {current} quoted with two different texts")
            found[current] = text
            current = None
    return found


def chapter_titles():
    titles = {}
    for line in LORE.read_text(encoding="utf-8").splitlines():
        m = CHAPTER_RE.match(line)
        if m:
            titles[f"B{m.group(1)}-C{int(m.group(2))}"] = m.group(3).strip()
    return titles


def build():
    lore, geo = quoted_paragraphs(LORE), quoted_paragraphs(GEO)
    conflicts = [p for p in set(lore) & set(geo) if lore[p] != geo[p]]
    if conflicts:
        raise ValueError(f"research documents disagree on {len(conflicts)} paragraphs, e.g. {conflicts[:3]}")
    paragraphs = {**geo, **lore}
    titles = chapter_titles()
    chapters, by_chapter = [], {}
    for pid in sorted(paragraphs, key=sort_key):
        by_chapter.setdefault(pid.rsplit("-P", 1)[0], []).append(pid)
    missing = []
    for chap, title in titles.items():
        ids = by_chapter.get(chap, [])
        nums = {sort_key(p)[2] for p in ids}
        top = max(nums) if nums else 0
        gaps = [f"{chap}-P{n:03d}" for n in range(2, top + 1) if n not in nums]
        missing += gaps
        chapters.append({"id": chap, "title": title, "paragraphs": len(ids), "missing": gaps})
    digest = hashlib.sha256()
    for path in (LORE, GEO):
        digest.update(path.read_bytes())
    return {
        "format": "morris-corpus/1",
        "work": "William Morris, The Well at the World's End (1896), Project Gutenberg eBook 169",
        "provenance": ("Reconstructed from paragraphs quoted in the two research documents in "
                       "research/sources/. Both documents agree on every paragraph they share. Not "
                       "verified against an independent copy of the novel."),
        "source_sha256": digest.hexdigest(),
        "stats": {"paragraphs": len(paragraphs), "in_lore_doc": len(lore), "in_geography_doc": len(geo),
                  "in_both": len(set(lore) & set(geo)), "chapters": len(chapters), "missing": len(missing)},
        "chapters": chapters,
        "paragraphs": {pid: paragraphs[pid] for pid in sorted(paragraphs, key=sort_key)},
        "missing": missing,
    }


def main():
    corpus = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(corpus, ensure_ascii=False, indent=0) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(REPO)}: {corpus['stats']}")


if __name__ == "__main__":
    main()
