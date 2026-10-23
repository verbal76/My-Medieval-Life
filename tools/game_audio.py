"""Import the game's music and ambience: Ogg Vorbis files made with ffmpeg, recorded in PROVENANCE.json.

Two sources (CLAUDE.md section 3, private asset workflow; owner directive 2026-10-23, docs/directives/2026-10-23_game_music.md):

  music    The owner's three songs (made with Suno), published as GitHub release assets on verbal76/My-Medieval-Life.
           game/data/music.json lists each with its URL, size and sha256. Windows and Linux ship the original WAVs
           (downloaded by .github/workflows/release.yml, never committed: 173 MB); Android carries Ogg Vorbis. This tool
           encodes the WAVs to game/assets/music/<id>.ogg (libvorbis, -q:a 4), the only music files committed.
           The WAVs are read from $MML_MUSIC_SOURCE, else private-assets/music/, else out/music_src/; with
           --download they are fetched from their release URLs into out/music_src/ first (sha256 checked).
  sfx      Cozy RPG SFX by Spaceyyy (Bramble & Byte): the ambience loops (private-assets/cozy-rpg-sfx-ambience-*.zip)
           and the effects the game wires (private-assets/cozy-rpg-sfx.zip, ids in game/data/music.json). Use in games
           is allowed, the sounds themselves may not be redistributed as assets. Each WAV is encoded to
           game/assets/sfx/<id>.ogg (the game loops the 16 s seamless ambience at run time).

ffmpeg is a developer tool and is never shipped. A source that is missing leaves the files already imported (and their
provenance) as they are.

    python3 tools/game_audio.py [--download]      # also run by tools/import_game_assets.py
"""
import hashlib
import json
import os
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MUSIC_JSON = REPO / "game" / "data" / "music.json"
MUSIC_OUT = REPO / "game" / "assets" / "music"
SFX_OUT = REPO / "game" / "assets" / "sfx"
QUALITY = "4"                                   # libvorbis -q:a (about 128 kbit/s)
SFX_PACKS = {                                   # id -> (zip in private-assets/, member)
    "forest": ("cozy-rpg-sfx-ambience-2.zip", "cozy-rpg-sfx/ambience/ambience-forest.wav"),
    "cave_wind": ("cozy-rpg-sfx-ambience-2.zip", "cozy-rpg-sfx/ambience/ambience-cave-wind.wav"),
    "dungeon": ("cozy-rpg-sfx-ambience-1.zip", "cozy-rpg-sfx/ambience/ambience-dungeon.wav"),
    "campfire": ("cozy-rpg-sfx-ambience-1.zip", "cozy-rpg-sfx/ambience/ambience-campfire.wav"),
}
MINI_SFX_ZIP = "Minifantasy_Forgotten_Plains_SFX.zip"        # Minifantasy: Forgotten Plains SFX by Leohpaz (members are at the zip's root)
MINI_LOOPS = {"birds": "13_Birds_loop", "crickets": "11_Crickets_2_loop", "cicada": "12_Cicada_loop", "wind": "14_Wind_loop"}
MINI_VARIANTS = {"bush_rustling": ("01_bush_rustling", 3), "tree_rustling": ("02_tree_rustling", 4), "fruit_drop": ("03_fruit_drop", 2),
                 "step_grass": ("04_step_grass", 3), "step_dirt": ("05_step_dirt", 3), "step_stone": ("06_step_stone", 3),
                 "hit_on_wood": ("15_Hit_on_wood", 2), "hit_on_brick": ("16_Hit_on_brick", 2)}
MINI_MUSIC_ZIP = "Minifantasy_ForgottenPlains_Music.zip"     # Minifantasy: Forgotten Plains music by Leohpaz
MINI_MUSIC = {"fair_fight": "Minifantasy_ForgottenPlains_Music/Music/Fair_Fight_(Battle).wav",
              "plain_sight": "Minifantasy_ForgottenPlains_Music/Music/Plain_Sight_(Regular).wav"}
MINI_MUSIC_QUALITY = "6"                       # these two are committed as Ogg on every platform, so a higher quality than the Android copies
SFX_PACK_NAME = "Cozy RPG SFX by Spaceyyy (Bramble & Byte)"


def _sha_bytes(data):
    return hashlib.sha256(data).hexdigest()


def _sha(path):
    return _sha_bytes(Path(path).read_bytes())


def private_dir():
    return Path(os.environ.get("MML_PRIVATE_ASSETS") or REPO / "private-assets")


def music_dirs():
    env = os.environ.get("MML_MUSIC_SOURCE")
    return ([Path(env)] if env else []) + [private_dir() / "music", REPO / "out" / "music_src"]


