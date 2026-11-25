// ===================== TEST BUILD: six themed regions =====================
// Each chapter is a region with its own scene, its own things to sort and its own jar.
// Same levels and rules. Added on top of the normal game by tools/web/edit_regions.py.
const REGIONS = [
  { name: "reef", custom: 1, day: 1, title: "Bubble Reef", item: "fish", jar: "tube", deco: "bubbles",
    sky: ["#8af3ea", "#2ec7d7", "#0e86ae"], hills: ["#f2d9a0", "#e0bf80", "#2e9e6a"], glow: "#bff9ff",
    cap: ["#a8574c", "#f29b8a", "#ffe6df"], shelf: ["#e9cf94", "#b98f55", "#fff1cc"] },
  { name: "sunpetal", custom: 1, day: 1, title: "Sunpetal Meadow", item: "flower", jar: "vase", deco: "clay",
    sky: ["#ff8f8f", "#ffb877", "#ffe3a3"], hills: ["#a6d872", "#86c45c", "#62a843"], glow: "#ffb347",
    cap: ["#8c3f22", "#d9744a", "#ffc7a6"], shelf: ["#a86b3c", "#6e4223", "#c98a55"] },
  { name: "grove", custom: 1, title: "Lantern Grove", item: "gem", jar: "mason", deco: "lantern",
    sky: ["#2f7a4f", "#1e5b3c", "#123826"], hills: ["#1b5233", "#2c5e2a", "#16391f"], glow: "#7dffd0",
    cap: ["#5a3c1c", "#c9a45a", "#f5e0a0"], shelf: ["#5a3d22", "#3a2614", "#6fae4b"] },
  Object.assign({}, THEMES[0], { title: "Firefly Night", item: "fly", jar: "mason" }),
  { name: "candy", custom: 1, day: 1, title: "Candy Clouds", item: "candy", jar: "tube", deco: "stripes", line: "rgba(255,255,255,.9)",
    sky: ["#ff8fc8", "#ffaed6", "#ffd0e8"], hills: ["#ff7fbd", "#ffa3cf", "#fff2f8"], glow: "#ff8fc8",
    cap: ["#c2407a", "#ff7fb5", "#ffe0ee"], shelf: ["#f7c9a0", "#d99a6a", "#fff0e0"] },
  { name: "space", custom: 1, title: "Starlight Space", item: "planet", jar: "tube", deco: "metal",
    sky: ["#0c0626", "#2a1258", "#5a2a8a"], hills: ["#3b2370", "#2a1756", "#1a0d3a"], glow: "#c58bff",
    cap: ["#4a5570", "#aab6d0", "#f2f6ff"], shelf: ["#59607a", "#363b52", "#9aa4c4"] },
];
CHAPTERS.length = 0; REGIONS.forEach(t => CHAPTERS.push(t.title));
THEMES.length = 0; REGIONS.forEach(t => THEMES.push(t));

const lerpHex = (a, b, k) => { const A = parseInt(a.slice(1), 16), B = parseInt(b.slice(1), 16), f = s => Math.round(((A >> s) & 255) * (1 - k) + ((B >> s) & 255) * k);
  return "#" + [16, 8, 0].map(s => f(s).toString(16).padStart(2, "0")).join(""); };
const GOLD = ["#b9843a", "#ecc675", "#8a5d22", "#d9a74e", "#fbe7a6", "#d6a24c", "#7a5220", "#c99a4a", "#fff3c8", "#b9873a"];
function capCols() {
  const T = themeNow(); if (!T.cap) return GOLD;
  const [d, m, l] = T.cap;
  return [lerpHex(d, m, .5), lerpHex(m, l, .5), d, m, l, m, lerpHex(d, "#000000", .1), lerpHex(d, m, .7), lerpHex(l, "#ffffff", .5), lerpHex(d, m, .5)];
}

