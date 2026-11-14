# Build 42 shared agent brief (lead, 2026-11-13; restored 2026-11-14 after a container restart). Read fully before starting.

Durable copy: origin/wip/requirements-control docs/handoffs/B42_AGENT_BRIEF.md (the /dev/shm copy is wiped by restarts).
Project: Forge My Life (formerly My Medieval Life), Godot 4.7.2, repo verbal76/My-Medieval-Life, local repo
/home/user/My-Medieval-Life. Owner directives on origin/wip/requirements-control docs/directives/ (Build 42:
2026-11-13_build42_engineering_directive.md, 2026-11-14_b42_owner_decisions_open_issue_accountability.md,
2026-11-14_b42_movement_stutter_correction.md). Project rules: CLAUDE.md (sections 4, 5, 9a, 10, 10a, 12, wiki rule).

BASE: Build 42 work branches from 0bbee94 (Build 41 candidate) unless your assignment says otherwise. Integration branch
(lead only): wip/b42-integration. Never push to wip/b25-preview, wip/b41-stream-candidate, main, staging, or another
agent's branch. No merges into protected branches, no packaging runs, no publishing, no baseline approval/re-recording.
GitHub Actions: only what your assignment explicitly allows.

ENVIRONMENT (mandatory; / is nearly full; /dev/shm is wiped by container restarts):
- Checkout in /dev/shm ONLY:
    git clone -q --shared /home/user/My-Medieval-Life /dev/shm/<you>
    cd /dev/shm/<you> && git remote set-url origin "$(git -C /home/user/My-Medieval-Life remote get-url origin)"
    for b in staging/my-medieval-life wip/build18 wip/build17 wip/expansion18-preparation wip/expansion19-preparation wip/expansion20-preparation wip/expansion21-preparation wip/expansion20 wip/requirements-control; do git fetch -q origin "+$b:refs/remotes/origin/$b"; done
    git fetch -q origin <your-branch>; git checkout -q -B <your-branch> origin/<your-branch>   (or -b from 0bbee94 if new)
  Where the branch has tools/check_test_env.py, use `python3 tools/check_test_env.py --fetch --candidate <sha>` instead.
- export PATH=/opt/godot:$PATH XDG_DATA_HOME=/dev/shm/<you>-data TMPDIR=/dev/shm/<you>-tmp (mkdir it); outputs in /dev/shm.
- CPU/RAM: 4 cores shared by several agents; runs have been OOM-killed. At most ONE Godot process at a time; no local
  sims beyond 30 days (365-day runs go to CI via the flight-recorder agent only).
- Commit and push your branch after each meaningful step. Trailer:
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01Twyxni5CnEyE5LMG3EMiFY

RECORDS: register and tracker live on origin/wip/requirements-control and are edited ONLY by the lead; report status to
the lead. Keep original ids. INT manifest entries and DECISIONS rows go on your code branch with your change; wiki pages
for player-facing behaviour.

VERIFICATION STANDARD (owner): implemented ≠ internally verified. Verified = intended behaviour (owner's wording and
decisions) + integrated + applicable tests + cross-system checks + sims where relevant + anomalies investigated + evidence
on an exact SHA. Tests can confirm wrong behaviour: check they assert what the owner asked. Owner device playtesting is
not required for internal verification. Separate facts from hypotheses; preserve failed approaches; genuine owner
decisions go to the lead with options and a recommendation.

REPORT: commits (SHA), files, tests with exact counts, the 10-day seed-1 fingerprint where you touched game logic
(`godot --headless --path game -s tests/economy_sim.gd -- --days 10 --seed 1`; reference judgment state hash 2716197525
for 0bbee94-equivalent simulation; explain any deliberate difference), what remains, owner questions. Counts, not percentages.
