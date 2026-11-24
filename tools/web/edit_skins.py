# Skins shop (jar and firefly looks for coins), coin packs, and iPhone haptics for the web test page.
# Mirrors game/scripts (art.gd SKINS, main.gd _show_skins, store.gd COIN_PACKS).
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
def rep(old, new, cnt=1):
    global s
    c = s.count(old)
    if c != cnt:
        print("COUNT", c, "expected", cnt, "for:", old[:120]); sys.exit(1)
    s = s.replace(old, new)

# ---- saved choices ----
rep('''colorBlind: false, seen: {},''', '''colorBlind: false, skins: {}, jarSkin: "classic", flySkin: "classic", seen: {},''')

# ---- CSS ----
rep('''</style>''', '''.sideL { position: absolute; left: max(12px, env(safe-area-inset-left, 0px)); top: 46%; z-index: 2; }
.skinsCard { gap: 12px; padding: 18px 16px; }
.skHead { display: flex; align-items: center; gap: 8px; }
.skHead .title { flex: 1; font-size: 40px; text-align: start; }
.skCoins { display: flex; align-items: center; gap: 6px; font-weight: 800; font-size: 20px; color: #ffe8a3; }
.skCoins svg.i { width: 24px; height: 24px; }
.skTabs { display: flex; gap: 10px; }
.skTabs button { flex: 1; height: 46px; border-radius: 16px; border: 1.5px solid var(--glass-line); background: rgba(255, 255, 255, .06); color: #fff; font-family: var(--logo); font-size: 19px; }
.skTabs button.on { border: 0; background: linear-gradient(180deg, #ffe066, #ffb830 60%, #ff9f43); color: #3a2205; box-shadow: 0 3px 0 #b3600c; }
.skGrid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.skTile { display: flex; flex-direction: column; align-items: center; gap: 1px; padding: 6px 2px 7px; border-radius: 16px; border: 1.5px solid rgba(150, 175, 255, .25); background: rgba(30, 38, 92, .55); color: #fff; min-width: 0; }
.skTile canvas { width: 84px; height: 84px; }
.skTile b { font-size: 13px; line-height: 1.15; min-height: 15px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%; }
.skTile small { font-size: 13px; font-weight: 800; color: var(--muted); display: flex; align-items: center; gap: 3px; }
.skTile small svg.i { width: 15px; height: 15px; }
.skTile small.gold { color: #ffd93b; } .skTile small.can { color: #ffe8a3; }
.skTile.on { border: 2.5px solid #ffd93b; background: rgba(255, 217, 59, .12); box-shadow: 0 0 14px rgba(255, 217, 59, .3); }
.skPacks { display: flex; gap: 8px; }
.skPacks button { flex: 1; display: flex; flex-direction: column; align-items: center; padding: 6px 2px; border-radius: 16px; border: 1.5px solid rgba(255, 200, 60, .6); background: rgba(255, 200, 60, .12); color: #ffe8a3; font-family: var(--logo); }
.skPacks .pc { display: flex; } .skPacks .pc svg.i { width: 20px; height: 20px; margin: 0 -3px; }
.skPacks b { font-size: 19px; } .skPacks small { font-size: 13px; color: #fff; }
.skinsCard .note { text-align: center; margin-bottom: -4px; }
.skinsCard .coinBtn { height: 50px; font-size: 19px; }
.skinsCard .big { min-height: 58px; font-size: 24px; }
</style>''')

# ---- HTML: the shop, the side button, and ids on the test store ----
rep('''<div class="overlay" id="store" hidden>''', '''<div class="overlay" id="skins" hidden>
  <div class="card skinsCard">
    <div class="skHead"><div class="title">Skins</div><div class="skCoins"><span data-ico="coin"></span><span id="skCoinN">0</span></div></div>
    <div class="skTabs"><button id="skTabJar" class="on">Jars</button><button id="skTabFly">Fireflies</button></div>
    <div class="skGrid" id="skGrid"></div>
    <button class="coinBtn" id="skAction"></button>
    <div class="note">Get more coins</div>
    <div class="skPacks" id="skPacks"></div>
    <button class="big" id="skDone">Done</button>
  </div>
</div>
<div class="overlay" id="store" hidden>''')
rep('''    <div class="title" style="font-size:40px">Remove ads</div>
    <div class="sub">No more ads''', '''    <div class="title" style="font-size:40px" id="storeTitle">Remove ads</div>
    <div class="sub"><span id="storeWhat">No more ads''')
