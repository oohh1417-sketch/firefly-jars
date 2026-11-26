# Builds the Jar World web page from the original single-file game (tools/web/base.html):
#   family link:  python3 tools/web/edit_regions.py tools/web/base.html index.html --family && python3 tools/i18n/build.py index.html
#   test page:    python3 tools/web/edit_regions.py tools/web/base.html pv/index.html && python3 tools/i18n/build.py pv/index.html
# The test page keeps its own save ("fj-preview") and lets you tap a chapter name on the map to jump there.
# The family page keeps everyone's real save ("fj-save"). Edit base.html / regions.js / regions.css, never index.html.
import sys, os, re
src, dst = sys.argv[1], sys.argv[2]
FAMILY = "--family" in sys.argv
VERSION = "v0.34"
s = open(src, encoding="utf-8").read()

def rep(old, new, cnt=1):
    global s
    c = s.count(old)
    if c != cnt:
        print("COUNT", c, "expected", cnt, "for:", old[:90]); sys.exit(1)
    s = s.replace(old, new)

# own save slot for the test page
if not FAMILY:
    s = s.replace('"fj-save"', '"fj-preview"')
rep("Test build v0.29", ("Jar World " if FAMILY else "Test build ") + VERSION)
rep('<title>Firefly Jars</title>', '<title>Jar World</title>')
rep('<div class="logo-main">Firefly</div>', '<div class="logo-main">Jar</div>', 2)
rep('<div class="logo-sub">JARS</div>', '<div class="logo-sub">WORLD</div>', 2)
rep('content="Firefly Jars"', 'content="Jar World"')
# screw threads only on mason jars
rep('''g.strokeStyle = "rgba(215,235,255,.5)"; g.lineWidth = Math.max(1.2, R * .07);
  for (const k of [.03, .08])''', '''g.strokeStyle = "rgba(215,235,255,.5)"; g.lineWidth = Math.max(1.2, R * .07);
  if ((themeNow().jar || "mason") === "mason" && !themeNow().deco) for (const k of [.03, .08])''')
# softer seam between two map scenes
rep('sg.addColorStop(.45, "rgba(3,4,12,.9)")', 'sg.addColorStop(.45, "rgba(3,4,12,.45)")')
# the cracked-jar repair: bigger world helpers, and their sparkles and glow take the world's color (no golden firefly trail)
a = s.index("// ===================== the cracked jar"); b = s.index("function paintHelper(g, x, y, r, flap, left) {")
body = s[a:b]
n = body.count('"#fff0a0"')
if n < 5: print("helper colors", n); sys.exit(1)
body = body.replace('"#fff0a0"', "helperCol()")
for old, new in [("paintHelper(ctx, x, y, R * .8,", "paintHelper(ctx, x, y, R * helperSize(),"),
                 ("if (particles.length < 260) particles.push(", "if (particles.length < 260 && Math.random() < helperTrail()) particles.push("),
                 ("twinkle(.55);", "if (helperTrail() > .9) twinkle(.55);")]:
    if body.count(old) != 1: print("helper patch", old); sys.exit(1)
    body = body.replace(old, new)
s = s[:a] + body + s[b:]
# the lid takes the region's colors
a = s.index("function paintCap(g, r, age) {"); b = s.index("// after the click the whole jar")
body = s[a:b]
gold = ["#b9843a", "#ecc675", "#8a5d22", "#d9a74e", "#fbe7a6", "#d6a24c", "#7a5220", "#c99a4a", "#fff3c8", "#b9873a"]
for i, c in enumerate(gold):
    if body.count('"%s"' % c) != 1: print("cap color", c, body.count('"%s"' % c)); sys.exit(1)
    body = body.replace('"%s"' % c, "CC[%d]" % i)
body = body.replace("function paintCap(g, r, age) {", "function paintCap(g, r, age) {\n  const CC = capCols();", 1)
s = s[:a] + body + s[b:]
# the loading screen shows every world: twilight sky, a bubble for each world, mixed things filling the jar
rep("""  function draw(t) {
    if (done) return;""", """  function draw(t) { HUB = 1; try { drawBoot(t); } finally { HUB = 0; } }
  function drawBoot(t) {
    if (done) return;""")
rep("    // the jar fills one firefly at a time", """    hubSky(g, W, H, T, H * .8); hubLand(g, W, H, T, H * .8); hubOrbs(g, W, H, T, BOOT_ORBS);
    // the jar fills one firefly at a time""")
