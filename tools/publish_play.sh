#!/usr/bin/env bash
# Upload a release bundle to a Google Play track from the terminal.
# Enrolled testers then get the update from the Play Store app itself —
# no reinstall, no sideload (agreed 2026-09-01).
#
# First real run 2026-09-09: 0.21.0+45 onto the closed "alpha" track.
#
# ONE-TIME SETUP (done 2026-09-09; here for the next machine):
#   1. Play Console → Users and permissions → Invite new user → paste the
#      service account's email, give it "Release to testing tracks" (or admin
#      on this app). The account itself is made once in GCP:
#        gcloud iam service-accounts create play-publisher --project myrecibook-prod
#        gcloud iam service-accounts keys create ~/keystores/play-publisher.json \
#          --iam-account play-publisher@myrecibook-prod.iam.gserviceaccount.com
#   2. APIs & Services on myrecibook-prod → enable "Google Play Android Developer API".
#   The key file never enters the repo; ~/keystores/ is where the upload key lives too.
#
# Usage: tools/publish_play.sh <path/to/app-release.aab> [track] [key.json]
#   track: internal (default) · alpha (the closed test) · beta · production
set -euo pipefail
AAB="${1:?aab path}"; TRACK="${2:-internal}"; KEY="${3:-$HOME/keystores/play-publisher.json}"
PKG="com.merkurialstudio.myrecibook"
# The release is named after pubspec's version line, e.g. "0.21.0+45".
NAME=$(sed -n 's/^version: *//p' "$(dirname "$0")/../app/pubspec.yaml")
# Print one field of a JSON answer, or the whole answer if it is not JSON — a
# 403 from Play is JSON too, so the message is always shown, never swallowed.
field() { python3 -c 'import json,sys
raw=sys.stdin.read()
try: d=json.loads(raw)
except Exception: print(raw.strip() or "(empty answer)"); sys.exit(1)
if "error" in d: print(d["error"].get("message", d)); sys.exit(1)
v=d
for k in sys.argv[1:]: v=v.get(k, v) if isinstance(v, dict) else v
print(v)' "$@"; }
export PATH="$HOME/google-cloud-sdk/bin:$PATH"
[[ -f "$AAB" ]] || { echo "no bundle at $AAB"; exit 1; }
[[ -f "$KEY" ]] || { echo "no service-account key at $KEY — see the setup note at the top of this script"; exit 1; }

# A short-lived token for the Play Developer API, minted from the key file.
TOKEN=$(gcloud auth print-access-token --scopes=https://www.googleapis.com/auth/androidpublisher \
  --impersonate-service-account="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['client_email'])" "$KEY")" 2>/dev/null \
  || CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="$KEY" gcloud auth print-access-token --scopes=https://www.googleapis.com/auth/androidpublisher)
API="https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$PKG"
H=(-H "Authorization: Bearer $TOKEN")

echo "── 1/4 open an edit"
EDIT=$(curl -sS -X POST "${H[@]}" "$API/edits" | field id)

echo "── 2/4 upload the bundle ($(du -h "$AAB" | cut -f1))"
VC=$(curl -sS -X POST "${H[@]}" -H "Content-Type: application/octet-stream" --data-binary @"$AAB" \
  "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/$PKG/edits/$EDIT/bundles?uploadType=media" \
  | field versionCode)
echo "   versionCode $VC"

echo "── 3/4 put versionCode $VC on the $TRACK track as \"$NAME\""
curl -sS -X PUT "${H[@]}" -H "Content-Type: application/json" "$API/edits/$EDIT/tracks/$TRACK" \
  -d "{\"track\":\"$TRACK\",\"releases\":[{\"name\":\"$NAME\",\"versionCodes\":[\"$VC\"],\"status\":\"completed\"}]}" \
  | field track

echo "── 4/4 commit"
curl -sS -X POST "${H[@]}" "$API/edits/$EDIT:commit" | field id
echo "done — Play rolls it to the $TRACK testers; the Store app shows Update within hours."