rep('''rewards stay available.<br><br><small class="note">In the real game''', '''rewards stay available.<br><br></span><small class="note">In the real game''')
rep('''      <button class="sideBtn streakSide" id="streakSide"''', '''      <button class="sideBtn streakSide" id="streakSide"''')
rep('''    <div class="side">''', '''    <div class="sideL"><button class="sideBtn" id="skinsSide" aria-label="Skins"><span class="sb" data-ico="skins"></span><b>Skins</b></button></div>
    <div class="side">''')

# ---- icon ----
rep('''  gift: '<svg class="i"''', '''  skins: '<svg class="i" viewBox="0 0 24 24" aria-hidden="true"><path d="M8.5 3.5h7v2.2c2 .6 3.3 2 3.3 4.3v8.5c0 1.5-1 2.5-2.5 2.5H7.7c-1.5 0-2.5-1-2.5-2.5V10c0-2.3 1.3-3.7 3.3-4.3z" fill="rgba(170,205,255,.18)" stroke="#d7ebff" stroke-width="1.4"/><circle cx="11.5" cy="15" r="3" fill="#ff5c8a"/><circle cx="10.6" cy="14" r=".9" fill="#fff"/><path d="M18.5 2l.9 2.1 2.1.9-2.1.9-.9 2.1-.9-2.1-2.1-.9 2.1-.9z" fill="#ffd93b"/></svg>',
  gift: '<svg class="i"''')

# ---- drawing: jar skins ----
rep('''  g.fillStyle = gr; g.fill();
  if (only >= 0 || done)''', '''  g.fillStyle = gr; g.fill();
  const glass = SKIN_GLASS[r.skin || save.jarSkin]; if (glass) { g.fillStyle = glass; g.fill(); }
  if (only >= 0 || done)''')
rep('''  let line = "rgba(215,235,255,.6)";
  if (done) line = COLORS[jar[0]];''', '''  let line = jarLine(r.skin);
  if (done) line = COLORS[jar[0]];''')
rep('''  for (const k of [.03, .08]) { g.beginPath(); g.moveTo(r.x + r.w * .1, r.y + r.w * k); g.lineTo(r.x + r.w * .9, r.y + r.w * (k + .015)); g.stroke(); }
  if (only >= 0) {''', '''  for (const k of [.03, .08]) { g.beginPath(); g.moveTo(r.x + r.w * .1, r.y + r.w * k); g.lineTo(r.x + r.w * .9, r.y + r.w * (k + .015)); g.stroke(); }
  paintJarDeco(g, r, r.skin || save.jarSkin);
  if (only >= 0) {''')

# ---- drawing: firefly skins ----
rep('''function paintFly(g, x, y, r, c, flap, awake, moving, id) {
  const col = COLORS[c];''', '''function paintFly(g, x, y, r, c, flap, awake, moving, id, skin) {
  const col = COLORS[c], sk = skin || save.flySkin;''')
rep('''  g.fillStyle = "rgba(230,240,255,.45)";
  for (const side of [-1, 1]) { g.beginPath(); g.ellipse(x + side * r * .62, y - r * .5, r * .42, r * .42 * wy, side * .5, 0, 6.283); g.fill(); }
  g.fillStyle = col; g.beginPath(); g.arc(x, y, r * .74, 0, 6.283); g.fill();
  g.fillStyle = "rgba(255,255,255,.8)"; g.beginPath(); g.arc(x - r * .22, y - r * .25, r * .2, 0, 6.283); g.fill();''', '''  if (sk === "fairy") {
    // butterfly wings in the firefly's own color: a big upper pair and a small lower pair
    for (const side of [-1, 1]) {
      g.globalAlpha = .55; g.fillStyle = mixWhite(col, .35);
      g.beginPath(); g.ellipse(x + side * r * .72, y - r * .55, r * .55, r * .55 * wy, side * .7, 0, 6.283); g.fill();
      g.beginPath(); g.ellipse(x + side * r * .62, y + r * .12, r * .32, r * .32 * wy, -side * .5, 0, 6.283); g.fill();
      g.globalAlpha = .35; g.fillStyle = "#fff"; g.beginPath(); g.ellipse(x + side * r * .72, y - r * .55, r * .25, r * .25 * wy, side * .7, 0, 6.283); g.fill();
      g.globalAlpha = 1;
    }
  } else {
    g.fillStyle = "rgba(230,240,255,.45)";
    for (const side of [-1, 1]) { g.beginPath(); g.ellipse(x + side * r * .62, y - r * .5, r * .42, r * .42 * wy, side * .5, 0, 6.283); g.fill(); }
  }
  g.fillStyle = col; g.beginPath(); g.arc(x, y, r * .74, 0, 6.283); g.fill();
  g.fillStyle = "rgba(255,255,255,.8)"; g.beginPath(); g.arc(x - r * .22, y - r * .25, r * .2, 0, 6.283); g.fill();
  flyExtra(g, x, y, r, col, id, sk);''')

