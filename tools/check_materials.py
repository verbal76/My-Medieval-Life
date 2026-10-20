"""Report material and profession coverage from the recipe data (World Design Rules 001, 002, 003, 007).

Rule 007 (Automated Compliance, register entry WDR-007-C) asks for a material interdependency report
generated from the actual recipe data, flagging violations, broken references and undocumented
exceptions. This tool builds that report from game/data (recipes.json, items.json, balance.json,
resources.json) and from the code that decides who crafts what (NPCBrain's job functions), checks it
against the thresholds of Rules 001 and 002, and generates docs/systems/MATERIAL_INTERDEPENDENCY.md.

What is counted, and why (the same text heads the generated document):

- A *standard crafting material* is an item of type "resource" (items.json) that a recipe or a
  construction consumes. Food, medicine and equipment that a recipe also takes (ale, milk, a healing
  tonic) are end goods, listed apart and not held to Rule 001.
- A material's *meaningful uses* are the distinct products of the recipes consuming it plus the
  distinct kinds of construction consuming it (Rule 003: two recipes making the same item, such as
  tan_pelts and tan_leather, count once). Construction counts because Rule 001's own example counts a
  house: house_cost, workshop_cost (all kinds as one), the loft, the storefront and the shop fittings
  (shop_equipment) are five construction uses.
- A recipe's *profession* is the NPC job whose work code runs it (JOB_WORK below: the functions are
  cited and checked). The game has no recipe-to-trade field: the station does not decide it (the
  workbench serves both the tanner and the carpenter), the job's code does. Recipes no job runs are
  the player's alone (any station, main.gd::craft) and add no profession. Households (home work,
  building their own houses) are not a profession, and the game has no builder trade, so construction
  adds uses but no profession.
- A *production profession* is a job that runs a recipe or harvests a node (GATHERING: the node
  categories its work function harvests, NPC-harvested nodes only). It *supplies* another profession
  when one of its products is an input of a recipe that profession runs, an item the profession buys
  for its trade (NPCBrain.BUYS) or an item it keeps for its work, such as its tools (NPCBrain.KEEPS).
  Merchants' purchases (BUYS merchant_*) are resale, shown but not counted.
- An *orphaned recipe* makes nothing that a recipe or construction consumes, a job needs, or that is an
  end good: food (food > 0), medicine (heal > 0), equipment (EQUIP types), a cart (cart: true), a
  plant, or an item with a code-defined use in resources.json "materials".
- Exceptions are recorded in docs/systems/material_exceptions.json (mml-material-exceptions/1); each
  names one material, profession or recipe, the finding it excuses, the reason and the rule.

Hard errors (exit 1): broken references (unknown item, station, recipe, job or cited function) and
stale or invalid exceptions. Threshold violations without an exception are listed and counted; with
--strict they fail the check too.

    python3 tools/check_materials.py            # report; exit 1 on broken references or stale exceptions
    python3 tools/check_materials.py --strict   # also exit 1 on any open threshold violation
    python3 tools/check_materials.py --write    # regenerate docs/systems/MATERIAL_INTERDEPENDENCY.md, then check
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_resources as cr  # noqa: E402  (one loader and one set of derived facts for the game data)

ROOT = Path(__file__).resolve().parent.parent
DOC = ROOT / "docs" / "systems" / "MATERIAL_INTERDEPENDENCY.md"
EXCEPTIONS = ROOT / "docs" / "systems" / "material_exceptions.json"
EXC_FORMAT = "mml-material-exceptions/1"
MIN_USES = 3          # Rule 001: at least three meaningfully different recipes
MIN_PROFESSIONS = 2   # Rule 001: across at least two distinct professions
BRAIN = "game/scripts/core/npc_brain.gd"
# which code runs each job's recipes ("file::function", or "file::function@branch" for one branch of a
# `match n.job` in that function)
JOB_WORK = {
    "smith": [BRAIN + "::_smith"],
    "tanner": [BRAIN + "::_tanner"],
    "cook": [BRAIN + "::_cook"],
    "carpenter": [BRAIN + "::_plan_job@carpenter", BRAIN + "::_carpenter_carts"],
    "sage": [BRAIN + "::_plan_job@sage"],
}
# households' own recipes (not a profession): home brewing, cooking at the hearth, a storefront's cart,
# sawing planks for their own house
HOUSEHOLD_WORK = [BRAIN + "::_plan_home_work", BRAIN + "::_cook_at_home", BRAIN + "::_plan_cart",
                  "game/scripts/core/construction.gd::_make_timber"]
# the node categories (resources.json) each gathering job harvests, and the function that does it
GATHERING = {
    "miner": (["mineral"], BRAIN + "::_miner"),
    "laborer": (["mineral"], BRAIN + "::_plan_job@laborer"),
    "woodcutter": (["wood"], BRAIN + "::_woodcutter"),
    "farmer": (["crop", "livestock"], BRAIN + "::_farmer"),
    "hunter": (["game"], BRAIN + "::_hunter"),
}
END_TYPES = sorted(set(cr.EQUIP) | {"food", "medicine"})
FINDINGS = {"few_uses": "material", "few_professions": "material", "supplies_nobody": "profession",
            "orphan": "recipe"}
HEADER = ("<!-- Generated by tools/check_materials.py --write from game/data (recipes, items, balance, "
          "resources), the job code and docs/systems/material_exceptions.json. Do not edit: change the data "
          "or the exceptions and regenerate. -->")


# ---------------------------------------------------------------- loading --------------------
def code_body(root, ref):
    """The text of a cited function (or one `match` branch of it), or None when it is missing."""
    path, _, name = ref.partition("::")
    name, _, branch = name.partition("@")
    p = root / path
    if not p.is_file():
        return None
    body = cr.func_body(p.read_text(encoding="utf-8"), name)
    if not body:
        return None
    if not branch:
        return body
    lines = body.splitlines()
    for n, line in enumerate(lines):
        if re.match(r'^\s+("[a-z_]+",\s*)*"%s"(,\s*"[a-z_]+")*:\s*$' % re.escape(branch), line):
            depth = len(line) - len(line.lstrip("\t"))
            out = [line]
            for more in lines[n + 1:]:
                if more.strip() and len(more) - len(more.lstrip("\t")) <= depth:
                    break
                out.append(more)
            return "\n".join(out)
    return None


def recipes_in(text, recipes):
    """Recipe ids named as string literals in a piece of code."""
    return sorted({s for s in re.findall(r'"(\w+)"', text or "") if s in recipes})


def load(root=ROOT):
    """The game's data as the plain dict build_report reads."""
    ctx = cr.load(root)
    items, recipes, bal = ctx["items"], ctx["recipes"], ctx["balance"]
    brain = (root / BRAIN).read_text(encoding="utf-8")
    jobs = sorted(cr.gd_const((root / "game/scripts/core/population.gd").read_text(encoding="utf-8"), "JOBS"))
    refs, crafters = [], {}
    for job, cited in sorted(JOB_WORK.items()):
        for ref in cited:
            body = code_body(root, ref)
            refs.append({"ref": ref, "ok": body is not None})
            for r in recipes_in(body, recipes):
                crafters.setdefault(r, set()).add(job)
    household = set()
    for ref in HOUSEHOLD_WORK:
        body = code_body(root, ref)
        refs.append({"ref": ref, "ok": body is not None})
        household |= set(recipes_in(body, recipes))
    gathering = {}
    for job, (cats, ref) in sorted(GATHERING.items()):
        refs.append({"ref": ref, "ok": code_body(root, ref) is not None})
        got = set()
        for node in ctx["res"]["nodes"].values():
            if node.get("npc_harvest") and node.get("category") in cats:
                got |= set(cr.products(ctx, node))
        gathering[job] = sorted(got)
    needs, resale = {}, set()
    for role, caps in ctx["buys"].items():
        if role.startswith("merchant_"):
            resale |= set(caps)
        elif role in jobs:
            for i in caps:
                needs.setdefault(role, {})[i] = "buys"
    for job, tools in cr.gd_const(brain, "KEEPS").items():
        if job in jobs:
            for i in tools:
                needs.setdefault(job, {}).setdefault(i, "keeps")
    construction = {
        "house": {"house": bal["house_cost"]},
        "workshop": bal.get("workshop_cost", {}),
        "loft": {"loft": bal.get("loft", {}).get("cost", {})},
        "storefront": {"storefront": bal.get("storefront_cost", {})},
        "shop fittings": bal.get("shop_equipment", {}),
    }
    end_uses = {}
    for i, it in items.items():
        kinds = set()
        if it.get("type") in END_TYPES:
            kinds.add(it["type"] if it["type"] in ("food", "medicine") else "equipment")
        if it.get("food", 0) > 0:
            kinds.add("food")
        if it.get("heal", 0) > 0:
            kinds.add("medicine")
        if it.get("cart"):
            kinds.add("cart")
        if it.get("plant"):
            kinds.add("plant")
        for u in ctx["res"].get("materials", {}).get(i, []):
            kinds.add(u["use"])
        if kinds:
            end_uses[i] = sorted(kinds)
    path = root / EXCEPTIONS.relative_to(ROOT)
    exc = json.loads(path.read_text()) if path.is_file() else {"format": EXC_FORMAT, "exceptions": []}
    return {
        "items": items, "recipes": recipes, "stations": sorted(cr.station_types(ctx)), "jobs": jobs,
        "crafters": {r: sorted(j) for r, j in sorted(crafters.items())}, "household": sorted(household),
        "gathering": gathering, "needs": {j: dict(sorted(n.items())) for j, n in sorted(needs.items())},
        "resale": sorted(resale), "construction": construction, "end_uses": end_uses,
        "code_refs": refs, "exceptions_format": exc.get("format"), "exceptions": exc.get("exceptions", []),
    }


