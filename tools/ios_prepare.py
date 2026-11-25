#!/usr/bin/env python3
"""Get the Godot project in game/ ready for an iPhone export on GitHub Actions.

- turns on the AdMob editor plugin and sets the real iOS AdMob App ID
- fills the iOS export preset: team, version, plugins, tracking text, entitlements
Usage: ios_prepare.py <game dir> <team id or ''> <short version> <build number> [profile uuid]
With a profile uuid (from tools/asc_signing.py) the release export signs manually
with that App Store profile and the Apple Distribution certificate.
"""
import re, sys
from pathlib import Path

game, team, short_ver, build_no = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
profile_uuid = sys.argv[5] if len(sys.argv) > 5 else ""
IOS_ADMOB_APP_ID = "ca-app-pub-4638827077517403~5345092257"

# ---------- project.godot ----------
pg = game / "project.godot"
s = pg.read_text()
def set_section(text, section, lines):
    block = "\n".join(lines)
    if f"[{section}]" in text:
        return re.sub(rf"\[{re.escape(section)}\]\n", f"[{section}]\n{block}\n", text, count=1)
    return text.rstrip() + f"\n\n[{section}]\n\n{block}\n"
s = set_section(s, "editor_plugins", ['enabled=PackedStringArray("res://addons/admob/plugin.cfg")'])
s = set_section(s, "admob", [
    "general/ios/enabled=true",
    f'general/ios/app_id="{IOS_ADMOB_APP_ID}"',
    "general/android/enabled=false",
])
pg.write_text(s)

# ---------- export_presets.cfg: replace the iOS preset options ----------
ep = game / "export_presets.cfg"
e = ep.read_text()
m = re.search(r'\[preset\.(\d+)\]\n\nname="iOS"', e)
if not m:
    sys.exit("No iOS preset in export_presets.cfg")
n = m.group(1)
opt_head = f"[preset.{n}.options]\n"
start = e.index(opt_head) + len(opt_head)
nxt = e.find("\n[preset.", start)
body = e[start:] if nxt == -1 else e[start:nxt]

plist = ("<key>NSUserTrackingUsageDescription</key>"
         "<string>Your choice lets us show ads that fit you better. Jar World works the same either way.</string>"
         "<key>ITSAppUsesNonExemptEncryption</key><false/>"
         "<key>UIRequiresFullScreen</key><true/>")
ent = ("<key>com.apple.developer.ubiquity-kvstore-identifier</key>"
       "<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>")
want = {
    "application/app_store_team_id": f'"{team}"',
    "application/export_project_only": "true",
    "application/export_method_release": "0",
    "application/bundle_identifier": '"com.hatem.fireflyjars"',
    "application/short_version": f'"{short_ver}"',
    "application/version": f'"{build_no}"',
    "application/min_ios_version": '"15.0"',
    "application/targeted_device_family": "0",          # iPhone only
    "application/additional_plist_content": '"' + plist.replace('"', '\\"') + '"',
    "entitlements/game_center": "true",
    "entitlements/additional": '"' + ent.replace('"', '\\"') + '"',
    "privacy/tracking_enabled": "true",
    "plugins/AdMob": "true",
    "plugins/InAppStore": "true",
    "plugins/GameCenter": "true",
    "plugins/iCloud": "true",
}
if profile_uuid:
    want["application/code_sign_identity_release"] = '"Apple Distribution"'
    want["application/provisioning_profile_uuid_release"] = f'"{profile_uuid}"'
lines = [l for l in body.strip("\n").split("\n") if l and l.split("=", 1)[0] not in want]
lines += [f"{k}={v}" for k, v in want.items()]
new_body = "\n".join(lines) + "\n"
e = e[:start] + new_body + ("" if nxt == -1 else e[nxt:])
ep.write_text(e)
print(f"iOS preset {n} ready: version {short_ver} ({build_no}), team {'set' if team else 'MISSING (unsigned test build)'}")