def encode(src_wav, dest):
    """Encode one WAV to Ogg Vorbis (libvorbis); no metadata, so the file carries nothing but the audio."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src_wav), "-map_metadata", "-1", "-vn",
                    "-c:a", "libvorbis", "-q:a", QUALITY, str(dest)], check=True)


def download_music(track_list, folder):
    """Fetch each song from its release URL into `folder`, checking size and sha256."""
    folder.mkdir(parents=True, exist_ok=True)
    for t in track_list:
        path = folder / t["source_name"]
        if path.is_file() and _sha(path) == t["sha256"]:
            continue
        print("downloading", t["url"])
        urllib.request.urlretrieve(t["url"], path)
        if path.stat().st_size != t["bytes"] or _sha(path) != t["sha256"]:
            raise SystemExit("%s: size or sha256 differs from game/data/music.json" % path)


def _keep(prov, source_names):
    """Carry over the provenance of files that could not be re-imported."""
    old = REPO / "game" / "assets" / "PROVENANCE.json"
    if old.exists():
        prov.extend(e for e in json.loads(old.read_text())["files"] if e.get("source") in source_names)


def import_music(prov, record, download=False):
    tracks = [t for t in json.loads(MUSIC_JSON.read_text())["tracks"] if "url" in t]      # the owner's releases (the pack songs have none)
    if download:
        download_music(tracks, REPO / "out" / "music_src")
    n = 0
    missing = []
    for t in tracks:
        src = next((d / t["source_name"] for d in music_dirs() if (d / t["source_name"]).is_file()), None)
        if src is None:
            missing.append(t["source_name"])
            continue
        if _sha(src) != t["sha256"]:
            raise SystemExit("%s differs from the sha256 in game/data/music.json" % src)
        dest = MUSIC_OUT / (t["id"] + ".ogg")
        encode(src, dest)
        record(dest, t["url"], t["source_name"],
               "encoded to Ogg Vorbis with ffmpeg/libvorbis -q:a %s (Android's copy; PC builds use the original WAV: %d bytes, sha256 %s)"
               % (QUALITY, t["bytes"], t["sha256"]))
        n += 1
    if missing:
        print("music not found (%s): its Ogg files are left as they are; try --download" % ", ".join(missing))
        _keep(prov, {t["url"] for t in tracks if t["source_name"] in missing})
    return n


def sfx_sources():
    """id -> (zip, member): the four ambience loops and every effect game/data/music.json lists (names use dashes in the pack)."""
    out = dict(SFX_PACKS)
    for sid in json.loads(MUSIC_JSON.read_text())["sfx"]["ids"]:
        out[sid] = ("cozy-rpg-sfx.zip", "cozy-rpg-sfx/sfx/%s.wav" % sid.replace("_", "-"))
    for sid, stem in MINI_LOOPS.items():
        out[sid] = (MINI_SFX_ZIP, stem + ".wav")
    for base, (stem, n) in MINI_VARIANTS.items():
        for i in range(1, n + 1):
            out["%s_%d" % (base, i)] = (MINI_SFX_ZIP, "%s_%d.wav" % (stem, i))
    return out


def import_sfx(prov, record):
    n = 0
    for sid, (zip_name, member) in sorted(sfx_sources().items()):
        path = private_dir() / zip_name
        if not path.is_file():
            print("%s not found: the %s sound is left as it is" % (zip_name, sid))
            _keep(prov, {zip_name})
            continue
        tmp = REPO / "out" / "audio_tmp"
        tmp.mkdir(parents=True, exist_ok=True)
        wav = tmp / (sid + ".wav")
        wav.write_bytes(zipfile.ZipFile(path).read(member))
        dest = SFX_OUT / (sid + ".ogg")
        encode(wav, dest)
        wav.unlink()
        record(dest, zip_name, member, "encoded to Ogg Vorbis with ffmpeg/libvorbis -q:a %s%s" % (QUALITY, "; the game loops it (a seamless loop)" if sid in SFX_PACKS or sid in MINI_LOOPS else ""))
        n += 1
    return n


def import_pack_music(prov, record):
    """The two Minifantasy songs (fight, countryside): Ogg Vorbis on every platform, from private-assets/."""
    n = 0
    path = private_dir() / MINI_MUSIC_ZIP
    if not path.is_file():
        print("%s not found: its two songs are left as they are" % MINI_MUSIC_ZIP)
        _keep(prov, {MINI_MUSIC_ZIP})
        return 0
    tmp = REPO / "out" / "audio_tmp"
    tmp.mkdir(parents=True, exist_ok=True)
    for tid, member in sorted(MINI_MUSIC.items()):
        wav = tmp / (tid + ".wav")
        wav.write_bytes(zipfile.ZipFile(path).read(member))
        dest = MUSIC_OUT / (tid + ".ogg")
        dest.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-map_metadata", "-1", "-vn",
                        "-c:a", "libvorbis", "-q:a", MINI_MUSIC_QUALITY, str(dest)], check=True)
        wav.unlink()
        record(dest, MINI_MUSIC_ZIP, member, "encoded to Ogg Vorbis with ffmpeg/libvorbis -q:a %s (used on every platform: the pack may not be redistributed, so its WAV is not committed)" % MINI_MUSIC_QUALITY)
        n += 1
    return n


def import_into(prov, record, download=False):
    """Entry point for tools/import_game_assets.py. Returns the number of files written."""
    n = import_music(prov, record, download) + import_pack_music(prov, record) + import_sfx(prov, record)
    print("encoded %d audio files" % n)
    return n


def main():
    prov_path = REPO / "game" / "assets" / "PROVENANCE.json"
    doc = json.loads(prov_path.read_text())
    prov = [e for e in doc["files"] if not e["file"].startswith(("assets/music/", "assets/sfx/"))]
    # files not re-imported keep their entries
    keep = [e for e in doc["files"] if e["file"].startswith(("assets/music/", "assets/sfx/"))]

    def record(dest, source, member, how):
        prov.append({"file": str(Path(dest).relative_to(REPO / "game")), "source": source, "member": member,
                     "transform": how, "sha256": _sha(dest)})

    before = len(prov)
    import_into([], record, "--download" in sys.argv)
    done = {e["file"] for e in prov[before:]}
    prov.extend(e for e in keep if e["file"] not in done)
    doc["files"] = prov
    prov_path.write_text(json.dumps(doc, indent=1) + "\n")


if __name__ == "__main__":
    main()
