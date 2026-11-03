"""Build 21 (owner directive 2026-10-24, section 3): the Android export asks for the network permissions LAN play needs. INTERNET,
ACCESS_NETWORK_STATE and ACCESS_WIFI_STATE (and CHANGE_WIFI_MULTICAST_STATE for discovery broadcasts) are ordinary manifest
permissions, granted at install with no runtime prompt. Reads game/export_presets.cfg; standard library only, no Godot needed.
The exported APK's manifest is checked in the release workflow (aapt dump permissions)."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NEEDED = ["internet", "access_network_state", "access_wifi_state", "change_wifi_multicast_state"]


def preset_options(name):
    """The options section of the export preset called `name`, as {key: raw value}."""
    text = (ROOT / "game" / "export_presets.cfg").read_text()
    sections, current = {}, None
    for line in text.splitlines():
        m = re.match(r"\[(preset\.\d+(?:\.options)?)\]", line)
        if m:
            current = m.group(1)
            sections[current] = {}
            continue
        m = re.match(r"([\w/]+)=(.*)", line)
        if m and current:
            sections[current][m.group(1)] = m.group(2)
    for sec, vals in sections.items():
        if not sec.endswith(".options") and vals.get("name") == '"%s"' % name:
            return sections[sec + ".options"]
    raise AssertionError("no export preset named %s" % name)


ANDROID_PRESETS = ["Android", "Android Demo"]     # DEMO-01 (owner 2026-11-03): the demo is its own Android app, with the same permissions


def preset_section_text(name):
    """The raw text of the options section of the export preset called `name`."""
    text = (ROOT / "game" / "export_presets.cfg").read_text()
    blocks = re.split(r"(?m)^(?=\[preset\.)", text)
    index = None
    for b in blocks:
        m = re.match(r"\[preset\.(\d+)\]\n", b)
        if m and re.search(r'(?m)^name="%s"$' % re.escape(name), b):
            index = m.group(1)
    if index is None:
        raise AssertionError("no export preset named %s" % name)
    for b in blocks:
        if b.startswith("[preset.%s.options]" % index):
            return b
    raise AssertionError("export preset %s has no options section" % name)


class AndroidNetworkPermissions(unittest.TestCase):
    def test_lan_permissions_are_on(self):
        for name in ANDROID_PRESETS:
            opts = preset_options(name)
            for p in NEEDED:
                self.assertEqual(opts.get("permissions/" + p), "true", "permissions/%s must be true in the %s preset" % (p, name))

    def test_each_permission_once(self):
        # each Android preset names each permission once (a preset of its own may repeat it: the demo's does)
        for name in ANDROID_PRESETS:
            text = preset_section_text(name)
            for p in NEEDED:
                self.assertEqual(len(re.findall(r"^permissions/%s=" % p, text, re.M)), 1, "%s in %s" % (p, name))

    def test_demo_has_its_own_package_and_the_full_game_keeps_its_own(self):
        # the owner's package id stays on the full game; the demo is a separate app beside it (DEMO-01)
        self.assertEqual(preset_options("Android").get("package/unique_name"), '"com.hotatticgames.mymedievallife.dev"')
        self.assertEqual(preset_options("Android Demo").get("package/unique_name"), '"com.hotatticgames.mymedievallife.dev.demo"')

    def test_workflow_checks_the_apk_manifest(self):
        wf = (ROOT / ".github" / "workflows" / "release.yml").read_text()
        self.assertIn("dump permissions", wf)
        for p in ["INTERNET", "ACCESS_NETWORK_STATE", "ACCESS_WIFI_STATE"]:
            self.assertIn(p, wf)


    def test_workflow_signs_with_the_permanent_release_key_only(self):
        # owner, 2026-10-24: the four ANDROID_RELEASE_* secrets, no throwaway fallback, the signature verified and recorded
        wf = (ROOT / ".github" / "workflows" / "release.yml").read_text()
        for name in ["ANDROID_RELEASE_KEYSTORE_BASE64", "ANDROID_RELEASE_KEYSTORE_PASSWORD",
                     "ANDROID_RELEASE_KEY_ALIAS", "ANDROID_RELEASE_KEY_PASSWORD"]:
            self.assertIn("secrets." + name, wf)
        for gone in ["allow_temporary_key", "genkeypair", "ANDROID_TEST_"]:
            self.assertNotIn(gone, wf)
        self.assertIn("--key-pass env:KEY_PASSWORD", wf)
        self.assertIn("apksigner\" verify", wf)
        self.assertIn("certificate SHA-256 digest", wf)

if __name__ == "__main__":
    unittest.main()
