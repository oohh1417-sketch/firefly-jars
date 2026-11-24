import sys, re
p = sys.argv[1]
s = open(p, encoding="utf-8").read()


def rep(old, new, cnt=1):
    global s
    c = s.count(old)
    if c != cnt:
        print("COUNT", c, "expected", cnt, "for:", old[:100])
        sys.exit(1)
    s = s.replace(old, new)


# ---------- head: pick the language early, load its font ----------
rep('''<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@500;700;800&family=Fredoka:wght@600;700&display=swap">
''', '''<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@500;700;800&family=Fredoka:wght@600;700&display=swap">
<script>
// Language: the player's choice in Settings, else the phone's. Arabic reads right to left.
// Only the font for the language in use is loaded (Arabic, Russian, Japanese, Korean or Chinese letters).
(function () {
  var LANGS = ["en", "ar", "es", "pt", "fr", "de", "tr", "ru", "ja", "ko", "zh"], pick = "";
  try { pick = JSON.parse(localStorage.getItem("fj-save") || "{}").lang || ""; } catch (e) {}
  var lang = LANGS.indexOf(pick) >= 0 ? pick : "en";
  if (LANGS.indexOf(pick) < 0) {
    var nav = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || "en"];
    for (var i = 0; i < nav.length; i++) { var c = String(nav[i]).toLowerCase().slice(0, 2); if (LANGS.indexOf(c) >= 0) { lang = c; break; } }
  }
  var FONT = { ar: ["Baloo Bhaijaan 2", "Baloo+Bhaijaan+2:wght@600;700;800"], ru: ["Nunito", "Nunito:wght@700;800;900"],
    ja: ["M PLUS Rounded 1c", "M+PLUS+Rounded+1c:wght@700;800"], ko: ["Jua", "Jua"], zh: ["Noto Sans SC", "Noto+Sans+SC:wght@700;800"] }[lang];
  var extra = FONT ? '"' + FONT[0] + '", ' : "", h = document.documentElement;
  if (FONT) { var l = document.createElement("link"); l.rel = "stylesheet"; l.href = "https://fonts.googleapis.com/css2?family=" + FONT[1] + "&display=swap"; document.head.appendChild(l); }
  h.lang = lang; if (lang === "ar") h.dir = "rtl";
  h.style.setProperty("--font", '"Baloo 2", ' + extra + '"Trebuchet MS", system-ui, sans-serif');
  h.style.setProperty("--logo", '"Fredoka", "Baloo 2", ' + extra + 'system-ui, sans-serif');
  window.FJ_LANG = lang; window.FJ_CANVAS_FONT = "'Baloo 2', " + extra + "sans-serif";
})();
</script>
''')

# ---------- CSS: right-to-left fixes and the language picker ----------
rep('''.btnRow { display: flex; gap: 10px; }''', '''.btnRow { display: flex; gap: 10px; }
.srow select { flex: none; max-width: 52%; height: 40px; padding: 0 12px; border-radius: 14px; border: 1.5px solid var(--glass-line); background: rgba(255, 255, 255, .08); color: #fff; font: 700 17px var(--font); }
.srow select option { background: #1f2a55; color: #fff; }
[dir=rtl] .srow { text-align: right; }
[dir=rtl] .srow .sw::after { left: auto; right: 3px; }
[dir=rtl] .srow input:checked + .sw::after { transform: translateX(-22px); }
/* other languages have longer words: buttons grow instead of cutting text off */
.big { height: auto; min-height: 76px; line-height: 1.1; padding-block: 8px; }
.ghostBtn, .coinBtn { height: auto; min-height: 56px; line-height: 1.15; padding-block: 6px; }
.tool { white-space: nowrap; min-width: 0; font-size: min(20px, 4.4vw); }
#hardBanner b { white-space: normal; text-align: center; max-width: 86vw; }
.chip small, .sideBtn b { white-space: nowrap; }
#chapterCount { direction: ltr; unicode-bidi: isolate; }
.level span, #movesLeft { white-space: nowrap; }
.level span { font-size: min(28px, 6.6vw); }
:root:not([lang=en]) .level small { letter-spacing: .05em; }
[lang=ja] .card .title, [lang=zh] .card .title, [lang=ko] .card .title { font-size: 34px !important; line-height: 1.15; }''')

