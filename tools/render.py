"""Render the Hot Attic Games registry from scan data. Read-only against the source clones.

Usage: python3 -I render.py <data_dir> <notes.json> <out_dir> <repo,repo,...>   (the repos rendered so far)
"""
import collections, json, os, re, subprocess, sys

DATA, NOTES, OUT, INCL = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4].split(',')
notes = json.load(open(NOTES))
rel = json.load(open(os.path.join(DATA, 'releases.json')))
SCAN_DAY = '2026-10-18'
GH = 'https://github.com/verbal76/'
AUTH = {'My-Medieval-Life': 'staging/my-medieval-life', 'Climb-Up': 'ccr-cb458cd1-w4dh5c', 'Tartaria-RPG': 'golem-line',
        'Backrooms-Survivor': 'dev', 'Purgatory-Dungeon': 'ccr-5f32885a-gvu16v', 'Ragdoll-Rally': 'claude/launch-gameplay-pivot',
        'Idle-game': 'claude/repo-gameplay-review-loq9rq', 'My-Personal-Crossow0rd': 'claude/native-stack-modernization',
        'Zombie-squisher': 'ccr-27903f19-fy49jb'}
UPWARDLY_PATH = re.compile(r'^(branding/(steam|logo)/|desktop/src/main/resources/icons/upwardly_|docs/play_store_icon_512|assets/branding/|branding/master/|tools/icon/)')


def load(repo):
    return json.load(open(os.path.join(DATA, repo + '.json')))


def git(d, *a):
    r = subprocess.run(['git', '-C', d, *a], capture_output=True, text=True)
    return r.returncode, r.stdout.strip()


def anc(d, a, b):
    return subprocess.run(['git', '-C', d, 'merge-base', '--is-ancestor', a, b]).returncode == 0


def blob(repo, sha, path):
    return f'{GH}{repo}/blob/{sha}/{path}'.replace(' ', '%20')


def esc(s):
    return (s or '').replace('|', '\\|').replace('\n', ' ')


def status_of(d):
    dates = [b['committer_date'][:10] for b in d['branches'] if b.get('committer_date')]
    last = max(dates) if dates else None
    if not last:
        return 'unknown', None
    import datetime
    age = (datetime.date.fromisoformat(SCAN_DAY) - datetime.date.fromisoformat(last)).days
    return ('active' if age <= 14 else 'dormant'), last


def classify(repo, d):
    """Branch roles from names and ancestry; returns {name: (role, note)}."""
    clone = d['clone']; ref = AUTH.get(repo) or d['latest_branch']; refsha = next((b['sha'] for b in d['branches'] if b['name'] == ref), None)
    latest_date = max(b['committer_date'] for b in d['branches'] if b.get('committer_date'))
    out = {}
    for b in d['branches']:
        n = b['name']; role = []
        if n == d['default_branch']: role.append('GitHub default')
        if n == AUTH.get(repo): role.append('authoritative line (per repo records)')
        elif n == ref: role.append('most recent branch (reference line; not stated authoritative)')
        if n.startswith('wip/'): role.append('agent WIP snapshot')
        if n.startswith(('backup/', 'checkpoint/', 'preserve/', 'archive/')): role.append('backup / checkpoint')
        if n.startswith(('release/', 'qualify/')) or 'release' in n: role.append('release-related')
        if n.startswith(('ota', 'ota/')) or '/ota' in n: role.append('OTA channel/line')
        if n.startswith(('claude/', 'ccr-')): role.append('agent session branch')
        if n.startswith('exp/'): role.append('experimental')
        if n == 'inventory/registry': role.append('this registry (orphan)')
        note = ''
        if refsha and n != ref and 'sha' in b and b.get('committer_date'):
            if anc(clone, b['sha'], refsha):
                note = f'contained in `{ref}`'
            else:
                note = f'NOT contained in `{ref}`'
                import datetime
                age = (datetime.datetime.fromisoformat(latest_date) - datetime.datetime.fromisoformat(b['committer_date'])).days
                if age > 5 and n != 'inventory/registry':
                    note += f'; {age} days older than the newest branch: possibly stale or abandoned (unverified by content)'
        out[n] = (', '.join(role) or 'unknown', note, ref)
    return out


def dims(im):
    return f"{im['width']}x{im['height']}" if im.get('width') else 'unknown'


