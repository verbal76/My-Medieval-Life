"""Fetch the owner's three songs as WAV for the Windows and Linux packages (MUSIC-18).

The songs are release assets of verbal76/My-Medieval-Life (game/data/music.json lists each URL, size and sha256).
They are 173 MB, so they are never committed (.gitignore); .github/workflows/release.yml runs this before the project is
imported. Each download is checked against its recorded size and sha256 and saved as game/assets/music/<id>.wav, with a
<id>.wav.import beside it that tells Godot to keep the sound as plain PCM (compress/mode=0: the original quality; the
importer's default is lossy QOA). The Android export excludes the WAVs (game/export_presets.cfg), the PC exports
exclude the Ogg copies, and the game plays the WAV when it is there, else the Ogg.

    python3 tools/fetch_music.py [--dest DIR] [--source-dir DIR]     # --source-dir: copy from local files, no download
"""
import argparse
import hashlib
import json
import shutil
import sys
import time
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
IMPORT = """[remap]

importer="wav"
type="AudioStreamWAV"

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=0
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
"""


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def fetch(track, dest, source_dir=None):
    wav = dest / (track["id"] + ".wav")
    if source_dir is not None:
        shutil.copyfile(Path(source_dir) / track["source_name"], wav)
    else:
        for attempt in range(1, 4):
            try:
                print("downloading", track["url"], flush=True)
                urllib.request.urlretrieve(track["url"], wav)
                break
            except OSError as e:
                if attempt == 3:
                    raise SystemExit("could not download %s: %s" % (track["url"], e))
                time.sleep(5 * attempt)
    if wav.stat().st_size != track["bytes"]:
        raise SystemExit("%s: %d bytes, expected %d" % (track["id"], wav.stat().st_size, track["bytes"]))
    if sha256(wav) != track["sha256"]:
        raise SystemExit("%s: sha256 differs from game/data/music.json" % track["id"])
    (dest / (track["id"] + ".wav.import")).write_text(IMPORT)
    print("ok %s (%d bytes, sha256 checked)" % (wav.name, track["bytes"]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dest", default=str(REPO / "game" / "assets" / "music"))
    ap.add_argument("--source-dir")
    args = ap.parse_args()
    dest = Path(args.dest)
    dest.mkdir(parents=True, exist_ok=True)
    tracks = [t for t in json.loads((REPO / "game" / "data" / "music.json").read_text())["tracks"] if "url" in t]
    for t in tracks:
        fetch(t, dest, args.source_dir)
    print("fetched %d songs" % len(tracks))


if __name__ == "__main__":
    sys.exit(main())