# ---------- markup ----------
rep('''<label class="srow"><span>Color-blind mode<small>A shape on every firefly color</small></span><input type="checkbox" id="setCB"><i class="sw"></i></label>''',
    '''<label class="srow"><span>Color-blind mode<small>A shape on every firefly color</small></span><input type="checkbox" id="setCB"><i class="sw"></i></label>
    <label class="srow"><span>Language</span><select id="setLang" aria-label="Language"></select></label>''')
rep('· Test build v0.23</div>', '· Test build v0.24</div>')

# ---------- the translation table and helpers, first thing in the game script ----------
rep('''<script>
// ===================== rules (same as scripts/puzzle.gd in the Godot game) =====================''', '''<script>
// ===================== languages =====================
// Every text is written in English and looked up here (tools/i18n/strings.py in the repo, shared with the Godot game).
/*I18N-DATA*/const I18N = {};/*END-I18N-DATA*/
const LANG = window.FJ_LANG || "en", TX = (I18N.t && I18N.t[LANG]) || {}, CANVAS_FONT = window.FJ_CANVAS_FONT || "'Baloo 2', sans-serif";
// L("Level {0}", 5) -> "Nivel 5". Text that isn't in the table (already translated, or a number) comes back as it is.
const L = (s, ...a) => String(TX[s] || s).replace(/\\{(\\d)\\}/g, (m, i) => a[i]);
const UP = s => s.toLocaleUpperCase(LANG);
function dateText(d = new Date()) { const m = (I18N.months || {})[LANG] || { names: ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"], fmt: "{0} {1}" }; return m.fmt.replace("{0}", m.names[d.getMonth()]).replace("{1}", d.getDate()); }
// The page is written in English: swap every text and label that has a translation.
function translatePage() {
  if (LANG === "en") return;
  const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n; (n = w.nextNode());) { const t = n.nodeValue.trim(); if (t && TX[t]) n.nodeValue = n.nodeValue.replace(t, TX[t]); }
  for (const el of document.querySelectorAll("[aria-label],[title]")) for (const a of ["aria-label", "title"]) { const v = el.getAttribute(a); if (v && TX[v]) el.setAttribute(a, TX[v]); }
}
translatePage();

// ===================== rules (same as scripts/puzzle.gd in the Godot game) =====================''')

# ---------- sound status ----------
rep('''const txt = !this.started ? "Tap anywhere to start the music" :''', '''const txt = !this.started ? L("Tap anywhere to start the music") :''')

# ---------- top bar ----------
rep('''$("levelLabel").textContent = mode === "daily" ? new Date().toLocaleDateString(undefined, { month: "short", day: "numeric" }) : mode === "practice" ? "Tutorial" : "Level " + save.level;''',
    '''$("levelLabel").textContent = mode === "daily" ? dateText() : mode === "practice" ? L("Tutorial") : L("Level {0}", save.level);''')
rep('''<span class="ico">${ICONS.undo}</span>Undo <span''', '''<span class="ico">${ICONS.undo}</span>${L("Undo")} <span''')
rep('''<span class="ico">${ICONS.bulb}</span>Hint <span''', '''<span class="ico">${ICONS.bulb}</span>${L("Hint")} <span''')
rep('''$("chapterLabel").textContent = mode === "daily" ? "Daily puzzle" : hardNow() && !won ? tierName(save.level) + " level" : chapterOf(save.level).name;''',
    '''$("chapterLabel").textContent = mode === "daily" ? L("Daily puzzle") : hardNow() && !won ? L(tierName(save.level) + " level") : chapterOf(save.level).name;''')
rep('''ml.textContent = !movesMax ? "…" : left === 1 ? "1 move left" : left + " moves left";''', '''ml.textContent = !movesMax ? "…" : left === 1 ? L("1 move left") : L("{0} moves left", left);''')
rep('''function say(t) { $("info").textContent = t;''', '''function say(t) { $("info").textContent = L(t);''')
rep('''$("hardBanner").querySelector("b").textContent = tierName(save.level) + " level";''', '''$("hardBanner").querySelector("b").textContent = L(tierName(save.level) + " level");''')
rep('''$("hardBannerSub").textContent = (moveLimit ? `${moveLimit} moves. ` : "") + `Win for ${ext ? COIN.extreme : COIN.hard} coins + 1 hint`;''',
    '''const prize = ext ? COIN.extreme : COIN.hard; $("hardBannerSub").textContent = moveLimit ? L("{0} moves. Win for {1} coins + 1 hint", moveLimit, prize) : L("Limited moves. Win for {0} coins + 1 hint", prize);''')