def important_images(d, repo):
    ref = AUTH.get(repo) or d['latest_branch']
    kw = re.compile(r'(?i)logo|icon|splash|brand|steam|store|promo|banner|cover|hero|title|feature|screenshot|capsule|key.?art|master')
    rows = []
    for im in d['images']:
        big = (im.get('width') or 0) >= 512 or (im.get('height') or 0) >= 512
        if (kw.search(im['path']) and not re.search(r'(?i)glyph|prompts?/', im['path'])) or big:
            rows.append(im)
    rows.sort(key=lambda im: (ref not in im['branches'], im['path']))
    return rows, ref


def repo_md(repo):
    nt = notes['repos'][repo]
    if nt.get('skip'):
        return f"# {repo}\n\nVisibility: {nt['visibility']}.\n\n**Not scanned.** {nt['skip']}\n"
    d = load(repo); st, last = status_of(d); cls = classify(repo, d)
    L = [f"# {repo}", '', f"Scanned {d['scanned_at']} from a blobless clone (trees and commits; blobs fetched only for images and key documents). Nothing in the repository was changed.", '']
    L += ['| | |', '|---|---|', f"| Product | {esc(nt['display'])} |", f"| Kind | {nt['kind']} |", f"| Visibility | {nt['visibility']} |",
          f"| Engine / language | {esc(nt['engine'])} |", f"| GitHub default branch | `{d['default_branch']}` @ `{d['default_head']}` (moving) |",
          f"| Most recent branch | `{d['latest_branch']}` |", f"| Last commit on any branch | {last} |", f"| Status | {st} (active = a commit within 14 days of {SCAN_DAY}) |",
          f"| Links | {GH}{repo} |", '']
    L += ['## Purpose', '', f"{nt['purpose']} (`{nt['purpose_src']}`)", '', '## Source of truth', '', nt['authoritative'], '']
    if nt.get('note'): L += [f"> {nt['note']}", '']
    if nt.get('extra') == 'mml': L += mml_section(d)
    if nt.get('extra') == 'climb': L += climb_section(d)
    L += ['## Branches', '', 'Branch heads move; the SHA is the head at scan time.', '', '| Branch | Head SHA | Last commit | Ahead / behind default | Role | Relation to reference line | Last subject |', '|---|---|---|---|---|---|---|']
    for b in d['branches']:
        r = cls[b['name']]
        L.append(f"| `{b['name']}` | `{b['sha']}` | {(b.get('committer_date') or '')[:10]} | {b.get('ahead_of_default')} / {b.get('behind_default')} | {r[0]} | {r[1]} | {esc(b.get('subject',''))[:90]} |")
    L += ['', f"Pull-request refs on the remote: {', '.join('#' + p for p in d['pull_refs']) or 'none'} (refs only; PR state not read).", '']
    L += ['## Tags and releases', '']
    rr = {x['tag']: x for x in rel.get(repo, [])}
    if repo in rel:
        L += ['Releases read with the GitHub API (this session\'s scope). Tags are immutable references unless moved; the commit is the peeled tag target.', '']
    else:
        L += ['Release details could not be read (the GitHub API refused: repository outside this session\'s scope). Tags from `git ls-remote --tags`; whether each tag has a GitHub Release is unknown.', '']
    if d['tags']:
        L += ['| Tag | Commit | Commit date | Release | Commit subject |', '|---|---|---|---|---|']
        for t in sorted(d['tags'], key=lambda t: (t.get('commit_date') or ''), reverse=True):
            x = rr.get(t['name'])
            r = f"{x['name']}{' (pre-release)' if x['prerelease'] else ''}, published {x['published_at'][:10]}" if x else ('no release found' if repo in rel else 'unknown')
            L.append(f"| `{t['name']}` | `{t['commit']}` | {(t.get('commit_date') or '')[:10]} | {esc(r)} | {esc(t.get('subject'))[:70]} |")
    else:
        L.append('No tags.')
    L.append('')
    L += ['## Asset manifests and licence records', '']
    L += [f"- `{p}`" for p in d['manifest_paths'][:40]] or ['- none found by name']
    if len(d['manifest_paths']) > 40: L.append(f"- ... {len(d['manifest_paths']) - 40} more (registry.json)")
    L.append('')
    rows, ref = important_images(d, repo)
    L += ['## Important artwork', '', f"Logos, icons, splash, branding and store-like images, and any image 512 px or larger, across every branch head ({len(d['images'])} distinct image path/blob pairs in total). Links pin the branch head SHA where the file was seen.", '']
    if rows:
        L += ['| Path | Size (px) | Bytes | Blob | Seen on | Link |', '|---|---|---|---|---|---|']
        shas = {b['name']: b['sha'] for b in d['branches']}
        for im in rows[:70]:
            br = ref if ref in im['branches'] else im['branches'][0]
            L.append(f"| `{im['path']}` | {dims(im)} | {im.get('bytes')} | `{im['blob'][:12]}` | {('`' + br + '`') + (f' +{len(im['branches'])-1}' if len(im['branches']) > 1 else '')} | [view]({blob(repo, shas[br], im['path'])}) |")
        if len(rows) > 70: L.append(f"| ... {len(rows) - 70} more in registry.json | | | | | |")
    else:
        L.append('None.')
    if d['other_art']:
        L += ['', f"Other art/source files (svg, psd, pdf, ...): {len(d['other_art'])}; first few: " + ', '.join(f"`{a['path']}`" for a in d['other_art'][:8])]
    L.append('')
    L += ['## Features and layout', '', f"Top level of `{ref}`:", '']
    tops = d['branch_top'].get(ref, {})
    L.append(', '.join(f"`{k}` ({v})" for k, v in tops.items()) or 'empty')
    if ref != d['default_branch']:
        L += ['', f"Top level of default `{d['default_branch']}`: " + ', '.join(f"`{k}` ({v})" for k, v in d['default_tree']['top'].items())]
    L.append('')
    L += ['## CI workflows', '', 'Path and trigger only; never changed or run.', '']
    wf = [(k, v) for k, v in d['docs'].items() if v['path'].startswith('.github/workflows/')]
    if wf:
        L += ['| Branch:path | Name | Trigger (`on:`) |', '|---|---|---|']
        for k, v in sorted(wf):
            L.append(f"| `{k}` | {esc(v.get('name'))} | {esc(v.get('on'))[:160]} |")
    else:
        L.append('None on the default or most recent branch.')
    L.append('')
    L += ['## Sensitive files (paths only; contents not read)', '']
    L += [f"- `{p}`" for p in d['secret_paths']] or ['- none matched']
    L.append('')
    # intra-repo duplicates
    bl = json.load(open(os.path.join(DATA, repo + '.blobs.json')))
    dup = sorted([(o, ps) for o, ps in bl.items() if len(ps) > 1 and o != 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391' and not all(p.endswith(('.import', '.uid', '.gitkeep')) for p in ps)], key=lambda x: -len(x[1]))
    L += ['## Unknowns and duplicates', '', f"Same blob under more than one path on some branch head: {len(dup)} blobs."]
    for o, ps in dup[:12]:
        L.append(f"- `{o[:12]}`: " + ', '.join(f"`{p}`" for p in ps[:4]) + (f' (+{len(ps)-4})' if len(ps) > 4 else ''))
    if d['default_branch'] != ref and d['default_tree']['files'] < 30:
        L.append(f"- The GitHub default branch `{d['default_branch']}` holds only {d['default_tree']['files']} files while work lives on `{ref}`; anyone cloning the default sees an upload snapshot, not the product.")
    L.append('')
    return '\n'.join(L)


def mml_section(d):
    clone = d['clone']; S = 'staging/my-medieval-life'; ssha = next(b['sha'] for b in d['branches'] if b['name'] == S)
    L = ['## Current development (My-Medieval-Life records)', '',
         f"- `staging/my-medieval-life` head at scan: `{ssha}` (moving). `main` head: `{d['default_head']}` (moving; owner-merge only).",
         '- Records read on staging at that SHA: `CLAUDE.md`, `docs/DEVELOPMENT_QUEUE.md`, `docs/HANDOFF.md`, `docs/release/BUILD_7_ISSUES.md`, `ASSET_MANIFEST.md`, `asset_manifest.csv`, `game/assets/PROVENANCE.json` (`mml-provenance/1`), `game/data/resources.json` (`mml-resources/1`), `docs/systems/RESOURCE_NODE_MANIFEST.md`, `docs/systems/RESOURCE_USAGE_REGISTRY.md`.',
         '- `docs/DEVELOPMENT_QUEUE.md`: "Build 7 is the testing release. No Build 8, no replacement release, no merge into `main` without the owner\'s explicit authorization." Item 10 is this registry ("Discovery only; nothing moved").',
         '- `docs/release/BUILD_7_ISSUES.md`: Release `build-7` (pre-release), source commit `679907121654c7630b170690752429b55a74b8ac`.', '',
         '### wip/agent-* snapshot branches', '', 'Each is a snapshot commit on top of agent work. "Head in staging" uses `git merge-base --is-ancestor`; a snapshot head is never an ancestor, so the parent is checked too. Content-level integration was not verified.', '',
         '| Branch | Head | Head in staging | Parent | Parent in staging | Diff vs staging merge-base |', '|---|---|---|---|---|---|']
    for b in d['branches']:
        if not b['name'].startswith('wip/'): continue
        _, p = git(clone, 'rev-parse', b['sha'] + '^')
        _, ds = git(clone, 'diff', '--shortstat', f'{ssha}...{b["sha"]}')
        L.append(f"| `{b['name']}` | `{b['sha']}` | {'yes' if anc(clone, b['sha'], ssha) else 'no'} | `{p}` | {'yes' if anc(clone, p, ssha) else 'no'} | {ds.strip()} |")
    L += ['', 'By the ancestry test no wip head is in staging, so none counts as integrated. Where the parent is in staging, only the snapshot of uncommitted work is outside it; where the parent is not (`wip/agent-a71e3cddb5b8d02d4`, `wip/agent-a892fc619ec33a8eb` at scan time), committed agent work is outside staging too. Whether any of it reached staging by another route (cherry-pick, re-implementation) is unresolved.', '']
    L += ['### Builds 1 to 7', '', '| Release | Tag commit | In staging | In main |', '|---|---|---|---|']
    for t in sorted(d['tags'], key=lambda t: t['name']):
        L.append(f"| `{t['name']}` | `{t['commit']}` | {'yes' if anc(clone, t['commit'], ssha) else 'no'} | {'yes' if anc(clone, t['commit'], d['default_head']) else 'no'} |")
    L += ['', 'Every build tag is contained in staging and none in `main`, consistent with CLAUDE.md section 5 ("An approved test build may come from an approved staging commit without merging into `main`").', '',
          '### Asset records', '',
          '- `ASSET_MANIFEST.md` / `asset_manifest.csv` (generated by `tools/build_manifest.py`): every file in every source archive with size, SHA-256 and image dimensions. Licence labels: paid / CC0 / CC BY 4.0 / free / verify.',
          '- Labelled `verify` (licence unresolved in the repo\'s own records): `Character-Customizer.zip`, `My_Medieval_Life_Icon_Pack.zip` (the game\'s app icon, 48 to 1024 px), `PUNY_WORLD_v1.zip`, `Flat Game UI Icon Pack/`.',
          '- `ClimbUp_restore_backup.zip` is described in the manifest as "NOT an art pack: backup of a separate \'Climb up\' game-designer project (project.json + splash image)". Its splash member `studio_splash_e3d9bb56.png` (1536x1024, sha256 `e3d9bb56...`) is the Hot Attic Games master logo, the same file as Climb-Up\'s `branding/master/studio_splash_e3d9bb56.png`. It belongs to Climb-Up / Game-Designer, not this game: a consolidation candidate (proposal only).',
          '- `main` holds byte-identical duplicate uploads: `MiniWorldSprites.zip`, `MiniWorldSprites (1).zip`, `MiniWorldSprites (2).zip` (blob `25d808fffc66`), and `PUNY-WORLD-PAID_v1.zip`, `PUNY-WORLD-PAID_v1 (1).zip` (blob `fd6c1a26e133`). Staging keeps one copy of each.',
          '- `game/assets/PROVENANCE.json` (`mml-provenance/1`) records each imported file\'s source zip, member, transform and sha256; `game/data/resources.json` (`mml-resources/1`) is the one definition of resource nodes; `docs/systems/*.md` are generated from it.', '']
    return L


def climb_section(d):
    L = ['## Upwardly Steam artwork (priority search)', '',
         '**No Steam store or library capsule art was found** (no header 460x215, small 231x87, main 616x353 or 1232x706, vertical 374x448, library capsule 600x900, library hero 1920x620 / 3840x1240, or library logo). Searched: every branch head\'s tree, all images\' pixel sizes, and every path ever committed on any branch or tag (`git log --all --name-only`) for capsule/header/library/hero/store/promo/marketing/press/key art. `docs/windows/STEAM_PACKAGING.md` says "Nothing here has been uploaded to Steam ... no store page" (older text), while `HANDOFF.md` records Build 70 live on Steam on 15 October; the store art itself is not in the repository.', '',
         'What exists, all on `ccr-cb458cd1-w4dh5c` only (head `245307499a33725cd21f51116d860e2bea5221d6`):', '',
         '| Asset | Path | Size (px) | Bytes | Link |', '|---|---|---|---|---|']
    sha = '245307499a33725cd21f51116d860e2bea5221d6'
    for im in d['images']:
        if 'ccr-cb458cd1-w4dh5c' in im['branches'] and re.match(r'^branding/(steam/(icon|shortcut|linux)|logo/)|^branding/steam/achievements/(contact_sheet|export_check|revisions)', im['path']):
            L.append(f"| {'Achievement review sheet' if 'achievements' in im['path'] else ('Steam icon' if 'steam' in im['path'] else 'Logo')} | `{im['path']}` | {dims(im)} | {im.get('bytes')} | [view]({blob('Climb-Up', sha, im['path'])}) |")
    L += [f"| Achievement icons (54 PNG, 256x256, manifest.csv) | `branding/steam/achievements/icons/` | 256x256 | | [tree]({GH}Climb-Up/tree/{sha}/branding/steam/achievements/icons) |",
          f"| Achievement icon zip / PDF | `branding/steam/achievements/Upwardly_Steam_Achievement_Icons.zip`, `Upwardly_Steam_Achievements.pdf` | | | [tree]({GH}Climb-Up/tree/{sha}/branding/steam/achievements) |",
          f"| Steam docs | `docs/STEAMWORKS_SETUP.md`, `docs/STEAM_ACHIEVEMENTS_ENTRY_SHEET.md`, `docs/STEAM_DECK_TESTING.md`, `docs/windows/STEAM_PACKAGING.md`, `steam_appid.txt` | | | [docs]({GH}Climb-Up/tree/{sha}/docs) |", '',
         '`branding/steam/README.md`: design A "Sky Peek", "Chosen by the owner on 15 October 2026". The logo PNGs (`branding/logo/*`, up to 18100x3460, transparent, with SVG/PDF) are the likeliest source for a library logo, but no Steam-sized export exists.', '']
    return L


def readme(incl):
    L = ['# Hot Attic Games repository registry', '',
         'A read-only inventory of every repository owned by GitHub user `verbal76` (Hot Attic Games). It lives on the orphan branch `inventory/registry` of `verbal76/My-Medieval-Life` and contains no game files. Nothing in any repository was changed to build it.', '',
         '## How to use it', '', '- This table: one line per repository. `repos/<repo>.md`: purpose, branches, tags/releases, manifests, artwork, layout, CI, sensitive paths (names only), duplicates.',
         '- `assets.md`: cross-repo artwork index (Upwardly Steam art first). `releases.md`: releases and their source commits. `findings.md`: duplicates, stale branches, conflicting sources of truth, consolidation proposals.',
         '- `registry.json` (`hag-registry/1`): machine-readable; every entry has repo, branch, path, SHA and scan date.', '',
         '## Legend', '', '- **Branch head SHA**: where a moving branch pointed at scan time; re-check with `git ls-remote` before relying on it. **Tag commit**: immutable unless the tag is moved.',
         '- **Authoritative**: only when the repo\'s own records say so (README, CLAUDE.md, ledger, manifest); otherwise **unresolved**.',
         '- **Status**: active = a commit on any branch within 14 days of the scan; dormant = older; unknown = not scanned.',
         '- **Visibility**: as given by the owner; "not stated" repos were read through the session git proxy, which may carry credentials, so they may be private.', '',
         f'## Scans', '', f'All scans on {SCAN_DAY} (UTC). Per-repo timestamps are in each `repos/*.md` and in `registry.json`.', '',
         '## Repositories', '', '| Repository | Product | Visibility | Default branch @ head (moving) | Last commit | Engine / language | Status | Authoritative line (per records) |', '|---|---|---|---|---|---|---|---|']
    for repo in notes['order']:
        nt = notes['repos'][repo]
        if repo not in incl:
            continue
        if nt.get('skip'):
            L.append(f"| [{repo}](repos/{repo}.md) | (not recorded) | {nt['visibility']} | not read | | | not scanned (owner rule) | |"); continue
        d = load(repo); st, last = status_of(d)
        L.append(f"| [{repo}](repos/{repo}.md) | {esc(nt['display'])} | {nt['visibility']} | `{d['default_branch']}` @ `{d['default_head'][:12]}` | {last} | {esc(nt['engine'])} | {st} | {('`' + AUTH[repo] + '`') if repo in AUTH else 'unresolved'} |")
    pending = [r for r in notes['order'] if r not in incl]
    if pending: L += ['', 'Not yet scanned in this registry version: ' + ', '.join(pending)]
    L.append('')
    return '\n'.join(L)


def assets(incl):
    L = ['# Cross-repo artwork index', '', 'Links pin a branch head SHA at scan time. Sizes read from the image headers.', '']
    if 'Climb-Up' in incl:
        d = load('Climb-Up')
        L += climb_section(d)[0:2] + climb_section(d)[2:]
    L += ['## Hot Attic Games studio logo', '', 'Blob `e11f8c576652b82780967a02ee4b4acd12e8a3c8` (1536x1024 PNG, 2,838,266 bytes; owner-supplied `Hot_Attic_Games_Master_Logo_ALPHA_FINAL.png`; several repos\' CLAUDE.md call it "canonical"). Same bytes in:', '']
    idx = blobs_index(incl)
    for r, ps in sorted(idx.get('e11f8c576652b82780967a02ee4b4acd12e8a3c8', {}).items()):
        L.append(f"- {r}: " + ', '.join(f'`{p}`' for p in ps))
    L += ['', '## Per-repository key art', '', 'App icons, logos, splash screens, branding and large images (512 px or more). Full lists in each `repos/*.md`.', '']
    for repo in notes['order']:
        if repo not in incl or notes['repos'][repo].get('skip'): continue
        d = load(repo); rows, ref = important_images(d, repo)
        rows = [im for im in rows if re.search(r'(?i)logo|icon|splash|brand|steam|store|banner|cover|title|master|playstore', im['path'])]
        if not rows: continue
        shas = {b['name']: b['sha'] for b in d['branches']}
        L += [f"### {repo}", '', '| Path | Size | Seen on | Link |', '|---|---|---|---|']
        seen = set()
        for im in rows[:25]:
            if im['path'] in seen: continue
            seen.add(im['path']); br = ref if ref in im['branches'] else im['branches'][0]
            L.append(f"| `{im['path']}` | {dims(im)} | `{br}` | [view]({blob(repo, shas[br], im['path'])}) |")
        L.append('')
    return '\n'.join(L)


def releases(incl):
    L = ['# Releases and source revisions', '', 'Releases for My-Medieval-Life, voiceforge, spiroglyphics, personal-assistant- and web_auditor were read with the GitHub API. For the other repositories the API refused (outside this session\'s scope), so only tags are listed; whether a GitHub Release exists for each tag is unknown.', '']
    for repo in notes['order']:
        if repo not in incl or notes['repos'][repo].get('skip'): continue
        d = load(repo); tags = {t['name']: t for t in d['tags']}
        L += [f"## {repo}", '']
        if repo in rel:
            L += ['| Release | Tag | Source commit | Published | Pre-release |', '|---|---|---|---|---|']
            for x in rel[repo]:
                t = tags.get(x['tag'])
                L.append(f"| {esc(x['name'])} | `{x['tag']}` | `{t['commit'] if t else 'tag not found'}` | {x['published_at'][:10]} | {'yes' if x['prerelease'] else 'no'} |")
            extra = [t for t in d['tags'] if t['name'] not in {x['tag'] for x in rel[repo]}]
            if extra: L += ['', 'Tags without a release: ' + ', '.join(f"`{t['name']}` (`{t['commit'][:12]}`)" for t in extra)]
        elif d['tags']:
            by = collections.defaultdict(list)
            for t in d['tags']: by[t['commit']].append(t['name'])
            L += ['| Tags | Commit | Commit date |', '|---|---|---|']
            for c, ns in sorted(by.items(), key=lambda kv: tags[kv[1][0]].get('commit_date') or '', reverse=True):
                L.append(f"| {', '.join('`' + n + '`' for n in sorted(ns))} | `{c}` | {(tags[ns[0]].get('commit_date') or '')[:10]} |")
        else:
            L.append('No tags or releases.')
        L.append('')
    return '\n'.join(L)


def blobs_index(incl):
    idx = collections.defaultdict(dict)
    for repo in incl:
        f = os.path.join(DATA, repo + '.blobs.json')
        if not os.path.exists(f): continue
        for o, ps in json.load(open(f)).items(): idx[o][repo] = ps
    return idx


def findings(incl):
    idx = blobs_index(incl)
    L = ['# Findings', '', 'Observations only. Every item is a proposal; nothing was moved, merged, renamed or deleted.', '',
         '## Duplicated files across repositories (same git blob SHA)', '']
    cross = [(o, v) for o, v in idx.items() if len(v) > 1 and o != 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391']
    glyph = [x for x in cross if all('glyph' in p for ps in x[1].values() for p in ps)]
    other = [x for x in cross if x not in glyph]
    L += [f"- {len(cross)} blobs appear in two or more repositories.",
          f"- {len(glyph)} are controller/keyboard glyph PNGs (the same prompt icon pack copied under different names into up to 9 repos, e.g. blob `3bf4371d26e8` = Xbox A).",
          '- The studio logo blob `e11f8c576652` is in ' + str(len(idx.get('e11f8c576652b82780967a02ee4b4acd12e8a3c8', {}))) + ' repos (see assets.md).', '', '| Blob | Repositories and paths |', '|---|---|']
    for o, v in sorted(other, key=lambda x: (-len(x[1]), x[0]))[:60]:
        L.append(f"| `{o[:12]}` | " + '; '.join(f"{r}: `{ps[0]}`" + (f' (+{len(ps)-1})' if len(ps) > 1 else '') for r, ps in sorted(v.items())) + ' |')
    if len(other) > 60: L.append(f"| ... | {len(other) - 60} more |")
    L += ['', '## Possibly abandoned or stale branches', '', 'A branch is listed when it is not contained in the repository\'s reference line (authoritative per records, else the most recent branch) and its last commit is more than 5 days older than the newest branch. Not verified at content level: work may have been cherry-picked or squashed.', '']
    for repo in notes['order']:
        if repo not in incl or notes['repos'][repo].get('skip'): continue
        d = load(repo); cls = classify(repo, d)
        st = [(b, cls[b['name']]) for b in d['branches'] if 'possibly stale' in cls[b['name']][1]]
        if st:
            L.append(f"- **{repo}** (reference `{st[0][1][2]}`): " + ', '.join(f"`{b['name']}` ({b['committer_date'][:10]}, `{b['sha'][:12]}`)" for b, _ in st))
    L += ['', '## Conflicting or unresolved sources of truth', '',
          '- **Default branch is not the product line** in most repos: Climb-Up, Tartaria-RPG, Axolotl, Ocean-spore, Purgatory-Dungeon, Ragdoll-Rally, Endless-Escaspe, Idle-game, My-Personal-Crossow0rd, Zombie-squisher, LLM-Trainer, Cfm-calculator, Manual-J, voiceforge, spiroglyphics, Fix-Tremors and Game-Designer keep a small upload snapshot on `main` while work lives on `claude/*` or `ccr-*` branches. Purgatory-Dungeon\'s ledger says agent worktrees "are cut from the default branch", so agents start from the wrong code.',
          '- **Zombie-squisher**: docs/BRANCH_LEDGER.md names `ccr-27903f19-fy49jb` the authoritative line; README.md on the same branch calls `Github-build-pipeline-zombie-crusher` the "Primary working branch". The game name (Squisher vs Crusher) is an open owner decision.',
          '- **Tartaria-RPG**: HANDOFF.md says `golem-line` is the trunk and `HaL2001` is archived but the HAL product "is the live line"; `main` is a 12-file snapshot.',
          '- **Idle-game**: product name differs by branch ("Boarder" on `main`, "Where\'s the Bottom?" on the agent lines); the authoritative line is named in `authoritative.json`.',
          '- **Climb-Up / Upwardly**: the store-art location is unknown (not in any repo); `docs/windows/STEAM_PACKAGING.md` ("Nothing here has been uploaded to Steam") is outdated against HANDOFF.md (Build 70 live on Steam).',
          '- **My-Medieval-Life**: `wip/agent-a71e3cddb5b8d02d4` and `wip/agent-a892fc619ec33a8eb` have parents outside staging: unresolved whether integrated by content. CLAUDE.md says the formal engine entry in docs/DECISIONS.md is still *Proposed* while the Godot 4.7 prototype is in use. Four asset packs carry the `verify` licence label.',
          '- **Visibility**: only 8 repos had visibility given; the rest were readable through the session git proxy, which may carry credentials. Manual-J\'s CLAUDE.md says not to make the repo public; its actual visibility is unchecked.',
          '', '## Consolidation opportunities (proposals only)', '',
          '- One shared studio-assets source (studio logo, controller glyph pack, Kenney packs) instead of copies in up to 18 repos; repos would record the source and hash.',
          '- Make each repo\'s authoritative line its GitHub default branch (owner action), or record the authoritative branch in the README, so new agents and clones start from the right code.',
          '- Prune or archive agent session branches already contained in the authoritative line (listed as "contained in" in each repo file), after the owner reviews them.',
          '- Move `ClimbUp_restore_backup.zip` out of My-Medieval-Life to Climb-Up or Game-Designer, where it belongs (its manifest entry already says it is not an art pack).',
          '- Remove the byte-identical duplicate uploads on My-Medieval-Life `main` when the owner next merges staging (staging already has one copy).',
          '- Put the Upwardly Steam store and library art in `branding/steam/` on the authoritative line once located, beside the icons and achievements.',
          '- Give HotAtticGames.github.io real content (it holds only README.md), e.g. one page per product from this registry.', '']
    return '\n'.join(L)


def registry_json(incl):
    out = {'format': 'hag-registry/1', 'owner': 'verbal76', 'registry_branch': 'inventory/registry', 'scan_date': SCAN_DAY, 'repos': []}
    for repo in notes['order']:
        if repo not in incl: continue
        nt = notes['repos'][repo]
        if nt.get('skip'):
            out['repos'].append({'repo': repo, 'visibility': nt['visibility'], 'scanned': False, 'reason': nt['skip']}); continue
        d = load(repo); st, last = status_of(d); cls = classify(repo, d)
        shas = {b['name']: b['sha'] for b in d['branches']}
        e = {'repo': repo, 'url': GH + repo, 'visibility': nt['visibility'], 'scanned': True, 'scanned_at': d['scanned_at'], 'product': nt['display'], 'kind': nt['kind'],
             'engine': nt['engine'], 'status': st, 'last_commit': last, 'default_branch': d['default_branch'], 'default_head': d['default_head'],
             'authoritative_branch': AUTH.get(repo), 'authoritative_basis': nt['authoritative'], 'purpose': nt['purpose'], 'purpose_source': nt['purpose_src'],
             'branches': [{'repo': repo, 'branch': b['name'], 'sha': b['sha'], 'ref_kind': 'moving branch head', 'committer_date': b.get('committer_date'), 'role': cls[b['name']][0], 'relation': cls[b['name']][1], 'scan_date': d['scanned_at']} for b in d['branches']],
             'tags': [{'repo': repo, 'tag': t['name'], 'sha': t['commit'], 'tag_object': t['object'], 'ref_kind': 'tag', 'release': next((x for x in rel.get(repo, []) if x['tag'] == t['name']), None) if repo in rel else 'unreadable', 'scan_date': d['scanned_at']} for t in d['tags']],
             'images': [{'repo': repo, 'branch': (im['branches'][0]), 'sha': shas[im['branches'][0]], 'path': im['path'], 'blob': im['blob'], 'width': im['width'], 'height': im['height'], 'bytes': im['bytes'], 'branches': im['branches'], 'scan_date': d['scanned_at']} for im in d['images']],
             'manifests': d['manifest_paths'], 'sensitive_paths_names_only': d['secret_paths'],
             'workflows': [{'repo': repo, 'branch': v['branch'], 'sha': shas[v['branch']], 'path': v['path'], 'name': v.get('name'), 'on': v.get('on'), 'scan_date': d['scanned_at']} for v in d['docs'].values() if v['path'].startswith('.github/workflows/')],
             'steam_candidates': [{'repo': repo, 'path': c['path'], 'width': c['width'], 'height': c['height'], 'steam_size': c['steam_size'], 'branches': c['branches']} for c in d['steam_candidates']]}
        out['repos'].append(e)
    return out


os.makedirs(os.path.join(OUT, 'repos'), exist_ok=True)
for repo in INCL:
    open(os.path.join(OUT, 'repos', repo + '.md'), 'w').write(repo_md(repo))
open(os.path.join(OUT, 'README.md'), 'w').write(readme(INCL))
open(os.path.join(OUT, 'assets.md'), 'w').write(assets(INCL))
open(os.path.join(OUT, 'releases.md'), 'w').write(releases(INCL))
open(os.path.join(OUT, 'findings.md'), 'w').write(findings(INCL))
json.dump(registry_json(INCL), open(os.path.join(OUT, 'registry.json'), 'w'), indent=1, ensure_ascii=False)
print('rendered', len(INCL))
