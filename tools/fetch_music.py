"""Fetch the music as WAV for the Windows and Linux packages (MUSIC-18).

The owner's three songs are single WAV release assets; the two Minifantasy tracks (Leohpaz) are taken from the zip in the
owner's "Minifantasy" release (zip and member each checked by size and sha256), so the pack itself is never committed.

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
import tempfile
import urllib.request
import zipfile
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


def download(url, out):
    for attempt in range(1, 4):
        try:
            print("downloading", url, flush=True)
            urllib.request.urlretrieve(url, out)
            return
        except OSError as e:
            if attempt == 3:
                raise SystemExit("could not download %s: %s" % (url, e))
            time.sleep(5 * attempt)


def check(path, size, digest, what):
    if path.stat().st_size != size:
        raise SystemExit("%s: %d bytes, expected %d" % (what, path.stat().st_size, size))
    if sha256(path) != digest:
        raise SystemExit("%s: sha256 differs from game/data/music.json" % what)


def zip_for(track, work, source_dir, cache):
    """The track's release zip, downloaded (or copied) once and checked."""
    if track["zip_url"] not in cache:
        z = Path(work) / track["zip_name"]
        if source_dir is not None:
            shutil.copyfile(Path(source_dir) / track["zip_name"], z)
        else:
            download(track["zip_url"], z)
        check(z, track["zip_bytes"], track["zip_sha256"], track["zip_name"])
        cache[track["zip_url"]] = z
    return cache[track["zip_url"]]


def fetch(track, dest, source_dir=None, work=None, cache=None):
    wav = dest / (track["id"] + ".wav")
    if "zip_url" in track:
        with zipfile.ZipFile(zip_for(track, work, source_dir, cache)) as z, z.open(track["zip_member"]) as src, open(wav, "wb") as out:
            shutil.copyfileobj(src, out)
    elif source_dir is not None:
        shutil.copyfile(Path(source_dir) / track["source_name"], wav)
    else:
        download(track["url"], wav)
    check(wav, track["bytes"], track["sha256"], track["id"])
    (dest / (track["id"] + ".wav.import")).write_text(IMPORT)
    print("ok %s (%d bytes, sha256 checked)" % (wav.name, track["bytes"]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dest", default=str(REPO / "game" / "assets" / "music"))
    ap.add_argument("--source-dir")
    args = ap.parse_args()
    dest = Path(args.dest)
    dest.mkdir(parents=True, exist_ok=True)
    tracks = [t for t in json.loads((REPO / "game" / "data" / "music.json").read_text())["tracks"] if "url" in t or "zip_url" in t]
    with tempfile.TemporaryDirectory() as work:
        cache = {}
        for t in tracks:
            fetch(t, dest, args.source_dir, work, cache)
    print("fetched %d tracks" % len(tracks))


if __name__ == "__main__":
    sys.exit(main())