# ---------- explainer cards ----------
rep('''$("tipTitle").textContent = "New: " + TIPS[k].title; $("tipText").textContent = TIPS[k].text;''', '''$("tipTitle").textContent = L("New: {0}", L(TIPS[k].title)); $("tipText").textContent = L(TIPS[k].text);''')

# ---------- menu ----------
rep('''const chapterOf = lv => { const i = Math.floor((lv - 1) / 10); return { num: i + 1, name: CHAPTERS[i % CHAPTERS.length] + (''',
    '''const chapterOf = lv => { const i = Math.floor((lv - 1) / 10); return { num: i + 1, name: L(CHAPTERS[i % CHAPTERS.length]) + (''')
rep('''return mins >= 60 ? `${Math.floor(mins / 60)}h ${mins % 60}m` : `${mins}m`; }''', '''return mins >= 60 ? L("{0}h {1}m", Math.floor(mins / 60), mins % 60) : L("{0}m", mins); }
const levelText = lv => isHard(lv) ? L("Level {0} · {1}", lv, L(tierName(lv))) : L("Level {0}", lv);''')
rep('''$("chapterNum").firstChild.textContent = "Chapter " + ch.num;''', '''$("chapterNum").firstChild.textContent = L("Chapter {0}", ch.num);''')
rep('''$("playSub").textContent = "Level " + save.level + (isHard(save.level) ? " · " + tierName(save.level) : "");''', '''$("playSub").textContent = levelText(save.level);''')
rep('''$("dailySub").textContent = doneToday ? `Solved! Next puzzle in ${untilMidnight()}` : (alive && save.streak ? `Solve today to keep your streak` : "A new puzzle every day");''',
    '''$("dailySub").textContent = doneToday ? L("Solved! Next puzzle in {0}", untilMidnight()) : L(alive && save.streak ? "Solve today to keep your streak" : "A new puzzle every day");''')

# ---------- map ----------
rep('''g.font = `800 ${Math.round(h * .2)}px Nunito, sans-serif`;
    g.fillText(`CHAPTER ${i + 1}`, x, y - h * .2);''', '''g.font = `800 ${Math.round(h * .2)}px Nunito, ${CANVAS_FONT}`;
    g.fillText(UP(L("Chapter {0}", i + 1)), x, y - h * .2, w - h);''')
rep('''g.font = `700 ${Math.round(h * .34)}px 'Baloo 2', sans-serif`;''', '''g.font = `700 ${Math.round(h * .34)}px ${CANVAS_FONT}`;''')
rep('''const nm = CHAPTERS[i % CHAPTERS.length] + (''', '''const nm = L(CHAPTERS[i % CHAPTERS.length]) + (''')
rep('''g.fillText(nm, x, y + h * .17);''', '''g.fillText(nm, x, y + h * .17, w - h * 1.3);''')
rep('''g.font = `800 ${Math.round(r * (lv >= 100 ? .72 : .85))}px Nunito, sans-serif`;''', '''g.font = `800 ${Math.round(r * (lv >= 100 ? .72 : .85))}px Nunito, ${CANVAS_FONT}`;''')
rep('''g.font = "700 34px 'Baloo 2', sans-serif";''', '''g.font = "700 34px " + CANVAS_FONT;''')
rep('''g.fillText("New chapter!", MPW / 2, y);''', '''g.fillText(L("New chapter!"), MPW / 2, y, MPW - 20);''')
rep('''$("mapPlaySub").textContent = "Level " + save.level + (isHard(save.level) ? " · " + tierName(save.level) : "");''', '''$("mapPlaySub").textContent = levelText(save.level);''')
rep('''g.font = "800 40px 'Baloo 2', sans-serif";''', '''g.font = "800 40px " + CANVAS_FONT;''')
rep('''g.font = "700 22px 'Baloo 2', sans-serif";''', '''g.font = "700 22px " + CANVAS_FONT;''')
rep('''g.font = `800 ${Math.round(r.w * .3)}px 'Baloo 2', sans-serif`;''', '''g.font = `800 ${Math.round(r.w * .3)}px ${CANVAS_FONT}`;''')

