#!/usr/bin/env python3
"""App Store signing for the iPhone build, using only the App Store Connect API key.

Xcode's automatic signing first needs a *development* profile, and Apple only
makes one when the team has a registered iPhone. Hatem has no Mac, so we skip
that: this script makes an Apple Distribution certificate and an App Store
provisioning profile through the App Store Connect API and installs them.

The certificate's private key is kept between runs in $CERT_DIR (restored from
the Actions cache, encrypted with a key derived from the API key secret), so
the same certificate is reused instead of making a new one every build.

Usage:
  asc_signing.py setup <bundle id>   -> prints PROFILE_UUID=... for $GITHUB_ENV
  asc_signing.py cleanup             -> removes the temporary keychain
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_FILE, CERT_DIR, RUNNER_TEMP
Needs only the Python standard library and openssl.
"""
import base64, json, os, subprocess, sys, time, urllib.error, urllib.request
from pathlib import Path

API = "https://api.appstoreconnect.apple.com/v1"
KEY_ID, ISSUER, KEY_FILE = os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_FILE"]
TMP = Path(os.environ.get("RUNNER_TEMP", "/tmp"))
CERT_DIR = Path(os.environ.get("CERT_DIR", TMP / "asc-cert"))
STATE = TMP / "asc_state.json"
PROFILE_PREFIX = "Jar World CI"
LIBRESSL = "/usr/bin/openssl"  # macOS openssl: its .p12 files import into the keychain


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def b64url(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def der_to_raw(sig):
    # ECDSA DER (SEQUENCE { INTEGER r, INTEGER s }) -> 64 raw bytes for ES256
    assert sig[0] == 0x30
    i = 2 if sig[1] < 0x80 else 2 + (sig[1] & 0x7F)
    out = b""
    for _ in range(2):
        assert sig[i] == 0x02
        ln = sig[i + 1]
        n = sig[i + 2:i + 2 + ln].lstrip(b"\x00")
        out += n.rjust(32, b"\x00")
        i += 2 + ln
    return out


_tok = {"t": None, "at": 0}


def token():
    now = int(time.time())
    if _tok["t"] and now - _tok["at"] < 600:
        return _tok["t"]
    head = b64url(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    body = b64url(json.dumps({"iss": ISSUER, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"}).encode())
    msg = f"{head}.{body}".encode()
    sig = subprocess.run(["openssl", "dgst", "-sha256", "-sign", KEY_FILE], input=msg,
                         capture_output=True, check=True).stdout
    _tok.update(t=f"{head}.{body}.{b64url(der_to_raw(sig))}", at=now)
    return _tok["t"]


def api(method, path, body=None):
    url = path if path.startswith("http") else API + path
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, {"raw": raw.decode(errors="replace")}


def must(res, what):
    code, js = res
    if code >= 300:
        log(f"App Store Connect said no to {what} (HTTP {code}):")
        for err in js.get("errors", [js]):
            log("  ", err.get("title", ""), "-", err.get("detail", err))
        sys.exit(1)
    return js


def sh(*cmd, **kw):
    return subprocess.run(list(cmd), check=True, capture_output=True, **kw).stdout


def get_certificate():
    """Reuse the cached certificate if Apple still has it, else make a new one."""
    CERT_DIR.mkdir(parents=True, exist_ok=True)
    key, info = CERT_DIR / "key.pem", CERT_DIR / "cert.json"
    if key.exists() and info.exists():
        cid = json.loads(info.read_text())["id"]
        code, js = api("GET", f"/certificates/{cid}")
        if code == 200 and js["data"]["attributes"].get("expirationDate", "9") > time.strftime("%Y-%m-%dT%H:%M:%S"):
            log("Reusing distribution certificate", cid)
            return cid, base64.b64decode(js["data"]["attributes"]["certificateContent"])
        log("Cached certificate is gone or expired; making a new one")
    sh("openssl", "genrsa", "-out", str(key), "2048")
    csr = sh("openssl", "req", "-new", "-key", str(key), "-subj", "/CN=Jar World CI/C=SA").decode()
    body = {"data": {"type": "certificates", "attributes": {"certificateType": "DISTRIBUTION", "csrContent": csr}}}
    code, js = api("POST", "/certificates", body)
    if code == 409:
        # Apple allows only a few distribution certificates. Hatem has no Mac, so every
        # one on this team was made by this build: revoke the oldest and try again.
        lst = must(api("GET", "/certificates?filter[certificateType]=DISTRIBUTION&limit=50"), "listing certificates")
        certs = sorted(lst["data"], key=lambda c: c["attributes"].get("expirationDate", ""))
        if not certs:
            must((code, js), "making a certificate")
        old = certs[0]
        log("Certificate limit reached; revoking the oldest one:", old["id"], old["attributes"].get("expirationDate"))
        must(api("DELETE", f"/certificates/{old['id']}"), "revoking an old certificate")
        code, js = api("POST", "/certificates", body)
    js = must((code, js), "making a distribution certificate")
    cid = js["data"]["id"]
    info.write_text(json.dumps({"id": cid}))
    log("Made distribution certificate", cid)
    return cid, base64.b64decode(js["data"]["attributes"]["certificateContent"])


def install_certificate(cert_der):
    key = CERT_DIR / "key.pem"
    der, pem, p12 = TMP / "dist.cer", TMP / "dist.pem", TMP / "dist.p12"
    der.write_bytes(cert_der)
    sh("openssl", "x509", "-inform", "der", "-in", str(der), "-out", str(pem))
    pw = "ci"
    sh(LIBRESSL, "pkcs12", "-export", "-inkey", str(key), "-in", str(pem), "-out", str(p12), "-passout", f"pass:{pw}")
    kc = str(TMP / "signing.keychain-db")
    kpw = "ci-keychain"
    subprocess.run(["security", "delete-keychain", kc], capture_output=True)
    sh("security", "create-keychain", "-p", kpw, kc)
    sh("security", "set-keychain-settings", "-lut", "21600", kc)
    sh("security", "unlock-keychain", "-p", kpw, kc)
    # Apple's intermediate certificate, in case this Mac image lacks it
    wwdr = TMP / "AppleWWDRCAG3.cer"
    try:
        urllib.request.urlretrieve("https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer", wwdr)
        subprocess.run(["security", "import", str(wwdr), "-k", kc], capture_output=True)
    except Exception as e:
        log("Could not fetch Apple WWDR G3 (probably already installed):", e)
    sh("security", "import", str(p12), "-k", kc, "-P", pw, "-T", "/usr/bin/codesign", "-T", "/usr/bin/security")
    sh("security", "set-key-partition-list", "-S", "apple-tool:,apple:,codesign:", "-s", "-k", kpw, kc)
    existing = sh("security", "list-keychains", "-d", "user").decode().split()
    existing = [k.strip('"') for k in existing if "signing.keychain" not in k]
    sh("security", "list-keychains", "-d", "user", "-s", kc, *existing)
    for p in (p12, pem, der):
        p.unlink(missing_ok=True)
    log(sh("security", "find-identity", "-v", "-p", "codesigning", kc).decode())


def make_profile(bundle, cert_id):
    js = must(api("GET", f"/bundleIds?filter[identifier]={bundle}&limit=50"), "finding the App ID")
    ids = [b for b in js["data"] if b["attributes"]["identifier"] == bundle]
    if not ids:
        log(f"No App ID {bundle} in this Apple account"); sys.exit(1)
    bid = ids[0]["id"]
    # remove old CI profiles so they don't pile up
    old = must(api("GET", f"/profiles?filter[profileType]=IOS_APP_STORE&limit=200"), "listing profiles")
    for p in old["data"]:
        if p["attributes"]["name"].startswith(PROFILE_PREFIX):
            api("DELETE", f"/profiles/{p['id']}")
    name = f"{PROFILE_PREFIX} {time.strftime('%Y%m%d-%H%M%S')}"
    body = {"data": {"type": "profiles",
                     "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
                     "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bid}},
                                       "certificates": {"data": [{"type": "certificates", "id": cert_id}]}}}}
    js = must(api("POST", "/profiles", body), "making the App Store profile")
    a = js["data"]["attributes"]
    content, uuid = base64.b64decode(a["profileContent"]), a["uuid"]
    home = Path.home()
    for d in (home / "Library/MobileDevice/Provisioning Profiles",
              home / "Library/Developer/Xcode/UserData/Provisioning Profiles"):
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{uuid}.mobileprovision").write_bytes(content)
    STATE.write_text(json.dumps({"profile": js["data"]["id"]}))
    log("Made App Store profile", name, uuid)
    return uuid


def main():
    if sys.argv[1] == "setup":
        cid, der = get_certificate()
        install_certificate(der)
        print(f"PROFILE_UUID={make_profile(sys.argv[2], cid)}")
    elif sys.argv[1] == "cleanup":
        subprocess.run(["security", "delete-keychain", str(TMP / "signing.keychain-db")], capture_output=True)


if __name__ == "__main__":
    main()
