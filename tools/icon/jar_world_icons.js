// Jar World app icon (chosen: Jar Planet, optH). Run: node tools/icon/jar_world_icons.js OUTDIR layers  -> D-full.png (icon.png), D-bg.png, D-fg.png
const { chromium } = require('playwright'); const fs = require('fs');
const OUT = process.argv[2] || '.';
let uid = 0; const id = p => p + (uid++);
const lin = (stops, x1 = 0, y1 = 0, x2 = 0, y2 = 1) => { const g = id('l'); return [g, `<defs><linearGradient id="${g}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}">${stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('')}</linearGradient></defs>`]; };
const rad = (stops, cx = '50%', cy = '50%', r = '50%') => { const g = id('r'); return [g, `<defs><radialGradient id="${g}" cx="${cx}" cy="${cy}" r="${r}">${stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('')}</radialGradient></defs>`]; };
const glow = (cx, cy, r, col, a = .6) => { const [g, d] = rad([[0, col, a], [.4, col, a * .45], [1, col, 0]]); return d + `<circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#${g})"/>`; };
const spark = (cx, cy, r, col = '#fff8d8', a = .95) => { const k = r * .22; return `<path d="M${cx},${cy - r} Q${cx + k},${cy - k} ${cx + r},${cy} Q${cx + k},${cy + k} ${cx},${cy + r} Q${cx - k},${cy + k} ${cx - r},${cy} Q${cx - k},${cy - k} ${cx},${cy - r}Z" fill="${col}" opacity="${a}"/>`; };
// ---- the six world items ----
function fish(cx, cy, s, col = '#ffb43b', rot = 0) {
  return `<g transform="translate(${cx} ${cy}) rotate(${rot}) scale(${s / 100})">
  <path d="M38,0 L78,-30 Q70,0 78,30 Z" fill="${col}" stroke="#7a3d10" stroke-width="6" stroke-linejoin="round"/>
  <ellipse cx="-8" cy="0" rx="56" ry="40" fill="${col}" stroke="#7a3d10" stroke-width="6"/>
  <path d="M-10,-38 Q10,-62 30,-30" fill="${col}" stroke="#7a3d10" stroke-width="6" stroke-linejoin="round"/>
  <ellipse cx="-20" cy="-14" rx="26" ry="10" fill="#fff" opacity=".45"/>
  <circle cx="-36" cy="-6" r="10" fill="#fff"/><circle cx="-39" cy="-6" r="5.5" fill="#1a1430"/></g>`;
}
function flower(cx, cy, s, col = '#ff7eb6') {
  let p = ''; for (let k = 0; k < 6; k++) { const a = k * 60; p += `<ellipse cx="0" cy="-42" rx="24" ry="36" fill="${col}" stroke="#a8325f" stroke-width="5" transform="rotate(${a})"/>`; }
  return `<g transform="translate(${cx} ${cy}) scale(${s / 100})">${p}<circle r="26" fill="#ffd93b" stroke="#c98a10" stroke-width="5"/><circle cx="-8" cy="-8" r="8" fill="#fff" opacity=".6"/></g>`;
}
function gem(cx, cy, s, col = '#3fe08a') {
  return `<g transform="translate(${cx} ${cy}) scale(${s / 100})"><path d="M-44,-18 L-24,-46 L24,-46 L44,-18 L0,52 Z" fill="${col}" stroke="#145c36" stroke-width="6" stroke-linejoin="round"/>
  <path d="M-44,-18 L44,-18 M-24,-46 L-12,-18 L0,52 L12,-18 L24,-46" fill="none" stroke="#145c36" stroke-width="4" opacity=".6"/><path d="M-24,-46 L-12,-18 L-44,-18Z" fill="#fff" opacity=".45"/></g>`;
}
function firefly(cx, cy, s, col = '#ffd93b') {
  return glow(cx, cy, s * 1.6, col, .55) + `<g transform="translate(${cx} ${cy}) scale(${s / 100})">
  <ellipse cx="-34" cy="-34" rx="30" ry="20" transform="rotate(-28 -34 -34)" fill="#eef4ff" opacity=".8"/><ellipse cx="34" cy="-34" rx="30" ry="20" transform="rotate(28 34 -34)" fill="#eef4ff" opacity=".8"/>
  <circle r="42" fill="${col}" stroke="#a87410" stroke-width="5"/><circle cx="-13" cy="-14" r="12" fill="#fff" opacity=".85"/></g>`;
}
function candy(cx, cy, s, col = '#ff5c9a', rot = -20) {
  return `<g transform="translate(${cx} ${cy}) rotate(${rot}) scale(${s / 100})">
  <path d="M-40,0 L-80,-30 L-72,0 L-80,30Z" fill="${col}" stroke="#8a1844" stroke-width="5" stroke-linejoin="round"/><path d="M40,0 L80,-30 L72,0 L80,30Z" fill="${col}" stroke="#8a1844" stroke-width="5" stroke-linejoin="round"/>
  <ellipse rx="46" ry="34" fill="${col}" stroke="#8a1844" stroke-width="5"/>
  <path d="M-30,-24 Q-14,0 -30,24 M-6,-33 Q10,0 -6,33 M18,-30 Q34,0 18,30" stroke="#fff" stroke-width="7" fill="none" opacity=".8"/></g>`;
}
function planet(cx, cy, s, col = '#9b7bff', ring = '#ffd36b') {
  const [g, d] = rad([[0, '#ffffff', .5], [.35, col], [1, col]], '35%', '30%', '75%');
  return d + `<g transform="translate(${cx} ${cy}) scale(${s / 100}) rotate(-18)">
  <path d="M-78,0 A78,22 0 0 0 78,0" fill="none" stroke="${ring}" stroke-width="10" opacity=".9" transform="scale(1 1)"/>
  <circle r="44" fill="url(#${g})" stroke="#4a2f9a" stroke-width="5"/>
  <path d="M-78,0 A78,22 0 0 1 78,0" fill="none" stroke="${ring}" stroke-width="10"/></g>`;
}
const ITEMS = [(x, y, s) => fish(x, y, s), (x, y, s) => flower(x, y, s), (x, y, s) => gem(x, y, s), (x, y, s) => firefly(x, y, s), (x, y, s) => candy(x, y, s), (x, y, s) => planet(x, y, s)];
// ---- jar ----
function jarPath(x, top, w, h, br = .3) {
  const sh = top + w * .26, bot = top + h, b = w * br, nx = w * .11;
  return `M${x + nx},${top} L${x + nx},${top + w * .1} Q${x},${top + w * .12} ${x},${sh} L${x},${bot - b} Q${x},${bot} ${x + b},${bot} L${x + w - b},${bot} Q${x + w},${bot} ${x + w},${bot - b} L${x + w},${sh} Q${x + w},${top + w * .12} ${x + w - nx},${top + w * .1} L${x + w - nx},${top} Z`;
}
function lid(x, top, w, cols = ['#a8701f', '#ffe6a6', '#f2c46a', '#9a6418'], edge = '#6b4210') {
  const [g, d] = lin([[0, cols[0]], [.45, cols[1]], [.6, cols[2]], [1, cols[3]]], 0, 0, 1, 0);
  const lx = x + w * .06, lw = w * .88, lh = w * .17, ly = top - lh * .6;
  let s = d + `<rect x="${lx}" y="${ly}" width="${lw}" height="${lh}" rx="${lh * .3}" fill="url(#${g})" stroke="${edge}" stroke-width="${w * .016}"/>`;
  for (let i = 1; i < 9; i++) s += `<rect x="${lx + lw * i / 9 - w * .007}" y="${ly + lh * .28}" width="${w * .014}" height="${lh * .5}" rx="${w * .007}" fill="${edge}" opacity=".45"/>`;
  return s + `<rect x="${lx + lw * .05}" y="${ly + lh * .1}" width="${lw * .9}" height="${lh * .16}" rx="${lh * .08}" fill="#fff8dc" opacity=".75"/>`;
}
function jar(x, top, w, h, inside = '', o = {}) {
  const d = jarPath(x, top, w, h), clip = id('c');
  const [g, gd] = lin([[0, '#d8ecff', .42], [.5, '#d8ecff', .1], [1, '#d8ecff', .34]], 0, 0, 1, 0);
  let s = gd + `<defs><clipPath id="${clip}"><path d="${d}"/></clipPath></defs>`;
  if (o.back) s += `<path d="${d}" fill="${o.back}"/>`;
  s += `<path d="${d}" fill="url(#${g})"/><g clip-path="url(#${clip})">${inside}</g>`;
  s += `<path d="${d}" fill="none" stroke="${o.line || '#ffffff'}" stroke-opacity="${o.lineA || .9}" stroke-width="${w * .05}" stroke-linejoin="round"/>`;
  s += `<rect x="${x + w * .1}" y="${top + w * .36}" width="${w * .085}" height="${h * .5}" rx="${w * .04}" fill="#fff" opacity=".45"/>`;
  s += `<rect x="${x + w * .82}" y="${top + w * .46}" width="${w * .04}" height="${h * .26}" rx="${w * .02}" fill="#fff" opacity=".25"/>`;
  if (o.lid !== false) s += lid(x, top, w);
  return s;
}
const wrap = b => `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">${b}</svg>`;
const bgFill = (stops, x2 = 0, y2 = 1) => { const [g, d] = lin(stops, 0, 0, x2, y2); return d + `<rect width="1024" height="1024" fill="url(#${g})"/>`; };
const WC = [['#2fa8ff', '#0b5fa8'], ['#ffcf3a', '#e08a00'], ['#2ecf7a', '#137a44'], ['#26306e', '#121640'], ['#ff86c0', '#d0407e'], ['#7b5cff', '#3a239a']];
const stars = (n, seed, a = .7) => { let x = seed * 977, s = ''; const r = () => (x = (x * 9301 + 49297) % 233280) / 233280; for (let i = 0; i < n; i++) s += `<circle cx="${r() * 1024}" cy="${r() * 1024}" r="${2 + r() * 3}" fill="#fff" opacity="${a * (.3 + r() * .7)}"/>`; return s; };
const twilight = () => bgFill([[0, '#2a1d6e'], [.55, '#5b3aa8'], [1, '#ff8fb8']]) + stars(40, 3, .6);
// E. Slice world: a round glass jar holding a little planet made of six world slices
function optE() {
  let s = twilight();
  const cx = 512, cy = 560, R = 330;
  s += glow(cx, cy, 520, '#ffe7a8', .45);
  // round jar body
  const neckW = 300, neckTop = cy - R - 40;
  const body = `M${cx - neckW / 2},${neckTop} L${cx - neckW / 2},${cy - R + 30} A${R},${R} 0 1 0 ${cx + neckW / 2},${cy - R + 30} L${cx + neckW / 2},${neckTop} Z`;
  const clip = id('c');
  s += `<defs><clipPath id="${clip}"><path d="${body}"/></clipPath></defs><path d="${body}" fill="#d8ecff" fill-opacity=".18"/>`;
  // planet of six slices
  const pr = 245; let pie = '';
  const ang = a => [cx + Math.cos(a) * pr, cy + 40 + Math.sin(a) * pr];
  for (let k = 0; k < 6; k++) {
    const a0 = -Math.PI / 2 + k * Math.PI / 3, a1 = a0 + Math.PI / 3; const [x0, y0] = ang(a0), [x1, y1] = ang(a1);
    const [g, d] = rad([[0, WC[k][0]], [1, WC[k][1]]], '50%', '50%', '70%');
    pie += d + `<path d="M${cx},${cy + 40} L${x0},${y0} A${pr},${pr} 0 0 1 ${x1},${y1} Z" fill="url(#${g})" stroke="#fff" stroke-width="10" stroke-linejoin="round"/>`;
  }
  pie += `<circle cx="${cx}" cy="${cy + 40}" r="${pr}" fill="none" stroke="#fff" stroke-width="12"/>`;
  const order = [5, 0, 1, 2, 3, 4];
  for (let k = 0; k < 6; k++) { const a = -Math.PI / 2 + (k + .5) * Math.PI / 3; const x = cx + Math.cos(a) * pr * .62, y = cy + 40 + Math.sin(a) * pr * .62; pie += ITEMS[k](x, y, k == 3 ? 70 : 80); }
  s += pie;
  s += `<path d="${body}" fill="none" stroke="#fff" stroke-opacity=".95" stroke-width="18" stroke-linejoin="round"/>`;
  s += `<path d="M${cx - 230},${cy - 60} A${R - 40},${R - 40} 0 0 0 ${cx - 200},${cy + 200}" stroke="#fff" stroke-width="22" fill="none" opacity=".45" stroke-linecap="round"/>`;
  s += lid(cx - neckW / 2 - 10, neckTop + 6, neckW + 20);
  s += spark(170, 230, 34) + spark(860, 260, 26) + spark(880, 820, 22);
  return wrap(s);
}
// F. Six jars: one small jar for each world, two rows
function optF() {
  let s = twilight();
  s += glow(512, 520, 520, '#ffe7a8', .35);
  const w = 230, h = 300, xs = [92, 397, 702], ys = [150, 560];
  // shelves
  ys.forEach(y => s += `<rect x="60" y="${y + h - 4}" width="904" height="34" rx="12" fill="#8a5a34"/><rect x="60" y="${y + h - 4}" width="904" height="10" rx="5" fill="#c08a5a"/>`);
  for (let k = 0; k < 6; k++) {
    const x = xs[k % 3], y = ys[Math.floor(k / 3)] + 30;
    const [g, d] = lin([[0, WC[k][0], .55], [1, WC[k][1], .85]]);
    const ins = d + `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#${g})"/>` + ITEMS[k](x + w / 2, y + h * .58, k == 3 ? 78 : 92);
    s += jar(x, y, w, h - 30, ins);
  }
  return wrap(s);
}
// G. Mixed jar: six world stripes behind one big jar holding a mix of all six (the puzzle before sorting)
function optG() {
  let s = '';
  for (let k = 0; k < 8; k++) { const x0 = -600 + k * 300; s += `<path d="M${x0},1024 L${x0 + 300},1024 L${x0 + 300 + 600},0 L${x0 + 600},0 Z" fill="${WC[k % 6][0]}"/>`; }
  s += `<rect width="1024" height="1024" fill="#1a1040" opacity=".25"/>`;
  s += glow(512, 560, 470, '#fff3c8', .7);
  const x = 222, top = 220, w = 580, h = 700;
  const [g, d] = lin([[0, '#ffffff', .55], [1, '#e8f2ff', .7]]);
  let ins = d + `<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="url(#${g})"/>`;
  ins += fish(410, 800, 110) + candy(620, 810, 100, '#ff5c9a', 15) + gem(390, 600, 105) + planet(630, 600, 110) + flower(430, 410, 100) + firefly(625, 405, 86);
  s += jar(x, top, w, h, ins, { line: '#ffffff', lineA: 1 });
  return wrap(s);
}
// H. Jar planet: a big jar with a planet ring, the six worlds riding the ring
function optH(mode = 'full') {
  let s = bgFill([[0, '#120c3a'], [.6, '#2b1a6e'], [1, '#4b2a8e']]) + stars(80, 9, .8);
  s += glow(512, 540, 500, '#ffd9f0', .45);
  if (mode === 'bg') return wrap(s);
  if (mode === 'fg') s = '';
  const cx = 512, cy = 560, rx = 430, ry = 150, rot = -10;
  const ring = (sweep) => `<path d="M${cx - rx},${cy} A${rx},${ry} 0 0 ${sweep} ${cx + rx},${cy}" fill="none" stroke="#ffd36b" stroke-width="34" stroke-linecap="round" transform="rotate(${rot} ${cx} ${cy})" opacity=".95"/><path d="M${cx - rx},${cy} A${rx},${ry} 0 0 ${sweep} ${cx + rx},${cy}" fill="none" stroke="#fff3c0" stroke-width="8" stroke-linecap="round" transform="rotate(${rot} ${cx} ${cy})" opacity=".8"/>`;
  const pos = t => { const a = t, x = Math.cos(a) * rx, y = Math.sin(a) * ry, r = rot * Math.PI / 180; return [cx + x * Math.cos(r) - y * Math.sin(r), cy + x * Math.sin(r) + y * Math.cos(r)]; };
  // back ring + back items (angles in PI..2PI are behind)
  s += ring(1);
  const angs = [Math.PI * 1.22, Math.PI * 1.78, Math.PI * .08, Math.PI * .36, Math.PI * .64, Math.PI * .92];
  const itemAt = (k) => { const [x, y] = pos(angs[k]); return ITEMS[[5, 4, 0, 1, 2, 3][k]](x, y, k == 5 ? 70 : 84); };
  s += itemAt(0) + itemAt(1);
  const x = 322, top = 250, w = 380, h = 560;
  const [g, d] = rad([[0, '#ff9fd0'], [.5, '#7b5cff'], [1, '#2fa8ff']], '40%', '35%', '80%');
  s += jar(x, top, w, h, d + `<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="url(#${g})"/>` + stars(30, 4, .8).replace(/<circle cx="(\d+\.?\d*)" cy="(\d+\.?\d*)"/g, (m, a, b) => `<circle cx="${x + (a / 1024) * w}" cy="${top + (b / 1024) * h}"`));
  s += ring(0);
  s += itemAt(2) + itemAt(3) + itemAt(4) + itemAt(5);
  return wrap(s);
}
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1024, height: 1024 } });
  if (process.argv[3] === 'layers') {
    for (const m of ['full', 'bg', 'fg']) { uid = 0; await p.setContent(`<html><body style="margin:0;background:transparent">${optH(m)}</body></html>`); await p.screenshot({ path: `${OUT}/D-${m}.png`, omitBackground: true }); }
    await b.close(); return;
  }
  const opts = { 'jw2-option-A-world-slices': optE(), 'jw2-option-B-six-jars': optF(), 'jw2-option-C-mixed-jar': optG(), 'jw2-option-D-jar-planet': optH() };
  for (const [n, svg] of Object.entries(opts)) { await p.setContent(`<html><body style="margin:0;background:#000">${svg}</body></html>`); await p.screenshot({ path: `${OUT}/${n}.png` }); }
  await b.close();
})();
