"""Scan every asset pack and write the asset registry (asset-integration-pipeline skill).

Reads docs/assets/packs.json (the hand-kept knowledge and decisions about each pack), opens every source
in place (zips, folders, private-assets/), and measures it: files by type, images and their sizes, each
sheet's frame grid and frames per row (tools/assets/sheets.py), the pack's licence and readme files, and
which of its files the game imported (game/assets/PROVENANCE.json). Writes:

    data/asset_registry.json       generated, deterministic: per pack, sizes, frame grids, licence files, imports
                                   (every image listed for packs of up to DETAIL_MAX images)
    docs/assets/ASSET_REGISTRY.md  generated, the readable registry

    python3 tools/assets/scan_packs.py            # rescan (unchanged files come from the cache)
    python3 tools/assets/scan_packs.py --check    # exit 1 if the written files are out of date

A private pack missing on this machine (a CI runner, a fresh clone) keeps its last measurements, so the
registry is identical on every clone; a pack never scanned anywhere is reported as not present.
"""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sheets  # noqa: E402

REPO = sheets.REPO
PACKS = REPO / "docs" / "assets" / "packs.json"
OUT_JSON = REPO / "data" / "asset_registry.json"
OUT_MD = REPO / "docs" / "assets" / "ASSET_REGISTRY.md"
CACHE = REPO / "out" / "asset_scan_cache.json"      # per-image measurements by checksum (git-ignored)
DETAIL_MAX = 150         # packs with at most this many images list every image in the registry
PROVENANCE = REPO / "game" / "assets" / "PROVENANCE.json"
LICENCE_RE = re.compile(r"(licen[cs]e|readme|credits?|terms|copying|\.url$)", re.I)
MAX_SIDE = 1024          # sheets larger than this are atlases: size only, no grid detection


def _provenance():
    p = json.loads(PROVENANCE.read_text())
    return p.get("files", p) if isinstance(p, dict) else p


def scan_source(rel, cache):
    src = sheets.Source(rel)
    if not src.exists():
        return {"source": rel, "present": False}
    files, images, licences, by_ext = 0, [], [], {}
    for m in src.members():
        files += 1
        ext = Path(m).suffix.lower() or "(none)"
        by_ext[ext] = by_ext.get(ext, 0) + 1
        if LICENCE_RE.search(Path(m).name):
            licences.append(m)
        if ext not in sheets.IMAGE_EXT:
            continue
        data = src.read(m)
        digest = hashlib.sha256(data).hexdigest()[:16]
        key = "%s|%s|%s" % (rel, m, digest)
        if key in cache:
            images.append(cache[key])
            continue
        try:
            img = sheets.Source.image(src, m)
        except Exception:
            rec = {"member": m, "sha": digest, "error": "unreadable"}
        else:
            rec = {"member": m, "sha": digest, "size": list(img.size), "content": list(img.getbbox() or (0, 0, 0, 0))}
            if img.width <= MAX_SIDE and img.height <= MAX_SIDE:
                cw, ch = sheets.detect_grid(img)
                rec["frame"] = [cw, ch]
                rec["frames_per_row"] = sheets.frames_per_row(img, cw, ch)
            else:
                rec["atlas"] = True
        cache[key] = rec
        images.append(rec)
    return {"source": rel, "present": True, "files": files, "by_ext": dict(sorted(by_ext.items())), "licence_files": licences,
            "images": images}


def _summary(s):
    """A source's scan reduced for the committed registry: histograms, and every image only for small packs."""
    imgs = s.pop("images", [])
    sizes, frames = {}, {}
    for r in imgs:
        if "size" in r:
            k = "%dx%d" % tuple(r["size"])
            sizes[k] = sizes.get(k, 0) + 1
        if "frame" in r and r["frame"] != r.get("size"):
            k = "%dx%d" % tuple(r["frame"])
            frames.setdefault(k, []).append(r["member"])
    s["image_count"] = len(imgs)
    s["sizes"] = dict(sorted(sizes.items(), key=lambda kv: (-kv[1], kv[0]))[:12])
    s["frame_grids"] = {k: {"sheets": len(v), "example": sorted(v)[0]} for k, v in sorted(frames.items(), key=lambda kv: (-len(kv[1]), kv[0]))[:12]}
    if len(imgs) <= DETAIL_MAX:
        s["images"] = imgs
    return s


def build(old, cache):
    meta = json.loads(PACKS.read_text())
    prov = _provenance()
    out = []
    for p in meta["packs"]:
        scans = []
        for rel in p["sources"]:
            s = scan_source(rel, cache)
            if not s["present"]:
                prev = next((x for q in old.get("packs", []) for x in q.get("scan", []) if x["source"] == rel), None)
                if prev:
                    scans.append(prev)       # last measured where the pack was present: the same on every clone
                    continue
            scans.append(_summary(s) if s["present"] else s)
        names = set(p["sources"]) | {Path(r).name for r in p["sources"]}
        imported = sorted(f["file"] for f in prov if str(f.get("source", "")) in names)
        out.append(dict(p, scan=scans, imported=imported))
    return {"format": "mml-asset-registry/1", "note": "Generated by tools/assets/scan_packs.py from docs/assets/packs.json; do not edit.", "packs": out}