rep("St.jars[0].forEach((col, s2) => paintFly(g,", "St.jars[0].forEach((col, s2) => mixFly(BOOT_KINDS[s2], g,")
rep("paintFly(g, x, y, R, n, T * 12, true, true, n * 3)", "mixFly(BOOT_KINDS[n], g, x, y, R, n, T * 12, true, true, n * 3)")
rep(">Catching fireflies…<", ">Filling the jars…<")
# each world's lid when locked, and its own sparks
rep("""    const lg = g.createLinearGradient(0, -r.w * .22, 0, r.w * .16); lg.addColorStop(0, "#8a6239"); lg.addColorStop(1, "#5a3c22");
    g.fillStyle = lg; roundRect(g, -r.w * .5, -r.w * .2, r.w, r.w * .34, 7, 7); g.fill();
    g.strokeStyle = "rgba(40,24,10,.35)"; g.lineWidth = 1.5; for (let k = -2; k <= 2; k++) { g.beginPath(); g.moveTo(k * r.w * .18, -r.w * .18); g.lineTo(k * r.w * .18, r.w * .12); g.stroke(); }""",
"""    LOCK_BADGE_Y = -.03;
    if (!lockArt(g, r)) {
    const lg = g.createLinearGradient(0, -r.w * .22, 0, r.w * .16); lg.addColorStop(0, "#8a6239"); lg.addColorStop(1, "#5a3c22");
    g.fillStyle = lg; roundRect(g, -r.w * .5, -r.w * .2, r.w, r.w * .34, 7, 7); g.fill();
    g.strokeStyle = "rgba(40,24,10,.35)"; g.lineWidth = 1.5; for (let k = -2; k <= 2; k++) { g.beginPath(); g.moveTo(k * r.w * .18, -r.w * .18); g.lineTo(k * r.w * .18, r.w * .12); g.stroke(); }
    }""")
rep("""      g.fillStyle = "#fff6d6"; g.beginPath(); g.arc(0, -r.w * .03, r.w * .22, 0, 6.283); g.fill();""", """      g.fillStyle = "#fff6d6"; g.beginPath(); g.arc(0, r.w * LOCK_BADGE_Y, r.w * .22, 0, 6.283); g.fill();""")
rep("""      g.fillText(String(lock), 0, -r.w * .0);""", """      g.fillText(String(lock), 0, r.w * (LOCK_BADGE_Y + .03));""")
rep("""    const a = 1 - p.life / p.max; glow(ctx, p.x, p.y, p.size * 3, p.col, .5 * a);
    ctx.fillStyle = `rgba(255,255,240,${a})`; ctx.fillRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size);""",
"""    paintParticle(ctx, p, 1 - p.life / p.max);""")
css = open(os.path.join(os.path.dirname(__file__), "regions.css"), encoding="utf-8").read()
rep("</style>", "\n" + css + "</style>")
# locked level stones on the map take their world's color
rep('g.fillStyle = "rgba(16,22,52,.88)"; g.beginPath(); g.arc(p.x, p.y, r, 0, 6.283); g.fill();', 'g.fillStyle = T.stone || "rgba(16,22,52,.88)"; g.beginPath(); g.arc(p.x, p.y, r, 0, 6.283); g.fill();')
# rounder bottom corners on the classic jar, so they match its shoulders
rep("sh = r.y + w * .3, bot = r.y + r.h, br = w * .24, nx = w * .1;", "sh = r.y + w * .3, bot = r.y + r.h, br = w * .36, nx = w * .1;")
# the regions themselves, added just before the loading screen starts
js = open(os.path.join(os.path.dirname(__file__), "regions.js"), encoding="utf-8").read()
if FAMILY:
    js = re.sub(r"// <test-only>.*?// </test-only>\n", "", js, flags=re.S)
rep("(function boot() {", js + "\n(function boot() {")
# each region's own music and sounds (made by game/tools/make_region_audio.py), as small MP3s inside the page
import subprocess, tempfile, base64, glob
audio = {}
root = os.path.join(os.path.dirname(__file__), "..", "..", "game", "audio")
with tempfile.TemporaryDirectory() as tmp:
    for wav in sorted(glob.glob(os.path.join(root, "*", "*.wav"))):
        region, name = os.path.basename(os.path.dirname(wav)), os.path.basename(wav)[:-4]
        mp3 = os.path.join(tmp, region + "_" + name + ".mp3")
        rate = "64k" if name == "music" else "48k"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-ac", "1", "-b:a", rate, mp3], check=True)
        audio[region + "_" + name] = "data:audio/mpeg;base64," + base64.b64encode(open(mp3, "rb").read()).decode()
import json
snd = ("Object.assign(SOUND_DATA, " + json.dumps(audio) + ");\n" +
       "for (const k of Object.keys(SOUND_DATA)) if (/^[a-z]+_sfx_/.test(k) && !SFX_NAMES.includes(k)) SFX_NAMES.push(k);\n")
rep("const Snd = {", snd + "const Snd = {")
print("region sounds", len(audio), sum(len(v) for v in audio.values()) // 1024, "KB")
os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
open(dst, "w", encoding="utf-8").write(s)
print("ok", len(s))