# ---------- tutorial and board messages ----------
rep('''if (msg !== tut.msg) { tut.msg = msg; clearTimeout(infoTimer); $("info").textContent = msg;''', '''if (msg !== tut.msg) { tut.msg = msg; clearTimeout(infoTimer); $("info").textContent = L(msg);''')
rep('''say(`This jar opens after ${S.locks[i]} more ${S.locks[i] === 1 ? "pour" : "pours"}`)''', '''say(S.locks[i] === 1 ? L("This jar opens after 1 more pour") : L("This jar opens after {0} more pours", S.locks[i]))''')
rep('''say(`That jar only takes ${COLOR_NAMES[S.only[i]]} fireflies`)''', '''say(L("That jar only takes {0} fireflies", L(COLOR_NAMES[S.only[i]])))''')

# ---------- win card ----------
rep('''let title = "All glowing!", text = `Solved in ${moves} moves`, sfx = "sfx_win", gain = 0;''', '''let title = "All glowing!", text = L("Solved in {0} moves", moves), sfx = "sfx_win", gain = 0;''')
rep('''title = "Well done!"; text = "That's all there is to it."; tutStop();
    $("nextBtn").textContent = "Back to menu";''', '''title = "Well done!"; text = L("That's all there is to it."); tutStop();
    $("nextBtn").textContent = L("Back to menu");''')
rep('''title = "Daily solved!"; text = `Solved in ${moves} moves · ${save.streak}-day streak 🔥\\n+1 hint. Come back tomorrow for a new puzzle.`; sfx = "sfx_daily";
    $("nextBtn").textContent = "Back to levels";''', '''title = "Daily solved!"; text = L("Solved in {0} moves", moves) + "\\n" + L("{0}-day streak, +1 hint", save.streak) + " 🔥\\n" + L("Come back tomorrow for a new puzzle."); sfx = "sfx_daily";
    $("nextBtn").textContent = L("Back to levels");''')
rep('''text += "\\n+1 hint";''', '''text += "\\n" + L("+1 hint");''')
rep('''    $("nextBtn").textContent = "Next level";''', '''    $("nextBtn").textContent = L("Next level");''')
rep('''$("winTitle").textContent = title; $("winText").textContent = text;''', '''$("winTitle").textContent = L(title); $("winText").textContent = text;''')

# ---------- out of moves, coins, offers ----------
rep('''setCoinBtn($("movesCoinBtn"), PRICE.moves, "+5 moves for");''', '''setCoinBtn($("movesCoinBtn"), PRICE.moves, "+5 moves for {0}");''')
rep('''b.innerHTML = ok ? `${verb} ${price} ${ICONS.coin}` : `${price} ${ICONS.coin} needed · you have ${save.coins}`;''',
    '''b.innerHTML = ok ? L(verb, `${price} ${ICONS.coin}`) : L("{0} needed · you have {1}", `${price} ${ICONS.coin}`, save.coins);''')
rep('''$("doubleBtn").innerHTML = `${ICONS.play} Double it: +${gain} ${ICONS.coin}`;''', '''$("doubleBtn").innerHTML = `${ICONS.play} ${L("Double it: +{0}", gain)} ${ICONS.coin}`;''')
rep('''price: PRICE.hint, verb: "Use" },''', '''price: PRICE.hint, verb: "Use {0}" },''')
rep('''price: PRICE.undo, verb: "Use" },''', '''price: PRICE.undo, verb: "Use {0}" },''')
rep('''price: PRICE.jar, verb: "Mend for" },''', '''price: PRICE.jar, verb: "Mend for {0}" },''')
rep('''$("offerTitle").textContent = o.title; $("offerText").textContent = o.text;
  $("offerAd").innerHTML = `${ICONS.play} Free video`;''', '''$("offerTitle").textContent = L(o.title); $("offerText").textContent = L(o.text);
  $("offerAd").innerHTML = `${ICONS.play} ${L("Free video")}`;''')

# ---------- pretend ads ----------
rep('''$("adTitle").textContent = kind === "rewarded" ? "Video ad" : "Ad break";
  $("adSub").textContent = kind === "rewarded" ? "Watch to the end for your reward" : "In the real game, a short ad plays here";''',
    '''$("adTitle").textContent = L(kind === "rewarded" ? "Video ad" : "Ad break");
  $("adSub").textContent = L(kind === "rewarded" ? "Watch to the end for your reward" : "In the real game, a short ad plays here");''')

