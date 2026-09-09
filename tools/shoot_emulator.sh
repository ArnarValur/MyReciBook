#!/usr/bin/env bash
# Shoot the marketing set off the stocked emulator — light, then dark.
#
# Needs: the pixel_7_api_35 AVD running, the profile build installed
# (flutter build apk --profile --dart-define-from-file=dev.env), and the
# folder seeded (tools/seed_emulator.py --clear --photos ... --pantry-photos ...).
# Camera permission must be granted once, or the scanner shows a dialog:
#   adb shell pm grant com.merkurialstudio.myrecibook.dev android.permission.CAMERA
#
# Every tap below is a coordinate on the 1080x2400 Pixel 7 screen, read off
# `uiautomator dump`. A different AVD moves them; re-read, don't guess.
#
# Usage: tools/shoot_emulator.sh [out-dir]   (default docs/MyReciBook-Emulator-Shots)
set -euo pipefail
export ANDROID_SERIAL=emulator-5554
A="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"
OUT="${1:-docs/MyReciBook-Emulator-Shots}"
mkdir -p "$OUT"

T() { "$A" shell input tap "$1" "$2"; sleep "${3:-1.5}"; }
SHOT() { "$A" exec-out screencap -p > "$OUT/$1.png"; echo "  $1"; }
# The status bar in demo mode: 9:30, full battery, wifi, nothing else.
demo() {
  "$A" shell settings put global sysui_demo_allowed 1
  local b="am broadcast -a com.android.systemui.demo -e command"
  "$A" shell $b enter >/dev/null
  "$A" shell $b clock -e hhmm 0930 >/dev/null
  "$A" shell $b battery -e level 100 -e plugged false >/dev/null
  "$A" shell $b network -e wifi show -e level 4 -e fully true >/dev/null
  "$A" shell $b network -e mobile hide >/dev/null
  "$A" shell $b notifications -e visible false >/dev/null
}

# Nav pill: Cookbook 156 · Grocery 360 · + 540 · Food 720 · Settings 924, y 2220.
# The grocery list is not seeded — three recipes are added from their pages,
# which also produces the "Same thing?" merge card the website shows.
seed_grocery() {
  T 156 2220 2; "$A" shell input swipe 540 800 540 1800 300; sleep 1.5
  for card in "792 1200" "792 1680" "288 1680"; do   # focaccia, tomato soup, miso mushrooms
    T $card 2.5; T 211 2232 1.2; T 100 208 1.5
  done
}

# One pass through every screen. $1 = suffix ("" or "-dark").
pass() {
  local s="$1"
  T 156 2220 2; "$A" shell input swipe 540 800 540 1800 300; sleep 1.5; SHOT "cookbook$s"
  T 792 1200 2.5; SHOT "recipe$s"                        # focaccia
  T 712 2232 3; for _ in 1 2 3 4; do T 712 2128 0.7; done; sleep 1; SHOT "cookmode$s"   # step 5 offers a timer
  T 980 264 1.5; T 100 208 1.5
  T 360 2220 2; SHOT "grocery$s"
  T 720 2220 2; T 300 260 2; T 116 425 1.5; SHOT "diary$s"   # yesterday: a day under goal
  T 964 425 2.5; T 540 345 2; SHOT "trends$s"; T 73 208 1.5  # three-month view with the records ledger
  T 778 260 2; SHOT "pantry$s"; T 540 1065 2.5; SHOT "product$s"; T 73 208 1.5   # first dairy product
  T 156 2220 2.5; T 540 2196 2; SHOT "import$s"; "$A" shell input keyevent 4; sleep 1
}

demo
seed_grocery
"$A" shell cmd uimode night no >/dev/null; sleep 3; echo "light:"; pass ""
"$A" shell cmd uimode night yes >/dev/null; sleep 3; echo "dark:"; pass "-dark"
"$A" shell cmd uimode night no >/dev/null
echo "done → $OUT"