// ---------- the things to sort ----------
const ITEMS = {
  fish(g, x, y, r, col, flap, aw, mv, id) {
    const d = (Math.round(id) & 1) ? 1 : -1, wag = Math.sin(flap) * .3;
    g.save(); g.translate(x, y); g.scale(d, 1); g.lineJoin = "round";
    g.strokeStyle = "rgba(15,40,70,.4)"; g.lineWidth = Math.max(1, r * .08);
    g.save(); g.translate(r * .55, 0); g.rotate(wag); g.fillStyle = shade(col, .86);
    g.beginPath(); g.moveTo(0, 0); g.lineTo(r * .5, -r * .45); g.quadraticCurveTo(r * .36, 0, r * .5, r * .45); g.closePath(); g.fill(); g.stroke(); g.restore();
    g.fillStyle = shade(col, .86); g.beginPath(); g.moveTo(-r * .3, -r * .42); g.quadraticCurveTo(0, -r * .9, r * .35, -r * .36); g.closePath(); g.fill(); g.stroke();
    g.fillStyle = col; g.beginPath(); g.ellipse(0, 0, r * .78, r * .56, 0, 0, 6.283); g.fill(); g.stroke();
    g.fillStyle = "rgba(255,255,255,.35)"; g.beginPath(); g.ellipse(-r * .08, r * .2, r * .45, r * .16, 0, 0, 6.283); g.fill();
    g.strokeStyle = "rgba(255,255,255,.65)"; g.lineWidth = Math.max(1, r * .11); g.beginPath(); g.moveTo(r * .14, -r * .46); g.quadraticCurveTo(r * .3, 0, r * .14, r * .46); g.stroke();
    g.fillStyle = "#fff"; g.beginPath(); g.arc(-r * .44, -r * .1, r * .17, 0, 6.283); g.fill();
    g.fillStyle = "#13243a"; g.beginPath(); g.arc(-r * .48, -r * .1, r * .09, 0, 6.283); g.fill();
    g.restore();
  },
  flower(g, x, y, r, col, flap, aw, mv, id) {
    g.save(); g.translate(x, y); g.rotate(id * .9 + Math.sin(flap * .15) * .15);
    g.strokeStyle = "rgba(90,30,20,.32)"; g.lineWidth = Math.max(1, r * .07);
    for (let k = 0; k < 5; k++) {
      g.save(); g.rotate(k * 1.2566); g.fillStyle = col; g.beginPath(); g.ellipse(0, -r * .47, r * .36, r * .47, 0, 0, 6.283); g.fill(); g.stroke();
      g.fillStyle = "rgba(255,255,255,.35)"; g.beginPath(); g.ellipse(0, -r * .55, r * .12, r * .24, 0, 0, 6.283); g.fill(); g.restore();
    }
    g.fillStyle = col === "#ffd93b" ? "#ff9f43" : "#ffd54a"; g.beginPath(); g.arc(0, 0, r * .26, 0, 6.283); g.fill(); g.strokeStyle = "rgba(170,90,10,.6)"; g.stroke();
    g.fillStyle = "rgba(255,250,210,.9)"; g.beginPath(); g.arc(-r * .07, -r * .07, r * .09, 0, 6.283); g.fill();
    g.restore();
  },
  gem(g, x, y, r, col, flap, aw, mv, id) {
    if (aw) glow(g, x, y, r * 2.4, col, .32 + .1 * Math.sin(now / 300 + id));
    const h = r * .84, w = r * .7, P = (pts, f) => { g.beginPath(); pts.forEach(([a, b], i) => i ? g.lineTo(a, b) : g.moveTo(a, b)); g.closePath(); if (f) { g.fillStyle = f; g.fill(); } };
    const out = [[0, -h], [w, -h * .35], [w, h * .35], [0, h], [-w, h * .35], [-w, -h * .35]];
    g.save(); g.translate(x, y); g.rotate(Math.sin(now / 700 + id) * .08);
    P(out, col); P([[0, -h], [w, -h * .35], [0, -h * .05], [-w, -h * .35]], "rgba(255,255,255,.5)");
    P([[0, -h * .05], [w, -h * .35], [w, h * .35], [0, h]], "rgba(0,0,0,.18)"); P([[0, -h * .75], [w * .35, -h * .45], [0, -h * .3]], "rgba(255,255,255,.85)");
    P(out); g.strokeStyle = "rgba(10,30,20,.4)"; g.lineWidth = Math.max(1, r * .06); g.lineJoin = "round"; g.stroke();
    g.restore();
  },
  candy(g, x, y, r, col, flap, aw, mv, id) {
    g.save(); g.translate(x, y); g.rotate(-.3 + Math.sin(flap * .2 + id) * .06);
    g.strokeStyle = "rgba(110,20,60,.35)"; g.lineWidth = Math.max(1, r * .07); g.lineJoin = "round";
    for (const s of [-1, 1]) { g.fillStyle = mixWhite(col, .35); g.beginPath(); g.moveTo(s * r * .5, 0); g.lineTo(s * r * .98, -r * .38); g.quadraticCurveTo(s * r * .86, 0, s * r * .98, r * .38); g.closePath(); g.fill(); g.stroke(); }
    g.fillStyle = col; g.beginPath(); g.ellipse(0, 0, r * .6, r * .5, 0, 0, 6.283); g.fill(); g.stroke();
    g.save(); g.beginPath(); g.ellipse(0, 0, r * .6, r * .5, 0, 0, 6.283); g.clip();
    g.strokeStyle = col === "#ffffff" ? "rgba(255,92,138,.6)" : "rgba(255,255,255,.55)"; g.lineWidth = r * .12;
    for (let k = -2; k <= 2; k++) { g.beginPath(); g.moveTo(k * r * .3 - r * .3, -r * .6); g.lineTo(k * r * .3 + r * .3, r * .6); g.stroke(); }
    g.restore();
    g.fillStyle = "rgba(255,255,255,.75)"; g.beginPath(); g.ellipse(-r * .22, -r * .22, r * .14, r * .08, -.5, 0, 6.283); g.fill();
    g.restore();
  },
  planet(g, x, y, r, col, flap, aw, mv, id) {
    if (aw) glow(g, x, y, r * 2.2, col, .28);
    const tilt = -.35 + ((Math.round(id) % 3) - 1) * .15, ring = mixWhite(col, .55);
    g.save(); g.translate(x, y); g.rotate(tilt);
    g.strokeStyle = ring; g.lineWidth = Math.max(1.5, r * .12); g.beginPath(); g.ellipse(0, 0, r * .98, r * .3, 0, Math.PI, 2 * Math.PI); g.stroke();
    const gr = g.createRadialGradient(-r * .25, -r * .25, r * .1, 0, 0, r * .62); gr.addColorStop(0, mixWhite(col, .5)); gr.addColorStop(1, col);
    g.fillStyle = gr; g.beginPath(); g.arc(0, 0, r * .6, 0, 6.283); g.fill(); g.strokeStyle = "rgba(10,0,30,.35)"; g.lineWidth = Math.max(1, r * .06); g.stroke();
    g.save(); g.beginPath(); g.arc(0, 0, r * .6, 0, 6.283); g.clip(); g.fillStyle = "rgba(0,0,0,.13)"; g.fillRect(-r, -r * .16, r * 2, r * .12); g.fillRect(-r, r * .2, r * 2, r * .08); g.restore();
    g.strokeStyle = ring; g.lineWidth = Math.max(1.5, r * .12); g.beginPath(); g.ellipse(0, 0, r * .98, r * .3, 0, 0, Math.PI); g.stroke();
    g.restore();
  },
};
const _paintFly = paintFly;
paintFly = function (g, x, y, r, c, flap, awake, moving, id, skin) {
  const kind = themeNow().item || "fly";
  if (kind === "fly") return _paintFly(g, x, y, r, c, flap, awake, moving, id, skin);
  const col = COLORS[c], sk = skin || save.flySkin;
  if (!col) return;
  g.save(); if (!awake) g.globalAlpha *= .5;
  ITEMS[kind](g, x, y, r, col, flap || 0, awake, moving, id || 0);
  g.restore();
  if (awake && sk !== "fairy") flyExtra(g, x, y, r, col, id, sk);
  if (save.colorBlind) paintSymbol(g, x + r * .08, y + r * .12, r * .3, c);
};

