"""Split the original novel into chapters and stable paragraph ids, and audit the research documents.

Reads research/sources/pg169.txt (Project Gutenberg eBook 169, The Well at the World's
End) and writes research/corpus/novel.json:

    {"format", "source_sha256", "boundaries", "front_matter", "books": [...],
     "chapters": [{"id", "book", "number", "title", "paragraphs": [ids]}],
     "paragraphs": {id: text}}

Literary boundaries. Everything up to and including Gutenberg's "*** START" marker, and
everything from the "*** END" marker on (licence, donation and distribution notices), is
Project Gutenberg's material and is excluded. Between them are the author's title page and
table of contents (kept as front_matter: they give the book and chapter titles), then the
tale itself from the first bare "BOOK ONE" line to "AND HERE ENDS THE TALE OF THE WELL AT
THE WORLD'S END." The exact line numbers are recorded in "boundaries", and the tale is
checked for any leftover Gutenberg or transcriber material.

Ids follow the scheme used by the two research documents: BONE-C1-P002 = book one,
chapter 1, paragraph 2. P001 is the chapter title; body paragraphs start at P002.
A paragraph is a block of lines separated by blank lines, joined with single spaces.

It then compares the novel with research/corpus/paragraphs.json (the paragraphs the
research documents quote) and writes research/corpus/document_audit.json: which ids
match exactly, differ, or exist in only one of the two.

Usage:
    python3 tools/lore/build_novel.py
"""
import hashlib
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
NOVEL = REPO / "research" / "sources" / "pg169.txt"
DOC_CORPUS = REPO / "research" / "corpus" / "paragraphs.json"
OUT = REPO / "research" / "corpus" / "novel.json"
AUDIT = REPO / "research" / "corpus" / "document_audit.json"

START = "*** START OF THE PROJECT GUTENBERG EBOOK"
END = "*** END OF THE PROJECT GUTENBERG EBOOK"
LAST_WORDS = "TALE OF THE WELL AT THE WORLD'S END."
# Things that would only appear in publisher/digitisation material, never in Morris's prose.
ADMIN_PATTERNS = [r"gutenberg", r"https?://", r"www\.", r"\be-?book", r"\be-?text", r"transcriber",
                  r"\blicen[cs]e\b", r"copyright", r"donat(e|ion)", r"\bunicode\b", r"\butf-?8\b",
                  r"\bascii\b", r"\bPGLAF\b", r"\bEIN\b", r"[^\x00-\x7f]"]
# Exclusion is by the boundaries above; these patterns only flag paragraphs for a human look.
# Hits that were checked and are Morris's own words are listed here with the reason.
REVIEWED_LITERARY = {
    "BONE-C12-P022": "a weapon-seller asks for a licence to buy weapons under the seal of the Burg",
    "BONE-C12-P023": "same scene: the craft's law requires the licence",
    "BTWO-C30-P010": "'leave and license' to send sergeants with a traveller",
    "BFOUR-C8-P003": "the Clerk of the Porte at Goldburg brings a licence to wage men",
}
BOOK_NAMES = {"ONE": 1, "TWO": 2, "THREE": 3, "FOUR": 4}


def blocks(lines):
    """Blank-line separated blocks, each joined into one string."""
    out, cur = [], []
    for line in lines:
        if line.strip():
            cur.append(line.strip())
        elif cur:
            out.append(" ".join(cur))
            cur = []
    if cur:
        out.append(" ".join(cur))
    return out


