# Makes the TEST page with six themed regions: python3 tools/web/edit_regions.py index.html preview/index.html
# The normal page (family link) stays as it is. The test page keeps its own save, so testing never touches real progress.
import sys, os, re
src, dst = sys.argv[1], sys.argv[2]
s = open(src, encoding="utf-8").read()

def rep(old, new, cnt=1):
    global s
    c = s.count(old)
    if c != cnt:
        print("COUNT", c, "expected", cnt, "for:", old[:90]); sys.exit(1)
    s = s.replace(old, new)

# own save slot
s = s.replace('"fj-save"', '"fj-preview"')
rep('<title>Firefly Jars</title>', '<title>Jar World</title>')
rep('<div class="logo-main">Firefly</div>', '<div class="logo-main">Jar</div>', 2)
rep('<div class="logo-sub">JARS</div>', '<div class="logo-sub">WORLD</div>', 2)
rep('content="Firefly Jars"', 'content="Jar World"')
# screw threads only on mason jars
rep('''g.strokeStyle = "rgba(215,235,255,.5)"; g.lineWidth = Math.max(1.2, R * .07);
  for (const k of [.03, .08])''', '''g.strokeStyle = "rgba(215,235,255,.5)"; g.lineWidth = Math.max(1.2, R * .07);
  if ((themeNow().jar || "mason") === "mason") for (const k of [.03, .08])''')
# softer seam between two map scenes
rep('sg.addColorStop(.45, "rgba(3,4,12,.9)")', 'sg.addColorStop(.45, "rgba(3,4,12,.45)")')
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
# the regions themselves, added just before the loading screen starts
js = open(os.path.join(os.path.dirname(__file__), "regions.js"), encoding="utf-8").read()
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
