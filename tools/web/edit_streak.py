import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
def rep(old, new, cnt=1):
    global s
    c = s.count(old)
    if c != cnt:
        print("COUNT", c, "expected", cnt, "for:", old[:120]); sys.exit(1)
    s = s.replace(old, new)

# ---- CSS: the pill under the level, the glowing streak chip ----
rep('''.level span, #movesLeft { white-space: nowrap; }''', '''.level span, #movesLeft { white-space: nowrap; }
#movesLeft .sk { color: #ffb347; text-shadow: 0 0 8px rgba(255, 150, 40, .9); margin-inline-end: 4px; }
#movesLeft .sk svg.i { width: 14px; height: 14px; vertical-align: -2px; }
#movesLeft.target { color: #d9f6ff; background: rgba(60, 170, 255, .16); border-color: rgba(120, 200, 255, .55); }
#movesLeft.target.off { color: rgba(220, 230, 255, .55); background: rgba(255, 255, 255, .06); border-color: rgba(255, 255, 255, .18); }
.streakSide .sb svg.i { color: #ff9a3c; }
.streakSide b { min-width: 30px; color: #ffcf7a; border-color: rgba(255, 160, 60, .75); }
.streakSide.hot .sb { animation: streakGlow 1.8s ease-in-out infinite; }
@keyframes streakGlow { 0%, 100% { box-shadow: 0 0 8px rgba(255, 140, 40, .35); } 50% { box-shadow: 0 0 18px rgba(255, 150, 40, .8); } }''')

# ---- save ----
rep('''dailyDone: "", streak: 0, adsRemoved''', '''dailyDone: "", streak: 0, skill: 0, adsRemoved''')
rep('''bestStreak: 0, repairs: 0''', '''bestStreak: 0, bestSkill: 0, repairs: 0''')

# ---- state ----
rep('''let movesMax = 0, moveLimit = 0;''', '''// Skill streak: on normal levels (from level 3) finish within `target` pours and without a hint.
// On Hard/Extreme levels, win with 3+ pours to spare and without losing a heart on that level.
const STREAK_FROM = 3, STREAK_SPARE = 3, STREAK_BONUS = { 3: 15, 5: 30, 10: 60 };   // GUESS: bonus sizes
let target = 0, heartLostAt = 0;
const streakBonus = n => STREAK_BONUS[n] || (n > 10 && n % 5 === 0 ? 60 : 0);
let movesMax = 0, moveLimit = 0;''')

# ---- the pill under the level name ----
rep('''  ml.hidden = !hardNow() || won;
  ml.textContent = !movesMax ? "…" : left === 1 ? L("1 move left") : L("{0} moves left", left);''',
'''  const tgtNow = mode === "level" && !isHard(save.level) && $("menu").hidden && target > 0;
  ml.hidden = !(hardNow() || tgtNow) || won;
  const sk = save.skill > 0 ? `<span class="sk">${ICONS.flame}${save.skill}</span>` : "";
  ml.classList.toggle("target", tgtNow); ml.classList.toggle("off", tgtNow && (usedHint || moves > target));
  ml.innerHTML = sk + (tgtNow ? L("Target: {0} / {1}", moves, target) : !movesMax ? "…" : left === 1 ? L("1 move left") : L("{0} moves left", left));''')
rep('''ml.classList.toggle("low", !!movesMax && left <= 5 && left > 2); ml.classList.toggle("last", !!movesMax && left <= 2);''',
    '''ml.classList.toggle("low", !tgtNow && !!movesMax && left <= 5 && left > 2); ml.classList.toggle("last", !tgtNow && !!movesMax && left <= 2);''')

# ---- start of a level: work out the target (normal levels) the same way as the Hard move limit ----
rep('''  hintPlan = null; startS = generate(save.level); moveLimit = moveLimitFor(save.level, startS); resetExtra(); loadState(copyS(startS), true); maybeTip();
  if (isHard(save.level) && !moveLimit) {''',
'''  hintPlan = null; startS = generate(save.level); moveLimit = moveLimitFor(save.level, startS); target = streakTargetFor(save.level, startS); resetExtra(); loadState(copyS(startS), true); maybeTip();
  if (heartLostAt !== save.level) heartLostAt = 0;
  const nextLv = save.level + 1, prefetchNext = () => setTimeout(() => prefetchLimit(nextLv), 2500);   // get the next level ready while this one is played
  if (!isHard(save.level) && save.level >= STREAK_FROM && !target) {
    const lv = save.level, st = startS;
    prefetchLimit(lv, () => {
      prefetchNext();
      if (mode !== "level" || save.level !== lv || startS !== st || won) return;
      target = streakTargetFor(lv, st); refresh(); if (target && !save.seen.streak) showTip("streak");
    });
  } else if (!isHard(save.level) || moveLimit) prefetchNext();
  if (target && !save.seen.streak) showTip("streak");
  if (isHard(save.level) && !moveLimit) {''')
rep('''      if (outOfMoves()) showOutOfMoves();
    });
  }
  if (isHard(save.level + 1)) setTimeout(() => prefetchLimit(save.level + 1), 2500);   // get the next hard level ready while this one is played''',
'''      if (outOfMoves()) showOutOfMoves();
      prefetchNext();
    });
  }''')
rep('''function startDaily() {
  Snd.start(); mode = "daily"; dailyDate = today(); moveLimit = 0; hintPlan = null;''', '''function startDaily() {
  Snd.start(); mode = "daily"; dailyDate = today(); moveLimit = 0; target = 0; hintPlan = null;''')

# ---- the search now runs for every level (normal ones for the target) ----
rep('''function prefetchLimit(lv, onDone) {
  if (!isHard(lv)) return;''', '''function prefetchLimit(lv, onDone) {
  if (!isHard(lv) && lv < STREAK_FROM) return;''')