# ---------- settings: language picker ----------
rep('''$("replayTutBtn").onclick = () => { $("settings").hidden = true; startPractice(); };''', '''$("replayTutBtn").onclick = () => { $("settings").hidden = true; startPractice(); };
(function langPicker() {
  const sel = $("setLang"), opts = [["", L("Automatic")]].concat((I18N.langs || ["en"]).map(c => [c, (I18N.native || {})[c] || c]));
  sel.innerHTML = opts.map(([c, n]) => `<option value="${c}">${n}</option>`).join("");
  sel.value = save.lang || "";
  // the whole page is set up for one language, so it reloads in the new one (progress is saved)
  sel.onchange = () => { save.lang = sel.value; store(); location.reload(); };
})();''')

# ---------- remove ads ----------
rep('''b.textContent = save.adsRemoved ? "Ads removed ✓" : "Remove ads · $2.99";''', '''b.textContent = save.adsRemoved ? L("Ads removed ✓") : L("Remove ads · {0}", "$2.99");''')
rep('''$("storeCancel").onclick = () => {''', '''$("storeBuy").textContent = L("Buy for {0}", "$2.99");
$("storeCancel").onclick = () => {''')

# ---------- hearts ----------
rep('''el.textContent = n >= LIVES_MAX ? "Full" : mmss(t);''', '''el.textContent = n >= LIVES_MAX ? L("Full") : mmss(t);''')
rep('''$("noLivesTime").textContent = n > 0 ? "You have a heart again!" : `Next heart in ${mmss(t)}`;''', '''$("noLivesTime").textContent = n > 0 ? L("You have a heart again!") : L("Next heart in {0}", mmss(t));''')
rep('''$("leaveTitle").textContent = what === "restart" ? "Restart this level?" : "Leave this level?";
  $("leaveText").textContent = `You'll lose a heart. Hard and Extreme levels cost a heart when you give up. You have ${livesNow()} left.`;
  $("leaveYes").textContent = what === "restart" ? "Restart (−1 heart)" : "Leave (−1 heart)";''',
    '''$("leaveTitle").textContent = L(what === "restart" ? "Restart this level?" : "Leave this level?");
  $("leaveText").textContent = L("You'll lose a heart. Hard and Extreme levels cost a heart when you give up. You have {0} left.", livesNow());
  $("leaveYes").textContent = L(what === "restart" ? "Restart (−1 heart)" : "Leave (−1 heart)");''')
rep('''setCoinBtn($("lifeCoinBtn"), LIFE_PRICE, "+1 heart for"); $("lifeAdBtn").innerHTML = `${ICONS.play} Video: +1 heart`;''',
    '''setCoinBtn($("lifeCoinBtn"), LIFE_PRICE, "+1 heart for {0}"); $("lifeAdBtn").innerHTML = `${ICONS.play} ${L("Video: +1 heart")}`;''')

# ---------- daily rewards ----------
rep('''const giftLabel = g => g.coins ? `${g.coins}` : g.hints ? `${g.hints} hint${g.hints > 1 ? "s" : ""}` : "Full hearts";''',
    '''const giftLabel = g => g.coins ? `${g.coins}` : g.hints ? (g.hints > 1 ? L("{0} hints", g.hints) : L("1 hint")) : L("Full hearts");''')
rep('''<small>Day ${i + 1}</small>''', '''<small>${L("Day {0}", i + 1)}</small>''')
rep('''$("giftSub").textContent = st.ready ? "Come back every day for a new gift. Day 7 is the biggest! Miss a day and it starts again." : `Come back tomorrow for day ${(done % 7) + 1}. Miss a day and it starts again from day 1.`;''',
    '''$("giftSub").textContent = st.ready ? L("Come back every day for a new gift. Day 7 is the biggest! Miss a day and it starts again.") : L("Come back tomorrow for day {0}. Miss a day and it starts again from day 1.", (done % 7) + 1);''')
rep('''toast(`Day ${st.day + 1} gift`, g.coins ? `+${g.coins} coins` : g.hints ? `+${g.hints} hint${g.hints > 1 ? "s" : ""}` : "Hearts refilled");''',
    '''toast(L("Day {0} gift", st.day + 1), g.coins ? L("+{0} coins", g.coins) : g.hints ? (g.hints > 1 ? L("+{0} hints", g.hints) : L("+1 hint")) : L("Hearts refilled"));''')

