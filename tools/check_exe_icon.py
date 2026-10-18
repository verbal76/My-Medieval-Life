"""Check that a Windows .exe carries the game's icon (owner: the approved My Medieval Life artwork,
not Godot's default). Reads the executable's resources (RT_GROUP_ICON and RT_ICON) and compares every
icon image in it, pixel by pixel, with game/assets/icon/icon.ico scaled to that size (Godot's Windows
export re-encodes the icon into its own set of sizes, so the bytes differ but the pixels match).

    python3 tools/check_exe_icon.py path/to/MyMedievalLife.exe [--ico game/assets/icon/icon.ico]

Exit code 0 when every icon in the exe matches (mean colour difference under MAX_DIFF), 1 otherwise.
Needs Pillow.
"""
import io
import struct
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
RT_ICON, RT_GROUP_ICON = 3, 14


def ico_images(data: bytes) -> list:
    """The image payloads of an .ico file, in directory order: [(width, height, bytes)]."""
    _reserved, kind, count = struct.unpack_from("<HHH", data, 0)
    assert kind == 1, "not an icon file"
    out = []
    for i in range(count):
        w, h, _colors, _r, _planes, _bpp, size, offset = struct.unpack_from("<BBBBHHII", data, 6 + 16 * i)
        out.append((w or 256, h or 256, data[offset:offset + size]))
    return out


def exe_resources(data: bytes) -> dict:
    """{(type, id): bytes} for the first language of every resource of an executable."""
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    assert data[pe:pe + 4] == b"PE\0\0", "not a PE file"
    sections, opt_size = struct.unpack_from("<H", data, pe + 6)[0], struct.unpack_from("<H", data, pe + 20)[0]
    table = pe + 24 + opt_size
    rsrc = None
    for i in range(sections):
        name, vsize, vaddr, rsize, raw = struct.unpack_from("<8sIIII", data, table + 40 * i)
        if name.rstrip(b"\0") == b".rsrc":
            rsrc = (vaddr, raw)
    assert rsrc, "no resource section"
    base_rva, base_off = rsrc

    def entries(off):
        named, ids = struct.unpack_from("<HH", data, base_off + off + 12)
        for k in range(named + ids):
            name, target = struct.unpack_from("<II", data, base_off + off + 16 + 8 * k)
            yield name, target

    out = {}
    for rtype, t1 in entries(0):
        for rid, t2 in entries(t1 & 0x7FFFFFFF):
            for _lang, t3 in entries(t2 & 0x7FFFFFFF):
                rva, size = struct.unpack_from("<II", data, base_off + (t3 & 0x7FFFFFFF))
                off = base_off + rva - base_rva
                out[(rtype, rid)] = data[off:off + size]
                break
    return out


def exe_icon_images(data: bytes) -> list:
    """The images of the executable's first icon group: [(width, height, bytes)]."""
    res = exe_resources(data)
    groups = sorted(k for k in res if k[0] == RT_GROUP_ICON)
    assert groups, "no icon group in the executable"
    grp = res[groups[0]]
    count = struct.unpack_from("<H", grp, 4)[0]
    out = []
    for i in range(count):
        w, h, _c, _r, _p, _b, _size, icon_id = struct.unpack_from("<BBBBHHIH", grp, 6 + 14 * i)
        out.append((w or 256, h or 256, res[(RT_ICON, icon_id)]))
    return out


MAX_DIFF = 2.0          # mean per-channel difference allowed (0-255); Godot's default icon scores ~80+


def decode(w: int, h: int, payload: bytes):
    """An icon resource's image (PNG, or a DIB wrapped into a one-image .ico) as RGBA."""
    from PIL import Image
    if payload[:8] == b"\x89PNG\r\n\x1a\n":
        return Image.open(io.BytesIO(payload)).convert("RGBA")
    head = struct.pack("<HHH", 0, 1, 1) + struct.pack("<BBBBHHII", w % 256, h % 256, 0, 0, 1, 32, len(payload), 22)
    return Image.open(io.BytesIO(head + payload)).convert("RGBA")


def check(exe: Path, ico: Path) -> tuple:
    """(ok, [(width, height, mean difference)]) for the exe's icon images against the .ico's art."""
    from PIL import Image, ImageChops, ImageStat
    art = Image.open(ico)
    art.size = max(art.info.get("sizes", {(256, 256)}))
    art = art.convert("RGBA")
    rows = []
    for w, h, payload in exe_icon_images(exe.read_bytes()):
        diff = ImageStat.Stat(ImageChops.difference(decode(w, h, payload), art.resize((w, h), Image.LANCZOS))).mean
        rows.append((w, h, sum(diff[:3]) / 3))
    return bool(rows) and all(d <= MAX_DIFF for _w, _h, d in rows), rows


def main(argv):
    exe = Path(argv[0])
    ico = Path(argv[argv.index("--ico") + 1]) if "--ico" in argv else REPO / "game/assets/icon/icon.ico"
    ok, rows = check(exe, ico)
    for w, h, d in rows:
        print(f"  {w}x{h}: mean difference {d:.1f}")
    print(f"{exe.name}: the executable carries the game's icon" if ok else
          f"{exe.name}: MISMATCH: the executable does not carry the game's icon")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
