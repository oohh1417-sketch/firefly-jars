#!/usr/bin/env python3
"""Cuts the language fonts down to just the letters the game uses, so the app stays small.

  pip install fonttools brotli
  python3 tools/i18n/fonts.py <folder with the full Google Fonts .ttf files>

Needs (from github.com/google/fonts, all SIL Open Font License):
  Baloo2[wght].ttf, BalooBhaijaan2[wght].ttf, Nunito[wght].ttf, MPLUSRounded1c-ExtraBold.ttf,
  Jua-Regular.ttf, NotoSansSC[wght].ttf
Writes game/fonts/Baloo2-Bold.woff2, Baloo2-ExtraBold.woff2 (now with Turkish letters) and game/fonts/lang/*.woff2.
Run it again after adding texts in new letters (mostly Chinese, Japanese and Korean).
"""
import os, sys
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools import subset

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import strings as S  # noqa: E402

EXTRA = "0123456789 +-−·:.,!?()%/…✓▶✕"


def chars(lang):
    i = S.LANGS.index(lang)
    txt = "".join(r[i] for r in S.S) + S.NATIVE[lang] + EXTRA
    if lang in S.MONTHS:
        txt += "".join(S.MONTHS[lang][0]) + S.MONTHS[lang][1]
    return txt


def cut(src, dst, text=None, unicodes=None, weight=None):
    f = TTFont(src)
    if "fvar" in f:
        f = instancer.instantiateVariableFont(f, {a.axisTag: (weight if a.axisTag == "wght" else a.defaultValue) for a in f["fvar"].axes})
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    s = subset.Subsetter(opts)
    s.populate(text=text or "", unicodes=unicodes or [])
    s.subset(f)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    f.flavor = "woff2"
    f.save(dst)
    print(f"{os.path.relpath(dst, ROOT)}: {os.path.getsize(dst) // 1024} KB")


if __name__ == "__main__":
    src = sys.argv[1]
    fonts = os.path.join(ROOT, "game", "fonts")
    latin = list(range(0x20, 0x7F)) + list(range(0xA0, 0x180)) + [ord(c) for c in "–—‘’“”…•·−€₺₽"]
    latin_text = "".join(chars(l) for l in ["es", "pt", "fr", "de", "tr"])
    for w, name in [(700, "Baloo2-Bold"), (800, "Baloo2-ExtraBold")]:
        cut(os.path.join(src, "Baloo2[wght].ttf"), os.path.join(fonts, name + ".woff2"), text=latin_text, unicodes=latin, weight=w)
    cut(os.path.join(src, "BalooBhaijaan2[wght].ttf"), os.path.join(fonts, "lang", "ar.woff2"), text=chars("ar"), weight=800)
    cut(os.path.join(src, "Nunito[wght].ttf"), os.path.join(fonts, "lang", "ru.woff2"), text=chars("ru"), weight=850)
    cut(os.path.join(src, "MPLUSRounded1c-ExtraBold.ttf"), os.path.join(fonts, "lang", "ja.woff2"), text=chars("ja"))
    cut(os.path.join(src, "Jua-Regular.ttf"), os.path.join(fonts, "lang", "ko.woff2"), text=chars("ko"))
    cut(os.path.join(src, "NotoSansSC[wght].ttf"), os.path.join(fonts, "lang", "zh.woff2"), text=chars("zh"), weight=800)