# ---------- trophies, toasts ----------
rep('''toastBusy = true; el.querySelector("small").textContent = t[0]; $("trophyName").textContent = t[1];''', '''toastBusy = true; el.querySelector("small").textContent = L(t[0]); $("trophyName").textContent = L(t[1]);''')
rep('''$("trophyCount").textContent = `${got} of ${TROPHIES.length} unlocked`;''', '''$("trophyCount").textContent = L("{0} of {1} unlocked", got, TROPHIES.length);''')
rep('''<span><b>${name}</b><small>${how}</small></span>''', '''<span><b>${L(name)}</b><small>${L(how)}</small></span>''')

# ---------- loading screen ----------
rep('''$("bootTip").textContent = TIPS[Math.floor(Math.random() * TIPS.length)];''', '''$("bootTip").textContent = L(TIPS[Math.floor(Math.random() * TIPS.length)]);''')
rep('''$("bootStatus").textContent = "Tap to play";''', '''$("bootStatus").textContent = L("Tap to play");''')


# ---------- round jar mouth on the big menu jar (Hatem: the opening looked straight) ----------
rep('''function jarPath(g, r) {
  const x = r.x, w = r.w, top = r.y, sh = r.y + w * .3, bot = r.y + r.h, br = w * .24, nx = w * .1;''',
    '''// mouth > 0 closes the top with the back half of an oval, so the opening looks round instead of flat
function jarPath(g, r, mouth = 0) {
  const x = r.x, w = r.w, top = r.y, sh = r.y + w * .3, bot = r.y + r.h, br = w * .24, nx = w * .1;''')
rep('''  g.quadraticCurveTo(x + w, top + w * .14, x + w - nx, top + w * .12); g.lineTo(x + w - nx, top); g.closePath();
}''',
    '''  g.quadraticCurveTo(x + w, top + w * .14, x + w - nx, top + w * .12); g.lineTo(x + w - nx, top);
  if (mouth) g.ellipse(x + w / 2, top, w / 2 - nx, mouth, 0, 0, Math.PI, true);
  g.closePath();
}''')
rep('''function heroBody(J) { return { x: J.x, y: J.y + J.h * .1, w: J.w, h: J.h * .9 }; }''',
    '''function heroBody(J) { return { x: J.x, y: J.y + J.h * .1, w: J.w, h: J.h * .9, m: J.w * .15 }; }''')
s = s.replace("jarPath(g, b);", "jarPath(g, b, b.m);")
rep("h: b.h - inset * 1.3 });", "h: b.h - inset * 1.3 }, b.m * .85);")
rep('''  // back edge of the open mouth
  g.strokeStyle = "rgba(200,225,255,.35)"; g.lineWidth = Math.max(1.5, b.w * .012);
  g.beginPath(); g.ellipse(cx, b.y, b.w * .4, b.w * .055, 0, Math.PI, 2 * Math.PI); g.stroke();''',
    '''  // the open mouth: a dark oval inside the rim, and the glass thickness along its back edge
  g.fillStyle = "rgba(5,8,25,.28)"; g.beginPath(); g.ellipse(cx, b.y, b.w * .37, b.m * .82, 0, 0, 2 * Math.PI); g.fill();
  g.strokeStyle = "rgba(200,225,255,.3)"; g.lineWidth = Math.max(1.5, b.w * .012);
  g.beginPath(); g.ellipse(cx, b.y, b.w * .37, b.m * .82, 0, Math.PI, 2 * Math.PI); g.stroke();''')
rep('''  for (let k = 0; k < 2; k++) { const y = top + w * (.035 + k * .045); g.beginPath(); g.moveTo(x + w * .11, y + w * .012); g.quadraticCurveTo(cx, y + w * .04, x + w * .89, y - w * .004); g.stroke(); }''',
    '''  for (let k = 0; k < 2; k++) { const y = top + w * (.04 + k * .045); g.beginPath(); g.ellipse(cx, y, w * .4, b.m * .9, 0, .12, Math.PI - .12); g.stroke(); }''')
rep('''g.beginPath(); g.ellipse(cx, top, w * .4, w * .055, 0, 0, Math.PI); g.stroke();''',
    '''g.beginPath(); g.ellipse(cx, top, w * .4, b.m, 0, 0, Math.PI); g.stroke();''')

open(p, "w", encoding="utf-8").write(s)
left = [m for m in re.findall(r"'Baloo 2', sans-serif", s)]
print("ok; Baloo literals left:", len(left))
