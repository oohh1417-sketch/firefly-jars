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

for b in js["data"][:3]:
    print("\n== build", b["attributes"]["version"])
    print(json.dumps(b["attributes"], indent=1))
    c, d = a.api("GET", f"/builds/{b['id']}/buildBetaDetail")
    print("beta:", json.dumps(d.get("data", {}).get("attributes", d)))
c, d = a.api("GET", "/certificates?filter[certificateType]=DISTRIBUTION")
for x in d.get("data", []):
    print("cert", x["id"], x["attributes"].get("expirationDate"), x["attributes"].get("activated"))

print("\n== versions")
c, d = a.api("GET", f"/apps/{app}/appStoreVersions?include=build&limit=3")
print(c, json.dumps([(v["attributes"].get("versionString"), v["attributes"].get("appStoreState"), v["attributes"].get("appVersionState"), v["relationships"]["build"].get("data")) for v in d.get("data", [])]))
c, d = a.api("GET", f"/reviewSubmissions?filter[app]={app}&include=items&limit=5")
print("review", c, json.dumps(d)[:3000])