# ---------------------------------------------------------------- the report -----------------
def build_report(data):
    """Coverage, findings and errors for one dataset (see the module docstring for the rules)."""
    items, recipes = data["items"], data["recipes"]
    stations, jobs = set(data["stations"]), set(data["jobs"])
    crafters, construction = data.get("crafters", {}), data.get("construction", {})
    gathering, needs = data.get("gathering", {}), data.get("needs", {})
    end_uses = data.get("end_uses", {})
    broken = []

    def item_ok(where, i):
        if i not in items:
            broken.append("%s: unknown item %r" % (where, i))

    for r, rec in sorted(recipes.items()):
        if rec.get("station") not in stations:
            broken.append("recipe %s: unknown station %r" % (r, rec.get("station")))
        if not rec.get("out"):
            broken.append("recipe %s: makes nothing" % r)
        for side in ("in", "out"):
            for i in sorted(rec.get(side, {})):
                item_ok("recipe %s (%s)" % (r, side), i)
    for r, js in sorted(crafters.items()):
        if r not in recipes:
            broken.append("job code names unknown recipe %r" % r)
        for j in js:
            if j not in jobs:
                broken.append("recipe %s: run by unknown job %r" % (r, j))
    for r in data.get("household", []):
        if r not in recipes:
            broken.append("household code names unknown recipe %r" % r)
    for j, got in sorted(gathering.items()):
        if j not in jobs:
            broken.append("gathering: unknown job %r" % j)
        for i in got:
            item_ok("gathering by %s" % j, i)
    for j, need in sorted(needs.items()):
        if j not in jobs:
            broken.append("trade needs: unknown job %r" % j)
        for i in sorted(need):
            item_ok("trade needs of %s" % j, i)
    for group, kinds in sorted(construction.items()):
        for kind, cost in sorted(kinds.items()):
            for i in sorted(cost):
                item_ok("construction %s (%s)" % (group, kind), i)
    for ref in data.get("code_refs", []):
        if not ref["ok"]:
            broken.append("cited code not found: %s" % ref["ref"])

    runs_by = {r: sorted(j for j in crafters.get(r, []) if j in jobs) for r in recipes}
    household = set(data.get("household", []))
    consumers, makers = {}, {}
    for r, rec in sorted(recipes.items()):
        for i in rec.get("in", {}):
            consumers.setdefault(i, []).append(r)
        for i in rec.get("out", {}):
            makers.setdefault(i, []).append(r)
    built_with = {}
    for group, kinds in sorted(construction.items()):
        for kind, cost in sorted(kinds.items()):
            for i in cost:
                built_with.setdefault(i, {}).setdefault(group, []).append(kind)
    gathered_by = {}
    for j, got in sorted(gathering.items()):
        for i in got:
            gathered_by.setdefault(i, []).append(j)
    needed_by = {}
    for j, need in sorted(needs.items()):
        for i, how in sorted(need.items()):
            needed_by.setdefault(i, []).append((j, how))

    findings = []          # (kind of subject, subject, finding, detail)
    # materials (Rules 001 and 003)
    materials, ingredients = {}, {}
    for i in sorted(set(consumers) | set(built_with)):
        if i not in items:
            continue
        rs = consumers.get(i, [])
        products = sorted({o for r in rs for o in recipes[r].get("out", {})})
        groups = sorted(built_with.get(i, {}))
        profs = sorted({j for r in rs for j in runs_by[r]})
        row = {"recipes": rs, "products": products, "construction": groups, "uses": len(products) + len(groups),
               "professions": profs, "made_by": sorted(makers.get(i, [])), "gathered_by": gathered_by.get(i, []),
               "player_only": sorted(r for r in rs if not runs_by[r] and r not in household),
               "household": sorted(r for r in rs if r in household)}
        if items[i].get("type") != "resource":
            row["type"] = items[i].get("type", "")
            ingredients[i] = row
            continue
        row["findings"] = []
        if row["uses"] < MIN_USES:
            row["findings"].append("few_uses")
            findings.append(("material", i, "few_uses", "%d meaningful uses (%d recipes, %d construction), fewer than %d"
                             % (row["uses"], len(rs), len(groups), MIN_USES)))
        if len(profs) < MIN_PROFESSIONS:
            row["findings"].append("few_professions")
            findings.append(("material", i, "few_professions", "consumed by %d professions (%s), fewer than %d"
                             % (len(profs), ", ".join(profs) or "none", MIN_PROFESSIONS)))
        materials[i] = row

    # professions (Rule 002)
    professions = {}
    producing = sorted({j for js in runs_by.values() for j in js} | {j for j, g in gathering.items() if g and j in jobs})
    demand = {}
    for r, js in runs_by.items():
        for j in js:
            for i in recipes[r].get("in", {}):
                demand.setdefault(j, {}).setdefault(i, "recipe %s" % r)
    for j, need in needs.items():
        for i, how in need.items():
            demand.setdefault(j, {}).setdefault(i, "buys it" if how == "buys" else "keeps it for its work")
    resale = set(data.get("resale", []))
    for j in producing:
        made = sorted({o for r, js in runs_by.items() if j in js for o in recipes[r].get("out", {})} |
                      set(gathering.get(j, [])))
        supplies = {}
        for i in made:
            for q in sorted(demand):
                if q != j and i in demand[q]:
                    supplies.setdefault(q, []).append("%s (%s)" % (i, demand[q][i]))
        row = {"makes": made, "supplies": supplies, "resale": sorted(i for i in made if i in resale), "findings": []}
        if not supplies:
            row["findings"].append("supplies_nobody")
            findings.append(("profession", j, "supplies_nobody", "none of %s is needed by another profession"
                             % ", ".join(made)))
        professions[j] = row

    # orphaned recipes
    orphans = {}
    for r, rec in sorted(recipes.items()):
        outs = sorted(rec.get("out", {}))
        if outs and all(o not in consumers and o not in built_with and o not in needed_by and not end_uses.get(o)
                        for o in outs):
            orphans[r] = outs
            findings.append(("recipe", r, "orphan", "makes %s, which nothing consumes or uses" % ", ".join(outs)))

    # exceptions
    found = {(k, s, f) for k, s, f, _ in findings}
    excepted, stale, used = {}, [], set()
    if data.get("exceptions_format", EXC_FORMAT) != EXC_FORMAT:
        stale.append("material_exceptions.json: format is %r, not %r" % (data.get("exceptions_format"), EXC_FORMAT))
    subjects = {"material": items, "profession": jobs, "recipe": recipes}
    for n, e in enumerate(data.get("exceptions", [])):
        f = e.get("finding")
        kind = FINDINGS.get(f)
        where = "exception %d" % (n + 1)
        if kind is None:
            stale.append("%s: unknown finding %r (one of %s)" % (where, f, ", ".join(sorted(FINDINGS))))
            continue
        subject = e.get(kind)
        if not subject:
            stale.append("%s: a %s exception needs a %r" % (where, f, kind))
            continue
        if subject not in subjects[kind]:
            broken.append("%s: unknown %s %r" % (where, kind, subject))
            continue
        if not str(e.get("reason", "")).strip() or not str(e.get("rule", "")).strip():
            stale.append("%s (%s %s): needs a reason and a rule" % (where, subject, f))
        key = (kind, subject, f)
        if key in used:
            stale.append("%s (%s %s): recorded twice" % (where, subject, f))
        used.add(key)
        if key not in found:
            stale.append("stale exception: %s %s %s no longer occurs (remove it)" % (kind, subject, f))
            continue
        excepted[key] = e
    violations = [{"kind": k, "subject": s, "finding": f, "detail": d, "exception": excepted.get((k, s, f))}
                  for k, s, f, d in sorted(findings)]
    return {
        "materials": materials, "ingredients": ingredients, "professions": professions, "orphans": orphans,
        "recipes": recipes, "runs_by": runs_by, "household": sorted(household), "violations": violations,
        "open": [v for v in violations if not v["exception"]], "broken": sorted(set(broken)), "stale": stale,
    }


