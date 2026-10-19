"""One-time migration (2026-10-19) that built docs/requirements/requirements.json, the requirements register.

Kept for the audit trail (owner directive docs/directives/2026-10-19_build14_readiness_requirements_preservation.md,
sections 7 and 34): it shows where every first entry came from. Its inputs were the Build 14 audit's documentary
inventory (every table in the release registers, punch lists, the old ledger, the queue, the Designing Virtual Worlds
review, the economy proposals, the Build 12 audit, the remediation list, the design gap assessment and the decision
log, parsed to rows with their recorded status), plus the ledger rows the audit added (B14, CQ, MP, GM, WR, VP, DVW,
FR) and the corrections that audit made. After the migration the register is edited directly and checked by
tools/check_requirements.py; this script is not run again.

    python3 tools/requirements_migrate.py INVENTORY_ROWS.json   # writes docs/requirements/requirements.json
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "docs" / "requirements" / "requirements.json"
TODAY = "2026-10-19"
MIGRATED = {"date": TODAY, "change": "entered in the register", "why": "requirements preservation directive (migration)"}

PLAYTEST_DEVICES = {
    "B7-001": ["phone"], "B7-005": ["phone"], "B7-010": ["phone"], "B7-011": ["phone"], "B7-012": ["phone", "controller"],
    "B7-013": ["phone"], "PL1-03": ["phone"], "PL1-05": ["phone"], "B8-018": ["windows"], "B13-12": ["controller"],
    "B13-13": ["phone"], "Q-04": ["phone"],
}


def base(rid, title, kind, status, source, **kw):
    e = {"id": rid, "title": title, "kind": kind, "status": status, "owner_wording": kw.pop("owner_wording", None),
         "description": kw.pop("description", title), "source": source, "approval": kw.pop("approval", ""),
         "acceptance": kw.pop("acceptance", []), "implementation": kw.pop("implementation", ""), "tests": kw.pop("tests", ""),
         "playtest": kw.pop("playtest", []), "branch": kw.pop("branch", ""), "commits": kw.pop("commits", []),
         "parent": kw.pop("parent", None), "depends_on": kw.pop("depends_on", []), "blockers": kw.pop("blockers", []),
         "rules": kw.pop("rules", []), "interactions": kw.pop("interactions", []), "wiki": kw.pop("wiki", []),
         "next_action": kw.pop("next_action", ""), "priority": kw.pop("priority", ""), "workstream": kw.pop("workstream", ""),
         "superseded_by": kw.pop("superseded_by", None), "notes": kw.pop("notes", ""), "history": [dict(MIGRATED)]}
    assert not kw, kw
    return e


def short_id(rid, sec):
    rid = rid.replace("`", "").strip()
    fixed = {"K-3 / F-4": "K-3", "ECON-P2.1-P2.6": "ECON-P2", "ECON-P3.1-P3.5": "ECON-P3", "DGA-R1-R7": "DGA-R", "DGA-S1, S2": "DGA-S"}
    if rid in fixed:
        return fixed[rid]
    if re.match(r"^Q\d+$", rid):
        return "Q-%02d" % int(rid[1:])                 # queue item numbers
    if rid.startswith("B12A"):
        return "B12A-" + {"Defects11": "01", "Defect13m": "02", "Weaktests": "03", "PadJourna": "04", "Accessibi": "05",
                          "Wikigapsc": "06", "Artblocke": "07", "Deferred1": "08", "RTKpersis": "09", "Hardwarev": "10",
                          "Titlewind": "11"}[rid.replace("B12A-", "B12A")[4:13]]
    if rid.startswith("AR-"):
        m = re.match(r"AR-(P\d-\d)", rid)
        return "AR-" + m.group(1) if m else "AR-OWNER"
    return rid


def from_inventory(rows):
    out = {}
    for r in rows:
        rid = short_id(r["id"], r.get("source"))
        if rid == "B8-021..024" or rid.startswith(("ECON-B7-009", "ECON-Household")):
            continue                                   # not requirements: a numbering gap, and duplicates of B7-009 / B8-029
        kind = "approved" if r["kind"] == "approved" else "proposal"
        status = r["status"]
        if kind == "approved" and status == "COMPLETE AND VERIFIED" and rid in PLAYTEST_DEVICES:
            status = "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED"
        e = base(rid, r["title"], kind, status, "%s (audit inventory row %s)" % (r["source"], r["records_line"]),
                 approval=("recorded in %s" % r["source"]) if kind == "approved" else "agent proposal; not approved",
                 acceptance=["As recorded in the source document; evidence named in implementation and tests"],
                 implementation=r["record"][:600])
        e["playtest"] = PLAYTEST_DEVICES.get(rid, [])
        e["acceptance_derived"] = True
        out[rid] = e
    return out


def corrections(reg):
    def st(rid, status, why, **kw):
        e = reg[rid]
        e["history"].append({"date": TODAY, "change": "%s -> %s" % (e["status"], status), "why": why})
        e["status"] = status
        for k, v in kw.items():
            e[k] = v
    st("B8R-010", "COMPLETE AND VERIFIED", "owner decided (2026-10-18): children's pockets cannot be picked; World.pickpocket refuses", tests="code: world.gd pickpocket refuses role child")
    st("B8R-006", "SUPERSEDED", "carried forward as FR-03 (campfire)", superseded_by="FR-03")
    st("B8R-005", "SUPERSEDED", "replaced by the master list's HUD item B8-019", superseded_by="B8-019")
    st("PL1-12", "PARTIALLY IMPLEMENTED", "Build 14 audit: pickable in the village; the overworld draws no red flowers", next_action="Add tile 2656 to overworld flowers with the next overworld generator version (with B14-09)")
    st("DVW-A3", "ACTIVE DEVELOPMENT", "100- and 365-day runs on the current code (2026-10-19)")
    st("B12A-04", "SUPERSEDED", "carried forward as FR-04", superseded_by="FR-04")
    st("B12A-11", "SUPERSEDED", "carried forward as FR-05", superseded_by="FR-05")
    st("B12A-06", "SUPERSEDED", "carried forward as FR-06", superseded_by="FR-06")
    st("AR-P1-1", "SUPERSEDED", "the same work as B13-15", superseded_by="B13-15")
    st("F-2", "SUPERSEDED", "built as B8-029", superseded_by="B8-029")
    st("B7-009", "IMPLEMENTED — TESTING REQUIRED", "option (b) is in the code without a recorded owner decision; owner asked for a comparison (2026-10-19)", next_action="Four-way comparison runs, then owner decision", blockers=["owner decision after comparison"])
    st("B7-014", "IMPLEMENTED — TESTING REQUIRED", "a finite caravan purse is in the code without a recorded owner decision; owner asked for a comparison (2026-10-19)", next_action="Four-way comparison runs, then owner decision", blockers=["owner decision after comparison"])
    st("Q-08", "BLOCKED", "investigated; the decision is OD-01 (deposits) and WR-01 (wildlife, approved since)", blockers=["owner decision OD-01"])
    reg["Q-11"]["kind"] = "proposal"
    st("OWN-08", "PARTIALLY IMPLEMENTED", "everything but the stable Android key is done; that remains as B13-15", depends_on=["B13-15"])
    st("OWN-09", "COMPLETE AND VERIFIED", "a process decision, recorded and followed")
    reg["OWN-09"]["kind"] = "decision"
    st("OWN-12", "SUPERSEDED", "the open parts are OD-01 (mine wage, deposits)", superseded_by="OD-01")
    st("OWN-17", "SUPERSEDED", "the same as OD-02", superseded_by="OD-02")
    st("K-3", "SUPERSEDED", "the same as OD-02", superseded_by="OD-02")
    st("OWN-21", "SUPERSEDED", "owner's later decision: builds are private drafts made by hand (OWN-09)", superseded_by="OWN-09")
    st("OWN-24", "SUPERSEDED", "tracked as FR-01", superseded_by="FR-01")
    st("OWN-28", "PARTIALLY IMPLEMENTED", "living world built; isometric (DGA-D1/D2), magic beyond fireball (DGA-D9) and multiplayer (MP-01) open", depends_on=["MP-01", "DGA-D1", "DGA-D9"])
    reg["B12A-05"]["kind"] = "idea"
    reg["B12A-05"]["approval"] = "not requested by the owner (Build 12 audit suggestion)"
    reg["DVW-A10"]["parent"] = "B14-07"
    reg["DVW-A10"]["notes"] = "Built into B14-07 (cliff steps): no dead-end spaces"


LEDGER_ADD = [
    # id, title, status, source, extra
    ("B14-01", "Harvest or talk: A works the resource, Y / T talks to the villager beside it", "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED", "docs/DECISIONS.md (owner, Build 13 playtest)", {"commits": ["60a365b"], "tests": "start_test", "playtest": ["controller"]}),
    ("B14-02", "Villagers' home production: forage, brew poultices, treat their own wounds", "COMPLETE AND VERIFIED", "docs/DECISIONS.md (owner, Build 14)", {"commits": ["b94dc22"], "tests": "home_test", "interactions": ["INT-141"]}),
    ("B14-03", "House storefronts (player and villager households)", "COMPLETE AND VERIFIED", "docs/DECISIONS.md (owner, Build 14)", {"commits": ["a9c6db0", "d01376c"], "tests": "home_test", "interactions": ["INT-142"]}),
    ("B14-04", "Cart parts and handcarts", "COMPLETE AND VERIFIED", "docs/DECISIONS.md (owner, Build 14)", {"commits": ["d01376c"], "tests": "home_test", "interactions": ["INT-143"]}),
    ("B14-05", "Local-availability pricing", "COMPLETE AND VERIFIED", "docs/DECISIONS.md (owner, Build 14)", {"commits": ["75093bf"], "tests": "home_test, business_test", "interactions": ["INT-144"]}),
    ("B14-06", "Carts in play: pulled storage, parking, cart stops, deliveries, household market runs", "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED", "docs/DECISIONS.md (owner, Build 14)", {"commits": ["512f1bc", "f9fb853", "8ae29c2"], "tests": "home_test::test_carts_in_play", "playtest": ["phone"], "interactions": ["INT-146"], "notes": "Stand-in cart art (mine cart); hubs are the two market cart stops"}),
    ("B14-07", "Cliff steps (pickaxe, Mining), wooden stairs and walkways (planks, nails, Carpentry, a mallet)", "APPROVED — NOT STARTED", "owner message and answers 2026-10-19 (DEVELOPMENT_LEDGER B14-07)", {"next_action": "Start next (owner order)", "priority": "next"}),
    ("B14-08", "Forest animals (MiniFolks): grazers, predators, fox raids, fights", "COMPLETE AND VERIFIED", "docs/DECISIONS.md (owner, Build 14)", {"commits": ["2caca5a", "f9fb853"], "tests": "wildlife_test", "interactions": ["INT-145"], "notes": "The 365-day run shows wild animals at 0 by day 320: see WR-01 and the Build 14 readiness report"}),
    ("B14-09", "Skeletons in caves and uncleared woods (guard by day, roam at night, 3-day respawn; bones and rusty gear)", "APPROVED — NOT STARTED", "owner answers 2026-10-19", {"depends_on": [], "next_action": "After B14-07"}),
    ("B14-10", "Craftpix farm plants: crop stages, produce, crates, fruit trees chopped like the others", "PARTIALLY IMPLEMENTED", "owner message 2026-10-19", {"commits": ["f9fb853"], "interactions": ["INT-147"], "notes": "Apple trees done; crop stages, produce icons, storefront crates, more fruit trees remain"}),
    ("B14-11", "Animal Farm pack: the horse and farm animals", "APPROVED — NOT STARTED", "owner message 2026-10-19; horse role decided by the owner 2026-10-19: a plough horse bought from the visiting caravan", {"commits": ["a91b8f1", "f9fb853"], "notes": "Horse sheet imported with the farm sprite layout. Owner's role: plough horse sold by the caravan (no other horse capabilities approved)", "next_action": "Plough horse from the caravan: purchase, keeping (pen), tilling faster with the hand plough"}),
    ("B14-12", "Sprite list with pixel-grid copies for Aseprite (missing and weak sprites)", "APPROVED — NOT STARTED", "owner message 2026-10-19", {"next_action": "Generate the package with tools/assets/sheets.py contact"}),
    ("B14-13", "A controller connected to a phone or tablet hides the touch buttons and uses the pad controls", "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED", "docs/directives/2026-10-19_android_controller.md", {"commits": ["1458da8", "c984b4f"], "tests": "start_test", "playtest": ["phone", "controller"]}),
    ("CQ-01", "Sword responsiveness and hit detection (buffer, reach, phases, walls)", "AUTOMATED TESTS PASSED — PLAYTEST REQUIRED", "docs/directives/2026-10-19_sword_combat.md", {"commits": ["3e283b6"], "tests": "combat_test (41)", "playtest": ["phone", "controller"], "interactions": ["INT-012", "INT-088"], "wiki": ["sys:fighting"]}),
    ("MP-01", "Player-hosted multiplayer: two-player LAN milestone, host-authoritative", "ACTIVE DEVELOPMENT", "docs/directives/2026-10-19_multiplayer_foundation.md", {"branch": "wip/multiplayer", "commits": ["d18d7d1"], "tests": "net_test (36, separate processes)", "playtest": ["two-device LAN", "phone"], "workstream": "multiplayer (isolated)"}),
    ("GM-01", "Generational memory and historical consequences (the 30-planks chain)", "APPROVED — NOT STARTED", "docs/directives/2026-10-19_memory_refuges_politics.md Part I", {"depends_on": ["DVW-B1"], "rules": ["WDR-017"]}),
    ("WR-01", "Protected wildlife breeding refuges, offspring cohorts and dispersal", "APPROVED — NOT STARTED", "docs/directives/2026-10-19_memory_refuges_politics.md Part II", {"rules": ["WDR-018"], "priority": "high: wildlife reaches 0 in the 365-day run"}),
    ("VP-01", "Living village politics: offices, individual NPC voting, elections, civic authority", "APPROVED — NOT STARTED", "docs/directives/2026-10-19_memory_refuges_politics.md Part III", {"depends_on": ["GM-01", "DVW-B1"], "rules": ["WDR-015", "WDR-019"]}),
    ("FR-01", "Lizards and spiders as enemies", "BLOCKED", "owner 2026-10-18 ('good enemies'; docs/DECISIONS.md)", {"blockers": ["no lizard or spider pack supplied"]}),
    ("FR-02", "Forgotten Memories waterfalls, fences and props", "APPROVED — NOT STARTED", "owner message 2026-10-19", {"next_action": "With B14-07"}),
    ("FR-03", "A campfire for cooking raw meat outside the village", "APPROVED — NOT STARTED", "owner request in Build 8 testing (BUILD_8_ISSUES)", {}),
    ("FR-04", "Pad shortcuts for the Journal and Build menus; complete on-screen controls list", "APPROVED — NOT STARTED", "docs/release/BUILD_12_FULL_AUDIT.md", {}),
    ("FR-05", "Title window opens scrolled into the controls list", "COMPLETE AND VERIFIED", "docs/release/BUILD_13_PACKET.md", {"commits": ["ec3bd0e"], "tests": "start_test"}),
    ("FR-06", "Wiki pages missing: magic, the employer star, journal and map, death causes, caravan, bandits", "PARTIALLY IMPLEMENTED", "docs/release/BUILD_12_FULL_AUDIT.md", {}),
    ("FR-07", "Economy and household simulations in CI (short variant)", "APPROVED — NOT STARTED", "Build 14 audit", {}),
    ("FR-08", "Music and sound", "BLOCKED", "BUILD_7_ISSUES F-3", {"blockers": ["no audio supplied"]}),
    ("FR-09", "Crime from desperation", "DEFERRED", "owner design intent 2026-10-17, deferred by the owner ('no desperation crime yet')", {}),
    ("FR-10", "Archery", "DEFERRED", "docs/directives/2026-10-19_sword_combat.md (future, not authorised)", {}),
    ("FR-11", "Personality, prestige and migration (owner's living-society list, 2026-10-17)", "UNKNOWN — INVESTIGATION REQUIRED", "owner message 2026-10-17", {}),
    ("OD-01", "Owner decision: deposit sustainability (P1) and the mine wage (B7-006)", "BLOCKED", "docs/release/ECONOMY_SUSTAINABILITY_PROPOSALS.md", {"blockers": ["owner decision"]}),
    ("OD-02", "Owner decision: balance review of every provisional number", "BLOCKED", "docs/DECISIONS.md", {"blockers": ["owner review"]}),
    ("OD-03", "Owner decisions: design gap assessment D1-D12 (isometric, magic, era, county)", "BLOCKED", "docs/DESIGN_GAP_ASSESSMENT.md", {"blockers": ["owner decision"]}),
    ("OD-04", "Owner decisions: chest and lock questions", "BLOCKED", "docs/BUILD_DECISIONS.md", {"blockers": ["owner decision"]}),
    ("OD-05", "Owner decisions: inner doorways, relaying survey plots", "BLOCKED", "docs/BUILD_DECISIONS.md", {"blockers": ["owner decision"]}),
    ("OD-06", "Owner decisions: farming (Farming skill, wheat versus wages)", "BLOCKED", "docs/BUILD_DECISIONS.md", {"blockers": ["owner decision"]}),
    ("OD-07", "Owner decision: hunting in Gather mode", "BLOCKED", "docs/HANDOFF.md", {"blockers": ["owner decision"]}),
    ("OD-08", "Owner decision: is honest arbitrage intended?", "BLOCKED", "docs/reference/DESIGNING_VIRTUAL_WORLDS.md A5", {"blockers": ["owner decision"]}),
    ("OD-09", "Owner decisions: GAME_DESIGN items still open (U3-U5, U13, U16-U21)", "BLOCKED", "docs/GAME_DESIGN.md", {"blockers": ["owner decision"]}),
]
LEDGER_ADD += [
    ("ENV-RTK", "RTK token tool and its hook persistent in the cloud environment", "BLOCKED", "owner request 2026-10-19 (DEVELOPMENT_LEDGER ENV-RTK)", {"blockers": ["owner: environment setup script"]}),
    ("REQ-GRAVE", "Graveyards, ancestry and NPC legacy", "APPROVED — NOT STARTED", "owner: World Design Rule 14 topic; directive 2026-10-19 (requirements preservation) s.26", {"rules": ["WDR-014"], "depends_on": ["GM-01"]}),
    ("REQ-BANDIT", "Bandit factions, criminal careers and outlaw leadership", "APPROVED — NOT STARTED", "owner: World Design Rule 16 topic; directive 2026-10-19 (requirements preservation) s.26", {"rules": ["WDR-016"]}),
    ("B14R-01", "Record completed 100-day economy simulations (start, seeds, currency, wealth, jobs, trade, resources, food, population, shortages, regressions)", "ACTIVE DEVELOPMENT", "docs/directives/2026-10-19_build14_readiness_requirements_preservation.md s.1", {"workstream": "build 14 readiness"}),
    ("B14R-02", "Compare the manor reserve and the caravan money limit (four configurations) and recommend", "ACTIVE DEVELOPMENT", "same directive s.2", {"depends_on": ["B7-009", "B7-014"], "workstream": "build 14 readiness"}),
    ("B14R-03", "Investigate iron and coal running out by day 10; document sustainable alternatives without changing the resource model", "ACTIVE DEVELOPMENT", "same directive s.3", {"depends_on": ["OD-01"], "workstream": "build 14 readiness"}),
    ("B14R-04", "Build 14 tester notes", "APPROVED — NOT STARTED", "same directive s.4", {"workstream": "build 14 readiness"}),
    ("B14R-05", "Identify the Build 14 candidate commit and ask the owner for build approval", "APPROVED — NOT STARTED", "same directive s.5", {"depends_on": ["B14R-01", "B14R-04", "B14R-12"], "workstream": "build 14 readiness"}),
    ("B14R-06", "Permanent requirements register, lifecycle, validation, silent-deletion detection, startup and handoff rules", "ACTIVE DEVELOPMENT", "same directive Parts II, V, VI", {"workstream": "requirements preservation"}),
    ("B14R-07", "Second historical requirements recovery pass and coverage report", "ACTIVE DEVELOPMENT", "same directive Part III", {"workstream": "requirements preservation"}),
    ("B14R-08", "Reconcile the original 16 World Design Rules (restore text if the source is found)", "PARTIALLY IMPLEMENTED", "same directive Part IV", {"blockers": ["original rule text not found in any accessible source"]}),
    ("B14R-09", "Stable Android test-signing procedure documented (credentials, secrets, setup, key preservation, risks, install and update test)", "APPROVED — NOT STARTED", "same directive s.28", {"depends_on": ["B13-15"]}),
    ("B14R-10", "Separate real-device verification queue (phone, controller, Windows, cross-platform and two-device LAN)", "ACTIVE DEVELOPMENT", "same directive s.29", {}),
    ("B14R-11", "Review draft PR #1 for unique content before recommending closure", "ACTIVE DEVELOPMENT", "same directive s.30", {}),
    ("B14R-12", "Long-run regression: wild animals reach 0 by day 320 and the population falls from 100 to 69 in the 365-day run", "ACTIVE DEVELOPMENT", "Build 14 readiness simulations 2026-10-19 (owner: investigate and correct genuine regressions, s.1)", {"priority": "immediate", "depends_on": [], "notes": "Wildlife: 54 at start, 24 by day 40, 0 by day 320. Population: about 45 game years pass (8-day year)."}),
]
RULE_TOPICS = ["Material Interdependency", "Professional Interdependency", "Meaningful Recipes", "Economic Consequences",
    "Living World Independence", "Maintain the Existing Interlocking Systems Manifest", "Automated Compliance", "Player Knowledge and Wiki",
    "Emergent Gameplay", "Depth Without Obscurity", "NPC Self-Improvement and Prosperity", "NPC Competition and Economic Rivalry",
    "Finite Resources and Actual Consumption", "Graveyards, Ancestry, and NPC Legacy", "Political Authority, Social Hierarchy, and Civic Employment",
    "Bandit Factions, Criminal Careers, and Outlaw Leadership"]
for _i, _t in enumerate(RULE_TOPICS, 1):
    LEDGER_ADD.append(("WDR-%03d" % _i, "World Design Rule %d: %s" % (_i, _t), "BLOCKED",
        "owner directive 2026-10-19 (requirements preservation) Part IV: topic list; original text in My_Medieval_Life_World_Design_Rules_v1 (pdf/docx), not found",
        {"kind": "rule", "blockers": ["original rule text awaiting source recovery"], "notes": "Topic preserved; detailed text not invented"}))
for _i, (_t, _sec) in enumerate([("Generational Memory and Living History", "40"), ("Protected Ecological Continuity", "40"),
                                  ("Living Political Agency and Democratic Consequences", "40")], 17):
    LEDGER_ADD.append(("WDR-%03d" % _i, "World Design Rule %d: %s" % (_i, _t), "COMPLETE AND VERIFIED",
        "docs/directives/2026-10-19_memory_refuges_politics.md s.%s (text recorded in docs/WORLD_DESIGN_RULES.md)" % _sec, {"kind": "rule"}))
KIND_DECISION = {"OD-%02d" % i for i in range(1, 10)}


def main():
    rows = json.load(open(sys.argv[1]))
    reg = from_inventory(rows)
    for rid, title, status, source, extra in LEDGER_ADD:
        old = reg.pop(rid, None)
        kind = extra.pop("kind", "decision" if rid in KIND_DECISION else "approved")
        e = base(rid, title, kind, status, source,
                 approval=source if rid not in KIND_DECISION else "open owner question",
                 acceptance=["As recorded in the source; evidence named in implementation and tests"])
        e["acceptance_derived"] = True
        for k, v in extra.items():
            e[k] = v
        if old:
            e["history"].append({"date": TODAY, "change": "merged with the audit inventory row", "why": "one entry per id"})
        reg[rid] = e
    corrections(reg)
    data = {"format": "mml-requirements/1", "requirements": sorted(reg.values(), key=lambda e: e["id"])}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n")
    print("wrote %d requirements" % len(data["requirements"]))


if __name__ == "__main__":
    main()
