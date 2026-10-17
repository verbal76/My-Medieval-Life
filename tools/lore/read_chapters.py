"""Print chapters of the novel compactly for reading, with chapter-local paragraph numbers.

Usage:
    python3 tools/lore/read_chapters.py BONE-C1 BONE-C2
"""
import json
import sys
from pathlib import Path

NOVEL = Path(__file__).resolve().parent.parent.parent / "research" / "corpus" / "novel.json"


def main(argv):
    novel = json.loads(NOVEL.read_text(encoding="utf-8"))
    chapters = {c["id"]: c for c in novel["chapters"]}
    for cid in argv:
        c = chapters[cid]
        print(f"=== {cid} · {c['title']} ({len(c['paragraphs']) - 1} paragraphs)")
        for pid in c["paragraphs"][1:]:
            print(f"{pid.rsplit('-', 1)[1]} {novel['paragraphs'][pid]}")


if __name__ == "__main__":
    main(sys.argv[1:])
