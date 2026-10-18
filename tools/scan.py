"""Read-only scanner for one blobless clone. Usage: python3 -I scan.py <clone_dir> <repo> <out.json>

Never writes to the remote. Only fetches missing blobs (images, key docs) into the local blobless clone.
"""
import json, os, re, struct, subprocess, sys, datetime

SECRET_RE = re.compile(r'(^|/)(\.env(\..*)?|.*\.(keystore|jks|pem|p12|pfx|key|mobileprovision|p8)|credentials.*|secrets?\..*|google-services\.json|service[-_]account.*\.json|id_rsa.*|.*\.keystore\.b64)$', re.I)
IMG_RE = re.compile(r'\.(png|jpe?g|webp|gif|bmp|ico)$', re.I)
ART_RE = re.compile(r'\.(png|jpe?g|webp|gif|bmp|ico|svg|psd|ai|kra|aseprite|ase|xcf|tga|pdf)$', re.I)
KW_RE = re.compile(r'upwardly|steam|capsule|header|library_|librar(y|ies)[-_ ]?(hero|logo|capsule)|store|promo|marketing|press|key[-_ ]?art|banner|feature[-_]?graphic|screenshot|logo|branding|splash|icon|cover|trailer', re.I)
STEAM_KW = re.compile(r'upwardly|steam|capsule|header|library|hero|store|promo|marketing|press|key[-_ ]?art', re.I)
STEAM_SIZES = {(460, 215): 'header capsule', (616, 353): 'small/main capsule', (231, 87): 'small capsule',
               (374, 448): 'vertical capsule', (3840, 1240): 'library hero 2x', (1920, 620): 'library hero',
               (600, 900): 'library capsule', (1232, 706): 'main capsule 2x', (1280, 720): 'library logo/screenshot?',
               (920, 430): 'header capsule 2x', (462, 174): 'small capsule 2x', (748, 896): 'vertical capsule 2x',
               (1200, 1800): 'library capsule 2x', (1280, 640): 'library logo?', (184, 184): 'community icon',
               (32, 32): None}
DOC_NAMES = ['README.md', 'README', 'readme.md', 'CLAUDE.md', 'HANDOFF.md', 'docs/HANDOFF.md', 'ASSETS.md', 'ASSET_MANIFEST.md',
             'docs/BRANCH_LEDGER.md', 'docs/RELEASES.md', 'RELEASES.md', 'CHANGELOG.md', 'docs/DECISIONS.md', 'MASTER_PROMPT.md',
             'docs/DEVELOPMENT_QUEUE.md', 'docs/release/BUILD_7_ISSUES.md', 'docs/THIRD_PARTY_ASSETS.md', 'CREDITS.md', 'LICENSE', 'package.json',
             'project.godot', 'game/project.godot', 'build.gradle', 'app/build.gradle', 'pubspec.yaml', 'Cargo.toml', 'pyproject.toml', 'requirements.txt']


def git(d, *args, check=True, binary=False):
    r = subprocess.run(['git', '-C', d, *args], capture_output=True)
    if check and r.returncode:
        raise RuntimeError(f'git {args}: {r.stderr.decode(errors="replace")}')
    return r.stdout if binary else r.stdout.decode('utf-8', errors='replace')


def dims(data):
    try:
        if data[:8] == b'\x89PNG\r\n\x1a\n':
            w, h = struct.unpack('>II', data[16:24]); return w, h, 'png'
        if data[:6] in (b'GIF87a', b'GIF89a'):
            w, h = struct.unpack('<HH', data[6:10]); return w, h, 'gif'
        if data[:2] == b'BM':
            w, h = struct.unpack('<ii', data[18:26]); return w, abs(h), 'bmp'
        if data[:4] == b'RIFF' and data[8:12] == b'WEBP':
            c = data[12:16]
            if c == b'VP8 ':
                w, h = struct.unpack('<HH', data[26:30]); return w & 0x3fff, h & 0x3fff, 'webp'
            if c == b'VP8L':
                b = data[21:25]; v = int.from_bytes(b, 'little'); return (v & 0x3fff) + 1, ((v >> 14) & 0x3fff) + 1, 'webp'
            if c == b'VP8X':
                return int.from_bytes(data[24:27], 'little') + 1, int.from_bytes(data[27:30], 'little') + 1, 'webp'
        if data[:4] == b'\x00\x00\x01\x00':
            n = struct.unpack('<H', data[4:6])[0]; best = (0, 0)
            for i in range(n):
                e = data[6 + 16 * i: 22 + 16 * i]; w = e[0] or 256; h = e[1] or 256
                best = max(best, (w, h))
            return best[0], best[1], f'ico({n})'
        if data[:2] == b'\xff\xd8':
            i = 2
            while i < len(data) - 9:
                if data[i] != 0xFF: i += 1; continue
                m = data[i + 1]
                if m in (0xD8, 0x01) or 0xD0 <= m <= 0xD7: i += 2; continue
                L = struct.unpack('>H', data[i + 2:i + 4])[0]
                if m in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                    h, w = struct.unpack('>HH', data[i + 5:i + 9]); return w, h, 'jpeg'
                i += 2 + L
    except Exception:
        pass
    return None, None, 'unknown'


