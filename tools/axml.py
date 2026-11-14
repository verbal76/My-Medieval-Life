"""Read Android's binary XML (AXML), the compiled form of AndroidManifest.xml inside an APK, with the standard library only.

The release gate (tools/check_android_apk.py, B42-ANDROID-DEBUGGABLE) uses it to read what an exported APK really declares
(package id, versionCode, versionName, android:debuggable, android:testOnly) without aapt, so the check does not depend on
which build-tools a runner has. Ported from Agent B's Build 41 package inspection script (2026-11-13).

    python3 tools/axml.py path/to/app.apk           # prints every element with its attributes, as JSON lines
    python3 tools/axml.py path/to/AndroidManifest.xml

Library: elements(data) -> [(tag, {attr: value})] in document order; manifest_facts(data) -> the facts the gate checks.
Values are decoded by type: strings as str, booleans (TYPE_INT_BOOLEAN) as bool, integers as int, references as "@0x7f..".
"""
import json
import struct
import sys
import zipfile

RES_XML_TYPE = 0x0003
RES_STRING_POOL_TYPE = 0x0001
RES_XML_RESOURCE_MAP_TYPE = 0x0180
RES_XML_START_ELEMENT_TYPE = 0x0102
NO_ENTRY = 0xFFFFFFFF
UTF8_FLAG = 0x100

# android:* attribute resource ids, for manifests whose attribute-name strings were stripped (obfuscated APKs)
ANDROID_ATTR_IDS = {
    0x0101000F: "debuggable",
    0x0101021B: "versionCode",
    0x0101021C: "versionName",
    0x01010270: "testOnly",
    0x01010003: "name",
    0x01010001: "label",
}

# Res_value data types
TYPE_REFERENCE = 0x01
TYPE_STRING = 0x03
TYPE_INT_DEC = 0x10
TYPE_INT_HEX = 0x11
TYPE_INT_BOOLEAN = 0x12


class AxmlError(ValueError):
    pass


def _string_pool(b, off):
    _t, hs, _sz, count, _styles, flags, strings_start, _styles_start = struct.unpack_from("<HHIIIIII", b, off)
    offsets = struct.unpack_from("<%dI" % count, b, off + hs)
    out = []
    for o in offsets:
        p = off + strings_start + o
        if flags & UTF8_FLAG:
            n = b[p]                                        # length in UTF-16 units (1 or 2 bytes), skipped
            p += 2 if n & 0x80 else 1
            n = b[p]                                        # length in bytes (1 or 2 bytes)
            if n & 0x80:
                n = ((n & 0x7F) << 8) | b[p + 1]
                p += 2
            else:
                p += 1
            out.append(b[p:p + n].decode("utf-8", "replace"))
        else:
            n = struct.unpack_from("<H", b, p)[0]
            p += 2
            if n & 0x8000:
                n = ((n & 0x7FFF) << 16) | struct.unpack_from("<H", b, p)[0]
                p += 2
            out.append(b[p:p + 2 * n].decode("utf-16le", "replace"))
    return out


def _value(strings, raw, dtype, data):
    if raw != NO_ENTRY and raw < len(strings):
        return strings[raw]
    if dtype == TYPE_INT_BOOLEAN:
        return data != 0
    if dtype == TYPE_REFERENCE:
        return "@0x%08x" % data
    if dtype == TYPE_STRING and data < len(strings):
        return strings[data]
    if dtype in (TYPE_INT_DEC, TYPE_INT_HEX):
        return data
    return data


def elements(b):
    """Every start element of the AXML document `b`, in order, as (tag, {attribute name: decoded value})."""
    if len(b) < 8:
        raise AxmlError("too short to be binary XML")
    t, hs, size = struct.unpack_from("<HHI", b, 0)
    if t != RES_XML_TYPE:
        raise AxmlError("not binary XML (chunk type 0x%04x; a text manifest is not an exported APK's)" % t)
    end = min(size, len(b))
    p = hs
    strings, resmap, out = [], [], []
    while p + 8 <= end:
        t, hs, size = struct.unpack_from("<HHI", b, p)
        if size < 8:
            raise AxmlError("corrupt chunk at %d" % p)
        if t == RES_STRING_POOL_TYPE:
            strings = _string_pool(b, p)
        elif t == RES_XML_RESOURCE_MAP_TYPE:
            resmap = list(struct.unpack_from("<%dI" % ((size - hs) // 4), b, p + hs))
        elif t == RES_XML_START_ELEMENT_TYPE:
            _ns, name, attr_start, attr_size, attr_count = struct.unpack_from("<IIHHH", b, p + 16)
            attrs = {}
            for i in range(attr_count):
                a = p + 16 + attr_start + i * attr_size
                _ans, an, raw, _vs, _res0, dtype, data = struct.unpack_from("<IIIHBBI", b, a)
                key = strings[an] if an < len(strings) else ""
                if not key and an < len(resmap):
                    key = ANDROID_ATTR_IDS.get(resmap[an], "0x%08x" % resmap[an])
                attrs[key] = _value(strings, raw, dtype, data)
            out.append((strings[name], attrs))
        p += size
    return out


def manifest_bytes(path):
    """The binary AndroidManifest.xml of an APK, or the file itself when `path` is a manifest."""
    if zipfile.is_zipfile(path):
        with zipfile.ZipFile(path) as z:
            return z.read("AndroidManifest.xml")
    with open(path, "rb") as f:
        return f.read()


def manifest_facts(b):
    """What the release gate checks: {package, versionCode, versionName, debuggable, testOnly, minSdk, targetSdk}.
    debuggable and testOnly are False when absent (Android's default)."""
    els = elements(b)
    man = next((a for t, a in els if t == "manifest"), None)
    if man is None:
        raise AxmlError("no <manifest> element")
    app = next((a for t, a in els if t == "application"), {})
    sdk = next((a for t, a in els if t == "uses-sdk"), {})

    def flag(v):
        return bool(v) if isinstance(v, (bool, int)) else str(v).lower() == "true"
    return {"package": man.get("package"), "versionCode": man.get("versionCode"), "versionName": man.get("versionName"),
            "debuggable": flag(app.get("debuggable", False)), "testOnly": flag(app.get("testOnly", man.get("testOnly", False))),
            "minSdk": sdk.get("minSdkVersion"), "targetSdk": sdk.get("targetSdkVersion")}


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        print(__doc__)
        return 2
    b = manifest_bytes(argv[0])
    for tag, attrs in elements(b):
        print(json.dumps({"tag": tag, "attrs": attrs}))
    print(json.dumps({"facts": manifest_facts(b)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
