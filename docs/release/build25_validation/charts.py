"""Inline SVG line charts for the Build 25 report (theme colors come from CSS classes)."""
import math
def nice(v):
    if v <= 0: return 1
    e = 10 ** math.floor(math.log10(v)); f = v / e
    return (1 if f <= 1 else 2 if f <= 2 else 5 if f <= 5 else 10) * e
def line_chart(series, title, ylabel, ymax=None, w=640, h=250, pct=False):
    """series: [(label, cls, [(x, y), ...], dashed)]"""
    L, R, T, B = 56, 12, 14, 34
    xs = [p[0] for s in series for p in s[2]]; ys = [p[1] for s in series for p in s[2] if p[1] is not None]
    xmax = max(xs) if xs else 1
    top = ymax if ymax is not None else max(ys) if ys else 1
    step = nice(top / 4); top = step * math.ceil(top / step) if ymax is None else ymax
    sx = lambda x: L + (w - L - R) * x / xmax
    sy = lambda y: T + (h - T - B) * (1 - y / top)
    o = [f'<svg viewBox="0 0 {w} {h}" role="img" aria-label="{title}" class="chart">']
    t = 0
    while t <= top + 1e-9:
        y = sy(t)
        o.append(f'<line x1="{L}" x2="{w-R}" y1="{y:.1f}" y2="{y:.1f}" class="grid"/>')
        lab = f"{int(t)}%" if pct else (f"{int(t):,}")
        o.append(f'<text x="{L-6}" y="{y+4:.1f}" class="tick" text-anchor="end">{lab}</text>')
        t += step if ymax is None else (ymax / 4)
    for xv in range(0, int(xmax) + 1, 60):
        x = sx(xv)
        o.append(f'<line x1="{x:.1f}" x2="{x:.1f}" y1="{h-B}" y2="{h-B+4}" class="axis"/>')
        o.append(f'<text x="{x:.1f}" y="{h-B+17}" class="tick" text-anchor="middle">{xv}</text>')
    o.append(f'<line x1="{L}" x2="{w-R}" y1="{h-B}" y2="{h-B}" class="axis"/>')
    o.append(f'<text x="{(L+w-R)/2:.0f}" y="{h-2}" class="tick" text-anchor="middle">game day</text>')
    for label, cls, pts, dashed in series:
        pts = [(x, y) for x, y in pts if y is not None]
        if not pts: continue
        d = " ".join(("M" if i == 0 else "L") + f"{sx(x):.1f},{sy(y):.1f}" for i, (x, y) in enumerate(pts))
        o.append(f'<path d="{d}" class="ln {cls}{" dash" if dashed else ""}" fill="none"/>')
        x, y = pts[-1]
        o.append(f'<circle cx="{sx(x):.1f}" cy="{sy(y):.1f}" r="3" class="pt {cls}"/>')
    o.append('</svg>')
    leg = "".join(f'<span class="key"><i class="sw {cls}{" dash" if dashed else ""}"></i>{label}</span>' for label, cls, pts, dashed in series)
    return f'<figure class="fig"><figcaption><b>{title}</b><span class="unit">{ylabel}</span></figcaption>{"".join(o)}<div class="legend">{leg}</div></figure>'