def prefetch(d, oids):
    oids = sorted(set(oids))
    for i in range(0, len(oids), 150):
        subprocess.run(['git', '-C', d, '-c', 'fetch.negotiationAlgorithm=noop', 'fetch', '-q', '--no-tags', '--no-write-fetch-head',
                        '--filter=blob:none', 'origin', *oids[i:i + 150]], capture_output=True)


def main():
    d, repo, out = sys.argv[1], sys.argv[2], sys.argv[3]
    now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    ls = git(d, 'ls-remote', 'origin')
    remote = {}
    for line in ls.splitlines():
        sha, ref = line.split('\t'); remote[ref] = sha
    # refresh local view if the remote moved
    heads = {r[len('refs/heads/'):]: s for r, s in remote.items() if r.startswith('refs/heads/')}
    stale = [b for b, s in heads.items() if git(d, 'rev-parse', '-q', '--verify', f'refs/remotes/origin/{b}^{{commit}}', check=False).strip() != s]
    if stale:
        git(d, 'fetch', '-q', '--prune', '--tags', 'origin', check=False)
    head_ref = remote.get('HEAD')
    default = git(d, 'symbolic-ref', '-q', 'refs/remotes/origin/HEAD', check=False).strip().replace('refs/remotes/origin/', '') or 'main'
    for b, s in heads.items():
        if s == head_ref and b == default:
            break
    branches = []
    dref = f'refs/remotes/origin/{default}'
    for b, s in sorted(heads.items()):
        info = git(d, 'log', '-1', '--format=%cI%x00%aI%x00%an%x00%s', s, check=False).split('\x00')
        if len(info) < 4:
            branches.append({'name': b, 'sha': s, 'error': 'commit not available locally'}); continue
        anc = subprocess.run(['git', '-C', d, 'merge-base', '--is-ancestor', s, dref]).returncode == 0
        lr = git(d, 'rev-list', '--left-right', '--count', f'{dref}...{s}', check=False).split()
        branches.append({'name': b, 'sha': s, 'committer_date': info[0], 'author_date': info[1], 'author': info[2],
                         'subject': info[3].strip(), 'ancestor_of_default': anc,
                         'behind_default': int(lr[0]) if lr else None, 'ahead_of_default': int(lr[1]) if lr else None})
    tags = []
    for r, s in sorted(remote.items()):
        if r.startswith('refs/tags/') and not r.endswith('^{}'):
            peeled = remote.get(r + '^{}', s)
            info = git(d, 'log', '-1', '--format=%cI%x00%s', peeled, check=False).split('\x00')
            tags.append({'name': r[10:], 'object': s, 'commit': peeled, 'annotated': r + '^{}' in remote,
                         'commit_date': info[0] if len(info) > 1 else None, 'subject': info[1].strip() if len(info) > 1 else None})
    pulls = sorted({r.split('/')[2] for r in remote if r.startswith('refs/pull/')}, key=lambda x: int(x) if x.isdigit() else 0)
    # trees of every branch head
    trees = {}
    for b in branches:
        if 'error' in b: continue
        entries = []
        for line in git(d, 'ls-tree', '-r', '--full-tree', b['sha']).splitlines():
            meta, path = line.split('\t', 1)
            mode, typ, oid = meta.split()
            entries.append((path, oid, typ, mode))
        trees[b['name']] = entries
    dtree = trees.get(default, [])
    files_default = [p for p, o, t, m in dtree if t == 'blob']
    top = {}
    for p in files_default:
        k = p.split('/')[0] + ('/' if '/' in p else '')
        top[k] = top.get(k, 0) + 1
    branch_top = {}
    for bname, entries in trees.items():
        tp = {}
        for p, o, t, m in entries:
            if t == 'blob':
                k = p.split('/')[0] + ('/' if '/' in p else ''); tp[k] = tp.get(k, 0) + 1
        branch_top[bname] = tp
    # union index of path/blob across branches
    union = {}
    for b, entries in trees.items():
        for p, o, t, m in entries:
            if t != 'blob': continue
            union.setdefault((p, o), []).append(b)
    blob_index = {}
    for (p, o), bs in union.items():
        blob_index.setdefault(o, set()).add(p)
    # prefetch images + key docs + workflows
    want = [o for (p, o) in union if IMG_RE.search(p)]
    docs_wanted = {}
    dated = [b for b in branches if 'error' not in b]
    latest = max(dated, key=lambda b: b['committer_date'])['name'] if dated else default
    for bname in ([default, latest] if latest != default else [default]):
        for p, o, t, m in trees.get(bname, []):
            if t == 'blob' and (p in DOC_NAMES or p.startswith('.github/workflows/') or re.search(r'(?i)(manifest|provenance)[^/]*\.(md|json|csv|txt)$', p)):
                docs_wanted[(bname, p)] = o
    prefetch(d, want + list(docs_wanted.values()))
    sizes = {}
    allo = sorted(set(want) | set(docs_wanted.values()))
    if allo:
        r = subprocess.run(['git', '-C', d, 'cat-file', '--batch-check=%(objectname) %(objectsize)'], input='\n'.join(allo).encode(), capture_output=True)
        for line in r.stdout.decode().splitlines():
            parts = line.split()
            if len(parts) == 2 and parts[1].isdigit(): sizes[parts[0]] = int(parts[1])
    images = []
    for (p, o), bs in sorted(union.items()):
        if not IMG_RE.search(p): continue
        data = git(d, 'cat-file', 'blob', o, binary=True, check=False)[:65536]
        w, h, fmt = dims(data)
        images.append({'path': p, 'blob': o, 'bytes': sizes.get(o), 'width': w, 'height': h, 'format': fmt,
                       'branches': sorted(bs), 'on_default': default in bs})
    other_art = [{'path': p, 'blob': o, 'branches': sorted(bs)} for (p, o), bs in sorted(union.items()) if ART_RE.search(p) and not IMG_RE.search(p)]
    docs = {}
    for (bname, p), o in docs_wanted.items():
        txt = git(d, 'cat-file', 'blob', o, check=False)
        k = f'{bname}:{p}'
        docs[k] = {'branch': bname, 'path': p, 'blob': o, 'bytes': sizes.get(o), 'head': txt[:6000] if not p.startswith('.github/workflows/') else None}
        if p.startswith('.github/workflows/'):
            m = re.search(r'(?ms)^(on|"on"|\'on\'|true):\s*(.*?)(?=^\S)', txt)
            docs[k]['on'] = (m.group(2).strip() if m else '')[:600]
            nm = re.search(r'(?m)^name:\s*(.+)$', txt)
            docs[k]['name'] = nm.group(1).strip() if nm else None
    kw_paths = sorted({p for (p, o) in union if KW_RE.search(p)})
    secrets = sorted({p for (p, o) in union if SECRET_RE.search(p)})
    manifests = sorted({p for (p, o) in union if re.search(r'(?i)(manifest|provenance|third_party|licen[cs]e|credits|assets\.md)', p.split('/')[-1])})
    lfs = [p for p, o, t, m in dtree if p == '.gitattributes']
    steam_candidates = []
    for im in images:
        tag = STEAM_SIZES.get((im['width'], im['height']))
        if tag or STEAM_KW.search(im['path']):
            steam_candidates.append(dict(im, steam_size=tag))
    res = {'repo': repo, 'scanned_at': now, 'clone': d, 'default_branch': default, 'default_head': heads.get(default),
           'remote_HEAD': head_ref, 'latest_branch': latest, 'branches': branches, 'tags': tags, 'pull_refs': pulls,
           'default_tree': {'files': len(files_default), 'top': dict(sorted(top.items()))}, 'branch_top': branch_top,
           'docs': docs, 'images': images, 'other_art': other_art, 'keyword_paths': kw_paths, 'secret_paths': secrets,
           'manifest_paths': manifests, 'steam_candidates': steam_candidates,
           'gitattributes': bool(lfs)}
    json.dump(res, open(out, 'w'), indent=1)
    json.dump({o: sorted(ps) for o, ps in blob_index.items()}, open(out.replace('.json', '.blobs.json'), 'w'))
    print(repo, 'branches', len(branches), 'tags', len(tags), 'files', len(files_default), 'images', len(images), 'steam?', len(steam_candidates))


main()
