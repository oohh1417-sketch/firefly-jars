// ===================== TEST BUILD: six themed regions =====================
// Each chapter is a region with its own scene, its own things to sort and its own jar.
// Same levels and rules. Added on top of the normal game by tools/web/edit_regions.py.
let HUB = 0, FORCE_KIND = null;   // set while drawing the hub (loading screen and menu)
const REGIONS = [
  { name: "reef", stone: "#0b5470e6", custom: 1, day: 1, title: "Bubble Reef", item: "fish", jar: "tube", deco: "bubbles",
    sky: ["#8af3ea", "#2ec7d7", "#0e86ae"], hills: ["#f2d9a0", "#e0bf80", "#2e9e6a"], glow: "#bff9ff",
    cap: ["#a8574c", "#f29b8a", "#ffe6df"], shelf: ["#e9cf94", "#b98f55", "#fff1cc"] },
  { name: "sunpetal", stone: "#7a3a22e6", custom: 1, day: 1, title: "Sunpetal Meadow", item: "flower", jar: "vase", deco: "clay",
    sky: ["#ff8f8f", "#ffb877", "#ffe3a3"], hills: ["#a6d872", "#86c45c", "#62a843"], glow: "#ffb347",
    cap: ["#8c3f22", "#d9744a", "#ffc7a6"], shelf: ["#a86b3c", "#6e4223", "#c98a55"] },
  { name: "grove", stone: "#1e4a2ce6", custom: 1, title: "Lantern Grove", item: "gem", jar: "mason", deco: "lantern",
    sky: ["#2f7a4f", "#1e5b3c", "#123826"], hills: ["#1b5233", "#2c5e2a", "#16391f"], glow: "#7dffd0",
    cap: ["#5a3c1c", "#c9a45a", "#f5e0a0"], shelf: ["#5a3d22", "#3a2614", "#6fae4b"] },
  Object.assign({}, THEMES[0], { title: "Firefly Night", item: "fly", jar: "mason", deco: "twine" }),
  { name: "candy", stone: "#a33a78e6", custom: 1, day: 1, title: "Candy Clouds", item: "candy", jar: "tube", deco: "stripes", line: "rgba(255,255,255,.9)",
    sky: ["#ff8fc8", "#ffaed6", "#ffd0e8"], hills: ["#ff7fbd", "#ffa3cf", "#fff2f8"], glow: "#ff8fc8",
    cap: ["#c2407a", "#ff7fb5", "#ffe0ee"], shelf: ["#f7c9a0", "#d99a6a", "#fff0e0"] },
  { name: "space", stone: "#2e1a66e6", custom: 1, title: "Starlight Space", item: "planet", jar: "tube", deco: "metal",
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
  const kind = FORCE_KIND || themeNow().item || "fly";
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
// ---------- each world's own jar: drawn behind the things inside (back) and in front of them (front) ----------
const BRASS = (g, x0, x1) => { const b = g.createLinearGradient(x0, 0, x1, 0); b.addColorStop(0, "#7a5a20"); b.addColorStop(.45, "#f3d98c"); b.addColorStop(1, "#80601f"); return b; };
const STEEL = (g, x0, x1) => { const b = g.createLinearGradient(x0, 0, x1, 0); b.addColorStop(0, "#4a5068"); b.addColorStop(.4, "#eef2ff"); b.addColorStop(1, "#3e4460"); return b; };
function shellPath(g, cx, cy, s) {
  g.beginPath(); g.moveTo(cx, cy + s * .5);
  for (let k = 0; k <= 6; k++) { const a = Math.PI * (1.1 + k * .8 / 6), px = cx + Math.cos(a) * s, py = cy + s * .5 + Math.sin(a) * s;
    if (k) { const am = Math.PI * (1.1 + (k - .5) * .8 / 6); g.quadraticCurveTo(cx + Math.cos(am) * s * 1.12, cy + s * .5 + Math.sin(am) * s * 1.12, px, py); } else g.lineTo(px, py); }
  g.closePath();
}
function daisy(g, cx, cy, s, petal, mid) {
  g.fillStyle = petal; for (let k = 0; k < 6; k++) { const a = k * Math.PI / 3; ellipse(g, cx + Math.cos(a) * s * .55, cy + Math.sin(a) * s * .55, s * .42, s * .42, petal); }
  ellipse(g, cx, cy, s * .38, s * .38, mid);
}
function leaf(g, x, y, s, rot, col) { g.save(); g.translate(x, y); g.rotate(rot); g.fillStyle = col; g.beginPath(); g.moveTo(0, 0); g.quadraticCurveTo(s * .5, -s * .45, s, 0); g.quadraticCurveTo(s * .5, s * .45, 0, 0); g.fill(); g.restore(); }
function regionBack(g, r, deco, i) {
  const x = r.x, w = r.w, top = r.y, bot = r.y + r.h, t = now / 1000;
  g.save(); jarPath(g, r); g.clip();
  if (deco === "bubbles") {
    const wy = top + w * .34, wg = g.createLinearGradient(0, wy, 0, bot);
    wg.addColorStop(0, "rgba(120,235,255,.16)"); wg.addColorStop(1, "rgba(20,140,210,.34)");
    g.fillStyle = wg; g.beginPath(); g.moveTo(x, wy);
    for (let k = 0; k <= 8; k++) g.lineTo(x + w * k / 8, wy + Math.sin(t * 2.2 + k * 1.3 + i) * w * .025);
    g.lineTo(x + w, bot); g.lineTo(x, bot); g.closePath(); g.fill();
    g.strokeStyle = "rgba(230,255,255,.55)"; g.lineWidth = Math.max(1, w * .03); g.beginPath();
    for (let k = 0; k <= 8; k++) g.lineTo(x + w * k / 8, wy + Math.sin(t * 2.2 + k * 1.3 + i) * w * .025); g.stroke();
    // sand on the bottom
    const sg = g.createLinearGradient(0, bot - w * .16, 0, bot); sg.addColorStop(0, "#f8e2ab"); sg.addColorStop(1, "#d6ad62");
    g.fillStyle = sg; g.beginPath(); g.moveTo(x, bot - w * .1); g.quadraticCurveTo(x + w * .3, bot - w * .17, x + w * .55, bot - w * .11); g.quadraticCurveTo(x + w * .8, bot - w * .06, x + w, bot - w * .13); g.lineTo(x + w, bot); g.lineTo(x, bot); g.closePath(); g.fill();
    // little bubbles rising through the water
    g.strokeStyle = "rgba(255,255,255,.6)"; g.lineWidth = Math.max(.8, w * .022);
    for (let k = 0; k < 4; k++) { const p = (t * .35 + k * .27 + i * .13) % 1, yy = bot - w * .15 - p * (bot - w * .15 - wy), xx = x + w * (.18 + .64 * ((k * .37 + i * .21) % 1)) + Math.sin(t * 3 + k) * w * .04;
      g.beginPath(); g.arc(xx, yy, w * (.03 + .015 * (k % 2)), 0, 6.283); g.stroke(); }
  } else if (deco === "clay") {
    g.fillStyle = "rgba(255,205,150,.10)"; g.fillRect(x, top, w, r.h);
  } else if (deco === "lantern") {
    glow(g, x + w / 2, bot - w * .4, w * 1.1, "#ffcf5a", .2 + .05 * Math.sin(t * 7 + i * 2) * Math.sin(t * 3.1 + i));
  } else if (deco === "stripes") {
    g.fillStyle = "rgba(255,175,215,.12)"; g.fillRect(x, top, w, r.h);
    const sy = bot - w * .16; g.fillStyle = "rgba(255,255,255,.7)"; g.fillRect(x, sy, w, w * .16);
    g.fillStyle = "rgba(255,92,138,.6)"; for (let k = -1; k < 6; k++) { g.beginPath(); g.moveTo(x + k * w * .22, bot); g.lineTo(x + k * w * .22 + w * .1, bot); g.lineTo(x + k * w * .22 + w * .26, sy); g.lineTo(x + k * w * .22 + w * .16, sy); g.closePath(); g.fill(); }
  } else if (deco === "metal") {
    const sg = g.createLinearGradient(0, top, 0, bot); sg.addColorStop(0, "rgba(90,40,160,0)"); sg.addColorStop(1, "rgba(90,40,160,.3)");
    g.fillStyle = sg; g.fillRect(x, top, w, r.h);
    for (let k = 0; k < 6; k++) { const a = .3 + .7 * Math.abs(Math.sin(t * 1.5 + k * 1.7 + i)); g.fillStyle = `rgba(255,255,255,${a * .8})`; g.fillRect(x + w * (.15 + ((k * .41 + i * .17) % .7)), top + r.h * (.25 + ((k * .23 + i * .11) % .65)), 1.5, 1.5); }
  }
  g.restore();
  if (deco === "metal") {   // back half of the ring around the capsule
    g.strokeStyle = "rgba(205,175,255,.38)"; g.lineWidth = Math.max(2, w * .07);
    g.beginPath(); g.ellipse(x + w / 2, top + r.h * .56, w * .68, w * .15, -.12, Math.PI, 2 * Math.PI); g.stroke();
  }
}
// true while a jar with its lid on is drawn (Sunpetal hides the side daisy then)
let CORKED = false;
// the front half of Sunpetal's clay rim, drawn again over the cork so the cork sits inside the neck
function clayLip(g, cx, top, w) {
  const x = cx - w / 2, lg = g.createLinearGradient(0, top + w * .02, 0, top + w * .09); lg.addColorStop(0, "#e08a62"); lg.addColorStop(1, "#b9562f");
  g.save(); g.fillStyle = lg; roundRect(g, x + w * .06, top + w * .02, w * .88, w * .07, w * .035, w * .035); g.fill();
  g.strokeStyle = "rgba(110,40,15,.6)"; g.lineWidth = Math.max(1, w * .025); g.stroke();
  for (let k = 0; k < 6; k++) ellipse(g, x + w * (.17 + k * .133), top + w * .055, w * .018, w * .018, "#fff3dc");
  g.restore();
}
function regionDeco(g, r, deco, i) {
  const x = r.x, w = r.w, top = r.y, bot = r.y + r.h, lw = Math.max(1.5, w * .04), t = now / 1000;
  g.save(); g.lineCap = "round"; g.lineJoin = "round";
  if (deco === "bubbles") {
    // coral collar around the rim, with a shell in front
    const cg = g.createLinearGradient(0, top - w * .05, 0, top + w * .1); cg.addColorStop(0, "#ffc0b0"); cg.addColorStop(1, "#e2665a");
    g.fillStyle = cg; roundRect(g, x - w * .01, top - w * .04, w * 1.02, w * .13, w * .065, w * .065); g.fill();
    g.strokeStyle = "rgba(140,45,40,.55)"; g.lineWidth = Math.max(1, w * .025); g.stroke();
    for (let k = 0; k < 5; k++) ellipse(g, x + w * (.12 + k * .19), top + w * .025, w * .022, w * .022, "rgba(255,240,230,.85)");
    shellPath(g, x + w * .5, top - w * .02, w * .16); g.fillStyle = "#fff1e2"; g.fill(); g.strokeStyle = "#d9826e"; g.lineWidth = Math.max(1, w * .022); g.stroke();
    for (let k = 1; k < 5; k++) { const a = Math.PI * (1.1 + k * .8 / 5); g.beginPath(); g.moveTo(x + w * .5, top + w * .06); g.lineTo(x + w * .5 + Math.cos(a) * w * .13, top + w * .06 + Math.sin(a) * w * .13); g.stroke(); }
    // bubbles floating up beside the tube
    g.strokeStyle = "rgba(255,255,255,.8)"; g.lineWidth = Math.max(1, w * .025);
    for (const [bx, by, br, sp] of [[1.1, .45, .07, 0], [1.18, .25, .045, 1], [1.1, .1, .03, 2]]) { g.beginPath(); g.arc(x + w * bx + Math.sin(t * 2 + sp) * w * .02, top + w * by, w * br, 0, 6.283); g.stroke(); }
    // a starfish and seaweed at the foot
    g.strokeStyle = "#2ea36a"; g.lineWidth = Math.max(1.5, w * .05);
    g.beginPath(); g.moveTo(x + w * .9, bot + w * .02); g.quadraticCurveTo(x + w * 1.08 + Math.sin(t * 1.6 + i) * w * .05, bot - w * .2, x + w * .98, bot - w * .4); g.stroke();
    starPath(g, x + w * .06, bot - w * .02, w * .14, w * .06); g.fillStyle = "#ff9f43"; g.fill(); g.strokeStyle = "#c8651c"; g.lineWidth = Math.max(1, w * .02); g.stroke();
  } else if (deco === "clay") {
    // painted terracotta rim
    const rim = g.createLinearGradient(0, top - w * .04, 0, top + w * .1); rim.addColorStop(0, "#f2a27b"); rim.addColorStop(1, "#b9562f");
    g.fillStyle = rim; roundRect(g, x + w * .06, top - w * .03, w * .88, w * .12, w * .05, w * .05); g.fill(); g.strokeStyle = "rgba(110,40,15,.6)"; g.lineWidth = Math.max(1, w * .025); g.stroke();
    for (let k = 0; k < 6; k++) ellipse(g, x + w * (.17 + k * .133), top + w * .03, w * .02, w * .02, "#fff3dc");
    // twine wrapped around the neck, with a daisy tucked in
    g.strokeStyle = "#caa06a"; g.lineWidth = Math.max(1.2, w * .035);
    for (let k = 0; k < 3; k++) { const yy = top + w * (.13 + k * .05); g.beginPath(); g.moveTo(x + w * .15, yy + w * .03); g.lineTo(x + w * .85, yy); g.stroke(); }
    if (!CORKED) daisy(g, x + w * .84, top + w * .17, w * .13, "#ffffff", "#ffc93b");
    // a painted vine climbing the glass
    g.strokeStyle = "rgba(80,160,60,.75)"; g.lineWidth = Math.max(1, w * .025);
    g.beginPath(); g.moveTo(x + w * .86, bot - w * .1); g.bezierCurveTo(x + w * .7, bot - r.h * .3, x + w * .95, top + r.h * .5, x + w * .82, top + r.h * .3); g.stroke();
    for (const [fy, rot] of [[.75, -2.4], [.55, -.6], [.38, -2.5]]) leaf(g, x + w * .84, top + r.h * fy, w * .16, rot, "rgba(110,190,80,.85)");
    // terracotta foot with a dotted band
    const fg = g.createLinearGradient(0, bot - w * .06, 0, bot + w * .08); fg.addColorStop(0, "#e88a5e"); fg.addColorStop(1, "#9c4524");
    g.fillStyle = fg; roundRect(g, x + w * .1, bot - w * .05, w * .8, w * .12, w * .05, w * .05); g.fill(); g.strokeStyle = "rgba(110,40,15,.6)"; g.lineWidth = Math.max(1, w * .02); g.stroke();
    for (let k = 0; k < 5; k++) ellipse(g, x + w * (.22 + k * .14), bot + w * .01, w * .018, w * .018, "#fff3dc");
  } else if (deco === "lantern") {
    // brass lantern frame: two side posts with rivets and a little vine
    const dark = "rgba(60,38,10,.85)"; g.lineWidth = Math.max(1, w * .022); g.strokeStyle = dark;
    for (const sx of [-.05, .95]) {
      g.fillStyle = BRASS(g, x + w * sx, x + w * (sx + .1)); roundRect(g, x + w * sx, top + w * .2, w * .1, r.h - w * .26, w * .04, w * .04); g.fill(); g.stroke();
      for (const fy of [.3, .55, .8]) ellipse(g, x + w * (sx + .05), top + r.h * fy, w * .025, w * .025, "#5a4012");
    }
    // top band and base plate with feet
    g.fillStyle = BRASS(g, x - w * .08, x + w * 1.08); roundRect(g, x - w * .08, top + w * .1, w * 1.16, w * .12, w * .05, w * .05); g.fill(); g.stroke();
    g.fillStyle = BRASS(g, x - w * .1, x + w * 1.1); roundRect(g, x - w * .1, bot - w * .1, w * 1.2, w * .15, w * .05, w * .05); g.fill(); g.stroke();
    for (const fx of [-.04, .86]) { g.fillStyle = "#6b4c16"; roundRect(g, x + w * fx, bot + w * .04, w * .18, w * .07, 0, w * .04); g.fill(); }
    // the bail handle on top
    g.strokeStyle = BRASS(g, x + w * .2, x + w * .8); g.lineWidth = Math.max(1.5, w * .055);
    g.beginPath(); g.moveTo(x - w * .02, top + w * .16); g.bezierCurveTo(x - w * .02, top - w * .5, x + w * 1.02, top - w * .5, x + w * 1.02, top + w * .16); g.stroke();
    // ivy on the posts
    g.strokeStyle = "#3f8a2e"; g.lineWidth = Math.max(1, w * .025);
    g.beginPath(); g.moveTo(x, bot - w * .1); g.bezierCurveTo(x - w * .12, bot - r.h * .25, x + w * .1, top + r.h * .55, x - w * .03, top + r.h * .4); g.stroke();
    for (const [fy, rot] of [[.78, 3.6], [.62, -.4], [.47, 3.3]]) leaf(g, x - w * .02, top + r.h * fy, w * .17, rot, "#5cb23f");
    glow(g, x + w / 2, bot - w * .05, w * .6, "#ffd36a", .16);
  } else if (deco === "twine") {
    // the classic jar: twine wrapped twice around the neck, and a little paper tag hanging from it
    g.strokeStyle = "#c9a36a"; g.lineWidth = Math.max(1.2, w * .035);
    for (let k = 0; k < 2; k++) { g.beginPath(); g.ellipse(x + w / 2, top + w * (.05 + k * .045), w * .41, w * .06, 0, .05, Math.PI - .05); g.stroke(); }
    const tx = x + w * .88, ty = top + w * .1, sw = Math.sin(t * 1.4 + i) * .08;
    g.lineWidth = Math.max(1, w * .03); g.beginPath(); g.moveTo(tx, ty); g.lineTo(tx + w * .1, ty + w * .2); g.stroke();
    g.save(); g.translate(tx + w * .1, ty + w * .2); g.rotate(.15 + sw);
    g.fillStyle = "#f6ecd0"; roundRect(g, -w * .11, 0, w * .22, w * .27, w * .03, w * .03); g.fill(); g.strokeStyle = "rgba(120,90,40,.6)"; g.lineWidth = Math.max(1, w * .02); g.stroke();
    ellipse(g, 0, w * .035, w * .02, w * .02, "rgba(120,90,40,.7)");
    starPath(g, 0, w * .15, w * .07, w * .03); g.fillStyle = "#ffc93b"; g.fill(); g.restore();
  } else if (deco === "stripes") {
    // pink icing around the rim, dripping down the glass, with sprinkles
    g.fillStyle = "#ff8fc0"; g.beginPath(); g.moveTo(x - w * .02, top - w * .04); g.lineTo(x + w * 1.02, top - w * .04); g.lineTo(x + w * 1.02, top + w * .1);
    for (let k = 5; k >= 0; k--) { const dx = x + w * (k / 5) * 1.0, dl = [.1, .22, .12, .28, .14, .1][k]; g.quadraticCurveTo(dx + w * .1, top + w * .1, dx + w * .02, top + w * (.1 + dl)); g.arc(dx, top + w * (.1 + dl), w * .025, 0, Math.PI); }
    g.closePath(); g.fill();
    g.fillStyle = "rgba(255,255,255,.55)"; roundRect(g, x + w * .05, top - w * .03, w * .9, w * .03, w * .015, w * .015); g.fill();
    for (const [sx, sy, c] of [[.15, .03, "#7dff6b"], [.35, .06, "#5cf2ff"], [.55, .02, "#ffd93b"], [.75, .05, "#ffffff"], [.9, .02, "#b98cff"]]) { g.save(); g.translate(x + w * sx, top + w * sy); g.rotate(sx * 9); g.fillStyle = c; roundRect(g, -w * .045, -w * .015, w * .09, w * .03, w * .015, w * .015); g.fill(); g.restore(); }
    // twisted candy-wrapper ends on both sides
    for (const s of [-1, 1]) {
      const ex = s < 0 ? x - w * .02 : x + w * 1.02, ey = top + w * .03;
      g.fillStyle = s < 0 ? "#ffd93b" : "#5cf2ff"; g.beginPath(); g.moveTo(ex, ey);
      g.lineTo(ex + s * w * .2, ey - w * .13);
      for (let k = 0; k < 3; k++) { const y0 = ey - w * .13 + k * w * .1; g.quadraticCurveTo(ex + s * w * .3, y0 + w * .05, ex + s * w * .2, y0 + w * .1); }
      g.lineTo(ex, ey + w * .04); g.closePath(); g.fill(); g.fillStyle = "rgba(0,0,0,.12)"; ellipse(g, ex + s * w * .02, ey + w * .02, w * .035, w * .05, "rgba(0,0,0,.15)");
      g.strokeStyle = "rgba(255,255,255,.7)"; g.lineWidth = Math.max(1, w * .02); g.beginPath(); g.moveTo(ex + s * w * .03, ey); g.lineTo(ex + s * w * .16, ey - w * .06); g.moveTo(ex + s * w * .03, ey + w * .02); g.lineTo(ex + s * w * .16, ey + w * .1); g.stroke();
    }
  } else if (deco === "metal") {
    // front half of the ring, a metal collar with a blinking antenna, and a thruster base
    g.strokeStyle = "rgba(220,195,255,.85)"; g.lineWidth = Math.max(2, w * .07);
    g.beginPath(); g.ellipse(x + w / 2, top + r.h * .56, w * .68, w * .15, -.12, 0, Math.PI); g.stroke();
    g.strokeStyle = "rgba(255,255,255,.6)"; g.lineWidth = Math.max(1, w * .02); g.beginPath(); g.ellipse(x + w / 2, top + r.h * .56, w * .68, w * .15, -.12, .3, 1.2); g.stroke();
    g.fillStyle = STEEL(g, x - w * .04, x + w * 1.04); roundRect(g, x - w * .04, top - w * .03, w * 1.08, w * .12, w * .05, w * .05); g.fill();
    g.fillStyle = "#2c3147"; for (const k of [.15, .5, .85]) ellipse(g, x + w * k, top + w * .03, w * .02, w * .02, "#2c3147");
    g.strokeStyle = "#9aa4c4"; g.lineWidth = Math.max(1, w * .03); g.beginPath(); g.moveTo(x + w * .85, top - w * .03); g.lineTo(x + w * .98, top - w * .3); g.stroke();
    const on = Math.sin(t * 4 + i) > 0; glow(g, x + w * .98, top - w * .32, w * .2, on ? "#ff5c8a" : "#5cf2ff", .5); ellipse(g, x + w * .98, top - w * .32, w * .045, w * .045, on ? "#ff8fb0" : "#aaf8ff");
    for (const s of [-1, 1]) { g.fillStyle = "#6a5aa8"; g.beginPath(); const fx = s < 0 ? x + w * .06 : x + w * .94; g.moveTo(fx, bot - w * .5); g.lineTo(fx + s * w * .2, bot - w * .05); g.lineTo(fx + s * w * .2, bot + w * .06); g.lineTo(fx, bot - w * .08); g.closePath(); g.fill(); }
    g.fillStyle = STEEL(g, x + w * .05, x + w * .95); roundRect(g, x + w * .08, bot - w * .06, w * .84, w * .12, w * .03, w * .06); g.fill();
    glow(g, x + w / 2, bot + w * .1, w * .45, "#5cf2ff", .35 + .1 * Math.sin(t * 6 + i));
  }
  g.restore();
}
const _pjb = paintJarBack;
paintJarBack = function (g, r, St, i) { _pjb(g, r, St, i); const T = themeNow(); if (T.deco) regionBack(g, r, T.deco, i); };
const _pjf = paintJarFront;
paintJarFront = function (g, r, St, i, R) { const T = themeNow(); CORKED = !r.tip && ((corks[i] !== undefined && St.jars[i].length > 0) || St.locks[i] > 0); if (T.deco) regionDeco(g, r, T.deco, i); _pjf(g, r, St, i, R); CORKED = false; };
const _shelf = paintShelf;
paintShelf = function (g, sh) {
  const T = themeNow(); if (!T.shelf) return _shelf(g, sh);
  const x = sh.x, y = sh.y, w = sh.w, h = Math.max(sh.h * 1.7, 12), t = now / 1000, r = rng(Math.round(y) + 3), n = T.name;
  g.fillStyle = "rgba(0,0,0,.22)"; g.beginPath(); g.ellipse(x + w / 2, y + h * 1.35, w * .5, h * .45, 0, 0, 6.283); g.fill();
  g.save(); g.lineJoin = "round"; g.lineCap = "round";
  const bumpy = (yy, amp, step, ph) => { for (let xx = x; xx <= x + w + .1; xx += step) g.lineTo(xx, yy + Math.sin(xx * .13 + ph) * amp + Math.sin(xx * .37 + ph * 2) * amp * .5); };
  if (n === "reef") {   // a coral rock ledge with sand on top
    g.beginPath(); g.moveTo(x, y + h * .2); bumpy(y, 1.2, 6, 1); g.lineTo(x + w, y + h * .5);
    for (let xx = x + w; xx >= x; xx -= 9) g.lineTo(xx, y + h + Math.abs(Math.sin(xx * .09)) * h * .45); g.closePath();
    const rg = g.createLinearGradient(0, y, 0, y + h * 1.4); rg.addColorStop(0, "#f6b9a3"); rg.addColorStop(1, "#b9645a"); g.fillStyle = rg; g.fill();
    g.strokeStyle = "rgba(120,45,40,.5)"; g.lineWidth = 1.2; g.stroke();
    for (let k = 0; k < Math.floor(w / 16); k++) ellipse(g, x + r() * w, y + h * (.45 + r() * .5), 1.5 + r() * 2, 1 + r() * 1.5, "rgba(120,40,40,.35)");
    g.fillStyle = "#f8e2ab"; g.beginPath(); g.moveTo(x + 2, y + 2); bumpy(y - 1, 1, 6, 1); g.lineTo(x + w - 2, y + 4); g.lineTo(x + 2, y + 4); g.closePath(); g.fill();
    for (let k = 0; k < Math.floor(w / 40); k++) { const bx = x + 8 + r() * (w - 16), by = y + h * (.5 + r() * .4); g.fillStyle = "#fff4ec"; g.beginPath(); g.arc(bx, by, 2.2, Math.PI, 0); g.fill(); }
  } else if (n === "sunpetal") {   // a wooden garden plank with moss and little flowers
    const wg = g.createLinearGradient(0, y, 0, y + h); wg.addColorStop(0, "#c48850"); wg.addColorStop(1, "#7a4a26");
    g.fillStyle = wg; roundRect(g, x, y + 2, w, h - 2, 3, 3); g.fill(); g.strokeStyle = "rgba(70,35,12,.6)"; g.lineWidth = 1.2; g.stroke();
    g.strokeStyle = "rgba(70,35,12,.35)"; g.lineWidth = 1; for (let k = 0; k < 3; k++) { const yy = y + h * (.45 + k * .17); g.beginPath(); g.moveTo(x + 6 + r() * 20, yy); g.quadraticCurveTo(x + w / 2, yy + (r() - .5) * 3, x + w - 6 - r() * 20, yy); g.stroke(); }
    for (const nx of [x + 6, x + w - 6]) ellipse(g, nx, y + h * .6, 1.6, 1.6, "#4a2c12");
    g.fillStyle = "#79bf55"; g.beginPath(); g.moveTo(x + 2, y + 4); for (let xx = x + 2; xx <= x + w - 2; xx += 5) g.lineTo(xx, y + 1 - Math.abs(Math.sin(xx * .21)) * 2.5 - (r() < .3 ? 1.5 : 0)); g.lineTo(x + w - 2, y + 5); g.lineTo(x + 2, y + 5); g.closePath(); g.fill();
    for (let k = 0; k < Math.floor(w / 22); k++) ellipse(g, x + 6 + r() * (w - 12), y + 1 + r() * 2, 1.6, 1.6, ["#ffffff", "#ff8fc8", "#ffd93b"][k % 3]);
  } else if (n === "grove") {   // a mossy log with a glowing mushroom
    const lg = g.createLinearGradient(0, y, 0, y + h); lg.addColorStop(0, "#7a5532"); lg.addColorStop(.5, "#5a3c20"); lg.addColorStop(1, "#38240f");
    g.fillStyle = lg; roundRect(g, x, y + 1, w, h, h / 2, h / 2); g.fill();
    g.strokeStyle = "rgba(30,18,6,.55)"; g.lineWidth = 1; for (let k = 0; k < Math.floor(w / 12); k++) { const bx = x + h / 2 + r() * (w - h); g.beginPath(); g.moveTo(bx, y + h * .3); g.lineTo(bx + 4, y + h * .8); g.stroke(); }
    for (const ex of [x + h * .45, x + w - h * .45]) { ellipse(g, ex, y + 1 + h / 2, h * .32, h * .45, "#c99a62"); g.strokeStyle = "rgba(110,70,30,.7)"; g.beginPath(); g.ellipse(ex, y + 1 + h / 2, h * .18, h * .26, 0, 0, 6.283); g.stroke(); }
    g.fillStyle = "#4f9a3a"; g.beginPath(); g.moveTo(x + h / 2, y + 4); for (let xx = x + h / 2; xx <= x + w - h / 2; xx += 5) g.lineTo(xx, y + 1 - Math.abs(Math.sin(xx * .17 + 1)) * 2.5); g.lineTo(x + w - h / 2, y + 5); g.closePath(); g.fill();
    const mx = x + w * .85; glow(g, mx, y - 3, 14, "#7dffd0", .35 + .1 * Math.sin(t * 2)); g.fillStyle = "#e9f7ff"; g.fillRect(mx - 1, y - 4, 2, 5); g.fillStyle = "#7dffd0"; g.beginPath(); g.arc(mx, y - 4, 4, Math.PI, 0); g.fill();
  } else if (n === "candy") {   // a wafer with pink frosting and sprinkles
    g.fillStyle = "#e8b77a"; roundRect(g, x, y + 2, w, h - 1, 3, 3); g.fill();
    g.save(); roundRect(g, x, y + 2, w, h - 1, 3, 3); g.clip(); g.strokeStyle = "rgba(170,105,45,.55)"; g.lineWidth = 1;
    for (let xx = x - h; xx < x + w + h; xx += 7) { g.beginPath(); g.moveTo(xx, y); g.lineTo(xx + h, y + h + 2); g.moveTo(xx + h, y); g.lineTo(xx, y + h + 2); g.stroke(); } g.restore();
    g.fillStyle = "#e8458a"; g.beginPath(); g.moveTo(x, y + 4); g.lineTo(x, y); g.lineTo(x + w, y); g.lineTo(x + w, y + 4);
    for (let xx = x + w; xx > x; xx -= 10) { const d = 2 + (Math.round(xx) % 3) * 2; g.quadraticCurveTo(xx - 2, y + 4, xx - 3, y + 4 + d); g.arc(xx - 5, y + 4 + d, 2, 0, Math.PI); g.lineTo(xx - 10, y + 4); } g.closePath(); g.fill();
    for (let k = 0; k < Math.floor(w / 10); k++) { g.fillStyle = COLORS[k % 7]; g.fillRect(x + r() * w, y + .5 + r() * 2, 3, 1.5); }
  } else if (n === "space") {   // a floating metal platform with lights and thrusters
    for (const fx of [.2, .5, .8]) { const fl = 6 + Math.sin(t * 20 + fx * 9) * 2; const fg = g.createLinearGradient(0, y + h, 0, y + h + fl * 2); fg.addColorStop(0, "rgba(120,240,255,.9)"); fg.addColorStop(1, "rgba(120,140,255,0)");
      g.fillStyle = fg; g.beginPath(); g.moveTo(x + w * fx - 4, y + h); g.lineTo(x + w * fx + 4, y + h); g.lineTo(x + w * fx, y + h + fl * 2); g.closePath(); g.fill(); }
    glow(g, x + w / 2, y + h + 6, w * .4, "#5cf2ff", .2);
    g.fillStyle = STEEL(g, x, x + w); g.beginPath(); g.moveTo(x, y + 1); g.lineTo(x + w, y + 1); g.lineTo(x + w - h * .6, y + h); g.lineTo(x + h * .6, y + h); g.closePath(); g.fill();
    g.fillStyle = "rgba(255,255,255,.75)"; g.fillRect(x + 2, y + 1, w - 4, 1.5);
    for (let k = 0; k < Math.floor(w / 26); k++) { const lx = x + 14 + k * 26, on = Math.sin(t * 3 + k) > 0; ellipse(g, lx, y + h * .55, 1.8, 1.8, on ? "#5cf2ff" : "#ff5c8a"); if (on) glow(g, lx, y + h * .55, 6, "#5cf2ff", .5); }
  }
  g.restore();
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
// ---------- Jar World hub: the loading screen and the main menu show every world, not just one ----------
const MIX = ["fish", "flower", "gem", "fly", "candy", "planet"];
const _themeNow = themeNow;
themeNow = function () {
  if (HUB) return THEMES[3];
  // after a win the level number has already moved on: keep the world of the level just solved until the next one starts
  if (mode === "level" && won && save.level > 1) return THEMES[Math.floor((save.level - 2) / 10) % THEMES.length];
  return _themeNow();
};   // the hub jar is the classic glass jar with the gold lid
function mixFly(kind, ...a) { FORCE_KIND = kind; try { paintFly(...a); } finally { FORCE_KIND = null; } }
const hubStars = Array.from({ length: 90 }, (_, i) => { const r = rng(i * 29 + 5); return [r(), r(), r() * 6.28, .6 + r() * 1.3]; });
// a twilight sky: deep blue at the top, purple, then a warm glow at the horizon
function hubSky(g, W, H, T, horizon) {
  const s = g.createLinearGradient(0, 0, 0, horizon);
  s.addColorStop(0, "#0b0a2a"); s.addColorStop(.45, "#271b5c"); s.addColorStop(.75, "#573287"); s.addColorStop(.9, "#a9528e"); s.addColorStop(1, "#f09a7a");
  g.fillStyle = s; g.fillRect(0, 0, W, horizon); g.fillStyle = "#f09a7a"; g.fillRect(0, horizon, W, H - horizon);
  for (const st of hubStars) { const y = st[1] * horizon * .8; const a = (.2 + .55 * Math.abs(Math.sin(T * .6 * st[3] + st[2]))) * (1 - y / horizon); g.fillStyle = `rgba(255,250,235,${a})`; g.fillRect(st[0] * W, y, st[3], st[3]); }
}
function hubLand(g, W, H, T, ground) {
  hillW(g, W, H, ground - H * .11, H * .03, 5, 1.2, "#4a2a72");
  hillW(g, W, H, ground - H * .05, H * .025, 7, 3.1, "#331c5c");
  hillW(g, W, H, ground, H * .012, 4, .4, "#1d1040");
}
// six little glass bubbles, one for each world, floating around the jar
function worldOrb(g, x, y, R, i, T) {
  const Wd = REGIONS[i];
  glow(g, x, y, R * 1.9, Wd.glow, .22);
  g.save(); g.beginPath(); g.arc(x, y, R, 0, 6.283); g.clip();
  const s = g.createLinearGradient(0, y - R, 0, y + R); s.addColorStop(0, Wd.sky[0]); s.addColorStop(.6, Wd.sky[1]); s.addColorStop(1, Wd.sky[2]);
  g.fillStyle = s; g.fillRect(x - R, y - R, R * 2, R * 2);
  ellipse(g, x, y + R * 1.15, R * 1.3, R * .55, Wd.hills[0]);
  g.restore();
  mixFly(Wd.item, g, x, y - R * .04, R * .5, [0, 6, 4, 0, 2, 5][i], T * 8 + i, true, true, i * 3);
  g.strokeStyle = "rgba(255,255,255,.8)"; g.lineWidth = Math.max(1.5, R * .08); g.beginPath(); g.arc(x, y, R, 0, 6.283); g.stroke();
  g.strokeStyle = "rgba(255,255,255,.7)"; g.lineWidth = Math.max(1.5, R * .1); g.lineCap = "round"; g.beginPath(); g.arc(x, y, R * .74, Math.PI * 1.1, Math.PI * 1.4); g.stroke();
}
function hubOrbs(g, W, H, T, spots) {
  const R = Math.min(W * (spots === MENU_ORBS ? .055 : .07), 34);
  spots.forEach(([fx, fy], i) => worldOrb(g, fx * W, fy * H + Math.sin(T * 1.2 + i * 1.7) * 4, R, i, T));
}
const BOOT_ORBS = [[.15, .33], [.85, .33], [.1, .52], [.9, .52], [.16, .71], [.84, .71]];
const BOOT_KINDS = ["fish", "flower", "candy", "planet"];
const MENU_ORBS = [[.13, .2], [.88, .47], [.23, .31], [.75, .56], [.13, .39], [.27, .56]];
drawMenu = function () {
  if (!MW) sizeMenu(); if (!MW) return;
  HUB = 1; try { drawHubMenu(); } finally { HUB = 0; }
};
function drawHubMenu() {
  const g = mctx, tt = now / 1000; g.setTransform(MD, 0, 0, MD, 0, 0);
  const J = heroRect(), ground = J.y + J.h * .97, r = J, R = r.w * .11;
  hubSky(g, MW, MH, tt, ground - MH * .05);
  hubLand(g, MW, MH, tt, ground);
  glow(g, J.cx, J.y + J.h * .55, J.w * 1.9, "#ffcf4a", .2 + .04 * Math.sin(tt * 2));
  hubOrbs(g, MW, MH, tt, MENU_ORBS);
  heroBack(g, J, tt, ground);
  inJar.forEach((f, k) => { const x = r.cx + Math.sin(tt * f.sp + f.a) * r.w * .3, y = r.y + r.h * .6 + Math.sin(tt * f.sp * 1.4 + f.b) * r.h * .26; f.flap += .25; mixFly(MIX[k % 6], g, x, y, R, f.c, f.flap, true, true, f.a * 10); });
  heroFront(g, J, tt);
  outFlies.forEach((f, k) => {
    const e = (f.t + tt * .045) % 1;
    const x = r.cx + Math.sin(e * 6 + f.seed) * MW * .45 * Math.min(1, e * 2.2) + Math.sin(tt * 1.7 + f.seed) * 6, y = r.y + r.h * .08 - e * (r.y + r.h * .1 + 40) + Math.cos(tt * 1.3 + f.seed) * 5;
    g.globalAlpha = Math.min(1, e * 6, (1 - e) * 4); f.flap += .3; mixFly(MIX[k % 6], g, x, y, R * (.55 + .45 * (1 - e)), f.c, f.flap, true, true, f.seed * 7); g.globalAlpha = 1;
  });
}
// <test-only> TEST BUILD ONLY: tap a chapter's name on the map to jump to its first level
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
// </test-only>

// ---- each region has its own music and sounds (keys like "reef_sfx_select", "reef_music") ----
(function regionSound() {
  // A world's own sound is used only when it is ready to play; otherwise the shared sound plays, so a tap is never silent.
  const ready = k => !!SOUND_DATA[k] && ((Snd.ctx && Snd.ctx.state === "running" && Snd.buffers[k]) || (Snd.pools[k] && Snd.pools[k].ok));
  const _play = Snd.play;
  Snd.play = function (name, rate, vol, again) {
    let k = name;
    try { const r = themeNow().name + "_" + name; if (ready(r)) k = r; } catch (e) {}
    return _play.call(this, k, rate, vol, again);
  };
  // Backup players (used when the phone pauses Web Audio) are made only for the shared sounds and the current
  // world, a few at a time inside a tap: making all 45 at once is too much for iPhones and they stay silent.
  const unlockOne = n => {
    if (Snd.pools[n] || !SOUND_DATA[n]) return;
    Snd.pools[n] = [0, 1].map(() => { const el = new window.Audio(SOUND_DATA[n]); el.preload = "auto"; el.setAttribute("playsinline", ""); return el; });
    let left = 2;
    for (const el of Snd.pools[n]) {
      el.muted = true; const pr = el.play();
      const done = () => { el.pause(); el.currentTime = 0; el.muted = false; if (--left === 0) Snd.pools[n].ok = true; };
      if (pr && pr.then) pr.then(done).catch(done); else done();
    }
  };
  Snd.unlockPools = function () {
    this.poolsMade = true;
    for (const n of SFX_NAMES) if (!/^[a-z]+_sfx_/.test(n)) unlockOne(n);
    try { const w = themeNow().name; for (const n of SFX_NAMES) if (n.startsWith(w + "_")) unlockOne(n); } catch (e) {}
  };
  for (const n of SFX_NAMES) if (Snd.pools[n]) Snd.pools[n].ok = true;
  // the music for the world being played; switched inside a tap, and Web Audio woken right after,
  // because on iPhones changing the music can pause the sound effects
  let cur = "music";
  const want = () => { try { const r = themeNow().name + "_music"; if (SOUND_DATA[r]) return r; } catch (e) {} return "music"; };
  const swap = inTap => {
    if (!Snd.musicEl) return;
    const k = want(); if (k === cur) return;
    const was = !Snd.musicEl.paused;
    if (was && !inTap) return;   // wait for the next tap
    cur = k; Snd.musicEl.src = SOUND_DATA[k];
    if (was) { const pr = Snd.musicEl.play(); if (pr && pr.catch) pr.catch(() => {}); }
  };
  document.addEventListener("pointerdown", () => {
    swap(true);
    if (Snd.started && Snd.ctx && Snd.ctx.state !== "running" && Snd.ctx.state !== "closed") Snd.ctx.resume().catch(() => {});
    if (Snd.poolsMade) Snd.unlockPools();   // the current world's backup players, if not made yet
  }, true);
  document.addEventListener("pointerup", () => { if (Snd.started && Snd.ctx && Snd.ctx.state !== "running" && Snd.ctx.state !== "closed") Snd.ctx.resume().catch(() => {}); }, true);
  setInterval(() => swap(false), 400);
})();

// ---------- each world's own lid (the one that closes a full jar, and the locked lid with a number) ----------
const CAP_KIND = { reef: "shell", sunpetal: "cork", grove: "dome", candy: "bonbon", space: "hatch" };
// draws the lid with its bottom edge at (cx, yb); w is the jar width; turn is the screw-on angle
function capShape(g, kind, cx, yb, w, turn) {
  g.save(); g.lineJoin = "round"; g.lineCap = "round";
  const ol = Math.max(1, w * .022);
  if (kind === "shell") {
    const R = w * .5, hy = yb + w * .02;
    g.beginPath(); g.moveTo(cx - R * .25, hy);
    for (let k = 0; k <= 8; k++) { const a = Math.PI * (1.02 + k * .96 / 8), am = Math.PI * (1.02 + (k - .5) * .96 / 8);
      const px = cx + Math.cos(a) * R, py = hy + Math.sin(a) * R * .9;
      if (k === 0) g.lineTo(px, py); else g.quadraticCurveTo(cx + Math.cos(am) * R * 1.1, hy + Math.sin(am) * R * 1.0, px, py); }
    g.lineTo(cx + R * .25, hy); g.closePath();
    const sg = g.createLinearGradient(0, hy - R, 0, hy); sg.addColorStop(0, "#fff2ea"); sg.addColorStop(.6, "#ffc2b2"); sg.addColorStop(1, "#ee8a80");
    g.fillStyle = sg; g.fill(); g.strokeStyle = "#c96a5e"; g.lineWidth = ol; g.stroke();
    g.strokeStyle = "rgba(200,100,90,.55)"; g.lineWidth = Math.max(1, w * .018);
    for (let k = 1; k < 8; k++) { const a = Math.PI * (1.02 + k * .96 / 8); g.beginPath(); g.moveTo(cx, hy); g.lineTo(cx + Math.cos(a) * R * .95, hy + Math.sin(a) * R * .85); g.stroke(); }
    g.fillStyle = "#e9877b"; roundRect(g, cx - R * .3, hy - w * .03, R * .6, w * .07, w * .03, w * .03); g.fill();
    glow(g, cx, hy - R * .92, w * .2, "#ffffff", .5);
    const pg = g.createRadialGradient(cx - w * .02, hy - R * .95, 1, cx, hy - R * .92, w * .07); pg.addColorStop(0, "#ffffff"); pg.addColorStop(1, "#d9d2f0");
    g.fillStyle = pg; g.beginPath(); g.arc(cx, hy - R * .92, w * .065, 0, 6.283); g.fill();
  } else if (kind === "cork") {
    const h = w * .3, tw = w * .8, bw = w * .68, top = yb - h;
    g.beginPath(); g.moveTo(cx - bw / 2, yb); g.lineTo(cx - tw / 2, top + w * .03); g.lineTo(cx + tw / 2, top + w * .03); g.lineTo(cx + bw / 2, yb); g.closePath();
    const cg = g.createLinearGradient(cx - tw / 2, 0, cx + tw / 2, 0); cg.addColorStop(0, "#a8703c"); cg.addColorStop(.4, "#e8b77a"); cg.addColorStop(1, "#9a6534");
    g.fillStyle = cg; g.fill(); g.strokeStyle = "rgba(90,50,20,.7)"; g.lineWidth = ol; g.stroke();
    const rr = rng(7); g.fillStyle = "rgba(110,65,25,.45)"; for (let k = 0; k < 14; k++) { const u = rr(), v = rr(); g.fillRect(cx - bw / 2 + u * bw, top + w * .06 + v * h * .8, w * .025, w * .02); }
    ellipse(g, cx, top + w * .03, tw / 2, w * .06, "#f0c58c"); g.strokeStyle = "rgba(90,50,20,.6)"; g.lineWidth = ol; g.beginPath(); g.ellipse(cx, top + w * .03, tw / 2, w * .06, 0, 0, 6.283); g.stroke();
    leaf(g, cx, top + w * .01, w * .22, -2.7, "#5cb23f"); leaf(g, cx, top + w * .01, w * .22, -.4, "#6fc24c");
    g.save(); g.translate(cx, top - w * .02); g.rotate(turn * .15); daisy(g, 0, 0, w * .13, "#ffffff", "#ffc93b"); g.restore();
  } else if (kind === "dome") {
    const bh = w * .11, top = yb - bh;
    g.fillStyle = BRASS(g, cx - w * .5, cx + w * .5); roundRect(g, cx - w * .5, top, w, bh, w * .03, w * .03); g.fill(); g.strokeStyle = "rgba(60,38,10,.8)"; g.lineWidth = ol; g.stroke();
    for (const k of [-.36, -.12, .12, .36]) ellipse(g, cx + w * k, top + bh / 2, w * .022, w * .022, "#5a4012");
    g.beginPath(); g.moveTo(cx - w * .42, top); g.quadraticCurveTo(cx - w * .4, top - w * .3, cx, top - w * .32); g.quadraticCurveTo(cx + w * .4, top - w * .3, cx + w * .42, top); g.closePath();
    g.fillStyle = BRASS(g, cx - w * .42, cx + w * .42); g.fill(); g.stroke();
    g.strokeStyle = "rgba(255,245,200,.6)"; g.lineWidth = Math.max(1, w * .025); g.beginPath(); g.moveTo(cx - w * .25, top - w * .05); g.quadraticCurveTo(cx - w * .22, top - w * .22, cx - w * .05, top - w * .26); g.stroke();
    ellipse(g, cx, top - w * .34, w * .06, w * .05, "#d9b865");
    g.strokeStyle = "#d9b865"; g.lineWidth = Math.max(1.5, w * .035); g.beginPath(); g.arc(cx, top - w * .45, w * .08, 0, 6.283); g.stroke();
    glow(g, cx, top - w * .1, w * .5, "#ffd36a", .18);
  } else if (kind === "bonbon") {
    const top = yb - w * .3;
    for (const s of [-1, 1]) {
      const ex = cx + s * w * .42, ey = yb - w * .12;
      g.fillStyle = s < 0 ? "#ffd93b" : "#5cf2ff"; g.beginPath(); g.moveTo(ex, ey);
      g.lineTo(ex + s * w * .2, ey - w * .13);
      for (let k = 0; k < 3; k++) { const y0 = ey - w * .13 + k * w * .09; g.quadraticCurveTo(ex + s * w * .29, y0 + w * .045, ex + s * w * .2, y0 + w * .09); }
      g.lineTo(ex, ey + w * .02); g.closePath(); g.fill();
    }
    g.save(); g.beginPath(); g.moveTo(cx - w * .46, yb); g.quadraticCurveTo(cx - w * .46, top, cx, top); g.quadraticCurveTo(cx + w * .46, top, cx + w * .46, yb); g.closePath();
    g.fillStyle = "#ff7fb5"; g.fill(); g.clip();
    g.fillStyle = "rgba(255,255,255,.85)";
    for (let k = -4; k < 5; k++) { const x0 = cx + k * w * .16 + ((turn * w * .05) % (w * .16)); g.beginPath(); g.moveTo(x0, yb); g.lineTo(x0 + w * .06, yb); g.lineTo(x0 + w * .2, top); g.lineTo(x0 + w * .14, top); g.closePath(); g.fill(); }
    g.restore();
    g.strokeStyle = "rgba(170,40,100,.7)"; g.lineWidth = ol; g.beginPath(); g.moveTo(cx - w * .46, yb); g.quadraticCurveTo(cx - w * .46, top, cx, top); g.quadraticCurveTo(cx + w * .46, top, cx + w * .46, yb); g.closePath(); g.stroke();
    g.fillStyle = "#fff0f6"; roundRect(g, cx - w * .48, yb - w * .05, w * .96, w * .07, w * .03, w * .03); g.fill();
    g.strokeStyle = "#3f8a2e"; g.lineWidth = Math.max(1, w * .03); g.beginPath(); g.moveTo(cx, top - w * .02); g.quadraticCurveTo(cx + w * .04, top - w * .14, cx + w * .1, top - w * .17); g.stroke();
    ellipse(g, cx, top - w * .02, w * .085, w * .085, "#e8283c"); ellipse(g, cx - w * .03, top - w * .05, w * .025, w * .02, "rgba(255,255,255,.8)");
  } else if (kind === "hatch") {
    const bh = w * .11, top = yb - bh;
    g.fillStyle = STEEL(g, cx - w * .5, cx + w * .5); roundRect(g, cx - w * .5, top, w, bh, w * .04, w * .04); g.fill();
    for (let k = 0; k < 6; k++) { const a = turn + k * 1.047, f = Math.sin(a); if (f > 0) ellipse(g, cx + Math.cos(a) * w * .44, top + bh / 2, w * .02 * f + .5, w * .02, "#2c3147"); }
    g.beginPath(); g.ellipse(cx, top, w * .4, w * .3, 0, Math.PI, 2 * Math.PI); g.closePath();
    const dg = g.createLinearGradient(0, top - w * .3, 0, top); dg.addColorStop(0, "rgba(170,240,255,.85)"); dg.addColorStop(1, "rgba(90,120,220,.75)");
    g.fillStyle = dg; g.fill(); g.strokeStyle = "rgba(220,235,255,.9)"; g.lineWidth = ol; g.stroke();
    g.strokeStyle = "rgba(255,255,255,.8)"; g.lineWidth = Math.max(1, w * .03); g.beginPath(); g.ellipse(cx, top, w * .3, w * .22, 0, Math.PI * 1.2, Math.PI * 1.45); g.stroke();
    const on = Math.sin(now / 250) > 0; glow(g, cx, top - w * .32, w * .2, on ? "#5cf2ff" : "#ff5c8a", .6); ellipse(g, cx, top - w * .32, w * .045, w * .045, on ? "#bff9ff" : "#ff9fbf");
  }
  g.restore();
}
const _paintCap = paintCap;
paintCap = function (g, r, age) {
  const kind = CAP_KIND[themeNow().name];
  if (!kind) { g.save(); g.translate(0, r.w * .03); _paintCap(g, r, age); g.restore(); return; }
  const T = capTimeline(age), w = r.w, cx = r.x + w / 2, yb = r.y + w * (kind === "cork" ? .075 : .1) - T.lift * w;
  g.save(); g.globalAlpha *= T.alpha;
  if (T.squash !== 1) { g.translate(cx, yb); g.scale(1 + (1 - T.squash) * .5, T.squash); g.translate(-cx, -yb); }
  capShape(g, kind, cx, yb, w, T.spin);
  g.restore();
  if (kind === "cork") clayLip(g, cx, r.y, w);
  const gt = (age - CAP_TOTAL - 120) / 420;
  if (gt > 0 && gt < 1) glow(g, cx - w * .5 + gt * w, yb - w * .12, w * .35, "#ffffff", .55 * Math.sin(gt * Math.PI));
};
// the locked lid (with the number of pours it waits for) takes the world's lid too
function lockArt(g, r) {
  const kind = CAP_KIND[themeNow().name]; if (!kind) return false;
  if (kind === "cork") { capShape(g, kind, 0, r.w * .055, r.w, 0); if (g.globalAlpha >= 1) clayLip(g, 0, -r.w * .02, r.w); LOCK_BADGE_Y = -.1; return true; }
  capShape(g, kind, 0, r.w * .14, r.w, 0); return true;
}
let LOCK_BADGE_Y = -.03;

// ---------- sparks in each world's style: bubbles, petals, gem glints, sprinkles, little stars ----------
function paintParticle(g, p, a) {
  const kind = CAP_KIND[themeNow().name];
  if (!kind) { glow(g, p.x, p.y, p.size * 3, p.col, .5 * a); g.fillStyle = `rgba(255,255,240,${a})`; g.fillRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size); return; }
  const s = p.size * 1.6, rot = (p.seed || (p.seed = Math.random() * 6.28)) + p.life * 6;
  g.save(); g.globalAlpha = a;
  if (kind === "shell") { g.strokeStyle = "rgba(255,255,255,.9)"; g.lineWidth = Math.max(1, s * .3); g.beginPath(); g.arc(p.x, p.y, s, 0, 6.283); g.stroke(); ellipse(g, p.x - s * .35, p.y - s * .35, s * .25, s * .25, "rgba(255,255,255,.9)"); }
  else if (kind === "cork") { g.translate(p.x, p.y); g.rotate(rot); ellipse(g, 0, 0, s * 1.2, s * .55, p.col); ellipse(g, 0, 0, s * .6, s * .25, "rgba(255,255,255,.5)"); }
  else if (kind === "dome") { glow(g, p.x, p.y, s * 2.5, p.col, .5); g.fillStyle = "#fffbe0"; g.translate(p.x, p.y); g.rotate(rot * .3); g.beginPath(); g.moveTo(0, -s); g.lineTo(s * .6, 0); g.lineTo(0, s); g.lineTo(-s * .6, 0); g.closePath(); g.fill(); }
  else if (kind === "bonbon") { g.translate(p.x, p.y); g.rotate(rot); g.fillStyle = p.col; roundRect(g, -s, -s * .3, s * 2, s * .6, s * .3, s * .3); g.fill(); }
  else if (kind === "hatch") { glow(g, p.x, p.y, s * 2.5, p.col, .45); g.fillStyle = "#ffffff"; sparkPath(g, p.x, p.y, s * 1.2, s * .3); g.fill(); }
  g.restore();
}

// buttons and popups follow the world being played (the menu and map keep the Jar World look)
setInterval(() => {
  let w = "hub";
  try { if ($("menu").hidden && $("map").hidden) w = themeNow().name; } catch (e) {}
  if (document.documentElement.dataset.world !== w) document.documentElement.dataset.world = w;
}, 250);

// ---------- the little helpers that mend a cracked jar: one per world (the night world keeps its fireflies) ----------
const _paintHelper = paintHelper;
paintHelper = function (g, x, y, r, flap, left) {
  const n = themeNow().name, f = left ? -1 : 1, wy = .35 + .65 * Math.abs(Math.sin(flap));
  if (!["reef", "sunpetal", "grove", "candy", "space"].includes(n)) return _paintHelper(g, x, y, r, flap, left);
  const eyes = (ex, ey, s) => { for (const sx of [-1, 1]) { ellipse(g, ex + sx * s * 1.1, ey, s, s, "#ffffff"); ellipse(g, ex + sx * s * 1.1 + f * s * .25, ey + s * .1, s * .55, s * .55, "#1a1430"); } };
  g.save(); g.lineCap = "round"; g.lineJoin = "round";
  if (n === "reef") {   // a little crab
    glow(g, x, y, r * 3, "#bff9ff", .45);
    g.strokeStyle = "#c8402c"; g.lineWidth = Math.max(1.2, r * .12);
    for (const sx of [-1, 1]) for (let k = 0; k < 3; k++) { const lx = x + sx * r * (.35 + k * .18), kick = Math.sin(flap * 2 + k) * r * .12; g.beginPath(); g.moveTo(lx, y + r * .2); g.lineTo(lx + sx * r * .35, y + r * .45 + kick); g.lineTo(lx + sx * r * .4, y + r * .75 + kick); g.stroke(); }
    for (const sx of [-1, 1]) { const cx = x + sx * r * 1.0, cy = y - r * .45 + Math.sin(flap + sx) * r * .1; g.beginPath(); g.moveTo(x + sx * r * .55, y - r * .05); g.lineTo(cx, cy + r * .2); g.stroke();
      ellipse(g, cx, cy, r * .32, r * .26, "#ff6a4d"); g.fillStyle = "#bff9ff"; g.beginPath(); g.moveTo(cx + sx * r * .05, cy - r * .04); g.lineTo(cx + sx * r * .36, cy - r * .2); g.lineTo(cx + sx * r * .34, cy + r * .02); g.closePath(); g.fill(); }
    ellipse(g, x, y, r * .78, r * .52, "#ff6a4d"); ellipse(g, x - r * .2, y - r * .2, r * .3, r * .12, "rgba(255,255,255,.35)");
    g.strokeStyle = "#c8402c"; g.lineWidth = Math.max(1, r * .1); for (const sx of [-1, 1]) { g.beginPath(); g.moveTo(x + sx * r * .22, y - r * .4); g.lineTo(x + sx * r * .26, y - r * .7); g.stroke(); }
    for (const sx of [-1, 1]) { ellipse(g, x + sx * r * .26, y - r * .74, r * .14, r * .14, "#ffffff"); ellipse(g, x + sx * r * .26 + f * r * .04, y - r * .73, r * .07, r * .07, "#1a1430"); }
    ellipse(g, x, y + r * .15, r * .18, r * .08, "#c8402c");
  } else if (n === "sunpetal") {   // a bee
    glow(g, x, y, r * 3, "#ffe9a0", .45);
    g.fillStyle = "rgba(255,255,255,.75)"; for (const sx of [-1, 1]) { g.beginPath(); g.ellipse(x + sx * r * .3, y - r * .6, r * .32, r * .5 * wy, sx * .4, 0, 6.283); g.fill(); }
    g.save(); g.beginPath(); g.ellipse(x, y, r * .82, r * .58, 0, 0, 6.283); g.clip(); g.fillStyle = "#ffcf3b"; g.fillRect(x - r, y - r, r * 2, r * 2);
    g.fillStyle = "#2a1c10"; for (const k of [-.15, .25]) g.fillRect(x + f * r * k - r * .09, y - r, r * .18, r * 2); g.restore();
    g.fillStyle = "#2a1c10"; g.beginPath(); g.moveTo(x - f * r * .8, y - r * .08); g.lineTo(x - f * r * 1.05, y); g.lineTo(x - f * r * .8, y + r * .08); g.closePath(); g.fill();
    ellipse(g, x + f * r * .45, y - r * .08, r * .14, r * .14, "#ffffff"); ellipse(g, x + f * r * .5, y - r * .06, r * .07, r * .07, "#1a1430");
    g.strokeStyle = "#2a1c10"; g.lineWidth = Math.max(1, r * .07); g.beginPath(); g.moveTo(x + f * r * .55, y - r * .45); g.quadraticCurveTo(x + f * r * .7, y - r * .8, x + f * r * .9, y - r * .8); g.stroke();
  } else if (n === "grove") {   // a glowing forest sprite with leaf wings
    glow(g, x, y, r * 3.6, "#7dffd0", .6);
    for (const sx of [-1, 1]) leaf(g, x + sx * r * .3, y - r * .2, r * 1.0 * (.6 + .4 * wy), sx < 0 ? Math.PI + .5 : -.5, "rgba(140,230,120,.85)");
    ellipse(g, x, y, r * .7, r * .7, "#d9fff0"); ellipse(g, x, y + r * .15, r * .45, r * .45, "#7dffd0");
    eyes(x, y - r * .05, r * .1);
    leaf(g, x, y - r * .62, r * .5, -1.9, "#5cb23f");
  } else if (n === "candy") {   // a gumdrop with little wings
    glow(g, x, y, r * 3, "#ffc0de", .45);
    g.fillStyle = "rgba(255,255,255,.75)"; for (const sx of [-1, 1]) { g.beginPath(); g.ellipse(x + sx * r * .75, y - r * .35, r * .35, r * .45 * wy, sx * .6, 0, 6.283); g.fill(); }
    g.fillStyle = "#ff5c9a"; g.beginPath(); g.moveTo(x - r * .75, y + r * .5); g.quadraticCurveTo(x - r * .8, y - r * .75, x, y - r * .75); g.quadraticCurveTo(x + r * .8, y - r * .75, x + r * .75, y + r * .5); g.closePath(); g.fill();
    for (const [sx, sy] of [[-.4, -.3], [.3, -.45], [.45, .1], [-.2, .25], [0, -.1]]) ellipse(g, x + sx * r, y + sy * r, r * .05, r * .05, "rgba(255,255,255,.85)");
    eyes(x, y + r * .05, r * .11);
  } else if (n === "space") {   // a tiny flying saucer
    glow(g, x, y, r * 3.2, "#5cf2ff", .45);
    g.beginPath(); g.ellipse(x, y - r * .15, r * .45, r * .45, 0, Math.PI, 2 * Math.PI); g.closePath(); g.fillStyle = "rgba(150,240,255,.85)"; g.fill();
    eyes(x, y - r * .3, r * .09);
    const sg = g.createLinearGradient(x - r, 0, x + r, 0); sg.addColorStop(0, "#6a7090"); sg.addColorStop(.45, "#eef2ff"); sg.addColorStop(1, "#5a6080");
    g.fillStyle = sg; g.beginPath(); g.ellipse(x, y, r * 1.0, r * .3, 0, 0, 6.283); g.fill();
    for (let k = 0; k < 5; k++) { const on = Math.sin(flap * .8 + k) > 0; ellipse(g, x + (k - 2) * r * .38, y + r * .05, r * .07, r * .07, on ? "#ffd93b" : "#ff5c8a"); }
    g.fillStyle = "rgba(120,240,255,.18)"; g.beginPath(); g.moveTo(x - r * .3, y + r * .25); g.lineTo(x + r * .3, y + r * .25); g.lineTo(x + r * .6, y + r * 1.3); g.lineTo(x - r * .6, y + r * 1.3); g.closePath(); g.fill();
  }
  g.restore();
};

// the repair sparkles, trail and glow follow the helper of each world (only the night world keeps golden firefly light)
const HELPER_COL = { reef: "#bff9ff", sunpetal: "#ffc6e0", grove: "#a8ffb8", candy: "#ff9fd0", space: "#c4b6ff" };
function helperCol() { try { return HELPER_COL[themeNow().name] || "#fff0a0"; } catch (e) { return "#fff0a0"; } }
function helperSize() { try { return HELPER_COL[themeNow().name] ? 1.3 : .8; } catch (e) { return .8; } }
function helperTrail() { try { return HELPER_COL[themeNow().name] ? .3 : 1; } catch (e) { return 1; } }