def _sizes(scans):
    count = {}
    for s in scans:
        for k, v in s.get("sizes", {}).items():
            count[k] = count.get(k, 0) + v
    return ", ".join("%s (%d)" % kv for kv in sorted(count.items(), key=lambda kv: (-kv[1], kv[0]))[:6])


def _frames(scans):
    seen = {}
    for s in scans:
        for k, v in s.get("frame_grids", {}).items():
            n, ex = seen.get(k, (0, v["example"]))
            seen[k] = (n + v["sheets"], ex)
    return "; ".join("%s: %d sheets (e.g. %s)" % (k, n, Path(ex).name) for k, (n, ex) in sorted(seen.items(), key=lambda kv: -kv[1][0])[:8])


def render(reg):
    rows = ["# Asset registry", "",
            "Generated by `tools/assets/scan_packs.py` from `docs/assets/packs.json` (hand-kept decisions) and a scan of every pack; do not edit by hand. "
            "Policy: CLAUDE.md, \"Asset integration policy\". Scaling: `docs/assets/ASSET_SCALING_STANDARD.md`. Skill: `.claude/skills/asset-integration-pipeline/`.", "",
            "| Pack | Creator | Licence | Storage | Status | Files | Images | Imported into the game |", "|---|---|---|---|---|---|---|---|"]
    for p in reg["packs"]:
        files = sum(s.get("files", 0) for s in p["scan"])
        imgs = sum(s.get("image_count", 0) for s in p["scan"])
        here = "" if all(s.get("present") for s in p["scan"]) else " (not all present here)"
        rows.append("| %s | %s | %s | %s | %s | %d%s | %d | %d |" % (p["name"], p["creator"], p["licence"], p["storage"], p["status"], files, here, imgs, len(p["imported"])))
    rows.append("")
    for p in reg["packs"]:
        rows += ["## %s" % p["name"], ""]
        rows.append("- **Sources:** %s" % ", ".join("`%s`%s" % (s["source"], "" if s.get("present") else " (not present on this machine)") for s in p["scan"]))
        rows.append("- **Licence:** %s. %s" % (p["licence"], p["permissions"]))
        lic = [m for s in p["scan"] for m in s.get("licence_files", [])]
        rows.append("- **Licence and readme files in the pack:** %s" % (", ".join("`%s`" % m for m in lic[:6]) if lic else "none (terms from the page the owner supplied; ASSET_MANIFEST.md)"))
        rows.append("- **Categories:** %s; **status:** %s" % (", ".join(p.get("categories", [])) or "-", p["status"]))
        if any(s.get("image_count") for s in p["scan"]):
            rows.append("- **Image sizes:** %s" % _sizes(p["scan"]))
            fr = _frames(p["scan"])
            if fr:
                rows.append("- **Detected frame grids:** %s" % fr)
        exts = {}
        for s in p["scan"]:
            for k, v in s.get("by_ext", {}).items():
                exts[k] = exts.get(k, 0) + v
        if exts:
            rows.append("- **Files by type:** %s" % ", ".join("%s %d" % kv for kv in sorted(exts.items())))
        for key, label in [("scale", "Scale"), ("used_for", "Used for"), ("opportunities", "Opportunities"), ("decision", "Decision"), ("known_issues", "Known issues")]:
            if p.get(key):
                rows.append("- **%s:** %s" % (label, p[key]))
        rows.append("- **Imported game files (%d):** %s" % (len(p["imported"]), ", ".join("`%s`" % f for f in p["imported"][:12]) + (" ..." if len(p["imported"]) > 12 else "") if p["imported"] else "none"))
        rows.append("")
    return "\n".join(rows) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    old = json.loads(OUT_JSON.read_text()) if OUT_JSON.exists() else {}
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    reg = build(old, cache)
    CACHE.parent.mkdir(exist_ok=True)
    CACHE.write_text(json.dumps(cache))
    text = json.dumps(reg, indent=1, sort_keys=False) + "\n"
    md = render(reg)
    if a.check:
        stale = (not OUT_JSON.exists() or OUT_JSON.read_text() != text) or (not OUT_MD.exists() or OUT_MD.read_text() != md)
        print("asset registry %s" % ("out of date (run tools/assets/scan_packs.py)" if stale else "up to date"))
        sys.exit(1 if stale else 0)
    OUT_JSON.write_text(text)
    OUT_MD.write_text(md)
    print("%d packs, %d images scanned" % (len(reg["packs"]), sum(s.get("image_count", 0) for p in reg["packs"] for s in p["scan"])))


if __name__ == "__main__":
    main()
