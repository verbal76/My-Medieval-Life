"""Agent I (B42): starvation victim trace from a flight-recorder archive session plus the nearest segment state.
usage: python3 -I trace.py SESSION_DIR STATE_FILE VICTIM_ID DEATH_DAY LABEL   (standard library only)"""
import sys,json,gzip,glob,os,collections,re
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import stateworld
sess,state,pid,dday,label=sys.argv[1],sys.argv[2],sys.argv[3],int(sys.argv[4]),sys.argv[5]
num=int(pid.split(':')[1])
out=[];P=out.append
P('### %s %s (died day %d)'%(label,pid,dday))
ev=[];sm=[]
for d in range(dday-2,dday+1):
    dd=os.path.join(sess,'d%04d'%d)
    for f in sorted(glob.glob(dd+'/event.*.gz')):
        for l in gzip.open(f,'rt'):
            if pid in l and not l.startswith('{'):
                r=json.loads(l)
                if r[14]==pid and r[10]!='judgment': ev.append(r)
    for f in sorted(glob.glob(dd+'/sample.*.gz')):
        for l in gzip.open(f,'rt'):
            if pid in l and not l.startswith('{'):
                r=json.loads(l)
                if r[3]==pid: sm.append(r)
ev.sort(key=lambda r:r[0]); sm.sort(key=lambda r:r[0])
w=stateworld.world(state); b=None; hh=[]
n=[x for x in w['npcs'] if int(x.get('id',-1))==num]; n=n[0] if n else None
P('- state file day %d: %s'%(int(w['minutes']//1440),'victim record: home=%r household=%r job=%r role=%r alive=%r pos=%s'%(n.get('home'),n.get('household'),n.get('job'),n.get('role'),n.get('alive'),[round(v,1) for v in n.get('pos',[])]) if n else 'victim not in npcs (born after the save)'))
hid=n.get('household') if n else None
if hid is None:
    for r in ev:
        m=re.search(r'household=(\d+)',r[18]) if r[13]=='death' else None
        if m: hid=int(m.group(1)); P('- household from the death record: %d'%hid)
hh=[h for h in w['households'] if h.get('id')==hid]
if hh:
    h=hh[0]; home=h.get('home','')
    b=w['buildings'].get(home) if home else None
    P('- household %s (%s): home=%r members=%s; home building: %s'%(hid,h.get('family'),home,h.get('members'),
      ('exists type=%s name=%r door=%s owner=%s'%(b.get('type'),b.get('name'),b.get('door'),b.get('owner'))) if b else 'NOT in buildings'))
else:
    P('- household %r not found in state'%hid)
claims=w.get('homesteads',{}).get('claims',[])
P('- homestead claim membership: %s'%([(c['id'],c.get('faction')) for c in claims if num in c.get('members',[])] or 'none'))
fails=[r for r in ev if r[13]=='walk_lost']
P('- failed walks in last 2 days: %d, reasons %s; cells %s'%(len(fails),dict(collections.Counter(r[16] for r in fails)),dict(collections.Counter('(%d,%d)'%(r[8],r[9]) for r in fails))))
door=b.get('door') if b else None
if door and fails:
    for c in sorted(set((r[8],r[9]) for r in fails)):
        bx=max(c[0],door[0])-min(c[0],door[0])+21; by=max(c[1],door[1])-min(c[1],door[1])+21
        P('- presumed eat_home target = home door %s (go targets are not recorded); world-path box from %s: %dx%d (WORLD_PATH_CELLS 140: %s)'%(door,c,bx,by,'REFUSED' if max(bx,by)>140 else 'within limit'))
P('- plans chosen: %s'%dict(collections.Counter(r[18] for r in ev if r[13]=='plan_next').most_common(8)))
other=[r for r in ev if r[13] not in ('walk_lost','plan_next','mj_step','church_pickup')]
P('- other events: '+'; '.join('d%d %04.0f %s %s %s'%(r[5],r[6],r[13],r[16],r[18][:60]) for r in other[:25]))
per=collections.Counter((r[5],int(r[6]//60)) for r in ev if r[13]=='plan_next')
P('- hourly (cell, doing, hunger, hp, coins, decisions that hour):')
for s in sm:
    P('  - d%d %02d: (%d,%d) %s; hunger %.1f hp %.1f coins %d; decisions %d'%(s[1],s[2],s[6],s[7],s[8],s[4],s[5],s[9],per.get((s[1],s[2]),0)))
P('')
print('\n'.join(out))
