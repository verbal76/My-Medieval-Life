"""Evidence corrections and new records of the 2026-10-23 reconciliation (owner directive
docs/directives/2026-10-23_master_requirements_reconciliation.md), applied by tools/requirements_migrate_v2.py.

Every change here states its evidence and becomes a history line on the record. Sources of the evidence:
the Builds 18-21 audit of 2026-10-23 (branch heads, commits, test records), the owner's answers saved in
docs/directives/2026-10-23_*.md, and the branch documents named per item. Nothing here answers an owner decision.
"""

B18_SUITE = "all 66 Godot suites (exit 0, 0 SCRIPT ERROR, 0 FAIL) and the Python suite at wip/build18 83d3afc, run by the lead 2026-10-23"
X19 = "wip/expansion19-preparation"
X19_TESTS = "judgment_test 168, judgment_live_test 53, judgment_decay_demo 24, judgment_perf 9 checks, 0 failures (expansion19/PROGRESS.md on wip/expansion19-preparation, c4b10e4)"
X19_REWORK = ("rework for the owner's answers of 2026-10-23: SJD-Q05 no prior-opinion bias in interpretation; X19-REGARD trust "
              "separate from liking (new structure); X19-Q-TIMING gossip passed at each meeting by contact and closeness "
              "(the prototype batches by the hour); X19-ASSAULT assault permanent; X19-HARMED keep the instant harm to kin; "
              "X19-CRT12 keep the courtship cut-offs; X19-GUARD a friendly guard reduces, never waives, a fine; "
              "synchronize with the finished Build 18 (the branch is on Build 17 cd7439c)")

# Build 18 open items: design state and effort band from the audit (docs: the audit report of 2026-10-23).
B18_PLAN = {
    "DVW-B3-CHAPEL": ("SPECIFIED", "L"), "SET-C-SIM": ("SPECIFIED", "XL"), "SET-C-FIVE": ("SPECIFIED", "M"),
    "ECON-P1.3": ("SPECIFIED", "M"), "DVW-B3-FEAST": ("SPECIFIED", "M"), "DVW-B3-LUX": ("SPECIFIED", "S"),
    "DVW-B5": ("SPECIFIED", "M"), "ECON-P3": ("SPECIFIED", "M"), "TRADE-CREDIT": ("SPECIFIED", "L"),
    "MIGRATE-18": ("SPECIFIED", "L"), "SET-D": ("DESIGN WORK REQUIRED", "XL"), "WDR-011-C": ("DESIGN WORK REQUIRED", "L"),
    "WDR-012-C": ("DESIGN WORK REQUIRED", "M"), "WDR-004-C": ("DESIGN WORK REQUIRED", "M"), "WDR-002-C": ("SPECIFIED", "M"),
    "X18-SIM": ("SPECIFIED", "M"), "X18-Q12": ("PARTIAL", "L"), "X18-Q12-BOOTH": ("SPECIFIED", "M"),
    "X18-Q12-POST": ("SPECIFIED", "M"), "X18-Q13": ("PARTIAL", "L"), "LAW-SKILL": ("SPECIFIED", "S"),
    "X18-STONECUT": ("OWNER DECISION REQUIRED", "M"), "STONE-02": ("OWNER DECISION REQUIRED", "S"),
    "STONE-03": ("OWNER DECISION REQUIRED", "S"), "STONE-04": ("OWNER DECISION REQUIRED", "S"),
    "STONE-06": ("OWNER DECISION REQUIRED", "S"), "SET-A": ("SPECIFIED", "XS"), "SET-B": ("SPECIFIED", "S"),
    "SET-C": ("SPECIFIED", "UNKNOWN"), "PL1-10": ("UNKNOWN", "UNKNOWN"), "PL2-008": ("UNKNOWN", "UNKNOWN"),
    "PL2-014": ("UNKNOWN", "UNKNOWN"), "PL2-015": ("UNKNOWN", "UNKNOWN"),
}
STONE_DECISIONS = {"X18-STONECUT": ["STONE-D1", "STONE-D2"], "STONE-02": ["STONE-D1", "STONE-D2"], "STONE-03": ["STONE-D1"],
                   "STONE-04": ["STONE-D1"], "STONE-06": ["STONE-D2"]}


