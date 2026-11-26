#!/usr/bin/env python3
"""Print the latest App Store Connect builds and their processing state (read-only)."""
import sys, json
sys.path.insert(0, "tools")
import asc_signing as a
js = a.must(a.api("GET", "/apps?filter[bundleId]=com.hatem.fireflyjars"), "finding the app")
app = js["data"][0]["id"]
js = a.must(a.api("GET", f"/builds?filter[app]={app}&sort=-uploadedDate&limit=8&include=preReleaseVersion,buildBetaDetail"), "listing builds")
inc = {(i["type"], i["id"]): i["attributes"] for i in js.get("included", [])}
for b in js["data"]:
    at = b["attributes"]
    pv = b["relationships"]["preReleaseVersion"]["data"]
    ver = inc.get(("preReleaseVersions", pv["id"]), {}).get("version") if pv else None
    print(ver, at["version"], at["processingState"], "expired" if at.get("expired") else "", at.get("usesNonExemptEncryption"), at["uploadedDate"])
