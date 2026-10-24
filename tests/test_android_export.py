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


class AndroidNetworkPermissions(unittest.TestCase):
    def test_lan_permissions_are_on(self):
        opts = preset_options("Android")
        for p in NEEDED:
            self.assertEqual(opts.get("permissions/" + p), "true", "permissions/%s must be true in the Android preset" % p)

    def test_each_permission_once(self):
        text = (ROOT / "game" / "export_presets.cfg").read_text()
        for p in NEEDED:
            self.assertEqual(len(re.findall(r"^permissions/%s=" % p, text, re.M)), 1, p)

    def test_workflow_checks_the_apk_manifest(self):
        wf = (ROOT / ".github" / "workflows" / "release.yml").read_text()
        self.assertIn("dump permissions", wf)
        for p in ["INTERNET", "ACCESS_NETWORK_STATE", "ACCESS_WIFI_STATE"]:
            self.assertIn(p, wf)


if __name__ == "__main__":
    unittest.main()