rep('''// Color-blind mode: every color also has its own shape''', '''// ===================== skins (same as SKINS in scripts/art.gd) =====================
// The first of each list is free. GUESS: prices, so the first skin takes about 20 levels and the last about 80.
const SKINS = {
  jar: [["classic", "Clear glass", 0], ["frost", "Frosted glass", 200], ["honey", "Honey glass", 350], ["moon", "Moonlight glass", 500], ["rose", "Rose glass", 800]],
  fly: [["classic", "Classic", 0], ["bug", "Little antennae", 200], ["fairy", "Fairy wings", 350], ["star", "Starlight", 500], ["royal", "Royal crown", 800]],
};
const SKIN_GLASS = { frost: "rgba(235,245,255,.13)", honey: "rgba(255,180,70,.14)", moon: "rgba(128,108,255,.14)", rose: "rgba(255,115,180,.13)" };
function jarLine(skin) { return { frost: "rgba(237,247,255,.75)", honey: "rgba(255,204,115,.7)", moon: "rgba(190,184,255,.7)", rose: "rgba(255,178,210,.7)" }[skin || save.jarSkin] || "rgba(215,235,255,.6)"; }
function mixWhite(hex, k) { if (typeof hex !== "string" || hex[0] !== "#") return "rgba(230,240,255,.8)"; const n = parseInt(hex.slice(1), 16), f = v => Math.round(v + (255 - v) * k); return `rgb(${f(n >> 16)},${f((n >> 8) & 255)},${f(n & 255)})`; }
function sparkPath(g, x, y, ro, ri) { g.beginPath(); for (let k = 0; k < 8; k++) { const a = Math.PI / 4 * k - Math.PI / 2, rr = k % 2 ? ri : ro; g.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); } g.closePath(); }
function starPath(g, x, y, ro, ri) { g.beginPath(); for (let k = 0; k < 10; k++) { const a = Math.PI / 5 * k - Math.PI / 2, rr = k % 2 ? ri : ro; g.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); } g.closePath(); }
function heartPath(g, x, y, w) { const s = w / 2; g.beginPath(); g.moveTo(x, y + s * .9); g.bezierCurveTo(x - s * 1.3, y, x - s * .9, y - s * 1.1, x, y - s * .35); g.bezierCurveTo(x + s * .9, y - s * 1.1, x + s * 1.3, y, x, y + s * .9); g.closePath(); }
// the small painted extras of each jar skin
function paintJarDeco(g, r, skin) {
  const w = r.w, x = r.x, bot = r.y + r.h;
  g.save();
  if (skin === "frost") {
    g.fillStyle = "rgba(242,250,255,.22)"; g.beginPath(); g.moveTo(x + w * .16, bot - w * .02);
    for (let k = 0; k <= 12; k++) { const t = k / 12; g.lineTo(x + w * (.06 + .88 * t), bot - w * (.12 + .05 * Math.sin(t * 9))); }
    g.lineTo(x + w * .84, bot - w * .02); g.closePath(); g.fill();
    g.strokeStyle = "rgba(255,255,255,.55)"; g.lineWidth = Math.max(1, w * .018); g.lineCap = "round";
    for (const [fx, fy] of [[.74, .55], [.3, .78], [.68, 1.25]]) { const cx = x + w * fx, cy = r.y + w * fy;
      for (let k = 0; k < 3; k++) { const a = Math.PI * k / 3; g.beginPath(); g.moveTo(cx - Math.cos(a) * w * .06, cy - Math.sin(a) * w * .06); g.lineTo(cx + Math.cos(a) * w * .06, cy + Math.sin(a) * w * .06); g.stroke(); } }
  } else if (skin === "honey") {
    g.strokeStyle = "rgba(255,209,102,.8)"; g.lineWidth = Math.max(1.5, w * .025);
    for (const k of [.03, .08]) { g.beginPath(); g.moveTo(x + w * .1, r.y + w * k); g.lineTo(x + w * .9, r.y + w * (k + .015)); g.stroke(); }
    const dx = x + w * .72, top = r.y + w * .16;
    g.strokeStyle = "rgba(255,184,51,.6)"; g.lineWidth = Math.max(2, w * .05); g.lineCap = "round"; g.beginPath(); g.moveTo(dx, top); g.lineTo(dx, top + w * .3); g.stroke();
    g.fillStyle = "rgba(255,184,51,.65)"; g.beginPath(); g.arc(dx, top + w * .33, w * .05, 0, 6.283); g.fill();
    g.strokeStyle = "rgba(255,209,102,.45)"; g.lineWidth = Math.max(1, w * .015);
    for (const [hx, hy] of [[.3, .88], [.42, .95]]) { const cx = x + w * hx, cy = bot - w * hy * .5; g.beginPath(); for (let k = 0; k <= 6; k++) g.lineTo(cx + Math.cos(Math.PI / 3 * k) * w * .06, cy + Math.sin(Math.PI / 3 * k) * w * .06); g.stroke(); }
  } else if (skin === "moon") {
    const mx = x + w * .72, my = r.y + w * .62;
    g.fillStyle = "rgba(255,242,191,.7)"; g.beginPath(); g.arc(mx, my, w * .1, 0, 6.283); g.fill();
    g.fillStyle = "rgba(77,66,153,.85)"; g.beginPath(); g.arc(mx + w * .045, my - w * .03, w * .085, 0, 6.283); g.fill();
    g.fillStyle = "rgba(255,242,191,.6)";
    for (const [sx, sy] of [[.3, .75], [.62, 1.05], [.36, 1.35], [.75, 1.55]]) { starPath(g, x + w * sx, r.y + w * sy, w * .05, w * .02); g.fill(); }
  } else if (skin === "rose") {
    g.fillStyle = "rgba(255,140,191,.5)";
    for (const [hx, hy] of [[.28, .16], [.72, .24], [.5, .42]]) { heartPath(g, x + w * hx, bot - w * hy, w * .14); g.fill(); }
  }
  g.restore();
}
// the extra look of each firefly skin; the body color never changes, so the puzzle colors stay easy to tell apart
function flyExtra(g, x, y, r, col, id, sk) {
  if (sk === "bug") {
    g.strokeStyle = "rgba(26,31,64,.85)"; g.lineWidth = Math.max(1, r * .09); g.lineCap = "round";
    for (const sx of [-1, 1]) {
      g.beginPath(); g.moveTo(x + sx * r * .22, y - r * .62); g.quadraticCurveTo(x + sx * r * .18, y - r * 1.05, x + sx * r * .55, y - r * 1.2); g.stroke();
      g.fillStyle = mixWhite(col, .45); g.beginPath(); g.arc(x + sx * r * .55, y - r * 1.2, r * .13, 0, 6.283); g.fill();
    }
  } else if (sk === "star") {
    const tw = .55 + .45 * Math.sin(now / 333 + (id || 0));
    g.fillStyle = "rgba(255,255,255,.95)"; sparkPath(g, x - r * .2, y - r * .24, r * .36, r * .07); g.fill();
    g.fillStyle = `rgba(255,255,230,${.85 * tw})`; sparkPath(g, x + r * .95, y - r * .7, r * .3 * tw, r * .06 * tw); g.fill();
  } else if (sk === "royal") {
    const b = y - r * .6, cw = r * .42;
    g.beginPath(); g.moveTo(x - cw, b); g.lineTo(x - cw, b - r * .3); g.lineTo(x - cw * .5, b - r * .12); g.lineTo(x, b - r * .42); g.lineTo(x + cw * .5, b - r * .12); g.lineTo(x + cw, b - r * .3); g.lineTo(x + cw, b); g.closePath();
    g.fillStyle = "#ffc83c"; g.fill(); g.strokeStyle = "rgba(140,84,13,.9)"; g.lineWidth = Math.max(1, r * .06); g.lineJoin = "round"; g.stroke();
    g.fillStyle = "#fff3b0"; g.beginPath(); g.arc(x, b - r * .42, r * .07, 0, 6.283); g.fill();
    g.fillStyle = "#ff5c8a"; g.beginPath(); g.arc(x, b - r * .1, r * .06, 0, 6.283); g.fill();
  }
}
// Color-blind mode: every color also has its own shape''')