// ---------- jars ----------
const _jarPath = jarPath;
jarPath = function (g, r, mouth = 0) {
  const st = themeNow().jar, x = r.x, w = r.w, top = r.y, bot = r.y + r.h;
  if (st === "tube") {
    g.beginPath(); g.moveTo(x + w * .06, top); g.lineTo(x + w * .06, bot - w * .44); g.arc(x + w / 2, bot - w * .44, w * .44, Math.PI, 0, true); g.lineTo(x + w * .94, top);
    if (mouth) g.ellipse(x + w / 2, top, w * .44, mouth, 0, 0, Math.PI, true);
    g.closePath(); return;
  }
  if (st === "vase") {
    g.beginPath(); g.moveTo(x + w * .14, top); g.lineTo(x + w * .14, top + w * .14);
    g.bezierCurveTo(x - w * .02, top + w * .32, x, top + w * .48, x, top + w * .66); g.lineTo(x, bot - w * .3); g.quadraticCurveTo(x, bot, x + w * .3, bot);
    g.lineTo(x + w * .7, bot); g.quadraticCurveTo(x + w, bot, x + w, bot - w * .3); g.lineTo(x + w, top + w * .66);
    g.bezierCurveTo(x + w, top + w * .48, x + w * 1.02, top + w * .32, x + w * .86, top + w * .14); g.lineTo(x + w * .86, top);
    if (mouth) g.ellipse(x + w / 2, top, w * .36, mouth, 0, 0, Math.PI, true);
    g.closePath(); return;
  }
  return _jarPath(g, r, mouth);
};
const _jarLine = jarLine;
jarLine = function (skin) { const T = themeNow(); if (T.line && (!(skin || save.jarSkin) || (skin || save.jarSkin) === "classic")) return T.line; return _jarLine(skin); };
function regionDeco(g, r, deco) {
  const x = r.x, w = r.w, top = r.y, bot = r.y + r.h, lw = Math.max(1.5, w * .04);
  g.save(); g.lineCap = "round"; g.lineJoin = "round";
  if (deco === "bubbles") {
    for (const [bx, by, br] of [[1.08, .35, .07], [1.16, .2, .045], [1.1, .08, .03]]) { g.strokeStyle = "rgba(255,255,255,.75)"; g.lineWidth = Math.max(1, w * .025); g.beginPath(); g.arc(x + w * bx, top + w * by, w * br, 0, 6.283); g.stroke(); }
    g.fillStyle = "#ff9d8c"; g.strokeStyle = "#d9675a"; g.lineWidth = Math.max(1, w * .03);
    g.beginPath(); g.moveTo(x + w * .08, bot + w * .02); for (let k = 0; k < 4; k++) g.quadraticCurveTo(x + w * (.08 + k * .21 + .105), bot - w * .12, x + w * (.08 + (k + 1) * .21), bot + w * .02); g.closePath(); g.fill(); g.stroke();
  } else if (deco === "clay") {
    const rim = g.createLinearGradient(0, top - w * .04, 0, top + w * .1); rim.addColorStop(0, "#f2a27b"); rim.addColorStop(1, "#b9562f");
    g.fillStyle = rim; roundRect(g, x + w * .06, top - w * .03, w * .88, w * .12, w * .05, w * .05); g.fill(); g.strokeStyle = "rgba(110,40,15,.6)"; g.lineWidth = Math.max(1, w * .025); g.stroke();
    g.strokeStyle = "#5fa640"; g.lineWidth = lw; g.beginPath(); g.moveTo(x + w * .5, bot); g.quadraticCurveTo(x + w * .5, bot + w * .1, x + w * .32, bot + w * .12); g.stroke();
    ellipse(g, x + w * .66, bot + w * .07, w * .1, w * .05, "#6fb14d");
  } else if (deco === "lantern") {
    const wood = "#6b4a26", dark = "rgba(50,30,12,.8)";
    g.fillStyle = wood; g.strokeStyle = dark; g.lineWidth = Math.max(1, w * .025);
    for (const sx of [-.03, .95]) { roundRect(g, x + w * sx, top + w * .28, w * .08, r.h - w * .36, w * .03, w * .03); g.fill(); g.stroke(); }
    roundRect(g, x - w * .06, bot - w * .1, w * 1.12, w * .14, w * .04, w * .04); g.fill(); g.stroke();
    g.strokeStyle = "#c9a45a"; g.lineWidth = lw; g.beginPath(); g.arc(x + w / 2, top - w * .32, w * .14, Math.PI * 1.05, Math.PI * 1.95); g.stroke();
    glow(g, x + w / 2, bot - w * .05, w * .6, "#ffd36a", .18);
  } else if (deco === "stripes") {
    g.save(); jarPath(g, r); g.clip();
    const sy = bot - w * .26; g.fillStyle = "rgba(255,255,255,.75)"; g.fillRect(x, sy, w, w * .26);
    g.fillStyle = "rgba(255,92,138,.55)"; for (let k = -1; k < 6; k++) { g.beginPath(); g.moveTo(x + k * w * .22, bot); g.lineTo(x + k * w * .22 + w * .1, bot); g.lineTo(x + k * w * .22 + w * .3, sy); g.lineTo(x + k * w * .22 + w * .2, sy); g.closePath(); g.fill(); }
    g.restore();
    for (const [sx, sy2, c] of [[.18, .9, "#7dff6b"], [.8, 1.3, "#5cf2ff"], [.25, 1.6, "#ffd93b"]]) { g.fillStyle = c; g.globalAlpha = .7; roundRect(g, x + w * sx, top + w * sy2, w * .1, w * .035, w * .017, w * .017); g.fill(); }
    g.globalAlpha = 1;
  } else if (deco === "metal") {
    const band = (yy) => { const mg = g.createLinearGradient(x, 0, x + w, 0); mg.addColorStop(0, "#59607a"); mg.addColorStop(.4, "#e6ecff"); mg.addColorStop(1, "#4a5068");
      g.fillStyle = mg; roundRect(g, x - w * .02, yy, w * 1.04, w * .1, w * .04, w * .04); g.fill(); g.fillStyle = "#2c3147"; for (const k of [.15, .5, .85]) { g.beginPath(); g.arc(x + w * k, yy + w * .05, w * .022, 0, 6.283); g.fill(); } };
    band(top + w * .14); band(bot - w * .5);
    g.fillStyle = "rgba(255,255,255,.8)"; for (const [sx, sy] of [[.3, .7], [.7, 1.2], [.4, 1.7]]) { sparkPath(g, x + w * sx, top + w * sy, w * .06, w * .015); g.fill(); }
  }
  g.restore();
}
const _pjf = paintJarFront;
paintJarFront = function (g, r, St, i, R) { const T = themeNow(); if (T.deco && T.deco !== "lantern") regionDeco(g, r, T.deco); if (T.deco === "lantern") regionDeco(g, r, "lantern"); _pjf(g, r, St, i, R); };
const _shelf = paintShelf;
paintShelf = function (g, sh) {
  const T = themeNow(); if (!T.shelf) return _shelf(g, sh);
  const [a, b, topc] = T.shelf;
  g.fillStyle = "rgba(0,0,0,.2)"; g.beginPath(); g.ellipse(sh.x + sh.w / 2, sh.y + sh.h * 1.7, sh.w * .5, sh.h * .6, 0, 0, 6.283); g.fill();
  const wg = g.createLinearGradient(0, sh.y, 0, sh.y + sh.h); wg.addColorStop(0, a); wg.addColorStop(1, b);
  g.fillStyle = wg; roundRect(g, sh.x, sh.y, sh.w, sh.h, sh.h * .45, sh.h * .45); g.fill();
  g.fillStyle = topc; roundRect(g, sh.x + 3, sh.y, sh.w - 6, Math.max(2, sh.h * .25), 2, 2); g.fill();
  const r = rng(Math.round(sh.y));
  if (T.name === "candy") for (let k = 0; k < 14; k++) { g.fillStyle = COLORS[k % 7]; g.fillRect(sh.x + r() * sh.w, sh.y + sh.h * (.35 + r() * .45), 4, 2); }
  if (T.name === "reef") for (let k = 0; k < 3; k++) { const sx = sh.x + sh.w * (.2 + k * .3), sy = sh.y + sh.h * .7; g.fillStyle = "#ffd2c2"; g.beginPath(); g.arc(sx, sy, sh.h * .3, Math.PI, 0); g.fill(); }
  if (T.name === "grove") for (let k = 0; k < 6; k++) ellipse(g, sh.x + sh.w * (.08 + k * .17), sh.y + 1, sh.h * .5, sh.h * .25, "#4f9a3a");
  if (T.name === "space") { g.fillStyle = "#2c3147"; for (let k = 0; k < 6; k++) { g.beginPath(); g.arc(sh.x + sh.w * (.08 + k * .168), sh.y + sh.h * .6, 2, 0, 6.283); g.fill(); } }
  if (T.glow && !T.day) glow(g, sh.x + sh.w / 2, sh.y, sh.w * .55, T.glow, .1);
};

