#!/usr/bin/env bash
# Release .aab build — PROD wiring, one command.
# docs/prod-gcp-setup.md steps 13+15: swaps google-services-prod.json in so
# Crashlytics reports to myrecibook-prod, builds with prod.env dart-defines,
# then restores the dev file no matter how the build ends.
#
# Usage: cd app && ./build-release.sh
set -euo pipefail
cd "$(dirname "$0")"

GS=android/app/google-services.json
[[ -f android/app/google-services-prod.json ]] || { echo "prod json missing"; exit 1; }
[[ -f prod.env ]] || { echo "prod.env missing"; exit 1; }

cp "$GS" "$GS.dev-backup"
cp android/app/google-services-prod.json "$GS"
trap 'mv "$GS.dev-backup" "$GS"' EXIT

flutter build appbundle --release --dart-define-from-file=prod.env

echo
echo "aab: build/app/outputs/bundle/release/app-release.aab"
echo "dev google-services.json restored."
