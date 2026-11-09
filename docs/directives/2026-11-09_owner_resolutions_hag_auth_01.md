# Owner directive, 2026-11-09: Owner resolutions to HAG-AUTH-01 (five decisions)

Received 2026-11-09 15:10 EST (system clock) in the lead session. Saved verbatim below; never edited. Register ids:
PAR-AGENTS-01, REL-OWNER-01, BRANCH-POL-Q1 and BRANCH-POL-Q2 (answered), BASELINE-AUTH-01, DECISION-CONFLICT-01.

---

MY MEDIEVAL LIFE — OWNER RESOLUTIONS TO HAG-AUTH-01

Owner decisions — November 9, 2026

Record the following five decisions in the authoritative requirements register and generated authority view on "wip/requirements-control".

Preserve the previous decisions, mark supersessions explicitly, update affected recovery instructions, and run the documentation integrity checks.

1. PARALLEL AGENTS — APPROVED WITH CONDITIONS

You are authorized to operate with one lead agent and up to two additional Claude agents simultaneously.

Additional agents are permitted when their assignments are properly scoped and they will not interfere with each other or compromise existing development.

Requirements:

- Each worker has one clearly defined responsibility and deliverable.
- Each worker uses an isolated worktree and its own authorized working branch.
- No two agents modify the same files or systems concurrently without a documented coordination plan.
- The lead remains responsible for reviewing, testing, and integrating their work.
- Workers must commit and push recoverable checkpoints and document decisions, results, and unfinished work.
- Do not duplicate ongoing simulations or restart expensive tests unnecessarily.
- Monitor Claude token consumption. At my last check, usage was approximately 2% of the available allowance; this is an observation, not a verified current reading.
- Do not exceed two additional agents without further owner authorization.

The previous standing one-worker restriction is superseded to the extent it conflicts with this authorization. This does not override safeguards against overlapping work, unauthorized production changes, or excessive resource usage.

You may assign these workers when genuinely useful. Do not spawn agents merely to fill the available slots.

2. RELEASE AUTHORIZATION — OWNER CONTROL

No automatic publishing or creation of releases, including private-draft releases, based solely on passing validation gates.

Agents may complete development, run authorized tests, prepare packages where already authorized, and report release readiness.

I retain final authorization for creating or publishing releases.

Previously granted automatic release permissions that conflict with this decision are superseded. Preserve the historical records explaining those permissions.

3. BRANCH AUTHORITY — CONFIRMED

The authoritative Build 25 development branch is:

"wip/b25r2-rev2"

Update outdated branch-policy instructions that still identify "wip/expansion20" as the current development line.

The authoritative documentation and requirements-control branch remains separate:

"wip/requirements-control"

Do not merge these two branches merely to consolidate records.

The development branch owns integrated game code. The records branch owns the authoritative requirements, decisions, and documentation.

Update BRANCH-POL-Q1 and BRANCH-POL-Q2 accordingly, preserving the superseded branch history.

4. BASELINE AUTHORITY — OWNER APPROVAL REQUIRED

No agent has independent authority to promote, replace, or re-record simulation baselines.

Agents may investigate discrepancies, produce candidate baselines, measure differences, and recommend changes supported by evidence.

The owner must authorize baseline promotion.

Preserve the Generation 8 baseline decision and distinguish existing approved baseline records from unapproved candidates.

Never modify a baseline merely to make failing tests pass.

5. CONFLICTING DECISIONS — COMPLETE ANALYSIS REQUIRED

The latest explicit owner decision governs the specific subject it actually changes.

However, a later answer does not automatically supersede unrelated requirements or every part of an earlier directive.

When two decisions appear to conflict, do not silently select one.

Prepare a complete owner-decision analysis containing:

A. Original position

- The full original requirement or decision.
- Its purpose and underlying reasoning.
- Its supporting evidence and implementation history.
- The systems and behaviors it protects.

B. Later position

- The full later requirement or decision.
- Why it was introduced.
- What changed in the evidence, circumstances, or owner's goals.
- Exactly which portions of the earlier decision it explicitly replaces.

C. Additional alternatives

Do not assume the answer must be A or B.

Investigate whether a third option, compromise, or redesigned approach better accomplishes the intended goals.

Explain the advantages, disadvantages, implementation effort, and risks of each feasible alternative.

D. Complete system impact analysis

For every proposed resolution, identify ALL affected game systems and explain HOW each would change.

Consider, as applicable:

- Gameplay mechanics and player interactions.
- NPC behavior, employment, and household relationships.
- Economy, inventory, goods, money, and conservation rules.
- Property ownership, construction, and businesses.
- Settlements, regions, travel, and migration.
- Multiplayer, permissions, security, and synchronization.
- Save files, persistence, backward compatibility, and migration.
- User interface and player feedback.
- Performance and determinism.
- Dependencies on other features or approved requirements.
- Existing tests, regression coverage, and simulation baselines.
- Release compatibility across Windows, Linux, and Android.

Do not merely list system names. Explain the direct and indirect consequences of each proposed option. Mark unknown impacts as requiring investigation.

E. Recommendation and owner decision

Present the evidence-supported recommendation, including any superior third alternative.

Identify what will remain unchanged and what will be superseded.

Do not implement an ambiguous policy change until I resolve the conflict.

Once resolved, update the authoritative register, supersession chains, affected system documentation, and regression requirements.

EXECUTION

Record these five owner decisions in the existing requirements-control system. Do not create a competing authority register.

Run the documentation checks and correct any problems introduced by these updates.

Commit and push to the records branch, verify the remote SHA, and report:

1. Decision IDs updated or created.
2. Conflicts resolved.
3. Conflicts still requiring my attention.
4. Tests passed.
5. Verified GitHub commit SHA.

Continue authorized Build 25 and MP-05 work without interrupting existing simulation campaigns.

These decisions establish the governing policy. Do not reopen them merely because an older document says something different.
