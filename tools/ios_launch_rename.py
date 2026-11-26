#!/usr/bin/env python3
"""Give the iPhone launch screen new file names after Godot exports the Xcode project.

iPhones save a picture of each app's launch screen and can keep showing an old
one after an update (we saw the old "Firefly Jars" picture flash for a frame).
iOS makes a fresh picture when the launch storyboard and its image have new names,
so this renames Godot's "Launch Screen.storyboard" and "SplashImage".
Change TAG whenever the launch picture changes again.
Usage: ios_launch_rename.py <exported ios dir> (the folder holding FireflyJars.xcodeproj)
"""
import sys
from pathlib import Path

TAG = "JarWorldLaunch1"
root = Path(sys.argv[1])
app = root / "FireflyJars"

def edit(path, pairs):
    s = path.read_text()
    for old, new in pairs:
        if old not in s:
            sys.exit(f"{path.name}: '{old}' not found (Godot's export changed?)")
        s = s.replace(old, new)
    path.write_text(s)

sb_old = app / "Launch Screen.storyboard"
sb_new = app / f"{TAG}.storyboard"
edit(sb_old, [('image="SplashImage"', f'image="{TAG}Image"'), ('name="SplashImage"', f'name="{TAG}Image"')])
sb_old.rename(sb_new)
(app / "Images.xcassets" / "SplashImage.imageset").rename(app / "Images.xcassets" / f"{TAG}Image.imageset")
edit(app / "FireflyJars-Info.plist", [("<string>Launch Screen</string>", f"<string>{TAG}</string>")])
edit(root / "FireflyJars.xcodeproj" / "project.pbxproj",
     [('path = "Launch Screen.storyboard"', f'path = "{TAG}.storyboard"'),
      ("Launch Screen.storyboard", f"{TAG}.storyboard")])
print(f"Launch screen renamed to {TAG}")
