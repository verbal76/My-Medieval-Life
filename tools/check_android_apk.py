"""The Android production-package gate (B42-ANDROID-DEBUGGABLE; owner directive 2026-11-14 item 5: "a release gate that detects
an incorrectly configured Android production build").

It reads the APK's own compiled manifest (tools/axml.py, no aapt) and its signature (apksigner verify --print-certs), and
fails when the package is not a production release package as tools/release_requirements.json ("android") defines it:
android:debuggable or android:testOnly true, a package id other than the edition's, a versionCode other than the build
number, a versionName other than 0.1.<n>-test, a signature that does not verify, more or fewer than one signer, a certificate
other than the owner's permanent release certificate, or no v2/v3 signature. Standard library only.

    python3 tools/check_android_apk.py --apk pkg/ForgeMyLife-B42-Android.apk --edition full --build-number 42 \\
        --apksigner "$tools_dir/apksigner" [--json out/android-gate.json]
    python3 tools/check_android_apk.py --manifest AndroidManifest.xml --signature-text apk-signature.txt --edition demo --build-number 42

Exit 0 when every check passes, 1 otherwise (each failure printed as a ::error:: line), 2 on bad arguments.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import axml  # noqa: E402

REQUIREMENTS = REPO / "tools" / "release_requirements.json"


def load_requirements(path=REQUIREMENTS):
    return json.loads(Path(path).read_text())


def parse_signature(text):
    """apksigner verify --verbose --print-certs output -> {verifies, signers, digests, schemes}."""
    schemes = {m.group(1): m.group(2) == "true"
               for m in re.finditer(r"^Verified using (v\d) scheme[^:]*: (true|false)$", text, re.M)}
    digests = sorted({m.group(1).lower() for m in re.finditer(r"^Signer #\d+ certificate SHA-256 digest: *([0-9a-fA-F]{64})\s*$", text, re.M)})
    n = re.search(r"^Number of signers: (\d+)$", text, re.M)
    return {"verifies": bool(re.search(r"^Verifies$", text, re.M)) and "DOES NOT VERIFY" not in text,
            "signers": int(n.group(1)) if n else None, "digests": digests, "schemes": schemes}


def check(facts, sig, edition, build_number, req):
    """The reasons the package is not a correct production package ([] = it is). `facts` from axml.manifest_facts, `sig` from
    parse_signature, `req` the "android" section of tools/release_requirements.json."""
    problems = []
    ed = req["editions"].get(edition)
    if ed is None:
        return ["unknown edition %r (known: %s)" % (edition, ", ".join(sorted(req["editions"])))]
    if facts["debuggable"] != req.get("debuggable", False):
        problems.append("android:debuggable is %s: a debug export (godot --export-debug, the debug template), not a production package"
                        % str(facts["debuggable"]).lower())
    if facts["testOnly"] != req.get("test_only", False):
        problems.append("android:testOnly is %s" % str(facts["testOnly"]).lower())
    if facts["package"] != ed["package"]:
        problems.append("package id is %s, not %s (package ids change only with the owner's approval)" % (facts["package"], ed["package"]))
    if facts["versionCode"] != int(build_number):
        problems.append("versionCode is %s, not the build number %s" % (facts["versionCode"], build_number))
    want_name = req.get("version_name", "").replace("{n}", str(build_number))
    if want_name and facts["versionName"] != want_name:
        problems.append("versionName is %s, not %s" % (facts["versionName"], want_name))
    if not sig["verifies"]:
        problems.append("the signature does not verify (apksigner verify)")
    if sig["signers"] != 1 or len(sig["digests"]) != 1:
        problems.append("expected exactly one signer with one certificate, found %s signer(s) and %d certificate digest(s)"
                        % (sig["signers"], len(sig["digests"])))
    want_cert = req["certificate_sha256"].lower().replace(":", "")
    if sig["digests"] and any(d != want_cert for d in sig["digests"]):
        problems.append("signing certificate SHA-256 %s is not the permanent release certificate %s (signing continuity; never rotate the key without the owner)"
                        % (", ".join(sig["digests"]), want_cert))
    any_of = req.get("signature_schemes_any", [])
    if any_of and not any(sig["schemes"].get(s) for s in any_of):
        problems.append("not signed with any of the %s schemes" % "/".join(any_of))
    return problems


def run_apksigner(apksigner, apk):
    p = subprocess.run([apksigner, "verify", "--verbose", "--print-certs", str(apk)], capture_output=True, text=True)
    return p.stdout + ("\nDOES NOT VERIFY\n" if p.returncode != 0 else "")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--apk")
    src.add_argument("--manifest", help="a binary AndroidManifest.xml (tests)")
    sg = ap.add_mutually_exclusive_group(required=True)
    sg.add_argument("--apksigner", help="the apksigner to run on --apk")
    sg.add_argument("--signature-text", help="recorded apksigner verify --verbose --print-certs output")
    ap.add_argument("--edition", required=True)
    ap.add_argument("--build-number", required=True, type=int)
    ap.add_argument("--requirements", default=str(REQUIREMENTS))
    ap.add_argument("--json", default="")
    a = ap.parse_args(argv)
    if a.apksigner and not a.apk:
        ap.error("--apksigner needs --apk")
    req = load_requirements(a.requirements)["android"]
    path = a.apk or a.manifest
    try:
        facts = axml.manifest_facts(axml.manifest_bytes(path))
    except (axml.AxmlError, KeyError, OSError, IndexError, ValueError) as e:     # struct.error is a ValueError
        print("::error::%s: the manifest could not be read (%s)" % (path, e))
        return 1
    text = run_apksigner(a.apksigner, a.apk) if a.apksigner else Path(a.signature_text).read_text()
    sig = parse_signature(text)
    problems = check(facts, sig, a.edition, a.build_number, req)
    rep = {"format": "mml-android-gate/1", "file": Path(path).name, "edition": a.edition, "build_number": a.build_number,
           "manifest": facts, "signature": sig, "problems": problems, "result": "fail" if problems else "pass"}
    if a.json:
        Path(a.json).parent.mkdir(parents=True, exist_ok=True)
        Path(a.json).write_text(json.dumps(rep, indent=1) + "\n")
    print("Android production gate, %s (%s, build %d): package %s, versionCode %s, versionName %s, debuggable %s, certificate %s: %s"
          % (Path(path).name, a.edition, a.build_number, facts["package"], facts["versionCode"], facts["versionName"],
             str(facts["debuggable"]).lower(), ",".join(sig["digests"]) or "none", rep["result"].upper()))
    for p in problems:
        print("::error::%s: %s" % (Path(path).name, p))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
