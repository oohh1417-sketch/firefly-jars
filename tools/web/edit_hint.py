import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
def rep(old, new, cnt=1):
    global s
    c = s.count(old)
    if c != cnt:
        print("COUNT", c, "expected", cnt, "for:", old[:120]); sys.exit(1)
    s = s.replace(old, new)

# a hint always comes from a real route to the finish: the shortest one, else a quick near-shortest one
rep('''  const p = (movesMax ? shortestPath(S, 20000) : null) || solve(S);   // with a move limit, prefer the shortest route''',
    '''  const p = shortestPath(S, 20000) || shortestPath(S, 40000, 3) || solve(S);   // shortest route first, then a quick near-shortest one''')
# the fireflies that should move glow and bob; the jar they go into glows gold, with a little arrow above it
rep('''  if (isHint) line = `rgba(255,255,255,${.45 + .55 * Math.abs(Math.sin(now / 250))})`;''',
    '''  if (isHint && hint[1] === i) { const pu = Math.abs(Math.sin(now / 250)); line = `rgba(255,217,59,${.55 + .45 * pu})`; glow(g, r.x + r.w / 2, r.y + r.h * .5, r.h * .75, "#ffd93b", .16 + .14 * pu); }''')
rep('''  flies.forEach((list, i) => wob(i, () => list.forEach(f => {
    const moving = f.speed > 25; f.flap += moving ? .9 : .12;
    paintFly(ctx, f.x, f.y, R, f.c, f.flap, !(S.locks[i] > 0) || !!f.arc, moving, f.id);''',
'''  const hn = hint ? Math.min(topRun(S.jars[hint[0]]), CAP - S.jars[hint[1]].length) : 0;
  flies.forEach((list, i) => wob(i, () => list.forEach((f, k) => {
    const moving = f.speed > 25; f.flap += moving ? .9 : .12;
    const lit = hint && i === hint[0] && k >= list.length - hn && !f.arc, bob = lit ? -R * .25 * Math.abs(Math.sin(now / 300)) : 0;
    if (lit) { glow(ctx, f.x, f.y + bob, R * 3.2, "#fff3a0", .55 + .25 * Math.sin(now / 200)); f.flap += .6; }
    paintFly(ctx, f.x, f.y + bob, R, f.c, f.flap, !(S.locks[i] > 0) || !!f.arc || lit, moving || lit, f.id);''')
rep('''  const xi = extraIdx(); if (xi >= 0 && rects[xi]) paintCracked(''', '''  if (hint && rects[hint[1]]) { const r = rects[hint[1]], ax = r.x + r.w / 2, ay = r.y - R * .9 - R * .35 * Math.abs(Math.sin(now / 250));
    ctx.fillStyle = "#ffd93b"; ctx.strokeStyle = "rgba(60,35,0,.6)"; ctx.lineWidth = 2; ctx.beginPath();
    ctx.moveTo(ax - R * .55, ay - R * .5); ctx.lineTo(ax + R * .55, ay - R * .5); ctx.lineTo(ax, ay + R * .2); ctx.closePath(); ctx.fill(); ctx.stroke(); }
  const xi = extraIdx(); if (xi >= 0 && rects[xi]) paintCracked(''')
rep('''say("Pour the glowing jar into the other one");''', '''say("Move the glowing fireflies into the gold jar");''')
# the hint message sits under the moves pill instead of on top of it
rep('''  position: absolute; left: 50%; top: 70px; transform: translateX(-50%); z-index: 3; pointer-events: none;''',
    '''  position: absolute; left: 50%; top: 96px; transform: translateX(-50%); z-index: 3; pointer-events: none; font-size: 14px !important; padding-block: 5px !important; line-height: 1.25;''')
open(p, "w", encoding="utf-8").write(s)
print("hint ok")