def apply(d, date):
    by = {r["id"]: r for r in d["requirements"]}
    notes = []

    def hist(r, change, why):
        r.setdefault("history", []).append({"date": date, "change": change, "why": why})

    def setr(rid, why, **kw):
        r = by[rid]
        before = {k: r.get(k) for k in kw}
        r.update(kw)
        changed = [k for k in kw if before.get(k) != kw[k]]
        hist(r, "reconciliation: " + "; ".join("%s=%s" % (k, kw[k] if not isinstance(kw[k], (list, dict)) else "…") for k in changed), why)
        notes.append({"id": rid, "source": "2026-10-23 evidence correction", "canonical_id": rid, "action": "corrected", "reason": why,
                      "evidence": why})

    def add(rec, why):
        rec.setdefault("history", []).append({"date": date, "change": "entered in the register", "why": why})
        d["requirements"].append(rec)
        by[rec["id"]] = rec
        notes.append({"id": rec["id"], "source": rec.get("source"), "canonical_id": rec["id"], "action": "added (previously unregistered)",
                      "reason": why, "evidence": rec.get("source")})

    # ---- 1. stale IN DEVELOPMENT entries with no worker (owner directive section 9) --------------------------------
    for rid in ("OVN-01", "OVN-02", "REL-15-18", "B18-DIR"):
        setr(rid, "a directive in force, not a piece of work: tracked through its children; no worker develops it",
             umbrella=True, implementation_status="NOT APPLICABLE", verification_status="NOT APPLICABLE", release_status="NOT APPLICABLE")
    for rid in ("EXP-A", "EXP-B", "EXP-C", "EXP-D", "DVW-B3"):
        setr(rid, "an expansion or umbrella requirement: its children carry the work and are counted instead", umbrella=True)
    setr("PROS-18", "Expansion 18 branch merged into wip/build18 as d63d8d7 (inactive parts off); umbrella of the X18 entries; no worker",
         umbrella=True, implementation_status="INTEGRATED", integrated_in=["Build 18 wip/build18"], verification_status="TARGETED TESTS PASSED",
         assigned_worker="", branch="")
    setr("PROS-19", "prototype on wip/expansion19-preparation (c4b10e4), switched off, not integrated; the worker is idle since 2026-10-22",
         umbrella=True, implementation_status="IMPLEMENTED ON TASK BRANCH", branch=X19, assigned_worker="",
         verification_status="TARGETED TESTS PASSED", tests=X19_TESTS, remaining_work=X19_REWORK, test_commit="c4b10e4")
    for rid, why in (("B16-AUDIT", "Build 16 status audit delivered (docs/BUILD_16_STATUS.md); Build 16 released; closure not recorded"),
                     ("B16-READY", "Build 16 readiness report delivered (docs/BUILD_16_STATUS.md); Build 16 released; closure not recorded"),
                     ("FSE-00", "audit and deliverables in docs/design/FOOD_SECURITY_AUDIT.md; closure not recorded")):
        setr(rid, why + "; no worker", implementation_status="INTEGRATED", legacy_evidence=why, verification_status="NOT TESTED",
             remaining_work="closure review against its acceptance criteria (human review)")
    for rid, why in (("DVW-A3", "money-supply re-measurement: no worker; whether the Build 16 long runs satisfy it is unrecorded"),
                     ("FARM-08", "shared-yield comparison: crop allocation answered by the owner (FARM-08-Q-CROP); remaining runs unrecorded; no worker"),
                     ("PERF-01", "performance audit measured (history); closure not recorded; no worker"),
                     ("WDR-022-C", "a standing compliance principle applied in every report; no worker; compliance audit not recorded"),
                     ("WIKI-B17", "Build 17 wiki reconciliation: 0147066 and 3dcd583 closed the known gaps; what remains is unrecorded; no worker")):
        setr(rid, why, implementation_status="PARTIALLY IMPLEMENTED", remaining_work="unknown: needs a human review of what remains")
    setr("MP-01", "two-player LAN prototype on wip/multiplayer (d18d7d1); excluded from Build 18 by the owner; no worker",
         implementation_status="IMPLEMENTED ON TASK BRANCH", branch="wip/multiplayer", task_branches=["multiplayer prototype wip/multiplayer"])
    for rid in ("X18-Q12", "X18-Q12-BOOTH", "X18-Q12-POST", "X18-Q13"):
        setr(rid, "courier and formal-contract code merged into wip/build18 with Expansion 18 (d63d8d7) but not wired into play (inert); "
                  "no worker; Q18-14..16 answered 2026-10-23", implementation_status="PARTIALLY IMPLEMENTED", integrated_in=["Build 18 wip/build18"],
             commits=sorted(set((by[rid].get("commits") or []) + ["d63d8d7"])),
             remaining_work="wire into play: booths (any shop, Q18-15; built near the market, Q18-16), the postage-style window, fees (X18-FEES), Law notary path (LAW-SKILL)")
    setr("X18-SIM", "no simulation campaign has been run; no worker", implementation_status="READY")

    # ---- 2. Build 18: settlement code present but recorded as not started ------------------------------------------
    for rid in ("SET-A", "SET-B"):
        setr(rid, "settlement design, ledger and capability model merged with Expansion 18 (d63d8d7) and live since 60e8318 (capability hook on); close-out against the specification not done",
             implementation_status="PARTIALLY IMPLEMENTED", integrated_in=["Build 18 wip/build18"], commits=["d63d8d7", "60e8318"],
             remaining_work="close-out against the specification's acceptance criteria")
    setr("SET-C", "regional-economy code merged with Expansion 18 (d63d8d7) but not wired; replaced in practice by SET-C-SIM (in development)",
         implementation_status="PARTIALLY IMPLEMENTED", integrated_in=["Build 18 wip/build18"], commits=["d63d8d7"],
         remaining_work="lands with SET-C-SIM and SET-C-FIVE")
    # ---- 3. active workers (owner directive section 2) -------------------------------------------------------------
    setr("DVW-B3-CHAPEL", "chapel worker started 2026-10-23 from wip/build18 83d3afc; uncommitted work in progress",
         implementation_status="IN DEVELOPMENT", assigned_worker="chapel worker (Sonnet subagent, started 2026-10-23)", branch="wip/b18-chapel")
    for rid in ("SET-C-SIM", "SET-C-FIVE", "ECON-P1.3"):
        setr(rid, "regions worker started 2026-10-23 from wip/build18 83d3afc; uncommitted work in progress",
             implementation_status="IN DEVELOPMENT", assigned_worker="regions worker (Sonnet subagent, started 2026-10-23)", branch="wip/b18-regions")
    # ---- 4. Build 18 integrated items: integration evidence ----------------------------------------------------------
    for r in d["requirements"]:
        if (r.get("target_build") == "18" and r.get("kind") == "approved" and r.get("implementation_status") == "INTEGRATED"
                and not r.get("umbrella") and "Build 18 wip/build18" in (r.get("integrated_in") or [])):
            r["verification_status"] = "INTEGRATION VERIFIED"
            r["test_commit"] = "83d3afc"
            r["tests"] = (str(r.get("tests") or "").strip() + "; " if str(r.get("tests") or "").strip() else "") + B18_SUITE
            if not r.get("playtest"):
                r["playtest"] = ["owner playtest on a device"]
            hist(r, "reconciliation: verification INTEGRATION VERIFIED (test_commit 83d3afc); owner playtest outstanding",
                 "the full automated suite passed on the integrated build; no device or owner playtest recorded")
    for rid in ("LAW-SKILL",):
        by[rid]["integrated_in"] = ["Build 18 wip/build18"]
        by[rid]["remaining_work"] = "courier-notary path not live; villagers do not take lessons; clergy teaching waits on DVW-B3-CHAPEL"
    setr("STONE-05", "the owner's Q18-1 answer added 'Masonry (stoneworking)' as a skill of its own; Masonry governs dress_stone "
                     "(72e6c3e, trade_skills_test 96/0), so this requirement is met by SKILL-TRADES-18",
         implementation_status="INTEGRATED", integrated_in=["Build 18 wip/build18"], commits=["72e6c3e"],
         verification_status="INTEGRATION VERIFIED", test_commit="83d3afc", tests="trade_skills_test 96/0; " + B18_SUITE,
         related=["SKILL-TRADES-18"], playtest=["owner playtest on a device"])
    for rid, (des, eff) in B18_PLAN.items():
        by[rid]["design"] = des
        by[rid]["effort"] = eff
        if rid in STONE_DECISIONS:
            by[rid]["decisions"] = STONE_DECISIONS[rid]
    # ---- 5. decisions (owner directive section 7) --------------------------------------------------------------------
    setr("X19-DECAY", "the owner chose a half-life of 2 game years (16 days) and then asked for the calendar to be explained before "
                      "finalizing (2026-10-23): provisional, not implemented", disposition="PROVISIONAL", depends_on=["OD-21"],
         owner_answer="Held, provisional: half-life 2 game years (16 game days on the 8-day year) per deed in the observer's ledger; murder and assault permanent; deterministic. The owner asked for the calendar to be explained before finalizing (docs/directives/2026-10-23_owner_answers_x19_assault_crt12_decay.md).")
    setr("Q18-11", "scale and model approved (Q18-11A, Q18-11B); final percentages wait for X18-SIM evidence", disposition="PROVISIONAL",
         related=["X18-SIM", "Q18-11A"])
    setr("CARAVAN-TMP", "the owner's answer of 2026-10-23 (docs/directives/2026-10-23_owner_answers_caravan_purses_skills.md): the "
                        "caravan becomes the settlements' traders and the daily allowance goes away", disposition="SUPERSEDED", superseded_by="ECON-P1.3")
    hist(by["OD-21"], "reconciliation: note",
         "owner asked on 2026-10-23 for the calendar to be explained (answered in the session); no change requested: the 8-day year stands. "
         "Approved decisions establish design intent and may be revisited by the owner when evidence shows unintended consequences.")
    by["OD-21"]["notes"] = (str(by["OD-21"].get("notes") or "") + " Calendar explained to the owner 2026-10-23; X19-DECAY waits on the owner's view of it.").strip()
    for rid in ("CON-08-Q",):
        by[rid]["blocks_implementation"] = True
    for r in d["requirements"]:
        if r["id"].startswith("OD-LE-") and r["id"] != "OD-LE-01":
            r["blocks_implementation"] = True
    # ---- 6. Builds 20 and 21: assignments the owner made (OD-30 numbering, OD-LE-01 placement) --------------------------
    for r in d["requirements"]:
        if r["id"] in ("EXP-D", "LE-01", "LE-02", "LE-03", "LE-04", "LE-05", "LE-06", "LE-07") or (r["id"].startswith("OD-LE-") and r["id"] != "OD-LE-01"):
            if r.get("target_build") != "20":
                setr(r["id"], "OD-30 and OD-LE-01 (owner): Living Economy is Expansion 20; numbering and placement only, implementation not authorized",
                     target_build="20")
    setr("VP-01", "OD-30 (owner): Village Politics is Expansion 21; numbering only, implementation not authorized", target_build="21")
    for rid in ("OD-LE-05", "OD-LE-07", "OD-LE-08", "OD-LE-12"):
        by[rid]["related"] = {"OD-LE-05": ["TRADE-CREDIT"], "OD-LE-07": ["ECON-P3"], "OD-LE-08": ["TRADE-CREDIT"], "OD-LE-12": ["DVW-B3-CHAPEL"]}[rid]
        hist(by[rid], "reconciliation: related", "overlaps a Build 18 owner answer of 2026-10-23; to be reconciled with the owner, not assumed answered")
    # ---- 7. aliases from other numbering schemes found in the documents -----------------------------------------------
    for rid, als, why in (("ORE-PLACE-01", ["WORLD-ORE-01"], "docs/directives/2026-10-22_build18_world_axe_tree_corrections.md names it WORLD-ORE-01"),
                          ("BARBER-01", ["BARBER-18"], "docs/SYSTEM_INTERACTION_MANIFEST.md names it BARBER-18"),
                          ("MIN-E-Q4", ["MIN-E-Q6"], "the consolidated Build 17 directive numbers it MIN-E-Q6 (its header maps it)"),
                          ("MIN-E-Q5", ["MIN-E-Q7"], "the consolidated Build 17 directive numbers it MIN-E-Q7 (its header maps it)"),
                          ("K-3", ["F-4"], "docs/release/BUILD_7_ISSUES.md row F-4 is this item (K-3)")):
        by[rid]["aliases"] = sorted(set((by[rid].get("aliases") or []) + als))
        hist(by[rid], "reconciliation: aliases %s" % ", ".join(als), why)
        for a in als:
            notes.append({"id": a, "source": why, "canonical_id": rid, "action": "alias", "reason": "another numbering of the same record", "evidence": why})

    # ---- 8. records found in the documents but never registered --------------------------------------------------------
    def decision(rid, title, target, source, disposition="OPEN", answer=None, blocks=False, related=None, notes_=""):
        return {"id": rid, "kind": "decision", "title": title, "description": title, "source": source, "owner_wording": None,
                "owner_answer": answer, "disposition": disposition, "blocks_implementation": blocks, "target_build": target,
                "related": related or [], "approval": "", "acceptance": [], "notes": notes_}
    add(decision("X18-D2", "Expansion 18 D2: what limits effective capability", "18",
                 "docs/directives/2026-10-23_owner_answers_tailor_barber_d2_d3.md", "APPROVED",
                 "No limit now (effective capability equals experience); when facilities gain wear or damage, a worn facility caps whoever works at it",
                 related=["X18-CAPCOMP"]), "owner answer of 2026-10-23, recorded only on X18-CAPCOMP's history until now")
    add(decision("Q18-6", "Q18-6: may abstract regions show 'two settlements develop different profiles'", "18",
                 "expansion18/DECISIONS_PENDING.md on wip/build18; docs/directives/2026-10-23_owner_answers_q18_4_q18_8.md", "PROVISIONAL",
                 "Agent reading, not an owner answer: settled by Q18-3 (each settlement a simulated economy under the same rules, so profiles diverge). Needs the owner's confirmation.",
                 related=["Q18-3"]), "named in the Expansion 18 documents but never registered")
    add(decision("STONE-D1", "Stone dressing efficiency values by skill (STONE-04) and the materials rule's numbers", "18",
                 "docs/directives/2026-10-22_msw01_outstanding_issues_x18_preparation.md; expansion18/DECISIONS_PENDING.md on wip/build18 (blocked items)",
                 blocks=True, related=["STONE-04", "X18-STONECUT"]), "listed as an owner question in the documents, never registered")
    add(decision("STONE-D2", "Iron chisel wear and recipe (STONE-06)", "18",
                 "docs/directives/2026-10-22_msw01_outstanding_issues_x18_preparation.md; expansion18/DECISIONS_PENDING.md on wip/build18 (blocked items)",
                 blocks=True, related=["STONE-06", "X18-STONECUT"]), "listed as an owner question in the documents, never registered")
    add(decision("X18-FEES", "Courier fee coefficients and the small-agreement threshold (X18-Q12, X18-Q13)", "18",
                 "expansion18/DESIGN.md on wip/build18 (owner questions: the fee coefficients and the small-agreement threshold need numbers)",
                 related=["X18-Q12", "X18-Q13"], notes_="Non-blocking: provisional values in couriers.json can stand until the owner reviews."),
        "listed in the Expansion 18 design, never registered")
    pol = [("Q-POL-7", "Placement and gate: politics waits for Expansion 19's live judgment, or an interim voter model behind a switch"),
           ("Q-POL-1", "Political structure of the starting village (manor with a reeve, elected mayor, council, or a mix; what the lord retains)"),
           ("Q-POL-2", "Franchise: who votes and who may stand"),
           ("Q-POL-3", "Office terms, election season and by-elections (with the 8-day game year)"),
           ("Q-POL-5", "Ties in elections"), ("Q-POL-6", "Removal from office"),
           ("Q-POL-4", "Vote privacy and which totals are public"),
           ("Q-POL-8", "The constable and the law: a constable and crime records before Expansion 22; the friendly guard (X19 conflict 3)"),
           ("Q-POL-9", "Taxes under an elected authority and DVW-B5's predictability")]
    for rid, q in pol:
        add(decision(rid, q, "21", "docs/directives/2026-10-21_master_expansion_roadmap.md; Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 5.2)",
                     blocks=True, related=["VP-01"], notes_="Drafted by the agent in the preliminary plan; not yet presented to the owner."),
            "Build 21 preliminary plan question, never registered")
    by["Q-POL-9"]["related"] = ["VP-01", "DVW-B5"]
    for rid, t in (("VP-01A", "Audit of the reeve, guard pay and succession decision points"), ("VP-01B", "Offices and civic work"),
                   ("VP-01C", "Voting and the election lifecycle"), ("VP-01D", "Political consequences in village life"),
                   ("VP-01E", "Soak, calibration and owner review")):
        add({"id": rid, "kind": "proposal", "title": "Village politics stage: " + t, "description": "Agent-proposed implementation stage (Build 21 preliminary plan section 6); not approved",
             "source": "Build 21 preliminary plan (wip/expansion21-preparation 0eeb3df, expansion21/PRELIMINARY_PLAN.md section 6)",
             "parent": "VP-01", "target_build": "21", "approval": "", "acceptance": [], "approval_status": "PROPOSED",
             "implementation_status": "NOT STARTED", "verification_status": "NOT APPLICABLE", "release_status": "NOT APPLICABLE", "completion": "OPEN"},
            "agent-proposed stage in the Build 21 plan, never registered")
    wdr = {"017": ("Generational Memory and Living History", "NOT STARTED", ["GM-01", "DVW-B7"]),
           "018": ("Protected Ecological Continuity", "PARTIALLY IMPLEMENTED", ["ECON-P2"]),
           "019": ("Living Political Agency and Democratic Consequences", "NOT STARTED", ["VP-01"]),
           "020": ("Autonomous Housing", "PARTIALLY IMPLEMENTED", ["EQ-07"]),
           "021": ("Household Succession and Family Care", "PARTIALLY IMPLEMENTED", [])}
    for n, (name, impl, rel) in wdr.items():
        add({"id": "WDR-%s-C" % n, "kind": "approved", "title": "Comply with World Design Rule %d: %s" % (int(n), name),
             "description": "Compliance with the owner's World Design Rule %s (docs/WORLD_DESIGN_RULES.md); entries WDR-001-C..016-C and WDR-022-C set the precedent" % n,
             "source": "docs/WORLD_DESIGN_RULES.md (WDR-%s)" % n, "approval": "owner rule WDR-%s" % n,
             "acceptance": ["Rule %d's mandatory bullets met, shown by its verification scenario (docs/WORLD_DESIGN_RULES.md)" % int(n)],
             "target_build": "unassigned", "related": rel, "approval_status": "OWNER APPROVED", "implementation_status": impl,
             "verification_status": "NOT TESTED", "release_status": "NOT READY", "completion": "OPEN",
             "remaining_work": "compliance audit against the rule's verification scenario (human review)" if impl != "NOT STARTED" else ""},
            "rules 017-021 had no compliance entry (the Build 21 plan found the WDR-019-C gap); build not assigned")
    gate = [("REL18-SUITES", "All automated suites pass on the final Build 18 integration commit"),
            ("REL18-DET", "Determinism gate re-recorded on Build 18 code (two independent runs identical)"),
            ("REL18-LONGRUN", "Conservation and long runs: one 365-day run per required seed, no ledger leak (SIM-01)"),
            ("REL18-SAVE", "Save compatibility: a real Build 17 save loads into Build 18, plus migration fixtures"),
            ("REL18-EXPORT", "Android, Windows and Linux packages from one commit and one build number"),
            ("REL18-DEVICE", "Device and owner playtest of every player-facing Build 18 requirement (the playtest queue)"),
            ("REL18-WIKI", "WIKI-01 release gate: new and changed mechanics documented, wiki checks pass"),
            ("REL18-OWNER", "The owner's approval to publish a Build 18 distributable (B17-DIR exception carried to Build 18)")]
    for rid, t in gate:
        add({"id": rid, "kind": "approved", "title": "Build 18 release gate: " + t, "description": t,
             "source": "CLAUDE.md section 5 (release policy; testing philosophy; SIM-01; WIKI-01)", "approval": "standing owner release policy (CLAUDE.md section 5)",
             "acceptance": [t], "target_build": "18", "workstream": "release gate", "approval_status": "OWNER APPROVED",
             "implementation_status": "NOT STARTED", "verification_status": "NOT TESTED", "release_status": "NOT READY",
             "completion": "OPEN", "design": "SPECIFIED", "effort": "M" if rid in ("REL18-LONGRUN", "REL18-DEVICE", "REL18-EXPORT") else "S"},
            "the release gate was not tracked in the register, so release readiness could not be computed")
    # ---- 9. Build 19: the prototype gates, the X19 decisions' build, design and effort (audit 2026-10-23) ------------------
    for rid in ("SJD-B", "SJD-C", "SJD-D"):
        setr(rid, "done in prototype form on %s (c4b10e4): expansion19 DESIGN.md (audit), judgment_store (prototype), judgment_weighting (decision prototype); switched off, not integrated" % X19,
             implementation_status="IMPLEMENTED ON TASK BRANCH", branch=X19, task_branches=["Expansion 19 prototype " + X19],
             verification_status="TARGETED TESTS PASSED", tests=X19_TESTS, test_commit="c4b10e4", commits=["c4b10e4"])
    setr("SJD-E", "live adapter (judgment_live) exists on %s, switched off; no domain integrated; needs the rework for the owner's 2026-10-23 answers" % X19,
         implementation_status="PARTIALLY IMPLEMENTED", branch=X19, task_branches=["Expansion 19 prototype " + X19], commits=["c4b10e4"],
         verification_status="TARGETED TESTS PASSED", tests=X19_TESTS, test_commit="c4b10e4", remaining_work=X19_REWORK)
    for rid, (des, eff) in {"SJD-B": ("SPECIFIED", "XS"), "SJD-C": ("SPECIFIED", "M"), "SJD-D": ("SPECIFIED", "M"),
                            "SJD-E": ("SPECIFIED", "L"), "SJD-F": ("SPECIFIED", "XL"), "SJD-G": ("PARTIAL", "L"), "SJD-H": ("SPECIFIED", "XS"),
                            "DVW-B2": ("UNKNOWN", "L"), "GM-01": ("UNKNOWN", "L"), "DVW-B1": ("PARTIAL", "M")}.items():
        by[rid]["design"], by[rid]["effort"] = des, eff
    by["SJD-G"]["decisions"] = ["X19-DECAY"]
    for r in d["requirements"]:
        if r["id"].startswith("X19-") and r.get("kind") == "decision" and r.get("target_build") != "19":
            setr(r["id"], "a Build 19 judgment decision (parent PROS-19); the build is established by its parent", target_build="19")
    # Build 18 records implemented and tested against their acceptance criteria were specified enough to build
    for r in d["requirements"]:
        if r.get("target_build") == "18" and r.get("kind") == "approved" and r.get("implementation_status") == "INTEGRATED" and not r.get("design"):
            r["design"] = "SPECIFIED"
    add({"id": "REQ-CTRL-01", "kind": "approved", "title": "One authoritative requirements and decision register with separate status dimensions, validation, generated views and divergence control",
         "description": "Master requirements reconciliation and permanent development control system (owner directive of 2026-10-23)",
         "source": "docs/directives/2026-10-23_master_requirements_reconciliation.md", "approval": "owner directive 2026-10-23",
         "owner_wording": "One authoritative source of truth. One consistent development workflow. No lost requirements. No inflated completion reports.",
         "acceptance": ["Section 21 of the directive: every original record accounted for; one register; one decision register; generated views; validator passes; reproducible reports; worker instructions; compaction recovery points to the records"],
         "target_build": "unassigned", "workstream": "project management", "approval_status": "OWNER APPROVED",
         "implementation_status": "IN DEVELOPMENT", "assigned_worker": "lead", "branch": "wip/requirements-control",
         "verification_status": "NOT TESTED", "release_status": "NOT APPLICABLE", "completion": "OPEN", "design": "SPECIFIED", "effort": "M"},
        "this directive")
    for r in d["requirements"]:
        r.setdefault("history", [])
    return notes