rep('''  return limitFor(lv, best);
}''', '''  return limitFor(lv, best);
}
// Normal levels: the fewest possible pours plus a little room (25%, at least 3). 0 while not known yet.
function streakTargetFor(lv, s) {
  if (isHard(lv) || lv < STREAK_FROM) return 0;
  const c = limitCache[lv];
  if (!c || c.key !== key(s) || !c.path) return 0;
  hintPlan = planFrom(s, c.path);
  const best = c.path.length;
  return best + Math.max(3, Math.ceil(best * .25));
}''')

# ---- hearts ----
rep('''  save.lives = Math.max(0, save.lives - 1); store(); refreshLives();''', '''  save.lives = Math.max(0, save.lives - 1); store(); refreshLives();
  if (mode === "level") heartLostAt = save.level;''')

# ---- the win ----
rep('''    const wasHard = isHard(save.level), wasExt = isExtreme(save.level);
    save.level++;
    gain = wasExt ? COIN.extreme : wasHard ? COIN.hard : COIN.level;''',
'''    const wasHard = isHard(save.level), wasExt = isExtreme(save.level);
    // skill streak: null = this level doesn't count (too early, or no target yet)
    let ok = null, why = "";
    if (wasHard && moveLimit) { ok = moveLimit - moves >= STREAK_SPARE && heartLostAt !== save.level; why = heartLostAt === save.level ? "Streak lost: a heart was lost" : "Streak lost: win with 3 moves to spare"; }
    else if (!wasHard && target) { ok = !usedHint && moves <= target; why = usedHint ? "Streak lost: a hint was used" : "Streak lost: over the target moves"; }
    let streakText = "", bonus = 0;
    if (ok) { save.skill++; save.stats.bestSkill = Math.max(save.stats.bestSkill, save.skill); bonus = streakBonus(save.skill);
      streakText = "\\n" + L("Skill streak: {0}", save.skill) + " 🔥" + (bonus ? "\\n" + L("Streak bonus: +{0} coins", bonus) : ""); }
    else if (ok === false && save.skill > 0) { save.skill = 0; streakText = "\\n" + L(why); }
    Analytics.log("skill_streak", { level: save.level, ok: ok === null ? "na" : ok ? "yes" : "no", streak: save.skill });
    save.level++;
    gain = (wasExt ? COIN.extreme : wasHard ? COIN.hard : COIN.level) + bonus;''')
rep('''    else if (save.level < 10 && save.level % 5 === 0) save.hints++;
    $("nextBtn").textContent = L("Next level");''', '''    else if (save.level < 10 && save.level % 5 === 0) save.hints++;
    text += streakText;
    $("nextBtn").textContent = L("Next level");''')

# ---- menu chip ----
rep('''  $("streakChip").hidden = true;''', '''  $("streakChip").hidden = true;
  $("streakSide").hidden = !(save.skill > 0 || save.seen.streak); $("streakSideN").textContent = save.skill; $("streakSide").classList.toggle("hot", save.skill > 0);''')
rep('''<i class="badge" id="giftBadge">!</i></button>''', '''<i class="badge" id="giftBadge">!</i></button>
      <button class="sideBtn streakSide" id="streakSide" aria-label="Skill streak" hidden><span class="sb" data-ico="flame"></span><b id="streakSideN">0</b></button>''')
rep('''$("tipBtn").onclick = ''', '''$("streakSide").onclick = () => { Snd.play("sfx_select"); showTip("streak"); };
$("tipBtn").onclick = ''')

# ---- explainer card ----
rep('''  map: { title: "Your firefly trail",''', '''  streak: { title: "Skill streak", text: "Finish a level within the target moves, without a hint, and your streak grows. On Hard and Extreme levels, win with 3 or more moves to spare without losing a heart. Bonus coins at 3, 5 and 10 in a row! Miss, and it starts again from 0." },
  map: { title: "Your firefly trail",''')
rep('''  if (["hard", "extreme", "lives", "coins", "map"].includes(k)) return drawTipIcon(g, k);''',
    '''  if (["hard", "extreme", "lives", "coins", "map", "streak"].includes(k)) return drawTipIcon(g, k);''')
rep('''  if (k === "map") {''', '''  if (k === "streak") { glow(g, cx, cy, 95, "#ff8a2a", .6);
    const fl = (w, h, c) => { g.fillStyle = c; g.beginPath(); g.moveTo(cx, cy - h * .55); g.bezierCurveTo(cx + w * .2, cy - h * .2, cx + w * .55, cy - h * .05, cx + w * .5, cy + h * .2);
      g.bezierCurveTo(cx + w * .45, cy + h * .45, cx + w * .2, cy + h * .5, cx, cy + h * .5); g.bezierCurveTo(cx - w * .2, cy + h * .5, cx - w * .45, cy + h * .45, cx - w * .5, cy + h * .2);
      g.bezierCurveTo(cx - w * .55, cy - h * .05, cx - w * .15, cy - h * .15, cx, cy - h * .55); g.fill(); };
    fl(120, 160, "#ff7a1a"); fl(80, 110, "#ffb830"); g.save(); g.translate(0, 22); fl(46, 64, "#fff0a0"); g.restore();
    g.fillStyle = "#7a2a00"; g.font = "800 34px " + CANVAS_FONT; g.textAlign = "center"; g.textBaseline = "middle"; g.fillText("3", cx, cy + 44); }
  if (k === "map") {''')
open(p, "w", encoding="utf-8").write(s)
print("streak ok")
s = s.replace("· Test build v0.24</div>", "· Test build v0.28</div>")
open(p, "w", encoding="utf-8").write(s)