# ---- a nicer crown: curved points with little glowing orbs, a band with gems, soft gold shading ----
s = open(p, encoding="utf-8").read()
rep('''function lockIcon(g, x, y, s, col) {''', '''// The Extreme crown. w = width; (x, y) = its middle. detail = false for the tiny map crowns.
function drawCrown(g, x, y, w, detail = true) {
  const h = w * .7, b = y + h * .5, bh = h * .26, tipY = [-.5, -.32, -.5].map(v => y + h * v);
  const pts = [[x - w * .5, tipY[1]], [x, tipY[0] - h * .04], [x + w * .5, tipY[1]]];
  g.save();
  // body: three soft points joined by curved valleys, sitting on a band
  g.beginPath(); g.moveTo(x - w * .46, b - bh);
  g.lineTo(pts[0][0] + w * .02, pts[0][1]);
  g.quadraticCurveTo(x - w * .3, y + h * .02, x - w * .22, y + h * .04);
  g.lineTo(pts[1][0], pts[1][1]);
  g.lineTo(x + w * .22, y + h * .04);
  g.quadraticCurveTo(x + w * .3, y + h * .02, pts[2][0] - w * .02, pts[2][1]);
  g.lineTo(x + w * .46, b - bh); g.closePath();
  const gr = g.createLinearGradient(0, y - h * .5, 0, b);
  gr.addColorStop(0, "#fff2a8"); gr.addColorStop(.45, "#ffcf3a"); gr.addColorStop(1, "#e0901f");
  g.fillStyle = gr; g.fill(); g.strokeStyle = "rgba(110,50,0,.65)"; g.lineWidth = Math.max(1.2, w * .022); g.lineJoin = "round"; g.stroke();
  // the band
  roundRect(g, x - w * .5, b - bh, w, bh, bh * .35, bh * .35);
  const bg = g.createLinearGradient(0, b - bh, 0, b); bg.addColorStop(0, "#ffd75a"); bg.addColorStop(1, "#c7761a");
  g.fillStyle = bg; g.fill(); g.stroke();
  // a little glowing orb on each point, like a firefly resting there
  for (const [px, py] of pts) { if (detail) glow(g, px, py, w * .16, "#fff3a0", .7); g.fillStyle = "#fff8d0"; g.beginPath(); g.arc(px, py, w * .055, 0, 6.283); g.fill(); g.stroke(); }
  if (detail) {
    // gems on the band, each with a tiny highlight
    for (const [dx, c] of [[-.28, "#ff4d6d"], [0, "#5cf2ff"], [.28, "#7dff6b"]]) {
      const gx = x + w * dx, gy = b - bh / 2; glow(g, gx, gy, w * .09, c, .5);
      g.fillStyle = c; g.beginPath(); g.ellipse(gx, gy, w * .05, bh * .3, 0, 0, 6.283); g.fill(); g.strokeStyle = "rgba(80,30,0,.5)"; g.lineWidth = 1; g.stroke();
      g.fillStyle = "rgba(255,255,255,.8)"; g.beginPath(); g.arc(gx - w * .015, gy - bh * .1, w * .014, 0, 6.283); g.fill(); }
    // a soft shine down the left side
    g.strokeStyle = "rgba(255,255,255,.55)"; g.lineWidth = w * .025; g.lineCap = "round";
    g.beginPath(); g.moveTo(x - w * .4, b - bh * 1.3); g.quadraticCurveTo(x - w * .4, y - h * .05, x - w * .44, y - h * .18); g.stroke();
  }
  g.restore();
}
function lockIcon(g, x, y, s, col) {''')
rep('''glow(g, cx, cy, 95, "#ff3b2e", .6); g.fillStyle = "#ffcf3a"; crownPath(g, cx, cy, 130); g.fill(); g.strokeStyle = "rgba(90,30,0,.7)"; g.lineWidth = 3; g.stroke();
    for (const [dx, c] of [[-40, "#ff3b2e"], [0, "#5cf2ff"], [40, "#7dff6b"]]) { g.fillStyle = c; g.beginPath(); g.arc(cx + dx * .9, cy + 16, 7, 0, 6.283); g.fill(); } }''',
    '''glow(g, cx, cy, 95, "#ff6a3a", .45); drawCrown(g, cx, cy + 4, 140); }''')
rep('''g.fillStyle = "#ffcf3a"; crownPath(g, x, y - 18, 20); g.fill(); }''', '''drawCrown(g, x, y - 18, 22, false); }''')
rep('''g.fillStyle = "#ffcf3a"; crownPath(g, p.x, p.y - r * 1.05, r * .8); g.fill(); g.strokeStyle = "rgba(90,30,0,.7)"; g.lineWidth = 1.5; g.stroke(); }''',
    '''drawCrown(g, p.x, p.y - r * 1.05, r * .85, false); }''')
open(p, "w", encoding="utf-8").write(s)
print("crown ok")

# ---- the menu jar's gold lid is a real round lid: its side curves along an oval, like a short cylinder ----
s = open(p, encoding="utf-8").read()
rep('''  g.fillStyle = lg; roundRect(g, -lid, -lh, lid, lh, lh * .22, lh * .22); g.fill();
  g.strokeStyle = "rgba(90,50,10,.55)"; g.lineWidth = Math.max(1, w * .008);
  for (let k = 1; k < 14; k++) { const lx = -lid + k * lid / 14; g.beginPath(); g.moveTo(lx, -lh * .78); g.lineTo(lx, -lh * .12); g.stroke(); }''',
'''  const ry = lh * .42;   // the same oval as the top of the lid
  g.fillStyle = lg; g.beginPath(); g.moveTo(-lid, -lh); g.lineTo(-lid, 0); g.ellipse(-lid / 2, 0, lid / 2, ry, 0, Math.PI, 0, true);
  g.lineTo(0, -lh); g.ellipse(-lid / 2, -lh, lid / 2, ry, 0, 0, Math.PI); g.closePath(); g.fill();
  g.strokeStyle = "rgba(110,60,12,.6)"; g.lineWidth = Math.max(1, w * .008); g.beginPath(); g.ellipse(-lid / 2, 0, lid / 2, ry, 0, .02, Math.PI - .02); g.stroke();
  // ridges around the side, closer together toward the edges as they turn away
  g.strokeStyle = "rgba(90,50,10,.55)";
  for (let k = 1; k < 18; k++) { const a = Math.PI - k * Math.PI / 18, lx = -lid / 2 + Math.cos(a) * lid / 2, dy = Math.sin(a) * ry;
    g.lineWidth = Math.max(.6, w * .008 * (.4 + .6 * Math.sin(a))); g.beginPath(); g.moveTo(lx, -lh * .78 + dy); g.lineTo(lx, -lh * .12 + dy); g.stroke(); }''')