// ---------- scenes ----------
function grad(g, H, cols, y0 = 0) { const gr = g.createLinearGradient(0, y0, 0, H); cols.forEach((c, k) => gr.addColorStop(k / (cols.length - 1), c)); return gr; }
function puff(g, x, y, s, col) { ellipse(g, x, y, 42 * s, 15 * s, col); ellipse(g, x - 15 * s, y - 9 * s, 17 * s, 17 * s, col); ellipse(g, x + 12 * s, y - 13 * s, 21 * s, 21 * s, col); }
function rays(g, W, H, col, list) {
  for (const [a, b, c, d] of list) { const gr = g.createLinearGradient(0, 0, 0, H * .8); gr.addColorStop(0, col); gr.addColorStop(1, "rgba(255,255,255,0)");
    g.fillStyle = gr; g.beginPath(); g.moveTo(W * a, 0); g.lineTo(W * b, 0); g.lineTo(W * d, H * .8); g.lineTo(W * c, H * .8); g.closePath(); g.fill(); }
}
function coral(g, x, base, s, col) {
  g.strokeStyle = col; g.lineCap = "round"; g.lineWidth = 9 * s;
  g.beginPath(); g.moveTo(x, base); g.lineTo(x, base - 50 * s); g.moveTo(x, base - 22 * s); g.quadraticCurveTo(x - 20 * s, base - 28 * s, x - 22 * s, base - 55 * s);
  g.moveTo(x, base - 30 * s); g.quadraticCurveTo(x + 18 * s, base - 36 * s, x + 20 * s, base - 64 * s); g.stroke();
}
function mush(g, x, base, s, cap) {
  g.fillStyle = "#f3e8cf"; roundRect(g, x - 5 * s, base - 22 * s, 10 * s, 22 * s, 4 * s, 2 * s); g.fill();
  g.fillStyle = cap; g.beginPath(); g.moveTo(x - 22 * s, base - 18 * s); g.quadraticCurveTo(x - 20 * s, base - 44 * s, x, base - 46 * s); g.quadraticCurveTo(x + 20 * s, base - 44 * s, x + 22 * s, base - 18 * s); g.closePath(); g.fill();
  ellipse(g, x - 8 * s, base - 32 * s, 3 * s, 3 * s, "rgba(255,255,255,.8)"); ellipse(g, x + 7 * s, base - 36 * s, 2.5 * s, 2.5 * s, "rgba(255,255,255,.8)");
}
function lolly(g, x, base, h, col) {
  g.strokeStyle = "#fff"; g.lineWidth = Math.max(2, h * .05); g.beginPath(); g.moveTo(x, base); g.lineTo(x, base - h); g.stroke();
  const rr = h * .28; ellipse(g, x, base - h, rr, rr, col);
  g.strokeStyle = "rgba(255,255,255,.8)"; g.lineWidth = Math.max(1.5, rr * .18); g.beginPath();
  for (let a = 0; a < 12; a += .3) { const q = rr * a / 12; g.lineTo(x + Math.cos(a) * q, base - h + Math.sin(a) * q); } g.stroke();
}
function bigPlanet(g, x, y, r) {
  glow(g, x, y, r * 2.4, "#ff9f43", .22);
  g.strokeStyle = "rgba(255,220,170,.7)"; g.lineWidth = r * .1; g.beginPath(); g.ellipse(x, y, r * 1.7, r * .45, -.3, Math.PI * .97, Math.PI * 2.03); g.stroke();
  const gr = g.createRadialGradient(x - r * .3, y - r * .3, r * .1, x, y, r); gr.addColorStop(0, "#ffd29a"); gr.addColorStop(1, "#d9662f");
  g.fillStyle = gr; g.beginPath(); g.arc(x, y, r, 0, 6.283); g.fill();
  g.save(); g.beginPath(); g.arc(x, y, r, 0, 6.283); g.clip(); g.fillStyle = "rgba(120,40,10,.18)"; g.fillRect(x - r, y - r * .2, r * 2, r * .15); g.fillRect(x - r, y + r * .25, r * 2, r * .1); g.restore();
  g.strokeStyle = "rgba(255,220,170,.85)"; g.beginPath(); g.ellipse(x, y, r * 1.7, r * .45, -.3, Math.PI * .03, Math.PI * .97); g.stroke();
}
const SCENE = {
  reef: {
    sky(g, T, W, H) {
      g.fillStyle = grad(g, H, T.sky); g.fillRect(0, 0, W, H);
      rays(g, W, H, "rgba(255,255,255,.28)", [[.08, .2, .3, .5], [.55, .63, .7, .9], [.82, .88, .92, 1.05]]);
      g.strokeStyle = "rgba(255,255,255,.55)"; g.lineWidth = 3; g.beginPath(); for (let x = 0; x <= W; x += 6) g.lineTo(x, H * .012 + Math.sin(x / 22) * 3); g.stroke();
    },
    land(g, T, W, H) {
      hillW(g, W, H, H * .84, H * .018, 3, .5, T.hills[1]);
      [[.1, "#ff7a8a", 1], [.9, "#ffa24d", .9], [.72, "#c77dff", .6]].forEach(([cx, c, s]) => coral(g, W * cx, H * .9, s * Math.min(1.4, W / 360), c));
      hillW(g, W, H, H * .9, H * .012, 5, 2, T.hills[0]);
      for (let k = 0; k < 3; k++) { const sx = W * (.3 + k * .2), sy = H * (.95 + (k % 2) * .02); g.fillStyle = "#ffd2c2"; g.beginPath(); g.arc(sx, sy, 9, Math.PI, 0); g.fill(); g.strokeStyle = "#e59a85"; g.lineWidth = 1.5; g.stroke(); }
    },
    live(g, T, W, H, t, part) {
      if (part === "sky") {
        for (let k = 0; k < 3; k++) { const dir = k % 2 ? -1 : 1, u = ((t * .03 * (1 + k * .3) + k * .37) % 1.3) - .15, x = dir > 0 ? u * W : W - u * W, y = H * (.3 + k * .14) + Math.sin(t + k) * 6;
          g.save(); g.globalAlpha = .35; g.translate(x, y); g.scale(-dir, 1); g.fillStyle = "#0a6f8f"; g.beginPath(); g.ellipse(0, 0, 14, 7, 0, 0, 6.283); g.fill(); g.beginPath(); g.moveTo(10, 0); g.lineTo(20, -7); g.lineTo(20, 7); g.closePath(); g.fill(); g.restore(); }
        for (let k = 0; k < 16; k++) { const r = rng(k * 7 + 3), sp = .04 + r() * .05, u = (r() + t * sp) % 1, x = r() * W + Math.sin(t * 1.5 + k) * 6, y = H * (1.02 - u * 1.05), s = 2 + r() * 5;
          g.strokeStyle = "rgba(255,255,255,.7)"; g.lineWidth = 1.3; g.beginPath(); g.arc(x, y, s, 0, 6.283); g.stroke(); }
        return;
      }
      g.strokeStyle = T.hills[2]; g.lineCap = "round";
      for (let k = 0; k < 6; k++) { const x = W * (.05 + k * .19), base = H * .93, h = H * (.1 + (k % 3) * .03); g.lineWidth = 6;
        g.beginPath(); g.moveTo(x, base); for (let s = 1; s <= 8; s++) { const u = s / 8; g.lineTo(x + Math.sin(t * 1.2 + k + u * 4) * 8 * u, base - h * u); } g.stroke(); }
    },
  },
  sunpetal: {
    sky(g, T, W, H) {
      g.fillStyle = grad(g, H * .75, T.sky); g.fillRect(0, 0, W, H);
      glow(g, W * .72, H * .2, W * .45, "#fff3b0", .55); ellipse(g, W * .72, H * .2, W * .11, W * .11, "#fff8d6");
      puff(g, W * .18, H * .12, W / 380, "rgba(255,255,255,.85)"); puff(g, W * .8, H * .36, W / 520, "rgba(255,255,255,.75)");
    },
    land(g, T, W, H) {
      hillW(g, W, H, H * .66, H * .02, 3, 1, "#b8e08a");
      [.12, .86].forEach((x, i) => roundTree(g, W * x, H * .7, H * .14, "#7a4a2a", "#6fb14d", "rgba(255,255,255,.35)", i * 5 + 2));
      hillW(g, W, H, H * .74, H * .02, 4, 2.2, T.hills[0]);
      hillW(g, W, H, H * .83, H * .018, 3, .7, T.hills[1]);
      hillW(g, W, H, H * .91, H * .012, 5, 1.4, T.hills[2]);
      const r = rng(5); for (let k = 0; k < 26; k++) { const x = r() * W, y = H * (.76 + r() * .22); ITEMS.flower(g, x, y, 5 + r() * 3, ["#ffffff", "#ff5c8a", "#ffd93b", "#b98cff"][k % 4], 0, 1, 0, k); }
    },
    live(g, T, W, H, t, part) {
      if (part === "sky") { const x = ((t * .01) % 1.4 - .2) * W; puff(g, x, H * .26, W / 620, "rgba(255,255,255,.55)"); return; }
      for (const p of petals) { const u = (p.o + t * p.v) % 1, x = (p.x + Math.sin(t * .5 + p.a) * .05 + u * .2) % 1 * W, y = u * H;
        g.save(); g.translate(x, y); g.rotate(t * 1.5 * p.s + p.a); ellipse(g, 0, 0, 4 * p.s, 2.2 * p.s, "rgba(255,140,170,.75)"); g.restore(); }
      for (let k = 0; k < 2; k++) { const x = W * (.3 + k * .4) + Math.sin(t * .7 + k * 2) * W * .12, y = H * (.55 + k * .08) + Math.sin(t * 1.9 + k) * 12, f = Math.abs(Math.sin(t * 9 + k));
        g.fillStyle = k ? "#ffffff" : "#ffb347"; for (const s of [-1, 1]) { g.beginPath(); g.ellipse(x + s * 5 * f, y, 5 * f + 1, 7, s * .4, 0, 6.283); g.fill(); } }
    },
  },
  grove: {
    sky(g, T, W, H) {
      g.fillStyle = grad(g, H, T.sky); g.fillRect(0, 0, W, H);
      rays(g, W, H, "rgba(234,255,176,.3)", [[.3, .48, .6, .9], [.6, .7, .9, 1.05]]);
      g.fillStyle = "rgba(18,56,36,.7)"; [[.0, .09], [.9, .12], [.76, .04], [.15, .035]].forEach(([x, w]) => g.fillRect(W * x, 0, W * w, H));
      ellipse(g, W * .05, -10, W * .3, H * .09, "#1b5233"); ellipse(g, W * .95, -20, W * .32, H * .1, "#1b5233"); ellipse(g, W * .5, -30, W * .24, H * .07, "#22603b");
    },
    land(g, T, W, H) {
      hillW(g, W, H, H * .86, H * .015, 4, 1.1, T.hills[1]);
      [[.1, 1.1], [.88, .9], [.22, .6], [.7, .7], [.5, .5]].forEach(([x, s]) => mush(g, W * x, H * .89, s * Math.min(1.5, W / 320), "#7dffd0"));
      hillW(g, W, H, H * .93, H * .01, 6, 2.6, T.hills[2]);
    },
    live(g, T, W, H, t, part) {
      if (part === "sky") return;
      [[.1, 1.1], [.88, .9], [.22, .6], [.7, .7], [.5, .5]].forEach(([x, s], k) => glow(g, W * x, H * .89 - 34 * s * Math.min(1.5, W / 320), 50 * s, "#7dffd0", .18 + .1 * Math.sin(t * 1.6 + k)));
      for (let k = 0; k < 18; k++) { const r = rng(k * 13 + 1), u = (r() + t * (.01 + r() * .02)) % 1, x = (r() + Math.sin(t * .4 + k) * .03) * W, y = H * (1 - u);
        glow(g, x, y, 8, "#d7ff9a", .5 * Math.abs(Math.sin(t + k))); g.fillStyle = "rgba(230,255,180,.8)"; g.fillRect(x - 1, y - 1, 2, 2); }
    },
  },
  candy: {
    sky(g, T, W, H) {
      g.fillStyle = grad(g, H, T.sky); g.fillRect(0, 0, W, H);
      const cols = ["255,90,110", "255,160,70", "255,230,90", "110,240,130", "90,200,255", "190,120,255"];
      g.lineWidth = W * .03; for (let k = 0; k < 6; k++) { g.strokeStyle = `rgba(${cols[k]},.22)`; g.beginPath(); g.arc(W * .5, H * .62, W * (.62 - k * .03), Math.PI, 2 * Math.PI); g.stroke(); }
      puff(g, W * .2, H * .14, W / 330, "#ffffff"); puff(g, W * .82, H * .3, W / 420, "#ffe6f3"); puff(g, W * .55, H * .08, W / 600, "#ffffff");
    },
    land(g, T, W, H) {
      hillW(g, W, H, H * .76, H * .02, 3, .4, T.hills[0]);
      [[.12, .14, "#5cf2ff"], [.86, .17, "#ffd93b"], [.3, .1, "#7dff6b"]].forEach(([x, h, c]) => lolly(g, W * x, H * .82, H * h, c));
      hillW(g, W, H, H * .84, H * .016, 4, 1.8, T.hills[1]);
      hillW(g, W, H, H * .92, H * .01, 6, 2.8, T.hills[2]);
      const r = rng(9); for (let k = 0; k < 7; k++) { const x = W * (.08 + k * .14), y = H * (.9 + r() * .05); g.fillStyle = COLORS[(k * 3) % 7]; g.beginPath(); g.ellipse(x, y, 11, 10, 0, Math.PI, 0); g.fill(); ellipse(g, x - 3, y - 5, 3, 2, "rgba(255,255,255,.6)"); }
    },
    live(g, T, W, H, t, part) {
      if (part === "sky") { const x = ((t * .012) % 1.4 - .2) * W; puff(g, x, H * .46, W / 640, "rgba(255,255,255,.7)"); return; }
      for (let k = 0; k < 12; k++) { const r = rng(k * 19 + 2), x = r() * W, y = r() * H * .7, a = Math.max(0, Math.sin(t * (1 + r()) + k * 2));
        g.fillStyle = `rgba(255,255,255,${.9 * a})`; sparkPath(g, x, y, 6 * a + 1, 1.5); g.fill(); }
    },
  },
  space: {
    sky(g, T, W, H) {
      g.fillStyle = grad(g, H, T.sky); g.fillRect(0, 0, W, H);
      glow(g, W * .75, H * .35, W * .6, "#c058ff", .22); glow(g, W * .2, H * .55, W * .5, "#4d8bff", .2);
      const r = rng(3); for (let k = 0; k < 110; k++) { g.fillStyle = `rgba(255,255,255,${.3 + r() * .6})`; const s = .6 + r() * 1.6; g.fillRect(r() * W, r() * H * .8, s, s); }
      bigPlanet(g, W * .24, H * .17, Math.min(W, H) * .09);
      ellipse(g, W * .85, H * .1, W * .03, W * .03, "#e9e4ff");
    },
    land(g, T, W, H) {
      hillW(g, W, H, H * .85, H * .02, 3, .6, T.hills[0]);
      hillW(g, W, H, H * .91, H * .012, 5, 2, T.hills[1]);
      const r = rng(4); for (let k = 0; k < 6; k++) { const x = r() * W, y = H * (.9 + r() * .07), s = 6 + r() * 10; ellipse(g, x, y, s * 1.6, s * .5, "rgba(10,0,30,.35)"); }
    },
    live(g, T, W, H, t, part) {
      if (part !== "sky") return;
      for (let k = 0; k < 14; k++) { const r = rng(k * 31 + 5), x = r() * W, y = r() * H * .75, a = Math.max(0, Math.sin(t * (.8 + r()) + k));
        g.fillStyle = `rgba(255,255,255,${a})`; sparkPath(g, x, y, 5 * a + 1, 1.2); g.fill(); }
      const key = W + "x" + H; SCENE.space.met[key] = SCENE.space.met[key] || { list: [], next: 0 }; drawMeteors(g, t, W, H, false, SCENE.space.met[key]);
    },
    met: {},
  },
};
const _paintSky = paintSky, _paintLand = paintLand, _paintLive = paintLive;
paintSky = function (g, T, W, H, moon) { if (T.custom) return SCENE[T.name].sky(g, T, W, H); return _paintSky(g, T, W, H, moon); };
paintLand = function (g, T, W, H) { if (T.custom) return SCENE[T.name].land(g, T, W, H); return _paintLand(g, T, W, H); };
paintLive = function (g, T, W, H, t, part) { if (T.custom) return SCENE[T.name].live(g, T, W, H, t, part); return _paintLive(g, T, W, H, t, part); };
function sceneCanvas(T, W, H, D, vig) {
  const c = document.createElement("canvas"); c.width = W * D; c.height = H * D;
  const g = c.getContext("2d"); g.setTransform(D, 0, 0, D, 0, 0);
  paintSky(g, T, W, H, false); paintLand(g, T, W, H);
  if (vig) { const v = g.createRadialGradient(W / 2, H * .5, Math.min(W, H) * .3, W / 2, H * .5, Math.max(W, H) * .75);
    v.addColorStop(0, "rgba(0,0,0,0)"); v.addColorStop(1, `rgba(0,0,0,${T.day ? .16 : .35})`); g.fillStyle = v; g.fillRect(0, 0, W, H); }
  return c;
}
const _drawBackdrop = drawBackdrop;
drawBackdrop = function () {
  if (!BW) sizeBg(); const T = themeNow(); if (!T.custom) return _drawBackdrop();
  const keyNow = T.name + BW + "x" + BH;
  if (keyNow !== bgKey) { bgCache = sceneCanvas(T, BW, BH, BD, true); bgKey = keyNow; }
  const g = bctx, t = now / 1000; g.setTransform(1, 0, 0, 1, 0, 0); g.drawImage(bgCache, 0, 0); g.setTransform(BD, 0, 0, BD, 0, 0);
  paintLive(g, T, BW, BH, t, "sky"); paintLive(g, T, BW, BH, t, "ground");
};
const _bandImage = bandImage;
bandImage = function (G, i) {
  const T = THEMES[i % THEMES.length]; if (!T.custom) return _bandImage(G, i);
  let c = mapBands.get(i); if (c) return c;
  if (mapBands.size > 6) mapBands.delete(mapBands.keys().next().value);
  c = sceneCanvas(T, Math.ceil(G.W), Math.ceil(G.band), MPD, false); mapBands.set(i, c); return c;
};
// the menu shows the region the player is in, with its jar and its things dancing inside
let menuBg = null, menuBgKey = "";
const _drawMenu = drawMenu;
drawMenu = function () {
  const T = themeNow(); if (!T.custom) return _drawMenu();
  if (!MW) sizeMenu(); if (!MW) return;
  const g = mctx, tt = now / 1000, key = T.name + MW + "x" + MH;
  if (key !== menuBgKey) { menuBg = sceneCanvas(T, MW, MH, MD, false); menuBgKey = key; }
  g.setTransform(1, 0, 0, 1, 0, 0); g.drawImage(menuBg, 0, 0); g.setTransform(MD, 0, 0, MD, 0, 0);
  paintLive(g, T, MW, MH, tt, "sky"); paintLive(g, T, MW, MH, tt, "ground");
  const J = heroRect(), ground = J.y + J.h * .97, r = J, R = r.w * .11;
  heroBack(g, J, tt, ground);
  for (const f of inJar) { const x = r.cx + Math.sin(tt * f.sp + f.a) * r.w * .3, y = r.y + r.h * .6 + Math.sin(tt * f.sp * 1.4 + f.b) * r.h * .26; f.flap += .25; paintFly(g, x, y, R, f.c, f.flap, true, true, f.a * 10); }
  heroFront(g, J, tt);
  for (const f of outFlies) {
    const e = (f.t + tt * .045) % 1;
    const x = r.cx + Math.sin(e * 6 + f.seed) * MW * .45 * Math.min(1, e * 2.2) + Math.sin(tt * 1.7 + f.seed) * 6, y = r.y + r.h * .08 - e * (r.y + r.h * .1 + 40) + Math.cos(tt * 1.3 + f.seed) * 5;
    g.globalAlpha = Math.min(1, e * 6, (1 - e) * 4); f.flap += .3; paintFly(g, x, y, R * (.55 + .45 * (1 - e)), f.c, f.flap, true, true, f.seed * 7); g.globalAlpha = 1;
  }
};
// TEST BUILD ONLY: tap a chapter's name on the map to jump to its first level
let pvDown = null;
mapCv.addEventListener("pointerdown", e => { pvDown = { x: e.clientX, y: e.clientY }; });
mapCv.addEventListener("pointerup", e => {
  if (!pvDown) return; const moved = Math.hypot(e.clientX - pvDown.x, e.clientY - pvDown.y); pvDown = null; if (moved > 10) return;
  const G = mapGeom(), rc = mapCv.getBoundingClientRect(), y = e.clientY - rc.top + mapScroll;
  for (let i = 0; i < G.n; i++) {
    const sy = bandTop(G, i) + G.step * 10 + G.sign * .5, h = G.sign * .62;
    if (Math.abs(y - sy) < h / 2 + 6) {
      if (i !== Math.floor((save.level - 1) / 10)) { save.level = i * 10 + 1; save.mapCh = i + 1; store(); Snd.play("sfx_unlock"); bgKey = ""; menuBgKey = ""; showMap(mapFrom); try { updateMenu(); } catch (err) {} }
      return;
    }
  }
});

// ---- each region has its own music and sounds (keys like "reef_sfx_select", "reef_music") ----
(function regionSound() {
  const _play = Snd.play;
  Snd.play = function (name, rate, vol, again) {
    let k = name;
    try { const r = themeNow().name + "_" + name; if (SOUND_DATA[r]) k = r; } catch (e) {}
    return _play.call(this, k, rate, vol, again);
  };
  let cur = "music";
  setInterval(() => {
    if (!Snd.musicEl) return;
    let k = "music";
    try { const r = themeNow().name + "_music"; if (SOUND_DATA[r]) k = r; } catch (e) {}
    if (k === cur) return;
    cur = k;
    const was = !Snd.musicEl.paused;
    Snd.musicEl.src = SOUND_DATA[k];
    if (was) { const pr = Snd.musicEl.play(); if (pr && pr.catch) pr.catch(() => {}); }
  }, 400);
})();