# ---- haptics: phones with vibration use it; iPhone Safari (no vibrate) gets the switch-tap trick ----
rep('''function buzz(p) { if (save.vibrate && navigator.vibrate) try { navigator.vibrate(p); } catch (e) {} }''',
'''// iPhone Safari has no navigator.vibrate, but tapping a hidden switch control gives a light haptic tick (iOS 18+)
const hapticEl = (() => { try { const l = document.createElement("label"), i = document.createElement("input"); i.type = "checkbox"; i.setAttribute("switch", ""); l.setAttribute("aria-hidden", "true"); l.style.display = "none"; l.appendChild(i); document.body.appendChild(l); return l; } catch (e) { return null; } })();
function buzz(p) {
  if (!save.vibrate) return;
  if (navigator.vibrate) { try { navigator.vibrate(p); } catch (e) {} return; }
  try { if (hapticEl) { hapticEl.click(); if (Array.isArray(p) && p.length > 2) setTimeout(() => hapticEl.click(), 130); } } catch (e) {}
}''')
rep('''function celebrate() {
  let title''', '''function celebrate() {
  buzz([40, 120, 70]);   // a happy double tap on the phone
  let title''')

# ---- the shop ----
rep('''// ===================== hearts (lives) =====================''', '''// ===================== skins shop and coin packs (same as main.gd _show_skins, store.gd COIN_PACKS) =====================
// Coin packs are used up when bought. The IDs must be created in App Store Connect as "Consumable". GUESS: sizes.
const COIN_PACKS = [["coins_500", 500, "$0.99"], ["coins_1800", 1800, "$2.99"], ["coins_3500", 3500, "$4.99"]];
let skTab = "jar", skPick = "", skRaf = 0, storeProduct = "remove_ads";
const skOwned = (k, id) => id === "classic" || !!save.skins[k + "_" + id];
const skUsing = (k, id) => (k === "jar" ? save.jarSkin : save.flySkin) === id;
function showSkins() { skPick = ""; refreshSkins(); $("skins").hidden = false; Snd.play("sfx_select"); cancelAnimationFrame(skRaf); skRaf = requestAnimationFrame(skAnim); }
function refreshSkins() {
  $("skCoinN").textContent = save.coins;
  $("skTabJar").classList.toggle("on", skTab === "jar"); $("skTabFly").classList.toggle("on", skTab === "fly");
  $("skGrid").innerHTML = SKINS[skTab].map(([id, name, price]) => {
    const own = skOwned(skTab, id), use = skUsing(skTab, id);
    const st = use ? `<small class="gold">${ICONS.check} ${L("In use")}</small>` : own ? `<small>${L("Owned")}</small>` : `<small class="${save.coins >= price ? "can" : ""}">${ICONS.coin} ${price}</small>`;
    return `<button class="skTile ${use || skPick === id ? "on" : ""}" data-id="${id}"><canvas width="168" height="168"></canvas><b>${L(name)}</b>${st}</button>`;
  }).join("");
  $("skGrid").querySelectorAll(".skTile").forEach(b => b.onclick = () => {
    const id = b.dataset.id; Snd.play("sfx_select");
    if (skOwned(skTab, id)) useSkin(skTab, id);
    skPick = id; refreshSkins();
  });
  const it = SKINS[skTab].find(x => x[0] === skPick), a = $("skAction");
  if (!it || skOwned(skTab, it[0])) { a.disabled = true; a.textContent = it ? L("You're using it now") : L("Tap a look to choose it"); }
  else setCoinBtn(a, it[2], "Buy for {0}");
  skDraw();
}
function skDraw() {
  const t = performance.now() / 1000;
  $("skGrid").querySelectorAll(".skTile").forEach((b, n) => {
    const g = b.querySelector("canvas").getContext("2d"), id = b.dataset.id;
    g.setTransform(2, 0, 0, 2, 0, 0); g.clearRect(0, 0, 84, 84);
    if (skTab === "jar") {
      const r = { x: 23, y: 6, w: 38, h: 74, tip: true, skin: id }, St = { jars: [[]], only: [-1], locks: [0] };
      paintJarBack(g, r, St, 0);
      paintFly(g, 36, 66 + Math.sin(t * 2) * 1.5, 8, 0, t * 9, true, false, 1);
      paintFly(g, 48, 50 + Math.sin(t * 2 + 1) * 1.5, 8, 2, t * 9 + 1, true, false, 2);
      paintJarFront(g, r, St, 0, 8);
    } else {
      const c = (n * 3) % 10, y = 48 + Math.sin(t * 2.2 + n) * 3;
      paintFly(g, 42, y, 17, c, t * 9 + n, true, true, n * 2, id);
    }
  });
}
function skAnim() { if ($("skins").hidden) return; skDraw(); skRaf = requestAnimationFrame(skAnim); }
function useSkin(k, id) { if (k === "jar") save.jarSkin = id; else save.flySkin = id; store(); Analytics.log("skin_use", { kind: k, skin: id }); }
$("skTabJar").onclick = () => { skTab = "jar"; skPick = ""; Snd.play("sfx_select"); refreshSkins(); };
$("skTabFly").onclick = () => { skTab = "fly"; skPick = ""; Snd.play("sfx_select"); refreshSkins(); };
$("skAction").onclick = () => {
  const it = SKINS[skTab].find(x => x[0] === skPick);
  if (!it || skOwned(skTab, it[0]) || !spendCoins(it[2], "skin_" + skTab + "_" + it[0])) return;
  save.skins[skTab + "_" + it[0]] = true; useSkin(skTab, it[0]);
  Snd.play("sfx_jar_done"); buzz(25); toast("New look!", L(it[1])); refreshSkins();
};
$("skDone").onclick = () => { $("skins").hidden = true; Snd.play("sfx_drop"); refresh(); };
$("skinsSide").onclick = () => { Snd.start(); showSkins(); };
$("coinChip").onclick = () => { Snd.start(); showSkins(); };
$("skPacks").innerHTML = COIN_PACKS.map(([id, n, price], k) => `<button data-id="${id}"><span class="pc">${ICONS.coin.repeat(k + 1)}</span><b>${n}</b><small>${price}</small></button>`).join("");
$("skPacks").querySelectorAll("button").forEach(b => b.onclick = () => { Snd.play("sfx_select"); openStore(b.dataset.id); });
// the test store card, for Remove ads or a coin pack
function openStore(id) {
  storeProduct = id;
  const pk = COIN_PACKS.find(x => x[0] === id);
  $("storeTitle").textContent = pk ? L("{0} coins", pk[1]) : L("Remove ads");
  $("storeWhat").hidden = !!pk;
  $("storeBuy").textContent = L("Buy for {0}", pk ? pk[2] : "$2.99");
  $("store").hidden = false;
}
$("removeAdsBtn").onclick = () => { if (save.adsRemoved) return; Snd.play("sfx_select"); openStore("remove_ads"); };
$("noAdsSide").onclick = () => { Snd.start(); if (save.adsRemoved) return; Snd.play("sfx_select"); openStore("remove_ads"); };
$("storeBuy").onclick = () => {
  const pk = COIN_PACKS.find(x => x[0] === storeProduct);
  if (!pk) {
    $("store").hidden = true; save.adsRemoved = true; store(); refreshStore(); refreshSide(); Snd.play("sfx_jar_done");
    toast("Thank you!", "Ads between levels are gone"); Analytics.log("purchase", { item_id: "remove_ads", value: 2.99, currency: "USD" });
    return;
  }
  $("store").hidden = true; addCoins(pk[1], "purchase"); Snd.play("sfx_jar_done");
  toast("Thank you!", L("+{0} coins", pk[1])); Analytics.log("purchase", { item_id: pk[0], value: +pk[2].slice(1), currency: "USD" });
  if (!$("skins").hidden) refreshSkins();
};

// ===================== hearts (lives) =====================''')

open(p, "w", encoding="utf-8").write(s)
print("skins ok")