def parse():
    raw = NOVEL.read_bytes()
    lines = raw.decode("utf-8").replace("\r\n", "\n").split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith(START))
    end = next(i for i, l in enumerate(lines) if l.startswith(END))
    # the table of contents also says "BOOK ONE ..."; the tale begins at a bare "BOOK ONE" line
    tale_first = next(i for i in range(start, end) if lines[i].strip() == "BOOK ONE")
    tale_last = max(i for i in range(start, end) if LAST_WORDS in lines[i])
    front = [l for l in lines[start + 1:tale_first]]
    body = lines[tale_first:tale_last + 1]
    boundaries = {
        "file_lines": len(lines),
        "gutenberg_header": [1, start + 1],
        "front_matter": [start + 2, tale_first],
        "tale": [tale_first + 1, tale_last + 1],
        "gutenberg_footer": [end + 1, len(lines)],
        "note": "1-based inclusive line ranges; header and footer are Project Gutenberg material and excluded",
    }

    books, chapters, paragraphs = [], [], {}
    book, i = None, 0
    marks = [(k, l.strip()) for k, l in enumerate(body)
             if re.fullmatch(r"BOOK (ONE|TWO|THREE|FOUR)", l.strip()) or re.fullmatch(r"CHAPTER \d+", l.strip())]
    for n, (k, mark) in enumerate(marks):
        stop = marks[n + 1][0] if n + 1 < len(marks) else len(body)
        chunk = blocks(body[k + 1:stop])
        if mark.startswith("BOOK"):
            book = mark.split()[1]
            books.append({"id": f"B{book}", "number": BOOK_NAMES[book], "title": chunk[0] if chunk else ""})
            continue
        num = int(mark.split()[1])
        cid = f"B{book}-C{num}"
        ids = []
        for p, text in enumerate(chunk, start=1):
            pid = f"{cid}-P{p:03d}"
            paragraphs[pid] = text
            ids.append(pid)
        chapters.append({"id": cid, "book": BOOK_NAMES[book], "number": num, "title": chunk[0],
                         "paragraphs": ids})
    toc = [l.strip() for l in front if re.match(r"\s+\d+\s\s", l)]
    toc_titles = [re.sub(r"^\d+\s+", "", t) for t in toc]
    # the chapter heading in the text is authoritative; a few contents entries are shortened
    sp = lambda t: re.sub(r"\s+", " ", t)
    if len(toc_titles) != len(chapters) or any(not sp(c["title"]).startswith(sp(t))
                                               for t, c in zip(toc_titles, chapters)):
        raise ValueError("chapter titles in the text do not match the table of contents")
    toc_shortened = [{"chapter": c["id"], "contents": t, "heading": c["title"]}
                     for t, c in zip(toc_titles, chapters) if sp(t) != sp(c["title"])]
    admin = [(pid, pat) for pid, text in paragraphs.items() for pat in ADMIN_PATTERNS
             if re.search(pat, text, re.I)]
    unreviewed = sorted({pid for pid, _ in admin if pid not in REVIEWED_LITERARY})
    if unreviewed:
        raise ValueError(f"possible publisher material inside the tale, review: {unreviewed}")
    return {
        "format": "morris-novel/1",
        "work": "William Morris, The Well at the World's End (1896), Project Gutenberg eBook 169",
        "source": "research/sources/pg169.txt",
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "boundaries": boundaries,
        "front_matter": {"title": "The Well at the World's End", "author": "William Morris",
                         "table_of_contents": toc_titles,
                         "contents_entries_shorter_than_heading": toc_shortened},
        "admin_term_flags": [{"paragraph": p, "pattern": pat, "reviewed_as_literary": REVIEWED_LITERARY[p]}
                             for p, pat in admin],
        "stats": {"books": len(books), "chapters": len(chapters), "paragraphs": len(paragraphs),
                  "body_paragraphs": len(paragraphs) - len(chapters),
                  "words": sum(len(t.split()) for t in paragraphs.values())},
        "books": books,
        "chapters": chapters,
        "paragraphs": paragraphs,
    }


def audit(novel):
    docs = json.loads(DOC_CORPUS.read_text(encoding="utf-8"))["paragraphs"]
    norm = lambda s: re.sub(r"\s+", " ", s).strip()
    exact, whitespace_only, differ = [], [], []
    for pid, text in docs.items():
        if pid not in novel["paragraphs"]:
            continue
        if text == novel["paragraphs"][pid]:
            exact.append(pid)
        elif norm(text) == norm(novel["paragraphs"][pid]):
            whitespace_only.append(pid)
        else:
            differ.append(pid)
    body = [p for c in novel["chapters"] for p in c["paragraphs"][1:]]
    return {
        "format": "morris-document-audit/1",
        "compared": len(docs),
        "exact": len(exact),
        "whitespace_only": whitespace_only,
        "differ": differ,
        "only_in_documents": sorted(set(docs) - set(novel["paragraphs"])),
        "body_paragraphs_not_quoted_by_documents": [p for p in body if p not in docs],
        "chapter_titles_quoted_by_documents": [c["paragraphs"][0] for c in novel["chapters"]
                                               if c["paragraphs"][0] in docs],
    }


def main():
    novel = parse()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(novel, ensure_ascii=False, indent=0) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(REPO)}: {novel['stats']}")
    print("boundaries:", novel["boundaries"])
    print(f"admin-term flags inside the tale: {len(novel['admin_term_flags'])}, all reviewed as Morris's text")
    if DOC_CORPUS.exists():
        a = audit(novel)
        AUDIT.write_text(json.dumps(a, indent=1) + "\n", encoding="utf-8")
        print(f"wrote {AUDIT.relative_to(REPO)}: compared {a['compared']}, exact {a['exact']}, "
              f"whitespace-only {len(a['whitespace_only'])}, differ {len(a['differ'])}, "
              f"only in documents {len(a['only_in_documents'])}, "
              f"novel body paragraphs not quoted {len(a['body_paragraphs_not_quoted_by_documents'])}")


if __name__ == "__main__":
    main()