open(p, "w", encoding="utf-8").write(s)
print("lid ok")

# ---- the closed cap on finished jars and the loading jar is round too: a short cylinder seen a little from above ----
s = open(p, encoding="utf-8").read()
rep('''  g.save(); g.globalAlpha = T.alpha;
  // the band, shaded like a metal cylinder
  const mg = g.createLinearGradient(x0, 0, x0 + cw, 0);
  mg.addColorStop(0, "#8a5d22"); mg.addColorStop(.18, "#d9a74e"); mg.addColorStop(.4, "#fbe7a6"); mg.addColorStop(.62, "#d6a24c"); mg.addColorStop(1, "#7a5220");
  g.fillStyle = mg; roundRect(g, x0, top, cw, bh, w * .05, w * .05); g.fill();
  g.save(); roundRect(g, x0, top, cw, bh, w * .05, w * .05); g.clip();''',
'''  g.save(); g.globalAlpha = T.alpha;
  const half = cw / 2, bend = w * .055, dy = x => { const t = Math.max(-1, Math.min(1, (x - cx) / half)); return bend * Math.sqrt(1 - t * t); };
  const band = () => { g.beginPath(); g.moveTo(x0, top); g.lineTo(x0, top + bh); g.ellipse(cx, top + bh, half, bend, 0, Math.PI, 0, true); g.lineTo(x0 + cw, top); g.ellipse(cx, top, half, bend, 0, 0, Math.PI); g.closePath(); };
  // the flat top of the lid
  g.fillStyle = "#b9843a"; g.beginPath(); g.ellipse(cx, top, half, bend, 0, 0, 6.283); g.fill();
  g.fillStyle = "#ecc675"; g.beginPath(); g.ellipse(cx, top + bend * .12, half * .86, bend * .78, 0, 0, 6.283); g.fill();
  // the band, shaded like a metal cylinder
  const mg = g.createLinearGradient(x0, 0, x0 + cw, 0);
  mg.addColorStop(0, "#8a5d22"); mg.addColorStop(.18, "#d9a74e"); mg.addColorStop(.4, "#fbe7a6"); mg.addColorStop(.62, "#d6a24c"); mg.addColorStop(1, "#7a5220");
  g.fillStyle = mg; band(); g.fill();
  g.save(); band(); g.clip();''')
rep('''    g.beginPath(); g.moveTo(x, top + bh * .28); g.lineTo(x, top + bh * .94); g.stroke();''',
'''    const yy = top + dy(x);
    g.beginPath(); g.moveTo(x, yy + bh * .28); g.lineTo(x, yy + bh * .94); g.stroke();''')
rep('''    g.beginPath(); g.moveTo(x + w * .014, top + bh * .3); g.lineTo(x + w * .014, top + bh * .92); g.stroke();''',
'''    g.beginPath(); g.moveTo(x + w * .014, yy + bh * .3); g.lineTo(x + w * .014, yy + bh * .92); g.stroke();''')
rep('''g.fillRect(cx + Math.cos(ma) * cw / 2 - w * .03 * mf, top + bh * .3, w * .06 * mf, bh * .6); }''',
'''const mx = cx + Math.cos(ma) * cw / 2; g.fillRect(mx - w * .03 * mf, top + dy(mx) + bh * .3, w * .06 * mf, bh * .6); }''')
rep('''g.fillStyle = gg; g.fillRect(x0, top, cw, bh); }''', '''g.fillStyle = gg; g.fillRect(x0, top - bend, cw, bh + bend * 2); }''')
rep('''  g.fillStyle = tg; roundRect(g, x0 + w * .02, top, cw - w * .04, Math.max(2, bh * .22), w * .04, w * .02); g.fill();
  g.strokeStyle = "rgba(70,40,10,.55)"; g.lineWidth = Math.max(1, w * .015); roundRect(g, x0, top, cw, bh, w * .05, w * .05); g.stroke();''',
'''  g.strokeStyle = tg; g.lineWidth = Math.max(2, bh * .18); g.lineCap = "round"; g.beginPath(); g.ellipse(cx, top + bh * .08, half * .97, bend, 0, .08, Math.PI - .08); g.stroke();
  g.strokeStyle = "rgba(70,40,10,.55)"; g.lineWidth = Math.max(1, w * .015);
  g.beginPath(); g.ellipse(cx, top, half, bend, 0, Math.PI, 6.283); g.lineTo(x0 + cw, top + bh); g.ellipse(cx, top + bh, half, bend, 0, 0, Math.PI); g.closePath(); g.stroke();''')
open(p, "w", encoding="utf-8").write(s)
print("cap ok")