def errors(report, strict=False):
    """The problems that fail the check: broken references and stale exceptions (and, if strict, every
    threshold violation without an exception)."""
    out = ["broken reference: " + b for b in report["broken"]] + ["exception: " + s for s in report["stale"]]
    if strict:
        out += ["open violation: %s %s %s (%s)" % (v["kind"], v["subject"], v["finding"], v["detail"])
                for v in report["open"]]
    return out


# ---------------------------------------------------------------- the document ---------------
def _codes(xs):
    return ", ".join("`%s`" % x for x in xs) or "none"


def render(report):
    def exc_of(kind, subject, finding):
        for v in report["violations"]:
            if (v["kind"], v["subject"], v["finding"]) == (kind, subject, finding):
                return v["exception"]
        return None

    L = [HEADER, "", "# Material interdependency report", "",
         "World Design Rule 007 (Automated Compliance, register entry WDR-007-C): material and profession coverage "
         "generated from the recipe data and the job code, checked against Rules 001 (every standard crafting "
         "material consumed by at least %d meaningfully different recipes across at least %d professions), 002 (every "
         "production profession supplies another) and 003 (near-duplicate recipes count once). Run "
         "`python3 tools/check_materials.py` to check and `--write` to regenerate; `--strict` also fails on open "
         "violations. Exceptions are recorded in `docs/systems/material_exceptions.json`." % (MIN_USES, MIN_PROFESSIONS),
         "", "## How it is counted", "",
         "- **Standard crafting material:** an item of type `resource` (items.json) that a recipe or a construction "
         "consumes. Food, medicine and equipment that a recipe also takes are end goods (listed below, not held to "
         "Rule 001).",
         "- **Meaningful uses:** the distinct products of the recipes consuming it (Rule 003: two recipes making the "
         "same item count once) plus the distinct kinds of construction consuming it. Construction counts because "
         "Rule 001's own example counts a house: `house_cost`, `workshop_cost` (all kinds as one), the loft, the "
         "storefront and the shop fittings (`shop_equipment`) are five construction uses (balance.json).",
         "- **Profession of a recipe:** the NPC job whose work code runs it (tools/check_materials.py `JOB_WORK`, "
         "cited functions checked). The game has no recipe-to-trade field and the station does not decide it (the "
         "workbench serves the tanner and the carpenter). Recipes no job runs are the player's alone and add no "
         "profession; households (home work, their own houses) are not a profession, and the game has no builder "
         "trade, so construction adds uses but no profession.",
         "- **Supplying (Rule 002):** a production profession (one that runs a recipe or harvests a node) supplies "
         "another when one of its products is an input of a recipe that profession runs, an item it buys for its "
         "trade (`NPCBrain.BUYS`) or an item it keeps for its work, such as its tools (`NPCBrain.KEEPS`). Merchants' purchases are resale: shown, "
         "not counted.",
         "- **Orphaned recipe:** makes nothing that a recipe or construction consumes, a job needs, or that is an end "
         "good (food, medicine, equipment, a cart, a plant, or an item with a code-defined use in resources.json).",
         "", "## Summary", "",
         "| Measure | Count |", "|---|---|",
         "| Standard crafting materials | %d |" % len(report["materials"]),
         "| Production professions | %d |" % len(report["professions"]),
         "| Recipes | %d |" % len(report["runs_by"]),
         "| Threshold findings | %d |" % len(report["violations"]),
         "| ... with a recorded exception | %d |" % (len(report["violations"]) - len(report["open"])),
         "| ... open (no exception) | %d |" % len(report["open"]),
         "| Orphaned recipes | %d |" % len(report["orphans"]),
         "| Broken references | %d |" % len(report["broken"]),
         "| Stale or invalid exceptions | %d |" % len(report["stale"]),
         "", "## Materials (Rule 001)", "",
         "| Material | Meaningful uses | Consuming recipes | Construction | Professions | Made by | Gathered by | Result |",
         "|---|---|---|---|---|---|---|---|"]
    for i, m in report["materials"].items():
        if not m["findings"]:
            result = "pass"
        else:
            parts = []
            for f in m["findings"]:
                e = exc_of("material", i, f)
                parts.append("%s: %s" % (f.replace("_", " "), "exception" if e else "**open**"))
            result = "; ".join(parts)
        recs = []
        for r in m["recipes"]:
            who = ", ".join(report["runs_by"][r]) or ("households" if r in report["household"] else "player only")
            recs.append("`%s` (%s)" % (r, who))
        L.append("| `%s` | %d | %s | %s | %s | %s | %s | %s |" % (
            i, m["uses"], "; ".join(recs) or "none", ", ".join(m["construction"]) or "none",
            ", ".join(m["professions"]) or "none", _codes(m["made_by"]), ", ".join(m["gathered_by"]) or "none", result))
    L += ["", "### End goods also used as ingredients (not held to Rule 001)", "",
          "| Item | Type | Consuming recipes |", "|---|---|---|"]
    for i, m in report["ingredients"].items():
        L.append("| `%s` | %s | %s |" % (i, m.get("type", ""), _codes(m["recipes"])))
    L += ["", "## Professions (Rule 002)", "",
          "| Profession | Makes or gathers | Supplies | Resale to merchants | Result |", "|---|---|---|---|---|"]
    for j, p in report["professions"].items():
        sup = "; ".join("%s: %s" % (q, ", ".join(xs)) for q, xs in sorted(p["supplies"].items())) or "nobody"
        res = "pass" if not p["findings"] else ("supplies nobody: %s" % (
            "exception" if exc_of("profession", j, "supplies_nobody") else "**open**"))
        L.append("| %s | %s | %s | %s | %s |" % (j, _codes(p["makes"]), sup, _codes(p["resale"]), res))
    L += ["", "## Recipes and who runs them", "", "| Recipe | Station | Consumes | Makes | Run by |", "|---|---|---|---|---|"]
    for r in sorted(report["runs_by"]):
        rec = report["recipes"][r]
        who = list(report["runs_by"][r]) + (["households"] if r in report["household"] else [])
        L.append("| `%s` | %s | %s | %s | %s |" % (
            r, rec.get("station", ""), ", ".join("%s %s" % (q, i) for i, q in sorted(rec.get("in", {}).items())),
            ", ".join("%s %s" % (q, i) for i, q in sorted(rec.get("out", {}).items())), ", ".join(who) or "player only"))
    L += ["", "## Orphaned recipes", ""]
    L += ["- `%s` makes %s%s" % (r, _codes(o), " (exception)" if exc_of("recipe", r, "orphan") else "")
          for r, o in report["orphans"].items()] or ["None."]
    L += ["", "## Findings and exceptions", "", "| Subject | Finding | Detail | Exception (rule: reason) |", "|---|---|---|---|"]
    for v in report["violations"]:
        e = v["exception"]
        L.append("| %s `%s` | %s | %s | %s |" % (v["kind"], v["subject"], v["finding"], v["detail"],
                                                 "%s: %s" % (e["rule"], e["reason"]) if e else "**none: open**"))
    L += ["", "## Broken references", ""] + (["- " + b for b in report["broken"]] or ["None."])
    L += ["", "## Stale or invalid exceptions", ""] + (["- " + s for s in report["stale"]] or ["None."])
    return "\n".join(L) + "\n"


def main(argv):
    data = load()
    report = build_report(data)
    text = render(report)
    if "--write" in argv:
        DOC.parent.mkdir(parents=True, exist_ok=True)
        DOC.write_text(text)
    found = errors(report, strict="--strict" in argv)
    if not DOC.is_file() or DOC.read_text() != text:
        found.append("%s is out of date (run with --write)" % DOC.relative_to(ROOT))
    for v in report["open"]:
        print("open violation: %s %s %s: %s" % (v["kind"], v["subject"], v["finding"], v["detail"]))
    for p in found:
        print("problem: " + p)
    print("%d materials, %d professions, %d recipes: %d findings (%d excepted, %d open), %d orphaned recipes, "
          "%d broken references, %d stale exceptions" % (
              len(report["materials"]), len(report["professions"]), len(report["runs_by"]), len(report["violations"]),
              len(report["violations"]) - len(report["open"]), len(report["open"]), len(report["orphans"]),
              len(report["broken"]), len(report["stale"])))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
